---
id: PD-REF-044
type: Document
category: General
version: 1.0
created: 2026-03-03
updated: 2026-03-03
target_area: linkwatcher/updater.py
refactoring_scope: Extract PathResolver from LinkUpdater (TD033)
priority: Medium
---

# Refactoring Plan: Extract PathResolver from LinkUpdater (TD033)

## Overview
- **Target Area**: linkwatcher/updater.py
- **Priority**: Medium
- **Created**: 2026-03-03
- **Author**: AI Agent & Human Partner
- **Status**: Completed

## Refactoring Scope

Extract path resolution logic from `LinkUpdater` into a standalone `PathResolver` class to address TD033's SRP violation. LinkUpdater currently mixes three distinct responsibilities: path resolution (~250 LOC, 10 methods), regex/text replacement (~100 LOC, 4 methods), and file I/O (~50 LOC). Path resolution is the largest, most cohesive group and the clearest extraction candidate.

### Current Issues

- **SRP violation**: LinkUpdater (628 LOC) handles path resolution, regex replacement, and file I/O in a single class
- **Low cohesion**: Path resolution methods (10 methods, ~250 LOC) have no dependency on file I/O or regex replacement — they only use `normalize_path` from utils and `os`/`pathlib` stdlib
- **Testing friction**: Path resolution logic can only be tested through LinkUpdater, requiring file fixtures even when testing pure path calculations

### Refactoring Goals

- Extract `PathResolver` class into `linkwatcher/path_resolver.py` containing all path calculation methods
- LinkUpdater delegates to PathResolver for path calculations, retaining file I/O and text replacement
- All 386 existing tests pass without modification (behavior preservation)
- No changes to public API (`update_references`, `set_dry_run`, `set_backup_enabled`)

## Current State Analysis

### Code Quality Metrics (Baseline)

- **LinkUpdater LOC**: 628 lines, 20 methods
- **Path resolution methods**: 10 methods (~250 LOC): `_calculate_new_target`, `_calculate_new_target_relative`, `_match_direct`, `_match_stripped`, `_match_resolved`, `_analyze_link_type`, `_resolve_to_absolute_path`, `_convert_to_original_link_type`, `_calculate_relative_path_between_files`, `_calculate_new_python_import`
- **Test baseline**: 386 passed, 5 skipped, 7 xfailed
- **Technical Debt**: TD033 (Medium priority, Large effort, assessed PF-VAL-038)

### Affected Components

- `linkwatcher/updater.py` — Remove path resolution methods, add PathResolver dependency
- `linkwatcher/path_resolver.py` — New file containing extracted PathResolver class
- `linkwatcher/__init__.py` — Export PathResolver
- `tests/unit/test_updater.py` — Tests calling private path methods will need import updates

### Dependencies and Impact

- **Internal consumers of LinkUpdater**: `handler.py`, `reference_lookup.py`, `service.py` — use only public API (`update_references`, `set_dry_run`, `set_backup_enabled`, `backup_enabled`). No changes needed.
- **Test consumers**: `test_updater.py` calls `_calculate_new_target` and `_replace_markdown_target` directly. These stay on LinkUpdater (it delegates internally).
- **External Dependencies**: None
- **Risk Assessment**: Low — pure Extract Class refactoring with no public API changes. Path resolution methods have no side effects.

## Refactoring Strategy

### Approach

**Extract Class** refactoring: Move all path resolution methods from LinkUpdater into a new PathResolver class. LinkUpdater creates and owns a PathResolver instance, delegating path calculations to it. No public API changes.

### Specific Techniques

- **Extract Class**: Create `PathResolver` with the 10 path-resolution methods
- **Delegation**: LinkUpdater's `_calculate_new_target` delegates to `self.path_resolver`
- **Preserve private method signatures**: Tests calling `updater._calculate_new_target()` continue to work because this method stays on LinkUpdater as a thin delegate

### Implementation Plan

1. **Phase 1**: Create `linkwatcher/path_resolver.py` with PathResolver class
   - Copy all 10 path resolution methods
   - PathResolver takes `project_root` and `logger` in constructor
   - Public API: `calculate_new_target(ref, old_path, new_path) -> str`

