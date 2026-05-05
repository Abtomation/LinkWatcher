---
id: TE-STA-003
type: Process Framework
category: State File
version: 1.1
created: 2026-04-09
updated: 2026-04-28
tracking_scope: Performance Test Tracking
state_type: Implementation Status
---
# Performance Test Tracking

> **Purpose**: Single source of truth for all performance tests — registry, baselines, lifecycle status, and related features.
>
> **Lifecycle**: ⬜ Needs Creation → 📋 Needs Baseline → ✅ Baselined → ⚠️ Needs Re-baseline
>
> **Related**: [Performance Testing Guide](/process-framework/guides/03-testing/performance-testing-guide.md) | [Results Database](/process-framework/scripts/test/performance_db.py)

## Status Legend

### Lifecycle Status

| Symbol | Status              | Description                                                                          | Next Task  |
| ------ | ------------------- | ------------------------------------------------------------------------------------ | ---------- |
| ⬜     | Needs Creation      | Test specified by scoping task, needs implementation                                 | PF-TSK-084 |
| 📋     | Needs Baseline      | Test created, needs audit (separate Audit Status column) then baseline capture       | PF-TSK-085 |
| ✅     | Baselined           | Baseline captured, stable — monitoring for regressions                               | —          |
| ⚠️     | Needs Re-baseline   | Baseline is stale due to code changes, needs re-capture                              | PF-TSK-085 |

### Audit Status

Tracked per-test in the **Audit Status** column. Set by [Test Audit (PF-TSK-030)](/process-framework/tasks/03-testing/test-audit-task.md) with `-TestType Performance`.

| Symbol | Status              | Description                                                                          |
| ------ | ------------------- | ------------------------------------------------------------------------------------ |
| 🔍     | Audit Approved      | All audit criteria pass — test is ready for baseline capture                        |
| 🔄     | Needs Update        | Test has methodology, tolerance, or measurement issues that need fixing before baseline capture |
| 🔴     | Audit Failed        | Fundamental methodology or measurement issues                                        |
| —      | _(not yet audited)_ | Test has not undergone audit. **Only valid** when Lifecycle Status is `📋 Needs Baseline`. A `✅ Baselined` row with `Audit Status = —` is a compliance hole (e.g., pre-gate migration) and needs retroactive audit. |

> **Audit gate**: Tests in `📋 Needs Baseline` status must reach `✅ Audit Approved` in the Audit Status column before baseline capture. The audit gate enforces a one-way flow: Lifecycle Status `✅ Baselined` implies an approved audit.

## Test Inventory

> **Multi-metric tests**: Each metric gets its own row (Metric column). Single-metric tests use `—`. Tolerances are single-metric per row, keyed by `(Test ID, Metric)`. The `Status` column reflects the test as a whole; metric rows for the same test share status.

### Component Benchmarks (Level 1)

| Test ID | Metric | Operation | Related Features | Status | Baseline | Tolerance | Last Result | Last Run | Test File | Audit Status | Audit Report | Spec Ref |
|---------|--------|-----------|-----------------|--------|----------|-----------|-------------|----------|-----------|--------------|--------------|----------|
| BM-001 | — | Parser throughput (100 file sets, 400 files across .md/.txt/.json/.yaml) | 2.1.1 | ✅ Baselined | 299.2 files/sec | >50 files/sec | 299.2 files/sec (mean of 3 runs, 2026-04-29) | 2026-04-29 | [test_benchmark.py](/test/automated/performance/test_benchmark.py) | ✅ Audit Approved | [audit-report-2-1-1-test-benchmark](../../audits/performance/audit-report-2-1-1-test-benchmark.md) | — |
| BM-002 | — | DB add (10000 refs, fresh db) | 0.1.2 | ✅ Baselined | 0.245s (40794 ops/sec) | <3s | 0.245s (mean of 3 runs, 2026-04-29) | 2026-04-29 | [test_benchmark.py](/test/automated/performance/test_benchmark.py) | ✅ Audit Approved | [audit-report-2-1-1-test-benchmark](../../audits/performance/audit-report-2-1-1-test-benchmark.md) | — |
| BM-007 | — | DB lookup (100 refs, 1000-entry db) | 0.1.2 | ✅ Baselined | 0.195s (515 ops/sec) | <1.8s | 0.195s (mean of 3 runs, 2026-04-29) | 2026-04-29 | [test_benchmark.py](/test/automated/performance/test_benchmark.py) | ✅ Audit Approved | [audit-report-2-1-1-test-benchmark](../../audits/performance/audit-report-2-1-1-test-benchmark.md) | — |
| BM-008 | — | DB update (50 refs, 1000-entry db) | 0.1.2 | ✅ Baselined | 0.002s (30920 ops/sec) | <0.02s | 0.002s (mean of 3 runs, 2026-04-29) | 2026-04-29 | [test_benchmark.py](/test/automated/performance/test_benchmark.py) | ✅ Audit Approved | [audit-report-2-1-1-test-benchmark](../../audits/performance/audit-report-2-1-1-test-benchmark.md) | — |
| BM-004 | — | Updater throughput (50 files, 50 refs) | 2.2.1 | ✅ Baselined | 65.1 files/sec | >10 files/sec | 65.1 files/sec (mean of 3 runs, 2026-04-29) | 2026-04-29 | [test_benchmark.py](/test/automated/performance/test_benchmark.py) | ✅ Audit Approved | [audit-report-2-1-1-test-benchmark](../../audits/performance/audit-report-2-1-1-test-benchmark.md) | — |

