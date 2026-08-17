---
id: PF-TSK-020
type: Process Framework
category: Task Definition
version: 1.6
created: 2025-07-19
updated: 2026-08-04
change_notes: "v1.5 - Check Recommended Skills wiring: api-design craft skill replaces the retired API Specification + API Data Model creation guides (Craft-as-Skill BL-5 batch 1)"
description: "Design comprehensive API contracts and specifications before implementation begins"
complexity: medium
use_when: >-
  Design comprehensive API contracts and specifications before implementation begins
automation: full
scripts:
  - ../../scripts/file-creation/02-design/New-APISpecification.ps1
  - ../../scripts/file-creation/02-design/New-APIDataModel.ps1
trigger_status:
  - file: feature-tracking.md
    status: "🔌 Needs API Design"
output_status:
  - raw: "`feature-tracking.md` Status → next design-chain gate (`🎨 Needs UI Design` / `📜 Needs Instruction Design` if still flagged) else `📝 Needs TDD` (Tier 2+) / `🔧 Needs Impl Plan` (Tier 1, since Tier 1 skips TDD); API Specification + Data Model rows inserted into per-feature state file's §4 Documentation Inventory (PF-PRO-002)"
next_tasks:
  - task: ui-design-task.md
    condition: "Feature Status is `🎨 Needs UI Design` — the design-chain gate ordered after API"
  - task: instruction-design-task.md
    condition: "Feature Status is `📜 Needs Instruction Design` — the feature has an instruction dimension"
  - task: tdd-creation-task.md
    condition: "Create detailed technical design based on API specifications"
  - task: ../03-testing/test-specification-creation-task.md
    condition: "Define test cases for API endpoints and contracts"
  - task: ../04-implementation/feature-implementation-planning-task.md
    condition: "Plan and implement the API according to the design specifications"
---

# API Design Task

> **▶ Execute this task under the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md).** This file holds only this task's specific content; the universal contract every task shares lives once in the protocol and is mandatory here.

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

