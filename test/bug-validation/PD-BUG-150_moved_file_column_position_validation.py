"""
PD-BUG-150 Manual Validation: within-moved-file rewrite honours column positions.

PURPOSE:
    Verify that when a file carrying two or more references to the same (or a
    nested) target ON ONE LINE is moved to a different depth, each reference is
    rewritten at the position the parser found it.

    Before the fix, ``reference_lookup._replace_links_in_lines`` rewrote every
    non-markdown reference with ``line.replace(target, new, 1)``, discarding the
    column span the parser supplies.  Every replacement therefore landed on the
    LEFTMOST match:

        Run `../doc/a.md` then `../doc/a.md` again.        (authored)
        Run `../../../doc/a.md` then `../doc/a.md` again.  (pre-fix result)

    The first link is over-deepened into a path that resolves nowhere, and the
    second is left stale.  Both silently: the daemon logs
    ``moved_file_links_updated links_updated=2`` and emits no warning.

    Markdown links took a different branch (a content-global regex) and were
    never affected, which is why this needs its own observation.

    REWORK (2026-08-30, after Code Review rejected the first fix):
    The first fix routed EVERY non-markdown reference into position-based
    replacement.  A reference definition's recorded span covers the whole
    line, so the splice overwrote its label and title as well:

        [lbl]: ../doc/a.md "Title"   (authored)
        ../../doc/a.md               (first-fix result -- label and title gone)

    That destroys the definition and orphans every ``[text][lbl]`` usage in
    the file, again silently.  The definition line below observes it.

HOW TO RUN:
    python test/bug-validation/PD-BUG-150_moved_file_column_position_validation.py

    The script builds a throwaway project in a temp directory, drives a real
    move through the service handler, and prints the file before and after.

WHAT TO OBSERVE:
    The "AFTER" block must show BOTH references at ``../../`` depth.  Any
    ``../../../`` is the over-deepened first span; any remaining bare ``../``
    is the skipped second span.  Both are the bug.

TO OBSERVE THE BUG YOURSELF (filesystem reproduction, no code):
    1. In any project watched by a running LinkWatcher daemon, create
       ``doc/a.md`` and a directory ``sub/deeper/``.
    2. Create ``sub/note.md`` containing this single line:
           Run `../doc/a.md` then `../doc/a.md` again.
    3. Move ``sub/note.md`` to ``sub/deeper/note.md`` (VS Code, Explorer, or
       ``git mv`` -- any method).
    4. Open the moved file.  Against a pre-fix daemon the line reads
       ``Run `../../../doc/a.md` then `../doc/a.md` again.``  Against a fixed
       one, both spans read ``../../doc/a.md``.

    5. Round 3 (padding).  In the same project create ``sub/doc/target/`` and a
       file ``sub/script.ps1`` containing, with the spaces exactly as shown:
           $dir = "  doc/target  "
       Move it to ``sub/deeper/script.ps1``.  Against a pre-fix daemon the line
       comes back ``$dir = "../doc/target"`` -- re-depthed correctly, but the
       author's padding silently destroyed, because the recorded span covered
       whitespace the target no longer named.  Against a fixed one it reads
       ``$dir = "  ../doc/target  "``.  Extensionless on purpose: a target
       carrying a file extension is captured tight and never showed the bug.

EXPECTED RESULT:
    All 6 checks pass.
"""

import sys
import tempfile
from pathlib import Path

# Add project root to path
project_root = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(project_root))

from watchdog.events import FileMovedEvent  # noqa: E402

from linkwatcher.service import LinkWatcherService  # noqa: E402

AUTHORED = (
    "# Notes\n"
    "\n"
    "Run `../doc/a.md` then `../doc/a.md` again.\n"
    "Both `../doc/` and `../doc/` are the same real directory.\n"
    "A markdown pair: [a](../doc/a.md) and again [a](../doc/a.md).\n"
    "A definition usage: [see it][lbl].\n"
    "\n"
    '[lbl]: ../doc/a.md "Title"\n'
    "[plain]: ../doc/\n"
)

EXPECTED = (
    "# Notes\n"
    "\n"
    "Run `../../doc/a.md` then `../../doc/a.md` again.\n"
    "Both `../../doc/` and `../../doc/` are the same real directory.\n"
    "A markdown pair: [a](../../doc/a.md) and again [a](../../doc/a.md).\n"
    "A definition usage: [see it][lbl].\n"
    "\n"
    '[lbl]: ../../doc/a.md "Title"\n'
    "[plain]: ../../doc/\n"
)

# Round 3: the span covered padding the target did not name.  Extensionless so
# it reaches the quoted-DIRECTORY scan -- the one that strips its target.
PS_AUTHORED = '$dir = "  doc/target  "\n'
PS_EXPECTED = '$dir = "  ../doc/target  "\n'


