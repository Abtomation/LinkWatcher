---
id: PD-REF-143
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-02
updated: 2026-04-02
mode: lightweight
priority: Medium
refactoring_scope: Add per-file DEBUG timing to validation scan
target_area: LinkValidator
---

# Lightweight Refactoring Plan: Add per-file DEBUG timing to validation scan

- **Target Area**: LinkValidator
- **Priority**: Medium
- **Created**: 2026-04-02
- **Author**: AI Agent & Human Partner
- **Status**: Planning
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD145 — Add per-file DEBUG timing to validation scan

**Scope**: Add optional DEBUG-level per-file timing within `LinkValidator.validate()` and an aggregate timing summary by file extension. Currently only total scan duration is logged — diagnosing slow validation requires external profiling. Dimension: OB (Observability).

**Changes Made**:
- [x] Added `collections.defaultdict` import
- [x] Added `ext_timings` dict to track per-extension cumulative timing
- [x] Wrapped `_check_file()` call with `time.monotonic()` and DEBUG log (`validation_file_checked`)
- [x] Added aggregate timing-by-extension DEBUG log (`validation_timing_by_extension`) after scan loop

**Test Baseline**: 656 passed, 5 skipped, 6 xfailed
**Test Result**: 656 passed, 5 skipped, 6 xfailed (identical)

**Documentation & State Updates**:
- [x] Feature implementation state file (6.1.1) updated, or N/A — _N/A: grepped state file — no references to validate() internals or timing; state file tracks high-level feature status only_
- [x] TDD (6.1.1) updated, or N/A — _N/A: no TDD exists for 6.1.1 (no PD-TDD for Link Validation)_
- [x] Test spec (6.1.1) updated, or N/A — _N/A: no test spec exists for 6.1.1; grepped feature-specs — no references to validate() or _check_file()_
- [x] FDD (6.1.1) updated, or N/A — _N/A: no FDD exists for 6.1.1 (no PD-FDD for Link Validation)_
- [x] ADR (6.1.1) updated, or N/A — _N/A: no ADR references validation timing — grepped ADR directory_
- [x] Validation tracking updated, or N/A — _N/A: 6.1.1 is tracked in R3 but all dimensions COMPLETE; additive DEBUG logging doesn't affect validation scores_
- [ ] Technical Debt Tracking: TD item marked resolved

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD145 | Complete | None | None |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)

