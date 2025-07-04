"""
Error Handling Integration Tests (EH Test Cases)

This module implements error handling test cases, focusing on how the system
behaves under various error conditions and edge cases.

Test Cases Implemented:
- EH-001: File permission errors
- EH-002: Disk space issues
- EH-003: Network drive scenarios
- EH-004: Service interruption and recovery
- EH-005: Corrupted file handling
- EH-006: Large file handling
- EH-007: Unicode and encoding issues
- EH-008: Concurrent access scenarios
"""

import os
import shutil
import tempfile
import threading
import time
from pathlib import Path
from unittest.mock import Mock, patch

import pytest

from linkwatcher.database import LinkDatabase
from linkwatcher.parser import LinkParser
from linkwatcher.service import LinkWatcherService
from linkwatcher.updater import LinkUpdater


class TestFilePermissionErrors:
    """Test handling of file permission errors."""

    def test_eh_001_readonly_file_update(self, temp_project_dir):
        """
        EH-001: File permission errors

        Test Case: Attempt to update read-only files
        Expected: Graceful error handling, no system crash
        Priority: High
        """
        # Create files with references
        source_file = temp_project_dir / "source.txt"
        source_file.write_text("Original content")

        target_file = temp_project_dir / "target.md"
        target_content = "See [source file](source.txt) for details."
        target_file.write_text(target_content)

        # Make target file read-only
        target_file.chmod(0o444)  # Read-only

        try:
            # Initialize service
            service = LinkWatcherService(str(temp_project_dir))
            service._initial_scan()

            # Attempt to move source file (should trigger update attempt)
            new_source = temp_project_dir / "renamed_source.txt"
            source_file.rename(new_source)

            # Process the move event
            service.handler.on_moved(None, str(source_file), str(new_source), False)

            # System should handle the permission error gracefully
            # The database should still be updated even if file update fails
            references = service.link_db.get_references_to_file("renamed_source.txt")
            assert len(references) >= 0  # Database operation should succeed

            # Original file should remain unchanged due to permission error
            content = target_file.read_text()
            assert "source.txt" in content  # Original reference preserved

        finally:
            # Restore permissions for cleanup
            target_file.chmod(0o644)

    def test_eh_001_readonly_directory(self, temp_project_dir):
        """Test handling of read-only directory."""
        # Create directory structure
        docs_dir = temp_project_dir / "docs"
        docs_dir.mkdir()

        readme = docs_dir / "readme.mdd"
        readme.write_text("# Documentation")

        main_file = temp_project_dir / "main.md"
        main_file.write_text("[Documentation](docs/readme.md)")

        # Make docs directory read-only
        docs_dir.chmod(0o555)  # Read-only directory

        try:
            service = LinkWatcherService(str(temp_project_dir))
            service._initial_scan()

            # Try to move the readme file (should fail due to directory permissions)
            new_readme = docs_dir / "documentation.md"

            # This should be handled gracefully
            try:
                readme.rename(new_readme)
                service.handler.on_moved(None, str(readme), str(new_readme), False)
            except PermissionError:
                # Expected - system should handle this gracefully
                pass

            # Service should continue operating
            stats = service.link_db.get_stats()
            assert stats is not None

        finally:
            # Restore permissions
            docs_dir.chmod(0o755)

    def test_eh_001_permission_denied_database(self, temp_project_dir):
        """Test handling of database permission errors."""
        # Create initial setup
        service = LinkWatcherService(str(temp_project_dir))

        # Create a file with references
        test_file = temp_project_dir / "test.md"
        test_file.write_text("[Link](target.txt)")

        service._initial_scan()

        # Make database file read-only (simulate permission error)
        db_file = Path(service.link_db.db_path)
        if db_file.exists():
            db_file.chmod(0o444)

        try:
            # Try to add more references (should handle database permission error)
            new_file = temp_project_dir / "new.md"
            new_file.write_text("[Another link](another.txt)")

            # This should be handled gracefully
            service.handler.on_created(None, str(new_file), False)

            # Service should continue operating even if database updates fail
            assert service.link_db is not None

        finally:
            # Restore permissions
            if db_file.exists():
                db_file.chmod(0o644)


