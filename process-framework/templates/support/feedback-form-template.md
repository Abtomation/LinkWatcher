---
# Template Metadata
id: PF-TEM-007
type: Process Framework
category: Template
version: 3.1
created: 2023-06-15
updated: 2026-07-21

# Document Creation Metadata
template_for: Tool Feedback Form
creates_document_type: Process Framework
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
> **📖 Need Help?** See the [Feedback Form Guide](../../guides/framework/feedback-form-guide.md) for detailed instructions and rating guidelines.
>
> **🚀 Quick Start**: Use the automation script: `scripts/file-creation/New-FeedbackForm.ps1 -DocumentId "PF-TSK-XXX" -TaskContext "Task Name" -FeedbackType "MultipleTools"`
>
> **✅ Before Submitting**: Run validation with `Validate-FeedbackForms.ps1` (in the framework's validation scripts) to ensure completion

| Task Evaluated | [Task Name (PF-TSK-XXX)] |
| Task Context | [Brief description of what was accomplished] |
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

> **🔖 The `(...)` after each tool name is its `tool_doc_id`** — the database key that links your ratings to the tool's change history. Use the artifact's **portable framework ID** (`PF-TSK-009`, `PF-GDE-068`, `PF-TEM-033`, `PF-FST-003` — any pool in the rolled-out `PF-id-registry.json`); use the **filename** only when the artifact has no such ID — a script, craft skill, or companion path file (`New-Task.ps1`, `imp-triage/SKILL.md`, `code-refactoring-lightweight-path.md`), path-qualified when the basename is shared (`unit/README.md`). Do **not** use a project-local instance ID (`PD-*`, `TE-*`, `PF-STA`) — rate the `blueprint/` template that generated it instead — and do **not** leave it blank. Examples — `### Tool 1: Process Improvement (PF-TSK-009)`, `### Tool 2: New-Task script (New-Task.ps1)`, `### Tool 3: imp-triage craft skill (imp-triage/SKILL.md)`. Full rule: [TOOL_DOC_ID convention](../../guides/support/process-improvement-task-reference-guide.md#tool_doc_id-convention).

### Tool 1: [Tool display name] ([tool_doc_id — see note above])
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

### Tool 2: [Tool display name] ([tool_doc_id])
*(Optional — complete only if a second tool was used.)*
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

### Tool 3: [Tool display name] ([tool_doc_id])
*(Optional — complete only if a third tool was used.)*
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

## Improvement Suggestions

### What worked well
[List aspects of the tool that worked well]

### What could be improved
[List aspects of the tool that could be improved]

### Specific suggestions
*The single canonical suggestion list in this form — Tools Review drains improvement candidates from here. Any actionable suggestion written in a rating Comments field above must be repeated here; comment-borne suggestions have no other route into the review pipeline.*
<!-- NOTE: Suggestions ride this list to Tools Review — do NOT run New-ProcessImprovement.ps1 for them. An issue meeting the Issue Classification and Routing Guide's file-now conditions (blocks/affects other sessions, human-directed, or filed by the owning task's own process) is filed directly and listed here as "[ALREADY FILED — PF-IMP-NNNN, do not re-file]". -->
- [Specific, actionable suggestion]
- [Specific, actionable suggestion]

## Human Intervention Log
*Record each instance where the human partner **countered or redirected the AI agent's current course** — corrections, reversals, rejected proposals, missing information the agent should have had. Checkpoint approvals and option selections ("proceed", "approve", "Option B") are the workflow operating as designed — do **not** log them. Each genuine intervention is a potential documentation gap. Skip this section if no interventions occurred.*

| # | What Human Said | What AI Modified | Doc with Gap | Suggested Fix |
|---|----------------|-----------------|-------------|---------------|
| 1 | [Correction or redirection given] | [What the AI changed in response] | [Document ID or "N/A — inherently human decision"] | [Specific doc update that would prevent recurrence, or "None — judgment call"] |
| 2 | [Correction or redirection given] | [What the AI changed in response] | [Document ID or "N/A — inherently human decision"] | [Specific doc update that would prevent recurrence, or "None — judgment call"] |

*Add rows as needed. Mark "N/A — inherently human decision" when the correction reflects a preference or judgment that cannot be codified.*

*Post-session: the human partner appends any further feedback — corrections the agent missed, observations about the session — as additional rows in this table. (This replaces the former standalone "Human User Feedback" section.)*

---

## Additional Context

### Task-specific challenges
[Describe any challenges specific to this task that affected the tool's usefulness]

### Integration with other tools
[Describe how this tool integrated with other tools/templates/guides]

## Follow-up Actions Required
*Complete this section to identify next steps*

### Documentation Streamlining Opportunities
- [ ] [Specific overdocumentation to address]
- [ ] [Specific overdocumentation to address]
