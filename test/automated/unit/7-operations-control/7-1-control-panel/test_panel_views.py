"""
Document Metadata:
ID: TE-TST-147
Type: Test File
Category: Test
Version: 1.0
Created: 2026-08-10
Updated: 2026-08-10
Component Name: views
Feature Id: 7.1.1
Language: Python
Test Name: panel_views
Test Type: Unit
"""

# Headless component tests for the Control Panel view state logic
# (``linkwatcher.linkwatcher_control_panel.views.rendering``), per TE-TSP-045.
#
# Phase C: COMP-1 — the toolbar enablement matrix (BR-1, PD-UIX-003 §4.2).
# Phase D: COMP-5 — the shutdown-dialog row states and "k of n stopped"
# counter (PD-UIX-003 §4.7).
# Phase E: COMP-3 — the validation pane's single visible state (§4.5);
# COMP-4 — the config notice line's single-message rule (§4.4); COMP-6 — the
# unsaved-changes guard resolution (never a silent discard); COMP-7 — the log
# pane's scroll-lock state machine (§4.3).
# Phase G: COMP-2 — the status → glyph + label + token mapping, asserted as a
# totality over ``DaemonStatus`` so no status can ever render color-only
# (PD-UIX-003 §3.4); COMP-8 — the list pane's empty state, the calm EC-8
# presentation that must never read as an error.  Per the test spec's "Tk
# display: avoided" rule these tests drive the pure rendering functions only —
# no widget is ever instantiated.

import pytest

from linkwatcher.linkwatcher_control_panel.model import DaemonSnapshot, DaemonStatus, ValidationRun
from linkwatcher.linkwatcher_control_panel.views import tokens
from linkwatcher.linkwatcher_control_panel.views.rendering import (
    DISCOVERING_TEXT,
    EMPTY_PROJECTS_TEXT,
    ActionEnablement,
    GuardOutcome,
    ListPaneDisplay,
    ScrollLock,
    ShutdownRowDisplay,
    ShutdownSummary,
    action_enablement,
    config_notice,
    format_uptime,
    list_pane_display,
    shutdown_row_display,
    shutdown_summary,
    status_display,
    status_text,
    summarize,
    unsaved_guard_outcome,
    validation_display,
)

pytestmark = [
    pytest.mark.feature("7.1.1"),
    pytest.mark.priority("Standard"),
    pytest.mark.test_type("unit"),
    pytest.mark.specification("TE-TSP-045"),
]


# --------------------------------------------------------------------------- #
# COMP-1 — Toolbar enablement matrix
# --------------------------------------------------------------------------- #
@pytest.mark.parametrize(
    "status, start_enabled, stop_enabled",
    [
        (DaemonStatus.STOPPED, True, False),
        (DaemonStatus.STALE_LOCK, True, False),
        (DaemonStatus.RUNNING, False, True),
        (DaemonStatus.STARTING, False, False),
        (DaemonStatus.DRAINING, False, False),
        (DaemonStatus.FORCE_STOPPED, False, False),
        (DaemonStatus.START_FAILED, False, False),
    ],
)
def test_enablement_matrix(make_project, status, start_enabled, stop_enabled):
    """COMP-1: Start only for STOPPED/STALE_LOCK; Stop only for RUNNING;
    transitions and outcome states enable neither (BR-1, PD-UIX-003 §4.2)."""
    snapshot = DaemonSnapshot(make_project(), status, [])

    assert action_enablement(snapshot) == ActionEnablement(start_enabled, stop_enabled)


def test_no_selection_disables_both():
    """COMP-1: with no selected row, both actions are disabled."""
    assert action_enablement(None) == ActionEnablement(False, False)


def test_shutdown_mode_disables_everything(make_project):
    """COMP-1/COMP-5: global shutdown mode overrides any per-row enablement."""
    snapshot = DaemonSnapshot(make_project(), DaemonStatus.STOPPED, [])

    assert action_enablement(snapshot, shutting_down=True) == ActionEnablement(False, False)


def test_matrix_is_total_over_daemon_status(make_project):
    """Every DaemonStatus member has a defined enablement — a status added later
    must extend the matrix, not crash the toolbar."""
    project = make_project()
    for status in DaemonStatus:
        enablement = action_enablement(DaemonSnapshot(project, status, []))
        assert isinstance(enablement, ActionEnablement)


