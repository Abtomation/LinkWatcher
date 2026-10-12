"""
Single-instance guard and surface channel for the LinkWatcher Control Panel.

One mechanism serves two requirements (TDD §4.5, KR-04 / D-T3): exactly one
panel window exists (FDD EC-9), and a second launch — manual or hook auto-open
— *surfaces* the existing window instead of opening a duplicate (FDD AC-11).

Protocol
--------
The running instance binds a ``127.0.0.1`` TCP socket on an **ephemeral** port
and publishes that port to ``<install_dir>/panel.port``.  A later launch reads
the file and connects:

    client → ``SURFACE\\n``
    server → ``LINKWATCHER-PANEL OK\\n``

Only a peer that answers with that exact banner is accepted as a live panel.
The handshake is what makes "connect failure ⇒ stale port file" trustworthy:
ephemeral ports get recycled, so a stale file can point at a port some
*unrelated* process now owns.  Without the ack, a bare successful connect would
be read as "a panel is already running" and the real panel would never open.

The banner is sent **after** the window has actually surfaced, never before
(PD-BUG-157).  It is the client's only evidence that a window reached the
operator, so an incumbent whose UI thread is dead, blocked, or not yet wired
stays silent and lets the caller open a real window.  Acking first made a
process that merely *had a listener thread* indistinguishable from a usable
panel, and every relaunch was absorbed with no window and no error.

AI Context
----------
- **Entry point**: :meth:`SingleInstanceGuard.acquire` — returns an
  :class:`InstanceOutcome`.  ``already_running`` True means the caller must exit
  quietly (the existing window has been asked to surface); False means this
  process owns the instance and must call :meth:`SingleInstanceGuard.release`
  on the way out.
- **Threading**: the listener runs on its own daemon thread and never touches Tk
  or the model.  Each request is served on a further short-lived thread, so
  simultaneous launches are answered in parallel rather than queueing behind
  one another's raise.  A request invokes ``on_surface`` — which callers set to
  ``app.make_surface_hook(app)``, a closure that posts through
  ``ControlPanelApp.post(...)`` and waits for the UI thread to report back — so
  surfacing lands on the UI thread through the same dispatcher queue every
  worker uses (TDD §4.3), and the listener learns whether it happened.  The
  hook is given the remaining confirm budget and returns True only once the
  window has been raised.
- **Fail-open**: a bind failure (no loopback, sandbox, exhausted ports) must not
  stop the operator getting a panel.  ``acquire`` then reports
  ``already_running=False`` with a ``warning`` and no listener — one window with
  no single-instance protection beats no window at all.
- **Self-owned cleanup**: ``release`` deletes ``panel.port`` only when it still
  holds *this* instance's port — the same self-owned-resource rule the daemon
  applies to ``.linkwatcher.lock`` (§4.4), so a successor that already took the
  file over is never disturbed.
"""

from __future__ import annotations

import os
import socket
import threading
import time
from dataclasses import dataclass
from enum import Enum
from pathlib import Path
from typing import Callable, Optional

from .panel_log import get_panel_logger

# Published beside main.py / control_panel.py in the install directory.
PORT_FILENAME = "panel.port"

# The one verb the listener accepts, and the banner that proves the peer is a
# LinkWatcher panel rather than an unrelated process on a recycled port.
SURFACE_TOKEN = b"SURFACE"
PANEL_BANNER = b"LINKWATCHER-PANEL OK\n"

# The listener is a fixed one-verb protocol: never read more than a short line,
# so a chatty or hostile peer cannot make the panel allocate.
MAX_REQUEST_BYTES = 64

# Loopback only — the socket must not be reachable off-host (TDD §4.7 security).
LOOPBACK = "127.0.0.1"

# A local handshake is sub-millisecond; these bound the pathological cases
# (a peer that connects and then goes silent) without a perceptible delay.
CONNECT_TIMEOUT_SECONDS = 1.0
HANDSHAKE_TIMEOUT_SECONDS = 2.0

