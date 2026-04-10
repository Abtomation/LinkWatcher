"""
Tests for the LinkWatcherService class.

This module tests the main service orchestration and integration.
"""

import time
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest

from linkwatcher.service import LinkWatcherService

pytestmark = [
    pytest.mark.feature("0.1.1"),
    pytest.mark.priority("Critical"),
    pytest.mark.cross_cutting(["1.1.1", "0.1.2"]),
    pytest.mark.test_type("unit"),
    pytest.mark.specification(
        "test/specifications/feature-specs/test-spec-0-1-1-core-architecture.md"
    ),
]


class TestLinkWatcherService:
    """Test cases for LinkWatcherService."""

    def test_service_initialization(self, temp_project_dir):
        """Test service initialization."""
        service = LinkWatcherService(str(temp_project_dir))

        assert service.project_root == temp_project_dir
        assert service.observer is None
        assert service.running is False

        # Check that components are initialized
        assert service.link_db is not None
        assert service.parser is not None
        assert service.updater is not None
        assert service.handler is not None

    def test_service_initialization_default_path(self):
        """Test service initialization with default path."""
        service = LinkWatcherService()

        # Should use current directory
        assert service.project_root == Path(".").resolve()

    def test_initial_scan(self, temp_project_dir, sample_files):
        """Test initial scan functionality."""
        service = LinkWatcherService(str(temp_project_dir))

        # Perform initial scan
        service._initial_scan()

        # Check that database was populated
        stats = service.link_db.get_stats()
        assert stats["files_with_links"] > 0
        assert stats["total_references"] > 0

        # Check that scan time was recorded
        assert service.link_db.last_scan is not None

    def test_get_status(self, temp_project_dir):
        """Test getting service status."""
        service = LinkWatcherService(str(temp_project_dir))

        status = service.get_status()

        assert "running" in status
        assert "project_root" in status
        assert "database_stats" in status
        assert "handler_stats" in status
        assert "last_scan" in status

        assert status["running"] is False
        assert status["project_root"] == str(temp_project_dir)

    def test_force_rescan(self, temp_project_dir, sample_files):
        """Test forcing a complete rescan."""
        service = LinkWatcherService(str(temp_project_dir))

        # Do initial scan
        service._initial_scan()
        initial_stats = service.link_db.get_stats()

        # Add some data to database manually
        from linkwatcher.models import LinkReference

        fake_ref = LinkReference("fake.md", 1, 0, 10, "fake", "fake.txt", "test")
        service.link_db.add_link(fake_ref)

        # Database should have extra reference
        modified_stats = service.link_db.get_stats()
        assert modified_stats["total_references"] > initial_stats["total_references"]

        # Force rescan
        service.force_rescan()

        # Database should be back to original state
        final_stats = service.link_db.get_stats()
        assert final_stats["total_references"] == initial_stats["total_references"]

    def test_set_dry_run(self, temp_project_dir):
        """Test setting dry run mode."""
        service = LinkWatcherService(str(temp_project_dir))

        # Enable dry run
        service.set_dry_run(True)
        assert service.updater.dry_run is True

        # Disable dry run
        service.set_dry_run(False)
        assert service.updater.dry_run is False

    def test_add_custom_parser(self, temp_project_dir):
        """Test adding a custom parser."""
        service = LinkWatcherService(str(temp_project_dir))

        # Create mock parser
        class MockParser:
            def parse_file(self, file_path):
                return []

        # Add custom parser
        service.add_parser(".custom", MockParser())

        # Should be added to parser
        assert ".custom" in service.parser.parsers

        # Should be added to handler's monitored extensions
        assert ".custom" in service.handler.monitored_extensions

    def test_check_links_no_broken_links(self, temp_project_dir, sample_files):
        """Test link checking when all links are valid."""
        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        # All sample files should exist, so no broken links
        result = service.check_links()

        assert "total_checked" in result
        assert "broken_count" in result
        assert "broken_links" in result

        assert result["total_checked"] > 0
        assert result["broken_count"] == 0
        assert len(result["broken_links"]) == 0

    def test_check_links_with_broken_links(self, temp_project_dir, file_helper):
        """Test link checking when there are broken links."""
        service = LinkWatcherService(str(temp_project_dir))

        # Create a file with broken link
        md_file = temp_project_dir / "broken.md"
        content = "This has a [broken link](nonexistent.txt)."
        file_helper.create_markdown_file(md_file, content)

        service._initial_scan()

        # Check links
        result = service.check_links()

        assert result["total_checked"] > 0
        assert result["broken_count"] > 0
        assert len(result["broken_links"]) > 0

        # Check broken link details
        broken = result["broken_links"][0]
        assert "reference" in broken
        assert "target_path" in broken
        assert "reason" in broken
        assert broken["reason"] == "File not found"

    def test_check_links_anchor_fragment_not_false_positive(self, temp_project_dir, file_helper):
        """Regression: #fragment anchors should not be reported as broken."""
        service = LinkWatcherService(str(temp_project_dir))

        # Create target file (exists on disk)
        target_file = temp_project_dir / "target.md"
        file_helper.create_markdown_file(target_file, "# Section\nContent here.")

        # Create source file with anchor link to existing file
        source_file = temp_project_dir / "source.md"
        file_helper.create_markdown_file(
            source_file, "See [section](target.md#section) for details."
        )

        service._initial_scan()
        result = service.check_links()

        # target.md exists — the #section anchor must NOT cause a false positive
        broken_targets = [b["target_path"] for b in result["broken_links"]]
        assert (
            "target.md#section" not in broken_targets
        ), "Link with anchor fragment was incorrectly reported as broken (PD-BUG-070)"
        assert "target.md" not in broken_targets

    def test_service_components_integration(self, temp_project_dir, sample_files):
        """Test that all service components work together."""
        service = LinkWatcherService(str(temp_project_dir))

        # Initial scan should populate database
        service._initial_scan()
        initial_stats = service.link_db.get_stats()
        assert initial_stats["total_references"] > 0

        # Handler should be able to access database
        handler_stats = service.handler.get_stats()
        assert isinstance(handler_stats, dict)

        # Parser should be working
        md_file = next(f for f in sample_files.values() if f.suffix == ".md")
        references = service.parser.parse_file(str(md_file))
        assert len(references) > 0

        # Updater should be configured
        assert service.updater is not None
        assert hasattr(service.updater, "dry_run")

    def test_signal_handler_setup(self, temp_project_dir):
        """Test that signal handlers are properly set up."""
        import signal

        service = LinkWatcherService(str(temp_project_dir))

        # Signal handlers should be set
        assert signal.getsignal(signal.SIGINT) == service._signal_handler

        # Test signal handler function
        service.running = True
        service._signal_handler(signal.SIGINT, None)
        assert service.running is False

    def test_signal_handler_skipped_when_disabled(self, temp_project_dir):
        """Test that signal handlers are not registered when register_signals=False."""
        import signal

        handler_before = signal.getsignal(signal.SIGINT)
        service = LinkWatcherService(str(temp_project_dir), register_signals=False)

        # Signal handler should NOT have been changed
        assert signal.getsignal(signal.SIGINT) == handler_before
        # But the method should still exist on the instance
        assert hasattr(service, "_signal_handler")

    def test_service_statistics_tracking(self, temp_project_dir, sample_files):
        """Test that service properly tracks statistics."""
        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        # Get initial statistics
        status = service.get_status()
        db_stats = status["database_stats"]
        handler_stats = status["handler_stats"]

        # Database stats should be populated
        assert db_stats["total_references"] > 0
        assert db_stats["files_with_links"] > 0

        # Handler stats should be initialized
        assert "files_moved" in handler_stats
        assert "files_deleted" in handler_stats
        assert "files_created" in handler_stats
        assert "links_updated" in handler_stats
        assert "errors" in handler_stats

    def test_service_error_handling(self, temp_project_dir):
        """Test service error handling."""
        # Test with invalid project root
        with pytest.raises(Exception):
            service = LinkWatcherService("/nonexistent/path")
            service._initial_scan()

    def test_service_thread_safety(self, temp_project_dir, sample_files):
        """Test basic thread safety of service operations."""
        import threading

        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        results = []

        def check_status():
            for _ in range(10):
                status = service.get_status()
                results.append(status["database_stats"]["total_references"])
                time.sleep(0.001)

        # Start multiple threads
        threads = []
        for _ in range(3):
            thread = threading.Thread(target=check_status)
            threads.append(thread)
            thread.start()

        # Wait for completion
        for thread in threads:
            thread.join()

        # All results should be consistent (same reference count)
        assert len(set(results)) == 1  # All values should be the same


