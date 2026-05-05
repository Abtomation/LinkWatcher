---
id: PF-TEM-071
type: Process Framework
category: Template
version: 1.0
created: 2026-04-09
updated: 2026-04-09
task_name: [TASK-NAME]
---

# Temporary Framework Extension State: [Task Name]

> **⚠️ TEMPORARY FILE**: This file tracks multi-session implementation of a framework extension (PF-TSK-026). Move to `process-framework-local/state-tracking/temporary/old` after all phases are complete.

## Extension Overview

- **Extension Name**: [Task Name]
- **Source Concept**: [Link to Framework Extension Concept document]
- **Source IMP(s)**: [IMP-XXX — link to process-improvement-tracking.md entry, if applicable]
- **Scope**: [Brief description of what will change]
- **Estimated Sessions**: [Number of sessions expected]

## Artifact Tracking

| Artifact | Type | Location | Creator Task | Updater Task(s) | Status |
|----------|------|----------|-------------|-----------------|--------|
| [artifact-name.md] | Template | [target path] | PF-TSK-026 | [tasks that update it] | NOT_STARTED |
| [script-name.ps1] | Script | [target path] | PF-TSK-026 | [tasks that update it] | NOT_STARTED |
| [guide-name.md] | Guide | [target path] | PF-TSK-026 | [tasks that update it] | NOT_STARTED |
| [task-name.md] | Task Def | [target path] | PF-TSK-001 | [tasks that update it] | NOT_STARTED |
| [context-map.md] | Context Map | [target path] | PF-TSK-026 | [tasks that update it] | NOT_STARTED |

**Status Legend**: NOT_STARTED | IN_PROGRESS | COMPLETED | DEFERRED

## Task Impact

Existing tasks affected by this extension:

| Task | ID | Change Required | Priority | Status |
|------|----|----|----------|--------|
| [Task Name] | PF-TSK-XXX | [What changes — new step, new reference, new output] | HIGH/MEDIUM/LOW | NOT_STARTED |

## Implementation Roadmap

> **One phase per calendar session.** Phase 2 / Phase 3 / mid-flight migrations should each
> get their own fresh session — see [framework-extension-task.md Phase 3](/process-framework/tasks/support/framework-extension-task.md#phase-3-multi-session-implementation)
> for rationale (checkpoint discipline + Session Tracking labeling consistency).

### Phase 1: Concept & Approval

**Priority**: HIGH — Must complete before implementation begins

- [ ] **Pre-concept analysis**: Study existing patterns, trace lifecycle, establish abstraction model
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
  - **Key findings**: [Summary]

- [ ] **Create concept document**: Use `New-FrameworkExtensionConcept.ps1`
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
  - **Concept ID**: [PF-PRO-XXX]

- [ ] **CHECKPOINT**: Present concept to human partner
  - **Status**: [NOT_STARTED/APPROVED/REJECTED]
  - **Outcome**: [Approval notes or revision requests]

### Phase 2: Artifact Creation

**Priority**: HIGH — Core implementation work

> Create artifacts in dependency order. Update the Artifact Tracking table as each artifact is completed.

- [ ] [Describe first artifact to create]
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]

- [ ] [Describe second artifact to create]
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]

- [ ] **CHECKPOINT**: Review created artifacts with human partner
  - **Status**: [NOT_STARTED/APPROVED/REJECTED]
  - **Outcome**: [Approval notes or revision requests]

### Phase 3: Integration & Task Updates

**Priority**: HIGH — Wire extension into existing framework

> Update existing tasks, registries, and documentation maps. Update the Task Impact table as each task is modified.

- [ ] [Describe task/registry update]
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]

- [ ] **Update documentation maps**: Add new artifacts to PF-documentation-map.md and/or PD-documentation-map.md
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]

- [ ] **Update ID registries**: Add new prefixes to PF-id-registry.json or PD-id-registry.json
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]

- [ ] **CHECKPOINT**: Review integration with human partner
  - **Status**: [NOT_STARTED/APPROVED/REJECTED]
  - **Outcome**: [Approval notes or revision requests]

### Phase 4: Finalization

**Priority**: MEDIUM — Testing, documentation, and completion

- [ ] **Test automation scripts**: Verify with `-WhatIf` and real invocations
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
  - **Test results**: [Summary]

- [ ] **Update process-improvement-tracking.md**: Mark source IMP(s) as Completed (if applicable)
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]

- [ ] **Log tool changes**: Record modifications in feedback database
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]

- [ ] **Complete feedback form**: Submit feedback for PF-TSK-026
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

- [ ] All artifacts in the Artifact Tracking table are COMPLETED or DEFERRED
- [ ] All task impacts in the Task Impact table are COMPLETED
- [ ] Documentation maps and ID registries are updated
- [ ] Automation scripts are tested and working
- [ ] Process improvement tracking is updated (if applicable)
- [ ] Feedback form is completed

## Notes and Decisions

### Key Decisions Made

- [Decision 1]: [Rationale]

### Implementation Notes

- [Note 1]
