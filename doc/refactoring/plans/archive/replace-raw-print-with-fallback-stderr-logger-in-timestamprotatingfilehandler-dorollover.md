---
id: PD-REF-142
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-02
updated: 2026-04-02
priority: Medium
mode: lightweight
target_area: src/linkwatcher/logging.py
refactoring_scope: Replace raw print() with fallback stderr logger in TimestampRotatingFileHandler.doRollover()
---

# Lightweight Refactoring Plan: Replace raw print() with fallback stderr logger in TimestampRotatingFileHandler.doRollover()

- **Target Area**: src/linkwatcher/logging.py
- **Priority**: Medium
- **Created**: 2026-04-02
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD144 — Replace raw print() with fallback stderr logger in doRollover()

**Scope**: `TimestampRotatingFileHandler.doRollover()` uses `print(..., file=sys.stderr)` at lines 114-118 and 128-131 for rotation failure warnings. Replace both with a module-level fallback `logging.Logger` that writes to stderr via a `StreamHandler`. This avoids the circular dependency (can't log through the handler being rotated) while providing structured log output instead of raw print.

**Dims**: OB (Observability)

**Changes Made**:
- [x] Created module-level `_fallback_logger` with `StreamHandler(sys.stderr)`, WARNING level, and `propagate=False` (logging.py lines 93-102)
- [x] Replaced both `print()` calls in `doRollover()` with `_fallback_logger.warning()` using %-style formatting (logging.py lines 116-118, 126-128)

**Test Baseline**: 656 passed, 5 skipped, 6 xfailed
**Test Result**: 656 passed, 5 skipped, 6 xfailed (identical — no regressions)

**Documentation & State Updates**:
- [x] Feature implementation state file (3.1.1) updated, or N/A — _Grepped feature state files for `TimestampRotatingFileHandler`/`doRollover` — no references found_
- [x] TDD (3.1.1) updated, or N/A — _Grepped TDD directory — no references to `TimestampRotatingFileHandler` or `doRollover`_
- [x] Test spec (3.1.1) updated, or N/A — _Grepped test specifications — no references to changed component_
- [x] FDD (3.1.1) updated, or N/A — _Grepped FDD directory — no references to changed component_
- [x] ADR updated, or N/A — _Grepped ADR directory — no references to changed component_
- [x] Validation tracking updated — _OB-R3-004 in validation-tracking-3.md references this; will be updated via Update-TechDebt.ps1 -ValidationNote_
- [x] Technical Debt Tracking: TD144 marked resolved via Update-TechDebt.ps1; OB-R3-004 in validation-tracking-3.md updated manually

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD144 | Complete | None | None (no docs reference this component) |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
