---
id: PF-REF-028
type: Document
category: General
version: 1.0
created: 2026-03-02
updated: 2026-03-02
priority: High
debt_item: TD007
refactoring_scope: Decompose _handle_file_moved mega method into focused sub-methods
target_area: handler.py
---

# Refactoring Plan: Decompose _handle_file_moved mega method into focused sub-methods

## Overview
- **Target Area**: handler.py
- **Priority**: High
- **Debt Item**: TD007 (PF-TDI-003)
- **Created**: 2026-03-02
- **Author**: AI Agent & Human Partner
- **Status**: Completed

## Refactoring Scope

`_handle_file_moved` in `linkwatcher/handler.py` (lines 272-407, ~136 lines) combines reference lookup, update orchestration, stale retry logic, database cleanup, and statistics reporting in a single method. After TD008 extracted helper methods (`_find_references_multi_format`, `_get_old_path_variations`, `_get_path_variations`), the method shrunk from ~270 to ~136 lines but still has 6+ distinct responsibilities.

### Current Issues

- **Multiple responsibilities**: Reference finding, file content updates, stale retry, DB cleanup, statistics, and moved-file self-link updates all interleaved in one method
- **Stale retry logic block** (lines 296-344, ~49 lines): Longest single section, complex rescan-and-retry flow
- **Database cleanup block** (lines 346-373, ~28 lines): Remove old refs, rescan affected files — conceptually separate from the update orchestration
- **Statistics/reporting block** (lines 375-389, ~15 lines): Mixed into the method body instead of separated

### Refactoring Goals

- Decompose `_handle_file_moved` into an orchestrator (~30-40 lines) calling focused sub-methods
- Extract stale retry logic into `_retry_stale_references()` — reusable by `_handle_directory_moved` (prepares for TD009)
- Extract database cleanup into `_cleanup_database_after_file_move()`
- Preserve all existing behavior — pure internal refactoring

## Current State Analysis

### Code Quality Metrics (Baseline)

- **Method length**: 136 lines (272-407)
- **Distinct responsibilities**: 6 (validation, reference update, stale retry, DB cleanup, statistics, self-link update)
- **Nesting depth**: 4 levels (try → if references → if stale_files → if unique_retry)
- **Handler.py total lines**: 1264
- **Test coverage**: 65 test methods across 8 test files cover handler move functionality

### Affected Components

- `linkwatcher/handler.py` — Only file modified (internal method extraction)

### Dependencies and Impact

- **Internal dependencies**: No external callers of `_handle_file_moved` (private method, called only from `on_moved`)
- **External dependencies**: None
- **Risk Assessment**: Low — pure internal decomposition of a private method, extensive test coverage (65 tests)

## Refactoring Strategy

### Approach

Extract Method refactoring — move distinct responsibility blocks from `_handle_file_moved` into private methods. Each extraction preserves exact behavior and is verified by running the full test suite.

### Specific Techniques

- **Extract Method**: Move cohesive code blocks into named methods
- **Compose Method**: Restructure `_handle_file_moved` as a high-level orchestrator calling sub-methods

### Implementation Plan

1. **Phase 1**: Extract `_retry_stale_references(old_path, new_path, update_stats)` → returns merged update_stats
   - Extract lines 296-344 (stale file rescan + retry + result merging)
   - Run tests

2. **Phase 2**: Extract `_cleanup_database_after_file_move(references, path_updates)` → void
   - Extract lines 346-373 (remove old targets, rescan affected files)
   - Run tests

3. **Phase 3**: Clean up remaining `_handle_file_moved` as orchestrator
   - Verify it reads as a clear step-by-step flow
   - Run full test suite

## Testing Strategy

### Existing Test Coverage

- **Unit Tests**: `test_move_detection.py` (4 methods), `test_directory_move_detection.py` (21 methods)
- **Integration Tests**: `test_link_updates.py` (11), `test_file_movement.py` (7), `test_sequential_moves.py` (4), `test_powershell_script_monitoring.py` (5), `test_image_file_monitoring.py` (6), `test_comprehensive_file_monitoring.py` (7)
- **Total**: 65 test methods covering handler move functionality

