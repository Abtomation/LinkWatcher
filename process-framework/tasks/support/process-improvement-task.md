---
id: PF-TSK-009
type: Process Framework
category: Task Definition
domain: agnostic
version: 3.0
created: 2024-07-15
updated: 2026-05-20
description: "Improve development processes"
---

# Process Improvement

## Purpose & Context

Analyze, optimize, and document development processes to improve efficiency, quality, and consistency across the project, enabling more effective workflows and higher quality outputs through systematic improvements.

## Document set

Three files cover this task:

- **This file** — the operative process: 17 steps to execute end-to-end
- **[Reference companion](../../guides/support/process-improvement-task-reference-guide.md)** — tables and conventions you look up at specific steps: evaluation criteria, routing destinations, risk classes, common stale-description sites, TOOL_DOC_ID convention
- **[Implementation guide](../../guides/support/process-improvement-task-implementation-guide.md)** — worked examples, troubleshooting, and the reasoning behind the gates in this process

Read this file end-to-end at session start. Cross to the reference at the step that points to it. Read the implementation guide when you want a pattern to imitate or to understand why a gate exists.

## AI Agent Role

**Role**: Process Engineer
**Mindset**: Analytical, efficiency-focused, systematic improvement-oriented
**Focus Areas**: Workflow bottlenecks, automation opportunities, process standardization, quality metrics
**Communication Style**: Present data-driven improvement recommendations, ask about pain points and workflow preferences

