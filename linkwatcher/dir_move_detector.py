"""
Batch directory move detection via delete+create event correlation.

On Windows, directory moves are reported by watchdog as a directory_deleted
event followed by individual file_created events (instead of a single
DirMovedEvent). This module implements a 3-phase batch detection algorithm:

Phase 1 (Buffer): On directory deletion, snapshot all known files under
    the directory and start a max timeout timer.
Phase 2 (Match): As file_created events arrive, correlate them with the
    buffered directory. Infer the new directory from the first match,
    then verify subsequent files by prefix. Reset a settle timer on
    each match.
Phase 3 (Process): When all files match (or a settle/max timer fires),
    confirm the directory move via callback and process unmatched files.
"""

import os
import threading
import time
from typing import Callable

from .logging import get_logger
from .utils import normalize_path


class _PendingDirMove:
    """Internal state for tracking a pending directory move detection.

    On Windows, directory moves are reported as a directory_deleted event
    followed by individual file_created events. This class tracks the
    state needed to correlate these events and process the move as a
    single batch operation.
    """

    __slots__ = (
        "deleted_dir",
        "known_files",
        "dir_prefix",
        "total_expected",
        "new_dir",
        "matched_count",
        "unmatched",
        "timestamp",
        "max_timer",
        "settle_timer",
    )

    def __init__(self, deleted_dir, known_files):
        self.deleted_dir = deleted_dir
        self.known_files = frozenset(known_files)
        self.dir_prefix = normalize_path(deleted_dir) + "/"
        self.total_expected = len(known_files)
        self.new_dir = None
        self.matched_count = 0
        self.unmatched = set(known_files)
        self.timestamp = time.time()
        self.max_timer = None
        self.settle_timer = None


