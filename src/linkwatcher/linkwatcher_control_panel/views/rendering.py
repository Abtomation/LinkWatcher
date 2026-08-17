"""
Display-free rendering rules for the Control Panel views.

Pure functions that turn model values into the strings and tokens a widget
shows.  Keeping them out of the widgets is a design obligation from the TDD
(§4.2, "render from model only"): it is what lets the component tests (COMP-1…8)
assert rendering rules headlessly, and what keeps a toolkit swap confined to the
``views/`` layer.

AI Context
----------
- Every status renders as **glyph + text**, never color-only (PD-UIX-003 §5 /
  WCAG 2.1 AA) — the color token is an accompaniment, never the sole carrier of
  meaning.
- STALE_LOCK renders as *not running* with a warning, per TDD §4.4: a lock with
  nothing behind it must never look like a live daemon.
- No module here imports Tkinter, so these rules are importable and testable
  without a display.
"""

from __future__ import annotations

from pathlib import Path
from typing import NamedTuple, Optional

from ..lifecycle import STILL_DRAINING_STATUSES
from ..model import DaemonSnapshot, DaemonStatus, ValidationRun
from . import tokens


class StatusDisplay(NamedTuple):
    """How one :class:`~..model.DaemonStatus` is presented in the list."""

    glyph: str
    label: str
    color: str


_STATUS_DISPLAY = {
    DaemonStatus.RUNNING: StatusDisplay(tokens.GLYPH_RUNNING, "Running", tokens.STATUS_RUNNING),
    DaemonStatus.STOPPED: StatusDisplay(tokens.GLYPH_STOPPED, "Stopped", tokens.STATUS_STOPPED),
    DaemonStatus.STARTING: StatusDisplay(
        tokens.GLYPH_TRANSITION, "Starting…", tokens.STATUS_TRANSITION
    ),
    DaemonStatus.DRAINING: StatusDisplay(
        tokens.GLYPH_TRANSITION, "Stopping — draining…", tokens.STATUS_TRANSITION
    ),
    DaemonStatus.FORCE_STOPPED: StatusDisplay(
        tokens.GLYPH_ERROR, "Force-stopped", tokens.STATUS_ERROR
    ),
    DaemonStatus.START_FAILED: StatusDisplay(
        tokens.GLYPH_ERROR, "Start failed", tokens.STATUS_ERROR
    ),
    DaemonStatus.STALE_LOCK: StatusDisplay(
        tokens.GLYPH_WARNING, "Stopped (stale lock)", tokens.STATUS_ERROR
    ),
}


def status_display(status: DaemonStatus) -> StatusDisplay:
    """Glyph, label and color token for *status* (every status maps to all three)."""
    return _STATUS_DISPLAY[status]


def status_text(status: DaemonStatus) -> str:
    """The list cell's text: glyph and label together, never one without the other."""
    display = status_display(status)
    return f"{display.glyph} {display.label}"


def format_uptime(started_at: Optional[float], now: float) -> str:
    """Render elapsed time since *started_at* (epoch seconds) as a compact string.

    Returns an em-dash for a daemon that isn't running, and for a clock skew that
    would otherwise render a negative age.
    """
    if started_at is None:
        return "—"
    seconds = int(now - started_at)
    if seconds < 0:
        return "—"
    if seconds < 60:
        return f"{seconds}s"
    minutes, seconds = divmod(seconds, 60)
    if minutes < 60:
        return f"{minutes}m {seconds:02d}s"
    hours, minutes = divmod(minutes, 60)
    if hours < 24:
        return f"{hours}h {minutes:02d}m"
    days, hours = divmod(hours, 24)
    return f"{days}d {hours}h"


def summarize(rows) -> str:
    """Status-bar summary: how many of the listed daemons are running."""
    running = sum(1 for row in rows if row.status is DaemonStatus.RUNNING)
    if not rows:
        return "0 daemons running"
    return f"{running} of {len(rows)} daemon{'s' if len(rows) != 1 else ''} running"


# The Screen-5 empty state (PD-UIX-003 §2.2): EC-8 is a calm state, not an
# error, so its wording never mentions failure.
EMPTY_PROJECTS_TEXT = (
    "No registered projects found.\n\n"
    "Projects appear here once registered\n"
    "in the central project registry."
)


# Shown until the first poll lands.  "No registered projects" is a *claim about
# reality*; before discovery has reported, the panel does not know it yet — and
# the first psutil pass can take several seconds on a busy machine (Phase G
# measurement: ~7.5 s cold, ~0.1 s warm).  Announcing the empty state during
# that window would make the panel say something false, which is the same
# truthfulness rule that forbids optimistic row states (TDD §4.3).
DISCOVERING_TEXT = "Discovering daemons…"


