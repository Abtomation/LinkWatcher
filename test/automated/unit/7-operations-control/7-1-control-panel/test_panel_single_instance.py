"""
Document Metadata:
ID: TE-TST-151
Type: Test File
Category: Test
Version: 1.0
Created: 2026-08-10
Updated: 2026-08-10
Component Name: single_instance
Feature Id: 7.1.1
Language: Python
Test Name: panel_single_instance
Test Type: Unit

Unit tests for the Control Panel single-instance guard
(``linkwatcher.linkwatcher_control_panel.single_instance``):

- UNIT-I1 — first launch binds a ``127.0.0.1`` ephemeral port and publishes it
  to ``panel.port``
- UNIT-I2 — second launch reads the port file, connects, sends ``SURFACE`` and
  reports "already running" instead of opening a window (EC-9/AC-11)
- UNIT-I3 — the listener fires the surface callback **exactly once** per request
- UNIT-I4 — a stale port file (nothing listening) is taken over: the new launch
  binds and rewrites the file

Plus the guard properties that keep those four honest: a recycled port owned by
an unrelated process must not be mistaken for a panel, a raising callback must
not kill the listener, and release must only delete a port file it still owns.

Sockets are **real** loopback sockets on ephemeral ports (per the test spec's
mock table) — the handshake is the behavior under test, so faking it would test
nothing.  No Tk is instantiated.
"""

import logging
import queue
import socket
import threading
import time

import pytest

from linkwatcher.linkwatcher_control_panel.panel_log import get_panel_logger
from linkwatcher.linkwatcher_control_panel.single_instance import (
    HANDSHAKE_TIMEOUT_SECONDS,
    PANEL_BANNER,
    PORT_FILENAME,
    SURFACE_CONFIRM_TIMEOUT_SECONDS,
    SURFACE_TOKEN,
    SingleInstanceGuard,
    SurfaceOutcome,
    surface_existing_instance,
)

pytestmark = [
    pytest.mark.feature("7.1.1"),
    pytest.mark.priority("Standard"),
    pytest.mark.test_type("unit"),
    pytest.mark.specification("TE-TSP-045"),
]

# Generous enough to be reliable on a loaded CI box, short enough that a real
# failure fails fast rather than hanging the suite.
WAIT_TIMEOUT_SECONDS = 5.0

# How long a simulated UI thread is given to report that it surfaced.  Kept far
# below the guard's own budget so the "dead UI" hooks resolve fast — the value
# only has to expire, not match production timing.
CONFIRM_WAIT_SECONDS = 0.2


@pytest.fixture
def install_dir(tmp_path):
    """A throwaway install directory — the guard publishes panel.port here."""
    directory = tmp_path / "install"
    directory.mkdir()
    return directory


@pytest.fixture
def guard(install_dir):
    """A guard that is always released, even when the test fails mid-way."""
    instance = SingleInstanceGuard(install_dir)
    yield instance
    instance.release()


def port_file(install_dir):
    return install_dir / PORT_FILENAME


def wait_until(predicate, timeout=WAIT_TIMEOUT_SECONDS):
    """Poll *predicate* until true or *timeout*; returns the final result.

    The listener runs on its own thread, so assertions about callbacks are
    inherently asynchronous — polling keeps them deterministic without sleeps
    that are either flaky or slow.
    """
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if predicate():
            return True
        time.sleep(0.01)
    return predicate()


def send_raw(port, payload, expect_reply=True):
    """Speak to the listener directly, bypassing the client helper."""
    with socket.create_connection(("127.0.0.1", port), timeout=WAIT_TIMEOUT_SECONDS) as sock:
        sock.settimeout(WAIT_TIMEOUT_SECONDS)
        sock.sendall(payload)
        if not expect_reply:
            return b""
        try:
            return sock.recv(len(PANEL_BANNER))
        except OSError:
            return b""


# --------------------------------------------------------------------------- #
# UNIT-I1 — first launch
# --------------------------------------------------------------------------- #


