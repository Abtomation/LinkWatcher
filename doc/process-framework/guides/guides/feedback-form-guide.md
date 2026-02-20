---
id: PF-GDE-012
type: Process Framework
category: Template
version: 1.0
created: 2025-06-05
updated: 2025-07-04
---

# Feedback Form Guide

This guide provides comprehensive instructions for completing feedback forms effectively.

## Quick Start

1. **Use the automation script** (recommended):
   ```bash
   # Windows command pattern (use this for reliable execution):
   echo Set-Location 'c:\Users\ronny\VS_Code\LinkWatcher\doc\process-framework\scripts\file-creation'; ^& .\New-FeedbackForm.ps1 -DocumentId 'PF-TSK-XXX' -TaskContext 'Task Name' -FeedbackType 'MultipleTools' -Confirm:$false > temp_feedback.ps1 && pwsh.exe -ExecutionPolicy Bypass -File temp_feedback.ps1 && del temp_feedback.ps1
   ```
   > **Note**: Update the path to match your actual project location

2. **Manual creation**: Copy the template and follow the naming convention: `YYYYMMDD-HHMMSS-document-id-feedback.md`

3. **File placement**: Save in `/doc/process-framework/feedback/feedback-forms/`

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
- **Process Improvements**: Specific workflow enhancements to consider
- **Documentation Streamlining**: Areas where documentation could be more concise

### Human User Feedback
**CRITICAL**: The AI assistant must actively solicit user feedback before completing this section.

**Required approach**:
1. Ask specific questions about process effectiveness
2. Request feedback on observed issues or challenges
3. Solicit suggestions for improvement
4. Gather overall satisfaction assessment
5. Document the actual user responses

**Do not**:
- Fill this section without user input
- Make assumptions about user satisfaction
- Skip this section

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
- [ ] Metadata ID is properly assigned (ART-FEE-XXX format)

## Getting Help

If you need assistance with feedback forms:
1. Review this guide thoroughly
2. Check existing feedback forms for examples
3. Consult the [Assessment Quick Reference](../../../../templates/methodologies/documentation-tiers/assessment-quick-reference.md) for evaluation criteria
4. Ask for clarification on specific rating scenarios

Remember: Good feedback drives process improvement. Take the time to provide thoughtful, specific, and actionable feedback.
