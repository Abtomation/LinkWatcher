"""
Test suite to verify the enhanced move detection logic.

Tests the internal _detect_potential_move and _handle_detected_move methods
of the LinkMaintenanceHandler to ensure move operations are correctly
detected from paired delete+create events and that references are updated.
"""

import threading

import pytest
from watchdog.events import (
    DirMovedEvent,
    FileCreatedEvent,
    FileDeletedEvent,
    FileModifiedEvent,
    FileMovedEvent,
)

from linkwatcher.config.settings import LinkWatcherConfig
from linkwatcher.database import LinkDatabase
from linkwatcher.handler import LinkMaintenanceHandler
from linkwatcher.parser import LinkParser
from linkwatcher.updater import LinkUpdater

pytestmark = [
    pytest.mark.feature("1.1.1"),
    pytest.mark.priority("Standard"),
    pytest.mark.cross_cutting(["2.2.1", "0.1.2"]),
    pytest.mark.test_type("integration"),
    pytest.mark.specification(
        "test/specifications/feature-specs/test-spec-1-1-1-file-system-monitoring.md"
    ),
]


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
        project_setup["link_db"]

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
        project_setup["tmp_path"]
        settings_file = project_setup["settings_file"]
        moved_dir = project_setup["moved_dir"]

        # Phase 1: Setup cleanup — buffer a delete for settings.conf
        handler._move_detector.buffer_delete("data/settings.conf", str(settings_file))

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
        handler._move_detector.buffer_delete("data/settings.conf", str(settings_file))

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
            f"Real move should be detected when old file is gone, " f"but got: {matched}"
        )

    def test_dir_move_rejected_when_old_dir_still_exists(self, project_setup):
        """PD-BUG-042: DirectoryMoveDetector must not infer a directory move
        when the old directory still exists on the filesystem.

        Simulates: setup deletes data/ dir, setup re-creates it (copy),
        then a file is created under a different directory. The stale directory
        buffer should not claim the create.
        """
        handler = project_setup["handler"]
        project_setup["tmp_path"]
        project_setup["data_dir"]
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
        project_setup["source"]

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

        # Verify links exist before deletion
        refs_before = link_db.get_references_to_file("target.md")
        assert len(refs_before) >= 1, "Precondition: should have at least 1 reference to target.md"

        # Actually delete the file
        source.unlink()

        # Now the timer fires for a truly deleted file
        handler._process_true_file_delete("source.md")

        # files_deleted stat should be incremented
        assert (
            handler.stats["files_deleted"] == 1
        ), "Expected files_deleted stat to be 1 after processing a true deletion"

        # Links should still be in the database (stale entries are kept
        # intentionally per PD-BUG-035 — they self-heal on restart)
        refs_after = link_db.get_references_to_file("target.md")
        assert len(refs_after) == len(refs_before), (
            "Links should be retained in DB after true deletion "
            "(stale entries self-heal on restart)"
        )


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
        assert (
            ".conf" not in handler.monitored_extensions
        ), ".conf should not be in monitored_extensions for this test to be valid"

        # But it IS referenced by a monitored file
        refs = link_db.get_references_to_file("data/settings.conf")
        assert (
            len(refs) >= 1
        ), "Expected at least 1 reference to data/settings.conf from config.yaml"

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


