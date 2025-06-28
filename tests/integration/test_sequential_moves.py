"""
Integration Tests for Sequential File Movement Issues

This module tests the specific issue where sequential file moves cause the database
to lose track of references after the first few moves.

Test Cases Implemented:
- SM-001: Sequential moves between directories
- SM-002: Sequential renames within same directory after moves
- SM-003: Mixed moves and renames in complex sequence
"""

import time
from pathlib import Path

import pytest
from watchdog.events import FileMovedEvent

from linkwatcher.service import LinkWatcherService


class TestSequentialMoves:
    """Integration tests for sequential file movement scenarios."""

    def test_sm_001_sequential_directory_moves(self, temp_project_dir, file_helper):
        """
        SM-001: Sequential moves between directories

        Test Case: Reproduce the exact issue from user log:
        1. test_project/file1.txt → file1.txt (works)
        2. file1.txt → test_project/file1.txt (works)
        3. test_project/file1.txt → test_project/documentation/file1.txt (fails - finds 0 references)
        4. test_project/documentation/file1.txt → test_project/file1.txt (fails - finds 0 references)

        Expected: All moves should find and update references correctly
        Priority: Critical
        """
        # Setup directory structure
        test_project_dir = temp_project_dir / "test_project"
        documentation_dir = test_project_dir / "documentation"
        test_project_dir.mkdir()
        documentation_dir.mkdir()

        # Create the target file
        original_file = test_project_dir / "../../manual_markdown_tests/test_project/documentatio/file1.txt"
        original_file.write_text("This is file1 content")

        # Create files with references to the target file
        md_file1 = temp_project_dir / "doc1.md"
        md_file1.write_text("""# Documentation 1

See [file1](test_project/file1.txt) for details.
Also check test_project/file1.txt for more info.
""")

        md_file2 = temp_project_dir / "doc2.md"
        md_file2.write_text("""# Documentation 2

Reference: test_project/file1.txt
Link: [file1](test_project/file1.txt)
""")

        yaml_file = temp_project_dir / "config.yaml"
        yaml_file.write_text("""
settings:
  help_file: test_project/file1.txt
  reference: "test_project/file1.txt"
""")

        # Initialize service and perform initial scan
        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        # Verify initial state - should find references to test_project/file1.txt
        initial_refs = service.link_db.get_references_to_file("test_project/file1.txt")
        print(f"Initial references to test_project/file1.txt: {len(initial_refs)}")
        assert len(initial_refs) >= 3, f"Expected at least 3 initial references, got {len(initial_refs)}"

        # Move 1: test_project/file1.txt → ../../../tests/integration/test_project/documentation/file1.txtt(should work)
        print("\n=== Move 1: test_project/file1.txt → file1.txt ===")
        move1_target = temp_project_dir / "../../manual_markdown_tests/test_project/documentatio/file1.txt"
        original_file.rename(move1_target)

        move_event1 = FileMovedEvent(str(original_file), str(move1_target))
        service.handler.on_moved(move_event1)

        # Verify move 1 results
        refs_after_move1 = service.link_db.get_references_to_file("../../manual_markdown_tests/test_project/documentatio/file1.txt")
        old_refs_after_move1 = service.link_db.get_references_to_file("test_project/file1.txt")
        print(f"After move 1 - References to file1.txt: {len(refs_after_move1)}")
        print(f"After move 1 - References to test_project/file1.txt: {len(old_refs_after_move1)}")
        assert len(refs_after_move1) >= 3, f"Move 1 failed: Expected at least 3 references to file1.txt, got {len(refs_after_move1)}"
        assert len(old_refs_after_move1) == 0, f"Move 1 failed: Old references should be 0, got {len(old_refs_after_move1)}"

        # Move 2: ../../../tests/integration/test_project/documentation/file1.txtt→ test_project/file1.txt (should work)
        print("\n=== Move 2: file1.txt → test_project/file1.txt ===")
        move2_target = test_project_dir / "../../manual_markdown_tests/test_project/documentatio/file1.txt"
        move1_target.rename(move2_target)

        move_event2 = FileMovedEvent(str(move1_target), str(move2_target))
        service.handler.on_moved(move_event2)

        # Verify move 2 results
        refs_after_move2 = service.link_db.get_references_to_file("test_project/file1.txt")
        old_refs_after_move2 = service.link_db.get_references_to_file("../../manual_markdown_tests/test_project/documentatio/file1.txt")
        print(f"After move 2 - References to test_project/file1.txt: {len(refs_after_move2)}")
        print(f"After move 2 - References to file1.txt: {len(old_refs_after_move2)}")
        assert len(refs_after_move2) >= 3, f"Move 2 failed: Expected at least 3 references to test_project/file1.txt, got {len(refs_after_move2)}"
        assert len(old_refs_after_move2) == 0, f"Move 2 failed: Old references should be 0, got {len(old_refs_after_move2)}"

        # Move 3: test_project/file1.txt → test_project/documentation/file1.txt (THIS IS WHERE IT FAILS)
        print("\n=== Move 3: test_project/file1.txt → test_project/documentation/file1.txt ===")
        move3_target = documentation_dir / "../../manual_markdown_tests/test_project/documentatio/file1.txt"
        move2_target.rename(move3_target)

        move_event3 = FileMovedEvent(str(move2_target), str(move3_target))
        service.handler.on_moved(move_event3)

        # Verify move 3 results - THIS IS THE CRITICAL TEST
        refs_after_move3 = service.link_db.get_references_to_file("test_project/documentation/file1.txt")
        old_refs_after_move3 = service.link_db.get_references_to_file("test_project/file1.txt")
        print(f"After move 3 - References to test_project/documentation/file1.txt: {len(refs_after_move3)}")
        print(f"After move 3 - References to test_project/file1.txt: {len(old_refs_after_move3)}")

        # Debug: Print database state
        print("\nDEBUG: Database state after move 3:")
        for key, refs in service.link_db.links.items():
            if "file1" in key:
                print(f"  Key: '{key}' -> {len(refs)} references")
                for r in refs:
                    print(f"    {r.file_path}:{r.line_number} -> '{r.link_target}'")

        # This should pass but currently fails
        assert len(refs_after_move3) >= 3, f"Move 3 FAILED: Expected at least 3 references to test_project/documentation/file1.txt, got {len(refs_after_move3)}"
        assert len(old_refs_after_move3) == 0, f"Move 3 FAILED: Old references should be 0, got {len(old_refs_after_move3)}"

        # Move 4: test_project/documentation/file1.txt → test_project/file1.txt (THIS ALSO FAILS)
        print("\n=== Move 4: test_project/documentation/file1.txt → test_project/file1.txt ===")
        move4_target = test_project_dir / "../../manual_markdown_tests/test_project/documentatio/file1.txt"
        move3_target.rename(move4_target)

        move_event4 = FileMovedEvent(str(move3_target), str(move4_target))
        service.handler.on_moved(move_event4)

        # Verify move 4 results
        refs_after_move4 = service.link_db.get_references_to_file("test_project/file1.txt")
        old_refs_after_move4 = service.link_db.get_references_to_file("test_project/documentation/file1.txt")
        print(f"After move 4 - References to test_project/file1.txt: {len(refs_after_move4)}")
        print(f"After move 4 - References to test_project/documentation/file1.txt: {len(old_refs_after_move4)}")

        # This should also pass but currently fails
        assert len(refs_after_move4) >= 3, f"Move 4 FAILED: Expected at least 3 references to test_project/file1.txt, got {len(refs_after_move4)}"
        assert len(old_refs_after_move4) == 0, f"Move 4 FAILED: Old references should be 0, got {len(old_refs_after_move4)}"

        print("\n✅ All sequential moves completed successfully!")

    def test_sm_002_sequential_renames_after_moves(self, temp_project_dir, file_helper):
        """
        SM-002: Sequential renames within same directory after moves

        Test Case: After moving files between directories, test renames within directory
        Expected: Renames should work correctly even after previous moves
        Priority: High
        """
        # Setup directory structure
        test_project_dir = temp_project_dir / "test_project"
        test_project_dir.mkdir()

        # Create the target file
        original_file = test_project_dir / "../../manual_markdown_tests/test_project/documentatio/file1.txt"
        original_file.write_text("This is file1 content")

        # Create file with reference
        md_file = temp_project_dir / "doc.md"
        md_file.write_text("[Link to file1](test_project/file1.txt)")

        # Initialize service and perform initial scan
        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        # Move 1: test_project/file1.txt → ../../../tests/integration/test_project/documentation/file1.txtt        move1_target = temp_project_dir / ../../manual_markdown_tests/test_project/documentation/file1.txtxt
        original_file.rename(move1_target)
        move_event1 = FileMovedEvent(str(original_file), str(move1_target))
        service.handler.on_moved(move_event1)

        # Move 2: ../../../tests/integration/test_project/documentation/file1.txtt→ test_project/file1.txt
        move2_target = test_project_dir / "../../manual_markdown_tests/test_project/documentatio/file1.txt"
        move1_target.rename(move2_target)
        move_event2 = FileMovedEvent(str(move1_target), str(move2_target))
        service.handler.on_moved(move_event2)

        # Now test rename within directory: test_project/file1.txt → ../tests/integration/file2.txt
        rename_target = test_project_dir / "file2.txt"
        move2_target.rename(rename_target)
        rename_event = FileMovedEvent(str(move2_target), str(rename_target))
        service.handler.on_moved(rename_event)

        # Verify rename worked
        refs_after_rename = service.link_db.get_references_to_file("../tests/integration/file2.txt")
        old_refs_after_rename = service.link_db.get_references_to_file("test_project/file1.txt")

        assert len(refs_after_rename) >= 1, f"Rename failed: Expected at least 1 reference to ../tests/integration/file2.txt, got {len(refs_after_rename)}"
        assert len(old_refs_after_rename) == 0, f"Rename failed: Old references should be 0, got {len(old_refs_after_rename)}"

    def test_sm_003_debug_database_state_during_moves(self, temp_project_dir, file_helper):
        """
        SM-003: Debug database state during sequential moves

        This test helps debug what's happening to the database during moves
        """
        # Setup
        test_project_dir = temp_project_dir / "test_project"
        test_project_dir.mkdir()

        original_file = test_project_dir / "../../manual_markdown_tests/test_project/documentatio/file1.txt"
        original_file.write_text("Content")

        md_file = temp_project_dir / "doc.md"
        md_file.write_text("[Link](test_project/file1.txt)")

        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        def print_db_state(stage):
            print(f"\n=== Database State - {stage} ===")
            print(f"Total database keys: {len(service.link_db.links)}")
            for key, refs in service.link_db.links.items():
                if "file1" in key:
                    print(f"  Key: '{key}' -> {len(refs)} references")
                    for r in refs:
                        print(f"    {r.file_path} -> '{r.link_target}'")

        print_db_state("Initial")

        # Move 1
        move1_target = temp_project_dir / "../../manual_markdown_tests/test_project/documentatio/file1.txt"
        original_file.rename(move1_target)
        move_event1 = FileMovedEvent(str(original_file), str(move1_target))
        service.handler.on_moved(move_event1)
        print_db_state("After Move 1")

        # Move 2
        move2_target = test_project_dir / "../../manual_markdown_tests/test_project/documentatio/file1.txt"
        move1_target.rename(move2_target)
        move_event2 = FileMovedEvent(str(move1_target), str(move2_target))
        service.handler.on_moved(move_event2)
        print_db_state("After Move 2")

        # Move 3 - This is where it breaks
        documentation_dir = test_project_dir / "documentation"
        documentation_dir.mkdir()
        move3_target = documentation_dir / "../../manual_markdown_tests/test_project/documentatio/file1.txt"
        move2_target.rename(move3_target)
        move_event3 = FileMovedEvent(str(move2_target), str(move3_target))
        service.handler.on_moved(move_event3)
        print_db_state("After Move 3")

        # Test lookups
        refs = service.link_db.get_references_to_file("test_project/documentation/file1.txt")
        print(f"\nLookup test: References to 'test_project/documentation/file1.txt': {len(refs)}")

        # This test is for debugging - it will show us what's wrong
        # We don't assert here, just observe the output


