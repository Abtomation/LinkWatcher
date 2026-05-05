---
id: PD-REF-212
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-29
updated: 2026-04-29
mode: lightweight
feature_id: 4.1.1
priority: Low
target_area: test/automated/performance/test_large_projects.py
debt_item: TD244
refactoring_scope: Switch time.time() to time.perf_counter() across PH tests in test_large_projects.py (TD244)
---

# Lightweight Refactoring Plan: Switch time.time() to time.perf_counter() across PH tests in test_large_projects.py (TD244)

- **Target Area**: test/automated/performance/test_large_projects.py
- **Priority**: Low
- **Created**: 2026-04-29
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Debt Item**: TD244
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD244 — Switch `time.time()` → `time.perf_counter()` across PH tests

**Scope**: Replace all `time.time()` call sites with `time.perf_counter()` across the 6 PH tests in `test_large_projects.py` that perform wall-clock timing (PH-001 through PH-006). PH-007 (`test_memory_usage_monitoring`) and PH-008 (`test_cpu_usage_monitoring`) measure RAM/CPU instead of elapsed time, so no `time.time()` calls exist there. `perf_counter` is monotonic and sub-microsecond; `time.time()` Windows resolution (~15ms) is at or above measurements like PH-002 move (40-50ms). Pure symbol replacement — no semantic change to what is measured. Mirror of [PD-REF-196 Item 1 (TD217)](/doc/refactoring/plans/archive/tighten-bm-002-bm-006-tolerances-add-warmups-switch-to-perf.md) which applied the same change to BM tests on 2026-04-28 with no bugs.

**Verified scope vs. TD244 description**:
- TD244 says "~14 call sites" → actual is **24 call sites** (6 in PH-001, 4 in PH-002, 4 in PH-003, 6 in PH-004, 2 in PH-005, 2 in PH-006).
- TD244 says "all 8 PH tests" → only **6 PH tests** use `time.time()` (PH-007 and PH-008 are RAM/CPU tests, not wall-clock timed).

**Changes Made**:
- [x] Replaced all 24 `time.time()` occurrences with `time.perf_counter()` across PH-001..PH-006 (single Edit replace_all). Post-edit grep: 0 `time.time()` remaining, 24 `time.perf_counter()` present.
- [x] No `import time` change required (module already imported)

**Test Baseline** (2026-04-29):
- Full no-slow suite (`pytest -m "not slow"`): **831 passed, 0 failed**, 3 skipped, 4 deselected, 4 xfailed in 98.37s
- PH tests (slow, file under refactoring): **8 passed, 0 failed** in 76.07s

**Test Result** (2026-04-29, post-refactor):
- PH tests in file (`pytest test/automated/performance/test_large_projects.py`): **8 passed, 0 failed** in 76.53s — same as baseline.
- Full no-slow suite: **830 passed, 1 failed** in 96.10s. Failure: `test_cpu_usage_monitoring` (PH-008) at line 618 (`assert max_cpu < 95`, observed 98.2%).
- Re-run of `test_cpu_usage_monitoring` in isolation: **PASSED** in 22.89s. Flaky under concurrent load.

**L7 Diff vs L3 Baseline**:
- PH file run: 8/8 passed → 8/8 passed (no delta)
- No-slow suite: 831/0 → 830/1 (PH-008 flaky failure under load)
- The failed test (PH-008 / `test_cpu_usage_monitoring`) does NOT use `time.time()` or `time.perf_counter()` — it measures CPU via `psutil.cpu_percent`. The refactoring cannot have caused this failure. The failure is environmental: PH-008 runs unmarked-as-slow, so it executes alongside hundreds of other tests in the no-slow run; under that concurrent load, system CPU samples occasionally cross the 95% threshold. This brittleness is consistent with the broader Criterion 1 findings of audit TE-TAR-070 (cold-start contamination, measurement isolation) that produced TD245/TD246 — pre-existing latent flakiness exposed by load, not regression caused by this session.

**Test Coverage Assessment (L4)**: Sufficient. The 8 PH tests in `test_large_projects.py` are the tests being modified — they are self-verifying. `time.time()` → `time.perf_counter()` does not change semantics (both return monotonically-non-decreasing seconds with sub-second precision); the same elapsed-time assertions and tolerance thresholds apply. No characterization tests needed.

**Documentation & State Updates**:
<!-- Test-only shortcut applies: items 1-7 batched as N/A. -->
- N/A items 1–7: *Test-only refactoring — no production code changes; design and state documents (feature state 4.1.1, TDD, test spec, FDD, ADR, integration narrative, validation tracking) do not reference test internals.*
- [ ] Technical Debt Tracking: TD244 marked Resolved
- [ ] Audit closure check (TE-TAR-070): TD245 and TD246 from same audit remain Open after this work — audit closure is **partial**, route to PF-TSK-030 re-audit instead of marking "Audit Approved".

**Bugs Discovered**: [PD-BUG-097](/doc/state-tracking/permanent/bug-tracking.md) — `test_cpu_usage_monitoring` (PH-008) flaky under concurrent load. Pre-existing latent fragility unrelated to perf_counter migration; PH-008 uses `psutil.cpu_percent`, not `time.time()`. Severity: Low.

**TD Resolution**: TD244 → Resolved via `Update-TechDebt.ps1` 2026-04-29.

**Audit Closure Check (TE-TAR-070)**: **Partial** — TD245 and TD246 from same audit remain Open. Per [Code Refactoring Lightweight Path L10](/process-framework/tasks/06-maintenance/code-refactoring-lightweight-path.md): "If findings are only partially addressed — do NOT mark as 'Audit Approved'. Route to PF-TSK-030 for re-audit instead." `Update-TestFileAuditState.ps1` not invoked. Audit will be re-evaluated when remaining findings are resolved.

<!-- BATCH MODE: Copy the "## Item N" section above for each additional debt item in this session -->

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD244 | Complete | PD-BUG-097 (unrelated flaky test) | None — test-only refactoring |

## L7 Regression Diff Summary

| Metric | L3 (pre) | L7 (post) | Delta |
|--------|----------|-----------|-------|
| PH file: passed | 8 | 8 | 0 |
| PH file: failed | 0 | 0 | 0 |
| No-slow suite: passed | 831 | 830 | -1 |
| No-slow suite: failed | 0 | 1 | +1 (PH-008, flaky CPU; verified passes in isolation) |
| No-slow suite: skipped | 3 | 3 | 0 |
| No-slow suite: xfailed | 4 | 4 | 0 |

**Failure delta**: PH-008 (`test_cpu_usage_monitoring`) passes alone (22.89s) but fails under concurrent suite load (98.2% > 95% threshold). Test does not use `time.time()` or `time.perf_counter()` — uses `psutil.cpu_percent`. Refactoring cannot have caused this. Tracked as PD-BUG-097.

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
