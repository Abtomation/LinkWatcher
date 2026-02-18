---
# Template Metadata
id: PF-TEM-007
type: Process Framework
category: Template
version: 2.0
created: 2023-06-15
updated: 2025-07-08

# Document Creation Metadata
template_for: Tool Feedback Form
creates_document_type: Artifact
creates_document_category: Feedback
creates_document_prefix: PF-FBK
creates_document_version: 1.0

# Template Usage Context
usage_context: Process Framework - Tool Feedback Collection
description: Creates feedback forms for evaluating tools and processes

# Additional Fields for Generated Documents
additional_fields:
  feedback_type: "[FEEDBACK_TYPE]"
  task_context: "[TASK_CONTEXT]"
  document_id: "[DOCUMENT_ID]"
---

# Tool Feedback Form

> **🚨 CRITICAL COMPLETION REMINDER**: This feedback form MUST be fully completed before submission. Forms with template placeholders like [Rating], [Tool Name], or [Comments] will be automatically archived as incomplete and excluded from tools review analysis.
>
> **📖 Need Help?** See the [Feedback Form Guide](feedback-form-guide.md) for detailed instructions, time tracking requirements, and rating guidelines.
>
> **🚀 Quick Start**: Use the automation script: `scripts/file-creation/New-FeedbackForm.ps1 -DocumentId "PF-TSK-XXX" -TaskContext "Task Name" -FeedbackType "Multiple Tools"`
>
> **✅ Before Submitting**: Run validation: `./doc/process-framework/feedback/Validate-FeedbackForms.ps1` to ensure completion

| Task Evaluated | [Task Name (PF-TSK-XXX)] |
| Task Context | [Brief description of what was accomplished] |
| Session Duration | [REQUIRED: Start: HH:MM, End: HH:MM, Total: X minutes] |
| Feedback Type | [Single Tool / Multiple Tools / Task-Level] |

## Task-Level Evaluation
*Complete this section for task-level feedback or when evaluating multiple tools*

### Overall Process Effectiveness
How effectively did the complete workflow support task completion?

**Rating (1-5)**: [Rating]

**Comments**:
[Overall assessment of the task process, workflow integration, and outcome quality]

### Process Conciseness
Was the overall process appropriately streamlined without unnecessary steps or documentation overhead?

**Rating (1-5)**: [Rating]

**Comments**:
[Assessment of process efficiency and documentation overhead]

---

## Tool Evaluation
*Complete one section per tool used. For single-tool feedback, complete only Tool 1.*

### Tool 1: [Tool Name ([PREFIX]-XXX-XXX)]
**Purpose**: [How this tool was used in the task]

### Effectiveness
How effectively did this tool support the completion of the task?

**Rating (1-5)**: [Rating]

**Comments**:
[Detailed comments about the tool's effectiveness]

### Clarity
How clear and understandable was this tool?

**Rating (1-5)**: [Rating]

**Comments**:
[Detailed comments about the tool's clarity]

### Completeness
Did this tool provide all the necessary information/guidance?

**Rating (1-5)**: [Rating]

**Comments**:
[Detailed comments about the tool's completeness]

### Efficiency
Did this tool help complete the task efficiently?

**Rating (1-5)**: [Rating]

**Comments**:
[Detailed comments about the tool's efficiency]

### Conciseness
Was this tool appropriately concise, containing only task-essential information?

**Rating (1-5)**: [Rating]

**Comments**:
[Detailed comments about overdocumentation, redundancy, or missing essential information]

### Tool 2: [Tool Name ([PREFIX]-XXX-XXX)] *(Optional)*
**Purpose**: [How this tool was used in the task]

#### Effectiveness
**Rating (1-5)**: [Rating]
**Comments**: [Brief comments]

#### Clarity
**Rating (1-5)**: [Rating]
**Comments**: [Brief comments]

#### Completeness
**Rating (1-5)**: [Rating]
**Comments**: [Brief comments]

#### Efficiency
**Rating (1-5)**: [Rating]
**Comments**: [Brief comments]

#### Conciseness
**Rating (1-5)**: [Rating]
**Comments**: [Brief comments]

### Tool 3: [Tool Name ([PREFIX]-XXX-XXX)] *(Optional)*
**Purpose**: [How this tool was used in the task]

#### Effectiveness
**Rating (1-5)**: [Rating]
**Comments**: [Brief comments]

#### Clarity
**Rating (1-5)**: [Rating]
**Comments**: [Brief comments]

#### Completeness
**Rating (1-5)**: [Rating]
**Comments**: [Brief comments]

#### Efficiency
**Rating (1-5)**: [Rating]
**Comments**: [Brief comments]

#### Conciseness
**Rating (1-5)**: [Rating]
**Comments**: [Brief comments]

*[Add more tool sections as needed]*

---

## Integration Assessment
*Complete this section when evaluating multiple tools*

### Tool Synergy
How well did the tools work together as a cohesive system?

**Rating (1-5)**: [Rating]

**Comments**:
[Assessment of how tools complemented each other, any conflicts or gaps]

### Workflow Efficiency
Was the sequence of tool usage logical and efficient?

**Rating (1-5)**: [Rating]

**Comments**:
[Assessment of tool usage order, transitions between tools, workflow logic]

---

## Improvement Suggestions

### What worked well
[List aspects of the tool that worked well]

### What could be improved
[List aspects of the tool that could be improved]

### Specific suggestions
[Provide specific, actionable suggestions for improving the tool]

## Additional Context

### Task-specific challenges
[Describe any challenges specific to this task that affected the tool's usefulness]

### Integration with other tools
[Describe how this tool integrated with other tools/templates/guides]

## Follow-up Actions Required
*Complete this section to identify next steps*

### Tools Needing Detailed Feedback
- [ ] [Tool Name ([PREFIX]-XXX-XXX)] - Scored ≤3 in [criteria] - Requires detailed feedback form
- [ ] [Tool Name ([PREFIX]-XXX-XXX)] - Scored ≤3 in [criteria] - Requires detailed feedback form

### Process Improvements to Consider
- [ ] [Specific improvement suggestion]
- [ ] [Specific improvement suggestion]

### Documentation Streamlining Opportunities
- [ ] [Specific overdocumentation to address]
- [ ] [Specific overdocumentation to address]

---

## Human User Feedback
*AI assistant MUST actively solicit user feedback before completing this section*

> **CRITICAL**: Do not fill this section without first asking the human user for their input.

[User feedback will be documented here after being actively solicited by the AI assistant]

---

## AI Assistant Summary
[Provide a brief summary of the overall feedback and key priorities for improvement]
