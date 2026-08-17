---
id: PF-GDE-012
type: Process Framework
category: Guide
version: 1.3
created: 2025-06-05
updated: 2026-07-21
description: "Comprehensive guide for completing feedback forms effectively (referenced by all tasks)"
---

# Feedback Form Guide

This guide provides comprehensive instructions for completing feedback forms effectively.

## Quick Start

1. **Use the automation script** (recommended):
   ```bash
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/support/New-FeedbackForm.ps1 -DocumentId "PF-TSK-XXX" -TaskContext "Task Name" -FeedbackType "MultipleTools" -Confirm:\$false
   ```

   The script auto-prunes Tool sections to match `-FeedbackType`: `SingleTool` → 1 section, `MultipleTools` → 2 sections, `TaskLevel` → no Tool sections (heading removed). If you need additional Tool sections, copy the Tool 2 block in the generated file and renumber.

2. **Manual creation**: Copy the template and follow the naming convention: `YYYYMMDD-HHMMSS-document-id-feedback.md`

3. **File placement**: Save in `appdev/process-framework-central/feedback/feedback-forms/`

## Rating Scale Guidelines

All ratings use a 1-5 scale. Here's how to interpret each level:

### Effectiveness (How well did it work?)
- **5**: Excellent - Essential for task completion, highly effective
- **4**: Good - Effective with minor limitations
- **3**: Adequate - Moderately effective but had some issues
- **2**: Poor - Significant limitations that hindered progress
- **1**: Ineffective - Did not support task completion or caused problems

### Clarity (How easy was it to understand?)
- **5**: Excellent - Very clear and easy to understand
- **4**: Good - Mostly clear with minor ambiguities
- **3**: Adequate - Understandable but required interpretation
- **2**: Poor - Significant unclear or confusing sections
- **1**: Confusing - Difficult to understand or misleading

### Completeness (Did it provide everything needed?)
- **5**: Excellent - All necessary information with no gaps
- **4**: Good - Mostly complete with minor missing elements
- **3**: Adequate - Covered most needs but had some gaps
- **2**: Poor - Significant missing information or guidance
- **1**: Incomplete - Lacked essential information for task completion

### Efficiency (Did it help work faster?)
- **5**: Excellent - Significantly improved task efficiency and speed
- **4**: Good - Helped complete task efficiently with minor delays
- **3**: Adequate - Supported completion without major efficiency gains
- **2**: Poor - Caused some inefficiencies or unnecessary steps
- **1**: Inefficient - Significantly slowed down or complicated completion

### Conciseness (Right amount of information?)
- **5**: Perfect balance - Contains only essential information
- **4**: Mostly concise with minimal unnecessary content
- **3**: Adequate but some non-essential information present
- **2**: Contains significant unnecessary/redundant content
- **1**: Heavily overdocumented with excessive irrelevant information

## Section-by-Section Guide

### Basic Information
- **Task Evaluated**: Use the exact task name and document ID
- **Task Context**: Brief description of what was accomplished (1-2 sentences)
- **Feedback Type**: Choose Single Tool, Multiple Tools, or Task-Level

### Task-Level Evaluation
Complete this when evaluating the overall process or multiple tools together.

**Process Effectiveness**: Focus on the complete workflow, not individual tools.
**Process Conciseness**: Evaluate if the process has the right balance of structure vs. overhead.

### Tool Evaluation
Complete one section per tool used.

