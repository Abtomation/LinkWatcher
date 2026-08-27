"""
Document Metadata:
ID: TE-TST-146
Type: Test File
Category: Test
Version: 1.1
Created: 2026-08-10
Updated: 2026-08-25
Component Name: lifecycle
Feature Id: 7.1.1
Language: Python
Test Name: panel_lifecycle
Test Type: Unit
"""

# Unit tests for Control Panel lifecycle actions
# (``linkwatcher.linkwatcher_control_panel.lifecycle``), per TE-TSP-045:
#
# - start via the project's own launcher: success / idempotent / failure /
#   timeout / missing script (UNIT-L1…L3)
# - drain state machine with fake clock + fake log-stat source — quiescence,
#   grace timeout, rotation-safe watch, no-log shortcut (UNIT-L4…L7)
# - guarded pair termination — the kill-time identity re-check is the single
#   most important test target in the feature (UNIT-L8/L9)
# - self-owned lock cleanup (UNIT-L10/L11)
# - correlation-aware quiescence: a buffered move-correlation is invisible in the
#   log signature, so the drain widens its idle requirement to the project's own
#   move_detect_delay (UNIT-L16, PD-BUG-136)
# - lock cleanup under a concurrent holder: Windows blocks the unlink while any
#   handle is open, so the delete backs off and a lock that is ours and still
#   undeletable is surfaced rather than swallowed (UNIT-L17, PD-BUG-137)
# - LifecycleController pin/outcome orchestration and the one-action-per-project
#   busy guard (supports INT-3/INT-4 pipelines in test_panel_integration.py)
#
# No real process is ever spawned, terminated, or waited on: the process table,
# terminator, launcher runner, clock, sleep, and log-stat source are all fakes
# from the local conftest.

import os
import tempfile
from pathlib import Path

import pytest

from linkwatcher.config import LinkWatcherConfig
from linkwatcher.linkwatcher_control_panel.discovery import LOCK_FILE_NAME
from linkwatcher.linkwatcher_control_panel.lifecycle import (
    CORRELATION_GRACE_HEADROOM_SECONDS,
    DRAIN_PIN_MARGIN_SECONDS,
    EXIT_WAIT_TIMEOUT_SECONDS,
    LAUNCHER_TIMEOUT_SECONDS,
    LifecycleController,
    LogStat,
    RunResult,
    _sweep_stale_captures,
    cleanup_lock,
    drain_and_terminate,
    launcher_path,
    newest_log_stat,
    read_correlation_window,
    resolve_shell,
    run_launcher,
    terminate_project_daemon,
    watch_quiescence,
)
from linkwatcher.linkwatcher_control_panel.model import AppModel, DaemonSnapshot, DaemonStatus

pytestmark = [
    pytest.mark.feature("7.1.1"),
    pytest.mark.priority("Critical"),
    pytest.mark.test_type("unit"),
    pytest.mark.specification("TE-TSP-045"),
]


def make_controller(model, fake_process_table, fake_runner, fake_terminator, fake_clock, log_stat):
    """A controller wired for synchronous, deterministic unit testing.

    ``post`` executes immediately (single-threaded test), ``executor`` runs the
    worker inline, and ``sleep`` advances the fake clock instead of waiting.
    """
    return LifecycleController(
        model=model,
        post=lambda callback: callback(),
        process_table=fake_process_table,
        grace_period_seconds=20.0,
        log_idle_threshold_seconds=3.0,
        runner=fake_runner,
        terminator=fake_terminator,
        clock=fake_clock,
        sleep=fake_clock.advance,
        log_stat=log_stat,
        executor=lambda fn: fn(),
    )


def seed_model(project, status, pids=(), clock=None):
    """An AppModel already holding one poll snapshot for *project*."""
    model = AppModel(clock=clock) if clock is not None else AppModel()
    model.apply_poll([DaemonSnapshot(project, status, list(pids))])
    return model


# --------------------------------------------------------------------------- #
# UNIT-L1 — Start success
# --------------------------------------------------------------------------- #
def test_start_invokes_projects_own_launcher(make_project, write_launcher, fake_runner):
    """UNIT-L1: the launcher invoked is the *project's own* script, via -File (D-T4)."""
    project = make_project()
    script = write_launcher(project)

    outcome = run_launcher(project, fake_runner)

    assert outcome.ok
    args, timeout = fake_runner.calls[0]
    assert str(script) in args
    assert "-File" in args
    assert timeout == LAUNCHER_TIMEOUT_SECONDS
    assert launcher_path(project.root) == script


def test_start_success_pins_starting(
    make_project, write_launcher, fake_process_table, fake_runner, fake_terminator, fake_clock
):
    """UNIT-L1: exit 0 → the row is pinned STARTING until the poll observes the pair."""
    project = make_project()
    write_launcher(project)
    model = seed_model(project, DaemonStatus.STOPPED, clock=fake_clock)
    controller = make_controller(
        model, fake_process_table, fake_runner, fake_terminator, fake_clock, lambda d: None
    )

    assert controller.start("PRJ-001") is True

    assert model.snapshot_for("PRJ-001").status is DaemonStatus.STARTING
    assert len(fake_runner.calls) == 1


# --------------------------------------------------------------------------- #
# UNIT-L2 — Start idempotent (EC-2/AC-10)
# --------------------------------------------------------------------------- #
def test_start_already_running_is_idempotent_success(
    make_project, write_launcher, fake_process_table, fake_runner, fake_terminator, fake_clock
):
    """UNIT-L2: launcher exit 0 on already-running is success, and the poll resolves it."""
    project = make_project()
    write_launcher(project)
    fake_runner.script(
        RunResult(0, "LinkWatcher is already running for X (PID: 123)\nNot starting.", "")
    )
    model = seed_model(project, DaemonStatus.STOPPED, clock=fake_clock)
    controller = make_controller(
        model, fake_process_table, fake_runner, fake_terminator, fake_clock, lambda d: None
    )

    assert controller.start("PRJ-001") is True
    assert model.snapshot_for("PRJ-001").status is DaemonStatus.STARTING  # not an error

    # The next poll observes the running pair — the STARTING pin resolves.
    model.apply_poll([DaemonSnapshot(project, DaemonStatus.RUNNING, [700, 701], 100.0)])
    assert model.snapshot_for("PRJ-001").status is DaemonStatus.RUNNING
    assert len(fake_runner.calls) == 1  # no second start


