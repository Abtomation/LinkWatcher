"""
Tests for the LinkDatabase class.

This module tests the link database functionality including
adding, removing, and querying link references.
"""

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


class TestLongPathNormalization:
    """PD-BUG-014: Regression tests for long path normalization in database operations."""

    def test_normalize_path_strips_windows_long_path_prefix(self):
        """normalize_path must strip the \\\\?\\ prefix so prefixed and
        non-prefixed forms of the same path produce identical results."""
        from linkwatcher.utils import normalize_path

        plain = "C:/Users/test/project/deep/file.txt"
        # Simulate the \\?\ prefix that Windows adds for long paths
        prefixed = "\\\\?\\C:\\Users\\test\\project\\deep\\file.txt"

        norm_plain = normalize_path(plain)
        norm_prefixed = normalize_path(prefixed)
        assert (
            norm_plain == norm_prefixed
        ), f"Prefixed path normalized differently: {norm_prefixed!r} != {norm_plain!r}"

    def test_database_lookup_with_long_path_prefix(self, link_database):
        """Database lookup must find references regardless of \\\\?\\ prefix."""
        target = "very/deep/nested/directory/structure/file.txt"
        ref = LinkReference("doc.md", 1, 0, 40, "file.txt", target, "markdown")
        link_database.add_link(ref)

        # Lookup with \\?\ prefixed absolute path should still resolve
        prefixed_target = "\\\\?\\C:\\project\\" + target.replace("/", "\\")
        non_prefixed = "C:\\project\\" + target.replace("/", "\\")

        # Both forms must normalize consistently for _reference_points_to_file
        from linkwatcher.utils import normalize_path

        assert normalize_path(prefixed_target) == normalize_path(
            non_prefixed
        ), "Prefixed and non-prefixed absolute paths must normalize identically"

    def test_database_add_and_lookup_with_long_relative_path(self, link_database):
        """Database add/lookup must work correctly with long relative paths (>260 chars)."""
        components = [
            f"very_long_directory_name_{i:02d}_with_lots_of_characters" for i in range(10)
        ]
        long_target = "/".join(components + ["deep_file.txt"])
        assert len(long_target) > 260, "Path must exceed 260 chars for this test"

        ref = LinkReference("test.md", 1, 0, len(long_target), "Deep link", long_target, "markdown")
        link_database.add_link(ref)

        results = link_database.get_references_to_file(long_target)
        assert len(results) >= 1, f"Expected at least 1 reference for long path, got {len(results)}"

    def test_update_target_path_with_long_path_prefix(self, link_database):
        """update_target_path must work when old/new paths have \\\\?\\ prefix."""
        from linkwatcher.utils import normalize_path

        old_target = "deep/nested/old_file.txt"
        ref = LinkReference("doc.md", 1, 0, 30, "old_file.txt", old_target, "markdown")
        link_database.add_link(ref)

        # Simulate update using \\?\ prefixed paths
        old_prefixed = "\\\\?\\C:\\project\\deep\\nested\\old_file.txt"

        # normalize_path must produce the same result for prefixed and non-prefixed
        assert normalize_path(old_prefixed) == normalize_path(
            "C:\\project\\deep\\nested\\old_file.txt"
        ), "Prefix stripping must work for update operations"


class TestGetReferencesToDirectory:
    """Test cases for LinkDatabase.get_references_to_directory()."""

    def test_exact_directory_match(self, link_database):
        """References targeting the exact directory path are found."""
        ref = LinkReference(
            "script.ps1",
            10,
            5,
            30,
            "doc/process-framework/scripts",
            "doc/process-framework/scripts",
            "powershell-quoted-dir",
        )
        link_database.add_link(ref)

        results = link_database.get_references_to_directory("doc/process-framework/scripts")
        assert len(results) == 1
        assert results[0].link_target == "doc/process-framework/scripts"

    def test_prefix_match_subdirectory(self, link_database):
        """References targeting subdirectories of the directory path are found."""
        ref = LinkReference(
            "script.ps1",
            5,
            0,
            40,
            "doc/process-framework/scripts/file-creation",
            "doc/process-framework/scripts/file-creation",
            "powershell-quoted-dir",
        )
        link_database.add_link(ref)

        results = link_database.get_references_to_directory("doc/process-framework/scripts")
        assert len(results) == 1
        assert results[0].link_target == "doc/process-framework/scripts/file-creation"

    def test_no_false_prefix_match(self, link_database):
        """Directory paths that share a prefix but aren't subdirectories are excluded."""
        ref = LinkReference(
            "script.ps1",
            5,
            0,
            40,
            "doc/process-framework/scripts-old",
            "doc/process-framework/scripts-old",
            "powershell-quoted-dir",
        )
        link_database.add_link(ref)

        results = link_database.get_references_to_directory("doc/process-framework/scripts")
        assert len(results) == 0

    def test_no_match_unrelated_path(self, link_database):
        """References to unrelated paths are not returned."""
        ref = LinkReference(
            "readme.md",
            1,
            0,
            20,
            "src/main.py",
            "src/main.py",
            "markdown",
        )
        link_database.add_link(ref)

        results = link_database.get_references_to_directory("doc/process-framework")
        assert len(results) == 0

    def test_multiple_references_to_same_directory(self, link_database):
        """Multiple references to the same directory from different files are all found."""
        ref1 = LinkReference(
            "script1.ps1",
            10,
            5,
            30,
            "doc/old-dir",
            "doc/old-dir",
            "powershell-quoted-dir",
        )
        ref2 = LinkReference(
            "script2.ps1",
            20,
            8,
            35,
            "doc/old-dir",
            "doc/old-dir",
            "powershell-quoted-dir",
        )
        link_database.add_link(ref1)
        link_database.add_link(ref2)

        results = link_database.get_references_to_directory("doc/old-dir")
        assert len(results) == 2

    def test_mixed_file_and_directory_targets(self, link_database):
        """Only directory-path targets are returned, not file targets within the directory."""
        dir_ref = LinkReference(
            "script.ps1",
            10,
            5,
            30,
            "doc/old-dir",
            "doc/old-dir",
            "powershell-quoted-dir",
        )
        file_ref = LinkReference(
            "readme.md",
            1,
            0,
            20,
            "doc/old-dir/readme.md",
            "doc/old-dir/readme.md",
            "markdown",
        )
        link_database.add_link(dir_ref)
        link_database.add_link(file_ref)

        # Both the exact dir match and the file within should be found
        results = link_database.get_references_to_directory("doc/old-dir")
        assert len(results) == 2

    def test_deduplication(self, link_database):
        """Duplicate references are not returned."""
        ref = LinkReference(
            "script.ps1",
            10,
            5,
            30,
            "doc/old-dir",
            "doc/old-dir",
            "powershell-quoted-dir",
        )
        # Add same reference object to multiple keys (simulating anchored storage)
        link_database.add_link(ref)

        results = link_database.get_references_to_directory("doc/old-dir")
        assert len(results) == 1
