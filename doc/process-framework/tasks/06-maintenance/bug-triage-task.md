---
id: PF-TSK-041
type: Process Framework
category: Task Definition
version: 1.0
created: 2025-08-30
updated: 2025-08-30
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

  - [Testing Guide](/doc/product-docs/guides/guides/testing-guide.md) - Guidelines for understanding test-related bugs
  - [Project Architecture](/doc/product-docs/technical/architecture) - Understanding system architecture for impact assessment

- **Reference Only (Access When Needed):**
  - [Process Improvement Tracking](../../state-tracking/permanent/process-improvement-tracking.md) - For process-related bug patterns

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished! 🚨**
>
> **⚠️ MANDATORY: All bug triage decisions must be documented with clear rationale.**

### Preparation

1. Review the [Bug Tracking](../../state-tracking/permanent/bug-tracking.md) document to identify bugs with status 🆕 Reported
2. Gather all available information about each bug (reproduction steps, screenshots, logs)
3. Understand the current development priorities from [Feature Tracking](../../state-tracking/permanent/feature-tracking.md)
4. Review any related bugs or patterns in the bug registry

### Evaluation

5. **Assess Bug Validity**: Determine if the reported issue is actually a bug
   - Verify reproduction steps
   - Confirm expected vs actual behavior
   - Check if it's a feature request rather than a bug
6. **Evaluate Impact and Severity**:
   - **Critical**: System crash, data loss, security vulnerability
   - **High**: Major feature not working, significant user impact
   - **Medium**: Minor feature issue, workaround available
   - **Low**: Cosmetic issue, minimal user impact
7. **Determine Priority Level**:
   - **P1 (Critical)**: System breaking, security issues - Immediate response
   - **P2 (High)**: Major functionality affected - Within 24 hours
   - **P3 (Medium)**: Minor functionality affected - Within 1 week
   - **P4 (Low)**: Cosmetic or enhancement requests - When time permits
8. **Check for Duplicates**: Compare with existing bugs to identify duplicates

### Assignment and Documentation

9. **Assign Priority and Severity**: Update bug entry with determined priority and severity
10. **Provide Triage Rationale**: Document the reasoning behind priority and severity assignments
11. **Identify Related Features**: Link bugs to affected features in Feature Tracking
12. **Estimate Effort**: Provide rough effort estimate for fixing the bug
13. **Update Bug Status**: Change status from 🆕 Reported to 🔍 Triaged
    - **Manual Update**: Edit the [Bug Tracking](../../state-tracking/permanent/bug-tracking.md) file directly
    - **Optional Automation**: Use [`Update-BugStatus.ps1`](../../scripts/Update-BugStatus.ps1) script for consistent formatting:
      ```powershell
      ../../scripts/Update-BugStatus.ps1 -BugId "BUG-001" -NewStatus "Triaged" -Priority "High" -Severity "Medium"
      ```

### Finalization

14. **Update Bug Registry**: Ensure all bug information is properly recorded
15. **Plan Next Steps**: Determine immediate next actions for high-priority bugs
16. **Update Statistics**: Refresh bug tracking statistics
17. **🚨 MANDATORY FINAL STEP**: Complete the Task Completion Checklist below

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

## Outputs

- **Updated Bug Registry** - [Bug Tracking](../../state-tracking/permanent/bug-tracking.md) with triaged bugs
- **Triage Documentation** - Clear rationale for all priority and severity assignments
- **Effort Estimates** - Rough estimates for bug fix complexity
- **Duplicate Identification** - Consolidated duplicate bugs with cross-references

## State Tracking

The following state files must be updated as part of this task:

- [Bug Tracking](../../state-tracking/permanent/bug-tracking.md) - Update with:
  - Bug status changed from 🆕 Reported to 🔍 Triaged
  - Priority and severity assignments
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
  - [ ] Impact and severity have been determined using the framework
  - [ ] Priority has been assigned using the decision matrix
  - [ ] Duplicate bugs have been identified and consolidated
  - [ ] Triage rationale is documented for all decisions

- [ ] **Verify Documentation**: Confirm proper documentation

  - [ ] All bugs have clear priority and severity assignments
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

- [**Feature Implementation**](../04-implementation/feature-implementation-task.md) - If bugs reveal need for new functionality

## Related Resources

- [Bug Tracking State File](../../state-tracking/permanent/bug-tracking.md) - Central bug registry
- [Feature Tracking State File](../../state-tracking/permanent/feature-tracking.md) - Feature priorities and relationships
- [Task Transition Guide](../../guides/guides/task-transition-guide.md) - Guidance on transitioning between tasks
- [Task Creation and Improvement Guide](../../guides/guides/task-creation-guide.md) - Guide for creating and improving tasks
