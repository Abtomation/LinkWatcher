"""
PD-BUG-077 Regression Test: Startup script must use dedicated venv Python.

Validates that start_linkwatcher_background.ps1 uses a dedicated LinkWatcher
venv Python interpreter instead of bare 'python', which can resolve to a
project's .venv and fail silently.

Test File ID: TE-TST-130
Created: 2026-04-07
"""

from pathlib import Path

import pytest

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent.parent

pytestmark = [
    pytest.mark.feature("3.1.1"),
    pytest.mark.priority("Standard"),
    pytest.mark.test_type("bug_validation"),
]


class TestStartupScriptVenvUsage:
    """Regression tests for PD-BUG-077: bare python in startup script."""

    @pytest.fixture
    def startup_script_content(self):
        script_path = (
            PROJECT_ROOT
            / "process-framework"
            / "tools"
            / "linkWatcher"
            / "start_linkwatcher_background.ps1"
        )
        assert script_path.exists(), f"Startup script not found: {script_path}"
        return script_path.read_text(encoding="utf-8")

    def test_no_bare_python_in_start_process(self, startup_script_content):
        """PD-BUG-077: Start-Process must NOT use bare 'python' as -FilePath.

        Bare 'python' resolves to project .venv in projects with virtual
        environments, causing silent import failures.
        """
        assert '-FilePath "python"' not in startup_script_content, (
            "Startup script still uses bare 'python' in Start-Process. "
            "Must use dedicated LinkWatcher venv Python interpreter."
        )

    def test_uses_linkwatcher_venv_python(self, startup_script_content):
        """PD-BUG-077: Startup script must reference a dedicated LinkWatcher venv."""
        assert ".linkwatcher-venv" in startup_script_content, (
            "Startup script does not reference .linkwatcher-venv. "
            "Must use dedicated venv to isolate from project environments."
        )

    def test_startup_verification_exists(self, startup_script_content):
        """PD-BUG-077: Script must verify the process survives initialization.

        The old script reported 'started successfully' before the process
        had time to crash on missing imports.
        """
        assert "HasExited" in startup_script_content or "Exited" in startup_script_content, (
            "Startup script lacks post-start verification. "
            "Must check that process survives initialization."
        )


class TestLinkWatcherVenvSetup:
    """Tests for the dedicated LinkWatcher venv installation."""

    def test_install_global_creates_venv(self):
        """PD-BUG-077: install_global.py must handle venv creation."""
        install_script = PROJECT_ROOT / "deployment" / "install_global.py"
        assert (
            install_script.exists()
        ), "install_global.py not found at deployment/install_global.py."
        content = install_script.read_text(encoding="utf-8")
        assert "create_linkwatcher_venv" in content, (
            "install_global.py does not contain venv creation logic. "
            "It must create a dedicated .linkwatcher-venv during installation."
        )
