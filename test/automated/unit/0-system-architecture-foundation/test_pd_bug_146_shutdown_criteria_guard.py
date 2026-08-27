"""
Document Metadata:
ID: TE-TST-160
Type: Test File
Category: Test
Version: 1.0
Created: 2026-08-27
Updated: 2026-08-27
Component Name: e2e_acceptance_cases
Feature Id: 0.1.1
Language: Python
Test Name: PD Bug 146 Shutdown Criteria Guard
Test Type: Unit
"""

# PD-BUG-146: an E2E case must not assert an outcome its own harness prevents.
#
# E2E cases that stop LinkWatcher through Stop-WorkspaceLinkWatcher are ended by
# `Stop-Process -Force` (lw-e2e-helpers.ps1) — a hard TerminateProcess. No Python
# shutdown code runs, so under those cases:
#   - the daemon emits no shutdown/stopping log record, and
#   - the exit code is -1, never 0.
#
# TE-E2E-020 nevertheless listed "Application log contains a shutdown/stopping
# message" and "LinkWatcher process exited with code 0" among its pass criteria,
# and TE-E2E-021 claimed the process "exits cleanly". Verify-TestResult.ps1
# compares only files under expected/ and cannot read logs or exit codes, so the
# impossible criteria were never machine-checked and the case sat at Passed and
# Audit Approved. This guard is the missing check: nothing else in the suite can
# tell a criterion that is merely unverified from one that is unsatisfiable.
#
# Deliberately matches ASSERTIONS, not mentions. Only the assertion-bearing
# sections are scanned, and a line carrying a negation is skipped — so prose that
# documents WHY a forced kill emits no shutdown record does not trip the guard
# (the text-match trap: a note explaining a removal must not fail the check that
# pins the removal).
#
# Cases whose process exits on its own — the --validate cases TE-E2E-026/027/028
# — legitimately assert exit codes and are out of scope by construction: they
# never call Stop-WorkspaceLinkWatcher. test_validate_cases_are_out_of_scope
# pins that discrimination, so this guard cannot pass by scanning nothing.

import re
from pathlib import Path

import pytest

pytestmark = [
    pytest.mark.feature("0.1.1"),
    pytest.mark.priority("Standard"),
    pytest.mark.test_type("unit"),
]

PROJECT_ROOT = Path(__file__).resolve().parents[4]
E2E_ROOT = PROJECT_ROOT / "test" / "e2e-acceptance-testing"

# The helper whose only stop route is `Stop-Process -Force`.
FORCE_KILL_HELPER = "Stop-WorkspaceLinkWatcher"

# Sections that state what the case asserts. Prose sections (Notes, Fail Actions,
# Test Fixtures) are excluded: they explain rather than assert.
ASSERTION_HEADINGS = {
    "steps",
    "expected results",
    "behavioral outcomes",
    "verification method",
    "pass criteria",
    # Group master tests restate their cases' expectations in these sections —
    # PD-BUG-146 also lived in master-test-graceful-shutdown.md, unchecked.
    "quick validation sequence",
    "if failed",
}

# A hard kill sets exit code -1, so any positive claim of exit code 0 is unsatisfiable.
EXIT_CODE_ZERO = re.compile(r"exit(?:ed|s)?\s*(?:with\s*)?code\s*(?:is\s*)?[:=]?\s*0\b")

# A hard kill runs no shutdown code, so any claim that a shutdown/stopping/stopped
# record was logged is unsatisfiable. Keyed on record/message as well as log: the
# same claim reads "no service_stopping record" just as naturally as "not in the log".
SHUTDOWN_LOG = re.compile(
    r"(?:\b(?:logs?|records?|messages?)\b[^.]{0,60}\b(?:shutdown|stopping|stopped)\b"
    r"|\b(?:shutdown|stopping|stopped)\b[^.]{0,60}\b(?:logs?|records?|messages?)\b)"
)

# A forced termination is not a clean exit, so claiming one is unsatisfiable.
EXITS_CLEANLY = re.compile(r"exit(?:ed|s)?\s+cleanly")

UNSATISFIABLE_PATTERNS = (
    ("exit code 0", EXIT_CODE_ZERO),
    ("shutdown log record", SHUTDOWN_LOG),
    ("clean exit", EXITS_CLEANLY),
)

