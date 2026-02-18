---
id: PF-GDE-018
type: Process Framework
category: Guide
version: 1.8
created: 2025-07-13
updated: 2026-02-17
change_notes: "v1.8 - Added Onboarding Workflow (PF-TSK-064/065/066) transitions for framework adoption into existing projects"
---

# Task Transition Guide

This guide provides clear guidance on when and how to transition between related tasks in the development workflow, filling a critical process gap in the framework. Updated to include all current tasks including Database Schema Design, Test Implementation, Test Audit, ADR Creation, Code Refactoring, Support Tasks, and Onboarding Tasks. Includes the new "Ready for Review" status in the feature development workflow.

## Overview

The process framework includes multiple interconnected tasks. This guide helps you understand:

- When to transition from one task to another
- What outputs are required before transitioning
- How to prepare for the next task
- Common transition patterns and workflows
- **NEW**: What information flows between tasks and how to avoid duplication

## Information Flow and Separation of Concerns

> **📋 Enhancement**: This section was added as part of IMP-097/IMP-098 to address documentation duplication and clarify task boundaries.

### Purpose

This section establishes clear boundaries between tasks to prevent documentation duplication while ensuring comprehensive coverage. It defines:

- **What information** flows between tasks
- **Who owns** each type of information
- **How to reference** other tasks' outputs
- **When to duplicate** vs. **when to reference**

### Information Flow Model

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Feature Development Information Flow              │
└─────────────────────────────────────────────────────────────────────┘

Feature Discovery
    ↓ [Feature descriptions, priorities, initial requirements]
Feature Tier Assessment
    ↓ [Complexity tier, documentation requirements, UI design needs]
FDD Creation
    ↓ [Functional requirements, user flows, data requirements]
    ├──→ System Architecture Review
    │    ↓ [Architectural decisions, patterns, constraints]
    ├──→ API Design
    │    ↓ [API contracts, endpoints, data access patterns]
    ├──→ Database Schema Design
    │    ↓ [Data model, relationships, constraints, migrations]
    ├──→ UI/UX Design
    │    ↓ [Visual specifications, wireframes, accessibility requirements]
    └──→ TDD Creation
         ↓ [Technical design, implementation approach, components]
         └──→ Test Specification Creation (Tier 3 only)
              ↓ [Test plans, test cases, acceptance criteria]
              └──→ Feature Implementation
                   ↓ [Working code, tests, documentation]
                   └──→ Code Review → Release
```

### Task Responsibility Matrix

This matrix defines **who owns what information** to prevent duplication:

| Information Type              | Primary Owner              | Cross-Reference From                            | Notes                                       |
| ----------------------------- | -------------------------- | ----------------------------------------------- | ------------------------------------------- |
| **Functional Requirements**   | FDD Creation               | All design/implementation tasks                 | What the feature does from user perspective |
| **User Flows & Interactions** | FDD Creation               | API Design, TDD, Test Specification             | How users interact with the feature         |
| **Data Requirements**         | FDD Creation               | Database Schema Design, API Design              | What data is needed (high-level)            |
| **Architectural Decisions**   | System Architecture Review | TDD, Feature Implementation                     | System-level patterns and constraints       |
| **API Contracts & Endpoints** | API Design                 | TDD, Test Specification, Feature Implementation | How services communicate                    |
| **Data Access Patterns**      | API Design                 | Database Schema Design, TDD                     | How data is accessed through APIs           |
| **Data Model & Schema**       | Database Schema Design     | API Design, TDD, Test Specification             | Database structure and relationships        |
| **Database Constraints**      | Database Schema Design     | API Design, Test Specification                  | Database-level validation rules             |
| **RLS Policies**              | Database Schema Design     | API Design, Test Specification                  | Database-level security                     |
| **Migration Scripts**         | Database Schema Design     | Feature Implementation                          | How to deploy schema changes                |
| **Visual Design & UI Specs**  | UI/UX Design               | TDD, Feature Implementation                     | Visual layout, components, accessibility    |
| **Wireframes & User Flows**   | UI/UX Design               | FDD, TDD, Feature Implementation                | Visual representation of interactions       |
| **Technical Design**          | TDD Creation               | Feature Implementation, Test Specification      | How the feature is implemented              |
| **Component Architecture**    | TDD Creation               | Feature Implementation                          | Code structure and organization             |
| **Implementation Details**    | TDD Creation               | Feature Implementation                          | Specific algorithms and approaches          |
| **Test Plans & Cases**        | Test Specification         | Feature Implementation, Test Implementation     | Comprehensive testing strategy              |
| **Acceptance Criteria**       | Test Specification         | Feature Implementation, Code Review             | Definition of done                          |
| **Working Code**              | Feature Implementation     | Code Review, Release                            | Actual implementation                       |

### Cross-Reference Standards

When one task needs to reference another task's outputs, use this standard format:

#### Standard Cross-Reference Format

```markdown
## [Section Name]

> **📋 Primary Documentation**: [Task Name] ([Task ID])
> **🔗 Link**: [Document Name - Document ID] > **👤 Owner**: [Task Name]
>
> **Purpose**: [Brief explanation of why this cross-reference exists and what perspective this task takes]

### [Task-Specific Perspective]

