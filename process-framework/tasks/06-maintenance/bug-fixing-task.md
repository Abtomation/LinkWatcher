---
id: PF-TSK-007
type: Process Framework
category: Task Definition
version: 2.26
created: 2023-06-15
updated: 2026-09-28
description: "Diagnose and fix bugs"
complexity: medium
use_when: >-
  Implement fixes for triaged product bugs with root cause analysis and regression prevention. Triggers: 'fix this bug', 'resolve issue X', 'fix the bug from PD-BUG-NNN' (product code only).
triggers:
  - "fix this bug"
  - "resolve issue X"
  - "fix the bug from PD-BUG-NNN"
automation: semi
scripts:
  - ../../scripts/update/Update-BugStatus.ps1
  - ../../scripts/file-creation/06-maintenance/New-BugFixState.ps1
  - ../../scripts/file-creation/03-testing/New-E2EScenarioGap.ps1
  - ../../scripts/file-creation/03-testing/New-WorkflowEntry.ps1
  - ../../scripts/update/Update-TechDebt.ps1
trigger_status:
  - file: bug-tracking.md
    status: "🔍 Needs Fix"
output_status:
  - raw: "`bug-tracking.md` → `🟡 In Progress` → `👀 Needs Review` (M/L-scope) or → `🔒 Closed` (S-scope quick path); `e2e-test-tracking.md` → affected groups → `🔄 Needs Re-execution`"
next_tasks:
  - task: code-review-task.md
    condition: "Reviews the bug fix for quality and correctness; transitions bug from 👀 Needs Review → 🔒 Closed on approval (not needed for S-scope quick path)"
  - task: ../03-testing/performance-and-e2e-test-scoping-task.md
    condition: "If L-scope fix changes feature behavior significantly (AI agent self-assessment at the E2E follow-through step)"
  - task: ../03-testing/e2e-acceptance-test-case-creation-task.md
    condition: "Build the case for a scenario gap this task filed (Discovered Scenario Gaps row), in its own session"
  - task: ../03-testing/e2e-acceptance-test-execution-task.md
    condition: "Validate the fix through manual testing of affected test groups"
  - task: bug-triage-task.md
    condition: "If additional bugs are discovered during fixing"
  - task: ../04-implementation/feature-implementation-planning-task.md
    condition: "If the bug fix reveals the need for new functionality"
  - task: ../03-testing/test-specification-creation-task.md
    condition: "If systemic test gaps are discovered during bug investigation that warrant a formal test specification"
---

# Bug Fixing

> **▶ Execute this task under the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md).** This file holds only this task's specific content; the universal contract every task shares lives once in the protocol and is mandatory here.

## Purpose & Context

Diagnose, fix, and verify solutions for reported bugs or issues in the application, ensuring software quality and maintaining user trust by promptly addressing defects in the system.

## AI Agent Role

**Role**: Debugging Specialist
**Mindset**: Methodical, root-cause focused, systematic
**Focus Areas**: Issue reproduction, root cause analysis, prevention strategies, systematic debugging
**Communication Style**: Ask detailed questions about symptoms and context, request specific reproduction steps, discuss prevention measures

## Context Requirements

- **Critical (Must Read):**

  - [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md) - Central bug registry and status tracking
  - Specific source files containing the bug
  - Tests related to the affected functionality

- **Important (Load If Space):**

  - [Project Architecture](../../../doc/technical/architecture) - Understanding of the system architecture
  - [`test-authoring` craft skill](../../../.claude/skills/test-authoring/SKILL.md) - the judgment behind the Test Authoring Guide procedure Step 13 cites (discriminating condition, mutation choice, failure-signature reading, fixture capability, harness recipes), invoked at Step 13

- **Reference Only (Access When Needed):**
  - [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) - To understand feature relationships and priorities when bugs affect specific features
  - [Bug Fix State Template](../../templates/06-maintenance/bug-fix-state-tracking-template.md) - For multi-session complex bug fixes (Large effort)
  - [Test-file customization reference (`test-authoring` skill)](../../../.claude/skills/test-authoring/references/test-file-customization.md) - For creating new test files when coverage gaps are identified (replaces the retired Test File Creation Guide)