### Operation Benchmarks (Level 2)

| Test ID | Metric | Operation | Related Features | Status | Baseline | Tolerance | Last Result | Last Run | Test File | Audit Status | Audit Report | Spec Ref |
|---------|--------|-----------|-----------------|--------|----------|-----------|-------------|----------|-----------|--------------|--------------|----------|
| BM-003 | — | Initial scan (400 files) | 0.1.1, 2.1.1, 0.1.2 | ✅ Baselined | 1.51s | <10s | 1.51s (mean of 3 runs, 2026-04-29) | 2026-04-29 | [test_benchmark.py](/test/automated/performance/test_benchmark.py) | ✅ Audit Approved | [audit-report-2-1-1-test-benchmark](../../audits/performance/audit-report-2-1-1-test-benchmark.md) | — |
| BM-005 | — | Validation mode (100 files) | 0.1.1, 2.1.1 | ✅ Baselined | 1.020s | <10s | 1.020s (mean of 3 runs, 2026-04-29) | 2026-04-29 | [test_benchmark.py](/test/automated/performance/test_benchmark.py) | ✅ Audit Approved | [audit-report-2-1-1-test-benchmark](../../audits/performance/audit-report-2-1-1-test-benchmark.md) | — |
| BM-006 | — | Delete+create correlation (20 moves; 100% match rate also asserted in test code) | 1.1.1 | ✅ Baselined | 1.06ms avg, 100% match rate | <10ms | 1.06ms avg, 100% match rate (mean of 3 runs, 2026-04-29) | 2026-04-29 | [test_benchmark.py](/test/automated/performance/test_benchmark.py) | ✅ Audit Approved | [audit-report-2-1-1-test-benchmark](../../audits/performance/audit-report-2-1-1-test-benchmark.md) | — |

### Scale Tests (Level 3)

| Test ID | Metric | Operation | Related Features | Status | Baseline | Tolerance | Last Result | Last Run | Test File | Audit Status | Audit Report | Spec Ref |
|---------|--------|-----------|-----------------|--------|----------|-----------|-------------|----------|-----------|--------------|--------------|----------|
| PH-001 | scan | 1000-file scan + move | 0.1.1, 1.1.1, 2.2.1 | ✅ Baselined | 9.21s | <30s | 9.21s | 2026-04-09 | [test_large_projects.py](/test/automated/performance/test_large_projects.py) | ✅ Audit Approved | [audit-report-0-1-1-test-large-projects](../../audits/performance/audit-report-0-1-1-test-large-projects.md) | — |
| PH-001 | move | 1000-file scan + move | 0.1.1, 1.1.1, 2.2.1 | ✅ Baselined | 0.16s | <1s | 0.16s | 2026-04-09 | [test_large_projects.py](/test/automated/performance/test_large_projects.py) | ✅ Audit Approved | [audit-report-0-1-1-test-large-projects](../../audits/performance/audit-report-0-1-1-test-large-projects.md) | — |
| PH-002 | scan | Deep directory (15 levels) scan + move | 0.1.1, 1.1.1 | ✅ Baselined | 0.11s | <1s | 0.11s | 2026-04-09 | [test_large_projects.py](/test/automated/performance/test_large_projects.py) | ✅ Audit Approved | [audit-report-0-1-1-test-large-projects](../../audits/performance/audit-report-0-1-1-test-large-projects.md) | — |
| PH-002 | move | Deep directory (15 levels) scan + move | 0.1.1, 1.1.1 | ✅ Baselined | 0.06s | <0.5s | 0.06s | 2026-04-09 | [test_large_projects.py](/test/automated/performance/test_large_projects.py) | ✅ Audit Approved | [audit-report-0-1-1-test-large-projects](../../audits/performance/audit-report-0-1-1-test-large-projects.md) | — |
| PH-003 | — | Large files (1KB-5MB) scan | 0.1.1, 2.1.1 | ✅ Baselined | 1.80s | <15s | 1.80s | 2026-04-09 | [test_large_projects.py](/test/automated/performance/test_large_projects.py) | ✅ Audit Approved | [audit-report-0-1-1-test-large-projects](../../audits/performance/audit-report-0-1-1-test-large-projects.md) | — |
| PH-004 | — | Many references (300 refs to one file) move | 0.1.1, 2.2.1 | ✅ Baselined | 6.38s | <10s | 6.38s | 2026-04-09 | [test_large_projects.py](/test/automated/performance/test_large_projects.py) | ✅ Audit Approved | [audit-report-0-1-1-test-large-projects](../../audits/performance/audit-report-0-1-1-test-large-projects.md) | — |
| PH-005 | total | Rapid file operations (50 moves) | 1.1.1, 2.2.1 | ✅ Baselined | 4.88s | <30s | 4.88s | 2026-04-09 | [test_large_projects.py](/test/automated/performance/test_large_projects.py) | ✅ Audit Approved | [audit-report-0-1-1-test-large-projects](../../audits/performance/audit-report-0-1-1-test-large-projects.md) | — |
| PH-005 | avg | Rapid file operations (50 moves) | 1.1.1, 2.2.1 | ✅ Baselined | 0.098s | <0.5s | 0.098s | 2026-04-09 | [test_large_projects.py](/test/automated/performance/test_large_projects.py) | ✅ Audit Approved | [audit-report-0-1-1-test-large-projects](../../audits/performance/audit-report-0-1-1-test-large-projects.md) | — |
| PH-006 | — | Directory batch detection (100 files, 5 subdirs) | 1.1.1, 0.1.2, 2.2.1 | ✅ Baselined | 1.22s | <5s | 1.22s | 2026-04-09 | [test_large_projects.py](/test/automated/performance/test_large_projects.py) | ✅ Audit Approved | [audit-report-0-1-1-test-large-projects](../../audits/performance/audit-report-0-1-1-test-large-projects.md) | — |

