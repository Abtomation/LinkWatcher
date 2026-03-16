# Structure Change Proposal: Manual Testing Framework

## Overview

**Proposer:** AI Agent & Human Partner
**Date Proposed:** 2026-03-14
**Target Implementation Date:** 2026-03 (across ~5 sessions)
**Scope:** Full Process (multi-type changes: tasks + templates + scripts + state files, breaking changes to existing tasks)

### Problem Statement

The current testing infrastructure focuses on automated tests written and executed by AI agents (247+ pytest methods). While comprehensive on paper, these tests:

1. **Are a black box** to the human partner — test quality and coverage cannot be easily evaluated
2. **Miss system-level bugs** — most recent bugs were found through manual human interaction (moving files, observing real behavior)
3. **Don't test the running system** — automated tests create temp directories, call functions directly, and assert return values. The actual service (watchdog monitoring → event detection → database lookup → link update) is never tested end-to-end
4. **Lack concrete reproducibility** — existing manual test procedures (tests/manual/test_procedures.md) describe steps at a high level without exact file contents, expected outcomes per file, or environment setup

### Goal

Introduce a **Manual Testing Framework** into the process framework that:

- Provides concrete, reproducible manual test cases with exact steps and expected outcomes
- Supports a test environment with pristine templates that get copied into a workspace for each test session
- Includes master test files for quick validation after code changes (test once, dig deeper only if needed)
- Tracks manual test creation and execution status alongside automated tests
- Integrates with existing task workflows (new features, bug fixes, tech debt, enhancements)
- Is **project-agnostic** — part of the framework skeleton usable by any project

---

## Current Structure

### Testing Tasks (Process Framework)

| Task | ID | Purpose | Gap |
|------|----|---------|-----|
| Test Specification Creation | PF-TSK-012 | Define what to test (specs for AI agents) | No classification of manual vs. automated scenarios. No review of UI documentation |
| Integration and Testing | PF-TSK-053 | Implement automated tests | Only automated tests |
| Test Audit | PF-TSK-030 | Evaluate test quality | Only evaluates automated tests |

### Test Tracking (State Files)

| File | Purpose | Gap |
|------|---------|-----|
| ../feature-tracking.md | Feature status with Test Status + Test Spec columns | No visibility into manual test coverage. No status for "re-testing needed" |
| ../test-implementation-tracking.md | Tracks test files per feature | Only tracks automated test files. No manual test tracking |

### Test Infrastructure (Directories)

| Location | Purpose | Gap |
|----------|---------|-----|
| tests/ | Automated pytest test suite | No manual test environment |
| tests/manual/ | Bug regression validation scripts + high-level procedures | Not reproducible: no exact file contents, no expected outcomes, no environment setup |

---

## Proposed Structure

### A. Modified Existing Tasks

#### A1. Test Specification Creation (PF-TSK-012) — Modifications

**New steps to add:**

1. **Review UI documentation** — For features with UI interactions, review the UI documentation linked from feature tracking to identify scenarios requiring manual validation
2. **Classify test scenarios** — For each test scenario in the spec, classify as:
   - `automated` — Covered by unit/integration tests
   - `manual` — Requires human interaction with the running system (file moves, UI operations, observing real-time behavior)
   - `both` — Needs automated regression test + manual validation
3. **Define manual test requirements** — For `manual` and `both` scenarios, specify:
   - What user action triggers the test
   - What file types and link formats are involved
   - What the expected observable outcome is
   - Which test group this belongs to

**New outputs:**

- Manual test scenario section in the test specification document (listing scenarios flagged as manual/both with requirements)

**New state tracking updates:**

- feature-tracking.md: Update Test Status to reflect manual test needs (new statuses, see section C1)
- ../test-tracking.md (renamed): Add manual test scenario entries

**New handover interface (outgoing):**

- → Manual Test Case Creation task: Consumes the manual test scenarios from the spec
- → Integration and Testing (PF-TSK-053): Continues to consume automated test scenarios (unchanged)

#### A2. Bug Fixing Task (PF-TSK-006) — Modifications

**New steps to add:**

1. **Check manual test coverage** — Before fixing, check if a manual test case exists for the affected behavior. If not, create one via Manual Test Case Creation task first (defines "what fixed looks like")
2. **Mark test groups for re-execution** — After fix, run `Update-TestExecutionStatus.ps1` to mark affected manual test groups as "🔄 Needs Re-execution"

