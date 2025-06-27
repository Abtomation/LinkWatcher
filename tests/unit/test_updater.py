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
        updater = LinkUpdater()

        assert updater._normalize_path("/test/file.txt") == "test/file.txt"
        assert updater._normalize_path("test\\file.txt") == "test/file.txt"
        assert updater._normalize_path("./test/file.txt") == "test/file.txt"

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
            LinkReference(str(test_file), 3, 13, 20, "link", "old.txt", "markdown"),  # First [link](old.txt)
            LinkReference(str(test_file), 3, 40, 47, "link", "old.txt", "markdown"),  # second [link](old.txt)
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