# The incumbent must prove it surfaced before it acks (PD-BUG-157).  Bounded
# *below* HANDSHAKE_TIMEOUT_SECONDS so a panel that cannot confirm declines
# while the client is still listening, leaving it time to open its own window
# rather than time out.  The budget also covers a panel still building its
# window: a second launch can arrive before ``on_surface`` is wired (observed
# in the field 337 ms after acquire, with the window ready at 632 ms), and
# refusing that request would open a duplicate panel.
SURFACE_CONFIRM_TIMEOUT_SECONDS = 1.5

# How often the listener re-checks for a surface hook that is not wired yet.
SURFACE_READY_POLL_SECONDS = 0.02

# Surface requests are served on their own short-lived threads so simultaneous
# launches do not queue behind one another's raise (each would then wait out
# every raise before it, and the last would time out against the client's
# handshake budget on a perfectly healthy panel).  Capped at the listen backlog
# so a misbehaving loopback peer cannot spawn threads without bound.
MAX_CONCURRENT_SURFACE_REQUESTS = 8


@dataclass
class InstanceOutcome:
    """Result of :meth:`SingleInstanceGuard.acquire`.

    ``already_running`` is the only field the caller must branch on:

    - ``True``  → another panel answered the handshake and was asked to
      surface; this process should exit quietly (``message`` explains why).
    - ``False`` → this process owns the instance.  ``port`` is the listener
      port when one was bound, or ``None`` in the degraded fail-open case,
      where ``warning`` says what went wrong.
    """

    already_running: bool
    port: Optional[int] = None
    message: Optional[str] = None
    warning: Optional[str] = None


def _read_published_port(port_file: Path) -> Optional[int]:
    """Return the port recorded in *port_file*, or ``None`` if unusable.

    Missing, empty, non-numeric and out-of-range contents are all just "no
    usable predecessor" — the file is operational state written by a previous
    run, so it is parsed defensively and never trusted.
    """
    try:
        raw = port_file.read_text(encoding="utf-8").strip()
    except OSError:
        return None
    try:
        port = int(raw)
    except ValueError:
        return None
    return port if 0 < port < 65536 else None


def _write_published_port(port_file: Path, port: int) -> None:
    """Publish *port* atomically (temp file in the same dir + ``os.replace``).

    Atomic so a concurrent reader never sees a half-written or truncated file;
    same-directory temp so the replace stays on one filesystem.
    """
    port_file.parent.mkdir(parents=True, exist_ok=True)
    temp_path = port_file.with_name(f"{port_file.name}.{os.getpid()}.tmp")
    try:
        temp_path.write_text(f"{port}\n", encoding="utf-8")
        os.replace(temp_path, port_file)
    finally:
        try:
            temp_path.unlink()
        except OSError:
            pass  # already replaced (the success path) or never created


class SurfaceOutcome(Enum):
    """What a launch found at the published port.

    ``DECLINED`` and ``ABSENT`` both end in a takeover, but they are different
    events and the operator reads the log to tell them apart: ``ABSENT`` means
    the previous panel died and its port file outlived it, while ``DECLINED``
    means a live process is still there and a *second* window is about to
    exist, with the incumbent no longer reachable through ``panel.port``.
    Collapsing the two into one boolean made the second case report itself as
    the first, which is false on both counts (PD-BUG-157).
    """

    SURFACED = "surfaced"
    DECLINED = "declined"
    ABSENT = "absent"


