---
id: PF-INF-002
type: Process Framework
category: Infrastructure
version: 1.0
created: 2025-07-13
updated: 2026-04-13
change_notes: "v1.0 - Moved from guides/framework/task-transition-guide.md to infrastructure/. Information Flow section extracted to PF-GDE-062. Reclassified as infrastructure registry (was PF-GDE-018)."
---

# Task Transition Registry

This document provides per-task transition procedures: prerequisites, handover artifacts, and next-task routing for every task in the framework.

> **📋 Information Flow**: For information flow patterns, task ownership boundaries, cross-reference standards, and separation of concerns guidance, see the [Information Flow Guide](../guides/framework/information-flow-guide.md).

## Overview

The process framework includes multiple interconnected tasks. This document helps you understand:

- When to transition from one task to another
- What outputs are required before transitioning
- How to prepare for the next task
- Common transition patterns and workflows

## Detailed Transition Procedures

### Transitioning FROM Codebase Feature Discovery (PF-TSK-064)

**Prerequisites for Transition:**

- [ ] [Retrospective Master State File](../../process-framework-local/state-tracking/temporary/old/retrospective-master-state.md) created with project name and DISCOVERY status
- [ ] ALL source files listed and assigned to features (100% codebase file coverage)
- [ ] ALL features added to [Feature Tracking](../../doc/state-tracking/permanent/feature-tracking.md) with IDs and descriptions
- [ ] [Feature Implementation State file](../../doc/state-tracking/features) created for every feature with complete code inventory
- [ ] Phase 1 marked complete in master state file

**Next Task Selection:**

- **Always**: → [Codebase Feature Analysis (PF-TSK-065)](../tasks/00-setup/codebase-feature-analysis.md)

**Preparation for Next Task:**

1. Verify master state shows Phase 1 complete with 100% file coverage
2. Review Feature Tracking for the full feature list to analyze
3. Identify feature categories for batching analysis sessions
4. Set master state status to "ANALYSIS"

### Transitioning FROM Codebase Feature Analysis (PF-TSK-065)

**Prerequisites for Transition:**

- [ ] Implementation patterns analyzed and documented for every feature
- [ ] Dependencies identified and documented for every feature
- [ ] Test coverage mapped for every feature
- [ ] Complexity factors noted for features without tier assessments
- [ ] Phase 2 marked complete in [master state file](../../process-framework-local/state-tracking/temporary/old/retrospective-master-state.md)

**Next Task Selection:**

- **Always**: → [Retrospective Documentation Creation (PF-TSK-066)](../tasks/00-setup/retrospective-documentation-creation.md)

**Preparation for Next Task:**

1. Verify master state shows Phase 2 complete with all features analyzed
2. Review complexity factors to plan tier assessment order (Foundation first → Tier 3 → Tier 2)
3. Identify features that already have tier assessments vs. those that need new ones
4. Set master state status to "ASSESSMENT_AND_DOCUMENTATION"

### Transitioning FROM Retrospective Documentation Creation (PF-TSK-066)

**Prerequisites for Transition:**

- [ ] Every feature has a tier assessment (created or validated)
- [ ] All Tier 2+ features have FDD and TDD, marked "Retrospective"
- [ ] All Tier 3 features have Test Specifications, marked "Retrospective"
- [ ] All Foundation 0.x.x features have ADRs where architectural decisions exist
- [ ] All document links added to [Feature Tracking](../../doc/state-tracking/permanent/feature-tracking.md)
- [ ] [Documentation Map](../PF-documentation-map.md) updated with all new documents
- [ ] Final metrics recorded in master state Completion Summary
- [ ] [Master State File](../../process-framework-local/state-tracking/temporary/old/retrospective-master-state.md) archived to `/temporary/archived/`

**Next Task Selection:**

```
What work follows the completed onboarding?
├─ Extend or modify existing features → Feature Implementation
├─ Validate code against documented design → Code Review
├─ Address technical debt discovered during analysis → Technical Debt Assessment
└─ No immediate development work → Framework adoption complete, use normal workflow
```

**Preparation for Next Task:**

1. Review Feature Tracking for features requiring further work
2. Consult retrospective documentation for design decisions and patterns
3. Use the normal development workflow (Feature Discovery → Tier Assessment → Design → Implementation)
4. Technical debt items identified during onboarding can be addressed via Technical Debt Assessment

### Transitioning FROM Project Initiation (PF-TSK-059)

**Prerequisites for Transition:**

- [ ] `project-config.json` created at `doc/project-config.json` with project identification, directory mappings, and testing configuration
- [ ] Language config file created in `languages-config/{language}/`
- [ ] Test infrastructure scaffolded (directory structure, tracker, registry, fixtures)
- [ ] CI/CD infrastructure set up (if applicable: pre-commit hooks, dev script, pipeline)
- [ ] User Workflow Tracking file created at `doc/state-tracking/permanent/user-workflow-tracking.md`

**Next Task Selection:**

```
What is needed next?
├─ Framework customization needed → Framework Domain Adaptation
├─ Features already known → Feature Request Evaluation or Feature Discovery
├─ Adopting framework into existing codebase → Codebase Feature Discovery
└─ Greenfield project → Begin normal development workflow (Feature Discovery)
```

**Preparation for Next Task:**

1. Verify `project-config.json` is complete and test runner works (`Run-Tests.ps1 -ListCategories`)
2. Confirm test infrastructure directories match project language and conventions
3. Review User Workflow Tracking for initial workflow stubs to guide feature planning

### Transitioning FROM Feature Request Evaluation (PF-TSK-067)

**Prerequisites for Transition:**

- [ ] Change request classified (new feature or enhancement)
- [ ] For enhancements: target feature proposed and human-approved
- [ ] Enhancement State Tracking File created and customized
- [ ] Target feature status set to "🔄 Needs Enhancement" in feature tracking

**Next Task Selection:**

- **If classified as new feature**: → Feature Tier Assessment (existing workflow)
- **If classified as enhancement**: → Feature Enhancement (PF-TSK-068)

**Preparation for Next Task:**

1. Ensure Enhancement State Tracking File is fully customized (no placeholder content)
2. Verify target feature's status shows "🔄 Needs Enhancement" with link to state file
3. Confirm all execution steps have referenced task documentation links

