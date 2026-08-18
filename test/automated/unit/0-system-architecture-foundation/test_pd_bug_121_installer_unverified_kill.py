"""
Document Metadata:
ID: TE-TST-154
Type: Test File
Category: Test
Version: 1.0
Created: 2026-08-18
Updated: 2026-08-18
Component Name: install_global
Feature Id: 0.1.1
Language: Python
Test Name: PD Bug 121 Installer Unverified Kill
Test Type: Unit
"""

# PD-BUG-121: the installer force-killed an unverified PID read from a stale
# .linkwatcher.lock.
#
# stop_running_linkwatcher() read the lock file, coerced its contents to an int
# and handed that straight to `taskkill /F` — no command-line check, no main.py
# check, no --project-root match. A PID Windows had recycled to an unrelated
# process (editor, test run, shell) was hard-killed with no clean-shutdown
# chance, reported as a stopped daemon, and the lock unlinked, destroying the
# evidence.
#
# Fix under test (root-cause removal, not identity verification):
#   - stop_running_linkwatcher() and its main() call site are gone. The lock
#     file is never a kill source anywhere in the installer.
#   - stop_daemons_using_venv() — which already ran one line later — remains the
#     single stop mechanism: it identifies daemons by ExecutablePath under the
#     install venv (not by a guessable integer) and tree-kills with /T.
#   - Stale locks are self-healed at daemon startup (main.py acquire_lock).
#
# Test File ID: TE-TST-154
# Created: 2026-08-18

import ast
import subprocess
import sys
from pathlib import Path

import pytest

# deployment/ is not a package on sys.path — add it so the module imports by name.
_PROJECT_ROOT = Path(__file__).resolve().parents[4]
_DEPLOYMENT_DIR = _PROJECT_ROOT / "deployment"
sys.path.insert(0, str(_DEPLOYMENT_DIR))

import install_global  # noqa: E402

_SOURCE_PATH = _DEPLOYMENT_DIR / "install_global.py"
_TREE = ast.parse(_SOURCE_PATH.read_text(encoding="utf-8"))

pytestmark = [
    pytest.mark.feature("0.1.1"),
    pytest.mark.priority("Critical"),
    pytest.mark.test_type("unit"),
]


def _string_literals(tree):
    """Every bare string constant in the module (docstrings included)."""
    return {
        node.value
        for node in ast.walk(tree)
        if isinstance(node, ast.Constant) and isinstance(node.value, str)
    }


def _functions_containing_a_kill(tree):
    """Names of module-level functions that terminate a process.

    Matched on the AST, not the source text, so a comment or docstring
    *explaining* the removed kill path can never satisfy — or trip — this.
    """
    names = set()
    for func in [n for n in ast.walk(tree) if isinstance(n, ast.FunctionDef)]:
        for node in ast.walk(func):
            if isinstance(node, ast.Constant) and node.value == "taskkill":
                names.add(func.name)
            if (
                isinstance(node, ast.Call)
                and isinstance(node.func, ast.Attribute)
                and node.func.attr == "kill"
            ):
                names.add(func.name)
    return names


def _called_names(func_node):
    """Names of every function called directly inside *func_node*."""
    return {
        node.func.id
        for node in ast.walk(func_node)
        if isinstance(node, ast.Call) and isinstance(node.func, ast.Name)
    }


def _function(tree, name):
    for node in ast.walk(tree):
        if isinstance(node, ast.FunctionDef) and node.name == name:
            return node
    raise AssertionError(f"{name}() not found in install_global.py")


def _still_alive(proc, settle=3.0):
    """True if *proc* is still running after *settle* seconds."""
    try:
        proc.wait(timeout=settle)
        return False
    except subprocess.TimeoutExpired:
        return True


@pytest.fixture
def bystander():
    """An unrelated live process — the recycled-PID victim of the bug."""
    proc = subprocess.Popen([sys.executable, "-c", "import time; time.sleep(60)"])
    try:
        yield proc
    finally:
        proc.kill()
        proc.wait(timeout=10)


