---
id: PD-REF-216
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-29
updated: 2026-04-29
mode: lightweight
priority: Medium
target_area: test/automated/performance/test_large_projects.py
feature_id: 4.1.1
debt_item: TD246
refactoring_scope: Add warmup cycles to all 8 PH tests in test_large_projects.py
---

# Lightweight Refactoring Plan: Add warmup cycles to all 8 PH tests in test_large_projects.py

- **Target Area**: test/automated/performance/test_large_projects.py
- **Priority**: Medium
- **Created**: 2026-04-29
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Debt Item**: TD246
- **Mode**: Lightweight (no architectural impact)

## Shared Context

All 8 PH tests in [test/automated/performance/test_large_projects.py](/test/automated/performance/test_large_projects.py) lack warmup cycles before their timed measurements. Each test's first call to `service._initial_scan()` (or first move/sampling event for PH-005/006/007/008) is exposed to cold-start effects: import init, module loading, filesystem cache priming, JIT, and thread pool startup. Audit [TE-TAR-070](/test/audits/performance/audit-report-4-1-1-test-large-projects.md) Criterion 1 documented this as the dominant cause of first-iteration inflation (PH-001 Run 1 16.01s vs Run 2 9.58s = 67% inflation).

This refactoring mirrors the warmup work done for BM tests in [PD-REF-196](tighten-bm-002-bm-006-tolerances-add-warmups-switch-to-perf.md) (Item 2, TD216) — same problem class, same fix pattern (external `tempfile.TemporaryDirectory()` warmup, then discard, then run the actual timed window).

**Documentation & State Updates (test-only shortcut applies)**: Items 1–7 (feature state, TDD, test spec, FDD, ADR, integration narrative, validation tracking) batched as N/A — *Test-only refactoring — no production code changes; design and state documents do not reference test internals.* Item 8 (Technical Debt Tracking) checked individually below.

---

## Item 1: TD246 — Add warmup cycles to all 8 PH tests

**Scope**: Insert a service-instantiation + initial-scan warmup against an *external* `tempfile.TemporaryDirectory()` before the timed window of each PH test, so import init / filesystem cache / module load costs are excluded from the measurement. The warmup tempdir must NOT be inside `temp_project_dir` to avoid the warmup files contaminating the test's actual scan (this defect was caught and self-corrected in PD-REF-196 / TD216 BM warmup work).

Per-test warmup design:
- **PH-001/002/003**: Warm up service + `_initial_scan()` against external tempdir before the timed scan. (PH-001 also has a timed move; the same warmed service primes the move path.)
- **PH-004**: Warm up service + scan + one move event against external tempdir before the timed move (popular file with 200+ references).
- **PH-005**: Warm up service + scan + a few rapid move events against external tempdir before the timed loop.
- **PH-006**: Warm up service + scan + a small directory-move event against external tempdir before the timed batch detection.
- **PH-007 (memory)**: Warm up service + scan against external tempdir before measuring `initial_memory`, so first-time module/code allocations are amortized away from the `memory_increase` window. Cleanly delete the warmup service to release its references before measuring.
- **PH-008 (CPU)**: Warm up service + scan against external tempdir before starting the `cpu_monitor` thread, so first-time CPU costs are excluded from the sampling window.

**Changes Made**:
- [x] Added `import tempfile` and `from pathlib import Path` at module level
- [x] Added `_warmup_service(num_files, num_moves, dir_move)` module-level helper that uses an external `tempfile.TemporaryDirectory()`, instantiates a separate `LinkWatcherService`, runs `_initial_scan()`, optionally exercises move events, and optionally exercises a directory-move event
- [x] PH-001 warmup added (`num_files=5, num_moves=1`) — primes scan + move
- [x] PH-002 warmup added (`num_files=5, num_moves=1`) — primes scan + move
- [x] PH-003 warmup added (`num_files=5`) — primes scan only (no timed move in PH-003)
- [x] PH-004 warmup added (`num_files=5, num_moves=1`) — primes scan + move (popular-file move)
- [x] PH-005 warmup added (`num_files=5, num_moves=3`) — primes scan + multiple moves
- [x] PH-006 warmup added (`num_files=5, dir_move=True`) — primes scan + directory-batch event
- [x] PH-007 warmup added (`num_files=5`) — placed BEFORE `initial_memory` measurement so first-time module/code allocations don't inflate `memory_increase`
- [x] PH-008 warmup added (`num_files=5, num_moves=1`) — placed BEFORE `cpu_monitor` thread starts so first-time CPU costs aren't counted in the sampling window

