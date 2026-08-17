---
id: PF-TSK-044
type: Process Framework
category: Task Definition
version: 1.7
created: 2025-10-30
updated: 2026-08-04
change_notes: "v1.6 - Step 17 passes -Tier so Tier 1 features actually get the lightweight plan template; plan-doc section list realigned to the de-duplicated template (File and Component Mapping -> Architecture Context; per-phase file mapping stays state-file-owned) at Step 18, Outputs, and checklist (PF-IMP-1561)"
description: "Analyze design documentation and create detailed implementation plan with task sequencing and dependency mapping"
complexity: medium
use_when: >-
  Analyze design documentation and create detailed implementation plan with task sequencing
automation: semi
scripts:
  - ../../scripts/file-creation/04-implementation/New-ImplementationPlan.ps1
trigger_status:
  - file: feature-tracking.md
    status: "🔧 Needs Impl Plan"
output_status:
  - raw: "`feature-tracking.md` → `🟡 In Progress`; Feature impl state file → task sequence initialized (`not_started`)"
---

# Feature Implementation Planning Task

> **▶ Execute this task under the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md).** This file holds only this task's specific content; the universal contract every task shares lives once in the protocol and is mandatory here.

## Purpose & Context

Transform completed design documentation (FDD, TDD, Database Schema Design, API Design, UI/UX Design, Instruction Design) into an actionable implementation execution strategy. This task creates a decomposed task sequence with clear dependencies, effort estimates, integration points, and risk mitigation strategies. It also initializes the permanent feature implementation state tracking document that will be maintained throughout the feature's entire lifecycle.

**Critical Distinction**: This task does NOT create design documentation (FDD, TDD, etc.). It assumes all design work is complete and focuses on EXECUTION PLANNING - how to systematically implement what has already been designed.

## AI Agent Role

**Role**: Implementation Architect
**Mindset**: Strategic execution planner focused on task sequencing, dependency management, and risk mitigation
**Focus Areas**: Task decomposition, dependency mapping, effort estimation, integration planning, risk identification
**Communication Style**: Present task sequencing options with trade-offs, proactively highlight blocking dependencies and integration risks, ask about resource constraints and timeline expectations

## Information Flow

