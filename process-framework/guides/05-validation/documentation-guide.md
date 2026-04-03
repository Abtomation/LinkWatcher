---
id: PF-GDE-055
type: Process Framework
category: Guide
version: 2.0
created: 2023-06-15
updated: 2026-02-27
---

# Documentation Guide

This guide outlines best practices for writing and structuring documentation. Following these guidelines ensures that documentation is consistent, comprehensive, and useful for all contributors.

## Quick Reference

**Need something specific?**

- Creating new docs: See [File Structure and Naming](#file-structure-and-naming)
- Formatting help: See [Markdown Formatting Guidelines](#markdown-formatting-guidelines)
- Writing style: See [Writing Style and Tone](#writing-style-and-tone)
- Code examples: See [Code Examples](#code-examples)

## Table of Contents

1. [Documentation Types](#documentation-types)
2. [File Structure and Naming](#file-structure-and-naming)
3. [Markdown Formatting Guidelines](#markdown-formatting-guidelines)
4. [Writing Style and Tone](#writing-style-and-tone)
5. [Documentation Components](#documentation-components)
6. [Code Examples](#code-examples)
7. [Images and Diagrams](#images-and-diagrams)
8. [Versioning Documentation](#versioning-documentation)
9. [Review Process](#review-process)
10. [Documentation Maintenance](#documentation-maintenance)

For a comprehensive map of all documentation files and their relationships, see the [Process: Documentation Map](../../PF-documentation-map.md).

## Documentation Types

### 1. README

The project's main entry point. It should include:

- Project overview and purpose
- Quick start guide
- Basic usage examples
- Links to more detailed documentation
- Installation instructions
- License information

### 2. Technical Documentation

Detailed documentation for developers working on the project:

- Architecture overview
- API documentation
- Database schema
- Component documentation
- Testing procedures

### 3. User Guides

Documentation for end-users of the application:

- Feature guides
- Tutorials
- FAQs
- Troubleshooting

### 4. Process Documentation

Documentation for project processes:

- Contribution guidelines
- Code review process
- Release procedures
- Testing protocols

## File Structure and Naming

### Location

- Place documentation files in the appropriate directories:
  - Root-level documentation (README.md, CONTRIBUTING.md, LICENSE) in the project root
  - Technical documentation in the `/doc/technical` directory
  - User guides in `/doc/user`
  - Process documentation in `/doc`

### Naming Conventions

- Use UPPERCASE for root-level documentation files (e.g., README.md, CONTRIBUTING.md)
- Use lowercase with hyphens for other documentation files (e.g., `api-reference.md`, `user-guide.md`)
- Use descriptive names that clearly indicate the content

### Directory Structure Example

```
project/
├── README.md
├── CONTRIBUTING.md
├── LICENSE
├── doc/
│   ├── doc/
│   │   ├── technical/
│   │   │   ├── architecture/
│   │   │   ├── design/
│   │   │   └── implementation/
│   │   ├── guides/
│   │   └── user/
│   └── process-framework/
│       ├── tasks/
│       ├── templates/
│       ├── guides/
│       └── state-tracking/
└── ...
```

## Markdown Formatting Guidelines

All documentation should be written in Markdown for consistency and readability.

### Headers

Use headers to organize content hierarchically:

```markdown
# Main Title (H1) - Use only once per document

## Section (H2)

### Subsection (H3)

#### Minor Subsection (H4)
```

### Lists

Use unordered lists for items without sequence:

```markdown
- Item 1
- Item 2
  - Subitem 2.1
  - Subitem 2.2
```

Use ordered lists for sequential steps:

```markdown
1. First step
2. Second step
   1. Substep 2.1
   2. Substep 2.2
```

### Code Blocks

For inline code, use backticks:

```markdown
Use the `python main.py` command to start the application.
```

For code blocks, use triple backticks with language specification:

````markdown
```python
def main():
    print("Hello, world!")
```
````

### Tables

Use tables for structured data:

```markdown
| Name   | Type | Description         |
| ------ | ---- | ------------------- |
| id     | int  | Unique identifier   |
| name   | str  | User's display name |
```

### Links

For internal links, use relative paths:

```markdown
See the `[API documentation](../../technical/api/reference.md)` for more details.
```

For external links, use full URLs:

```markdown
For more information, visit [Python's documentation](https://docs.python.org/).
```

## Writing Style and Tone

### General Guidelines

- **Be clear and concise**: Use simple language and avoid unnecessary words
- **Be consistent**: Use the same terminology throughout the documentation
- **Use active voice**: "Click the button" instead of "The button should be clicked"
- **Address the reader directly**: Use "you" instead of "the user"
- **Use present tense**: "The function returns a value" instead of "The function will return a value"

### Technical Accuracy

- Ensure all technical information is accurate and up-to-date
- Have technical content reviewed by subject matter experts
- Include version information when relevant

### Accessibility

- Write for a diverse audience with varying technical backgrounds
- Define technical terms and acronyms on first use
- Use inclusive language

## Documentation Components

Each documentation file should include these components:

### 1. Title and Introduction

Start with a clear title and a brief introduction explaining the purpose of the document.

```markdown
# Configuration Reference

This document describes all available configuration options and their defaults.
```

### 2. Table of Contents

For longer documents, include a table of contents:

```markdown
## Table of Contents

1. [Overview](#overview)
2. [Configuration Options](#configuration-options)
3. [Examples](#examples)
```

### 3. Prerequisites

List any prerequisites or requirements:

```markdown
## Prerequisites

- Python 3.8 or higher
- pip package manager
- Basic knowledge of YAML configuration
```

### 4. Main Content

Organize the main content into logical sections using headers.

### 5. Examples

Include practical examples to illustrate concepts.

### 6. Troubleshooting

Add a section for common issues and their solutions.

### 7. Related Resources

Link to related documentation or external resources.

```markdown
## Related Resources

- `[Configuration Reference](../configuration.md)`
- [Python Documentation](https://docs.python.org/)
```

## Code Examples

### Best Practices for Code Examples

- Keep examples simple and focused on the concept being explained
- Include comments to explain complex parts
- Show both the code and the expected output when relevant
- Use syntax highlighting by specifying the language

### Example Template

````markdown
### Example: Processing a File

```python
from pathlib import Path

def process_file(filepath: str) -> dict:
    """Process a file and return its metadata."""
    path = Path(filepath)

    if not path.exists():
        raise FileNotFoundError(f"File not found: {filepath}")

    return {
        "name": path.name,
        "size": path.stat().st_size,
        "extension": path.suffix,
    }
```

**Expected output:**

```
{'name': 'config.yaml', 'size': 1024, 'extension': '.yaml'}
```
````

## Images and Diagrams

### Image Guidelines

- Use images to illustrate complex concepts or UI elements
- Keep images in a `/doc/assets` directory
- Use descriptive filenames (e.g., `architecture-overview.png`)
- Include alt text for accessibility

```markdown
`![Architecture Overview](../../assets/architecture-overview.png)`
```

### Diagram Types

- **Architecture diagrams**: Show system components and their relationships
- **Flow diagrams**: Illustrate processes or workflows
- **Entity-relationship diagrams**: Show database schema
- **Sequence diagrams**: Demonstrate interaction between components

### Tools for Creating Diagrams

- [Draw.io](https://draw.io) (free, web-based)
- [Lucidchart](https://www.lucidchart.com) (freemium)
- [Mermaid](https://mermaid-js.github.io/mermaid/#/) (text-based, can be embedded in Markdown)

## Versioning Documentation

### Version Tagging

- Tag documentation with version information when applicable
- Indicate when features were introduced or deprecated

```markdown
> **Available since:** v1.2.0
> **Deprecated in:** v2.0.0
```

### Handling Changes

- Update documentation when code changes
- Archive outdated documentation instead of deleting it

## Review Process

### Documentation Review Checklist

- [ ] Content is accurate and up-to-date
- [ ] Follows formatting guidelines
- [ ] No spelling or grammatical errors
- [ ] Links work correctly
- [ ] Code examples are correct and follow best practices
- [ ] Images and diagrams are clear and relevant
- [ ] Consistent terminology is used throughout

### Review Workflow

1. Author creates or updates documentation
2. Technical review by subject matter expert
3. Editorial review for clarity and consistency
4. Address feedback and make revisions
5. Final approval and merge

## Documentation Maintenance

### Regular Maintenance

- Review documentation quarterly to ensure it remains accurate
- Update documentation when code changes
- Archive outdated documentation
- Collect and incorporate user feedback

### Maintaining Links Between Documents

**IMPORTANT:** When moving, renaming, or deleting documentation files, you must update all links that reference those files.

To help with this process:

1. **Always consult the [Documentation Map](../../PF-documentation-map.md)** before moving or renaming any documentation file.
2. The Documentation Map lists all documentation files and what other files link to them.
3. When moving or renaming a file, update:
   - The file's entry in the Documentation Map
   - All links in the files listed in the "Linked From" column
   - Any other files that might link to the moved/renamed file

### Updating the Documentation Map

The [Documentation Map](../../PF-documentation-map.md) must be updated whenever documentation is:

- Added
- Moved
- Renamed
- Removed

When adding a new documentation file:

1. Add an entry to the Documentation Map in the appropriate section
2. List all files that link to the new documentation

### Documentation Formatting Standards

To maintain consistency across all documentation:

1. **Link Formatting**

   - All links to documentation files must use Markdown format: `[Link Text](relative/path/to/file.md)`
   - Use relative paths with `./` prefix when linking to files in the same directory
   - Use relative paths with `../` prefix when linking to files in parent directories

2. **Consistency Check**
   - Before committing documentation changes, verify that all links follow these formatting standards
   - Check that all documentation references are properly tracked in the Documentation Map

### Responsibilities

- Assign documentation owners for different areas
- Include documentation updates in the definition of "done" for features
- Make documentation part of the code review process
- Ensure the Documentation Map is kept up-to-date

---

## Example Documentation Structure

Below is an example of how to structure a typical documentation file following these guidelines:

````markdown
# Feature Title

## Overview

Brief description of the feature and its purpose.

## Prerequisites

- Requirement 1
- Requirement 2

## Getting Started

Instructions for getting started with the feature.

### Installation

```bash
pip install package-name
```

### Configuration

Steps to configure the feature.

## Usage

### Basic Usage

Simple examples of how to use the feature.

### Advanced Usage

More complex examples and use cases.

## API Reference

Detailed API documentation.

### Class: FeatureName

#### Methods

| Method  | Parameters   | Return Type | Description            |
| ------- | ------------ | ----------- | ---------------------- |
| method1 | param1: str  | None        | Description of method1 |

## Troubleshooting

Common issues and their solutions.

## Related Resources

- `[Related Documentation](../related-doc.md)`
- [External resource](https://example.com)
````

---

## Related Documentation

- [Documentation Map](../../PF-documentation-map.md) - Central reference for all documentation files
- [Process Improvement Task](../../tasks/support/process-improvement-task.md) - For systematic improvements to documentation processes and structure

By following these guidelines, documentation will be consistent, comprehensive, and useful for all contributors.
