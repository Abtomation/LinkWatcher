---
id: PF-PRO-013
type: Document
category: Proposal
version: 1.0
created: 2026-03-30
updated: 2026-03-30
proposal_status: Draft
---

# Proposal: Dimension-Aware Development Integration

## Overview

Integrate the 11 validation dimensions into the entire development lifecycle — from planning through execution to review — so that quality concerns are **designed for** during development rather than only **discovered** during post-implementation validation rounds.

**Proposer**: AI Agent & Human Partner
**Date Proposed**: 2026-03-30
**Type**: Structural Change (cross-cutting framework enhancement)

## Problem Statement

### Current State

The validation dimensions (Architectural Consistency, Code Quality, Security, Performance, Observability, Data Integrity, etc.) are currently an **exclusively post-implementation concept**. They exist only within the `05-validation/` task family:

- **Validation Preparation** (PF-TSK-077) evaluates which dimensions apply to which features
- **11 dimension-specific validation tasks** check code against those dimensions
- Validation reports document findings — many of which become tech debt items

The word "dimension" does not appear in any planning, implementation, or maintenance task definition.

### The Gap

This creates a **validate-after** model where developers can complete implementation tasks without ever considering security, observability, data integrity, or performance as explicit concerns. The validation round then discovers issues that would have been cheaper to address during development.

**Concrete examples from Round 2 validation:**
- Security findings (input validation gaps) that should have been considered during implementation
- Performance issues (O(n²) patterns) that a dimension-aware implementation step would have caught
- Observability gaps (missing logging in error paths) that are trivial to add during coding but expensive to retrofit
- Data integrity issues (missing atomicity guarantees) that require architectural changes when caught late

### Desired State

A **design-for** model where:
1. Dimensions are **identified early** (during planning/triage)
2. Dimension requirements are **carried through** to execution tasks via state files
3. Implementation tasks **explicitly consider** the identified dimensions
4. Code review **focuses on** the flagged dimensions
5. Validation rounds become **confirmation** rather than **discovery**

## Proposed Solution

### Component 1: Universal Dimension Reference Guide

Create a new guide at `doc/process-framework/guides/framework/development-dimensions-guide.md` that serves as the single authoritative reference for dimensions across all task phases. Unlike the current `feature-validation-guide.md` (which is scoped to validation), this guide would be **task-phase-agnostic**.

**Content structure:**

For each of the 11 dimensions:
- **Definition**: What this dimension covers (1-2 sentences)
- **Applicability Criteria**: When this dimension is relevant (reused from validation guide)
- **Planning Considerations**: What to think about when scoping work (2-3 bullet points)
- **Development Checklist**: Concrete items to verify during implementation (5-8 items)
- **Review Focus Points**: What a reviewer should check (3-5 items)
- **Common Anti-Patterns**: What typically goes wrong when this dimension is ignored (2-3 examples)

**Key design principle**: This guide must be **concise and actionable** — not a comprehensive validation methodology. Tasks would reference specific sections rather than requiring agents to read the entire guide. Each dimension's development checklist should fit in ~10 lines.

**Relationship to existing validation guide**: The `feature-validation-guide.md` would reference this new guide for dimension definitions but retain its own validation-specific scoring methodology, thresholds, and reporting templates. No duplication — the validation guide would link to the universal guide for definitions and applicability criteria.

### Component 2: Feature Tier Assessment as Dimension Source of Truth

The **Feature Tier Assessment** (PF-TSK-002) is the natural home for dimension identification because:
- It already analyzes the feature's characteristics (complexity factors)
- It runs early in the workflow (right after Feature Request Evaluation)
- Its output feeds into feature-tracking.md — the central reference
- The dimension applicability criteria (handles user input? has UI? does I/O?) align with the complexity factors it already evaluates

**Proposed changes to PF-TSK-002:**

Add a **Dimension Applicability Evaluation** step after tier determination:
1. Using the applicability criteria from the Development Dimensions Guide, evaluate each of the 11 dimensions
2. Mark each as: **Applicable** / **Not Applicable** (with brief rationale for extended dimensions)
3. The 4 core dimensions (Architectural Consistency, Code Quality, Integration, Documentation Alignment) are always applicable — no evaluation needed
4. The 7 extended dimensions use the existing "Apply When" criteria

**Output**: The assessment document gets a new **Dimension Profile** section listing applicable dimensions with rationale.

