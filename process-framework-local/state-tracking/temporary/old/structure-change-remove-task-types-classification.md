---
id: PF-STA-071
type: Document
category: General
version: 1.0
created: 2026-04-02
updated: 2026-04-02
change_name: remove-task-types-classification
---

# Structure Change State: Remove task_types classification

> **⚠️ TEMPORARY FILE**: This file tracks implementation of a content update structure change. Move to `process-framework-local/state-tracking/temporary/old` after all changes are validated.

## Structure Change Overview
- **Change Name**: Remove task_types classification
- **Change ID**: SC-009
- **Change Type**: Content Update
- **Scope**: Remove task_types concept from entire process framework: domain-config.json, script parameters, YAML frontmatter in task definitions and context maps, templates, and documentation
- **Expected Completion**: 2026-04-16

## Content Changes

### Change Description
Remove the `task_types` classification concept from the entire process framework. Task types (Discrete, Cyclical, Continuous, Support, Onboarding) duplicate what the directory structure already expresses — a task in `tasks/cyclical/` is inherently cyclical, making the metadata redundant. No script reads task_types from domain-config.json; scripts hardcode their own divergent copies. Removing this simplifies the framework with no loss of functionality.

### Affected Files

#### Group 1: Scripts (functional changes — HIGH priority)

| File | Change Required | Status |
|------|----------------|--------|
| `process-framework/scripts/file-creation/support/New-Task.ps1` | Remove `$TaskType` parameter, ValidateSet, switch-based section routing; replace with `$Phase`-based routing | DONE |
| `process-framework/scripts/file-creation/support/New-TempTaskState.ps1` | Remove `$TaskType` parameter, ValidateSet, template replacement, validation check | DONE |
| `process-framework/scripts/file-creation/06-maintenance/New-ReviewSummary.ps1` | Remove `$TaskTypeCount` parameter and template replacement | DONE |
| `process-framework/scripts/Common-ScriptHelpers/DocumentManagement.psm1` | Remove `"task_type"` from additional metadata fields and examples | DONE |

#### Group 2: Configuration

| File | Change Required | Status |
|------|----------------|--------|
| `process-framework/domain-config.json` | Remove `task_types` section entirely | DONE |

#### Group 3: Templates

| File | Change Required | Status |
|------|----------------|--------|
| `process-framework/templates/support/task-template.md` | Remove `task_type: "[TASK_TYPE]"` from frontmatter | DONE |
| `process-framework/templates/support/temp-task-creation-state-template.md` | Remove Task Type field and `-TaskType` from command examples | DONE |
| `process-framework/templates/support/tools-review-summary-template.md` | Remove "Task Types Covered" from metadata table | DONE |
| `process-framework/templates/support/framework-extension-concept-template.md` | Remove "Task Type" column from task table | DONE |

#### Group 4: Task definition YAML frontmatter (~50 files)

| File Pattern | Change Required | Status |
|------|----------------|--------|
| `process-framework/tasks/**/*.md` | Remove `task_type:` line from YAML frontmatter in all task definitions (55 files) | DONE |

#### Group 5: Context map YAML frontmatter (~20 files)

| File Pattern | Change Required | Status |
|------|----------------|--------|
| `process-framework/visualization/context-maps/**/*.md` | Remove `task_type:` line from YAML frontmatter in all context maps (21 files) | DONE |

#### Group 6: Documentation and guides

| File | Change Required | Status |
|------|----------------|--------|
| `process-framework/ai-tasks.md` | Remove "Task Types Explained" section, remove "Type" column from support tasks table | DONE |
| `process-framework/tasks/README.md` | Remove "Task Types" section, simplify task structure description | DONE |
| `process-framework/guides/support/task-creation-guide.md` | Remove "Task Types Overview" section, remove `-TaskType` from commands/examples | DONE |
| `process-framework/guides/support/visualization-creation-guide.md` | Remove `-TaskType` from command examples | DONE |
| `process-framework/tasks/support/new-task-creation-process.md` | Remove `-TaskType` from command examples | DONE |
| `process-framework/tasks/support/framework-extension-task.md` | Remove `-TaskType` from command example | DONE |
| `process-framework/tasks/support/framework-domain-adaptation.md` | Remove `task_types.values` reference and `-TaskType` from examples | DONE |
| `process-framework/tasks/06-maintenance/code-refactoring-standard-path.md` | Remove `-TaskType` from command example | DONE |
| `process-framework/tasks/support/tools-review-task.md` | Remove `-TaskTypeCount` from command example | DONE |
| `process-framework/guides/framework/terminology-guide.md` | Remove `task_type:` from metadata example | DONE |
| `process-framework/PF-documentation-map.md` | No changes needed — section headers already phase-based | N/A |