@pytest.fixture
def stubbed_install(tmp_path, monkeypatch):
    """Run main() against a sandbox project root with every install step stubbed.

    main() derives project_root from the module's __file__, so pointing that at
    a sandbox deployment/ directory redirects the lock-file read into tmp_path.
    Only the daemon-stop sequence is left live.
    """
    fake_deployment = tmp_path / "deployment"
    fake_deployment.mkdir()
    monkeypatch.setattr(install_global, "__file__", str(fake_deployment / "install_global.py"))

    # The venv-daemon stop path is exercised by TE-TST-139 (PD-BUG-106); stub it
    # so this test isolates the lock-file path.
    monkeypatch.setattr(install_global, "stop_daemons_using_venv", lambda *a, **k: None)
    monkeypatch.setattr(install_global, "venv_python_locked", lambda *a, **k: False)
    monkeypatch.setattr(install_global, "check_python_version", lambda *a, **k: True)
    monkeypatch.setattr(install_global, "install_dependencies", lambda *a, **k: True)
    monkeypatch.setattr(install_global, "install_linkwatcher", lambda *a, **k: True)
    monkeypatch.setattr(install_global, "create_linkwatcher_venv", lambda *a, **k: True)
    monkeypatch.setattr(install_global, "create_wrapper_scripts", lambda *a, **k: None)
    monkeypatch.setattr(install_global, "test_installation", lambda *a, **k: True)
    monkeypatch.setattr(install_global, "propagate_config_schema_signal", lambda *a, **k: None)
    monkeypatch.setattr(install_global, "check_release_tag", lambda *a, **k: None)
    monkeypatch.setattr(
        sys, "argv", ["install_global.py", "--install-dir", str(tmp_path / "install")]
    )
    return tmp_path


class TestInstallerNeverKillsAnUnverifiedPid:
    """The bug itself: a lock file must never be a source of kill targets."""

    def test_unrelated_process_named_by_a_stale_lock_survives_the_install(
        self, stubbed_install, bystander
    ):
        (stubbed_install / ".linkwatcher.lock").write_text(str(bystander.pid))

        install_global.main()

        # Negative assertion (the buggy outcome): the bystander must NOT have
        # been terminated. Before the fix, taskkill /F killed it outright.
        assert _still_alive(bystander), (
            "Buggy behavior: the installer hard-killed PID "
            f"{bystander.pid} — an unrelated process — because a stale lock "
            "file named it, with no identity verification"
        )

    def test_stale_lock_file_is_preserved_as_evidence(self, stubbed_install, bystander):
        lock = stubbed_install / ".linkwatcher.lock"
        lock.write_text(str(bystander.pid))

        install_global.main()

        # Before the fix the installer unlinked the lock right after the kill,
        # destroying the only record of what it had targeted.
        assert lock.exists(), "Buggy behavior: the installer destroyed the stale-lock evidence"
        assert lock.read_text().strip() == str(bystander.pid)


class TestNoLockFileKillPathRemains:
    """Structural pins — AST-based, so prose about the removal cannot trip them."""

    def test_installer_reads_no_lock_file_at_all(self):
        assert ".linkwatcher.lock" not in _string_literals(_TREE), (
            "install_global.py still references the lock file; the PID it holds "
            "is unverifiable and must not re-enter the installer"
        )

    def test_only_the_venv_enumeration_path_terminates_processes(self):
        assert _functions_containing_a_kill(_TREE) == {"stop_daemons_using_venv"}, (
            "A second kill path exists. Process termination must come only from "
            "stop_daemons_using_venv(), which identifies daemons by executable "
            "path rather than by a guessable PID"
        )

    def test_main_calls_no_lock_file_stop_function(self):
        assert "stop_running_linkwatcher" not in _called_names(_function(_TREE, "main"))

    def test_surviving_kill_path_tree_kills(self):
        """/T is what makes the surviving path complete: the venv-shim parent and
        its base-interpreter child must both go down (PD-BUG-106)."""
        stop = _function(_TREE, "stop_daemons_using_venv")
        assert "/T" in _string_literals(stop)
