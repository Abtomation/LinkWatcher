"""
PD-BUG-021 Manual Validation: GenericParser detects quoted directory paths.

PURPOSE:
    Verify that GenericParser correctly captures directory paths (paths without
    file extensions) from quoted strings in files handled by the generic parser
    (.ps1, .sh, .bat, etc.).

    Before the fix, GenericParser's quoted_pattern regex required a file extension
    (\.[a-zA-Z0-9]+) at the end of every match, so directory paths like
    "doc/process-framework/templates" were never detected.

HOW TO RUN:
    python tests/manual/PD-BUG-021_directory_path_detection_validation.py

EXPECTED RESULT:
    All 5 checks pass. Directory paths inside quotes are detected alongside
    file paths, with no false positives for non-path strings.
"""

import os
import sys
from pathlib import Path

# Add project root to path
project_root = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(project_root))

from linkwatcher.parsers.generic import GenericParser


def main():
    print("=" * 60)
    print("PD-BUG-021: Directory path detection validation")
    print("=" * 60)

    checks_passed = 0
    checks_total = 5
    parser = GenericParser()

    # --- Check 1: Quoted directory paths with forward slashes ---
    print("\n--- Check 1: Quoted directory paths (forward slashes) ---")
    content = """# PowerShell script
$templateDir = "doc/process-framework/templates/templates"
$outputDir = 'doc/process-framework/state-tracking/permanent'
"""
    refs = parser.parse_content(content, "test.ps1")
    targets = [r.link_target for r in refs]
    dir1 = "doc/process-framework/templates/templates"
    dir2 = "doc/process-framework/state-tracking/permanent"
    if dir1 in targets and dir2 in targets:
        print(f"  PASS: Both directory paths detected")
        print(f"    Found: {dir1}")
        print(f"    Found: {dir2}")
        checks_passed += 1
    else:
        print(f"  FAIL: Missing directory paths")
        print(f"    Expected: {dir1} -> {'FOUND' if dir1 in targets else 'MISSING'}")
        print(f"    Expected: {dir2} -> {'FOUND' if dir2 in targets else 'MISSING'}")

    # --- Check 2: Relative directory paths ---
    print("\n--- Check 2: Relative directory paths ---")
    content = 'Set-Location "../../scripts/file-creation"\n'
    refs = parser.parse_content(content, "test.ps1")
    targets = [r.link_target for r in refs]
    expected = "../../scripts/file-creation"
    if expected in targets:
        print(f"  PASS: Relative directory path detected: {expected}")
        checks_passed += 1
    else:
        print(f"  FAIL: Relative directory path not detected: {expected}")
        print(f"    Found targets: {targets}")

    # --- Check 3: Mixed file and directory paths ---
    print("\n--- Check 3: Mixed file + directory paths (no duplicates) ---")
    content = """$config = "config/settings.yaml"
$dir = "config/settings"
"""
    refs = parser.parse_content(content, "test.ps1")
    file_refs = [r for r in refs if r.link_target == "config/settings.yaml"]
    dir_refs = [r for r in refs if r.link_target == "config/settings"]
    if len(file_refs) == 1 and len(dir_refs) == 1:
        print(
            f"  PASS: File path (type={file_refs[0].link_type}) and directory path (type={dir_refs[0].link_type}) each appear once"
        )
        checks_passed += 1
    else:
        print(f"  FAIL: file_refs={len(file_refs)}, dir_refs={len(dir_refs)} (expected 1 each)")

    # --- Check 4: Windows backslash directory paths ---
    print("\n--- Check 4: Windows backslash directory paths ---")
    content = r'$path = "doc\process-framework\scripts"' + "\n"
    refs = parser.parse_content(content, "test.ps1")
    targets = [r.link_target for r in refs]
    expected = r"doc\process-framework\scripts"
    if expected in targets:
        print(f"  PASS: Backslash directory path detected: {expected}")
        checks_passed += 1
    else:
        print(f"  FAIL: Backslash directory path not detected: {expected}")
        print(f"    Found targets: {targets}")

    # --- Check 5: False positive prevention ---
    print("\n--- Check 5: Non-path strings not captured ---")
    content = """$name = "hello world"
$msg = "error: something failed"
$url = "https://example.com/path"
$flag = "true"
"""
    refs = parser.parse_content(content, "test.ps1")
    targets = [r.link_target for r in refs]
    false_positives = ["hello world", "error: something failed", "https://example.com/path", "true"]
    found_fps = [fp for fp in false_positives if fp in targets]
    if not found_fps:
        print(f"  PASS: No false positives detected (checked {len(false_positives)} strings)")
        checks_passed += 1
    else:
        print(f"  FAIL: False positives detected: {found_fps}")

    # --- Summary ---
    print("\n" + "=" * 60)
    print(f"Result: {checks_passed}/{checks_total} checks passed")
    if checks_passed == checks_total:
        print("ALL CHECKS PASSED")
    else:
        print(f"FAILED: {checks_total - checks_passed} check(s) failed")
    print("=" * 60)

    return 0 if checks_passed == checks_total else 1


if __name__ == "__main__":
    sys.exit(main())
