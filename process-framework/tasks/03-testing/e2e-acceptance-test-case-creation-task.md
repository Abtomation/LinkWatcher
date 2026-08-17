---
id: PF-TSK-069
type: Process Framework
category: Task Definition
domain: agnostic
version: 1.5
created: 2026-03-15
updated: 2026-07-20
change_notes: "v1.5 - PF-IMP-1592 BL-5 residue removal: Step 7's per-field customization bullets collapsed to the e2e-test-case-creation skill's field-customization guidance"
description: "Create concrete, reproducible E2E acceptance test cases from test specifications with exact steps, file contents, and expected outcomes"
complexity: medium
use_when: >-
  Create concrete, reproducible E2E acceptance test cases from test specifications with exact steps, file contents, and expected outcomes. Triggers: 'create e2e test case', 'write acceptance test', 'add E2E test for workflow X'.
triggers:
  - "create e2e test case"
  - "write acceptance test"
  - "add E2E test for workflow X"
automation: semi
scripts:
  - ../../scripts/file-creation/03-testing/New-E2EAcceptanceTestCase.ps1
trigger_status:
  - raw: "E2E spec / bug report / refactoring plan _(multi-path)_"
output_status:
  - raw: "`e2e-test-tracking.md` → `📋 Needs Execution` → (audit gate) → `✅ Audit Approved`"
next_tasks:
  - task: test-audit-task.md
    condition: "(with `-TestType E2E`) — Audit newly created E2E test cases before execution. Test cases must reach `✅ Audit Approved` status before proceeding to E2E Test Execution"
  - task: e2e-acceptance-test-execution-task.md
    condition: "Execute the test cases created by this task. For new feature and enhancement paths, this happens after implementation is complete. For bug fix and tech debt paths, this happens after the code change. Requires `✅ Audit Approved` audit status"
  - task: ../06-maintenance/bug-triage-task.md
    condition: "If test case creation reveals additional bugs or inconsistencies during fixture preparation"
---

# E2E Acceptance Test Case Creation

> **▶ Execute this task under the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md).** This file holds only this task's specific content; the universal contract every task shares lives once in the protocol and is mandatory here.

## Purpose & Context

Create concrete, reproducible E2E acceptance test cases from test specifications, bug reports, or refactoring plans. Each test case includes exact steps, preconditions, file contents (where applicable), and expected outcomes — enabling the human partner to validate system behavior through direct interaction with the running application.

This task bridges the gap between test specifications (which define _what_ to test) and actual test execution (which validates _how_ the system behaves). Test specifications flag scenarios as requiring E2E acceptance validation; this task creates the executable test cases with real project fixtures and step-by-step instructions.

> **Scope — framework self-testing**: This task also applies to **framework script workflows** when invoked from a framework-change task ([Process Improvement (PF-TSK-009)](../support/process-improvement-task.md), [Structure Change (PF-TSK-014)](../support/structure-change-task.md), [Framework Extension (PF-TSK-026)](../support/framework-extension-task.md)). Per-workflow E2E layout, `WF-NNN` IDs, and master-test conventions are identical. When invoked from appdev (PRJ-000) against framework workflows, this task silently no-ops for missing `feature-tracking.md` (appdev has no product features) and uses `user-workflow-tracking.md` as the workflow source.

## AI Agent Role

**Role**: QA Engineer
**Mindset**: Precision-focused, detail-oriented, reproducibility-driven
**Focus Areas**: Test design, scenario construction, expected outcome definition, edge case identification
**Communication Style**: Ask about observable behaviors, clarify pass/fail criteria, confirm test environment assumptions with human partner

## Context Requirements

- **Critical (Must Read):**

  - **Cross-Cutting E2E Test Specification** (milestone path) - E2E acceptance test scenarios identifying what needs E2E acceptance validation
  - **Cross-Cutting E2E Test Specification** (milestone path) - [Cross-cutting E2E spec](../../../test/specifications/cross-cutting-specs) defining scenarios that span multiple features, organized by user workflow
  - [User Workflow Tracking](../../../doc/state-tracking/permanent/user-workflow-tracking.md) - Workflow definitions and feature mappings for multi-feature test cases
  - **Bug Report** (bug fix path) - Reproduction steps and expected vs. actual behavior
  - **Refactoring Plan** (tech debt path) - Affected functionality and expected behavior preservation
  - [E2E Acceptance Test Case Template](../../templates/03-testing/e2e-acceptance-test-case-template.md) - Template for individual test case files
  - [E2E Acceptance Master Test Template](../../templates/03-testing/e2e-acceptance-master-test-template.md) - Template for group-level quick validation files

