---
id: PF-TSK-026
type: Process Framework
category: Task Definition
domain: agnostic
version: 1.0
created: 2025-07-26
updated: 2025-07-26
task_type: Support
---

# Framework Extension Task

## Purpose & Context

This task manages the systematic extension of the task-based development framework with entirely new functionalities, capabilities, or systematic approaches. It ensures that framework extensions are properly planned, implemented across multiple sessions, and integrated with existing framework components while maintaining consistency with established principles.

## AI Agent Role

**Role**: Framework Architect
**Mindset**: Extensibility-focused, component-oriented, integration-aware
**Focus Areas**: Framework design, component relationships, extensibility patterns, integration points
**Communication Style**: Consider framework evolution and component interactions, ask about long-term extensibility and integration requirements

## When to Use

- When adding entirely new framework capabilities (e.g., architecture framework, testing framework, deployment framework)
- When extending framework scope with new domains of functionality requiring multiple interconnected components
- When making systematic framework evolution that affects fundamental structure or capabilities
- When creating multi-component extensions requiring multiple new tasks, templates, guides, and infrastructure components working together
- When the extension requires more than just creating a single new task (use New Task Creation Process for single tasks)

## Context Requirements

[View Context Map for this task](../../visualization/context-maps/support/framework-extension-task-map.md)

