"""
Document Metadata:
ID: TE-TST-143
Type: Test File
Category: Test
Version: 1.0
Created: 2026-07-31
Updated: 2026-07-31
Component Name: model
Feature Id: 7.1.1
Language: Python
Test Name: panel_model
Test Type: Unit

Unit tests for the Control Panel observable model
(``linkwatcher.linkwatcher_control_panel.model``):

- notification contract — fires on change, silent otherwise (UNIT-M1)
- keyed snapshots and selection survival across refreshes (UNIT-M2, UNIT-M3)
- the reconciliation rule: pins override poll truth, resolve on their observed
  destination state, and always expire (UNIT-M4…M6, TDD §4.3)
- global shutdown mode (UNIT-M7)

Pin expiry is driven by the injected ``fake_clock`` — the model never waits, so
deadline behavior (including the exact boundary) is asserted deterministically.
"""

from pathlib import Path

import pytest

from linkwatcher.linkwatcher_control_panel.model import (
    AppModel,
    DaemonSnapshot,
    DaemonStatus,
    ProjectInfo,
    ValidationRun,
)

pytestmark = [
    pytest.mark.feature("7.1.1"),
    pytest.mark.priority("Critical"),
    pytest.mark.test_type("unit"),
    pytest.mark.specification("TE-TSP-045"),
]


# --------------------------------------------------------------------------- #
# Helpers
# --------------------------------------------------------------------------- #
def _project(project_id: str = "PRJ-001") -> ProjectInfo:
    root = Path(f"C:/x/{project_id}")
    return ProjectInfo(
        project_id=project_id,
        name=project_id,
        root=root,
        config_path=root / "tools" / "linkwatcher" / "linkwatcher-config.yaml",
        log_dir=root / "logs" / "linkwatcher",
    )


def _snapshot(project_id="PRJ-001", status=DaemonStatus.STOPPED, pids=None, started_at=None):
    return DaemonSnapshot(_project(project_id), status, list(pids or []), started_at)


class Recorder:
    """Counts subscriber notifications."""

    def __init__(self):
        self.calls = 0

    def __call__(self):
        self.calls += 1


# --------------------------------------------------------------------------- #
# UNIT-M1 — Observable updates
# --------------------------------------------------------------------------- #
def test_subscriber_notified_when_state_changes(fake_clock):
    """UNIT-M1: applying a poll that changes rendered state notifies subscribers."""
    model = AppModel(clock=fake_clock)
    recorder = Recorder()
    model.subscribe(recorder)

    model.apply_poll([_snapshot(status=DaemonStatus.RUNNING, pids=[1, 2])])

    assert recorder.calls == 1


def test_identical_poll_produces_no_notification(fake_clock):
    """UNIT-M1: re-applying an unchanged poll is silent — no spurious repaints."""
    model = AppModel(clock=fake_clock)
    model.apply_poll([_snapshot(status=DaemonStatus.RUNNING, pids=[1, 2])])
    recorder = Recorder()
    model.subscribe(recorder)

    model.apply_poll([_snapshot(status=DaemonStatus.RUNNING, pids=[1, 2])])

    assert recorder.calls == 0


def test_all_subscribers_are_notified(fake_clock):
    """UNIT-M1 (edge): every registered subscriber receives the notification."""
    model = AppModel(clock=fake_clock)
    first, second = Recorder(), Recorder()
    model.subscribe(first)
    model.subscribe(second)

    model.apply_poll([_snapshot(status=DaemonStatus.RUNNING)])

    assert (first.calls, second.calls) == (1, 1)


def test_discovery_error_change_alone_notifies(fake_clock):
    """UNIT-M1: a newly surfaced discovery error repaints even with identical rows."""
    model = AppModel(clock=fake_clock)
    model.apply_poll([_snapshot()])
    recorder = Recorder()
    model.subscribe(recorder)

    model.apply_poll([_snapshot()], error="registry unreadable")

    assert recorder.calls == 1
    assert model.discovery_error == "registry unreadable"


# --------------------------------------------------------------------------- #
# UNIT-M2 — Keyed snapshots
# --------------------------------------------------------------------------- #
def test_rows_are_keyed_by_project_id(fake_clock):
    """UNIT-M2: a poll updates only the row for each project_id it carries."""
    model = AppModel(clock=fake_clock)
    model.apply_poll(
        [
            _snapshot("PRJ-001", DaemonStatus.RUNNING, [1]),
            _snapshot("PRJ-002", DaemonStatus.STOPPED),
        ]
    )

    model.apply_poll(
        [
            _snapshot("PRJ-001", DaemonStatus.RUNNING, [1]),
            _snapshot("PRJ-002", DaemonStatus.RUNNING, [9]),
        ]
    )

    statuses = {row.project.project_id: row.status for row in model.rows()}
    assert statuses == {"PRJ-001": DaemonStatus.RUNNING, "PRJ-002": DaemonStatus.RUNNING}


