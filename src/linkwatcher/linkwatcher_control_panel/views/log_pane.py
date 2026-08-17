"""
Log tab for the Control Panel (PD-UIX-003 §4.3, TDD §4.5).

A read-only monospace tail of the selected project's newest log file, following
appends live.  All tail mechanics (incremental reads, rotation reattach, the
bounded buffer) live in the display-free :class:`~..log_tail.LogTail`; the
auto-scroll pause/resume rules live in :class:`~.rendering.ScrollLock` — this
module only builds widgets and forwards events.

AI Context
----------
- **One tail, selected project only** (TDD §3.1): rebinding on selection change
  replaces the single :class:`LogTail`; unselected projects are never polled.
- **The 500 ms tick reads appended bytes on the UI thread** — a deliberate TDD
  §4.5 design (reads are incremental and capped per tick, so one tick is a few
  KB of file I/O at most).
- **Scroll-lock**: scrolling away from the end pauses following and unticks the
  Auto-scroll checkbox; re-ticking or Ctrl+End jumps to the newest lines and
  resumes.  A programmatic re-render must not read as a user scroll — hence
  the ``_painting`` guard around full renders.
- Historical content stays visible for a stopped daemon (the header notes it);
  a project with no log yet gets a calm placeholder, never an error (EC-5).
"""

from __future__ import annotations

import os
import tkinter as tk
from tkinter import ttk
from typing import Callable, Optional

from ..log_tail import MAX_BUFFER_LINES, LogTail
from ..model import DaemonStatus
from ..panel_log import get_panel_logger
from . import rendering, tokens

# Tail cadence (TDD §4.5: a 500 ms UI-timer tick reads only appended bytes).
TAIL_TICK_MS = 500

_SELECT_PLACEHOLDER = "Select a project"
_NO_LOG_PLACEHOLDER = "No log file for this project yet."

# Statuses whose daemon is alive enough that the header needs no note.
_LIVE_STATUSES = frozenset({DaemonStatus.RUNNING, DaemonStatus.DRAINING, DaemonStatus.STARTING})


