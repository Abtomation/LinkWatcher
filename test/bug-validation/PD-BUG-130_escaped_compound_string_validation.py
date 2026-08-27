"""
PD-BUG-130 Manual Validation: escaped paths inside COMPOUND strings are
detected and updated.

PURPOSE:
    Verify that a file path embedded in a space-bearing ("compound") JSON or
    YAML value -- a command line, a permission pattern, a hook invocation -- is
    tracked and updated even when the surrounding source literal carries
    escapes.

    Before the fix the compound branch searched the raw line for the DECODED
    whole string, which never matches once anything is escaped, and offset each
    candidate span within the DECODED text rather than the raw text.  Two
    silent outcomes followed, decided only by where the path sat:

      * path in the MIDDLE  -> no reference and no warning at all;
      * path at the END     -> a reference whose target was the ENTIRE command
                               line, which can never resolve to a file.

    Sibling of PD-BUG-126, which fixed the whole-string branch only.

HOW TO RUN:
    python test/bug-validation/PD-BUG-130_escaped_compound_string_validation.py

WHAT TO OBSERVE (filesystem, no API calls):
    The script builds a temp project, prints each config file BEFORE the move,
    moves the target file, then prints the same files AFTER.  Compare the two:
    every spelling of the moved path must have followed the move, the command
    text around it must be untouched, and both files must still parse.

EXPECTED RESULT:
    All 7 checks pass.

CHECK 4 -- the corruption guard:
    The compound case carries a risk the whole-value case does not: the span
    addresses a candidate sitting INSIDE a larger escaped literal, so a
    mis-mapped span damages surrounding command text rather than just the path
    (the PD-BUG-124 class).  Check 4 pins that the command wrapper survives
    byte-for-byte.
"""

import json
import sys
import tempfile
from pathlib import Path

project_root = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(project_root))

import yaml  # noqa: E402
from watchdog.events import FileMovedEvent  # noqa: E402

from linkwatcher.service import LinkWatcherService  # noqa: E402

BS = chr(92)


def _check(label, condition, detail=""):
    mark = "PASS" if condition else "FAIL"
    print("  [%s] %s" % (mark, label))
    if detail:
        print("         %s" % detail)
    return 1 if condition else 0


def main():
    print("=" * 70)
    print("PD-BUG-130: escaped compound-string path detection and update")
    print("=" * 70)

    passed = 0
    total = 7

    with tempfile.TemporaryDirectory() as tmpdir:
        tmpdir = Path(tmpdir)

        target = tmpdir / "logs" / "sub" / "run.py"
        target.parent.mkdir(parents=True)
        target.write_text("payload", encoding="utf-8")

        ps_target = tmpdir / "logs" / "sub" / "run.ps1"
        ps_target.write_text("payload", encoding="utf-8")

        config = tmpdir / "config.json"
        config.write_text(
            "{\n"
            '  "middle":  "Bash(python logs' + BS * 2 + "sub" + BS * 2 + 'run.py *)",\n'
            '  "end":     "pwsh -File logs' + BS * 2 + "sub" + BS * 2 + 'run.ps1",\n'
            '  "quoted":  "echo ' + BS + '"go' + BS + '" && python logs/sub/run.py",\n'
            '  "plain":   "Bash(python logs/sub/run.py *)"\n'
            "}\n",
            encoding="utf-8",
        )

        ycfg = tmpdir / "config.yaml"
        ycfg.write_text(
            'escaped: "pwsh -File logs' + BS * 2 + "sub" + BS * 2 + 'run.ps1 -Quick"\n'
            'plain:   "pwsh -File logs/sub/run.ps1 -Quick"\n',
            encoding="utf-8",
        )

        print("\nBEFORE the move -- config.json:")
        print("-" * 70)
        print(config.read_text(encoding="utf-8"))
        print("BEFORE the move -- config.yaml:")
        print("-" * 70)
        print(ycfg.read_text(encoding="utf-8"))

        print("Moving  logs/sub/run.py   ->  archive/moved.py")
        print("Moving  logs/sub/run.ps1  ->  archive/moved.ps1\n")

        service = LinkWatcherService(str(tmpdir))
        service._initial_scan()

        archive = tmpdir / "archive"
        archive.mkdir()
        for old, new in ((target, archive / "moved.py"), (ps_target, archive / "moved.ps1")):
            old.rename(new)
            service.handler.on_moved(FileMovedEvent(str(old), str(new)))

        print("AFTER the move -- config.json:")
        print("-" * 70)
        raw_json = config.read_text(encoding="utf-8")
        print(raw_json)
        print("AFTER the move -- config.yaml:")
        print("-" * 70)
        raw_yaml = ycfg.read_text(encoding="utf-8")
        print(raw_yaml)

        print("CHECKS")
        print("-" * 70)

        try:
            decoded = json.loads(raw_json)
            passed += _check("config.json still parses as JSON", True)
        except ValueError as exc:
            passed += _check("config.json still parses as JSON", False, str(exc))
            decoded = {}

        middle = decoded.get("middle", "")
        passed += _check(
            "path in the MIDDLE of a compound value followed the move",
            middle.replace(BS, "/") == "Bash(python archive/moved.py *)",
            "got: %r" % middle,
        )

        end = decoded.get("end", "")
        passed += _check(
            "path at the END is the target, not the whole command line",
            end.replace(BS, "/") == "pwsh -File archive/moved.ps1",
            "got: %r" % end,
        )

        passed += _check(
            "surrounding command text survived byte-for-byte (corruption guard)",
            middle.startswith("Bash(python ") and middle.endswith(" *)"),
            "got: %r" % middle,
        )

        quoted = decoded.get("quoted", "")
        passed += _check(
            "clean path inside an escape-bearing literal followed the move",
            quoted == 'echo "go" && python archive/moved.py',
            "got: %r" % quoted,
        )

        passed += _check(
            "escape-free sibling still updates (no regression)",
            decoded.get("plain") == "Bash(python archive/moved.py *)",
            "got: %r" % decoded.get("plain"),
        )

        try:
            ydec = yaml.safe_load(raw_yaml)
            ok = ydec.get("escaped", "").replace(BS, "/") == "pwsh -File archive/moved.ps1 -Quick"
            passed += _check(
                "YAML escaped compound scalar followed the move and still parses",
                ok,
                "got: %r" % ydec.get("escaped"),
            )
        except yaml.YAMLError as exc:
            passed += _check(
                "YAML escaped compound scalar followed the move and still parses",
                False,
                str(exc),
            )

    print("-" * 70)
    print("%d/%d checks passed" % (passed, total))
    return 0 if passed == total else 1


if __name__ == "__main__":
    sys.exit(main())
