---
id: PF-GDE-000
type: Process Framework
category: Guide
version: 1.0
created: 2025-07-08
updated: 2025-07-08
---

# Process Framework Guides

## Overview

The Process Framework Guides directory contains comprehensive guides that provide detailed instructions, best practices, and methodologies for working within the BreakoutBuddies development process. These guides complement the task definitions by providing deeper context and detailed procedures for complex activities.

## Purpose

The guides in this directory serve to:

1. Provide detailed instructions for complex development processes
2. Establish best practices and standards for consistent work quality
3. Offer comprehensive reference materials for development activities
4. Support the task-based workflow with detailed procedural guidance
5. Document methodologies and approaches used in the project
6. Enable knowledge transfer and onboarding for new team members

## Available Guides

### Development Process Guides

| Guide                                                  | Description                                                      | When to Use                                          |
| ------------------------------------------------------ | ---------------------------------------------------------------- | ---------------------------------------------------- |
| [Task Creation Guide](guides/task-creation-guide.md)   | Comprehensive guide for creating and improving development tasks | When creating new tasks or improving existing ones   |
| [Implementation Guide](guides/implementation-guide.md) | Best practices for implementing features and functionality       | During feature development and implementation phases |
| [Assessment Guide](guides/assessment-guide.md)         | Guidelines for assessing feature complexity and requirements     | When evaluating new features or changes              |

### Documentation Guides

| Guide                                                                    | Description                                                  | When to Use                                                      |
| ------------------------------------------------------------------------ | ------------------------------------------------------------ | ---------------------------------------------------------------- |
| [Documentation Guide](guides/documentation-guide.md)                     | Standards and practices for project documentation            | When creating or updating any project documentation              |
| [Documentation Structure Guide](guides/documentation-structure-guide.md) | Guidelines for organizing and structuring documentation      | When planning documentation architecture or reorganizing content |
| [Template Development Guide](guides/template-development-guide.md)       | Instructions for creating and maintaining document templates | When developing new templates or updating existing ones          |
| [Terminology Guide](guides/terminology-guide.md)                         | Definitions and usage of project-specific terminology        | When clarifying terminology or ensuring consistent language use  |

### Technical Guides

| Guide                                                                                              | Description                                                    | When to Use                                                |
| -------------------------------------------------------------------------------------------------- | -------------------------------------------------------------- | ---------------------------------------------------------- |
| [Document Creation Script Development Guide](guides/document-creation-script-development-guide.md) | Guide for developing and maintaining document creation scripts | When working on automation scripts for document generation |
| [Visual Notation Guide](guides/visual-notation-guide.md)                                           | Standards for visual elements and notation in documentation    | When creating diagrams, charts, or visual documentation    |

### Process Management Guides

| Guide                                                                               | Description                                                     | When to Use                                                    |
| ----------------------------------------------------------------------------------- | --------------------------------------------------------------- | -------------------------------------------------------------- |
| [Feedback Form Guide](guides/feedback-form-guide.md)                                | Instructions for creating and using feedback forms              | When collecting feedback on tools, processes, or documentation |
| [Migration Best Practices](guides/migration-best-practices.md)                      | Best practices for migrating processes, tools, or documentation | When planning or executing migration activities                |
| [Temp Task State Creation Guide](guides/temp-state-tracking-customization-guide.md) | Guide for creating temporary task state tracking                | When managing temporary or short-term task states              |

## Guide Creation Tools

### Automated Guide Creation

The guides directory includes automation tools to streamline guide creation:

**New-Guide.ps1 Script**

- **Purpose**: Creates new guides from the standardized guide template
- **Location**: `doc/process-framework/scripts/file-creation/New-Guide.ps1`
- **Usage**:
  ```powershell
  ..\scripts\file-creation\New-Guide.ps1 -GuideTitle "Your Guide Title" -GuideDescription "Brief description" [-GuideCategory "Category"] [-OpenInEditor]
  ```
- **Features**:
  - Automatically assigns unique PF-GDE-XXX IDs
  - Updates central ID registry
  - Creates properly formatted guide files
  - Supports optional categorization
  - Can open created guides in editor

**Examples**:

```powershell
# Create a basic guide
..\scripts\file-creation\New-Guide.ps1 -GuideTitle "API Integration Setup" -GuideDescription "Step-by-step guide for integrating third-party APIs"

# Create a guide with category and open in editor
..\scripts\file-creation\New-Guide.ps1 -GuideTitle "Testing Best Practices" -GuideDescription "Comprehensive guide for writing effective tests" -GuideCategory "Development Process" -OpenInEditor
```

## Guide Structure

Each guide follows a consistent structure to ensure clarity and usability:

1. **Guide Metadata**: Version information, guide type, and creation dates
2. **Purpose**: What the guide accomplishes and why it's needed
3. **Scope**: What is and isn't covered by the guide
4. **Prerequisites**: Knowledge or setup required before using the guide
5. **Detailed Instructions**: Step-by-step procedures and best practices
6. **Examples**: Practical examples demonstrating the concepts
7. **Troubleshooting**: Common issues and their solutions
8. **References**: Related documents and additional resources

## Relationship to Tasks

These guides support the task-based development workflow by providing:

- **Detailed Procedures**: In-depth instructions that tasks reference
- **Best Practices**: Standards that ensure consistent quality across tasks
- **Reference Materials**: Information that multiple tasks may need
- **Methodologies**: Approaches that guide how tasks are executed

## Using the Guides

### For New Team Members

1. Start with the [Terminology Guide](guides/terminology-guide.md) to understand project language
2. Review the [Documentation Guide](guides/documentation-guide.md) for general standards
3. Read guides relevant to your specific role and responsibilities

### For Ongoing Development

1. Reference guides when performing related tasks
2. Consult guides when encountering unfamiliar processes
3. Use guides to maintain consistency across different work sessions

### For Process Improvement

1. Review guides when identifying process inefficiencies
2. Update guides based on lessons learned and feedback
3. Create new guides when recurring questions or issues arise

### For Creating New Guides

1. Use the `New-Guide.ps1` script for consistent guide creation
2. Provide clear, descriptive titles and descriptions
3. Categorize guides appropriately for better organization
4. Follow the established guide structure and formatting standards

## Guide Maintenance

Guides should be regularly reviewed and updated to ensure they remain:

- **Current**: Reflecting the latest processes and best practices
- **Accurate**: Containing correct and verified information
- **Complete**: Covering all necessary aspects of their subject matter
- **Clear**: Written in an accessible and understandable manner

## Feedback and Improvement

When using these guides:

1. **Document Issues**: Note any unclear instructions or missing information
2. **Suggest Improvements**: Propose enhancements based on practical experience
3. **Share Feedback**: Use the [Feedback Form Guide](guides/feedback-form-guide.md) to provide structured feedback
4. **Contribute Updates**: Help maintain guides by suggesting or implementing improvements

## Document ID Format

All Process Framework guides use the following ID format:

`PF-GDE-###`

Where:

- `PF` indicates it's a Process Framework document
- `GDE` indicates it's a Guide
- `###` is a sequential number within the guide type

## Integration with Process Framework

These guides are integral to the Process Framework and work in conjunction with:

- **[Tasks](../tasks/)**: Providing detailed procedures that tasks reference
- **[Templates](../templates/)**: Offering guidance for template creation and use
- **[Methodologies](../methodologies/)**: Supporting established development approaches
- **[State Tracking](../state-tracking/)**: Guiding proper state management practices

---

_This README serves as the central index for all Process Framework guides and provides guidance on their effective use within the development workflow._
