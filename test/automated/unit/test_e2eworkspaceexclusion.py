"""
Document Metadata:
ID: TE-TST-138
Type: Test File
Category: Test
Version: 1.0
Created: 2026-06-11
Updated: 2026-06-11
Feature Id: 1.1.1
Language: Python
Component Name: Config
Test Name: E2EWorkspaceExclusion
Test Type: Unit

Regression guard for PD-BUG-105: the project's LinkWatcher daemon must not
watch test/e2e-acceptance-testing/ — scoped per-test daemons are the only
writers inside their workspaces during E2E execution. The exclusion lives in
the per-project config (tools/linkwatcher/linkwatcher-config.yaml,
ignored_directories), which the daemon loads via --config since PF-IMP-1115.

Because a config-file ignored_directories REPLACES the built-in default set
wholesale (merge semantics), these tests also guard against the enumeration
silently dropping a built-in default.
"""

from pathlib import Path

import pytest

from linkwatcher.config import LinkWatcherConfig
from linkwatcher.utils import should_monitor_file

pytestmark = [
    pytest.mark.feature("1.1.1"),
    pytest.mark.priority("Critical"),
    pytest.mark.test_type("unit"),
]

PROJECT_ROOT = Path(__file__).resolve().parents[3]
ACTIVE_CONFIG = PROJECT_ROOT / "tools" / "linkwatcher" / "linkwatcher-config.yaml"


@pytest.fixture(scope="module")
def active_config():
    assert ACTIVE_CONFIG.exists(), f"active per-project config missing: {ACTIVE_CONFIG}"
    return LinkWatcherConfig.from_file(str(ACTIVE_CONFIG))


class TestE2EWorkspaceExclusion:
    """PD-BUG-105: project daemon must skip the E2E acceptance-testing tree."""

    def test_config_excludes_e2e_acceptance_testing(self, active_config):
        assert "e2e-acceptance-testing" in active_config.ignored_directories, (
            "tools/linkwatcher/linkwatcher-config.yaml must list "
            "'e2e-acceptance-testing' in ignored_directories — without it the "
            "project daemon live-updates E2E workspaces over the scoped "
            "per-test daemons (PD-BUG-105)"
        )

    def test_config_preserves_all_builtin_default_ignores(self, active_config):
        # ignored_directories in a config file replaces the default set
        # wholesale; the project config must therefore re-enumerate every
        # built-in default or the daemon starts watching e.g. .git.
        defaults = LinkWatcherConfig().ignored_directories
        dropped = defaults - active_config.ignored_directories
        assert not dropped, (
            f"project config ignored_directories dropped built-in defaults: "
            f"{sorted(dropped)} — enumerate the full default set plus additions"
        )

    def test_workspace_file_is_not_monitored(self, active_config):
        workspace_file = str(
            PROJECT_ROOT
            / "test"
            / "e2e-acceptance-testing"
            / "dry-run-mode-preview-without-changes"
            / "workspace"
            / "docs"
            / "readme.md"
        )
        assert not should_monitor_file(
            workspace_file,
            active_config.monitored_extensions,
            active_config.ignored_directories,
            str(PROJECT_ROOT),
        ), (
            "a markdown file inside an E2E workspace must NOT be monitored by "
            "the project daemon (PD-BUG-105: dry-run/ignore/backup expectations "
            "were overridden by concurrent default-config live updates)"
        )

    def test_exclusion_is_not_overbroad(self, active_config):
        # Positive control: ordinary project docs must still be monitored,
        # so the exclusion fixes the bug without disabling the core value prop.
        ordinary_doc = str(PROJECT_ROOT / "doc" / "user" / "handbooks" / "quick-reference.md")
        assert should_monitor_file(
            ordinary_doc,
            active_config.monitored_extensions,
            active_config.ignored_directories,
            str(PROJECT_ROOT),
        ), "ordinary project markdown must remain monitored after the exclusion"