### Transitioning FROM Feature Enhancement (PF-TSK-068)

**Prerequisites for Transition:**

- [ ] All execution steps in Enhancement State Tracking File marked complete
- [ ] All design documentation updates completed as scoped
- [ ] All code changes implemented
- [ ] All test changes implemented
- [ ] Target feature's implementation state file updated
- [ ] Feature tracking status restored (removed "🔄 Needs Enhancement")
- [ ] Enhancement State Tracking File archived to `state-tracking/temporary/old/`

**Next Task Selection:**

- **Standard path**: → Code Review → Release & Deployment
- **If enhancement revealed additional work**: → Feature Request Evaluation (new change request)

**Preparation for Next Task:**

1. Ensure all modified files are committed and ready for review
2. Document any follow-up work discovered during enhancement in feature tracking
3. Verify the archived state file is in `temporary/old/`

### Transitioning FROM Feature Discovery

**Prerequisites for Transition:**

- [ ] New features identified and documented
- [ ] Features added to Feature Tracking with initial priorities
- [ ] Dependencies between features identified
- [ ] Technical debt implications noted

**Next Task Selection:**

- **If features need complexity assessment**: → Feature Tier Assessment
- **If features are well-understood and simple**: → Feature Implementation
- **If exploring technical feasibility**: → Continue with additional discovery cycles

**Preparation for Next Task:**

1. Ensure Feature Tracking is updated with all new features
2. Verify feature descriptions are clear and actionable
3. Confirm initial priorities are assigned
4. Review dependencies for implementation order

### Transitioning FROM Feature Tier Assessment

**Prerequisites for Transition:**

- [ ] Assessment document created with tier assignment
- [ ] Design Requirements Evaluation completed (API Design and DB Design requirements determined)
- [ ] Feature Tracking updated with tier emoji, assessment link, and design requirements ("Yes"/"No")
- [ ] Rationale for tier assignment documented
- [ ] Assessment quality verified

**Next Task Selection Decision Tree:**

```
What tier was assigned?
├─ Tier 1 (🔵) → Check Design Requirements → Feature Implementation
│   └─ Reason: Simple features can be developed with lightweight design
├─ Tier 2 (🟠) → Check Design Requirements → [API Design if "Yes"] → [Database Schema Design if "Yes"] → TDD Creation
│   └─ Reason: Moderate features need targeted design work based on requirements evaluation
└─ Tier 3 (🔴) → System Architecture Review (recommended) → [API Design if "Yes"] → [Database Schema Design if "Yes"] → TDD Creation
    └─ Reason: Complex features benefit from comprehensive architectural planning plus targeted design work
```

**Design Requirements Check:**

- **API Design = "Yes"** → Complete API Design Task before proceeding
- **DB Design = "Yes"** → Complete Database Schema Design Task before proceeding
- Both requirements determined during Feature Tier Assessment's Design Requirements Evaluation

**Optional Task Guidelines:**

- **System Architecture Review**:
  - **✅ Use when**: Feature impacts system architecture, introduces new patterns, requires cross-cutting concerns, needs Foundation Feature (0.x.x), or has architectural implications
  - **❌ Skip when**: Simple UI changes, business logic within existing patterns, no architectural impact
- **API Design**:
  - **✅ Use when**: New API endpoints required, significant API modifications, external integrations, or API contract changes
  - **❌ Skip when**: No API changes, internal-only features, or minor API parameter adjustments
- **Database Schema Design**:
  - **✅ Use when**: Schema changes required, new tables/relationships, data migration needed, or data model changes
  - **❌ Skip when**: No database changes, read-only features, or minor data field additions
- **UI/UX Design**:
  - **✅ Use when**: New visual interfaces, complex user interactions, accessibility requirements, multi-platform designs, or visual consistency concerns
  - **❌ Skip when**: Backend-only features, simple text changes, minor styling adjustments, or using existing UI components as-is

**Preparation for Next Task:**

1. Review assessment rationale to understand complexity factors
2. Identify specific areas that drove the tier assignment
3. Prepare context for design or implementation decisions
4. Check for any dependencies that need to be addressed first

### Transitioning FROM FDD Creation

**Prerequisites for Transition:**

- [ ] FDD document created using New-FDD.ps1 script
- [ ] Functional requirements documented with user perspective
- [ ] User flows and acceptance criteria defined
- [ ] FDD linked in Feature Tracking
- [ ] Human consultation completed for feature behavior

**Next Task Selection:**

```
Does the feature impact system architecture or introduce new patterns?
├─ Yes → System Architecture Review
│   └─ Reason: Architectural analysis needed before technical design
└─ No → Check Design Requirements → [API Design if "Yes"] → [Database Schema Design if "Yes"] → TDD Creation
    └─ Reason: Proceed directly to targeted design work based on requirements evaluation
```

**Preparation for Next Task:**

1. Review functional requirements to understand user needs
2. Ensure user flows are clear and complete
3. Verify acceptance criteria are testable and specific
4. Prepare functional context for technical design decisions

### Transitioning FROM TDD Creation

**Prerequisites for Transition:**

- [ ] TDD document created and reviewed
- [ ] TDD linked in Feature Tracking
- [ ] Design decisions documented and approved
- [ ] Technical approach validated

**Next Task Selection:**

```
What was the original tier assessment?
├─ Tier 2 (🟠) → Feature Implementation → 👀 Needs Review → Code Review
│   └─ Reason: Moderate complexity with lightweight design is sufficient
└─ Tier 3 (🔴) → Test Specification Creation → Feature Implementation → 👀 Needs Review → Code Review
    └─ Reason: Complex features need comprehensive test planning before implementation
```

**When to Use Decomposed Mode:**

- **✅ Use when**:
  - Multi-session implementation expected (feature takes multiple sessions)
  - Complex features with distinct layers (data, state, UI)
  - Context preservation critical between sessions
  - Team collaboration requires clear handoffs
  - Session management and progress tracking important
  - Clear separation of concerns needed

- **❌ Skip when**:
  - Simple features completable in single session
  - Minimal layer separation (e.g., UI-only changes)
  - Single developer working continuously
  - Rapid prototyping or experimental features

**Preparation for Next Task:**

