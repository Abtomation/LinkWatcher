---
id: PD-REF-079
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-27
updated: 2026-03-27
refactoring_scope: Add structured logging to MoveDetector buffer/match/expire algorithm
target_area: linkwatcher/move_detector.py
priority: Medium
mode: lightweight
---

# Lightweight Refactoring Plan: Add structured logging to MoveDetector buffer/match/expire algorithm

- **Target Area**: linkwatcher/move_detector.py
- **Priority**: Medium
- **Created**: 2026-03-27
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD079 — Add structured logging to MoveDetector

**Scope**: MoveDetector has zero logging — the timing-critical buffer/match/expire algorithm is invisible at runtime. Add `get_logger()` and DEBUG-level structured log calls to `buffer_delete()`, `match_created_file()` (match found + stale discard), and `_timer_expired()`.

**Changes Made**:
- [x] Import `get_logger` from `.logging`, add `self.logger = get_logger()` to `__init__`
- [x] `buffer_delete()`: DEBUG log with rel_path, file_size, delay
- [x] `match_created_file()`: DEBUG log on match found (old_path → new_path); DEBUG log on stale discard (PD-BUG-042)
- [x] `_timer_expired()`: DEBUG log on confirmed true delete (rel_path)

**Test Baseline**: 20 passed in test_move_detection.py (0.76s)
**Test Result**: 20 passed in test_move_detection.py (0.75s); full suite: 604 passed, 5 skipped, 7 xfailed (52.11s)

**Documentation & State Updates**:
- [x] Feature implementation state file (1.1.1) updated, or N/A — _Grepped state file: references MoveDetector module but documents algorithm structure, not logging. No update needed._
- [x] TDD (1.1.1) updated, or N/A — _Grepped TDD: references MoveDetector class but documents design, not logging. No interface change._
- [x] Test spec (1.1.1) updated, or N/A — _Grepped test spec: no references to MoveDetector. No behavior change._
- [x] FDD (1.1.1) updated, or N/A — _No FDD references to MoveDetector._
- [x] ADR updated, or N/A — _Grepped ADR: references timer-based algorithm, not logging. No architectural decision affected._
- [x] Validation tracking updated, or N/A — _Logging-only change does not affect validation dimensions._
- [x] Technical Debt Tracking: TD079 marked resolved

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD079 | Complete | None | None |

## Related Documentation
- [Technical Debt Tracking](/doc/product-docs/state-tracking/permanent/technical-debt-tracking.md)
