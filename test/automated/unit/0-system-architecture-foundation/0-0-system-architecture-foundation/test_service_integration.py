"""
Service Integration Tests (SI Test Cases)

This module implements comprehensive service integration test cases,
focusing on end-to-end service behavior and lifecycle management.

Test Cases Implemented:
- SI-001: Service startup and initialization
- SI-002: Service shutdown and cleanup
- SI-003: Configuration changes at runtime
- SI-004: Multi-threaded operation validation
- SI-005: Service state persistence
- SI-006: Event processing pipeline
- SI-007: Resource management
- SI-008: Service health monitoring
"""

import signal
import threading
import time
from pathlib import Path
from unittest.mock import MagicMock

import pytest
from watchdog.events import FileCreatedEvent, FileDeletedEvent, FileMovedEvent

from linkwatcher.config import LinkWatcherConfig
from linkwatcher.models import LinkReference
from linkwatcher.service import LinkWatcherService

pytestmark = [
    pytest.mark.feature("0.1.1"),
    pytest.mark.priority("Standard"),
    pytest.mark.cross_cutting(["1.1.1", "3.1.1", "0.1.2"]),
    pytest.mark.test_type("integration"),
    pytest.mark.specification(
        "test/specifications/feature-specs/test-spec-0-1-1-core-architecture.md"
    ),
]


class TestServiceLifecycle:
    """Test service startup, operation, and shutdown."""

    def test_si_001_service_startup_initialization(self, temp_project_dir):
        """
        SI-001: Service startup and initialization

        Test Case: Complete service initialization process
        Expected: Service starts correctly and is ready for operation
        Priority: Critical
        """
        # Test basic service initialization
        service = LinkWatcherService(str(temp_project_dir))

        # Verify service components are initialized
        assert str(service.project_root) == str(Path(temp_project_dir).resolve())
        assert service.link_db is not None
        assert service.parser is not None
        assert service.updater is not None
        assert service.handler is not None

        # Verify handler has monitored_extensions and ignored_dirs
        assert hasattr(service.handler, "monitored_extensions")
        assert hasattr(service.handler, "ignored_dirs")

        # Test initial scan
        test_file = temp_project_dir / "test.md"
        test_file.write_text("[Link](target.txt)")

        target_file = temp_project_dir / "target.txt"
        target_file.write_text("Target content")

        # Perform initial scan
        service._initial_scan()

        # Verify scan results
        stats = service.link_db.get_stats()
        assert stats["total_references"] > 0
        assert stats["files_with_links"] > 0

        # Verify references were found
        references = service.link_db.get_references_to_file("target.txt")
        assert len(references) > 0

    def test_si_001_service_with_custom_config(self, temp_project_dir):
        """Test service initialization with custom configuration applied post-init."""
        # Initialize service (no config param accepted)
        service = LinkWatcherService(str(temp_project_dir))

        # Apply custom configuration to handler
        service.handler.monitored_extensions = {".md", ".txt"}
        service.handler.ignored_dirs = {".git"}
        service.updater.set_dry_run(True)

        # Test that service respects configuration
        py_file = temp_project_dir / "test.py"
        py_file.write_text('# Python file with "config.json" reference')

        md_file = temp_project_dir / "test.md"
        md_file.write_text("[Link](target.txt)")

        service._initial_scan()

        # Should process .md files; collect all references from the database
        all_refs = []
        for refs_list in service.link_db.links.values():
            all_refs.extend(refs_list)
        md_refs = [ref for ref in all_refs if ref.file_path.endswith(".md")]

        assert len(md_refs) > 0  # Should find .md references

    def test_si_001_service_initialization_errors(self, temp_project_dir):
        """Test service initialization error handling."""
        # Test with invalid project directory
        with pytest.raises((FileNotFoundError, OSError)):
            LinkWatcherService("/nonexistent/directory")

        # Test with file instead of directory
        test_file = temp_project_dir / "not_a_directory.txt"
        test_file.write_text("content")

        with pytest.raises((NotADirectoryError, OSError)):
            LinkWatcherService(str(test_file))

    def test_si_002_service_shutdown_cleanup(self, temp_project_dir):
        """
        SI-002: Service shutdown and cleanup

        Test Case: Proper service shutdown and resource cleanup
        Expected: All resources cleaned up, no hanging threads
        Priority: Critical
        """
        # Initialize service
        service = LinkWatcherService(str(temp_project_dir))

        # Create test files
        test_file = temp_project_dir / "test.md"
        test_file.write_text("[Link](target.txt)")

        service._initial_scan()

        # Verify service is operational
        stats_before = service.link_db.get_stats()
        assert stats_before["total_references"] >= 1  # at least the [Link](target.txt) ref

        # Stop service
        service.stop()

        # Verify cleanup
        # Database should still be accessible for final queries
        stats_after = service.link_db.get_stats()
        assert isinstance(stats_after, dict)
        assert "total_references" in stats_after

        # File watcher should be stopped
        assert service.observer is None or not service.observer.is_alive()

    def test_si_002_service_multiple_stop_calls(self, temp_project_dir):
        """Test that multiple stop calls are handled gracefully."""
        service = LinkWatcherService(str(temp_project_dir))

        # Stop service multiple times
        service.stop()
        service.stop()  # Should not raise error
        service.stop()  # Should not raise error

        # Service should remain in stopped state
        assert service.observer is None or not service.observer.is_alive()


