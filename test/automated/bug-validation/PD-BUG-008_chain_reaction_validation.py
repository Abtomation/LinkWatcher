"""
PD-BUG-008 Manual Validation: Chain reaction moves leave database in inconsistent state

WHAT THIS TESTS:
When multiple files are moved sequentially (in the same directory), the database
must update the source file paths so that subsequent moves correctly find and
update the right files.

HOW TO USE:
1. Run this script: python tests/manual/PD-BUG-008_chain_reaction_validation.py
2. The script creates a temp directory with 3 files in a circular reference chain.
3. It moves each file and checks whether the database is consistent after each move.
4. Review the PASS/FAIL output for each check.

EXPECTED RESULT (after fix):
- All 5 checks should PASS
- Each file's content should reference the renamed version of its target
- The database should never contain stale source paths
"""

import os
import shutil
import sys
import tempfile
from pathlib import Path

# Add project root to path
project_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, project_root)

from watchdog.events import FileMovedEvent

from linkwatcher.service import LinkWatcherService


def main():
    print("=" * 70)
    print("PD-BUG-008: Chain Reaction Moves — Manual Validation")
    print("=" * 70)

    temp_dir = tempfile.mkdtemp(prefix="bug008_")
    print(f"\nTemp directory: {temp_dir}\n")

    try:
        # Setup: 3 files with circular references
        # A → B, B → C, C → A
        file_a = Path(temp_dir) / "alpha.md"
        file_a.write_text("# Alpha\nSee [beta](beta.md) for details.\n")

        file_b = Path(temp_dir) / "beta.md"
        file_b.write_text("# Beta\nSee [gamma](gamma.md) for details.\n")

        file_c = Path(temp_dir) / "gamma.md"
        file_c.write_text("# Gamma\nSee [alpha](alpha.md) for details.\n")

        print("BEFORE moves:")
        print(f"  alpha.md: {file_a.read_text().strip()}")
        print(f"  beta.md:  {file_b.read_text().strip()}")
        print(f"  gamma.md: {file_c.read_text().strip()}")

        # Initialize service
        service = LinkWatcherService(temp_dir)
        service._initial_scan()
        print(f"\nDB stats after scan: {service.handler.link_db.get_stats()}")

        results = []

        # Move 1: alpha.md → alpha_v2.md
        print("\n--- Move 1: alpha.md → alpha_v2.md ---")
        new_a = Path(temp_dir) / "alpha_v2.md"
        file_a.rename(new_a)
        service.handler.on_moved(FileMovedEvent(str(file_a), str(new_a)))

        # Check 1: DB source path updated for alpha's outgoing link
        refs_to_beta = service.handler.link_db.get_references_to_file("beta.md")
        source_files = {ref.file_path for ref in refs_to_beta}
        check1 = "alpha.md" not in source_files and "alpha_v2.md" in source_files
        results.append(("DB source path updated after Move 1", check1, source_files))
        print(f"  Check 1 — DB refs to beta.md from: {source_files}")

        # Check 2: gamma.md content updated to reference alpha_v2.md
        gamma_content = (Path(temp_dir) / "gamma.md").read_text()
        check2 = "alpha_v2.md" in gamma_content and "alpha.md" not in gamma_content.replace(
            "alpha_v2.md", ""
        )
        results.append(("gamma.md references alpha_v2.md", check2, gamma_content.strip()))

        # Move 2: beta.md → beta_v2.md
        print("\n--- Move 2: beta.md → beta_v2.md ---")
        new_b = Path(temp_dir) / "beta_v2.md"
        file_b.rename(new_b)
        service.handler.on_moved(FileMovedEvent(str(file_b), str(new_b)))

        # Check 3: alpha_v2.md content updated to reference beta_v2.md
        alpha_content = new_a.read_text()
        check3 = "beta_v2.md" in alpha_content
        results.append(("alpha_v2.md references beta_v2.md", check3, alpha_content.strip()))

        # Move 3: gamma.md → gamma_v2.md
        print("\n--- Move 3: gamma.md → gamma_v2.md ---")
        new_c = Path(temp_dir) / "gamma_v2.md"
        file_c.rename(new_c)
        service.handler.on_moved(FileMovedEvent(str(file_c), str(new_c)))

        # Check 4: beta_v2.md content updated to reference gamma_v2.md
        beta_content = new_b.read_text()
        check4 = "gamma_v2.md" in beta_content
        results.append(("beta_v2.md references gamma_v2.md", check4, beta_content.strip()))

        # Check 5: Final file contents are all correct
        final_a = new_a.read_text()
        final_b = new_b.read_text()
        final_c = new_c.read_text()
        check5 = "beta_v2.md" in final_a and "gamma_v2.md" in final_b and "alpha_v2.md" in final_c
        results.append(
            (
                "All final references correct",
                check5,
                f"a→{final_a.strip()}, b→{final_b.strip()}, c→{final_c.strip()}",
            )
        )

        # Print results
        print("\n" + "=" * 70)
        print("RESULTS:")
        print("=" * 70)
        all_pass = True
        for i, (desc, passed, detail) in enumerate(results, 1):
            status = "PASS" if passed else "FAIL"
            if not passed:
                all_pass = False
            print(f"  Check {i}: [{status}] {desc}")
            if not passed:
                print(f"           Detail: {detail}")

        print(f"\nOverall: {'ALL CHECKS PASSED' if all_pass else 'SOME CHECKS FAILED'}")
        print(f"DB stats: {service.handler.link_db.get_stats()}")
        return 0 if all_pass else 1

    finally:
        shutil.rmtree(temp_dir, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())