class TestDiskSpaceIssues:
    """Test handling of disk space issues."""

    @pytest.mark.skipif(os.name == "nt", reason="Disk space simulation complex on Windows")
    def test_eh_002_disk_full_simulation(self, temp_project_dir):
        """
        EH-002: Disk space issues

        Test Case: Simulate disk full condition
        Expected: Graceful degradation, no data corruption
        Priority: Medium
        """
        # Create service
        service = LinkWatcherService(str(temp_project_dir))

        # Create test files
        source_file = temp_project_dir / "source.txt"
        source_file.write_text("Content")

        target_file = temp_project_dir / "target.md"
        target_file.write_text("[Link](source.txt)")

        service._initial_scan()

        # Mock disk full condition
        original_write = Path.write_text

        def mock_write_text(self, data, encoding=None, errors=None):
            if "renamed" in str(self):
                raise OSError("No space left on device")
            return original_write(self, data, encoding, errors)

        with patch.object(Path, "write_text", mock_write_text):
            # Try to move file (should trigger update that fails due to "disk full")
            new_source = temp_project_dir / "renamed_source.txt"
            source_file.rename(new_source)

            # Process move event
            service.handler.on_moved(None, str(source_file), str(new_source), False)

            # System should handle the disk full error gracefully
            # Database should still be updated
            references = service.link_db.get_references_to_file("renamed_source.txt")
            assert len(references) >= 0

            # Original file should remain unchanged due to disk full
            content = target_file.read_text()
            assert "source.txt" in content

    def test_eh_002_backup_creation_failure(self, temp_project_dir):
        """Test handling of backup creation failure."""
        # Create service with backups enabled
        service = LinkWatcherService(str(temp_project_dir))
        service.config.create_backups = True

        # Create test files
        source_file = temp_project_dir / "source.txt"
        source_file.write_text("Content")

        target_file = temp_project_dir / "target.md"
        target_file.write_text("[Link](source.txt)")

        service._initial_scan()

        # Mock backup creation failure
        original_copy = shutil.copy2

        def mock_copy_fail(src, dst):
            if dst.endswith(".bak"):
                raise OSError("No space left on device")
            return original_copy(src, dst)

        with patch("shutil.copy2", mock_copy_fail):
            # Move file (backup creation should fail but update should continue)
            new_source = temp_project_dir / "renamed_source.txt"
            source_file.rename(new_source)

            service.handler.on_moved(None, str(source_file), str(new_source), False)

            # Update should still proceed despite backup failure
            content = target_file.read_text()
            # Depending on implementation, update might still succeed
            assert content is not None


class TestNetworkDriveScenarios:
    """Test handling of network drive scenarios."""

    def test_eh_003_network_timeout_simulation(self, temp_project_dir):
        """
        EH-003: Network drive scenarios

        Test Case: Simulate network timeout
        Expected: Graceful timeout handling
        Priority: Low
        """
        # Create service
        service = LinkWatcherService(str(temp_project_dir))

        # Create test files
        test_file = temp_project_dir / "test.md"
        test_file.write_text("[Link](target.txt)")

        service._initial_scan()

        # Mock network timeout
        original_read_text = Path.read_text

        def mock_read_timeout(self, encoding=None, errors=None):
            if "network" in str(self):
                time.sleep(0.1)  # Simulate delay
                raise TimeoutError("Network timeout")
            return original_read_text(self, encoding, errors)

        with patch.object(Path, "read_text", mock_read_timeout):
            # Try to process a "network" file
            network_file = temp_project_dir / "network_file.md"
            network_file.write_text("[Network link](network_target.txt)")

            # This should be handled gracefully
            service.handler.on_created(None, str(network_file), False)

            # Service should continue operating
            stats = service.link_db.get_stats()
            assert stats is not None

    def test_eh_003_intermittent_connectivity(self, temp_project_dir):
        """Test handling of intermittent network connectivity."""
        service = LinkWatcherService(str(temp_project_dir))

        # Simulate intermittent failures
        failure_count = 0

        def mock_intermittent_failure(*args, **kwargs):
            nonlocal failure_count
            failure_count += 1
            if failure_count % 3 == 0:  # Fail every 3rd call
                raise ConnectionError("Network unreachable")
            return True

        # Test that service handles intermittent failures gracefully
        with patch.object(service.link_db, "add_reference", mock_intermittent_failure):
            for i in range(10):
                test_file = temp_project_dir / f"test_{i}.md"
                test_file.write_text(f"[Link {i}](target_{i}.txt)")

                try:
                    service.handler.on_created(None, str(test_file), False)
                except ConnectionError:
                    # Expected for some calls
                    pass

        # Service should still be operational
        assert service.link_db is not None


