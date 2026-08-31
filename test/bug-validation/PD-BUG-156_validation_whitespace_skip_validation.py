"""
PD-BUG-156 Manual Validation: validation scan silently skips targets containing a space.

PURPOSE:
    The broken-link scan (``--validate``) discarded EVERY link target containing
    a space before ever checking it on disk.  The skip lived in one predicate in
    ``LinkValidator._TARGET_SKIP_PREDICATES``::

        (lambda t, lt: " " in t, "contains whitespace")

    That predicate is load-bearing noise suppression -- for HEURISTIC link types
    (backticked commands, bare prose paths, YAML/JSON description strings) a
    space almost always means the string is not a path at all.  Deleting it was
    measured at 54 new broken-link reports across this repo, none of them
    genuine.  So the defect was never "the predicate exists"; it was that the
    predicate was applied link-type-BLIND.

    For EXPLICIT link syntax -- ``[text](path)``, ``[label]: path``,
    ``<a href="path">`` -- the author wrote deliberate link markup, so a space is
    part of the filename.  CommonMark in fact REQUIRES the angle-bracket form
    ``[text](<a b.md>)`` when a destination contains a space, which makes that
    the one population the form exists for.  Refusing to check it meant such a
    link could go stale and no scan would ever say so.

    The failure was silent in the strongest sense: the reference was never
    selected, so there was no warning, no count, and no skipped-link entry.  It
    simply did not appear in ``links_checked``.

    The fix narrows the predicate to exempt the explicit link types, reusing the
    ``_EXPLICIT_LINK_TYPES`` frozenset already defined in the same module for the
    sibling bare-filename predicate (BUG-088 drew the identical
    explicit-vs-heuristic line).

    This script runs the REAL LinkValidator over a temp workspace TWICE -- once
    with the old link-type-blind predicate restored in-process, once with the
    shipped code -- and prints both columns side by side, so the before/after is
    visible in a single run.

    The two CONTROL rows are space-free and must pass in BOTH columns: a failing
    control proves the fixture is broken rather than the code.  Checks 3 and 4
    are guards that must also pass in both columns -- they fail if the fix
    over-reached, either by reporting a link that resolves or by letting
    heuristic noise back in.  Only Checks 1 and 2 are expected to flip.

HOW TO RUN:
    python test/bug-validation/PD-BUG-156_validation_whitespace_skip_validation.py

TO OBSERVE THE BUG YOURSELF (filesystem reproduction, no code):
    1. In any project, create a file whose name contains a space, e.g.
       ``doc/release notes.md``, and link to it from ``doc/index.md`` using the
       CommonMark angle form::

           [notes](<release notes.md>)
           [control](gone.md)

    2. Delete ``doc/release notes.md`` so the first link is now stale.
    3. Run the validation scan:
           pwsh.exe -ExecutionPolicy Bypass -File process-framework/tools/linkWatcher/run_linkwatcher_validate.ps1
    4. Read the report it prints the path to.  Against a pre-fix build only
       ``gone.md`` is listed -- the stale ``release notes.md`` link is missing
       entirely, and the scan reports one fewer link checked than the file
       contains.  Against a fixed build BOTH are listed.

    NOTE: the launcher runs the INSTALLED LinkWatcher (under the install dir,
    default ``%USERPROFILE%\\bin``), which lags this repository until a release.
    To observe the fix before release, run the repo copy directly:
        python main.py --validate --project-root <your project>

EXPECTED RESULT:
    All 6 checks FAIL in the "pre-fix" column except the controls, and all 6
    PASS in the "post-fix" column.
"""

import os
import sys
import tempfile
from pathlib import Path

# Add project root to path
project_root = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(project_root))

import linkwatcher.validator as validator_module  # noqa: E402
from linkwatcher.config.settings import LinkWatcherConfig  # noqa: E402
from linkwatcher.validator import LinkValidator  # noqa: E402

# A workspace where NOTHING under gone/ exists on disk, and doc/a b.md DOES.
FILES = {
    "doc/a b.md": "# a real file whose name contains a space\n",
    "doc/stale.md": (
        "# Stale links\n"
        "\n"
        "Angle form, space:  [angle](<gone/a b.md>)\n"
        "Tight form, space:  [tight](gone/a b.md)\n"
        "CONTROL space-free: [control](gone/ab.md)\n"
        "\n"
        "Ref usage [r] and control [rc].\n"
        "\n"
        "[r]: <gone/a b.md>\n"
        "[rc]: gone/ab.md\n"
    ),
    "doc/resolves.md": (
        "# Links that must NOT be reported\n"
        "\n"
        "Angle form: [ok](<a b.md>)\n"
        "Tight form: [ok2](a b.md)\n"
    ),
    "doc/prose.md": (
        "# Heuristic noise that must STAY suppressed\n"
        "\n"
        "Run `pytest test/automated/unit/test_config.py` to check.\n"
        "The file carries 7 `../missing/ ../gone/` links.\n"
        "CONTROL space-free: [control](gone/cd.md)\n"
    ),
}