**Test Baseline (L3, 2026-04-29)**: `838 passed, 3 skipped, 4 xfailed, 0 failed in 114.70s` (full suite via `python -m pytest test/automated/`, includes slow tests). No pre-existing failures.

**Test Result (L7, 2026-04-29)**: `838 passed, 3 skipped, 4 xfailed, 0 failed in 119.51s` — **identical pass/fail counts**. Time delta +4.81s, consistent with ~600ms warmup overhead × 8 tests. All 8 PH tests pass standalone in 76.70s.

**Documentation & State Updates**:
- [x] Feature implementation state file (4.1.1) updated, or N/A: _Test-only shortcut — see Shared Context._
- [x] TDD (4.1.1) updated, or N/A: _Test-only shortcut — see Shared Context._
- [x] Test spec (4.1.1) updated, or N/A: _Test-only shortcut — see Shared Context._
- [x] FDD (4.1.1) updated, or N/A: _Test-only shortcut — see Shared Context._
- [x] ADR (4.1.1) updated, or N/A: _Test-only shortcut — see Shared Context._
- [x] Integration Narrative updated, or N/A: _Test-only shortcut — see Shared Context._
- [x] Validation tracking updated, or N/A: _Test-only shortcut — see Shared Context._
- [ ] Technical Debt Tracking: TD246 marked resolved (will be done at L10 via `Update-TechDebt.ps1`)

**Bugs Discovered**: None.

**TD Resolution**: TD246 → Resolved.

<!-- BATCH MODE: Copy the "## Item N" section above for each additional debt item in this session -->

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD246 | Complete | None | None (test-only shortcut) |

## L7 Regression Diff Summary

| Metric | L3 baseline | L7 post | Delta |
|--------|-------------|---------|-------|
| Passed | 838 | 838 | 0 |
| Failed | 0 | 0 | 0 |
| Skipped | 3 | 3 | 0 |
| xfailed | 4 | 4 | 0 |
| Wall time | 114.70s | 119.51s | +4.81s |

The +4.81s delta is consistent with ~600ms warmup overhead × 8 PH tests. No regressions; identical pass/fail outcomes across the suite.

## Audit Loop Status

Audit [TE-TAR-070](/test/audits/performance/audit-report-0-1-1-test-large-projects.md) is **NOT closed as Audit Approved**. TD247 (PH-008 process CPU), TD248 (PH-005 sleep inside loop), TD249 (tighten tolerances), and TD250 (psutil dependency) are still open from this audit, plus TD244 follow-up. Audit Status remains `🔄 Needs Update` per [Code Refactoring Lightweight Path L10](/process-framework/tasks/06-maintenance/code-refactoring-lightweight-path.md): "If findings are only partially addressed — do NOT mark as Audit Approved."

## Side-Effect: PH rows already flagged Needs Re-baseline

All 8 PH rows in [performance-test-tracking.md](/test/state-tracking/permanent/performance-test-tracking.md) were flagged ⚠️ Needs Re-baseline by audit TE-TAR-070 — no additional flag changes needed for this work. Handoff to [Performance Baseline Capture (PF-TSK-085)](/process-framework/tasks/03-testing/performance-baseline-capture-task.md) will run after the remaining PH-related TDs (TD247, TD248) are resolved.

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
- [TE-TAR-070 audit report](/test/audits/performance/audit-report-0-1-1-test-large-projects.md)
- [PD-REF-196 — BM warmup precedent](tighten-bm-002-bm-006-tolerances-add-warmups-switch-to-perf.md)
