"""
Test suite to verify the enhanced move detection logic.

Tests the internal _detect_potential_move and _handle_detected_move methods
of the LinkMaintenanceHandler to ensure move operations are correctly
detected from paired delete+create events and that references are updated.
"""

import time
from pathlib import Path

import pytest

from linkwatcher.database import LinkDatabase
from linkwatcher.handler import LinkMaintenanceHandler
from linkwatcher.parser import LinkParser
from linkwatcher.updater import LinkUpdater


class TestMoveDetectionLogic:
    """Tests for the move detection logic in the handler."""

    @pytest.fixture
    def project_setup(self, tmp_path):
        """Set up a test project with handler components."""
        # Create test structure
        test_file = tmp_path / "file1.txt"
        test_file.write_text("Test content")

        docs_dir = tmp_path / "documentation"
        docs_dir.mkdir()

        # Create a markdown file that references the test file
        md_file = tmp_path / "test.md"
        md_file.write_text("# Test\n\nSee [file](file1.txt) for details.")

        # Initialize components
        link_db = LinkDatabase()
        parser = LinkParser()
        updater = LinkUpdater(str(tmp_path))
        handler = LinkMaintenanceHandler(link_db, parser, updater, str(tmp_path))

        # Scan initial files
        for file_path in tmp_path.rglob("*"):
            if file_path.is_file() and file_path.suffix in {".md", ".txt"}:
                rel_path = str(file_path.relative_to(tmp_path)).replace("\\", "/")
                references = parser.parse_file(str(file_path))
                for ref in references:
                    ref.file_path = rel_path
                    link_db.add_link(ref)

        return {
            "tmp_path": tmp_path,
            "test_file": test_file,
            "docs_dir": docs_dir,
            "md_file": md_file,
            "link_db": link_db,
            "parser": parser,
            "updater": updater,
            "handler": handler,
        }

    def test_initial_references_found(self, project_setup):
        """Verify that the initial scan finds the expected references."""
        link_db = project_setup["link_db"]
        refs = link_db.get_references_to_file("file1.txt")
        assert len(refs) >= 1, f"Expected at least 1 reference to file1.txt, got {len(refs)}"

    def test_move_detection_identifies_paired_delete_create(self, project_setup):
        """Test that _detect_potential_move correctly pairs a delete with a create."""
        handler = project_setup["handler"]
        docs_dir = project_setup["docs_dir"]

        created_path = "documentation/file1.txt"
        created_abs_path = str(docs_dir / "file1.txt")

        # Add to pending deletes (simulate delete event)
        handler.pending_deletes["file1.txt"] = (time.time(), 12)  # 12 bytes for "Test content"

        # Create the file at the new location
        new_file = docs_dir / "file1.txt"
        new_file.write_text("Test content")

        # Test move detection
        detected_source = handler._detect_potential_move(created_path, created_abs_path)

        assert detected_source is not None, "Move detection should have found a matching delete"
        assert (
            detected_source == "file1.txt"
        ), f"Expected source 'file1.txt', got '{detected_source}'"

    def test_handle_detected_move_updates_references(self, project_setup):
        """Test that _handle_detected_move correctly updates file references."""
        handler = project_setup["handler"]
        docs_dir = project_setup["docs_dir"]
        md_file = project_setup["md_file"]
        link_db = project_setup["link_db"]

        created_path = "documentation/file1.txt"
        created_abs_path = str(docs_dir / "file1.txt")

        # Add to pending deletes (simulate delete event)
        handler.pending_deletes["file1.txt"] = (time.time(), 12)

        # Create the file at the new location
        new_file = docs_dir / "file1.txt"
        new_file.write_text("Test content")

        # Detect the move
        detected_source = handler._detect_potential_move(created_path, created_abs_path)
        assert detected_source is not None, "Move should have been detected"

        # Handle the detected move
        handler._handle_detected_move(detected_source, created_path)

        # Check if reference was updated in the markdown file
        updated_content = md_file.read_text()
        assert "documentation/file1.txt" in updated_content, (
            f"Reference should be updated to 'documentation/file1.txt', "
            f"but content is: {updated_content}"
        )

    def test_no_false_positive_without_pending_delete(self, project_setup):
        """Test that move detection does not fire without a matching pending delete."""
        handler = project_setup["handler"]
        docs_dir = project_setup["docs_dir"]

        created_path = "documentation/file1.txt"
        created_abs_path = str(docs_dir / "file1.txt")

        # Do NOT add any pending deletes

        # Create the file
        new_file = docs_dir / "file1.txt"
        new_file.write_text("Test content")

        # Move detection should return None
        detected_source = handler._detect_potential_move(created_path, created_abs_path)
        assert detected_source is None, "Should not detect a move without a matching delete"
