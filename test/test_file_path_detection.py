#!/usr/bin/env python3
"""
Test script to verify _looks_like_file_path() function behavior.
"""

import sys
from pathlib import Path

# Add the LinkWatcher directory to the path
sys.path.insert(0, str(Path(__file__).parent))

from link_watcher import LinkParser

def test_file_path_detection():
    """Test the _looks_like_file_path() function with various inputs."""
    parser = LinkParser()
    
    # Test cases that should be detected as file paths
    valid_files = [
        "check_links.py",
        "output.txt", 
        "README_LINK_WATCHER.md",
        "test-config.json",
        "link_watcher.py",
        "templates/task-template.md",
        "templates/feedback-form-template.md",
        "icons/web/icons/Icon-192.png",
        "path/to/file.ext",
        "simple.txt",
        "config.yaml",
        "data.json"
    ]
    
    # Test cases that should NOT be detected as file paths
    invalid_files = [
        "1.2.3",  # version number
        "8.18.2",  # version number
        "object.method",  # method call
        "result.add",  # property access
        "user.save",  # method call
        "data.length",  # property access
        "array.push",  # method call
        "string.trim",  # method call
        "//registry.npmjs.org",  # registry URL
        "example.com",  # domain name
        "test.com",  # domain name
        "123.45",  # decimal number
        "http://example.com",  # URL
        "https://test.com",  # URL
        "package:flutter/material.dart",  # package reference
        "no_extension",  # no extension
        "a.b",  # too short filename
    ]
    
    print("Testing valid file paths:")
    print("=" * 50)
    for file_path in valid_files:
        result = parser._looks_like_file_path(file_path)
        status = "PASS" if result else "FAIL"
        print(f"{status}: {file_path}")
    
    print("\nTesting invalid file paths:")
    print("=" * 50)
    for file_path in invalid_files:
        result = parser._looks_like_file_path(file_path)
        status = "PASS" if not result else "FAIL"
        print(f"{status}: {file_path}")
    
    # Count results
    valid_passed = sum(1 for f in valid_files if parser._looks_like_file_path(f))
    invalid_passed = sum(1 for f in invalid_files if not parser._looks_like_file_path(f))
    
    print(f"\nResults:")
    print(f"Valid files correctly detected: {valid_passed}/{len(valid_files)}")
    print(f"Invalid files correctly rejected: {invalid_passed}/{len(invalid_files)}")
    print(f"Overall accuracy: {(valid_passed + invalid_passed)}/{len(valid_files) + len(invalid_files)}")

if __name__ == "__main__":
    test_file_path_detection()