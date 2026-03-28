"""
Per-file move detection via delete+create event correlation.

On Windows, file moves may be reported by watchdog as separate
delete and create events rather than a single move event. This
module correlates these event pairs by buffering deletes and
matching them against subsequent creates based on filename and
file size within a configurable time window.

AI Context
----------
- **Entry point**: ``MoveDetector`` -- instantiated by handler.
  ``buffer_delete(rel_path)`` stores a pending delete;
  ``match_created_file(rel_path)`` attempts to pair it with a create.
- **Key mechanism**: deletes are stored in ``self._pending`` (dict keyed
  by rel_path).  A single worker thread sleeps until the earliest
  expiry in a priority queue (heapq); expired, unmatched deletes are
  confirmed via ``on_true_delete`` callback.  Matched pairs fire
  ``on_move_detected(old_path, new_path)``.
- **Threading model**: one daemon worker thread + one lock.  The worker
  sleeps on ``self._wake`` (a ``threading.Event``) and re-checks the
  queue after each wake-up.  ``buffer_delete`` and ``match_created_file``
  signal ``_wake`` when they modify the queue.
- **Common tasks**:
  - Tuning timing: adjust ``delay`` parameter (default 10s).  Too short
    misses slow moves; too long delays true-delete processing.
  - Debugging missed matches: check basename matching logic and file
    size comparison in ``match_created_file()``.
  - Understanding thread safety: ``self._lock`` guards ``_pending``
    and ``_queue``; the worker thread acquires the lock before
    processing expired entries.
"""

import heapq
import os
import threading
import time
from typing import Callable

from .logging import get_logger


class MoveDetector:
    """Detects per-file moves by correlating delete+create event pairs.

    When a file is deleted, it is buffered with its size and timestamp.
    If a new file with the same name and size appears within the delay
    window, the pair is treated as a move. Otherwise, after the delay
    expires, the delete is confirmed as a true deletion via callback.

    Uses a single worker thread with a priority queue instead of
    per-delete timer threads, keeping thread count at O(1) regardless
    of how many deletes are pending.

    Args:
        on_move_detected: Callback(old_rel_path, new_rel_path) for confirmed moves.
        on_true_delete: Callback(rel_path) for confirmed true deletions.
        delay: Seconds to wait for a matching create after a delete.
    """

    def __init__(
        self,
        on_move_detected: Callable[[str, str], None],
        on_true_delete: Callable[[str], None],
        delay: float = 10.0,
    ):
        self._on_move = on_move_detected
        self._on_delete = on_true_delete
        self._pending = {}  # {rel_path: (timestamp, file_size, abs_path)}
        self._queue = []  # min-heap of (expiry_time, rel_path)
        self._delay = delay
        self._lock = threading.Lock()
        self._wake = threading.Event()
        self._stopped = False
        self.logger = get_logger()

        self._worker = threading.Thread(target=self._expiry_worker, daemon=True)
        self._worker.start()

    def buffer_delete(self, rel_path, abs_path):
        """Buffer a file deletion for potential move correlation.

        Stores the file's size (if still available) and adds an expiry
        entry to the priority queue.  If no matching create arrives
        before the expiry, the worker thread confirms the deletion via
        the on_true_delete callback.
        """
        file_size = 0
        try:
            if os.path.exists(abs_path):
                file_size = os.path.getsize(abs_path)
        except Exception:
            pass

        now = time.time()
        with self._lock:
            self._pending[rel_path] = (now, file_size, abs_path)
            heapq.heappush(self._queue, (now + self._delay, rel_path))

            self.logger.debug(
                "move_detect_buffer_delete",
                rel_path=rel_path,
                file_size=file_size,
                delay=self._delay,
            )

        # Wake the worker so it can recalculate its sleep time
        self._wake.set()

    def match_created_file(self, rel_path, abs_path):
        """Try to match a created file with a pending delete.

        Checks if any buffered deletion has the same filename and
        compatible file size. Returns the old path if a match is
        found (indicating a move), or None if no match.
        """
        with self._lock:
            if not self._pending:
                return None

            try:
                created_size = os.path.getsize(abs_path)
            except Exception:
                return None

            created_filename = os.path.basename(rel_path)
            current_time = time.time()

            for deleted_path, (delete_time, delete_size, deleted_abs) in list(
                self._pending.items()
            ):
                if current_time - delete_time > self._delay:
                    continue

                if os.path.basename(deleted_path) == created_filename:
                    if delete_size == 0 or created_size == delete_size:
                        # PD-BUG-042: If the old file has been re-created at
                        # its original location (e.g., by a bulk copy after
                        # cleanup), this pending delete is stale -- discard it
                        # instead of matching it with an unrelated create.
                        if os.path.exists(deleted_abs):
                            del self._pending[deleted_path]
                            self.logger.debug(
                                "move_detect_stale_discard",
                                deleted_path=deleted_path,
                                reason="original file re-created at old location",
                            )
                            continue

                        del self._pending[deleted_path]
                        self.logger.debug(
                            "move_detect_match_found",
                            old_path=deleted_path,
                            new_path=rel_path,
                        )
                        return deleted_path

        return None

    @property
    def has_pending(self):
        """Whether there are any pending deletions being tracked."""
        return bool(self._pending)

    def _expiry_worker(self):
        """Single worker thread that processes expired pending deletes.

        Sleeps until the earliest queued expiry, then confirms any
        expired entries as true deletes.  Uses lazy deletion: queue
        entries for already-matched paths are silently skipped.
        """
        while not self._stopped:
            self._wake.clear()

            # Collect all expired entries under the lock
            expired = []
            wait_time = None

            with self._lock:
                now = time.time()
                while self._queue:
                    earliest_expiry, earliest_path = self._queue[0]
                    if earliest_expiry <= now:
                        heapq.heappop(self._queue)
                        # Lazy deletion: skip if already matched/removed
                        if earliest_path in self._pending:
                            # Verify this queue entry corresponds to the
                            # current pending entry (not a stale re-buffer)
                            pending_time = self._pending[earliest_path][0]
                            if abs((pending_time + self._delay) - earliest_expiry) < 0.001:
                                del self._pending[earliest_path]
                                expired.append(earliest_path)
                    else:
                        wait_time = earliest_expiry - now
                        break

            # Fire callbacks outside the lock to avoid deadlocks
            for rel_path in expired:
                self.logger.debug(
                    "move_detect_timer_expired",
                    rel_path=rel_path,
                    action="confirmed_true_delete",
                )
                self._on_delete(rel_path)

            # Sleep until next expiry or until woken by new buffer_delete
            if wait_time is not None:
                self._wake.wait(timeout=wait_time)
            else:
                self._wake.wait(timeout=1.0)
