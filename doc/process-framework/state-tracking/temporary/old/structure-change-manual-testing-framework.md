---
id: PF-STA-054
type: Document
category: General
version: 1.0
created: 2026-03-14
updated: 2026-03-15
change_name: manual-testing-framework
---

# Structure Change State: Manual Testing Framework

> **⚠️ TEMPORARY FILE**: This file tracks multi-session implementation of structure change. Move to `doc/process-framework/state-tracking/temporary/old/` after all changes are implemented and validated.

## Structure Change Overview

- **Change Name**: Manual Testing Framework
- **Change ID**: PF-STA-054
- **Proposal Document**: [Structure Change Proposal](/doc/process-framework/proposals/proposals/old/structure-change-manual-testing-proposal.md)
- **Change Type**: Documentation Architecture
- **Scope**: Introduce manual testing framework with concrete test cases, test environment management, and execution tracking. Modifies existing tasks, creates new tasks, adds templates/scripts, extends state tracking.
- **Expected Completion**: ~5 sessions

## Affected Components Analysis

### Templates Affected

| Template | Location | Change Required | Priority | Impact Level |
|----------|----------|----------------|----------|--------------|
| ../manual-test-case-template.md | NEW — `templates/templates/` | Create new template for ../test-case.md files | HIGH | N/A (new) |
| ../manual-master-test-template.md | NEW — `templates/templates/` | Create new template for group master tests | HIGH | N/A (new) |

### Content Files Affected

| File Type | Count | Location Pattern | Migration Complexity | Notes |
|-----------|-------|------------------|---------------------|-------|
| Task definitions (modified) | 5-7 | `tasks/*/` | MODERATE | Add manual test handover interfaces to PF-TSK-012, 006, 022, 068, 053 + review others |
| State tracking (modified) | 2 | `state-tracking/permanent/` | MODERATE | Rename test-implementation-tracking.md, add columns + statuses to ../feature-tracking.md |
| Task definitions (new) | 2 | `tasks/03-testing/` | SIMPLE | Manual Test Case Creation + Manual Test Execution |
| Directory structure (new) | 1 | `test/manual-testing/` | SIMPLE | Framework skeleton for manual test environment |

### Infrastructure Components

| Component Type | Name | Location | Change Required | Priority |
|----------------|------|----------|----------------|----------|
| Script (new) | ../Setup-TestEnvironment.ps1 | `scripts/testing/` | Create test environment setup script | HIGH |
| Script (new) | ../Verify-TestResult.ps1 | `scripts/testing/` | Create test result verification script | HIGH |
| Script (new) | ../Update-TestExecutionStatus.ps1 | `scripts/testing/` | Create status update automation | HIGH |
| State File (rename) | ../test-implementation-tracking.md → ../test-tracking.md | `state-tracking/permanent/` | Rename + extend with manual test columns | HIGH |
| State File (modify) | ../feature-tracking.md | `state-tracking/permanent/` | Add new Test Status values | MEDIUM |
| Task (modify) | PF-TSK-012 Test Specification Creation | `tasks/03-testing/` | Add manual test classification, UI doc review | HIGH |
| Task (modify) | PF-TSK-006 Bug Fixing | `tasks/06-maintenance/` | Add manual test handover interfaces | MEDIUM |
| Task (modify) | PF-TSK-022 Code Refactoring | `tasks/06-maintenance/` | Add manual test handover interfaces | MEDIUM |
| Task (modify) | PF-TSK-068 Feature Enhancement | `tasks/04-implementation/` | Add manual test handover interfaces | MEDIUM |
| Task (modify) | PF-TSK-053 Integration and Testing | `tasks/04-implementation/` | Add re-execution marking step | MEDIUM |
| Task (review) | PF-TSK-029 Foundation Feature Impl | `tasks/04-implementation/` | Review for manual test handover needs | LOW |
| Task (review) | PF-TSK-044 Feature Impl Planning | `tasks/04-implementation/` | Review for manual test planning step | LOW |
| Task (review) | PF-TSK-015 Release & Deployment | `tasks/07-deployment/` | Review for manual test gate requirement | LOW |
| Task (review) | PF-TSK-007 Code Review | `tasks/06-maintenance/` | Review for manual test check | LOW |

