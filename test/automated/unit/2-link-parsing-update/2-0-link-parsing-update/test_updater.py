"""
Tests for the LinkUpdater class.

This module tests the file updating functionality when links need
to be changed due to file moves or renames.
"""

import pytest

from linkwatcher.link_types import LinkType
from linkwatcher.models import LinkReference
from linkwatcher.updater import LinkUpdater, UpdateResult

pytestmark = [
    pytest.mark.feature("2.2.1"),
    pytest.mark.priority("Critical"),
    pytest.mark.cross_cutting(["0.1.1"]),
    pytest.mark.test_type("unit"),
    pytest.mark.specification("test/specifications/feature-specs/test-spec-2-2-1-link-updating.md"),
]


class TestLinkUpdater:
    """Test cases for LinkUpdater."""

    def test_updater_initialization(self):
        """Test updater initialization."""
        updater = LinkUpdater()

        assert updater.backup_enabled is True
        assert updater.dry_run is False

    def test_set_dry_run_mode(self):
        """Test enabling/disabling dry run mode."""
        updater = LinkUpdater()

        # Enable dry run
        updater.set_dry_run(True)
        assert updater.dry_run is True

        # Disable dry run
        updater.set_dry_run(False)
        assert updater.dry_run is False

    def test_set_backup_enabled(self):
        """Test enabling/disabling backup creation."""
        updater = LinkUpdater()

        # Disable backups
        updater.set_backup_enabled(False)
        assert updater.backup_enabled is False

        # Enable backups
        updater.set_backup_enabled(True)
        assert updater.backup_enabled is True

    def test_group_references_by_file(self):
        """Test grouping references by their containing file."""
        updater = LinkUpdater()

        references = [
            LinkReference("doc1.md", 1, 0, 10, "file.txt", "file.txt", "markdown"),
            LinkReference("doc1.md", 2, 0, 10, "other.txt", "other.txt", "markdown"),
            LinkReference("doc2.md", 1, 0, 10, "file.txt", "file.txt", "markdown"),
        ]

        grouped = updater._group_references_by_file(references)

        assert len(grouped) == 2
        assert "doc1.md" in grouped
        assert "doc2.md" in grouped
        assert len(grouped["doc1.md"]) == 2
        assert len(grouped["doc2.md"]) == 1

    def test_calculate_new_target_simple(self):
        """Test calculating new target for simple path replacement."""
        updater = LinkUpdater()

        ref = LinkReference("doc.md", 1, 0, 10, "old.txt", "old.txt", "markdown")
        new_target = updater._calculate_new_target(ref, "old.txt", "new.txt")

        assert new_target == "new.txt"

    def test_calculate_new_target_with_anchor(self):
        """Test calculating new target preserving anchors."""
        updater = LinkUpdater()

        ref = LinkReference("doc.md", 1, 0, 20, "old.txt#section", "old.txt#section", "markdown")
        new_target = updater._calculate_new_target(ref, "old.txt", "new.txt")

        assert new_target == "new.txt#section"

    def test_calculate_new_target_relative_path(self):
        """Test calculating new target for relative paths."""
        updater = LinkUpdater()

        ref = LinkReference("doc.md", 1, 0, 15, "../old.txt", "../old.txt", "markdown")
        new_target = updater._calculate_new_target(ref, "../old.txt", "../new.txt")

        assert new_target == "../new.txt"

    def test_replace_markdown_target(self):
        """Test replacing target in markdown link format."""
        updater = LinkUpdater()

        ref = LinkReference("doc.md", 1, 10, 25, "Link Text", "old.txt", "markdown")
        line = "This is a [Link Text](old.txt) in markdown."

        updated_line = updater._replace_markdown_target(line, ref, "new.txt")

        assert updated_line == "This is a [Link Text](new.txt) in markdown."

    def test_replace_markdown_target_with_anchor(self):
        """Test replacing markdown target that includes an anchor."""
        updater = LinkUpdater()

        ref = LinkReference("doc.md", 1, 10, 30, "Link Text", "old.txt#section", "markdown")
        line = "This is a [Link Text](old.txt#section) in markdown."

        updated_line = updater._replace_markdown_target(line, ref, "new.txt#section")

        assert updated_line == "This is a [Link Text](new.txt#section) in markdown."

    def test_replace_in_line_non_markdown(self):
        """Test replacing target in non-markdown content."""
        updater = LinkUpdater()

        ref = LinkReference("config.yaml", 1, 6, 13, "old.txt", "old.txt", "yaml")
        line = "file: old.txt"

        updated_line = updater._replace_in_line(line, ref, "new.txt")

        assert updated_line == "file: new.txt"

    def test_normalize_path(self):
        """Test path normalization."""
        from linkwatcher.utils import normalize_path

        assert normalize_path("/test/file.txt") == "test/file.txt"
        assert normalize_path("test\\file.txt") == "test/file.txt"
        assert normalize_path("./test/file.txt") == "test/file.txt"

    def test_update_references_dry_run(self, temp_project_dir):
        """Test updating references in dry run mode."""
        updater = LinkUpdater()
        updater.set_dry_run(True)

        # Create a test file
        test_file = temp_project_dir / "test.md"
        content = "This is a [link](old.txt) to update."
        test_file.write_text(content)

        # Create reference
        ref = LinkReference(str(test_file), 1, 11, 25, "link", "old.txt", "markdown")

        # Update references
        stats = updater.update_references([ref], "old.txt", "new.txt")

        # Should report success but not actually modify file
        assert stats["files_updated"] == 1
        assert stats["references_updated"] == 1
        assert stats["errors"] == 0

        # File should be unchanged
        assert test_file.read_text() == content

    def test_update_references_real_mode(self, temp_project_dir):
        """Test updating references in real mode."""
        updater = LinkUpdater()
        updater.set_dry_run(False)
        updater.set_backup_enabled(False)  # Disable backups for test

        # Create a test file
        test_file = temp_project_dir / "test.md"
        original_content = "This is a [link](old.txt) to update."
        test_file.write_text(original_content)

        # Create reference
        ref = LinkReference(str(test_file), 1, 11, 25, "link", "old.txt", "markdown")

        # Update references
        stats = updater.update_references([ref], "old.txt", "new.txt")

        # Should report success
        assert stats["files_updated"] == 1
        assert stats["references_updated"] == 1
        assert stats["errors"] == 0

        # File should be updated
        updated_content = test_file.read_text()
        assert updated_content == "This is a [link](new.txt) to update."
        assert updated_content != original_content

    def test_update_multiple_references_same_file(self, temp_project_dir):
        """Test updating multiple references in the same file."""
        updater = LinkUpdater()
        updater.set_dry_run(False)
        updater.set_backup_enabled(False)

        # Create a test file with multiple references
        test_file = temp_project_dir / "test.md"
        original_content = """# Test Document

First [link](old.txt) and second [link](old.txt).
Also a reference to "old.txt" in quotes.
"""
        test_file.write_text(original_content)

        # Create references with correct positions
        references = [
            LinkReference(
                str(test_file), 3, 13, 20, "link", "old.txt", "markdown"
            ),  # First [link](old.txt)
            LinkReference(
                str(test_file), 3, 40, 47, "link", "old.txt", "markdown"
            ),  # second [link](old.txt)
            LinkReference(str(test_file), 4, 20, 29, "old.txt", "old.txt", "quoted"),  # "old.txt"
        ]

        # Update references
        stats = updater.update_references(references, "old.txt", "new.txt")

        # Should update all references
        assert stats["files_updated"] == 1
        assert stats["references_updated"] == 3
        assert stats["errors"] == 0

        # Check file content
        updated_content = test_file.read_text()
        assert "new.txt" in updated_content
        assert "old.txt" not in updated_content

    def test_update_references_with_backup(self, temp_project_dir):
        """Test that backup files are created when enabled."""
        updater = LinkUpdater()
        updater.set_dry_run(False)
        updater.set_backup_enabled(True)

        # Create a test file
        test_file = temp_project_dir / "test.md"
        original_content = "This is a [link](old.txt) to update."
        test_file.write_text(original_content)

        # Create reference
        ref = LinkReference(str(test_file), 1, 11, 25, "link", "old.txt", "markdown")

        # Update references
        updater.update_references([ref], "old.txt", "new.txt")

        # Should create backup file
        backup_file = temp_project_dir / "test.md.bak"
        assert backup_file.exists()
        assert backup_file.read_text() == original_content

        # Original file should be updated
        assert test_file.read_text() != original_content

    def test_update_references_error_handling(self, temp_project_dir):
        """Test error handling when file operations fail."""
        updater = LinkUpdater()
        updater.set_dry_run(False)

        # Create reference to non-existent file
        ref = LinkReference("nonexistent.md", 1, 0, 10, "link", "old.txt", "markdown")

        # Try to update references
        stats = updater.update_references([ref], "old.txt", "new.txt")

        # Should report error
        assert stats["files_updated"] == 0
        assert stats["references_updated"] == 0
        assert stats["errors"] == 1

    def test_atomic_file_operations(self, temp_project_dir):
        """Test that file updates are atomic (use temporary files)."""
        updater = LinkUpdater()
        updater.set_dry_run(False)
        updater.set_backup_enabled(False)

        # Create a test file
        test_file = temp_project_dir / "test.md"
        original_content = "This is a [link](old.txt) to update."
        test_file.write_text(original_content)

        # Mock the _write_file_safely method to verify it's called
        original_write = updater._write_file_safely
        write_called = False

        def mock_write(file_path, content):
            nonlocal write_called
            write_called = True
            return original_write(file_path, content)

        updater._write_file_safely = mock_write

        # Create reference and update
        ref = LinkReference(str(test_file), 1, 11, 25, "link", "old.txt", "markdown")

        updater.update_references([ref], "old.txt", "new.txt")

        # Verify atomic write was used
        assert write_called