# --------------------------------------------------------------------------- #
# UNIT-L3 — Start failure (EC-7)
# --------------------------------------------------------------------------- #
def test_start_failure_surfaces_stderr_reason(
    make_project, write_launcher, fake_process_table, fake_runner, fake_terminator, fake_clock
):
    """UNIT-L3: exit 1 → START_FAILED with the captured stderr as the reason."""
    project = make_project()
    write_launcher(project)
    fake_runner.script(RunResult(1, "", "config missing for project"))
    model = seed_model(project, DaemonStatus.STOPPED, clock=fake_clock)
    controller = make_controller(
        model, fake_process_table, fake_runner, fake_terminator, fake_clock, lambda d: None
    )

    controller.start("PRJ-001")

    row = model.snapshot_for("PRJ-001")
    assert row.status is DaemonStatus.START_FAILED
    assert "config missing for project" in row.detail


def test_start_failure_reason_falls_back_to_stdout(
    make_project, write_launcher, fake_process_table, fake_runner, fake_terminator, fake_clock
):
    """UNIT-L3: the launcher reports via Write-Host (stdout) — empty stderr must not
    produce an empty reason."""
    project = make_project()
    write_launcher(project)
    fake_runner.script(
        RunResult(
            1,
            "Starting LinkWatcher in background...\n"
            "Error: LinkWatcher process exited immediately (exit code: 1)",
            "",
        )
    )
    model = seed_model(project, DaemonStatus.STOPPED, clock=fake_clock)
    controller = make_controller(
        model, fake_process_table, fake_runner, fake_terminator, fake_clock, lambda d: None
    )

    controller.start("PRJ-001")

    row = model.snapshot_for("PRJ-001")
    assert row.status is DaemonStatus.START_FAILED
    assert "exited immediately" in row.detail


def test_start_timeout_surfaces_reason(
    make_project, write_launcher, fake_process_table, fake_runner, fake_terminator, fake_clock
):
    """UNIT-L3 edge: a hung launcher is bounded and surfaced, never waited on forever."""
    project = make_project()
    write_launcher(project)
    fake_runner.script(RunResult(None, "", "", timed_out=True))
    model = seed_model(project, DaemonStatus.STOPPED, clock=fake_clock)
    controller = make_controller(
        model, fake_process_table, fake_runner, fake_terminator, fake_clock, lambda d: None
    )

    controller.start("PRJ-001")

    row = model.snapshot_for("PRJ-001")
    assert row.status is DaemonStatus.START_FAILED
    assert "did not finish" in row.detail


def test_start_missing_launcher_script_fails_without_spawning(
    make_project, fake_process_table, fake_runner, fake_terminator, fake_clock
):
    """UNIT-L3 edge: no launcher script → surfaced failure, nothing invoked."""
    project = make_project()  # root exists, but no process-framework/ inside
    model = seed_model(project, DaemonStatus.STOPPED, clock=fake_clock)
    controller = make_controller(
        model, fake_process_table, fake_runner, fake_terminator, fake_clock, lambda d: None
    )

    controller.start("PRJ-001")

    row = model.snapshot_for("PRJ-001")
    assert row.status is DaemonStatus.START_FAILED
    assert "not found" in row.detail
    assert fake_runner.calls == []


# --------------------------------------------------------------------------- #
# UNIT-L4 / UNIT-L5 — Drain quiescence and grace timeout
# --------------------------------------------------------------------------- #
def test_drain_quiescent_after_idle_threshold(tmp_path, fake_clock, fake_log_stat):
    """UNIT-L4: a log silent for the idle threshold means the daemon is quiescent."""
    quiescent = watch_quiescence(
        tmp_path,
        idle_threshold=3.0,
        grace_period=20.0,
        correlation_window=0.0,  # base idle/grace mechanics; correlations covered by UNIT-L16
        clock=fake_clock,
        sleep=fake_clock.advance,
        log_stat=fake_log_stat,
    )

    assert quiescent is True
    assert fake_clock.now == pytest.approx(3.0, abs=0.5)


def test_drain_forces_at_grace_period_when_log_stays_active(tmp_path, fake_clock, fake_log_stat):
    """UNIT-L5: a log that never goes quiet bounds the drain at the grace period."""

    def busy_sleep(seconds):
        fake_clock.advance(seconds)
        fake_log_stat.touch()  # activity on every check

    quiescent = watch_quiescence(
        tmp_path,
        idle_threshold=3.0,
        grace_period=20.0,
        correlation_window=0.0,  # base idle/grace mechanics; correlations covered by UNIT-L16
        clock=fake_clock,
        sleep=busy_sleep,
        log_stat=fake_log_stat,
    )

    assert quiescent is False
    assert fake_clock.now == pytest.approx(20.0, abs=0.5)


# --------------------------------------------------------------------------- #
# UNIT-L6 — Rotation-safe watch (real files)
# --------------------------------------------------------------------------- #
def test_newest_log_stat_picks_newest_sibling(tmp_path):
    """UNIT-L6: the watcher targets the newest LinkWatcherLog*.txt by mtime."""
    rotated = tmp_path / "LinkWatcherLog_20260809_2200.txt"
    rotated.write_text("rotated", encoding="utf-8")
    active = tmp_path / "LinkWatcherLog.txt"
    active.write_text("active", encoding="utf-8")
    os.utime(rotated, (1000, 1000))
    os.utime(active, (2000, 2000))

    stat = newest_log_stat(tmp_path)

    assert stat is not None
    assert stat.path == active


