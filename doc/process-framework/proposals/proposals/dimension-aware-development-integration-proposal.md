---
id: PF-PRO-013
type: Document
category: Proposal
version: 4.0
created: 2026-03-30
updated: 2026-03-30
proposal_status: Approved
---

# Proposal: Dimension-Aware Development Integration

## Overview

Integrate validation dimensions into the development lifecycle — from planning through execution to review — so that quality concerns are **designed for** during development rather than only **discovered** during post-implementation validation rounds.

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

---

## Design Decisions

### D1: Dimension Importance Scoring — Lightweight 3-Level Scale

Rather than a full numerical scoring system per dimension per feature, use a **3-level importance scale**:

| Level | Meaning | Example |
|-------|---------|---------|
| **Critical** | Dimension is central to the feature's quality; failure here is a showstopper | Security for a feature handling user file paths |
| **Relevant** | Dimension applies but isn't a primary concern; good practice to address | Performance for a feature that does occasional I/O |
| **N/A** | Dimension does not apply to this feature | Accessibility for a backend-only CLI tool |

**Why not numerical?** Full numeric scoring (1-10) creates false precision at the planning stage where you don't yet know how the implementation will look. The 3-level scale gives enough signal to focus implementation and review attention (Critical dimensions get deeper review, Relevant ones get checklist treatment) without turning planning into a scoring exercise.

The **validation phase** retains its existing 0-3 scoring system — that's where detailed numerical assessment is appropriate because the code exists and can be measured.

### D2: Tier Assessment and Dimensions Are Orthogonal

The current tier assessment answers: **"How much documentation does this feature need?"** (driven by overall complexity). Dimensions answer: **"What quality aspects matter for this feature?"** These are independent concerns:

- A simple Tier 1 feature (e.g., config file parser) can have **Critical** Security and Data Integrity dimensions
- A complex Tier 3 feature (e.g., core architecture) might have **N/A** Accessibility

**Tiers should not be assigned based on dimensions** and dimensions should not be derived from tiers. They are evaluated at similar points in the workflow but remain independent outputs.

### D3: Dimension Ownership — Feature Implementation State File, Not Tier Assessment

The tier assessment's single responsibility is determining documentation depth. Bolting dimension evaluation onto it muddies its purpose. Instead:

- **For new features**: **Feature Implementation Planning** (PF-TSK-044) evaluates dimensions when creating the implementation plan. At this point, the FDD/TDD context exists and the implementation scope is clear — this is when dimension applicability can be meaningfully assessed.
- **For enhancements**: **Feature Request Evaluation** (PF-TSK-067) inherits the parent feature's dimension profile and adjusts for the enhancement scope.
- **For bugs**: **Bug Triage** (PF-TSK-006) identifies which dimensions the bug affects.

The **feature implementation state file** is the single source of truth for dimension profiles. It's the working reference during implementation and the handoff artifact between tasks.

### D4: AI Agent Continuity — Remove as Dimension, Keep as Validation Task

AI Agent Continuity does not provide sufficient independent value as a dimension. Analysis of what it checks:

| AI Continuity Criterion | Already Covered By |
|------------------------|-------------------|
| Code readability, naming conventions | CQ (Code Quality) |
| Modular structure, file sizes | EM (Extensibility & Maintainability) |
| Documentation clarity, state files | DA (Documentation Alignment) |
| Context window optimization | Unique — but niche |
| Continuation points | Unique — but niche |

The two genuinely unique aspects (context window optimization, continuation points) are valuable as a periodic check but not significant enough to warrant a dimension that flows through planning → implementation → review. They are better served as criteria within the **AI Agent Continuity validation task** (PF-TSK-036), which remains as a standalone validation task.

**Proposal**:
- **Remove AI from the dimension list entirely** — the framework has **10 dimensions**, not 11
- **Keep PF-TSK-036** as a validation task that can be run during validation rounds for projects using AI-assisted development
- The Development Dimensions Guide covers 10 dimensions; the validation task family has 11 tasks (10 dimension-aligned + 1 standalone AI continuity check)
- `AI` is no longer a valid dimension abbreviation; remove from tech debt ValidateSet

