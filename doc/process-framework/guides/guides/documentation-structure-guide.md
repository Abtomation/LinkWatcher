---
id: PF-GDE-005
type: Process Framework
category: Guide
version: 1.1
created: 2025-06-07
updated: 2025-01-11
---

# Documentation Structure Guide

## Purpose
This guide provides principles and patterns for creating consistent, maintainable documentation structures across the BreakoutBuddies project. It serves as a reference for anyone creating or updating documentation structures.

## Core Principles

### 1. Consistency Over Creativity
- Use consistent structures, headings, and formatting across similar document types
- Follow established patterns rather than creating new ones
- Maintain consistent terminology and naming conventions

### 2. Progressive Disclosure
- Present the most important information first
- Structure documents to reveal details progressively
- Use hierarchical organization to manage complexity

### 3. Context Before Detail
- Provide context before diving into details
- Explain why before explaining how
- Connect documents to the larger system

### 4. Actionable Over Theoretical
- Focus on what readers need to do
- Provide clear, actionable steps
- Include examples for complex concepts

### 5. Maintainability First
- Design structures that are easy to maintain
- Minimize duplication across documents
- Use linking rather than copying information

### 6. 🚨 System Integration
- **Consider automation and tooling dependencies when making structural changes**
- Maintain consistency between documentation and supporting systems
- Test integrations after structural modifications
- Document system dependencies for future maintainers

## Document Structure Patterns

### Task Definition Pattern
```
# Task Name

## Purpose & Context
[Why this task exists and how it fits into the larger process]

## When to Use
[Clear guidance on when to perform this task]

## Context Requirements
- **Critical (Must Read):**
  [Essential files and information needed for the task]

- **Important (Load If Space):**
  [Valuable context that could be loaded if context window allows]

- **Reference Only (Access When Needed):**
  [Files only needed for specific operations]

## Process
[Step-by-step instructions, organized into phases]

## Outputs
[What is produced by the task]

## State Tracking
[What state files are updated]

## Task Completion Checklist
[Verification steps to ensure the task is complete]

## Next Tasks
[What typically follows this task]

## Related Resources
[Additional helpful information]
```

### Guide Pattern
```
# Guide Title

## Purpose
[Why this guide exists and who it's for]

## Core Principles/Concepts
[Fundamental ideas that guide the subject]

## Detailed Guidance
[Specific instructions or information, organized by topic]

## Examples
[Concrete examples demonstrating the concepts]

## Common Pitfalls
[Mistakes to avoid]

## Related Resources
[Additional helpful information]
```

### State Tracking Pattern
```
# State Tracking Title

## Overview
[What this state file tracks and why]

## Status Definitions
[Clear definitions of status terms used]

## Current Items
[Table of current items being tracked]

## Historical Items
[Completed or archived items]

## Related Tasks
[Tasks that update this state file]

## Update History
[Record of significant updates]
```

## Linking Strategy

### Internal Linking
- Use relative paths for all internal links
- Link to specific sections when referencing part of a document
- Prefer linking to canonical sources rather than duplicating information

### External Linking
- Only link to stable external resources
- Include date of last verification for external links
- Consider archiving external resources if they're critical

## Metadata Standards

### Required Metadata
- id: Unique identifier for the document
- type: Document type (e.g., Process Framework)
- category: Specific category within the type
- version: Current version number
- created: Creation date
- updated: Last update date

### Optional Metadata
- status: Current status (if applicable)
- tags: Keywords for categorization

## Visual Elements

### When to Use Visual Elements
- Use diagrams for process flows
- Use tables for structured information
- Use callouts for warnings, notes, and tips
- Use code blocks for examples

### Formatting Standards
- Use standard Markdown formatting
- Use consistent emoji for visual cues (e.g., 🚨 for warnings)
- Use bold for emphasis, italics for definitions
- Use headings consistently for document hierarchy

## Implementation Guidelines

### Evolving Documentation Structures
1. Start with a clear problem statement
2. Create a structure change proposal
3. **🚨 CRITICAL: Identify system dependencies** (automation, tooling, integrations)
4. Prototype the new structure with a few documents
5. Collect feedback and iterate
6. Create a migration plan for existing documents
7. **Update supporting systems and tools FIRST**
8. Update templates and guides
9. Implement the new structure systematically
10. **Verify all integrations work with new structure**

### Testing Documentation Structures
- Test new structures with actual users
- Verify that structures scale with document complexity
- Ensure structures work for all expected document types
- Check that navigation and linking work as expected

### 🚨 System Integration Requirements

When making structural changes that affect supporting systems:

#### 1. Dependency Identification
- **Automation Scripts**: Identify scripts that reference the structure
- **Validation Rules**: Find hardcoded validation or categorization logic
- **Templates**: Locate templates that use structural elements
- **Integration Points**: Discover external systems that depend on the structure

#### 2. Impact Assessment
- **Direct Dependencies**: Systems that directly reference structural elements
- **Indirect Dependencies**: Systems that derive behavior from the structure
- **Documentation References**: All documentation that mentions the structure
- **User Workflows**: Processes that depend on the current structure

#### 3. Systematic Update Process
```bash
# General approach for finding dependencies:
# 1. Search for structural references in code/scripts
rg "pattern-to-find" --type [file-type]

# 2. Search for references in documentation
rg "structural-element" --type md

# 3. Test affected systems
# 4. Verify integrations work correctly
# 5. Update all dependent documentation
```

#### 4. Common Integration Points
- **Creation/Generation Scripts**: Any automation that creates or processes documents
- **Validation Systems**: Rules that enforce structural consistency
- **Templates and Scaffolding**: Reusable structures and examples
- **Navigation and Linking**: Systems that depend on document organization
- **External Integrations**: Tools that consume or process the documentation

## 🔧 Structure Change Checklist

Use this checklist when making significant structural changes:

### Before Making Changes
- [ ] Document all current system dependencies
- [ ] Identify all tools and automation that reference the structure
- [ ] List all documentation that references the structure
- [ ] Plan the complete update sequence
- [ ] Assess impact on existing workflows

### During Implementation
- [ ] Update supporting systems and tools first
- [ ] Update all usage examples and documentation
- [ ] Update templates and scaffolding
- [ ] Test system functionality with new structure
- [ ] Verify integrations work correctly

### After Implementation
- [ ] Run systematic verification of all dependencies
- [ ] Test end-to-end workflows with new structure
- [ ] Update this guide if new patterns emerge
- [ ] Document lessons learned for future changes
- [ ] Communicate changes to stakeholders

### Emergency Recovery
If systems break after structural changes:
1. Revert critical systems to working state immediately
2. Create temporary workaround documentation
3. Fix all dependencies systematically
4. Re-test before re-deploying changes
5. Review process to prevent similar issues

## Related Resources
- <!-- [Template Development Guide](../../template-development-guide.md) - Template/example link commented out -->
- [Migration Best Practices](../../migration-best-practices.md)
- [Structure Change Task](../../../tasks/support/structure-change-task.md)
- [Task Creation and Improvement Guide](../../task-creation-guide.md)
- [New Task Creation Process](../../../tasks/support/new-task-creation-process.md)
