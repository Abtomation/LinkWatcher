---
id: PF-TSK-084
type: Process Framework
category: Task Definition
domain: agnostic
version: 1.0
created: 2026-04-09
updated: 2026-04-09
---

# Performance Test Creation

## Purpose & Context

Implement performance tests from a performance test specification. This task covers measurement design, threshold-setting against baselines, test registration in performance-test-tracking.md, and lifecycle transition from ⬜ Specified to 📋 Created.

Implement performance tests identified through the [Performance Testing Guide](/process-framework/guides/03-testing/performance-testing-guide.md) decision matrix. Performance test needs are identified after implementation when the actual code changes can be assessed against the decision matrix criteria (parser changes, algorithm changes, scaling characteristics, etc.).

## AI Agent Role

**Role**: Performance Test Engineer
**Mindset**: Measurement-focused, threshold-aware, cross-cutting perspective
**Focus Areas**: Reliable measurement methodology, appropriate tolerance bands, proper test isolation, tracking registration
**Communication Style**: Present each test's measurement approach and threshold rationale at checkpoints; ask about acceptable performance ranges when thresholds are ambiguous

## When to Use

- After implementation, when the [Performance Testing Guide](/process-framework/guides/03-testing/performance-testing-guide.md) decision matrix identifies performance test needs (e.g., parser changes, algorithm changes, scaling characteristics)
- When performance-test-tracking.md has `⬜ Specified` entries that need implementation
- When expanding performance coverage after discovering gaps during Baseline Capture
- Standalone when adding performance coverage for untested areas

## Context Requirements

- **Critical (Must Read):**

  - **Performance Testing Guide** — [Decision matrix](/process-framework/guides/03-testing/performance-testing-guide.md#decision-matrix) determining which test levels apply to the code changes
  - [Performance Testing Guide](/process-framework/guides/03-testing/performance-testing-guide.md) — Test levels, measurement methodology, threshold-setting, avoiding flaky benchmarks
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

1. **Identify performance tests needed** using the [Performance Testing Guide decision matrix](/process-framework/guides/03-testing/performance-testing-guide.md#decision-matrix). For each affected component, determine the test level (Component/Operation/Scale/Resource), operation description, and success criteria.

2. **Read performance-test-tracking.md** to understand existing coverage. Note any `⬜ Specified` entries that already exist for the tests in the spec.

3. **Pre-populate tracking file** — for each test in the spec that doesn't have a tracking entry yet, add a row with status `⬜ Specified`, linking the Spec Ref column to the spec section.

4. **🚨 CHECKPOINT**: Present the list of tests to implement with proposed levels, operations, and threshold rationale. Get human approval before writing test code.

### Execution

5. **Implement tests** following the Performance Testing Guide methodology:
   - Choose the appropriate test file (or create a new one following naming conventions)
   - Use required pytest markers: `@pytest.mark.performance`, `@pytest.mark.test_type("performance")`, `@pytest.mark.feature("cross-cutting")`
   - Add `@pytest.mark.slow` for tests expected to take >10 seconds
   - Print measured values in test output for baseline capture
   - Assert against tolerance thresholds, not exact values

6. **Update tracking file** — for each test implemented, update its row from `⬜ Specified` → `📋 Created`. Fill in the Test File column.

7. **Run the new tests** to verify they pass and produce measurable output:
   ```bash
   python -m pytest test/automated/performance/<test_file>.py -v -s -k "<test_name>"
   ```

8. **🚨 CHECKPOINT**: Present test results, measured values, and threshold rationale for human review.

### Finalization

9. **Update tracking file summary** — recalculate the Summary table counts.

10. **Verify all specified tests are accounted for** — grep for `⬜ Specified` in the tracking file. Any remaining entries are deferred to a future session.

11. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

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
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Completion Instructions](../../guides/framework/feedback-form-completion-instructions.md) for each tool used, using task ID "PF-TSK-084" and context "Performance Test Creation"

## Next Tasks

- **[Performance Baseline Capture](/process-framework/tasks/03-testing/performance-baseline-capture-task.md)** — Run the newly created tests and capture initial baselines (📋 → ✅)
- **[Code Review](/process-framework/tasks/06-maintenance/code-review-task.md)** — Review new test code for quality

## Related Resources

- [Performance Testing Guide](/process-framework/guides/03-testing/performance-testing-guide.md) — Measurement methodology and best practices
- [Performance Test Tracking](/test/state-tracking/permanent/performance-test-tracking.md) — Test registry and baselines
- [Test Specification Creation](/process-framework/tasks/03-testing/test-specification-creation-task.md) — Automated test specification task (does not route performance tests)
- [Performance Baseline Capture](/process-framework/tasks/03-testing/performance-baseline-capture-task.md) — Downstream task that records baselines
