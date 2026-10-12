"""
PD-BUG-157 Manual Validation: the panel acked "already running" without surfacing.

PURPOSE:
    A second Control Panel launch does not open a window.  It asks the running
    panel to surface over a loopback channel and exits quietly if that panel
    answers with the banner ``LINKWATCHER-PANEL OK``.  That banner is the
    launcher's ONLY evidence that a window reached the operator.

    The listener sent it in the wrong order -- before, and independently of,
    the surfacing it claimed to have performed::

        conn.sendall(PANEL_BANNER)      # ack first, unconditionally
        callback = self.on_surface
        if callback is None:
            return                      # ...already acked
        callback()                      # app.post(app.surface): enqueue only

    ``callback()`` merely enqueues the raise onto the dispatcher queue that the
    Tk mainloop drains.  So the ack proved one thing only: a LISTENER THREAD was
    alive.  It did not prove a mainloop was running, that the queue was ever
    drained, or that a window existed at all.  An incumbent whose UI was dead,
    wedged, or not yet wired absorbed every relaunch: the launcher was told
    "already running", exited 0, and no window appeared anywhere.  Deleting
    ``panel.port`` by hand was the operator's only recovery, which is why the
    defect was originally reported as a stale-port-file bug.

    The fix inverts the order: the listener runs the surface hook, waits for the
    UI thread to report that it ran, and only then sends the banner.  No
    confirmation means silence, and the launcher opens a real window instead.

    SECTION 2 covers the REWORK.  The first attempt at this fix was rejected at
    code review: it gave the wire-wait and the confirm a full budget EACH, back
    to back, so the listener could take up to 3.0 s to answer a client that
    stops listening at 2.0 s.  The launcher then timed out on a panel that WAS
    surfacing, opened a duplicate, and rewrote ``panel.port`` over the live
    incumbent -- re-creating the very running-but-unreachable state this bug
    was filed about.  Serving requests inline on the accept loop amplified it
    onto the healthy path: simultaneous launches queued behind one another's
    raise, and the last one timed out with no wedged UI anywhere.

    This script stands up REAL loopback listeners and runs the real client
    helper ``surface_existing_instance`` against each scenario, comparing the
    defective implementation with the shipped one side by side.

    "Launcher exits with no window" is the operator-visible failure, so each
    check reports whether the launcher would have been sent away.

HOW TO RUN:
    python test/bug-validation/PD-BUG-157_surface_confirmation_validation.py

TO OBSERVE THE BUG YOURSELF (UI reproduction, no code):
    1. Launch the Control Panel and confirm its window opens.
    2. Wedge its UI thread WITHOUT killing the process -- the state the bug is
       about is a live process whose window cannot be reached.  The simplest
       honest approximation: minimise the panel, then move it to another
       virtual desktop, or leave it running and log into a different session.
    3. Launch the panel again:  linkwatcher-panel.bat
    4. Against a pre-fix build the launcher prints "already running -- surfaced
       that window" and exits, and no window appears.  Against a fixed build,
       if the incumbent cannot confirm the raise within 1.5 s, a real window
       opens instead.
    5. Healthy case (must not regress): with the panel visible on the current
       desktop, launch again -- the existing window must be raised and no
       second window may appear.
    6. Rework case: launch the panel three times in quick succession while it is
       healthy.  Exactly one window must exist afterwards, and
       ``<install>/logs/panel.log`` must not contain ``stale_port_file``.

EXPECTED RESULT:
    Section 1 checks 1-3 flip FAIL -> PASS between the columns; checks 4-6 pass
    in both.  Section 2 checks 7-9 flip FAIL -> PASS.  Any FAIL in a "shipped"
    column means the fix is broken or absent.
"""

import logging
import socket
import sys
import tempfile
import threading
import time
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "src"))

from linkwatcher.linkwatcher_control_panel import single_instance as si  # noqa: E402
from linkwatcher.linkwatcher_control_panel.panel_log import get_panel_logger  # noqa: E402
from linkwatcher.linkwatcher_control_panel.single_instance import (  # noqa: E402
    SingleInstanceGuard,
    SurfaceOutcome,
)

# Short enough to keep the script snappy; only has to expire.
CONFIRM_WAIT = 0.2
BUDGET = si.SURFACE_CONFIRM_TIMEOUT_SECONDS


# --------------------------------------------------------------------------- #
# The two defective implementations, restored in-process for comparison.
# --------------------------------------------------------------------------- #
def _handle_ack_first(self, conn, peer):
    """The ORIGINAL defect: the ack precedes the action it claims to report."""
    if peer and peer[0] != si.LOOPBACK:
        return
    conn.settimeout(si.HANDSHAKE_TIMEOUT_SECONDS)
    request = conn.recv(si.MAX_REQUEST_BYTES)
    if request.strip() != si.SURFACE_TOKEN:
        return
    conn.sendall(si.PANEL_BANNER)  # <-- claimed before performed
    callback = self.on_surface
    if callback is None:
        return
    try:
        callback()
    except Exception:  # noqa: BLE001 - the old code isolated this too
        pass