def test_drain_watcher_survives_mid_drain_rotation(tmp_path, fake_clock):
    """UNIT-L6: the active log renamed mid-drain → the watcher retargets the newest
    file; the rotation registers as activity, then quiet means quiescent."""
    active = tmp_path / "LinkWatcherLog.txt"
    active.write_text("active", encoding="utf-8")
    os.utime(active, (1000, 1000))
    state = {"sleeps": 0}

    def rotating_sleep(seconds):
        fake_clock.advance(seconds)
        state["sleeps"] += 1
        if state["sleeps"] == 4:  # ~1 s in: rotation happens
            active.rename(tmp_path / "LinkWatcherLog_20260810_1100.txt")
            fresh = tmp_path / "LinkWatcherLog.txt"
            fresh.write_text("fresh", encoding="utf-8")
            os.utime(fresh, (2000, 2000))

    quiescent = watch_quiescence(
        tmp_path,
        idle_threshold=3.0,
        grace_period=20.0,
        correlation_window=0.0,  # base idle/grace mechanics; correlations covered by UNIT-L16
        clock=fake_clock,
        sleep=rotating_sleep,
        log_stat=newest_log_stat,
    )

    assert quiescent is True
    # Idle window restarted at the rotation (~1 s), so quiescence lands ~4 s.
    assert fake_clock.now == pytest.approx(4.0, abs=0.6)
    assert newest_log_stat(tmp_path).path == tmp_path / "LinkWatcherLog.txt"


# --------------------------------------------------------------------------- #
# UNIT-L7 — No log file
# --------------------------------------------------------------------------- #
def test_no_log_file_is_quiescent_immediately(tmp_path, fake_clock):
    """UNIT-L7: a project with no log at all must not wait the grace period on nothing."""
    quiescent = watch_quiescence(
        tmp_path,
        idle_threshold=3.0,
        grace_period=20.0,
        correlation_window=0.0,  # base idle/grace mechanics; correlations covered by UNIT-L16
        clock=fake_clock,
        sleep=fake_clock.advance,
        log_stat=newest_log_stat,
    )

    assert quiescent is True
    assert fake_clock.now == 0.0  # decided without a single wait


# --------------------------------------------------------------------------- #
# UNIT-L8 — Terminate targets the pair, nothing else
# --------------------------------------------------------------------------- #
def test_terminate_targets_whole_pair_and_nothing_else(
    make_project, fake_process_table, fake_terminator, daemons
):
    """UNIT-L8: both PIDs of the verified pair are terminated; unrelated PIDs untouched."""
    project = make_project()
    fake_process_table.set_entries(
        daemons.pair(project.root, parent_pid=2000, child_pid=2001) + [daemons.unrelated(pid=4242)]
    )

    terminated = terminate_project_daemon(project, fake_process_table, fake_terminator)

    assert terminated == [2000, 2001]
    assert fake_terminator.terminated == [2000, 2001]
    assert 4242 not in fake_terminator.terminated


# --------------------------------------------------------------------------- #
# UNIT-L9 — The termination guard (highest-value test in the feature)
# --------------------------------------------------------------------------- #
def test_termination_guard_refuses_recycled_pid(
    make_project, fake_process_table, fake_terminator, daemons
):
    """UNIT-L9: a PID recycled between poll and action fails the kill-time identity
    re-check and is never terminated (D-T5)."""
    project = make_project()
    # Poll time believed PID 2000 was the daemon; by kill time 2000 is notepad.
    fake_process_table.set_entries([daemons.unrelated(pid=2000)])

    terminated = terminate_project_daemon(project, fake_process_table, fake_terminator)

    assert terminated == []
    assert fake_terminator.terminated == []


def test_termination_guard_refuses_wrong_project_daemon(
    make_project, fake_process_table, fake_terminator, daemons, tmp_path
):
    """UNIT-L9: a live LinkWatcher daemon for a *different* root is never this
    project's kill target."""
    project = make_project()
    other_root = tmp_path / "other-project"
    fake_process_table.set_entries(daemons.pair(other_root, parent_pid=3000, child_pid=3001))

    terminated = terminate_project_daemon(project, fake_process_table, fake_terminator)

    assert terminated == []
    assert fake_terminator.terminated == []


def test_drain_pipeline_reports_nothing_performed_when_guard_refuses(
    make_project, fake_process_table, fake_terminator, fake_clock, fake_log_stat, daemons
):
    """UNIT-L9: the full stop pipeline surfaces a guard refusal as performed=False."""
    project = make_project()
    fake_process_table.set_entries([daemons.unrelated(pid=2000)])

    outcome = drain_and_terminate(
        project,
        idle_threshold=3.0,
        grace_period=20.0,
        process_table=fake_process_table,
        terminator=fake_terminator,
        clock=fake_clock,
        sleep=fake_clock.advance,
        log_stat=fake_log_stat,
    )

    assert outcome.performed is False
    assert outcome.terminated == ()
    assert fake_terminator.terminated == []


# --------------------------------------------------------------------------- #
# UNIT-L10 / UNIT-L11 — Self-owned lock cleanup
# --------------------------------------------------------------------------- #
def test_lock_deleted_only_when_it_names_terminated_pid(make_project, write_lock):
    """UNIT-L10: after confirmed exit the lock is deleted iff it holds a terminated PID."""
    project = make_project()
    write_lock(project, 2001)

    assert cleanup_lock(project.root, [2000, 2001]) is True
    assert not (project.root / LOCK_FILE_NAME).exists()


def test_foreign_lock_left_intact(make_project, write_lock):
    """UNIT-L11: a lock now holding a different PID belongs to a successor — untouched."""
    project = make_project()
    lock = write_lock(project, 9999)

    assert cleanup_lock(project.root, [2000, 2001]) is False
    assert lock.exists()


def test_corrupt_lock_left_intact(make_project, write_lock):
    """UNIT-L11 edge: unreadable lock content is never deleted here (discovery
    surfaces it as STALE_LOCK instead)."""
    project = make_project()
    lock = write_lock(project, "not-a-pid")

    assert cleanup_lock(project.root, [2000, 2001]) is False
    assert lock.exists()


def test_missing_lock_is_a_calm_noop(make_project):
    """UNIT-L10 edge: no lock file → nothing to clean, no error."""
    project = make_project()

    assert cleanup_lock(project.root, [2000, 2001]) is False


