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

### Component Benchmarks (Level 1)

| Test ID | Operation | Related Features | Status | Baseline | Tolerance | Last Result | Last Run | Test File | Audit Status | Audit Report | Spec Ref |
|---------|-----------|-----------------|--------|----------|-----------|-------------|----------|-----------|--------------|--------------|----------|
| BM-001 | Parser throughput (100 mixed-format files) | 2.1.1 | ⚠️ Needs Re-baseline | 144.0 files/sec | >50 files/sec | 21-45 files/sec (post-perf_counter, 2026-04-28) | 2026-04-28 | [test_benchmark.py](/test/automated/performance/test_benchmark.py) | 🔄 Needs Update | [audit-report-2-1-1-test-benchmark](../../audits/performance/audit-report-2-1-1-test-benchmark.md) | — |
| BM-002 | DB add (10000 refs, fresh db) | 0.1.2 | ⚠️ Needs Re-baseline | 0.015s (68067 ops/sec) — stale, test now uses 10000 ops | <3s | 1.488s (post-rework, 2026-04-28) | 2026-04-28 | [test_benchmark.py](/test/automated/performance/test_benchmark.py) | 🔄 Needs Update | [audit-report-2-1-1-test-benchmark](../../audits/performance/audit-report-2-1-1-test-benchmark.md) | — |
| BM-002 | DB lookup (100 refs, 1000-entry db) | 0.1.2 | ⚠️ Needs Re-baseline | 0.265s (377 ops/sec) — stale | <1.8s | 1.140s (post-rework, 2026-04-28) | 2026-04-28 | [test_benchmark.py](/test/automated/performance/test_benchmark.py) | 🔄 Needs Update | [audit-report-2-1-1-test-benchmark](../../audits/performance/audit-report-2-1-1-test-benchmark.md) | — |
| BM-002 | DB update (50 refs, 1000-entry db) | 0.1.2 | ⚠️ Needs Re-baseline | 0.003s (19805 ops/sec) — stale | <0.2s | 0.015s (post-rework, 2026-04-28) | 2026-04-28 | [test_benchmark.py](/test/automated/performance/test_benchmark.py) | 🔄 Needs Update | [audit-report-2-1-1-test-benchmark](../../audits/performance/audit-report-2-1-1-test-benchmark.md) | — |
| BM-004 | Updater throughput (50 files, 50 refs) | 2.2.1 | ⚠️ Needs Re-baseline | 43.0 files/sec | >10 files/sec | 11-14 files/sec (post-warmup, 2026-04-28) | 2026-04-28 | [test_benchmark.py](/test/automated/performance/test_benchmark.py) | 🔄 Needs Update | [audit-report-2-1-1-test-benchmark](../../audits/performance/audit-report-2-1-1-test-benchmark.md) | — |

### Operation Benchmarks (Level 2)

| Test ID | Operation | Related Features | Status | Baseline | Tolerance | Last Result | Last Run | Test File | Audit Status | Audit Report | Spec Ref |
|---------|-----------|-----------------|--------|----------|-----------|-------------|----------|-----------|--------------|--------------|----------|
| BM-003 | Initial scan (400 files) | 0.1.1, 2.1.1, 0.1.2 | ⚠️ Needs Re-baseline | 2.06s (48.6 files/sec) — stale | <10s | 15.43s (2026-04-28) | 2026-04-28 | [test_benchmark.py](/test/automated/performance/test_benchmark.py) | 🔄 Needs Update | [audit-report-2-1-1-test-benchmark](../../audits/performance/audit-report-2-1-1-test-benchmark.md) | — |
| BM-005 | Validation mode (100 files) | 0.1.1, 2.1.1 | ⚠️ Needs Re-baseline | 2.47s | <10s | 8.7s (post-warmup, 2026-04-28) | 2026-04-28 | [test_benchmark.py](/test/automated/performance/test_benchmark.py) | 🔄 Needs Update | [audit-report-2-1-1-test-benchmark](../../audits/performance/audit-report-2-1-1-test-benchmark.md) | — |
| BM-006 | Delete+create correlation (20 moves) | 1.1.1 | ⚠️ Needs Re-baseline | 1.79ms avg, 100% rate — stale | <25ms avg, 100% rate | 6-8ms avg (post-warmup, 2026-04-28) | 2026-04-28 | [test_benchmark.py](/test/automated/performance/test_benchmark.py) | 🔄 Needs Update | [audit-report-2-1-1-test-benchmark](../../audits/performance/audit-report-2-1-1-test-benchmark.md) | — |