**For enhancements and bugs** (which don't go through tier assessment):
- **Feature Request Evaluation** (PF-TSK-067): When classifying an enhancement, inherit the parent feature's dimension profile as a starting point, then adjust based on the enhancement's specific scope (an enhancement might add security concerns that the original feature didn't have)
- **Bug Triage** (PF-TSK-006): Identify which dimensions are affected by the bug. A data corruption bug triggers Data Integrity + Observability. A path traversal bug triggers Security. This is a subset identification ("which dimensions does this bug touch?") rather than a full applicability evaluation

### Component 3: State Tracking File Changes

#### 3a. Feature Tracking (feature-tracking.md)

Add a **Dimensions** column to the feature registry table. Content would be a compact notation of applicable dimensions, e.g., `AC CQ ID DA EM SE PE OB DI` (abbreviations for the 11 dimensions). This provides at-a-glance visibility of which dimensions matter for each feature.

**Abbreviation key** (added to the Status Legends section):
| Abbr | Dimension |
|------|-----------|
| AC | Architectural Consistency |
| CQ | Code Quality & Standards |
| ID | Integration & Dependencies |
| DA | Documentation Alignment |
| EM | Extensibility & Maintainability |
| AI | AI Agent Continuity |
| SE | Security & Data Protection |
| PE | Performance & Scalability |
| OB | Observability |
| UX | Accessibility / UX Compliance |
| DI | Data Integrity |

#### 3b. Feature Implementation State Files

Add a **Dimension Profile** section (after Section 6: Dependencies, before Section 7: Design Decisions):

```markdown
## Dimension Profile

Source: [Tier Assessment PD-TAS-XXX](link) | Last reviewed: YYYY-MM-DD

### Applicable Dimensions
| Dimension | Rationale | Key Considerations |
|-----------|-----------|-------------------|
| Security & Data Protection | Handles file paths from user input | Validate path traversal, sanitize inputs |
| Performance & Scalability | File I/O on large projects | Batch operations, avoid O(n²) scans |
| Data Integrity | Modifies files atomically | Ensure backup before write, handle partial failures |

### Not Applicable (with rationale)
| Dimension | Rationale |
|-----------|-----------|
| Accessibility / UX | No UI components — CLI tool |
```

This section serves as the **working reference** during implementation — the developer/agent reads it before starting coding work on the feature.

#### 3c. Enhancement State Tracking Files

Add a **Dimension Impact Assessment** section before the Execution Steps:

```markdown
## Dimension Impact Assessment

Inherited from parent feature: AC, CQ, ID, DA, EM, SE, PE, OB, DI
**Additional dimensions for this enhancement**: [none / list with rationale]
**Reduced dimensions for this enhancement**: [none / list with rationale — e.g., "UX: N/A — this enhancement is backend-only"]

### Key Dimension Considerations for This Enhancement
- **Security**: New config options must validate input values against allowlist
- **Performance**: New ignore patterns evaluated on every file event — must be O(1) lookup
```

#### 3d. Bug Tracking (bug-tracking.md)

Add a **Dims** column to the bug registry tables. Content is the compact abbreviation notation showing which dimensions the bug affects (e.g., `SE DI` for a data corruption bug with security implications).

This is populated during Bug Triage and informs Bug Fixing scope.

#### 3e. Bug Fix State Tracking Files

Add dimension context to the **Root Cause Analysis** section:

```markdown
### Affected Dimensions
- **Data Integrity**: Bug causes silent data loss during concurrent writes
- **Observability**: No logging when the race condition occurs — failure is invisible

### Dimension-Informed Fix Requirements
- Fix must include atomicity guarantee (Data Integrity)
- Fix must add logging for concurrent access attempts (Observability)
```

#### 3f. Technical Debt Tracking (technical-debt-tracking.md)

The existing **Category** column already partially maps to dimensions (Security, Performance, Accessibility categories exist). Proposal: Add an **Affected Dimensions** column that provides finer granularity — a single debt item might be categorized as "Code Quality" but also affect "Performance" and "Extensibility".

### Component 4: Task Definition Changes

The following tasks require process step additions to become dimension-aware:

#### Planning Phase Tasks

**Feature Tier Assessment (PF-TSK-002)**:
- Add Step: "Evaluate Dimension Applicability" after tier determination
- Add Output: Dimension Profile in assessment document
- Add: Update feature-tracking.md Dimensions column

**Feature Request Evaluation (PF-TSK-067)**:
- Add Step: When classifying as enhancement, inherit parent feature's dimension profile
- Add Step: Evaluate if the enhancement scope changes dimension applicability
- Add Output: Dimension Impact Assessment in Enhancement State Tracking File

**Bug Triage (PF-TSK-006)**:
- Add Step: "Identify Affected Dimensions" during severity/scope assessment
- Add Output: Dims column in bug-tracking.md entry
- For Large-scope bugs: Dimension context in Bug Fix State File

**Feature Implementation Planning (PF-TSK-044)**:
- Add Step: "Review Feature Dimension Profile" during plan creation
- Add Step: Map dimensions to specific implementation tasks (e.g., "Data Layer Implementation must address Data Integrity dimension")
- Add: Dimension requirements as acceptance criteria in the implementation plan

**Technical Debt Assessment (cyclical)**:
- Add Step: Tag each debt item with affected dimensions
- This enables prioritization by dimension impact (security-tagged debt ranks higher)

#### Execution Phase Tasks

**Core Logic Implementation (PF-TSK-078)**:
- Add to Preparation: "Read the feature's Dimension Profile from the implementation state file"
- Add to Execution: "Before marking module complete, verify flagged dimensions are addressed using the Development Dimensions Guide checklist"
- Add to Bug Discovery: "Tag discovered bugs with affected dimensions"

**Feature Enhancement (PF-TSK-068)**:
- Add to Preparation: "Read the Dimension Impact Assessment from the Enhancement State Tracking File"
- Add to each execution step: "Consider applicable dimensions per the Development Dimensions Guide"

**Bug Fixing (PF-TSK-007)**:
- Add to Preparation: "Read the affected dimensions from the bug tracking entry or bug fix state file"
- Add to Fix Implementation: "Verify the fix addresses all affected dimensions (e.g., if Observability is flagged, ensure the fix includes proper logging)"
- Add to Validation: "Confirm dimension-specific requirements are met"

**Data Layer Implementation (PF-TSK-051)**:
- Add to Preparation: "Review Data Integrity and Security dimensions from feature profile"

**Code Refactoring (PF-TSK-022)**:
- Add to Preparation: "Read affected dimensions from the tech debt item"
- Add to Validation: "Verify improvement along the flagged dimensions"

**Foundation Feature Implementation (PF-TSK-024)**:
- Already has automated dimension validation — add explicit dimension profile review in preparation step to align automated checks with the feature's identified dimensions

#### Verification Phase Tasks

**Code Review (PF-TSK-005)**:
- Add to Preparation: "Read the feature's/bug's dimension profile to focus review"
- Add to Review Checklist: "Verify dimension-specific considerations from the Development Dimensions Guide were addressed"
- This makes reviews more targeted — a security-flagged change gets deeper security review

**Integration & Testing (PF-TSK-053)**:
- Add to Test Planning: "Ensure test coverage addresses identified dimensions (e.g., if Performance is flagged, include performance regression tests)"

**Test Specification Creation (PF-TSK-016)**:
- Add to Specification Scope: "Include test scenarios for each applicable dimension from the feature's dimension profile"

### Component 5: Validation Task Alignment

The Validation Preparation task (PF-TSK-077) currently performs its own dimension applicability evaluation. With this proposal:

- **Validation Preparation** would **verify and update** the dimension profiles established during planning, rather than evaluating from scratch
- If a feature's dimension profile is missing (legacy features, pre-integration work), Validation Preparation falls back to its current full evaluation
- The dimension applicability matrix in validation tracking would reference the tier assessment as its source

This creates a natural feedback loop: validation may discover that a dimension was incorrectly marked N/A during planning, triggering an update to the feature's dimension profile for future work.

## Dimension Completeness Assessment

### Current 11 Dimensions — Assessment

The current dimension set is comprehensive and well-structured. After analysis, the following observations:

**Dimensions that are well-defined and complete:**
- Architectural Consistency, Code Quality, Integration & Dependencies, Documentation Alignment — solid core dimensions
- Security & Data Protection, Performance & Scalability, Data Integrity — clear scope and applicability criteria
- Extensibility & Maintainability — important for growing projects

**Dimensions to review for potential restructuring:**

1. **Error Handling & Resilience**: Currently distributed across Code Quality (error handling practices), Data Integrity (error recovery), and Performance (failure modes). Consider whether this deserves its own dimension or whether the current distribution is sufficient. For LinkWatcher specifically, error handling is a major concern (file system operations fail frequently) — but this may not justify a universal dimension.

2. **Testing Quality**: Testing is handled by separate task families (Test Specification, Test Audit, Integration & Testing) rather than as a validation dimension. This seems correct — testing is a process concern, not a code quality dimension. No change recommended.

3. **AI Agent Continuity**: This dimension is project-specific (only relevant when using AI-assisted development). Consider whether it should remain a standard dimension or become a project-level configuration option. For the process framework itself it's valuable; for projects that don't use AI agents, it's noise.

**Recommendation**: No restructuring needed. The 11 dimensions cover the quality landscape well. The distributed handling of error handling/resilience is appropriate since different aspects of resilience genuinely belong to different dimensions. If a future project consistently finds gaps, a new dimension can be added — but the current set shouldn't be expanded speculatively.

### Potential Future Dimension: Backward Compatibility

For projects with external consumers (APIs, libraries, SDKs), a **Backward Compatibility** dimension could be valuable (API versioning, deprecation handling, migration paths). Not applicable to LinkWatcher currently but worth noting as a candidate for framework extension.

## Implementation Approach

### Recommended Sequence

This is a cross-cutting structural change affecting ~15 task definitions, ~5 state tracking templates, 1 new guide, and the validation guide. Recommended phased implementation:

**Phase 1: Foundation**
1. Create the Development Dimensions Guide (Component 1)
2. Update the Feature Tier Assessment task (Component 2) — this establishes the source of truth
3. Update feature-tracking.md with Dimensions column (Component 3a)
4. Backfill dimension profiles for existing 9 features

**Phase 2: State Tracking Integration**
5. Update Feature Implementation State File template + backfill existing files (Component 3b)
6. Update Enhancement State Tracking template (Component 3c)
7. Update Bug Tracking + Bug Fix State templates (Component 3d, 3e)
8. Update Technical Debt Tracking (Component 3f)

**Phase 3: Task Definition Updates**
9. Update planning phase tasks (Tier Assessment, Feature Request Evaluation, Bug Triage, Implementation Planning)
10. Update execution phase tasks (Core Logic, Feature Enhancement, Bug Fixing, Data Layer, Refactoring)
11. Update verification phase tasks (Code Review, Integration & Testing, Test Spec Creation)

**Phase 4: Validation Alignment**
12. Update Validation Preparation to reference dimension profiles rather than evaluating from scratch
13. Update feature-validation-guide.md to reference the new Development Dimensions Guide for definitions

### Execution Method

Each phase could be executed as a **Structure Change** (PF-TSK-015) or **Process Improvement** (PF-TSK-009) task. Phase 3 is the largest and might need multiple sessions given the number of task definitions to update.

## Risks & Considerations

1. **Overhead**: Adding dimension evaluation to every tier assessment and bug triage adds process weight. Mitigation: Keep the evaluation lightweight — the 4 core dimensions are always-on (no evaluation needed), and the 7 extended dimensions use simple yes/no criteria.

2. **Stale profiles**: Dimension profiles might become outdated as features evolve. Mitigation: Validation rounds serve as the correction mechanism — update profiles when validation finds mismatches.

3. **Over-engineering for simple work**: A simple typo fix doesn't need dimension analysis. Mitigation: Only Bug Triage (not every bug fix) performs dimension identification. Small-scope bugs (S) get a quick dimension tag; only Large-scope bugs get detailed dimension analysis in state files.

4. **Template bloat**: Adding dimension sections to all state templates increases template size. Mitigation: Keep sections concise — the dimension profile is a small table, not a detailed analysis.

## Open Questions

1. Should the Development Dimensions Guide include project-specific examples (LinkWatcher-focused) or remain fully generic (portable to other projects using the framework)?
2. Should the Dimensions column in feature-tracking.md show all 11 dimensions or only the applicable extended ones (since core 4 are always implied)?
3. Should there be a lightweight "dimension review" step in the Definition of Done, or is the task-level integration sufficient?

## Next Steps

- [ ] Human review and feedback on this proposal
- [ ] Decide on open questions
- [ ] If approved, create Structure Change state file for phased implementation
