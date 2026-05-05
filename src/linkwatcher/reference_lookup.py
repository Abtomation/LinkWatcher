"""Reference lookup and database management for the LinkWatcher system.

AI Context
----------
- **What this module does**: finds references to files in the link
  database, rescans files to refresh DB entries, retries stale references,
  cleans up the database after file moves, and updates relative links
  within moved files.  Extracted from handler.py (TD022/TD035).
- **Key class**: ``ReferenceLookup`` — instantiated by
  ``LinkWatcherService`` and used exclusively by ``LinkMaintenanceHandler``
  to separate reference management from event dispatch.
- **Dependencies**: database (link queries/mutations), parser (link
  extraction), updater (file writes), utils (path normalization).
- **Common tasks**:
  - Debugging missed references: check ``find_references()`` →
    ``get_path_variations()`` — path format mismatches (forward/back
    slash, with/without first directory) are the most common cause.
  - Debugging stale update retries: ``retry_stale_references()`` rescans
    source files once and re-queries; if retry also stales, it logs a
    warning and moves on.
  - Understanding DB cleanup after moves: ``cleanup_after_file_move()``
    removes old target entries and rescans affected source files, or
    defers rescanning to the caller for batch efficiency (TD128).
  - Directory move processing: ``collect_directory_file_refs()`` gathers
    refs without updating (for batch pipeline); ``process_directory_file_move()``
    does the full per-file cycle (find → update → retry → cleanup → rescan).
  - Link recalculation inside moved files: ``update_links_within_moved_file()``
    reads the file, filters for relative links, recalculates targets from
    the new location via ``_calculate_updated_relative_path()``, and writes
    back atomically.
  - Testing: ``test/automated/unit/test_reference_lookup.py``.
"""

import os
import re
import shutil
import tempfile
from pathlib import Path

from .database import LinkDatabaseInterface
from .link_types import LinkType
from .logging import get_logger
from .parser import LinkParser
from .updater import LinkUpdater
from .utils import get_relative_path, path_exists_under_root


