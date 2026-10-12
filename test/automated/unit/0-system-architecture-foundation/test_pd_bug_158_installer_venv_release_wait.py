"""
Document Metadata:
ID: TE-TST-166
Type: Test File
Category: Test
Version: 1.0
Created: 2026-08-31
Updated: 2026-08-31
Component Name: install_global
Feature Id: 0.1.1
Language: Python
Test Name: PD Bug 158 Installer Venv Release Wait
Test Type: Unit
"""

# PD-BUG-158: the installer aborts on a false venv-lock reading because the
# stop pass does not wait for the processes it killed to exit.
#
# main() (install_global.py) runs, on consecutive statements:
#
#     stop_daemons_using_venv(install_dir)      # taskkill /F /T per PID
#     if venv_python_locked(install_dir): abort # one open("ab"), no tolerance
#
# taskkill signals termination; Windows tears the tree down and releases the
# executable's file handle a short moment later. The gate has zero tolerance
# for that moment, so a release deploy aborts before copying any files while
# reporting a running process that is already on its way out.
#
# MEASURED on 2026-08-31 by replaying this exact sequence against two live
# daemons: the gate read locked=True 1967 ms in (the abort), and the lock
# cleared 52 ms later with zero surviving venv processes. A second identical
# run did not reproduce — the window is real but intermittent, which is why
# the fix waits for the condition instead of sleeping a fixed amount.
#
# Fix under test:
#   - wait_for_venv_python_release(install_dir, ...): bounded poll of the
#     actual condition the gate tests
#   - stop_daemons_using_venv(): waits for that release before returning, so
#     it is responsible for the effect it claims to have produced
#   - venv_lock_holder_report(): says what is really holding the interpreter
#     instead of asserting a running process that may not exist
#
# Test File ID: TE-TST-166
# Created: 2026-08-31

import subprocess
import sys
from pathlib import Path

import pytest

# deployment/ is not a package on sys.path — add it so the module imports by name.
_PROJECT_ROOT = Path(__file__).resolve().parents[4]
_DEPLOYMENT_DIR = _PROJECT_ROOT / "deployment"
sys.path.insert(0, str(_DEPLOYMENT_DIR))

import install_global  # noqa: E402

pytestmark = [
    pytest.mark.feature("0.1.1"),
    pytest.mark.priority("Standard"),
    pytest.mark.test_type("unit"),
]


def _make_venv(install_dir):
    """Create a minimal fake install-dir venv with a python.exe placeholder."""
    scripts = install_dir / ".linkwatcher-venv" / "Scripts"
    scripts.mkdir(parents=True)
    (scripts / "python.exe").write_bytes(b"fake exe")
    return install_dir / ".linkwatcher-venv"


class _LockStub:
    """venv_python_locked stand-in: locked for the first `hold` calls, then free.

    Models the residual window measured on real daemons — the handle is still
    denied for a moment after taskkill returns, then clears on its own.
    """

    def __init__(self, hold):
        self.hold = hold
        self.calls = 0

    def __call__(self, install_dir):
        self.calls += 1
        return self.calls <= self.hold


def _silence_kills(monkeypatch, calls=None):
    """Make subprocess.run a no-op so no real taskkill is issued."""

    def _run(args, **kw):
        if calls is not None:
            calls.append(args)
        return subprocess.CompletedProcess(args, 0, stdout="", stderr="")

    monkeypatch.setattr(install_global.subprocess, "run", _run)


