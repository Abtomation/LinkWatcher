#!/usr/bin/env python3
"""
Test script to verify the file move issue is fixed.
This reproduces the scenario from the user's log.
"""

import os
import shutil
import tempfile
import time
from pathlib import Path

from linkwatcher.database import LinkDatabase
from linkwatcher.handler import LinkMaintenanceHandler
from linkwatcher.parser import LinkParser
from linkwatcher.updater import LinkUpdater


def test_move_issue_fix():
    """Test the specific move issue reported by the user."""

    # Create a temporary directory structure
    with tempfile.TemporaryDirectory() as temp_dir:
        temp_path = Path(temp_dir)

        # Create directory structure
        test_project_dir = temp_path / "test_project"
        test_project_dir.mkdir()

        # Create test files
        file1_path = temp_path / "tests/file1.txt"
        file1_path.write_text("This is file1 content")

        # Create a markdown file with a link to manual_markdown_tests/test_project/file1.txt     md_file = temp_path / "test.md"
        md_file.write_text("[Link to file1](file1.txt)")

        # Initialize components
        link_db = LinkDatabase()
        parser = LinkParser()
        updater = LinkUpdater(str(temp_path))
        handler = LinkMaintenanceHandler(link_db, parser, updater, str(temp_path))

        # Initial scan
        print("=== Initial scan ===")
        references = parser.parse_file(str(md_file))
        for ref in references:
            ref.file_path = "test.md"  # Set relative path
            link_db.add_link(ref)
            print(f"Added reference: {ref.file_path} -> {ref.link_target}")

        # Verify initial state
        refs = link_db.get_references_to_file("manual_markdown_tests/test_project/documentation/file1.txt")
        print(f"Initial references to file1.txt: {len(refs)}")
        assert len(refs) == 1, f"Expected 1 reference, got {len(refs)}"

        # Move 1: manual_markdown_tests/test_project/documentation/file1.txt-> test_project/file1.txt
        print("\n=== Move 1: file1.txt -> test_project/file1.txt ===")
        new_path = test_project_dir / "manual_markdown_tests/test_project/documentation/file1.txt"
        shutil.move(str(file1_path), str(new_path))

        # Simulate the move event
        class MockMoveEvent:
            def __init__(self, src, dest):
                self.src_path = src
                self.dest_path = dest
                self.is_directory = False

        move_event = MockMoveEvent(str(file1_path), str(new_path))
        handler._handle_file_moved(move_event)

        # Check references after first move
        refs_old = link_db.get_references_to_file("manual_markdown_tests/test_project/documentation/file1.txt")
        refs_new = link_db.get_references_to_file("test_project/file1.txt")
        print(f"References to old path 'manual_markdown_tests/test_project/documentation/file1.txt: {len(refs_old)}")
        print(f"References to new path 'test_project/file1.txt': {len(refs_new)}")

        # Move 2: test_project/file1.txt -> manual_markdown_tests/test_project/documentation/file1.txt(back to original)
        print("\n=== Move 2: test_project/file1.txt -> file1.txt ===")
        file1_back = temp_path / "manual_markdown_tests/test_project/documentation/file1.txt"
        shutil.move(str(new_path), str(file1_back))

        move_event2 = MockMoveEvent(str(new_path), str(file1_back))
        handler._handle_file_moved(move_event2)

        # Check references after second move - this should work now!
        refs_old2 = link_db.get_references_to_file("test_project/file1.txt")
        refs_new2 = link_db.get_references_to_file("manual_markdown_tests/test_project/documentation/file1.txt")
        print(f"References to old path 'test_project/file1.txt': {len(refs_old2)}")
        print(f"References to new path 'manual_markdown_tests/test_project/documentation/file1.txt: {len(refs_new2)}")

        # The fix should ensure we can still find references
        assert len(refs_new2) > 0, "Should find references to file1.txt after move back"

        print("\n✅ Test passed! The move issue has been fixed.")


if __name__ == "__main__":
    test_move_issue_fix()
