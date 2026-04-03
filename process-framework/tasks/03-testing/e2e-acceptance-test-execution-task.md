---
id: PF-TSK-070
type: Process Framework
category: Task Definition
domain: agnostic
version: 1.1
created: 2026-03-15
updated: 2026-03-18
---

# E2E Acceptance Test Execution

## Purpose & Context

Execute E2E acceptance test cases systematically, record results, and report issues discovered through human interaction with the running system. This task is primarily executed by the **human partner**, with the AI agent assisting with environment setup, result recording, and bug reporting.

E2E acceptance test execution validates system behavior that cannot be covered by automated tests — scenarios requiring real user interaction, visual confirmation, timing-dependent behavior, or end-to-end system validation.

## AI Agent Role

**Role**: QA Support Assistant
**Mindset**: Organized, precise, detail-oriented about recording outcomes
**Focus Areas**: Environment setup, result recording, bug report creation, tracking updates
**Communication Style**: Guide human partner through test sequences, prompt for observations, help document findings accurately

## When to Use

- After code changes that affect tested functionality — e2e-test-tracking.md shows groups marked `🔄 Needs Re-execution`
- After E2E acceptance test cases are created — initial validation of new test cases
- As part of release validation — all test groups must pass before deployment
- When investigating a suspected regression — targeted execution of specific groups

## Context Requirements

[View Context Map for this task (PF-VIS-050)](../../visualization/context-maps/03-testing/e2e-acceptance-test-execution-map.md)

- **Critical (Must Read):**

  - [E2E Test Tracking](../../../test/state-tracking/permanent/e2e-test-tracking.md) — Identifies which groups need re-execution and current status of all E2E acceptance tests
  - **Master test file** for the target group — Defines the quick validation sequence
  - **Individual test-case.md files** — Exact steps, preconditions, expected results

- **Important (Load If Space):**

  - [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) — Feature-level test coverage overview
  - **Test case `project/` and `expected/` directories** — Fixtures and expected state for automated comparison

- **Reference Only (Access When Needed):**
  - [E2E Acceptance Test Case Creation Task](manual-test-case-creation-task.md) — If test cases need updates during execution
  - [Bug Triage Task](../06-maintenance/bug-triage-task.md) — For reporting discovered failures
  - [Visual Notation Guide](/process-framework/guides/support/visual-notation-guide.md) — For interpreting context map diagrams

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished! 🚨**
>
> **⚠️ NOTE: This task is primarily executed by the human partner. The AI agent assists with setup, recording, and tracking.**

### Preparation

1. **Identify what needs testing**: Review [e2e-test-tracking.md](../../../test/state-tracking/permanent/e2e-test-tracking.md) for groups marked `🔄 Needs Re-execution`. Also check the **Workflow Milestone Tracking** section for workflows with `⬜ Not Created` status — these may need test case creation (PF-TSK-069) first. For release validation, identify all groups that must pass.
2. **Install code changes globally** (if code was modified since last install): Ensure the system under test uses the latest code. For Python projects: `pip install -e .` from the project root. Skip if no code changes since last install.
3. **Set up test environment**: Run [Setup-TestEnvironment.ps1](../../scripts/test/e2e-acceptance-testing/Setup-TestEnvironment.ps1) to copy pristine templates into the workspace:
   ```bash
   cd process-framework/scripts/test/e2e-acceptance-testing && pwsh.exe -ExecutionPolicy Bypass -Command '& .\Setup-TestEnvironment.ps1 -Group "group-name" -Clean -Confirm:$false'
   ```
   > Omit `-Group` to set up all groups. Use `-Clean` to remove any previous workspace state.
4. **Review the master test** for the target group to understand the quick validation sequence

### Execution

5. **Check for scripted test cases**: If test cases have `Execution Mode: scripted` (i.e., they have a `run.ps1` file), offer the human partner a choice:
   - **Run automatically** via [Run-E2EAcceptanceTest.ps1](../../scripts/test/e2e-acceptance-testing/Run-E2EAcceptanceTest.ps1) — stops project LW, starts a workspace-scoped LW per test case (fast scan), then runs Setup → settle → run.ps1 → wait → Verify:
     ```bash
     cd process-framework/scripts/test/e2e-acceptance-testing && pwsh.exe -ExecutionPolicy Bypass -Command '& .\Run-E2EAcceptanceTest.ps1 -Group "group-name" -Clean -Detailed'
     ```
     > Use `-SettleSeconds N` (default: 3) to adjust the delay between scan completion and test action. Use `-WaitSeconds N` (default: 5) for propagation delay after the action.
   - **Run manually** — human follows the Steps section in test-case.md (same as manual test cases)
   > If all test cases in a group are scripted and the human chooses automatic execution, `Run-E2EAcceptanceTest.ps1` handles the entire pipeline. Skip to step 8 for result recording.
6. **Execute master test first** (manual test cases): Follow the master test's Quick Validation Sequence step by step
   - **If master test passes** → Group is validated. Skip to step 9.
   - **If master test fails** → Continue to step 7 to isolate the issue.
