---
id: PF-TSK-070
type: Process Framework
category: Task Definition
domain: agnostic
version: 1.0
created: 2026-03-15
updated: 2026-03-15
task_type: Discrete
---

# Manual Test Execution

## Purpose & Context

Execute manual test cases systematically, record results, and report issues discovered through human interaction with the running system. This task is primarily executed by the **human partner**, with the AI agent assisting with environment setup, result recording, and bug reporting.

Manual test execution validates system behavior that cannot be covered by automated tests — scenarios requiring real user interaction, visual confirmation, timing-dependent behavior, or end-to-end system validation.

## AI Agent Role

**Role**: QA Support Assistant
**Mindset**: Organized, precise, detail-oriented about recording outcomes
**Focus Areas**: Environment setup, result recording, bug report creation, tracking updates
**Communication Style**: Guide human partner through test sequences, prompt for observations, help document findings accurately

## When to Use

- After code changes that affect tested functionality — test-tracking.md shows groups marked `🔄 Needs Re-execution`
- After manual test cases are created — initial validation of new test cases
- As part of release validation — all test groups must pass before deployment
- When investigating a suspected regression — targeted execution of specific groups

## Context Requirements

[View Context Map for this task (PF-VIS-050)](../../visualization/context-maps/03-testing/manual-test-execution-map.md)

- **Critical (Must Read):**

  - [Test Tracking](../../state-tracking/permanent/test-tracking.md) — Identifies which groups need re-execution and current status of all manual tests
  - **Master test file** for the target group — Defines the quick validation sequence
  - **Individual test-case.md files** — Exact steps, preconditions, expected results

- **Important (Load If Space):**

  - [Feature Tracking](../../state-tracking/permanent/feature-tracking.md) — Feature-level test coverage overview
  - **Test case `project/` and `expected/` directories** — Fixtures and expected state for automated comparison

- **Reference Only (Access When Needed):**
  - [Manual Test Case Creation Task](manual-test-case-creation-task.md) — If test cases need updates during execution
  - [Bug Triage Task](../06-maintenance/bug-triage-task.md) — For reporting discovered failures
  - [Visual Notation Guide](/doc/process-framework/guides/support/visual-notation-guide.md) — For interpreting context map diagrams

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished! 🚨**
>
> **⚠️ NOTE: This task is primarily executed by the human partner. The AI agent assists with setup, recording, and tracking.**

### Preparation

1. **Identify what needs testing**: Review [test-tracking.md](../../state-tracking/permanent/test-tracking.md) for groups marked `🔄 Needs Re-execution`. For release validation, identify all groups that must pass.
2. **Set up test environment**: Run [Setup-TestEnvironment.ps1](../../scripts/test/manual-testing/Setup-TestEnvironment.ps1) to copy pristine templates into the workspace:
   ```bash
   cd /c/path/to/project/doc/process-framework/scripts/testing && pwsh.exe -ExecutionPolicy Bypass -Command '& .\Setup-TestEnvironment.ps1 -Group "group-name" -Clean -Confirm:$false'
   ```
   > Omit `-Group` to set up all groups. Use `-Clean` to remove any previous workspace state.
3. **Review the master test** for the target group to understand the quick validation sequence

### Execution

4. **Execute master test first** (human partner): Follow the master test's Quick Validation Sequence step by step
   - **If master test passes** → Group is validated. Skip to step 7.
   - **If master test fails** → Continue to step 5 to isolate the issue.
5. **Execute individual test cases** (human partner): Follow each test-case.md's Steps section exactly. For each test case:
   - Verify preconditions are met
   - Execute steps in order
   - Observe and record actual results
   - Compare against expected results
6. **Verify results**: Run [Verify-TestResult.ps1](../../scripts/test/manual-testing/Verify-TestResult.ps1) to compare workspace against expected state:
   ```bash
   cd /c/path/to/project/doc/process-framework/scripts/testing && pwsh.exe -ExecutionPolicy Bypass -Command '& .\Verify-TestResult.ps1 -Group "group-name" -Detailed'
   ```
   > Use `-TestCase "MT-NNN"` for a single test case. Use `-Detailed` to see line-by-line diffs for failures.

### Finalization

7. **Record results**: Run [Update-TestExecutionStatus.ps1](../../scripts/test/manual-testing/Update-TestExecutionStatus.ps1) to update tracking files:
   ```bash
   cd /c/path/to/project/doc/process-framework/scripts/testing && pwsh.exe -ExecutionPolicy Bypass -Command '& .\Update-TestExecutionStatus.ps1 -Group "group-name" -Status "Passed" -Confirm:$false'
   ```
   > For failures, use `-Status "Failed" -Reason "description of failure"`.
8. **Report bugs**: For test failures that indicate genuine defects, create bug reports using [New-BugReport.ps1](../../scripts/file-creation/06-maintenance/New-BugReport.ps1):
   ```bash
   cd /c/path/to/project/doc/process-framework/scripts/file-creation && pwsh.exe -ExecutionPolicy Bypass -Command '& .\New-BugReport.ps1 -Title "Brief description" -Description "Detailed description" -DiscoveredBy "Testing" -Severity "High" -Component "ComponentName" -Confirm:$false'
   ```
9. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Outputs

- **Updated test-tracking.md** — Execution status (`✅ Passed` or `🔴 Failed`), Last Executed date for each tested group/case
- **Updated feature-tracking.md** — Test Status updated based on execution results
- **Bug reports** (if failures found) — Created via `New-BugReport.ps1` for genuine defects
- **Test session log** (optional) — In `test/manual-testing/results/` for audit trail

## State Tracking

The following state files are updated as part of this task:

- [Test Tracking](../../state-tracking/permanent/test-tracking.md) — Update execution status and Last Executed date for each tested group/case (automated via `Update-TestExecutionStatus.ps1`)
- [Feature Tracking](../../state-tracking/permanent/feature-tracking.md) — Update Test Status based on execution results (automated via `Update-TestExecutionStatus.ps1`)

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

Before considering this task finished:

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] All targeted test groups have been executed (master test or individual cases)
  - [ ] Results recorded via `Update-TestExecutionStatus.ps1`
  - [ ] Bug reports created for any genuine defects
- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] [Test Tracking](../../state-tracking/permanent/test-tracking.md) — execution status and dates updated
  - [ ] [Feature Tracking](../../state-tracking/permanent/feature-tracking.md) — Test Status reflects current state
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Completion Instructions](../../guides/framework/feedback-form-completion-instructions.md) for each tool used, using task ID "PF-TSK-070" and context "Manual Test Execution"

## Next Tasks

- [**Bug Triage**](../06-maintenance/bug-triage-task.md) — For any failures discovered during execution
- [**Manual Test Case Creation**](manual-test-case-creation-task.md) — If execution reveals missing test coverage or test cases that need updates

## Related Resources

- [Manual Test Case Creation Task](manual-test-case-creation-task.md) — Upstream task that creates the test cases executed here
- [Setup-TestEnvironment.ps1](../../scripts/test/manual-testing/Setup-TestEnvironment.ps1) — Environment setup script
- [Verify-TestResult.ps1](../../scripts/test/manual-testing/Verify-TestResult.ps1) — Result verification script
- [Update-TestExecutionStatus.ps1](../../scripts/test/manual-testing/Update-TestExecutionStatus.ps1) — Status update script
- [New-BugReport.ps1](../../scripts/file-creation/06-maintenance/New-BugReport.ps1) — Bug report creation script for discovered defects
