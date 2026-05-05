---
id: PD-REF-218
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-29
updated: 2026-04-29
debt_item: TD248
mode: lightweight
target_area: test/automated/performance/test_large_projects.py
refactoring_scope: Remove sleep contamination from PH-005 timed loop
priority: Medium
---

# Lightweight Refactoring Plan: Remove sleep contamination from PH-005 timed loop

- **Target Area**: test/automated/performance/test_large_projects.py
- **Priority**: Medium
- **Created**: 2026-04-29
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Debt Item**: TD248
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD248 — Remove sleep from PH-005 timed loop

**Scope**: PH-005 (`test_ph_005_rapid_file_operations`) has `time.sleep(0.01)` inside the timed window between `start_time` (line 424) and `total_time` computation (line 439). With 50 iterations, this adds 0.5s of pure sleep contamination — ~13% of measured time in Run 2 (3.95s) — degrading performance regression detection sensitivity. The "simulate real-world timing" comment is not load-bearing: `service.handler.on_moved()` is synchronous, so inter-move spacing has no functional purpose. **Dimension**: TST (test code quality). **Approach**: Remove the sleep entirely (per checkpoint approval — Option A over the alternative of bookkeeping subtraction). Performance tests should measure max throughput; artificial throttling defeats the purpose. The performance assertions (`total_time < 30.0`, `avg_time_per_move < 0.5`) remain valid post-removal.

**Changes Made**:
- [x] Removed `time.sleep(0.01)` and the preceding `# Small delay to simulate real-world timing` comment from the timed loop in `test_ph_005_rapid_file_operations` (test_large_projects.py, was lines 436-437)

**Test Baseline**:
- Non-slow suite: 838 passed, 3 skipped, 0 failures, 4 xfailed, 4 deselected (93.82s)
- PH-005 (slow, run separately): PASSED in 5.26s

**Test Result**:
- Non-slow suite: **838 passed, 3 skipped, 0 failures, 4 xfailed, 4 deselected (97.58s)** — identical to baseline, **no regressions**.
- PH-005 (slow, run separately): **PASSED in 4.36s** — down from 5.26s baseline (~0.9s reduction, consistent with 0.5s sleep removal plus measurement variance). Confirms sleep contamination removed.

**Documentation & State Updates**:
<!-- Test-only shortcut applied per L8: items 1-7 batched as N/A -->
- [x] Items 1–7 (feature state file, TDD, test spec, FDD, ADR, integration narrative, validation tracking) — N/A: _Test-only refactoring — no production code changes; design and state documents do not reference test internals._
- [x] Technical Debt Tracking: TD248 marked resolved

**Bugs Discovered**: None

<!-- BATCH MODE: Copy the "## Item N" section above for each additional debt item in this session -->

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD248 | Complete | None | None (test-only refactor; items 1–7 N/A, item 8: TD248 resolved) |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