**Tool heading — `tool_doc_id`**: The `(...)` after the tool name in each `### Tool N:` heading is the `tool_doc_id` the analytics DB uses to link your ratings to that tool's change history. Use the **task ID** (`PF-TSK-NNN`) for a task definition, or the **filename** (`New-Task.ps1`, `feature-validation-guide.md`) for a script, guide, template, or context map — never the artifact's own `PF-GDE/PF-SCR/PF-TEM/PD-*` ID, and never blank. Matches the [TOOL_DOC_ID convention](../support/process-improvement-task-reference-guide.md#tool_doc_id-convention).

**Purpose**: Briefly explain how the tool was used in this specific task.

**Rating Guidelines**:
- Be honest and specific
- Consider the tool's performance in this specific context
- Compare against what you needed, not perfection
- Use the full 1-5 range when appropriate

**Comments Guidelines**:
- Provide specific examples when possible
- Explain your rating reasoning
- Mention both positives and negatives
- Focus on actionable observations
- **If a comment contains an actionable suggestion, repeat it in "Specific suggestions"** — comments are not machine-extracted, so a suggestion that lives only in a comment never reaches the review pipeline

### Improvement Suggestions

#### What Worked Well
- List specific positive aspects
- Mention features that saved time or effort
- Note anything that exceeded expectations

#### What Could Be Improved
- Identify specific pain points
- Note missing features or information
- Mention confusing or inefficient aspects

#### Specific Suggestions
This is the **single canonical suggestion list** in the form — Tools Review drains improvement candidates from here.
- Provide actionable recommendations
- Be specific about what should change
- Consider implementation feasibility
- Repeat here any actionable suggestion that appears in a rating Comments field
- Document only — do not register PF-IMP entries or run `New-ProcessImprovement.ps1` for suggestions. The one exception: an issue meeting the [Issue Classification and Routing Guide](issue-classification-and-routing-guide.md)'s file-now conditions is filed directly during the session and listed here as `[ALREADY FILED — PF-IMP-NNNN, do not re-file]` so Tools Review does not file it twice

### Additional Context
Use this section for:
- Unique challenges in this task
- Environmental factors that affected tool performance
- Integration issues with other tools
- Context that might affect the feedback interpretation

### Follow-up Actions
This section helps prioritize improvements:
- **Documentation Streamlining**: Areas where documentation could be more concise

### Human Intervention Log
Use this section to capture each instance where the human partner **countered or redirected the AI agent's current course** during the task — corrections, reversals, rejected proposals, missing information the agent should have had. Checkpoint approvals and option selections ("proceed", "approve", "Option B") are the workflow operating as designed and are **not** interventions — do not log them. The goal is **documentation gap detection**, not blame — each genuine intervention is a signal that a task definition, guide, or template may be missing information.

**When to fill**: After completing the task work, as part of session finalization. Review the session and identify moments where the human partner countered or redirected the work.

**How to fill each column**:
- **What Human Said**: The correction, redirection, or information the human provided (paraphrase, keep brief)
- **What AI Modified**: What the AI changed as a result (e.g., "switched from approach A to B", "added missing validation step")
- **Doc with Gap**: The document ID (e.g., PF-TSK-009, PF-GDE-012) whose missing or unclear guidance caused the issue. Use "N/A — inherently human decision" for preference-based corrections that cannot be codified
- **Suggested Fix**: A specific, actionable documentation update that would prevent recurrence (e.g., "Add callout to Step 3 about X"). Use "None — judgment call" when the correction was situational

**Skip this section entirely** if no human interventions occurred during the session.

**Key principle**: Not every intervention is a doc gap. Some corrections reflect situational judgment, personal preference, or novel circumstances that no documentation could anticipate. Use the "N/A" and "None" options honestly — inflating doc-gap counts undermines the signal.

**Post-session human rows**: the Human Intervention Log doubles as the human partner's feedback channel. After the session ends, the human appends any further feedback — corrections the agent missed, observations about the session — as additional rows in the same table. The AI agent must not solicit this feedback during the session or write rows on the human's behalf.

## Feedback Handling Rules

### Scope Freeze During Finalization

> **⚠️ SCOPE FREEZE during finalization**: If you discover new improvement opportunities, bugs, or process issues while completing feedback forms, record them as observations in the feedback form — do not stop to implement them. Finalization is for documenting what happened, not for starting new work. Implementing changes during finalization breaks checkpoint discipline and risks incomplete session closure.

### Document, Don't Implement

When you discover issues or improvements during finalization, **record them in the feedback form** — do not implement changes directly. Feedback flows through the Tools Review cycle (PF-TSK-010), which triages, prioritizes, and routes improvements properly. Implementing fixes inline during finalization bypasses this process and risks unreviewed changes.

### Keep Feedback in the Form

If a finding can be resolved by updating a task definition, guide, or template, **leave it in the feedback form only**. Do not save it to persistent memory or external tracking — the feedback form is the intake mechanism (an IMP filed directly under the [routing guide](issue-classification-and-routing-guide.md)'s file-now conditions is the exception, cross-referenced in the form as already filed). Once the Tools Review processes the form and the relevant document is updated, memory entries about it become stale and misleading.

## Common Pitfalls to Avoid

### Rating Pitfalls
- **Grade inflation**: Don't default to 4-5 ratings
- **Perfectionism**: A tool doesn't need to be perfect to get a 5
- **Context ignorance**: Rate based on this specific use case
- **Comparison confusion**: Rate the tool, not your skill with it

### Comment Pitfalls
- **Vague feedback**: "It was fine" doesn't help improve anything
- **Only negatives**: Mention what worked well too
- **No examples**: Specific examples make feedback actionable
- **Personal preferences**: Focus on objective effectiveness

## Examples of Good vs. Poor Feedback

### Good Effectiveness Comment
"The template provided clear structure for the analysis, and the step-by-step process helped ensure I didn't miss any critical evaluation criteria. The rating scales were particularly helpful for maintaining consistency across multiple tools."

### Poor Effectiveness Comment
"It worked okay."

### Good Improvement Suggestion
"Add a quick reference card with the rating scale definitions so I don't have to scroll back to the guide repeatedly. Also, consider adding a checklist at the end to verify all required sections are complete."

### Poor Improvement Suggestion
"Make it better."

## Quality Checklist

Before submitting your feedback form, verify:

- [ ] All required fields are completed
- [ ] Ratings are justified with specific comments
- [ ] Improvement suggestions are actionable and specific
- [ ] Comment-borne actionable suggestions are repeated in "Specific suggestions"
- [ ] Intervention log contains only counter-flow interventions (no checkpoint approvals)
- [ ] File is saved with correct naming convention in correct location
- [ ] Metadata ID is properly assigned (PF-FEE-XXX format)

## Getting Help

If you need assistance with feedback forms:
1. Review this guide thoroughly
2. Check existing feedback forms for examples
3. Ask for clarification on specific rating scenarios

Remember: Good feedback drives process improvement. Take the time to provide thoughtful, specific, and actionable feedback.