class TestFirstLaunch:
    """UNIT-I1: binds loopback ephemeral port and publishes it."""

    def test_acquire_reports_ownership_and_binds_a_port(self, guard):
        outcome = guard.acquire()

        assert outcome.already_running is False
        assert outcome.warning is None
        assert outcome.port and 0 < outcome.port < 65536
        assert guard.port == outcome.port

    def test_acquire_publishes_the_port_to_the_port_file(self, guard, install_dir):
        outcome = guard.acquire()

        assert port_file(install_dir).read_text(encoding="utf-8").strip() == str(outcome.port)

    def test_bound_port_accepts_a_loopback_connection(self, guard):
        guard.on_surface = lambda _budget: True  # a healthy panel confirms it surfaced
        outcome = guard.acquire()

        assert send_raw(outcome.port, SURFACE_TOKEN + b"\n") == PANEL_BANNER

    def test_port_file_directory_is_created_when_absent(self, tmp_path):
        missing = tmp_path / "not-yet" / "install"
        instance = SingleInstanceGuard(missing)
        try:
            outcome = instance.acquire()
            assert (missing / PORT_FILENAME).read_text(encoding="utf-8").strip() == str(
                outcome.port
            )
        finally:
            instance.release()


# --------------------------------------------------------------------------- #
# UNIT-I2 — second launch
# --------------------------------------------------------------------------- #


class TestSecondLaunch:
    """UNIT-I2: a second launch surfaces the incumbent instead of opening."""

    def test_second_guard_reports_already_running(self, install_dir, guard):
        guard.on_surface = lambda _budget: True  # a healthy incumbent confirms the surface
        first = guard.acquire()
        second = SingleInstanceGuard(install_dir)

        outcome = second.acquire()

        assert outcome.already_running is True
        assert outcome.port == first.port
        assert "already running" in outcome.message

    def test_second_launch_triggers_the_incumbents_surface_callback(self, install_dir, guard):
        calls = []

        def record(_budget):
            calls.append(1)
            return True

        guard.on_surface = record
        guard.acquire()

        SingleInstanceGuard(install_dir).acquire()

        assert wait_until(lambda: len(calls) == 1)

    def test_second_launch_leaves_the_published_port_untouched(self, install_dir, guard):
        guard.on_surface = lambda _budget: True
        first = guard.acquire()

        SingleInstanceGuard(install_dir).acquire()

        assert port_file(install_dir).read_text(encoding="utf-8").strip() == str(first.port)

    def test_second_launch_binds_no_socket_of_its_own(self, install_dir, guard):
        guard.on_surface = lambda _budget: True
        guard.acquire()
        second = SingleInstanceGuard(install_dir)

        second.acquire()

        assert second.port is None


# --------------------------------------------------------------------------- #
# UNIT-I3 — surface dispatch
# --------------------------------------------------------------------------- #


class TestSurfaceDispatch:
    """UNIT-I3: exactly one callback per SURFACE request, and never for others."""

    def test_surface_request_fires_the_callback_exactly_once(self, guard):
        calls = []

        def record(_budget):
            calls.append(1)
            return True

        guard.on_surface = record
        outcome = guard.acquire()

        assert send_raw(outcome.port, SURFACE_TOKEN + b"\n") == PANEL_BANNER

        assert wait_until(lambda: len(calls) == 1)
        # Give a duplicate dispatch a chance to show up before asserting "once".
        time.sleep(0.1)
        assert calls == [1]

    def test_each_request_fires_its_own_callback(self, guard):
        calls = []

        def record(_budget):
            calls.append(1)
            return True

        guard.on_surface = record
        outcome = guard.acquire()

        for _ in range(3):
            send_raw(outcome.port, SURFACE_TOKEN + b"\n")

        assert wait_until(lambda: len(calls) == 3)

    def test_unknown_verb_is_ignored_without_firing_the_callback(self, guard):
        calls = []
        guard.on_surface = lambda _budget: calls.append(1)
        outcome = guard.acquire()

        assert send_raw(outcome.port, b"SHUTDOWN\n") != PANEL_BANNER

        time.sleep(0.1)
        assert calls == []

    # Error isolation for a raising callback, and the not-yet-wired request, are
    # covered by TestSurfaceConfirmation below: under the PD-BUG-157 contract
    # both must ALSO decline the ack, so asserting the banner here would pin the
    # defect that fix removed.

    def test_concurrent_surface_requests_are_all_served(self, guard):
        calls = []
        lock = threading.Lock()

        def record(_budget):
            with lock:
                calls.append(1)
            return True

        guard.on_surface = record
        outcome = guard.acquire()

        threads = [
            threading.Thread(target=send_raw, args=(outcome.port, SURFACE_TOKEN + b"\n"))
            for _ in range(5)
        ]
        for thread in threads:
            thread.start()
        for thread in threads:
            thread.join(timeout=WAIT_TIMEOUT_SECONDS)

        assert wait_until(lambda: len(calls) == 5)