- **Important (Load If Space):**

  - [`e2e-test-case-creation` craft skill](../../../.claude/skills/e2e-test-case-creation/SKILL.md) — the customization craft (test-case.md fields, fixture population, run.ps1 recipe, hermetic-central pattern), activated in Preparation Step 1 (Check Recommended Skills). Replaces the former procedural customization guide and drives the per-file customization in Execution.
  - **Feature documentation** (FDD, TDD, UI documentation) - For understanding the feature's intended behavior and user interactions
  - [E2E Test Tracking](../../../test/state-tracking/permanent/e2e-test-tracking.md) - Current E2E acceptance test coverage and status
  - [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) - Feature status and test coverage overview
  - **Existing test cases for the same feature** - To avoid duplication and ensure consistency

## Process

> **⚠️ MANDATORY: Use automation scripts for test case creation. Never create test case directories manually.**

### Preparation

1. **Check Recommended Skills**: Read the active language-config (`languages-config/{language}/{language}-config.json`) and `project-config.json` for `recommended_skills` entries keyed to `e2e-acceptance-test-case-creation-task`. If the `e2e-test-case-creation` craft skill is available in the session, activate it — it owns the **customization craft** this task delegates to (how to fill test-case.md, the fixtures, and run.ps1 well, including the hermetic-central pattern). If it is not listed in the session, read [`SKILL.md`](../../../.claude/skills/e2e-test-case-creation/SKILL.md) directly and apply it — that file is the canonical source the Skill tool loads, so a direct read is equivalent, not degraded. The customization craft is unavailable for this run only if the skill file itself is absent (the retired procedural customization guide has no successor).
2. **Identify the workflow context**: Determine which path triggered this task (new feature, bug fix, tech debt, or enhancement) — this affects what inputs are available and what the test cases need to demonstrate
3. **Review inputs based on context**:
   - **New feature/enhancement**: Read the cross-cutting E2E test specification's scenarios section. Identify which scenarios need individual test cases and which group they belong to
   - **Cross-feature milestone**: Read the [cross-cutting E2E test specification](../../../test/specifications/cross-cutting-specs) for the triggered workflow. Use `-FeatureIds` to attribute the test case to all participating features and `-Workflow` to link to the workflow map
   - **Bug fix**: Read the bug report. Extract the reproduction steps and define what "fixed" looks like as a concrete expected outcome
   - **Tech debt**: Read the refactoring plan. Identify behaviors that must be preserved and create baseline E2E acceptance test cases that capture current correct behavior
4. **Review existing test cases**: Check `test/e2e-acceptance-testing/<workflow-slug>/templates/` for existing test cases in the same workflow. Determine whether the new test case joins an existing workflow (master test already present) or initiates the workflow's first master test (`-NewMaster` switch).
   > **Layout (PF-IMP-871 Phase 3c2)**: Per-workflow e2e dirs live under `test/e2e-acceptance-testing/<workflow-slug>/{templates,workspace,results}/`. Test cases sit directly under `templates/` (no intermediate group layer). The workflow's `templates/` subdir is pre-scaffolded by `New-WorkflowEntry.ps1` (Phase 3c1); `-NewMaster` adds the master test file inside it.
5. **🚨 CHECKPOINT**: Present the test case plan to the human partner:
   - Which test group(s) the cases will belong to (new or existing)
   - List of test cases to create with brief descriptions
   - Priority classification for each test case (P0–P3)
   - Whether a master test file needs to be created or updated

### Execution