def surface_existing_instance(port: int) -> SurfaceOutcome:
    """Ask the panel listening on *port* to surface and report what happened.

    - ``SURFACED`` — a panel answered the banner handshake; it raised a window.
    - ``DECLINED`` — something is listening but did not confirm: a panel whose
      UI is dead, blocked or over budget, or an unrelated process that
      inherited a recycled port.
    - ``ABSENT`` — nothing is listening at all; the port file is stale.
    """
    # The discriminator is whether the *connection was established*, not which
    # error came back.  Windows reports a closed loopback port as a connect
    # ``TimeoutError`` rather than ``ConnectionRefusedError``, so classifying by
    # exception type reads "nothing there" as "a live peer declined".  A
    # completed connect means some process holds that port; only then can a
    # missing ack mean a panel that would not confirm.
    try:
        sock = socket.create_connection((LOOPBACK, port), timeout=CONNECT_TIMEOUT_SECONDS)
    except OSError:
        return SurfaceOutcome.ABSENT  # nothing accepted the connection
    with sock:
        sock.settimeout(HANDSHAKE_TIMEOUT_SECONDS)
        try:
            sock.sendall(SURFACE_TOKEN + b"\n")
            reply = sock.recv(len(PANEL_BANNER))
        except OSError:
            return SurfaceOutcome.DECLINED  # a live peer that never answered
    return SurfaceOutcome.SURFACED if reply == PANEL_BANNER else SurfaceOutcome.DECLINED


