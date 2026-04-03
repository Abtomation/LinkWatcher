---
id: PD-STA-059
type: Document
category: General
version: 1.0
created: 2026-03-18
updated: 2026-03-18
change_name: rename-manual-testing-to-e2e-acceptance-testing
---

# Structure Change State: Rename Manual-Testing to E2E Acceptance Testing

> **⚠️ TEMPORARY FILE**: This file tracks multi-session implementation of structure change. Move to `process-framework/state-tracking/temporary/old` after all changes are implemented and validated.

## Structure Change Overview
- **Change Name**: Rename Manual-Testing to E2E Acceptance Testing
- **Change ID**: SC-007
- **Proposal Document**: (embedded in this state file — lightweight proposal)
- **Change Type**: Directory Reorganization
- **Scope**: Rename `manual-testing` → `e2e-acceptance-testing` across directories, scripts, task definitions, guides, templates, ID registry, and all content references
- **Rationale**: Current name describes *how* tests are run (manually). New name describes *why* they exist (end-to-end acceptance validation of the full reactive loop). The tests verify LinkWatcher's core value proposition: a human moves a file → links update automatically.
- **Expected Completion**: 2026-04-01

## Affected Components Analysis

### Templates Affected

| Template | Location | Change Required | Priority | Impact Level |
|----------|----------|----------------|----------|--------------|
| manual-test-case-template.md | templates/03-testing/ | Rename file + update all "manual test" → "E2E acceptance test" references | HIGH | BREAKING |
| manual-master-test-template.md | templates/03-testing/ | Rename file + update MT-GRP references and descriptive text | HIGH | BREAKING |

### Content Files Affected

| File Type | Count | Location Pattern | Migration Complexity | Notes |
|-----------|-------|------------------|---------------------|-------|
| Task definitions | 2 | process-framework/tasks/03-testing | COMPLEX | PF-TSK-069, PF-TSK-070 — rename files + extensive content updates |
| Guides | 3 | process-framework/guides/03-testing | COMPLEX | Customization guide, test infrastructure guide, test implementation guide |
| Context maps | 2 | visualization/context-maps/03-testing/ | MODERATE | Rename files + update titles and component references |
| State tracking | 2 | state-tracking/permanent/ | MODERATE | test-tracking.md, feature-tracking.md — MT-GRP/MT references |
| Documentation map | 1 | process-framework/ | COMPLEX | 8+ entry updates, section headers, script descriptions |
| process-framework/ai-tasks.md | 1 | root | MODERATE | Task names, descriptions, workflow references |
| README.md | 1 | root | SIMPLE | Test documentation section |
| Test specs | 1 | test/specifications/ | SIMPLE | test-spec-4-1-1 references |
| TDD/FDD docs | 2 | doc/ | SIMPLE | Feature 4.1.1 test suite docs |
| Audit reports | 1 | test/audits/ | SIMPLE | audit-report-2-1-1 reference |
| Low-impact refs | ~15 | various | SIMPLE | Scattered "manual test" mentions |
| Archive files | ~10 | feedback/archive/, state-tracking/old/ | NONE | Leave as historical records |

### Infrastructure Components

| Component Type | Name | Location | Change Required | Priority |
|----------------|------|----------|----------------|----------|
| Directory | test/manual-testing/ | test/ | Rename → test/e2e-acceptance-testing/ | CRITICAL |
| Directory | scripts/test/manual-testing/ | process-framework/scripts/test | Rename → scripts/test/e2e-acceptance-testing/ | CRITICAL |
| Script | New-ManualTestCase.ps1 | scripts/file-creation/03-testing/ | Rename → New-E2EAcceptanceTestCase.ps1 + update all internal paths/references | HIGH |
| Script | Run-ManualTest.ps1 | scripts/test/manual-testing/ | Rename → Run-E2EAcceptanceTest.ps1 + update internal paths | HIGH |
| Script | Setup-TestEnvironment.ps1 | scripts/test/manual-testing/ | Update internal path references | MEDIUM |
| Script | Verify-TestResult.ps1 | scripts/test/manual-testing/ | Update internal path references | MEDIUM |
| Script | Update-TestExecutionStatus.ps1 | scripts/test/manual-testing/ | Update internal path references | MEDIUM |
| Module | TestTracking.psm1 | scripts/Common-ScriptHelpers/ | Update MT-/MT-GRP ID handling, path patterns | HIGH |
| Registry | id-registry.json | doc/ | Rename MT → E2E, MT-GRP → E2E-GRP prefixes + update directory paths | HIGH |
| Config | .gitignore | root | Update manual-testing workspace/results paths | LOW |