# --------------------------------------------------------------------------- #
# COMP-2 — Status rendering: glyph + label + token, never color-only
# --------------------------------------------------------------------------- #
def test_every_status_renders_glyph_and_label():
    """COMP-2: every DaemonStatus maps to a glyph **and** a text label.

    The WCAG 2.1 AA rule this enforces (PD-UIX-003 §3.4 / §5.1) is that status
    is never carried by color alone — so a status added later must extend the
    map rather than fall back to a colored blank.
    """
    for status in DaemonStatus:
        display = status_display(status)
        assert display.glyph.strip(), f"{status} has no glyph"
        assert display.label.strip(), f"{status} has no label"
        assert display.color.startswith("#"), f"{status} has no color token"

        # The list cell always carries both, in that order.
        assert status_text(status) == f"{display.glyph} {display.label}"


def test_status_labels_are_unique_so_text_alone_disambiguates():
    """COMP-2: two statuses may share a glyph (▲ starting/draining) or a color,
    but never a label — the text is what a color-blind user, and anyone reading
    the column at a glance, actually relies on."""
    labels = [status_display(status).label for status in DaemonStatus]

    assert len(set(labels)) == len(labels)


@pytest.mark.parametrize(
    "status, glyph, color",
    [
        (DaemonStatus.FORCE_STOPPED, tokens.GLYPH_ERROR, tokens.STATUS_ERROR),
        (DaemonStatus.START_FAILED, tokens.GLYPH_ERROR, tokens.STATUS_ERROR),
        (DaemonStatus.STALE_LOCK, tokens.GLYPH_WARNING, tokens.STATUS_ERROR),
    ],
)
def test_failure_states_use_error_and_warning_tokens(status, glyph, color):
    """COMP-2: the three abnormal outcomes render with error/warning tokens
    (PD-UIX-003 §3.4) — a forced stop or a failed start is never quiet."""
    display = status_display(status)

    assert display.glyph == glyph
    assert display.color == color


def test_stale_lock_reads_as_not_running():
    """COMP-2 + TDD §4.4: a lock with nothing behind it must never look like a
    live daemon — the label says stopped and names the stale lock."""
    label = status_display(DaemonStatus.STALE_LOCK).label

    assert "Stopped" in label
    assert "stale lock" in label


def test_running_and_stopped_do_not_share_a_glyph():
    """The two steady states must be distinguishable at a glance without color."""
    assert status_display(DaemonStatus.RUNNING).glyph != status_display(DaemonStatus.STOPPED).glyph


# --------------------------------------------------------------------------- #
# COMP-2 (list rendering) — uptime column and status-bar summary
#
# Written in Phase B alongside the daemon list, before this file existed; the
# Phase G coverage review found them untested.  Both are pure functions the
# list and status bar render on every tick.
# --------------------------------------------------------------------------- #
@pytest.mark.parametrize(
    "elapsed, expected",
    [
        (0, "0s"),
        (45, "45s"),
        (59, "59s"),
        (60, "1m 00s"),  # zero-padded seconds so the column does not jitter
        (125, "2m 05s"),
        (3599, "59m 59s"),
        (3600, "1h 00m"),
        (7380, "2h 03m"),
        (86399, "23h 59m"),
        (86400, "1d 0h"),
        (183600, "2d 3h"),
    ],
)
def test_uptime_renders_at_the_right_granularity(elapsed, expected):
    """Uptime steps down in precision as it grows (PD-UIX-003 §4.1) and never
    jitters the column width within a unit."""
    assert format_uptime(1000.0, 1000.0 + elapsed) == expected


def test_uptime_is_a_dash_when_there_is_nothing_to_count():
    """A daemon that is not running has no start time — an em-dash, not '0s'."""
    assert format_uptime(None, 5000.0) == "—"


def test_uptime_survives_clock_skew():
    """A start time in the future (system clock adjusted, or a create_time from a
    differently-synced source) must not render a negative age."""
    assert format_uptime(2000.0, 1000.0) == "—"


def test_summary_counts_running_daemons(make_project):
    """The status bar's summary line (PD-UIX-003 §4.6), including its plural."""
    project = make_project()
    rows = [
        DaemonSnapshot(project, DaemonStatus.RUNNING, [700]),
        DaemonSnapshot(project, DaemonStatus.STOPPED, []),
        DaemonSnapshot(project, DaemonStatus.STALE_LOCK, []),
    ]

    assert summarize(rows) == "1 of 3 daemons running"
    assert summarize(rows[:1]) == "1 of 1 daemon running"  # singular
    assert summarize([]) == "0 daemons running"


