"""
Tests for the LinkWatcherService class.

This module tests the main service orchestration and integration.
"""

import time
from pathlib import Path

import pytest

from linkwatcher.service import LinkWatcherService


class TestLinkWatcherService:
    """Test cases for LinkWatcherService."""

    def test_service_initialization(self, temp_project_dir):
        """Test service initialization."""
        service = LinkWatcherService(str(temp_project_dir))

        assert service.project_root == temp_project_dir
        assert service.observer is None
        assert service.running == False

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

        assert status["running"] == False
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
        assert service.updater.dry_run == True

        # Disable dry run
        service.set_dry_run(False)
        assert service.updater.dry_run == False

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
        # Note: This is a basic test - full signal testing would require more complex setup
        assert hasattr(service, "_signal_handler")

        # Test signal handler function
        service.running = True
        service._signal_handler(signal.SIGINT, None)
        assert service.running == False

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
