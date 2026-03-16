"""
File system event handler for the LinkWatcher system.

This module handles file system events (move, delete, create) and
coordinates the appropriate responses.
"""

import os
import threading
from pathlib import Path

from colorama import Fore
from watchdog.events import (
    FileCreatedEvent,
    FileDeletedEvent,
    FileMovedEvent,
    FileSystemEventHandler,
)

from .config.defaults import DEFAULT_CONFIG
from .database import LinkDatabase
from .dir_move_detector import DirectoryMoveDetector
from .logging import get_logger, with_context
from .move_detector import MoveDetector
from .parser import LinkParser
from .reference_lookup import ReferenceLookup
from .updater import LinkUpdater
from .utils import get_relative_path, should_monitor_file


class _SyntheticMoveEvent:
    """Lightweight event object for programmatic move handling.

    Mimics watchdog's FileMovedEvent interface with src_path, dest_path,
    and is_directory attributes. Used when moves are detected via
    delete+create correlation rather than native OS move events.
    """

    __slots__ = ("src_path", "dest_path", "is_directory")

    def __init__(self, src_path, dest_path, is_directory=False):
        self.src_path = src_path
        self.dest_path = dest_path
        self.is_directory = is_directory


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

        # Per-file move detection (delete+create correlation)
        self._move_detector = MoveDetector(
            on_move_detected=self._handle_detected_move,
            on_true_delete=self._process_true_file_delete,
            delay=10.0,
        )

        # Directory move detection (batch, for directory moves on Windows)
        self._dir_move_detector = DirectoryMoveDetector(
            link_db=link_db,
            project_root=self.project_root,
            on_dir_move=self._handle_confirmed_dir_move,
            on_true_file_delete=self._process_true_file_delete,
            max_timeout=300.0,
            settle_delay=5.0,
        )

        # Reference lookup, DB management, and link updates (TD022/TD035 extractions)
        self._ref_lookup = ReferenceLookup(
            link_db=link_db,
            parser=parser,
            updater=updater,
            project_root=self.project_root,
            logger=self.logger,
        )

        # Statistics (protected by _stats_lock — PD-BUG-026)
        self.stats = {
            "files_moved": 0,
            "files_deleted": 0,
            "files_created": 0,
            "links_updated": 0,
            "errors": 0,
        }
        self._stats_lock = threading.Lock()

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
            self._update_stat("errors")

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
                known_files = self._dir_move_detector.get_files_under_directory(deleted_path)
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
            self._update_stat("errors")

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
            self._update_stat("errors")

    def on_error(self, event):
        """Handle watchdog errors to prevent silent observer thread death."""
        self.logger.error(
            "watchdog_error",
            error=str(event),
            error_type=type(event).__name__,
        )
        self._update_stat("errors")

    @with_context(component="handler", operation="file_move")
    def _handle_file_moved(self, event: FileMovedEvent):
        """Handle individual file move."""
        old_path = self._get_relative_path(event.src_path)
        new_path = self._get_relative_path(event.dest_path)

        if not old_path or not new_path:
            return

        self.logger.file_moved(old_path, new_path)

        try:
            # Get all references to the old file using all path format variations
            references = self._ref_lookup.find_references(old_path)

            if references:
                print(f"{Fore.YELLOW}🔗 Updating {len(references)} unique references...")

                # Collect old path variations for DB cleanup FIRST
                # before making any changes (since each update modifies the database)
                old_targets = self._ref_lookup.get_old_path_variations(old_path)

                # Update the files FIRST (before modifying the database)
                update_stats = self.updater.update_references(references, old_path, new_path)

                # Handle stale line numbers: rescan affected files and retry once
                self._ref_lookup.retry_stale_references(old_path, new_path, update_stats)

                # Remove old DB entries and rescan affected files
                # Pass old_path so the moved file is skipped here —
                # _update_links_within_moved_file handles it below
                self._ref_lookup.cleanup_after_file_move(
                    references, old_targets, moved_file_path=old_path
                )

                # Update statistics
                self._update_stat("links_updated", update_stats["references_updated"])
                self._update_stat("errors", update_stats["errors"])

                # Report results
                if update_stats["files_updated"] > 0:
                    self.logger.info(
                        "file_move_completed",
                        files_updated=update_stats["files_updated"],
                        references_updated=update_stats["references_updated"],
                    )
                else:
                    self.logger.info("no_files_updated", old_path=old_path, new_path=new_path)
            else:
                self.logger.warning("no_references_found", old_path=old_path, new_path=new_path)

            # If the moved file contains links, update its entries and fix relative paths
            if self._should_monitor_file(event.dest_path):
                # Update links within the moved file to reflect new relative paths
                # This method handles both content updates and database updates
                self._update_links_within_moved_file(old_path, new_path, event.dest_path)

            self._update_stat("files_moved")

        except Exception as e:
            self.logger.error(
                "file_move_error",
                old_path=old_path,
                new_path=new_path,
                error=str(e),
                error_type=type(e).__name__,
            )
            self._update_stat("errors")

    def _handle_directory_moved(self, event: FileMovedEvent):
        """Handle directory move - affects all files within.

        Walks the moved directory to find all monitored files, then delegates
        per-file reference updates to ReferenceLookup.process_directory_file_move().
        """
        old_dir = self._get_relative_path(event.src_path)
        new_dir = self._get_relative_path(event.dest_path)

        self.logger.info("directory_moved", old_dir=old_dir, new_dir=new_dir)

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

            # Process each moved file via ReferenceLookup
            total_references_updated = 0
            for old_file_path, new_file_path in moved_files:
                refs_updated, errors = self._ref_lookup.process_directory_file_move(
                    old_file_path, new_file_path
                )
                total_references_updated += refs_updated
                self._update_stat("errors", errors)

            # Phase 2: Update references to the directory path itself
            # (e.g., quoted directory paths in PowerShell scripts)
            #
            # Directory-path references may target the moved directory exactly
            # OR subdirectories within it (e.g., old_dir/assessments).  The
            # updater's path resolver expects old_path to match ref.link_target
            # exactly, so we group references by their link_target and compute
            # the correct per-target old→new mapping using prefix replacement.
            dir_refs = self._ref_lookup.find_directory_path_references(old_dir)
            dir_refs_updated = 0
            if dir_refs:
                from .utils import normalize_path as _norm

                old_dir_norm = _norm(old_dir)
                old_dir_prefix = old_dir_norm.rstrip("/") + "/"
                new_dir_norm = _norm(new_dir)

                # Group references by their link_target
                refs_by_target = {}
                for ref in dir_refs:
                    refs_by_target.setdefault(ref.link_target, []).append(ref)

                for target, target_refs in refs_by_target.items():
                    target_norm = _norm(target)
                    if target_norm == old_dir_norm:
                        # Exact directory match — use old_dir / new_dir directly
                        ref_old = old_dir
                        ref_new = new_dir
                    elif target_norm.startswith(old_dir_prefix):
                        # Subdirectory match — replace the prefix
                        suffix = target_norm[len(old_dir_prefix) :]
                        ref_old = target
                        ref_new = new_dir_norm + "/" + suffix
                    else:
                        # Fallback (e.g., backslash variant) — simple string replace
                        ref_old = target
                        ref_new = (
                            target.replace(
                                old_dir.replace("/", "\\"),
                                new_dir.replace("/", "\\"),
                            )
                            if "\\" in target
                            else target.replace(old_dir, new_dir)
                        )

                    stats = self.updater.update_references(target_refs, ref_old, ref_new)
                    dir_refs_updated += stats["references_updated"]
                    self._update_stat("errors", stats["errors"])

                total_references_updated += dir_refs_updated
                self._ref_lookup.cleanup_after_directory_path_move(old_dir, new_dir)
                self.logger.info(
                    "directory_path_references_updated",
                    old_dir=old_dir,
                    new_dir=new_dir,
                    count=dir_refs_updated,
                )

            self.logger.info(
                "directory_move_completed",
                total_references_updated=total_references_updated,
                moved_files_count=len(moved_files),
                dir_path_refs_updated=dir_refs_updated,
            )
            self._update_stat("links_updated", total_references_updated)
            self._update_stat("files_moved", len(moved_files))

        except Exception as e:
            self.logger.error(
                "directory_move_error",
                old_dir=old_dir,
                new_dir=new_dir,
                error=str(e),
                error_type=type(e).__name__,
            )
            self._update_stat("errors")

    def _handle_file_deleted(self, event: FileDeletedEvent):
        """Handle file deletion with delayed move detection."""
        deleted_path = self._get_relative_path(event.src_path)
        self.logger.file_deleted(deleted_path)
        self._move_detector.buffer_delete(deleted_path, event.src_path)

    def _handle_directory_deleted(self, event: FileDeletedEvent):
        """Handle directory deletion with batch move detection."""
        deleted_dir = self._get_relative_path(event.src_path)
        self.logger.warning("directory_deleted", deleted_dir=deleted_dir)
        self._dir_move_detector.handle_directory_deleted(deleted_dir)

    def _handle_file_created(self, event: FileCreatedEvent):
        """Handle file creation with move detection."""
        created_path = self._get_relative_path(event.src_path)

        # Check directory moves first (has priority over per-file detection)
        if self._dir_move_detector.match_created_file(created_path, event.src_path):
            return

        # Check if this might be a per-file move operation
        potential_move_source = self._move_detector.match_created_file(created_path, event.src_path)

        if potential_move_source:
            # Handle as move operation
            self.logger.info(
                "move_detected", source=potential_move_source, destination=created_path
            )
            self._handle_detected_move(potential_move_source, created_path)
        else:
            # Handle as regular file creation
            self.logger.file_created(created_path)
            try:
                # Scan the new file for links
                self._ref_lookup.rescan_file_links(event.src_path)
                self._update_stat("files_created")
            except Exception as e:
                self.logger.error(
                    "file_creation_error",
                    created_path=created_path,
                    error=str(e),
                    error_type=type(e).__name__,
                )
                self._update_stat("errors")

    def _handle_detected_move(self, old_path: str, new_path: str):
        """Handle a detected move operation."""
        try:
            # Create a synthetic move event and handle it
            project_root_str = str(self.project_root)
            synthetic_event = _SyntheticMoveEvent(
                os.path.join(project_root_str, old_path),
                os.path.join(project_root_str, new_path),
                is_directory=False,
            )
            self._handle_file_moved(synthetic_event)

        except Exception as e:
            self.logger.error(
                "detected_move_error",
                old_path=old_path,
                new_path=new_path,
                error=str(e),
                error_type=type(e).__name__,
            )
            self._update_stat("errors")

    def _handle_confirmed_dir_move(self, old_dir, new_dir):
        """Callback from DirectoryMoveDetector for confirmed directory moves."""
        project_root_str = str(self.project_root)
        synthetic = _SyntheticMoveEvent(
            os.path.join(project_root_str, old_dir),
            os.path.join(project_root_str, new_dir),
            is_directory=True,
        )
        try:
            self._handle_directory_moved(synthetic)
        except Exception as e:
            self.logger.error(
                "dir_move_processing_error",
                old_dir=old_dir,
                new_dir=new_dir,
                error=str(e),
                error_type=type(e).__name__,
            )
            self._update_stat("errors")

    def _update_links_within_moved_file(
        self, old_file_path: str, new_file_path: str, abs_new_path: str
    ):
        """Update relative links within a moved file to reflect its new location.

        Delegates to ReferenceLookup.update_links_within_moved_file() and
        updates handler statistics based on the result.
        """
        links_updated = self._ref_lookup.update_links_within_moved_file(
            old_file_path,
            new_file_path,
            abs_new_path,
            backup_enabled=self.updater.backup_enabled,
        )
        if links_updated:
            self._update_stat("links_updated", links_updated)

    def _process_true_file_delete(self, file_path):
        """Process a single file as a true deletion.

        Used as callback by both MoveDetector (per-file deletes) and
        DirectoryMoveDetector (unmatched files in directory deletes).

        PD-BUG-035: If the file still exists when the timer fires, it was
        replaced (e.g., sed -i), not truly deleted. Rescan instead of removing.
        We no longer remove links from the database on deletion — stale entries
        are harmless (cause non-fatal errors if targets move) and self-heal
        on restart.
        """
        try:
            # PD-BUG-035: Check if file was replaced rather than deleted
            abs_path = os.path.join(str(self.project_root), file_path)
            if os.path.exists(abs_path):
                self.logger.info(
                    "file_replaced_not_deleted",
                    file_path=file_path,
                )
                self._ref_lookup.rescan_file_links(abs_path)
                return

            references = self.link_db.get_references_to_file(file_path)
            if references:
                self.logger.warning(
                    "broken_references_found",
                    deleted_file=file_path,
                    broken_references_count=len(references),
                )
                for ref in references:
                    self.logger.debug(
                        "broken_reference_detail",
                        file_path=ref.file_path,
                        line_number=ref.line_number,
                        link_text=ref.link_text,
                    )
                    print(
                        f"   {Fore.YELLOW}• {ref.file_path}:" f"{ref.line_number} - {ref.link_text}"
                    )

            self._update_stat("files_deleted")
        except Exception as e:
            self.logger.error(
                "file_deletion_error",
                deleted_path=file_path,
                error=str(e),
                error_type=type(e).__name__,
            )
            self._update_stat("errors")

    def _should_monitor_file(self, file_path: str) -> bool:
        """Check if a file should be monitored."""
        return should_monitor_file(file_path, self.monitored_extensions, self.ignored_dirs)

    def _get_relative_path(self, abs_path: str) -> str:
        """Convert absolute path to relative path from project root."""
        return get_relative_path(abs_path, str(self.project_root))

    def _update_stat(self, key: str, delta: int = 1):
        """Thread-safe stats increment (PD-BUG-026)."""
        with self._stats_lock:
            self.stats[key] += delta

    def get_stats(self) -> dict:
        """Get handler statistics."""
        with self._stats_lock:
            return self.stats.copy()

    def reset_stats(self):
        """Reset statistics counters."""
        with self._stats_lock:
            for key in self.stats:
                self.stats[key] = 0