**Valid dimension abbreviations**: AC, CQ, ID, DA, EM, SE, PE, OB, UX, DI (+ TST for tech debt only)

### D4a: Phase Applicability of the 10 Development Dimensions

All 10 development dimensions are carried through all phases, but their **meaning and evaluation depth** varies:

| Dimension | Planning | Implementation | Review | Validation |
|-----------|----------|---------------|--------|------------|
| AC | Identify patterns to follow | Follow patterns | Check patterns | Deep assessment |
| CQ | Identify standards | Follow checklist | Check compliance | Deep assessment |
| ID | Identify integration points | Test boundaries | Check contracts | Deep assessment |
| DA | "What docs will we need?" | Keep docs in sync | Check accuracy | Deep assessment |
| EM | Identify extension points | Design for extensibility | Check modularity | Deep assessment |
| SE | "Handles user input?" | Follow checklist | Focused review | Deep assessment |
| PE | "I/O at scale?" | Follow checklist | Check hot paths | Deep assessment |
| OB | "Background process?" | Add logging | Check coverage | Deep assessment |
| UX | "Has UI?" | Follow standards | Check compliance | Deep assessment |
| DI | "Modifies data?" | Follow checklist | Check atomicity | Deep assessment |

**Planning-strong** (answerable immediately): SE, PE, UX, DI, OB
**Planning-limited** (can identify scope but not assess compliance): DA, CQ, ID

### D5: Phase-Appropriate Dimension Interpretation

Not all dimensions mean the same thing at every stage. The Development Dimensions Guide must define **what each dimension means at each phase**:

| Phase | What dimension evaluation means | Example: Documentation Alignment |
|-------|-------------------------------|----------------------------------|
| **Planning** | "Is this dimension applicable? What priority?" | "FDD + TDD will be needed (Tier 2)" |
| **Implementation** | "Am I actively addressing this dimension's checklist?" | "Keep docs in sync as I code" |
| **Review** | "Were dimension requirements met?" | "Do code comments match TDD descriptions?" |
| **Validation** | "Deep quality assessment against dimension criteria" | "Full TDD/FDD alignment scoring" |

**Dimensions where planning-phase evaluation is limited:**
- **DA**: Can't check alignment when docs don't exist yet → "identify which docs will be needed"
- **CQ**: Can identify standards, but can't assess compliance before code exists
- **ID**: Can identify integration points, but can't validate contracts pre-implementation

**Dimensions where planning-phase evaluation is strong:**
- **SE**: "Does this feature handle user input?" — answerable immediately
- **PE**: "Does this feature do I/O on large datasets?" — answerable immediately
- **UX**: "Does this feature have a UI?" — answerable immediately

### D6: Technical Debt Categories → Unified Dimension Vocabulary

The current tech debt categories overlap ~80% with dimensions:

| Current TD Category | Maps to Dimension |
|--------------------|--------------------|
| Architectural | AC |
| Code Quality | CQ |
| Integration | ID |
| Documentation | DA |
| Performance | PE |
| Security | SE |
| Accessibility + UX | UX |
| Data Integrity | DI |
| Observability | OB |
| **Testing** | **No dimension equivalent** |

**Proposal**: Replace the Category column with **Primary Dimension** using standard abbreviations, plus an **Additional Dimensions** column for secondary impacts. Add **TST** (Testing) as a valid value — it's a legitimate tech debt category even though it's not a quality dimension.

**Valid values**: AC, CQ, ID, DA, EM, SE, PE, OB, UX, DI, TST

**Migration**: ~122 resolved items keep old category names (historical). Only 2 active items (TD128, TD129 — both PE) need migration. Update `Update-TechDebt.ps1` ValidateSet.

### D7: Tier-Dependent Workflows That Benefit from Dimension Awareness

