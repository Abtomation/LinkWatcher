#!/usr/bin/env python3
"""
Debug script to investigate why the directory rename test is finding 4 references instead of 5.
"""

import sys
from pathlib import Path
import tempfile

# Add the project root to Python path
sys.path.insert(0, str(Path(__file__).parent.parent))

from linkwatcher.service import LinkWatcherService


def investigate_directory_test():
    """Recreate the exact test scenario and analyze what references are found."""
    
    print("🔍 Investigating Directory Rename Test")
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
        
        print("\n📋 File contents:")
        print(f"\n📄 README.md:")
        print(readme.read_text())
        
        print(f"\n📄 main.py:")
        print(main_py.read_text())

        # Initialize service
        print("\n🔍 Initializing LinkWatcher service...")
        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        # Analyze what was found
        stats = service.link_db.get_stats()
        print(f"\n📊 Scan Results:")
        print(f"   • Files scanned: {stats.get('files_scanned', 'N/A')}")
        print(f"   • Files with links: {stats['files_with_links']}")
        print(f"   • Total references: {stats['total_references']}")
        print(f"   • Unique targets: {stats['total_targets']}")
        
        print(f"\n📋 All references found:")
        all_refs = []
        for target, refs in service.link_db.links.items():
            for ref in refs:
                all_refs.append((ref.file_path, ref.line_number, ref.link_type, target))
                
        # Sort by file and line number for easier analysis
        all_refs.sort(key=lambda x: (x[0], x[1]))
        
        for i, (file_path, line_num, link_type, target) in enumerate(all_refs, 1):
            print(f"   {i:2d}. {file_path}:{line_num} → {target} ({link_type})")
        
        print(f"\n🎯 Expected references (based on test):")
        print(f"   1. README.md → docs/guide.md (markdown link)")
        print(f"   2. README.md → docs/api.md (markdown link)")
        print(f"   3. README.md → docs/config.yaml (quoted string)")
        print(f"   4. main.py → docs/guide.md (comment)")
        print(f"   5. main.py → docs/api.md (comment)")
        print(f"   6. main.py → docs/config.yaml (quoted string)")
        
        print(f"\n🔍 Analysis:")
        if stats['total_references'] < 5:
            print(f"   ❌ Found {stats['total_references']} references, expected at least 5")
            print(f"   🔍 Missing references might be due to:")
            print(f"      • Parser not detecting certain reference types")
            print(f"      • File type not being monitored")
            print(f"      • Reference format not recognized")
        else:
            print(f"   ✅ Found {stats['total_references']} references, meets expectation")
            
        # Check specific targets
        print(f"\n📋 References by target:")
        for target in ["docs/guide.md", "docs/api.md", "docs/config.yaml"]:
            refs = service.link_db.get_references_to_file(target)
            print(f"   • {target}: {len(refs)} reference(s)")
            for ref in refs:
                print(f"     └─ {ref.file_path}:{ref.line_number} ({ref.link_type})")


if __name__ == "__main__":
    investigate_directory_test()