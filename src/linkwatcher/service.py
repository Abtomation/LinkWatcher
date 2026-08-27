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
from .liveness import WatchLivenessMonitor
from .logging import LogTimer, get_logger, with_context
from .parser import LinkParser
from .parsers.base import BaseParser
from .updater import LinkUpdater
from .utils import (
    compute_own_output_exclusions,
    get_relative_path,
    is_own_output,
    should_monitor_file,
)
from .winapi_patch import install_watch_root_deletion_fix

# Name of the watch-liveness probe file (PD-BUG-139).  Shared by the path
# resolver and the shutdown cleanup so the two can never disagree about
# which file the daemon is responsible for.
LIVENESS_SENTINEL_NAME = ".linkwatcher-liveness-probe"


class LinkWatcherService:
    """
    Main service that orchestrates all LinkWatcher components.

    This service:
    1. Initializes all components
    2. Manages the file system observer
    3. Handles graceful shutdown
    4. Provides status and statistics
    """

    def __init__(
        self,
        project_root: str = ".",
        config: LinkWatcherConfig = None,
        register_signals: bool = True,
    ):
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
        # Lifecycle flags kept separate from `running` (PD-BUG-144).  `running`
        # answers "should the monitoring loop keep looping", and every path that
        # leaves that loop clears it *before* `stop()` is reached — so it cannot
        # also answer "has shutdown already happened".  `_started` is set once
        # the observer thread is actually running; `_stopped` on the first real
        # shutdown.
        self._started = False
        self._stopped = False
        self._liveness_monitor = None
        self._liveness_sentinel = None

        # Initialize components
        self.logger.debug("initializing_components")
        self.link_db = LinkDatabase(
            parser_type_extensions=config.parser_type_extensions if config else None
        )
        self.parser = LinkParser(config=config)
        self.updater = LinkUpdater(
            str(self.project_root),
            python_source_root=config.python_source_root if config else "",
            path_resolution_overrides=config.path_resolution_overrides if config else None,
        )
        self.handler = LinkMaintenanceHandler(
            self.link_db,
            self.parser,
            self.updater,
            str(self.project_root),
            monitored_extensions=config.monitored_extensions if config else None,
            ignored_directories=config.ignored_directories if config else None,
            config=config,
        )

        if config is not None:
            self.updater.set_dry_run(config.dry_run_mode)
            self.updater.set_backup_enabled(config.create_backups)

        # Setup signal handlers for graceful shutdown
        if register_signals:
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
            # Sweep a probe stranded by a previous daemon (PD-BUG-145).  The
            # normal stop paths are hard kills — `Stop-Process -Force` from
            # stop_linkwatcher.ps1, `psutil terminate()` from the Control
            # Panel — and neither runs Python shutdown code, so startup is the
            # only hook that can clean up after them (an atexit/signal handler
            # cannot: TerminateProcess gives the process no chance to run).
            #
            # Placement is load-bearing twice over.  It must run AFTER logging
            # setup, because `_liveness_sentinel_path` pins its answer for the
            # daemon's lifetime and that answer depends on whether the log
            # directory exists yet — sweeping any earlier would pin the
            # project-root fallback and relocate the probe for every
            # deployment.  Callers satisfy this: main.py runs setup_logging()
            # before constructing the service.  It must also run BEFORE the
            # observer starts, so the delete emits no event to dispatch.
            self._remove_liveness_sentinel()

            # Activate event deferral so events arriving during initial
            # scan are queued until the link DB is fully populated (PD-BUG-053)
            self.handler.begin_event_deferral()

            # Setup and start file system observer BEFORE initial scan
            # so that file moves during the scan are captured (PD-BUG-053)
            self.logger.debug("setting_up_file_observer")
            # PD-BUG-141: watchdog's watch-root deletion predicate is a
            # constant true on Windows, so any transient ReadDirectoryChangesW
            # error is rewritten into a synthetic deletion that permanently
            # stops the emitter. Correct it before the observer is built.
            if os.name == "nt" and not install_watch_root_deletion_fix():
                self.logger.warning(
                    "watch_root_deletion_fix_unavailable",
                    detail=(
                        "Could not install the corrected watch-root deletion check "
                        "(PD-BUG-141). A transient file-observation error may stop "
                        "the watch instead of being reported. Check the watchdog version."
                    ),
                )
            self.observer = Observer()
            self.observer.schedule(self.handler, str(self.project_root), recursive=True)
            self.observer.start()
            # Only now is the observer thread joinable.  Set *after*
            # `observer.start()` returns so a failure above (a `schedule()`
            # raising, say) leaves `stop()` — which the `finally` below always
            # calls — with nothing to unwind (PD-BUG-144).
            self._started = True
            self.running = True

            # Perform initial scan if requested
            if initial_scan:
                self.logger.info("initial_scan_starting")
                with LogTimer(
                    "initial_scan",
                    self.logger,
                    enabled=(self.config or DEFAULT_CONFIG).performance_logging,
                ):
                    self._initial_scan()

                stats = self.link_db.get_stats()
                self.logger.info(
                    "initial_scan_complete",
                    files_with_links=stats["files_with_links"],
                    total_references=stats["total_references"],
                    total_targets=stats["total_targets"],
                )

            # Signal handler that DB is fully populated — replay any
            # events that arrived during the initial scan (PD-BUG-053)
            self.handler.notify_scan_complete()

            self.logger.info("monitoring_started")

            # Keep the service running, monitoring watch health
            self._liveness_monitor = self._build_liveness_monitor()
            try:
                while self.running:
                    time.sleep(1)
                    if not self._watch_is_healthy():
                        self.running = False
            except KeyboardInterrupt:
                pass

        except Exception as e:
            self.logger.error("service_start_failed", error=str(e), error_type=type(e).__name__)
            raise
        finally:
            self.stop()

    def _liveness_sentinel_path(self) -> str:
        """Where the liveness probe file lives (PD-BUG-139).

        Preferred home is the daemon's own-output directory, which is already
        excluded from both the initial scan and event handling (PD-BUG-107),
        so the probe cannot pollute the link database even if the drop in
        ``handler.dispatch`` were ever bypassed — and, being where the daemon
        already writes, it is somewhere users already exclude from version
        control.  When the log lives at the project root or outside the
        project there is no such directory inside the watched tree, so the
        probe falls back to a dotfile at the project root — it still must be
        inside the tree to prove the watch works.

        Resolved once and pinned for the daemon's lifetime: the answer depends
        on whether the log directory exists yet, so re-resolving at shutdown
        could name a different file than the one the probe actually wrote and
        leave the real one behind.
        """
        if self._liveness_sentinel is not None:
            return self._liveness_sentinel

        self._liveness_sentinel = self._resolve_liveness_sentinel_path()
        return self._liveness_sentinel

    def _resolve_liveness_sentinel_path(self) -> str:
        """Compute the sentinel path — see :meth:`_liveness_sentinel_path`."""
        config = self.config if self.config else DEFAULT_CONFIG
        own_output = compute_own_output_exclusions(config.log_file, str(self.project_root))

        # Read the registry's "dirs" set explicitly.  Iterating the registry
        # itself yields its KEYS ("dirs", "file_stems"), never a directory, so
        # the own-output branch below silently never fired and every daemon
        # fell through to the project-root fallback (code-review finding on
        # the original PD-BUG-139 fix).  Sorted for a deterministic choice if
        # a future daemon output registers a second directory.
        for directory in sorted(own_output["dirs"]):
            candidate = Path(directory)
            if candidate.is_dir() and self.project_root in candidate.parents:
                return str(candidate / LIVENESS_SENTINEL_NAME)

        return str(self.project_root / LIVENESS_SENTINEL_NAME)

    @staticmethod
    def _write_liveness_sentinel(sentinel_path: str):
        """Touch the sentinel so the OS emits an event for it."""
        with open(sentinel_path, "w", encoding="utf-8") as handle:
            handle.write(str(time.time()))

    def _build_liveness_monitor(self):
        """Construct the watch-liveness monitor from config (PD-BUG-139)."""
        config = self.config if self.config else DEFAULT_CONFIG
        return WatchLivenessMonitor(
            observer=self.observer,
            handler=self.handler,
            logger=self.logger,
            idle_seconds=config.watch_liveness_idle_seconds,
            probe_timeout=config.watch_liveness_probe_timeout,
            failure_threshold=config.watch_liveness_failure_threshold,
            sentinel_path=self._liveness_sentinel_path(),
            write_sentinel=self._write_liveness_sentinel,
            enabled=config.watch_liveness_enabled,
        )

    def _watch_is_healthy(self) -> bool:
        """One health poll of the file system watch.

        Two layers (PD-BUG-139).  ``observer.is_alive()`` covers a dead
        dispatcher thread (PD-BUG-018).  The liveness monitor covers the case
        that fix cannot see: a live observer whose watch has stopped
        delivering, which previously left the daemon blind and silent for its
        whole lifetime.

        Returns:
            bool: False when the daemon must stop rather than keep running
            blind.
        """
        if self.observer and not self.observer.is_alive():
            self.logger.error(
                "observer_thread_died",
                detail="Watchdog observer thread is no longer alive",
            )
            return False

        monitor = getattr(self, "_liveness_monitor", None)
        if monitor is not None and not monitor.check():
            return False

        return True

    def stop(self):
        """Stop the LinkWatcher service."""
        # Kept OUTSIDE the idempotence guard below so cleanup cannot be lost to
        # a future early return added there.  It originally sat here to escape
        # the `running` guard that PD-BUG-144 has since replaced; the unlink is
        # idempotent and costs nothing, so it stays unconditional.  This is the
        # clean-stop layer only — it is unreachable on the hard kills that
        # normally end this daemon, which is why the probe is also discarded
        # after each round trip and swept at startup (PD-BUG-145).
        self._remove_liveness_sentinel()

        # Idempotence is tracked on `_stopped`, never on `running` (PD-BUG-144).
        # Every path that reaches this method has already cleared `running` —
        # the monitoring loop clears it on a liveness failure or a dead observer
        # thread, and `_signal_handler` clears it on SIGINT/SIGTERM — so a
        # `running` guard skipped the whole sequence on exactly the self-stop
        # and Ctrl+C shutdowns: the observer was never stopped or joined
        # (0.1.1-FR-5), statistics were never printed (0.1.1-FR-6), and the log
        # carried no shutdown record, leaving an operator unable to tell a clean
        # stop from a crash.  `_started` keeps a service that never ran silent.
        if not self._started or self._stopped:
            return
        self._stopped = True

        self.logger.info("service_stopping")
        self.running = False

        if self.observer:
            self.observer.stop()
            self.observer.join()
            self.logger.debug("file_observer_stopped")

        # Log final statistics
        self._print_final_stats()
        self.logger.info("service_stopped")

    def _remove_liveness_sentinel(self):
        """Best-effort removal of the liveness probe file (PD-BUG-139).

        The probe is daemon-scoped scaffolding, not project content — a file
        left behind outlives the daemon that explains it, and in the
        project-root fallback case it would surface as a stray untracked file
        in the user's repository.

        Called from two places (PD-BUG-145), neither of them after the
        observer has stopped: at the top of ``start()``, to sweep a probe
        stranded by a hard-killed predecessor, and at the top of ``stop()``
        for the clean-stop path.  A failure here must never obstruct either —
        on shutdown the daemon is already on its way out, and on startup a
        stale probe is inert — so the error is logged at debug and swallowed.
        """
        try:
            Path(self._liveness_sentinel_path()).unlink(missing_ok=True)
        except OSError as e:
            self.logger.debug("liveness_sentinel_cleanup_failed", error=str(e))

    def _initial_scan(self):
        """Perform initial scan of all monitored files."""
        scanned_files = 0
        scan_errors = 0
        config = self.config if self.config else DEFAULT_CONFIG
        ignored_dirs = config.ignored_directories
        monitored_extensions = config.monitored_extensions
        # PD-BUG-107: the daemon's own outputs (log + colocated files)
        # must never be parsed into the link database.
        own_output = compute_own_output_exclusions(config.log_file, str(self.project_root))

        for root, dirs, files in os.walk(self.project_root):
            # Skip ignored directories
            dirs[:] = [d for d in dirs if d not in ignored_dirs]
            # PD-BUG-107: never descend into the own-output zone
            dirs[:] = [d for d in dirs if not is_own_output(os.path.join(root, d), own_output)]

            for file in files:
                file_path = os.path.join(root, file)

                # PD-BUG-107: skip own-output files (covers the
                # log-in-project-root rotation-sibling case)
                if is_own_output(file_path, own_output):
                    continue

                if should_monitor_file(
                    file_path, monitored_extensions, ignored_dirs, str(self.project_root)
                ):
                    try:
                        references = self.parser.parse_file(file_path)
                        # Normalize file paths to relative paths before storing
                        relative_file_path = get_relative_path(file_path, str(self.project_root))
                        for ref in references:
                            # Update the reference to use relative path
                            ref.file_path = relative_file_path
                        self.link_db.add_links_batch(references)
                        scanned_files += 1

                        progress_interval = config.scan_progress_interval
                        if scanned_files % progress_interval == 0:
                            info_milestone = scanned_files % (progress_interval * 4) == 0
                            self.logger.scan_progress(scanned_files, info_level=info_milestone)

                    except Exception as e:
                        scan_errors += 1
                        self.logger.warning(
                            "file_scan_failed",
                            file_path=file_path,
                            error=str(e),
                            error_type=type(e).__name__,
                        )

        self.link_db.last_scan = time.time()
        self.logger.info("scan_complete", files_scanned=scanned_files, scan_errors=scan_errors)

    def _signal_handler(self, signum, frame):
        """Handle shutdown signals."""
        self.logger.info("shutdown_signal_received", signal=signum)
        self.running = False

    def _print_final_stats(self):
        """Print final statistics before shutdown."""
        config = self.config if self.config else DEFAULT_CONFIG
        if not config.show_statistics:
            return
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
        self.handler.add_monitored_extension(extension)

    def check_links(self) -> dict:
        """Check all links and return broken ones."""
        self.logger.info("link_check_starting")

        broken_links = []
        total_checked = 0

        for target_path, references in self.link_db.get_all_targets_with_references().items():
            total_checked += len(references)

            # Strip #fragment anchors before filesystem check (PD-BUG-070)
            check_path = target_path.split("#", 1)[0] if "#" in target_path else target_path
            target_abs_path = os.path.join(self.project_root, check_path)
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
