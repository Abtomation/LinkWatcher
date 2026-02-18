---
id: PF-TEM-037
type: Process Framework
category: Template
version: 1.5
created: 2025-01-20
updated: 2026-02-17
creates_document_prefix: PF-FIS
creates_document_version: 1.0
description: Template for permanent feature implementation state tracking throughout feature lifecycle
creates_document_type: Process Framework
usage_context: Process Framework - Feature State Tracking
creates_document_category: Feature Implementation State
template_for: Feature State Tracking
---

# [Feature Name] - Implementation State

> **📖 Usage guide**: [Feature Implementation State Tracking Guide (PF-GDE-043)](../../guides/guides/feature-implementation-state-tracking-guide.md)
>
> **Retrospective Analysis mode** (onboarding tasks [PF-TSK-064](../../tasks/00-onboarding/codebase-feature-discovery.md), [PF-TSK-065](../../tasks/00-onboarding/codebase-feature-analysis.md), [PF-TSK-066](../../tasks/00-onboarding/retrospective-documentation-creation.md)):
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

| Document   | Type         | Status   | Location | Last Updated |
| ---------- | ------------ | -------- | -------- | ------------ |
| [Doc name] | End User Doc | [STATUS] | [path]   | YYYY-MM-DD   |

### Developer Documentation

| Document   | Type          | Status   | Location | Last Updated |
| ---------- | ------------- | -------- | -------- | ------------ |
| [Doc name] | API Reference | [STATUS] | [path]   | YYYY-MM-DD   |

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

### Files Used by This Feature

| File Path | How Used | Methods/APIs Used | Notes   |
| --------- | -------- | ----------------- | ------- |
| [path]    | [Usage]  | [APIs]            | [Notes] |

**Code Markers**: Used files include `// USED BY FEATURES: {feature-id}` comments

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

## 7. Design Decisions

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

- Pattern: [e.g., Riverpod AsyncNotifier]
- Why: [Reason]
- Where: [Components]

**Error Handling Pattern**:

- Pattern: [e.g., Result<T, E> wrapper]
- Why: [Reason]
- Where: [Layers]

**Data Flow Pattern**:

- Pattern: [e.g., Repository → Provider → UI]
- Why: [Reason]
- Where: [Components]

---

## 8. Issues & Resolutions Log

### Issue 1: [Issue Title]

**Status**: [BLOCKED | IN_PROGRESS | RESOLVED | DEFERRED]
**Severity**: [CRITICAL | HIGH | MEDIUM | LOW]
**Reported**: YYYY-MM-DD
**Resolved**: YYYY-MM-DD
**Task**: PF-TSK-XXX

**Problem**: [Detailed description]

**Impact**:

- What: [Functionality affected]
- Scope: [How much blocked]
- Users: [Who impacted]

**Investigation**:

- Hypothesis 1: [What tested] → [Result]
- Hypothesis 2: [What tested] → [Result]

**Root Cause**: [Ultimate cause]

**Resolution**: [How solved - specific changes]

**Prevention**: [How to avoid in future]

**Notes for Next Session**: [Context if spans sessions]

---

### Tech Debt and Known Limitations