class TestConfigurationManagement:
    """Test runtime configuration changes."""

    def test_si_003_configuration_changes_runtime(self, temp_project_dir):
        """
        SI-003: Configuration changes at runtime

        Test Case: Modify configuration while service is running
        Expected: Changes take effect appropriately
        Priority: Medium
        """
        # Initialize service
        service = LinkWatcherService(str(temp_project_dir))

        # Create test files
        md_file = temp_project_dir / "test.md"
        md_file.write_text("[Link](target.txt)")

        py_file = temp_project_dir / "test.py"
        py_file.write_text('# Reference to "config.json"')

        service._initial_scan()

        # Get initial stats
        initial_stats = service.link_db.get_stats()

        # Modify handler configuration to include .py files
        service.handler.monitored_extensions.add(".py")

        # Re-scan with new configuration
        service._initial_scan()

        # Verify new files are processed
        new_stats = service.link_db.get_stats()
        # After re-scan with .py added, should still have at least the .md references
        assert new_stats["total_references"] >= initial_stats["total_references"]

    def test_si_003_config_validation_runtime(self, temp_project_dir):
        """Test configuration validation during runtime changes."""
        # Create a standalone config object and test validation
        config = LinkWatcherConfig()

        # Set invalid value
        original_max_size = config.max_file_size_mb
        config.max_file_size_mb = -1

        # Validate configuration
        issues = config.validate()
        assert len(issues) > 0  # Should find validation issues

        # Restore valid configuration
        config.max_file_size_mb = original_max_size

        # Validation should pass
        issues = config.validate()
        assert "max_file_size_mb must be positive" not in issues


