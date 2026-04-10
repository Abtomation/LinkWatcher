---
id: PF-GDE-035
type: Process Framework
category: Guide
version: 1.2
created: 2025-07-28
updated: 2026-04-09
related_task: PF-TSK-026
related_script: New-FrameworkExtensionConcept.ps1
---
# Framework Extension Concept Customization Guide

## Overview

This guide provides comprehensive instructions for customizing Framework Extension Concept documents created by the New-FrameworkExtensionConcept.ps1 script. The script generates only a structural template - this guide shows you how to transform that template into a comprehensive, actionable concept document.

> **🚨 CRITICAL**: The New-FrameworkExtensionConcept.ps1 script creates only a TEMPLATE requiring extensive customization. This guide is essential for creating functional concept documents.

## When to Use This Guide

Use this guide when you have:

- **Generated a Framework Extension Concept template** using New-FrameworkExtensionConcept.ps1
- **Received a template with placeholder content** that needs to be replaced with specific concept details
- **Been assigned to customize a concept document** as part of the Framework Extension Task process
- **Need to understand** how to properly define extension scope, workflow, and integration strategy

## Understanding the Template Structure

When you run `New-FrameworkExtensionConcept.ps1`, you receive a document with this structure:

```
Framework Extension Concept: [Extension Name]
├── Executive Summary (placeholder text)
├── Extension Overview (template sections)
├── Scope Definition (example content)
├── Implementation Strategy (generic workflow)
├── Integration Plan (placeholder steps)
├── Resource Requirements (template estimates)
└── Success Criteria (example metrics)
```

