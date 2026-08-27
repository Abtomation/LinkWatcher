---
id: TE-TAR-099
type: Testing
category: Test Audit Report
version: 1.0
created: 2026-08-25
updated: 2026-08-25
audit_date: 2026-08-25
auditor: AI Agent
description: Test audit report for feature 7.1.1 (E2E)
feature_id: 7.1.1
test_file_path: test/e2e-acceptance-testing/manage-running-linkwatcher-instances-via-control-panel/templates/TE-E2E-035-start-and-stop-daemon-from-panel/test-case.md
---

# E2E Test Audit Report - Feature 7.1.1

## Audit Overview

| Field | Value |
|-------|-------|
| **Feature ID** | 7.1.1 |
| **Test Case ID** | TE-E2E-035 |
| **Test Group** | TE-E2G-015 |
| **Test Case Location** | `test/e2e-acceptance-testing/manage-running-linkwatcher-instances-via-control-panel/templates/TE-E2E-035-start-and-stop-daemon-from-panel/test-case.md` |
| **Workflow** | WF-010: Manage running LinkWatcher instances via Control Panel |
| **Auditor** | AI Agent |
| **Audit Date** | 2026-08-25 |
| **Audit Status** | ✅ Audit Approved |

## Tests Audited

| Test Case ID | Group | Workflow | Description | Current Status |
|-------------|-------|----------|-------------|----------------|
| TE-E2E-035 | TE-E2G-015 | WF-010 | Start a daemon from the panel, stop it, and confirm a second start creates no duplicate daemon | 📋 Needs Execution |

**Acceptance criteria covered**: AC-2 (start), AC-3 (stop drains and the row reflects it) and AC-10 (no second daemon for an already-running project)

**Execution mode**: manual (window-driven). **Priority**: P0.

## Audit Evaluation

### 1. Fixture Correctness
**Question**: Are `project/` and `expected/` directories accurate representations of the test scenario?

**Assessment**: PASS

**Findings**:
- **Project fixture accuracy**: two identically-shaped sandbox projects, matching the fixture table. `sandbox-b` exists specifically to prove the start is row-scoped rather than registry-wide — a purposeful fixture, not filler.
- **Expected fixture accuracy**: `expected/` holds the four content files, byte-identical to `project/`, which is correct for a case that performs no move.
- **Stale content**: none.
- **File completeness**: complete. The seed-stamped `doc/project-config.json` is correctly excluded from `expected/`.

**Evidence**:
- Verified the `expected/` root aligns with the harness contract: `Verify-TestResult.ps1` compares `<workflow>/workspace/<case>/project/` against `<workflow>/templates/<case>/expected/`, so `expected/sandbox-a/...` maps onto `project/sandbox-a/...` correctly.
- Confirmed the comparison is one-directional (only files present in `expected/` are compared), so the generated `sandbox-registry.json`, the seed-stamped `doc/project-config.json`, `logs/`, `.linkwatcher.lock` and other run artefacts correctly fall outside the assertion.
- Diffed all four `expected/` files against `project/`: identical, as required.

**Recommendations**:
- None.

---

### 2. Scenario Completeness
**Question**: Does the test cover the full user workflow end-to-end, including edge cases?

**Assessment**: PASS

**Findings**:
- **Workflow coverage**: all three acceptance criteria are exercised, and the AC-10 half is the strongest part of the case — it captures the PID set before and after the duplicate-start attempt and compares them, which is the only assertion that actually distinguishes “no second daemon” from “the UI looked unchanged”.
- **Edge cases**: the case pre-empts the most likely misreading by stating that a healthy daemon is a process *pair* (venv shim plus real interpreter) and that a process count is never an instance count. Without that note, step 6 would look like an AC-10 failure to anyone reading two rows.
- **Error paths**: step 7 explicitly allows a disabled start control to satisfy AC-10 by construction, so a correct implementation cannot be failed on a technicality.
- **Cross-feature interaction**: correctly scoped to 7.1.1; the note that start goes through the project launcher by design (D-T4) tells an executor where to look when a start fails.