class TestStopWaitsForRelease:
    """The regression pin: stop must not return while the interpreter is locked."""

    def test_stop_does_not_return_while_venv_python_is_still_locked(self, tmp_path, monkeypatch):
        """Reproduces PD-BUG-158 at the exact production seam.

        main() calls venv_python_locked on the statement after
        stop_daemons_using_venv returns. If the stop pass returns during the
        residual window, that next call reads True and the install aborts.
        """
        _make_venv(tmp_path)
        monkeypatch.setattr(install_global.platform, "system", lambda: "Windows")
        monkeypatch.setattr(
            install_global,
            "find_venv_daemon_processes",
            lambda venv_dir: [(111, 'cmd --project-root "C:\\a"'), (222, "cmd2")],
        )
        _silence_kills(monkeypatch)
        lock = _LockStub(hold=2)
        monkeypatch.setattr(install_global, "venv_python_locked", lock)

        install_global.stop_daemons_using_venv(tmp_path)

        # This is main()'s very next statement. It must not see a lock.
        assert install_global.venv_python_locked(tmp_path) is False, (
            "stop_daemons_using_venv returned during the residual window — "
            "the pre-flight gate aborts the install on a lock that is dissolving"
        )
        # And it must have got there by polling, not by luck.
        assert lock.calls > 1, "stop_daemons_using_venv never waited for the release"

    def test_stop_waits_for_a_lock_left_by_a_kill_it_did_not_make(self, tmp_path, monkeypatch):
        """The wait is unconditional — the defect does not require our own kill.

        Code Review 2026-08-31 (Minor): guarding the wait on `stopped` left the
        same defect class uncovered whenever the lock is dissolving from a
        process killed outside the installer moments earlier — a Control Panel
        closed by hand before an install, which step 3 of release-process.md
        invites. Nothing is in `stopped` then, so a guarded wait never runs and
        the gate on the next statement aborts the release anyway.
        """
        _make_venv(tmp_path)
        monkeypatch.setattr(install_global.platform, "system", lambda: "Windows")
        monkeypatch.setattr(install_global, "find_venv_daemon_processes", lambda venv_dir: [])
        _silence_kills(monkeypatch)
        lock = _LockStub(hold=2)
        monkeypatch.setattr(install_global, "venv_python_locked", lock)

        install_global.stop_daemons_using_venv(tmp_path)

        assert install_global.venv_python_locked(tmp_path) is False, (
            "stop returned while a lock left by an external kill was still "
            "dissolving — main()'s next statement aborts the install on it"
        )
        assert lock.calls > 1, "stop did not wait when the kill came from outside the installer"

    def test_stop_costs_one_lock_check_when_the_interpreter_is_free(self, tmp_path, monkeypatch):
        """The unconditional wait is cheap: a clean install pays one open(), not the timeout."""
        _make_venv(tmp_path)
        monkeypatch.setattr(install_global.platform, "system", lambda: "Windows")
        monkeypatch.setattr(install_global, "find_venv_daemon_processes", lambda venv_dir: [])
        _silence_kills(monkeypatch)
        lock = _LockStub(hold=0)
        monkeypatch.setattr(install_global, "venv_python_locked", lock)

        install_global.stop_daemons_using_venv(tmp_path)

        assert lock.calls == 1, "the free-interpreter path must not poll"

    def test_stop_warns_when_the_lock_outlives_the_timeout(self, tmp_path, monkeypatch, capsys):
        """A genuine, non-transient holder must be reported, not waited on forever."""
        _make_venv(tmp_path)
        monkeypatch.setattr(install_global.platform, "system", lambda: "Windows")
        monkeypatch.setattr(
            install_global, "find_venv_daemon_processes", lambda venv_dir: [(111, "cmd")]
        )
        _silence_kills(monkeypatch)
        monkeypatch.setattr(install_global, "venv_python_locked", lambda install_dir: True)
        monkeypatch.setattr(install_global, "VENV_RELEASE_TIMEOUT", 0.05)
        monkeypatch.setattr(install_global, "VENV_RELEASE_POLL_INTERVAL", 0.01)

        install_global.stop_daemons_using_venv(tmp_path)

        out = capsys.readouterr().out
        assert "WARNING" in out
        # Code Review 2026-08-31 (Suggestion): the warning must state the timeout
        # the wait actually ran for. Rendering the constant with :.0f reported
        # "0s" for a 0.05s wait — a duration that never elapsed.
        assert "0.05s" in out, f"warning did not report the effective timeout: {out!r}"


