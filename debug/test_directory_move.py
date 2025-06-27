#!/usr/bin/env python3
"""
Debug script to test directory move functionality specifically.
"""

import sys
import tempfile
from pathlib import Path

# Add the project root to Python path
sys.path.insert(0, str(Path(__file__).parent.parent))

from watchdog.events import DirMovedEvent
from linkwatcher.service import LinkWatcherService


def test_directory_move():
    """Test directory move functionality in detail."""
    
    print("🔍 Testing Directory Move Functionality")
    print("=" * 60)
    
    # Create temporary directory (same as test)
    with tempfile.TemporaryDirectory() as temp_dir:
        temp_project_dir = Path(temp_dir)
        
        print(f"📁 Test directory: {temp_project_dir}")
        
        # Setup directory with multiple files (exact same as test)
        docs_dir = temp_project_dir / "docs"
        docs_dir.mkdir()

        # Create multiple files in docs directory
        file1 = docs_dir / "guide.md"
        file1.write_text("# Guide\nContent here")

        file2 = docs_dir / "api.md"
        file2.write_text("# API\nAPI documentation")

        file3 = docs_dir / "config.yaml"
        file3.write_text("setting: value")

        # Create files with references to docs files
        readme = temp_project_dir / "README.md"
        readme_content = """# Project

- [User Guide](docs/guide.md)
- [API Docs](docs/api.md)
- Configuration: "docs/config.yaml"
"""
        readme.write_text(readme_content)

        main_py = temp_project_dir / "main.py"
        main_py.write_text('# See docs/guide.md and docs/api.md\nconfig = "docs/config.yaml"')
        
        print("\n📄 Created files:")
        for file_path in temp_project_dir.rglob("*"):
            if file_path.is_file():
                rel_path = file_path.relative_to(temp_project_dir)
                print(f"   • {rel_path}")

        # Initialize service
        print("\n🔍 Initializing LinkWatcher service...")
        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        # Show initial state
        stats = service.link_db.get_stats()
        print(f"\n📊 Initial state:")
        print(f"   • Total references: {stats['total_references']}")
        
        print(f"\n📋 References before move:")
        for target in ["docs/guide.md", "docs/api.md", "docs/config.yaml"]:
            refs = service.link_db.get_references_to_file(target)
            print(f"   • {target}: {len(refs)} reference(s)")
            for ref in refs:
                print(f"     └─ {ref.file_path}:{ref.line_number}")

        # Perform directory rename
        print(f"\n🔄 Performing directory move...")
        new_docs_dir = temp_project_dir / "documentation"
        docs_dir.rename(new_docs_dir)
        
        print(f"   From: {docs_dir}")
        print(f"   To:   {new_docs_dir}")

        # Process directory move event
        print(f"\n⚡ Processing move event...")
        move_event = DirMovedEvent(str(docs_dir), str(new_docs_dir))
        service.handler.on_moved(move_event)

        # Check results
        print(f"\n📋 References after move:")
        for old_target, new_target in [
            ("docs/guide.md", "documentation/guide.md"),
            ("docs/api.md", "documentation/api.md"), 
            ("docs/config.yaml", "documentation/config.yaml")
        ]:
            old_refs = service.link_db.get_references_to_file(old_target)
            new_refs = service.link_db.get_references_to_file(new_target)
            print(f"   • {old_target}: {len(old_refs)} reference(s) (should be 0)")
            print(f"   • {new_target}: {len(new_refs)} reference(s) (should be >0)")

        # Check file contents
        print(f"\n📄 File contents after move:")
        print(f"\nREADME.md:")
        print(readme.read_text())
        
        print(f"\nmain.py:")
        print(main_py.read_text())
        
        # Final statistics
        final_stats = service.link_db.get_stats()
        handler_stats = service.handler.get_stats()
        
        print(f"\n📊 Final Statistics:")
        print(f"   • Total references: {final_stats['total_references']}")
        print(f"   • Files moved: {handler_stats['files_moved']}")
        print(f"   • Links updated: {handler_stats['links_updated']}")
        print(f"   • Errors: {handler_stats['errors']}")


if __name__ == "__main__":
    test_directory_move()