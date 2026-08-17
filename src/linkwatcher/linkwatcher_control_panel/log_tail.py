"""
Incremental, rotation-aware log tail for the Control Panel's Log pane (TDD §4.5).

One :class:`LogTail` instance follows the *newest* ``LinkWatcherLog*.txt`` in a
single project's log directory — the panel creates one for the selected project
only, so unselected projects' logs are never polled (TDD §3.1).

AI Context
----------
- **Incremental by contract**: after the initial window, every poll reads only the
  bytes appended since the previous poll (byte offset tracked) — the file is
  never re-read per tick (UNIT-T2), and a per-poll read cap bounds the worst
  case of a debug-level log burst.
- **Rotation is detected, never assumed**: the current file vanishing or
  shrinking, or a newer ``LinkWatcherLog*.txt`` appearing, triggers a clean
  reattach to the newest log (UNIT-T3 / EC-5).  "Newest" reuses
  :func:`~.lifecycle.newest_log_stat` — the same mtime-based resolution the
  drain heuristic trusts, not the filename.
- **Bounded everywhere**: the initial attach seeks to ``max(0, size − 64 KB)``
  (instant open on arbitrarily large logs) and the display buffer holds at most
  1,000 lines, trimmed from the top (UNIT-T1/T4).
- **No log is a calm state**: a project with no log file yet reports
  ``has_log = False`` and never raises (UNIT-T5); the pane renders a
  placeholder, and a later poll attaches automatically once a log appears.
- Bytes are decoded with an incremental UTF-8 decoder so a multi-byte character
  split across two polls never renders as mojibake, and Windows ``\\r\\n`` line
  endings (what the daemon's text-mode logging writes) are normalized to
  ``\\n`` — including a ``\\r\\n`` pair split across two reads, via a held-back
  trailing ``\\r``.
"""

from __future__ import annotations

import codecs
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, List, Optional

from .lifecycle import LogStat, newest_log_stat

# Initial attach window: only the last 64 KB of a large log are loaded (TDD §4.5).
INITIAL_WINDOW_BYTES = 64 * 1024

# Per-poll read cap — bounds one UI-thread tick against a log burst
# (checkpoint-approved guard, 2026-08-10); the remainder arrives next tick.
READ_LIMIT_BYTES = 64 * 1024

# Display buffer cap, trimmed from the top (TDD §4.5).
MAX_BUFFER_LINES = 1000


@dataclass(frozen=True)
class TailUpdate:
    """Outcome of one :meth:`LogTail.attach` / :meth:`LogTail.poll` pass.

    ``reattached`` means the buffer was rebuilt (initial attach or rotation) —
    the view must re-render in full; otherwise ``appended`` carries exactly the
    new text (possibly empty) to add to an incremental display.
    """

    has_log: bool
    reattached: bool
    appended: str
    path: Optional[Path]


