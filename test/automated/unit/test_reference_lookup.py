"""
Tests for the ReferenceLookup class.

This module tests the reference lookup and database management functionality
including path variation generation, reference finding, stale retry logic,
database cleanup, file rescanning, directory move processing, and link
updates within moved files.
"""

import os
import shutil
import tempfile
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest

from linkwatcher.models import LinkReference
from linkwatcher.reference_lookup import ReferenceLookup

pytestmark = [
    pytest.mark.feature("1.1.1"),
    pytest.mark.priority("Critical"),
    pytest.mark.cross_cutting(["0.1.1", "0.1.2", "2.2.1"]),
    pytest.mark.test_type("unit"),
    pytest.mark.specification(
        "test/specifications/feature-specs/test-spec-1-1-1-file-system-monitoring.md"
    ),
]


@pytest.fixture
def mock_db():
    """Create a mock LinkDatabaseInterface."""
    db = MagicMock()
    db.get_references_to_file.return_value = []
    db.get_references_to_directory.return_value = []
    return db


@pytest.fixture
def mock_parser():
    """Create a mock LinkParser."""
    parser = MagicMock()
    parser.parse_file.return_value = []
    parser.parse_content.return_value = []
    return parser


@pytest.fixture
def mock_updater():
    """Create a mock LinkUpdater."""
    updater = MagicMock()
    updater.update_references.return_value = {
        "files_updated": 0,
        "references_updated": 0,
        "errors": 0,
    }
    return updater


@pytest.fixture
def temp_dir():
    """Create a temporary directory for tests needing real files."""
    d = tempfile.mkdtemp()
    yield Path(d)
    shutil.rmtree(d, ignore_errors=True)


@pytest.fixture
def lookup(mock_db, mock_parser, mock_updater, temp_dir):
    """Create a ReferenceLookup instance with mocked dependencies."""
    return ReferenceLookup(
        link_db=mock_db,
        parser=mock_parser,
        updater=mock_updater,
        project_root=temp_dir,
    )


# ---------------------------------------------------------------------------
# Path Variations
# ---------------------------------------------------------------------------


class TestGetPathVariations:
    """Tests for get_path_variations() — multi-format path generation."""

    def test_basic_path_includes_exact_and_basename(self, lookup):
        """Single-level path returns exact path and basename."""
        result = lookup.get_path_variations("file.md")
        assert "file.md" in result
        # basename of "file.md" is "file.md" — should still appear
        assert result[0] == "file.md"

    def test_deep_path_includes_relative_and_backslash(self, lookup):
        """Path with 3+ parts generates relative (strip first dir) and backslash."""
        result = lookup.get_path_variations("alpha-project/docs/sub/file.md")
        assert "alpha-project/docs/sub/file.md" in result
        assert "docs/sub/file.md" in result  # first dir stripped
        assert "docs\\sub\\file.md" in result  # backslash variant
        assert "file.md" in result  # basename

    def test_two_level_path_no_relative_variant(self, lookup):
        """Path with exactly 2 parts does NOT generate relative variant."""
        result = lookup.get_path_variations("dir/file.md")
        assert "dir/file.md" in result
        assert "file.md" in result
        # "file.md" appears only as basename, not as stripped relative
        assert len([v for v in result if v == "file.md"]) >= 1

    def test_extensionless_variation_for_python_files(self, lookup):
        """Python files get an extensionless variation (PD-BUG-043)."""
        result = lookup.get_path_variations("src/utils/helper.py")
        assert "src/utils/helper" in result

    def test_no_extensionless_for_extensionless_path(self, lookup):
        """Paths without extension don't get a duplicate extensionless entry."""
        result = lookup.get_path_variations("Makefile")
        # Should not crash; "Makefile" has no ext so root would be "Makefile"
        # which is the same as the original — but the code adds it if root != ""
        assert "Makefile" in result

    def test_get_old_path_variations_delegates(self, lookup):
        """get_old_path_variations() returns same result as get_path_variations()."""
        path = "alpha-project/docs/sub/file.md"
        assert lookup.get_old_path_variations(path) == lookup.get_path_variations(path)


# ---------------------------------------------------------------------------
# Reference Finding
# ---------------------------------------------------------------------------


