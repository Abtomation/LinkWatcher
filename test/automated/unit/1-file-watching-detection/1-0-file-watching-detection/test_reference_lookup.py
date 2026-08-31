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
from linkwatcher.parser import LinkParser
from linkwatcher.reference_lookup import ReferenceLookup
from linkwatcher.updater import LinkUpdater

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
    # PD-BUG-116: real boolean — a bare MagicMock attribute is truthy, which
    # would send every write test down the dry-run path.
    updater.dry_run = False
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


class TestBug120TrailingSeparatorPreserved:
    """Regression tests for PD-BUG-120: the authored trailing separator was
    stripped from links recalculated inside a moved file.

    ``os.path.relpath`` drops a trailing separator, so a directory reference
    authored as ``doc/x/`` came back as ``../doc/x``. Sibling of PD-BUG-118,
    which fixed the same loss on the *other* path (references in OTHER files,
    via the shared ``utils.apply_trailing_separator_style`` at the
    ``PathResolver.calculate_new_target`` choke point) — that choke point never
    sees the links recalculated here.

    A rewrite changes WHERE a target points, never HOW it was written. The
    damaging case is a path authored as a concatenation prefix in a moved
    ``.py``/``.ps1``/``.yaml`` (``logs/linkwatcher/`` → ``../logs/linkwatcher``),
    which silently breaks every downstream concatenation.
    """

    @pytest.fixture
    def dir_target(self, temp_dir):
        """A real directory target, referenced from a file at the project root."""
        d = temp_dir / "doc" / "state-tracking"
        d.mkdir(parents=True, exist_ok=True)
        (d / "keep.md").write_text("# keep")
        return d

    def test_bug120_main_branch_keeps_trailing_slash(self, lookup, dir_target):
        """Main branch (target exists, containing file changed directory)."""
        result = lookup._calculate_updated_relative_path(
            "doc/state-tracking/", "notes.md", "sub/notes.md"
        )
        assert result == "../doc/state-tracking/"
        assert result != "../doc/state-tracking", "PD-BUG-120: trailing separator was dropped"

    def test_bug120_dot_slash_authored_form_keeps_trailing_slash(self, lookup, dir_target):
        """The ``./dir/`` authored form loses its separator through the same path."""
        result = lookup._calculate_updated_relative_path(
            "./doc/state-tracking/", "notes.md", "sub/notes.md"
        )
        assert result.endswith("/"), "PD-BUG-120: trailing separator was dropped"
        assert result == "../doc/state-tracking/"

    def test_bug120_backslash_authored_form_keeps_a_trailing_separator(self, lookup, dir_target):
        """A backslash-authored directory reference still ends in a separator.

        The recalculated path is forward-slash form, so the restored separator
        matches the result's own style rather than producing ``../doc/x\\``.
        """
        result = lookup._calculate_updated_relative_path(
            "doc\\state-tracking\\", "notes.md", "sub/notes.md"
        )
        assert result == "../doc/state-tracking/"
        assert not result.endswith("\\"), "must not mix separator styles in one path"

    def test_bug120_move_memory_branch_keeps_trailing_slash(self, lookup, temp_dir):
        """Move-memory branch: the target itself moved in the same operation."""
        relocated = temp_dir / "doc" / "relocated"
        relocated.mkdir(parents=True, exist_ok=True)
        (relocated / "keep.md").write_text("# keep")
        lookup.record_move("doc/vacated", "doc/relocated")

        result = lookup._calculate_updated_relative_path("doc/vacated/", "notes.md", "sub/notes.md")
        assert result == "../doc/relocated/"
        assert result != "../doc/relocated", "PD-BUG-120: trailing separator was dropped"

    def test_bug120_move_memory_to_root_keeps_trailing_slash(self, lookup, temp_dir):
        """Move-memory branch with an empty new_dir (file moved to the root).

        Distinct return site: the move-memory target is returned as-is instead
        of going through ``os.path.relpath``.
        """
        relocated = temp_dir / "doc" / "relocated"
        relocated.mkdir(parents=True, exist_ok=True)
        (relocated / "keep.md").write_text("# keep")
        lookup.record_move("doc/vacated", "doc/relocated")

        result = lookup._calculate_updated_relative_path(
            "../doc/vacated/", "sub/notes.md", "notes.md"
        )
        assert result == "doc/relocated/"
        assert result != "doc/relocated", "PD-BUG-120: trailing separator was dropped"

    def test_bug120_trailing_slash_with_anchor_keeps_both(self, lookup, dir_target):
        """The separator belongs before the #fragment, not after it."""
        result = lookup._calculate_updated_relative_path(
            "doc/state-tracking/#top", "notes.md", "sub/notes.md"
        )
        assert result == "../doc/state-tracking/#top"

    def test_bug120_no_separator_invented_when_none_authored(self, lookup, dir_target):
        """Control: a directory reference authored WITHOUT a separator keeps none."""
        result = lookup._calculate_updated_relative_path(
            "doc/state-tracking", "notes.md", "sub/notes.md"
        )
        assert result == "../doc/state-tracking"

    def test_bug120_file_target_unaffected(self, lookup, dir_target):
        """Control: file references are untouched by the separator restoration."""
        result = lookup._calculate_updated_relative_path(
            "doc/state-tracking/keep.md", "notes.md", "sub/notes.md"
        )
        assert result == "../doc/state-tracking/keep.md"


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

    def _redepth_scenario(self, mock_parser, temp_dir):
        """Set up the standard re-depth scenario: file.md links to ../shared/data.md."""
        f = temp_dir / "file.md"
        original = "# Test\n\n[link](../shared/data.md)\n"
        f.write_text(original)

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
        return f, original

    def test_dry_run_prevents_write(self, lookup, mock_parser, mock_updater, temp_dir):
        """Dry-run mode must not rewrite the moved file on disk (PD-BUG-116)."""
        mock_updater.dry_run = True
        f, original = self._redepth_scenario(mock_parser, temp_dir)

        lookup.update_links_within_moved_file(
            "src/file.md", "src/deep/file.md", str(f), backup_enabled=True
        )

        content = f.read_text()
        assert content == original
        assert "../../shared/data.md" not in content
        assert not Path(str(f) + ".bak").exists()

    def test_dry_run_rescans_original_content(self, lookup, mock_parser, mock_updater, temp_dir):
        """In dry-run the DB rescan must index the on-disk (original) content,
        not the previewed rewrite (PD-BUG-116)."""
        mock_updater.dry_run = True
        f, original = self._redepth_scenario(mock_parser, temp_dir)

        lookup.update_links_within_moved_file("src/file.md", "src/deep/file.md", str(f))

        # parse_content runs twice: link discovery, then the DB rescan.
        rescan_content = mock_parser.parse_content.call_args_list[-1][0][0]
        assert rescan_content == original
        assert "../../shared/data.md" not in rescan_content

    def test_normal_mode_still_writes(self, lookup, mock_parser, mock_updater, temp_dir):
        """Non-dry-run mode still rewrites the moved file (fixture guard, PD-BUG-116)."""
        mock_updater.dry_run = False
        f, _ = self._redepth_scenario(mock_parser, temp_dir)

        lookup.update_links_within_moved_file("src/file.md", "src/deep/file.md", str(f))

        assert "../../shared/data.md" in f.read_text()


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


