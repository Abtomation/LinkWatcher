#!/usr/bin/env python3
"""
Manual validation for PD-BUG-102: a link written into an EXISTING monitored
file by an external tool was never indexed (no on_modified handler), so a
later move of the link's target ran with references_count=0 and left the
link pointing at the old path.

This script is itself the "external tool": it appends a markdown link into
an already-existing file while the LinkWatcher daemon runs, then you move
the target via normal filesystem actions and observe whether the link
follows.

How to validate the fix (project daemon must be running — check
`Get-Process python*` / the SessionStart hook output):

  1. python test/bug-validation/PD-BUG-102_modify_event_rescan_validation.py setup
     -> Creates test/bug-validation/_pd102_playground/ with target-file.md
        and notes.md (notes.md has NO link yet). Wait ~5s so the daemon
        indexes the new files.
  2. python test/bug-validation/PD-BUG-102_modify_event_rescan_validation.py add-link
     -> Appends a link to target-file.md into notes.md (external edit of an
        existing file — the exact PD-BUG-102 trigger). Wait ~5s.
  3. Move the target with File Explorer or PowerShell:
        Move-Item test/bug-validation/_pd102_playground/target-file.md `
                  test/bug-validation/_pd102_playground/moved/
     Wait ~15s (move_detect_delay correlation window).
  4. python test/bug-validation/PD-BUG-102_modify_event_rescan_validation.py check
     -> WITHOUT the fix: notes.md still points at the OLD path; the daemon
        log shows file_moved references_count=0 + no_references_found.
     -> WITH the fix: notes.md points at moved/target-file.md; the log shows
        file_links_scanned for notes.md after step 2, and the move rewrites
        one reference.
  5. python test/bug-validation/PD-BUG-102_modify_event_rescan_validation.py cleanup
"""

import shutil
import sys
from pathlib import Path

PLAYGROUND = Path(__file__).resolve().parent / "_pd102_playground"
TARGET = PLAYGROUND / "target-file.md"
NOTES = PLAYGROUND / "notes.md"
MOVED_DIR = PLAYGROUND / "moved"
LINK_LINE = (
    "\nSee [the target](test/bug-validation/_pd102_playground/target-file.md) for details.\n"
)


def setup():
    PLAYGROUND.mkdir(exist_ok=True)
    MOVED_DIR.mkdir(exist_ok=True)
    TARGET.write_text("# Target File\n\nContent that gets moved.\n", encoding="utf-8")
    NOTES.write_text("# Notes\n\nNo links yet.\n", encoding="utf-8")
    print(f"Created playground: {PLAYGROUND}")
    print("  target-file.md  (the file you will move in step 3)")
    print("  notes.md        (existing file — gets the link in step 2)")
    print("\nBEFORE state of notes.md:\n" + "-" * 40)
    print(NOTES.read_text(encoding="utf-8"))
    print("-" * 40)
    print("Wait ~5s for the daemon to index the new files, then run: add-link")


def add_link():
    if not NOTES.exists():
        sys.exit("notes.md missing — run setup first")
    NOTES.write_text(NOTES.read_text(encoding="utf-8") + LINK_LINE, encoding="utf-8")
    print("Appended link into EXISTING notes.md (external modification).")
    print("\nnotes.md is now:\n" + "-" * 40)
    print(NOTES.read_text(encoding="utf-8"))
    print("-" * 40)
    print("Wait ~5s, then move the target (step 3 in the docstring),")
    print("wait ~15s for move correlation, then run: check")


def check():
    if not NOTES.exists():
        sys.exit("notes.md missing — run setup first")
    content = NOTES.read_text(encoding="utf-8")
    print("AFTER state of notes.md:\n" + "-" * 40)
    print(content)
    print("-" * 40)
    old = "_pd102_playground/target-file.md" in content
    new = "_pd102_playground/moved/target-file.md" in content
    if new and not old:
        print("RESULT: PASS — link was rewritten to the new path (fix works)")
    elif old and not new:
        print("RESULT: FAIL — link still points at the OLD path (PD-BUG-102 behavior)")
        print("Check the daemon log for: file_moved references_count=0 / no_references_found")
    else:
        print("RESULT: INCONCLUSIVE — did the move happen? Is the daemon running?")


def cleanup():
    if PLAYGROUND.exists():
        shutil.rmtree(PLAYGROUND)
        print(f"Removed {PLAYGROUND}")
    else:
        print("Nothing to clean up.")


if __name__ == "__main__":
    actions = {"setup": setup, "add-link": add_link, "check": check, "cleanup": cleanup}
    if len(sys.argv) != 2 or sys.argv[1] not in actions:
        sys.exit(f"Usage: {Path(__file__).name} {{setup|add-link|check|cleanup}}\n\n{__doc__}")
    actions[sys.argv[1]]()
