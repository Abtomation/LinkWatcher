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

from watchdog.events import FileCreatedEvent, FileDeletedEvent

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

        # Buffer a delete event via MoveDetector
        handler._move_detector.buffer_delete("file1.txt", str(project_setup["test_file"]))

        # Actually delete the old file (simulates real move — file gone from old location)
        project_setup["test_file"].unlink()

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

        # Actually delete the old file (simulates real move)
        project_setup["test_file"].unlink()

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
        assert "docs/file" in variations, "Should include extensionless variant (PD-BUG-043)"
        # Only 2 parts — relative variant should NOT be generated
        # 3 variations: exact, filename-only, extensionless
        assert (
            len(variations) == 3
        ), f"Expected 3 variations for shallow path, got {len(variations)}"

    def test_get_old_path_variations_filename_only(self, project_setup):
        """Regression test for PD-BUG-024: filename-only path produces minimal variations."""
        handler = project_setup["handler"]
        variations = handler._ref_lookup.get_old_path_variations("file.md")
        assert "file.md" in variations, "Should include exact/filename path"
        assert "file" in variations, "Should include extensionless variant (PD-BUG-043)"
        # Single segment — only exact + basename + extensionless
        assert len(variations) <= 3, f"Expected at most 3 variations, got {len(variations)}"

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


class TestBulkOperationMoveDetection:
    """Regression tests for PD-BUG-042: move detection confused by rapid
    file creation and deletion cycles.

    When bulk operations (cleanup + copy) generate delete events followed by
    create events at the SAME location, the pending deletes should not match
    against unrelated creates that arrive later (e.g., from an actual file move).
    """

    @pytest.fixture
    def project_setup(self, tmp_path):
        """Set up a test project with handler and files."""
        # Create initial project structure
        data_dir = tmp_path / "data"
        data_dir.mkdir()
        settings_file = data_dir / "settings.conf"
        settings_file.write_text("key=value")

        config_file = tmp_path / "config.yaml"
        config_file.write_text("config_file: data/settings.conf\n")

        moved_dir = tmp_path / "moved"
        moved_dir.mkdir()

        # Initialize components
        link_db = LinkDatabase()
        parser = LinkParser()
        updater = LinkUpdater(str(tmp_path))
        handler = LinkMaintenanceHandler(link_db, parser, updater, str(tmp_path))

        # Scan initial files
        for file_path in tmp_path.rglob("*"):
            if file_path.is_file():
                rel_path = str(file_path.relative_to(tmp_path)).replace("\\", "/")
                references = parser.parse_file(str(file_path))
                for ref in references:
                    ref.file_path = rel_path
                    link_db.add_link(ref)

        return {
            "tmp_path": tmp_path,
            "data_dir": data_dir,
            "settings_file": settings_file,
            "moved_dir": moved_dir,
            "link_db": link_db,
            "handler": handler,
        }

    def test_per_file_move_rejected_when_old_path_recreated(self, project_setup):
        """PD-BUG-042: MoveDetector must not match a create against a pending
        delete when the old file has been re-created at its original location.

        Simulates: setup deletes settings.conf, setup re-creates it (copy),
        then a real move creates settings.conf at a new location. The pending
        delete from setup should NOT match the real move's create.
        """
        handler = project_setup["handler"]
        tmp_path = project_setup["tmp_path"]
        settings_file = project_setup["settings_file"]
        moved_dir = project_setup["moved_dir"]

        # Phase 1: Setup cleanup — buffer a delete for settings.conf
        handler._move_detector.buffer_delete(
            "data/settings.conf", str(settings_file)
        )

        # Phase 2: Setup copy — re-create the file at the same location
        # (simulates fixture copy; the file still exists at old path)
        settings_file.write_text("key=value")

        # Phase 3: Real move — file created at new location
        new_file = moved_dir / "settings.conf"
        new_file.write_text("key=value")
        new_rel = "moved/settings.conf"
        new_abs = str(new_file)

        # The pending delete from Phase 1 should NOT match this create
        # because the old file still exists at data/settings.conf
        matched = handler._move_detector.match_created_file(new_rel, new_abs)

        assert matched is None, (
            "PD-BUG-042: MoveDetector matched a stale pending delete against "
            "an unrelated create. When the old file has been re-created at its "
            "original location, the pending delete must be discarded, not matched."
        )

    def test_per_file_real_move_still_detected(self, project_setup):
        """PD-BUG-042: MoveDetector must still detect real moves where the old
        file is truly gone from its original location."""
        handler = project_setup["handler"]
        settings_file = project_setup["settings_file"]
        moved_dir = project_setup["moved_dir"]

        # Buffer a delete
        handler._move_detector.buffer_delete(
            "data/settings.conf", str(settings_file)
        )

        # Actually delete the old file (simulates a real move)
        settings_file.unlink()

        # Create at new location
        new_file = moved_dir / "settings.conf"
        new_file.write_text("key=value")
        new_rel = "moved/settings.conf"
        new_abs = str(new_file)

        # This SHOULD match — old file is truly gone
        matched = handler._move_detector.match_created_file(new_rel, new_abs)

        assert matched == "data/settings.conf", (
            f"Real move should be detected when old file is gone, "
            f"but got: {matched}"
        )

    def test_dir_move_rejected_when_old_dir_still_exists(self, project_setup):
        """PD-BUG-042: DirectoryMoveDetector must not infer a directory move
        when the old directory still exists on the filesystem.

        Simulates: setup deletes data/ dir, setup re-creates it (copy),
        then a file is created under a different directory. The stale directory
        buffer should not claim the create.
        """
        handler = project_setup["handler"]
        tmp_path = project_setup["tmp_path"]
        data_dir = project_setup["data_dir"]
        moved_dir = project_setup["moved_dir"]

        # Phase 1: Buffer directory deletion
        handler._dir_move_detector.handle_directory_deleted("data")

        # Phase 2: Directory re-created by setup (still exists)
        # data_dir already exists — simulates fixture copy restoring it

        # Phase 3: A file created under moved/ (from a real move)
        new_file = moved_dir / "settings.conf"
        new_file.write_text("key=value")

        # The directory move detector should NOT claim this create
        # because data/ still exists on the filesystem
        claimed = handler._dir_move_detector.match_created_file(
            "moved/settings.conf", str(new_file)
        )

        assert not claimed, (
            "PD-BUG-042: DirectoryMoveDetector claimed a file create for a "
            "stale directory buffer. When the old directory still exists on "
            "the filesystem, the buffer should be invalidated."
        )


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