class DirectoryMoveDetector:
    """Detects directory moves by correlating delete+create event batches.

    Args:
        link_db: LinkDatabase instance for querying known files.
        project_root: Absolute path to the project root.
        on_dir_move: Callback(old_dir, new_dir) for confirmed directory moves.
        on_true_file_delete: Callback(file_path) for confirmed file deletions.
        max_timeout: Max seconds to wait for all files to appear.
        settle_delay: Seconds to wait after last matched file before processing.
    """

    def __init__(
        self,
        link_db,
        project_root,
        on_dir_move: Callable[[str, str], None],
        on_true_file_delete: Callable[[str], None],
        max_timeout: float = 300.0,
        settle_delay: float = 5.0,
    ):
        self._link_db = link_db
        self._project_root = project_root
        self._on_dir_move = on_dir_move
        self._on_true_file_delete = on_true_file_delete
        self._logger = get_logger()

        self.pending_dir_moves = {}  # {deleted_dir: _PendingDirMove}
        self._lock = threading.Lock()
        self._max_timeout = max_timeout
        self._settle_delay = settle_delay

    def handle_directory_deleted(self, deleted_dir):
        """Buffer a directory deletion for batch move detection (Phase 1).

        Snapshots all known files under the directory and starts a max
        timeout timer. Returns True if files were found and buffered.
        """
        known_files = self.get_files_under_directory(deleted_dir)

        if known_files:
            pending = _PendingDirMove(deleted_dir, known_files)

            with self._lock:
                self.pending_dir_moves[deleted_dir] = pending

            pending.max_timer = threading.Timer(
                self._max_timeout,
                self._process_timeout,
                [deleted_dir],
            )
            pending.max_timer.daemon = True
            pending.max_timer.start()

            self._logger.info(
                "dir_move_buffered",
                deleted_dir=deleted_dir,
                known_file_count=len(known_files),
                max_timeout=self._max_timeout,
            )
            self._logger.performance.log_metric(
                "dir_move_batch_size", len(known_files), unit="files",
                deleted_dir=deleted_dir,
            )
            return True
        else:
            self._logger.warning(
                "dir_deletion_no_known_files",
                deleted_dir=deleted_dir,
            )
            return False

    def match_created_file(self, created_path, created_abs_path):
        """Check if a created file matches a pending directory move (Phase 2).

        Returns True if the file was claimed by a directory move, False otherwise.
        """
        if not self.pending_dir_moves:
            return False

        created_normalized = normalize_path(created_path)
        created_basename = os.path.basename(created_path)

        with self._lock:
            for deleted_dir, pending in list(self.pending_dir_moves.items()):
                # PD-BUG-042: If the old directory has been re-created
                # (e.g., by a bulk copy after cleanup), this pending
                # entry is stale — remove it and skip matching.
                old_dir_abs = os.path.join(self._project_root, deleted_dir)
                if os.path.isdir(old_dir_abs):
                    if pending.settle_timer is not None:
                        pending.settle_timer.cancel()
                    if pending.max_timer is not None:
                        pending.max_timer.cancel()
                    del self.pending_dir_moves[deleted_dir]
                    continue

                if pending.new_dir is not None:
                    # We already know the new directory — check by prefix
                    expected_prefix = normalize_path(pending.new_dir) + "/"
                    if created_normalized.startswith(expected_prefix):
                        rel_within_new = created_normalized[len(expected_prefix) :]
                        expected_old = pending.dir_prefix + rel_within_new
                        if expected_old in pending.unmatched:
                            pending.unmatched.discard(expected_old)
                            pending.matched_count += 1
                            self._reset_settle_timer(deleted_dir, pending)

                            self._logger.debug(
                                "dir_move_file_matched",
                                matched=pending.matched_count,
                                total=pending.total_expected,
                                file_name=os.path.basename(created_path),
                            )
                            self._logger.performance.log_metric(
                                "dir_move_match_progress",
                                pending.matched_count,
                                unit="files",
                                total=pending.total_expected,
                                deleted_dir=deleted_dir,
                            )

                            if not pending.unmatched:
                                self._logger.info(
                                    "dir_move_all_files_matched",
                                    matched_count=pending.matched_count,
                                    deleted_dir=deleted_dir,
                                )
                                self._logger.performance.log_metric(
                                    "dir_move_completion_trigger", 1, unit="event",
                                    trigger="all_matched",
                                    matched=pending.matched_count,
                                    total=pending.total_expected,
                                )
                                self._trigger_processing(deleted_dir, pending)
                            return True
                else:
                    # First match — infer new_dir from this file
                    for known_file in list(pending.unmatched):
                        if os.path.basename(known_file) != created_basename:
                            continue

                        # Compute relative path within old directory
                        rel_within_dir = known_file[len(pending.dir_prefix) :]

                        # Check if created path ends with this relative path
                        if rel_within_dir == created_normalized:
                            new_dir = ""
                        elif created_normalized.endswith("/" + rel_within_dir):
                            new_dir = created_normalized[: -(len(rel_within_dir) + 1)]
                        elif "/" not in rel_within_dir and created_normalized.endswith(
                            rel_within_dir
                        ):
                            new_dir = created_normalized[: -len(rel_within_dir)].rstrip("/")
                        else:
                            continue

                        # Sanity: new_dir must differ from old dir
                        if normalize_path(new_dir) == normalize_path(deleted_dir):
                            continue

                        # Match found — set new_dir
                        pending.new_dir = new_dir
                        pending.unmatched.discard(known_file)
                        pending.matched_count = 1
                        self._reset_settle_timer(deleted_dir, pending)

                        first_match_latency_ms = (time.time() - pending.timestamp) * 1000
                        self._logger.info(
                            "dir_move_detected",
                            old_dir=deleted_dir,
                            new_dir=new_dir,
                            first_match=created_path,
                            total_expected=pending.total_expected,
                        )
                        self._logger.performance.log_metric(
                            "dir_move_first_match_latency",
                            round(first_match_latency_ms, 2),
                            unit="ms",
                            deleted_dir=deleted_dir,
                            new_dir=new_dir,
                        )

                        if not pending.unmatched:
                            self._logger.info(
                                "dir_move_all_files_matched",
                                matched_count=pending.matched_count,
                                deleted_dir=deleted_dir,
                            )
                            self._logger.performance.log_metric(
                                "dir_move_completion_trigger", 1, unit="event",
                                trigger="all_matched",
                                matched=pending.matched_count,
                                total=pending.total_expected,
                            )
                            self._trigger_processing(deleted_dir, pending)
                        return True

        return False

    def get_files_under_directory(self, dir_path):
        """Get all files known to the database under a given directory path.

        Checks both link targets and source files to find all files
        that are tracked in the database under the specified directory.

        Link targets in the DB are stored as they appear in the source file
        (relative to the source file's location), so we must resolve each
        target to a project-root-relative path before comparing with dir_path.
        """
        dir_prefix = normalize_path(dir_path.rstrip("/\\")) + "/"
        known_files = set()

        # Check link targets via thread-safe snapshot
        all_targets = self._link_db.get_all_targets_with_references()
        for target_path, references in all_targets.items():
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
                        break
                except Exception:
                    pass

        # Check source files (files that contain links)
        for file_path in self._link_db.get_source_files():
            normalized = normalize_path(file_path)
            if normalized.startswith(dir_prefix):
                known_files.add(normalized)

        return known_files

    # --- Internal timer and processing methods ---

    def _reset_settle_timer(self, deleted_dir, pending):
        """Reset the settle timer for a directory move."""
        if pending.settle_timer is not None:
            pending.settle_timer.cancel()
        pending.settle_timer = threading.Timer(
            self._settle_delay,
            self._process_settled,
            [deleted_dir],
        )
        pending.settle_timer.daemon = True
        pending.settle_timer.start()

    def _trigger_processing(self, deleted_dir, pending):
        """Cancel timers and schedule directory move processing.

        Must be called with self._lock held.
        """
        if pending.settle_timer is not None:
            pending.settle_timer.cancel()
        if pending.max_timer is not None:
            pending.max_timer.cancel()

        if deleted_dir in self.pending_dir_moves:
            del self.pending_dir_moves[deleted_dir]

        # Process on a separate thread to not block the watchdog event thread
        t = threading.Thread(
            target=self._process_dir_move,
            args=(pending,),
            daemon=True,
        )
        t.start()

    def _process_settled(self, deleted_dir):
        """Called when settle timer fires — process with whatever we have."""
        with self._lock:
            pending = self.pending_dir_moves.get(deleted_dir)
            if pending is None:
                return  # Already processed

            if pending.max_timer is not None:
                pending.max_timer.cancel()

            del self.pending_dir_moves[deleted_dir]

        self._logger.info(
            "dir_move_settle_timer_fired",
            old_dir=deleted_dir,
            new_dir=pending.new_dir,
            matched=pending.matched_count,
            unmatched=len(pending.unmatched),
        )
        self._logger.performance.log_metric(
            "dir_move_completion_trigger", 1, unit="event",
            trigger="settle_timer",
            matched=pending.matched_count,
            total=pending.total_expected,
        )
        self._process_dir_move(pending)

    def _process_timeout(self, deleted_dir):
        """Called when max timer fires — process or treat as true delete."""
        with self._lock:
            pending = self.pending_dir_moves.get(deleted_dir)
            if pending is None:
                return  # Already processed

            if pending.settle_timer is not None:
                pending.settle_timer.cancel()

            del self.pending_dir_moves[deleted_dir]

        if pending.new_dir is not None:
            # At least one match — process as partial directory move
            self._logger.warning(
                "dir_move_max_timeout",
                old_dir=deleted_dir,
                new_dir=pending.new_dir,
                matched=pending.matched_count,
                unmatched=len(pending.unmatched),
            )
            self._logger.performance.log_metric(
                "dir_move_completion_trigger", 1, unit="event",
                trigger="max_timeout",
                matched=pending.matched_count,
                total=pending.total_expected,
            )
            self._process_dir_move(pending)
        else:
            # No matches at all — true directory deletion
            self._logger.info(
                "directory_true_delete",
                deleted_dir=deleted_dir,
                files_count=pending.total_expected,
            )
            self._logger.performance.log_metric(
                "dir_move_completion_trigger", 1, unit="event",
                trigger="max_timeout_no_match",
                files_count=pending.total_expected,
            )
            self._process_dir_true_delete(pending)

    def _process_dir_move(self, pending):
        """Process a detected directory move (Phase 3).

        Resolves any unmatched files, then delegates to the on_dir_move
        callback for actual reference updates.
        """
        old_dir = pending.deleted_dir
        new_dir = pending.new_dir
        total_duration_ms = (time.time() - pending.timestamp) * 1000

        self._logger.info(
            "dir_move_processing",
            old_dir=old_dir,
            new_dir=new_dir,
            matched=pending.matched_count,
            unmatched=len(pending.unmatched),
            total=pending.total_expected,
        )
        self._logger.performance.log_metric(
            "dir_move_total_duration", round(total_duration_ms, 2),
            unit="ms",
            old_dir=old_dir,
            new_dir=new_dir,
            matched=pending.matched_count,
            total=pending.total_expected,
        )

        # Resolve any unmatched files via filesystem verification
        if pending.unmatched:
            self._resolve_unmatched_files(pending)

        self._on_dir_move(old_dir, new_dir)

    def _resolve_unmatched_files(self, pending):
        """Verify unmatched files against the filesystem."""
        self._logger.info(
            "resolving_unmatched_files",
            count=len(pending.unmatched),
            old_dir=pending.deleted_dir,
            new_dir=pending.new_dir,
        )

        for old_file in list(pending.unmatched):
            rel_within_dir = old_file[len(pending.dir_prefix) :]
            new_file_path = os.path.join(str(self._project_root), pending.new_dir, rel_within_dir)
            old_file_path = os.path.join(str(self._project_root), old_file)

            if os.path.exists(new_file_path):
                self._logger.info(
                    "unmatched_file_found_at_new_location",
                    old_path=old_file,
                    new_path=f"{pending.new_dir}/{rel_within_dir}",
                )
            elif os.path.exists(old_file_path):
                self._logger.warning(
                    "unmatched_file_still_at_old_location",
                    old_path=old_file,
                )
            else:
                self._logger.warning(
                    "unmatched_file_truly_deleted",
                    old_path=old_file,
                )
                self._on_true_file_delete(old_file)

    def _process_dir_true_delete(self, pending):
        """Process a directory that was truly deleted (no move detected)."""
        for file_path in pending.known_files:
            self._on_true_file_delete(file_path)
