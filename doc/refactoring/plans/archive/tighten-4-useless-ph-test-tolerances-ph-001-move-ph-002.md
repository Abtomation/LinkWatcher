---
id: PD-REF-220
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-29
updated: 2026-04-29
debt_item: TD249
refactoring_scope: Tighten 4 useless PH-test tolerances (PH-001 move, PH-002 scan/move, PH-006) to guide-aligned 5-10x ratios
mode: lightweight
feature_id: 4.1.1
target_area: test_large_projects.py
priority: Medium
---

# Lightweight Refactoring Plan: Tighten 4 useless PH-test tolerances (PH-001 move, PH-002 scan/move, PH-006) to guide-aligned 5-10x ratios

- **Target Area**: test_large_projects.py
- **Priority**: Medium
- **Created**: 2026-04-29
- **Author**: AI Agent & Human Partner
- **Status**: Planning
- **Debt Item**: TD249
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD249 — Tighten 4 useless PH-test tolerances

**Scope**: Tighten 4 PH-test tolerance assertions in `test/automated/performance/test_large_projects.py` from 30x-60x of the post-warmup measured baselines to guide-aligned 5-10x ratios. The current loose tolerances are decoupled from real performance — a 10x regression would still pass them, defeating the point of the assertion. Mirror of TD215 / PD-REF-196 work for BM tests. **Dim**: TST. The fix changes only test thresholds (numeric constants); no production code is affected.

**Post-warmup baselines** (single measurement, 2026-04-29, on the post-TD244+TD246 code; PF-TSK-085 re-baseline still pending and will replace these as authoritative):

| Test | Line | Baseline | Current Tolerance | Current Ratio | New Tolerance | New Ratio |
|---|---|---|---|---|---|---|
| PH-001 move | 159 | 0.14s | <5.0s | 35.7x | **<1.0s** | 7.1x |
| PH-002 scan | 209 | 0.19s | <10.0s | 52.6x | **<1.0s** | 5.3x |
| PH-002 move | 226 | 0.05s | <3.0s | 60.0x | **<0.5s** | 10.0x |
| PH-006 directory batch | 533 | 0.95s | <30.0s | 31.6x | **<5.0s** | 5.3x |

PH-008 sub-item from TD249's original description is excluded — already resolved bundled with TD247 (PD-REF-217).

**Changes Made**:
- [x] Line 159 (PH-001 move): `assert move_time < 5.0` → `assert move_time < 1.0` (7.1x of 0.14s baseline)
- [x] Line 209 (PH-002 scan): `assert scan_time < 10.0` → `assert scan_time < 1.0` (5.3x of 0.19s baseline)
- [x] Line 226 (PH-002 move): `assert move_time < 3.0` → `assert move_time < 0.5` (10.0x of 0.05s baseline; looser due to sub-100ms OS noise)
- [x] Line 533 (PH-006): `assert elapsed < 30.0, ...` → `assert elapsed < 5.0, ...` (5.3x of 0.95s baseline)

**Test Baseline** (2026-04-29, `pytest test/automated/ -m "not slow"`, 105.69s): 838 passed, 3 skipped, 4 deselected (slow), 4 xfailed, 0 failed, 0 errors. PH-002 (not marked slow) included and passed at current loose tolerance. PH-001, PH-005, PH-006 (slow) deselected; verified separately by running the 3 PH tests in scope manually — all passed.
**Test Result** (post-change, 2026-04-29):
- PH-001/PH-002/PH-006 modified tests verified individually: all 3 PASSED in 16.14s.
- Full non-slow suite: 838 passed, 3 skipped, 4 deselected, 4 xfailed, 0 failed — **identical to baseline**.
- Diff vs baseline: no new failures, no regressions.

**Documentation & State Updates**:
<!-- Test-only refactoring shortcut: items 1–7 batched as N/A; item 8 individually -->
- [x] Items 1–7 (Feature state, TDD, test spec, FDD, ADR, Integration Narrative, Validation tracking): N/A — *Test-only refactoring — no production code changes; design and state documents do not reference test internals or these specific tolerance constants.*
- [ ] Technical Debt Tracking: TD249 marked Resolved

**Bugs Discovered**: None.

<!-- BATCH MODE: Copy the "## Item N" section above for each additional debt item in this session -->

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD249 | Complete | None | None (test-only refactoring shortcut applied) |

**Notes for follow-up (PF-TSK-085 baseline re-capture)**: The new tolerances were chosen against single-run post-warmup measurements taken on 2026-04-29 (PH-001 move 0.14s, PH-002 scan 0.19s, PH-002 move 0.05s, PH-006 0.95s). When PF-TSK-085 captures multi-run authoritative baselines for PH-001..PH-006 against the post-TD244+TD246 code, the tolerance:baseline ratios may need a minor adjustment to stay in the guide's 3-5x band. The PH-002 move 10x ratio is intentional (sub-100ms; OS noise dominates) and should likely stay loose even after re-baseline.

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
