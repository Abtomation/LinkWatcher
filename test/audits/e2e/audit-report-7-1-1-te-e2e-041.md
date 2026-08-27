---
id: TE-TAR-105
type: Testing
category: Test Audit Report
version: 1.0
created: 2026-08-25
updated: 2026-08-25
audit_date: 2026-08-25
auditor: AI Agent
description: Test audit report for feature 7.1.1 (E2E)
feature_id: 7.1.1
test_file_path: test/e2e-acceptance-testing/manage-running-linkwatcher-instances-via-control-panel/templates/TE-E2E-041-second-launch-surfaces-existing-window/test-case.md
---

# E2E Test Audit Report - Feature 7.1.1

## Audit Overview

| Field | Value |
|-------|-------|
| **Feature ID** | 7.1.1 |
| **Test Case ID** | TE-E2E-041 |
| **Test Group** | TE-E2G-015 |
| **Test Case Location** | `test/e2e-acceptance-testing/manage-running-linkwatcher-instances-via-control-panel/templates/TE-E2E-041-second-launch-surfaces-existing-window/test-case.md` |
| **Workflow** | WF-010: Manage running LinkWatcher instances via Control Panel |
| **Auditor** | AI Agent |
| **Audit Date** | 2026-08-25 |
| **Audit Status** | ✅ Audit Approved |

## Tests Audited

| Test Case ID | Group | Workflow | Description | Current Status |
|-------------|-------|----------|-------------|----------------|
| TE-E2E-041 | TE-E2G-015 | WF-010 | A second panel launch surfaces the existing window instead of opening a duplicate | 📋 Needs Execution |

**Acceptance criteria covered**: the second clause of AC-11 (an already-open panel window is surfaced rather than a second window being created)

**Execution mode**: manual (window-driven). **Priority**: P2.

## Audit Evaluation

### 1. Fixture Correctness
**Question**: Are `project/` and `expected/` directories accurate representations of the test scenario?

**Assessment**: PASS

**Findings**:
- **Project fixture accuracy**: one sandbox, sufficient because the subject is the panel's own single-instance guard rather than any daemon behaviour. The case states that no daemon needs to run, which keeps the fixture honest about what it is for.
- **Expected fixture accuracy**: `expected/` holds the reference pair byte-identical to `project/` — correct for a case that only opens and surfaces a window.
- **Stale content**: none.
- **File completeness**: complete.

**Evidence**:
- Verified the `expected/` root aligns with the harness contract: `Verify-TestResult.ps1` compares `<workflow>/workspace/<case>/project/` against `<workflow>/templates/<case>/expected/`, so `expected/sandbox-a/...` maps onto `project/sandbox-a/...` correctly.
- Confirmed the comparison is one-directional (only files present in `expected/` are compared), so the generated `sandbox-registry.json`, the seed-stamped `doc/project-config.json`, `logs/`, `.linkwatcher.lock` and other run artefacts correctly fall outside the assertion.
- Diffed both `expected/` files against `project/`: identical.

**Recommendations**:
- None.

---

### 2. Scenario Completeness
**Question**: Does the test cover the full user workflow end-to-end, including edge cases?

**Assessment**: PASS

**Findings**:
- **Workflow coverage**: the second clause of AC-11 is fully covered, and the scope boundary is stated explicitly rather than left as a silent gap.
- **The deliberate coverage gap is legitimate and was verified.** The case states that AC-11's first clause (the panel opening automatically when the `SessionStart` hook starts a daemon) is not currently delivered — implemented and live-verified on 2026-08-10, silently reverted by the 2026-08-14 framework rollout, re-tracked as PF-IMP-2032, with FR-8 / UI-7 / BR-8 remaining UNMET. I checked this against the 7.1.1 feature implementation state file and it is accurate in every particular, including the review finding (CR-1) and the rollout date. The instruction not to author an auto-open case before that improvement lands is correct — such a case could not pass.
- **Edge cases**: simultaneous double-launch (two launches racing before either publishes its port) is named as an accepted Known Limitation and explicitly excluded, so an executor does not test it and file a spurious defect.
- **Error paths**: the Fail Actions separate “guard worked, surfacing failed” from “guard worked, window was already in front”, and point at `panel.port` contents as the known failure mode.

