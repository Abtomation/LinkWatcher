---
id: PF-TSK-069
type: Process Framework
category: Task Definition
domain: agnostic
version: 1.1
created: 2026-03-15
updated: 2026-03-18
---

# E2E Acceptance Test Case Creation

## Purpose & Context

Create concrete, reproducible E2E acceptance test cases from test specifications, bug reports, or refactoring plans. Each test case includes exact steps, preconditions, file contents (where applicable), and expected outcomes — enabling the human partner to validate system behavior through direct interaction with the running application.

This task bridges the gap between test specifications (which define _what_ to test) and actual test execution (which validates _how_ the system behaves). Test specifications flag scenarios as requiring E2E acceptance validation; this task creates the executable test cases with real project fixtures and step-by-step instructions.

## AI Agent Role

**Role**: QA Engineer
**Mindset**: Precision-focused, detail-oriented, reproducibility-driven
**Focus Areas**: Test design, scenario construction, expected outcome definition, edge case identification
**Communication Style**: Ask about observable behaviors, clarify pass/fail criteria, confirm test environment assumptions with human partner

## When to Use

- After a test specification flags scenarios as `manual` or `both` (new feature workflow)
- Before bug fixing, when a reproduction case needs to be defined so the fix can be verified (bug fix workflow)
- Before refactoring, when current correct behavior needs to be captured as a baseline (tech debt workflow)
- After a feature enhancement, when new behavior needs E2E acceptance validation (enhancement workflow)

### Workflow Position

The position of this task varies by context:

```
NEW FEATURE:    Test Spec Creation → Implementation → E2E Acceptance Test Case Creation → E2E Acceptance Test Execution
BUG FIX:        E2E Acceptance Test Case Creation (reproduction case) → Bug Fixing → E2E Acceptance Test Execution
TECH DEBT:      E2E Acceptance Test Case Creation (capture behavior) → Code Refactoring → E2E Acceptance Test Execution
ENHANCEMENT:    Test Spec Creation → Feature Enhancement → E2E Acceptance Test Case Creation → E2E Acceptance Test Execution
```

### Prerequisites

- **New feature path**: Test specification exists with E2E acceptance test scenarios section populated
- **Bug fix path**: Bug report exists with reproduction steps (even if incomplete)
- **Tech debt path**: Refactoring plan exists identifying affected functionality
- **Enhancement path**: Enhancement state tracking file exists with scope defined

## Context Requirements

[View Context Map for this task (PF-VIS-049)](../../visualization/context-maps/03-testing/e2e-acceptance-test-case-creation-map.md)

- **Critical (Must Read):**

  - **Test Specification** (new feature/enhancement paths) - E2E acceptance test scenarios section identifying what needs E2E acceptance validation
  - **Cross-Cutting E2E Test Specification** (milestone path) - [Cross-cutting E2E spec](/test/specifications/cross-cutting-specs/) defining scenarios that span multiple features, organized by user workflow
  - [User Workflow Tracking](/doc/state-tracking/permanent/user-workflow-tracking.md) - Workflow definitions and feature mappings for multi-feature test cases
  - **Bug Report** (bug fix path) - Reproduction steps and expected vs. actual behavior
  - **Refactoring Plan** (tech debt path) - Affected functionality and expected behavior preservation
  - [E2E Acceptance Test Case Template](../../templates/03-testing/e2e-acceptance-test-case-template.md) - Template for individual test case files
  - [E2E Acceptance Master Test Template](../../templates/03-testing/e2e-acceptance-master-test-template.md) - Template for group-level quick validation files

- **Important (Load If Space):**

  - **Feature documentation** (FDD, TDD, UI documentation) - For understanding the feature's intended behavior and user interactions
  - [E2E Test Tracking](../../../test/state-tracking/permanent/e2e-test-tracking.md) - Current E2E acceptance test coverage and status
  - [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) - Feature status and test coverage overview
  - **Existing test cases for the same feature** - To avoid duplication and ensure consistency

- **Reference Only (Access When Needed):**
  - [E2E Acceptance Test Case Customization Guide](../../guides/03-testing/e2e-acceptance-test-case-customization-guide.md) - For template customization guidance
  - [Visual Notation Guide](/process-framework/guides/support/visual-notation-guide.md) - For interpreting context map diagrams

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished! 🚨**
>
> **⚠️ MANDATORY: Use automation scripts for test case creation. Never create test case directories manually.**

