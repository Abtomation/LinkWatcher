#!/usr/bin/env python3
"""
Quick File Movement Test Demo

This script demonstrates LinkWatcher's file movement detection and link updating
without running the interactive service.
"""

import os
import shutil
import sys
import time
from pathlib import Path

# Add the project root to Python path
sys.path.insert(0, str(Path(__file__).parent.parent))

from watchdog.events import FileMovedEvent

from linkwatcher.service import LinkWatcherService


def test_file_movement():
    """Test file movement functionality."""

    # Use the manual test directory
    test_dir = Path("c:/Users/ronny/VS_Code/LinkWatcher/manual_test")

    if not test_dir.exists():
        print(
            "❌ Manual test directory not found. Run 'python scripts/create_test_structure.py' first."
        )
        return

    print("🧪 Testing LinkWatcher File Movement Functionality")
    print("=" * 60)

    # Initialize LinkWatcher service
    print("📊 Initializing LinkWatcher service...")
    service = LinkWatcherService(str(test_dir))

    # Enable dry run mode for safety
    service.set_dry_run(True)

    # Perform initial scan
    print("🔍 Performing initial scan...")
    service._initial_scan()

    # Show initial statistics
    stats = service.link_db.get_stats()
    print(f"✅ Initial scan complete:")
    print(f"   • {stats['files_with_links']} files with links")
    print(f"   • {stats['total_references']} total references")
    print(f"   • {stats['total_targets']} unique targets")

    # Show some example references
    print(f"\n📋 Example references found:")
    for target, refs in list(service.link_db.links.items())[:5]:
        print(f"   📄 {target} ← referenced by {len(refs)} file(s)")
        for ref in refs[:2]:  # Show first 2 references
            print(f"      └─ {ref.file_path}:{ref.line_number} ({ref.link_type})")

    print(f"\n🔄 Testing File Movement Detection...")

    # Test 1: Simulate renaming user-guide.md to user-manual.md
    old_file = test_dir / "docs" / "user-guide.md"
    new_file = test_dir / "docs" / "user-manual.md"

    if old_file.exists():
        print(f"\n📝 Test 1: Simulating file rename")
        print(f"   From: {old_file.relative_to(test_dir)}")
        print(f"   To:   {new_file.relative_to(test_dir)}")

        # Get references before move
        old_refs = service.link_db.get_references_to_file("docs/user-guide.md")
        print(f"   📊 Found {len(old_refs)} references to update")

        # Simulate the move event (without actually moving the file)
        move_event = FileMovedEvent(str(old_file), str(new_file))
        service.handler.on_moved(move_event)

        # Check if references were updated in database
        new_refs = service.link_db.get_references_to_file("docs/user-manual.md")
        remaining_old_refs = service.link_db.get_references_to_file("docs/user-guide.md")

        print(f"   ✅ After move simulation:")
        print(f"      • New references: {len(new_refs)}")
        print(f"      • Remaining old references: {len(remaining_old_refs)}")

    # Test 2: Simulate moving utils.py to helpers.py
    old_utils = test_dir / "src" / "utils.py"
    new_helpers = test_dir / "src" / "helpers.py"

    if old_utils.exists():
        print(f"\n📝 Test 2: Simulating file move with rename")
        print(f"   From: {old_utils.relative_to(test_dir)}")
        print(f"   To:   {new_helpers.relative_to(test_dir)}")

        # Get references before move
        old_refs = service.link_db.get_references_to_file("src/utils.py")
        print(f"   📊 Found {len(old_refs)} references to update")

        # Simulate the move event
        move_event = FileMovedEvent(str(old_utils), str(new_helpers))
        service.handler.on_moved(move_event)

        # Check results
        new_refs = service.link_db.get_references_to_file("src/helpers.py")
        remaining_old_refs = service.link_db.get_references_to_file("src/utils.py")

        print(f"   ✅ After move simulation:")
        print(f"      • New references: {len(new_refs)}")
        print(f"      • Remaining old references: {len(remaining_old_refs)}")

    # Test 3: Check link validation
    print(f"\n🔍 Testing Link Validation...")
    broken_links = service.check_links()

    print(f"\n📊 Final Statistics:")
    final_stats = service.link_db.get_stats()
    handler_stats = service.handler.get_stats()

    print(
        f"   Database: {final_stats['total_references']} references to {final_stats['total_targets']} targets"
    )
    print(
        f"   Operations: {handler_stats['files_moved']} moves, {handler_stats['links_updated']} links updated"
    )
    print(f"   Errors: {handler_stats['errors']}")

    print(f"\n✅ File movement test completed!")
    print(f"💡 Note: This was run in dry-run mode - no actual files were modified.")


if __name__ == "__main__":
    test_file_movement()