class TestStaleLineNumberDetection:
    """Test cases for stale line number detection (PD-BUG-005)."""

    def test_stale_detection_line_out_of_bounds(self, temp_project_dir):
        """Test that out-of-bounds line numbers are detected as stale."""
        updater = LinkUpdater()
        updater.set_backup_enabled(False)

        # Create a short file (3 lines)
        test_file = temp_project_dir / "doc.md"
        content = "Line 1\nLine 2\nLine 3\n"
        test_file.write_text(content)

        # Reference pointing to line 10 (out of bounds)
        ref = LinkReference(str(test_file), 10, 0, 7, "link", "old.txt", "markdown")

        result = updater._update_file_references(str(test_file), [ref], "old.txt", "new.txt")

        assert result == UpdateResult.STALE
        # File must not be modified
        assert test_file.read_text() == content

    def test_stale_detection_target_not_on_expected_line(self, temp_project_dir):
        """Test that wrong line content is detected as stale."""
        updater = LinkUpdater()
        updater.set_backup_enabled(False)

        # Original file had link on line 2, but user inserted a line at top
        test_file = temp_project_dir / "doc.md"
        content = "Newly inserted line\nOriginal line 1\nSee [link](old.txt) for info.\n"
        test_file.write_text(content)

        # Stale reference: still points to line 2, but link is now on line 3
        ref = LinkReference(str(test_file), 2, 4, 18, "link", "old.txt", "markdown")

        result = updater._update_file_references(str(test_file), [ref], "old.txt", "new.txt")

        assert result == UpdateResult.STALE
        # File must not be modified
        assert test_file.read_text() == content

    def test_no_stale_when_line_content_matches(self, temp_project_dir):
        """Test that correct line numbers result in successful update."""
        updater = LinkUpdater()
        updater.set_backup_enabled(False)

        test_file = temp_project_dir / "doc.md"
        content = "Some text [link](old.txt) more text\n"
        test_file.write_text(content)

        ref = LinkReference(str(test_file), 1, 11, 25, "link", "old.txt", "markdown")

        result = updater._update_file_references(str(test_file), [ref], "old.txt", "new.txt")

        assert result == UpdateResult.UPDATED
        assert "new.txt" in test_file.read_text()
        assert "old.txt" not in test_file.read_text()

    def test_stale_detection_prevents_partial_writes(self, temp_project_dir):
        """Test that stale detection prevents partial file modifications."""
        updater = LinkUpdater()
        updater.set_backup_enabled(False)

        # File with links on lines 2 and 4
        test_file = temp_project_dir / "doc.md"
        content = (
            "# Title\n"
            "First [link](old.txt) here.\n"
            "Some other text.\n"
            "This line has NO link (was shifted).\n"
        )
        test_file.write_text(content)

        # Line 2 has the correct link, line 4 is stale (link was shifted away)
        references = [
            LinkReference(str(test_file), 2, 6, 20, "link", "old.txt", "markdown"),
            LinkReference(str(test_file), 4, 6, 20, "link", "old.txt", "markdown"),
        ]

        result = updater._update_file_references(str(test_file), references, "old.txt", "new.txt")

        # Bottom-to-top processing: line 4 checked first, detected stale
        assert result == UpdateResult.STALE
        # File must be completely unchanged - no partial writes
        assert test_file.read_text() == content

    def test_update_references_reports_stale_files(self, temp_project_dir):
        """Test that update_references tracks stale files in stats."""
        updater = LinkUpdater()
        updater.set_backup_enabled(False)

        # File 1: correct line numbers
        file1 = temp_project_dir / "correct.md"
        file1.write_text("See [link](old.txt) here.\n")

        # File 2: stale line numbers (3 lines, ref points to line 10)
        file2 = temp_project_dir / "stale.md"
        file2.write_text("Line 1\nLine 2\nLine 3\n")

        references = [
            LinkReference(str(file1), 1, 4, 18, "link", "old.txt", "markdown"),
            LinkReference(str(file2), 10, 0, 7, "link", "old.txt", "markdown"),
        ]

        stats = updater.update_references(references, "old.txt", "new.txt")

        assert stats["files_updated"] == 1
        assert len(stats["stale_files"]) == 1
        assert str(file2) in stats["stale_files"]
        # Correct file should be updated
        assert "new.txt" in file1.read_text()
        # Stale file should be unchanged
        assert file2.read_text() == "Line 1\nLine 2\nLine 3\n"

    def test_no_changes_return_value(self, temp_project_dir):
        """Test that unchanged target returns 'no_changes'."""
        updater = LinkUpdater()
        updater.set_backup_enabled(False)

        test_file = temp_project_dir / "doc.md"
        content = "See [link](other.txt) here.\n"
        test_file.write_text(content)

        # Reference target doesn't match old_path, so no change needed
        ref = LinkReference(str(test_file), 1, 4, 19, "link", "other.txt", "markdown")

        result = updater._update_file_references(str(test_file), [ref], "old.txt", "new.txt")

        assert result == UpdateResult.NO_CHANGES


