"""
Main window shell for the LinkWatcher Control Panel (Screen 1, PD-UIX-003 §2.2).

Master–detail single window: a toolbar (Start / Stop / Refresh), a resizable
horizontal splitter with the daemon list on the left and a Log / Configuration /
Validation notebook on the right, and a status bar.  All widget construction
lives in the ``views/`` layer so the toolkit stays swappable (the recorded
PySide6 fallback rewrites only this layer).

Phase B made the daemon list live; Phase C wired the toolbar actions; Phase E
fills the notebook with the real detail panes (Log / Configuration /
Validation).  :meth:`MainWindow.render` is subscribed to the
:class:`~..model.AppModel` and repaints from it — one-way, never from an action
(PD-UIX-003 §10.2).  Rows are keyed by ``project_id`` and updated **in place**,
so a poll cycle produces no flicker and never steals the selection.  Start/Stop
enablement derives from the selected row's *effective* status via
:func:`.rendering.action_enablement` (COMP-1 matrix) — a click only dispatches
the action callback; the row's state change arrives back through the model.

Navigation away from a dirty config editor — a row switch or a tab switch — is
intercepted by the config pane's unsaved-changes guard (COMP-6): the switch
proceeds only when the guard resolves to proceed, otherwise the selection/tab
is snapped back.  Keyboard accelerators (PD-UIX-003 §2.2/§4.2): Alt+S / Alt+T /
F5 drive the toolbar actions (each gated on that button's enablement, so the
COMP-1 matrix governs the keyboard too), Ctrl+1/2/3 select the detail tabs,
Ctrl+S saves the config, double-clicking a row focuses the Log tab.

All rendering *rules* (status glyph+label, uptime formatting, the summary line)
live in :mod:`.rendering` as pure functions, so they are testable without a
display.
"""

from __future__ import annotations

import time
import tkinter as tk
from tkinter import ttk
from typing import Callable, Optional

from ..model import DaemonStatus
from ..panel_log import get_panel_logger
from . import rendering, tokens
from .config_pane import ConfigPane
from .log_pane import LogPane
from .validation_pane import ValidationPane

# Window geometry (PD-UIX-003 §3.3).
DEFAULT_GEOMETRY = "960x600"
MIN_WIDTH = 760
MIN_HEIGHT = 480
LIST_PANE_WIDTH = 320

DETAIL_TABS = ("Log", "Configuration", "Validation")


