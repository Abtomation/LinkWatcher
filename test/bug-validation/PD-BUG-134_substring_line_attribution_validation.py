"""
PD-BUG-134 Manual Validation: a value is attributed to the line it actually
occupies, not to an earlier line that merely contains it as a substring.

PURPOSE:
    Both structured parsers located a decoded value by plain substring search.
    A short path was therefore attributed to any earlier line whose larger
    literal happened to contain that text -- the reference was recorded against
    the wrong line, the updater rewrote the occurrence there, and the line the
    value really sits on was never touched.  It went stale on a move with
    nothing logged, because a line WAS found: just the wrong one, so the
    ``path_value_line_not_located`` warning (PD-BUG-126) never fired.

    Two shapes are exercised end to end, one per format:

    (a) JSON -- a compound value on line 2 embeds the same directory that
        line 3 holds as a plain value.  Both references landed on line 2.

    (b) YAML -- an UNQUOTED directory inside a compound scalar on line 1.
        That is deliberately NOT a reference (PD-BUG-131), so the plain scalar
        on line 2 was attributed to it: line 2 went stale AND line 1 was
        rewritten even though it is not a tracked reference.

HOW TO RUN:
    python test/bug-validation/PD-BUG-134_substring_line_attribution_validation.py

WHAT TO OBSERVE:
    The script prints both config files BEFORE and AFTER a real directory move.
    Every line that still holds the OLD path after the move is flagged
    "<== STALE".  Before the fix, config.json line 3 and config.yaml line 2 are
    stale; after the fix no line is.  Watch config.yaml line 1 too: its
    unquoted directory must stay untouched in both runs -- if it moves, the
    rewrite is landing on a value that is not a reference.

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
BS = chr(92)
OLD = "doc/technical/design"
NEW = "doc/architecture/design"


def show(label, text, flag_stale=False, expected_old=()):
    """Print a numbered file listing; after the move, flag lines still holding
    the OLD path (before the move the old path is simply the current one).

    *expected_old* names lines that are SUPPOSED to keep the old path because
    they hold no tracked reference -- flagging those "STALE" would read as a
    failure when it is the contract (see Check 5)."""
    print("\n" + label)
    for i, line in enumerate(text.rstrip("\n").split("\n"), 1):
        flag = ""
        if flag_stale and OLD in line:
            flag = "   <== unchanged, not a reference" if i in expected_old else "   <== STALE"
        print("  {}: {}{}".format(i, line, flag))


def main():
    print("=" * 70)
    print("PD-BUG-134: value line attribution under substring collision")
    print("=" * 70)

    checks_passed = 0
    checks_total = 5

    with tempfile.TemporaryDirectory() as tmpdir:
        tmpdir = Path(tmpdir)

        watched = tmpdir / "doc" / "technical" / "design"
        watched.mkdir(parents=True)
        (watched / "note.md").write_text("payload\n", encoding="utf-8")

        # (a) JSON: compound value on line 2, plain value on line 3.
        config_json = tmpdir / "config.json"
        json_content = (
            "{\n"
            '  "watched_dir": "Bash([ -d ' + BS + Q + OLD + BS + Q + ' ])",\n'
            '  "plain_dir": "' + OLD + '"\n'
            "}\n"
        )
        config_json.write_text(json_content, encoding="utf-8")

        # (b) YAML: unquoted directory inside a compound scalar on line 1.
        config_yaml = tmpdir / "config.yaml"
        yaml_content = "cmd: pwsh -File " + OLD + " -Recurse\n" "plain: " + OLD + "\n"
        config_yaml.write_text(yaml_content, encoding="utf-8")

        show("BEFORE -- config.json", json_content)
        show("BEFORE -- config.yaml", yaml_content)

        # --- Check 1: parse-level attribution (JSON) ------------------------
        refs = JsonParser().parse_content(json_content, str(config_json))
        lines = sorted(r.line_number for r in refs if r.link_target == OLD)
        if lines == [2, 3]:
            print("\n[PASS] Check 1: the two JSON references sit on lines 2 and 3")
            checks_passed += 1
        else:
            print("\n[FAIL] Check 1: expected lines [2, 3], got {}".format(lines))
            print("       (both collapsing onto line 2 is the defect)")

        # --- Move the directory through the real service --------------------
        service = LinkWatcherService(str(tmpdir))
        service._initial_scan()

        new_dir = tmpdir / "doc" / "architecture" / "design"
        new_dir.parent.mkdir(parents=True, exist_ok=True)
        watched.rename(new_dir)
        service.handler.on_moved(DirMovedEvent(str(watched), str(new_dir)))

        updated_json = config_json.read_text(encoding="utf-8")
        updated_yaml = config_yaml.read_text(encoding="utf-8")

        print("\nAFTER moving {} -> {}".format(OLD, NEW))
        show("AFTER -- config.json", updated_json, flag_stale=True)
        show("AFTER -- config.yaml", updated_yaml, flag_stale=True, expected_old=(1,))

        json_lines = updated_json.split("\n")
        yaml_lines = updated_yaml.split("\n")

        # --- Check 2: the JSON plain value followed the move ----------------
        if NEW in json_lines[2]:
            print("\n[PASS] Check 2: config.json line 3 followed the move")
            checks_passed += 1
        else:
            print("\n[FAIL] Check 2: config.json line 3 left stale")
            print("       " + json_lines[2].strip())

        # --- Check 3: the JSON compound value still follows (regression) ----
        if NEW in json_lines[1]:
            print("[PASS] Check 3: the embedded directory on line 2 still follows")
            checks_passed += 1
        else:
            print("[FAIL] Check 3: line 2 regressed")
            print("       " + json_lines[1].strip())

        # --- Check 4: the YAML plain scalar followed the move ---------------
        if NEW in yaml_lines[1]:
            print("[PASS] Check 4: config.yaml line 2 followed the move")
            checks_passed += 1
        else:
            print("[FAIL] Check 4: config.yaml line 2 left stale")
            print("       " + yaml_lines[1].strip())

        # --- Check 5: the UNQUOTED directory is not a reference -------------
        if OLD in yaml_lines[0]:
            print("[PASS] Check 5: the unquoted directory on line 1 was not rewritten")
            print("       (it is deliberately not a reference -- PD-BUG-131)")
            checks_passed += 1
        else:
            print("[FAIL] Check 5: line 1 was rewritten although it is not a reference")
            print("       " + yaml_lines[0].strip())

        # Content sanity: the rewrite must leave a parseable document.
        try:
            json.loads(updated_json)
        except json.JSONDecodeError as exc:
            print("[WARN] updated config.json is no longer valid JSON: {}".format(exc))

    print("\n" + "=" * 70)
    print("RESULT: {}/{} checks passed".format(checks_passed, checks_total))
    print("=" * 70)
    return 0 if checks_passed == checks_total else 1


if __name__ == "__main__":
    sys.exit(main())
