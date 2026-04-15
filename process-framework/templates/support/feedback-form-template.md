---
# Template Metadata
id: PF-TEM-007
type: Process Framework
category: Template
version: 2.1
created: 2023-06-15
updated: 2026-04-14

# Document Creation Metadata
template_for: Tool Feedback Form
creates_document_type: Artifact
creates_document_category: Feedback
creates_document_prefix: PF-FEE
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
> **📖 Need Help?** See the [Feedback Form Guide](../../guides/framework/feedback-form-guide.md) for detailed instructions, time tracking requirements, and rating guidelines.
>
> **🚀 Quick Start**: Use the automation script: `scripts/file-creation/New-FeedbackForm.ps1 -DocumentId "PF-TSK-XXX" -TaskContext "Task Name" -FeedbackType "MultipleTools"`
>
> **✅ Before Submitting**: Run validation: process-framework/scripts/validation/Validate-FeedbackForms.ps1 to ensure completion

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

## Human Intervention Log
*Record each instance where the human partner corrected, redirected, or supplemented the AI agent's work. Each entry is a potential documentation gap — if the docs were complete, the correction may not have been needed. Skip this section if no interventions occurred.*

| # | What Human Said | What AI Modified | Doc with Gap | Suggested Fix |
|---|----------------|-----------------|-------------|---------------|
| 1 | [Correction or redirection given] | [What the AI changed in response] | [Document ID or "N/A — inherently human decision"] | [Specific doc update that would prevent recurrence, or "None — judgment call"] |
| 2 | [Correction or redirection given] | [What the AI changed in response] | [Document ID or "N/A — inherently human decision"] | [Specific doc update that would prevent recurrence, or "None — judgment call"] |

*Add rows as needed. Mark "N/A — inherently human decision" when the correction reflects a preference or judgment that cannot be codified.*

---

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
<!-- NOTE: Only document suggestions here. Do NOT register PF-IMP entries or run New-ProcessImprovement.ps1 — that is the job of PF-TSK-009/PF-TSK-010. -->
- [ ] [Specific improvement suggestion]
- [ ] [Specific improvement suggestion]

### Documentation Streamlining Opportunities
- [ ] [Specific overdocumentation to address]
- [ ] [Specific overdocumentation to address]

---

## Human User Feedback
*This section is for the human partner to fill independently after the session ends. AI agents should leave this section empty.*

[Human partner fills this section after the session]

---

## AI Assistant Summary
[Provide a brief summary of the overall feedback and key priorities for improvement]
