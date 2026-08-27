"""
Document Metadata:
ID: TE-TST-157
Type: Test File
Category: Test
Version: 1.0
Created: 2026-08-25
Updated: 2026-08-25
Component Name: LinkWatcherService
Feature Id: 1.1.1
Language: Python
Test Name: WatchLiveness
Test Type: Unit
"""

# WatchLiveness Unit Test
#
# Regression coverage for PD-BUG-139 — a daemon that stops receiving file
# events while continuing to report itself healthy.
#
# The defect class is "alive but not delivering": on Windows the watchdog
# Observer's dispatcher thread stays alive while the per-watch *emitter*
# thread — the actual event producer — is silently lost.  Before the fix,
# service.py polled ``observer.is_alive()`` only, which is structurally
# incapable of seeing this, so the daemon went permanently blind with no
# log record of any kind.
#
# Test File ID: TE-TST-157
# Created: 2026-08-25

import threading
import time
from pathlib import Path

import pytest

from linkwatcher.handler import LinkMaintenanceHandler

pytestmark = [
    pytest.mark.feature("1.1.1"),
    pytest.mark.priority("Critical"),
    pytest.mark.test_type("unit"),
]


# --------------------------------------------------------------------------
# Test doubles
# --------------------------------------------------------------------------


class FakeEmitter:
    """Stands in for watchdog's per-watch WindowsApiEmitter thread."""

    def __init__(self, alive=True):
        self._alive = alive

    def is_alive(self):
        return self._alive

    def kill(self):
        self._alive = False


class FakeObserver:
    """Stands in for watchdog's Observer.

    Mirrors the measured watchdog 6.0.0 behaviour: ``is_alive()`` reports the
    dispatcher thread and stays True even when every emitter is gone.
    """

    def __init__(self, emitters=None, alive=True):
        self.emitters = set(emitters if emitters is not None else [FakeEmitter()])
        self._alive = alive

    def is_alive(self):
        return self._alive


class RecordingLogger:
    """Captures structured log calls so assertions can target level + event."""

    def __init__(self):
        self.records = []

    def _record(self, level):
        def log(event, **kwargs):
            self.records.append((level, event, kwargs))

        return log

    def __getattr__(self, name):
        if name in ("debug", "info", "warning", "error", "critical"):
            return self._record(name)
        raise AttributeError(name)

    def events(self, level=None):
        return [e for lvl, e, _ in self.records if level is None or lvl == level]


class FakeHandler:
    """Minimal stand-in for LinkMaintenanceHandler's liveness surface."""

    def __init__(self, idle=0.0, observes_probe=True):
        self._idle = idle
        self._observes_probe = observes_probe
        self._armed = None
        self._observed = False

    def seconds_since_last_event(self):
        return self._idle

    def arm_liveness_probe(self, path):
        self._armed = path
        self._observed = False

    def liveness_probe_observed(self):
        # A healthy watch delivers the sentinel event; a blind one never does.
        if self._observes_probe:
            self._observed = True
        return self._observed


def make_monitor(**overrides):
    """Build a WatchLivenessMonitor with test-friendly defaults."""
    from linkwatcher.liveness import WatchLivenessMonitor

    writes = []

    params = dict(
        observer=FakeObserver(),
        handler=FakeHandler(),
        logger=RecordingLogger(),
        idle_seconds=60.0,
        probe_timeout=0.05,
        failure_threshold=3,
        sentinel_path="sentinel.tmp",
        write_sentinel=writes.append,
        clock=time.monotonic,
        sleep=lambda _s: None,
    )
    params.update(overrides)
    monitor = WatchLivenessMonitor(**params)
    monitor.test_writes = writes
    return monitor


# --------------------------------------------------------------------------
# The gap itself — what PD-BUG-139 proved the service could not see
# --------------------------------------------------------------------------