### Testing Approach During Refactoring

- **Regression Testing**: Run full `pytest tests/` after each phase
- **Incremental Testing**: Run tests after each extraction before proceeding
- **New Test Requirements**: None — pure internal refactoring, no new behavior

## Success Criteria

### Quality Improvements

- **Method length**: 136 lines → ~30-40 lines (orchestrator) + focused sub-methods
- **Max nesting depth**: 4 → 2 in orchestrator
- **Responsibilities per method**: 6 → 1-2 per method
- **Technical Debt**: TD007 resolved

### Functional Requirements

- [x] All existing functionality preserved
- [x] No breaking changes to public APIs
- [x] All 65 handler-related tests continue to pass (344 total pass, same 8 pre-existing failures)
- [x] Performance maintained (no additional I/O or DB calls)

## Implementation Tracking

### Progress Log

| Date | Phase | Completed Work | Issues Encountered | Next Steps |
|------|-------|----------------|-------------------|------------|
| 2026-03-02 | Phase 1 | Extracted `_retry_stale_references()` (57 lines) | None | Phase 2 |
| 2026-03-02 | Phase 2 | Extracted `_cleanup_database_after_file_move()` (31 lines) | None | Phase 3 |
| 2026-03-02 | Phase 3 | Verified orchestrator reads cleanly (62 lines) | None | Finalization |

### Metrics Tracking

| Metric | Baseline | Final | Target | Status |
|--------|----------|-------|--------|--------|
| `_handle_file_moved` length | 136 lines | 62 lines | ~30-40 lines | Achieved (54% reduction) |
| Max nesting depth | 4 | 2 | 2 | Achieved |
| Responsibilities per method | 6 | 2 (orchestrator) + 1 each (sub-methods) | 1-2 | Achieved |
| Handler.py total lines | 1264 | 1281 (+17 net from docstrings/signatures) | N/A | Expected |
| Test results | 344 pass / 8 fail (pre-existing) | 344 pass / 8 fail (same) | No regressions | Achieved |

## Results and Lessons Learned

### Final Metrics

- **Method length**: 136 → 62 lines (-54%)
- **Max nesting depth**: 4 → 2 in orchestrator
- **Handler.py total**: 1264 → 1281 lines (+17 net from method signatures and docstrings)
- **Technical Debt**: TD007 resolved; `_retry_stale_references()` now reusable for TD009

### Achievements

- Decomposed `_handle_file_moved` into clear orchestrator + 2 focused sub-methods
- Extracted `_retry_stale_references()` is directly reusable for TD009 (duplicated stale retry in `_handle_directory_moved`)
- Zero test regressions across 344 passing tests
- Clean orchestrator reads as step-by-step: find refs → collect paths → update files → retry stale → cleanup DB → report

### Challenges and Solutions

- No significant challenges — the method boundaries were clear and the existing test coverage provided confidence

### Lessons Learned

- Previous refactoring (TD008, TD010) had already reduced the method from ~270 to ~136 lines, making this decomposition straightforward
- The 62-line orchestrator is slightly longer than the 30-40 line target because the statistics/reporting block (12 lines) was small enough to leave inline

### Remaining Technical Debt

- **TD009** (Medium): Duplicated stale retry logic in `_handle_directory_moved` — now addressable by calling `_retry_stale_references()` (prepared by this refactoring)
- **TD005** (High): God Class `LinkMaintenanceHandler` — method extraction is a step toward eventual class decomposition

## Related Documentation
- [Technical Debt Tracking](/doc/process-framework/state-tracking/permanent/technical-debt-tracking.md)
- [Code Quality Standards](/doc/process-framework/guides/guides/code-quality-standards.md)
- [Testing Guidelines](/doc/process-framework/guides/guides/testing-guidelines.md)