Currently 14 decision points in the framework branch on tier. Most are correctly tier-based (documentation depth), but some would benefit from dimension input:

| Current Tier-Based Decision | Dimension Improvement |
|----------------------------|----------------------|
| TDD quality attribute sections: Tier 3 = "comprehensive" | Dimension profile guides **which** attributes to detail — see D10 |
| Test depth: Tier 3 = full suite | A Tier 1 feature with Critical DI needs data integrity tests regardless of tier |
| Test Specification required: Tier 3 only | A Tier 2 feature with Critical SE + PE could benefit from a focused test spec |

These are **not replacements** — tier controls depth/volume, dimensions control **which topics** get attention within that depth. The proposal adds dimension awareness as a secondary input to these decisions without removing tier as the primary gate.

### D10: TDD Quality Attributes — Dimension-Informed, Not Dimension-Structured

A TDD answers "how will this be built?" — its structure follows the architecture: component design, data models, interfaces, error handling. **TDDs should NOT be restructured around dimensions.** Dimensions are a quality lens, not an organizational principle.

Where dimensions and TDDs intersect is the **Quality Attributes** section. Currently, tier controls depth:
- Tier 1: brief quality notes
- Tier 2: quality requirements with implementation approach
- Tier 3: comprehensive quality attributes with measurement

**Proposed change**: For each **Critical** dimension in the feature's dimension profile, treat the corresponding quality attribute subsection with **one tier higher depth** than the feature's base tier:

| Base Tier | N/A Dimension | Relevant Dimension | Critical Dimension |
|-----------|--------------|-------------------|-------------------|
| Tier 1 | Omit subsection | Tier 1 depth (brief note) | **Tier 2 depth** (requirements + approach) |
| Tier 2 | Omit subsection | Tier 2 depth (standard) | **Tier 3 depth** (comprehensive + measurement) |
| Tier 3 | Omit subsection | Tier 3 depth (standard) | Tier 3 depth (already maximum) |

**Example**: A Tier 2 feature with Critical SE and Critical PE:
- Security Design section → Tier 3 depth (threat model, input validation strategy, measurement criteria)
- Performance Design section → Tier 3 depth (complexity targets, benchmarking approach, resource budgets)
- Accessibility Design section → Omitted (N/A for CLI tool)
- Observability Design section → Tier 2 depth (Relevant — standard logging approach)

This keeps the TDD's natural structure intact (it's still organized by architecture, not by dimension) while ensuring that quality attributes critical to the feature get adequate design attention regardless of the overall tier.

**Mapping: Dimensions → TDD Quality Attribute Subsections**

| Dimension | TDD Quality Attribute Subsection |
|-----------|--------------------------------|
| SE | Security Design (threat model, input validation, auth, secrets) |
| PE | Performance Design (complexity targets, I/O strategy, resource budgets) |
| DI | Data Integrity Design (atomicity, consistency, error recovery, backup) |
| OB | Observability Design (logging strategy, error tracing, monitoring hooks) |
| UX | Accessibility Design (standards compliance, keyboard nav, screen reader) |
| AC | Architecture Compliance (pattern adherence — usually covered in main TDD body) |
| EM | Extensibility Design (plugin points, configuration, upgrade paths) |
| ID | Integration Design (API contracts, dependency management — usually covered in main TDD body) |
| CQ | Coding Standards (usually referenced, not detailed in TDD) |
| DA | N/A — DA is about documentation itself, not a TDD content area |

Not all dimensions map to TDD subsections equally. AC, ID, and CQ are typically covered in the main TDD body (component design, interfaces, coding notes) rather than in a dedicated quality attribute subsection. DA has no TDD representation — it's about the documentation itself. The dimension-informed depth rule primarily benefits SE, PE, DI, OB, UX, and EM.

### D8: No Dimensions Column in Feature Tracking

