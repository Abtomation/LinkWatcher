"""
Tests for the LinkUpdater class.

This module tests the file updating functionality when links need
to be changed due to file moves or renames.
"""

from pathlib import Path

import pytest

from linkwatcher.models import LinkReference
from linkwatcher.updater import LinkUpdater


class TestLinkUpdater:
    """Test cases for LinkUpdater."""

    def test_updater_initialization(self):
        """Test updater initialization."""
        updater = LinkUpdater()

        assert updater.backup_enabled == True
        assert updater.dry_run == False

    def test_set_dry_run_mode(self):
        """Test enabling/disabling dry run mode."""
        updater = LinkUpdater()

        # Enable dry run
        updater.set_dry_run(True)
        assert updater.dry_run == True

        # Disable dry run
        updater.set_dry_run(False)
        assert updater.dry_run == False

    def test_set_backup_enabled(self):
        """Test enabling/disabling backup creation."""
        updater = LinkUpdater()

        # Disable backups
        updater.set_backup_enabled(False)
        assert updater.backup_enabled == False

        # Enable backups
        updater.set_backup_enabled(True)
        assert updater.backup_enabled == True

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

    def test_replace_path_part_exact_match(self):
        """Test replacing path part with exact match."""
        updater = LinkUpdater()

        result = updater._replace_path_part("old.txt", "old.txt", "new.txt")
        assert result == "new.txt"

        # Test with absolute path
        result = updater._replace_path_part("/old.txt", "old.txt", "new.txt")
        assert result == "/new.txt"

    def test_replace_path_part_partial_match(self):
        """Test replacing path part with partial match."""
        updater = LinkUpdater()

        result = updater._replace_path_part("docs/old.txt", "old.txt", "new.txt")
        assert result == "docs/new.txt"

    def test_replace_path_part_no_match(self):
        """Test replacing path part with no match returns original."""
        updater = LinkUpdater()

        result = updater._replace_path_part("other.txt", "old.txt", "new.txt")
        assert result == "other.txt"

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
        stats = updater.update_references([ref], "old.txt", "new.txt")

        # Should create backup file
        backup_file = temp_project_dir / "test.md.linkwatcher.bak"
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

        assert result == "stale"
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

        assert result == "stale"
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

        assert result == "updated"
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
        assert result == "stale"
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

        assert result == "no_changes"


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
        target_dir = temp_project_dir / "doc" / "state-tracking"
        target_dir.mkdir(parents=True)
        new_target_dir = temp_project_dir / "doc" / "tracking"
        new_target_dir.mkdir(parents=True)

        # Script with a root-relative path argument
        script_file = script_dir / "New-BugReport.ps1"
        content = (
            "$BugTrackingFile = Join-Path -Path $ProjectRoot "
            '-ChildPath "doc/state-tracking/bug-tracking.md"\n'
        )
        script_file.write_text(content)

        # Reference as GenericParser would create it
        ref = LinkReference(
            file_path="scripts/file-creation/New-BugReport.ps1",
            line_number=1,
            column_start=content.index("doc/state-tracking"),
            column_end=content.index("doc/state-tracking")
            + len("doc/state-tracking/bug-tracking.md"),
            link_text="doc/state-tracking/bug-tracking.md",
            link_target="doc/state-tracking/bug-tracking.md",
            link_type="generic-quoted",
        )

        old_path = "doc/state-tracking/bug-tracking.md"
        new_path = "doc/tracking/bug-tracking.md"

        new_target = updater._calculate_new_target(ref, old_path, new_path)

        # Must be the new root-relative path, NOT "../../tracking/bug-tracking.md"
        assert new_target == "doc/tracking/bug-tracking.md"
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
        content = '$path = "doc/config/settings.yaml"\n'
        script_file.write_text(content)

        ref = LinkReference(
            file_path="scripts/deep/tool.ps1",
            line_number=1,
            column_start=content.index("doc/config"),
            column_end=content.index("doc/config") + len("doc/config/settings.yaml"),
            link_text="doc/config/settings.yaml",
            link_target="doc/config/settings.yaml",
            link_type="generic-quoted",
        )

        stats = updater.update_references(
            [ref], "doc/config/settings.yaml", "doc/configuration/settings.yaml"
        )

        assert stats["files_updated"] == 1
        updated = script_file.read_text()
        assert "doc/configuration/settings.yaml" in updated
        assert "doc/config/settings.yaml" not in updated
        # Must NOT contain source-relative path
        assert "../" not in updated

    def test_explicit_relative_path_still_works(self, temp_project_dir):
        """Ensure explicit relative paths (../) are NOT affected by the fix."""
        updater = LinkUpdater(str(temp_project_dir))
        updater.set_backup_enabled(False)

        doc_dir = temp_project_dir / "doc" / "guides"
        doc_dir.mkdir(parents=True)

        md_file = doc_dir / "guide.md"
        content = "See [tracking](../state-tracking/bug-tracking.md) for details.\n"
        md_file.write_text(content)

        ref = LinkReference(
            file_path="doc/guides/guide.md",
            line_number=1,
            column_start=14,
            column_end=14 + len("../state-tracking/bug-tracking.md"),
            link_text="tracking",
            link_target="../state-tracking/bug-tracking.md",
            link_type="markdown",
        )

        old_path = "doc/state-tracking/bug-tracking.md"
        new_path = "doc/tracking/bug-tracking.md"

        new_target = updater._calculate_new_target(ref, old_path, new_path)

        # "../state-tracking/bug-tracking.md" != "doc/state-tracking/bug-tracking.md"
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
            link_text="/doc/state/file.md",
            link_target="/doc/state/file.md",
            link_type="generic-quoted",
        )

        new_target = updater._calculate_new_target(
            ref, "doc/state/file.md", "doc/new-state/file.md"
        )

        # Leading slash should be preserved
        assert new_target == "/doc/new-state/file.md"

    def test_unrelated_root_relative_path_not_modified(self):
        """Test that a root-relative path NOT matching old_path is left alone."""
        updater = LinkUpdater()

        ref = LinkReference(
            file_path="scripts/tool.ps1",
            line_number=1,
            column_start=0,
            column_end=20,
            link_text="doc/other/file.md",
            link_target="doc/other/file.md",
            link_type="generic-quoted",
        )

        new_target = updater._calculate_new_target(
            ref, "doc/state/bug-tracking.md", "doc/new-state/bug-tracking.md"
        )

        # Different path — should not be modified
        assert new_target == "doc/other/file.md"
