---
id: PD-REF-131
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-02
updated: 2026-04-02
refactoring_scope: Migrate 22 print() calls to structured logger in reference_lookup.py, dir_move_detector.py, handler.py (TD134)
target_area: linkwatcher core modules
priority: Medium
mode: lightweight
---

# Lightweight Refactoring Plan: Migrate 22 print() calls to structured logger in reference_lookup.py, dir_move_detector.py, handler.py (TD134)

- **Target Area**: linkwatcher core modules
- **Priority**: Medium
- **Created**: 2026-04-02
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Dependencies and Impact
- **Affected Components**: src/linkwatcher/reference_lookup.py, src/linkwatcher/dir_move_detector.py, src/linkwatcher/handler.py
- **Internal Dependencies**: All three modules already use `get_logger()` from linkwatcher.logging — no new dependencies introduced
- **Risk Assessment**: Low — mechanical replacement of print() with logger calls; no logic changes

## Item 1: TD134 — Migrate 22 print() calls to structured logger

**Scope**: Replace 22 print() calls using colorama.Fore formatting with structured logger calls across reference_lookup.py (15), dir_move_detector.py (5), and handler.py (2). Follows TD099/TD112 precedent. Dims: CQ, OB.

**Log Level Mapping**:
- Operation start/progress (CYAN): `logger.info` with structured event names
- Success results (GREEN): `logger.info` for summaries, `logger.debug` for per-link detail
- No-change/skip (CYAN): `logger.debug`
- Warnings (YELLOW): `logger.warning`
- Broken reference detail (YELLOW, already has logger.debug companion): `logger.debug`

**Changes Made**:
- [x] reference_lookup.py: 15 print() → logger calls (info/debug/warning), removed `from colorama import Fore`
- [x] dir_move_detector.py: 5 print() → logger calls (info/debug/warning), removed `from colorama import Fore`
- [x] handler.py: 2 print() → 1 logger.info + 1 removed (redundant with existing logger.debug), removed `from colorama import Fore`
- [x] colorama now only imported by logging.py (feature 3.1.1) — correct architectural ownership

**Test Baseline**: 649 passed, 5 skipped, 6 xfailed
**Test Result**: 649 passed, 5 skipped, 6 xfailed (identical)

**Documentation & State Updates**:
- [x] Feature implementation state file (1.1.1) updated, or N/A — N/A, state file references components but not print/colorama usage
- [x] TDD updated, or N/A — N/A, grepped TDDs for "print"/"colorama" — TDD-2-2-1 mentions colorama for updater.py (separate feature, not in scope)
- [x] Test spec updated, or N/A — N/A, no active test specs reference print() or colorama for changed files
- [x] FDD updated, or N/A — N/A, FDD-0-1-1 lists colorama as project dependency (still used by logging.py). FDD-1-1-1 has no colorama references.
- [x] ADR updated, or N/A — N/A, grepped ADR directory — no print/colorama references relevant to this change
- [x] Validation tracking updated, or N/A — CQ-R3-001 / OB-R3-001 will be auto-updated by Update-TechDebt.ps1 -ValidationNote
- [x] Technical Debt Tracking: TD134 marked resolved via Update-TechDebt.ps1, CQ-R3-001 marked Resolved in validation-tracking-3.md

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD134 | Complete | None | None |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
