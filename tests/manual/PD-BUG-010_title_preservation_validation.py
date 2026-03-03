"""
PD-BUG-010 Manual Validation: Markdown link title attributes preserved during file moves.

PURPOSE:
    Verify that when a markdown file containing links with title attributes
    (e.g., [text](path "title")) is moved to a different directory, the
    handler's _update_links_within_moved_file correctly updates relative paths
    while preserving the title portion of each link.

    Before the fix, the handler's regex did not include an optional title group,
    so links with titles failed to match and were silently NOT updated (the
    relative path stayed stale while the title was technically preserved but
    the link was broken).

HOW TO RUN:
    python tests/manual/PD-BUG-010_title_preservation_validation.py

EXPECTED RESULT:
    All 5 checks pass. Links with double-quoted, single-quoted, and
    parenthesized titles are updated with the correct new relative path
    and titles are preserved intact.
"""

import os
import sys
import tempfile
from pathlib import Path

# Add project root to path
project_root = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(project_root))

from watchdog.events import FileMovedEvent

from linkwatcher.service import LinkWatcherService


def main():
    print("=" * 60)
    print("PD-BUG-010: Title preservation validation")
    print("=" * 60)

    with tempfile.TemporaryDirectory() as tmpdir:
        tmpdir = Path(tmpdir)

        # Setup: create target file at root
        target = tmpdir / "target.txt"
        target.write_text("Target content")

        # Setup: create markdown file at root with titled links
        md_file = tmpdir / "guide.md"
        md_content = """# Guide

- [Double-quoted](target.txt "API Reference")
- [Single-quoted](target.txt 'Quick Guide')
- [Paren title](target.txt (See Also))
- [No title](target.txt)
"""
        md_file.write_text(md_content)

        # Initialize service and scan
        service = LinkWatcherService(str(tmpdir))
        service._initial_scan()

        # Move markdown file into a subdirectory (forces path change)
        sub_dir = tmpdir / "docs" / "sub"
        sub_dir.mkdir(parents=True)
        new_md_file = sub_dir / "guide.md"
        md_file.rename(new_md_file)

        # Simulate move event
        event = FileMovedEvent(str(md_file), str(new_md_file))
        service.handler._handle_file_moved(event)

        # Read updated content
        updated = new_md_file.read_text()

        print()
        print("Updated file content:")
        print("-" * 40)
        print(updated)
        print("-" * 40)
        print()

        # Validate
        checks_passed = 0
        total_checks = 5

        # Check 1: Double-quoted title preserved with new path
        if '../../target.txt "API Reference"' in updated:
            print("[PASS] Check 1: Double-quoted title preserved with updated path")
            checks_passed += 1
        else:
            print("[FAIL] Check 1: Double-quoted title NOT preserved or path not updated")

        # Check 2: Single-quoted title preserved with new path
        if "../../target.txt 'Quick Guide'" in updated:
            print("[PASS] Check 2: Single-quoted title preserved with updated path")
            checks_passed += 1
        else:
            print("[FAIL] Check 2: Single-quoted title NOT preserved or path not updated")

        # Check 3: Parenthesized title preserved with new path
        if "../../target.txt (See Also)" in updated:
            print("[PASS] Check 3: Parenthesized title preserved with updated path")
            checks_passed += 1
        else:
            print("[FAIL] Check 3: Parenthesized title NOT preserved or path not updated")

        # Check 4: No-title link also updated
        if "[No title](../../target.txt)" in updated:
            print("[PASS] Check 4: No-title link correctly updated")
            checks_passed += 1
        else:
            print("[FAIL] Check 4: No-title link NOT updated")

        # Check 5: Old path should NOT remain
        if "(target.txt " not in updated and "(target.txt)" not in updated:
            print("[PASS] Check 5: Old relative path fully replaced")
            checks_passed += 1
        else:
            print("[FAIL] Check 5: Old relative path still present")

        print()
        print(f"Results: {checks_passed}/{total_checks} checks passed")

        if checks_passed == total_checks:
            print("SUCCESS: All checks passed!")
            return 0
        else:
            print("FAILURE: Some checks failed!")
            return 1


if __name__ == "__main__":
    sys.exit(main())
