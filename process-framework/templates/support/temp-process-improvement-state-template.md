---
id: PF-TEM-063
type: Process Framework
category: Template
version: 1.4
created: 2026-03-23
updated: 2026-07-30
task_name: [TASK-NAME]
creates_document_type: Process Framework
creates_document_category: State Tracking
description: "Template for tracking multi-session process improvement implementation (via New-TempTaskState.ps1 -Variant ProcessImprovement)"
---

# Temporary Process Improvement State: [Task Name]

> **⚠️ TEMPORARY FILE**: This file tracks multi-session implementation of a process improvement. Move to `process-framework-central/state-tracking/temporary/old` after all phases are complete.

## Improvement Overview

- **Improvement Name**: [Task Name]
- **Source IMP(s)**: [IMP-XXX — link to process-improvement-tracking.md entry]
- **Source Feedback**: [Link to Tools Review summary or feedback form that identified this improvement]
- **Scope**: [Brief description of what will change]

## Affected Components

> Write this table by diffing against the source IMP row(s): every component a row names appears here, and a deliberately excluded one keeps a row marked "out of scope — \<rationale\>" so the exclusion is visible at handover rather than discovered by the next session.

| Component Type | Name | Current State | Planned Change | Priority |
| -------------- | ---- | ------------- | -------------- | -------- |
| Script         | [script-name.ps1] | [Description of current behavior] | [What changes] | [HIGH/MEDIUM/LOW] |
| Template       | [template-name.md] | [Description of current state] | [What changes] | [HIGH/MEDIUM/LOW] |
| Guide          | [guide-name.md] | [Description of current state] | [What changes] | [HIGH/MEDIUM/LOW] |
| Task Def       | [task-name.md] | [Description of current state] | [What changes] | [HIGH/MEDIUM/LOW] |

## Implementation Roadmap

### Phase 1: Analysis & Design

**Priority**: HIGH — Must complete before implementation begins

- [ ] **Review source feedback**: Read Tools Review summary and feedback forms
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
  - **Source**: [Link to feedback]
  - **Key findings**: [Summary of what the feedback identified]

- [ ] **Analyze current state**: Examine affected components
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
  - **Components examined**: [List files read and analyzed]
  - **Root cause**: [Why the current state is problematic]

- [ ] **Design solution**: Propose approach with pros/cons
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
  - **Chosen approach**: [Description of selected approach]
  - **Alternatives considered**: [Brief list of alternatives and why they were rejected]

- [ ] **CHECKPOINT**: Present analysis and approach to human partner
  - **Status**: [NOT_STARTED/APPROVED/REJECTED]
  - **Outcome**: [Approval notes or rejection reason]

### Phase 2: Implementation

**Priority**: HIGH — Core implementation work

> Customize this phase for your specific improvement. Add more phases (Phase 2a, 2b, or renumber) if the implementation spans multiple sessions or has distinct stages.

- [ ] [Describe implementation task]
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]

- [ ] **Test changes**: Verify implementation works correctly
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
  - **Test method**: [How changes were validated — e.g., -WhatIf, manual test, grep verification]
  - **Test results**: [Summary of results]

- [ ] **CHECKPOINT**: Review implementation with human partner
  - **Status**: [NOT_STARTED/APPROVED/REJECTED]
  - **Outcome**: [Approval notes or revision requests]

### Phase 3: Finalization

**Priority**: MEDIUM — Documentation, tracking, and completion

- [ ] **Update linked documents**: Update guides, task definitions, context maps that reference changed components
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
  - **Documents updated**: [List of files updated]

- [ ] **Log tool change**: Record modification in feedback database
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
  - **Convention for `<TOOL_DOC_ID>`**: the portable framework ID of the `blueprint/` artifact (`PF-TSK-009`, `PF-GDE-068`, `PF-TEM-033`, `PF-FST-003`); filename only for ID-less artifacts (scripts, craft skills, companion path files) — e.g. `New-FeedbackForm.ps1`. Never an instance ID (`PD-*`/`TE-*`/`PF-STA`) — rate the generating template instead. See [TOOL_DOC_ID convention](../../guides/support/process-improvement-task-reference-guide.md#tool_doc_id-convention).
  - **Verify canonical ID first**: `python process-framework/scripts/feedback_db.py list-tools --filter <substring>`
  - **Command**: `python process-framework/scripts/feedback_db.py log-change --tool <TOOL_DOC_ID> --imp <IMP-XXX> --description "<what changed>"` (`--date` defaults to today — pass it only for retroactive logging; add `--new-tool` if it's a first-time tool registration; for `--batch` mixed batches, prefer per-entry `"new_tool": true` in JSON so typo detection stays armed on the other entries — PF-IMP-866)

- [ ] **Update process-improvement-tracking.md**: Mark improvement as Completed
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
  - **Command**: `Update-ProcessImprovement.ps1 -ImprovementId "IMP-XXX" -NewStatus "Completed" -Impact "HIGH|MEDIUM|LOW" -ValidationNotes "What was done."`

## Session Tracking

### Session 1: [YYYY-MM-DD]

**Focus**: [Session focus]
**Completed**:

- [List completed items]

**Issues/Blockers**:

- [List any issues encountered]

**Next Session Plan**:

- [Plan for next session]

### Session 2: [YYYY-MM-DD]

**Focus**: [Session focus]
**Completed**:

- [List completed items]

**Issues/Blockers**:

- [List any issues encountered]

**Next Session Plan**:

- [Plan for next session]

## Completion Criteria

This temporary state file can be moved to `process-framework-central/state-tracking/temporary/old` when:

- [ ] All implementation phases are complete
- [ ] All affected components are updated and tested
- [ ] Process improvement tracking is updated (Completed status)
- [ ] Linked documents are updated
- [ ] Feedback form completed for every calendar session (one per session — ai-tasks.md), including the final one

## Notes and Decisions

### Key Decisions Made

- [Decision 1]: [Rationale]

### Implementation Notes

- [Note 1]
