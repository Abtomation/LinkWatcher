---
id: PF-PRO-007
type: Document
category: Proposal
version: 1.0
created: 2026-03-17
updated: 2026-03-17
---

# Proposal: Testing Framework Enhancements

## Overview

Six improvements to the process framework's testing infrastructure, identified during a comprehensive testing setup review (2026-03-17). These address gaps in coverage tracking, regression workflows, test automation, prioritization, specification tracking, and test quality assessment.

**Related IMPs**: PF-IMP-132, PF-IMP-133, PF-IMP-134, PF-IMP-135, PF-IMP-136, PF-IMP-137
**Proposer**: AI Agent & Human Partner
**Date Proposed**: 2026-03-17

## Context

The process framework's testing infrastructure is mature — it has 4 active testing tasks, dual testing approaches (automated + manual), a six-criteria audit framework, and comprehensive state tracking. However, it tracks whether tests *exist* and *pass*, but not how *effective* they are or how *much code* they exercise. There are also workflow gaps around when to re-run tests and how to bridge fully manual tests with automated ones.

### Current Testing Flow
```
Test Specification → Test Implementation → Test Audit → Manual Test Cases → Manual Execution
```

### What's Missing
```
                    ↓ Coverage tracking (IMP-132)
                    ↓ Regression triggers (IMP-133)
                    ↓ Semi-automated execution (IMP-134)
                    ↓ Priority-based gating (IMP-135)
Test Specification → ↓ Spec-to-impl gap tracking (IMP-136)
                    ↓ Assertion quality assessment (IMP-137)
```

---

## Enhancement 1: Coverage Tracking (PF-IMP-132) — HIGH

### Problem
The framework tracks test existence and pass/fail status but not how much code tests actually exercise. Coverage is generated locally (`htmlcov/`) but lives outside the process framework — no per-feature visibility, no historical tracking, no release-gating threshold.

### Proposed Solution
Add a coverage percentage column to tracking files and optionally capture coverage data from `Run-Tests.ps1`.

**Option A — Column in test-tracking.md**:
Add a `Coverage %` column next to `Test Cases Count`. Updated manually or via a script after running coverage.

**Option B — Column in feature-tracking.md**:
Add per-feature coverage to the feature-level view. More useful for release decisions but harder to calculate (requires per-feature coverage isolation).

**Option C — Separate coverage-tracking.md**:
Dedicated file with per-feature coverage history. Avoids cluttering existing files but adds another tracking surface.

**Recommendation**: Option A — test-tracking.md already tracks per-feature test status. Adding a coverage column keeps it in one place.

### Implementation Notes
- `Run-Tests.ps1` already supports `-Coverage` flag; output could be parsed for per-directory percentages
- Language config already has `coverageArgs` — the framework just needs to consume the output
- Consider a `Run-Tests.ps1 -Coverage -Report` mode that outputs a framework-consumable summary (e.g., JSON with per-directory coverage %)
- The coverage column value should be a snapshot date + percentage (e.g., "87% (2026-03-17)")

### Files to Change
- `test-tracking.md` — add Coverage % column
- `Run-Tests.ps1` — optional `-Report` mode outputting parseable coverage data
- `languages-config/python-config.json` — may need `coverageReportCommand` or similar
- `test-infrastructure-guide.md` — document coverage tracking workflow

---

## Enhancement 2: Regression Testing Triggers (PF-IMP-133) — MEDIUM

### Problem
No defined process for when to re-run tests after code changes. Manual test status can transition to "Needs Re-execution" but there are no trigger rules. After a refactoring or bug fix, there's no prompt to verify affected tests still pass.

### Proposed Solution
Add regression testing guidance to existing task definitions as conditional steps — not a new task, just awareness at the right moments.

### Tasks to Update

| Task | What to Add |
|------|-------------|
| **Code Refactoring (PF-TSK-022)** | After implementation: "Run affected test categories. If manual tests exist for changed features, set status to Needs Re-execution in test-tracking.md" |
| **Bug Fixing (PF-TSK-007)** | Already has regression test step (IMP-046). Extend to include manual test re-execution trigger. |
| **Release & Deployment (PF-TSK-015)** | Add pre-release gate: "Run full test sweep (`Run-Tests.ps1 -All`). Verify all manual test groups with master tests." |
| **Feature Enhancement (PF-TSK-068)** | After implementation: "Re-run tests for the enhanced feature's category" |

### Implementation Notes
- Keep it lightweight — one conditional bullet per task, not a new process
- Reference `Run-Tests.ps1 -Category <affected>` for automated re-runs
- Reference `Update-TestExecutionStatus.ps1 -Status "Needs Re-execution"` for manual test status changes
- Consider adding a `-Regression` flag to `Run-Tests.ps1` that runs only test files tagged with `crossCuttingFeatures` matching the changed feature

