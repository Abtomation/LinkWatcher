"""
Document Metadata:
ID: TE-TST-167
Type: Test File
Category: Test
Version: 1.0
Created: 2026-09-01
Updated: 2026-09-01
Component Name: app
Feature Id: 7.1.1
Language: Python
Test Name: PdBug160ShutdownWindowAck
Test Type: Unit
"""

# PD-BUG-160 — a panel that is committed to exiting must stop claiming the
# single-instance slot.
#
# The guard's promise to a launching process has two halves: a window exists
# *now*, and it will still exist when you exit.  PD-BUG-157 made the listener
# verify the first.  Nothing verified the second, and nothing could: the app
# commits irreversibly to exit at `_on_close`, but held no reference to the
# guard, so `guard.release()` ran only in `main()`'s `finally` — after the whole
# drain.  Throughout that drain (up to `grace_period_seconds` + the AC-9
# watchdog margin, ~35 s at defaults) the listener kept answering, and the raise
# genuinely succeeded, so the ack was truthful at the instant it was sent about
# a window that was seconds from being destroyed.  The launcher exited, the
# incumbent finished draining, and the operator had no panel.
#
# The fix drops the instance claim the moment the panel commits to exiting, so a
# launch arriving during the drain sees no published port at all and opens a
# real window.
#
# What each test pins:
#
#   1-2. `_on_close` fires the shutdown-begin callback — on BOTH paths, the
#        nothing-to-drain path and the real drain.  These run without Tk by
#        invoking the unbound method against a stand-in `self`; the
#        nothing-to-drain case needs no patching at all, because
#        `ShutdownOrchestrator.begin()` returns False before any widget is
#        touched.
#   3.   The callback fires BEFORE the drain is dispatched, not after it
#        resolves — ordering is the whole point, since a callback fired at the
#        end of shutdown would leave the window wide open.
#   4.   A second close request does not fire it again (the existing
#        `_shutdown is not None` guard must keep covering it).
#   5.   An unwired callback is not an error — the panel must still close.
#   6.   The end-to-end contract on the guard side: once released, a *fresh*
#        launch takes ownership cleanly rather than being sent away.
#   7.   The entry script actually wires the two together.  `control_panel.main`
#        is unreachable by any in-process test (it builds a real Tk window and
#        blocks in `mainloop`), so this is asserted on the AST — matched as a
#        real assignment, never as source text, so a comment mentioning the
#        wiring cannot satisfy it (the same discipline the framework's own
#        removal assertions use).

import ast
import socket
import threading
from pathlib import Path

import pytest

from linkwatcher.linkwatcher_control_panel import app as app_module
from linkwatcher.linkwatcher_control_panel.app import ControlPanelApp
from linkwatcher.linkwatcher_control_panel.model import AppModel, ProjectInfo
from linkwatcher.linkwatcher_control_panel.settings import PanelSettings
from linkwatcher.linkwatcher_control_panel.single_instance import PORT_FILENAME, SingleInstanceGuard

pytestmark = [
    pytest.mark.feature("7.1.1"),
    pytest.mark.priority("Standard"),
    pytest.mark.test_type("unit"),
    pytest.mark.specification("TE-TSP-045"),
]


# --------------------------------------------------------------------------- #
# Tk-free stand-ins
#
# `_on_close` is a method on the one class in the panel that owns Tk, so the
# suite never constructs it.  It is still ordinary Python: invoked against a
# stand-in `self` carrying the handful of attributes it reads, the real
# `ShutdownOrchestrator` and the real `AppModel` run untouched and only the
# widgets are faked.
# --------------------------------------------------------------------------- #


class RecordingLog:
    """Swallows the panel log lines `_on_close` emits."""

    def __init__(self):
        self.messages = []

    def info(self, message, *args):
        self.messages.append(message % args if args else message)

    def exception(self, message, *args):  # pragma: no cover - not exercised here
        self.messages.append(message)


class FakeRoot:
    """Records `root.after` schedules instead of running a mainloop."""

    def __init__(self):
        self.scheduled = []

    def after(self, delay_ms, callback):
        self.scheduled.append((delay_ms, callback))


class FakeDialog:
    """Stands in for the modal ShutdownDialog (a real Toplevel needs a display)."""

    def __init__(self, *args, **kwargs):
        self.args = args

    def render(self):  # pragma: no cover - the model never notifies in these tests
        pass


class RecordingLifecycle:
    """Records the stop dispatches the orchestrator makes."""

    def __init__(self):
        self.stopped = []

    def stop(self, project_id):
        self.stopped.append(project_id)
        return True


