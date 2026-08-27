r"""
Manual validation test for PD-BUG-124: a reconstructed backslash separator was
emitted as a bare backslash, corrupting the string literal it was written into.

PURPOSE:
  Verify that when LinkWatcher rewrites a path inside an ESCAPED string literal
  (a .py or .json file), the separator it emits keeps the author's escaping.

  Inside a Python string literal one path separator must be authored as TWO
  backslash characters. LinkWatcher spliced its rewrite back into the file's raw
  source but emitted ONE backslash, which the language then reads as an escape
  character rather than a separator. Two failure shapes:

    LOUD   - a trailing backslash escapes the closing quote, so the line becomes
             an unterminated string literal and the whole file stops parsing.
    SILENT - a backslash before 'n' (or 'd', 't', ...) forms a valid escape, so
             the file still parses but the VALUE is quietly wrong. Nothing fails
             and nothing is logged.

  Three sites shared the defect, all reached from PathResolver:
    * utils.apply_trailing_separator_style     - the restored TRAILING separator
    * PathResolver._apply_separator_style      - BODY, directory-prefix branch
    * PathResolver._convert_to_original_link_type - BODY, match branch (silent)

HOW TO RUN:
  python test/bug-validation/PD-BUG-124_escaped_backslash_separator_validation.py

WHAT IT DOES (reproducible by hand: create the files, then rename the directory
or move the file with File Explorer or VS Code while LinkWatcher runs):
  1. Creates a temp project with a real logs/ tree.
  2. Writes .py files whose path constants use ESCAPED backslashes - the only
     valid way to write a Windows-style path in a Python string.
  3. Renames a directory / moves a file so LinkWatcher rewrites those constants.
  4. Prints each file BEFORE and AFTER, whether it still PARSES, and what the
     constant actually DECODES to - so the silent case is visible too.

EXPECTED RESULT (fixed):
  Every file still parses, and every constant decodes to the intended path with
  its escaping intact.

PRE-FIX BEHAVIOUR (the bug):
  Case A -> LOG = "logs2\"            SyntaxError: unterminated string literal
  Case B -> LOG = "logs\"             SyntaxError: unterminated string literal
  Case C -> LOG = "logs2\sub\x.txt"   SyntaxError: truncated \xXX escape
  Case D -> LOG = "logs\deep\notes.txt"  parses, but decodes with a NEWLINE
                                         where a separator belonged - silent
"""

import ast
import sys
import tempfile
from pathlib import Path

# Add project root to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from watchdog.events import DirMovedEvent, FileMovedEvent  # noqa: E402

from linkwatcher.service import LinkWatcherService  # noqa: E402

# One backslash, and the doubled form an author MUST write for one separator
# inside a Python string literal. Built from chr(92) so the two are unmistakable.
BS = chr(92)
ESC = BS * 2


def _parses(text):
    try:
        ast.parse(text)
        return True, "parses"
    except SyntaxError as e:
        return False, "SyntaxError: %s" % e.msg


def _decode(text):
    """Return the decoded value of the LOG constant, or None if unparseable."""
    namespace = {}
    try:
        exec(text, namespace)  # noqa: S102 - showing the human the decoded value
    except Exception:
        return None
    return namespace.get("LOG")


def _report(label, path, expected_value):
    text = path.read_text(encoding="utf-8")
    ok_parse, parse_note = _parses(text)
    value = _decode(text)
    value_ok = value == expected_value

    print("    %s" % label)
    print("      source : %r" % text.rstrip("\n"))
    print("      parses : %s (%s)" % ("YES" if ok_parse else "NO", parse_note))
    print("      decodes: %r" % (value,))
    print("      wanted : %r" % (expected_value,))
    return ok_parse and value_ok