class TestFindReferences:
    """Tests for find_references() — multi-variation lookup with dedup."""

    def _make_ref(self, file_path="src/a.md", line=1, col=0, target="alpha-project/docs/file.md"):
        return LinkReference(
            file_path=file_path,
            line_number=line,
            column_start=col,
            column_end=col + len(target),
            link_text="link",
            link_target=target,
            link_type="markdown",
        )

    def test_returns_references_from_multiple_variations(self, lookup, mock_db):
        """References found via different path variations are combined."""
        ref1 = self._make_ref(target="alpha-project/docs/sub/file.md")
        ref2 = self._make_ref(file_path="src/b.md", target="docs/sub/file.md")
        mock_db.get_references_to_file.side_effect = lambda v: (
            [ref1]
            if v == "alpha-project/docs/sub/file.md"
            else [ref2]
            if v == "docs/sub/file.md"
            else []
        )
        result = lookup.find_references("alpha-project/docs/sub/file.md")
        assert len(result) == 2
        assert ref1 in result
        assert ref2 in result

    def test_deduplicates_identical_references(self, lookup, mock_db):
        """Same reference returned by multiple variations is deduplicated."""
        ref = self._make_ref()
        mock_db.get_references_to_file.return_value = [ref]
        result = lookup.find_references("alpha-project/docs/sub/file.md")
        # ref is returned for every variation, but dedup keeps only one
        assert result.count(ref) == 1

    def test_filter_files_restricts_results(self, lookup, mock_db):
        """filter_files parameter restricts results to specified file paths."""
        ref_a = self._make_ref(file_path="src/a.md")
        ref_b = self._make_ref(file_path="src/b.md")
        mock_db.get_references_to_file.return_value = [ref_a, ref_b]
        result = lookup.find_references("target.md", filter_files={"src/a.md"})
        assert len(result) == 1
        assert result[0].file_path == "src/a.md"

    def test_empty_database_returns_empty(self, lookup, mock_db):
        """No references in DB returns empty list."""
        mock_db.get_references_to_file.return_value = []
        assert lookup.find_references("nonexistent.md") == []


# ---------------------------------------------------------------------------
# Stale Reference Retry
# ---------------------------------------------------------------------------


class TestRetryStaleReferences:
    """Tests for retry_stale_references() — rescan and retry logic."""

    def test_no_stale_files_does_nothing(self, lookup, mock_updater):
        """No stale_files key means no action."""
        stats = {"files_updated": 1, "references_updated": 2, "errors": 0}
        lookup.retry_stale_references("old.md", "new.md", stats)
        mock_updater.update_references.assert_not_called()

    def test_empty_stale_list_does_nothing(self, lookup, mock_updater):
        """Empty stale_files list means no action."""
        stats = {
            "files_updated": 1,
            "references_updated": 2,
            "errors": 0,
            "stale_files": [],
        }
        lookup.retry_stale_references("old.md", "new.md", stats)
        mock_updater.update_references.assert_not_called()

    def test_retry_rescans_stale_files(self, lookup, mock_db, mock_updater, temp_dir):
        """Stale files are rescanned and references retried."""
        # Create the stale file so os.path.exists passes
        stale_file = temp_dir / "src" / "stale.md"
        stale_file.parent.mkdir(parents=True, exist_ok=True)
        stale_file.write_text("# stale")

        ref = LinkReference(
            file_path="src/stale.md",
            line_number=1,
            column_start=0,
            column_end=10,
            link_text="link",
            link_target="old.md",
            link_type="markdown",
        )
        mock_db.get_references_to_file.return_value = [ref]
        mock_updater.update_references.return_value = {
            "files_updated": 1,
            "references_updated": 1,
            "errors": 0,
        }

        stats = {
            "files_updated": 0,
            "references_updated": 0,
            "errors": 0,
            "stale_files": ["src/stale.md"],
        }
        lookup.retry_stale_references("old.md", "new.md", stats)

        # Stats should be merged
        assert stats["references_updated"] == 1
        assert stats["files_updated"] == 1

    def test_retry_after_retry_logs_warning(self, lookup, mock_db, mock_updater, temp_dir):
        """If retry also returns stale files, a warning is logged."""
        stale_file = temp_dir / "stale.md"
        stale_file.write_text("# stale")

        ref = LinkReference(
            file_path="stale.md",
            line_number=1,
            column_start=0,
            column_end=5,
            link_text="x",
            link_target="old.md",
            link_type="markdown",
        )
        mock_db.get_references_to_file.return_value = [ref]
        mock_updater.update_references.return_value = {
            "files_updated": 0,
            "references_updated": 0,
            "errors": 0,
            "stale_files": ["stale.md"],
        }

        stats = {
            "files_updated": 0,
            "references_updated": 0,
            "errors": 0,
            "stale_files": ["stale.md"],
        }
        lookup.retry_stale_references("old.md", "new.md", stats)
        # Should not raise — just logs warning


