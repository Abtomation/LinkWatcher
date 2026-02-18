---
id: PF-GDE-011
type: Documentation
version: 2.0
created: 2024-12-19
updated: 2025-07-28
---

# Temporary State File Customization Guide

## Document Metadata
| Metadata | Value |
|----------|-------|
| Document Type | Process Guide |
| Template Source | /doc/process-framework/templates/guide-template.mdd |
| Created Date | 2024-12-19 |
| Last Updated | 2025-07-28 |
| Version | 2.0 |
| Status | Active |
| Owner | BreakoutBuddies Team |
| Created By | AI Assistant |
| Source Documents | [temp-task-creation-state-template.md](../../templates/templates/temp-task-creation-state-template.md), [structure-change-state-template.md](../../templates/templates/structure-change-state-template.md) |
| Consumer Documents | [New Task Creation Process](../../tasks/support/new-task-creation-process.md), [Framework Extension Task](../../tasks/support/framework-extension-task.md), [Structure Change Task](../../tasks/support/structure-change-task.md) |
| Consumer Working Modes | Task Creation, Framework Extension, Structure Changes, Multi-Session Development |
| Governed By | /doc/process-framework/README.mdd |

## Overview

This guide helps you customize temporary state tracking files for different types of multi-session implementation work. It covers template selection, phase customization, and common adaptation patterns for various workflow types.

## Table of Contents

