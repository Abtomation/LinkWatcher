#!/usr/bin/env python3
"""
Test script to verify the specific move sequence issue is fixed.
This reproduces the exact scenario from the user's log.
"""

import os
import shutil
import tempfile
from pathlib import Path

from linkwatcher.database import LinkDatabase
from linkwatcher.handler import LinkMaintenanceHandler
from linkwatcher.models import LinkReference
from linkwatcher.parser import LinkParser
from linkwatcher.updater import LinkUpdater


def test_move_sequence():
    """Test the specific move sequence that was failing."""

    # Create a temporary directory structure
    with tempfile.TemporaryDirectory() as temp_dir:
        temp_path = Path(temp_dir)

        # Create directory structure
        test_project_dir = temp_path / "test_project"
        test_project_dir.mkdir()

        # Create test files
        file1_path = test_project_dir / "tests/file1.txt
        file1_path.write_text("This is file1 content")

        # Create markdown files with links
        md_file1 = temp_path / "test1.md"
        md_file1.write_text("[Link to file1](test_project/file1.txt)")

        md_file2 = temp_path / "test2.md"
        md_file2.write_text("[Another link](test_project/file1.txt)")

        # Initialize components
        link_db = LinkDatabase()
        parser = LinkParser()
        updater = LinkUpdater(str(temp_path))
        handler = LinkMaintenanceHandler(link_db, parser, updater, str(temp_path))

        # Initial scan
        print("=== Initial scan ===")
        for md_file in [md_file1, md_file2]:
            references = parser.parse_file(str(md_file))
            for ref in references:
                ref.file_path = md_file.name  # Set relative path
                link_db.add_link(ref)
                print(f"Added reference: {ref.file_path} -> {ref.link_target}")

        # Verify initial state
        refs = link_db.get_references_to_file("test_project/file1.txt")
        print(f"Initial references to test_project/file1.txt: {len(refs)}")
        assert len(refs) == 2, f"Expected 2 references, got {len(refs)}"

        # Mock move event class
        class MockMoveEvent:
            def __init__(self, src, dest):
                self.src_path = src
                self.dest_path = dest
                self.is_directory = False

        # Move 1: test_project/file1.txt -> manual_markdown_tests/test_project/file1.txt        print("\n=== Move 1: test_project/file1.txt -> file1.txt ===")
        new_path1 = temp_path / "manual_markdown_tests/test_project/documentation/file1.txt
        shutil.move(str(file1_path), str(new_path1))

        move_event1 = MockMoveEvent(str(file1_path), str(new_path1))
        handler._handle_file_moved(move_event1)

        # Check references after first move
        refs_old1 = link_db.get_references_to_file("test_project/file1.txt")
        refs_new1 = link_db.get_references_to_file("manual_markdown_tests/test_project/documentation/file1.txt)
        print(f"References to old path 'test_project/file1.txt': {len(refs_old1)}")
        print(f"References to new path 'manual_markdown_tests/test_project/documentation/file1.txt: {len(refs_new1)}")
        assert len(refs_new1) == 2, f"Expected 2 references to file1.txt, got {len(refs_new1)}"

        # Move 2: manual_markdown_tests/test_project/documentation/file1.txt-> test_project/file1.txt (back)
        print("\n=== Move 2: file1.txt -> test_project/file1.txt ===")
        file1_back = test_project_dir / "manual_markdown_tests/test_project/documentation/file1.txt
        shutil.move(str(new_path1), str(file1_back))

        move_event2 = MockMoveEvent(str(new_path1), str(file1_back))
        handler._handle_file_moved(move_event2)

        # Check references after second move
        refs_old2 = link_db.get_references_to_file("manual_markdown_tests/test_project/documentation/file1.txt)
        refs_new2 = link_db.get_references_to_file("test_project/file1.txt")
        print(f"References to old path 'manual_markdown_tests/test_project/documentation/file1.txt: {len(refs_old2)}")
        print(f"References to new path 'test_project/file1.txt': {len(refs_new2)}")
        assert len(refs_new2) == 2, f"Expected 2 references to test_project/file1.txt, got {len(refs_new2)}"

        # Move 3: test_project/file1.txt -> test_project/file3.txt (rename within directory)
        print("\n=== Move 3: test_project/file1.txt -> test_project/file3.txt ===")
        file3_path = test_project_dir / "manual_markdown_tests/test_project/documentation/file1.txt
        shutil.move(str(file1_back), str(file3_path))

        move_event3 = MockMoveEvent(str(file1_back), str(file3_path))
        handler._handle_file_moved(move_event3)

        # Check references after third move - THIS WAS FAILING BEFORE THE FIX
        refs_old3 = link_db.get_references_to_file("test_project/file1.txt")
        refs_new3 = link_db.get_references_to_file("test_project/file3.txt")
        print(f"References to old path 'test_project/file1.txt': {len(refs_old3)}")
        print(f"References to new path 'test_project/file3.txt': {len(refs_new3)}")
        assert len(refs_new3) == 2, f"Expected 2 references to test_project/file3.txt, got {len(refs_new3)}"

        # Move 4: test_project/file3.txt -> test_project/file1.txt (rename back)
        print("\n=== Move 4: test_project/file3.txt -> test_project/file1.txt ===")
        file1_final = test_project_dir / "manual_markdown_tests/test_project/documentation/file1.txt
        shutil.move(str(file3_path), str(file1_final))

        move_event4 = MockMoveEvent(str(file3_path), str(file1_final))
        handler._handle_file_moved(move_event4)

        # Check references after fourth move - THIS WAS ALSO FAILING BEFORE THE FIX
        refs_old4 = link_db.get_references_to_file("test_project/file3.txt")
        refs_new4 = link_db.get_references_to_file("test_project/file1.txt")
        print(f"References to old path 'test_project/file3.txt': {len(refs_old4)}")
        print(f"References to new path 'test_project/file1.txt': {len(refs_new4)}")
        assert len(refs_new4) == 2, f"Expected 2 references to test_project/file1.txt, got {len(refs_new4)}"

        print("\n✅ All move sequences work correctly! The issue has been fixed.")


if __name__ == "__main__":
    test_move_sequence()
