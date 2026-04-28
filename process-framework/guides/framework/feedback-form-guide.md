---
id: PF-GDE-012
type: Process Framework
category: Guide
version: 1.1
created: 2025-06-05
updated: 2026-04-14
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

3. **File placement**: Save in `/process-framework-local/feedback/feedback-forms`

## Time Tracking Requirements

**CRITICAL**: Use actual measured time, not estimates.

### How to Track Time Accurately
1. **Record start time** when beginning the task (format: HH:MM)
2. **Record end time** when completing the task (format: HH:MM)
3. **Calculate total duration** in minutes
4. **Format**: "Start: 14:30, End: 15:45, Total: 75 minutes"

### Examples
- ✅ **Good**: "Start: 09:15, End: 10:30, Total: 75 minutes"
- ✅ **Good**: "Start: 14:00, End: 14:45, Total: 45 minutes"
- ❌ **Bad**: "About an hour"
- ❌ **Bad**: "45-60 minutes"
- ❌ **Bad**: "Not sure, maybe 30 minutes"

### Why Accurate Time Matters
- Enables process efficiency improvements
- Validates tool enhancement effectiveness
- Supports data-driven optimization decisions
- Tracks trends in task completion times

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
- **Session Duration**: Use the time tracking format described above
- **Feedback Type**: Choose Single Tool, Multiple Tools, or Task-Level

### Task-Level Evaluation
Complete this when evaluating the overall process or multiple tools together.

**Process Effectiveness**: Focus on the complete workflow, not individual tools.
**Process Conciseness**: Evaluate if the process has the right balance of structure vs. overhead.

### Tool Evaluation
Complete one section per tool used.

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

### Integration Assessment
Complete when using multiple tools.

**Tool Synergy**: How well did tools work together? Look for conflicts, gaps, or smooth handoffs.
**Workflow Efficiency**: Was the sequence logical? Were there unnecessary back-and-forth steps?

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
- Provide actionable recommendations
- Be specific about what should change
- Consider implementation feasibility

### Additional Context
Use this section for:
- Unique challenges in this task
- Environmental factors that affected tool performance
- Integration issues with other tools
- Context that might affect the feedback interpretation

### Follow-up Actions
This section helps prioritize improvements:
- **Tools Needing Detailed Feedback**: Any tool scoring ≤3 in any criteria
- **Process Improvements**: Specific workflow enhancements to consider (document only — do not register PF-IMP entries; that is handled by PF-TSK-009/PF-TSK-010)
- **Documentation Streamlining**: Areas where documentation could be more concise

### Human Intervention Log
Use this section to capture each instance where the human partner corrected or redirected the AI agent during the task. The goal is **documentation gap detection**, not blame — each intervention is a signal that a task definition, guide, or template may be missing information.

**When to fill**: After completing the task work, as part of session finalization. Review the session and identify moments where the human partner stepped in.

**How to fill each column**:
- **What Human Said**: The correction, redirection, or information the human provided (paraphrase, keep brief)
- **What AI Modified**: What the AI changed as a result (e.g., "switched from approach A to B", "added missing validation step")
- **Doc with Gap**: The document ID (e.g., PF-TSK-009, PF-GDE-012) whose missing or unclear guidance caused the issue. Use "N/A — inherently human decision" for preference-based corrections that cannot be codified
- **Suggested Fix**: A specific, actionable documentation update that would prevent recurrence (e.g., "Add callout to Step 3 about X"). Use "None — judgment call" when the correction was situational

**Skip this section entirely** if no human interventions occurred during the session.

**Key principle**: Not every intervention is a doc gap. Some corrections reflect situational judgment, personal preference, or novel circumstances that no documentation could anticipate. Use the "N/A" and "None" options honestly — inflating doc-gap counts undermines the signal.

### Human User Feedback
This section is **reserved for the human partner** to fill independently after the session ends. The AI agent must leave it empty.

**Do not**:
- Solicit human feedback during the session
- Fill this section with assumed or inferred feedback
- Skip creating the section (it must be present in the template for the human to fill)

## Feedback Handling Rules

### Scope Freeze During Finalization

> **⚠️ SCOPE FREEZE during finalization**: If you discover new improvement opportunities, bugs, or process issues while completing feedback forms, record them as observations in the feedback form — do not stop to implement them. Finalization is for documenting what happened, not for starting new work. Implementing changes during finalization breaks checkpoint discipline and risks incomplete session closure.

### Document, Don't Implement

When you discover issues or improvements during finalization, **record them in the feedback form** — do not implement changes directly. Feedback flows through the Tools Review cycle (PF-TSK-010), which triages, prioritizes, and routes improvements properly. Implementing fixes inline during finalization bypasses this process and risks unreviewed changes.

### Keep Feedback in the Form

If a finding can be resolved by updating a task definition, guide, or template, **leave it in the feedback form only**. Do not save it to persistent memory or external tracking — the feedback form is the intake mechanism. Once the Tools Review processes the form and the relevant document is updated, memory entries about it become stale and misleading.

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

### Time Tracking Pitfalls
- **Estimates**: Always use actual measured time
- **Interruptions**: Note if timing was affected by interruptions
- **Scope creep**: Track only the time for the specific task
- **Rounding**: Be precise with start/end times

## Examples of Good vs. Poor Feedback

### Good Effectiveness Comment
"The template provided clear structure for the analysis, and the step-by-step process helped ensure I didn't miss any critical evaluation criteria. The rating scales were particularly helpful for maintaining consistency across multiple tools."

### Poor Effectiveness Comment
"It worked okay."

### Good Improvement Suggestion
"Add a quick reference card with the rating scale definitions so I don't have to scroll back to the guide repeatedly. Also, consider adding a checklist at the end to verify all required sections are complete."

### Poor Improvement Suggestion
"Make it better."

### Good Time Tracking
"Start: 14:15, End: 15:30, Total: 75 minutes (includes 5-minute interruption for urgent email)"

### Poor Time Tracking
"Around an hour or so"

## Quality Checklist

Before submitting your feedback form, verify:

- [ ] All required fields are completed
- [ ] Time tracking uses actual measured time with start/end times
- [ ] Ratings are justified with specific comments
- [ ] Improvement suggestions are actionable and specific
- [ ] Human user feedback has been actively solicited and documented
- [ ] File is saved with correct naming convention in correct location
- [ ] Metadata ID is properly assigned (PF-FEE-XXX format)

## Getting Help

If you need assistance with feedback forms:
1. Review this guide thoroughly
2. Check existing feedback forms for examples
3. Consult the [Assessment Guide](../01-planning/assessment-guide.md) for evaluation criteria
4. Ask for clarification on specific rating scenarios

Remember: Good feedback drives process improvement. Take the time to provide thoughtful, specific, and actionable feedback.