def test_summary_counts_only_genuinely_running_rows(make_project):
    """Transitional and outcome states are not running — the summary must not
    inflate the count while a daemon is draining or has failed to start."""
    project = make_project()
    rows = [
        DaemonSnapshot(project, DaemonStatus.DRAINING, [700]),
        DaemonSnapshot(project, DaemonStatus.STARTING, []),
        DaemonSnapshot(project, DaemonStatus.START_FAILED, []),
        DaemonSnapshot(project, DaemonStatus.FORCE_STOPPED, []),
    ]

    assert summarize(rows) == "0 of 4 daemons running"


# --------------------------------------------------------------------------- #
# COMP-5 — Shutdown dialog rows + counter
# --------------------------------------------------------------------------- #
def test_shutdown_row_draining_states(make_project):
    """COMP-5: draining rows show glyph + elapsed seconds; RUNNING (stop not yet
    pinned) renders as draining too — the dialog never claims a live daemon."""
    draining = shutdown_row_display(DaemonStatus.DRAINING, elapsed_seconds=4.2)
    assert draining == ShutdownRowDisplay("▲ Draining… (4s)", tokens.STATUS_TRANSITION)

    assert shutdown_row_display(DaemonStatus.RUNNING, 0.4).text == "▲ Draining… (0s)"
    assert shutdown_row_display(DaemonStatus.DRAINING).text == "▲ Draining…"  # no elapsed


def test_shutdown_row_terminal_states():
    """COMP-5: force-stopped rows keep their error surfacing until exit (EC-4);
    every other terminal state renders as cleanly stopped."""
    forced = shutdown_row_display(DaemonStatus.FORCE_STOPPED, 25.0)
    assert forced == ShutdownRowDisplay("✕ Force-stopped (grace elapsed)", tokens.STATUS_ERROR)

    stopped = shutdown_row_display(DaemonStatus.STOPPED, 6.0)
    assert stopped == ShutdownRowDisplay("✔ Stopped", tokens.STATUS_RUNNING)

    # Daemon gone but a foreign lock was left intact — the daemon IS stopped.
    assert shutdown_row_display(DaemonStatus.STALE_LOCK, 6.0).text == "✔ Stopped"


def test_shutdown_row_display_is_total_over_daemon_status():
    """A status added later must render somehow, never crash the dialog."""
    for status in DaemonStatus:
        assert isinstance(shutdown_row_display(status, 1.0), ShutdownRowDisplay)


def test_shutdown_summary_matches_wireframe():
    """COMP-5: one ✔, one ✕, one still draining → '2 of 3 stopped' (Screen 4)."""
    summary = shutdown_summary(
        [DaemonStatus.DRAINING, DaemonStatus.STOPPED, DaemonStatus.FORCE_STOPPED]
    )
    assert summary == ShutdownSummary(2, 3, "2 of 3 stopped")


def test_shutdown_summary_all_resolved():
    """COMP-5: the counter reaches n of n when every row is terminal."""
    summary = shutdown_summary([DaemonStatus.STOPPED, DaemonStatus.FORCE_STOPPED])
    assert summary.done == summary.total == 2
    assert summary.text == "2 of 2 stopped"


# --------------------------------------------------------------------------- #
# COMP-3 — Validation pane: one visible state at a time
# --------------------------------------------------------------------------- #
def test_validation_state_walk_mirrors_validation_run():
    """COMP-3: idle → running → result transitions mirror ValidationRun.state."""
    assert validation_display(None).mode == "idle"
    assert validation_display(ValidationRun()).mode == "idle"
    assert validation_display(ValidationRun(state="running")).mode == "running"
    assert validation_display(ValidationRun(state="ok", broken_count=0)).mode == "result"
    assert validation_display(ValidationRun(state="broken", broken_count=3)).mode == "result"
    assert validation_display(ValidationRun(state="failed", error="x")).mode == "failure"


def test_validation_running_notes_the_daemon_keeps_running():
    """BR-6 surfaced in the UI: a validation run never touches the daemon."""
    display = validation_display(ValidationRun(state="running"))
    assert "daemon keeps running" in display.text
    assert display.color == tokens.STATUS_TRANSITION