class TestRootRelativePathHandling:
    """Regression tests for PD-BUG-017: root-relative paths in scripts.

    The updater previously assumed all non-absolute paths were relative to the
    source file.  Paths that match the moved file's old_path directly are
    project-root-relative and must be updated to new_path as-is, not converted
    to a source-relative path.
    """

    def test_root_relative_path_preserved_in_script(self, temp_project_dir):
        """Core regression: root-relative path must NOT be converted to source-relative.

        Simulates a PowerShell script at scripts/file-creation/New-BugReport.ps1
        containing a Join-Path -ChildPath with a root-relative path to
        doc/state-tracking/bug-tracking.md.  When bug-tracking.md moves, the path
        in the script must remain root-relative (not ../../...).
        """
        updater = LinkUpdater(str(temp_project_dir))
        updater.set_backup_enabled(False)

        # Create directory structure
        script_dir = temp_project_dir / "scripts" / "file-creation"
        script_dir.mkdir(parents=True)
        target_dir = temp_project_dir / "alpha-project" / "state-tracking"
        target_dir.mkdir(parents=True)
        new_target_dir = temp_project_dir / "alpha-project" / "tracking"
        new_target_dir.mkdir(parents=True)

        # Script with a root-relative path argument
        script_file = script_dir / "New-BugReport.ps1"
        content = (
            "$BugTrackingFile = Join-Path -Path $ProjectRoot "
            '-ChildPath "alpha-project/state-tracking/bug-tracking.md"\n'
        )
        script_file.write_text(content)

        # Reference as GenericParser would create it
        ref = LinkReference(
            file_path="scripts/file-creation/New-BugReport.ps1",
            line_number=1,
            column_start=content.index("alpha-project/state-tracking"),
            column_end=content.index("alpha-project/state-tracking")
            + len("alpha-project/state-tracking/bug-tracking.md"),
            link_text="alpha-project/state-tracking/bug-tracking.md",
            link_target="alpha-project/state-tracking/bug-tracking.md",
            link_type="generic-quoted",
        )

        old_path = "alpha-project/state-tracking/bug-tracking.md"
        new_path = "alpha-project/tracking/bug-tracking.md"

        new_target = updater._calculate_new_target(ref, old_path, new_path)

        # Must be the new root-relative path, NOT "../../tracking/bug-tracking.md"
        assert new_target == "alpha-project/tracking/bug-tracking.md"
        assert not new_target.startswith(
            "../"
        ), f"Root-relative path was wrongly converted to source-relative: {new_target}"

    def test_root_relative_path_end_to_end(self, temp_project_dir):
        """End-to-end test: file on disk is updated with correct root-relative path."""
        updater = LinkUpdater(str(temp_project_dir))
        updater.set_backup_enabled(False)

        script_dir = temp_project_dir / "scripts" / "deep"
        script_dir.mkdir(parents=True)

        script_file = script_dir / "tool.ps1"
        content = '$path = "alpha-project/config/settings.yaml"\n'
        script_file.write_text(content)

        ref = LinkReference(
            file_path="scripts/deep/tool.ps1",
            line_number=1,
            column_start=content.index("alpha-project/config"),
            column_end=content.index("alpha-project/config")
            + len("alpha-project/config/settings.yaml"),
            link_text="alpha-project/config/settings.yaml",
            link_target="alpha-project/config/settings.yaml",
            link_type="generic-quoted",
        )

        stats = updater.update_references(
            [ref], "alpha-project/config/settings.yaml", "alpha-project/configuration/settings.yaml"
        )

        assert stats["files_updated"] == 1
        updated = script_file.read_text()
        assert "alpha-project/configuration/settings.yaml" in updated
        assert "alpha-project/config/settings.yaml" not in updated
        # Must NOT contain source-relative path
        assert "../" not in updated

    def test_explicit_relative_path_still_works(self, temp_project_dir):
        """Ensure explicit relative paths (../) are NOT affected by the fix."""
        updater = LinkUpdater(str(temp_project_dir))
        updater.set_backup_enabled(False)

        doc_dir = temp_project_dir / "alpha-project" / "guides"
        doc_dir.mkdir(parents=True)

        md_file = doc_dir / "guide.md"
        content = "See [tracking](../state-tracking/bug-tracking.md) for details.\n"
        md_file.write_text(content)

        ref = LinkReference(
            file_path="alpha-project/guides/guide.md",
            line_number=1,
            column_start=14,
            column_end=14 + len("../state-tracking/bug-tracking.md"),
            link_text="tracking",
            link_target="../state-tracking/bug-tracking.md",
            link_type="markdown",
        )

        old_path = "alpha-project/state-tracking/bug-tracking.md"
        new_path = "alpha-project/tracking/bug-tracking.md"

        new_target = updater._calculate_new_target(ref, old_path, new_path)

        # "../state-tracking/bug-tracking.md" != "alpha-project/state-tracking/bug-tracking.md"
        # so the early check should NOT trigger; existing resolution logic handles it
        assert new_target != old_path  # should be recalculated, not returned as-is

    def test_root_relative_with_leading_slash_preserved(self):
        """Test that /doc/... style absolute-root paths preserve the leading slash."""
        updater = LinkUpdater()

        ref = LinkReference(
            file_path="scripts/tool.ps1",
            line_number=1,
            column_start=0,
            column_end=30,
            link_text="/alpha-project/state/file.md",
            link_target="/alpha-project/state/file.md",
            link_type="generic-quoted",
        )

        new_target = updater._calculate_new_target(
            ref, "alpha-project/state/file.md", "alpha-project/new-state/file.md"
        )

        # Leading slash should be preserved
        assert new_target == "/alpha-project/new-state/file.md"

    def test_unrelated_root_relative_path_not_modified(self):
        """Test that a root-relative path NOT matching old_path is left alone."""
        updater = LinkUpdater()

        ref = LinkReference(
            file_path="scripts/tool.ps1",
            line_number=1,
            column_start=0,
            column_end=20,
            link_text="alpha-project/other/file.md",
            link_target="alpha-project/other/file.md",
            link_type="generic-quoted",
        )

        new_target = updater._calculate_new_target(
            ref, "alpha-project/state/bug-tracking.md", "alpha-project/new-state/bug-tracking.md"
        )

        # Different path — should not be modified
        assert new_target == "alpha-project/other/file.md"


class TestReplaceReferenceTarget:
    """Tests for _replace_reference_target() — markdown reference link format."""

    def test_basic_reference_link(self):
        """Test replacing target in basic reference link [label]: target."""
        updater = LinkUpdater()
        ref = LinkReference("doc.md", 1, 0, 20, "label", "old/path.md", "markdown-reference")
        line = "[label]: old/path.md"

        result = updater._replace_reference_target(line, ref, "new/path.md")

        assert result == "[label]: new/path.md"

    def test_reference_link_with_double_quoted_title(self):
        """Test replacing target in reference link with double-quoted title."""
        updater = LinkUpdater()
        ref = LinkReference("doc.md", 1, 0, 30, "docs", "old/file.md", "markdown-reference")
        line = '[docs]: old/file.md "Documentation"'

        result = updater._replace_reference_target(line, ref, "new/file.md")

        assert result == '[docs]: new/file.md "Documentation"'

    def test_reference_link_with_paren_title(self):
        """Test replacing target in reference link with parenthesized title."""
        updater = LinkUpdater()
        ref = LinkReference("doc.md", 1, 0, 30, "link", "old/file.md", "markdown-reference")
        line = "[link]: old/file.md (My Title)"

        result = updater._replace_reference_target(line, ref, "new/file.md")

        assert result == "[link]: new/file.md (My Title)"

    def test_reference_link_target_not_found(self):
        """Test that line is unchanged when target doesn't match."""
        updater = LinkUpdater()
        ref = LinkReference("doc.md", 1, 0, 20, "label", "missing.md", "markdown-reference")
        line = "[label]: other.md"

        result = updater._replace_reference_target(line, ref, "new.md")

        assert result == "[label]: other.md"


