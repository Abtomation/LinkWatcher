"""
Application composition root for the LinkWatcher Control Panel.

Owns the Tk root, the observable model, the discovery poller, the UI-thread
dispatcher queue, and (from Phase D) the window-close shutdown orchestration.
Worker threads never touch Tk or the model directly: they :meth:`ControlPanelApp.post`
a callable onto a thread-safe queue that a ``root.after(100)`` pump drains and
runs on the UI thread (threading model per TDD §4.0 / §4.3).

Phase B made the panel a truthful read-only monitor; Phase C added the
lifecycle actions (start via launcher, drain-then-terminate stop) through the
:class:`~.lifecycle.LifecycleController`; Phase D wires window close to the
:class:`~.lifecycle.ShutdownOrchestrator` — modal shutdown-progress dialog,
parallel per-daemon drains, deterministic exit bounded by the grace period plus
a watchdog (AC-7/AC-9).  The poller keeps running during shutdown so clean
drains resolve observationally.  Phase E fills the detail notebook (log tail,
config editor, validation) and adds the :class:`~.validation.ValidationController`
for on-demand ``--validate`` runs.

AI Context
----------
- **One direction only**: poller thread → queue → dispatcher → ``AppModel`` →
  views.  A view never reads the process table and never writes the model.
- **Two timers**: the 100 ms dispatcher pump (queue drain) and a 1 s UI tick that
  expires transitional pins and keeps uptime counting between polls.
- The panel opens even with an unresolved registry — the list pane shows the
  registry-error banner instead of a tree, and no poller is started.
"""

from __future__ import annotations

import queue
import sys
import threading
import time
import tkinter as tk

from .discovery import DiscoveryPoller, PsutilProcessTable
from .lifecycle import LifecycleController, ShutdownOrchestrator
from .model import AppModel
from .panel_log import get_panel_logger
from .settings import PanelSettings, RegistryResolution
from .validation import ValidationController
from .views import MainWindow, ShutdownDialog

# root.after cadence for the UI-thread dispatcher (TDD §4.0: root.after(100)).
DISPATCH_INTERVAL_MS = 100

# UI tick: expires pins whose deadline passed and refreshes rendered uptimes.
UI_TICK_INTERVAL_MS = 1000


def report_callback_exception(log, exc_type, exc_value, exc_traceback) -> None:
    """Record an exception Tk raised inside one of its own callbacks (CR-19).

    Module-level and Tk-free for the same reason as :func:`drain_queue`: the rule
    is assertable without a display. Tk's default hook prints to stderr, which
    under the ``pythonw.exe`` launch the hook uses is attached to nothing — so
    such a failure vanished completely.

    Complements :func:`drain_queue`, which isolates callbacks the panel *queues*;
    this covers the other UI-thread entry point, the handlers Tk invokes directly
    (button commands, key bindings, ``<<TreeviewSelect>>``), which never pass
    through the dispatcher at all. Never raises: it is the last handler standing.
    """
    try:
        log.error("ui_callback_failed", exc_info=(exc_type, exc_value, exc_traceback))
    except Exception:  # noqa: BLE001 - the last-resort handler cannot itself raise
        pass


def drain_queue(pending: "queue.Queue", log) -> int:
    """Run every queued UI-thread callback, isolating failures. Returns how many ran.

    Module-level and Tk-free on purpose: the isolation rule this implements
    (TDD §3.3 — a worker failure never propagates to the mainloop) is the one
    half of INT-8 that runs on the UI thread, and keeping it out of the
    Tk-owning class is what lets it be tested without a display.

    A callback that raises is logged to the panel log and swallowed, and the
    callbacks queued behind it still run — one bad update can neither kill the
    mainloop nor strand the updates waiting behind it.

    Queue depth is sampled here, before the drain, and logged at DEBUG whenever
    it is non-empty (TDD §7.1): depth growing tick over tick is the early signal
    that workers are outpacing the UI thread. Only non-empty depths are logged,
    so an idle panel stays silent instead of writing a line every 100 ms.
    """
    depth = pending.qsize()
    if depth:
        log.debug("dispatch_queue_depth depth=%d", depth)
    ran = 0
    while True:
        try:
            callback = pending.get_nowait()
        except queue.Empty:
            return ran
        ran += 1
        try:
            callback()
        except Exception:  # noqa: BLE001 - isolate worker/callback failures
            log.exception("dispatch_callback_failed")