# --------------------------------------------------------------------------- #
# UNIT-L17 — Lock cleanup survives the panel racing itself (PD-BUG-137)
# --------------------------------------------------------------------------- #
# The poller reads every project's lock file each cycle (`read_lock_pid` ->
# `Path.read_text`) and keeps running throughout shutdown; the stop worker
# unlinks that same file on another thread.  Windows opens without
# FILE_SHARE_DELETE, so an overlap fails the unlink with PermissionError
# (WinError 32) — measured at 208/300 attempts under a concurrent reader.  A
# single unlink attempt therefore loses a real race, and swallowing the error
# into a bare False left the panel logging `lock_removed=False` with no way to
# tell a lost race from a deliberately untouched foreign lock.
def _flaky_unlink(failures: int):
    """A ``Path.unlink`` replacement that raises WinError 32 the first *n* times.

    Deliberately a plain function, not a callable instance: only a function is a
    descriptor, so only a function binds as a method when assigned to ``Path``.
    A callable object assigned there is invoked with no ``self`` at all.
    """
    real_unlink = Path.unlink
    state = {"remaining": failures, "calls": 0}

    def unlink(self, *args, **kwargs):
        state["calls"] += 1
        if state["remaining"] > 0:
            state["remaining"] -= 1
            raise PermissionError(
                32, "The process cannot access the file because it is being used by another process"
            )
        return real_unlink(self, *args, **kwargs)

    return unlink, state


def test_lock_cleanup_retries_a_transient_sharing_violation(make_project, write_lock, monkeypatch):
    """UNIT-L17: a poll read that briefly blocks the unlink must not cost the cleanup.

    Discriminating condition: the unlink fails twice and then succeeds. A single
    attempt returns False here and leaves the lock on disk — the PD-BUG-137
    defect — so this passes only if the retry is real.
    """
    project = make_project()
    lock = write_lock(project, 2001)
    unlink, state = _flaky_unlink(2)
    monkeypatch.setattr(Path, "unlink", unlink)

    removed = cleanup_lock(project.root, [2000, 2001], sleep=lambda _s: None)

    assert removed is True, "a transient sharing violation must not defeat cleanup"
    assert state["calls"] == 3, "expected two failures then a successful unlink"
    assert not lock.exists()


def test_lock_cleanup_reports_a_persistent_unlink_failure(
    make_project, write_lock, monkeypatch, panel_log_capture
):
    """UNIT-L17: a lock that is ours and still will not delete must say why.

    Discriminating condition: pre-fix this returned a bare False identical to the
    foreign-lock and no-lock outcomes, which is exactly why the original incident
    could not be diagnosed from the panel log.
    """
    project = make_project()
    lock = write_lock(project, 2001)
    unlink, _state = _flaky_unlink(99)
    monkeypatch.setattr(Path, "unlink", unlink)

    removed = cleanup_lock(project.root, [2000, 2001], sleep=lambda _s: None)

    assert removed is False
    assert lock.exists()
    warnings = [r for r in panel_log_capture.records if r.levelno >= 30]
    assert warnings, "a lock we own that will not delete must be surfaced, not swallowed"
    text = " ".join(r.getMessage() for r in warnings)
    assert "lock" in text.lower()
    assert "another process" in text, "the underlying OS error must reach the operator"


@pytest.mark.parametrize(
    "lock_pid, case",
    [(9999, "foreign lock — a successor owns it"), ("not-a-pid", "corrupt lock")],
)
def test_lock_cleanup_stays_silent_on_deliberately_untouched_locks(
    make_project, write_lock, panel_log_capture, lock_pid, case
):
    """UNIT-L17 guard: the benign non-removals are correct outcomes, not incidents.

    Discriminating condition: warning on every False would make a normal panel
    close noisy and bury the one case that matters.
    """
    project = make_project()
    lock = write_lock(project, lock_pid)

    assert cleanup_lock(project.root, [2000, 2001]) is False
    assert lock.exists()
    assert not [
        r for r in panel_log_capture.records if r.levelno >= 30
    ], f"{case} is a deliberate outcome and must not warn"


def test_lock_cleanup_stays_silent_when_there_is_no_lock(make_project, panel_log_capture):
    """UNIT-L17 guard: the commonest clean-stop shape must not warn."""
    project = make_project()

    assert cleanup_lock(project.root, [2000, 2001]) is False
    assert not [r for r in panel_log_capture.records if r.levelno >= 30]


# --------------------------------------------------------------------------- #
# Controller stop orchestration (drives INT-4's building blocks)
# --------------------------------------------------------------------------- #
def test_stop_clean_path_terminates_pair_and_cleans_lock(
    make_project,
    write_lock,
    fake_process_table,
    fake_runner,
    fake_terminator,
    fake_clock,
    fake_log_stat,
    daemons,
):
    """Clean stop: drain quiesces → pair terminated → own lock removed → the
    DRAINING pin resolves when the poll observes the exit (no RUNNING flicker)."""
    project = make_project()
    fake_process_table.set_entries(daemons.pair(project.root, parent_pid=900, child_pid=901))
    write_lock(project, 900)
    model = seed_model(project, DaemonStatus.RUNNING, pids=[900, 901], clock=fake_clock)
    controller = make_controller(
        model, fake_process_table, fake_runner, fake_terminator, fake_clock, fake_log_stat
    )

    assert controller.stop("PRJ-001") is True

    assert fake_terminator.terminated == [900, 901]
    assert not (project.root / LOCK_FILE_NAME).exists()
    # Worker left the DRAINING pin in place; the poll observing STOPPED resolves it.
    assert model.snapshot_for("PRJ-001").status is DaemonStatus.DRAINING
    model.apply_poll([DaemonSnapshot(project, DaemonStatus.STOPPED, [])])
    assert model.snapshot_for("PRJ-001").status is DaemonStatus.STOPPED


def test_stop_grace_timeout_surfaces_force_stopped(
    make_project,
    write_lock,
    fake_process_table,
    fake_runner,
    fake_terminator,
    fake_clock,
    fake_log_stat,
    daemons,
):
    """EC-4/AC-9: a never-quiet log forces termination at the grace bound, and the
    forced outcome is pinned visibly — never silent."""
    project = make_project()
    fake_process_table.set_entries(daemons.pair(project.root, parent_pid=910, child_pid=911))
    write_lock(project, 910)
    model = seed_model(project, DaemonStatus.RUNNING, pids=[910, 911], clock=fake_clock)

    def busy_sleep(seconds):
        fake_clock.advance(seconds)
        fake_log_stat.touch()  # the log never goes quiet

    controller = LifecycleController(
        model=model,
        post=lambda callback: callback(),
        process_table=fake_process_table,
        grace_period_seconds=20.0,
        log_idle_threshold_seconds=3.0,
        runner=fake_runner,
        terminator=fake_terminator,
        clock=fake_clock,
        sleep=busy_sleep,
        log_stat=fake_log_stat,
        executor=lambda fn: fn(),
    )

    assert controller.stop("PRJ-001") is True

    row = model.snapshot_for("PRJ-001")
    assert row.status is DaemonStatus.FORCE_STOPPED
    assert "Force-stopped" in row.detail
    assert fake_terminator.terminated == [910, 911]


