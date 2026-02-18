---
id: PF-GDE-024
type: Document
category: General
version: 1.1
created: 2025-07-27
updated: 2025-07-29
guide_status: Active
related_tasks:
guide_description: Best practices for creating effective guides within the task framework, including prevention of task usage guide anti-patterns
related_script: New-Guide.ps1
guide_title: Guide Creation Best Practices Guide
---

# Guide Creation Best Practices Guide

## Overview

This guide provides comprehensive best practices for creating effective guides within the BreakoutBuddies task framework. It covers both general guide creation principles and specialized approaches for template customization guides, ensuring consistency, quality, and framework integration.

## When to Use

Use this guide when you need to:

- Create a new guide using the New-Guide.ps1 script
- Customize the guide template for specific use cases
- Ensure your guide meets framework quality standards
- Create template customization guides for New-\* scripts
- Review and improve existing guides

> **🚨 CRITICAL**: All guides must follow the established guide template structure (PF-TEM-003) and use the New-Guide.ps1 script for creation to ensure proper ID assignment and metadata integration.

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

Before creating guides, ensure you have:

- Access to PowerShell and the New-Guide.ps1 script
- Understanding of the task framework structure and principles
- Familiarity with the guide template (PF-TEM-003) structure
- Knowledge of the specific domain or process you're documenting
- Access to related tasks, scripts, and templates you'll be referencing

## Background

The BreakoutBuddies project uses a structured approach to documentation through the task framework. Guides serve as instructional documents that help users accomplish specific objectives within this framework. There are two main types of guides:

### General Guides

Standard instructional guides that help users complete processes, understand concepts, or use tools effectively.

### Template Customization Guides

Specialized guides that help users customize templates created by New-\* scripts. These guides require additional sections and considerations to ensure effective template usage.

### Framework Integration

All guides must integrate properly with the task framework by:

- Using consistent terminology and structure
- Referencing related tasks and components appropriately
- Following established quality standards
- Supporting the overall framework objectives

## Template Structure Analysis

The guide template (PF-TEM-003) provides a flexible structure that supports both general guides and template customization guides:

### Core Template Sections

**Required for all guides:**

- **Metadata**: ID, type, category, version, dates, status
- **Overview**: Brief description of guide purpose and outcome
- **Prerequisites**: Required knowledge, tools, and access
- **Step-by-Step Instructions**: Detailed procedural guidance
- **Examples**: Real-world usage scenarios
- **Troubleshooting**: Common issues and solutions
- **Related Resources**: Links to relevant documentation

**Optional for general guides:**

- **When to Use**: Specific triggers and decision criteria
- **Background**: Contextual information and concepts

### Enhanced Sections for Template Customization Guides

**Additional optional sections:**

- **Template Structure Analysis**: Breakdown of template anatomy
- **Customization Decision Points**: Key choices and decision frameworks
- **Quality Assurance**: Comprehensive QA guidance with checklists
- **Validation and Testing**: Within Step-by-Step Instructions

### Enhanced Metadata Fields

- **related_script**: Links guide to the script that creates templates
- **related_tasks**: Connects guide to relevant task framework components

## Customization Decision Points

When creating guides, you must make several key decisions that impact effectiveness and framework integration:

### Guide Type Decision

**Decision**: General guide vs. Template customization guide
**Criteria**:

- Does this guide help customize templates created by a script? → Template customization guide
- Does this guide provide general instructional content? → General guide
  **Impact**: Determines which optional sections to include

> **🚨 CRITICAL ANTI-PATTERN**: Never create "task usage guides" that focus on task workflow execution. All guides must focus on artifact customization or general instructional content. Task workflows are documented in the task definitions themselves.

### Metadata Enhancement Decision

**Decision**: Whether to use enhanced metadata fields
**Criteria**:

- Is there a related script? → Include `related_script`
- Are there related tasks? → Include `related_tasks`
  **Impact**: Improves traceability and discoverability

### Section Inclusion Decision

**Decision**: Which optional sections to include
**Criteria**:

- Template customization guides: Include Template Structure Analysis, Customization Decision Points, Quality Assurance
- Complex processes: Include Background section
- Conditional usage: Include When to Use section
  **Impact**: Affects guide completeness and usability

### Detail Level Decision

**Decision**: Depth of instructional detail
**Criteria**:

- Process complexity
- Framework integration requirements
  **Impact**: Determines guide accessibility and effectiveness