def make_surface_hook(app):
    """Build the ``on_surface`` hook the single-instance guard calls.

    Lives here, at module level, rather than as a closure inside the entry
    script: the guard's contract says the hook returns True only once the
    window has *actually* been raised, and a closure buried in
    ``control_panel.main()`` is unreachable by any test — regressing it to
    return ``None`` left the whole panel suite green while every relaunch would
    have opened a duplicate window (TD312, found reviewing PD-BUG-157).

    The raise itself must happen on the UI thread, so it goes through
    :meth:`ControlPanelApp.post` like any other worker callback and this hook
    waits for the UI thread to report back.  Silence within *timeout* means the
    mainloop is dead, wedged, or slower than the launcher is willing to wait —
    all cases where the honest answer is "not surfaced", so the guard declines
    the ack and the launching process opens a real window.

    Confirmation means the UI thread ran the raise *and the raise succeeded*.
    Reporting only that it ran acked a window that was not there whenever the
    raise threw — a root already destroyed, a Tk that has failed — while the
    same panel logged ``surface_failed`` (PD-BUG-159).  What confirmation still
    does not prove is that Windows honoured the activation; a refused foreground
    grab presents as a taskbar flash (the documented floor, TDD §4.5).
    """

    def surface_hook(timeout: float) -> bool:
        surfaced = threading.Event()
        deadline = time.monotonic() + timeout

        def raise_window():
            if time.monotonic() > deadline:
                # The launcher stopped waiting and opened its own window;
                # raising now would fight it for the foreground.
                return
            if app.surface():
                surfaced.set()

        app.post(raise_window)
        return surfaced.wait(timeout)

    return surface_hook


