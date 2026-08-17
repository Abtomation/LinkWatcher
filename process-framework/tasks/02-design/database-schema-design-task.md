---
id: PF-TSK-021
type: Process Framework
category: Task Definition
version: 1.6
created: 2025-07-21
updated: 2026-08-04
change_notes: "v1.3 - Updated for IMP-097/IMP-098: Clarified database-only scope, added information flow section, updated outputs to remove non-database concerns"
description: "Plan data model changes before coding to prevent data integrity issues"
complexity: medium
use_when: >-
  Plan data model changes before coding to prevent data integrity issues
automation: full
scripts:
  - ../../scripts/file-creation/02-design/New-SchemaDesign.ps1
trigger_status:
  - file: feature-tracking.md
    status: "🗄️ Needs DB Design"
output_status:
  - raw: "`feature-tracking.md` Status → next design-chain gate still flagged (`🔌 Needs API Design` / `🎨 Needs UI Design` / `📜 Needs Instruction Design`) else `📝 Needs TDD` (Tier 2+) / `🔧 Needs Impl Plan` (Tier 1 — Tier 1 skips TDD); Schema Design row inserted into per-feature state file's §4 Documentation Inventory (PF-PRO-002)"
next_tasks:
  - task: ../04-implementation/feature-implementation-planning-task.md
    condition: "Plan and implement the feature using the designed schema"
  - task: api-design-task.md
    condition: "Design APIs that work with the new data model (if applicable)"
  - task: ui-design-task.md
    condition: "Feature Status is `🎨 Needs UI Design` — the design-chain gate after API"
  - task: instruction-design-task.md
    condition: "Feature Status is `📜 Needs Instruction Design` — the feature has an instruction dimension"
  - task: ../06-maintenance/code-review-task.md
    condition: "Review the schema design before implementation begins"
---

# Database Schema Design Task

> **▶ Execute this task under the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md).** This file holds only this task's specific content; the universal contract every task shares lives once in the protocol and is mandatory here.

**🤖 AUTOMATION UPDATE (PF-PRO-002 / PF-IMP-760)**: This task is **FULLY AUTOMATED**. The `New-SchemaDesign.ps1` script (via the shared `Invoke-DesignArtifactCreation` core) inserts a Schema Design row into the per-feature state file's §4 Documentation Inventory and updates the feature-tracking.md row's Status. The feature-tracking.md schema no longer carries a DB Design column — the design-required flag from Tier Assessment is preserved in the per-feature state file and drives the next-action Status transition.

## Purpose & Context

Systematic data model planning before implementation to prevent data integrity issues, migration problems, and architectural inconsistencies.

**Scope**: This task focuses exclusively on **database-level concerns**: data structures, relationships, constraints, migrations, and database performance. API specifications, service integration patterns, and comprehensive testing strategies are owned by their respective tasks (API Design, TDD, Test Specification).

## AI Agent Role

**Role**: Database Architect
**Mindset**: Data-integrity focused, performance-aware, scalability-minded
**Focus Areas**: Data modeling, query optimization, migration safety, data consistency
**Communication Style**: Consider data consistency and performance implications, ask about scalability requirements and data access patterns

## Information Flow