**Evidence**:
- Mapped AC-2 to steps 4–5, AC-10 to steps 7–8, AC-3 to steps 10–11; every criterion has a step and a pass criterion.

**Recommendations**:
- None.

---

### 3. Expected Outcome Accuracy
**Question**: Are the expected results in `expected/` actually correct for the given scenario?

**Assessment**: PASS

**Findings**:
- **Link target correctness**: the `guide.md` → `notes/setup.md` references resolve in both sandboxes.
- **Content accuracy**: identity with `project/` is the correct expectation for a no-move case.
- **Diff analysis**: zero differences, all intentional.
- **Manual verification**: verified by diff during this audit.
- **Note**: the load-bearing assertion in this case is not the file comparison but the PID-set equality between steps 6 and 8. That one is genuinely discriminating — a duplicate daemon changes it.

**Evidence**:
- `diff` over all four file pairs: no differences.
- Confirmed the AC-10 assertion is a before/after PID-set comparison rather than a UI observation.

**Recommendations**:
- None.

---

### 4. Reproducibility
**Question**: Can the test be executed independently and produce consistent results?

**Assessment**: PASS

**Findings**:
- **State independence**: self-contained; no dependency on any other case having run.
- **Setup reliability**: standard setup plus seed; the registry is generated with absolute roots.
- **Clean workspace**: passes from clean by construction.
- **Timing sensitivity**: bounded and justified — up to 30 s for the start to converge, with the reason given (the launcher sleeps ~2 s for its own post-start check and the panel needs up to two poll cycles), and up to the 20 s grace period for the stop.

**Evidence**:
- The 30 s and 20 s waits are tied to named mechanisms rather than being arbitrary sleeps, so an executor can tell a slow pass from a real failure.

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
All five criteria pass. The case covers three acceptance criteria, and its central AC-10 assertion is built on a before/after PID-set comparison rather than on a UI impression — the difference between a test that can catch a duplicate daemon and one that cannot. The process-pair note and the explicit allowance for a disabled start control both prevent false failures without weakening the assertion.

### Critical Issues
- **The entire WF-010 test group is untracked in git** — 83 files under `test/e2e-acceptance-testing/manage-running-linkwatcher-instances-via-control-panel/`, with only `.gitkeep` tracked and nothing covered by `.gitignore`. This is the same failure mode that produced CR-1 on this feature (the hook auto-open was implemented, live-verified on 2026-08-10, and silently reverted by the 2026-08-14 rollout because the work was never committed). Any `git clean` erases the whole group. Committing is a human decision and was not performed by this audit.

### Improvement Opportunities
- None material.

### Strengths Identified
- AC-10 is asserted by comparing captured PID sets, not by looking at the window — the only form of the assertion that can actually fail for the reason it names.
- The process-pair note and the disabled-control allowance each remove a specific, likely false-failure path without loosening what is being tested.
- The `action.ps1` (not `run.ps1`) naming decision is not stylistic — it is load-bearing and correct. `Run-E2EAcceptanceTest.ps1` classifies a case as fully scripted by the presence of `run.ps1` (filter at line 213); naming these `run.ps1` would have executed a window-driven case unattended with no panel open, producing a false PASS. The rationale is documented in every script header.
- `seed-sandbox.ps1` refuses to seed a sandbox missing `doc/project-config.json`, and the refusal is genuinely load-bearing: the launcher walks up to 10 levels looking for that file, the workspace sits inside the real LinkWatcher repository, so a missing config would silently start a daemon over the whole repo. Failing loudly here is the right call.
- Every sandbox launcher fixture is a byte-verbatim copy of the repository launcher (verified across all 10 sandbox projects), so the start path under test is the real one.
- Preconditions are unusually strong for manual cases: the single-instance guard, a stale `panel.port`, and pre-existing daemons are each called out with the reason they would invalidate the observation.

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
