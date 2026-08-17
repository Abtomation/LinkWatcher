"""
Modal shutdown-progress dialog for the LinkWatcher Control Panel
(PD-UIX-003 Screen 4 / §4.7).

Shown when the window closes with daemons still to drain.  Deliberately not
user-closable — no ✕ handling, no Esc: the bounded grace period plus the app's
watchdog guarantee exit, so the dialog needs no escape hatch (BR-7/AC-9).  No
close-confirmation precedes it (UI Design Decision D3); the dialog itself is
the visible acknowledgment of what closing does.

AI Context
----------
- **Renders from the model only**, like every view: one row per shutdown
  target, repainted on model notifications and on the app's 1 s tick (which
  advances the "Draining… (n s)" elapsed suffix).  All display rules — row
  text/color, the "k of n stopped" counter — are the pure functions in
  :mod:`.rendering` (COMP-5), so this module holds only widget plumbing.
- The application exit is **not** this dialog's job: the
  :class:`~..lifecycle.ShutdownOrchestrator` decides completion and the app
  destroys the whole widget tree.  The dialog never calls ``destroy`` itself.
"""

from __future__ import annotations

import time
import tkinter as tk
from tkinter import ttk
from typing import Callable, Sequence

from ..model import DaemonStatus
from . import rendering

# ~420 px wide per PD-UIX-003 §4.7; height fits the daemon count.
PROGRESS_LENGTH = 240


class ShutdownDialog:
    """Builds and owns the shutdown-progress Toplevel over the main window."""

    def __init__(
        self,
        parent: tk.Misc,
        *,
        model,
        targets: Sequence[str],
        clock: Callable[[], float] = time.monotonic,
    ):
        self.model = model
        self.targets = list(targets)
        self._clock = clock
        self._opened_at = clock()

        self.top = tk.Toplevel(parent)
        self.top.title("Shutting down LinkWatcher")
        self.top.transient(parent)
        self.top.resizable(False, False)
        # Not user-closable: closing is already in progress and exit-bounded.
        self.top.protocol("WM_DELETE_WINDOW", lambda: None)

        frame = ttk.Frame(self.top, padding=16)
        frame.pack(fill=tk.BOTH, expand=True)
        ttk.Label(frame, text="Draining daemons before terminating…").pack(anchor=tk.W)

        rows = ttk.Frame(frame)
        rows.pack(fill=tk.X, pady=12)
        self._row_labels = {}
        for index, project_id in enumerate(self.targets):
            snapshot = model.snapshot_for(project_id)
            name = snapshot.project.name if snapshot is not None else project_id
            ttk.Label(rows, text=name).grid(row=index, column=0, sticky=tk.W, padx=(4, 24))
            state = ttk.Label(rows, text="")
            state.grid(row=index, column=1, sticky=tk.W)
            self._row_labels[project_id] = state

        bottom = ttk.Frame(frame)
        bottom.pack(fill=tk.X)
        self.progress = ttk.Progressbar(
            bottom,
            mode="determinate",
            maximum=max(1, len(self.targets)),
            length=PROGRESS_LENGTH,
        )
        self.progress.pack(side=tk.LEFT)
        self.summary_var = tk.StringVar(value="")
        ttk.Label(bottom, textvariable=self.summary_var).pack(side=tk.LEFT, padx=(8, 0))

        try:
            self.top.grab_set()  # modal: focus held inside the dialog
        except tk.TclError:  # pragma: no cover - unviewable parent (headless harness)
            pass
        self._center_over(parent)
        self.render()

    def _center_over(self, parent: tk.Misc) -> None:
        try:
            self.top.update_idletasks()
            x = parent.winfo_rootx() + (parent.winfo_width() - self.top.winfo_width()) // 2
            y = parent.winfo_rooty() + (parent.winfo_height() - self.top.winfo_height()) // 2
            self.top.geometry(f"+{max(0, x)}+{max(0, y)}")
        except tk.TclError:  # pragma: no cover - depends on window realization
            pass

    def render(self) -> None:
        """Repaint every row + the counter from the model (safe on every change)."""
        elapsed = self._clock() - self._opened_at
        statuses = []
        for project_id, label in self._row_labels.items():
            snapshot = self.model.snapshot_for(project_id)
            # A target that vanished from the registry mid-shutdown is resolved.
            status = DaemonStatus.STOPPED if snapshot is None else snapshot.status
            statuses.append(status)
            display = rendering.shutdown_row_display(status, elapsed)
            label.configure(text=display.text, foreground=display.color)
        summary = rendering.shutdown_summary(statuses)
        self.progress.configure(value=summary.done)
        self.summary_var.set(summary.text)
