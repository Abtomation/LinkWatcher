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

> **⚠️ TEMPORARY FILE**: This file tracks implementation of a content update structure change. Move to `doc/process-framework/state-tracking/temporary/old/` after all changes are validated.

## Structure Change Overview
- **Change Name**: [Change Name]
- **Change ID**: [To be assigned - SC-XXX format]
- **Change Type**: Content Update
- **Scope**: [Brief description of what's being changed]
- **Expected Completion**: [YYYY-MM-DD]

## Content Changes

### Change Description
[Describe the content changes: what text/sections are being updated, added, or removed and why]

### Affected Files
Files requiring content updates:

| File | Change Required | Priority | Status |
|------|----------------|----------|--------|
| [file-path] | [Description of change] | [HIGH/MEDIUM/LOW] | [PENDING/DONE] |

### Non-File Updates
Scripts, configs, or other infrastructure needing updates:

| Component | Change Required | Status |
|-----------|----------------|--------|
| [component] | [Description] | [PENDING/DONE] |

## Implementation Roadmap

### Phase 1: Preparation (Session 1)
- [ ] **Identify all affected files** (grep for patterns, review references)
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
- [ ] **Document changes** in Affected Files table above
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
- [ ] **Checkpoint**: Present change plan to human partner for approval
  - **Status**: [NOT_STARTED/COMPLETED]

### Phase 2: Execution & Validation (Session 1-2)
- [ ] **Apply content changes**: Update files per the Affected Files table
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
- [ ] **Update non-file components**: Fix scripts, configs if needed
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
- [ ] **Validate**: Grep for old patterns, confirm no stale content remains
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
- [ ] **Update documentation**: Update Documentation Map and any affected guides
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]

## Session Tracking

### Session 1: [YYYY-MM-DD]
**Focus**: Preparation & Execution
**Completed**:
- [List completed items]

**Issues/Blockers**:
- [List any issues encountered]

**Next Session Plan**:
- [Plan for next session, if needed]

## State File Updates Required

- [ ] **Documentation Map**: Update if document names/locations changed
  - **Status**: [PENDING/COMPLETED]
- [ ] **Process Improvement Tracking**: Record completion if IMP-linked
  - **Status**: [PENDING/COMPLETED]

## Completion Criteria

This file can be archived to `state-tracking/temporary/old/` when:

- [ ] All content changes applied
- [ ] Validation confirms no stale patterns remain
- [ ] Documentation updated if needed
- [ ] Feedback form completed