def test_new_project_is_added_and_removed_project_is_dropped(fake_clock):
    """UNIT-M2 (edge): the row set follows the registry — additions and removals."""
    model = AppModel(clock=fake_clock)
    model.apply_poll([_snapshot("PRJ-001")])

    model.apply_poll([_snapshot("PRJ-002")])

    assert [row.project.project_id for row in model.rows()] == ["PRJ-002"]
    assert model.snapshot_for("PRJ-001") is None


# --------------------------------------------------------------------------- #
# UNIT-M3 — Selection survival
# --------------------------------------------------------------------------- #
def test_selection_survives_a_full_refresh(fake_clock):
    """UNIT-M3: selection is keyed by project, so a poll never steals it."""
    model = AppModel(clock=fake_clock)
    model.apply_poll([_snapshot("PRJ-001"), _snapshot("PRJ-002")])
    model.select("PRJ-002")

    model.apply_poll([_snapshot("PRJ-001", DaemonStatus.RUNNING, [1]), _snapshot("PRJ-002")])

    assert model.selected_project_id == "PRJ-002"


def test_selection_cleared_when_selected_project_disappears(fake_clock):
    """UNIT-M3 (edge): a project dropped from the registry cannot stay selected."""
    model = AppModel(clock=fake_clock)
    model.apply_poll([_snapshot("PRJ-001"), _snapshot("PRJ-002")])
    model.select("PRJ-002")

    model.apply_poll([_snapshot("PRJ-001")])

    assert model.selected_project_id is None


def test_selecting_an_unknown_project_is_ignored(fake_clock):
    """UNIT-M3 (guard): selection can never point at a row that isn't listed."""
    model = AppModel(clock=fake_clock)
    model.apply_poll([_snapshot("PRJ-001")])

    model.select("PRJ-404")

    assert model.selected_project_id is None


# --------------------------------------------------------------------------- #
# UNIT-M4 — Pin overrides poll
# --------------------------------------------------------------------------- #
def test_draining_pin_overrides_a_poll_that_still_sees_running(fake_clock):
    """UNIT-M4: a DRAINING row stays DRAINING while the poll still reports RUNNING.

    The truthful-state rule (FDD FR-4): a slow poll must not undo a transition
    the panel itself initiated.
    """
    model = AppModel(clock=fake_clock)
    model.apply_poll([_snapshot(status=DaemonStatus.RUNNING, pids=[1, 2])])
    model.pin("PRJ-001", DaemonStatus.DRAINING, ttl_seconds=25.0, detail="draining")

    model.apply_poll([_snapshot(status=DaemonStatus.RUNNING, pids=[1, 2])])

    row = model.snapshot_for("PRJ-001")
    assert row.status is DaemonStatus.DRAINING
    assert row.detail == "draining"
    assert row.pids == [1, 2]  # the pin overrides status, not the observed facts


def test_starting_pin_overrides_a_poll_that_still_sees_stopped(fake_clock):
    """UNIT-M4 (edge): STARTING survives polls reporting STOPPED until it resolves."""
    model = AppModel(clock=fake_clock)
    model.apply_poll([_snapshot(status=DaemonStatus.STOPPED)])
    model.pin("PRJ-001", DaemonStatus.STARTING, ttl_seconds=15.0)

    model.apply_poll([_snapshot(status=DaemonStatus.STOPPED)])

    assert model.snapshot_for("PRJ-001").status is DaemonStatus.STARTING


def test_force_stopped_pin_is_not_cleared_by_a_stopped_poll(fake_clock):
    """An outcome pin (FORCE_STOPPED) is not resolved away — a forced stop stays visible.

    Only its deadline releases it, so the operator sees *why* the daemon stopped
    instead of a plain "Stopped" (BR-7: forced termination is never silent).
    """
    model = AppModel(clock=fake_clock)
    model.apply_poll([_snapshot(status=DaemonStatus.RUNNING, pids=[1])])
    model.pin("PRJ-001", DaemonStatus.FORCE_STOPPED, ttl_seconds=30.0)

    model.apply_poll([_snapshot(status=DaemonStatus.STOPPED)])

    assert model.snapshot_for("PRJ-001").status is DaemonStatus.FORCE_STOPPED


# --------------------------------------------------------------------------- #
# UNIT-M5 — Pin expiry
# --------------------------------------------------------------------------- #
def test_expired_pin_is_dropped_and_poll_truth_wins(fake_clock):
    """UNIT-M5: once the deadline passes the pin is gone — a hung worker never freezes a row."""
    model = AppModel(clock=fake_clock)
    model.apply_poll([_snapshot(status=DaemonStatus.RUNNING, pids=[1])])
    model.pin("PRJ-001", DaemonStatus.DRAINING, ttl_seconds=25.0)

    fake_clock.advance(25.1)

    assert model.snapshot_for("PRJ-001").status is DaemonStatus.RUNNING
    assert model.pinned_status("PRJ-001") is None


