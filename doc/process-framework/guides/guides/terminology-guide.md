---
id: PF-GDE-001
type: Process Framework
category: Guide
version: 1.0
created: 2025-05-29
updated: 2025-05-29
---

# Documentation Terminology Guide

## Purpose

This guide establishes clear terminology for the BreakoutBuddies documentation system, distinguishing between process-related documentation and product-related documentation. It serves as the reference for understanding the documentation organization and naming conventions.

## Terminology Separation

The BreakoutBuddies project now uses two distinct terminology categories for documentation:

### Key Terminology Distinction: Guides vs. Handbooks

- **Guides** are used exclusively in the Process Framework to describe how to perform processes and tasks.
- **Handbooks** are used exclusively in the Product Documentation to provide comprehensive information about product features and implementation.

This clear distinction helps avoid confusion between process-related and product-related documentation.

### 1. Process Framework

**Definition**: All documents that define, guide, and improve the development process itself.

**Examples**:

- Task definitions
- Documentation templates
- Process methodologies
- Document creation systems
- Process improvement guides

**Directory**: `/doc/process-framework/`

**ID Format**: `PF-XXX-###` (e.g., `PF-TSK-001` for a process framework task)

### 2. Product Documentation

**Definition**: All documents that describe the application, its features, and technical implementation.

**Examples**:

- Technical Design Documents (TDDs)
- API references
- User handbooks
- Feature specifications
- Code documentation

**Directory**: `/doc/product-docs/`

**ID Format**: `PD-XXX-###` (e.g., `PD-TDD-001` for a product technical design document)

## Directory Structure

The documentation is organized according to this terminology separation:

```
doc/
├── process-framework/        # Process-related documentation
│   ├── tasks/                # Task definitions
│   │   ├── 01-planning/      # Planning tasks
│   │   ├── 02-design/        # Design tasks
│   │   ├── 03-testing/       # Testing tasks
│   │   ├── 04-implementation/ # Implementation tasks
│   │   ├── 05-validation/    # Validation tasks
│   │   ├── 06-maintenance/   # Maintenance tasks
│   │   ├── 07-deployment/    # Deployment tasks

│   │   └── cyclical/         # Recurring tasks
│   ├── templates/            # Process document templates
│   ├── methodologies/        # Process methodologies
│   └── improvement/          # Process improvement
│
├── product-docs/             # Product-related documentation
    ├── technical/            # Technical documentation
    │   ├── design/           # TDDs and design docs
    │   ├── api/              # API documentation
    │   ├── architecture/     # Architecture documentation
    │   └── implementation/   # Implementation handbooks
    ├── user/                 # User-facing documentation
    │   ├── handbooks/        # User handbooks
    │   ├── features/         # Feature descriptions
    │   └── faq/              # Frequently asked questions
    └── development/          # Developer documentation
```

## Document ID Prefixes

All documentation now uses prefixes in their IDs to clearly indicate their category:

### Process Framework Prefixes

- `PF-TSK`: Process Framework Task
- `PF-TEM`: Process Framework Template
- `PF-MTH`: Process Framework Methodology
- `PF-GDE`: Process Framework Guide
- `PF-IMP`: Process Framework Improvement

### Product Documentation Prefixes

- `PD-TDD`: Product Technical Design Document
- `PD-API`: Product API Documentation
- `PD-ARC`: Product Architecture Documentation
- `PD-USR`: Product User Documentation
- `PD-UHB`: Product User Handbook
- `PD-IHB`: Product Implementation Handbook
- `PD-DEV`: Product Development Documentation

## Document Metadata

All documentation files include metadata that explicitly categorizes them:

### Process Framework Metadata Example

```yaml
---
id: PF-TSK-XXX
type: Process Framework
category: Task Definition
version: 1.0
created: YYYY-MM-DD
updated: YYYY-MM-DD
task_type: Discrete # If applicable
---
```

### Product Documentation Metadata Example

```yaml
---
id: PD-TDD-XXX
type: Product Documentation
category: Technical Design
version: 1.0
created: YYYY-MM-DD
updated: YYYY-MM-DD
feature: "Authentication" # If applicable
---
```

## Reference System

When referencing documents in markdown files, use the following format to clearly indicate the document category:

- Process Framework reference: `[Process: Task Definition](../../../tasks/04-implementation/feature-implementation-task.md)`
- Process Framework guide: `[Process: Documentation Guide](../../documentation-guide.md)`
- Product Documentation reference: `<!-- [Product: Authentication API](../../../../product-docs/technical/api/authentication.md) - File not found -->`
- Product User Handbook: `[Product: User Handbook](../../../../product-docs/user/handbooks/creating-an-account.md)`
- Product Implementation Handbook: `<!-- [Product: Implementation Handbook](../../../../product-docs/technical/implementation/state-management-implementation.md) - File not found -->`

## Transition Period

During the transition period:

1. All new documentation should follow the new terminology and organization
2. Existing documentation will be gradually migrated to the new structure
3. Redirect files will be placed in old locations pointing to new locations
4. The documentation map will be updated to reflect both old and new locations

## Questions and Support

If you have questions about the new terminology or organization, please refer to:

- [Process: Documentation Map](../../../documentation-map.md)
- [Process: Document Creation System](../../../improvement/document-creation-system.md)

---

_This terminology guide is part of the Process Framework and should be referenced when creating or updating any documentation in the BreakoutBuddies project._