# A claim that is itself denied is documentation, not an assertion of the outcome.
# Scoped to the matched claim plus a short lead-in, NOT the whole line: an
# elaboration such as "exits cleanly (no crash, no hang)" negates nothing, while
# "the log carries no shutdown record" does.
NEGATION_LOOKBEHIND = 20
NEGATION_MARKERS = (
    " no ",
    " not ",
    " never ",
    " non-zero ",
    " nonzero ",
    " cannot ",
    " without ",
    " neither ",
)


def _normalize(line: str) -> str:
    """Strip markdown emphasis and checkbox syntax; pad so negation markers match at edges."""
    text = line.replace("*", "").replace("`", "").replace("_", " ")
    text = re.sub(r"^\s*-\s*\[[ x]\]\s*", "", text)
    text = re.sub(r"^\s*[-+]\s*", "", text)
    text = re.sub(r"\s+", " ", text).strip().lower()
    return f" {text} "


def _is_negated(normalized: str, start: int, end: int) -> bool:
    """True when a negation sits inside the matched claim or just ahead of it."""
    window = normalized[max(0, start - NEGATION_LOOKBEHIND) : end]
    return any(marker in window for marker in NEGATION_MARKERS)


def _assertion_lines(markdown: str):
    """Yield (line_number, raw_line) for lines inside assertion-bearing sections."""
    current = None
    for number, raw in enumerate(markdown.splitlines(), start=1):
        heading = re.match(r"^(#{2,4})\s+(.*)$", raw)
        if heading:
            current = re.sub(r"[^a-z ]", "", heading.group(2).lower()).strip()
            continue
        if current in ASSERTION_HEADINGS:
            yield number, raw


def _force_kill_cases():
    """Every E2E case directory whose run.ps1 ends the daemon with a hard kill."""
    cases = []
    for run_script in sorted(E2E_ROOT.glob("*/templates/*/run.ps1")):
        if FORCE_KILL_HELPER not in run_script.read_text(encoding="utf-8"):
            continue
        case_doc = run_script.parent / "test-case.md"
        if case_doc.exists():
            cases.append(case_doc)
    return cases


def _force_kill_master_tests():
    """Group master tests whose EVERY case is force-killed.

    A mixed group is excluded: the link-health group's master test legitimately
    restates the exit codes of its self-exiting --validate cases.
    """
    masters = []
    for templates_dir in sorted(E2E_ROOT.glob("*/templates")):
        run_scripts = list(templates_dir.glob("*/run.ps1"))
        if not run_scripts:
            continue
        if not all(
            FORCE_KILL_HELPER in script.read_text(encoding="utf-8") for script in run_scripts
        ):
            continue
        masters.extend(sorted(templates_dir.glob("master-test-*.md")))
    return masters


FORCE_KILL_CASES = _force_kill_cases()
FORCE_KILL_MASTER_TESTS = _force_kill_master_tests()


def _violations(case_doc: Path):
    found = []
    for number, raw in _assertion_lines(case_doc.read_text(encoding="utf-8")):
        normalized = _normalize(raw)
        for label, pattern in UNSATISFIABLE_PATTERNS:
            match = pattern.search(normalized)
            if match and not _is_negated(normalized, match.start(), match.end()):
                found.append((number, label, raw.strip()))
    return found


# The exact criteria TE-E2E-020 and TE-E2E-021 carried before the PD-BUG-146 fix.
# If the matcher is ever loosened, these go red rather than the guard silently
# passing every case — a scan that flags nothing is indistinguishable from a clean
# tree without them.
HISTORICAL_VIOLATIONS = [
    "   - **Observe**: Process exit code is 0; log shows shutdown message",
    '- Log shows clean shutdown message (e.g., "Stopping", "Shutdown complete", "LinkWatcher stopped", or similar)',
    "- Process exits with code 0",
    "- [ ] **Log check**: Check application log for clean shutdown message and absence of errors",
    "- [ ] Application log contains a shutdown/stopping message",
    "- [ ] LinkWatcher process exited with code 0",
    "4. **Verify clean shutdown**: Check that the process exited cleanly",
    "- LinkWatcher process exits cleanly (no crash, no hang)",
    # From master-test-graceful-shutdown.md — the negation ("no error messages")
    # sits just outside the lookbehind window, so this one is pinned by
    # measurement rather than by reading the regex.
    "   - Expected: Clean shutdown, no error messages, process exits with code 0, all files unchanged",
]

