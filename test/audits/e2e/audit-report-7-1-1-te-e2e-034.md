---
id: TE-TAR-098
type: Testing
category: Test Audit Report
version: 1.0
created: 2026-08-25
updated: 2026-08-25
audit_date: 2026-08-25
auditor: AI Agent
description: Test audit report for feature 7.1.1 (E2E)
feature_id: 7.1.1
test_file_path: test/e2e-acceptance-testing/manage-running-linkwatcher-instances-via-control-panel/templates/TE-E2E-034-panel-lists-running-daemons/test-case.md
---

# E2E Test Audit Report - Feature 7.1.1

## Audit Overview

| Field | Value |
|-------|-------|
| **Feature ID** | 7.1.1 |
| **Test Case ID** | TE-E2E-034 |
| **Test Group** | TE-E2G-015 |
| **Test Case Location** | `test/e2e-acceptance-testing/manage-running-linkwatcher-instances-via-control-panel/templates/TE-E2E-034-panel-lists-running-daemons/test-case.md` |
| **Workflow** | WF-010: Manage running LinkWatcher instances via Control Panel |
| **Auditor** | AI Agent |
| **Audit Date** | 2026-08-25 |
| **Audit Status** | ✅ Audit Approved |

## Tests Audited

| Test Case ID | Group | Workflow | Description | Current Status |
|-------------|-------|----------|-------------|----------------|
| TE-E2E-034 | TE-E2G-015 | WF-010 | Panel lists daemons for a two-project sandbox registry, including a daemon started outside the panel | 📋 Needs Execution |

**Acceptance criteria covered**: AC-1 (lists running daemons with correct identity and status) and AC-4 (a daemon the panel did not start is listed and stoppable)

**Execution mode**: manual (window-driven). **Priority**: P0.

## Audit Evaluation

### 1. Fixture Correctness
**Question**: Are `project/` and `expected/` directories accurate representations of the test scenario?

**Assessment**: PASS

**Findings**:
- **Project fixture accuracy**: both `sandbox-a` and `sandbox-b` carry the five load-bearing files the fixture table claims — `doc/project-config.json` (root-resolution guard), a verbatim launcher, a per-project `linkwatcher-config.yaml`, and the `docs/guide.md` → `notes/setup.md` reference pair. The two projects are deliberately identical in shape and differ only by `project_id`, which is exactly what a two-row listing test needs.
- **Expected fixture accuracy**: `expected/` holds the four content files and is byte-identical to `project/` — correct, because this case asserts that nothing is rewritten.
- **Stale content**: none. No placeholder text, no content copied from another workflow.
- **File completeness**: `doc/project-config.json` is deliberately absent from `expected/` because `seed-sandbox.ps1` stamps an absolute `root_directory` into it at test time. Excluding it is correct; including it would produce a guaranteed false mismatch on every machine.

**Evidence**:
- Verified the `expected/` root aligns with the harness contract: `Verify-TestResult.ps1` compares `<workflow>/workspace/<case>/project/` against `<workflow>/templates/<case>/expected/`, so `expected/sandbox-a/...` maps onto `project/sandbox-a/...` correctly.
- Confirmed the comparison is one-directional (only files present in `expected/` are compared), so the generated `sandbox-registry.json`, the seed-stamped `doc/project-config.json`, `logs/`, `.linkwatcher.lock` and other run artefacts correctly fall outside the assertion.
- Diffed all four `expected/` files against their `project/` counterparts: all identical, as the no-change scenario requires.

**Recommendations**:
- None.

---

### 2. Scenario Completeness
**Question**: Does the test cover the full user workflow end-to-end, including edge cases?

**Assessment**: PASS

**Findings**:
- **Workflow coverage**: both acceptance criteria are exercised end to end. AC-4 in particular is set up honestly — `sandbox-a` is started by running that project's own launcher directly (step 3), which is what the `SessionStart` hook does, rather than by the panel. A test that started it from the panel would not test AC-4 at all.
- **Edge cases**: step 5 asserts the pending-discovery wait state and that the panel must never claim “No registered projects found” while the first poll is outstanding. That is a targeted regression guard for the defect recorded in the feature state file (§9 Decision 11b, first poll measured at ~7.5 s) — coverage beyond the bare acceptance criterion.
- **Error paths**: step 3 carries a resolved-root check that aborts if the launcher banner names the LinkWatcher repository instead of the sandbox, catching the one setup error that would be catastrophic rather than merely wrong.
- **Cross-feature interaction**: correctly scoped to 7.1.1 only; no move or rename is performed, so no parser or updater behaviour is drawn in.

**Evidence**:
- Cross-checked the case against the AC list in `fdd-7-1-1-linkwatcher-control-panel.md`: AC-1 and AC-4 are stated in the case header and each maps to specific steps (6–7 for AC-1, 7–9 for AC-4).

**Recommendations**:
- None.

---

### 3. Expected Outcome Accuracy
**Question**: Are the expected results in `expected/` actually correct for the given scenario?

**Assessment**: PASS

**Findings**:
- **Link target correctness**: `docs/guide.md` references `../notes/setup.md` in both sandboxes and that target exists — the references resolve, so a spurious rewrite would be visible as a mismatch.
- **Content accuracy**: the expected content is correct precisely *because* it equals `project/` — this case asserts non-modification, and identity is the correct expected outcome.
- **Diff analysis**: zero differences between `project/` and `expected/`, all intentional.
- **Manual verification**: verified by direct diff during this audit rather than assumed.

