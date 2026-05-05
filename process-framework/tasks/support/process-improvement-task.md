---
id: PF-TSK-009
type: Process Framework
category: Task Definition
domain: agnostic
version: 2.10
created: 2024-07-15
updated: 2026-05-05
---

# Process Improvement

## Purpose & Context

Analyze, optimize, and document development processes to improve efficiency, quality, and consistency across the project, enabling more effective workflows and higher quality outputs through systematic improvements.

## AI Agent Role

**Role**: Process Engineer
**Mindset**: Analytical, efficiency-focused, systematic improvement-oriented
**Focus Areas**: Workflow bottlenecks, automation opportunities, process standardization, quality metrics
**Communication Style**: Present data-driven improvement recommendations, ask about pain points and workflow preferences

## When to Use

- When executing an improvement identified in [Process Improvement Tracking](../../../process-framework-local/state-tracking/permanent/process-improvement-tracking.md)
- When existing processes need refinement based on feedback
- When standardization is needed across different activities
- When documentation of processes is incomplete or outdated
- **When refactoring framework scripts** (`process-framework/scripts/**/*.ps1`, `*.psm1`) — this task is the home for behavior-preserving framework code changes (regex replacement, helper extraction, parser swap, etc.). PF-TSK-022 (Code Refactoring) is for product code only. Use Step 10 medium-risk path with synthetic-harness verification (happy / error / defect-specific cases against real state files); record pre-fix and post-fix counts in IMP completion notes. See [framework-vs-product policy](../../ai-tasks.md#step-1-what-are-you-working-on).

> **Note**: Improvement *identification* and *prioritization* is handled by the [Tools Review Task](tools-review-task.md). This task focuses on *executing* prioritized improvements.

## Context Requirements

[View Context Map for this task](../../visualization/context-maps/support/process-improvement-map.md)

- **Critical (Must Read):**

  - [Process Improvement Tracking](../../../process-framework-local/state-tracking/permanent/process-improvement-tracking.md) - Select the improvement to execute
  - [Tools Review Summaries](../../feedback/reviews) - Source analysis for the selected improvement
  - [Visual Notation Guide](/process-framework/guides/support/visual-notation-guide.md) - For interpreting context map diagrams

- **Important (Load If Space):**

  - [Task Definitions](..) - Current task definitions (read the specific file(s) being improved)
  - [Feedback Forms](../../feedback/feedback-forms) - Source feedback forms referenced by the improvement

- **Reference Only (Access When Needed):**
  - [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) - Can be used to identify areas needing improvement

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished!**
>
> **🚨 CRITICAL: The IMP is raw input, not a specification.** This task owns problem verification, solution exploration, and implementation. Confirm the problem (Step 2) and explore the solution space independently before treating the IMP description as authoritative.
>
> **⚠️ MANDATORY: Never implement a solution without first getting explicit approval on the approach (Step 6 checkpoint).** Per-change checkpoint frequency is risk-classified — see Step 10.

### Preparation

> **🚨 SESSION LIMIT**: Maximum **3 improvements per session**. After completing the 3rd improvement, skip Step 16 (the continue/close prompt) and proceed directly to Step 17 (final feedback form) to close the session. Quality and checkpoint discipline degrade beyond 3.

1. **Select improvement** from [Process Improvement Tracking](../../../process-framework-local/state-tracking/permanent/process-improvement-tracking.md)
   > After completing an improvement (including tracking update), ask the human partner: **"Continue with another improvement or close the session?"** Each improvement follows the per-improvement workflow (Steps 1–15) independently. Step 16 (continue/close prompt) and Step 17 (feedback form) run once at session boundaries — one feedback form covers all improvements done in the session.
   >
   > **⚠️ PARALLEL SESSION CHECK**: Before starting work, verify the IMP's current status. If it is already **In Progress**, another session may be working on it — flag this to the human partner and do not proceed until confirmed safe. If the status is **Needs Prioritization** or **Needs Implementation**, claim the IMP by setting it to **In Progress** before any other work:
   > ```powershell
   > Update-ProcessImprovement.ps1 -ImprovementId "IMP-XXX" -NewStatus "InProgress"
   > ```
2. **Verify the problem**: The IMP description is raw input, not a specification. Confirm the problem exists and is current before evaluating. Methods (use what fits): grep recent sessions for the symptom, read the artifact under discussion, check IMP history for prior similar reports, inspect the feedback DB. If the problem is clearly absent, already resolved, or trivially mis-described, mark the IMP as Rejected with rationale and skip to Step 14 — no human checkpoint needed at this gate. Otherwise, proceed to Step 3.
3. **Evaluate the IMP**: Assess the improvement against structured criteria. First validity, then implementation merit:

   | Criterion | Question | Rating |
   |-----------|----------|--------|
   | **Still Valid?** | Is the problem still present and accurately described? (Already covered by Step 2 — confirm rating here) | Yes / No |
   | **Recurring Value** | Will this benefit multiple future sessions, not just a one-off scenario? | High / Medium / Low |
   | **Framework Fit** | Does this align with framework principles and existing patterns? (If the fix requires creating new artifacts rather than modifying existing tooling, route to PF-TSK-026/PF-TSK-001 instead.) | Good / Marginal / Poor |
   | **Maintainability** | Will the change be easy to maintain, or does it add complexity/fragility? | Improves / Neutral / Degrades |
   | **Complexity-to-Benefit** | Is the implementation effort proportional to the expected benefit? | Favorable / Balanced / Unfavorable |
   | **Minimum Viability** | Could a simpler change (warning-only, doc-only, smaller scope, or *no change at all*) solve the same problem? If yes, prefer the simpler change unless concrete evidence shows it's insufficient. | Yes / No / Not Explored |
   | **Root-Cause Targeting** | Does the proposed fix target the underlying defect, or route around it via a flag/option/opt-out/escape hatch? If the latter, what is the underlying defect, and is fixing it in scope? | Root-cause / Symptom-only / N/A |
   | **Data-Driven Validation** | Is there data anywhere in the project (feedback DB, review summaries, IMP history, code metrics, git history, test results, etc.) that could validate or invalidate this IMP's premise? If yes, has it been analyzed? | Analyzed / No Data Available |

   > **Conciseness rule**: When all criteria are favorable (Yes / High / Good / Improves / Favorable / Yes-or-No / Root-cause-or-N/A / Analyzed-or-N/A), present a one-line summary at Step 6 (e.g., "Evaluation: all favorable; proceeding with Approach X"). Present the full table only when one or more criteria rate poorly or trigger a gate below.
   >
   > If **Still Valid?** is No, recommend rejection. If multiple criteria rate poorly (Low/Poor/Degrades/Unfavorable), recommend rejection with rationale.
   >
   > **Minimum-viability gate**: If **Minimum Viability** is "Yes" or "Not Explored", the Step 6 checkpoint must explicitly compare the proposed approach against the simpler alternative — present both options to the human partner before committing.
   >
   > **Root-cause-vs-symptom gate**: If **Root-Cause Targeting** is "Symptom-only", the Step 6 checkpoint must articulate the underlying defect explicitly and present both the symptom-fix (as the IMP describes) and the root-cause-fix as options for human review. The symptom-fix is sometimes the correct answer (root cause out of scope, or the symptom *is* the actual problem) — but the *distinction* must be surfaced before commitment.
   >
   > **Data-driven validation gate**: When **Data-Driven Validation** is "Analyzed", do not proceed to implementation until the analysis is complete. This may require a dedicated multi-session data collection effort (create a temp state file via Step 7). Data sources are unrestricted — feedback DB ratings, review summaries, IMP history, code metrics, git history, test results, or anything else relevant. If the data contradicts the IMP's premise, reject the IMP regardless of intuitive appeal. See [Framework Evaluation](framework-evaluation.md) (PF-TSK-079) Step 8 for methodology and the IMP-525 precedent.
   >
   > **Task routing**: Before proceeding, check the nature of the solution:
   > - **Content update** to existing file (adding a callout, fixing a template, updating guidance) → continue with PF-TSK-009
   > - **Structural change** (moving files, renaming directories, reorganizing sections) → delegate to [Structure Change Task](structure-change-task.md) (PF-TSK-014)
   > - **New framework capability** (new task, new template + script + guide, new workflow) → delegate to [Framework Extension Task](framework-extension-task.md) (PF-TSK-026)
   >
   > If delegating, mark the IMP as Deferred with a delegation note and recommend the target task to the human partner.
4. **Review source feedback**: Read the [Tools Review summary](../../feedback/reviews) and/or specific feedback forms that identified this improvement
5. **Read current state**: Examine the file(s)/tool(s) to be improved to understand the current implementation
6. **🚨 CHECKPOINT**: Present problem analysis and proposed approach(es) to human partner
   > **Format**: Begin with a **Problem Summary** (1-2 sentences — your restated problem after Step 2 verification, not a copy of the IMP description), then the evaluation table from Step 3 (or a one-line summary per the Step 3 conciseness rule), then proposed approach(es).
   >
   > **Solution exploration directives**: Before proposing, explore the solution space — at minimum consider an MVP variant *and* a more radical alternative, weighting the radical option by its benefit ceiling rather than its effort cost. The space between is fair game. Present 1–3 surviving options. **Do not enumerate ideas you discarded during exploration** — the human only sees the survivors.
   >
   > **Counter-proposal evaluation** (apply when your proposed approach materially differs from the IMP description — e.g., counter-design, target re-routing, doc-only fix instead of code, scope reduction): Before presenting, run your counter-proposal through the same Step 3 criteria the IMP got. Pay particular attention to:
   > - **Recurring Value** — name a concrete scenario where the counter-proposal would fire usefully. If you can't, the counter-proposal is ceremony.
   > - **Minimum Viability** — could leaving it alone work? If agents already self-organized the right discipline organically, codifying it adds friction without catch.
   > - **Root-Cause Targeting** — does the counter-proposal target the underlying defect, or route around it via a flag/option/escape hatch?
   >
   > Present both evaluations at this checkpoint: the IMP evaluation and the counter-proposal evaluation. The IMP gets challenged at Step 3; the counter-proposal deserves the same scrutiny because it's also raw input, not a spec.
   >
   > **Valid outcomes**: Approve an approach and proceed, request alternative approaches, or **reject the improvement** if analysis shows it's unnecessary (mark as Rejected in tracking and skip to finalization)
   >
   > **Reclassification**: If the IMP describes valid work that is not a process improvement, reject it and route to the correct tracker. Use the **domain heuristic**: `process-framework/`, `doc/` = IMP; `src/linkwatcher` = BUG; `test/` = either (infrastructure = IMP, product defect = BUG).
   > - **Product bug** → [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md) via [New-BugReport.ps1](../../scripts/file-creation/06-maintenance/New-BugReport.ps1)
   > - **Feature request** → [Feature Request Tracking](../../../doc/state-tracking/permanent/feature-request-tracking.md) via [New-FeatureRequest.ps1](../../scripts/file-creation/01-planning/New-FeatureRequest.ps1)
   > - **Technical / test infrastructure debt** → [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md) via [Update-TechDebt.ps1 -Add](../../scripts/update/Update-TechDebt.ps1)
   >
   > Include the new item's ID in the IMP rejection note (e.g., "Reclassified as PD-TDI-XXX") so the routing is traceable.

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

10. **Execute changes by risk class**. First, classify the change set:
    - **Low-risk**: typo, wording, link fix, additive callout, single-file edit with no semantic change, formatting/style
    - **Medium-risk**: behavior changes within one task/script/template, non-trivial logic, multi-file but bounded
    - **High-risk**: structural change, cross-task or cross-script impact, change to a high-frequency workflow, anything affecting human-facing UX in repeated tasks

    Then execute according to class:
    - **Low-risk**: implement directly in batch — no per-change checkpoint
    - **Medium-risk**: state the planned change set briefly (one paragraph or bullet list), implement in batch — no per-change checkpoint (the Step 6 approach approval covers it)
    - **High-risk**: per-change loop — for each significant change, (a) present the specific change to be made, (b) **🚨 CHECKPOINT** get explicit approval before implementing, (c) implement the approved change, (d) **🚨 CHECKPOINT** confirm the change meets expectations

    Always state the classification you applied at the Step 13 checkpoint so the human can override it.

    > **For bulk/repetitive changes** (same pattern across many files): after applying all changes, verify completeness with grep-based checks (e.g., confirm all target files contain the new pattern, confirm no target files still contain the old pattern).
    >
    > **⚠️ PRE-IMPLEMENTATION CHECK**: Before creating or modifying any tracked file, verify whether an automation script exists for that operation (check `process-framework/scripts/file-creation/` and `process-framework/scripts/update/`). Always use scripts when available — they update surrounding infrastructure (ID registries, tracking files, counters) that manual edits miss.
    >
    > **⚠️ SCOPE BOUNDARY**: If implementing an improvement requires work that fits another task's scope — such as creating a new task definition (PF-TSK-001), reorganizing directory structures (PF-TSK-014), or extending the framework (PF-TSK-026) — do not perform that work inline. Instead, document the need, update the IMP with a delegation note, and recommend the appropriate task to the human partner.
11. **🔍 Verify linked documents** *(silent housekeeping — do not surface routinely)*: For each file modified in this improvement, grep for its path/filename across the project (task definitions, guides, context maps, templates, registries). For each hit, read the surrounding paragraph — descriptions, parameter examples, and usage guidance may reference the old behavior and need updating even when the link itself is correct. Apply updates where surrounding context is outdated. Mention in the Step 13 checkpoint **only if substantive references were found and updated**; otherwise stay silent.

    **Common stale-description sites** *(non-exhaustive — sweep these first; LinkWatcher rewrites the path token but [does not touch surrounding prose](/doc/user/handbooks/linkwatcher-capabilities-reference.md#what-linkwatcher-does-not-do))*:
    - **Script header blocks** — PowerShell `.SYNOPSIS` / `.DESCRIPTION` / `.PARAMETER` / `.EXAMPLE`; Python module docstrings and `--help`/argparse text
    - **PF-documentation-map.md** — script-index lines often enumerate subcommands, parameters, or capabilities in the trailing description
    - **process-framework-task-registry.md** — per-task automation bullets and the Automation Scripts / Testing Scripts tables describe each script's capabilities
    - **README.md files** — `templates/README.md`, directory READMEs, and root README script tables
    - **Task definitions** referencing the modified artifact — embedded example invocations and parameter lists
12. **Log tool change in feedback database** *(silent housekeeping — do not surface to the human)*: Record the modification for trend analysis:
    ```bash
    # Single change:
    python process-framework/scripts/feedback_db.py log-change --tool <TOOL_DOC_ID> --date <YYYY-MM-DD> --imp <IMP-XXX> --description "<what changed>"

    # Multiple changes (batch via stdin):
    echo '[{"tool": "ID-1", "date": "YYYY-MM-DD", "imp": "IMP-XXX", "description": "..."}, {"tool": "ID-2", "date": "YYYY-MM-DD", "imp": "IMP-XXX", "description": "..."}]' | python process-framework/scripts/feedback_db.py log-change --batch -
    ```

    > **Canonical `<TOOL_DOC_ID>` convention** (verify with `list-tools --filter`):
    > - **Task definitions** (file declares `id: PF-TSK-NNN` in frontmatter) → use the task ID: `PF-TSK-NNN` (e.g., `PF-TSK-009`)
    > - **Everything else** (anything without that frontmatter — templates, guides, scripts, context maps, handbooks, and companion task files like `code-refactoring-lightweight-path.md`) → use the filename: `New-FeedbackForm.ps1`, `framework-evaluation-map.md`, `feature-validation-guide.md`
    >
    > **⚠️ Unknown tool_doc_id?** The script blocks unknown IDs to prevent silent typos. Before logging, verify the canonical ID:
    > ```bash
    > python process-framework/scripts/feedback_db.py list-tools --filter <substring>
    > ```
    > If the tool is genuinely new (first-time registration), add `--new-tool` to acknowledge.

### Finalization

13. **🚨 CHECKPOINT — Decision review**: Present the diff (what you changed and why) and the risk classification you applied. Mention substantive Step 11 findings only if any were needed. Do not mention Step 12. Get approve / revise / reject decision. This is the only mandatory finalization-side checkpoint — Step 10's per-change sub-checkpoints apply only to high-risk changes.
    >
    > **Compressed format option**: When Step 11 found no substantive references AND the change matches the Step 6 plan with no deviation, you may present a one-line variant — *"Risk class: \<class\>. Step 11 sweep clean. No deviation from Step 6 plan. Approve / revise / reject?"* — instead of restating the diff that was already approved at Step 6. Use the full format whenever the change deviates from the Step 6 plan or Step 11 surfaced substantive findings. Mirrors Step 8's "Otherwise skip" relief valve for trivial cases.
    >
    > **Skip option**: For **low-risk** changes (per Step 10 classification) that match the Step 6 plan with no deviation AND where Step 11 found no substantive references, you may skip this checkpoint entirely and proceed directly to Step 14. The Step 6 approval covered the change; a second checkpoint adds no new signal when nothing has surfaced. Keep the checkpoint for medium- and high-risk changes regardless.
14. Update [Process Improvement Tracking](../../../process-framework-local/state-tracking/permanent/process-improvement-tracking.md) using [Update-ProcessImprovement.ps1](../../scripts/update/Update-ProcessImprovement.ps1):
    ```powershell
    Update-ProcessImprovement.ps1 -ImprovementId "IMP-XXX" -NewStatus "Completed" -Impact "HIGH|MEDIUM|LOW" -ValidationNotes "What was done."
    ```

    > **Bash gotcha**: If invoking from bash and `-ValidationNotes` contains backtick code spans (e.g., `` `[string]$Param` ``), use **single quotes** around the value — bash command substitution silently truncates backtick segments inside double-quoted strings before pwsh sees them.
15. Update any other affected state files
    > If a temp state file was created in Step 7, mark its checkboxes complete and move it to `process-framework-local/state-tracking/temporary/old/`.
16. **Ask**: "Continue with another improvement or close the session?" If continuing and session limit (3 IMPs) not reached, return to Step 1 for the next improvement. If limit reached, proceed to Step 17.
17. **🚨 MANDATORY FINAL STEP** (session end only): Complete the Task Completion Checklist below — one feedback form covering all improvements done in this session

> **Validation**: Improvements are validated through the next usage cycle. Subsequent feedback (via [Tools Review](tools-review-task.md)) will confirm whether the improvement achieved its goal.

## Tools and Scripts

- **[New-ProcessImprovement.ps1](../../scripts/file-creation/support/New-ProcessImprovement.ps1)** - Add new improvement entries with auto-assigned PF-IMP IDs
- **[Update-ProcessImprovement.ps1](../../scripts/update/Update-ProcessImprovement.ps1)** - Automate tracking file updates (status changes, completion moves, summary count, update history)
- **[New-TempTaskState.ps1 -Variant ProcessImprovement](../../scripts/file-creation/support/New-TempTaskState.ps1)** - Create multi-session process improvement state tracking files (uses [process improvement template](../../templates/support/temp-process-improvement-state-template.md))
- **[New-FeedbackForm.ps1](../../scripts/file-creation/support/New-FeedbackForm.ps1)** - Create feedback forms for task completion
- **[Process Improvement Tracking](../../../process-framework-local/state-tracking/permanent/process-improvement-tracking.md)** - Central tracking file for all improvements
- **[feedback_db.py](../../scripts/feedback_db.py)** - Record tool changes for trend analysis (`log-change` subcommand, supports `--batch` for multiple changes)

## Outputs

- **Process Documentation** - New or updated process documentation (task definitions, templates, guides, scripts)
- **Updated Tracking** - [Process Improvement Tracking](../../../process-framework-local/state-tracking/permanent/process-improvement-tracking.md) updated with improvement status and completion details

## State Tracking

The following state files must be updated as part of this task:

- [Process Improvement Tracking](../../../process-framework-local/state-tracking/permanent/process-improvement-tracking.md) - Update with:
  - Completion date and impact for implemented improvements
  - Move completed items from "Current Improvement Opportunities" to "Completed Improvements"
  - Ensure "Current Improvement Opportunities" contains only open items

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

- [ ] **Update State Files**:
  - [ ] Process Improvement Tracking: completed improvement moved to "Completed Improvements" with date and impact
  - [ ] "Current Improvement Opportunities" contains only open items
  - [ ] File metadata updated with current date

- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Guide](../../guides/framework/feedback-form-guide.md) for each tool used, using task ID "PF-TSK-009" and context "Process Improvement"

## Next Tasks

- [**Feature Implementation Planning**](../04-implementation/feature-implementation-planning-task.md) - To apply new processes to development work
- [**Structure Change Task**](structure-change-task.md) - If process changes require structural modifications

## Related Resources

- [Tools Review Task](tools-review-task.md) - Identifies and prioritizes improvements (upstream of this task)
- [Process Improvement Task Implementation Guide](../../guides/support/process-improvement-task-implementation-guide.md) - Step-by-step guide for executing this task effectively
- [Task Creation and Improvement Guide](../../guides/support/task-creation-guide.md) - Guide for creating and improving tasks
