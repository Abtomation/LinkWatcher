---
id: PD-REF-038
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-03
updated: 2026-03-03
mode: lightweight
refactoring_scope: Add missing @wraps decorator to with_context in logging.py (TD028)
priority: Medium
target_area: src/linkwatcher/logging.py
---

# Lightweight Refactoring Plan: Add missing @wraps decorator to with_context in logging.py (TD028)

- **Target Area**: src/linkwatcher/logging.py
- **Priority**: Medium
- **Created**: 2026-03-03
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (≤15 min effort, single file, no architectural impact)

## Item 1: TD028 — Add missing `@wraps(func)` to `with_context()` decorator

**Scope**: The `with_context()` decorator in `linkwatcher/logging.py:428` wraps functions without using `functools.wraps`, causing decorated functions to lose their `__name__`, `__doc__`, and `__module__` attributes. Add `from functools import wraps` to imports and `@wraps(func)` above the inner `wrapper` function.

**Changes Made**:
- [x] Add `from functools import wraps` to module imports (line 18)
- [x] Add `@wraps(func)` decorator to `wrapper` function inside `with_context()` (line 434)

**Test Baseline**: 389 passed, 5 skipped, 7 xfailed
**Test Result**: 389 passed, 5 skipped, 7 xfailed (identical)

**Documentation & State Updates**:
- [x] Feature implementation state file updated — N/A (no feature boundary change)
- [x] TDD updated — N/A (no interface/design change)
- [x] Test spec updated — N/A (no behavior change)
- [x] FDD updated — N/A (no functional change)
- [x] Technical Debt Tracking: TD028 marked resolved via Update-TechDebt.ps1

**Bugs Discovered**: None

<!-- BATCH MODE: Copy the "## Item N" section above for each additional debt item in this session -->

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD028 | Complete | None | None |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