## Migration Strategy

### Migration Approach
- **Strategy Type**: Phased (infrastructure first, then content, then cleanup)
- **Rollback Strategy**: LinkWatcher will handle most link updates automatically when directories are moved. Git history preserves all previous state. No destructive operations involved.
- **Backup Plan**: Git working tree already tracks all files. No additional backups needed beyond normal git workflow.

### File Mapping — Directories

| Current Structure | New Structure | Migration Method |
|-------------------|---------------|------------------|
| `test/manual-testing/` | `test/e2e-acceptance-testing/` | Directory rename (LinkWatcher handles links) |
| `test/manual-testing/templates/` | `test/e2e-acceptance-testing/templates/` | Included in parent rename |
| `scripts/test/manual-testing/` | `scripts/test/e2e-acceptance-testing/` | Directory rename |
| `MT-001-*`, `MT-002-*`, etc. | `E2E-001-*`, `E2E-002-*`, etc. | Directory rename per test case |

### File Mapping — Key Renames

| Current Name | New Name | Migration Method |
|--------------|----------|------------------|
| `New-ManualTestCase.ps1` | `New-E2EAcceptanceTestCase.ps1` | Rename + internal update |
| `Run-ManualTest.ps1` | `Run-E2EAcceptanceTest.ps1` | Rename + internal update |
| `manual-test-case-creation-task.md` | `e2e-acceptance-test-case-creation-task.md` | Rename + content update |
| `manual-test-execution-task.md` | `e2e-acceptance-test-execution-task.md` | Rename + content update |
| `manual-test-case-customization-guide.md` | `e2e-acceptance-test-case-customization-guide.md` | Rename + content update |
| `manual-test-case-template.md` | `e2e-acceptance-test-case-template.md` | Rename + content update |
| `manual-master-test-template.md` | `e2e-acceptance-master-test-template.md` | Rename + content update |
| `manual-test-case-creation-map.md` | `e2e-acceptance-test-case-creation-map.md` | Rename + content update |
| `manual-test-execution-map.md` | `e2e-acceptance-test-execution-map.md` | Rename + content update |

### ID Prefix Mapping

| Current Prefix | New Prefix | Current Description | New Description |
|---------------|------------|--------------------|-----------------|
| `MT` | `E2E` | Manual Testing - Test Cases | E2E Acceptance Testing - Test Cases |
| `MT-GRP` | `E2E-GRP` | Manual Testing - Test Groups | E2E Acceptance Testing - Test Groups |

## Implementation Roadmap

> **Delegation Tracking**: Each work item includes a **Delegated To** field. PF-TSK-014 orchestrates the overall change but delegates specialized work (task creation, template development, script development) to their respective tasks/processes. See the delegation table in the [Structure Change Task](../../../tasks/support/structure-change-task.md) for the full mapping.

### Phase 1: Preparation & Decisions (Session 1)
**Priority**: HIGH - Must complete before any changes

- [x] **Impact Assessment**: Full impact analysis across all file categories
  - **Status**: COMPLETED
  - **Delegated To**: PF-TSK-014 direct
  - **Result**: ~50+ active files affected, ~10 archive files (leave as-is), 2 directories to rename, 6 scripts to update, 2 ID prefixes to rename

- [x] **Key Decisions**: All resolved — human approved 2026-03-18
  - **Status**: COMPLETED
  - **Decisions confirmed**:
    1. ID prefix rename: MT/MT-GRP → E2E/E2E-GRP — **YES**
    2. Test group directory names: keep descriptive names as-is — **YES** (only parent changes)
    3. Archive files: leave with original names as historical records — **YES**

### Phase 2: Infrastructure — ID Registry + Scripts (Session 2)
**Priority**: HIGH - Update infrastructure before content

- [x] **ID Registry Update**: Rename MT/MT-GRP → E2E/E2E-GRP in id-registry.json
  - **Status**: COMPLETED
  - **Changes**: Renamed prefix keys, updated descriptions, updated directory paths