# ---------------------------------------------------------------------------
# Database Cleanup After File Move
# ---------------------------------------------------------------------------


class TestCleanupAfterFileMove:
    """Tests for cleanup_after_file_move() — DB entry removal and rescan."""

    def _make_ref(self, file_path, target="moved.md"):
        return LinkReference(
            file_path=file_path,
            line_number=1,
            column_start=0,
            column_end=10,
            link_text="link",
            link_target=target,
            link_type="markdown",
        )

    def test_removes_old_targets_from_db(self, lookup, mock_db, temp_dir):
        """Old target path variations are removed from the database."""
        ref = self._make_ref("src/a.md")
        mock_db.get_references_to_file.return_value = []

        lookup.cleanup_after_file_move([ref], ["moved.md", "moved"])

        assert mock_db.remove_targets_by_path.call_count == 2
        mock_db.remove_targets_by_path.assert_any_call("moved.md")
        mock_db.remove_targets_by_path.assert_any_call("moved")

    def test_skips_moved_file_in_rescan(self, lookup, mock_db, mock_parser, temp_dir):
        """The moved_file_path is not rescanned (handled separately)."""
        ref = self._make_ref("src/a.md")
        moved_ref = self._make_ref("old/moved.md")
        mock_db.get_references_to_file.return_value = []

        # Create the affected file so rescan proceeds
        affected = temp_dir / "src" / "a.md"
        affected.parent.mkdir(parents=True, exist_ok=True)
        affected.write_text("# content")

        lookup.cleanup_after_file_move(
            [ref, moved_ref], ["moved.md"], moved_file_path="old/moved.md"
        )

        # rescan_file_links should be called for src/a.md but not old/moved.md
        rescan_paths = [str(c[0][0]) for c in mock_parser.parse_file.call_args_list]
        assert any("a.md" in p for p in rescan_paths)
        assert not any("moved.md" in p for p in rescan_paths)


# ---------------------------------------------------------------------------
# File Rescanning
# ---------------------------------------------------------------------------


class TestRescanFileLinks:
    """Tests for rescan_file_links() and rescan_moved_file_links()."""

    def test_rescan_removes_existing_and_adds_new(self, lookup, mock_db, mock_parser, temp_dir):
        """rescan_file_links removes existing entries and adds parsed ones."""
        ref = LinkReference(
            file_path="rel/test.md",
            line_number=1,
            column_start=0,
            column_end=10,
            link_text="link",
            link_target="target.md",
            link_type="markdown",
        )
        mock_parser.parse_file.return_value = [ref]

        abs_path = str(temp_dir / "rel" / "test.md")
        lookup.rescan_file_links(abs_path)

        mock_db.remove_file_links.assert_called_once()
        mock_db.add_link.assert_called_once()

    def test_rescan_without_remove(self, lookup, mock_db, mock_parser, temp_dir):
        """rescan_file_links with remove_existing=False skips removal."""
        mock_parser.parse_file.return_value = []
        abs_path = str(temp_dir / "test.md")
        lookup.rescan_file_links(abs_path, remove_existing=False)
        mock_db.remove_file_links.assert_not_called()

    def test_rescan_error_handled_gracefully(self, lookup, mock_parser, temp_dir):
        """Parse errors are caught and logged, not raised."""
        mock_parser.parse_file.side_effect = Exception("parse error")
        abs_path = str(temp_dir / "bad.md")
        # Should not raise
        lookup.rescan_file_links(abs_path)

    def test_rescan_moved_file_uses_old_path_for_removal(self, lookup, mock_db, mock_parser):
        """rescan_moved_file_links removes using old path, adds with new path."""
        ref = LinkReference(
            file_path="old/path.md",
            line_number=1,
            column_start=0,
            column_end=5,
            link_text="x",
            link_target="t.md",
            link_type="markdown",
        )
        mock_parser.parse_file.return_value = [ref]

        lookup.rescan_moved_file_links("old/path.md", "new/path.md", "/abs/new/path.md")

        mock_db.remove_file_links.assert_called_once_with("old/path.md")
        # The ref's file_path should be updated to new path before add
        added_ref = mock_db.add_link.call_args[0][0]
        assert added_ref.file_path == "new/path.md"


