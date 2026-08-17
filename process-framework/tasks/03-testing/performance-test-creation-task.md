---
id: PF-TSK-084
type: Process Framework
category: Task Definition
domain: agnostic
version: 1.2
created: 2026-04-09
updated: 2026-06-12
description: "Implement performance tests from specifications, register in tracking, capture initial measurements"
complexity: medium
use_when: >-
  Implement performance tests from specifications, register in tracking, capture initial measurements
automation: semi
scripts:
  - ../../scripts/update/Update-PerformanceTracking.ps1
trigger_status:
  - raw: "`performance-test-tracking.md` → `⬜ Needs Creation` entries (created by PF-TSK-086)"
output_status:
  - raw: "`performance-test-tracking.md` → `⬜ Needs Creation` → `📋 Needs Baseline` → (audit gate) → `✅ Audit Approved`"
---

# Performance Test Creation

> **▶ Execute this task under the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md).** This file holds only this task's specific content; the universal contract every task shares lives once in the protocol and is mandatory here.

## Purpose & Context

Implement performance tests from a performance test specification. This task covers measurement design, threshold-setting against baselines, test registration in performance-test-tracking.md, and lifecycle transition from ⬜ Needs Creation to 📋 Needs Baseline.

Implement performance tests identified by the [Performance & E2E Test Scoping task (PF-TSK-086)](performance-and-e2e-test-scoping-task.md). Performance test needs appear as `⬜ Needs Creation` entries in performance-test-tracking.md after the scoping task applies the [decision matrix](../../../.claude/skills/perf-e2e-scoping/SKILL.md#performance-test-decision-matrix) (`perf-e2e-scoping` craft skill) against a feature's code changes.

> **Scope — framework self-testing**: This task also applies to **framework script workflows** when invoked from a framework-change task ([Process Improvement (PF-TSK-009)](../support/process-improvement-task.md), [Structure Change (PF-TSK-014)](../support/structure-change-task.md), [Framework Extension (PF-TSK-026)](../support/framework-extension-task.md)). The 4-level performance taxonomy (component / operation / scale / resource) and tracking lifecycle are identical. When invoked from appdev (PRJ-000), this task silently no-ops for missing `feature-tracking.md` entries and operates against framework-script targets registered in `performance-test-tracking.md`.

## AI Agent Role

**Role**: Performance Test Engineer
**Mindset**: Measurement-focused, threshold-aware, cross-cutting perspective
**Focus Areas**: Reliable measurement methodology, appropriate tolerance bands, proper test isolation, tracking registration
**Communication Style**: Present each test's measurement approach and threshold rationale at checkpoints; ask about acceptable performance ranges when thresholds are ambiguous

## Context Requirements

- **Critical (Must Read):**

  - [Performance Testing Guide](../../guides/03-testing/performance-testing-guide.md) — Test levels, measurement methodology, threshold-setting, avoiding flaky benchmarks
  - [`perf-e2e-scoping` craft skill](../../../.claude/skills/perf-e2e-scoping/SKILL.md) — Decision matrix that produced the `⬜ Needs Creation` entries
  - [Performance Test Tracking](../../../test/state-tracking/permanent/performance-test-tracking.md) — Current test inventory and baselines

- **Important (Load If Space):**

  - [Test Infrastructure Guide](../../guides/03-testing/test-infrastructure-guide.md) — test/ directory conventions, pytest markers, isolation rules
  - Existing performance test files in `test/automated/performance/` — for pattern consistency

- **Reference Only (Access When Needed):**
  - [Performance Results Database](../../scripts/test/performance_db.py) — For recording initial measurements

## Process

> **⚠️ MANDATORY: Follow the Performance Testing Guide for measurement methodology.**

### Preparation

1. **Read performance-test-tracking.md** and identify all `⬜ Needs Creation` entries. These were created by the [Performance & E2E Test Scoping task (PF-TSK-086)](performance-and-e2e-test-scoping-task.md) using the [decision matrix](../../../.claude/skills/perf-e2e-scoping/SKILL.md#performance-test-decision-matrix) (`perf-e2e-scoping` craft skill). Each entry includes the test level, target subsystem, and rationale.

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
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/update/Update-PerformanceTracking.ps1 -TestId "<BM-xxx|PH-xxx>" -NewStatus "NeedsBaseline" -TestFile "[test_file.py](/test/automated/performance/test_file.py)"
   ```
   The script transitions `⬜ Needs Creation → 📋 Needs Baseline`, fills the Test File column, and recalculates the Summary table automatically.

7. **Run the new tests** to verify they pass and produce measurable output:
   ```bash
   python -m pytest test/automated/performance/<test_file>.py -v -s -k "<test_name>"
   ```

8. **🚨 CHECKPOINT**: Present test results, measured values, and threshold rationale for human review.

### Finalization

9. **Verify tracking file summary** — the Summary table is recalculated automatically by the update script. Verify counts are correct.

10. **Verify all specified tests are accounted for** — grep for `⬜ Needs Creation` in the tracking file. Any remaining entries are deferred to a future session.

11. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Tools and Scripts

- **[Update-PerformanceTracking.ps1](../../scripts/update/Update-PerformanceTracking.ps1)** — Automate status transitions and column updates in performance-test-tracking.md (⬜ → 📋 with `-TestFile`)
- **[New-FeedbackForm.ps1](../../scripts/file-creation/support/New-FeedbackForm.ps1)** — Create feedback forms for task completion

## Outputs

- **New/updated performance test files** in `test/automated/performance/`
- **Updated performance-test-tracking.md** — new rows at `📋 Needs Baseline` status with test file references
- **Test execution output** — measured values for each new test (used by Baseline Capture task)

## State Tracking

The following state files must be updated as part of this task:

- [Performance Test Tracking](../../../test/state-tracking/permanent/performance-test-tracking.md) — Add rows, update statuses ⬜ → 📋, update summary
- [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) — Update if test coverage changes affect feature status

## ⚠️ MANDATORY Task Completion Checklist

> Completion discipline, output verification, and the feedback form are governed by the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md) (Phase C). The items below are the **task-specific** verifications that plug into it.

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] All tests from the spec are implemented or explicitly deferred with rationale
  - [ ] Each new test has required pytest markers
  - [ ] Each new test prints measured values in output
  - [ ] All new tests pass when run
- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] [Performance Test Tracking](../../../test/state-tracking/permanent/performance-test-tracking.md) rows updated (⬜ → 📋)
  - [ ] Summary table recalculated
- [ ] **Feedback form** completed per the [Task Execution Protocol → Feedback step](../../guides/framework/task-execution-protocol-guide.md#feedback-step) — task ID `PF-TSK-084`, context "Performance Test Creation".

## File Operations

| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | Performance test files | Manual | Test files in `test/automated/performance/` |
| **Updates** | [`performance-test-tracking.md`](../../../test/state-tracking/permanent/performance-test-tracking.md) | `Update-PerformanceTracking.ps1` | Status ⬜ → 📋, Test File column, summary recalculation |
| **Updates** | [`feature-tracking.md`](../../../doc/state-tracking/permanent/feature-tracking.md) | Manual | Update if test coverage changes affect feature status |

## Next Tasks

- **[Test Audit](test-audit-task.md)** (with `-TestType Performance`) — Audit newly created performance tests before baseline capture. Tests must reach `✅ Audit Approved` status before proceeding to Baseline Capture
- **[Performance Baseline Capture](performance-baseline-capture-task.md)** — Run the newly created tests and capture initial baselines (📋 → ✅). Requires `✅ Audit Approved` audit status
- **[Code Review](../06-maintenance/code-review-task.md)** — Review new test code for quality

<!-- merged from transition-registry entry: Performance Test Creation (PF-TSK-084) -->
### Prerequisites for Transition

- [ ] Performance tests implemented with required pytest markers
- [ ] performance-test-tracking.md updated: `⬜ Needs Creation → 📋 Needs Baseline` with Test File links
- [ ] All new tests pass when run

### Next Task Selection

```
Tests created?
├─ Yes → Test Audit (PF-TSK-030, -TestType Performance)
│   └─ Reason: Audit gate is mandatory before baseline capture
└─ Issues found during creation → Fix tests → Re-run
```

### Preparation for Next Task

1. Verify all new test entries show `📋 Needs Baseline` in performance-test-tracking.md
2. Ensure test files are committed and accessible for audit review

## Related Resources

- [Performance Testing Guide](../../guides/03-testing/performance-testing-guide.md) — Measurement methodology and best practices
- [Performance Test Tracking](../../../test/state-tracking/permanent/performance-test-tracking.md) — Test registry and baselines
- [Test Specification Creation](test-specification-creation-task.md) — Automated test specification task (does not route performance tests)
- [Performance Baseline Capture](performance-baseline-capture-task.md) — Downstream task that records baselines