### Guide Focus Decision (CRITICAL)

**Decision**: Artifact customization vs. Task workflow focus
**Criteria**:

- ✅ **CORRECT**: Guide helps users customize documents/artifacts created by scripts
- ✅ **CORRECT**: Guide provides general instructional content for processes
- ❌ **INCORRECT**: Guide explains how to execute task workflows step-by-step
- ❌ **INCORRECT**: Guide duplicates content already in task definitions
  **Impact**: Determines guide value and prevents framework redundancy

> **🚨 ANTI-PATTERN WARNING**: "Task usage guides" that focus on task execution workflows are redundant with task definitions and create maintenance overhead. Always focus on artifact customization or general instruction instead.

## Step-by-Step Instructions

### 1. Planning and Preparation

1. **Identify the guide purpose and scope**

   - Define what the guide will help users accomplish
   - Determine the target audience and their expertise level
   - Identify the specific process or concept to document

2. **Gather required information**

   - Collect all relevant documentation, scripts, and templates
   - Identify related tasks and framework components
   - Research existing guides for consistency patterns

3. **Determine guide type and structure**

   - Decide between general guide or template customization guide
   - Plan which optional sections to include
   - Identify required metadata fields

4. **Validate guide focus (CRITICAL)**
   - ✅ **VERIFY**: Guide focuses on artifact customization OR general instruction
   - ❌ **REJECT**: Guide explains task workflow execution (this belongs in task definitions)
   - ❌ **REJECT**: Guide duplicates existing task documentation
   - **Check**: Does a proper artifact customization guide already exist for this topic?

**Expected Result:** Clear understanding of guide scope, structure, and requirements with validated focus

### 2. Phase A - Structure Generation Using New-Guide.ps1

> **🚨 CRITICAL**: This phase creates only the STRUCTURAL FRAMEWORK. The guide is NOT functional until Phase B customization is completed.

1. **Navigate to the guides directory**

   ```powershell
   cd doc/process-framework/guides
   ```

2. **Execute the New-Guide.ps1 script with appropriate parameters**

   ```powershell
   # For general guides
   .\New-Guide.ps1 -GuideTitle "Your Guide Title" -GuideDescription "Brief description of guide purpose"

   # For template customization guides
   .\New-Guide.ps1 -GuideTitle "Template Creation Guide" -GuideDescription "Guide for customizing templates" -RelatedScript "New-ScriptName.ps1" -RelatedTasks "PF-TSK-XXX"
   ```

3. **Verify structure generation and ID assignment**
   - Confirm the guide file was created in the correct location
   - Verify the assigned ID and metadata fields
   - Check that the template structure is properly applied
   - ⚠️ **IMPORTANT**: Note that content is placeholder text requiring replacement

**Expected Result:** New guide file with proper ID, metadata, and template structure - REQUIRES EXTENSIVE CUSTOMIZATION

**Status After Phase A:** STRUCTURE_CREATED (Not ready for use)

### 3. Phase B - Content Customization and Development

> **🚨 CRITICAL**: This phase transforms the structural framework into a functional guide. ALL placeholder content must be replaced with comprehensive, actionable content.

1. **Replace ALL placeholder content systematically**

   - Replace `[Optional section...]` placeholders with actual content or remove sections
   - Replace `[Prerequisite 1]` style placeholders with specific requirements
   - Replace `[Detailed instruction]` placeholders with step-by-step procedures
   - Remove template guidance comments at the end of the file

2. **Develop comprehensive core sections**

   - **Overview**: Write clear, specific description of what the guide accomplishes
   - **When to Use**: Define specific triggers and decision criteria
   - **Prerequisites**: List concrete requirements with links to resources
   - **Background**: Add context information if needed for understanding

3. **Create detailed Step-by-Step Instructions**

   - Break complex processes into logical, actionable steps
   - Include specific code examples, commands, or screenshots
   - When other documents are referenced, provide the actual links to those documents
   - Provide concrete expected results for each major step
   - Add validation and testing procedures for template customization guides

4. **Develop practical Examples**

   - Use real-world scenarios from the actual project
   - Provide complete, working examples with actual commands/code
   - Include both common and edge cases where relevant
   - Test examples to ensure they work as documented

5. **Complete supporting sections**
   - **Troubleshooting**: Add common issues with symptoms, causes, and solutions
   - **Related Resources**: Provide actual links to relevant documentation