1. Ensure TDD is complete and addresses all complexity factors
2. Verify technical approach is feasible
3. Confirm all design decisions are documented
4. Review any implementation constraints or considerations

### Transitioning TO System Architecture Review

**Prerequisites for Transition:**

- [ ] FDD completed and approved (for Tier 2+ features)
- [ ] Feature Tier Assessment completed with Tier 2+ complexity
- [ ] Feature impacts system architecture or introduces new patterns
- [ ] Architectural decisions need to be made
- [ ] Cross-cutting concerns identified

**Trigger Criteria (Any of the following):**

**🏗️ Architectural Impact Indicators:**

- New component types being introduced
- Changes to existing component relationships
- Modifications to system boundaries or interfaces
- Introduction of new architectural patterns

**🔗 Integration Complexity:**

- External system integrations required
- New API contracts or significant API modifications
- Database schema changes affecting multiple features
- Cross-cutting concerns spanning multiple components

**⚡ Performance & Scalability:**

- Performance requirements that may impact architecture
- Scalability concerns requiring architectural decisions
- Resource management or caching strategy changes

**🔒 Security Architecture:**

- Security architecture implications
- Authentication or authorization pattern changes
- Data privacy or compliance requirements affecting architecture

**🎯 Foundation Feature Indicators:**

- Feature requires new architectural foundations (0.x.x)
- Cross-cutting functionality needed by multiple features
- Architectural patterns that will be reused

**Decision Matrix:**
| Scenario | Trigger System Architecture Review? | Reason |
|----------|-----------------------------------|---------|
| Simple UI changes | ❌ No | No architectural impact |
| New business logic in existing patterns | ❌ No | Follows established architecture |
| New external API integration | ✅ Yes | Integration patterns and error handling |
| New component type (e.g., background service) | ✅ Yes | Architectural pattern establishment |
| Database schema changes | ✅ Yes | Data architecture impact assessment |
| Performance optimization requiring caching | ✅ Yes | Caching strategy architectural decisions |
| Security feature affecting multiple components | ✅ Yes | Security architecture implications |

**Preparation for System Architecture Review:**

1. **Load Current Architecture State**: Review [Architecture Tracking](../../doc/state-tracking/permanent/architecture-tracking.md)
2. **Gather Feature Context**: Ensure FDD and Feature Tier Assessment are complete
3. **Identify Relevant Context Packages**: Determine which architectural context areas apply to this feature
4. **Review Related ADRs**: Check existing [Architecture Decision Records](../../doc/technical/adr)
5. **Prepare Impact Analysis Framework**: Set up structured approach for architectural evaluation

### Transitioning FROM System Architecture Review

**Prerequisites for Transition:**

- [ ] Architecture impact assessment completed
- [ ] Architectural decisions documented
- [ ] System constraints and patterns identified
- [ ] Architecture Impact Assessment document linked in Arch Review column

**Next Task Selection:**

**Foundation Feature Decision Tree:**

```
Does feature require new architectural work?
├─ Yes → Is architecture work cross-cutting (affects multiple features)?
│  ├─ Yes → Create Foundation Feature (0.x.x) for architectural work
│  │       → Update/Create Architecture Context Package
│  │       → Update Architecture Tracking
│  │       → Foundation Feature Implementation
│  └─ No → Include architectural work in feature TDD
│          → Does the feature require new or modified API endpoints?
│          ├─ Yes → API Design → TDD Creation
│          └─ No → TDD Creation
└─ No → Continue to existing workflow
        → Does the feature require new or modified API endpoints?
        ├─ Yes → API Design → TDD Creation
        └─ No → TDD Creation
```

**Decision Criteria for Foundation Features:**

**✅ Create Foundation Feature (0.x.x) when:**

- Architectural work affects multiple current or future features
- New architectural patterns need to be established
- Cross-cutting concerns require dedicated implementation
- Architectural foundations are missing for feature implementation
- System-wide changes to existing architectural patterns

**❌ Include in Feature TDD when:**

- Architectural work is specific to this feature only
- Minor architectural adjustments within existing patterns
- Feature-specific implementation details
- No cross-cutting impact expected

**Preparation for Next Task:**

1. **For Foundation Features**: Load Architecture Context Package for focused architectural work
2. **Review Architectural Framework Usage Guide**: [Architectural Framework Usage Guide](../guides/01-planning/architectural-framework-usage-guide.md) for step-by-step instructions
3. Review architectural decisions that impact design
4. Identify system patterns and constraints to follow
5. Understand integration points with existing architecture
6. Prepare architectural context for design decisions

### Transitioning FROM Foundation Feature Implementation

**Prerequisites for Transition:**

- [ ] Foundation feature implementation completed
- [ ] Architecture Context Package updated with implementation results
- [ ] Architecture Tracking updated with session progress
- [ ] ADRs created for architectural decisions made
- [ ] Foundation feature marked complete in Feature Tracking

**Next Task Selection:**

```
Are there dependent regular features ready for implementation?
├─ Yes → Feature Implementation (for dependent features)
│   └─ Reason: Foundation enables dependent feature development
└─ No → Continue with next foundation feature or architectural work
    └─ Reason: Complete architectural foundation before regular features
```

**Preparation for Next Task:**

1. **Update Architecture Context Package**: Reflect implementation progress and next priorities
2. **Update Architecture Tracking**: Document session outcomes and handover information
3. **Create/Update ADRs**: Document architectural decisions made during implementation
4. **Validate Foundation**: Ensure foundation feature works as expected before dependent features
5. **Prepare Context for Next Agent**: Ensure clear handover documentation for architectural continuity

### Transitioning FROM API Design

**Prerequisites for Transition:**

- [ ] API specification documents created
- [ ] Data models defined for all request/response objects
- [ ] API documentation created for consumers
- [ ] API design linked in Feature Tracking

**Next Task Selection:**

```
Does the feature require database schema changes?
├─ Yes → Database Schema Design
│   └─ Reason: Schema should be designed before technical implementation
└─ No → TDD Creation
    └─ Reason: Proceed directly to technical design with API contracts
```

**Preparation for Next Task:**

1. Review API specifications to understand interface requirements
2. Ensure data models align with feature requirements
3. Verify API design follows project patterns and standards
4. Prepare API context for design decisions

