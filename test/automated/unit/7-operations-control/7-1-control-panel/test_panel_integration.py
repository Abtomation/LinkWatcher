"""
Document Metadata:
ID: TE-TST-144
Type: Test File
Category: Test
Version: 1.0
Created: 2026-07-31
Updated: 2026-07-31
Component Name: app
Feature Id: 7.1.1
Language: Python
Test Name: panel_integration
Test Type: Unit

Integration tests for the Control Panel discovery pipeline
(discovery → dispatcher queue → ``AppModel``), per TE-TSP-045 INT-1/INT-2.

Phase B scope: convergence on externally started and externally stopped daemons
— the property that makes the panel a truthful monitor (KR-01, AC-1/AC-4).
Phase C adds the action pipelines: start (INT-3), stop with drain (INT-4), and
the duplicate-start race (INT-9), driven through a synchronously-executed
:class:`~linkwatcher.linkwatcher_control_panel.lifecycle.LifecycleController`
posting into the same dispatcher queue.  Phase D adds shutdown orchestration
(INT-5/INT-6 plus the watchdog backstop and the zero-target / adopted-drain
edges) via :class:`~linkwatcher.linkwatcher_control_panel.lifecycle.ShutdownOrchestrator`.
Phase E adds the config-save notice pipeline (INT-7: a real ``save_config``
against the project's config plus the notice decision from the model's row
status).  Phase G adds worker-error isolation (INT-8) across all four worker
surfaces — start, stop, validation, discovery — plus the UI-thread dispatcher,
each asserted against a **real** panel log file; and the EC-7 pipeline half
(a surfaced start failure decays back to poll truth) that the unit tests
cannot see.

Note on "parallel": production runs one drain worker thread per project; with
this file's synchronous executor the drains run back-to-back on one shared fake
clock, so elapsed fake time is the *sum* of the per-project drains.  The
assertions target outcomes and bounds, not wall-clock overlap.

No Tk is instantiated (per the test spec's "Tk display: avoided" rule): the
:class:`Pipeline` harness below reproduces the app's queue-and-dispatch wiring
so the pipeline is exercised exactly as ``app.py`` drives it, but synchronously.

Recorded as a unit-type test because this project's Python test configuration
defines no separate integration directory; the scenarios are the spec's INT-*.
"""

import logging
import queue
import sys
import threading
from pathlib import Path

import pytest

from linkwatcher.linkwatcher_control_panel.app import drain_queue, report_callback_exception
from linkwatcher.linkwatcher_control_panel.config_edit import save_config
from linkwatcher.linkwatcher_control_panel.discovery import LOCK_FILE_NAME, DiscoveryPoller
from linkwatcher.linkwatcher_control_panel.lifecycle import (
    OUTCOME_PIN_TTL_SECONDS,
    LifecycleController,
    LogStat,
    RunResult,
    ShutdownOrchestrator,
)
from linkwatcher.linkwatcher_control_panel.model import AppModel, DaemonStatus
from linkwatcher.linkwatcher_control_panel.panel_log import get_panel_logger, setup_panel_log
from linkwatcher.linkwatcher_control_panel.validation import ValidationController
from linkwatcher.linkwatcher_control_panel.views.rendering import config_notice

pytestmark = [
    pytest.mark.feature("7.1.1"),
    pytest.mark.priority("Critical"),
    pytest.mark.test_type("unit"),
    pytest.mark.specification("TE-TSP-045"),
]


class Pipeline:
    """poller → thread-safe queue → UI-thread dispatcher → model, without Tk.

    Mirrors ``ControlPanelApp``: the poller hands results to a queue and never
    touches the model; :meth:`pump` plays the role of the ``root.after(100)``
    dispatcher.  :meth:`cycle` runs one full poll+dispatch synchronously so
    convergence can be asserted in exact poll cycles.
    """

    def __init__(self, registry_path, process_table, interval_seconds: float = 0.01, clock=None):
        self.model = AppModel() if clock is None else AppModel(clock)
        self.queue: "queue.Queue" = queue.Queue()
        self.poller = DiscoveryPoller(
            registry_path,
            process_table,
            interval_seconds=interval_seconds,
            on_result=self.on_result,
        )

    def on_result(self, result) -> None:
        self.queue.put(lambda: self.model.apply_poll(result.snapshots, error=result.error))

    def pump(self) -> None:
        while True:
            try:
                callback = self.queue.get_nowait()
            except queue.Empty:
                return
            callback()

    def cycle(self) -> None:
        self.on_result(self.poller.poll_once())
        self.pump()

    def status(self, project_id: str) -> DaemonStatus:
        return self.model.snapshot_for(project_id).status

    def controller(self, process_table, runner, terminator, clock, log_stat) -> LifecycleController:
        """A lifecycle controller wired into this pipeline's queue.

        The worker runs synchronously (``executor``) and its completions land on
        the same dispatcher queue the poller uses — exactly the app's wiring,
        minus the threads, so INT-3/INT-4/INT-9 are deterministic.
        """
        return LifecycleController(
            model=self.model,
            post=self.queue.put,
            process_table=process_table,
            grace_period_seconds=20.0,
            log_idle_threshold_seconds=3.0,
            runner=runner,
            terminator=terminator,
            clock=clock,
            sleep=clock.advance,
            log_stat=log_stat,
            executor=lambda fn: fn(),
        )


