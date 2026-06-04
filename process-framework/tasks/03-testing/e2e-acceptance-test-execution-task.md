---
id: PF-TSK-070
type: Process Framework
category: Task Definition
domain: agnostic
version: 1.3
created: 2026-03-15
updated: 2026-05-16
description: "Execute E2E acceptance test cases systematically, record results, and report issues through human interaction with the running system"
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

## Context Requirements

[View Context Map for this task](../../visualization/context-maps/03-testing/e2e-acceptance-test-execution-map.md)

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
  - [Visual Notation Guide](../../guides/support/visual-notation-guide.md) — For interpreting context map diagrams

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished!**
>
> **⚠️ NOTE: This task is primarily executed by the human partner. The AI agent assists with setup, recording, and tracking.**

### Preparation

1. **Identify what needs testing**: Review [e2e-test-tracking.md](../../../test/state-tracking/permanent/e2e-test-tracking.md) for groups marked `🔄 Needs Re-execution`. Also check the **Workflow Milestone Tracking** section for workflows with `⬜ Not Created` status — these may need test case creation (PF-TSK-069) first. For release validation, identify all groups that must pass.

2. **🚨 Verify audit gate for `📋 Needs Execution` entries**: Before executing newly created test cases, confirm their **Audit Status** column shows `✅ Audit Approved` in e2e-test-tracking.md. Test cases at `📋 Needs Execution` that have not been audited (Audit Status is empty or `⬜ Not Audited`) **must** pass [Test Audit (PF-TSK-030)](test-audit-task.md) with `-TestType E2E` first. This gate does **not** apply to `🔄 Needs Re-execution` entries (they were already audited when first created).
3. **Install code changes globally** (if code was modified since last install): Ensure the system under test uses the latest code. Run `python deployment/install_global.py` from the project root — this copies source files, creates/updates the dedicated LinkWatcher venv, and updates startup scripts. Skip if no code changes since last install.
4. **Set up test environment**: Run [Setup-TestEnvironment.ps1](../../scripts/test/e2e-acceptance-testing/Setup-TestEnvironment.ps1) to copy pristine templates into the workspace:
   ```bash
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/test/e2e-acceptance-testing/Setup-TestEnvironment.ps1 -Workflow "workflow-slug" -Clean -Confirm:\$false
   ```
   > Omit `-Workflow` to set up all workflows. Use `-Clean` to remove any previous workspace state.
   > Per-workflow paths (PF-IMP-871 Phase 3c2): templates and workspace live under `test/e2e-acceptance-testing/<workflow-slug>/`.
5. **Review the master test** for the target group to understand the quick validation sequence

### Execution

6. **Check for scripted test cases**: If test cases have `Execution Mode: scripted` (i.e., they have a `run.ps1` file), offer the human partner a choice:
   - **Run automatically** via [Run-E2EAcceptanceTest.ps1](../../scripts/test/e2e-acceptance-testing/Run-E2EAcceptanceTest.ps1) — runs Setup → run.ps1 → optional wait → Verify:
     ```bash
     pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/test/e2e-acceptance-testing/Run-E2EAcceptanceTest.ps1 -Workflow "workflow-slug" -Clean -Detailed
     ```
     > Use `-WaitSeconds N` (default: 0) when the action triggers asynchronous effects that need time to settle before verification.
   - **Run manually** — human follows the Steps section in test-case.md (same as manual test cases)
   > If all test cases in a group are scripted and the human chooses automatic execution, `Run-E2EAcceptanceTest.ps1` handles the entire pipeline. Skip to step 9 for result recording.
6a. **Start workspace-scoped LinkWatcher** (manual test cases only — scripted tests handle this automatically):
    Manual E2E tests need LinkWatcher watching the test workspace, not the project root. Before executing manual test steps:
    ```bash
    # 1. Stop project-level LinkWatcher
    pwsh.exe -ExecutionPolicy Bypass -Command 'Get-Content .linkwatcher.lock | ForEach-Object { Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue }'

    # 2. Start workspace-scoped LinkWatcher (adjust path to the test case workspace)
    python main.py --project-root test/e2e-acceptance-testing/<workflow-slug>/workspace/<test-case-id> --debug &

    # 3. Wait for initial scan to complete before executing test steps
    ```
    > After testing, stop the workspace LW (`kill` or Ctrl+C) and restart the project-level LW: `process-framework/tools/linkWatcher/start_linkwatcher_background.ps1`
