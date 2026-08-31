"""
PD-BUG-153 Manual Validation: markdown link text and chained targets in a moved file.

PURPOSE:
    Two defects in the markdown half of the within-moved-file rewrite, fixed
    together.

    (1) Stale link text.  The markdown branch carried its own copy of the
        markdown regex instead of calling the shared
        ``replacement.replace_markdown_target``, so it never applied the
        PD-BUG-012 rule that updates a link's TEXT when the text is exactly the
        old target.  A self-named link -- the ``[references/x.md](references/x.md)``
        idiom -- had its target re-depthed while the visible text kept
        advertising a path that no longer resolves from the new location.  The
        updater path (references in OTHER files) has done this correctly for
        months; only the moved-file path diverged.  Silent, and counted as a
        successful update.

    (2) Compounded targets.  That branch replaced CONTENT-GLOBALLY, once per
        reference, in sequence.  When one reference's NEW target equalled a
        later reference's OLD target, the later pass rewrote the earlier
        reference a second time -- silently pointing a link at a different file.
        This is the PD-BUG-150 compounding shape surviving in the markdown half.

    Both are closed by the same change: each markdown link is now rewritten at
    the column span the parser recorded for it, through the shared helper, so no
    reference can observe another's output and the link-text rule arrives with
    the helper rather than being copied.

    Two mechanisms carry that fix and the checks below separate them, because
    they are NOT interchangeable.  Right-to-left ordering alone repairs the
    FORWARD chain (Check 2).  Only span confinement repairs the REVERSE chain
    (Check 3), where the left-hand link's old target is what the right-hand link
    becomes -- ordering cannot help there, because the right-hand link is
    already rewritten by the time the left-hand pass runs.  A validation that
    exercised only the forward shape would score 5/5 against a fix missing span
    confinement, which is exactly what an earlier draft of this script did.

HOW TO RUN:
    python test/bug-validation/PD-BUG-153_moved_file_markdown_link_text_validation.py

TO OBSERVE THE BUG YOURSELF (filesystem reproduction, no code):
    1. In any project watched by a running LinkWatcher daemon, create
       ``doc/a.md``, ``sub/doc/a.md``, ``sub/mid/doc/a.md`` and a directory
       ``sub/mid/deeper/``.
    2. Create ``sub/mid/note.md`` containing these lines:
           [../doc/a.md](../doc/a.md)
           [x](doc/a.md) then [y](../doc/a.md)
           [a](../../doc/a.md) and [b](../doc/a.md)
    3. Move ``sub/mid/note.md`` to ``sub/mid/deeper/note.md`` (VS Code,
       Explorer, or ``git mv`` -- any method).
    4. Open the moved file.  Against a pre-fix daemon line 1 reads
       ``[../doc/a.md](../../doc/a.md)`` -- the visible text still names the old
       path -- and ``[x]`` has been dragged to ``../../doc/a.md``, a different
       file from the ``sub/mid/doc/a.md`` it was written for.  Against a fixed
       daemon line 1 reads ``[../../doc/a.md](../../doc/a.md)``, ``[x]`` reads
       ``../doc/a.md``, and ``[b]`` reads ``../../doc/a.md``.

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
    "Self-named: [../doc/a.md](../doc/a.md)\n"
    'Self-named with title: [../doc/a.md](../doc/a.md "The A doc")\n'
    "Normal text: [A doc](../doc/a.md)\n"
    "Backticked text: [`../doc/a.md`](../doc/a.md)\n"
    "Forward chain: [x](doc/a.md) then [y](../doc/a.md)\n"
    "Reverse chain: [a](../../doc/a.md) and [b](../doc/a.md)\n"
    "Definition usage: [see it][lbl].\n"
    "\n"
    '[lbl]: ../doc/a.md "Title"\n'
)

EXPECTED = (
    "# Notes\n"
    "\n"
    "Self-named: [../../doc/a.md](../../doc/a.md)\n"
    'Self-named with title: [../../doc/a.md](../../doc/a.md "The A doc")\n'
    "Normal text: [A doc](../../doc/a.md)\n"
    "Backticked text: [`../doc/a.md`](../../doc/a.md)\n"
    "Forward chain: [x](../doc/a.md) then [y](../../doc/a.md)\n"
    "Reverse chain: [a](../../../doc/a.md) and [b](../../doc/a.md)\n"
    "Definition usage: [see it][lbl].\n"
    "\n"
    '[lbl]: ../../doc/a.md "Title"\n'
)


def main():
    print("=" * 68)
    print("PD-BUG-153: moved-file markdown link text and chained targets")
    print("=" * 68)

    with tempfile.TemporaryDirectory() as tmpdir:
        tmpdir = Path(tmpdir)

        # Three real targets at three depths, so both chain shapes are genuine:
        # from sub/mid/, doc/a.md is sub/mid/doc/a.md, ../doc/a.md is
        # sub/doc/a.md, and ../../doc/a.md is doc/a.md.
        for rel in ("doc/a.md", "sub/doc/a.md", "sub/mid/doc/a.md"):
            p = tmpdir / rel
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text("# a", encoding="utf-8")

        note = tmpdir / "sub" / "mid" / "note.md"
        note.write_text(AUTHORED, encoding="utf-8")

        print()
        print("BEFORE (sub/mid/note.md):")
        print("-" * 68)
        print(AUTHORED, end="")
        print("-" * 68)

        service = LinkWatcherService(str(tmpdir))
        service._initial_scan()

        deeper = tmpdir / "sub" / "mid" / "deeper"
        deeper.mkdir()
        moved = deeper / "note.md"
        note.rename(moved)
        service.handler._handle_file_moved(FileMovedEvent(str(note), str(moved)))

        updated = moved.read_text(encoding="utf-8")

        print()
        print("AFTER (sub/mid/deeper/note.md):")
        print("-" * 68)
        print(updated, end="")
        print("-" * 68)
        print()

        checks_passed = 0
        total_checks = 6

        # Check 1: PD-BUG-153 proper -- self-named text followed its target.
        if "[../../doc/a.md](../../doc/a.md)" in updated:
            print("[PASS] Check 1: self-named link text was updated with its target")
            checks_passed += 1
        else:
            print("[FAIL] Check 1: self-named link text is stale -- the visible text")
            print("               still advertises a path that no longer resolves")

        # Check 2: forward chain.  [x] was written for sub/mid/doc/a.md and must
        # land on ../doc/a.md, not be dragged to [y]'s depth.  Repaired by the
        # right-to-left ordering.
        if "[x](../doc/a.md)" in updated and "[x](../../doc/a.md)" not in updated:
            print("[PASS] Check 2: the forward-chained link kept its own target")
            checks_passed += 1
        else:
            print("[FAIL] Check 2: the forward-chained link was rewritten twice -- it")
            print("               now points at a different file than it was written for")

        # Check 3: reverse chain.  [b] must land on ../../doc/a.md and must NOT
        # be caught by [a]'s pass.  Ordering cannot repair this one -- only
        # confining each replacement to its own span can.
        if "[b](../../doc/a.md)" in updated and "[b](../../../doc/a.md)" not in updated:
            print("[PASS] Check 3: the reverse-chained link kept its own target")
            checks_passed += 1
        else:
            print("[FAIL] Check 3: the reverse-chained link was overwritten by the")
            print("               left-hand link's replacement reaching past its span")

        # Check 4: the exact-equality boundary held -- backticked text is not
        # the target, so it must be left exactly as authored.
        if "[`../doc/a.md`](../../doc/a.md)" in updated:
            print("[PASS] Check 4: backticked link text was left untouched")
            checks_passed += 1
        else:
            print("[FAIL] Check 4: backticked link text was rewritten -- the rule is")
            print("               exact equality, and this text is not the target")

        # Check 5: reference definition kept its label and title.
        if '[lbl]: ../../doc/a.md "Title"' in updated:
            print("[PASS] Check 5: the reference definition kept label and title")
            checks_passed += 1
        else:
            print("[FAIL] Check 5: the reference definition lost its label or title")

        # Check 6: whole-file equality -- nothing else moved.
        if updated == EXPECTED:
            print("[PASS] Check 6: file matches the expected rewrite exactly")
            checks_passed += 1
        else:
            print("[FAIL] Check 6: file differs from the expected rewrite")
            print("       expected: {!r}".format(EXPECTED))
            print("       actual  : {!r}".format(updated))

        print()
        print("=" * 68)
        print("Result: {}/{} checks passed".format(checks_passed, total_checks))
        print("=" * 68)
        return 0 if checks_passed == total_checks else 1


if __name__ == "__main__":
    sys.exit(main())
