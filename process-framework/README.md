---
id: PF-MAI-000
type: Process Framework
category: Guide
version: 1.0
created: 2025-05-29
updated: 2025-05-29
---

# Process Framework Documentation

## Overview

The Process Framework documentation contains all documents that define, guide, and improve the development process. This directory is separate from Product Documentation, which describes the application itself.

## Directory Structure

The Process Framework documentation is organized into the following directories:

- **[tasks/](../process-framework/tasks)**: Task definitions that guide development activities

  - **[01-planning/](../process-framework/tasks/01-planning)**: Planning and assessment tasks
  - **[02-design/](../process-framework/tasks/02-design)**: Design and specification tasks
  - **[03-testing/](../process-framework/tasks/03-testing)**: Testing and quality assurance tasks
  - **[04-implementation/](../process-framework/tasks/04-implementation)**: Implementation and development tasks
  - **[05-validation/](../process-framework/tasks/05-validation)**: Validation and verification tasks
  - **[06-maintenance/](../process-framework/tasks/06-maintenance)**: Maintenance and improvement tasks
  - **[07-deployment/](../process-framework/tasks/07-deployment)**: Deployment and release tasks

  - **[cyclical/](../process-framework/tasks/cyclical)**: Recurring tasks that follow a defined cycle

- **[state-tracking/](../process-framework-local/state-tracking)**: Persistent project state management

  - **[permanent/](../process-framework-local/state-tracking/permanent)**: Long-term state files including architecture tracking
  - **[temporary/](../process-framework-local/state-tracking/temporary)**: Short-term implementation tracking

- **[templates/](../process-framework/templates)**: Templates for creating consistent process documents

- **[guides/](../process-framework/guides)**: Best practices and reference guides for development

## Key Documents

- [Terminology Guide](guides/framework/terminology-guide.md): Explains the terminology separation between Process Framework and Product Documentation
- [Documentation Map](PF-documentation-map.md): Central reference for all documentation files

- [Architecture Tracking](../doc/state-tracking/permanent/architecture-tracking.md): Cross-cutting architectural state management and AI agent continuity

## Document ID Format

All Process Framework documents use the following ID format:

`PF-XXX-###`

Where:

- `PF` indicates it's a Process Framework document
- `XXX` is a three-letter code for the document type (e.g., TSK for Task, TEM for Template)
- `###` is a sequential number within that type

## Reference Format

When referencing Process Framework documents in markdown files, use the following format:

```
[Process: Document Name](/doc/path/to/document.md)
```

## Relationship to Product Documentation

The Process Framework documentation is distinct from Product Documentation:

- **Process Framework**: Defines how development is done (the process)
- **Product Documentation**: Describes what is being built (the product)

For Product Documentation, see the [Product Documentation directory](/doc).

---

_This README is part of the Process Framework and serves as an entry point to understanding the development process documentation._
