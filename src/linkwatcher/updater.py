"""
Link updater for modifying files when links need to be updated.

This module handles the actual file modifications when links need to be
updated due to file moves or renames. Path resolution is delegated to
PathResolver (linkwatcher.path_resolver).

AI Context
----------
- **Entry point**: ``LinkUpdater.update_references_in_file()`` — called
  by handler after a move is detected to rewrite link targets in a
  single source file.
- **Delegation**: updater → PathResolver (new relative path calculation),
  parser-specific replace methods (``_replace_markdown_target``, etc.).
  File I/O uses atomic tempfile-write + rename pattern.
- **Common tasks**:
  - Adding a new file format: add a ``_replace_<format>_target()``
    method and wire it into ``_replace_reference_target()``.
  - Debugging failed updates: check ``UpdateResult`` return value —
    ``STALE`` means the old link text was not found in the file
    (file changed between scan and update).
  - Understanding backup behavior: controlled by ``self.backup_enabled``
    and ``config.create_backups``.  Backups are ``.bak`` files created
    before each write.
"""

import os
import re
import shutil
import tempfile
from enum import Enum
from pathlib import Path
from typing import Dict, List, Tuple, TypedDict

from .link_types import LinkType
from .logging import get_logger
from .models import LinkReference
from .path_resolver import PathResolver


class UpdateStats(TypedDict):
    """Statistics returned by update_references()."""

    files_updated: int
    references_updated: int
    errors: int
    stale_files: List[str]


class UpdateResult(Enum):
    """Result of updating references in a single file."""

    UPDATED = "updated"
    STALE = "stale"
    NO_CHANGES = "no_changes"


