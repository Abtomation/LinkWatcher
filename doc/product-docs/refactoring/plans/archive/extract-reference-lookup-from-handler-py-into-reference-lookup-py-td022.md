---
id: PD-REF-042
type: Document
category: General
version: 1.0
created: 2026-03-03
updated: 2026-03-03
refactoring_scope: Extract reference lookup from handler.py into reference_lookup.py (TD022)
priority: Medium
target_area: linkwatcher/handler.py
---

# Refactoring Plan: Extract reference lookup from handler.py into reference_lookup.py (TD022)

## Overview
- **Target Area**: linkwatcher/handler.py
- **Priority**: Medium
- **Created**: 2026-03-03
- **Author**: AI Agent & Human Partner
- **Status**: Complete

## Refactoring Scope

TD005 decomposed `LinkMaintenanceHandler` into `handler.py`, `move_detector.py`, and `dir_move_detector.py`. The planned `reference_lookup.py` extraction was never done, leaving the handler at ~873 LOC with reference-lookup responsibilities mixed in.

### Current Issues
- Handler.py has 873 lines — still a large module after TD005 partial decomposition
- Reference lookup, stale retry, DB cleanup, and file rescanning methods are interleaved with event dispatch and move orchestration
- 7 methods (~195 lines) form a cohesive "reference lookup and DB management" concern that doesn't belong in the event handler

### Refactoring Goals
- Extract reference lookup and DB management methods into `ReferenceLookup` class in `linkwatcher/reference_lookup.py`
- Reduce handler.py from 873 to ~680 lines (~22% reduction)
- Handler becomes a pure orchestrator; reference work is delegated to `ReferenceLookup`

## Current State Analysis

### Code Quality Metrics (Baseline)
- **Handler LOC**: 873 lines
- **Test Suite**: 386 passed, 5 skipped, 7 xfailed
- **Technical Debt**: TD022 open (this item)

### Affected Components
- `linkwatcher/handler.py` — Remove 7 methods, add ReferenceLookup instantiation, update all call sites
- `linkwatcher/reference_lookup.py` — New module containing extracted `ReferenceLookup` class
- `tests/test_move_detection.py` — 3 tests call `handler._get_old_path_variations()` directly; update to use `handler._ref_lookup.get_old_path_variations()`

### Dependencies and Impact
- **Internal Dependencies**: `_handle_file_moved` and `_handle_directory_moved` call all 7 extracted methods; `_handle_file_created` calls `_rescan_file_links`; `_process_true_file_delete` is not affected (uses link_db directly)
- **External Dependencies**: None
- **Risk Assessment**: Low — pure structural extraction, no behavioral changes

## Refactoring Strategy

### Approach
Extract Move Object (composition pattern). Create a `ReferenceLookup` class that holds references to `link_db`, `parser`, `updater`, `project_root`, and `logger`. Handler instantiates it in `__init__` and delegates reference operations.

### Specific Techniques
- **Extract Class**: Move 7 cohesive methods into `ReferenceLookup`
- **Composition over Inheritance**: Handler holds a `ReferenceLookup` instance (`self._ref_lookup`)
- **Preserve interface**: Methods keep the same signatures (drop `self` prefix convention: `_find_references_multi_format` → `find_references`)

### Implementation Plan
1. **Phase 1**: Create `linkwatcher/reference_lookup.py` with `ReferenceLookup` class containing all 7 methods
2. **Phase 2**: Update `handler.py` — instantiate `ReferenceLookup` in `__init__`, replace `self._method()` calls with `self._ref_lookup.method()` calls, remove extracted methods
3. **Phase 3**: Update tests — fix 3 direct method calls in `test_move_detection.py`
4. **Phase 4**: Run full test suite, verify 386 passed

### Methods to Extract