### Transitioning FROM Database Schema Design

**Prerequisites for Transition:**

- [ ] Database schema design document created
- [ ] Schema changes documented with migration plan
- [ ] Data integrity constraints defined
- [ ] Schema design linked in Feature Tracking

**Next Task Selection:**

- **Always**: → TDD Creation (schema design informs technical implementation)

**Preparation for Next Task:**

1. Review schema design to understand data model requirements
2. Ensure schema changes align with feature requirements
3. Verify migration plan is feasible and safe
4. Prepare database context for technical design decisions

### Transitioning FROM Integration Narrative Creation (PF-TSK-083)

**Prerequisites for Transition:**

- [ ] Integration Narrative created via New-IntegrationNarrative.ps1
- [ ] All cross-feature interactions verified against source code
- [ ] Data flow, callback chains, and error propagation paths documented
- [ ] user-workflow-tracking.md updated with Integration Doc link

**Next Task Selection:**

```
Is a cross-cutting E2E test specification needed for this workflow?
├─ Yes (all workflow features implemented + E2E milestone exists) →
│   Cross-cutting E2E Test Specification (New-TestSpecification.ps1 -CrossCutting)
│   → then E2E Test Case Creation (PF-TSK-069) → Test Audit → E2E Execution
│   └─ Reason: Integration Narrative provides verified cross-feature understanding for E2E tests
├─ No (workflow not yet E2E-ready) → Continue with other work
│   └─ Reason: Remaining workflow features must reach Implemented status first
└─ Documentation validation round active? → Documentation Alignment Validation
    └─ Reason: Integration Narratives are validated as part of documentation accuracy checks
```

**Preparation for Next Task:**

1. Review narrative for complete coverage of cross-feature touchpoints
2. Confirm all participating features are listed in user-workflow-tracking.md
3. Verify the workflow's E2E readiness status in e2e-test-tracking.md
4. Ensure narrative includes sufficient detail for E2E test case design (data formats, expected states, error scenarios)

### Transitioning FROM Test Specification Creation

**Prerequisites for Transition:**

- [ ] Test specification document created
- [ ] Test cases cover all TDD requirements
- [ ] Test specification linked in tracking files
- [ ] Test approach validated

**Next Task Selection:**

```
Is test-first development approach being used?
├─ Yes → Integration & Testing
│   └─ Reason: Implement tests before feature development for TDD approach
└─ No → Feature Implementation
    └─ Reason: Proceed directly to feature implementation with test specifications as reference
```

**Preparation for Next Task:**

1. Review test specification to understand testing requirements
2. Ensure test cases align with TDD design
3. Verify test data and environment requirements
4. Confirm testing approach is feasible

### Transitioning FROM Integration & Testing

**Prerequisites for Transition:**

- [ ] Test cases implemented according to test specifications
- [ ] Test implementation status updated to "🔄 Needs Audit"
- [ ] Test tracking files updated with test file links and status
- [ ] Test environment and data setup complete

**Next Task Selection:**

```
Is systematic test quality assessment needed?
├─ Yes → Test Audit → Feature Implementation → 👀 Needs Review → Code Review
│   └─ Reason: Quality gate to ensure test implementation meets standards
└─ No → Feature Implementation → 👀 Needs Review → Code Review
    └─ Reason: Proceed directly to feature implementation (for simple tests or when quality is assured)
```

**Preparation for Next Task:**

1. **For Test Audit**: Ensure test files are accessible and specifications are available
2. **For Feature Implementation**: Review implemented test cases to understand expected behavior
3. Ensure test environment is properly configured
4. Verify test data and fixtures are available

### Transitioning FROM Test Audit (PF-TSK-030)

**Prerequisites for Transition:**

- [ ] Test audit report completed with type-appropriate criteria assessed (6 Automated / 4 Performance / 5 E2E)
- [ ] Audit decision made (Audit Approved or Needs Update)
- [ ] Type-specific tracking file updated with audit results (test-tracking.md, performance-test-tracking.md, or e2e-test-tracking.md)
- [ ] Audit report validated using Validate-AuditReport.ps1

**Next Task Selection (by test type):**

```
What test type was audited?
├─ Automated → 3-outcome decision tree:
│  ├─ ✅ Audit Approved → Feature Implementation → 👀 Needs Review → Code Review
│  ├─ 🔄 Needs Update → Integration & Testing (fix issues)
│  └─ 🔴 Tests Incomplete → Integration & Testing (add missing tests)
│
├─ Performance → Was audit approved?
│  ├─ ✅ Audit Approved → Performance Baseline Capture (PF-TSK-085)
│  │   └─ Reason: Tests meet quality criteria, ready for baseline measurement
│  └─ 🔄 Needs Update → Performance Test Creation (fix issues, re-audit)
│
└─ E2E → Was audit approved?
   ├─ ✅ Audit Approved → E2E Acceptance Test Execution (PF-TSK-070)
   │   └─ Reason: Test cases meet quality criteria, ready for execution
   └─ 🔄 Needs Update → E2E Test Case Creation (fix issues, re-audit)
```

**Preparation for Next Task:**

1. **For Feature Implementation** (Automated): Review audit findings for any implementation considerations
2. **For Integration & Testing** (Automated): Review audit recommendations and action items
3. **For Performance Baseline Capture** (Performance): Verify Audit Status shows `✅ Audit Approved` in performance-test-tracking.md
4. **For E2E Test Execution** (E2E): Verify Audit Status shows `✅ Audit Approved` in e2e-test-tracking.md
5. Update type-specific tracking file with appropriate status
6. Ensure audit findings are addressed before proceeding

### Transitioning FROM E2E Acceptance Test Case Creation (PF-TSK-069)

**Prerequisites for Transition:**

- [ ] Test case directories created in `test/e2e-acceptance-testing/templates/<group>/E2E-NNN-<name>/`
- [ ] Each test case contains: `test-case.md`, `project/`, `expected/`, and `run.ps1` (for scripted tests)
- [ ] Master test file updated at `test/e2e-acceptance-testing/templates/<group>/master-test-<group-name>.md`
- [ ] E2E test tracking (`e2e-test-tracking.md`) updated with new test cases
- [ ] Feature tracking updated with E2E test references

