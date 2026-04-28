---
id: PD-REF-047
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-03
updated: 2026-03-03
priority: Medium
target_area: src/linkwatcher/service.py
refactoring_scope: Remove dual print+logger output in service.py (TD034)
mode: lightweight
---

# Lightweight Refactoring Plan: Remove dual print+logger output in service.py (TD034)

- **Target Area**: src/linkwatcher/service.py
- **Priority**: Medium
- **Created**: 2026-03-03
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (≤15 min effort, single file, no architectural impact)

## Item 1: TD034 — Remove dual print+logger output in service.py

**Scope**: Eliminate 12 paired print()+logger duplicates where the same event is output to both channels. Assign each message to one channel: print for user-facing progress/status, logger for errors/warnings/operational records. Same pattern as resolved TD010 (handler.py) and PF-REF-039 (updater.py).

**Changes Made**:
- [x] Removed 7 logger calls paired with user-facing print (service_starting, initial_scan_complete, file_monitoring_started, service_stopping, service_stopped, scan_progress, initial_scan_files_completed)
- [x] Removed 5 print call blocks paired with logger errors/records (observer_thread_died print, service_start_failed print, file_scan_failed print, shutdown_signal_received print, final stats print block)
- Result: 33→22 print calls, 21→14 logger calls (incl. LogTimer + with_context). File reduced from 293 to 268 lines.

**Test Baseline**: 386 passed, 5 skipped, 7 xfailed, 15 warnings
**Test Result**: 386 passed, 5 skipped, 7 xfailed, 15 warnings (identical)

**Documentation & State Updates**:
- [x] Feature implementation state file updated (N/A — no feature scope change)
- [x] TDD updated (N/A — no interface/design change)
- [x] Test spec updated (N/A — no behavior change)
- [x] FDD updated (N/A — no functional change)
- [x] Technical Debt Tracking: TD034 marked resolved

**Bugs Discovered**: None

<!-- BATCH MODE: Copy the "## Item N" section above for each additional debt item in this session -->

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD034 | Complete | None | None |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