**New handover interfaces:**

- → Manual Test Case Creation: For creating reproduction/verification test cases before fixing
- → Manual Test Execution: For validating the fix after code change

#### A3. Code Refactoring Task (PF-TSK-022) — Modifications

**New steps to add:**

1. **Check manual test coverage** — Before refactoring, check if affected functionality has manual test cases. If so, note which test groups will need re-execution
2. **Mark test groups for re-execution** — After refactoring, run `Update-TestExecutionStatus.ps1` to mark affected manual test groups as "🔄 Needs Re-execution"

**New handover interfaces:**

- → Manual Test Execution: For verifying behavior preservation after refactoring

#### A4. Feature Enhancement Task (PF-TSK-068) — Modifications

Similar to bug fixing: check for existing manual tests, create new ones if scope warrants it, mark for re-execution after changes.

#### A5. Integration and Testing (PF-TSK-053) — Modifications

**New step to add:**

1. **Mark manual test groups for re-execution** — After implementing new automated tests (which implies code was recently changed), mark affected manual test groups as "🔄 Needs Re-execution"

#### A6. Other Tasks That May Need Updates

The following tasks should be reviewed during implementation for potential handover interface updates:

- **Foundation Feature Implementation (PF-TSK-029)** — May need manual test creation step
- **Feature Implementation Planning (PF-TSK-044)** — Should include manual test planning in implementation plans
- **Release & Deployment (PF-TSK-015)** — Should verify all manual test groups are in "✅ Passed" state before release
- **Code Review (PF-TSK-007)** — May check if manual tests were created/updated as part of the review

> **Note**: These additional task modifications should be evaluated during implementation sessions and handled only where the handover interface is genuinely needed.

### B. New Tasks

#### B1. Manual Test Case Creation (03-testing)

**Purpose:** Create concrete, reproducible manual test cases from test specifications with exact steps, file contents, and expected outcomes.

**When to Use:**

- After test specification flags scenarios as `manual` or `both` (new feature path)
- Before bug fixing when a reproduction case needs to be defined (bug fix path)
- Before refactoring when current correct behavior needs to be captured (tech debt path)

**AI Agent Role:** QA Engineer — test design, scenario construction, expected outcome definition

**Process (high-level):**

1. **Review inputs**: Test specification (manual scenarios section), UI documentation, feature documentation
2. **Design test case structure**: Determine which test group the case belongs to, create project fixtures with exact file contents and link patterns
3. **Define expected outcomes**: Create `expected/` folder with the post-test file state, or define verification criteria in ../test-case.md
4. **Create or update master test file**: Add the new test case to the group's master test file for quick validation
5. **Update state tracking**: Register new test cases in test-tracking.md, update feature tracking

**Outputs:**

- Test case folder in `test/manual-testing/templates/<group>/<test-case>/` containing:
  - `project/` — Pristine test project files
  - `expected/` — Expected state after test execution
  - `test-case.md` — Exact steps, preconditions, expected results, verification method
- Updated master test file for the group
- Updated state tracking

**Key distinction from PF-TSK-012:** Test specs define _what_ to test and flag scenarios as manual. This task creates the _concrete, executable_ test cases with real files.

**Workflow position:**

```
NEW FEATURE:    Test Spec Creation → Implementation → Manual Test Case Creation → Manual Test Execution
BUG FIX:        Manual Test Case Creation (reproduction case) → Bug Fixing → Manual Test Execution
TECH DEBT:      Manual Test Case Creation (capture behavior) → Code Refactoring → Manual Test Execution
ENHANCEMENT:    Test Spec Creation → Feature Enhancement → Manual Test Case Creation → Manual Test Execution
```

**Handover interfaces:**

- ← PF-TSK-012 (Test Spec Creation): Receives manual test scenario requirements
- ← Bug Fixing / Code Refactoring: Receives request to create reproduction/baseline cases
- → Manual Test Execution: Produces ready-to-execute test cases
- → test-tracking.md: Updates manual test case status

#### B2. Manual Test Execution (03-testing)

**Purpose:** Execute manual test cases systematically, record results, and report issues discovered through human interaction with the running system.

**When to Use:**

- After code changes that affect tested functionality (test-tracking.md shows "🔄 Needs Re-execution")
- As part of release validation (all test groups must pass)
- After manual test cases are created (initial validation)