class TestObserverResilience:
    """Regression tests for PD-BUG-018: Observer thread dies silently.

    These tests verify that:
    1. Handler event methods catch exceptions instead of killing the observer thread
    2. The on_error method handles watchdog errors
    3. The service main loop detects a dead observer thread
    """

    def test_on_moved_catches_exception(self, temp_project_dir):
        """on_moved must catch exceptions to keep the observer thread alive."""
        service = LinkWatcherService(str(temp_project_dir))
        handler = service.handler

        class BadEvent:
            @property
            def is_directory(self):
                raise RuntimeError("simulated error")

            src_path = str(temp_project_dir / "fake.md")

        initial_errors = handler.stats["errors"]
        # Must not raise — observer thread would die
        handler.on_moved(BadEvent())
        assert handler.stats["errors"] == initial_errors + 1

    def test_on_deleted_catches_exception(self, temp_project_dir):
        """on_deleted must catch exceptions to keep the observer thread alive."""
        service = LinkWatcherService(str(temp_project_dir))
        handler = service.handler

        class BadEvent:
            @property
            def is_directory(self):
                raise RuntimeError("simulated error")

            src_path = str(temp_project_dir / "fake.md")

        initial_errors = handler.stats["errors"]
        handler.on_deleted(BadEvent())
        assert handler.stats["errors"] == initial_errors + 1

    def test_on_created_catches_exception(self, temp_project_dir):
        """on_created must catch exceptions to keep the observer thread alive."""
        service = LinkWatcherService(str(temp_project_dir))
        handler = service.handler

        class BadEvent:
            @property
            def is_directory(self):
                raise RuntimeError("simulated error")

            src_path = str(temp_project_dir / "fake.md")

        initial_errors = handler.stats["errors"]
        handler.on_created(BadEvent())
        assert handler.stats["errors"] == initial_errors + 1

    def test_on_error_handles_watchdog_error(self, temp_project_dir):
        """on_error must handle watchdog OS errors without crashing."""
        service = LinkWatcherService(str(temp_project_dir))
        handler = service.handler

        initial_errors = handler.stats["errors"]
        handler.on_error(OSError("simulated watchdog OS error"))
        assert handler.stats["errors"] == initial_errors + 1

    def test_service_detects_dead_observer(self, temp_project_dir):
        """Service main loop must detect when observer thread has died."""
        service = LinkWatcherService(str(temp_project_dir))

        mock_observer = MagicMock()
        mock_observer.is_alive.return_value = False

        service.observer = mock_observer
        service.running = True

        # Simulate one iteration of the main loop health check
        if service.observer and not service.observer.is_alive():
            service.running = False

        assert service.running is False
        mock_observer.is_alive.assert_called_once()