class ControlPanelApp:
    """Wires settings, registry, discovery and the model into the window shell."""

    def __init__(
        self,
        settings: PanelSettings,
        registry: RegistryResolution,
        install_dir,
        *,
        process_table=None,
    ):
        self.settings = settings
        self.registry = registry
        self.install_dir = install_dir
        self._queue: "queue.Queue" = queue.Queue()
        self._log = get_panel_logger()
        self._shutdown = None
        self.shutdown_dialog = None
        self._exiting = False
        # Fired once, the moment the panel commits to exiting.  Callers wire it
        # to the single-instance guard's release so a panel that is on its way
        # out stops claiming the instance slot (PD-BUG-160).  A mutable
        # attribute rather than a constructor argument for the same reason the
        # guard's ``on_surface`` is one: the two are wired to each other after
        # both exist.
        self.on_shutdown_begin = None

        self.root = tk.Tk()
        # Tk swallows exceptions raised inside its own callbacks by printing to
        # stderr — which under the `pythonw.exe` launch the hook uses is not
        # attached to anything, so such a failure vanished entirely (CR-19).
        # Routing it to the panel log makes it diagnosable by the same file the
        # status bar already points operators at.
        self.root.report_callback_exception = self._report_callback_exception
        self.model = AppModel()

        # One process table shared by discovery and lifecycle (it is stateless).
        table = process_table if process_table is not None else PsutilProcessTable()
        self.lifecycle = LifecycleController(
            model=self.model,
            post=self.post,
            process_table=table,
            grace_period_seconds=settings.grace_period_seconds,
            log_idle_threshold_seconds=settings.log_idle_threshold_seconds,
        )

        # Phase E: on-demand validation runs (subprocess per project; BR-6).
        self.validation = ValidationController(
            model=self.model,
            post=self.post,
            install_dir=install_dir,
        )

        registry_error = None if registry.resolved else registry.error
        self.main_window = MainWindow(
            self.root,
            model=self.model,
            registry_error=registry_error,
            on_select=self._on_select,
            on_refresh=self._on_refresh,
            on_start=self._on_start,
            on_stop=self._on_stop,
            on_validate=self._on_validate,
        )
        self.model.subscribe(self.main_window.render)

        # One manual refresh at a time (CR-7); the periodic poller is separate.
        self._refresh_lock = threading.Lock()
        self._refresh_in_flight = False
        self.poller = None
        if registry.resolved:
            self.poller = DiscoveryPoller(
                registry.path,
                table,
                interval_seconds=settings.poll_interval_seconds,
                on_result=self._on_poll_result,
            )
            self.poller.start()

        # Close routes through our handler — never a direct destroy (Phase D
        # replaces this with the shutdown-progress orchestration).
        self.root.protocol("WM_DELETE_WINDOW", self._on_close)
        self._pump_dispatch_queue()
        self._ui_tick()

    # ------------------------------------------------------------------ #
    # Dispatcher
    # ------------------------------------------------------------------ #
    def _report_callback_exception(self, exc_type, exc_value, exc_traceback) -> None:
        """Tk's callback-exception hook — delegates to the Tk-free implementation."""
        report_callback_exception(self._log, exc_type, exc_value, exc_traceback)

    def post(self, callback) -> None:
        """Thread-safe: schedule *callback* to run on the UI thread.

        The single funnel every worker thread uses to mutate the model/views;
        keeps all Tk access on the UI thread.
        """
        self._queue.put(callback)

    def _pump_dispatch_queue(self) -> None:
        """Drain queued callbacks on the UI thread, then reschedule.

        The drain itself lives in :func:`drain_queue` (module level, Tk-free)
        so its failure-isolation rule is testable without a display.

        Queue-depth instrumentation (TDD §7.1) lives in :func:`drain_queue`
        alongside the drain it measures, for the same display-free-testability
        reason the drain itself was extracted.
        """
        drain_queue(self._queue, self._log)
        self.root.after(DISPATCH_INTERVAL_MS, self._pump_dispatch_queue)

    def _ui_tick(self) -> None:
        """Expire due pins and repaint, so uptime advances between polls.

        Also repaints the shutdown dialog (when open) so its "Draining… (n s)"
        elapsed suffix advances between model changes.
        """
        try:
            self.model.tick()
            self.main_window.render()
            if self.shutdown_dialog is not None:
                self.shutdown_dialog.render()
        except Exception:  # noqa: BLE001 - a render failure must not kill the tick
            self._log.exception("ui_tick_failed")
        self.root.after(UI_TICK_INTERVAL_MS, self._ui_tick)

    # ------------------------------------------------------------------ #
    # Wiring
    # ------------------------------------------------------------------ #
    def _on_poll_result(self, result) -> None:
        """Poller-thread callback: hand the result to the UI thread untouched.

        The poll's start-order sequence rides along so the model can drop a
        result that observed reality earlier than one already applied (CR-7).
        """
        self.post(
            lambda: self.model.apply_poll(
                result.snapshots,
                error=result.error,
                sequence=getattr(result, "sequence", None),
            )
        )

    def _on_select(self, project_id) -> None:
        self.model.select(project_id)

    def _on_start(self, project_id) -> None:
        self.lifecycle.start(project_id)

    def _on_stop(self, project_id) -> None:
        self.lifecycle.stop(project_id)

    def _on_validate(self, project_id) -> None:
        self.validation.run(project_id)

    def _on_refresh(self) -> None:
        """Manual Refresh: run one poll off-thread so the UI never blocks.

        Guarded against overlap: every F5 / Refresh press used to spawn another
        thread, so holding the key queued an unbounded pile of concurrent polls
        that all raced to apply (CR-7). One manual refresh at a time is enough —
        the periodic poller is still running underneath.
        """
        if self.poller is None:
            return
        with self._refresh_lock:
            if self._refresh_in_flight:
                return
            self._refresh_in_flight = True

        def _run() -> None:
            try:
                self._on_poll_result(self.poller.poll_once())
            finally:
                with self._refresh_lock:
                    self._refresh_in_flight = False

        threading.Thread(target=_run, name="lw-panel-refresh", daemon=True).start()

    # ------------------------------------------------------------------ #
    # Surfacing (single instance / hook auto-open)
    # ------------------------------------------------------------------ #
    def surface(self) -> bool:
        """Raise and focus the window — the AC-11 response to a second launch.

        Returns True once the window has been raised, False if it could not be.
        The exception is still swallowed and still logged — surfacing must never
        kill the panel — but the *outcome* now reaches the caller.  Returning
        nothing made a failed raise indistinguishable from a successful one, so
        the guard acked a window that did not exist while this method logged the
        failure one line earlier (PD-BUG-159).

        Called on the UI thread only: the single-instance listener thread posts
        this through :meth:`post` like any other worker callback.  Windows'
        foreground lock may refuse the raise for a background process, in which
        case the taskbar button flashes instead — that is the documented
        floor (TDD §4.5).  So the foreground assist sits *after* the flag is
        set: the window is up either way, and only the activation was denied.
        """
        raised = False
        try:
            self.root.deiconify()
            self.root.lift()
            self.root.focus_force()
            raised = True
            self._request_foreground()
        except Exception:  # noqa: BLE001 - surfacing must never kill the panel
            self._log.exception("surface_failed")
        return raised

    def _request_foreground(self) -> None:
        """Windows-only ``SetForegroundWindow`` assist; a no-op elsewhere."""
        if not sys.platform.startswith("win"):
            return
        try:
            import ctypes

            handle = self.root.winfo_id()
            # The Tk toplevel's own HWND is a child; the foreground call needs
            # the owning top-level window.
            handle = ctypes.windll.user32.GetAncestor(handle, 2)  # GA_ROOT
            ctypes.windll.user32.SetForegroundWindow(handle)
        except Exception:  # noqa: BLE001 - foreground lock / no user32: flash only
            self._log.debug("set_foreground_unavailable", exc_info=True)

    # ------------------------------------------------------------------ #
    # Lifecycle
    # ------------------------------------------------------------------ #
    def _on_close(self) -> None:
        """Close = drain-then-terminate every managed daemon, then exit (AC-7/AC-9).

        The poller keeps running so clean drains resolve observationally; the
        watchdog guarantees exit even if a worker hangs.  A second close
        request while shutting down is ignored — the dialog owns the exit.
        No confirmation precedes this (UI Design Decision D3): the progress
        dialog itself is the visible acknowledgment of what closing does.

        The single-instance claim is dropped *first*, before anything is
        drained.  A panel that is committed to exiting is not a window a launch
        can be sent to, but the listener kept answering for the whole drain —
        up to the grace period plus the watchdog margin — and the raise it
        performed genuinely succeeded, so the ack was truthful about a window
        that was seconds from being destroyed.  The launcher exited, this panel
        finished draining, and the operator was left with none (PD-BUG-160).
        Dropping the claim here means such a launch finds no published port at
        all and simply opens its own window.
        """
        if self._shutdown is not None:
            return
        self._release_instance_claim()
        self._log.info("panel_closing (drain-then-terminate, AC-7)")
        self._shutdown = ShutdownOrchestrator(
            model=self.model,
            controller=self.lifecycle,
            grace_period_seconds=self.settings.grace_period_seconds,
            on_complete=self._finish_shutdown,
        )
        if not self._shutdown.begin():
            return  # nothing to drain — _finish_shutdown already ran
        self.shutdown_dialog = ShutdownDialog(
            self.root, model=self.model, targets=self._shutdown.targets
        )
        self.model.subscribe(self.shutdown_dialog.render)
        self.root.after(
            int(self._shutdown.watchdog_delay_seconds * 1000),
            self._shutdown.watchdog_fired,
        )

    def _release_instance_claim(self) -> None:
        """Tell whoever wired ``on_shutdown_begin`` that this panel is exiting.

        Best-effort and never fatal: a window the operator has asked to close
        must close even if dropping the claim fails, and the worst case of a
        failure here is the pre-fix behaviour rather than a stuck panel.
        """
        callback = self.on_shutdown_begin
        if callback is None:
            return  # unwired — a fail-open launch binds no listener to release
        try:
            callback()
        except Exception:  # noqa: BLE001 - closing must never be blocked by this
            self._log.exception("shutdown_claim_release_failed")

    def _finish_shutdown(self) -> None:
        """Orchestrator callback: exit on the next Tk tick (idempotent).

        Deferred one tick so the final model notification cascade (which may
        have invoked this) finishes before the widget tree is torn down.
        """
        if self._exiting:
            return
        self._exiting = True
        self._log.info("panel_exit shutdown_complete")
        self.root.after(0, self._exit_now)

    def _exit_now(self) -> None:
        if self.poller is not None:
            self.poller.stop(timeout=1.0)
        self.root.destroy()

    def run(self) -> None:
        """Enter the Tk mainloop (blocks until the window closes)."""
        self._log.info("panel_started")
        self.root.mainloop()