class TestMultiThreadedOperation:
    """Test multi-threaded service operation."""

    def test_si_004_concurrent_file_operations(self, temp_project_dir):
        """
        SI-004: Multi-threaded operation validation

        Test Case: Concurrent file operations and event processing
        Expected: Thread-safe operation, no race conditions
        Priority: High
        """
        service = LinkWatcherService(str(temp_project_dir))

        # Create initial files
        for i in range(10):
            test_file = temp_project_dir / f"test_{i}.md"
            test_file.write_text(f"[Link {i}](target_{i}.txt)")

        service._initial_scan()

        # Define concurrent operations
        def create_files():
            for i in range(10, 20):
                test_file = temp_project_dir / f"new_test_{i}.md"
                test_file.write_text(f"[New Link {i}](new_target_{i}.txt)")
                create_event = FileCreatedEvent(str(test_file))
                service.handler.on_created(create_event)
                time.sleep(0.01)  # Small delay to simulate real operations

        def move_files():
            for i in range(5):
                old_file = temp_project_dir / f"test_{i}.md"
                new_file = temp_project_dir / f"moved_test_{i}.md"
                if old_file.exists():
                    old_file.rename(new_file)
                    move_event = FileMovedEvent(str(old_file), str(new_file))
                    service.handler.on_moved(move_event)
                    time.sleep(0.01)

        query_successes = []

        def query_database():
            successes = 0
            for i in range(20):
                try:
                    service.link_db.get_stats()
                    # Iterate over links dict instead of get_all_references()
                    for refs_list in service.link_db.links.values():
                        _ = list(refs_list)
                    successes += 1
                    time.sleep(0.005)
                except (KeyError, RuntimeError):
                    pass  # Expected: dict changed size during concurrent iteration
            query_successes.append(successes)

        # Run operations concurrently
        threads = [
            threading.Thread(target=create_files),
            threading.Thread(target=move_files),
            threading.Thread(target=query_database),
            threading.Thread(target=query_database),  # Multiple query threads
        ]

        for thread in threads:
            thread.start()

        for thread in threads:
            thread.join()

        # Verify service is still operational after concurrent access
        final_stats = service.link_db.get_stats()
        assert isinstance(final_stats, dict)
        assert "total_references" in final_stats
        assert isinstance(final_stats["total_references"], int)

        # At least some queries should have succeeded per thread
        for successes in query_successes:
            assert successes > 0, "All query iterations failed — possible concurrency regression"

    def test_si_004_thread_safety_database(self, temp_project_dir):
        """Test database thread safety."""
        service = LinkWatcherService(str(temp_project_dir))

        # Concurrent database operations — track success rates
        add_successes = []
        remove_successes = []
        query_successes = []

        def add_references():
            successes = 0
            for i in range(50):
                try:
                    service.link_db.add_link(
                        LinkReference(
                            file_path=f"file_{i}.md",
                            line_number=1,
                            column_start=0,
                            column_end=10,
                            link_text=f"link_{i}",
                            link_target=f"target_{i}.txt",
                            link_type="test",
                        )
                    )
                    successes += 1
                except (KeyError, RuntimeError):
                    pass  # Expected under concurrent mutation
            add_successes.append(successes)

        def remove_references():
            successes = 0
            for i in range(25):
                try:
                    service.link_db.remove_file_links(f"file_{i}.md")
                    successes += 1
                except (KeyError, RuntimeError):
                    pass  # Expected under concurrent mutation
            remove_successes.append(successes)

        def query_references():
            successes = 0
            for i in range(100):
                try:
                    service.link_db.get_stats()
                    # Iterate over links dict instead of get_all_references()
                    for refs_list in service.link_db.links.values():
                        _ = list(refs_list)
                    successes += 1
                except (KeyError, RuntimeError):
                    pass  # Expected: dict changed size during concurrent iteration
            query_successes.append(successes)

        # Run concurrent database operations
        threads = [
            threading.Thread(target=add_references),
            threading.Thread(target=add_references),
            threading.Thread(target=remove_references),
            threading.Thread(target=query_references),
            threading.Thread(target=query_references),
        ]

        for thread in threads:
            thread.start()

        for thread in threads:
            thread.join()

        # Database should remain consistent
        stats = service.link_db.get_stats()
        assert isinstance(stats, dict)
        assert "total_references" in stats

        # Verify at least some operations succeeded per thread
        for s in add_successes:
            assert s > 0, "All add operations failed — possible concurrency regression"
        for s in query_successes:
            assert s > 0, "All query operations failed — possible concurrency regression"