# --------------------------------------------------------------------------- #
# INT-1 — External start convergence
# --------------------------------------------------------------------------- #
def test_externally_started_daemon_appears_within_two_poll_cycles(
    make_project, write_registry, write_lock, fake_process_table, daemons
):
    """INT-1: a daemon started outside the panel (e.g. by the hook) converges to RUNNING.

    This is AC-1/AC-4 and the TDD §7.1 convergence target: nothing about the
    start goes through the panel, so only observation can produce the row.
    """
    project = make_project()
    pipeline = Pipeline(write_registry([project]), fake_process_table)

    pipeline.cycle()
    assert pipeline.status("PRJ-001") is DaemonStatus.STOPPED

    # Something else starts the daemon between polls.
    fake_process_table.set_entries(daemons.pair(project.root, parent_pid=700, child_pid=701))
    write_lock(project, 701)

    pipeline.cycle()

    row = pipeline.model.snapshot_for("PRJ-001")
    assert row.status is DaemonStatus.RUNNING
    assert row.pids == [700, 701]


def test_selection_and_row_identity_survive_convergence(
    make_project, write_registry, write_lock, fake_process_table, daemons
):
    """INT-1: a status change repaints the row in place — the selection is not lost."""
    project_a = make_project("PRJ-001", "alpha")
    project_b = make_project("PRJ-002", "beta")
    pipeline = Pipeline(write_registry([project_a, project_b]), fake_process_table)

    pipeline.cycle()
    pipeline.model.select("PRJ-002")

    fake_process_table.set_entries(daemons.pair(project_a.root, parent_pid=800, child_pid=801))
    write_lock(project_a, 800)
    pipeline.cycle()

    assert pipeline.model.selected_project_id == "PRJ-002"
    assert pipeline.status("PRJ-001") is DaemonStatus.RUNNING


# --------------------------------------------------------------------------- #
# INT-2 — External stop convergence
# --------------------------------------------------------------------------- #
def test_externally_killed_daemon_leaves_a_stale_lock_row(
    make_project, write_registry, write_lock, fake_process_table, daemons
):
    """INT-2: a killed daemon whose lock survives becomes STALE_LOCK, not RUNNING.

    A hard kill never runs ``release_lock()``, so the lock outlives the process.
    The row must stop claiming a live daemon (EC-1) and must expose no PIDs —
    there is nothing left that may be acted on.
    """
    project = make_project()
    pipeline = Pipeline(write_registry([project]), fake_process_table)
    fake_process_table.set_entries(daemons.pair(project.root, parent_pid=900, child_pid=901))
    write_lock(project, 900)

    pipeline.cycle()
    assert pipeline.status("PRJ-001") is DaemonStatus.RUNNING

    # Killed externally; the lock file is left behind.
    fake_process_table.remove(900, 901)
    pipeline.cycle()

    row = pipeline.model.snapshot_for("PRJ-001")
    assert row.status is DaemonStatus.STALE_LOCK
    assert row.pids == []
    assert (project.root / LOCK_FILE_NAME).exists()  # the panel never deletes it here


def test_clean_stop_converges_to_stopped(
    make_project, write_registry, write_lock, fake_process_table, daemons
):
    """INT-2: a clean stop (process gone, lock released) converges to a calm STOPPED."""
    project = make_project()
    pipeline = Pipeline(write_registry([project]), fake_process_table)
    fake_process_table.set_entries(daemons.pair(project.root, parent_pid=910, child_pid=911))
    lock = write_lock(project, 910)

    pipeline.cycle()
    fake_process_table.remove(910, 911)
    lock.unlink()
    pipeline.cycle()

    row = pipeline.model.snapshot_for("PRJ-001")
    assert row.status is DaemonStatus.STOPPED
    assert row.detail is None


# --------------------------------------------------------------------------- #
# INT-3 — Start action pipeline
# --------------------------------------------------------------------------- #
def test_start_action_pipeline_resolves_to_running(
    make_project,
    write_registry,
    write_lock,
    write_launcher,
    fake_process_table,
    fake_runner,
    fake_terminator,
    fake_clock,
    fake_log_stat,
    daemons,
):
    """INT-3: Start on a STOPPED project → STARTING pin posted, launcher invoked,
    and the pin resolves to RUNNING once the poll observes the pair (AC-2)."""
    project = make_project()
    write_launcher(project)
    pipeline = Pipeline(write_registry([project]), fake_process_table)
    pipeline.cycle()
    assert pipeline.status("PRJ-001") is DaemonStatus.STOPPED

    controller = pipeline.controller(
        fake_process_table, fake_runner, fake_terminator, fake_clock, fake_log_stat
    )
    assert controller.start("PRJ-001") is True
    assert pipeline.status("PRJ-001") is DaemonStatus.STARTING  # pinned immediately
    assert len(fake_runner.calls) == 1
    pipeline.pump()

    # The launcher's daemon comes up between polls.
    fake_process_table.set_entries(daemons.pair(project.root, parent_pid=700, child_pid=701))
    write_lock(project, 700)
    pipeline.cycle()

    row = pipeline.model.snapshot_for("PRJ-001")
    assert row.status is DaemonStatus.RUNNING
    assert row.pids == [700, 701]


