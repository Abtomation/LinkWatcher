---
id: PF-TSK-012
type: Process Framework
category: Task Definition
domain: agnostic
version: 2.0
created: 2025-01-15
updated: 2026-04-10
change_notes: "v2.0 - Restructured into Preparation/Routing/Specification phases (PF-IMP-424). Added state tracking seeding step for e2e-test-tracking and performance-test-tracking (PF-IMP-425). Standardized terminology to automated/e2e/both (PF-IMP-426). Removed AI Session Context step (not consumed by downstream tasks). Fixed Next Tasks to reference PF-TSK-069 and PF-TSK-084."
---

# Test Specification Creation

## Purpose & Context

Create comprehensive test specifications from existing Technical Design Documents (TDDs) to enable Test-First Development Integration (TFDI), providing behavioral specifications that complement architectural design and facilitate AI-assisted development across sessions.

## AI Agent Role

**Role**: QA Engineer
**Mindset**: Quality-first, thorough, prevention-focused
**Focus Areas**: Test coverage, edge cases, quality gates, behavioral validation
**Communication Style**: Emphasize comprehensive testing and quality metrics, ask about edge cases and failure scenarios

## When to Use

- After a Technical Design Document (TDD) has been created for a feature
- Before beginning Test-First Development Implementation of a feature
- When transitioning from design phase to implementation phase
- When preparing comprehensive test context for AI agent sessions
- When implementing features that require behavioral validation alongside architectural guidance
- When establishing test-driven development practices for complex features

## When NOT to Use

- For assessment/documentation features that don't produce testable code (mark as "🚫 No Test Required" in feature tracking)
- For pure analysis tasks that only generate documentation
- For architectural assessment features that establish baselines rather than implement functionality

## Information Flow

