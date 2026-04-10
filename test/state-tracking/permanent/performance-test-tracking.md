# Performance Test Tracking

> **Purpose**: Single source of truth for all performance tests — registry, baselines, lifecycle status, and related features.
>
> **Lifecycle**: ⬜ Specified → 📋 Created → ✅ Baselined → ⚠️ Stale
>
> **Related**: [Performance Testing Guide](/process-framework/guides/03-testing/performance-testing-guide.md) | [Results Database](/process-framework/scripts/test/performance_db.py)

## Test Inventory

### Component Benchmarks (Level 1)

| Test ID | Operation | Related Features | Status | Baseline | Tolerance | Last Result | Last Run | Test File | Spec Ref |
|---------|-----------|-----------------|--------|----------|-----------|-------------|----------|-----------|----------|
| BM-001 | Parser throughput (100 mixed-format files) | 2.1.1 | ✅ Baselined | 144.0 files/sec | >50 files/sec | 144.0 files/sec | 2026-04-09 | [test_benchmark.py](/test/automated/performance/test_benchmark.py) | — |
| BM-002 | DB add (1000 refs) | 0.1.2 | ✅ Baselined | 0.015s (68067 ops/sec) | <5s | 0.015s | 2026-04-09 | [test_benchmark.py](/test/automated/performance/test_benchmark.py) | — |
| BM-002 | DB lookup (100 refs) | 0.1.2 | ✅ Baselined | 0.265s (377 ops/sec) | <2s | 0.265s | 2026-04-09 | [test_benchmark.py](/test/automated/performance/test_benchmark.py) | — |
| BM-002 | DB update (50 refs) | 0.1.2 | ✅ Baselined | 0.003s (19805 ops/sec) | <2s | 0.003s | 2026-04-09 | [test_benchmark.py](/test/automated/performance/test_benchmark.py) | — |
| BM-004 | Updater throughput (50 files, 50 refs) | 2.2.1 | ✅ Baselined | 43.0 files/sec | >10 files/sec | 43.0 files/sec | 2026-04-09 | [test_benchmark.py](/test/automated/performance/test_benchmark.py) | — |

### Operation Benchmarks (Level 2)

| Test ID | Operation | Related Features | Status | Baseline | Tolerance | Last Result | Last Run | Test File | Spec Ref |
|---------|-----------|-----------------|--------|----------|-----------|-------------|----------|-----------|----------|
| BM-003 | Initial scan (400 files) | 0.1.1, 2.1.1, 0.1.2 | ✅ Baselined | 2.06s (48.6 files/sec) | <10s | 2.06s | 2026-04-09 | [test_benchmark.py](/test/automated/performance/test_benchmark.py) | — |
| BM-005 | Validation mode (100 files) | 0.1.1, 2.1.1 | ✅ Baselined | 2.47s | <10s | 2.47s | 2026-04-09 | [test_benchmark.py](/test/automated/performance/test_benchmark.py) | — |
| BM-006 | Delete+create correlation (20 moves) | 1.1.1 | ✅ Baselined | 1.79ms avg, 100% rate | <100ms avg, 100% rate | 1.79ms avg, 100% | 2026-04-09 | [test_benchmark.py](/test/automated/performance/test_benchmark.py) | — |

### Scale Tests (Level 3)

| Test ID | Operation | Related Features | Status | Baseline | Tolerance | Last Result | Last Run | Test File | Spec Ref |
|---------|-----------|-----------------|--------|----------|-----------|-------------|----------|-----------|----------|
| PH-001 | 1000-file scan + move | 0.1.1, 1.1.1, 2.2.1 | ✅ Baselined | 9.21s scan, 0.16s move | <30s scan, <5s move | 9.21s, 0.16s | 2026-04-09 | [test_large_projects.py](/test/automated/performance/test_large_projects.py) | — |
| PH-002 | Deep directory (15 levels) scan + move | 0.1.1, 1.1.1 | ✅ Baselined | 0.11s scan, 0.06s move | <10s scan, <3s move | 0.11s, 0.06s | 2026-04-09 | [test_large_projects.py](/test/automated/performance/test_large_projects.py) | — |
| PH-003 | Large files (1KB-5MB) scan | 0.1.1, 2.1.1 | ✅ Baselined | 1.80s | <15s | 1.80s | 2026-04-09 | [test_large_projects.py](/test/automated/performance/test_large_projects.py) | — |
| PH-004 | Many references (300 refs to one file) move | 0.1.1, 2.2.1 | ✅ Baselined | 6.38s | <10s | 6.38s | 2026-04-09 | [test_large_projects.py](/test/automated/performance/test_large_projects.py) | — |
| PH-005 | Rapid file operations (50 moves) | 1.1.1, 2.2.1 | ✅ Baselined | 4.88s total, 0.098s avg | <30s total, <0.5s avg | 4.88s, 0.098s | 2026-04-09 | [test_large_projects.py](/test/automated/performance/test_large_projects.py) | — |
| PH-006 | Directory batch detection (100 files, 5 subdirs) | 1.1.1, 0.1.2, 2.2.1 | ✅ Baselined | 1.22s | <30s | 1.22s | 2026-04-09 | [test_large_projects.py](/test/automated/performance/test_large_projects.py) | — |

### Resource Bounds (Level 4)

| Test ID | Operation | Related Features | Status | Baseline | Tolerance | Last Result | Last Run | Test File | Spec Ref |
|---------|-----------|-----------------|--------|----------|-----------|-------------|----------|-----------|----------|
| PH-MEM | Memory usage (200 files) | cross-cutting | ✅ Baselined | — | <100MB increase, <20MB per op | skipped | 2026-04-09 | [test_large_projects.py](/test/automated/performance/test_large_projects.py) | — |
| PH-CPU | CPU usage (100 files + 20 moves) | cross-cutting | ✅ Baselined | — | avg <80%, peak <95% | skipped | 2026-04-09 | [test_large_projects.py](/test/automated/performance/test_large_projects.py) | — |

## Summary

| Level | Total | ✅ Baselined | 📋 Created | ⬜ Specified | ⚠️ Stale |
|-------|-------|-------------|-----------|-------------|----------|
| Component | 5 | 5 | 0 | 0 | 0 |
| Operation | 3 | 3 | 0 | 0 | 0 |
| Scale | 6 | 6 | 0 | 0 | 0 |
| Resource | 2 | 2 | 0 | 0 | 0 |
| **Total** | **16** | **16** | **0** | **0** | **0** |

## Migration Notes

- All existing performance tests migrated from test-tracking.md on 2026-04-09
- Initial baselines captured on commit 091ad8c
- PH-MEM and PH-CPU tests are `@pytest.mark.slow` and were skipped during baseline capture (require psutil); marked as Baselined with tolerance thresholds from test assertions
- Results database populated with all measured baselines: `test/state-tracking/permanent/performance-results.db`
