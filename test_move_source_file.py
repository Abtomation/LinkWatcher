#!/usr/bin/env python3
"""
Test script to verify the fix for updating links within moved files.
This tests the specific scenario where a file CONTAINING links is moved.
"""

import os
import shutil
import tempfile
from pathlib import Path

from linkwatcher import LinkWatcherService


def test_move_file_containing_links():
    """Test moving a file that contains relative links."""

    # Create a temporary directory for testing
    with tempfile.TemporaryDirectory() as temp_dir:
        temp_path = Path(temp_dir)

        # Create test structure
        # temp_dir/
        #   ├── manual_markdown_tests/test_project/file1.txt       #   ├── file2.txt
        #   ├── test_file.md (contains links to manual_markdown_tests/test_project/documentation/file1.txtand file2.txt)
        #   └── subdir/
        #       └── (we'll move test_file.md here)

        # Create target files
        file1 = temp_path / "manual_markdown_tests/test_project/documentation/file1.txt
        file2 = temp_path / "file2.txt"
        file1.write_text("Content of file1")
        file2.write_text("Content of file2")

        # Create source file with relative links
        test_file = temp_path / "test_file.md"
        test_content = """# Test File

This file contains relative links:

- [File 1](file1.txt)
- [File 2](file2.txt)
- [File 1 again](./file1.txt)

These links should be updated when the file is moved.
"""
        test_file.write_text(test_content)

        # Create subdirectory
        subdir = temp_path / "subdir"
        subdir.mkdir()

        print(f"Created test structure in: {temp_path}")
        print(f"Original content of test_file.md:")
        print(test_file.read_text())

        # Initialize LinkWatcher service
        service = LinkWatcherService(str(temp_path))
        service._initial_scan()

        print(f"\nInitial scan complete. Database contains:")
        stats = service.link_db.get_stats()
        print(f"  Files with links: {stats['files_with_links']}")
        print(f"  Total references: {stats['total_references']}")

        # Move the file to subdirectory
        new_location = subdir / "test_file.md"
        print(f"\nMoving {test_file} to {new_location}")

        # Simulate the move operation
        old_path = str(test_file)
        new_path = str(new_location)

        # Actually move the file
        shutil.move(old_path, new_path)

        # Create a synthetic move event
        class MockMoveEvent:
            def __init__(self, src, dest):
                self.src_path = src
                self.dest_path = dest
                self.is_directory = False

        # Process the move event
        move_event = MockMoveEvent(old_path, new_path)
        service.handler._handle_file_moved(move_event)

        # Check the updated content
        print(f"\nAfter move, content of test_file.md:")
        updated_content = Path(new_path).read_text()
        print(updated_content)

        # Verify the links were updated correctly
        # From subdir/, manual_markdown_tests/test_project/documentation/file1.txtshould be ../file1.txt
        expected_updates = [
            "[File 1](../file1.txt)",
            "[File 2](../file2.txt)",
            "[File 1 again](../file1.txt)"
        ]

        success = True
        for expected in expected_updates:
            if expected in updated_content:
                print(f"✓ Found expected update: {expected}")
            else:
                print(f"✗ Missing expected update: {expected}")
                success = False

        # Check that old links are gone
        old_patterns = ["](file1.txt)", "](./file1.txt)", "](file2.txt)"]
        for old_pattern in old_patterns:
            if old_pattern in updated_content:
                print(f"✗ Old pattern still present: {old_pattern}")
                success = False
            else:
                print(f"✓ Old pattern correctly removed: {old_pattern}")

        if success:
            print(f"\n🎉 SUCCESS: All links were updated correctly!")
        else:
            print(f"\n❌ FAILURE: Some links were not updated correctly!")

        return success


if __name__ == "__main__":
    test_move_file_containing_links()