### Scale Tests (Level 3)

| Test ID | Operation | Related Features | Status | Baseline | Tolerance | Last Result | Last Run | Test File | Audit Status | Audit Report | Spec Ref |
|---------|-----------|-----------------|--------|----------|-----------|-------------|----------|-----------|--------------|--------------|----------|
| PH-001 | 1000-file scan + move | 0.1.1, 1.1.1, 2.2.1 | ✅ Baselined | 9.21s scan, 0.16s move | <30s scan, <5s move | 9.21s, 0.16s | 2026-04-09 | [test_large_projects.py](/test/automated/performance/test_large_projects.py) | — | — | — |
| PH-002 | Deep directory (15 levels) scan + move | 0.1.1, 1.1.1 | ✅ Baselined | 0.11s scan, 0.06s move | <10s scan, <3s move | 0.11s, 0.06s | 2026-04-09 | [test_large_projects.py](/test/automated/performance/test_large_projects.py) | — | — | — |
| PH-003 | Large files (1KB-5MB) scan | 0.1.1, 2.1.1 | ✅ Baselined | 1.80s | <15s | 1.80s | 2026-04-09 | [test_large_projects.py](/test/automated/performance/test_large_projects.py) | — | — | — |
| PH-004 | Many references (300 refs to one file) move | 0.1.1, 2.2.1 | ✅ Baselined | 6.38s | <10s | 6.38s | 2026-04-09 | [test_large_projects.py](/test/automated/performance/test_large_projects.py) | — | — | — |
| PH-005 | Rapid file operations (50 moves) | 1.1.1, 2.2.1 | ✅ Baselined | 4.88s total, 0.098s avg | <30s total, <0.5s avg | 4.88s, 0.098s | 2026-04-09 | [test_large_projects.py](/test/automated/performance/test_large_projects.py) | — | — | — |
| PH-006 | Directory batch detection (100 files, 5 subdirs) | 1.1.1, 0.1.2, 2.2.1 | ✅ Baselined | 1.22s | <30s | 1.22s | 2026-04-09 | [test_large_projects.py](/test/automated/performance/test_large_projects.py) | — | — | — |

### Resource Bounds (Level 4)

| Test ID | Operation | Related Features | Status | Baseline | Tolerance | Last Result | Last Run | Test File | Audit Status | Audit Report | Spec Ref |
|---------|-----------|-----------------|--------|----------|-----------|-------------|----------|-----------|--------------|--------------|----------|
| PH-MEM | Memory usage (200 files) | cross-cutting | ✅ Baselined | — | <100MB increase, <20MB per op | skipped | 2026-04-09 | [test_large_projects.py](/test/automated/performance/test_large_projects.py) | — | — | — |
| PH-CPU | CPU usage (100 files + 20 moves) | cross-cutting | ✅ Baselined | — | avg <80%, peak <95% | skipped | 2026-04-09 | [test_large_projects.py](/test/automated/performance/test_large_projects.py) | — | — | — |

## Summary

| Level | Total | ✅ Baselined | 📋 Needs Baseline | ⬜ Needs Creation | ⚠️ Needs Re-baseline |
|-------|-------|-------------|-----------|-------------|----------|
| Component | 5 | 0 | 0 | 0 | 5 |
| Operation | 3 | 0 | 0 | 0 | 3 |
| Scale | 6 | 6 | 0 | 0 | 0 |
| Resource | 2 | 2 | 0 | 0 | 0 |
| **Total** | **16** | **8** | **0** | **0** | **8** |

## Migration Notes

- All existing performance tests migrated from test-tracking.md on 2026-04-09
- Initial baselines captured on commit 091ad8c
- PH-MEM and PH-CPU tests are `@pytest.mark.slow` and were skipped during baseline capture (require psutil); marked as Baselined with tolerance thresholds from test assertions
- Results database populated with all measured baselines: `test/state-tracking/permanent/performance-results.db`
