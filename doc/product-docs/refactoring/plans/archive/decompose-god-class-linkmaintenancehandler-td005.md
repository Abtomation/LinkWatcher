---
id: PD-REF-029
type: Document
category: General
version: 1.0
created: 2026-03-02
updated: 2026-03-02
refactoring_scope: Decompose God Class LinkMaintenanceHandler (TD005)
priority: High
target_area: linkwatcher/handler.py
debt_item: TD005 (PF-TDI-001)
assessment: PF-TDA-001
---

# Refactoring Plan: Decompose God Class LinkMaintenanceHandler (TD005)

## Overview
- **Target Area**: linkwatcher/handler.py
- **Priority**: High
- **Created**: 2026-03-02
- **Author**: AI Agent & Human Partner
- **Status**: Completed
- **Debt Item**: TD005 / PF-TDI-001
- **Assessment**: PF-TDA-001 <!-- [PF-TDA-001](/doc/process-framework/assessments/technical-debt/assessments/handler-module-structural-debt-assessment.md) - Removed: file deleted -->

## Refactoring Scope

Extract two self-contained state machine classes from `LinkMaintenanceHandler` to eliminate the God Class anti-pattern. After Phases 1-2 of the assessment's remediation plan were completed (TDI-002 through TDI-010), this is Phase 3: Module Extraction.

### Current Issues
- **God Class**: `LinkMaintenanceHandler` has 10+ responsibilities in 1281 lines, making every change high-risk
- **Tangled state**: Per-file move detection state (`pending_deletes`, timers, lock) and directory move detection state (`pending_dir_moves`, timers, lock) are mixed into the same class
- **Cascading bug risk**: Bug history confirms handler.py changes introduce new bugs (BUG-019 fix → BUG-020)
- **TD009**: Duplicated stale retry logic between file and directory moves (~90 lines)

### Refactoring Goals
- Extract `MoveDetector` class into `linkwatcher/move_detector.py` (per-file move detection via delete+create correlation)
- Extract `DirectoryMoveDetector` class into `linkwatcher/dir_move_detector.py` (batch directory move detection with 3-phase approach)
- Slim `LinkMaintenanceHandler` to event dispatch + move/update orchestration
- Resolve TD009 (duplicated stale retry) as part of directory move extraction

## Current State Analysis

### Code Quality Metrics (Baseline)
- **File size**: 1281 lines (handler.py)
- **Class methods**: 30+ methods in one class
- **Largest method**: `_update_links_within_moved_file` at 127 lines
- **Test suite**: 344 passed, 9 failed (pre-existing), 4 skipped, 21 xfailed
- **Handler-specific tests**: 36 tests, all passing
- **Open TD items in handler.py**: TD005, TD009, TD015, TD016, TD017, TD018

### Method Inventory

| Responsibility Group | Methods | Lines | Target Module |
|---|---|---|---|
| Event dispatch | `on_moved`, `on_deleted`, `on_created`, `on_error` | ~62 | handler.py |
| Constructor + config | `__init__` | ~53 | handler.py (slimmed) |
| Reference lookup | `_get_path_variations`, `_find_references_multi_format`, `_get_old_path_variations` | ~61 | handler.py |
| File move handling | `_handle_file_moved`, `_retry_stale_references`, `_cleanup_database_after_file_move` | ~152 | handler.py |
| Directory move handling | `_handle_directory_moved` | ~99 | handler.py |
| File scanning | `_rescan_file_links`, `_rescan_moved_file_links` | ~50 | handler.py |
| Links within moved file | `_update_links_within_moved_file`, `_calculate_updated_relative_path` | ~162 | handler.py |
| File creation routing | `_handle_file_created` | ~32 | handler.py |
| **Per-file move detection** | `_handle_file_deleted`, `_process_delayed_delete`, `_detect_potential_move`, `_handle_detected_move` | **~152** | **move_detector.py** |
| **Dir move detection** | `_handle_directory_deleted`, `_match_dir_move_file`, `_reset_dir_move_settle_timer`, `_trigger_dir_move_processing`, `_process_dir_move_settled`, `_process_dir_move_timeout`, `_process_dir_move`, `_resolve_unmatched_files`, `_process_dir_true_delete`, `_process_true_file_delete`, `_get_files_under_directory` | **~355** | **dir_move_detector.py** |
| Utilities | `_should_monitor_file`, `_get_relative_path`, `get_stats`, `reset_stats` | ~16 | handler.py |

