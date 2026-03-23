---
id: PF-REF-043
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-03
updated: 2026-03-03
refactoring_scope: Extract match strategies from _calculate_new_target_relative in updater.py
target_area: linkwatcher/updater.py
priority: Medium
mode: lightweight
---

# Lightweight Refactoring Plan: Extract match strategies from _calculate_new_target_relative in updater.py

- **Target Area**: linkwatcher/updater.py
- **Priority**: Medium
- **Created**: 2026-03-03
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (≤15 min effort, single file, no architectural impact)

## Item 1: TD032 — Extract match strategies from _calculate_new_target_relative

**Scope**: Extract 3 nested fallback match strategies from `_calculate_new_target_relative` (lines 248-301, ~54 lines of match logic) into focused helper methods: `_match_direct`, `_match_stripped`, `_match_resolved`. This reduces the method's cyclomatic complexity and nesting depth from 4-deep to 1-2 deep, improving readability without changing behavior.

**Changes Made**:
- [x] Extract direct path comparison into `_match_direct()` — 2-line method, returns bool
- [x] Extract stripped-slash comparison into `_match_stripped()` — 3-line method, handles /doc vs doc mismatches
- [x] Extract resolved path + filename-only fallback into `_match_resolved()` — 2 sub-strategies in focused method
- [x] Replace inline match logic in `_calculate_new_target_relative` with short-circuit `or` chain calling the 3 helpers

**Test Baseline**: 386 passed, 5 skipped, 7 xfailed, 15 warnings
**Test Result**: 386 passed, 5 skipped, 7 xfailed, 15 warnings (identical)

**Documentation & State Updates**:
- [x] Feature implementation state file updated — N/A (internal method extraction, no feature-level change)
- [x] TDD updated — N/A (no interface/design change)
- [x] Test spec updated — N/A (no behavior change)
- [x] FDD updated — N/A (no functional change)
- [x] Technical Debt Tracking: TD032 marked resolved via Update-TechDebt.ps1

**Bugs Discovered**: None

<!-- BATCH MODE: Copy the "## Item N" section above for each additional debt item in this session -->

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD032 | Complete | None | None (all N/A) |

## Related Documentation
- [Technical Debt Tracking](/doc/product-docs/state-tracking/permanent/technical-debt-tracking.md)
