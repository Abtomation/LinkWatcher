"""
Document Metadata:
ID: TE-TST-135
Type: Test File
Category: Test
Version: 1.0
Created: 2026-06-08
Updated: 2026-06-08
Feature Id: 0.1.1
Test Name: pd-bug-100 launcher lock cleanup
Test Type: Unit
Component Name: start_linkwatcher_background
Language: Python

PD-BUG-100 regression: the background launcher's post-start cleanup must NOT
delete a lock owned by a different, live LinkWatcher instance.

When two starts race, the loser's main.py correctly exits(1) because the winner
holds the lock. The launcher then sees its spawned process HasExited and, in the
buggy version, unconditionally ran `Remove-Item .linkwatcher.lock` — deleting the
*winner's* lock. With the lock gone, the next start spawns a second daemon, so
two instances persist per project root (the reported symptom).

The fix lives in Get-DaemonExitDisposition in
process-framework/tools/linkWatcher/start_linkwatcher_background.ps1. These tests
dot-source that script (its `InvocationName -eq '.'` guard defines the helpers
without spawning a daemon) and assert the cleanup decision for each ownership
case, with an injectable liveness probe so no real processes are required.
"""

import shutil
import subprocess
from pathlib import Path

import pytest

# parents: [0]=unit [1]=automated [2]=test [3]=repo root
PROJECT_ROOT = Path(__file__).resolve().parents[3]
LAUNCHER = (
    PROJECT_ROOT
    / "process-framework"
    / "tools"
    / "linkWatcher"
    / "start_linkwatcher_background.ps1"
)
LOCK_NAME = ".linkwatcher.lock"

pytestmark = [
    pytest.mark.feature("0.1.1"),
    pytest.mark.priority("Critical"),
    pytest.mark.test_type("unit"),
]


def _pwsh():
    exe = shutil.which("pwsh") or shutil.which("pwsh.exe")
    if not exe:
        pytest.skip("pwsh not available — launcher is PowerShell")
    return exe


def _disposition(lock_dir: Path, spawned_pid: int, alive: bool, lock_content=None):
    """Dot-source the launcher and run Get-DaemonExitDisposition with an injected
    liveness probe. Returns (disposition, remove_lock: bool, owner: str)."""
    lock_file = lock_dir / LOCK_NAME
    if lock_content is not None:
        lock_file.write_text(str(lock_content), encoding="ascii")
    alive_literal = "$true" if alive else "$false"
    ps = (
        f". '{LAUNCHER}'\n"
        f"$d = Get-DaemonExitDisposition -SpawnedPid {spawned_pid} "
        f"-LockFile '{lock_file}' -IsPidAlive {{ param($p) {alive_literal} }}\n"
        f'Write-Output ("DISPOSITION=" + $d.Disposition)\n'
        f'Write-Output ("REMOVELOCK=" + $d.RemoveLock)\n'
        f'Write-Output ("OWNER=" + $d.OwnerPid)\n'
    )
    proc = subprocess.run(
        [_pwsh(), "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", ps],
        capture_output=True,
        text=True,
        timeout=60,
    )
    assert proc.returncode == 0, f"pwsh failed: {proc.stderr}\n{proc.stdout}"
    out = {}
    for line in proc.stdout.splitlines():
        if "=" in line:
            k, _, v = line.partition("=")
            out[k.strip()] = v.strip()
    return out.get("DISPOSITION"), out.get("REMOVELOCK") == "True", out.get("OWNER")


class TestLauncherLockCleanup:
    """PD-BUG-100: the launcher must never delete a live foreign owner's lock."""

    def test_foreign_live_owner_lock_is_preserved(self, tmp_path):
        """THE regression: lock owned by a different, LIVE PID → declined duplicate.

        Must report 'AlreadyRunning' and leave the lock intact. The buggy launcher
        returned RemoveLock=True here, deleting the running winner's lock.
        """
        disposition, remove_lock, owner = _disposition(
            tmp_path, spawned_pid=999999, alive=True, lock_content=4242
        )
        # Strong negative assertion: the foreign lock must NOT be slated for removal.
        assert remove_lock is False, "must NOT delete a live foreign owner's lock"
        assert disposition == "AlreadyRunning"
        assert owner == "4242"
        # And the file itself is still on disk untouched.
        assert (tmp_path / LOCK_NAME).read_text().strip() == "4242"

    def test_own_crashed_lock_is_removed(self, tmp_path):
        """A genuine self-crash (lock holds OUR spawned PID) is still cleaned up."""
        disposition, remove_lock, owner = _disposition(
            tmp_path, spawned_pid=4242, alive=True, lock_content=4242
        )
        assert disposition == "Crashed"
        assert remove_lock is True
        assert owner == "4242"

    def test_foreign_dead_owner_lock_not_removed(self, tmp_path):
        """A foreign DEAD owner is left for main.py's stale-reclaim, not deleted
        by the launcher — the launcher only ever removes its own PID's lock."""
        disposition, remove_lock, _ = _disposition(
            tmp_path, spawned_pid=999999, alive=False, lock_content=4242
        )
        assert disposition == "Crashed"
        assert remove_lock is False

    def test_empty_lock_not_removed(self, tmp_path):
        """An empty lock (crash inside the create-then-write window) has no owner;
        leave it for main.py's settle-read to reclaim rather than racing on it."""
        disposition, remove_lock, _ = _disposition(
            tmp_path, spawned_pid=999999, alive=True, lock_content=""
        )
        assert disposition == "Crashed"
        assert remove_lock is False

    def test_no_lock_file_nothing_to_remove(self, tmp_path):
        """No lock on disk → nothing to remove and no false 'already running'."""
        disposition, remove_lock, _ = _disposition(
            tmp_path, spawned_pid=999999, alive=True, lock_content=None
        )
        assert disposition == "Crashed"
        assert remove_lock is False
