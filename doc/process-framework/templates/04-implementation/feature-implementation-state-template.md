---
id: PF-TEM-037
type: Process Framework
category: Template
version: 2.0
created: 2025-01-20
updated: 2026-02-27
creates_document_prefix: PF-FIS
creates_document_version: 1.0
description: Template for permanent feature implementation state tracking throughout feature lifecycle
creates_document_type: Process Framework
usage_context: Process Framework - Feature State Tracking
creates_document_category: Feature Implementation State
template_for: Feature State Tracking
---

# [Feature Name] - Implementation State

> **📖 Usage guide**: [Feature Implementation State Tracking Guide (PF-GDE-043)](../../guides/04-implementation/feature-implementation-state-tracking-guide.md)
>
> **Retrospective Analysis mode** (onboarding tasks [PF-TSK-064](../../tasks/00-setup/codebase-feature-discovery.md), [PF-TSK-065](../../tasks/00-setup/codebase-feature-analysis.md), [PF-TSK-066](../../tasks/00-setup/retrospective-documentation-creation.md)):
> - Section 3 tracks analysis progress rather than planned tasks
> - Section 5 (Code Inventory) is the primary deliverable — every file must be assigned
> - Section 7 documents decisions discovered in code, not planned decisions
> - All content is descriptive ("what is") rather than prescriptive ("what should be")

---

## 1. Feature Overview

### Feature Description

[2-3 paragraph description of what this feature does and why it exists]

### Business Value

- **User Need**: [What problem this solves for users]
- **Business Goal**: [What business objective this achieves]
- **Success Metrics**: [How success will be measured post-deployment]

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
**Completion**: [X]% complete

### What's Working

- [✓] [Completed capability 1]
- [✓] [Completed capability 2]

### What's In Progress

- [⚙] [Current work item 1]
- [⚙] [Current work item 2]

### What's Blocked

- [🚫] [Blocker 1 - description and owner]

---

## 3. Implementation Progress

### Task Sequence

> **Note**: Each decomposed task has its own unique task ID assigned via the ID registry (using New-Task.ps1). Replace PF-TSK-XXX placeholders with actual task IDs.

- [✓] **PF-TSK-XXX**: Feature Implementation Planning

  - **Completed**: YYYY-MM-DD
  - **Duration**: X hours / Y sessions
  - **Key Outputs**: [Brief description]
  - **Session Notes**: [Important context]