The feature-tracking.md table already has 12 columns and serves as a **status dashboard**, not a working reference. Adding a Dimensions column would:
- Bloat an already dense table
- Duplicate what's in the feature implementation state file (the actual working reference)
- Create yet another field to maintain in sync
- Save Validation Preparation one click at most (they already read state files)

**Proposal**: The feature implementation state file is the sole home for dimension profiles. Feature-tracking.md does not get a Dimensions column. If at-a-glance visibility is needed later, it can be added, but start without it.

### D9: Definition of Done — Deprecation Candidate

The Definition of Done (PF-MTH-001) has light usage — only 2 of 50+ task definitions reference it. Most tasks have their own embedded checklists. With dimension-aware integration:

- Dimension checklists in the Development Dimensions Guide replace its quality criteria
- Task-specific completion checklists already cover process requirements

**Proposal**: Flag as deprecation candidate. Don't integrate dimensions into it. Evaluate during Phase 4 whether to archive.

---

## Proposed Solution

### Component 1: Universal Development Dimensions Guide

Create `doc/process-framework/guides/framework/development-dimensions-guide.md` as the **single authoritative reference** for all 10 dimensions across all task phases.

**Content structure per dimension:**

```markdown
### [Dimension Name] ([ABBR])

**Definition**: [1-2 sentences]
**Applicability**: [When this dimension is relevant]

#### Phase-Specific Guidance

**Planning** (Implementation Planning / Triage):
- [2-3 bullet points: what to identify at this stage]

**Implementation** (Coding / Enhancement / Bug Fixing):
- [ ] [5-8 checklist items — concrete, verifiable]

**Review** (Code Review / Testing):
- [3-5 focus points for reviewers]

#### Common Anti-Patterns
- [2-3 examples of what goes wrong when this dimension is ignored]
```

**Design principles:**
- **Concise**: Each dimension ~15-20 lines. Full guide fits in one context window
- **Actionable**: Checklists, not essays
- **Phase-aware**: Different guidance per phase (see D5)
- **Generic**: No project-specific examples — portable to any project

**Relationship to existing validation guide**: The `feature-validation-guide.md` references this guide for definitions and applicability criteria but retains its own scoring methodology, thresholds, and reporting templates. Both guides cover the same 10 dimensions. The AI Agent Continuity validation task (PF-TSK-036) is a standalone task not backed by a dimension (see D4).

**Dimension abbreviation standard** (used framework-wide):

| Abbr | Dimension | Core/Extended |
|------|-----------|---------------|
| AC | Architectural Consistency | Core |
| CQ | Code Quality & Standards | Core |
| ID | Integration & Dependencies | Core |
| DA | Documentation Alignment | Core |
| EM | Extensibility & Maintainability | Extended |
| SE | Security & Data Protection | Extended |
| PE | Performance & Scalability | Extended |
| OB | Observability | Extended |
| UX | Accessibility / UX Compliance | Extended |
| DI | Data Integrity | Extended |

### Component 2: Dimension Evaluation Ownership

#### New Features: Feature Implementation Planning (PF-TSK-044)

When creating the implementation plan, evaluate dimension applicability:
1. Core dimensions (AC, CQ, ID, DA) are always **Relevant** or **Critical** — no evaluation needed
2. For the 6 extended dimensions (EM, SE, PE, OB, UX, DI), apply the "Apply When" criteria
3. Assign importance: **Critical** / **Relevant** / **N/A** (with rationale for extended)
4. Record the dimension profile in the **feature implementation state file**

This is the right point because the planner has read the tier assessment, FDD, TDD, and understands the implementation scope.

#### Enhancements: Feature Request Evaluation (PF-TSK-067)

When classifying as enhancement:
1. Inherit the parent feature's dimension profile from its implementation state file
2. Evaluate if the enhancement scope changes applicability (adds SE concerns, removes UX, etc.)
3. Record the adjusted profile in the **Enhancement State Tracking File**

#### Bugs: Bug Triage (PF-TSK-006)

During severity/scope assessment:
1. Identify which dimensions the bug **affects** (subset identification)
2. Record affected dimensions in the **bug-tracking.md** Dims column
3. For Large-scope bugs: detailed dimension context in the **Bug Fix State File**

