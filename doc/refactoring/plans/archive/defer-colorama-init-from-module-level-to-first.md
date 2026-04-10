---
id: PD-REF-169
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-09
updated: 2026-04-09
priority: Medium
target_area: linkwatcher/logging.py
refactoring_scope: Defer colorama.init() from module-level to first ColoredFormatter use
mode: lightweight
---

# Lightweight Refactoring Plan: Defer colorama.init() from module-level to first ColoredFormatter use

- **Target Area**: linkwatcher/logging.py
- **Priority**: Medium
- **Created**: 2026-04-09
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD185 — Defer colorama.init() from module-level to first ColoredFormatter use

**Scope**: `colorama.init(autoreset=True)` at line 90 of `linkwatcher/logging.py` wraps `sys.stdout`/`sys.stderr` at import time, causing side effects in test harnesses and non-terminal environments. Replace with lazy initialization on first `ColoredFormatter` instantiation with `colored=True`, using a module-level `_colorama_initialized` flag.

**Changes Made**:
- [x] Removed `init(autoreset=True)` call at module level (was line 90)
- [x] Added `_colorama_initialized = False` module-level flag
- [x] Added `_ensure_colorama()` helper that calls `init(autoreset=True)` once
- [x] Call `_ensure_colorama()` in `ColoredFormatter.__init__()` when `colored=True`

**Test Baseline**: 757 passed, 0 failed, 5 skipped, 4 deselected, 4 xfailed
**Test Result**: 758 passed, 0 failed, 5 skipped, 4 deselected, 4 xfailed — no regressions

**Documentation & State Updates**:
- [x] Feature implementation state file (3.1.1) updated, or N/A — _Grepped state file for "colorama" and "ColoredFormatter"; references are to the class existence, not init timing. N/A._
- [x] TDD (PD-TDD-023) updated, or N/A — _Grepped TDD for "colorama" and "ColoredFormatter"; references describe colorama as a dependency and ColoredFormatter in the architecture diagram. No interface or design change. N/A._
- [x] Test spec (TE-TSP-009) updated, or N/A — _Grepped test spec; references describe ColoredFormatter test cases. No behavior change. N/A._
- [x] FDD (PD-FDD-025) updated, or N/A — _Grepped FDD; references describe colorama as a dependency. No functional change. N/A._
- [x] ADR updated, or N/A — _Grepped ADR directory for "colorama" and "ColoredFormatter". No matches. N/A._
- [x] Validation tracking updated, or N/A — _No active validation tracking file for feature 3.1.1. N/A._
- [x] Technical Debt Tracking: TD185 marked resolved via Update-TechDebt.ps1

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD185 | Complete | None | None |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
