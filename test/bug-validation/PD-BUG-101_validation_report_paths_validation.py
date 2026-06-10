"""
PD-BUG-101 Manual Validation: --validate writes the report to logs/linkwatcher/
and loads its ignore rules from tools/linkwatcher/ (not the legacy
process-framework-local/tools/linkWatcher/ path).

PURPOSE:
    Before the fix, the LinkWatcherConfig defaults pointed at the pre-Phase-5
    location:
        validation_output_dir   = "process-framework-local/tools/linkWatcher"
        validation_ignore_file  = "process-framework-local/tools/linkWatcher/.linkwatcher-ignore"
    so `python main.py --validate` wrote LinkWatcherBrokenLinks.txt to a directory
    the docs no longer reference, and read its suppression rules from there too.

    The fix splits the two by their nature:
        validation_output_dir   = "logs/linkwatcher"            (runtime output, gitignored)
        validation_ignore_file  = "tools/linkwatcher/.linkwatcher-ignore"  (tracked config)

    This script builds a throwaway project with ONE genuinely broken link and ONE
    link that an ignore rule should suppress, runs the REAL `--validate` CLI, and
    shows the human where the report landed and that suppression still works from
    the new ignore-file location.

HOW TO RUN:
    python test/bug-validation/PD-BUG-101_validation_report_paths_validation.py

EXPECTED RESULT (fixed code):
    - Report exists at  <tmp>/logs/linkwatcher/LinkWatcherBrokenLinks.txt
    - Report does NOT exist at <tmp>/process-framework-local/tools/linkWatcher/
    - Report lists the genuinely-broken link (missing-real.md)
    - Report does NOT list the suppressed link (placeholder-example.md), proving the
      ignore file at <tmp>/tools/linkwatcher/.linkwatcher-ignore was loaded
    ->  VALIDATION PASSED.

    With the old defaults the report would appear under
    process-framework-local/tools/linkWatcher/ and the ignore file there would be
    consulted instead.
"""

import subprocess
import sys
import tempfile
from pathlib import Path

# parent: bug-validation -> test -> repo root
PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
MAIN_PY = PROJECT_ROOT / "main.py"

NEW_REPORT_REL = Path("logs/linkwatcher/LinkWatcherBrokenLinks.txt")
LEGACY_REPORT_REL = Path("process-framework-local/tools/linkWatcher/LinkWatcherBrokenLinks.txt")
IGNORE_REL = Path("tools/linkwatcher/.linkwatcher-ignore")


def _build_project(root: Path) -> None:
    """A tiny project: one real broken link + one link suppressed by an ignore rule."""
    docs = root / "docs"
    docs.mkdir(parents=True, exist_ok=True)
    (docs / "page.md").write_text(
        "# Page\n\n"
        "- [genuinely broken](missing-real.md)\n"
        "- [example placeholder](placeholder-example.md)\n",
        encoding="utf-8",
    )
    # Ignore rule at the NEW tracked config location. Suppresses the placeholder
    # link only — the genuinely-broken one must still be reported.
    ignore = root / IGNORE_REL
    ignore.parent.mkdir(parents=True, exist_ok=True)
    ignore.write_text("docs/*.md -> placeholder-example.md\n", encoding="utf-8")


def main() -> int:
    print("=" * 64)
    print("PD-BUG-101: validation report + ignore-file path validation")
    print("=" * 64)

    if not MAIN_PY.exists():
        print(f"FAIL: main.py not found at {MAIN_PY}")
        return 1

    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        _build_project(root)

        print("\nBEFORE (project on disk)")
        print(f"  project root     : {root}")
        print(f"  ignore file at   : {IGNORE_REL}  (NEW tracked config location)")
        print(
            "  links in page.md : missing-real.md (broken), placeholder-example.md (should be suppressed)"
        )

        proc = subprocess.run(
            [sys.executable, str(MAIN_PY), "--project-root", str(root), "--validate"],
            cwd=str(root),
            capture_output=True,
            text=True,
            timeout=120,
        )
        print("\nCLI OUTPUT")
        for line in (proc.stdout or "").splitlines():
            if "Report written" in line or "Broken links" in line:
                print(f"  {line.strip()}")

        new_report = root / NEW_REPORT_REL
        legacy_report = root / LEGACY_REPORT_REL

        print("\nAFTER (where did the report go?)")
        print(f"  {NEW_REPORT_REL}  exists: {new_report.exists()}   <- expected True")
        print(f"  {LEGACY_REPORT_REL}  exists: {legacy_report.exists()}   <- expected False")

        report_text = new_report.read_text(encoding="utf-8") if new_report.exists() else ""
        lists_broken = "missing-real.md" in report_text
        lists_suppressed = "placeholder-example.md" in report_text

        print("\nSUPPRESSION (ignore file loaded from tools/linkwatcher/?)")
        print(f"  report lists missing-real.md (broken)        : {lists_broken}   <- expected True")
        print(
            f"  report lists placeholder-example.md (ignored): {lists_suppressed}   <- expected False"
        )

        ok = (
            new_report.exists()
            and not legacy_report.exists()
            and lists_broken
            and not lists_suppressed
        )

        print("\n" + "=" * 64)
        if ok:
            print("VALIDATION PASSED — report in logs/linkwatcher/, suppression loaded")
            print("from tools/linkwatcher/.linkwatcher-ignore; legacy path unused.")
            print("=" * 64)
            return 0
        print("VALIDATION FAILED — see expected-vs-actual above.")
        print("=" * 64)
        return 1


if __name__ == "__main__":
    sys.exit(main())