class ListPaneDisplay(NamedTuple):
    """Which content the list pane shows: the tree, a wait state, the empty state, or an error."""

    mode: str  # "tree" | "loading" | "empty" | "error"
    text: str
    color: str


def list_pane_display(
    rows, error: Optional[str] = None, *, discovery_pending: bool = False
) -> ListPaneDisplay:
    """Select the list pane's content (COMP-8, PD-UIX-003 Screen 5).

    Precedence: rows win — a registry/discovery error that still produced rows
    belongs in the status bar, not in place of the list.  With no rows, a real
    error is a banner; otherwise a discovery that has not reported yet is a
    wait state, and only a *completed* discovery with nothing in it is the calm
    EC-8 empty state.  An empty registry is never presented as a failure, and a
    pending one is never presented as empty.
    """
    if rows:
        return ListPaneDisplay("tree", "", tokens.MUTED_TEXT)
    if error:
        return ListPaneDisplay("error", error, tokens.STATUS_ERROR)
    if discovery_pending:
        return ListPaneDisplay("loading", DISCOVERING_TEXT, tokens.MUTED_TEXT)
    return ListPaneDisplay("empty", EMPTY_PROJECTS_TEXT, tokens.MUTED_TEXT)


class ActionEnablement(NamedTuple):
    """Whether the Start / Stop toolbar actions apply to the selected row."""

    start: bool
    stop: bool


# The COMP-1 enablement matrix (BR-1, PD-UIX-003 §4.2): Start only where a start
# can do something (STOPPED, or STALE_LOCK — the launcher's stale-reclaim path);
# Stop only on a live daemon.  Transitional (STARTING/DRAINING) and outcome
# (FORCE_STOPPED/START_FAILED) states enable neither — the row resolves to poll
# truth first.
_START_ENABLED = frozenset({DaemonStatus.STOPPED, DaemonStatus.STALE_LOCK})
_STOP_ENABLED = frozenset({DaemonStatus.RUNNING})


def action_enablement(
    snapshot: Optional[DaemonSnapshot], shutting_down: bool = False
) -> ActionEnablement:
    """Start/Stop enablement for the selected row (``None`` = no selection).

    Pure function of the *effective* snapshot status — a pinned transitional
    state disables both by construction, and shutdown mode disables everything
    (UNIT-M7 / COMP-5).
    """
    if snapshot is None or shutting_down:
        return ActionEnablement(False, False)
    return ActionEnablement(
        start=snapshot.status in _START_ENABLED,
        stop=snapshot.status in _STOP_ENABLED,
    )


class ShutdownRowDisplay(NamedTuple):
    """One shutdown-dialog row: state text (glyph included) and color token."""

    text: str
    color: str


def shutdown_row_display(
    status: DaemonStatus, elapsed_seconds: Optional[float] = None
) -> ShutdownRowDisplay:
    """A shutdown-dialog row's state per PD-UIX-003 §4.7 (COMP-5).

    RUNNING counts as draining — during shutdown it only means the stop worker
    has not pinned the row yet.  Anything outside the still-draining pair is a
    resolved daemon: FORCE_STOPPED keeps its error surfacing (visible until
    exit, never silent — EC-4); every other terminal state (STOPPED, or
    STALE_LOCK when a foreign lock was left intact) renders as cleanly stopped
    — the daemon is gone either way.
    """
    if status in STILL_DRAINING_STATUSES:
        suffix = "" if elapsed_seconds is None else f" ({int(elapsed_seconds)}s)"
        return ShutdownRowDisplay(
            f"{tokens.GLYPH_TRANSITION} Draining…{suffix}", tokens.STATUS_TRANSITION
        )
    if status is DaemonStatus.FORCE_STOPPED:
        return ShutdownRowDisplay(
            f"{tokens.GLYPH_ERROR} Force-stopped (grace elapsed)", tokens.STATUS_ERROR
        )
    return ShutdownRowDisplay(f"{tokens.GLYPH_STOPPED_CLEAN} Stopped", tokens.STATUS_RUNNING)


class ShutdownSummary(NamedTuple):
    """The dialog's progress state: resolved daemons out of total targets."""

    done: int
    total: int
    text: str


def shutdown_summary(statuses) -> ShutdownSummary:
    """The "«k» of «n» stopped" counter + progress value (COMP-5)."""
    total = len(statuses)
    done = sum(1 for status in statuses if status not in STILL_DRAINING_STATUSES)
    return ShutdownSummary(done, total, f"{done} of {total} stopped")


class ValidationDisplay(NamedTuple):
    """The Validation pane's single visible state (COMP-3, PD-UIX-003 §4.5).

    ``mode`` selects which block is shown — ``idle`` / ``running`` / ``result``
    / ``failure`` — exactly one at a time; ``report_path`` enables the
    "Open report" affordance when set.
    """

    mode: str
    text: str
    color: str
    report_path: Optional[Path]


