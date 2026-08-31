"""
PD-BUG-155 Manual Validation: a CommonMark angle-bracket destination was never
updated on a move, in EITHER rewrite path.

PURPOSE:
    CommonMark lets an inline link -- and a reference definition -- enclose its
    destination in angle brackets, and REQUIRES that form when the path holds a
    space::

        [x](<doc/a b.md>)          [label]: <doc/a b.md>

    ``MarkdownParser._extract_url_from_link_content`` peeled titles and stripped
    whitespace but never unwrapped those brackets, so ``link_target`` held
    ``<doc/a b.md>`` -- brackets included.  Everything downstream then failed for
    that single reason, each in its own way and every one of them SILENTLY:

      * updater path     -- the link database is keyed on target, so a moved
                            file never matched such a reference at all.  It was
                            not "skipped": it was never SELECTED.  No warning,
                            no count, no stale-file entry.  The larger exposure,
                            since it reaches every file referencing the target.
      * moved-file path  -- the bracketed "path" resolves to nothing on disk, so
                            the existence guard dropped it before replacement.
      * ``--validate``   -- the validator's placeholder filter matches
                            ``<[^>]+>``, so every angle-wrapped target was
                            discarded as a template placeholder and never
                            checked.  The documented recovery procedure could
                            not find the stale links either.

    The fix unwraps at capture and preserves at replacement: the two markdown
    replacers try an angle-wrapped pattern before the tight one and write the
    brackets back VERBATIM.  Preserving rather than normalizing the authored
    form is the PD-BUG-118 / PD-BUG-120 / PD-BUG-124 / PD-BUG-152 rule -- a
    rewrite changes WHERE a link points, never HOW it was written.

HOW TO RUN:
    python test/bug-validation/PD-BUG-155_angle_bracket_destination_validation.py

WHAT TO OBSERVE:
    The script prints two files BEFORE and AFTER real moves, driving the
    daemon's own move handler.

    * Every angle-bracket destination must follow the move with its brackets
      intact.  Before the fix every one was left byte-identical.

    * The SPACED cases matter most -- that is the one situation CommonMark
      requires this form for, and the form both live instances in this repo use.

    * The tight controls must behave exactly as they always did.

EXPECTED RESULT:
    All 9 checks pass.
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
    print("PD-BUG-155: an ANGLE-BRACKET destination must follow a move")
    print("=" * 72)

    passed = 0
    total = 9

    # Lives INSIDE the file that moves -> moved-file rewrite path.
    note_body = (
        "A angle plain:   [d](<../doc/a.md>) end.\n"
        "B angle spaced:  [d](<../doc/a b.md>) end.\n"
        'C angle + title: [d](<../doc/a.md> "The A doc") end.\n'
        "D tight control: [d](../doc/a.md) end.\n"
        "E angle refdef below.\n"
        "[lbl]: <../doc/a.md>\n"
    )

    with tempfile.TemporaryDirectory() as tmpdir:
        tmpdir = Path(tmpdir)
        (tmpdir / "doc").mkdir(parents=True)
        (tmpdir / "doc" / "a.md").write_text("a\n", encoding="utf-8")
        (tmpdir / "doc" / "a b.md").write_text("a b\n", encoding="utf-8")
        (tmpdir / "sub" / "deeper").mkdir(parents=True)

        # Lives in ANOTHER file, references targets that will move ->
        # updater rewrite path (the larger, fully silent half).
        other_body = (
            "F angle plain:   [d](<doc/a.md>) end.\n"
            "G angle spaced:  [d](<doc/a b.md>) end.\n"
            "H tight control: [d](doc/a.md) end.\n"
            "[lbl2]: <doc/a.md>\n"
        )
        (tmpdir / "other.md").write_text(other_body, encoding="utf-8")
        (tmpdir / "sub" / "note.md").write_text(note_body, encoding="utf-8")

        show("BEFORE -- sub/note.md   (moves; its own links re-depth)", note_body)
        show("BEFORE -- other.md      (stays; references the moved targets)", other_body)

        service = LinkWatcherService(str(tmpdir))
        service._initial_scan()

        # --- Move 1: the note itself moves one level deeper. ---
        src = tmpdir / "sub" / "note.md"
        dst = tmpdir / "sub" / "deeper" / "note.md"
        src.rename(dst)
        service.handler.on_moved(FileMovedEvent(str(src), str(dst)))
        note_after = dst.read_text(encoding="utf-8")
        show("AFTER  -- sub/deeper/note.md", note_after)

        # --- Move 2 and 3: the TARGETS move; other.md must be rewritten. ---
        (tmpdir / "doc2").mkdir()
        for name in ("a.md", "a b.md"):
            tsrc = tmpdir / "doc" / name
            tdst = tmpdir / "doc2" / name
            tsrc.rename(tdst)
            service.handler.on_moved(FileMovedEvent(str(tsrc), str(tdst)))
        other_after = (tmpdir / "other.md").read_text(encoding="utf-8")
        show("AFTER  -- other.md", other_after)

        print()
        nl = note_after.rstrip("\n").split("\n")
        ol = other_after.rstrip("\n").split("\n")

        checks = [
            (
                "A angle destination re-depthed, brackets intact",
                nl[0] == "A angle plain:   [d](<../../doc/a.md>) end.",
            ),
            (
                "B SPACED angle destination re-depthed (the form CommonMark requires)",
                nl[1] == "B angle spaced:  [d](<../../doc/a b.md>) end.",
            ),
            (
                "C angle + title: both preserved",
                nl[2] == 'C angle + title: [d](<../../doc/a.md> "The A doc") end.',
            ),
            ("D tight control unaffected", nl[3] == "D tight control: [d](../../doc/a.md) end."),
            (
                "E angle reference definition re-depthed, brackets intact",
                nl[5] == "[lbl]: <../../doc/a.md>",
            ),
            (
                "F angle destination in ANOTHER file updated (the fully silent half)",
                ol[0] == "F angle plain:   [d](<doc2/a.md>) end.",
            ),
            (
                "G SPACED angle destination in ANOTHER file updated",
                ol[1] == "G angle spaced:  [d](<doc2/a b.md>) end.",
            ),
            (
                "H tight control in another file unaffected",
                ol[2] == "H tight control: [d](doc2/a.md) end.",
            ),
            (
                "I angle reference definition in ANOTHER file updated",
                ol[3] == "[lbl2]: <doc2/a.md>",
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
