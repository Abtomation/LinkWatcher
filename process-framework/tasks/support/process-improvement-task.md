---
id: PF-TSK-009
type: Process Framework
category: Task Definition
domain: agnostic
version: 2.2
created: 2024-07-15
updated: 2026-03-03
task_type: Discrete
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

- When executing an improvement identified in [Process Improvement Tracking](../../state-tracking/permanent/process-improvement-tracking.md)
- When existing processes need refinement based on feedback
- When standardization is needed across different activities
- When documentation of processes is incomplete or outdated

> **Note**: Improvement *identification* and *prioritization* is handled by the [Tools Review Task](tools-review-task.md). This task focuses on *executing* prioritized improvements.

## Context Requirements

- [Process Improvement Context Map](/process-framework/visualization/context-maps/support/process-improvement-map.md) - Visual guide to the components relevant to this task

- **Critical (Must Read):**

  - [Process Improvement Tracking](../../state-tracking/permanent/process-improvement-tracking.md) - Select the improvement to execute
  - [Tools Review Summaries](../../feedback/reviews/) - Source analysis for the selected improvement
  - [Visual Notation Guide](/process-framework/guides/support/visual-notation-guide.md) - For interpreting context map diagrams

- **Important (Load If Space):**

  - [Task Definitions](..) - Current task definitions (read the specific file(s) being improved)
  - [Feedback Forms](../../feedback/feedback-forms) - Source feedback forms referenced by the improvement

- **Reference Only (Access When Needed):**
  - [Feature Tracking](../../../doc/product-docs/state-tracking/permanent/feature-tracking.md) - Can be used to identify areas needing improvement

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished! 🚨**
>
> **🚨 CRITICAL: All process improvements MUST be implemented incrementally with explicit human feedback at EACH stage.**
>
> **⚠️ MANDATORY: Never implement a complete solution without first presenting the plan and getting explicit approval.**

### Preparation

> **🚨 SESSION LIMIT**: Maximum **3 improvements per session**. After completing the 3rd improvement, proceed directly to finalization (Step 17) and close the session. Quality and checkpoint discipline degrade beyond 3.

1. **Select improvement** from [Process Improvement Tracking](../../state-tracking/permanent/process-improvement-tracking.md)
   > After completing an improvement (including tracking update), ask the human partner: **"Continue with another improvement or close the session?"** Each improvement follows the full checkpoint workflow (Steps 1–16) independently. The feedback form is deferred until the session ends — one form covers all improvements done in the session.
2. **Validate the IMP is still needed**: Before diving into implementation, critically evaluate whether the IMP description is still accurate and the fix is still needed. Check if the problem was already addressed by another change, if the target file/tool still exists in the described form, or if the context has changed. If the IMP is no longer valid, present findings and recommend rejection at the checkpoint.
3. **Review source feedback**: Read the [Tools Review summary](../../feedback/reviews/) and/or specific feedback forms that identified this improvement
4. **Read current state**: Examine the file(s)/tool(s) to be improved to understand the current implementation
5. **🚨 CHECKPOINT**: Present problem analysis and proposed approach(es) to human partner
   > **Valid outcomes**: Approve an approach and proceed, request alternative approaches, or **reject the improvement** if analysis shows it's unnecessary (mark as Rejected in tracking and skip to finalization)

### Planning

6. **For multi-session improvements**: Create a state tracking file to track progress across sessions:
   ```powershell
   .\New-TempTaskState.ps1 -TaskName "<Improvement Name>" -Variant "ProcessImprovement" -Description "<scope>"
   ```
   > Single-session improvements do not need a state file — skip this step.
7. For complex improvements: propose multiple solution approaches with pros and cons
8. **🚨 CHECKPOINT**: Get explicit human approval on the chosen approach

### Execution

9. Implement changes in small, reviewable increments (never all at once)
   - **For bulk/repetitive changes** (same pattern across many files): after applying all changes, verify completeness with grep-based checks (e.g., confirm all target files contain the new pattern, confirm no target files still contain the old pattern)
   > **⚠️ SCOPE BOUNDARY**: If implementing an improvement requires work that fits another task's scope — such as creating a new task definition (PF-TSK-001), reorganizing directory structures (PF-TSK-014), or extending the framework (PF-TSK-048) — do not perform that work inline. Instead, document the need, update the IMP with a delegation note, and recommend the appropriate task to the human partner.
10. For each significant change:
    a. Present the specific change to be made
    b. **🚨 CHECKPOINT**: Get explicit approval before implementing
    c. Implement the approved change
    d. **🚨 CHECKPOINT**: Confirm the change meets expectations
