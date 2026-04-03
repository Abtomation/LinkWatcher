---
id: PD-REF-150
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-02
updated: 2026-04-02
target_area: LinkValidator
refactoring_scope: Extract _should_skip_reference() from _check_file() to consolidate 5 redundant standalone-type skip conditions
priority: Medium
mode: lightweight
---

# Lightweight Refactoring Plan: Extract _should_skip_reference() from _check_file() to consolidate 5 redundant standalone-type skip conditions

- **Target Area**: LinkValidator
- **Priority**: Medium
- **Created**: 2026-04-02
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD152 — Extract skip-logic from _check_file()

**Scope**: Extract a `_should_skip_reference()` method from `_check_file()` in `linkwatcher/validator.py` to consolidate 5 redundant skip conditions (ignored patterns, code block, archival details, template file, placeholder lines, table rows) that currently repeat the `ref.link_type in _STANDALONE_LINK_TYPES` check. Reduces `_check_file` by ~35 lines and groups all per-reference skip logic in one testable method. Dims: AC (Architectural Consistency).

**Changes Made**:
- [x] Extracted `_should_skip_reference()` static method (validator.py:397-441) — consolidates 6 skip conditions into one method with early return for non-standalone types
- [x] Simplified `_check_file()` loop (validator.py:315-327) — replaced 35 lines of sequential if-continue blocks with single method call

**Test Baseline**: 75 passed, 0 failed (test_validator.py); 654 passed, 5 skipped, 6 xfailed (full suite)
**Test Result**: 75 passed, 0 failed (test_validator.py); 654 passed, 5 skipped, 6 xfailed (full suite) — identical

**Documentation & State Updates**:
- [x] Feature implementation state file (6.1.1) updated, or N/A — _Grepped feature state files for `_check_file` — no references found_
- [x] TDD (6.1.1) updated, or N/A — _Grepped TDD directory for `_check_file` — no references found_
- [x] Test spec (6.1.1) updated, or N/A — _Grepped test specs for `_check_file` — no references found; no behavior change_
- [x] FDD (6.1.1) updated, or N/A — _Grepped FDD directory for `_check_file` — no references found_
- [x] ADR updated, or N/A — _Grepped ADR directory for `validator` — no references found_
- [x] Validation tracking updated, or N/A — _6.1.1 validation R3 already COMPLETE; internal extraction doesn't affect validation results_
- [x] Technical Debt Tracking: TD152 marked resolved via Update-TechDebt.ps1

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD152 | Complete | None | None |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)

