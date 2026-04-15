---
id: [DOCUMENT-ID]
type: Process Framework
category: Template
version: 1.0
created: [CREATED-DATE]
updated: [UPDATED-DATE]
change_name: [CHANGE-NAME]
---

# Structure Change State: [Change Name]

> **TEMPORARY FILE**: This file tracks multi-session implementation of a framework extension structure change. Move to `process-framework-local/state-tracking/temporary/old` after all changes are implemented and validated.

## Structure Change Overview
- **Change Name**: [Change Name]
- **Change ID**: [To be assigned - SC-XXX format]
- **Extension Concept**: [Link to framework-extension-concept document, if applicable]
- **Change Type**: Framework Extension
- **Scope**: [Brief description of what's being changed]
- **Expected Completion**: [YYYY-MM-DD]

## Affected Components Analysis

### New Artifacts
Artifacts to be created as part of this extension:

| Artifact Type | Name | Location | Script/Manual | Status |
|---------------|------|----------|---------------|--------|
| Template | [template-name.md] | [path] | [New-Template.ps1 / Manual] | [PENDING/DONE] |
| Script | [script-name.ps1] | [path] | [Manual] | [PENDING/DONE] |
| Guide | [guide-name.md] | [path] | [New-Guide.ps1 / Manual] | [PENDING/DONE] |

### Modified Artifacts
Existing files requiring updates:

| File | Change Required | Priority | Status |
|------|----------------|----------|--------|
| [file-path] | [Description of change] | [HIGH/MEDIUM/LOW] | [PENDING/DONE] |

### Infrastructure Updates
Registries, tracking files, and documentation maps requiring updates:

| Component | Change Required | Status |
|-----------|----------------|--------|
| PF-id-registry.json | [New prefix / counter update] | [PENDING/DONE] |
| PF-documentation-map.md | [New entries] | [PENDING/DONE] |
| [other tracking file] | [Description] | [PENDING/DONE] |

## Implementation Roadmap

### Phase 1: Preparation (Session 1)
- [ ] **Review extension concept**: Confirm scope and affected components
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
- [ ] **Complete affected components tables** above
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
- [ ] **Checkpoint**: Present plan to human partner for approval
  - **Status**: [NOT_STARTED/COMPLETED]

### Phase 2: Create & Modify Artifacts (Session 1-2)
- [ ] **Create new artifacts**: Templates, scripts, guides per New Artifacts table
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
- [ ] **Modify existing artifacts**: Updates per Modified Artifacts table
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
- [ ] **Update infrastructure**: Registries, tracking files, documentation maps
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]

### Phase 3: Validation & Cleanup (Session 2-3)
- [ ] **Validate changes**: Run relevant validation scripts, verify cross-references
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
- [ ] **Update documentation**: Documentation Map, affected guides
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
- [ ] **Cleanup**: Archive temporary files
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]

## Session Tracking

### Session 1: [YYYY-MM-DD]
**Focus**: Preparation & Artifact Creation
**Completed**:
- [List completed items]

**Issues/Blockers**:
- [List any issues encountered]

**Next Session Plan**:
- [Plan for next session]

### Session 2: [YYYY-MM-DD]
**Focus**: Remaining Artifacts & Validation
**Completed**:
- [List completed items]

**Issues/Blockers**:
- [List any issues encountered]

**Next Session Plan**:
- [Plan for next session, if needed]

## State File Updates Required

- [ ] **Documentation Map**: Add new artifacts
  - **Status**: [PENDING/COMPLETED]
- [ ] **Process Improvement Tracking**: Record completion if IMP-linked
  - **Status**: [PENDING/COMPLETED]

## Completion Criteria

This file can be archived to `state-tracking/temporary/old/` when:

- [ ] All new artifacts created
- [ ] All existing artifacts modified
- [ ] All infrastructure updated (registries, maps, tracking)
- [ ] Validation scripts pass
- [ ] Documentation updated
- [ ] Feedback form completed