> **📋 Ownership & cross-reference rules**: [Information Flow Guide → Database Schema Design Task (PF-TSK-021)](../../guides/framework/information-flow-guide.md#database-schema-design-task-pf-tsk-021) — what this task owns, what it references instead, and the cross-reference format.

### Inputs from Other Tasks

- **FDD Creation Task** (PF-TSK-027): Functional requirements, data requirements, business rules, user flows
- **Tier assessment** (via Feature Request Evaluation, PF-TSK-067): Complexity tier, documentation requirements, confirmation that DB Design is needed
- **API Design Task** (PF-TSK-020): API contracts and data access patterns (when API Design precedes Schema Design)

### Outputs to Other Tasks

- **API Design Task** (PF-TSK-020): Data model, relationships, constraints, security policies (when Schema Design precedes API Design)
- **TDD Creation Task** (PF-TSK-015): Schema design, database performance considerations, data access patterns
- **Test Specification Task** (PF-TSK-012): Validation rules, security policies (RLS), performance requirements, migration testing needs
- **Decomposed implementation tasks**: Migration scripts, schema specifications, data model documentation

## Context Requirements

- **Critical (Must Read):**

  - **Functional Design Document (FDD)** - For Tier 2+ features, the FDD containing functional requirements and data requirements that inform schema design (located in `/doc/functional-design/fdds`)
  - [Feature Requirements](../../../doc/state-tracking/permanent/feature-tracking.md) - Understanding what functionality requires database changes and confirming DB Design is required
  - **Tier assessment** - The tier assessment for this feature (locate via [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md))
  - **Current Database Schema** - Existing schema documentation and structure:
    - Current schema: `/data`
    - Database reference: `/doc/technical/architecture/database-reference.md`
    - Existing schema designs: `/doc/technical/database/schemas`
  - **Data Flow Requirements** - How data moves through the system and integration points

- **Important (Load If Space):**

  - **API Specifications** - Existing API contracts that may be affected by schema changes (located in `/doc/technical/api/specifications`)
  - **Performance Requirements** - Scalability and performance constraints for the data model
  - **Business Rules** - Domain-specific constraints and validation requirements from FDDs
  - **Migration History** - Previous database migrations and their outcomes (located in `/doc/technical/database/migrations`)

- **Reference Only (Access When Needed):**
  - **Database Documentation** - Existing database documentation and conventions:
    - Architecture documentation: `/doc/technical/architecture`
    - Database diagrams: `/doc/technical/database/diagrams`
  - **Security Policies** - Data security and privacy requirements

## Process

> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

### Preparation

1. **Verify DB Design Requirement**: Confirm the feature's Status in [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) is `🗄️ Needs DB Design` (set by Tier Assessment when database design is required for this feature)
2. Review the [Feature Tier Assessment](../../../doc/documentation-tiers/assessments) that determined database design is needed
3. **Gather Context**: Load all critical context files including feature requirements, current schema, and data flow requirements
4. **Analyze Current State**: Review existing database schema (`/data` and `/doc/technical/architecture/database-reference.md`) and identify areas that will be affected by the changes
5. **Validate Requirements**: Ensure all functional and non-functional requirements are clearly understood
6. **🚨 CHECKPOINT**: Present current schema analysis, identified impact areas, and requirements to human partner for approval

### Execution

7. **Create Schema Design Document**: Use the schema design script to generate the main design document and automatically update feature tracking
   ```powershell
   # Generate schema design document with automatic feature tracking updates
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/02-design/New-SchemaDesign.ps1 -FeatureName "Feature Name" -SchemaType "New|Modification|Optimization" -FeatureId "X.X.X"
   ```
8. **Design Data Model**: Create entity-relationship diagrams and define data structures, relationships, and constraints
9. **Plan Migration Strategy**: Design safe migration scripts with rollback procedures and data preservation strategies
10. **Performance Analysis**: Plan indexes, partitioning, and optimization strategies for the new schema
11. **Validate Design**: Review schema against business rules, technical constraints, and integration requirements
12. **🚨 CHECKPOINT**: Present schema design, data model, migration strategy, and performance analysis to human partner for review and approval

### Finalization

13. **Create Migration Scripts**: Generate production-ready migration scripts with proper rollback procedures
14. **Document Database-Level Integration Notes**: Add brief notes on database access requirements and cross-schema dependencies (detailed API specifications belong in API Design task)
15. **Add Cross-References**: Include brief cross-reference sections linking to API Design and Test Specification tasks where appropriate
16. **Verify Automated Updates**: Confirm that `New-SchemaDesign.ps1` automatically inserted a Schema Design row into the per-feature state file's §4 Documentation Inventory and updated the [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) row's Status to the next design gate
17. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Outputs

- **Schema Design Document** - Comprehensive data model specification in `/doc/technical/database/schemas/[feature-name]-schema-design.md`
  - Entity definitions with fields, types, and constraints
  - Relationships and foreign keys
  - Database security policies (RLS)
  - Performance considerations (indexes, partitioning)
  - Brief cross-references to API Design and Test Specification tasks
- **Entity-Relationship Diagram** - Visual representation of data relationships in `/doc/technical/database/diagrams/[feature-name]-erd.md`
- **Migration Script** - Safe database migration with rollback procedures in `/doc/technical/database/migrations/[timestamp]-[feature-name]-migration.sql`
- **Data Dictionary** - Detailed field definitions and constraints in the schema design document
- **Database-Level Integration Notes** - Brief notes on database access requirements and cross-schema dependencies (detailed API specifications are in API Design task)

## Example Output

A completed schema design should look like this (abbreviated):

```markdown
# Schema Design: User Profile (2.3.1)

## Entity Definitions
### user_profiles
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PK, DEFAULT gen_random_uuid() | Profile identifier |
| user_id | UUID | FK -> auth.users, UNIQUE, NOT NULL | Owning user |
| display_name | VARCHAR(50) | NOT NULL, CHECK(length >= 3) | Display name |
| avatar_url | TEXT | NULLABLE | S3 object URL |
| updated_at | TIMESTAMPTZ | NOT NULL, DEFAULT now() | Last modification |

### Relationships
- user_profiles.user_id -> auth.users.id (1:1, CASCADE DELETE)

## Indexing Strategy
- PRIMARY: user_profiles(id)
- UNIQUE: user_profiles(user_id) — profile lookup by user
- INDEX: user_profiles(updated_at DESC) — recent activity queries

## Migration Plan
### Up
ALTER TABLE public ADD user_profiles (...);
CREATE INDEX idx_profiles_updated ON user_profiles(updated_at DESC);

### Rollback
DROP TABLE IF EXISTS public.user_profiles;
```

## State Tracking

The following state files are updated as part of this task:

- [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) - **AUTOMATICALLY UPDATED** by the schema design script:
  - Status: set to the next design-chain gate still flagged (`🔌 Needs API Design`, then `🎨 Needs UI Design`, then `📜 Needs Instruction Design`); with none left, `📝 Needs TDD` (Tier 2+) or `🔧 Needs Impl Plan` (Tier 1, since Tier 1 skips TDD)
- Per-feature state file (`doc/state-tracking/features/<id>-implementation-state.md`) - **AUTOMATICALLY UPDATED**:
  - Schema Design row inserted into §4 Documentation Inventory (PF-PRO-002 / PF-IMP-760)
- [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md) - **MANUAL UPDATE REQUIRED**: Add any schema optimization opportunities identified during design
- **Database Schema Tracking** - Track schema changes across features (to be created as part of task infrastructure)

## ⚠️ MANDATORY Task Completion Checklist

> Completion discipline, output verification, and the feedback form are governed by the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md) (Phase C). The items below are the **task-specific** verifications that plug into it.

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] Schema design document created with comprehensive data model specification
  - [ ] Entity-relationship diagram completed showing all data relationships
  - [ ] Migration script created with rollback procedures
  - [ ] Performance analysis completed with optimization recommendations
  - [ ] Database-level integration notes documented (with cross-references to API Design task for detailed specifications)
  - [ ] Cross-reference sections added linking to API Design and Test Specification tasks
