---
id: PF-REF-071
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-17
updated: 2026-03-17
refactoring_scope: Add Callable type annotations to callback signatures
target_area: move_detector.py, dir_move_detector.py
priority: Medium
debt_item: TD060
mode: lightweight
---

# Lightweight Refactoring Plan: Add Callable type annotations to callback signatures

- **Target Area**: move_detector.py, dir_move_detector.py
- **Priority**: Medium
- **Created**: 2026-03-17
- **Author**: AI Agent & Human Partner
- **Status**: Completed
- **Debt Item**: TD060
- **Mode**: Lightweight (≤15 min effort, no architectural impact)

## Item 1: TD060 — Add Callable type annotations to callback signatures

**Scope**: Add `Callable` type annotations to 4 callback parameters in `MoveDetector.__init__` and `DirectoryMoveDetector.__init__` so AI agents and IDEs can infer callback contracts. Also typed `delay`/`max_timeout`/`settle_delay` as `float`.

**Changes Made**:
- [x] `move_detector.py`: Added `from typing import Callable`, typed `on_move_detected: Callable[[str, str], None]`, `on_true_delete: Callable[[str], None]`, `delay: float`
- [x] `dir_move_detector.py`: Added `from typing import Callable`, typed `on_dir_move: Callable[[str, str], None]`, `on_true_file_delete: Callable[[str], None]`, `max_timeout: float`, `settle_delay: float`

**Test Baseline**: 458 passed, 5 skipped, 7 xfailed
**Test Result**: 458 passed, 5 skipped, 7 xfailed — no regressions

**Documentation & State Updates**:
- [x] Feature implementation state file (1.1.1) updated, or N/A — type annotations don't change component lists or architecture: _N/A_
- [x] TDD (1.1.1) updated, or N/A — no interface/design changes, only type hints added: _N/A_
- [x] Test spec (1.1.1) updated, or N/A — no behavior change: _N/A_
- [x] FDD (1.1.1) updated, or N/A — no functional change: _N/A_
- [x] ADR updated, or N/A — no architectural decision affected: _N/A_
- [x] Foundational validation tracking (1.1.1) updated via Update-TechDebt.ps1 -FoundationalNote
- [x] Technical Debt Tracking: TD060 marked resolved

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD060 | Complete | None | None (type annotations only) |

## Related Documentation
- [Technical Debt Tracking](/doc/product-docs/state-tracking/permanent/technical-debt-tracking.md)
