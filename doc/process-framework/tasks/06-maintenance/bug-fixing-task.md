---
id: PF-TSK-007
type: Process Framework
category: Task Definition
version: 2.0
created: 2023-06-15
updated: 2026-03-04
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

  - [Project Architecture](/doc/product-docs/technical/architecture) - Understanding of the system architecture

- **Reference Only (Access When Needed):**
  - [Feature Tracking](../../state-tracking/permanent/feature-tracking.md) - To understand feature relationships and priorities when bugs affect specific features
  - [Bug Fix State Template](../../templates/templates/bug-fix-state-tracking-template.md) - For multi-session complex bug fixes (Large effort)

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished! 🚨**
>
> **⚠️ MANDATORY: Always create or update tests to verify fixes and prevent regression.**
>
> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

### Preparation

1. Review the [Bug Tracking](../../state-tracking/permanent/bug-tracking.md) document to identify a triaged bug to fix (status 🔍 Triaged)
2. If no triaged bugs are found but bugs with status 🆕 Reported exist, **ask the human partner** whether to switch to [Bug Triage](bug-triage-task.md) first. Do not proceed with an un-triaged bug.
3. Verify the selected bug has been properly triaged with priority and scope assigned
4. **Multi-session gate**: If the bug scope is "L" (Large) or requires architectural changes (e.g., redesigning a component, changing cross-cutting patterns), create a bug fix state tracking file:
   ```powershell
   cd doc/process-framework/scripts/file-creation
   .\New-BugFixState.ps1 -BugId "PD-BUG-XXX" -BugTitle "Bug Title" -Severity "High" -AffectedFeature "X.Y.Z — Feature Name" -EstimatedSessions 2
   ```
   After creation, **customize the state file to the specific bug**: fill in the Implementation Progress table with the files/components that will need changing, identify which documents need updating in the Documentation Updates table, and outline the resolution plan in the Fix Approach section. This plan serves as the blueprint for the fix and enables session handover.
   For single-session bugs (Small/Medium effort), skip this step — no state file needed.
5. Reproduce the bug to understand its exact behavior and confirm the issue
   - For code-structural bugs (e.g., missing error handling, absent code paths), confirming the gap through code review serves as reproduction
6. Document the reproduction steps for future reference
7. Analyze the affected code area to understand the context
8. Update bug status from 🔍 Triaged to 🟡 In Progress
   - **Automated Option**: Use [`Update-BugStatus.ps1`](../../scripts/update/Update-BugStatus.ps1) script:
     ```powershell
     ../../scripts/update/Update-BugStatus.ps1 -BugId "BUG-001" -NewStatus "InProgress"
     ```
9. **🚨 CHECKPOINT**: Present reproduction results, affected code area analysis, and proposed investigation approach to human partner
   - **S-scope bugs**: Combine with Step 12 — present reproduction, root cause analysis, and proposed fix approach in a single checkpoint. After approval, skip directly to Step 13.

### Execution

10. Analyze the code to identify the root cause of the bug
    - **If multi-session**: Update the Root Cause Analysis section in the bug fix state file
11. Consider alternative approaches to fixing the issue
    - **If multi-session**: Document chosen approach and alternatives in the Fix Approach section
12. **🚨 CHECKPOINT**: Present root cause analysis, proposed fix approach (with alternatives and trade-offs), and test strategy to human partner for approval
    - **S-scope bugs**: If already covered in the combined Step 9 checkpoint, skip this step.
13. **Write regression test(s) BEFORE implementing the fix** — this confirms the test actually catches the bug:
    - Write test(s) that reproduce the exact bug scenario and verify they **FAIL**
    - **Test strategy**:
      - Prefer unit tests for isolated logic bugs; add integration tests when the bug involves component interaction
      - If the root cause is a pattern (e.g., off-by-one, null handling), add 1-2 boundary/edge case tests beyond the reproduction test
      - **Use strong assertions**: Assert the old/buggy value is **NOT** present (negative assertion), not just that the new/correct value **IS** present (positive assertion). Overly permissive tests that only check for the expected value can pass even when the bug persists alongside the fix.
      - Keep regression tests focused on the specific fix — note pre-existing test gaps for a future test audit rather than expanding scope here
    - **Adding to an existing test file** (most common): Find the relevant test file in the project's test directory (see `paths.tests` in `project-config.json`). Add regression test(s) following the existing patterns in the file. After adding, update the `testCasesCount` for the file in [Test Registry](/test/test-registry.yaml). If the file is not yet in the registry, add a new entry with the next available `PD-TST` ID and bump `nextAvailable` in [ID Registry](/doc/id-registry.json).
    - **Creating a new test file** (rare): Use [`New-TestFile.ps1`](../../scripts/file-creation/New-TestFile.ps1) which auto-updates test-registry.yaml, test-implementation-tracking.md, and feature-tracking.md:
      ```powershell
      cd doc/process-framework/scripts/file-creation
      .\New-TestFile.ps1 -TestName "BugDescription" -TestType "Unit" -FeatureId "X.Y.Z" -ComponentName "ComponentName"
      ```
    - **If multi-session**: Note test file changes in the Implementation Progress table
14. Develop a fix that addresses the root cause, not just the symptoms
    - **If multi-session**: Track each file change in the Implementation Progress table
15. Verify regression tests now **PASS** with the fix applied, and test thoroughly to ensure the fix resolves the issue completely
    - **If multi-session (architectural changes)**: Run the full test suite and document results in the Validation Status section of the bug fix state file
16. Verify that the fix doesn't introduce new problems
17. Check for similar issues in other parts of the codebase
    - If the root cause is a shared pattern (e.g., regex, utility function), check **all** components that use the same pattern
    - Prioritize sibling components (same role/type, e.g., all parsers, all handlers) as they most likely share the same code pattern
