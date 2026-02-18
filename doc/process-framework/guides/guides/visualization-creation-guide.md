---
id: PF-GDE-014
type: Process Framework
category: Guide
version: 1.0
created: 2025-07-11
updated: 2025-07-27
related_script: New-ContextMap.ps1
related_tasks: PF-TSK-001
---

# Visualization Creation Guide

## Purpose

This guide provides comprehensive instructions for creating visualizations in the BreakoutBuddies project, specifically context maps and other visual documentation that helps understand component relationships and task execution flows.

## When to Use

Use this guide when you need to:

- Create context maps for new tasks
- Visualize component relationships and dependencies
- Document complex workflows or processes
- Create visual aids for understanding system architecture
- Support task execution with clear visual context

## Prerequisites

Before creating visualizations, ensure you have:

- Understanding of the task or process being visualized
- Access to the relevant components and their relationships
- Familiarity with the project's visual notation standards
- PowerShell execution permissions for automation scripts

## Types of Visualizations

### 1. Context Maps

**Purpose**: Show the relationships between components, files, and resources needed for task execution.

**When to Create**:

- For every new task definition
- When task context becomes complex
- When multiple components interact in non-obvious ways

**Creation Process**:

```powershell
# Navigate to visualization directory
cd doc/process-framework/visualization

# Create new context map
..\..\scripts\file-creation\New-ContextMap.ps1 -TaskName "Your Task Name" -TaskType "Discrete|Cyclical|Continuous|Support" -MapDescription "Brief description"
```

### 2. Process Flow Diagrams

**Purpose**: Illustrate the sequence of steps in a process or workflow.

**When to Create**:

- For complex multi-step processes
- When decision points need clarification
- When parallel activities occur

### 3. Component Relationship Diagrams

**Purpose**: Show how different system components interact and depend on each other.

**When to Create**:

- For architectural documentation
- When component dependencies are complex
- When integration points need clarification

## Context Map Creation Process

### Step 1: Analyze the Task

Before creating a context map:

1. **Identify all components** involved in the task
2. **Understand relationships** between components
3. **Determine critical vs. optional** context
4. **Map dependencies** and prerequisites

### Step 2: Use the Creation Script

```powershell
# Basic context map creation
..\..\scripts\file-creation\New-ContextMap.ps1 -TaskName "Feature Implementation" -TaskType "Discrete" -MapDescription "Context map showing all components needed for feature implementation"

# Create and open in editor
..\..\scripts\file-creation\New-ContextMap.ps1 -TaskName "Bug Fixing" -TaskType "Discrete" -MapDescription "Context map for bug fixing workflow" -OpenInEditor
```

### Step 3: Complete the Context Map

Fill in the generated template with:

#### Context Components

List all files, resources, and information needed:

```markdown
- **Critical (Must Read):**
  - [File Name](path/to/file.md) - Brief description of why it's critical
- **Important (Load If Space):**
  - [File Name](path/to/file.md) - Description of its importance
- **Reference Only (Access When Needed):**
  - [File Name](path/to/file.md) - When and why to access
```

#### Component Relationships

Show how components interact:

```markdown
[Component A] → [Component B] (relationship type)
[Component B] ↔ [Component C] (bidirectional relationship)
```

#### Context Flow

Document the sequence of context loading:

```markdown
1. Load critical components first
2. Assess space for important components
3. Access reference components as needed during execution
```

### Step 4: Integrate with Task Definition

Update the related task definition to reference the context map:

```markdown
## Context Requirements

[View Context Map for this task](../../../visualization/context-maps/[task-type]/[task-name]-map.md)
```

## Visual Notation Standards

### Component Types

- 📄 **Documents**: Files that contain information
- 🔧 **Tools**: Scripts, applications, or utilities
- 📊 **Data**: Databases, state files, or data sources
- 🎯 **Processes**: Workflows or procedures
- 👤 **Actors**: People or roles involved

### Relationship Types

- `→` **Depends on**: Component A requires Component B
- `↔` **Interacts with**: Bidirectional relationship
- `⚡` **Triggers**: Component A causes Component B to activate
- `📝` **Updates**: Component A modifies Component B
- `🔍` **References**: Component A reads from Component B

