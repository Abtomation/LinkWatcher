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
from .link_types import LinkType
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
# Explicit link syntax types — link types where the author wrote deliberate
# link markup, so bare filenames (no path separator) are valid targets.
# E.g. [text](file.md), [label]: file.md, <a href="file.md">.
# All other link types use heuristic/standalone detection where bare names
# are more likely prose mentions than intentional links.  (BUG-088)
# ---------------------------------------------------------------------------

_EXPLICIT_LINK_TYPES: frozenset = frozenset(
    {
        LinkType.MARKDOWN,
        LinkType.MARKDOWN_REFERENCE,
        LinkType.HTML_ANCHOR,
    }
)

# ---------------------------------------------------------------------------
# Target-skip predicates — each returns True when a target should be skipped.
# Used by ``_should_check_target()`` to filter non-path strings.
# ---------------------------------------------------------------------------

_TARGET_SKIP_PREDICATES: tuple = (
    # URLs
    (lambda t, lt: t.startswith(_URL_PREFIXES), "URL prefix"),
    # Python import targets (module paths, not file paths)
    (lambda t, lt: lt == LinkType.PYTHON_IMPORT, "python-import link type"),
    # Shell commands / CLI invocations
    (lambda t, lt: bool(_COMMAND_PATTERN.match(t)), "shell command"),
    # Wildcard / glob patterns (e.g. *.md, **/*.py)
    (lambda t, lt: bool(_WILDCARD_PATTERN.search(t)), "wildcard/glob"),
    # Numeric/slash patterns like "3.475/4.0" (scores, not paths)
    (lambda t, lt: bool(_NUMERIC_SLASH_PATTERN.match(t)), "numeric/slash score"),
    # Slash-separated alternatives where a segment has a file extension
    (lambda t, lt: bool(_EXT_BEFORE_SLASH_PATTERN.search(t)), "ext-before-slash"),
    # Regex metacharacters impossible in paths: ^ { } |
    (lambda t, lt: any(c in t for c in "^{}|"), "regex metachar"),
    # Regex fragments: ]+ or \[
    (lambda t, lt: "]+" in t or "\\[" in t, "regex fragment"),
    # PowerShell .\Script.ps1 invocation syntax
    (
        lambda t, lt: t.startswith(".\\") and t.lower().endswith(".ps1"),
        "PowerShell .\\",
    ),
    # Template placeholder paths
    (lambda t, lt: bool(_PLACEHOLDER_PATTERN.search(t)), "template placeholder"),
    # Whitespace beyond a simple path
    (lambda t, lt: " " in t, "contains whitespace"),
    # Bare filenames without any path separator — skip unless the link type
    # uses explicit link syntax where bare filenames are valid targets
    # (e.g. [text](file.md), [label]: file.md, <a href="file.md">).  (BUG-088)
    (
        lambda t, lt: lt not in _EXPLICIT_LINK_TYPES
        and "/" not in t
        and "\\" not in t
        and not t.startswith("."),
        "bare filename",
    ),
)

# ---------------------------------------------------------------------------
# Link-type classification constants — categorise link types for special
# resolution logic (code-block skipping, project-root fallback).
# ---------------------------------------------------------------------------

# Link types that represent bare/standalone path text (no explicit link syntax).
# These are safe to skip inside fenced code blocks because real references in
# code blocks use proper link syntax ([text](path)) which has its own link_type.
_STANDALONE_LINK_TYPES: frozenset = frozenset(
    {
        LinkType.MARKDOWN_STANDALONE,
        LinkType.MARKDOWN_QUOTED,
        LinkType.MARKDOWN_QUOTED_DIR,
        LinkType.MARKDOWN_BACKTICK,
        LinkType.MARKDOWN_BACKTICK_DIR,
        LinkType.MARKDOWN_BARE_PATH,
        LinkType.MARKDOWN_AT_PREFIX,
    }
)