2. **Phase 2**: Update `linkwatcher/updater.py`
   - Import PathResolver, instantiate in `__init__`
   - Replace `_calculate_new_target` body with delegation to `self.path_resolver.calculate_new_target()`
   - Remove the 9 extracted private methods
   - Run tests

3. **Phase 3**: Update exports and finalize
   - Add PathResolver to `__init__.py` exports
   - Run full test suite
   - Update documentation

## Testing Strategy

### Existing Test Coverage

- **Unit Tests**: `tests/unit/test_updater.py` — 3 test classes, ~40 test methods covering path calculation, stale detection, root-relative paths, markdown replacement, dry run, backup, error handling
- **Integration Tests**: `tests/integration/` — `test_link_updates.py`, `test_powershell_script_monitoring.py`, `test_windows_platform.py`, `test_error_handling.py` all use LinkUpdater
- **Move Detection Tests**: `tests/test_move_detection.py`, `tests/test_directory_move_detection.py` — end-to-end handler+updater tests

### Testing Approach During Refactoring

- **Regression Testing**: Full 386-test suite run after each phase
- **Incremental Testing**: Run `pytest test/automated/unit/test_updater.py -q` after each change
- **New Test Requirements**: None — existing tests cover all path resolution behavior through LinkUpdater's interface

## Success Criteria

### Quality Improvements

- **SRP compliance**: LinkUpdater reduced from 3 responsibilities to 2 (file I/O + text replacement)
- **LOC reduction**: LinkUpdater reduced from ~628 to ~380 LOC
- **New module**: PathResolver ~280 LOC with single responsibility (path calculation)
- **Performance**: N/A — no performance target (pure structural refactoring)
- **Technical Debt**: TD033 resolved

### Functional Requirements

- [ ] All existing functionality preserved
- [ ] No breaking changes to public APIs
- [ ] All existing tests continue to pass (386 passed)
- [ ] Performance maintained

## Implementation Tracking

### Progress Log

| Date | Phase | Completed Work | Issues Encountered | Next Steps |
|------|-------|----------------|-------------------|------------|
| 2026-03-03 | Phase 1 | Created `linkwatcher/path_resolver.py` with 10 methods (332 LOC) | None | Update updater.py |
| 2026-03-03 | Phase 2 | Updated `updater.py` to delegate; removed 9 private methods | None | Update exports |
| 2026-03-03 | Phase 3 | Added PathResolver to `__init__.py` exports; all 386 tests pass | None | State files |

### Metrics Tracking

| Metric | Baseline | Final | Target | Status |
|--------|----------|-------|--------|--------|
| updater.py LOC | 628 | 348 | ~380 | Exceeded |
| path_resolver.py LOC | 0 | 332 | ~280 | Acceptable |
| Test Suite | 386 passed | 386 passed | 386 passed | Met |
| LinkUpdater responsibilities | 3 | 2 | 2 | Met |

## Results and Lessons Learned

### Final Metrics

- **updater.py LOC**: 348 (Change: −45%)
- **path_resolver.py LOC**: 332 (new module)
- **Test Suite**: 386 passed, 5 skipped, 7 xfailed (unchanged)
- **Technical Debt**: TD033 resolved

### Achievements

- Extracted PathResolver class with single responsibility (path calculation)
- LinkUpdater reduced from 3 responsibilities to 2 (text replacement + file I/O)
- Zero test changes required — delegation pattern preserved all existing interfaces
- No bugs discovered during refactoring

### Challenges and Solutions

- No challenges encountered. Clean Extract Class refactoring with well-separated concerns.

### Lessons Learned

- When private methods have no dependency on class state beyond constructor params, they are excellent extraction candidates
- Keeping a thin delegate method (`_calculate_new_target`) on the original class avoids breaking test code that calls private methods

### Remaining Technical Debt

- TD033 is fully resolved
- Remaining updater-related debt: TD034 (dual print+logger in service.py, separate from updater)

## Related Documentation
- [Technical Debt Tracking](/doc/product-docs/state-tracking/permanent/technical-debt-tracking.md)
- [Code Quality Standards](/process-framework/guides/03-testing/code-quality-standards.md)
- [Testing Guidelines](/process-framework/guides/03-testing/testing-guidelines.md)