class TestWatchLivenessGap:
    """The detection capability PD-BUG-139 showed was missing entirely."""

    def test_service_exposes_a_watch_liveness_check(self):
        """The service must have a health check beyond observer.is_alive().

        Fails before the fix because no such code path exists — that absence
        IS the bug: a blind daemon had nothing that could notice.
        """
        from linkwatcher.service import LinkWatcherService

        assert hasattr(LinkWatcherService, "_watch_is_healthy"), (
            "LinkWatcherService has no watch-liveness check (PD-BUG-139). "
            "observer.is_alive() reports the dispatcher thread only and cannot "
            "detect a lost emitter or stalled delivery."
        )

    def test_observer_is_alive_alone_cannot_detect_a_dead_emitter(self):
        """Pins the measured watchdog behaviour the fix must compensate for."""
        observer = FakeObserver(emitters=[FakeEmitter(alive=False)])

        # This is precisely what the pre-fix service polled, and why it was blind.
        assert observer.is_alive() is True
        assert not any(e.is_alive() for e in observer.emitters)


# --------------------------------------------------------------------------
# Emitter-liveness check (fast, precise diagnosis)
# --------------------------------------------------------------------------


class TestEmitterLiveness:
    def test_dead_emitter_is_reported_unhealthy(self):
        logger = RecordingLogger()
        monitor = make_monitor(
            observer=FakeObserver(emitters=[FakeEmitter(alive=False)]), logger=logger
        )

        assert monitor.check() is False, "a dead emitter must not report healthy"
        assert "observer_emitter_died" in logger.events("error")

    def test_missing_emitter_is_reported_unhealthy(self):
        """An emitter that self-stopped is removed from delivery entirely."""
        logger = RecordingLogger()
        monitor = make_monitor(observer=FakeObserver(emitters=[]), logger=logger)

        assert monitor.check() is False
        assert "observer_emitter_died" in logger.events("error")

    def test_live_emitter_with_recent_activity_is_healthy(self):
        """No false positive on a healthy, active watch."""
        logger = RecordingLogger()
        monitor = make_monitor(handler=FakeHandler(idle=0.0), logger=logger)

        assert monitor.check() is True
        assert logger.events("error") == []
        assert monitor.test_writes == [], "must not probe while events are flowing"


# --------------------------------------------------------------------------
# Delivery canary — the only check that covers this incident's failure mode
# --------------------------------------------------------------------------


class TestDeliveryCanary:
    def test_quiet_tree_triggers_a_probe(self):
        monitor = make_monitor(handler=FakeHandler(idle=999.0, observes_probe=True))

        assert monitor.check() is True
        assert monitor.test_writes == ["sentinel.tmp"], "silence must trigger a probe"

    def test_undelivered_probe_is_tolerated_below_threshold(self):
        """A single missed probe must not kill a daemon (false-positive guard)."""
        logger = RecordingLogger()
        monitor = make_monitor(
            handler=FakeHandler(idle=999.0, observes_probe=False),
            logger=logger,
            failure_threshold=3,
        )

        assert monitor.check() is True
        assert monitor.check() is True
        assert "watch_delivery_stalled" not in logger.events("error")

    def test_undelivered_probe_is_reported_unhealthy_at_threshold(self):
        logger = RecordingLogger()
        monitor = make_monitor(
            handler=FakeHandler(idle=999.0, observes_probe=False),
            logger=logger,
            failure_threshold=3,
        )

        results = [monitor.check() for _ in range(3)]

        assert results[-1] is False, "delivery stall must be reported at threshold"
        assert "watch_delivery_stalled" in logger.events("error")

    def test_successful_probe_resets_the_failure_run(self):
        handler = FakeHandler(idle=999.0, observes_probe=False)
        monitor = make_monitor(handler=handler, failure_threshold=3)

        monitor.check()
        monitor.check()
        handler._observes_probe = True  # delivery recovers
        assert monitor.check() is True

        handler._observes_probe = False
        # The run restarted, so two more misses must still be tolerated.
        assert monitor.check() is True
        assert monitor.check() is True

    def test_disabled_monitor_never_probes_or_fails(self):
        monitor = make_monitor(
            observer=FakeObserver(emitters=[FakeEmitter(alive=False)]),
            handler=FakeHandler(idle=999.0, observes_probe=False),
            enabled=False,
        )

        assert monitor.check() is True
        assert monitor.test_writes == []


# --------------------------------------------------------------------------
# Handler-side observation point
# --------------------------------------------------------------------------