### Component 3: State Tracking File Changes

#### 3a. Feature Implementation State Files (PRIMARY DIMENSION HOME)

Add a **Dimension Profile** section (after Section 6: Dependencies, before Section 7: Design Decisions):

```markdown
## Dimension Profile

Source: Feature Implementation Planning | Last reviewed: YYYY-MM-DD

### Applicable Dimensions
| Dimension | Importance | Key Considerations |
|-----------|-----------|-------------------|
| Security & Data Protection (SE) | Critical | Validate path traversal, sanitize inputs |
| Performance & Scalability (PE) | Critical | Batch operations, avoid O(n²) scans |
| Data Integrity (DI) | Critical | Ensure backup before write, handle partial failures |
| Observability (OB) | Relevant | Log error paths and recovery actions |
| Extensibility & Maintainability (EM) | Relevant | Parser registry pattern for new formats |

### Not Applicable
| Dimension | Rationale |
|-----------|-----------|
| Accessibility / UX (UX) | No UI components — CLI tool |
```

This is the **single source of truth** and **working reference** during implementation.

#### 3b. Enhancement State Tracking Files

Add a **Dimension Impact Assessment** section before the Execution Steps:

```markdown
## Dimension Impact Assessment

Inherited from parent feature (0.1.3): AC CQ ID DA **SE** **PE** OB EM
**Additional for this enhancement**: DI (Critical) — enhancement adds file write operations
**Reduced for this enhancement**: none

### Key Dimension Considerations
- **Security (SE)**: New config options must validate input values against allowlist
- **Performance (PE)**: New ignore patterns evaluated on every file event — must be O(1) lookup
- **Data Integrity (DI)**: Config file writes must be atomic
```

#### 3c. Bug Tracking (bug-tracking.md)

Add a **Dims** column to the bug registry tables. Content: abbreviations of affected dimensions (e.g., `SE DI`). Populated during Bug Triage.

#### 3d. Bug Fix State Tracking Files

Add dimension context to the **Root Cause Analysis** section:

```markdown
### Affected Dimensions
- **Data Integrity (DI)**: Bug causes silent data loss during concurrent writes
- **Observability (OB)**: No logging when the race condition occurs — failure is invisible

### Dimension-Informed Fix Requirements
- Fix must include atomicity guarantee (DI)
- Fix must add logging for concurrent access attempts (OB)
```

#### 3e. Technical Debt Tracking (technical-debt-tracking.md)

**Replace** the Category column with **Primary Dimension** (abbreviation) + **Additional Dimensions** column. See D6 for migration details.

### Component 4: Task Definition Changes

#### Planning Phase Tasks

**Feature Implementation Planning (PF-TSK-044)** — PRIMARY DIMENSION EVALUATION POINT:
- Add Step: "Evaluate Dimension Applicability" using the Development Dimensions Guide
- Add Step: Map Critical dimensions to specific implementation tasks as acceptance criteria
- Add Output: Dimension Profile in the feature implementation state file

**Feature Request Evaluation (PF-TSK-067)**:
- Add Step (enhancement path): Inherit parent feature's dimension profile
- Add Step: Evaluate if enhancement scope changes dimension applicability
- Add Output: Dimension Impact Assessment in Enhancement State Tracking File

**Bug Triage (PF-TSK-006)**:
- Add Step: "Identify Affected Dimensions" during severity/scope assessment
- Add Output: Dims column in bug-tracking.md entry
- For Large-scope bugs: Dimension context in Bug Fix State File

**Technical Debt Assessment (cyclical)**:
- Add Step: Tag each debt item with Primary Dimension + Additional Dimensions
- Enables prioritization by dimension impact (SE-tagged debt ranks higher)

#### Execution Phase Tasks

