---
id: PF-STA-078
type: Document
category: General
version: 1.0
created: 2026-04-08
updated: 2026-04-08
task_name: integration-narrative-extension
---

# Temporary Task Creation State: Integration Narrative Extension

> **⚠️ TEMPORARY FILE**: This file tracks multi-session implementation of task creation infrastructure. Move to `process-framework-local/state-tracking/temporary/old` after all components are implemented.

## Task Overview

- **Task Name**: Integration Narrative Creation
- **Task ID**: [To be assigned by New-Task.ps1]
- **Concept Document**: [PF-PRO-016](../../../proposals/old/cross-feature-integration-documentation.md)
- **Source IMP**: PF-IMP-386
- **Extension Type**: Hybrid (new artifacts + existing file modifications)

## Infrastructure Analysis

### Required Artifacts

| Artifact Type | Name | Status | Priority | Notes |
| ------------- | ---- | ------ | -------- | ----- |
| Task Definition | integration-narrative-creation-task.md | NEEDED | HIGH | New lightweight task in 02-design phase |
| Directory | `doc/technical/integration/` | NEEDED | HIGH | Storage for PD-INT narrative files |
| Template | integration-narrative-template.md | NEEDED | HIGH | Standardized narrative structure |
| Guide | integration-narrative-customization-guide.md | NEEDED | MEDIUM | How to customize the template |
| Script | New-IntegrationNarrative.ps1 | NEEDED | HIGH | Creation script with PD-INT IDs, auto-updates PD-documentation-map.md |
| Context Map | integration-narrative-creation-map.md | NEEDED | MEDIUM | Visual context for the new task |

### Available for Reuse

| Artifact | Location | Reuse Notes |
| -------- | -------- | ----------- |
| Common-ScriptHelpers.psm1 | `process-framework/scripts/Common-ScriptHelpers.psm1` | `New-StandardProjectDocument` pattern for script creation |
| Document Creation Script Template | `process-framework/templates/support/document-creation-script-template.ps1` | Base template for New-IntegrationNarrative.ps1 |
| PD-id-registry.json | `doc/PD-id-registry.json` | Add PD-INT prefix — standard pattern |
| user-workflow-tracking.md | `doc/state-tracking/permanent/user-workflow-tracking.md` | Add "Integration Doc" column at end (safe — validation uses index 3) |

## Implementation Roadmap

### Phase 1: Core Task Infrastructure (Session 1)

**Priority**: HIGH — Must complete before task can be used

- [x] **Task Definition File**: Create "Integration Narrative Creation" task
  - **Status**: COMPLETED
  - **ID**: PF-TSK-083
  - **Path**: `process-framework/tasks/02-design/integration-narrative-creation.md`
  - **Customization**: Full process (13 steps), code verification emphasis, 2 checkpoints, Integration Architect role

- [x] **Verify automated documentation updates**: Confirm New-Task.ps1 updated PF-documentation-map.md, tasks/README.md, ai-tasks.md
  - **Status**: COMPLETED
  - PF-documentation-map.md: Entry fixed from table format to prose format matching section convention
  - tasks/README.md: "When to Use" updated from generic to specific trigger description
  - ai-tasks.md: Row added to 02-design table
  - process-framework-task-registry.md: Entry updated from placeholders to actual script/file/impact details

### Phase 2: Document Creation Infrastructure (Session 2)

**Priority**: HIGH — Script needed for all narrative creation

- [x] **Create output directory**: `doc/technical/integration/`
  - **Status**: COMPLETED

- [x] **Update PD-id-registry.json**: Add PD-INT prefix
  - **Status**: COMPLETED
  - **New Prefix**: `PD-INT`, directory `doc/technical/integration`, nextAvailable: 1