# --------------------------------------------------------------------------- #
# INT-4 — Stop action pipeline
# --------------------------------------------------------------------------- #
def test_stop_action_pipeline_drains_then_confirms_stopped(
    make_project,
    write_registry,
    write_lock,
    fake_process_table,
    fake_runner,
    fake_terminator,
    fake_clock,
    fake_log_stat,
    daemons,
):
    """INT-4: Stop on a RUNNING row → DRAINING pin → quiescent drain → pair
    terminated → own lock cleaned → the next poll confirms STOPPED (AC-3)."""
    project = make_project()
    pipeline = Pipeline(write_registry([project]), fake_process_table)
    fake_process_table.set_entries(daemons.pair(project.root, parent_pid=900, child_pid=901))
    lock = write_lock(project, 900)
    pipeline.cycle()
    assert pipeline.status("PRJ-001") is DaemonStatus.RUNNING

    controller = pipeline.controller(
        fake_process_table, fake_runner, fake_terminator, fake_clock, fake_log_stat
    )
    assert controller.stop("PRJ-001") is True

    # Worker ran synchronously: pair terminated, lock cleaned, pin still DRAINING.
    assert fake_terminator.terminated == [900, 901]
    assert not lock.exists()
    assert pipeline.status("PRJ-001") is DaemonStatus.DRAINING

    pipeline.pump()
    pipeline.cycle()  # the poll observes the exit and resolves the pin

    row = pipeline.model.snapshot_for("PRJ-001")
    assert row.status is DaemonStatus.STOPPED
    assert row.pids == []


# --------------------------------------------------------------------------- #
# INT-9 — Duplicate-start race
# --------------------------------------------------------------------------- #
def test_duplicate_start_takes_idempotent_path(
    make_project,
    write_registry,
    write_lock,
    write_launcher,
    fake_process_table,
    fake_runner,
    fake_terminator,
    fake_clock,
    fake_log_stat,
    daemons,
):
    """INT-9: Start clicked while a daemon is already up (but not yet observed by
    the poll) rides the launcher's idempotent path — one RUNNING row, no second
    daemon (EC-2/AC-10)."""
    project = make_project()
    write_launcher(project)
    pipeline = Pipeline(write_registry([project]), fake_process_table)
    pipeline.cycle()
    assert pipeline.status("PRJ-001") is DaemonStatus.STOPPED

    # The daemon appears externally (e.g. hook-started) before the next poll...
    fake_process_table.set_entries(daemons.pair(project.root, parent_pid=800, child_pid=801))
    write_lock(project, 800)
    # ...and the user clicks Start against the stale STOPPED row.
    controller = pipeline.controller(
        fake_process_table, fake_runner, fake_terminator, fake_clock, fake_log_stat
    )
    assert controller.start("PRJ-001") is True
    assert len(fake_runner.calls) == 1  # launcher invoked; its guards decline the duplicate
    pipeline.pump()

    pipeline.cycle()

    rows = pipeline.model.rows()
    assert len(rows) == 1
    assert rows[0].status is DaemonStatus.RUNNING
    assert rows[0].pids == [800, 801]


# --------------------------------------------------------------------------- #
# INT-5 / INT-6 — Shutdown orchestration
# --------------------------------------------------------------------------- #
class RoutedLogStat:
    """Per-project drain behavior on one shared clock, keyed by project dir name.

    ``quiet_after[name]`` is the clock time after which that project's log goes
    silent (``0.0`` = quiet from the start, ``None`` = never quiet → forced).
    Before the threshold the returned stat changes on every call (activity).
    """

    def __init__(self, clock):
        self.clock = clock
        self.quiet_after = {}

    def __call__(self, log_dir):
        name = Path(log_dir).parents[1].name
        threshold = self.quiet_after.get(name)
        tick = self.clock() if threshold is None else min(self.clock(), threshold)
        return LogStat(Path("LinkWatcherLog.txt"), 100 + int(tick * 10), float(tick))


def make_orchestrator(pipeline, controller, completed, grace=20.0):
    return ShutdownOrchestrator(
        model=pipeline.model,
        controller=controller,
        grace_period_seconds=grace,
        on_complete=lambda: completed.append(True),
    )


