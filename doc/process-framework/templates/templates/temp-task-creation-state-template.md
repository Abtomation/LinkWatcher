---
id: PF-TEM-001
type: Process Framework
category: Template
version: 1.0
created: 2025-07-04
updated: 2025-07-04
task_name: [TASK-NAME]
---

# Temporary Task Creation State: [Task Name]

> **⚠️ TEMPORARY FILE**: This file tracks multi-session implementation of task creation infrastructure. Move to `doc/process-framework/state-tracking/temporary/old/` after all components are implemented.

## Task Overview

- **Task Name**: [Task Name]
- **Task Type**: [Discrete/Cyclical/Continuous/Support]
- **Task ID**: [To be assigned by ../New-Task.ps1]

## Infrastructure Analysis

### Required Artifacts

List all artifacts needed for this task:

| Artifact Type | Name                 | Status                      | Priority          | Notes   |
| ------------- | -------------------- | --------------------------- | ----------------- | ------- |
| Directory     | [directory-name]     | [NEEDED/EXISTS]             | [HIGH/MEDIUM/LOW] | [Notes] |
| Template      | [template-name.md]   | [NEEDED/EXISTS/PLACEHOLDER] | [HIGH/MEDIUM/LOW] | [Notes] |
| Guide         | [guide-name.md]      | [NEEDED/EXISTS/PLACEHOLDER] | [HIGH/MEDIUM/LOW] | [Notes] |
| Script        | [script-name.ps1]    | [NEEDED/EXISTS/PLACEHOLDER] | [HIGH/MEDIUM/LOW] | [Notes] |
| State File    | [state-file-name.md] | [NEEDED/EXISTS/PLACEHOLDER] | [HIGH/MEDIUM/LOW] | [Notes] |

### Available for Reuse

List existing artifacts that can be reused:

| Artifact        | Location | Reuse Notes            |
| --------------- | -------- | ---------------------- |
| [artifact-name] | [path]   | [How it can be reused] |

## Implementation Roadmap

### Phase 1: Core Task Infrastructure (Session 1)

**Priority**: HIGH - Must complete before task can be used

- [ ] **Task Definition File**: Create using New-Task.ps1 and task-creation-guide.md

  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
  - **Dependencies**: Task concept finalized, task creation guide reviewed
  - **Guide**: [Task Creation Guide](../../guides/guides/task-creation-guide.md)
  - **Script**: `doc/process-framework/tasks/New-Task.ps1`
  - **Command**: `cd doc/process-framework/tasks && .\New-Task.ps1 -TaskName "[Task Name]" -TaskType "[Discrete/Cyclical/Continuous/Support]" -Description "[Brief description]"`
  - **Notes**: This creates the core task definition file with proper ID assignment

- [ ] **Evaluate Task File Creation Requirements**: Determine if task creates new files as outputs
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
  - **Decision**: [CREATES_FILES/NO_FILES_CREATED]
  - **File Types**: [List types of files the task will create, if any]
  - **Notes**: This decision determines if document creation infrastructure is needed

### Phase 2: Document Creation Infrastructure (Session 2)

**Priority**: HIGH - Only execute if Phase 1 determined CREATES_FILES

> **⚠️ CONDITIONAL PHASE**: Only execute if task creates new files as outputs

- [ ] **Task Output Directory**: Create directory structure for task outputs

  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED/SKIPPED]
  - **Dependencies**: Task definition completed, file types identified
  - **Directories**: [List specific directories needed - include full paths with subdirectories, e.g., doc/product-docs/technical/api/specifications/specifications/]
  - **Command**: `mkdir -p [directory-path]` or manual creation
  - **Notes**: Create the directory where task outputs will be stored. Consider using subdirectories for better organization of different file types.

- [ ] **Document Creation Script**: Create script for generating new files using document-creation-script-development-guide.md and document-creation-script-template.ps1

  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED/SKIPPED]
  - **Dependencies**: Task definition completed, directory structure created
  - **Guide**: [Document Creation Script Development Guide](../../guides/guides/document-creation-script-development-guide.md)
  - **Template**: [Document Creation Script Template](../templates/document-creation-script-template.ps1)
  - **Location**: [Where the script will be placed - e.g., doc/process-framework/[category]/New-[ScriptName].ps1]
  - **Notes**: Script that generates files created by the task

- [ ] **ID Registry Update**: Update doc/id-registry.json with new ID prefix for file types
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED/SKIPPED]
  - **Dependencies**: Understanding of what file types the task will create
  - **File**: `doc/id-registry.json`
  - **New Prefix**: [e.g., PF-XXX or PD-XXX]
  - **Directory Mapping**: [Directory where files will be stored - include subdirectories if needed, e.g., doc/product-docs/technical/api/specifications/specifications]
  - **Notes**: Add new prefix entry with appropriate directory mapping. Use subdirectories for better organization when task creates multiple file types.

