"""
Reference lookup and database management for the LinkWatcher system.

This module handles finding references to files in the link database,
rescanning files to refresh database entries, retrying stale references,
cleaning up the database after file moves, and updating links within
moved files.

Extracted from handler.py as part of TD022/TD035 decomposition.
"""

import os
import re
import shutil
from pathlib import Path

from colorama import Fore

from .database import LinkDatabase
from .logging import get_logger
from .parser import LinkParser
from .updater import LinkUpdater


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
        link_db: LinkDatabase,
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
        (first directory stripped), backslash (Windows), and filename-only.
        """
        variations = [path]
        path_parts = path.split("/")
        if len(path_parts) > 2:  # Has at least 2 directory levels
            relative = "/".join(path_parts[1:])  # Remove first directory
            variations.append(relative)
            variations.append(relative.replace("/", "\\"))  # Windows backslash
        variations.append(os.path.basename(path))
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

        print(
            f"{Fore.YELLOW}🔄 Rescanning {len(stale_files)} file(s) " f"with stale line numbers..."
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
            print(f"{Fore.CYAN}🔄 Retrying with {len(unique_retry)} " f"fresh reference(s)...")
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

    def cleanup_after_file_move(self, references, old_targets, moved_file_path=None):
        """Remove old DB entries and rescan affected files after a file move.

        Instead of updating the database in place, removes old references
        and rescans the affected files to ensure database consistency.

        Args:
            references: References found pointing to the moved file.
            old_targets: List of old target path variations to remove from DB.
            moved_file_path: If provided, skip this file in the rescan loop.
                _update_links_within_moved_file handles it separately.
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

        # Rescan all affected files to rebuild database entries
        # Skip the moved file itself — _update_links_within_moved_file handles it
        for file_path in affected_files:
            if file_path == moved_file_path:
                continue
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
                print(f"{Fore.GREEN}📊 Scanned {len(references)} link(s) in {rel_path}")

        except Exception as e:
            self.logger.warning(
                "rescan_file_error",
                file_path=file_path,
                error=str(e),
                error_type=type(e).__name__,
            )

    def rescan_moved_file_links(self, old_path, new_path, abs_new_path):
        """Rescan a moved file and properly update the link database."""
        try:
            # Remove existing links using the OLD path (since that's what's in the database)
            self.link_db.remove_file_links(old_path)

            # Parse and add new links with the NEW path
            references = self.parser.parse_file(abs_new_path)
            for ref in references:
                # Update the reference to use the new relative path
                ref.file_path = new_path
                self.link_db.add_link(ref)

            if references:
                print(f"{Fore.GREEN}📊 Scanned {len(references)} link(s) in {new_path}")

        except Exception as e:
            self.logger.warning(
                "rescan_moved_file_error",
                file_path=abs_new_path,
                error=str(e),
                error_type=type(e).__name__,
            )

    def process_directory_file_move(self, old_file_path: str, new_file_path: str):
        """Process a single file's reference updates during a directory move.

        Finds references to the old path, updates them, handles stale retry,
        cleans up the database, and rescans the moved file for its own links.

        Args:
            old_file_path: Relative old path of the file.
            new_file_path: Relative new path of the file.

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
            self.cleanup_after_file_move(references, old_targets, moved_file_path=old_file_path)

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
            print(f"{Fore.CYAN}🔧 Updating links within moved file: {new_file_path}")

            # Read the file content once — parse from the same content we'll modify
            # (PD-BUG-025: eliminates race condition between parse and read)
            with open(abs_new_path, "r", encoding="utf-8") as f:
                content = f.read()

            # Parse from already-read content
            references = self.parser.parse_content(content, abs_new_path)
            if not references:
                # PD-BUG-008: Still update DB source path even with no outgoing links,
                # so files_with_links doesn't retain the stale old path.
                self.rescan_moved_file_links(old_file_path, new_file_path, abs_new_path)
                return

            # Filter for relative links that might need updating
            relative_links = []
            for ref in references:
                # Skip absolute paths and URLs
                if (
                    ref.link_target.startswith("http://")
                    or ref.link_target.startswith("https://")
                    or ref.link_target.startswith("/")
                    or (len(ref.link_target) > 1 and ref.link_target[1] == ":")
                ):  # Windows drive letter
                    continue

                # This is a relative link that might need updating
                relative_links.append(ref)

            if not relative_links:
                print(f"{Fore.CYAN}   No relative links found to update")
                # PD-BUG-008: Still update DB source path for the moved file.
                self.rescan_moved_file_links(old_file_path, new_file_path, abs_new_path)
                return

            print(f"{Fore.CYAN}   Found {len(relative_links)} relative link(s) to check")

            # Calculate the directory change
            old_dir = os.path.dirname(old_file_path)
            new_dir = os.path.dirname(new_file_path)

            if old_dir == new_dir:
                print(f"{Fore.CYAN}   File moved within same directory, no link updates needed")
                # PD-BUG-008: Still update DB source path — without this, subsequent
                # moves of files referenced by this file try to open the old (non-existent) path.
                self.rescan_moved_file_links(old_file_path, new_file_path, abs_new_path)
                return

            original_content = content

            # Split into lines for line-targeted replacement (PD-BUG-025)
            lines = content.split("\n")

            # Update each relative link
            links_updated = 0
            for ref in relative_links:
                # Calculate what the link should be from the new location
                new_target = self._calculate_updated_relative_path(
                    ref.link_target, old_file_path, new_file_path
                )

                if new_target != ref.link_target:
                    # For markdown links, replace the target in parentheses
                    if ref.link_type == "markdown":
                        # Replace [text](old) with [text](new), preserving title
                        # Escape special regex chars in the old target
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
                            print(f"{Fore.GREEN}   ✓ Updated: {ref.link_target} → {new_target}")
                        else:
                            print(f"{Fore.YELLOW}   ⚠ Pattern not found for: {ref.link_target}")
                    else:
                        # PD-BUG-025: Line-targeted replacement to prevent substring corruption.
                        # Only replace on the specific line where the parser found the reference.
                        line_idx = ref.line_number - 1  # line_number is 1-indexed
                        if 0 <= line_idx < len(lines) and ref.link_target in lines[line_idx]:
                            lines[line_idx] = lines[line_idx].replace(
                                ref.link_target, new_target, 1
                            )
                            links_updated += 1
                            print(f"{Fore.GREEN}   ✓ Updated: {ref.link_target} → {new_target}")
                        else:
                            print(
                                f"{Fore.YELLOW}   ⚠ Target not found on line "
                                f"{ref.line_number}: {ref.link_target}"
                            )
                else:
                    print(f"{Fore.CYAN}   = No change needed: {ref.link_target}")

            content = "\n".join(lines)

            # Write the updated content back to the file if there were changes
            if links_updated > 0 and content != original_content:
                # Create backup if enabled
                if backup_enabled:
                    backup_path = f"{abs_new_path}.linkwatcher.bak"
                    try:
                        shutil.copy2(abs_new_path, backup_path)
                    except Exception as e:
                        self.logger.warning(
                            "backup_creation_error",
                            file_path=abs_new_path,
                            error=str(e),
                        )

                # Write the updated content
                with open(abs_new_path, "w", encoding="utf-8") as f:
                    f.write(content)

            # PD-BUG-008: Update DB source path via shared method (same logic
            # as early-return paths above, and as _handle_directory_moved).
            self.rescan_moved_file_links(old_file_path, new_file_path, abs_new_path)

            if links_updated > 0:
                print(f"{Fore.GREEN}✓ Updated {links_updated} relative link(s) in moved file")
            else:
                print(f"{Fore.CYAN}   No links needed updating")

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

    def _calculate_updated_relative_path(
        self, original_target: str, old_file_path: str, new_file_path: str
    ) -> str:
        """Calculate how a relative path should be updated when its containing file is moved."""
        try:
            # Get the directories
            old_dir = os.path.dirname(old_file_path)
            new_dir = os.path.dirname(new_file_path)

            # Convert the original relative target to an absolute path from the old location
            if old_dir:
                old_absolute_target = os.path.join(old_dir, original_target)
            else:
                old_absolute_target = original_target

            # Normalize the path
            old_absolute_target = os.path.normpath(old_absolute_target).replace("\\", "/")

            # Calculate the new relative path from the new location
            if new_dir:
                # Use os.path.relpath to calculate the relative path
                new_relative_target = os.path.relpath(old_absolute_target, new_dir)
                # Normalize path separators to forward slashes
                new_relative_target = new_relative_target.replace("\\", "/")
            else:
                new_relative_target = old_absolute_target
            return new_relative_target

        except Exception as e:
            self.logger.warning(
                "path_calculation_error",
                original_target=original_target,
                error=str(e),
            )
            return original_target

    def _get_relative_path(self, abs_path):
        """Convert absolute path to relative path from project root."""
        from .utils import get_relative_path

        return get_relative_path(abs_path, str(self.project_root))
