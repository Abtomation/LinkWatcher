---
id: PF-STA-077
type: Document
category: General
version: 1.0
created: 2026-04-08
updated: 2026-04-08
task_name: imp-387-script-parameter-check
---

# Temporary Process Improvement State: IMP-387 Script Parameter Check

> **⚠️ TEMPORARY FILE**: This file tracks multi-session implementation of a process improvement. Move to `process-framework-local/state-tracking/temporary/old` after all phases are complete.

## Improvement Overview

- **Improvement Name**: IMP-387 Script Parameter Check
- **Source IMP(s)**: [IMP-XXX — link to process-improvement-tracking.md entry]
- **Source Feedback**: [Link to Tools Review summary or feedback form that identified this improvement]
- **Scope**: Add check-parameters-first instruction to CLAUDE.md, script-development-quick-reference.md, and task definitions with variable-parameter script calls

## Affected Components

| Component Type | Name | Current State | Planned Change | Priority |
| -------------- | ---- | ------------- | -------------- | -------- |
| Script         | [script-name.ps1] | [Description of current behavior] | [What changes] | [HIGH/MEDIUM/LOW] |
| Template       | [template-name.md] | [Description of current state] | [What changes] | [HIGH/MEDIUM/LOW] |
| Guide          | [guide-name.md] | [Description of current state] | [What changes] | [HIGH/MEDIUM/LOW] |
| Task Def       | [task-name.md] | [Description of current state] | [What changes] | [HIGH/MEDIUM/LOW] |

## Implementation Roadmap

### Phase 1: Problem Analysis & Solution Design (Session 1)

**Priority**: HIGH - Must complete before implementation begins

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

### Phase 2: Implementation & Testing (Session 2)

**Priority**: HIGH - Core implementation work

- [ ] **Implement changes**: Apply approved approach incrementally
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
  - **Changes made**: [List of specific changes]

- [ ] **Test changes**: Verify implementation works correctly
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
  - **Test method**: [How changes were validated — e.g., -WhatIf, manual test, grep verification]
  - **Test results**: [Summary of results]

- [ ] **CHECKPOINT**: Review implementation with human partner
  - **Status**: [NOT_STARTED/APPROVED/REJECTED]
  - **Outcome**: [Approval notes or revision requests]

### Phase 3: Documentation & Integration (Session 3)

**Priority**: MEDIUM - Needed for complete integration

- [ ] **Update linked documents**: Update guides, task definitions, context maps that reference changed components
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
  - **Documents updated**: [List of files updated]

- [ ] **Update documentation map**: Add/update entries in PF-documentation-map.md if new artifacts were created
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED/SKIPPED]
  - **Reason for skip**: [If skipped — e.g., no new artifacts created]

- [ ] **Log tool change**: Record modification in feedback database
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
  - **Command**: `python process-framework/scripts/feedback_db.py log-change --tool <TOOL_DOC_ID> --date <YYYY-MM-DD> --imp <IMP-XXX> --description "<what changed>"`

### Phase 4: Validation & Completion (Session 4)

**Priority**: MEDIUM - Final validation and tracking updates

- [ ] **Final checkpoint**: Get human approval on complete solution
  - **Status**: [NOT_STARTED/APPROVED/REJECTED]

- [ ] **Update process-improvement-tracking.md**: Mark improvement as Completed
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
  - **Command**: `Update-ProcessImprovement.ps1 -ImprovementId "IMP-XXX" -NewStatus "Completed" -Impact "HIGH|MEDIUM|LOW" -ValidationNotes "What was done."`

- [ ] **Complete feedback form**: Submit feedback for PF-TSK-009
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]

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

This temporary state file can be moved to `process-framework-local/state-tracking/temporary/old` when:

- [ ] All implementation phases are complete
- [ ] All affected components are updated and tested
- [ ] Process improvement tracking is updated (Completed status)
- [ ] Linked documents are updated
- [ ] Feedback form is completed

## Notes and Decisions

### Key Decisions Made

- [Decision 1]: [Rationale]

### Implementation Notes

- [Note 1]
