"""
Tests for the LinkDatabase class.

This module tests the link database functionality including
adding, removing, and querying link references.
"""

import pytest

from linkwatcher.database import LinkDatabase
from linkwatcher.models import LinkReference


class TestLinkDatabase:
    """Test cases for LinkDatabase."""

    def test_add_link(self, link_database):
        """Test adding a link reference."""
        ref = LinkReference(
            file_path="test.md",
            line_number=1,
            column_start=0,
            column_end=10,
            link_text="test.txt",
            link_target="test.txt",
            link_type="markdown",
        )

        link_database.add_link(ref)

        assert "test.txt" in link_database.links
        assert len(link_database.links["test.txt"]) == 1
        assert link_database.links["test.txt"][0] == ref
        assert "test.md" in link_database.files_with_links

    def test_remove_file_links(self, link_database):
        """Test removing all links from a file."""
        ref1 = LinkReference("test.md", 1, 0, 10, "docs/file1.txt", "docs/file1.txt", "markdown")
        ref2 = LinkReference("test.md", 2, 0, 10, "file2.txt", "file2.txt", "markdown")
        ref3 = LinkReference("other.md", 1, 0, 10, "docs/file1.txt", "docs/file1.txt", "markdown")

        link_database.add_link(ref1)
        link_database.add_link(ref2)
        link_database.add_link(ref3)

        # Remove links from test.md
        link_database.remove_file_links("test.md")

        # test.md should be removed from files_with_links
        assert "test.md" not in link_database.files_with_links
        assert "other.md" in link_database.files_with_links

        # file2.txt should be completely removed (only referenced by test.md)
        assert "file2.txt" not in link_database.links

        # docs/file1.txt should still have reference from other.md
        assert "docs/file1.txt" in link_database.links
        assert len(link_database.links["docs/file1.txt"]) == 1
        assert link_database.links["docs/file1.txt"][0].file_path == "other.md"

    def test_get_references_to_file(self, link_database):
        """Test getting references to a specific file."""
        ref1 = LinkReference("doc1.md", 1, 0, 10, "target.txt", "target.txt", "markdown")
        ref2 = LinkReference("doc2.md", 1, 0, 10, "target.txt", "target.txt", "markdown")
        ref3 = LinkReference("doc3.md", 1, 0, 10, "other.txt", "other.txt", "markdown")

        link_database.add_link(ref1)
        link_database.add_link(ref2)
        link_database.add_link(ref3)

        references = link_database.get_references_to_file("target.txt")

        assert len(references) == 2
        file_paths = [ref.file_path for ref in references]
        assert "doc1.md" in file_paths
        assert "doc2.md" in file_paths
        assert "doc3.md" not in file_paths

    def test_update_target_path(self, link_database):
        """Test updating target path for references."""
        ref = LinkReference("doc.md", 1, 0, 10, "old.txt", "old.txt", "markdown")
        link_database.add_link(ref)

        # Update the target path
        link_database.update_target_path("old.txt", "new.txt")

        # Old target should be gone
        assert "old.txt" not in link_database.links

        # New target should exist
        assert "new.txt" in link_database.links
        assert len(link_database.links["new.txt"]) == 1

        # Reference should be updated
        updated_ref = link_database.links["new.txt"][0]
        assert updated_ref.link_target == "new.txt"

    def test_normalize_path(self, link_database):
        """Test path normalization."""
        from linkwatcher.utils import normalize_path

        # Test various path formats
        assert normalize_path("/file.txt") == "file.txt"
        assert normalize_path("./file.txt") == "file.txt"
        assert normalize_path("../file.txt") == "../file.txt"
        assert normalize_path("docs/file.txt") == "docs/file.txt"

    def test_reference_points_to_file(self, link_database):
        """Test reference matching logic."""
        ref = LinkReference("docs/readme.md", 1, 0, 10, "test.txt", "test.txt", "markdown")

        # Direct match
        assert link_database._reference_points_to_file(ref, "test.txt")

        # Same directory match
        assert link_database._reference_points_to_file(ref, "docs/test.txt")

        # Different directory - should not match
        assert not link_database._reference_points_to_file(ref, "other/test.txt")

    def test_relative_path_resolution(self, link_database):
        """Test relative path resolution in references."""
        ref = LinkReference("docs/readme.md", 1, 0, 10, "../test.txt", "../test.txt", "markdown")

        # Should resolve to parent directory
        assert link_database._reference_points_to_file(ref, "test.txt")

        # Should not match file in docs directory
        assert not link_database._reference_points_to_file(ref, "docs/test.txt")

    def test_anchor_handling(self, link_database):
        """Test handling of anchored links."""
        ref = LinkReference("doc.md", 1, 0, 20, "test.txt#section", "test.txt#section", "markdown")
        link_database.add_link(ref)

        # Should find reference when looking for the base file
        references = link_database.get_references_to_file("test.txt")
        assert len(references) == 1
        assert references[0].link_target == "test.txt#section"

        # Update should preserve anchor
        link_database.update_target_path("test.txt", "new.txt")
        updated_refs = link_database.get_references_to_file("new.txt")
        assert len(updated_refs) == 1
        assert updated_refs[0].link_target == "new.txt#section"

    def test_get_stats(self, link_database):
        """Test database statistics."""
        # Empty database
        stats = link_database.get_stats()
        assert stats["total_targets"] == 0
        assert stats["total_references"] == 0
        assert stats["files_with_links"] == 0

        # Add some references
        ref1 = LinkReference("doc1.md", 1, 0, 10, "docs/file1.txt", "docs/file1.txt", "markdown")
        ref2 = LinkReference("doc1.md", 2, 0, 10, "file2.txt", "file2.txt", "markdown")
        ref3 = LinkReference("doc2.md", 1, 0, 10, "docs/file1.txt", "docs/file1.txt", "markdown")

        link_database.add_link(ref1)
        link_database.add_link(ref2)
        link_database.add_link(ref3)

        stats = link_database.get_stats()
        assert stats["total_targets"] == 2  # docs/file1.txt and file2.txt
        assert stats["total_references"] == 3  # 3 references total
        assert stats["files_with_links"] == 2  # doc1.md, doc2.md

    def test_clear(self, link_database):
        """Test clearing the database."""
        ref = LinkReference("doc.md", 1, 0, 10, "file.txt", "file.txt", "markdown")
        link_database.add_link(ref)

        assert len(link_database.links) > 0
        assert len(link_database.files_with_links) > 0

        link_database.clear()

        assert len(link_database.links) == 0
        assert len(link_database.files_with_links) == 0
        assert link_database.last_scan is None

    def test_thread_safety(self, link_database):
        """Test basic thread safety with locks."""
        import threading
        import time

        def add_references():
            for i in range(100):
                ref = LinkReference(
                    f"doc{i}.md", 1, 0, 10, f"file{i}.txt", f"file{i}.txt", "markdown"
                )
                link_database.add_link(ref)
                time.sleep(0.001)  # Small delay to encourage race conditions

        # Start multiple threads
        threads = []
        for _ in range(3):
            thread = threading.Thread(target=add_references)
            threads.append(thread)
            thread.start()

        # Wait for all threads to complete
        for thread in threads:
            thread.join()

        # Check that all references were added correctly
        stats = link_database.get_stats()
        assert stats["total_references"] == 300  # 3 threads * 100 references each
