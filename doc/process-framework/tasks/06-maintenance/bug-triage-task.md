---
id: PF-TSK-041
type: Process Framework
category: Task Definition
version: 1.3
created: 2025-08-30
updated: 2026-03-03
task_type: Discrete
---

# Bug Triage

## Purpose & Context

Systematically evaluate, prioritize, and assign reported bugs to ensure efficient resource allocation and timely resolution of issues based on their impact, severity, and business priority.

## AI Agent Role

**Role**: Bug Triage Specialist
**Mindset**: Analytical, priority-focused, systematic evaluation
**Focus Areas**: Impact assessment, priority assignment, resource allocation, stakeholder communication
**Communication Style**: Ask detailed questions about bug impact and user experience, request reproduction steps, discuss priority rationale

## When to Use

- When new bugs have been reported and need evaluation
- When bug priority needs reassessment due to changing circumstances
- When multiple bugs need to be prioritized for development resources
- When bug reports need validation and categorization
- When duplicate bugs need to be identified and consolidated

## Context Requirements

- [Bug Triage Context Map](/doc/process-framework/visualization/context-maps/06-maintenance/bug-triage-map.md) - Visual guide to the components relevant to this task

- **Critical (Must Read):**

  - [Bug Tracking](../../state-tracking/permanent/bug-tracking.md) - Current bug registry and status
  - [Feature Tracking](../../state-tracking/permanent/feature-tracking.md) - To understand feature priorities and relationships
  - [Visual Notation Guide](/doc/process-framework/guides/guides/visual-notation-guide.md) - For interpreting context map diagrams

- **Important (Load If Space):**

  - [Feature Implementation State Files](../../state-tracking/features/) - State file for the affected feature (known issues, related bugs, implementation progress)
  - [Testing Guide](/doc/product-docs/guides/guides/testing-guide.md) - Guidelines for understanding test-related bugs
  - [Project Architecture](/doc/product-docs/technical/architecture) - Understanding system architecture for impact assessment

- **Reference Only (Access When Needed):**
  - [Process Improvement Tracking](../../state-tracking/permanent/process-improvement-tracking.md) - For process-related bug patterns

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished! 🚨**
>
> **⚠️ MANDATORY: All bug triage decisions must be documented with clear rationale.**
>
> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

### Preparation

