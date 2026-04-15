"""
Document Metadata:
ID: TE-TST-131
Type: Test File
Category: Test
Version: 1.0
Created: 2026-04-12
Updated: 2026-04-12
Test Type: Unit
Component Name: utils
Language: Python
Test Name: ShouldMonitorFileAncestorPath
Feature Id: 6.1.1
"""

# PD-BUG-087 regression tests: should_monitor_file must only check
# path parts relative to project_root, not ancestor directories.
#
# Test File ID: TE-TST-131
# Created: 2026-04-12

import os

import pytest

from linkwatcher.utils import should_monitor_file

pytestmark = [
    pytest.mark.feature("6.1.1"),
    pytest.mark.priority("Critical"),
    pytest.mark.test_type("unit"),
]


class TestShouldMonitorFileAncestorPath:
    """PD-BUG-087: should_monitor_file must ignore ancestor directories above project_root."""

    def test_file_under_ignored_ancestor_accepted_with_project_root(self):
        """File with an ignored dir name in its ancestor path (above project_root)
        should still be accepted when project_root is provided."""
        # Arrange — path has "e2e-acceptance-testing" as ancestor, which is
        # in the default validation_extra_ignored_dirs
        project_root = os.path.normpath("/repo/test/e2e-acceptance-testing/workspace/project")
        file_path = os.path.join(project_root, "docs", "readme.md")
        monitored = {".md"}
        ignored = {"e2e-acceptance-testing", ".git"}

        # Act
        result = should_monitor_file(file_path, monitored, ignored, project_root)

        # Assert — must be True; ancestor "e2e-acceptance-testing" is above project_root
        assert result is True, (
            "should_monitor_file rejected a file because an ancestor directory "
            "above project_root matched ignored_dirs"
        )

    def test_file_in_ignored_subdir_rejected_with_project_root(self):
        """File inside an ignored directory *below* project_root must still
        be rejected even when project_root is provided."""
        project_root = os.path.normpath("/repo/project")
        file_path = os.path.join(project_root, ".git", "config")
        monitored = {".md", ".yaml", ""}  # empty string for extensionless
        ignored = {".git"}

        result = should_monitor_file(file_path, monitored, ignored, project_root)

        assert (
            result is False
        ), "should_monitor_file accepted a file inside an ignored sub-directory"

    def test_backward_compat_no_project_root(self):
        """When project_root is not provided (None), the function falls back
        to checking all path parts — preserving backward compatibility."""
        file_path = os.path.normpath(
            "/repo/test/e2e-acceptance-testing/workspace/project/docs/readme.md"
        )
        monitored = {".md"}
        ignored = {"e2e-acceptance-testing"}

        # Without project_root, ancestor dirs ARE checked (old behavior)
        result = should_monitor_file(file_path, monitored, ignored)

        assert (
            result is False
        ), "Without project_root, ancestor ignored dirs should still be checked"

    def test_multiple_ignored_ancestors_accepted(self):
        """Multiple ignored dir names in ancestors should all be ignored
        when project_root is provided."""
        project_root = os.path.normpath(
            "/repo/archive/fixtures/e2e-acceptance-testing/workspace/project"
        )
        file_path = os.path.join(project_root, "config", "settings.yaml")
        monitored = {".yaml"}
        ignored = {"archive", "fixtures", "e2e-acceptance-testing"}

        result = should_monitor_file(file_path, monitored, ignored, project_root)

        assert result is True

    def test_extension_filter_still_works_with_project_root(self):
        """Extension filtering must still apply when project_root is provided."""
        project_root = os.path.normpath("/repo/project")
        file_path = os.path.join(project_root, "src", "main.exe")
        monitored = {".md", ".py"}
        ignored = set()

        result = should_monitor_file(file_path, monitored, ignored, project_root)

        assert result is False