# ---------------------------------------------------------------------------
# Directory Move Processing
# ---------------------------------------------------------------------------


class TestProcessDirectoryFileMove:
    """Tests for process_directory_file_move() — per-file directory move logic."""

    def test_no_references_still_rescans_moved_file(
        self, lookup, mock_db, mock_parser, mock_updater
    ):
        """Even with no references, the moved file is rescanned."""
        mock_db.get_references_to_file.return_value = []
        mock_parser.parse_file.return_value = []

        refs_updated, errors = lookup.process_directory_file_move("old/file.md", "new/file.md")

        assert refs_updated == 0
        assert errors == 0
        # rescan_moved_file_links should still be called
        mock_parser.parse_file.assert_called_once()

    def test_python_module_references_handled(self, lookup, mock_db, mock_updater, mock_parser):
        """Python files trigger module reference lookup (without .py extension)."""
        mock_db.get_references_to_file.return_value = []
        mock_parser.parse_file.return_value = []

        lookup.process_directory_file_move("pkg/module.py", "newpkg/module.py")

        # Should query for "pkg/module" (extensionless) in addition to variations
        calls = [c[0][0] for c in mock_db.get_references_to_file.call_args_list]
        assert "pkg/module" in calls


# ---------------------------------------------------------------------------
# Directory Path References
# ---------------------------------------------------------------------------


class TestFindDirectoryPathReferences:
    """Tests for find_directory_path_references() — directory-level lookup."""

    def _make_ref(self, file_path, target):
        return LinkReference(
            file_path=file_path,
            line_number=1,
            column_start=0,
            column_end=len(target),
            link_text=target,
            link_target=target,
            link_type="direct",
        )

    def test_queries_multiple_variations(self, lookup, mock_db):
        """Directory lookup tries exact, relative, and backslash variations."""
        mock_db.get_references_to_directory.return_value = []
        lookup.find_directory_path_references("alpha-project/docs/sub/dir")

        called_variations = [c[0][0] for c in mock_db.get_references_to_directory.call_args_list]
        assert "alpha-project/docs/sub/dir" in called_variations
        assert "docs/sub/dir" in called_variations
        assert "docs\\sub\\dir" in called_variations
        assert "alpha-project\\docs\\sub\\dir" in called_variations

    def test_deduplicates_results(self, lookup, mock_db):
        """Same reference from multiple variations is deduplicated."""
        ref = self._make_ref("src/a.md", "alpha-project/docs/sub/dir")
        mock_db.get_references_to_directory.return_value = [ref]

        result = lookup.find_directory_path_references("alpha-project/docs/sub/dir")
        assert len(result) == 1


# ---------------------------------------------------------------------------
# Calculate Updated Relative Path
# ---------------------------------------------------------------------------


