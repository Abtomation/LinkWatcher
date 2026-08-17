---
id: PF-TEM-083
type: Process Framework
category: Template
version: 1.0
created: 2026-06-30
updated: 2026-06-30
creates_document_category: Functional Design Document
creates_document_prefix: PD-FDD
creates_document_type: Product Documentation
creates_document_version: 1.0
description: Retrospective sibling of fdd-template.md for documenting an already-implemented feature as-built — forward-planning scaffolding stripped/reframed; selected by New-FDD.ps1 -Retrospective.
template_for: Functional Design Document
usage_context: Product Documentation - Functional Design Document Creation
documentation_mode: as-built
---

# [Feature Name] - Functional Design Document (Retrospective)

> **Retrospective**: This FDD documents an **already-implemented** feature as-built. Describe what the system *does*, not what it should do. For a Target-State feature (Code Maturity < 2.0), switch to prescriptive framing and add a Gap Analysis section per the [Retrospective Documentation Creation task](../../tasks/00-setup/retrospective-documentation-creation.md).

## Feature Overview

- **Business Value**: [Why this feature matters to users and business, as observed in the shipped implementation]
- **User Story**: As a [user type], I want [goal] so that [benefit]

## Cross-References

> Flat list of related documents that exist for this feature. Add only rows that point at a real document; omit the rest.

- **TDD**: [PD-TDD-XXX](path) — Technical design
- **Test Spec**: [TE-TSP-XXX](path) — Test specification
- **API Spec**: [PD-API-XXX](path) — API contract (if any)
- **Schema Design**: [PD-SCH-XXX](path) — Database schema (if any)

## Functional Requirements

> Document the requirements the implementation **satisfies**, derived from its observed behavior.

### Core Functionality

- **[Feature-ID]-FR-1**: [What the system does]
- **[Feature-ID]-FR-2**: [What the system does]
- **[Feature-ID]-FR-3**: [Additional functional requirements as observed]

### User Interactions

- **[Feature-ID]-UI-1**: [How users interact with the feature, as implemented]
- **[Feature-ID]-UI-2**: [Specific UI behaviors and responses]
- **[Feature-ID]-UI-3**: [Additional user interaction behaviors]

### Business Rules

- **[Feature-ID]-BR-1**: [Validation logic, constraints, or business logic enforced by the code]
- **[Feature-ID]-BR-2**: [Data validation, workflow rules as implemented]
- **[Feature-ID]-BR-3**: [Additional business rules]

## User Experience Flow

[Describe the actual user journey as implemented, step-by-step:]

1. **Entry Point**: How users reach this feature
2. **Main Flow**: Actual user actions and system responses
3. **Decision Points**: Where users make choices and the options the code provides
4. **Alternative Paths**: Other ways users complete the task in the current implementation
5. **Exit Points**: How the journey concludes

## Workflow Participation

[List the user workflows this feature participates in, referencing [User Workflow Tracking](../../../doc/state-tracking/permanent/user-workflow-tracking.md). For each workflow, briefly describe this feature's role as implemented.]

| Workflow | Role in Workflow |
|----------|-----------------|
| [WF-XXX] | [How this feature contributes to the workflow] |

> **If no workflows exist yet**, note "No existing workflows — consider whether this feature represents a user workflow worth tracking."

## Acceptance Criteria

> Criteria the current implementation **meets** — verified against observed behavior. Check the boxes that the as-built implementation satisfies.

- [ ] **[Feature-ID]-AC-1**: [Verifiable behavior the implementation exhibits]
- [ ] **[Feature-ID]-AC-2**: [Verifiable behavior the implementation exhibits]
- [ ] **[Feature-ID]-AC-3**: [Additional acceptance criteria]

## Edge Cases & Error Handling

> Edge cases and error paths as **handled by the implementation**.

- **[Feature-ID]-EC-1**: [Edge case and how the code behaves]
- **[Feature-ID]-EC-2**: [Error scenario and the system's actual response]
- **[Feature-ID]-EC-3**: [Additional edge cases and error conditions]

## Dependencies

### Functional Dependencies

- [Other features this feature depends on functionally]
- [User permissions or roles required]
- [Data that must exist for this feature to work]

### Technical Dependencies

- [Technical systems, APIs, or services the implementation relies on]
- [Database schema requirements]
- [Third-party integrations in use]

## Success Metrics

- [How feature success is measured from the user perspective]
- [Key performance indicators for feature adoption]
- [User satisfaction or engagement metrics]

## Notes

[Any assumptions, known limitations, or considerations discovered while documenting the existing implementation. For Target-State features, record gaps between current and intended behavior here or in a dedicated Gap Analysis section.]

## Documentation Verification Checklist

- [ ] Functional requirements reflect the behavior actually implemented in code
- [ ] User interactions match the shipped UI behavior
- [ ] Business rules correspond to validation/logic present in the implementation
- [ ] Acceptance criteria are verifiable against the running system
- [ ] Edge cases describe how the code actually behaves, not aspirational handling
- [ ] Dependencies reflect the real dependency graph
- [ ] Cross-references point only at documents that exist

---

_This Functional Design Document was created retrospectively to document the existing implementation of [Feature Name]._
