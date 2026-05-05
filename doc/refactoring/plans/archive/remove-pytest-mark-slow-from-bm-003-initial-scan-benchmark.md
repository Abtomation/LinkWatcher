---
id: PD-REF-201
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-29
updated: 2026-04-29
refactoring_scope: TE-TAR-066 audit follow-up bookkeeping — resolve TD219/TD240 (BM-003 slow marker) and close the audit-trail loop on TD236/TD237/TD238/TD239 (already implemented via PD-REF-196 but not marked resolved)
debt_item: TD219,TD240,TD236,TD237,TD238,TD239
mode: lightweight
target_area: test/automated/performance/test_benchmark.py + doc/state-tracking/permanent/technical-debt-tracking.md
priority: Low
---

# Lightweight Refactoring Plan: TE-TAR-066 audit follow-up bookkeeping (TD219/TD236/TD237/TD238/TD239/TD240)

- **Target Area**: test/automated/performance/test_benchmark.py + technical-debt-tracking.md
- **Priority**: Low
- **Created**: 2026-04-29
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Debt Items**: TD219, TD240, TD236, TD237, TD238, TD239
- **Mode**: Lightweight (no architectural impact)

## Shared Context

All six items target audit [TE-TAR-066](/test/audits/performance/audit-report-2-1-1-test-benchmark.md) on `test_benchmark.py`. Item 1 is the only one with code work — a single decorator removal for BM-003. Items 2–6 are **bookkeeping cleanup** to close audit-trail loops:

- **TD240** is a verbatim duplicate of TD219 (created 2 days later from the same audit report).
- **TD236/237/238/239** describe code work that was already implemented on 2026-04-28 via [PD-REF-196](/doc/refactoring/plans/archive/tighten-bm-002-bm-006-tolerances-add-warmups-switch-to-perf.md) (commit 130b3ea). PD-REF-196 marked four corresponding rows resolved as **TD215, TD216, TD217, TD218** (lines 263–266 of the Recently Resolved table). Each of TD236/237/238/239 is therefore a duplicate of an already-resolved item:

| Open (duplicate) | Resolved (canonical) | Description |
|---|---|---|
| TD239 | TD218 | BM-001 code assertion reconcile (elapsed → throughput) |
| TD238 | TD217 | Switch `time.time()` → `time.perf_counter()` |
| TD237 | TD216 | Add warmup cycles to BM-002/004/005/006 |
| TD236 | TD215 | Tighten BM-002/006 tolerances |

**Strategy for Items 3–6**: mark TD236/237/238/239 Resolved via `Update-TechDebt.ps1 -NewStatus Resolved` with cross-reference notes pointing at TD215–218. This follows the established duplicate-discharge precedent (TD221/TD222/TD225/TD230 resolved 2026-04-28). No manual row repair needed — earlier observation of "broken ID columns" was inaccurate; current file state has proper TD IDs in those rows.

## Item 1: TD219 — Remove @pytest.mark.slow from BM-003 initial scan benchmark

