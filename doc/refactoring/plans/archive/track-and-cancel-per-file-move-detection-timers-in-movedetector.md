---
id: PD-REF-032
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-02
updated: 2026-03-02
mode: lightweight
target_area: linkwatcher/move_detector.py
priority: Medium
refactoring_scope: Track and cancel per-file move detection timers in MoveDetector
---

# Lightweight Refactoring Plan: Track and cancel per-file move detection timers in MoveDetector

- **Target Area**: linkwatcher/move_detector.py
- **Priority**: Medium
- **Created**: 2026-03-02
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (≤15 min effort, single file, no architectural impact)

## Item 1: TD018 — Track and cancel per-file move detection timers

**Scope**: `MoveDetector.buffer_delete` creates a `threading.Timer` but never stores a reference to it. This means timers cannot be cancelled when a match is found (via `match_created_file`) or when the same path is re-buffered. In high-churn scenarios, orphan timers accumulate and waste threads. Fix: add a `_timers` dict, store each timer keyed by `rel_path`, cancel on match or re-buffer.

**Changes Made**:
- [x] Add `self._timers = {}` dict to `__init__` (line 34)
- [x] In `buffer_delete`: cancel existing timer for same path before creating new one; store timer in `_timers` (lines 55-63)
- [x] In `match_created_file`: cancel timer for matched path when removing from `_pending` (lines 92-94)
- [x] In `_timer_expired`: remove timer from `_timers` dict (line 110)
- [x] Mark timers as daemon threads (consistent with dir_move_detector) (line 61)

**Test Baseline**: 4 passed (test_move_detection.py), 21 passed (test_directory_move_detection.py)
**Test Result**: 4 passed (test_move_detection.py), 21 passed (test_directory_move_detection.py) — all 25 pass

**Documentation & State Updates**:
- [x] Feature implementation state file updated (1.1.1: line count 99→113, added TD018 to progress + recently completed)
- [x] TDD updated (PD-TDD-023: MoveDetector pseudocode updated with _timers dict, buffer_delete/match_created_file pseudocode, TD018 in known debt)
- [x] Test spec updated (N/A — no behavior change)
- [x] FDD updated (N/A — no functional change)
- [x] Technical Debt Tracking: TD018 marked resolved

**Bugs Discovered**: None

<!-- BATCH MODE: Copy the "## Item N" section above for each additional debt item in this session -->

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD018 | Complete | None | TDD PD-TDD-023, Feature State 1.1.1 |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