class TestHandlerLivenessObservation:
    def test_handler_exposes_liveness_surface(self):
        for name in (
            "seconds_since_last_event",
            "arm_liveness_probe",
            "liveness_probe_observed",
        ):
            assert hasattr(LinkMaintenanceHandler, name), (
                f"handler must expose {name}() so delivery can be observed "
                "before own-output/ignored filtering drops the event"
            )

    def test_sentinel_event_is_not_processed_as_a_real_file(self, tmp_path):
        """The probe file must never enter the link database."""
        from linkwatcher.database import LinkDatabase
        from linkwatcher.parser import LinkParser
        from linkwatcher.updater import LinkUpdater

        db = LinkDatabase()
        handler = LinkMaintenanceHandler(
            link_db=db,
            parser=LinkParser(),
            updater=LinkUpdater(),
            project_root=str(tmp_path),
        )

        sentinel = tmp_path / ".linkwatcher-liveness-probe"
        sentinel.write_text("probe", encoding="utf-8")
        handler.arm_liveness_probe(str(sentinel))

        class _Event:
            is_directory = False
            event_type = "created"
            src_path = str(sentinel)

        handler.dispatch(_Event())

        assert handler.liveness_probe_observed() is True
        assert db.get_stats()["total_references"] == 0, (
            "the liveness sentinel must be observed for liveness only and never "
            "be parsed into the link database"
        )

    def test_real_event_refreshes_the_idle_clock(self, tmp_path):
        from linkwatcher.database import LinkDatabase
        from linkwatcher.parser import LinkParser
        from linkwatcher.updater import LinkUpdater

        handler = LinkMaintenanceHandler(
            link_db=LinkDatabase(),
            parser=LinkParser(),
            updater=LinkUpdater(),
            project_root=str(tmp_path),
        )

        class _Event:
            is_directory = False
            event_type = "modified"
            src_path = str(tmp_path / "notes.md")

        time.sleep(0.02)
        before = handler.seconds_since_last_event()
        handler.dispatch(_Event())
        after = handler.seconds_since_last_event()

        assert after < before, "an arriving event must refresh the idle clock"


# --------------------------------------------------------------------------
# Configuration surface
# --------------------------------------------------------------------------


class TestLivenessConfiguration:
    def test_liveness_settings_exist_with_conservative_defaults(self):
        from linkwatcher.config.settings import LinkWatcherConfig

        config = LinkWatcherConfig()

        assert config.watch_liveness_enabled is True
        assert config.watch_liveness_idle_seconds > 0
        assert config.watch_liveness_probe_timeout > 0
        assert (
            config.watch_liveness_failure_threshold >= 2
        ), "a single missed probe must never be enough to stop a daemon"

    def test_invalid_liveness_values_are_reported_by_validate(self):
        from linkwatcher.config.settings import LinkWatcherConfig

        config = LinkWatcherConfig()
        config.watch_liveness_idle_seconds = -1

        issues = config.validate()

        assert any("watch_liveness_idle_seconds" in issue for issue in issues)

    def test_a_failure_threshold_of_one_is_rejected(self):
        """A threshold of 1 is *positive*, so the schema's default rule admits
        it — but it makes the very first missed probe stop the daemon, which
        contradicts both the monitor's own contract and the promise stated in
        FDD 1.1.1-EC-11 that a single missed probe never stops a daemon.  A
        transiently slow filesystem must not be able to take down a working
        watch (PD-BUG-139 code-review finding)."""
        from linkwatcher.config.settings import LinkWatcherConfig

        config = LinkWatcherConfig()
        config.watch_liveness_failure_threshold = 1

        issues = config.validate()

        assert any(
            "watch_liveness_failure_threshold" in issue for issue in issues
        ), "a threshold of 1 breaks the single-missed-probe guarantee and must be rejected"

    def test_a_failure_threshold_of_two_is_accepted(self):
        """The boundary itself stays usable — the rule rejects 1, not 'small'."""
        from linkwatcher.config.settings import LinkWatcherConfig

        config = LinkWatcherConfig()
        config.watch_liveness_failure_threshold = 2

        issues = config.validate()

        assert not any("watch_liveness_failure_threshold" in issue for issue in issues)


# --------------------------------------------------------------------------
# Repair guidance — PD-BUG-139 code-review finding (2026-08-26)
# --------------------------------------------------------------------------