class TestUpdateFileReferencesMulti:
    """Tests for _update_file_references_multi() — multi old→new in one file."""

    def test_single_ref_tuple(self, temp_project_dir):
        """Test updating a single (ref, old, new) tuple in a file."""
        updater = LinkUpdater(str(temp_project_dir))
        updater.set_backup_enabled(False)

        test_file = temp_project_dir / "test.md"
        test_file.write_text("See [link](old.txt) for details.\n")

        ref = LinkReference(str(test_file), 1, 5, 18, "link", "old.txt", "markdown")
        ref_tuples = [(ref, "old.txt", "new.txt")]

        result = updater._update_file_references_multi(str(test_file), ref_tuples)

        assert result == UpdateResult.UPDATED
        assert test_file.read_text() == "See [link](new.txt) for details.\n"

    def test_multiple_ref_tuples_different_moves(self, temp_project_dir):
        """Test updating multiple refs from different moves in one file."""
        updater = LinkUpdater(str(temp_project_dir))
        updater.set_backup_enabled(False)

        test_file = temp_project_dir / "index.md"
        test_file.write_text("- [A](alpha.md)\n- [B](beta.md)\n")

        ref_a = LinkReference(str(test_file), 1, 3, 14, "A", "alpha.md", "markdown")
        ref_b = LinkReference(str(test_file), 2, 3, 13, "B", "beta.md", "markdown")
        ref_tuples = [
            (ref_a, "alpha.md", "new/alpha.md"),
            (ref_b, "beta.md", "new/beta.md"),
        ]

        result = updater._update_file_references_multi(str(test_file), ref_tuples)

        assert result == UpdateResult.UPDATED
        content = test_file.read_text()
        assert "new/alpha.md" in content
        assert "new/beta.md" in content

    def test_no_change_when_targets_match(self, temp_project_dir):
        """Test NO_CHANGES returned when new target equals old target."""
        updater = LinkUpdater(str(temp_project_dir))
        updater.set_backup_enabled(False)

        test_file = temp_project_dir / "test.md"
        test_file.write_text("See [link](same.txt) here.\n")

        ref = LinkReference(str(test_file), 1, 5, 18, "link", "same.txt", "markdown")
        # old_path == new_path → calculate_new_target returns same target
        ref_tuples = [(ref, "same.txt", "same.txt")]

        result = updater._update_file_references_multi(str(test_file), ref_tuples)

        assert result == UpdateResult.NO_CHANGES

    def test_dry_run_returns_updated_without_modifying(self, temp_project_dir):
        """Test dry run reports UPDATED but doesn't modify file."""
        updater = LinkUpdater(str(temp_project_dir))
        updater.set_dry_run(True)

        test_file = temp_project_dir / "test.md"
        original = "See [link](old.txt) here.\n"
        test_file.write_text(original)

        ref = LinkReference(str(test_file), 1, 5, 18, "link", "old.txt", "markdown")
        ref_tuples = [(ref, "old.txt", "new.txt")]

        result = updater._update_file_references_multi(str(test_file), ref_tuples)

        assert result == UpdateResult.UPDATED
        assert test_file.read_text() == original


class TestUpdateReferencesBatch:
    """Tests for update_references_batch() — batch directory move API."""

    def test_single_move_group(self, temp_project_dir):
        """Test batch with a single move group."""
        updater = LinkUpdater(str(temp_project_dir))
        updater.set_backup_enabled(False)

        test_file = temp_project_dir / "readme.md"
        test_file.write_text("Link to [doc](old/file.md).\n")

        ref = LinkReference(str(test_file), 1, 9, 22, "doc", "old/file.md", "markdown")
        move_groups = [([ref], "old/file.md", "new/file.md")]

        stats = updater.update_references_batch(move_groups)

        assert stats["files_updated"] == 1
        assert stats["references_updated"] == 1
        assert stats["errors"] == 0
        assert "new/file.md" in test_file.read_text()

    def test_multiple_move_groups_same_file(self, temp_project_dir):
        """Test that multiple move groups referencing the same file consolidate."""
        updater = LinkUpdater(str(temp_project_dir))
        updater.set_backup_enabled(False)

        test_file = temp_project_dir / "index.md"
        test_file.write_text("- [A](dir/a.md)\n- [B](dir/b.md)\n")

        ref_a = LinkReference(str(test_file), 1, 3, 14, "A", "dir/a.md", "markdown")
        ref_b = LinkReference(str(test_file), 2, 3, 14, "B", "dir/b.md", "markdown")

        # Two separate move groups (as from a directory move) both touching same file
        move_groups = [
            ([ref_a], "dir/a.md", "new-dir/a.md"),
            ([ref_b], "dir/b.md", "new-dir/b.md"),
        ]

        stats = updater.update_references_batch(move_groups)

        assert stats["files_updated"] == 1  # consolidated into single file write
        assert stats["references_updated"] == 2
        assert stats["errors"] == 0
        content = test_file.read_text()
        assert "new-dir/a.md" in content
        assert "new-dir/b.md" in content

    def test_multiple_move_groups_different_files(self, temp_project_dir):
        """Test batch with move groups referencing different files."""
        updater = LinkUpdater(str(temp_project_dir))
        updater.set_backup_enabled(False)

        file_a = temp_project_dir / "a.md"
        file_a.write_text("See [x](old/x.md).\n")
        file_b = temp_project_dir / "b.md"
        file_b.write_text("See [y](old/y.md).\n")

        ref_a = LinkReference(str(file_a), 1, 5, 16, "x", "old/x.md", "markdown")
        ref_b = LinkReference(str(file_b), 1, 5, 16, "y", "old/y.md", "markdown")

        move_groups = [
            ([ref_a], "old/x.md", "new/x.md"),
            ([ref_b], "old/y.md", "new/y.md"),
        ]

        stats = updater.update_references_batch(move_groups)

        assert stats["files_updated"] == 2
        assert stats["references_updated"] == 2
        assert stats["errors"] == 0

    def test_batch_dry_run(self, temp_project_dir):
        """Test batch in dry run mode reports success without modifying."""
        updater = LinkUpdater(str(temp_project_dir))
        updater.set_dry_run(True)

        test_file = temp_project_dir / "test.md"
        original = "Link [a](old.md).\n"
        test_file.write_text(original)

        ref = LinkReference(str(test_file), 1, 6, 14, "a", "old.md", "markdown")
        move_groups = [([ref], "old.md", "new.md")]

        stats = updater.update_references_batch(move_groups)

        assert stats["files_updated"] == 1
        assert stats["references_updated"] == 1
        assert test_file.read_text() == original

    def test_batch_error_handling(self, temp_project_dir):
        """Test batch handles file errors gracefully and continues."""
        updater = LinkUpdater(str(temp_project_dir))
        updater.set_backup_enabled(False)

        # Good file
        good_file = temp_project_dir / "good.md"
        good_file.write_text("See [a](old.md).\n")

        ref_bad = LinkReference("nonexistent.md", 1, 0, 10, "x", "old.md", "markdown")
        ref_good = LinkReference(str(good_file), 1, 5, 13, "a", "old.md", "markdown")

        move_groups = [
            ([ref_bad], "old.md", "new.md"),
            ([ref_good], "old.md", "new.md"),
        ]

        stats = updater.update_references_batch(move_groups)

        assert stats["errors"] == 1
        assert stats["files_updated"] == 1
        assert "new.md" in good_file.read_text()


