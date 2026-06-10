"""
PD-BUG-100 Manual Validation: launcher must not delete a running owner's lock.

PURPOSE:
    Reproduce the condition behind "two LinkWatcher daemons per project". When
    two starts race, the loser's main.py correctly exits(1) because the winner
    holds .linkwatcher.lock. The background launcher then saw its spawned process
    HasExited and, in the buggy version, unconditionally deleted .linkwatcher.lock
    — stripping the *running winner's* lock so the next start spawned a second
    daemon.

    This script stands up a real, live "winner" process owning the lock, then
    runs the REAL launcher cleanup decision (Get-DaemonExitDisposition, using its
    real Get-Process liveness probe) as if our just-spawned daemon had exited.
    It then applies that decision and shows whether the winner's lock survived.

HOW TO RUN:
    python test/bug-validation/PD-BUG-100_duplicate_daemon_lock_preservation_validation.py

EXPECTED RESULT (fixed code):
    Disposition = AlreadyRunning, RemoveLock = False, and the winner's lock is
    STILL on disk afterwards  ->  VALIDATION PASSED.

    With the old code the decision would have been "delete", the lock would be
    gone, and the next start would create a duplicate daemon.
"""

import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

# parent: bug-validation -> test -> repo root
PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
LAUNCHER = (
    PROJECT_ROOT
    / "process-framework"
    / "tools"
    / "linkWatcher"
    / "start_linkwatcher_background.ps1"
)
LOCK_NAME = ".linkwatcher.lock"


def _pwsh():
    return shutil.which("pwsh") or shutil.which("pwsh.exe")


def main():
    print("=" * 64)
    print("PD-BUG-100: launcher lock-preservation validation")
    print("=" * 64)

    pwsh = _pwsh()
    if not pwsh:
        print("SKIP: pwsh not found (the launcher is PowerShell).")
        return 0
    if not LAUNCHER.exists():
        print(f"FAIL: launcher not found at {LAUNCHER}")
        return 1

    # A real, live process standing in for the WINNER daemon that holds the lock.
    winner = subprocess.Popen([sys.executable, "-c", "import time; time.sleep(60)"])
    try:
        with tempfile.TemporaryDirectory() as tmp_dir:
            lock = Path(tmp_dir) / LOCK_NAME
            lock.write_text(str(winner.pid), encoding="ascii")

            # A PID for the daemon WE just spawned that has since exited(1) because
            # the winner held the lock. Any value distinct from the winner works.
            spawned_pid = 999999

            print("\nBEFORE")
            print(f"  lock file        : {lock}")
            print(f"  lock owner PID   : {lock.read_text().strip()}  (winner, ALIVE)")
            print(f"  our spawned PID  : {spawned_pid}  (exited because lock was held)")

            ps = (
                f". '{LAUNCHER}'\n"
                f"$d = Get-DaemonExitDisposition -SpawnedPid {spawned_pid} -LockFile '{lock}'\n"
                f'Write-Output ("DISPOSITION=" + $d.Disposition)\n'
                f'Write-Output ("REMOVELOCK=" + $d.RemoveLock)\n'
            )
            proc = subprocess.run(
                [pwsh, "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", ps],
                capture_output=True,
                text=True,
                timeout=60,
            )
            if proc.returncode != 0:
                print(f"FAIL: launcher dot-source failed:\n{proc.stderr}\n{proc.stdout}")
                return 1

            result = {}
            for line in proc.stdout.splitlines():
                if "=" in line:
                    k, _, v = line.partition("=")
                    result[k.strip()] = v.strip()
            disposition = result.get("DISPOSITION")
            remove_lock = result.get("REMOVELOCK") == "True"

            # Apply the launcher's decision exactly as the script does.
            if remove_lock and lock.exists():
                lock.unlink()

            print("\nDECISION")
            print(f"  Disposition      : {disposition}")
            print(f"  RemoveLock       : {remove_lock}")

            survived = lock.exists()
            print("\nAFTER")
            print(f"  winner lock kept : {survived}")
            if survived:
                print(f"  lock owner PID   : {lock.read_text().strip()}")

            print("\n" + "=" * 64)
            if survived and disposition == "AlreadyRunning" and not remove_lock:
                print("VALIDATION PASSED — winner's lock preserved; no duplicate daemon.")
                print("(Old behavior: RemoveLock=True -> lock deleted -> 2nd daemon spawns.)")
                print("=" * 64)
                return 0
            print("VALIDATION FAILED — the running winner's lock was deleted.")
            print("=" * 64)
            return 1
    finally:
        winner.terminate()
        try:
            winner.wait(timeout=5)
        except subprocess.TimeoutExpired:
            winner.kill()


if __name__ == "__main__":
    sys.exit(main())
