---
id: PD-REF-137
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-02
updated: 2026-04-02
refactoring_scope: Add metric instrumentation to MoveDetector and DirectoryMoveDetector
mode: lightweight
target_area: Move Detection (1.1.1)
priority: Medium
---

# Lightweight Refactoring Plan: Add metric instrumentation to MoveDetector and DirectoryMoveDetector

- **Target Area**: Move Detection (1.1.1)
- **Priority**: Medium
- **Created**: 2026-04-02
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Dependencies and Impact
- **Affected Components**: `src/linkwatcher/move_detector.py`, `src/linkwatcher/dir_move_detector.py`
- **Internal Dependencies**: Both modules are instantiated by `src/linkwatcher/handler.py`. `PerformanceLogger` from `src/linkwatcher/logging.py` is the metric API (already used elsewhere).
- **Risk Assessment**: Low — purely additive `log_metric()` calls at existing code paths; no behavior or interface changes.

## Item 1: TD140 — Add metric instrumentation to MoveDetector and DirectoryMoveDetector

**Scope**: Add `PerformanceLogger.log_metric()` and `start_timer()`/`end_timer()` calls to measure: (1) buffer count per operation, (2) buffer-to-match latency, (3) match success rate, (4) timer expiry rate, (5) dir move batch size and match ratio. Uses existing `PerformanceLogger` API — no new infrastructure needed. Dimension: OB (Observability). Source: PD-VAL-080 R3 OB-R3-002.

**Changes Made**:
- [x] `move_detector.py`: Added `log_metric("move_detect_pending_count")` in `buffer_delete()`; `start_timer`/`end_timer("move_detect_match")` with result tags in `match_created_file()`; `log_metric("move_detect_match_latency")` on successful match; `log_metric("move_detect_expiry_count")` in `_expiry_worker()`
- [x] `dir_move_detector.py`: Added `log_metric("dir_move_batch_size")` in `handle_directory_deleted()`; `log_metric("dir_move_match_progress")` on each prefix match; `log_metric("dir_move_first_match_latency")` on first match inference; `log_metric("dir_move_completion_trigger")` with trigger type (all_matched/settle_timer/max_timeout/max_timeout_no_match) in all completion paths; `log_metric("dir_move_total_duration")` in `_process_dir_move()`

**Test Baseline**: 649 passed, 5 skipped, 6 xfailed
**Test Result**: 649 passed, 5 skipped, 6 xfailed — no regressions

**Documentation & State Updates**:
- [x] Feature implementation state file (1.1.1) updated, or N/A — _N/A: Grepped state file — references describe module purpose/architecture, not internal logging; no update needed for additive metric calls_
- [x] TDD (1.1.1) updated, or N/A — _N/A: Grepped TDD — describes move detection design and threading model; metric instrumentation is internal implementation detail, no interface/design change_
- [x] Test spec (1.1.1) updated, or N/A — _N/A: Grepped test spec — no matches for move_detector/MoveDetector; purely additive logging has no behavior change_
- [x] FDD (1.1.1) updated, or N/A — _N/A: Grepped FDD — no references to move_detector modules_
- [x] ADR (1.1.1) updated, or N/A — _N/A: Grepped ADR — describes detection algorithm decisions; metric instrumentation doesn't change any architectural decision_
- [x] Validation tracking updated, or N/A — _N/A: Feature 1.1.1 R3 validation complete; additive observability doesn't affect validation scores_
- [x] Technical Debt Tracking: TD140 marked resolved via Update-TechDebt.ps1

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD140 | Complete | None | None (all N/A — additive observability) |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
