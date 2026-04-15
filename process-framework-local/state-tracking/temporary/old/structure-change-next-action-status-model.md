---
id: PF-STA-083
type: Document
category: General
version: 1.0
created: 2026-04-11
updated: 2026-04-11
change_name: next-action-status-model
---

# Structure Change State: Next-Action Status Model

> **⚠️ TEMPORARY FILE**: This file tracks implementation of a content update structure change. Move to `process-framework-local/state-tracking/temporary/old` after all changes are validated.

## Structure Change Overview
- **Change Name**: Next-Action Status Model
- **Change ID**: [To be assigned - SC-XXX format]
- **Change Type**: Content Update
- **Scope**: Restructure feature-tracking.md Implementation Status from last-completed to next-action statuses across ~40 files
- **Expected Completion**: 2026-04-25

## Content Changes

### Change Description

Replace the "last-completed" Implementation Status model in feature-tracking.md with a "next-action" model. Every status tells the reader which task to pick up next, rather than which milestone was last achieved. Requires updating status strings across ~40 files: scripts, task definitions, infrastructure docs, guides, state tracking, and context maps.

See [Proposal: PF-PRO-018](../../../proposals/structure-change-next-action-status-model-proposal.md) for full rationale, status mapping, and task modification details.

### Status Value Mapping

| Old Status | New Status | Emoji Change |
|-----------|-----------|-------------|
| ⬜ Not Started | ⬜ Needs Assessment | Same emoji |
| 📊 Assessment Created | 📋 Needs FDD (T2+) / 📝 Needs TDD (T1) | Tier-dependent |
| 📋 FDD Created | 📝 Needs TDD | Same emoji |
| 🏗️ Architecture Reviewed | _(removed from primary chain)_ | ADR column only |
| 📝 TDD Created | 🧪 Needs Test Spec | Same emoji |
| _(new)_ | 🔧 Needs Impl Plan | New status |
| 🟡 In Progress | 🟡 In Progress | No change |
| 🧪 Testing | _(merged into In Progress)_ | Removed |
| 👀 Ready for Review | 👀 Needs Review | Same emoji |
| 🟢 Completed | 🟢 Completed | No change |
| 🔄 Needs Revision | 🔄 Needs Enhancement | Same emoji |

### Affected Files — Scripts (14)

| File | Change Required | Status |
|------|----------------|--------|
| `scripts/Common-ScriptHelpers/FeatureTracking.psm1` | Status string matching | DONE |
| `scripts/file-creation/01-planning/New-Assessment.ps1` | Output: tier-dependent next-action | DONE |
| `scripts/file-creation/02-design/New-FDD.ps1` | Output: "Needs TDD" | DONE |
| `scripts/file-creation/02-design/New-TDD.ps1` | Output: "Needs Test Spec" | DONE |
| `scripts/file-creation/02-design/New-ArchitectureAssessment.ps1` | Remove primary status update | DONE |
| `scripts/update/Update-FeatureTrackingFromAssessment.ps1` | Tier-dependent routing | DONE |
| `scripts/update/Update-CodeReviewState.ps1` | Trigger/output labels | DONE |
| `scripts/update/Update-FeatureImplementationState.ps1` | Status transitions | DONE |
| `scripts/update/Update-FeatureRequest.ps1` | "Needs Enhancement" label | DONE |
| `scripts/update/Update-BatchFeatureStatus.ps1` | ValidateSet values | DONE |
| `scripts/update/Finalize-Enhancement.ps1` | Enhancement labels | DONE |
| `scripts/validation/Validate-StateTracking.ps1` | Valid status list | DONE |
| `scripts/Start-AutomationMenu.ps1` | Menu status references | DONE |
| `scripts/AUTOMATION-USAGE-GUIDE.md` | Documentation | DONE |

### Affected Files — Task Definitions (11)

| File | Change Required | Status |
|------|----------------|--------|
| `tasks/01-planning/feature-tier-assessment-task.md` | Output status | DONE |
| `tasks/01-planning/feature-request-evaluation.md` | Enhancement/new feature labels | DONE |
| `tasks/01-planning/system-architecture-review.md` | Remove from primary chain | DONE |
| `tasks/02-design/fdd-creation-task.md` | Output status | DONE |
| `tasks/02-design/tdd-creation-task.md` | Output status | DONE |
| `tasks/04-implementation/feature-enhancement.md` | Trigger label | DONE |
| `tasks/04-implementation/feature-implementation-planning-task.md` | Trigger/output statuses | DONE |
| `tasks/04-implementation/foundation-feature-implementation-task.md` | Output status | DONE |
| `tasks/06-maintenance/code-review-task.md` | Trigger/output statuses | DONE |
| `tasks/06-maintenance/code-refactoring-standard-path.md` | Status references | DONE |
| `tasks/00-setup/codebase-feature-analysis.md` | Status references | DONE |

