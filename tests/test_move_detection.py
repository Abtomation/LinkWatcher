#!/usr/bin/env python3
"""
Test script to verify the enhanced move detection logic.
"""

import os
import tempfile
import time
from pathlib import Path

from linkwatcher.database import LinkDatabase
from linkwatcher.handler import LinkMaintenanceHandler
from linkwatcher.parser import LinkParser
from linkwatcher.updater import LinkUpdater


def test_move_detection_logic():
    """Test the move detection logic directly."""

    # Create a temporary test directory
    with tempfile.TemporaryDirectory() as temp_dir:
        temp_path = Path(temp_dir)

        # Create test structure
        test_file = temp_path / "../manual_markdown_tests/test_project/documentatio/file1.txt"
        test_file.write_text("Test content")

        docs_dir = temp_path / "documentation"
        docs_dir.mkdir()

        # Create a markdown file that references the test file
        md_file = temp_path / "test.md"
        md_file.write_text("# Test\n\nSee [file](../manual_markdown_tests/tests/documentation/file1.txtt for details.")

        # Initialize components
        link_db = LinkDatabase()
        parser = LinkParser()
        updater = LinkUpdater(str(temp_path))
        handler = LinkMaintenanceHandler(link_db, parser, updater, str(temp_path))

        # Scan initial files
        print("Scanning initial files...")
        for file_path in temp_path.rglob("*"):
            if file_path.is_file() and file_path.suffix in {".md", ".txt"}:
                rel_path = str(file_path.relative_to(temp_path)).replace("\\", "/")
                references = parser.parse_file(str(file_path))
                for ref in references:
                    ref.file_path = rel_path
                    link_db.add_link(ref)

        print("Initial references:")
        refs = link_db.get_references_to_file("../manual_markdown_tests/test_project/documentatio/file1.txt")
        for ref in refs:
            print(f"  {ref.file_path}:{ref.line_number} - {ref.link_text}")

        # Test the move detection logic
        print("\nTesting move detection logic...")

        # Simulate delete event
        created_path = "documentation/file1.txt"
        created_abs_path = str(docs_dir / "../manual_markdown_tests/test_project/documentatio/file1.txt")

        # Add to pending deletes (simulate delete event)
        handler.pending_deletes["../manual_markdown_tests/test_project/documentatio/file1.txt] = (time.time(), 12)  # 12 bytes for "Test content"

        # Create the file
        new_file = docs_dir / "../manual_markdown_tests/test_project/documentatio/file1.txt"
        new_file.write_text("Test content")

        # Test move detection
        detected_source = handler._detect_potential_move(created_path, created_abs_path)

        if detected_source:
            print(f"✅ Move detected! Source: {detected_source}")

            # Test the move handling
            handler._handle_detected_move(detected_source, created_path)

            # Check if reference was updated
            updated_content = md_file.read_text()
            print(f"Updated content: {updated_content}")

            if "documentation/file1.txt" in updated_content:
                print("✅ Move handling worked! Reference was updated.")
            else:
                print("❌ Move handling failed. Reference was not updated.")
        else:
            print("❌ Move detection failed.")


if __name__ == "__main__":
    test_move_detection_logic()
