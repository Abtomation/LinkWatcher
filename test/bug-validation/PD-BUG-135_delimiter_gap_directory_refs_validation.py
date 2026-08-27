"""
PD-BUG-135 Manual Validation: the span BETWEEN two delimited literals is not a
directory reference -- and the real reference it was hiding now follows a move.

PURPOSE:
    The directory patterns are delimiter-class regexes that require a
    separator INSIDE the span::

        QUOTED_DIR_PATTERN     ['"]([^'"]*[/\\][^'"]*)['"]
        backtick_dir_pattern   `([^`]*[/\\][^`]*)`

    When a legitimate literal holds no separator the regex fails at that start
    position and re-anchors on the literal's CLOSING delimiter, pairing it with
    the NEXT literal's OPENING delimiter.  The text between two literals was
    therefore captured whenever it held a "/" or a "\\".

    Two consequences, and the second is the one that actually costs the user:

    (a) NOISE -- a bogus target that never resolves.  The dominant shape is two
        backticked literals joined by a slash: `a` / `b` yielded the target
        " / " 383 times in this repo's markdown alone.

    (b) SUPPRESSION -- markdown suppresses a lower-priority match that falls
        inside an already-claimed span, so a bogus span STRADDLING a real
        backticked directory hid that real reference.  It was never tracked,
        so it silently failed to follow a move.

HOW TO RUN:
    python test/bug-validation/PD-BUG-135_delimiter_gap_directory_refs_validation.py

WHAT TO OBSERVE:
    The script prints each document BEFORE and AFTER a real directory move.

    * notes.md line 1 holds the noise shape.  Before the fix the parser reports
      a directory target of " / "; after the fix it reports none.  Nothing in
      the file changes either way -- this half is database noise, not damage.

    * guide.md line 1 is the one to watch.  A prose apostrophe ("project's")
      opens a bogus span that straddles the real `doc/founding/inputs/`
      reference later on the line.  BEFORE the fix that reference is invisible
      and the line is left STALE by the move; AFTER the fix it is tracked and
      the path follows the move.

EXPECTED RESULT:
    All 4 checks pass.
"""

import sys
import tempfile
from pathlib import Path

project_root = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(project_root))

from watchdog.events import DirMovedEvent  # noqa: E402

from linkwatcher.parsers.markdown import MarkdownParser  # noqa: E402
from linkwatcher.service import LinkWatcherService  # noqa: E402

BT = chr(96)  # backtick
OLD = "doc/founding/inputs"
NEW = "doc/origin/inputs"


def show(label, text, stale_marker=None):
    print("\n" + label)
    for i, line in enumerate(text.rstrip("\n").split("\n"), 1):
        flag = ""
        if stale_marker and stale_marker in line:
            flag = "   <== STALE (did not follow the move)"
        print("  {}: {}{}".format(i, line, flag))


def main():
    print("=" * 72)
    print("PD-BUG-135: delimiter-gap spans, and the reference they were hiding")
    print("=" * 72)

    checks_passed = 0
    checks_total = 4

    # Line 1 of guide.md: an apostrophe in "project's" opens a bogus span that
    # straddles the genuine backticked directory later on the same line.
    # The bogus span runs from the apostrophe to the later double quote -- a
    # MISMATCHED delimiter pair -- and straddles the backticked path between
    # them, which markdown then suppresses as already claimed.  This is the
    # real shape from retrospective-documentation-creation.md line 383.
    guide_line = (
        "- The project's founding material is placed raw in "
        + BT
        + OLD
        + "/"
        + BT
        + ' and captured into the concept (or left unfilled with a "no material" note).\n'
    )
    # Line 1 of notes.md: the pure-noise shape -- two literals joined by a slash.
    notes_line = (
        "- " + BT + "dev.bat dev-setup" + BT + " / " + BT + "dev.bat pre-commit" + BT + "\n"
    )

    # ---------- Check 1 + 2: parse level, before any file movement ----------
    parser = MarkdownParser()

    noise_targets = [r.link_target for r in parser.parse_content(notes_line, "notes.md")]
    if " / " not in noise_targets:
        print("\n[PASS] Check 1: the gap between two backticked literals is not a target")
        checks_passed += 1
    else:
        print("\n[FAIL] Check 1: captured the gap as a directory: {}".format(noise_targets))

    guide_targets = [r.link_target for r in parser.parse_content(guide_line, "guide.md")]
    if OLD + "/" in guide_targets:
        print("[PASS] Check 2: the real reference behind the bogus span is visible")
        checks_passed += 1
    else:
        print("[FAIL] Check 2: the real reference is suppressed. targets={}".format(guide_targets))

    # ---------- Check 3 + 4: end to end through a real directory move -------
    with tempfile.TemporaryDirectory() as tmpdir:
        tmpdir = Path(tmpdir)

        watched = tmpdir / "doc" / "founding" / "inputs"
        watched.mkdir(parents=True)
        (watched / "origin.md").write_text("payload\n", encoding="utf-8")

        guide = tmpdir / "guide.md"
        notes = tmpdir / "notes.md"
        guide.write_text(guide_line, encoding="utf-8")
        notes.write_text(notes_line, encoding="utf-8")

        show("BEFORE -- guide.md", guide_line)
        show("BEFORE -- notes.md", notes_line)

        service = LinkWatcherService(str(tmpdir))
        service._initial_scan()

        new_dir = tmpdir / "doc" / "origin" / "inputs"
        new_dir.parent.mkdir(parents=True, exist_ok=True)
        watched.rename(new_dir)
        service.handler.on_moved(DirMovedEvent(str(watched), str(new_dir)))

        updated_guide = guide.read_text(encoding="utf-8")
        updated_notes = notes.read_text(encoding="utf-8")

        print("\nAFTER moving {} -> {}".format(OLD, NEW))
        show("AFTER -- guide.md", updated_guide, stale_marker=OLD)
        show("AFTER -- notes.md", updated_notes)

        if NEW in updated_guide and OLD not in updated_guide:
            print("\n[PASS] Check 3: the previously hidden reference followed the move")
            checks_passed += 1
        else:
            print("\n[FAIL] Check 3: guide.md line 1 left stale (reference never tracked)")

        # The noise line must be byte-identical: a gap is not a reference, so
        # nothing in it may be rewritten.
        if updated_notes == notes_line:
            print("[PASS] Check 4: the noise line is untouched by the move")
            checks_passed += 1
        else:
            print("[FAIL] Check 4: the noise line was rewritten:\n  {!r}".format(updated_notes))

    print("\n" + "=" * 72)
    print("RESULT: {}/{} checks passed".format(checks_passed, checks_total))
    print("=" * 72)
    return 0 if checks_passed == checks_total else 1


if __name__ == "__main__":
    sys.exit(main())