**Evidence**:
- Verified the PF-IMP-2032 / CR-1 claim against `doc/state-tracking/features/7.1.1-LinkWatcher-Control-Panel-implementation-state.md`: the state file records the same revert, the same date, the same IMP, and the same UNMET set.
- Verified against the FDD that AC-11 does contain two clauses and that only the second is claimed here.

**Recommendations**:
- None. When PF-IMP-2032 lands, add a new case for the first clause rather than widening this one, as the case itself instructs.

---

### 3. Expected Outcome Accuracy
**Question**: Are the expected results in `expected/` actually correct for the given scenario?

**Assessment**: PASS

**Findings**:
- **Link target correctness**: the reference pair resolves; no rewrite is expected.
- **Content accuracy**: identity with `project/` is correct for a window-only case.
- **Diff analysis**: zero differences, all intentional.
- **Manual verification**: verified by diff during this audit.
- **Note**: the discriminating assertion is the PID comparison between steps 5 and 9 plus the visual confirmation that the surfaced window kept the position set in step 6. The file comparison is incidental here.

**Evidence**:
- Step 5 records the panel PID and step 9 requires the same single PID, so a second window would change the observable rather than needing to be spotted visually.

**Recommendations**:
- None.

---

### 4. Reproducibility
**Question**: Can the test be executed independently and produce consistent results?

**Assessment**: PASS

**Findings**:
- **State independence**: self-contained, with the strongest precondition in the group — a pre-existing panel invalidates this case completely, and the case says exactly that.
- **Setup reliability**: standard setup plus seed; step 3 verifies no panel process exists before starting, so the precondition is checked rather than assumed.
- **Clean workspace**: passes from clean by construction.
- **Timing sensitivity**: low. The case requires launching the second panel only after the first window is fully open, which also keeps it clear of the excluded race condition.
- **Step 6 is a genuine discriminating-condition design**: moving the window and sending it behind another makes “surfaced” distinguishable from “already in front”. Without it the central observation would be unfalsifiable, and the Fail Actions say so.

**Evidence**:
- Step 3 executes a process check and requires it to return nothing; the stale `panel.port` precondition is stated with the reason it matters.

**Recommendations**:
- None.

---

### 5. Precondition Coverage
**Question**: Are preconditions documented and enforceable?

**Assessment**: PASS

**Findings**:
- **Documentation**: All preconditions are listed in test-case.md, each with the reason it matters.
- **Enforcement**: There is no `run.ps1` and none is expected — this is a manual, window-driven case, so a missing `run.ps1` is correct rather than an enforcement gap. `Setup-TestEnvironment.ps1 -Clean` plus `seed-sandbox.ps1` perform the enforceable half, and `seed-sandbox.ps1` hard-fails on the one precondition that would silently corrupt the run (a sandbox missing `doc/project-config.json`).
- **LinkWatcher dependency**: The LinkWatcher dependency is documented both ways: the global install is the default and `LINKWATCHER_INSTALL_DIR` is named as the override for exercising repository source.
- **Environment assumptions**: Windows/PowerShell and the panel install directory are documented, including that `panel-config.yaml` / `panel.log` / `panel.port` resolve against the install directory rather than the workspace — the cases are hermetic in their registry and projects, not in the panel runtime files, and they say so.

**Evidence**:
- Read the case's Preconditions block against the actual requirements of its steps; every tool, process and file the steps rely on is declared.
- Confirmed against `Run-E2EAcceptanceTest.ps1` that a case with no `run.ps1` is skipped rather than failed, so the manual execution mode is handled correctly by the harness.

**Recommendations**:
- None.

---

## Overall Audit Summary

### Audit Decision
**Status**: AUDIT_APPROVED

**Status Definitions**:
- **✅ Audit Approved**: All criteria pass — test is ready for execution
- **🔄 Needs Update**: Test case or fixtures need corrections before execution
- **🔴 Audit Failed**: Scenario fundamentally flawed or fixtures incorrect

