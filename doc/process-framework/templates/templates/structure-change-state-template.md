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

> **⚠️ TEMPORARY FILE**: This file tracks multi-session implementation of structure change. Move to `doc/process-framework/state-tracking/temporary/old/` after all changes are implemented and validated.

## Structure Change Overview
- **Change Name**: [Change Name]
- **Change ID**: [To be assigned - SC-XXX format]
- **Proposal Document**: [Link to structure-change-proposal document]
- **Change Type**: [Template Update/Directory Reorganization/Metadata Structure/Documentation Architecture]
- **Scope**: [Brief description of what's being changed]
- **Expected Completion**: [YYYY-MM-DD]

## Affected Components Analysis

### Templates Affected
List all templates that need updates:

| Template | Location | Change Required | Priority | Impact Level |
|----------|----------|----------------|----------|--------------|
| [template-name.md] | [path] | [Description of change] | [HIGH/MEDIUM/LOW] | [BREAKING/COMPATIBLE] |

### Content Files Affected
List all content files that need migration:

| File Type | Count | Location Pattern | Migration Complexity | Notes |
|-----------|-------|------------------|---------------------|-------|
| [file-type] | [~X files] | [path-pattern] | [SIMPLE/MODERATE/COMPLEX] | [Migration notes] |

### Infrastructure Components
List scripts, guides, and other infrastructure affected:

| Component Type | Name | Location | Change Required | Priority |
|----------------|------|----------|----------------|----------|
| Script | [script-name.ps1] | [path] | [Description] | [HIGH/MEDIUM/LOW] |
| Guide | [guide-name.md] | [path] | [Description] | [HIGH/MEDIUM/LOW] |
| State File | [state-file.md] | [path] | [Description] | [HIGH/MEDIUM/LOW] |

## Migration Strategy

### Migration Approach
- **Strategy Type**: [Big Bang/Phased/Pilot-First]
- **Rollback Strategy**: [Description of how to revert changes]
- **Backup Plan**: [What gets backed up and where]

### File Mapping
Document the before/after structure:

| Current Structure | New Structure | Migration Method |
|-------------------|---------------|------------------|
| [current-pattern] | [new-pattern] | [manual/script/tool] |

## Implementation Roadmap

### Phase 1: Preparation & Proposal (Session 1)
**Priority**: HIGH - Must complete before any changes

- [ ] **Structure Change Proposal**: Create comprehensive proposal document
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
  - **Dependencies**: Change requirements identified, impact analysis completed
  - **Template**: [Structure Change Proposal Template](structure-change-proposal-template.md)
  - **Location**: `doc/process-framework/state-tracking/temporary/[change-name]-structure-change-proposal.md`
  - **Notes**: Detailed proposal with rationale, affected files, migration strategy

- [ ] **Backup Creation**: Create backups of all files to be modified
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
  - **Dependencies**: Affected files identified
  - **Backup Location**: [Specify backup directory or method]
  - **Notes**: Ensure rollback capability before making any changes

- [ ] **Impact Assessment**: Document full impact of proposed changes
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
  - **Dependencies**: Proposal completed, affected components identified
  - **Assessment Areas**: Templates, content files, cross-references, automation scripts
  - **Notes**: Identify all downstream effects and dependencies

### Phase 2: Infrastructure Updates (Session 2)
**Priority**: HIGH - Update supporting infrastructure first

- [ ] **Template Updates**: Update or create new templates using established processes
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
  - **Dependencies**: Proposal approved, new structure defined
  - **Process**: Use [New-Template.ps1](../../scripts/file-creation/New-Template.ps1) for new templates, follow [Template Development Guide](../../guides/guides/template-development-guide.md) for updates
  - **Notes**: Update templates before migrating content to ensure consistency

- [ ] **Script Updates**: Update or create automation scripts
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
  - **Dependencies**: Template updates completed
  - **Process**: Use [Document Creation Script Development Guide](../../guides/guides/document-creation-script-development-guide.md)
  - **Notes**: Ensure scripts work with new structure before content migration

- [ ] **Guide Updates**: Update documentation guides
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
  - **Dependencies**: Templates and scripts updated
  - **Process**: Use [New-Guide.ps1](../../scripts/file-creation/New-Guide.ps1) for new guides
  - **Notes**: Update guides to reflect new structure and processes

### Phase 3: Pilot Implementation (Session 3)
**Priority**: HIGH - Test changes on subset before full migration

- [ ] **Pilot File Selection**: Choose representative files for pilot testing
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
  - **Dependencies**: Infrastructure updates completed
  - **Pilot Criteria**: [Specify how pilot files are selected]
  - **Pilot Size**: [X files representing Y% of total affected files]
  - **Notes**: Select files that represent different complexity levels and use cases

- [ ] **Pilot Migration**: Migrate pilot files to new structure
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
  - **Dependencies**: Pilot files selected, migration tools ready
  - **Migration Method**: [Manual/Script/Tool-assisted]
  - **Notes**: Document any issues or unexpected complications

- [ ] **Pilot Validation**: Test pilot files thoroughly
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
  - **Dependencies**: Pilot migration completed
  - **Validation Criteria**: [List specific tests and checks]
  - **Success Metrics**: [Define what constitutes successful pilot]
  - **Notes**: Validate functionality, cross-references, and integration

### Phase 4: Full Migration (Session 4)
**Priority**: HIGH - Execute full migration based on pilot learnings

- [ ] **Migration Plan Refinement**: Update migration approach based on pilot results
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
  - **Dependencies**: Pilot validation completed successfully
  - **Refinements**: [List changes to migration approach based on pilot]
  - **Notes**: Incorporate lessons learned from pilot implementation

- [ ] **Batch Migration**: Migrate remaining files in planned batches
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
  - **Dependencies**: Migration plan refined, pilot successful
  - **Batch Strategy**: [Describe batching approach - by type, priority, etc.]
  - **Progress Tracking**: [Method for tracking migration progress]
  - **Notes**: Execute migration systematically with progress checkpoints

- [ ] **Cross-Reference Updates**: Update all cross-references and links
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
  - **Dependencies**: File migration completed
  - **Update Method**: [Manual/LinkWatcher/Script]
  - **Validation**: [How to verify all links are updated correctly]
  - **Notes**: Ensure all internal references point to new locations

### Phase 5: Validation & Cleanup (Session 5)
**Priority**: HIGH - Ensure changes are complete and system is stable

- [ ] **Comprehensive Testing**: Test entire system with new structure
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
  - **Dependencies**: Full migration completed
  - **Test Areas**: [List all areas to test - functionality, links, scripts, etc.]
  - **Success Criteria**: [Define what constitutes successful testing]
  - **Notes**: Comprehensive validation of entire changed system

- [ ] **Documentation Updates**: Update system documentation
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
  - **Dependencies**: Testing completed successfully
  - **Updates Required**: [Documentation Map, guides, README files, etc.]
  - **Notes**: Ensure all documentation reflects new structure

- [ ] **Cleanup & Archival**: Clean up temporary files and archive migration artifacts
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
  - **Dependencies**: All changes validated and documented
  - **Cleanup Items**: [List temporary files, backup files, migration artifacts]
  - **Archive Location**: `doc/process-framework/state-tracking/temporary/old/`
  - **Notes**: Preserve historical record while cleaning up working directories

## Session Tracking

### Session 1: [YYYY-MM-DD]
**Focus**: Preparation & Proposal
**Completed**:
- [List completed items]

**Issues/Blockers**:
- [List any issues encountered]

**Next Session Plan**:
- [Plan for next session]

### Session 2: [YYYY-MM-DD]
**Focus**: Infrastructure Updates
**Completed**:
- [List completed items]

**Issues/Blockers**:
- [List any issues encountered]

**Next Session Plan**:
- [Plan for next session]

### Session 3: [YYYY-MM-DD]
**Focus**: Pilot Implementation
**Completed**:
- [List completed items]

**Issues/Blockers**:
- [List any issues encountered]

**Next Session Plan**:
- [Plan for next session]

### Session 4: [YYYY-MM-DD]
**Focus**: Full Migration
**Completed**:
- [List completed items]

**Issues/Blockers**:
- [List any issues encountered]

**Next Session Plan**:
- [Plan for next session]

### Session 5: [YYYY-MM-DD]
**Focus**: Validation & Cleanup
**Completed**:
- [List completed items]

**Issues/Blockers**:
- [List any issues encountered]

**Next Session Plan**:
- [Plan for next session]

## Testing & Validation

### Test Cases
Document specific tests to validate the structure change:

| Test Case | Description | Expected Result | Actual Result | Status |
|-----------|-------------|----------------|---------------|--------|
| [TC-001] | [Test description] | [Expected outcome] | [Actual outcome] | [PASS/FAIL/PENDING] |

### Success Criteria
Define what constitutes successful completion:

- [ ] **Functional Criteria**:
  - [ ] All templates work correctly with new structure
  - [ ] All scripts function properly
  - [ ] All cross-references are valid
  - [ ] No broken links or missing files

- [ ] **Quality Criteria**:
  - [ ] New structure improves usability/maintainability
  - [ ] Documentation is clear and complete
  - [ ] Migration was completed without data loss
  - [ ] System performance is maintained or improved

### Issues & Resolutions
Track problems encountered and their solutions:

| Issue | Description | Impact | Resolution | Status |
|-------|-------------|--------|------------|--------|
| [ISS-001] | [Issue description] | [HIGH/MEDIUM/LOW] | [Resolution description] | [OPEN/RESOLVED] |

## Rollback Information

### Rollback Triggers
Conditions that would require rolling back the changes:

- [ ] **Critical Issues**:
  - [ ] Data loss or corruption
  - [ ] System functionality broken
  - [ ] Major performance degradation
  - [ ] Widespread link breakage

### Rollback Procedure
Step-by-step process to revert changes:

1. **Stop Current Work**: Halt any ongoing migration activities
2. **Restore Backups**: [Specific steps to restore from backups]
3. **Verify Restoration**: [Steps to verify rollback was successful]
4. **Update Documentation**: [Update tracking files to reflect rollback]
5. **Analyze Failure**: [Document what went wrong for future reference]

### Rollback Validation
How to verify rollback was successful:

- [ ] All original files restored correctly
- [ ] All functionality working as before
- [ ] No residual changes from migration attempt
- [ ] Documentation reflects current state

## State File Updates Required

Track which state files need updates as changes are implemented:

- [ ] **Documentation Map**: Update with structural changes
  - **Status**: [PENDING/COMPLETED]
  - **Changes**: [List changes to documentation organization]

- [ ] **Process Improvement Tracking**: Record structure improvement
  - **Status**: [PENDING/COMPLETED]
  - **Improvement**: [Description of process improvement achieved]

- [ ] **Template Registry**: Update template listings if applicable
  - **Status**: [PENDING/COMPLETED]
  - **Updates**: [List template changes]

## Completion Criteria

This temporary state file can be moved to `doc/process-framework/state-tracking/temporary/old/` when:

- [ ] All phases completed successfully
- [ ] All test cases pass
- [ ] All success criteria met
- [ ] All affected files migrated and validated
- [ ] All cross-references updated
- [ ] All documentation updated
- [ ] System functioning normally with new structure
- [ ] Cleanup completed
- [ ] Feedback forms completed for the structure change process

## Notes and Decisions

### Key Decisions Made
- [Decision 1]: [Rationale and impact]
- [Decision 2]: [Rationale and impact]

### Implementation Notes
- [Note 1]: [Important implementation detail]
- [Note 2]: [Lesson learned or best practice]

### Future Considerations
- [Consideration 1]: [Future improvement or consideration]
- [Consideration 2]: [Potential follow-up work]

## Metrics and Measurements

### Implementation Metrics
Track the progress and efficiency of the structure change:

| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| Files Migrated | [X files] | [Y files] | [ON_TRACK/BEHIND/AHEAD] |
| Migration Time | [X hours] | [Y hours] | [ON_TRACK/BEHIND/AHEAD] |
| Issues Encountered | [< X issues] | [Y issues] | [ACCEPTABLE/CONCERNING] |
| Test Pass Rate | [100%] | [Y%] | [PASS/FAIL] |

### Quality Metrics
Measure the success of the structure change:

| Quality Aspect | Before | After | Improvement |
|----------------|--------|-------|-------------|
| Usability Score | [X/10] | [Y/10] | [+/-Z] |
| Maintainability | [X/10] | [Y/10] | [+/-Z] |
| Consistency | [X/10] | [Y/10] | [+/-Z] |
| Documentation Clarity | [X/10] | [Y/10] | [+/-Z] |
