#!/usr/bin/env python3
"""
Debug script to understand path calculation issues.
"""

import os
import tempfile
from pathlib import Path

from linkwatcher.parser import LinkParser
from linkwatcher.updater import LinkUpdater


def debug_path_calculation():
    """Debug the path calculation logic."""

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

        print(f"Temp directory: {temp_path}")
        print(f"Test markdown: {test_md}")
        print(f"Original SVG: {test_svg}")
        print(f"Target location: {subfolder / 'icon.svg'}")

        # Parse the file
        parser = LinkParser()
        references = parser.parse_file(str(test_md))

        print(f"\nFound references:")
        for ref in references:
            print(f"  {ref.link_target} (from {ref.file_path})")

        # Move the file
        moved_svg = subfolder / "icon.svg"
        test_svg.rename(moved_svg)

        print(f"\nMoved SVG to: {moved_svg}")

        # Create updater and debug the path calculation
        updater = LinkUpdater(str(temp_path))

        # Let's manually debug the path calculation
        ref = references[0]  # Get the first reference

        print(f"\nDebugging path calculation:")
        print(f"  Reference file_path: {ref.file_path}")
        print(f"  Reference link_target: {ref.link_target}")
        print(f"  Old path: icon.svg")
        print(f"  New path: images/icon.svg")

        # Test the internal method
        new_target = updater._calculate_new_target(ref, "icon.svg", "images/icon.svg")
        print(f"  Calculated new target: {new_target}")

        # Let's also test with absolute paths
        old_abs = str(temp_path / "icon.svg")
        new_abs = str(moved_svg)

        print(f"\nTesting with absolute paths:")
        print(f"  Old absolute: {old_abs}")
        print(f"  New absolute: {new_abs}")

        new_target_abs = updater._calculate_new_target(ref, old_abs, new_abs)
        print(f"  Calculated new target (abs): {new_target_abs}")

        # Test the relative path calculation directly
        print(f"\nTesting relative path calculation:")
        rel_path = updater._calculate_relative_path_between_files(str(test_md), str(moved_svg))
        print(f"  Relative path from {test_md} to {moved_svg}: {rel_path}")


if __name__ == "__main__":
    debug_path_calculation()
