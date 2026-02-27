"""
Manual validation test for PD-BUG-019: Directory move detection timer expiry fix.

PURPOSE:
  Verify that moving a directory with multiple files correctly updates ALL
  references, even when files arrive with slight delays between them.

HOW TO RUN:
  python tests/manual/PD-BUG-019_directory_move_validation.py

WHAT IT DOES:
  1. Creates a temporary project with a directory containing multiple files
  2. Creates markdown files that reference those files
  3. Initializes LinkWatcher service
  4. Simulates a directory move (delete + file creates with delays)
  5. Waits for batch processing to complete
  6. Verifies ALL references were updated

EXPECTED RESULT:
  All assertions pass, indicating the batch directory move detection
  correctly handles multiple files without per-file timer expiry.

BUG CONTEXT:
  Before this fix, per-file 10-second timers would expire while the
  handler processed earlier matched files synchronously (~1-2s each).
  The new batch detection (Phase 1-3) buffers all files from a directory
  delete and processes them as a single batch operation.
"""

import shutil
import sys
import tempfile
import time
from pathlib import Path

# Add project root to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from watchdog.events import FileCreatedEvent, FileDeletedEvent

from linkwatcher.service import LinkWatcherService


def run_validation():
    """Run the manual validation test."""
    print("=" * 60)
    print("PD-BUG-019: Directory Move Detection Validation")
    print("=" * 60)

    with tempfile.TemporaryDirectory() as tmpdir:
        tmp_path = Path(tmpdir)

        # --- Setup: Create project structure ---
        print("\n[1] Setting up test project...")

        docs_dir = tmp_path / "docs"
        docs_dir.mkdir()
        (docs_dir / "guide.md").write_text("# Guide\nSetup instructions.")
        (docs_dir / "api.md").write_text("# API\nEndpoint reference.")
        (docs_dir / "faq.md").write_text("# FAQ\nCommon questions.")

        sub_dir = docs_dir / "tutorials"
        sub_dir.mkdir()
        (sub_dir / "quickstart.md").write_text("# Quickstart\nGet started fast.")

        readme = tmp_path / "README.md"
        readme.write_text(
            "# Project\n\n"
            "- [Guide](docs/guide.md)\n"
            "- [API Reference](docs/api.md)\n"
            "- [FAQ](docs/faq.md)\n"
            "- [Quickstart](docs/tutorials/quickstart.md)\n"
        )

        index = tmp_path / "index.md"
        index.write_text(
            "# Index\n\n"
            "See the [guide](docs/guide.md) and [API](docs/api.md).\n"
        )

        new_docs_dir = tmp_path / "documentation"
        new_docs_dir.mkdir()
        (new_docs_dir / "tutorials").mkdir()

        print(f"  Created 4 docs in docs/ and 2 referencing files")

        # --- Initialize service ---
        print("\n[2] Initializing LinkWatcher service...")
        service = LinkWatcherService(str(tmp_path))
        service._initial_scan()

        # Verify initial references
        refs_guide = service.link_db.get_references_to_file("docs/guide.md")
        refs_api = service.link_db.get_references_to_file("docs/api.md")
        refs_faq = service.link_db.get_references_to_file("docs/faq.md")
        refs_qs = service.link_db.get_references_to_file("docs/tutorials/quickstart.md")
        print(f"  Initial refs: guide={len(refs_guide)}, api={len(refs_api)}, "
              f"faq={len(refs_faq)}, quickstart={len(refs_qs)}")

        assert len(refs_guide) >= 2, f"Expected >= 2 refs to guide, got {len(refs_guide)}"
        assert len(refs_api) >= 2, f"Expected >= 2 refs to api, got {len(refs_api)}"

        # --- Simulate directory move ---
        print("\n[3] Simulating directory move: docs/ -> documentation/")

        # Step 3a: Fire directory delete event
        dir_delete_event = FileDeletedEvent(str(docs_dir))
        dir_delete_event.is_directory = False  # Windows behavior
        service.handler.on_deleted(dir_delete_event)

        pending_count = len(service.handler.pending_dir_moves)
        print(f"  Pending dir moves after delete: {pending_count}")
        assert pending_count >= 1, "Should have pending_dir_moves entry"

        if "docs" in service.handler.pending_dir_moves:
            pending = service.handler.pending_dir_moves["docs"]
            print(f"  Buffered files: {pending.total_expected}")
            print(f"  dir_prefix: {repr(pending.dir_prefix)}")
            assert pending.dir_prefix.endswith("/"), \
                f"dir_prefix must end with '/', got: {repr(pending.dir_prefix)}"

        # Step 3b: Move files and fire create events WITH DELAYS
        # (simulates real watchdog behavior where events arrive over time)
        files_to_move = [
            ("docs/guide.md", "documentation/guide.md"),
            ("docs/api.md", "documentation/api.md"),
            ("docs/faq.md", "documentation/faq.md"),
            ("docs/tutorials/quickstart.md", "documentation/tutorials/quickstart.md"),
        ]

        print("\n[4] Moving files with 0.5s delays between events...")
        for old_rel, new_rel in files_to_move:
            old_abs = tmp_path / old_rel.replace("/", "\\")
            new_abs = tmp_path / new_rel.replace("/", "\\")
            old_abs.rename(new_abs)

            create_event = FileCreatedEvent(str(new_abs))
            service.handler.on_created(create_event)
            print(f"  Moved: {old_rel} -> {new_rel}")
            time.sleep(0.5)  # Simulate delay between events

        # --- Wait for batch processing ---
        print("\n[5] Waiting for batch processing (3 seconds)...")
        time.sleep(3.0)

        # --- Verify ALL references updated ---
        print("\n[6] Verifying references updated...")

        readme_content = readme.read_text()
        index_content = index.read_text()

        results = {
            "README: guide": "documentation/guide.md" in readme_content,
            "README: api": "documentation/api.md" in readme_content,
            "README: faq": "documentation/faq.md" in readme_content,
            "README: quickstart": "documentation/tutorials/quickstart.md" in readme_content,
            "index: guide": "documentation/guide.md" in index_content,
            "index: api": "documentation/api.md" in index_content,
        }

        all_passed = True
        for check, passed in results.items():
            status = "PASS" if passed else "FAIL"
            print(f"  [{status}] {check}")
            if not passed:
                all_passed = False

        # Also verify old references are gone
        old_refs = {
            "README no old guide": "docs/guide.md" not in readme_content,
            "README no old api": "docs/api.md" not in readme_content,
        }
        for check, passed in old_refs.items():
            status = "PASS" if passed else "FAIL"
            print(f"  [{status}] {check}")
            if not passed:
                all_passed = False

        print("\n" + "=" * 60)
        if all_passed:
            print("RESULT: ALL CHECKS PASSED")
            print("The directory move detection correctly updated all references.")
        else:
            print("RESULT: SOME CHECKS FAILED")
            print("The directory move detection did NOT update all references.")
            print("\nREADME content:")
            print(readme_content)
            print("\nindex.md content:")
            print(index_content)
        print("=" * 60)

        return all_passed


if __name__ == "__main__":
    success = run_validation()
    sys.exit(0 if success else 1)
