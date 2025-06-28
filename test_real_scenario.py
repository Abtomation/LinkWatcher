#!/usr/bin/env python3
"""
Test the real scenario: LR-002_relative_links.md moved from manual_markdown_tests/
to manual_markdown_tests/test_project/ and links need to be updated.
"""

import os
import shutil
from pathlib import Path

from linkwatcher import LinkWatcherService


def test_real_scenario():
    """Test the real scenario that was reported."""

    # Set up the project root
    project_root = Path("c:/Users/ronny/VS_Code/LinkWatcher")

    # Path to the file that needs fixing
    file_path = project_root / "manual_markdown_tests" / "test_project" / "LR-002_relative_links.md"

    if not file_path.exists():
        print(f"❌ File not found: {file_path}")
        return False

    print(f"📁 Testing file: {file_path}")
    print(f"📄 Original content:")
    original_content = file_path.read_text()
    print(original_content)

    # Initialize LinkWatcher service
    service = LinkWatcherService(str(project_root))

    # Simulate the move that already happened:
    # From: manual_markdown_tests/LR-002_relative_links.mdtive_links.mdon/LR-002_relative_links.mdtive_links.md
    # To: manual_markdown_tests/test_project/LR-002_relative_links.md
    old_path = "manual_markdown_tests/LR-002_relative_links.mdtive_links.mdon/LR-002_relative_links.mdtive_links.md"
    new_path = "manual_markdown_tests/test_project/LR-002_relative_links.md"

    print(f"\n🔧 Simulating move: {old_path} → {new_path}")

    # Create a synthetic move event
    class MockMoveEvent:
        def __init__(self, src, dest):
            self.src_path = str(project_root / src)
            self.dest_path = str(project_root / dest)
            self.is_directory = False

    # Process the move event with our fix
    move_event = MockMoveEvent(old_path, new_path)
    service.handler._handle_file_moved(move_event)

    # Check the updated content
    print(f"\n📄 Updated content:")
    updated_content = file_path.read_text()
    print(updated_content)

    # Verify the expected changes
    expected_changes = [
        ("test_project/file1.txt", "tests/file1.txt"),
        ("test_project/file2.txt", "file2.txt"),
        ("test_project/root.txt", "root.txt"),
        ("test_project/config/settings.yaml", "config/settings.yaml"),
        ("test_project/api/reference.txt", "api/reference.txt"),
        ("test_project/assets/logo.png", "assets/logo.png"),
        ("test_project/inline.txt", "inline.txt"),
        ("./test_project/docs/readme.md", "./docs/readme.md")
    ]

    success = True
    for old_link, new_link in expected_changes:
        if old_link in updated_content:
            print(f"❌ Old link still present: {old_link}")
            success = False
        elif new_link in updated_content:
            print(f"✅ Successfully updated: {old_link} → {new_link}")
        else:
            print(f"⚠️  Neither old nor new link found: {old_link} → {new_link}")

    if success:
        print(f"\n🎉 SUCCESS: All links were updated correctly!")
    else:
        print(f"\n❌ FAILURE: Some links were not updated correctly!")

    return success


if __name__ == "__main__":
    test_real_scenario()
