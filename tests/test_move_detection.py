"""
Test suite to verify the enhanced move detection logic.

Tests the internal _detect_potential_move and _handle_detected_move methods
of the LinkMaintenanceHandler to ensure move operations are correctly
detected from paired delete+create events and that references are updated.
"""

import threading
import time
from pathlib import Path

import pytest

from linkwatcher.database import LinkDatabase
from linkwatcher.handler import LinkMaintenanceHandler
from linkwatcher.parser import LinkParser
from linkwatcher.updater import LinkUpdater


class TestMoveDetectionLogic:
    """Tests for the move detection logic in the handler."""

    @pytest.fixture
    def project_setup(self, tmp_path):
        """Set up a test project with handler components."""
        # Create test structure
        test_file = tmp_path / "file1.txt"
        test_file.write_text("Test content")

        docs_dir = tmp_path / "documentation"
        docs_dir.mkdir()

        # Create a markdown file that references the test file
        md_file = tmp_path / "test.md"
        md_file.write_text("# Test\n\nSee [file](file1.txt) for details.")

        # Initialize components
        link_db = LinkDatabase()
        parser = LinkParser()
        updater = LinkUpdater(str(tmp_path))
        handler = LinkMaintenanceHandler(link_db, parser, updater, str(tmp_path))

        # Scan initial files
        for file_path in tmp_path.rglob("*"):
            if file_path.is_file() and file_path.suffix in {".md", ".txt"}:
                rel_path = str(file_path.relative_to(tmp_path)).replace("\\", "/")
                references = parser.parse_file(str(file_path))
                for ref in references:
                    ref.file_path = rel_path
                    link_db.add_link(ref)

        return {
            "tmp_path": tmp_path,
            "test_file": test_file,
            "docs_dir": docs_dir,
            "md_file": md_file,
            "link_db": link_db,
            "parser": parser,
            "updater": updater,
            "handler": handler,
        }

    def test_initial_references_found(self, project_setup):
        """Verify that the initial scan finds the expected references."""
        link_db = project_setup["link_db"]
        refs = link_db.get_references_to_file("file1.txt")
        assert len(refs) >= 1, f"Expected at least 1 reference to file1.txt, got {len(refs)}"

    def test_move_detection_identifies_paired_delete_create(self, project_setup):
        """Test that MoveDetector correctly pairs a delete with a create."""
        handler = project_setup["handler"]
        docs_dir = project_setup["docs_dir"]

        created_path = "documentation/file1.txt"
        created_abs_path = str(docs_dir / "file1.txt")

        # Buffer a delete event via MoveDetector (file still exists at original path)
        handler._move_detector.buffer_delete("file1.txt", str(project_setup["test_file"]))

        # Create the file at the new location
        new_file = docs_dir / "file1.txt"
        new_file.write_text("Test content")

        # Test move detection
        detected_source = handler._move_detector.match_created_file(created_path, created_abs_path)

        assert detected_source is not None, "Move detection should have found a matching delete"
        assert (
            detected_source == "file1.txt"
        ), f"Expected source 'file1.txt', got '{detected_source}'"

    def test_handle_detected_move_updates_references(self, project_setup):
        """Test that _handle_detected_move correctly updates file references."""
        handler = project_setup["handler"]
        docs_dir = project_setup["docs_dir"]
        md_file = project_setup["md_file"]
        link_db = project_setup["link_db"]

        created_path = "documentation/file1.txt"
        created_abs_path = str(docs_dir / "file1.txt")

        # Buffer a delete event via MoveDetector
        handler._move_detector.buffer_delete("file1.txt", str(project_setup["test_file"]))

        # Create the file at the new location
        new_file = docs_dir / "file1.txt"
        new_file.write_text("Test content")

        # Detect the move
        detected_source = handler._move_detector.match_created_file(created_path, created_abs_path)
        assert detected_source is not None, "Move should have been detected"

        # Handle the detected move
        handler._handle_detected_move(detected_source, created_path)

        # Check if reference was updated in the markdown file
        updated_content = md_file.read_text()
        assert "documentation/file1.txt" in updated_content, (
            f"Reference should be updated to 'documentation/file1.txt', "
            f"but content is: {updated_content}"
        )

    def test_get_old_path_variations_same_depth(self, project_setup):
        """Regression test for PD-BUG-024: verify old path variations for same-depth moves."""
        handler = project_setup["handler"]
        variations = handler._ref_lookup.get_old_path_variations("docs/guides/file.md")
        assert "docs/guides/file.md" in variations, "Should include exact path"
        assert "guides/file.md" in variations, "Should include relative (first dir stripped)"
        assert "guides\\file.md" in variations, "Should include backslash variant"
        assert "file.md" in variations, "Should include filename-only"

    def test_get_old_path_variations_shallow_path(self, project_setup):
        """Regression test for PD-BUG-024: shallow paths should not generate relative variant."""
        handler = project_setup["handler"]
        variations = handler._ref_lookup.get_old_path_variations("docs/file.md")
        assert "docs/file.md" in variations, "Should include exact path"
        assert "file.md" in variations, "Should include filename-only"
        # Only 2 parts — relative variant should NOT be generated
        assert (
            len(variations) == 2
        ), f"Expected 2 variations for shallow path, got {len(variations)}"

    def test_get_old_path_variations_filename_only(self, project_setup):
        """Regression test for PD-BUG-024: filename-only path produces minimal variations."""
        handler = project_setup["handler"]
        variations = handler._ref_lookup.get_old_path_variations("file.md")
        assert "file.md" in variations, "Should include exact/filename path"
        # Single segment — only exact + basename (which are the same)
        assert len(variations) <= 2, f"Expected at most 2 variations, got {len(variations)}"

    def test_no_false_positive_without_pending_delete(self, project_setup):
        """Test that move detection does not fire without a matching pending delete."""
        handler = project_setup["handler"]
        docs_dir = project_setup["docs_dir"]

        created_path = "documentation/file1.txt"
        created_abs_path = str(docs_dir / "file1.txt")

        # Do NOT buffer any deletes

        # Create the file
        new_file = docs_dir / "file1.txt"
        new_file.write_text("Test content")

        # Move detection should return None
        detected_source = handler._move_detector.match_created_file(created_path, created_abs_path)
        assert detected_source is None, "Should not detect a move without a matching delete"