# --------------------------------------------------------------------------- #
# PD-BUG-157 — the ack must prove the surface, not merely request it
# --------------------------------------------------------------------------- #


def dead_ui_callback():
    """A surface hook wired to a UI thread that never drains the queue.

    Stands in for an incumbent whose Tk mainloop is gone: post the work, wait
    for the UI thread to report it ran, time out, report failure.  It caps its
    wait well below the budget the guard hands it, purely to keep the suite
    fast — the *real* hook honours the full budget, and that is pinned against
    the production code in :class:`TestSurfaceHookFactory` rather than mirrored
    here (TD312: a mirror is not the thing).
    """
    posted = queue.Queue()

    def _surface(budget=CONFIRM_WAIT_SECONDS):
        done = threading.Event()
        posted.put(done)
        return done.wait(min(budget, CONFIRM_WAIT_SECONDS))  # nothing ever sets it

    return _surface, posted


class TestSurfaceConfirmation:
    """PD-BUG-157: an incumbent that cannot surface must not claim it did.

    The banner is the client's only liveness proof.  Emitting it before — and
    independently of — the surface let a panel with a dead, blocked or unwired
    UI absorb every relaunch: the launcher exited quietly and no window ever
    appeared, with ``panel.port`` deletion the operator's only recovery.
    """

    def test_unconfirmed_surface_is_not_acked(self, guard):
        """The regression: a live listener over a dead UI must stay silent."""
        surface, posted = dead_ui_callback()
        guard.on_surface = surface
        outcome = guard.acquire()

        reply = send_raw(outcome.port, SURFACE_TOKEN + b"\n")

        assert reply != PANEL_BANNER, "acked without surfacing — PD-BUG-157"
        assert reply == b"", "an unconfirmed surface must send nothing at all"
        assert posted.qsize() == 1, "the surface must still have been attempted"

    def test_client_opens_its_own_window_when_the_incumbent_cannot_confirm(self, guard):
        """The operator-visible contract: no proof ⇒ the launcher takes over."""
        surface, _ = dead_ui_callback()
        guard.on_surface = surface
        outcome = guard.acquire()

        # This is precisely what a second launch asks before deciding to exit.
        assert surface_existing_instance(outcome.port) is SurfaceOutcome.DECLINED

    def test_raising_callback_is_not_acked_but_the_listener_survives(self, guard):
        calls = []

        def explode(_budget):
            calls.append(1)
            raise RuntimeError("UI thread is gone")

        guard.on_surface = explode
        outcome = guard.acquire()

        assert send_raw(outcome.port, SURFACE_TOKEN + b"\n") != PANEL_BANNER
        assert wait_until(lambda: len(calls) == 1)

        # Error isolation is unchanged: the next request is still served.
        guard.on_surface = lambda _budget: True
        assert send_raw(outcome.port, SURFACE_TOKEN + b"\n") == PANEL_BANNER

    def test_callback_never_wired_is_not_acked(self, guard):
        """No UI was ever attached, so there is nothing to surface."""
        outcome = guard.acquire()  # on_surface stays None for the whole budget

        assert send_raw(outcome.port, SURFACE_TOKEN + b"\n") != PANEL_BANNER

    def test_callback_wired_late_still_acks(self, guard):
        """The startup race must NOT produce a duplicate window.

        A second launch can arrive while the incumbent is still building its
        window — observed in the field at 337 ms after ``acquire``, with
        ``panel_started`` only at 632 ms.  Declining that request would open a
        second panel, so the listener waits for the hook inside its budget.
        """
        outcome = guard.acquire()  # on_surface still None

        def wire_later():
            time.sleep(0.3)
            guard.on_surface = lambda _budget: True

        threading.Thread(target=wire_later, daemon=True).start()

        assert send_raw(outcome.port, SURFACE_TOKEN + b"\n") == PANEL_BANNER

    def test_confirmed_surface_is_acked(self, guard):
        """The healthy path is unchanged."""
        guard.on_surface = lambda _budget: True
        outcome = guard.acquire()

        assert send_raw(outcome.port, SURFACE_TOKEN + b"\n") == PANEL_BANNER