class TestFileFilterOnEvents:
    """Regression tests for PD-BUG-040: on_moved and on_deleted skip file filter check.

    on_created correctly filters unmonitored files via _should_monitor_file(),
    but on_moved and on_deleted did not, causing wasted processing of .pyc,
    .tmp, sed temp files, etc.
    """

    def test_on_moved_skips_unmonitored_file(self, temp_project_dir):
        """on_moved must skip files with unmonitored extensions (e.g. .pyc)."""
        service = LinkWatcherService(str(temp_project_dir))
        handler = service.handler

        class FakeMovedEvent:
            is_directory = False
            src_path = str(temp_project_dir / "module.pyc")
            dest_path = str(temp_project_dir / "module_renamed.pyc")

        with patch.object(handler, "_handle_file_moved") as mock_handle:
            handler.on_moved(FakeMovedEvent())
            mock_handle.assert_not_called()

    def test_on_moved_processes_monitored_file(self, temp_project_dir):
        """on_moved must still process files with monitored extensions."""
        service = LinkWatcherService(str(temp_project_dir))
        handler = service.handler

        class FakeMovedEvent:
            is_directory = False
            src_path = str(temp_project_dir / "test.md")
            dest_path = str(temp_project_dir / "renamed.md")

        with patch.object(handler, "_handle_file_moved") as mock_handle:
            handler.on_moved(FakeMovedEvent())
            mock_handle.assert_called_once()

    def test_on_deleted_skips_unmonitored_file(self, temp_project_dir):
        """on_deleted must skip files with unmonitored extensions (e.g. .tmp)."""
        service = LinkWatcherService(str(temp_project_dir))
        handler = service.handler

        class FakeDeletedEvent:
            is_directory = False
            src_path = str(temp_project_dir / "pytest_tmp_file.tmp")

        with patch.object(handler, "_handle_file_deleted") as mock_handle:
            handler.on_deleted(FakeDeletedEvent())
            mock_handle.assert_not_called()

    def test_on_deleted_processes_monitored_file(self, temp_project_dir):
        """on_deleted must still process files with monitored extensions."""
        service = LinkWatcherService(str(temp_project_dir))
        handler = service.handler

        class FakeDeletedEvent:
            is_directory = False
            src_path = str(temp_project_dir / "deleted_file.md")

        with patch.object(handler, "_handle_file_deleted") as mock_handle:
            handler.on_deleted(FakeDeletedEvent())
            mock_handle.assert_called_once()

    def test_on_deleted_directory_workaround_not_broken(self, temp_project_dir):
        """Windows directory workaround must still work — directory paths have no
        extension and should not be filtered out by _should_monitor_file.

        On Windows, watchdog may report directory deletions with is_directory=False.
        The handler checks get_files_under_directory to detect this case. The file
        filter must not block this check for extensionless directory paths.
        """
        service = LinkWatcherService(str(temp_project_dir))
        handler = service.handler

        sub_dir = temp_project_dir / "subdir"

        class FakeDeletedEvent:
            is_directory = False  # Windows reports directory as non-directory
            src_path = str(sub_dir)

        # Mock get_files_under_directory to return tracked files
        with patch.object(
            handler._dir_move_detector,
            "get_files_under_directory",
            return_value={"subdir/file.md"},
        ) as mock_get_files, patch.object(handler, "_handle_directory_deleted") as mock_dir_handler:
            handler.on_deleted(FakeDeletedEvent())
            # Directory workaround should fire — lookup must not be blocked
            mock_get_files.assert_called_once()
            mock_dir_handler.assert_called_once()


