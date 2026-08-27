"""
PD-BUG-132 Manual Validation: a validate run that never scanned is shown as a
failure, never as the previous run's link-health verdict.

PURPOSE:
    Verify that the Control Panel's Validation pane distinguishes "this run
    found broken links" from "this run never got as far as scanning".

    The validator writes its report to the conventional path
    logs/linkwatcher/LinkWatcherBrokenLinks.txt on EVERY completed run, so for
    any project validated even once a report is always sitting there.  A run
    that exits 1 BEFORE scanning -- invalid config, invalid project root, an
    exception inside the scan -- writes none.  Before the fix the panel's
    conventional-path fallback handed that run the PREVIOUS run's report, so a
    configuration error was rendered as a link-health verdict:

      * earlier run found 7 broken  ->  pane shows "7 broken links" (stale);
      * earlier run was clean       ->  pane shows "0 broken links", a literal
                                        false-clean -- FDD edge case
                                        7-1-1-EC-6 violated in its own terms.

    In both shapes the config_issue text naming the offending key was discarded
    entirely.  The fix requires positive evidence from the run's own stdout
    that the scan completed before any report is credited to it.

HOW TO RUN:
    python test/bug-validation/PD-BUG-132_stale_validation_report_validation.py

WHAT TO OBSERVE (real subprocesses, no mocking):
    The script builds a temp project, runs the REAL `main.py --validate` twice
    -- once with a good config (which writes the report), once with a broken
    config (which aborts before scanning) -- and prints, for the second run,
    the exact line the Validation pane would display under the OLD logic and
    under the FIXED logic.  Compare the two: the old line is a link-health
    verdict for a scan that never happened; the fixed line names the offending
    configuration key.

EXPECTED RESULT:
    All 6 checks pass.

CHECK 6 -- the over-correction guard:
    Requiring evidence must not suppress genuine results.  Check 6 runs a real
    validate against a tree with a real broken link and pins that the pane still
    reports the count.
"""

import subprocess
import sys
import tempfile
from pathlib import Path

project_root = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(project_root / "src"))

from linkwatcher.linkwatcher_control_panel.lifecycle import RunResult  # noqa: E402
from linkwatcher.linkwatcher_control_panel.validation import (  # noqa: E402
    REPORT_FILENAME,
    parse_validation_result,
    strip_ansi,
)
from linkwatcher.linkwatcher_control_panel.views.rendering import validation_display  # noqa: E402

MAIN = project_root / "main.py"


def _check(label, condition, detail=""):
    mark = "PASS" if condition else "FAIL"
    print("  [%s] %s" % (mark, label))
    if detail:
        print("         %s" % detail)
    return 1 if condition else 0


def run_validate(tree: Path, config: Path) -> RunResult:
    """Invoke the real CLI exactly as the panel does."""
    completed = subprocess.run(
        [
            sys.executable,
            str(MAIN),
            "--project-root",
            str(tree),
            "--validate",
            "--config",
            str(config),
        ],
        capture_output=True,
        text=True,
    )
    return RunResult(completed.returncode, completed.stdout, completed.stderr)


def pane_line_pre_fix(result: RunResult, log_dir: Path) -> str:
    """What the pane showed BEFORE the fix: a locatable report was enough.

    Reproduces the old branch condition -- `returncode == 1 and report is not
    None` -- with no check that this run actually scanned.
    """
    report = Path(log_dir) / REPORT_FILENAME
    if result.returncode == 1 and report.is_file():
        text = report.read_text(encoding="utf-8")
        for line in text.splitlines():
            if "Broken links" in line:
                count = line.split(":")[1].strip()
                plural = "" if count == "1" else "s"
                return "%s broken link%s" % (count, plural)
    return "(failure)"


def pane_line_fixed(result: RunResult, log_dir: Path) -> str:
    return validation_display(parse_validation_result(result, log_dir)).text


