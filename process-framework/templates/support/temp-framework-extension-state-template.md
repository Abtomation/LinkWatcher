---
id: PF-TEM-071
type: Process Framework
category: Template
version: 1.0
created: 2026-04-09
updated: 2026-04-09
task_name: [TASK-NAME]
description: "Template for tracking multi-session framework extension implementation with artifact tracking and task impact analysis (via New-TempTaskState.ps1 -Variant FrameworkExtension)"
---

# Temporary Framework Extension State: [Task Name]

> **⚠️ TEMPORARY FILE**: This file tracks multi-session implementation of a framework extension (PF-TSK-026). Move to `process-framework-central/state-tracking/temporary/old` after all phases are complete.

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

> **Default cadence: one phase per calendar session.** By default Phase 2 / Phase 3 /
> mid-flight migrations each get a fresh session; running a second phase in one session is
> allowed only under the documented waiver conditions. See
> [framework-extension-task.md Phase 3](../../tasks/support/framework-extension-task.md#phase-3-multi-session-implementation)
> for the waiver conditions, the phase-resumption naming convention, and the
> calendar-vs-roadmap session terminology.

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

> **Archive-split convention**: When this file exceeds ~800 lines, archive completed session logs to a sibling file named `<this-file-name>-session-archive.md`. Keep the most recent 2–3 sessions here for continuity context; move earlier sessions to the archive. Add a reference line below linking to the archive. See [Framework Extension Task Step 14](../../tasks/support/framework-extension-task.md) for the full procedure.

<!-- When sessions are archived, uncomment and update this line:
> **Archived sessions**: Sessions 1–N are in [<archive-file-name>.md](<relative-link>).
-->

> Add one entry per session as work proceeds — copy the block below for each new session.

### Session N

**Focus**: [Session focus]
**Completed**:

- [List completed items]

**Issues/Blockers**:

- [List any issues encountered]

**Next Session Plan**:

- [Plan for next session]

## Bug-Discovery Log

Record bugs and defects surfaced during implementation work — a test reveals a
counting defect in a helper module, a hardcoded path no longer resolves after a
structural change, a script's recovery handler dies before it can recover, etc.

**Convention: fix bugs inline.** When a bug is discovered mid-session, the
default is to fix it in the same session rather than defer it as a pin test
(assert-the-bug-now, flip-when-fixed), a follow-up IMP, or a "later cleanup"
entry. Write tests against correct behavior, after the fix.

**Exception**: If the fix would balloon session scope (e.g., a 30-site sweep
when the session goal is unrelated), surface the finding explicitly to the
human partner and let them choose scope rather than silently expand the
session. Document the scope shift in the relevant session log.

Each entry records what was found, where, and how it was resolved.

| ID | Severity | Surface | Description | Resolution |
|----|----------|---------|-------------|------------|
| BD-001 | [severity] | [module/function/script] | [what's wrong] | Session N: fixed inline / deferred per user direction |

## Completion Criteria

This temporary state file can be moved to `process-framework-central/state-tracking/temporary/old` when:

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
