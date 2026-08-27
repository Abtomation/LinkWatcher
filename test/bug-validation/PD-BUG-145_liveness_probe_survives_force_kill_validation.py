#!/usr/bin/env python3
"""
Manual validation for PD-BUG-145: the watch-liveness probe file outlived the
daemon on the stop paths that actually stop daemons.

The liveness canary (PD-BUG-139) writes a real file inside the watched tree so
the OS has something to emit an event for. Cleanup for that file lived in
``LinkWatcherService.stop()`` — which is only reached when Python gets to run
shutdown code at all. Neither operator stop path does:

    stop path                        mechanism                   runs stop()?
    -------------------------------  --------------------------  ------------
    stop_linkwatcher.ps1             Stop-Process -Force         NO
    Control Panel                    psutil terminate()          NO
    Ctrl+C on a foreground run       SIGINT -> _signal_handler   yes
    liveness self-stop               loop exits -> finally       yes

Rows 1 and 2 are how daemons are normally stopped here, and both are a hard
``TerminateProcess`` on Windows. An atexit or signal hook cannot help for the
same reason: the process is not asked to exit, it is destroyed.

So the probe was stranded. Where that lands depends on the log location:

    log_file location             probe lands in           user-visible?
    ----------------------------  -----------------------  -------------
    logs/linkwatcher/ (default)   the same excluded dir     no, benign
    project root (fallback)       the project root          YES

The fallback row is the one that matters: a stray ``.linkwatcher-liveness-probe``
dotfile sitting untracked in the user's repository. This validation uses that
layout deliberately, because it is the case a human can see.

The fix has two layers, because neither is sufficient alone:

  1. the probe is deleted as soon as its round trip is decided — it only has to
     exist long enough to emit one event, so it is no longer persistent state
     that a kill can strand; and
  2. startup sweeps whatever an abnormal exit left behind — the only layer that
     can cover a process which never runs shutdown code (force-kill, crash,
     power loss).

How to validate:

  1. python test/bug-validation/PD-BUG-145_liveness_probe_survives_force_kill_validation.py

     Runs both halves back to back against a real daemon on a throwaway
     project, killing it with taskkill /F — the same TerminateProcess the
     launcher and the Control Panel use:

       -> "PRE-FIX  (both layers disabled)" = the old behaviour. After the kill
          the probe file is still sitting in the project root.
       -> "POST-FIX (shipped)"              = nothing is left behind, and a
          probe planted by a hypothetical killed predecessor is swept away
          while the daemon comes up.

     Exit 0 only when the pre-fix half really strands the probe AND the
     post-fix half leaves the tree clean. A pre-fix half that comes back clean
     means the halves are not actually different and the run proves nothing.

  2. To see it by hand instead, look at the sandbox path the script prints and
     run `git status` in it after the pre-fix half — the probe shows up as an
     untracked file.

Test File ID: PD-BUG-145 validation (manual)
Created: 2026-08-27
"""

import shutil
import subprocess
import sys
import time
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
SANDBOX = Path(r"C:\tmp\PD-BUG-145-validation")
SENTINEL_NAME = ".linkwatcher-liveness-probe"

IDLE_SECONDS = 2.0
PROBE_TIMEOUT = 5.0


# ---------------------------------------------------------------------------
# Child mode: run a real daemon, optionally with the fix disabled
# ---------------------------------------------------------------------------


def _run_daemon(project_root, disable_fix):
    """Run a real LinkWatcherService until killed (child process)."""
    sys.path.insert(0, str(REPO_ROOT / "src"))

    from linkwatcher.config.settings import LinkWatcherConfig
    from linkwatcher.liveness import WatchLivenessMonitor
    from linkwatcher.service import LinkWatcherService

    if disable_fix:
        # Restore the pre-fix behaviour exactly: cleanup existed only on the
        # stop() path, and the probe persisted on disk between round trips.
        WatchLivenessMonitor._discard_sentinel = lambda self: None
        LinkWatcherService._remove_liveness_sentinel = lambda self: None

    config = LinkWatcherConfig()
    # Log at the project ROOT -> the fallback placement, where the leftover is
    # user-visible. See the table in the module docstring.
    config.log_file = str(Path(project_root) / "LinkWatcherLog.txt")
    config.watch_liveness_enabled = True
    config.watch_liveness_idle_seconds = IDLE_SECONDS
    config.watch_liveness_probe_timeout = PROBE_TIMEOUT
    config.watch_liveness_failure_threshold = 2

    service = LinkWatcherService(str(project_root), config=config)
    service.start(initial_scan=False)


# ---------------------------------------------------------------------------
# Parent mode: drive the two halves
# ---------------------------------------------------------------------------