class LinkUpdater:
    """
    Handles updating link references in files when targets change.
    Uses proper file handling to ensure atomic updates and backup safety.
    Delegates path resolution to PathResolver.
    """

    def __init__(self, project_root: str = ".", python_source_root: str = ""):
        self.backup_enabled = True
        self.dry_run = False
        self.project_root = Path(project_root).resolve()
        self.logger = get_logger()
        self.path_resolver = PathResolver(
            project_root, self.logger, python_source_root=python_source_root
        )
        self._regex_cache: Dict[str, re.Pattern] = {}
        self._REGEX_CACHE_MAX_SIZE = 1024

    def update_references(
        self, references: List[LinkReference], old_path: str, new_path: str
    ) -> UpdateStats:
        """
        Update all references from old_path to new_path.

        Returns:
            Dict with statistics: {'files_updated': int, 'references_updated': int, 'errors': int}
        """
        stats = {"files_updated": 0, "references_updated": 0, "errors": 0, "stale_files": []}

        # Group references by file for efficient processing
        files_to_update = self._group_references_by_file(references)

        for file_path, file_references in files_to_update.items():
            try:
                result = self._update_file_references(
                    file_path, file_references, old_path, new_path
                )
                if result == UpdateResult.UPDATED:
                    stats["files_updated"] += 1
                    stats["references_updated"] += len(file_references)
                    self.logger.links_updated(file_path, len(file_references))
                elif result == UpdateResult.STALE:
                    stats["stale_files"].append(file_path)
                    self.logger.warning(
                        "stale_references_detected",
                        file_path=file_path,
                        references_count=len(file_references),
                    )
                else:
                    self.logger.debug("no_changes_needed", file_path=file_path)
            except Exception as e:
                stats["errors"] += 1
                self.logger.error(
                    "file_update_failed",
                    file_path=file_path,
                    error=str(e),
                    error_type=type(e).__name__,
                )

        return stats

    def update_references_batch(
        self,
        move_groups: List[Tuple[List[LinkReference], str, str]],
    ) -> UpdateStats:
        """Update references for multiple old→new path pairs in a single pass.

        Groups all references by their containing file so each file is opened,
        modified, and written at most once — even when many moved files are
        referenced from the same source file.

        Args:
            move_groups: List of (references, old_path, new_path) tuples.

        Returns:
            Aggregated UpdateStats across all groups.
        """
        stats: UpdateStats = {
            "files_updated": 0,
            "references_updated": 0,
            "errors": 0,
            "stale_files": [],
        }

        # Build a per-source-file list of (ref, old_path, new_path)
        file_work: Dict[str, List[Tuple[LinkReference, str, str]]] = {}
        for references, old_path, new_path in move_groups:
            for ref in references:
                file_work.setdefault(ref.file_path, []).append((ref, old_path, new_path))

        for file_path, ref_tuples in file_work.items():
            try:
                result = self._update_file_references_multi(file_path, ref_tuples)
                if result == UpdateResult.UPDATED:
                    stats["files_updated"] += 1
                    stats["references_updated"] += len(ref_tuples)
                    self.logger.links_updated(file_path, len(ref_tuples))
                elif result == UpdateResult.STALE:
                    stats["stale_files"].append(file_path)
                    self.logger.warning(
                        "stale_references_detected",
                        file_path=file_path,
                        references_count=len(ref_tuples),
                    )
                else:
                    self.logger.debug("no_changes_needed", file_path=file_path)
            except Exception as e:
                stats["errors"] += 1
                self.logger.error(
                    "file_update_failed",
                    file_path=file_path,
                    error=str(e),
                    error_type=type(e).__name__,
                )

        return stats

    def _group_references_by_file(
        self, references: List[LinkReference]
    ) -> Dict[str, List[LinkReference]]:
        """Group references by their containing file."""
        files = {}
        for ref in references:
            if ref.file_path not in files:
                files[ref.file_path] = []
            files[ref.file_path].append(ref)
        return files

    def _update_file_references(
        self, file_path: str, references: List[LinkReference], old_path: str, new_path: str
    ) -> UpdateResult:
        """Update references in a single file for one old→new path pair."""
        if not os.path.isabs(file_path):
            abs_file_path = os.path.join(self.project_root, file_path)
        else:
            abs_file_path = file_path

        if self.dry_run:
            self.logger.info(
                "dry_run_skip",
                file_path=abs_file_path,
                references_count=len(references),
            )
            return UpdateResult.UPDATED

        # Build (ref, new_target) pairs, filtering out no-change items
        replacement_items = []
        for ref in references:
            new_target = self._calculate_new_target(ref, old_path, new_path)
            if new_target != ref.link_target:
                replacement_items.append((ref, new_target))

        if not replacement_items:
            return UpdateResult.NO_CHANGES

        return self._apply_replacements(abs_file_path, file_path, replacement_items)

    def _update_file_references_multi(
        self,
        file_path: str,
        ref_tuples: List[Tuple[LinkReference, str, str]],
    ) -> UpdateResult:
        """Update references in a single file for multiple old→new path pairs.

        Processes all path replacements in one read→modify→write cycle.
        Each ref_tuple is (reference, old_path, new_path).
        """
        if not os.path.isabs(file_path):
            abs_file_path = os.path.join(self.project_root, file_path)
        else:
            abs_file_path = file_path

        if self.dry_run:
            self.logger.info(
                "dry_run_skip",
                file_path=abs_file_path,
                references_count=len(ref_tuples),
            )
            return UpdateResult.UPDATED

        # Build (ref, new_target) pairs, computing new_target for each move
        replacement_items = []
        for ref, old_path, new_path in ref_tuples:
            new_target = self._calculate_new_target(ref, old_path, new_path)
            if new_target != ref.link_target:
                replacement_items.append((ref, new_target))

        if not replacement_items:
            return UpdateResult.NO_CHANGES

        return self._apply_replacements(abs_file_path, file_path, replacement_items)

    def _apply_replacements(
        self,
        abs_file_path: str,
        file_path: str,
        replacement_items: List[Tuple[LinkReference, str]],
    ) -> UpdateResult:
        """Apply pre-computed replacements to a single file.

        Algorithm (two phases):
          Phase 1 — Line-by-line replacement (bottom-to-top order to preserve
          line/column positions). For each reference, performs stale-detection
          checks and replaces the old target on the matched line. Python-import
          module renames are collected for Phase 2.

          Phase 2 — File-wide Python module usage replacement (PD-BUG-045).
          When a Python import statement is renamed (e.g. "utils.helpers" →
          "core.helpers"), all usages of the old module name elsewhere in the
          file are replaced using a regex with negative lookbehind ``(?<![.\w])``
          and negative lookahead ``(?!\w)`` around the escaped module name.
          PD-BUG-094 replaced the original ``\b…\b`` boundaries because plain
          ``\b`` fires between ``.`` and a letter, causing double-application
          of prefixes when an updated path is rescanned.

        Args:
            abs_file_path: Absolute path to the file.
            file_path: Original (possibly relative) path for log messages.
            replacement_items: Pre-filtered list of (reference, new_target) pairs
                where new_target differs from ref.link_target.

        Returns:
            UpdateResult.UPDATED if file was modified,
            UpdateResult.NO_CHANGES if no changes needed,
            UpdateResult.STALE if stale line numbers were detected (file NOT modified).
        """
        try:
            with open(abs_file_path, "r", encoding="utf-8") as f:
                lines = f.readlines()

            changes_made = False

            # Sort by line number (descending) and column (descending)
            # to update from bottom to top, preserving line/column positions
            sorted_items = sorted(
                replacement_items,
                key=lambda item: (item[0].line_number, item[0].column_start),
                reverse=True,
            )

            # Phase 1: Line-by-line replacement with stale detection
            python_module_renames = {}

            for ref, new_target in sorted_items:
                line_idx = ref.line_number - 1  # Convert to 0-based index

                # Collect module rename mapping for Phase 2 (PD-BUG-045)
                if ref.link_type == LinkType.PYTHON_IMPORT and ref.link_text:
                    new_module = new_target.replace("/", ".")
                    if ref.link_text != new_module:
                        python_module_renames[ref.link_text] = new_module

                # Stale detection: line index out of bounds
                if not (0 <= line_idx < len(lines)):
                    self.logger.warning(
                        "stale_line_number_detected",
                        file_path=file_path,
                        line_number=ref.line_number,
                        total_lines=len(lines),
                        link_target=ref.link_target,
                    )
                    return UpdateResult.STALE

                line = lines[line_idx]

                # Stale detection: expected target not found on this line
                if ref.link_target not in line:
                    # For Python imports, link_target uses slash notation
                    # (e.g. "src/utils/file_utils") but the line has dot
                    # notation ("src.utils.file_utils").  Check link_text too.
                    if (
                        ref.link_type == LinkType.PYTHON_IMPORT
                        and ref.link_text
                        and ref.link_text in line
                    ):
                        pass  # Not stale — found via dot-notation link_text
                    elif new_target in line or (
                        ref.link_type == LinkType.PYTHON_IMPORT
                        and new_target.replace("/", ".") in line
                    ):
                        continue  # Already handled by an earlier replacement
                    else:
                        self.logger.warning(
                            "stale_line_content_detected",
                            file_path=file_path,
                            line_number=ref.line_number,
                            expected_target=ref.link_target,
                        )
                        return UpdateResult.STALE

                updated_line = self._replace_in_line(line, ref, new_target)
                if updated_line != line:
                    lines[line_idx] = updated_line
                    changes_made = True

            # Phase 2 (PD-BUG-045): File-wide module usage replacement.
            # When a Python import is updated (e.g., "import utils.helpers" →
            # "import core.helpers"), usage sites on other lines
            # (e.g., "utils.helpers.func()") must also be updated.
            if python_module_renames:
                content = "".join(lines)
                for old_module, new_module in python_module_renames.items():
                    # PD-BUG-094: Use negative lookbehind for '.' and \w to
                    # prevent matching inside already-updated module paths.
                    # Plain \b fires between '.' and a letter (e.g.,
                    # "src.utils" contains a \b before "utils"), causing
                    # double-application of prefixes.  The trailing \b is
                    # replaced with (?!\w) to still allow ".func()" after
                    # the module name.
                    pattern = r"(?<![.\w])" + re.escape(old_module) + r"(?!\w)"
                    content = re.sub(pattern, new_module, content)
                new_lines = content.splitlines(True)
                if new_lines != lines:
                    lines = new_lines
                    changes_made = True

            # Write the updated content if changes were made
            if changes_made:
                self._write_file_safely(abs_file_path, "".join(lines))
                return UpdateResult.UPDATED

            return UpdateResult.NO_CHANGES

        except Exception as e:
            raise RuntimeError(f"Failed to update file {abs_file_path}: {e}")

    def _calculate_new_target(self, ref: LinkReference, old_path: str, new_path: str) -> str:
        """Calculate the new target path for a reference.

        Delegates to PathResolver.calculate_new_target().
        """
        return self.path_resolver.calculate_new_target(ref, old_path, new_path)

    def _replace_in_line(self, line: str, ref: LinkReference, new_target: str) -> str:
        """Replace the target in a line based on the reference information."""
        # Handle different link types appropriately
        if ref.link_type == LinkType.MARKDOWN:
            # For markdown links [text](target), replace just the target part
            return self._replace_markdown_target(line, ref, new_target)
        elif ref.link_type == LinkType.MARKDOWN_REFERENCE:
            # For reference links [label]: target "title", replace just the target part
            return self._replace_reference_target(line, ref, new_target)
        else:
            # For other types, use position-based replacement for precision
            return self._replace_at_position(line, ref, new_target)

    def _replace_markdown_target(self, line: str, ref: LinkReference, new_target: str) -> str:
        """Replace target in markdown link format, handling titles properly.

        When the link text exactly matches the old target, the text is also
        updated to the new target (PD-BUG-012).
        """
        # Escape special regex characters in the original target
        escaped_target = re.escape(ref.link_target)

        # Pattern to match [text](target optional_title) where target is our specific target
        # Text is captured separately so we can update it when it matches the old target
        # This handles titles in formats: "title", 'title', (title)
        pattern = rf"(\[)([^\]]*)(\]\()({escaped_target})(\s+[\"'(][^\"')]*[\"')])?(\))"

        def replace_func(match):
            # Group 1: [
            # Group 2: link text
            # Group 3: ](
            # Group 4: target (the file path we want to replace)
            # Group 5: optional title (including the space and quotes/parens)
            # Group 6: closing )
            link_text = match.group(2)
            title_part = match.group(5) if match.group(5) else ""
            # Update link text when it exactly matches the old target
            if link_text == ref.link_target:
                link_text = new_target
            return (
                f"{match.group(1)}{link_text}{match.group(3)}"
                f"{new_target}{title_part}{match.group(6)}"
            )

        compiled = self._get_cached_regex(pattern)
        return compiled.sub(replace_func, line)

    def _replace_reference_target(self, line: str, ref: LinkReference, new_target: str) -> str:
        """Replace target in reference link format [label]: target "title"."""
        # Escape special regex characters in the original target
        escaped_target = re.escape(ref.link_target)

        # Pattern to match [label]: target optional_title
        # This handles titles in formats: "title", 'title', (title)
        pattern = rf"(\[[^\]]*\]:\s*)({escaped_target})(\s+[\"'(][^\"')]*[\"')])?(\s*$)"

        def replace_func(match):
            # Group 1: [label]:
            # Group 2: target (the file path we want to replace)
            # Group 3: optional title (including the space and quotes/parens)
            # Group 4: end of line
            title_part = match.group(3) if match.group(3) else ""
            end_part = match.group(4) if match.group(4) else ""
            return f"{match.group(1)}{new_target}{title_part}{end_part}"

        compiled = self._get_cached_regex(pattern)
        return compiled.sub(replace_func, line)

    def _get_cached_regex(self, pattern: str) -> re.Pattern:
        """Get a compiled regex from cache, compiling and caching if needed."""
        compiled = self._regex_cache.get(pattern)
        if compiled is None:
            if len(self._regex_cache) >= self._REGEX_CACHE_MAX_SIZE:
                self._regex_cache.clear()
            compiled = re.compile(pattern)
            self._regex_cache[pattern] = compiled
        return compiled

    def _replace_at_position(self, line: str, ref: LinkReference, new_target: str) -> str:
        """Replace target at specific position in line."""
        # Special handling for Python imports - replace the text, not the target
        if ref.link_type == LinkType.PYTHON_IMPORT:
            # For Python imports, we need to replace the dot notation in the line
            # Convert new_target (slash notation) back to dot notation
            new_import_text = new_target.replace("/", ".")
            return line.replace(ref.link_text, new_import_text)

        # Use column positions to replace only the specific occurrence
        start_col = ref.column_start
        end_col = ref.column_end

        # Validate positions
        if start_col < 0 or end_col > len(line) or start_col >= end_col:
            # Fall back to simple replacement if positions are invalid
            return line.replace(ref.link_target, new_target)

        # Extract the text at the specified position
        text_at_position = line[start_col:end_col]

        # For quoted references, the text might include quotes
        if (
            ref.link_type
            in [
                LinkType.MARKDOWN_QUOTED,
                LinkType.QUOTED,
                LinkType.PYTHON_QUOTED,
                LinkType.HTML_ANCHOR,
            ]
            and text_at_position.startswith('"')
            and text_at_position.endswith('"')
        ):
            # Replace just the content inside quotes
            return line[:start_col] + f'"{new_target}"' + line[end_col:]
        elif (
            ref.link_type
            in [
                LinkType.MARKDOWN_QUOTED,
                LinkType.QUOTED,
                LinkType.PYTHON_QUOTED,
                LinkType.HTML_ANCHOR,
            ]
            and text_at_position.startswith("'")
            and text_at_position.endswith("'")
        ):
            # Replace just the content inside single quotes
            return line[:start_col] + f"'{new_target}'" + line[end_col:]
        else:
            # Direct replacement at position
            return line[:start_col] + new_target + line[end_col:]

    def _write_file_safely(self, file_path: str, content: str):
        """Write file content safely with backup and atomic operation."""
        # Create backup if enabled
        if self.backup_enabled:
            backup_path = f"{file_path}.bak"
            try:
                shutil.copy2(file_path, backup_path)
            except Exception as e:
                self.logger.warning(
                    "backup_creation_failed",
                    file_path=file_path,
                    error=str(e),
                    error_type=type(e).__name__,
                )

        # Write to temporary file first, then move (atomic operation)
        temp_path = None
        try:
            # Create temporary file in the same directory
            dir_path = os.path.dirname(file_path)
            with tempfile.NamedTemporaryFile(
                mode="w", encoding="utf-8", dir=dir_path, delete=False
            ) as temp_file:
                temp_path = temp_file.name
                temp_file.write(content)

            # Atomic move
            shutil.move(temp_path, file_path)

        except Exception as e:
            # Clean up temp file if it exists
            if temp_path and os.path.exists(temp_path):
                try:
                    os.unlink(temp_path)
                except Exception:
                    pass
            raise e

    def set_dry_run(self, enabled: bool):
        """Enable or disable dry run mode."""
        self.dry_run = enabled

    def set_backup_enabled(self, enabled: bool):
        """Enable or disable backup creation."""
        self.backup_enabled = enabled
