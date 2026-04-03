---
id: PD-REF-106
type: Document
category: General
version: 1.0
created: 2026-03-27
updated: 2026-03-27
target_area: File System Monitoring
priority: Medium
refactoring_scope: Replace timer-per-delete model with priority queue and single worker thread in MoveDetector
debt_item: TD107
---

# Refactoring Plan: Replace timer-per-delete model with priority queue and single worker thread in MoveDetector

## Overview
- **Target Area**: File System Monitoring
- **Priority**: Medium
- **Created**: 2026-03-27
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Debt Item**: TD107

## Refactoring Scope

### Current Issues
- Each `buffer_delete()` call creates a dedicated `threading.Timer` thread — N pending deletes = N OS threads
- During mass operations (directory cleanup with 100+ files), this spawns 100+ timer threads with OS scheduling overhead
- Timer cancellation requires explicit `timer.cancel()` calls in multiple code paths (match, stale discard, re-buffer)

### Scope Discovery
- **Original Tech Debt Description**: Timer-per-delete model in MoveDetector creates N threads for N pending deletes — priority queue would be more efficient for mass operations
- **Actual Scope Findings**: Confirmed. `self._timers` dict holds one `threading.Timer` per pending path. Three separate code paths cancel timers (match, stale discard, re-buffer).
- **Scope Delta**: None — scope matches original description

### Refactoring Goals
- Replace N timer threads with 1 worker thread + heapq priority queue
- Simplify cancellation to lazy deletion (skip stale queue entries)
- Preserve all existing behavior and public API

## Current State Analysis

### Code Quality Metrics (Baseline)
- **Lines**: 174
- **Threads per N deletes**: N (one `threading.Timer` per `buffer_delete()` call)
- **Code Coverage**: 20/20 tests passing (test_move_detection.py)
- **Full regression**: 596 passed, 5 skipped, 7 xfailed

### Affected Components
- `linkwatcher/move_detector.py` — sole file modified

### Dependencies and Impact
- **Internal Dependencies**: `linkwatcher/handler.py` instantiates `MoveDetector` and calls `buffer_delete()`, `match_created_file()`, `has_pending`
- **External Dependencies**: None
- **Risk Assessment**: Low — public API unchanged, all tests pass

## Refactoring Strategy

### Approach
Replace the per-delete `threading.Timer` pattern with a single daemon worker thread that sleeps on a `threading.Event`, waking when new entries arrive or when the earliest expiry is reached. A heapq priority queue orders pending deletes by expiry time.

### Specific Techniques
- **Heapq priority queue**: `(expiry_time, rel_path)` tuples, O(log N) insert
- **Lazy deletion**: When `match_created_file()` removes a path from `_pending`, the queue entry remains but is silently skipped by the worker (dict membership + timestamp check)
- **Stale re-buffer detection**: Worker verifies queue entry expiry matches current `_pending` timestamp before confirming, preventing stale entries from a re-buffered path from firing

### Implementation Plan
1. Replace `self._timers` dict with `self._queue` heapq and `self._wake` Event
2. Add `_expiry_worker()` method as single daemon thread
3. Modify `buffer_delete()` to push to queue + wake worker instead of creating Timer
4. Simplify `match_created_file()` — remove timer cancellation, just delete from `_pending`
5. Remove `_timer_expired()` — logic absorbed into `_expiry_worker()`

## Testing Strategy

### Existing Test Coverage
- **test_move_detection.py**: 20 tests covering buffer/match, bulk operations, stale discard, timer expiry, thread safety, non-monitored extensions

### Testing Approach During Refactoring
- **Regression Testing**: Full `test/automated/` suite after implementation
- **Incremental Testing**: `test_move_detection.py` after each change
- **New Test Requirements**: None — existing tests cover all behavioral contracts

## Results

### Before/After Metrics
| Metric | Before | After |
|--------|--------|-------|
| Lines | 174 | 198 |
| Threads per N deletes | N | 1 |
| Data structures | `_pending` + `_timers` | `_pending` + `_queue` (heapq) |
| Cancellation | Explicit `timer.cancel()` in 3 paths | Lazy deletion (1 check in worker) |

### Test Results
| Suite | Before | After |
|-------|--------|-------|
| test_move_detection.py | 20 passed, 0.75s | 20 passed, 0.65s |
| Full regression | 596 passed, 5 skipped, 7 xfailed | 596 passed, 5 skipped, 7 xfailed |

### Functional Requirements
- [x] All existing functionality preserved
- [x] No breaking changes to public APIs
- [x] All existing tests continue to pass
- [x] Performance maintained or improved

### Achievements
- Reduced thread count from O(N) to O(1) for pending deletes
- Simplified cancellation logic from 3 explicit cancel paths to 1 lazy check
- No new test failures

### Challenges and Solutions
- None — straightforward pattern replacement

### Remaining Technical Debt
- None introduced by this refactoring

### Bugs Discovered
- None

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