6. **Create test case via script**: For each test case, run [New-E2EAcceptanceTestCase.ps1](../../scripts/file-creation/03-testing/New-E2EAcceptanceTestCase.ps1). Use `-NewMaster` for the first test case in a workflow that doesn't yet have a master test. Use `-Scripted` for test cases where the action can be automated (e.g., file moves, content edits).
   ```bash
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/03-testing/New-E2EAcceptanceTestCase.ps1 -TestCaseName "descriptive-name" -Workflow "workflow-slug" -FeatureIds "X.Y.Z" -FeatureName "Feature Name" -NewMaster -Source "Test Spec TE-TSP-NNN" -Description "Brief description" -Confirm:\$false
   ```
   > The script automatically: creates the `<workflow>/templates/<E2E-NNN>-[name]/` directory with `project/`, `expected/`, and `test-case.md`; assigns an E2E ID from the registry; updates the master test's "If Failed" table; adds an entry to e2e-test-tracking.md; updates feature-tracking.md Test Status. When `-NewMaster` is used, also creates the workflow's `master-test-<workflow>.md` (with a TE-E2G ID), adds a TE-E2G master row to the E2E Test Cases table, and updates the Workflow Milestone Tracking table.
   >
   > When `-Scripted` is used, the script also creates a `run.ps1` skeleton and sets `Execution Mode` to `scripted` in test-case.md. Scripted test cases can be executed automatically via [Run-E2EAcceptanceTest.ps1](../../scripts/test/e2e-acceptance-testing/Run-E2EAcceptanceTest.ps1) or manually by following the Steps section.
   >
   > **Why master test first**: When `-NewMaster` is used, the script creates the master test file before the test case. The master test defines the workflow's scope and validation strategy. Individual test cases support isolation when the master test fails.

7. **Customize test-case.md**: Following the [`e2e-test-case-creation` craft skill](../../../.claude/skills/e2e-test-case-creation/SKILL.md), replace all placeholder content per its field-customization guidance (Preconditions, Steps, Expected Results, Verification Method, Pass Criteria)
8. **Populate project fixtures**: Add exact files needed as the starting state to `project/` subdirectory
9. **Populate expected state**: Add post-test file state to `expected/` subdirectory for automated comparison
10. **Customize run.ps1** (scripted tests only): Replace the skeleton with the actual test action. The script receives a `$WorkspacePath` parameter and should perform only the action (e.g., `Move-Item`). See the [`e2e-test-case-creation` craft skill](../../../.claude/skills/e2e-test-case-creation/SKILL.md) for the action-only recipe — and its hermetic-central reference when the script under test touches central framework state.
11. **Update master test Quick Validation Sequence** (if adding to an existing workflow): Incorporate the new scenario into the workflow's `master-test-<workflow-slug>.md` Quick Validation Sequence. The "If Failed" table is already updated by the script.
12. **Repeat steps 6–11** for each additional test case in the plan
13. **Update cross-cutting spec coverage** (milestone path only): If test cases were created from a [cross-cutting E2E test specification](../../../test/specifications/cross-cutting-specs), update the spec's **Coverage Summary** table with the new E2E IDs, scenario mappings, group assignments, and statuses
14. **🚨 CHECKPOINT**: Present the completed test cases to the human partner for review. Confirm that:
    - Steps are unambiguous and executable by someone unfamiliar with the codebase
    - Expected results are concrete and verifiable
    - Pass criteria are complete and measurable

### Finalization

15. **Verify state tracking updates**: Confirm that New-E2EAcceptanceTestCase.ps1 correctly updated [e2e-test-tracking.md](../../../test/state-tracking/permanent/e2e-test-tracking.md) and [feature-tracking.md](../../../doc/state-tracking/permanent/feature-tracking.md) for all created test cases
16. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Outputs

- **Test case directories** in `test/e2e-acceptance-testing/<workflow-slug>/templates/E2E-NNN-<name>/` — each containing:
  - `test-case.md` — Exact steps, preconditions, expected results, verification method, pass criteria
  - `project/` — Pristine test project fixtures (starting state files)
  - `expected/` — Expected file state after test execution (for automated comparison)
  - `run.ps1` — (Scripted tests only) Automated test action script
- **Master test file** — `test/e2e-acceptance-testing/<workflow-slug>/templates/master-test-<workflow-slug>.md` — Quick validation sequence for the workflow (created via `-NewMaster` on the first test case in a workflow; updated as later test cases are added)
- **Updated state tracking** — New entries in e2e-test-tracking.md and feature-tracking.md

## State Tracking

The following state files must be updated as part of this task:

- [E2E Test Tracking](../../../test/state-tracking/permanent/e2e-test-tracking.md) — Add new E2E acceptance test entries (groups and individual cases) with status `📋 Needs Execution` and appropriate Test Type (`E2E Group` or `E2E Case`)
- [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) — Update the feature's Test Status if E2E acceptance test coverage changes the overall status

## ⚠️ MANDATORY Task Completion Checklist

> Completion discipline, output verification, and the feedback form are governed by the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md) (Phase C). The items below are the **task-specific** verifications that plug into it.

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
- [ ] **Feedback form** completed per the [Task Execution Protocol → Feedback step](../../guides/framework/task-execution-protocol-guide.md#feedback-step) — task ID `PF-TSK-069`, context "E2E Acceptance Test Case Creation".

## File Operations

| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | Test case directory: `E2E-NNN-<name>/` | `New-E2EAcceptanceTestCase.ps1` | Contains `test-case.md`, `project/`, `expected/`, optional `run.ps1` |
| **Creates** | Master test file (new groups) | `New-E2EAcceptanceTestCase.ps1` | `master-test-<group-name>.md` with quick validation sequences |
| **Updates** | [`e2e-test-tracking.md`](../../../test/state-tracking/permanent/e2e-test-tracking.md) | `New-E2EAcceptanceTestCase.ps1` | New E2E acceptance test entries added |
| **Updates** | [`feature-tracking.md`](../../../doc/state-tracking/permanent/feature-tracking.md) | Manual | Test Status updated |

## Next Tasks

- [**Test Audit**](test-audit-task.md) (with `-TestType E2E`) — Audit newly created E2E test cases before execution. Test cases must reach `✅ Audit Approved` status before proceeding to E2E Test Execution
- [**E2E Acceptance Test Execution**](e2e-acceptance-test-execution-task.md) — Execute the test cases created by this task. For new feature and enhancement paths, this happens after implementation is complete. For bug fix and tech debt paths, this happens after the code change. Requires `✅ Audit Approved` audit status
- [**Bug Triage**](../06-maintenance/bug-triage-task.md) — If test case creation reveals additional bugs or inconsistencies during fixture preparation

<!-- merged from transition-registry entry: E2E Acceptance Test Case Creation (PF-TSK-069) -->
### Prerequisites for Transition

- [ ] Test case directories created in `test/e2e-acceptance-testing/<workflow-slug>/templates/TE-E2E-NNN-<name>/` (PF-IMP-871 Phase 3c2 per-workflow layout — group layer collapsed)
- [ ] Each test case contains: `test-case.md`, `project/`, `expected/`, and `run.ps1` (for scripted tests)
- [ ] Master test file at `test/e2e-acceptance-testing/<workflow-slug>/templates/master-test-<workflow>.md`
- [ ] E2E test tracking (`e2e-test-tracking.md`) updated with new test cases
- [ ] Feature tracking updated with E2E test references

### Next Task Selection

```
What is the context?
├─ Test cases ready → Test Audit (PF-TSK-030, -TestType E2E) → ✅ Audit Approved → E2E Test Execution (PF-TSK-070)
│   └─ Reason: Newly created test cases must be audited before execution
├─ Test case creation revealed additional bugs → Bug Triage (PF-TSK-041)
└─ More test cases needed for other groups → Continue E2E Test Case Creation (next group)
```

### Preparation for Next Task

1. Verify all test case `project/` and `expected/` directories contain correct fixtures
2. Confirm master test file lists all test cases in the group
3. Review `e2e-test-tracking.md` for groups ready for audit

## Related Resources

- [Test Specification Creation](test-specification-creation-task.md) — Automated test specification task (E2E scenarios come from cross-cutting specs, not per-feature test specs)
- [New-E2EAcceptanceTestCase.ps1](../../scripts/file-creation/03-testing/New-E2EAcceptanceTestCase.ps1) — Creation script for test case directories with automatic state tracking updates
- [E2E Acceptance Test Case Template](../../templates/03-testing/e2e-acceptance-test-case-template.md) — Template for individual test case files
- [E2E Acceptance Master Test Template](../../templates/03-testing/e2e-acceptance-master-test-template.md) — Template for group-level quick validation files
- [`e2e-test-case-creation` craft skill](../../../.claude/skills/e2e-test-case-creation/SKILL.md) — the test-case customization craft (replaces the retired customization guide); activated by the Check Recommended Skills step