- [x] **Create New-IntegrationNarrative.ps1**: Document creation script
  - **Status**: COMPLETED
  - **Location**: `process-framework/scripts/file-creation/02-design/New-IntegrationNarrative.ps1`
  - **Parameters**: `-WorkflowName`, `-WorkflowId`, `-Description`, `-OpenInEditor`
  - **Auto-updates**: PD-id-registry.json (via Common-ScriptHelpers), PD-documentation-map.md (via Add-DocumentationMapEntry), user-workflow-tracking.md "Integration Doc" column (custom update by WorkflowId)
  - **Graceful fallbacks**: Reports when "### Integration Narratives" section or "Integration Doc" column don't exist yet (Phase 4)

- [x] **Test script**: Verify ID assignment, file creation, doc-map auto-update
  - **Status**: COMPLETED
  - WhatIf: Correct ShouldProcess output, graceful fallback messages for missing Phase 4 structures
  - Real run: Created PD-INT-001 at correct path, template replacements correct, ID registry incremented
  - Cleanup: Test file removed, counter reset to 1
  - Note: Metadata type/category defaults to "Document"/"General" — will be fixed when template is properly customized in Session 3

### Phase 3: Template and Guide (Session 3)

**Priority**: MEDIUM — Needed for consistent narrative structure

- [x] **Create integration-narrative-template.md**: Template via New-Template.ps1
  - **Status**: COMPLETED
  - **ID**: PF-TEM-070
  - **Path**: `process-framework/templates/02-design/integration-narrative-template.md`
  - **Sections**: Workflow Overview, Participating Features, Component Interaction Diagram, Data Flow Sequence, Callback/Event Chains, Configuration Propagation, Error Handling Across Boundaries, TDD/Code Divergence Notes
  - **Customization**: Full instructional comments, conditional section "not applicable" text, Visual Notation Guide conventions, fixed `creates_document_type` to "Product Documentation"

- [x] **Create integration-narrative-customization-guide.md**: Guide via New-Guide.ps1
  - **Status**: COMPLETED
  - **ID**: PF-GDE-059
  - **Path**: `process-framework/guides/02-design/integration-narrative-customization-guide.md`
  - **Customization**: Template Structure Analysis, 3 Decision Points, 8-step instructions, QA checklist, 3 troubleshooting scenarios
  - **Note**: Renamed from `integration-narrative-customization.md` to match expected filename; fixed PF-documentation-map.md reference

### Phase 4: Framework Integration (Session 4)

**Priority**: HIGH — Connects extension to existing framework

- [x] **Create context map**: integration-narrative-creation-map.md
  - **Status**: COMPLETED
  - **ID**: PF-VIS-066
  - **Path**: `process-framework/visualization/context-maps/02-design/integration-narrative-creation-map.md`
  - **Customization**: Full mermaid diagram (10 components, 3 priority levels), 8 implementation steps, related documentation links

- [x] **Update user-workflow-tracking.md**: Add "Integration Doc" column at end of table
  - **Status**: COMPLETED
  - All 8 workflows initialized with "—" (dash), ready for PD-INT IDs when narratives are created

- [x] **Update PD-documentation-map.md**: Add "Integration Narratives" section header
  - **Status**: COMPLETED
  - Added `..### technical/integration/ — Integration Narratives` section under `technical/`

- [x] **Update PF-documentation-map.md**: Add script and context map entries
  - **Status**: COMPLETED
  - Script entry added (New-IntegrationNarrative.ps1), context map entry auto-added by New-ContextMap.ps1

- [x] **Update ai-tasks.md**: Add task to 02-design table + update E2E workflow diagram
  - **Status**: COMPLETED
  - Task row verified (already added by New-Task.ps1)
  - `[Integration Narrative Creation]` added to "New Feature Planning" and "Complex Features" workflows (after TDD Creation)
  - Integration Narrative added before E2E test spec in "E2E Acceptance Testing" workflow with updated milestone trigger note

- [x] **Update bug-fixing-task.md**: Add Integration Narrative maintenance check to Step 27
  - **Status**: COMPLETED
  - Added after FDD bullet, before N/A guidance

- [x] **Update code-refactoring-standard-path.md**: Add Integration Narrative bullet to Step 14
  - **Status**: COMPLETED
  - Added after Feature tracking bullet

