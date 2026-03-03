"""
PD-BUG-009: Unicode file names cause database lookup failures
Manual validation script.

This script verifies that LinkWatcher correctly handles files with Unicode
names through the full lifecycle: scan, database lookup, and move handling.

Usage:
    python tests/manual/PD-BUG-009_unicode_filename_validation.py

Expected: All checks pass with no UnicodeEncodeError exceptions.
"""

import os
import shutil
import sys
import tempfile

# Add project root to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from linkwatcher.service import LinkWatcherService


def main():
    print("=" * 60)
    print("PD-BUG-009: Unicode Filename Validation")
    print("=" * 60)
    print()

    # Report encoding state
    print(f"  Python version:    {sys.version}")
    print(f"  UTF-8 mode:        {sys.flags.utf8_mode}")
    print(f"  stdout encoding:   {sys.stdout.encoding}")
    print()

    passed = 0
    failed = 0

    with tempfile.TemporaryDirectory() as tmpdir:
        # --- Setup: create files with Unicode names ---
        md_file = os.path.join(tmpdir, "测试文件.md")
        target_file = os.path.join(tmpdir, "目标文件.txt")
        accented_file = os.path.join(tmpdir, "café_naïve.md")
        accented_target = os.path.join(tmpdir, "résumé.txt")

        with open(md_file, "w", encoding="utf-8") as f:
            f.write("[Link](目标文件.txt)\n")
        with open(target_file, "w", encoding="utf-8") as f:
            f.write("Unicode target content\n")
        with open(accented_file, "w", encoding="utf-8") as f:
            f.write("[Link](résumé.txt)\n")
        with open(accented_target, "w", encoding="utf-8") as f:
            f.write("Accented target content\n")

        # --- Check 1: Service initializes without crash ---
        print("[Check 1] Service initialization with Unicode files...")
        try:
            service = LinkWatcherService(tmpdir)
            print("  PASS: Service created successfully")
            passed += 1
        except Exception as e:
            print(f"  FAIL: {e}")
            failed += 1
            return

        # --- Check 2: Initial scan processes Unicode files ---
        print("[Check 2] Initial scan with Unicode filenames...")
        try:
            service._initial_scan()
            stats = service.link_db.get_stats()
            print(
                f"  Scanned: {stats['files_with_links']} files, {stats['total_references']} references"
            )
            if stats["total_references"] >= 2:
                print("  PASS: Unicode files scanned and references stored")
                passed += 1
            else:
                print(f"  FAIL: Expected >= 2 references, got {stats['total_references']}")
                failed += 1
        except Exception as e:
            print(f"  FAIL: {e}")
            failed += 1

        # --- Check 3: Database lookup with CJK filename ---
        print("[Check 3] Database lookup for CJK target (目标文件.txt)...")
        try:
            refs = service.link_db.get_references_to_file("目标文件.txt")
            if len(refs) >= 1:
                print(f"  PASS: Found {len(refs)} reference(s)")
                passed += 1
            else:
                print(f"  FAIL: Expected >= 1 references, got {len(refs)}")
                failed += 1
        except Exception as e:
            print(f"  FAIL: {e}")
            failed += 1

        # --- Check 4: Database lookup with accented filename ---
        print("[Check 4] Database lookup for accented target (résumé.txt)...")
        try:
            refs = service.link_db.get_references_to_file("résumé.txt")
            if len(refs) >= 1:
                print(f"  PASS: Found {len(refs)} reference(s)")
                passed += 1
            else:
                print(f"  FAIL: Expected >= 1 references, got {len(refs)}")
                failed += 1
        except Exception as e:
            print(f"  FAIL: {e}")
            failed += 1

        # --- Check 5: File move with Unicode name ---
        print("[Check 5] File move with CJK filename...")
        try:
            new_target = os.path.join(tmpdir, "新目标文件.txt")
            os.rename(target_file, new_target)

            from watchdog.events import FileMovedEvent

            move_event = FileMovedEvent(target_file, new_target)
            service.handler.on_moved(move_event)

            with open(md_file, "r", encoding="utf-8") as f:
                content = f.read()

            if "新目标文件.txt" in content:
                print("  PASS: Link updated to new Unicode filename")
                passed += 1
            else:
                print(f"  FAIL: Link not updated. Content: {content.strip()}")
                failed += 1
        except Exception as e:
            print(f"  FAIL: {e}")
            failed += 1

    # --- Summary ---
    print()
    print("=" * 60)
    total = passed + failed
    print(f"Results: {passed}/{total} checks passed")
    if failed == 0:
        print("STATUS: ALL CHECKS PASSED")
    else:
        print(f"STATUS: {failed} CHECK(S) FAILED")
    print("=" * 60)

    return 0 if failed == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
