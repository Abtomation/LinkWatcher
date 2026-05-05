---
id: PF-TSK-007
type: Process Framework
category: Task Definition
version: 2.1
created: 2023-06-15
updated: 2026-05-05
---

# Bug Fixing

## Purpose & Context

Diagnose, fix, and verify solutions for reported bugs or issues in the application, ensuring software quality and maintaining user trust by promptly addressing defects in the system.

## AI Agent Role

**Role**: Debugging Specialist
**Mindset**: Methodical, root-cause focused, systematic
**Focus Areas**: Issue reproduction, root cause analysis, prevention strategies, systematic debugging
**Communication Style**: Ask detailed questions about symptoms and context, request specific reproduction steps, discuss prevention measures

## When to Use

- When a bug has been reported and needs to be fixed
- When an issue has been identified during testing
- When a regression has been detected in existing functionality
- When a security vulnerability has been discovered
- When a performance issue has been identified

## Context Requirements

[View Context Map for this task](../../visualization/context-maps/06-maintenance/bug-fixing-map.md)

- **Critical (Must Read):**

  - [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md) - Central bug registry and status tracking
  - Specific source files containing the bug
  - Tests related to the affected functionality
  - [Visual Notation Guide](/process-framework/guides/support/visual-notation-guide.md) - For interpreting context map diagrams

- **Important (Load If Space):**

  - [Project Architecture](/doc/technical/architecture) - Understanding of the system architecture

- **Reference Only (Access When Needed):**
  - [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) - To understand feature relationships and priorities when bugs affect specific features
  - [Bug Fix State Template](../../templates/06-maintenance/bug-fix-state-tracking-template.md) - For multi-session complex bug fixes (Large effort)
  - [Test File Creation Guide](../../guides/03-testing/test-file-creation-guide.md) - For creating new test files when coverage gaps are identified

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished!**
>
> **⚠️ MANDATORY: Always create or update tests to verify fixes and prevent regression.**
>
> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

### Preparation

