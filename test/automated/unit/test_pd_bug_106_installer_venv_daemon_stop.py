"""
Document Metadata:
ID: TE-TST-139
Type: Test File
Category: Test
Version: 1.0
Created: 2026-06-11
Updated: 2026-06-11
Feature Id: 0.1.1
Test Type: Unit
Language: Python
Component Name: install_global
Test Name: PD Bug 106 Installer Venv Daemon Stop
"""

# PD-BUG-106: install_global.py venv rebuild fails when another project's
# daemon holds the shared venv.
#
# stop_running_linkwatcher() only stops the daemon of the source project (via
# its .linkwatcher.lock). Daemons of other projects run from the same shared
# <install>/.linkwatcher-venv and lock its python.exe, so the venv recreation
# step fails with Permission denied and the install exits 1 mid-flow (files
# copied, but no venv/wrapper/smoke-test).
#
# Fix under test:
#   - stop_daemons_using_venv(install_dir): enumerate ALL processes whose
#     executable lives under the install-dir venv and tree-kill them
#   - venv_python_locked(install_dir): pre-flight gate — abort BEFORE any
#     files are copied if the venv python.exe is still locked
#   - main() wiring: both run before install_linkwatcher / create_linkwatcher_venv
#
# Test File ID: TE-TST-139
# Created: 2026-06-11

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
    pytest.mark.priority("Critical"),
    pytest.mark.test_type("unit"),
]


def _make_venv(install_dir):
    """Create a minimal fake install-dir venv with a python.exe placeholder."""
    scripts = install_dir / ".linkwatcher-venv" / "Scripts"
    scripts.mkdir(parents=True)
    (scripts / "python.exe").write_bytes(b"fake exe")
    return install_dir / ".linkwatcher-venv"


class TestParseDaemonLines:
    """Pure parsing of the PowerShell 'PID|CommandLine' enumeration output."""

    def test_parses_pids_and_command_lines(self):
        out = (
            '17404|"C:\\Users\\u\\bin\\.linkwatcher-venv\\Scripts\\python.exe" '
            'C:\\Users\\u\\bin\\main.py --project-root "C:\\proj\\appdev"\r\n'
            '22222|"C:\\Users\\u\\bin\\.linkwatcher-venv\\Scripts\\pythonw.exe" something\r\n'
        )
        procs = install_global.parse_daemon_lines(out)
        assert [pid for pid, _ in procs] == [17404, 22222]
        assert "--project-root" in procs[0][1]

    def test_skips_blank_and_malformed_lines(self):
        out = "\r\n\r\nnot-a-pid|cmd\r\nno-separator-line\r\n123|ok\r\n"
        procs = install_global.parse_daemon_lines(out)
        assert procs == [(123, "ok")]

    def test_empty_output_yields_no_processes(self):
        assert install_global.parse_daemon_lines("") == []


class TestProjectRootFromCmdline:
    """Extracting the owning project from a daemon command line (for reporting)."""

    def test_extracts_quoted_project_root(self):
        cmd = (
            '"C:\\Users\\u\\bin\\.linkwatcher-venv\\Scripts\\python.exe" '
            'C:\\Users\\u\\bin\\main.py --project-root "C:\\proj\\appdev" '
            '--log-file "C:\\proj\\appdev\\logs\\lw.txt"'
        )
        assert install_global.project_root_from_cmdline(cmd) == "C:\\proj\\appdev"

    def test_returns_none_when_absent(self):
        assert install_global.project_root_from_cmdline('"python.exe" main.py') is None


class TestStopDaemonsUsingVenv:
    """Orchestration: every enumerated daemon is tree-killed; safe no-ops otherwise."""

    def test_tree_kills_every_enumerated_daemon(self, tmp_path, monkeypatch):
        _make_venv(tmp_path)
        monkeypatch.setattr(install_global.platform, "system", lambda: "Windows")
        monkeypatch.setattr(
            install_global,
            "find_venv_daemon_processes",
            lambda venv_dir: [(111, 'cmd --project-root "C:\\a"'), (222, "cmd2")],
        )
        calls = []
        monkeypatch.setattr(
            install_global.subprocess,
            "run",
            lambda args, **kw: calls.append(args)
            or subprocess.CompletedProcess(args, 0, stdout="", stderr=""),
        )

        install_global.stop_daemons_using_venv(tmp_path)

        assert ["taskkill", "/F", "/T", "/PID", "111"] in calls
        assert ["taskkill", "/F", "/T", "/PID", "222"] in calls
        # Tree-kill is mandatory: the venv-shim parent spawns a base-interpreter
        # child; killing only the parent would leave the child running.
        assert all("/T" in c for c in calls if c[0] == "taskkill")

    def test_noop_when_venv_does_not_exist(self, tmp_path, monkeypatch):
        monkeypatch.setattr(install_global.platform, "system", lambda: "Windows")
        calls = []
        monkeypatch.setattr(
            install_global.subprocess,
            "run",
            lambda args, **kw: calls.append(args)
            or subprocess.CompletedProcess(args, 0, stdout="", stderr=""),
        )

        install_global.stop_daemons_using_venv(tmp_path)

        assert calls == []

    def test_noop_on_non_windows(self, tmp_path, monkeypatch):
        _make_venv(tmp_path)
        monkeypatch.setattr(install_global.platform, "system", lambda: "Linux")
        calls = []
        monkeypatch.setattr(
            install_global.subprocess,
            "run",
            lambda args, **kw: calls.append(args)
            or subprocess.CompletedProcess(args, 0, stdout="", stderr=""),
        )

        install_global.stop_daemons_using_venv(tmp_path)

        assert calls == []

    def test_enumeration_failure_is_nonfatal(self, tmp_path, monkeypatch):
        """A failing PowerShell query must not crash the install (best-effort)."""
        _make_venv(tmp_path)
        monkeypatch.setattr(install_global.platform, "system", lambda: "Windows")
        monkeypatch.setattr(
            install_global.subprocess,
            "run",
            lambda args, **kw: subprocess.CompletedProcess(args, 1, stdout="", stderr="boom"),
        )

        install_global.stop_daemons_using_venv(tmp_path)  # must not raise