- [ ] **Verify State File Updates**: Ensure all state tracking files have been updated
  - [ ] [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) row Status **AUTOMATICALLY UPDATED** to next design gate; Schema Design row **AUTOMATICALLY INSERTED** into per-feature state file's §4 Documentation Inventory (verify both automations worked correctly)
  - [ ] [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md) **MANUALLY UPDATED** with schema optimization opportunities identified during design
  - [ ] Database Schema Tracking updated with new schema changes
- [ ] **Feedback form** completed per the [Task Execution Protocol → Feedback step](../../guides/framework/task-execution-protocol-guide.md#feedback-step) — task ID `PF-TSK-021`, context "Database Schema Design Task".

## File Operations

| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | `[feature-name]-schema-design.md` | `New-SchemaDesign.ps1` | Complete database schema design document with comprehensive data model specification |
| **Creates** | Migration scripts (multiple) | `New-SchemaDesign.ps1` | Database migration files for schema changes with rollback procedures |
| **Creates** | ERD diagrams (multiple) | `New-SchemaDesign.ps1` | Entity-relationship diagrams for visual schema representation |
| **Updates** | [`feature-tracking.md`](../../../doc/state-tracking/permanent/feature-tracking.md) | `New-SchemaDesign.ps1` | Status: `🗄️ Needs DB Design` → next design gate<br/>• Add schema design creation date to Notes |
| **Updates** | Per-feature state file (`doc/state-tracking/features/<id>-implementation-state.md`) | `New-SchemaDesign.ps1` (via `Add-StateFileDocumentationInventoryRow`) | Insert Schema Design row into §4 Documentation Inventory (PF-PRO-002 / PF-IMP-760) |
| **Updates** | [`technical-debt-tracking.md`](../../../doc/state-tracking/permanent/technical-debt-tracking.md) | Manual | Add schema optimization opportunities identified during design |

## Next Tasks

- [**Feature Implementation Planning**](../04-implementation/feature-implementation-planning-task.md) - Plan and implement the feature using the designed schema
- [**API Design Task**](api-design-task.md) - Design APIs that work with the new data model (if applicable)
- [**Code Review**](../06-maintenance/code-review-task.md) - Review the schema design before implementation begins

<!-- merged from transition-registry entry: Database Schema Design -->
### Prerequisites for Transition

- [ ] Database schema design document created
- [ ] Schema changes documented with migration plan
- [ ] Data integrity constraints defined
- [ ] Schema design linked in Feature Tracking

### Next Task Selection

- **Next design-chain gate** (recomputed feature Status; order DB → API → 🎨 UI → 📜 Instruction → TDD): → **API Design** (`🔌 Needs API Design`), **UI Design** (`🎨 Needs UI Design`) or **Instruction Design** (`📜 Needs Instruction Design`) if still flagged, otherwise → **TDD Creation** (`🔧 Needs Impl Plan` for Tier 1). Schema design informs the technical implementation that follows.

### Preparation for Next Task

1. Review schema design to understand data model requirements
2. Ensure schema changes align with feature requirements
3. Verify migration plan is feasible and safe
4. Prepare database context for technical design decisions

## Related Resources

- [System Architecture Review Task](../01-planning/system-architecture-review.md) - For evaluating how schema changes fit into existing architecture
- [API Design Task](api-design-task.md) - For designing APIs that work with the new data model
- [Feature Implementation Planning](../04-implementation/feature-implementation-planning-task.md) - For planning and implementing features using the designed schema
- [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md) - For tracking schema optimization opportunities
