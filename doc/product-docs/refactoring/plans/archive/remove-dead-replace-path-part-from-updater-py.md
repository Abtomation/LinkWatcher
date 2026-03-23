---
id: PF-REF-041
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-03
updated: 2026-03-03
priority: Medium
mode: lightweight
target_area: LinkUpdater
refactoring_scope: Remove dead _replace_path_part from updater.py
---

# Lightweight Refactoring Plan: Remove dead _replace_path_part from updater.py

- **Target Area**: LinkUpdater
- **Priority**: Medium
- **Created**: 2026-03-03
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (≤15 min effort, single file, no architectural impact)

## Item 1: TD027 — Remove dead `_replace_path_part()` from updater.py

**Scope**: Remove the `_replace_path_part()` method (lines 443-457) from `linkwatcher/updater.py` — it was included in the original commit but never called. The updater uses `_calculate_new_target_relative()` instead. Also remove 3 associated dead tests from `tests/unit/test_updater.py` and update test-spec-2-2-1.

**Changes Made**:
- [x] Removed `_replace_path_part()` method from `linkwatcher/updater.py` (was lines 443-457, 15 lines)
- [x] Removed 3 test methods from `tests/unit/test_updater.py` (was lines 136-159): `test_replace_path_part_exact_match`, `test_replace_path_part_partial_match`, `test_replace_path_part_no_match`
- [x] Updated test spec `test-spec-2-2-1-link-updating.md` — removed 3 test case rows

**Test Baseline**: 389 passed, 5 skipped, 7 xfailed
**Test Result**: 386 passed, 5 skipped, 7 xfailed (3 removed tests account for difference)

**Documentation & State Updates**:
- [x] Feature implementation state file — N/A (no reference to this method)
- [x] TDD updated — N/A (no interface/design change)
- [x] Test spec updated — removed 3 rows from test-spec-2-2-1-link-updating.md
- [x] FDD updated — N/A (no functional change)
- [x] Technical Debt Tracking: TD027 marked resolved via Update-TechDebt.ps1

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD027 | Complete | None | test-spec-2-2-1 |

## Related Documentation
- [Technical Debt Tracking](/doc/product-docs/state-tracking/permanent/technical-debt-tracking.md)