def test_validation_results_are_glyph_plus_text(tmp_path):
    """Results carry glyph + count + token — never color alone (PD-UIX-003 §3.4)."""
    report = tmp_path / "LinkWatcherBrokenLinks.txt"
    clean = validation_display(ValidationRun(state="ok", broken_count=0, report_path=report))
    assert clean.text == f"{tokens.GLYPH_STOPPED_CLEAN} 0 broken links"
    assert clean.color == tokens.STATUS_RUNNING
    assert clean.report_path == report

    broken = validation_display(ValidationRun(state="broken", broken_count=3, report_path=report))
    assert broken.text == f"{tokens.GLYPH_ERROR} 3 broken links"
    assert broken.color == tokens.STATUS_ERROR
    assert broken.report_path == report

    single = validation_display(ValidationRun(state="broken", broken_count=1))
    assert single.text == f"{tokens.GLYPH_ERROR} 1 broken link"  # singular


def test_validation_broken_without_a_count_still_reports_broken():
    """EC-6: an unparseable count must not soften "broken" into a clean result —
    the pane says broken links were found, just without a number."""
    display = validation_display(ValidationRun(state="broken", broken_count=None))

    assert display.mode == "result"
    assert display.text == f"{tokens.GLYPH_ERROR} Broken links found"
    assert display.color == tokens.STATUS_ERROR


def test_validation_failure_never_renders_as_success():
    """COMP-3/EC-6: a failure is its own state with the reason, no report link."""
    display = validation_display(ValidationRun(state="failed", error="spawn failed"))
    assert display.mode == "failure"
    assert "Validation failed: spawn failed" in display.text
    assert display.color == tokens.STATUS_ERROR
    assert display.report_path is None


# --------------------------------------------------------------------------- #
# COMP-4 — Config notice line: single-message rule
# --------------------------------------------------------------------------- #
def test_config_notice_states_are_mutually_exclusive():
    """COMP-4: exactly one of clean/dirty/error/saved — never stacked; each
    state yields one message string, so stacking is impossible by construction."""
    assert config_notice("clean").text == ""
    assert config_notice("dirty").text == f"{tokens.GLYPH_INFO} Unsaved changes"
    assert (
        config_notice("error", error="Line 12: mapping values are not allowed").text
        == f"{tokens.GLYPH_ERROR} Line 12: mapping values are not allowed"
    )
    assert config_notice("saved").text == "Saved."


def test_config_notice_restart_needed_when_daemon_running():
    """BR-9/INT-7: the restart notice appears whenever the daemon is running."""
    running = config_notice("saved", daemon_running=True)
    assert running.text == f"{tokens.GLYPH_WARNING} Saved. Restart the daemon to apply changes."
    assert running.color == tokens.STATUS_TRANSITION

    stopped = config_notice("saved", daemon_running=False)
    assert stopped.text == "Saved."
    assert stopped.color == tokens.STATUS_RUNNING


def test_config_notice_error_uses_error_token():
    assert config_notice("error", error="bad").color == tokens.STATUS_ERROR
    assert config_notice("dirty").color == tokens.MUTED_TEXT


def test_config_notice_rejects_unknown_state():
    with pytest.raises(ValueError):
        config_notice("panicking")


# --------------------------------------------------------------------------- #
# COMP-6 — Unsaved-changes guard: never a silent discard
# --------------------------------------------------------------------------- #
def test_guard_save_proceeds_only_when_save_succeeded():
    assert unsaved_guard_outcome("save", save_succeeded=True) == GuardOutcome(True, False)
    # A blocked save stays on the editor with its error visible — no discard.
    assert unsaved_guard_outcome("save", save_succeeded=False) == GuardOutcome(False, False)


def test_guard_discard_is_the_only_path_that_reverts():
    assert unsaved_guard_outcome("discard") == GuardOutcome(True, True)


def test_guard_cancel_and_dismissed_dialog_stay_put():
    """COMP-6: cancel (or dismissing the dialog) never proceeds, never reverts."""
    assert unsaved_guard_outcome("cancel") == GuardOutcome(False, False)
    assert unsaved_guard_outcome(None) == GuardOutcome(False, False)