# Link types whose paths are data values (config entries, registry fields,
# prose mentions) rather than explicit navigable links.  These commonly use
# project-root-relative paths regardless of the source file's location, so
# the validator applies a project-root fallback before flagging them broken.
_DATA_VALUE_LINK_TYPES: frozenset = _STANDALONE_LINK_TYPES | frozenset(
    {
        LinkType.YAML,
        LinkType.YAML_DIR,
        LinkType.JSON,
        LinkType.JSON_DIR,
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
                if not should_monitor_file(
                    file_path, self._validation_extensions, ignored_dirs, self.project_root
                ):
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
            for ext, secs in sorted(ext_timings.items(), key=lambda x: x[1], reverse=True):
                self.logger.performance.log_metric(
                    "validation_extension_duration",
                    round(secs * 1000, 1),
                    unit="ms",
                    extension=ext,
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
            (
                code_block_lines,
                archival_details_lines,
                table_row_lines,
                placeholder_lines,
            ) = self._get_context_lines(lines)

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
                    and not target.startswith(("/", "./", "../../..", "\\"))
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
        and strings that don't look like file paths.  Each filter is defined
        in the module-level ``_TARGET_SKIP_PREDICATES`` tuple for easy
        extension and independent testability.
        """
        if any(pred(target, link_type) for pred, _ in _TARGET_SKIP_PREDICATES):
            return False

        # Apply the existing heuristic — must look like a file or dir path
        if not looks_like_file_path(target):
            # Also accept directory-like targets (end with / or \)
            if not target.endswith("/") and not target.endswith("\\"):
                return False

        return True

    @staticmethod
    def _get_context_lines(
        lines: List[str],
    ) -> Tuple[FrozenSet[int], FrozenSet[int], FrozenSet[int], FrozenSet[int]]:
        """Classify markdown lines by context in a single pass.

        Returns (code_block_lines, archival_details_lines, table_row_lines,
        placeholder_lines) — four frozensets of 1-based line numbers.

        Combines what were previously four separate O(n) passes into one.
        """
        code_lines: set = set()
        archival_lines: set = set()
        table_lines: set = set()
        placeholder_lines_set: set = set()

        # Code-block state
        in_block = False

        # Archival <details> state
        in_details = False
        is_archival = False
        pending_summary_check = False

        for lineno, line in enumerate(lines, start=1):
            # --- Code blocks ---
            if _FENCE_RE.match(line):
                if in_block:
                    code_lines.add(lineno)
                in_block = not in_block
                # Fence lines are not table rows or placeholder lines,
                # but archival tracking continues across fences.
                # Fall through to archival detection below.
            elif in_block:
                code_lines.add(lineno)

            # --- Archival <details> ---
            if _DETAILS_OPEN_RE.search(line):
                in_details = True
                is_archival = False
                pending_summary_check = True
                summary_match = _SUMMARY_RE.search(line)
                if summary_match:
                    summary_text = summary_match.group(1).lower()
                    summary_text = re.sub(r"<[^>]+>", "", summary_text)
                    is_archival = any(kw in summary_text for kw in _ARCHIVAL_SUMMARY_KEYWORDS)
                    pending_summary_check = False
            elif _DETAILS_CLOSE_RE.search(line):
                if is_archival:
                    archival_lines.add(lineno)
                in_details = False
                is_archival = False
                pending_summary_check = False
            else:
                if pending_summary_check and in_details:
                    summary_match = _SUMMARY_RE.search(line)
                    if summary_match:
                        summary_text = summary_match.group(1).lower()
                        summary_text = re.sub(r"<[^>]+>", "", summary_text)
                        is_archival = any(kw in summary_text for kw in _ARCHIVAL_SUMMARY_KEYWORDS)
                        pending_summary_check = False
                    elif line.strip():
                        pending_summary_check = False
                if in_details and is_archival:
                    archival_lines.add(lineno)

            # --- Table rows (only outside code blocks) ---
            if not in_block:
                stripped = line.lstrip()
                if stripped.startswith("|"):
                    table_lines.add(lineno)

            # --- Placeholder lines ---
            if "replace with actual" in line.lower():
                placeholder_lines_set.add(lineno)

        return (
            frozenset(code_lines),
            frozenset(archival_lines),
            frozenset(table_lines),
            frozenset(placeholder_lines_set),
        )

    @staticmethod
    def _glob_to_regex(pattern: str) -> re.Pattern:
        """Convert a glob pattern with ``**`` support to a compiled regex.

        ``**`` matches zero or more path segments (including none).
        ``*`` matches anything within a single path segment.
        """
        parts = pattern.replace("\\", "/").split("**/")
        regex_parts = [fnmatch.translate(p).removesuffix(r"\Z").removesuffix("$") for p in parts]
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