class TestWaitForVenvPythonRelease:
    """The bounded wait itself."""

    def test_returns_true_as_soon_as_the_lock_clears(self, tmp_path, monkeypatch):
        lock = _LockStub(hold=3)
        monkeypatch.setattr(install_global, "venv_python_locked", lock)

        assert (
            install_global.wait_for_venv_python_release(tmp_path, timeout=5, poll_interval=0.001)
            is True
        )
        assert lock.calls == 4, "should stop polling the moment the lock clears"

    def test_returns_true_immediately_when_never_locked(self, tmp_path, monkeypatch):
        lock = _LockStub(hold=0)
        monkeypatch.setattr(install_global, "venv_python_locked", lock)

        assert (
            install_global.wait_for_venv_python_release(tmp_path, timeout=5, poll_interval=0.001)
            is True
        )
        assert lock.calls == 1

    def test_returns_false_when_the_lock_never_clears(self, tmp_path, monkeypatch):
        """Bounded: a permanent holder must not hang the installer."""
        monkeypatch.setattr(install_global, "venv_python_locked", lambda install_dir: True)

        assert (
            install_global.wait_for_venv_python_release(tmp_path, timeout=0.05, poll_interval=0.01)
            is False
        )


class TestVenvLockHolderReport:
    """Diagnostics: the abort message must describe reality (PD-BUG-158, OB)."""

    def test_names_the_processes_still_running_from_the_venv(self, tmp_path, monkeypatch):
        _make_venv(tmp_path)
        monkeypatch.setattr(
            install_global,
            "find_venv_daemon_processes",
            lambda venv_dir: [(9632, "cmd"), (23128, "cmd2")],
        )

        report = install_global.venv_lock_holder_report(tmp_path)

        assert "9632" in report and "23128" in report

    def test_says_the_holder_is_outside_the_venv_when_none_are_found(self, tmp_path, monkeypatch):
        """The old message asserted a running process even when none existed.

        That claim sent the operator hunting for a process that was not there.
        """
        _make_venv(tmp_path)
        monkeypatch.setattr(install_global, "find_venv_daemon_processes", lambda venv_dir: [])

        report = install_global.venv_lock_holder_report(tmp_path)

        assert "No process is running from the install venv" in report


class TestMainAbortMessage:
    """The OB half pinned where production reaches it — main()'s abort path.

    Code Review 2026-08-31 (Major) rejected the first fix here:
    venv_lock_holder_report was defined and unit-tested in isolation but never
    called, so the installer still printed the message this bug was filed
    against. The helper tests above passed the whole time — they exercised a
    function production never invoked. These tests drive main() instead, so the
    wiring itself is what is under test.
    """

    @pytest.fixture
    def abort_run(self, tmp_path, monkeypatch, capsys):
        """Drive main() to its pre-flight abort; return what it printed."""

        def _run(holders=(), stopped=()):
            monkeypatch.setattr(install_global, "stop_daemons_using_venv", lambda d: list(stopped))
            monkeypatch.setattr(install_global, "venv_python_locked", lambda d: True)
            monkeypatch.setattr(
                install_global, "find_venv_daemon_processes", lambda venv_dir: list(holders)
            )
            monkeypatch.setattr(sys, "argv", ["install_global.py", "--install-dir", str(tmp_path)])

            with pytest.raises(SystemExit):
                install_global.main()

            return capsys.readouterr().out

        return _run

    def test_abort_does_not_assert_a_running_process_when_none_exists(self, abort_run):
        """The reported defect: the message named a process that was not there.

        Negative assertion on the old text — asserting only that the new text is
        present would pass with the buggy sentence still printed alongside it.
        """
        out = abort_run(holders=(), stopped=(111, 222))

        assert "locked by a running process" not in out, (
            "main() still prints the message PD-BUG-158 was filed against — "
            "venv_lock_holder_report is not wired into the abort path"
        )
        assert "No process is running from the install venv" in out

    def test_abort_names_the_surviving_venv_processes(self, abort_run):
        out = abort_run(holders=[(9632, "cmd"), (23128, "cmd2")])

        assert "9632" in out and "23128" in out

    def test_abort_reports_how_many_processes_the_installer_stopped(self, abort_run):
        """Pins the consumer of stop_daemons_using_venv's return value.

        "we stopped 4 and nothing survives, yet it is still locked" and "we
        stopped nothing and nothing survives" are different diagnoses; the count
        is what separates them. Code Review 2026-08-31 flagged the documented
        return value as having no consumer at either call site.
        """
        out = abort_run(holders=(), stopped=(111, 222, 333))

        # Asserted as a whole phrase: a bare "3" would also match the tmp_path
        # in the message and pass without the count ever being printed.
        assert (
            "Processes stopped by this installer: 3" in out
        ), f"the stopped count never reaches the operator: {out!r}"
