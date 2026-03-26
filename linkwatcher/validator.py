"""
Link validation module for the LinkWatcher system.

Provides on-demand workspace scanning to detect broken file references
across all supported file formats. Read-only operation — does not modify
any files.
"""

import os
import re
import time
from dataclasses import dataclass, field
from typing import FrozenSet, List, Optional, Set

from .config.settings import LinkWatcherConfig
from .logging import get_logger
from .models import LinkReference
from .parser import LinkParser
from .utils import looks_like_file_path, should_monitor_file


@dataclass
class BrokenLink:
    """A link reference whose target does not exist on disk."""

    source_file: str
    line_number: int
    target_path: str
    link_type: str


@dataclass
class ValidationResult:
    """Aggregated result of a workspace validation scan."""

    broken_links: List[BrokenLink] = field(default_factory=list)
    files_scanned: int = 0
    links_checked: int = 0
    duration_seconds: float = 0.0

    @property
    def is_clean(self) -> bool:
        return len(self.broken_links) == 0


# Prefixes that indicate a URL rather than a local file path.
_URL_PREFIXES = ("http://", "https://", "ftp://", "mailto:", "tel:", "data:")

# Directories that should be ignored during validation but may not be in the
# watcher's ignored_directories (e.g., output/run directories that contain
# log files with embedded paths, not real references).
_VALIDATION_EXTRA_IGNORED_DIRS: Set[str] = {
    "LinkWatcher_run",
    "old",
    "archive",
    "fixtures",
    "e2e-acceptance-testing",
}

# Patterns that indicate a target string is a shell command, not a file path.
_COMMAND_PATTERN = re.compile(
    r"^(?:"
    r"Bash\(|"  # Claude Code permission strings
    r"pwsh(?:\.exe)?\s|"  # PowerShell invocations
    r"python\s|"  # Python invocations
    r"pip\s|"  # pip commands
    r"npm\s|"  # npm commands
    r"git\s|"  # git commands
    r"find\s|"  # find commands
    r"grep\s|"  # grep commands
    r"curl\s|"  # curl commands
    r"echo\s"  # echo commands
    r")",
    re.IGNORECASE,
)

# Glob/wildcard patterns are not real file references.
_WILDCARD_PATTERN = re.compile(r"[*?]")

# Numeric patterns that contain "/" but are not file paths (e.g. "3.475/4.0").
_NUMERIC_SLASH_PATTERN = re.compile(r"^\d[\d.]*/.+")

# Template placeholders that are not real paths.
# Matches: YYYY, XXXX, HHMMSS, <angle-bracket>, [square-bracket] placeholders.
_PLACEHOLDER_PATTERN = re.compile(r"YYYY|XXXX|HHMMSS|<[^>]+>|\[[a-z][a-z-]*\]")

# Link types that represent bare/standalone path text (no explicit link syntax).
# These are safe to skip inside fenced code blocks because real references in
# code blocks use proper link syntax ([text](path)) which has its own link_type.
_STANDALONE_LINK_TYPES: frozenset = frozenset(
    {
        "markdown-standalone",
        "markdown-quoted",
        "markdown-quoted-dir",
    }
)

# Link types whose paths are data values (config entries, registry fields,
# prose mentions) rather than explicit navigable links.  These commonly use
# project-root-relative paths regardless of the source file's location, so
# the validator applies a project-root fallback before flagging them broken.
_DATA_VALUE_LINK_TYPES: frozenset = _STANDALONE_LINK_TYPES | frozenset(
    {
        "yaml",
        "yaml-dir",
        "json",
        "json-dir",
    }
)

# File extensions whose links should be validated.  Source code files (.py,
# .ps1, .psm1, .dart, …) contain string literals and comments with paths that
# are data values — they matter for the real-time watcher but not for the
# on-demand validation report.
_VALIDATION_EXTENSIONS: Set[str] = {
    ".md",
    ".yaml",
    ".yml",
    ".json",
}

# Regex matching the opening/closing fence of a code block (``` or ~~~).
_FENCE_RE = re.compile(r"^[ \t]*(```|~~~)")


