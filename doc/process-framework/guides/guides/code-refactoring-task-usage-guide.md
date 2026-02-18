---
id: PF-GDE-020
type: Document
category: General
version: 1.0
created: 2025-07-21
updated: 2025-07-29
guide_description: Template customization guide for refactoring plan documents created by the Code Refactoring Task
guide_title: Refactoring Plan Template Customization Guide
guide_status: Active
related_script: New-RefactoringPlan.ps1
related_tasks: PF-TSK-022
---

# Refactoring Plan Template Customization Guide

## Overview

This guide provides comprehensive instructions for creating and customizing Refactoring Plan documents using the New-RefactoringPlan.ps1 script and refactoring-plan-template.md. It helps you create detailed refactoring plans that ensure systematic code improvement while preserving functionality.

## When to Use

Use this guide when you need to:

- Create comprehensive refactoring plans for code improvement initiatives
- Document refactoring scope, strategy, and success criteria
- Plan systematic technical debt reduction efforts
- Customize refactoring plan templates for different types of code improvements
- Ensure proper documentation of refactoring goals and implementation strategies

> **🚨 CRITICAL**: Always use the New-RefactoringPlan.ps1 script to create refactoring plans - never create them manually. This ensures proper ID assignment, metadata integration, and framework compatibility.

## Table of Contents

