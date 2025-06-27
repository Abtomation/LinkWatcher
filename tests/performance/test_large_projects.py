"""
Performance Tests for Large Projects (PH Test Cases)

This module implements the PH test cases from our comprehensive test documentation,
focusing on performance with large projects and many files.

Test Cases Implemented:
- PH-001: 1000+ files with links
- PH-002: Deep directory structures
- PH-003: Large files
- PH-004: Many references to single file
- PH-005: Rapid file operations
"""

import shutil
import tempfile
import time
from pathlib import Path

import pytest

from linkwatcher.service import LinkWatcherService


class TestLargeProjectHandling:
    """Performance tests for large project scenarios."""

    @pytest.mark.slow
    def test_ph_001_thousand_plus_files(self, temp_project_dir):
        """
        PH-001: 1000+ files with links

        Test Case: Project with 1000+ linked files
        Expected: System handles load efficiently
        Priority: High
        """
        # Create large project structure
        num_files = 1000
        files_per_dir = 50

        # Create directory structure
        dirs = []
        for i in range(0, num_files, files_per_dir):
            dir_path = temp_project_dir / f"dir_{i//files_per_dir:03d}"
            dir_path.mkdir()
            dirs.append(dir_path)

        # Create files with cross-references
        created_files = []
        start_time = time.time()

        for i in range(num_files):
            dir_index = i // files_per_dir
            file_path = dirs[dir_index] / f"file_{i:04d}.md"

            # Create content with references to other files
            content = f"# File {i}\n\n"

            # Add references to a few other files
            for j in range(min(5, num_files)):
                ref_index = (i + j + 1) % num_files
                ref_dir_index = ref_index // files_per_dir
                ref_file = f"dir_{ref_dir_index:03d}/file_{ref_index:04d}.md"
                content += f"- [Reference {j}]({ref_file})\n"

            # Add some quoted references
            if i > 0:
                prev_dir_index = (i - 1) // files_per_dir
                prev_file = f"dir_{prev_dir_index:03d}/file_{i-1:04d}.md"
                content += f'\nSee "{prev_file}" for previous info.\n'

            file_path.write_text(content)
            created_files.append(file_path)

        creation_time = time.time() - start_time
        print(f"Created {num_files} files in {creation_time:.2f} seconds")

        # Initialize service and perform initial scan
        service = LinkWatcherService(str(temp_project_dir))

        scan_start = time.time()
        service._initial_scan()
        scan_time = time.time() - scan_start

        print(f"Initial scan completed in {scan_time:.2f} seconds")

        # Verify performance requirements
        assert scan_time < 30.0  # Should complete within 30 seconds
        assert creation_time < 60.0  # File creation should be reasonable

        # Verify database was populated
        stats = service.link_db.get_stats()
        assert stats["files_with_links"] >= num_files * 0.8  # Most files should have links
        assert stats["total_references"] >= num_files * 3  # Multiple refs per file

        print(f"Database stats: {stats}")

        # Test file move performance
        test_file = created_files[100]  # Pick a file in the middle
        new_location = temp_project_dir / "moved" / "test_file.md"
        new_location.parent.mkdir()

        move_start = time.time()
        test_file.rename(new_location)
        service.handler.on_moved(None, str(test_file), str(new_location), False)
        move_time = time.time() - move_start

        print(f"File move processed in {move_time:.2f} seconds")
        assert move_time < 5.0  # Move should be processed quickly

    def test_ph_002_deep_directory_structures(self, temp_project_dir):
        """
        PH-002: Deep directory structures

        Test Case: 10+ level deep directories
        Expected: All levels processed correctly
        Priority: Medium
        """
        # Create very deep directory structure
        max_depth = 15
        current_path = temp_project_dir

        # Build deep path
        for i in range(max_depth):
            current_path = current_path / f"level_{i:02d}"
            current_path.mkdir()

            # Create a file at each level
            file_path = current_path / f"file_at_level_{i}.md"

            # Create references to files at other levels
            content = f"# File at Level {i}\n\n"

            # Reference files at shallower levels
            for j in range(min(3, i)):
                rel_path = "../" * (i - j)
                ref_path = f"{rel_path}level_{j:02d}/file_at_level_{j}.md"
                content += f"- [Level {j}]({ref_path})\n"

            # Reference files at deeper levels (if they exist)
            for j in range(i + 1, min(i + 3, max_depth)):
                rel_path = "/".join([f"level_{k:02d}" for k in range(i + 1, j + 1)])
                ref_path = f"{rel_path}/file_at_level_{j}.md"
                content += f"- [Level {j}]({ref_path})\n"

            file_path.write_text(content)

        # Initialize service
        service = LinkWatcherService(str(temp_project_dir))

        # Measure scan performance
        start_time = time.time()
        service._initial_scan()
        scan_time = time.time() - start_time

        print(f"Deep structure scan completed in {scan_time:.2f} seconds")
        assert scan_time < 10.0  # Should handle deep structures efficiently

        # Verify all levels were processed
        stats = service.link_db.get_stats()
        assert stats["files_with_links"] >= max_depth * 0.8

        # Test moving a file from deep level
        deep_file = current_path / f"file_at_level_{max_depth-1}.md"
        shallow_location = temp_project_dir / "moved_from_deep.md"

        move_start = time.time()
        deep_file.rename(shallow_location)
        service.handler.on_moved(None, str(deep_file), str(shallow_location), False)
        move_time = time.time() - move_start

        print(f"Deep file move processed in {move_time:.2f} seconds")
        assert move_time < 3.0

    @pytest.mark.slow
    def test_ph_003_large_files(self, temp_project_dir):
        """
        PH-003: Large files

        Test Case: Files near size limits
        Expected: Large files processed or skipped appropriately
        Priority: Medium
        """
        # Create files of various sizes
        file_sizes = [
            (1024, "small.md"),  # 1KB
            (1024 * 100, "medium.md"),  # 100KB
            (1024 * 1024, "large.md"),  # 1MB
            (1024 * 1024 * 5, "huge.md"),  # 5MB
        ]

        created_files = []

        for size_bytes, filename in file_sizes:
            file_path = temp_project_dir / filename

            # Create content with file references
            base_content = f"# Large File {filename}\n\n"
            base_content += "References:\n"
            base_content += "- [Small file](small.md)\n"
            base_content += "- [Medium file](medium.md)\n"
            base_content += "- [Large file](large.md)\n"
            base_content += "- [Huge file](huge.md)\n\n"

            # Pad with content to reach target size
            padding_needed = size_bytes - len(base_content.encode("utf-8"))
            if padding_needed > 0:
                # Add repetitive content
                padding_line = "This is padding content to make the file larger. " * 10 + "\n"
                lines_needed = padding_needed // len(padding_line.encode("utf-8"))
                padding = padding_line * lines_needed
                content = base_content + padding
            else:
                content = base_content

            start_write = time.time()
            file_path.write_text(content)
            write_time = time.time() - start_write

            actual_size = file_path.stat().st_size
            print(f"Created {filename}: {actual_size} bytes in {write_time:.2f}s")

            created_files.append((file_path, actual_size))

        # Initialize service with size limits
        service = LinkWatcherService(str(temp_project_dir))

        # Measure parsing performance for different file sizes
        start_time = time.time()
        service._initial_scan()
        scan_time = time.time() - start_time

        print(f"Large files scan completed in {scan_time:.2f} seconds")

        # Verify performance is reasonable
        assert scan_time < 15.0  # Should handle large files within reasonable time

        # Check which files were processed
        stats = service.link_db.get_stats()
        print(f"Processed files stats: {stats}")

        # Smaller files should definitely be processed
        small_refs = service.link_db.get_references_to_file("small.md")
        medium_refs = service.link_db.get_references_to_file("medium.md")

        assert len(small_refs) >= 3  # Referenced by other files
        assert len(medium_refs) >= 3

        # Very large files might be skipped depending on configuration
        # This is acceptable behavior for performance

    def test_ph_004_many_references_to_single_file(self, temp_project_dir):
        """
        PH-004: Many references to single file

        Test Case: 100+ references to one file
        Expected: All references updated efficiently
        Priority: Medium
        """
        # Create target file
        target_file = temp_project_dir / "popular_file.txt"
        target_file.write_text("This file is referenced by many others")

        # Create many files that reference the target
        num_referencing_files = 100
        referencing_files = []

        start_time = time.time()

        for i in range(num_referencing_files):
            ref_file = temp_project_dir / f"referencing_{i:03d}.md"

            content = f"# Referencing File {i}\n\n"
            content += f"- [Popular file](popular_file.txt)\n"
            content += f'- See "popular_file.txt" for details\n'
            content += f"- Check popular_file.txt for info\n"

            # Add some additional references to create variety
            if i > 0:
                content += f"- [Previous file](referencing_{i-1:03d}.md)\n"
            if i < num_referencing_files - 1:
                content += f"- [Next file](referencing_{i+1:03d}.md)\n"

            ref_file.write_text(content)
            referencing_files.append(ref_file)

        creation_time = time.time() - start_time
        print(f"Created {num_referencing_files} referencing files in {creation_time:.2f}s")

        # Initialize service
        service = LinkWatcherService(str(temp_project_dir))

        scan_start = time.time()
        service._initial_scan()
        scan_time = time.time() - scan_start

        print(f"Scan with many references completed in {scan_time:.2f}s")

        # Verify all references were found
        target_refs = service.link_db.get_references_to_file("popular_file.txt")
        print(f"Found {len(target_refs)} references to popular_file.txt")

        assert len(target_refs) >= num_referencing_files * 2  # Multiple refs per file

        # Test moving the popular file
        new_target = temp_project_dir / "moved" / "renamed_popular.txt"
        new_target.parent.mkdir()

        move_start = time.time()
        target_file.rename(new_target)
        service.handler.on_moved(None, str(target_file), str(new_target), False)
        move_time = time.time() - move_start

        print(f"Updated {len(target_refs)} references in {move_time:.2f}s")

        # Performance should be reasonable even with many references
        assert move_time < 10.0  # Should update many references efficiently

        # Verify a sample of files were updated
        sample_files = referencing_files[:5]  # Check first 5 files
        for ref_file in sample_files:
            content = ref_file.read_text()
            assert "moved/renamed_popular.txt" in content
            assert "popular_file.txt" not in content

    @pytest.mark.slow
    def test_ph_005_rapid_file_operations(self, temp_project_dir):
        """
        PH-005: Rapid file operations

        Test Case: Batch move operations
        Expected: All operations processed correctly
        Priority: High
        """
        # Create initial file structure
        num_files = 50
        files = []

        # Create source directory
        src_dir = temp_project_dir / "src"
        src_dir.mkdir()

        for i in range(num_files):
            file_path = src_dir / f"file_{i:02d}.txt"
            content = f"File {i} content\n"

            # Add cross-references
            for j in range(min(3, num_files)):
                if j != i:
                    content += f"Reference to file_{j:02d}.txt\n"

            file_path.write_text(content)
            files.append(file_path)

        # Create destination directory
        dest_dir = temp_project_dir / "dest"
        dest_dir.mkdir()

        # Initialize service
        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        # Perform rapid file moves
        start_time = time.time()

        for i, file_path in enumerate(files):
            new_path = dest_dir / f"moved_{i:02d}.txt"

            # Move file
            file_path.rename(new_path)

            # Process move event immediately
            service.handler.on_moved(None, str(file_path), str(new_path), False)

            # Small delay to simulate real-world timing
            time.sleep(0.01)

        total_time = time.time() - start_time
        avg_time_per_move = total_time / num_files

        print(f"Processed {num_files} rapid moves in {total_time:.2f}s")
        print(f"Average time per move: {avg_time_per_move:.3f}s")

        # Performance requirements
        assert total_time < 30.0  # Should handle rapid operations
        assert avg_time_per_move < 0.5  # Each move should be fast

        # Verify all references were updated correctly
        for i in range(num_files):
            moved_file = dest_dir / f"moved_{i:02d}.txt"
            content = moved_file.read_text()

            # Should reference other moved files
            for j in range(min(3, num_files)):
                if j != i:
                    # References should be updated to new locations
                    assert f"moved_{j:02d}.txt" in content or f"dest/moved_{j:02d}.txt" in content
                    assert f"file_{j:02d}.txt" not in content