### Affected Files — Infrastructure & Guides (4)

| File | Change Required | Status |
|------|----------------|--------|
| `infrastructure/task-trigger-output-traceability.md` | 26 status references | DONE |
| `infrastructure/process-framework-task-registry.md` | Status references | DONE |
| `guides/framework/task-transition-guide.md` | Status routing logic | DONE |
| `guides/support/state-file-creation-guide.md` | Status references | DONE |

### Affected Files — State Tracking & Visualization (8 active)

| File | Change Required | Status |
|------|----------------|--------|
| `doc/state-tracking/permanent/feature-tracking.md` | Legend + data rows + summary | DONE |
| `doc/state-tracking/permanent/feature-request-tracking.md` | Status references | DONE |
| `doc/state-tracking/features/6.1.1-Link Validation-implementation-state.md` | Parent status | DONE |
| `doc/state-tracking/validation/validation-tracking-3.md` | Status refs (if active) | DONE |
| `doc/state-tracking/validation/validation-tracking-4.md` | Status refs (if active) | DONE |
| `visualization/context-maps/00-setup/retrospective-documentation-creation-map.md` | Status refs | DONE |
| `visualization/context-maps/04-implementation/feature-enhancement-map.md` | Status refs | DONE |
| `visualization/context-maps/01-planning/feature-request-evaluation-map.md` | Status refs | DONE |

Archived files (skip — historical record): `validation-tracking-2.md` (archive), `validation-tracking-3.md` (archive), `enhancement-ignored-patterns-configuration.md` (old)

## Implementation Roadmap

### Phase 1: Core Update — feature-tracking.md + scripts (Session 1)
- [x] **Impact analysis**: Identified all ~40 affected files
  - **Status**: COMPLETED
- [x] **Proposal created**: PF-PRO-018
  - **Status**: COMPLETED
- [x] **Checkpoint**: Present proposal for approval
  - **Status**: COMPLETED
- [x] **Update feature-tracking.md**: Legend + data rows
  - **Status**: COMPLETED
- [x] **Update scripts**: All 14 script files
  - **Status**: COMPLETED
- [x] **Validate Phase 1**: Run Validate-StateTracking.ps1
  - **Status**: COMPLETED

### Phase 2: Task Definitions + Infrastructure (Session 1)
- [x] **Update task definitions**: All 11 task files
  - **Status**: COMPLETED
- [x] **Update infrastructure docs**: traceability + registry
  - **Status**: COMPLETED
- [x] **Update guides**: task-transition + state-file-creation
  - **Status**: COMPLETED

### Phase 3: State Tracking + Visualization + Cleanup (Session 1)
- [x] **Update active state tracking files**: 5 files + template + feature-dependencies
  - **Status**: COMPLETED
- [x] **Update context maps**: 3 files
  - **Status**: COMPLETED
- [x] **Update feature-tracking.md Progress Summary**: Reflect new status names
  - **Status**: COMPLETED
- [x] **Final validation**: Validate-StateTracking.ps1 — 0 errors
  - **Status**: COMPLETED

## Session Tracking

### Session 1: 2026-04-11
**Focus**: All 3 phases completed in single session
**Completed**:
- Impact analysis (grep-based, all categories)
- Proposal PF-PRO-018 created and filled
- State tracking file PF-STA-083 created and customized
- Phase 1: feature-tracking.md legend/rows + 14 scripts
- Phase 2: 11 task definitions + 2 infrastructure + 2 guides
- Phase 3: 5 state tracking files + 3 context maps + 1 template + 1 auto-generated
- Validation: Validate-StateTracking.ps1 — 0 errors
- Total files modified: ~42

**Issues/Blockers**:
- None

## State File Updates Required

- [x] **feature-tracking.md Update History**: Added v2.13 entry
  - **Status**: COMPLETED

## Completion Criteria

This file can be archived to `state-tracking/temporary/old/` when:

- [x] All content changes applied across ~42 files
- [x] Grep for old status patterns returns 0 hits (excluding archived/proposal files)
- [x] `Validate-StateTracking.ps1` passes with 0 errors
- [x] Feedback form completed
