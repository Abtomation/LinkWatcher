---
id: PF-STA-002
type: Process Framework
category: State Tracking
version: 1.1
created: 2025-06-15
updated: 2025-01-27
---

# Technical Debt Tracker

This document tracks technical debt. As a solo developer, it's important to be intentional about technical debt - sometimes taking shortcuts is necessary to make progress, but these should be documented and addressed later.

## What is Technical Debt?

Technical debt refers to the implied cost of future rework caused by choosing an easy or quick solution now instead of a better approach that would take longer. It's not inherently bad, but it should be managed.

## Technical Debt Categories

- **Architectural**: Issues related to the overall system design
- **Code Quality**: Issues related to code readability, maintainability, or duplication
- **Testing**: Missing or inadequate tests
- **Documentation**: Missing, outdated, or inadequate documentation
- **Performance**: Known performance issues
- **Security**: Known security vulnerabilities or concerns
- **Accessibility**: Known accessibility issues
- **UX**: User experience compromises

## Priority Levels

- **Critical**: Must be addressed before the next release
- **High**: Should be addressed in the next development cycle
- **Medium**: Should be addressed when convenient
- **Low**: Nice to fix, but not urgent

## Technical Debt Registry

| ID    | Description                                                | Category      | Location                                                                     | Created Date | Priority | Estimated Effort | Status      | Resolution Date | Assessment ID | Notes                                                                                                |
| ----- | ---------------------------------------------------------- | ------------- | ---------------------------------------------------------------------------- | ------------ | -------- | ---------------- | ----------- | --------------- | ------------- | ---------------------------------------------------------------------------------------------------- |


## Recently Resolved Technical Debt

| ID  | Description | Category | Location | Created Date | Priority | Resolution Date | Assessment ID | Notes |
| --- | ----------- | -------- | -------- | ------------ | -------- | --------------- | ------------- | ----- |
| -   | -           | -        | -        | -            | -        | -               | -             | -     |

## Technical Debt Management Strategy

As a solo developer, follow these guidelines for managing technical debt:

1. **Be intentional**: When creating technical debt, do so consciously and document it immediately
2. **Comment in code**: Mark technical debt in code with `// TODO: [TD###] Description` comments
3. **Regular review**: Review this document periodically to reassess priorities
4. **Batch similar items**: Address similar technical debt items together for efficiency
5. **Refactoring sessions**: Dedicate occasional focused sessions to addressing technical debt

## Linking with Assessment System

**Assessment ID Column**: Links debt items to their originating technical debt assessments:

- **Assessment IDs**: Use format `PF-TDA-XXX` for items identified during formal assessments
- **Debt Item IDs**: Individual debt items get `PF-TDI-XXX` IDs during assessment
- **Manual Items**: Items identified outside assessments leave Assessment ID blank (`-`)

**Workflow Integration**:

1. During Technical Debt Assessment, individual debt items are created with `PF-TDI-XXX` IDs
2. Assessment generates report with `PF-TDA-XXX` ID
3. When adding items to this registry, reference the assessment ID in the Assessment ID column
4. This creates traceability from registry entries back to detailed assessment documentation

## Adding New Technical Debt Items

When adding a new technical debt item:

1. Assign the next available ID (TD###)
2. Add a detailed description
3. Categorize it appropriately
4. Note the exact location in code
5. Assign a priority
6. Estimate the effort required to fix it
7. Add any relevant notes
8. Add a corresponding comment in the code

## Resolving Technical Debt Items

When resolving a technical debt item:

1. Update its status to "Resolved"
2. Add the resolution date
3. Add notes about how it was resolved
4. Move it to the "Recently Resolved" section
5. Remove the corresponding TODO comment from the code

---

_This document is part of the Process Framework and provides a system for tracking and managing technical debt._