> **🚨 SCOPE GUARD — Framework path target**: This task is for **product code defects only**. If the affected file(s) live in `process-framework/`, `process-framework-local/`, or a root-level routing file (`CLAUDE.md`, `MEMORY.md`, `ai-tasks.md`), this task does **NOT** apply. Framework defects are tracked as IMPs and resolved through [Process Improvement](../support/process-improvement-task.md) (PF-TSK-009) — file via [New-ProcessImprovement.ps1](../../scripts/file-creation/support/New-ProcessImprovement.ps1), not [New-BugReport.ps1](../../scripts/file-creation/06-maintenance/New-BugReport.ps1). **Stop now and switch tasks.** See [ai-tasks.md framework-vs-product policy](../../ai-tasks.md#step-1-what-are-you-working-on).

1. Review the [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md) document to identify a bug ready for fixing (status 🔍 Needs Fix)
2. If no bugs with status 🔍 Needs Fix are found but bugs with status 🆕 Needs Triage exist, **ask the human partner** whether to switch to [Bug Triage](bug-triage-task.md) first. Do not proceed with an un-triaged bug.
3. Verify the selected bug has been properly triaged with priority, scope, and **affected dimensions** (Dims column) assigned. Read the affected dimensions to understand which quality concerns the fix must address (e.g., `SE DI` means the fix must ensure both security and data integrity). For Large-scope bugs with a bug fix state file, review the Affected Dimensions and Dimension-Informed Fix Requirements sections.
4. **Assess workflow blast radius**: Check the **Workflows** column in the bug entry (or look up the Related Feature in [User Workflow Tracking](../../../doc/state-tracking/permanent/user-workflow-tracking.md)) to identify which user workflows are affected. This informs the scope of testing needed — a bug affecting WF-001 (single file move) impacts the core value proposition and requires thorough regression testing across all referencing formats.
5. **Multi-session gate**: If the bug scope is "L" (Large) or requires architectural changes (e.g., redesigning a component, changing cross-cutting patterns), create a bug fix state tracking file:
   ```powershell
   cd process-framework/scripts/file-creation
   New-BugFixState.ps1 -BugId "PD-BUG-XXX" -BugTitle "Bug Title" -Severity "High" -AffectedFeature "X.Y.Z — Feature Name" -EstimatedSessions 2
   ```
   After creation, **customize the state file to the specific bug**: fill in the Implementation Progress table with the files/components that will need changing, identify which documents need updating in the Documentation Updates table, and outline the resolution plan in the Fix Approach section. This plan serves as the blueprint for the fix and enables session handover.
   **Notes column rule**: When a state file exists, keep the Notes column in bug-tracking.md minimal — link to the state file and a one-line status summary only. All session progress, root cause details, and fix approaches belong in the state file, not inline.
   For single-session bugs (Small/Medium effort), skip this step — no state file needed.
6. **Check manual test coverage**: Review [e2e-test-tracking.md](../../../test/state-tracking/permanent/e2e-test-tracking.md) for existing E2E test cases covering the affected behavior. If no E2E test exists and the bug involves user-observable behavior, consider creating a reproduction test case via [E2E Test Case Creation](../03-testing/e2e-acceptance-test-case-creation-task.md) before fixing.
7. Reproduce the bug to understand its exact behavior and confirm the issue
   - For code-structural bugs (e.g., missing error handling, absent code paths), confirming the gap through code review serves as reproduction
8. Document the reproduction steps for future reference
9. Analyze the affected code area to understand the context
10. Update bug status from 🔍 Needs Fix to 🟡 In Progress
   - **Automated Option**: Use [`Update-BugStatus.ps1`](../../scripts/update/Update-BugStatus.ps1) script:
     ```powershell
     ../../scripts/update/Update-BugStatus.ps1 -BugId "BUG-001" -NewStatus "InProgress"
     ```
11. **🚨 CHECKPOINT**: Present reproduction results, affected code area analysis, workflow blast radius, and proposed investigation approach to human partner
   - **S-scope quick path**: If the bug meets **all** quick path criteria — (1) Scope = S, (2) no E2E test groups affected, (3) root cause is obvious or already known — then this session combines triage (if needed), fix, and self-review into a single flow:
     - If the bug is 🆕 Needs Triage: perform inline triage — assign priority, scope=S, related feature, dims — and transition to 🔍 Needs Fix using `Update-BugStatus.ps1 -NewStatus "NeedsFix" -Priority "..." -Scope "S" -RelatedFeature "..." -Dims "..."`
     - Combine with Step 14 — present reproduction, root cause analysis, and proposed fix approach in a single checkpoint
     - After approval, skip directly to Step 15
     - After human approval at Step 23 checkpoint: close the bug in one call using `-FastClose`:
       ```powershell
       ../../scripts/update/Update-BugStatus.ps1 -BugId "BUG-001" -FastClose -Priority "Medium" -Scope "S" -RelatedFeature "1.1.1" -Dims "CQ" -FixDetails "..." -RootCause "..." -TestsAdded "Yes" -VerificationNotes "S-scope quick path: human-approved at checkpoint"
       ```
       This chains NeedsFix → InProgress → Closed in a single script call. No separate Code Review task needed.
     - Skip Step 24. Proceed directly to the completion checklist (Step 33)
   - **M/L-scope bugs**: Combine with Step 14 — present reproduction, root cause analysis, and proposed fix approach in a single checkpoint. After approval, skip directly to Step 15.
   - **Not-a-bug**: If investigation reveals the reported issue is expected behavior, user error, already fixed, or otherwise not a bug — present the evidence to the human partner. If they agree, transition to **Rejected** and skip to finalization:
     ```powershell
     ../../scripts/update/Update-BugStatus.ps1 -BugId "BUG-001" -NewStatus "Rejected" -RejectionReason "Not a bug — [evidence summary]"
     ```
     Then skip directly to Step 29 (verify tracking update) → Step 33 (completion checklist). Steps 12–28 do not apply.
   - **Won't Fix**: If investigation confirms a real bug but the fix cost is disproportionate to impact (e.g., requires architectural changes for an edge case, performance fix with negligible real-world benefit) — present the cost/benefit analysis to the human partner. If they agree, transition to **Rejected** and skip to finalization:
     ```powershell
     ../../scripts/update/Update-BugStatus.ps1 -BugId "BUG-001" -NewStatus "Rejected" -RejectionReason "Won't fix — [cost/benefit rationale]"
     ```
     Then skip directly to Step 29 (verify tracking update) → Step 33 (completion checklist). Steps 12–28 do not apply.
   - **Other**: For rejection rationales not matching the above (e.g., duplicate of in-flight work where the bug is the user-observable symptom of an already-tracked TD/IMP/feature) — present the evidence to the human partner. If they agree, transition to **Rejected** with a clear RejectionReason naming the rationale and any relevant tracker. If the rejection cross-references another tracked item, also add a back-reference from that item to the bug for bidirectional traceability:
     ```powershell
     ../../scripts/update/Update-BugStatus.ps1 -BugId "BUG-001" -NewStatus "Rejected" -RejectionReason "[Rationale summary] — [evidence/tracker reference]"
     ```
     Then skip directly to Step 29 (verify tracking update) → Step 33 (completion checklist). Steps 12–28 do not apply.

### Execution

12. Analyze the code to identify the root cause of the bug
    - **If multi-session**: Update the Root Cause Analysis section in the bug fix state file
13. Consider alternative approaches to fixing the issue
    - **If multi-session**: Document chosen approach and alternatives in the Fix Approach section
    - **Scope reassessment**: If root cause analysis reveals the fix is simpler than the triaged scope suggested (e.g., L-scope bug requires only a small, isolated change), reassess the scope downward. Present the revised scope at the Step 14 checkpoint — if approved, the multi-session gate (Step 5) no longer applies: archive any state file created prematurely, and proceed as a single-session fix.
14. **🚨 CHECKPOINT**: Present root cause analysis, proposed fix approach (with alternatives and trade-offs), and test strategy to human partner for approval
    - **S-scope bugs**: If already covered in the combined Step 11 checkpoint, skip this step.
15. **Write regression test(s) BEFORE implementing the fix** — this confirms the test actually catches the bug:
    - Write test(s) that reproduce the exact bug scenario and verify they **FAIL**
    - **Verify the test fails for the right reason**: Inspect the failure output — confirm the test setup actually exercises the target code path and that the failure corresponds to the bug, not to a setup error, import issue, or unrelated assertion. A test that fails for the wrong reason gives false confidence when it later "passes."
    - **Test strategy**:
      - Prefer unit tests for isolated logic bugs; add integration tests when the bug involves component interaction
      - If the root cause is a pattern (e.g., off-by-one, null handling), add 1-2 boundary/edge case tests beyond the reproduction test
      - **Use strong assertions**: Assert the old/buggy value is **NOT** present (negative assertion), not just that the new/correct value **IS** present (positive assertion). Overly permissive tests that only check for the expected value can pass even when the bug persists alongside the fix.
      - Keep regression tests focused on the specific fix — note pre-existing test gaps for a future test audit rather than expanding scope here
    - **Decision: new file vs. existing file**:
      - **Create a new test file** when: (1) no existing test file covers the affected component, (2) the bug spans multiple components not covered by a single existing file, or (3) the bug reveals a new category of behavior that doesn't fit existing test organization
      - **Add to an existing file** (default): when a test file already covers the affected component — follow existing patterns in that file
    - **Adding to an existing test file**: Find the relevant test file in the project's test directory (see `paths.tests` in `project-config.json`). Add regression test(s) following the existing patterns in the file. After adding, update the test's pytest markers if needed (feature, priority). Then update the "Test Cases Count" column for the affected file in [test-tracking.md](../../../test/state-tracking/permanent/test-tracking.md) — this is not automated when adding to existing files (only `New-TestFile.ps1` sets the initial count for new files).
    - **Creating a new test file**: Use [`New-TestFile.ps1`](../../scripts/file-creation/03-testing/New-TestFile.ps1) which writes pytest markers and auto-updates test-tracking.md and feature-tracking.md:
      ```powershell
      cd process-framework/scripts/file-creation
      New-TestFile.ps1 -TestName "BugDescription" -TestType "Unit" -FeatureId "X.Y.Z" -ComponentName "ComponentName"
      ```
    - **If multi-session**: Note test file changes in the Implementation Progress table
    - After creating or modifying tests, complete the documentation steps in the [Test File Creation Guide — Test Documentation Completeness](/process-framework/guides/03-testing/test-file-creation-guide.md#5-complete-test-documentation) section.
16. Develop a fix that addresses the root cause, not just the symptoms
    - **If multi-session**: Track each file change in the Implementation Progress table
17. Verify regression tests now **PASS** with the fix applied, and test thoroughly to ensure the fix resolves the issue completely
    - **If multi-session (architectural changes)**: Run the full test suite and document results in the Validation Status section of the bug fix state file
18. **Run full regression test suite** (`Run-Tests.ps1 -All`) to confirm the fix doesn't introduce regressions elsewhere. If E2E tests exist for the affected feature, set their status to "Needs Re-execution" in e2e-test-tracking.md.
19. Verify that the fix doesn't introduce new problems
20. Check for similar issues in other parts of the codebase
    - If the root cause is a shared pattern (e.g., regex, utility function), check **all** components that use the same pattern
    - Prioritize sibling components (same role/type, e.g., all parsers, all handlers) as they most likely share the same code pattern
21. **Create a manual validation test** in the project's manual test directory — write it **before implementing the fix** so the bug is observable first:
    - The test must set up a scenario the human partner can **reproduce via UI or filesystem actions** — not via programmatic API calls
    - Print or display **before/after state** so the human can compare the result with and without the fix
    - Example: a script that creates a temp environment with the conditions that trigger the bug, prints the current (buggy) state, then instructs the human to apply the trigger action and observe the result
    - *Skip this step when:*
      - The bug has no observable behavior (e.g., dead code removal, internal refactoring)
      - The bug is non-UI / non-filesystem (e.g., internal logic error, code-structural fix) with no user-observable symptom
      - Existing automated tests already reproduce the exact scenario — manual validation would duplicate coverage
22. **Session boundary** (multi-session only): If ending a session before the fix is complete, update the Session Log in the bug fix state file with completed work and next-session plan. The next session resumes from this state file.
23. **🚨 CHECKPOINT**: Present fix results for human approval before updating bug status:
    - Code changes summary (files modified, approach taken)
    - Test results (regression tests pass, full suite regression check)
    - Manual validation test results (if applicable, from Step 21)
    - Similar issues found and addressed (from Step 20)
    - **E2E verification** (if bug was discovered via E2E testing): Run the specific E2E test(s) that originally exposed the bug using [`Run-E2EAcceptanceTest.ps1`](/process-framework/scripts/test/e2e-acceptance-testing/Run-E2EAcceptanceTest.ps1) and include pass/fail results in the checkpoint presentation
    - **Dimension verification**: Confirm the fix addresses all affected dimensions from the bug's Dims column (e.g., if DI was flagged, confirm atomicity/recovery is handled; if SE was flagged, confirm input validation is addressed)
    > **ADR trigger**: If the fix changed architectural behavior, introduced a new pattern, or made a design trade-off not covered by existing ADRs, create an ADR using [New-ArchitectureDecision.ps1](/process-framework/scripts/file-creation/02-design/New-ArchitectureDecision.ps1) and the [Architecture Decision Creation Guide](/process-framework/guides/02-design/architecture-decision-creation-guide.md).
    > **L-scope test scoping assessment**: For L-scope bugs with architectural changes, evaluate whether the fix changes feature behavior significantly enough to warrant performance or E2E test scoping. If yes, note in the checkpoint presentation that after Code Review the bug should route to PF-TSK-086 (`🔎 Needs Test Scoping`) instead of directly to `🔒 Closed`.
24. Update bug status from 🟡 In Progress to 👀 Needs Review (S-scope quick path: skip this step — already closed at Step 11)
    - **Automated Option**: Use [`Update-BugStatus.ps1`](../../scripts/update/Update-BugStatus.ps1) script:
      ```powershell
      ../../scripts/update/Update-BugStatus.ps1 -BugId "BUG-001" -NewStatus "NeedsReview" -FixDetails "Fixed null pointer exception" -RootCause "Missing null check" -TestsAdded "Yes" -PullRequestUrl "https://github.com/repo/pull/123"
      ```

### Finalization

25. **Mark manual test groups for re-execution**: If the fix affects functionality covered by manual tests, run `Update-TestExecutionStatus.ps1` to mark affected groups:
    ```bash
    pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/test/e2e-acceptance-testing/Update-TestExecutionStatus.ps1 -FeatureId "X.Y.Z" -Status "Needs Re-execution" -Reason "Bug fix PD-BUG-XXX" -Confirm:\$false
    ```
26. Document the nature of the bug and the solution approach
27. **Update feature documentation** (if the fix changes technical design or behavior):
    - **Feature implementation state file** (`state-tracking/features/`) — update implementation notes, known issues, or status
    - **TDD** — update technical design descriptions that no longer match the code
    - **Test specification** — update expected behavior or add new test scenarios
    - **FDD** — update functional behavior descriptions if user-facing behavior changed
    - **Integration Narrative** (`doc/technical/integration/`) — update if the fix changes how features interact in a cross-feature workflow documented by a PD-INT narrative
    - *Before marking N/A: briefly check each referenced document to confirm it does not describe the changed component or behavior. Skip only after verifying no documentation references the fix area.*
    - **If multi-session**: Update the Documentation Updates table in the bug fix state file
28. Refactor code if necessary for better maintainability
29. Verify the fix resolves the issue completely
30. **Run test tracking validation** (if tests were added or modified):
    ```powershell
    process-framework/scripts/validation/Validate-TestTracking.ps1
    ```
    Fix any mismatches in `testCasesCount` or missing registry entries before proceeding.
31. **If multi-session**: Archive the bug fix state file to `doc/state-tracking/temporary/old` after the bug is closed
32. **Batch opportunity**: Check [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md) for additional bugs with status 🔍 Needs Fix. Ask the human partner if they want to fix another bug in this session before proceeding to the feedback form. If yes, loop back to Step 1 (Preparation) for the next bug. Defer the feedback form until all bugs in the session are complete.
    > **Note**: Bug status transitions to 🔒 Closed happen in Code Review (PF-TSK-005), not in this task — except for S-scope quick path bugs which are closed at Step 11. This task exits at 👀 Needs Review for M/L-scope bugs.
33. **🚨 MANDATORY FINAL STEP**: Complete the Task Completion Checklist below

## Outputs

- **Modified Source Code** - Source code files that fix the bug
- **Updated Tests** - New or updated test files that verify the fix
- **Bug Fix Documentation** - Documentation of the root cause and solution approach
- **Updated Bug Tracking** - [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md) with bug status and resolution details updated

## State Tracking

The following state files must be updated as part of this task:

- [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md) - Update with:
  - Bug status progression: 🔍 Needs Fix → 🟡 In Progress → 👀 Needs Review (then Code Review closes to 🔒 Closed), or S-scope quick path: 🟡 In Progress → 🔒 Closed at checkpoint, or 🟡 In Progress → ❌ Rejected (not-a-bug, won't-fix, or other rationale per Step 11)
  - Fix date and resolution details
  - Root cause analysis and solution approach
  - Link to relevant pull request or commit (if applicable)
  - Any lessons learned for future development
  - Testing verification results
  - For bugs affecting specific features: Reference related feature ID from [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md)
- **Conditional — multi-session** (only for Large-effort or architectural bugs):
  - [Bug fix state file](/doc/state-tracking/temporary) — created via [`New-BugFixState.ps1`](../../scripts/file-creation/06-maintenance/New-BugFixState.ps1), tracks root cause, fix approach, implementation progress, validation status, and session log. Archive to `doc/state-tracking/temporary/old/` when bug is closed.
  - **Notes column**: When a state file exists, the bug-tracking.md Notes column should contain only a link to the state file and a one-line status summary (e.g., `See [state file](path). Session 2/3 complete.`). Do not duplicate session logs or fix details inline.
- **Conditional** (only when fix changes technical design or behavior):
  - [Feature implementation state files](/doc/state-tracking/features/) — update implementation notes, known issues, or status
  - TDD for the affected feature — update technical design descriptions
  - Test specification for the affected feature — update expected behavior or test scenarios
  - FDD for the affected feature — update functional behavior descriptions

**Automation Support**: The [`Update-BugStatus.ps1`](../../scripts/update/Update-BugStatus.ps1) script can automate status updates and ensure consistent formatting. While manual updates are supported, the script provides standardized status transitions and automatic timestamp tracking.

## ⚠️ MANDATORY Task Completion Checklist

**TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF**

Before considering this task finished:

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] Source code changes properly fix the bug
  - [ ] Tests verify the fix and prevent regression
  - [ ] Test Registry updated (new entry or updated `testCasesCount`, ID counter bumped if new entry)
  - [ ] Bug fix documentation clearly explains the issue and solution
  - [ ] All modified files follow coding standards
- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] Bug tracking document shows proper status progression and final status
  - [ ] Fix date, root cause analysis, and solution approach are recorded
  - [ ] Testing verification results are documented
  - [ ] Any lessons learned are documented for future reference
  - [ ] Related feature references are updated if bug affects specific features
  - [ ] If fix changed technical design or behavior (Step 27):
    - [ ] Feature implementation state file updated, or N/A — verified file does not reference changed component
    - [ ] TDD updated, or N/A — verified no design changes affect TDD
    - [ ] Test specification updated, or N/A — verified no behavior change affects spec
    - [ ] FDD updated, or N/A — verified no functional change affects FDD
  - [ ] If multi-session: bug fix state file archived to `doc/state-tracking/temporary/old`
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Guide](../../guides/framework/feedback-form-guide.md) for each tool used, using task ID "PF-TSK-007" and context "Bug Fixing"