def _surface_and_confirm_sequential(self):
    """The REJECTED rework: wire-wait and confirm each get a full budget."""
    deadline = time.monotonic() + BUDGET
    callback = self.on_surface
    while callback is None and time.monotonic() < deadline:
        time.sleep(si.SURFACE_READY_POLL_SECONDS)
        callback = self.on_surface
    if callback is None:
        return False
    try:
        return bool(callback())  # its own full budget, starting now
    except Exception:  # noqa: BLE001
        return False


def _surface_existing_two_state(port):
    """The pre-rework client, expressed in the current vocabulary.

    It answered with a single boolean, so "a live process is there but it would
    not confirm" and "nothing is there at all" collapsed into one value -- and
    ``acquire`` then reported both as a stale port file.  Mapping DECLINED onto
    ABSENT reproduces exactly that loss of information.
    """
    outcome = _client_shipped(port)
    return outcome if outcome is SurfaceOutcome.SURFACED else SurfaceOutcome.ABSENT


def _dispatch_inline(self, conn, peer):
    """The REJECTED rework: requests served on the accept loop, one at a time."""
    try:
        self._handle(conn, peer)
    except Exception:  # noqa: BLE001
        pass
    finally:
        try:
            conn.close()
        except OSError:
            pass


_handle_shipped = SingleInstanceGuard._handle
_confirm_shipped = SingleInstanceGuard._surface_and_confirm
_dispatch_shipped = SingleInstanceGuard._dispatch
_client_shipped = si.surface_existing_instance


# --------------------------------------------------------------------------- #
# Scenario hooks.  They accept *args so the same hook works against both the
# zero-argument (defective) and budget-taking (shipped) call conventions.
# --------------------------------------------------------------------------- #
def hook_dead_ui():
    """UI thread gone: the raise is posted and nothing ever drains the queue."""

    def _surface(*_args):
        done = threading.Event()
        return done.wait(CONFIRM_WAIT)  # never set

    return _surface


def hook_never_wired():
    return None


def hook_raises():
    def _surface(*_args):
        raise RuntimeError("UI thread is gone")

    return _surface


def hook_healthy():
    return lambda *_args: True


def hook_slow_but_healthy(cost):
    def _surface(*_args):
        time.sleep(cost)
        return True

    return _surface


# --------------------------------------------------------------------------- #
# Harness
# --------------------------------------------------------------------------- #
class Incumbent:
    """A real guard on a real loopback port, released on exit."""

    def __init__(self, hook, wire_after=None):
        self.install = Path(tempfile.mkdtemp())
        self.guard = SingleInstanceGuard(self.install)
        self.guard.on_surface = hook
        self._wire_after = wire_after

    def __enter__(self):
        self.guard.acquire()
        if self._wire_after is not None:

            def wire_later():
                time.sleep(self._wire_after)
                self.guard.on_surface = hook_healthy()

            threading.Thread(target=wire_later, daemon=True).start()
        return self

    @property
    def port(self):
        return int((self.install / si.PORT_FILENAME).read_text(encoding="utf-8").strip())

    def __exit__(self, *_exc):
        self.guard.release()
        return False


def absorbed(hook, wire_after=None):
    """Was the second launch told 'already running' (so it opened no window)?"""
    with Incumbent(hook, wire_after) as incumbent:
        return si.surface_existing_instance(incumbent.port) is SurfaceOutcome.SURFACED


def absorbed_dead_port():
    """A genuinely stale port file: nothing is listening at all."""
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.bind((si.LOOPBACK, 0))
    dead_port = sock.getsockname()[1]
    sock.close()
    return si.surface_existing_instance(dead_port) is SurfaceOutcome.SURFACED


SECTION1 = [
    ("1. Incumbent alive, Tk mainloop dead", lambda: absorbed(hook_dead_ui()), False),
    ("2. Incumbent alive, hook never wired", lambda: absorbed(hook_never_wired()), False),
    ("3. Incumbent alive, hook raises", lambda: absorbed(hook_raises()), False),
    ("4. GUARD  healthy panel (must absorb)", lambda: absorbed(hook_healthy()), True),
    ("5. GUARD  startup race, hook wired late", lambda: absorbed(None, wire_after=0.3), True),
    ("6. CONTROL genuinely stale port", absorbed_dead_port, False),
]


# --------------------------------------------------------------------------- #
# Section 2 checks -- the rework
# --------------------------------------------------------------------------- #
def check7_answer_arrives_in_time():
    """Slow-to-wire panel with a slow raise: the launcher must get an ANSWER.

    Not necessarily an ack -- a panel that cannot confirm inside its budget is
    honestly declined.  What must never happen is the launcher sitting through
    its whole handshake timeout and then taking over a live panel.
    """
    with Incumbent(None, wire_after=BUDGET * 0.8) as incumbent:
        incumbent.guard.on_surface = None

        def wire_slow():
            time.sleep(BUDGET * 0.8)
            incumbent.guard.on_surface = hook_slow_but_healthy(BUDGET * 0.6)

        threading.Thread(target=wire_slow, daemon=True).start()
        started = time.monotonic()
        si.surface_existing_instance(incumbent.port)
        elapsed = time.monotonic() - started
    return elapsed < si.HANDSHAKE_TIMEOUT_SECONDS, f"answered in {elapsed:.2f}s"


