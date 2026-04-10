---
id: PD-REF-186
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-09
updated: 2026-04-09
refactoring_scope: Add cumulative scan error counter to _initial_scan
target_area: Core Architecture
priority: Medium
feature_id: 0.1.1
mode: lightweight
debt_item: TD205
---

# Lightweight Refactoring Plan: Add cumulative scan error counter to _initial_scan

- **Target Area**: Core Architecture
- **Priority**: Medium
- **Created**: 2026-04-09
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Debt Item**: TD205
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD205 — Add cumulative scan error counter to _initial_scan

**Scope**: Add a `scan_errors` counter to `_initial_scan()` in `service.py`. Increment it in the except block alongside the existing per-file warning. Include `scan_errors` in the `scan_complete` log message so operators can assess scan health ratio. Dimension: OB (Observability).

**Changes Made**:
- [x] Add `scan_errors = 0` counter initialization (service.py:178)
- [x] Increment `scan_errors += 1` in except block (service.py:206)
- [x] Add `scan_errors=scan_errors` to `scan_complete` log call (service.py:215)

**Test Baseline**: 497 passed, 166 failed (pre-existing), 3 skipped, 4 deselected, 4 xfailed, 98 errors
**Test Result**: 763 passed, 5 skipped, 4 deselected, 4 xfailed — no new failures (pre-existing failures resolved by parallel session)

**Documentation & State Updates**:
- [x] Feature implementation state file (0.1.1) updated, or N/A: _Grepped state file — no references to `_initial_scan`, `scan_complete`, or `scan_errors`_
- [x] TDD (0.1.1) updated, or N/A: _TDD references `_initial_scan()` method signature but not log fields; no interface or design change — only added a counter variable and log field_
- [x] Test spec (0.1.1) updated, or N/A: _Grepped test spec — references `test_initial_scan` but no behavior change affects spec_
- [x] FDD (0.1.1) updated, or N/A: _No FDD exists for 0.1.1 (grepped functional-design directory — no hits)_
- [x] ADR (0.1.1) updated, or N/A: _ADR references orchestrator pattern, not scan logging details — no architectural decision affected_
- [x] Validation tracking updated, or N/A: _No validation tracking file found for 0.1.1_
- [x] Technical Debt Tracking: TD205 marked resolved via Update-TechDebt.ps1

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD205 | Complete | None | None |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
