---
id: TE-TAR-101
type: Testing
category: Test Audit Report
version: 1.0
created: 2026-08-25
updated: 2026-08-25
audit_date: 2026-08-25
auditor: AI Agent
description: Test audit report for feature 7.1.1 (E2E)
feature_id: 7.1.1
test_file_path: test/e2e-acceptance-testing/manage-running-linkwatcher-instances-via-control-panel/templates/TE-E2E-037-forced-terminate-on-grace-expiry/test-case.md
---

# E2E Test Audit Report - Feature 7.1.1

## Audit Overview

| Field | Value |
|-------|-------|
| **Feature ID** | 7.1.1 |
| **Test Case ID** | TE-E2E-037 |
| **Test Group** | TE-E2G-015 |
| **Test Case Location** | `test/e2e-acceptance-testing/manage-running-linkwatcher-instances-via-control-panel/templates/TE-E2E-037-forced-terminate-on-grace-expiry/test-case.md` |
| **Workflow** | WF-010: Manage running LinkWatcher instances via Control Panel |
| **Auditor** | AI Agent |
| **Audit Date** | 2026-08-25 |
| **Audit Status** | ✅ Audit Approved |

## Tests Audited

| Test Case ID | Group | Workflow | Description | Current Status |
|-------------|-------|----------|-------------|----------------|
| TE-E2E-037 | TE-E2G-015 | WF-010 | A daemon that never reaches quiescence is force-terminated at grace expiry and the panel still exits | 📋 Needs Execution |

**Acceptance criteria covered**: AC-9 (force-terminate at grace expiry, still exit without hanging, leave no file corrupted)

**Execution mode**: manual (window-driven). **Priority**: P1.

## Audit Evaluation

### 1. Fixture Correctness
**Question**: Are `project/` and `expected/` directories accurate representations of the test scenario?

**Assessment**: PASS

**Findings**:
- **Project fixture accuracy**: one sandbox with the reference pair as the no-corruption witness, a config whose `monitored_extensions` includes `.md` (load-bearing — the churn files must generate daemon events), a verbatim launcher and the root guard.
- **Expected fixture accuracy**: `expected/` holds `docs/guide.md` and `notes/setup.md` byte-identical to `project/`. Correct — nothing is moved, so a forced kill must leave both untouched.
- **Stale content**: none.
- **File completeness**: the churn files are written into a dedicated `churn/` subdirectory that is absent from `expected/`, so test scaffolding provably cannot influence the comparison. Verified.

**Evidence**:
- Verified the `expected/` root aligns with the harness contract: `Verify-TestResult.ps1` compares `<workflow>/workspace/<case>/project/` against `<workflow>/templates/<case>/expected/`, so `expected/sandbox-a/...` maps onto `project/sandbox-a/...` correctly.
- Confirmed the comparison is one-directional (only files present in `expected/` are compared), so the generated `sandbox-registry.json`, the seed-stamped `doc/project-config.json`, `logs/`, `.linkwatcher.lock` and other run artefacts correctly fall outside the assertion.
- Diffed both `expected/` files against `project/`: identical.
- Confirmed `.md` is in the fixture's `monitored_extensions`, so the churn writer actually provokes daemon logging.

**Recommendations**:
- None.

---

### 2. Scenario Completeness
**Question**: Does the test cover the full user workflow end-to-end, including edge cases?

**Assessment**: PASS

**Findings**:
- **Workflow coverage**: AC-9 fully covered, and the case frames itself correctly as the counterpart to TE-E2E-036 — that case proves the drain waits, this one proves it gives up safely. The pair is what makes the drain behaviour actually specified rather than half-tested.
- **Edge cases**: step 5 is a genuine pre-assertion gate — the operator must confirm the daemon log is growing continuously and never silent for 3 s before closing the panel. If churn is not reaching the daemon, the operator stops rather than recording a forced-terminate pass that was really just a normal quiescent drain.
- **Error paths**: the case distinguishes a hang from a forced terminate and requires capturing the process list and panel log *before* killing a hung panel, since the hang is the defect and the evidence disappears on kill.
- **Cross-feature interaction**: declares 2.2.1 and 0.1.2 alongside 7.1.1, consistent with the no-corruption witness being a reference pair.