**Rationale**:
All five criteria pass. The case tests a narrow, well-chosen slice of AC-11 and is unusually careful about the falsifiability of its own central observation: step 6 exists solely so that “surfaced” cannot be confused with “already in front”. The deliberate exclusion of AC-11's first clause is justified and I verified the justification against the feature state file rather than accepting it. One tracking defect found during this audit — the case had no row in `e2e-test-tracking.md` — was fixed under Minor Fix Authority.

### Critical Issues
- **The entire WF-010 test group is untracked in git** — 83 files under `test/e2e-acceptance-testing/manage-running-linkwatcher-instances-via-control-panel/`, with only `.gitkeep` tracked and nothing covered by `.gitignore`. This is the same failure mode that produced CR-1 on this feature (the hook auto-open was implemented, live-verified on 2026-08-10, and silently reverted by the 2026-08-14 rollout because the work was never committed). Any `git clean` erases the whole group. Committing is a human decision and was not performed by this audit.

### Improvement Opportunities
- When PF-IMP-2032 lands, add a separate case for AC-11's first clause (hook auto-open) and extend the master sequence with an auto-open step, per the instruction already written into this case and the master test.

### Strengths Identified
- Step 6 (move the window, then send it behind another) is included specifically so that the pass observation can fail — without it, “the window is in front” would be true whether or not surfacing worked.
- The scope boundary against AC-11's first clause is stated with its cause, its tracking ID and an instruction not to author a case that cannot pass — and every element of it checks out against the feature state file.
- The accepted Known Limitation (simultaneous double-launch) is named and excluded, preventing a spurious defect report.
- The `action.ps1` (not `run.ps1`) naming decision is not stylistic — it is load-bearing and correct. `Run-E2EAcceptanceTest.ps1` classifies a case as fully scripted by the presence of `run.ps1` (filter at line 213); naming these `run.ps1` would have executed a window-driven case unattended with no panel open, producing a false PASS. The rationale is documented in every script header.
- `seed-sandbox.ps1` refuses to seed a sandbox missing `doc/project-config.json`, and the refusal is genuinely load-bearing: the launcher walks up to 10 levels looking for that file, the workspace sits inside the real LinkWatcher repository, so a missing config would silently start a daemon over the whole repo. Failing loudly here is the right call.
- Every sandbox launcher fixture is a byte-verbatim copy of the repository launcher (verified across all 10 sandbox projects), so the start path under test is the real one.
- Preconditions are unusually strong for manual cases: the single-instance guard, a stale `panel.port`, and pre-existing daemons are each called out with the reason they would invalidate the observation.

## Minor Fixes Applied

| Fix | What Changed | Why | Time Spent |
|-----|-------------|-----|------------|
| Missing tracking row added | Added the `TE-E2E-041` row to the E2E Test Cases table in `test/state-tracking/permanent/e2e-test-tracking.md` (Status `📋 Needs Execution`, Last Updated 2026-08-25), built header-driven so all 11 cells align with the table header. | The case existed on disk and was referenced by the master test's If Failed table, but had no tracking row. It was therefore invisible to the audit gate, invisible to `Run-E2EAcceptanceTest.ps1`'s gate check, and `Update-TestFileAuditState.ps1` would have had no row to write to. The fix is confirmed load-bearing: `New-TestAuditReport.ps1` wrote TE-TAR-105 into that row, which could not have happened before it existed. | 3 min |

## Action Items

- [ ] **Commit the WF-010 test group to git** — 83 files are currently untracked (human decision).
- [ ] Proceed to E2E Acceptance Test Execution (PF-TSK-070).

## Audit Completion

### Validation Checklist
- [x] All five evaluation criteria have been assessed
- [x] Specific findings documented with evidence
- [x] Clear audit decision made with rationale
- [x] Action items defined
- [x] E2E test tracking updated with audit status

### Next Steps
1. Proceed to execution (PF-TSK-070). The audit gate is satisfied.

### Follow-up Required
- **Re-audit Date**: Not required — audit approved.
- **Follow-up Items**: The untracked-in-git condition covering this group (see Critical Issues) is not a test-quality defect and does not gate execution, but it does put the artefacts at risk until committed.

---

**Audit Completed By**: AI Agent
**Completion Date**: 2026-08-25
**Report Version**: 1.0
