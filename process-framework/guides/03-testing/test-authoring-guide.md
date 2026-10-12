---
id: PF-GDE-079
type: Process Framework
category: Guide
version: 1.8
created: 2026-09-03
updated: 2026-09-28
description: "The agnostic test-authoring procedure every test-writing task cites as an executable step: name the discriminating condition, choose harness and home, write, prove the test fails for the defect's reason (fail-first or mutation), record the contrast, sync tracking"
related_task: PF-TSK-007,PF-TSK-053,PF-TSK-024,PF-TSK-052,PF-TSK-030,PF-TSK-005
---

# Test Authoring Guide

## Overview

A test counts as coverage only once it has been shown to fail for the reason it names. This guide is the one procedure for getting there — the same four phases whether the test pins a defect, covers a feature, characterizes code before a refactor, or drives an E2E fixture. Task steps that write tests cite it as an executable step; the reviewer-side checks (Test Audit, Code Review Step 13, the bug-fix review path) verify the evidence it produces.

The doctrine it applies — the discriminating condition and mutation verification — lives once, in [Load-Bearing Assertions](../support/script-development-quick-reference.md#load-bearing-assertions-discriminating-condition--mutation-verification) (PF-GDE-019). This guide applies it to **product tests**; framework-script suites and migration-entry pre-checks cite that section directly.

## When to Use

Follow this procedure whenever a task step writes or changes a test:

- a **regression test** for a defect (Bug Fixing) — [Phase 3](#phase-3-prove) is fail-first;
- **coverage tests** for a feature under implementation (Integration and Testing, Core Logic, Data Layer, State Management, UI, Foundation Feature) — Phase 3 is mutation verification;
- **characterization tests** before a behaviour-preserving change (Code Refactoring, Codebase Source Migration);
- **edits to existing tests** (Feature Enhancement, test-only refactors) — an edited assertion re-enters Phase 3.

The harness-specific craft stays in its own home — E2E instruction fixtures in the `e2e-test-case-creation` skill, benchmarks in the [Performance Testing Guide](performance-testing-guide.md) — and each harness discharges Phase 3 in its own form (an oracle observed failing; a benchmark that detects the regression it guards). The obligations do not change with the harness.

## Phase 1: Before writing

1. **Name the discriminating condition.** For each behaviour the test will assert, state the condition under which the assertion would be *absent* or wrong. A fixture that makes the asserted value true by construction says nothing about the code ([obligation 1](../support/script-development-quick-reference.md#load-bearing-assertions-discriminating-condition--mutation-verification)).
2. **Choose the harness and the test's home.** Take the test type from the source specification or the defect — unit for isolated logic, integration for component interaction, characterization for current behaviour, fixture or benchmark where the harness demands it. The `-TestType` vocabulary is the project's own test subdirectories (`Run-Tests.ps1 -ListCategories`), never a fixed framework list. Then decide **new file vs. existing file**:
   - **Add to an existing file** (default) when a test file already covers the affected component — follow that file's patterns and update its markers (feature, priority) if they change.
   - **Create a new file** when no existing file covers the component, the change spans components no single file covers, or it reveals a behaviour category that does not fit the existing organization. Always create through [`New-TestFile.ps1`](../../scripts/file-creation/03-testing/New-TestFile.ps1), which writes the markers and registers the file in test-tracking; the parameter and customization craft is the [test-file customization reference](../../../.claude/skills/test-authoring/references/test-file-customization.md).
3. **Land new surface first.** When the change introduces a module, parameter, or helper, land that surface with the old or a no-op behaviour *before* the first test run, so the first failure carries the defect's signature instead of a collection-time import error.
4. **Check module resolution.** Confirm the harness imports the code under test from the tree you are editing — an installed copy can silently outrank it — before reading any result as evidence.
5. **Characterize before a behaviour-preserving change.** Where coverage of the paths the change touches is thin, pin their *current* behaviour first, imperfections included: characterization tests are a safety net, not a quality judgment. Scope them to the paths the change touches, and count transitive callers that exercise the branch through a public API as coverage.

## Phase 2: Write

6. **Assert the behaviour, not the call.** Check return values, state changes, and side effects — not merely that no exception was thrown. When the root cause is a pattern (off-by-one, null handling), add one or two boundary cases beyond the reproduction. Keep a regression test focused on the defect; note pre-existing gaps for the next test audit rather than widening the change.
7. **Make negative assertions discriminating.** Assert that the buggy value is absent *and* confirm the asserted fragment cannot occur in correct output — prefer an exact expected-line comparison to a substring, or the assertion fails a working fix.
8. **Make the fixture capable.** The fixture — or the manual validation script — must be able to reach the branch under test and produce the condition being asserted. A script that only prints before and after state cannot fail, so it is not a test.

## Phase 3: Prove

9. **Fail-first where a defect exists.** Run the tests before implementing the fix and read every failure **per test** for the defect's own signature — not a setup error, a wrong import path, or an unrelated assertion. A test that *passes* before the fix is not a regression test: its fixture never reached the defective branch, so fix the fixture or drop the test. A collection-time import error on code that does not exist yet is neither the signature nor a harness fault — go back to step 3. Writing the tests after the fix forfeits the evidence this phase exists to produce.
10. **Mutation-verify where no defect exists.** Break the behaviour the assertion asserts, confirm *that* assertion goes red, restore. Green under mutation means the assertion was vacuous; a *different* assertion going red means the mapping is wrong — fix the mapping, not the mutation ([obligation 2](../support/script-development-quick-reference.md#load-bearing-assertions-discriminating-condition--mutation-verification)). Do it per assertion while authoring; a later sweep is the review layer this step replaces.
11. **Record the contrast — where and when.** The record is one line naming what was broken and which tests went red:

   | Work | Carrier | When |
   |---|---|---|
   | Bug fix | the bug row's `-VerificationNotes` / `-TestsAdded` via [`Update-BugStatus.ps1`](../../scripts/update/Update-BugStatus.ps1) | at the status transition (Bug Fixing's status step, or the bug-fix review path's B8) — the script has no notes-only mode |
   | Feature implementation | the feature implementation state file's testing notes | with the coverage record (Integration and Testing Step 14) |
   | Refactoring | the refactoring plan's Test Baseline field | when the baseline is taken |
   | Onboarding migration | the retrospective master state's session log | at the migration step |
   | Anything else | the suite or file header | when the test is written |

## Phase 4: Close

12. **Sync tracking.** After adding tests to an existing file, run [`Validate-TestTracking.ps1`](../../scripts/validation/Validate-TestTracking.ps1) `-Fix -Path "<the test files you touched>"`: the `-Path` scope confines the sync to your files' rows, where an unscoped `-Fix` would also sync every other drifted row (PF-IMP-1176); `New-TestFile.ps1` sets the count only at creation, so an existing file's count is otherwise left stale (PF-IMP-1047). Unrelated repo-wide drift stays out of scope — note it as an observation.
13. **Complete the documentation steps** in [Test Infrastructure Guide — Test Documentation Completeness](test-infrastructure-guide.md#test-documentation-completeness): update the feature's test specification, validate, and decide whether to escalate to Test Specification Creation.
14. **Hand the evidence to the reviewer-side check.** Test Audit, Code Review (Step 13) and the bug-fix review path verify that the obligations were discharged against this guide; the author records the evidence and does not pre-empt the verdict.

## Example

A fix adds a `--strict` parameter to a parser and corrects a swallowed error. Phase 1: the discriminating condition is "the malformed line produces no error"; the test lands in the existing parser file; the parameter is added first as a no-op so the suite still collects. Phase 2: the test feeds the malformed line and asserts the exact error line, plus one boundary case (an empty line). Phase 3: run before the fix — the strict test fails on the missing error (the defect's signature), the boundary test passes and is rewritten until it fails too. Phase 4: `Validate-TestTracking.ps1 -Fix -Path` on the file, the spec gains the two scenarios, and the bug row's `-VerificationNotes` at the transition reads *"pre-fix: 2 red (missing error, empty-line passthrough); post-fix: green"*.

## Related Resources

- [Load-Bearing Assertions — Script Development Quick Reference (PF-GDE-019)](../support/script-development-quick-reference.md#load-bearing-assertions-discriminating-condition--mutation-verification) — the two obligations this procedure discharges
- [Test Infrastructure Guide (PF-GDE-050)](test-infrastructure-guide.md) — [Test Priority](test-infrastructure-guide.md#test-priority), [Test Documentation Completeness](test-infrastructure-guide.md#test-documentation-completeness), [Test Isolation Rules](test-infrastructure-guide.md#test-isolation-rules)
- [`test-authoring` craft skill](../../../.claude/skills/test-authoring/SKILL.md) — the judgment layer of this procedure (finding the discriminating condition, choosing the mutation, reading a failure for the defect's signature, fixture capability) with its [harness recipes](../../../.claude/skills/test-authoring/references/harness-recipes.md) (pytest, Pester, E2E fixtures, benchmarks) and [test-file customization reference](../../../.claude/skills/test-authoring/references/test-file-customization.md) (`New-TestFile.ps1` parameters, mock strategy, generated-file customization)
- [Instruction fixtures — designing assertions that discriminate](../../../.claude/skills/e2e-test-case-creation/references/instruction-fixtures.md#designing-assertions-that-discriminate) — the E2E form of Phase 3 (an oracle observed failing)
- [Performance Testing Guide (PF-GDE-060)](performance-testing-guide.md) — measurement, flaky-benchmark avoidance, tolerance bands
- [Bug Fixing (PF-TSK-007)](../../tasks/06-maintenance/bug-fixing-task.md), [Integration and Testing (PF-TSK-053)](../../tasks/04-implementation/integration-and-testing.md) — the first citing steps; [Test Audit (PF-TSK-030)](../../tasks/03-testing/test-audit-task.md), [Code Review (PF-TSK-005)](../../tasks/06-maintenance/code-review-task.md) Step 13 and the [Code Review bug-fix path](../../tasks/06-maintenance/code-review-bug-fix-path.md) — the reviewer-side checks