# --------------------------------------------------------------------------- #
# UNIT-I4 — stale port file takeover
# --------------------------------------------------------------------------- #


class TestStalePortFile:
    """UNIT-I4: nothing listening ⇒ take over and rewrite the port file."""

    def test_stale_port_is_taken_over_and_rewritten(self, install_dir, guard):
        # A port that was bound and then released: nothing listens there now.
        probe = socket.socket()
        probe.bind(("127.0.0.1", 0))
        dead_port = probe.getsockname()[1]
        probe.close()
        port_file(install_dir).write_text(f"{dead_port}\n", encoding="utf-8")

        outcome = guard.acquire()

        assert outcome.already_running is False
        assert outcome.port != dead_port
        assert port_file(install_dir).read_text(encoding="utf-8").strip() == str(outcome.port)

    @pytest.mark.parametrize(
        "contents",
        ["", "   ", "not-a-port", "0", "-1", "99999", "12 34"],
        ids=["empty", "blank", "text", "zero", "negative", "out-of-range", "garbage"],
    )
    def test_unusable_port_file_contents_are_taken_over(self, install_dir, guard, contents):
        port_file(install_dir).write_text(contents, encoding="utf-8")

        outcome = guard.acquire()

        assert outcome.already_running is False
        assert port_file(install_dir).read_text(encoding="utf-8").strip() == str(outcome.port)

    def test_foreign_listener_on_a_recycled_port_is_not_mistaken_for_a_panel(
        self, install_dir, guard
    ):
        """An unrelated process on the recycled port must not block the panel.

        This is why the protocol requires an ack: a bare successful connect
        would read as "a panel is already running" and no window would ever
        open.
        """
        foreign = socket.socket()
        foreign.bind(("127.0.0.1", 0))
        foreign.listen(1)
        foreign_port = foreign.getsockname()[1]
        port_file(install_dir).write_text(f"{foreign_port}\n", encoding="utf-8")

        def accept_and_say_nothing():
            try:
                conn, _ = foreign.accept()
                conn.close()
            except OSError:
                pass

        responder = threading.Thread(target=accept_and_say_nothing, daemon=True)
        responder.start()
        try:
            outcome = guard.acquire()
        finally:
            foreign.close()
            responder.join(timeout=WAIT_TIMEOUT_SECONDS)

        assert outcome.already_running is False
        assert outcome.port != foreign_port

    def test_surface_existing_instance_is_false_when_nothing_listens(self):
        probe = socket.socket()
        probe.bind(("127.0.0.1", 0))
        dead_port = probe.getsockname()[1]
        probe.close()

        assert surface_existing_instance(dead_port) is SurfaceOutcome.ABSENT


# --------------------------------------------------------------------------- #
# Release — self-owned cleanup
# --------------------------------------------------------------------------- #


