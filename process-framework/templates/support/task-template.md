---
# Template Metadata
id: PF-TEM-015
type: Process Framework
category: Template
version: 1.2
created: 2025-01-27
updated: 2026-06-12

# Document Creation Metadata
template_for: Task Definition
creates_document_type: Process Framework
creates_document_category: Task Definition
creates_document_prefix: PF-TSK
creates_document_version: 1.0

# Template Usage Context
usage_context: Process Framework - Task Creation
description: Creates task definition documents for process framework

---

# [Task Name]

<!-- 📐 TASK METADATA SCHEMA (single source of truth — PF-PRO-042):
After creation, extend this file's frontmatter with the task-metadata fields below.
Build-TaskMetadata.ps1 generates the ai-tasks.md tables, both infrastructure registries,
and the tasks/README catalog from these fields plus the File Operations and Next Tasks
sections — never hand-edit those generated surfaces. `-ReportMissing` flags task files
lacking required fields. Per-category rules: `complexity` is omitted for support tasks
(no Complexity column); `trigger_status`/`output_status` are omitted for tasks without
state-file triggers; cyclical tasks use `use_when` for the Trigger column text.

complexity: simple | medium | complex     # renders 🟢/🟡/🔴
use_when: >-
  Routing text for the Use When column.
triggers:                                  # example phrasings, appended to the Use When cell
  - "improve task X"
automation: full | semi | partial | manual
frequency: "Quarterly/As needed"           # cyclical tasks only (renders the Frequency column)
scripts:                                   # file-relative paths (LinkWatcher-maintained on moves)
  - ../../scripts/file-creation/support/New-Task.ps1
trigger_status:                            # state-file status that activates this task
  - file: feature-tracking.md
    status: "📝 Needs TDD"
output_status:                             # state-file status this task produces
  - file: feature-tracking.md
    status: "🧪 Needs Test Spec"
    condition: ""                          # optional, for branching outputs
next_tasks:                                # downstream chain (also keep the Next Tasks section)
  - task: ../03-testing/test-specification-creation-task.md
    condition: "Always"
-->

> **▶ Execute this task under the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md).** This file holds only this task's specific content; the universal contract every task shares lives once in the protocol and is mandatory here.

## Purpose & Context

[1-2 sentences explaining the task's purpose and importance in the overall process]

## AI Agent Role

**Role**: [Professional Role Title]
**Mindset**: [Key behavioral and thinking patterns for this role]
**Focus Areas**: [Primary areas of attention and expertise]
**Communication Style**: [How to interact with human partner in this role]

## Context Requirements

- **Critical (Must Read):**

  - [Critical Input 1] - [Brief description with link to source]
  - [Critical Input 2] - [Brief description with link to source]

- **Important (Load If Space):**

  - [Important Input 1] - [Brief description with link to source]
  - [Important Input 2] - [Brief description with link to source]
  <!-- Component Relationship Index - Removed: file deleted -->

- **Reference Only (Access When Needed):**
  - [Reference Input 1] - [Brief description with link to source]
  - [Reference Input 2] - [Brief description with link to source]

## Process

> Add any **task-specific** cautions here (e.g. "create backups first", "never proceed past a checkpoint without approval"). The universal completion / feedback / automation-script mandates live in the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md) — do not restate them.

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

<!-- Note to task creator: Replace placeholders with actual linked state files (e.g., [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md)) -->

## ⚠️ Task Completion Checklist (task-specific)

> Completion discipline, output verification, and the feedback form are governed by the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md) (Phase C). The items below are the **task-specific** verifications that plug into it.

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] [Specific output 1 verification]
  - [ ] [Specific output 2 verification]
- [ ] **Update State Files**: Ensure all state tracking files have been updated

  - [ ] [Specific state file 1 update verification]
  - [ ] [Specific state file 2 update verification]

  <!-- Note to task creator: Link state files in checklist items just as in the State Tracking section -->

- [ ] **Feedback form** completed per the [Task Execution Protocol → Feedback step](../../guides/framework/task-execution-protocol-guide.md#feedback-step) — task ID `PF-TSK-XXX`, context "[Task Name]".

## File Operations

<!-- Authored metadata section (PF-PRO-042): the generator aggregates this table into the
process-framework-task-registry.md catalog entry for this task. List every file this task
creates or updates, including the update mechanism (script or manual). -->

| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | `[file-pattern.md]` | `[Script.ps1 / Manual]` | [What is created] |
| **Updates** | [state-file link] | `[Script.ps1 / Manual]` | [Status transition or content change] |

## Next Tasks

- **Next Task 1** - [Brief description of how it connects]
- **Next Task 2** - [Brief description of how it connects]

<!-- Authored metadata section (PF-PRO-042): the three subsections below are aggregated by
the generator into task-transition-registry.md. Keep them current alongside the link list above. -->

### Prerequisites for Transition

- [ ] [Output or state required before leaving this task]
- [ ] [Verification completed]

### Next Task Selection

[Decision tree or rule for choosing the next task — plain statement when unconditional]

### Preparation for Next Task

1. [Step to set up the next task's inputs]
2. [Context to carry forward]

<!-- For Cyclical Tasks Only -->

## Metrics and Evaluation

- [Metric 1]: [How to measure]
- [Metric 2]: [How to measure]
- Success criteria: [What indicates successful completion]

<!-- For Cyclical Tasks Only -->

## Continuous Improvement

[How this task or process should be evaluated and improved over time]

## Related Resources

- Resource 1 - [Brief description]
- Resource 2 - [Brief description]