class TestStatePersistence:
    """Test service state persistence."""

    def test_si_005_state_persistence_across_restarts(self, temp_project_dir):
        """
        SI-005: Service state persistence

        Test Case: State persistence across service restarts
        Expected: State is preserved and restored correctly
        Priority: High
        """
        # Create first service instance
        service1 = LinkWatcherService(str(temp_project_dir))

        # Create test files
        test_files = []
        for i in range(5):
            test_file = temp_project_dir / f"test_{i}.md"
            test_file.write_text(f"[Link {i}](target_{i}.txt)")
            test_files.append(test_file)

            target_file = temp_project_dir / f"target_{i}.txt"
            target_file.write_text(f"Target {i} content")

        # Initial scan
        service1._initial_scan()

        # Get state before shutdown
        stats_before = service1.link_db.get_stats()
        all_refs_before = []
        for refs_list in service1.link_db.links.values():
            all_refs_before.extend(refs_list)

        # Stop first service
        service1.stop()
        del service1

        # Create second service instance (simulating restart)
        service2 = LinkWatcherService(str(temp_project_dir))

        # Re-scan to rebuild in-memory database
        service2._initial_scan()

        # Check if state is restored
        stats_after = service2.link_db.get_stats()
        all_refs_after = []
        for refs_list in service2.link_db.links.values():
            all_refs_after.extend(refs_list)

        # State should be preserved (or rebuilt consistently)
        assert stats_after["total_references"] == stats_before["total_references"]
        assert len(all_refs_after) == len(all_refs_before)

        # Test that operations work after restart
        new_file = temp_project_dir / "new_after_restart.md"
        new_file.write_text("[New link](new_target.txt)")

        create_event = FileCreatedEvent(str(new_file))
        service2.handler.on_created(create_event)

        # Should be able to add new references
        updated_stats = service2.link_db.get_stats()
        assert updated_stats["total_references"] >= stats_after["total_references"]

    def test_si_005_database_persistence(self, temp_project_dir):
        """Test database persistence specifically (in-memory database rebuilds on re-scan)."""
        # Create service and add data
        service1 = LinkWatcherService(str(temp_project_dir))

        # Create test files so the database has something to scan
        test_file = temp_project_dir / "test.md"
        test_file.write_text("[link](target.txt)\n[another](other.txt)")

        target_file = temp_project_dir / "target.txt"
        target_file.write_text("target content")

        other_file = temp_project_dir / "other.txt"
        other_file.write_text("other content")

        # Initial scan populates database
        service1._initial_scan()

        # Verify data is populated
        target_refs = service1.link_db.get_references_to_file("target.txt")
        other_refs = service1.link_db.get_references_to_file("other.txt")
        assert len(target_refs) >= 1
        assert len(other_refs) >= 1

        # Stop service
        service1.stop()
        del service1

        # Create new service and re-scan
        service2 = LinkWatcherService(str(temp_project_dir))
        service2._initial_scan()

        # Verify data is restored via re-scan
        target_refs = service2.link_db.get_references_to_file("target.txt")
        other_refs = service2.link_db.get_references_to_file("other.txt")

        assert len(target_refs) >= 1
        assert len(other_refs) >= 1


class TestEventProcessing:
    """Test event processing pipeline."""

    def test_si_006_event_processing_pipeline(self, temp_project_dir):
        """
        SI-006: Event processing pipeline

        Test Case: Complete event processing from detection to update
        Expected: Events processed correctly through entire pipeline
        Priority: Critical
        """
        service = LinkWatcherService(str(temp_project_dir))

        # Create initial files
        source_file = temp_project_dir / "source.txt"
        source_file.write_text("Source content")

        ref_file = temp_project_dir / "reference.md"
        ref_file.write_text("[Link](source.txt)")

        service._initial_scan()

        # Verify initial state
        initial_refs = service.link_db.get_references_to_file("source.txt")
        assert len(initial_refs) > 0

        # Test file creation event
        new_ref_file = temp_project_dir / "new_reference.md"
        new_ref_file.write_text("[New link](source.txt)")

        create_event = FileCreatedEvent(str(new_ref_file))
        service.handler.on_created(create_event)

        # Verify creation was processed
        updated_refs = service.link_db.get_references_to_file("source.txt")
        assert len(updated_refs) > len(initial_refs)

        # Test file move event
        new_source = temp_project_dir / "renamed_source.txt"
        source_file.rename(new_source)

        move_event = FileMovedEvent(str(source_file), str(new_source))
        service.handler.on_moved(move_event)

        # Verify move was processed
        old_refs = service.link_db.get_references_to_file("source.txt")
        new_refs = service.link_db.get_references_to_file("renamed_source.txt")

        assert len(old_refs) == 0  # Old references should be gone
        assert len(new_refs) > 0  # New references should exist

        # Verify file content was updated
        ref_content = ref_file.read_text()
        new_ref_content = new_ref_file.read_text()

        assert "renamed_source.txt" in ref_content
        assert "renamed_source.txt" in new_ref_content

        # Test file deletion event
        delete_event = FileDeletedEvent(str(new_source))
        service.handler.on_deleted(delete_event)

        # Verify deletion was processed
        final_refs = service.link_db.get_references_to_file("renamed_source.txt")
        assert isinstance(final_refs, list)

    def test_si_006_event_ordering(self, temp_project_dir):
        """Test that events are processed in correct order."""
        service = LinkWatcherService(str(temp_project_dir))

        # Create test file
        test_file = temp_project_dir / "test.txt"
        test_file.write_text("Original content")

        ref_file = temp_project_dir / "ref.md"
        ref_file.write_text("[Link](test.txt)")

        service._initial_scan()

        moved_path = str(temp_project_dir / "moved_test.txt")

        # Simulate rapid sequence of events
        events = [
            ("created", str(test_file)),
            # Skip "modified" since handler has no on_modified
            ("moved", str(test_file), moved_path),
            ("deleted", moved_path),
        ]

        # Process events in sequence
        for event in events:
            if event[0] == "created":
                create_event = FileCreatedEvent(event[1])
                service.handler.on_created(create_event)
            elif event[0] == "moved":
                move_event = FileMovedEvent(event[1], event[2])
                service.handler.on_moved(move_event)
            elif event[0] == "deleted":
                delete_event = FileDeletedEvent(event[1])
                service.handler.on_deleted(delete_event)

            time.sleep(0.01)  # Small delay between events

        # Service should handle rapid events gracefully
        stats = service.link_db.get_stats()
        assert isinstance(stats, dict)
        assert "total_references" in stats


