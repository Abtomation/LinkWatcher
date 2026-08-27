"""
PD-BUG-126 Manual Validation: escape-bearing JSON values are detected and updated.

PURPOSE:
    Verify that a JSON string value written with an escape sequence is tracked
    like its escape-free sibling, and is updated when its target moves.

    Before the fix the parser searched the RAW source line for the DECODED
    value.  Every escape makes those two differ, so the search failed, the
    reference was discarded with nothing written to the log, and the target
    was silently left stale on the next move.

    JSON has no escape-free string form, so this reached every value that has
    to be escaped at all.

HOW TO RUN:
    python test/bug-validation/PD-BUG-126_escaped_json_literal_validation.py

EXPECTED RESULT:
    All 6 checks pass.

CHECK 6 -- the escaping guard:
    The backslash-authored value is the one the bug was filed about, and the
    one that could re-introduce the PD-BUG-124 corruption class: its span
    covers an ESCAPED literal, so a replacement spliced in raw would emit a
    single backslash and break the string.  Check 6 pins BOTH halves -- the
    value is updated, and it comes back correctly escaped, leaving the file
    parseable.
"""

import json
import sys
import tempfile
from pathlib import Path

project_root = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(project_root))

from watchdog.events import FileMovedEvent  # noqa: E402

from linkwatcher.parsers.json_parser import JsonParser  # noqa: E402
from linkwatcher.service import LinkWatcherService  # noqa: E402

BS = chr(92)


def main():
    print("=" * 68)
    print("PD-BUG-126: escaped JSON literal detection and update validation")
    print("=" * 68)

    checks_passed = 0
    checks_total = 7

    with tempfile.TemporaryDirectory() as tmpdir:
        tmpdir = Path(tmpdir)

        target = tmpdir / "logs" / "sub" / "x.txt"
        target.parent.mkdir(parents=True)
        target.write_text("payload", encoding="utf-8")

        # Non-ASCII sibling: its authored spelling must survive a rewrite
        # untouched. json.dumps defaults to ensure_ascii=True, which would
        # re-spell it as a unicode escape -- valid, decode-identical, and
        # still wrong: a rewrite changes WHERE a target points, never HOW
        # it was written.
        nonascii = tmpdir / "logs" / "sub" / ("n" + "ö" + "te.txt")
        nonascii.write_text("payload", encoding="utf-8")

        config_json = tmpdir / "config.json"
        config_content = (
            "{\n"
            '  "escaped_slash":   "logs' + BS + "/sub" + BS + '/x.txt",\n'
            '  "escaped_unicode": "logs/sub/' + BS + 'u0078.txt",\n'
            '  "backslash":       "logs' + BS * 2 + "sub" + BS * 2 + 'x.txt",\n'
            '  "plain":           "logs/sub/x.txt",\n'
            '  "non_ascii":       "logs' + BS * 2 + "sub" + BS * 2 + "n" + "ö" + 'te.txt"\n'
            "}\n"
        )
        config_json.write_text(config_content, encoding="utf-8")

        print("\nSetup: config.json holds the same target in four spellings.")
        print("BEFORE move:\n" + config_content)

        # --- Check 1: all four spellings are detected -------------------
        refs = JsonParser().parse_content(config_content, str(config_json))
        if len(refs) == 5:
            print("[PASS] Check 1: parser detected all 5 spellings")
            print("       (before the fix only the plain one was detected)")
            checks_passed += 1
        else:
            print("[FAIL] Check 1: expected 5 refs, got {}".format(len(refs)))
            for r in refs:
                print("         line {} -> {!r}".format(r.line_number, r.link_target))

        # --- Move the target through the real service -------------------
        service = LinkWatcherService(str(tmpdir))
        service._initial_scan()

        new_target = tmpdir / "archive" / "y.txt"
        new_target.parent.mkdir()
        target.rename(new_target)
        service.handler.on_moved(FileMovedEvent(str(target), str(new_target)))

        updated = config_json.read_text(encoding="utf-8")
        print("\nAFTER move:\n" + updated)

        # --- Check 2: file is still parseable ---------------------------
        try:
            decoded = json.loads(updated)
            print("[PASS] Check 2: updated content is still valid JSON")
            checks_passed += 1
        except json.JSONDecodeError as exc:
            print("[FAIL] Check 2: rewrite left invalid JSON: {}".format(exc))
            decoded = None

        if decoded is None:
            print("\nAborting remaining checks: file is unparseable.")
            return 1

        expected = "archive/y.txt"

        # --- Check 3: escaped forward slash updated ---------------------
        if decoded["escaped_slash"] == expected:
            print("[PASS] Check 3: escaped forward-slash value updated")
            checks_passed += 1
        else:
            print(
                "[FAIL] Check 3: escaped forward-slash value is {!r}".format(
                    decoded["escaped_slash"]
                )
            )

        # --- Check 4: unicode escape updated ----------------------------
        if decoded["escaped_unicode"] == expected:
            print("[PASS] Check 4: unicode-escaped value updated")
            checks_passed += 1
        else:
            print(
                "[FAIL] Check 4: unicode-escaped value is {!r}".format(decoded["escaped_unicode"])
            )

        # --- Check 5: plain sibling still updated (regression guard) ----
        if decoded["plain"] == expected:
            print("[PASS] Check 5: plain sibling still updated")
            checks_passed += 1
        else:
            print(
                "[FAIL] Check 5: plain sibling is {!r} -- the escaped value "
                "poisoned its file".format(decoded["plain"])
            )

        # --- Check 6: backslash value updated AND still escaped ---------
        expected_backslash = "archive" + BS + "y.txt"
        raw_has_escaped_pair = ("archive" + BS * 2 + "y.txt") in updated
        if decoded["backslash"] == expected_backslash and raw_has_escaped_pair:
            print("[PASS] Check 6: backslash value updated and re-escaped correctly")
            print(
                "       raw source holds the doubled backslash; decodes to {!r}".format(
                    decoded["backslash"]
                )
            )
            checks_passed += 1
        else:
            print(
                "[FAIL] Check 6: backslash value is {!r} (raw doubled-backslash "
                "present: {}) -- a single backslash here would break the "
                "string literal".format(decoded["backslash"], raw_has_escaped_pair)
            )

        # --- Check 7: non-ASCII authoring survives the rewrite ----------
        nonascii_new = tmpdir / "archive" / ("n" + "ö" + "te.txt")
        nonascii.rename(nonascii_new)
        service.handler.on_moved(FileMovedEvent(str(nonascii), str(nonascii_new)))
        final = config_json.read_text(encoding="utf-8")
        decoded_final = json.loads(final)
        respelled = (chr(92) + "u00f6") in final
        expected_na = "archive" + chr(92) + "n" + "ö" + "te.txt"
        print("\nAFTER non-ASCII move:\n" + final)
        if decoded_final["non_ascii"] == expected_na and not respelled:
            print("[PASS] Check 7: non-ASCII authoring preserved on rewrite")
            print("       authored character still literal, not a unicode escape")
            checks_passed += 1
        else:
            print(
                "[FAIL] Check 7: value is {!r} (re-spelled as unicode escape: "
                "{}) -- the rewrite changed HOW the path was written".format(
                    decoded_final["non_ascii"], respelled
                )
            )

    print("\n" + "=" * 68)
    print("RESULT: {}/{} checks passed".format(checks_passed, checks_total))
    print("=" * 68)
    return 0 if checks_passed == checks_total else 1


if __name__ == "__main__":
    sys.exit(main())
