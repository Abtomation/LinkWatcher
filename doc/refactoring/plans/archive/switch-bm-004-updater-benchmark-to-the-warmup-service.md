---
id: PD-REF-235
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-06-04
updated: 2026-06-04
target_area: Performance benchmarks (test_component_benchmarks.py)
debt_item: TD259
refactoring_scope: Switch BM-004 updater benchmark to the warmup_service fixture to remove inlined warmup duplication
priority: Medium
mode: lightweight
---

# Lightweight Refactoring Plan: Switch BM-004 updater benchmark to the warmup_service fixture to remove inlined warmup duplication

- **Target Area**: Performance benchmarks (test_component_benchmarks.py)
- **Priority**: Medium
- **Created**: 2026-06-04
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Debt Item**: TD259
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD259 — Replace inlined warmup block in BM-004 with the `warmup_service` fixture

**Dims**: TST (test-code maintainability / DRY)

**Scope**: `test_bm_004_updater_throughput` (BM-004) inlines a 14-line warmup block (local `import tempfile`, external tempdir, `warmup_target.txt` + 5 `warmup_src_{i}.md` files, `LinkWatcherService` + `_initial_scan()`) that exactly duplicates the `warmup_service` factory fixture in `performance/conftest.py`. Verified line-by-line that `warmup_service(num_files=5)` (i.e. `num_moves=0, dir_move=False`) is behavior-equivalent — same file-content strings, same external-tempdir isolation, and the `num_moves`/`dir_move` branches are skipped. BM-004 is the only performance test still inlining this; the other 9 call sites (level2 / level3 ×6 / level4 ×2) already use the fixture. Replace the inlined block with `warmup_service(num_files=5)`, add the fixture as a test parameter, and drop the now-dead local `import tempfile`.

**Changes Made**:
- [x] Added `warmup_service` fixture parameter to `test_bm_004_updater_throughput` ([test_component_benchmarks.py:187](../../../../test/automated/performance/level1-component/test_component_benchmarks.py#L187))
- [x] Replaced the 14-line inlined warmup block (incl. local `import tempfile`) with `warmup_service(num_files=5)` — net −13 lines. The original `import time` / `from pathlib import Path` module imports are retained (still used elsewhere in the file).

**L4 (test coverage)**: Test-only refactoring — coverage assessment N/A; the modified benchmark verifies its own behavior (throughput assertion `files_per_sec > 10` + `"moved/target.txt" in sample`).

**Test Baseline** (L3, captured 2026-06-04 before changes; same commands re-run at L7):
- Target file (`pytest test/automated/performance/level1-component/test_component_benchmarks.py -v`): **3 passed in 4.72s** (BM-001, BM-002, BM-004) — 0 failed.
- Broader suite (`Run-Tests.ps1 -All`): **842 passed, 3 skipped, 6 deselected, 4 xfailed in 43.56s** — 0 failed, 0 errors.
- Pre-existing failures: **none**.

**Test Result** (L7, same commands as L3 baseline):
- Target file: **3 passed in 4.80s** — BM-004 green, identical to baseline.
- Broader suite (`Run-Tests.ps1 -All`): **842 passed, 3 skipped, 6 deselected, 4 xfailed in 42.83s** — diff vs baseline = **0 new failures, 0 new errors**.
- `Validate-TestTracking.ps1`: **0 errors** (35 pre-existing warnings, none on `test_component_benchmarks.py`; its count unchanged at 3).
- E2E re-execution: N/A — BM-004 is a performance benchmark, no E2E acceptance tests cover benchmark internals.

**Documentation & State Updates**:
Items 1–8 batched N/A under the **test-only shortcut**: *Test-only refactoring — no production code changes; the warmup setup is now sourced from an existing shared fixture. Design (TDD/FDD/ADR), test-spec, integration-narrative, user-doc, and validation-tracking surfaces do not reference test-internal warmup scaffolding.*
- [x] Feature implementation state file — N/A (test-only shortcut)
- [x] TDD — N/A (test-only shortcut)
- [x] Test spec — N/A (test-only shortcut)
- [x] FDD — N/A (test-only shortcut)
- [x] ADR — N/A (test-only shortcut)
- [x] Integration Narrative — N/A (test-only shortcut)
- [x] User documentation — N/A (test-only shortcut)
- [x] Validation tracking — N/A (test-only shortcut)
- [x] Test tracking files (performance-test-tracking.md) — N/A: verified BM-004 row's mirrored values (threshold `>10 files/sec`, scope `50 files, 50 refs`, baseline `65.1 files/sec`) are unchanged; warmup-source is internal scaffolding, not a tracked column. Audit Status already `✅ Audit Approved`.
- [x] Technical Debt Tracking: TD259 marked Resolved — done at L11.

**Bugs Discovered**: None

<!-- BATCH MODE: Use `-ItemCount N` when running New-RefactoringPlan.ps1 to pre-generate N Item sections up front. To add more debt items mid-session (i.e., new TD IDs — sub-findings of an existing TD become additional `Changes Made` bullets within its Item, not new Items), copy the "## Item N" section above. -->

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD259 | Complete | None | None (test-only — items 1–9 N/A; TD259 resolved) |

**Net effect**: BM-004 now uses the `warmup_service(num_files=5)` fixture like all 9 sibling performance call sites; −13 lines of duplicated warmup scaffolding and a dead local `import tempfile` removed. Behavior preserved (regression diff clean vs baseline). Audit TE-TAR-073 was already `✅ Audit Approved` (TD259 was a non-blocking follow-up), so no audit-status closure was required.

## Related Documentation
- [Technical Debt Tracking](../../../state-tracking/permanent/technical-debt-tracking.md)