# The corrected replacements, plus prose that DENIES the outcome. None may be
# flagged: a note explaining why a forced kill emits no shutdown record must not
# fail the check that pins its removal.
PERMITTED_LINES = [
    "- The daemon is ended by a hard kill and runs no Python cleanup, so it writes no "
    "`service_stopping` / `service_stopped` records and its exit code is -1.",
    "- LinkWatcher neither crashes nor hangs before `run.ps1` terminates it",
    "- [ ] All project files are byte-identical to their pre-test state (no corruption)",
    "- [ ] No error messages, exceptions, or stack traces in application log up to termination",
    "- the log carries no shutdown record",
    "- [ ] Exit code is 1",
    "- [ ] LinkWatcher process exited without hanging (within reasonable timeout)",
]


def _flags(line: str) -> bool:
    normalized = _normalize(line)
    for _, pattern in UNSATISFIABLE_PATTERNS:
        match = pattern.search(normalized)
        if match and not _is_negated(normalized, match.start(), match.end()):
            return True
    return False


class TestMatcherDiscriminates:
    """The matcher must separate an unsatisfiable claim from prose describing one."""

    @pytest.mark.parametrize("line", HISTORICAL_VIOLATIONS)
    def test_flags_the_historical_violations(self, line):
        assert _flags(line), f"matcher no longer flags a known PD-BUG-146 violation: {line!r}"

    @pytest.mark.parametrize("line", PERMITTED_LINES)
    def test_does_not_flag_corrected_or_negated_lines(self, line):
        assert not _flags(line), f"matcher flags a legitimate line: {line!r}"


class TestShutdownCriteriaGuard:
    """PD-BUG-146 regression guard for force-killed E2E acceptance cases."""

    def test_discovery_is_not_vacuous(self):
        """The scan must actually find force-killed cases, or every assertion below is empty."""
        assert len(FORCE_KILL_CASES) >= 20, (
            f"Only {len(FORCE_KILL_CASES)} force-killed E2E cases discovered under {E2E_ROOT} — "
            "the glob or the helper name has drifted, so this guard is checking nothing."
        )

    def test_validate_cases_are_out_of_scope(self):
        """Cases whose process self-exits must NOT be scanned — their exit-code criteria are valid."""
        scanned = {doc.parent.name for doc in FORCE_KILL_CASES}
        for self_exiting in (
            "TE-E2E-026-validate-clean-workspace",
            "TE-E2E-027-validate-broken-links-detected",
            "TE-E2E-028-validate-ignore-rules-suppress",
        ):
            assert self_exiting not in scanned, (
                f"{self_exiting} runs main.py --validate, which exits on its own; it must stay "
                "out of this guard or its legitimate exit-code criteria would be flagged."
            )

    def test_master_test_discovery_is_not_vacuous(self):
        """At least the graceful-shutdown group's master tests must be in scope."""
        assert FORCE_KILL_MASTER_TESTS, (
            "No group master tests discovered for all-force-killed groups — the "
            "master-test-*.md glob or the group layout has drifted."
        )

    @pytest.mark.parametrize("master_doc", FORCE_KILL_MASTER_TESTS, ids=lambda doc: doc.name)
    def test_master_tests_carry_no_unsatisfiable_criteria(self, master_doc):
        """A master test must not restate an expectation its group's harness prevents."""
        violations = _violations(master_doc)
        assert not violations, (
            f"{master_doc.name} covers a group whose cases are all force-killed, but asserts:\n"
            + "\n".join(f"  line {n}: [{label}] {text}" for n, label, text in violations)
        )

    @pytest.mark.parametrize("case_doc", FORCE_KILL_CASES, ids=lambda doc: doc.parent.name)
    def test_no_unsatisfiable_shutdown_criteria(self, case_doc):
        """A force-killed case must not assert a shutdown record, exit code 0, or a clean exit."""
        violations = _violations(case_doc)
        assert not violations, (
            f"{case_doc.parent.name} stops LinkWatcher with a hard kill "
            f"({FORCE_KILL_HELPER} -> Stop-Process -Force), which emits no shutdown record and "
            f"exits -1, but asserts:\n"
            + "\n".join(f"  line {n}: [{label}] {text}" for n, label, text in violations)
        )