# --------------------------------------------------------------------------- #
# COMP-7 — Log pane scroll-lock state machine
# --------------------------------------------------------------------------- #
def test_scroll_lock_pauses_on_scroll_up():
    """COMP-7: following pauses when the user leaves the end position."""
    lock = ScrollLock()
    assert lock.following  # follows by default

    lock.scrolled(at_end=False)
    assert not lock.following

    # Staying scrolled up keeps it paused; landing at the end alone does not
    # resume — only an explicit re-enable does (PD-UIX-003 §4.3).
    lock.scrolled(at_end=True)
    assert not lock.following


def test_scroll_lock_resumes_on_checkbox_re_enable():
    lock = ScrollLock()
    lock.scrolled(at_end=False)
    lock.set_following(True)
    assert lock.following

    lock.set_following(False)  # unticking pauses without scrolling
    assert not lock.following


def test_scroll_lock_resumes_on_jump_to_end():
    """COMP-7: Ctrl+End jumps to the newest lines and re-enables following."""
    lock = ScrollLock()
    lock.scrolled(at_end=False)
    lock.jump_to_end()
    assert lock.following


def test_scroll_lock_ignores_at_end_reports_while_following():
    """Appends keep the view at the end — that must never flip the state."""
    lock = ScrollLock()
    lock.scrolled(at_end=True)
    assert lock.following


# --------------------------------------------------------------------------- #
# COMP-8 — Empty state (EC-8): no registered projects is calm, not an error
# --------------------------------------------------------------------------- #
def test_empty_registry_selects_the_calm_empty_state():
    """COMP-8/EC-8: zero registered projects renders Screen 5's muted message —
    an empty registry is a state of the world, not a failure of the panel."""
    display = list_pane_display([], None)

    assert display == ListPaneDisplay("empty", EMPTY_PROJECTS_TEXT, tokens.MUTED_TEXT)
    assert "registered" in display.text


def test_empty_state_wording_never_reads_as_a_failure():
    """EC-8 in words: the empty state must not use error vocabulary, or the
    operator will hunt for a fault that does not exist."""
    text = list_pane_display([], None).text.lower()

    for word in ("error", "failed", "failure", "cannot", "unable"):
        assert word not in text


def test_empty_state_leaves_the_toolbar_fully_disabled():
    """COMP-8: with nothing to select there is nothing to act on (BR-1)."""
    assert action_enablement(None) == ActionEnablement(False, False)


def test_unresolved_registry_renders_as_an_error_banner():
    """COMP-8: the *unresolved registry* case is distinct from the empty one —
    it is a real fault and gets the error token (UNIT-S5 keeps them separate)."""
    display = list_pane_display([], "Project registry not found — see panel log")

    assert display.mode == "error"
    assert display.text == "Project registry not found — see panel log"
    assert display.color == tokens.STATUS_ERROR


def test_pending_discovery_is_not_reported_as_an_empty_registry():
    """COMP-8: before the first poll lands the panel does not know whether any
    projects exist — claiming "no registered projects" would be false.

    Found in Phase G against a real machine: the first psutil pass took ~7.5 s
    (409 processes), during which the pane asserted an empty registry.  Same
    truthfulness rule as transitional row states (TDD §4.3), applied to the
    list pane's own "no data yet" case.
    """
    display = list_pane_display([], None, discovery_pending=True)

    assert display == ListPaneDisplay("loading", DISCOVERING_TEXT, tokens.MUTED_TEXT)
    assert display.text != EMPTY_PROJECTS_TEXT


def test_completed_discovery_with_nothing_in_it_is_the_empty_state():
    """The wait state is only for *pending* discovery — once a poll has landed,
    zero projects really is the EC-8 empty state."""
    assert list_pane_display([], None, discovery_pending=False).mode == "empty"


def test_a_real_error_outranks_the_pending_state():
    """An unresolved registry never resolves — showing "Discovering…" forever
    would hide a fault the operator must act on."""
    display = list_pane_display([], "Project registry not found", discovery_pending=True)

    assert display.mode == "error"


def test_rows_outrank_a_discovery_error(make_project):
    """COMP-8: a discovery error that still produced rows belongs in the status
    bar — the list keeps showing the daemons it knows about."""
    rows = [DaemonSnapshot(make_project(), DaemonStatus.RUNNING, [700])]

    assert list_pane_display(rows, "one project failed to classify").mode == "tree"