18. **Create a manual validation test** in the project's manual test directory — write it **before implementing the fix** so the bug is observable first:
    - The test must set up a scenario the human partner can **reproduce via UI or filesystem actions** — not via programmatic API calls
    - Print or display **before/after state** so the human can compare the result with and without the fix
    - Example: a script that creates a temp environment with the conditions that trigger the bug, prints the current (buggy) state, then instructs the human to apply the trigger action and observe the result
    - *Skip this step for bugs with no observable behavior* (e.g., dead code removal, internal refactoring)
19. **Session boundary** (multi-session only): If ending a session before the fix is complete, update the Session Log in the bug fix state file with completed work and next-session plan. The next session resumes from this state file.
20. Update bug status from 🟡 In Progress to 🧪 Fixed
    - **Automated Option**: Use [`Update-BugStatus.ps1`](../../scripts/update/Update-BugStatus.ps1) script:
      ```powershell
      ../../scripts/update/Update-BugStatus.ps1 -BugId "BUG-001" -NewStatus "Fixed" -FixDetails "Fixed null pointer exception" -RootCause "Missing null check" -TestsAdded "Yes" -PullRequestUrl "https://github.com/repo/pull/123"
      ```

### Finalization

21. Document the nature of the bug and the solution approach
22. **Update feature documentation** (if the fix changes technical design or behavior):
    - **Feature implementation state file** (`state-tracking/features/`) — update implementation notes, known issues, or status
    - **TDD** — update technical design descriptions that no longer match the code
    - **Test specification** — update expected behavior or add new test scenarios
    - **FDD** — update functional behavior descriptions if user-facing behavior changed
    - *Before marking N/A: briefly check each referenced document to confirm it does not describe the changed component or behavior. Skip only after verifying no documentation references the fix area.*
    - **If multi-session**: Update the Documentation Updates table in the bug fix state file
23. Refactor code if necessary for better maintainability
24. Verify the fix resolves the issue completely
25. Update bug status from 🧪 Fixed to ✅ Verified (after testing confirmation)
    - **Automated Option**: Use [`Update-BugStatus.ps1`](../../scripts/update/Update-BugStatus.ps1) script:
      ```powershell
      ../../scripts/update/Update-BugStatus.ps1 -BugId "BUG-001" -NewStatus "Closed" -VerificationNotes "Fix verified in production, no regressions detected"
      ```
      > **Note**: The script automatically moves the bug entry to the Closed Bugs section and recalculates Bug Statistics — no manual editing needed.
26. Verify the [Bug Tracking](../../state-tracking/permanent/bug-tracking.md) document was updated correctly (bug moved to Closed section, statistics updated)
27. **If multi-session**: Archive the bug fix state file to `state-tracking/temporary/old/` after the bug is closed
28. **🚨 MANDATORY FINAL STEP**: Complete the Task Completion Checklist below

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
- **Conditional — multi-session** (only for Large-effort or architectural bugs):
  - [Bug fix state file](../../state-tracking/temporary/) — created via [`New-BugFixState.ps1`](../../scripts/file-creation/New-BugFixState.ps1), tracks root cause, fix approach, implementation progress, validation status, and session log. Archive to `state-tracking/temporary/old/` when bug is closed.
- **Conditional** (only when fix changes technical design or behavior):
  - [Feature implementation state files](../../state-tracking/features/) — update implementation notes, known issues, or status
  - TDD for the affected feature — update technical design descriptions
  - Test specification for the affected feature — update expected behavior or test scenarios
  - FDD for the affected feature — update functional behavior descriptions

**Automation Support**: The [`Update-BugStatus.ps1`](../../scripts/update/Update-BugStatus.ps1) script can automate status updates and ensure consistent formatting. While manual updates are supported, the script provides standardized status transitions and automatic timestamp tracking.

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

Before considering this task finished:

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] Source code changes properly fix the bug
  - [ ] Tests verify the fix and prevent regression
  - [ ] Test Registry updated (new entry or updated `testCasesCount`, ID counter bumped if new entry)
  - [ ] Bug fix documentation clearly explains the issue and solution
  - [ ] All modified files follow coding standards
- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] Bug tracking document shows proper status progression and final status
  - [ ] Fix date, root cause analysis, and solution approach are recorded
  - [ ] Testing verification results are documented
  - [ ] Any lessons learned are documented for future reference
  - [ ] Related feature references are updated if bug affects specific features
  - [ ] If fix changed technical design or behavior (Step 22):
    - [ ] Feature implementation state file updated, or N/A — verified file does not reference changed component
    - [ ] TDD updated, or N/A — verified no design changes affect TDD
    - [ ] Test specification updated, or N/A — verified no behavior change affects spec
    - [ ] FDD updated, or N/A — verified no functional change affects FDD
  - [ ] If multi-session: bug fix state file archived to `state-tracking/temporary/old/`
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Completion Instructions](../../guides/guides/feedback-form-completion-instructions.md) for each tool used, using task ID "PF-TSK-007" and context "Bug Fixing"

## Next Tasks

- [**Code Review**](code-review-task.md) - Reviews the bug fix for quality and correctness
- [**Bug Triage**](bug-triage-task.md) - If additional bugs are discovered during fixing
- [**Feature Implementation Planning**](../04-implementation/feature-implementation-planning-task.md) - If the bug fix reveals the need for new functionality

## Related Resources

- [Testing Guide](/doc/product-docs/guides/guides/testing-guide.md) - Comprehensive testing procedures and debugging approaches
- [Visual Notation Guide](/doc/process-framework/guides/guides/visual-notation-guide.md) - For interpreting context map diagrams and component relationships
- [Task Creation and Improvement Guide](../task-creation-guide.md) - Guide for creating and improving tasks
