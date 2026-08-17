---
id: PF-TSK-012
type: Process Framework
category: Task Definition
domain: agnostic
version: 3.6
created: 2025-01-15
updated: 2026-08-05
change_notes: "v3.5 - PF-PRO-059 pilot: edge-case file enabled (skill references/edge-cases.md); no-test-feature note routed there"
description: "Create comprehensive test specifications from TDDs"
complexity: medium
use_when: >-
  Create automated test specifications from TDDs for Test-First Development. Triggers: 'create test spec', 'write test specification', 'spec the tests for feature X'.
triggers:
  - "create test spec"
  - "write test specification"
  - "spec the tests for feature X"
automation: full
scripts:
  - ../../scripts/file-creation/03-testing/New-TestSpecification.ps1
trigger_status:
  - file: feature-tracking.md
    status: "🧪 Needs Test Spec"
output_status:
  - file: feature-tracking.md
    status: "🔧 Needs Impl Plan"
next_tasks:
  - task: ../04-implementation/integration-and-testing.md
    condition: "Implement automated test cases and validate integration after feature implementation"
  - task: ../04-implementation/feature-implementation-planning-task.md
    condition: "Plan and execute feature implementation using decomposed tasks"
  - task: ../06-maintenance/code-review-task.md
    condition: "Review implemented tests and code for quality assurance"
---

# Test Specification Creation

> **▶ Execute this task under the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md).** This file holds only this task's specific content; the universal contract every task shares lives once in the protocol and is mandatory here.

## Purpose & Context

Create automated test specifications from existing Technical Design Documents (TDDs) to enable Test-First Development Integration (TFDI), providing behavioral specifications that complement architectural design and facilitate AI-assisted development across sessions.

## AI Agent Role

**Role**: QA Engineer
**Mindset**: Quality-first, thorough, prevention-focused
**Focus Areas**: Test coverage, edge cases, quality gates, behavioral validation
**Communication Style**: Emphasize comprehensive testing and quality metrics, ask about edge cases and failure scenarios

## Information Flow