def test_parallel_shutdown_resolves_every_row(
    make_project,
    write_registry,
    write_lock,
    fake_process_table,
    fake_runner,
    fake_terminator,
    fake_clock,
    daemons,
):
    """INT-5: three running daemons — fast, at-boundary, never-quiescent — all
    resolve (STOPPED / STOPPED / FORCE_STOPPED) and the exit condition is
    reached (AC-7)."""
    alpha = make_project("PRJ-001", "alpha")
    beta = make_project("PRJ-002", "beta")
    gamma = make_project("PRJ-003", "gamma")
    pipeline = Pipeline(write_registry([alpha, beta, gamma]), fake_process_table)
    fake_process_table.set_entries(
        daemons.pair(alpha.root, parent_pid=100, child_pid=101)
        + daemons.pair(beta.root, parent_pid=200, child_pid=201)
        + daemons.pair(gamma.root, parent_pid=300, child_pid=301)
    )
    write_lock(alpha, 100)
    write_lock(beta, 200)
    write_lock(gamma, 301)
    pipeline.cycle()
    assert all(row.status is DaemonStatus.RUNNING for row in pipeline.model.rows())

    stat = RoutedLogStat(fake_clock)
    stat.quiet_after = {"alpha": 0.0, "beta": 15.0, "gamma": None}
    controller = pipeline.controller(
        fake_process_table, fake_runner, fake_terminator, fake_clock, stat
    )
    completed = []
    orchestrator = make_orchestrator(pipeline, controller, completed)

    assert orchestrator.begin() is True
    assert pipeline.model.shutting_down is True
    assert sorted(orchestrator.targets) == ["PRJ-001", "PRJ-002", "PRJ-003"]

    pipeline.pump()  # worker completions (gamma's FORCE_STOPPED pin)
    pipeline.cycle()  # the poll observes the exits → remaining pins resolve

    assert completed == [True]
    assert pipeline.status("PRJ-001") is DaemonStatus.STOPPED
    assert pipeline.status("PRJ-002") is DaemonStatus.STOPPED
    assert pipeline.status("PRJ-003") is DaemonStatus.FORCE_STOPPED
    assert sorted(fake_terminator.terminated) == [100, 101, 200, 201, 300, 301]
    # Sequential fake time ≈ 3 (alpha) + 15+3 (beta) + 20 (gamma forced) s.
    assert 35.0 <= fake_clock.now <= 45.0


def test_shutdown_is_bounded_when_nothing_quiesces(
    make_project,
    write_registry,
    write_lock,
    fake_process_table,
    fake_runner,
    fake_terminator,
    fake_clock,
    daemons,
):
    """INT-6: a daemon that never goes quiet is force-stopped at the grace bound
    — the exit condition is still reached, so close cannot hang (AC-9/BR-7)."""
    project = make_project("PRJ-001", "noisy")
    pipeline = Pipeline(write_registry([project]), fake_process_table)
    fake_process_table.set_entries(daemons.pair(project.root, parent_pid=400, child_pid=401))
    write_lock(project, 400)
    pipeline.cycle()

    stat = RoutedLogStat(fake_clock)
    stat.quiet_after = {"noisy": None}
    controller = pipeline.controller(
        fake_process_table, fake_runner, fake_terminator, fake_clock, stat
    )
    completed = []
    orchestrator = make_orchestrator(pipeline, controller, completed)

    assert orchestrator.begin() is True
    pipeline.pump()
    pipeline.cycle()

    assert completed == [True]
    assert pipeline.status("PRJ-001") is DaemonStatus.FORCE_STOPPED
    assert sorted(fake_terminator.terminated) == [400, 401]
    assert 19.5 <= fake_clock.now <= 25.0  # bounded by the grace period


def test_watchdog_forces_completion_when_a_worker_hangs(
    make_project,
    write_registry,
    write_lock,
    fake_process_table,
    fake_runner,
    fake_terminator,
    fake_clock,
    fake_log_stat,
    daemons,
):
    """AC-9 backstop: a hung stop worker cannot prevent the exit condition."""
    project = make_project()
    pipeline = Pipeline(write_registry([project]), fake_process_table)
    fake_process_table.set_entries(daemons.pair(project.root, parent_pid=500, child_pid=501))
    write_lock(project, 500)
    pipeline.cycle()

    hung = []  # the executor swallows workers: the drain never runs
    controller = LifecycleController(
        model=pipeline.model,
        post=pipeline.queue.put,
        process_table=fake_process_table,
        grace_period_seconds=20.0,
        log_idle_threshold_seconds=3.0,
        runner=fake_runner,
        terminator=fake_terminator,
        clock=fake_clock,
        sleep=fake_clock.advance,
        log_stat=fake_log_stat,
        executor=hung.append,
    )
    completed = []
    orchestrator = make_orchestrator(pipeline, controller, completed)

    assert orchestrator.begin() is True
    pipeline.pump()
    assert completed == []  # row pinned DRAINING, worker hung — not complete
    assert orchestrator.watchdog_delay_seconds == pytest.approx(35.0)

    orchestrator.watchdog_fired()

    assert completed == [True]
    assert fake_terminator.terminated == []  # nothing was harmed by the hang


