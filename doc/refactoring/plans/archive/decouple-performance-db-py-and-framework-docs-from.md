---
id: PD-REF-213
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-29
updated: 2026-04-29
target_area: process-framework/scripts/test, process-framework/guides/03-testing, process-framework/tasks/03-testing
mode: lightweight
refactoring_scope: Decouple performance_db.py and framework docs from LinkWatcher-specific test IDs
debt_item: TD245
priority: Low
---

# Lightweight Refactoring Plan: Decouple performance_db.py and framework docs from LinkWatcher-specific test IDs

- **Target Area**: process-framework/scripts/test, process-framework/guides/03-testing, process-framework/tasks/03-testing
- **Priority**: Low
- **Created**: 2026-04-29
- **Author**: AI Agent & Human Partner
- **Status**: Planning
- **Debt Item**: TD245
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD245 — Decouple framework-shared performance artifacts from LinkWatcher-specific test IDs

**Scope**: Three framework-shared performance artifacts contain LinkWatcher-specific test IDs that break reusability when the framework is adopted in another project:

1. `process-framework/scripts/test/performance_db.py` — `TOLERANCES` dict (lines 66-80) hardcodes 13 LinkWatcher test IDs (BM-001/002/003/007/008, PH-001/002/003/004/005 with sub-keys) and project-specific thresholds. Module docstring and `--test-id` argparse help also reference `BM-001` as a concrete example.
2. `process-framework/guides/03-testing/performance-testing-guide.md` — two CLI command examples (lines 280, 312) reference concrete `BM-001`. (Tables on lines 52/90/108 already use generic `BM-0xx`/`PH-0xx`.)
3. `process-framework/tasks/03-testing/performance-baseline-capture-task.md` — two CLI command examples (lines 86, 131) reference concrete `BM-001`.

**DA root cause analysis** (per L2 DA-category guidance):
- **Originating session**: `git log --all` for `performance_db.py` returns a single commit (`21fc102`, 2026-04-10, "Bulk update") — the script was created with the concrete LinkWatcher test IDs already embedded. This is **initial coupling, not subsequent drift**: the framework script was authored against the local performance test suite and concrete test IDs were used as defaults rather than as project-side configuration.
- **Drift mechanism**: When designing a script intended to be shared across projects, project-specific data (test IDs and tolerance thresholds) was placed inside the shared script rather than in a project-side config file. The same pattern applied to docstring/help-text examples.
- **Discovery trigger**: The coupling became visible during PF-STA-099 (performance test ID renumber, Mechanical Rename Variant of PF-TSK-014) — when LinkWatcher's test IDs were renumbered, the divergence between framework "shared" intent and actual project-specific content became apparent.
- **Process improvement candidate**: Future framework-script creation guidance should explicitly call out "no project-specific data in shared scripts" as a design check. This is captured by closing TD245 itself; consider whether a process improvement is warranted (assess at L11).

**Approach (Option B, approved)**:
1. Extract `TOLERANCES` dict to a project-side config file: `test/state-tracking/permanent/performance-tolerances.json` (mirrors where `performance-results.db` already lives — same project-side directory).
2. Replace hardcoded `TOLERANCES` in `performance_db.py` with a `_load_tolerances()` helper that reads the JSON file. Graceful fallback to empty dict if file missing (preserves correctness; just no warnings printed).
3. Replace concrete `BM-001` in module docstring and argparse help with `BM-NNN` placeholder.
4. Replace concrete `BM-001` in the 4 CLI examples in the two markdown files with `BM-NNN`.

**Changes Made**:
- [x] Created `test/state-tracking/permanent/performance-tolerances.json` with the 13 LinkWatcher tolerances (byte-identical values to the previous `TOLERANCES` dict).
- [x] Refactored `performance_db.py`: replaced inline `TOLERANCES` dict with `_load_tolerances()` reading the JSON file (with file-not-found and JSONDecodeError graceful fallback to `{}`); added `_resolve_tolerances_path()` mirroring `_resolve_db_path()`; extracted shared `_project_root()` helper to avoid duplication.
- [x] Replaced `BM-001` → `BM-NNN` in `performance_db.py` module docstring (3 locations) and argparse help (1 location).
- [x] Replaced `BM-001` → `BM-NNN` in `performance-testing-guide.md` CLI examples (2 lines).
- [x] Replaced `BM-001` → `BM-NNN` in `performance-baseline-capture-task.md` CLI examples (2 lines).
- [x] Added "Script-side tolerances" callout to `performance-testing-guide.md` Tolerance Bands section documenting the JSON file location and schema.
- [x] Added a paragraph to `performance_db.py` module docstring documenting the JSON config location and graceful-fallback behavior.

**Smoke test** (verifying byte-identical runtime behavior):
- `python -c "import performance_db; ..."` — loaded 13 tolerances with identical (op, threshold, unit) tuples to the previous hardcoded dict.
- `python performance_db.py regressions` — output: "No regressions detected. (17 tests checked)" — matches pre-refactor.
- `python performance_db.py trend --test-id BM-001 --last 3` — output includes `Tolerance: >50.0 files/sec — PASS` — tolerance lookup working correctly.