11. **Update linked documents**: Search for files that reference the changed file(s) and update or remove outdated content (guides, context maps, registry entries, templates)
12. **Log tool change in feedback database**: Record the modification for trend analysis:
    ```bash
    python process-framework/scripts/feedback_db.py log-change --tool <TOOL_DOC_ID> --date <YYYY-MM-DD> --imp <IMP-XXX> --description "<what changed>"
    ```
13. **🚨 CHECKPOINT**: Review changes with human partner

### Finalization

14. **🚨 CHECKPOINT**: Get final approval on the complete solution
15. Update [Process Improvement Tracking](../../state-tracking/permanent/process-improvement-tracking.md) using [Update-ProcessImprovement.ps1](../../scripts/update/Update-ProcessImprovement.ps1):
    ```powershell
    .\Update-ProcessImprovement.ps1 -ImprovementId "IMP-XXX" -NewStatus "Completed" -Impact "HIGH|MEDIUM|LOW" -ValidationNotes "What was done."
    ```
16. Update any other affected state files
17. **Ask**: "Continue with another improvement or close the session?" If continuing and session limit (3 IMPs) not reached, return to Step 1 for the next improvement. If limit reached, proceed to Step 18.
18. **🚨 MANDATORY FINAL STEP** (session end only): Complete the Task Completion Checklist below — one feedback form covering all improvements done in this session

> **Validation**: Improvements are validated through the next usage cycle. Subsequent feedback (via [Tools Review](tools-review-task.md)) will confirm whether the improvement achieved its goal.

## Tools and Scripts

- **[New-ProcessImprovement.ps1](../../scripts/file-creation/support/New-ProcessImprovement.ps1)** - Add new improvement entries with auto-assigned PF-IMP IDs
- **[Update-ProcessImprovement.ps1](../../scripts/update/Update-ProcessImprovement.ps1)** - Automate tracking file updates (status changes, completion moves, summary count, update history)
- **[New-TempTaskState.ps1 -Variant ProcessImprovement](../../scripts/file-creation/support/New-TempTaskState.ps1)** - Create multi-session process improvement state tracking files (uses [process improvement template](../../templates/support/temp-process-improvement-state-template.md))
- **[New-FeedbackForm.ps1](../../scripts/file-creation/support/New-FeedbackForm.ps1)** - Create feedback forms for task completion
- **[Process Improvement Tracking](../../state-tracking/permanent/process-improvement-tracking.md)** - Central tracking file for all improvements
- **[feedback_db.py](../../scripts/feedback_db.py)** - Record tool changes for trend analysis (`log-change` subcommand)

## Outputs

- **Process Documentation** - New or updated process documentation (task definitions, templates, guides, scripts)
- **Updated Tracking** - [Process Improvement Tracking](../../state-tracking/permanent/process-improvement-tracking.md) updated with improvement status and completion details

## State Tracking

The following state files must be updated as part of this task:

- [Process Improvement Tracking](../../state-tracking/permanent/process-improvement-tracking.md) - Update with:
  - Completion date and impact for implemented improvements
  - Move completed items from "Current Improvement Opportunities" to "Completed Improvements"
  - Ensure "Current Improvement Opportunities" contains only open items

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

Before considering this task finished:

- [ ] **Verify Incremental Implementation**: Confirm the process was followed correctly
  - [ ] Each IMP was validated as still needed before starting work (Step 2)
  - [ ] Problem analysis was presented before solutions
  - [ ] Approach was approved before any changes
  - [ ] Changes were implemented incrementally (not all at once)
  - [ ] Human feedback was received at each checkpoint
  - [ ] Session limit of 3 IMPs was respected

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] Process documentation changes are clear and actionable
  - [ ] Changed files are consistent with the rest of the framework
  - [ ] Linked documents (guides, context maps, registries) are updated or removed

- [ ] **Update State Files**:
  - [ ] Process Improvement Tracking: completed improvement moved to "Completed Improvements" with date and impact
  - [ ] "Current Improvement Opportunities" contains only open items
  - [ ] File metadata updated with current date

- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Completion Instructions](../../guides/framework/feedback-form-completion-instructions.md) for each tool used, using task ID "PF-TSK-009" and context "Process Improvement"

## Next Tasks

- [**Feature Implementation Planning**](../04-implementation/feature-implementation-planning-task.md) - To apply new processes to development work
- [**Structure Change Task**](structure-change-task.md) - If process changes require structural modifications

## Related Resources

- [Tools Review Task](tools-review-task.md) - Identifies and prioritizes improvements (upstream of this task)
- [Process Improvement Task Implementation Guide](../../guides/support/process-improvement-task-implementation-guide.md) - Step-by-step guide for executing this task effectively
- [Task Creation and Improvement Guide](../../guides/support/task-creation-guide.md) - Guide for creating and improving tasks
