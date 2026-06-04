---
id: PF-TSK-020
type: Process Framework
category: Task Definition
version: 1.4
created: 2025-07-19
updated: 2026-05-16
change_notes: "v1.2 - Added Information Flow section for IMP-097/IMP-098"
description: "Design comprehensive API contracts and specifications before implementation begins"
---

# API Design Task

## Purpose & Context

Design comprehensive API contracts and specifications before implementation begins, ensuring consistent interfaces and proper integration patterns

**🔒 API Scope**: All project APIs are **internal-only** and designed exclusively for use within the application ecosystem. These APIs are not public-facing and are not intended for third-party integrations or external consumers.

## 🤖 Automation Status

**✅ FULLY AUTOMATED TASK** - Complete automation available

**✅ AUTOMATED COMPONENTS:**

- API specification document creation with proper ID and structure
- Request and response data model creation with validation rules
- Feature tracking updates with intelligent replacement/append logic:
  - **First API specification**: Replaces "Yes" with clickable API specification link
  - **Additional API specifications**: Appends with " • " separator to existing links
- Correct relative path generation for clickable links
- Timestamped automation notes and audit trail

**🔧 MANUAL COMPONENTS:**

- Data models registry updates
- Technical debt tracking updates

## AI Agent Role

**Role**: API Architect
**Mindset**: Contract-first, integration-focused, standards-aware
**Focus Areas**: API design, integration patterns, versioning, backward compatibility
**Communication Style**: Discuss API evolution and backward compatibility, ask about integration requirements and consumer needs

## Information Flow

> **📋 Detailed Guidance**: See [Information Flow Guide](../../guides/framework/information-flow-guide.md)

This task focuses exclusively on **API-level concerns**: endpoint specifications, request/response contracts, authentication patterns, and service integration protocols.

### Inputs from Other Tasks

- **FDD Creation Task** (PF-TSK-010): Functional requirements, user flows, data requirements (high-level)
- **Feature Tier Assessment** (PF-TSK-002): Complexity tier, documentation requirements
- **System Architecture Review** (PF-TSK-011): Architectural decisions, patterns, integration constraints
- **Database Schema Design** (PF-TSK-021): Data model, relationships, constraints (when schema is designed first)

### Outputs to Other Tasks

- **Database Schema Design Task** (PF-TSK-021): Data access patterns, API-level data requirements
- **TDD Creation Task** (PF-TSK-022): API contracts, endpoint specifications, integration patterns
- **Test Specification Task** (PF-TSK-012): API contracts, error scenarios, authentication requirements
- **Feature Implementation Task** (PF-TSK-030): API specifications, data models, integration requirements

### Cross-Reference Standards

When referencing this task's outputs in other tasks:

- Use brief summary (2-5 sentences) + link to API specification document
- Focus on task-specific perspective:
  - **Database Schema Design**: Focus on data access patterns and database-level requirements
  - **TDD**: Focus on service implementation and integration patterns
  - **Test Specification**: Focus on API contract validation and error scenarios
- Avoid duplicating detailed endpoint specifications, request/response schemas, or authentication patterns

### Separation of Concerns

**✅ This task owns**:

- API endpoint specifications (paths, methods, parameters)
- Request/response schemas and data contracts
- API authentication and authorization patterns
- API error handling and status codes
- API versioning strategy
- Service integration patterns and communication protocols

**❌ Other tasks own**:

- Database schema details → Database Schema Design (PF-TSK-021)
- Service implementation details → TDD (PF-TSK-022)
- Functional requirements → FDD (PF-TSK-010)
- Comprehensive test plans → Test Specification (PF-TSK-012)

## Context Requirements

[View Context Map for this task](../../visualization/context-maps/02-design/api-design-task-map.md)

- **Critical (Must Read):**

  - **Functional Design Document (FDD)** - For Tier 2+ features, the FDD containing functional requirements and user flows that inform API design
  - [Feature Requirements](../../../doc/state-tracking/permanent/feature-tracking.md) - Understanding what functionality the API must support and confirming API Design is required
  - **Feature Tier Assessment** - The tier assessment for this feature (locate via [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md))
  - **System Architecture Review Results** - Architecture decisions that impact API design (if a review was conducted)

