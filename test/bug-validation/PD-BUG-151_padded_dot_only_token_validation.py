"""
PD-BUG-151 / TD305 Manual Validation: a dot-only token written with surrounding
whitespace evaded the PD-BUG-149 guard, and a padded directory reference went
silently stale.

PURPOSE:
    PD-BUG-149 stopped every parser registering a bare ``../`` written inside a
    quote or a backtick.  The guard -- ``utils.is_dot_only_path`` -- split the
    captured span on separators and required every segment to be ``.``, ``..``
    or empty.  It tested the span VERBATIM, so padding defeated it::

        '../../'    ->  ['..', '..', '']    -> dot-only, suppressed
        ' ../../ '  ->  [' ..', '..', ' ']  -> NOT dot-only, registered

    The padded token stayed registered, and the whole span INCLUDING its padding
    was then replaced by the recalculated value.  So the padded spelling was not
    merely re-depthed like PD-BUG-149 -- it was DESTROYED::

        "So ` ../../ ` lands two levels up."  ->  "So `..` lands two levels up."

    Silent, and counted in the daemon's ``moved_file_links_updated`` total.
    Measured destructive in five parsers; YAML and JSON put the damage in
    structured config VALUES rather than prose.

    The root cause (TD305) was that the parsers captured the padding INTO the
    reference span at all.  That had a second, quieter consequence: a padded
    DIRECTORY reference such as ``" ../doc/sub "`` never resolved on disk, so
    the existence guard skipped it and the reference silently went stale on a
    move -- no warning, no error, no count.

    The fix normalizes every reference at one choke point in
    ``BaseParser.parse_content``: strip the target, shrink the columns onto it,
    re-apply the path predicates so a token that only qualified BECAUSE of its
    padding is dropped, and drop references that normalization made identical.

HOW TO RUN:
    python test/bug-validation/PD-BUG-151_padded_dot_only_token_validation.py

WHAT TO OBSERVE:
    The script prints four files BEFORE and AFTER a real move one directory
    deeper, driving the daemon's own move handler.

    * The padded prose spans and padded config VALUES must come back
      BYTE-IDENTICAL.  Before the fix each collapsed to ``..``.

    * The padded DIRECTORY reference must be re-depthed and keep its padding.
      Before the fix it was left stale.

    * The genuine markdown link must still be re-depthed -- the feature works.

EXPECTED RESULT:
    All 6 checks pass.
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


def move_file(service, tmpdir, rel_from, rel_to, body):
    src = tmpdir / rel_from
    src.parent.mkdir(parents=True, exist_ok=True)
    src.write_text(body, encoding="utf-8")
    return src


def main():
    print("=" * 72)
    print("PD-BUG-151: a PADDED dot-only token must not be rewritten by a move")
    print("=" * 72)

    checks_passed = 0
    checks_total = 6

    note_body = (
        "See [x](../README.md) for details.\n"
        "So " + BT + " ../../ " + BT + " lands two levels up.\n"
        'A quoted padded token: " ../../ " in prose.\n'
        'See " ../doc/sub " for the sources.\n'
    )
    yaml_body = 'key: " ../../ "\nother: plain\n'
    json_body = '{\n  "key": " ../../ "\n}\n'
    ps1_body = '$x = " ../../ "\n'

    with tempfile.TemporaryDirectory() as tmpdir:
        tmpdir = Path(tmpdir)
        (tmpdir / "README.md").write_text("readme\n", encoding="utf-8")
        (tmpdir / "doc" / "sub").mkdir(parents=True)
        (tmpdir / "doc" / "sub" / "keep.md").write_text("keep\n", encoding="utf-8")
        (tmpdir / "sub" / "deeper").mkdir(parents=True)

        files = [
            ("note.md", note_body),
            ("conf.yaml", yaml_body),
            ("conf.json", json_body),
            ("script.ps1", ps1_body),
        ]
        for name, body in files:
            (tmpdir / "sub" / name).write_text(body, encoding="utf-8")
            show("BEFORE -- sub/" + name, body)

        service = LinkWatcherService(str(tmpdir))
        service._initial_scan()

        results = {}
        for name, _ in files:
            src = tmpdir / "sub" / name
            dst = tmpdir / "sub" / "deeper" / name
            src.rename(dst)
            service.handler.on_moved(FileMovedEvent(str(src), str(dst)))
            results[name] = dst.read_text(encoding="utf-8")
            show("AFTER  -- sub/deeper/" + name, results[name])

        print()
        note_lines = results["note.md"].rstrip("\n").split("\n")
        note_original = note_body.rstrip("\n").split("\n")

        # Check 1: the genuine markdown link followed the move.
        if "[x](../../README.md)" in note_lines[0]:
            print("[PASS] Check 1: the real markdown link was re-depthed")
            checks_passed += 1
        else:
            print(
                "[FAIL] Check 1: the real link did not follow the move: {!r}".format(note_lines[0])
            )

        # Checks 2-3: padded prose spans byte-identical (backtick and quoted).
        for offset, label in ((1, "padded backtick"), (2, "padded quoted")):
            if note_lines[offset] == note_original[offset]:
                print("[PASS] Check {}: {} span untouched".format(offset + 1, label))
                checks_passed += 1
            else:
                print(
                    "[FAIL] Check {}: {} span was rewritten\n"
                    "         authored: {!r}\n"
                    "         now:      {!r}".format(
                        offset + 1, label, note_original[offset], note_lines[offset]
                    )
                )

        # Check 4: TD305 -- the padded DIRECTORY reference followed the move.
        if note_lines[3] == 'See " ../../doc/sub " for the sources.':
            print("[PASS] Check 4: padded directory reference followed the move (TD305)")
            checks_passed += 1
        else:
            print(
                "[FAIL] Check 4: padded directory reference not updated as expected\n"
                "         now: {!r}".format(note_lines[3])
            )

        # Checks 5-6: structured config VALUES survive byte-identical.
        for check_no, name, original in (
            (5, "conf.yaml", yaml_body),
            (6, "conf.json", json_body),
        ):
            if results[name] == original:
                print("[PASS] Check {}: {} value untouched".format(check_no, name))
                checks_passed += 1
            else:
                print(
                    "[FAIL] Check {}: {} value was rewritten\n"
                    "         authored: {!r}\n"
                    "         now:      {!r}".format(check_no, name, original, results[name])
                )

        # Reported, not a numbered check: the PowerShell shape is covered by the
        # automated suite's double-replacement guard.
        if results["script.ps1"] != ps1_body:
            print("[NOTE] script.ps1 changed: {!r} -> {!r}".format(ps1_body, results["script.ps1"]))

    print("\n" + "=" * 72)
    print("RESULT: {}/{} checks passed".format(checks_passed, checks_total))
    print("=" * 72)
    return 0 if checks_passed == checks_total else 1


if __name__ == "__main__":
    sys.exit(main())
