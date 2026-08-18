"""
Document Metadata:
ID: TE-TST-146
Type: Test File
Category: Test
Version: 1.0
Created: 2026-08-10
Updated: 2026-08-10
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

from linkwatcher.linkwatcher_control_panel.discovery import LOCK_FILE_NAME
from linkwatcher.linkwatcher_control_panel.lifecycle import (
    DRAIN_PIN_MARGIN_SECONDS,
    EXIT_WAIT_TIMEOUT_SECONDS,
    LAUNCHER_TIMEOUT_SECONDS,
    LifecycleController,
    RunResult,
    _sweep_stale_captures,
    cleanup_lock,
    drain_and_terminate,
    launcher_path,
    newest_log_stat,
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
