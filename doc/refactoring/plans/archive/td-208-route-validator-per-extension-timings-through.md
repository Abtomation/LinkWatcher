---
id: PD-REF-190
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-09
updated: 2026-04-09
refactoring_scope: TD-208: Route validator per-extension timings through PerformanceLogger.log_metric()
mode: lightweight
target_area: Validator
priority: Medium
---

# Lightweight Refactoring Plan: TD-208: Route validator per-extension timings through PerformanceLogger.log_metric()

- **Target Area**: Validator
- **Priority**: Medium
- **Created**: 2026-04-09
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD208 — Route validator per-extension timings through PerformanceLogger.log_metric()

**Scope**: `validator.py:248-286` accumulates per-extension validation timings in a local `defaultdict` and emits them via a plain `logger.debug()` call. This bypasses the standard `PerformanceLogger.log_metric()` pipeline used by all other components (e.g., `dir_move_detector.py`, `move_detector.py`). Change: emit each extension's cumulative timing via `self.logger.performance.log_metric()` so timing data enters the standard metric pipeline. Dims: OB (Observability).

**Changes Made**:
<!-- Fill in after implementation -->
- [x] Replace `self.logger.debug("validation_timing_by_extension", ...)` with per-extension `self.logger.performance.log_metric()` calls at validator.py:279-285

**Test Baseline**: 767 passed, 5 skipped, 4 xfailed, 0 failures
**Test Result**: 767 passed, 5 skipped, 4 xfailed, 0 failures — identical to baseline, zero regressions

**Documentation & State Updates**:
- [x] Feature implementation state file (6.1.1, 3.1.1) updated, or N/A: _Tier 1 features — no design documents exist for Link Validation or Logging Framework._
- [x] TDD updated, or N/A: _Tier 1 feature — no TDD exists for 6.1.1 Link Validation._
- [x] Test spec updated, or N/A: _Tier 1 feature — no behavior change affects spec._
- [x] FDD updated, or N/A: _Tier 1 feature — no FDD exists for 6.1.1 Link Validation._
- [x] ADR updated, or N/A: _Tier 1 feature — no architectural decision affected._
- [x] Validation tracking updated, or N/A: _Change doesn't affect validation tracking._
- [x] Technical Debt Tracking: TD208 marked resolved via Update-TechDebt.ps1

**Bugs Discovered**: None

<!-- BATCH MODE: Copy the "## Item N" section above for each additional debt item in this session -->

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD208 | Complete | None | None (Tier 1 — no design docs) |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