**Core Logic Implementation (PF-TSK-078)**:
- Preparation: "Read the feature's Dimension Profile from the implementation state file"
- Execution: "Before marking module complete, verify Critical dimensions are addressed using the Development Dimensions Guide implementation checklist"
- Bug Discovery: "Tag discovered bugs with affected dimensions"

**Feature Enhancement (PF-TSK-068)**:
- Preparation: "Read the Dimension Impact Assessment from the Enhancement State Tracking File"
- Execution: "Consider applicable dimensions per the Development Dimensions Guide"

**Bug Fixing (PF-TSK-007)**:
- Preparation: "Read the affected dimensions from the bug tracking entry or bug fix state file"
- Implementation: "Verify the fix addresses all affected dimensions"
- Validation: "Confirm dimension-specific requirements are met"

**Data Layer Implementation (PF-TSK-051)**:
- Preparation: "Review DI and SE dimensions from feature profile"

**Code Refactoring (PF-TSK-022)**:
- Preparation: "Read Primary/Additional Dimensions from the tech debt item"
- Validation: "Verify improvement along the flagged dimensions"

**Foundation Feature Implementation (PF-TSK-024)**:
- Already has automated dimension validation — add explicit dimension profile review to align automated checks with the feature's identified dimensions

#### Verification Phase Tasks

**Code Review (PF-TSK-005)**:
- Preparation: "Read the feature's/bug's dimension profile to focus review"
- Review: "Verify Critical dimension considerations were addressed using the Development Dimensions Guide review focus points"

**Integration & Testing (PF-TSK-053)**:
- Test Planning: "Ensure test coverage addresses Critical dimensions"

**Test Specification Creation (PF-TSK-016)**:
- Scope: "Include test scenarios for Critical dimensions from the feature's dimension profile"

#### Tier-Informed Dimension Additions (D7)

These existing tier-dependent decisions gain dimension awareness as a **secondary input**:

**TDD Creation (PF-TSK-003)**:
- Quality attribute subsections guided by dimension profile (see D10). For each Critical dimension, treat the corresponding subsection with one tier higher depth. A Tier 2 feature with Critical SE gets Tier 3 depth security design (threat model, input validation strategy, measurement criteria) while the rest of the TDD follows Tier 2 depth.

**Test Specification Creation (PF-TSK-016)**:
- Consider creating focused test specs for Tier 1/2 features with Critical SE, PE, or DI dimensions, even though test specs are currently only required for Tier 3.

**Integration & Testing (PF-TSK-053)**:
- Test depth informed by dimension importance, not just tier. Critical PE → include performance regression tests regardless of tier.

### Component 5: Validation Task Alignment

**Validation Preparation** (PF-TSK-077) currently performs its own dimension applicability evaluation. With this proposal:

- Validation Preparation would **verify and update** the dimension profiles from implementation state files, rather than evaluating from scratch
- If a feature's dimension profile is missing (legacy features, pre-integration work), fall back to current full evaluation
- The dimension applicability matrix references the implementation state file as its source

This creates a **feedback loop**: validation may discover that a dimension was incorrectly marked N/A during planning → update the feature's dimension profile for future work.

### Component 6: Template, Script, and Guide Changes

This structural change has significant impact on supporting infrastructure. **These must be updated alongside the task definitions and state files — not as an afterthought.**

#### Templates Requiring Changes (5)

| Template | Change |
|----------|--------|
| `templates/04-implementation/feature-implementation-state-template.md` | Add Dimension Profile section (Section 6.5) |
| `templates/04-implementation/enhancement-state-tracking-template-template.md` | Add Dimension Impact Assessment section |
| `templates/06-maintenance/bug-fix-state-tracking-template.md` | Add Affected Dimensions to Root Cause Analysis |
| `templates/05-validation/validation-tracking-template.md` | Add "Source: Implementation State File" reference |
| `templates/05-validation/validation-report-template.md` | Add "Dimensions Validated" field |

#### Automation Scripts Requiring Changes (10)

**File creation scripts (4):**