class TestRelease:
    """The port file is operational state; only its owner may delete it."""

    def test_release_removes_a_self_owned_port_file(self, install_dir, guard):
        guard.acquire()

        guard.release()

        assert not port_file(install_dir).exists()

    def test_release_stops_the_listener(self, install_dir, guard):
        outcome = guard.acquire()

        guard.release()

        assert surface_existing_instance(outcome.port) is SurfaceOutcome.ABSENT

    def test_release_leaves_a_successors_port_file_alone(self, install_dir, guard):
        guard.acquire()
        # A successor took the file over (the guard's own port is now stale).
        port_file(install_dir).write_text("54321\n", encoding="utf-8")

        guard.release()

        assert port_file(install_dir).read_text(encoding="utf-8").strip() == "54321"

    def test_release_is_idempotent(self, install_dir, guard):
        guard.acquire()

        guard.release()
        guard.release()  # must not raise

        assert not port_file(install_dir).exists()

    def test_release_without_acquire_is_a_no_op(self, guard):
        guard.release()  # must not raise

        assert guard.port is None


# --------------------------------------------------------------------------- #
# PD-BUG-157 rework — one response budget, bounded by the client's timeout
# --------------------------------------------------------------------------- #


@pytest.fixture
def panel_log_records():
    """Collect panel-logger messages regardless of propagation settings.

    ``configure_panel_logging`` turns propagation off, so ``caplog`` cannot be
    relied on here; attaching a handler to the panel logger itself is immune to
    whatever another test left configured.
    """
    records = []

    class _Collect(logging.Handler):
        def emit(self, record):
            records.append(record.getMessage())

    logger = get_panel_logger()
    handler = _Collect()
    previous_level = logger.level
    logger.addHandler(handler)
    logger.setLevel(logging.DEBUG)
    try:
        yield records
    finally:
        logger.removeHandler(handler)
        logger.setLevel(previous_level)


def handshake(port, timeout=HANDSHAKE_TIMEOUT_SECONDS):
    """Speak the client half of the protocol; return (acked, elapsed).

    A local twin of :func:`surface_existing_instance` for tests that need the
    *server's* timing measured against the client budget, without coupling to
    how the client reports its verdict.
    """
    started = time.monotonic()
    try:
        with socket.create_connection(("127.0.0.1", port), timeout=timeout) as sock:
            sock.settimeout(timeout)
            sock.sendall(SURFACE_TOKEN + b"\n")
            reply = sock.recv(len(PANEL_BANNER))
    except OSError:
        reply = b""
    return reply == PANEL_BANNER, time.monotonic() - started


class TestResponseBudget:
    """The confirm budget must be bounded BY the client handshake timeout.

    The first PD-BUG-157 fix spent up to a full ``SURFACE_CONFIRM_TIMEOUT_SECONDS``
    waiting for the hook to be wired and *then* handed the hook its own full
    budget, so the two waits ran back to back — up to 3.0 s against a client
    that stops listening at 2.0 s.  Both waits were individually inside budget,
    which is why the sum went unnoticed.  A launch that timed out went on to
    rewrite ``panel.port`` and orphan a live incumbent: the same
    running-but-unreachable class this bug was filed about, re-entered through
    the decline path the fix introduced.
    """

    def test_server_answers_before_the_client_stops_listening(self, guard):
        """Measured pre-fix: 2.02 s against a 2.0 s client timeout."""
        outcome = guard.acquire()  # on_surface deliberately not wired yet

        def wire_later():
            time.sleep(SURFACE_CONFIRM_TIMEOUT_SECONDS * 0.8)

            def slow_raise(*_budget):
                time.sleep(SURFACE_CONFIRM_TIMEOUT_SECONDS * 0.6)
                return True

            guard.on_surface = slow_raise

        threading.Thread(target=wire_later, daemon=True).start()

        _acked, elapsed = handshake(outcome.port)

        assert elapsed < HANDSHAKE_TIMEOUT_SECONDS, (
            f"the server answered after {elapsed:.2f}s; the client gives up at "
            f"{HANDSHAKE_TIMEOUT_SECONDS}s, opens a duplicate window, and "
            f"rewrites panel.port over a live incumbent"
        )

    def test_the_hook_is_given_only_the_budget_that_is_left(self, guard):
        """One deadline, shared: whatever the wire-wait spends, the hook loses."""
        seen = []
        outcome = guard.acquire()
        spent_waiting = SURFACE_CONFIRM_TIMEOUT_SECONDS * 0.4

        def wire_later():
            time.sleep(spent_waiting)
            guard.on_surface = lambda budget: (seen.append(budget), True)[1]

        threading.Thread(target=wire_later, daemon=True).start()
        send_raw(outcome.port, SURFACE_TOKEN + b"\n")

        assert wait_until(lambda: seen), "the hook was never handed a budget"
        assert 0 < seen[0] < SURFACE_CONFIRM_TIMEOUT_SECONDS - spent_waiting * 0.5, (
            f"hook received {seen[0]:.2f}s after {spent_waiting:.2f}s was already "
            f"spent waiting for it to be wired — the budget is not shared"
        )