### Priority Levels

- 🔴 **Critical**: Must have for task execution
- 🟡 **Important**: Valuable but not essential
- 🟢 **Optional**: Nice to have or reference only
- ⚪ **Conditional**: Needed only in specific scenarios

## Best Practices

### 1. Keep It Simple

- Focus on essential relationships
- Avoid overwhelming detail
- Use clear, concise descriptions

### 2. Maintain Consistency

- Use standard notation across all visualizations
- Follow established naming conventions
- Keep formatting consistent

### 3. Update Regularly

- Review visualizations when components change
- Update relationships when dependencies evolve
- Archive outdated visualizations

### 4. Test Usability

- Verify that visualizations help task execution
- Get feedback from users
- Refine based on actual usage

## Integration with Task System

### Context Map Requirements

Every task should have a context map that:

- Lists all required context components
- Prioritizes components by importance
- Shows relationships between components
- Provides guidance for context loading

### Linking to Tasks

Context maps should be:

- Referenced in task definitions
- Updated when tasks change
- Archived when tasks are deprecated
- Versioned with task versions

## Troubleshooting

### Common Issues

**Context map is too complex**

- Break down into multiple focused maps
- Use hierarchical organization
- Focus on most critical relationships

**Components keep changing**

- Use more generic component descriptions
- Focus on stable relationships
- Update maps more frequently

**Users ignore the visualizations**

- Simplify the visual presentation
- Make visualizations more actionable
- Integrate better with task workflows

## Enhanced Guide Creation for Template Customization

### Using Enhanced Metadata Fields

When creating guides for template customization (like guides for New-\* scripts), use the enhanced metadata fields:

```powershell
# Example: Creating a guide for a script that creates templates
.\New-Guide.ps1 -GuideTitle "Debt Item Creation Guide" -GuideDescription "Guide for customizing technical debt item templates" -RelatedScript "New-DebtItem.ps1" -RelatedTasks "PF-TSK-023"

# Example: Creating a guide related to multiple tasks
.\New-Guide.ps1 -GuideTitle "API Design Guide" -GuideDescription "Guide for API design templates" -RelatedScript "New-APISpecification.ps1" -RelatedTasks "PF-TSK-020,PF-TSK-021"
```

### Benefits of Enhanced Metadata

The enhanced metadata fields provide:

- **Traceability**: Clear connection between guides, scripts, and tasks
- **Context**: Better understanding of when and why to use the guide
- **Maintenance**: Easier identification of guides that need updates when scripts or tasks change
- **Discovery**: Better searchability and cross-referencing

### Template Customization Guide Structure

For guides that help customize templates created by scripts, follow this enhanced approach:

1. **Template Structure Analysis**: Explain the template sections and their purposes
2. **Customization Decision Points**: Guide users through key decisions
3. **Validation and Testing**: Provide methods to verify customized templates
4. **Integration Points**: Show how the customized template fits into the broader workflow

## Related Resources

- [Visual Notation Guide](visual-notation-guide.md) - Standard notation for all visualizations
- [Context Map Template](../../templates/templates/context-map-template.md) - Template for creating context maps
- [New-ContextMap.ps1](../../scripts/file-creation/New-ContextMap.ps1) - Script for creating context maps
- [Task Creation Guide](task-creation-guide.md) - How to integrate visualizations with tasks
- [Documentation Structure Guide](documentation-structure-guide.md) - Overall documentation organization

## Examples

### Simple Context Map

For a basic bug fixing task:

```
Critical Components:
- Bug report → Provides issue details
- Codebase → Contains code to fix
- Test suite → Validates fix

Flow:
1. Read bug report
2. Locate relevant code
3. Implement fix
4. Run tests
5. Verify resolution
```

### Complex Context Map

For a feature implementation task:

```
Critical Components:
- Feature specification ↔ Implementation guide
- Architecture docs → Design constraints
- API documentation → Integration requirements

Important Components:
- Similar features → Implementation patterns
- Test specifications → Validation approach

Reference Components:
- Style guide → When styling questions arise
- Performance benchmarks → When optimization needed
```