class TestFindVenvDaemonProcesses:
    """Enumeration wrapper around the PowerShell Win32_Process query."""

    def test_returns_parsed_processes_on_success(self, tmp_path, monkeypatch):
        venv_dir = _make_venv(tmp_path)
        monkeypatch.setattr(
            install_global.subprocess,
            "run",
            lambda args, **kw: subprocess.CompletedProcess(
                args, 0, stdout="17404|some cmd\r\n", stderr=""
            ),
        )
        assert install_global.find_venv_daemon_processes(venv_dir) == [(17404, "some cmd")]

    def test_returns_empty_on_query_failure(self, tmp_path, monkeypatch):
        venv_dir = _make_venv(tmp_path)
        monkeypatch.setattr(
            install_global.subprocess,
            "run",
            lambda args, **kw: subprocess.CompletedProcess(args, 1, stdout="", stderr="err"),
        )
        assert install_global.find_venv_daemon_processes(venv_dir) == []

    def test_returns_empty_when_powershell_unavailable(self, tmp_path, monkeypatch):
        venv_dir = _make_venv(tmp_path)

        def _raise(args, **kw):
            raise OSError("powershell not found")

        monkeypatch.setattr(install_global.subprocess, "run", _raise)
        assert install_global.find_venv_daemon_processes(venv_dir) == []


class TestVenvPythonLocked:
    """Pre-flight gate: detect a still-locked venv python.exe before copying."""

    def test_false_when_venv_absent(self, tmp_path):
        assert install_global.venv_python_locked(tmp_path) is False

    def test_false_when_python_writable(self, tmp_path):
        _make_venv(tmp_path)
        assert install_global.venv_python_locked(tmp_path) is False

    def test_true_when_python_locked(self, tmp_path, monkeypatch):
        _make_venv(tmp_path)

        def _deny(self, *args, **kwargs):
            raise PermissionError(13, "Permission denied", str(self))

        monkeypatch.setattr(Path, "open", _deny)
        assert install_global.venv_python_locked(tmp_path) is True


class TestMainFlowWiring:
    """The bug itself: main() must stop venv daemons and gate on the lock
    BEFORE any files are copied or the venv is rebuilt."""

    @pytest.fixture
    def wired_main(self, tmp_path, monkeypatch):
        """Stub every install step, recording call order."""
        order = []

        def record(name, ret=None):
            def _f(*a, **k):
                order.append(name)
                return ret

            return _f

        monkeypatch.setattr(install_global, "stop_running_linkwatcher", record("stop_project"))
        monkeypatch.setattr(install_global, "stop_daemons_using_venv", record("stop_venv_daemons"))
        monkeypatch.setattr(install_global, "venv_python_locked", record("lock_gate", False))
        monkeypatch.setattr(install_global, "check_python_version", record("pyver", True))
        monkeypatch.setattr(install_global, "install_dependencies", record("deps", True))
        monkeypatch.setattr(install_global, "install_linkwatcher", record("copy", True))
        monkeypatch.setattr(install_global, "create_linkwatcher_venv", record("venv", True))
        monkeypatch.setattr(install_global, "create_wrapper_scripts", record("wrappers"))
        monkeypatch.setattr(install_global, "test_installation", record("smoke", True))
        monkeypatch.setattr(install_global, "propagate_config_schema_signal", record("schema"))
        monkeypatch.setattr(install_global, "check_release_tag", record("tag"))
        monkeypatch.setattr(sys, "argv", ["install_global.py", "--install-dir", str(tmp_path)])
        return order

    def test_main_stops_venv_daemons_before_copy_and_venv_rebuild(self, wired_main):
        install_global.main()
        order = wired_main
        assert (
            "stop_venv_daemons" in order
        ), "Buggy behavior: installer never stops other projects' daemons"
        assert order.index("stop_venv_daemons") < order.index("copy")
        assert order.index("stop_venv_daemons") < order.index("venv")

    def test_main_aborts_before_copy_when_venv_still_locked(self, wired_main, monkeypatch):
        monkeypatch.setattr(
            install_global, "venv_python_locked", lambda d: wired_main.append("lock_gate") or True
        )
        with pytest.raises(SystemExit):
            install_global.main()
        # Negative assertion (the old buggy outcome): no partial state — file
        # copy must NOT have happened when the venv is still locked.
        assert "copy" not in wired_main
        assert "venv" not in wired_main