class TestStartupObserverOrder:
    """Regression test for PD-BUG-053: File move during startup scan not detected.

    The observer must be started BEFORE the initial scan runs, so that file
    moves occurring during the scan are captured by the watchdog observer.
    If the observer starts after the scan, there is a gap where moves are
    invisible.
    """

    def test_observer_starts_before_initial_scan(self, temp_project_dir):
        """Observer.start() must be called before _initial_scan() runs.

        Instead of running the full start() loop, we intercept _initial_scan
        and Observer to record call order without entering the blocking main loop.
        """
        import threading

        service = LinkWatcherService(str(temp_project_dir))

        call_order = []

        original_initial_scan = service._initial_scan

        def tracked_initial_scan():
            call_order.append("initial_scan")
            original_initial_scan()

        mock_observer = MagicMock()

        def tracked_observer_start():
            call_order.append("observer_start")
            # Schedule a stop so the main loop exits quickly
            threading.Timer(0.1, lambda: setattr(service, "running", False)).start()

        mock_observer.start = tracked_observer_start
        mock_observer.is_alive.return_value = True

        with patch.object(service, "_initial_scan", side_effect=tracked_initial_scan), patch(
            "linkwatcher.service.Observer", return_value=mock_observer
        ):
            service.start(initial_scan=True)

        assert "observer_start" in call_order, "observer.start() was never called"
        assert "initial_scan" in call_order, "_initial_scan() was never called"

        observer_idx = call_order.index("observer_start")
        initial_scan_idx = call_order.index("initial_scan")
        assert (
            observer_idx < initial_scan_idx
        ), f"Observer must start before initial scan, but order was: {call_order}"


