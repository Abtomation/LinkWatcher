"""
PD-BUG-160 Manual Validation: the panel answered a launch while it was shutting down.

PURPOSE:
    A second Control Panel launch does not open its own window.  It asks the
    running panel to surface over a loopback channel and exits quietly if that
    panel confirms.  Since PD-BUG-157 that confirmation is honest about the
    present: the listener runs the raise on the UI thread and acks only once the
    window has actually been raised.

    But the promise a launching process reads has two halves -- a window exists
    NOW, and it will still exist when you exit -- and nothing verified the
    second.  ``ControlPanelApp`` commits irreversibly to exiting at
    ``_on_close``, yet held no reference to the guard, so the instance claim was
    dropped only in ``main()``'s ``finally``::

        guard.on_surface = make_surface_hook(app)
        try:
            app.run()            # <-- the ENTIRE drain happens in here
        finally:
            guard.release()      # <-- claim dropped only now

    Throughout the drain-then-terminate shutdown the mainloop and the dispatcher
    pump keep running, so the raise really does succeed and the ack really is
    truthful -- about a window that is seconds from being destroyed.  The
    launcher printed "already running", exited 0, the incumbent finished
    draining and exited, and the operator was left with no panel at all.

    The window is bounded by the AC-9 watchdog, not by the grace period as
    originally filed: ``grace_period_seconds`` (20 s) plus
    ``WATCHDOG_MARGIN_SECONDS`` (15 s), so about 35 s at defaults.  It is
    self-healing -- relaunching once more works, because ``release`` has removed
    ``panel.port`` by then -- which is why it is Low priority rather than a
    lockout.

    THE FIX drops the instance claim the moment the panel commits to exiting.
    A launch arriving during the drain then finds no published port at all, so
    it opens a real window -- and it does so cleanly, taking neither the
    "stale port file" nor the "live process declined" branch, because there is
    nothing left to probe.

    ACCEPTED TRADE-OFF: for the duration of a drain, two panel windows can
    exist -- the one that is exiting and the new one.  That is a deliberate,
    bounded departure from FDD 7-1-1-EC-9, on the same reasoning EC-9 already
    records for PD-BUG-157: being left with NO usable window is the worse
    failure.

WHAT THIS SCRIPT DOES:
    Drives the real ``ControlPanelApp`` -- real Tk mainloop, real dispatcher
    pump, real ShutdownOrchestrator -- with the real ``SingleInstanceGuard``,
    and asks the production client question in the middle of the shutdown:

        "Is a panel already running?"

    No real daemon is started or killed: the process table and the terminator
    are fakes, the same seams the unit suite uses.  A real Tk window opens for a
    few seconds and closes itself.

HOW TO RUN:
    python test/bug-validation/PD-BUG-160_shutdown_window_ack_validation.py

WHAT YOU SHOULD SEE:
    BEFORE the fix:
        launch during shutdown : already_running=True
                                 "...is already running - surfaced that window."
        launch after exit      : already_running=False
        => the launcher was sent away by a panel that then vanished.

    AFTER the fix:
        launch during shutdown : already_running=False
        => the launch opens its own window, which is what the operator needs.

    The script prints its own verdict line, so you do not have to interpret the
    flags by hand.

WATCH THE SCREEN TOO:
    The panel window appears, then the modal "Shutting down" dialog.  Before the
    fix you will see that dialog get RAISED to the foreground when the second
    launch arrives -- the incumbent really did surface, which is exactly why the
    ack was truthful -- and then the whole thing disappears.
"""

import json
import sys
import tempfile
import threading
import time
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT))
sys.path.insert(0, str(REPO_ROOT / "src"))

from linkwatcher.linkwatcher_control_panel.app import (  # noqa: E402
    ControlPanelApp,
    make_surface_hook,
)
from linkwatcher.linkwatcher_control_panel.discovery import ProcessEntry  # noqa: E402
from linkwatcher.linkwatcher_control_panel.lifecycle import LifecycleController  # noqa: E402
from linkwatcher.linkwatcher_control_panel.panel_log import setup_panel_log  # noqa: E402
from linkwatcher.linkwatcher_control_panel.settings import (  # noqa: E402
    PanelSettings,
    RegistryResolution,
)
from linkwatcher.linkwatcher_control_panel.single_instance import SingleInstanceGuard  # noqa: E402

T0 = time.monotonic()


def note(label, **fields):
    print(f"[{time.monotonic() - T0:7.3f}] {label} {fields}", flush=True)


class FakeProcessTable:
    """Scriptable process table -- no real process is ever inspected."""

    def __init__(self, entries=()):
        self.entries = list(entries)

    def snapshot(self):
        return list(self.entries)

    def set_entries(self, entries):
        self.entries = list(entries)


class FakeTerminator:
    """Records terminations; never touches a real process."""

    def __init__(self):
        self.terminated = []

    def terminate(self, pid):
        self.terminated.append(pid)


def daemon_pair(project_root):
    """A realistic venv-shim + interpreter daemon pair for *project_root*."""
    parent = [
        r"C:\Users\tester\bin\.linkwatcher-venv\Scripts\python.exe",
        r"C:\Users\tester\bin\main.py",
        "--project-root",
        str(project_root),
        "--log-file",
        str(Path(project_root) / "logs" / "linkwatcher" / "LinkWatcherLog.txt"),
    ]
    child = list(parent)
    child[0] = r"C:\Users\tester\AppData\Local\Programs\Python\python.exe"
    return [
        ProcessEntry(pid=1000, cmdline=tuple(parent), create_time=100.0, ppid=1),
        ProcessEntry(pid=1001, cmdline=tuple(child), create_time=100.5, ppid=1000),
    ]