class TestIgnoredDirectoryEventBoundary:
    """Regression tests for PD-BUG-105: ignored_directories must be a hard
    boundary for live events.

    The known-reference-target bypass (PD-BUG-046) and the directory-move
    paths (PD-BUG-071) skip _should_monitor_file(), which is the only place
    ignored_directories is enforced for events. When a monitored file
    OUTSIDE an ignored tree references a path INSIDE it (e.g. audit reports
    quoting E2E workspace paths), events from the ignored tree re-enter the
    pipeline and the daemon parses and WRITES inside the ignored tree —
    racing the scoped per-test daemons that own those files.
    """

    @pytest.fixture
    def project_setup(self, tmp_path):
        """A report outside the ignored zone references a file inside it."""
        zone = tmp_path / "ignored-zone" / "sub"
        zone.mkdir(parents=True)
        inside_target = zone / "target.md"
        inside_target.write_text("# Target\n")
        inside_ref = zone / "readme.md"
        inside_ref.write_text("# Readme\n\n[Target](target.md)\n")

        report = tmp_path / "audits" / "report.md"
        report.parent.mkdir()
        report.write_text("# Report\n\nSee `ignored-zone/sub/target.md` for details.\n")

        ignored_dirs = {"ignored-zone", ".git"}
        link_db = LinkDatabase()
        parser = LinkParser()
        updater = LinkUpdater(str(tmp_path))
        handler = LinkMaintenanceHandler(
            link_db,
            parser,
            updater,
            str(tmp_path),
            ignored_directories=ignored_dirs,
        )

        # Mirror the initial scan: only files OUTSIDE ignored dirs are indexed,
        # so the DB knows the report's reference into the ignored zone but has
        # no entries for files inside it.
        for file_path in tmp_path.rglob("*.md"):
            rel_parts = file_path.relative_to(tmp_path).parts
            if any(part in ignored_dirs for part in rel_parts):
                continue
            rel_path = str(file_path.relative_to(tmp_path)).replace("\\", "/")
            references = parser.parse_file(str(file_path))
            for ref in references:
                ref.file_path = rel_path
                link_db.add_link(ref)

        return {
            "tmp_path": tmp_path,
            "zone": zone,
            "inside_target": inside_target,
            "inside_ref": inside_ref,
            "report": report,
            "link_db": link_db,
            "handler": handler,
        }

    def test_inside_file_is_a_known_reference_target(self, project_setup):
        """Precondition: the report's link makes the inside file a known
        reference target — the exact condition that re-armed PD-BUG-105."""
        handler = project_setup["handler"]
        inside_target = project_setup["inside_target"]
        assert handler._is_known_reference_target(str(inside_target)), (
            "Precondition failed: the file inside the ignored zone must be a "
            "known reference target (referenced by audits/report.md) for these "
            "regression tests to exercise the PD-BUG-046 bypass"
        )

    def test_on_deleted_drops_event_inside_ignored_dir(self, project_setup):
        """PD-BUG-105: a delete inside an ignored dir must NOT be buffered,
        even when the file is a known reference target."""
        handler = project_setup["handler"]
        inside_target = project_setup["inside_target"]

        handler.on_deleted(FileDeletedEvent(str(inside_target)))

        assert not handler._move_detector.has_pending, (
            "PD-BUG-105: on_deleted buffered a DELETE from inside an ignored "
            "directory because the file is a known reference target — "
            "ignored_directories must override the PD-BUG-046 bypass"
        )

    def test_move_inside_ignored_dir_rewrites_nothing(self, project_setup):
        """PD-BUG-105: a delete+create move inside an ignored dir must not
        update any references — neither outside nor inside the zone."""
        handler = project_setup["handler"]
        zone = project_setup["zone"]
        inside_target = project_setup["inside_target"]
        inside_ref = project_setup["inside_ref"]
        report = project_setup["report"]

        report_before = report.read_text()
        inside_ref_before = inside_ref.read_text()

        handler.on_deleted(FileDeletedEvent(str(inside_target)))
        archive = zone / "archive"
        archive.mkdir()
        new_path = archive / "target.md"
        inside_target.rename(new_path)
        handler.on_created(FileCreatedEvent(str(new_path)))

        assert report.read_text() == report_before, (
            "PD-BUG-105: the daemon rewrote a reference in audits/report.md "
            "for a move that happened inside an ignored directory"
        )
        assert inside_ref.read_text() == inside_ref_before, (
            "PD-BUG-105: the daemon WROTE inside the ignored directory "
            "(rewrote readme.md) — exactly the dry-run-override failure "
            "observed in TE-E2E-019"
        )
        assert (
            "archive/target.md" not in report.read_text()
        ), "PD-BUG-105: new path must not appear in the outside report"

    def test_on_created_inside_ignored_dir_not_indexed(self, project_setup):
        """PD-BUG-105: a create inside an ignored dir must not be parsed into
        the database, even while the move detector has pending deletes."""
        handler = project_setup["handler"]
        link_db = project_setup["link_db"]
        tmp_path = project_setup["tmp_path"]
        zone = project_setup["zone"]

        # Arm the on_created bypass: a legit pending delete OUTSIDE the zone.
        outside = tmp_path / "audits" / "floating.md"
        outside.write_text("# Floating\n")
        handler.on_deleted(FileDeletedEvent(str(outside)))
        assert handler._move_detector.has_pending

        new_inside = zone / "new-doc.md"
        new_inside.write_text("# New\n\n[Target](target.md)\n")
        handler.on_created(FileCreatedEvent(str(new_inside)))

        rel = "ignored-zone/sub/new-doc.md"
        assert rel not in link_db.get_source_files(), (
            "PD-BUG-105: a file created inside an ignored directory was "
            "parsed and indexed into the database"
        )

    def test_native_directory_move_inside_ignored_dir_dropped(self, project_setup):
        """PD-BUG-105: a native directory move inside an ignored dir must be
        dropped — _handle_directory_moved (PD-BUG-071) bypasses ignore checks
        by design, so the guard must fire before it."""
        handler = project_setup["handler"]
        zone = project_setup["zone"]
        report = project_setup["report"]

        report_before = report.read_text()
        renamed = zone.parent / "sub-renamed"
        zone.rename(renamed)
        handler.on_moved(DirMovedEvent(str(zone), str(renamed)))

        assert report.read_text() == report_before, (
            "PD-BUG-105: a directory rename inside an ignored directory "
            "triggered reference updates in an outside file"
        )

    def test_native_file_move_out_of_ignored_dir_indexes_dest(self, project_setup):
        """PD-BUG-108: a native file move OUT of an ignored tree into a
        monitored location must index the destination like a creation.
        The DB has never seen the file (ignored events are dropped), so
        dropping the move leaves its links invisible until a later modify
        event or restart."""
        handler = project_setup["handler"]
        link_db = project_setup["link_db"]
        tmp_path = project_setup["tmp_path"]
        inside_ref = project_setup["inside_ref"]
        report = project_setup["report"]

        report_before = report.read_text()
        dest = tmp_path / "audits" / "readme.md"
        inside_ref.rename(dest)
        handler.on_moved(FileMovedEvent(str(inside_ref), str(dest)))

        assert "audits/readme.md" in link_db.get_source_files(), (
            "PD-BUG-108: a file natively moved out of an ignored directory "
            "into a monitored location was not indexed — its links stay "
            "invisible to the link database"
        )
        assert report.read_text() == report_before, (
            "PD-BUG-108: move-out must be create-like indexing only — "
            "references in outside files pointing into the ignored tree "
            "must not be rewritten (PD-BUG-105 boundary)"
        )

    def test_native_file_move_out_non_monitored_extension_not_indexed(self, project_setup):
        """PD-BUG-108: create-like indexing applies the normal monitoring
        filter — a non-monitored file emerging from an ignored tree is not
        parsed into the database."""
        handler = project_setup["handler"]
        link_db = project_setup["link_db"]
        tmp_path = project_setup["tmp_path"]
        zone = project_setup["zone"]

        unmonitored = zone / "notes.xyz"
        unmonitored.write_text("see target.md\n")
        dest = tmp_path / "audits" / "notes.xyz"
        unmonitored.rename(dest)
        handler.on_moved(FileMovedEvent(str(unmonitored), str(dest)))

        assert "audits/notes.xyz" not in link_db.get_source_files(), (
            "PD-BUG-108: a non-monitored file moved out of an ignored "
            "directory was parsed and indexed into the database"
        )

    def test_native_file_move_between_ignored_dirs_still_dropped(self, project_setup):
        """PD-BUG-108: a native move whose destination is ALSO inside an
        ignored tree stays fully dropped — the hard boundary (PD-BUG-105)
        is unchanged when the file never enters monitored space."""
        handler = project_setup["handler"]
        link_db = project_setup["link_db"]
        zone = project_setup["zone"]
        inside_ref = project_setup["inside_ref"]
        report = project_setup["report"]

        report_before = report.read_text()
        dest = zone.parent / "readme.md"  # still under ignored-zone/
        inside_ref.rename(dest)
        handler.on_moved(FileMovedEvent(str(inside_ref), str(dest)))

        assert "ignored-zone/readme.md" not in link_db.get_source_files(), (
            "PD-BUG-108: a move between two locations inside the ignored "
            "tree must not index anything"
        )
        assert report.read_text() == report_before, (
            "PD-BUG-108: a move within the ignored tree must not rewrite " "outside references"
        )

    def test_native_directory_move_out_of_ignored_dir_indexes_contents(self, project_setup):
        """PD-BUG-108: a native DIRECTORY move out of an ignored tree has
        the same root cause one line away — the whole subtree emerges into
        monitored space and its monitored files must be indexed."""
        handler = project_setup["handler"]
        link_db = project_setup["link_db"]
        tmp_path = project_setup["tmp_path"]
        zone = project_setup["zone"]
        report = project_setup["report"]

        report_before = report.read_text()
        dest = tmp_path / "sub-moved"
        zone.rename(dest)
        handler.on_moved(DirMovedEvent(str(zone), str(dest)))

        assert "sub-moved/readme.md" in link_db.get_source_files(), (
            "PD-BUG-108: a monitored file inside a directory natively moved "
            "out of an ignored tree was not indexed"
        )
        assert report.read_text() == report_before, (
            "PD-BUG-108: directory move-out must be create-like indexing "
            "only — outside references must not be rewritten"
        )