## Next Tasks

- [**Code Review**](code-review-task.md) - Reviews the bug fix for quality and correctness; transitions bug from 👀 Needs Review → 🔒 Closed on approval (not needed for S-scope quick path)
- [**Performance & E2E Test Scoping**](../03-testing/performance-and-e2e-test-scoping-task.md) - If L-scope fix changes feature behavior significantly (AI agent self-assessment at Step 23)
- [**Manual Test Case Creation**](../03-testing/e2e-acceptance-test-case-creation-task.md) - Create reproduction/verification test cases for the bug (if not already created in Step 6)
- [**Manual Test Execution**](../03-testing/e2e-acceptance-test-execution-task.md) - Validate the fix through manual testing of affected test groups
- [**Bug Triage**](bug-triage-task.md) - If additional bugs are discovered during fixing
- [**Feature Implementation Planning**](../04-implementation/feature-implementation-planning-task.md) - If the bug fix reveals the need for new functionality
- [**Test Specification Creation**](../03-testing/test-specification-creation-task.md) - If systemic test gaps are discovered during bug investigation that warrant a formal test specification

## Related Resources

- [Visual Notation Guide](/process-framework/guides/support/visual-notation-guide.md) - For interpreting context map diagrams and component relationships
- [Task Creation and Improvement Guide](../../guides/support/task-creation-guide.md) - Guide for creating and improving tasks