def run_validation():
    print("=" * 72)
    print("PD-BUG-124: escaped backslash separators - validation")
    print("=" * 72)

    results = {}

    # ---------------------------------------------------------------- Case A
    print("\n[1] Case A - trailing separator, directory renamed")
    print("    (hand-repro: rename logs\\ to logs2\\ in File Explorer)")
    with tempfile.TemporaryDirectory() as tmpdir:
        p = Path(tmpdir)
        (p / "logs").mkdir()
        (p / "logs" / "x.txt").write_text("x\n", encoding="utf-8")
        py = p / "collect.py"
        py.write_text('LOG = "logs' + ESC + '"\n', encoding="utf-8")
        print("    BEFORE : %r" % py.read_text(encoding="utf-8").rstrip())

        service = LinkWatcherService(str(p))
        service._initial_scan()
        (p / "logs").rename(p / "logs2")
        service.handler.on_moved(DirMovedEvent(str(p / "logs"), str(p / "logs2")))

        results["A: trailing separator keeps its escaping"] = _report(
            "AFTER  collect.py:", py, "logs2" + BS
        )

    # ---------------------------------------------------------------- Case B
    print("\n[2] Case B - trailing separator, containing file moved to the root")
    print("    (hand-repro: drag sub\\collect.py up to the project root)")
    with tempfile.TemporaryDirectory() as tmpdir:
        p = Path(tmpdir)
        (p / "logs").mkdir()
        (p / "logs" / "x.txt").write_text("x\n", encoding="utf-8")
        (p / "sub").mkdir()
        py = p / "sub" / "collect.py"
        py.write_text('LOG = "..' + ESC + "logs" + ESC + '"\n', encoding="utf-8")
        print("    BEFORE : %r" % py.read_text(encoding="utf-8").rstrip())

        service = LinkWatcherService(str(p))
        service._initial_scan()
        moved = p / "collect.py"
        py.rename(moved)
        service.handler.on_moved(FileMovedEvent(str(py), str(moved)))

        # reference_lookup always emits forward-slash output, so the restored
        # separator is a forward slash at every result depth (secondary defect).
        results["B: single-segment result emits no bare backslash"] = _report(
            "AFTER  collect.py:", moved, "logs/"
        )

    # ---------------------------------------------------------------- Case C
    print("\n[3] Case C - BODY separators, directory renamed")
    print("    (hand-repro: rename logs\\ to logs2\\ with a nested reference)")
    with tempfile.TemporaryDirectory() as tmpdir:
        p = Path(tmpdir)
        (p / "logs" / "sub").mkdir(parents=True)
        (p / "logs" / "sub" / "x.txt").write_text("x\n", encoding="utf-8")
        py = p / "collect.py"
        py.write_text('LOG = "logs' + ESC + "sub" + ESC + 'x.txt"\n', encoding="utf-8")
        print("    BEFORE : %r" % py.read_text(encoding="utf-8").rstrip())

        service = LinkWatcherService(str(p))
        service._initial_scan()
        (p / "logs").rename(p / "logs2")
        service.handler.on_moved(DirMovedEvent(str(p / "logs"), str(p / "logs2")))

        results["C: body separators keep their escaping"] = _report(
            "AFTER  collect.py:", py, "logs2" + BS + "sub" + BS + "x.txt"
        )

    # ---------------------------------------------------------------- Case D
    print("\n[4] Case D - BODY separators, file moved (the SILENT case)")
    print("    (hand-repro: move logs\\sub\\notes.txt to logs\\deep\\notes.txt)")
    print("    NOTE: pre-fix this file still PARSED - only the decoded value was")
    print("          wrong, because the emitted backslash before 'notes' became a")
    print("          newline escape. Watch the 'decodes' line, not 'parses'.")
    with tempfile.TemporaryDirectory() as tmpdir:
        p = Path(tmpdir)
        (p / "logs" / "sub").mkdir(parents=True)
        src = p / "logs" / "sub" / "notes.txt"
        src.write_text("x\n", encoding="utf-8")
        py = p / "collect.py"
        py.write_text('LOG = "logs' + ESC + "sub" + ESC + 'notes.txt"\n', encoding="utf-8")
        print("    BEFORE : %r" % py.read_text(encoding="utf-8").rstrip())

        service = LinkWatcherService(str(p))
        service._initial_scan()
        (p / "logs" / "deep").mkdir()
        dst = p / "logs" / "deep" / "notes.txt"
        src.rename(dst)
        service.handler.on_moved(FileMovedEvent(str(src), str(dst)))

        results["D: silent case - decoded value is correct"] = _report(
            "AFTER  collect.py:", py, "logs" + BS + "deep" + BS + "notes.txt"
        )

    # ------------------------------------------------------------ Control E
    print("\n[5] Control E - unescaped single-backslash authoring is untouched")
    print("    (markdown authors ONE backslash and means it - it must not double)")
    with tempfile.TemporaryDirectory() as tmpdir:
        p = Path(tmpdir)
        (p / "logs").mkdir()
        (p / "logs" / "x.txt").write_text("x\n", encoding="utf-8")
        md = p / "notes.md"
        md.write_text("See `logs" + BS + "` for output.\n", encoding="utf-8")
        print("    BEFORE : %r" % md.read_text(encoding="utf-8").rstrip())

        service = LinkWatcherService(str(p))
        service._initial_scan()
        (p / "logs").rename(p / "logs2")
        service.handler.on_moved(DirMovedEvent(str(p / "logs"), str(p / "logs2")))

        after_md = md.read_text(encoding="utf-8")
        print("    AFTER  : %r" % after_md.rstrip())
        ok = ("logs2" + BS) in after_md and (ESC not in after_md)
        print("      single backslash preserved, not doubled: %s" % ("YES" if ok else "NO"))
        results["E: control - single-backslash authoring unchanged"] = ok

    # ------------------------------------------------------------------ Verdict
    print("\n[6] Verifying...")
    all_passed = True
    for label, ok in results.items():
        print("    [%s] %s" % ("PASS" if ok else "FAIL", label))
        all_passed = all_passed and ok

    print("\n" + "=" * 72)
    if all_passed:
        print("RESULT: ALL CHECKS PASSED - rewrites keep the authored escaping,")
        print("        every file still parses, and every value decodes correctly.")
    else:
        print("RESULT: SOME CHECKS FAILED - a rewrite damaged the string literal")
        print("        it was written into.")
    print("=" * 72)
    return all_passed


if __name__ == "__main__":
    success = run_validation()
    sys.exit(0 if success else 1)