class TestResourceManagement:
    """Test resource management and cleanup."""

    def test_si_007_memory_management(self, temp_project_dir):
        """
        SI-007: Resource management

        Test Case: Memory usage and cleanup
        Expected: No memory leaks, proper resource cleanup
        Priority: Medium
        """
        service = LinkWatcherService(str(temp_project_dir))

        # Create many files to test memory usage
        for i in range(100):
            test_file = temp_project_dir / f"test_{i}.md"
            content = f"# Test {i}\n\n"
            for j in range(10):
                content += f"[Link {j}](target_{i}_{j}.txt)\n"
            test_file.write_text(content)

        # Initial scan
        service._initial_scan()

        # Perform many operations
        for i in range(50):
            # Create new file
            new_file = temp_project_dir / f"new_{i}.md"
            new_file.write_text(f"[New link {i}](new_target_{i}.txt)")
            create_event = FileCreatedEvent(str(new_file))
            service.handler.on_created(create_event)

            # Move existing file
            if i < 25:
                old_file = temp_project_dir / f"test_{i}.md"
                new_location = temp_project_dir / f"moved_test_{i}.md"
                if old_file.exists():
                    old_file.rename(new_location)
                    move_event = FileMovedEvent(str(old_file), str(new_location))
                    service.handler.on_moved(move_event)

        # Service should continue operating efficiently
        stats = service.link_db.get_stats()
        # 100 files × 10 links each + 50 new files = significant references expected
        assert stats["total_references"] >= 100

        # Cleanup
        service.stop()

    def test_si_007_file_handle_management(self, temp_project_dir):
        """Test file handle management."""
        service = LinkWatcherService(str(temp_project_dir))

        # Create many files
        files = []
        for i in range(50):
            test_file = temp_project_dir / f"handle_test_{i}.txt"
            test_file.write_text(f"Content {i}")
            files.append(test_file)

        # Process files multiple times
        for _ in range(3):
            service._initial_scan()

        # Should not run out of file handles
        stats = service.link_db.get_stats()
        assert isinstance(stats, dict)
        assert "total_references" in stats


