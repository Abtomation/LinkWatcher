---
id: PF-TSK-084
type: Process Framework
category: Task Definition
domain: agnostic
version: 1.1
created: 2026-04-09
updated: 2026-04-13
---

# Performance Test Creation

## Purpose & Context

Implement performance tests from a performance test specification. This task covers measurement design, threshold-setting against baselines, test registration in performance-test-tracking.md, and lifecycle transition from ⬜ Specified to 📋 Created.

Implement performance tests identified by the [Performance & E2E Test Scoping task (PF-TSK-086)](/process-framework/tasks/03-testing/performance-and-e2e-test-scoping-task.md). Performance test needs appear as `⬜ Specified` entries in performance-test-tracking.md after the scoping task applies the [decision matrix](/process-framework/guides/03-testing/performance-and-e2e-test-scoping-guide.md#performance-test-decision-matrix) against a feature's code changes.

## AI Agent Role

**Role**: Performance Test Engineer
**Mindset**: Measurement-focused, threshold-aware, cross-cutting perspective
**Focus Areas**: Reliable measurement methodology, appropriate tolerance bands, proper test isolation, tracking registration
**Communication Style**: Present each test's measurement approach and threshold rationale at checkpoints; ask about acceptable performance ranges when thresholds are ambiguous

## When to Use

- When performance-test-tracking.md has `⬜ Specified` entries created by the [Performance & E2E Test Scoping task (PF-TSK-086)](/process-framework/tasks/03-testing/performance-and-e2e-test-scoping-task.md)
- When expanding performance coverage after discovering gaps during Baseline Capture
- Standalone when adding performance coverage for untested areas

## Context Requirements

- **Critical (Must Read):**

  - [Performance Testing Guide](/process-framework/guides/03-testing/performance-testing-guide.md) — Test levels, measurement methodology, threshold-setting, avoiding flaky benchmarks
  - [Performance & E2E Test Scoping Guide](/process-framework/guides/03-testing/performance-and-e2e-test-scoping-guide.md) — Decision matrix that produced the `⬜ Specified` entries
  - [Performance Test Tracking](/test/state-tracking/permanent/performance-test-tracking.md) — Current test inventory and baselines

- **Important (Load If Space):**

  - [Test File Creation Guide](/process-framework/guides/03-testing/test-file-creation-guide.md) — pytest markers, file organization
  - Existing performance test files in `test/automated/performance/` — for pattern consistency

- **Reference Only (Access When Needed):**
  - [Performance Results Database](/process-framework/scripts/test/performance_db.py) — For recording initial measurements
  - [Visual Notation Guide](/process-framework/guides/support/visual-notation-guide.md) — For interpreting context map diagrams

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished! 🚨**
>
> **⚠️ MANDATORY: Follow the Performance Testing Guide for measurement methodology.**

### Preparation

1. **Read performance-test-tracking.md** and identify all `⬜ Specified` entries. These were created by the [Performance & E2E Test Scoping task (PF-TSK-086)](/process-framework/tasks/03-testing/performance-and-e2e-test-scoping-task.md) using the [decision matrix](/process-framework/guides/03-testing/performance-and-e2e-test-scoping-guide.md#performance-test-decision-matrix). Each entry includes the test level, target subsystem, and rationale.

2. **Review existing tests** to understand coverage and patterns. Check if any existing tests partially cover the specified entries.

4. **🚨 CHECKPOINT**: Present the list of tests to implement with proposed levels, operations, and threshold rationale. Get human approval before writing test code.

### Execution

5. **Implement tests** following the Performance Testing Guide methodology:
   - Choose the appropriate test file (or create a new one following naming conventions)
   - Use required pytest markers: `@pytest.mark.performance`, `@pytest.mark.test_type("performance")`, `@pytest.mark.feature("cross-cutting")`
   - Add `@pytest.mark.slow` for tests expected to take >10 seconds
   - Print measured values in test output for baseline capture
   - Assert against tolerance thresholds, not exact values

6. **Update tracking file** — for each test implemented, transition its status using the automation script:
   ```bash
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/update/Update-PerformanceTracking.ps1 -TestId "<BM-xxx|PH-xxx>" -NewStatus "Created" -TestFile "[test_file.py](/test/automated/performance/test_file.py)"
   ```
   The script transitions `⬜ Specified → 📋 Created`, fills the Test File column, and recalculates the Summary table automatically.

7. **Run the new tests** to verify they pass and produce measurable output:
   ```bash
   python -m pytest test/automated/performance/<test_file>.py -v -s -k "<test_name>"
   ```

8. **🚨 CHECKPOINT**: Present test results, measured values, and threshold rationale for human review.

### Finalization

9. **Verify tracking file summary** — the Summary table is recalculated automatically by the update script. Verify counts are correct.

10. **Verify all specified tests are accounted for** — grep for `⬜ Specified` in the tracking file. Any remaining entries are deferred to a future session.

11. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Tools and Scripts

- **[Update-PerformanceTracking.ps1](/process-framework/scripts/update/Update-PerformanceTracking.ps1)** — Automate status transitions and column updates in performance-test-tracking.md (⬜ → 📋 with `-TestFile`)
- **[New-FeedbackForm.ps1](/process-framework/scripts/file-creation/support/New-FeedbackForm.ps1)** — Create feedback forms for task completion

## Outputs

- **New/updated performance test files** in `test/automated/performance/`
- **Updated performance-test-tracking.md** — new rows at `📋 Created` status with test file references
- **Test execution output** — measured values for each new test (used by Baseline Capture task)

## State Tracking

The following state files must be updated as part of this task:

- [Performance Test Tracking](/test/state-tracking/permanent/performance-test-tracking.md) — Add rows, update statuses ⬜ → 📋, update summary
- [Feature Tracking](/doc/state-tracking/permanent/feature-tracking.md) — Update if test coverage changes affect feature status

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

Before considering this task finished:

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] All tests from the spec are implemented or explicitly deferred with rationale
  - [ ] Each new test has required pytest markers
  - [ ] Each new test prints measured values in output
  - [ ] All new tests pass when run
- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] [Performance Test Tracking](/test/state-tracking/permanent/performance-test-tracking.md) rows updated (⬜ → 📋)
  - [ ] Summary table recalculated
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Guide](../../guides/framework/feedback-form-guide.md) for each tool used, using task ID "PF-TSK-084" and context "Performance Test Creation"

## Next Tasks

- **[Test Audit](/process-framework/tasks/03-testing/test-audit-task.md)** (with `-TestType Performance`) — Audit newly created performance tests before baseline capture. Tests must reach `🔍 Audit Approved` status before proceeding to Baseline Capture
- **[Performance Baseline Capture](/process-framework/tasks/03-testing/performance-baseline-capture-task.md)** — Run the newly created tests and capture initial baselines (📋 → ✅). Requires `🔍 Audit Approved` audit status
- **[Code Review](/process-framework/tasks/06-maintenance/code-review-task.md)** — Review new test code for quality

## Related Resources

- [Performance Testing Guide](/process-framework/guides/03-testing/performance-testing-guide.md) — Measurement methodology and best practices
- [Performance Test Tracking](/test/state-tracking/permanent/performance-test-tracking.md) — Test registry and baselines
- [Test Specification Creation](/process-framework/tasks/03-testing/test-specification-creation-task.md) — Automated test specification task (does not route performance tests)
- [Performance Baseline Capture](/process-framework/tasks/03-testing/performance-baseline-capture-task.md) — Downstream task that records baselines
