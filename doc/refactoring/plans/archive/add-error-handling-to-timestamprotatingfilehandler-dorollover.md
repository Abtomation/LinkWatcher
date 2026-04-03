---
id: PD-REF-102
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-27
updated: 2026-03-27
target_area: linkwatcher/logging.py
refactoring_scope: Add error handling to TimestampRotatingFileHandler.doRollover
mode: lightweight
priority: Medium
---

# Lightweight Refactoring Plan: Add error handling to TimestampRotatingFileHandler.doRollover

- **Target Area**: linkwatcher/logging.py
- **Priority**: Medium
- **Created**: 2026-03-27
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD098 — Add error handling to doRollover() os.rename/os.remove calls

**Scope**: Wrap `os.rename()` and `os.remove()` calls in `TimestampRotatingFileHandler.doRollover()` (lines 110, 117) with try/except for `OSError`. On Windows, file locking by antivirus or other processes can cause these to fail, propagating unhandled exceptions that crash the logging handler and silence all subsequent file logging. The fix logs warnings to stderr and continues gracefully.

**Changes Made**:
<!-- Fill in after implementation -->
- [x] Wrap os.rename() in try/except OSError — on failure, warn to stderr and continue (log to fresh file)
- [x] Wrap os.remove() in try/except OSError — on failure, warn to stderr and skip cleanup of that backup

**Test Baseline**: 593 passed, 5 skipped, 7 xfailed
**Test Result**: 593 passed, 5 skipped, 7 xfailed — no regressions

**Documentation & State Updates**:
<!-- Check each — for N/A, write brief justification (e.g., "Grepped TDD — no references to changed method") -->
- [x] Feature implementation state file (3.1.1) updated, or N/A — verified no reference to changed component: _Grepped state file — no references to doRollover or TimestampRotatingFileHandler_
- [x] TDD (3.1.1) updated, or N/A — verified no interface/design changes documented: _Grepped TDD — no references to doRollover or TimestampRotatingFileHandler_
- [x] Test spec (3.1.1) updated, or N/A — verified no behavior change affects spec: _Grepped test spec — no references to doRollover or TimestampRotatingFileHandler_
- [x] FDD (3.1.1) updated, or N/A — verified no functional change affects FDD: _Grepped FDD — no references to doRollover or TimestampRotatingFileHandler_
- [x] ADR updated, or N/A — verified no architectural decision affected: _Grepped ADR directory — no references_
- [x] Validation tracking updated, or N/A — verified change doesn't affect validation: _Grepped validation tracking — TD098 not referenced_
- [x] Technical Debt Tracking: TD item marked resolved via Update-TechDebt.ps1

**Bugs Discovered**: None

<!-- BATCH MODE: Copy the "## Item N" section above for each additional debt item in this session -->

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD098 | Complete | None | None |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