- [x] **Update feature-enhancement.md**: Add Integration Narrative to Step 9 doc check
  - **Status**: COMPLETED
  - Added after FDD bullet, before N/A guidance

- [x] **Update documentation-alignment-validation.md**: Add Integration Narrative validation step
  - **Status**: COMPLETED
  - Added Step 9 (Integration Narrative Accuracy) with 4 verification criteria, renumbered Steps 10-20

- [x] **Cross-cutting updates**: Task transition guide, process framework task registry
  - **Status**: COMPLETED
  - Task transition guide: Added Integration Narrative Creation ownership section (PF-TSK-083)
  - Task registry: Updated script reference from placeholder to actual link, updated auto-update function list, corrected workflow-tracking update method from Manual to Script

- [x] **Validate**: Run `Validate-StateTracking.ps1` to confirm no breakage
  - **Status**: COMPLETED
  - Full validation: Pre-existing warnings only (ID counter gaps, empty state file sections)
  - Surface 8 (Workflow Tracking): 85/85 checks passed, 0 errors — column addition safe

## Session Tracking

### Session 0: 2026-04-08 (Concept + Planning)

**Focus**: PF-TSK-026 Phase 1-2: Concept development, human review, impact analysis, state file creation
**Completed**:
- Created concept document PF-PRO-016
- Human review with 3 rounds of feedback (workflow tracking, Full Mode, maintenance triggers)
- Impact analysis on 8 files to be modified
- Created this temp state file PF-STA-078