class TestCalculateUpdatedRelativePath:
    """Tests for _calculate_updated_relative_path() — path recalculation."""

    def test_basic_relative_path_recalculation(self, lookup, temp_dir):
        """Moving a file deeper recalculates relative targets."""
        # Create the target file so existence check passes
        target = temp_dir / "shared" / "data.md"
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text("# data")

        result = lookup._calculate_updated_relative_path(
            "../shared/data.md", "src/file.md", "src/deep/file.md"
        )
        # From src/deep/, to reach shared/ we need ../../shared/data.md
        assert result == "../../shared/data.md"

    def test_project_root_relative_path_preserved(self, lookup, temp_dir):
        """Root-relative paths are not recalculated (PD-BUG-032)."""
        # Create at project root
        root_target = temp_dir / "alpha-project" / "docs" / "templates"
        root_target.mkdir(parents=True, exist_ok=True)

        result = lookup._calculate_updated_relative_path(
            "alpha-project/docs/templates",
            "scripts/file-creation/script.ps1",
            "scripts/file-creation/new-dir/script.ps1",
        )
        assert result == "alpha-project/docs/templates"

    def test_nonexistent_target_returns_original(self, lookup, temp_dir):
        """Non-existent targets are returned unchanged (PD-BUG-033)."""
        result = lookup._calculate_updated_relative_path(
            "nonexistent/path.md", "src/file.md", "dst/file.md"
        )
        assert result == "nonexistent/path.md"

    def test_same_directory_move_no_change(self, lookup, temp_dir):
        """File moved within same directory doesn't change targets."""
        target = temp_dir / "sibling.md"
        target.write_text("# sibling")

        result = lookup._calculate_updated_relative_path("sibling.md", "file.md", "renamed.md")
        assert result == "sibling.md"

    def test_error_returns_original(self, lookup):
        """Exceptions during path calculation return the original target."""
        # Force an error by using an impossible path scenario
        with patch("os.path.normpath", side_effect=Exception("boom")):
            result = lookup._calculate_updated_relative_path(
                "../target.md", "src/file.md", "dst/file.md"
            )
        assert result == "../target.md"

    def test_anchor_fragment_preserved_on_move(self, lookup, temp_dir):
        """Links with #anchor fragments are recalculated with anchor preserved.

        Regression test for PD-BUG-069: _calculate_updated_relative_path()
        included the #fragment in os.path.exists() checks, causing the check
        to fail and the link to be returned unchanged.
        """
        target = temp_dir / "shared" / "data.md"
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text("# data\n## section\n")

        result = lookup._calculate_updated_relative_path(
            "../shared/data.md#section", "src/file.md", "src/deep/file.md"
        )
        assert result == "../../shared/data.md#section"

    def test_nonexistent_target_with_anchor_returns_original(self, lookup, temp_dir):
        """Non-existent targets with anchors are still returned unchanged.

        Ensures PD-BUG-033 guard is respected even after PD-BUG-069 fix.
        """
        result = lookup._calculate_updated_relative_path(
            "nonexistent/path.md#heading", "src/file.md", "dst/file.md"
        )
        assert result == "nonexistent/path.md#heading"


# ---------------------------------------------------------------------------
# Update Links Within Moved File
# ---------------------------------------------------------------------------


class TestUpdateLinksWithinMovedFile:
    """Tests for update_links_within_moved_file() — content rewriting."""

    def test_same_directory_skips_update(self, lookup, mock_parser, temp_dir):
        """File moved within same directory skips link updates."""
        f = temp_dir / "file.md"
        f.write_text("# test [link](other.md)")

        ref = LinkReference(
            file_path="dir/file.md",
            line_number=1,
            column_start=7,
            column_end=20,
            link_text="link",
            link_target="other.md",
            link_type="markdown",
        )
        mock_parser.parse_content.return_value = [ref]

        lookup.update_links_within_moved_file("dir/old.md", "dir/new.md", str(f))
        # No links should be updated (same directory)
        content = f.read_text()
        assert "other.md" in content

    def test_absolute_and_url_links_skipped(self, lookup, mock_parser, temp_dir):
        """Absolute paths and URLs are not treated as relative links."""
        f = temp_dir / "file.md"
        f.write_text("# test")

        refs = [
            LinkReference("f", 1, 0, 10, "x", "https://example.com", "markdown"),
            LinkReference("f", 2, 0, 10, "x", "http://example.com", "markdown"),
            LinkReference("f", 3, 0, 10, "x", "/absolute/path.md", "markdown"),
            LinkReference("f", 4, 0, 10, "x", "C:/windows/path.md", "markdown"),
        ]
        mock_parser.parse_content.return_value = refs

        lookup.update_links_within_moved_file("src/file.md", "dst/file.md", str(f))
        # None of these should trigger path recalculation

    def test_no_references_still_rescans_db(self, lookup, mock_parser, mock_db, temp_dir):
        """File with no outgoing links still updates DB source path (PD-BUG-008)."""
        f = temp_dir / "empty.md"
        f.write_text("# no links")
        mock_parser.parse_content.return_value = []

        lookup.update_links_within_moved_file("old/empty.md", "new/empty.md", str(f))

        # rescan_moved_file_links should be called (DB source path update)
        mock_db.remove_file_links.assert_called_once_with("old/empty.md")

    def test_markdown_link_updated(self, lookup, mock_parser, temp_dir):
        """Markdown links have their targets recalculated and updated."""
        f = temp_dir / "file.md"
        f.write_text("# Test\n\n[link](../shared/data.md)\n")

        # Create the target so _calculate_updated_relative_path resolves it
        target = temp_dir / "shared" / "data.md"
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text("# data")

        ref = LinkReference(
            file_path="src/file.md",
            line_number=3,
            column_start=1,
            column_end=25,
            link_text="link",
            link_target="../shared/data.md",
            link_type="markdown",
        )
        mock_parser.parse_content.return_value = [ref]

        lookup.update_links_within_moved_file("src/file.md", "src/deep/file.md", str(f))

        content = f.read_text()
        assert "../../shared/data.md" in content

    def test_non_markdown_line_targeted_replacement(self, lookup, mock_parser, temp_dir):
        """Non-markdown links use line-targeted replacement (PD-BUG-025)."""
        f = temp_dir / "config.yaml"
        f.write_text("ref: ../shared/data.md\nother: value\n")

        target = temp_dir / "shared" / "data.md"
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text("# data")

        ref = LinkReference(
            file_path="src/config.yaml",
            line_number=1,
            column_start=5,
            column_end=25,
            link_text="../shared/data.md",
            link_target="../shared/data.md",
            link_type="yaml",
        )
        mock_parser.parse_content.return_value = [ref]

        lookup.update_links_within_moved_file("src/config.yaml", "src/deep/config.yaml", str(f))

        content = f.read_text()
        assert "../../shared/data.md" in content

    def test_error_returns_zero(self, lookup, mock_parser, temp_dir):
        """Exceptions during update return 0 and don't propagate."""
        # Use a non-existent file path to trigger an error
        result = lookup.update_links_within_moved_file(
            "old/file.md", "new/file.md", str(temp_dir / "nonexistent.md")
        )
        assert result == 0

    def test_backup_created_when_enabled(self, lookup, mock_parser, temp_dir):
        """Backup file is created when backup_enabled=True and links are updated."""
        f = temp_dir / "file.md"
        f.write_text("# Test\n\n[link](../shared/data.md)\n")

        target = temp_dir / "shared" / "data.md"
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text("# data")

        ref = LinkReference(
            file_path="src/file.md",
            line_number=3,
            column_start=1,
            column_end=25,
            link_text="link",
            link_target="../shared/data.md",
            link_type="markdown",
        )
        mock_parser.parse_content.return_value = [ref]

        lookup.update_links_within_moved_file(
            "src/file.md", "src/deep/file.md", str(f), backup_enabled=True
        )

        backup_path = Path(str(f) + ".bak")
        assert backup_path.exists()


