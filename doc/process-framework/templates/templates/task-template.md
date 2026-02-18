---
# Template Metadata
id: PF-TEM-015
type: Process Framework
category: Template
version: 1.0
created: 2025-01-27
updated: 2025-07-08

# Document Creation Metadata
template_for: Task Definition
creates_document_type: Process Framework
creates_document_category: Task Definition
creates_document_prefix: PF-TSK
creates_document_version: 1.0

# Template Usage Context
usage_context: Process Framework - Task Creation
description: Creates task definition documents for process framework

# Additional Fields for Generated Documents
additional_fields:
  task_type: "[TASK_TYPE]"
---

# [Task Name]

## Purpose & Context

[1-2 sentences explaining the task's purpose and importance in the overall process]

## AI Agent Role

**Role**: [Professional Role Title]
**Mindset**: [Key behavioral and thinking patterns for this role]
**Focus Areas**: [Primary areas of attention and expertise]
**Communication Style**: [How to interact with human partner in this role]

## When to Use

- [Clear criteria for when this task should be performed]
- [Trigger conditions for cyclical or continuous tasks]
- [Prerequisites that must be met before starting]

## Context Requirements

<!-- [View Context Map for this task](../../visualization/context-maps/[task-type]/[task-name]-map.md) - Template/example link commented out -->

- **Critical (Must Read):**

  - [Critical Input 1] - [Brief description with link to source]
  - [Critical Input 2] - [Brief description with link to source]

- **Important (Load If Space):**

  - [Important Input 1] - [Brief description with link to source]
  - [Important Input 2] - [Brief description with link to source]
  - Component Relationship Index](/doc/product-docs/technical/architecture/component-relationship-index.md) - For understanding component interactions

- **Reference Only (Access When Needed):**
  - [Reference Input 1] - [Brief description with link to source]
  - [Reference Input 2] - [Brief description with link to source]
  - [Visual Notation Guide](/doc/process-framework/guides/guides/visual-notation-guide.md) - For interpreting context map diagrams

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished! 🚨**
>
> **⚠️ MANDATORY: Use the appropriate automation tools where indicated.**

### Preparation

1. [Initial step with clear instruction]
2. [Review or setup steps]
3. [Any required tool configuration]

### Execution

4. [Main execution steps with detailed instructions]
5. [Automation steps with exact commands where applicable]
   ```bash
   # Example automation command
   .<!-- /script-name.ps1 - File not found --> -Parameter "Value"
   ```
6. [Decision points with clear guidance]
7. [Quality checks during execution]

### Finalization

8. [Final steps to complete the task]
9. [Verification steps]
10. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

<!-- For Cyclical Tasks Only -->

## Cycle Frequency

[For cyclical tasks, describe how often this task should be performed]

<!-- For Cyclical Tasks Only -->

## Trigger Events

[For cyclical tasks, describe what events trigger this task]

## Outputs

- **[Output 1 Name]** - [Detailed description with exact location]
- **[Output 2 Name]** - [Detailed description with exact location]
- **[Additional outputs as needed]**

## State Tracking

The following state files must be updated as part of this task:

- [State File 1] - Update with [specific information to update]
- [State File 2] - Update with [specific information to update]

<!-- Note to task creator: Replace placeholders with actual linked state files (e.g., [Feature Tracking](../../state-tracking/permanent/feature-tracking.md)) -->

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

Before considering this task finished:

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] [Specific output 1 verification]
  - [ ] [Specific output 2 verification]
- [ ] **Update State Files**: Ensure all state tracking files have been updated

  - [ ] [Specific state file 1 update verification]
  - [ ] [Specific state file 2 update verification]

  <!-- Note to task creator: Link state files in checklist items just as in the State Tracking section -->

- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Completion Instructions](../../guides/guides/feedback-form-completion-instructions.md) for each tool used, using task ID "PF-TSK-XXX" and context "[Task Name]"

## Next Tasks

- <!-- [**Next Task 1**](../path/to/next-task-1.md) - Template/example link commented out --> - [Brief description of how it connects]
- <!-- [**Next Task 2**](../path/to/next-task-2.md) - Template/example link commented out --> - [Brief description of how it connects]

<!-- For Cyclical Tasks Only -->

## Metrics and Evaluation

- [Metric 1]: [How to measure]
- [Metric 2]: [How to measure]
- Success criteria: [What indicates successful completion]

<!-- For Cyclical Tasks Only -->

## Continuous Improvement

[How this task or process should be evaluated and improved over time]

## Related Resources

- <!-- [Resource 1](../link-to-resource1.md) - Template/example link commented out --> - [Brief description]
- <!-- [Resource 2](../link-to-resource2.md) - Template/example link commented out --> - [Brief description]