- [⚙] **PF-TSK-YYY**: Data Layer Implementation (CURRENT)

  - **Started**: YYYY-MM-DD
  - **Expected Completion**: YYYY-MM-DD
  - **Status**: [X]% complete
  - **Current Work**: [What's being implemented]
  - **Next Steps for This Task**:
    1. [Specific next action]
    2. [Specific next action]

- [ ] **PF-TSK-ZZZ**: State Management Implementation

  - **Dependencies**: [What must be complete first]
  - **Planned Start**: [YYYY-MM-DD]

- [ ] **PF-TSK-AAA**: UI Implementation
- [ ] **PF-TSK-BBB**: Integration & Testing
- [ ] **PF-TSK-CCC**: Quality Validation
- [ ] **PF-TSK-DDD**: Implementation Finalization

---

## 4. Documentation Inventory

### Design Documentation

| Document   | Type        | Status   | Location | Last Updated |
| ---------- | ----------- | -------- | -------- | ------------ |
| [Doc name] | Design Spec | [STATUS] | [path]   | YYYY-MM-DD   |

### User Documentation

> **Trigger for [User Documentation Creation](../../../process-framework/tasks/07-deployment/user-documentation-creation.md)**: When this feature has user-visible behavior, set Status to `❌ Needed` after implementation. The task resolves it to `✅ Created` with links. Use `N/A` for internal-only features. A feature may have multiple handbook entries.

| Document   | Type         | Status   | Location | Last Updated |
| ---------- | ------------ | -------- | -------- | ------------ |
| [Doc name] | End User Doc | [STATUS] | [path]   | YYYY-MM-DD   |

### Developer Documentation

| Document   | Type          | Status   | Location | Last Updated |
| ---------- | ------------- | -------- | -------- | ------------ |
| [Doc name] | API Reference | [STATUS] | [path]   | YYYY-MM-DD   |

### Existing Project Documentation

> Records pre-existing project documentation identified during onboarding audit (PF-TSK-064 step 3b). Content relevance is confirmed during analysis (PF-TSK-065). Confirmed entries guide documentation creation (PF-TSK-066) to extract rather than re-derive.
>
> For new projects: _No pre-existing project documentation identified._

| Document | Type | Relevant Content | Confirmed | Notes |
| -------- | ---- | ---------------- | --------- | ----- |
| [Name](path) | [Architecture Overview / User Guide / Test Plan / CI/CD / Troubleshooting / Developer Guide / Configuration / Changelog / Other] | [What's extractable for THIS feature] | [Unconfirmed / Confirmed / Partially Accurate / Outdated] | [Notes] |

### Quick Links

- **Main Design**: [Link]
- **Implementation Tasks**: [Link]
- **Related Features**: [Link]

---

## 5. Code Inventory

### Files Created by This Feature

| File Path | Purpose   | Key Components | Status   | Created    |
| --------- | --------- | -------------- | -------- | ---------- |
| [path]    | [Purpose] | [Components]   | [STATUS] | YYYY-MM-DD |

**Code Markers**: All created files include `// FEATURE: {feature-id}` header marker

### Files Modified by This Feature

| File Path | What Changed | Reason   | Impact   | Modified   |
| --------- | ------------ | -------- | -------- | ---------- |
| [path]    | [Change]     | [Reason] | [Impact] | YYYY-MM-DD |

**Code Markers**: All modifications include `// [FEATURE: {feature-id}]` inline markers

### Test Files

| Test File | Type | Coverage Areas | Status   | Created    |
| --------- | ---- | -------------- | -------- | ---------- |
| [path]    | Unit | [Areas]        | [STATUS] | YYYY-MM-DD |

### Database/Schema Changes

| Migration/Change | Type      | Description   | Applied    | Rollback Tested |
| ---------------- | --------- | ------------- | ---------- | --------------- |
| [name]           | Migration | [Description] | YYYY-MM-DD | Yes/No          |

---

## 6. Dependencies

### Feature Dependencies

**This Feature Depends On**:

- **[PF-FEA-XXX: Feature Name]**
  - Why: [Reason]
  - Status: [STATUS]
  - Impact if unavailable: [Impact]

**Other Features Depend On This**:

- **[PF-FEA-XXX: Feature Name]** ([Status])
  - Why: [Reason]
  - Note: [Important note]

### System Dependencies

**Required Services**:

- [Service 1]: [Purpose]
- [Service 2]: [Purpose]

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

## 7. Dimension Profile

> **📖 Reference**: [Development Dimensions Guide](/doc/process-framework/guides/framework/development-dimensions-guide.md)
>
> **Source**: Feature Implementation Planning | **Last reviewed**: [YYYY-MM-DD]
>
> Core dimensions (AC, CQ, ID, DA) are always at least Relevant — list only extended dimensions below.

### Applicable Dimensions

| Dimension | Importance | Key Considerations |
|-----------|-----------|-------------------|
| [Dimension Name (ABBR)] | [Critical / Relevant] | [1-line: what to watch for in this feature] |

### Not Applicable

| Dimension | Rationale |
|-----------|-----------|
| [Dimension Name (ABBR)] | [Why this dimension does not apply] |

---

## 8. Design Decisions

### Decision 1: [Decision Title]

**Date**: YYYY-MM-DD
**Context**: [Why this decision was needed]

**Options Considered**:

1. [Option 1]: [Description] - [Pros/Cons]
2. [Option 2]: [Description] - [Pros/Cons]
3. [Option 3]: [Description] - [Pros/Cons]

**Decision Made**: [What was chosen]

**Rationale**: [Why this was the best choice - technical reasons, constraints, trade-offs]

**Implications**:

- [Impact on implementation]
- [Impact on future work]
- [Impact on other components]

**Validation**: [How we'll verify this decision was correct]

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

## 9. Issues & Resolutions Log

> Populate when issues arise during work on this feature (bug fixes, blockers, investigations). For formal bug reports, use [bug-tracking.md](../../../product-docs/state-tracking/permanent/bug-tracking.md); this section provides feature-local context.

| Issue | Severity | Status | Reported | Resolved | Root Cause | Resolution |
| ----- | -------- | ------ | -------- | -------- | ---------- | ---------- |
| [Issue title] | [CRITICAL/HIGH/MEDIUM/LOW] | [OPEN/RESOLVED/DEFERRED] | YYYY-MM-DD | YYYY-MM-DD | [Brief root cause] | [Brief resolution] |

### Known Limitations & Tech Debt

| Item | Type | Priority | Mitigation | Tracked In |
| ---- | ---- | -------- | ---------- | ---------- |
| [Item] | [Tech Debt / Known Limitation / Architectural Constraint] | [Priority] | [Current mitigation] | [Bug ID or debt item ref] |

---

## 10. Next Steps

> Populate during active work on this feature. Update at the end of every work session.

**Last Updated**: YYYY-MM-DD

1. **[Most important next action]** — [Why, what files, what to do]
2. **[Second action]** — [Brief description]
3. **[Third action]** — [Brief description]

### Open Questions

- [Question needing clarification before proceeding]