**Next Task Selection:**

```
What is the context?
├─ Test cases ready → Test Audit (PF-TSK-030, -TestType E2E) → ✅ Audit Approved → E2E Test Execution (PF-TSK-070)
│   └─ Reason: Newly created test cases must be audited before execution
├─ Test case creation revealed additional bugs → Bug Triage (PF-TSK-041)
└─ More test cases needed for other groups → Continue E2E Test Case Creation (next group)
```

**Preparation for Next Task:**

1. Verify all test case `project/` and `expected/` directories contain correct fixtures
2. Confirm master test file lists all test cases in the group
3. Review `e2e-test-tracking.md` for groups ready for audit

### Transitioning FROM E2E Acceptance Test Execution (PF-TSK-070)

**Prerequisites for Transition:**

- [ ] All target test groups executed (or blocked with documented reasons)
- [ ] `e2e-test-tracking.md` updated with execution status and Last Executed dates
- [ ] `feature-tracking.md` updated with Test Status based on results
- [ ] Bug reports created (via `New-BugReport.ps1`) for any failures discovered

**Next Task Selection:**

```
What were the results?
├─ All tests passed → Release & Deployment (if release-ready)
│   └─ Or return to development work
├─ Failures found → Bug Triage (PF-TSK-041) for each failure
├─ Missing coverage discovered → E2E Test Case Creation (PF-TSK-069) for new cases
└─ Test cases need updates (stale expectations) → E2E Test Case Creation (update existing)
```

**Preparation for Next Task:**

1. Review bug reports for severity and priority assignment
2. Check if failures block the release or can be addressed in parallel
3. Update User Workflow Tracking if workflow-level pass/fail status changed

### Transitioning FROM Needs Review

**Prerequisites for Transition:**

- [ ] Feature implementation is complete and functional
- [ ] All tests pass (unit, component, integration as applicable)
- [ ] Feature meets all acceptance criteria
- [ ] Code follows project standards and conventions
- [ ] Feature status updated to "👀 Needs Review" in Feature Tracking
- [ ] All documentation is up-to-date

**Next Task Selection:**

```
Needs Review → Code Review → [Conditional Branching]
├─ Review Passed → Completed (🟢)
│   └─ Reason: Feature meets all quality standards and requirements
└─ Issues Found → Needs Enhancement (🔄) → Bug Fixing → 👀 Needs Review
    └─ Reason: Issues must be addressed before feature can be completed
```

**Preparation for Next Task:**

1. **For Code Review**: Ensure all code is committed and accessible for review
2. **For Code Review**: Prepare context about implementation decisions and trade-offs
3. Update Feature Tracking with review request and reviewer assignment
5. Ensure all related documentation is current and linked

### Transitioning FROM Implementation Tasks

**Prerequisites for Transition:**

- [ ] Implementation complete according to design/requirements
- [ ] Unit tests written and passing
- [ ] Documentation updated
- [ ] Feature Tracking updated with implementation status

**Next Task Selection:**

- **Always**: → Code Review

**Preparation for Next Task:**

1. Prepare code for review (clean commits, clear comments)
2. Document any deviations from original design
3. Ensure all tests are passing
4. Prepare summary of implementation approach

### Transitioning FROM Code Review

**Prerequisites for Transition:**

- [ ] Code review completed
- [ ] Review findings documented
- [ ] Tracking files updated with review status

**Next Task Selection Decision:**

```
What was the review result?
├─ Approved with no issues → Performance & E2E Test Scoping (PF-TSK-086)
│  (Feature status set to 🔎 Needs Test Scoping)
├─ Minor issues identified → Bug Fixing → Code Review (repeat)
├─ Major issues identified → Bug Fixing → Code Review (repeat)
└─ Code quality issues identified → Code Refactoring → Code Review (repeat)
```

**Preparation for Next Task:**

1. Feature status updated to `🔎 Needs Test Scoping` (for passed reviews)
2. All review findings documented and routed (bugs, tech debt, implementation gaps)
3. Test tracking updated with review results

### Transitioning FROM Performance & E2E Test Scoping (PF-TSK-086)

**Prerequisites for Transition:**

- [ ] Performance decision matrix applied against feature's code changes
- [ ] E2E milestone readiness evaluated for all relevant workflows
- [ ] Any untracked cross-feature interactions added to user-workflow-tracking.md
- [ ] User Documentation status checked in feature state file (Step 13)
- [ ] Feature status updated to `📖 Needs User Docs` or `🟢 Completed` (based on User Documentation status)

**Next Task Selection Decision:**

```
What did the scoping task identify?
├─ Performance tests needed → Performance Test Creation (PF-TSK-084) → Test Audit (-TestType Performance) → Baseline Capture
├─ Workflow now E2E-ready → E2E Test Case Creation (PF-TSK-069) → Test Audit (-TestType E2E) → E2E Execution
│  (preceded by Integration Narrative Creation if none exists)
├─ Both perf + E2E needed → Performance Test Creation first, then E2E (each with audit gate)
├─ Neither needed → Check feature state file ### User Documentation status:
│  ├─ ❌ Needed → Feature set to 📖 Needs User Docs → User Documentation Creation (PF-TSK-081)
│  └─ N/A or ✅ Created → Feature set to 🟢 Completed → Release & Deployment
└─ Tests already exist for identified needs → Check user documentation status (same as above)
```

**Preparation for Next Task:**

1. Performance test entries at `⬜ Needs Creation` in performance-test-tracking.md (if applicable)
2. E2E milestone entry added to e2e-test-tracking.md (if applicable)
3. Rationale documented for all "no tests needed" decisions
4. Feature status set to `📖 Needs User Docs` if user documentation needed (for PF-TSK-081 pickup)

### Transitioning FROM Performance Test Creation (PF-TSK-084)

**Prerequisites for Transition:**

- [ ] Performance tests implemented with required pytest markers
- [ ] performance-test-tracking.md updated: `⬜ Needs Creation → 📋 Needs Baseline` with Test File links
- [ ] All new tests pass when run

**Next Task Selection:**

```
Tests created?
├─ Yes → Test Audit (PF-TSK-030, -TestType Performance)
│   └─ Reason: Audit gate is mandatory before baseline capture
└─ Issues found during creation → Fix tests → Re-run
```

