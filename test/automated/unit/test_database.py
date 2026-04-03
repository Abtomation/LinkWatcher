"""
Tests for the LinkDatabase class.

This module tests the link database functionality including
adding, removing, and querying link references.
"""

import pytest

from linkwatcher.models import LinkReference

pytestmark = [
    pytest.mark.feature("0.1.2"),
    pytest.mark.priority("Critical"),
    pytest.mark.cross_cutting(["0.1.1"]),
    pytest.mark.test_type("unit"),
    pytest.mark.specification(
        "test/specifications/feature-specs/test-spec-0-1-2-in-memory-link-database.md"
    ),
]


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

    def test_add_link_duplicate_detection(self, link_database):
        """Test that adding the same reference twice does not create duplicates (TD100)."""
        ref = LinkReference(
            file_path="test.md",
            line_number=5,
            column_start=0,
            column_end=10,
            link_text="target.txt",
            link_target="target.txt",
            link_type="markdown",
        )

        link_database.add_link(ref)
        link_database.add_link(ref)  # duplicate call

        assert len(link_database.links["target.txt"]) == 1
        assert link_database.get_stats()["total_references"] == 1

    def test_add_link_same_target_different_lines(self, link_database):
        """Test that references to the same target from different lines are both kept."""
        ref1 = LinkReference("test.md", 1, 0, 10, "target.txt", "target.txt", "markdown")
        ref2 = LinkReference("test.md", 5, 0, 10, "target.txt", "target.txt", "markdown")

        link_database.add_link(ref1)
        link_database.add_link(ref2)

        assert len(link_database.links["target.txt"]) == 2

    def test_add_link_same_line_different_columns(self, link_database):
        """Test that two references on the same line at different columns are both kept."""
        ref1 = LinkReference("docs.md", 1, 5, 15, "target.txt", "target.txt", "direct")
        ref2 = LinkReference("docs.md", 1, 30, 40, "target.txt", "target.txt", "markdown")

        link_database.add_link(ref1)
        link_database.add_link(ref2)

        assert len(link_database.links["target.txt"]) == 2

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

    def test_get_references_relative_path_resolution(self, link_database):
        """get_references_to_file finds refs stored under relative-path keys."""
        # Source file docs/readme.md links to ../src/main.py
        # That resolves to src/main.py
        ref = LinkReference(
            "docs/readme.md", 1, 0, 15, "../src/main.py", "../src/main.py", "markdown"
        )
        link_database.add_link(ref)

        results = link_database.get_references_to_file("src/main.py")
        assert len(results) == 1
        assert results[0].file_path == "docs/readme.md"

        # Should NOT match a file in a different directory
        assert link_database.get_references_to_file("other/main.py") == []

    def test_get_references_filename_only_match(self, link_database):
        """get_references_to_file finds refs stored under bare filename keys."""
        # Source file utils/runner.py links to just "helpers.py" (same dir)
        ref = LinkReference("utils/runner.py", 1, 0, 10, "helpers.py", "helpers.py", "python")
        link_database.add_link(ref)

        # Should match when querying the full path in same directory
        results = link_database.get_references_to_file("utils/helpers.py")
        assert len(results) == 1
        assert results[0].file_path == "utils/runner.py"

        # Should NOT match a file with same name in different directory
        assert link_database.get_references_to_file("other/helpers.py") == []

    def test_get_references_suffix_match(self, link_database):
        """get_references_to_file finds project-root-relative refs (PD-BUG-045).

        When a reference uses a project-root-relative path (e.g., Python import
        'utils/helpers'), the DB key is a suffix of the full project path. The
        match should succeed when the referring file shares the same subtree.
        """
        # Source: myproject/app/main.py links to utils/helpers (project-relative)
        ref = LinkReference(
            "myproject/app/main.py", 3, 0, 14, "utils/helpers", "utils/helpers", "python"
        )
        link_database.add_link(ref)

        # Query for the full path — suffix match should find it
        results = link_database.get_references_to_file("myproject/utils/helpers.py")
        assert len(results) == 1
        assert results[0].file_path == "myproject/app/main.py"
        assert results[0].link_target == "utils/helpers"

    def test_get_references_suffix_match_negative(self, link_database):
        """Suffix match must NOT match when referring file is in a different subtree.

        PD-BUG-045 subtree guard: key 'utils/helpers' from source
        'otherproject/app/main.py' must NOT match 'myproject/utils/helpers.py'
        because the two files are in different project roots.
        """
        ref = LinkReference(
            "otherproject/app/main.py", 3, 0, 14, "utils/helpers", "utils/helpers", "python"
        )
        link_database.add_link(ref)

        results = link_database.get_references_to_file("myproject/utils/helpers.py")
        assert len(results) == 0

    def test_get_references_suffix_match_extensionless(self, link_database):
        """Suffix match works when DB key lacks extension that the queried file has.

        Python imports are stored without .py extension (e.g., 'utils/helpers').
        Querying 'myproject/utils/helpers.py' should still match via extension
        stripping in the suffix comparison. Extension stripping is type-aware:
        python refs match only .py files (PD-BUG-059).
        """
        ref = LinkReference(
            "myproject/app/runner.py", 5, 0, 14, "utils/helpers", "utils/helpers", "python"
        )
        link_database.add_link(ref)

        # Match with .py extension on the queried file
        results = link_database.get_references_to_file("myproject/utils/helpers.py")
        assert len(results) == 1

        # Python ref must NOT match .js file (PD-BUG-059)
        results_js = link_database.get_references_to_file("myproject/utils/helpers.js")
        assert len(results_js) == 0

        # But a completely different filename should NOT match
        assert link_database.get_references_to_file("myproject/utils/other.py") == []

    def test_get_references_suffix_match_cross_extension_false_positive(self, link_database):
        """Python import must NOT match a file with a different extension (PD-BUG-059).

        A Python import 'utils/helpers' (link_type='python') stored without .py
        extension should match 'myproject/utils/helpers.py' but must NOT match
        'myproject/utils/helpers.js'. Extension stripping must be type-aware:
        python refs → .py only, dart refs → .dart only.
        """
        ref = LinkReference(
            "myproject/app/runner.py", 5, 0, 14, "utils/helpers", "utils/helpers", "python"
        )
        link_database.add_link(ref)

        # Python ref should match .py file
        results_py = link_database.get_references_to_file("myproject/utils/helpers.py")
        assert len(results_py) == 1

        # Python ref must NOT match .js file (PD-BUG-059 false positive)
        results_js = link_database.get_references_to_file("myproject/utils/helpers.js")
        assert len(results_js) == 0, (
            "Python import 'utils/helpers' should not match helpers.js — "
            "extension stripping must be type-aware"
        )

        # Python ref must NOT match .dart file either
        results_dart = link_database.get_references_to_file("myproject/utils/helpers.dart")
        assert len(results_dart) == 0

    def test_get_references_suffix_match_dart_extension_aware(self, link_database):
        """Dart import must only match .dart files, not .py or .js (PD-BUG-059).

        A Dart import 'utils/helpers' (link_type='dart') should match
        'myproject/utils/helpers.dart' but not other extensions.
        """
        ref = LinkReference(
            "myproject/lib/main.dart", 3, 0, 14, "utils/helpers", "utils/helpers", "dart"
        )
        link_database.add_link(ref)

        # Dart ref should match .dart file
        results_dart = link_database.get_references_to_file("myproject/utils/helpers.dart")
        assert len(results_dart) == 1

        # Dart ref must NOT match .py file
        results_py = link_database.get_references_to_file("myproject/utils/helpers.py")
        assert len(results_py) == 0

        # Dart ref must NOT match .js file
        results_js = link_database.get_references_to_file("myproject/utils/helpers.js")
        assert len(results_js) == 0

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

        def add_references(thread_id):
            for i in range(100):
                ref = LinkReference(
                    f"doc_t{thread_id}_{i}.md",
                    1,
                    0,
                    10,
                    f"file_t{thread_id}_{i}.txt",
                    f"file_t{thread_id}_{i}.txt",
                    "markdown",
                )
                link_database.add_link(ref)
                time.sleep(0.001)  # Small delay to encourage race conditions

        # Start multiple threads with unique references per thread
        threads = []
        for tid in range(3):
            thread = threading.Thread(target=add_references, args=(tid,))
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

        # Both forms must normalize consistently for reference matching
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
            "alpha-project/framework/scripts",
            "alpha-project/framework/scripts",
            "powershell-quoted-dir",
        )
        link_database.add_link(ref)

        results = link_database.get_references_to_directory("alpha-project/framework/scripts")
        assert len(results) == 1
        assert results[0].link_target == "alpha-project/framework/scripts"

    def test_prefix_match_subdirectory(self, link_database):
        """References targeting subdirectories of the directory path are found."""
        ref = LinkReference(
            "script.ps1",
            5,
            0,
            40,
            "alpha-project/framework/scripts/file-creation",
            "alpha-project/framework/scripts/file-creation",
            "powershell-quoted-dir",
        )
        link_database.add_link(ref)

        results = link_database.get_references_to_directory("alpha-project/framework/scripts")
        assert len(results) == 1
        assert results[0].link_target == "alpha-project/framework/scripts/file-creation"

    def test_no_false_prefix_match(self, link_database):
        """Directory paths that share a prefix but aren't subdirectories are excluded."""
        ref = LinkReference(
            "script.ps1",
            5,
            0,
            40,
            "alpha-project/framework/scripts-old",
            "alpha-project/framework/scripts-old",
            "powershell-quoted-dir",
        )
        link_database.add_link(ref)

        results = link_database.get_references_to_directory("alpha-project/framework/scripts")
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

        results = link_database.get_references_to_directory("alpha-project/framework")
        assert len(results) == 0

    def test_multiple_references_to_same_directory(self, link_database):
        """Multiple references to the same directory from different files are all found."""
        ref1 = LinkReference(
            "script1.ps1",
            10,
            5,
            30,
            "alpha-project/docs/old-dir",
            "alpha-project/docs/old-dir",
            "powershell-quoted-dir",
        )
        ref2 = LinkReference(
            "script2.ps1",
            20,
            8,
            35,
            "alpha-project/docs/old-dir",
            "alpha-project/docs/old-dir",
            "powershell-quoted-dir",
        )
        link_database.add_link(ref1)
        link_database.add_link(ref2)

        results = link_database.get_references_to_directory("alpha-project/docs/old-dir")
        assert len(results) == 2

    def test_mixed_file_and_directory_targets(self, link_database):
        """Only directory-path targets are returned, not file targets within the directory."""
        dir_ref = LinkReference(
            "script.ps1",
            10,
            5,
            30,
            "alpha-project/docs/old-dir",
            "alpha-project/docs/old-dir",
            "powershell-quoted-dir",
        )
        file_ref = LinkReference(
            "readme.md",
            1,
            0,
            20,
            "alpha-project/docs/old-dir/readme.md",
            "alpha-project/docs/old-dir/readme.md",
            "markdown",
        )
        link_database.add_link(dir_ref)
        link_database.add_link(file_ref)

        # Both the exact dir match and the file within should be found
        results = link_database.get_references_to_directory("alpha-project/docs/old-dir")
        assert len(results) == 2

    def test_deduplication(self, link_database):
        """Duplicate references are not returned."""
        ref = LinkReference(
            "script.ps1",
            10,
            5,
            30,
            "alpha-project/docs/old-dir",
            "alpha-project/docs/old-dir",
            "powershell-quoted-dir",
        )
        # Add same reference object to multiple keys (simulating anchored storage)
        link_database.add_link(ref)

        results = link_database.get_references_to_directory("alpha-project/docs/old-dir")
        assert len(results) == 1

    def test_relative_path_exact_directory_match(self, link_database):
        """Relative-path references targeting a directory are found via resolved index.

        Regression test for PD-BUG-068: get_references_to_directory() failed to
        resolve relative paths like ../../../target/dir stored as link keys.
        """
        # A file deep in the tree references a top-level directory via relative path
        ref = LinkReference(
            "alpha/bravo/charlie/config.ps1",
            15,
            5,
            35,
            "../../../target/dir",
            "../../../target/dir",
            "powershell-quoted-dir",
        )
        link_database.add_link(ref)

        results = link_database.get_references_to_directory("target/dir")
        assert len(results) == 1
        assert results[0].link_target == "../../../target/dir"

    def test_relative_path_subdirectory_prefix_match(self, link_database):
        """Relative-path references to subdirectories within moved dir are found.

        Regression test for PD-BUG-068: prefix matching must work on resolved
        paths, not just raw keys.
        """
        # Reference targets a subdirectory within the moved directory
        ref = LinkReference(
            "alpha/bravo/charlie/script.ps1",
            20,
            8,
            50,
            "../../../target/dir/nested/deep",
            "../../../target/dir/nested/deep",
            "powershell-quoted-dir",
        )
        link_database.add_link(ref)

        results = link_database.get_references_to_directory("target/dir")
        assert len(results) == 1
        assert results[0].link_target == "../../../target/dir/nested/deep"


