---
id: PF-TSK-021
type: Process Framework
category: Task Definition
version: 1.3
created: 2025-07-21
updated: 2025-01-27
task_type: Discrete
change_notes: "v1.3 - Updated for IMP-097/IMP-098: Clarified database-only scope, added information flow section, updated outputs to remove non-database concerns"
---

# Database Schema Design Task

**🤖 AUTOMATION UPDATE (2025-01-27)**: This task is now **FULLY AUTOMATED** for feature tracking updates. The `New-SchemaDesign.ps1` script automatically updates the DB Design column in feature tracking from "Yes" to the schema design document link when a FeatureId is provided.

## Purpose & Context

Systematic data model planning before implementation to prevent data integrity issues, migration problems, and architectural inconsistencies.

**Scope**: This task focuses exclusively on **database-level concerns**: data structures, relationships, constraints, migrations, and database performance. API specifications, service integration patterns, and comprehensive testing strategies are owned by their respective tasks (API Design, TDD, Test Specification).

## AI Agent Role

**Role**: Database Architect
**Mindset**: Data-integrity focused, performance-aware, scalability-minded
**Focus Areas**: Data modeling, query optimization, migration safety, data consistency
**Communication Style**: Consider data consistency and performance implications, ask about scalability requirements and data access patterns

## When to Use

- When the [Feature Tier Assessment](../01-planning/feature-tier-assessment-task.md) indicates "Yes" in the DB Design column
- Features requiring new data structures or database schema modifications
- Before implementing any feature that changes the data model
- When existing schema needs optimization or refactoring
- Before major database migrations or structural changes
- When data integrity issues are identified that require schema changes
- Prerequisites: Feature requirements defined, Feature Tier Assessment completed

## Information Flow

