#!/usr/bin/env python3
"""
Manual validation for PD-BUG-109: the own-output exclusion zone swallows
the entire watched tree when the log file lives OUTSIDE the project root.
compute_own_output_exclusions (PD-BUG-107 fix) excluded the log file's
parent directory whenever it differed from the project root; when that
parent is an ancestor of the root (E2E harness layout), every path in
the watched tree prefix-matches the exclusion — 0 files scanned, all
events ignored, daemon silently inert.

The playground lives OUTSIDE the repo (C:/tmp) so the project's own
daemon doesn't index it and confound the observation. The daemon under
test must run FROM REPO SOURCE (the deployed ~/bin daemon lags the fix).

How to validate:

  1. python test/bug-validation/PD-BUG-109_outside_root_log_exclusion_validation.py setup
     -> Creates C:/tmp/pd109-playground/project/ with linked markdown
        files. The log file path is C:/tmp/pd109-playground/lw.log —
        one level ABOVE the watched root, like the E2E harness.
  2. In a SEPARATE terminal, start a repo-source daemon against the
     playground project and let the initial scan finish (~10 seconds):
        python main.py --project-root C:/tmp/pd109-playground/project `
                       --log-file C:/tmp/pd109-playground/lw.log
  3. While it runs, move the linked target to trigger a reference update:
        Move-Item C:/tmp/pd109-playground/project/target.md `
                  C:/tmp/pd109-playground/project/renamed.md
     Give the daemon ~5 seconds, then stop it (Ctrl+C).
  4. python test/bug-validation/PD-BUG-109_outside_root_log_exclusion_validation.py check
     -> WITHOUT the fix: log shows own_output_excluded with the
        playground dir, scan_complete files_scanned=0, and notes.md
        still references target.md (no update happened).
     -> WITH the fix: no own_output_excluded directory zone, initial
        scan finds files (files_scanned >= 2), and notes.md now
        references renamed.md.
  5. python test/bug-validation/PD-BUG-109_outside_root_log_exclusion_validation.py cleanup
"""

import re
import shutil
import sys
from pathlib import Path

PLAYGROUND = Path("C:/tmp/pd109-playground")
PROJECT = PLAYGROUND / "project"
LOG_FILE = PLAYGROUND / "lw.log"


def setup():
    if PLAYGROUND.exists():
        shutil.rmtree(PLAYGROUND)
    PROJECT.mkdir(parents=True)
    (PROJECT / "target.md").write_text("# Target\n", encoding="utf-8")
    (PROJECT / "notes.md").write_text("# Notes\n\nSee [target](target.md).\n", encoding="utf-8")
    print(f"Playground created: {PROJECT}")
    print(f"Log file will be OUTSIDE the watched root: {LOG_FILE}")
    print("Now start a repo-source daemon against it (see module docstring, step 2).")


def check():
    if not LOG_FILE.exists():
        print(f"No log file at {LOG_FILE} — did the daemon run? (step 2)")
        sys.exit(2)
    lines = LOG_FILE.read_text(encoding="utf-8", errors="replace").splitlines()

    excluded_dir_lines = [
        ln for ln in lines if "own_output_excluded" in ln and "pd109-playground" in ln.lower()
    ]
    scanned = None
    for ln in lines:
        m = re.search(r"files_scanned[\"':= ]+(\d+)", ln)
        if m:
            scanned = int(m.group(1))
    notes = (PROJECT / "notes.md").read_text(encoding="utf-8")
    updated = "renamed.md" in notes and "target.md" not in notes

    print(f"Log lines total:                                {len(lines)}")
    print(f"own_output_excluded zones naming the playground: {len(excluded_dir_lines)}")
    print(f"Initial scan files_scanned:                      {scanned}")
    print(f"notes.md reference updated after move:           {updated}")
    for ln in excluded_dir_lines[:3]:
        print(f"  ZONE EVIDENCE: {ln}")

    if scanned == 0 or (excluded_dir_lines and not updated):
        print("\nRESULT: BUG PRESENT — the exclusion zone swallowed the watched")
        print("tree: nothing was scanned and the move produced no reference update.")
        sys.exit(1)
    print("\nRESULT: CLEAN — the watched tree was scanned and the move was")
    print("processed normally with the log living outside the project root.")
    sys.exit(0)


def cleanup():
    if PLAYGROUND.exists():
        shutil.rmtree(PLAYGROUND)
        print(f"Removed {PLAYGROUND}")
    else:
        print("Nothing to clean up.")


if __name__ == "__main__":
    actions = {"setup": setup, "check": check, "cleanup": cleanup}
    if len(sys.argv) != 2 or sys.argv[1] not in actions:
        print(__doc__)
        sys.exit(2)
    actions[sys.argv[1]]()
