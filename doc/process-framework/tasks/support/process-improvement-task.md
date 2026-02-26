---
id: PF-TSK-009
type: Process Framework
category: Task Definition
domain: agnostic
version: 2.0
created: 2024-07-15
updated: 2026-02-26
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

- [Process Improvement Context Map](/doc/process-framework/visualization/context-maps/support/process-improvement-map.md) - Visual guide to the components relevant to this task

- **Critical (Must Read):**

  - [Process Improvement Tracking](../../state-tracking/permanent/process-improvement-tracking.md) - Select the improvement to execute
  - [Tools Review Summaries](../../feedback/reviews/) - Source analysis for the selected improvement
  - [Visual Notation Guide](/doc/process-framework/guides/guides/visual-notation-guide.md) - For interpreting context map diagrams

- **Important (Load If Space):**

  - [Task Definitions](..) - Current task definitions (read the specific file(s) being improved)
  - [Feedback Forms](../../feedback/feedback-forms) - Source feedback forms referenced by the improvement

- **Reference Only (Access When Needed):**
  - [Feature Tracking](../../state-tracking/permanent/feature-tracking.md) - Can be used to identify areas needing improvement

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished! 🚨**
>
> **🚨 CRITICAL: All process improvements MUST be implemented incrementally with explicit human feedback at EACH stage.**
>
> **⚠️ MANDATORY: Never implement a complete solution without first presenting the plan and getting explicit approval.**

### Preparation

1. **Select improvement** from [Process Improvement Tracking](../../state-tracking/permanent/process-improvement-tracking.md)
2. **Review source feedback**: Read the [Tools Review summary](../../feedback/reviews/) and/or specific feedback forms that identified this improvement
3. **Read current state**: Examine the file(s)/tool(s) to be improved to understand the current implementation
4. **🚨 CHECKPOINT**: Present problem analysis and proposed approach(es) to human partner

### Planning

5. For complex improvements: propose multiple solution approaches with pros and cons
6. **🚨 CHECKPOINT**: Get explicit human approval on the chosen approach

### Execution

7. Implement changes in small, reviewable increments (never all at once)
8. For each significant change:
   a. Present the specific change to be made
   b. **🚨 CHECKPOINT**: Get explicit approval before implementing
   c. Implement the approved change
   d. **🚨 CHECKPOINT**: Confirm the change meets expectations
9. **Update linked documents**: Search for files that reference the changed file(s) and update or remove outdated content (guides, context maps, registry entries, templates)
10. **🚨 CHECKPOINT**: Review changes with human partner

### Finalization

11. **🚨 CHECKPOINT**: Get final approval on the complete solution
12. Update [Process Improvement Tracking](../../state-tracking/permanent/process-improvement-tracking.md) — move completed improvement(s) from "Current Improvement Opportunities" to "Completed Improvements"
13. Update any other affected state files
14. **🚨 MANDATORY FINAL STEP**: Complete the Task Completion Checklist below

> **Validation**: Improvements are validated through the next usage cycle. Subsequent feedback (via [Tools Review](tools-review-task.md)) will confirm whether the improvement achieved its goal.

## Tools and Scripts

- **[New-FeedbackForm.ps1](../../scripts/file-creation/New-FeedbackForm.ps1)** - Create feedback forms for task completion
- **[Process Improvement Tracking](../../state-tracking/permanent/process-improvement-tracking.md)** - Central tracking file for all improvements

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
  - [ ] Problem analysis was presented before solutions
  - [ ] Approach was approved before any changes
  - [ ] Changes were implemented incrementally (not all at once)
  - [ ] Human feedback was received at each checkpoint

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] Process documentation changes are clear and actionable
  - [ ] Changed files are consistent with the rest of the framework
  - [ ] Linked documents (guides, context maps, registries) are updated or removed

- [ ] **Update State Files**:
  - [ ] Process Improvement Tracking: completed improvement moved to "Completed Improvements" with date and impact
  - [ ] "Current Improvement Opportunities" contains only open items
  - [ ] File metadata updated with current date

- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Completion Instructions](../../guides/guides/feedback-form-completion-instructions.md) for each tool used, using task ID "PF-TSK-009" and context "Process Improvement"

## Next Tasks

- [**Feature Implementation Planning**](../04-implementation/feature-implementation-planning-task.md) - To apply new processes to development work
- [**Structure Change Task**](structure-change-task.md) - If process changes require structural modifications

## Related Resources

- [Tools Review Task](tools-review-task.md) - Identifies and prioritizes improvements (upstream of this task)
- [Process Improvement Task Implementation Guide](../../guides/guides/process-improvement-task-implementation-guide.md) - Step-by-step guide for executing this task effectively
- [Task Creation and Improvement Guide](../task-creation-guide.md) - Guide for creating and improving tasks
