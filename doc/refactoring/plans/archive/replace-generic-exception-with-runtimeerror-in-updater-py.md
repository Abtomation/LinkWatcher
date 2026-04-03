---
id: PD-REF-119
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-27
updated: 2026-03-27
target_area: linkwatcher/updater.py
refactoring_scope: Replace generic Exception with RuntimeError in updater.py
priority: Medium
mode: lightweight
---

# Lightweight Refactoring Plan: Replace generic Exception with RuntimeError in updater.py

- **Target Area**: linkwatcher/updater.py
- **Priority**: Medium
- **Created**: 2026-03-27
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD118 — Replace generic Exception with RuntimeError

**Scope**: Line 255 of `linkwatcher/updater.py` raises bare `Exception` in `_update_file_references()`. Change to `RuntimeError` for better error specificity. The caller (`update_references` line 103) catches `Exception`, so this is fully backward-compatible.

**Changes Made**:
<!-- Fill in after implementation -->
- [x] Changed `raise Exception(...)` to `raise RuntimeError(...)` on line 255

**Test Baseline**: 597 passed, 5 skipped, 7 xfailed
**Test Result**: 597 passed, 5 skipped, 7 xfailed — no regressions

**Documentation & State Updates**:
<!-- Check each — for N/A, write brief justification (e.g., "Grepped TDD — no references to changed method") -->
- [x] Feature implementation state file (2.2.1) updated, or N/A — verified no reference to changed component: _Grepped state file — no mention of Exception type or line 255_
- [x] TDD (2.2.1) updated, or N/A — verified no interface/design changes documented: _TDD references `_update_file_references` but only documents return type and algorithm, not exception types_
- [x] Test spec (2.2.1) updated, or N/A — verified no behavior change affects spec: _Grepped test spec — no references to exception types_
- [x] FDD (2.2.1) updated, or N/A — verified no functional change affects FDD: _Grepped FDD — no references to exception types_
- [x] ADR updated, or N/A — verified no architectural decision affected: _Grepped ADR directory — no references to updater exception handling_
- [x] Validation tracking updated, or N/A — verified change doesn't affect validation: _Internal exception type change, no validation impact_
- [x] Technical Debt Tracking: TD118 marked resolved via Update-TechDebt.ps1

**Bugs Discovered**: None

<!-- BATCH MODE: Copy the "## Item N" section above for each additional debt item in this session -->

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD118 | Complete | None | None |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
