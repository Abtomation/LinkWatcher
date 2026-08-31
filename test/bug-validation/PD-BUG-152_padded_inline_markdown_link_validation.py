"""
PD-BUG-152 Manual Validation: a padded inline markdown link was never
re-depthed on a move, in EITHER rewrite path.

PURPOSE:
    CommonMark allows whitespace around an inline link destination, and every
    spelling renders to the same anchor::

        [x]( ../doc/y.md )      [x]( ../doc/y.md)      [x](../doc/y.md )

    The markdown parser strips the captured destination, so ``link_target``
    holds the TIGHT path while the source line is padded.  The shared replacer
    ``replacement.replace_markdown_target`` then anchored its pattern on ``](``
    IMMEDIATELY followed by the target, and on the target immediately followed
    by a title or ``)``.  Neither juxtaposition can hold for a padded link, so
    the substitution matched nothing and the line came back unchanged -- leaving
    the link pointing at a path that no longer exists.

    The bug was filed as moved-file-only.  It was not.  Since the PD-BUG-153
    fix, BOTH rewrite paths funnel through that one replacer:

      * updater path     -- a padded link in ANY OTHER file referencing a moved
                            target.  Fails SILENTLY: no warning, no count.
                            This is the larger exposure.
      * moved-file path  -- a padded link inside the file that moves.  At least
                            emits ``link_target_not_found_on_line``.

    The fix widens the pattern to tolerate whitespace on both sides of the
    target and writes the authored whitespace back VERBATIM.  Preserving rather
    than normalizing it is the rule PD-BUG-118 / PD-BUG-120 / PD-BUG-124
    established, and which the reference-definition replacer already honoured:
    a rewrite changes WHERE a link points, never HOW it was written.

HOW TO RUN:
    python test/bug-validation/PD-BUG-152_padded_inline_markdown_link_validation.py

WHAT TO OBSERVE:
    The script prints two files BEFORE and AFTER a real move, driving the
    daemon's own move handler.

    * Every padded link must be re-depthed, with its authored spacing intact
      at the exact width it was written.  Before the fix each was left stale.

    * The tight controls must be re-depthed exactly as they always were.

    * The padded REFERENCE DEFINITION must keep working (it always did) -- it
      takes a different replacer, and the fix must not disturb it.

EXPECTED RESULT:
    All 8 checks pass.
"""

import sys
import tempfile
from pathlib import Path

project_root = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(project_root))

from watchdog.events import FileMovedEvent  # noqa: E402

from linkwatcher.service import LinkWatcherService  # noqa: E402


def show(label, text):
    print("\n" + label)
    for i, line in enumerate(text.rstrip("\n").split("\n"), 1):
        print("  {}: {}".format(i, line))


def main():
    print("=" * 72)
    print("PD-BUG-152: a PADDED inline markdown link must follow a move")
    print("=" * 72)

    passed = 0
    total = 8

    # Lives INSIDE the file that moves -> moved-file rewrite path.
    note_body = (
        "A padded both:    [d]( ../doc/a.md ) end.\n"
        "B padded leading: [d]( ../doc/a.md) end.\n"
        "C padded trailing:[d](../doc/a.md ) end.\n"
        'D padded + title: [d]( ../doc/a.md "The A doc" ) end.\n'
        "E tight control:  [d](../doc/a.md) end.\n"
        "F padded refdef below.\n"
        "[lbl]:  ../doc/a.md  \n"
    )

    with tempfile.TemporaryDirectory() as tmpdir:
        tmpdir = Path(tmpdir)
        (tmpdir / "doc").mkdir(parents=True)
        (tmpdir / "doc" / "a.md").write_text("a\n", encoding="utf-8")
        (tmpdir / "sub" / "deeper").mkdir(parents=True)

        # Lives in ANOTHER file, references the target that will move ->
        # updater rewrite path (the half the bug was not filed against).
        other_body = (
            "G padded both:    [d]( doc/a.md ) end.\n"
            "H padded leading: [d]( doc/a.md) end.\n"
            "I tight control:  [d](doc/a.md) end.\n"
        )
        (tmpdir / "other.md").write_text(other_body, encoding="utf-8")
        (tmpdir / "sub" / "note.md").write_text(note_body, encoding="utf-8")

        show("BEFORE -- sub/note.md   (moves; its own links re-depth)", note_body)
        show("BEFORE -- other.md      (stays; references the moved target)", other_body)

        service = LinkWatcherService(str(tmpdir))
        service._initial_scan()

        # --- Move 1: the note itself moves one level deeper. ---
        src = tmpdir / "sub" / "note.md"
        dst = tmpdir / "sub" / "deeper" / "note.md"
        src.rename(dst)
        service.handler.on_moved(FileMovedEvent(str(src), str(dst)))
        note_after = dst.read_text(encoding="utf-8")
        show("AFTER  -- sub/deeper/note.md", note_after)

        # --- Move 2: the TARGET moves; other.md must be rewritten. ---
        (tmpdir / "doc2").mkdir()
        tsrc = tmpdir / "doc" / "a.md"
        tdst = tmpdir / "doc2" / "a.md"
        tsrc.rename(tdst)
        service.handler.on_moved(FileMovedEvent(str(tsrc), str(tdst)))
        other_after = (tmpdir / "other.md").read_text(encoding="utf-8")
        show("AFTER  -- other.md", other_after)

        print()
        nl = note_after.rstrip("\n").split("\n")
        ol = other_after.rstrip("\n").split("\n")

        checks = [
            (
                "A padded-both re-depthed, spacing intact",
                nl[0] == "A padded both:    [d]( ../../doc/a.md ) end.",
            ),
            (
                "B padded-leading re-depthed, spacing intact",
                nl[1] == "B padded leading: [d]( ../../doc/a.md) end.",
            ),
            (
                "C padded-trailing re-depthed, spacing intact",
                nl[2] == "C padded trailing:[d](../../doc/a.md ) end.",
            ),
            (
                "D padded + title: both preserved",
                nl[3] == 'D padded + title: [d]( ../../doc/a.md "The A doc" ) end.',
            ),
            ("E tight control unaffected", nl[4] == "E tight control:  [d](../../doc/a.md) end."),
            ("F padded reference definition still works", nl[6] == "[lbl]:  ../../doc/a.md  "),
            (
                "G/H padded links in ANOTHER file updated (the unfiled half)",
                ol[0] == "G padded both:    [d]( doc2/a.md ) end."
                and ol[1] == "H padded leading: [d]( doc2/a.md) end.",
            ),
            (
                "I tight control in another file unaffected",
                ol[2] == "I tight control:  [d](doc2/a.md) end.",
            ),
        ]

        for label, ok in checks:
            if ok:
                print("[PASS] {}".format(label))
                passed += 1
            else:
                print("[FAIL] {}".format(label))

        print("\n{} of {} checks passed".format(passed, total))
        return 0 if passed == total else 1


if __name__ == "__main__":
    sys.exit(main())
