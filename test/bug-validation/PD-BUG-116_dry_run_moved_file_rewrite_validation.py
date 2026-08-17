"""
Manual validation test for PD-BUG-116: dry-run mode does not prevent link
rewrites inside moved files.

PURPOSE:
  Verify that with dry-run enabled, moving a file that contains outgoing
  relative links does NOT modify that file on disk. References in OTHER
  files were always correctly dry-run-gated; only the within-moved-file
  re-depth pass bypassed the gate.

HOW TO RUN:
  python test/bug-validation/PD-BUG-116_dry_run_moved_file_rewrite_validation.py

WHAT IT DOES (reproducible by hand: start LinkWatcher with --dry-run, then
move docs/A.md into docs/sub/ with any tool):
  1. Creates a temp project:
       docs/A.md    (links to ../other/C.md — needs re-depth after the move)
       other/C.md
  2. Initializes LinkWatcher with dry-run ENABLED, moves docs/A.md to
     docs/sub/A.md on disk, and delivers the move event.
  3. Prints A.md BEFORE and AFTER so you can compare.
  4. Repeats the same move with dry-run DISABLED to show the rewrite is
     otherwise live (proves dry-run is the differentiator, not the scenario).

EXPECTED RESULT (fixed):
  - Dry-run leg:  A.md byte-identical after the move ([C](../other/C.md)).
  - Live leg:     A.md rewritten to [C](../../other/C.md).

PRE-FIX BEHAVIOUR (the bug):
  - Dry-run leg:  A.md is rewritten on disk to ../../other/C.md despite
    dry-run — the within-moved-file pass ignores the flag.
"""

import shutil
import sys
import tempfile
from pathlib import Path

# Add project root to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from watchdog.events import FileMovedEvent  # noqa: E402

from linkwatcher.service import LinkWatcherService  # noqa: E402


def setup_project(root: Path):
    (root / "docs" / "sub").mkdir(parents=True)
    (root / "other").mkdir(parents=True)

    a = root / "docs" / "A.md"
    c = root / "other" / "C.md"

    c.write_text("# C\n", encoding="utf-8")
    a.write_text("# A\nLink: [C](../other/C.md)\n", encoding="utf-8")
    return a


def run_leg(dry_run: bool) -> bool:
    label = "dry-run ENABLED" if dry_run else "dry-run DISABLED"
    root = Path(tempfile.mkdtemp(prefix=f"pd_bug_116_{'dry' if dry_run else 'live'}_"))
    try:
        a_old = setup_project(root)
        a_new = root / "docs" / "sub" / "A.md"

        print(f"\n--- Leg: {label} ---")
        before = a_old.read_text(encoding="utf-8")
        print("A.md BEFORE:")
        print(before)

        service = LinkWatcherService(str(root))
        service.set_dry_run(dry_run)
        service._initial_scan()

        a_old.rename(a_new)
        service.handler.on_moved(FileMovedEvent(str(a_old), str(a_new)))

        after = a_new.read_text(encoding="utf-8")
        print("A.md AFTER:")
        print(after)

        if dry_run:
            ok = after == before
            print(f"  File untouched in dry-run: {'PASS' if ok else 'FAIL  <-- the bug'}")
        else:
            ok = "(../../other/C.md)" in after
            print(f"  File rewritten when live:  {'PASS' if ok else 'FAIL'}")
        return ok
    finally:
        shutil.rmtree(root, ignore_errors=True)


def run_validation():
    print("=" * 64)
    print("PD-BUG-116: Dry-run within-moved-file rewrite validation")
    print("=" * 64)

    dry_ok = run_leg(dry_run=True)
    live_ok = run_leg(dry_run=False)

    print("\n" + "=" * 64)
    if dry_ok and live_ok:
        print("RESULT: PASS — dry-run previews only; live mode still rewrites (bug fixed)")
    else:
        print("RESULT: FAIL — dry-run modified the moved file (PD-BUG-116 present)")
    print("=" * 64)
    return dry_ok and live_ok


if __name__ == "__main__":
    sys.exit(0 if run_validation() else 1)