### Resource Bounds (Level 4)

| Test ID | Metric | Operation | Related Features | Status | Baseline | Tolerance | Last Result | Last Run | Test File | Audit Status | Audit Report | Spec Ref |
|---------|--------|-----------|-----------------|--------|----------|-----------|-------------|----------|-----------|--------------|--------------|----------|
| PH-007 | net | Memory usage (200 files) | cross-cutting | ✅ Baselined | -1.0 MB | <100MB | -1.0 MB (PF-TSK-085, mean of 3 runs) | 2026-04-29 | [test_large_projects.py](/test/automated/performance/test_large_projects.py) | ✅ Audit Approved | [audit-report-0-1-1-test-large-projects](../../audits/performance/audit-report-0-1-1-test-large-projects.md) | — |
| PH-007 | op-delta | Memory usage (200 files) | cross-cutting | ✅ Baselined | 4.9 MB | <20MB | 4.9 MB (PF-TSK-085, mean of 3 runs) | 2026-04-29 | [test_large_projects.py](/test/automated/performance/test_large_projects.py) | ✅ Audit Approved | [audit-report-0-1-1-test-large-projects](../../audits/performance/audit-report-0-1-1-test-large-projects.md) | — |
| PH-008 | avg-raw | CPU usage (100 files + 20 moves); cpu_count normalization in test code (asserts (avg/cpu_count) <80%) | cross-cutting | ✅ Baselined | 65.5% raw (4.1% per-core normalized) | — | 65.5% raw (4.1% normalized) (PF-TSK-085, mean of 3 runs) | 2026-04-29 | [test_large_projects.py](/test/automated/performance/test_large_projects.py) | ✅ Audit Approved | [audit-report-0-1-1-test-large-projects](../../audits/performance/audit-report-0-1-1-test-large-projects.md) | — |
| PH-008 | peak | CPU usage (100 files + 20 moves); diagnostic only post-PD-REF-217 | cross-cutting | ✅ Baselined | 117.6% | — | 117.6% (PF-TSK-085, mean of 3 runs) | 2026-04-29 | [test_large_projects.py](/test/automated/performance/test_large_projects.py) | ✅ Audit Approved | [audit-report-0-1-1-test-large-projects](../../audits/performance/audit-report-0-1-1-test-large-projects.md) | — |

## Summary

| Level | Total | ✅ Baselined | 📋 Needs Baseline | ⬜ Needs Creation | ⚠️ Needs Re-baseline |
|-------|-------|-------------|-----------|-------------|----------|
| Component | 5 | 5 | 0 | 0 | 0 |
| Operation | 3 | 3 | 0 | 0 | 0 |
| Scale | 6 | 6 | 0 | 0 | 0 |
| Resource | 2 | 2 | 0 | 0 | 0 |
| **Total** | **16** | **16** | **0** | **0** | **0** |

## Migration Notes

- All existing performance tests migrated from test-tracking.md on 2026-04-09
- Initial baselines captured on commit 091ad8c
- PH-007 (Memory) and PH-008 (CPU) baselines were captured 2026-04-29 (PF-TSK-085) after methodology rework (PD-REF-214/216/217/218/220) and re-audit approval (TE-TAR-071). `psutil>=5.9.0` now declared in pyproject.toml test extras. (Originally tracked as PH-MEM/PH-CPU; renumbered to script convention 2026-04-29 via PF-STA-099.)
- Results database populated with all measured baselines: `test/state-tracking/permanent/performance-results.db`