def test_stop_noop_releases_row_to_poll_truth(
    make_project,
    fake_process_table,
    fake_runner,
    fake_terminator,
    fake_clock,
    fake_log_stat,
    daemons,
):
    """Guard refusal at kill time clears the DRAINING pin — the row falls back to truth."""
    project = make_project()
    fake_process_table.set_entries([daemons.unrelated(pid=920)])
    model = seed_model(project, DaemonStatus.RUNNING, pids=[920], clock=fake_clock)
    controller = make_controller(
        model, fake_process_table, fake_runner, fake_terminator, fake_clock, fake_log_stat
    )

    assert controller.stop("PRJ-001") is True

    assert fake_terminator.terminated == []
    # Pin cleared: the effective status is the (stale) poll truth again.
    assert model.snapshot_for("PRJ-001").status is DaemonStatus.RUNNING


# --------------------------------------------------------------------------- #
# Controller busy guard
# --------------------------------------------------------------------------- #
def test_second_action_rejected_while_first_in_flight(
    make_project, write_launcher, fake_process_table, fake_runner, fake_terminator, fake_clock
):
    """One action per project at a time — the backstop behind toolbar disablement."""
    project = make_project()
    write_launcher(project)
    model = seed_model(project, DaemonStatus.STOPPED, clock=fake_clock)
    pending = []
    controller = LifecycleController(
        model=model,
        post=lambda callback: callback(),
        process_table=fake_process_table,
        grace_period_seconds=20.0,
        log_idle_threshold_seconds=3.0,
        runner=fake_runner,
        terminator=fake_terminator,
        clock=fake_clock,
        sleep=fake_clock.advance,
        log_stat=lambda d: None,
        executor=pending.append,  # defer the worker: the action stays in flight
    )

    assert controller.start("PRJ-001") is True
    assert controller.is_busy("PRJ-001") is True
    assert controller.start("PRJ-001") is False  # rejected while in flight
    assert controller.stop("PRJ-001") is False

    for worker in pending:
        worker()  # complete the first action

    assert controller.is_busy("PRJ-001") is False
    assert controller.start("PRJ-001") is True


def test_unknown_project_is_rejected(
    make_project, fake_process_table, fake_runner, fake_terminator, fake_clock
):
    """Actions on a project the model does not list are refused outright."""
    project = make_project()
    model = seed_model(project, DaemonStatus.STOPPED, clock=fake_clock)
    controller = make_controller(
        model, fake_process_table, fake_runner, fake_terminator, fake_clock, lambda d: None
    )

    assert controller.start("PRJ-404") is False
    assert controller.stop("PRJ-404") is False
    assert fake_runner.calls == []


# --------------------------------------------------------------------------- #
# CR-8 / CR-9 / CR-12 + TD263 — Code Review 2026-08-17, session 2
# --------------------------------------------------------------------------- #
def test_draining_pin_outlives_the_stop_worker_worst_case():
    """CR-8: the pin must not expire while its own worker can still be running.

    The stop worker's worst case is the full grace period in `watch_quiescence`
    followed by `wait_for_exit` (EXIT_WAIT_TIMEOUT_SECONDS). The DRAINING pin
    used to carry a 5 s margin, expiring at grace + 5 s — so for the last 5 s of
    a slow stop the row reverted to poll truth (Running) and re-enabled a Stop
    button whose click the controller's busy guard then swallowed.

    Discriminating condition: restore a margin below the exit wait and this
    fails for every grace period.
    """
    for grace in (5.0, 20.0, 60.0):
        pin_ttl = grace + DRAIN_PIN_MARGIN_SECONDS
        worker_worst_case = grace + EXIT_WAIT_TIMEOUT_SECONDS
        assert pin_ttl > worker_worst_case, f"pin expires mid-stop at grace={grace}"


def test_launcher_shell_is_resolved_absolutely(tmp_path, monkeypatch):
    """CR-9: the current directory must never supply the launcher shell.

    Windows CreateProcess searches the working directory before PATH, so a bare
    "pwsh.exe" runs whatever sits there. `shutil.which` is not a fix — it
    unconditionally prepends os.curdir on Windows, returning the decoy even when
    given an explicit path=.

    Discriminating condition: resolve via the current directory (or via
    shutil.which) and the decoy below is selected.
    """
    decoy_dir = tmp_path / "cwd"
    decoy_dir.mkdir()
    (decoy_dir / "pwsh.exe").write_bytes(b"MZ")
    real_dir = tmp_path / "tools"
    real_dir.mkdir()
    real_shell = real_dir / "pwsh.exe"
    real_shell.write_bytes(b"MZ")
    monkeypatch.chdir(decoy_dir)

    resolved = resolve_shell(env={"PATH": str(real_dir)})

    assert Path(resolved) == real_shell
    assert Path(resolved).parent != decoy_dir


@pytest.mark.parametrize("path_value", ["", ".", f".{os.pathsep}..", "relative/dir"])
def test_launcher_shell_falls_back_rather_than_failing(path_value):
    """CR-9 guard rail: an unresolvable PATH degrades, it does not raise.

    Every entry here is relative and must be skipped; a machine with no absolute
    pwsh on PATH keeps working exactly as before rather than losing Start.
    """
    assert resolve_shell(env={"PATH": path_value}) == "pwsh.exe"


