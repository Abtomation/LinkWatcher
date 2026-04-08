"""
Link validation module for the LinkWatcher system.

Provides on-demand workspace scanning to detect broken file references
across all supported file formats. Read-only operation — does not modify
any files.

AI Context
----------
- **Entry point**: ``LinkValidator.validate()`` — scans the workspace
  and returns a ``ValidationResult`` with all broken links found.
  Invoked via ``python main.py --validate`` or
  ``LinkWatcherService.check_links()``.
- **Delegation**: validator → parser (link extraction per file),
  ``_target_exists()`` (path resolution and existence check).
  Standalone from the live-watching pipeline — no database dependency.
- **Common tasks**:
  - Adding a file type to validation: ensure the parser handles it and
    ``should_monitor_file()`` includes the extension.
  - Debugging false positives: check ``_should_check_target()`` for
    skip patterns (URLs, anchors, templates) and
    ``EXTRA_IGNORED_DIRS`` for excluded directories.
  - Debugging false negatives: check ``_target_exists()`` path
    resolution — it tries both direct and case-insensitive matching.
"""

import fnmatch
import os
import re
import time
from collections import defaultdict
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, FrozenSet, List, Optional, Tuple

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


# ---------------------------------------------------------------------------
# Skip-pattern constants — used by _should_skip_target() to reject non-path
# strings (URLs, shell commands, globs, numeric fractions, extension-before-
# slash alternatives, and template placeholders).
# ---------------------------------------------------------------------------

# Prefixes that indicate a URL rather than a local file path.
_URL_PREFIXES = ("http://", "https://", "ftp://", "mailto:", "tel:", "data:")

# NOTE: Extra ignored directories for validation are now configurable via
# LinkWatcherConfig.validation_extra_ignored_dirs (default: LinkWatcher_run,
# old, archive, fixtures, e2e-acceptance-testing, config-examples).

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

# Slash-separated alternatives where a segment before the last "/" has a file
# extension (e.g. "logging.py/logging_config.py").  Requires at least one
# word character before the dot so dotfile dirs (.git/, .vscode/) are safe.
_EXT_BEFORE_SLASH_PATTERN = re.compile(r"\w\.\w{1,6}/")

# Template placeholders that are not real paths.
# Matches: YYYY, XXXX, HHMMSS, <angle-bracket>, [square-bracket] placeholders.
_PLACEHOLDER_PATTERN = re.compile(r"YYYY|XXX|HHMMSS|<[^>]+>|\[[a-z][a-z-]*\]")

# ---------------------------------------------------------------------------
# Link-type classification constants — categorise link types for special
# resolution logic (code-block skipping, project-root fallback).
# ---------------------------------------------------------------------------

