#!/usr/bin/env python3
"""
Test script to verify the multi-project workflow works correctly.
"""

import os
import sys
import tempfile
import subprocess
from pathlib import Path

def test_linkwatcher_from_different_directory():
    """Test that LinkWatcher works when called from a different directory."""
    
    # Get the LinkWatcher directory
    linkwatcher_dir = Path(__file__).parent.parent
    link_watcher_script = linkwatcher_dir / "link_watcher.py"
    check_links_script = linkwatcher_dir / "check_links.py"
    
    if not link_watcher_script.exists():
        print("ERROR: link_watcher.py not found")
        return False
    
    if not check_links_script.exists():
        print("ERROR: check_links.py not found")
        return False
    
    # Create a temporary test project directory
    with tempfile.TemporaryDirectory() as temp_dir:
        test_project = Path(temp_dir) / "test_project"
        test_project.mkdir()
        
        # Create some test files with links
        (test_project / "README.md").write_text("""
# Test Project

This links to [another file](docs/guide.md).
""")
        
        docs_dir = test_project / "docs"
        docs_dir.mkdir()
        (docs_dir / "guide.md").write_text("""
# Guide

This is the guide file.
""")
        
        print(f"OK: Created test project at: {test_project}")
        
        # Change to the test project directory
        original_cwd = os.getcwd()
        os.chdir(test_project)
        
        try:
            # Test check_links.py from the test directory
            print("Testing check_links.py from test project directory...")
            result = subprocess.run([
                sys.executable, str(check_links_script), "--quiet"
            ], capture_output=True, text=True)
            
            if result.returncode == 0:
                print("OK: check_links.py works from different directory")
            else:
                print(f"ERROR: check_links.py failed: {result.stderr}")
                return False
            
            # Test link_watcher.py help from the test directory
            print("Testing link_watcher.py help from test project directory...")
            result = subprocess.run([
                sys.executable, str(link_watcher_script), "--help"
            ], capture_output=True, text=True)
            
            if result.returncode == 0:
                print("OK: link_watcher.py help works from different directory")
            else:
                print(f"ERROR: link_watcher.py help failed: {result.stderr}")
                return False
            
            print("SUCCESS: All tests passed!")
            return True
            
        finally:
            # Restore original directory
            os.chdir(original_cwd)

def main():
    """Run the workflow test."""
    print("LinkWatcher Multi-Project Workflow Test")
    print("=" * 40)
    
    if test_linkwatcher_from_different_directory():
        print("\nSUCCESS: LinkWatcher can be used from any project directory!")
        print("\nNext steps:")
        print("1. Run: python install_global.py")
        print("2. Copy setup_project.py to your project directories")
        print("3. Run setup_project.py from each project")
        print("4. Use LinkWatcher from any project directory!")
    else:
        print("\nFAILED: There are issues with the multi-project setup")
        return 1
    
    return 0

if __name__ == "__main__":
    sys.exit(main())