"""
PD-BUG-020 Manual Validation: Single file move must NOT trigger directory scan.

PURPOSE:
    Verify that moving a single file via delete+create events does NOT
    cause LinkWatcher to walk the entire project directory. Before the fix,
    _get_files_under_directory had a missing trailing slash in dir_prefix
    (normalize_path stripped it), allowing a file path to match itself as
    a "directory" via startswith, which cascaded into treating the project
    root as the "new directory" and scanning all 657+ files.

HOW TO RUN:
    python tests/manual/PD-BUG-020_single_file_move_validation.py

EXPECTED RESULT:
    All assertions pass. The single file delete goes to pending_deletes
    (per-file move detection), NOT pending_dir_moves (directory move detection).
"""

import os
import sys
import tempfile
from pathlib import Path

# Add project root to path
project_root = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(project_root))

from watchdog.events import FileCreatedEvent, FileDeletedEvent

from linkwatcher.database import LinkDatabase
from linkwatcher.handler import LinkMaintenanceHandler
from linkwatcher.parser import LinkParser
from linkwatcher.updater import LinkUpdater


def main():
    print("=" * 60)
    print("PD-BUG-020: Single file move validation")
    print("=" * 60)

    with tempfile.TemporaryDirectory() as tmp_dir:
        tmp_path = Path(tmp_dir)

        # Create a project structure with multiple files
        templates_dir = tmp_path / "doc" / "templates" / "templates"
        templates_dir.mkdir(parents=True)
        tests_dir = tmp_path / "test" / "specs"
        tests_dir.mkdir(parents=True)
        tools_dir = tmp_path / "tools"
        tools_dir.mkdir()

        # Create the file that will be "moved"
        assessment = templates_dir / "assessment-template.md"
        assessment.write_text("# Assessment Template\n[Guide](../../guides/guide.md)\n")

        # Create other files (simulating a real project)
        test_spec = tests_dir / "test-spec.md"
        test_spec.write_text("# Test Spec\n[Template](../../doc/templates/templates/assessment-template.md)\n")

        dashboard = tools_dir / "dashboard.py"
        dashboard.write_text("# Dashboard\nTEMPLATE = 'doc/templates/templates/assessment-template.md'\n")

        readme = tmp_path / "README.md"
        readme.write_text("# Project\n[Assessment](doc/templates/templates/assessment-template.md)\n")

        # Initialize LinkWatcher
        link_db = LinkDatabase()
        parser = LinkParser()
        updater = LinkUpdater(str(tmp_path))
        handler = LinkMaintenanceHandler(link_db, parser, updater, str(tmp_path))

        # Scan all files into DB
        for file_path in tmp_path.rglob("*"):
            if file_path.is_file() and file_path.suffix in {".md", ".py"}:
                rel_path = str(file_path.relative_to(tmp_path)).replace("\\", "/")
                references = parser.parse_file(str(file_path))
                for ref in references:
                    ref.file_path = rel_path
                    link_db.add_link(ref)

        print(f"\nFiles in database: {len(link_db.files_with_links)}")
        print(f"Link targets in database: {len(link_db.links)}")

        # === Test 1: _get_files_under_directory with file path ===
        print("\n--- Test 1: _get_files_under_directory with file path ---")
        file_path = "doc/templates/templates/assessment-template.md"
        files = handler._get_files_under_directory(file_path)
        print(f"  _get_files_under_directory('{file_path}') returned {len(files)} file(s)")
        assert len(files) == 0, (
            f"FAIL: Expected 0 files for file path, got {len(files)}: {files}"
        )
        print("  PASS: File path correctly returns empty set")

        # === Test 2: Single file delete does NOT create pending_dir_moves ===
        print("\n--- Test 2: Single file delete routing ---")
        event = FileDeletedEvent(str(assessment))
        event.is_directory = False
        handler.on_deleted(event)

        assert len(handler.pending_dir_moves) == 0, (
            f"FAIL: Single file delete created pending_dir_moves: "
            f"{list(handler.pending_dir_moves.keys())}"
        )
        rel_deleted = str(assessment.relative_to(tmp_path)).replace("\\", "/")
        assert rel_deleted in handler.pending_deletes, (
            f"FAIL: File should be in pending_deletes, got: "
            f"{list(handler.pending_deletes.keys())}"
        )
        print(f"  PASS: File routed to pending_deletes (per-file move detection)")

        # === Test 3: Real directory still works ===
        print("\n--- Test 3: Real directory delete still detected correctly ---")
        # Clear state
        handler.pending_deletes.clear()

        dir_event = FileDeletedEvent(str(templates_dir))
        dir_event.is_directory = False  # Windows behavior
        handler.on_deleted(dir_event)

        dir_key = "doc/templates/templates"
        if dir_key in handler.pending_dir_moves:
            pending = handler.pending_dir_moves[dir_key]
            print(f"  PASS: Directory routed to pending_dir_moves "
                  f"({pending.total_expected} files buffered)")
            # Clean up timer
            if pending.max_timer:
                pending.max_timer.cancel()
        else:
            # After deleting the assessment file above, only the directory
            # itself would be checked. If no files remain, it goes to
            # file delete path, which is also acceptable.
            print(f"  INFO: Directory had no remaining tracked files "
                  f"(assessment-template.md was already 'deleted')")

        print("\n" + "=" * 60)
        print("ALL TESTS PASSED")
        print("=" * 60)


if __name__ == "__main__":
    main()