class TestPythonImportIdempotency:
    """TD251: _replace_at_position must be idempotent for PYTHON_IMPORT refs.

    PD-BUG-096 was fixed at the collection layer (reference_lookup.py).
    This test guards the underlying replacement layer: even if a duplicate
    PYTHON_IMPORT ref reached Phase 1 by some future code path, applying
    the same replacement twice must not double-prefix the import.
    """

    def test_first_application_updates_import(self):
        """Sanity: a single application of the replacement updates the import."""
        updater = LinkUpdater()
        ref = LinkReference(
            file_path="main.py",
            line_number=1,
            column_start=7,
            column_end=14,
            link_text="utils.a",
            link_target="utils/a",
            link_type=LinkType.PYTHON_IMPORT,
        )

        result = updater._replace_at_position("import utils.a\n", ref, "src/utils/a")

        assert result == "import src.utils.a\n"

    def test_second_application_is_no_op(self):
        """The hazard: applying the same PYTHON_IMPORT replacement twice must
        not produce double-prefix corruption (e.g., 'src.src.utils.a').

        Without the negative-lookbehind guard, the second call's unbounded
        substring match would find 'utils.a' inside 'src.utils.a' and produce
        'src.src.utils.a'. With the guard, the second call is a no-op.
        """
        updater = LinkUpdater()
        ref = LinkReference(
            file_path="main.py",
            line_number=1,
            column_start=7,
            column_end=14,
            link_text="utils.a",
            link_target="utils/a",
            link_type=LinkType.PYTHON_IMPORT,
        )

        first = updater._replace_at_position("import utils.a\n", ref, "src/utils/a")
        second = updater._replace_at_position(first, ref, "src/utils/a")

        assert (
            second == first
        ), f"Re-applying replacement must be a no-op; got double-prefix: {second!r}"
        assert "src.src." not in second

    def test_dot_preceded_module_not_replaced(self):
        """Negative-lookbehind property: 'utils.a' inside 'pkg.utils.a' must not match."""
        updater = LinkUpdater()
        ref = LinkReference(
            file_path="main.py",
            line_number=1,
            column_start=0,
            column_end=20,
            link_text="utils.a",
            link_target="utils/a",
            link_type=LinkType.PYTHON_IMPORT,
        )

        # 'pkg.utils.a' must stay intact; only the standalone 'utils.a' is matched.
        result = updater._replace_at_position("x = pkg.utils.a; y = utils.a\n", ref, "src/utils/a")

        assert "pkg.utils.a" in result, "dot-preceded module name must not be replaced"
        assert "y = src.utils.a" in result, "standalone occurrence should be replaced"


