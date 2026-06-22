"""
Document Metadata:
ID: TE-TST-140
Type: Test File
Category: Test
Version: 1.0
Created: 2026-06-13
Updated: 2026-06-13
Test Type: Unit
Test Name: PD Bug 110 Installer Venv Rebuild Retry
Component Name: install_global
Language: Python
Feature Id: 0.1.1
"""

# PD-BUG-110: install_global.py venv rebuild races against daemon auto-restart.
#
# The pre-flight lock gate (venv_python_locked) runs in main() BEFORE files are
# copied, but LinkWatcher daemons auto-restart asynchronously (SessionStart
# hooks). A daemon can relaunch during the copy + dependency-install window and
# re-lock <install>/.linkwatcher-venv/Scripts/python.exe, so create_linkwatcher_venv
# fails with Errno 13 / Access denied AFTER files were already copied —
# contradicting the documented abort-before-copy guarantee (half-updated install).
#
# Fix under test (defend the rebuild operation itself):
#   - create_linkwatcher_venv re-stops venv daemons immediately before each
#     creation attempt, and
#   - retries ONCE if `python -m venv` fails with a lock error (the daemon that
#     slipped in is tree-killed, then the rebuild succeeds — mirrors the manual
#     Stop-Process + retry recovery).
#   - Non-lock failures and a second consecutive lock failure still return False
#     (no masking of real errors, no unbounded retry).
#
# Test File ID: TE-TST-140
# Created: 2026-06-13

import subprocess
import sys
from pathlib import Path

import pytest

# deployment/ is not a package on sys.path — add it so the module imports by name.
_PROJECT_ROOT = Path(__file__).resolve().parents[3]
_DEPLOYMENT_DIR = _PROJECT_ROOT / "deployment"
sys.path.insert(0, str(_DEPLOYMENT_DIR))

import install_global  # noqa: E402

pytestmark = [
    pytest.mark.feature("0.1.1"),
    pytest.mark.priority("Standard"),
    pytest.mark.test_type("unit"),
]

# A realistic Windows "interpreter still locked" stderr from `python -m venv`.
LOCK_STDERR = (
    r"Error: [WinError 5] Access is denied: "
    r"'C:\\Users\\u\\bin\\.linkwatcher-venv\\Scripts\\python.exe'"
)
# A failure that is NOT a lock — must not trigger a retry.
NON_LOCK_STDERR = "Error: [Errno 28] No space left on device"


def _is_venv_create(args):
    """The venv-creation subprocess call: [sys.executable, '-m', 'venv', dir]."""
    return len(args) >= 3 and args[1] == "-m" and args[2] == "venv"


class _FakeRun:
    """Records the ordered sequence of side-effecting calls and drives the
    outcome of successive venv-creation attempts.

    `venv_outcomes` is applied to successive venv-create calls:
      "ok"    -> CompletedProcess rc=0
      "lock"  -> raise CalledProcessError with a lock stderr
      "other" -> raise CalledProcessError with a non-lock stderr
    pip / verify subprocess calls always succeed (verify returns 'OK').
    """

    def __init__(self, venv_outcomes):
        self.venv_outcomes = list(venv_outcomes)
        self.calls = []  # "stop_daemons" | "venv_create" | "pip" | "verify"
        self._venv_idx = 0

    def record_stop(self, _install_dir):
        self.calls.append("stop_daemons")

    def run(self, args, **kwargs):
        args = list(args)
        if _is_venv_create(args):
            self.calls.append("venv_create")
            outcome = self.venv_outcomes[self._venv_idx]
            self._venv_idx += 1
            if outcome == "lock":
                raise subprocess.CalledProcessError(1, args, output="", stderr=LOCK_STDERR)
            if outcome == "other":
                raise subprocess.CalledProcessError(1, args, output="", stderr=NON_LOCK_STDERR)
            return subprocess.CompletedProcess(args, 0, stdout="", stderr="")
        if "-c" in args:  # the import-verification call
            self.calls.append("verify")
            return subprocess.CompletedProcess(args, 0, stdout="OK", stderr="")
        self.calls.append("pip")  # pip upgrade / install
        return subprocess.CompletedProcess(args, 0, stdout="", stderr="")


@pytest.fixture
def wire(monkeypatch):
    """Install a _FakeRun with the given venv outcomes and patch the module."""

    def _wire(venv_outcomes):
        fake = _FakeRun(venv_outcomes)
        monkeypatch.setattr(install_global, "stop_daemons_using_venv", fake.record_stop)
        monkeypatch.setattr(install_global.subprocess, "run", fake.run)
        return fake

    return _wire


class TestRebuildRaceDefense:
    """create_linkwatcher_venv must defend the rebuild against an
    auto-restarted daemon re-locking the venv interpreter (PD-BUG-110)."""

    def test_re_stops_daemons_before_creating_the_venv(self, tmp_path, wire):
        """The vulnerable operation is guarded at point-of-use, not only in main()."""
        fake = wire(["ok"])

        assert install_global.create_linkwatcher_venv(tmp_path) is True
        assert "stop_daemons" in fake.calls, "rebuild never re-stops venv daemons"
        assert fake.calls.index("stop_daemons") < fake.calls.index("venv_create")

    def test_retries_once_after_re_stop_on_lock_error(self, tmp_path, wire):
        """First attempt hits a locked interpreter; re-stop + retry then succeeds."""
        fake = wire(["lock", "ok"])

        assert install_global.create_linkwatcher_venv(tmp_path) is True
        # Exactly two creation attempts were made.
        assert fake.calls.count("venv_create") == 2
        # A re-stop occurred between the failed attempt and the successful retry.
        first = fake.calls.index("venv_create")
        second = fake.calls.index("venv_create", first + 1)
        assert (
            "stop_daemons" in fake.calls[first + 1 : second]
        ), "retry must re-stop the daemon that slipped in before retrying"

    def test_does_not_retry_on_non_lock_failure(self, tmp_path, wire):
        """A genuine failure (e.g. disk full) must surface immediately, not be retried."""
        fake = wire(["other"])

        assert install_global.create_linkwatcher_venv(tmp_path) is False
        assert fake.calls.count("venv_create") == 1, "non-lock errors must not retry"

    def test_gives_up_after_two_consecutive_lock_errors(self, tmp_path, wire):
        """Retry is bounded: a persistently locked venv fails after the retry, no loop."""
        fake = wire(["lock", "lock"])

        assert install_global.create_linkwatcher_venv(tmp_path) is False
        assert fake.calls.count("venv_create") == 2, "retry must be bounded to one extra attempt"