7. **Execute master test first** (manual test cases): Follow the master test's Quick Validation Sequence step by step
   - **If master test passes** → Group is validated. Skip to step 10.
   - **If master test fails** → Continue to step 8 to isolate the issue.
8. **Execute individual test cases** (manual test cases): Follow each test-case.md's Steps section exactly. For each test case:
   - Verify preconditions are met
   - Execute steps in order
   - Observe and record actual results
   - Compare against expected results
9. **Verify results** (manual test cases only — scripted tests verify automatically): Run [Verify-TestResult.ps1](../../scripts/test/e2e-acceptance-testing/Verify-TestResult.ps1) to compare workspace against expected state:
   ```bash
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/test/e2e-acceptance-testing/Verify-TestResult.ps1 -Workflow "workflow-slug" -Detailed
   ```
   > Use `-TestCase "E2E-NNN"` for a single test case. Use `-Detailed` to see line-by-line diffs for failures.
9a. **On failure — root cause analysis**: When a test case fails, the AI agent MUST investigate the root cause before proceeding. Check system logs, trace the event flow, and identify whether the failure is caused by a code defect, test fixture issue, infrastructure problem, or environmental factor. Document the root cause clearly.
   > **🚨 CRITICAL**: Do NOT propose or attempt to fix the issue during test execution. The purpose of this task is to discover and document failures, not to fix them. Fixes belong in a separate Bug Fixing task (PF-TSK-007).
9b. **On failure — always file a bug**: Every test failure MUST result in a bug report, regardless of root cause. Add the bug entry to [bug-tracking.md](../../../doc/state-tracking/permanent/bug-tracking.md) with: root cause analysis, affected test cases, component involved, and severity assessment. Increment the PD-BUG counter in [PD ID Registry](../../../doc/PD-id-registry.json).

### Finalization

10. **Record results**: For **scripted tests**, `Run-E2EAcceptanceTest.ps1` automatically calls `Update-TestExecutionStatus.ps1` per test case after verification (use `-SkipTracking` to disable). For **non-scripted tests** or to add a `-Reason` to failures, run manually:
    ```bash
    pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/test/e2e-acceptance-testing/Update-TestExecutionStatus.ps1 -Workflow "WF-001" -Status "Passed" -Confirm:\$false
    ```
    > `-Workflow` matches the Workflow column (WF-NNN or workflow slug) in e2e-test-tracking.md. For failures, use `-Status "Failed" -Reason "PD-BUG-NNN: description of failure"`. Always reference the bug ID.
11. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Sandbox Execution (PRJ-T01 only)

> **Scope**: This section applies **only when the test case targets the appdev framework self-test sandbox** (`PRJ-T01`, located at `FrameworkBuilder/sandboxes/appdev/PRJ-000/`). It is the canonical E2E target for the Framework Self-Testing extension (PF-PRO-035). Tests targeting product projects (PRJ-001+) use the normal Setup→Verify pipeline described above and do **not** consume this section.

### Why the sandbox is different

Framework-self-test E2E cases mutate state files (`technical-debt-tracking.md`, `user-workflow-tracking.md`, registries) inside a real project tree to validate that framework scripts produce correct end-to-end behavior. Between test runs, the mutation must be reverted so the next test starts from a known baseline. The sandbox uses a **git-checkout-based reset** that intentionally invokes operations the global "Prohibited Git Commands" rule otherwise forbids:

- `git checkout HEAD -- <specific-path>` for files the test mutated (reverts to last baseline)
- `Remove-Item <specific-path>` for files the test created (deletes test-created artifacts)

### Why this is safe in the sandbox

The general prohibition exists because product-project working trees carry uncommitted work from parallel sessions; broad `git checkout --` would destroy it. None of those conditions apply in `sandboxes/appdev/PRJ-000/`:

- **Sandbox state is rollout-pipeline-owned**: no ad-hoc edits land there. Every change comes from a Push (see [Framework Rollout (PF-TSK-088)](../support/framework-rollout-task.md) Mode B) followed by `Commit-SandboxBaseline.ps1`. There is no uncommitted "work" to lose.
- **Reset is scoped, not blanket**: each invocation of `Reset-SandboxFixtures.ps1` is bound to a specific test case ID (`TE-E2E-NNN`) and operates on the explicit per-test path list in [`sandbox-reset-registry.json`](../../scripts/test/e2e-acceptance-testing/sandbox-reset-registry.json). No path not registered there is touched.
- **Reset is invoked only by the test runner**, never interactively or by other framework operations.

### Reset workflow

`Run-E2EAcceptanceTest.ps1` calls `Reset-SandboxFixtures.ps1 -TestId TE-E2E-NNN` before each test case's pre-test setup, against the sandbox path resolved from `project-registry.json` PRJ-T01. The reset:

1. Reads the per-test path lists from `sandbox-reset-registry.json` (two arrays: `mutates` for files reverted via `git checkout HEAD --`, `creates` for files removed via `Remove-Item`).
2. Applies `git checkout HEAD -- <path>` for every entry in `mutates` (working in the sandbox's own git repo; no effect on appdev or any product project).
3. Applies `Remove-Item -Force <path>` for every entry in `creates`.
4. Exits non-zero if any path fails to reset (test runner aborts the test rather than running against a contaminated baseline).

### What the test author registers

When authoring a new framework-self-test E2E case (`TE-E2E-NNN`), the author:

1. Identifies which sandbox files the case will mutate (e.g., `doc/state-tracking/permanent/technical-debt-tracking.md`).
2. Identifies which files the case will create (e.g., a new task definition file at `process-framework/tasks/support/<test-task-slug>.md`).
3. Adds an entry to [`sandbox-reset-registry.json`](../../scripts/test/e2e-acceptance-testing/sandbox-reset-registry.json):

   ```json
   {
     "TE-E2E-003": {
       "description": "Update-TechDebt -Add sandbox test",
       "mutates": ["doc/state-tracking/permanent/technical-debt-tracking.md"],
       "creates": []
     }
   }
   ```

4. The case's `run.ps1` does not need to call the reset directly — `Run-E2EAcceptanceTest.ps1` orchestrates this.

If the sandbox's `HEAD` baseline must be updated to support a new test (e.g., a Tier B test expects a different initial `technical-debt-tracking.md` shape), run `Commit-SandboxBaseline.ps1` in the sandbox after seeding the new state. The next reset cycle uses the new baseline as the canonical pristine state.

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

**TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF**

Before considering this task finished:

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] All targeted test groups have been executed (master test or individual cases)
  - [ ] Results recorded via `Update-TestExecutionStatus.ps1`
  - [ ] Bug reports created for any genuine defects
- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] [E2E Test Tracking](../../../test/state-tracking/permanent/e2e-test-tracking.md) — execution status and dates updated
  - [ ] [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) — Test Status reflects current state
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Guide](../../guides/framework/feedback-form-guide.md) for each tool used, using task ID "PF-TSK-070" and context "E2E Acceptance Test Execution"

## Next Tasks

- [**Bug Triage**](../06-maintenance/bug-triage-task.md) — For any failures discovered during execution
- [**E2E Acceptance Test Case Creation**](manual-test-case-creation-task.md) — If execution reveals missing test coverage or test cases that need updates

## Related Resources

- [Test Audit](test-audit-task.md) — Audit gate task; `📋 Needs Execution` test cases must be audited before execution
- [E2E Acceptance Test Case Creation Task](manual-test-case-creation-task.md) — Upstream task that creates the test cases executed here
- [Setup-TestEnvironment.ps1](../../scripts/test/e2e-acceptance-testing/Setup-TestEnvironment.ps1) — Environment setup script
- [Run-E2EAcceptanceTest.ps1](../../scripts/test/e2e-acceptance-testing/Run-E2EAcceptanceTest.ps1) — Orchestrator for scripted test cases (workspace-scoped LW → Setup → settle → run.ps1 → wait → Verify)
- [Verify-TestResult.ps1](../../scripts/test/e2e-acceptance-testing/Verify-TestResult.ps1) — Result verification script
- [Update-TestExecutionStatus.ps1](../../scripts/test/e2e-acceptance-testing/Update-TestExecutionStatus.ps1) — Status update script
- [New-BugReport.ps1](../../scripts/file-creation/06-maintenance/New-BugReport.ps1) — Bug report creation script for discovered defects
