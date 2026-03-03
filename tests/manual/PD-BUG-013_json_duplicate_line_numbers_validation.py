"""
PD-BUG-013 Manual Validation: JSON parser resolves correct line numbers for duplicate values.

PURPOSE:
    Verify that when a JSON file contains the same file path string in multiple
    locations, moving that file causes ALL references to be updated — not just
    the first occurrence.

    Before the fix, _find_line_number() always returned the first matching line,
    so all duplicate values got the same line number. The updater would only
    update the first occurrence, leaving the rest stale.

HOW TO RUN:
    python tests/manual/PD-BUG-013_json_duplicate_line_numbers_validation.py

EXPECTED RESULT:
    All 5 checks pass. Every occurrence of the moved file path is updated
    in the JSON, regardless of how many times it appears.
"""

import json
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
    print("PD-BUG-013: JSON duplicate line number resolution validation")
    print("=" * 60)

    checks_passed = 0
    checks_total = 5

    with tempfile.TemporaryDirectory() as tmpdir:
        tmpdir = Path(tmpdir)

        # --- Setup: create target file ---
        data_file = tmpdir / "data.csv"
        data_file.write_text("col1,col2\nval1,val2")

        # --- Setup: create JSON with the same path 4 times ---
        config_json = tmpdir / "config.json"
        config_content = """{
  "application": {
    "data_source": "data.csv"
  },
  "files": [
    "data.csv"
  ],
  "paths": {
    "data": "data.csv"
  },
  "backup": {
    "data_file": "data.csv"
  }
}"""
        config_json.write_text(config_content)

        print(f"\nSetup: Created config.json with 'data.csv' on 4 different lines")
        print(f"BEFORE move:\n{config_content}")

        # --- Initialize service and scan ---
        service = LinkWatcherService(str(tmpdir))
        service._initial_scan()

        # --- Check 1: Parser finds all 4 references with unique line numbers ---
        from linkwatcher.parsers.json_parser import JsonParser

        parser = JsonParser()
        refs = parser.parse_content(config_content, str(config_json))
        data_refs = [r for r in refs if r.link_target == "data.csv"]
        line_numbers = [r.line_number for r in data_refs]
        unique_lines = len(set(line_numbers))

        if unique_lines == len(data_refs) and len(data_refs) == 4:
            print(
                f"\n[PASS] Check 1: Parser found {len(data_refs)} refs with {unique_lines} unique line numbers: {sorted(line_numbers)}"
            )
            checks_passed += 1
        else:
            print(
                f"\n[FAIL] Check 1: Expected 4 refs with 4 unique lines, got {len(data_refs)} refs with lines {line_numbers}"
            )

        # --- Move the file ---
        new_data = tmpdir / "datasets" / "main.csv"
        new_data.parent.mkdir()
        data_file.rename(new_data)

        move_event = FileMovedEvent(str(data_file), str(new_data))
        service.handler.on_moved(move_event)

        # --- Read updated content ---
        updated_content = config_json.read_text()
        print(f"\nAFTER move:\n{updated_content}")

        # --- Check 2: No stale "data.csv" remains ---
        if "data.csv" not in updated_content:
            print(f"\n[PASS] Check 2: No stale 'data.csv' references remain")
            checks_passed += 1
        else:
            print(f"\n[FAIL] Check 2: Stale 'data.csv' still found in updated content")

        # --- Check 3: New path present ---
        if "datasets/main.csv" in updated_content:
            print(f"[PASS] Check 3: New path 'datasets/main.csv' found in updated content")
            checks_passed += 1
        else:
            print(f"[FAIL] Check 3: New path 'datasets/main.csv' NOT found in updated content")

        # --- Check 4: Valid JSON structure maintained ---
        try:
            updated_data = json.loads(updated_content)
            print(f"[PASS] Check 4: Updated content is valid JSON")
            checks_passed += 1
        except json.JSONDecodeError as e:
            print(f"[FAIL] Check 4: Updated content is NOT valid JSON: {e}")
            updated_data = None

        # --- Check 5: All 4 values updated ---
        if updated_data:
            all_updated = (
                updated_data["application"]["data_source"] == "datasets/main.csv"
                and "datasets/main.csv" in updated_data["files"]
                and updated_data["paths"]["data"] == "datasets/main.csv"
                and updated_data["backup"]["data_file"] == "datasets/main.csv"
            )
            if all_updated:
                print(f"[PASS] Check 5: All 4 JSON values updated to new path")
                checks_passed += 1
            else:
                print(f"[FAIL] Check 5: Not all values updated:")
                print(f"  application.data_source = {updated_data['application']['data_source']}")
                print(f"  files[0] = {updated_data['files'][0]}")
                print(f"  paths.data = {updated_data['paths']['data']}")
                print(f"  backup.data_file = {updated_data['backup']['data_file']}")

    print(f"\n{'=' * 60}")
    print(f"Results: {checks_passed}/{checks_total} checks passed")
    print(f"{'=' * 60}")

    return 0 if checks_passed == checks_total else 1


if __name__ == "__main__":
    sys.exit(main())