**Key decisions**:
- Standalone doc type (not TDD section)
- Track in user-workflow-tracking.md (not feature-tracking.md) — 1:1 workflow mapping
- New lightweight task (not piggyback on existing tasks)
- Full Mode (4 sessions) per PF-TSK-001 scope assessment
- Script auto-updates PD-documentation-map.md
- Code verification mandatory in task process (don't just trust TDDs)
- Position before E2E test case creation (PF-TSK-069)
- Maintenance checks in Bug Fixing, Code Refactoring, Feature Enhancement
- Documentation Alignment Validation extended

**Next Session Plan**: Phase 3 Session 1 — Create task definition via New-Task.ps1, customize

### Session 1: 2026-04-08

**Focus**: Phase 1 — Core task infrastructure
**Completed**:
- Created task definition PF-TSK-083 via New-Task.ps1
- Fully customized task: 13-step process, Integration Architect role, 2 checkpoints, code verification emphasis
- Verified and fixed all 4 auto-updated files (PF-documentation-map.md format, README "When to Use", task registry details)
- Updated this state file

**Next Session Plan**: Phase 2 — Create output directory, add PD-INT prefix to registry, create New-IntegrationNarrative.ps1 script, test

### Session 2: 2026-04-08

**Focus**: Phase 2 — Document creation infrastructure (script, directory, ID prefix)
**Completed**:
- Created `doc/technical/integration/` directory
- Added PD-INT prefix to PD-id-registry.json
- Created `New-IntegrationNarrative.ps1` with 3 auto-updates (registry, doc-map, workflow-tracking)
- Tested with WhatIf and real run — both pass, graceful fallbacks for missing Phase 4 structures
- Created placeholder template (will be fully customized in Session 3)

**Next Session Plan**: Phase 3 — Create full template via New-Template.ps1 and customization guide via New-Guide.ps1

### Session 3: 2026-04-08

**Focus**: Phase 3 — Template + customization guide
**Completed**:
- Removed placeholder template from Session 2, re-created via New-Template.ps1 with proper ID (PF-TEM-070)
- Fully customized template: 8 sections with instructional comments, conditional sections, Visual Notation Guide conventions
- Fixed `creates_document_type` metadata from "Process Framework" to "Product Documentation"
- Created customization guide via New-Guide.ps1 (PF-GDE-059)
- Fully customized guide: Template Structure Analysis, 3 Decision Points, 8 step-by-step instructions, QA checklist, troubleshooting
- Renamed guide file from `integration-narrative-customization.md` to `integration-narrative-customization-guide.md` to match task/state references
- Fixed PF-documentation-map.md guide entry to use correct filename

**Next Session Plan**: Phase 4 — Framework integration (context map, 8 existing file modifications, cross-cutting updates, validation)

### Session 4: 2026-04-08

**Focus**: Phase 4 — Framework integration (8 file modifications + context map + validation)
**Completed**:
- Created context map PF-VIS-066 via New-ContextMap.ps1, fully customized (10 components, 3 priority levels)
- Added "Integration Doc" column to user-workflow-tracking.md (8 workflows, all initialized with "—")
- Added "Integration Narratives" section header to PD-documentation-map.md
- Added script entry to PF-documentation-map.md (context map auto-added by script)
- Verified ai-tasks.md row (auto-added), updated 3 workflow diagrams (New Feature Planning, Complex Features, E2E Acceptance Testing)
- Added Integration Narrative maintenance check to bug-fixing-task.md Step 27
- Added Integration Narrative bullet to code-refactoring-standard-path.md Step 14
- Added Integration Narrative bullet to feature-enhancement.md Step 9
- Added Integration Narrative Accuracy step (Step 9) to documentation-alignment-validation.md, renumbered Steps 10-20
- Added Integration Narrative Creation ownership section to task-transition-guide.md
- Updated process-framework-task-registry.md (script link, auto-update details)
- Validated: Validate-StateTracking.ps1 Surface 8 = 85/85 passed, 0 errors

**Remaining for PF-TSK-026 finalization**:
- ~~Update PF-IMP-386 to Completed~~ DONE
- ~~Move concept document PF-PRO-016 to proposals/old/~~ DONE
- Create feedback form for PF-TSK-026
- Move this state file to temporary/old/

## State File Updates Required

- [x] **PF-documentation-map.md**: Add script and context map entries — **Status**: COMPLETED
- [x] **PD-documentation-map.md**: Add "Integration Narratives" section header — **Status**: COMPLETED
- [x] **ai-tasks.md**: Add task to 02-design table + update workflow diagram — **Status**: COMPLETED
- [x] **user-workflow-tracking.md**: Add "Integration Doc" column — **Status**: COMPLETED
- [x] **PD-id-registry.json**: Add PD-INT prefix — **Status**: COMPLETED
- [x] **Process Improvement Tracking**: Update PF-IMP-386 to Completed — **Status**: COMPLETED

## Completion Criteria

This temporary state file can be moved to `process-framework-local/state-tracking/temporary/old` when:

- [x] Task definition created and customized (Phase 1)
- [x] Script created and tested (Phase 2)
- [x] Template and guide created and customized (Phase 3)
- [x] All 8 existing files modified (Phase 4)
- [x] Context map created (Phase 4)
- [x] Validate-StateTracking.ps1 passes
- [x] PF-IMP-386 marked Completed
- [x] Concept document PF-PRO-016 moved to proposals/old/
- [ ] Feedback forms completed for PF-TSK-026

## Notes and Decisions

### Key Decisions Made

- **Standalone doc type over TDD section**: Integration Narratives serve a different purpose (cross-feature workflow) than TDDs (single feature design). Future tasks need the integration view, not individual feature docs.
- **user-workflow-tracking.md over feature-tracking.md**: Narratives map 1:1 to workflows, not to features. A single narrative covers 2-4 features.
- **Full Mode over Lightweight**: Creates new file types (PD-INT), needs new template/guide/script — all three PF-TSK-001 criteria trigger Full Mode.
- **Code verification mandatory**: TDDs may be outdated — task process requires reading source code, not just trusting documentation.
- **TDD/code divergence → tech debt, not narrative content**: Discrepancies between TDDs and source code are reported as technical debt via `Update-TechDebt.ps1`. The narrative documents the actual state (what the code does).
- **Script auto-updates user-workflow-tracking.md**: The `-WorkflowId` parameter allows the script to find and fill the "Integration Doc" column automatically, eliminating a manual finalization step.
- **Position before E2E test case creation**: Integration understanding helps write better E2E tests.
