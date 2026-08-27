"""
Document Metadata:
ID: TE-TST-155
Type: Test File
Category: Test
Version: 1.0
Created: 2026-08-19
Updated: 2026-08-19
Component Name: utils
Feature Id: 6.1.1
Language: Python
Test Name: ShouldMonitorFileExtensionCase
Test Type: Unit
"""

# PD-BUG-129 regression tests (second half): should_monitor_file must compare
# extensions case-insensitively on BOTH sides.
#
# The function lowercases the file suffix it derives from splitext but not the
# configured extension set, so the case-insensitive matching the project
# documents was only half implemented: a ".MD" *file* already matches a ".md"
# config entry, while a ".MD" *config entry* matches nothing at all. That is
# the same silent-no-match failure as the dotless entry this bug is filed for —
# the scan simply selects no files and reports a clean result.
#
# Test File ID: TE-TST-155
# Created: 2026-08-19

import os

import pytest

from linkwatcher.utils import should_monitor_file

pytestmark = [
    pytest.mark.feature("6.1.1"),
    pytest.mark.priority("Critical"),
    pytest.mark.cross_cutting(["0.1.3", "1.1.1"]),
    pytest.mark.test_type("unit"),
]

PROJECT_ROOT = os.path.normpath("/repo/project")
IGNORED_DIRS = {".git", "node_modules"}


def _path(name):
    return os.path.join(PROJECT_ROOT, "docs", name)


class TestShouldMonitorFileExtensionCase:
    """PD-BUG-129: an uppercase configured extension must match, like an
    uppercase file already does."""

    # ---- the defect: the configured side was never normalized -------------

    def test_uppercase_config_entry_matches_lowercase_file(self):
        assert should_monitor_file(_path("readme.md"), {".MD"}, IGNORED_DIRS, PROJECT_ROOT)

    def test_uppercase_config_entry_matches_uppercase_file(self):
        """Both sides uppercase still missed pre-fix: the file suffix is
        lowercased to `.md` and compared against an un-normalized `.MD`."""
        assert should_monitor_file(_path("README.MD"), {".MD"}, IGNORED_DIRS, PROJECT_ROOT)

    def test_mixed_case_config_entry_matches(self):
        assert should_monitor_file(_path("readme.md"), {".Md"}, IGNORED_DIRS, PROJECT_ROOT)

    def test_uppercase_entry_does_not_shadow_others_in_the_set(self):
        """A realistic set mixing cases must match every member."""
        extensions = {".MD", ".yaml", ".Json"}

        assert should_monitor_file(_path("a.md"), extensions, IGNORED_DIRS, PROJECT_ROOT)
        assert should_monitor_file(_path("b.yaml"), extensions, IGNORED_DIRS, PROJECT_ROOT)
        assert should_monitor_file(_path("c.json"), extensions, IGNORED_DIRS, PROJECT_ROOT)

    # ---- controls -----------------------------------------------------------

    def test_control_lowercase_config_matches_lowercase_file(self):
        """The ordinary path must be untouched."""
        assert should_monitor_file(_path("readme.md"), {".md"}, IGNORED_DIRS, PROJECT_ROOT)

    def test_control_lowercase_config_already_matches_uppercase_file(self):
        """Passes pre-fix — this is the half of the asymmetry that always
        worked, and the evidence that case-insensitivity was the intent."""
        assert should_monitor_file(_path("README.MD"), {".md"}, IGNORED_DIRS, PROJECT_ROOT)

    def test_control_unmonitored_extension_is_still_rejected(self):
        """The negative assertion: a fix that normalizes too eagerly (or
        matches on a substring) would start accepting everything."""
        assert not should_monitor_file(_path("notes.txt"), {".md"}, IGNORED_DIRS, PROJECT_ROOT)

    def test_control_dotless_config_entry_still_matches_nothing(self):
        """Case normalization must not paper over the dotless entry — that stays
        a config error `validate()` reports, not something to silently accept."""
        assert not should_monitor_file(_path("readme.md"), {"md"}, IGNORED_DIRS, PROJECT_ROOT)

    def test_control_ignored_directory_still_rejected(self):
        """Directory filtering must be unaffected by the extension change."""
        path = os.path.join(PROJECT_ROOT, "node_modules", "readme.md")

        assert not should_monitor_file(path, {".MD"}, IGNORED_DIRS, PROJECT_ROOT)

    def test_control_empty_extension_set_matches_nothing(self):
        assert not should_monitor_file(_path("readme.md"), set(), IGNORED_DIRS, PROJECT_ROOT)