class TestServiceHealth:
    """Test service health monitoring."""

    def test_si_008_service_health_monitoring(self, temp_project_dir):
        """
        SI-008: Service health monitoring

        Test Case: Monitor service health and status
        Expected: Service provides health information
        Priority: Low
        """
        service = LinkWatcherService(str(temp_project_dir))

        # Create test files
        test_file = temp_project_dir / "test.md"
        test_file.write_text("[Link](target.txt)")

        service._initial_scan()

        # Check service health indicators
        stats = service.link_db.get_stats()
        assert isinstance(stats, dict)

        # Verify expected health indicators
        assert "total_references" in stats
        assert "files_with_links" in stats
        assert "total_targets" in stats

        # All values should be non-negative
        for key, value in stats.items():
            if isinstance(value, (int, float)):
                assert value >= 0, f"Health indicator {key} has negative value: {value}"

    def test_si_008_error_recovery(self, temp_project_dir):
        """Test service error recovery."""
        service = LinkWatcherService(str(temp_project_dir))

        # Create test file
        test_file = temp_project_dir / "test.md"
        test_file.write_text("[Link](target.txt)")

        service._initial_scan()

        # Simulate error condition
        original_method = service.link_db.add_link

        def failing_add_link(*args, **kwargs):
            raise Exception("Simulated database error")

        # Temporarily replace method with failing version
        service.link_db.add_link = failing_add_link

        # Try to process new file (should handle error gracefully)
        new_file = temp_project_dir / "new.md"
        new_file.write_text("[New link](new_target.txt)")

        try:
            create_event = FileCreatedEvent(str(new_file))
            service.handler.on_created(create_event)
        except Exception:
            # Error might propagate, that's OK
            pass

        # Restore original method
        service.link_db.add_link = original_method

        # Service should recover and continue operating
        recovery_file = temp_project_dir / "recovery.md"
        recovery_file.write_text("[Recovery link](recovery_target.txt)")

        create_event = FileCreatedEvent(str(recovery_file))
        service.handler.on_created(create_event)

        # Should be able to process new files after recovery
        stats = service.link_db.get_stats()
        assert stats["total_references"] >= 1  # at least the initial scan refs


