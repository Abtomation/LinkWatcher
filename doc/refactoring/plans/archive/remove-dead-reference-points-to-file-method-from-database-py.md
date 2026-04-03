---
id: PD-REF-147
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-02
updated: 2026-04-02
refactoring_scope: Remove dead _reference_points_to_file method from database.py
target_area: linkwatcher/database.py
priority: Medium
mode: lightweight
---

# Lightweight Refactoring Plan: Remove dead _reference_points_to_file method from database.py

- **Target Area**: linkwatcher/database.py
- **Priority**: Medium
- **Created**: 2026-04-02
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD150 — Remove dead `_reference_points_to_file` method

**Scope**: Remove `_reference_points_to_file()` (database.py:408-477, ~70 LOC) which is no longer called from any production code after `get_references_to_file()` was optimized to use index-based lookups with inline suffix matching. Also remove the two test methods that directly test this private method (`test_reference_points_to_file` and `test_relative_path_resolution` in test_database.py:155-176). Update the comment at line 363 that references the removed method.

**Dims**: AC (Architectural Consistency) — dead code removal.

**Changes Made**:
- [x] Remove `_reference_points_to_file()` method from database.py (lines 408-477)
- [x] Update comment at database.py:363 to remove method name reference
- [x] Update comment at test_database.py:409 to remove method name reference
- [x] Remove `test_reference_points_to_file` test (test_database.py:155-166)
- [x] Remove `test_relative_path_resolution` test (test_database.py:168-176)

**Test Baseline**: 656 passed, 5 skipped, 6 xfailed
**Test Result**: 654 passed, 5 skipped, 6 xfailed (656 - 2 removed tests = 654, no regressions)

**Documentation & State Updates**:
- [x] Feature implementation state file (0.1.2) updated, or N/A — _Grepped state file for `_reference_points_to_file` — no references found_
- [x] TDD (0.1.2) updated — _Removed method name from performance implementation section (line 399)_
- [x] Test spec (0.1.2) updated — _Removed two test rows for deleted tests (test_reference_points_to_file, test_relative_path_resolution)_
- [x] FDD (0.1.2) updated, or N/A — _Grepped FDD directory — no references found_
- [x] ADR updated, or N/A — _Grepped ADR directory — no references found_
- [x] Validation tracking updated, or N/A — _Dead code removal doesn't affect validation results; tracked via TD resolution_
- [x] Technical Debt Tracking: TD150 marked resolved via Update-TechDebt.ps1

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD150 | Complete | None | TDD 0.1.2, Test Spec 0.1.2 |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)