**Evidence**:
- The quiescence threshold (>= 3 s of log silence) and the grace period (default 20 s) named in the case match the mechanism the churn writer is built to defeat (a write every 400 ms).
- `DurationSeconds` defaults to 90 s, comfortably longer than the 20 s grace plus human reaction time.

**Recommendations**:
- None.

---

### 3. Expected Outcome Accuracy
**Question**: Are the expected results in `expected/` actually correct for the given scenario?

**Assessment**: PASS

**Findings**:
- **Link target correctness**: `guide.md` references `../notes/setup.md`, which exists and is expected to stay in place.
- **Content accuracy**: identity with `project/` is the correct expectation — a forced kill must not corrupt anything.
- **Diff analysis**: zero differences; the churn scaffolding is outside `expected/` by design.
- **Manual verification**: verified by diff during this audit.
- **Note**: the discriminating assertions here are the bounded close-to-exit time and the WARN-level forced-termination log entry, not the file comparison. The file comparison is the corruption guard.

**Evidence**:
- Confirmed `churn/` appears in neither `expected/` nor `project/`, so it is created at runtime and cannot affect the one-directional comparison.

**Recommendations**:
- None.

---

### 4. Reproducibility
**Question**: Can the test be executed independently and produce consistent results?

**Assessment**: PASS

**Findings**:
- **State independence**: self-contained. `action.ps1` writes a PID file and refuses to start a second churn writer while one is recorded, preventing overlapping writers across re-runs.
- **Setup reliability**: `action.ps1` errors if the sandbox fixture is missing, and the churn writer self-terminates after its duration even if `-Stop` is forgotten — a leaked writer cannot run indefinitely.
- **Clean workspace**: passes from clean by construction.
- **Timing sensitivity**: present but bounded and self-verifying. Step 5 confirms non-quiescence before the close, and the pass criterion is “bounded and roughly the configured grace” rather than a fixed 20 s, so a `panel-config.yaml` override does not produce a spurious failure.

**Evidence**:
- `action.ps1` guards: PID-file collision check, missing-fixture check, `-Stop` path that tolerates an already-exited writer.
- The churn body's link line is justified with a measurement recorded in the script (about 2.0 KB vs 0.9 KB of log per write), and the script is explicit that this is margin rather than a hard requirement.

**Recommendations**:
- Always run `action.ps1 -Stop` after the case, as the Fail Actions require — a leaked writer keeps rewriting files and the PID file blocks the next run.

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
All five criteria pass. The case is well-constructed for a scenario that is easy to fake: step 5 forces the operator to confirm the daemon is genuinely non-quiescent before closing, so a run that was really an ordinary clean drain cannot be recorded as an AC-9 pass. The churn design is measured rather than guessed, the scaffolding is provably outside the file comparison, and the pass criterion scales with a configured grace period instead of hard-coding 20 s.

### Critical Issues
- **The entire WF-010 test group is untracked in git** — 83 files under `test/e2e-acceptance-testing/manage-running-linkwatcher-instances-via-control-panel/`, with only `.gitkeep` tracked and nothing covered by `.gitignore`. This is the same failure mode that produced CR-1 on this feature (the hook auto-open was implemented, live-verified on 2026-08-10, and silently reverted by the 2026-08-14 rollout because the work was never committed). Any `git clean` erases the whole group. Committing is a human decision and was not performed by this audit.

### Improvement Opportunities
- None material.

### Strengths Identified
- Step 5 is a pre-assertion gate against the case's own vacuous-pass mode — without confirmed non-quiescence, a “forced terminate” observation would be indistinguishable from a normal drain.
- The churn writer's design decisions are justified with recorded measurements in the script header, and the script is honest that the link line is margin rather than a requirement.
- The pass criterion is expressed relative to the configured grace period, so a `panel-config.yaml` override changes the expected wait instead of producing a false failure.
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