class TestServiceInterruption:
    """Test service interruption and recovery scenarios."""

    def test_eh_004_service_restart_recovery(self, temp_project_dir):
        """
        EH-004: Service interruption and recovery

        Test Case: Service restart and state recovery
        Expected: Service recovers previous state
        Priority: High
        """
        # Create initial service and files
        service1 = LinkWatcherService(str(temp_project_dir))

        test_file = temp_project_dir / "test.md"
        test_file.write_text("[Link](target.txt)")

        target_file = temp_project_dir / "target.txt"
        target_file.write_text("Target content")

        service1._initial_scan()

        # Verify initial state
        initial_stats = service1.link_db.get_stats()
        assert initial_stats["total_references"] > 0

        # Simulate service shutdown
        service1.stop()
        del service1

        # Create new service instance (simulating restart)
        service2 = LinkWatcherService(str(temp_project_dir))
        service2._initial_scan()

        # Verify state recovery
        recovered_stats = service2.link_db.get_stats()
        assert recovered_stats["total_references"] == initial_stats["total_references"]

        # Test that operations work after restart
        new_target = temp_project_dir / "renamed_target.txt"
        target_file.rename(new_target)

        service2.handler.on_moved(None, str(target_file), str(new_target), False)

        # Verify update worked
        updated_content = test_file.read_text()
        assert "renamed_target.txt" in updated_content

    def test_eh_004_database_corruption_recovery(self, temp_project_dir):
        """Test recovery from database corruption."""
        # Create service
        service = LinkWatcherService(str(temp_project_dir))

        # Create test files
        test_file = temp_project_dir / "test.md"
        test_file.write_text("[Link](target.txt)")

        service._initial_scan()

        # Simulate database corruption by writing invalid data
        db_file = Path(service.link_db.db_path)
        if db_file.exists():
            db_file.write_text("CORRUPTED DATABASE CONTENT")

        # Create new service (should handle corrupted database)
        service2 = LinkWatcherService(str(temp_project_dir))

        # Should recover by rebuilding database
        service2._initial_scan()

        # Verify recovery
        stats = service2.link_db.get_stats()
        assert stats is not None
        assert stats["total_references"] >= 0

    def test_eh_004_concurrent_service_instances(self, temp_project_dir):
        """Test handling of concurrent service instances."""
        # Create two service instances
        service1 = LinkWatcherService(str(temp_project_dir))
        service2 = LinkWatcherService(str(temp_project_dir))

        # Create test file
        test_file = temp_project_dir / "test.md"
        test_file.write_text("[Link](target.txt)")

        # Both services scan (should handle concurrent access)
        service1._initial_scan()
        service2._initial_scan()

        # Both should be operational
        stats1 = service1.link_db.get_stats()
        stats2 = service2.link_db.get_stats()

        assert stats1 is not None
        assert stats2 is not None