**Evidence**:
- `diff` over all four file pairs returned no differences.
- Confirmed `notes/setup.md` exists in both sandboxes, so the `guide.md` references are live rather than already-broken.

**Recommendations**:
- None.

---

### 4. Reproducibility
**Question**: Can the test be executed independently and produce consistent results?

**Assessment**: PASS

**Findings**:
- **State independence**: the case is self-contained — `Setup-TestEnvironment.ps1 -Clean` plus `seed-sandbox.ps1` establish the whole starting state, and the registry is generated into the workspace rather than shipped, so no absolute path is baked into a fixture.
- **Setup reliability**: `seed-sandbox.ps1` stamps each sandbox config and writes the registry with absolute roots; it prints the exact panel command to use, removing the main transcription error.
- **Clean workspace**: passes on a fresh workspace by construction.
- **Timing sensitivity**: bounded and disclosed — up to 10 s for the first discovery pass, with the measured 7.5 s figure given so an operator does not call a slow poll a failure.
- **Observation (not a defect)**: because this is a no-change case, `Verify-TestResult.ps1` also passes on a freshly set-up workspace where the test was never run. Its green therefore proves “nothing was corrupted”, not “the test executed”. The case does not overclaim — the behavioural evidence sits in the process, visual and log checks alongside it — but the automated check should not be read alone.

**Evidence**:
- Traced the setup chain end to end: `Setup-TestEnvironment.ps1` copies `templates/<case>/project/` into `workspace/<case>/project/`; `seed-sandbox.ps1` writes `sandbox-registry.json` beside it, outside the compared tree.

**Recommendations**:
- None blocking. When recording results, cite the process/visual/log checks as the primary evidence for this case and treat the `Verify-TestResult.ps1` green as the corruption guard it is.

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
All five criteria pass. Fixtures are accurate and complete, the two acceptance criteria are covered with AC-4 set up honestly (external launcher, not a panel start), expected outcomes were verified by direct diff, and preconditions are documented with the reasons they matter. The one reproducibility observation — that a no-change case yields a trivially-green automated comparison — is inherent to asserting non-modification and is not overclaimed by the case.

### Critical Issues
- **The entire WF-010 test group is untracked in git** — 83 files under `test/e2e-acceptance-testing/manage-running-linkwatcher-instances-via-control-panel/`, with only `.gitkeep` tracked and nothing covered by `.gitignore`. This is the same failure mode that produced CR-1 on this feature (the hook auto-open was implemented, live-verified on 2026-08-10, and silently reverted by the 2026-08-14 rollout because the work was never committed). Any `git clean` erases the whole group. Committing is a human decision and was not performed by this audit.

### Improvement Opportunities
- Consider stating explicitly in the Verification Method that the `Verify-TestResult.ps1` line is a corruption guard rather than proof of execution, so a future executor does not read a green run as a completed test.

### Strengths Identified
- Step 5 turns a known past defect (the false “No registered projects found” during the first poll) into a standing assertion — regression coverage earned from a real incident.
- The step 3 resolved-root check catches the one setup mistake whose blast radius is the whole repository, and it aborts rather than warns.
- The `action.ps1` (not `run.ps1`) naming decision is not stylistic — it is load-bearing and correct. `Run-E2EAcceptanceTest.ps1` classifies a case as fully scripted by the presence of `run.ps1` (filter at line 213); naming these `run.ps1` would have executed a window-driven case unattended with no panel open, producing a false PASS. The rationale is documented in every script header.
- `seed-sandbox.ps1` refuses to seed a sandbox missing `doc/project-config.json`, and the refusal is genuinely load-bearing: the launcher walks up to 10 levels looking for that file, the workspace sits inside the real LinkWatcher repository, so a missing config would silently start a daemon over the whole repo. Failing loudly here is the right call.
- Every sandbox launcher fixture is a byte-verbatim copy of the repository launcher (verified across all 10 sandbox projects), so the start path under test is the real one.
- Preconditions are unusually strong for manual cases: the single-instance guard, a stale `panel.port`, and pre-existing daemons are each called out with the reason they would invalidate the observation.

## Minor Fixes Applied

| Fix | What Changed | Why | Time Spent |
|-----|-------------|-----|------------|
| Master test Phase 1 step 3 retargeted | The master test's log-tail step appended a line to `sandbox-b/docs/guide.md` inside **this case's** workspace, but that exact file is asserted unchanged by this case's `expected/`. The step now creates a new `docs/tail-probe.md` instead. | The master's own pass criterion (“`Verify-TestResult.ps1` shows all green for TE-E2E-034, TE-E2E-036, TE-E2E-037”) was unsatisfiable — TE-E2E-034 would fail on every run. Retargeting the probe removes the collision and keeps the no-corruption assertion intact, rather than weakening the criterion to hide it. | 5 min |
| WF-010 milestone status corrected | `e2e-test-tracking.md` Workflow Milestone Tracking: WF-010 moved from `⬜ Not Created` to `✅ Covered`. | Eight cases and a master test exist at `📋 Needs Execution`; the milestone row still claimed nothing had been created, contradicting the case table directly below it. | 2 min |

## Action Items

- [ ] **Commit the WF-010 test group to git** — 83 files are currently untracked (human decision; not performed by this audit).
- [ ] Proceed to E2E Acceptance Test Execution (PF-TSK-070); no fixture or case changes are required first.

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
