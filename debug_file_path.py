#!/usr/bin/env python3
"""
Debug script to understand why _looks_like_file_path() is failing.
"""

import re

def debug_looks_like_file_path(text):
    """Debug version of _looks_like_file_path() with detailed output."""
    print(f"\nDebugging: '{text}'")
    
    if not text or len(text) < 3:
        print("  FAIL: Too short")
        return False
    
    # Skip URLs
    if text.startswith(('http://', 'https://', 'ftp://', 'mailto:', 'tel:')):
        print("  FAIL: URL")
        return False
    
    # Skip package references
    if text.startswith('package:'):
        print("  FAIL: Package reference")
        return False
        
    # Skip version numbers (e.g., "1.2.3", "8.18.2")
    if re.match(r'^\d+\.\d+(\.\d+)*$', text):
        print("  FAIL: Version number")
        return False
        
    # Skip method calls and property access (e.g., "object.method", "result.add")
    # But don't skip files with common extensions
    if re.match(r'^[a-zA-Z_][a-zA-Z0-9_]*\.[a-zA-Z_][a-zA-Z0-9_]*$', text) and not ('/' in text or '\\' in text):
        # Check if this looks like a method call rather than a file
        parts = text.split('.')
        if len(parts) == 2:
            extension = parts[1].lower()
            print(f"  Extension check: '{extension}'")
            # Common file extensions - don't filter these out
            common_extensions = {
                'py', 'js', 'ts', 'html', 'css', 'json', 'xml', 'yaml', 'yml', 
                'md', 'txt', 'log', 'csv', 'sql', 'sh', 'bat', 'ps1',
                'java', 'cpp', 'c', 'h', 'cs', 'php', 'rb', 'go', 'rs',
                'png', 'jpg', 'jpeg', 'gif', 'svg', 'ico', 'bmp',
                'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx',
                'zip', 'tar', 'gz', 'rar', '7z',
                'mp3', 'mp4', 'avi', 'mov', 'wav',
                'dart', 'kt', 'swift', 'gradle', 'properties', 'toml', 'ini'
            }
            if extension not in common_extensions:
                print("  FAIL: Method call/property access (not a common file extension)")
                return False
            else:
                print("  PASS: Common file extension, continuing...")
        else:
            print("  FAIL: Method call/property access (multiple dots)")
            return False
        
    # Skip registry URLs or similar (e.g., "//registry.npmjs.org/...")
    if text.startswith('//'):
        print("  FAIL: Registry URL")
        return False
        
    # Skip domain names without protocol (e.g., "example.com")
    if re.match(r'^[a-zA-Z0-9.-]+\.(com|org|net|edu|gov|io|co|uk|de|fr|js|ts)$', text) and not ('/' in text or '\\' in text):
        print("  FAIL: Domain name")
        return False
        
    # Skip decimal numbers
    if re.match(r'^\d+\.\d+$', text):
        print("  FAIL: Decimal number")
        return False
    
    # Must have an extension
    if '.' not in text:
        print("  FAIL: No extension")
        return False
    
    # Must look like a reasonable file path
    regex_match = re.match(r'^[a-zA-Z0-9_\-./\\]+\.[a-zA-Z0-9]+$', text)
    print(f"  Regex match: {regex_match is not None}")
    
    if regex_match:
        # Additional validation: should contain path separators OR be a reasonable filename
        parts = text.split('.')
        print(f"  Parts: {parts}")
        
        has_separators = '/' in text or '\\' in text
        print(f"  Has separators: {has_separators}")
        
        if has_separators:
            print("  PASS: Has path separators")
            return True
        elif len(parts) >= 2 and len(parts[0]) > 0 and len(parts[-1]) > 0:
            extension = parts[-1].lower()
            filename_part = '.'.join(parts[:-1])
            print(f"  Filename part: '{filename_part}', Extension: '{extension}'")
            print(f"  Filename length: {len(filename_part)}, Extension length: {len(extension)}")
            
            if len(filename_part) >= 1 and len(extension) >= 1 and len(extension) <= 10:
                print("  PASS: Valid filename and extension")
                return True
            else:
                print("  FAIL: Invalid filename or extension length")
                return False
        else:
            print("  FAIL: Invalid parts structure")
            return False
    else:
        print("  FAIL: Regex doesn't match")
        return False

# Test the failing cases
test_cases = [
    "check_links.py",
    "output.txt", 
    "README_LINK_WATCHER.md",
    "simple.txt",
    "config.yaml",
    "data.json"
]

for case in test_cases:
    debug_looks_like_file_path(case)