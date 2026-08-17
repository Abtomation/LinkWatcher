---
id: PF-GDE-024
type: Process Framework
category: Guide
version: 1.2
created: 2025-07-27
updated: 2026-07-13
related_script: New-Guide.ps1
description: "Best practices for creating effective guides within the task framework"
---

# Guide Creation Best Practices Guide

## Overview

This guide provides best practices for creating effective guides within the task framework — choosing the right guide shape, customizing the guide template (PF-TEM-003), and meeting framework quality standards.

## When to Use

Use this guide when you need to:

- Create a new guide using the New-Guide.ps1 script
- Customize the guide template for a specific use case
- Ensure your guide meets framework quality standards
- Review and improve existing guides

> **🚨 CRITICAL**: All guides must follow the established guide template structure (PF-TEM-003) and use the New-Guide.ps1 script for creation to ensure proper ID assignment and metadata integration.

> **Customization craft is not a guide.** Material teaching an agent *how to fill in* an artifact a `New-*` script creates belongs in a **craft skill**, not a guide — see the [Craft Skill Authoring Guide](craft-skill-authoring-guide.md) (PF-GDE-077). Guides carry procedures, conventions, and reference material.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Background](#background)
3. [Template Structure Analysis](#template-structure-analysis)
4. [Customization Decision Points](#customization-decision-points)
5. [Step-by-Step Instructions](#step-by-step-instructions)
6. [Quality Assurance](#quality-assurance)
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

The project uses a structured approach to documentation through the task framework. Guides serve as instructional documents that help users accomplish specific objectives within this framework. Guides come in two shapes:

### Procedure Guides

How-to guides that walk the reader through a process end-to-end: setup, migration, authoring, or operational procedures. They keep the step-by-step scaffolding — Prerequisites, Background, Step-by-Step Instructions, Examples, Troubleshooting.

### Convention / Reference Guides

Guides that carry a decision rule, a set of definitions, or a lookup table the reader consults rather than follows. They keep Overview and When to Use, then their own domain sections — the procedure scaffolding is deleted.

### Framework Integration

All guides must integrate properly with the task framework by:

- Using consistent terminology and structure
- Referencing related tasks and components appropriately
- Following established quality standards
- Supporting the overall framework objectives

## Template Structure Analysis

The guide template (PF-TEM-003) scaffolds a **procedure guide** and expects a convention/reference guide to delete what it does not need.

### Core Template Sections

**Required for every guide:**

- **Metadata**: ID, type, category, version, dates, status, `description`
- **Overview**: Brief description of guide purpose and outcome
- **When to Use**: The triggers and decision criteria that send a reader here
- **Related Resources**: Links to relevant documentation

**Procedure scaffolding — keep for a procedure guide, delete for a convention/reference guide:**

- **Table of Contents**: Worth keeping only for a long guide
- **Prerequisites**: Required knowledge, tools, and access
- **Background**: Context and concepts needed before the steps
- **Step-by-Step Instructions**: The procedure, with an Expected Result per step
- **Examples**: Real-world usage scenarios
- **Troubleshooting**: Symptom / cause / solution entries

A convention or reference guide replaces that scaffolding with its own domain sections — the decision rule, the definitions, the lookup table.

### Enhanced Metadata Fields

- **related_script**: Links the guide to a related script
- **related_task**: Names the owning task(s) as comma-separated `PF-TSK-NNN` IDs, so guide-to-task ownership queries are grep-complete; a framework-wide guide with no single owner leaves it unset

## Customization Decision Points

When creating guides, you must make several key decisions that impact effectiveness and framework integration:

### Guide Shape Decision

**Decision**: Procedure guide vs. convention/reference guide
**Criteria**:

- Does the reader **follow** this end-to-end to accomplish something? → Procedure guide (keep the step-by-step scaffolding)
- Does the reader **consult** it to decide or look something up? → Convention/reference guide (delete the scaffolding, write your own domain sections)
  **Impact**: Determines which template sections survive customization

> **🚨 CRITICAL ANTI-PATTERN**: Never create "task usage guides" that restate a task's workflow. Task workflows are documented in the task definitions themselves.

> **Not a guide at all**: craft that teaches an agent how to *fill in* an artifact created by a `New-*` script is authored as a **craft skill** — see the [Craft Skill Authoring Guide](craft-skill-authoring-guide.md). Guides carry procedures, conventions, and reference material; skills carry customization craft.

### Metadata Enhancement Decision

**Decision**: Whether to use enhanced metadata fields
**Criteria**:

- Is there a related script? → Include `related_script`
- Does a task (or a small set of tasks) own this guide? → Include `related_task`
  **Impact**: Improves traceability and discoverability

### Detail Level Decision

**Decision**: Depth of instructional detail
**Criteria**:

- Process complexity
- Framework integration requirements
  **Impact**: Determines guide accessibility and effectiveness

### Guide Focus Decision (CRITICAL)

**Decision**: Procedure / convention content vs. task workflow focus
**Criteria**:

- ✅ **CORRECT**: Guide walks the reader through a process the task definitions do not own
- ✅ **CORRECT**: Guide states a convention, decision rule, or reference the reader consults
- ❌ **INCORRECT**: Guide explains how to execute task workflows step-by-step
- ❌ **INCORRECT**: Guide duplicates content already in task definitions
- ↪️ **ROUTE ELSEWHERE**: Guide teaches how to fill in an artifact a `New-*` script creates → author a [craft skill](craft-skill-authoring-guide.md) instead
  **Impact**: Determines guide value and prevents framework redundancy

> **Note**: "Task usage guides" that restate task execution workflows are redundant with task definitions and create maintenance overhead.

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

3. **Determine guide shape and structure**

   - Decide between a procedure guide and a convention/reference guide (see the Guide Shape Decision above)
   - Plan which template sections survive and which get deleted
   - Identify required metadata fields

4. **Validate guide focus (CRITICAL)**
   - ✅ **VERIFY**: Guide carries a procedure, convention, or reference the framework does not already own
   - ❌ **REJECT**: Guide explains task workflow execution (this belongs in task definitions)
   - ❌ **REJECT**: Guide duplicates existing task documentation
   - ↪️ **REROUTE**: Content is artifact-customization craft → author a [craft skill](craft-skill-authoring-guide.md), not a guide

**Expected Result:** Clear understanding of guide scope, structure, and requirements with validated focus

### 2. Phase A - Structure Generation Using New-Guide.ps1

> **🚨 CRITICAL**: This phase creates only the STRUCTURAL FRAMEWORK. The guide is NOT functional until Phase B customization is completed.

1. **Navigate to the guides directory**

   ```powershell
   cd process-framework/guides
   ```

2. **Execute the New-Guide.ps1 script with appropriate parameters**

   ```powershell
   # -SubDirectory controls placement within guides/
   New-Guide.ps1 -GuideTitle "Your Guide Title" -SubDirectory "support" -GuideDescription "Brief description of guide purpose"

   # With traceability to a related script and task
   New-Guide.ps1 -GuideTitle "Schema Audit Procedure" -SubDirectory "support" -GuideDescription "How to reconcile template-frontmatter schema drift" -RelatedScript "Validate-StateTracking.ps1" -RelatedTasks "PF-TSK-009"
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

   - Replace `[Optional section...]` placeholders with actual content or delete the section
   - Replace `[Prerequisite 1]` style placeholders with specific requirements
   - Replace `[Detailed instruction]` placeholders with step-by-step procedures
   - Delete the procedure scaffolding your shape does not use (a convention/reference guide keeps Overview, When to Use, its own domain sections, and Related Resources)
   - Remove template guidance comments at the end of the file

2. **Develop comprehensive core sections**

   - **Overview**: Write clear, specific description of what the guide accomplishes
   - **When to Use**: Define specific triggers and decision criteria
   - **Prerequisites**: List concrete requirements with links to resources
   - **Background**: Add context information if needed for understanding

3. **Create detailed Step-by-Step Instructions** *(procedure guides)*

   - Break complex processes into logical, actionable steps
   - Include specific code examples, commands, or screenshots
   - When other documents are referenced, provide the actual links to those documents
   - Provide concrete expected results for each major step

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

## Quality Assurance

Comprehensive quality assurance ensures guides meet framework standards and serve users effectively:

### Self-Review Checklist

**Content Quality:**

- [ ] Overview clearly explains guide purpose and outcome
- [ ] When to Use states the triggers that send a reader here
- [ ] Content matches the chosen shape — a procedure guide's steps are complete and accurate; a convention/reference guide's rule or lookup is unambiguous
- [ ] Examples are relevant, working, and helpful
- [ ] Related resources are current and accessible
- [ ] Unused scaffolding sections were deleted, not left as placeholders

**Framework Integration:**

- [ ] Metadata fields are properly completed
- [ ] Terminology is consistent with framework standards
- [ ] Cross-references and links are correct and functional
- [ ] Guide aligns with related task objectives
- [ ] Structure follows the established template

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

- Test all instructions by following them step-by-step
- Verify examples work in the actual project environment
- Check that cross-references lead to correct resources
- Confirm guide helps users achieve stated objectives

## Examples

### Example 1: Creating a Procedure Guide

Creating a guide for the schema-audit procedure:

```powershell
New-Guide.ps1 -GuideTitle "Schema Audit Procedure" -SubDirectory "support" -GuideDescription "How to reconcile template-frontmatter schema drift surfaced by Validate-StateTracking.ps1" -RelatedScript "Validate-StateTracking.ps1" -RelatedTasks "PF-TSK-009"
```

**Customization approach:**

- Keep the full procedure scaffolding: Prerequisites, Background, Step-by-Step Instructions, Troubleshooting
- Give every major step a concrete Expected Result
- Provide Examples with real commands from the project

**Result:** A guide the reader follows end-to-end to complete the procedure

### Example 2: Creating a Convention / Reference Guide

Creating a guide that states where shared app-shell UI is documented:

```powershell
New-Guide.ps1 -GuideTitle "App Shell vs Feature Views Convention" -SubDirectory "02-design" -GuideDescription "When shared app-shell UI belongs in a shared design doc vs. a feature's own UI Design"
```

**Customization approach:**

- Keep Overview and When to Use; delete the Table of Contents, Prerequisites, Background, Step-by-Step Instructions and Troubleshooting scaffolding
- Write the domain sections the reader actually consults: Definitions, The Decision Rule, Proportionality, a Worked Example
- Keep Related Resources

**Result:** A guide the reader consults to make a decision, with no procedure scaffolding to wade through

### Example 3: Avoiding Task Usage Guide Anti-Pattern

**❌ INCORRECT Approach - Task Usage Guide:**

```powershell
# DON'T DO THIS
New-Guide.ps1 -GuideTitle "Code Refactoring Task Usage Guide" -SubDirectory "06-maintenance" -GuideDescription "How to execute the code refactoring task step-by-step"
```

**Problems with this approach:**

- Duplicates content already in the task definition
- Restates task workflow rather than carrying content the framework does not already own
- Creates maintenance overhead when task processes change
- Provides no additional value beyond the task definition

**✅ CORRECT Approach — carry content the task definition does not own:**

A guide earns its place when it holds a procedure, convention, or reference that no task owns — and that several readers or tasks consult. If instead the content teaches an agent how to *fill in* an artifact a `New-*` script creates, it is craft: author a [craft skill](craft-skill-authoring-guide.md) and bind it to the owning task, rather than a guide.

**Key Principle:** Ask "does this carry a procedure, convention, or reference the framework does not already own?" If it just repeats task workflow steps, don't create it. If it is artifact-customization craft, make it a skill.

## Troubleshooting

### Guide Creation Script Fails

**Symptom:** New-Guide.ps1 script execution fails with permission or path errors

**Cause:** PowerShell execution policy restrictions or incorrect working directory

**Solution:**

1. Check PowerShell execution policy: `Get-ExecutionPolicy`
2. If restricted, set policy: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`
3. Ensure you're in the correct directory: `cd process-framework/guides`
4. Verify script exists: `Test-Path .\New-Guide.ps1`

### Metadata Fields Not Populating

**Symptom:** Related script and task fields appear empty in created guide

**Cause:** Parameters not provided or incorrectly formatted in New-Guide.ps1 command

**Solution:**

1. Verify parameter syntax: `-RelatedScript "ScriptName.ps1" -RelatedTasks "PF-TSK-XXX"`
2. Check for typos in parameter names
3. Ensure task IDs are comma-separated for multiple tasks: `"PF-TSK-001,PF-TSK-009"`

### Guide Structure Inconsistencies

**Symptom:** Created guide doesn't match expected template structure

**Cause:** Guide template (PF-TEM-003) may be outdated or corrupted

**Solution:**

1. Verify guide template exists: `process-framework/templates/support/guide-template.md`
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

### Guide Restates a Task Workflow

**Symptom:** Guide explains how to execute task steps rather than carrying content of its own

**Cause:** Misunderstanding of guide purpose — a "task usage guide" duplicates the task definition

**Solution:**

1. **STOP**: Do not create task usage guides — they duplicate task definitions
2. **CHECK**: Is the real content a procedure, convention, or reference the framework does not own?
3. **REROUTE**: If it is artifact-customization craft, author a [craft skill](craft-skill-authoring-guide.md) instead
4. **REFERENCE**: Link to task definitions for workflow information instead of duplicating it

**Prevention:** Always validate guide focus during planning phase using the Guide Focus Decision criteria

## Related Resources

- [Guide Template (PF-TEM-003)](../../templates/support/guide-template.md) - The base template for all guides
- [New-Guide.ps1 Script](../../scripts/file-creation/support/New-Guide.ps1) - Script for creating new guides with proper ID assignment
- [Craft Skill Authoring Guide (PF-GDE-077)](craft-skill-authoring-guide.md) - Where artifact-customization craft belongs instead of a guide
- [Task Framework Overview](../../README.md) - Understanding the broader framework context