| Item   | Type      | Reason   | Current Mitigation | Priority   | Estimated Effort | Future Resolution | Tracked In |
| ------ | --------- | -------- | ------------------ | ---------- | ---------------- | ----------------- | ---------- |
| [Item] | Tech Debt | [Reason] | [Mitigation]       | [Priority] | [Effort]         | [Plan]            | [Issue #]  |

**Type Legend**:

- **Tech Debt**: Shortcuts that should be refactored
- **Known Limitation**: Feature constraints or missing functionality
- **Architectural Constraint**: System-level limitations

---

## 9. Next Steps

**Last Updated**: YYYY-MM-DD HH:MM

### Immediate Next Actions

1. **[Action 1 - Most Important]**

   - **Why**: [Reason this is priority]
   - **How**: [Specific steps]
   - **Files**: [Which files]
   - **Estimate**: [Time/complexity]

2. **[Action 2]**

   - **Why**: [Reason]
   - **How**: [Steps]
   - **Dependencies**: [What must be done first]
   - **Estimate**: [Time/complexity]

3. **[Action 3]**
   - **Why**: [Reason]
   - **How**: [Steps]
   - **Estimate**: [Time/complexity]

### Upcoming Work (Next 1-2 Tasks)

- [ ] [Work item 1] - Expected: [Date]
- [ ] [Work item 2] - Expected: [Date]
- [ ] [Work item 3] - Expected: [Date]

### Questions That Need Answers

1. [Question affecting next steps]
2. [Question needing clarification]

### Recommended Starting Points for Next Session

**If Continuing Current Task**:

- Start in: [Specific file/component]
- Context needed: [What to understand]
- Previous work: [What just completed]

**If Starting Next Task**:

- Prerequisites: [What to verify]
- Begin with: [Where to start]
- Reference: [What to read]

---

## 10. Quality Metrics

**Last Updated**: YYYY-MM-DD

### Code Quality

**Linting**:

- Total Issues: [Number]
- Critical: [Number]
- Warnings: [Number]
- Status: [CLEAN | NEEDS_ATTENTION]

**Code Review**:

- Status: [SELF_REVIEWED | PEER_REVIEWED | NOT_REVIEWED]
- Reviewer: [Name]
- Review Date: YYYY-MM-DD
- Issues Found: [Number and severity]

**Documentation Coverage**:

- Public APIs Documented: [X]%
- Complex Logic Explained: [YES | PARTIAL | NO]
- Code Comments Quality: [GOOD | ADEQUATE | NEEDS_IMPROVEMENT]

### Test Coverage

**Unit Tests**:

- Coverage: [X]%
- Tests Written: [Number]
- Tests Passing: [Number]
- Critical Paths Covered: [YES | PARTIAL | NO]

**Widget Tests**:

- Coverage: [X]%
- Tests Written: [Number]
- Tests Passing: [Number]
- Key UI Flows Covered: [YES | PARTIAL | NO]

**Integration Tests**:

- End-to-End Scenarios: [Number defined] / [Number implemented]
- Tests Passing: [Number]
- Critical User Journeys Covered: [YES | PARTIAL | NO]

### Performance Metrics

| Metric        | Target   | Current   | Status   | Notes   |
| ------------- | -------- | --------- | -------- | ------- |
| [Metric name] | [Target] | [Current] | [Status] | [Notes] |

### Standards Compliance

- [ ] Follows project coding standards
- [ ] Adheres to Flutter best practices
- [ ] Follows Riverpod patterns
- [ ] Security requirements met
- [ ] Accessibility requirements met

---

## 11. API Documentation Reference

### Public APIs Exposed by This Feature

| Component | Type   | Documentation Link | Status   | Notes   |
| --------- | ------ | ------------------ | -------- | ------- |
| [Name]    | [Type] | [Link]             | [STATUS] | [Notes] |

### Key Integration Points

**This Feature Exposes**:

- [API/capability 1]
- [API/capability 2]

**This Feature Requires**:

- [Dependency 1] (`method()`)
- [Dependency 2] (model/API)

**Events Emitted**:

- [Event 1], [Event 2], [Event 3]

**See Full API Documentation**: [Link to comprehensive docs]

---

## 12. Lessons Learned

**Last Updated**: YYYY-MM-DD

### What Went Well

#### Success 1: [Title]

**What Happened**: [Description]

**Why It Worked**: [Contributing factors]

**Application to Future Work**: [How to replicate]

**Process Framework Insight**: [Framework improvement insights]

---

### What Could Be Improved

#### Improvement Area 1: [Title]

**What Happened**: [Description]

**Impact**: [Effect on implementation]

**Root Cause**: [Why this happened]

**Suggested Improvement**: [Specific recommendation]

**Process Framework Action**: [Needed framework change]

---

### AI Collaboration Patterns

**Effective Patterns**:

- [Pattern 1]: [What worked well]
- [Pattern 2]: [Effective communication/workflow]

**Ineffective Patterns**:

- [Pattern 1]: [What didn't work] - [Why] - [Better approach]
- [Pattern 2]: [What didn't work] - [Why] - [Better approach]

### Tool and Technique Insights

**Helpful Tools/Approaches**:

- [Tool 1]: [How it helped] - [When to use]
- [Tool 2]: [How it helped] - [When to use]

**Limitations Discovered**:

- [Limitation 1]: [What didn't work] - [Workaround] - [Alternative]
- [Limitation 2]: [What didn't work] - [Workaround] - [Alternative]

### Recommendations for Similar Features

1. [Recommendation 1 with rationale]
2. [Recommendation 2 with rationale]
3. [Recommendation 3 with rationale]

### Open Questions for Framework Evolution

1. [Question about process or template]
2. [Question about task structure or guidance]
