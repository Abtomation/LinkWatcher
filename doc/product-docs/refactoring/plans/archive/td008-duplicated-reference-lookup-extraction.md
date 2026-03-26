---
id: PD-REF-021
type: Document
category: General
version: 1.0
created: 2026-03-02
updated: 2026-03-02
target_area: linkwatcher/handler.py
priority: High
refactoring_scope: TD008 Duplicated Reference Lookup Extraction
---

# Refactoring Plan: TD008 Duplicated Reference Lookup Extraction

## Overview
- **Target Area**: linkwatcher/handler.py
- **Priority**: High
- **Created**: 2026-03-02
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Tech Debt Item**: TD008 (PF-TDI-004)
- **Assessment**: PF-TDA-001 <!-- [PF-TDA-001](/doc/process-framework/assessments/technical-debt/assessments/handler-module-structural-debt-assessment.md) - Removed: file deleted -->

## Refactoring Scope

### Current Issues
- **Duplicated reference lookup**: The "try multiple path formats" pattern (exact → relative → backslash → filename) is repeated 3 times within `_handle_file_moved` spanning ~150 lines of near-identical logic
- **Duplicated deduplication**: Reference deduplication logic (seen-set pattern) appears twice in the same method
- **Inconsistent format coverage**: The stale retry lookup (3rd instance) skips the backslash variation — likely a bug or oversight

### Three Duplication Sites

| # | Lines | Purpose | Formats Tried |
|---|-------|---------|---------------|
| 1 | 209-263 | Initial reference discovery | exact, relative, backslash, filename |
| 2 | 276-303 | Path update collection | exact, relative, backslash, filename |
| 3 | 335-351 | Stale retry lookup | exact, relative, filename (missing backslash) |

### Refactoring Goals
- Extract a single `_get_path_variations` helper that generates all path format variations from a given path
- Extract `_find_references_multi_format` that uses path variations to query the database and deduplicate
- Extract `_collect_path_updates` that builds the (old, new) path tuple list for database cleanup
- Reduce `_handle_file_moved` line count by ~100 lines
- Ensure consistent path format coverage across all three call sites

## Current State Analysis

### Code Quality Metrics (Baseline)
- **`_handle_file_moved` length**: ~270 lines (197-456)
- **Handler total lines**: 1,409
- **Duplicated lines (TD008)**: ~150 lines across 3 sites
- **Test suite**: 344 passed, 9 pre-existing failures, 4 skipped

### Affected Components
- `linkwatcher/handler.py` — the only file modified (all 3 duplication sites are internal)

### Dependencies and Impact
- **Internal Dependencies**: `_handle_file_moved` is called from `on_moved` event handler and `_process_pending_dir_move`
- **External Dependencies**: None — this is an internal method refactoring
- **Risk Assessment**: Low — extracting private helper methods does not change any public API

## Refactoring Strategy

### Approach
Extract Method refactoring — pull the duplicated path-format logic into private helper methods on the same class. No new files or classes needed. The helpers stay within `LinkMaintenanceHandler` since they're tightly coupled to `self.link_db` and `self.logger`.

### Specific Techniques
- **Extract Method**: Create `_get_path_variations(path)` returning a list of path format strings
- **Extract Method**: Create `_find_references_multi_format(target_path, filter_files=None)` combining lookup + dedup
- **Extract Method**: Create `_collect_path_updates(old_path, new_path)` for the path update list
- **Replace duplicated code**: Substitute all 3 sites with calls to the new helpers

### Implementation Plan

1. **Phase 1**: Extract `_get_path_variations(path)` helper
   - Step 1.1: Create helper method that generates [exact, relative, backslash, filename] variations
   - Step 1.2: Run tests to verify no regressions

2. **Phase 2**: Extract `_find_references_multi_format(target_path, filter_files=None)` helper
   - Step 2.1: Create helper using `_get_path_variations` + dedup logic
   - Step 2.2: Replace duplication site 1 (lines 209-264) with helper call
   - Step 2.3: Replace duplication site 3 (lines 335-359) with helper call (with filter_files param)
   - Step 2.4: Run tests

3. **Phase 3**: Extract `_collect_path_updates(old_path, new_path)` helper
   - Step 3.1: Create helper using `_get_path_variations` to build path update tuples
   - Step 3.2: Replace duplication site 2 (lines 276-303) with helper call
   - Step 3.3: Run tests

## Testing Strategy

### Existing Test Coverage
- **15 test files** reference `_handle_file_moved` or `get_references_to_file`
- **Key integration tests**: `test_link_updates.py`, `test_file_movement.py`, `test_sequential_moves.py`
- **Pre-existing failures**: 9 tests fail before refactoring (unrelated to TD008)

### Testing Approach During Refactoring
- **Regression Testing**: Run full test suite after each phase
- **Incremental Testing**: Run handler-specific tests after each helper extraction
- **Behavior Preservation**: All 344 passing tests must continue to pass

## Success Criteria

### Quality Improvements
- **Line Reduction**: ~100 fewer lines in `_handle_file_moved`
- **Duplication Elimination**: 3 sites → 1 implementation
- **Consistency**: All lookup sites use the same path format coverage (fix missing backslash in stale retry)

### Functional Requirements
- [x] All existing functionality preserved
- [x] No breaking changes to public APIs
- [x] All 344 currently-passing tests continue to pass
- [x] Performance maintained (no additional database queries beyond current behavior)

## Implementation Tracking

### Progress Log
| Date | Phase | Completed Work | Issues Encountered | Next Steps |
|------|-------|----------------|-------------------|------------|
| 2026-03-02 | Planning | Analysis complete, plan drafted | None | Await approval |
| 2026-03-02 | Phase 1-3 | All 3 helpers extracted, all 3 sites replaced | None | State updates |

### Metrics Tracking
| Metric | Baseline | Current | Target | Status |
|--------|----------|---------|--------|--------|
| `_handle_file_moved` lines | ~270 | ~168 | ~170 | Exceeded |
| Duplication sites | 3 | 0 | 0 | Complete |
| Passing tests | 344 | 344 | 344 | Verified |

## Results and Lessons Learned

### Final Metrics
- **`_handle_file_moved` length**: ~168 lines (Change: -102 lines, -38%)
- **Handler total lines**: 1,372 (Change: -37 net, with 65 lines of helpers added)
- **Duplication**: 0 sites (Change: eliminated all 3)
- **Test suite**: 344 passed, same 9 pre-existing failures — no regressions

### Achievements
- Eliminated all 3 duplication sites with 3 focused helper methods
- Fixed inconsistency where stale retry missed Windows backslash path variation
- Made `_handle_file_moved` significantly more readable

### Challenges and Solutions
- No challenges encountered — the duplication sites were well-bounded and the extraction was straightforward

### Lessons Learned
- The `_collect_path_updates` method needs to generate paired old/new variations, so it can't simply reuse `_get_path_variations` directly (different return shape). Keeping a small amount of variation logic in both methods is acceptable since the alternative (a complex pair-returning API) would be over-engineered.

### Remaining Technical Debt
- TD005 (God Class) — this refactoring reduces it slightly but the fundamental issue remains
- TD007 (Mega Method) — this refactoring is a prerequisite step toward decomposing `_handle_file_moved`

## Related Documentation
- [Technical Debt Tracking](/doc/product-docs/state-tracking/permanent/technical-debt-tracking.md)
<!-- - [PF-TDA-001 Assessment](/doc/process-framework/assessments/technical-debt/assessments/handler-module-structural-debt-assessment.md) - Removed: file deleted -->