**AI Agent Role:** N/A — This task is primarily executed by the **human partner**. The AI agent assists with setup, result recording, and bug reporting.

**Process (high-level):**

1. **Review what needs testing**: Check ../test-tracking.md for groups marked "🔄 Needs Re-execution"
2. **Set up test environment**: Run `Setup-TestEnvironment.ps1` to copy pristine templates into workspace
3. **Execute master test first**: Run the group's master test for quick validation
   - If master test passes → group is validated, mark as ✅ Passed
   - If master test fails → execute individual test cases to isolate the issue
4. **Execute individual test cases**: Follow ../test-case.md steps exactly
5. **Verify results**: Run `Verify-TestResult.ps1` to compare workspace against expected state
6. **Record results**: Update ../test-tracking.md with pass/fail status and date
7. **Report bugs**: For failures, create bug reports using existing ../New-BugReport.ps1

**Outputs:**

- Test results recorded in ../test-tracking.md
- Bug reports for any failures
- Test session log in `test/manual-testing/results/`

**Handover interfaces:**

- ← Manual Test Case Creation: Receives ready-to-execute test cases
- ← Bug Fixing / Code Refactoring / Implementation tasks: Receives "needs re-execution" triggers
- → Bug Triage (PF-TSK-005): Sends discovered bugs
- → test-tracking.md: Updates execution status

### C. State Tracking Changes

#### C1. Feature Tracking (feature-tracking.md) — New Test Statuses

Add new statuses to the Test Status Legend (no new column — test spec link remains the entry point):

| Symbol | Status | Description |
|--------|--------|-------------|
| ⬜ | No Tests | No test specifications exist for this feature |
| 🚫 | No Test Required | Feature explicitly marked as not requiring tests |
| 📋 | Specs Created | Test specifications exist but implementation not started |
| 🟡 | In Progress | Some tests implemented, some pending |
| ✅ | All Passing | All automated AND manual tests implemented and passing |
| 🔴 | Some Failing | Some tests are failing |
| 🔧 | Automated Only | Only automated tests exist; manual test cases not yet created |
| 🔄 | Re-testing Needed | Code changes require manual test re-execution |

The key additions are `🔧 Automated Only` (signals manual test gap) and `🔄 Re-testing Needed` (signals action required after code changes).

#### C2. Test Implementation Tracking — Rename and Extend

**Rename**: `test-implementation-tracking.md` → `test-tracking.md`

**Extend tables** to include manual test entries alongside automated test entries:

| Test ID | Feature ID | Test Type | Test File/Case | Status | Last Executed | Last Updated | Notes |
|---------|------------|-----------|----------------|--------|---------------|--------------|-------|
| PD-TST-102 | 0.1.1 | Automated | ../test_service.py | ✅ Implemented | — | 2026-02-20 | Unit tests |
| MT-GRP-01 | 1.1.1 | Manual Group | ../group-01-basic-operations/master-test.md | 🔄 Needs Re-execution | 2026-03-10 | 2026-03-14 | Code change in ../handler.py |
| MT-001 | 1.1.1 | Manual Case | ../tc-001-single-file-rename/test-case.md | ✅ Passed | 2026-03-10 | 2026-03-10 | Last validated after PD-BUG-025 fix |

**New columns:**

- **Test Type**: `Automated`, `Manual Group`, `Manual Case`
- **Last Executed**: Date of last manual test execution (N/A for automated)

**New statuses for manual entries:**

| Status | Description |
|--------|-------------|
| 📋 Case Created | Manual test case exists but has never been executed |
| ✅ Passed | Last execution passed |
| 🔴 Failed | Last execution failed |
| 🔄 Needs Re-execution | Code changes invalidated the last result |
| ⬜ Not Created | Manual test case needed but not yet created |

### D. New Templates

#### D1. Manual Test Case Template

Template for `test-case.md` files. Located at `doc/process-framework/templates/templates/manual-test-case-template.md`.

Key sections:

```markdown
# Test Case: [TC-ID] [Title]

## Metadata
| Field | Value |
|-------|-------|
| Test Case ID | [TC-ID] |
| Group | [Group name] |
| Feature | [Feature ID] |
| Priority | [P0/P1/P2/P3] |
| Estimated Duration | [X minutes] |
| Created | [Date] |

## Preconditions
- [Exact starting state description]
- [Services that must be running]
- [Configuration requirements]

## Steps
1. **[Action]**: [Exact description of what to do]
   - Tool: [File Explorer / VS Code / Command Line / etc.]
   - Target: [Exact file path]
2. **[Wait/Observe]**: [What to observe and for how long]
3. **[Verify]**: [What to check]

## Expected Results
| File | Line | Before | After |
|------|------|--------|-------|
| [path] | [n] | `[old content]` | `[new content]` |

## Verification Method
- [ ] Visual inspection of files listed above
- [ ] Run `Verify-TestResult.ps1 -TestCase [TC-ID]`
- [ ] Check log output for [specific messages]

## Pass Criteria
- [ ] [Criterion 1]
- [ ] [Criterion 2]

## Notes
[Edge cases, known issues, things to watch for]
```

#### D2. Master Test File Template

Template for group-level master tests. Located at `doc/process-framework/templates/templates/manual-master-test-template.md`.

Key sections:

```markdown
# Master Test: [Group Name]

## Purpose
Quick validation sequence covering all test cases in this group.
Run this FIRST after a code change. If it passes, all individual test cases are considered validated.
If it fails, run individual test cases to isolate the issue.

## Preconditions
[Shared preconditions for all test cases in this group]

## Quick Validation Sequence
1. **[Step combining TC-001 scenario]**: [Action] → Expected: [Result]
2. **[Step combining TC-002 scenario]**: [Action] → Expected: [Result]
3. **[Step combining TC-003 scenario]**: [Action] → Expected: [Result]

## Pass Criteria
- [ ] All steps above produce expected results
- [ ] No errors in service log
- [ ] Run `Verify-TestResult.ps1 -Group [GroupName]` shows all green

## If Failed
Run individual test cases to isolate:
- [TC-001](../tc-001-xxx/test-case.md) — [Brief description]
- [TC-002](../tc-002-xxx/test-case.md) — [Brief description]
```

### E. New Scripts

All scripts located in `doc/process-framework/scripts/testing/`.

#### E1. ../Setup-TestEnvironment.ps1

**Purpose:** Copy pristine templates into workspace for test execution.

**Parameters:**

- `-Group [string]` — Optional: Only set up a specific test group
- `-Clean` — Optional: Remove existing workspace before copying
- `-ProjectRoot [string]` — Project root path (default: auto-detect)

**Behavior:**

1. If `-Clean` or workspace doesn't exist: Create/clean `test/manual-testing/workspace/`
2. Copy from `test/manual-testing/templates/` to `test/manual-testing/workspace/`
3. If `-Group` specified: Only copy the named group
4. Report what was set up

#### E2. ../Verify-TestResult.ps1

**Purpose:** Compare workspace state against expected state after test execution.

**Parameters:**

- `-TestCase [string]` — Verify a single test case
- `-Group [string]` — Verify all test cases in a group
- `-Detailed` — Show line-by-line diff for failures

**Behavior:**

1. For each test case: Compare files in `workspace/<group>/<test-case>/project/` against `templates/<group>/<test-case>/expected/`
2. Report per-file: ✅ Match / 🔴 Mismatch (with diff if `-Detailed`)
3. Summary: X/Y test cases passed

#### E3. ../Update-TestExecutionStatus.ps1

**Purpose:** Mark manual test groups as needing re-execution after code changes.

**Parameters:**

- `-FeatureId [string]` — Mark all manual test groups for a feature
- `-Group [string]` — Mark a specific test group
- `-Status [string]` — New status (default: "Needs Re-execution")
- `-Reason [string]` — Why re-execution is needed (e.g., "Bug fix PD-BUG-028")

**Behavior:**

1. Update ../test-tracking.md entries matching the feature/group
2. Update ../feature-tracking.md Test Status to "🔄 Re-testing Needed" if any manual test group is invalidated
3. Log the change with timestamp and reason

### F. Directory Structure (Framework Skeleton)

```
test/manual-testing/                       # Part of framework skeleton
├── README.md                              # How to use the manual testing system
├── templates/                             # PRISTINE fixtures (NEVER modified during tests)
│   ├── group-01-[name]/                   # Test group (e.g., "basic-file-operations")
│   │   ├── tc-001-[name]/                 # Individual test case
│   │   │   ├── project/                   # Test project files with known content
│   │   │   ├── expected/                  # Expected file state after test execution
│   │   │   └── ../test-case.md               # Steps + verification criteria
│   │   ├── tc-002-[name]/
│   │   │   └── ...
│   │   └── ../master-test.md                 # Quick-validation sequence for entire group
│   └── group-02-[name]/
│       └── ...
├── workspace/                             # GENERATED by ../Setup-TestEnvironment.ps1 (gitignored)
└── results/                               # Test session logs (gitignored)

doc/process-framework/scripts/testing/     # Testing automation scripts
├── ../Setup-TestEnvironment.ps1
├── ../Verify-TestResult.ps1
└── ../Update-TestExecutionStatus.ps1
```