class LogPane:
    """Builds and owns the Log tab's widget tree inside a notebook frame."""

    def __init__(
        self,
        parent: ttk.Frame,
        *,
        model=None,
        open_path: Optional[Callable[[str], None]] = None,
        make_tail: Callable[..., LogTail] = LogTail,
    ):
        self.model = model
        self._open_path = open_path if open_path is not None else os.startfile
        self._make_tail = make_tail
        self._log = get_panel_logger()
        self._project_id: Optional[str] = None
        self._tail: Optional[LogTail] = None
        self._scroll = rendering.ScrollLock()
        self._painting = False
        self._build(parent)
        self._rebind()
        parent.after(TAIL_TICK_MS, self._tick)

    # ------------------------------------------------------------------ #
    # Construction
    # ------------------------------------------------------------------ #
    def _build(self, parent: ttk.Frame) -> None:
        self.frame = parent

        self.header = ttk.Label(parent, font=tokens.FONT_HEADING)
        self.header.pack(side=tk.TOP, anchor=tk.W)

        footer = ttk.Frame(parent)
        footer.pack(side=tk.BOTTOM, fill=tk.X, pady=(8, 0))
        self.follow_var = tk.BooleanVar(value=True)
        self.follow_check = ttk.Checkbutton(
            footer,
            text="Auto-scroll",
            variable=self.follow_var,
            command=self._handle_follow_toggle,
        )
        self.follow_check.pack(side=tk.LEFT)
        self.open_button = ttk.Button(
            footer, text="Open log file", command=self._handle_open, state=tk.DISABLED
        )
        self.open_button.pack(side=tk.RIGHT)

        self.placeholder = ttk.Label(
            parent, anchor=tk.CENTER, foreground=tokens.MUTED_TEXT, text=_SELECT_PLACEHOLDER
        )

        self.body = ttk.Frame(parent)
        self.text = tk.Text(self.body, wrap="none", state=tk.DISABLED, font=tokens.FONT_MONO)
        yscroll = ttk.Scrollbar(self.body, orient=tk.VERTICAL, command=self.text.yview)
        xscroll = ttk.Scrollbar(self.body, orient=tk.HORIZONTAL, command=self.text.xview)
        self._yscrollbar = yscroll
        self.text.configure(yscrollcommand=self._handle_yscroll, xscrollcommand=xscroll.set)
        xscroll.pack(side=tk.BOTTOM, fill=tk.X)
        yscroll.pack(side=tk.RIGHT, fill=tk.Y)
        self.text.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        self.text.bind("<Control-End>", self._handle_jump_to_end)

    # ------------------------------------------------------------------ #
    # Rendering (one-way, from the model)
    # ------------------------------------------------------------------ #
    def render(self) -> None:
        """Model subscriber: rebind on selection change, else refresh the header."""
        selected = self.model.selected_project_id if self.model is not None else None
        if selected != self._project_id:
            self._project_id = selected
            self._rebind()
        else:
            self._render_header()

    def _rebind(self) -> None:
        """Point the (single) tail at the newly selected project."""
        snapshot = (
            self.model.snapshot_for(self._project_id)
            if self.model is not None and self._project_id is not None
            else None
        )
        if snapshot is None:
            self._tail = None
        else:
            self._tail = self._make_tail(snapshot.project.log_dir)
            self._tail.attach()
        self._scroll = rendering.ScrollLock()
        self.follow_var.set(True)
        self._render_full()

    def _render_full(self) -> None:
        """Rebuild the whole pane (rebind or rotation reattach)."""
        self._render_header()
        if self._tail is None or not self._tail.has_log:
            self.body.pack_forget()
            self.placeholder.configure(
                text=_SELECT_PLACEHOLDER if self._tail is None else _NO_LOG_PLACEHOLDER
            )
            self.placeholder.pack(expand=True, fill=tk.BOTH)
            self.open_button.configure(state=tk.DISABLED)
            return
        self.placeholder.pack_forget()
        self.body.pack(side=tk.TOP, fill=tk.BOTH, expand=True)
        self.open_button.configure(state=tk.NORMAL)
        self._painting = True
        try:
            self.text.configure(state=tk.NORMAL)
            self.text.delete("1.0", tk.END)
            self.text.insert(tk.END, self._tail.text())
            self.text.configure(state=tk.DISABLED)
            if self._scroll.following:
                self.text.see(tk.END)
        finally:
            self._painting = False

    def _render_header(self) -> None:
        if self.model is None or self._project_id is None:
            self.header.configure(text="Log")
            return
        snapshot = self.model.snapshot_for(self._project_id)
        if snapshot is None:
            self.header.configure(text="Log")
            return
        log_name = (
            self._tail.path.name if self._tail is not None and self._tail.path else "no log file"
        )
        note = "" if snapshot.status in _LIVE_STATUSES else " (daemon not running)"
        self.header.configure(text=f"{snapshot.project.name} — {log_name}{note}")

    # ------------------------------------------------------------------ #
    # Tail tick (TDD §4.5)
    # ------------------------------------------------------------------ #
    def _tick(self) -> None:
        try:
            if self._tail is not None:
                update = self._tail.poll()
                if update.reattached:
                    self._render_full()
                elif update.appended:
                    self._append(update.appended)
        except Exception:  # noqa: BLE001 - a tick failure must not kill the timer
            self._log.exception("log_tail_tick_failed project=%s", self._project_id)
        self.frame.after(TAIL_TICK_MS, self._tick)

    def _append(self, appended: str) -> None:
        """Incremental append + top-trim — never a full re-render (TDD §4.5)."""
        self._painting = True
        try:
            self.text.configure(state=tk.NORMAL)
            self.text.insert(tk.END, appended)
            line_count = int(self.text.index("end-1c").split(".")[0])
            if line_count > MAX_BUFFER_LINES:
                self.text.delete("1.0", f"{line_count - MAX_BUFFER_LINES + 1}.0")
            self.text.configure(state=tk.DISABLED)
            if self._scroll.following:
                self.text.see(tk.END)
        finally:
            self._painting = False

    # ------------------------------------------------------------------ #
    # Events
    # ------------------------------------------------------------------ #
    def _handle_yscroll(self, lo: str, hi: str) -> None:
        """View moved: sync the scrollbar and detect a scroll away from the end."""
        self._yscrollbar.set(lo, hi)
        if self._painting:
            return
        was_following = self._scroll.following
        self._scroll.scrolled(at_end=float(hi) >= 1.0)
        if was_following and not self._scroll.following:
            self.follow_var.set(False)

    def _handle_follow_toggle(self) -> None:
        enabled = bool(self.follow_var.get())
        self._scroll.set_following(enabled)
        if enabled:
            self.text.see(tk.END)

    def _handle_jump_to_end(self, _event=None) -> str:
        """Ctrl+End: jump to the newest lines and resume following (PD-UIX-003 §4.3)."""
        self._scroll.jump_to_end()
        self.follow_var.set(True)
        self.text.see(tk.END)
        return "break"

    def _handle_open(self) -> None:
        if self._tail is None or self._tail.path is None:
            return
        try:
            self._open_path(str(self._tail.path))
        except OSError:
            self._log.exception("open_log_failed path=%s", self._tail.path)
