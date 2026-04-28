---
id: PD-REF-048
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-03
updated: 2026-03-03
target_area: src/linkwatcher/logging.py, src/linkwatcher/logging_config.py
priority: Medium
mode: lightweight
refactoring_scope: Add reset functions for global singletons in logging modules
---

# Lightweight Refactoring Plan: Add reset functions for global singletons in logging modules

- **Target Area**: src/linkwatcher/logging.py, src/linkwatcher/logging_config.py
- **Priority**: Medium
- **Created**: 2026-03-03
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (≤15 min effort, single file, no architectural impact)

## Item 1: TD036 — Add reset functions for global singletons in logging modules

**Scope**: Add `reset_logger()` to `src/linkwatcher/logging.py` and `reset_config_manager()` to `src/linkwatcher/logging_config.py` to provide clean test isolation without tests reaching into private module state (`_logger = None`). These are test-utility functions that properly close handlers before resetting.

**Changes Made**:
- [x] Add `reset_logger()` to `src/linkwatcher/logging.py` — closes handlers and sets `_logger = None`
- [x] Add `reset_config_manager()` to `src/linkwatcher/logging_config.py` — sets `_config_manager = None`
- [x] Update `tests/unit/test_logging.py` to use `reset_logger()` instead of `linkwatcher.logging._logger = None` (2 call sites replaced)

**Test Baseline**: 386 passed, 5 skipped, 7 xfailed
**Test Result**: 386 passed, 5 skipped, 7 xfailed (identical)

**Documentation & State Updates**:
- [x] Feature implementation state file updated — N/A (no feature boundary change)
- [x] TDD updated — N/A (no interface/design change)
- [x] Test spec updated — N/A (no behavior change)
- [x] FDD updated — N/A (no functional change)
- [x] Technical Debt Tracking: TD036 marked resolved

**Bugs Discovered**: None

<!-- BATCH MODE: Copy the "## Item N" section above for each additional debt item in this session -->

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD036 | Complete | None | None |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