### Affected Components
- `linkwatcher/handler.py` - Primary target, will be decomposed
- `linkwatcher/move_detector.py` - New file (per-file move detection)
- `linkwatcher/dir_move_detector.py` - New file (directory move detection)
- `linkwatcher/service.py` - May need import updates if it references handler internals
- `tests/test_move_detection.py` - May need import updates
- `tests/test_directory_move_detection.py` - May need import updates

### Dependencies and Impact
- **Internal Dependencies**: `service.py` creates and uses `LinkMaintenanceHandler`; test files import handler components
- **External Dependencies**: None — watchdog event model is consumed, not extended
- **Risk Assessment**: Medium — many tests cover behavior but internal coupling between detection and handling requires careful callback design

## Refactoring Strategy

### Approach
**Extract Class** refactoring: Move self-contained state machines into their own classes with callback-based communication back to the handler. The handler delegates detection to the extracted classes and receives callbacks when moves/deletes are confirmed.

### Specific Techniques
- **Extract Class**: Move state + methods for file move detection and directory move detection into separate classes
- **Callback pattern**: Each detector takes callback functions in its constructor for `on_move_detected` and `on_true_delete` events
- **Preserve interface**: `LinkMaintenanceHandler` keeps its `FileSystemEventHandler` interface unchanged — external code sees no change

### Implementation Plan

1. **Phase 3A**: Extract `MoveDetector` (~150 lines)
   - Create `linkwatcher/move_detector.py` with `MoveDetector` class
   - Move `pending_deletes`, `move_detection_delay`, `move_detection_lock` state
   - Move `_handle_file_deleted`, `_process_delayed_delete`, `_detect_potential_move`, `_handle_detected_move`
   - Handler delegates `on_deleted` (non-directory) and `on_created` (move matching) to `MoveDetector`
   - MoveDetector calls back to handler via callbacks for confirmed moves and true deletes
   - Run all tests to verify

2. **Phase 3B**: Extract `DirectoryMoveDetector` (~355 lines)
   - Create `linkwatcher/dir_move_detector.py` with `DirectoryMoveDetector` class
   - Move `_PendingDirMove`, `pending_dir_moves`, `dir_move_lock`, timer settings
   - Move all `_match_dir_move_file`, `_handle_directory_deleted`, `_reset_dir_move_settle_timer`, `_trigger_dir_move_processing`, `_process_dir_move_settled`, `_process_dir_move_timeout`, `_process_dir_move`, `_resolve_unmatched_files`, `_process_dir_true_delete`, `_process_true_file_delete`, `_get_files_under_directory`
   - Handler delegates directory deletion events and file creation matching to `DirectoryMoveDetector`
   - DirectoryMoveDetector calls back for confirmed dir moves and true deletes
   - Inline the duplicated stale retry logic from `_handle_directory_moved` → resolve TD009
   - Run all tests to verify

3. **Phase 3C**: Cleanup and documentation
   - Update handler.py `__init__` to instantiate detectors
   - Verify handler.py is slimmed to ~720 lines
   - Update any imports in service.py or tests
   - Update documentation

## Testing Strategy

### Existing Test Coverage
- **Handler-specific tests**: 36 tests in `tests/test_move_detection.py`, `tests/test_directory_move_detection.py`, `tests/integration/test_file_movement.py`, `tests/integration/test_sequential_moves.py` — all passing
- **Full suite**: 344 passing, 9 pre-existing failures (unrelated to handler)
- **Coverage areas**: File moves, directory moves, sequential moves, error handling, complex scenarios

### Testing Approach During Refactoring
- **Regression Testing**: Run full test suite after each phase to ensure 344 tests still pass
- **Incremental Testing**: Run handler-specific 36 tests after each method extraction
- **New Test Requirements**: None — this is a pure refactoring with no behavior change. Existing tests validate behavior preservation.

## Success Criteria