- **Important (Load If Space):**

  - **Existing API Documentation** - Current API patterns and conventions for the project (if available)
  - [Technical Design Documents](../../../doc/technical/tdd) - Related technical designs

- **Reference Only (Access When Needed):**
  - [API Design Best Practices](https://restfulapi.net/) - Industry standards for REST API design
  - [OpenAPI Specification](https://swagger.io/specification/) - Standard for API documentation
  - [Visual Notation Guide](../../guides/support/visual-notation-guide.md) - For interpreting context map diagrams

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished!**
>
> **⚠️ MANDATORY: Use the appropriate automation tools where indicated.**
>
> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

### Preparation

1. **Verify API Design Requirement**: Confirm the feature's Status in [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) is `🔌 Needs API Design` (set by Tier Assessment when API design is required for this feature)
2. Review the [Feature Tier Assessment](../../../doc/documentation-tiers/assessments) of this feature that determined API design is needed
3. Review feature requirements and understand the functionality that needs API support
4. Examine existing API patterns and conventions in the project
5. Identify data models and schemas that will be needed for the API
6. **🚨 CHECKPOINT**: Present preparation findings, identified API patterns, and data model requirements to human partner for approval

### Execution

7. **🤖 AUTOMATED - Create API Specification Document**: Use the automation script to generate the main API contract and update feature tracking:

   ```powershell
   cd doc/technical/api/specifications
   ../../../scripts/file-creation/New-APISpecification.ps1 -APIName "[Feature Name] API" -APIDescription "[Brief description]" -APIType "REST" -FeatureId "[FeatureId]"
   ```

   **✅ AUTOMATION FEATURES:**

   - Creates API specification document with proper ID and structure
   - **Automatically inserts an API Specification row** into the per-feature state file's §4 Documentation Inventory (PF-PRO-002 / PF-IMP-760). Additional API specs become additional rows.
   - **Automatically updates feature-tracking.md** Status to the next gate (`📝 Needs TDD` / `🔧 Needs Impl Plan`)
   - Adds timestamped automation notes to feature-tracking.md Notes column
   - Provides comprehensive feedback and next steps

8. **Define API Contract**: Specify endpoints, HTTP methods, URL patterns, authentication, and error handling following RESTful conventions

    - **Reference the Response Status Catalog** in your Status Codes section
    - Use the canonical status codes defined in the catalog for consistency

9. **🔄 SEMI-AUTOMATED - Create Request Data Model**: Generate detailed request schema with validation rules (only if not reusing existing model):

    ```powershell
    cd doc/technical/api/models
    ../../scripts/file-creation/02-design/New-APIDataModel.ps1 -ModelName "[API Name] Request" -ModelDescription "[Brief description]" -FeatureId "[FeatureId]"
    ```

    **✅ AUTOMATED**: API Data Model row inserted into the per-feature state file's §4 Documentation Inventory (PF-PRO-002 / PF-IMP-760)

10. **🔄 SEMI-AUTOMATED - Create Response Data Model**: Generate detailed response schema with field definitions (only if not reusing existing model):

    ```powershell
    cd doc/technical/api/models
    ../../scripts/file-creation/02-design/New-APIDataModel.ps1 -ModelName "[API Name] Response" -ModelDescription "[Brief description]" -FeatureId "[FeatureId]"
    ```

    **✅ AUTOMATED**: API Data Model row inserted into the per-feature state file's §4 Documentation Inventory (PF-PRO-002 / PF-IMP-760)

11. **🤖 AUTOMATED - Create API Documentation** (optional): If developer-facing documentation is needed, generate it from template:

    ```powershell
    cd process-framework/scripts/file-creation/02-design
    .\New-APIDocumentation.ps1 -APIName "[API Name]" -APIVersion "[version]" -TargetAudience "[audience]"
    ```

    This creates a user-facing documentation page in `doc/technical/api/documentation/` complementing the technical specification.

12. **Review Design Consistency**: Validate API design against existing patterns and architectural decisions
13. **🚨 CHECKPOINT**: Present complete API design including specification, data models, and contract details to human partner for review and approval

### Finalization

14. **Validate Complete Design**: Ensure API specification and data models work together cohesively
15. **✅ AUTOMATED - State File Updates**: API specification and data model rows automatically inserted into the per-feature state file's §4 Documentation Inventory by `New-APISpecification.ps1` and `New-APIDataModel.ps1` (via the shared `Invoke-DesignArtifactCreation` core, PF-PRO-002 / PF-IMP-760). Feature-tracking.md Status auto-advances to next gate.
16. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Outputs

- **API Specification Document** - Comprehensive API contract definition saved to `/doc/technical/api/specifications/specifications/[api-name].md`
- **Request Data Model** - Schema definition for request objects saved to `/doc/technical/api/models/[api-name]-request.md`
- **Response Data Model** - Schema definition for response objects saved to `/doc/technical/api/models/[api-name]-response.md`

## Example Output

A completed API specification should look like this (abbreviated):

```markdown
# API Specification: User Profile API

## Overview
RESTful API for managing user profile data. All endpoints require
Bearer token authentication.

## Endpoints
### GET /api/v1/profile/{user_id}
- **Description**: Retrieve user profile
- **Auth**: Required (own profile or admin role)
- **Response**: 200 OK

| Field | Type | Description |
|-------|------|-------------|
| user_id | UUID | Unique user identifier |
| display_name | string | User's display name (3-50 chars) |
| avatar_url | string? | URL to avatar image |

### PUT /api/v1/profile/{user_id}
- **Description**: Update user profile
- **Auth**: Required (own profile only)
- **Request Body**: { display_name?: string, avatar?: file }
- **Response**: 200 OK (updated profile) | 422 Validation Error
- **Rate Limit**: 10 requests/minute per user

## Error Handling
| Code | Meaning | When |
|------|---------|------|
| 404 | Profile not found | Invalid user_id |
| 429 | Rate limited | Display name change within 24h |
```

## State Tracking

The following state files must be updated as part of this task:

- **✅ AUTOMATED** - [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md):
  - Status: set to `📝 Needs TDD` (Tier 2+ — API Design is the last design step before TDD) or `🔧 Needs Impl Plan` (Tier 1 — Tier 1 skips TDD)
- **✅ AUTOMATED** - Per-feature state file (`doc/state-tracking/features/<id>-implementation-state.md`):
  - API Specification and API Data Model rows inserted into §4 Documentation Inventory by `New-APISpecification.ps1` / `New-APIDataModel.ps1` (PF-PRO-002 / PF-IMP-760)
- **🔧 MANUAL** - [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md) - Record any API design decisions that create technical debt

## ⚠️ MANDATORY Task Completion Checklist

**TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF**

Before considering this task finished:

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] API Specification Document created and saved to specifications directory
  - [ ] Request Data Model created with comprehensive validation rules and examples
  - [ ] Response Data Model created with complete structure and field definitions
- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] **✅ AUTOMATED** - [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) Status updated to next gate; API Specification and API Data Model rows inserted into per-feature state file's §4 Documentation Inventory (PF-PRO-002 / PF-IMP-760)
  - [ ] **🔧 MANUAL** - [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md) updated with any design decisions creating technical debt
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Guide](../../guides/framework/feedback-form-guide.md) for each tool used, using task ID "PF-TSK-020" and context "API Design Task"

## Next Tasks

- [**TDD Creation**](tdd-creation-task.md) - Create detailed technical design based on API specifications
- [**Test Specification Creation**](../03-testing/test-specification-creation-task.md) - Define test cases for API endpoints and contracts
- [**Feature Implementation Planning**](../04-implementation/feature-implementation-planning-task.md) - Plan and implement the API according to the design specifications


## Related Resources

- [API Specification Creation Guide](../../guides/02-design/api-specification-creation-guide.md) - How to use the ../../scripts/file-creation/02-design/New-APISpecification.ps1 script effectively
- [API Data Model Creation Guide](../../guides/02-design/api-data-model-creation-guide.md) - How to use the ../../scripts/file-creation/02-design/New-APIDataModel.ps1 script effectively
- [API Design Task Context Map](../../visualization/context-maps/02-design/api-design-task-map.md) - Visual guide to task components and relationships
- [System Architecture Review Task](../01-planning/system-architecture-review.md) - Prerequisite task for understanding architectural constraints
- [Visual Notation Guide](../../guides/support/visual-notation-guide.md) - Standard notation for API diagrams and documentation