class TestBlindWatchRepairGuidance:
    """What the operator is told when the watch is declared dead.

    Data Integrity is a Critical dimension for this bug: the harm is not the
    stopped daemon, it is the references silently left stale during the blind
    window.  Restarting restores *monitoring* and repairs nothing, so an
    instruction to restart is only half the remedy — the operator also needs
    to be pointed at the scan that finds what already broke.
    """

    @staticmethod
    def _detail(monitor, event):
        return [kw["detail"] for lvl, e, kw in monitor.logger.records if e == event][0]

    def test_emitter_death_points_at_the_repair_scan(self):
        monitor = make_monitor(observer=FakeObserver(emitters=[FakeEmitter(alive=False)]))

        assert monitor.check() is False

        detail = self._detail(monitor, "observer_emitter_died")
        assert "--validate" in detail, (
            "restarting restores monitoring but not the references already left "
            "stale; the operator must be told how to find them"
        )

    def test_delivery_stall_points_at_the_repair_scan(self):
        monitor = make_monitor(
            handler=FakeHandler(idle=999.0, observes_probe=False),
            failure_threshold=1,
        )

        assert monitor.check() is False

        detail = self._detail(monitor, "watch_delivery_stalled")
        assert "--validate" in detail


# --------------------------------------------------------------------------
# Sentinel placement — PD-BUG-139 code-review finding (2026-08-26)
# --------------------------------------------------------------------------


class TestLivenessSentinelPlacement:
    """Where the probe file lands, and whether it outlives the daemon.

    The canary writes a real file inside the watched tree, so its location is
    a product decision rather than an implementation detail.  The daemon's
    own-output directory is already excluded from both the initial scan and
    event handling (PD-BUG-107); the project root is excluded from neither,
    is visible to git, and a file rewritten there every idle window is churn
    for anything else watching the tree.

    Code review found ``_liveness_sentinel_path`` iterating the *dict*
    returned by ``compute_own_output_exclusions``.  Iterating a dict yields
    its keys — the strings "dirs" and "file_stems", never a directory — so
    the own-output branch was unreachable and every deployment fell through
    to the project-root fallback.
    """

    @staticmethod
    def _service(project_root, log_file):
        from linkwatcher.config.settings import LinkWatcherConfig
        from linkwatcher.service import LinkWatcherService

        config = LinkWatcherConfig()
        config.log_file = str(log_file)
        return LinkWatcherService(str(project_root), config=config, register_signals=False)

    def test_sentinel_lands_in_the_own_output_directory(self, tmp_path):
        log_dir = tmp_path / "logs" / "linkwatcher"
        log_dir.mkdir(parents=True)
        service = self._service(tmp_path, log_dir / "LinkWatcherLog.txt")

        sentinel = Path(service._liveness_sentinel_path())

        assert sentinel.parent == log_dir, (
            "the probe belongs in the excluded own-output directory, not loose " "in the project"
        )
        assert sentinel.parent != tmp_path, "must not fall through to the project root"

    def test_sentinel_falls_back_to_the_project_root_when_the_log_sits_there(self, tmp_path):
        # A log written directly to the project root excludes only its own
        # rotation-sibling stems, never a directory, so there is no excluded
        # folder to hide the probe in and the root is the correct fallback.
        service = self._service(tmp_path, tmp_path / "LinkWatcherLog.txt")

        sentinel = Path(service._liveness_sentinel_path())

        assert sentinel.parent == tmp_path

    def test_sentinel_stays_inside_the_tree_when_the_log_is_outside_it(self, tmp_path):
        outside = tmp_path / "outside"
        outside.mkdir()
        project = tmp_path / "project"
        project.mkdir()
        service = self._service(project, outside / "LinkWatcherLog.txt")

        sentinel = Path(service._liveness_sentinel_path())

        assert sentinel.parent == project, (
            "the probe proves the watch works, so it must be written inside the "
            "watched tree even when the log is not"
        )

    def test_sentinel_is_removed_when_the_daemon_stops(self, tmp_path):
        """A probe file that outlives the daemon outlives its explanation."""
        log_dir = tmp_path / "logs" / "linkwatcher"
        log_dir.mkdir(parents=True)
        service = self._service(tmp_path, log_dir / "LinkWatcherLog.txt")
        sentinel = Path(service._liveness_sentinel_path())
        sentinel.write_text("probe", encoding="utf-8")

        service.running = True
        service.stop()

        assert not sentinel.exists()

    def test_sentinel_is_removed_even_when_running_was_already_cleared(self, tmp_path):
        """The self-stop path clears ``running`` before ``stop()`` is reached.

        ``stop()`` guards its body with ``if self.running``, and every path that
        leaves the monitoring loop — a liveness failure setting ``running =
        False``, or ``_signal_handler`` doing the same — clears the flag first.
        So the guarded body does not run on precisely the shutdowns where a
        probe file exists.  Cleanup must therefore sit outside that guard;
        measured against a real daemon, a self-stopped one left its probe
        behind when it did not.
        """
        log_dir = tmp_path / "logs" / "linkwatcher"
        log_dir.mkdir(parents=True)
        service = self._service(tmp_path, log_dir / "LinkWatcherLog.txt")
        sentinel = Path(service._liveness_sentinel_path())
        sentinel.write_text("probe", encoding="utf-8")

        service.running = False  # the state every self-stop path arrives in
        service.stop()

        assert not sentinel.exists(), "cleanup must not depend on the `running` guard"

    def test_stop_survives_an_already_absent_sentinel(self, tmp_path):
        """The common case: a busy tree never goes quiet, so no probe is ever
        written.  Cleanup must not turn that into a shutdown error."""
        log_dir = tmp_path / "logs" / "linkwatcher"
        log_dir.mkdir(parents=True)
        service = self._service(tmp_path, log_dir / "LinkWatcherLog.txt")

        service.running = True
        service.stop()  # must not raise