### Quality Improvements
- **File size**: handler.py from 1281 lines → ~720 lines (~44% reduction)
- **Responsibility count**: From 10+ → ~6 (event dispatch, orchestration, reference lookup, file scanning, move handling, link updates)
- **New modules**: 2 focused classes with single responsibilities
- **TD resolution**: TD005 resolved, TD009 resolved as part of Phase 3B

### Functional Requirements
- [x] All existing functionality preserved
- [x] No breaking changes to public APIs (`LinkMaintenanceHandler` interface unchanged)
- [x] All existing tests continue to pass (344 passed baseline)
- [x] Performance maintained (no additional overhead from delegation)

## Implementation Tracking

### Progress Log
| Date | Phase | Completed Work | Issues Encountered | Next Steps |
|------|-------|----------------|-------------------|------------|
| 2026-03-02 | Analysis | Current state analysis, test baseline, plan creation | None | Strategy approval, begin Phase 3A |
| 2026-03-02 | Phase 3A | Extracted MoveDetector (99 lines) into move_detector.py | 5 test failures from direct attribute access — fixed by updating tests | Phase 3B |
| 2026-03-02 | Phase 3B | Extracted DirectoryMoveDetector (409 lines) into dir_move_detector.py | Test references to handler.pending_dir_moves needed updating | Phase 3C |
| 2026-03-02 | Phase 3C | Cleanup: removed unused imports (time, threading, normalize_path), resolved TD009 (duplicated stale retry) | None | Finalization |

### Metrics Tracking
| Metric | Baseline | Current | Target | Status |
|--------|----------|---------|--------|--------|
| handler.py lines | 1281 | 839 | ~720 | Complete (34.5% reduction) |
| Class responsibilities | 10+ | ~6 | ~6 | Complete |
| Handler-specific tests passing | 36/36 | 36/36 | 36/36 | Complete |
| Full suite passing | 344 | 344 | 344 | Complete |
| TD items resolved | 0 | 2 | 2 (TD005, TD009) | Complete |

## Results and Lessons Learned

### Final Metrics
- **handler.py**: 1281 → 839 lines (34.5% reduction)
- **New modules**: move_detector.py (99 lines), dir_move_detector.py (409 lines)
- **Total code**: 1347 lines across 3 files (slight increase due to class boilerplate, docstrings, and proper encapsulation)
- **All 344 tests passing**, 36/36 handler-specific tests passing
- **TD005 (God Class)** and **TD009 (Duplicated stale retry)** both resolved

### Achievements
- Decomposed 10+ responsibility God Class into 3 focused modules
- Handler now focuses on: event dispatch, orchestration, reference lookup, file scanning, move handling, link updates
- MoveDetector: self-contained per-file delete+create correlation state machine
- DirectoryMoveDetector: self-contained 3-phase batch directory move detection state machine
- Callback pattern keeps detectors decoupled from handler internals
- TD009 resolved by reusing `_retry_stale_references` in `_handle_directory_moved` instead of inline duplication

### Challenges and Solutions
- **Test coupling**: Tests directly accessed `handler.pending_deletes` and `handler.pending_dir_moves` — solved by updating test assertions to use `handler._move_detector._pending` and `handler._dir_move_detector.pending_dir_moves`
- **Callback design**: Chose callbacks over direct link_db access in MoveDetector to keep it decoupled. DirectoryMoveDetector needs link_db for `get_files_under_directory` queries, so it takes it as a constructor parameter.

### Lessons Learned
- Extract Class refactoring works well for self-contained state machines with clear boundaries
- Callback pattern provides good decoupling without excessive abstraction
- Test suites that access internal state need updating after refactoring — future tests should prefer testing through public APIs

### Remaining Technical Debt
TD015, TD016, TD017, TD018 remain open but are independent of this refactoring.

## Related Documentation
- [Technical Debt Tracking](/doc/product-docs/state-tracking/permanent/technical-debt-tracking.md)
<!-- - [Technical Debt Assessment PF-TDA-001](/doc/process-framework/assessments/technical-debt/assessments/handler-module-structural-debt-assessment.md) - Removed: file deleted -->
- [Previous refactoring: PF-REF-028 (Mega Method)](/doc/product-docs/refactoring/plans/archive/decompose-handle-file-moved-mega-method-into-focused-sub-methods.md)
