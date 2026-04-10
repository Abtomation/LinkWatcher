---
id: PF-GDE-017
type: Process Framework
category: Guide
version: 1.0
created: 2025-07-13
updated: 2026-04-10
---

# Feedback Form Completion Instructions

This document provides standardized instructions for completing feedback forms that are referenced by all task definitions to eliminate duplication.

## Standard Feedback Form Completion Process

**🚨 MANDATORY**: Complete feedback forms for each tool used during the task.

### Step 1: Create Feedback Form

Use the provided PowerShell script to automatically create a feedback form:

```bash
pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/support/New-FeedbackForm.ps1 -DocumentId "[TASK-ID]" -TaskContext "[Task Name]" -FeedbackType "MultipleTools" -Confirm:\$false
```

**Replace placeholders:**
- `[TASK-ID]`: The actual task ID (e.g., "PF-TSK-002")
- `[Task Name]`: The actual task name (e.g., "Feature Tier Assessment")

### Step 2: Complete the Form

The script automatically:
- Names the file using format: `YYYYMMDD-HHMMSS-document-id-feedback.md`
- Places the file in `/process-framework-local/feedback/feedback-forms`
- Assigns unique artifact IDs (`ART-FEE-XXX`) in metadata
- Includes a section for human user feedback (AI assistant will prompt for input)

### Step 3: Follow Completion Guidelines

For detailed guidance on completing feedback forms effectively, see:
- [Feedback Form Guide](feedback-form-guide.md) - Comprehensive guide for completing feedback forms

## Integration with Tasks

### For Task Authors
When creating or updating task definitions, reference this guide instead of duplicating instructions:

```markdown
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Completion Instructions](feedback-form-completion-instructions.md) for each tool used, using task ID "[TASK-ID]" and context "[Task Name]"
```

### For Task Executors
1. Complete your task work
2. Follow the instructions in this guide
3. Use the specific task ID and name for your current task
4. Complete all feedback forms before considering the task finished

> **⚠️ SCOPE FREEZE during finalization**: If you discover new improvement opportunities, bugs, or process issues while completing feedback forms, record them as observations in the feedback form — do not stop to implement them. Finalization is for documenting what happened, not for starting new work. Implementing changes during finalization breaks checkpoint discipline and risks incomplete session closure.

## Benefits of This Approach

- **Consistency**: All tasks use identical feedback instructions
- **Maintainability**: Updates only need to be made in one location
- **Clarity**: Detailed instructions available without cluttering task definitions
- **Efficiency**: Reduced duplication across all task documents

---

*This guide is part of the Process Framework and provides standardized feedback form completion instructions for all tasks.*
