---
id: PD-REF-022
type: Document
category: General
version: 1.0
created: 2026-03-02
updated: 2026-03-02
refactoring_scope: TD006 Encapsulation Violation Fix
target_area: handler.py database.py service.py
priority: High
---

# Refactoring Plan: TD006 Encapsulation Violation Fix

## Overview
- **Target Area**: handler.py, database.py, service.py
- **Priority**: High
- **Created**: 2026-03-02
- **Author**: AI Agent & Human Partner
- **Status**: Completed

## Refactoring Scope

### Current Issues
- Handler directly accesses `link_db.links` dict (handler.py:374,380,965) bypassing thread-safe public API
- Handler directly accesses `link_db.files_with_links` set (handler.py:988) bypassing thread-safe public API
- Service directly accesses `link_db.links` dict (service.py:262) bypassing thread-safe public API
- All accesses lack `_lock` protection, creating potential race conditions

### Refactoring Goals
- Eliminate all direct access to `LinkDatabase` internal data structures from external modules
- Add thread-safe public API methods to `LinkDatabase` for all required operations
- Maintain identical external behavior (zero functional changes)

## Current State Analysis

### Code Quality Metrics (Baseline)
- **Test Coverage**: 344 passed, 9 failed (pre-existing), 4 skipped
- **Direct violations**: 4 locations across 2 files accessing internal database state
- **Technical Debt**: TD006 — High priority, Low effort

### Affected Components
- `src/linkwatcher/database.py` — Add 3 new public API methods
- `src/linkwatcher/handler.py` — Replace 3 direct accesses with API calls
- `src/linkwatcher/service.py` — Replace 1 direct access with API call

### Dependencies and Impact
- **Internal Dependencies**: handler.py and service.py depend on database.py public API
- **External Dependencies**: None
- **Risk Assessment**: Low — new methods are semantically identical to replaced inline code

## Refactoring Strategy

### Approach
Add missing public methods to `LinkDatabase` that encapsulate the operations previously done inline, then replace all direct accesses with method calls.

### Specific Techniques
- **Encapsulate Collection**: Expose read-only snapshot copies instead of mutable internal state
- **Extract Method**: Move target-removal logic into database class where it belongs

### Implementation Plan
1. **Phase 1**: Add 3 new methods to `LinkDatabase`
   - `remove_targets_by_path(old_path)` — anchor-aware, thread-safe target removal
   - `get_all_targets_with_references()` — snapshot copy of all targets and references
   - `get_source_files()` — copy of files_with_links set

2. **Phase 2**: Replace handler.py violations
   - Lines 374,380: Replace inline dict iteration+deletion with `remove_targets_by_path()`
   - Line 965: Replace `list(self.link_db.links.items())` with `get_all_targets_with_references()`
   - Line 988: Replace `list(self.link_db.files_with_links)` with `get_source_files()`

3. **Phase 3**: Replace service.py violation
   - Line 262: Replace `self.link_db.links.items()` with `get_all_targets_with_references().items()`

## Testing Strategy

### Existing Test Coverage
- **Unit Tests**: 11 tests in test_database.py — all passing
- **Integration Tests**: Multiple test files covering handler and service behavior
- **Full Suite**: 344 passing, 9 pre-existing failures

### Testing Approach During Refactoring
- **Regression Testing**: Full test suite run after all changes — identical results (344 pass, 9 fail)
- **Incremental Testing**: Database unit tests run after adding new methods (11/11 pass)
- **New Test Requirements**: None — existing tests adequately cover the changed behavior paths

## Results and Lessons Learned

### Final Metrics
- **Test Results**: 344 passed, 9 failed (identical to baseline — zero regressions)
- **Violations Eliminated**: 4/4 (100%)
- **New API Methods**: 3 added to LinkDatabase
- **Thread Safety**: Fixed — all database access now goes through locked methods

### Achievements
- Eliminated all direct access to `LinkDatabase` internals from external modules
- Fixed latent race condition where handler accessed internal dict without lock protection
- Established clean public API boundary for database class

### Remaining Technical Debt
- TD005: God Class — handler.py still has 10+ responsibilities (separate item)
- TD007: Mega Method — _handle_file_moved still needs decomposition (separate item)

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
<!-- - [Technical Debt Assessment PF-TDA-001](/process-framework/assessments/technical-debt/assessments/handler-module-structural-debt-assessment.md) - Removed: file deleted -->
