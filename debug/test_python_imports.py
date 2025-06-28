#!/usr/bin/env python3
"""
Test the Python parser's ability to detect local imports.
"""

import sys
import tempfile
from pathlib import Path

# Add the project root to Python path
sys.path.insert(0, str(Path(__file__).parent.parent))

from linkwatcher.parsers.python import PythonParser


def test_python_imports():
    """Test Python import detection."""

    print("🔍 Testing Python Import Detection")
    print("=" * 60)

    # Create temporary directory
    with tempfile.TemporaryDirectory() as temp_dir:
        temp_project_dir = Path(temp_dir)

        # Create test Python file with various import types
        main_py = temp_project_dir / "main.py"
        main_content = """# Main application
import os  # Standard library - should be ignored
from sys import path  # Standard library - should be ignored
from src.utils.string_utils import format_string  # Local import - should be detected
from src.utils.file_utils import read_file  # Local import - should be detected
import src.helpers.common  # Local import - should be detected
# Also see "src/utils/common/helpers.py"  # Comment reference - should be detected
config = "config/settings.yaml"  # Quoted path - should be detected
"""
        main_py.write_text(main_content)

        print(f"📄 Test file content:")
        print(main_content)

        # Test the parser
        parser = PythonParser()
        references = parser.parse_file(str(main_py))

        print(f"📋 Found {len(references)} reference(s):")
        for i, ref in enumerate(references, 1):
            print(
                f"   {i:2d}. Line {ref.line_number}: '{ref.link_text}' → '{ref.link_target}' ({ref.link_type})"
            )

        # Check specific expectations
        expected_targets = [
            "src/utils/string_utils",
            "src/utils/file_utils",
            "src/helpers/common",
            "src/utils/common/helpers.py",
            "config/settings.yaml",
        ]

        found_targets = [ref.link_target for ref in references]

        print(f"\n🎯 Expected targets: {expected_targets}")
        print(f"✅ Found targets: {found_targets}")

        for target in expected_targets:
            if target in found_targets:
                print(f"   ✅ {target}")
            else:
                print(f"   ❌ {target} - MISSING")


if __name__ == "__main__":
    test_python_imports()