> **📋 Detailed Guidance**: See [Task Transition Guide - Information Flow Section](../../guides/framework/task-transition-guide.md#information-flow-and-separation-of-concerns)

### Inputs from Other Tasks

- **[FDD Creation](/process-framework/tasks/02-design/fdd-creation-task.md)** (Tier 2+): Functional requirements, acceptance criteria, user workflows, business rules
- **[Feature Tier Assessment](/process-framework/tasks/01-planning/feature-tier-assessment-task.md)**: Complexity tier, test depth requirements, quality attribute priorities
- **[TDD Creation](/process-framework/tasks/02-design/tdd-creation-task.md)**: Technical architecture, component interactions, quality attribute requirements, implementation approach
- **[API Design](/process-framework/tasks/02-design/api-design-task.md)**: API contracts, endpoint specifications, request/response schemas
- **[Database Schema Design](/process-framework/tasks/02-design/database-schema-design-task.md)**: Data validation rules, security policies, performance requirements

### Outputs to Other Tasks

- **[Integration and Testing](/process-framework/tasks/04-implementation/integration-and-testing.md)**: Test cases, test data, mock strategies, validation criteria, test implementation roadmap
- **[Performance Test Creation](/process-framework/tasks/03-testing/performance-test-creation-task.md)**: Performance test specification (when PE dimension applies) — test levels, operations, tolerances, measurement methodology
- **[E2E Acceptance Test Case Creation](/process-framework/tasks/03-testing/e2e-acceptance-test-case-creation-task.md)**: E2E test scenario requirements — scenarios classified as `e2e` or `both` with user actions, expected outcomes, and test group assignments

### Cross-Reference Standards

When referencing other tasks' outputs in Test Specifications:

- Use brief summary (2-5 sentences) + link to source document
- Focus on **testing-level perspective** (how to validate it, not how to build it)
- Avoid duplicating functional requirements, technical architecture, or API contracts
- Reference acceptance criteria from FDD and quality requirements from TDD

### Separation of Concerns

**✅ Test Specifications Should Document:**

- Test cases and test scenarios
- Test data and mock strategies
- Validation criteria and assertions
- Test implementation roadmap
- Test coverage requirements
- Testing-specific quality attributes
- Test environment setup
- Edge cases and failure scenarios
- Test execution order and dependencies

**❌ Test Specifications Should NOT Document:**

- Functional requirements (owned by FDD)
- Technical implementation details (owned by TDD)
- API endpoint contracts (owned by API Design Task)
- Database schema design (owned by Database Schema Design Task)
- Component architecture (owned by TDD)
- Business rules (owned by FDD)

## Context Requirements

[View Context Map for this task](../../visualization/context-maps/03-testing/test-specification-creation-map.md)

- **Critical (Must Read):**

  - [Functional Design Document](/doc/functional-design/fdds) - For Tier 2+ features, the FDD containing acceptance criteria and user flows that inform test scenarios
  - [Technical Design Document](/doc/technical/tdd) - The TDD for the feature being specified
  - [Tier Assessments](/doc/documentation-tiers/assessments) - Complexity assessment to determine test depth
  - [Development Guide](/process-framework/guides/04-implementation/development-guide.md) - Testing standards and practices

- **Important (Load If Space):**

  - Pytest markers (via `test_query.py --feature X.Y.Z`) - Current test file metadata
  - [Test Tracking](/test/state-tracking/permanent/test-tracking.md) - Current test implementation status
  - [Existing Test Structure](/test/) - Current test organization and patterns

- **Reference Only (Access When Needed):**
  - [Feature Tracking](/doc/state-tracking/permanent/feature-tracking.md) - Feature development status
  - [Visual Notation Guide](/process-framework/guides/support/visual-notation-guide.md) - For interpreting context map diagrams
  - [TE ID Registry](/test/TE-id-registry.json) - Test document ID counter management

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished! 🚨**
>
> **⚠️ MANDATORY: Create test specifications that complement, not replace, the existing TDD.**
>
> **⚠️ MANDATORY: Use the Test Specification Template for consistency.**
>
> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

### Preparation

1. **Review the Functional Design Document (FDD)**: For Tier 2+ features, read the FDD to understand acceptance criteria and user flows that need testing
2. **Review the Target TDD**: Read the complete Technical Design Document for the feature
3. **Review UI Documentation** (if applicable): For features with UI interactions, review any UI documentation linked from feature tracking to identify scenarios requiring E2E validation with the running system
4. **Review Dimension Profile**: Read the feature's Dimension Profile from its implementation state file. Include test scenarios for **Critical** dimensions — e.g., Critical SE → security boundary tests, Critical DI → data integrity edge cases. Consider creating focused test specs even for Tier 1/2 features when they have Critical SE or DI dimensions.
   - **PE dimension handling**: Note whether the PE dimension applies using the [Performance Testing Guide](/process-framework/guides/03-testing/performance-testing-guide.md) decision matrix. If yes, this will be captured as a routing dimension in the Routing Phase.
5. **Assess Test Complexity**: Review the feature's tier assessment to determine appropriate test depth:
   - **Tier 1 🔵**: Basic unit tests and key integration scenarios
   - **Tier 2 🟠**: Comprehensive unit tests, integration tests, and UI/component tests
   - **Tier 3 🔴**: Full test suite including unit, integration, UI/component, and end-to-end tests
6. **Analyze Existing Test Structure**: Review current test organization and identify patterns to follow
7. **Identify Test Dependencies**: Determine what mocks, helpers, and test utilities are needed
8. **🚨 CHECKPOINT**: Present test complexity assessment, dimension profile test implications, existing test structure analysis, and identified dependencies to human partner for approval

### Routing Phase

> **Purpose**: Determine which downstream test tasks this feature triggers and produce an explicit routing plan before detailed specification work begins. This is the task's primary gate function — routing decisions made here inform the scope and depth of the Specification Phase.

9. **Identify Test Paths**: For each TDD component, make two independent routing decisions:

   **a) Execution method classification** — who runs the test:
   - **`automated`** — Covered by unit/integration tests that an AI agent can implement and run → feeds [Integration and Testing (PF-TSK-053)](/process-framework/tasks/04-implementation/integration-and-testing.md)
   - **`e2e`** — Requires human interaction with the running system (file moves, UI operations, observing real-time behavior) → feeds [E2E Acceptance Test Case Creation (PF-TSK-069)](/process-framework/tasks/03-testing/e2e-acceptance-test-case-creation-task.md)
   - **`both`** — Needs automated regression test + E2E acceptance validation → feeds both PF-TSK-053 and PF-TSK-069

   **b) Additional routing dimensions** (orthogonal to classification):
   - **Performance (PE)** — Does the PE dimension apply (identified in Step 4)? If yes → feeds [Performance Test Creation (PF-TSK-084)](/process-framework/tasks/03-testing/performance-test-creation-task.md)
   - **Cross-cutting** — Does this feature participate in multi-feature user workflows? Reference [User Workflow Tracking](/doc/state-tracking/permanent/user-workflow-tracking.md). If this is the **last** feature needed for a workflow, a cross-cutting E2E test specification should be created (milestone trigger)