### Preparation

1. **Identify the workflow context**: Determine which path triggered this task (new feature, bug fix, tech debt, or enhancement) — this affects what inputs are available and what the test cases need to demonstrate
2. **Review inputs based on context**:
   - **New feature/enhancement**: Read the test specification's E2E acceptance test scenarios section. Identify which scenarios need individual test cases and which group they belong to
   - **Cross-feature milestone**: Read the [cross-cutting E2E test specification](/test/specifications/cross-cutting-specs/) for the triggered workflow. Use `-FeatureIds` to attribute the test case to all participating features and `-Workflow` to link to the workflow map
   - **Bug fix**: Read the bug report. Extract the reproduction steps and define what "fixed" looks like as a concrete expected outcome
   - **Tech debt**: Read the refactoring plan. Identify behaviors that must be preserved and create baseline E2E acceptance test cases that capture current correct behavior
3. **Review existing test cases**: Check `test/e2e-acceptance-testing/templates/` for existing test groups related to the same feature. Determine whether new test cases should join an existing group or form a new group
4. **🚨 CHECKPOINT**: Present the test case plan to the human partner:
   - Which test group(s) the cases will belong to (new or existing)
   - List of test cases to create with brief descriptions
   - Priority classification for each test case (P0–P3)
   - Whether a master test file needs to be created or updated

### Execution

5. **Create test case via script**: For each test case, run [New-E2EAcceptanceTestCase.ps1](../../scripts/file-creation/03-testing/New-E2EAcceptanceTestCase.ps1). Use `-NewGroup` for the first test case in a new group. Use `-Scripted` for test cases where the action can be automated (e.g., file moves, content edits).
   ```bash
   cd process-framework/scripts/file-creation/03-testing && pwsh.exe -ExecutionPolicy Bypass -Command '& .\New-E2EAcceptanceTestCase.ps1 -TestCaseName "descriptive-name" -GroupName "group-name" -FeatureIds "X.Y.Z" -FeatureName "Feature Name" -Workflow "WF-NNN" -NewGroup -Source "Test Spec PF-TSP-NNN" -Description "Brief description" -Confirm:$false'
   ```
   > The script automatically: creates the `E2E-NNN-[name]/` directory with `project/`, `expected/`, and `test-case.md`; assigns an E2E ID from the registry; updates the master test's "If Failed" table; adds an entry to e2e-test-tracking.md; updates feature-tracking.md Test Status. When `-NewGroup` is used, also adds a TE-E2G group row to the E2E Test Cases table and updates the Workflow Milestone Tracking table (if `-Workflow` is provided).
   >
   > When `-Scripted` is used, the script also creates a `run.ps1` skeleton and sets `Execution Mode` to `scripted` in test-case.md. Scripted test cases can be executed automatically via [Run-E2EAcceptanceTest.ps1](../../scripts/test/e2e-acceptance-testing/Run-E2EAcceptanceTest.ps1) or manually by following the Steps section.
   >
   > **Why master test first**: When `-NewGroup` is used, the script creates the master test file before the test case. The master test defines the group's scope and validation strategy. Individual test cases support isolation when the master test fails.

6. **Customize test-case.md**: Following the [E2E Acceptance Test Case Customization Guide](../../guides/03-testing/e2e-acceptance-test-case-customization-guide.md), replace all placeholder content with:
   - **Preconditions**: Exact starting state (services running, configuration, initial file state)
   - **Steps**: Numbered, unambiguous actions using specific tools (e.g., "In File Explorer, drag `report.md` from `docs/` to `archive/`")
   - **Expected Results**: Concrete, verifiable outcomes (e.g., exact file contents after the action, specific log messages, observable UI state)
   - **Verification Method**: How to confirm pass/fail (visual inspection, verification script, log check)
   - **Pass Criteria**: Checklist of conditions that must all be true for the test to pass