> **📋 Ownership & cross-reference rules**: [Information Flow Guide → Feature Implementation Planning Task (PF-TSK-044)](../../guides/framework/information-flow-guide.md#feature-implementation-planning-task-pf-tsk-044) — what this task owns, what it references instead, and the cross-reference format.

### Inputs from Other Tasks

- **FDD Creation Task** (Tier 2+): Functional requirements, user workflows, acceptance criteria
- **TDD Creation Task**: Technical architecture, component design, implementation approach
- **API Design Task**: API contracts, endpoints, service integration patterns
- **Database Schema Design Task**: Data model, migration scripts, RLS policies
- **Instruction Design Task**: Executable procedure, artifact inventory with declared kinds, instruction contract, verification plan
- **UI/UX Design Task**: Visual specifications, component structure, platform adaptations
- **Feature Tracking**: Feature ID, complexity tier, dependencies

### Outputs to Other Tasks

- **Feature Implementation Task** (decomposed): Sequenced implementation tasks with clear scope and dependencies
- **Feature State Tracking** (permanent): Living document tracking implementation progress and context
- **Test Specification Task**: Testing strategy and quality validation approach
- **Code Review Task**: Quality criteria and architectural compliance points


## Context Requirements

- **Critical (Must Read):**

  - **Feature Tracking** - [Feature details from feature-tracking.md](../../../doc/state-tracking/permanent/feature-tracking.md) including feature ID, name, complexity tier, and design document links
  - **TDD (Technical Design Document)** - The approved technical design at `/doc/technical/tdd` containing component architecture and implementation approach
  - **FDD (Functional Design Document)** - For Tier 2+ features, the functional requirements at `/doc/functional-design/fdds`
  - **Development Dimensions Guide** - [Dimension definitions, applicability criteria, and phase-specific guidance](../../guides/framework/development-dimensions-guide.md) - **MUST READ** for evaluating dimension applicability during planning
  - **Feature Implementation State Template** - [Template for permanent state tracking](../../templates/04-implementation/feature-implementation-state-template.md) - **MUST READ** to understand living document structure
  - [`feature-implementation-planning` craft skill](../../../.claude/skills/feature-implementation-planning/SKILL.md) — the state-file initialization and maintenance craft (section-ownership boundary, variant awareness, section-by-section judgment, living-document maintenance), activated in Step 1 (Check Recommended Skills). Replaces the retired Feature Implementation State Tracking Guide.

- **Important (Load If Space):**

  - **API Design Documentation** - If applicable, API contracts and endpoints at `/doc/technical/api`
  - **Database Schema Design** - If applicable, data model and migrations at `/doc/technical/database`
  - **Instruction Design Documentation** - If applicable, the executable procedure and artifact inventory at `/doc/technical/design/instruction`
  <!-- UI/UX Design Documentation - If applicable, visual specifications at /doc/technical/ui-design (directory does not exist in this project) -->
  <!-- Component Relationship Index - Removed: file deleted -->
  - **Codebase Structure** - Relevant source directories where feature components will be implemented
  - **Information Flow Guide** - [For understanding information flow between tasks](../../guides/framework/information-flow-guide.md)

- **Reference Only (Access When Needed):**
  - **Architecture Decision Records** - [ADRs](../../../doc/technical/adr) relevant to this feature
  <!-- Test Strategy Documentation - directory /doc/technical/testing does not exist in this project -->

## Process

> **⚠️ MANDATORY: Use the New-ImplementationPlan.ps1 script for creating implementation plan documents.**
>
> **⚠️ MANDATORY: The Feature Implementation State file must already exist (created by [Feature Request Evaluation (PF-TSK-067)](../01-planning/feature-request-evaluation.md)). Initialize it with planning-phase content.**
>
> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

### Preparation

1. **Check Recommended Skills**: Read the active language-config (`languages-config/{language}/{language}-config.json`) and `project-config.json` for `recommended_skills` entries keyed to `feature-implementation-planning-task`. If the `feature-implementation-planning` craft skill is available in the session, activate it — it owns the **state-file initialization and maintenance craft** this task delegates to (the two-planning-task section-ownership boundary, template-variant awareness, section-by-section initialization judgment, and the living-document maintenance / bidirectional-marker / onboarding-section references). If it is not listed in the session, read [`SKILL.md`](../../../.claude/skills/feature-implementation-planning/SKILL.md) directly and apply it — that file is the canonical source the Skill tool loads, so a direct read is equivalent, not degraded. The craft is unavailable for this run only if the skill file itself is absent (the retired procedural guide has no successor).
2. **Gather All Design Documentation**: Collect and review all completed design documents:
   - Technical Design Document (TDD) - primary source for technical approach
   - Functional Design Document (FDD) - for Tier 2+ features, functional requirements and acceptance criteria
   - API Design documents - if applicable, service contracts and endpoints
   - Database Schema Design - if applicable, data model and migration strategy
   - Instruction Design - if applicable, the procedure and its artifact inventory (a `mixed` feature decomposes into both code and instruction work)
   - UI/UX Design documents - if applicable, visual specifications and component structure
3. **Review Feature Context**: Load feature details from [feature-tracking.md](../../../doc/state-tracking/permanent/feature-tracking.md):
   - Feature ID and name
   - Complexity tier (Tier 1, 2, or 3)
   - Dependencies on other features
   - Current status and design document links
4. **Study Feature Implementation State File**: **CRITICAL** - Read the existing Feature Implementation State file for this feature (at `/doc/state-tracking/features/`) and apply the [`feature-implementation-planning` craft skill](../../../.claude/skills/feature-implementation-planning/SKILL.md) (activated at Step 1) to understand its living-document structure, which sections planning initializes, and how the file is maintained through implementation.
5. **Assess Codebase Context**: Review existing code structure:
   - Identify directories where feature components will live
   - Review similar features for reusable patterns
   - Identify existing components that will be integrated with or modified
   - Note any architectural constraints from ADRs
6. **Evaluate Dimension Applicability**: Using the [Development Dimensions Guide](../../guides/framework/development-dimensions-guide.md), evaluate which quality dimensions apply to this feature:
   - **Core dimensions** (AC, CQ, ID, DA) are always **Relevant** or **Critical** — no evaluation needed
   - **Extended dimensions** (EM, SE, PE, OB, UX, DI) — apply the guide's "Applicability" criteria to determine Critical / Relevant / N/A for each
   - For each **Critical** dimension, note specific considerations that will inform implementation tasks (e.g., "SE Critical — feature handles user-provided file paths, must validate against path traversal")
   - Map Critical dimensions to specific implementation tasks as acceptance criteria
7. **🚨 CHECKPOINT**: Present design document review summary, codebase context assessment, dimension applicability evaluation, and identified constraints to human partner for approval

### Execution - Part 1: Implementation Roadmap Creation

8. **Break Down Feature into Implementation Phases**: Organize the work into logical implementation phases:

   - **Data Layer**: Models, repositories, database migrations
   - **Service Layer**: Business logic, validation, external service integration
   - **State Management**: State containers, managers, state classes
   - **UI Layer**: Screens, components, forms, navigation
   - **Testing**: Unit tests, component tests, integration tests
   - **Integration**: API integration, authentication, navigation flows
   - **Review & Quality Gate**: code review covering code quality, acceptance criteria, performance-vs-targets, and security

9. **Identify Files and Components per Phase**: For each implementation phase, document:

   - **Existing files to modify**: Specific file paths in the source directory that need changes
   - **New files to create**: File paths and purposes for new components
   - **Design documents to reference**: Which sections of [FDD](../../../doc/functional-design/fdds), [TDD](../../../doc/technical/tdd), DB Schema, API, UI Design, or Instruction Design documents are relevant
   - **Existing patterns to follow**: Similar features in the codebase to reference

10. **Sequence Implementation Phases**: Order phases based on:

   - **Technical Dependencies**: Data models before repositories, repositories before services
   - **Integration Dependencies**: External service setup before integration code
   - **Risk Mitigation**: High-risk or uncertain components early in sequence
   - **Testing Opportunities**: Structure for test-driven development
   - **Session Boundaries**: Natural stopping points for long-running implementations

11. **Create Dependency Map**: Document explicit dependencies between phases:

   - Which phases BLOCK other phases (must complete before)
   - Which phases SHARE components (coordination needed across files)
   - Which phases depend on EXTERNAL systems (setup or access needed)
   - Which phases require DATABASE changes (migrations must be applied first)

12. **Estimate Effort per Phase**: Provide realistic effort estimates:
   - **Small (S)**: 1-3 hours, single component, straightforward implementation
   - **Medium (M)**: 3-8 hours, multiple related components, moderate complexity
   - **Large (L)**: 8+ hours, complex logic, extensive integration, significant testing

### Execution - Part 2: Integration and Risk Planning

13. **Identify System Integration Points**: Document where feature touches existing system:

    - **Database**: Tables/views accessed, migrations needed, RLS policy impact
    - **Authentication**: Auth requirements, role checks, permission guards
    - **State Management**: Global state interactions, provider dependencies
    - **Navigation**: Route definitions, deep links, navigation guards
    - **External Services**: API calls, third-party integrations, service dependencies

14. **Define Testing Strategy per Phase**: Specify testing approach for each implementation task:

    - **Unit Testing**: Services, repositories, utility functions, validation logic
    - **Component Testing**: UI components, forms, user interactions
    - **Integration Testing**: Database operations, API calls, service interactions
    - **End-to-End Testing**: Complete user workflows, cross-feature scenarios

15. **Assess Implementation Risks**: Identify risks and mitigation strategies:
    - **Technical Risks**: Performance bottlenecks, scalability concerns, technical debt
    - **Integration Risks**: External service dependencies, breaking changes, version conflicts
    - **Timeline Risks**: Blocking dependencies, resource constraints, scope creep
    - **Quality Risks**: Insufficient test coverage, security vulnerabilities, accessibility gaps
    - **Mitigation Strategies**: Specific actions to reduce or eliminate each identified risk
16. **🚨 CHECKPOINT**: Present implementation roadmap, dependency map, integration points, and risk assessment to human partner for review and approval

### Execution - Part 3: Documentation Creation

17. **Create Implementation Plan Document**: Use the automation script:

    ```powershell
    # Create implementation plan (include Feature ID in name; -Tier is the tier from Step 3)
    pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/04-implementation/New-ImplementationPlan.ps1 -FeatureName "[feature-id]-[feature-name]" -Description "[Brief feature description]" -Tier [1|2|3]
    ```

    The script will:

    - Create document at [`/doc/technical/implementation-plans/`](../../../doc/technical/implementation-plans) with assigned PD-IMP-XXX ID
    - Filename will include Feature ID: `[feature-id]-[feature-name]-implementation-plan.md`
    - Select the template by tier — `-Tier 1` emits the lightweight variant; tiers 2/3 emit the full one. Passing the feature's real tier is what makes a Tier 1 plan lightweight
    - Populate template with feature information
    - Guide you to complete remaining sections

18. **Complete Implementation Plan Sections**: Fill in all template sections:

    - **Feature Overview**: Brief summary with links to design documents ([FDD](../../../doc/functional-design/fdds), [TDD](../../../doc/technical/tdd), API, DB, UI)
    - **Implementation Objectives**: Clear goals and success criteria for implementation
    - **Implementation Phases**: Sequenced breakdown with descriptions and effort estimates
    - **Architecture Context**: Build footprint (components created vs. modified) plus the Design Inputs table linking each governing design document — summarize, never restate, what those documents own
    - **Dependency Map**: Visual or text-based representation of phase dependencies
    - **Integration Points**: System touchpoints with implementation notes
    - **Testing Strategy**: Testing approach per implementation phase
    - **Risk Assessment**: Identified risks with severity and mitigation strategies
    - **Success Criteria**: Measurable completion criteria for the implementation

19. **Initialize Feature Implementation State File**: The Feature Implementation State file was already created by [Feature Request Evaluation (PF-TSK-067)](../01-planning/feature-request-evaluation.md). Locate it at [`/doc/state-tracking/features/`](../../../doc/state-tracking/features) and populate the planning-phase sections of its tier variant — the [state template](../../templates/04-implementation/feature-implementation-state-template.md) defines the structure, and the [`feature-implementation-planning` craft skill](../../../.claude/skills/feature-implementation-planning/SKILL.md) (activated at Step 1) owns the section-by-section judgment for filling it. Two task-owned obligations while doing so:
    - **Dimension Profile**: record the dimension applicability evaluation from step 6 — this section is the **single source of truth** for dimension awareness during implementation, review, and validation
    - **`### User Documentation` subsection** (in Documentation Inventory): populate it by applying the [Diátaxis Content Type Guide](../../guides/07-deployment/diataxis-content-type-guide.md):
      - Evaluate whether this feature has user-visible behavior (new CLI options, configuration, workflows, commands)
      - If **no user-visible behavior**: add a single row with Content Type `N/A` and Status `N/A` plus a brief rationale (e.g., "internal foundation feature")
      - If **user-visible behavior**: apply the guide's [decision matrix](../../guides/07-deployment/diataxis-content-type-guide.md#decision-matrix) and [typical mappings](../../guides/07-deployment/diataxis-content-type-guide.md#typical-mappings) to identify which content types the feature will likely need. Create **one row per identified content type**, each with the appropriate Content Type set and Status `❌ Needed`
      - Each row with status `❌ Needed` is independently a trigger for [User Documentation Creation (PF-TSK-081)](../07-deployment/user-documentation-creation.md) after test scoping; the feature is `🟢 Completed` only when all rows are `✅ Created`

### Finalization

20. **🚨 CHECKPOINT**: Present completed implementation plan document and initialized feature state file to human partner for final review and approval

21. **Validate Plan Completeness**: Review both documents for quality:

    - All implementation phases are clearly defined with reasonable scope
    - Specific file paths documented for each phase (what to create/modify in the source directory)
    - Design document sections mapped to relevant phases
    - Dependencies are explicitly stated and sequencing is logical
    - Effort estimates are realistic and justified
    - Integration points are identified with sufficient detail
    - Risks have specific, actionable mitigation strategies
    - Testing strategy covers all critical paths

22. **Update Feature Tracking**: Update [`feature-tracking.md`](../../../doc/state-tracking/permanent/feature-tracking.md):

    - Update status to indicate planning is complete
    - Keep Notes column brief — implementation plan and feature state links are accessed via the feature ID column (which links to the state file)

23. **Document Planning Decisions**: Record any significant decisions made during planning:

    - Phase sequencing rationale
    - File organization approach
    - Scope trade-offs or deferrals
    - Alternative approaches considered

24. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Outputs

- **Implementation Plan Document** - Strategic roadmap at [`/doc/technical/implementation-plans/`](../../../doc/technical/implementation-plans)`[feature-id]-[feature-name]-implementation-plan.md` with assigned PD-IMP-XXX ID containing:
  - **Feature Overview**: Brief summary with links to all design documents ([FDD](../../../doc/functional-design/fdds), [TDD](../../../doc/technical/tdd), API, DB, UI)
  - **Implementation Objectives**: Clear goals and success criteria
  - **Implementation Phases**: Sequenced breakdown with descriptions and effort estimates
  - **Architecture Context**: Build footprint (components created vs. modified) plus the Design Inputs table linking each governing design document — the per-phase file mapping belongs to the state file's File and Component Context, not here
  - **Dependency Map**: Visual or text-based representation of phase dependencies
  - **Integration Points**: System touchpoints with implementation guidance
  - **Testing Strategy**: Testing approach per implementation phase (unit, component, integration, e2e)
  - **Risk Assessment**: Identified risks with severity levels and specific mitigation strategies
  - **Success Criteria**: Measurable completion criteria for the implementation
- **Feature Implementation State File** - **PERMANENT** living document at [`/doc/state-tracking/features/`](../../../doc/state-tracking/features)`[feature-id]-implementation-state.md` (created by [Feature Request Evaluation (PF-TSK-067)](../01-planning/feature-request-evaluation.md)) with its planning-phase sections initialized — structure per the tier's [state template variant](../../templates/04-implementation/feature-implementation-state-template.md), content per the [`feature-implementation-planning` craft skill](../../../.claude/skills/feature-implementation-planning/SKILL.md)'s section-by-section judgment. The **Dimension Profile** is the single source of truth for dimension awareness during implementation, review, and validation; the **File and Component Context** mapping is what lets implementation tasks work without re-reading all design documents.

  > **🚨 CRITICAL**: This document is NEVER archived. It serves as permanent feature documentation throughout the entire feature lifecycle.

## State Tracking

The following state files must be updated as part of this task:

- **[Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md)** - Manual update required:
  - Locate the feature entry in the appropriate category section
  - Update status if applicable (e.g., from "🔧 Needs Impl Plan" to "🟡 In Progress" when implementation begins)
  - Keep the **Notes** column brief — the implementation plan and state file are accessed via the feature ID column link (per step 22)
- **Feature Implementation State File** - Initialize the existing file at [`/doc/state-tracking/features/`](../../../doc/state-tracking/features)`[feature-id]-implementation-state.md` (created by [Feature Request Evaluation (PF-TSK-067)](../01-planning/feature-request-evaluation.md)):
  - Populate planning-phase sections with contextual information
  - This file will be continuously updated throughout implementation (NEVER archived)

## ⚠️ MANDATORY Task Completion Checklist

> Completion discipline, output verification, and the feedback form are governed by the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md) (Phase C). The items below are the **task-specific** verifications that plug into it.

