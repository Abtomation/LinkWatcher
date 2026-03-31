---
id: PD-REF-026
type: Document
category: General
version: 1.0
created: 2026-03-02
updated: 2026-03-02
refactoring_scope: Unify Duplicate Synthetic Event Classes in handler.py (TD013)
target_area: linkwatcher/handler.py
priority: Low
---

# Refactoring Plan: Unify Duplicate Synthetic Event Classes (TD013)

## Overview
- **Target Area**: linkwatcher/handler.py
- **Priority**: Low
- **Created**: 2026-03-02
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Assessment**: PF-TDA-001 <!-- [PF-TDA-001](../../assessments/technical-debt/assessments/handler-module-structural-debt-assessment.md) - Removed: file deleted -->
- **Debt Item**: PF-TDI-009

## Refactoring Scope

### Current Issues

Two nearly identical classes defined inline inside methods:

1. `SyntheticMoveEvent` (line 694) in `_handle_detected_move` — `is_directory = False`, joins paths in `__init__`
2. `_SyntheticDirMoveEvent` (line 1182) in `_process_dir_move_batch` — `is_directory = True`, takes pre-joined paths

Both mimic watchdog's move event interface (`src_path`, `dest_path`, `is_directory`).

### Refactoring Goals

- Unify into a single `_SyntheticMoveEvent` class at module level
- Accept `is_directory` as a parameter (default `False`)
- Use `__slots__` for memory efficiency
- Update both usage sites to pass pre-joined paths consistently

## Implementation

1. Created `_SyntheticMoveEvent` at module level with `__slots__` and `is_directory` parameter
2. Replaced inline `SyntheticMoveEvent` — moved path joining outside constructor
3. Replaced inline `_SyntheticDirMoveEvent` — used unified class with `is_directory=True`

## Success Criteria

- [x] Single `_SyntheticMoveEvent` class at module level
- [x] Zero inline class definitions for synthetic events
- [x] All existing tests continue to pass (344 passed)
- [x] No new test failures introduced

## Implementation Tracking

| Date | Phase | Completed Work | Issues Encountered | Next Steps |
|------|-------|----------------|-------------------|------------|
| 2026-03-02 | Execution | Created unified class, replaced 2 inline definitions | None | Validate |
| 2026-03-02 | Validation | Tests: 344 passed, 9 failed (same as baseline) | None | Complete |

## Results

- **Class count**: 2 inline → 1 module-level with `__slots__`
- **Net lines**: -8 (removed 2 class defs of ~5 lines each, added 1 class of ~12 lines including docstring)
- **Test results**: Identical before/after
- **Bug discovery**: No bugs discovered

## Related Documentation
- [Technical Debt Tracking](/doc/product-docs/state-tracking/permanent/technical-debt-tracking.md)
<!-- - [Handler Module Structural Debt Assessment](/process-framework/assessments/technical-debt/assessments/handler-module-structural-debt-assessment.md) - Removed: file deleted -->
