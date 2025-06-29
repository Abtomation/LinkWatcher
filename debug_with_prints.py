#!/usr/bin/env python3
"""
Debug with temporary prints in the updater.
"""

import os
import tempfile
from pathlib import Path

from linkwatcher.parser import LinkParser
from linkwatcher.updater import LinkUpdater

# Monkey patch the method to add debug prints
original_method = LinkUpdater._calculate_new_target_relative


def debug_calculate_new_target_relative(self, original_target, old_path, new_path, source_file):
    print(f"\n=== _calculate_new_target_relative DEBUG ===")
    print(f"  original_target: {original_target}")
    print(f"  old_path: {old_path}")
    print(f"  new_path: {new_path}")
    print(f"  source_file: {source_file}")

    try:
        # Step 1: Analyze the original link type
        link_info = self._analyze_link_type(original_target, source_file)
        print(f"  link_info: {link_info}")

        # Step 2: Convert original target to absolute path for comparison
        absolute_target = self._resolve_to_absolute_path(original_target, source_file, link_info)
        print(f"  absolute_target: {absolute_target}")

        # Normalize paths for comparison (use forward slashes)
        absolute_target_norm = absolute_target.replace("\\", "/")
        old_path_norm = old_path.replace("\\", "/")
        new_path_norm = new_path.replace("\\", "/")

        print(f"  absolute_target_norm: {absolute_target_norm}")
        print(f"  old_path_norm: {old_path_norm}")
        print(f"  new_path_norm: {new_path_norm}")

        # Step 3: Check if this link refers to the moved file
        match_found = False

        if absolute_target_norm == old_path_norm:
            print(f"  Direct match found!")
            match_found = True
        else:
            # Try to resolve old_path relative to source file for comparison
            try:
                source_dir = os.path.dirname(source_file.replace("\\", "/"))
                print(f"  source_dir: {source_dir}")

                if source_dir and not old_path_norm.startswith("/") and ":" not in old_path_norm:
                    # old_path appears to be relative, resolve it relative to source
                    resolved_old_path = os.path.normpath(
                        os.path.join(source_dir, old_path_norm)
                    ).replace("\\", "/")
                    print(f"  resolved_old_path: {resolved_old_path}")

                    if absolute_target_norm == resolved_old_path:
                        print(f"  Match found with resolved old path!")
                        match_found = True
            except Exception as e:
                print(f"  Exception in old path resolution: {e}")

        if match_found:
            print(f"  Match found! Converting new path...")

            # Here's where the issue might be - let's see what new_path_norm becomes
            print(f"  About to convert: new_path_norm={new_path_norm}")

            result = self._convert_to_original_link_type(new_path_norm, source_file, link_info)
            print(f"  Conversion result: {result}")
            return result

        print(f"  No match found, returning original: {original_target}")
        return original_target

    except Exception as e:
        print(f"  Exception in method: {e}")
        return original_target


# Apply the monkey patch
LinkUpdater._calculate_new_target_relative = debug_calculate_new_target_relative


def test_with_debug():
    """Test with debug prints."""

    with tempfile.TemporaryDirectory() as temp_dir:
        temp_path = Path(temp_dir)

        # Create test structure
        test_md = temp_path / "test.md"
        test_svg = temp_path / "icon.svg"
        subfolder = temp_path / "images"
        subfolder.mkdir()

        # Create files
        test_svg.write_text("fake svg")
        test_md.write_text('![Icon](icon.svg "SVG title")')

        # Parse and move
        parser = LinkParser()
        references = parser.parse_file(str(test_md))

        moved_svg = subfolder / "icon.svg"
        test_svg.rename(moved_svg)

        # Test the update
        updater = LinkUpdater(str(temp_path))
        result = updater._calculate_new_target(references[0], "icon.svg", "images/icon.svg")

        print(f"\nFINAL RESULT: {result}")


if __name__ == "__main__":
    test_with_debug()