- [ ] **Verify Outputs - Implementation Plan Document**: Confirm implementation plan is complete and comprehensive
  - [ ] Document created at [`/doc/technical/implementation-plans/`](../../../doc/technical/implementation-plans) with proper naming including Feature ID and assigned PD-IMP-XXX ID
  - [ ] **Feature Overview**: Includes brief summary and links to all design documents ([FDD](../../../doc/functional-design/fdds), [TDD](../../../doc/technical/tdd), API, DB, UI)
  - [ ] **Implementation Objectives**: Clear goals and success criteria defined
  - [ ] **Implementation Phases**: Sequenced breakdown with descriptions and effort estimates
  - [ ] **Architecture Context**: Build footprint documented and every governing design document linked in Design Inputs, with no design content restated
  - [ ] **Dependency Map**: Dependencies clearly documented (blocking phases, shared components, external systems, data stores)
  - [ ] **Integration Points**: All system touchpoints identified with implementation guidance
  - [ ] **Testing Strategy**: Testing approach defined per implementation phase
  - [ ] **Risk Assessment**: Risks identified with severity levels and specific, actionable mitigation strategies
  - [ ] **Success Criteria**: Measurable completion criteria defined
- [ ] **Verify Outputs - Feature Implementation State File**: Confirm the state file (created by [Feature Request Evaluation (PF-TSK-067)](../01-planning/feature-request-evaluation.md), status now "PLANNING") is properly initialized
  - [ ] All planning-phase sections of the tier variant populated per the [`feature-implementation-planning` craft skill](../../../.claude/skills/feature-implementation-planning/SKILL.md)'s section-by-section judgment — including the **File and Component Context** mapping (files to create/modify and test files per phase, with the design-document sections that inform each) and **Implementation Progress** matching the implementation plan
  - [ ] **Dimension Profile**: all 10 dimensions evaluated with importance level (Critical/Relevant/N/A), key considerations for applicable dimensions, N/A rationale for excluded ones
  - [ ] **User Documentation subsection** populated per the [Diátaxis Content Type Guide](../../guides/07-deployment/diataxis-content-type-guide.md) (one row per needed content type with `❌ Needed`, or a justified `N/A` row)
