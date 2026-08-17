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

import socket
import threading
import time

import pytest

from linkwatcher.linkwatcher_control_panel.single_instance import (
    PANEL_BANNER,
    PORT_FILENAME,
    SURFACE_TOKEN,
    SingleInstanceGuard,
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
        first = guard.acquire()
        second = SingleInstanceGuard(install_dir)

        outcome = second.acquire()

        assert outcome.already_running is True
        assert outcome.port == first.port
        assert "already running" in outcome.message

    def test_second_launch_triggers_the_incumbents_surface_callback(self, install_dir, guard):
        calls = []
        guard.on_surface = lambda: calls.append(1)
        guard.acquire()

        SingleInstanceGuard(install_dir).acquire()

        assert wait_until(lambda: len(calls) == 1)

    def test_second_launch_leaves_the_published_port_untouched(self, install_dir, guard):
        first = guard.acquire()

        SingleInstanceGuard(install_dir).acquire()

        assert port_file(install_dir).read_text(encoding="utf-8").strip() == str(first.port)

    def test_second_launch_binds_no_socket_of_its_own(self, install_dir, guard):
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
        guard.on_surface = lambda: calls.append(1)
        outcome = guard.acquire()

        assert send_raw(outcome.port, SURFACE_TOKEN + b"\n") == PANEL_BANNER

        assert wait_until(lambda: len(calls) == 1)
        # Give a duplicate dispatch a chance to show up before asserting "once".
        time.sleep(0.1)
        assert calls == [1]

    def test_each_request_fires_its_own_callback(self, guard):
        calls = []
        guard.on_surface = lambda: calls.append(1)
        outcome = guard.acquire()

        for _ in range(3):
            send_raw(outcome.port, SURFACE_TOKEN + b"\n")

        assert wait_until(lambda: len(calls) == 3)

    def test_unknown_verb_is_ignored_without_firing_the_callback(self, guard):
        calls = []
        guard.on_surface = lambda: calls.append(1)
        outcome = guard.acquire()

        assert send_raw(outcome.port, b"SHUTDOWN\n") != PANEL_BANNER

        time.sleep(0.1)
        assert calls == []

    def test_listener_survives_a_raising_callback(self, guard):
        calls = []

        def explode():
            calls.append(1)
            raise RuntimeError("surface handler blew up")

        guard.on_surface = explode
        outcome = guard.acquire()

        send_raw(outcome.port, SURFACE_TOKEN + b"\n")
        assert wait_until(lambda: len(calls) == 1)

        # The listener must still serve the next request (error isolation).
        assert send_raw(outcome.port, SURFACE_TOKEN + b"\n") == PANEL_BANNER
        assert wait_until(lambda: len(calls) == 2)

    def test_request_before_a_callback_is_wired_still_acks(self, guard):
        outcome = guard.acquire()  # on_surface still None

        assert send_raw(outcome.port, SURFACE_TOKEN + b"\n") == PANEL_BANNER

    def test_concurrent_surface_requests_are_all_served(self, guard):
        calls = []
        lock = threading.Lock()

        def record():
            with lock:
                calls.append(1)

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

        assert surface_existing_instance(dead_port) is False


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

        assert surface_existing_instance(outcome.port) is False

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