> **Important**: The `templates/` directory contains pristine test fixtures that must NOT be modified by the project's file monitoring system. Each project must configure its file monitoring to exclude this directory. For LinkWatcher, add `manual-testing` to `ignored_directories` in the project configuration.

---

## Migration Strategy

### Phase 1: Foundation (Session 1)

- Create structure change state tracking file
- Create this proposal document ✅
- Get human partner approval on proposal

### Phase 2: State Tracking Changes (Session 2)

- Rename ../test-implementation-tracking.md → ../test-tracking.md
- Add new columns (Test Type, Last Executed)
- Add new manual test statuses to status legend
- Add new test statuses to ../feature-tracking.md legend (🔧 Automated Only, 🔄 Re-testing Needed)
- Update all references to ../test-implementation-tracking.md across the framework
- Modify PF-TSK-012 (Test Specification Creation): Add manual test classification steps, UI documentation review, new outputs and handover interfaces

### Phase 3: New Tasks — Manual Test Case Creation (Session 3)

- Create Manual Test Case Creation task using ../New-Task.ps1 (lightweight mode)
- Create manual test case template using ../New-Template.ps1
- Create master test file template using ../New-Template.ps1
- Create context map using ../New-ContextMap.ps1
- Customize all generated files with content from this proposal

### Phase 4: New Tasks — Manual Test Execution + Scripts (Session 4)

- Create Manual Test Execution task using ../New-Task.ps1 (lightweight mode)
- Create context map using ../New-ContextMap.ps1
- Create ../Setup-TestEnvironment.ps1
- Create ../Verify-TestResult.ps1
- Create ../Update-TestExecutionStatus.ps1
- Create test/manual-testing/ directory structure with README.md
- Add .gitignore for workspace/ and results/

### Phase 5: Task Handover Updates + Validation (Session 5)

- Modify Bug Fixing task (PF-TSK-006): Add manual test check steps and handover interfaces
- Modify Code Refactoring task (PF-TSK-022): Add manual test check steps and handover interfaces
- Modify Feature Enhancement task (PF-TSK-068): Add manual test check steps
- Modify Integration and Testing task (PF-TSK-053): Add re-execution marking step
- Review additional tasks (PF-TSK-029, PF-TSK-044, PF-TSK-015, PF-TSK-007) for handover needs
- Update ../documentation-map.md with all new artifacts
- Run ../Validate-StateTracking.ps1
- Cleanup and feedback forms

---

## Testing Approach

### Test Cases for This Structure Change

1. **State file rename**: Verify all cross-references to ../test-implementation-tracking.md are updated
2. **New task definitions**: Verify tasks are correctly registered in ai-tasks.md and ../documentation-map.md
3. **Script functionality**: Test Setup-TestEnvironment.ps1, Verify-TestResult.ps1, ../Update-TestExecutionStatus.ps1 with sample data
4. **Handover interfaces**: Trace a complete workflow (e.g., bug fix path) through all task modifications to verify interface consistency
5. **Template completeness**: Create a sample test case from the template and verify it contains all needed information

### Success Criteria

- All new tasks registered in ai-tasks.md and ../documentation-map.md
- ../test-tracking.md (renamed) contains both automated and manual test entries
- Scripts execute without errors on sample data
- All modified tasks have explicit handover interfaces to/from new tasks
- Directory structure created with README.md
- No broken cross-references (Validate-StateTracking.ps1 passes)

---

## Rollback Plan

### Trigger Conditions

- Structure change creates inconsistencies that cannot be resolved
- Task modifications break existing workflows

### Rollback Steps

1. Revert ../test-tracking.md rename (restore ../test-implementation-tracking.md from git)
2. Revert task definition modifications from git
3. Remove new task files, templates, and scripts
4. Remove test/manual-testing/ directory

---

## Approval

**Status:** Awaiting human partner review
**Date:** 2026-03-14