class SingleInstanceGuard:
    """Owns the loopback listener, the ``panel.port`` file, and the surface hook.

    Typical use from the entry script::

        guard = SingleInstanceGuard(install_dir)
        outcome = guard.acquire()
        if outcome.already_running:
            return                      # existing window was surfaced
        app = ControlPanelApp(...)
        guard.on_surface = make_surface_hook(app)
        try:
            app.run()
        finally:
            guard.release()

    ``on_surface`` is a mutable attribute rather than a constructor argument
    because the listener must be bound *before* the Tk window exists (so a
    losing launch can be told to exit without a window ever being built).  It
    takes the seconds of budget it may spend and returns True once the window
    has actually been raised on the UI thread; anything falsy means "not
    surfaced", and the listener then declines to ack.  Wiring it to something
    that merely *queues* the raise — the pre-PD-BUG-157 ``lambda:
    app.post(app.surface)`` — declines every request, because ``post`` returns
    ``None``; use :func:`~.app.make_surface_hook`, which waits for the UI
    thread to report back.

    A SURFACE arriving before the hook is assigned is *waited for* rather than
    dropped: the panel is opening anyway, and declining would open a second
    one.  That wait and the hook's own share **one** deadline of
    ``SURFACE_CONFIRM_TIMEOUT_SECONDS``, so the total stays under the client's
    ``HANDSHAKE_TIMEOUT_SECONDS`` however the budget is split between them.
    """

    def __init__(self, install_dir, on_surface: Optional[Callable[[float], bool]] = None):
        self.install_dir = Path(install_dir)
        self.port_file = self.install_dir / PORT_FILENAME
        self.on_surface = on_surface
        self.port: Optional[int] = None
        self._server: Optional[socket.socket] = None
        self._thread: Optional[threading.Thread] = None
        self._stopping = threading.Event()
        self._request_slots = threading.BoundedSemaphore(MAX_CONCURRENT_SURFACE_REQUESTS)
        self._log = get_panel_logger()

    # ------------------------------------------------------------------ #
    # Acquisition
    # ------------------------------------------------------------------ #
    def acquire(self) -> InstanceOutcome:
        """Claim the single-instance slot, or surface the incumbent.

        Order matters: a live incumbent is detected *before* binding, so the
        normal second-launch path never disturbs the published port file.
        """
        published = _read_published_port(self.port_file)
        found = surface_existing_instance(published) if published is not None else None
        if found is SurfaceOutcome.SURFACED:
            self._log.info("single_instance surfaced_existing port=%s", published)
            return InstanceOutcome(
                already_running=True,
                port=published,
                message="LinkWatcher Control Panel is already running — surfaced that window.",
            )

        if found is SurfaceOutcome.DECLINED:
            # Not a stale file: a live process is still on that port.  Taking
            # over is right — an incumbent that cannot show a window is no use
            # to the operator — but say what actually happened, because a
            # second window now exists and the incumbent has just lost its
            # route back (PD-BUG-157).
            self._log.warning(
                "single_instance surface_declined port=%s "
                "(live process did not confirm a window; taking over — a second "
                "panel window will now exist and the incumbent is unreachable)",
                published,
            )
        elif found is SurfaceOutcome.ABSENT:
            self._log.info("single_instance stale_port_file port=%s (taking over)", published)

        try:
            server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            server.bind((LOOPBACK, 0))
            server.listen(8)
        except OSError as exc:
            # Fail open: no single-instance protection is better than no panel.
            self._log.warning("single_instance bind_failed: %s (continuing unguarded)", exc)
            return InstanceOutcome(
                already_running=False,
                warning=f"single-instance socket unavailable ({exc}); duplicate windows are possible",
            )

        self._server = server
        self.port = server.getsockname()[1]
        self._thread = threading.Thread(
            target=self._serve, name="lw-panel-surface-listener", daemon=True
        )
        self._thread.start()

        try:
            _write_published_port(self.port_file, self.port)
        except OSError as exc:
            # The listener is live but unreachable by a later launch; the panel
            # still works, so warn rather than fail.
            self._log.warning("single_instance port_file_write_failed: %s", exc)
            return InstanceOutcome(
                already_running=False,
                port=self.port,
                warning=f"could not write {self.port_file} ({exc}); duplicate windows are possible",
            )

        self._log.info("single_instance acquired port=%s", self.port)
        return InstanceOutcome(already_running=False, port=self.port)

    # ------------------------------------------------------------------ #
    # Listener
    # ------------------------------------------------------------------ #
    def _serve(self) -> None:
        """Accept loop: hand each connection to its own short-lived thread.

        The accept loop must not *serve* requests, only accept them.  Serving
        inline made simultaneous launches queue behind one another: each waited
        out every raise before it, so on a healthy panel with a slow raise the
        last launch timed out against the client handshake budget and opened a
        duplicate window (PD-BUG-157).

        Every failure is contained per request — a bad peer, a dropped
        connection, or a raising callback must never take down the listener or
        the panel (per-surface error isolation, TDD §3.3).
        """
        while not self._stopping.is_set():
            try:
                conn, peer = self._server.accept()
            except OSError:
                break  # socket closed by release(), or unrecoverable — stop
            self._dispatch(conn, peer)

    def _dispatch(self, conn: socket.socket, peer) -> None:
        """Serve one connection off the accept loop, within the concurrency cap."""
        if not self._request_slots.acquire(blocking=False):
            # Pathological, and safe: the caller hears silence and opens its
            # own window rather than waiting on a listener that is saturated.
            self._log.warning("single_instance surface_requests_saturated (declining)")
            self._close(conn)
            return
        try:
            threading.Thread(
                target=self._serve_one,
                args=(conn, peer),
                name="lw-panel-surface-request",
                daemon=True,
            ).start()
        except RuntimeError:  # thread creation failed — release the slot we took
            self._request_slots.release()
            self._log.exception("single_instance request_thread_failed")
            self._close(conn)

    def _serve_one(self, conn: socket.socket, peer) -> None:
        """Run one request to completion and always give the slot back."""
        try:
            self._handle(conn, peer)
        except Exception:  # noqa: BLE001 - one bad peer never stops the listener
            self._log.exception("single_instance request_failed")
        finally:
            self._request_slots.release()
            self._close(conn)

    @staticmethod
    def _close(conn: socket.socket) -> None:
        try:
            conn.close()
        except OSError:
            pass

    def _handle(self, conn: socket.socket, peer) -> None:
        """Serve one connection: verify, surface, and ack only if that worked.

        The ack is the client's *only* evidence that a window reached the
        operator, so it must follow the surface rather than precede it
        (PD-BUG-157).  Acking first let an incumbent whose UI thread was dead,
        blocked or not yet wired absorb every relaunch: the launcher exited
        quietly, no window ever appeared, and deleting ``panel.port`` by hand
        was the only recovery.  Silence is the honest answer — the client reads
        it as "no live panel here" and opens its own window.
        """
        if peer and peer[0] != LOOPBACK:
            return  # defence in depth; the bind already restricts to loopback
        conn.settimeout(HANDSHAKE_TIMEOUT_SECONDS)
        request = conn.recv(MAX_REQUEST_BYTES)
        if request.strip() != SURFACE_TOKEN:
            return  # unknown verb — the protocol accepts nothing else
        if not self._surface_and_confirm():
            self._log.warning("single_instance surface_unconfirmed (declining ack)")
            return
        conn.sendall(PANEL_BANNER)

    def _surface_and_confirm(self) -> bool:
        """Run the surface hook and report whether it actually surfaced.

        ``on_surface`` returns True once the window has been raised on the UI
        thread.  A hook that is not wired yet is waited for, so a panel still
        building its window keeps its claim on the instance instead of being
        displaced by a duplicate.

        Both waits share **one** deadline.  Giving each its own full budget
        made them additive — up to twice ``SURFACE_CONFIRM_TIMEOUT_SECONDS``,
        which overruns the client's ``HANDSHAKE_TIMEOUT_SECONDS`` even though
        each wait is individually inside budget.  The client then gave up on a
        panel that *was* surfacing, opened a duplicate, and rewrote
        ``panel.port`` over the live incumbent (PD-BUG-157).
        """
        deadline = time.monotonic() + SURFACE_CONFIRM_TIMEOUT_SECONDS
        callback = self.on_surface
        while callback is None and time.monotonic() < deadline:
            time.sleep(SURFACE_READY_POLL_SECONDS)
            callback = self.on_surface
        if callback is None:
            return False  # no UI was ever attached — nothing can surface
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            return False  # the whole budget went on waiting for the UI to wire up
        self._log.info("single_instance surface_requested")
        return self._run_within(callback, remaining)

    def _run_within(self, callback: Callable[[float], bool], budget: float) -> bool:
        """Call *callback* with *budget* seconds, and never wait longer than that.

        The hook is *told* its budget and the shipped one honours it, but a
        deadline this class advertises must not depend on a caller-supplied
        closure cooperating — that is exactly the shape of the defect this bug
        is about, a property asserted in a docstring and enforced nowhere.  So
        the wait is bounded here as well.  An overrunning hook is abandoned
        rather than killed (there is no safe way to stop a thread mid-raise);
        it finds its own deadline passed and suppresses the late raise.
        """
        result = {}

        def run() -> None:
            try:
                result["surfaced"] = bool(callback(budget))
            except Exception:  # noqa: BLE001 - a failed surface is a declined ack, not a crash
                self._log.exception("single_instance surface_failed")
                result["surfaced"] = False

        worker = threading.Thread(target=run, name="lw-panel-surface-confirm", daemon=True)
        worker.start()
        worker.join(budget)
        if worker.is_alive():
            self._log.warning("single_instance surface_over_budget (declining ack)")
            return False
        return result.get("surfaced", False)

    # ------------------------------------------------------------------ #
    # Release
    # ------------------------------------------------------------------ #
    def release(self) -> None:
        """Stop the listener and drop the port file if we still own it.

        Idempotent — the exit path may run it more than once.  The port file is
        removed **only** when it still holds this instance's port, so a
        successor that already took over is left alone.
        """
        self._stopping.set()
        if self._server is not None:
            try:
                self._server.close()
            except OSError:
                pass
            self._server = None
        if self._thread is not None:
            self._thread.join(timeout=1.0)
            self._thread = None
        if self.port is not None and _read_published_port(self.port_file) == self.port:
            try:
                self.port_file.unlink()
            except OSError:
                pass
        self.port = None
