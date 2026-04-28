---
id: PF-TEM-068
type: Process Framework
category: Template
version: 1.1
created: 2026-04-04
updated: 2026-04-04
creates_document_prefix: PD-FIS
creates_document_version: 1.0
description: Lightweight template for Tier 1 feature implementation state tracking — fewer sections, optimized for simple features and retrospective analysis
creates_document_type: Process Framework
usage_context: Process Framework - Feature State Tracking (Lightweight)
creates_document_category: Feature Implementation State
template_for: Feature State Tracking (Lightweight)
---

# [Feature Name] - Implementation State

> **📖 Usage guide**: [Feature Implementation State Tracking Guide (PF-GDE-043)](../../guides/04-implementation/feature-implementation-state-tracking-guide.md)
>
> **Lightweight variant** — used for Tier 1 features and retrospective analysis. For Tier 2/3 features, use the [full template](feature-implementation-state-template.md).

---

## 1. Feature Overview

### Feature Description

[2-3 paragraph description of what this feature does and why it exists]

### Business Value

- **User Need**: [What problem this solves for users]
- **Business Goal**: [What business objective this achieves]

### Scope

**In Scope**:

- [Capability 1]
- [Capability 2]
- [Capability 3]

**Out of Scope**:

- [Capability explicitly excluded]
- [Capability deferred to future work]

---

## 2. Current State Summary

**Last Updated**: [YYYY-MM-DD HH:MM]
**Current Status**: [PLANNING | IN_PROGRESS | TESTING | COMPLETE | DEPLOYED | MAINTAINED]
**Current Task**: [PF-TSK-XXX: Task Name]

### What's Working

- [✓] [Completed capability 1]
- [✓] [Completed capability 2]

### What's In Progress

- [⚙] [Current work item 1]

### What's Blocked

- [🚫] [Blocker 1 - description and owner]

---

## 3. Documentation Inventory

### Design Documentation

| Document   | Type        | Status   | Location | Last Updated |
| ---------- | ----------- | -------- | -------- | ------------ |
| [Doc name] | Design Spec | [STATUS] | [path]   | YYYY-MM-DD   |

### User Documentation

> **Trigger for [User Documentation Creation](../../../process-framework/tasks/07-deployment/user-documentation-creation.md)**: When this feature has user-visible behavior, identify required Diátaxis content types (tutorials/how-to/reference/explanation) during PF-TSK-081's analysis step, then add one row per required content type with Status `❌ Needed`. The task resolves each row to `✅ Created` with a link. Use `N/A` for internal-only features. Feature is `🟢 Completed` only when ALL rows are `✅ Created`.
>
> **Content Type column** values: declared in [PD-id-registry.json](../../../doc/PD-id-registry.json) under `PD-UGD.subdirectories.values`. Framework default: `tutorials`, `how-to`, `reference`, `explanation` (Diátaxis).

| Document   | Content Type | Status   | Location | Last Updated |
| ---------- | ------------ | -------- | -------- | ------------ |
| [Doc name] | how-to       | [STATUS] | [path]   | YYYY-MM-DD   |

### Existing Project Documentation

> Records pre-existing project documentation identified during onboarding audit (PF-TSK-064 step 3b). Content relevance is confirmed during analysis (PF-TSK-065). Confirmed entries guide documentation creation (PF-TSK-066) to extract rather than re-derive.
>
> For new projects: _No pre-existing project documentation identified._