> **📋 Ownership & cross-reference rules**: [Information Flow Guide → API Design Task (PF-TSK-020)](../../guides/framework/information-flow-guide.md#api-design-task-pf-tsk-020) — what this task owns, what it references instead, and the cross-reference format.

This task focuses exclusively on **API-level concerns**: endpoint specifications, request/response contracts, authentication patterns, and service integration protocols.

### Inputs from Other Tasks

- **FDD Creation Task** (PF-TSK-027): Functional requirements, user flows, data requirements (high-level)
- **Tier assessment** (via Feature Request Evaluation, PF-TSK-067): Complexity tier, documentation requirements
- **System Architecture Review** (PF-TSK-019): Architectural decisions, patterns, integration constraints
- **Database Schema Design** (PF-TSK-021): Data model, relationships, constraints (when schema is designed first)

### Outputs to Other Tasks

- **Database Schema Design Task** (PF-TSK-021): Data access patterns, API-level data requirements
- **TDD Creation Task** (PF-TSK-015): API contracts, endpoint specifications, integration patterns
- **Test Specification Task** (PF-TSK-012): API contracts, error scenarios, authentication requirements
- **Decomposed implementation tasks**: API specifications, data models, integration requirements

## Context Requirements

- **Critical (Must Read):**

  - **Functional Design Document (FDD)** - For Tier 2+ features, the FDD containing functional requirements and user flows that inform API design
  - [Feature Requirements](../../../doc/state-tracking/permanent/feature-tracking.md) - Understanding what functionality the API must support and confirming API Design is required
  - **Tier assessment** - The tier assessment for this feature (locate via [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md))
  - **System Architecture Review Results** - Architecture decisions that impact API design (if a review was conducted)

- **Important (Load If Space):**

  - [`api-design` craft skill](../../../.claude/skills/api-design/SKILL.md) — the customization craft for both artifact kinds (API-type/template selection, auth strategy, error granularity, data-model structure/validation/versioning decisions), activated in Preparation Step 1 (Check Recommended Skills). Replaces the former API Specification and API Data Model creation guides and **drives the contract and model customization in Execution.**
  - **Existing API Documentation** - Current API patterns and conventions for the project (if available)
  - [Technical Design Documents](../../../doc/technical/tdd) - Related technical designs

- **Reference Only (Access When Needed):**
  - [API Design Best Practices](https://restfulapi.net/) - Industry standards for REST API design
  - [OpenAPI Specification](https://swagger.io/specification/) - Standard for API documentation

## Process

> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

### Preparation

1. **Check Recommended Skills**: Read the active language-config (`languages-config/{language}/{language}-config.json`) and `project-config.json` for `recommended_skills` entries keyed to `api-design-task`. If the `api-design` craft skill is available in the session, activate it — it owns the **customization craft** this task delegates to (how to fill API specifications and data models well). If it is not listed in the session, read [`SKILL.md`](../../../.claude/skills/api-design/SKILL.md) directly and apply it — that file is the canonical source the Skill tool loads, so a direct read is equivalent, not degraded. The customization craft is unavailable for this run only if the skill file itself is absent (the retired procedural creation guides have no successors).
2. **Verify API Design Requirement**: Confirm the feature's Status in [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) is `🔌 Needs API Design` (set by Tier Assessment when API design is required for this feature)
3. Review the [Feature Tier Assessment](../../../doc/documentation-tiers/assessments) of this feature that determined API design is needed
4. Review feature requirements and understand the functionality that needs API support
5. Examine existing API patterns and conventions in the project
6. Identify data models and schemas that will be needed for the API
7. **🚨 CHECKPOINT**: Present preparation findings, identified API patterns, and data model requirements to human partner for approval

### Execution

8. **🤖 AUTOMATED - Create API Specification Document**: Use the automation script to generate the main API contract and update feature tracking (the `api-design` craft skill carries the load-bearing `-APIType` template-selection decision):

   ```powershell
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/02-design/New-APISpecification.ps1 -APIName "[Feature Name] API" -APIDescription "[Brief description]" -APIType "REST" -FeatureId "[FeatureId]"
   ```

   **✅ AUTOMATION FEATURES:**

   - Creates API specification document with proper ID and structure
   - **Automatically inserts an API Specification row** into the per-feature state file's §4 Documentation Inventory (PF-PRO-002 / PF-IMP-760). Additional API specs become additional rows.
   - **Automatically updates feature-tracking.md** Status to the next gate (`🎨 Needs UI Design` / `📜 Needs Instruction Design` / `📝 Needs TDD` / `🔧 Needs Impl Plan`)
   - Adds timestamped automation notes to feature-tracking.md Notes column
   - Provides comprehensive feedback and next steps

9. **Define API Contract**: Specify endpoints, HTTP methods, URL patterns, authentication, and error handling following RESTful conventions

    - **Reference the Response Status Catalog** in your Status Codes section
    - Use the canonical status codes defined in the catalog for consistency

10. **🔄 SEMI-AUTOMATED - Create Request Data Model**: Generate detailed request schema with validation rules (only if not reusing existing model):

    ```powershell
    pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/02-design/New-APIDataModel.ps1 -ModelName "[API Name] Request" -ModelDescription "[Brief description]" -FeatureId "[FeatureId]"
    ```

    **✅ AUTOMATED**: API Data Model row inserted into the per-feature state file's §4 Documentation Inventory (PF-PRO-002 / PF-IMP-760)

11. **🔄 SEMI-AUTOMATED - Create Response Data Model**: Generate detailed response schema with field definitions (only if not reusing existing model):

    ```powershell
    pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/02-design/New-APIDataModel.ps1 -ModelName "[API Name] Response" -ModelDescription "[Brief description]" -FeatureId "[FeatureId]"
    ```

    **✅ AUTOMATED**: API Data Model row inserted into the per-feature state file's §4 Documentation Inventory (PF-PRO-002 / PF-IMP-760)

12. **🤖 AUTOMATED - Create API Documentation** (optional): If developer-facing documentation is needed, generate it from template:

    ```powershell
    pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/02-design/New-APIDocumentation.ps1 -APIName "[API Name]" -APIVersion "[version]" -TargetAudience "[audience]"
    ```

    This creates a user-facing documentation page in `doc/technical/api/documentation/` complementing the technical specification.

13. **Review Design Consistency**: Validate API design against existing patterns and architectural decisions
14. **🚨 CHECKPOINT**: Present complete API design including specification, data models, and contract details to human partner for review and approval

### Finalization

15. **Validate Complete Design**: Ensure API specification and data models work together cohesively
16. **✅ AUTOMATED - State File Updates**: API specification and data model rows automatically inserted into the per-feature state file's §4 Documentation Inventory by `New-APISpecification.ps1` and `New-APIDataModel.ps1` (via the shared `Invoke-DesignArtifactCreation` core, PF-PRO-002 / PF-IMP-760). Feature-tracking.md Status auto-advances to next gate.
17. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

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
  - Status: set to the next design-chain gate still flagged (`🎨 Needs UI Design`, then `📜 Needs Instruction Design`); with none left, `📝 Needs TDD` (Tier 2+) or `🔧 Needs Impl Plan` (Tier 1 — Tier 1 skips TDD)
- **✅ AUTOMATED** - Per-feature state file (`doc/state-tracking/features/<id>-implementation-state.md`):
  - API Specification and API Data Model rows inserted into §4 Documentation Inventory by `New-APISpecification.ps1` / `New-APIDataModel.ps1` (PF-PRO-002 / PF-IMP-760)
- **🔧 MANUAL** - [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md) - Record any API design decisions that create technical debt

## ⚠️ MANDATORY Task Completion Checklist

> Completion discipline, output verification, and the feedback form are governed by the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md) (Phase C). The items below are the **task-specific** verifications that plug into it.

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] API Specification Document created and saved to specifications directory
  - [ ] Request Data Model created with comprehensive validation rules and examples
  - [ ] Response Data Model created with complete structure and field definitions
- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] **✅ AUTOMATED** - [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) Status updated to next gate; API Specification and API Data Model rows inserted into per-feature state file's §4 Documentation Inventory (PF-PRO-002 / PF-IMP-760)
  - [ ] **🔧 MANUAL** - [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md) updated with any design decisions creating technical debt