def test_close_with_nothing_running_completes_immediately(
    make_project,
    write_registry,
    fake_process_table,
    fake_runner,
    fake_terminator,
    fake_clock,
    fake_log_stat,
):
    """Zero targets: begin() declines, completion is immediate, no shutdown mode."""
    project = make_project()
    pipeline = Pipeline(write_registry([project]), fake_process_table)
    pipeline.cycle()
    assert pipeline.status("PRJ-001") is DaemonStatus.STOPPED

    controller = pipeline.controller(
        fake_process_table, fake_runner, fake_terminator, fake_clock, fake_log_stat
    )
    completed = []
    orchestrator = make_orchestrator(pipeline, controller, completed)

    assert orchestrator.begin() is False
    assert completed == [True]
    assert pipeline.model.shutting_down is False
    assert orchestrator.targets == []


def test_shutdown_adopts_an_in_flight_stop(
    make_project,
    write_registry,
    write_lock,
    fake_process_table,
    fake_runner,
    fake_terminator,
    fake_clock,
    fake_log_stat,
    daemons,
):
    """A row already draining from a user stop is watched, never double-drained
    (the controller's busy guard rejects the duplicate dispatch)."""
    project = make_project()
    pipeline = Pipeline(write_registry([project]), fake_process_table)
    fake_process_table.set_entries(daemons.pair(project.root, parent_pid=600, child_pid=601))
    write_lock(project, 600)
    pipeline.cycle()

    deferred = []
    controller = LifecycleController(
        model=pipeline.model,
        post=pipeline.queue.put,
        process_table=fake_process_table,
        grace_period_seconds=20.0,
        log_idle_threshold_seconds=3.0,
        runner=fake_runner,
        terminator=fake_terminator,
        clock=fake_clock,
        sleep=fake_clock.advance,
        log_stat=fake_log_stat,
        executor=deferred.append,
    )
    assert controller.stop("PRJ-001") is True  # user stop, worker deferred
    assert pipeline.status("PRJ-001") is DaemonStatus.DRAINING

    completed = []
    orchestrator = make_orchestrator(pipeline, controller, completed)
    assert orchestrator.begin() is True
    assert orchestrator.targets == ["PRJ-001"]
    assert len(deferred) == 1  # no duplicate drain worker was dispatched

    deferred[0]()  # the in-flight drain completes
    pipeline.pump()
    pipeline.cycle()

    assert completed == [True]
    assert pipeline.status("PRJ-001") is DaemonStatus.STOPPED
    assert fake_terminator.terminated == [600, 601]


# --------------------------------------------------------------------------- #
# Poll thread wiring
# --------------------------------------------------------------------------- #
def test_poller_thread_delivers_results_to_the_queue(
    make_project, write_registry, fake_process_table, daemons
):
    """The background poller really runs and feeds the dispatcher queue.

    ``cycle()`` above drives the pipeline synchronously; this asserts the thread
    that does it in production starts, polls, and stops cleanly.
    """
    project = make_project()
    fake_process_table.set_entries(daemons.pair(project.root, parent_pid=920, child_pid=921))
    pipeline = Pipeline(write_registry([project]), fake_process_table, interval_seconds=0.01)
    delivered = threading.Event()
    original = pipeline.on_result
    pipeline.poller._on_result = lambda result: (original(result), delivered.set())

    pipeline.poller.start()
    try:
        assert delivered.wait(timeout=5.0), "poller thread produced no result"
    finally:
        pipeline.poller.stop()
    pipeline.pump()

    assert pipeline.status("PRJ-001") is DaemonStatus.RUNNING


def test_a_failing_consumer_does_not_kill_the_poll_thread(
    make_project, write_registry, fake_process_table
):
    """A raising result consumer is isolated — the poller keeps polling.

    Guards the poll loop's own error isolation (TDD §3.3); the broader
    worker-isolation sweep (INT-8) belongs to the Phase G hardening pass.
    """
    project = make_project()
    calls = []

    def exploding(result):
        calls.append(result)
        raise RuntimeError("consumer blew up")

    poller = DiscoveryPoller(
        write_registry([project]), fake_process_table, interval_seconds=0.01, on_result=exploding
    )
    poller.start()
    try:
        deadline = threading.Event()
        deadline.wait(0.3)  # let several cycles run
    finally:
        poller.stop()

    assert len(calls) > 1, "poller stopped after the first consumer failure"


