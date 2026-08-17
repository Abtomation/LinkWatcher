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

AI Context
----------
- **Entry point**: :meth:`SingleInstanceGuard.acquire` — returns an
  :class:`InstanceOutcome`.  ``already_running`` True means the caller must exit
  quietly (the existing window has been asked to surface); False means this
  process owns the instance and must call :meth:`SingleInstanceGuard.release`
  on the way out.
- **Threading**: the listener runs on its own daemon thread and never touches Tk
  or the model.  It invokes ``on_surface`` — which callers set to a
  ``ControlPanelApp.post(...)`` closure — so surfacing lands on the UI thread
  through the same dispatcher queue every worker uses (TDD §4.3).
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
from dataclasses import dataclass
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


def surface_existing_instance(port: int) -> bool:
    """Ask the panel listening on *port* to surface; True if one answered.

    False covers every "no live panel there" case — nothing listening (stale
    file), a refused or timed-out connect, and a peer that connects but fails
    the banner handshake (a recycled port owned by an unrelated process).
    """
    try:
        with socket.create_connection((LOOPBACK, port), timeout=CONNECT_TIMEOUT_SECONDS) as sock:
            sock.settimeout(HANDSHAKE_TIMEOUT_SECONDS)
            sock.sendall(SURFACE_TOKEN + b"\n")
            reply = sock.recv(len(PANEL_BANNER))
    except OSError:
        return False
    return reply == PANEL_BANNER


class SingleInstanceGuard:
    """Owns the loopback listener, the ``panel.port`` file, and the surface hook.

    Typical use from the entry script::

        guard = SingleInstanceGuard(install_dir)
        outcome = guard.acquire()
        if outcome.already_running:
            return                      # existing window was surfaced
        app = ControlPanelApp(...)
        guard.on_surface = lambda: app.post(app.surface)
        try:
            app.run()
        finally:
            guard.release()

    ``on_surface`` is a mutable attribute rather than a constructor argument
    because the listener must be bound *before* the Tk window exists (so a
    losing launch can be told to exit without a window ever being built).  A
    SURFACE arriving in the millisecond before the callback is assigned is
    dropped rather than queued — the panel is opening anyway, which is what the
    request wanted.
    """

    def __init__(self, install_dir, on_surface: Optional[Callable[[], None]] = None):
        self.install_dir = Path(install_dir)
        self.port_file = self.install_dir / PORT_FILENAME
        self.on_surface = on_surface
        self.port: Optional[int] = None
        self._server: Optional[socket.socket] = None
        self._thread: Optional[threading.Thread] = None
        self._stopping = threading.Event()
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
        if published is not None and surface_existing_instance(published):
            self._log.info("single_instance surfaced_existing port=%s", published)
            return InstanceOutcome(
                already_running=True,
                port=published,
                message="LinkWatcher Control Panel is already running — surfaced that window.",
            )

        if published is not None:
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
        """Accept loop: answer the handshake and fire ``on_surface`` per request.

        Every failure is contained here — a bad peer, a dropped connection, or a
        raising callback must never take down the listener or the panel
        (per-surface error isolation, TDD §3.3).
        """
        while not self._stopping.is_set():
            try:
                conn, peer = self._server.accept()
            except OSError:
                break  # socket closed by release(), or unrecoverable — stop
            try:
                self._handle(conn, peer)
            except Exception:  # noqa: BLE001 - one bad peer never stops the listener
                self._log.exception("single_instance request_failed")
            finally:
                try:
                    conn.close()
                except OSError:
                    pass

    def _handle(self, conn: socket.socket, peer) -> None:
        """Serve one connection: verify, ack, then surface exactly once."""
        if peer and peer[0] != LOOPBACK:
            return  # defence in depth; the bind already restricts to loopback
        conn.settimeout(HANDSHAKE_TIMEOUT_SECONDS)
        request = conn.recv(MAX_REQUEST_BYTES)
        if request.strip() != SURFACE_TOKEN:
            return  # unknown verb — the protocol accepts nothing else
        conn.sendall(PANEL_BANNER)
        callback = self.on_surface
        if callback is None:
            return
        self._log.info("single_instance surface_requested")
        callback()

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