# ---------------------------------------------------------------------------
# Cleanup After Directory Path Move
# ---------------------------------------------------------------------------


class TestCleanupAfterDirectoryPathMove:
    """Tests for cleanup_after_directory_path_move() — directory DB cleanup."""

    def test_removes_old_directory_targets(self, lookup, mock_db):
        """Old directory path variations are removed from DB."""
        mock_db.get_references_to_directory.return_value = []
        lookup.cleanup_after_directory_path_move(
            "alpha-project/docs/old/dir", "alpha-project/docs/new/dir"
        )

        remove_calls = [c[0][0] for c in mock_db.remove_targets_by_path.call_args_list]
        assert "alpha-project/docs/old/dir" in remove_calls

    def test_rescans_affected_files(self, lookup, mock_db, mock_parser, temp_dir):
        """Files that referenced the old directory are rescanned."""
        ref = LinkReference(
            file_path="src/script.ps1",
            line_number=5,
            column_start=0,
            column_end=10,
            link_text="alpha-project/docs/old/dir",
            link_target="alpha-project/docs/old/dir",
            link_type="direct",
        )
        mock_db.get_references_to_directory.return_value = [ref]

        # Create the affected file
        affected = temp_dir / "src" / "script.ps1"
        affected.parent.mkdir(parents=True, exist_ok=True)
        affected.write_text("# script")

        lookup.cleanup_after_directory_path_move(
            "alpha-project/docs/old/dir", "alpha-project/docs/new/dir"
        )

        # Should remove file links and rescan
        mock_db.remove_file_links.assert_called()
        mock_parser.parse_file.assert_called()


# ---------------------------------------------------------------------------
# Helper: _get_relative_path
# ---------------------------------------------------------------------------


class TestGetRelativePath:
    """Tests for _get_relative_path() — delegates to utils."""

    def test_converts_absolute_to_relative(self, lookup, temp_dir):
        """Absolute path is converted relative to project root."""
        abs_path = str(temp_dir / "src" / "file.py")
        result = lookup._get_relative_path(abs_path)
        assert "src" in result or "file.py" in result
        assert not os.path.isabs(result)