def main():
    print("=" * 68)
    print("PD-BUG-150: within-moved-file rewrite column-position validation")
    print("=" * 68)

    with tempfile.TemporaryDirectory() as tmpdir:
        tmpdir = Path(tmpdir)

        # Setup: a real link target, and the file that will move one level deeper
        (tmpdir / "doc").mkdir()
        (tmpdir / "doc" / "a.md").write_text("# a", encoding="utf-8")

        (tmpdir / "sub").mkdir()
        note = tmpdir / "sub" / "note.md"
        note.write_text(AUTHORED, encoding="utf-8")

        print()
        print("BEFORE (sub/note.md):")
        print("-" * 68)
        print(AUTHORED, end="")
        print("-" * 68)

        service = LinkWatcherService(str(tmpdir))
        service._initial_scan()

        # Move one directory deeper -- every ../ must gain one level
        deeper = tmpdir / "sub" / "deeper"
        deeper.mkdir()
        moved = deeper / "note.md"
        note.rename(moved)
        service.handler._handle_file_moved(FileMovedEvent(str(note), str(moved)))

        updated = moved.read_text(encoding="utf-8")

        print()
        print("AFTER (sub/deeper/note.md):")
        print("-" * 68)
        print(updated, end="")
        print("-" * 68)
        print()

        # Round 3 scenario: a padded quoted DIRECTORY in a PowerShell file.
        # Its span covered the padding while its target did not, so positional
        # replacement spliced the bare target across the whitespace.
        (tmpdir / "sub" / "doc" / "target").mkdir(parents=True)
        script = tmpdir / "sub" / "script.ps1"
        script.write_text(PS_AUTHORED, encoding="utf-8")
        service._initial_scan()

        moved_script = deeper / "script.ps1"
        script.rename(moved_script)
        service.handler._handle_file_moved(FileMovedEvent(str(script), str(moved_script)))
        ps_updated = moved_script.read_text(encoding="utf-8")

        print("BEFORE (sub/script.ps1):        {!r}".format(PS_AUTHORED))
        print("AFTER  (sub/deeper/script.ps1): {!r}".format(ps_updated))
        print()

        checks_passed = 0
        total_checks = 6

        # Check 1: nothing over-deepened (the compounded first span)
        if "../../../" not in updated:
            print("[PASS] Check 1: no reference was rewritten twice (no ../../../)")
            checks_passed += 1
        else:
            print("[FAIL] Check 1: a reference was compounded to ../../../ -- the")
            print("               second span matched inside the first replacement")

        # Check 2: nothing left stale (the skipped second span)
        if "`../doc" not in updated and "](../doc" not in updated and ": ../doc" not in updated:
            print("[PASS] Check 2: no reference was left at its old depth")
            checks_passed += 1
        else:
            print("[FAIL] Check 2: a reference still reads ../doc -- it was skipped")

        # Check 3: every span reached the correct depth
        if updated.count("../../doc/a.md") == 5 and updated.count("../../doc/`") == 2:
            print("[PASS] Check 3: all eight references reached ../../ depth")
            checks_passed += 1
        else:
            print("[FAIL] Check 3: reference count at ../../ depth is wrong")

        # Check 4: the file is otherwise byte-identical to what was authored
        if updated == EXPECTED:
            print("[PASS] Check 4: file matches the expected rewrite exactly")
            checks_passed += 1
        else:
            print("[FAIL] Check 4: file differs from the expected rewrite")
            print("       expected: {!r}".format(EXPECTED))
            print("       actual  : {!r}".format(updated))

        # Check 5: reference definitions kept their label (and title)
        if '[lbl]: ../../doc/a.md "Title"' in updated and "[plain]: ../../doc/" in updated:
            print("[PASS] Check 5: reference definitions kept label and title")
            checks_passed += 1
        else:
            print("[FAIL] Check 5: a reference definition lost its label or title --")
            print("               the whole-line span was overwritten by the target")

        # Check 6: a padded quoted directory kept the whitespace it was authored
        # with (round 3).  Compares the WHOLE line: the target lands correctly in
        # every spelling, so any check that only looks for the new target passes
        # on the damaged output.
        if ps_updated == PS_EXPECTED:
            print("[PASS] Check 6: padded quoted directory kept its whitespace")
            checks_passed += 1
        else:
            print("[FAIL] Check 6: the authored padding was destroyed -- the bare")
            print("               target was spliced across a span that covered it")
            print("       expected: {!r}".format(PS_EXPECTED))
            print("       actual  : {!r}".format(ps_updated))

        print()
        print("=" * 68)
        print("Result: {}/{} checks passed".format(checks_passed, total_checks))
        print("=" * 68)
        return 0 if checks_passed == total_checks else 1


if __name__ == "__main__":
    sys.exit(main())