class LinkValidator:
    """
    Scans a workspace and reports broken local file references.

    Reuses the existing LinkParser infrastructure to extract links,
    then resolves each target relative to its source file and checks
    whether it exists on disk.
    """

    def __init__(self, project_root: str, config: Optional[LinkWatcherConfig] = None):
        self.project_root = os.path.abspath(project_root)
        self.config = config or LinkWatcherConfig()
        self.parser = LinkParser(self.config)
        self.logger = get_logger()

    def validate(self) -> ValidationResult:
        """Walk the workspace, parse every monitored file, and check links."""
        result = ValidationResult()
        start = time.monotonic()

        ignored_dirs = self.config.ignored_directories | _VALIDATION_EXTRA_IGNORED_DIRS

        for root, dirs, files in os.walk(self.project_root):
            # Prune ignored directories in-place (same pattern as _initial_scan)
            dirs[:] = [d for d in dirs if d not in ignored_dirs]

            for filename in files:
                file_path = os.path.join(root, filename)

                # Only validate documentation files — source code files (.py,
                # .ps1, etc.) contain string/comment paths that are data values,
                # not document cross-references.
                if not should_monitor_file(file_path, _VALIDATION_EXTENSIONS, ignored_dirs):
                    continue

                self._check_file(file_path, result)

        result.duration_seconds = time.monotonic() - start
        return result

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    def _check_file(self, file_path: str, result: ValidationResult) -> None:
        """Parse a single file and verify every link target."""
        try:
            references: List[LinkReference] = self.parser.parse_file(file_path)
        except Exception as exc:
            self.logger.warning(
                "validation_parse_failed",
                file_path=file_path,
                error=str(exc),
            )
            return

        result.files_scanned += 1

        # For markdown files, identify fenced code block lines so we can
        # skip standalone (bare-path) links inside them.  Proper [text](path)
        # links inside code blocks are still checked — zero false negatives.
        code_block_lines: FrozenSet[int] = frozenset()
        if file_path.lower().endswith(".md"):
            code_block_lines = self._get_code_block_lines(file_path)

        for ref in references:
            target = ref.link_target

            if not self._should_check_target(target, ref.link_type):
                continue

            # Skip standalone link types inside fenced code blocks
            if (
                code_block_lines
                and ref.link_type in _STANDALONE_LINK_TYPES
                and ref.line_number in code_block_lines
            ):
                continue

            result.links_checked += 1

            if not self._target_exists(file_path, target):
                # Data-value link types (standalone prose mentions, YAML/JSON
                # config entries) are often written as project-root-relative
                # even inside deeply nested files.  Try root-relative
                # resolution as fallback before declaring them broken.
                if (
                    ref.link_type in _DATA_VALUE_LINK_TYPES
                    and not target.startswith(("/", ".", "\\"))
                    and self._target_exists_at_root(target)
                ):
                    continue

                rel_source = os.path.relpath(file_path, self.project_root)
                result.broken_links.append(
                    BrokenLink(
                        source_file=rel_source.replace("\\", "/"),
                        line_number=ref.line_number,
                        target_path=target,
                        link_type=ref.link_type,
                    )
                )

    @staticmethod
    def _should_check_target(target: str, link_type: str) -> bool:
        """Decide whether a parsed link target is worth checking on disk.

        Filters out URLs, Python imports, shell commands, wildcard patterns,
        and strings that don't look like file paths.
        """
        # Skip URLs
        if target.startswith(_URL_PREFIXES):
            return False

        # Skip Python import targets (module paths, not file paths)
        if link_type == "python-import":
            return False

        # Skip shell commands / CLI invocations
        if _COMMAND_PATTERN.match(target):
            return False

        # Skip wildcard / glob patterns (e.g. *.md, **/*.py)
        if _WILDCARD_PATTERN.search(target):
            return False

        # Skip numeric/slash patterns like "3.475/4.0" (scores, not paths)
        if _NUMERIC_SLASH_PATTERN.match(target):
            return False

        # Skip template placeholder paths (YYYYMMDD, <placeholder>, etc.)
        if _PLACEHOLDER_PATTERN.search(target):
            return False

        # Skip targets that contain whitespace beyond a simple path
        # (e.g. "pwsh.exe -ExecutionPolicy Bypass ...")
        if " " in target and not os.path.sep == " ":
            return False

        # Bare filenames without any path separator (e.g. "Script.ps1") are
        # typically prose mentions, not navigable references.  Only check
        # targets that contain a path component (/ or \).
        if "/" not in target and "\\" not in target and not target.startswith("."):
            return False

        # Apply the existing heuristic — must look like a file or dir path
        if not looks_like_file_path(target):
            # Also accept directory-like targets (end with / or \)
            if not target.endswith("/") and not target.endswith("\\"):
                return False

        return True

    @staticmethod
    def _get_code_block_lines(file_path: str) -> FrozenSet[int]:
        """Return the set of 1-based line numbers inside fenced code blocks.

        Only looks for ``` and ~~~ fences (the two CommonMark fence markers).
        """
        code_lines: set = set()
        in_block = False
        try:
            with open(file_path, "r", encoding="utf-8", errors="replace") as fh:
                for lineno, line in enumerate(fh, start=1):
                    if _FENCE_RE.match(line):
                        if in_block:
                            # Closing fence — this line is still part of the block
                            code_lines.add(lineno)
                        in_block = not in_block
                        continue
                    if in_block:
                        code_lines.add(lineno)
        except OSError:
            pass
        return frozenset(code_lines)

    def _target_exists_at_root(self, target: str) -> bool:
        """Check whether *target* exists when resolved against project root."""
        # Strip anchor
        if "#" in target:
            target = target.split("#", 1)[0]
            if not target:
                return True
        resolved = os.path.normpath(os.path.join(self.project_root, target))
        return os.path.exists(resolved)

    def _target_exists(self, source_file: str, target: str) -> bool:
        """Resolve *target* relative to *source_file* and check existence."""
        # Strip anchor (e.g. file.md#section → file.md)
        if "#" in target:
            target = target.split("#", 1)[0]
            if not target:
                # Pure anchor link (#section) — always valid within the file
                return True

        # Root-relative paths (starting with /) resolve against project root.
        # This is the convention used by markdown links in this project:
        # [text](/doc/process-framework/...) means <project_root>/doc/...
        if target.startswith("/"):
            resolved = os.path.normpath(os.path.join(self.project_root, target.lstrip("/")))
        else:
            # Resolve relative to the directory containing the source file
            source_dir = os.path.dirname(source_file)
            resolved = os.path.normpath(os.path.join(source_dir, target))

        return os.path.exists(resolved)

    # ------------------------------------------------------------------
    # Report formatting
    # ------------------------------------------------------------------

    @staticmethod
    def format_report(result: ValidationResult) -> str:
        """Return a human-readable text report."""
        lines: List[str] = []
        lines.append("=" * 60)
        lines.append("LinkWatcher - Link Validation Report")
        lines.append("=" * 60)
        lines.append("")
        lines.append(f"Files scanned : {result.files_scanned}")
        lines.append(f"Links checked : {result.links_checked}")
        lines.append(f"Broken links  : {len(result.broken_links)}")
        lines.append(f"Duration      : {result.duration_seconds:.2f}s")
        lines.append("")

        if result.is_clean:
            lines.append("No broken links found.")
        else:
            lines.append("Broken links:")
            lines.append("-" * 60)
            for bl in result.broken_links:
                lines.append(f"  {bl.source_file}:{bl.line_number}")
                lines.append(f"    -> {bl.target_path}  ({bl.link_type})")
            lines.append("-" * 60)

        lines.append("")
        return "\n".join(lines)

    @staticmethod
    def write_report(result: ValidationResult, output_dir: str) -> str:
        """Write the report to *output_dir*/LinkWatcherBrokenLinks.txt.

        Returns the absolute path of the written file.
        """
        os.makedirs(output_dir, exist_ok=True)
        report_path = os.path.join(output_dir, "LinkWatcherBrokenLinks.txt")
        with open(report_path, "w", encoding="utf-8") as fh:
            fh.write(LinkValidator.format_report(result))
        return report_path
