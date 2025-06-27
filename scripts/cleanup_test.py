#!/usr/bin/env python3
"""
Clean up the manual test directory.
"""

import shutil
from pathlib import Path


def cleanup_test():
    """Remove the manual test directory."""

    project_root = Path("c:/Users/ronny/VS_Code/LinkWatcher")
    test_dir = project_root / "manual_test"

    if test_dir.exists():
        shutil.rmtree(test_dir)
        print(f"🧹 Cleaned up test directory: {test_dir}")
        print(f"✅ Manual test cleanup complete!")
    else:
        print(f"ℹ️  Test directory doesn't exist - nothing to clean up.")


if __name__ == "__main__":
    cleanup_test()
