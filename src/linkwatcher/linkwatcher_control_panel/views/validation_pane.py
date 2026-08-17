"""
Validation tab for the Control Panel (PD-UIX-003 §4.5 / Screen 3, TDD §4.6).

A Run button plus a single-visible-state area (idle / running / result /
failure) driven entirely by the model's :class:`~..model.ValidationRun` through
the display-free :func:`~.rendering.validation_display` rule (COMP-3) — this
module only builds widgets and forwards events.

AI Context
----------
- **One state visible at a time** (COMP-3): the pane renders whatever
  :func:`validation_display` says and nothing else; a result persists until the
  next run or a project switch (``ValidationRun`` lives in the model, keyed by
  project).
- **Run is disabled while this project's run is in flight** (UNIT-V4/BR-6) —
  the model's ``running`` state drives it, so the disable is truthful, not
  optimistic.  The daemon is never touched by a run ("daemon keeps running" is
  part of the running text).
- The indeterminate progress bar is started/stopped exactly on state edges
  (a re-render must not restart the marquee animation).
"""

from __future__ import annotations

import os
import tkinter as tk
from tkinter import ttk
from typing import Callable, Optional

from ..panel_log import get_panel_logger
from . import rendering, tokens

_SELECT_PLACEHOLDER = "Select a project"


class ValidationPane:
    """Builds and owns the Validation tab's widget tree inside a notebook frame."""

    def __init__(
        self,
        parent: ttk.Frame,
        *,
        model=None,
        on_run: Optional[Callable[[str], None]] = None,
        open_path: Optional[Callable[[str], None]] = None,
    ):
        self.model = model
        self._on_run = on_run
        self._open_path = open_path if open_path is not None else os.startfile
        self._log = get_panel_logger()
        self._report_path = None
        self._progress_running = False
        self._build(parent)
        self.render()

    # ------------------------------------------------------------------ #
    # Construction
    # ------------------------------------------------------------------ #
    def _build(self, parent: ttk.Frame) -> None:
        self.frame = parent

        self.header = ttk.Label(parent, font=tokens.FONT_HEADING)
        self.header.pack(side=tk.TOP, anchor=tk.W)

        self.run_button = ttk.Button(
            parent,
            text=f"{tokens.GLYPH_START} Run validation",
            command=self._handle_run,
            state=tk.DISABLED,
        )
        self.run_button.pack(side=tk.TOP, anchor=tk.W, pady=(12, 16))

        state_area = ttk.Frame(parent)
        state_area.pack(side=tk.TOP, fill=tk.X)
        self.progress = ttk.Progressbar(state_area, mode="indeterminate", length=200)
        # Wraplength stays inside the detail pane at the 760 px minimum window
        # (PD-UIX-003 §6.1: min window minus the 240 px minimum list pane).
        self.state_label = ttk.Label(state_area, anchor=tk.W, wraplength=440, justify=tk.LEFT)
        self.state_label.pack(side=tk.TOP, anchor=tk.W)
        self.report_button = ttk.Button(
            state_area, text="Open report", command=self._handle_open_report
        )

    # ------------------------------------------------------------------ #
    # Rendering (one-way, from the model)
    # ------------------------------------------------------------------ #
    def render(self) -> None:
        """Repaint from the model's ValidationRun for the selected project."""
        selected = self.model.selected_project_id if self.model is not None else None
        snapshot = (
            self.model.snapshot_for(selected)
            if self.model is not None and selected is not None
            else None
        )
        shutting_down = self.model.shutting_down if self.model is not None else False

        if snapshot is None:
            self.header.configure(text="Link validation")
            self.state_label.configure(text=_SELECT_PLACEHOLDER, foreground=tokens.MUTED_TEXT)
            self.run_button.configure(state=tk.DISABLED)
            self._set_progress(False)
            self.report_button.pack_forget()
            self._report_path = None
            return

        self.header.configure(text=f"{snapshot.project.name} — link validation")
        display = rendering.validation_display(self.model.validation.get(selected))
        self._report_path = display.report_path

        can_run = display.mode != "running" and self._on_run is not None and not shutting_down
        self.run_button.configure(state=tk.NORMAL if can_run else tk.DISABLED)
        self.state_label.configure(text=display.text, foreground=display.color)
        self._set_progress(display.mode == "running")
        if display.report_path is not None:
            self.report_button.pack(side=tk.TOP, anchor=tk.W, pady=(8, 0))
        else:
            self.report_button.pack_forget()

    def _set_progress(self, running: bool) -> None:
        """Start/stop the marquee only on state edges (no re-render restarts)."""
        if running and not self._progress_running:
            self.progress.pack(side=tk.TOP, anchor=tk.W, pady=(0, 8), before=self.state_label)
            self.progress.start(50)
            self._progress_running = True
        elif not running and self._progress_running:
            self.progress.stop()
            self.progress.pack_forget()
            self._progress_running = False

    # ------------------------------------------------------------------ #
    # Events
    # ------------------------------------------------------------------ #
    def _handle_run(self) -> None:
        if self._on_run is None or self.model is None:
            return
        selected = self.model.selected_project_id
        if selected is not None:
            self._on_run(selected)

    def _handle_open_report(self) -> None:
        if self._report_path is None:
            return
        try:
            self._open_path(str(self._report_path))
        except OSError:
            self._log.exception("open_report_failed path=%s", self._report_path)