1. [Template Selection Guide](#template-selection-guide)
2. [Phase Customization Patterns](#phase-customization-patterns)
3. [Session Planning Strategies](#session-planning-strategies)
4. [Common Customization Examples](#common-customization-examples)
5. [Integration Best Practices](#integration-best-practices)
6. [Related Resources](#related-resources)

## Template Selection Guide

Choose the appropriate template based on your workflow type:

### Task Creation Workflows
**Use**: `temp-task-creation-state-template.md`
**Script**: `New-TempTaskState.ps1`
**Best For**:
- Creating new task definitions
- Framework extensions
- Adding new capabilities
- Building new infrastructure

**Characteristics**:
- Creates NEW artifacts (no rollback needed)
- 4-phase structure: Core → Infrastructure → Templates/Guides → Documentation
- Conditional Phase 2 for file-creating tasks
- Focus on artifact creation and integration

### Structure Change Workflows
**Use**: `structure-change-state-template.md`
**Script**: `New-StructureChangeState.ps1`
**Best For**:
- Reorganizing existing structure
- Migrating files or directories
- Changing documentation architecture
- Modifying existing templates

**Characteristics**:
- Modifies EXISTING artifacts (rollback essential)
- 5-phase structure: Preparation → Infrastructure → Pilot → Migration → Validation
- Built-in rollback planning and testing phases
- Focus on migration safety and validation

### Process Improvement Workflows
**Use**: `temp-task-creation-state-template.md` (with heavy customization)
**Script**: `New-TempTaskState.ps1`
**Best For**:
- Improving existing processes
- Enhancing framework capabilities
- Optimizing workflows
- Adding specialized tools

**Characteristics**:
- Adapts task creation phases to improvement workflow
- Phase 1: Problem analysis and solution design
- Phase 2: Implementation and testing
- Phase 3: Documentation and integration
- Phase 4: Validation and rollout

## Phase Customization Patterns

### Standard 4-Phase Pattern (Task Creation)
```markdown
Phase 1: Core Task Infrastructure
Phase 2: Document Creation Infrastructure (conditional)
Phase 3: Templates and Guides
Phase 4: Documentation and Visualization
```

### Migration 5-Phase Pattern (Structure Changes)
```markdown
Phase 1: Preparation & Proposal
Phase 2: Infrastructure Updates
Phase 3: Pilot Implementation
Phase 4: Full Migration
Phase 5: Validation & Cleanup
```

### Custom Phase Adaptations

#### For Process Improvements
```markdown
Phase 1: Problem Analysis & Solution Design
Phase 2: Implementation & Testing
Phase 3: Documentation & Integration
Phase 4: Validation & Rollout
```

#### For Framework Extensions
```markdown
Phase 1: Core Extension Infrastructure
Phase 2: Supporting Templates & Scripts
Phase 3: Usage Guides & Integration Documentation
Phase 4: Framework Integration & Testing
```

### Phase Customization Guidelines

1. **Rename Phases**: Adapt phase names to match your workflow
2. **Modify Checklists**: Customize checklist items for your specific needs
3. **Add/Remove Items**: Include only relevant tasks for your workflow
4. **Mark Conditional**: Use SKIPPED status for non-applicable phases
5. **Adjust Priorities**: Set HIGH/MEDIUM/LOW based on your requirements

## Session Planning Strategies

### Multi-Session Work Breakdown

#### Session 1: Foundation & Analysis
- **Focus**: Core infrastructure and requirements analysis
- **Typical Duration**: 30-60 minutes
- **Key Activities**:
  - Complete infrastructure analysis
  - Identify required artifacts and dependencies
  - Plan subsequent sessions
  - Create core components (task definitions, directories)

#### Session 2: Implementation Infrastructure
- **Focus**: Supporting infrastructure and automation
- **Typical Duration**: 45-90 minutes
- **Key Activities**:
  - Create document creation scripts (if needed)
  - Update ID registry
  - Set up directory structures
  - Build automation tools

#### Session 3: Content & Documentation
- **Focus**: Templates, guides, and documentation
- **Typical Duration**: 60-120 minutes
- **Key Activities**:
  - Create templates using established processes
  - Write usage guides
  - Document integration patterns
  - Test components

#### Session 4: Integration & Finalization
- **Focus**: System integration and completion
- **Typical Duration**: 30-60 minutes
- **Key Activities**:
  - Update documentation map
  - Create context maps
  - Complete feedback forms
  - Archive temporary state file

### Session Planning Best Practices

1. **Estimate Realistically**: Plan 30-120 minutes per session based on complexity
2. **Define Clear Objectives**: Each session should have specific, measurable goals
3. **Plan Dependencies**: Ensure prerequisites are completed before dependent work
4. **Document Progress**: Update state file after each session with progress and blockers
5. **Plan Next Steps**: Always end sessions with clear plan for next session

## Common Customization Examples

### Example 1: Task Creation with File Generation
**Scenario**: Creating a new task that generates TDD documents

**Template**: `temp-task-creation-state-template.md`

**Key Customizations**:
```markdown
### Phase 2: Document Creation Infrastructure (Session 2)
**Priority**: HIGH - Task creates TDD files

- [x] **Task Output Directory**: doc/product-docs/technical/design/tdds/
- [x] **Document Creation Script**: New-TDD.ps1
- [x] **ID Registry Update**: Add PD-TDD prefix
```

### Example 2: Framework Extension
**Scenario**: Adding AI-powered code analysis capability

**Template**: `temp-task-creation-state-template.md`

**Phase Customization**:
```markdown
### Phase 1: Core Extension Infrastructure
- [x] **Extension Concept Document**: Define AI analysis framework
- [x] **Task Definition**: Framework Extension Task

### Phase 2: Supporting Templates & Scripts
- [x] **Analysis Template**: Code analysis report template
- [x] **Generation Script**: New-CodeAnalysis.ps1

### Phase 3: Usage Guides & Integration Documentation
- [x] **Usage Guide**: How to perform AI-powered analysis
- [x] **Integration Guide**: Connecting with existing workflows

### Phase 4: Framework Integration & Testing
- [x] **AI Tasks Update**: Add to task registry
- [x] **Context Map**: Show analysis workflow relationships
```

### Example 3: Structure Change
**Scenario**: Reorganizing template directory structure

**Template**: `structure-change-state-template.md`

**Migration Planning**:
```markdown
### Affected Components Analysis
| Template | Current Location | New Location | Migration Method |
|----------|------------------|--------------|------------------|
| TDD Template | templates/tdd-template.md | templates/design/tdd-template.md | Manual move |
| API Template | templates/api-template.md | templates/technical/api-template.md | Script-assisted |

### Phase 3: Pilot Implementation
- [x] **Pilot Selection**: 3 templates representing different complexity levels
- [x] **Pilot Migration**: Move pilot templates to new structure
- [x] **Pilot Validation**: Test all references and links work correctly
```

### Example 4: Process Improvement
**Scenario**: Improving feedback collection process

**Template**: `temp-task-creation-state-template.md` (customized)

**Phase Adaptation**:
```markdown
### Phase 1: Problem Analysis & Solution Design
- [x] **Problem Identification**: Feedback forms are inconsistent
- [x] **Solution Design**: Standardized feedback form template
- [x] **Impact Assessment**: Affects all task definitions

### Phase 2: Implementation & Testing
- [x] **Template Creation**: New standardized feedback template
- [x] **Script Enhancement**: Update New-FeedbackForm.ps1
- [x] **Pilot Testing**: Test with 3 different task types

### Phase 3: Documentation & Integration
- [x] **Usage Guide**: How to use new feedback system
- [x] **Task Updates**: Update all task definitions to reference new template

### Phase 4: Validation & Rollout
- [x] **System Testing**: Verify all tasks work with new feedback system
- [x] **Documentation Map**: Update with new feedback components
```

## Integration Best Practices

### State File Management

1. **Regular Updates**: Update state file after each session with progress and blockers
2. **Clear Status Tracking**: Use consistent status values (NOT_STARTED, IN_PROGRESS, COMPLETED, SKIPPED)
3. **Dependency Management**: Clearly document dependencies between phases and components
4. **Session Planning**: Always end sessions with clear objectives for next session

### Framework Integration

1. **Follow Established Processes**: Use existing scripts (New-Task.ps1, New-Template.ps1, etc.) rather than manual creation
2. **Update State Files**: Keep documentation map, process improvement tracking, and other state files current
3. **Maintain Consistency**: Follow existing naming conventions and directory structures
4. **Complete Feedback Forms**: Always complete feedback forms for process improvement

### Quality Assurance

1. **Test Integration**: Verify new components work with existing framework
2. **Validate Links**: Ensure all cross-references and links are correct
3. **Check Dependencies**: Confirm all dependencies are properly documented and available
4. **Archive Properly**: Move completed state files to `temporary/old/` directory

### Common Pitfalls to Avoid

1. **Skipping Phases**: Don't skip phases without marking them as SKIPPED with rationale
2. **Manual Creation**: Avoid creating templates, guides, or scripts manually - use established processes
3. **Incomplete Documentation**: Don't leave placeholder content without implementation plans
4. **Missing Updates**: Always update documentation map and other state files
5. **Premature Archival**: Don't archive state files until ALL completion criteria are met

## Related Resources

### Templates
- [Temporary Task Creation State Template](../../templates/templates/temp-task-creation-state-template.md) - For task creation workflows
- [Structure Change State Template](../../templates/templates/structure-change-state-template.md) - For structure change workflows

### Scripts
- [New-TempTaskState.ps1](../../scripts/file-creation/New-TempTaskState.ps1) - Creates task creation state files
- [New-StructureChangeState.ps1](../../scripts/file-creation/New-StructureChangeState.ps1) - Creates structure change state files

### Task Definitions
- [New Task Creation Process](../../tasks/support/new-task-creation-process.md) - Primary consumer of task creation template
- [Framework Extension Task](../../tasks/support/framework-extension-task.md) - Uses task creation template with customization
- [Structure Change Task](../../tasks/support/structure-change-task.md) - Uses specialized structure change template
- [Process Improvement Task](../../tasks/support/process-improvement-task.md) - Uses task creation template with heavy customization

### Supporting Guides
- [Task Creation Guide](task-creation-guide.md) - For creating task definitions
- [Template Development Guide](template-development-guide.md) - For creating templates
- [Document Creation Script Development Guide](document-creation-script-development-guide.md) - For creating automation scripts
- [Feedback Form Completion Instructions](feedback-form-completion-instructions.md) - For completing feedback forms