# One backslash character, and the doubled form a .py/.json author MUST write to
# express ONE separator inside an escaped string literal.
BS = chr(92)
ESC = BS * 2


class TestBug124TrailingSeparatorStyleIsConsistent:
    """PD-BUG-124 regression on the ``reference_lookup`` path.

    ``apply_trailing_separator_style`` chose the restored separator from the
    RESULT's own style, falling back to the AUTHORED style only when the result
    carried no separator.  ``_calculate_updated_relative_path`` always emits
    forward-slash output, so one authored backslash form produced two different
    answers depending only on how deep the result happened to be: a
    multi-segment result got a forward slash (correct), while a single-segment
    result got a bare backslash -- which, in a ``.py`` file, escapes the closing
    quote of the literal it is written into.

    The separator now follows the style this module actually emits, so the
    answer no longer depends on the result's depth.  Companion of
    ``TestBug120TrailingSeparatorPreserved`` above, whose backslash test already
    pinned the multi-segment half of this contract.
    """

    @pytest.fixture
    def logs_dir(self, temp_dir):
        d = temp_dir / "logs"
        d.mkdir(parents=True, exist_ok=True)
        (d / "x.txt").write_text("x")
        return d

    def test_single_segment_result_does_not_emit_a_bare_backslash(self, lookup, logs_dir):
        """The reported Case B: ``sub/collect.py`` moves to the project root."""
        result = lookup._calculate_updated_relative_path(
            ".." + ESC + "logs" + ESC, "sub/collect.py", "collect.py"
        )

        assert result == "logs/", "expected forward-slash form, got {!r}".format(result)
        assert not result.endswith(BS), (
            "PD-BUG-124: a bare trailing backslash escapes the closing quote of "
            "the .py string literal it is written into"
        )

    def test_style_does_not_depend_on_result_depth(self, lookup, logs_dir):
        """One authored form must not yield two separator styles.

        Same authored target and same origin, two destination depths -- both
        genuinely recalculated, so the restored separator must match.  (A
        same-directory 'move' would not do: the authored-form guard returns the
        original untouched, which is correct but proves nothing here.)
        """
        authored = ".." + ESC + "logs" + ESC
        single_segment = lookup._calculate_updated_relative_path(
            authored, "sub/collect.py", "collect.py"
        )
        multi_segment = lookup._calculate_updated_relative_path(
            authored, "sub/collect.py", "sub/deep/collect.py"
        )

        assert single_segment == "logs/", "unexpected: {!r}".format(single_segment)
        assert multi_segment == "../../logs/", "unexpected: {!r}".format(multi_segment)
        assert (
            single_segment[-1] == multi_segment[-1]
        ), "separator style depends on result depth: {!r} vs {!r}".format(
            single_segment, multi_segment
        )