class TestConcurrentLaunches:
    """A healthy panel must not lose a launch to the accept loop.

    ``_handle`` ran inline on the accept loop, so simultaneous launches queued
    behind one another and each waited out every raise before it.  Measured: a
    healthy incumbent taking 0.8 s to raise, three simultaneous launches, one
    declined at exactly the 2.0 s client timeout — no wedged UI anywhere.
    """

    def test_a_healthy_incumbent_acks_every_simultaneous_launch(self, guard):
        raise_cost = SURFACE_CONFIRM_TIMEOUT_SECONDS * 0.5

        def slow_but_healthy(*_budget):
            time.sleep(raise_cost)
            return True

        guard.on_surface = slow_but_healthy
        outcome = guard.acquire()

        verdicts = {}

        def launch(index):
            verdicts[index] = handshake(outcome.port)[0]

        threads = [threading.Thread(target=launch, args=(i,)) for i in range(3)]
        for thread in threads:
            thread.start()
        for thread in threads:
            thread.join(timeout=WAIT_TIMEOUT_SECONDS)

        assert verdicts == {
            0: True,
            1: True,
            2: True,
        }, f"a healthy panel declined a launch it could serve: {verdicts}"


class TestTakeoverIsReportedHonestly:
    """A live panel that declined is not a stale port file.

    Both cases end in a takeover, but they are different events and the log is
    where the operator tells them apart: nothing listening means the previous
    panel died, while a live process that would not confirm means a second
    window now exists and the incumbent is no longer reachable through
    ``panel.port``.
    """

    def test_a_declining_live_panel_is_distinguished_from_an_empty_port(self, guard):
        surface, _posted = dead_ui_callback()
        guard.on_surface = surface
        live_but_declining = guard.acquire().port

        probe = socket.socket()
        probe.bind(("127.0.0.1", 0))
        nothing_there = probe.getsockname()[1]
        probe.close()

        assert surface_existing_instance(live_but_declining) != surface_existing_instance(
            nothing_there
        ), "a live panel that declined is indistinguishable from a dead port"

    def test_a_peer_that_accepts_and_never_answers_is_declined_not_absent(self):
        """The handshake times out rather than ending in EOF.

        A peer can hold the connection open and say nothing — a wedged process,
        or an unrelated one that inherited a recycled port.  The connect
        succeeded, so something is genuinely there; reporting that as ABSENT
        would put "the previous panel died" in the log for a port that is still
        occupied.
        """
        silent = socket.socket()
        silent.bind(("127.0.0.1", 0))
        silent.listen(1)
        port = silent.getsockname()[1]
        held = []

        def accept_and_stall():
            try:
                conn, _peer = silent.accept()
                held.append(conn)  # kept open: no reply, no EOF
            except OSError:
                pass

        stall = threading.Thread(target=accept_and_stall, daemon=True)
        stall.start()
        try:
            assert surface_existing_instance(port) is SurfaceOutcome.DECLINED
        finally:
            for conn in held:
                conn.close()
            silent.close()
            stall.join(timeout=WAIT_TIMEOUT_SECONDS)

    def test_acquire_does_not_report_a_stale_port_file_for_a_live_panel(
        self, install_dir, guard, panel_log_records
    ):
        surface, _posted = dead_ui_callback()
        guard.on_surface = surface
        guard.acquire()  # publishes its own port; its UI cannot confirm

        successor = SingleInstanceGuard(install_dir)
        try:
            successor.acquire()
        finally:
            successor.release()

        messages = " ".join(panel_log_records)
        assert "stale_port_file" not in messages, (
            "a live panel that declined was reported as a stale port file — " "false on both counts"
        )
        assert "surface_declined" in messages