**Preparation for Next Task:**

1. Verify all new test entries show `📋 Needs Baseline` in performance-test-tracking.md
2. Ensure test files are committed and accessible for audit review

### Transitioning FROM Performance Baseline Capture (PF-TSK-085)

**Prerequisites for Transition:**

- [ ] All targeted tests run successfully
- [ ] Results recorded in performance-results.db
- [ ] performance-test-tracking.md updated with results and status
- [ ] Regression check completed

**Next Task Selection:**

```
What were the results?
├─ No regressions → Release & Deployment (if release-ready)
├─ Tolerance breach → Bug Triage (PF-TSK-041)
└─ Trend degradation → Technical Debt Assessment (or file debt item directly)
```

**Preparation for Next Task:**

1. Verify Summary table recalculated in performance-test-tracking.md
2. Review trend data for key tests

### Transitioning FROM User Documentation Creation (PF-TSK-081)

**Prerequisites for Transition:**

- [ ] Handbook(s) created or updated via New-Handbook.ps1
- [ ] Content customized and reviewed by human partner
- [ ] Feature state file `### User Documentation` updated to `✅ Created` via Update-UserDocumentationState.ps1
- [ ] Feature status set from `📖 Needs User Docs` to `🟢 Completed` via Update-BatchFeatureStatus.ps1
- [ ] README.md updated if applicable

**Next Task Selection Decision:**

```
Documentation complete?
├─ Yes → Feature set to 🟢 Completed → Release & Deployment
└─ Needs revision → Revise handbook content → Re-review
```

**Preparation for Next Task:**

1. Verify all user-facing behavior changes are documented
2. Feature status is `🟢 Completed` in feature-tracking.md
2. Ensure handbook is linked from README.md documentation table if appropriate
3. Proceed to Release & Deployment

### Transitioning FROM Release & Deployment (PF-TSK-008)

**Prerequisites for Transition:**

- [ ] Release notes created (version, features, bug fixes, known issues)
- [ ] All E2E test groups passed (verified in `e2e-test-tracking.md`)
- [ ] Feature tracking updated with release version for included features
- [ ] Bug reports created for any issues discovered during deployment validation

**Next Task Selection:**

```
What happened during deployment?
├─ Deployment successful, no issues → Begin next development cycle
│   ├─ Features planned → Feature Request Evaluation or Feature Discovery
│   └─ Tech debt to address → Technical Debt Assessment
├─ Issues discovered during deployment → Bug Triage (PF-TSK-041)
└─ Post-release monitoring reveals problems → Bug Triage (PF-TSK-041)
```

**Preparation for Next Task:**

1. Archive or close completed feature state files if appropriate
2. Review Feature Request Tracking for the next batch of work
3. Update Technical Debt Tracking with any debt introduced during the release

### Transitioning FROM Git Commit and Push (PF-TSK-082)

**Prerequisites for Transition:**

- [ ] All working directory changes staged and committed
- [ ] Commit pushed successfully to remote repository
- [ ] No sensitive files included in commit

**Next Task Selection:**

```
Push completed successfully
├─ Continuing current work → Return to active task
├─ Session ending → No follow-up needed
└─ Starting new work → Select appropriate task from ai-tasks.md
```

**Preparation for Next Task:**

1. Verify the push was successful (commit hash confirmed on remote)
2. Continue with the next task or end the session

### Transitioning FROM Code Refactoring

**Prerequisites for Transition:**

- [ ] **Refactoring Implementation Complete**: All planned refactoring work executed
- [ ] **3-Phase State Updates Complete**: All state files updated according to comprehensive checklist
  - [ ] Phase 1: Temporary state tracking, bug tracking, technical debt progress documented
  - [ ] Phase 2: Technical debt resolved, feature status improved, architecture tracking updated
  - [ ] Phase 3: Temporary state archived, context packages updated
- [ ] **Bug Discovery Complete**: Systematic bug identification performed with 4-tier decision matrix
- [ ] **ADRs Created**: Architecture Decision Records created for architectural refactoring (via New-ArchitectureDecision.ps1)
- [ ] **Quality Validation**: All tests still passing after refactoring
- [ ] **Documentation Updated**: Refactoring plan completed with results and lessons learned

**Next Task Selection:**

```
What was the refactoring outcome?
├─ Feature status improved to "👀 Needs Review" → Code Review
│   └─ Reason: Refactored features need testing and quality verification
├─ Bugs discovered during refactoring → Bug Triage → Bug Fixing
│   └─ Reason: Address bugs found during refactoring process
├─ Architectural changes made → Code Review (focus on architecture)
│   └─ Reason: Architectural refactoring needs specialized review
└─ Technical debt resolved → Continue Development → Code Review
    └─ Reason: Improved codebase ready for continued development
```

**Preparation for Next Task:**

1. **For Testing/Code Review**: Prepare summary of refactoring changes and architectural improvements
2. **For Bug Triage**: Ensure all discovered bugs are properly documented with refactoring context
3. **For Continued Development**: Update development context with improved codebase state
4. **Always**: Verify external behavior remains unchanged and all tests are passing

### Transitioning FROM Documentation Tier Adjustment

**Prerequisites for Transition:**

- [ ] Tier adjustment assessment completed
- [ ] New tier assigned and documented
- [ ] Feature Tracking updated with new tier
- [ ] Rationale for tier change documented

**Next Task Selection:**

```
What is the new tier assignment?
├─ Tier increased (more complex) → Add required documentation tasks
│   └─ Example: Tier 1→2 may require TDD Creation
├─ Tier decreased (less complex) → Remove unnecessary documentation
│   └─ Example: Tier 3→2 may skip Test Specification Creation
└─ Tier unchanged → Continue with current task
```

**Preparation for Next Task:**

1. Review new tier requirements and adjust task sequence
2. Update project timeline based on tier change
3. Communicate tier change to stakeholders
4. Prepare context for adjusted documentation requirements

### Transitioning FROM Technical Debt Assessment

**Prerequisites for Transition:**

- [ ] Technical debt assessment completed
- [ ] Debt items prioritized and documented
- [ ] Technical Debt Tracking updated
- [ ] Refactoring recommendations made

**Next Task Selection:**