| Script | Change |
|--------|--------|
| `New-FeatureImplementationState.ps1` | Add `-DimensionProfile` parameter; populate Dimension Profile section |
| `New-EnhancementState.ps1` | Add `-InheritedDimensions` parameter; populate Dimension Impact Assessment |
| `New-BugFixState.ps1` | Add `-AffectedDimensions` parameter; populate Affected Dimensions section |
| `New-BugReport.ps1` | Add `-Dimensions` parameter; populate Dims column |

**Update scripts (4):**

| Script | Change |
|--------|--------|
| `Update-TechDebt.ps1` | Replace Category ValidateSet with dimension abbreviations + TST; rename column |
| `Update-FeatureRequest.ps1` | Pass inherited dimensions when creating Enhancement State files |
| `Update-BugStatus.ps1` | Preserve/update Dims column during status transitions |
| `Update-FeatureImplementationState.ps1` | Support dimension-specific progress notes |

**Validation scripts (2):**

| Script | Change |
|--------|--------|
| `Validate-StateTracking.ps1` | Add Surface 7: Dimension Consistency (verify profiles exist and use valid abbreviations) |
| `validate-id-registry.ps1` | No change expected |

#### Guides Requiring Changes (5 existing + 1 new)

| Guide | Change |
|-------|--------|
| **NEW: `development-dimensions-guide.md`** | Create as Component 1 |
| `feature-validation-guide.md` | Reference new guide for definitions; update Dimension Catalog to 10 dimensions; document AI continuity task as standalone |
| `feature-implementation-state-tracking-guide.md` | Add "Understanding Dimension Profiles" section |
| `enhancement-state-tracking-customization-guide.md` | Add dimension inheritance guidance |
| `code-refactoring-task-usage-guide.md` | Add dimension-aware refactoring guidance |
| `tdd-creation-guide.md` | Add dimension-informed quality attribute depth rules (D10) |

---

## Dimension Completeness Assessment

### 10 Dimensions — Assessment

**Well-defined and complete:**
- Core 4 (AC, CQ, ID, DA) — solid universal dimensions
- SE, PE, DI — clear scope and applicability criteria
- EM, OB — well-scoped extended dimensions
- UX — clear applicability criteria (UI-facing features)

**Removed:**
- **AI Agent Continuity** → Removed as dimension (see D4). Its unique criteria (context window optimization, continuation points) are retained as criteria within the standalone validation task PF-TSK-036, which continues to exist but is no longer backed by a dimension. During development, AI continuity concerns collapse into CQ (readability, naming), EM (modularity, file sizes), and DA (documentation clarity).

**Considered but rejected as new dimensions:**
- **Error Handling & Resilience**: Distributed across CQ (practices), DI (recovery), PE (failure modes). Distribution is appropriate.
- **Testing Quality**: Handled by task families, not a code quality dimension. TST added as tech debt category only.
- **Backward Compatibility**: Relevant for API-facing projects. Can be added as project-specific dimension if needed.

**Recommendation**: 10 dimensions is the right count. Future projects can extend with project-specific dimensions if needed.

---

## Implementation Approach

### Recommended Sequence

Cross-cutting structural change affecting ~15 task definitions, 5 templates, 10 scripts, 6 guides, and 2 permanent state tracking files.

**Phase 1: Foundation (Guide + Working Reference)**
1. Create the Development Dimensions Guide (Component 1)
2. Update Feature Implementation State template with Dimension Profile section
3. Update `New-FeatureImplementationState.ps1` to accept dimension parameters
4. Backfill dimension profiles for existing 9 feature implementation state files

**Phase 2: State Tracking Integration (Templates + Scripts)**
5. Update Enhancement State Tracking template + `New-EnhancementState.ps1`
6. Update Bug Tracking + Bug Fix State templates + `New-BugReport.ps1` + `New-BugFixState.ps1`
7. Replace tech debt Category with Primary Dimension + `Update-TechDebt.ps1`
8. Add Validate-StateTracking.ps1 Surface 7: Dimension Consistency

