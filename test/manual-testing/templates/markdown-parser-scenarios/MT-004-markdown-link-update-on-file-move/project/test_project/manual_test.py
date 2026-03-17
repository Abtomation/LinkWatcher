#!/usr/bin/env python3
"""
Manual Testing Script for Real File Movement/Renaming

This script helps you test the LinkWatcher with real files that you can
actually move, rename, and modify.
"""

import os
import sys
from pathlib import Path

# Add the LinkWatcher root to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from linkwatcher.parsers.markdown import MarkdownParser


def check_file_exists(file_path, base_dir):
    """Check if a referenced file actually exists."""
    if file_path.startswith(("http://", "https://", "mailto:", "tel:")):
        return "External"

    if file_path.startswith("#"):
        return "Anchor"

    full_path = Path(base_dir) / file_path
    return "✅ EXISTS" if full_path.exists() else "❌ MISSING"


def test_markdown_file(md_file_path):
    """Test a markdown file and show which referenced files exist."""
    print(f"\n{'='*80}")
    print(f"Testing: {md_file_path}")
    print(f"{'='*80}")

    if not os.path.exists(md_file_path):
        print(f"❌ Markdown file not found: {md_file_path}")
        return

    base_dir = Path(md_file_path).parent
    parser = MarkdownParser()

    try:
        references = parser.parse_file(md_file_path)

        print(f"\n📊 Found {len(references)} links:")
        print("-" * 80)

        if references:
            for i, ref in enumerate(references, 1):
                status = check_file_exists(ref.link_target, base_dir)
                print(f"{i:2d}. {ref.link_target:<30} {status}")
                print(f"    Text: '{ref.link_text}'")
                print(f"    Line: {ref.line_number}, Type: {ref.link_type}")
                print()
        else:
            print("No links found.")

        # Summary
        existing_files = [
            ref for ref in references if check_file_exists(ref.link_target, base_dir) == "✅ EXISTS"
        ]
        missing_files = [
            ref for ref in references if check_file_exists(ref.link_target, base_dir) == "❌ MISSING"
        ]

        print(f"\n📈 Summary:")
        print(f"   ✅ Existing files: {len(existing_files)}")
        print(f"   ❌ Missing files: {len(missing_files)}")

        if missing_files:
            print(f"\n❌ Missing files (broken links):")
            for ref in missing_files:
                print(f"   - {ref.link_target}")

    except Exception as e:
        print(f"❌ Error parsing file: {e}")


def list_project_files():
    """List all files in the test project."""
    project_dir = Path(__file__).parent
    print(f"\n📁 Files in test project ({project_dir}):")
    print("-" * 60)

    for file_path in sorted(project_dir.rglob("*")):
        if file_path.is_file() and file_path.name != "manual_test.py":
            rel_path = file_path.relative_to(project_dir)
            print(f"   {rel_path}")


def suggest_moves():
    """Suggest file movements for testing."""
    print(f"\n🔄 Suggested Manual Tests:")
    print("-" * 60)
    print("1. Move docs/readme.md → documentation/readme.md")
    print("2. Rename config/settings.yaml → config/app-settings.yaml")
    print("3. Move api/reference.txt → docs/api-reference.txt")
    print("4. Move assets/logo.png → images/logo.png")
    print("5. Rename file1.txt → renamed-file1.txt")
    print()
    print("After each move:")
    print("- Run this script again to see broken links")
    print("- Use LinkWatcher to update the links")
    print("- Verify the links are fixed")


def main():
    """Main testing interface."""
    print("🧪 Manual File Movement Testing")
    print("=" * 60)

    project_dir = Path(__file__).parent
    readme_file = project_dir / "README.md"

    while True:
        print(f"\nOptions:")
        print("1. Test ../test_projects/README.md (main test file)")
        print("2. List all project files")
        print("3. Show suggested file movements")
        print("4. Test specific markdown file")
        print("5. Quit")

        choice = input("\nYour choice (1-5): ").strip()

        if choice == "1":
            test_markdown_file(str(readme_file))
        elif choice == "2":
            list_project_files()
        elif choice == "3":
            suggest_moves()
        elif choice == "4":
            filename = input("Enter markdown filename: ").strip()
            file_path = project_dir / filename
            test_markdown_file(str(file_path))
        elif choice == "5":
            break
        else:
            print("❌ Invalid choice")


if __name__ == "__main__":
    main()
