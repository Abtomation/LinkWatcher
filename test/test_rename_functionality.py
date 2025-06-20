#!/usr/bin/env python3
"""
Test script to verify that file renaming works with JSON files.
"""

import os
import sys
import tempfile
import json
from pathlib import Path

# Add the LinkWatcher directory to the path
sys.path.insert(0, str(Path(__file__).parent))

from link_watcher import LinkParser, LinkUpdater

def test_json_file_renaming():
    """Test that JSON file references are updated when files are renamed."""
    
    # Create a temporary directory for testing
    with tempfile.TemporaryDirectory() as temp_dir:
        temp_path = Path(temp_dir)
        
        # Create test files
        original_file = temp_path / "original_file.py"
        original_file.write_text("# This is the original file\nprint('Hello World')")
        
        # Create a JSON file that references the original file
        config_json = temp_path / "config.json"
        config_data = {
            "name": "Test Config",
            "files": {
                "script": "original_file.py",
                "templatePath": "original_file.py"
            },
            "templates": [
                {
                    "name": "test",
                    "template": "original_file.py"
                }
            ]
        }
        config_json.write_text(json.dumps(config_data, indent=2))
        
        # Create a markdown file that also references the original file
        readme_md = temp_path / "README.md"
        readme_md.write_text("""
# Test Project

This project uses [original_file.py](original_file.py) for processing.

See also: original_file.py
""")
        
        print(f"Created test files in: {temp_path}")
        print(f"Original JSON content:")
        print(config_json.read_text())
        print(f"\nOriginal README content:")
        print(readme_md.read_text())
        
        # Initialize the LinkParser and LinkUpdater
        parser = LinkParser()
        updater = LinkUpdater()
        
        # Parse the files to find references
        print("\nParsing files for references...")
        json_refs = parser.parse_file(str(config_json))
        md_refs = parser.parse_file(str(readme_md))
        
        print(f"Found {len(json_refs)} references in JSON file:")
        for ref in json_refs:
            print(f"  Line {ref.line_number}: {ref.link_target} (type: {ref.link_type})")
        
        print(f"Found {len(md_refs)} references in Markdown file:")
        for ref in md_refs:
            print(f"  Line {ref.line_number}: {ref.link_target} (type: {ref.link_type})")
        
        # Simulate file renaming
        new_file = temp_path / "renamed_file.py"
        original_file.rename(new_file)
        
        print(f"\nRenamed {original_file.name} to {new_file.name}")
        
        # Update references
        print("Updating references...")
        all_refs = json_refs + md_refs
        
        # Filter references that match the old file
        matching_refs = [ref for ref in all_refs if ref.link_target == "original_file.py"]
        
        print(f"Found {len(matching_refs)} references to update")
        
        # Update all references
        files_updated = updater.update_references(matching_refs, "original_file.py", "renamed_file.py")
        print(f"Updated {len(files_updated)} files: {list(files_updated.keys())}")
        
        # Check the results
        print(f"\nUpdated JSON content:")
        print(config_json.read_text())
        print(f"\nUpdated README content:")
        print(readme_md.read_text())
        
        # Verify the updates
        updated_json = json.loads(config_json.read_text())
        success = True
        
        if updated_json["files"]["script"] != "renamed_file.py":
            print("ERROR: JSON script reference not updated")
            success = False
        
        if updated_json["files"]["templatePath"] != "renamed_file.py":
            print("ERROR: JSON templatePath reference not updated")
            success = False
            
        if updated_json["templates"][0]["template"] != "renamed_file.py":
            print("ERROR: JSON template reference not updated")
            success = False
        
        updated_readme = readme_md.read_text()
        if "renamed_file.py" not in updated_readme:
            print("ERROR: README references not updated")
            success = False
        
        # Check that the standalone reference was updated (should not contain "See also: original_file.py")
        if "See also: original_file.py" in updated_readme:
            print("ERROR: README standalone reference not updated")
            success = False
        
        # Check that the markdown link target was updated (should contain "](renamed_file.py)")
        if "](renamed_file.py)" not in updated_readme:
            print("ERROR: README markdown link target not updated")
            success = False
        
        if success:
            print("\nSUCCESS: All file references were updated correctly!")
            return True
        else:
            print("\nFAILED: Some references were not updated correctly")
            return False

if __name__ == "__main__":
    if test_json_file_renaming():
        print("\nJSON file renaming functionality works correctly!")
        sys.exit(0)
    else:
        print("\nJSON file renaming functionality has issues!")
        sys.exit(1)