class ReferenceLookup:
    """Finds references in the link database and manages DB state after file moves.

    Provides multi-format path lookup, stale reference retry, database cleanup
    after moves, file rescanning, link content updates within moved files, and
    per-file processing for directory moves. Used by LinkMaintenanceHandler to
    separate reference management from event dispatch.

    Args:
        link_db: The link database instance.
        parser: The link parser for rescanning files.
        updater: The link updater for retrying stale references.
        project_root: Resolved project root path.
        logger: Structured logger instance.
    """

    def __init__(
        self,
        link_db: LinkDatabaseInterface,
        parser: LinkParser,
        updater: LinkUpdater,
        project_root: Path,
        logger=None,
    ):
        self.link_db = link_db
        self.parser = parser
        self.updater = updater
        self.project_root = project_root
        self.logger = logger or get_logger()

    def get_path_variations(self, path):
        """Generate all format variations of a path for database lookup.

        Returns a list of path strings covering: exact path, relative
        (first directory stripped), backslash (Windows), filename-only,
        and extensionless (for parsers that store module-style references).
        """
        variations = [path]
        path_parts = path.split("/")
        if len(path_parts) > 2:  # Has at least 2 directory levels
            relative = "/".join(path_parts[1:])  # Remove first directory
            variations.append(relative)
            variations.append(relative.replace("/", "\\"))  # Windows backslash
        variations.append(os.path.basename(path))

        # Extensionless variation: some parsers (e.g., PythonParser for imports)
        # store targets without file extension.  PD-BUG-043.
        root, ext = os.path.splitext(path)
        if ext and root:
            variations.append(root)
        return variations

    def find_references(self, target_path, filter_files=None):
        """Find all references to a target path using multiple path format variations.

        Tries exact, relative, backslash, and filename-only variations.
        Returns deduplicated results.

        Args:
            target_path: The target path to find references for.
            filter_files: Optional set of file paths to restrict results to.
        """
        references = []
        for variation in self.get_path_variations(target_path):
            refs = self.link_db.get_references_to_file(variation)
            if filter_files is not None:
                refs = [r for r in refs if r.file_path in filter_files]
            references.extend(refs)
            self.logger.debug("references_found_variation", variation=variation, count=len(refs))

        # Deduplicate using composite key
        seen = set()
        unique = []
        for ref in references:
            key = (ref.file_path, ref.line_number, ref.column_start, ref.link_target)
            if key not in seen:
                seen.add(key)
                unique.append(ref)
        return unique

    def get_old_path_variations(self, old_path):
        """Get all format variations of old_path for database cleanup.

        Returns the same variations as get_path_variations: exact path,
        relative (first directory stripped), backslash, and filename-only.
        Used by cleanup_after_file_move to remove stale DB entries.
        """
        return self.get_path_variations(old_path)

    def retry_stale_references(self, old_path, new_path, update_stats):
        """Rescan files with stale line numbers and retry reference updates.

        When the updater reports stale line numbers (file content changed between
        DB scan and update), this method rescans those files and retries once.
        Results are merged into update_stats in place.
        """
        stale_files = update_stats.get("stale_files", [])
        if not stale_files:
            return

        self.logger.info(
            "rescanning_stale_files",
            stale_file_count=len(stale_files),
        )

        # Rescan only the stale source files to refresh line numbers
        for stale_file in stale_files:
            abs_stale_path = (
                os.path.join(self.project_root, stale_file)
                if not os.path.isabs(stale_file)
                else stale_file
            )
            if os.path.exists(abs_stale_path):
                self.rescan_file_links(abs_stale_path)

        # Re-query fresh references for stale files only
        stale_set = set(stale_files)
        unique_retry = self.find_references(old_path, filter_files=stale_set)

        if unique_retry:
            self.logger.info(
                "retrying_fresh_references",
                reference_count=len(unique_retry),
            )
            retry_stats = self.updater.update_references(unique_retry, old_path, new_path)

            # Merge retry results
            update_stats["files_updated"] += retry_stats["files_updated"]
            update_stats["references_updated"] += retry_stats["references_updated"]
            update_stats["errors"] += retry_stats["errors"]

            # Exit gate: if retry also found stale, log and move on
            if retry_stats.get("stale_files"):
                self.logger.warning(
                    "stale_after_retry",
                    stale_files=retry_stats["stale_files"],
                )
        else:
            self.logger.warning(
                "no_fresh_references_after_rescan",
                stale_files=stale_files,
            )

    def cleanup_after_file_move(
        self, references, old_targets, moved_file_path=None, deferred_rescan_files=None
    ):
        """Remove old DB entries and rescan affected files after a file move.

        Instead of updating the database in place, removes old references
        and rescans the affected files to ensure database consistency.

        Args:
            references: References found pointing to the moved file.
            old_targets: List of old target path variations to remove from DB.
            moved_file_path: If provided, skip this file in the rescan loop.
                _update_links_within_moved_file handles it separately.
            deferred_rescan_files: If provided, collect affected files into this
                set instead of rescanning immediately. The caller is responsible
                for rescanning after all moves are processed (TD128).
        """
        affected_files = set()
        for ref in references:
            affected_files.add(ref.file_path)

        # Remove old references for all path variations
        for old_target in old_targets:
            old_refs = self.link_db.get_references_to_file(old_target)
            for ref in old_refs:
                affected_files.add(ref.file_path)

            # Remove from database - thread-safe, anchor-aware removal
            self.link_db.remove_targets_by_path(old_target)

        # Skip the moved file itself — _update_links_within_moved_file handles it
        if moved_file_path:
            affected_files.discard(moved_file_path)

        if deferred_rescan_files is not None:
            # Defer rescanning — caller will do a single bulk rescan (TD128)
            deferred_rescan_files.update(affected_files)
            return

        # Rescan all affected files to rebuild database entries
        for file_path in affected_files:
            abs_file_path = (
                os.path.join(self.project_root, file_path)
                if not os.path.isabs(file_path)
                else file_path
            )
            if os.path.exists(abs_file_path):
                # First remove any remaining references from this file
                self.link_db.remove_file_links(file_path)
                # Then rescan to add updated references
                self.rescan_file_links(abs_file_path, remove_existing=False)

    def rescan_file_links(self, file_path, remove_existing=True):
        """Rescan a file and update the link database."""
        try:
            rel_path = self._get_relative_path(file_path)

            # Remove existing links from this file (if requested)
            if remove_existing:
                self.link_db.remove_file_links(rel_path)

            # Parse and add new links
            references = self.parser.parse_file(file_path)
            for ref in references:
                # Update the reference to use relative path
                ref.file_path = rel_path
                self.link_db.add_link(ref)

            if references:
                self.logger.info(
                    "file_links_scanned",
                    file_path=rel_path,
                    link_count=len(references),
                )

        except Exception as e:
            self.logger.warning(
                "rescan_file_error",
                file_path=file_path,
                error=str(e),
                error_type=type(e).__name__,
            )

    def rescan_moved_file_links(self, old_path, new_path, abs_new_path, content=None):
        """Rescan a moved file and properly update the link database.

        Args:
            old_path: Relative old path (used for DB cleanup).
            new_path: Relative new path (used for new DB entries).
            abs_new_path: Absolute path to the file at its new location.
            content: Pre-read file content. When provided, uses parse_content()
                instead of parse_file() to avoid a redundant disk read.
        """
        try:
            # Remove existing links using the OLD path (since that's what's in the database)
            self.link_db.remove_file_links(old_path)

            # Parse and add new links with the NEW path
            if content is not None:
                references = self.parser.parse_content(content, abs_new_path)
            else:
                references = self.parser.parse_file(abs_new_path)
            for ref in references:
                # Update the reference to use the new relative path
                ref.file_path = new_path
                self.link_db.add_link(ref)

            if references:
                self.logger.info(
                    "moved_file_links_scanned",
                    file_path=new_path,
                    link_count=len(references),
                )

        except Exception as e:
            self.logger.warning(
                "rescan_moved_file_error",
                file_path=abs_new_path,
                error=str(e),
                error_type=type(e).__name__,
            )

    def collect_directory_file_refs(self, old_file_path: str, new_file_path: str):
        """Collect references and module refs for a moved file without updating.

        Used by the batched directory-move pipeline: the handler collects
        references for ALL moved files first, then passes them to
        updater.update_references_batch() for a single I/O pass per
        referring file.

        Args:
            old_file_path: Relative old path of the file.
            new_file_path: Relative new path of the file.

        Returns:
            Tuple of (file_references, module_references, old_targets) where:
            - file_references: list of LinkReference pointing to the old path
            - module_references: list of LinkReference for Python module paths
              (empty list if not a .py file or no module refs found)
            - old_targets: list of old path variations for DB cleanup
        """
        file_references = self.find_references(old_file_path)
        old_targets = self.get_old_path_variations(old_file_path)

        module_references = []
        if old_file_path.endswith(".py"):
            # PD-BUG-096: find_references() also returns PYTHON_IMPORT refs for
            # .py files via the resolved-target index, so they would otherwise
            # appear in both groups. Leaving them in file_references caused
            # Phase 1 to apply str.replace twice on the same import line,
            # double-prefixing it (e.g. "import src.src.utils.a"). Keep
            # PYTHON_IMPORT refs only in module_references where they are
            # paired with the correct module-path target.
            file_references = [r for r in file_references if r.link_type != LinkType.PYTHON_IMPORT]
            old_module_path = old_file_path[:-3]
            module_references = self.link_db.get_references_to_file(old_module_path)

        return file_references, module_references, old_targets

    def process_directory_file_move(
        self, old_file_path: str, new_file_path: str, deferred_rescan_files: set = None
    ):
        """Process a single file's reference updates during a directory move.

        Finds references to the old path, updates them, handles stale retry,
        cleans up the database, and rescans the moved file for its own links.

        Args:
            old_file_path: Relative old path of the file.
            new_file_path: Relative new path of the file.
            deferred_rescan_files: If provided, collect affected files for bulk
                rescan instead of rescanning per-file (TD128).

        Returns:
            Tuple of (references_updated, errors) counts.
        """
        references_updated = 0
        errors = 0

        references = self.find_references(old_file_path)
        old_targets = self.get_old_path_variations(old_file_path)

        # For Python files, also check for module references (without .py extension)
        if old_file_path.endswith(".py"):
            old_module_path = old_file_path[:-3]
            new_module_path = new_file_path[:-3]
            module_references = self.link_db.get_references_to_file(old_module_path)

            if module_references:
                module_update_stats = self.updater.update_references(
                    module_references, old_module_path, new_module_path
                )
                references_updated += module_update_stats["references_updated"]
                errors += module_update_stats["errors"]

                # Update database for module references
                self.link_db.update_target_path(old_module_path, new_module_path)

        # Update file contents FIRST (while database still has old references)
        if references:
            update_stats = self.updater.update_references(references, old_file_path, new_file_path)
            references_updated += update_stats["references_updated"]
            errors += update_stats["errors"]

            # Handle stale references: reuse shared retry logic
            pre_retry_refs = update_stats["references_updated"]
            pre_retry_errs = update_stats["errors"]
            self.retry_stale_references(old_file_path, new_file_path, update_stats)
            references_updated += update_stats["references_updated"] - pre_retry_refs
            errors += update_stats["errors"] - pre_retry_errs

            # Remove old DB entries and rescan affected files
            self.cleanup_after_file_move(
                references,
                old_targets,
                moved_file_path=old_file_path,
                deferred_rescan_files=deferred_rescan_files,
            )

        # Rescan the moved file for its own links
        abs_new_path = os.path.join(self.project_root, new_file_path)
        self.rescan_moved_file_links(old_file_path, new_file_path, abs_new_path)

        return references_updated, errors

    def find_directory_path_references(self, dir_path):
        """Find all references to a directory path using multiple path variations.

        Queries the database for references whose target matches the directory
        path (exact or prefix). Tries the same path variations as file lookups:
        exact path, relative (first dir stripped), and backslash format.

        Args:
            dir_path: The directory path to find references for.

        Returns:
            Deduplicated list of LinkReference objects targeting this directory.
        """
        references = []
        # Use path variations (excluding filename-only, which doesn't apply to dirs)
        variations = [dir_path]
        path_parts = dir_path.split("/")
        if len(path_parts) > 2:
            relative = "/".join(path_parts[1:])
            variations.append(relative)
            variations.append(relative.replace("/", "\\"))
        # Also try backslash version of the full path
        variations.append(dir_path.replace("/", "\\"))

        for variation in variations:
            refs = self.link_db.get_references_to_directory(variation)
            references.extend(refs)
            if refs:
                self.logger.debug(
                    "dir_references_found_variation",
                    variation=variation,
                    count=len(refs),
                )

        # Deduplicate using composite key
        seen = set()
        unique = []
        for ref in references:
            key = (ref.file_path, ref.line_number, ref.column_start, ref.link_target)
            if key not in seen:
                seen.add(key)
                unique.append(ref)
        return unique

    def cleanup_after_directory_path_move(self, old_dir, new_dir):
        """Update the database after directory-path references have been updated in files.

        Rescans affected files to rebuild their database entries, ensuring
        the database reflects the new directory path in all references.

        Args:
            old_dir: The old directory path.
            new_dir: The new directory path.
        """
        # Find all affected source files (files that contained directory-path references)
        references = self.find_directory_path_references(old_dir)
        affected_files = set()
        for ref in references:
            affected_files.add(ref.file_path)

        # Remove old directory-path targets from the database
        # Use the same path variations as the lookup to ensure all entries are cleaned
        variations = [old_dir]
        path_parts = old_dir.split("/")
        if len(path_parts) > 2:
            relative = "/".join(path_parts[1:])
            variations.append(relative)
            variations.append(relative.replace("/", "\\"))
        variations.append(old_dir.replace("/", "\\"))

        for variation in variations:
            self.link_db.remove_targets_by_path(variation)

        # Rescan affected files to rebuild their database entries
        for file_path in affected_files:
            abs_file_path = (
                os.path.join(self.project_root, file_path)
                if not os.path.isabs(file_path)
                else file_path
            )
            if os.path.exists(abs_file_path):
                self.link_db.remove_file_links(file_path)
                self.rescan_file_links(abs_file_path, remove_existing=False)

    def update_links_within_moved_file(
        self,
        old_file_path: str,
        new_file_path: str,
        abs_new_path: str,
        backup_enabled: bool = False,
    ):
        """Update relative links within a moved file to reflect its new location.

        Reads the moved file, parses for relative links, recalculates each
        link target from the new location, and writes the updated content.
        Also updates the database via rescan_moved_file_links.

        Args:
            old_file_path: Relative old path of the moved file.
            new_file_path: Relative new path of the moved file.
            abs_new_path: Absolute path to the file at its new location.
            backup_enabled: Whether to create a backup before writing.
        """
        try:
            self.logger.info(
                "updating_links_within_moved_file",
                file_path=new_file_path,
            )

            # Read the file content once — parse from the same content we'll modify
            # (PD-BUG-025: eliminates race condition between parse and read)
            with open(abs_new_path, "r", encoding="utf-8") as f:
                content = f.read()

            # Parse from already-read content
            references = self.parser.parse_content(content, abs_new_path)
            if not references:
                # PD-BUG-008: Still update DB source path even with no outgoing links,
                # so files_with_links doesn't retain the stale old path.
                self.rescan_moved_file_links(
                    old_file_path, new_file_path, abs_new_path, content=content
                )
                return 0

            relative_links = self._filter_relative_links(references)

            if not relative_links:
                self.logger.debug("no_relative_links_to_update", file_path=new_file_path)
                # PD-BUG-008: Still update DB source path for the moved file.
                self.rescan_moved_file_links(
                    old_file_path, new_file_path, abs_new_path, content=content
                )
                return 0

            self.logger.debug(
                "relative_links_found",
                file_path=new_file_path,
                link_count=len(relative_links),
            )

            # Check if file stayed in the same directory (no path recalculation needed)
            old_dir = os.path.dirname(old_file_path)
            new_dir = os.path.dirname(new_file_path)

            if old_dir == new_dir:
                self.logger.debug(
                    "same_directory_move_no_updates",
                    file_path=new_file_path,
                )
                # PD-BUG-008: Still update DB source path — without this, subsequent
                # moves of files referenced by this file try to open the old (non-existent) path.
                self.rescan_moved_file_links(
                    old_file_path, new_file_path, abs_new_path, content=content
                )
                return 0

            original_content = content

            # Replace links and write results
            lines, links_updated = self._replace_links_in_lines(
                content.split("\n"), relative_links, old_file_path, new_file_path
            )
            content = "\n".join(lines)

            if links_updated > 0 and content != original_content:
                self._write_with_backup(abs_new_path, content, backup_enabled)

            # PD-BUG-008: Update DB source path via shared method (same logic
            # as early-return paths above, and as _handle_directory_moved).
            self.rescan_moved_file_links(
                old_file_path, new_file_path, abs_new_path, content=content
            )

            if links_updated > 0:
                self.logger.info(
                    "moved_file_links_updated",
                    file_path=new_file_path,
                    links_updated=links_updated,
                )
            else:
                self.logger.debug(
                    "moved_file_no_links_updated",
                    file_path=new_file_path,
                )

            return links_updated

        except Exception as e:
            self.logger.error(
                "update_links_within_moved_file_error",
                old_path=old_file_path,
                new_path=new_file_path,
                error=str(e),
                error_type=type(e).__name__,
            )
            return 0

    def _filter_relative_links(self, references):
        """Filter parsed references to only relative links that may need updating.

        Excludes URLs (http/https), absolute paths (/), and Windows drive-letter
        paths (e.g., C:).
        """
        relative_links = []
        for ref in references:
            if (
                ref.link_target.startswith("http://")
                or ref.link_target.startswith("https://")
                or ref.link_target.startswith("/")
                or (len(ref.link_target) > 1 and ref.link_target[1] == ":")
            ):  # Windows drive letter
                continue
            relative_links.append(ref)
        return relative_links

    def _replace_links_in_lines(self, lines, relative_links, old_file_path, new_file_path):
        """Replace link targets in content lines to reflect the file's new location.

        For markdown links, uses regex replacement preserving title attributes
        (PD-BUG-010). For other link types, uses line-targeted replacement to
        prevent substring corruption (PD-BUG-025).

        Returns:
            Tuple of (updated_lines, links_updated_count).
        """
        links_updated = 0
        for ref in relative_links:
            new_target = self._calculate_updated_relative_path(
                ref.link_target, old_file_path, new_file_path
            )

            if new_target == ref.link_target:
                self.logger.debug(
                    "link_no_change_needed",
                    link_target=ref.link_target,
                )
                continue

            if ref.link_type == LinkType.MARKDOWN:
                # Replace [text](old) with [text](new), preserving title
                escaped_old = re.escape(ref.link_target)
                # PD-BUG-010: Include optional title group to preserve title attributes
                # Titles can be "double-quoted", 'single-quoted', or (parenthesized)
                pattern = rf"(\[[^\]]*\]\()({escaped_old})(\s+[\"'(][^\"')]*[\"')])?(\))"
                _nt = new_target  # capture for closure

                def _md_replace(m, nt=_nt):
                    title = m.group(3) or ""
                    return f"{m.group(1)}{nt}{title}{m.group(4)}"

                content = "\n".join(lines)
                new_content = re.sub(pattern, _md_replace, content)

                if new_content != content:
                    lines = new_content.split("\n")
                    links_updated += 1
                    self.logger.debug(
                        "link_updated_in_moved_file",
                        old_target=ref.link_target,
                        new_target=new_target,
                    )
                else:
                    self.logger.warning(
                        "link_pattern_not_found",
                        file_path=new_file_path,
                        link_target=ref.link_target,
                    )
            else:
                # PD-BUG-025: Line-targeted replacement to prevent substring corruption.
                # Only replace on the specific line where the parser found the reference.
                line_idx = ref.line_number - 1  # line_number is 1-indexed
                if 0 <= line_idx < len(lines) and ref.link_target in lines[line_idx]:
                    lines[line_idx] = lines[line_idx].replace(ref.link_target, new_target, 1)
                    links_updated += 1
                    self.logger.debug(
                        "link_updated_in_moved_file",
                        old_target=ref.link_target,
                        new_target=new_target,
                    )
                else:
                    self.logger.warning(
                        "link_target_not_found_on_line",
                        file_path=new_file_path,
                        line_number=ref.line_number,
                        link_target=ref.link_target,
                    )

        return lines, links_updated

    def _write_with_backup(self, abs_new_path, content, backup_enabled):
        """Write updated content to file, creating a backup first if enabled."""
        if backup_enabled:
            backup_path = f"{abs_new_path}.bak"
            try:
                shutil.copy2(abs_new_path, backup_path)
            except Exception as e:
                self.logger.warning(
                    "backup_creation_error",
                    file_path=abs_new_path,
                    error=str(e),
                )

        # Write to temporary file first, then move (atomic operation)
        temp_path = None
        try:
            dir_path = os.path.dirname(abs_new_path)
            with tempfile.NamedTemporaryFile(
                mode="w", encoding="utf-8", dir=dir_path, delete=False
            ) as temp_file:
                temp_path = temp_file.name
                temp_file.write(content)
            shutil.move(temp_path, abs_new_path)
        except Exception:
            if temp_path and os.path.exists(temp_path):
                os.unlink(temp_path)
            raise

    def _calculate_updated_relative_path(
        self, original_target: str, old_file_path: str, new_file_path: str
    ) -> str:
        """Calculate how a relative path should be updated when its containing file is moved."""
        try:
            # PD-BUG-069: Strip #fragment before path resolution — os.path.exists()
            # fails on paths containing anchors (e.g., "file.md#section").
            # Reattach the fragment to the result after recalculation.
            fragment = ""
            base_target = original_target
            if "#" in original_target:
                base_target, frag = original_target.split("#", 1)
                fragment = "#" + frag

            # Get the directories
            old_dir = os.path.dirname(old_file_path)
            new_dir = os.path.dirname(new_file_path)

            # PD-BUG-032: Detect project-root-relative paths before applying
            # source-relative logic. A path that resolves from the project root
            # but NOT from the file's directory is project-root-relative (e.g.,
            # "doc/templates" in a PS script at scripts/file-creation/).
            # These should not be recalculated when the containing file moves.
            # When old_dir is empty (file at root), source == root resolution,
            # so we can't distinguish — fall through to source-relative (safe).
            if old_dir and not base_target.startswith(("./", "../../..")):
                root_resolved = os.path.join(str(self.project_root), base_target)
                source_resolved = os.path.join(str(self.project_root), old_dir, base_target)
                if os.path.exists(root_resolved) and not os.path.exists(source_resolved):
                    return original_target

            # Convert the original relative target to an absolute path from the old location
            if old_dir:
                old_absolute_target = os.path.join(old_dir, base_target)
            else:
                old_absolute_target = base_target

            # Normalize the path
            old_absolute_target = os.path.normpath(old_absolute_target).replace("\\", "/")

            # PD-BUG-033: Skip non-existent targets — if the resolved path doesn't
            # exist as a file or directory, the extracted "link" was never a real path
            # (e.g., regex patterns, filter strings, example text in PowerShell scripts).
            if not path_exists_under_root(self.project_root, old_absolute_target):
                return original_target

            # Calculate the new relative path from the new location
            if new_dir:
                # Use os.path.relpath to calculate the relative path
                new_relative_target = os.path.relpath(old_absolute_target, new_dir)
                # Normalize path separators to forward slashes
                new_relative_target = new_relative_target.replace("\\", "/")
            else:
                new_relative_target = old_absolute_target
            return new_relative_target + fragment

        except Exception as e:
            self.logger.warning(
                "path_calculation_error",
                original_target=original_target,
                error=str(e),
            )
            return original_target

    def _get_relative_path(self, abs_path):
        """Convert absolute path to relative path from project root."""
        return get_relative_path(abs_path, str(self.project_root))