**Expected Result:** Fully functional guide with comprehensive, actionable content

**Status After Phase B:** CONTENT_COMPLETED (Ready for use)

### 4. Quality Assurance and Validation

1. **Perform self-review using the quality checklist**

   - Verify all required sections are complete and accurate
   - Check that examples work correctly
   - Ensure cross-references and links are valid
   - Confirm alignment with framework standards

2. **Test the guide instructions**

   - Follow your own guide step-by-step
   - Verify that all commands and procedures work as documented
   - Test examples in the actual project environment
   - Validate integration with related framework components

3. **Review framework integration**
   - Confirm proper use of terminology and conventions
   - Verify links to related tasks and resources
   - Check metadata accuracy and completeness
   - Ensure consistency with other guides

**Expected Result:** High-quality guide that meets framework standards and works correctly

### Validation and Testing

For template customization guides, include additional validation steps:

- **Template Testing**: Verify that following the guide produces functional templates
- **Script Integration**: Test that customized templates work with related scripts
- **Framework Compatibility**: Ensure templates integrate properly with task workflows
- **User Acceptance**: Validate that the guide helps users accomplish their objectives effectively

## Quality Assurance

Comprehensive quality assurance ensures guides meet framework standards and serve users effectively:

### Self-Review Checklist

**Content Quality:**

- [ ] Overview clearly explains guide purpose and outcome
- [ ] Prerequisites list all required knowledge and tools
- [ ] Step-by-step instructions are complete and accurate
- [ ] Examples are relevant, working, and helpful
- [ ] Troubleshooting addresses common issues
- [ ] Related resources are current and accessible

**Framework Integration:**

- [ ] Metadata fields are properly completed
- [ ] Terminology is consistent with framework standards
- [ ] Cross-references and links are correct and functional
- [ ] Guide aligns with related task objectives
- [ ] Structure follows the established template

**Template Customization Guides (Additional):**

- [ ] Template structure analysis is comprehensive
- [ ] Customization decision points are clearly explained
- [ ] Validation and testing procedures are included
- [ ] Quality assurance section provides actionable guidance

### Validation Criteria

**Functional Validation:**

- All instructions work correctly when followed
- Examples produce expected results
- Commands and code snippets execute properly
- Links and references are accessible

**Content Validation:**

- Information is accurate and up-to-date
- Instructions are clear and unambiguous
- Examples reflect real project scenarios
- Troubleshooting solutions are effective

**Integration Validation:**

- Guide integrates properly with related framework components
- Cross-references connect to correct resources
- Workflow integration points function correctly
- Compatibility with existing guides is maintained

**Standards Validation:**

- Follows project documentation conventions
- Uses consistent terminology and formatting
- Meets accessibility and usability standards
- Aligns with framework quality requirements

### Integration Testing Procedures

**For All Guides:**

- Test all instructions by following them step-by-step
- Verify examples work in the actual project environment
- Check that cross-references lead to correct resources
- Confirm guide helps users achieve stated objectives

**For Template Customization Guides:**

- Test template creation using the related script
- Verify customized templates work with related tools
- Validate integration with task workflows
- Confirm templates meet project standards

## Examples

### Example 1: Creating a General Guide

Creating a guide for API integration best practices:

```powershell
# Navigate to guides directory
cd doc/process-framework/guides

# Create the guide
.\New-Guide.ps1 -GuideTitle "API Integration Best Practices" -GuideDescription "Comprehensive guide for integrating third-party APIs in the BreakoutBuddies project"
```

**Customization approach:**

- Include When to Use section for specific integration scenarios
- Add Background section explaining API architecture concepts
- Focus on Step-by-Step Instructions with code examples
- Provide Examples for different API types (REST, GraphQL, etc.)
- Include comprehensive Troubleshooting for common integration issues

**Result:** A general guide that helps developers integrate APIs effectively

### Example 2: Creating a Template Customization Guide

Creating a guide for customizing debt item templates:

```powershell
# Navigate to guides directory
cd doc/process-framework/guides

# Create the template customization guide
.\New-Guide.ps1 -GuideTitle "Debt Item Creation Guide" -GuideDescription "Guide for customizing technical debt item templates" -RelatedScript "New-DebtItem.ps1" -RelatedTasks "PF-TSK-023"
```

**Customization approach:**

