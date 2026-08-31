"""
PD-BUG-149 Manual Validation: a bare ``../`` written in prose is notation, not a
link, and must survive a move that changes the file's depth.

PURPOSE:
    ``utils.looks_like_directory_path`` accepted any string carrying a
    separator, and ``utils.looks_like_file_path`` accepted any string carrying a
    separator and a dot.  A bare parent-directory token satisfies both, so every
    parser registered ``../`` written inside a quote or a backtick as a real
    reference.

    Nothing looks wrong until the containing file MOVES to a different depth.
    The within-moved-file rewrite then re-depths those tokens exactly as it
    re-depths genuine links, and the prose changes meaning:

        "a template carries 7 `../` links"  ->  "... 7 `../../` links"

    The damage is silent.  The daemon logs ``moved_file_links_updated`` with a
    count that includes the prose spans, and emits no warning.

    Observed 2026-08-29 in the appdev workspace: a git mv of four concept
    documents one directory deeper corrupted three prose spans in
    PRJ-000_template-link-depth-independence.md.  Two sibling files that
    contained only real links moved correctly, which is what isolated the defect
    to bare-token handling.

    The fix guards both predicates through the shared ``is_dot_only_path()``.

HOW TO RUN:
    python test/bug-validation/PD-BUG-149_dot_only_prose_token_validation.py

WHAT TO OBSERVE:
    The script prints notes.md BEFORE and AFTER a real file move (the file is
    moved one directory deeper, driving the daemon's own move handler).

    * The genuine markdown link on line 1 MUST be re-depthed:
      ``](../README.md)`` becomes ``](../../README.md)``.  This is the feature
      working — the fix must not disable it.

    * The three prose lines MUST be byte-identical.  Before the fix each one
      gained a ``../`` segment; after the fix none of them changes.

    * Line 5 is the over-correction guard: a NAMED backtick path
      (``../README.md`` in backticks) is a real reference and must still follow
      the move.

EXPECTED RESULT:
    All 5 checks pass.
"""

import sys
import tempfile
from pathlib import Path

project_root = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(project_root))

from watchdog.events import FileMovedEvent  # noqa: E402

from linkwatcher.service import LinkWatcherService  # noqa: E402

BT = chr(96)  # backtick


def show(label, text):
    print("\n" + label)
    for i, line in enumerate(text.rstrip("\n").split("\n"), 1):
        print("  {}: {}".format(i, line))


def main():
    print("=" * 72)
    print("PD-BUG-149: bare ../ in prose must not be re-depthed by a move")
    print("=" * 72)

    checks_passed = 0
    checks_total = 5

    body = (
        "See [x](../README.md) for details.\n"
        "A template carries 7 " + BT + "../" + BT + " links.\n"
        "So " + BT + "../../" + BT + " lands one level up.\n"
        "Each " + BT + "../" + BT + " link is depth-bound.\n"
        "Sources live in " + BT + "../README.md" + BT + " today.\n"
    )

    with tempfile.TemporaryDirectory() as tmpdir:
        tmpdir = Path(tmpdir)
        (tmpdir / "README.md").write_text("readme\n", encoding="utf-8")
        (tmpdir / "sub" / "deeper").mkdir(parents=True)

        notes = tmpdir / "sub" / "note.md"
        notes.write_text(body, encoding="utf-8")

        show("BEFORE -- sub/note.md", body)

        service = LinkWatcherService(str(tmpdir))
        service._initial_scan()

        moved = tmpdir / "sub" / "deeper" / "note.md"
        notes.rename(moved)
        service.handler.on_moved(FileMovedEvent(str(notes), str(moved)))

        result = moved.read_text(encoding="utf-8")
        show("AFTER  -- sub/deeper/note.md", result)

        lines = result.rstrip("\n").split("\n")
        original = body.rstrip("\n").split("\n")

        print()

        # Check 1: the genuine markdown link followed the move.
        if "[x](../../README.md)" in lines[0]:
            print("[PASS] Check 1: the real markdown link was re-depthed")
            checks_passed += 1
        else:
            print("[FAIL] Check 1: the real link did not follow the move: {!r}".format(lines[0]))

        # Checks 2-4: each prose line is byte-identical to what was authored.
        for offset, label in ((1, "carries 7"), (2, "so ../.. lands"), (3, "each ../ link")):
            if lines[offset] == original[offset]:
                print("[PASS] Check {}: prose line ({}) untouched".format(offset + 1, label))
                checks_passed += 1
            else:
                print(
                    "[FAIL] Check {}: prose line ({}) was rewritten\n"
                    "         authored: {!r}\n"
                    "         now:      {!r}".format(
                        offset + 1, label, original[offset], lines[offset]
                    )
                )

        # Check 5: over-correction guard -- a NAMED backtick path still moves.
        if BT + "../../README.md" + BT in lines[4]:
            print("[PASS] Check 5: a named backtick path still followed the move")
            checks_passed += 1
        else:
            print("[FAIL] Check 5: named backtick path left stale: {!r}".format(lines[4]))

    print("\n" + "=" * 72)
    print("RESULT: {}/{} checks passed".format(checks_passed, checks_total))
    print("=" * 72)
    return 0 if checks_passed == checks_total else 1


if __name__ == "__main__":
    sys.exit(main())