def _make_config():
    cfg = LinkWatcherConfig()
    cfg.monitored_extensions = {".md"}
    cfg.ignored_directories = {".git"}
    cfg.enable_dart_parser = False
    cfg.enable_python_parser = False
    cfg.enable_powershell_parser = False
    return cfg


def _build(root):
    for rel, content in FILES.items():
        full = os.path.join(root, rel.replace("/", os.sep))
        os.makedirs(os.path.dirname(full), exist_ok=True)
        with open(full, "w", encoding="utf-8") as fh:
            fh.write(content)


def _scan(root):
    """Run the real validator; return (reported targets, links_checked)."""
    result = LinkValidator(root, _make_config()).validate()
    return {bl.target_path for bl in result.broken_links}, result.links_checked


def _checks(reported, checked):
    """Return a list of (label, passed, detail). Controls come first."""
    noisy = {t for t in reported if " " in t and t.startswith(("../", "pytest"))}
    return [
        (
            "CONTROL  space-free stale link is reported",
            "gone/ab.md" in reported,
            "gone/ab.md",
        ),
        (
            "CONTROL  space-free stale link (prose file) is reported",
            "gone/cd.md" in reported,
            "gone/cd.md",
        ),
        (
            "Check 1  stale angle/tight link with a space IS reported",
            "gone/a b.md" in reported,
            "gone/a b.md",
        ),
        (
            "Check 2  every link in the workspace was actually checked",
            checked >= 8,
            "links_checked=%d (expected >= 8)" % checked,
        ),
        (
            "Check 3  resolving space-containing links are NOT reported",
            "a b.md" not in reported,
            "a b.md must be absent",
        ),
        (
            "Check 4  heuristic noise with spaces stays suppressed",
            noisy == set(),
            "noise leaked: %s" % sorted(noisy) if noisy else "none leaked",
        ),
    ]


def main():
    print("=" * 74)
    print("PD-BUG-156: validation scan silently skips targets containing a space")
    print("=" * 74)

    original = validator_module._TARGET_SKIP_PREDICATES
    # The pre-fix predicate: link-type-blind.
    pre_fix = tuple(
        (lambda t, lt: " " in t, name) if name == "contains whitespace" else (p, name)
        for p, name in original
    )

    with tempfile.TemporaryDirectory() as tmpdir:
        _build(tmpdir)

        validator_module._TARGET_SKIP_PREDICATES = pre_fix
        try:
            before_reported, before_checked = _scan(tmpdir)
        finally:
            validator_module._TARGET_SKIP_PREDICATES = original

        after_reported, after_checked = _scan(tmpdir)

    print()
    print("WORKSPACE: 4 files. doc/a b.md EXISTS; nothing under gone/ exists.")
    print()
    print(
        "  pre-fix  reported %d broken, checked %d links" % (len(before_reported), before_checked)
    )
    print("           %s" % sorted(before_reported))
    print("  post-fix reported %d broken, checked %d links" % (len(after_reported), after_checked))
    print("           %s" % sorted(after_reported))
    print()

    before = _checks(before_reported, before_checked)
    after = _checks(after_reported, after_checked)

    print("%-52s %-10s %-10s" % ("", "PRE-FIX", "POST-FIX"))
    print("-" * 74)
    for (label, ok_before, _), (_, ok_after, detail) in zip(before, after):
        print(
            "%-52s %-10s %-10s"
            % (label, "PASS" if ok_before else "FAIL", "PASS" if ok_after else "FAIL")
        )
        if not ok_after:
            print("      detail: %s" % detail)

    passed_before = sum(1 for _, ok, _ in before if ok)
    passed_after = sum(1 for _, ok, _ in after if ok)
    total = len(after)

    print("-" * 74)
    print(
        "pre-fix  score: %d/%d   post-fix score: %d/%d"
        % (passed_before, total, passed_after, total)
    )
    print()

    if passed_after != total:
        print("RESULT: FAILED - the fix is not behaving as expected.")
        return 1
    if passed_before == total:
        print("RESULT: INCONCLUSIVE - the pre-fix column passed everything, so this")
        print("        script does not discriminate. Investigate before trusting it.")
        return 2
    print(
        "RESULT: PASSED - %d check(s) fail pre-fix and all %d pass post-fix."
        % (total - passed_before, total)
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