- Include Template Structure Analysis explaining debt item template sections
- Add Customization Decision Points for debt categorization and prioritization
- Develop Step-by-Step Instructions with Validation and Testing subsection
- Include Quality Assurance section with debt item-specific checklists
- Provide Examples for different types of technical debt

**Result:** A specialized guide that helps users create effective technical debt documentation

### Example 3: Avoiding Task Usage Guide Anti-Pattern

**❌ INCORRECT Approach - Task Usage Guide:**

```powershell
# DON'T DO THIS
.\New-Guide.ps1 -GuideTitle "Code Refactoring Task Usage Guide" -GuideDescription "How to execute the code refactoring task step-by-step"
```

**Problems with this approach:**

- Duplicates content already in the task definition
- Focuses on task workflow execution rather than artifact customization
- Creates maintenance overhead when task processes change
- Provides no additional value beyond the task definition

**✅ CORRECT Approach - Artifact Customization Guide:**

```powershell
# DO THIS INSTEAD
.\New-Guide.ps1 -GuideTitle "Refactoring Plan Customization Guide" -GuideDescription "Guide for customizing refactoring plan documents created by the Code Refactoring Task" -RelatedScript "New-RefactoringPlan.ps1" -RelatedTasks "PF-TSK-022"
```

**Benefits of this approach:**

- Focuses on customizing the refactoring plan document (artifact)
- Provides value beyond the task definition
- Helps users create better refactoring plans
- Avoids duplication with task workflow documentation

**Key Principle:** Always ask "Does this guide help users customize an artifact, or does it just repeat task workflow steps?" If it's the latter, either convert it to artifact customization focus or don't create it.

## Troubleshooting

### Guide Creation Script Fails

**Symptom:** New-Guide.ps1 script execution fails with permission or path errors

**Cause:** PowerShell execution policy restrictions or incorrect working directory

**Solution:**

1. Check PowerShell execution policy: `Get-ExecutionPolicy`
2. If restricted, set policy: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`
3. Ensure you're in the correct directory: `cd doc/process-framework/guides`
4. Verify script exists: `Test-Path .\New-Guide.ps1`

### Metadata Fields Not Populating

**Symptom:** Related script and task fields appear empty in created guide

**Cause:** Parameters not provided or incorrectly formatted in New-Guide.ps1 command

**Solution:**

1. Verify parameter syntax: `-RelatedScript "ScriptName.ps1" -RelatedTasks "PF-TSK-XXX"`
2. Check for typos in parameter names
3. Ensure task IDs are comma-separated for multiple tasks: `"PF-TSK-001,PF-TSK-002"`

### Guide Structure Inconsistencies

**Symptom:** Created guide doesn't match expected template structure

**Cause:** Guide template (PF-TEM-003) may be outdated or corrupted

**Solution:**

1. Verify guide template exists: `doc/process-framework/templates/templates/guide-template.md`
2. Check template version and update date
3. Compare with working guides to identify discrepancies
4. Regenerate guide if template issues are found

### Cross-References and Links Broken

**Symptom:** Links to related resources return 404 or file not found errors

**Cause:** Incorrect relative paths or moved/renamed files

**Solution:**

1. Verify target files exist at specified paths
2. Check relative path accuracy from guide location
3. Update links to reflect current file structure
4. Test all links before finalizing guide

### Guide Focuses on Task Workflow Instead of Artifact Customization

**Symptom:** Guide explains how to execute task steps rather than how to customize artifacts

**Cause:** Misunderstanding of guide purpose - creating "task usage guide" instead of artifact customization guide

**Solution:**

1. **STOP**: Do not create task usage guides - they duplicate task definitions
2. **CHECK**: Does a proper artifact customization guide already exist for this topic?
3. **CONVERT**: If needed, focus on customizing documents/artifacts created by the task
4. **REFERENCE**: Link to task definitions for workflow information instead of duplicating it

**Prevention:** Always validate guide focus during planning phase using the Guide Focus Decision criteria

## Related Resources

- [Guide Template (PF-TEM-003)](../../templates/templates/guide-template.md) - The base template for all guides
- [New-Guide.ps1 Script](../../scripts/file-creation/New-Guide.ps1) - Script for creating new guides with proper ID assignment

- [Visualization Creation Guide](visualization-creation-guide.md) - Example of enhanced metadata usage
- [Task Framework Overview](../../README.md) - Understanding the broader framework context

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