class CloseHarness:
    """A stand-in `self` for `ControlPanelApp._on_close`.

    Carries exactly the attributes that method reads.  `events` records the
    order in which things happened, which is what test 3 asserts on.
    """

    def __init__(self, *, model, on_shutdown_begin=None):
        self.model = model
        self.settings = PanelSettings(grace_period_seconds=20.0)
        self.lifecycle = RecordingLifecycle()
        self.root = FakeRoot()
        self.shutdown_dialog = None
        self.on_shutdown_begin = on_shutdown_begin
        self._shutdown = None
        self._log = RecordingLog()
        self._exiting = False
        self.events = []

    # The real implementation, borrowed rather than faked: it is part of what is
    # under test, so a stub here would let the try/except regress unnoticed.
    _release_instance_claim = ControlPanelApp._release_instance_claim

    def _finish_shutdown(self):
        self.events.append("shutdown_finished")


def close(harness):
    """Run the real `_on_close` against *harness*."""
    ControlPanelApp._on_close(harness)


@pytest.fixture
def patched_dialog(monkeypatch):
    """Replace the modal dialog so the draining path needs no display."""
    monkeypatch.setattr(app_module, "ShutdownDialog", FakeDialog)


def project(project_id="PRJ-001", root=Path("/tmp/PRJ-001")):
    return ProjectInfo(
        project_id=project_id,
        name=project_id,
        root=root,
        config_path=root / "linkwatcher-config.yaml",
        log_dir=root / "logs",
    )


# --------------------------------------------------------------------------- #
# The claim is dropped when the panel commits to exiting
# --------------------------------------------------------------------------- #


class TestCloseReleasesTheInstanceClaim:
    """A panel that is exiting must stop answering for the instance slot."""

    def test_close_with_nothing_to_drain_fires_the_shutdown_callback(self):
        # No rows -> ShutdownOrchestrator.begin() returns False and `_on_close`
        # returns before any widget is touched, so this path needs no patching.
        fired = []
        harness = CloseHarness(model=AppModel(), on_shutdown_begin=lambda: fired.append(True))

        close(harness)

        assert fired == [True], "closing must drop the single-instance claim"

    def test_close_with_a_daemon_to_drain_fires_the_shutdown_callback(self, patched_dialog):
        # The reported scenario: something is draining, so the panel stays alive
        # for the whole grace period while the listener would otherwise answer.
        fired = []
        model = AppModel()
        model.apply_poll(_running_snapshot())
        harness = CloseHarness(model=model, on_shutdown_begin=lambda: fired.append(True))

        close(harness)

        assert harness.lifecycle.stopped, "precondition: a drain must be in flight"
        assert fired == [True], "the claim must be dropped during a real drain too"

    def test_callback_fires_before_the_drain_is_dispatched(self, patched_dialog):
        # Ordering is the defect.  A callback fired once shutdown *completes*
        # would leave exactly the window this bug is about.
        model = AppModel()
        model.apply_poll(_running_snapshot())
        harness = CloseHarness(model=model)
        harness.on_shutdown_begin = lambda: harness.events.append("claim_released")
        original_stop = harness.lifecycle.stop

        def recording_stop(project_id):
            harness.events.append("drain_dispatched")
            return original_stop(project_id)

        harness.lifecycle.stop = recording_stop

        close(harness)

        assert (
            harness.events[0] == "claim_released"
        ), f"claim must be dropped first, got order: {harness.events}"
        assert "drain_dispatched" in harness.events

    def test_a_second_close_request_does_not_fire_it_again(self, patched_dialog):
        # The dialog owns the exit; a second WM_DELETE_WINDOW is ignored, and
        # releasing twice would be harmless but would muddy the log.
        calls = []
        model = AppModel()
        model.apply_poll(_running_snapshot())
        harness = CloseHarness(model=model, on_shutdown_begin=lambda: calls.append(True))

        close(harness)
        close(harness)

        assert calls == [True]

    def test_a_raising_callback_does_not_block_the_close(self):
        # Worst case of a failed release is the pre-fix behaviour; worst case of
        # letting it propagate is a window the operator cannot close.
        def boom():
            raise OSError("port file is locked")

        harness = CloseHarness(model=AppModel(), on_shutdown_begin=boom)

        close(harness)  # must not raise

        assert harness.events == ["shutdown_finished"], "the panel must still close"
        assert any(
            "release_failed" in m for m in harness._log.messages
        ), "a failed release must be diagnosable from the panel log"

    def test_close_without_a_wired_callback_still_closes(self):
        # The callback is optional: the panel must close even when nothing
        # wired it (a degraded fail-open launch binds no listener at all).
        harness = CloseHarness(model=AppModel(), on_shutdown_begin=None)

        close(harness)  # must not raise

        assert harness.events == ["shutdown_finished"]


def _running_snapshot():
    """One project whose daemon is RUNNING, as the poller would report it."""
    from linkwatcher.linkwatcher_control_panel.model import DaemonSnapshot, DaemonStatus

    return [
        DaemonSnapshot(
            project=project(),
            status=DaemonStatus.RUNNING,
            pids=[1000, 1001],
            started_at=100.0,
        )
    ]


# --------------------------------------------------------------------------- #
# The other half: what a launch arriving after the release actually gets
# --------------------------------------------------------------------------- #