def test_stale_launcher_captures_are_swept(tmp_path, monkeypatch):
    """CR-12: capture files left by earlier runs are removed, bounding the leak.

    Every successful Start leaked a pair: the spawned daemon inherits the handle
    and the CRT opens without FILE_SHARE_DELETE, so the `finally` unlink fails
    and is swallowed. Files nearly eight days old were measured still present,
    contradicting the "cleaned up by the OS" comment that justified ignoring it.

    Discriminating condition: remove the sweep and the aged files below survive.
    """
    monkeypatch.setattr(tempfile, "gettempdir", lambda: str(tmp_path))
    aged_out = tmp_path / "lw-panel-out-aged.txt"
    aged_err = tmp_path / "lw-panel-err-aged.txt"
    unrelated = tmp_path / "someone-elses-file.txt"
    for f in (aged_out, aged_err, unrelated):
        f.write_text("x", encoding="utf-8")
        os.utime(f, (0, 0))  # epoch — far older than the max age

    removed = _sweep_stale_captures()

    assert removed == 2
    assert not aged_out.exists() and not aged_err.exists()
    assert unrelated.exists(), "the sweep must only touch its own capture prefixes"


def test_sweep_never_touches_an_in_flight_capture(tmp_path, monkeypatch):
    """CR-12 guard rail: a capture belonging to a start in progress must survive.

    Discriminating condition: sweep by prefix alone (ignoring age) and this file
    — the shape of a capture whose launcher is still running — is deleted out
    from under the run that owns it.
    """
    monkeypatch.setattr(tempfile, "gettempdir", lambda: str(tmp_path))
    fresh = tmp_path / "lw-panel-out-fresh.txt"
    fresh.write_text("in flight", encoding="utf-8")

    removed = _sweep_stale_captures()

    assert removed == 0
    assert fresh.exists()


def test_unconfirmed_exit_is_reported_when_the_daemon_does_not_die(
    make_project,
    write_lock,
    fake_process_table,
    fake_terminator,
    fake_clock,
    fake_log_stat,
    daemons,
):
    """TD263: the exit-confirmation timeout branch, previously unreachable.

    `FakeTerminator` removes the PID from the table synchronously, so every
    existing test made `wait_for_exit` return True immediately and neither its
    timeout branch nor the `daemon_exit_unconfirmed` warning ever executed
    (TE-TAR-090). An unlinked terminator reproduces a process that ignores
    termination: the wait must time out, the outcome must say so, and the lock
    must be left alone because the daemon may still be using it.
    """
    project = make_project()
    fake_process_table.set_entries([daemons.entry(4242, str(project.root), create_time=1.0)])
    write_lock(project, 4242)
    # TD263's condition: the terminator records the kill but the process does not
    # leave the table, so wait_for_exit has something to actually time out on.
    fake_terminator.table = None
    stubborn = fake_terminator

    outcome = drain_and_terminate(
        project,
        idle_threshold=3.0,
        grace_period=20.0,
        process_table=fake_process_table,
        terminator=stubborn,
        clock=fake_clock,
        sleep=fake_clock.advance,
        log_stat=fake_log_stat,
    )

    assert stubborn.terminated == [4242]
    assert outcome.performed is True
    assert outcome.exited is False, "wait_for_exit must report the timeout"
    assert outcome.lock_removed is False, "a lock is never removed on an unconfirmed exit"
    assert (project.root / LOCK_FILE_NAME).exists()


# --------------------------------------------------------------------------- #
# UNIT-L16 — Correlation-aware drain (PD-BUG-136)
# --------------------------------------------------------------------------- #
# A daemon holding a *buffered move-correlation* — a DELETE waiting up to
# `move_detect_delay` for its matching CREATE — writes nothing while it waits, so
# its (path, size, mtime) log signature is byte-for-byte identical to an idle
# daemon's.  Judging quiescence by that signature alone terminated the daemon
# after `log_idle_threshold_seconds` (3 s) while the correlation window (10 s)
# was still open, dropping the reference update FDD 7-1-1-BR-3 requires the drain
# to let finish.  The drain must therefore wait out the correlation window when
# the daemon has logged recently enough for one to still be pending.
def _log_written_at(mtime: float) -> LogStat:
    """A log signature whose mtime is *mtime* (wall clock, as ``st_mtime`` is)."""
    return LogStat(Path("LinkWatcherLog.txt"), size=100, mtime=mtime)


def test_drain_waits_out_correlation_window_when_daemon_logged_recently(
    tmp_path, fake_clock, fake_log_stat
):
    """UNIT-L16: a log that went quiet moments ago may be a buffered correlation,
    not an idle daemon — the drain must hold for the correlation window.

    Discriminating condition: the log signature never changes, so the pre-fix
    quiescence rule (silence >= idle_threshold) resolves at 3 s.  Only a rule
    that also accounts for the correlation window reaches 10 s.
    """
    fake_log_stat.current = _log_written_at(1000.0)

    quiescent = watch_quiescence(
        tmp_path,
        idle_threshold=3.0,
        grace_period=20.0,
        correlation_window=10.0,
        clock=fake_clock,
        sleep=fake_clock.advance,
        log_stat=fake_log_stat,
        wall_clock=lambda: 1000.0,  # the log was written "just now"
    )

    assert quiescent is True, "a quiet daemon still drains cleanly, just later"
    assert fake_clock.now != pytest.approx(
        3.0, abs=0.5
    ), "terminating at the log-idle threshold is the PD-BUG-136 defect"
    assert fake_clock.now == pytest.approx(10.0, abs=0.5)


def test_drain_keeps_short_idle_path_when_log_is_older_than_the_window(
    tmp_path, fake_clock, fake_log_stat
):
    """UNIT-L16: silence already longer than the correlation window proves nothing
    is pending — a buffered delete expires exactly `move_detect_delay` after the
    `file_deleted` record that created it — so the fast path is kept.

    Discriminating condition: same call as the test above with only the log's age
    changed; a rule that always waits the window would resolve at 10 s here.
    """
    fake_log_stat.current = _log_written_at(1000.0)

    quiescent = watch_quiescence(
        tmp_path,
        idle_threshold=3.0,
        grace_period=20.0,
        correlation_window=10.0,
        clock=fake_clock,
        sleep=fake_clock.advance,
        log_stat=fake_log_stat,
        wall_clock=lambda: 1020.0,  # log last written 20 s ago — window long closed
    )

    assert quiescent is True
    assert fake_clock.now == pytest.approx(3.0, abs=0.5)


