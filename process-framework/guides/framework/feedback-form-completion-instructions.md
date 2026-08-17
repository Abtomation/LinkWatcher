---
id: PF-GDE-017
type: Process Framework
category: Guide
version: 1.2
created: 2025-07-13
updated: 2026-06-11
description: "Standardized feedback form completion process referenced by all task definitions to eliminate duplication"
---

# Feedback Form Completion Instructions

This document provides standardized instructions for completing feedback forms that are referenced by all task definitions to eliminate duplication.

## Standard Feedback Form Completion Process

**🚨 MANDATORY**: A feedback form must be created for each task session.

### Step 1: Create Feedback Form

At **genuine session end** — after the final batch of a multi-batch session, never at the first batch boundary — use the provided PowerShell script to create the single per-session feedback form covering all batches. Filing it early risks a mid-session Tools Review sweeping a premature, incomplete form:

```bash
pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/support/New-FeedbackForm.ps1 -DocumentId "[TASK-ID]" -TaskContext "[Task Name]" -FeedbackType "MultipleTools" -Confirm:\$false
```

**Replace placeholders:**
- `[TASK-ID]`: The actual task ID (e.g., "PF-TSK-009")
- `[Task Name]`: The actual task name (e.g., "Process Improvement")

### Step 2: Complete the Form

The AI agent fills in all sections of the feedback form: task-level evaluation, tool ratings, improvement suggestions, and the human intervention log.

**Authoring rule — comment-borne suggestions**: any actionable suggestion written in a rating Comments field must also be added to "Specific suggestions". The ratings extractor captures numbers only, so a suggestion that exists solely in a comment never reaches the review pipeline.

**Do not** solicit human feedback during the session. The human partner contributes independently after the session by appending rows to the form's Human Intervention Log.

The script automatically:
- Names the file using format: `YYYYMMDD-HHMMSS-document-id-feedback.md`
- Places the file in `appdev/process-framework-central/feedback/feedback-forms/`
- Assigns unique artifact IDs (`ART-FEE-XXX`) in metadata

### Step 3: Follow Completion Guidelines

For detailed guidance on completing feedback forms effectively, see:
- [Feedback Form Guide](feedback-form-guide.md) - Comprehensive guide for completing feedback forms

> **⚠️ SCOPE FREEZE during finalization**: If you discover new improvement opportunities, bugs, or process issues while creating the feedback form, record them as observations — do not stop to implement them. Finalization is for documenting what happened, not for starting new work.

## Integration with Tasks

### For Task Authors
When creating or updating task definitions, reference this guide instead of duplicating instructions:

```markdown
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Completion Instructions](feedback-form-completion-instructions.md) for each tool used, using task ID "[TASK-ID]" and context "[Task Name]"
```

### For Task Executors (AI Agent)
1. Complete your task work
2. Create the feedback form using the script above
3. Fill in all sections (ratings, comments, suggestions, intervention log)
4. Repeat any comment-borne actionable suggestion in "Specific suggestions"

### For Human Partners
1. After the session ends, open the feedback form in `appdev/process-framework-central/feedback/feedback-forms/`
2. Append any further feedback — corrections the agent missed, observations about the session — as additional rows in the Human Intervention Log
3. See [Feedback Form Guide](feedback-form-guide.md) for detailed completion guidance

## Benefits of This Approach

- **Consistency**: All tasks use identical feedback instructions
- **Maintainability**: Updates only need to be made in one location
- **Efficiency**: Human provides feedback asynchronously without session overhead
- **Quality**: Human can reflect on the session before providing feedback

---

*This guide is part of the Process Framework and provides standardized feedback form completion instructions for all tasks.*