class FakeApp:
    """A ControlPanelApp stand-in whose dispatcher queue the test drives by hand."""

    def __init__(self):
        self.queued = []
        self.raised = 0

    def post(self, callback):
        self.queued.append(callback)

    def surface(self):
        # Returns True like the real ``ControlPanelApp.surface``: a stand-in
        # that reported nothing is what hid PD-BUG-159, since a hook gating on
        # the outcome and a hook ignoring it looked identical through it.
        self.raised += 1
        return True

    def drain(self):
        pending, self.queued = self.queued, []
        for callback in pending:
            callback()


class TestSurfaceHookFactory:
    """TD312: pin the ``on_surface`` contract at the site that implements it.

    The production hook was a closure inside ``control_panel.main()``, which no
    test could reach, so the suite covered it with an analogue instead —
    verified at review: regressing the real closure to return ``None`` left
    every test green while every relaunch would open a duplicate window.
    """

    def test_hook_declines_when_the_ui_thread_never_drains(self):
        from linkwatcher.linkwatcher_control_panel.app import make_surface_hook

        app = FakeApp()
        hook = make_surface_hook(app)

        assert hook(CONFIRM_WAIT_SECONDS) is False
        assert app.queued, "the raise must still have been posted"
        assert app.raised == 0

    def test_hook_confirms_once_the_ui_thread_raises_the_window(self):
        from linkwatcher.linkwatcher_control_panel.app import make_surface_hook

        app = FakeApp()
        hook = make_surface_hook(app)

        def drain_soon():
            time.sleep(0.05)
            app.drain()

        threading.Thread(target=drain_soon, daemon=True).start()

        assert hook(WAIT_TIMEOUT_SECONDS) is True
        assert app.raised == 1

    def test_hook_does_not_raise_the_window_after_its_budget_expires(self):
        """The launcher already gave up and opened its own window."""
        app = FakeApp()
        from linkwatcher.linkwatcher_control_panel.app import make_surface_hook

        hook = make_surface_hook(app)

        assert hook(CONFIRM_WAIT_SECONDS) is False
        # Draining the instant the hook returns is a coin flip: Event.wait can
        # come back a hair early against the clock the hook reads, and the raise
        # then lands just inside its deadline.  Wait past it unambiguously —
        # the case under test is a UI thread that drains *late*, not one that
        # drains at the boundary.
        time.sleep(CONFIRM_WAIT_SECONDS)
        app.drain()  # the UI thread finally gets around to it

        assert app.raised == 0, "raised a window the launcher stopped waiting for"


class ScriptedRoot:
    """A Tk root stand-in whose window commands are scripted per test.

    No real ``tk.Tk()`` is built (this file instantiates no Tk): the case under
    test — every window command raising, which is the state of a root after
    ``destroy()`` — is reachable without one.  ``attempts`` records that the
    raise was actually tried, so a test cannot pass because the raise was never
    reached.
    """

    def __init__(self, *, raises=False, winfo_id_raises=False):
        self.raises = raises
        self.winfo_id_raises = winfo_id_raises
        self.attempts = 0
        self.deiconified = False
        self.lifted = False
        self.focused = False

    def _guard(self):
        if self.raises:
            raise RuntimeError('can\'t invoke "deiconify" command: application has been destroyed')

    def deiconify(self):
        self.attempts += 1
        self._guard()
        self.deiconified = True

    def lift(self):
        self._guard()
        self.lifted = True

    def focus_force(self):
        self._guard()
        self.focused = True

    def winfo_id(self):
        if self.winfo_id_raises:
            raise RuntimeError("winfo_id on a root that is going away")
        return 0