class TestLaunchAfterTheClaimIsDropped:
    """Dropping the claim must yield a usable window, not a different dead end."""

    def test_a_launch_after_release_takes_ownership_cleanly(self, tmp_path):
        install_dir = tmp_path / "install"
        install_dir.mkdir()
        incumbent = SingleInstanceGuard(install_dir)
        incumbent.acquire()

        incumbent.release()  # what closing now does, before the drain finishes

        launch = SingleInstanceGuard(install_dir)
        try:
            outcome = launch.acquire()

            # Not merely "not surfaced": the port file is gone, so the launch
            # never probes at all and never reports a takeover of a live peer.
            assert outcome.already_running is False
            assert outcome.message is None
            assert outcome.warning is None
            assert outcome.port
        finally:
            launch.release()

    def test_the_released_listener_no_longer_answers(self, tmp_path):
        install_dir = tmp_path / "install"
        install_dir.mkdir()
        incumbent = SingleInstanceGuard(install_dir)
        outcome = incumbent.acquire()
        port = outcome.port

        incumbent.release()

        assert not (install_dir / PORT_FILENAME).exists()
        with pytest.raises(OSError):
            socket.create_connection(("127.0.0.1", port), timeout=1.0).close()


# --------------------------------------------------------------------------- #
# The wiring the entry script owns
# --------------------------------------------------------------------------- #


class TestEntryScriptWiring:
    """`control_panel.main` must connect the app's close to the guard's release.

    Asserted on the AST rather than the source text: a comment or docstring
    naming `guard.release` must not be able to satisfy this, and a future edit
    that only *documents* the wiring must turn it red.
    """

    @staticmethod
    def _main_ast():
        entry = Path(app_module.__file__).parents[3] / "control_panel.py"
        if not entry.exists():  # dev repo: package is an editable install
            entry = Path(__file__).parents[5] / "control_panel.py"
        assert entry.exists(), f"entry script not found at {entry}"
        tree = ast.parse(entry.read_text(encoding="utf-8"))
        main = next(
            (n for n in tree.body if isinstance(n, ast.FunctionDef) and n.name == "main"), None
        )
        assert main is not None, "control_panel.main not found"
        return main

    def test_main_wires_the_shutdown_callback_to_the_guard_release(self):
        main = self._main_ast()

        wired = [
            node
            for node in ast.walk(main)
            # app.on_shutdown_begin = guard.release  (an attribute, not a call:
            # the app calls it, the entry script only hands it over)
            if isinstance(node, ast.Assign)
            and any(
                isinstance(t, ast.Attribute) and t.attr == "on_shutdown_begin" for t in node.targets
            )
            and isinstance(node.value, ast.Attribute)
            and node.value.attr == "release"
        ]

        assert wired, (
            "control_panel.main must assign the guard's release to the app's "
            "on_shutdown_begin, or a closing panel keeps the instance slot"
        )

    def test_the_app_actually_invokes_what_the_entry_script_wires(self):
        """Both halves of the app side must be present and connected.

        The entry script hands over ``on_shutdown_begin``; the app reads it in
        ``_release_instance_claim``; ``_on_close`` calls that.  Break any link
        and the claim survives the close, which is the bug.
        """
        tree = ast.parse(Path(app_module.__file__).read_text(encoding="utf-8"))
        functions = {
            node.name: node for node in ast.walk(tree) if isinstance(node, ast.FunctionDef)
        }

        assert "_release_instance_claim" in functions
        reads = [
            node
            for node in ast.walk(functions["_release_instance_claim"])
            if isinstance(node, ast.Attribute) and node.attr == "on_shutdown_begin"
        ]
        assert reads, "_release_instance_claim must read self.on_shutdown_begin"

        calls = [
            node
            for node in ast.walk(functions["_on_close"])
            if isinstance(node, ast.Call)
            and isinstance(node.func, ast.Attribute)
            and node.func.attr == "_release_instance_claim"
        ]
        assert calls, "_on_close must drop the instance claim"


# --------------------------------------------------------------------------- #
# Thread hygiene: the release runs on the UI thread, so it must not block it
# --------------------------------------------------------------------------- #


def test_release_from_the_ui_thread_returns_promptly(tmp_path):
    """`release()` joins the listener thread; closing must not stall on it.

    The join is bounded at 1 s, but the accept loop unblocks as soon as the
    socket closes, so the real cost is microseconds.  Pinning it keeps a future
    change from turning window-close into a visible stall.
    """
    install_dir = tmp_path / "install"
    install_dir.mkdir()
    guard = SingleInstanceGuard(install_dir)
    guard.acquire()

    done = threading.Event()

    def ui_thread():
        guard.release()
        done.set()

    threading.Thread(target=ui_thread, name="fake-ui-thread", daemon=True).start()

    assert done.wait(0.5), "release blocked the calling thread for over 500 ms"
