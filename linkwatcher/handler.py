"""
File system event handler for the LinkWatcher system.

This module handles file system events (move, delete, create) and
coordinates the appropriate responses.
"""

import os
import threading
import time
from pathlib import Path

from colorama import Fore, Style
from watchdog.events import (
    FileCreatedEvent,
    FileDeletedEvent,
    FileMovedEvent,
    FileSystemEventHandler,
)

from .config.defaults import DEFAULT_CONFIG
from .database import LinkDatabase
from .logging import LogTimer, get_logger, with_context
from .models import FileOperation
from .parser import LinkParser
from .updater import LinkUpdater
from .utils import get_relative_path, normalize_path, should_ignore_directory, should_monitor_file


class LinkMaintenanceHandler(FileSystemEventHandler):
    """
    Handles file system events and maintains link integrity.

    This handler responds to file moves, deletions, and creations by:
    1. Updating the link database
    2. Finding affected references
    3. Updating files with broken links
    """

    def __init__(
        self,
        link_db: LinkDatabase,
        parser: LinkParser,
        updater: LinkUpdater,
        project_root: str,
        monitored_extensions: set = None,
        ignored_directories: set = None,
    ):
        super().__init__()
        self.link_db = link_db
        self.parser = parser
        self.updater = updater
        self.project_root = Path(project_root).resolve()
        self.logger = get_logger()

        # Configuration from parameters or DEFAULT_CONFIG
        self.monitored_extensions = (
            monitored_extensions
            if monitored_extensions is not None
            else DEFAULT_CONFIG.monitored_extensions.copy()
        )
        self.ignored_dirs = (
            ignored_directories
            if ignored_directories is not None
            else DEFAULT_CONFIG.ignored_directories.copy()
        )

        # Delayed move detection
        self.pending_deletes = {}  # {file_path: (timestamp, file_size)}
        self.move_detection_delay = 2.0  # seconds to wait for create after delete
        self.move_detection_lock = threading.Lock()

        # Statistics
        self.stats = {
            "files_moved": 0,
            "files_deleted": 0,
            "files_created": 0,
            "links_updated": 0,
            "errors": 0,
        }

        self.logger.debug(
            "handler_initialized",
            monitored_extensions=list(self.monitored_extensions),
            ignored_dirs=list(self.ignored_dirs),
        )

    def on_moved(self, event):
        """Handle file/directory move events."""
        try:
            if event.is_directory:
                self._handle_directory_moved(event)
            else:
                self._handle_file_moved(event)
        except Exception as e:
            self.logger.error(
                "on_moved_unhandled_error",
                error=str(e),
                error_type=type(e).__name__,
                src_path=getattr(event, "src_path", "unknown"),
            )
            print(f"{Fore.RED}✗ Unhandled error in on_moved: {e}")
            self.stats["errors"] += 1

    def on_deleted(self, event):
        """Handle file/directory deletion events."""
        try:
            if event.is_directory:
                self._handle_directory_deleted(event)
            else:
                # On Windows, watchdog may fire delete events for directories
                # with is_directory=False. Check if the deleted path is a known
                # directory in our database (has files tracked under it).
                deleted_path = self._get_relative_path(event.src_path)
                known_files = self._get_files_under_directory(deleted_path)
                if known_files:
                    self._handle_directory_deleted(event)
                else:
                    self._handle_file_deleted(event)
        except Exception as e:
            self.logger.error(
                "on_deleted_unhandled_error",
                error=str(e),
                error_type=type(e).__name__,
                src_path=getattr(event, "src_path", "unknown"),
            )
            print(f"{Fore.RED}✗ Unhandled error in on_deleted: {e}")
            self.stats["errors"] += 1

    def on_created(self, event):
        """Handle file/directory creation events."""
        try:
            if not event.is_directory and self._should_monitor_file(event.src_path):
                self._handle_file_created(event)
        except Exception as e:
            self.logger.error(
                "on_created_unhandled_error",
                error=str(e),
                error_type=type(e).__name__,
                src_path=getattr(event, "src_path", "unknown"),
            )
            print(f"{Fore.RED}✗ Unhandled error in on_created: {e}")
            self.stats["errors"] += 1

    def on_error(self, event):
        """Handle watchdog errors to prevent silent observer thread death."""
        self.logger.error(
            "watchdog_error",
            error=str(event),
            error_type=type(event).__name__,
        )
        print(f"{Fore.RED}✗ Watchdog error: {event}")
        self.stats["errors"] += 1

    @with_context(component="handler", operation="file_move")
    def _handle_file_moved(self, event: FileMovedEvent):
        """Handle individual file move."""
        old_path = self._get_relative_path(event.src_path)
        new_path = self._get_relative_path(event.dest_path)

        if not old_path or not new_path:
            return

        self.logger.file_moved(old_path, new_path)
        print(f"{Fore.CYAN}📁 File moved: {old_path} → {new_path}")

        try:
            # Get all references to the old file - try multiple path formats
            references = []

            # Try exact path match
            refs_exact = self.link_db.get_references_to_file(old_path)
            references.extend(refs_exact)
            self.logger.debug("references_found_exact", path=old_path, count=len(refs_exact))
            print(f"{Fore.CYAN}Found {len(refs_exact)} references with exact path: {old_path}")

            # Try relative path variations (remove leading directory components)
            # For example: "test/source_dir/file.md" -> "source_dir/file.md"
            path_parts = old_path.split("/")
            if len(path_parts) > 2:  # Has at least 2 directory levels
                relative_path = "/".join(path_parts[1:])  # Remove first directory
                refs_relative = self.link_db.get_references_to_file(relative_path)
                references.extend(refs_relative)
                self.logger.debug(
                    "references_found_relative", path=relative_path, count=len(refs_relative)
                )
                print(
                    f"{Fore.CYAN}Found {len(refs_relative)} references with relative path: {relative_path}"
                )

                # Also try backslash version for Windows
                relative_path_backslash = relative_path.replace("/", "\\")
                refs_backslash = self.link_db.get_references_to_file(relative_path_backslash)
                references.extend(refs_backslash)
                self.logger.debug(
                    "references_found_backslash",
                    path=relative_path_backslash,
                    count=len(refs_backslash),
                )
                print(
                    f"{Fore.CYAN}Found {len(refs_backslash)} references with backslash path: {relative_path_backslash}"
                )

            # Try just filename
            old_filename = os.path.basename(old_path)
            refs_filename = self.link_db.get_references_to_file(old_filename)
            references.extend(refs_filename)
            self.logger.debug(
                "references_found_filename", filename=old_filename, count=len(refs_filename)
            )
            print(f"{Fore.CYAN}Found {len(refs_filename)} references with filename: {old_filename}")

            # Remove duplicates - use more specific key to avoid over-deduplication
            seen = set()
            unique_references = []
            for ref in references:
                # Include column position to distinguish multiple references on same line
                key = (ref.file_path, ref.line_number, ref.column_start, ref.link_target)
                if key not in seen:
                    seen.add(key)
                    unique_references.append(ref)

            references = unique_references

            if references:
                self.logger.info(
                    "updating_references",
                    old_path=old_path,
                    new_path=new_path,
                    references_count=len(references),
                )
                print(f"{Fore.YELLOW}🔗 Updating {len(references)} unique references...")

                # Collect all path variations that need updating FIRST
                # before making any changes (since each update modifies the database)
                path_updates = []

                # Try exact path match
                if self.link_db.get_references_to_file(old_path):
                    path_updates.append((old_path, new_path))

                # Try relative path variations
                path_parts = old_path.split("/")
                if len(path_parts) > 2:  # Has at least 2 directory levels
                    relative_old_path = "/".join(path_parts[1:])  # Remove first directory
                    relative_new_path = "/".join(new_path.split("/")[1:])  # Remove first directory
                    if self.link_db.get_references_to_file(relative_old_path):
                        path_updates.append((relative_old_path, relative_new_path))

                    # Also try backslash version for Windows
                    relative_old_path_backslash = relative_old_path.replace("/", "\\")
                    relative_new_path_backslash = relative_new_path.replace("/", "\\")
                    if self.link_db.get_references_to_file(relative_old_path_backslash):
                        path_updates.append(
                            (relative_old_path_backslash, relative_new_path_backslash)
                        )

                # Try just filename
                old_filename = os.path.basename(old_path)
                new_filename = os.path.basename(new_path)
                if self.link_db.get_references_to_file(old_filename):
                    path_updates.append((old_filename, new_filename))

                # Update the files FIRST (before modifying the database)
                update_stats = self.updater.update_references(references, old_path, new_path)

                # Handle stale line numbers: rescan affected files and retry once
                stale_files = update_stats.get("stale_files", [])
                if stale_files:
                    self.logger.info(
                        "rescanning_stale_files",
                        stale_files=stale_files,
                        count=len(stale_files),
                    )
                    print(
                        f"{Fore.YELLOW}🔄 Rescanning {len(stale_files)} file(s) "
                        f"with stale line numbers..."
                    )

                    # Rescan only the stale source files to refresh line numbers
                    for stale_file in stale_files:
                        abs_stale_path = (
                            os.path.join(self.project_root, stale_file)
                            if not os.path.isabs(stale_file)
                            else stale_file
                        )
                        if os.path.exists(abs_stale_path):
                            self._rescan_file_links(abs_stale_path)

                    # Re-query fresh references for stale files only
                    stale_set = set(stale_files)
                    retry_references = []

                    # Try all path variations (same as original lookup above)
                    for ref in self.link_db.get_references_to_file(old_path):
                        if ref.file_path in stale_set:
                            retry_references.append(ref)

                    path_parts_retry = old_path.split("/")
                    if len(path_parts_retry) > 2:
                        relative_old = "/".join(path_parts_retry[1:])
                        for ref in self.link_db.get_references_to_file(relative_old):
                            if ref.file_path in stale_set:
                                retry_references.append(ref)

                    old_fn = os.path.basename(old_path)
                    for ref in self.link_db.get_references_to_file(old_fn):
                        if ref.file_path in stale_set:
                            retry_references.append(ref)

                    # Deduplicate
                    seen_retry = set()
                    unique_retry = []
                    for ref in retry_references:
                        key = (ref.file_path, ref.line_number, ref.column_start, ref.link_target)
                        if key not in seen_retry:
                            seen_retry.add(key)
                            unique_retry.append(ref)

                    if unique_retry:
                        print(
                            f"{Fore.CYAN}🔄 Retrying with {len(unique_retry)} "
                            f"fresh reference(s)..."
                        )
                        retry_stats = self.updater.update_references(
                            unique_retry, old_path, new_path
                        )

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
                            print(
                                f"{Fore.RED}⚠ References still stale after "
                                f"rescan. Skipping to prevent loop."
                            )
                    else:
                        self.logger.warning(
                            "no_fresh_references_after_rescan",
                            stale_files=stale_files,
                        )
                        print(
                            f"{Fore.YELLOW}⚠ No fresh references found after "
                            f"rescan for stale files"
                        )

                # Instead of trying to update the database in place, remove old references
                # and rescan the affected files to ensure database consistency
                affected_files = set()
                for ref in references:
                    affected_files.add(ref.file_path)

                # Remove old references for all path variations
                for old_target, new_target in path_updates:
                    # Remove references to the old target
                    old_refs = self.link_db.get_references_to_file(old_target)
                    for ref in old_refs:
                        affected_files.add(ref.file_path)

                    # Remove from database - need to handle normalized paths
                    old_normalized = normalize_path(old_target)
                    keys_to_remove = []
                    for key in self.link_db.links.keys():
                        base_key = key.split("#", 1)[0] if "#" in key else key
                        if normalize_path(base_key) == old_normalized:
                            keys_to_remove.append(key)

                    for key in keys_to_remove:
                        del self.link_db.links[key]

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
                        self._rescan_file_links(abs_file_path, remove_existing=False)

                # Update statistics
                self.stats["links_updated"] += update_stats["references_updated"]
                self.stats["errors"] += update_stats["errors"]

                # Report results
                if update_stats["files_updated"] > 0:
                    self.logger.info(
                        "file_move_completed",
                        files_updated=update_stats["files_updated"],
                        references_updated=update_stats["references_updated"],
                    )
                    print(f"{Fore.GREEN}✓ Updated links in {update_stats['files_updated']} files")
                else:
                    self.logger.info("no_files_updated", old_path=old_path, new_path=new_path)
                    print(f"{Fore.YELLOW}⚠ No files needed updating")
            else:
                self.logger.warning("no_references_found", old_path=old_path, new_path=new_path)
                print(f"{Fore.YELLOW}⚠ No references found to update")

            # If the moved file contains links, update its entries and fix relative paths
            if self._should_monitor_file(event.dest_path):
                # Update links within the moved file to reflect new relative paths
                # This method handles both content updates and database updates
                self._update_links_within_moved_file(old_path, new_path, event.dest_path)

            self.stats["files_moved"] += 1

        except Exception as e:
            self.logger.error(
                "file_move_error",
                old_path=old_path,
                new_path=new_path,
                error=str(e),
                error_type=type(e).__name__,
            )
            print(f"{Fore.RED}✗ Error handling file move: {e}")
            self.stats["errors"] += 1

    def _handle_directory_moved(self, event: FileMovedEvent):
        """Handle directory move - affects all files within."""
        old_dir = self._get_relative_path(event.src_path)
        new_dir = self._get_relative_path(event.dest_path)

        self.logger.info("directory_moved", old_dir=old_dir, new_dir=new_dir)
        print(f"{Fore.CYAN}📂 Directory moved: {old_dir} → {new_dir}")

        try:
            # Find all files that were moved
            moved_files = []
            for root, dirs, files in os.walk(event.dest_path):
                # Skip ignored directories
                dirs[:] = [d for d in dirs if d not in self.ignored_dirs]

                for file in files:
                    file_path = os.path.join(root, file)
                    if self._should_monitor_file(file_path):
                        rel_new_path = self._get_relative_path(file_path)
                        # Calculate what the old path would have been
                        rel_old_path = rel_new_path.replace(new_dir, old_dir, 1)
                        moved_files.append((rel_old_path, rel_new_path))

            # Update each moved file
            total_references_updated = 0
            for old_file_path, new_file_path in moved_files:
                # Find references BEFORE updating database
                references = self.link_db.get_references_to_file(old_file_path)

                # For Python files, also check for module references (without .py extension)
                if old_file_path.endswith(".py"):
                    old_module_path = old_file_path[:-3]  # Remove .py extension
                    new_module_path = new_file_path[:-3]  # Remove .py extension
                    module_references = self.link_db.get_references_to_file(old_module_path)

                    # Update module references separately
                    if module_references:
                        module_update_stats = self.updater.update_references(
                            module_references, old_module_path, new_module_path
                        )
                        total_references_updated += module_update_stats["references_updated"]
                        self.stats["errors"] += module_update_stats["errors"]

                        # Update database for module references
                        self.link_db.update_target_path(old_module_path, new_module_path)

                # Update file contents FIRST (while database still has old references)
                if references:
                    update_stats = self.updater.update_references(
                        references, old_file_path, new_file_path
                    )
                    total_references_updated += update_stats["references_updated"]
                    self.stats["errors"] += update_stats["errors"]

                    # Handle stale references: rescan affected files and retry once
                    stale_files = update_stats.get("stale_files", [])
                    if stale_files:
                        for stale_file in stale_files:
                            abs_stale = (
                                os.path.join(self.project_root, stale_file)
                                if not os.path.isabs(stale_file)
                                else stale_file
                            )
                            if os.path.exists(abs_stale):
                                self._rescan_file_links(abs_stale)

                        retry_refs = self.link_db.get_references_to_file(old_file_path)
                        stale_set = set(stale_files)
                        retry_refs = [r for r in retry_refs if r.file_path in stale_set]
                        if retry_refs:
                            retry_stats = self.updater.update_references(
                                retry_refs, old_file_path, new_file_path
                            )
                            total_references_updated += retry_stats["references_updated"]
                            self.stats["errors"] += retry_stats["errors"]

                # Update database AFTER file contents are updated
                self.link_db.update_target_path(old_file_path, new_file_path)

                # Rescan the file for its own links
                abs_new_path = os.path.join(self.project_root, new_file_path)
                self._rescan_moved_file_links(old_file_path, new_file_path, abs_new_path)

            self.logger.info(
                "directory_move_completed",
                total_references_updated=total_references_updated,
                moved_files_count=len(moved_files),
            )
            print(
                f"{Fore.GREEN}✓ Updated {total_references_updated} reference(s) for {len(moved_files)} moved files"
            )
            self.stats["links_updated"] += total_references_updated
            self.stats["files_moved"] += len(moved_files)

        except Exception as e:
            self.logger.error(
                "directory_move_error",
                old_dir=old_dir,
                new_dir=new_dir,
                error=str(e),
                error_type=type(e).__name__,
            )
            print(f"{Fore.RED}✗ Error handling directory move: {e}")
            self.stats["errors"] += 1

    def _handle_file_deleted(self, event: FileDeletedEvent):
        """Handle file deletion with delayed move detection."""
        deleted_path = self._get_relative_path(event.src_path)

        # Get file info before it's gone
        file_size = 0
        try:
            if os.path.exists(event.src_path):
                file_size = os.path.getsize(event.src_path)
        except:
            pass

        self.logger.file_deleted(deleted_path)
        print(f"{Fore.RED}🗑️ File deleted: {deleted_path}")

        # Buffer this delete event for potential move detection
        with self.move_detection_lock:
            self.pending_deletes[deleted_path] = (time.time(), file_size)

        # Schedule delayed processing
        timer = threading.Timer(
            self.move_detection_delay, self._process_delayed_delete, [deleted_path]
        )
        timer.start()

    def _process_delayed_delete(self, deleted_path: str):
        """Process a delete event after the move detection delay."""
        with self.move_detection_lock:
            if deleted_path not in self.pending_deletes:
                return  # Already processed as a move

            # Remove from pending deletes
            del self.pending_deletes[deleted_path]

        # Process as actual deletion
        try:
            # Remove from database
            self.link_db.remove_file_links(deleted_path)

            # Find references to the deleted file (these are now broken)
            references = self.link_db.get_references_to_file(deleted_path)
            if references:
                self.logger.warning(
                    "broken_references_found",
                    deleted_file=deleted_path,
                    broken_references_count=len(references),
                )
                print(
                    f"{Fore.YELLOW}⚠️ Found {len(references)} broken reference(s) to deleted file"
                )
                # Note: We don't auto-fix broken references to deleted files
                # This is intentional - user should decide what to do
                for ref in references:
                    self.logger.debug(
                        "broken_reference_detail",
                        file_path=ref.file_path,
                        line_number=ref.line_number,
                        link_text=ref.link_text,
                    )
                    print(f"   {Fore.YELLOW}• {ref.file_path}:{ref.line_number} - {ref.link_text}")

            self.stats["files_deleted"] += 1

        except Exception as e:
            self.logger.error(
                "file_deletion_error",
                deleted_path=deleted_path,
                error=str(e),
                error_type=type(e).__name__,
            )
            print(f"{Fore.RED}✗ Error handling file deletion: {e}")
            self.stats["errors"] += 1

    def _handle_directory_deleted(self, event: FileDeletedEvent):
        """Handle directory deletion with move detection.

        On Windows, directory moves are reported by watchdog as a directory
        delete event followed by individual file create events (instead of
        a DirMovedEvent). This method buffers the known files under the
        deleted directory as pending deletes so that when the corresponding
        file create events arrive, _detect_potential_move pairs them and
        the moves are handled correctly.
        """
        deleted_dir = self._get_relative_path(event.src_path)
        self.logger.warning("directory_deleted", deleted_dir=deleted_dir)
        print(f"{Fore.RED}🗑️ Directory deleted: {deleted_dir}")

        # Get all known files under this directory from the database
        known_files = self._get_files_under_directory(deleted_dir)

        if known_files:
            # Buffer each file as a pending delete for move detection.
            # When watchdog fires FileCreatedEvent for the same filenames
            # at a new location, _detect_potential_move will match them.
            current_time = time.time()
            with self.move_detection_lock:
                for file_path in known_files:
                    self.pending_deletes[file_path] = (current_time, 0)

            # Schedule delayed processing for each (handles true deletes)
            for file_path in known_files:
                timer = threading.Timer(
                    self.move_detection_delay,
                    self._process_delayed_delete,
                    [file_path],
                )
                timer.start()

            self.logger.info(
                "directory_files_buffered_for_move_detection",
                deleted_dir=deleted_dir,
                files_count=len(known_files),
            )
            print(
                f"{Fore.CYAN}📂 Buffered {len(known_files)} known file(s) "
                f"from '{deleted_dir}' for move detection"
            )
        else:
            self.logger.warning(
                "directory_deletion_no_known_files",
                deleted_dir=deleted_dir,
                recommendation="full_rescan",
            )
            print(
                f"{Fore.YELLOW}⚠️ Directory deletion detected with no known "
                f"files in database. Consider running a full rescan."
            )

    def _handle_file_created(self, event: FileCreatedEvent):
        """Handle file creation with move detection."""
        created_path = self._get_relative_path(event.src_path)

        # Check if this might be a move operation
        potential_move_source = self._detect_potential_move(created_path, event.src_path)

        if potential_move_source:
            # Handle as move operation
            self.logger.info(
                "move_detected", source=potential_move_source, destination=created_path
            )
            print(f"{Fore.CYAN}📁 Detected move: {potential_move_source} → {created_path}")
            self._handle_detected_move(potential_move_source, created_path)
        else:
            # Handle as regular file creation
            self.logger.file_created(created_path)
            print(f"{Fore.GREEN}📄 File created: {created_path}")
            try:
                # Scan the new file for links
                self._rescan_file_links(event.src_path)
                self.stats["files_created"] += 1
            except Exception as e:
                self.logger.error(
                    "file_creation_error",
                    created_path=created_path,
                    error=str(e),
                    error_type=type(e).__name__,
                )
                print(f"{Fore.RED}✗ Error handling file creation: {e}")
                self.stats["errors"] += 1

    def _detect_potential_move(self, created_path: str, created_abs_path: str) -> str:
        """Detect if a file creation is actually part of a move operation."""
        with self.move_detection_lock:
            if not self.pending_deletes:
                return None

            # Get file size of created file
            try:
                created_size = os.path.getsize(created_abs_path)
            except:
                return None

            # Look for a recently deleted file with same name and size
            created_filename = os.path.basename(created_path)
            current_time = time.time()

            for deleted_path, (delete_time, delete_size) in list(self.pending_deletes.items()):
                # Check if delete was recent enough
                if current_time - delete_time > self.move_detection_delay:
                    continue

                # Check if filename matches
                deleted_filename = os.path.basename(deleted_path)
                if created_filename == deleted_filename:
                    # Check if size matches (if we have size info)
                    if delete_size == 0 or created_size == delete_size:
                        # This looks like a move!
                        del self.pending_deletes[deleted_path]
                        return deleted_path

            return None

    def _handle_detected_move(self, old_path: str, new_path: str):
        """Handle a detected move operation."""
        try:
            # Create a synthetic move event and handle it
            project_root_str = str(self.project_root)

            class SyntheticMoveEvent:
                def __init__(self, src_path, dest_path):
                    self.src_path = os.path.join(project_root_str, src_path)
                    self.dest_path = os.path.join(project_root_str, dest_path)
                    self.is_directory = False

            synthetic_event = SyntheticMoveEvent(old_path, new_path)
            self._handle_file_moved(synthetic_event)

        except Exception as e:
            print(f"{Fore.RED}✗ Error handling detected move: {e}")
            self.stats["errors"] += 1

    def _rescan_file_links(self, file_path: str, remove_existing: bool = True):
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
            print(f"{Fore.YELLOW}Warning: Could not rescan {file_path}: {e}")

    def _rescan_moved_file_links(self, old_path: str, new_path: str, abs_new_path: str):
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
            print(f"{Fore.YELLOW}Warning: Could not rescan moved file {abs_new_path}: {e}")

    def _update_links_within_moved_file(
        self, old_file_path: str, new_file_path: str, abs_new_path: str
    ):
        """Update relative links within a moved file to reflect its new location."""
        try:
            print(f"{Fore.CYAN}🔧 Updating links within moved file: {new_file_path}")

            # Parse the file to get all its links
            references = self.parser.parse_file(abs_new_path)
            if not references:
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
                return

            print(f"{Fore.CYAN}   Found {len(relative_links)} relative link(s) to check")

            # Calculate the directory change
            old_dir = os.path.dirname(old_file_path)
            new_dir = os.path.dirname(new_file_path)

            if old_dir == new_dir:
                print(f"{Fore.CYAN}   File moved within same directory, no link updates needed")
                return

            # Read the file content
            with open(abs_new_path, "r", encoding="utf-8") as f:
                content = f.read()

            original_content = content

            # Update each relative link by direct string replacement
            links_updated = 0
            for ref in relative_links:
                # Calculate what the link should be from the new location
                new_target = self._calculate_updated_relative_path(
                    ref.link_target, old_file_path, new_file_path
                )

                if new_target != ref.link_target:
                    # For markdown links, replace the target in parentheses
                    if ref.link_type == "markdown":
                        # Replace [text](old_target) with [text](new_target)
                        import re

                        # Escape special regex characters in the old target
                        escaped_old = re.escape(ref.link_target)
                        pattern = rf"(\[[^\]]*\]\()({escaped_old})(\))"
                        replacement = rf"\1{new_target}\3"
                        new_content = re.sub(pattern, replacement, content)

                        if new_content != content:
                            content = new_content
                            links_updated += 1
                            print(f"{Fore.GREEN}   ✓ Updated: {ref.link_target} → {new_target}")
                        else:
                            print(f"{Fore.YELLOW}   ⚠ Pattern not found for: {ref.link_target}")
                    else:
                        # For other link types, try simple replacement
                        if ref.link_target in content:
                            content = content.replace(ref.link_target, new_target)
                            links_updated += 1
                            print(f"{Fore.GREEN}   ✓ Updated: {ref.link_target} → {new_target}")
                        else:
                            print(
                                f"{Fore.YELLOW}   ⚠ Target not found in content: {ref.link_target}"
                            )
                else:
                    print(f"{Fore.CYAN}   = No change needed: {ref.link_target}")

            # Write the updated content back to the file if there were changes
            if links_updated > 0 and content != original_content:
                # Create backup if enabled
                if self.updater.backup_enabled:
                    backup_path = f"{abs_new_path}.linkwatcher.bak"
                    try:
                        import shutil

                        shutil.copy2(abs_new_path, backup_path)
                    except Exception as e:
                        print(f"{Fore.YELLOW}Warning: Could not create backup: {e}")

                # Write the updated content
                with open(abs_new_path, "w", encoding="utf-8") as f:
                    f.write(content)

            # Always update the database to reflect the new file path
            # Remove old entries from the old path
            self.link_db.remove_file_links(old_file_path)

            # Re-scan the file to update the database with the new path
            updated_refs = self.parser.parse_file(abs_new_path)
            for updated_ref in updated_refs:
                updated_ref.file_path = new_file_path
                self.link_db.add_link(updated_ref)

            if links_updated > 0:
                print(f"{Fore.GREEN}✓ Updated {links_updated} relative link(s) in moved file")
                self.stats["links_updated"] += links_updated
            else:
                print(f"{Fore.CYAN}   No links needed updating")

        except Exception as e:
            print(f"{Fore.RED}✗ Error updating links within moved file: {e}")
            self.stats["errors"] += 1

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
            print(
                f"{Fore.YELLOW}Warning: Could not calculate updated path for {original_target}: {e}"
            )
            return original_target

    def _get_files_under_directory(self, dir_path: str) -> set:
        """Get all files known to the database under a given directory path.

        Checks both link targets and source files to find all files
        that are tracked in the database under the specified directory.

        Link targets in the DB are stored as they appear in the source file
        (relative to the source file's location), so we must resolve each
        target to a project-root-relative path before comparing with dir_path.
        """
        dir_prefix = normalize_path(dir_path.rstrip("/\\") + "/")
        known_files = set()

        # Check link targets (keys in the links dict)
        for target_path, references in list(self.link_db.links.items()):
            base_target = target_path.split("#", 1)[0] if "#" in target_path else target_path
            normalized = normalize_path(base_target)

            # Direct prefix match (for already project-root-relative targets)
            if normalized.startswith(dir_prefix):
                known_files.add(normalized)
                continue

            # Resolve relative targets using source file paths
            for ref in references:
                ref_dir = os.path.dirname(normalize_path(ref.file_path))
                try:
                    resolved = os.path.normpath(os.path.join(ref_dir, normalized)).replace(
                        "\\", "/"
                    )
                    if resolved.startswith(dir_prefix):
                        known_files.add(resolved)
                        break  # One match is enough for this target
                except Exception:
                    pass

        # Check source files (files that contain links)
        for file_path in list(self.link_db.files_with_links):
            normalized = normalize_path(file_path)
            if normalized.startswith(dir_prefix):
                known_files.add(normalized)

        return known_files

    def _should_monitor_file(self, file_path: str) -> bool:
        """Check if a file should be monitored."""
        return should_monitor_file(file_path, self.monitored_extensions, self.ignored_dirs)

    def _get_relative_path(self, abs_path: str) -> str:
        """Convert absolute path to relative path from project root."""
        return get_relative_path(abs_path, str(self.project_root))

    def get_stats(self) -> dict:
        """Get handler statistics."""
        return self.stats.copy()

    def reset_stats(self):
        """Reset statistics counters."""
        for key in self.stats:
            self.stats[key] = 0