> **🚨 CRITICAL**: ALL content in brackets `[like this]` and placeholder text must be replaced with your specific extension details.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Customization Process](#customization-process)
3. [Section-by-Section Guide](#section-by-section-guide)
4. [Examples](#examples)
5. [Validation Checklist](#validation-checklist)
6. [Related Resources](#related-resources)

## Prerequisites

Before customizing a Framework Extension Concept document, ensure you have:

- **Generated Template**: A Framework Extension Concept template created by New-FrameworkExtensionConcept.ps1
- **Extension Understanding**: Clear understanding of what framework capability you want to add
- **Framework Knowledge**: Familiarity with existing framework structure and task types
- **Scope Clarity**: Well-defined scope of the extension including components and integration points
- **Implementation Vision**: Clear idea of how the extension will work and be used
- **Resource Awareness**: Understanding of time, complexity, and dependencies involved

## Customization Process

The Framework Extension Concept template contains placeholder content that must be replaced with your specific extension details. Follow this systematic approach:

### Phase 1: Content Replacement
1. **Replace all bracketed placeholders** `[like this]` with actual content
2. **Remove template guidance text** (usually in italics or marked as examples)
3. **Customize section headings** to match your extension's specific focus
4. **Add extension-specific subsections** as needed

### Phase 2: Content Development
1. **Expand brief descriptions** into comprehensive explanations
2. **Add specific technical details** relevant to your extension
3. **Include concrete examples** of how the extension will be used
4. **Define measurable success criteria** for the extension

> **⚠️ Project-specific adaptation**: Define categories, levels, and terminology specific to YOUR project's architecture. Do not copy generic industry terminology — study the project's existing patterns first (see Pre-Concept Analysis in [Framework Extension Task](../../tasks/support/framework-extension-task.md) Step 1) and derive categories that match the project's actual structure.

### Phase 3: Integration Planning
1. **Map dependencies** on existing framework components
2. **Identify integration points** with current processes
3. **Plan multi-session implementation** with clear milestones
4. **Define human review checkpoints** throughout implementation

## Section-by-Section Guide

This section provides detailed guidance for customizing each section of the Framework Extension Concept template.

### Extension Type Section

**Template Content:** A table with three extension types (Creation, Modification, Hybrid)
**Your Task:** Select the type that matches your extension and delete irrelevant sections

**Customization Steps:**
1. **Determine your extension type**:
   - **Creation**: You are adding entirely new artifacts (new tasks, new templates, new scripts). Use the creation-oriented sections; delete the Modification-Focused Sections block.
   - **Modification**: You are modifying existing artifacts (adding steps to tasks, updating templates, changing guides). Use the Modification-Focused Sections; delete "New Artifacts Created", "New Tasks Required", and "New Permanent State Files Required".
   - **Hybrid**: You are both creating new artifacts and modifying existing ones. Keep all sections.
2. **Replace `[Creation / Modification / Hybrid]`** with your selected type
3. **Delete the sections marked for removal** based on your type selection

**Example:**
```
BEFORE: **Selected Type**: [Creation / Modification / Hybrid]
AFTER:  **Selected Type**: Modification
```

### Modification-Focused Sections

**Template Content:** Three tables for state tracking audit, guide update inventory, and automation integration
**Your Task:** Fill in the modification impact analysis for your extension

**When to use:** Only for Modification or Hybrid extension types. Delete this entire block for Creation-only extensions.

**Customization Steps:**
1. **State Tracking Audit**: List every existing state file your extension will modify. Use `grep` to find state files that reference the artifacts you're changing. Describe the specific field/section changes needed.
2. **Guide Update Inventory**: List every guide, task definition, and doc that references the artifacts being modified. Use `grep` for the file paths and task IDs involved. This prevents broken references after implementation.
3. **Automation Integration Strategy**: List every script that reads from or writes to the artifacts you're modifying. Determine if each script needs changes and whether changes are backward compatible.

**Key principle:** The discovery method row is important — document how you found the references so reviewers can verify completeness.

### Existing Project Precedents Section

**Template Content:** Table for documenting how the project already handles similar or analogous cases
**Your Task:** Research existing patterns before designing the extension

**Customization Steps:**
1. **Search the codebase** for existing workflows, tasks, or patterns that solve similar problems to what the extension addresses
2. **Fill in the precedent table** with concrete file paths and descriptions — do not leave this generic
3. **Write the Key Takeaways** summarizing what to reuse, what gaps exist, and what the extension adds that is genuinely new
4. **Verify each precedent** by reading the referenced files — do not rely on assumptions about what exists

**Key principle:** This section must be completed *before* designing the Core Process Overview or artifact lists. The precedents inform the design.

### Interfaces to Existing Framework Section

**Template Content:** Three sub-tables for task interfaces, state file interfaces, and artifact interfaces
**Your Task:** Map every touchpoint between the extension and the existing framework

**Customization Steps:**
1. **Task Interfaces**: List every existing task that feeds into or consumes from this extension. Specify the direction (upstream input, downstream consumer, or modified by extension) and what flows between them.
2. **State File Interfaces**: List every state file the extension reads from or writes to. Be specific about which fields or sections are affected.
3. **Artifact Interfaces**: List every existing artifact type (templates, guides, tracking files) the extension uses or updates.
4. **Verify with grep**: Use `grep` for task IDs, file paths, and state file names to ensure completeness.

**Key principle:** If a touchpoint is not listed here, it will likely be missed during implementation. Err on the side of over-documenting interfaces.

### Executive Summary Section

**Template Content:** Generic summary with placeholder text
**Your Task:** Replace with a concise overview of your specific extension

**Customization Steps:**
1. **Replace `[Extension Name]`** with your actual extension name
2. **Replace `[brief description]`** with 1-2 sentences describing the extension
3. **Replace `[key benefits]`** with specific benefits your extension provides
4. **Replace `[implementation approach]`** with your planned implementation strategy

**Example Transformation:**
```
BEFORE: "This document proposes [Extension Name] to [brief description]..."
AFTER: "This document proposes the Multi-Language Support Extension to enable framework documentation and tasks in multiple languages..."
```

### Extension Overview Section

**Template Content:** Generic overview with example components
**Your Task:** Define your extension's specific scope and components

**Customization Steps:**
1. **Replace component examples** with your actual extension components
2. **Define specific capabilities** your extension will add
3. **Identify target users** who will benefit from the extension
4. **Specify integration points** with existing framework components

### Scope Definition Section

**Template Content:** Generic scope boundaries with placeholder examples
**Your Task:** Define precise boundaries and deliverables for your extension

**Customization Steps:**
1. **Replace `[specific capabilities]`** with detailed capability descriptions
2. **Replace `[component list]`** with actual components you'll create
3. **Replace `[integration points]`** with specific framework touchpoints
4. **Replace `[exclusions]`** with what your extension will NOT include

### Implementation Strategy Section

**Template Content:** Generic multi-session workflow template
**Your Task:** Create specific implementation plan for your extension

**Customization Steps:**
1. **Replace session examples** with your actual planned sessions
2. **Define specific deliverables** for each implementation phase
3. **Identify dependencies** between components and sessions
4. **Plan human review checkpoints** at appropriate milestones

## Examples

### Example 1: Multi-Language Support Extension

**Before Customization:**
```
Extension Name: [Extension Name]
Description: [Brief description of the extension]
Components: [List of components to be created]
```

**After Customization:**
```
Extension Name: Multi-Language Support Extension
Description: Enable framework documentation and tasks to support multiple languages with translation workflows and localized templates
Components:
- Language-specific task templates
- Translation workflow tasks
- Localized documentation templates
- Language preference management
```

### Example 2: Performance Monitoring Extension

**Before Customization:**
```
Success Criteria: [How will you measure success]
Timeline: [Expected implementation timeline]
```

**After Customization:**
```
Success Criteria:
- Task execution time tracking implemented
- Performance bottleneck identification automated
- Performance reports generated for all task types
- 90% of tasks show measurable performance metrics

Timeline: 4 sessions over 2 weeks
- Session 1: Performance tracking task definitions
- Session 2: Monitoring templates and data collection
- Session 3: Reporting and visualization components
- Session 4: Integration and testing
```

## Validation Checklist

Before submitting your customized Framework Extension Concept document, verify:

### Content Completeness
- [ ] All bracketed placeholders `[like this]` have been replaced
- [ ] All template guidance text has been removed or customized
- [ ] Each section contains specific, actionable content
- [ ] Extension name is consistent throughout the document

### Technical Accuracy
- [ ] Component list is complete and realistic
- [ ] Integration points are clearly identified
- [ ] Dependencies are properly mapped
- [ ] Implementation timeline is feasible

### Framework Alignment
- [ ] Extension aligns with framework principles
- [ ] Naming conventions follow framework standards
- [ ] Integration approach respects existing architecture
- [ ] Success criteria are measurable and relevant

## Related Resources

### Framework Documentation
- [Framework Extension Task Definition](../../tasks/support/framework-extension-task.md) - Complete task definition and process
- [Framework Extension Concept Template](../../templates/support/framework-extension-concept-template.md) - Template structure and sections
- [New-FrameworkExtensionConcept.ps1](../../scripts/file-creation/support/New-FrameworkExtensionConcept.ps1) - Script for generating concept templates

### Supporting Guides
- [Template Development Guide](template-development-guide.md) - Best practices for creating templates
- [Guide Creation Best Practices Guide](guide-creation-best-practices-guide.md) - Standards for creating guides
- [Task Definition Guide](task-definition-guide.md) - Guidelines for defining new tasks

### Framework Infrastructure
- [Documentation Map](../../PF-documentation-map.md) - Complete framework documentation index
- [AI Tasks Registry](../../ai-tasks.md) - Main task registry and entry point
- [PF ID Registry](../../PF-id-registry.json) - Document ID assignment and tracking

---

*This guide focuses specifically on customizing Framework Extension Concept documents. For guidance on using the Framework Extension Task itself, see the [Framework Extension Task Definition](../../tasks/support/framework-extension-task.md).*
   - Session 2: Templates for performance specifications and reports
   - Session 3: Guides for performance monitoring usage
   - Session 4: Integration with existing development tasks

**Result:** Complete performance monitoring capability integrated into the framework

### Example 2: Adding Security Assessment Workflows

**Scenario:** Need to add comprehensive security assessment capabilities that integrate with existing development and testing workflows.

**Extension Concept:**
- **Extension Name**: Security Assessment Framework Extension
- **Extension Description**: Comprehensive security assessment workflows with threat modeling, vulnerability scanning, and security review processes
- **Extension Scope**: New security-focused task category with automated assessment tools and reporting

**Key Integration Points:**
- Links with existing testing tasks for security test integration
- Connects with code review processes for security-focused reviews
- Integrates with documentation tasks for security documentation requirements

**Result:** Systematic security assessment capability that enhances existing development workflows

## Troubleshooting

### Extension Scope Too Broad

**Symptom:** Concept document becomes overwhelming with too many components and unclear implementation path

**Cause:** Attempting to solve multiple unrelated problems in a single extension

**Solution:**
1. Break down the extension into smaller, focused extensions
2. Identify the core capability and separate supporting features
3. Consider if some components can be handled by existing tasks
4. Create multiple smaller extensions with clear dependencies

### Human Review Rejection

**Symptom:** Concept document is rejected during human review phase

**Cause:** Insufficient justification for framework-level changes or unclear integration strategy

**Solution:**
1. Revisit the decision criteria - ensure framework extension is truly needed
2. Provide more detailed integration analysis with existing components
3. Clarify the unique value proposition of the extension
4. Consider alternative approaches using existing framework capabilities

### Multi-Session Implementation Stalls

**Symptom:** Implementation progress stops between sessions due to unclear state or dependencies

**Cause:** Inadequate state tracking or unclear implementation roadmap

**Solution:**
1. Review and update temporary state tracking file with current progress
2. Clarify next steps and dependencies in state tracking notes
3. Break down remaining work into smaller, more manageable chunks
4. Ensure all required resources and scripts are accessible

### Integration Conflicts

**Symptom:** New extension components conflict with existing framework components

**Cause:** Insufficient analysis of existing framework during concept development

**Solution:**
1. Pause implementation and review existing framework components
2. Identify specific conflicts and their root causes
3. Modify extension design to work harmoniously with existing components
4. Update concept document and get human re-approval if significant changes needed

## Related Resources

### Framework Documentation
- [Framework Extension Task Definition](../../tasks/support/framework-extension-task.md) - Complete task definition and specifications
- [Framework Extension Concept Template](../../templates/support/framework-extension-concept-template.md) - Template for creating concept documents
- [Task Creation Guide](task-creation-guide.md) - Guide for creating individual tasks
- [Documentation Structure Guide](../framework/documentation-structure-guide.md) - Framework documentation standards

### State Tracking Resources
- [Temp State Tracking Customization Guide](temp-state-tracking-customization-guide.md) - Guide for customizing temporary state tracking
- [State File Creation Guide](state-file-creation-guide.md) - Guide for creating permanent state files

### Script and Template Resources
- [Template Development Guide](template-development-guide.md) - Guide for creating templates
- [Script Development Quick Reference](script-development-quick-reference.md) - Quick reference for script development
- [Guide Creation Best Practices Guide](guide-creation-best-practices-guide.md) - Best practices for creating guides

### Process Framework Core
- [AI Tasks Registry](../../ai-tasks.md) - Complete list of available tasks
- [Documentation Map](../../PF-documentation-map.md) - Map of all framework documentation
- [Process Framework Overview](../../README.md) - Overview of the entire process framework