def _fresh_project(name):
    project = SANDBOX / name
    if project.exists():
        shutil.rmtree(project, ignore_errors=True)
    project.mkdir(parents=True)
    (project / "guide.md").write_text("see [notes](notes.md)\n", encoding="utf-8")
    (project / "notes.md").write_text("notes\n", encoding="utf-8")
    return project


def _spawn(project, disable_fix):
    return subprocess.Popen(
        [
            sys.executable,
            str(Path(__file__).resolve()),
            "--daemon",
            str(project),
            "1" if disable_fix else "0",
        ],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def _force_kill(proc):
    """Kill exactly the way the operator stop paths do."""
    subprocess.run(
        ["taskkill", "/F", "/T", "/PID", str(proc.pid)],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    try:
        proc.wait(timeout=20)
    except subprocess.TimeoutExpired:
        proc.kill()
    time.sleep(1.0)


def _wait_for(predicate, timeout):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if predicate():
            return True
        time.sleep(0.25)
    return False


def _leftovers(project):
    return sorted(p.name for p in project.iterdir())


def half_pre_fix():
    print("=" * 74)
    print("PRE-FIX  (both layers disabled — the behaviour PD-BUG-145 reported)")
    print("=" * 74)

    project = _fresh_project("pre-fix")
    sentinel = project / SENTINEL_NAME
    print(f"project : {project}")

    proc = _spawn(project, disable_fix=True)
    print(f"daemon  : PID {proc.pid} — waiting for the tree to go quiet and a probe to fire")

    if not _wait_for(sentinel.exists, timeout=60):
        _force_kill(proc)
        print("\nINCONCLUSIVE: no probe was ever written, so its cleanup cannot be judged.")
        return None

    print(f"probe   : written at {sentinel.name}")
    print("kill    : taskkill /F  (same TerminateProcess as Stop-Process -Force)")
    _force_kill(proc)

    stranded = sentinel.exists()
    print(f"\nafter the kill, the project root contains: {_leftovers(project)}")
    if stranded:
        print("\n  >> STRANDED. The probe outlived the daemon that explains it.")
        print("     In a real repository this is an untracked dotfile the user")
        print("     never created and cannot account for.")
    else:
        print("\n  >> not stranded (unexpected for the pre-fix half).")
    return stranded


def half_post_fix():
    print()
    print("=" * 74)
    print("POST-FIX (shipped)")
    print("=" * 74)

    project = _fresh_project("post-fix")
    sentinel = project / SENTINEL_NAME
    print(f"project : {project}")

    # Layer 2 first: plant what a hard-killed predecessor would have left.
    planted = "stranded by a killed predecessor"
    sentinel.write_text(planted, encoding="utf-8")
    print("planted : a stranded probe, as a force-killed predecessor would leave")

    proc = _spawn(project, disable_fix=False)
    print(f"daemon  : PID {proc.pid}")

    swept = _wait_for(lambda: not sentinel.exists(), timeout=60)
    print(f"sweep   : stranded probe removed at startup = {swept}")

    # Layer 1: let a live probe cycle happen, then kill mid-flight.
    time.sleep(IDLE_SECONDS + PROBE_TIMEOUT + 3)
    print("kill    : taskkill /F  (same TerminateProcess as Stop-Process -Force)")
    _force_kill(proc)

    survived = sentinel.exists()
    print(f"\nafter the kill, the project root contains: {_leftovers(project)}")

    clean = swept and not survived
    if clean:
        print("\n  >> CLEAN. Nothing the daemon wrote for its own use outlived it.")
    else:
        if not swept:
            print("\n  >> FAIL: the stranded probe was not swept at startup.")
        if survived:
            print("\n  >> FAIL: a probe still outlived a force-killed daemon.")
    return clean


def main():
    print()
    print("PD-BUG-145 — does the liveness probe outlive a force-killed daemon?")
    print(f"sandbox: {SANDBOX}")
    print()

    SANDBOX.mkdir(parents=True, exist_ok=True)

    stranded_before = half_pre_fix()
    clean_after = half_post_fix()

    print()
    print("=" * 74)
    print("VERDICT")
    print("=" * 74)

    if stranded_before is None:
        print("INCONCLUSIVE — the pre-fix half never wrote a probe.")
        return 2
    if not stranded_before:
        print("INCONCLUSIVE — the pre-fix half did not reproduce the bug, so the")
        print("two halves are not actually different and this run proves nothing.")
        return 2
    if not clean_after:
        print("FAIL — the fix did not keep the tree clean.")
        return 1

    print("PASS")
    print("  pre-fix : the probe was stranded in the project root by a force-kill")
    print("  post-fix: nothing was stranded, and a planted leftover was swept at startup")
    print()
    print(f"Sandbox left in place for inspection: {SANDBOX}")
    return 0


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--daemon":
        _run_daemon(sys.argv[2], disable_fix=sys.argv[3] == "1")
    else:
        sys.exit(main())
