---
id: PF-REF-046
type: Document
category: General
version: 1.0
created: 2026-03-03
updated: 2026-03-03
priority: Medium
refactoring_scope: Extract _update_links_within_moved_file and _handle_directory_moved from handler.py
target_area: linkwatcher/handler.py
---

# Refactoring Plan: Extract _update_links_within_moved_file and _handle_directory_moved from handler.py

## Overview
- **Target Area**: linkwatcher/handler.py
- **Priority**: Medium
- **Created**: 2026-03-03
- **Author**: AI Agent & Human Partner
- **Status**: Completed

## Refactoring Scope

Continuation of TD005 (God Class decomposition). Handler.py was reduced from 1409→839→681 LOC through prior extractions (move_detector.py, dir_move_detector.py, reference_lookup.py). Two large methods remain that violate SRP — they handle link content manipulation and directory move orchestration, responsibilities distinct from handler's core event dispatch role.

### Current Issues

- `_update_links_within_moved_file` (~147 LOC, lines 437-583) performs file I/O, link parsing, regex replacement, backup creation, and DB updates — mixing content manipulation with event handling
- `_calculate_updated_relative_path` (~35 LOC, lines 585-619) is a pure helper only used by `_update_links_within_moved_file` — should move with it
- `_handle_directory_moved` (~88 LOC, lines 259-346) orchestrates per-file reference updates for all files in a moved directory — duplicates logic from `_handle_file_moved` but with directory-level iteration

### Refactoring Goals

- Reduce handler.py from 681 to ~410 LOC by extracting ~270 LOC
- Improve SRP: handler focuses on event dispatch, not content manipulation
- Follow established extraction patterns (move_detector.py, dir_move_detector.py, reference_lookup.py)

## Current State Analysis

### Code Quality Metrics (Baseline)

- **Handler LOC**: 681 lines, 22 methods
- **Test Suite**: 386 passed, 5 skipped, 7 xfailed
- **Technical Debt**: TD035 (Medium priority, Medium effort)

### Affected Components

- `linkwatcher/handler.py` — Source: extract methods out
- `linkwatcher/reference_lookup.py` (256 LOC) — Destination for `_handle_directory_moved` logic (already handles reference lookup + DB cleanup for file moves)
- New or existing module — Destination for `_update_links_within_moved_file` + `_calculate_updated_relative_path`

### Dependencies and Impact

- **Internal Dependencies**: `_handle_file_moved` calls `_update_links_within_moved_file`; `on_moved` and `_handle_confirmed_dir_move` call `_handle_directory_moved`
- **External Dependencies**: None
- **Risk Assessment**: Medium — methods contain bug fixes (PD-BUG-008, PD-BUG-010, PD-BUG-025) that must be preserved exactly

## Refactoring Strategy

### Approach

Extend `ReferenceLookup` with both extracted methods. ReferenceLookup already holds all required dependencies (parser, updater, link_db, logger, project_root) and conceptually owns "reference management after file moves." This avoids creating a new module and follows the existing dependency graph.

Handler retains event dispatch + directory walking (its core orchestration role) but delegates the heavy per-file processing logic to ReferenceLookup.

### Specific Techniques

- **Extract Method → Move Method**: Move `_update_links_within_moved_file` + `_calculate_updated_relative_path` to ReferenceLookup as `update_links_within_moved_file()` and `_calculate_updated_relative_path()`
- **Extract Method → Move Method**: Move the per-file processing loop from `_handle_directory_moved` to ReferenceLookup as `process_directory_file_move()`, keeping directory walking in handler
- **Dependency injection for handler-specific config**: Pass `should_monitor_file` function and `ignored_dirs` as parameters to ReferenceLookup methods that need them, rather than adding handler config to ReferenceLookup's constructor

### Implementation Plan

1. **Phase 1**: Extract `_update_links_within_moved_file` + `_calculate_updated_relative_path`
   - Step 1.1: Add `update_links_within_moved_file()` and `_calculate_updated_relative_path()` to ReferenceLookup, accepting `backup_enabled` as parameter (from updater)
   - Step 1.2: Update handler to delegate to `self._ref_lookup.update_links_within_moved_file()`
   - Step 1.3: Run tests — verify all 386 pass

2. **Phase 2**: Extract `_handle_directory_moved` per-file loop
   - Step 2.1: Add `process_directory_file_move()` to ReferenceLookup — handles reference lookup, update, retry, cleanup, and rescan for a single file in a directory move
   - Step 2.2: Simplify handler's `_handle_directory_moved` to: walk directory → call `process_directory_file_move()` per file
   - Step 2.3: Run tests — verify all 386 pass

