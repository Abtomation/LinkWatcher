"""
Main LinkWatcher service that orchestrates all components.

This module provides the main service class that coordinates the database,
parser, updater, and file system handler.

AI Context
----------
- **Entry point**: ``LinkWatcherService`` is the top-level orchestrator.
  ``start()`` wires all components and begins file watching;
  ``stop()`` tears down gracefully.
- **Delegation**: service → handler (event dispatch), database (link
  storage), parser (link extraction), updater (file modification).
  Service owns the watchdog ``Observer`` and the initial scan loop.
- **Common tasks**:
  - Adding a new component: wire it in ``__init__``, pass to handler
    or call from the scan loop.
  - Debugging startup: check ``_initial_scan()`` — it walks the project
    tree, filters via ``should_monitor_file()``, and populates the DB.
  - Debugging shutdown: ``_signal_handler()`` and ``stop()`` coordinate
    observer shutdown and handler cleanup.
  - Statistics: ``get_stats()`` aggregates status from all sub-components.
"""

import os
import signal
import time
from pathlib import Path

from watchdog.observers import Observer

from .config.defaults import DEFAULT_CONFIG
from .config.settings import LinkWatcherConfig
from .database import LinkDatabase
from .handler import LinkMaintenanceHandler
from .logging import LogTimer, get_logger, with_context
from .parser import LinkParser
from .parsers.base import BaseParser
from .updater import LinkUpdater
from .utils import get_relative_path, should_monitor_file


