"""
Per-file move detection via delete+create event correlation.

On Windows, file moves may be reported by watchdog as separate
delete and create events rather than a single move event. This
module correlates these event pairs by buffering deletes and
matching them against subsequent creates based on filename and
file size within a configurable time window.
"""

import os
import threading
import time


class MoveDetector:
    """Detects per-file moves by correlating delete+create event pairs.

    When a file is deleted, it is buffered with its size and timestamp.
    If a new file with the same name and size appears within the delay
    window, the pair is treated as a move. Otherwise, after the timer
    expires, the delete is confirmed as a true deletion via callback.

    Args:
        on_move_detected: Callback(old_rel_path, new_rel_path) for confirmed moves.
        on_true_delete: Callback(rel_path) for confirmed true deletions.
        delay: Seconds to wait for a matching create after a delete.
    """

    def __init__(self, on_move_detected, on_true_delete, delay=10.0):
        self._on_move = on_move_detected
        self._on_delete = on_true_delete
        self._pending = {}  # {rel_path: (timestamp, file_size)}
        self._timers = {}  # {rel_path: threading.Timer}
        self._delay = delay
        self._lock = threading.Lock()

    def buffer_delete(self, rel_path, abs_path):
        """Buffer a file deletion for potential move correlation.

        Stores the file's size (if still available) and starts a timer.
        If no matching create arrives before the timer fires, the
        deletion is confirmed via the on_true_delete callback.
        """
        file_size = 0
        try:
            if os.path.exists(abs_path):
                file_size = os.path.getsize(abs_path)
        except Exception:
            pass

        with self._lock:
            self._pending[rel_path] = (time.time(), file_size)

            # Cancel existing timer for this path (re-buffered delete)
            old_timer = self._timers.get(rel_path)
            if old_timer is not None:
                old_timer.cancel()

            timer = threading.Timer(self._delay, self._timer_expired, [rel_path])
            timer.daemon = True
            self._timers[rel_path] = timer
            timer.start()

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

            for deleted_path, (delete_time, delete_size) in list(self._pending.items()):
                if current_time - delete_time > self._delay:
                    continue

                if os.path.basename(deleted_path) == created_filename:
                    if delete_size == 0 or created_size == delete_size:
                        del self._pending[deleted_path]
                        # Cancel the pending timer — no longer needed
                        timer = self._timers.pop(deleted_path, None)
                        if timer is not None:
                            timer.cancel()
                        return deleted_path

        return None

    @property
    def has_pending(self):
        """Whether there are any pending deletions being tracked."""
        return bool(self._pending)

    def _timer_expired(self, rel_path):
        """Timer callback: confirm as true delete if still pending."""
        with self._lock:
            if rel_path not in self._pending:
                return  # Already matched as a move
            del self._pending[rel_path]
            self._timers.pop(rel_path, None)

        self._on_delete(rel_path)