# --------------------------------------------------------------------------- #
# INT-7 — config save + running daemon → restart-needed notice (BR-9/AC-12)
# --------------------------------------------------------------------------- #
def _save_and_notice(model: AppModel, project):
    """The config pane's save flow, minus widgets: persist, then pick the notice.

    Mirrors ``ConfigPane.save`` exactly — a real ``save_config`` against the
    project's real config file, then the notice decision from the model's
    *effective* row status at save time.
    """
    result = save_config(project.config_path, "max_file_size_mb: 25\n")
    assert result.ok, f"save unexpectedly blocked: {result.error}"
    snapshot = model.snapshot_for(project.project_id)
    daemon_running = snapshot is not None and snapshot.status is DaemonStatus.RUNNING
    return config_notice("saved", daemon_running=daemon_running)


def test_int7_save_while_running_produces_restart_notice(
    make_project, write_registry, fake_process_table, daemons
):
    """INT-7: a valid save while the row is RUNNING → restart-needed notice
    (the daemon reads config only at startup, BR-9)."""
    project = make_project()
    Path(project.config_path).write_text("max_file_size_mb: 10\n", encoding="utf-8")
    fake_process_table.set_entries(daemons.pair(project.root, parent_pid=700, child_pid=701))
    pipeline = Pipeline(write_registry([project]), fake_process_table)
    pipeline.cycle()
    assert pipeline.status("PRJ-001") is DaemonStatus.RUNNING

    notice = _save_and_notice(pipeline.model, project)

    assert "Restart the daemon" in notice.text
    assert Path(project.config_path).read_text(encoding="utf-8") == "max_file_size_mb: 25\n"


def test_int7_save_while_stopped_produces_plain_saved_notice(
    make_project, write_registry, fake_process_table
):
    """INT-7: the restart notice is NOT shown for a stopped daemon."""
    project = make_project()
    Path(project.config_path).write_text("max_file_size_mb: 10\n", encoding="utf-8")
    pipeline = Pipeline(write_registry([project]), fake_process_table)  # empty table
    pipeline.cycle()
    assert pipeline.status("PRJ-001") is DaemonStatus.STOPPED

    notice = _save_and_notice(pipeline.model, project)

    assert notice.text == "Saved."
    assert "Restart" not in notice.text


# --------------------------------------------------------------------------- #
# EC-7 — a surfaced start failure decays back to poll truth
# --------------------------------------------------------------------------- #
def test_ec7_start_failure_is_surfaced_then_yields_to_poll_truth(
    make_project,
    write_registry,
    write_launcher,
    fake_process_table,
    fake_runner,
    fake_terminator,
    fake_clock,
    fake_log_stat,
):
    """EC-7 (second half): the failure is visible, then the list goes back to
    reflecting the true state — "project remains not running".

    The unit test (UNIT-L3) proves the reason is captured; only the pipeline can
    prove the outcome pin is temporary, i.e. that a failed start cannot leave a
    permanently red row that no longer matches reality.
    """
    project = make_project()
    write_launcher(project)
    pipeline = Pipeline(write_registry([project]), fake_process_table, clock=fake_clock)
    pipeline.cycle()
    assert pipeline.status("PRJ-001") is DaemonStatus.STOPPED

    controller = pipeline.controller(
        fake_process_table, fake_runner, fake_terminator, fake_clock, fake_log_stat
    )
    fake_runner.script(RunResult(1, "", "pwsh: cannot find the interpreter"))
    controller.start("PRJ-001")
    pipeline.pump()

    row = pipeline.model.snapshot_for("PRJ-001")
    assert row.status is DaemonStatus.START_FAILED
    assert "cannot find the interpreter" in row.detail

    # The daemon never came up; once the outcome pin expires, poll truth wins.
    fake_clock.advance(OUTCOME_PIN_TTL_SECONDS + 1)
    pipeline.model.tick()

    assert pipeline.status("PRJ-001") is DaemonStatus.STOPPED


# --------------------------------------------------------------------------- #
# INT-8 — Worker error isolation (TDD §3.3)
# --------------------------------------------------------------------------- #
@pytest.fixture
def panel_log(tmp_path):
    """A **real** panel log file, per the test spec's mock table for INT-8.

    Configures the shared panel logger against a temp install dir and yields a
    reader for its contents; handlers are closed on teardown so no file handle
    outlives the test (Windows would otherwise block temp cleanup).
    """
    install = tmp_path / "panel-install"
    setup_panel_log(install, to_console=False)
    log_path = install / "logs" / "panel.log"

    def read() -> str:
        return log_path.read_text(encoding="utf-8") if log_path.exists() else ""

    yield read

    logger = get_panel_logger()
    for handler in logger.handlers[:]:
        handler.close()
        logger.removeHandler(handler)
    logger.propagate = True


class ExplodingRunner:
    """A launcher/validate runner whose invocation raises, not merely fails.

    Distinct from a scripted non-zero exit (UNIT-L3/UNIT-V3): this is the
    *unexpected* failure INT-8 is about — the worker never reaches its own
    error handling.
    """

    def __init__(self, message="worker exploded"):
        self.message = message
        self.calls = 0

    def run(self, args, timeout):
        self.calls += 1
        raise RuntimeError(self.message)