class TestModifyEventRescan:
    """Regression tests for PD-BUG-102: links written into an EXISTING
    monitored file by an external tool were never indexed, because the
    handler had no on_modified hook. The database only learned links at
    startup scan, on_created, or LinkWatcher's own rewrites — so a later
    move of the fresh link's target ran with references_count=0
    (no_references_found) and left the link pointing at the old path.
    """

    @pytest.fixture
    def project_setup(self, tmp_path):
        """A target file plus a tracking file that does NOT reference it
        yet at initial-scan time — the link arrives via external edit."""
        notes_dir = tmp_path / "notes"
        notes_dir.mkdir()
        target = notes_dir / "target.md"
        target.write_text("# Target\n")

        tracking = tmp_path / "tracking.md"
        tracking.write_text("# Tracking\n\nNo links yet.\n")

        zone = tmp_path / "ignored-zone"
        zone.mkdir()

        ignored_dirs = {"ignored-zone", ".git"}
        link_db = LinkDatabase()
        parser = LinkParser()
        updater = LinkUpdater(str(tmp_path))
        handler = LinkMaintenanceHandler(
            link_db,
            parser,
            updater,
            str(tmp_path),
            ignored_directories=ignored_dirs,
        )

        # Mirror the initial scan (tracking.md has no links at this point)
        for file_path in tmp_path.rglob("*.md"):
            rel_parts = file_path.relative_to(tmp_path).parts
            if any(part in ignored_dirs for part in rel_parts):
                continue
            rel_path = str(file_path.relative_to(tmp_path)).replace("\\", "/")
            references = parser.parse_file(str(file_path))
            for ref in references:
                ref.file_path = rel_path
                link_db.add_link(ref)

        return {
            "tmp_path": tmp_path,
            "notes_dir": notes_dir,
            "target": target,
            "tracking": tracking,
            "zone": zone,
            "link_db": link_db,
            "handler": handler,
        }

    def _append_link(self, tracking, link_target="notes/target.md"):
        """Simulate an external tool writing a new link into the file."""
        tracking.write_text(tracking.read_text() + f"\nSee [Target]({link_target}).\n")

    def test_modify_event_indexes_new_link(self, project_setup):
        """PD-BUG-102 core: an externally written link must enter the
        database when the modify event for the edited file arrives."""
        handler = project_setup["handler"]
        tracking = project_setup["tracking"]
        link_db = project_setup["link_db"]

        self._append_link(tracking)
        handler.on_modified(FileModifiedEvent(str(tracking)))

        refs = link_db.get_references_to_file("notes/target.md")
        assert refs, (
            "PD-BUG-102: a link freshly written into an existing monitored "
            "file was not indexed on the modify event — a later move of "
            "notes/target.md would find no references"
        )

    def test_move_after_external_edit_rewrites_fresh_link(self, project_setup):
        """PD-BUG-102 full scenario (matches the 2026-06-10 log evidence):
        external edit adds a link, then the target moves via delete+create
        correlation — the fresh link must be rewritten to the new path."""
        handler = project_setup["handler"]
        tracking = project_setup["tracking"]
        tmp_path = project_setup["tmp_path"]
        target = project_setup["target"]

        self._append_link(tracking)
        handler.on_modified(FileModifiedEvent(str(tracking)))

        # Move the target: delete event, physical move, create event
        moved_dir = tmp_path / "archive"
        moved_dir.mkdir()
        new_path = moved_dir / "target.md"
        handler.on_deleted(FileDeletedEvent(str(target)))
        target.rename(new_path)
        handler.on_created(FileCreatedEvent(str(new_path)))

        content = tracking.read_text()
        assert "archive/target.md" in content, (
            "PD-BUG-102: the freshly written link was not rewritten when "
            f"its target moved — content: {content}"
        )
        assert "notes/target.md" not in content, (
            "PD-BUG-102: the old path must NOT remain in the tracking file "
            f"after the move — content: {content}"
        )

    def test_modify_event_drops_stale_entries(self, project_setup):
        """A rewrite that REMOVES a link must also drop its DB entry —
        the rescan must replace, not accumulate."""
        handler = project_setup["handler"]
        tracking = project_setup["tracking"]
        link_db = project_setup["link_db"]

        self._append_link(tracking)
        handler.on_modified(FileModifiedEvent(str(tracking)))
        assert link_db.get_references_to_file("notes/target.md")

        # External rewrite replaces the link with a different target
        tracking.write_text("# Tracking\n\nSee [Other](notes/other.md).\n")
        handler.on_modified(FileModifiedEvent(str(tracking)))

        stale = [
            r
            for r in link_db.get_references_to_file("notes/target.md")
            if r.file_path == "tracking.md"
        ]
        assert not stale, (
            "PD-BUG-102: stale link entry survived a modify-event rescan "
            "after the link was removed from the file"
        )
        assert link_db.get_references_to_file(
            "notes/other.md"
        ), "PD-BUG-102: replacement link was not indexed by the rescan"

    def test_modify_inside_ignored_dir_not_indexed(self, project_setup):
        """PD-BUG-105 boundary applies to modify events too: edits inside
        an ignored directory must not be parsed into the database."""
        handler = project_setup["handler"]
        zone = project_setup["zone"]
        link_db = project_setup["link_db"]

        inside = zone / "inside.md"
        inside.write_text("# Inside\n\n[Target](../notes/target.md)\n")
        handler.on_modified(FileModifiedEvent(str(inside)))

        assert "ignored-zone/inside.md" not in link_db.get_source_files(), (
            "PD-BUG-102/105: a modify event inside an ignored directory "
            "was parsed and indexed into the database"
        )

    def test_modify_event_deferred_during_initial_scan(self, project_setup):
        """PD-BUG-053 pattern: modify events arriving before the initial
        scan completes must be deferred and replayed afterward."""
        handler = project_setup["handler"]
        tracking = project_setup["tracking"]
        link_db = project_setup["link_db"]

        handler.begin_event_deferral()
        self._append_link(tracking)
        handler.on_modified(FileModifiedEvent(str(tracking)))
        assert not link_db.get_references_to_file("notes/target.md"), (
            "modify event must not be processed while the initial scan is "
            "still populating the database"
        )

        handler.notify_scan_complete()
        assert link_db.get_references_to_file(
            "notes/target.md"
        ), "deferred modify event was not replayed after scan completion"


