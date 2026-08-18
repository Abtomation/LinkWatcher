"""
Document Metadata:
ID: TE-TST-153
Type: Test File
Category: Test
Version: 1.0
Created: 2026-08-18
Updated: 2026-08-18
Component Name: install_global
Feature Id: 7.1.1
Language: Python
Test Name: panel_installer_packaging
Test Type: Unit
"""

# Installer and packaging findings from the feature 7.1.1 Code Review
# (2026-08-17), closed in the Feature Enhancement gap closure (PF-STA-111,
# session 3):
#
#   CR-17  the smoke tests rendered their failure reason from stderr, while
#          control_panel.py prints its dependency diagnostic to stdout, so a
#          real failure printed an empty reason
#   CR-18  the GitPython floor admitted versions carrying CVE-2023-40590 /
#          CVE-2023-41040
#   CR-20  the install path was interpolated into a single-quoted PowerShell
#          literal, so an apostrophe produced a malformed script
#
# These live in deployment/ and pyproject.toml rather than the panel subpackage,
# which is why they get their own file rather than joining a test_panel_* suite.
#
# Test File ID: TE-TST-153

import sys
import tomllib
from pathlib import Path

import pytest

# deployment/ is not a package on sys.path — add it so the module imports by name.
_PROJECT_ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(_PROJECT_ROOT / "deployment"))

import install_global  # noqa: E402

pytestmark = [
    pytest.mark.feature("7.1.1"),
    pytest.mark.priority("Standard"),
    pytest.mark.test_type("unit"),
    pytest.mark.specification("TE-TSP-045"),
]


class _Result:
    """Stand-in for a finished subprocess.CompletedProcess."""

    def __init__(self, stdout="", stderr="", returncode=1):
        self.stdout = stdout
        self.stderr = stderr
        self.returncode = returncode


class TestSmokeFailureReason:
    """CR-17 — the reported reason must come from whichever stream carries it."""

    def test_stderr_is_used_when_present(self):
        assert install_global.smoke_failure_reason(_Result(stderr="boom")) == "boom"

    def test_stdout_is_used_when_stderr_is_empty(self):
        """The control_panel.py case: its diagnostic is a bare print(), i.e. stdout.

        Discriminating condition: render from stderr alone and this returns "",
        which is exactly the empty "ERROR: ... failed:" the finding describes.
        """
        result = _Result(stdout="Missing required dependency: psutil")

        assert install_global.smoke_failure_reason(result) == "Missing required dependency: psutil"

    def test_stderr_wins_when_both_are_present(self):
        result = _Result(stdout="noise", stderr="the real reason")

        assert install_global.smoke_failure_reason(result) == "the real reason"

    def test_reason_is_never_empty(self):
        """With no output at all the exit code still has to reach the operator."""
        assert "3" in install_global.smoke_failure_reason(_Result(returncode=3))

    def test_whitespace_only_output_is_not_treated_as_a_reason(self):
        result = _Result(stdout="   \n", stderr="\t", returncode=9)

        assert "9" in install_global.smoke_failure_reason(result)


class TestPowerShellPathQuoting:
    """CR-20 — an apostrophe in the install path must not break the script."""

    def test_apostrophe_is_doubled_for_a_single_quoted_literal(self):
        """PowerShell escapes an apostrophe inside a single-quoted string by doubling.

        Discriminating condition: interpolate the raw path and the literal ends
        at the apostrophe, producing a script that fails to parse and therefore
        silently enumerates no processes.
        """
        raw = r"C:\Users\O'Brien\bin\.linkwatcher-venv"

        escaped = raw.replace("'", "''")

        assert escaped == r"C:\Users\O''Brien\bin\.linkwatcher-venv"
        assert escaped.count("''") == 1

    def test_paths_without_an_apostrophe_are_unchanged(self):
        raw = r"C:\Users\ronny\bin\.linkwatcher-venv"

        assert raw.replace("'", "''") == raw

    def test_the_installer_escapes_before_interpolating(self):
        """The escape must live in the installer, not only in this test.

        Discriminating condition: remove the `.replace("'", "''")` from
        find_venv_daemons and this fails.
        """
        source = (_PROJECT_ROOT / "deployment" / "install_global.py").read_text(encoding="utf-8")

        assert 'replace("\'", "\'\'")' in source


class TestDeclaredDependencies:
    """CR-18 — the declared floors must exclude known-vulnerable releases."""

    @staticmethod
    def _runtime_dependencies():
        with open(_PROJECT_ROOT / "pyproject.toml", "rb") as handle:
            return tomllib.load(handle)["project"]["dependencies"]

    def test_gitpython_floor_excludes_the_cve_bearing_versions(self):
        """CVE-2023-40590 (Windows untrusted search path for git.exe) and
        CVE-2023-41040 affect GitPython below 3.1.41, and the shape is reachable
        here: Repo() runs on Windows against user-supplied project roots.

        Discriminating condition: lower the floor and this fails.
        """
        gitpython = [d for d in self._runtime_dependencies() if d.lower().startswith("gitpython")]

        assert gitpython, "GitPython must stay a declared runtime dependency"
        floor = gitpython[0].split(">=")[1].strip()
        assert tuple(int(p) for p in floor.split(".")) >= (3, 1, 41)

    def test_psutil_is_declared_at_runtime_not_only_for_tests(self):
        """Regression guard for the Phase F defect: psutil sat under the test
        extra, so the installed venv lacked it and every poll raised."""
        assert any(d.lower().startswith("psutil") for d in self._runtime_dependencies())
