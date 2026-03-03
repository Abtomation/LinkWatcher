"""
PD-BUG-024 Manual Validation: Cross-depth file move with DB cleanup.

PURPOSE:
    Verify that moving a file across different directory depths (e.g.,
    from a/b/c/file.md to x/file.md) correctly cleans up all old database
    entries and updates all references.

    Before the fix, _collect_path_updates generated incorrect (old, new)
    pairs for cross-depth moves. The new_target was never used by the
    consumer, so the bug had no observable effect — but the dead code was
    a latent defect. The fix replaced _collect_path_updates with
    _get_old_path_variations (flat list of old targets only).

BUG CONTEXT:
    The bug was in dead code (new_target never read), so both before and
    after the fix, cross-depth moves work correctly. This test validates
    that cross-depth moves continue to work and that old DB entries are
    properly cleaned up after the fix.

HOW TO RUN:
    1. Run this script to set up a temporary project:
       python tests/manual/PD-BUG-024_old_path_variations_validation.py

    2. The script creates a temp project, starts LinkWatcher, and opens
       a 60-second window for you to verify.

    3. During the window, you can inspect the temp directory printed
       at startup. The script will:
       a) Move a deeply-nested file to a shallow location (cross-depth)
       b) Wait for LinkWatcher to process the move
       c) Print the file contents and DB state so you can verify

EXPECTED RESULT (AFTER FIX):
    - README.md should show updated reference to new path
    - No stale DB entries for the old path
    - All 3 checks pass

EXPECTED RESULT (BEFORE FIX):
    - Same behavior (bug was in dead code), but internal _collect_path_updates
      would have generated incorrect new_target values. This test validates
      the end-to-end behavior remains correct after the simplification.
"""

import sys
import tempfile
import time
from pathlib import Path

# Add project root to path
project_root = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(project_root))

from watchdog.events import FileMovedEvent

from linkwatcher.service import LinkWatcherService


def main():
    print("=" * 70)
    print("PD-BUG-024: Cross-depth file move validation")
    print("=" * 70)

    with tempfile.TemporaryDirectory() as tmpdir:
        tmp_path = Path(tmpdir)

        # --- Step 1: Create project structure with deeply-nested file ---
        print(f"\n[Step 1] Creating test project at: {tmp_path}")

        # Deep file: a/b/c/target.md (3 levels deep)
        deep_dir = tmp_path / "a" / "b" / "c"
        deep_dir.mkdir(parents=True)
        target_file = deep_dir / "target.md"
        target_file.write_text("# Target File\nThis file will be moved.")

        # Shallow destination: x/target.md (1 level deep)
        shallow_dir = tmp_path / "x"
        shallow_dir.mkdir()

        # README.md that references the deep file
        readme = tmp_path / "README.md"
        readme.write_text("# Project\n\n" "See [target](a/b/c/target.md) for details.\n")

        # A second file that uses a relative reference (without top dir)
        notes = tmp_path / "a" / "notes.md"
        notes.write_text("# Notes\n\n" "Related: [target](b/c/target.md)\n")

        print("  Created structure:")
        print("    a/b/c/target.md  (file to move)")
        print("    a/notes.md       (references b/c/target.md)")
        print("    x/               (move destination)")
        print("    README.md        (references a/b/c/target.md)")

        # --- Step 2: Initialize LinkWatcher ---
        print("\n[Step 2] Initializing LinkWatcher service...")
        service = LinkWatcherService(str(tmp_path))
        service._initial_scan()

        # Show initial DB state
        refs_full = service.link_db.get_references_to_file("a/b/c/target.md")
        refs_rel = service.link_db.get_references_to_file("b/c/target.md")
        refs_name = service.link_db.get_references_to_file("target.md")
        print(f"  DB refs to 'a/b/c/target.md': {len(refs_full)}")
        print(f"  DB refs to 'b/c/target.md':   {len(refs_rel)}")
        print(f"  DB refs to 'target.md':       {len(refs_name)}")

        print("\n  Initial README.md content:")
        print(f"    {readme.read_text().strip()}")
        print(f"\n  Initial a/notes.md content:")
        print(f"    {notes.read_text().strip()}")

        # --- Step 3: Move the file across depths ---
        print("\n[Step 3] Moving file: a/b/c/target.md -> x/target.md")
        print("  (This is a cross-depth move: 3 levels deep -> 1 level deep)")

        new_target = shallow_dir / "target.md"
        target_file.rename(new_target)

        # Fire the move event
        move_event = FileMovedEvent(str(target_file), str(new_target))
        service.handler.on_moved(move_event)

        # Brief pause for processing
        time.sleep(1.0)

        # --- Step 4: Verify results ---
        print("\n[Step 4] Verifying results...")

        readme_content = readme.read_text()
        notes_content = notes.read_text()

        print(f"\n  Updated README.md content:")
        print(f"    {readme_content.strip()}")
        print(f"\n  Updated a/notes.md content:")
        print(f"    {notes_content.strip()}")

        # Check old DB entries are cleaned up
        stale_full = service.link_db.get_references_to_file("a/b/c/target.md")
        stale_rel = service.link_db.get_references_to_file("b/c/target.md")
        new_refs = service.link_db.get_references_to_file("x/target.md")
        print(f"\n  DB refs to 'a/b/c/target.md' (should be 0): {len(stale_full)}")
        print(f"  DB refs to 'b/c/target.md' (should be 0):   {len(stale_rel)}")
        print(f"  DB refs to 'x/target.md' (should be >0):    {len(new_refs)}")

        # --- Checks ---
        checks_passed = 0
        checks_total = 3

        print("\n" + "-" * 70)

        # Check 1: README reference updated
        check1 = "x/target.md" in readme_content and "a/b/c/target.md" not in readme_content
        status = "PASS" if check1 else "FAIL"
        print(f"  [{status}] README.md reference updated to x/target.md")
        if check1:
            checks_passed += 1

        # Check 2: No stale DB entries for old full path
        check2 = len(stale_full) == 0
        status = "PASS" if check2 else "FAIL"
        print(f"  [{status}] No stale DB entries for 'a/b/c/target.md'")
        if check2:
            checks_passed += 1

        # Check 3: No stale DB entries for old relative path
        check3 = len(stale_rel) == 0
        status = "PASS" if check3 else "FAIL"
        print(f"  [{status}] No stale DB entries for 'b/c/target.md'")
        if check3:
            checks_passed += 1

        print(f"\n{'=' * 70}")
        print(f"Results: {checks_passed}/{checks_total} checks passed")
        if checks_passed == checks_total:
            print("ALL CHECKS PASSED")
            print("Cross-depth file move correctly updated references and cleaned DB.")
        else:
            print("SOME CHECKS FAILED")
            print("Cross-depth file move may have issues with DB cleanup.")
        print("=" * 70)

        return checks_passed == checks_total


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