#### Group 7: Historical files (DO NOT CHANGE)

Completed feedback forms, archived state files, and process-improvement-tracking.md entries referencing task types are left as-is — they are historical records.

## Implementation Roadmap

### Phase 1: Preparation (Session 1)
- [x] **Identify all affected files** (grep for patterns, review references)
  - **Status**: COMPLETED
- [x] **Document changes** in Affected Files table above
  - **Status**: COMPLETED
- [x] **Checkpoint**: Present change plan to human partner for approval
  - **Status**: COMPLETED

### Phase 2: Scripts (Session 1) — HIGH priority, functional changes
- [x] **Update New-Task.ps1**: Remove `$TaskType` parameter, replace section routing with `$WorkflowPhase`-based logic
  - **Status**: COMPLETED
- [x] **Update New-TempTaskState.ps1**: Remove `$TaskType` parameter and related logic
  - **Status**: COMPLETED
- [x] **Update New-ReviewSummary.ps1**: Remove `$TaskTypeCount` parameter
  - **Status**: COMPLETED
- [x] **Update DocumentManagement.psm1**: Remove `task_type` metadata references
  - **Status**: COMPLETED
- [x] **Test scripts**: Verified New-Task.ps1 and New-TempTaskState.ps1 with `-WhatIf`
  - **Status**: COMPLETED

### Phase 3: Bulk metadata removal (Session 1)
- [x] **Remove `task_type:` from task definition frontmatter** (55 files)
  - **Status**: COMPLETED
- [x] **Remove `task_type:` from context map frontmatter** (21 files)
  - **Status**: COMPLETED
- [x] **Remove `task_types` from domain-config.json**
  - **Status**: COMPLETED

### Phase 4: Templates and documentation (Session 1)
- [x] **Update templates** (4 files): Remove task type placeholders and conditional sections
  - **Status**: COMPLETED
- [x] **Update documentation and guides** (10 files): Remove task type explanations, command examples, sections
  - **Status**: COMPLETED

### Phase 5: Validation & Finalization (Session 1)
- [x] **Validate**: Grep for residual `task_type` patterns — confirmed clean removal
  - **Status**: COMPLETED
- [x] **Update Documentation Map**: No changes needed — section headers already phase-based
  - **Status**: COMPLETED (N/A)
- [ ] **Feedback form**: Complete PF-TSK-014 feedback
  - **Status**: NOT_STARTED

## Session Tracking

### Session 1: 2026-04-02
**Start Time**: 14:35
**Focus**: Full execution — all 5 phases completed in single session
**Completed**:
- Scope assessment: Full process with Content Update variant (confirmed by human)
- Comprehensive grep for all task_type references across 70+ files
- Created state tracking file PF-STA-071
- Phase 2: Updated 4 scripts (New-Task.ps1, New-TempTaskState.ps1, New-ReviewSummary.ps1, DocumentManagement.psm1)
- Phase 3: Bulk removed task_type from 76 YAML frontmatter files + domain-config.json
- Phase 4: Updated 4 templates
- Phase 5: Updated 10 documentation/guide files, validated clean removal via grep

**Issues/Blockers**:
- None

**Total files modified**: ~94 files

## State File Updates Required

- [x] **Documentation Map**: No changes needed — section headers already phase-based
  - **Status**: COMPLETED (N/A)
- [x] **Process Improvement Tracking**: Not IMP-linked — no update needed
  - **Status**: COMPLETED (N/A)

## Completion Criteria

This file can be archived to `state-tracking/temporary/old/` when:

- [x] All content changes applied
- [x] Validation confirms no stale patterns remain
- [x] Documentation updated if needed
- [ ] Feedback form completed