class TestOverlappingReferenceCorruption:
    """PD-BUG-098 regression: when multiple LinkReferences on the same line have
    overlapping column ranges (one strictly contained in another), the descending-
    column processing in `_apply_replacements` produces corrupted output. The
    rightmost (inner) replacement extends the line, then the leftmost (outer)
    replacement uses stale column positions and slices into the freshly-inserted
    text — yielding `<new_path> + chopped_tail_of_<new_path>`.

    These tests construct the corruption-producing scenario with explicit
    LinkReference tuples and assert that `_apply_replacements` produces a clean
    result with no overlapping-substring corruption.
    """

    def _make_ref(
        self,
        file_path: str,
        line_number: int,
        column_start: int,
        column_end: int,
        link_target: str,
        link_type: str = LinkType.GENERIC_UNQUOTED,
    ) -> LinkReference:
        return LinkReference(
            file_path=file_path,
            line_number=line_number,
            column_start=column_start,
            column_end=column_end,
            link_text="",
            link_target=link_target,
            link_type=link_type,
        )

    def test_inner_contained_in_outer_no_corruption(self, temp_project_dir):
        """Two refs on same line where inner is strictly inside outer.

        Reproduces the exact corruption pattern from PD-BUG-098: outer ref for
        `tools/linkWatcher/LinkWatcherBrokenLinks.txt` contains inner ref for
        `LinkWatcherBrokenLinks.txt` (bare filename). Both rewrite to the same
        new path. Without the fix, the line ends with chopped-tail corruption
        like `...LinkWatcherBrokenLinks.txtols/linkWatcher/LinkWatcherBrokenLinks.txt`.
        """
        updater = LinkUpdater(project_root=str(temp_project_dir))
        updater.set_dry_run(False)
        updater.set_backup_enabled(False)

        outer_target = "tools/linkWatcher/LinkWatcherBrokenLinks.txt"
        inner_target = "LinkWatcherBrokenLinks.txt"
        new_path = "process-framework-local/tools/linkWatcher/LinkWatcherBrokenLinks.txt"

        line_text = f"See report {outer_target} for details.\n"
        test_file = temp_project_dir / "test.md"
        test_file.write_text(line_text)

        outer_start = line_text.index(outer_target)
        outer_end = outer_start + len(outer_target)
        inner_start = line_text.index(inner_target, outer_start)
        inner_end = inner_start + len(inner_target)

        # Sanity: confirm geometry is contained-in-outer
        assert outer_start < inner_start < inner_end == outer_end

        items = [
            (
                self._make_ref(str(test_file), 1, outer_start, outer_end, outer_target),
                new_path,
            ),
            (
                self._make_ref(str(test_file), 1, inner_start, inner_end, inner_target),
                new_path,
            ),
        ]

        result = updater._apply_replacements(str(test_file), str(test_file), items)
        updated = test_file.read_text()

        expected = f"See report {new_path} for details.\n"
        assert updated == expected, f"Overlap-corruption bug: expected {expected!r} got {updated!r}"
        # Negative assertion: the documented PD-BUG-098 corruption signature
        # must NOT be present.
        assert (
            "txtols/linkWatcher" not in updated
        ), f"PD-BUG-098 corruption pattern present in: {updated!r}"
        # New path must appear exactly once (not duplicated by stale-column slicing).
        assert updated.count(new_path) == 1, (
            f"new path duplicated by overlap corruption: count={updated.count(new_path)}, "
            f"line={updated!r}"
        )
        assert result == UpdateResult.UPDATED

    def test_triple_nested_overlap_no_corruption(self, temp_project_dir):
        """Three nested refs on same line — the validator.py:703 docstring variant.

        The bug-098 description shows that when three overlapping refs land on a
        line, the corruption compounds: `...txtols/linkWatcher/...txtenLinks.txt`.
        Three nested ranges all rewriting to the same target must produce a
        single clean replacement.
        """
        updater = LinkUpdater(project_root=str(temp_project_dir))
        updater.set_dry_run(False)
        updater.set_backup_enabled(False)

        outermost = "tools/linkWatcher/LinkWatcherBrokenLinks.txt"
        middle = "linkWatcher/LinkWatcherBrokenLinks.txt"
        innermost = "LinkWatcherBrokenLinks.txt"
        new_path = "process-framework-local/tools/linkWatcher/LinkWatcherBrokenLinks.txt"

        line_text = f"prefix {outermost} suffix\n"
        test_file = temp_project_dir / "test.md"
        test_file.write_text(line_text)

        out_start = line_text.index(outermost)
        out_end = out_start + len(outermost)
        mid_start = line_text.index(middle, out_start)
        mid_end = mid_start + len(middle)
        inn_start = line_text.index(innermost, mid_start)
        inn_end = inn_start + len(innermost)

        # Sanity: nested containment
        assert out_start < mid_start < inn_start < inn_end == mid_end == out_end

        items = [
            (self._make_ref(str(test_file), 1, out_start, out_end, outermost), new_path),
            (self._make_ref(str(test_file), 1, mid_start, mid_end, middle), new_path),
            (self._make_ref(str(test_file), 1, inn_start, inn_end, innermost), new_path),
        ]

        updater._apply_replacements(str(test_file), str(test_file), items)
        updated = test_file.read_text()

        expected = f"prefix {new_path} suffix\n"
        assert (
            updated == expected
        ), f"Triple-overlap corruption: expected {expected!r} got {updated!r}"
        assert (
            "txtols" not in updated and "txtenLinks" not in updated
        ), f"Triple-overlap corruption pattern present in: {updated!r}"

    def test_non_overlapping_refs_same_line_still_work(self, temp_project_dir):
        """Sanity check: two non-overlapping refs on the same line update both.

        Guards against over-eager filtering — only refs that are strictly
        contained in another ref should be dropped, not all same-line refs.
        """
        updater = LinkUpdater(project_root=str(temp_project_dir))
        updater.set_dry_run(False)
        updater.set_backup_enabled(False)

        line_text = 'See "old-a.txt" and also "old-b.txt" please.\n'
        test_file = temp_project_dir / "test.md"
        test_file.write_text(line_text)

        a_start = line_text.index("old-a.txt")
        a_end = a_start + len("old-a.txt")
        b_start = line_text.index("old-b.txt")
        b_end = b_start + len("old-b.txt")

        # Sanity: ranges do not overlap
        assert a_end < b_start

        items = [
            (
                self._make_ref(str(test_file), 1, a_start, a_end, "old-a.txt", LinkType.QUOTED),
                "new-a.txt",
            ),
            (
                self._make_ref(str(test_file), 1, b_start, b_end, "old-b.txt", LinkType.QUOTED),
                "new-b.txt",
            ),
        ]

        updater._apply_replacements(str(test_file), str(test_file), items)
        updated = test_file.read_text()

        assert (
            updated == 'See "new-a.txt" and also "new-b.txt" please.\n'
        ), f"Non-overlapping refs lost an update: {updated!r}"

    def test_invalid_columns_fallback_no_unbounded_replace(self, temp_project_dir):
        """Secondary risk: when column positions are invalid, the fallback at
        `_replace_at_position` previously called the unbounded `line.replace(old,
        new)`, which would replace ALL occurrences if `link_target` appeared
        more than once on the line. After the fix, this case must NOT do
        unbounded multi-replacement.
        """
        updater = LinkUpdater(project_root=str(temp_project_dir))

        # link_target appears twice on the line; columns are invalid (start>=end)
        # to force the fallback path.
        line = 'a = "config.json"; b = "config.json"\n'
        ref = LinkReference(
            file_path="dummy.py",
            line_number=1,
            column_start=0,
            column_end=0,  # Invalid: start_col >= end_col triggers fallback
            link_text="",
            link_target="config.json",
            link_type=LinkType.QUOTED,
        )

        result = updater._replace_at_position(line, ref, "new-config.json")

        # Must NOT replace both occurrences (which is what unbounded
        # `line.replace()` would do).
        assert (
            result.count("new-config.json") <= 1
        ), f"Unbounded fallback replaced multiple occurrences: {result!r}"

    def test_ambiguous_fallback_increments_errors_count(self, temp_project_dir):
        """TD252 / Option C: when _replace_at_position hits the invalid-column
        ambiguous-fallback path (occurrences>1), the silently-skipped ref must
        surface in UpdateStats["errors"] so callers see the failure.

        Without this propagation, a file move could leave references unupdated
        while update_references reports success — a data integrity hazard.
        STALE-escalation was rejected because it would block all other refs in
        the same file; per-skip counter preserves visibility without blast.
        """
        updater = LinkUpdater(project_root=str(temp_project_dir))
        updater.set_dry_run(False)
        updater.set_backup_enabled(False)

        # Two occurrences of "config.json" + invalid columns force the
        # ambiguous-fallback path inside _replace_at_position.
        test_file = temp_project_dir / "test.py"
        test_file.write_text('a = "config.json"; b = "config.json"\n')

        ref = LinkReference(
            file_path=str(test_file),
            line_number=1,
            column_start=0,
            column_end=0,  # Invalid: start_col >= end_col triggers fallback
            link_text="",
            link_target="config.json",
            link_type=LinkType.QUOTED,
        )

        stats = updater.update_references([ref], "config.json", "new-config.json")

        assert (
            stats["errors"] == 1
        ), f"TD252: ambiguous-fallback skip not surfaced in errors, got {stats!r}"
        # No unbounded replacement leaked through (regression guard).
        assert test_file.read_text().count("new-config.json") <= 1