def real_surface_app(root):
    """An app stand-in carrying the **real** ``ControlPanelApp.surface``.

    ``FakeApp.surface`` above can never fail, so no test built on it can tell a
    hook that reports the raise *outcome* from one that reports only that the UI
    thread ran (PD-BUG-159).  These cases therefore run the production method.

    ``post`` executes inline — a UI thread that drains immediately.  That keeps
    the declining case deterministic: with a queue plus a drainer thread, a hook
    that returns False because its budget expired is indistinguishable from one
    that returns False because the raise threw.
    """
    from linkwatcher.linkwatcher_control_panel.app import ControlPanelApp

    class RealSurfaceApp(FakeApp):
        surface = ControlPanelApp.surface
        _request_foreground = ControlPanelApp._request_foreground

        def post(self, callback):
            callback()

    app = RealSurfaceApp()
    app.root = root
    app._log = get_panel_logger()
    return app


class TestSurfaceReportsItsOutcome:
    """PD-BUG-159: a raise that threw must not be acked as a surfaced window.

    ``ControlPanelApp.surface`` swallows every exception — it must, since
    surfacing may never kill the panel — but it used to return ``None`` on both
    paths, and ``raise_window`` set its event regardless.  A raise that threw
    therefore returned True from the hook, the listener sent the banner, and the
    launching process exited with no window while the same panel logged
    ``surface_failed``.  The contract in ``single_instance`` says True means the
    window has actually been raised.
    """

    def test_surface_reports_success_when_the_window_raises(self):
        """The discriminating control: without it, always-False also passes."""
        app = real_surface_app(ScriptedRoot())

        assert app.surface() is True
        assert app.root.deiconified
        assert app.root.lifted
        assert app.root.focused

    def test_surface_reports_failure_when_the_raise_throws(self, panel_log_records):
        app = real_surface_app(ScriptedRoot(raises=True))

        assert app.surface() is False
        assert app.root.attempts == 1, "the raise was never attempted"
        assert any("surface_failed" in message for message in panel_log_records), (
            "the failure must stay diagnosable in the panel log — reporting it "
            "to the caller replaces the silence, not the log line"
        )

    def test_surface_still_succeeds_when_the_foreground_grab_is_refused(self):
        """A refused foreground grab is the documented floor (TDD §4.5).

        The window is on screen; only the activation was denied, which presents
        as a flashing taskbar button.  That must keep reporting success, or the
        listener declines an ack for a panel the operator can see.

        ``_request_foreground`` is a no-op off Windows, so elsewhere this passes
        without exercising the swallow it pins.
        """
        app = real_surface_app(ScriptedRoot(winfo_id_raises=True))

        assert app.surface() is True
        assert app.root.deiconified

    def test_hook_declines_when_the_raise_throws_on_the_ui_thread(self):
        """The bug as the launcher meets it, through the production hook."""
        from linkwatcher.linkwatcher_control_panel.app import make_surface_hook

        app = real_surface_app(ScriptedRoot(raises=True))
        hook = make_surface_hook(app)

        assert hook(CONFIRM_WAIT_SECONDS) is False
        assert app.root.attempts == 1, (
            "declined for the wrong reason — the raise was never attempted, so "
            "this pins the budget path, not the failing-raise path"
        )

    def test_hook_confirms_when_the_real_surface_raises_the_window(self):
        """Control for the case above, through the same production hook."""
        from linkwatcher.linkwatcher_control_panel.app import make_surface_hook

        app = real_surface_app(ScriptedRoot())
        hook = make_surface_hook(app)

        assert hook(WAIT_TIMEOUT_SECONDS) is True
        assert app.root.deiconified
