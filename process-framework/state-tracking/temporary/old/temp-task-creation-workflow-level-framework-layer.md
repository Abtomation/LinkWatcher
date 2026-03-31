---
id: PF-STA-068
type: Document
category: General
version: 1.0
created: 2026-03-31
updated: 2026-03-31
task_name: workflow-level-framework-layer
---

# Temporary State: Workflow-Level Framework Layer (PF-IMP-258)

> **Temporary file** — move to `process-framework/state-tracking/temporary/old` when all sessions complete.

## Overview

- **Source**: [PF-IMP-258](/process-framework/state-tracking/permanent/process-improvement-tracking.md)
- **Concept Document**: [PF-PRO-013](/process-framework/proposals/proposals/old/workflow-level-framework-layer.md)
- **Task**: PF-TSK-026 (Framework Extension Task)
- **Total Sessions**: 4 planned

## Implementation Roadmap

### Session 1: Foundation — Workflow Tracking Promotion + State File Integration
**Priority**: HIGH
**Status**: COMPLETED

- [x] Relocate `user-workflow-tracking.md` → `doc/product-docs/state-tracking/permanent/user-workflow-tracking.md`
- [x] Rename file, update ID to PD-STA-066
- [x] Add "Impl Status" and "E2E Status" columns, populate from current state
- [x] Update all existing references (18 files updated manually — LinkWatcher didn't detect cross-directory move+rename)
- [x] Update PD-id-registry.json (PD-STA nextAvailable 66→67)
- [x] Update process-improvement-tracking.md (IMP-258 status → In Progress, changelog entry)
- [x] Add "Workflows" column to bug-tracking.md tables
- [x] Add "Workflows" column to technical-debt-tracking.md
- [x] Add "Workflows" metadata field to all 8 feature state files
- [x] Update documentation-map.md for relocated file (already done — reference updated in Session 2)

### Session 2: Phase 06 Maintenance + Phase 02 Design Integration
**Priority**: HIGH
**Status**: COMPLETED

Tasks:
- [x] Modify Bug Triage (PF-TSK-041): add workflow lookup step (step 16)
- [x] Modify Bug Fixing (PF-TSK-022): add workflow blast radius step (step 4)
- [x] Modify Code Refactoring (PF-TSK-007): add workflow correctness check (after Effort Assessment Gate)
- [x] Update Bug Reporting Guide (added Workflows optional parameter)
- [x] Update Code Refactoring Usage Guide (added Workflow-Aware Refactoring pattern)

Templates:
- [x] Add "Workflow Participation" section to FDD template (between User Experience Flow and Acceptance Criteria)
- [x] Modify FDD Creation (PF-TSK-005): add workflow participation step (step 9)
- [x] Update FDD Customization Guide (new step 4, renumbered subsequent steps)
- [x] Add "Workflow Context" field to TDD template (all 3 tiers: T1, T2, T3)
- [x] Modify TDD Creation (PF-TSK-002): add workflow context reference (step 12)
- [x] Update TDD Creation Guide (new step 3, renumbered subsequent steps)

### Session 3: Phase 04-05 Implementation + Validation + Automation
**Priority**: MEDIUM
**Status**: COMPLETED (Surface 7 deferred to Session 4)

Guides:
- [x] Add "Workflow Awareness" section to Development Guide
- [x] Update Feature Implementation State Tracking Guide (added `workflows:` field documentation)

Validation:
- [x] Add optional "Workflow Impact" subsection to validation report template
- [x] Modify Validation Preparation (PF-TSK-077): add workflow cohort grouping step
- [x] Update Feature Validation Guide with cohort grouping guidance
- [x] Update validation tracking template for cohort annotations (added Workflow Cohort column)

Automation:
- [x] Create `Update-WorkflowTracking.ps1` (process-framework/scripts/update/)
- [x] Integrate into `Update-FeatureImplementationState.ps1`
- [x] Integrate into `Update-TestExecutionStatus.ps1`
- [x] Extend `Validate-StateTracking.ps1` with Surface 8 (WorkflowTracking) — **completed in Session 4** (Surface 7 was already DimensionConsistency)

### Session 4: Phase 00-01 Setup + Planning + Finalization
**Priority**: MEDIUM
**Status**: COMPLETED

Tasks:
- [x] Modify Codebase Feature Discovery (PF-TSK-064): add workflow tracking creation step (step 9)
- [x] Modify Codebase Feature Analysis (PF-TSK-065): add workflow map validation step (step 9)
- [x] Modify Project Initiation (PF-TSK-059): add empty workflow tracking creation (step 10)
- [x] Modify Feature Request Evaluation (PF-TSK-067): add workflow mapping step (enhanced steps 5a, 5b)

Guides:
- [x] Update Enhancement State Tracking Customization Guide (added Affected Workflows field and Step 17 workflow guidance)
- [ ] Update Task Transition Guide with workflow info flow *(optional — skipped, low value)*

Automation (deferred from Session 3):
- [x] Extend Validate-StateTracking.ps1 with Surface 8 (WorkflowTracking) — validates WF-ID cross-references between feature state files and user-workflow-tracking.md

Finalization:
- [x] Final documentation-map.md sweep (updated Validate-StateTracking description: 5 surfaces → 8)
- [x] Update ai-tasks.md if needed (no changes needed — no new tasks)
- [ ] Archive this state file to old/
- [ ] Complete feedback form

## Session Log

### Session 1: 2026-03-31

**Focus**: Concept development and approval (Phase 1 of PF-TSK-026)
**Completed**:
- Created concept document PF-PRO-013
- Conducted gap analysis (bookend pattern, 17 tasks with zero workflow refs)
- Audited all state tracking files for workflow value
- Identified 7 must-update guides + 3 optional
- Designed automation strategy (Update-WorkflowTracking called by existing scripts)
- Human approved concept

**Decisions**:
- Lightweight approach: modify existing tasks, no new tasks
- feature-tracking.md excluded (redundant — feature state files + workflow tracking cover it)
- Automation via composition: existing update scripts call Update-WorkflowTracking
- No template for workflow tracking file — created directly during setup
- File renamed to user-workflow-tracking.md (state tracking convention)

**Next Session Plan**: Session 1 implementation — relocate workflow map, add columns to state files

### Session 2: 2026-03-31

**Focus**: Session 1 implementation — workflow map promotion + start of state file integration
**Completed**:
- Relocated user-workflow-map.md → state-tracking/permanent/user-workflow-tracking.md (PD-STA-066)
- Updated metadata (ID, category, version), added Impl Status and E2E Status columns
- Populated status columns from feature-tracking.md and e2e-test-tracking.md
- Updated PD-id-registry.json (PD-STA nextAvailable 66→67)
- Updated 18 files with new references (manual — LinkWatcher didn't detect cross-dir move+rename)
- Updated IMP-258 status to In Progress in process-improvement-tracking.md + changelog entry

**Issues/Blockers**:
- LinkWatcher did not detect the cross-directory move+rename as a file move (saw it as delete+create). References updated manually.

**Remaining for Session 1 roadmap (4 items)**:
- Add "Workflows" column to bug-tracking.md tables
- Add "Workflows" column to technical-debt-tracking.md
- Add "Workflows" metadata field to all 8 feature state files
- Update documentation-map.md for relocated file

**Next Session Plan**: Complete remaining Session 1 items, then proceed to Session 2 roadmap (Phase 06 + Phase 02 task/template/guide modifications)

### Session 3: 2026-03-31

**Focus**: Complete Session 1 roadmap — remaining 4 items (state file integration)
**Completed**:
- Added "Workflows" column to bug-tracking.md (all 5 tables: Critical, High, Medium, Low, Closed)
- Populated Workflows for active bugs with Related Feature 2.1.1 → WF-001, WF-002, WF-003, WF-005
- Closed bugs: column header added, blank workflow cells (historical data)
- Added "Workflows" column to technical-debt-tracking.md active registry table
- Resolved items table left as-is (different column schema, historical)
- Added `workflows:` YAML metadata field to all 8 feature state files with WF-IDs derived from user-workflow-tracking.md
- Confirmed documentation-map.md already references the relocated file (done in Session 2)

**Decisions**:
- Closed bugs get empty Workflows cells (historical, no operational value in backfilling)
- technical-debt-tracking.md resolved items table left unchanged (different schema, collapsed historical section)
- Feature 6.1.1 (Link Validation) gets `workflows: []` — on-demand tool, not part of any real-time workflow

**Next Session Plan**: Session 2 roadmap — Phase 06 maintenance task modifications (bug triage, bug fixing, code refactoring) + Phase 02 design template/task modifications (FDD, TDD)

### Session 4: 2026-03-31 (continued)

**Focus**: Session 2 roadmap — Phase 06 maintenance + Phase 02 design integration (11 items)
**Completed**:
- **Phase 06 — 3 tasks modified**:
  - Bug Triage (PF-TSK-041): Added step 16 "Identify Affected Workflows" in Assignment section, look up WF-IDs from user-workflow-tracking.md and populate Workflows column. Added checklist item.
  - Bug Fixing (PF-TSK-007): Added step 4 "Assess workflow blast radius" in Preparation section. Renumbered all subsequent steps (5→6 through 33→35). Updated all internal step cross-references.
  - Code Refactoring (PF-TSK-022): Added "Workflow awareness" note after Effort Assessment Gate, referencing feature state file `workflows:` metadata and user-workflow-tracking.md.
- **Phase 06 — 2 guides updated**:
  - Bug Reporting Guide: Added `Workflows` optional parameter to the parameters table
  - Code Refactoring Usage Guide: Added "Workflow-Aware Refactoring" pattern covering regression testing scope, co-participant awareness, and E2E test re-execution
- **Phase 02 — 3 FDD items**:
  - FDD template: Added "Workflow Participation" section (table format) between User Experience Flow and Acceptance Criteria
  - FDD Creation task (PF-TSK-005): Added step 9 "Document Workflow Participation", renumbered 10→13 through 15→16
  - FDD Customization Guide: Added step 4 "Document Workflow Participation" with example, renumbered steps 5→6, 6→7
- **Phase 02 — 3 TDD items**:
  - TDD templates (all 3 tiers): Added "Workflow Context" field in Overview section (T1: after Overview, T2/T3: as subsection 1.3/1.4)
  - TDD Creation task (PF-TSK-002): Added step 12 "Populate Workflow Context", renumbered 13→21
  - TDD Creation Guide: Added step 3 "Populate Workflow Context", renumbered step 4→5

**Decisions**:
- All additions are lightweight (few lines each) — no new tasks, templates, or scripts created
- Bug Fixing step numbering was the most impactful change (34 steps → 35 steps) requiring careful cross-reference updates
- FDD Workflow Participation uses a table format (Workflow | Role in Workflow) for structured data
- TDD Workflow Context is a simple field (list of WF-IDs) since TDDs focus on technical design, not functional workflow descriptions

**Next Session Plan**: Session 3 roadmap — Phase 04-05 implementation guides, validation task modifications, and automation scripts (Update-WorkflowTracking.ps1)

### Session 5: 2026-03-31 (continued)

**Focus**: Session 3 roadmap — Phase 04-05 guides, validation modifications, automation scripts (9 of 10 items)
**Completed**:
- **Guides (2 items)**:
  - Development Guide: Added "Workflow Awareness" section before Feature Development Guidelines — 3-step checklist (find workflows, understand co-participants, test workflow paths) with concrete example
  - Feature Implementation State Tracking Guide: Added `workflows:` field documentation in Step 2 (Populate Core Metadata) with YAML example and explanation
- **Validation (4 items)**:
  - Validation report template: Added optional "Workflow Impact" subsection in Cross-Feature Analysis section
  - Validation Preparation (PF-TSK-077): Added workflow cohort grouping guidance as sub-step within step 8 (Plan Session Sequence)
  - Feature Validation Guide: Updated session planning example to show WF-001 cohort grouping
  - Validation tracking template: Added "Workflow Cohort" column to Feature Scope table
- **Automation (3 of 4 items)**:
  - Created `Update-WorkflowTracking.ps1` (~180 LOC): Parses feature-tracking.md for impl statuses, e2e-test-tracking.md for E2E milestone statuses, and updates user-workflow-tracking.md Impl Status and E2E Status columns. Tested with -WhatIf: correctly identified 10 features, 7 workflow E2E statuses, 6 rows to update.
  - Integrated into `Update-FeatureImplementationState.ps1`: Calls Update-WorkflowTracking after feature state changes (respects -DryRun)
  - Integrated into `Update-TestExecutionStatus.ps1`: Calls Update-WorkflowTracking after E2E test status changes (respects -WhatIf)

**Deferred to Session 4**:
- Validate-StateTracking.ps1 Surface 7 (WorkflowTracking) — user approved deferral

**Next Session Plan**: Session 4 roadmap — Phase 00-01 setup/planning task modifications, optional guides, finalization (archive state file, feedback form), and deferred Surface 7 validation

### Session 6: 2026-03-31 (continued)

**Focus**: Session 4 roadmap — Phase 00-01 setup/planning task modifications, deferred Surface 8, finalization
**Completed**:
- **Phase 00 — 2 tasks modified**:
  - Codebase Feature Discovery (PF-TSK-064): Added step 9 "Create User Workflow Tracking File" between feature state file creation and checkpoint. Renumbered steps 10→15. Added checklist items for workflow tracking file and workflows: metadata. Added output and state tracking entries.
  - Project Initiation (PF-TSK-059): Added step 10 "Create Empty User Workflow Tracking File" between test infrastructure and CI/CD setup. Renumbered steps 11→16. Added output and checklist items.
- **Phase 00 — 1 task modified**:
  - Codebase Feature Analysis (PF-TSK-065): Added step 9 "Validate Workflow Map Completeness" in Finalization section. Renumbered steps 10→12. Added checklist item for workflow map validation.
- **Phase 01 — 1 task modified**:
  - Feature Request Evaluation (PF-TSK-067): Enhanced steps 5a and 5b with explicit guidance on updating user-workflow-tracking.md and setting `workflows:` metadata in feature state files.
- **Guide — 1 updated**:
  - Enhancement State Tracking Customization Guide: Added "Affected Workflows" row to Step 1 (Enhancement Overview) table and workflow update guidance to Step 4 Block 17.
- **Automation — 1 item completed (deferred from Session 3)**:
  - Validate-StateTracking.ps1: Added Surface 8 (WorkflowTracking) — validates WF-ID cross-references between feature state files' `workflows:` metadata and user-workflow-tracking.md. Supports both YAML list and inline formats. 85 checks passed on first run after format fix.
- **Finalization**:
  - documentation-map.md: Updated Validate-StateTracking description (5 surfaces → 8 surfaces)
  - ai-tasks.md: No changes needed (no new tasks created)

**Decisions**:
- Task Transition Guide workflow info flow update skipped (optional, low value — the workflow tracking is already well-documented in the tasks themselves)
- Surface numbered 8 (not 7) because Surface 7 was already DimensionConsistency
- YAML list format (`- WF-XXX`) supported in addition to inline format (`[WF-001, WF-002]`) for workflow parsing

**Next**: Archive state file, complete feedback form

## Completion Criteria

- [x] All 4 sessions completed
- [x] All items in roadmap checked off (except optional Task Transition Guide update — skipped)
- [x] documentation-map.md updated with all changes
- [ ] Feedback form completed
- [ ] This file archived to old/