> **Note**: Phase 7 workflow (2026-05-11): IMP *intake* is handled by [Tools Review (PF-TSK-010)](tools-review-task.md) (writes to Section 1 — Intake); IMP *classification and section routing* is handled by [IMP Triage (PF-TSK-089)](imp-triage-task.md) (moves rows from Intake to Improvements / Extensions / Structural Changes / Active Pilots / Rejected). This task picks up rows that Triage placed in **Section 2 — Improvements** and *executes* them. If scope mismatch surfaces during evaluation (Step 3), re-route via the [Routing reference](../../guides/support/process-improvement-task-reference-guide.md#routing) rather than handling out-of-scope work inline.

## Context Requirements

[View Context Map for this task](../../visualization/context-maps/support/process-improvement-map.md)

- **Critical (Must Read):**

  - [Process Improvement Tracking](../../../process-framework-central/state-tracking/permanent/process-improvement-tracking.md) - Select the improvement to execute
  - [Tools Review Summaries](../../../process-framework-central/feedback/reviews/) - Source analysis for the selected improvement
  - [Process Improvement Task Reference](../../guides/support/process-improvement-task-reference-guide.md) - Lookup tables consulted at Steps 3, 10, 11, 12, 14
  - [Process Improvement Task Implementation Guide](../../guides/support/process-improvement-task-implementation-guide.md) - Examples, troubleshooting, gate rationales

- **Important (Load If Space):**

  - [Task Definitions](..) - Current task definitions (read the specific file(s) being improved)
  - [Feedback Forms](../../../process-framework-central/feedback/feedback-forms/) - Source feedback forms referenced by the improvement

- **Reference Only (Access When Needed):**
  - [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) - Can be used to identify areas needing improvement
  - [Visual Notation Guide](../../guides/support/visual-notation-guide.md) - For interpreting context map diagrams

## Process

> **🚨 Never implement a solution without explicit Step 6 approval.** Per-change checkpoint frequency is risk-classified — see Step 10.

### Preparation

> **Session limit**: Maximum **3 improvements per session**. After the 3rd, skip Step 16 (continue/close prompt) and go directly to Step 17 (final feedback form). Quality and checkpoint discipline degrade beyond 3.

1. **Select improvement** from [Process Improvement Tracking](../../../process-framework-central/state-tracking/permanent/process-improvement-tracking.md) and run the **claim protocol**:
   - **Parallel-session check**: If status is **In Progress**, another session may hold it — flag to the human partner and pause until confirmed safe. If **Needs Prioritization** or **Needs Implementation**, proceed to claim.
   - **Resp Task pre-routing**: Read the IMP's **Resp Task** column. If blank or `PF-TSK-009`, claim and continue (Step 3 still runs the routing assessment — triager may have misjudged scope). If another task ID (`PF-TSK-014`, `PF-TSK-026`, `PF-TSK-001`, ...), do not claim — surface to the human partner: *"PF-IMP-XXX is pre-routed to <task-id>; switch tasks or override?"* Resp Task is a hint at intake, not authoritative routing.
   - **Claim**: `Update-ProcessImprovement.ps1 -ImprovementId "IMP-XXX" -NewStatus "InProgress"`
2. **Verify the problem**: The IMP description is raw input, not a specification. Confirm the problem exists and is current before evaluating. Methods (use what fits): grep recent sessions for the symptom, read the artifact under discussion, check IMP history for prior similar reports, inspect the feedback DB. If the problem is clearly absent, already resolved, mark the IMP as Rejected with rationale and skip to Step 14 — no human checkpoint needed at this gate. Otherwise, proceed to Step 3.
3. **Evaluate the IMP** against the 7-criterion matrix in [Evaluation criteria](../../guides/support/process-improvement-task-reference-guide.md#evaluation-criteria) of the reference. Apply the **conciseness rule** (one-line summary at Step 6 if all criteria favorable; full table only when one or more rate poorly or trigger a gate). If multiple criteria rate poorly, recommend rejection with rationale. The **minimum-viability**, **root-cause-vs-symptom**, and **data-driven validation** gates fire at Step 6 — see the reference. If the IMP needs re-routing, consult the [Routing reference](../../guides/support/process-improvement-task-reference-guide.md#routing); the IMP leaves this task's responsibility after re-routing.
4. **Review source feedback**: Read the [Tools Review summary](../../../process-framework-central/feedback/reviews/) and/or specific feedback forms that identified this improvement
5. **Read current state**: Examine the file(s)/tool(s) to be improved to understand the current implementation
6. **🚨 CHECKPOINT**: Present problem analysis and proposed approach(es) to human partner.

   **Format**: Begin with a **Problem Summary** (1-2 sentences — your restated problem after Step 2 verification, not a copy of the IMP description), then the evaluation table from Step 3 (or a one-line summary per the conciseness rule), then proposed approach(es).

   **Solution exploration**: Before proposing, explore the solution space — at minimum consider an MVP variant *and* a more radical alternative. Present 1–3 surviving options. Do not enumerate discarded ideas.

   **Counter-proposal evaluation**: When your proposed approach materially differs from the IMP description, run it through the same 7-criterion evaluation the IMP got and present both. The counter-proposal is also raw input, not a spec.

   *Rationale for solution exploration and counter-proposal evaluation: see the [implementation guide explanation](../../guides/support/process-improvement-task-implementation-guide.md#explanation).*

   **Valid outcomes**: Approve an approach and proceed, request alternative approaches, or **reject the improvement** if analysis shows it's unnecessary (mark as Rejected in tracking and skip to finalization).

   **Reclassification**: If the IMP describes valid work that is not a process improvement (product bug, feature request, tech debt), reject it and route per the [Routing reference](../../guides/support/process-improvement-task-reference-guide.md#routing).

### Planning

7. **For multi-session improvements**: Create a state tracking file to track progress across sessions:
   ```powershell
   New-TempTaskState.ps1 -TaskName "<Improvement Name>" -Variant "ProcessImprovement" -Description "<scope>"
   ```
   > Single-session improvements do not need a state file — skip this step.
8. For complex improvements with multiple distinct approaches worth deliberating, present them at Step 6 with pros/cons. Otherwise skip.
9. **🚨 CHECKPOINT** *(conditional)*: If Step 8 produced multiple alternatives, get explicit human approval on the chosen approach.
   > **Skip if Step 8 was not used and Step 6 already approved a single concrete approach.** Step 6's "approve an approach and proceed" outcome covers both checkpoints when there are no alternatives to deliberate.

### Execution

10. **Execute changes by risk class.** Classify the change set per [Risk classification](../../guides/support/process-improvement-task-reference-guide.md#risk-classification), then execute per-class:
    - **Low-risk**: implement directly in batch — no per-change checkpoint
    - **Medium-risk**: state the planned change set briefly, implement in batch; for framework-script edits, add/update the script's Pester unit test and run `Run-Tests.ps1 -Category <area>` (or `-Quick`)
    - **High-risk**: per-change loop — state → checkpoint → implement → checkpoint

    State the applied classification at the Step 13 checkpoint so the human can override it.

    > **Script soak workflow** *(framework-script edits only)*: Hash-changed scripts must pass a soak counter (default 3 successful invocations) tracked in [script-soak-tracking.md](../../../process-framework-central/state-tracking/permanent/script-soak-tracking.md). Helper-routed armoring (Pattern B in [ExecutionVerification.psm1](../../scripts/Common-ScriptHelpers/ExecutionVerification.psm1)) registers and counts automatically. Scripts not routed through the helper need a manual `Register-SoakScript` call. Use `Get-SoakStatus` to check current state.

    > **For bulk/repetitive changes**: after applying all changes, verify completeness with grep-based checks (confirm all target files contain the new pattern; confirm no target files still contain the old pattern).

    > **⚠️ PRE-IMPLEMENTATION CHECK**: Before creating or modifying any tracked file, verify whether an automation script exists for that operation (check `process-framework/scripts/file-creation/` and `process-framework/scripts/update/`). Always use scripts when available — they update surrounding infrastructure that manual edits miss.

    > **Scope boundary**: If executing the planned change would require another task's work (new task definition, dir reorg, framework extension), implement only the in-scope parts and file a scope-spillover IMP per the [Routing reference](../../guides/support/process-improvement-task-reference-guide.md#routing).

    > **Inline-authorized handling of mid-session IMPs**: If a new IMP is filed mid-session (scope-spillover, or a defect surfaced during the current work) and the human partner authorizes handling it inline, invoke `Update-ProcessImprovement.ps1 -MoveToSection Improvements -Priority <High|Medium|Low> -Reason "<one-line>"` to record the triage decision, then continue in the current session. A separate [IMP Triage (PF-TSK-089)](imp-triage-task.md) session is not required for a single inline-authorized IMP.
11. **🔍 Verify linked documents** *(silent housekeeping — do not surface routinely)*: For each file modified, grep for its path/filename across the project. Read the surrounding paragraph at each hit — descriptions and usage guidance may reference the old behavior. Update outdated context. Sweep the [common stale-description sites](../../guides/support/process-improvement-task-reference-guide.md#common-stale-description-sites) first. Mention in the Step 13 checkpoint **only if substantive references were found and updated**; otherwise stay silent.
12. **Log tool change in feedback database** *(silent housekeeping — do not surface to the human)*. Single change via `feedback_db.py log-change`; multiple via `--batch -`. See [TOOL_DOC_ID convention](../../guides/support/process-improvement-task-reference-guide.md#tool_doc_id-convention) for the canonical ID form.
    ```bash
    # Single change:
    python process-framework/scripts/feedback_db.py log-change --tool <TOOL_DOC_ID> --date <YYYY-MM-DD> --imp <IMP-XXX> --description "<what changed>"

    # Multiple changes (batch via stdin):
    echo '[{"tool": "ID-1", "date": "YYYY-MM-DD", "imp": "IMP-XXX", "description": "..."}, ...]' | python process-framework/scripts/feedback_db.py log-change --batch -
    ```

    > **Fold-in alternative (PF-IMP-832 (b))**: When the next step is `-NewStatus Completed`, pass the same JSON to [Update-ProcessImprovement.ps1](../../scripts/update/Update-ProcessImprovement.ps1) via `-LogToolChanges <json>` to fold Step 12 into the Step 14 invocation. Log-change failure emits a WARN; the IMP move is preserved.

### Finalization

13. **🚨 CHECKPOINT — Decision review**: Present the diff + risk classification + any substantive Step 11 findings. Get approve / revise / reject. Do not mention Step 12. Format scales with risk and deviation:
    - **Skip Step 13 entirely** — low-risk AND matches Step 6 plan AND Step 11 clean. The Step 6 approval already covered everything; go directly to Step 14.
    - **One-line confirmation** — medium- or high-risk, matches Step 6 plan, Step 11 clean. Present *"Risk class: \<class\>. Step 11 sweep clean. No deviation from Step 6 plan. Approve / revise / reject?"*
    - **Full diff** — change deviated from Step 6 plan OR Step 11 surfaced substantive findings. Re-approval signal needed.
14. Update [Process Improvement Tracking](../../../process-framework-central/state-tracking/permanent/process-improvement-tracking.md) using [Update-ProcessImprovement.ps1](../../scripts/update/Update-ProcessImprovement.ps1):
    ```powershell
    Update-ProcessImprovement.ps1 -ImprovementId "IMP-XXX" -NewStatus "Completed" -Impact "HIGH|MEDIUM|LOW" -ValidationNotes "What was done."
    ```

    > **Bash gotcha for `-ValidationNotes` with backticks**: see the [reference](../../guides/support/process-improvement-task-reference-guide.md#bash--validationnotes-backtick-gotcha).
15. Update any other affected state files
    > If a temp state file was created in Step 7, mark its checkboxes complete and move it to the `state-tracking/temporary/old/` directory at the location that `Get-StateTrackingContext` resolved for you (post-Phase-5/7: appdev → `process-framework-central/state-tracking/temporary/old/`; projects → `doc/state-tracking/temporary/old/`).
    > **Pending-migration entries (cwd=appdev only)**: If the change touched a `blueprint/` file *outside* `blueprint/process-framework/` — e.g. `blueprint/CLAUDE.md`, `blueprint/doc/`, or `blueprint/test/` — file a pending-migration entry under `process-framework-central/per-project-migrations/<PRJ-NNN>/pending-migrations.md` for every registered product project. `Push-FrameworkUpdate.ps1` mirrors only `blueprint/process-framework/`; the rest of `blueprint/` seeds project working trees at `Register-Project` bootstrap, so post-bootstrap changes don't reach existing projects without a migration. Use the [Pending Migration Entry Template](../../templates/support/pending-migration-entry-template.md).
16. **Ask**: "Continue with another improvement or close the session?" If continuing and session limit (3 IMPs) not reached, return to Step 1 for the next improvement. If limit reached, proceed to Step 17.
17. **🚨 MANDATORY FINAL STEP** (session end only): Complete the Task Completion Checklist below — one feedback form covering all improvements done in this session

> **Validation**: Improvements are validated through the next usage cycle. Subsequent feedback (via [Tools Review](tools-review-task.md)) will confirm whether the improvement achieved its goal.

## Tools and Scripts

- **[New-ProcessImprovement.ps1](../../scripts/file-creation/support/New-ProcessImprovement.ps1)** - Add new improvement entries with auto-assigned PF-IMP IDs
- **[Update-ProcessImprovement.ps1](../../scripts/update/Update-ProcessImprovement.ps1)** - Automate tracking file updates (status changes, completion moves, summary count, update history)
- **[New-TempTaskState.ps1 -Variant ProcessImprovement](../../scripts/file-creation/support/New-TempTaskState.ps1)** - Create multi-session process improvement state tracking files (uses [process improvement template](../../templates/support/temp-process-improvement-state-template.md))
- **[New-FeedbackForm.ps1](../../scripts/file-creation/support/New-FeedbackForm.ps1)** - Create feedback forms for task completion
- **[Process Improvement Tracking](../../../process-framework-central/state-tracking/permanent/process-improvement-tracking.md)** - Central tracking file for all improvements
- **[feedback_db.py](../../scripts/feedback_db.py)** - Record tool changes for trend analysis (`log-change` subcommand, supports `--batch` for multiple changes)

## Outputs

- **Process Documentation** - New or updated process documentation (task definitions, templates, guides, scripts)
- **Updated Tracking** - [Process Improvement Tracking](../../../process-framework-central/state-tracking/permanent/process-improvement-tracking.md) updated with improvement status and completion details

## State Tracking

The following state files must be updated as part of this task:

- [Process Improvement Tracking](../../../process-framework-central/state-tracking/permanent/process-improvement-tracking.md) - Update with:
  - Completion date and impact for implemented improvements
  - Move completed items from "Section 2 — Improvements" to "Section 6 — Completed"
  - Ensure "Section 2 — Improvements" contains only open items

## ⚠️ MANDATORY Task Completion Checklist

**TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF**

Before considering this task finished:

- [ ] **Verify Process Discipline**: Confirm the process was followed correctly
  - [ ] Each IMP was either rejected at the problem-verification gate (Step 2) or evaluated against structured criteria (Step 3)
  - [ ] Problem analysis was presented at Step 6 before any solution work
  - [ ] Approach was approved at Step 6 (and Step 9 if multiple alternatives) before execution
  - [ ] Changes were executed by risk class (Step 10); high-risk changes used per-change sub-checkpoints
  - [ ] Human feedback was received at all required checkpoints (Step 6, Step 13, plus Step 10 sub-checkpoints for high-risk)
  - [ ] Session limit of 3 IMPs was respected

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] Process documentation changes are clear and actionable
  - [ ] Changed files are consistent with the rest of the framework
  - [ ] Linked documents (guides, context maps, registries) are updated or removed
  - [ ] **Framework script tests**: for each `.ps1`/`.psm1` edited or created in this session, the corresponding Pester unit test (`<ScriptName>.Tests.ps1`) exists, was added/updated alongside the edit, and runs green. N/A if the session touched no PowerShell scripts.

- [ ] **Update State Files**:
  - [ ] Process Improvement Tracking: completed improvement moved to "Section 6 — Completed" with date and impact
  - [ ] "Section 2 — Improvements" contains only open items
  - [ ] File metadata updated with current date
  - [ ] **Pending-migration entries filed (cwd=appdev only)**: If this change touched a `blueprint/` file outside `blueprint/process-framework/` (e.g. `blueprint/CLAUDE.md`, `blueprint/doc/`, `blueprint/test/`), a pending-migration entry has been filed under `process-framework-central/per-project-migrations/<PRJ-NNN>/pending-migrations.md` for every registered product project, using the [Pending Migration Entry Template](../../templates/support/pending-migration-entry-template.md). `Push-FrameworkUpdate.ps1` mirrors only `blueprint/process-framework/`; everything else in `blueprint/` reaches existing projects only via a migration entry. N/A if the change touched only `blueprint/process-framework/` (which Push mirrors automatically).

- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Guide](../../guides/framework/feedback-form-guide.md) for each tool used, using task ID "PF-TSK-009" and context "Process Improvement"

## Next Tasks

## Related Resources

- [Process Improvement Task Reference](../../guides/support/process-improvement-task-reference-guide.md) - Lookup tables and conventions
- [Process Improvement Task Implementation Guide](../../guides/support/process-improvement-task-implementation-guide.md) - Examples, troubleshooting, gate rationales
- [Tools Review Task](tools-review-task.md) - Identifies and prioritizes improvements (upstream of this task)
- [Task Creation and Improvement Guide](../../guides/support/task-creation-guide.md) - Guide for creating and improving tasks
