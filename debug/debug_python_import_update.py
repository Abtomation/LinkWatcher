#!/usr/bin/env python3
"""
Debug Python import updating specifically.
"""

import sys
from pathlib import Path

# Add the project root to Python path
sys.path.insert(0, str(Path(__file__).parent.parent))

from linkwatcher.models import LinkReference
from linkwatcher.updater import LinkUpdater


def debug_python_import_update():
    """Debug Python import updating."""

    print("🔍 Debugging Python Import Update")
    print("=" * 60)

    # Create a test reference (python-import type)
    ref = LinkReference(
        file_path="main.py",
        line_number=2,
        column_start=5,
        column_end=25,
        link_text="src.utils.string_utils",
        link_target="src/utils/string_utils",
        link_type="python-import",
    )

    print(f"📋 Test reference:")
    print(f"   • File: {ref.file_path}")
    print(f"   • Line: {ref.line_number}")
    print(f"   • Text: '{ref.link_text}'")
    print(f"   • Target: '{ref.link_target}'")
    print(f"   • Type: {ref.link_type}")

    # Test the updater's calculation
    updater = LinkUpdater()
    old_path = "src/utils/string_utils"
    new_path = "src/helpers/string_utils"

    print(f"\n🔧 Testing updater calculation:")
    print(f"   • Old path: '{old_path}'")
    print(f"   • New path: '{new_path}'")

    new_target = updater._calculate_new_target(ref, old_path, new_path)
    print(f"   • Calculated new target: '{new_target}'")

    # Test if it would update
    would_update = new_target != ref.link_target
    print(f"   • Would update: {would_update}")

    if would_update:
        # Test the line replacement
        test_line = "from src.utils.string_utils import format_string"
        print(f"\n📝 Testing line replacement:")
        print(f"   • Original line: '{test_line}'")

        updated_line = updater._replace_at_position(test_line, ref, new_target)
        print(f"   • Updated line: '{updated_line}'")

    # Test the Python import calculation method directly
    print(f"\n🐍 Testing Python import calculation directly:")
    python_new_target = updater._calculate_new_python_import(ref.link_target, old_path, new_path)
    print(f"   • Direct calculation result: '{python_new_target}'")


if __name__ == "__main__":
    debug_python_import_update()
