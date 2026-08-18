"""
Manual validation test for PD-BUG-120: the authored trailing separator is
stripped from links INSIDE a moved file.

PURPOSE:
  Verify that when a file MOVES, the relative links it contains are re-pointed
  at their targets without changing HOW they were written. A directory
  reference authored as `doc/state-tracking/` must come back as
  `../doc/state-tracking/` - with its trailing separator - not
  `../doc/state-tracking`.

  Sibling of PD-BUG-118, which fixed the same loss on the OTHER path:
  references in other files, rewritten when the TARGET moves (via
  utils.apply_trailing_separator_style at the PathResolver.calculate_new_target
  choke point). That choke point never sees the within-moved-file recalculation
  in reference_lookup._calculate_updated_relative_path, which returned raw
  os.path.relpath output at three sites.

HOW TO RUN:
  python test/bug-validation/PD-BUG-120_trailing_separator_within_moved_file_validation.py

WHAT IT DOES (reproducible by hand: create the files, then move notes.md into
sub/ with File Explorer or VS Code while LinkWatcher runs):
  1. Creates a temp project containing a real doc/state-tracking/ tree and a
     real logs/linkwatcher/ tree.
  2. Creates notes.md at the project root with a markdown link to
     doc/state-tracking/ (trailing slash authored).
  3. Creates collect.py at the project root whose LOG_DIR constant is
     "logs/linkwatcher/" - a path used as a CONCATENATION PREFIX.
  4. Initializes LinkWatcher and moves both files into sub/.
  5. Prints each file BEFORE and AFTER, plus what the concatenation in
     collect.py evaluates to, so you can compare them directly.

EXPECTED RESULT (fixed):
  - notes.md   -> [state](../doc/state-tracking/)   trailing slash KEPT
  - collect.py -> LOG_DIR = "../logs/linkwatcher/"  trailing slash KEPT, so
                  LOG_DIR + "run.log" still yields ../logs/linkwatcher/run.log

PRE-FIX BEHAVIOUR (the bug):
  - notes.md   -> [state](../doc/state-tracking)    slash silently dropped
  - collect.py -> LOG_DIR = "../logs/linkwatcher"   slash silently dropped, so
                  LOG_DIR + "run.log" yields ../logs/linkwatcherrun.log - a
                  broken path, with no warning logged
"""

import sys
import tempfile
from pathlib import Path

# Add project root to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from watchdog.events import FileMovedEvent  # noqa: E402

from linkwatcher.service import LinkWatcherService  # noqa: E402


def _show(label, text):
    print(f"    {label}")
    for line in text.rstrip("\n").split("\n"):
        print("      " + repr(line))


def run_validation():
    """Run the manual validation test."""
    print("=" * 72)
    print("PD-BUG-120: Trailing separator stripped inside a moved file - validation")
    print("=" * 72)

    with tempfile.TemporaryDirectory() as tmpdir:
        tmp_path = Path(tmpdir)

        # --- Setup ---
        print("\n[1] Setting up test project...")
        tracking = tmp_path / "doc" / "state-tracking"
        tracking.mkdir(parents=True)
        (tracking / "feature-tracking.md").write_text("# Feature Tracking\n", encoding="utf-8")

        log_dir = tmp_path / "logs" / "linkwatcher"
        log_dir.mkdir(parents=True)
        (log_dir / "LinkWatcherLog.txt").write_text("log\n", encoding="utf-8")

        notes = tmp_path / "notes.md"
        md_before = "# Notes\n\nSee [state](doc/state-tracking/) for current status.\n"
        notes.write_text(md_before, encoding="utf-8")

        collector = tmp_path / "collect.py"
        py_before = 'LOG_DIR = "logs/linkwatcher/"\n' 'path = LOG_DIR + "run.log"\n'
        collector.write_text(py_before, encoding="utf-8")

        _show("BEFORE notes.md:", md_before)
        _show("BEFORE collect.py:", py_before)
        print("      concatenation yields: 'logs/linkwatcher/run.log'")

        # --- Move the CONTAINING files (not their targets) ---
        print("\n[2] Initializing LinkWatcher and moving")
        print("    notes.md -> sub/notes.md and collect.py -> sub/collect.py ...")
        service = LinkWatcherService(str(tmp_path))
        service._initial_scan()

        sub = tmp_path / "sub"
        sub.mkdir()

        new_notes = sub / "notes.md"
        notes.rename(new_notes)
        service.handler.on_moved(FileMovedEvent(str(notes), str(new_notes)))

        new_collector = sub / "collect.py"
        collector.rename(new_collector)
        service.handler.on_moved(FileMovedEvent(str(collector), str(new_collector)))

        md_after = new_notes.read_text(encoding="utf-8")
        py_after = new_collector.read_text(encoding="utf-8")

        print("\n[3] AFTER:")
        _show("AFTER  sub/notes.md:", md_after)
        _show("AFTER  sub/collect.py:", py_after)

        # What the concatenation in the moved file now evaluates to
        prefix = ""
        for line in py_after.split("\n"):
            if line.startswith("LOG_DIR = "):
                prefix = line.split('"')[1] if '"' in line else ""
        print(f"      concatenation yields: {prefix + 'run.log'!r}")

        # --- Checks ---
        print("\n[4] Verifying...")
        checks = {
            "markdown: link re-pointed for the new depth": "(../doc/state-tracking" in md_after,
            "markdown: authored trailing slash kept": "(../doc/state-tracking/)" in md_after,
            "markdown: surrounding prose intact": (
                md_after.startswith("# Notes\n\nSee [state](")
                and md_after.rstrip().endswith("for current status.")
            ),
            "python: prefix re-pointed for the new depth": '"../logs/linkwatcher' in py_after,
            "python: authored trailing slash kept": '"../logs/linkwatcher/"' in py_after,
            "python: concatenation still yields a valid path": (
                prefix + "run.log" == "../logs/linkwatcher/run.log"
            ),
        }

        all_passed = True
        for label, ok in checks.items():
            print(f"    [{'PASS' if ok else 'FAIL'}] {label}")
            all_passed = all_passed and ok

        print("\n" + "=" * 72)
        if all_passed:
            print("RESULT: ALL CHECKS PASSED - links re-pointed, authored form preserved.")
        else:
            print("RESULT: SOME CHECKS FAILED - the authored trailing separator was lost.")
        print("=" * 72)
        return all_passed


if __name__ == "__main__":
    success = run_validation()
    sys.exit(0 if success else 1)