class MainWindow:
    """Builds and owns the Screen 1 widget tree under a given Tk root.

    *model* is the single source of rendered state; *on_select* is notified with
    the newly selected ``project_id`` (or ``None``); *on_refresh* is invoked by
    the Refresh button; *on_start*/*on_stop* receive the selected ``project_id``
    when the corresponding toolbar action fires.  With no model (or an
    unresolved registry) the list pane shows the corresponding message state
    instead of the tree.
    """

    def __init__(
        self,
        root: tk.Misc,
        *,
        model=None,
        registry_error: Optional[str] = None,
        on_select: Optional[Callable[[Optional[str]], None]] = None,
        on_refresh: Optional[Callable[[], None]] = None,
        on_start: Optional[Callable[[str], None]] = None,
        on_stop: Optional[Callable[[str], None]] = None,
        on_validate: Optional[Callable[[str], None]] = None,
    ):
        self.root = root
        self.model = model
        self._registry_error = registry_error
        self._on_select = on_select
        self._on_refresh = on_refresh
        self._on_start = on_start
        self._on_stop = on_stop
        self._on_validate = on_validate
        self._suppress_select_event = False
        self._suppress_tab_event = False
        self._current_tab_index = 0
        self._build()
        self.render()

    # ------------------------------------------------------------------ #
    # Construction
    # ------------------------------------------------------------------ #
    def _build(self) -> None:
        self.root.title("LinkWatcher Control Panel")
        self.root.geometry(DEFAULT_GEOMETRY)
        self.root.minsize(MIN_WIDTH, MIN_HEIGHT)

        self._build_toolbar()
        self._build_status_bar()  # packed to the bottom before the paned area fills
        self._build_master_detail()

    def _build_toolbar(self) -> None:
        toolbar = ttk.Frame(self.root, padding=(12, 8))
        toolbar.pack(side=tk.TOP, fill=tk.X)

        # Initial state is disabled; render() applies the COMP-1 enablement
        # matrix from the model on every repaint.
        self.start_button = ttk.Button(
            toolbar,
            text=f"{tokens.GLYPH_START} Start",
            command=self._handle_start,
            state=tk.DISABLED,
        )
        self.stop_button = ttk.Button(
            toolbar,
            text=f"{tokens.GLYPH_STOP} Stop",
            command=self._handle_stop,
            state=tk.DISABLED,
        )
        self.refresh_button = ttk.Button(
            toolbar,
            text=f"{tokens.GLYPH_REFRESH} Refresh",
            command=self._handle_refresh,
            state=tk.NORMAL if self._on_refresh else tk.DISABLED,
        )
        for index, button in enumerate((self.start_button, self.stop_button, self.refresh_button)):
            button.pack(side=tk.LEFT, padx=(0 if index == 0 else 8, 0))

        # Toolbar accelerators (PD-UIX-003 §4.2, and §5.1 "all functionality
        # keyboard-operable").  Each fires through the button's own enablement,
        # so the COMP-1 matrix governs the keyboard exactly as it governs the
        # mouse — a disabled action can never be triggered by a keystroke.
        for sequence, button, handler in (
            ("<Alt-s>", self.start_button, self._handle_start),
            ("<Alt-t>", self.stop_button, self._handle_stop),
            ("<F5>", self.refresh_button, self._handle_refresh),
        ):
            self.root.bind(sequence, self._make_action_accel(button, handler))

    def _build_status_bar(self) -> None:
        self.status_var = tk.StringVar(value="")
        status = ttk.Label(self.root, textvariable=self.status_var, anchor=tk.W, padding=(12, 4))
        status.pack(side=tk.BOTTOM, fill=tk.X)

    def _build_master_detail(self) -> None:
        paned = ttk.PanedWindow(self.root, orient=tk.HORIZONTAL)
        paned.pack(side=tk.TOP, fill=tk.BOTH, expand=True)

        # Left — list pane: the tree and a message label, one visible at a time.
        self.list_pane = ttk.Frame(paned, padding=12, width=LIST_PANE_WIDTH)
        paned.add(self.list_pane, weight=0)

        self.list_message = ttk.Label(
            self.list_pane, anchor=tk.CENTER, justify=tk.CENTER, wraplength=LIST_PANE_WIDTH - 32
        )
        self.tree = ttk.Treeview(
            self.list_pane, columns=("status", "uptime"), show="tree headings", selectmode="browse"
        )
        self.tree.heading("#0", text="Project")
        self.tree.heading("status", text="Status")
        self.tree.heading("uptime", text="Uptime")
        self.tree.column("#0", width=130, stretch=True)
        self.tree.column("status", width=130, stretch=False)
        self.tree.column("uptime", width=70, anchor=tk.E, stretch=False)
        for status in DaemonStatus:
            self.tree.tag_configure(status.value, foreground=rendering.status_display(status).color)
        self.tree.bind("<<TreeviewSelect>>", self._handle_select)
        # Keyboard entry point: with no row selected, item focus is "" and every
        # arrow keypress is a no-op, so a keyboard-only operator can never reach
        # a first row (CR-6). Focusing the list adopts the first row.
        self.tree.bind("<FocusIn>", self._handle_tree_focus_in)

        # Right — detail notebook: the Phase E panes (Log / Configuration /
        # Validation), each owning its tab frame and rendering from the model.
        self.notebook = ttk.Notebook(paned)
        log_frame = ttk.Frame(self.notebook, padding=12)
        config_frame = ttk.Frame(self.notebook, padding=12)
        validation_frame = ttk.Frame(self.notebook, padding=12)
        for frame, name in zip((log_frame, config_frame, validation_frame), DETAIL_TABS):
            self.notebook.add(frame, text=name)
        self.log_pane = LogPane(log_frame, model=self.model)
        self.config_pane = ConfigPane(config_frame, model=self.model)
        self.validation_pane = ValidationPane(
            validation_frame, model=self.model, on_run=self._on_validate
        )
        self.notebook.bind("<<NotebookTabChanged>>", self._handle_tab_changed)
        paned.add(self.notebook, weight=1)

        # Keyboard accelerators (PD-UIX-003 §2.2): tab selection + config save.
        for index in range(len(DETAIL_TABS)):
            self.root.bind(f"<Control-Key-{index + 1}>", self._make_tab_accel(index))
        self.root.bind("<Control-s>", self._handle_save_accel)
        self.tree.bind("<Double-1>", self._handle_row_double_click)

        # Place the splitter at the default list-pane width.
        self.root.update_idletasks()
        try:
            paned.sashpos(0, LIST_PANE_WIDTH)
        except tk.TclError:  # pragma: no cover - depends on window realization timing
            pass

    # ------------------------------------------------------------------ #
    # Rendering (one-way, from the model)
    # ------------------------------------------------------------------ #
    def render(self) -> None:
        """Repaint list + status bar from the model. Safe to call on every change."""
        rows = self.model.rows() if self.model is not None else []
        error = self._registry_error or (
            self.model.discovery_error if self.model is not None else None
        )

        # No poll has been applied yet → discovery is still running, so the list
        # must not claim there are no projects (the first psutil pass can take
        # seconds on a busy machine).
        pending = self.model is not None and self.model.last_refresh is None
        display = rendering.list_pane_display(rows, error, discovery_pending=pending)
        if display.mode == "tree":
            self._show_tree(rows)
        else:
            self._show_message(display)
        self._render_status(rows, error, display)
        self._render_toolbar()
        self.log_pane.render()
        self.config_pane.render()
        self.validation_pane.render()

    def _show_message(self, display: rendering.ListPaneDisplay) -> None:
        """Show the calm empty state, or the error banner when one is set (COMP-8)."""
        self.tree.pack_forget()
        self.list_message.configure(text=display.text, foreground=display.color)
        self.list_message.pack(expand=True, fill=tk.BOTH)

    def _show_tree(self, rows) -> None:
        """Update rows in place — no rebuild, so there is no flicker (TDD §4.2)."""
        self.list_message.pack_forget()
        self.tree.pack(expand=True, fill=tk.BOTH)

        now = time.time()
        wanted = []
        for row in rows:
            project_id = row.project.project_id
            wanted.append(project_id)
            values = (
                rendering.status_text(row.status),
                rendering.format_uptime(row.started_at, now),
            )
            if self.tree.exists(project_id):
                self.tree.item(
                    project_id, text=row.project.name, values=values, tags=(row.status.value,)
                )
            else:
                self.tree.insert(
                    "",
                    tk.END,
                    iid=project_id,
                    text=row.project.name,
                    values=values,
                    tags=(row.status.value,),
                )

        for existing in self.tree.get_children(""):
            if existing not in wanted:
                self.tree.delete(existing)

        self._sync_selection()

    def _sync_selection(self) -> None:
        """Mirror the model's selection into the tree without re-firing the event."""
        selected = self.model.selected_project_id if self.model is not None else None
        current = self.tree.selection()
        if selected is not None and self.tree.exists(selected):
            if current != (selected,):
                self._suppress_select_event = True
                try:
                    self.tree.selection_set(selected)
                    # Tk's Treeview key navigation moves the *focus item*, not
                    # the selection. Selecting without focusing leaves item focus
                    # at "", where every arrow keypress is a no-op and no row can
                    # be reached without a mouse (CR-6).
                    self.tree.focus(selected)
                finally:
                    self._suppress_select_event = False
        elif current:
            self._suppress_select_event = True
            try:
                self.tree.selection_remove(*current)
            finally:
                self._suppress_select_event = False

    def _render_status(
        self, rows, error: Optional[str], display: Optional[rendering.ListPaneDisplay] = None
    ) -> None:
        """Status bar: the selected row's detail if it has one, else a summary."""
        if error and not rows:
            # Report the error we actually have. A fixed "registry not found"
            # string contradicted the banner beside it, which shows the real
            # reason — the registry can equally be unreadable, invalid JSON, or
            # missing its `projects` mapping, and discovery itself can fail
            # outright (CR-16). The panel log now carries these too, so the
            # pointer to it is honest.
            self.status_var.set(f"{error} — see panel log")
            return
        if display is not None and display.mode == "loading":
            # "0 daemons running" would be the same false claim as the empty state.
            self.status_var.set(display.text)
            return

        selected = self.model.selected_project_id if self.model is not None else None
        if selected is not None and self.model is not None:
            snapshot = self.model.snapshot_for(selected)
            if snapshot is not None and snapshot.detail:
                self.status_var.set(snapshot.detail)
                return
        summary = rendering.summarize(rows)
        self.status_var.set(f"{summary} — {error}" if error else summary)

    def _render_toolbar(self) -> None:
        """Apply the COMP-1 enablement matrix to Start/Stop from the model."""
        snapshot = None
        shutting_down = False
        if self.model is not None:
            shutting_down = self.model.shutting_down
            selected = self.model.selected_project_id
            if selected is not None:
                snapshot = self.model.snapshot_for(selected)
        enablement = rendering.action_enablement(snapshot, shutting_down)
        can_start = enablement.start and self._on_start is not None
        can_stop = enablement.stop and self._on_stop is not None
        self.start_button.configure(state=tk.NORMAL if can_start else tk.DISABLED)
        self.stop_button.configure(state=tk.NORMAL if can_stop else tk.DISABLED)

    # ------------------------------------------------------------------ #
    # Events
    # ------------------------------------------------------------------ #
    def _handle_tree_focus_in(self, _event=None) -> None:
        """Adopt the first row when the list gains focus with nothing focused.

        Deliberately does nothing when an item already has focus (so returning to
        the list keeps the operator's place) and when the list is empty. Lets the
        selection event fire normally, so the model — and every pane bound to it
        — follows the keyboard exactly as it follows the mouse.
        """
        try:
            if self.tree.focus():
                return
            children = self.tree.get_children()
            if not children:
                return
            first = children[0]
            self.tree.focus(first)
            self.tree.selection_set(first)
        except Exception:  # noqa: BLE001 - a focus assist must never break the UI thread
            get_panel_logger().exception("tree_focus_in_failed")

    def _handle_select(self, _event=None) -> None:
        if self._suppress_select_event or self._on_select is None:
            return
        selection = self.tree.selection()
        target = selection[0] if selection else None
        current = self.model.selected_project_id if self.model is not None else None
        if target == current:
            return
        if not self.config_pane.guard_navigation():
            # Unsaved changes, navigation cancelled — snap the tree back to the
            # model's selection (COMP-6: never a silent discard).
            self._sync_selection()
            return
        self._on_select(target)

    def _handle_tab_changed(self, _event=None) -> None:
        if self._suppress_tab_event:
            return
        try:
            new_index = self.notebook.index(self.notebook.select())
        except tk.TclError:  # pragma: no cover - notebook being torn down
            return
        if new_index == self._current_tab_index:
            return
        leaving_config = self._current_tab_index == DETAIL_TABS.index("Configuration")
        if leaving_config and not self.config_pane.guard_navigation():
            self._suppress_tab_event = True
            try:
                self.notebook.select(self._current_tab_index)
            finally:
                self._suppress_tab_event = False
            return
        self._current_tab_index = new_index

    def _make_action_accel(self, button, handler):
        """A toolbar accelerator gated on the button's current enabled state."""

        def _fire(_event=None) -> str:
            if str(button.cget("state")) == tk.NORMAL:
                handler()
            return "break"

        return _fire

    def _make_tab_accel(self, index: int):
        def _select_tab(_event=None) -> str:
            # Goes through notebook.select so the unsaved-changes guard in
            # _handle_tab_changed applies to keyboard navigation too.
            self.notebook.select(index)
            return "break"

        return _select_tab

    def _handle_save_accel(self, _event=None) -> None:
        self.config_pane.save()

    def _handle_row_double_click(self, _event=None) -> str:
        """Double-click a row → focus the Log tab (PD-UIX-003 §4.1)."""
        self.notebook.select(DETAIL_TABS.index("Log"))
        return "break"

    def _handle_refresh(self) -> None:
        if self._on_refresh is not None:
            self._on_refresh()

    def _handle_start(self) -> None:
        if self._on_start is None or self.model is None:
            return
        selected = self.model.selected_project_id
        if selected is not None:
            self._on_start(selected)

    def _handle_stop(self) -> None:
        if self._on_stop is None or self.model is None:
            return
        selected = self.model.selected_project_id
        if selected is not None:
            self._on_stop(selected)
