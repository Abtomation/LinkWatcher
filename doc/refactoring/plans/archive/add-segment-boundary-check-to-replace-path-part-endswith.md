---
id: PD-REF-164
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-09
updated: 2026-04-09
priority: Medium
target_area: database.py
feature_id: 0.1.2
mode: lightweight
refactoring_scope: Add segment-boundary check to _replace_path_part endswith
debt_item: TD179
---

# Lightweight Refactoring Plan: Add segment-boundary check to _replace_path_part endswith

- **Target Area**: database.py
- **Priority**: Medium
- **Created**: 2026-04-09
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Debt Item**: TD179
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD179 — Add segment-boundary check to _replace_path_part endswith

**Scope**: `_replace_path_part()` in `linkwatcher/database.py:501` uses `endswith()` for partial path matching without verifying the character before the match is a `/` or the match starts at position 0. This could cause false matches across path boundaries (e.g., `my-docs/readme.md` matching `docs/readme.md`). Fix: add a segment-boundary guard before accepting the `endswith` match.

**Changes Made**:
- [x] Added segment-boundary check to `_replace_path_part` endswith branch (`database.py:504-506`)
- [x] Added 6 characterization tests in `TestReplacePathPart` class (`test_database.py`)

**Test Baseline**: 751 passed, 5 skipped, 4 deselected, 4 xfailed, 0 failures
**Test Result**: 757 passed (+6 new), 5 skipped, 4 deselected, 4 xfailed, 0 failures. No regressions.

**Documentation & State Updates**:
- [x] Feature implementation state file (0.1.2) updated, or N/A — _Grepped state file for `_replace_path_part` and `endswith` — no references found_
- [x] TDD (0.1.2) updated, or N/A — _Grepped TDD for `_replace_path_part` — no references; internal guard addition, no interface change_
- [x] Test spec (0.1.2) updated, or N/A — _Grepped test specs — no references to `_replace_path_part`_
- [x] FDD (0.1.2) updated, or N/A — _No FDD exists for feature 0.1.2 (Database is infrastructure)_
- [x] ADR (0.1.2) updated, or N/A — _Grepped ADR directory — no references to `_replace_path_part`_
- [x] Validation tracking updated, or N/A — _R4-AC-L03 in validation-tracking-4.md references TD179; will be resolved when TD is marked resolved_
- [x] Technical Debt Tracking: TD179 marked resolved via Update-TechDebt.ps1

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD179 | Complete | None | None (all N/A) |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
