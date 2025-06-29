#!/usr/bin/env python3
"""
Detailed debug of the path calculation issue.
"""

import os
import tempfile
from pathlib import Path

from linkwatcher.parser import LinkParser
from linkwatcher.updater import LinkUpdater


def debug_detailed():
    """Debug the path calculation in detail."""

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

        print(f"Working directory: {temp_path}")
        print(f"Markdown file: {test_md}")
        print(f"Original SVG: {test_svg}")

        # Parse the file
        parser = LinkParser()
        references = parser.parse_file(str(test_md))
        ref = references[0]

        # Move the file
        moved_svg = subfolder / "icon.svg"
        test_svg.rename(moved_svg)
        print(f"Moved SVG to: {moved_svg}")

        # Create updater
        updater = LinkUpdater(str(temp_path))

        # Debug step by step
        print(f"\n=== DEBUGGING STEP BY STEP ===")
        print(f"Reference: {ref.link_target} (from {ref.file_path})")
        print(f"Old path: 'icon.svg'")
        print(f"New path: 'images/icon.svg'")

        # Step 1: Analyze link type
        link_info = updater._analyze_link_type(ref.link_target, ref.file_path)
        print(f"\nStep 1 - Link analysis:")
        for key, value in link_info.items():
            print(f"  {key}: {value}")

        # Step 2: Resolve to absolute path
        absolute_target = updater._resolve_to_absolute_path(
            ref.link_target, ref.file_path, link_info
        )
        print(f"\nStep 2 - Absolute target: {absolute_target}")

        # Step 3: Path normalization
        absolute_target_norm = absolute_target.replace("\\", "/")
        old_path_norm = "icon.svg".replace("\\", "/")
        new_path_norm = "images/icon.svg".replace("\\", "/")

        print(f"\nStep 3 - Normalized paths:")
        print(f"  absolute_target_norm: {absolute_target_norm}")
        print(f"  old_path_norm: {old_path_norm}")
        print(f"  new_path_norm: {new_path_norm}")

        # Step 4: Check for match
        print(f"\nStep 4 - Match checking:")
        print(
            f"  Direct match (absolute_target_norm == old_path_norm): {absolute_target_norm == old_path_norm}"
        )

        # Try resolving old_path relative to source
        source_dir = os.path.dirname(ref.file_path.replace("\\", "/"))
        print(f"  Source directory: {source_dir}")

        if source_dir and not old_path_norm.startswith("/") and ":" not in old_path_norm:
            resolved_old_path = os.path.normpath(os.path.join(source_dir, old_path_norm)).replace(
                "\\", "/"
            )
            print(f"  Resolved old path: {resolved_old_path}")
            print(f"  Match with resolved: {absolute_target_norm == resolved_old_path}")

            if absolute_target_norm == resolved_old_path:
                print(f"\n  MATCH FOUND! Converting new path...")

                # Step 5: Convert new path to original link style
                # First, resolve new_path_norm relative to source
                resolved_new_path = os.path.normpath(
                    os.path.join(source_dir, new_path_norm)
                ).replace("\\", "/")
                print(f"  Resolved new path: {resolved_new_path}")

                # Convert back to original link style
                result = updater._convert_to_original_link_type(
                    resolved_new_path, ref.file_path, link_info
                )
                print(f"  Final result: {result}")

        # Compare with the actual method call
        print(f"\n=== ACTUAL METHOD RESULT ===")
        actual_result = updater._calculate_new_target(ref, "icon.svg", "images/icon.svg")
        print(f"Actual result: {actual_result}")


if __name__ == "__main__":
    debug_detailed()