## Process

> **⚠️ MANDATORY: Always create or update tests to verify fixes and prevent regression.**
>
> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

### Preparation

> **🚨 SCOPE GUARD — Framework path target**: This task is for **product code defects only**. If the affected file(s) live in `process-framework/` or a root-level routing file (`CLAUDE.md`, `MEMORY.md`, `ai-tasks.md`), this task does **NOT** apply. Framework defects are tracked as IMPs and resolved through [Process Improvement](../support/process-improvement-task.md) (PF-TSK-009) — file via [New-ProcessImprovement.ps1](../../scripts/file-creation/support/New-ProcessImprovement.ps1), not [New-BugReport.ps1](../../scripts/file-creation/06-maintenance/New-BugReport.ps1). **Stop now and switch tasks.** See [ai-tasks.md framework-vs-product policy](../../ai-tasks.md#framework-path-vs-product-path-disambiguation).

> **↩️ Re-entry from Code Review**: a bug you left at 👀 Needs Review that now sits at 🟡 In Progress has, as the first hypothesis, been rejected by [Code Review](code-review-task.md) (PF-TSK-005) — its findings are in the bug's Notes; read them before suspecting a concurrent write. Re-enter here rather than restarting from triage, and resume where the findings point: Step 13 for a mechanical rework, Step 10 when the root cause is in question, Step 11 and the Step 12 checkpoint when the findings implicate the fix approach or open a decision fork the first pass did not have. The quick path is not available on re-entry — the fix exits at 👀 Needs Review again, where the review scopes to the delta.

0. **Check Recommended Skills**: Read the active language-config (`languages-config/{language}/{language}-config.json`) and `project-config.json` for `recommended_skills` entries keyed to `bug-fixing-task`, and invoke each at the step that uses it — the `test-authoring` craft at Step 13, so it is fresh when the tests are written.
1. Review the [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md) document to identify a bug ready for fixing (status 🔍 Needs Fix)
2. If no bugs with status 🔍 Needs Fix are found but bugs with status 🆕 Needs Triage exist, **ask the human partner** whether to switch to [Bug Triage](bug-triage-task.md) first. Do not proceed with an un-triaged bug.
3. Verify the selected bug has been properly triaged with priority, scope, and **affected dimensions** (Dims column — codes in the [Dimension Abbreviation Reference](../../guides/framework/development-dimensions-guide.md#dimension-abbreviation-reference)) assigned. Read the affected dimensions to understand which quality concerns the fix must address (e.g., `SE DI` means the fix must ensure both security and data integrity). For Large-scope bugs with a bug fix state file, review the Affected Dimensions and Dimension-Informed Fix Requirements sections.
4. **Assess workflow blast radius and E2E coverage**: Check the **Workflows** column in the bug entry (or look up the Related Feature in [User Workflow Tracking](../../../doc/state-tracking/permanent/user-workflow-tracking.md)) to identify which user workflows are affected, and note which cases in [e2e-test-tracking.md](../../../test/state-tracking/permanent/e2e-test-tracking.md) cover the affected behaviour — or that none does, which Step 21 acts on.
5. **Multi-session gate**: If the bug scope is "L" (Large) — including L assigned *by chain* at [Bug Triage](bug-triage-task.md) Step 11b, where the fix answers a recurring class rather than this instance — or the bug requires architectural changes (e.g., redesigning a component, changing cross-cutting patterns), create a bug fix state tracking file:
   ```powershell
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/06-maintenance/New-BugFixState.ps1 -BugId "PD-BUG-XXX" -BugTitle "Bug Title" -Severity "High" -AffectedFeature "X.Y.Z — Feature Name" -EstimatedSessions N
   ```
   After creation, **customize the state file to the specific bug**: fill in the Implementation Progress table with the files/components that will need changing, identify which documents need updating in the Documentation Updates table, outline the resolution plan in the Fix Approach section, and — for a chain-assigned L — list the chain's members in the **Chain** field so the fix is scoped to the class. This plan serves as the blueprint for the fix and enables session handover.
   **Notes column rule**: When a state file exists, keep the Notes column in bug-tracking.md minimal — link to the state file and a one-line status summary only. All session progress, root cause details, and fix approaches belong in the state file, not inline.
   For single-session bugs (Small/Medium effort), skip this step — no state file needed.
6. Reproduce the bug to understand its exact behavior and confirm the issue — starting from what the triage notes and the Related Feature's [implementation state file](../../../doc/state-tracking/features) issues log already record, failed reproductions included; a recorded mechanism is Step 10's first hypothesis.
   - For code-structural bugs (e.g., missing error handling, absent code paths), confirming the gap through code review serves as reproduction
7. Document the reproduction steps for future reference
8. Analyze the affected code area to understand the context
9. Update bug status from 🔍 Needs Fix to 🟡 In Progress
   - **Automated Option**: Use [`Update-BugStatus.ps1`](../../scripts/update/Update-BugStatus.ps1) script:
     ```powershell
     ../../scripts/update/Update-BugStatus.ps1 -BugId "BUG-001" -NewStatus "InProgress"
     ```
10. Analyze the code to identify the root cause, pinning the **exact code mechanism** — the specific branch/function that produces the defect — empirically rather than inferred from the symptom: by reproduction, or, when the reported symptom will not reproduce (state the attempt count and what was ruled out), by injecting the precondition the mechanism requires; Step 13's fail-first then runs against that injected precondition and the fix record says so, so a closed row never implies reproduction-verified when it was not.
    - **If multi-session**: Update the Root Cause Analysis section in the bug fix state file
11. Consider alternative approaches to fixing the issue
    - **If multi-session**: Document chosen approach and alternatives in the Fix Approach section
    - **Scope reassessment** (either direction): If root cause analysis reveals the fix differs from the triaged scope, reassess and present the revised scope at the Step 12 checkpoint. **Downward** (e.g., an L-scope bug needs only a small, isolated change): once approved, the multi-session gate (Step 5) no longer applies — archive any state file created prematurely and proceed as a single-session fix. **Upward** (e.g., an S-scope bug proves larger or riskier than triaged): route it as a fix, not the quick path, and exit at 👀 Needs Review for Code Review instead of self-closing.
12. **🚨 CHECKPOINT**: Present reproduction results, workflow blast radius, root cause analysis, the proposed fix approach (with alternatives and trade-offs) and test strategy to the human partner, and route the bug by what the investigation found:
   - **Fix (M/L-scope — the ordinary path)**: after approval, continue with Step 13.
   - **S-scope quick path** — self-review replaces Code Review when **all** hold: (1) Scope = S, (2) priority Medium or Low, (3) no E2E evidence is invalidated by the fix (a behaviour-preserving change invalidates none — the Step 21 question, answered here), (4) the mechanism is pinned by reproduction. If the bug is 🆕 Needs Triage, triage it inline first (`Update-BugStatus.ps1 -NewStatus "NeedsFix" -Priority "..." -Scope "S" -RelatedFeature "..." -Dims "..."`). Then run the full path with one substitution — the Step 26 status update becomes closing in one call after the Step 22 approval:
     ```powershell
     ../../scripts/update/Update-BugStatus.ps1 -BugId "BUG-001" -FastClose -Priority "Medium" -Scope "S" -RelatedFeature "1.1.1" -Dims "CQ" -FixDetails "..." -RootCause "..." -TestsAdded "Yes" -VerificationNotes "S-scope quick path: human-approved at checkpoint"
     ```
     Every finalization step still applies; an upward scope reassessment (Step 11) abandons the quick path.
   - **Reject**: present the evidence; if the human partner agrees, transition to **Rejected** with a `RejectionReason` that opens with its kind — *Not a bug* (expected behaviour, user error, already fixed), *Won't fix* (a real bug whose fix cost is disproportionate to its impact — give the cost/benefit), *Cannot reproduce* (attempt count and what was ruled out, mechanism not pinnable by injection either; a recurrence re-enters through the [Reopen Workflow](bug-triage-task.md#reopen-workflow)), or *Duplicate / other* (name the tracked item that owns it and add a back-reference from that item to the bug):
     ```powershell
     ../../scripts/update/Update-BugStatus.ps1 -BugId "BUG-001" -NewStatus "Rejected" -RejectionReason "<kind> — <evidence or rationale>"
     ```
     Then skip directly to Step 29 (completion checklist); Steps 13–28 do not apply.

### Execution

13. **Write regression test(s) BEFORE implementing the fix** — this confirms the test actually catches the bug. Invoke the `test-authoring` craft skill first — again for each bug in a batch; if unlisted, read its [`SKILL.md`](../../../.claude/skills/test-authoring/SKILL.md) directly (equivalent). It owns the judgment the procedure below delegates to.
    > **Instruction-medium bugs (PF-PRO-064)**: when the defective artifact is an instruction (the owning feature's `**Medium**` is `instruction`, or the instruction part of a `mixed` feature), the regression test is an **L3 instruction fixture reproducing the mis-execution**, not a unit test: seed a fixture where following the instruction as written yields the wrong end state, confirm its `assert.ps1` oracle **FAILS** before the fix and **PASSES** after — the same fail-first discipline on a different harness (pattern: the `e2e-test-case-creation` skill's instruction-fixtures reference; execution wiring: [E2E Acceptance Test Execution](../03-testing/e2e-acceptance-test-execution-task.md)). If the mis-execution is a contract defect (a named script, parameter, or step that does not exist), `Check-InstructionContract.ps1` flagging it before the fix and passing after is the regression pin instead.
    - **Write test(s) that reproduce the exact bug scenario and prove them per the [Test Authoring Guide](../../guides/03-testing/test-authoring-guide.md)**: Phase 1 names each test's discriminating condition and lands any new API surface first; Phase 2 keeps assertions behavioural and negative assertions discriminating; [Phase 3](../../guides/03-testing/test-authoring-guide.md#phase-3-prove) is this step's evidence — every test **FAILS** before the fix, for the defect's own reason, read per test.
    - Keep regression tests focused on the specific fix — do not expand scope here. A pre-existing gap in *automated* coverage is a note for a future test audit; a missing **E2E scenario** is filed at Step 21 into the Discovered Scenario Gaps table, because that tracker has an owning task and a note does not
    - **File placement and tracking sync** (new file vs. existing file, `New-TestFile.ps1`, the scoped `Validate-TestTracking.ps1 -Fix -Path` sync): the guide's [Phase 1](../../guides/03-testing/test-authoring-guide.md#phase-1-before-writing) and [Phase 4](../../guides/03-testing/test-authoring-guide.md#phase-4-close).
    - **If multi-session**: Note test file changes in the Implementation Progress table
    - After creating or modifying tests, complete the documentation steps in the [Test Infrastructure Guide — Test Documentation Completeness](../../guides/03-testing/test-infrastructure-guide.md#test-documentation-completeness) section.
    - **Manual validation script** (`test/bug-validation/` — placement and naming: [Bug Reporting Guide](../../guides/06-maintenance/bug-reporting-guide.md#where-validation-scripts-live)): author one now, beside the regression tests, when the bug names an **operator-facing symptom** (reached through the real entry point — UI, filesystem, daemon startup — that unit tests reach only via an internal call) and a human can drive its trigger by hand. It is the one artifact that runs the real path, whatever the unit tests cover; a symptom with no hand-drivable trigger (race, ordering, internal state) gets none — a manual run seeing nothing proves nothing. Extend the bug's existing script rather than add a second. It is a test under the same guide: the human reproduces by UI or filesystem actions, the script **asserts** the before/after difference against its discriminating condition ([Phase 2 step 8](../../guides/03-testing/test-authoring-guide.md#phase-2-write) — a script that only prints cannot fail), and Phase 3 proves it.
14. Develop a fix that addresses the root cause, not just the symptoms; rename any symbol whose name the fix makes inaccurate
    - **If multi-session**: Track each file change in the Implementation Progress table
15. **Verify the fix**: the Step 13 regression tests and validation script now **PASS**, and the Step 7 reproduction no longer triggers the issue — re-run the original failing input, not only the tests written from it. For a **surface-widening fix** (one that makes the system emit, write, or detect something it previously did not), also enumerate every context that consumes the new output and verify each — a class the regression tests cannot see, since nothing was ever asserted about behaviour that did not exist. *If multi-session*: record the results in the state file's Validation Status section.
16. **Check for similar issues** — sweep the *invariant the fix restores*, not the component type:
    - State in one sentence what the fix now guarantees, then enumerate **every site that can violate it** — each producer and consumer of what it governs — across the Related Feature's full package tree (every subpackage) and along the bug's Dims; same-type siblings are a secondary pass, not the axis. Carry the result into `-FixDetails` as one line — the invariant, each site *covered* or *accepted: <reason>* — so Code Review re-derives the enumeration.
    - If the fix removed or renamed a function, constant, or parameter, grep source, tests **and** `test/bug-validation/` for its old name — bug-validation scripts sit outside the automated suite, so a broken import there stays silent ([residue kinds](../../guides/support/script-development-quick-reference.md#-removing-a-code-path-or-doc-subsection-leaves-residue-stale-help-dead-branches-coupled-tests-orphaned-prose)).
    - File each defect this sweep finds with `New-BugReport.ps1 -OriginBug "<this bug>"` — the sweep is a chain's most common origin, and the link is what lets triage see the third instance as a class
17. **Session boundary** (multi-session only): If ending a session before the fix is complete, update the Session Log in the bug fix state file with completed work and next-session plan. The next session resumes from this state file.
18. **Apply the project's format and lint gate** — its pre-commit hooks, or `testing.lintCommand` in the language config — to the files the fix changed, so a reformat cannot invalidate a recorded suite result.
19. **Run the full regression suite** (`Run-Tests.ps1 -All`) now — after the sweep and format gate, which can both change code — in the background while you do Steps 20–21. A failure outside your change set is attributed and routed here, per [Test Infrastructure Guide — Attributing a Failure You Did Not Cause](../../guides/03-testing/test-infrastructure-guide.md#attributing-a-failure-you-did-not-cause), not carried to the checkpoint.
20. **Review feature documentation against the fix** — read each class below for the fix area and update what no longer matches, confirming each checkable claim you write at its source (file and line), cited in `-FixDetails`; a document that contradicts the impact you are about to present revises the impact statement here, before the checkpoint, never after it:
    - **Feature implementation state file** (`state-tracking/features/`) — update implementation notes, known issues, or status
    - **User handbooks** (`doc/user/handbooks/`) — when operator-visible behaviour or output changes: a console-output table or worked example can document the defect as the rule
    - **TDD** — update technical design descriptions that no longer match the code
    - **Test specification** — update expected behavior or add new test scenarios
    - **FDD** — update functional behavior descriptions if user-facing behavior changed
    - **Integration Narrative** (`doc/technical/integration/`) — update if the fix changes how features interact in a cross-feature workflow documented by a PD-INT narrative
    - **If multi-session**: Update the Documentation Updates table in the bug fix state file
21. **E2E follow-through**:
    - **Re-run the exposing case** (if the bug was discovered via E2E testing) with [`Run-E2EAcceptanceTest.ps1`](../../scripts/test/e2e-acceptance-testing/Run-E2EAcceptanceTest.ps1) and record pass/fail — unless the triage record shows the failure was never reproducible on demand, or the covering case is entangled with another session's in-flight change; then state which applies and what evidence stands in for the re-run
    - **Re-execution decision** (Step 23 executes it) — weigh three inputs, read off `-WhatIf` previews, never the entry count alone: does the fix invalidate E2E evidence at all (a behavior-preserving fix invalidates none); does the selector pick the entries covering the changed code path — `-FeatureId` with the bug's feature by default, `-Workflow` or `-TestCase` when that cascades across untouched workflows or misses the affected one; and how many selected entries are already at `🔄 Needs Re-execution`, which a re-flag leaves unchanged — all of them means no flag.
    - **File scenario gaps, never build the case here** — when no E2E case covers the bug's behaviour (Step 4), even if its workflow has no E2E coverage at all; when only real end-to-end behaviour can verify the fix (e.g., real OS event delivery); or when the fix revealed a scenario the covering workflow never exercises:
      ```bash
      pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/03-testing/New-E2EScenarioGap.ps1 -Workflow "WF-NNN" -Scenario "<what is unexercised, concrete enough to build a fixture from>" -Source "PD-BUG-NNN" -Confirm:\$false
      ```
      [E2E Acceptance Test Case Creation (PF-TSK-069)](../03-testing/e2e-acceptance-test-case-creation-task.md) builds the case from the row and closes it with `-ResolvesGap`. A bug in no tracked workflow: if a workflow is missing, add it with [`New-WorkflowEntry.ps1`](../../scripts/file-creation/03-testing/New-WorkflowEntry.ps1) and file against it; if none is (e.g., an internal helper script), file nothing and say why in the fix record.
    - **L-scope test scoping**: an L-scope architectural fix that changes feature behavior enough to warrant performance or E2E test scoping routes to PF-TSK-086 (`🔎 Needs Test Scoping`) after Code Review, not straight to `🔒 Closed`.
22. **🚨 CHECKPOINT**: Present fix results for human approval before updating bug status:
    - Code changes summary (files modified, approach taken) and the fix's **impact statement**, as confirmed by the Step 20 documentation review
    - Test results (regression tests pass, full suite regression check) and the **fail-first contrast** — which tests were red before the fix and for what reason, the [Test Authoring Guide — Phase 3](../../guides/03-testing/test-authoring-guide.md#phase-3-prove) evidence
    - Validation script results (from Step 13, when one exists)
    - Similar issues found and addressed (from Step 16)
    - **E2E follow-through** (Step 21): the re-run result, the flag / no-flag call with its three inputs, each `GAP-NNN` filed, and whether L-scope test scoping applies
    - **Dimension verification**: confirm the fix addresses every dimension in the bug's Dims column (e.g. DI — atomicity/recovery; SE — input validation). A dimension knowingly left open is **deferred, never dropped**: file its follow-up (feature request, tech-debt item or bug), cite that ID at each deferral site and state the residual cost here — the [Issue Classification guide](../../guides/framework/issue-classification-and-routing-guide.md)'s inverse-move rule
    > **ADR trigger**: If the fix changed architectural behavior, introduced a new pattern, or made a design trade-off not covered by existing ADRs, create an ADR using [New-ArchitectureDecision.ps1](../../scripts/file-creation/02-design/New-ArchitectureDecision.ps1), with the [`architecture-decision` craft skill](../../../.claude/skills/architecture-decision/SKILL.md) as the customization-craft home.

### Finalization

23. **Mark manual test groups for re-execution** per the Step 22 decision, with the selector approved there:
    ```bash
    pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/test/e2e-acceptance-testing/Update-TestExecutionStatus.ps1 -FeatureId "X.Y.Z" -Status "Needs Re-execution" -Reason "Bug fix PD-BUG-XXX" -Confirm:\$false
    ```
24. **File, don't refactor**: maintainability work the fix exposed becomes technical debt — refactoring now would change code approved at Step 22. Cite the ID in `-FixDetails` at Step 26:
    ```powershell
    process-framework/scripts/update/Update-TechDebt.ps1 -Add -Description "<what should be restructured>" -Dims "<DIM_CODE>" -Location "<path>" -Priority "<Critical|High|Medium|Low>"
    ```
25. **Run test tracking validation** (if tests were added or modified):
    ```powershell
    process-framework/scripts/validation/Validate-TestTracking.ps1 -Path "<test files your fix touched>"
    ```
    The `-Path` scope (PF-IMP-1176) makes the verdict reflect your change only — reconcile any reported mismatch (add `-Fix` to sync a drifted count, still scoped). Drift your change set did not cause — e.g. from an in-progress test-tree reorganization — is established and routed per [Test Infrastructure Guide — Attributing a Failure You Did Not Cause](../../guides/03-testing/test-infrastructure-guide.md#attributing-a-failure-you-did-not-cause), not reconciled here.
26. Update bug status from 🟡 In Progress to 👀 Needs Review — last, so the fix record is complete when Code Review picks it up (S-scope quick path: the `-FastClose` call from Step 12 instead)
    - **Automated Option**: Use [`Update-BugStatus.ps1`](../../scripts/update/Update-BugStatus.ps1) script:
      ```powershell
      ../../scripts/update/Update-BugStatus.ps1 -BugId "BUG-001" -NewStatus "NeedsReview" -FixDetails "Fixed null pointer exception" -RootCause "Missing null check" -TestsAdded "Yes" -PullRequestUrl "https://github.com/repo/pull/123"
      ```
27. **If multi-session**: Archive the bug fix state file to `doc/state-tracking/temporary/old` after the bug is closed
28. **Batch opportunity**: Check [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md) for additional bugs with status 🔍 Needs Fix. Ask the human partner if they want to fix another bug in this session before proceeding to the feedback form. If yes, loop back to Step 1 (Preparation) for the next bug. Defer the feedback form until all bugs in the session are complete.
    > **Note**: Bug status transitions to 🔒 Closed happen in Code Review (PF-TSK-005), not in this task — except for S-scope quick path bugs, closed by `-FastClose` at Step 26. This task exits at 👀 Needs Review for M/L-scope bugs.
29. **🚨 MANDATORY FINAL STEP**: Complete the Task Completion Checklist below

## Outputs

- **Modified Source Code** - Source code files that fix the bug
- **Updated Tests** - New or updated test files that verify the fix
- **Bug Fix Documentation** - Documentation of the root cause and solution approach
- **Updated Bug Tracking** - [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md) with bug status and resolution details updated

## State Tracking

The following state files must be updated as part of this task:

- [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md) - Update with:
  - Bug status progression: 🔍 Needs Fix → 🟡 In Progress → 👀 Needs Review (then Code Review closes to 🔒 Closed), or S-scope quick path: 🟡 In Progress → 🔒 Closed via `-FastClose`, or 🟡 In Progress → ❌ Rejected (rejection kind per Step 12)
  - Fix date and resolution details
  - Root cause analysis and solution approach
  - Link to relevant pull request or commit (if applicable)
  - Any lessons learned for future development
  - Testing verification results
  - For bugs affecting specific features: Reference related feature ID from [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md)
- **Conditional — multi-session** (only for Large-effort or architectural bugs):
  - [Bug fix state file](../../../doc/state-tracking/temporary) — created via [`New-BugFixState.ps1`](../../scripts/file-creation/06-maintenance/New-BugFixState.ps1), tracks root cause, fix approach, implementation progress, validation status, and session log. Archive to `doc/state-tracking/temporary/old/` when bug is closed.
  - **Notes column**: When a state file exists, the bug-tracking.md Notes column should contain only a link to the state file and a one-line status summary (e.g., `See [state file](path). Session 2/3 complete.`). Do not duplicate session logs or fix details inline.

**Automation Support**: The [`Update-BugStatus.ps1`](../../scripts/update/Update-BugStatus.ps1) script can automate status updates and ensure consistent formatting. While manual updates are supported, the script provides standardized status transitions and automatic timestamp tracking.

## ⚠️ MANDATORY Task Completion Checklist

> Completion discipline, output verification, and the feedback form are governed by the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md) (Phase C). The items below are the **task-specific** verifications that plug into it.

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
  - [ ] Step 20 documentation review done: each document class (state file, TDD, test specification, FDD, Integration Narrative, user handbooks) updated, or N/A after reading it
  - [ ] If multi-session: bug fix state file archived to `doc/state-tracking/temporary/old`
- [ ] **Feedback form** completed per the [Task Execution Protocol → Feedback step](../../guides/framework/task-execution-protocol-guide.md#feedback-step) — task ID `PF-TSK-007`, context "Bug Fixing".

## File Operations

| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | Bug Fix State File (conditional) | `New-BugFixState.ps1` | Multi-session state tracking for Large-effort or architectural bugs |
| **Updates** | [`bug-tracking.md`](../../../doc/state-tracking/permanent/bug-tracking.md) + sibling [`archive/bug-tracking-archive.md`](../../../doc/state-tracking/permanent/archive/bug-tracking-archive.md) (archive-split 2026-05-26, PF-IMP-872) | [`Update-BugStatus.ps1`](../../scripts/update/Update-BugStatus.ps1) | Update bug status through lifecycle:<br/>• 🔍 Needs Fix → 🟡 In Progress → 👀 Needs Review (M/L-scope) or → 🔒 Closed (S-scope quick path)<br/>• Automated status emoji updates and timestamp tracking<br/>• Automated notes management and metadata tracking<br/>• Automated fix details, root cause, and PR linking<br/>• **Closure automation**: auto-moves bug to archive ## Closed Bugs / ## Rejected Bugs section, recalculates Bug Statistics |
| **Updates** | [`test-tracking.md`](../../../test/state-tracking/permanent/test-tracking.md) | `New-TestFile.ps1` / Manual | Register regression tests added for the fix |
| **Updates** | [`e2e-test-tracking.md`](../../../test/state-tracking/permanent/e2e-test-tracking.md) | `Update-TestExecutionStatus.ps1` (conditional) | Mark affected E2E tests for re-execution |
| **Updates** | [`e2e-test-tracking.md`](../../../test/state-tracking/permanent/e2e-test-tracking.md) | `New-E2EScenarioGap.ps1` (conditional, Step 21) | File a discovered missing scenario into Discovered Scenario Gaps |
| **Updates** | [`user-workflow-tracking.md`](../../../doc/state-tracking/permanent/user-workflow-tracking.md) | `New-WorkflowEntry.ps1` (conditional, Step 21) | Add a missing workflow before filing its gap |
| **Updates** | [`technical-debt-tracking.md`](../../../doc/state-tracking/permanent/technical-debt-tracking.md) | `Update-TechDebt.ps1 -Add` (conditional, Step 24) | File maintainability work the fix exposed |
| **Updates** | Feature Implementation State Files | Manual (conditional) | When fix changes technical design |
| **Updates** | TDD / Test Spec / FDD / Integration Narrative / user handbooks | Manual (conditional) | When fix changes documented behavior |

## Next Tasks

- [**Code Review**](code-review-task.md) - Reviews the bug fix for quality and correctness; transitions bug from 👀 Needs Review → 🔒 Closed on approval (not needed for S-scope quick path)
- [**Performance & E2E Test Scoping**](../03-testing/performance-and-e2e-test-scoping-task.md) - If L-scope fix changes feature behavior significantly (AI agent self-assessment at the E2E follow-through step)
- [**Manual Test Case Creation**](../03-testing/e2e-acceptance-test-case-creation-task.md) - Build the case for a scenario gap this task filed (Discovered Scenario Gaps row), in its own session
- [**Manual Test Execution**](../03-testing/e2e-acceptance-test-execution-task.md) - Validate the fix through manual testing of affected test groups
- [**Bug Triage**](bug-triage-task.md) - If additional bugs are discovered during fixing
- [**Feature Implementation Planning**](../04-implementation/feature-implementation-planning-task.md) - If the bug fix reveals the need for new functionality
- [**Test Specification Creation**](../03-testing/test-specification-creation-task.md) - If systemic test gaps are discovered during bug investigation that warrant a formal test specification

<!-- merged from transition-registry entry: Bug Fixing -->
### Prerequisites for Transition

- [ ] Bug fix implemented according to root cause analysis
- [ ] Unit tests added or updated to prevent regression
- [ ] Bug reproduction steps no longer trigger the issue
- [ ] Bug status updated to 👀 Needs Review
- [ ] Fix implementation documented

### Next Task Selection

```
What scope is the bug?
├─ S-scope quick path → Bug already closed (🔒 Closed by `-FastClose`) → No transition needed
│   └─ Optionally: Release & Deployment (if release-ready)
├─ M/L-scope → Code Review (PF-TSK-005)
│   └─ Code Review will close the bug (👀 Needs Review → 🔒 Closed) on approval
└─ L-scope with architectural changes (AI self-assessment) → Code Review → then PF-TSK-086 (Test Scoping)
```

### Preparation for Next Task

Code Review works from the bug row's fix record — `-FixDetails` with the Step 16 invariant line and the Step 20 claim locators, `-RootCause`, `-TestsAdded` — so make it complete at Step 26 rather than preparing a separate summary.

## Related Resources

- [Test Authoring Guide (PF-GDE-079)](../../guides/03-testing/test-authoring-guide.md) - the test-writing procedure Step 13 cites: discriminating condition, fail-first evidence read per test, the contrast record, file placement and tracking sync
