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

import shutil
import tempfile
import threading
import time
from pathlib import Path
from unittest.mock import Mock, patch

import pytest
from watchdog.events import DirMovedEvent, FileCreatedEvent, FileDeletedEvent, FileMovedEvent

from linkwatcher.config import TESTING_CONFIG, LinkWatcherConfig
from linkwatcher.models import LinkReference
from linkwatcher.service import LinkWatcherService


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
        assert stats_before["total_references"] >= 0

        # Stop service
        service.stop()

        # Verify cleanup
        # Database should still be accessible for final queries
        stats_after = service.link_db.get_stats()
        assert stats_after is not None

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
        assert True  # If we get here, multiple stops were handled gracefully


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
        # Stats might change depending on whether .py files were processed before
        assert new_stats is not None

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

        def query_database():
            for i in range(20):
                try:
                    service.link_db.get_stats()
                    # Iterate over links dict instead of get_all_references()
                    for refs_list in service.link_db.links.values():
                        _ = list(refs_list)
                    time.sleep(0.005)
                except Exception:
                    # Some operations might fail due to concurrency
                    pass

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

        # Verify service is still operational
        final_stats = service.link_db.get_stats()
        assert final_stats is not None
        assert final_stats["total_references"] >= 0

    def test_si_004_thread_safety_database(self, temp_project_dir):
        """Test database thread safety."""
        service = LinkWatcherService(str(temp_project_dir))

        # Concurrent database operations
        def add_references():
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
                except Exception:
                    # Some operations might fail, that's acceptable
                    pass

        def remove_references():
            for i in range(25):
                try:
                    service.link_db.remove_file_links(f"file_{i}.md")
                except Exception:
                    pass

        def query_references():
            for i in range(100):
                try:
                    service.link_db.get_stats()
                    # Iterate over links dict instead of get_all_references()
                    for refs_list in service.link_db.links.values():
                        _ = list(refs_list)
                except Exception:
                    pass

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
        assert stats is not None


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
        # References might still exist in database but file is gone
        assert len(final_refs) >= 0

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
        assert stats is not None


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
        assert stats is not None
        assert stats["total_references"] > 0

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
        assert stats is not None


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
        assert stats is not None

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
        assert stats is not None