def validation_display(run: Optional[ValidationRun]) -> ValidationDisplay:
    """Map a :class:`~..model.ValidationRun` to the pane's one visible state.

    Mirrors ``ValidationRun.state`` (COMP-3): a result persists until the next
    run or project switch; a failure is never rendered as success (EC-6).
    """
    if run is None or run.state == "idle":
        return ValidationDisplay("idle", "No validation run yet.", tokens.MUTED_TEXT, None)
    if run.state == "running":
        return ValidationDisplay(
            "running",
            "Validating… daemon keeps running (no stop needed)",
            tokens.STATUS_TRANSITION,
            None,
        )
    if run.state == "ok":
        return ValidationDisplay(
            "result",
            f"{tokens.GLYPH_STOPPED_CLEAN} 0 broken links",
            tokens.STATUS_RUNNING,
            run.report_path,
        )
    if run.state == "broken":
        if run.broken_count is not None:
            plural = "s" if run.broken_count != 1 else ""
            text = f"{tokens.GLYPH_ERROR} {run.broken_count} broken link{plural}"
        else:
            text = f"{tokens.GLYPH_ERROR} Broken links found"
        return ValidationDisplay("result", text, tokens.STATUS_ERROR, run.report_path)
    return ValidationDisplay(
        "failure",
        f"{tokens.GLYPH_WARNING} Validation failed: {run.error or 'unknown reason'}",
        tokens.STATUS_ERROR,
        None,
    )


class ConfigNotice(NamedTuple):
    """The config editor's notice line: one message and its color token."""

    text: str
    color: str


def config_notice(
    state: str, *, error: Optional[str] = None, daemon_running: bool = False
) -> ConfigNotice:
    """The single-message notice line (COMP-4, PD-UIX-003 §4.4).

    Exactly one of clean (empty) / dirty ⓘ / error / saved is ever shown —
    never stacked.  The restart-needed variant appears whenever the project's
    daemon is running at save time (BR-9, INT-7): the daemon reads config only
    at startup, so no per-key hot-apply analysis is attempted.
    """
    if state == "clean":
        return ConfigNotice("", tokens.MUTED_TEXT)
    if state == "dirty":
        return ConfigNotice(f"{tokens.GLYPH_INFO} Unsaved changes", tokens.MUTED_TEXT)
    if state == "error":
        return ConfigNotice(
            f"{tokens.GLYPH_ERROR} {error or 'Invalid configuration'}", tokens.STATUS_ERROR
        )
    if state == "saved":
        if daemon_running:
            return ConfigNotice(
                f"{tokens.GLYPH_WARNING} Saved. Restart the daemon to apply changes.",
                tokens.STATUS_TRANSITION,
            )
        return ConfigNotice("Saved.", tokens.STATUS_RUNNING)
    raise ValueError(f"Unknown config notice state: {state!r}")


class GuardOutcome(NamedTuple):
    """Resolution of the unsaved-changes prompt: proceed with the switch? revert the editor?"""

    proceed: bool
    revert: bool


def unsaved_guard_outcome(
    choice: Optional[str], save_succeeded: Optional[bool] = None
) -> GuardOutcome:
    """Resolve a Save / Discard / Cancel prompt (COMP-6, PD-UIX-003 §4.4).

    *choice* is ``"save"`` / ``"discard"`` / ``"cancel"`` (``None`` — a
    dismissed dialog — counts as cancel).  Work is never silently lost: save
    proceeds only when the save actually succeeded (a blocked save stays on the
    editor with its error visible), and only an explicit discard reverts.
    """
    if choice == "save":
        return GuardOutcome(proceed=bool(save_succeeded), revert=False)
    if choice == "discard":
        return GuardOutcome(proceed=True, revert=True)
    return GuardOutcome(proceed=False, revert=False)


class ScrollLock:
    """The log pane's auto-scroll state machine (COMP-7, PD-UIX-003 §4.3).

    Display-free: the view reports scroll positions and checkbox toggles; this
    class answers "is following on?".  Scrolling away from the end pauses
    following; only an explicit re-enable (checkbox) or jump-to-end (Ctrl+End)
    resumes it.
    """

    def __init__(self):
        self.following = True

    def scrolled(self, at_end: bool) -> None:
        """The user (or a view change) left the pane at/off the end position."""
        if not at_end:
            self.following = False

    def set_following(self, enabled: bool) -> None:
        """The auto-scroll checkbox was toggled (re-enabling jumps to the end)."""
        self.following = bool(enabled)

    def jump_to_end(self) -> None:
        """Ctrl+End: jump to the newest lines and resume following."""
        self.following = True