def build_environment():
    """A throwaway install dir, project and registry the panel really reads."""
    tmp = Path(tempfile.mkdtemp(prefix="pd_bug_160_"))
    install_dir = tmp / "install"
    install_dir.mkdir()
    project_root = tmp / "PRJ-001"
    (project_root / "logs" / "linkwatcher").mkdir(parents=True)
    (project_root / "tools" / "linkwatcher").mkdir(parents=True)
    (project_root / ".linkwatcher.lock").write_text("1000", encoding="utf-8")
    registry_path = tmp / "project-registry.json"
    registry_path.write_text(
        json.dumps(
            {
                "projects": {
                    "PRJ-001": {
                        "name": "PRJ-001",
                        "path": str(project_root),
                        "version_freeze": False,
                    }
                }
            }
        ),
        encoding="utf-8",
    )
    return tmp, install_dir, project_root, registry_path


def main():
    tmp, install_dir, project_root, registry_path = build_environment()
    print(__doc__.split("HOW TO RUN:")[0])
    print(f"sandbox: {tmp}\n")

    setup_panel_log(install_dir)

    table = FakeProcessTable(daemon_pair(project_root))
    settings = PanelSettings(
        grace_period_seconds=20.0, log_idle_threshold_seconds=3.0, poll_interval_seconds=0.5
    )
    registry = RegistryResolution(path=registry_path, source="cli")

    guard = SingleInstanceGuard(install_dir)
    outcome = guard.acquire()
    note("incumbent_acquired", already_running=outcome.already_running, port=outcome.port)

    app = ControlPanelApp(settings, registry, install_dir, process_table=table)
    # The controller the app builds, but with a terminator that kills nothing.
    app.lifecycle = LifecycleController(
        model=app.model,
        post=app.post,
        process_table=table,
        grace_period_seconds=settings.grace_period_seconds,
        log_idle_threshold_seconds=settings.log_idle_threshold_seconds,
        terminator=FakeTerminator(),
        sleep=lambda seconds: time.sleep(min(seconds, 0.1)),
    )
    guard.on_surface = make_surface_hook(app)
    # Wire the close -> release seam exactly as control_panel.main does.  Absent
    # before the fix, so `getattr` keeps this script runnable against both.
    if hasattr(app, "on_shutdown_begin"):
        app.on_shutdown_begin = guard.release

    result = {}

    def scenario():
        # 1. Wait until the panel sees the daemon, so closing has work to do.
        deadline = time.monotonic() + 15
        while time.monotonic() < deadline:
            rows = app.model.rows()
            if rows and rows[0].status.name == "RUNNING":
                break
            time.sleep(0.1)
        note(
            "daemon_running", rows=[(r.project.project_id, r.status.name) for r in app.model.rows()]
        )

        # 2. The operator closes the window -> drain-then-terminate begins.
        app.post(app._on_close)
        time.sleep(1.0)
        note(
            "shutdown_in_progress",
            shutting_down=app.model.shutting_down,
            dialog=app.shutdown_dialog is not None,
        )

        # 3. THE PROBE: a second launch arrives, on the production client path.
        probe = SingleInstanceGuard(install_dir)
        started = time.monotonic()
        found = probe.acquire()
        result["mid_shutdown"] = (found.already_running, found.message)
        note(
            "second_launch_during_shutdown",
            already_running=found.already_running,
            message=found.message,
            seconds=round(time.monotonic() - started, 3),
        )
        if not found.already_running:
            probe.release()

        # 4. The daemon really goes away -> the drain resolves observationally.
        table.set_entries([])

    threading.Thread(target=scenario, name="pd-bug-160-scenario", daemon=True).start()

    try:
        app.run()
    finally:
        guard.release()
    note("incumbent_exited_and_released")

    # 5. What does the operator have now?  A third launch answers that.
    after = SingleInstanceGuard(install_dir)
    found = after.acquire()
    result["after_exit"] = (found.already_running, found.message)
    note("launch_after_exit", already_running=found.already_running, message=found.message)
    after.release()

    mid_running, mid_message = result["mid_shutdown"]
    post_running, _ = result["after_exit"]

    print("\n" + "=" * 78)
    print("RESULT")
    print("=" * 78)
    print(f"  launch during shutdown : already_running={mid_running!r}")
    print(f"                           message={mid_message!r}")
    print(f"  launch after exit      : already_running={post_running!r}")
    print()
    if mid_running and not post_running:
        print("  BUG PRESENT — the shutting-down panel claimed the instance slot and sent")
        print("  the launcher away; moments later no panel existed at all.")
        return 1
    if not mid_running:
        print("  FIXED — the launch arriving during shutdown was NOT sent away, so the")
        print("  operator gets a real window instead of none.")
        return 0
    print("  INCONCLUSIVE — the panel was still claiming the slot after it had exited.")
    print("  That is a different failure; investigate before trusting this run.")
    return 2


if __name__ == "__main__":
    sys.exit(main())
