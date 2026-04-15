---
id: PF-GDE-017
type: Process Framework
category: Guide
version: 1.1
created: 2025-07-13
updated: 2026-04-14
---

# Feedback Form Completion Instructions

This document provides standardized instructions for completing feedback forms that are referenced by all task definitions to eliminate duplication.

## Standard Feedback Form Completion Process

**🚨 MANDATORY**: A feedback form must be created for each task session.

### Step 1: Create Feedback Form

At session end, use the provided PowerShell script to create a feedback form template:

```bash
pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/support/New-FeedbackForm.ps1 -DocumentId "[TASK-ID]" -TaskContext "[Task Name]" -FeedbackType "MultipleTools" -Confirm:\$false
```

**Replace placeholders:**
- `[TASK-ID]`: The actual task ID (e.g., "PF-TSK-002")
- `[Task Name]`: The actual task name (e.g., "Feature Tier Assessment")

### Step 2: Complete the Form

The AI agent fills in all sections of the feedback form: task-level evaluation, tool ratings, integration assessment, improvement suggestions, human intervention log, and AI assistant summary.

**Do not** solicit human feedback during the session. The "Human User Feedback" section is left for the human partner to fill independently after the session ends.

The script automatically:
- Names the file using format: `YYYYMMDD-HHMMSS-document-id-feedback.md`
- Places the file in `/process-framework-local/feedback/feedback-forms`
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
3. Fill in all sections (ratings, comments, intervention log, summary)
4. Leave the "Human User Feedback" section empty — the human partner fills it independently after the session

### For Human Partners
1. After the session ends, open the feedback form in `/process-framework-local/feedback/feedback-forms`
2. Fill in the "Human User Feedback" section at your own pace
3. See [Feedback Form Guide](feedback-form-guide.md) for detailed completion guidance

## Benefits of This Approach

- **Consistency**: All tasks use identical feedback instructions
- **Maintainability**: Updates only need to be made in one location
- **Efficiency**: Human provides feedback asynchronously without session overhead
- **Quality**: Human can reflect on the session before providing feedback

---

*This guide is part of the Process Framework and provides standardized feedback form completion instructions for all tasks.*