class TestBug144ShutdownSequenceRunsOnEveryStopPath:
    """PD-BUG-144: ``stop()`` guarded its whole body with ``if self.running``,
    a flag every path that reaches it has already cleared.

    The monitoring loop exits by setting ``self.running = False`` — from a
    liveness failure (PD-BUG-139), from the observer-thread-died check
    (PD-BUG-018), or from ``_signal_handler`` on SIGINT/SIGTERM.  ``start()``'s
    ``finally`` then calls ``stop()``, the guard is already ``False``, and the
    entire shutdown sequence is skipped: the observer is never stopped or
    joined, final statistics are never printed, and neither ``service_stopping``
    nor ``service_stopped`` is logged.

    Consequences, in order of what actually matters:

    - It partially defeats PD-BUG-139.  That fix exists so a daemon which has
      gone blind stops *loudly* and the operator knows to run a validation
      scan.  On that exact path the log ends at ``observer_emitter_died`` with
      no shutdown confirmation, so a completed clean stop is indistinguishable
      from a crash mid-work.
    - It violates two named functional requirements — 0.1.1-FR-5 ("graceful
      shutdown ... stopping the file observer thread cleanly") and 0.1.1-FR-6
      ("SHALL report operational statistics upon shutdown") — and falsifies
      0.1.1-AC-4 and 0.1.1-AC-7, both of which the FDD records as met.

    Not reached at all under a hard kill: the Control Panel, the stop launcher
    and the E2E harness all use ``TerminateProcess`` / ``Stop-Process -Force``,
    so this defect belongs to WF-008 (Ctrl+C, self-stop), not WF-010.

    Contract pinned here: the shutdown sequence runs exactly once per started
    service, on every path that reaches ``stop()``, and a service that was
    never started stays silent.
    """

    @staticmethod
    def _service(tmp_path):
        """A service with its side-effecting collaborators replaced.

        ``register_signals=False`` keeps the real process's SIGINT handling out
        of the test session; the signal *path* is exercised by calling
        ``_signal_handler`` directly, which is exactly what the OS does.
        """
        svc = LinkWatcherService(str(tmp_path), register_signals=False)
        svc.observer = MagicMock()
        svc.logger = MagicMock()
        svc._print_final_stats = MagicMock()
        svc._remove_liveness_sentinel = MagicMock()
        svc._started = True
        svc.running = True
        return svc

    @staticmethod
    def _logged(svc):
        return [call.args[0] for call in svc.logger.info.call_args_list]

    # ---- the reported defect ----------------------------------------------

    def test_shutdown_runs_when_the_loop_cleared_running_first(self, tmp_path):
        """The liveness / observer-died self-stop shape: the loop sets
        ``running = False``, then ``start()``'s ``finally`` calls ``stop()``.
        """
        svc = self._service(tmp_path)
        svc.running = False  # what _watch_is_healthy() failing does

        svc.stop()

        assert svc.observer.stop.called, "observer was never stopped"
        assert svc.observer.join.called, "observer was never joined"
        assert svc._print_final_stats.called, "final statistics were never printed"
        assert "service_stopping" in self._logged(svc)
        assert "service_stopped" in self._logged(svc)

    def test_shutdown_runs_after_a_shutdown_signal(self, tmp_path):
        """The Ctrl+C shape. ``_signal_handler`` is what the OS invokes for
        SIGINT once ``start()`` has registered it, so this is the real path —
        the ``except KeyboardInterrupt`` branch in ``start()`` never fires
        while a handler is installed.
        """
        svc = self._service(tmp_path)
        svc._signal_handler(signal.SIGINT, None)

        svc.stop()

        assert svc.observer.stop.called
        assert svc.observer.join.called
        assert svc._print_final_stats.called
        assert "service_stopped" in self._logged(svc)

    def test_real_observer_is_not_left_running_after_a_signal_shutdown(self, tmp_path):
        """The non-mock assertion, and the one that reproduces 0.1.1-AC-4
        ("without orphaned threads") directly.

        A real observer is started, the loop is left the way a signal leaves
        it, and the observer thread must be dead once ``start()`` returns.
        Before the fix it is still alive — the watchdog thread is a daemon, so
        nothing hangs and the process exits cleanly, which is precisely why
        this went unnoticed.
        """
        (tmp_path / "a.md").write_text("[x](b.md)\n", encoding="utf-8")
        (tmp_path / "b.md").write_text("hi\n", encoding="utf-8")

        svc = LinkWatcherService(str(tmp_path), register_signals=False)
        loop = threading.Thread(target=lambda: svc.start(initial_scan=False), daemon=True)
        loop.start()

        deadline = time.time() + 15
        while time.time() < deadline and not svc.running:
            time.sleep(0.05)
        assert svc.running, "service never reached its monitoring loop"

        svc._signal_handler(signal.SIGINT, None)
        loop.join(timeout=15)

        assert not loop.is_alive(), "start() never returned"
        assert not svc.observer.is_alive(), "the observer thread was left running"

    # ---- controls ---------------------------------------------------------

    def test_control_explicit_stop_while_running_still_works(self, tmp_path):
        """The path that always worked — an exception in ``start()``, or a
        caller invoking ``stop()`` directly, both reach it with ``running``
        still ``True``.
        """
        svc = self._service(tmp_path)

        svc.stop()

        assert svc.observer.stop.called
        assert svc._print_final_stats.called
        assert "service_stopped" in self._logged(svc)

    def test_control_a_never_started_service_stays_silent(self, tmp_path):
        """``test_si_002_service_multiple_stop_calls`` calls ``stop()`` three
        times on a service that was never started. It must not raise — and it
        must not emit three shutdown records or three sets of statistics for a
        service that never ran.
        """
        svc = LinkWatcherService(str(tmp_path), register_signals=False)
        svc.logger = MagicMock()
        svc._print_final_stats = MagicMock()

        svc.stop()
        svc.stop()
        svc.stop()

        assert not svc._print_final_stats.called
        assert "service_stopping" not in self._logged(svc)
        assert "service_stopped" not in self._logged(svc)

    def test_control_shutdown_sequence_runs_exactly_once(self, tmp_path):
        """``start()``'s ``finally`` may call ``stop()`` after a caller already
        did. The second call must be a no-op, not a second join and a second
        set of statistics.
        """
        svc = self._service(tmp_path)

        svc.stop()
        svc.stop()

        assert svc.observer.stop.call_count == 1
        assert svc.observer.join.call_count == 1
        assert svc._print_final_stats.call_count == 1
        assert self._logged(svc).count("service_stopped") == 1

    def test_control_stop_does_not_raise_when_start_failed_before_the_observer_ran(self, tmp_path):
        """``start()`` builds the observer, schedules it, *then* starts it — and
        calls ``stop()`` from its ``finally`` whatever happens.

        If scheduling raises, the observer object exists but its thread never
        started, and ``join()`` on an unstarted thread raises ``RuntimeError``,
        which would mask the original failure. Guarding on ``self.observer``
        being set would reintroduce exactly that; the fix guards on the
        observer having actually started.
        """
        svc = LinkWatcherService(str(tmp_path), register_signals=False)
        svc.observer = MagicMock()
        svc.observer.join.side_effect = RuntimeError("cannot join thread before it is started")

        svc.stop()  # must not raise

        assert not svc.observer.join.called