class LinkWatcherService:
    """
    Main service that orchestrates all LinkWatcher components.

    This service:
    1. Initializes all components
    2. Manages the file system observer
    3. Handles graceful shutdown
    4. Provides status and statistics
    """

    def __init__(self, project_root: str = ".", config: LinkWatcherConfig = None):
        self.project_root = Path(project_root).resolve()
        self.config = config
        self.logger = get_logger()

        # Validate project root exists
        if not self.project_root.exists():
            self.logger.error("project_root_not_found", path=str(self.project_root))
            raise FileNotFoundError(f"Project root does not exist: {self.project_root}")

        if not self.project_root.is_dir():
            self.logger.error("project_root_not_directory", path=str(self.project_root))
            raise NotADirectoryError(f"Project root is not a directory: {self.project_root}")

        self.observer = None
        self.running = False

        # Initialize components
        self.logger.debug("initializing_components")
        self.link_db = LinkDatabase()
        self.parser = LinkParser(config=config)
        self.updater = LinkUpdater(str(self.project_root))
        self.handler = LinkMaintenanceHandler(
            self.link_db,
            self.parser,
            self.updater,
            str(self.project_root),
            monitored_extensions=config.monitored_extensions if config else None,
            ignored_directories=config.ignored_directories if config else None,
            config=config,
        )

        # Setup signal handlers for graceful shutdown
        signal.signal(signal.SIGINT, self._signal_handler)
        signal.signal(signal.SIGTERM, self._signal_handler)

        self.logger.info("service_initialized", project_root=str(self.project_root))

    @with_context(component="service")
    def start(self, initial_scan: bool = True):
        """
        Start the LinkWatcher service.

        Args:
            initial_scan: Whether to perform initial scan of all files
        """
        self.logger.info("service_starting", project_root=str(self.project_root))

        try:
            # Perform initial scan if requested
            if initial_scan:
                self.logger.info("initial_scan_starting")
                with LogTimer("initial_scan", self.logger):
                    self._initial_scan()

                stats = self.link_db.get_stats()
                self.logger.info(
                    "initial_scan_complete",
                    files_with_links=stats["files_with_links"],
                    total_references=stats["total_references"],
                    total_targets=stats["total_targets"],
                )

            # Setup file system observer
            self.logger.debug("setting_up_file_observer")
            self.observer = Observer()
            self.observer.schedule(self.handler, str(self.project_root), recursive=True)

            # Start watching
            self.observer.start()
            self.running = True

            self.logger.info("monitoring_started")

            # Keep the service running, monitoring observer health
            try:
                while self.running:
                    time.sleep(1)
                    if self.observer and not self.observer.is_alive():
                        self.logger.error(
                            "observer_thread_died",
                            message="Watchdog observer thread is no longer alive",
                        )
                        self.running = False
            except KeyboardInterrupt:
                pass

        except Exception as e:
            self.logger.error("service_start_failed", error=str(e), error_type=type(e).__name__)
            raise
        finally:
            self.stop()

    def stop(self):
        """Stop the LinkWatcher service."""
        if self.running:
            self.logger.info("service_stopping")
            self.running = False

            if self.observer:
                self.observer.stop()
                self.observer.join()
                self.logger.debug("file_observer_stopped")

            # Log final statistics
            self._print_final_stats()
            self.logger.info("service_stopped")

    def _initial_scan(self):
        """Perform initial scan of all monitored files."""
        scanned_files = 0
        config = self.config if self.config else DEFAULT_CONFIG
        ignored_dirs = config.ignored_directories
        monitored_extensions = config.monitored_extensions

        for root, dirs, files in os.walk(self.project_root):
            # Skip ignored directories
            dirs[:] = [d for d in dirs if d not in ignored_dirs]

            for file in files:
                file_path = os.path.join(root, file)

                if should_monitor_file(file_path, monitored_extensions, ignored_dirs):
                    try:
                        references = self.parser.parse_file(file_path)
                        # Normalize file paths to relative paths before storing
                        relative_file_path = get_relative_path(file_path, str(self.project_root))
                        for ref in references:
                            # Update the reference to use relative path
                            ref.file_path = relative_file_path
                            self.link_db.add_link(ref)
                        scanned_files += 1

                        if scanned_files % 50 == 0:  # Progress indicator
                            self.logger.scan_progress(scanned_files)

                    except Exception as e:
                        self.logger.warning(
                            "file_scan_failed",
                            file_path=file_path,
                            error=str(e),
                            error_type=type(e).__name__,
                        )

        self.link_db.last_scan = time.time()
        self.logger.info("scan_complete", files_scanned=scanned_files)

    def _signal_handler(self, signum, frame):
        """Handle shutdown signals."""
        self.logger.info("shutdown_signal_received", signal=signum)
        self.running = False

    def _print_final_stats(self):
        """Print final statistics before shutdown."""
        handler_stats = self.handler.get_stats()
        db_stats = self.link_db.get_stats()

        # Log final statistics
        self.logger.operation_stats(
            files_moved=handler_stats["files_moved"],
            files_deleted=handler_stats["files_deleted"],
            files_created=handler_stats["files_created"],
            links_updated=handler_stats["links_updated"],
            errors=handler_stats["errors"],
            total_references=db_stats["total_references"],
            total_targets=db_stats["total_targets"],
        )

    def get_status(self) -> dict:
        """Get current service status."""
        return {
            "running": self.running,
            "project_root": str(self.project_root),
            "database_stats": self.link_db.get_stats(),
            "handler_stats": self.handler.get_stats(),
            "last_scan": self.link_db.last_scan,
        }

    def force_rescan(self):
        """Force a complete rescan of all files."""
        self.logger.info("rescan_starting")
        self.link_db.clear()
        self._initial_scan()
        self.logger.info("rescan_complete")

    def set_dry_run(self, enabled: bool):
        """Enable or disable dry run mode."""
        self.updater.set_dry_run(enabled)
        self.logger.info("dry_run_toggled", enabled=enabled)

    def add_parser(self, extension: str, parser: BaseParser):
        """Add a custom parser for a specific file extension."""
        self.parser.add_parser(extension, parser)
        # Update handler's monitored extensions
        self.handler.monitored_extensions.add(extension.lower())

    def check_links(self) -> dict:
        """Check all links and return broken ones."""
        self.logger.info("link_check_starting")

        broken_links = []
        total_checked = 0

        for target_path, references in self.link_db.get_all_targets_with_references().items():
            total_checked += len(references)

            # Check once per target — all references share the same path
            target_abs_path = os.path.join(self.project_root, target_path)
            if not os.path.exists(target_abs_path):
                for ref in references:
                    broken_links.append(
                        {"reference": ref, "target_path": target_path, "reason": "File not found"}
                    )

        result = {
            "total_checked": total_checked,
            "broken_count": len(broken_links),
            "broken_links": broken_links,
        }

        if broken_links:
            self.logger.warning(
                "broken_links_found",
                broken_count=len(broken_links),
                total_checked=total_checked,
            )
            for broken in broken_links[:10]:
                ref = broken["reference"]
                self.logger.warning(
                    "broken_link",
                    source=f"{ref.file_path}:{ref.line_number}",
                    target=broken["target_path"],
                    reason=broken["reason"],
                )
            if len(broken_links) > 10:
                self.logger.warning(
                    "broken_links_truncated",
                    remaining=len(broken_links) - 10,
                )
        else:
            self.logger.info("all_links_valid", total_checked=total_checked)

        return result
