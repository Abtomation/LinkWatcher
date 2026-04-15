---
id: PF-GDE-062
type: Process Framework
category: Guide
version: 1.0
created: 2026-04-13
updated: 2026-04-13
change_notes: "v1.0 - Extracted from Task Transition Guide (PF-GDE-018) to separate information flow concerns from transition procedures"
---

# Information Flow and Separation of Concerns

This guide establishes clear boundaries between tasks to prevent documentation duplication while ensuring comprehensive coverage. It defines what information flows between tasks, who owns each type, how to reference other tasks' outputs, and when to duplicate vs. reference.

> **📋 Origin**: This content was extracted from the Task Transition Guide (now [Task Transition Registry](/process-framework/infrastructure/task-transition-registry.md)) as part of a structure change to separate information flow guidance from transition procedures. The two documents serve different audiences: this guide serves design/planning tasks; the registry serves implementation/maintenance tasks.

## Information Flow Model

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

## Task Responsibility Matrix

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
| **Test Plans & Cases**        | Test Specification         | Feature Implementation, Integration & Testing   | Comprehensive testing strategy              |
| **Acceptance Criteria**       | Test Specification         | Feature Implementation, Code Review             | Definition of done                          |
| **Working Code**              | Feature Implementation     | Code Review, Release                            | Actual implementation                       |

## Cross-Reference Standards

When one task needs to reference another task's outputs, use this standard format:

### Standard Cross-Reference Format

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

### Visual Indicators