**Phase 3: Task Definition Updates**
9. Planning tasks: Feature Implementation Planning (primary), Feature Request Evaluation, Bug Triage, Tech Debt Assessment
10. Execution tasks: Core Logic, Feature Enhancement, Bug Fixing, Data Layer, Refactoring, Foundation Feature
11. Verification tasks: Code Review, Integration & Testing, Test Spec Creation
12. Tier-informed additions: TDD Creation, Test Specification (D7 changes)

**Phase 4: Validation Alignment + Cleanup**
13. Update Validation Preparation to reference dimension profiles from state files
14. Update feature-validation-guide.md to reference Development Dimensions Guide; reduce to 10 dimensions; document AI continuity task as standalone
15. Update remaining guides (implementation state tracking, enhancement customization, refactoring)
16. Evaluate Definition of Done for deprecation

### Execution Method

Each phase as a **Structure Change** (PF-TSK-015) task. Phase 2 and 3 are the largest — expect multiple sessions each.

---

## Risks & Considerations

1. **Overhead**: Adding dimension evaluation to implementation planning and bug triage adds process weight. Mitigation: Core dimensions are always-on (no evaluation); extended dimensions use simple yes/no criteria with a 3-level importance scale.

2. **Stale profiles**: Dimension profiles may become outdated as features evolve. Mitigation: Validation rounds serve as the correction mechanism — update profiles when validation finds mismatches.

3. **Over-engineering for simple work**: A simple typo fix doesn't need dimension analysis. Mitigation: Only Bug Triage (not every bug fix) performs dimension identification. Small-scope (S) bugs get a quick dimension tag; only Large-scope bugs get detailed analysis.

4. **Script migration complexity**: 10 scripts need updates, some with new parameters. Mitigation: Phase 2 handles scripts alongside their templates, ensuring consistency. Each script change is testable in isolation.

5. **Backward compatibility**: Existing state files and tech debt items use old formats. Mitigation: Backfill in Phase 1-2; archive entries left as-is with migration note.

---

## Open Questions

All previous open questions have been resolved through design decisions D3-D9.

---

## Decision Log

| # | Question | Decision | Rationale |
|---|----------|----------|-----------|
| D1 | Numerical importance scoring? | 3-level scale (Critical/Relevant/N/A) | Numeric creates false precision at planning stage |
| D2 | Derive tier from dimensions? | No — orthogonal concerns | Tier = documentation depth; dimensions = quality aspects |
| D3 | Tier assessment as dimension source? | No — Feature Implementation Planning owns it | Tier assessment's job is documentation depth; implementation planning has full context |
| D4 | Keep AI Agent Continuity as dimension? | No — remove entirely, keep validation task | Collapses into CQ+EM+DA during development; unique value only in periodic validation |
| D4a | Which dimensions at which phases? | All 10 at all phases, with phase-specific meaning | Planning-strong (SE, PE, UX, DI, OB) vs planning-limited (DA, CQ, ID) |
| D5 | Same meaning per phase? | No — phase-specific interpretation | Guide must define what each dimension means at each phase |
| D6 | Replace tech debt Category? | Yes — unified vocabulary with TST added | 80% overlap; unification reduces cognitive load |
| D7 | Tier-dependent workflows? | Add dimension as secondary input | Tier controls depth; dimensions control which topics |
| D8 | Dimensions in feature-tracking.md? | No — feature state file is sufficient | Table already dense; avoid duplication |
| D9 | Definition of Done integration? | Deprecation candidate | Superseded by dimension checklists + task-specific checklists |
| D10 | TDD structure based on dimensions? | No — dimension-informed quality attribute depth | TDD structure follows architecture; dimensions control depth of quality attribute subsections |
| Q1 | Project-specific examples in guide? | Generic — portable | Framework should work for any project |

---

## Next Steps

- [x] Human review and feedback on this proposal — **Approved 2026-03-30**
- [ ] Create Structure Change state file for phased implementation (Phase 1-4)
