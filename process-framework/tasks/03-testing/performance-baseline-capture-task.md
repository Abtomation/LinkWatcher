---
id: PF-TSK-085
type: Process Framework
category: Task Definition
domain: agnostic
version: 1.2
created: 2026-04-09
updated: 2026-04-30
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
- When performance-test-tracking.md has ⚠️ Needs Re-baseline entries that need refresh
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

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished!**

### Preparation

1. **[Performance Test Tracking](/test/state-tracking/permanent/performance-test-tracking.md)** to identify which tests to run:
   - `📋 Needs Baseline` entries → need initial baselines
   - `⚠️ Needs Re-baseline` entries → need re-capture
   - `✅ Baselined` entries → run for regression check if triggered by code change
   - Optionally filter by Related Features column if triggered by a specific feature change

2. **🚨 Verify audit gate for `📋 Needs Baseline` entries**: Before capturing baselines for newly created tests, the **Audit Status** column in performance-test-tracking.md must be `✅ Audit Approved`. Any other value — empty, `⬜ Not Audited`, `🔄 Needs Update`, `🔴 Audit Failed` — blocks baseline capture; the test must pass [Test Audit (PF-TSK-030)](/process-framework/tasks/03-testing/test-audit-task.md) with `-TestType Performance` first. This gate does **not** apply to `⚠️ Needs Re-baseline` or `✅ Baselined` entries (they were already audited when first created).

3. **Check environment** — close unnecessary applications, ensure consistent test conditions. Note any environmental factors that could affect results.

### Execution

4. **Run performance tests**:
   ```bash
   # Run all performance tests
   python -m pytest test/automated/performance/ -v -s -m performance

   # Or run specific tests by file
   python -m pytest test/automated/performance/test_benchmark.py -v -s

   # Or run by Related Features (if filtering)
   python -m pytest test/automated/performance/ -v -s -k "bm_001 or bm_003"
   ```

   > **Measurement strategy**:
   > - **Default**: Run each test 3 times; record the **mean** as the canonical baseline value; capture the run-to-run range in `--notes` (e.g., `"3 runs: 4.7-4.9 MB/s"`).
   > - **High variance** (3-run spread >10%): use the **median** instead of mean; flag in notes (e.g., `"3 runs: 42-58 files/sec, median 49"`).
   > - **Warm-cache steady-state baselines**: drop run 1 (cold-cache) and average runs 2–3; tag notes accordingly (e.g., `"warm-cache mean of runs 2-3, run 1 cold: 6.2 MB/s"`).
   > - **Smoke checks** (single-run opportunistic captures, e.g., spot-check before deeper investigation): allowed, but tag notes with `"smoke check, single run"` so trend analysis can exclude them.

5. **Extract measured values** from test output. For each test, note the primary metric (throughput, latency, completion time).

   > **Note on 1:N pytest-to-ID mapping**: One pytest method can produce measurements for multiple BM/PH IDs. For example, `test_bm_002_database_operations` covers BM-002 (adds), BM-007 (lookups), and BM-008 (updates) because the operations share setup. Don't expect a 1:1 mapping between collected pytest cases and BM/PH IDs — check the test method's docstring and printed output for the full ID coverage.

6. **Record results in the database**:
   ```bash
   # Single-metric test
   python process-framework/scripts/test/performance_db.py record \
       --test-id BM-NNN --value 144.0 --unit "files/sec" --notes "Pre-release capture"

   # Multi-metric test (one record call per metric)
   python process-framework/scripts/test/performance_db.py record \
       --test-id PH-001 --metric scan --value 9.21 --unit "seconds" --notes "Pre-release capture"
   python process-framework/scripts/test/performance_db.py record \
       --test-id PH-001 --metric move --value 0.16 --unit "seconds" --notes "Pre-release capture"
   ```

7. **Check for regressions**:
   ```bash
   python process-framework/scripts/test/performance_db.py regressions
   ```

8. **🚨 CHECKPOINT**: Present results summary:
   - Tests run and their measured values
   - Comparison to previous baselines (% change)
   - Any regressions detected
   - Any notable trends

### Regression Handling

