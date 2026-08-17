"""
Configuration tab for the Control Panel (PD-UIX-003 §4.4 / Screen 2, TDD §4.6).

A raw-YAML editor (UI Design Decision D5) with validate-on-save, a
single-message notice line, and an unsaved-changes guard.  The save pipeline
and read/skeleton logic live in the display-free :mod:`~..config_edit`; the
notice-line and guard *rules* live in :mod:`~.rendering` (COMP-4/COMP-6) —
this module only builds widgets and forwards events.

AI Context
----------
- **The notice line carries exactly one message** (COMP-4): clean (empty) /
  dirty ⓘ / blocked-save error / saved (with the restart-needed variant when
  the daemon is running, BR-9).  The pane keeps one notice state and renders it
  through :func:`~.rendering.config_notice`.
- **Work is never silently discarded** (COMP-6): row/tab navigation with a
  dirty editor runs :meth:`guard_navigation` — Save / Discard / Cancel — and
  the caller only proceeds when the resolved outcome says so.
- **The missing-config state never auto-writes** (EC-10): a banner with the
  path plus an explicit "Create default config" button; an unreadable file gets
  the banner only.
- Editing is available whether or not the daemon runs; ``daemon_running`` is
  sampled at save time to pick the plain-saved vs. restart-needed notice.
"""

from __future__ import annotations

import tkinter as tk
from tkinter import messagebox, ttk
from typing import Callable, Optional

from .. import config_edit
from ..model import DaemonStatus
from . import rendering, tokens

_SELECT_PLACEHOLDER = "Select a project"

# The per-project config location, shown relative in the pane header.
_CONFIG_RELPATH = "tools/linkwatcher/linkwatcher-config.yaml"


