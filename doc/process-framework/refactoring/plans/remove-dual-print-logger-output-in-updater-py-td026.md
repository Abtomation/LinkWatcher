---
id: PF-REF-039
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-03
updated: 2026-03-03
mode: lightweight
priority: Medium
refactoring_scope: Remove dual print+logger output in updater.py (TD026)
target_area: linkwatcher/updater
---

# Lightweight Refactoring Plan: Remove dual print+logger output in updater.py (TD026)

- **Target Area**: linkwatcher/updater
- **Priority**: Medium
- **Created**: 2026-03-03
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (≤15 min effort, single file, no architectural impact)

## Item 1: TD026 — Remove dual print+logger output in updater.py

**Scope**: 6 `print()` calls in updater.py duplicate information already emitted by structured logger calls. Same pattern as resolved TD010 in handler.py. Each message will be assigned to one channel: print for user-facing progress/preview, logger for persistent structured records. 5 prints removed (logger kept), 1 logger removed (print kept for dry-run preview).

**Channel assignment**:
| Location | Message | Keep | Remove | Rationale |
|----------|---------|------|--------|-----------|
| L65-68 | Success: Updated N refs | logger.links_updated() | print | Structured stats tracking; caller uses returned stats |
| L71-76 | Stale line numbers | logger.warning() | print | Structured warning with details; caller uses stale_files list |
| L78-79 | No changes needed | logger.debug() | print | Debug-level info; not critical user feedback |
| L82-88 | Error updating file | logger.error() | print | Structured error with error_type; tracked in stats["errors"] |
| L121-126 | Dry run preview | print | logger.info() | User-facing dry-run preview is the whole point of dry-run mode |
| L579-585 | Backup creation failed | logger.warning() | print | Operational warning with error details |

**Changes Made**:
- [x] Remove 5 print() calls (lines 66-68, 76, 79, 88, 585)
- [x] Remove 1 logger.info() call (lines 121-123, dry run)
- [ ] ~~Remove unused `from colorama import Fore` import~~ — still used by remaining dry-run print

**Test Baseline**: 389 passed, 5 skipped, 7 xfailed
**Test Result**: 389 passed, 5 skipped, 7 xfailed (identical)

**Documentation & State Updates**:
- [x] Feature implementation state file updated — N/A (no interface change)
- [x] TDD updated — N/A (no interface/design change)
- [x] Test spec updated — N/A (no behavior change)
- [x] FDD updated — N/A (no functional change)
- [x] Technical Debt Tracking: TD026 marked resolved via Update-TechDebt.ps1

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD026 | Complete | None | None (all N/A) |

## Related Documentation
- [Technical Debt Tracking](/doc/process-framework/state-tracking/permanent/technical-debt-tracking.md)
