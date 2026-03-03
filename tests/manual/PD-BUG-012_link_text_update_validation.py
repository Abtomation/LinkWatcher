"""
PD-BUG-012 Manual Validation: Link text updated when it matches old target path.

PURPOSE:
    Verify that when a markdown link's display text exactly matches the link
    target (e.g., [../scripts/deploy.ps1](../scripts/deploy.ps1)), BOTH the
    display text and the target are updated when the referenced file is moved.

    Before the fix, only the target (url) part was updated. The display text
    was left with the stale old path, creating misleading links like:
    [../scripts/deploy.ps1](../scripts/automation/deploy.ps1)

HOW TO RUN:
    python tests/manual/PD-BUG-012_link_text_update_validation.py

EXPECTED RESULT:
    All 5 checks pass. Link text matching the old target is updated,
    display names and filenames are preserved unchanged.
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
    print("PD-BUG-012: Link text update validation")
    print("=" * 60)

    passed = 0
    failed = 0

    with tempfile.TemporaryDirectory() as tmpdir:
        project = Path(tmpdir)

        # Create directory structure
        (project / "scripts").mkdir()
        (project / "scripts" / "automation").mkdir()
        (project / "docs").mkdir()

        # Create PowerShell script
        ps1_file = project / "scripts" / "deploy.ps1"
        ps1_file.write_text("# PowerShell Deployment Script\nWrite-Host 'Deploying...'\n")

        # Create markdown with various link text patterns
        md_file = project / "docs" / "guide.md"
        md_content = """# Deployment Guide

## Links with path as text (should be updated)
1. Execute [../scripts/deploy.ps1](../scripts/deploy.ps1) to deploy

## Links with display names (should NOT be updated)
2. Use the [Deployment Script](../scripts/deploy.ps1) for automation

## Links with filename only (should NOT be updated)
3. Run [deploy.ps1](../scripts/deploy.ps1) to start

## Links with different text (should NOT be updated)
4. See [the script](../scripts/deploy.ps1) for details
"""
        md_file.write_text(md_content)

        # Initialize service and scan
        service = LinkWatcherService(str(project))
        service._initial_scan()

        # Move the script
        new_ps1 = project / "scripts" / "automation" / "deploy.ps1"
        ps1_file.rename(new_ps1)

        # Handle the move
        event = FileMovedEvent(str(ps1_file), str(new_ps1))
        service.handler._handle_file_moved(event)

        # Read updated content
        updated = md_file.read_text()
        print("\nUpdated content:")
        print(updated)
        print("-" * 60)

        # CHECK 1: Link text matching old target is updated
        check1 = "[../scripts/automation/deploy.ps1](../scripts/automation/deploy.ps1)" in updated
        status = "PASS" if check1 else "FAIL"
        print(f"[{status}] Check 1: Path-as-text link text updated to new path")
        passed += check1
        failed += not check1

        # CHECK 2: Display name text is preserved
        check2 = "[Deployment Script](../scripts/automation/deploy.ps1)" in updated
        status = "PASS" if check2 else "FAIL"
        print(f"[{status}] Check 2: Display name 'Deployment Script' preserved")
        passed += check2
        failed += not check2

        # CHECK 3: Filename-only text is preserved
        check3 = "[deploy.ps1](../scripts/automation/deploy.ps1)" in updated
        status = "PASS" if check3 else "FAIL"
        print(f"[{status}] Check 3: Filename-only text 'deploy.ps1' preserved")
        passed += check3
        failed += not check3

        # CHECK 4: Other text is preserved
        check4 = "[the script](../scripts/automation/deploy.ps1)" in updated
        status = "PASS" if check4 else "FAIL"
        print(f"[{status}] Check 4: Different text 'the script' preserved")
        passed += check4
        failed += not check4

        # CHECK 5: Old target path does NOT appear in any link target
        # Count occurrences in link targets (inside parentheses)
        import re

        old_target_in_parens = len(re.findall(r"\(../scripts/deploy\.ps1\)", updated))
        check5 = old_target_in_parens == 0
        status = "PASS" if check5 else "FAIL"
        print(
            f"[{status}] Check 5: No link targets contain old path (found {old_target_in_parens})"
        )
        passed += check5
        failed += not check5

    print("-" * 60)
    print(f"Results: {passed} passed, {failed} failed")
    if failed > 0:
        print("VALIDATION FAILED")
        sys.exit(1)
    else:
        print("ALL CHECKS PASSED")
        sys.exit(0)


if __name__ == "__main__":
    main()