def test_correlation_window_is_clamped_to_stay_inside_the_grace_period(
    tmp_path, fake_clock, fake_log_stat
):
    """UNIT-L16: a correlation window wider than the grace period must be clamped,
    not obeyed — BR-7 bounds the drain, and an unclamped window would turn every
    stop of such a project into a spurious forced termination.

    Discriminating condition: without the clamp the required idle (30 s) exceeds
    the grace period (20 s), so grace always wins and `quiescent` is False.
    """
    fake_log_stat.current = _log_written_at(1000.0)

    quiescent = watch_quiescence(
        tmp_path,
        idle_threshold=3.0,
        grace_period=20.0,
        correlation_window=30.0,
        clock=fake_clock,
        sleep=fake_clock.advance,
        log_stat=fake_log_stat,
        wall_clock=lambda: 1000.0,
    )

    assert quiescent is True, "a clamped window must still resolve as a clean drain"
    assert fake_clock.now == pytest.approx(20.0 - CORRELATION_GRACE_HEADROOM_SECONDS, abs=0.5)


def test_correlation_window_still_force_stops_a_log_that_never_goes_quiet(
    tmp_path, fake_clock, fake_log_stat
):
    """UNIT-L16: the window extends the wait; it must not defeat the grace bound
    (BR-7) for a daemon that genuinely keeps working."""
    fake_log_stat.current = _log_written_at(1000.0)

    def busy_sleep(seconds):
        fake_clock.advance(seconds)
        fake_log_stat.touch()

    quiescent = watch_quiescence(
        tmp_path,
        idle_threshold=3.0,
        grace_period=20.0,
        correlation_window=10.0,
        clock=fake_clock,
        sleep=busy_sleep,
        log_stat=fake_log_stat,
        wall_clock=lambda: 1000.0,
    )

    assert quiescent is False
    assert fake_clock.now == pytest.approx(20.0, abs=0.5)


def test_read_correlation_window_reads_the_projects_move_detect_delay(make_project):
    """UNIT-L16: the window is the project's own `move_detect_delay`, not a guess.

    Discriminating condition: the value written here (25) is not the daemon
    default, so returning the default would fail.
    """
    project = make_project()
    project.config_path.write_text(
        "monitored_extensions:\n  - .md\nmove_detect_delay: 25\n", encoding="utf-8"
    )

    assert read_correlation_window(project.config_path) == pytest.approx(25.0)


@pytest.mark.parametrize(
    "content",
    [
        None,  # no config file at all
        "monitored_extensions:\n  - .md\n",  # key absent
        "move_detect_delay: not-a-number\n",  # wrong type
        "move_detect_delay: -5\n",  # non-positive
        "move_detect_delay: [1, 2\n",  # unparseable YAML
        "just a bare string\n",  # valid YAML, not a mapping
    ],
)
def test_read_correlation_window_falls_back_to_the_daemon_default(make_project, content):
    """UNIT-L16: an absent, malformed, or nonsensical config must not disable the
    protection — it falls back to the daemon's own default, never to zero."""
    project = make_project()
    if content is not None:
        project.config_path.write_text(content, encoding="utf-8")

    window = read_correlation_window(project.config_path)

    assert window == pytest.approx(LinkWatcherConfig().move_detect_delay), (
        "the protective fallback must track the daemon's OWN default; comparing it to the "
        "panel's private constant is tautological with respect to drift (TD294)"
    )
    assert window > 0, "falling back to 0 would silently restore the PD-BUG-136 defect"


ENV_MOVE_DETECT_DELAY = "LINKWATCHER_MOVE_DETECT_DELAY"


@pytest.mark.parametrize(
    "file_content, env_value, expected, stale",
    [
        # PD-BUG-142 as filed: the env override raises the window above the file-derived one.
        ("monitored_extensions:\n  - .md\n", "30", 30.0, 10.0),
        # Same, where the file states the daemon default explicitly.
        ("move_detect_delay: 10\n", "30", 30.0, 10.0),
        # Same, over a non-default file value.
        ("move_detect_delay: 25\n", "30", 30.0, 25.0),
        # The direction the report did not name: an override BELOW the file value.
        ("move_detect_delay: 30\n", "5", 5.0, 30.0),
    ],
)
def test_read_correlation_window_honours_the_environment_override(
    make_project, monkeypatch, file_content, env_value, expected, stale
):
    """PD-BUG-142: the window must match the delay the daemon is ACTUALLY running with.

    ``main.py`` merges ``LinkWatcherConfig.from_env()`` OVER the file config, so a panel
    that reads only the YAML derives a different window than the daemon uses.  Where the
    panel's value is the shorter one it terminates a daemon still holding a buffered
    move-correlation and the reference update is silently dropped - PD-BUG-136 reopened.
    Where it is the longer one the drain over-waits and risks a needless FORCE_STOPPED.

    Discriminating condition: *stale* is the value the pre-fix implementation returns, and
    it differs from *expected* in every case - so the negative assertion fails against the
    old code rather than passing vacuously.
    """
    project = make_project()
    project.config_path.write_text(file_content, encoding="utf-8")
    monkeypatch.setenv(ENV_MOVE_DETECT_DELAY, env_value)

    window = read_correlation_window(project.config_path)

    assert window != pytest.approx(
        stale
    ), f"panel derived the file-only value {stale} while the daemon runs with {expected}"
    assert window == pytest.approx(expected)


def test_read_correlation_window_ignores_a_malformed_environment_override(
    make_project, monkeypatch
):
    """A junk env value must not raise and must not disable the protection.

    ``from_env`` warns and leaves the field at its default for an unparseable float, so
    the file value survives - the never-raises contract holds through the env path too.
    """
    project = make_project()
    project.config_path.write_text("move_detect_delay: 25\n", encoding="utf-8")
    monkeypatch.setenv(ENV_MOVE_DETECT_DELAY, "not-a-number")

    window = read_correlation_window(project.config_path)

    assert window == pytest.approx(25.0)
    assert window > 0, "falling back to 0 would silently restore the PD-BUG-136 defect"


def test_read_correlation_window_survives_a_broken_config_with_an_env_override(
    make_project, monkeypatch
):
    """An unreadable config must not swallow the env override.

    The pre-fix code returns the panel default here because it never consults the
    environment; the resolution path must still yield the daemon's effective value.
    """
    project = make_project()
    project.config_path.write_text("move_detect_delay: [1, 2\n", encoding="utf-8")
    monkeypatch.setenv(ENV_MOVE_DETECT_DELAY, "30")

    window = read_correlation_window(project.config_path)

    assert window != pytest.approx(10.0), "fell back to the default, ignoring the live override"
    assert window == pytest.approx(30.0)