def test_pin_expires_exactly_at_its_deadline(fake_clock):
    """UNIT-M5 (boundary): the pin holds *before* the deadline and is gone *at* it."""
    model = AppModel(clock=fake_clock)
    model.apply_poll([_snapshot(status=DaemonStatus.RUNNING, pids=[1])])
    model.pin("PRJ-001", DaemonStatus.DRAINING, ttl_seconds=20.0)

    fake_clock.advance(19.999)
    assert model.snapshot_for("PRJ-001").status is DaemonStatus.DRAINING

    fake_clock.advance(0.001)  # now == deadline
    assert model.snapshot_for("PRJ-001").status is DaemonStatus.RUNNING


def test_tick_notifies_when_a_pin_expires(fake_clock):
    """UNIT-M5: the UI tick repaints on expiry even without new poll data."""
    model = AppModel(clock=fake_clock)
    model.apply_poll([_snapshot(status=DaemonStatus.RUNNING, pids=[1])])
    model.pin("PRJ-001", DaemonStatus.DRAINING, ttl_seconds=5.0)
    recorder = Recorder()
    model.subscribe(recorder)

    model.tick()
    assert recorder.calls == 0  # nothing due yet

    fake_clock.advance(5.0)
    model.tick()
    assert recorder.calls == 1


# --------------------------------------------------------------------------- #
# UNIT-M6 — Pin resolution
# --------------------------------------------------------------------------- #
def test_starting_pin_resolves_when_poll_observes_running(fake_clock):
    """UNIT-M6: STARTING clears as soon as the poll sees the running pair."""
    model = AppModel(clock=fake_clock)
    model.apply_poll([_snapshot(status=DaemonStatus.STOPPED)])
    model.pin("PRJ-001", DaemonStatus.STARTING, ttl_seconds=15.0)

    model.apply_poll([_snapshot(status=DaemonStatus.RUNNING, pids=[1, 2])])

    assert model.snapshot_for("PRJ-001").status is DaemonStatus.RUNNING
    assert model.pinned_status("PRJ-001") is None


@pytest.mark.parametrize("observed", [DaemonStatus.STOPPED, DaemonStatus.STALE_LOCK])
def test_draining_pin_resolves_on_observed_exit(fake_clock, observed):
    """UNIT-M6: DRAINING clears on any observed exit — a left-behind lock counts."""
    model = AppModel(clock=fake_clock)
    model.apply_poll([_snapshot(status=DaemonStatus.RUNNING, pids=[1])])
    model.pin("PRJ-001", DaemonStatus.DRAINING, ttl_seconds=25.0)

    model.apply_poll([_snapshot(status=observed)])

    assert model.snapshot_for("PRJ-001").status is observed
    assert model.pinned_status("PRJ-001") is None


def test_clear_pin_releases_the_row_immediately(fake_clock):
    """UNIT-M6 (edge): a worker resolving its own action releases the pin at once."""
    model = AppModel(clock=fake_clock)
    model.apply_poll([_snapshot(status=DaemonStatus.RUNNING, pids=[1])])
    model.pin("PRJ-001", DaemonStatus.DRAINING, ttl_seconds=25.0)

    model.clear_pin("PRJ-001")

    assert model.snapshot_for("PRJ-001").status is DaemonStatus.RUNNING


def test_pin_for_a_vanished_project_is_discarded(fake_clock):
    """A pin cannot outlive its project — a dropped row takes its pin with it."""
    model = AppModel(clock=fake_clock)
    model.apply_poll([_snapshot("PRJ-001", DaemonStatus.RUNNING, [1])])
    model.pin("PRJ-001", DaemonStatus.DRAINING, ttl_seconds=25.0)

    model.apply_poll([_snapshot("PRJ-002")])

    assert model.pinned_status("PRJ-001") is None


# --------------------------------------------------------------------------- #
# UNIT-M7 — Shutdown mode
# --------------------------------------------------------------------------- #
def test_shutting_down_is_reflected_to_subscribers(fake_clock):
    """UNIT-M7: entering shutdown mode is a model change subscribers see."""
    model = AppModel(clock=fake_clock)
    recorder = Recorder()
    model.subscribe(recorder)

    model.set_shutting_down(True)

    assert model.shutting_down is True
    assert recorder.calls == 1


def test_setting_shutting_down_twice_is_idempotent(fake_clock):
    """UNIT-M7 (edge): re-setting the same value notifies nobody."""
    model = AppModel(clock=fake_clock)
    model.set_shutting_down(True)
    recorder = Recorder()
    model.subscribe(recorder)

    model.set_shutting_down(True)

    assert recorder.calls == 0


def test_validation_state_change_notifies(fake_clock):
    """A per-project validation result is model state and repaints its pane (Phase E)."""
    model = AppModel(clock=fake_clock)
    model.apply_poll([_snapshot()])
    recorder = Recorder()
    model.subscribe(recorder)

    model.set_validation("PRJ-001", ValidationRun(state="running"))

    assert recorder.calls == 1
    assert model.validation["PRJ-001"].state == "running"
