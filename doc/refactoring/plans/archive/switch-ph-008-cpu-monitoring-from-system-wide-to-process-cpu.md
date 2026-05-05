---
id: PD-REF-217
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-29
updated: 2026-04-29
refactoring_scope: Switch PH-008 CPU monitoring from system-wide to process CPU
priority: High
target_area: test/automated/performance/test_large_projects.py PH-008
mode: lightweight
debt_item: TD247
---

# Lightweight Refactoring Plan: Switch PH-008 CPU monitoring from system-wide to process CPU

- **Target Area**: test/automated/performance/test_large_projects.py PH-008
- **Priority**: High
- **Created**: 2026-04-29
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Debt Item**: TD247 (+ TD249 PH-008 sub-item, pulled in during L7)
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD247 — PH-008 measures system-wide CPU instead of LinkWatcher process CPU (+ TD249 PH-008 sub-item)

**Scope**: PH-008 (`test_cpu_usage_monitoring` in [test_large_projects.py](/test/automated/performance/test_large_projects.py)) called `psutil.cpu_percent(interval=0.1)` inside its monitor thread, returning host-wide CPU. This decoupled the assertion (`max_cpu < 95`) from LinkWatcher behavior and caused a false-positive failure in audit TE-TAR-070 Run 2 (peak=100% from unrelated host load). Switch to a process-scoped handle (`process.cpu_percent(interval=0.1)` via `psutil.Process(os.getpid())`), mirroring the process-handle pattern used by PH-007. Dimension: TST (test integrity).

**Scope expansion at L7**: The literal TD247 prescription produced a unit mismatch — `process.cpu_percent` returns `cores * 100%` on multi-core hosts (regression run measured 117.6% peak, 64.2% avg), so the existing `[0, 100]`-scale thresholds failed. TD249's PH-008 sub-item ("Replace PH-008 peak < 95 with a process-CPU threshold or remove entirely") was already blocked-on-TD247 in the tracking notes, so its PH-008 portion was bundled into this session per Option B (user-approved). This narrows TD249 — its PH-008 entry is now resolved; the remaining 4 tolerance-tightening items are unaffected.

**Changes Made**:
- [x] Added `import os` at the top of `test_cpu_usage_monitoring` (function-scope)
- [x] Built `process = psutil.Process(os.getpid())` once after the warmup, before `monitor_thread.start()`
- [x] In `monitor_cpu()`, replaced `psutil.cpu_percent(interval=0.1)` with `process.cpu_percent(interval=0.1)` (closes over the `process` handle)
- [x] Added inline comment referencing TD247 / audit Criterion 1
- [x] Removed `assert max_cpu < 95` (peaks of interval samplers are unstable; per TD249 explicit guidance "or remove entirely")
- [x] Replaced `assert avg_cpu < 80` with `assert (avg_cpu / cpu_count) < 80` to preserve the `[0, 100]`-scale "process not pegging the machine" semantic on multi-core hosts
- [x] No priming call (was in original plan): with `interval=0.1` (blocking mode), psutil samples internally and the first call already returns a meaningful value — the prime would have been dead code.

**Test Coverage Assessment (L4)**: Test-only refactoring — the test under change *is* the test. No characterization tests needed.

**Test Baseline (L3)**: 834 passed, 3 skipped, 4 deselected (slow), 4 xfailed, 0 failed in 98.69s (`pytest -m "not slow"`). PH-008 was included in the baseline pass count (no `@pytest.mark.slow`).

**Test Result (L7)**: 838 passed, 3 skipped, 4 deselected, 4 xfailed, 0 failed in 97.01s. PH-008 specifically: PASSED in 21.95s. Net change vs baseline: +4 passes (parallel-session test additions in the same file), 0 new failures, 0 new errors. (Initial L7 run with `-p no:logging` produced 3 spurious `caplog`-fixture-not-found errors in `test_config.py`; re-ran without that flag — confirmed an artifact of the regression-run command, not the code change.)

**Documentation & State Updates**:
- [x] Items 1–7 batched as N/A — *Test-only refactoring — no production code changes; design and state documents do not reference test internals.* (Lightweight Path Test-only shortcut.)
- [x] Technical Debt Tracking: TD247 marked Resolved; TD249 description amended to remove its PH-008 sub-item (pulled into this session).
- [x] **Audit-flagged TD closure (TE-TAR-070)**: Partial — TD247 is one of multiple findings from TE-TAR-070 (TD244, TD246, TD247, TD248, TD249 all reference it). Per Lightweight Path L10 guidance, do **NOT** mark `Audit Approved`; route to re-audit (PF-TSK-030) once all TE-TAR-070 findings are resolved. No `Update-TestFileAuditState.ps1` call this session.

**Bugs Discovered**: None.

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD247 (+ TD249 PH-008 sub-item) | Complete | None | TD249 description amended to remove PH-008 sub-item |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
- [Audit Report TE-TAR-070](/test/audits/performance/) (referenced by TD247; re-audit deferred until all TE-TAR-070 findings resolved)
