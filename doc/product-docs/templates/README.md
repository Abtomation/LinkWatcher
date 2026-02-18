---
id: PD-TEM-000
type: Product Documentation
category: Templates
version: 1.1
created: 2025-05-30
updated: 2025-07-06
---

# Product Documentation Templates

This directory contains templates for creating various types of Product Documentation. These templates provide consistent structure and formatting for different documentation types.

## Available Templates

| Template | Purpose | When to Use |
|----------|---------|-------------|
| [Product Documentation Template](/doc/product-docs/templates/templates/product-documentation-template.md) | General-purpose template for product documentation | For general documentation that doesn't fit other specific templates |
| [Feature Template](/doc/product-docs/templates/templates/feature-template.md) | Template for feature documentation | When documenting application features and their capabilities |
| [FAQ Template](/doc/product-docs/templates/templates/faq-template.md) | Template for frequently asked questions | When creating FAQ documents for specific topics |
| [User Handbook Template](/doc/product-docs/templates/templates/user-handbook-template.md) | Template for user handbooks and guides | When creating comprehensive user documentation |
| [Implementation Handbook Template](/doc/product-docs/templates/templates/implementation-handbook-template.md) | Template for implementation guides | When documenting how features or components are implemented |
| [ADR Template](/doc/product-docs/templates/templates/adr-template.md) | Template for Architecture Decision Records | When documenting architectural decisions and their rationale |
| [TDD T1 Template](/doc/product-docs/templates/templates/tdd-t1-template.md) | Template for TDD Tier 1 (Feature Planning Document) | When creating lightweight planning documents for simple features |
| [TDD T2 Template](/doc/product-docs/templates/templates/tdd-t2-template.md) | Template for TDD Tier 2 (Lightweight Technical Design Document) | When creating standard TDD with essential sections for moderate complexity features |
| [TDD T3 Template](/doc/product-docs/templates/templates/tdd-t3-template.md) | Template for TDD Tier 3 (Comprehensive Technical Design Document) | When creating comprehensive TDD with all sections for complex features |

## Using Templates

To use a template:

1. Copy the template file to the appropriate directory in the Product Documentation structure
2. Rename the file according to the naming conventions for that documentation type
3. Replace all placeholder text (indicated by [square brackets]) with actual content
4. Update the metadata at the top of the file:
   - Assign a unique ID following the pattern `PD-XXX-###`
   - Set the appropriate type and category
   - Update the version, creation date, and update date
5. Add the new document to the [Process: Documentation Map](/doc/process-framework/documentation-map.md)

## Template Structure

Each template includes:

- **Metadata Header** - Standard metadata for all documentation
- **Title** - Clear, descriptive title
- **Overview** - Brief introduction to the document's purpose
- **Main Content Sections** - Structured according to the document type
- **Related Documentation** - Links to related documents
- **Footer** - Standard footer indicating document type and purpose

## Creating New Templates

If you need to create a new template type:

1. Use the [Product Documentation Template](/doc/product-docs/templates/templates/product-documentation-template.md) as a starting point
2. Adapt the structure to suit the specific documentation type
3. Include clear placeholder text and instructions
4. Add the new template to this README and to the [Process: Documentation Map](/doc/process-framework/documentation-map.md)

## Best Practices

- Keep templates simple and focused
- Include clear instructions for template users
- Use consistent formatting across all templates
- Provide examples where helpful
- Update templates when documentation standards change

---

*This document is part of the Product Documentation and serves as an index for documentation templates.*