# --------------------------------------------------------------------------
# PD-BUG-145 — the probe must not outlive the daemon on the paths that
# actually stop daemons
# --------------------------------------------------------------------------


class TestLivenessSentinelSurvivesForceKill:
    """Cleanup-at-shutdown is the wrong hook for a process that is hard-killed.

    ``_remove_liveness_sentinel()`` is reachable only through ``stop()`` — that
    is, only when Python gets to run shutdown code at all.  Neither operator
    stop path does: ``stop_linkwatcher.ps1`` uses ``Stop-Process -Force`` and
    the Control Panel uses ``psutil terminate()``, both of which are a hard
    ``TerminateProcess`` on Windows.  An ``atexit``/signal hook is a dead end
    for the same reason.  Measured against a real daemon killed with
    ``taskkill /F``: the probe survived in both layouts — visibly, as an
    untracked dotfile in the repository root, when the log sits at the project
    root and the placement falls back there.

    Two defences, because neither is sufficient alone:

    * the probe is transient by nature, so it is removed as soon as its round
      trip is decided rather than left on disk between probes; and
    * startup sweeps whatever an abnormal exit left behind — force-kill,
      crash, or power loss — which is the only defence that can cover a
      process that never runs shutdown code.
    """

    @staticmethod
    def _service(project_root, log_file):
        from linkwatcher.config.settings import LinkWatcherConfig
        from linkwatcher.service import LinkWatcherService

        config = LinkWatcherConfig()
        config.log_file = str(log_file)
        return LinkWatcherService(str(project_root), config=config, register_signals=False)

    @staticmethod
    def _run_until_started(service, timeout=20.0):
        """Start the daemon in a thread and return once it is monitoring.

        The assertions must run while the daemon is UP.  Letting ``start()``
        return first would run ``stop()``, whose own cleanup would remove the
        probe and make a startup-sweep assertion pass for the wrong reason.
        ``running`` is set after the observer starts, which is after the sweep,
        so observing it is a sufficient ordering barrier with no race.
        """
        thread = threading.Thread(target=service.start, kwargs={"initial_scan": False})
        thread.daemon = True
        thread.start()

        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            if service.running:
                return thread
            time.sleep(0.02)
        raise AssertionError("service never reached the monitoring loop")

    @staticmethod
    def _shut_down(service, thread):
        service.running = False
        thread.join(timeout=20)
        observer = getattr(service, "observer", None)
        if observer is not None and observer.is_alive():
            observer.stop()
            observer.join(timeout=10)

    # -- defence 1: the probe does not persist between round trips ----------

    def _probing_monitor(self, sentinel, observes_probe):
        from linkwatcher.service import LinkWatcherService

        return make_monitor(
            handler=FakeHandler(idle=120.0, observes_probe=observes_probe),
            idle_seconds=60.0,
            sentinel_path=str(sentinel),
            # the real writer, so a real file lands on disk
            write_sentinel=LinkWatcherService._write_liveness_sentinel,
        )

    def test_observed_probe_leaves_no_file_behind(self, tmp_path):
        sentinel = tmp_path / ".linkwatcher-liveness-probe"
        monitor = self._probing_monitor(sentinel, observes_probe=True)

        assert monitor.check() is True, "a delivered probe must report healthy"

        assert not sentinel.exists(), (
            "the probe only has to exist long enough to emit one event; leaving "
            "it on disk is what lets a force-kill strand it"
        )

    def test_undelivered_probe_leaves_no_file_behind(self, tmp_path):
        """The failing probe is the one most likely to be stranded — a stalling
        watch is exactly when the daemon is about to stop."""
        sentinel = tmp_path / ".linkwatcher-liveness-probe"
        monitor = self._probing_monitor(sentinel, observes_probe=False)

        monitor.check()  # below threshold: tolerated, but the file must go

        assert not sentinel.exists()

    def test_an_unremovable_probe_does_not_change_the_verdict(self, tmp_path):
        """Cleanup is best-effort: it must never turn a healthy watch unhealthy."""
        sentinel = tmp_path / ".linkwatcher-liveness-probe"
        monitor = self._probing_monitor(sentinel, observes_probe=True)

        def _explode(_path):
            raise OSError("locked by another process")

        monitor.remove_sentinel = _explode

        assert monitor.check() is True, (
            "a probe that round-tripped is proof the watch is alive; failing to "
            "delete the file afterwards says nothing about delivery"
        )

    # -- defence 2: startup sweeps what an abnormal exit stranded -----------

    def test_startup_sweeps_a_probe_left_by_a_force_killed_daemon(self, tmp_path):
        log_dir = tmp_path / "logs" / "linkwatcher"
        log_dir.mkdir(parents=True)
        service = self._service(tmp_path, log_dir / "LinkWatcherLog.txt")

        stranded = Path(service._liveness_sentinel_path())
        stranded.write_text("left behind by a killed daemon", encoding="utf-8")

        thread = self._run_until_started(service)
        try:
            assert not stranded.exists(), (
                "a daemon that is hard-killed never runs shutdown code, so "
                "startup is the only place a stranded probe can be swept"
            )
        finally:
            self._shut_down(service, thread)

    def test_startup_sweeps_the_project_root_fallback_too(self, tmp_path):
        """The fallback layout is where the leftover is actually user-visible:
        an untracked dotfile sitting in the repository root."""
        service = self._service(tmp_path, tmp_path / "LinkWatcherLog.txt")

        stranded = Path(service._liveness_sentinel_path())
        assert stranded.parent == tmp_path, "guard: this must be the fallback layout"
        stranded.write_text("left behind by a killed daemon", encoding="utf-8")

        thread = self._run_until_started(service)
        try:
            assert not stranded.exists()
        finally:
            self._shut_down(service, thread)

    def test_startup_sweep_does_not_relocate_the_probe(self, tmp_path):
        """The sweep must not resolve the sentinel path too early.

        ``_liveness_sentinel_path`` pins its answer for the daemon's lifetime,
        and the answer depends on whether the log directory exists yet.  A
        sweep placed before logging setup would pin the project-root fallback
        and so relocate the probe for EVERY deployment — turning a cleanup fix
        into a placement regression that PD-BUG-139's code review already
        caught once.
        """
        log_dir = tmp_path / "logs" / "linkwatcher"
        log_dir.mkdir(parents=True)
        service = self._service(tmp_path, log_dir / "LinkWatcherLog.txt")

        thread = self._run_until_started(service)
        try:
            pinned = Path(service._liveness_sentinel_path())
            assert pinned.parent == log_dir, (
                "the sweep must run after logging setup so placement still "
                "resolves to the excluded own-output directory"
            )
            assert pinned.parent != tmp_path, "must not have fallen back to the project root"
        finally:
            self._shut_down(service, thread)

    def test_startup_is_unaffected_when_no_probe_was_stranded(self, tmp_path):
        """The normal case — the sweep must be a silent no-op, not an error."""
        log_dir = tmp_path / "logs" / "linkwatcher"
        log_dir.mkdir(parents=True)
        service = self._service(tmp_path, log_dir / "LinkWatcherLog.txt")
        sentinel = Path(service._liveness_sentinel_path())
        assert not sentinel.exists()

        thread = self._run_until_started(service)
        try:
            assert service.running is True
            assert not sentinel.exists()
        finally:
            self._shut_down(service, thread)