class LogTail:
    """Follows the newest log in one project's log directory, incrementally.

    ``log_stat`` is the injectable "what is the newest log?" seam (defaults to
    the real :func:`~.lifecycle.newest_log_stat`); everything else is genuine
    file I/O, exercised against real temp files in tests.
    """

    def __init__(
        self,
        log_dir,
        *,
        log_stat: Callable[[Path], Optional[LogStat]] = newest_log_stat,
        max_lines: int = MAX_BUFFER_LINES,
        initial_window: int = INITIAL_WINDOW_BYTES,
        read_limit: int = READ_LIMIT_BYTES,
    ):
        self._log_dir = Path(log_dir)
        self._log_stat = log_stat
        self._max_lines = max_lines
        self._initial_window = initial_window
        self._read_limit = read_limit
        self._path: Optional[Path] = None
        self._offset = 0
        self._lines: List[str] = []
        self._partial = ""
        self._pending_cr = False
        self._decoder = codecs.getincrementaldecoder("utf-8")("replace")

    # ------------------------------------------------------------------ #
    # State
    # ------------------------------------------------------------------ #
    @property
    def path(self) -> Optional[Path]:
        """The log file currently followed (``None`` when there is none)."""
        return self._path

    @property
    def has_log(self) -> bool:
        return self._path is not None

    def lines(self) -> List[str]:
        """The bounded display buffer, including any trailing partial line."""
        if self._partial:
            return (self._lines + [self._partial])[-self._max_lines :]
        return list(self._lines)

    def text(self) -> str:
        """The buffer as one string — what a full re-render shows."""
        return "\n".join(self.lines())

    # ------------------------------------------------------------------ #
    # Attach / poll
    # ------------------------------------------------------------------ #
    def attach(self) -> TailUpdate:
        """(Re)bind to the newest log and load its tail window (UNIT-T1)."""
        self._path = None
        self._offset = 0
        self._lines = []
        self._partial = ""
        self._pending_cr = False
        self._decoder = codecs.getincrementaldecoder("utf-8")("replace")

        stat = self._log_stat(self._log_dir)
        if stat is None:
            return TailUpdate(False, True, "", None)

        start = max(0, stat.size - self._initial_window)
        try:
            with open(stat.path, "rb") as handle:
                handle.seek(start)
                data = handle.read()
        except OSError:
            return TailUpdate(False, True, "", None)

        self._path = stat.path
        self._offset = start + len(data)
        text = self._normalize(self._decoder.decode(data))
        if start > 0:
            # A mid-file window almost certainly opens on a partial line — drop
            # it so the display starts on a line boundary.
            cut = text.find("\n")
            text = text[cut + 1 :] if cut >= 0 else ""
        self._ingest(text)
        return TailUpdate(True, True, "", self._path)

    def poll(self) -> TailUpdate:
        """Read appended bytes; detect rotation/truncation and reattach (UNIT-T2/T3)."""
        if self._path is None:
            # No log last time — attach as soon as one appears (UNIT-T5).
            if self._log_stat(self._log_dir) is None:
                return TailUpdate(False, False, "", None)
            return self.attach()

        try:
            size = self._path.stat().st_size
        except OSError:
            return self.attach()  # current file gone → rotation (EC-5)
        if size < self._offset:
            return self.attach()  # shrank → truncated/replaced (EC-5)
        if size == self._offset:
            # Nothing appended here — but a rotation may have started a newer
            # file while this one merely went quiet.
            newest = self._log_stat(self._log_dir)
            if newest is not None and newest.path != self._path:
                return self.attach()
            return TailUpdate(True, False, "", self._path)

        try:
            with open(self._path, "rb") as handle:
                handle.seek(self._offset)
                data = handle.read(self._read_limit)
        except OSError:
            return self.attach()
        self._offset += len(data)
        text = self._normalize(self._decoder.decode(data))
        self._ingest(text)
        return TailUpdate(True, False, text, self._path)

    # ------------------------------------------------------------------ #
    # Internals
    # ------------------------------------------------------------------ #
    def _normalize(self, text: str) -> str:
        """Normalize line endings to ``\\n``, safely across read boundaries.

        A trailing ``\\r`` is held back (it may be the first half of a
        ``\\r\\n`` pair whose ``\\n`` arrives with the next read) and re-joined
        then — so neither the line buffer nor the appended view text ever
        carries a stray carriage return.
        """
        if self._pending_cr:
            text = "\r" + text
            self._pending_cr = False
        if text.endswith("\r"):
            self._pending_cr = True
            text = text[:-1]
        return text.replace("\r\n", "\n").replace("\r", "\n")

    def _ingest(self, text: str) -> None:
        """Fold *text* into the line buffer, keeping at most ``max_lines`` (UNIT-T4)."""
        if not text:
            return
        parts = (self._partial + text).split("\n")
        self._partial = parts.pop()
        self._lines.extend(parts)
        if len(self._lines) > self._max_lines:
            del self._lines[: len(self._lines) - self._max_lines]
