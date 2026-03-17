"""
PD-BUG-025 Manual Validation: Line-targeted replacement prevents substring corruption.

PURPOSE:
    Verify that when a file containing multiple path references is moved,
    a short path like 'config.yaml' does NOT corrupt a longer path like
    'configs/config.yaml' via substring replacement.

    Before the fix, handler.py used content.replace(ref.link_target, new_target)
    which replaced ALL occurrences of the substring in the entire file content,
    including matches inside longer paths.

HOW TO RUN:
    python tests/manual/PD-BUG-025_substring_corruption_validation.py

EXPECTED RESULT:
    All 5 checks pass. Each path reference is updated independently
    without corrupting other paths that contain it as a substring.
"""

import os
import sys
import tempfile
from pathlib import Path

# Add project root to path
project_root = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(project_root))

from watchdog.events import FileMovedEvent

from linkwatcher.service import LinkWatcherService


def main():
    print("=" * 60)
    print("PD-BUG-025: Substring corruption validation")
    print("=" * 60)

    checks_passed = 0
    checks_total = 5

    with tempfile.TemporaryDirectory() as tmpdir:
        tmpdir = Path(tmpdir)

        # --- Setup: create target files ---
        config_file = tmpdir / "config.yaml"
        config_file.write_text("main: true")

        configs_dir = tmpdir / "configs"
        configs_dir.mkdir()
        nested_config = configs_dir / "config.yaml"
        nested_config.write_text("nested: true")

        # --- Setup: create YAML file referencing both paths ---
        yaml_file = tmpdir / "setup.yaml"
        yaml_content = "main_config: config.yaml\n" "nested_config: configs/config.yaml\n"
        yaml_file.write_text(yaml_content)

        print(f"\nBEFORE move (setup.yaml):")
        print(f"  {yaml_content.strip()}")

        # --- Initialize service and scan ---
        service = LinkWatcherService(str(tmpdir))
        service._initial_scan()

        # --- Move the YAML file into a subdirectory ---
        sub_dir = tmpdir / "deploy"
        sub_dir.mkdir()
        new_yaml = sub_dir / "setup.yaml"
        yaml_file.rename(new_yaml)

        event = FileMovedEvent(str(yaml_file), str(new_yaml))
        service.handler._handle_file_moved(event)

        updated_content = new_yaml.read_text()
        print(f"\nAFTER move (deploy/setup.yaml):")
        print(f"  {updated_content.strip()}")

        # --- Check 1: Short path updated ---
        print(f"\nCheck 1: Short path 'config.yaml' updated to '../config.yaml'")
        if "../config.yaml" in updated_content:
            print("  PASS")
            checks_passed += 1
        else:
            print("  FAIL - short path not updated")

        # --- Check 2: Long path not corrupted ---
        print(f"Check 2: Long path NOT corrupted (no 'configs/../config.yaml')")
        if "configs/../config.yaml" not in updated_content:
            print("  PASS")
            checks_passed += 1
        else:
            print("  FAIL - long path corrupted by substring replacement!")

        # --- Check 3: Long path correctly updated ---
        print(f"Check 3: Long path updated to '../configs/config.yaml'")
        if "../configs/config.yaml" in updated_content:
            print("  PASS")
            checks_passed += 1
        else:
            print("  FAIL - long path not correctly updated")

        # --- Check 4: First line correct ---
        lines = updated_content.strip().split("\n")
        print(f"Check 4: Line 1 is 'main_config: ../config.yaml'")
        if len(lines) >= 1 and lines[0].strip() == "main_config: ../config.yaml":
            print("  PASS")
            checks_passed += 1
        else:
            print(f"  FAIL - got: {lines[0] if lines else '(empty)'}")

        # --- Check 5: Second line correct ---
        print(f"Check 5: Line 2 is 'nested_config: ../configs/config.yaml'")
        if len(lines) >= 2 and lines[1].strip() == "nested_config: ../configs/config.yaml":
            print("  PASS")
            checks_passed += 1
        else:
            print(f"  FAIL - got: {lines[1] if len(lines) > 1 else '(empty)'}")

    print(f"\n{'=' * 60}")
    print(f"Results: {checks_passed}/{checks_total} checks passed")
    if checks_passed == checks_total:
        print("ALL CHECKS PASSED")
    else:
        print("SOME CHECKS FAILED")
    print(f"{'=' * 60}")

    return checks_passed == checks_total


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