# ---------------------------------------------------------------------------
# PD-BUG-150 — within-moved-file rewrite must honour column positions
# ---------------------------------------------------------------------------


class TestBug150ColumnPositionIgnored:
    """PD-BUG-150 regression: position-blind replacement inside a moved file.

    ``_replace_links_in_lines`` rewrote every non-markdown reference with
    ``lines[idx].replace(target, new, 1)``, discarding the ``column_start`` /
    ``column_end`` the parser supplies.  When a line carried two or more
    references whose targets are duplicates or nested, EVERY replacement landed
    on the LEFTMOST match:

      * the first span was rewritten a second time (compounded to a wrong
        depth, e.g. ``../doc/`` -> ``../../../doc/``), because the old target
        survives as a substring of its own replacement -- always true for the
        ``../`` depth family a move-deeper produces; and
      * the later span was never touched, so it stayed stale.

    Both outcomes are silent: ``moved_file_links_updated`` reports the full
    count and no warning is emitted.

    Sibling of PD-BUG-098, which fixed the same defect class in the OTHER
    rewrite path (``updater._apply_replacements``); the tests there are
    ``TestOverlappingReferenceCorruption`` in ``test_updater.py``.

    These tests drive the REAL parser and the REAL updater end to end, so the
    column values under test are the ones the parser actually produces rather
    than hand-picked constants that could agree with a broken implementation.

    Each assertion compares the WHOLE rewritten line, not a substring count.
    Counting occurrences is not discriminating here: dropping the
    descending-column ordering splices the second replacement at stale offsets
    and yields ``Both `../../doc/` an../../doc/oc/` are ...`` -- which still
    contains ``../../doc/`` exactly twice and no over-deepened path, so a
    count-based assertion passes on visibly corrupted output.  Verified by
    mutation while writing these tests.
    """

    @pytest.fixture
    def real_lookup(self, mock_db, temp_dir):
        """ReferenceLookup wired to a real parser and a real updater."""
        return ReferenceLookup(
            link_db=mock_db,
            parser=LinkParser(),
            updater=LinkUpdater(str(temp_dir)),
            project_root=temp_dir,
        )

    @staticmethod
    def _move_deeper(lookup, temp_dir, filename, line, extra_dirs=()):
        """Lay out a project, place ``line`` in the moved file, run the rewrite.

        The file is written directly at its NEW location because
        ``update_links_within_moved_file`` only ever reads the new path.

        Returns:
            Tuple of (links_updated, file content after the rewrite).
        """
        (temp_dir / "doc").mkdir(parents=True, exist_ok=True)
        (temp_dir / "doc" / "a.md").write_text("# a\n", encoding="utf-8")
        for extra in extra_dirs:
            (temp_dir / extra).mkdir(parents=True, exist_ok=True)

        (temp_dir / "sub" / "deeper").mkdir(parents=True, exist_ok=True)
        moved = temp_dir / "sub" / "deeper" / filename
        moved.write_text(line, encoding="utf-8")

        count = lookup.update_links_within_moved_file(
            "sub/{}".format(filename), "sub/deeper/{}".format(filename), str(moved)
        )
        return count, moved.read_text(encoding="utf-8")

    def test_duplicate_directory_refs_each_rewritten_at_its_own_position(
        self, real_lookup, temp_dir
    ):
        """The filed reproduction: one directory referenced twice on one line."""
        count, content = self._move_deeper(
            real_lookup,
            temp_dir,
            "note.md",
            "Both `../doc/` and `../doc/` are the same real directory.\n",
        )

        assert content == "Both `../../doc/` and `../../doc/` are the same real directory.\n", (
            "PD-BUG-150: each span must be rewritten where the parser found it. "
            "Pre-fix this compounded the first span to ../../../doc/ and left the "
            "second stale; got {!r}".format(content)
        )
        assert count == 2

    def test_duplicate_file_refs_each_rewritten_at_its_own_position(self, real_lookup, temp_dir):
        """Same defect with real FILE links -- no prose involved.

        This is the shape that leaves a genuinely broken path on disk, which is
        why PD-BUG-150 was split out of PD-BUG-149 rather than folded into it.
        """
        count, content = self._move_deeper(
            real_lookup,
            temp_dir,
            "note.md",
            "Run `../doc/a.md` then `../doc/a.md` again.\n",
        )

        assert content == "Run `../../doc/a.md` then `../../doc/a.md` again.\n", (
            "PD-BUG-150: pre-fix this produced `../../../doc/a.md` (resolves "
            "nowhere) alongside a stale `../doc/a.md`; got {!r}".format(content)
        )
        assert count == 2

    def test_nested_targets_still_rewritten_correctly(self, real_lookup, temp_dir):
        """Control: two DISTINCT nested targets already worked -- keep it so.

        ``../doc/`` does not survive inside ``../../doc/sub/``'s replacement in
        a way that misdirects the second rewrite, so this case passed before the
        fix.  It guards against an over-correction that breaks nesting.
        """
        count, content = self._move_deeper(
            real_lookup,
            temp_dir,
            "note.md",
            "See `../doc/` and `../doc/sub/` here.\n",
            extra_dirs=("doc/sub",),
        )

        assert (
            content == "See `../../doc/` and `../../doc/sub/` here.\n"
        ), "a nested pair must survive the fix unchanged: {!r}".format(content)
        assert count == 2

    def test_distinct_targets_on_one_line_unaffected(self, real_lookup, temp_dir):
        """Control: two unrelated targets on one line -- no interference."""
        count, content = self._move_deeper(
            real_lookup,
            temp_dir,
            "note.md",
            "See `../doc/` and `../other/` here.\n",
            extra_dirs=("other",),
        )

        assert (
            content == "See `../../doc/` and `../../other/` here.\n"
        ), "unrelated targets on one line must not interfere: {!r}".format(content)
        assert count == 2

    def test_three_duplicate_refs_on_one_line(self, real_lookup, temp_dir):
        """Three copies compounded hardest -- the shape seen in the incident.

        The PD-BUG-149 evidence recorded ``../`` reaching ``../../../../``
        where several spans shared one line; with N duplicates the leftmost span
        absorbs all N rewrites.
        """
        count, content = self._move_deeper(
            real_lookup,
            temp_dir,
            "note.md",
            "One `../doc/`, two `../doc/`, three `../doc/`.\n",
        )

        assert content == ("One `../../doc/`, two `../../doc/`, three `../../doc/`.\n"), (
            "PD-BUG-150: with three copies the leftmost span absorbed all three "
            "rewrites, reaching ../../../../doc/; got {!r}".format(content)
        )
        assert count == 3

    def test_duplicate_markdown_links_each_rewritten_without_warning(self, real_lookup, temp_dir):
        """Duplicate markdown links: one rewrite each, no false warning.

        Originally the markdown branch rewrote every occurrence of a target in a
        single content-global pass, so a second reference to the same target
        found nothing left to change and was reported as
        ``link_pattern_not_found`` -- a warning naming a real, correctly-rewritten
        link.  De-duplicating the targets removed the artefact.

        PD-BUG-153 removed the content-global pass itself: each reference is now
        rewritten at its own recorded span, so duplicates are no longer collapsed
        and each is counted.  Both must still be rewritten, and neither may be
        reported as missing -- now under the unified
        ``link_target_not_found_on_line`` event, which is the one this path can
        actually emit.
        """
        spy = MagicMock()
        with patch.object(real_lookup, "logger", spy):
            count, content = self._move_deeper(
                real_lookup,
                temp_dir,
                "note.md",
                "See [a](../doc/a.md) and again [a](../doc/a.md).\n",
            )

        assert (
            content == "See [a](../../doc/a.md) and again [a](../../doc/a.md).\n"
        ), "both markdown links must be rewritten: {!r}".format(content)
        assert count == 2, "each reference is rewritten at its own span and counted"

        warned = [c.args[0] for c in spy.warning.call_args_list if c.args]
        assert (
            "link_target_not_found_on_line" not in warned
        ), "a correctly-rewritten duplicate must not be reported as missing: {!r}".format(warned)

    def test_contained_overlap_does_not_chop_the_outer_replacement(
        self, lookup, mock_parser, temp_dir
    ):
        """A span nested inside another must not corrupt the outer rewrite.

        Refs are hand-built here rather than parsed: a single ``parse_content``
        pass emits one reference per span, so this shape is not reachable from
        the parser today (probed across markdown / YAML / JSON / Python /
        PowerShell lines while writing these tests).  The pre-pass is carried
        anyway because the OTHER rewrite path proved the failure mode real
        (PD-BUG-098) and both paths now share one implementation -- letting the
        two diverge again is what produced this bug family.  Without the
        pre-pass the inner replacement widens the line, the outer ref's
        recorded columns then point into shifted text, and the splice leaves
        ``...file.md.md``.
        """
        (temp_dir / "doc" / "sub").mkdir(parents=True, exist_ok=True)
        (temp_dir / "doc" / "sub" / "file.md").write_text("# f", encoding="utf-8")

        moved = temp_dir / "note.md"
        moved.write_text("See ../doc/sub/file.md here.\n", encoding="utf-8")

        inner = LinkReference(
            file_path="sub/note.md",
            line_number=1,
            column_start=4,
            column_end=15,
            link_text="",
            link_target="../doc/sub/",
            link_type="markdown-standalone",
        )
        outer = LinkReference(
            file_path="sub/note.md",
            line_number=1,
            column_start=4,
            column_end=22,
            link_text="",
            link_target="../doc/sub/file.md",
            link_type="markdown-standalone",
        )
        # Inner first: without the pre-pass this is the order that corrupts.
        mock_parser.parse_content.return_value = [inner, outer]

        lookup.update_links_within_moved_file("sub/note.md", "sub/deeper/note.md", str(moved))

        assert moved.read_text(encoding="utf-8") == "See ../../doc/sub/file.md here.\n", (
            "PD-BUG-098 shape: the outer replacement was spliced against stale "
            "columns, leaving a chopped tail: {!r}".format(moved.read_text(encoding="utf-8"))
        )

    # ------------------------------------------------------------------
    # Reference-definition shapes.
    #
    # Added at rework after Code Review (2026-08-30) rejected the first
    # PD-BUG-150 fix.  Phase 1 routed every non-MARKDOWN type into the
    # positional splice, but a MARKDOWN_REFERENCE span covers the WHOLE
    # definition line (the parser records ``match.start()``/``match.end()``
    # of ``[label]: target "title"``), so the splice overwrote label and
    # title along with the target -- silently, counted as a success.
    #
    # updater.py never had this problem: it dispatches on link type
    # (``_replace_in_line``) before falling through to positional
    # replacement.  Phase 1 adopted the guarded primitive without its
    # guard, so the fix that set out to end the divergence between the two
    # rewrite paths reintroduced a narrower one.  The dispatch now lives
    # in ``linkwatcher.replacement`` beside the primitive it guards, which
    # is what stops the next recurrence.
    #
    # Bound measured end to end across every link-type shape the parsers
    # emit: MARKDOWN_REFERENCE is the ONLY affected type.  All three of
    # its shapes are covered below because all three were damaged --
    # the no-title and directory forms lose the whole ``[label]: `` prefix,
    # not merely a title.
    # ------------------------------------------------------------------

    def test_reference_definition_with_title_keeps_label_and_title(self, real_lookup, temp_dir):
        """``[label]: target "title"`` -- only the target may change."""
        count, content = self._move_deeper(
            real_lookup,
            temp_dir,
            "note.md",
            '[lbl]: ../doc/a.md "Title"\n',
        )

        assert content == '[lbl]: ../../doc/a.md "Title"\n', (
            "the reference definition must survive intact: the splice against a "
            "whole-line span left the bare target ../../doc/a.md, destroying both "
            "label and title; got {!r}".format(content)
        )
        assert count == 1

    def test_reference_definition_without_title_keeps_label(self, real_lookup, temp_dir):
        """The title is optional, and its absence does not narrow the span."""
        count, content = self._move_deeper(
            real_lookup,
            temp_dir,
            "note.md",
            "[lbl]: ../doc/a.md\n",
        )

        assert content == "[lbl]: ../../doc/a.md\n", (
            "the label must survive: the splice left the bare target, orphaning "
            "every [text][lbl] usage in the file; got {!r}".format(content)
        )
        assert count == 1

    def test_reference_definition_with_directory_target_keeps_label(self, real_lookup, temp_dir):
        """A directory target is the third damaged shape, not a separate type."""
        count, content = self._move_deeper(
            real_lookup,
            temp_dir,
            "note.md",
            "[d]: ../doc/\n",
        )

        assert (
            content == "[d]: ../../doc/\n"
        ), "a directory reference definition must keep its label too: " "got {!r}".format(content)
        assert count == 1

    def test_reference_definition_alongside_positional_refs(self, real_lookup, temp_dir):
        """The two phases must coexist: a definition plus duplicate spans.

        This is the shape the E2E fixtures carry -- a reference-definition
        block at the foot of a file whose body also holds ordinary links --
        so it exercises the interaction rather than the definition alone.
        """
        count, content = self._move_deeper(
            real_lookup,
            temp_dir,
            "note.md",
            "Both `../doc/a.md` and `../doc/a.md` are the same file.\n"
            "\n"
            '[lbl]: ../doc/a.md "Title"\n',
        )

        assert content == (
            "Both `../../doc/a.md` and `../../doc/a.md` are the same file.\n"
            "\n"
            '[lbl]: ../../doc/a.md "Title"\n'
        ), "definition and duplicate spans must both come out right: {!r}".format(content)
        assert count == 3

    @pytest.mark.parametrize(
        "written,expected",
        [
            ('$dir = "  doc/target  "\n', '$dir = "  ../doc/target  "\n'),
            ('$dir = "  doc/target"\n', '$dir = "  ../doc/target"\n'),
            ('$dir = "doc/target  "\n', '$dir = "../doc/target  "\n'),
            ('$dir = "doc/target"\n', '$dir = "../doc/target"\n'),  # tight control
        ],
    )
    def test_padded_quoted_directory_keeps_its_whitespace(
        self, real_lookup, temp_dir, written, expected
    ):
        """A span wider than its target destroys the padding it covers.

        ``powershell.py``'s quoted-DIRECTORY scan strips the captured text into
        ``link_target`` while the columns keep the raw match extent, so the span
        still covers the surrounding whitespace.  Phase 1 then splices the bare
        target across the whole span.

        A REGRESSION on this path specifically: the ``line.replace(target, new,
        1)`` this fix replaced matched the tight target and left the padding
        alone.  The sibling defect in the updater path is older -- pinned in
        ``test_updater.TestBug150PaddedQuotedDirectorySpan``.

        Extensionless on purpose: an extension-bearing target is captured tight
        by a character class that cannot match a space, so the same assertion on
        a file target would pass before the fix.
        """
        count, content = self._move_deeper(
            real_lookup,
            temp_dir,
            "note.ps1",
            written,
            extra_dirs=("sub/doc/target",),
        )

        assert content == expected, (
            "PD-BUG-150: the target must be re-depthed and the authored padding "
            "preserved -- a rewrite changes WHERE a link points, never HOW it was "
            "written; got {!r}".format(content)
        )
        assert count == 1

    def test_ambiguous_skip_reported_once_and_counted(self, lookup, mock_parser, temp_dir):
        """An ambiguous refusal is reported once, by its real cause, and counted.

        When ``replace_at_position`` meets invalid columns AND the target occurs
        more than once on the line, it refuses the unbounded replace rather than
        corrupting the line (PD-BUG-098) and says so with
        ``ambiguous_fallback_replacement_skipped``.

        The moved-file caller then saw an unchanged line and logged
        ``link_target_not_found_on_line`` on top of it -- a second warning
        naming a different, wrong cause (the target IS on the line; it was
        refused, not missing).  Nothing counted the refusal either, so a
        reference silently left unrewritten inside a moved file had no number
        anywhere.  Raised as a Code Review suggestion at the rework.
        """
        (temp_dir / "doc").mkdir(parents=True, exist_ok=True)
        (temp_dir / "doc" / "a.md").write_text("# a", encoding="utf-8")

        moved = temp_dir / "note.md"
        moved.write_text("See ../doc/a.md twice: ../doc/a.md\n", encoding="utf-8")

        # Columns deliberately invalid (end beyond the line) so the refusal
        # branch is the one exercised, with the target present twice.
        ref = LinkReference(
            file_path="sub/note.md",
            line_number=1,
            column_start=0,
            column_end=9999,
            link_text="",
            link_target="../doc/a.md",
            link_type="markdown-standalone",
        )
        mock_parser.parse_content.return_value = [ref]

        spy = MagicMock()
        with patch.object(lookup, "logger", spy):
            lookup.update_links_within_moved_file("sub/note.md", "sub/deeper/note.md", str(moved))

        warned = [c.args[0] for c in spy.warning.call_args_list if c.args]

        assert (
            "ambiguous_fallback_replacement_skipped" in warned
        ), "the refusal itself must still be reported: {!r}".format(warned)
        assert "link_target_not_found_on_line" not in warned, (
            "a refused replacement must not ALSO be reported as a missing target -- "
            "two warnings, the second naming the wrong cause: {!r}".format(warned)
        )
        assert (
            "moved_file_ambiguous_skips" in warned
        ), "the refusal must be counted where a reader can see it: {!r}".format(warned)

        counted = [
            c.kwargs.get("skipped")
            for c in spy.warning.call_args_list
            if c.args and c.args[0] == "moved_file_ambiguous_skips"
        ]
        assert counted == [1], "exactly one skip should be counted: {!r}".format(counted)

        assert (
            moved.read_text(encoding="utf-8") == "See ../doc/a.md twice: ../doc/a.md\n"
        ), "the refusal must leave the line untouched, not partially rewritten"