class TestSequentialMovesEdgeCases:
    """Edge cases for sequential file movements."""

    def test_multiple_files_sequential_moves(self, temp_project_dir, file_helper):
        """Test sequential moves with multiple files to ensure no cross-contamination."""
        # Setup
        test_project_dir = temp_project_dir / "test_project"
        test_project_dir.mkdir()

        # Create multiple files
        file1 = test_project_dir / "../../manual_markdown_tests/test_project/documentatio/file1.txt"
        file2 = test_project_dir / "file2.txt"
        file1.write_text("File 1 content")
        file2.write_text("File 2 content")

        # Create references
        md_file = temp_project_dir / "doc.md"
        md_file.write_text("""
[Link to file1](test_project/file1.txt)
[Link to file2](../tests/integration/file2.txt)
""")

        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        # Move file1 multiple times
        move1_target = temp_project_dir / "../../manual_markdown_tests/test_project/documentatio/file1.txt"
        file1.rename(move1_target)
        move_event1 = FileMovedEvent(str(file1), str(move1_target))
        service.handler.on_moved(move_event1)

        move1_back = test_project_dir / "../../manual_markdown_tests/test_project/documentatio/file1.txt"
        move1_target.rename(move1_back)
        move_event1_back = FileMovedEvent(str(move1_target), str(move1_back))
        service.handler.on_moved(move_event1_back)

        # Now move file2 - this should still work
        move2_target = temp_project_dir / "file2.txt"
        file2.rename(move2_target)
        move_event2 = FileMovedEvent(str(file2), str(move2_target))
        service.handler.on_moved(move_event2)

        # Verify both files have correct references
        refs1 = service.link_db.get_references_to_file("test_project/file1.txt")
        refs2 = service.link_db.get_references_to_file("file2.txt")

        assert len(refs1) >= 1, f"File1 references lost: got {len(refs1)}"
        assert len(refs2) >= 1, f"File2 references lost: got {len(refs2)}"