class TestOwnOutputExclusion:
    """Regression tests for PD-BUG-107: the daemon indexed its own log
    files. logs/linkwatcher/ is not covered by ignored_directories (the
    linkWatcher entry matches case-sensitively), so log content entered
    the link database — moves rewrote historical log lines — and with the
    PD-BUG-102 on_modified rescan every rescan's own log write fired
    another modify event, a self-sustaining loop. The daemon must derive
    an own-output exclusion zone from its effective log file (the parent
    directory, where the launcher colocates all daemon outputs) and never
    index or react to events there.
    """

    @pytest.fixture
    def project_setup(self, tmp_path):
        """A project whose config points log_file at logs/linkwatcher/,
        with daemon-style output files and a doc referencing the log."""
        log_dir = tmp_path / "logs" / "linkwatcher"
        log_dir.mkdir(parents=True)
        log_file = log_dir / "LinkWatcherLog.txt"
        # Path-rich daemon log content — parses into references when indexed
        log_file.write_text(
            '2026-06-12 09:00:00 [info] file_moved src="notes/target.md" '
            'dest="archive/target.md"\n'
        )
        stdout_file = log_dir / "LinkWatcherStdout.txt"
        stdout_file.write_text('file_links_scanned file="notes/target.md"\n')

        notes_dir = tmp_path / "notes"
        notes_dir.mkdir()
        (notes_dir / "target.md").write_text("# Target\n")

        doc = tmp_path / "doc.md"
        doc.write_text("Check [the log](logs/linkwatcher/LinkWatcherLog.txt) for activity.\n")

        config = LinkWatcherConfig(log_file=str(log_file))
        link_db = LinkDatabase()
        parser = LinkParser()
        updater = LinkUpdater(str(tmp_path))
        handler = LinkMaintenanceHandler(
            link_db,
            parser,
            updater,
            str(tmp_path),
            config=config,
        )

        # Mirror the initial scan for doc.md only — the DB knows the doc's
        # reference to the log path (known-reference-target setup)
        for ref in parser.parse_file(str(doc)):
            ref.file_path = "doc.md"
            link_db.add_link(ref)

        return {
            "tmp_path": tmp_path,
            "log_dir": log_dir,
            "log_file": log_file,
            "stdout_file": stdout_file,
            "doc": doc,
            "link_db": link_db,
            "handler": handler,
        }

    def test_modify_event_on_own_log_not_indexed(self, project_setup):
        """PD-BUG-107 loop link: a modify event on the daemon's own log
        file must not trigger a rescan — indexing it makes every log
        write (including the rescan's own log line) feed the next rescan."""
        handler = project_setup["handler"]
        log_file = project_setup["log_file"]
        link_db = project_setup["link_db"]

        handler.on_modified(FileModifiedEvent(str(log_file)))

        assert "logs/linkwatcher/LinkWatcherLog.txt" not in link_db.get_source_files(), (
            "PD-BUG-107: the daemon's own log file was parsed and indexed "
            "on its modify event — every log write now feeds a rescan loop"
        )

    def test_modify_event_on_colocated_output_not_indexed(self, project_setup):
        """The launcher redirects daemon stdout/stderr into the log
        directory; the console handler writes a line there per log event.
        Files colocated with the log must be excluded or the loop survives
        through the redirect target."""
        handler = project_setup["handler"]
        stdout_file = project_setup["stdout_file"]
        link_db = project_setup["link_db"]

        handler.on_modified(FileModifiedEvent(str(stdout_file)))

        assert "logs/linkwatcher/LinkWatcherStdout.txt" not in link_db.get_source_files(), (
            "PD-BUG-107: a daemon output colocated with the log file "
            "(stdout redirect) was indexed — the rescan loop survives "
            "through the redirect target"
        )

    def test_rotation_rename_does_not_rewrite_references(self, project_setup):
        """Log rotation renames LinkWatcherLog.txt to a timestamped
        sibling. Docs reference the stable log path; the known-reference-
        target bypass must not treat rotation as a move and rewrite them."""
        handler = project_setup["handler"]
        log_file = project_setup["log_file"]
        log_dir = project_setup["log_dir"]
        doc = project_setup["doc"]

        rotated = log_dir / "LinkWatcherLog_20260612-090000.txt"
        log_file.rename(rotated)
        handler.on_moved(FileMovedEvent(str(log_file), str(rotated)))

        content = doc.read_text()
        assert "LinkWatcherLog_20260612-090000.txt" not in content, (
            "PD-BUG-107: log rotation was treated as a move of a referenced "
            f"target and rewrote the doc — content: {content}"
        )
        assert "logs/linkwatcher/LinkWatcherLog.txt" in content, (
            "PD-BUG-107: the stable log path must survive rotation — " f"content: {content}"
        )

    def test_create_event_in_own_output_dir_not_indexed(self, project_setup):
        """A file appearing in the daemon's output directory (rotated
        backup, fresh report) must not be parsed into the database."""
        handler = project_setup["handler"]
        log_dir = project_setup["log_dir"]
        link_db = project_setup["link_db"]

        report = log_dir / "LinkWatcherBrokenLinks.txt"
        report.write_text('broken reference: "notes/target.md" -> missing\n')
        handler.on_created(FileCreatedEvent(str(report)))

        assert "logs/linkwatcher/LinkWatcherBrokenLinks.txt" not in link_db.get_source_files(), (
            "PD-BUG-107: a file created in the daemon's own output "
            "directory was parsed and indexed"
        )

    def test_delete_event_in_own_output_dir_not_buffered(self, project_setup):
        """Deletes in the daemon's output directory (rotation cleanup of
        old backups) must not buffer for move correlation."""
        handler = project_setup["handler"]
        log_dir = project_setup["log_dir"]

        old_backup = log_dir / "LinkWatcherLog_20260601-000000.txt"
        handler.on_deleted(FileDeletedEvent(str(old_backup)))

        assert not handler._move_detector.has_pending, (
            "PD-BUG-107: a delete inside the daemon's own output directory "
            "was buffered for move correlation"
        )