9. **If regressions detected**:
   - Identify the likely cause (recent commits, environmental change)
   - Assess severity: tolerance breach vs. trend degradation
   - **Tolerance breach** → file as bug via Bug Triage (PF-TSK-024)
   - **Trend degradation (>5% over 3+ captures)** → file as tech debt item
   - Present regression analysis to human partner for decision

   > **Stale-baseline artifacts are auto-excluded.** `performance_db.py regressions` skips rows in `⚠️ Needs Re-baseline` status (their tolerances are known-stale by definition) and surfaces them in a separate "skipped" footer. Anything that does appear in the REGRESSIONS DETECTED list is therefore a real breach against a current baseline — proceed with Bug Triage. For rows in the skipped footer, the next action is re-baseline (capture in this same task), not Bug Triage.

### Finalization

10. **Update performance-test-tracking.md** using the automation script for each tested entry. For multi-metric tests, pass `-Metric` to disambiguate the row:
   ```bash
   # Initial baseline (Created → Baselined)
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/update/Update-PerformanceTracking.ps1 -TestId "<BM-xxx|PH-xxx>" -NewStatus "Baselined" -Baseline "<value with units>" -LastResult "<measured value>"

   # Multi-metric test (one invocation per metric row)
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/update/Update-PerformanceTracking.ps1 -TestId "PH-001" -Metric "scan" -NewStatus "Baselined" -LastResult "9.30s"

   # Refresh existing baseline results (Baselined → Baselined)
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/update/Update-PerformanceTracking.ps1 -TestId "<BM-xxx|PH-xxx>" -NewStatus "Baselined" -LastResult "<measured value>"

   # Intentional re-baseline with new threshold (Stale → Baselined)
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/update/Update-PerformanceTracking.ps1 -TestId "<BM-xxx|PH-xxx>" -NewStatus "Baselined" -Baseline "<new baseline>" -LastResult "<measured value>"

   # Mark as stale (code changed significantly since last capture)
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/update/Update-PerformanceTracking.ps1 -TestId "<BM-xxx|PH-xxx>" -NewStatus "Stale"
   ```
   The script handles status transitions, column updates, LastRun date (auto-populated), and Summary table recalculation automatically.

11. **Review trends** for key tests:
    ```bash
    python process-framework/scripts/test/performance_db.py trend --test-id BM-NNN --last 5
    ```

12. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Tools and Scripts

- **[Update-PerformanceTracking.ps1](/process-framework/scripts/update/Update-PerformanceTracking.ps1)** — Automate status transitions, column updates, and summary recalculation in performance-test-tracking.md (📋 → ✅, refresh results, mark ⚠️ Needs Re-baseline)
- **[performance_db.py](/process-framework/scripts/test/performance_db.py)** — Record measurements, query trends, detect regressions (`record`, `trend`, `regressions` subcommands)
- **[New-FeedbackForm.ps1](/process-framework/scripts/file-creation/support/New-FeedbackForm.ps1)** — Create feedback forms for task completion

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

**TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF**

Before considering this task finished:

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] All targeted tests were run successfully
  - [ ] Results recorded in performance-results.db via performance_db.py
  - [ ] Regressions check completed (`performance_db.py regressions`)
  - [ ] Any regressions filed appropriately (bug or tech debt)
- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] [Performance Test Tracking](/test/state-tracking/permanent/performance-test-tracking.md) — Last Result, Last Run, Status columns updated
  - [ ] Summary table recalculated
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Guide](../../guides/framework/feedback-form-guide.md) for each tool used, using task ID "PF-TSK-085" and context "Performance Baseline Capture"

## Next Tasks

- **[Code Review](/process-framework/tasks/06-maintenance/code-review-task.md)** — If regressions found, review the causing commits
- **[Bug Fixing](/process-framework/tasks/06-maintenance/bug-fixing-task.md)** — If regression filed as bug
- **[Release & Deployment](/process-framework/tasks/07-deployment/release-deployment-task.md)** — If this was a pre-release capture with no regressions

## Related Resources

- [Performance Testing Guide](/process-framework/guides/03-testing/performance-testing-guide.md) — Baseline management and trend analysis
- [Performance Test Tracking](/test/state-tracking/permanent/performance-test-tracking.md) — Test registry and baselines
- [Performance Results Database](/process-framework/scripts/test/performance_db.py) — Trend storage and query tool
- [Performance Test Creation](/process-framework/tasks/03-testing/performance-test-creation-task.md) — Upstream task that creates tests
- [Test Audit](/process-framework/tasks/03-testing/test-audit-task.md) — Audit gate task; `📋 Needs Baseline` tests must be audited before baseline capture