7. **Populate project fixtures**: Add exact files needed as the starting state to `project/` subdirectory
8. **Populate expected state**: Add post-test file state to `expected/` subdirectory for automated comparison
9. **Customize run.ps1** (scripted tests only): Replace the skeleton with the actual test action. The script receives a `$WorkspacePath` parameter and should perform only the action (e.g., `Move-Item`). See the [E2E Acceptance Test Case Customization Guide](../../guides/03-testing/e2e-acceptance-test-case-customization-guide.md) for examples.
10. **Update master test Quick Validation Sequence** (if adding to existing group): Incorporate the new scenario into the group's `master-test-[group-name].md` Quick Validation Sequence. The "If Failed" table is already updated by the script.
11. **Repeat steps 5–10** for each additional test case in the plan
12. **Update cross-cutting spec coverage** (milestone path only): If test cases were created from a [cross-cutting E2E test specification](/test/specifications/cross-cutting-specs/), update the spec's **Coverage Summary** table with the new E2E IDs, scenario mappings, group assignments, and statuses
13. **🚨 CHECKPOINT**: Present the completed test cases to the human partner for review. Confirm that:
    - Steps are unambiguous and executable by someone unfamiliar with the codebase
    - Expected results are concrete and verifiable
    - Pass criteria are complete and measurable

### Finalization

14. **Verify state tracking updates**: Confirm that New-E2EAcceptanceTestCase.ps1 correctly updated [e2e-test-tracking.md](../../../test/state-tracking/permanent/e2e-test-tracking.md) and [feature-tracking.md](../../../doc/state-tracking/permanent/feature-tracking.md) for all created test cases
15. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Outputs

- **Test case directories** in `test/e2e-acceptance-testing/templates/<group>/E2E-NNN-<name>/` — each containing:
  - `test-case.md` — Exact steps, preconditions, expected results, verification method, pass criteria
  - `project/` — Pristine test project fixtures (starting state files)
  - `expected/` — Expected file state after test execution (for automated comparison)
  - `run.ps1` — (Scripted tests only) Automated test action script
- **Master test file** — `test/e2e-acceptance-testing/templates/<group>/master-test-<group-name>.md` — Quick validation sequence for the entire group (created for new groups, updated for existing groups)
- **Updated state tracking** — New entries in e2e-test-tracking.md and feature-tracking.md

## State Tracking

The following state files must be updated as part of this task:

- [E2E Test Tracking](../../../test/state-tracking/permanent/e2e-test-tracking.md) — Add new E2E acceptance test entries (groups and individual cases) with status `📋 Case Created` and appropriate Test Type (`E2E Group` or `E2E Case`)
- [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) — Update the feature's Test Status if E2E acceptance test coverage changes the overall status

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

Before considering this task finished:

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] All planned test case directories created with `test-case.md`, `project/`, and `expected/` contents
  - [ ] Master test file created (new group) or updated (existing group) with Quick Validation Sequence
  - [ ] Test case steps are unambiguous and executable by someone unfamiliar with the codebase
  - [ ] Expected results are concrete and verifiable (not vague descriptions)
  - [ ] Project fixtures contain real, complete files (not placeholder content)
- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] [E2E Test Tracking](../../../test/state-tracking/permanent/e2e-test-tracking.md) updated with all new E2E acceptance test entries
  - [ ] [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) Test Status updated if needed
  - [ ] Cross-cutting spec Coverage Summary updated (milestone path only — skip if not applicable)
- [ ] **Human Review**: Human partner has reviewed and approved the test cases
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Completion Instructions](../../guides/framework/feedback-form-completion-instructions.md) for each tool used, using task ID "PF-TSK-069" and context "E2E Acceptance Test Case Creation"

## Next Tasks

- [**E2E Acceptance Test Execution**](e2e-acceptance-test-execution-task.md) — Execute the test cases created by this task. For new feature and enhancement paths, this happens after implementation is complete. For bug fix and tech debt paths, this happens after the code change
- [**Bug Triage**](../06-maintenance/bug-triage-task.md) — If test case creation reveals additional bugs or inconsistencies during fixture preparation

## Related Resources

- [Test Specification Creation](test-specification-creation-task.md) — Upstream task that identifies which scenarios need E2E acceptance test cases
- [New-E2EAcceptanceTestCase.ps1](../../scripts/file-creation/03-testing/New-E2EAcceptanceTestCase.ps1) — Creation script for test case directories with automatic state tracking updates
- [E2E Acceptance Test Case Template](../../templates/03-testing/e2e-acceptance-test-case-template.md) — Template for individual test case files
- [E2E Acceptance Master Test Template](../../templates/03-testing/e2e-acceptance-master-test-template.md) — Template for group-level quick validation files
- [E2E Acceptance Test Case Customization Guide](../../guides/03-testing/e2e-acceptance-test-case-customization-guide.md) — Guide for customizing test case and master test templates
