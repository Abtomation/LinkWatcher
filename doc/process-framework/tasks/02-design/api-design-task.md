---
id: PF-TSK-020
type: Process Framework
category: Task Definition
version: 1.2
created: 2025-07-19
updated: 2025-01-27
task_type: Discrete
change_notes: "v1.2 - Added Information Flow section for IMP-097/IMP-098"
---

# API Design Task

## Purpose & Context

Design comprehensive API contracts and specifications before implementation begins, ensuring consistent interfaces and proper integration patterns

**🔒 API Scope**: All BreakoutBuddies APIs are **internal-only** and designed exclusively for use within the BreakoutBuddies application ecosystem. These APIs are not public-facing and are not intended for third-party integrations or external consumers.

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

## When to Use

- When the [Feature Tier Assessment](../01-planning/feature-tier-assessment-task.md) indicates "Yes" in the API Design column
- Before implementing any feature that requires new API endpoints or modifies existing ones
- When creating microservices or service interfaces that will be consumed by other components
- After completing System Architecture Review but before TDD Creation
- When integrating with external APIs or third-party services
- Prerequisites: Feature requirements defined, system architecture decisions made, Feature Tier Assessment completed

## Information Flow

> **📋 Detailed Guidance**: See [Task Transition Guide - Information Flow Section](../../guides/guides/task-transition-guide.md#information-flow-and-separation-of-concerns)

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
  - [Feature Requirements](/doc/process-framework/state-tracking/permanent/feature-tracking.md) - Understanding what functionality the API must support and confirming API Design is required
  - [Feature Tier Assessment](../../../methodologies/documentation-tiers/assessments) - Assessment that determined API design is needed
  - [System Architecture Review Results](/doc/product-docs/technical/architecture/assessments/) - Architecture decisions that impact API design

- **Important (Load If Space):**

  - [Existing API Documentation](/doc/product-docs/technical/api/documentation/) - Current API patterns and conventions
  - [Response Status Catalog](/doc/product-docs/technical/api/specifications/shared/response-status-catalog.json) - Canonical HTTP status codes for all internal APIs
  - [API Specifications Directory README](/doc/product-docs/technical/api/specifications/README.md) - Guide to shared resources and API specification workflow
  - [API Data Models Registry](../../state-tracking/permanent/api-models-registry.md) - Registry of all API data models for reusability
  - [Data Models](/doc/product-docs/technical/api/models/) - Existing data model definition files
  - [Technical Design Documents](/doc/product-docs/technical/architecture/design-docs/tdd/) - Related technical designs

- **Reference Only (Access When Needed):**
  - [API Design Best Practices](https://restfulapi.net/) - Industry standards for REST API design
  - [OpenAPI Specification](https://swagger.io/specification/) - Standard for API documentation
  - [Visual Notation Guide](/doc/process-framework/guides/guides/visual-notation-guide.md) - For interpreting context map diagrams

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished! 🚨**
>
> **⚠️ MANDATORY: Use the appropriate automation tools where indicated.**

### Preparation

1. **Verify API Design Requirement**: Confirm in the [Feature Tracking](../../../state-tracking/permanent/feature-tracking.md) document that the API Design column shows "Yes" for this feature
2. Review the [Feature Tier Assessment](../../../methodologies/documentation-tiers/assessments) of this feature that determined API design is needed
3. Review feature requirements and understand the functionality that needs API support
4. Examine existing API patterns and conventions in the project
5. **Check Response Status Catalog**: Review [Response Status Catalog](/doc/product-docs/technical/api/specifications/shared/response-status-catalog.json) to identify existing status codes for similar scenarios and ensure consistency
6. **Check Data Models Registry**: Review [API Data Models Registry](../../state-tracking/permanent/api-models-registry.md) to identify existing data models that can be reused and avoid creating duplicates
7. Identify additional data models and schemas that will be needed for the API

### Execution

8. **Update Response Status Catalog**: Before creating the API specification, add your API's status codes to the [Response Status Catalog](/doc/product-docs/technical/api/specifications/shared/response-status-catalog.json):

   - Add a new entry under `apis` for your API
   - Define all endpoints with their HTTP methods
   - Document all scenarios (success, error cases) with status codes and descriptions
   - Follow existing naming patterns (e.g., `success`, `invalid_request`, `not_found`)
   - Update the catalog's `version` and `last_updated` metadata

9. **🤖 AUTOMATED - Create API Specification Document**: Use the automation script to generate the main API contract and update feature tracking:

   ```powershell
   cd doc/product-docs/technical/api/specifications
   ../../../scripts/file-creation/New-APISpecification.ps1 -APIName "[Feature Name] API" -APIDescription "[Brief description]" -APIType "REST" -FeatureId "[FeatureId]"
   ```

   **✅ AUTOMATION FEATURES:**

   - Creates API specification document with proper ID and structure
   - **Automatically updates feature tracking** with intelligent replacement/append logic:
     - **First API specification**: Replaces "Yes" with clickable link to API specification
     - **Additional API specifications**: Appends with " • " separator to existing links
   - Generates correct relative paths for clickable links in feature tracking
   - Adds timestamped automation notes to feature tracking
   - Provides comprehensive feedback and next steps

10. **Define API Contract**: Specify endpoints, HTTP methods, URL patterns, authentication, and error handling following RESTful conventions

    - **Reference the Response Status Catalog** in your Status Codes section
    - Use the canonical status codes defined in the catalog for consistency

11. **🔄 SEMI-AUTOMATED - Create Request Data Model**: Generate detailed request schema with validation rules (only if not reusing existing model):

    ```powershell
    cd doc/product-docs/technical/api/models
    ../../scripts/file-creation/New-APIDataModel.ps1 -ModelName "[API Name] Request" -ModelDescription "[Brief description]" -FeatureId "[FeatureId]"
    ```

    **✅ AUTOMATED**: Feature tracking API Design column automatically updated with intelligent replacement/append logic

12. **🔄 SEMI-AUTOMATED - Create Response Data Model**: Generate detailed response schema with field definitions (only if not reusing existing model):

    ```powershell
    cd doc/product-docs/technical/api/models
    ../../scripts/file-creation/New-APIDataModel.ps1 -ModelName "[API Name] Response" -ModelDescription "[Brief description]" -FeatureId "[FeatureId]"
    ```

    **✅ AUTOMATED**: Feature tracking API Design column automatically updated with intelligent replacement/append logic

13. **Review Design Consistency**: Validate API design against existing patterns and architectural decisions

### Finalization

14. **Validate Complete Design**: Ensure API specification and data models work together cohesively
15. **Verify Response Status Catalog Integration**: Confirm that your API specification correctly references the Response Status Catalog and uses canonical status codes
16. **🔧 MANUAL - Update Data Models Registry**: Add entries for all newly created models in [API Data Models Registry](/doc/product-docs/technical/api/models/README.md) and update "Used By Features" for any reused models
17. **✅ AUTOMATED - Feature Tracking Updates**: API specification and data model links automatically managed:
    - **../../scripts/file-creation/New-APISpecification.ps1**: Replaces "Yes" with first API spec, appends additional specs with " • " separator
    - **../../scripts/file-creation/New-APIDataModel.ps1**: Appends data model links with " • " separator using intelligent replacement/append logic
18. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Outputs

- **API Specification Document** - Comprehensive API contract definition saved to `/doc/product-docs/technical/api/specifications/specifications/[api-name].md`
- **Request Data Model** - Schema definition for request objects saved to `/doc/product-docs/technical/api/models/[api-name]-request.md`
- **Response Data Model** - Schema definition for response objects saved to `/doc/product-docs/technical/api/models/[api-name]-response.md`
- **Data Models Registry Update** - Registry entry in [API Data Models Registry](/doc/product-docs/technical/api/models/README.md) tracking all created models

## State Tracking

The following state files must be updated as part of this task:

- **✅ AUTOMATED** - [Feature Tracking](../../../state-tracking/permanent/feature-tracking.md) - API Design column updates:
  - **../../scripts/file-creation/New-APISpecification.ps1**: Replaces "Yes" with first API spec, appends additional specs with " • " separator
  - **../../scripts/file-creation/New-APIDataModel.ps1**: Appends data model links with " • " separator using intelligent replacement/append logic
- **🔧 MANUAL** - [Technical Debt Tracking](../../../state-tracking/permanent/technical-debt-tracking.md) - Record any API design decisions that create technical debt
- **🔧 MANUAL** - [API Data Models Registry](/doc/product-docs/technical/api/models/README.md) - Update with entries for all created data models

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

Before considering this task finished:

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] API Specification Document created and saved to specifications directory
  - [ ] Request Data Model created with comprehensive validation rules and examples
  - [ ] Response Data Model created with complete structure and field definitions
  - [ ] Data Models Registry updated with entries for all created models
- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] **✅ AUTOMATED** - [Feature Tracking](../../../state-tracking/permanent/feature-tracking.md) API Design column updates:
    - [x] **✅ AUTOMATED**: API specification and data model links automatically managed (intelligent replacement/append logic)
  - [ ] **🔧 MANUAL** - [Technical Debt Tracking](../../../state-tracking/permanent/technical-debt-tracking.md) updated with any design decisions creating technical debt
  - [ ] **🔧 MANUAL** - [API Data Models Registry](/doc/product-docs/technical/api/models/README.md) updated with new model entries and relationships
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Completion Instructions](../../../guides/guides/feedback-form-completion-instructions.md) for each tool used, using task ID "PF-TSK-020" and context "API Design Task"

## Next Tasks

- [**TDD Creation**](tdd-creation-task.md) - Create detailed technical design based on API specifications
- [**Test Specification Creation**](../test-specification-creation.md) - Define test cases for API endpoints and contracts
- [**Feature Implementation**](../feature-implementation-task.md) - Implement the API according to the design specifications
- [**API Documentation Creation**](../api-documentation-creation-task.md) - Create consumer-facing documentation after implementation (coming soon)

## Related Resources

- [API Specification Creation Guide](../../../guides/guides/api-specification-creation-guide.md) - How to use the ../../scripts/file-creation/New-APISpecification.ps1 script effectively
- [API Data Model Creation Guide](../../../guides/guides/api-data-model-creation-guide.md) - How to use the ../../scripts/file-creation/New-APIDataModel.ps1 script effectively
- [API Design Task Context Map](../../visualization/context-maps/02-design/api-design-task-map.md) - Visual guide to task components and relationships
- [System Architecture Review Task](../01-planning/system-architecture-review.md) - Prerequisite task for understanding architectural constraints
- [Visual Notation Guide](../../../guides/guides/visual-notation-guide.md) - Standard notation for API diagrams and documentation