10. **Create Routing Plan**: Produce a routing summary table in the test specification document's "Routing Plan" section:

    | Component | Classification | Performance | Cross-cutting | Downstream Task(s) |
    |-----------|---------------|-------------|---------------|---------------------|
    | *TDD component* | `automated` / `e2e` / `both` | Yes / No | *workflow name or —* | PF-TSK-053, PF-TSK-069, etc. |

    For components classified as `e2e` or `both`, additionally note:
    - What user action triggers the test
    - What file types, link formats, or system behaviors are involved
    - What the expected observable outcome is
    - Which test group this scenario belongs to (e.g., basic-file-operations, parser-specific, etc.)

11. **Seed State Tracking Files**: For each routing path identified, seed the corresponding downstream tracking file:
    - **automated** → Add feature section to [Test Tracking](/test/state-tracking/permanent/test-tracking.md) if missing
    - **e2e** / **both** → Add entries to [E2E Test Tracking](/test/state-tracking/permanent/e2e-test-tracking.md) with status `⬜ Not Created`
    - **performance** → Add entries to [Performance Test Tracking](/test/state-tracking/permanent/performance-test-tracking.md) with status `⬜ Specified`
    - Update [Feature Tracking](/doc/state-tracking/permanent/feature-tracking.md) Test Status — set to "🔧 Automated Only" if E2E scenarios were identified but E2E test cases not yet created, or "📋 Specs Created" if no E2E scenarios apply

12. **🚨 CHECKPOINT**: Present routing plan table, seeded tracking entries, and E2E scenario summaries to human partner for approval before proceeding to detailed specification

### Specification Phase

> **Purpose**: Create detailed test specifications informed by the routing decisions above. The routing plan determines which types of test cases to write and at what depth.

13. **Create Test Specification Document(s)** using the automation script:

    ```bash
    # Feature-specific test spec
    pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/03-testing/New-TestSpecification.ps1 -FeatureId "X.Y.Z" -FeatureName "Feature Name" -Confirm:\$false

    # Cross-cutting test spec (spans multiple features)
    pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/03-testing/New-TestSpecification.ps1 -CrossCutting -FeatureName "Spec Name" -FeatureIds "X.Y.Z, A.B.C" -Confirm:\$false
    ```

    - **If PE path is in routing plan**: Create a **separate performance test specification** using the same script. Customize it using the [Performance Test Spec Template](/process-framework/templates/03-testing/performance-test-specification-template.md) structure (level-specific criteria, baseline references, measurement methodology). This spec feeds the [Performance Test Creation](/process-framework/tasks/03-testing/performance-test-creation-task.md) task — not the functional test workflow.

14. **Specify Test Cases**: For each routed component, define test cases at the depth determined by the routing plan:

    - **Test Description**: What behavior is being tested
    - **Arrange**: Setup requirements and test data
    - **Act**: The action being performed
    - **Assert**: Expected outcomes and validation criteria
    - **Edge Cases**: Boundary conditions and error scenarios

15. **Map TDD Components to Tests**: Create explicit mapping between:

    - TDD Models → Unit test specifications
    - TDD Services → Service test specifications
    - TDD Data Flow → Integration test specifications
    - TDD UI Components → UI/component test specifications

16. **Define Mock Requirements**: Specify what mocks are needed and their expected behaviors

17. **Add Clickable Links**: Ensure all file path references in the specification are clickable markdown links:
    - **Test File** references (e.g., `test/automated/unit/test_service.py`) must use markdown link format: `[path](relative/path/to/file)` with correct relative prefix
    - **Files to Reference** section paths (TDD, source code, fixtures) must be linked
    - **Source Code** references (e.g., `linkwatcher/database.py`) must be linked
    - Relative prefix from `test/specifications/feature-specs` to project root is `../../../doc`

18. **🚨 CHECKPOINT**: Present draft test specification with test cases, routing-informed scope, mock requirements, and TDD mappings to human partner for review and approval

### Finalization

19. **Review Test Coverage**: Ensure all routed TDD components have corresponding test specifications
20. **Validate Test Feasibility**: Confirm all specified tests can be implemented with available tools
21. **Verify State Tracking Consistency**: Re-read tracking files seeded in Step 11 and verify they are consistent with the completed specification. Correct any discrepancies.
22. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Outputs