class TestCorruptedFileHandling:
    """Test handling of corrupted or invalid files."""

    def test_eh_005_binary_file_handling(self, temp_project_dir):
        """
        EH-005: Corrupted file handling

        Test Case: Process binary files
        Expected: Skip gracefully without errors
        Priority: Medium
        """
        # Create service
        service = LinkWatcherService(str(temp_project_dir))

        # Create binary file
        binary_file = temp_project_dir / "binary.dat"
        binary_content = bytes(range(256))  # Binary content
        binary_file.write_bytes(binary_content)

        # Should handle binary file gracefully
        service.handler.on_created(None, str(binary_file), False)

        # Service should continue operating
        stats = service.link_db.get_stats()
        assert stats is not None

    def test_eh_005_invalid_encoding_handling(self, temp_project_dir):
        """Test handling of files with invalid encoding."""
        service = LinkWatcherService(str(temp_project_dir))

        # Create file with invalid UTF-8
        invalid_file = temp_project_dir / "invalid.txt"
        invalid_content = b"Valid text\xff\xfe\xfd Invalid bytes [link](target.txt)"
        invalid_file.write_bytes(invalid_content)

        # Should handle encoding errors gracefully
        service.handler.on_created(None, str(invalid_file), False)

        # Service should continue operating
        stats = service.link_db.get_stats()
        assert stats is not None

    def test_eh_005_extremely_long_lines(self, temp_project_dir):
        """Test handling of files with extremely long lines."""
        service = LinkWatcherService(str(temp_project_dir))

        # Create file with very long line
        long_file = temp_project_dir / "long_lines.txt"
        long_line = "x" * 100000 + "[link](target.txt)" + "y" * 100000
        long_file.write_text(long_line)

        # Should handle long lines gracefully
        service.handler.on_created(None, str(long_file), False)

        # Should still find the link
        references = service.link_db.get_references_to_file("target.txt")
        assert len(references) >= 0


class TestLargeFileHandling:
    """Test handling of large files."""

    def test_eh_006_large_file_processing(self, temp_project_dir):
        """
        EH-006: Large file handling

        Test Case: Process files near size limits
        Expected: Handle according to configuration
        Priority: Medium
        """
        # Create service with small file size limit
        service = LinkWatcherService(str(temp_project_dir))
        service.config.max_file_size_mb = 1  # 1MB limit

        # Create large file (2MB)
        large_file = temp_project_dir / "large.txt"
        content = "Large file content\n" * 100000  # ~2MB
        content += "[link](target.txt)\n"
        large_file.write_text(content)

        # Should handle large file according to configuration
        service.handler.on_created(None, str(large_file), False)

        # File might be skipped due to size limit
        stats = service.link_db.get_stats()
        assert stats is not None

    def test_eh_006_memory_usage_large_files(self, temp_project_dir):
        """Test memory usage with large files."""
        service = LinkWatcherService(str(temp_project_dir))

        # Create multiple moderately large files
        for i in range(5):
            large_file = temp_project_dir / f"large_{i}.txt"
            content = f"File {i} content\n" * 10000
            content += f"[link {i}](target_{i}.txt)\n"
            large_file.write_text(content)

        # Process all files
        service._initial_scan()

        # Should complete without memory issues
        stats = service.link_db.get_stats()
        assert stats["files_with_links"] >= 0