**Scope**: BM-003 (`test_bm_003_initial_scan` at [test_benchmark.py:219](/test/automated/performance/test_benchmark.py#L219)) currently carries `@pytest.mark.slow`, but the test completes in ~2 seconds — well below the 10-second threshold the [Performance Testing Guide](/process-framework/guides/03-testing/performance-testing-guide.md) defines for the `slow` marker. The marker excludes the test from default test runs and creates noise in audit trails. Remove the single decorator line.

**Dimension** (TD219 Dims column): TST (Testing).

**Changes Made**:
- [x] Removed `@pytest.mark.slow` (was line 218) from `test_bm_003_initial_scan` in `test/automated/performance/test_benchmark.py`

**Test Result**: 815 passed, 5 skipped, 4 deselected, 5 xfailed, 0 failed. Diff vs baseline: **+1 passed, −1 deselected** (BM-003 moved from slow bucket to default run, completes in ~2s). No new failures. Pre-existing failures: none.

**Documentation & State Updates**:
<!-- Test-only refactoring shortcut applies (L8): items 1-7 batched as N/A -->
- [x] Items 1–7 batched as N/A — _Test-only refactoring — no production code changes; design and state documents do not reference test internals._
- [x] Technical Debt Tracking: TD219 marked Resolved via `Update-TechDebt.ps1` on 2026-04-29

**Bugs Discovered**: None.

---

## Item 2: TD240 — Duplicate of TD219 (BM-003 slow marker)

**Scope**: TD240 (created 2026-04-22 from audit TE-TAR-066 "Improvement Opportunities") is a verbatim duplicate of TD219 (created 2026-04-20 from the same audit). Same description, same target file, same fix. TD219 was created first, so TD240 is the duplicate.

**Dimension** (TD240 Dims column): TST (Testing).

**Changes Made**:
- [x] No code change — TD219's removal of `@pytest.mark.slow` resolves both items.

**Documentation & State Updates**:
- [x] Items 1–7 batched as N/A — _Bookkeeping resolution; no code changes; no design/state documents reference TD240._
- [x] Technical Debt Tracking: TD240 marked Resolved as duplicate of TD219 via `Update-TechDebt.ps1` on 2026-04-29.

**Bugs Discovered**: None.

---

## Item 3: TD236 — Duplicate of TD215 (BM-002/006 tolerances)

**Scope**: TD236 (open, created 2026-04-22) is a duplicate of **TD215** (resolved 2026-04-28 via PD-REF-196 Item 4 / commit 130b3ea). Same audit (TE-TAR-066 Criterion 2), same target file, same description ("Tighten BM-002 Adds/Updates and BM-006 tolerances to guide 3-5x baseline"). The work shipped under the TD215 ID; TD236 was created in parallel and never linked.

**Dimension** (TD236 Dims column): TST (Testing).

**Changes Made**:
- [x] No code change — already implemented via PD-REF-196 / commit 130b3ea on 2026-04-28 under TD215.
- [x] TD236 marked Resolved via `Update-TechDebt.ps1` on 2026-04-29 with cross-reference to TD215.

**Documentation & State Updates**:
- [x] Items 1–7 batched as N/A — _Bookkeeping cleanup only; underlying code changes already shipped via PD-REF-196._
- [x] Technical Debt Tracking: TD236 marked Resolved as duplicate of TD215.

**Bugs Discovered**: None.

---

## Item 4: TD237 — Duplicate of TD216 (warmup cycles)

**Scope**: TD237 (open, created 2026-04-22) is a duplicate of **TD216** (resolved 2026-04-28 via PD-REF-196 Item 2 / commit 130b3ea). Same audit (TE-TAR-066 Criterion 1), same description ("Add warmup cycles to BM-002, BM-004, BM-005, BM-006").

**Dimension** (TD237 Dims column): TST (Testing).

**Changes Made**:
- [x] No code change — already implemented via PD-REF-196 / commit 130b3ea on 2026-04-28 under TD216.
- [x] TD237 marked Resolved via `Update-TechDebt.ps1` on 2026-04-29 with cross-reference to TD216.

**Documentation & State Updates**:
- [x] Items 1–7 batched as N/A — _Bookkeeping cleanup only._
- [x] Technical Debt Tracking: TD237 marked Resolved as duplicate of TD216.

**Bugs Discovered**: None.

---

## Item 5: TD238 — Duplicate of TD217 (time.perf_counter switch)

**Scope**: TD238 (open, created 2026-04-22) is a duplicate of **TD217** (resolved 2026-04-28 via PD-REF-196 Item 1 / commit 130b3ea). Same audit (TE-TAR-066 Criterion 1), same description ("Switch time.time() to time.perf_counter() across all 6 BM tests"). Verified 2026-04-29: zero `time.time()` calls remain in `test_benchmark.py`; all 17 timing call sites use `time.perf_counter()`.

**Dimension** (TD238 Dims column): TST (Testing).

**Changes Made**:
- [x] No code change — already implemented via PD-REF-196 / commit 130b3ea on 2026-04-28 under TD217.
- [x] TD238 marked Resolved via `Update-TechDebt.ps1` on 2026-04-29 with cross-reference to TD217 and verification that zero `time.time()` calls remain in `test_benchmark.py`.

**Documentation & State Updates**:
- [x] Items 1–7 batched as N/A — _Bookkeeping cleanup only._
- [x] Technical Debt Tracking: TD238 marked Resolved as duplicate of TD217.

**Bugs Discovered**: None.

---

## Item 6: TD239 — Duplicate of TD218 (BM-001 assertion reconcile)

**Scope**: TD239 (open, created 2026-04-22) is a duplicate of **TD218** (resolved 2026-04-28 via PD-REF-196 Item 5 / commit 130b3ea). Same audit (TE-TAR-066 Criterion 2), same description ("Reconcile BM-001 code assertion — elapsed<10.0 → files_per_second>50").

**Dimension** (TD239 Dims column): TST (Testing).

**Changes Made**:
- [x] No code change — already implemented via PD-REF-196 / commit 130b3ea on 2026-04-28 under TD218.
- [x] TD239 marked Resolved via `Update-TechDebt.ps1` on 2026-04-29 with cross-reference to TD218.

**Documentation & State Updates**:
- [x] Items 1–7 batched as N/A — _Bookkeeping cleanup only._
- [x] Technical Debt Tracking: TD239 marked Resolved as duplicate of TD218.

**Bugs Discovered**: None.

## Test Baseline

Captured 2026-04-29 via `python -m pytest test/automated/ -m "not slow" --tb=no -q` (the same selection `Run-Tests.ps1 -All` uses):

- **814 passed**
- **5 skipped**
- **5 deselected** (slow-marked — includes BM-003)
- **5 xfailed**
- **0 failed**

No pre-existing failing tests.

**Expected delta after change**: BM-003 moves from "deselected" to "passed" → **815 passed, 4 deselected**, all other counts unchanged.

<!-- BATCH MODE: Copy the "## Item N" section above for each additional debt item in this session -->

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD219 | Complete | None | None (test-only refactoring) |
| 2 | TD240 (dup of TD219) | Complete | None | None |
| 3 | TD236 (dup of TD215) | Complete | None | None |
| 4 | TD237 (dup of TD216) | Complete | None | None |
| 5 | TD238 (dup of TD217) | Complete | None | None |
| 6 | TD239 (dup of TD218) | Complete | None | None |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