class TestPerformanceMetrics:
    """Tests for performance monitoring and metrics."""

    def test_memory_usage_monitoring(self, temp_project_dir):
        """Monitor memory usage during operations."""
        import os

        import psutil

        # Get current process
        process = psutil.Process(os.getpid())

        # Measure initial memory
        initial_memory = process.memory_info().rss / 1024 / 1024  # MB

        # Create moderate-sized project
        num_files = 200
        for i in range(num_files):
            file_path = temp_project_dir / f"file_{i:03d}.md"
            content = f"# File {i}\n\n"

            # Add references
            for j in range(min(5, num_files)):
                if j != i:
                    content += f"- [File {j}](file_{j:03d}.md)\n"

            file_path.write_text(content)

        # Initialize service and scan
        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        # Measure memory after scan
        after_scan_memory = process.memory_info().rss / 1024 / 1024  # MB
        memory_increase = after_scan_memory - initial_memory

        print(f"Memory usage: {initial_memory:.1f}MB → {after_scan_memory:.1f}MB")
        print(f"Memory increase: {memory_increase:.1f}MB for {num_files} files")

        # Memory usage should be reasonable
        assert memory_increase < 100  # Should not use excessive memory

        # Perform some operations and check for memory leaks
        for i in range(10):
            # Move a file
            old_file = temp_project_dir / f"file_{i:03d}.md"
            new_file = temp_project_dir / f"moved_{i:03d}.md"

            old_file.rename(new_file)
            service.handler.on_moved(None, str(old_file), str(new_file), False)

        # Check memory after operations
        final_memory = process.memory_info().rss / 1024 / 1024  # MB
        operation_memory_change = final_memory - after_scan_memory

        print(f"Memory after operations: {final_memory:.1f}MB")
        print(f"Memory change during operations: {operation_memory_change:.1f}MB")

        # Should not have significant memory leaks
        assert abs(operation_memory_change) < 20  # Small changes are acceptable

    def test_cpu_usage_monitoring(self, temp_project_dir):
        """Monitor CPU usage during intensive operations."""
        import threading
        import time

        import psutil

        # CPU monitoring function
        cpu_samples = []
        monitoring = True

        def monitor_cpu():
            while monitoring:
                cpu_samples.append(psutil.cpu_percent(interval=0.1))

        # Start CPU monitoring
        monitor_thread = threading.Thread(target=monitor_cpu)
        monitor_thread.start()

        try:
            # Create project and perform intensive operations
            num_files = 100

            # Create files
            for i in range(num_files):
                file_path = temp_project_dir / f"file_{i:03d}.md"
                content = f"# File {i}\n\n"

                # Add many references
                for j in range(min(10, num_files)):
                    if j != i:
                        content += f"- [File {j}](file_{j:03d}.md)\n"
                        content += f'- See "file_{j:03d}.md" for details\n'

                file_path.write_text(content)

            # Initialize and scan
            service = LinkWatcherService(str(temp_project_dir))
            service._initial_scan()

            # Perform multiple file operations
            for i in range(20):
                old_file = temp_project_dir / f"file_{i:03d}.md"
                new_file = temp_project_dir / f"moved_{i:03d}.md"

                old_file.rename(new_file)
                service.handler.on_moved(None, str(old_file), str(new_file), False)

        finally:
            # Stop monitoring
            monitoring = False
            monitor_thread.join()

        # Analyze CPU usage
        if cpu_samples:
            avg_cpu = sum(cpu_samples) / len(cpu_samples)
            max_cpu = max(cpu_samples)

            print(f"CPU usage - Average: {avg_cpu:.1f}%, Peak: {max_cpu:.1f}%")

            # CPU usage should be reasonable
            assert avg_cpu < 80  # Should not consistently use too much CPU
            assert max_cpu < 95  # Should not max out CPU
