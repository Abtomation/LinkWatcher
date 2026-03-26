---
id: PD-REF-025
type: Document
category: General
version: 1.0
created: 2026-03-02
updated: 2026-03-02
refactoring_scope: Move Inline Imports to Module Level in handler.py (TD012)
target_area: linkwatcher/handler.py
priority: Low
---

# Refactoring Plan: Move Inline Imports to Module Level in handler.py (TD012)

## Overview
- **Target Area**: linkwatcher/handler.py
- **Priority**: Low
- **Created**: 2026-03-02
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Assessment**: PF-TDA-001 <!-- [PF-TDA-001](../../assessments/technical-debt/assessments/handler-module-structural-debt-assessment.md) - Removed: file deleted -->
- **Debt Item**: PF-TDI-008

## Refactoring Scope

### Current Issues

Two standard library imports used inside method bodies instead of at module level:

1. `import re` at line 807 inside `_update_links_within_moved_file`
2. `import shutil` at line 840 inside `_update_links_within_moved_file`

### Refactoring Goals

- Move both imports to module level alongside existing stdlib imports
- Remove inline `import` statements from method body
- Follow PEP 8 import ordering (stdlib alphabetical)

## Current State Analysis

- **Inline import count**: 2 (`re`, `shutil`)
- **Test baseline**: 344 passed, 9 failed (pre-existing)
- **Risk**: Very Low — moving imports to module level has no behavioral impact

### Affected Components

- `linkwatcher/handler.py` — module-level imports section and `_update_links_within_moved_file` method

## Refactoring Strategy

1. Add `import re` and `import shutil` to module-level imports (alphabetical order between `os` and `threading`)
2. Remove inline `import re` and `import shutil` from method body
3. Run full test suite

## Success Criteria

- [x] Zero inline imports of `re` or `shutil` in handler.py
- [x] All existing tests continue to pass (same 344 passed)
- [x] No new test failures introduced

## Implementation Tracking

| Date | Phase | Completed Work | Issues Encountered | Next Steps |
|------|-------|----------------|-------------------|------------|
| 2026-03-02 | Execution | Added re, shutil to module imports; removed 2 inline imports | None | Validate |
| 2026-03-02 | Validation | Tests: 344 passed, 9 failed (same as baseline) | None | Complete |

## Results and Lessons Learned

- **Inline import count**: 2 → 0
- **Test results**: Identical before/after (344 passed, 9 failed pre-existing)
- **Bug discovery**: No bugs discovered. Trivial scope.
- **Status**: Complete

## Related Documentation
- [Technical Debt Tracking](/doc/product-docs/state-tracking/permanent/technical-debt-tracking.md)
<!-- - [Handler Module Structural Debt Assessment](/doc/process-framework/assessments/technical-debt/assessments/handler-module-structural-debt-assessment.md) - Removed: file deleted -->