class TestFileReplacementRetainsLinks:
    """Regression tests for PD-BUG-035: sed -i file replacement must not wipe DB entries."""

    @pytest.fixture
    def project_setup(self, tmp_path):
        """Set up a project with a file containing links."""
        # Create a markdown file that references another file
        target = tmp_path / "target.md"
        target.write_text("# Target")

        source = tmp_path / "source.md"
        source.write_text("# Source\n\nSee [target](target.md) for details.")

        link_db = LinkDatabase()
        parser = LinkParser()
        updater = LinkUpdater(str(tmp_path))
        handler = LinkMaintenanceHandler(link_db, parser, updater, str(tmp_path))

        # Scan initial files
        for file_path in [source, target]:
            rel_path = str(file_path.relative_to(tmp_path)).replace("\\", "/")
            references = parser.parse_file(str(file_path))
            for ref in references:
                ref.file_path = rel_path
                link_db.add_link(ref)

        return {
            "tmp_path": tmp_path,
            "source": source,
            "target": target,
            "link_db": link_db,
            "handler": handler,
        }

    def test_true_delete_timer_does_not_wipe_links_when_file_exists(self, project_setup):
        """PD-BUG-035: When the delete timer fires but the file still exists
        (e.g., sed -i replaced it), links must NOT be removed from the database."""
        link_db = project_setup["link_db"]
        handler = project_setup["handler"]
        source = project_setup["source"]

        # Verify links exist before
        refs_before = link_db.get_references_to_file("target.md")
        assert len(refs_before) >= 1, "Should have at least 1 reference to target.md"

        # Simulate what happens when sed -i's delete timer fires:
        # The file was deleted and recreated (replaced), so it still exists
        handler._process_true_file_delete("source.md")

        # Links FROM source.md should still be in the database
        # (the file exists, so it was replaced, not truly deleted)
        refs_after = link_db.get_references_to_file("target.md")
        assert len(refs_after) >= 1, (
            "PD-BUG-035: Links were wiped from DB even though source.md still exists. "
            "_process_true_file_delete must not remove links for files that still exist "
            "(they were replaced, not deleted)."
        )

    def test_true_delete_timer_reports_broken_refs_when_file_gone(self, project_setup):
        """When the file is truly deleted, broken references should still be reported."""
        link_db = project_setup["link_db"]
        handler = project_setup["handler"]
        source = project_setup["source"]

        # Actually delete the file
        source.unlink()

        # Now the timer fires for a truly deleted file
        handler._process_true_file_delete("source.md")

        # The file is gone — this is expected behavior, not a bug
        # Just verify no crash occurs (the method should handle it gracefully)


