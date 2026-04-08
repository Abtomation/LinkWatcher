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

> **⚠️ TEMPORARY FILE**: This file tracks implementation of a rename/move structure change. Move to `process-framework-local/state-tracking/temporary/old` after all changes are validated.

## Structure Change Overview
- **Change Name**: [Change Name]
- **Change ID**: [To be assigned - SC-XXX format]
- **Change Type**: Rename
- **Scope**: [Brief description of what's being changed]
- **Expected Completion**: [YYYY-MM-DD]

## File Mapping

| Current Path | New Path | Notes |
|-------------|----------|-------|
| [current-path] | [new-path] | [notes] |

## Affected References

Files that reference the renamed paths (LinkWatcher handles markdown links automatically):

| File | Reference Type | Auto-Updated | Manual Update Needed |
|------|---------------|--------------|---------------------|
| [file-path] | [link/import/config] | [Yes/No] | [Description if needed] |

## Implementation Roadmap

### Phase 1: Preparation (Session 1)
- [ ] **Document all renames** in File Mapping table above
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
- [ ] **Identify non-auto-updated references** (scripts, configs, non-markdown links)
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
- [ ] **Checkpoint**: Present rename plan to human partner for approval
  - **Status**: [NOT_STARTED/COMPLETED]

### Phase 2: Execution & Cleanup (Session 1-2)
- [ ] **Execute renames**: Move/rename files (LinkWatcher updates markdown links automatically)
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
- [ ] **Update non-auto-updated references**: Fix scripts, configs, non-markdown references
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
- [ ] **Validate**: Grep for old paths, confirm no stale references remain
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

- [ ] **Documentation Map**: Update with renamed paths
  - **Status**: [PENDING/COMPLETED]
- [ ] **Process Improvement Tracking**: Record completion if IMP-linked
  - **Status**: [PENDING/COMPLETED]

## Completion Criteria

This file can be archived to `state-tracking/temporary/old/` when:

- [ ] All renames executed
- [ ] All references updated (grep confirms no stale paths)
- [ ] Documentation Map updated
- [ ] Feedback form completed