class TestOverrideAwareResolution:
    """Unit tests for override-aware virtual-root resolution (v1.1).

    ``path_resolution_overrides`` maps a folder to a resolution base: files
    under that folder write host-absolute (``/...``) references against a
    *virtual* root (the blueprint-restructuring use case).  v1.1 extends the
    previously validate-only override into the live move/update path
    (PD-TDD-026 "Override-Aware Path Resolution").  Scenarios (a)-(d) from
    TE-TSP-040 "Override-Aware Resolution Tests"; scenario (e) is the
    directory-restructure integration test in test_link_updates.py.
    """

    OVERRIDES = {"appdev/blueprint": "appdev/blueprint"}

    @staticmethod
    def _resolver(temp_project_dir, overrides=None, logger=None):
        from linkwatcher.path_resolver import PathResolver

        return PathResolver(
            str(temp_project_dir), logger=logger, path_resolution_overrides=overrides
        )

    @staticmethod
    def _blueprint_ref(target="/process-framework/tasks/foo.md"):
        return LinkReference(
            file_path="appdev/blueprint/process-framework/ai-tasks.md",
            line_number=1,
            column_start=0,
            column_end=40,
            link_text="Foo",
            link_target=target,
            link_type="markdown",
        )

    @staticmethod
    def _make_moved_file(
        temp_project_dir, rel="appdev/blueprint/process-framework/tasks/foo-task.md"
    ):
        """Create the post-move target on disk (containment guard requires it)."""
        p = temp_project_dir / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text("content")
        return p

    OLD = "appdev/blueprint/process-framework/tasks/foo.md"
    NEW = "appdev/blueprint/process-framework/tasks/foo-task.md"

    def test_override_source_absolute_ref_rewritten(self, temp_project_dir):
        """(a) A /... reference from an override-folder source is matched and
        rewritten, preserving the leading-slash virtual-root style."""
        self._make_moved_file(temp_project_dir)
        resolver = self._resolver(temp_project_dir, self.OVERRIDES)

        result = resolver.calculate_new_target(self._blueprint_ref(), self.OLD, self.NEW)

        assert result == "/process-framework/tasks/foo-task.md"

    def test_override_rewrite_preserves_anchor(self, temp_project_dir):
        """(a) Anchor fragments survive an override-aware rewrite."""
        self._make_moved_file(temp_project_dir)
        resolver = self._resolver(temp_project_dir, self.OVERRIDES)

        ref = self._blueprint_ref("/process-framework/tasks/foo.md#section")
        result = resolver.calculate_new_target(ref, self.OLD, self.NEW)

        assert result == "/process-framework/tasks/foo-task.md#section"

    def test_non_override_source_unchanged(self, temp_project_dir):
        """(b) The same /... reference from a source OUTSIDE every override
        folder is left byte-for-byte unchanged."""
        self._make_moved_file(temp_project_dir)
        resolver = self._resolver(temp_project_dir, self.OVERRIDES)

        ref = LinkReference(
            file_path="doc/notes.md",
            line_number=1,
            column_start=0,
            column_end=40,
            link_text="Foo",
            link_target="/process-framework/tasks/foo.md",
            link_type="markdown",
        )
        result = resolver.calculate_new_target(ref, self.OLD, self.NEW)

        assert result == "/process-framework/tasks/foo.md"

    def test_no_override_config_keeps_v1_0_behavior(self, temp_project_dir):
        """(b) Without path_resolution_overrides configured, resolution is
        byte-for-byte the v1.0 behavior — including the lossy PD-BUG-045
        suffix-match fallback this enhancement supersedes when configured."""
        self._make_moved_file(temp_project_dir)
        resolver = self._resolver(temp_project_dir, overrides=None)

        result = resolver.calculate_new_target(self._blueprint_ref(), self.OLD, self.NEW)

        # v1.0: the PD-BUG-045 suffix match fires (source under the subtree)
        # and returns a slash-stripped, non-virtual-root form.  Locked in as a
        # regression anchor: no-config behavior must not change.
        assert result == "process-framework/tasks/foo-task.md"

    def test_override_relative_links_unaffected(self, temp_project_dir):
        """(b) Relative references from an override-folder source are not
        touched by override resolution — they resolve against the source
        file's own directory exactly as before."""
        self._make_moved_file(temp_project_dir)
        resolver = self._resolver(temp_project_dir, self.OVERRIDES)

        ref = LinkReference(
            file_path="appdev/blueprint/process-framework/tasks/index.md",
            line_number=1,
            column_start=0,
            column_end=20,
            link_text="Foo",
            link_target="foo.md",
            link_type="markdown",
        )
        result = resolver.calculate_new_target(ref, self.OLD, self.NEW)

        assert result == "foo-task.md"

    def test_override_guard_nonexistent_target_unchanged(self, temp_project_dir):
        """(c) An override match whose proposed new target does not exist on
        disk is left unchanged (containment guard, mirrors PD-BUG-095)."""
        # NOTE: deliberately no file created on disk.
        resolver = self._resolver(temp_project_dir, self.OVERRIDES)

        result = resolver.calculate_new_target(self._blueprint_ref(), self.OLD, self.NEW)

        assert result == "/process-framework/tasks/foo.md"

    def test_override_ref_to_unmoved_path_unchanged(self, temp_project_dir):
        """(c) A /... reference that does not resolve to the moved file is
        left unchanged."""
        self._make_moved_file(temp_project_dir)
        resolver = self._resolver(temp_project_dir, self.OVERRIDES)

        ref = self._blueprint_ref("/process-framework/guides/other.md")
        result = resolver.calculate_new_target(ref, self.OLD, self.NEW)

        assert result == "/process-framework/guides/other.md"

    def test_override_backslash_separator_preserved(self, temp_project_dir):
        """(d) An override-source reference written with backslash separators
        keeps them on rewrite (PD-BUG-112 regression class)."""
        self._make_moved_file(temp_project_dir)
        resolver = self._resolver(temp_project_dir, self.OVERRIDES)

        ref = self._blueprint_ref("\\process-framework\\tasks\\foo.md")
        result = resolver.calculate_new_target(ref, self.OLD, self.NEW)

        assert result == "\\process-framework\\tasks\\foo-task.md"

    def test_override_link_not_hijacked_by_coinciding_root_move(self, temp_project_dir):
        """(c) A virtual-root link must NOT be rewritten when a REAL root-level
        path that coincides with its virtual path moves.  E.g. root test/x.md
        moves while a blueprint link says /test/x.md — the blueprint link means
        <base>/test/x.md, not the root file, and must stay unchanged.
        (Found by the Step-13 quality audit: the early-exit equality/prefix
        branches compared the unresolved form and would have hijacked it.)"""
        # Real root-level file that moves
        moved = self._make_moved_file(temp_project_dir, rel="test/x-renamed.md")
        assert moved.exists()
        resolver = self._resolver(temp_project_dir, self.OVERRIDES)

        # Override-source link whose VIRTUAL path coincides with the root path
        ref = self._blueprint_ref("/test/x.md")
        result = resolver.calculate_new_target(ref, "test/x.md", "test/x-renamed.md")

        assert result == "/test/x.md", "virtual-root link hijacked by coinciding root move"

    def test_override_link_not_hijacked_by_coinciding_root_dir_move(self, temp_project_dir):
        """(c) Same protection for the directory-prefix early exit: a root-level
        DIRECTORY move must not relocate a virtual-root link under the same
        virtual prefix."""
        self._make_moved_file(temp_project_dir, rel="test2/sub/x.md")
        resolver = self._resolver(temp_project_dir, self.OVERRIDES)

        ref = self._blueprint_ref("/test/sub/x.md")
        result = resolver.calculate_new_target(ref, "test", "test2")

        assert result == "/test/sub/x.md", "virtual-root link hijacked by coinciding dir move"

    def test_override_link_not_hijacked_by_suffix_coinciding_move(self, temp_project_dir):
        """(c) The PD-BUG-045 suffix-match fallback must not fire for
        virtual-root links: a blueprint link /tasks/foo.md whose TRUE virtual
        target (<base>/tasks/foo.md) did not move must stay unchanged when an
        unrelated suffix-coinciding file (<override>/.../tasks/foo.md) is
        renamed.  Without the gate the link was rewritten to
        "tasks/foo-task.md" — wrong target AND virtual-root style lost.
        (2026-07-06 code-review Major finding: residual suffix hijack.)"""
        self._make_moved_file(temp_project_dir)
        resolver = self._resolver(temp_project_dir, self.OVERRIDES)

        # Virtual path /tasks/foo.md == <base>/tasks/foo.md, which is NOT the
        # moved file — but it is a path-suffix of the moved file's old path.
        ref = self._blueprint_ref("/tasks/foo.md")
        result = resolver.calculate_new_target(ref, self.OLD, self.NEW)

        assert result != "tasks/foo-task.md", "virtual-root link hijacked via suffix match"
        assert result == "/tasks/foo.md"

    def test_override_rewrite_emits_observability_event(self, temp_project_dir):
        """The override rewrite emits update_resolution_override_applied so
        blueprint rewrites are auditable (OB dimension)."""
        from unittest.mock import MagicMock

        self._make_moved_file(temp_project_dir)
        logger = MagicMock()
        resolver = self._resolver(temp_project_dir, self.OVERRIDES, logger=logger)

        resolver.calculate_new_target(self._blueprint_ref(), self.OLD, self.NEW)

        events = [call.args[0] for call in logger.debug.call_args_list]
        assert "update_resolution_override_applied" in events


