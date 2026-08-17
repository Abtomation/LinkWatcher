"""
Manual validation test for PD-BUG-118: the reference-update pass strips trailing
slashes and doubles segment letters in path spans.

PURPOSE:
  Verify that when a referenced directory moves, LinkWatcher rewrites ONLY the
  matched path substring. Two distinct defects are covered:

    Defect A - docstring column offset.
      The Python parser recorded a docstring reference's columns relative to the
      extracted docstring text rather than the physical line, so on any line that
      CONTAINS triple quotes the recorded columns were short by the length of the
      text before the docstring content (e.g. len('    \"\"\"') == 7). The updater
      then sliced the line at those stale columns, consuming and duplicating the
      characters next to the real path.

    Defect B - trailing-slash loss.
      Every rewrite returned normalize_path() output, and os.path.normpath strips
      a trailing separator. A directory reference authored as `doc/x/` came back
      as `doc/x`, so the authored form was damaged on every rewrite.

HOW TO RUN:
  python test/bug-validation/PD-BUG-118_path_span_corruption_validation.py

WHAT IT DOES (reproducible by hand: create the files, then move the directory in
File Explorer / VS Code while LinkWatcher runs):
  1. Creates a temp project containing a real doc/state-tracking/permanent/ tree.
  2. Creates scripts/performance_db.py whose one-line docstring mentions
     doc/state-tracking/permanent/. (the exact shape from the bug's evidence).
  3. Creates README.md with a backticked directory span `doc/state-tracking/`.
  4. Initializes LinkWatcher and moves doc/state-tracking -> doc/moved-tracking.
  5. Prints each file BEFORE and AFTER so you can compare them directly.

EXPECTED RESULT (fixed):
  - The docstring reads: \"\"\"Resolve database path to doc/moved-tracking/permanent/.\"\"\"
    Prose before and after the path is byte-identical; the closing quotes survive.
  - The markdown span reads: `doc/moved-tracking/` - trailing slash KEPT, and the
    surrounding backticks are intact.

PRE-FIX BEHAVIOUR (the bug):
  - docstring -> 'Resolve database pdoc/moved-tracking/permanentanent/.'
    (leading letter doubled, prose eaten, tail chopped)
  - markdown  -> `doc/moved-tracking`  (authored trailing slash silently dropped)
"""

import sys
import tempfile
from pathlib import Path

# Add project root to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from watchdog.events import DirMovedEvent  # noqa: E402

from linkwatcher.service import LinkWatcherService  # noqa: E402


def _show(label, text):
    print(f"    {label}")
    for line in text.rstrip("\n").split("\n"):
        print("      " + repr(line))


def run_validation():
    """Run the manual validation test."""
    print("=" * 72)
    print("PD-BUG-118: Path-span corruption on reference update - validation")
    print("=" * 72)

    with tempfile.TemporaryDirectory() as tmpdir:
        tmp_path = Path(tmpdir)

        # --- Setup ---
        print("\n[1] Setting up test project...")
        permanent = tmp_path / "doc" / "state-tracking" / "permanent"
        permanent.mkdir(parents=True)
        (permanent / "feature-tracking.md").write_text("# Feature Tracking\n", encoding="utf-8")

        scripts = tmp_path / "scripts"
        scripts.mkdir()
        pyfile = scripts / "performance_db.py"
        py_before = (
            "def _resolve_db_path():\n"
            '    """Resolve database path to doc/state-tracking/permanent/."""\n'
            '    return "results.db"\n'
        )
        pyfile.write_text(py_before, encoding="utf-8")

        readme = tmp_path / "README.md"
        md_before = "See the `doc/state-tracking/` tracker for current status.\n"
        readme.write_text(md_before, encoding="utf-8")

        _show("BEFORE scripts/performance_db.py:", py_before)
        _show("BEFORE README.md:", md_before)

        # --- Move the referenced directory ---
        print("\n[2] Initializing LinkWatcher and moving")
        print("    doc/state-tracking -> doc/moved-tracking ...")
        service = LinkWatcherService(str(tmp_path))
        service._initial_scan()

        old_dir = tmp_path / "doc" / "state-tracking"
        new_dir = tmp_path / "doc" / "moved-tracking"
        old_dir.rename(new_dir)
        service.handler.on_moved(DirMovedEvent(str(old_dir), str(new_dir)))

        py_after = pyfile.read_text(encoding="utf-8")
        md_after = readme.read_text(encoding="utf-8")

        print("\n[3] AFTER:")
        _show("AFTER  scripts/performance_db.py:", py_after)
        _show("AFTER  README.md:", md_after)

        # --- Checks ---
        print("\n[4] Verifying...")
        expected_docstring_line = (
            '    """Resolve database path to doc/moved-tracking/permanent/."""'
        )
        checks = {
            # Defect A - no character consumed or duplicated around the span.
            # The exact-line comparison is the load-bearing one: a substring
            # check like `"anent/." not in py_after` would fire on the CORRECT
            # output too, since it is a substring of "permanent/.".
            "docstring: line byte-identical apart from the path": (
                expected_docstring_line in py_after
            ),
            "docstring: prose before path intact ('Resolve database path to ')": (
                "Resolve database path to " in py_after
            ),
            "docstring: no doubled leading letter (pdoc/)": "pdoc/" not in py_after,
            "docstring: sentence period not eaten": "permanent/." in py_after,
            "docstring: no duplicated segment tail": "permanentanent" not in py_after,
            "docstring: closing triple quotes survive": '."""' in py_after,
            # Defect B - authored trailing slash preserved
            "markdown: directory reference updated": "doc/moved-tracking" in md_after,
            "markdown: authored trailing slash kept": "`doc/moved-tracking/`" in md_after,
            "markdown: backticks intact": md_after.count("`") == 2,
            "markdown: surrounding prose intact": (
                md_after.startswith("See the `")
                and md_after.rstrip().endswith("for current status.")
            ),
        }

        all_passed = True
        for label, ok in checks.items():
            print(f"    [{'PASS' if ok else 'FAIL'}] {label}")
            all_passed = all_passed and ok

        print("\n" + "=" * 72)
        if all_passed:
            print("RESULT: ALL CHECKS PASSED - only the matched path span was rewritten.")
        else:
            print("RESULT: SOME CHECKS FAILED - file content was corrupted.")
        print("=" * 72)
        return all_passed


if __name__ == "__main__":
    success = run_validation()
    sys.exit(0 if success else 1)