- **📋** = Primary Documentation (indicates where full details are documented)
- **🔗** = Link (provides navigation to the primary document)
- **👤** = Owner (identifies which task owns this information)
- **⚠️** = Conditional Section (indicates section may not always apply)
- **⏭️** = Not Applicable (indicates section doesn't apply in current context)

### Examples by Task

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

## Decision Framework: When to Duplicate vs. Reference

Use this framework to decide whether to duplicate information or reference another task:

### Duplicate When:

1. **Different Perspective**: The information serves a fundamentally different purpose in each task

   - Example: FDD describes "what data users need" (functional), Schema Design describes "how data is stored" (technical)

2. **Task-Specific Details**: Each task adds unique details not relevant to the other

   - Example: API Design specifies endpoint paths, Schema Design specifies table structures

3. **Standalone Readability**: The document must be understandable without reading other documents

   - Example: Each document should have enough context to understand its scope

4. **Critical Context**: The information is essential for understanding this task's outputs
   - Example: TDD must include enough functional context to understand technical decisions

### Reference When:

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

### Decision Tree

```
Does another task own the detailed specification?
├─ YES → Reference with brief summary (2-5 sentences)
└─ NO → Is this information critical for this task?
    ├─ YES → Duplicate with task-specific perspective
    └─ NO → Consider if section is needed at all
```

## Separation of Concerns by Task

This section clarifies what each task **owns** vs. what it **references**:

### FDD Creation Task (PF-TSK-027)

**Owns**:

- Functional requirements and user stories
- User flows and interaction patterns
- Business rules and validation logic (functional perspective)
- Data requirements (what data is needed, not how it's stored)
- Success criteria and acceptance criteria (functional perspective)

**Other tasks own**:

- Technical implementation approach → TDD (PF-TSK-015)
- Database schema design → Database Schema Design (PF-TSK-021)
- API endpoint specifications → API Design (PF-TSK-020)
- Comprehensive test plans → Test Specification (PF-TSK-012)

### Database Schema Design Task (PF-TSK-021)

**Owns**:

- Data structures (tables, columns, types)
- Relationships (foreign keys, joins)
- Database constraints (unique, not null, check)
- Database security (RLS policies, grants)
- Migration scripts and rollback procedures
- Database performance (indexes, partitioning)

**Other tasks own**:

- API endpoint specifications → API Design (PF-TSK-020)
- Service integration patterns → API Design (PF-TSK-020) or TDD (PF-TSK-015)
- Comprehensive test plans → Test Specification (PF-TSK-012)
- Implementation details → TDD (PF-TSK-015) or Feature Implementation (PF-TSK-024)

### API Design Task (PF-TSK-020)

**Owns**:

- API endpoint specifications (paths, methods, parameters)
- Request/response schemas and data contracts
- API authentication and authorization patterns
- API error handling and status codes
- API versioning strategy
- Service integration patterns and communication protocols

**Other tasks own**:

- Database schema details → Database Schema Design (PF-TSK-021)
- Service implementation details → TDD (PF-TSK-015)
- Functional requirements → FDD (PF-TSK-027)
- Comprehensive test plans → Test Specification (PF-TSK-012)

### TDD Creation Task (PF-TSK-015)

**Owns**:

- Technical design and architecture
- Component structure and organization
- Implementation approach and algorithms
- Technology choices and justifications
- Performance considerations (implementation-level)
- Error handling patterns (implementation-level)

**Other tasks own**:

- Functional requirements → FDD (PF-TSK-027)
- Database schema design → Database Schema Design (PF-TSK-021)
- API contracts → API Design (PF-TSK-020)
- Comprehensive test plans → Test Specification (PF-TSK-012)
- System architecture decisions → System Architecture Review (PF-TSK-019)

### Integration Narrative Creation Task (PF-TSK-083)

**Owns**:

- Cross-feature workflow documentation (how 2+ features collaborate at runtime)
- Component interaction diagrams spanning feature boundaries
- Data flow sequences across features
- Callback/event chains between features
- Configuration propagation across feature boundaries
- Error handling across feature boundaries
- TDD/Code divergence notes (reporting discrepancies as tech debt)

**Other tasks own**:

- Individual feature technical design → TDD (PF-TSK-015)
- Individual feature functional design → FDD (PF-TSK-027)
- Test plans for cross-feature workflows → Test Specification (PF-TSK-012)
- Architectural decisions → Create ADR inline using [New-ArchitectureDecision.ps1](/process-framework/scripts/file-creation/02-design/New-ArchitectureDecision.ps1) and the [Architecture Decision Creation Guide](/process-framework/guides/02-design/architecture-decision-creation-guide.md)

### Test Specification Creation Task (PF-TSK-012)

**Owns**:

- Comprehensive test plans and strategies
- Detailed test cases and scenarios
- Test data requirements and setup
- Acceptance criteria (testing perspective)
- Test coverage requirements
- Test execution procedures

**Other tasks own**:

- Functional requirements → FDD (PF-TSK-027)
- Technical implementation → TDD (PF-TSK-015)
- Database schema → Database Schema Design (PF-TSK-021)
- API contracts → API Design (PF-TSK-020)

## Common Pitfalls and Anti-Patterns

### Anti-Pattern 1: Full Duplication

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

### Anti-Pattern 2: No Context

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

### Anti-Pattern 3: Circular Dependencies

**Problem**: Task A references Task B, which references Task A, creating confusion about ownership

**Example**:

- API Design says "See Schema Design for data model"
- Schema Design says "See API Design for data model"

**Solution**: Establish clear ownership using Task Responsibility Matrix

- Schema Design **owns** the data model (tables, columns, relationships)
- API Design **owns** the data access patterns (how APIs use the data model)
- Each references the other for their specific perspective

### Anti-Pattern 4: Outdated Cross-References

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

### Anti-Pattern 5: Conditional Sections Without Guidance

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

## Best Practices Summary

1. **Use Visual Indicators**: 📋 🔗 👤 ⚠️ ⏭️ make cross-references scannable
2. **Provide Context**: Always include 2-5 sentences explaining the relationship
3. **Task-Specific Perspective**: Focus on what matters for this task
4. **Structured Subsections**: Use consistent subsection patterns
5. **Maintain Links**: Keep cross-references up-to-date
6. **Clear Ownership**: Use Task Responsibility Matrix to resolve ambiguity
7. **Conditional Guidance**: Mark sections that may not always apply
8. **Bidirectional References**: Related tasks can reference each other with different perspectives