class ExplodingTerminator:
    """A terminator that raises mid-stop (e.g. an OS refusal psutil re-raises)."""

    def __init__(self):
        self.attempts = []

    def terminate(self, pid: int) -> None:
        self.attempts.append(pid)
        raise OSError("access denied terminating process")


def _two_project_pipeline(make_project, write_registry, write_lock, fake_process_table, daemons):
    """Two registered projects, both RUNNING — so 'other rows unaffected' is assertable."""
    first = make_project("PRJ-001", "alpha")
    second = make_project("PRJ-002", "beta")
    pipeline = Pipeline(write_registry([first, second]), fake_process_table)
    fake_process_table.set_entries(
        daemons.pair(first.root, parent_pid=700, child_pid=701)
        + daemons.pair(second.root, parent_pid=800, child_pid=801)
    )
    write_lock(first, 700)
    write_lock(second, 800)
    pipeline.cycle()
    assert pipeline.status("PRJ-001") is DaemonStatus.RUNNING
    assert pipeline.status("PRJ-002") is DaemonStatus.RUNNING
    return pipeline, first, second


def test_int8_start_worker_exception_is_caught_logged_and_rendered(
    make_project,
    write_registry,
    write_lock,
    write_launcher,
    fake_process_table,
    fake_terminator,
    fake_clock,
    fake_log_stat,
    daemons,
    panel_log,
):
    """INT-8: an unexpected start-worker exception surfaces as START_FAILED with
    the reason, is written to the panel log, and leaves every other row alone."""
    pipeline, first, second = _two_project_pipeline(
        make_project, write_registry, write_lock, fake_process_table, daemons
    )
    write_launcher(first)
    controller = pipeline.controller(
        fake_process_table,
        ExplodingRunner("psutil died"),
        fake_terminator,
        fake_clock,
        fake_log_stat,
    )

    controller.start("PRJ-001")  # must not raise into the caller
    pipeline.pump()

    row = pipeline.model.snapshot_for("PRJ-001")
    assert row.status is DaemonStatus.START_FAILED
    assert "psutil died" in row.detail
    assert "start_worker_failed" in panel_log()
    # Isolation: the neighbouring project is untouched, and the failed project
    # is not left busy — the operator can retry.
    assert pipeline.status("PRJ-002") is DaemonStatus.RUNNING
    assert controller.is_busy("PRJ-001") is False


def test_int8_stop_worker_exception_releases_the_row_to_poll_truth(
    make_project,
    write_registry,
    write_lock,
    fake_process_table,
    fake_runner,
    fake_clock,
    fake_log_stat,
    daemons,
    panel_log,
):
    """INT-8: a stop worker that blows up mid-termination clears its pin instead
    of stranding the row in "Stopping — draining…" forever.

    Reverting to poll truth is the truthful outcome: the daemon is still in the
    process table, so the row must say RUNNING again — a stuck DRAINING row
    would also disable Stop, making the daemon unstoppable from its supervisor.
    """
    pipeline, _first, _second = _two_project_pipeline(
        make_project, write_registry, write_lock, fake_process_table, daemons
    )
    terminator = ExplodingTerminator()
    controller = pipeline.controller(
        fake_process_table, fake_runner, terminator, fake_clock, fake_log_stat
    )

    controller.stop("PRJ-001")
    pipeline.pump()

    assert terminator.attempts, "the stop worker never reached termination"
    assert pipeline.status("PRJ-001") is DaemonStatus.RUNNING  # pin cleared, truth wins
    assert "stop_worker_failed" in panel_log()
    assert pipeline.status("PRJ-002") is DaemonStatus.RUNNING
    assert controller.is_busy("PRJ-001") is False  # a retry is possible


def test_int8_validation_worker_exception_stays_pane_local(
    make_project, write_registry, write_lock, fake_process_table, daemons, tmp_path, panel_log
):
    """INT-8: a validation worker exception becomes that project's failure state
    only — no other project's validation state is touched (EC-6 rendering)."""
    pipeline, _first, _second = _two_project_pipeline(
        make_project, write_registry, write_lock, fake_process_table, daemons
    )
    controller = ValidationController(
        model=pipeline.model,
        post=pipeline.queue.put,
        install_dir=tmp_path,
        runner=ExplodingRunner("subprocess module exploded"),
        executor=lambda fn: fn(),
    )

    controller.run("PRJ-001")
    pipeline.pump()

    run = pipeline.model.validation["PRJ-001"]
    assert run.state == "failed"
    assert "subprocess module exploded" in run.error
    assert "validation_worker_failed" in panel_log()
    assert "PRJ-002" not in pipeline.model.validation
    assert controller.is_running("PRJ-001") is False


