---
id: PF-TSK-007
type: Process Framework
category: Task Definition
version: 1.2
created: 2023-06-15
updated: 2025-06-08
task_type: Discrete
---

# Bug Fixing

## Purpose & Context

Diagnose, fix, and verify solutions for reported bugs or issues in the application, ensuring software quality and maintaining user trust by promptly addressing defects in the system.

## AI Agent Role

**Role**: Debugging Specialist
**Mindset**: Methodical, root-cause focused, systematic
**Focus Areas**: Issue reproduction, root cause analysis, prevention strategies, systematic debugging
**Communication Style**: Ask detailed questions about symptoms and context, request specific reproduction steps, discuss prevention measures

## When to Use

- When a bug has been reported and needs to be fixed
- When an issue has been identified during testing
- When a regression has been detected in existing functionality
- When a security vulnerability has been discovered
- When a performance issue has been identified

## Context Requirements

- [Bug Fixing Context Map](/doc/process-framework/visualization/context-maps/06-maintenance/bug-fixing-map.md) - Visual guide to the components relevant to this task

- **Critical (Must Read):**

  - [Bug Tracking](../../state-tracking/permanent/bug-tracking.md) - Central bug registry and status tracking
  - Specific source files containing the bug
  - [Testing Guide](/doc/product-docs/guides/guides/testing-guide.md) - Guidelines for testing and debugging
  - Tests related to the affected functionality
  - [Visual Notation Guide](/doc/process-framework/guides/guides/visual-notation-guide.md) - For interpreting context map diagrams

- **Important (Load If Space):**

  - [Feature Implementation Checklist](/doc/product-docs/checklists/checklists/feature-implementation-checklist.md) - General checklist that can be adapted for bug fixes
  - [Project Architecture](/doc/product-docs/technical/architecture) - Understanding of the system architecture

- **Reference Only (Access When Needed):**
  - [Feature Tracking](../../state-tracking/permanent/feature-tracking.md) - To understand feature relationships and priorities when bugs affect specific features

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished! 🚨**
>
> **⚠️ MANDATORY: Always create or update tests to verify fixes and prevent regression.**

### Preparation

1. Review the [Bug Tracking](../../state-tracking/permanent/bug-tracking.md) document to identify a triaged bug to fix (status 🔍 Triaged)
2. Verify the bug has been properly triaged with priority and severity assigned
3. Reproduce the bug to understand its exact behavior and confirm the issue
4. Document the reproduction steps for future reference
5. Analyze the affected code area to understand the context
6. Update bug status from 🔍 Triaged to 🟡 In Progress
   - **Manual Update**: Edit the [Bug Tracking](../../state-tracking/permanent/bug-tracking.md) file directly
   - **Automated Option**: Use [`Update-BugStatus.ps1`](../../scripts/Update-BugStatus.ps1) script:
     ```powershell
     ../../scripts/Update-BugStatus.ps1 -BugId "BUG-001" -NewStatus "InProgress"
     ```

### Execution

7. Analyze the code to identify the root cause of the bug
8. Consider alternative approaches to fixing the issue
9. Develop a fix that addresses the root cause, not just the symptoms
10. Write or update tests to verify the fix and prevent regression
11. Test the fix thoroughly to ensure it resolves the issue
12. Verify that the fix doesn't introduce new problems
13. Check for similar issues in other parts of the codebase
14. Update bug status from 🟡 In Progress to 🧪 Fixed
    - **Manual Update**: Edit the [Bug Tracking](../../state-tracking/permanent/bug-tracking.md) file directly
    - **Automated Option**: Use [`Update-BugStatus.ps1`](../../scripts/Update-BugStatus.ps1) script:
      ```powershell
      ../../scripts/Update-BugStatus.ps1 -BugId "BUG-001" -NewStatus "Fixed" -FixDetails "Fixed null pointer exception" -RootCause "Missing null check" -TestsAdded "Yes" -PullRequestUrl "https://github.com/repo/pull/123"
      ```

### Finalization

15. Document the nature of the bug and the solution approach
16. Refactor code if necessary for better maintainability
17. Verify the fix resolves the issue completely
18. Update bug status from 🧪 Fixed to ✅ Verified (after testing confirmation)
    - **Manual Update**: Edit the [Bug Tracking](../../state-tracking/permanent/bug-tracking.md) file directly
    - **Automated Option**: Use [`Update-BugStatus.ps1`](../../scripts/Update-BugStatus.ps1) script:
      ```powershell
      ../../scripts/Update-BugStatus.ps1 -BugId "BUG-001" -NewStatus "Closed" -VerificationNotes "Fix verified in production, no regressions detected"
      ```
19. Update the [Bug Tracking](../../state-tracking/permanent/bug-tracking.md) document with fix details
20. **🚨 MANDATORY FINAL STEP**: Complete the Task Completion Checklist below

## Outputs

- **Modified Source Code** - Source code files that fix the bug
- **Updated Tests** - New or updated test files that verify the fix
- **Bug Fix Documentation** - Documentation of the root cause and solution approach
- **Updated Bug Tracking** - [Bug Tracking](../../state-tracking/permanent/bug-tracking.md) with bug status and resolution details updated

## State Tracking

The following state files must be updated as part of this task:

- [Bug Tracking](../../state-tracking/permanent/bug-tracking.md) - Update with:
  - Bug status progression: 🔍 Triaged → 🟡 In Progress → 🧪 Fixed → ✅ Verified
  - Fix date and resolution details
  - Root cause analysis and solution approach
  - Link to relevant pull request or commit (if applicable)
  - Any lessons learned for future development
  - Testing verification results
  - For bugs affecting specific features: Reference related feature ID from [Feature Tracking](../../state-tracking/permanent/feature-tracking.md)

**Automation Support**: The [`Update-BugStatus.ps1`](../../scripts/Update-BugStatus.ps1) script can automate status updates and ensure consistent formatting. While manual updates are supported, the script provides standardized status transitions and automatic timestamp tracking.

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

Before considering this task finished:

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] Source code changes properly fix the bug
  - [ ] Tests verify the fix and prevent regression
  - [ ] Bug fix documentation clearly explains the issue and solution
  - [ ] All modified files follow coding standards
- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] Bug tracking document shows proper status progression and final status
  - [ ] Fix date, root cause analysis, and solution approach are recorded
  - [ ] Testing verification results are documented
  - [ ] Any lessons learned are documented for future reference
  - [ ] Related feature references are updated if bug affects specific features
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Completion Instructions](../../guides/guides/feedback-form-completion-instructions.md) for each tool used, using task ID "PF-TSK-007" and context "Bug Fixing"

## Next Tasks

- [**Code Review**](code-review-task.md) - Reviews the bug fix for quality and correctness
- [**Bug Triage**](bug-triage-task.md) - If additional bugs are discovered during fixing
- [**Feature Implementation Planning**](../04-implementation/feature-implementation-planning-task.md) - If the bug fix reveals the need for new functionality

## Related Resources

- [Testing Guide](/doc/product-docs/guides/guides/testing-guide.md) - Comprehensive testing procedures and debugging approaches
- [Feature Implementation Checklist](/doc/product-docs/checklists/checklists/feature-implementation-checklist.md) - Quality assurance and testing practices applicable to bug fixes
- [Visual Notation Guide](/doc/process-framework/guides/guides/visual-notation-guide.md) - For interpreting context map diagrams and component relationships
- [Task Creation and Improvement Guide](../task-creation-guide.md) - Guide for creating and improving tasks
