---
id: PF-TEM-048
type: Process Framework
category: Template
version: 1.1
created: 2026-03-02
updated: 2026-03-02
usage_context: Process Framework - Bug Fix State Tracking
creates_document_type: Process Framework
creates_document_prefix: PF-STA
creates_document_version: 1.0
creates_document_category: State Tracking
description: Template for tracking multi-session complex bug fix work, produced by Bug Fixing task (PF-TSK-007) for Large-effort bugs
template_for: Bug Fix State Tracking
---

# Bug Fix State: [Bug ID] — [Bug Title]

> **TEMPORARY FILE**: This file tracks multi-session bug fix work for complex/architectural bugs. Created by Bug Fixing task (PF-TSK-007) when effort is "Large". Move to `state-tracking/temporary/old/` when fix is verified and closed.

## Bug Fix Overview

| Metadata | Value |
|----------|-------|
| **Bug ID** | [Bug ID] |
| **Bug Title** | [Bug Title] |
| **Severity** | [Critical / High / Medium / Low] |
| **Affected Feature** | [Feature ID] — [Feature Name] |
| **Estimated Sessions** | [2 / 3+] |
| **Created** | [YYYY-MM-DD] |

## Root Cause Analysis

> Populate after investigating the bug. This section preserves findings across sessions.

- **Symptom**: [Observable behavior / error]
- **Root Cause**: [Underlying technical cause]
- **Affected Components**: [List of files/modules involved]
- **Secondary Issues Discovered**: [Any additional bugs found during investigation, or "None"]

### Affected Dimensions

> **Reference**: [Development Dimensions Guide](/doc/process-framework/guides/framework/development-dimensions-guide.md)
>
> Identify which dimensions this bug affects. Use dimension abbreviations (AC, CQ, ID, DA, EM, SE, PE, OB, UX, DI).

- **[Dimension Name (ABBR)]**: [How this bug affects this dimension]

### Dimension-Informed Fix Requirements

- [Fix requirement derived from affected dimension — e.g., "Fix must include atomicity guarantee (DI)"]

## Fix Approach

> Document the chosen approach and alternatives considered. Critical for session handover.

- **Chosen Approach**: [Description of the fix strategy]
- **Rationale**: [Why this approach over alternatives]
- **Alternatives Considered**:
  1. [Alternative 1] — [why rejected]
  2. [Alternative 2] — [why rejected]

## Implementation Progress

| File / Component | Change Required | Status | Session |
|------------------|----------------|--------|---------|
| [file path] | [description of change] | [Not Started / In Progress / Done] | [1 / 2 / ...] |

## Validation Status

- [ ] Regression test(s) written and confirmed FAILING before fix
- [ ] Fix implemented — regression tests now PASSING
- [ ] Full test suite passing
- [ ] Similar patterns checked in sibling components
- [ ] Manual validation test created

**Test Suite Results**: [Not yet run / All passing / X failures — details]

## Documentation Updates

> Only applicable when fix changes technical design or behavior. Mark N/A if not needed.

| Document | ID | Action | Status |
|----------|----|--------|--------|
| Feature State File | [PF-FEA-XXX or N/A] | [Update / N/A] | [Pending / Done / N/A] |
| TDD | [PD-TDD-XXX or N/A] | [Update / N/A] | [Pending / Done / N/A] |
| Test Specification | [PF-TSP-XXX or N/A] | [Update / N/A] | [Pending / Done / N/A] |
| FDD | [PD-FDD-XXX or N/A] | [Update / N/A] | [Pending / Done / N/A] |

## Session Log

### Session 1: [YYYY-MM-DD]

**Completed**:
- [List completed work]

**Next Session**:
- [What to continue with]

### Session 2: [YYYY-MM-DD]

**Completed**:
- [List completed work]

**Next Session**:
- [What to continue with]

## Completion Criteria

This file can be archived to `state-tracking/temporary/old/` when:

- [ ] Bug status is ✅ Verified / 🔒 Closed
- [ ] All implementation progress items are Done
- [ ] All validation checks pass
- [ ] Documentation updates completed (or confirmed N/A)
- [ ] Bug tracking entry updated with resolution details