| Document | Type | Relevant Content | Confirmed | Notes |
| -------- | ---- | ---------------- | --------- | ----- |
| [Name](path) | [Architecture Overview / User Guide / Test Plan / CI/CD / Troubleshooting / Developer Guide / Configuration / Changelog / Other] | [What's extractable for THIS feature] | [Unconfirmed / Confirmed / Partially Accurate / Outdated] | [Notes] |

### Quick Links

- **Main Design**: [Link]
- **Related Features**: [Link]

---

## 4. Code Inventory

### File Inventory

| File Path | Role | Ownership | Origin | Notes |
| --------- | ---- | --------- | ------ | ----- |
| [path] | [Core/Supporting/Shared] | [Owned/Co-owned/External] | [Created/Modified/Pre-existing] | [Notes] |

- **Role**: Core (central to feature), Supporting (used but not central), Shared (used by multiple features)
- **Ownership**: Owned (this feature is primary owner), Co-owned (shared responsibility), External (owned by another feature)
- **Origin**: Created (new file), Modified (changed existing file), Pre-existing (used without changes)

**Code Markers**: Created files include `// FEATURE: {feature-id}` header marker. Modifications include `// [FEATURE: {feature-id}]` inline markers.

> **Do not include LOC counts, method counts, or other size metrics** in file descriptions. These are point-in-time snapshots that go stale as code evolves and add maintenance burden without clear value. Use `wc -l` or `grep` to check current sizes on demand.

### Test Files

| Test File | Type | Coverage Areas | Status   | Created    |
| --------- | ---- | -------------- | -------- | ---------- |
| [path]    | Unit | [Areas]        | [STATUS] | YYYY-MM-DD |

### Database/Schema Changes

| Migration/Change | Type      | Description   | Applied    | Rollback Tested |
| ---------------- | --------- | ------------- | ---------- | --------------- |
| [name]           | Migration | [Description] | YYYY-MM-DD | Yes/No          |

---

## 5. Dependencies

### Feature Dependencies

**This Feature Depends On**:

- **[PF-FEA-XXX: Feature Name]**
  - Why: [Reason]
  - Status: [STATUS]

**Other Features Depend On This**:

- **[PF-FEA-XXX: Feature Name]** ([Status])
  - Why: [Reason]

### System Dependencies

**Required Packages**:

| Package | Version   | Purpose   | Added      |
| ------- | --------- | --------- | ---------- |
| [name]  | [version] | [Purpose] | YYYY-MM-DD |

### Code Dependencies

**Existing Code This Feature Integrates With**:

| Component | Used For  | Methods/APIs Used | Notes   |
| --------- | --------- | ----------------- | ------- |
| [path]    | [Purpose] | [APIs]            | [Notes] |

---

## 6. Design Decisions

### Decision 1: [Decision Title]

**Date**: YYYY-MM-DD
**Context**: [Why this decision was needed]

**Options Considered**:

1. [Option 1]: [Description] - [Pros/Cons]
2. [Option 2]: [Description] - [Pros/Cons]

**Decision Made**: [What was chosen]

**Rationale**: [Why this was the best choice - technical reasons, constraints, trade-offs]

---

### Implementation Patterns Used

**State Management Pattern**:

- Pattern: [e.g., Observer, Event Bus, Redux-style]
- Why: [Reason]
- Where: [Components]

**Error Handling Pattern**:

- Pattern: [e.g., Result<T, E> wrapper]
- Why: [Reason]
- Where: [Layers]

**Data Flow Pattern**:

- Pattern: [e.g., Repository → Service → Controller]
- Why: [Reason]
- Where: [Components]

---

## 7. Quality Assessment

> **Onboarding Quality Gate** (PF-TSK-065): Populated during Codebase Feature Analysis. Scores determine whether this feature is documented as **As-Built** (descriptive) or **Target-State** (prescriptive with gap analysis) during PF-TSK-066.
>
> For new features (not onboarding): _Leave this section empty — quality gate applies only during framework adoption._

**Classification**: [As-Built / Target-State / Not Assessed]
**Average Score**: [X.X] / 3.0

| Dimension | Score (0-3) | Notes |
|-----------|-------------|-------|
| Structural clarity | [0-3] | [Brief observation] |
| Error handling | [0-3] | [Brief observation] |
| Data integrity | [0-3] | [Brief observation] |
| Test coverage | [0-3] | [Brief observation] |
| Maintainability | [0-3] | [Brief observation] |

**Quality Assessment Report**: [Link to PD-QAR-XXX, if Target-State] | N/A (As-Built)

---

## 8. Notes & Next Steps

### Issues & Known Limitations

| Issue | Severity | Status | Resolution |
| ----- | -------- | ------ | ---------- |
| [Issue title] | [CRITICAL/HIGH/MEDIUM/LOW] | [OPEN/RESOLVED/DEFERRED] | [Brief resolution or mitigation] |

### Known Tech Debt

| Item | Priority | Mitigation | Tracked In |
| ---- | -------- | ---------- | ---------- |
| [Item] | [Priority] | [Current mitigation] | [Bug ID or debt item ref] |

### Next Steps

**Last Updated**: YYYY-MM-DD

1. **[Most important next action]** — [Why, what files, what to do]
2. **[Second action]** — [Brief description]

### Open Questions

- [Question needing clarification before proceeding]