**Test Baseline** (captured 2026-04-29 pre-refactor): 831 passed, 3 skipped, 4 deselected (slow markers), 4 xfailed, 0 failed — clean baseline. Pre-existing failing tests: none.

**Test Coverage Assessment** (L4): `performance_db.py` has no dedicated automated test file — it is a CLI utility script (record/trend/regressions/export). Coverage strategy for this refactoring:
- The change is mechanical: replace inline `TOLERANCES` dict with `_load_tolerances()` reading from a JSON file with identical content. Behavior is byte-identical when the JSON file matches the current dict.
- Risk surface is the JSON-loading code path (file-not-found graceful fallback, JSON parse).
- Mitigation: post-refactor manual smoke test of `record` (tolerance-warning path) and `regressions` (tolerance-violation path) — see L6 verification steps.
- Writing a dedicated pytest file for this CLI script is disproportionate to the risk of this single low-priority refactoring. Deferred — out of scope for TD245.

**Test Result** (post-refactor): 830 passed, 1 failed, 3 skipped, 4 deselected, 4 xfailed. Diff vs. baseline: **1 failure not in baseline** — `test/automated/unit/test_validator.py::TestLinkValidator::test_linkwatcher_local_dir_ignored`.

**L7 ownership analysis**: This failure is **not caused by this refactoring**:
- `performance_db.py` imports only stdlib (`argparse`, `csv`, `io`, `json`, `sqlite3`, `subprocess`, `sys`, `datetime`, `pathlib`). It has no link to `LinkValidator` / `LinkWatcherConfig` / any LinkWatcher module.
- The other modified files (markdown docs + a new JSON config) are framework documentation and project-side data — they cannot affect Python test behavior.
- The failing test exercises `LinkValidator` against a fixture in `tmp_path`. The session's pre-existing working-tree modifications to `src/linkwatcher/config/settings.py` changed `validation_extra_ignored_dirs` from `"LinkWatcher_run"` to a multi-segment path `"process-framework-local/tools/linkWatcher"`. The test reproducibly fails (3/3 isolated runs) because the validator's matching logic apparently doesn't ignore multi-segment paths via that field. This is pre-existing WIP debt unrelated to TD245.
- Forensic note on baseline-vs-post divergence: between baseline (12:14) and post-refactor (12:28) test runs, `src/linkwatcher/validator.py` was touched (mtime 12:26:44) by LinkWatcher reacting to a pytest tmp-file move event for that file (`file_replaced_not_deleted` log entries). Bytes are unchanged, but pytest's import cache and/or some race may have produced the lucky pass in the baseline run.

**Action**: Pre-existing test failure surfaced to human partner at L11 checkpoint; not in scope for TD245. No bug report filed (the failing behavior originates from pre-existing in-progress edits in the working tree, not from the codebase as committed at HEAD).

**Documentation & State Updates**:

> **Framework-infrastructure shortcut applied**: This refactoring targets framework-shared scripts and guides (`process-framework/`) plus a new project-side data file. It does not touch any LinkWatcher product feature code, so feature-level design documents (FDD/TDD/test spec/ADR/integration narrative) and feature implementation state files do not reference the affected components. Items 1–6 batched as N/A with that single justification.

- [x] Feature implementation state file — N/A: change targets framework-shared scripts and project-side data, not LinkWatcher feature code. Greps confirmed no feature state file references `performance_db.py`, `TOLERANCES`, or `performance-tolerances.json`.
- [x] TDD — N/A: same reason; no LinkWatcher TDD references the framework script's internals.
- [x] Test spec — N/A: same reason.
- [x] FDD — N/A: same reason.
- [x] ADR — N/A: same reason.
- [x] Integration Narrative — N/A: same reason; framework-shared script is not part of any cross-feature LinkWatcher workflow.
- [x] Validation tracking — N/A: framework script not tracked in feature validation rounds.
- [x] Technical Debt Tracking: TD245 marked resolved via `Update-TechDebt.ps1` on 2026-04-29 (moved from Registry to Recently Resolved).

**Additional doc updates made within scope of this refactoring**:
- Updated `performance-testing-guide.md` Tolerance Bands section with a "Script-side tolerances" callout documenting the JSON file location and format — needed so framework adopters know where to define their thresholds.
- Updated `performance_db.py` module docstring with a paragraph documenting the JSON config location.

**Bugs Discovered**: None caused by this refactoring. **Pre-existing failure observed (not in scope)**: `test_linkwatcher_local_dir_ignored` reproducibly fails (3/3 isolated runs) due to pre-existing working-tree edits to `src/linkwatcher/config/settings.py` (multi-segment `validation_extra_ignored_dirs` value not matched by validator logic). Surfaced to human partner at L11 for triage; no bug report filed because the failing behavior is not present in HEAD-committed code.

<!-- BATCH MODE: Copy the "## Item N" section above for each additional debt item in this session -->

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD245 | Complete | None caused by this refactoring; one pre-existing test failure (`test_linkwatcher_local_dir_ignored`) observed and surfaced — not owned by this session | Performance Testing Guide gained "Script-side tolerances" callout; performance_db.py docstring documents JSON config location |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