def check8_simultaneous_launches():
    """Three launches at once against a healthy panel: all three must be absorbed."""
    with Incumbent(hook_slow_but_healthy(BUDGET * 0.5)) as incumbent:
        verdicts = {}

        def launch(index):
            verdicts[index] = (
                si.surface_existing_instance(incumbent.port) is SurfaceOutcome.SURFACED
            )

        threads = [threading.Thread(target=launch, args=(i,)) for i in range(3)]
        for thread in threads:
            thread.start()
        for thread in threads:
            thread.join(timeout=10)
    absorbed_count = sum(1 for value in verdicts.values() if value)
    return absorbed_count == 3, f"{absorbed_count} of 3 absorbed"


def check9_takeover_is_reported_honestly():
    """A live panel that declined must not be logged as a stale port file."""
    captured = []

    class _Collect(logging.Handler):
        def emit(self, record):
            captured.append(record.getMessage())

    logger = get_panel_logger()
    handler = _Collect()
    previous = logger.level
    logger.addHandler(handler)
    logger.setLevel(logging.DEBUG)
    try:
        with Incumbent(hook_dead_ui()) as incumbent:
            successor = SingleInstanceGuard(incumbent.install)
            try:
                successor.acquire()
            finally:
                successor.release()
    finally:
        logger.removeHandler(handler)
        logger.setLevel(previous)

    text = " ".join(captured)
    honest = "surface_declined" in text and "stale_port_file" not in text
    claim = next(
        (m for m in captured if "stale_port_file" in m or "surface_declined" in m),
        "(nothing logged)",
    )
    return honest, claim.strip()


SECTION2 = [
    ("7. Launcher gets an answer before its timeout", check7_answer_arrives_in_time),
    ("8. Three simultaneous launches, healthy panel", check8_simultaneous_launches),
    ("9. Takeover of a live panel reported honestly", check9_takeover_is_reported_honestly),
]


def install_defective_rework():
    SingleInstanceGuard._surface_and_confirm = _surface_and_confirm_sequential
    SingleInstanceGuard._dispatch = _dispatch_inline
    si.surface_existing_instance = _surface_existing_two_state


def install_shipped():
    SingleInstanceGuard._handle = _handle_shipped
    SingleInstanceGuard._surface_and_confirm = _confirm_shipped
    SingleInstanceGuard._dispatch = _dispatch_shipped
    si.surface_existing_instance = _client_shipped


def main():
    failures = 0

    print()
    print("PD-BUG-157 -- does the panel prove it surfaced before saying so?")
    print("=" * 78)
    print()
    print("SECTION 1: the original defect (ack sent before the surface).")
    print("Each check asks: was the second launch told 'already running'?")
    print("A launcher told that exits WITHOUT opening a window.")
    print()

    SingleInstanceGuard._handle = _handle_ack_first
    before = [probe() for _label, probe, _want in SECTION1]
    install_shipped()
    after = [probe() for _label, probe, _want in SECTION1]

    header = f"{'CHECK':<46} {'ack-first':>12} {'shipped':>12}"
    print(header)
    print("-" * len(header))
    for (label, _probe, want), pre, post in zip(SECTION1, before, after):
        if post != want:
            failures += 1
        print(
            f"{label:<46} "
            f"{('PASS' if pre == want else 'FAIL'):>12} "
            f"{('PASS' if post == want else 'FAIL'):>12}"
        )

    print()
    print("  Checks 1-3 flip FAIL -> PASS: that is the original bug being fixed.")
    print("  Checks 4-6 PASS in both columns: the fix did not over-reach.")
    print()
    print("SECTION 2: the rework (one shared budget, requests served in parallel).")
    print("The rejected fix answered up to 3.0 s late, so the launcher timed out,")
    print("opened a duplicate window, and rewrote panel.port over a live panel.")
    print()

    install_defective_rework()
    rejected = [probe() for _label, probe in SECTION2]
    install_shipped()
    shipped = [probe() for _label, probe in SECTION2]

    header = f"{'CHECK':<46} {'rejected':>12} {'shipped':>12}"
    print(header)
    print("-" * len(header))
    for (label, _probe), (pre_ok, pre_note), (post_ok, post_note) in zip(
        SECTION2, rejected, shipped
    ):
        if not post_ok:
            failures += 1
        print(
            f"{label:<46} "
            f"{('PASS' if pre_ok else 'FAIL'):>12} "
            f"{('PASS' if post_ok else 'FAIL'):>12}"
        )
        print(f"{'':<46} {pre_note:>12} | {post_note}")

    print()
    print("  Checks 7-9 flip FAIL -> PASS: that is the rework.")
    print("  A FAIL in a 'shipped' column means the fix is broken or absent.")
    print()
    print(f"RESULT: {'ALL SHIPPED CHECKS PASS' if not failures else f'{failures} FAILURES'}")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
