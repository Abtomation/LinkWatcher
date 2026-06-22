"""
Manual validation test for PD-BUG-112: reference-update pass corrupts non-path
content by normalizing backslashes to forward slashes.

PURPOSE:
  Verify that when a referenced directory moves, LinkWatcher rewrites the moved
  directory component WITHOUT flipping unrelated backslashes to '/'. In Python
  (and other) source, backslashes are often escape characters (\\n, \\t, \\")
  rather than path separators — flipping them corrupts the source (e.g. a Python
  SyntaxError).

HOW TO RUN:
  python test/bug-validation/PD-BUG-112_reference_update_separator_corruption_validation.py

WHAT IT DOES (reproducible by hand: create the files, then move the directory in
File Explorer / VS Code while LinkWatcher runs):
  1. Creates a temp project with a real directory blueprint/core/.
  2. Creates scripts/feedback_db.py containing:
       - a SQL string literal with \\n and \\t escape sequences,
       - a directory reference written with a backslash: "blueprint\\core".
  3. Initializes LinkWatcher and moves blueprint/ -> blueprint2/.
  4. Prints the file BEFORE and AFTER so you can compare.

EXPECTED RESULT (fixed):
  - The escape-laden SQL string is BYTE-IDENTICAL (no \\n -> /n corruption).
  - The directory reference updates blueprint -> blueprint2 but KEEPS its
    backslash: "blueprint\\core" -> "blueprint2\\core".

PRE-FIX BEHAVIOUR (the bug):
  - "blueprint\\core" -> "blueprint2/core"  (backslash flipped to '/')
  - escape sequences on any line that matched a moved prefix were likewise
    flipped, e.g. "...\\nFROM" -> "...​/nFROM" -> Python SyntaxError.
"""

import sys
import tempfile
from pathlib import Path

# Add project root to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from watchdog.events import DirMovedEvent  # noqa: E402

from linkwatcher.service import LinkWatcherService  # noqa: E402

BS = chr(92)  # a single backslash, used to build literal escape sequences


def run_validation():
    """Run the manual validation test."""
    print("=" * 64)
    print("PD-BUG-112: Reference-update separator corruption validation")
    print("=" * 64)

    with tempfile.TemporaryDirectory() as tmpdir:
        tmp_path = Path(tmpdir)

        # --- Setup ---
        print("\n[1] Setting up test project...")
        core = tmp_path / "blueprint" / "core"
        core.mkdir(parents=True)
        (core / "x.txt").write_text("data")

        scripts = tmp_path / "scripts"
        scripts.mkdir()
        pyfile = scripts / "feedback_db.py"
        # Build content with literal backslash escape sequences and a backslash
        # directory reference. Written via BS so there is no ambiguity.
        content = (
            "def query():\n"
            '    sql = "SELECT a' + BS + "nFROM t" + BS + 'tWHERE x"\n'
            '    template_dir = "blueprint' + BS + 'core"\n'
        )
        pyfile.write_text(content, encoding="utf-8")

        print("    BEFORE (on disk):")
        for line in content.split("\n"):
            print("      " + repr(line))

        # --- Move the referenced directory ---
        print("\n[2] Initializing LinkWatcher and moving blueprint/ -> blueprint2/ ...")
        service = LinkWatcherService(str(tmp_path))
        service._initial_scan()

        old_bp = tmp_path / "blueprint"
        new_bp = tmp_path / "blueprint2"
        old_bp.rename(new_bp)
        service.handler.on_moved(DirMovedEvent(str(old_bp), str(new_bp)))

        after = pyfile.read_text(encoding="utf-8")
        print("\n[3] AFTER (on disk):")
        for line in after.split("\n"):
            print("      " + repr(line))

        # --- Checks ---
        print("\n[4] Verifying...")
        checks = {
            "SQL \\n escape preserved (no /nFROM)": "/nFROM" not in after,
            "SQL \\t escape preserved (no /tWHERE)": "/tWHERE" not in after,
            "directory reference updated to blueprint2": "blueprint2" in after,
            "backslash separator preserved (blueprint2\\core)": "blueprint2" + BS + "core" in after,
            "no normalized form blueprint2/core": "blueprint2/core" not in after,
        }

        all_passed = True
        for label, ok in checks.items():
            print(f"    [{'PASS' if ok else 'FAIL'}] {label}")
            all_passed = all_passed and ok

        print("\n" + "=" * 64)
        if all_passed:
            print("RESULT: ALL CHECKS PASSED — escapes preserved, separator kept.")
        else:
            print("RESULT: SOME CHECKS FAILED — content was corrupted.")
        print("=" * 64)
        return all_passed


if __name__ == "__main__":
    success = run_validation()
    sys.exit(0 if success else 1)