- **Critical (Must Read):**

  - **Framework Extension Concept Document** - Human-provided concept document defining the extension scope, workflow, and integration strategy
  - [Framework Extension Customization Guide](../../guides/guides/framework-extension-customization-guide.md) - Essential guide for customizing Framework Extension Concept documents
  - [Task-Based Development Principles](../../../ai-tasks.md#understanding-task-based-development) - Understanding of framework principles for consistent extension
  - [New Task Creation Process](new-task-creation-process.md) - For creating individual tasks within the extension
  - [Visual Notation Guide](/doc/process-framework/guides/guides/visual-notation-guide.md) - For interpreting context map diagrams

- **Important (Load If Space):**

  - [Documentation Map](../../documentation-map.md) - For understanding current framework structure and updating with new artifacts
  - [Process Improvement Tracking](../../state-tracking/permanent/process-improvement-tracking.md) - For tracking framework capability enhancements
  - [New-TempTaskState.ps1](../../scripts/file-creation/New-TempTaskState.ps1) - Script for creating multi-session implementation tracking
  - [Template Development Guide](../../guides/guides/template-development-guide.md) - For creating extension-specific templates
  - [Document Creation Script Development Guide](../../guides/guides/document-creation-script-development-guide.md) - For creating automation scripts

- **Reference Only (Access When Needed):**
  - [ID Registry](../../../id-registry.json) - For adding new ID prefixes for extension-created file types
  - [Structure Change Task](structure-change-task.md) - For understanding structural modifications vs. extensions
  - [Process Improvement Task](process-improvement-task.md) - For understanding granular improvements vs. extensions

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished! 🚨**
>
> **⚠️ MANDATORY: Create comprehensive concept document and get human approval before implementation.**
>
> **📋 IMPORTANT: This is a multi-session task requiring temporary state tracking for implementation continuity.**

### Phase 1: Concept Development & Approval

1. **Create Framework Extension Concept Document** using the standardized script:
   ```powershell
   cd doc/process-framework/proposals
   ./New-FrameworkExtensionConcept.ps1 -ExtensionName "[Extension Name]" -ExtensionDescription "[Brief description]" -ExtensionScope "[Extension scope]" -OpenInEditor
   ```
   - Script creates structural template in `/doc/process-framework/proposals/proposals/[extension-name]-concept.md`
   - **CRITICAL**: Template requires extensive customization following [Framework Extension Customization Guide](../../guides/guides/framework-extension-customization-guide.md)
   - Define extension scope and new capabilities to be added
   - Specify workflow definition with clear input-process-output flow
   - Create artifact dependency map showing how new artifacts serve as inputs for subsequent tasks
   - Define state tracking integration strategy (new permanent state files vs. updating existing ones)
   - Include integration strategy with current framework workflow
2. **Present Concept for Human Review** - Get explicit approval before proceeding to implementation
3. **Analyze Framework Impact** - Document how the extension affects existing framework components

### Phase 2: State Tracking & Planning

4. **Create Temporary State Tracking File** using New-TempTaskState.ps1:
   ```powershell
   cd doc/process-framework/state-tracking
   ./New-TempTaskState.ps1 -TaskName "[Extension Name]" -TaskType "Support" -Description "Framework extension for [brief description]"
   ```
5. **Develop Implementation Roadmap** with detailed multi-session breakdown in the temporary state file
6. **Identify Required Components** (tasks, templates, guides, scripts, directories) and their dependencies
7. **Plan Integration Points** with existing framework components and state tracking files

### Phase 3: Multi-Session Implementation

8. **Execute Session-by-Session Implementation** following the detailed roadmap in temporary state tracking file:
   - **Session 1**: Core task definitions and primary infrastructure
   - **Session 2**: Supporting templates and document creation scripts
   - **Session 3**: Usage guides and integration documentation
   - **Session 4**: Framework integration and testing
9. **Progressive Component Creation** using two-phase document creation approach:
   - **Phase A - Structure Generation**: Use scripts (New-Task.ps1, New-Template.ps1, New-Guide.ps1) to generate basic document frameworks
     - ⚠️ **CRITICAL**: Script outputs are STARTING POINTS requiring extensive customization
     - Scripts create structural frameworks with placeholder content that MUST be replaced
   - **Phase B - Content Customization**: Follow best practices guides to fully customize generated structures
     - Templates require comprehensive content development following Template Development Guide
     - Guides require extensive customization following Guide Creation Best Practices Guide
     - Tasks require detailed process definition following Task Creation Guide
10. **Update Temporary State Tracking** after each session with progress and next steps
11. **Integration Testing** to ensure compatibility with existing framework components

### Phase 4: Framework Integration & Finalization

12. **Update Core Framework Files**:
    - Update [ai-tasks.md](../../../ai-tasks.md) with new tasks
    - Update [documentation-map.md](../../documentation-map.md) with all new artifacts
    - Update [id-registry.json](../../../id-registry.json) with new ID prefixes if needed
13. **Create Usage Documentation** demonstrating how to use the new framework extension
14. **Update Permanent State Files** as defined in the concept document
15. **Archive Temporary State Tracking** file to `/doc/process-framework/state-tracking/temporary/old/`
16. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Outputs

### Concept Phase Outputs

- **Framework Extension Concept Document** - Comprehensive proposal in `/doc/process-framework/proposals/proposals/[extension-name]-concept.md` including workflow definition, artifact dependency map, and state tracking integration plan
- **Impact Analysis** - Documentation of how the extension affects existing framework components

### Implementation Phase Outputs

- **New Task Definitions** - Multiple interconnected tasks with clear input requirements, process workflows, and output specifications
- **Supporting Infrastructure** - Templates, guides, scripts, and directories for extension functionality
- **Integration Documentation** - Documentation showing how the extension works with existing framework workflow
- **Updated Core Framework Files** - Modified ai-tasks.md, documentation-map.md, and id-registry.json

### State Tracking Outputs

- **Temporary State Tracking File** - Multi-session implementation tracker with detailed roadmap and progress tracking
- **Updated Permanent State Files** - Enhanced existing state files or new permanent state files as defined in concept

## State Tracking

The following state files must be updated as part of this task:

- **Temporary State Tracking File** - Create using New-TempTaskState.ps1 to track multi-session implementation progress
- [Documentation Map](../../documentation-map.md) - Update with all new artifacts and their relationships
- [Process Improvement Tracking](../../state-tracking/permanent/process-improvement-tracking.md) - Update with framework capability enhancements
- **Additional State Files** - As defined in the framework extension concept document (may include new permanent state files or updates to existing ones)

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

> **Note**: This is a multi-session task. Complete verification applies to the ENTIRE extension across all sessions.

Before considering this task finished:

- [ ] **Verify Concept Phase**: Confirm concept development and approval completed

  - [ ] Framework extension concept document created using New-FrameworkExtensionConcept.ps1 script
  - [ ] Template extensively customized following Framework Extension Customization Guide
  - [ ] Comprehensive workflow definition with clear input-process-output flow
  - [ ] Artifact dependency map clearly shows how new artifacts serve as inputs for subsequent tasks
  - [ ] State tracking integration strategy defined (new permanent state files vs. updating existing ones)
  - [ ] Human approval obtained for concept before implementation

- [ ] **Verify Implementation Phase**: Confirm all extension components implemented using two-phase approach

  - [ ] **Phase A - Structure Generation**: All document structures generated using appropriate scripts
    - [ ] Task definitions created using New-Task.ps1 (structural framework only)
    - [ ] Templates created using New-Template.ps1 (structural framework only)
    - [ ] Guides created using New-Guide.ps1 (structural framework only)
  - [ ] **Phase B - Content Customization**: All generated structures fully customized
    - [ ] Task definitions contain detailed input-process-output specifications (not placeholder content)
    - [ ] Templates contain comprehensive customizable content (not placeholder sections)
    - [ ] Guides contain detailed step-by-step instructions and examples (not template boilerplate)
  - [ ] Integration documentation shows how extension works with existing framework
  - [ ] Multi-session implementation tracked in temporary state file with two-phase progress tracking

- [ ] **Verify Framework Integration**: Confirm extension properly integrated

  - [ ] [ai-tasks.md](../../../ai-tasks.md) updated with new tasks
  - [ ] [Documentation Map](../../documentation-map.md) updated with all new artifacts and relationships
  - [ ] [ID Registry](../../../id-registry.json) updated with new prefixes if needed
  - [ ] Permanent state files updated as defined in concept document

- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] Temporary state tracking file archived to `/doc/process-framework/state-tracking/temporary/old/`
  - [ ] [Documentation Map](../../documentation-map.md) reflects all new artifacts
  - [ ] [Process Improvement Tracking](../../state-tracking/permanent/process-improvement-tracking.md) updated with framework capability enhancement
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Completion Instructions](../../guides/guides/feedback-form-completion-instructions.md) for each tool used, using task ID "PF-TSK-026" and context "Framework Extension Task"