```
What was the assessment result?
├─ High priority debt identified → Code Refactoring
│   └─ Reason: Address critical technical debt immediately
├─ Medium priority debt identified → Schedule Code Refactoring
│   └─ Reason: Plan refactoring for appropriate time
└─ Low priority debt identified → Continue current development
    └─ Reason: Technical debt can be addressed later
```

**Preparation for Next Task:**

1. **Prioritize Refactoring Scope**: Select technical debt items by impact and effort
2. **Prepare Refactoring Context**: Gather target code area, quality issues, and test coverage information
3. **Plan Comprehensive Workflow**: Prepare for temporary state tracking, bug discovery, and potential ADR creation
4. **Update Technical Debt Tracking**: Mark selected items as "🔄 In Progress" before starting refactoring
5. **Prepare Decision Matrix**: Review 4-tier bug severity decision process for systematic bug discovery

### Transitioning FROM Support Tasks

#### FROM Process Improvement

**Prerequisites for Transition:**

- [ ] Process improvement analysis completed
- [ ] Improvement recommendations documented
- [ ] Process changes implemented or planned
- [ ] Impact assessment completed

**Next Task Selection:**

```
What type of improvement was made?
├─ Workflow changes → Return to development with new process
├─ Documentation structure changes → Structure Change
└─ Tool improvements needed → Tools Review
```

#### FROM Structure Change

**Prerequisites for Transition:**

- [ ] Structure change plan executed
- [ ] Files moved/reorganized as planned
- [ ] All links and references updated
- [ ] Structure change documented

**Next Task Selection:**

- **Always**: → Return to interrupted development work or continue with planned tasks

#### FROM Tools Review

**Prerequisites for Transition:**

- [ ] Tool evaluation completed
- [ ] Tool improvements implemented
- [ ] Tool documentation updated
- [ ] Tool effectiveness measured

**Next Task Selection:**

- **Always**: → Return to development work with improved tools

#### FROM New Task Creation Process

**Prerequisites for Transition:**

- [ ] New task definition created
- [ ] Task integrated into framework
- [ ] Task documentation completed
- [ ] Task transition patterns defined

**Next Task Selection:**

- **Always**: → Update Task Transition Guide (this document) to include new task

#### FROM Framework Evaluation

**Prerequisites for Transition:**

- [ ] Evaluation scope defined and approved
- [ ] All selected dimensions evaluated with scores and evidence
- [ ] Evaluation report created via New-FrameworkEvaluationReport.ps1
- [ ] IMP entries registered for actionable findings

**Next Task Selection:**

- **Improvements needed**: → Process Improvement (to address IMP entries from evaluation)
- **Structural issues found**: → Structure Change (for reorganization needs)
- **Missing tasks identified**: → New Task Creation Process (to fill gaps)
- **No major issues**: → Return to development work

#### FROM Framework Extension Task

**Prerequisites for Transition:**