- [ ] **Feedback form** completed per the [Task Execution Protocol → Feedback step](../../guides/framework/task-execution-protocol-guide.md#feedback-step) — task ID `PF-TSK-020`, context "API Design Task".

## File Operations

| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | `[api-name].md` | `New-APISpecification.ps1` | API specification document with comprehensive contract definition |
| **Creates** | `[api-name]-request.md` | `New-APIDataModel.ps1` | Request data model with validation rules and examples |
| **Creates** | `[api-name]-response.md` | `New-APIDataModel.ps1` | Response data model with complete structure and field definitions |
| **Updates** | [`feature-tracking.md`](../../../doc/state-tracking/permanent/feature-tracking.md) | `New-APISpecification.ps1` | **AUTOMATED**: Status advanced to next gate (`🎨 Needs UI Design` / `📜 Needs Instruction Design` / `📝 Needs TDD` / `🔧 Needs Impl Plan`); timestamped automation notes appended to Notes column |
| **Updates** | Per-feature state file (`doc/state-tracking/features/<id>-implementation-state.md`) | `New-APISpecification.ps1` (via `Add-StateFileDocumentationInventoryRow`) | **AUTOMATED**: Insert API Specification row into §4 Documentation Inventory (PF-PRO-002 / PF-IMP-760). Additional API specs become additional rows. |
| **Updates** | Per-feature state file (`doc/state-tracking/features/<id>-implementation-state.md`) | `New-APIDataModel.ps1` (via `Add-StateFileDocumentationInventoryRow`) | **AUTOMATED**: Insert API Data Model row into §4 Documentation Inventory (PF-PRO-002 / PF-IMP-760) |
| **Updates** | [`technical-debt-tracking.md`](../../../doc/state-tracking/permanent/technical-debt-tracking.md) | Manual | Record API design decisions that create technical debt |

## Next Tasks

- [**TDD Creation**](tdd-creation-task.md) - Create detailed technical design based on API specifications
- [**Test Specification Creation**](../03-testing/test-specification-creation-task.md) - Define test cases for API endpoints and contracts
- [**Feature Implementation Planning**](../04-implementation/feature-implementation-planning-task.md) - Plan and implement the API according to the design specifications

<!-- merged from transition-registry entry: API Design -->
### Prerequisites for Transition

- [ ] API specification documents created
- [ ] Data models defined for all request/response objects
- [ ] API documentation created for consumers
- [ ] API design linked in Feature Tracking

### Next Task Selection

```
What is the next design-chain gate? (recomputed feature Status; order DB → API → 🎨 UI → 📜 Instruction → TDD)
├─ 🎨 Needs UI Design → UI Design
│   └─ Reason: UI Design is the design-chain gate after API
├─ 📜 Needs Instruction Design → Instruction Design
│   └─ Reason: no UI gate, but the feature has an instruction dimension
└─ 📝 Needs TDD / 🔧 Needs Impl Plan → TDD Creation (Impl Plan for Tier 1)
    └─ Reason: no gates left — proceed to technical design with the API contracts
```

### Preparation for Next Task

1. Review API specifications to understand interface requirements
2. Ensure data models align with feature requirements
3. Verify API design follows project patterns and standards
4. Prepare API context for design decisions

## Related Resources

- [`api-design` craft skill](../../../.claude/skills/api-design/SKILL.md) - the API design customization craft for both artifact kinds (replaces the retired API Specification and API Data Model creation guides); activated by the Check Recommended Skills step
- [System Architecture Review Task](../01-planning/system-architecture-review.md) - Prerequisite task for understanding architectural constraints
- [Visual Notation Guide](../../guides/support/visual-notation-guide.md) - Standard notation for API diagrams and documentation