# Link types that represent bare/standalone path text (no explicit link syntax).
# These are safe to skip inside fenced code blocks because real references in
# code blocks use proper link syntax ([text](path)) which has its own link_type.
_STANDALONE_LINK_TYPES: frozenset = frozenset(
    {
        "markdown-standalone",
        "markdown-quoted",
        "markdown-quoted-dir",
        "markdown-backtick",
        "markdown-backtick-dir",
        "markdown-bare-path",
        "markdown-at-prefix",
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

# NOTE: File extensions for validation are now configurable via
# LinkWatcherConfig.validation_extensions (default: .md, .yaml, .yml, .json).
# Source code files (.py, .ps1, etc.) are excluded by default because they
# contain string literals that are data values, not document cross-references.

# ---------------------------------------------------------------------------
# Markdown structure constants — used to track code-block fences and
# <details> archival sections so that standalone links inside them can be
# skipped (proper [text](path) links are still checked).
# ---------------------------------------------------------------------------

# Regex matching the opening/closing fence of a code block (``` or ~~~).
_FENCE_RE = re.compile(r"^[ \t]*(```|~~~)")

# Keywords in <details><summary> that indicate archival/closed content.
# Standalone links inside these sections are skipped (same principle as
# code blocks: proper [text](path) links are still checked).
_ARCHIVAL_SUMMARY_KEYWORDS = {"closed", "history", "completed", "archived"}

# Regex to extract <summary> text from a <details> block opener.
_DETAILS_OPEN_RE = re.compile(r"<details>", re.IGNORECASE)
_DETAILS_CLOSE_RE = re.compile(r"</details>", re.IGNORECASE)
_SUMMARY_RE = re.compile(r"<summary[^>]*>(.*?)</summary>", re.IGNORECASE | re.DOTALL)


class LinkValidator:
    """
    Scans a workspace and reports broken local file references.

    Reuses the existing LinkParser infrastructure to extract links,
    then resolves each target relative to its source file and checks
    whether it exists on disk.
    """

    def __init__(self, project_root: str, config: Optional[LinkWatcherConfig] = None):
        """Initialise the validator for the given project root.

        Args:
            project_root: Absolute or relative path to the workspace root.
                          Resolved to an absolute path internally.
            config: Optional configuration; defaults are used when *None*.
        """
        self.project_root = str(Path(project_root).resolve())
        self.config = config or LinkWatcherConfig()
        self.parser = LinkParser(self.config)
        self.logger = get_logger()
        self._validation_extensions = self.config.validation_extensions
        self._extra_ignored_dirs = self.config.validation_extra_ignored_dirs
        self._ignore_rules = self._load_ignore_file()
        self._exists_cache: Dict[str, bool] = {}

    def validate(self) -> ValidationResult:
        """Walk the workspace, parse every monitored file, and check links."""
        self._exists_cache.clear()
        result = ValidationResult()
        start = time.monotonic()

        self.logger.info(
            "validation_started",
            project_root=self.project_root,
        )

        ignored_dirs = self.config.ignored_directories | self._extra_ignored_dirs

        ext_timings: Dict[str, float] = defaultdict(float)

        for root, dirs, files in os.walk(self.project_root):
            # Prune ignored directories in-place (same pattern as _initial_scan)
            dirs[:] = [d for d in dirs if d not in ignored_dirs]

            for filename in files:
                file_path = os.path.join(root, filename)

                # Only validate documentation files — source code files (.py,
                # .ps1, etc.) contain string/comment paths that are data values,
                # not document cross-references.
                if not should_monitor_file(file_path, self._validation_extensions, ignored_dirs):
                    continue

                file_start = time.monotonic()
                self._check_file(file_path, result)
                file_elapsed = time.monotonic() - file_start

                ext = os.path.splitext(filename)[1].lower() or "(no ext)"
                ext_timings[ext] += file_elapsed

                self.logger.debug(
                    "validation_file_checked",
                    file_path=file_path,
                    extension=ext,
                    duration_ms=round(file_elapsed * 1000, 1),
                )

        result.duration_seconds = time.monotonic() - start

        if ext_timings:
            self.logger.debug(
                "validation_timing_by_extension",
                timings={
                    ext: round(secs * 1000, 1)
                    for ext, secs in sorted(ext_timings.items(), key=lambda x: x[1], reverse=True)
                },
            )

        self.logger.info(
            "validation_complete",
            files_scanned=result.files_scanned,
            links_checked=result.links_checked,
            broken_count=len(result.broken_links),
            duration_seconds=round(result.duration_seconds, 2),
        )

        return result

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    def _check_file(self, file_path: str, result: ValidationResult) -> None:
        """Parse a single file and verify every link target."""
        try:
            with open(file_path, "r", encoding="utf-8", errors="replace") as fh:
                content = fh.read()
        except OSError as exc:
            self.logger.warning(
                "validation_parse_failed",
                file_path=file_path,
                error=str(exc),
            )
            return

        try:
            references: List[LinkReference] = self.parser.parse_content(content, file_path)
        except Exception as exc:
            self.logger.warning(
                "validation_parse_failed",
                file_path=file_path,
                error=str(exc),
            )
            return

        result.files_scanned += 1

        # For markdown files, identify fenced code block lines, archival
        # <details> sections, and table rows so we can skip standalone
        # (bare-path) links inside them.  Proper [text](path) links are
        # still checked.
        code_block_lines: FrozenSet[int] = frozenset()
        archival_details_lines: FrozenSet[int] = frozenset()
        table_row_lines: FrozenSet[int] = frozenset()
        placeholder_lines: FrozenSet[int] = frozenset()
        if file_path.lower().endswith(".md"):
            lines = content.splitlines()
            code_block_lines = self._get_code_block_lines(lines)
            archival_details_lines = self._get_archival_details_lines(lines)
            table_row_lines = self._get_table_row_lines(lines, code_block_lines)
            placeholder_lines = self._get_placeholder_lines(lines)

        # Template files (under any templates/ directory) contain placeholder
        # paths that are instructional examples, not real references.  Skip
        # standalone/quoted link types there; proper [text](path) links are
        # still checked.
        rel_path = os.path.relpath(file_path, self.project_root).replace("\\", "/")
        is_template_file = "/templates/" in rel_path

        # Build the set of ignored patterns from config
        ignored_patterns = self.config.validation_ignored_patterns

        for ref in references:
            target = ref.link_target

            if not self._should_check_target(target, ref.link_type):
                continue

            if self._should_skip_reference(
                ref,
                ignored_patterns,
                code_block_lines,
                archival_details_lines,
                table_row_lines,
                placeholder_lines,
                is_template_file,
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
                    and not target.startswith(("/", "./", "../", "\\"))
                    and self._target_exists_at_root(target)
                ):
                    continue

                rel_source = os.path.relpath(file_path, self.project_root).replace("\\", "/")

                # Check per-file ignore rules from .linkwatcher-ignore
                if self._is_ignored(rel_source, target):
                    continue

                self.logger.warning(
                    "broken_link_found",
                    source_file=rel_source,
                    line_number=ref.line_number,
                    target_path=target,
                    link_type=ref.link_type,
                )

                result.broken_links.append(
                    BrokenLink(
                        source_file=rel_source,
                        line_number=ref.line_number,
                        target_path=target,
                        link_type=ref.link_type,
                    )
                )

    @staticmethod
    def _should_skip_reference(
        ref: LinkReference,
        ignored_patterns: FrozenSet[str],
        code_block_lines: FrozenSet[int],
        archival_details_lines: FrozenSet[int],
        table_row_lines: FrozenSet[int],
        placeholder_lines: FrozenSet[int],
        is_template_file: bool,
    ) -> bool:
        """Decide whether a parsed reference should be skipped based on context.

        Checks user-configured ignored patterns, then applies context-based
        skip rules for standalone link types (code blocks, archival sections,
        template files, placeholder lines, table rows).
        """
        target = ref.link_target

        # Skip targets matching user-configured ignored patterns
        if ignored_patterns and any(p in target for p in ignored_patterns):
            return True

        # Skip all link types on lines with placeholder instructions
        # like "*(replace with actual link)*" — these are template examples.
        if placeholder_lines and ref.line_number in placeholder_lines:
            return True

        # Remaining checks apply only to standalone (bare-path) link types.
        # Proper [text](path) links are always checked regardless of context.
        if ref.link_type not in _STANDALONE_LINK_TYPES:
            return False

        # Skip standalone links in template files (placeholder paths)
        if is_template_file:
            return True

        # Skip standalone links inside fenced code blocks, archival
        # <details> sections, or markdown table rows.
        line = ref.line_number
        if code_block_lines and line in code_block_lines:
            return True
        if archival_details_lines and line in archival_details_lines:
            return True
        if table_row_lines and line in table_row_lines:
            return True

        return False

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

        # Skip slash-separated alternatives like "logging.py/logging_config.py"
        # where a directory segment has a file extension (not a real path).
        if _EXT_BEFORE_SLASH_PATTERN.search(target):
            return False

        # Skip targets containing regex metacharacters that aren't valid in
        # file paths (e.g. "[^\'"]+\.[a-zA-Z0-9]+" extracted from code).
        # Only filter chars that are truly impossible in paths: ^ { } |
        # (+ and $ can appear in real paths like c++/config.h or $HOME)
        if any(c in target for c in "^{}|"):
            return False

        # Skip regex fragments: "]+" (one-or-more bracket) and "\["
        # (escaped bracket) never appear in legitimate file paths.
        if "]+" in target or "\\[" in target:
            return False

        # Skip PowerShell invocation syntax (.\Script.ps1) — these are
        # command examples, not file references from the document location.
        if target.startswith(".\\") and target.lower().endswith(".ps1"):
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
    def _get_code_block_lines(lines: List[str]) -> FrozenSet[int]:
        """Return the set of 1-based line numbers inside fenced code blocks.

        Only looks for ``` and ~~~ fences (the two CommonMark fence markers).
        Accepts pre-read lines (from str.splitlines()) to avoid re-reading the file.
        """
        code_lines: set = set()
        in_block = False
        for lineno, line in enumerate(lines, start=1):
            if _FENCE_RE.match(line):
                if in_block:
                    # Closing fence — this line is still part of the block
                    code_lines.add(lineno)
                in_block = not in_block
                continue
            if in_block:
                code_lines.add(lineno)
        return frozenset(code_lines)

    @staticmethod
    def _get_archival_details_lines(lines: List[str]) -> FrozenSet[int]:
        """Return line numbers inside <details> blocks whose <summary> signals
        archival content (closed, history, completed, archived).

        Only standalone/quoted link types are skipped in these regions —
        proper [text](path) links are still validated.
        Accepts pre-read lines (from str.splitlines()) to avoid re-reading the file.
        """
        archival_lines: set = set()
        in_details = False
        is_archival = False
        # Buffer summary text across lines (summary may follow <details>)
        pending_summary_check = False
        for lineno, line in enumerate(lines, start=1):
            if _DETAILS_OPEN_RE.search(line):
                in_details = True
                is_archival = False
                pending_summary_check = True
                # Check if <summary> is on the same line as <details>
                summary_match = _SUMMARY_RE.search(line)
                if summary_match:
                    summary_text = summary_match.group(1).lower()
                    # Strip HTML tags from summary text
                    summary_text = re.sub(r"<[^>]+>", "", summary_text)
                    is_archival = any(kw in summary_text for kw in _ARCHIVAL_SUMMARY_KEYWORDS)
                    pending_summary_check = False
                continue

            if pending_summary_check and in_details:
                # Check next lines for <summary>
                summary_match = _SUMMARY_RE.search(line)
                if summary_match:
                    summary_text = summary_match.group(1).lower()
                    summary_text = re.sub(r"<[^>]+>", "", summary_text)
                    is_archival = any(kw in summary_text for kw in _ARCHIVAL_SUMMARY_KEYWORDS)
                    pending_summary_check = False
                elif not line.strip():
                    # Empty line — keep waiting
                    pass
                else:
                    # Non-summary content — no summary tag found
                    pending_summary_check = False

            if _DETAILS_CLOSE_RE.search(line):
                if is_archival:
                    archival_lines.add(lineno)
                in_details = False
                is_archival = False
                continue

            if in_details and is_archival:
                archival_lines.add(lineno)
        return frozenset(archival_lines)

    @staticmethod
    def _get_table_row_lines(lines: List[str], code_block_lines: FrozenSet[int]) -> FrozenSet[int]:
        """Return 1-based line numbers of markdown table rows.

        A line is a table row if it starts with ``|`` (after optional
        whitespace) and is not inside a fenced code block.
        """
        table_lines: set = set()
        for lineno, line in enumerate(lines, start=1):
            if lineno in code_block_lines:
                continue
            stripped = line.lstrip()
            if stripped.startswith("|"):
                table_lines.add(lineno)
        return frozenset(table_lines)

    @staticmethod
    def _get_placeholder_lines(lines: List[str]) -> FrozenSet[int]:
        """Return 1-based line numbers containing placeholder instructions.

        Lines with phrases like ``*(replace with actual link)*`` indicate
        that every link on that line is an intentional template example,
        not a real reference.
        """
        placeholder_lines: set = set()
        for lineno, line in enumerate(lines, start=1):
            if "replace with actual" in line.lower():
                placeholder_lines.add(lineno)
        return frozenset(placeholder_lines)

    @staticmethod
    def _glob_to_regex(pattern: str) -> re.Pattern:
        """Convert a glob pattern with ``**`` support to a compiled regex.

        ``**`` matches zero or more path segments (including none).
        ``*`` matches anything within a single path segment.
        """
        parts = pattern.replace("\\", "/").split("**/")
        regex_parts = [fnmatch.translate(p).rstrip(r"\Z").rstrip("$") for p in parts]
        # fnmatch.translate anchors with \Z — strip it so we can rejoin.
        # Between parts separated by **, allow zero or more directory levels.
        combined = r"(?:.+/)?".join(regex_parts)
        # Re-anchor
        return re.compile(combined + r"\Z", re.DOTALL)

    def _load_ignore_file(self) -> List[Tuple[re.Pattern, str]]:
        """Load per-file ignore rules from ``.linkwatcher-ignore`` at project root.

        File format (one rule per line)::

            # Comment lines start with #
            source_glob -> target_substring
            process-framework/templates**/*.md -> related-design.md
            doc/validation/reports/**/*.md -> docs/README.md

        Returns a list of (compiled_source_regex, target_substring) tuples.
        """
        ignore_path = os.path.join(self.project_root, self.config.validation_ignore_file)
        rules: List[Tuple[re.Pattern, str]] = []
        if not os.path.isfile(ignore_path):
            return rules
        try:
            with open(ignore_path, "r", encoding="utf-8") as fh:
                for line in fh:
                    line = line.strip()
                    if not line or line.startswith("#"):
                        continue
                    if " -> " not in line:
                        continue
                    source_glob, target_pattern = line.split(" -> ", 1)
                    compiled = self._glob_to_regex(source_glob.strip())
                    rules.append((compiled, target_pattern.strip()))
        except OSError:
            pass
        return rules

    def _is_ignored(self, rel_source: str, target: str) -> bool:
        """Check whether a broken link is suppressed by ``.linkwatcher-ignore`` rules."""
        for source_re, target_pattern in self._ignore_rules:
            if source_re.match(rel_source) and target_pattern in target:
                return True
        return False

    def _target_exists_at_root(self, target: str) -> bool:
        """Check whether *target* exists when resolved against project root."""
        # Strip anchor
        if "#" in target:
            target = target.split("#", 1)[0]
            if not target:
                return True
        resolved = os.path.normpath(os.path.join(self.project_root, target))
        if resolved not in self._exists_cache:
            self._exists_cache[resolved] = os.path.exists(resolved)
        return self._exists_cache[resolved]

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
        # [text](/process-framework/...) means <project_root>/doc/...
        if target.startswith("/"):
            resolved = os.path.normpath(os.path.join(self.project_root, target.lstrip("/")))
        else:
            # Resolve relative to the directory containing the source file
            source_dir = os.path.dirname(source_file)
            resolved = os.path.normpath(os.path.join(source_dir, target))

        if resolved not in self._exists_cache:
            self._exists_cache[resolved] = os.path.exists(resolved)
        return self._exists_cache[resolved]

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
