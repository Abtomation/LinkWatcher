#!/usr/bin/env python3
"""
Debug script to understand why the updater isn't updating references.
"""

import sys
import tempfile
from pathlib import Path

# Add the project root to Python path
sys.path.insert(0, str(Path(__file__).parent.parent))

from linkwatcher.service import LinkWatcherService


def debug_updater():
    """Debug the updater to see why it's not updating references."""

    print("🔍 Debugging Updater Behavior")
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

        print(f"📄 Created files:")
        print(f"   • README.md: {readme.read_text()}")
        print(f"   • docs/guide.md: {target_file.read_text()}")

        # Initialize service
        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        # Get references
        references = service.link_db.get_references_to_file("docs/guide.md")
        print(f"\n📋 Found {len(references)} reference(s) to 'docs/guide.md':")
        for ref in references:
            print(
                f"   • {ref.file_path}:{ref.line_number} → '{ref.link_target}' (type: {ref.link_type})"
            )
            print(f"     Text: '{ref.link_text}' at columns {ref.column_start}-{ref.column_end}")

        # Test the updater directly
        print(f"\n🔧 Testing updater directly...")
        old_path = "docs/guide.md"
        new_path = "documentation/guide.md"

        if references:
            print(
                f"   Calling updater.update_references({len(references)} refs, '{old_path}' → '{new_path}')"
            )
            update_stats = service.updater.update_references(references, old_path, new_path)
            print(f"   Result: {update_stats}")

            # Check file content after update
            print(f"\n📄 File content after update:")
            print(f"   README.md: {readme.read_text()}")
        else:
            print("   No references to update!")


if __name__ == "__main__":
    debug_updater()