### Phase 3: Templates and Guides (Session 3)

**Priority**: MEDIUM - Needed for full functionality

- [ ] **Task-Specific Template**: Create template using template-development-guide.md and New-Template.ps1

  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED/SKIPPED]
  - **Dependencies**: Understanding of file structure needed, document creation script completed (if applicable)
  - **Guide**: [Template Development Guide](../../guides/guides/template-development-guide.md)
  - **Script**: `doc/process-framework/templates/New-Template.ps1`
  - **Command**: `cd doc/process-framework/templates && .\New-Template.ps1 -TemplateName "[Template Name]" -TemplateDescription "[Description]" -DocumentPrefix "[ID-PREFIX]" -DocumentCategory "[Category]"`
  - **Notes**: Template for files generated by the task (only needed if task creates new file types)

- [ ] **Task Usage Guide**: Create guide using New-Guide.ps1 and documentation-guide.md
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
  - **Dependencies**: Task definition and core infrastructure completed
  - **Guide**: [Documentation Guide](../../guides/guides/documentation-guide.md)
  - **Script**: `doc/process-framework/guides/New-Guide.ps1`
  - **Command**: `cd doc/process-framework/guides && .\New-Guide.ps1 -GuideTitle "[Task Name] Usage Guide" -GuideDescription "Comprehensive guide for using the [Task Name] task effectively"`
  - **Notes**: Explains how to use the task effectively, always needed for new tasks

### Phase 4: Documentation and Visualization (Session 4)

**Priority**: MEDIUM - Needed for complete task integration

- [ ] **Documentation Map Update**: Update documentation-map.md with all new artifacts

  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
  - **Dependencies**: All previous phases completed, all artifacts created
  - **File**: `doc/process-framework/documentation-map.md`
  - **Artifacts to Add**: [List all new files created: task definition, scripts, templates, guides, context map]
  - **Notes**: Register all new artifacts and their relationships in the documentation map

- [ ] **Context Map Visualization**: Create context map visualization for the task
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
  - **Dependencies**: Task definition completed, all components identified
  - **Guide**: [Visualization Creation Guide](../../guides/guides/visualization-creation-guide.md)
  - **Script**: `doc/process-framework/scripts/file-creation/New-ContextMap.ps1`
  - **Template**: [Context Map Template](../templates/context-map-template.md)
  - **Command**: `cd doc/process-framework/visualization && ..\scripts\file-creation\New-ContextMap.ps1 -TaskName "[Task Name]" -TaskType "[Type]" -MapDescription "Context map for [Task Name] task"`
  - **Notes**: Shows component relationships and context requirements for the task

## Session Tracking

### Session 1: [YYYY-MM-DD]

**Focus**: [Session focus]
**Completed**:

- [List completed items]

**Issues/Blockers**:

- [List any issues encountered]

**Next Session Plan**:

- [Plan for next session]

### Session 2: [YYYY-MM-DD]

**Focus**: [Session focus]
**Completed**:

- [List completed items]

**Issues/Blockers**:

- [List any issues encountered]

**Next Session Plan**:

- [Plan for next session]

## Placeholder Components Created

### Templates with PLACEHOLDER Status

| Template           | Location | Placeholder Content | Implementation Priority |
| ------------------ | -------- | ------------------- | ----------------------- |
| [template-name.md] | [path]   | [Brief description] | [HIGH/MEDIUM/LOW]       |

### Guides with PLACEHOLDER Status

| Guide           | Location | Placeholder Content | Implementation Priority |
| --------------- | -------- | ------------------- | ----------------------- |
| [guide-name.md] | [path]   | [Brief description] | [HIGH/MEDIUM/LOW]       |

### Scripts with PLACEHOLDER Status

| Script            | Location | Placeholder Content | Implementation Priority |
| ----------------- | -------- | ------------------- | ----------------------- |
| [script-name.ps1] | [path]   | [Brief description] | [HIGH/MEDIUM/LOW]       |

## State File Updates Required

Track which state files need updates as components are implemented:

- [ ] **Documentation Map**: Add new artifacts

  - **Status**: [PENDING/COMPLETED]
  - **Items to Add**: [List items]

- [ ] **AI Tasks Registry**: Add new task
  - **Status**: [PENDING/COMPLETED]
  - **Task Entry**: [Task details]

## Completion Criteria

This temporary state file can be moved to `doc/process-framework/state-tracking/temporary/old/` when:

- [ ] All HIGH priority components are implemented (not placeholders)
- [ ] Task definition is complete and functional
- [ ] All state files are updated
- [ ] Documentation map reflects all new artifacts
- [ ] Feedback forms are completed for the task creation process

## Notes and Decisions

### Key Decisions Made

- [Decision 1]: [Rationale]
- [Decision 2]: [Rationale]

### Implementation Notes

- [Note 1]
- [Note 2]

### Future Considerations

- [Consideration 1]
- [Consideration 2]
