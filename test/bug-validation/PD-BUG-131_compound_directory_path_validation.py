"""
PD-BUG-131 Manual Validation: a DIRECTORY path inside a compound .json/.yaml
value is tracked, and the whole command string is not.

PURPOSE:
    Verify two halves of one defect.

    (a) A directory path embedded in a compound (space-bearing) config value
        is extracted and updated when that directory moves.  Before the fix
        the structured parsers reached only for the extension-bearing
        ``_path_pattern``, so an extensionless directory produced no
        candidates at all.

    (b) The whole command string is no longer registered as the link target.
        With no candidates found, the value fell through to whole-string
        classification and the ENTIRE command was recorded as a directory
        reference -- one that can never resolve, so the real directory inside
        it stayed silently untracked.

    The delimiter requirement is deliberate: an extensionless directory is
    recognised only when quoted, which is what the markdown, generic, python
    and powershell parsers have always required.  An UNQUOTED directory in a
    compound value is still not a reference -- but it no longer manufactures
    a bogus whole-string one either.

HOW TO RUN:
    python test/bug-validation/PD-BUG-131_compound_directory_path_validation.py

WHAT TO OBSERVE:
    The script prints config.json BEFORE and AFTER a real directory move.
    Look at the "watched_dir" line: the quoted directory inside the command
    must follow the move, while the surrounding command text is untouched.

EXPECTED RESULT:
    All 5 checks pass.
"""

import json
import sys
import tempfile
from pathlib import Path

project_root = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(project_root))

from watchdog.events import DirMovedEvent  # noqa: E402

from linkwatcher.parsers.json_parser import JsonParser  # noqa: E402
from linkwatcher.service import LinkWatcherService  # noqa: E402

Q = chr(34)


def main():
    print("=" * 70)
    print("PD-BUG-131: compound-value directory path detection and update")
    print("=" * 70)

    checks_passed = 0
    checks_total = 5

    with tempfile.TemporaryDirectory() as tmpdir:
        tmpdir = Path(tmpdir)

        watched = tmpdir / "doc" / "technical" / "design"
        watched.mkdir(parents=True)
        (watched / "note.md").write_text("payload\n", encoding="utf-8")

        config_json = tmpdir / "config.json"
        config_content = (
            "{\n"
            '  "watched_dir": "Bash([ -d '
            + chr(92)
            + Q
            + "doc/technical/design"
            + chr(92)
            + Q
            + ' ])",\n'
            '  "plain_dir":   "doc/technical/design",\n'
            '  "spaced_dir":  "doc/my design",\n'
            '  "unquoted":    "Bash([ -d doc/technical/design ])"\n'
            "}\n"
        )
        config_json.write_text(config_content, encoding="utf-8")

        print("\nSetup: config.json holds the same directory in four shapes.")
        print("BEFORE move:\n" + config_content)

        refs = JsonParser().parse_content(config_content, str(config_json))
        targets = [r.link_target for r in refs]

        # --- Check 1: the quoted directory inside the command is extracted --
        if "doc/technical/design" in targets:
            print("[PASS] Check 1: quoted directory inside the command is tracked")
            print("       (before the fix this produced NO candidate at all)")
            checks_passed += 1
        else:
            print("[FAIL] Check 1: directory not extracted; got {!r}".format(targets))

        # --- Check 2: no whole command string survives as a target ----------
        whole = [t for t in targets if "Bash(" in t]
        if not whole:
            print("[PASS] Check 2: no whole command string registered as a target")
            print("       (before the fix BOTH Bash(...) values were targets)")
            checks_passed += 1
        else:
            print("[FAIL] Check 2: whole command still a target: {!r}".format(whole))

        # --- Check 3: a genuine directory containing a space still works ----
        if "doc/my design" in targets:
            print("[PASS] Check 3: 'doc/my design' still classified (space is not")
            print("       command syntax -- the containment must reject brackets)")
            checks_passed += 1
        else:
            print("[FAIL] Check 3: spaced directory lost; got {!r}".format(targets))

        # --- Move the directory through the real service --------------------
        service = LinkWatcherService(str(tmpdir))
        service._initial_scan()

        new_dir = tmpdir / "doc" / "architecture" / "design"
        new_dir.parent.mkdir(parents=True, exist_ok=True)
        watched.rename(new_dir)
        service.handler.on_moved(DirMovedEvent(str(watched), str(new_dir)))

        updated = config_json.read_text(encoding="utf-8")
        print("\nAFTER moving doc/technical/design -> doc/architecture/design:\n" + updated)

        # --- Check 4: still valid JSON --------------------------------------
        try:
            json.loads(updated)
            print("[PASS] Check 4: updated content is still valid JSON")
            checks_passed += 1
        except json.JSONDecodeError as exc:
            print("[FAIL] Check 4: rewrite left invalid JSON: {}".format(exc))

        # --- Check 5: the embedded directory followed the move --------------
        for line in updated.splitlines():
            if "watched_dir" in line:
                if "doc/architecture/design" in line:
                    print("[PASS] Check 5: embedded directory followed the move")
                    print("       " + line.strip())
                    checks_passed += 1
                else:
                    print("[FAIL] Check 5: embedded directory left stale")
                    print("       " + line.strip())
                break

    print("\n" + "=" * 70)
    print("RESULT: {}/{} checks passed".format(checks_passed, checks_total))
    print("=" * 70)
    return 0 if checks_passed == checks_total else 1


if __name__ == "__main__":
    sys.exit(main())