1. Review the [Bug Tracking](../../state-tracking/permanent/bug-tracking.md) document to identify bugs with status 🆕 Reported or bugs that need reopening (see [Reopen Workflow](#reopen-workflow) below)
2. Gather all available information about each bug (reproduction steps, screenshots, logs)
3. Understand the current development priorities from [Feature Tracking](../../state-tracking/permanent/feature-tracking.md)
4. For each bug, consult the affected feature's [implementation state file](../../state-tracking/features/) for known issues, related bugs, and current implementation status
5. Review any related bugs or patterns in the bug registry
6. **🚨 CHECKPOINT**: Present bug inventory, initial analysis, and current development priorities to human partner

### Evaluation

7. **Assess Bug Validity**: Determine if the reported issue is actually a bug
   - Verify reproduction steps
   - Confirm expected vs actual behavior
   - Check if it's a feature request rather than a bug
8. **Evaluate Impact and Severity**:
   - **Critical**: System crash, data loss, security vulnerability
   - **High**: Major feature not working, significant user impact
   - **Medium**: Minor feature issue, workaround available
   - **Low**: Cosmetic issue, minimal user impact
9. **Determine Priority Level**:
   - **P1 (Critical)**: System breaking, security issues - Immediate response
   - **P2 (High)**: Major functionality affected - Within 24 hours
   - **P3 (Medium)**: Minor functionality affected - Within 1 week
   - **P4 (Low)**: Cosmetic or enhancement requests - When time permits
10. **Check for Duplicates**: Compare with existing bugs to identify duplicates
11. **🚨 CHECKPOINT**: Present triage decisions (priority, scope, duplicates, rationale) to human partner for approval

### Assignment and Documentation

12. **Assign Priority and Scope**: Update bug entry with determined priority (P1-P4) and scope (S/M/L for fix complexity — see [Scope Levels](../../state-tracking/permanent/bug-tracking.md#scope-levels))
13. **Provide Triage Rationale**: Document the reasoning behind priority and scope assignments
14. **Identify Related Features**: Link bugs to affected features in Feature Tracking
    > **Tip**: Bugs discovered during code review often lack a "Related Feature" field. During triage, identify the affected feature from [Feature Tracking](../../state-tracking/permanent/feature-tracking.md) and populate this field.
15. **Estimate Effort**: Provide rough effort estimate for fixing the bug
16. **Update Bug Status**: Change status from 🆕 Reported to 🔍 Triaged
    - **Manual Update**: Edit the [Bug Tracking](../../state-tracking/permanent/bug-tracking.md) file directly
    - **Optional Automation**: Use [`Update-BugStatus.ps1`](../../scripts/Update-BugStatus.ps1) script for consistent formatting:
      ```powershell
      ../../scripts/Update-BugStatus.ps1 -BugId "BUG-001" -NewStatus "Triaged" -Priority "High" -Scope "S"
      ```

### Finalization

17. **Update Bug Registry**: Ensure all bug information is properly recorded
18. **Plan Next Steps**: Determine immediate next actions for high-priority bugs
19. **Update Statistics**: Refresh bug tracking statistics
20. **🚨 MANDATORY FINAL STEP**: Complete the Task Completion Checklist below

## Triage Decision Framework

### Priority Assignment Matrix

| Impact | Frequency | Priority      |
| ------ | --------- | ------------- |
| High   | High      | P1 (Critical) |
| High   | Medium    | P2 (High)     |
| High   | Low       | P2 (High)     |
| Medium | High      | P2 (High)     |
| Medium | Medium    | P3 (Medium)   |
| Medium | Low       | P3 (Medium)   |
| Low    | High      | P3 (Medium)   |
| Low    | Medium    | P4 (Low)      |
| Low    | Low       | P4 (Low)      |

### Severity vs Priority Guidelines

- **Severity**: Technical impact of the bug
- **Priority**: Business urgency for fixing the bug
- A low-severity bug can have high priority if it affects critical business functions
- A high-severity bug can have lower priority if it affects rarely-used features

### Special Considerations

- **Security Issues**: Always P1 regardless of other factors
- **Data Loss Bugs**: Always P1 regardless of other factors
- **Regression Bugs**: Priority based on affected feature priority
- **Performance Issues**: Priority based on user impact and frequency

## Reopen Workflow

When a previously closed bug recurs, decide whether to **reopen** the original or **create a new bug**:

| Reopen the original | Create a new bug |
|---|---|
| Same root cause as the original fix | Different root cause or different component |
| Fix was incomplete or regressed | Similar symptom but distinct underlying issue |
| Discovered shortly after closure | Original was closed long ago and codebase has changed significantly |

### Steps to reopen a bug

1. **Update status** using the automation script:
   ```powershell
   ../../scripts/Update-BugStatus.ps1 -BugId "PD-BUG-XXX" -NewStatus "Reopened" -ReopenReason "Description of why the bug recurred"
   ```
   This automatically moves the entry from the Closed section back to the correct active priority table and recalculates statistics.
2. **Re-evaluate priority and scope** — the original P-level and scope may no longer apply (e.g., a P4 bug that now causes data loss becomes P1)
3. **Continue with the normal Evaluation steps** (Steps 6-9) to update the triage rationale

## Outputs

- **Updated Bug Registry** - [Bug Tracking](../../state-tracking/permanent/bug-tracking.md) with triaged bugs
- **Triage Documentation** - Clear rationale for all priority and scope assignments
- **Effort Estimates** - Rough estimates for bug fix complexity
- **Duplicate Identification** - Consolidated duplicate bugs with cross-references

## State Tracking

The following state files must be updated as part of this task:

- [Bug Tracking](../../state-tracking/permanent/bug-tracking.md) - Update with:
  - Bug status changed from 🆕 Reported to 🔍 Triaged
  - Priority and scope assignments
  - Triage rationale and notes
  - Effort estimates
  - Related feature references
  - Updated statistics

**Automation Support**: While bug triage is primarily a manual evaluation process, the [`Update-BugStatus.ps1`](../../scripts/Update-BugStatus.ps1) script can be used to automate the status update portion for consistent formatting and automatic timestamp tracking.

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

Before considering this task finished:

- [ ] **Verify Evaluation Completeness**: Confirm all reported bugs have been evaluated

  - [ ] Bug validity has been assessed for all reported bugs
  - [ ] Impact has been evaluated and scope (S/M/L) has been determined
  - [ ] Priority has been assigned using the decision matrix
  - [ ] Duplicate bugs have been identified and consolidated
  - [ ] Triage rationale is documented for all decisions

- [ ] **Verify Documentation**: Confirm proper documentation

  - [ ] All bugs have clear priority and scope assignments
  - [ ] Triage rationale is documented for each bug
  - [ ] Related features are identified and linked
  - [ ] Effort estimates are provided where possible

- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] Bug Tracking document reflects all triage decisions
  - [ ] Bug status updated from 🆕 Reported to 🔍 Triaged
  - [ ] Statistics section is updated with current numbers
  - [ ] All required fields are populated for triaged bugs
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Completion Instructions](../../guides/guides/feedback-form-completion-instructions.md) for each tool used, using task ID "PF-TSK-041" and context "Bug Triage"

## Next Tasks

- [**Bug Fixing**](bug-fixing-task.md) - To resolve triaged bugs

- [**Feature Implementation Planning**](../04-implementation/feature-implementation-planning-task.md) - If bugs reveal need for new functionality

## Related Resources

- [Bug Tracking State File](../../state-tracking/permanent/bug-tracking.md) - Central bug registry
- [Feature Tracking State File](../../state-tracking/permanent/feature-tracking.md) - Feature priorities and relationships
- [Task Transition Guide](../../guides/guides/task-transition-guide.md) - Guidance on transitioning between tasks
- [Task Creation and Improvement Guide](../../guides/guides/task-creation-guide.md) - Guide for creating and improving tasks