## Next Tasks

- [**Process Improvement Task**](process-improvement-task.md) - If further refinements are needed for the extension
- **Extension-Specific Tasks** - Use the newly created tasks that comprise the framework extension

## Related Resources

### Core Framework Resources

- [Task-Based Development Principles](../../../ai-tasks.md#understanding-task-based-development) - Understanding framework principles
- [New Task Creation Process](new-task-creation-process.md) - For creating individual tasks within extensions
- [Structure Change Task](structure-change-task.md) - For understanding structural modifications vs. extensions
- [Process Improvement Task](process-improvement-task.md) - For understanding granular improvements vs. extensions

### Development Infrastructure

- [Template Development Guide](../../guides/guides/template-development-guide.md) - For creating extension-specific templates
- [Document Creation Script Development Guide](../../guides/guides/document-creation-script-development-guide.md) - For creating automation scripts
- [Framework Extension Customization Guide](../../guides/guides/framework-extension-customization-guide.md) - For customizing Framework Extension Concept documents
- [Visualization Creation Guide](../../guides/guides/visualization-creation-guide.md) - For creating context maps

### State Management

- [New-TempTaskState.ps1](../../scripts/file-creation/New-TempTaskState.ps1) - Script for multi-session implementation tracking
- [Documentation Map](../../documentation-map.md) - Framework structure and artifact relationships
- [Process Improvement Tracking](../../state-tracking/permanent/process-improvement-tracking.md) - Framework capability tracking