| Current Handler Method | New ReferenceLookup Method | Lines |
|------------------------|---------------------------|-------|
| `_get_path_variations` | `get_path_variations` | 14 |
| `_find_references_multi_format` | `find_references` | 27 |
| `_get_old_path_variations` | `get_old_path_variations` | 8 |
| `_retry_stale_references` | `retry_stale_references` | 57 |
| `_cleanup_database_after_file_move` | `cleanup_after_file_move` | 40 |
| `_rescan_file_links` | `rescan_file_links` | 26 |
| `_rescan_moved_file_links` | `rescan_moved_file_links` | 23 |

## Testing Strategy

### Existing Test Coverage
- **Direct tests**: 3 tests for `_get_old_path_variations` in `test_move_detection.py`
- **Indirect tests**: Integration tests for stale retry, title preservation, and move handling cover the extracted methods through `_handle_file_moved` and `_handle_directory_moved`
- **Full suite**: 386 passing tests provide comprehensive regression coverage

### Testing Approach During Refactoring
- **Regression Testing**: Run full suite after each phase
- **Incremental Testing**: Run `test_move_detection.py` after test updates
- **New Test Requirements**: None — extraction is structural, behavior is preserved

## Success Criteria

### Quality Improvements
- **LOC Reduction**: handler.py from 873 to ~680 lines (~22%)
- **Single Responsibility**: Handler handles events; ReferenceLookup handles DB queries and cleanup
- **Technical Debt**: TD022 resolved

### Functional Requirements
- [x] All existing functionality preserved
- [x] No breaking changes to public APIs
- [x] All existing tests continue to pass (386 passed)
- [x] Performance maintained

## Implementation Tracking

### Progress Log
| Date | Phase | Completed Work | Issues Encountered | Next Steps |
|------|-------|----------------|-------------------|------------|
| 2026-03-03 | Analysis | Code analysis, call graph, test coverage review | None | Create reference_lookup.py |
| 2026-03-03 | Phase 1 | Created linkwatcher/reference_lookup.py (233 lines) | None | Update handler.py |
| 2026-03-03 | Phase 2 | Updated handler.py: instantiated ReferenceLookup, delegated 14 call sites, removed 7 methods | None | Update tests |
| 2026-03-03 | Phase 3 | Updated 3 tests in test_move_detection.py | None | Run full suite |
| 2026-03-03 | Phase 4 | Full suite: 386 passed, 5 skipped, 7 xfailed (identical to baseline) | None | State updates |

### Metrics Tracking
| Metric | Baseline | Current | Target | Status |
|--------|----------|---------|--------|--------|
| Handler LOC | 873 | 681 | ~680 | **Hit** |
| Test Suite | 386 passed | 386 passed | 386 passed | **Hit** |

## Documentation & State Updates
- [x] Feature implementation state file updated (1.1.1 — added reference_lookup.py to component list, updated handler.py description)
- [x] TDD updated (1.1.1 File System Monitoring — added ReferenceLookup as 4th module)
- [x] Test spec updated (N/A — no behavior change)
- [x] FDD updated (N/A — no functional change)
- [x] Technical Debt Tracking: TD022 marked resolved

## Results and Lessons Learned

### Final Metrics
- **Handler LOC**: 681 (from 873, -22%)
- **New module**: reference_lookup.py — 233 lines
- **Test Suite**: 386 passed (unchanged)
- **Technical Debt**: TD022 resolved

### Achievements
- Handler.py reduced from 873 to 681 lines (22% reduction)
- Clean separation: handler does event dispatch + orchestration, ReferenceLookup does DB queries + cleanup
- Zero test failures — pure structural extraction with no behavioral changes
- Consistent with existing extraction pattern (move_detector.py, dir_move_detector.py)

### Challenges and Solutions
- No significant challenges — the methods had clean boundaries and minimal coupling to handler-specific state

### Remaining Technical Debt
- `_update_links_within_moved_file` (147 lines) + `_calculate_updated_relative_path` (35 lines) remain in handler.py — potential future extraction as `link_content_updater.py`

## Related Documentation
- [Technical Debt Tracking](/doc/product-docs/state-tracking/permanent/technical-debt-tracking.md)
- [TD005 — God Class decomposition](/doc/product-docs/refactoring/plans/decompose-god-class-linkmaintenancehandler-td005.md)
