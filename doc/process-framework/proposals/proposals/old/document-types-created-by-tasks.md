# Document Types Created by Framework Tasks

## Overview

This document catalogs all document types created by framework tasks to support the design of the Retrospective Feature Documentation task.

**Created**: 2026-02-17
**Purpose**: Inventory of outputs for retrospective documentation planning

---

## Document Types by Task Category

### 01-Planning Tasks

#### Feature Tier Assessment Task (PF-TSK-002)
- **Assessment Document** (ART-ASS-XXX)
  - Location: `/doc/process-framework/methodologies/documentation-tiers/assessments/`
  - Format: `ART-ASS-XXX-[feature-id]-[feature-name].md`
  - Content: Tier assignment, design requirements evaluation, complexity scores

### 02-Design Tasks

#### FDD Creation Task (PF-TSK-010)
- **Functional Design Document** (PD-FDD-XXX)
  - Location: `/doc/product-docs/functional-design/fdds/`
  - Format: `fdd-[feature-id]-[feature-name].md`
  - Content: Functional requirements, user stories, acceptance criteria, business rules

#### TDD Creation Task (PF-TSK-022)
- **Technical Design Document** (PD-TDD-XXX)
  - Location: `/doc/product-docs/technical/architecture/design-docs/tdd/`
  - Format: `tdd-[assessment-id]-[feature-name]-t[tier].md`
  - Content: Technical architecture, component design, implementation approach

#### ADR Creation Task (PF-TSK-023)
- **Architecture Decision Record** (PD-ADR-XXX)
  - Location: `/doc/product-docs/technical/architecture/design-docs/adr/adr/`
  - Format: Assigned automatically by script
  - Content: Decision context, alternatives considered, consequences

#### API Design Task (PF-TSK-020)
- **API Specification Document** (PD-API-XXX)
  - Location: `/doc/product-docs/technical/api/specifications/specifications/`
  - Format: `[api-name].md`
  - Content: API contracts, endpoints, authentication, error handling
- **Request Data Model**
  - Location: `/doc/product-docs/technical/api/models/`
  - Format: `[api-name]-request.md`
  - Content: Request schema definitions
- **Response Data Model**
  - Location: `/doc/product-docs/technical/api/models/`
  - Format: `[api-name]-response.md`
  - Content: Response schema definitions

#### Database Schema Design Task (PF-TSK-021)
- **Schema Design Document** (PD-SCH-XXX)
  - Location: `/doc/product-docs/technical/database/schemas/`
  - Format: `[feature-name]-schema-design.md`
  - Content: Entity definitions, relationships, constraints, RLS policies
- **Entity-Relationship Diagram**
  - Location: `/doc/product-docs/technical/database/diagrams/`
  - Format: `[feature-name]-erd.md`
  - Content: Visual data model representation
- **Migration Script**
  - Location: `/doc/product-docs/technical/database/migrations/`
  - Format: `[timestamp]-[feature-name]-migration.sql`
  - Content: Database migration with rollback procedures

#### UI/UX Design Task (PF-TSK-035)
- **UI/UX Design Document** (PD-UID-XXX)
  - Location: `/doc/product-docs/technical/design/ui-ux/features/`
  - Format: `[feature-name]-ui-design.md`
  - Content: Wireframes, visual specs, component specs, accessibility, responsive design

### 03-Testing Tasks

#### Test Specification Creation Task (PF-TSK-012)
- **Test Specification Document** (PD-TST-XXX)
  - Location: `/test/specifications/feature-specs/`
  - Format: `test-spec-[FEATURE-ID]-[feature-name].md`
  - Content: Test plans, test cases, mock requirements, acceptance criteria

### 04-Implementation Tasks

#### Feature Implementation Planning Task (PF-TSK-044)
- **Implementation Plan Document** (PD-IMP-XXX)
  - Location: `/doc/product-docs/technical/implementation-plans/`
  - Format: `[feature-id]-[feature-name]-implementation-plan.md`
  - Content: Implementation phases, file mapping, dependency map, testing strategy
- **Feature Implementation State File** (PF-FIS-XXX) - **PERMANENT**
  - Location: `/doc/process-framework/state-tracking/features/`
  - Format: `[feature-id]-implementation-state.md`
  - Content: Living document tracking implementation progress, code inventory, design decisions

---

## Summary by Feature Tier

### Tier 1 (Simple) - Required Documents
- Assessment Document ✅ (Already done for all 42 features)

### Tier 2 (Moderate) - Required Documents
- Assessment Document ✅ (Already done)
- **FDD** (Functional Design Document) - **TO CREATE**
- **TDD** (Technical Design Document) - **TO CREATE**
- Conditional: API Design, DB Schema Design, UI/UX Design (if marked "Yes" in assessment)

### Tier 3 (Complex) - Required Documents
- Assessment Document ✅ (Already done)
- **FDD** (Functional Design Document) - **TO CREATE**
- **TDD** (Technical Design Document) - **TO CREATE**
- **Test Specification** - **TO CREATE**
- Conditional: API Design, DB Schema Design, UI/UX Design (if marked "Yes" in assessment)

### Foundation Features (0.x.x) - Required Documents
- Assessment Document ✅ (Already done)
- **FDD** (if Tier 2+) - **TO CREATE**
- **TDD** (if Tier 2+) - **TO CREATE**
- **ADR** (Architecture Decision Records) - **TO CREATE** for architectural decisions
- **Test Specification** (if Tier 3) - **TO CREATE**
- Conditional: API Design, DB Schema Design (common for foundation features)

---

## Key Insights for Retrospective Documentation

### Documents NOT Created by Retrospective
These are forward-looking planning/implementation documents:
- Implementation Plan (PD-IMP-XXX) - Only for future implementations
- Implementation State File (PF-FIS-XXX) - **EXCEPT**: Used as analysis tool in retrospective

### Core Retrospective Workflow Pattern

**For each feature**:
1. **Analysis Phase** - Create/use Feature Implementation State file to analyze existing code
2. **Documentation Phase** - Create design documents based on discovered implementation
3. **Linking Phase** - Update Feature Tracking with all document links

---

## Recommendations for Retrospective Task

### Use Feature Implementation State as Analysis Tool
The Feature Implementation State template is perfect for retrospective analysis because it:
- Catalogs all existing files (created, modified, used)
- Documents actual dependencies (not planned ones)
- Records design decisions discovered in code
- Maps code to test files

### Create Only Design Documents
For retrospective, create:
- ✅ FDD (Tier 2+)
- ✅ TDD (Tier 2+)
- ✅ Test Specification (Tier 3)
- ✅ ADR (Foundation 0.x.x features)
- ✅ API/DB/UI Design (if assessment indicates needed)

Do NOT create:
- ❌ Implementation Plans (forward-looking)
- ❌ Assessment Documents (already exist)

### Multi-Session State Tracking
Retrospective task should have its own state tracking because:
- Analysis phase may take multiple sessions (for complex features)
- Documentation creation spans multiple sessions
- Need to track which design documents are complete

---

## Proposed Retrospective State File Structure

**File**: `/doc/process-framework/state-tracking/temporary/retrospective-[feature-id]-state.md`

**Sections**:
- Feature Information (ID, name, tier)
- Analysis Progress (code inventory status)
- Documentation Status (which docs created, which pending)
- Session Notes (discoveries, decisions)
- Next Steps (what to do next session)

**This file is TEMPORARY** - archived when feature documentation is complete.