class TestOwnOutputPredicate:
    """Unit tests for the PD-BUG-107 exclusion registry
    (compute_own_output_exclusions / is_own_output in utils)."""

    def test_log_in_subdirectory_excludes_whole_directory(self, tmp_path):
        from linkwatcher.utils import compute_own_output_exclusions, is_own_output

        log_file = tmp_path / "logs" / "linkwatcher" / "LinkWatcherLog.txt"
        registry = compute_own_output_exclusions(str(log_file), str(tmp_path))

        assert is_own_output(str(log_file), registry)
        assert is_own_output(str(log_file.parent / "LinkWatcherStdout.txt"), registry)
        assert is_own_output(str(log_file.parent / "nested" / "any.txt"), registry)
        assert not is_own_output(str(tmp_path / "logs" / "other" / "x.txt"), registry)
        assert not is_own_output(str(tmp_path / "readme.md"), registry)

    def test_log_in_project_root_excludes_only_rotation_family(self, tmp_path):
        from linkwatcher.utils import compute_own_output_exclusions, is_own_output

        log_file = tmp_path / "LinkWatcherLog.txt"
        registry = compute_own_output_exclusions(str(log_file), str(tmp_path))

        # Never exclude the whole project — only the log + rotation siblings
        assert is_own_output(str(log_file), registry)
        assert is_own_output(str(tmp_path / "LinkWatcherLog_20260612-090000.txt"), registry)
        assert not is_own_output(str(tmp_path / "LinkWatcherLogbook.txt"), registry)
        assert not is_own_output(str(tmp_path / "readme.md"), registry)
        assert not is_own_output(str(tmp_path / "notes" / "a.md"), registry)

    def test_no_file_logging_excludes_nothing(self, tmp_path):
        from linkwatcher.utils import compute_own_output_exclusions, is_own_output

        registry = compute_own_output_exclusions(None, str(tmp_path))
        assert not is_own_output(str(tmp_path / "anything.txt"), registry)

    def test_log_in_ancestor_of_root_excludes_nothing_in_tree(self, tmp_path):
        """PD-BUG-109: a log dir that is an ancestor of the project root
        must not be excluded as a directory — that prefix swallows the
        entire watched tree (0 files scanned, daemon inert)."""
        from linkwatcher.utils import compute_own_output_exclusions, is_own_output

        project_root = tmp_path / "project"
        log_file = tmp_path / "lw.log"  # E2E harness layout: log one level above root
        registry = compute_own_output_exclusions(str(log_file), str(project_root))

        assert not is_own_output(
            str(project_root), registry
        ), "PD-BUG-109: the project root itself matched the own-output zone"
        assert not is_own_output(
            str(project_root / "doc" / "readme.md"), registry
        ), "PD-BUG-109: a project file matched the own-output zone"
        # A log outside the watched tree can never be scanned or generate
        # events — the registry must be empty, not merely narrower.
        assert not registry["dirs"] and not registry["file_stems"]

    def test_log_in_sibling_dir_outside_root_excludes_nothing_in_tree(self, tmp_path):
        """PD-BUG-109 companion: log dir outside the root but not an
        ancestor (sibling) — likewise needs no exclusion."""
        from linkwatcher.utils import compute_own_output_exclusions, is_own_output

        project_root = tmp_path / "project"
        log_file = tmp_path / "elsewhere" / "lw.log"
        registry = compute_own_output_exclusions(str(log_file), str(project_root))

        assert not is_own_output(str(project_root / "doc" / "readme.md"), registry)
        assert not registry["dirs"] and not registry["file_stems"]

    def test_root_prefix_lookalike_dir_is_not_inside_root(self, tmp_path):
        """PD-BUG-109 boundary: a log dir whose path merely string-prefixes
        the root (``<root>-backup``) is outside the root — no exclusion,
        and never one that touches the watched tree."""
        from linkwatcher.utils import compute_own_output_exclusions, is_own_output

        project_root = tmp_path / "project"
        log_file = tmp_path / "project-backup" / "lw.log"
        registry = compute_own_output_exclusions(str(log_file), str(project_root))

        assert not is_own_output(str(project_root / "readme.md"), registry)
        assert not registry["dirs"] and not registry["file_stems"]

    def test_drive_root_project_keeps_inside_log_dir_excluded(self, tmp_path):
        """PD-BUG-109 amendment: with the project root at a drive root,
        ``abspath`` keeps the trailing separator, so the strictly-inside
        check must still match a log dir like ``C:\\logs`` — losing the
        exclusion re-opens the PD-BUG-107 rescan loop. Pure path logic,
        so the drive-root layout needs no real files."""
        import os

        from linkwatcher.utils import compute_own_output_exclusions, is_own_output

        drive_root = os.path.splitdrive(str(tmp_path))[0] + os.sep  # e.g. "C:\\"
        log_file = os.path.join(drive_root, "logs", "lw.log")
        registry = compute_own_output_exclusions(log_file, drive_root)

        assert registry["dirs"], "log dir strictly inside a drive-root project lost its exclusion"
        assert is_own_output(log_file, registry)
        assert not is_own_output(os.path.join(drive_root, "readme.md"), registry)