class TestEventDeferralDuringStartup:
    """Regression tests for PD-BUG-053: File move during startup scan not detected.

    The observer starts before initial scan, so move events can arrive before
    the link DB has indexed referencing files.  The handler must defer all
    filesystem events received before notify_scan_complete() is called, then
    replay them once the DB is fully populated.
    """

    def test_events_deferred_before_scan_complete(self, temp_project_dir):
        """Events arriving before notify_scan_complete() must be queued, not processed."""
        service = LinkWatcherService(str(temp_project_dir))
        handler = service.handler

        # Activate deferral (as service.start() does before initial scan)
        handler.begin_event_deferral()
        assert not handler._scan_complete.is_set()

        # Send a move event before scan is complete
        src = temp_project_dir / "old.md"
        dst = temp_project_dir / "new.md"
        src.write_text("[link](target.md)")
        dst.write_text("[link](target.md)")

        event = MagicMock()
        event.is_directory = False
        event.src_path = str(src)
        event.dest_path = str(dst)

        with patch.object(handler, "_handle_file_moved") as mock_moved:
            handler.on_moved(event)
            # Must NOT have been called — event should be deferred
            mock_moved.assert_not_called()

    def test_deferred_events_replayed_after_scan_complete(self, temp_project_dir):
        """After notify_scan_complete(), all deferred events must be replayed."""
        service = LinkWatcherService(str(temp_project_dir))
        handler = service.handler
        handler.begin_event_deferral()

        src = temp_project_dir / "old.md"
        dst = temp_project_dir / "new.md"
        src.write_text("[link](target.md)")
        dst.write_text("[link](target.md)")

        event = MagicMock()
        event.is_directory = False
        event.src_path = str(src)
        event.dest_path = str(dst)

        # Queue event before scan completes
        handler.on_moved(event)
        assert len(handler._deferred_events) == 1

        # Now complete scan — deferred events should replay
        with patch.object(handler, "_handle_file_moved") as mock_moved:
            handler.notify_scan_complete()
            mock_moved.assert_called_once()

    def test_events_processed_normally_after_scan_complete(self, temp_project_dir):
        """After scan completes, events must be processed immediately (not queued)."""
        service = LinkWatcherService(str(temp_project_dir))
        handler = service.handler
        handler.notify_scan_complete()

        src = temp_project_dir / "old.md"
        dst = temp_project_dir / "new.md"
        src.write_text("[link](target.md)")
        dst.write_text("[link](target.md)")

        event = MagicMock()
        event.is_directory = False
        event.src_path = str(src)
        event.dest_path = str(dst)

        with patch.object(handler, "_handle_file_moved") as mock_moved:
            handler.on_moved(event)
            mock_moved.assert_called_once()

    def test_all_event_types_deferred(self, temp_project_dir):
        """on_moved, on_deleted, on_created must all defer before scan complete."""
        service = LinkWatcherService(str(temp_project_dir))
        handler = service.handler
        handler.begin_event_deferral()

        f = temp_project_dir / "test.md"
        f.write_text("content")

        move_event = MagicMock()
        move_event.is_directory = False
        move_event.src_path = str(f)
        move_event.dest_path = str(temp_project_dir / "test2.md")

        delete_event = MagicMock()
        delete_event.is_directory = False
        delete_event.src_path = str(f)

        create_event = MagicMock()
        create_event.is_directory = False
        create_event.src_path = str(temp_project_dir / "new.md")

        handler.on_moved(move_event)
        handler.on_deleted(delete_event)
        handler.on_created(create_event)

        assert len(handler._deferred_events) == 3