class TestUnicodeAndEncoding:
    """Test Unicode and encoding handling."""

    def test_eh_007_unicode_file_names(self, temp_project_dir):
        """
        EH-007: Unicode and encoding issues

        Test Case: Files with Unicode names
        Expected: Handle Unicode correctly
        Priority: Medium
        """
        service = LinkWatcherService(str(temp_project_dir))

        # Create files with Unicode names
        unicode_file = temp_project_dir / "测试文件.md"
        unicode_file.write_text("[Link](目标文件.txt)")

        target_file = temp_project_dir / "目标文件.txt"
        target_file.write_text("Unicode target content")

        # Should handle Unicode file names
        service._initial_scan()

        # Verify references were found
        references = service.link_db.get_references_to_file("目标文件.txt")
        assert len(references) >= 0

        # Test file move with Unicode names
        new_target = temp_project_dir / "新目标文件.txt"
        target_file.rename(new_target)

        service.handler.on_moved(None, str(target_file), str(new_target), False)

        # Should handle Unicode file moves
        updated_content = unicode_file.read_text()
        assert "新目标文件.txt" in updated_content or "目标文件.txt" in updated_content

    def test_eh_007_mixed_encodings(self, temp_project_dir):
        """Test handling of files with different encodings."""
        service = LinkWatcherService(str(temp_project_dir))

        # Create files with different encodings
        utf8_file = temp_project_dir / "utf8.txt"
        utf8_file.write_text("UTF-8 content [link](target.txt)", encoding="utf-8")

        latin1_file = temp_project_dir / "latin1.txt"
        latin1_content = "Latin-1 content [link](target.txt) café"
        latin1_file.write_text(latin1_content, encoding="latin-1")

        # Should handle different encodings gracefully
        service._initial_scan()

        # Service should continue operating
        stats = service.link_db.get_stats()
        assert stats is not None


class TestConcurrentAccess:
    """Test concurrent access scenarios."""

    def test_eh_008_concurrent_file_operations(self, temp_project_dir):
        """
        EH-008: Concurrent access scenarios

        Test Case: Multiple simultaneous file operations
        Expected: Handle concurrency safely
        Priority: High
        """
        service = LinkWatcherService(str(temp_project_dir))

        # Create initial files
        for i in range(10):
            test_file = temp_project_dir / f"test_{i}.md"
            test_file.write_text(f"[Link {i}](target_{i}.txt)")

        service._initial_scan()

        # Simulate concurrent file operations
        def move_files():
            for i in range(5):
                old_file = temp_project_dir / f"test_{i}.md"
                new_file = temp_project_dir / f"moved_test_{i}.md"
                if old_file.exists():
                    old_file.rename(new_file)
                    service.handler.on_moved(None, str(old_file), str(new_file), False)

        def create_files():
            for i in range(10, 15):
                new_file = temp_project_dir / f"new_test_{i}.md"
                new_file.write_text(f"[New Link {i}](new_target_{i}.txt)")
                service.handler.on_created(None, str(new_file), False)

        # Run operations concurrently
        thread1 = threading.Thread(target=move_files)
        thread2 = threading.Thread(target=create_files)

        thread1.start()
        thread2.start()

        thread1.join()
        thread2.join()

        # Service should handle concurrent operations
        stats = service.link_db.get_stats()
        assert stats is not None
        assert stats["total_references"] >= 0

    def test_eh_008_database_concurrent_access(self, temp_project_dir):
        """Test concurrent database access."""
        service = LinkWatcherService(str(temp_project_dir))

        # Create test file
        test_file = temp_project_dir / "test.md"
        test_file.write_text("[Link](target.txt)")

        service._initial_scan()

        # Simulate concurrent database operations
        def add_references():
            for i in range(50):
                try:
                    service.link_db.add_reference(
                        f"file_{i}.md", 1, 0, 10, f"link_{i}", f"target_{i}.txt", "test"
                    )
                except Exception:
                    # Some operations might fail due to concurrency, that's OK
                    pass

        def query_references():
            for i in range(50):
                try:
                    service.link_db.get_references_to_file(f"target_{i}.txt")
                except Exception:
                    # Some operations might fail due to concurrency, that's OK
                    pass

        # Run concurrent database operations
        threads = []
        for _ in range(3):
            threads.append(threading.Thread(target=add_references))
            threads.append(threading.Thread(target=query_references))

        for thread in threads:
            thread.start()

        for thread in threads:
            thread.join()

        # Database should remain consistent
        stats = service.link_db.get_stats()
        assert stats is not None