def build_tree(tmpdir: Path, name: str, broken_link: bool) -> Path:
    """A project tree with exactly one link, broken or not.

    The config files live OUTSIDE the tree on purpose: LinkWatcher scans every
    monitored file it finds, so a config sitting inside the project would have
    its own `log_file:` value counted as a link and the "clean" scenario would
    never be clean.
    """
    tree = tmpdir / name
    (tree / "logs" / "linkwatcher").mkdir(parents=True)
    target = "missing.md" if broken_link else "there.md"
    (tree / "here.md").write_text("See [target](%s)\n" % target, encoding="utf-8")
    if not broken_link:
        (tree / "there.md").write_text("arrived\n", encoding="utf-8")
    return tree


def write_configs(tmpdir: Path, name: str):
    """The good/bad config pair for one scenario, kept out of the scanned tree."""
    good = tmpdir / ("%s-good.yaml" % name)
    good.write_text("log_file: logs/linkwatcher/lw.log\n", encoding="utf-8")
    bad = tmpdir / ("%s-bad.yaml" % name)
    bad.write_text(
        "log_file: logs/linkwatcher/lw.log\nlog_file_max_size_mb: big\n", encoding="utf-8"
    )
    return good, bad


def main():
    print("=" * 70)
    print("PD-BUG-132: a run that never scanned is not given the old report")
    print("=" * 70)

    passed = 0
    total = 6

    with tempfile.TemporaryDirectory() as tmp:
        tmpdir = Path(tmp)

        for name, label, broken_link, expected_count in (
            ("dirty", "earlier run FOUND BROKEN LINKS", True, "1"),
            ("clean", "earlier run was CLEAN", False, "0"),
        ):
            print("\n" + "-" * 70)
            print("SCENARIO: %s" % label)
            print("-" * 70)

            tree = build_tree(tmpdir, name, broken_link)
            log_dir = tree / "logs" / "linkwatcher"
            good, bad = write_configs(tmpdir, name)

            first = run_validate(tree, good)
            report = log_dir / REPORT_FILENAME
            print(
                "Run 1 (good config): exit %s, report written: %s"
                % (first.returncode, report.is_file())
            )

            second = run_validate(tree, bad)
            print(
                "Run 2 (bad  config): exit %s, report still the one from run 1: %s"
                % (second.returncode, report.is_file())
            )
            print("Run 2 said, on its own output:")
            for line in strip_ansi(second.stdout + second.stderr).splitlines():
                if "config_issue" in line or "Report written" in line:
                    print("    %s" % line.strip()[:100])

            old_line = pane_line_pre_fix(second, log_dir)
            new_line = pane_line_fixed(second, log_dir)
            print("\n  PANE BEFORE the fix : %s" % old_line)
            print("  PANE AFTER  the fix : %s" % new_line[:100])

            if label.endswith("BROKEN LINKS"):
                passed += _check(
                    "run 1 left a report at the conventional path",
                    report.is_file(),
                    "this is the normal state for any project validated even once",
                )
                passed += _check(
                    "old logic showed run 1's stale count as run 2's verdict",
                    old_line == "%s broken link" % expected_count,
                    "observed: %s" % old_line,
                )
                passed += _check(
                    "fixed logic reports a failure naming the offending key",
                    "log_file_max_size_mb" in new_line and "broken link" not in new_line,
                    "observed: %s" % new_line[:80],
                )
            else:
                passed += _check(
                    "old logic rendered the false-clean '0 broken links'",
                    old_line == "0 broken links",
                    "observed: %s" % old_line,
                )
                passed += _check(
                    "fixed logic never renders '0 broken links' for an aborted run",
                    "0 broken links" not in new_line,
                    "observed: %s" % new_line[:80],
                )

        print("\n" + "-" * 70)
        print("CONTROL: a genuine broken-links run still reports its count")
        print("-" * 70)
        tree = build_tree(tmpdir, "control", True)
        log_dir = tree / "logs" / "linkwatcher"
        good, _bad = write_configs(tmpdir, "control")
        genuine = run_validate(tree, good)
        control_line = pane_line_fixed(genuine, log_dir)
        print("  PANE: %s" % control_line)
        passed += _check(
            "evidence requirement does not suppress a real verdict",
            "broken link" in control_line,
            "observed: %s" % control_line,
        )

    print("\n" + "=" * 70)
    print("RESULT: %d/%d checks passed" % (passed, total))
    print("=" * 70)
    return 0 if passed == total else 1


if __name__ == "__main__":
    sys.exit(main())