> **📋 Ownership & cross-reference rules**: [Information Flow Guide → Test Specification Creation Task (PF-TSK-012)](../../guides/framework/information-flow-guide.md#test-specification-creation-task-pf-tsk-012) — what this task owns, what it references instead, and the cross-reference format.

### Inputs from Other Tasks

- **[FDD Creation](../02-design/fdd-creation-task.md)** (Tier 2+): Functional requirements, acceptance criteria, user workflows, business rules
- **Tier assessment** (via [Feature Request Evaluation](../01-planning/feature-request-evaluation.md)): Complexity tier, test depth requirements, quality attribute priorities
- **[TDD Creation](../02-design/tdd-creation-task.md)**: Technical architecture, component interactions, quality attribute requirements, implementation approach
- **[API Design](../02-design/api-design-task.md)**: API contracts, endpoint specifications, request/response schemas
- **[Database Schema Design](../02-design/database-schema-design-task.md)**: Data validation rules, security policies, performance requirements

### Outputs to Other Tasks

- **[Integration and Testing](../04-implementation/integration-and-testing.md)**: Test cases, test data, mock strategies, validation criteria, test implementation roadmap

## Context Requirements

- **Critical (Must Read):**

  - [Functional Design Document](../../../doc/functional-design/fdds) - For Tier 2+ features, the FDD containing acceptance criteria and user flows that inform test scenarios
  - [Technical Design Document](../../../doc/technical/tdd) - The TDD for the feature being specified
  - [Tier Assessments](../../../doc/documentation-tiers/assessments) - Complexity assessment to determine test depth
  - [Development Guide](../../guides/04-implementation/development-guide.md) - Testing standards and practices

- **Important (Load If Space):**

  - [`test-specification` craft skill](../../../.claude/skills/test-specification/SKILL.md) — the customization craft (tier-appropriate depth, TDD-to-test-category mapping, mock requirements, Implementation Coverage line), activated in Preparation Step 1 (Check Recommended Skills). Replaces the former procedural customization guide and drives the spec customization in the Specification Phase.
  - Pytest markers (via `test_query.py --feature X.Y.Z`) - Current test file metadata
  - [Test Tracking](../../../test/state-tracking/permanent/test-tracking.md) - Current test implementation status
  - [Existing Test Structure](../../../test) - Current test organization and patterns

- **Reference Only (Access When Needed):**
  - [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) - Feature development status
  - [TE ID Registry](../../../test/TE-id-registry.json) - Test document ID counter management

## Process

> **⚠️ MANDATORY: Create test specifications that complement, not replace, the existing TDD.**
>
> **⚠️ MANDATORY: Use the Test Specification Template for consistency.**
>
> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**
>
> **Instruction-medium branch (PF-PRO-064)**: for a feature whose medium is `instruction` — or the instruction part of a `mixed` feature — **verification-level selection and L3 fixtures replace test files and coverage**. The specification records which instruction verification levels apply and what each concretely checks: L1 static (`Build-DocumentationMap.ps1 -Tree SC -Check` + LinkWatcher), L2 contract (`Check-InstructionContract.ps1` over the feature's artifacts), L3 execution (agent-executed fixture cases — specify scenario, seeded fixture, and discriminating oracle assertions per the `e2e-test-case-creation` skill's instruction-fixtures reference). The feature's Instruction Design document (§6 Verification Plan) is the input, the way the TDD is for code; coverage targets and mock requirements are code concepts — mark them N/A for the instruction part.

### Preparation

1. **Check Recommended Skills**: Read the active language-config (`languages-config/{language}/{language}-config.json`) and `project-config.json` for `recommended_skills` entries keyed to `test-specification-creation-task`. If the `test-specification` craft skill is available in the session, activate it — it owns the **customization craft** this task delegates to (how to fill the Test Specification well; its test-file reference also serves the tasks that implement tests). If it is not listed in the session, read [`SKILL.md`](../../../.claude/skills/test-specification/SKILL.md) directly and apply it — that file is the canonical source the Skill tool loads, so a direct read is equivalent, not degraded. The customization craft is unavailable for this run only if the skill file itself is absent (the retired procedural customization guide has no successor).
2. **Review the Functional Design Document (FDD)**: For Tier 2+ features, read the FDD to understand acceptance criteria and user flows that need testing
3. **Review the Target TDD**: Read the complete Technical Design Document for the feature
4. **Review UI Documentation** (if applicable): For features with UI interactions, review any UI documentation linked from feature tracking to identify UI component test scenarios
5. **Review Dimension Profile**: Read the feature's Dimension Profile from its implementation state file and include test scenarios for **Critical** dimensions — e.g., Critical SE → security boundary tests, Critical DI → data integrity edge cases. On the first-pass workflow the section is still empty (Feature Implementation Planning populates it downstream): derive the same Critical-dimension scenarios from the FDD/TDD directly, applying the [Development Dimensions Guide](../../guides/framework/development-dimensions-guide.md)'s applicability criteria at tier-appropriate depth. Either way, consider focused test specs even for Tier 1/2 features when SE or DI is Critical.
6. **Assess Automated Test Depth**: Review the feature's tier assessment to determine the breadth and depth of automated tests (unit, integration, UI/component) at the tier-appropriate depth per the `test-specification` skill's tier-depth guidance
7. **Analyze Existing Test Structure**: Review current test organization and identify patterns to follow
8. **Identify Test Dependencies**: Determine what mocks, helpers, and test utilities are needed
9. **🚨 CHECKPOINT**: Present test complexity assessment, dimension profile test implications, existing test structure analysis, and identified dependencies to human partner for approval before proceeding to specification

### Specification Phase

10. **Create Test Specification Document(s)** using the automation script:

    ```bash
    pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/03-testing/New-TestSpecification.ps1 -FeatureId "X.Y.Z" -FeatureName "Feature Name" -Confirm:\$false
    ```

11. **Specify Test Cases**: For each TDD component, define test cases at the depth determined by the tier assessment, structured per the `test-specification` skill's test-case guidance (Arrange/Act/Assert, edge cases, error scenarios)

12. **Map TDD Components to Tests**: Create an explicit component→test-category mapping per the `test-specification` skill's Test Categories mapping

13. **Define Mock Requirements**: Specify what mocks are needed and their expected behaviors

14. **Add Clickable Links**: Ensure all file path references in the specification are clickable markdown links:
    - **Test File** references (e.g., `test/automated/unit/test_service.py`) must use markdown link format: `[path](relative/path/to/file)` with correct relative prefix
    - **Files to Reference** section paths (TDD, source code, fixtures) must be linked
    - **Source Code** references (e.g., `src/linkwatcher/database.py`) must be linked
    - Relative prefix from `test/specifications/feature-specs` to project root is `../../../doc`

15. **🚨 CHECKPOINT**: Present draft test specification with test cases, mock requirements, and TDD mappings to human partner for review and approval

### Finalization

16. **Review Test Coverage**: Ensure all TDD components have corresponding test specifications
17. **Validate Test Feasibility**: Confirm all specified tests can be implemented with available tools
18. **Update State Tracking**: Add feature section to [Test Tracking](../../../test/state-tracking/permanent/test-tracking.md) if missing. Update [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) Test Status to "📋 Specs Created". The Test Specification document link itself is inserted into the per-feature state file's §4 Documentation Inventory by `New-TestSpecification.ps1` (PF-PRO-002 / PF-IMP-760).
19. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Outputs

- **Test Specification Document** — Automated test specifications in `/test/specifications/feature-specs/test-spec-[FEATURE-ID]-[feature-name].md`
- **Component-to-Test Mapping** — Explicit mapping between TDD components and test types (unit, integration, component)
- **Mock Requirements Documentation** — Detailed specifications for required mocks and their behaviors

## State Tracking

The following state files must be updated as part of this task:

- [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) — Update Test Status to "📋 Specs Created"
- Per-feature state file (`doc/state-tracking/features/<id>-implementation-state.md`) — Test Specification row inserted into §4 Documentation Inventory by `New-TestSpecification.ps1` (PF-PRO-002 / PF-IMP-760)
- [TE ID Registry](../../../test/TE-id-registry.json) — Update `TE-TSP.nextAvailable` counter after creating specifications
- [Test Documentation Map](../../../test/TE-documentation-map.md) — Regenerated via `Build-DocumentationMap.ps1 -Tree TE` to pick up the new spec's `description:` (generated DO-NOT-EDIT projection, PF-PRO-050)
- [Test Tracking](../../../test/state-tracking/permanent/test-tracking.md) — Add feature section if missing

**Note**: A feature that turns out not to need tests: see the `test-specification` skill's [edge-case file](../../../.claude/skills/test-specification/references/edge-cases.md).

## ⚠️ MANDATORY Task Completion Checklist

> Completion discipline, output verification, and the feedback form are governed by the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md) (Phase C). The items below are the **task-specific** verifications that plug into it.

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] Test Specification Document created in `/test/specifications/feature-specs`
  - [ ] Implementation Coverage summary line set in Overview (e.g., `0/N scenarios implemented (0%)`)
  - [ ] Component-to-test mapping completed (TDD components → unit/integration/component tests)
  - [ ] Mock Requirements Documentation completed
- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) — Test Status updated to "📋 Specs Created"
  - [ ] Per-feature state file §4 Documentation Inventory — Test Specification row inserted by `New-TestSpecification.ps1` (PF-PRO-002 / PF-IMP-760)
  - [ ] [TE ID Registry](../../../test/TE-id-registry.json) — `TE-TSP.nextAvailable` counter incremented
  - [ ] [Test Documentation Map](../../../test/TE-documentation-map.md) — Regenerated via `Build-DocumentationMap.ps1 -Tree TE` and `-Check`-clean (reflects the new spec's `description:`)
  - [ ] [Test Tracking](../../../test/state-tracking/permanent/test-tracking.md) — Feature section added if missing
- [ ] **Feedback form** completed per the [Task Execution Protocol → Feedback step](../../guides/framework/task-execution-protocol-guide.md#feedback-step) — task ID `PF-TSK-012`, context "Test Specification Creation".

## File Operations

| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | `test-spec-[FeatureId]-[FeatureName].md` | `New-TestSpecification.ps1` | Comprehensive test specification document |
| **Updates** | [`feature-tracking.md`](../../../doc/state-tracking/permanent/feature-tracking.md) | `New-TestSpecification.ps1` | Test Status → "📋 Specs Created"<br/>• Add specification creation date to Notes |
| **Updates** | Per-feature state file (`doc/state-tracking/features/<id>-implementation-state.md`) | `New-TestSpecification.ps1` (via `Add-StateFileDocumentationInventoryRow`) | Insert Test Specification row into §4 Documentation Inventory (PF-PRO-002 / PF-IMP-760) |
| **Updates** | [`TE-id-registry.json`](../../../test/TE-id-registry.json) | `New-TestSpecification.ps1` | Update TE-TSP nextAvailable counter |
| **Updates** | [`TE-documentation-map.md`](../../../test/TE-documentation-map.md) | Generated by [`Build-DocumentationMap.ps1 -Tree TE`](../../scripts/validation/Build-DocumentationMap.ps1); `-Check` drift gate | Regenerate to reflect the new spec's `description:` (DO-NOT-EDIT projection, PF-PRO-050) |
| **Updates** | [`test-tracking.md`](../../../test/state-tracking/permanent/test-tracking.md) | Manual | Add feature section if missing |

## Next Tasks

- [**Integration & Testing (PF-TSK-053)**](../04-implementation/integration-and-testing.md) — Implement automated test cases and validate integration after feature implementation
- [**Feature Implementation Planning**](../04-implementation/feature-implementation-planning-task.md) — Plan and execute feature implementation using decomposed tasks
- [**Code Review**](../06-maintenance/code-review-task.md) — Review implemented tests and code for quality assurance

<!-- merged from transition-registry entry: Test Specification Creation -->
### Prerequisites for Transition

- [ ] Test specification document created
- [ ] Test cases cover all TDD requirements
- [ ] Test specification linked in tracking files
- [ ] Test approach validated

### Next Task Selection

```
Is test-first development approach being used?
├─ Yes → Integration & Testing
│   └─ Reason: Implement tests before feature development for TDD approach
└─ No → Feature Implementation
    └─ Reason: Proceed directly to feature implementation with test specifications as reference
```

### Preparation for Next Task

1. Review test specification to understand testing requirements
2. Ensure test cases align with TDD design
3. Verify test data and environment requirements
4. Confirm testing approach is feasible

## Related Resources

- [`test-specification` craft skill](../../../.claude/skills/test-specification/SKILL.md) - the Test Specification customization craft (replaces the retired customization guide); activated by the Check Recommended Skills step. Its [test-file customization reference](../../../.claude/skills/test-specification/references/test-file-customization.md) is the craft home for tasks that create test files.
- [Test Infrastructure Guide](../../guides/03-testing/test-infrastructure-guide.md) - test/ directory conventions, isolation rules, and the Test Documentation Completeness procedure