## Migration Strategy

### Migration Approach

- **Strategy Type**: Phased (5 sessions)
- **Rollback Strategy**: Git revert — all changes tracked in version control
- **Backup Plan**: Git provides full history; no separate backups needed

### File Mapping

| Current Structure | New Structure | Migration Method |
|-------------------|---------------|------------------|
| ../test-implementation-tracking.md | ../test-tracking.md (extended) | Rename + add columns via manual edit |
| ../feature-tracking.md Test Status legend | Same file, extended legend | Add new status entries |
| — | test/manual-testing/ skeleton | Create directories + README |
| — | scripts/testing/*.ps1 | Create new scripts |
| — | templates/templates/manual-*.md | Create via support/New-Template.ps1 |
| — | tasks/03-testing/manual-test-*.md | Create via support/New-Task.ps1 |

## Implementation Roadmap

### Phase 1: Preparation & Proposal (Session 1) ✅
**Priority**: HIGH — Must complete before any changes

- [x] **Structure Change Proposal**: Created comprehensive proposal document
  - **Status**: COMPLETED
  - **Location**: `/doc/process-framework/proposals/proposals/structure-change-manual-testing-proposal.md`

- [x] **State Tracking File**: Created this tracking file (PF-STA-054)
  - **Status**: COMPLETED

- [x] **Human Approval**: Proposal approved by human partner
  - **Status**: COMPLETED

### Phase 2: State Tracking Changes + PF-TSK-012 Modification (Session 2) ✅
**Priority**: HIGH — Foundation for all subsequent phases

- [x] **Rename ../test-implementation-tracking.md → test-tracking.md**
  - **Status**: COMPLETED
  - **Dependencies**: None
  - **Sub-tasks**:
    - [x] Rename file (done in session 1, content extended in session 2)
    - [x] Add Test Type column (Automated / Manual Group / Manual Case)
    - [x] Add Last Executed column
    - [x] Add manual test status legend (📋 Case Created, ✅ Passed, 🔴 Failed, 🔄 Needs Re-execution, ⬜ Not Created)
    - [x] Update all cross-references across framework — 13 files updated (TestTracking.psm1, FileOperations.psm1, 4 update scripts, Validate-StateTracking.ps1, test-audit-usage-guide.md, state-file-creation-guide.md, test-audit-map.md)
    - [x] Update ../Validate-StateTracking.ps1 and ../Validate-TestTracking.ps1 — both verified clean

- [x] **Extend ../feature-tracking.md Test Status legend**
  - **Status**: COMPLETED
  - **Dependencies**: None
  - **Sub-tasks**:
    - [x] Add `🔧 Automated Only` status
    - [x] Add `🔄 Re-testing Needed` status

- [x] **Modify PF-TSK-012 (Test Specification Creation)**
  - **Status**: COMPLETED (v1.3 → v1.4)
  - **Dependencies**: State tracking changes
  - **Sub-tasks**:
    - [x] Add step 3: Review UI documentation linked from feature tracking
    - [x] Add step 11: Classify each test scenario as automated / manual / both
    - [x] Add step 12: Define manual test requirements for flagged scenarios
    - [x] Add output: Manual test scenario section in test spec
    - [x] Add state tracking update: ../feature-tracking.md Test Status (step 20)
    - [x] Add state tracking update: ../test-tracking.md (step 20)
    - [x] Add handover interface: → Manual Test Case Creation task (Information Flow + Next Tasks)
    - [x] Update test specification template to include manual test section (v1.1 → v1.2)

- [x] **🚨 CHECKPOINT**: Present all changes to human partner — APPROVED

### Phase 3: Manual Test Case Creation Task (Session 3) ✅
**Priority**: HIGH — New task creation
**Delegated to**: [New Task Creation Process (PF-TSK-001)](../../../tasks/support/new-task-creation-process.md) — Full Mode (all sessions consolidated into one)
**Source**: Proposal section B1 (task), D1 (test case template), D2 (master test template)

- [x] **Delegate: Create Manual Test Case Creation task** → PF-TSK-001 Full Mode
  - **Status**: COMPLETED
  - **Input to delegation**: Proposal sections B1, D1, D2; naming conventions (MT-NNN, master-test-[group-name].md)
  - **Artifacts produced**:

    | Artifact | ID | Location |
    |----------|-----|----------|
    | Task definition | PF-TSK-069 | `tasks/03-testing/manual-test-case-creation-task.md` |
    | Master test template | PF-TEM-053 | `templates/templates/manual-master-test-template.md` |
    | Test case template | PF-TEM-054 | `templates/templates/manual-test-case-template.md` |
    | Creation script | — | `scripts/file-creation/New-ManualTestCase.ps1` |
    | Customization guide | PF-GDE-049 | `guides/guides/manual-test-case-customization-guide.md` |
    | Context map | PF-VIS-049 | `visualization/context-maps/03-testing/manual-test-case-creation-map.md` |
    | ID prefixes | MT, MT-GRP | `id-registry.json` |

  - **Infrastructure updated**: `Add-TestImplementationEntry` extended with `TestType` + `LastExecuted` parameters (backward compatible)
  - **Remaining**: Task transition guide update deferred to Phase 5

- [x] **🚨 CHECKPOINT**: All artifacts presented and approved by human partner

### Phase 4: Manual Test Execution Task + Scripts + Directory (Session 4) ✅
**Priority**: HIGH — New task + execution infrastructure
**Source**: Proposal sections B2 (task), E1–E3 (scripts), F (directory structure)

- [x] **Delegate: Create Manual Test Execution task** → [PF-TSK-001](../../../tasks/support/new-task-creation-process.md) Lightweight Mode
  - **Status**: COMPLETED
  - **Input to delegation**: Proposal section B2; no new file types (reuses Phase 3 templates)
  - **Artifacts produced**:

    | Artifact | ID | Location |
    |----------|-----|----------|
    | Task definition | PF-TSK-070 | `tasks/03-testing/manual-test-execution-task.md` |
    | Context map | PF-VIS-050 | `visualization/context-maps/03-testing/manual-test-execution-map.md` |

- [x] **Create execution scripts** (direct)
  - **Status**: COMPLETED
  - **Location**: `doc/process-framework/scripts/testing/`
  - **Scripts**:

    | Script | Parameters | Behavior |
    |--------|-----------|----------|
    | ../Setup-TestEnvironment.ps1 | -Group, -Clean, -ProjectRoot | Copy pristine templates → workspace |
    | ../Verify-TestResult.ps1 | -TestCase, -Group, -Detailed | Diff workspace vs. expected state |
    | ../Update-TestExecutionStatus.ps1 | -FeatureId, -Group, -Status, -Reason | Update ../test-tracking.md + ../feature-tracking.md |

- [x] **Create `test/manual-testing/` directory structure** (direct)
  - **Status**: COMPLETED
  - **Deliverables**: `templates/`, `workspace/`, `results/` directories; README.md; .gitignore

- [x] **Documentation updates**: ../documentation-map.md updated with task, context map, 3 scripts; ai-tasks.md and ../tasks/README.md auto-updated and link-fixed

- [x] **🚨 CHECKPOINT**: All Phase 4 artifacts presented and approved by human partner

### Phase 5: Task Handover Updates + Validation + Cleanup (Session 5) ✅
**Priority**: HIGH — Integration and finalization

- [x] **Modify existing tasks with manual test handover interfaces** (direct)
  - **Status**: COMPLETED
  - **Tasks modified**:

    | Task | Change Applied |
    |------|----------------|
    | PF-TSK-007 (Bug Fixing) | Added Step 5 (check manual test coverage), Step 22 (mark for re-execution), Next Tasks (Manual Test Case Creation + Manual Test Execution) |
    | PF-TSK-022 (Code Refactoring) — Standard Path | Added Step 4 (check manual test coverage), Phase 2 checklist (mark for re-execution), Next Tasks (Manual Test Execution) |
    | PF-TSK-068 (Feature Enhancement) | Added Step 3 (check manual test coverage), Next Tasks (Manual Test Case Creation + Manual Test Execution) |
    | PF-TSK-053 (Integration and Testing) | Added Step 23 (mark manual test groups for re-execution) |
    | PF-TSK-008 (Release & Deployment) | Added Step 8 (verify all manual test groups pass before release) |

  - **Tasks reviewed, no modification needed**: PF-TSK-029 (normal workflow handles it), PF-TSK-044 (planning only), PF-TSK-005 (Code Review — implicit in PR review)

- [x] **Update task transition guide** — Added Scenario 16: Manual Testing Workflows (all 5 paths)

- [x] **Documentation-map.md** — Already updated in Phase 4

- [x] **Run Validate-StateTracking.ps1** — 0 errors, 11 pre-existing warnings. Fixed import path bug in the script.

- [ ] **Cleanup**: Archive this state file to `temporary/old/`
  - **Status**: PENDING — awaiting human approval of Phase 5

- [ ] **Feedback forms** (PF-TSK-014, "Structure Change — Manual Testing Framework")
  - **Status**: PENDING

## Session Tracking

### Session 1: 2026-03-14
**Focus**: Preparation & Proposal
**Completed**:
- [x] Discussed current testing gaps with human partner
- [x] Explored all testing-related tasks (PF-TSK-012, PF-TSK-053, PF-TSK-030)
- [x] Explored structure change task (PF-TSK-014) and templates
- [x] Created comprehensive proposal with human partner input on:
  - No manual test column in feature-tracking (use test statuses instead)
  - Merge manual tracking into ../test-implementation-tracking.md (rename)
  - Scripts in scripts/testing/
  - Test spec task (PF-TSK-012) owns manual/automated classification
  - Workflow variations for new feature / bug fix / tech debt / enhancement
  - Handover interfaces between all affected tasks
- [x] Proposal approved by human partner
- [x] Created state tracking file (PF-STA-054)
- [x] Customized state tracking file with full implementation roadmap

**Issues/Blockers**:
- None

**Key Decisions**:
- Feature tracking: No new column. Add 🔧 Automated Only and 🔄 Re-testing Needed statuses
- Test tracking: Rename ../test-implementation-tracking.md → test-tracking.md, extend with manual test entries
- PF-TSK-012 owns manual/automated classification (has full context: TDD, FDD, UI docs)
- Manual Test Case Creation is a separate task (not embedded in structure change)
- Manual Test Execution is primarily human-executed, AI assists with setup/recording
- Update-TestExecutionStatus.ps1: New automated script for marking re-execution needs
- templates/ directory exclusion from file monitoring is project-level, not framework-level

**Next Session Plan**:
- Phase 2: Rename test-implementation-tracking.md, extend state files, modify PF-TSK-012

### Session 2: 2026-03-15
**Focus**: State Tracking Changes + PF-TSK-012 Modification
**Completed**:
- [x] Extended ../test-tracking.md with new columns (Test Type, Last Executed) and manual test status legend
- [x] Updated header from "Test Implementation Tracking" to "Test Tracking", version 2.5 → 3.0
- [x] All existing entries marked as "Automated" with Last Executed: —
- [x] Added manual test status transitions and "Adding Manual Test Cases" instructions
- [x] Extended ../feature-tracking.md Test Status legend with 🔧 Automated Only and 🔄 Re-testing Needed
- [x] Updated 13 files with cross-reference changes (old filename → new filename, old display name → new)
- [x] Modified PF-TSK-012 v1.3 → v1.4: added steps 3 (UI docs), 11 (classify), 12 (manual requirements), updated step 20, new output, new handover
- [x] Updated test specification template v1.1 → v1.2: added Manual Test Scenarios section
- [x] Checkpoint approved by human partner

**Issues/Blockers**:
- None

**Key Decisions**:
- No new decisions needed — all followed the Phase 2 plan from session 1

**Phase 3 Attempt (same session)**:
- [x] Attempted Phase 3 task creation without properly following PF-TSK-001 Full Mode
- [x] Created PF-TSK-069, PF-TEM-052, PF-TEM-053, PF-VIS-049 — but quality was insufficient
- [x] **ROLLED BACK**: All Phase 3 artifacts deleted, auto-updates reverted, ID counters restored, task-transition-guide reverted
- Human partner identified: task not thought through, missing creation script, wrong process order (master test should come before individual cases), non-standard sections (Information Flow)

**Issues/Blockers**:
- Phase 3 failed due to not properly following PF-TSK-001 Full Mode and Task Creation Guide
- Skipped reading Task Creation Guide carefully, rushed content customization
- Incorrectly marked "Session 2 — Document creation infrastructure: N/A" without thinking through script needs

**Key Decisions**:
- Phase 3 must be redone properly following PF-TSK-001 Full Mode step by step
- Test case directory creation needs a script (not manual AI agent work)
- Master test template should be created before individual test cases
- Task transition guide updates belong at the end (Phase 5), not during task creation

**Next Session Plan**:
- Phase 3 (redo): Follow PF-TSK-001 Full Mode properly — read Task Creation Guide, design creation script, plan ID prefix, then create task + templates + context map

### Session 3: 2026-03-15
**Focus**: Manual Test Case Creation Task + Templates + Script + Guide (redo, following PF-TSK-001 Full Mode properly)
**Completed**:
- [x] Read PF-TSK-001 Full Mode, Task Creation Guide, Template Development Guide, proposal sections B1/D1/D2
- [x] Created task definition PF-TSK-069 via New-Task.ps1, renamed to `-task` suffix
- [x] Fully customized task definition: Purpose, AI Agent Role (QA Engineer), When to Use (4 workflow paths), Context Requirements, Process (Preparation/Execution/Finalization), Outputs, State Tracking, Completion Checklist, Next Tasks, Related Resources
- [x] Created master test template PF-TEM-053 via New-Template.ps1, fully customized from proposal D2
- [x] Created test case template PF-TEM-054 via New-Template.ps1, fully customized from proposal D1
- [x] Updated naming conventions per human feedback: `MT-NNN-[name]/` (not `tc-NNN-`), `master-test-[group-name].md` (not `master-test.md`)
- [x] Registered ID prefixes MT and MT-GRP in ../id-registry.json
- [x] Updated `Add-TestImplementationEntry` in TestTracking.psm1 with `TestType` and `LastExecuted` parameters (backward compatible)
- [x] Created `New-ManualTestCase.ps1` creation script: creates directories, assigns IDs, updates master test + test-tracking + feature-tracking automatically
- [x] Fixed `Update-FeatureTrackingStatus` call (correct parameter: `StatusColumn` not `ColumnName`)
- [x] Fixed WhatIf handling in creation script (skip directory existence check, wrap ID registry writes)
- [x] Created customization guide PF-GDE-049 via New-Guide.ps1, fully customized
- [x] Created context map PF-VIS-049 via New-ContextMap.ps1, fully customized
- [x] Updated task definition to reference script in Execution steps (steps 5-10 use script, step 9 is manual master test Quick Validation update only)
- [x] Fixed documentation auto-update links (file rename from `.md` to `-task.md` in ai-tasks.md, documentation-map.md, tasks/README.md)
- [x] Added all new artifacts to ../documentation-map.md (task, 2 templates, script, guide, context map)
- [x] Tested script with -WhatIf: all operations traced correctly
- [x] Checkpoint approved by human partner

**Issues/Blockers**:
- None

**Key Decisions**:
- Individual test case directories use MT-NNN-[name]/ naming (not tc-NNN-)
- Master test files use master-test-[group-name].md naming (unique, descriptive)
- Creation script handles ../test-tracking.md and ../feature-tracking.md updates automatically
- Script adds to master test "If Failed" table automatically; Quick Validation Sequence remains manual (requires judgment)
- `Add-TestImplementationEntry` updated with new columns (backward compatible via defaults)
- Task transition guide updates deferred to Phase 5 (alongside all task handover modifications)

**Next Session Plan**:
- Phase 4: Manual Test Execution task + testing scripts (Setup-TestEnvironment.ps1, Verify-TestResult.ps1, Update-TestExecutionStatus.ps1) + test/manual-testing/ directory structure

### Session 4: 2026-03-15 (same session as Session 3)
**Focus**: Manual Test Execution Task + Scripts + Directory Structure
**Completed**:
- [x] Created task definition PF-TSK-070 via New-Task.ps1, renamed to `-task` suffix
- [x] Fully customized: Purpose (human-executed, AI assists), AI Agent Role (QA Support Assistant), process with script commands, all standard sections
- [x] Fixed documentation auto-update links (file rename to `-task` suffix) in ai-tasks.md, documentation-map.md, ../tasks/README.md
- [x] Created context map PF-VIS-050 via New-ContextMap.ps1, fully customized
- [x] Created `scripts/testing/` directory with 3 scripts:
  - Setup-TestEnvironment.ps1: copies pristine fixtures to workspace, supports -Group/-Clean
  - Verify-TestResult.ps1: diffs workspace vs expected state, supports -Detailed
  - Update-TestExecutionStatus.ps1: updates ../test-tracking.md + ../feature-tracking.md with execution results
- [x] Created `test/manual-testing/` directory structure: templates/, workspace/, results/, README.md, .gitignore
- [x] Updated ../documentation-map.md with task, context map, 3 scripts (new Testing Scripts section)
- [x] Checkpoint approved by human partner

**Issues/Blockers**:
- None

**Key Decisions**:
- Manual Test Execution is primarily human-executed, AI Agent Role is "QA Support Assistant" (not full QA Engineer)
- Testing scripts placed in `scripts/testing/` (separate from `scripts/file-creation/` and `scripts/update/`)
- workspace/ and results/ directories are gitignored

**Next Session Plan**:
- Phase 5: Task handover updates, task transition guide, validation, cleanup, feedback forms

### Session 5: 2026-03-15 (same session as Sessions 3+4)
**Focus**: Task Handover Updates + Validation + Cleanup
**Completed**:
- [x] Modified Bug Fixing (PF-TSK-007): manual test check step, re-execution marking, handover to creation/execution
- [x] Modified Code Refactoring Standard Path: manual test coverage check, re-execution marking in Phase 2 checklist
- [x] Modified Code Refactoring main task: Manual Test Execution in Next Tasks
- [x] Modified Feature Enhancement (PF-TSK-068): manual test check step, handover to creation/execution
- [x] Modified Integration and Testing (PF-TSK-053): re-execution marking step
- [x] Modified Release & Deployment (PF-TSK-008): manual test gate (all groups must pass)
- [x] Reviewed PF-TSK-029, PF-TSK-044, PF-TSK-005: no modification needed
- [x] Added Scenario 16 (Manual Testing Workflows) to task transition guide — all 5 paths documented
- [x] Fixed ../Validate-StateTracking.ps1 import path (was looking in validation/ for Common-ScriptHelpers.psm1)
- [x] Validation passed: 0 errors, 11 pre-existing warnings

**Issues/Blockers**:
- ../Validate-StateTracking.ps1 had a pre-existing bug (module import from wrong directory) — fixed as part of this phase

**Key Decisions**:
- PF-TSK-029 (Foundation Feature Implementation): No modification — normal workflow handles manual test creation
- PF-TSK-044 (Feature Implementation Planning): No modification — planning task, Test Spec Creation handles classification
- PF-TSK-005 (Code Review): No modification — manual test review is implicit in PR review
- PF-TSK-008 (Release & Deployment): Added manual test gate — additional to the original 4 tasks planned

**Remaining**:
- Archive state file (awaiting human approval)
- Feedback forms

## Testing & Validation

### Test Cases

| Test Case | Description | Expected Result | Actual Result | Status |
|-----------|-------------|----------------|---------------|--------|
| TC-001 | File rename: ../test-implementation-tracking.md → ../test-tracking.md | All cross-references updated, no broken links | 13 files updated, grep confirms 0 remaining references | PASSED |
| TC-002 | New tasks registered in ai-tasks.md | Both new tasks appear in 03-testing section | PF-TSK-069 + PF-TSK-070 both registered with -task suffix links | PASSED |
| TC-003 | New tasks registered in ../documentation-map.md | Both new tasks listed with links | Both in discrete tasks section + proper task listing | PASSED |
| TC-004 | ../Setup-TestEnvironment.ps1 with sample data | Templates copied to workspace correctly | — | PENDING |
| TC-005 | ../Verify-TestResult.ps1 with matching files | Reports all green / pass | — | PENDING |
| TC-006 | ../Verify-TestResult.ps1 with mismatched files | Reports failures with diff | — | PENDING |
| TC-007 | ../Update-TestExecutionStatus.ps1 | ../test-tracking.md and ../feature-tracking.md updated | — | PENDING |
| TC-008 | Handover chain: bug fix path | Trace through all modified tasks, interfaces consistent | — | PENDING |
| TC-009 | Handover chain: new feature path | Trace through all modified tasks, interfaces consistent | — | PENDING |
| TC-010 | ../Validate-StateTracking.ps1 | 0 errors across all surfaces | — | PENDING |

### Success Criteria

- [ ] **Functional Criteria**:
  - [ ] ../test-tracking.md (renamed) tracks both automated and manual test entries
  - [ ] All new tasks registered in ai-tasks.md and ../documentation-map.md
  - [ ] All three new scripts execute without errors on sample data
  - [ ] All modified tasks have explicit handover interfaces to/from new tasks
  - [ ] test/manual-testing/ directory structure created with README.md
  - [ ] ../Validate-StateTracking.ps1 passes with 0 errors

- [ ] **Quality Criteria**:
  - [ ] New tasks are project-agnostic (generic and reusable)
  - [ ] Templates provide clear structure for manual test case creation
  - [ ] Workflow variations (new feature, bug fix, tech debt, enhancement) are documented in task definitions
  - [ ] No duplicate information across task definitions

## Rollback Information

### Rollback Triggers

- [ ] **Critical Issues**:
  - [ ] Rename of ../test-implementation-tracking.md breaks existing automation
  - [ ] New statuses create confusion with existing test tracking
  - [ ] Modified tasks become internally inconsistent

### Rollback Procedure

1. **Stop Current Work**: Halt any ongoing changes
2. **Git Revert**: Revert all commits from this structure change
3. **Verify Restoration**: Run ../Validate-StateTracking.ps1
4. **Analyze Failure**: Document what went wrong in this state file

## Completion Criteria

This temporary state file can be moved to `doc/process-framework/state-tracking/temporary/old/` when:

- [ ] All 5 phases completed successfully
- [ ] All 10 test cases pass
- [ ] All success criteria met
- [ ] All tasks modified with handover interfaces
- [ ] All cross-references updated
- [ ] Documentation map updated
- [ ] ../Validate-StateTracking.ps1 passes
- [ ] Feedback forms completed

## Notes and Decisions

### Key Decisions Made

1. **No Manual Test column in feature-tracking.md**: Manual test coverage is tracked via Test Status values (🔧 Automated Only, 🔄 Re-testing Needed) and the test spec link remains the entry point. This avoids a 1:N column problem.

2. **Merge not separate**: Manual test tracking merges into ../test-implementation-tracking.md (renamed to test-tracking.md) rather than creating a separate tracking file. Keeps all test state in one surface.

3. **PF-TSK-012 owns classification**: The Test Specification Creation task determines which scenarios need manual tests (it has the full context: TDD, FDD, UI docs, tier assessment). The Manual Test Case Creation task then creates the concrete, executable test cases.

4. **Workflow variations**: The workflow position of Manual Test Case Creation varies by context:
   - New feature: After implementation
   - Bug fix: Before code change (define reproduction case)
   - Tech debt: Before code change (capture correct behavior)
   - Enhancement: After test spec creation

5. **templates/ exclusion**: Framework-level skeleton includes the directory structure; project-level configuration handles file monitoring exclusion.

### Feedback for Structure Change Task (PF-TSK-014)

> **To be included in final feedback form:**
>
> The Structure Change task (PF-TSK-014) should serve as a **manager/orchestrator** — it tracks overall progress and delegates to specialized tasks, rather than absorbing their processes. The state tracking file should reference delegated tasks and their own state files, not inline all the steps. For example, when a structure change involves creating new tasks, it should delegate to PF-TSK-001 (New Task Creation Process) which creates its own temp state file and follows its own quality gates. The structure change state file tracks the delegation status, not the individual sub-steps of the delegated task. This was discovered in Phase 3 when the structure change tried to do PF-TSK-001's job inline, bypassing its quality gates (file rename suffix, verify auto-updates, generic/reusable emphasis, Task Creation Guide reference, creation script design).