3. **Phase 3**: Cleanup and documentation
   - Step 3.1: Remove any dead code from handler
   - Step 3.2: Update module docstrings

## Testing Strategy

### Existing Test Coverage

- **Unit Tests**: test_move_detection.py (10 methods), test_directory_move_detection.py (15 methods)
- **Integration Tests**: test_file_movement.py (13), test_link_updates.py (17), test_complex_scenarios.py, test_error_handling.py, test_windows_platform.py
- **Manual Validation**: 12 PD-BUG regression tests

### Testing Approach During Refactoring

- **Regression Testing**: Full test suite (386 tests) after each phase
- **Incremental Testing**: Run tests after each method extraction before proceeding
- **New Test Requirements**: None — this is a pure structural extraction with no behavior change

## Success Criteria

### Quality Improvements

- **Handler LOC Reduction**: Target ~40% reduction (681 → ~410 LOC)
- **Maintainability**: Handler focuses on event dispatch only
- **Performance**: N/A — structural extraction, no performance target
- **Technical Debt**: TD035 resolved

### Functional Requirements

- [ ] All 386 existing tests continue to pass
- [ ] No breaking changes to public APIs
- [ ] All bug fixes preserved (PD-BUG-008, PD-BUG-010, PD-BUG-025)

## Implementation Tracking

### Progress Log

| Date | Phase | Completed Work | Issues Encountered | Next Steps |
|------|-------|----------------|-------------------|------------|
| 2026-03-03 | Phase 1 | Extracted `_update_links_within_moved_file` + `_calculate_updated_relative_path` to ReferenceLookup | None | Phase 2 |
| 2026-03-03 | Phase 2 | Extracted per-file loop from `_handle_directory_moved` as `process_directory_file_move()` on ReferenceLookup | None | Phase 3 |
| 2026-03-03 | Phase 3 | Removed unused imports (`re`, `shutil`), updated docstrings, verified tests | None | Complete |

### Metrics Tracking

| Metric | Baseline | Final | Target | Status |
|--------|----------|-------|--------|--------|
| Handler LOC | 681 | 474 | ~410 | Achieved 30% reduction |
| ReferenceLookup LOC | 257 | 517 | ~525 | As expected |
| Test Suite | 386 passed | 387 passed | 386+ passed | Pass (gained 1) |

## Results and Lessons Learned

### Final Metrics

- **Handler LOC**: 474 (Change: -30%, from 681)
- **ReferenceLookup LOC**: 517 (Change: +101%, from 257)
- **Test Suite**: 387 passed, 5 skipped, 7 xfailed (baseline: 386 passed)
- **Technical Debt**: TD035 resolved

### Achievements

- Handler reduced from 681 to 474 LOC (30% reduction)
- All bug fix logic (PD-BUG-008, PD-BUG-010, PD-BUG-025) preserved exactly
- ReferenceLookup now owns the complete reference management lifecycle: find, update, retry, cleanup, rescan, and link content updates
- Removed unused `re` and `shutil` imports from handler

### Challenges and Solutions

- No significant challenges — the established extraction pattern (TD022/ReferenceLookup) made the target and approach clear

### Lessons Learned

- Incremental extraction (TD022 first, then TD035) is smoother than attempting large monolithic extractions — each step builds on established patterns
- Returning structured results (tuples) from extracted methods allows the handler to maintain stats without coupling the extracted module to handler internals

### Remaining Technical Debt

- TD034: Dual print()+logger output in service.py (already resolved in parallel session)
- Handler is now 474 LOC — within acceptable range for an event dispatch module

## Documentation & State Updates

- [ ] Feature implementation state file updated: N/A (no feature boundary change)
- [ ] TDD updated: N/A (no interface/design change)
- [ ] Test spec updated: N/A (no behavior change)
- [ ] FDD updated: N/A (no functional change)
- [x] Technical Debt Tracking: TD035 marked resolved

## Related Documentation

- [Technical Debt Tracking](/doc/process-framework/state-tracking/permanent/technical-debt-tracking.md)
- [TD005 God Class Decomposition](/doc/process-framework/refactoring/plans/decompose-god-class-linkmaintenancehandler-td005.md)
- [TD022 Reference Lookup Extraction](/doc/process-framework/refactoring/plans/extract-reference-lookup-from-handler-py-into-reference-lookup-py-td022.md)