[2-5 sentences providing brief notes from this task's perspective]

**[Structured Subsection 1]**:

- [Brief bullet points specific to this task's concerns]
- [Example: Database-level considerations, API-level concerns, etc.]

**[Structured Subsection 2]**:

- [Additional task-specific considerations]
```

#### Visual Indicators

- **📋** = Primary Documentation (indicates where full details are documented)
- **🔗** = Link (provides navigation to the primary document)
- **👤** = Owner (identifies which task owns this information)
- **⚠️** = Conditional Section (indicates section may not always apply)
- **⏭️** = Not Applicable (indicates section doesn't apply in current context)

#### Examples by Task

**Database Schema Design referencing API Design**:

```markdown
## Integration Impact

> **📋 Primary Documentation**: API Design Task (PF-TSK-020)
> **🔗 Link**: [API Design Document - PD-API-XXX] > **👤 Owner**: API Design Task
>
> **Purpose**: This section provides database-level integration notes. Detailed API specifications are in the API Design document.

### Database-Level Integration Notes

**Schema Access Requirements**:

- User service requires read access to profiles table
- Auth service needs write access to sessions table

**Cross-Schema Dependencies**:

- Foreign key from posts.user_id to users.id
- Shared enum types with auth schema
```

**API Design referencing Database Schema Design**:

```markdown
## Data Model

> **📋 Primary Documentation**: Database Schema Design Task (PF-TSK-021)
> **🔗 Link**: [Schema Design Document - PD-SCH-XXX] > **👤 Owner**: Database Schema Design Task
>
> **Purpose**: This section provides API-level data access patterns. Detailed schema specifications are in the Schema Design document.

### API Data Access Patterns

**Read Operations**:

- GET /users/{id} → Single user lookup by primary key
- GET /users?email={email} → User lookup by unique email index

**Write Operations**:

- POST /users → Insert with email uniqueness validation
- PATCH /users/{id} → Update with optimistic locking
```

**TDD referencing Test Specification**:

```markdown
## Testing Approach

> **📋 Primary Documentation**: Test Specification Creation Task (PF-TSK-012)
> **🔗 Link**: [Test Specification Document - PD-TST-XXX] > **👤 Owner**: Test Specification Creation Task
>
> **Purpose**: This section provides implementation-level testing considerations. Comprehensive test plans are in the Test Specification document.

### Implementation Testing Considerations

**Unit Testing Strategy**:

- Each service method has corresponding unit test
- Mock external dependencies (database, APIs)

**Integration Testing Requirements**:

- Test database transactions with real database
- Validate API contract compliance
```

### Decision Framework: When to Duplicate vs. Reference

Use this framework to decide whether to duplicate information or reference another task:

#### ✅ Duplicate When:

1. **Different Perspective**: The information serves a fundamentally different purpose in each task

   - Example: FDD describes "what data users need" (functional), Schema Design describes "how data is stored" (technical)

2. **Task-Specific Details**: Each task adds unique details not relevant to the other

   - Example: API Design specifies endpoint paths, Schema Design specifies table structures

3. **Standalone Readability**: The document must be understandable without reading other documents

   - Example: Each document should have enough context to understand its scope

4. **Critical Context**: The information is essential for understanding this task's outputs
   - Example: TDD must include enough functional context to understand technical decisions

#### ❌ Reference When:

1. **Detailed Specifications**: Another task owns the detailed specification

   - Example: Schema Design references API Design for detailed endpoint specifications
   - **Action**: Provide 2-5 sentence summary + link to primary document

2. **Implementation Details**: Another task owns the implementation approach

   - Example: API Design references TDD for service implementation details
   - **Action**: Note the dependency + link to primary document

3. **Comprehensive Plans**: Another task owns the comprehensive plan

   - Example: Schema Design references Test Specification for comprehensive test plans
   - **Action**: Provide brief testing considerations + link to primary document

4. **Avoiding Maintenance Burden**: Information that changes frequently and is owned elsewhere
   - Example: Don't duplicate API endpoint lists in multiple documents
   - **Action**: Reference the primary source

#### Decision Tree

```
Does another task own the detailed specification?
├─ YES → Reference with brief summary (2-5 sentences)
└─ NO → Is this information critical for this task?
    ├─ YES → Duplicate with task-specific perspective
    └─ NO → Consider if section is needed at all
```

### Separation of Concerns by Task

This section clarifies what each task **owns** vs. what it **references**:

#### FDD Creation Task (PF-TSK-010)

**✅ This task owns**:

- Functional requirements and user stories
- User flows and interaction patterns
- Business rules and validation logic (functional perspective)
- Data requirements (what data is needed, not how it's stored)
- Success criteria and acceptance criteria (functional perspective)

**❌ Other tasks own**:

- Technical implementation approach → TDD (PF-TSK-022)
- Database schema design → Database Schema Design (PF-TSK-021)
- API endpoint specifications → API Design (PF-TSK-020)
- Comprehensive test plans → Test Specification (PF-TSK-012)

#### Database Schema Design Task (PF-TSK-021)

**✅ This task owns**:

- Data structures (tables, columns, types)
- Relationships (foreign keys, joins)
- Database constraints (unique, not null, check)
- Database security (RLS policies, grants)
- Migration scripts and rollback procedures
- Database performance (indexes, partitioning)

**❌ Other tasks own**:

- API endpoint specifications → API Design (PF-TSK-020)
- Service integration patterns → API Design (PF-TSK-020) or TDD (PF-TSK-022)
- Comprehensive test plans → Test Specification (PF-TSK-012)
- Implementation details → TDD (PF-TSK-022) or Feature Implementation (PF-TSK-030)

#### API Design Task (PF-TSK-020)

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

#### TDD Creation Task (PF-TSK-022)

**✅ This task owns**:

- Technical design and architecture
- Component structure and organization
- Implementation approach and algorithms
- Technology choices and justifications
- Performance considerations (implementation-level)
- Error handling patterns (implementation-level)

**❌ Other tasks own**:

- Functional requirements → FDD (PF-TSK-010)
- Database schema design → Database Schema Design (PF-TSK-021)
- API contracts → API Design (PF-TSK-020)
- Comprehensive test plans → Test Specification (PF-TSK-012)
- System architecture decisions → System Architecture Review (PF-TSK-011)

#### Test Specification Creation Task (PF-TSK-012)

**✅ This task owns**:

- Comprehensive test plans and strategies
- Detailed test cases and scenarios
- Test data requirements and setup
- Acceptance criteria (testing perspective)
- Test coverage requirements
- Test execution procedures

**❌ Other tasks own**:

- Functional requirements → FDD (PF-TSK-010)
- Technical implementation → TDD (PF-TSK-022)
- Database schema → Database Schema Design (PF-TSK-021)
- API contracts → API Design (PF-TSK-020)

### Common Pitfalls and Anti-Patterns

#### ❌ Anti-Pattern 1: Full Duplication

**Problem**: Copying entire sections from one document to another

**Example**:

```markdown
## Database Schema (in API Design document)

### Users Table

| Column     | Type      | Constraints      |
| ---------- | --------- | ---------------- |
| id         | uuid      | PRIMARY KEY      |
| email      | text      | UNIQUE, NOT NULL |
| created_at | timestamp | NOT NULL         |

[... 50 more lines of schema details ...]
```

**Solution**: Use cross-reference with brief summary

```markdown
## Data Model

> **📋 Primary Documentation**: Database Schema Design Task (PF-TSK-021)
> **🔗 Link**: [User Management Schema Design - PD-SCH-003] > **👤 Owner**: Database Schema Design Task

### API Data Access Patterns

The API accesses the users table for authentication and profile management. Key access patterns:

- Primary key lookups for user profile retrieval
- Email-based lookups for authentication
- Batch queries for user lists with pagination

See the Schema Design document for complete table specifications.
```

#### ❌ Anti-Pattern 2: No Context

**Problem**: Referencing another document without any context

**Example**:

```markdown
## Testing

See Test Specification document.
```

**Solution**: Provide task-specific perspective

```markdown
## Testing Strategy

> **📋 Primary Documentation**: Test Specification Creation Task (PF-TSK-012)
> **🔗 Link**: [User Management Test Specification - PD-TST-003] > **👤 Owner**: Test Specification Creation Task

### Database-Specific Testing Considerations

**Schema Validation**: Migration scripts must be tested with rollback procedures before production deployment.

**Performance Testing**: User lookup queries must complete within 100ms under load (1000 concurrent users).

**Security Testing**: RLS policies must be validated with multiple user roles to ensure proper data isolation.

See the Test Specification document for comprehensive test plans and test cases.
```

#### ❌ Anti-Pattern 3: Circular Dependencies

**Problem**: Task A references Task B, which references Task A, creating confusion about ownership

**Example**:

- API Design says "See Schema Design for data model"
- Schema Design says "See API Design for data model"

**Solution**: Establish clear ownership using Task Responsibility Matrix

- Schema Design **owns** the data model (tables, columns, relationships)
- API Design **owns** the data access patterns (how APIs use the data model)
- Each references the other for their specific perspective

#### ❌ Anti-Pattern 4: Outdated Cross-References

**Problem**: Cross-references point to old documents or wrong sections

**Example**:

```markdown
> **🔗 Link**: [Old Schema Design - PD-SCH-001]
```

(But the schema was redesigned in PD-SCH-005)

**Solution**: Maintain cross-references during updates

- When creating new versions of documents, update all cross-references
- Use Feature Tracking to identify related documents
- Include "Related Documents" section in each document

#### ❌ Anti-Pattern 5: Conditional Sections Without Guidance

**Problem**: Including sections that may not apply without clear guidance

**Example**:

```markdown
## Data Migration Strategy

[Empty or N/A]
```

**Solution**: Use conditional section pattern

```markdown
## Data Migration Strategy

> **⚠️ CONDITIONAL SECTION**: Complete this section only when:
>
> - Deploying to production with existing data
> - Making breaking changes to existing schemas
> - Migrating from another system
>
> **For initial development with no production data**, mark as:
> **Status**: ⏭️ N/A - Development Phase (No production data exists)
```

### Best Practices Summary

1. **Use Visual Indicators**: 📋 🔗 👤 ⚠️ ⏭️ make cross-references scannable
2. **Provide Context**: Always include 2-5 sentences explaining the relationship
3. **Task-Specific Perspective**: Focus on what matters for this task
4. **Structured Subsections**: Use consistent subsection patterns
5. **Maintain Links**: Keep cross-references up-to-date
6. **Clear Ownership**: Use Task Responsibility Matrix to resolve ambiguity
7. **Conditional Guidance**: Mark sections that may not always apply
8. **Bidirectional References**: Related tasks can reference each other with different perspectives

## Core Transition Patterns

### 1. Feature Development Workflow

#### New Feature Planning Path

```
Feature Discovery → Feature Tier Assessment → [Conditional Branching]
```

**Transition Criteria:**

- **From Feature Discovery**: Complete when new features are identified and documented in Feature Tracking
- **To Feature Tier Assessment**: When features need complexity evaluation before design/implementation

**Transition Checklist:**

- [ ] Feature Discovery outputs complete (features added to tracking)
- [ ] Features have clear descriptions and initial priorities
- [ ] Ready to assess documentation requirements

#### Complexity-Based Branching

```
Feature Tier Assessment → [Branch based on tier result]
├─ Tier 1 (Simple) → Feature Implementation (with lightweight design)
├─ Tier 2 (Moderate) → FDD Creation → [System Architecture Review] → [API Design] → TDD Creation → Feature Implementation
└─ Tier 3 (Complex) → FDD Creation → [System Architecture Review] → [API Design] → TDD Creation → Test Specification Creation → Feature Implementation
```

**Transition Criteria:**

- **From Feature Tier Assessment**: Complete when tier is assigned and documented
- **To next task**: Based on assigned documentation tier

**Decision Matrix:**
| Tier Result | Next Task | Reason |
|-------------|-----------|---------|
| 🔵 Tier 1 | Feature Implementation | Simple features can be developed with lightweight design |
| 🟠 Tier 2 | FDD Creation | Moderate complexity requires functional design documentation |
| 🔴 Tier 3 | FDD Creation | Complex features need comprehensive functional design documentation |

**Optional Pre-Implementation Tasks:**

- **System Architecture Review**: Use when feature impacts system architecture or introduces new patterns
- **API Design**: Use when feature requires new API endpoints or modifies existing API contracts

#### Pre-Implementation Analysis Path

```
FDD Creation → [System Architecture Review] → [Database Schema Design] → [API Design] → TDD Creation → [Conditional Branching]
├─ Tier 2 → Feature Implementation → Testing (🧪) → Ready for Review (👀) → Code Review
└─ Tier 3 → Test Specification Creation → [Test Implementation] → Feature Implementation → Testing (🧪) → Ready for Review (👀) → Code Review
```

**Transition Criteria:**

- **From FDD Creation**: Complete when functional design document is created and linked in Feature Tracking
- **From System Architecture Review**: Complete when architectural decisions are documented and constraints identified
- **From API Design**: Complete when API specifications are created and data models defined
- **From Database Schema Design**: Complete when schema changes are designed and migration plan is ready
- **From TDD Creation**: Complete when TDD is approved and linked in Feature Tracking
- **From Test Specification Creation**: Complete when comprehensive test specifications are documented
- **From Test Implementation**: Complete when test cases are implemented and ready for development
- **To next task**: Based on original tier assessment

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

#### Decomposed Feature Implementation Path

> **📋 New Enhancement**: Decomposed mode provides granular task-by-task implementation with dedicated context preservation for multi-session development workflows.

```
TDD Creation → [Implementation Mode Selection]
├─ Integrated Mode (Traditional) → Feature Implementation (PF-TSK-004) → Testing → Ready for Review → Code Review
└─ Decomposed Mode (Granular) →
    Feature Implementation Planning (PF-TSK-044) →
    Data Layer Implementation (PF-TSK-051) →
    State Management Implementation (PF-TSK-056) →
    UI Implementation (PF-TSK-052) →
    Integration & Testing (PF-TSK-053) →
    Quality Validation (PF-TSK-054) →
    Implementation Finalization (PF-TSK-055) →
    Testing → Ready for Review → Code Review
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

**Decomposed Task Flow Details:**

**Task 1: Feature Implementation Planning (PF-TSK-044)**

```
Prerequisites: TDD Creation complete
Purpose: Analyze requirements and create implementation roadmap
Outputs: Implementation plan, dependency map, risk mitigation strategies
Next Task: Data Layer Implementation (PF-TSK-051)
```

**Transition Criteria:**
- [ ] Implementation plan created with task breakdown
- [ ] Dependency map identifies component interactions
- [ ] Risk mitigation strategies documented
- [ ] Resource requirements estimated
- [ ] Feature Implementation State File created

**Task 2: Data Layer Implementation (PF-TSK-051)**

```
Prerequisites: Implementation planning complete
Purpose: Implement data models, repositories, and database integration
Outputs: Data model classes, repository implementations, migrations, data access tests
Next Task: State Management Implementation (PF-TSK-056)
```

**Transition Criteria:**
- [ ] Data models defined with validation logic
- [ ] Repository interfaces and implementations complete
- [ ] Database migrations created and tested
- [ ] Data access tests pass with ≥80% coverage
- [ ] Feature Implementation State File updated with data layer inventory

**Task 3: State Management Implementation (PF-TSK-056)**

```
Prerequisites: Data layer complete
Purpose: Implement Riverpod providers and state notifiers
Outputs: State model classes, Riverpod providers, state notifiers, provider tests
Next Task: UI Implementation (PF-TSK-052)
```

**Transition Criteria:**
- [ ] State models defined with immutable patterns
- [ ] Repository providers expose data layer
- [ ] State notifier providers manage mutable state
- [ ] Side effects and async operations handled
- [ ] Provider tests pass with comprehensive coverage
- [ ] Feature Implementation State File updated with state layer inventory

**Task 4: UI Implementation (PF-TSK-052)**

```
Prerequisites: State management complete
Purpose: Build Flutter widgets and screen layouts
Outputs: Widget components, screen widgets, navigation configuration, widget tests
Next Task: Integration & Testing (PF-TSK-053)
```

**Transition Criteria:**
- [ ] Widget components follow single responsibility principle
- [ ] Screen widgets consume providers correctly
- [ ] Navigation routes configured
- [ ] Responsive layouts work across screen sizes
- [ ] Widget tests cover rendering and interactions
- [ ] Feature Implementation State File updated with UI layer inventory

**Task 5: Integration & Testing (PF-TSK-053)**

```
Prerequisites: All layers implemented (data, state, UI)
Purpose: Integrate components and establish comprehensive test coverage
Outputs: Unit tests, widget tests, integration tests, test mocks, coverage report
Next Task: Quality Validation (PF-TSK-054)
```

**Transition Criteria:**
- [ ] Unit test coverage ≥80% for business logic
- [ ] Widget tests cover all screens and critical components
- [ ] Integration tests validate end-to-end workflows
- [ ] All tests pass successfully
- [ ] Coverage report meets project thresholds
- [ ] Feature Implementation State File updated with test metrics

**Task 6: Quality Validation (PF-TSK-054)**

```
Prerequisites: Integration testing complete
Purpose: Validate implementation against quality standards and business requirements
Outputs: Quality validation report, quality metrics, performance benchmarks, security audit, accessibility compliance
Next Task: Implementation Finalization (PF-TSK-055)
```

**Transition Criteria:**
- [ ] Code quality metrics meet standards
- [ ] Performance benchmarks meet targets
- [ ] Security audit identifies no critical vulnerabilities
- [ ] Accessibility compliance verified
- [ ] Business acceptance criteria validated
- [ ] No critical quality issues blocking deployment
- [ ] Feature Implementation State File updated with quality status

**Task 7: Implementation Finalization (PF-TSK-055)**

```
Prerequisites: Quality validation passed
Purpose: Complete remaining items and prepare feature for production
Outputs: Feature documentation, release notes, deployment checklist, rollback plan, deployment configuration
Next Task: Testing (🧪) → Ready for Review (👀) → Code Review
```

**Transition Criteria:**
- [ ] Feature documentation complete
- [ ] Release notes generated
- [ ] Deployment checklist created
- [ ] Rollback plan documented
- [ ] Deployment configurations prepared
- [ ] Stakeholder sign-off obtained
- [ ] Feature Implementation State File archived
- [ ] Feature Tracking updated to "Ready for Deployment"

**State Tracking for Decomposed Mode:**

Each decomposed task updates the **Feature Implementation State File** (`feature-implementation-state-[feature-id].md`) to preserve context:
- **Code Inventory**: Track all created files (models, providers, widgets, tests)
- **Implementation Progress**: Track completion % across layers
- **Implementation Notes**: Document decisions, patterns, and challenges
- **Issues/Blockers**: Track quality issues and dependencies

This enables seamless handoffs between sessions and provides comprehensive implementation history.

**Mode Selection Guidance:**

Refer to [Foundation Feature Implementation Usage Guide](foundation-feature-implementation-usage-guide.md) for detailed mode selection criteria and transition patterns.

### 2. Quality Assurance Workflow

#### Test Quality Assurance Path

```
Test Implementation → Test Audit → [Conditional Branching]
├─ Tests Approved → Feature Implementation → Testing (🧪) → Ready for Review (👀) → Code Review
├─ Tests Approved with Dependencies → [Implementation Tasks] → Feature Implementation → Testing (🧪) → Ready for Review (👀) → Code Review
├─ Needs Update → Test Implementation (address audit findings)
└─ Tests Incomplete → Test Implementation (add missing tests for existing code)
```

**Transition Criteria:**

- **From Test Implementation**: Complete when test implementation reaches "🔄 Ready for Validation" status
- **To Test Audit**: When tests need systematic quality assessment
- **From Test Audit**: Based on audit decision (4 possible outcomes)

**Test Audit Process:**

1. **Preparation**: Review test files and specifications
2. **Implementation Dependency Check**: Verify what can actually be tested
3. **Evaluation**: Assess implementable tests against six quality criteria
4. **Documentation**: Complete audit report with findings and dependency analysis
5. **Decision**: Make audit decision with implementation considerations
6. **Tracking Update**: Update test implementation status

**Audit Decision Outcomes:**

- **✅ Tests Approved**: All implementable tests are complete and high quality → Feature Implementation → Testing (🧪) → Ready for Review (👀) → Code Review
- **🟡 Tests Approved with Dependencies**: Current tests are good, but some await implementation → Implementation Tasks → Feature Implementation → Testing (🧪) → Ready for Review (👀) → Code Review
- **🔄 Needs Update**: Existing tests have issues → Test Implementation (fix issues)
- **🔴 Tests Incomplete**: Missing tests for existing code → Test Implementation (add missing tests)

#### Standard Code QA Path

```
[Any Implementation Task] → Testing (🧪) → Ready for Review (👀) → Code Review → [Conditional Branching]
├─ Review Passed → Completed (🟢) → Release & Deployment
└─ Issues Found → Needs Revision (🔄) → Bug Fixing → Code Review (repeat)
```

**Transition Criteria:**

- **From Implementation**: Complete when all implementation outputs are ready
- **To Testing**: When feature implementation is complete and ready for testing
- **From Testing**: Complete when all tests pass and feature is validated
- **To Ready for Review**: When testing is complete and feature is ready for code review
- **From Ready for Review**: When code review is initiated
- **To Code Review**: When code is ready for quality assessment
- **From Code Review**: Based on review results

### 3. Bug Management Workflow

The bug management workflow provides comprehensive coverage from bug discovery through resolution, integrating with all development tasks to ensure systematic bug identification and tracking.

#### Bug Discovery Sources

```
[Development Tasks] → Bug Discovery → Bug Reporting → Bug Triage → Bug Fixing → Verification
```

**Bug Discovery Integration Points:**

- **Test Audit Task**: Systematic bug identification during test quality assessment
- **Code Review Task**: Bug discovery during code quality review
- **Feature Implementation Task**: Bug identification during quality assurance
- **Test Implementation Task**: Bug discovery during test development
- **Release Deployment Task**: Bug identification during deployment validation
- **Foundation Feature Implementation Task**: Bug discovery for architectural issues
- **Code Refactoring Task**: Bug discovery revealed during code restructuring

#### Complete Bug Management Lifecycle

```
Bug Discovery → Bug Reporting → Bug Triage → [Priority-Based Branching]
├─ 🔴 Critical → Immediate Bug Fixing → Testing → Code Review → Verification → Closed
├─ 🟠 High → Scheduled Bug Fixing → Testing → Code Review → Verification → Closed
├─ 🟡 Medium → Backlog → [Planned Bug Fixing] → Testing → Code Review → Verification → Closed
└─ 🟢 Low → Backlog → [Future Bug Fixing] → Testing → Code Review → Verification → Closed
```

**Transition Criteria:**

- **From Bug Discovery**: Complete when bugs are systematically identified using task-specific categories
- **To Bug Reporting**: When bugs need to be documented in the tracking system
- **From Bug Reporting**: Complete when bug reports are created using New-BugReport.ps1 script
- **To Bug Triage**: When reported bugs need priority assessment and assignment
- **From Bug Triage**: Complete when bugs are prioritized and assigned for resolution
- **To Bug Fixing**: Based on priority level and resource availability
- **From Bug Fixing**: Complete when bug fix is implemented and ready for testing

#### Bug Discovery Decision Matrix

**When to Perform Bug Discovery:**
| Task Context | Bug Discovery Trigger | Bug Categories to Focus On |
|--------------|----------------------|---------------------------|
| **Test Audit** | During test quality assessment | Test implementation bugs, framework issues, integration problems |
| **Code Review** | During code quality review | Logic errors, security vulnerabilities, performance issues |
| **Feature Implementation** | During quality assurance phase | Logic errors, integration issues, UI/UX problems |
| **Test Implementation** | During test development | Implementation bugs, test framework issues, data handling bugs |
| **Release Deployment** | During deployment validation | Deployment failures, configuration problems, integration failures |
| **Foundation Implementation** | During architectural work | Architectural issues, integration problems, foundation logic errors |
| **Code Refactoring** | During code restructuring | Hidden dependencies, logic errors revealed by refactoring, performance issues, error handling gaps, integration issues, data handling bugs, concurrency issues, resource management problems |

#### Bug Reporting Standards

```
Bug Discovered → New-BugReport.ps1 Script → Bug Tracking Update → [Automatic Triage Trigger]
```

**Required Bug Report Elements:**

- **Title**: Clear, descriptive bug summary
- **Description**: Detailed bug description with reproduction steps
- **Severity**: Critical, High, Medium, Low based on impact
- **Component**: Affected system component or feature area
- **Environment**: Development, Testing, Production
- **Evidence**: Code references, error messages, screenshots
- **Discovery Context**: Which task/process revealed the bug

**Example Bug Reporting Commands by Context:**

```powershell
# From Test Audit Task
.\New-BugReport.ps1 -Title "Test framework timeout issues" -Description "Unit tests randomly timeout during CI/CD pipeline execution" -DiscoveredBy "Testing" -Severity "High" -Component "Test Framework" -Environment "CI/CD" -Evidence "Test audit findings: 15% of tests show intermittent timeouts"

# From Code Review Task
.\New-BugReport.ps1 -Title "SQL injection vulnerability in user input" -Description "User input not properly sanitized before database queries" -DiscoveredBy "Code Review" -Severity "Critical" -Component "User Authentication" -Environment "Development" -Evidence "Code review: lib/auth/user_service.dart:45-52"

# From Feature Implementation Task
.\New-BugReport.ps1 -Title "Form validation fails on special characters" -Description "Registration form rejects valid email addresses with plus signs" -DiscoveredBy "Development" -Severity "Medium" -Component "User Registration" -Environment "Development" -Evidence "QA testing: emails like user+test@example.com rejected"
```

#### Bug Triage Decision Process

```
Bug Reported → Impact Assessment → Priority Assignment → Resource Assignment → [Scheduling Decision]
├─ 🔴 Critical → Immediate Assignment → Bug Fixing (within 24 hours)
├─ 🟠 High → Next Sprint Assignment → Bug Fixing (within 1 week)
├─ 🟡 Medium → Backlog Assignment → Bug Fixing (planned release)
└─ 🟢 Low → Future Backlog → Bug Fixing (when resources available)
```

**Bug Triage Criteria:**

- **Critical (🔴)**: System crashes, security vulnerabilities, data loss, production down
- **High (🟠)**: Major functionality broken, significant user impact, performance degradation
- **Medium (🟡)**: Minor functionality issues, workarounds available, usability problems
- **Low (🟢)**: Cosmetic issues, edge cases, nice-to-have improvements

#### Bug Resolution Verification

```
Bug Fixing → Testing (🧪) → Ready for Review (👀) → Code Review → [Verification Branching]
├─ Fix Verified → Bug Status: Verified → [Deployment] → Bug Status: Closed
├─ Fix Incomplete → Bug Status: Reopened → Bug Fixing (repeat)
└─ New Issues Found → New Bug Reports → Bug Triage → Bug Fixing
```

**Verification Requirements:**

- **Testing**: All tests pass, bug reproduction steps no longer trigger the issue
- **Code Review**: Fix implementation follows coding standards and doesn't introduce new issues
- **Deployment Validation**: Fix works correctly in target environment
- **Regression Testing**: Related functionality still works correctly

### 4. Continuous and Cyclical Integration

#### Documentation Management (Continuous)

```
[Any Task] + Documentation Management (Continuous)
```

**Integration Points:**

- **During any task**: When documentation needs to be created or updated
- **Parallel execution**: Runs alongside other tasks
- **Completion**: When all documentation is current and accurate

#### Documentation Tier Adjustment (Cyclical)

```
[During Implementation] → Documentation Tier Adjustment → [Return to Implementation]
```

**Trigger Conditions:**

- **During implementation**: When feature complexity changes significantly
- **After discovery**: When initial tier assessment proves incorrect
- **Before release**: When documentation requirements need reassessment

#### Technical Debt Assessment (Cyclical)

```
[Quarterly/As Needed] → Technical Debt Assessment → [Code Refactoring] → [Continue Development]
```

**Trigger Conditions:**

- **Scheduled**: Quarterly reviews of code quality
- **Before major releases**: Assess technical debt impact
- **After significant changes**: When codebase changes substantially
- **Quality concerns**: When code quality metrics decline

#### Foundational Codebase Validation (Cyclical)

```
[Validation Trigger] → [Select Validation Type] → Validation Task Execution → [Conditional Branching]
├─ Critical Issues Found → [Immediate Remediation] → [Re-validation]
├─ Issues Found → [Plan Improvements] → [Continue Development]
└─ Validation Passed → [Update Tracking] → [Continue Development]
```

**Validation Types Available:**

- **Architectural Consistency Validation** (PF-TSK-031): Pattern adherence, ADR compliance, interface consistency
- **Code Quality Standards Validation** (PF-TSK-032): SOLID principles, best practices, maintainability
- **Integration Dependencies Validation** (PF-TSK-033): Dependency health, data flow, integration patterns
- **Documentation Alignment Validation** (PF-TSK-034): TDD compliance, API documentation accuracy
- **Extensibility Maintainability Validation** (PF-TSK-035): Extension points, testing support, modularity
- **AI Agent Continuity Validation** (PF-TSK-036): Context clarity, workflow optimization, session handoffs

**Trigger Conditions:**

- **Before major releases**: Validate foundational feature quality and consistency
- **After foundational feature implementation**: Ensure architectural integrity
- **Quality gate requirements**: When systematic validation is needed for quality assurance
- **Technical debt assessment follow-up**: Validate improvements after debt remediation
- **Onboarding preparation**: Establish baseline quality metrics for new team members

**Validation Workflow:**

1. **Planning**: Select validation type and features to validate using [Foundational Validation Guide](foundational-validation-guide.md)
2. **Execution**: Follow validation task procedures with comprehensive scoring criteria
3. **Reporting**: Generate validation reports using automation scripts (New-ValidationReport.ps1)
4. **Tracking**: Update validation matrix using Update-ValidationReportState.ps1
5. **Action**: Address findings based on severity and impact assessment

### 5. Support Tasks Workflow

#### Framework Improvement Path

```
[Process Issue Identified] → Process Improvement → [Structure Change] → [Tools Review] → [Continue Development]
```

**Transition Criteria:**

- **Process Improvement**: When development workflows need enhancement
- **Structure Change**: When directory structures or documentation architecture needs reorganization
- **Tools Review**: When project tools need evaluation or enhancement
- **New Task Creation**: When new task types are needed in the framework

**Integration Points:**

- **Parallel execution**: Support tasks can run alongside development work
- **As needed basis**: Triggered by process inefficiencies or improvement opportunities
- **Framework evolution**: Continuous improvement of the development process itself

### 6. Onboarding Workflow (Framework Adoption)

#### Onboarding Path for Existing Projects

```
[Existing Project] → Codebase Feature Discovery (PF-TSK-064)
    ↓ [Feature Implementation State files with code inventories, 100% file coverage]
Codebase Feature Analysis (PF-TSK-065)
    ↓ [Enriched state files: patterns, dependencies, test coverage, complexity]
Retrospective Documentation Creation (PF-TSK-066)
    ↓ [Tier assessments, FDDs, TDDs, Test Specs, ADRs — all marked "Retrospective"]
[Framework Fully Adopted] → Normal Development Workflow
```

**Shared State**: All three tasks share a single [Retrospective Master State File](../../state-tracking/temporary/retrospective-master-state.md) that tracks progress across phases. Each session must start by reading it and end by updating it.

**Transition Criteria:**

- **From Discovery (064) → Analysis (065)**: Phase 1 complete — 100% codebase file coverage, all features have implementation state files with code inventories
- **From Analysis (065) → Documentation (066)**: Phase 2 complete — all features analyzed (patterns, dependencies, test coverage documented)
- **From Documentation (066) → Normal Workflow**: Phase 3+4 complete — all tier assessments created, all required design documents created, master state archived

**Key Characteristics:**

- **Multi-session**: Each task spans multiple sessions; master state tracks progress
- **Batching recommended**: Process features by category (e.g., all foundation features, all parser features)
- **Automation**: Use `New-RetrospectiveMasterState.ps1` (Discovery) and `New-FeatureImplementationState.ps1` (Discovery) for file creation
- **One-time process**: Onboarding is done once per project; after completion, use normal development workflow

**After Onboarding Completes:**

- Use [Feature Implementation Task](../../tasks/04-implementation/feature-implementation-task.md) for extending features
- Use [Code Review Task](../../tasks/06-maintenance/code-review-task.md) for validating implementation against documented design
- Use [Technical Debt Assessment](../../tasks/cyclical/technical-debt-assessment-task.md) for debt discovered during analysis

## Detailed Transition Procedures

### Transitioning FROM Codebase Feature Discovery (PF-TSK-064)

**Prerequisites for Transition:**

- [ ] [Retrospective Master State File](../../state-tracking/temporary/retrospective-master-state.md) created with project name and DISCOVERY status
- [ ] ALL source files listed and assigned to features (100% codebase file coverage)
- [ ] ALL features added to [Feature Tracking](../../state-tracking/permanent/feature-tracking.md) with IDs and descriptions
- [ ] [Feature Implementation State file](../../state-tracking/features/) created for every feature with complete code inventory
- [ ] Phase 1 marked complete in master state file

**Next Task Selection:**

- **Always**: → [Codebase Feature Analysis (PF-TSK-065)](../../tasks/00-onboarding/codebase-feature-analysis.md)

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
- [ ] Phase 2 marked complete in [master state file](../../state-tracking/temporary/retrospective-master-state.md)

**Next Task Selection:**

- **Always**: → [Retrospective Documentation Creation (PF-TSK-066)](../../tasks/00-onboarding/retrospective-documentation-creation.md)

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
- [ ] All document links added to [Feature Tracking](../../state-tracking/permanent/feature-tracking.md)
- [ ] [Documentation Map](../../documentation-map.md) updated with all new documents
- [ ] Final metrics recorded in master state Completion Summary
- [ ] [Master State File](../../state-tracking/temporary/retrospective-master-state.md) archived to `/temporary/archived/`

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
├─ Tier 2 (🟠) → Feature Implementation → Testing (🧪) → Ready for Review (👀) → Code Review
│   └─ Reason: Moderate complexity with lightweight design is sufficient
└─ Tier 3 (🔴) → Test Specification Creation → Feature Implementation → Testing (🧪) → Ready for Review (👀) → Code Review
    └─ Reason: Complex features need comprehensive test planning before implementation
```

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

1. **Load Current Architecture State**: Review [Architecture Tracking](../../state-tracking/permanent/architecture-tracking.md)
2. **Gather Feature Context**: Ensure FDD and Feature Tier Assessment are complete
3. **Identify Relevant Context Packages**: Determine which [Architecture Context Packages](/doc/product-docs/technical/architecture/context-packages/) apply
4. **Review Related ADRs**: Check existing [Architecture Decision Records](/doc/product-docs/technical/architecture/design-docs/adr/README.md)
5. **Prepare Impact Analysis Framework**: Set up structured approach for architectural evaluation

### Transitioning FROM System Architecture Review

**Prerequisites for Transition:**

- [ ] Architecture impact assessment completed
- [ ] Architectural decisions documented
- [ ] System constraints and patterns identified
- [ ] Feature Tracking updated with status "🏗️ Architecture Reviewed"
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
2. **Review Architectural Framework Usage Guide**: [Architectural Framework Usage Guide](../architectural-framework-usage-guide.md) for step-by-step instructions
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

### Transitioning FROM Test Specification Creation

**Prerequisites for Transition:**

- [ ] Test specification document created
- [ ] Test cases cover all TDD requirements
- [ ] Test specification linked in tracking files
- [ ] Test approach validated

**Next Task Selection:**

```
Is test-first development approach being used?
├─ Yes → Test Implementation
│   └─ Reason: Implement tests before feature development for TDD approach
└─ No → Feature Implementation
    └─ Reason: Proceed directly to feature implementation with test specifications as reference
```

**Preparation for Next Task:**

1. Review test specification to understand testing requirements
2. Ensure test cases align with TDD design
3. Verify test data and environment requirements
4. Confirm testing approach is feasible

### Transitioning FROM Test Implementation

**Prerequisites for Transition:**

- [ ] Test cases implemented according to test specifications
- [ ] Test implementation status updated to "🔄 Ready for Validation"
- [ ] Test implementation linked in tracking files
- [ ] Test environment and data setup complete

**Next Task Selection:**

```
Is systematic test quality assessment needed?
├─ Yes → Test Audit → Feature Implementation → Testing (🧪) → Ready for Review (👀) → Code Review
│   └─ Reason: Quality gate to ensure test implementation meets standards
└─ No → Feature Implementation → Testing (🧪) → Ready for Review (👀) → Code Review
    └─ Reason: Proceed directly to feature implementation (for simple tests or when quality is assured)
```

**Preparation for Next Task:**

1. **For Test Audit**: Ensure test files are accessible and specifications are available
2. **For Feature Implementation**: Review implemented test cases to understand expected behavior
3. Ensure test environment is properly configured
4. Verify test data and fixtures are available

### Transitioning FROM Test Audit

**Prerequisites for Transition:**

- [ ] Test audit report completed with all six evaluation criteria assessed
- [ ] Audit decision made (Tests Approved or Needs Update)
- [ ] Test implementation tracking updated with audit results
- [ ] Audit report validated using Validate-AuditReport.ps1

**Next Task Selection:**

```
What was the audit decision?
├─ Tests Approved → Feature Implementation → Testing (🧪) → Ready for Review (👀) → Code Review
│   └─ Reason: Tests meet quality standards, proceed with feature development
└─ Needs Update → Test Implementation
    └─ Reason: Tests require improvements before feature development
```

**Preparation for Next Task:**

1. **For Feature Implementation**: Review audit findings for any implementation considerations
2. **For Test Implementation**: Review audit recommendations and action items
3. Update test implementation tracking with appropriate status
4. Ensure audit findings are addressed in next implementation cycle
5. Confirm all tests are in failing state and ready for implementation

### Transitioning FROM Ready for Review

**Prerequisites for Transition:**

- [ ] Feature implementation is complete and functional
- [ ] All tests pass (unit, widget, integration as applicable)
- [ ] Feature meets all acceptance criteria
- [ ] Code follows project standards and conventions
- [ ] Feature status updated to "👀 Ready for Review" in Feature Tracking
- [ ] All documentation is up-to-date

**Next Task Selection:**

```
Ready for Review → Code Review → [Conditional Branching]
├─ Review Passed → Completed (🟢)
│   └─ Reason: Feature meets all quality standards and requirements
└─ Issues Found → Needs Revision (🔄) → Bug Fixing → Testing (🧪) → Ready for Review (👀)
    └─ Reason: Issues must be addressed before feature can be completed
```

**Preparation for Next Task:**

1. **For Code Review**: Ensure all code is committed and accessible for review
2. **For Code Review**: Prepare context about implementation decisions and trade-offs
3. **For Code Review**: Verify that the [Code Review Checklist](../../../product-docs/checklists/checklists/code-review-checklist.md) can be completed
4. Update Feature Tracking with review request and reviewer assignment
5. Ensure all related documentation is current and linked

### Transitioning FROM ADR Creation

**Prerequisites for Transition:**

- [ ] Architecture Decision Record created and documented
- [ ] Decision rationale clearly explained
- [ ] Alternatives considered and documented
- [ ] Consequences and trade-offs identified
- [ ] ADR linked in Architecture Tracking

**Next Task Selection:**

```
What type of architectural work was this ADR for?
├─ Foundation Feature architectural decision → Foundation Feature Implementation
│   └─ Reason: ADR provides architectural guidance for foundation implementation
├─ Regular feature architectural decision → Continue with feature development workflow
│   └─ Reason: ADR informs technical design and implementation
└─ System-wide architectural decision → Update Architecture Context Package
    └─ Reason: ADR impacts broader architectural understanding
```

**Preparation for Next Task:**

1. Ensure ADR is properly linked in Architecture Tracking
2. Review architectural decision impact on current work
3. Prepare architectural constraints and guidelines for implementation
4. Update relevant Architecture Context Packages if needed

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
├─ Approved with no issues → Release & Deployment
├─ Minor issues identified → Address issues → Release & Deployment
├─ Major issues identified → Bug Fixing → Code Review (repeat)
└─ Code quality issues identified → Code Refactoring → Code Review (repeat)
```

**Preparation for Next Task:**

1. Address any review findings
2. Update documentation if needed
3. Ensure all quality gates are met
4. Prepare release notes if proceeding to deployment

### Transitioning FROM Code Refactoring

**Prerequisites for Transition:**

- [ ] **Refactoring Implementation Complete**: All planned refactoring work executed
- [ ] **3-Phase State Updates Complete**: All state files updated according to comprehensive checklist
  - [ ] Phase 1: Temporary state tracking, bug tracking, technical debt progress documented
  - [ ] Phase 2: Technical debt resolved, feature status improved, architecture tracking updated
  - [ ] Phase 3: Temporary state archived, context packages updated
- [ ] **Bug Discovery Complete**: Systematic bug identification performed with 4-tier decision matrix
- [ ] **ADR Creation Complete**: Architecture Decision Records created for architectural refactoring
- [ ] **Quality Validation**: All tests still passing after refactoring
- [ ] **Documentation Updated**: Refactoring plan completed with results and lessons learned

**Next Task Selection:**

```
What was the refactoring outcome?
├─ Feature status improved to "🧪 Testing" → Testing Phase → Ready for Review (👀) → Code Review
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
- [ ] Bug entry added to Bug Tracking with status 🆕 Reported
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
- [ ] Bug status updated to 🔄 Triaged
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
- [ ] Bug status updated to 🧪 Testing
- [ ] Fix implementation documented

**Next Task Selection:**

- **Always**: → Testing (🧪) → Ready for Review (👀) → Code Review

**Preparation for Next Task:**

1. Ensure all tests pass including new regression tests
2. Verify bug fix doesn't introduce new issues
3. Prepare summary of fix implementation approach
4. Document any design or architectural changes made
5. Update Bug Tracking with fix details and testing status

### Transitioning FROM Bug Verification

**Prerequisites for Transition:**

- [ ] Bug fix verified through testing
- [ ] Code review completed and approved
- [ ] Regression testing confirms no new issues introduced
- [ ] Deployment validation successful (if applicable)

**Next Task Selection Decision:**

```
What was the verification result?
├─ Fix Verified → Bug Status: ✅ Verified → [Deployment] → Bug Status: 🟢 Closed
├─ Fix Incomplete → Bug Status: 🔄 Reopened → Bug Fixing (repeat cycle)
├─ New Issues Found → New Bug Reports → Bug Triage → Bug Fixing
└─ Regression Issues → New Bug Reports → Bug Triage → Bug Fixing
```

**Preparation for Next Task:**

1. **For Verified Fixes**: Update Bug Tracking with closure information and deployment status
2. **For Incomplete Fixes**: Document what aspects still need work and return to Bug Fixing
3. **For New Issues**: Create new bug reports for any issues discovered during verification
4. **For Regression Issues**: Prioritize regression bugs appropriately based on impact
5. Update all relevant tracking files with final bug resolution status

## Common Transition Scenarios

### Scenario 1: Simple Feature End-to-End

```
Feature Discovery → Feature Tier Assessment (Tier 1) → Feature Implementation → Code Review → Release & Deployment
```

**Timeline**: Typically 1-3 days for small features
**Key Decision Points**: Tier assessment determines path

### Scenario 2: Moderate Complexity Feature

```
Feature Discovery → Feature Tier Assessment (Tier 2) → [System Architecture Review] → [API Design] → [Database Schema Design] → TDD Creation → Feature Implementation → Code Review → Release & Deployment
```

**Key Decision Points**: Architecture impact assessment, API design requirements, database schema changes, TDD quality gates

### Scenario 3: Complex Feature with Full Documentation

```
Feature Discovery → Feature Tier Assessment (Tier 3) → System Architecture Review → API Design → Database Schema Design → TDD Creation → Test Specification Creation → Test Implementation → Feature Implementation → Code Review → Release & Deployment
```

**Key Decision Points**: Architecture decisions, API contract completeness, database schema design, TDD quality, test specification coverage, test-first development approach

### Scenario 4: API-Focused Feature (Any Tier)

```
Feature Discovery → Feature Tier Assessment → System Architecture Review → API Design → [Database Schema Design] → TDD Creation → [Test Specification Creation] → [Test Implementation] → Feature Implementation → Code Review → Release & Deployment
```

**Key Decision Points**: API contract design, data model consistency, database schema alignment, integration patterns
**When to Use**: Any feature that introduces new API endpoints or modifies existing API contracts

### Scenario 5: Database-Focused Feature (Any Tier)

```
Feature Discovery → Feature Tier Assessment → [System Architecture Review] → Database Schema Design → TDD Creation → [Test Specification Creation] → [Test Implementation] → Feature Implementation → Code Review → Release & Deployment
```

**Key Decision Points**: Database schema design, data migration planning, data integrity constraints
**When to Use**: Any feature that requires significant database schema changes or new data models

### Scenario 6: Test-First Development (TDD Approach)

```
Feature Discovery → Feature Tier Assessment (Tier 3) → System Architecture Review → API Design → Database Schema Design → TDD Creation → Test Specification Creation → Test Implementation → Feature Implementation → Code Review → Release & Deployment
```

**Key Decision Points**: Comprehensive test planning, test implementation before feature development
**When to Use**: When using strict test-driven development methodology

### Scenario 7: Code Quality Improvement

```
Code Refactoring → Code Review → [Pass/Fail Decision]
├─ Pass → Update Technical Debt Tracking
└─ Fail → Code Refactoring (repeat)
```

**Key Decision Points**: Code quality improvements, technical debt reduction
**When to Use**: When addressing technical debt or improving code maintainability

### Scenario 8: Bug Management Lifecycle

```
[Development Task] → Bug Discovery → Bug Reporting → Bug Triage → [Priority-Based Branching]
├─ 🔴 Critical → Immediate Bug Fixing → Testing → Code Review → Verification → Closed
├─ 🟠 High → Scheduled Bug Fixing → Testing → Code Review → Verification → Closed
├─ 🟡 Medium → Backlog → Planned Bug Fixing → Testing → Code Review → Verification → Closed
└─ 🟢 Low → Future Backlog → Bug Fixing → Testing → Code Review → Verification → Closed
```

**Timeline**:

- Critical: 24 hours
- High: 1 week
- Medium: Next planned release
- Low: Maintenance cycles

**Key Decision Points**: Bug severity assessment, priority assignment, resource allocation, verification completeness
**When to Use**: When bugs are discovered during any development task

### Scenario 9: Bug Discovery During Code Review

```
Code Review → Bug Discovery → Bug Reporting → Bug Triage → Bug Fixing → Code Review (repeat) → [Pass/Fail Decision]
├─ Pass → Release & Deployment
└─ Additional Issues → Bug Discovery (repeat cycle)
```

**Key Decision Points**: Bug severity during review, fix complexity, review re-approval
**When to Use**: When code review reveals bugs that need immediate attention

### Scenario 10: Bug Discovery During Testing

```
Test Audit → Bug Discovery → Bug Reporting → Bug Triage → Bug Fixing → Testing → Code Review → [Verification Decision]
├─ Fix Verified → Continue with Feature Implementation
├─ Fix Incomplete → Bug Fixing (repeat)
└─ New Issues Found → Bug Discovery → Bug Reporting → Bug Triage
```

**Key Decision Points**: Test quality impact, bug fix verification, regression testing
**When to Use**: When systematic testing reveals bugs that affect feature development

### Scenario 11: Technical Debt Management

```
Technical Debt Assessment → Code Refactoring → Code Review → Release & Deployment
```

**Key Decision Points**: Debt prioritization, refactoring scope, quality verification
**When to Use**: Quarterly reviews or when code quality metrics decline

### Scenario 12: Complexity Change During Development

```
[During Implementation] → Documentation Tier Adjustment → [Adjusted Task Sequence] → Continue Implementation
```

**Key Decision Points**: Complexity reassessment, documentation requirements adjustment
**When to Use**: When feature complexity changes significantly during development

### Scenario 13: Framework Improvement

```
Process Improvement → [Structure Change] → [Tools Review] → [New Task Creation Process] → Continue Development
```

**Key Decision Points**: Process effectiveness, structural organization, tool efficiency
**When to Use**: When development workflows need enhancement or new capabilities

### Scenario 14: Framework Onboarding (Existing Project)

```
Codebase Feature Discovery (PF-TSK-064) → Codebase Feature Analysis (PF-TSK-065) → Retrospective Documentation Creation (PF-TSK-066) → [Normal Development Workflow]
```

**Timeline**: Multi-session per task; total depends on project size and feature count
**Key Decision Points**: Feature boundary identification, tier assessment accuracy, documentation completeness
**When to Use**: Adopting the process framework into an existing project with implemented but undocumented features
**Shared State**: All three tasks share a single [Retrospective Master State File](../../state-tracking/temporary/retrospective-master-state.md)
**Automation Scripts**: `New-RetrospectiveMasterState.ps1` (creates master state), `New-FeatureImplementationState.ps1` (creates per-feature state files with code inventories)

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

**Solution**: Use the decision trees in this guide and consult the task selection guide in ai-tasks.md

### Issue: Prerequisites Not Met

**Solution**: Return to previous task and complete missing outputs before transitioning

### Issue: Multiple Valid Next Tasks

**Solution**: Consider project priorities, resource availability, and dependencies to choose the most appropriate path

### Issue: Transition Blocked by External Dependencies

**Solution**: Document the blocker, update tracking files, and consider alternative approaches or parallel work

---

_This guide is part of the Process Framework and provides essential guidance for navigating between tasks effectively._