- [ ] **Verify Cross-References**: Ensure proper linking between documents
  - [ ] Implementation plan references all design documents ([FDD](../../../doc/functional-design/fdds), [TDD](../../../doc/technical/tdd), API, DB, UI)
  - [ ] Feature state file references implementation plan
  - [ ] Feature state file includes specific file paths in the source directory and the test directory
  - [ ] Both documents reference feature tracking entry
- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] [`feature-tracking.md`](../../../doc/state-tracking/permanent/feature-tracking.md) updated with:
    - Status updated if applicable
    - Notes column kept brief (no redundant links — implementation plan and state file are accessible via feature ID link)
- [ ] **Validate Planning Quality**: Review planning decisions and assumptions
  - [ ] Phase breakdown is logical and manageable
  - [ ] File and component mapping is complete and accurate (all files in the source directory identified)
  - [ ] Design document sections mapped to relevant implementation phases
  - [ ] Dependencies are complete and accurate
  - [ ] Effort estimates are realistic
  - [ ] Integration risks are identified
  - [ ] Testing strategy is comprehensive
  - [ ] Mitigation strategies are actionable
- [ ] **Feedback form** completed per the [Task Execution Protocol → Feedback step](../../guides/framework/task-execution-protocol-guide.md#feedback-step) — task ID `PF-TSK-044`, context "Feature Implementation Planning Task".

## File Operations

| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | Implementation Plan Document (PD-IMP-XXX) | `New-ImplementationPlan.ps1` | Detailed implementation plan with task sequencing and dependency mapping |
| **Updates** | Feature Implementation State File | Manual | Initialize planning-phase sections (file created earlier by Feature Request Evaluation, PF-TSK-067) |
| **Updates** | [`feature-tracking.md`](../../../doc/state-tracking/permanent/feature-tracking.md) | Manual | Links to implementation plan and feature state file |

## Next Tasks

After completing the implementation planning, begin implementing the feature using existing task definitions:

1. **Begin Implementation** - Use the created implementation plan and feature state file:
   - Follow the decomposed implementation tasks: [Data Layer (PF-TSK-051)](data-layer-implementation.md) → [Integration & Testing (PF-TSK-053)](integration-and-testing.md) → [Implementation Finalization (PF-TSK-055)](implementation-finalization.md) → [Code Review (PF-TSK-005)](../06-maintenance/code-review-task.md)
   - The feature state file you created contains all contextual information needed:
     - Which files in the source directory to create/modify
     - Which sections of design documents to reference
     - Implementation phase sequence and dependencies
   - Update feature state document as you progress through implementation phases
2. **Testing** - Follow testing strategy from implementation plan:
   - Create tests in the test directory as specified in feature state file
   - For Tier 3 features, may reference [Test Specification Creation Task](../03-testing/test-specification-creation-task.md) if detailed test specs are needed
3. **Code Review** - After implementation completes:
   - Use [Code Review Task](../06-maintenance/code-review-task.md) to validate implementation quality
   - Reference implementation plan's success criteria
   - Update feature state file with review outcomes

**Implementation Workflow:**

```
Implementation Planning (this task - PF-TSK-044) →
  Creates: Implementation Plan + Feature State File (with file/component context) →
    Decomposed Implementation Tasks (PF-TSK-051 → 056 → 052 → 053 → 054 → 055) →
      Update Feature State throughout implementation →
        Code Review (PF-TSK-005) →
          Feature Complete
```

**Key Concept**: This planning task prepares a detailed roadmap and context document. The actual implementation uses the decomposed implementation tasks, which guide the process while the feature state file provides all the feature-specific context.

## Related Resources

### Task Definition and Execution

- **[Data Layer Implementation (PF-TSK-051)](data-layer-implementation.md)** - First decomposed implementation task for data models and repositories
- **[`task-creation` craft skill](../../../.claude/skills/task-creation/SKILL.md)** - How to create decomposed implementation tasks using New-Task.ps1
- **[Information Flow Guide](../../guides/framework/information-flow-guide.md)** - Information flow and separation of concerns between tasks

### State Tracking and Documentation

- **[Feature Implementation State Template](../../templates/04-implementation/feature-implementation-state-template.md)** - Template for permanent state tracking
- [`feature-implementation-planning` craft skill](../../../.claude/skills/feature-implementation-planning/SKILL.md) - the state-file initialization and maintenance craft (replaces the retired Feature Implementation State Tracking Guide); activated by the Check Recommended Skills step
- **[Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md)** - Central feature tracking document

### Design Documentation (Inputs)

- **[FDD Creation Task](../02-design/fdd-creation-task.md)** - Understanding functional design inputs
- **[TDD Creation Task](../02-design/tdd-creation-task.md)** - Understanding technical design inputs
- **[API Design Task](../02-design/api-design-task.md)** - Understanding API design inputs
- **[Database Schema Design Task](../02-design/database-schema-design-task.md)** - Understanding database design inputs
- **[Instruction Design Task](../02-design/instruction-design-task.md)** - Understanding instruction design inputs

### Architecture and Standards

- **[Architecture Decision Records](../../../doc/technical/adr)** - Architectural constraints and decisions

### Testing and Validation

- **[Test Specification Creation Task](../03-testing/test-specification-creation-task.md)** - Creating comprehensive test specifications
<!-- Testing Strategy Documentation - directory /doc/technical/testing does not exist in this project -->
- **[Code Review Task](../06-maintenance/code-review-task.md)** - Post-implementation validation
