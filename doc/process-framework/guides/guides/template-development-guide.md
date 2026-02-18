---
id: PF-GDE-002
type: Process Framework
category: Guide
version: 1.1
created: 2025-06-07
updated: 2025-07-15
---

# Template Development Guide

## Purpose

This guide provides best practices for developing and maintaining templates in the BreakoutBuddies project. Templates ensure consistency across documents and reduce the effort required to create new content.

## Template Design Principles

### 1. Clarity Over Completeness

- Make templates easy to understand at a glance
- Include clear instructions within templates
- Use placeholder text that indicates what should replace it

### 2. Guidance Within

- Embed guidance in the template itself
- Use comments to explain rationale and provide examples
- Include links to relevant resources

### 3. Consistency Across Templates

- Use consistent naming conventions
- Maintain consistent structure between related templates
- Use consistent formatting and styling

### 4. Flexibility Within Constraints

- Allow for necessary variations while maintaining core structure
- Clearly indicate which elements are required vs. optional
- Support extension without breaking the core pattern

### 5. Evolution-Ready

- Design templates to accommodate future changes
- Document the template's version and update history
- Include extension points for anticipated future needs

## Template Components

### Metadata Section

```yaml
---
id: [Document ID pattern]
type: [Document type]
category: [Specific category]
version: [Version number]
created: [Creation date]
updated: [Last update date]
---
```

### Instructional Comments

```markdown
<!--
This is an instructional comment that explains how to use this section of the template.
It should be removed when the template is used to create a document.
-->
```

### Placeholder Text

```markdown
[Descriptive placeholder that indicates what content should go here]
```

### Required vs. Optional Sections

```markdown
## Required Section Title

[This section must be included in all instances]

## Optional Section Title (if applicable)

[This section can be included when relevant]
```

### Extension Points

```markdown
## Custom Sections (as needed)

<!-- Add additional sections here as required for your specific case -->
```

## Template Development Process

### 1. Needs Analysis

- Identify the document type that needs a template
- Collect examples of existing documents of this type
- Identify common patterns and variations
- Determine key information that must be included

### 2. Structure Design

- Create an outline of the template structure
- Identify required and optional sections
- Establish section order and hierarchy
- Define metadata requirements

### 3. Content Development

- Write clear placeholder text
- Create instructional comments
- Include examples where helpful
- Add links to relevant resources

### 4. Testing

- Create sample documents using the template
- Test with different users and use cases
- Identify unclear or problematic areas
- Refine based on feedback

### 5. Documentation

- Document the template's purpose and usage
- Create examples of completed documents
- Establish governance for template changes
- Define the update process

### 6. Two-Phase Template Creation and Deployment

#### Phase A - Structure Generation Using New-Template.ps1

> **🚨 CRITICAL**: This phase creates only the STRUCTURAL FRAMEWORK. The template is NOT functional until Phase B customization is completed.

The project provides a script to automate template structure creation:

```powershell
# Create a new template with basic information
..\..\scripts\file-creation\New-Template.ps1lateName "Feature Request" -TemplateDescription "Template for creating feature requests" -DocumentPrefix "PF-REQ" -DocumentCategory "Request"

# Create and immediately open in editor
..\..\scripts\file-creation\New-Template.ps1lateName "Architecture Overview" -TemplateDescription "Template for architecture documentation" -DocumentPrefix "PD-ARC" -DocumentCategory "Architecture" -OpenInEditor
```

**Phase A Script Output:**

- Generates proper metadata with a unique template ID
- Creates a standardized template structure with placeholder content
- Updates the ID registry automatically
- ⚠️ **IMPORTANT**: Provides STARTING POINT requiring extensive customization

**Status After Phase A:** STRUCTURE_CREATED (Not ready for use)

#### Phase B - Content Customization and Finalization

> **🚨 CRITICAL**: This phase transforms the structural framework into a functional template. ALL placeholder content must be replaced with comprehensive, usable content.

**Phase B Requirements:**

1. **Replace ALL placeholder content** with specific, actionable guidance
2. **Customize metadata sections** with appropriate fields for the document type
3. **Develop comprehensive section content** following the design principles above
4. **Add instructional comments** and examples throughout the template
5. **Test the template** by creating sample documents
6. **Document template usage** and provide examples

**Phase B Deployment:**

- Update references to the template in documentation
- Communicate the new template to users
- Provide transition guidance if replacing an existing template

**Status After Phase B:** CONTENT_COMPLETED (Ready for use)

## Template Maintenance

### Version Control

- Use semantic versioning for templates (MAJOR.MINOR.PATCH)
- Document changes in the template's update history
- Maintain backward compatibility when possible
- Clearly communicate breaking changes

### Update Triggers

- User feedback indicates confusion or difficulties
- New requirements emerge for the document type
- Inconsistencies are discovered across documents
- The underlying process changes

### Migration Strategy

- Plan how existing documents will migrate to new template versions
- Create migration scripts or tools when possible
- Provide clear guidance for manual migrations
- Set realistic timelines for migration completion

## Common Template Types

### Process Templates

- Task templates
- Workflow templates
- Review templates
- Decision templates

### Documentation Templates

- Guide templates
- Reference templates
- API documentation templates
- Tutorial templates

### Management Templates

- Tracking templates
- Status report templates
- Feedback templates
- Proposal templates

## Testing Templates

### Usability Testing

- Can users create a document without confusion?
- Are the instructions clear and helpful?
- Are placeholders easy to understand and replace?

### Completeness Testing

- Does the template include all necessary sections?
- Does it accommodate all valid variations?
- Are all required fields and sections clearly indicated?

### Consistency Testing

- Is the template consistent with related templates?
- Does it follow project-wide conventions?
- Does it use standard terminology?

## Related Resources

- [Documentation Structure Guide](../documentation-structure-guide.md)
- [Migration Best Practices](../migration-best-practices.md)
- [Structure Change Task](../../tasks/support/structure-change-task.md)
- [Task Creation and Improvement Guide](../task-creation-guide.md)
- [Template Creation Script](/doc/process-framework/scripts/file-creation/New-Template.ps1)
- [Template Base Template](/doc/process-framework/templates/templates/template-base-template.md)
- [Document Creation Script Development Guide](document-creation-script-development-guide.md)
