#!/usr/bin/env python3
"""
Demo script to test the fix for the sequential move issue.

This reproduces the exact scenario from the user's log:
1. LR-002_relative_links.md (file with links) is moved to test_project/
2. file1.txt (target of links) is moved to test_project/documentation/
3. file1.txt is moved back to test_project/

The fix ensures that after step 1, future moves of file1.txt still properly
update the moved LR-002_relative_links.md file.
"""

import os
import shutil
import tempfile
from pathlib import Path

from watchdog.events import FileMovedEvent

from linkwatcher.service import LinkWatcherService


def test_sequential_move_fix():
    """Test the fix for sequential move issue."""

    # Create a temporary directory for testing
    with tempfile.TemporaryDirectory() as temp_dir:
        temp_path = Path(temp_dir)

        # Create directory structure
        manual_tests_dir = temp_path / "manual_markdown_tests"
        test_project_dir = manual_tests_dir / "test_project"
        documentation_dir = test_project_dir / "documentation"

        manual_tests_dir.mkdir()
        test_project_dir.mkdir()
        documentation_dir.mkdir()

        print(f"🏗️ Created test directory structure in: {temp_path}")

        # Create the files
        # 1. LR-002_relative_links.md (represents "one" - file with links)
        lr_002_file = manual_tests_dir / "LR-002_relative_links.md"
        lr_002_content = """# LR-002: Relative Links

This file tests relative path link parsing with REAL files.

## Relative path variations:
- [Current directory](test_project/file1.txt)
- [Test project root](test_project/root.txt)

## Different relative formats:
- [File 1](test_project/file1.txt)
- [File 2](test_project/file2.txt)
"""
        lr_002_file.write_text(lr_002_content)

        # 2. MP-001_standard_links.md (represents "three" - file in different directory)
        mp_001_file = manual_tests_dir / "MP-001_standard_links.md"
        mp_001_content = """# MP-001: Standard Links Test

This file tests basic markdown link parsing with REAL files.

## Standard markdown links:
- [File 1](test_project/file1.txt)
- [File 2](test_project/file2.txt)
"""
        mp_001_file.write_text(mp_001_content)

        # 3. manual_markdown_tests/test_project/file1.txtrepresents "two" - target file)
        file1 = test_project_dir / "tests/file1.txt"
        file1.write_text("This is file1 content")

        # 4. Other files for completeness
        file2 = test_project_dir / "file2.txt"
        file2.write_text("This is file2 content")

        root_file = test_project_dir / "root.txt"
        root_file.write_text("This is root content")

        print("📄 Created test files:")
        print(f"   - {lr_002_file.relative_to(temp_path)}")
        print(f"   - {mp_001_file.relative_to(temp_path)}")
        print(f"   - {file1.relative_to(temp_path)}")
        print(f"   - {file2.relative_to(temp_path)}")
        print(f"   - {root_file.relative_to(temp_path)}")

        # Initialize LinkWatcher service
        service = LinkWatcherService(str(temp_path))
        service._initial_scan()

        print(f"\n📊 Initial scan complete:")
        stats = service.link_db.get_stats()
        print(f"   - Files with links: {stats['files_with_links']}")
        print(f"   - Total references: {stats['total_references']}")
        print(f"   - Total targets: {stats['total_targets']}")

        # Verify initial references to manual_markdown_tests/test_project/file1.txt       initial_refs = service.link_db.get_references_to_file("manual_markdown_tests/test_project/documentation/file1.txt")
        print(f"\n🔍 Initial references to file1.txt: {len(initial_refs)}")
        for ref in initial_refs:
            print(f"   - {ref.file_path}:{ref.line_number} -> '{ref.link_target}'")

        # STEP 1: Move LR-002_relative_links.md to test_project/ (this is the key move)
        print(f"\n🚀 STEP 1: Moving LR-002_relative_links.md to test_project/")
        lr_002_new_location = test_project_dir / "LR-002_relative_links.md"
        lr_002_file.rename(lr_002_new_location)

        move_event1 = FileMovedEvent(str(lr_002_file), str(lr_002_new_location))
        service.handler.on_moved(move_event1)

        print(f"✅ Moved: {lr_002_file.relative_to(temp_path)} → {lr_002_new_location.relative_to(temp_path)}")

        # Verify the database state after step 1
        refs_after_step1 = service.link_db.get_references_to_file("manual_markdown_tests/test_project/documentation/file1.txt")
        print(f"\n📊 After step 1 - References to file1.txt: {len(refs_after_step1)}")
        for ref in refs_after_step1:
            print(f"   - {ref.file_path}:{ref.line_number} -> '{ref.link_target}'")

        # STEP 2: Move manual_markdown_tests/test_project/documentation/file1.txtto documentation/ (this should update the moved LR-002 file)
        print(f"\n🚀 STEP 2: Moving file1.txt to documentation/")
        file1_new_location = documentation_dir / "manual_markdown_tests/test_project/documentation/file1.txt"
        file1.rename(file1_new_location)

        move_event2 = FileMovedEvent(str(file1), str(file1_new_location))
        service.handler.on_moved(move_event2)

        print(f"✅ Moved: {file1.relative_to(temp_path)} → {file1_new_location.relative_to(temp_path)}")

        # Verify the database state after step 2 - THIS IS THE CRITICAL TEST
        refs_after_step2 = service.link_db.get_references_to_file("manual_markdown_tests/test_project/documentation/file1.txt")
        print(f"\n📊 After step 2 - References to documentation/file1.txt: {len(refs_after_step2)}")
        for ref in refs_after_step2:
            print(f"   - {ref.file_path}:{ref.line_number} -> '{ref.link_target}'")

        # Check that the moved LR-002 file was updated
        lr_002_updated_content = lr_002_new_location.read_text()
        print(f"\n📄 Content of moved LR-002 file:")
        print(lr_002_updated_content)

        # STEP 3: Move manual_markdown_tests/test_project/documentation/file1.txtback to test_project/ (this should also work)
        print(f"\n🚀 STEP 3: Moving file1.txt back to test_project/")
        file1_final_location = test_project_dir / "manual_markdown_tests/test_project/documentation/file1.txt"
        file1_new_location.rename(file1_final_location)

        move_event3 = FileMovedEvent(str(file1_new_location), str(file1_final_location))
        service.handler.on_moved(move_event3)

        print(f"✅ Moved: {file1_new_location.relative_to(temp_path)} → {file1_final_location.relative_to(temp_path)}")

        # Final verification
        refs_after_step3 = service.link_db.get_references_to_file("manual_markdown_tests/test_project/documentation/file1.txt")
        print(f"\n📊 After step 3 - References to file1.txt: {len(refs_after_step3)}")
        for ref in refs_after_step3:
            print(f"   - {ref.file_path}:{ref.line_number} -> '{ref.link_target}'")

        # Check final content
        lr_002_final_content = lr_002_new_location.read_text()
        print(f"\n📄 Final content of LR-002 file:")
        print(lr_002_final_content)

        # Success criteria
        success = True
        if len(refs_after_step2) < 2:
            print(f"❌ FAILED: Step 2 should have found at least 2 references, got {len(refs_after_step2)}")
            success = False

        if len(refs_after_step3) < 2:
            print(f"❌ FAILED: Step 3 should have found at least 2 references, got {len(refs_after_step3)}")
            success = False

        # Check that references are from the correct file path (moved location)
        moved_file_refs = [ref for ref in refs_after_step3 if ref.file_path == "manual_markdown_tests/test_project/LR-002_relative_links.md"]
        if len(moved_file_refs) < 2:
            print(f"❌ FAILED: Should have references from moved file, got {len(moved_file_refs)}")
            success = False

        if success:
            print(f"\n🎉 SUCCESS: All sequential moves worked correctly!")
            print(f"   ✅ Step 1: File with links moved successfully")
            print(f"   ✅ Step 2: Target file move updated the moved file")
            print(f"   ✅ Step 3: Subsequent moves continue to work")
        else:
            print(f"\n💥 FAILED: Sequential moves did not work as expected")

        return success

if __name__ == "__main__":
    print("🧪 Testing the fix for sequential move issue...")
    print("=" * 60)

    success = test_sequential_move_fix()

    print("=" * 60)
    if success:
        print("🎉 TEST PASSED: The fix is working correctly!")
    else:
        print("💥 TEST FAILED: The issue still exists")

    exit(0 if success else 1)