def test_int8_discovery_failure_is_surfaced_and_recovers_next_cycle(
    make_project, write_registry, write_lock, fake_process_table, daemons, panel_log
):
    """INT-8: a process-table failure costs one poll cycle, not the panel.

    The error is surfaced on the model (the list pane renders it as a banner)
    and the very next healthy cycle restores the rows — the poll loop's
    "one bad cycle" contract.
    """
    project = make_project()
    fake_process_table.set_entries(daemons.pair(project.root, parent_pid=700, child_pid=701))
    write_lock(project, 700)

    class FlakyProcessTable:
        def __init__(self, inner):
            self.inner = inner
            self.fail = True

        def snapshot(self):
            if self.fail:
                raise OSError("psutil access denied enumerating processes")
            return self.inner.snapshot()

    flaky = FlakyProcessTable(fake_process_table)
    pipeline = Pipeline(write_registry([project]), flaky)

    pipeline.cycle()  # must not raise

    assert pipeline.model.rows() == []
    assert "Discovery failed" in pipeline.model.discovery_error
    assert "psutil access denied" in pipeline.model.discovery_error
    assert "discovery_poll_failed" in panel_log()

    flaky.fail = False
    pipeline.cycle()

    assert pipeline.status("PRJ-001") is DaemonStatus.RUNNING
    assert pipeline.model.discovery_error is None


def test_int8_dispatcher_isolates_a_failing_callback(panel_log):
    """INT-8 (UI thread): one bad model update can neither kill the dispatcher
    nor strand the updates queued behind it.

    This is the ``root.after(100)`` pump's half of the isolation rule, exercised
    through the same ``drain_queue`` the app calls — no Tk required.
    """
    pending: "queue.Queue" = queue.Queue()
    applied = []
    pending.put(lambda: applied.append("before"))
    pending.put(lambda: (_ for _ in ()).throw(RuntimeError("bad model update")))
    pending.put(lambda: applied.append("after"))

    ran = drain_queue(pending, get_panel_logger())

    assert ran == 3
    assert applied == ["before", "after"]
    assert "dispatch_callback_failed" in panel_log()
    assert pending.empty()


# --------------------------------------------------------------------------- #
# CR-13 / CR-19 — the observability TDD §7.1 and §7.3 already required
# (Code Review 2026-08-17, session 3). Before this, exactly one .debug() call
# existed in the whole subpackage while --debug advertised verbose logging, and
# a UI-thread callback exception vanished entirely under the pythonw launch.
# --------------------------------------------------------------------------- #
def test_dispatch_queue_depth_is_logged_when_work_is_pending(caplog):
    """CR-13: queue depth reaches the panel log, the §7.1 responsiveness signal.

    Discriminating condition: remove the sample and no depth line is emitted, so
    a queue growing tick over tick stays invisible until the user feels it.
    """
    pending = queue.Queue()
    for _ in range(3):
        pending.put(lambda: None)
    log = logging.getLogger("lw-panel-test-depth")

    with caplog.at_level(logging.DEBUG, logger=log.name):
        drain_queue(pending, log)

    depth_lines = [
        r.getMessage() for r in caplog.records if "dispatch_queue_depth" in r.getMessage()
    ]
    assert depth_lines == ["dispatch_queue_depth depth=3"]


def test_idle_dispatcher_logs_no_depth_line(caplog):
    """CR-13 guard rail: an idle panel must not write a line every 100 ms.

    Discriminating condition: log the depth unconditionally and this fails,
    which would bury the panel log at ten lines a second while doing nothing.
    """
    log = logging.getLogger("lw-panel-test-depth-idle")

    with caplog.at_level(logging.DEBUG, logger=log.name):
        drain_queue(queue.Queue(), log)

    assert not [r for r in caplog.records if "dispatch_queue_depth" in r.getMessage()]


def test_ui_callback_exception_is_recorded(caplog):
    """CR-19: an exception Tk raises inside its own callback must not vanish.

    Tk's default hook prints to stderr, which is attached to nothing under the
    `pythonw.exe` launch the hook wrapper uses — so a failing button command or
    key binding left no trace anywhere. These handlers are invoked by Tk
    directly and never pass through the dispatcher, so `drain_queue`'s isolation
    does not cover them.

    Discriminating condition: drop the override and nothing is logged.
    """
    log = logging.getLogger("lw-panel-test-callback")
    try:
        raise ValueError("button command blew up")
    except ValueError:
        exc_info = sys.exc_info()

    with caplog.at_level(logging.ERROR, logger=log.name):
        report_callback_exception(log, *exc_info)

    records = [r for r in caplog.records if "ui_callback_failed" in r.getMessage()]
    assert len(records) == 1
    assert records[0].exc_info is not None, "the traceback must be recorded, not just the message"


def test_callback_exception_handler_never_raises():
    """CR-19: the last handler standing cannot itself throw.

    Discriminating condition: drop its internal guard and a logger that raises
    propagates out of Tk's hook, where nothing else can catch it.
    """

    class BrokenLog:
        def error(self, *_args, **_kwargs):
            raise RuntimeError("logging backend is down")

    report_callback_exception(BrokenLog(), ValueError, ValueError("x"), None)