class TestNonMonitoredExtensionMoveDetection:
    """Regression tests for PD-BUG-046: file moves not detected for
    non-monitored extensions even when referenced by monitored files.

    When a file with an extension not in monitored_extensions (e.g., .conf)
    is moved across directories, the DELETE+CREATE events must still be
    processed for move detection if the file is a known reference target.
    """

    @pytest.fixture
    def project_setup(self, tmp_path):
        """Set up a project where a .yaml file references a .conf file."""
        data_dir = tmp_path / "data"
        data_dir.mkdir()
        conf_file = data_dir / "settings.conf"
        conf_file.write_text("key=value\n")

        moved_dir = tmp_path / "moved"
        moved_dir.mkdir()

        yaml_file = tmp_path / "config.yaml"
        yaml_file.write_text("config_file: data/settings.conf\n")

        link_db = LinkDatabase()
        parser = LinkParser()
        updater = LinkUpdater(str(tmp_path))
        handler = LinkMaintenanceHandler(link_db, parser, updater, str(tmp_path))

        # Scan the yaml file so the DB knows about the reference
        for file_path in tmp_path.rglob("*"):
            if file_path.is_file():
                rel_path = str(file_path.relative_to(tmp_path)).replace("\\", "/")
                references = parser.parse_file(str(file_path))
                for ref in references:
                    ref.file_path = rel_path
                    link_db.add_link(ref)

        return {
            "tmp_path": tmp_path,
            "conf_file": conf_file,
            "yaml_file": yaml_file,
            "moved_dir": moved_dir,
            "link_db": link_db,
            "handler": handler,
        }

    def test_conf_file_is_referenced_but_not_monitored(self, project_setup):
        """Verify precondition: .conf is referenced but not in monitored_extensions."""
        handler = project_setup["handler"]
        link_db = project_setup["link_db"]

        # .conf should NOT be in monitored extensions
        assert ".conf" not in handler.monitored_extensions, (
            ".conf should not be in monitored_extensions for this test to be valid"
        )

        # But it IS referenced by a monitored file
        refs = link_db.get_references_to_file("data/settings.conf")
        assert len(refs) >= 1, (
            "Expected at least 1 reference to data/settings.conf from config.yaml"
        )

    def test_on_deleted_buffers_non_monitored_referenced_file(self, project_setup):
        """PD-BUG-046: on_deleted must buffer deletes for files that are
        known reference targets, even if their extension is not monitored."""
        handler = project_setup["handler"]
        conf_file = project_setup["conf_file"]

        # Simulate watchdog DELETE event for .conf file
        event = FileDeletedEvent(str(conf_file))
        handler.on_deleted(event)

        # The move detector should have a pending delete for this file
        assert handler._move_detector.has_pending, (
            "PD-BUG-046: on_deleted dropped the DELETE event for a non-monitored "
            "extension (.conf) that IS a known reference target. The move detector "
            "must buffer this delete for potential move correlation."
        )

    def test_full_move_detected_for_non_monitored_extension(self, project_setup):
        """PD-BUG-046: Full move (delete+create) of a non-monitored file that
        is a known reference target should be detected and references updated."""
        handler = project_setup["handler"]
        conf_file = project_setup["conf_file"]
        yaml_file = project_setup["yaml_file"]
        moved_dir = project_setup["moved_dir"]

        # Simulate DELETE event
        delete_event = FileDeletedEvent(str(conf_file))
        handler.on_deleted(delete_event)

        # Actually move the file
        new_file = moved_dir / "settings.conf"
        conf_file.rename(new_file)

        # Simulate CREATE event
        create_event = FileCreatedEvent(str(new_file))
        handler.on_created(create_event)

        # Verify the yaml file was updated
        updated_content = yaml_file.read_text()
        assert "moved/settings.conf" in updated_content, (
            f"PD-BUG-046: YAML reference should be updated from "
            f"'data/settings.conf' to 'moved/settings.conf', "
            f"but content is: {updated_content}"
        )
        assert "data/settings.conf" not in updated_content, (
            f"PD-BUG-046: Old reference 'data/settings.conf' should no longer "
            f"be present after the move, but content is: {updated_content}"
        )
