#!/usr/bin/env python3
"""
Create a test structure for manually testing LinkWatcher functionality.
"""

import shutil
from pathlib import Path


def create_test_structure():
    """Create a comprehensive test structure for manual testing."""

    project_root = Path("c:/Users/ronny/VS_Code/LinkWatcher")
    test_dir = project_root / "manual_test"

    # Clean up existing test directory
    if test_dir.exists():
        shutil.rmtree(test_dir)
        print(f"🧹 Cleaned up existing test directory")

    # Create directory structure
    test_dir.mkdir()
    (test_dir / "docs").mkdir()
    (test_dir / "src").mkdir()
    (test_dir / "assets").mkdir()

    print(f"📁 Created test directory structure:")
    print(f"   manual_test/")
    print(f"   ├── docs/")
    print(f"   ├── src/")
    print(f"   └── assets/")

    # Create test files with various link types

    # 1. Main README with multiple link types
    readme = test_dir / "README.md"
    readme.write_text(
        """# Manual Test Project

This is a test project for LinkWatcher functionality.

## Documentation Links
- [User Guide](docs/user-guide.md)
- [API Reference](docs/api.md)
- [Configuration](docs/config.yaml)

## Source Code Links
- [Main Module](src/main.py)
- [Utils](src/utils.py)

## Asset Links
- [Logo](assets/logo.png)
- [Screenshot](assets/screenshot.jpg)

## External Links (should not be affected)
- [GitHub](https://github.com)
- [Python](https://python.org)

## Relative Links
- Link to [user guide](docs/user-guide.md) again
- Link to [main module](src/main.py) again
"""
    )

    # 2. Documentation files
    user_guide = test_dir / "docs" / "user-guide.md"
    user_guide.write_text(
        """# User Guide

Welcome to the user guide!

## Getting Started
See the [API Reference](api.md) for details.

## Configuration
Check out the [config file](config.yaml).

## Back to Main
Return to [README](../README.md).
"""
    )

    api_doc = test_dir / "docs" / "api.md"
    api_doc.write_text(
        """# API Reference

This is the API documentation.

## Main Module
The main functionality is in [main.py](../src/main.py).

## Utilities
Helper functions are in [utils.py](../src/utils.py).

## See Also
- [User Guide](user-guide.md)
- [Configuration](config.yaml)
"""
    )

    config_file = test_dir / "docs" / "config.yaml"
    config_file.write_text(
        """# Configuration File
app_name: "Test App"
version: "1.0.0"

# File references
main_script: "../src/main.py"
utils_script: "../src/utils.py"
readme_file: "../README.md"

# Asset references
logo: "../assets/logo.png"
screenshot: "../assets/screenshot.jpg"
"""
    )

    # 3. Source files
    main_py = test_dir / "src" / "main.py"
    main_py.write_text(
        """#!/usr/bin/env python3
\"\"\"
Main module for the test application.

See the user guide: ../docs/user-guide.md
Configuration: ../docs/config.yaml
\"\"\"

from utils import helper_function

def main():
    \"\"\"Main function.\"\"\"
    print("Hello from main!")
    # Load config from ../docs/config.yaml
    pass

if __name__ == "__main__":
    main()
"""
    )

    utils_py = test_dir / "src" / "utils.py"
    utils_py.write_text(
        """#!/usr/bin/env python3
\"\"\"
Utility functions.

Documentation: ../docs/api.md
\"\"\"

def helper_function():
    \"\"\"A helper function.\"\"\"
    # See ../docs/user-guide.md for usage
    return "Helper result"

def load_config():
    \"\"\"Load configuration from ../docs/config.yaml\"\"\"
    pass
"""
    )

    # 4. Create placeholder asset files
    logo = test_dir / "assets" / "logo.png"
    logo.write_text("# Placeholder for logo.png")

    screenshot = test_dir / "assets" / "screenshot.jpg"
    screenshot.write_text("# Placeholder for screenshot.jpg")

    print(f"\n📄 Created test files:")
    print(f"   ✅ README.md (main file with multiple link types)")
    print(f"   ✅ docs/user-guide.md (with relative links)")
    print(f"   ✅ docs/api.md (with cross-references)")
    print(f"   ✅ docs/config.yaml (with file references)")
    print(f"   ✅ src/main.py (with documentation links)")
    print(f"   ✅ src/utils.py (with relative references)")
    print(f"   ✅ assets/logo.png (placeholder)")
    print(f"   ✅ assets/screenshot.jpg (placeholder)")

    print(f"\n🎯 **Manual Testing Instructions:**")
    print(f"")
    print(f"1. **Start LinkWatcher:**")
    print(f"   cd c:/Users/ronny/VS_Code/LinkWatcher")
    print(f"   python link_watcher_new.py manual_test")
    print(f"")
    print(f"2. **Test File Renaming:**")
    print(f"   - Rename 'docs/user-guide.md' to 'docs/user-manual.md'")
    print(f"   - Check that links in README.md and api.md are updated")
    print(f"")
    print(f"3. **Test File Moving:**")
    print(f"   - Move 'src/utils.py' to 'src/helpers.py'")
    print(f"   - Check that references in main.py and config.yaml are updated")
    print(f"")
    print(f"4. **Test Directory Operations:**")
    print(f"   - Create new directory 'manual_test/lib/'")
    print(f"   - Move 'src/main.py' to 'lib/main.py'")
    print(f"   - Check that all references are updated correctly")
    print(f"")
    print(f"5. **Verify Results:**")
    print(f"   - Open the files and verify links point to correct locations")
    print(f"   - All internal links should be updated automatically")
    print(f"   - External links (github.com, python.org) should remain unchanged")

    return test_dir


if __name__ == "__main__":
    test_dir = create_test_structure()
    print(f"\n✅ Test structure created successfully at: {test_dir}")
    print(f"\nYou can now run manual tests using the instructions above!")
