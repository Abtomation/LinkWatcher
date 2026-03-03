"""
PD-BUG-011 Manual Validation: HTML anchor tags parsed and updated in markdown files.

PURPOSE:
    Verify that when a markdown file contains HTML anchor tags (<a href="...">),
    the parser recognizes them as link references and the updater correctly
    modifies the href values when the referenced file is moved.

    Before the fix, the MarkdownParser had no regex pattern for HTML anchor
    tags, so <a href="path"> links were silently ignored during file moves.

HOW TO RUN:
    python tests/manual/PD-BUG-011_html_anchor_parsing_validation.py

EXPECTED RESULT:
    All 5 checks pass. HTML anchor tags with double quotes, single quotes,
    title attributes, and mixed with standard markdown links are all updated.
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
    print("PD-BUG-011: HTML anchor tag parsing validation")
    print("=" * 60)

    with tempfile.TemporaryDirectory() as tmpdir:
        tmpdir = Path(tmpdir)

        # Setup: create target file
        target = tmpdir / "shared.txt"
        target.write_text("Shared content")

        # Setup: create markdown file with HTML anchor tags
        md_file = tmpdir / "index.md"
        md_content = """# HTML Anchor Test

Standard markdown: [link](shared.txt)
Double-quoted HTML: <a href="shared.txt">Link 1</a>
Single-quoted HTML: <a href='shared.txt'>Link 2</a>
HTML with title: <a href="shared.txt" title="Shared File">Link 3</a>
Mixed on same line: [md](shared.txt) and <a href="shared.txt">html</a>
"""
        md_file.write_text(md_content)

        # Initialize service and scan
        service = LinkWatcherService(str(tmpdir))
        service._initial_scan()

        # Show before state
        print("\n--- BEFORE move ---")
        print(md_file.read_text())

        # Move the target file
        new_target = tmpdir / "common.txt"
        target.rename(new_target)
        move_event = FileMovedEvent(str(target), str(new_target))
        service.handler.on_moved(move_event)

        # Show after state
        updated = md_file.read_text()
        print("--- AFTER move ---")
        print(updated)

        # Validation checks
        print("--- CHECKS ---")
        checks_passed = 0
        total_checks = 5

        # Check 1: Standard markdown link updated
        check1 = "[link](common.txt)" in updated
        print(f"{'PASS' if check1 else 'FAIL'} Check 1: Standard markdown link updated")
        checks_passed += check1

        # Check 2: Double-quoted HTML anchor updated
        check2 = '<a href="common.txt">Link 1</a>' in updated
        print(f"{'PASS' if check2 else 'FAIL'} Check 2: Double-quoted HTML anchor updated")
        checks_passed += check2

        # Check 3: Single-quoted HTML anchor updated
        check3 = "<a href='common.txt'>Link 2</a>" in updated
        print(f"{'PASS' if check3 else 'FAIL'} Check 3: Single-quoted HTML anchor updated")
        checks_passed += check3

        # Check 4: HTML anchor with title attribute updated
        check4 = '<a href="common.txt" title="Shared File">Link 3</a>' in updated
        print(f"{'PASS' if check4 else 'FAIL'} Check 4: HTML anchor with title attribute updated")
        checks_passed += check4

        # Check 5: Mixed line - both markdown and HTML updated
        check5 = "[md](common.txt)" in updated and '<a href="common.txt">html</a>' in updated
        print(
            f"{'PASS' if check5 else 'FAIL'} Check 5: Mixed line — both markdown and HTML updated"
        )
        checks_passed += check5

        print(f"\n{'=' * 60}")
        print(f"Result: {checks_passed}/{total_checks} checks passed")
        if checks_passed == total_checks:
            print("ALL CHECKS PASSED")
        else:
            print("SOME CHECKS FAILED — see details above")
        print(f"{'=' * 60}")

        return checks_passed == total_checks


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
