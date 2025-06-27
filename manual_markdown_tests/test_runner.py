#!/usr/bin/env python3
"""
Manual Markdown Parser Testing Script

This script allows you to test individual markdown files with the parser
and see exactly what links are found.
"""

import sys
import os
from pathlib import Path

# Add the parent directory to the path so we can import linkwatcher
sys.path.insert(0, str(Path(__file__).parent.parent))

from linkwatcher.parsers.markdown import MarkdownParser

def check_file_exists(file_path, base_dir):
    """Check if a referenced file actually exists."""
    if file_path.startswith(('http://', 'https://', 'mailto:', 'tel:')):
        return "🌐 External"
    
    if file_path.startswith('#'):
        return "⚓ Anchor"
    
    # Handle anchors in file paths
    clean_path = file_path.split('#')[0] if '#' in file_path else file_path
    full_path = Path(base_dir) / clean_path
    
    if full_path.exists():
        return "✅ EXISTS"
    else:
        return "❌ MISSING"

def test_file(file_path):
    """Test a single markdown file and display results."""
    print(f"\n{'='*80}")
    print(f"Testing: {file_path}")
    print(f"{'='*80}")
    
    if not os.path.exists(file_path):
        print(f"❌ File not found: {file_path}")
        return
    
    base_dir = Path(file_path).parent
    parser = MarkdownParser()
    try:
        references = parser.parse_file(file_path)
        
        print(f"\n📊 Results: Found {len(references)} links")
        print("-" * 80)
        
        if references:
            for i, ref in enumerate(references, 1):
                status = check_file_exists(ref.link_target, base_dir)
                print(f"{i:2d}. {ref.link_target:<40} {status}")
                print(f"    Text: '{ref.link_text}'")
                print(f"    Line: {ref.line_number}, Col: {ref.column_start}-{ref.column_end}")
                print(f"    Type: {ref.link_type}")
                print()
        else:
            print("No links found.")
            
        # Summary
        existing = [r for r in references if check_file_exists(r.link_target, base_dir) == "✅ EXISTS"]
        missing = [r for r in references if check_file_exists(r.link_target, base_dir) == "❌ MISSING"]
        external = [r for r in references if check_file_exists(r.link_target, base_dir) == "🌐 External"]
        
        print(f"\n📈 Summary:")
        print(f"   ✅ Existing files: {len(existing)}")
        print(f"   ❌ Missing files: {len(missing)}")
        print(f"   🌐 External links: {len(external)}")
        
        if missing:
            print(f"\n❌ Missing files (you can test by moving these):")
            for ref in missing:
                print(f"   - {ref.link_target}")
            
    except Exception as e:
        print(f"❌ Error parsing file: {e}")

def list_test_files():
    """List all available test files."""
    test_dir = Path(__file__).parent
    md_files = list(test_dir.glob("*.md"))
    
    print("\n📁 Available Test Files:")
    print("-" * 40)
    for i, file in enumerate(sorted(md_files), 1):
        print(f"{i:2d}. {file.name}")
    
    return sorted(md_files)

def main():
    """Main testing interface."""
    print("🧪 Manual Markdown Parser Testing")
    print("=" * 50)
    
    if len(sys.argv) > 1:
        # Test specific file provided as argument
        file_path = sys.argv[1]
        test_file(file_path)
    else:
        # Interactive mode
        while True:
            files = list_test_files()
            
            print(f"\nOptions:")
            print("- Enter number (1-{len(files)}) to test a file")
            print("- Enter filename to test specific file")
            print("- Enter 'all' to test all files")
            print("- Enter 'quit' to exit")
            
            choice = input("\nYour choice: ").strip()
            
            if choice.lower() in ['quit', 'exit', 'q']:
                break
            elif choice.lower() == 'all':
                for file in files:
                    test_file(str(file))
            elif choice.isdigit():
                idx = int(choice) - 1
                if 0 <= idx < len(files):
                    test_file(str(files[idx]))
                else:
                    print("❌ Invalid number")
            elif choice.endswith('.md'):
                test_file(choice)
            else:
                print("❌ Invalid choice")

if __name__ == "__main__":
    main()