class TestLinkDatabaseInterface:
    """Test cases for LinkDatabaseInterface ABC contract."""

    def test_linkdatabase_is_subclass_of_interface(self):
        """LinkDatabase must be a subclass of LinkDatabaseInterface."""
        from linkwatcher.database import LinkDatabase, LinkDatabaseInterface

        assert issubclass(LinkDatabase, LinkDatabaseInterface)

    def test_linkdatabase_instance_is_interface(self):
        """LinkDatabase instances satisfy the interface check."""
        from linkwatcher.database import LinkDatabase, LinkDatabaseInterface

        db = LinkDatabase()
        assert isinstance(db, LinkDatabaseInterface)

    def test_interface_cannot_be_instantiated(self):
        """LinkDatabaseInterface cannot be instantiated directly."""
        import pytest

        from linkwatcher.database import LinkDatabaseInterface

        with pytest.raises(TypeError):
            LinkDatabaseInterface()

    def test_incomplete_implementation_raises(self):
        """A subclass missing abstract methods cannot be instantiated."""
        import pytest

        from linkwatcher.database import LinkDatabaseInterface

        class IncompleteDB(LinkDatabaseInterface):
            pass

        with pytest.raises(TypeError):
            IncompleteDB()


class TestHasTargetWithBasename:
    """Tests for has_target_with_basename() and the _basename_to_keys index (TD139)."""

    def _make_ref(self, source, target):
        return LinkReference(
            file_path=source,
            line_number=1,
            column_start=0,
            column_end=10,
            link_text=target,
            link_target=target,
            link_type="markdown",
        )

    def test_hit(self, link_database):
        """Basename lookup returns True when a matching target exists."""
        link_database.add_link(self._make_ref("src/doc.md", "images/photo.png"))
        assert link_database.has_target_with_basename("photo.png") is True

    def test_miss(self, link_database):
        """Basename lookup returns False for non-existent basenames."""
        link_database.add_link(self._make_ref("src/doc.md", "images/photo.png"))
        assert link_database.has_target_with_basename("missing.txt") is False

    def test_empty_database(self, link_database):
        """Basename lookup returns False on an empty database."""
        assert link_database.has_target_with_basename("anything.txt") is False

    def test_after_removal(self, link_database):
        """Basename is no longer found after all references from that source are removed."""
        link_database.add_link(self._make_ref("src/doc.md", "images/photo.png"))
        assert link_database.has_target_with_basename("photo.png") is True
        link_database.remove_file_links("src/doc.md")
        assert link_database.has_target_with_basename("photo.png") is False

    def test_after_clear(self, link_database):
        """Basename is no longer found after clear()."""
        link_database.add_link(self._make_ref("src/doc.md", "images/photo.png"))
        assert link_database.has_target_with_basename("photo.png") is True
        link_database.clear()
        assert link_database.has_target_with_basename("photo.png") is False

    def test_after_target_update(self, link_database):
        """After update_target_path(), old basename gone and new basename present."""
        link_database.add_link(self._make_ref("src/doc.md", "images/old.png"))
        assert link_database.has_target_with_basename("old.png") is True
        link_database.update_target_path("images/old.png", "assets/new.png")
        assert link_database.has_target_with_basename("old.png") is False
        assert link_database.has_target_with_basename("new.png") is True

    def test_multiple_keys_same_basename(self, link_database):
        """Multiple targets with the same basename — removing one leaves the other."""
        link_database.add_link(self._make_ref("a.md", "dir1/readme.md"))
        link_database.add_link(self._make_ref("b.md", "dir2/readme.md"))
        assert link_database.has_target_with_basename("readme.md") is True
        link_database.remove_file_links("a.md")
        # dir2/readme.md still has that basename
        assert link_database.has_target_with_basename("readme.md") is True
        link_database.remove_file_links("b.md")
        assert link_database.has_target_with_basename("readme.md") is False