class ConfigPane:
    """Builds and owns the Configuration tab's widget tree inside a notebook frame."""

    def __init__(
        self,
        parent: ttk.Frame,
        *,
        model=None,
        read: Callable = config_edit.read_config,
        save: Callable = config_edit.save_config,
        create_default: Callable = config_edit.create_default_config,
        ask_unsaved: Optional[Callable[[str], Optional[bool]]] = None,
        confirm_discard: Optional[Callable[[], bool]] = None,
    ):
        self.model = model
        self._read = read
        self._save = save
        self._create_default = create_default
        self._ask_unsaved = ask_unsaved if ask_unsaved is not None else self._ask_unsaved_dialog
        self._confirm_discard = (
            confirm_discard if confirm_discard is not None else self._confirm_discard_dialog
        )
        self._project_id: Optional[str] = None
        self._mode = "none"  # none | ok | missing | error
        self._baseline = ""
        self._notice = "clean"  # clean | dirty | error | saved (rendering.config_notice)
        self._notice_error: Optional[str] = None
        self._saved_daemon_running = False
        self._loading = False
        self._build(parent)
        self._load()

    # ------------------------------------------------------------------ #
    # Construction
    # ------------------------------------------------------------------ #
    def _build(self, parent: ttk.Frame) -> None:
        self.frame = parent

        self.header = ttk.Label(parent, font=tokens.FONT_HEADING)
        self.header.pack(side=tk.TOP, anchor=tk.W)

        footer = ttk.Frame(parent)
        footer.pack(side=tk.BOTTOM, fill=tk.X, pady=(8, 0))
        self.notice = ttk.Label(footer, anchor=tk.W)
        self.notice.pack(side=tk.LEFT, fill=tk.X, expand=True)
        self.save_button = ttk.Button(
            footer, text="Save", command=self.save, state=tk.DISABLED, underline=0
        )
        self.save_button.pack(side=tk.RIGHT)
        self.discard_button = ttk.Button(
            footer, text="Discard", command=self.discard, state=tk.DISABLED
        )
        self.discard_button.pack(side=tk.RIGHT, padx=(0, 8))

        # Banner area for the placeholder / missing / read-error states.
        self.banner_frame = ttk.Frame(parent)
        # Wraplength keeps long config paths readable at the minimum window
        # width (PD-UIX-003 §6.1).
        self.banner = ttk.Label(
            self.banner_frame, anchor=tk.CENTER, justify=tk.CENTER, wraplength=440
        )
        self.banner.pack(expand=True)
        self.create_button = ttk.Button(
            self.banner_frame, text="Create default config", command=self._handle_create
        )

        self.body = ttk.Frame(parent)
        self.editor = tk.Text(self.body, wrap="none", undo=True, font=tokens.FONT_MONO)
        yscroll = ttk.Scrollbar(self.body, orient=tk.VERTICAL, command=self.editor.yview)
        self.editor.configure(yscrollcommand=yscroll.set)
        yscroll.pack(side=tk.RIGHT, fill=tk.Y)
        self.editor.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        self.editor.bind("<<Modified>>", self._handle_modified)
        self.editor.bind("<Control-s>", self._handle_save_accel)

    # ------------------------------------------------------------------ #
    # Rendering (one-way, from the model)
    # ------------------------------------------------------------------ #
    def render(self) -> None:
        """Model subscriber: reload on selection change, else refresh chrome."""
        selected = self.model.selected_project_id if self.model is not None else None
        if selected != self._project_id:
            self._project_id = selected
            self._load()
        else:
            self._render_notice()
            self._render_buttons()

    @property
    def is_dirty(self) -> bool:
        return self._mode == "ok" and self._content() != self._baseline

    def _load(self) -> None:
        """Bind the editor to the selected project's config file."""
        snapshot = (
            self.model.snapshot_for(self._project_id)
            if self.model is not None and self._project_id is not None
            else None
        )
        self._notice = "clean"
        self._notice_error = None

        if snapshot is None:
            self._mode = "none"
            self._baseline = ""
            self._set_content("")
            self._show_banner(_SELECT_PLACEHOLDER, error=False, offer_create=False)
            self.header.configure(text="Configuration")
        else:
            self.header.configure(text=f"{snapshot.project.name} — {_CONFIG_RELPATH}")
            result = self._read(snapshot.project.config_path)
            self._mode = result.status
            if result.status == "ok":
                self._baseline = result.text or ""
                self._set_content(self._baseline)
                self._show_editor()
            else:
                self._baseline = ""
                self._set_content("")
                self._show_banner(
                    result.error or "Configuration could not be read",
                    error=True,
                    offer_create=result.status == "missing",
                )
        self._render_notice()
        self._render_buttons()

    def _show_banner(self, text: str, *, error: bool, offer_create: bool) -> None:
        self.body.pack_forget()
        self.banner.configure(
            text=text, foreground=tokens.STATUS_ERROR if error else tokens.MUTED_TEXT
        )
        if offer_create:
            self.create_button.pack(pady=(8, 0))
        else:
            self.create_button.pack_forget()
        self.banner_frame.pack(expand=True, fill=tk.BOTH)

    def _show_editor(self) -> None:
        self.banner_frame.pack_forget()
        self.body.pack(side=tk.TOP, fill=tk.BOTH, expand=True)

    def _render_notice(self) -> None:
        display = rendering.config_notice(
            self._notice, error=self._notice_error, daemon_running=self._saved_daemon_running
        )
        self.notice.configure(text=display.text, foreground=display.color)

    def _render_buttons(self) -> None:
        shutting_down = self.model.shutting_down if self.model is not None else False
        editable = self._mode == "ok" and not shutting_down
        self.editor.configure(state=tk.NORMAL if editable else tk.DISABLED)
        dirty = editable and self.is_dirty
        self.save_button.configure(state=tk.NORMAL if dirty else tk.DISABLED)
        self.discard_button.configure(state=tk.NORMAL if dirty else tk.DISABLED)

    # ------------------------------------------------------------------ #
    # Actions
    # ------------------------------------------------------------------ #
    def save(self) -> bool:
        """Validate-on-save (KR-05): ``True`` only when the file was persisted."""
        if self._mode != "ok" or self._project_id is None or self.model is None:
            return False
        snapshot = self.model.snapshot_for(self._project_id)
        if snapshot is None:
            return False
        text = self._content()
        result = self._save(snapshot.project.config_path, text)
        if result.ok:
            self._baseline = text
            self._notice = "saved"
            self._notice_error = None
            # BR-9/INT-7: the restart notice appears whenever the daemon runs.
            self._saved_daemon_running = snapshot.status is DaemonStatus.RUNNING
        else:
            self._notice = "error"
            self._notice_error = result.error
        self._render_notice()
        self._render_buttons()
        return result.ok

    def discard(self) -> None:
        """Revert to the last-saved content (confirm first, PD-UIX-003 §4.4)."""
        if not self.is_dirty or not self._confirm_discard():
            return
        self._revert()

    def guard_navigation(self) -> bool:
        """Unsaved-changes guard (COMP-6): ``True`` = the switch may proceed."""
        if not self.is_dirty:
            return True
        answer = self._ask_unsaved(self._project_name())
        choice = "save" if answer else ("discard" if answer is False else "cancel")
        save_succeeded = self.save() if choice == "save" else None
        outcome = rendering.unsaved_guard_outcome(choice, save_succeeded)
        if outcome.revert:
            self._revert()
        return outcome.proceed

    def _handle_create(self) -> None:
        """Explicit default-config creation for the EC-10 missing state."""
        if self.model is None or self._project_id is None:
            return
        snapshot = self.model.snapshot_for(self._project_id)
        if snapshot is None:
            return
        result = self._create_default(snapshot.project.config_path)
        if result.ok:
            self._load()
        else:
            self.banner.configure(text=result.error, foreground=tokens.STATUS_ERROR)

    # ------------------------------------------------------------------ #
    # Events / internals
    # ------------------------------------------------------------------ #
    def _handle_modified(self, _event=None) -> None:
        if not self.editor.edit_modified():
            return
        self.editor.edit_modified(False)
        if self._loading:
            return
        if self.is_dirty:
            self._notice = "dirty"
            self._notice_error = None
        elif self._notice == "dirty":
            self._notice = "clean"
        self._render_notice()
        self._render_buttons()

    def _handle_save_accel(self, _event=None) -> str:
        self.save()
        return "break"

    def _revert(self) -> None:
        self._set_content(self._baseline)
        self._notice = "clean"
        self._notice_error = None
        self._render_notice()
        self._render_buttons()

    def _content(self) -> str:
        return self.editor.get("1.0", "end-1c")

    def _set_content(self, text: str) -> None:
        self._loading = True
        try:
            state = self.editor.cget("state")
            self.editor.configure(state=tk.NORMAL)
            self.editor.delete("1.0", tk.END)
            self.editor.insert("1.0", text)
            self.editor.edit_reset()
            self.editor.edit_modified(False)
            self.editor.configure(state=state)
        finally:
            self._loading = False

    def _project_name(self) -> str:
        if self.model is None or self._project_id is None:
            return ""
        snapshot = self.model.snapshot_for(self._project_id)
        return snapshot.project.name if snapshot is not None else self._project_id

    @staticmethod
    def _ask_unsaved_dialog(project_name: str) -> Optional[bool]:
        """Yes = save, No = discard, None (Cancel/dismiss) = stay."""
        target = f" for {project_name}" if project_name else ""
        return messagebox.askyesnocancel(
            "Unsaved changes", f"Save changes to the configuration{target}?"
        )

    @staticmethod
    def _confirm_discard_dialog() -> bool:
        return bool(
            messagebox.askyesno("Discard changes", "Revert to the last-saved configuration?")
        )