- [x] **TestTracking.psm1 Update**: Update ID handling in shared module
  - **Status**: COMPLETED
  - **Changes**: ValidateSet "Manual Group"/"Manual Case" → "E2E Group"/"E2E Case", comment updates

- [x] **Script Renames + Updates**: Rename and update all PowerShell scripts
  - **Status**: COMPLETED
  - **Scripts completed**: New-ManualTestCase.ps1 → New-E2EAcceptanceTestCase.ps1, Run-ManualTest.ps1 → Run-E2EAcceptanceTest.ps1, Setup-TestEnvironment.ps1 (paths), Verify-TestResult.ps1 (paths), Update-TestExecutionStatus.ps1 (paths + match patterns)

- [x] **Verify scripts work**: Ran New-E2EAcceptanceTestCase.ps1 with -WhatIf — correctly assigns E2E-005, looks for renamed template
  - **Status**: COMPLETED
  - **Note**: Only expected failure is template file not yet renamed (Phase 3)

### Phase 3: Directory Renames + Templates (Session 3)
**Priority**: HIGH - Physical directory moves, let LinkWatcher handle links

- [x] **Rename test/manual-testing/ → test/e2e-acceptance-testing/**
  - **Status**: COMPLETED

- [x] **Rename scripts/test/manual-testing/ → scripts/test/e2e-acceptance-testing/**
  - **Status**: COMPLETED

- [x] **Rename MT-* test case directories → E2E-***
  - **Status**: COMPLETED
  - **Scope**: MT-001→E2E-001, MT-002→E2E-002, MT-003→E2E-003, MT-004→E2E-004 (templates + workspace)

- [x] **Rename template files**: → e2e-acceptance-test-case-template.md, e2e-acceptance-master-test-template.md
  - **Status**: COMPLETED

- [x] **Update template content**: Frontmatter, placeholders, help text updated in both templates
  - **Status**: COMPLETED

- [x] **Update test case content**: All 7 test-case.md and master-test.md files updated (MT-→E2E-, MT-GRP→E2E-GRP)
  - **Status**: COMPLETED

- [x] **Update .gitignore**: No entries to update (no manual-testing paths present)
  - **Status**: COMPLETED (N/A)

### Phase 4: Task Definitions + Guides + Content (Session 4)
**Priority**: HIGH - Update all documentation content

- [x] **Rename + update task definitions**: PF-TSK-069 and PF-TSK-070
  - **Status**: COMPLETED
  - **Files**: e2e-acceptance-test-case-creation-task.md, e2e-acceptance-test-execution-task.md

- [x] **Rename + update guide**: e2e-acceptance-test-case-customization-guide.md
  - **Status**: COMPLETED

- [x] **Update test-infrastructure-guide.md**: All references updated
  - **Status**: COMPLETED

- [x] **Rename + update context maps**: 2 context map files renamed and updated
  - **Status**: COMPLETED
  - **Files**: e2e-acceptance-test-case-creation-map.md, e2e-acceptance-test-execution-map.md

- [x] **Update documentation-map.md**: All section headers, links, descriptions updated (15 edits)
  - **Status**: COMPLETED

- [x] **Update ai-tasks.md**: Task names and descriptions updated (2 table rows)
  - **Status**: COMPLETED

- [x] **Update state tracking files**: test-tracking.md fully updated (IDs, type labels, links, instructions)
  - **Status**: NOT_STARTED

### Phase 5: Low-Impact Content + Validation + Cleanup (Session 5)
**Priority**: HIGH - Sweep remaining files and validate

- [x] **Update low-impact content files**: README.md, audit reports (2), bug-tracking.md, test_procedures.md
  - **Status**: COMPLETED

- [x] **Run Validate-StateTracking.ps1**: 0 errors, 12 pre-existing warnings (unrelated)
  - **Status**: COMPLETED

- [x] **Grep sweep**: Zero MT- references in *.md/*.ps1/*.psm1/*.json/*.yaml files. Zero manual-testing path references.
  - **Status**: COMPLETED

- [x] **Verify LinkWatcher log**: LinkWatcher auto-updated most link paths; one manual fix needed (MT-001 path in test-tracking.md)
  - **Status**: COMPLETED

- [x] **Update documentation map**: Already completed in Phase 4
  - **Status**: COMPLETED

- [ ] **Archive this state file**: Move to state-tracking/temporary/old/
  - **Status**: PENDING (after human confirms completion)

- [ ] **Feedback form**: Complete feedback form for PF-TSK-014
  - **Status**: PENDING

## Session Tracking

### Session 1: 2026-03-18
**Focus**: Preparation — Impact analysis, state file creation, decisions
**Completed**:
- Impact analysis across all file categories (~50+ active files, 2 directories, 6 scripts, 2 ID prefixes)
- State file created (PF-STA-059) and customized with actual scope
- Key decisions proposed for human review

**Issues/Blockers**:
- None

**Next Session Plan**:
- ~~Phase 2: ID registry + script updates~~ (completed same session)

### Session 1 (continued): Phase 2 — Infrastructure
**Focus**: ID registry + script renames and updates
**Completed**:
- id-registry.json: MT/MT-GRP → E2E/E2E-GRP (keys, descriptions, directory paths)
- TestTracking.psm1: ValidateSet updated, comment references
- New-ManualTestCase.ps1 → New-E2EAcceptanceTestCase.ps1 (renamed + all internal refs)
- Run-ManualTest.ps1 → Run-E2EAcceptanceTest.ps1 (renamed + all internal refs)
- Setup-TestEnvironment.ps1, Verify-TestResult.ps1, Update-TestExecutionStatus.ps1 (path refs + patterns)
- Verified with -WhatIf: script correctly assigns E2E-005 and references new paths

**Issues/Blockers**:
- None

**Next Session Plan**:
- ~~Phase 3: Directory renames + template file renames/updates~~ (completed same session)

### Session 1 (continued): Phase 3 — Directory Renames + Templates
**Focus**: Physical directory/file renames, template content updates
**Completed**:
- test/manual-testing/ → test/e2e-acceptance-testing/ (full tree)
- scripts/test/manual-testing/ → scripts/test/e2e-acceptance-testing/
- MT-001→E2E-001, MT-002→E2E-002, MT-003→E2E-003, MT-004→E2E-004 (templates + workspace)
- Template files renamed: e2e-acceptance-test-case-template.md, e2e-acceptance-master-test-template.md
- Template content updated (frontmatter, placeholders, help text)
- All 7 test-case.md and master-test.md files updated (MT-→E2E-, MT-GRP→E2E-GRP)
- LinkWatcher confirmed processing renames

**Issues/Blockers**:
- None

**Next Session Plan**:
- ~~Phase 4: Task definitions + guides + documentation content updates~~ (completed same session)

### Session 1 (continued): Phase 4 — Task Definitions + Guides + Content
**Focus**: Update all documentation content files
**Completed**:
- Task definitions renamed + updated: PF-TSK-069, PF-TSK-070
- Guide renamed + updated: e2e-acceptance-test-case-customization-guide.md
- test-infrastructure-guide.md fully updated
- 2 context maps renamed + updated
- PF-documentation-map.md updated (15 edits)
- process-framework/ai-tasks.md updated (2 table rows)
- test-tracking.md fully updated (IDs, type labels, links, process instructions)

**Issues/Blockers**:
- LinkWatcher auto-updated some link paths but missed one (MT-001 in test-tracking.md link target) — fixed manually

**Next Session Plan**:
- Phase 5: Low-impact content sweep + validation + cleanup

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

This temporary state file can be moved to `process-framework/state-tracking/temporary/old` when:

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
- **Rename rationale**: "Manual testing" describes *how* tests run; "E2E acceptance testing" describes *why* they exist — validating the full reactive user workflow
- **ID prefix**: MT/MT-GRP → E2E/E2E-GRP (pending human approval)
- **Test group directories**: Keep descriptive names (e.g., `powershell-parser-patterns/`) — only parent directory changes
- **Archive files**: Leave with original names as historical records — no retroactive renaming

### Implementation Notes
- LinkWatcher will handle most link updates automatically when directories are renamed
- Scripts need manual internal path updates — LinkWatcher doesn't modify PowerShell code
- Content search-replace needs care to avoid false positives (e.g., "manual" in unrelated contexts)

### Future Considerations
- After rename, assess which features need new E2E test cases (the original discussion that led to this rename)

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