1. [Script Usage](#script-usage)
2. [Template Structure](#template-structure)
3. [Customization Guidelines](#customization-guidelines)
4. [Examples](#examples)
5. [Best Practices](#best-practices)
6. [Related Resources](#related-resources)

## Script Usage

### Creating a New Refactoring Plan

Use the New-RefactoringPlan.ps1 script to create refactoring plan documents:

```powershell
cd doc/process-framework/refactoring
./New-RefactoringPlan.ps1 -RefactoringScope "Brief description" -TargetArea "Component/Module name"
```

### Script Parameters

- **RefactoringScope** (Required): Brief description of what will be refactored
- **TargetArea** (Required): Specific component, module, or code area being refactored
- **Priority** (Optional): Priority level (High/Medium/Low) - defaults to Medium

### Example Script Usage

```powershell
# High-priority authentication service refactoring
./New-RefactoringPlan.ps1 -RefactoringScope "Authentication Service Simplification" -TargetArea "lib/services/auth/" -Priority "High"

# Database layer optimization
./New-RefactoringPlan.ps1 -RefactoringScope "Database Access Pattern Optimization" -TargetArea "lib/data/" -Priority "Medium"
```

## Template Structure

The refactoring plan template contains the following key sections that require customization:

### Metadata Section

- **refactoring_scope**: Brief description of the refactoring effort
- **target_area**: Specific code area or component being refactored
- **priority**: Priority level (High/Medium/Low)

### Core Content Sections

1. **Overview**: Summary of refactoring scope and basic information
2. **Refactoring Scope**: Detailed description, current issues, and goals
3. **Current State Analysis**: Baseline metrics and affected components
4. **Refactoring Strategy**: Approach, techniques, and implementation plan
5. **Testing Strategy**: Test coverage and testing approach during refactoring
6. **Success Criteria**: Quality improvements and functional requirements
7. **Implementation Tracking**: Progress log and results documentation

## Customization Guidelines

### 1. Refactoring Scope Section

**Current Issues Customization:**

- Document specific code smells, technical debt items, or quality problems
- Include measurable indicators (complexity scores, maintainability indices)
- Reference specific files, methods, or components with issues
- Link to technical debt assessments or code review findings

**Refactoring Goals Customization:**

- Set specific, measurable improvement targets
- Define clear success criteria for each goal
- Align goals with overall system architecture and quality standards
- Consider both immediate and long-term benefits

### 2. Current State Analysis

**Code Quality Metrics:**

- Use actual measurements from code analysis tools
- Include complexity scores, maintainability indices, test coverage percentages
- Document performance benchmarks if relevant
- Record technical debt assessments from previous evaluations

**Affected Components:**

- List all files, modules, or components that will be modified
- Include brief descriptions of each component's role
- Identify dependencies and integration points
- Assess risk levels for each component

### 3. Refactoring Strategy

**Approach Selection:**

- Choose appropriate refactoring techniques based on the specific issues
- Consider incremental vs. comprehensive refactoring approaches
- Plan for behavior preservation and testing strategies
- Account for system dependencies and integration requirements

**Implementation Plan Phases:**

- Break down refactoring into logical, testable phases
- Define specific actions for each phase
- Include testing and validation steps
- Plan for rollback strategies if issues arise

### 4. Testing Strategy

**Coverage Assessment:**

- Document existing test coverage for the target area
- Identify gaps in test coverage that need to be addressed
- Plan for additional tests if needed to ensure behavior preservation
- Define regression testing approach

**Testing During Refactoring:**

- Plan incremental testing after each change
- Define automated testing strategies
- Include manual testing for complex scenarios
- Plan for performance testing if relevant

## Examples

### Example 1: Authentication Service Refactoring Plan

**Template Customization for Complex Service Refactoring:**

```markdown
## Refactoring Scope

Simplify the authentication service by extracting responsibilities and improving code organization.

### Current Issues

- Single class handling authentication, token management, and user validation (SRP violation)
- Cyclomatic complexity of 15 in main authentication method
- Inconsistent error handling across authentication flows
- Duplicate token validation logic in multiple methods

### Refactoring Goals

- Extract token management into separate TokenService class
- Reduce main authentication method complexity to under 8
- Implement consistent error handling pattern using Result<T> type
- Eliminate duplicate token validation logic through shared utility methods
```

**Key Customization Points:**

- Specific complexity metrics (15 → under 8)
- Clear architectural improvements (SRP violation → separate services)
- Measurable outcomes (duplicate logic elimination)

### Example 2: Database Layer Optimization Plan

**Template Customization for Performance-Focused Refactoring:**

```markdown
## Current State Analysis

### Code Quality Metrics (Baseline)

- **Complexity Score**: 12.3 (High - target: under 8)
- **Code Coverage**: 65% (target: 85%+)
- **Performance**: Average query time 250ms (target: under 100ms)
- **Technical Debt**: 8 duplicate query methods identified

### Refactoring Strategy

### Specific Techniques

- **Extract Method**: Consolidate duplicate query logic into shared utilities
- **Strategy Pattern**: Implement query optimization strategies for different data types
- **Connection Pooling**: Replace direct connections with pooled connection manager
```

**Key Customization Points:**

- Specific performance metrics (250ms → under 100ms)
- Quantified technical debt (8 duplicate methods)
- Targeted refactoring techniques for the specific issues

## Best Practices

### Template Customization Best Practices

#### Be Specific and Measurable

- Use concrete metrics instead of vague descriptions
- Include baseline measurements and target improvements
- Reference specific files, methods, or components
- Set quantifiable success criteria

#### Plan Incrementally

- Break large refactoring efforts into smaller, manageable phases
- Define clear deliverables for each phase
- Include testing and validation steps in each phase
- Plan for rollback strategies if issues arise

#### Document Dependencies

- Identify all components that depend on the code being refactored
- Assess risk levels for each dependency
- Plan for integration testing of dependent components
- Consider impact on external APIs or interfaces

#### Align with Architecture

- Ensure refactoring goals align with overall system architecture
- Consider long-term maintainability and extensibility
- Review architectural patterns and design principles
- Consult with team members on architectural decisions

### Common Customization Patterns

#### Performance-Focused Refactoring

- Include specific performance metrics and targets
- Plan for performance testing and benchmarking
- Consider caching, optimization, and resource management
- Document expected performance improvements

#### Architecture-Focused Refactoring

- Emphasize design patterns and architectural principles
- Plan for interface changes and dependency management
- Consider impact on system modularity and coupling
- Document architectural improvements and rationale

#### Technical Debt-Focused Refactoring

- Reference specific technical debt items and assessments
- Prioritize high-impact debt reduction efforts
- Plan for code quality metric improvements
- Document debt reduction achievements

## Related Resources

- [Refactoring Plan Template](../../templates/templates/refactoring-plan-template.md) - Base template for creating refactoring plans
- [New-RefactoringPlan.ps1 Script](../../scripts/file-creation/New-RefactoringPlan.ps1) - Script for creating refactoring plan documents
- [Code Refactoring Task Definition](../../tasks/06-maintenance/code-refactoring-task.md) - Complete task definition and process
- [Technical Debt Assessment Task](../../tasks/cyclical/technical-debt-assessment-task.md) - For identifying refactoring targets
- [Template Development Guide](template-development-guide.md) - General guidance for customizing templates
- [Documentation Guide](documentation-guide.md) - Best practices for technical documentation
