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
- **Delegation**: updater → PathResolver (new relative path calculation)
  and ``linkwatcher.replacement`` for the whole replacement stack — link-type
  dispatch, the format-aware markdown replacers, column-span replacement and
  the contained-overlap pre-pass — shared with
  ``ReferenceLookup._replace_links_in_lines`` so the two rewrite paths
  cannot diverge again (PD-BUG-150).  The methods below are thin delegators.
  File I/O uses atomic tempfile-write + rename pattern.
- **Common tasks**:
  - Adding a new file format: add a ``replace_<format>_target()`` function
    to ``linkwatcher.replacement`` and wire it into its ``replace_in_line()``
    dispatch, so both rewrite paths pick it up.
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
from .replacement import (
    ESCAPABLE_STRUCTURED_TYPES,
    filter_contained_overlaps,
    replace_at_position,
    replace_in_line,
    replace_markdown_target,
    replace_reference_target,
)


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

    #: Link types whose recorded span may cover an ESCAPED source literal,
    #: so ``link_text`` (raw source) and ``link_target`` (decoded value)
    #: legitimately differ (PD-BUG-126).  Defined once in
    #: ``linkwatcher.replacement`` and shared with the within-moved-file
    #: rewrite path (PD-BUG-150); kept as a class attribute because the
    #: stale-detection branch below and existing tests reach it by that name.
    _ESCAPABLE_STRUCTURED_TYPES = ESCAPABLE_STRUCTURED_TYPES

    def __init__(
        self,
        project_root: str = ".",
        python_source_root: str = "",
        path_resolution_overrides=None,
    ):
        self.backup_enabled = True
        self.dry_run = False
        self.project_root = Path(project_root).resolve()
        self.logger = get_logger()
        # path_resolution_overrides is a passthrough to PathResolver only —
        # LinkUpdater does not interpret it (blueprint-aware reference
        # updating, PD-TDD-026 "Override-Aware Path Resolution").
        self.path_resolver = PathResolver(
            project_root,
            self.logger,
            python_source_root=python_source_root,
            path_resolution_overrides=path_resolution_overrides,
        )
        # PD-BUG-098 / TD252: per-file count of refs skipped via
        # _replace_at_position's invalid-column ambiguous-fallback path
        # (occurrences>1 case).  Reset by _update_file_references[_multi]
        # before each file; read by update_references[_batch] to surface
        # silent skips in UpdateStats["errors"].
        self._ambiguous_skip_count: int = 0

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
                # TD252: surface ambiguous-fallback skips (set inside
                # _replace_at_position) as errors regardless of UpdateResult.
                stats["errors"] += self._ambiguous_skip_count
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
                # TD252: surface ambiguous-fallback skips (see update_references).
                stats["errors"] += self._ambiguous_skip_count
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
        # PD-BUG-098 / TD252: reset per-file before any replacement work so
        # update_references can attribute skips to the current file.
        self._ambiguous_skip_count = 0
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
        # PD-BUG-098 / TD252: reset per-file (see _update_file_references).
        self._ambiguous_skip_count = 0
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
        r"""Apply pre-computed replacements to a single file.

        Algorithm (overlap filter + two phases):
          Pre-pass — Drop refs whose column range is strictly contained in
          another ref on the same line (PD-BUG-098).  When two refs overlap,
          descending-column processing replaces the inner one first, extending
          the line; the outer ref's original column positions are then stale
          and position-based slicing produces ``<new_target> + chopped_tail``
          corruption.  The outer replacement subsumes the inner range, so
          dropping the inner ref is correct as long as both rewrite to a
          target that resolves to the same file (true for directory moves
          containing the inner file — the canonical PD-BUG-098 trigger).

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

            # Pre-pass (PD-BUG-098): drop inner refs whose column range is
            # strictly contained in another ref on the same line.
            replacement_items = self._filter_contained_overlaps(replacement_items, file_path)

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
                    elif (
                        ref.link_type in self._ESCAPABLE_STRUCTURED_TYPES
                        and ref.link_text
                        and ref.link_text != ref.link_target
                        and ref.link_text in line
                    ):
                        # PD-BUG-126: an escaped JSON/YAML literal holds the
                        # RAW source in link_text and the DECODED value in
                        # link_target, so the decoded form is legitimately
                        # absent from the line.  Without this branch the
                        # file is declared stale and EVERY update in it is
                        # abandoned -- including references that update
                        # correctly today.
                        pass  # Not stale — found via raw-source link_text
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

    def _filter_contained_overlaps(
        self,
        replacement_items: List[Tuple[LinkReference, str]],
        file_path: str,
    ) -> List[Tuple[LinkReference, str]]:
        """Drop refs whose column range is strictly contained in another ref
        on the same line (PD-BUG-098).

        Delegates to :func:`linkwatcher.replacement.filter_contained_overlaps`,
        which the within-moved-file rewrite path shares (PD-BUG-150).  See that
        function for the full contract, including the strictly-contained-only
        scope limit.
        """
        return filter_contained_overlaps(replacement_items, file_path, self.logger)

    def _calculate_new_target(self, ref: LinkReference, old_path: str, new_path: str) -> str:
        """Calculate the new target path for a reference.

        Delegates to PathResolver.calculate_new_target().
        """
        return self.path_resolver.calculate_new_target(ref, old_path, new_path)

    def _replace_in_line(self, line: str, ref: LinkReference, new_target: str) -> str:
        """Replace the target in a line based on the reference information.

        Delegates to :func:`linkwatcher.replacement.replace_in_line`, which the
        within-moved-file rewrite path shares (PD-BUG-150).  The link-type
        dispatch lives there, beside the primitives it guards, so neither path
        can reach positional replacement without it.
        """
        return replace_in_line(line, ref, new_target, self.logger, self._note_ambiguous_skip)

    def _replace_markdown_target(self, line: str, ref: LinkReference, new_target: str) -> str:
        """Replace target in markdown link format, handling titles properly.

        Delegates to :func:`linkwatcher.replacement.replace_markdown_target`.
        """
        return replace_markdown_target(line, ref, new_target)

    def _replace_reference_target(self, line: str, ref: LinkReference, new_target: str) -> str:
        """Replace target in reference link format [label]: target "title".

        Delegates to :func:`linkwatcher.replacement.replace_reference_target`.
        """
        return replace_reference_target(line, ref, new_target)

    def _note_ambiguous_skip(self) -> None:
        """Record that a replacement was refused as ambiguous (TD252)."""
        self._ambiguous_skip_count += 1

    def _replace_at_position(self, line: str, ref: LinkReference, new_target: str) -> str:
        """Replace target at specific position in line.

        Delegates to :func:`linkwatcher.replacement.replace_at_position`, which
        the within-moved-file rewrite path shares (PD-BUG-150).
        """
        return replace_at_position(line, ref, new_target, self.logger, self._note_ambiguous_skip)

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
