---
id: PF-TSK-085
type: Process Framework
category: Task Definition
domain: agnostic
version: 1.0
created: 2026-04-09
updated: 2026-04-09
---

# Performance Baseline Capture

## Purpose & Context

Run performance tests, record results in the trend database, update the tracking file with latest values, and flag regressions. This is a lightweight recurring task that establishes and maintains performance baselines.

Unlike Performance Test Creation (which writes test code), this task **executes** existing tests and **records** their results for trend analysis.

## AI Agent Role

**Role**: Performance Analyst
**Mindset**: Data-driven, trend-aware, regression-sensitive
**Focus Areas**: Accurate measurement capture, trend interpretation, regression identification, baseline currency
**Communication Style**: Report results factually with trend context; flag regressions immediately with severity assessment

## When to Use

- After Performance Test Creation — new tests need initial baselines (📋 → ✅)
- After code changes to hot paths — verify no regression
- Pre-release verification — capture release baseline, confirm no regressions
- When performance-test-tracking.md has ⚠️ Stale entries that need refresh
- Periodic health check (e.g., quarterly or before major releases)

## Context Requirements

- **Critical (Must Read):**

  - [Performance Test Tracking](/test/state-tracking/permanent/performance-test-tracking.md) — Current baselines and lifecycle statuses
  - [Performance Testing Guide](/process-framework/guides/03-testing/performance-testing-guide.md) — Baseline management and trend analysis sections

- **Important (Load If Space):**

  - [Performance Results Database](/process-framework/scripts/test/performance_db.py) — record/trend/regressions subcommands
  - Recent git log — to correlate results with code changes

- **Reference Only (Access When Needed):**
  - [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md) — For filing degradation-related tech debt
  - [Visual Notation Guide](/process-framework/guides/support/visual-notation-guide.md) — For interpreting context map diagrams

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished! 🚨**

### Preparation

1. **Read performance-test-tracking.md** to identify which tests to run:
   - `📋 Created` entries → need initial baselines
   - `⚠️ Stale` entries → need re-capture
   - `✅ Baselined` entries → run for regression check if triggered by code change
   - Optionally filter by Related Features column if triggered by a specific feature change

2. **Check environment** — close unnecessary applications, ensure consistent test conditions. Note any environmental factors that could affect results.

### Execution

3. **Run performance tests**:
   ```bash
   # Run all performance tests
   python -m pytest test/automated/performance/ -v -s -m performance

   # Or run specific tests by file
   python -m pytest test/automated/performance/test_benchmark.py -v -s

   # Or run by Related Features (if filtering)
   python -m pytest test/automated/performance/ -v -s -k "bm_001 or bm_003"
   ```

4. **Extract measured values** from test output. For each test, note the primary metric (throughput, latency, completion time).

5. **Record results in the database**:
   ```bash
   # Record each measurement
   python process-framework/scripts/test/performance_db.py record \
       --test-id BM-001 --value 144.0 --unit "files/sec" --notes "Pre-release capture"

   # Repeat for each test
   ```

6. **Check for regressions**:
   ```bash
   python process-framework/scripts/test/performance_db.py regressions
   ```

7. **🚨 CHECKPOINT**: Present results summary:
   - Tests run and their measured values
   - Comparison to previous baselines (% change)
   - Any regressions detected
   - Any notable trends

### Regression Handling

8. **If regressions detected**:
   - Identify the likely cause (recent commits, environmental change)
   - Assess severity: tolerance breach vs. trend degradation
   - **Tolerance breach** → file as bug via Bug Triage (PF-TSK-024)
   - **Trend degradation (>5% over 3+ captures)** → file as tech debt item
   - Present regression analysis to human partner for decision

### Finalization

9. **Update performance-test-tracking.md**:
   - Update Last Result and Last Run columns for all tested entries
   - Transition `📋 Created` → `✅ Baselined` for newly baselined tests
   - Update Baseline column if this is an intentional re-baseline
   - Mark entries as `⚠️ Stale` if code has changed significantly since last capture
   - Recalculate Summary table

10. **Review trends** for key tests:
    ```bash
    python process-framework/scripts/test/performance_db.py trend --test-id BM-001 --last 5
    ```

11. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Outputs

- **Updated performance-test-tracking.md** — latest results and lifecycle transitions
- **New entries in performance-results.db** — historical measurements for trend analysis
- **Regression report** (if any) — filed as bug or tech debt item

## State Tracking

The following state files must be updated as part of this task:

- [Performance Test Tracking](/test/state-tracking/permanent/performance-test-tracking.md) — Update results, statuses, and summary
- [Bug Tracking](/doc/state-tracking/permanent/bug-tracking.md) — If regression filed as bug
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md) — If trend degradation filed as debt

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

Before considering this task finished:

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] All targeted tests were run successfully
  - [ ] Results recorded in performance-results.db via performance_db.py
  - [ ] Regressions check completed (`performance_db.py regressions`)
  - [ ] Any regressions filed appropriately (bug or tech debt)
- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] [Performance Test Tracking](/test/state-tracking/permanent/performance-test-tracking.md) — Last Result, Last Run, Status columns updated
  - [ ] Summary table recalculated
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Completion Instructions](../../guides/framework/feedback-form-completion-instructions.md) for each tool used, using task ID "PF-TSK-085" and context "Performance Baseline Capture"

## Next Tasks

- **[Code Review](/process-framework/tasks/06-maintenance/code-review-task.md)** — If regressions found, review the causing commits
- **[Bug Fixing](/process-framework/tasks/06-maintenance/bug-fixing-task.md)** — If regression filed as bug
- **[Release & Deployment](/process-framework/tasks/07-deployment/release-deployment-task.md)** — If this was a pre-release capture with no regressions

## Related Resources

- [Performance Testing Guide](/process-framework/guides/03-testing/performance-testing-guide.md) — Baseline management and trend analysis
- [Performance Test Tracking](/test/state-tracking/permanent/performance-test-tracking.md) — Test registry and baselines
- [Performance Results Database](/process-framework/scripts/test/performance_db.py) — Trend storage and query tool
- [Performance Test Creation](/process-framework/tasks/03-testing/performance-test-creation-task.md) — Upstream task that creates tests
