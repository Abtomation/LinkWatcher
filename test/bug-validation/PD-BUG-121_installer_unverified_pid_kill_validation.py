#!/usr/bin/env python3
"""
Manual validation for PD-BUG-121: the installer force-killed an unverified PID
read from a stale .linkwatcher.lock.

What this shows: a stale lock file naming a PID Windows has recycled to an
unrelated program. The old installer read that integer and ran `taskkill /F` on
it with no identity check — so the unrelated program died, the installer
reported it as a stopped daemon, and the lock was unlinked.

This script stands in a real, visible bystander (Notepad) for the recycled PID,
so you can watch the window survive or vanish.

  Step 1 — arm it:
      python test/bug-validation/PD-BUG-121_installer_unverified_pid_kill_validation.py
    Opens Notepad and plants its PID in <repo>/.linkwatcher.lock.
    Aborts untouched if a live LinkWatcher daemon already holds that lock —
    stop the daemon first (stop_linkwatcher.ps1) and re-run.

  Step 2 — run the real installer:
      python deployment/install_global.py

    WITHOUT the fix: the Notepad window disappears the moment the installer
      starts, and it prints "OK: Stopped running LinkWatcher (PID: <notepad>)".
      The lock file is gone — the evidence of what it killed is destroyed.

    WITH the fix: Notepad stays open. No such line is printed. The lock file is
      still there, untouched. (The installer still stops genuine daemons — those
      are found by executable path under the install venv, and reported as
      "OK: Stopped LinkWatcher daemon using install venv (PID: ...)".)

  Step 3 — read the after-state:
      python test/bug-validation/PD-BUG-121_installer_unverified_pid_kill_validation.py --check

  Step 4 — clean up (closes Notepad, removes the planted lock):
      python test/bug-validation/PD-BUG-121_installer_unverified_pid_kill_validation.py --cleanup
"""

import argparse
import json
import platform
import subprocess
import sys
import tempfile
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
LOCK_FILE = REPO_ROOT / ".linkwatcher.lock"
MARKER = Path(tempfile.gettempdir()) / "pd-bug-121-validation.json"


def pid_running(pid):
    """Is *pid* a live process? (Windows tasklist / POSIX signal 0.)"""
    if platform.system() == "Windows":
        result = subprocess.run(
            ["tasklist", "/FI", f"PID eq {pid}", "/NH"],
            capture_output=True,
            text=True,
        )
        return str(pid) in result.stdout
    try:
        import os

        os.kill(pid, 0)
        return True
    except OSError:
        return False


def spawn_bystander():
    """A visible, harmless stand-in for the process holding the recycled PID."""
    if platform.system() == "Windows":
        proc = subprocess.Popen(["notepad.exe"])
        return proc.pid, "Notepad (a window should now be open)"
    proc = subprocess.Popen([sys.executable, "-c", "import time; time.sleep(600)"])
    return proc.pid, "a python sleeper (no window — this platform has no Notepad)"


def arm():
    if LOCK_FILE.exists():
        try:
            existing = int(LOCK_FILE.read_text().strip())
        except (ValueError, OSError):
            existing = None
        if existing is not None and pid_running(existing):
            print(f"ABORTED — a live process ({existing}) already holds {LOCK_FILE.name}.")
            print("   That is almost certainly this project's LinkWatcher daemon.")
            print("   Stop it first:")
            print("     pwsh.exe -File process-framework/tools/linkWatcher/stop_linkwatcher.ps1")
            print("   Nothing was changed.")
            return 1
        print(f"NOTE: replacing a stale lock file that named dead PID {existing}.")

    pid, description = spawn_bystander()
    LOCK_FILE.write_text(str(pid))
    MARKER.write_text(json.dumps({"pid": pid}))

    print("BEFORE state")
    print(f"  Bystander   : PID {pid} — {description}")
    print(f"  Lock file   : {LOCK_FILE} now contains {pid}")
    print(f"  Alive?      : {pid_running(pid)}")
    print()
    print("Now run the installer and watch the window:")
    print("    python deployment/install_global.py")
    print()
    print("  WITHOUT the fix -> the window vanishes; installer prints")
    print(f"                     'OK: Stopped running LinkWatcher (PID: {pid})'; lock deleted.")
    print("  WITH the fix    -> the window stays open; no such line; lock untouched.")
    print()
    print("Then:  ... --check     (after-state)")
    print("       ... --cleanup   (close Notepad, remove the planted lock)")
    return 0


def check():
    if not MARKER.exists():
        print("No armed run found — run this script with no arguments first.")
        return 1
    pid = json.loads(MARKER.read_text())["pid"]
    alive = pid_running(pid)
    lock_present = LOCK_FILE.exists()

    print("AFTER state")
    print(f"  Bystander PID {pid} alive? : {alive}")
    print(f"  Lock file still present?   : {lock_present}")
    print()
    if alive and lock_present:
        print("PASS — the installer left the unverified PID and its lock file alone.")
        return 0
    print("FAIL — the bug is present:")
    if not alive:
        print(f"   The installer terminated PID {pid}, an unrelated process.")
    if not lock_present:
        print("   The installer unlinked the lock file, destroying the evidence.")
    return 1


def cleanup():
    if MARKER.exists():
        pid = json.loads(MARKER.read_text())["pid"]
        if pid_running(pid):
            if platform.system() == "Windows":
                subprocess.run(["taskkill", "/F", "/PID", str(pid)], capture_output=True)
            else:
                import os
                import signal

                os.kill(pid, signal.SIGTERM)
            print(f"Closed the bystander (PID {pid}).")
        MARKER.unlink(missing_ok=True)
    if LOCK_FILE.exists():
        LOCK_FILE.unlink(missing_ok=True)
        print(f"Removed the planted lock file: {LOCK_FILE}")
    print("Cleanup complete.")
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="report the after-state")
    parser.add_argument(
        "--cleanup", action="store_true", help="close the bystander, remove the lock"
    )
    args = parser.parse_args()

    print(f"PD-BUG-121 validation — repo: {REPO_ROOT}")
    print()
    if args.cleanup:
        return cleanup()
    if args.check:
        return check()
    return arm()


if __name__ == "__main__":
    sys.exit(main())
