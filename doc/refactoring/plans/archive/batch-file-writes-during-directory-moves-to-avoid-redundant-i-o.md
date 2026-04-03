---
id: PD-REF-126
type: Document
category: General
version: 1.0
created: 2026-03-30
updated: 2026-03-30
target_area: handler.py / reference_lookup.py / updater.py
refactoring_scope: Batch file writes during directory moves to avoid redundant I/O
debt_item: TD129
priority: Medium
---

# Refactoring Plan: Batch file writes during directory moves to avoid redundant I/O

## Overview
- **Target Area**: handler.py / reference_lookup.py / updater.py
- **Priority**: Medium
- **Created**: 2026-03-30
- **Author**: AI Agent & Human Partner
- **Status**: Completed
- **Debt Item**: TD129

## Refactoring Scope

### Current Issues
- `_handle_directory_moved` in handler.py processes each moved file individually in a sequential loop, calling `updater.update_references()` per file. When the same referring file (e.g., documentation-map.md) references N files in the moved directory, it gets opened→modified→written N times instead of once.

### Scope Discovery
- **Original Tech Debt Description**: TD129 described the full pipeline (DB update, reference lookup, file updates, cleanup, rescan) as sequential per-file, suggesting a complete pipeline rework.
- **Actual Scope Findings**: DB source path updates (Phase 0) were already a separate pre-loop. Bulk rescan was already deferred via TD128. DB lookups are O(1) indexed. The dominant cost was redundant file I/O in the updater.
- **Scope Delta**: Narrower than original — only the file-write batching needed optimization, not the full pipeline.

### Refactoring Goals
- Eliminate redundant file I/O during directory moves by batching all reference updates per referring file into a single read→modify→write cycle
- Preserve all existing behavior: stale detection, Python module renames, atomic writes, backup creation

## Current State Analysis

### Affected Components
- `linkwatcher/updater.py` — Added `update_references_batch()` and `_update_file_references_multi()`
- `linkwatcher/reference_lookup.py` — Added `collect_directory_file_refs()`
- `linkwatcher/handler.py` — Restructured `_handle_directory_moved` loop into collect→batch-update→cleanup phases

### Dependencies and Impact
- **Internal Dependencies**: handler.py orchestrates the pipeline; reference_lookup.py and updater.py provide the building blocks
- **Risk Assessment**: Medium — the replacement logic in `_update_file_references_multi()` replicates `_update_file_references()` but handles multiple old→new pairs per file

## Refactoring Strategy

### Approach
Split the per-file `process_directory_file_move()` call into two phases: a collection phase that gathers all references without writing, and a batch-update phase that processes all file writes in a single pass per referring file.

### Implementation Plan
1. **Phase 1**: Add `collect_directory_file_refs()` to ReferenceLookup — returns references, module refs, and old targets without triggering writes
2. **Phase 2**: Add `update_references_batch()` and `_update_file_references_multi()` to LinkUpdater — groups all references by containing file and applies all replacements in one read→modify→write cycle
3. **Phase 3**: Restructure `_handle_directory_moved` in handler.py to use collect→batch-update→cleanup pipeline

## Testing Strategy

### Existing Test Coverage
- **Unit Tests**: 67 tests covering updater and reference_lookup (test_updater.py, test_reference_lookup.py)
- **Integration Tests**: 39 tests covering directory moves, sequential moves, file movement (test_directory_move_detection.py, test_file_movement.py, test_sequential_moves.py)
- **E2E Tests**: TE-E2G-005 covers directory move workflows (marked for re-execution)

### Testing Approach
- Full test suite (621 tests) run after implementation — all passed
- No new tests required — existing tests exercise the same code paths through the new batch pipeline

## Success Criteria

### Functional Requirements
- [x] All existing functionality preserved
- [x] No breaking changes to public APIs (existing `update_references()` unchanged)
- [x] All 621 existing tests continue to pass
- [x] Performance improved for directory moves with shared referring files

## Implementation Tracking

### Progress Log
| Date | Phase | Completed Work | Issues Encountered | Next Steps |
|------|-------|----------------|-------------------|------------|
| 2026-03-30 | All | Implemented batch pipeline: collect_directory_file_refs, update_references_batch, _update_file_references_multi, handler restructure | None | Finalization |

## Results and Lessons Learned

### Achievements
- Each referring file is now opened/written at most once during directory moves regardless of how many moved files it references
- Existing `update_references()` API preserved for single-move callers
- `process_directory_file_move()` preserved for non-batch callers
- Stale retry logic adapted to work with batch results

### Remaining Technical Debt
- `_update_file_references_multi()` and `_update_file_references()` share near-identical replacement logic — could be consolidated into a single method accepting `List[Tuple[ref, new_target]]`. Low priority since both are stable and well-tested.

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