7. **Execute individual test cases** (manual test cases): Follow each test-case.md's Steps section exactly. For each test case:
   - Verify preconditions are met
   - Execute steps in order
   - Observe and record actual results
   - Compare against expected results
8. **Verify results** (manual test cases only — scripted tests verify automatically): Run [Verify-TestResult.ps1](../../scripts/test/e2e-acceptance-testing/Verify-TestResult.ps1) to compare workspace against expected state:
   ```bash
   cd process-framework/scripts/test/e2e-acceptance-testing && pwsh.exe -ExecutionPolicy Bypass -Command '& .\Verify-TestResult.ps1 -Group "group-name" -Detailed'
   ```
   > Use `-TestCase "E2E-NNN"` for a single test case. Use `-Detailed` to see line-by-line diffs for failures.
8a. **On failure — root cause analysis**: When a test case fails, the AI agent MUST investigate the root cause before proceeding. Check system logs, trace the event flow, and identify whether the failure is caused by a code defect, test fixture issue, infrastructure problem, or environmental factor. Document the root cause clearly.
   > **🚨 CRITICAL**: Do NOT propose or attempt to fix the issue during test execution. The purpose of this task is to discover and document failures, not to fix them. Fixes belong in a separate Bug Fixing task (PF-TSK-048).
8b. **On failure — always file a bug**: Every test failure MUST result in a bug report, regardless of root cause. Add the bug entry to [bug-tracking.md](../../../doc/state-tracking/permanent/bug-tracking.md) with: root cause analysis, affected test cases, component involved, and severity assessment. Increment the PD-BUG counter in [PD ID Registry](/doc/PD-id-registry.json).

### Finalization

9. **Record results**: For **scripted tests**, `Run-E2EAcceptanceTest.ps1` automatically calls `Update-TestExecutionStatus.ps1` per test case after verification (use `-SkipTracking` to disable). For **non-scripted tests** or to add a `-Reason` to failures, run manually:
   ```bash
   cd process-framework/scripts/test/e2e-acceptance-testing && pwsh.exe -ExecutionPolicy Bypass -Command '& .\Update-TestExecutionStatus.ps1 -Group "group-name" -Status "Passed" -Confirm:$false'
   ```
   > For failures, use `-Status "Failed" -Reason "PD-BUG-NNN: description of failure"`. Always reference the bug ID.
10. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Outputs

- **Updated e2e-test-tracking.md** — Execution status (`✅ Passed` or `🔴 Failed`), Last Executed date for each tested group/case
- **Updated feature-tracking.md** — Test Status updated based on execution results
- **Bug reports** (if failures found) — Created via `New-BugReport.ps1` for genuine defects
- **Test session log** (optional) — In `test/e2e-acceptance-testing/results/` for audit trail

## State Tracking

The following state files are updated as part of this task:

- [E2E Test Tracking](../../../test/state-tracking/permanent/e2e-test-tracking.md) — Update execution status and Last Executed date for each tested group/case (automated via `Update-TestExecutionStatus.ps1`)
- [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) — Update Test Status based on execution results (automated via `Update-TestExecutionStatus.ps1`)

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

Before considering this task finished:

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] All targeted test groups have been executed (master test or individual cases)
  - [ ] Results recorded via `Update-TestExecutionStatus.ps1`
  - [ ] Bug reports created for any genuine defects
- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] [E2E Test Tracking](../../../test/state-tracking/permanent/e2e-test-tracking.md) — execution status and dates updated
  - [ ] [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) — Test Status reflects current state
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Completion Instructions](../../guides/framework/feedback-form-completion-instructions.md) for each tool used, using task ID "PF-TSK-070" and context "E2E Acceptance Test Execution"

## Next Tasks

- [**Bug Triage**](../06-maintenance/bug-triage-task.md) — For any failures discovered during execution
- [**E2E Acceptance Test Case Creation**](manual-test-case-creation-task.md) — If execution reveals missing test coverage or test cases that need updates

## Related Resources

- [E2E Acceptance Test Case Creation Task](manual-test-case-creation-task.md) — Upstream task that creates the test cases executed here
- [Setup-TestEnvironment.ps1](../../scripts/test/e2e-acceptance-testing/Setup-TestEnvironment.ps1) — Environment setup script
- [Run-E2EAcceptanceTest.ps1](../../scripts/test/e2e-acceptance-testing/Run-E2EAcceptanceTest.ps1) — Orchestrator for scripted test cases (workspace-scoped LW → Setup → settle → run.ps1 → wait → Verify)
- [Verify-TestResult.ps1](../../scripts/test/e2e-acceptance-testing/Verify-TestResult.ps1) — Result verification script
- [Update-TestExecutionStatus.ps1](../../scripts/test/e2e-acceptance-testing/Update-TestExecutionStatus.ps1) — Status update script
- [New-BugReport.ps1](../../scripts/file-creation/06-maintenance/New-BugReport.ps1) — Bug report creation script for discovered defects