class TestDocstringColumnCorruption:
    """PD-BUG-118 (Defect A) regression, end-to-end through parser + updater.

    The defect lives in the seam: the Python parser emits columns relative to
    the extracted docstring text, and the updater slices the physical line at
    them.  Neither component is wrong in isolation, so this test drives the
    real parser output into the real updater rather than hand-building refs.

    The corruption signature from the bug report is asserted ABSENT, not merely
    the correct string present -- a permissive positive assertion would pass
    even if the mangled text were emitted alongside the right one.
    """

    def test_docstring_line_replacement_has_no_character_duplication(self, temp_project_dir):
        """The literal PD-BUG-118 evidence case, reproduced through both layers."""
        from linkwatcher.parsers.python import PythonParser

        source_line = '    """Resolve database path to test/state-tracking/permanent/."""'
        py_file = temp_project_dir / "performance_db.py"
        py_file.write_text("def _resolve_db_path():\n" + source_line + "\n", encoding="utf-8")

        refs = PythonParser().parse_content(py_file.read_text(encoding="utf-8"), str(py_file))
        target = "test/state-tracking/permanent/"
        doc_refs = [r for r in refs if r.link_target == target]
        assert doc_refs, "parser must still find the docstring directory reference"

        updater = LinkUpdater(project_root=str(temp_project_dir))
        updater.set_backup_enabled(False)
        updater._apply_replacements(
            str(py_file), str(py_file), [(doc_refs[0], "test/state-tracking/archive")]
        )
        updated = py_file.read_text(encoding="utf-8")

        # Negative assertions: the documented corruption signatures must be gone.
        assert "ptest/" not in updated, "PD-BUG-118 doubled-letter corruption in: {!r}".format(
            updated
        )
        assert "anent/." not in updated, "PD-BUG-118 chopped-tail corruption in: {!r}".format(
            updated
        )
        assert "permanentanent" not in updated, "PD-BUG-118 corruption in: {!r}".format(updated)
        # Surrounding prose and the docstring delimiters must survive intact.
        assert "Resolve database path to " in updated
        assert updated.rstrip().endswith('"""')

    def test_docstring_replacement_leaves_prose_byte_identical(self, temp_project_dir):
        """Nothing outside the matched path span may change (the bug's Expected)."""
        from linkwatcher.parsers.python import PythonParser

        prefix = '    """Templates in '
        suffix = ' for reuse."""'
        old_dir = "process-framework/templates/support/"
        new_dir = "process-framework/templates/shared/"
        py_file = temp_project_dir / "mod.py"
        py_file.write_text("def f():\n" + prefix + old_dir + suffix + "\n", encoding="utf-8")

        refs = PythonParser().parse_content(py_file.read_text(encoding="utf-8"), str(py_file))
        doc_refs = [r for r in refs if r.link_target == old_dir]
        assert doc_refs, "parser must find the docstring directory reference"

        updater = LinkUpdater(project_root=str(temp_project_dir))
        updater.set_backup_enabled(False)
        updater._apply_replacements(str(py_file), str(py_file), [(doc_refs[0], new_dir)])
        updated = py_file.read_text(encoding="utf-8")

        expected = "def f():\n" + prefix + new_dir + suffix + "\n"
        assert updated == expected, "characters outside the matched span were altered: {!r}".format(
            updated
        )


class TestTrailingSlashPreservation:
    """PD-BUG-118 (Defect B) regression: a directory reference authored with a
    trailing slash was rewritten without it.

    Every rewrite in ``PathResolver._calculate_new_target_relative`` returns
    ``normalize_path()`` output, and ``os.path.normpath`` strips the trailing
    separator.  The rewrite therefore differed from the authored target even
    when the path itself was right, which both damaged the authored form and
    caused files to be written for a difference that carried no meaning.

    The sibling write path already solved this: ``reference_lookup``'s
    authored-form guard names the ``"dir/" to "dir"`` case explicitly.  These
    tests hold ``path_resolver`` to the same contract.
    """

    def _dir_ref(self, source_file, target):
        return LinkReference(
            file_path=source_file,
            line_number=1,
            column_start=0,
            column_end=len(target),
            link_text=target,
            link_target=target,
            link_type=LinkType.MARKDOWN_BACKTICK_DIR,
        )

    def test_exact_directory_match_preserves_trailing_slash(self, temp_project_dir):
        """`doc/state-tracking/` moving to doc/moved-tracking keeps its slash."""
        updater = LinkUpdater(project_root=str(temp_project_dir))
        ref = self._dir_ref("README.md", "doc/state-tracking/")

        result = updater._calculate_new_target(ref, "doc/state-tracking", "doc/moved-tracking")

        assert result == "doc/moved-tracking/", "authored trailing slash lost: {!r}".format(result)

    def test_slashless_target_stays_slashless(self, temp_project_dir):
        """Control: a target authored WITHOUT a slash must not gain one."""
        updater = LinkUpdater(project_root=str(temp_project_dir))
        ref = self._dir_ref("README.md", "doc/state-tracking")

        result = updater._calculate_new_target(ref, "doc/state-tracking", "doc/moved-tracking")

        assert result == "doc/moved-tracking", "unexpected trailing slash added: {!r}".format(
            result
        )

    def test_subdirectory_prefix_match_preserves_trailing_slash(self, temp_project_dir):
        """The directory-prefix branch must preserve the slash too."""
        (temp_project_dir / "doc" / "moved-tracking" / "permanent").mkdir(parents=True)
        updater = LinkUpdater(project_root=str(temp_project_dir))
        ref = self._dir_ref("README.md", "doc/state-tracking/permanent/")

        result = updater._calculate_new_target(ref, "doc/state-tracking", "doc/moved-tracking")

        assert result == "doc/moved-tracking/permanent/", "trailing slash lost: {!r}".format(result)

    def test_leading_slash_form_preserves_trailing_slash(self, temp_project_dir):
        """Root-absolute authored form keeps BOTH its leading and trailing slash."""
        updater = LinkUpdater(project_root=str(temp_project_dir))
        ref = self._dir_ref("README.md", "/doc/state-tracking/")

        result = updater._calculate_new_target(ref, "doc/state-tracking", "doc/moved-tracking")

        assert result == "/doc/moved-tracking/", "authored form damaged: {!r}".format(result)

    def test_backslash_target_preserves_trailing_backslash(self, temp_project_dir):
        """Separator style and trailing separator must both survive (PD-BUG-112 sibling)."""
        (temp_project_dir / "doc" / "moved-tracking").mkdir(parents=True)
        updater = LinkUpdater(project_root=str(temp_project_dir))
        ref = self._dir_ref("README.md", "doc\\state-tracking\\")

        result = updater._calculate_new_target(ref, "doc/state-tracking", "doc/moved-tracking")

        assert result == "doc\\moved-tracking\\", "authored form damaged: {!r}".format(result)

    def test_no_op_move_does_not_rewrite_file(self, temp_project_dir):
        """PD-BUG-118 (Defect B, safety net): a move whose old and new paths are
        the same must never write the file.

        Before the fix the trailing-slash difference alone made ``new_target !=
        link_target``, so the file was rewritten -- losing the authored slash --
        for a move that relocated nothing.  ``update_references`` is public API;
        it must be inert for a no-op move regardless of what upstream produced
        it.
        """
        md_file = temp_project_dir / "README.md"
        original = "See the `doc/state-tracking/` tracker.\n"
        md_file.write_text(original, encoding="utf-8")

        updater = LinkUpdater(project_root=str(temp_project_dir))
        updater.set_backup_enabled(False)
        target = "doc/state-tracking/"
        ref = LinkReference(
            file_path=str(md_file),
            line_number=1,
            column_start=original.index(target),
            column_end=original.index(target) + len(target),
            link_text=target,
            link_target=target,
            link_type=LinkType.MARKDOWN_BACKTICK_DIR,
        )

        stats = updater.update_references([ref], "doc/state-tracking", "doc/state-tracking")

        assert md_file.read_text(encoding="utf-8") == original, "no-op move rewrote the file"
        assert stats["files_updated"] == 0