### Files to Change
- 4 task definitions (add conditional regression step)
- Optionally: `Run-Tests.ps1` (add `-Regression` flag)

---

## Enhancement 3: Semi-Automated Test Category (PF-IMP-134) — HIGH

### Problem
The manual testing framework has great automation for setup (`Setup-TestEnvironment.ps1`) and verification (`Verify-TestResult.ps1`), but the execution step requires human interaction. For tests like "move a file and verify LinkWatcher updates references," the *action* could be scripted while the *system under test* runs in production mode.

### Proposed Solution
Add a `run.ps1` (or `execute.ps1`) script to manual test case directories. The pipeline becomes:

```
Setup-TestEnvironment.ps1 → run.ps1 (scripted action) → [wait for system] → Verify-TestResult.ps1
```

### Test Case Structure Change
```
MT-NNN-<name>/
├── test-case.md        # Steps, preconditions, expected results
├── project/            # Starting state files
├── expected/           # Post-test expected state
└── run.ps1             # NEW: scripted action (e.g., Move-Item, edit file)
```

### Execution Modes
- **Manual**: Human follows steps in test-case.md (current behavior, unchanged)
- **Semi-automated**: Script runs `Setup → run.ps1 → wait → Verify` pipeline
- **Test case metadata**: Add `executionMode: manual | semi-automated` to test-case.md frontmatter

### Implementation Notes
- `run.ps1` contains only the *action* (e.g., `Move-Item`, `Set-Content`), not setup or verification
- The wait step is language/system-specific — for LinkWatcher, wait for file system events to propagate
- A new `Run-ManualTest.ps1` script could orchestrate the full pipeline: Setup → Execute → Wait → Verify
- Manual test case template (PF-TEM-054) needs an optional `run.ps1` section
- `New-ManualTestCase.ps1` could accept `-SemiAutomated` to generate the `run.ps1` skeleton

### Files to Change
- `New-ManualTestCase.ps1` — add `-SemiAutomated` switch
- Manual test case template (PF-TEM-054) — add executionMode metadata + run.ps1 section
- New script: `Run-ManualTest.ps1` — orchestrates Setup → Execute → Wait → Verify
- `test-infrastructure-guide.md` — document semi-automated category
- `test-tracking.md` — may need a new status icon for semi-automated tests

---

## Enhancement 4: Test Prioritization (PF-IMP-135) — MEDIUM

### Problem
All tests are treated equally. There's no concept of critical tests (must pass before any release) vs. extended tests (comprehensive but not blocking). `Run-Tests.ps1` has `-Critical` and `-Performance` flags using pytest markers, but these aren't connected to test-registry.yaml metadata.

### Proposed Solution
Add a `priority` field to test-registry.yaml entries and use it for filtering and release gating.

### Priority Levels

| Priority | Meaning | When to Run |
|----------|---------|-------------|
| **Critical** | Must pass before any release. Core functionality. | Every CI run, pre-release gate |
| **Standard** | Normal test coverage. Expected to pass. | Regular development, pre-release |
| **Extended** | Edge cases, performance, stress tests. Nice to have. | Periodic, not blocking |

### Implementation Notes
- Add `priority: Critical | Standard | Extended` to test-registry.yaml schema
- Default: `Standard` (backward compatible)
- `Run-Tests.ps1 -Critical` should filter based on registry metadata, not just pytest markers
- This requires Run-Tests.ps1 to read test-registry.yaml and generate a file list — more complex than current category-based approach
- **Alternative**: Keep it simpler — just add the field for documentation purposes and use it in the Release & Deployment task's pre-release checklist manually
- `Validate-TestTracking.ps1` should validate that the priority field exists

### Recommendation
Start with the simpler approach: add the field to test-registry.yaml, use it for documentation and manual release gating. Automate filtering later if needed.

### Files to Change
- `test-registry.yaml` — add `priority` field to all entries
- `Validate-TestTracking.ps1` — validate priority field
- Release & Deployment task — reference priorities in pre-release gate
- `test-infrastructure-guide.md` — document priority levels

---

## Enhancement 5: Spec-to-Implementation Gap Tracking (PF-IMP-136) — MEDIUM

### Problem
Test specifications define scenarios but there's no systematic way to track which scenarios are implemented vs. still pending. The Test Audit catches this retrospectively, but it's not a living tracker during development.

### Proposed Solution
Add a scenario implementation checklist to each test specification, updated as tests are written.

### Format

In each test specification file (e.g., `test-spec-0-1-1-core-architecture.md`), add:

```markdown
## Scenario Implementation Status

| # | Scenario | Test File | Status |
|---|----------|-----------|--------|
| 1 | Service initialization | PD-TST-102 | Implemented |
| 2 | Invalid config handling | PD-TST-102 | Implemented |
| 3 | Concurrent access | — | Not Implemented |
| 4 | Shutdown cleanup | — | Not Implemented |
```

### Implementation Notes
- Add section to test specification template (PF-TEM for test specs)
- Could be auto-populated by `New-TestFile.ps1` when a test file is created for a spec
- `Validate-TestTracking.ps1` could cross-check: if a spec lists scenarios as "Implemented" but no test file exists in registry, flag it
- Keep it simple — a markdown table, not a separate file. Updated manually when writing tests.
- For existing specs: backfill from audit reports which already identified implemented vs. missing scenarios

### Files to Change
- Test specification template — add Scenario Implementation Status section
- Existing 9 test specifications — backfill from audit reports
- Optionally: `New-TestFile.ps1` — auto-update spec's scenario table
- Optionally: `Validate-TestTracking.ps1` — cross-check scenarios vs. registry

---

## Enhancement 6: Test Effectiveness / Assertion Quality (PF-IMP-137) — MEDIUM

### Problem
100% coverage doesn't mean tests are correct. A test that calls a function without asserting the result gives full line coverage but catches nothing. The Test Audit's "Purpose Fulfillment" criterion is a subjective evaluation — there's no structured way to assess assertion quality.

### Proposed Solution
Add a lightweight "Test Effectiveness" assessment to the Test Audit criteria, with an optional mutation testing recommendation.

### What to Add to Test Audit

**New criterion or sub-criterion under "Purpose Fulfillment"**:

```markdown
### Assertion Quality Assessment
- **Assertion density**: Average assertions per test method (target: ≥2)
- **Behavioral assertions**: Tests check return values, state changes, and side effects (not just "no exception thrown")
- **Edge case coverage**: Tests include boundary conditions, error paths, and null/empty inputs
- **Mutation testing** (optional): If mutation testing tools are available, run them and report mutation kill rate
```

### Assertion Density Metric
A simple, language-agnostic metric: count `assert` statements (or equivalent) per test method.
- Python: `assert` keyword or `self.assert*` methods
- Dart: `expect()` calls
- Could add `assertionCountCommand` to language config for automated counting

### Implementation Notes
- Add to Test Audit Report template (PF-TAR template) as a sub-section of Purpose Fulfillment
- Add to Test Audit task (PF-TSK-030) process steps
- Keep mutation testing as "recommended if available" — don't make it mandatory
- For Python: `mutmut` or `cosmic-ray`; for Dart: no mature mutation testing tool exists
- Language config could add optional `mutationTestCommand` field

### Files to Change
- Test Audit Report template — add Assertion Quality Assessment sub-section
- Test Audit task (PF-TSK-030) — add assertion quality evaluation step
- Optionally: language config — add `assertionCountCommand` and `mutationTestCommand`
- Test Audit Usage Guide — document the new criterion

---

## Implementation Priority

| # | IMP | Enhancement | Priority | Effort | Dependencies |
|---|-----|-------------|----------|--------|--------------|
| 1 | 132 | Coverage tracking in state files | HIGH | Low | Run-Tests.ps1 (done) |
| 2 | 134 | Semi-automated manual tests | HIGH | Medium | Manual testing framework |
| 3 | 133 | Regression trigger definitions | MEDIUM | Low | None |
| 4 | 135 | Test prioritization | MEDIUM | Low | test-registry.yaml |
| 5 | 136 | Spec-to-implementation gap tracking | MEDIUM | Low | Test specifications |
| 6 | 137 | Test effectiveness / assertion quality | MEDIUM | Medium | Test Audit task |

**Recommended execution order**: 132 → 133 → 135 → 136 → 134 → 137

Rationale: Start with the quick wins (132, 133, 135, 136 are all low-effort additions to existing files), then tackle the more involved changes (134 needs new scripts, 137 needs audit process changes).

---

## Related Documents

- [Process Improvement Tracking](/process-framework/state-tracking/permanent/process-improvement-tracking.md) — PF-IMP-132 through PF-IMP-137
- [Test Infrastructure Guide](/process-framework/guides/03-testing/test-infrastructure-guide.md)
- [Test Tracking](/test/state-tracking/permanent/test-tracking.md)
- [Feature Tracking](/doc/state-tracking/permanent/feature-tracking.md)
- [Run-Tests.ps1](/process-framework/scripts/test/Run-Tests.ps1) — already made language-agnostic (PF-IMP-131)
- [Language Configurations](/process-framework/languages-config/README.md)
