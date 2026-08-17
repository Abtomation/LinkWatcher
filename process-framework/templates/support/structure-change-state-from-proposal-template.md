---
id: PF-TEM-104
type: Process Framework
category: Template
version: 1.0
created: [CREATED-DATE]
updated: [UPDATED-DATE]
change_name: [CHANGE-NAME]
variant_group: structure-change-state-templates
variant_siblings:
  - structure-change-state-template.md
  - structure-change-state-content-update-template.md
  - structure-change-state-framework-extension-template.md
  - structure-change-state-rename-template.md
creates_document_type: Process Framework
creates_document_category: State Tracking
description: "Lightweight execution-tracking template for proposal-backed structure changes (phase checklist + session log only)"
---

# Structure Change State: [Change Name]

> **Lightweight state file**: This change has a detailed proposal document. This file tracks **execution progress only** — see the proposal for rationale, affected files, and migration strategy.

## Structure Change Overview
- **Change Name**: [Change Name]
- **Change ID**: [The PF-STA-NNN ID assigned to this state file]
- **Proposal Document**: [Link to the proposal-of-record — a structure-change-proposal doc, or an owner-approved analysis (a Framework Evaluation finding / an approved IMP's analysis) inside a state or eval file]
- **Change Type**: [Template Update/Directory Reorganization/Metadata Structure/Documentation Architecture/Content Update]
- **Scope**: [Brief description of what's being changed]

## Implementation Roadmap

> **Cross-check reminder**: Verify every file in the proposal's affected files table appears in at least one phase checklist below.

> **Copy the proposal's phases here.** Each phase becomes a `### Phase N: <Name>` subsection containing checklist items in this shape:
>
> ```
> - [ ] **<Step description>**
>   - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
> ```
>
> The proposal owns phase shape, count, and names — this file just tracks execution against them.

## Session Tracking

### Session 1: [YYYY-MM-DD]
**Focus**: [Phase focus]
**Completed**:
- [List completed items]

**Issues/Blockers**:
- [List any issues encountered]

**Next Session Plan**:
- [Plan for next session]

## State File Updates Required

- [ ] **Documentation Map**: Update if document names/locations changed
  - **Status**: [PENDING/COMPLETED]
- [ ] **Process Improvement Tracking**: Record completion if IMP-linked
  - **Status**: [PENDING/COMPLETED]

## Completion Criteria

This file can be archived to `state-tracking/temporary/old/` when:

- [ ] All phases completed successfully
- [ ] All proposal-listed files addressed
- [ ] Documentation updated
- [ ] Feedback form completed
