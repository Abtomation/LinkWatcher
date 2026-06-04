---
id: PD-REF-231
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-06-04
updated: 2026-06-04
debt_item: TD254
mode: lightweight
priority: Low
target_area: Performance test suite (test/automated/performance/)
refactoring_scope: Split performance test files across their correct 4-level perf taxonomy dirs (TD254)
---

# Lightweight Refactoring Plan: Split performance test files across their correct 4-level perf taxonomy dirs (TD254)

- **Target Area**: Performance test suite (test/automated/performance/)
- **Priority**: Low
- **Created**: 2026-06-04
- **Author**: AI Agent & Human Partner
- **Status**: Implementation complete — pending L11 closure (re-audit flag, TD resolution, archive)
- **Debt Item**: TD254
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD254 — Split perf test files into their correct 4-level taxonomy dirs

**Scope**: During the MIG-005 test-tree reorg, `test_benchmark.py` (BM-001..008) was parked whole in `level2-operation/` and `test_large_projects.py` (PH-001..008) whole in `level3-scale/`, even though each file spans two perf-taxonomy levels. Split each file so every test lands in its correct level dir per the section assignments in [performance-test-tracking.md](../../../test/state-tracking/permanent/performance-test-tracking.md), extracting the two shared helpers (`create_benchmark_files`, `_warmup_service`) into a performance-scoped `conftest.py` as factory fixtures (required because the hyphenated level dirs are invalid Python packages, so module-import sharing is unavailable under `--import-mode=importlib`). Purely organizational: all test logic, assertions, tolerances, markers, and baselines are preserved verbatim.

**Level mapping** (authoritative source = tracking-file section headers):

| New file | Test IDs | Classes |
|----------|----------|---------|
| `level1-component/test_component_benchmarks.py` | BM-001, BM-002/007/008, BM-004 | TestParsingBenchmark, TestDatabaseBenchmark, TestUpdaterBenchmark |
| `level2-operation/test_operation_benchmarks.py` | BM-003, BM-005, BM-006 | TestInitialScanBenchmark, TestValidationBenchmark, TestCorrelationBenchmark |
| `level3-scale/test_large_projects.py` (kept) | PH-001..006 | TestLargeProjectHandling, TestDirectoryBatchDetection |
| `level4-resource/test_resource_bounds.py` | PH-007, PH-008 | TestPerformanceMetrics |

**Changes Made**:
- [x] Created `performance/conftest.py` with `benchmark_files` + `warmup_service` factory fixtures (bodies = original `create_benchmark_files` / `_warmup_service`, verbatim)
- [x] Created `level1-component/test_component_benchmarks.py` (BM-001/002/004/007/008) using the fixtures
- [x] Created `level2-operation/test_operation_benchmarks.py` (BM-003/005/006); deleted old `level2-operation/test_benchmark.py`
- [x] Created `level4-resource/test_resource_bounds.py` (PH-007/008) using `warmup_service`
- [x] Reduced `level3-scale/test_large_projects.py` to PH-001..006 (removed `TestPerformanceMetrics` + local `_warmup_service` + now-unused `tempfile`/`Path` imports)
- [x] Removed obsolete `.gitkeep` from `level1-component/` and `level4-resource/`
- [x] Updated [performance-test-tracking.md](../../../test/state-tracking/permanent/performance-test-tracking.md) Test File links (12 rows) + added a TD254 Migration Note
- [x] Updated [performance/__init__.py](../../../test/automated/performance/__init__.py) docstring (also fixed pre-existing rot: listed `test_stress.py`/`test_resource_management.py`/`test_benchmarks.py`, none of which exist)
- [x] Added forward-pointer notes to the 2 live audit reports; fixed benchmark report's broken frontmatter `test_file_path`
- [x] **(L11)** Flagged Audit Status → 🔄 Needs Update on the 3 new files (12 rows; scale file left ✅ per approval); marked TD254 Resolved via `Update-TechDebt.ps1`; archived this plan

**Test Baseline**: 14 passed, 0 failed in 95.65s (`python -m pytest test/automated/performance/ -v`, 2026-06-04). No pre-existing failures. Methods: BM-001/002/003/004/005/006 (6) + PH-001..006/memory/cpu (8).
**Test Result**: 14 passed, 0 failed in 89.57s (same command, post-split, 2026-06-04). **Diff vs baseline: clean** — same 14 methods, 0 new failures. Distribution: component 3 (BM-001/002/004), operation 3 (BM-003/005/006), scale 6 (PH-001..006), resource 2 (PH-007/008). LinkWatcher path-literal canary check: intact, no mangling.

**Documentation & State Updates**:
- [x] Items 1–8 (feature state / TDD / test spec / FDD / ADR / integration narrative / user docs / validation tracking) — **N/A, test-only refactoring**: no production code changed; grepped all 53 hits for `test_benchmark|test_large_projects` — the only design/spec/user-doc references are in `*/archive/` (point-in-time records, not rewritten) and `process-framework/` `.EXAMPLE`/doc snippets (framework path, out of PF-TSK-022 scope; `test_large_projects.py` still exists so they stay literally valid). No live FDD/TDD/ADR/test-spec/handbook/README references these files.
- [x] Test tracking files updated — [performance-test-tracking.md](../../../test/state-tracking/permanent/performance-test-tracking.md): 12 Test File links relocated + TD254 Migration Note. (`test-tracking.md` does not track perf tests — N/A.) Markers preserved verbatim per file so `Validate-TestTracking.ps1` stays green. **Audit Status → 🔄 re-audit flag pending L11 (gated by L10 checkpoint).**
- [x] Technical Debt Tracking: TD254 marked **Resolved** (`Update-TechDebt.ps1`, moved to archive); 3 new files flagged 🔄 Needs Update for fresh per-level Test Audit (PF-TSK-030).

**Bugs Discovered**: None

<!-- BATCH MODE: Use `-ItemCount N` when running New-RefactoringPlan.ps1 to pre-generate N Item sections up front. To add more debt items mid-session (i.e., new TD IDs — sub-findings of an existing TD become additional `Changes Made` bullets within its Item, not new Items), copy the "## Item N" section above. -->

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD254 | Implementation complete (14 passed before & after) | None | perf-test-tracking.md (12 Test File links + Migration Note), performance/\_\_init\_\_.py docstring, 2 audit reports (forward-pointer + frontmatter fix) |

## Related Documentation
- [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md)
