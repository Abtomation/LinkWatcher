#!/usr/bin/env python3
"""
Debug script to understand what's happening in the directory move handler.
"""

import sys
import tempfile
from pathlib import Path

# Add the project root to Python path
sys.path.insert(0, str(Path(__file__).parent.parent))

from watchdog.events import DirMovedEvent
from linkwatcher.service import LinkWatcherService


def debug_directory_handler():
    """Debug the directory move handler step by step."""
    
    print("🔍 Debugging Directory Move Handler")
    print("=" * 60)
    
    # Create temporary directory
    with tempfile.TemporaryDirectory() as temp_dir:
        temp_project_dir = Path(temp_dir)
        
        # Create simple test case
        docs_dir = temp_project_dir / "docs"
        docs_dir.mkdir()
        
        # Create target file
        target_file = docs_dir / "guide.md"
        target_file.write_text("# Guide\nContent here")
        
        # Create file with reference
        readme = temp_project_dir / "README.md"
        readme.write_text("See [guide](docs/guide.md) for details.")
        
        print(f"📄 Initial setup:")
        print(f"   • README.md: {readme.read_text()}")
        print(f"   • docs/guide.md exists: {target_file.exists()}")

        # Initialize service
        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        # Check initial references
        initial_refs = service.link_db.get_references_to_file("docs/guide.md")
        print(f"\n📋 Initial references to 'docs/guide.md': {len(initial_refs)}")
        for ref in initial_refs:
            print(f"   • {ref.file_path}:{ref.line_number} → '{ref.link_target}'")

        # Perform directory move
        print(f"\n🔄 Moving directory...")
        new_docs_dir = temp_project_dir / "documentation"
        docs_dir.rename(new_docs_dir)
        
        print(f"   • docs/ → documentation/")
        print(f"   • New file exists: {(new_docs_dir / 'guide.md').exists()}")

        # Check what the handler will see
        print(f"\n🔍 What the handler should process:")
        print(f"   • Old path: docs/guide.md")
        print(f"   • New path: documentation/guide.md")
        
        # Get references before handler processes
        refs_before = service.link_db.get_references_to_file("docs/guide.md")
        print(f"   • References to old path: {len(refs_before)}")
        
        # Process directory move event with detailed logging
        print(f"\n⚡ Processing move event...")
        move_event = DirMovedEvent(str(docs_dir), str(new_docs_dir))
        
        # Manually call the handler method to add debug info
        handler = service.handler
        old_dir = handler._get_relative_path(str(docs_dir))
        new_dir = handler._get_relative_path(str(new_docs_dir))
        
        print(f"   • Handler sees old_dir: '{old_dir}'")
        print(f"   • Handler sees new_dir: '{new_dir}'")
        
        # Check what files the handler finds
        import os
        moved_files = []
        for root, dirs, files in os.walk(str(new_docs_dir)):
            for file in files:
                file_path = os.path.join(root, file)
                if handler._should_monitor_file(file_path):
                    rel_new_path = handler._get_relative_path(file_path)
                    rel_old_path = rel_new_path.replace(new_dir, old_dir, 1)
                    moved_files.append((rel_old_path, rel_new_path))
                    print(f"   • Found moved file: '{rel_old_path}' → '{rel_new_path}'")
        
        # Check references for each moved file
        for old_file_path, new_file_path in moved_files:
            refs = service.link_db.get_references_to_file(old_file_path)
            print(f"   • References to '{old_file_path}': {len(refs)}")
            for ref in refs:
                print(f"     └─ {ref.file_path}:{ref.line_number} → '{ref.link_target}'")
        
        # Now actually process the event
        print(f"\n⚡ Actually processing event...")
        service.handler.on_moved(move_event)

        # Check final state
        print(f"\n📊 Final state:")
        final_refs_old = service.link_db.get_references_to_file("docs/guide.md")
        final_refs_new = service.link_db.get_references_to_file("documentation/guide.md")
        print(f"   • References to 'docs/guide.md': {len(final_refs_old)}")
        print(f"   • References to 'documentation/guide.md': {len(final_refs_new)}")
        print(f"   • README.md content: {readme.read_text()}")


if __name__ == "__main__":
    debug_directory_handler()