- [ ] Framework Extension Concept Document created and approved
- [ ] Impact analysis documented
- [ ] **Pilot vs. Full Rollout decision made at Step 4.5** (PF-PRO-030); if pilot, adopters / success criteria / decision trigger defined
- [ ] New task definitions created and integrated into `ai-tasks.md`
- [ ] Supporting infrastructure created (templates, guides, scripts, directories)
- [ ] Core framework files updated (`ai-tasks.md`, `PF-documentation-map.md`, PF ID Registry)
- [ ] Temporary state tracking file completed (all phases done)
- [ ] **If pilot was chosen**: pilot row exists in [Active Pilots](../../process-framework-local/state-tracking/permanent/process-improvement-tracking.md#active-pilots) with status `Active`; concept doc remains in `proposals/` (archive deferred until pilot resolves)

**Next Task Selection:**

- **Further refinements needed**: → Process Improvement (for polish and adjustments)
- **New tasks ready to use**: → Execute the newly created extension-specific tasks
- **Documentation updates needed**: → Structure Change (if reorganization required)
- **Pilot was chosen — eventual rollout/rollback decision**: → Process Improvement (later session) processes the decision-trigger IMP filed at Phase 4. On resolution: `Update-ProcessImprovement.ps1 -ImprovementId <pilot PF-IMP-NNN> -NewStatus Resolved -Impact <HIGH|MEDIUM|LOW> -ValidationNotes "<decision summary>"` records the disposition, automatically archives the concept doc to `proposals/old/`, and moves the pilot row from Active Pilots to Completed Improvements (PF-IMP-729). The originally-deferred archive is owned by this later session, not the original Framework Extension Task session.

### Transitioning FROM Bug Discovery

**Prerequisites for Transition:**

- [ ] Systematic bug discovery performed using task-specific categories
- [ ] Bug evidence collected (error messages, code references, reproduction steps)
- [ ] Bug impact assessed (user experience, system stability, security)
- [ ] Discovery context documented (which task revealed the bug)

**Next Task Selection:**

- **Always**: → Bug Reporting (using New-BugReport.ps1 script)

**Preparation for Next Task:**

1. Gather all bug evidence and reproduction steps
2. Determine appropriate severity level based on impact
3. Identify affected system component or feature area
4. Prepare clear, descriptive bug title and description
5. Document the discovery context and task that revealed the bug

### Transitioning FROM Bug Reporting

**Prerequisites for Transition:**

- [ ] Bug report created using New-BugReport.ps1 script
- [ ] Bug entry added to Bug Tracking with status 🆕 Needs Triage
- [ ] All required bug report elements completed (title, description, severity, component, environment, evidence)
- [ ] Bug report linked to discovery context

**Next Task Selection:**

- **Always**: → Bug Triage

**Preparation for Next Task:**

1. Ensure bug report is complete and accessible
2. Verify bug tracking entry is properly formatted
3. Prepare any additional context needed for triage assessment
4. Confirm bug reproduction steps are clear and actionable

### Transitioning FROM Bug Triage

**Prerequisites for Transition:**

- [ ] Bug impact assessment completed
- [ ] Priority level assigned (Critical 🔴, High 🟠, Medium 🟡, Low 🟢)
- [ ] Resource assignment determined
- [ ] Bug status updated to 🔍 Needs Fix
- [ ] Scheduling decision made based on priority

**Next Task Selection Decision:**

```
What priority was assigned?
├─ 🔴 Critical → Immediate Bug Fixing (within 24 hours)
│   └─ Reason: Critical bugs require immediate attention
├─ 🟠 High → Scheduled Bug Fixing (within 1 week)
│   └─ Reason: High priority bugs need prompt resolution
├─ 🟡 Medium → Backlog Assignment → Planned Bug Fixing
│   └─ Reason: Medium priority bugs can be scheduled with regular development
└─ 🟢 Low → Future Backlog → Bug Fixing when resources available
    └─ Reason: Low priority bugs addressed during maintenance cycles
```

**Preparation for Next Task:**

1. **For Critical/High Priority**: Clear immediate schedule for bug fixing work
2. **For Medium/Low Priority**: Add to appropriate backlog with timeline estimates
3. Ensure assigned developer has access to bug report and reproduction steps
4. Prepare development environment for bug investigation and fixing
5. Update Bug Tracking with assignment and timeline information

### Transitioning FROM Bug Fixing

**Prerequisites for Transition:**

- [ ] Bug fix implemented according to root cause analysis
- [ ] Unit tests added or updated to prevent regression
- [ ] Bug reproduction steps no longer trigger the issue
- [ ] Bug status updated to 👀 Needs Review
- [ ] Fix implementation documented

**Next Task Selection:**

```
What scope is the bug?
├─ S-scope quick path → Bug already closed (🔒 Closed at checkpoint) → No transition needed
│   └─ Optionally: Release & Deployment (if release-ready)
├─ M/L-scope → Code Review (PF-TSK-005)
│   └─ Code Review will close the bug (👀 Needs Review → 🔒 Closed) on approval
└─ L-scope with architectural changes (AI self-assessment) → Code Review → then PF-TSK-086 (Test Scoping)
```

**Preparation for Next Task:**

1. Ensure all tests pass including new regression tests
2. Verify bug fix doesn't introduce new issues
3. Prepare summary of fix implementation approach
4. Document any design or architectural changes made
5. Update Bug Tracking with fix details (status at 👀 Needs Review for M/L-scope)

### Transitioning FROM Code Review (Bug Fix Reviews)

**Prerequisites for Transition:**

- [ ] Code review completed for the bug fix
- [ ] Bug status transitioned by Code Review: 👀 Needs Review → 🔒 Closed (approval) or → 🟡 In Progress (rejection)

**Next Task Selection Decision:**

```
What was the review result?
├─ Approved → Bug Status: 🔒 Closed → Release & Deployment (if release-ready)
├─ Approved + L-scope architectural → Bug routes to PF-TSK-086 (🔎 Needs Test Scoping)
├─ Issues found → Bug Status: 🟡 In Progress → Bug Fixing (repeat cycle)
└─ New issues discovered → New Bug Reports → Bug Triage → Bug Fixing
```

**Preparation for Next Task:**

1. **For Approved Fixes**: Bug Tracking updated to 🔒 Closed by Code Review
2. **For Rejected Fixes**: Document review findings and route back to Bug Fixing
3. **For New Issues**: Create new bug reports for any issues discovered during review
4. Update all relevant tracking files with final bug resolution status

## Transition Failure Recovery

### When Transitions Fail

**Common Failure Points:**

1. **Incomplete Prerequisites**: Previous task outputs not complete
2. **Missing Context**: Information needed for next task not available
3. **Resource Constraints**: Next task cannot be started immediately
4. **Scope Changes**: Requirements change during transition

**Recovery Procedures:**

1. **Assess the Gap**: Identify what's missing for successful transition
2. **Complete Prerequisites**: Return to previous task if needed
3. **Update Planning**: Adjust timeline and resource allocation
4. **Document Changes**: Update tracking files with new status

### Rollback Procedures

**When to Rollback:**

- Critical errors discovered in previous task outputs
- Requirements change significantly
- Technical approach proves infeasible

**Rollback Steps:**

1. **Document the Issue**: Record why rollback is needed
2. **Update State Files**: Revert status in tracking documents
3. **Preserve Learning**: Document lessons learned
4. **Plan Re-execution**: Determine how to address the issues

## Best Practices

### Planning Transitions

- **Review Prerequisites**: Always check completion criteria before transitioning
- **Prepare Context**: Gather all information needed for the next task
- **Communicate Changes**: Update all relevant tracking files
- **Plan Resources**: Ensure availability for the next task

### Managing Dependencies

- **Check Blockers**: Verify no dependencies prevent starting the next task
- **Coordinate Timing**: Align transitions with team availability
- **Update Tracking**: Keep all stakeholders informed of progress

### Quality Gates

- **Verify Outputs**: Ensure all required outputs are complete and quality
- **Review Decisions**: Confirm all decisions are documented and sound
- **Test Readiness**: Validate that next task can be started successfully

## Troubleshooting Common Issues

### Issue: Unclear Which Task to Use Next

**Solution**: Use the decision trees in this guide and consult the task selection guide in process-framework/ai-tasks.md

**Common ambiguous cases:**

| Situation | Correct Task | Why |
|-----------|-------------|-----|
| Tech debt items already assessed and tracked | Code Refactoring (PF-TSK-022) | Assessment is done — execute the fix |
| Tech debt not yet identified or categorized | Technical Debt Assessment (cyclical) | Identification must happen before fixing |
| Test-category debt items (e.g., missing coverage, weak assertions) | Code Refactoring (PF-TSK-022) with test focus | Test code is code — refactoring task covers test improvements. Reference the relevant test specification for scope |
| Enhancement to existing feature | Feature Enhancement (PF-TSK-068) | Routed by Feature Request Evaluation; do not use Feature Implementation for amendments |
| Bug discovered during another task | Bug Triage (PF-TSK-041) first | Even obvious bugs need triage for priority assignment before fixing |

### Issue: Prerequisites Not Met

**Solution**: Return to previous task and complete missing outputs before transitioning

### Issue: Multiple Valid Next Tasks

**Solution**: Consider project priorities, resource availability, and dependencies to choose the most appropriate path

### Issue: Transition Blocked by External Dependencies

**Solution**: Document the blocker, update tracking files, and consider alternative approaches or parallel work

---

_This guide is part of the Process Framework and provides essential guidance for navigating between tasks effectively._