class TestStatsThreadSafety:
    """Regression tests for PD-BUG-026: stats dict thread safety."""

    @pytest.fixture
    def handler(self, tmp_path):
        """Create a minimal handler for stats testing."""
        link_db = LinkDatabase()
        parser = LinkParser()
        updater = LinkUpdater(str(tmp_path))
        return LinkMaintenanceHandler(link_db, parser, updater, str(tmp_path))

    def test_stats_lock_exists(self, handler):
        """PD-BUG-026: Handler must have a lock protecting stats access."""
        assert hasattr(handler, "_stats_lock"), (
            "Handler must have a _stats_lock attribute for thread-safe stats access. "
            "Without this lock, self.stats[key] += value is not safe across threads."
        )
        assert isinstance(
            handler._stats_lock, type(threading.Lock())
        ), "_stats_lock must be a threading.Lock instance"

    def test_update_stat_method_exists(self, handler):
        """PD-BUG-026: Handler must expose a thread-safe stats update method."""
        assert hasattr(
            handler, "_update_stat"
        ), "Handler must have a _update_stat method for thread-safe stat increments"
        # Verify it actually updates the stat
        handler._update_stat("errors", 5)
        assert handler.stats["errors"] == 5

    def test_concurrent_stats_increments_accurate(self, handler):
        """PD-BUG-026: Stats must be accurate under concurrent access.

        Spawns multiple threads each incrementing a stat counter many times.
        The final count must equal the exact expected total — no lost increments.
        """
        num_threads = 10
        increments_per_thread = 1000
        expected_total = num_threads * increments_per_thread
        barrier = threading.Barrier(num_threads)

        def increment_stats():
            barrier.wait()  # Synchronize thread start for max contention
            for _ in range(increments_per_thread):
                handler._update_stat("errors", 1)

        threads = [threading.Thread(target=increment_stats) for _ in range(num_threads)]
        for t in threads:
            t.start()
        for t in threads:
            t.join()

        actual = handler.stats["errors"]
        assert actual == expected_total, (
            f"Expected exactly {expected_total} errors after concurrent increments, "
            f"got {actual}. Lost {expected_total - actual} increments — "
            f"stats are NOT thread-safe."
        )
        # Negative assertion: count must not fall short
        assert actual >= expected_total, (
            f"Stats count {actual} is less than expected {expected_total} — "
            f"thread-safety violation detected"
        )

    def test_get_stats_returns_snapshot(self, handler):
        """PD-BUG-026: get_stats() must return a safe copy under concurrency."""
        handler._update_stat("files_moved", 42)
        snapshot = handler.get_stats()
        # Mutating snapshot must not affect handler's internal stats
        snapshot["files_moved"] = 999
        assert (
            handler.stats["files_moved"] == 42
        ), "get_stats() must return a copy, not a reference to internal stats"

    def test_reset_stats_clears_all_counters(self, handler):
        """PD-BUG-026: reset_stats() must safely clear all counters."""
        handler._update_stat("files_moved", 10)
        handler._update_stat("errors", 5)
        handler.reset_stats()
        for key, value in handler.stats.items():
            assert value == 0, f"Expected {key} to be 0 after reset, got {value}"
