---
id: PF-GDE-026
type: Document
category: General
version: 1.0
created: 2025-07-27
updated: 2025-07-27
guide_description: Guide for customizing state tracking file templates
guide_status: Active
guide_title: State File Creation Guide
related_tasks:
related_script: New-PermanentState.ps1
---

# State File Creation Guide

## Overview

This guide provides comprehensive instructions for creating and customizing state tracking files using the New-PermanentState.ps1 script and state-file-template.md. It helps you create systematic tracking for project components, ensuring consistent monitoring and status management across the development lifecycle.

## When to Use

Use this guide when you need to:

- Create new permanent state tracking files for project components
- Track ongoing status of features, bugs, technical debt, or processes
- Establish systematic monitoring for project elements
- Customize state tracking templates for specific project needs
- Ensure consistent state management across the framework

> **🚨 CRITICAL**: Always use the New-PermanentState.ps1 script to create state files - never create them manually. This ensures proper ID assignment and integration with the framework's state tracking system.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Background](#background)
3. [Template Structure Analysis](#template-structure-analysis) _(Optional - for template customization guides)_
4. [Customization Decision Points](#customization-decision-points) _(Optional - for template customization guides)_
5. [Step-by-Step Instructions](#step-by-step-instructions)
6. [Quality Assurance](#quality-assurance) _(Optional - for template customization guides)_
7. [Examples](#examples)
8. [Troubleshooting](#troubleshooting)
9. [Related Resources](#related-resources)

## Prerequisites

Before you begin, ensure you have:

- Access to PowerShell and the New-PermanentState.ps1 script in `doc/process-framework/state-tracking/`
- Understanding of what project component or process needs state tracking
- Familiarity with existing permanent state files in `doc/process-framework/state-tracking/permanent/`
- Knowledge of the tasks that will update this state file

- Understanding of the project's state tracking patterns and conventions

## Background

State tracking files are permanent records that monitor the ongoing status of project components, processes, and work items throughout the development lifecycle. They serve as the central source of truth for project state and enable systematic tracking of progress, issues, and improvements.

### Purpose of State Files

State files provide several critical functions:

- **Progress Monitoring**: Track implementation status of features, tasks, and improvements
- **Issue Management**: Monitor technical debt, bugs, and process issues
- **Process Coordination**: Enable tasks to understand current project state and determine next actions
- **Historical Record**: Maintain audit trail of changes and decisions over time
- **Cross-Session Continuity**: Preserve context between AI agent sessions and development cycles

### Types of State Files

The project uses several categories of permanent state files:

- **Feature Tracking**: Monitor feature implementation status and documentation requirements
- **Technical Debt Tracking**: Track identified technical debt items and remediation progress
- **Process Improvement Tracking**: Monitor process enhancement opportunities and implementations
- **Architecture Tracking**: Track architectural decisions and component relationships
- **Test Implementation Tracking**: Monitor test case implementation and coverage

### Integration with Tasks

State files are tightly integrated with the task framework - most tasks both read from and update relevant state files to maintain accurate project status and coordinate work across sessions.

## Template Structure Analysis

The state-file-template.md provides a standardized structure for all permanent state tracking files. Understanding each section helps you customize the template effectively for different tracking needs:

### Core Metadata Section

- **Document ID**: Automatically assigned (PF-STA-XXX format)
- **State Type**: Category of state being tracked (e.g., "Feature Implementation", "Technical Debt")
- **Tracking Scope**: Scope of what's being tracked (e.g., "Project-wide", "Component-specific")

### File Header and Description

**Purpose**: Provides clear context about what this state file tracks
**Customization**: Replace `[State File Name]` and `[what this file tracks]` with specific tracking purpose

### Status Legend Section

**Purpose**: Defines all possible status values and their meanings
**Critical customization area**: Must be tailored to the specific type of state being tracked
**Examples**:

- Feature tracking: Not Started, Assessment Created, TDD Created, In Progress, Testing, Complete
- Technical debt: Identified, Prioritized, In Progress, Resolved, Deferred
- Process improvement: Identified, Prioritized, In Progress, Completed, Rejected

### Main Content Section

**Purpose**: Contains the actual state tracking data in tabular format
**Standard columns**: ID, Name, Status, Last Updated, Notes
**Customization options**: Add domain-specific columns (Priority, Category, Effort, etc.)

### Tasks That Update This File Section

**Purpose**: Documents which tasks are responsible for updating this state file
**Critical for maintenance**: Ensures clear ownership and update responsibilities
**Integration point**: Links state file to the broader task framework

### Update History Section

**Purpose**: Provides audit trail of changes to the state file
**Maintenance requirement**: Must be updated whenever the state file is modified
**Format**: Date, Change description, Task/person responsible

## Customization Decision Points

When creating and customizing state tracking files, you'll face several critical decisions that impact the effectiveness of your state management:

### State Granularity Decision

**Decision**: What level of detail should be tracked in this state file?
**Options**:

- **High-level**: Track major milestones only (e.g., feature completion status)
- **Detailed**: Track sub-components and intermediate states (e.g., individual test cases)
- **Comprehensive**: Track all aspects including dependencies and blockers
  **Criteria**: Balance between useful detail and maintenance overhead
  **Impact**: Affects update frequency and usefulness for coordination

### Status Categories Decision

**Decision**: What status values are needed for this type of tracking?
**Criteria**:

- **Workflow-based**: Reflect actual work progression (Not Started → In Progress → Complete)
- **State-based**: Reflect current condition (Active, Inactive, Deprecated)
- **Priority-based**: Include priority levels (Critical, High, Medium, Low)
  **Impact**: Determines how effectively the state file supports decision-making

### Column Structure Decision

**Decision**: What additional columns beyond the standard set are needed?
**Standard columns**: ID, Name, Status, Last Updated, Notes
**Common additions**:

- **Priority**: For prioritization decisions
- **Category**: For grouping and filtering
- **Effort**: For resource planning
- **Dependencies**: For coordination
- **Owner**: For responsibility tracking
  **Impact**: Affects maintenance complexity and analytical capabilities

### Update Responsibility Decision

**Decision**: Which tasks should be responsible for updating this state file?
**Criteria**:

- **Primary tasks**: Tasks that directly work with the tracked items
- **Related tasks**: Tasks that need to coordinate with the tracked items
- **Management tasks**: Tasks that oversee the tracked domain
  **Impact**: Determines accuracy and timeliness of state information

### Integration Strategy Decision

**Decision**: How should this state file integrate with existing state files?
**Options**:

- **Standalone**: Independent tracking with minimal cross-references
- **Linked**: Cross-references to related state files
- **Hierarchical**: Parent-child relationships with other state files
  **Impact**: Affects coordination effectiveness and maintenance complexity

## Step-by-Step Instructions

### 1. Analyze State Tracking Requirements

1. **Identify what needs to be tracked**:

   - Determine the specific project component, process, or work items requiring state tracking
   - Review existing permanent state files to avoid duplication
   - Understand the lifecycle and workflow of items to be tracked

2. **Define tracking scope and granularity**:

   - Decide on the level of detail needed (high-level milestones vs. detailed sub-components)
   - Identify the key status transitions that need to be monitored
   - Consider the frequency of updates and maintenance overhead

3. **Identify integration points**:
   - Determine which tasks will read from this state file
   - Identify which tasks will be responsible for updating the state file
   - Consider relationships with existing state files

**Expected Result:** Clear understanding of state tracking requirements and integration needs

### 2. Create State File Using New-PermanentState.ps1

1. **Navigate to the state tracking directory**:

   ```powershell
   cd doc/process-framework/state-tracking
   ```

2. **Execute the New-PermanentState.ps1 script**:

   ```powershell
   # Basic usage
   .\New-PermanentState.ps1 -StateName "Component Integration Tracking"

   # With description and editor opening
   .\New-PermanentState.ps1 -StateName "API Development Status" -Description "Tracks the development status of API endpoints and integration points" -OpenInEditor
   ```

3. **Verify state file creation**:
   - Check the success message for the assigned ID (PF-STA-XXX)
   - Note the file path in `doc/process-framework/state-tracking/permanent/`
   - Confirm the basic template structure was applied

**Expected Result:** New state file created with proper ID assignment and basic template structure

### 3. Customize the Status Legend

1. **Define appropriate status values** for your tracking domain:

   ```markdown
   ## Status Legend

   | Status      | Description                                                 |
   | ----------- | ----------------------------------------------------------- |
   | Not Started | Component has been identified but development has not begun |
   | In Progress | Component is currently being developed                      |
   | Testing     | Component development is complete, undergoing testing       |
   | Complete    | Component is fully implemented and tested                   |
   | Blocked     | Component development is blocked by dependencies            |
   ```

2. **Add domain-specific status values** if needed:

   - For technical debt: Identified, Prioritized, In Progress, Resolved, Deferred
   - For features: Assessment Created, TDD Created, Implementation Started, Testing, Complete
   - For processes: Identified, Analyzed, Designed, Implemented, Validated

3. **Ensure status progression logic** makes sense:
   - Status values should reflect natural workflow progression
   - Consider terminal states (Complete, Rejected, Deferred)
   - Include blocked or error states if applicable

**Expected Result:** Comprehensive status legend tailored to the specific tracking domain

### 4. Customize Main Content Structure

1. **Design the tracking table** with appropriate columns:

   ```markdown
   ## [Main Content Section Name]

   | ID     | Name     | Status   | Priority   | Category   | Last Updated | Owner   | Notes   |
   | ------ | -------- | -------- | ---------- | ---------- | ------------ | ------- | ------- |
   | [ID_1] | [Item 1] | [STATUS] | [PRIORITY] | [CATEGORY] | [YYYY-MM-DD] | [OWNER] | [Notes] |
   ```

2. **Add domain-specific columns** as needed:

   - **Effort**: For resource planning (hours, days, story points)
   - **Dependencies**: For coordination tracking
   - **Target Date**: For deadline management
   - **Risk Level**: For risk assessment

3. **Populate initial entries** if known:
   - Add any existing items that should be tracked
   - Use consistent ID format (e.g., COMP-001, API-001, TD-001)
   - Include realistic status and priority values

**Expected Result:** Well-structured tracking table with appropriate columns and initial data

### 5. Document Task Integration

1. **Identify and document updating tasks**:

   ```markdown
   ## Tasks That Update This File

   The following tasks update this state file:

   - [Feature Implementation Task](../../tasks/04-implementation/feature-implementation-task.md): Updates status when features are completed
   - [Technical Debt Assessment Task](../../tasks/cyclical/technical-debt-assessment-task.md): Adds new debt items when identified
   ```

2. **Define update responsibilities**:

   - Specify which tasks add new entries
   - Identify which tasks update status values
   - Document which tasks archive or remove entries

3. **Create update procedures** for each task:
   - Define when updates should occur
   - Specify required information for updates
   - Include validation criteria for updates

**Expected Result:** Clear documentation of task integration and update responsibilities

### Validation and Testing

After completing the state file customization:

1. **Validate Template Structure**:

   - Ensure all placeholder text has been replaced with meaningful content
   - Verify that status legend covers all possible states
   - Check that column structure supports intended tracking needs
   - Confirm task integration documentation is complete

2. **Test Integration with Framework**:

   - Verify the state file can be referenced by related tasks
   - Check that the file location follows framework conventions
   - Test that cross-references to other state files work correctly
   - Confirm the file integrates with documentation management processes

3. **Review for Usability**:
   - Ensure the state file supports decision-making needs
   - Verify that maintenance overhead is reasonable
   - Check that the tracking granularity matches usage requirements
   - Confirm that the file provides value for project coordination

## Quality Assurance

[Optional section for template customization guides. Provide comprehensive quality assurance guidance including:

### Self-Review Checklist

- [ ] Template sections are properly customized
- [ ] All required fields are completed
- [ ] Customization aligns with task requirements
- [ ] Cross-references and links are correct
- [ ] Examples are relevant and accurate

### Validation Criteria

- Functional validation: Template works as intended
- Content validation: Information is accurate and complete
- Integration validation: Template integrates properly with related components
- Standards validation: Follows project conventions and standards

### Integration Testing Procedures

- Test template with related scripts and tools
- Verify workflow integration points
- Validate cross-references and dependencies
- Confirm compatibility with existing framework components]

## Examples

### Example 1: API Development Status Tracking

Creating a state file to track API endpoint development:

```powershell
# Navigate to state tracking directory
cd doc/process-framework/state-tracking

# Create the state file
.\New-PermanentState.ps1 -StateName "API Development Status" -Description "Tracks the development status of API endpoints and integration points" -OpenInEditor
```

**Customization approach:**

- **Status Legend**: Not Started, In Progress, Testing, Complete, Blocked, Deprecated
- **Main Content Columns**: ID, Endpoint, Status, Priority, Category, Target Date, Dependencies, Notes
- **Sample entries**: AUTH-001 (Login endpoint), USER-002 (Profile management), BOOK-003 (Booking creation)
- **Updating Tasks**: Feature Implementation Task, API Development Task, Integration Testing Task

**Result:** Comprehensive API tracking that supports development coordination and progress monitoring

### Example 2: Component Integration Tracking

Creating a state file for tracking system component integration:

```powershell
# Create component integration tracking
.\New-PermanentState.ps1 -StateName "Component Integration Tracking" -Description "Tracks integration status between system components"
```

**Customization approach:**

- **Status Legend**: Planned, In Progress, Testing, Integrated, Failed, Deferred
- **Main Content Columns**: ID, Integration Point, Status, Components, Risk Level, Last Updated, Notes
- **Integration focus**: Authentication-Database, UI-Backend, Payment-Booking, Notification-User
- **Updating Tasks**: Architecture Review Task, Integration Testing Task, System Testing Task

**Result:** Clear visibility into system integration progress and potential bottlenecks

## Troubleshooting

### State File Not Created in Expected Location

**Symptom:** Script reports success but state file cannot be found in permanent directory

**Cause:** Script path issues or directory permissions problems

**Solution:**

1. Ensure you're running from `doc/process-framework/state-tracking/` directory
2. Check that the `permanent/` subdirectory exists and is writable
3. Verify the full path reported in the success message
4. If directory is missing, create it: `New-Item -ItemType Directory -Path "permanent" -Force`

### Status Legend Doesn't Match Workflow

**Symptom:** Status values don't reflect actual work progression or decision needs

**Cause:** Insufficient analysis of tracking requirements or workflow understanding

**Solution:**

1. Review existing state files for similar tracking domains
2. Map out the actual workflow or lifecycle of tracked items
3. Interview stakeholders about decision points and information needs
4. Revise status legend to match real workflow progression
5. Update any existing entries to use new status values

### State File Updates Not Happening

**Symptom:** State file becomes outdated with tasks not updating it as expected

**Cause:** Unclear update responsibilities or missing task integration

**Solution:**

1. Review the "Tasks That Update This File" section for completeness
2. Verify that identified tasks actually reference this state file
3. Add explicit update steps to relevant task documentation
4. Create update procedures or checklists for complex updates
5. Consider adding the state file to task completion checklists

## Related Resources

- [New-PermanentState.ps1 Script](../../scripts/file-creation/New-PermanentState.ps1) - Script for creating state files
- [State File Template](../../templates/templates/state-file-template.md) - Template customized by this guide
- [Existing Permanent State Files](../../state-tracking/permanent/) - Examples of implemented state tracking
- [Feature Tracking (PF-STA-001)](../../state-tracking/permanent/feature-tracking.md) - Example feature state tracking
- [Technical Debt Tracking (PF-STA-002)](../../state-tracking/permanent/technical-debt-tracking.md) - Example technical debt tracking
- [Process Improvement Tracking (PF-STA-003)](../../state-tracking/permanent/process-improvement-tracking.md) - Example process tracking
- [Guide Creation Best Practices Guide (PF-GDE-024)](guide-creation-best-practices-guide.md) - Best practices for guide creation

<!--
TEMPLATE USAGE GUIDANCE:

ENHANCED METADATA:
- related_script: Include if this guide helps customize templates created by a specific script
- related_tasks: Include task IDs that this guide supports (comma-separated)
- These fields enhance traceability and make guides easier to discover and maintain

TEMPLATE CUSTOMIZATION GUIDE SECTIONS:
For guides that help customize templates created by scripts, use these optional sections:
- Template Structure Analysis: Break down the template structure and explain each section
- Customization Decision Points: Guide users through key customization decisions
- Validation and Testing: Include within Step-by-Step Instructions for testing procedures
- Quality Assurance: Provide comprehensive QA guidance with checklists and validation criteria

GENERAL GUIDE SECTIONS:
All guides use the standard sections: Overview, When to Use, Prerequisites, Background,
Step-by-Step Instructions, Examples, Troubleshooting, Related Resources
-->