> **📋 Detailed Guidance**: See [Task Transition Guide - Information Flow Section](../../guides/guides/task-transition-guide.md#task-transitions) for comprehensive information flow patterns.

### Inputs from Other Tasks

- **FDD Creation Task** (PF-TSK-001): Functional requirements, data requirements, business rules, user flows
- **Feature Tier Assessment** (PF-TSK-003): Complexity tier, documentation requirements, confirmation that DB Design is needed
- **API Design Task** (PF-TSK-020): API contracts and data access patterns (when API Design precedes Schema Design)

### Outputs to Other Tasks

- **API Design Task** (PF-TSK-020): Data model, relationships, constraints, security policies (when Schema Design precedes API Design)
- **TDD Creation Task** (PF-TSK-022): Schema design, database performance considerations, data access patterns
- **Test Specification Task** (PF-TSK-012): Validation rules, security policies (RLS), performance requirements, migration testing needs
- **Feature Implementation Task** (PF-TSK-030): Migration scripts, schema specifications, data model documentation

### Separation of Concerns

**This task owns**:

- ✅ Data structures (tables, columns, types)
- ✅ Relationships (foreign keys, joins)
- ✅ Database constraints (unique, not null, check)
- ✅ Database security (RLS policies, grants)
- ✅ Migration scripts and rollback procedures
- ✅ Database performance (indexes, partitioning)

**Other tasks own**:

- ❌ API endpoint specifications → API Design Task (PF-TSK-020)
- ❌ Service integration patterns → API Design Task (PF-TSK-020) or TDD (PF-TSK-022)
- ❌ Comprehensive test plans → Test Specification Task (PF-TSK-012)
- ❌ Implementation details → TDD (PF-TSK-022) or Feature Implementation (PF-TSK-030)

## Context Requirements

[View Context Map for this task](../../visualization/context-maps/02-design/database-schema-design-task-map.md)

- **Critical (Must Read):**

  - **Functional Design Document (FDD)** - For Tier 2+ features, the FDD containing functional requirements and data requirements that inform schema design (located in `/doc/product-docs/functional-design/fdds/`)
  - [Feature Requirements](/doc/process-framework/state-tracking/permanent/feature-tracking.md) - Understanding what functionality requires database changes and confirming DB Design is required
  - [Feature Tier Assessment](../../methodologies/documentation-tiers/assessments) - Assessment that determined database design is needed
  - **Current Database Schema** - Existing schema documentation and structure:
    - Current schema: `/data/`
    - Database reference: `/doc/product-docs/technical/architecture/database-reference.md`
    - Existing schema designs: `/doc/product-docs/technical/database/schemas/`
  - **Data Flow Requirements** - How data moves through the system and integration points

- **Important (Load If Space):**

  - **API Specifications** - Existing API contracts that may be affected by schema changes (located in `/doc/product-docs/technical/api/specifications/`)
  - **Performance Requirements** - Scalability and performance constraints for the data model
  - **Business Rules** - Domain-specific constraints and validation requirements from FDDs
  - **Migration History** - Previous database migrations and their outcomes (located in `/doc/product-docs/technical/database/migrations/`)

- **Reference Only (Access When Needed):**
  - **Database Documentation** - Existing database documentation and conventions:
    - Architecture documentation: `/doc/product-docs/technical/architecture/`
    - Database diagrams: `/doc/product-docs/technical/database/diagrams/`
  - **Security Policies** - Data security and privacy requirements
  - [Visual Notation Guide](/doc/process-framework/guides/guides/visual-notation-guide.md) - For interpreting context map diagrams

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished! 🚨**
>
> **⚠️ MANDATORY: Use the appropriate automation tools where indicated.**

### Preparation

1. **Verify DB Design Requirement**: Confirm in the [Feature Tracking](../../state-tracking/permanent/feature-tracking.md) document that the DB Design column shows "Yes" for this feature
2. Review the [Feature Tier Assessment](../../methodologies/documentation-tiers/assessments) that determined database design is needed
3. **Gather Context**: Load all critical context files including feature requirements, current schema, and data flow requirements
4. **Analyze Current State**: Review existing database schema (`/data/` and `/doc/product-docs/technical/architecture/database-reference.md`) and identify areas that will be affected by the changes
5. **Validate Requirements**: Ensure all functional and non-functional requirements are clearly understood

### Execution

6. **Create Schema Design Document**: Use the schema design script to generate the main design document and automatically update feature tracking
   ```powershell
   # Generate schema design document with automatic feature tracking updates
   Set-Location "c:\Users\ronny\VS_Code\BreakoutBuddies\breakoutbuddies\doc\product-docs\technical\database"
   ../New-SchemaDesign.ps1 -FeatureName "Feature Name" -SchemaType "New|Modification|Optimization" -FeatureId "X.X.X"
   ```
7. **Design Data Model**: Create entity-relationship diagrams and define data structures, relationships, and constraints
8. **Plan Migration Strategy**: Design safe migration scripts with rollback procedures and data preservation strategies
9. **Performance Analysis**: Plan indexes, partitioning, and optimization strategies for the new schema
10. **Validate Design**: Review schema against business rules, technical constraints, and integration requirements

### Finalization

11. **Create Migration Scripts**: Generate production-ready migration scripts with proper rollback procedures
12. **Document Database-Level Integration Notes**: Add brief notes on database access requirements and cross-schema dependencies (detailed API specifications belong in API Design task)
13. **Add Cross-References**: Include brief cross-reference sections linking to API Design and Test Specification tasks where appropriate
14. **Verify Automated Updates**: Confirm that the schema design script automatically updated the [Feature Tracking](../../state-tracking/permanent/feature-tracking.md) document, changing the DB Design column from "Yes" to a link to the schema design
15. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Outputs

- **Schema Design Document** - Comprehensive data model specification in `/doc/product-docs/technical/database/schemas/[feature-name]-schema-design.md`
  - Entity definitions with fields, types, and constraints
  - Relationships and foreign keys
  - Database security policies (RLS)
  - Performance considerations (indexes, partitioning)
  - Brief cross-references to API Design and Test Specification tasks
- **Entity-Relationship Diagram** - Visual representation of data relationships in `/doc/product-docs/technical/database/diagrams/[feature-name]-erd.md`
- **Migration Script** - Safe database migration with rollback procedures in `/doc/product-docs/technical/database/migrations/[timestamp]-[feature-name]-migration.sql`
- **Data Dictionary** - Detailed field definitions and constraints in the schema design document
- **Database-Level Integration Notes** - Brief notes on database access requirements and cross-schema dependencies (detailed API specifications are in API Design task)

## State Tracking

The following state files are updated as part of this task:

- [Feature Tracking](../../state-tracking/permanent/feature-tracking.md) - **AUTOMATICALLY UPDATED** by the schema design script: DB Design column changes from "Yes" to a link to the completed database schema design document
- [Technical Debt Tracking](../../state-tracking/permanent/technical-debt-tracking.md) - **MANUAL UPDATE REQUIRED**: Add any schema optimization opportunities identified during design
- **Database Schema Tracking** - Track schema changes across features (to be created as part of task infrastructure)

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

Before considering this task finished:

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] Schema design document created with comprehensive data model specification
  - [ ] Entity-relationship diagram completed showing all data relationships
  - [ ] Migration script created with rollback procedures
  - [ ] Performance analysis completed with optimization recommendations
  - [ ] Database-level integration notes documented (with cross-references to API Design task for detailed specifications)
  - [ ] Cross-reference sections added linking to API Design and Test Specification tasks
- [ ] **Verify State File Updates**: Ensure all state tracking files have been updated
  - [ ] [Feature Tracking](../../state-tracking/permanent/feature-tracking.md) DB Design column **AUTOMATICALLY UPDATED** from "Yes" to link to completed database schema design document (verify the automation worked correctly)
  - [ ] [Technical Debt Tracking](../../state-tracking/permanent/technical-debt-tracking.md) **MANUALLY UPDATED** with schema optimization opportunities identified during design
  - [ ] Database Schema Tracking updated with new schema changes
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Completion Instructions](../../guides/guides/feedback-form-completion-instructions.md) for each tool used, using task ID "PF-TSK-021" and context "Database Schema Design Task"

## Next Tasks

- [**Feature Implementation Planning**](../04-implementation/feature-implementation-planning-task.md) - Plan and implement the feature using the designed schema
- [**API Design Task**](api-design-task.md) - Design APIs that work with the new data model (if applicable)
- [**Code Review**](../06-maintenance/code-review-task.md) - Review the schema design before implementation begins

## Related Resources

- [System Architecture Review Task](../01-planning/system-architecture-review.md) - For evaluating how schema changes fit into existing architecture
- [API Design Task](api-design-task.md) - For designing APIs that work with the new data model
- [Feature Implementation Planning](../04-implementation/feature-implementation-planning-task.md) - For planning and implementing features using the designed schema
- [Technical Debt Tracking](../../state-tracking/permanent/technical-debt-tracking.md) - For tracking schema optimization opportunities