def test_drain_pipeline_honours_the_projects_configured_window(
    make_project,
    write_lock,
    fake_process_table,
    fake_terminator,
    fake_clock,
    fake_log_stat,
    daemons,
):
    """UNIT-L16: the whole stop pipeline picks the window up from the project's
    config — the wiring, not just the primitive.

    Discriminating condition: 15 s is neither the log-idle threshold (3 s) nor the
    daemon default (10 s), so only a value actually read from this project's
    config produces this timing.
    """
    project = make_project()
    project.config_path.write_text("move_detect_delay: 15\n", encoding="utf-8")
    fake_process_table.set_entries([daemons.entry(4242, str(project.root), create_time=1.0)])
    write_lock(project, 4242)
    fake_log_stat.current = _log_written_at(1000.0)

    outcome = drain_and_terminate(
        project,
        idle_threshold=3.0,
        grace_period=40.0,
        process_table=fake_process_table,
        terminator=fake_terminator,
        clock=fake_clock,
        sleep=fake_clock.advance,
        log_stat=fake_log_stat,
        wall_clock=lambda: 1000.0,
    )

    assert outcome.performed is True
    assert outcome.forced is False, "the drain resolved cleanly, not on the grace bound"
    assert fake_clock.now == pytest.approx(15.0, abs=0.5)


def test_drain_rearms_the_window_when_a_correlation_opens_mid_drain(tmp_path, fake_clock):
    """UNIT-L16 (CR F1): the window covers a correlation opened *during* the drain,
    not only one already open when it started.

    Ageing the log at entry is what keeps the common close fast, but it is a
    statement about the instant the drain begins.  The drain then runs for
    seconds, and a delete buffered inside that span opens a fresh correlation the
    entry-time decision knows nothing about.

    Discriminating condition: the log is 60 s old at entry, so the fast path is
    correctly chosen — and then the daemon logs a `file_deleted` 0.5 s in and goes
    silent again.  Computing the required span once returns quiescent at 3.5 s
    while the correlation stays open until 10.5 s: the same silent loss, one code
    path over.
    """
    wall_base = 100_000.0
    state = {"stat": LogStat(Path("LinkWatcherLog.txt"), 100, wall_base - 60.0), "fired": False}

    def log_stat(_log_dir):
        return state["stat"]

    def sleep_and_maybe_buffer(seconds):
        fake_clock.advance(seconds)
        if not state["fired"] and fake_clock.now >= 0.5:
            state["fired"] = True
            # The daemon logs the delete, buffers it, and goes quiet again.
            state["stat"] = LogStat(Path("LinkWatcherLog.txt"), 110, wall_base + fake_clock.now)

    quiescent = watch_quiescence(
        tmp_path,
        idle_threshold=3.0,
        grace_period=20.0,
        correlation_window=10.0,
        clock=fake_clock,
        sleep=sleep_and_maybe_buffer,
        log_stat=log_stat,
        wall_clock=lambda: wall_base + fake_clock.now,
    )

    assert quiescent is True, "the daemon does go quiet — this is a clean drain, just a later one"
    assert fake_clock.now != pytest.approx(
        3.5, abs=0.3
    ), "resolving 3.5 s in terminates while the correlation is still open"
    assert fake_clock.now == pytest.approx(10.5, abs=0.6)


def test_controller_stop_applies_the_correlation_window(
    make_project,
    write_lock,
    fake_process_table,
    fake_runner,
    fake_terminator,
    fake_clock,
    fake_log_stat,
    daemons,
):
    """UNIT-L16 (CR F4): the widening is reachable through the controller.

    Discriminating condition: `FakeLogStat` reports `mtime=1.0`, so against the
    real wall clock every log looks ancient and every controller-level drain took
    the 3 s fast path — the widened branch was unreachable from here regardless of
    whether it worked. Injecting `wall_clock` makes the log look freshly written,
    and the drain must then hold for the project's configured window.
    """
    project = make_project()
    project.config_path.write_text("move_detect_delay: 12\n", encoding="utf-8")
    fake_process_table.set_entries([daemons.entry(4242, str(project.root), create_time=1.0)])
    write_lock(project, 4242)
    fake_log_stat.current = _log_written_at(1000.0)
    model = seed_model(project, DaemonStatus.RUNNING, pids=[4242], clock=fake_clock)
    controller = LifecycleController(
        model=model,
        post=lambda callback: callback(),
        process_table=fake_process_table,
        grace_period_seconds=40.0,
        log_idle_threshold_seconds=3.0,
        runner=fake_runner,
        terminator=fake_terminator,
        clock=fake_clock,
        sleep=fake_clock.advance,
        log_stat=fake_log_stat,
        wall_clock=lambda: 1000.0,
        executor=lambda fn: fn(),
    )

    assert controller.stop("PRJ-001") is True

    assert fake_clock.now != pytest.approx(
        3.0, abs=0.5
    ), "the controller must not silently take the fast path when a window applies"
    assert fake_clock.now == pytest.approx(12.0, abs=0.5)


def test_rearming_still_force_stops_a_daemon_that_never_goes_quiet(tmp_path, fake_clock):
    """UNIT-L16 (CR F1) guard: re-arming must not defeat the BR-7 grace bound.

    Discriminating condition: activity on every check means the re-armed span is
    never satisfied, so grace — not quiescence — has to end the drain.
    """
    wall_base = 100_000.0
    state = {"stat": LogStat(Path("LinkWatcherLog.txt"), 100, wall_base - 60.0)}

    def log_stat(_log_dir):
        return state["stat"]

    def busy_sleep(seconds):
        fake_clock.advance(seconds)
        state["stat"] = LogStat(
            Path("LinkWatcherLog.txt"),
            state["stat"].size + 10,
            wall_base + fake_clock.now,
        )

    quiescent = watch_quiescence(
        tmp_path,
        idle_threshold=3.0,
        grace_period=20.0,
        correlation_window=10.0,
        clock=fake_clock,
        sleep=busy_sleep,
        log_stat=log_stat,
        wall_clock=lambda: wall_base + fake_clock.now,
    )

    assert quiescent is False
    assert fake_clock.now == pytest.approx(20.0, abs=0.5)
