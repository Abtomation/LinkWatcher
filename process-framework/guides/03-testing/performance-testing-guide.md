---
id: PF-GDE-060
type: Process Framework
category: Guide
version: 1.1
created: 2026-04-09
updated: 2026-04-10
---

# Performance Testing Guide

## Overview

This guide defines the performance testing methodology for the project. It covers test levels, measurement approaches, baseline management, trend analysis, and a decision matrix for when to create performance tests.

Performance testing is a **cross-cutting concern** — tests are not owned by individual features. Instead, features trigger performance testing when they affect hot-path components, end-to-end operations, or scaling characteristics.

## When to Use

Consult this guide when:

- **Creating new performance tests** — use the test level definitions and measurement methodology
- **Deciding whether a feature needs performance tests** — see the [Performance & E2E Test Scoping Guide](/process-framework/guides/03-testing/performance-and-e2e-test-scoping-guide.md) (decision matrix lives there)
- **Setting or updating baselines** — follow the baseline management process
- **Interpreting trend data** — use the trend analysis section to understand regressions vs. noise

## Table of Contents

1. [Performance Test Levels](#performance-test-levels)
2. [Decision Matrix: When to Create Performance Tests](#decision-matrix)
3. [Writing Performance Tests](#writing-performance-tests)
4. [Baseline Management](#baseline-management)
5. [Trend Analysis](#trend-analysis)
6. [Infrastructure](#infrastructure)
7. [Troubleshooting](#troubleshooting)
8. [Related Resources](#related-resources)

## Performance Test Levels

Performance tests are organized into four levels, adapted to the project's architecture. Each level measures different characteristics and uses different threshold types.

### Level 1: Component Benchmarks

**What it measures**: Single subsystem throughput in isolation.

**Threshold type**: Throughput (ops/sec, files/sec) or latency for fixed workload.

**When to use**: When a code change modifies a single subsystem's hot path (parser, database, updater, detector).

| Test ID Pattern | Subsystem | Example Metric |
|----------------|-----------|---------------|
| BM-0xx | Parser, DB, Updater, Detector | Parser: >50 files/sec for 100 mixed-format files |

**Measurement approach**:
1. Create a realistic but controlled input (e.g., 100 mixed-format files for parser)
2. Measure wall-clock time for the complete operation
3. Calculate throughput: items / elapsed time
4. Assert against tolerance threshold, not exact value

**Example test structure**:
```python
@pytest.mark.performance
def test_bm_001_parsing_throughput(self, tmp_path):
    # Setup: create 100 mixed-format files
    files = create_test_files(tmp_path, count=100)

    # Measure
    start = time.time()
    for f in files:
        service.scan_file(f)
    elapsed = time.time() - start

    throughput = len(files) / elapsed
    print(f"  {throughput:.1f} files/second")

    # Assert tolerance, not exact value
    assert throughput > 50, f"Throughput {throughput:.1f} below minimum 50 files/sec"
```

### Level 2: Operation Benchmarks

**What it measures**: Cross-cutting operations end-to-end — from input to final state change.

**Threshold type**: Latency (seconds for N items).

**When to use**: When a code change affects the full pipeline of an operation (initial scan, file move handling, validation mode).

| Test ID Pattern | Operation | Example Metric |
|----------------|-----------|---------------|
| BM-0xx | Initial scan, validation, move handling | Initial scan of 100 files: <10s |

**Measurement approach**:
1. Set up a project fixture at realistic scale (e.g., 100 files with cross-references)
2. Initialize the service and trigger the operation
3. Measure total wall-clock time
4. Assert against maximum acceptable latency

### Level 3: Scale Tests

**What it measures**: Operations under extreme conditions — high file counts, deep directories, many references, rapid changes.

**Threshold type**: Pass/fail at threshold (completes within N seconds at scale X).

**When to use**: When a code change affects data structures, algorithms, or architectural assumptions that govern scaling.

| Test ID Pattern | Scenario | Example Metric |
|----------------|----------|---------------|
| PH-0xx | 1000+ files, deep dirs, large files, many refs, rapid moves | 1000-file scan: <30s |

**Measurement approach**:
1. Create extreme-condition fixtures (1000+ files, 15-level deep dirs, 100+ refs to one file)
2. Run the full operation
3. Assert completion within acceptable time
4. Monitor that no single step dominates disproportionately

### Level 4: Resource Bounds

**What it measures**: System-wide resource consumption — memory, CPU.

**Threshold type**: Ceiling (MB, CPU%).

**When to use**: When a code change affects memory allocation patterns, caching strategies, or concurrent processing.

| Metric | Threshold | Example |
|--------|-----------|---------|
| RSS memory | <100MB for 200 files | Memory stays bounded during operations |
| CPU usage | avg <80%, peak <95% | CPU doesn't saturate during normal operation |

**Measurement approach**:
1. Use `psutil` to monitor process metrics during operations
2. Sample at regular intervals
3. Report peak and average values
4. Assert against ceiling thresholds

> **Note**: Resource tests may be skipped on CI or resource-constrained environments. Mark with `@pytest.mark.slow` in addition to `@pytest.mark.performance`.

## Decision Matrix

> **Migrated**: The performance test decision matrix has moved to the [Performance & E2E Test Scoping Guide](/process-framework/guides/03-testing/performance-and-e2e-test-scoping-guide.md#performance-test-decision-matrix), which is the authoritative reference for "when to create performance tests." This guide focuses on "how to test" — levels, baselines, and trends.

### Trigger Points in the Workflow

Performance testing is triggered at these points:

1. **After code review** — The [Performance & E2E Test Scoping task (PF-TSK-086)](/process-framework/tasks/03-testing/performance-and-e2e-test-scoping-task.md) applies the decision matrix and adds entries to performance-test-tracking.md
2. **Definition of Done** — "No regression in Operation benchmarks (verified via Baseline Capture)"
3. **Pre-release verification** — Run Baseline Capture, verify no regressions
4. **Post-refactoring** — If performance-affecting code changed, trigger Baseline Capture

## Writing Performance Tests

### File Organization

All performance tests live in `test/automated/performance/`. Use these conventions:

| File | Contents |
|------|----------|
| `test_benchmark.py` | Component and Operation benchmarks (BM-xxx) |
| `test_large_projects.py` | Scale tests (PH-xxx) and Resource bounds |
| Additional files | Named by subsystem if benchmarks grow large |

### Test ID Conventions

- **BM-xxx**: Benchmarks (Component and Operation levels)
- **PH-xxx**: Performance at scale (Scale and Resource levels)

#### Multi-metric tests: `--metric` flag

A single performance test can produce multiple measurements that warrant separate baselines (e.g., a "100 file move" test measures both initial scan time and per-move time). Each metric is recorded as a separate row in the `performance_results` table with an explicit `metric` column, captured via the `--metric` flag on `record`:

```bash
python process-framework/scripts/test/performance_db.py record --test-id PH-001 --metric scan --value 9.21 --unit "seconds"
python process-framework/scripts/test/performance_db.py record --test-id PH-001 --metric move --value 0.16 --unit "seconds"
```

In the tracking file, each metric occupies its own row, with the `Metric` column holding the metric name; single-metric tests use `Metric = "—"`. Tolerances are keyed by the `(Test ID, Metric)` tuple.

| Test | Metrics | Purpose |
|------|---------|---------|
| PH-001 | `scan`, `move` | Scan + move time for the same scenario |
| PH-002 | `scan`, `move` | Same shape; deep-directory variant |
| PH-005 | `total`, `avg` | Aggregate + per-op time for the same run |
| PH-007 | `net`, `op-delta` | Net + during-operation memory delta |
| PH-008 | `avg-raw`, `peak` | Asserted CPU% + diagnostic peak (peak not asserted) |

**Canonical baseline**: When a test records multiple metrics, the **primary asserted metric** is the canonical baseline — its tolerance gates pass/fail. Other metrics are recorded for trend visibility but do not trigger regressions. Document which metric is asserted in the test docstring or the tracking-file Notes column (e.g., PH-008 explicitly notes `peak` is "diagnostic only post-PD-REF-217").

**When to use a metric vs. a separate test ID**: Use the `--metric` flag when measurements share the same fixture, run, and conceptual scenario. Use separate test IDs when the scenarios differ.

### Required Markers

Every performance test must have:

```python
@pytest.mark.feature("cross-cutting")  # or specific feature ID if applicable
@pytest.mark.priority("Extended")
@pytest.mark.test_type("performance")
@pytest.mark.performance
```

Add `@pytest.mark.slow` for tests taking >10 seconds.

### Measurement Best Practices

1. **Use wall-clock time** (`time.time()` or `time.perf_counter()`) — not CPU time
2. **Print results** — always print measured values so they can be captured by the baseline system
3. **Assert tolerances, not exact values** — performance varies by machine and load
4. **Use realistic fixtures** — don't test with trivially small inputs
5. **Isolate the measurement** — setup and teardown outside the timing window
6. **One metric per assertion** — separate assertions for separate measurements
7. **Document the threshold rationale** — why is 50 files/sec the minimum? Where did 30s come from?

### Avoiding Flaky Benchmarks

- **Warm up**: Run the operation once before measuring to avoid cold-start effects
- **Generous tolerances**: Thresholds should be 3-5x worse than typical measurements. The test catches regressions, not noise.
- **No CI sensitivity**: Don't set thresholds that pass on fast hardware but fail on slow CI runners
- **Temp directories**: Always use `tmp_path` to avoid filesystem caching effects from prior runs

### Benchmarking Internal Components

Some components are not designed for isolated use — they have no public API, rely on callbacks, or lack clean shutdown methods. These still need benchmarking when they sit on a hot path. Use these patterns:

**Pattern 1: Direct instantiation with stub callbacks**

When a component is callback-driven, instantiate it directly and inject minimal callbacks to capture results:

```python
# Component uses callbacks — inject stubs to observe behavior
results = []

def on_result(old_path, new_path):
    results.append((old_path, new_path))

def on_fallback(path):
    pass  # Unused code path for this benchmark

component = InternalComponent(
    on_success=on_result,
    on_failure=on_fallback,
    delay=10.0,
)
```

**Pattern 2: Simulating multi-step internal protocols**

Some components require a specific call sequence that mirrors their runtime usage (e.g., buffering a delete, then matching a create). Time only the step you care about:

```python
# Setup: feed the component its precondition
component.buffer_delete(rel_src, abs_src)

# Move the file on disk (simulating the OS event)
src.rename(dest)

# Time the actual operation under test
start = time.time()
result = component.match_created_file(rel_dest, abs_dest)
elapsed = time.time() - start
```

**Pattern 3: Cleanup without a public stop method**

Components not designed for isolated testing may lack a `stop()` or `close()` method. Use `try/finally` with internal flags or attributes:

```python
try:
    # ... benchmark code ...
finally:
    component._stopped = True  # Access internal flag if no public API
    # Or: component._timer.cancel() if using threading timers
```

Document any internal attribute access with a comment explaining why — these are fragile and may break if the component is refactored.

**When to use these patterns**: Level 1 (Component Benchmarks) where the target subsystem has no service-level entry point. If the component *can* be exercised through a higher-level API, prefer that — it's more realistic and less fragile.

## Baseline Management

### What Is a Baseline?

A baseline is a recorded measurement of a performance test on a specific commit. It establishes the "expected" performance level for trend comparison.

### When to Set Baselines

| Trigger | Action |
|---------|--------|
| New performance test created | Capture initial baseline |
| Significant code refactoring | Re-capture affected baselines |
| Hardware/environment change | Re-capture all baselines |
| Pre-release | Capture release baseline |
| Baseline marked ⚠️ Needs Re-baseline | Re-capture |

### How to Capture Baselines

Use the Performance Baseline Capture task (Session 2+) or run manually:

```bash
# Run performance tests
python -m pytest test/automated/performance/ -v -s -m performance

# Record results in the trend database (git commit auto-captured from HEAD)
python process-framework/scripts/test/performance_db.py record --test-id BM-NNN --value 144.0 --unit "files/sec"

# For multi-metric tests, pass --metric (see "Multi-metric tests" above):
python process-framework/scripts/test/performance_db.py record --test-id PH-001 --metric scan --value 9.21 --unit "seconds"

# Or batch record (future enhancement)
python process-framework/scripts/test/performance_db.py record --from-output results.json
```

### Tolerance Bands

Each test has a tolerance defined in the tracking file. Tolerances represent the **minimum acceptable performance**, not the expected value:

| Level | Tolerance Approach |
|-------|-------------------|
| Component | Throughput floor (e.g., >50 files/sec) — well below typical measurement |
| Operation | Maximum latency (e.g., <10s) — 3-5x typical measurement |
| Scale | Maximum completion time at scale (e.g., <30s for 1000 files) |
| Resource | Ceiling (e.g., <100MB RSS) — well above typical usage |

> **Script-side tolerances**: The `performance_db.py` `record`, `trend`, and `regressions` subcommands enforce tolerances by parsing the **Tolerance** column of `test/state-tracking/permanent/performance-test-tracking.md` — the markdown file is the single source of truth. Each row has a single tolerance band (e.g., `<3s`, `>50 files/sec`) keyed by the `(Test ID, Metric)` pair from that row. Multi-metric tests have one row per metric; single-metric tests use `Metric = "—"`. Non-band entries (`—`, prose like "diagnostic only", or assertions enforced in test code such as cpu_count normalization) are skipped — tolerance enforcement for those metrics lives in the test code itself. If the file is missing or no rows parse, tolerance checks silently no-op.

### Staleness

A baseline becomes **stale** when:
- The code under test has been significantly modified since the last capture
- The baseline is older than a project-defined threshold (e.g., 2 releases)
- Environmental conditions have changed (OS update, hardware change)

Stale baselines are marked ⚠️ Needs Re-baseline in the tracking file and should be re-captured.

## Trend Analysis

### Using the Results Database

```bash
# Discover registered (test_id, metric) series. Use --filter to narrow:
#   filter matches against test_id OR metric name (case-insensitive).
python process-framework/scripts/test/performance_db.py list-test-ids
python process-framework/scripts/test/performance_db.py list-test-ids --filter PH-007

# View trend for a specific test (last 10 results)
python process-framework/scripts/test/performance_db.py trend --test-id BM-NNN --last 10

# Check for regressions (latest result vs. tolerance).
# Rows in `⚠️ Needs Re-baseline` status are auto-excluded (their tolerances
# are known-stale) and surfaced in a separate "skipped" footer.
python process-framework/scripts/test/performance_db.py regressions

# Export for external analysis
python process-framework/scripts/test/performance_db.py export --format csv
```

### Interpreting Trends

| Pattern | Interpretation | Action |
|---------|---------------|--------|
| Stable (±5%) | Normal variance | None |
| Gradual degradation (>10% over 3+ captures) | Accumulated overhead | Investigate, file tech debt |
| Sudden drop (>20% in one capture) | Likely regression from recent change | Bisect recent commits |
| Improvement (>10%) | Optimization or measurement change | Verify, update baseline if intentional |

### When to Act

- **Tolerance breach**: Latest result violates the test's tolerance → immediate investigation
- **Trend degradation**: 3+ consecutive captures show >5% degradation → file tech debt item
- **Unexplained improvement**: Verify measurement methodology hasn't changed

## Infrastructure

### Tracking File

**Location**: [performance-test-tracking.md](/test/state-tracking/permanent/performance-test-tracking.md)

Combined registry + baselines + lifecycle status. Single source of truth for all performance tests.

**Lifecycle**: ⬜ Needs Creation → 📋 Needs Baseline → ✅ Audit Approved → ✅ Baselined → ⚠️ Needs Re-baseline

> **Audit gate**: Newly created tests (`📋 Needs Baseline`) must pass [Test Audit (PF-TSK-030)](/process-framework/tasks/03-testing/test-audit-task.md) with `-TestType Performance` before baseline capture. The `⚠️ Needs Re-baseline` → `✅ Baselined` path is exempt (tests were already audited when first created).

### Results Database

**Location**: `test/state-tracking/permanent/performance-results.db` (SQLite)
**Script**: [performance_db.py](/process-framework/scripts/test/performance_db.py)

Stores historical measurements for trend analysis. Each record includes test ID, value, unit, timestamp, and git commit.

### Related Tasks

| Task | Role in Performance Testing |
|------|---------------------------|
| Performance & E2E Test Scoping (PF-TSK-086) | Identifies which performance tests are needed per feature (owns the decision matrix) |
| Performance Test Creation (PF-TSK-084) | Implements tests from `⬜ Needs Creation` entries in tracking, registers in tracking |
| Performance Baseline Capture (PF-TSK-085) | Runs tests, records results, detects regressions |

## Troubleshooting

### Flaky Performance Test

**Symptom**: Test passes sometimes, fails sometimes with values near the tolerance threshold.

**Cause**: Tolerance is too tight relative to normal variance on the test machine.

**Solution**: Widen the tolerance. Performance tests should catch regressions (2x-5x degradation), not noise (±10%). If a test needs tight tolerances, run multiple iterations and compare averages.

### Baseline Appears Wrong

**Symptom**: Recorded baseline doesn't match current measurements.

**Cause**: Baseline was captured under different conditions (different machine, different load, different data).

**Solution**: Re-capture the baseline on the current environment. Use `performance_db.py record` to add a new measurement — the old one stays in the trend history.

### All Performance Tests Slow

**Symptom**: All tests take significantly longer than baselines.

**Cause**: System under load, antivirus scanning temp directories, or disk I/O contention.

**Solution**: Close other applications, exclude temp directories from antivirus scanning, retry on idle system. If consistently slower, re-establish baselines for the new environment.

## Related Resources

- [Performance & E2E Test Scoping Guide](/process-framework/guides/03-testing/performance-and-e2e-test-scoping-guide.md) — Decision matrix for "when to test" (companion to this guide's "how to test")
- [Performance Test Tracking](/test/state-tracking/permanent/performance-test-tracking.md) — Registry of all performance tests with baselines
- [Performance Results Database](/process-framework/scripts/test/performance_db.py) — Trend storage and query tool
- [Test Infrastructure Guide](/process-framework/guides/03-testing/test-infrastructure-guide.md) — How test/ connects to the framework
- [Definition of Done](/process-framework/guides/04-implementation/definition-of-done.md) — Performance section (Section 8)
- [Development Dimensions Guide](/process-framework/guides/framework/development-dimensions-guide.md) — PE dimension definition
