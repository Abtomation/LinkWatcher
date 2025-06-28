#!/usr/bin/env python3
"""
Quick script to fix unterminated string literals in test files
"""

import re
from pathlib import Path

def fix_file(file_path):
    """Fix unterminated string literals in a file"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Pattern to find unterminated strings ending with file1.txt
        pattern = r'(".*?documentatio/file1\.txt)(?!")([^"]*$)'
        
        # Fix by adding closing quote
        fixed_content = re.sub(pattern, r'\1"\2', content, flags=re.MULTILINE)
        
        # Also fix other common patterns
        patterns_to_fix = [
            (r'("tests/file1\.txt)(?!")([^"]*$)', r'\1"\2'),
            (r'(".*?file1\.txt)(?!")([^"]*$)', r'\1"\2'),
        ]
        
        for pattern, replacement in patterns_to_fix:
            fixed_content = re.sub(pattern, replacement, fixed_content, flags=re.MULTILINE)
        
        if content != fixed_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(fixed_content)
            print(f"Fixed: {file_path}")
            return True
        else:
            print(f"No changes needed: {file_path}")
            return False
            
    except Exception as e:
        print(f"Error processing {file_path}: {e}")
        return False

# Files to fix
files_to_fix = [
    "tests/integration/test_sequential_moves.py",
    "tests/integration/test_file_movement.py", 
    "test_real_scenario.py",
    "test_fix_demo.py",
    "test_move_fix.py",
    "tests/test_move_detection.py",
    "tests/parsers/test_json.py",
    "tests/parsers/test_markdown.py"
]

for file_path in files_to_fix:
    full_path = Path(file_path)
    if full_path.exists():
        fix_file(full_path)
    else:
        print(f"File not found: {file_path}")