- **Test Specification Document** - Comprehensive test specifications in `/test/specifications/feature-specs/test-spec-[FEATURE-ID]-[feature-name].md`
- **Routing Plan** - Component-to-downstream-task mapping table in the test specification document's "Routing Plan" section, capturing execution method classification (`automated`/`e2e`/`both`) and additional routing dimensions (PE, cross-cutting) for each TDD component
- **Mock Requirements Documentation** - Detailed specifications for required mocks and their behaviors
- **E2E Acceptance Test Scenarios** (if applicable) - Details within the routing plan for components classified as `e2e` or `both`, with user actions, involved file types, expected outcomes, and test group assignments
- **Seeded State Tracking Entries** - Downstream tracking files seeded with work queue entries (Step 11) so downstream tasks have explicit queues to consume

## State Tracking

The following state files must be updated as part of this task (seeded in Step 11, verified in Step 21):

- [Feature Tracking](/doc/state-tracking/permanent/feature-tracking.md) - Update Test Status (🔧 Automated Only / 📋 Specs Created) and add Test Spec link
- [TE ID Registry](/test/TE-id-registry.json) - Update `TE-TSP.nextAvailable` counter after creating specifications
- [Test Documentation Map](/test/TE-documentation-map.md) - Add new test specification entries to the Test Specifications section
- [Test Tracking](/test/state-tracking/permanent/test-tracking.md) - Add feature section if missing (automated path)
- [E2E Test Tracking](/test/state-tracking/permanent/e2e-test-tracking.md) - Add entries with `⬜ Not Created` status (e2e/both path)
- [Performance Test Tracking](/test/state-tracking/permanent/performance-test-tracking.md) - Add entries with `⬜ Specified` status (PE path)

**Note**: If a feature is determined to not require tests (assessment/documentation features), update the Feature Tracking Test Status directly to "🚫 No Test Required" instead of using this task.

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

Before considering this task finished:

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] Test Specification Document created in `/test/specifications/feature-specs`
  - [ ] Routing Plan table included with component-to-downstream-task mapping
  - [ ] Implementation Coverage summary line set in Overview (e.g., `0/N scenarios implemented (0%)`)
  - [ ] Mock Requirements Documentation completed
  - [ ] Test scenarios classified as `automated`, `e2e`, or `both`
  - [ ] E2E scenario details included in routing plan (if any scenarios classified as `e2e` or `both`)
- [ ] **Update State Files**: Ensure all state tracking files have been seeded (Step 11) and verified (Step 21)
  - [ ] [Feature Tracking](/doc/state-tracking/permanent/feature-tracking.md) — Test Status updated (use "🔧 Automated Only" if E2E scenarios identified, "📋 Specs Created" if no E2E scenarios) and Test Spec link added
  - [ ] [TE ID Registry](/test/TE-id-registry.json) — `TE-TSP.nextAvailable` counter incremented
  - [ ] [Test Documentation Map](/test/TE-documentation-map.md) — New test spec entries added to Test Specifications section
  - [ ] [Test Tracking](/test/state-tracking/permanent/test-tracking.md) — Feature section added if missing (automated path)
  - [ ] [E2E Test Tracking](/test/state-tracking/permanent/e2e-test-tracking.md) — Entries added with `⬜ Not Created` status (if e2e/both scenarios exist)
  - [ ] [Performance Test Tracking](/test/state-tracking/permanent/performance-test-tracking.md) — Entries added with `⬜ Specified` status (if PE path applies)
- [ ] **Verify State Tracking Consistency**: Re-read seeded tracking files and confirm consistency with completed specification
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Completion Instructions](/process-framework/guides/framework/feedback-form-completion-instructions.md) for each tool used, using task ID "PF-TSK-012" and context "Test Specification Creation"

## Next Tasks

- [**Integration & Testing (PF-TSK-053)**](../04-implementation/integration-and-testing.md) - Implement automated test cases and validate integration after feature implementation
- [**E2E Acceptance Test Case Creation (PF-TSK-069)**](../03-testing/e2e-acceptance-test-case-creation-task.md) - Create concrete, reproducible E2E acceptance test cases from the E2E scenarios identified in the routing plan
- [**Performance Test Creation (PF-TSK-084)**](../03-testing/performance-test-creation-task.md) - Implement performance tests from performance test specification (when PE path applies)
- [**Feature Implementation Planning**](../04-implementation/feature-implementation-planning-task.md) - Plan and execute feature implementation using decomposed tasks
- [**Code Review**](../06-maintenance/code-review-task.md) - Review implemented tests and code for quality assurance

## Related Resources

- [Cross-Cutting Test Specification Template](../../templates/03-testing/cross-cutting-test-specification-template.md) - Template for tests spanning multiple features (use when test scenarios cross feature boundaries)
- [Test Specification Creation Guide](../../guides/03-testing/test-specification-creation-guide.md) - Comprehensive guide for using this task effectively
