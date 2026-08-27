---
id: TE-TAR-100
type: Testing
category: Test Audit Report
version: 1.0
created: 2026-08-25
updated: 2026-08-25
audit_date: 2026-08-25
auditor: AI Agent
description: Test audit report for feature 7.1.1 (E2E)
feature_id: 7.1.1
test_file_path: test/e2e-acceptance-testing/manage-running-linkwatcher-instances-via-control-panel/templates/TE-E2E-036-close-panel-drains-in-flight-move/test-case.md
---

# E2E Test Audit Report - Feature 7.1.1

## Audit Overview

| Field | Value |
|-------|-------|
| **Feature ID** | 7.1.1 |
| **Test Case ID** | TE-E2E-036 |
| **Test Group** | TE-E2G-015 |
| **Test Case Location** | `test/e2e-acceptance-testing/manage-running-linkwatcher-instances-via-control-panel/templates/TE-E2E-036-close-panel-drains-in-flight-move/test-case.md` |
| **Workflow** | WF-010: Manage running LinkWatcher instances via Control Panel |
| **Auditor** | AI Agent |
| **Audit Date** | 2026-08-25 |
| **Audit Status** | ✅ Audit Approved |

## Tests Audited

| Test Case ID | Group | Workflow | Description | Current Status |
|-------------|-------|----------|-------------|----------------|
| TE-E2E-036 | TE-E2G-015 | WF-010 | Closing the panel with a file move in flight drains the daemon so the reference update completes uncorrupted | 📋 Needs Execution |

**Acceptance criteria covered**: AC-7 (close drains and terminates every managed daemon, the app exits) and AC-8 (an in-progress update completes; no partial or corrupted file)

**Execution mode**: manual (window-driven). **Priority**: P0.

## Audit Evaluation

### 1. Fixture Correctness
**Question**: Are `project/` and `expected/` directories accurate representations of the test scenario?

**Assessment**: PASS

**Findings**:
- **Project fixture accuracy**: a single sandbox with the `docs/guide.md` → `notes/setup.md` reference pair, a config carrying `move_detect_delay: 10`, a verbatim launcher and the root guard. The config value is load-bearing: it is what keeps the move correlating for up to 10 s so the update is genuinely still in flight when the panel is closed.
- **Expected fixture accuracy**: `expected/` encodes the post-move state — `docs/guide.md` with the link rewritten to `../archive/setup.md`, and `archive/setup.md` present. Verified that `expected/sandbox-a/archive/setup.md` is byte-identical to `project/sandbox-a/notes/setup.md`, so the moved file's content is asserted to survive the move unchanged.
- **Stale content**: none.
- **File completeness**: `archive/setup.md` correctly has no `project/` counterpart — it must be produced by the test. The `churn/`-style run artefacts do not apply here.

**Evidence**:
- Verified the `expected/` root aligns with the harness contract: `Verify-TestResult.ps1` compares `<workflow>/workspace/<case>/project/` against `<workflow>/templates/<case>/expected/`, so `expected/sandbox-a/...` maps onto `project/sandbox-a/...` correctly.
- Confirmed the comparison is one-directional (only files present in `expected/` are compared), so the generated `sandbox-registry.json`, the seed-stamped `doc/project-config.json`, `logs/`, `.linkwatcher.lock` and other run artefacts correctly fall outside the assertion.
- Diff of `project/` vs `expected/`: exactly one line changes in `guide.md` (`../notes/setup.md` → `../archive/setup.md`), and `archive/setup.md` is new. Both deltas match the scenario precisely.

**Recommendations**:
- None.

---

### 2. Scenario Completeness
**Question**: Does the test cover the full user workflow end-to-end, including edge cases?

**Assessment**: PASS

**Findings**:
- **Workflow coverage**: this is the highest-value case in the group and it covers what it claims. AC-8 is tested at the only moment it is testable — a close landing while a rewrite is in progress — and AC-7 falls out of the same run.
- **Edge cases**: the case names its own degenerate outcome and rules it out: if the close lands after the update already finished, it degrades into a plain clean stop and proves nothing about AC-8, so the case instructs a re-run when the panel log shows the update completed before the close was requested. That is a self-check against a vacuous pass, and it is the single most important sentence in the case.
- **Error paths**: the Fail Actions distinguish a clean drain from a forced termination and state that the two point at different defects (drain-completion logic vs. quiescence detection) — useful triage rather than a generic “file a bug”.
- **Cross-feature interaction**: correctly declares 2.2.1 and 0.1.2 alongside 7.1.1, since the in-flight work being protected is a link-updater rewrite driven by move detection.

**Evidence**:
- Confirmed against the TDD reference in the case header: this is the scenario earmarked for E2E acceptance (§7.3, AC-8/AC-9).
- Confirmed `move_detect_delay: 10` in the fixture config, which is what makes the 1–2 s close window land inside the correlation window.

**Recommendations**:
- None.

---

### 3. Expected Outcome Accuracy
**Question**: Are the expected results in `expected/` actually correct for the given scenario?

**Assessment**: PASS

**Findings**:
- **Link target correctness**: the expected rewritten link `../archive/setup.md` resolves against the expected post-move location — verified that `archive/setup.md` is exactly where the rewrite points.
- **Content accuracy**: the expected content is genuinely derived from the scenario, not copied from `project/` — this is one of only two cases in the group whose `expected/` actually differs from its starting state.
- **Diff analysis**: one intentional line change plus one new file; no incidental differences.
- **Manual verification**: verified by diff, including the byte-identity of the moved file's content.
- **Gap (documented, non-blocking)**: `Verify-TestResult.ps1` is one-directional — it only compares files present in `expected/`. It therefore cannot assert that `notes/setup.md` is *absent* after the move. A failure mode in which the daemon copied rather than moved would leave `notes/setup.md` in place and still pass the automated comparison. The case does carry it as a manual pass criterion (“`notes/setup.md` is gone”), so the coverage exists — it just sits with the human, not the harness.

**Evidence**:
- Read the comparison loop in `Verify-TestResult.ps1`: it iterates `Get-ChildItem $expectedDir -Recurse -File` and reports missing or mismatched files, with no reverse sweep for files that should have disappeared.
- Confirmed the automated half is still load-bearing here: if the move never happened, `archive/setup.md` is missing and `guide.md` mismatches, so the case fails.

**Recommendations**:
- No change required for execution. If a future revision wants the absence asserted mechanically, it needs a harness capability that does not exist today — file it as a framework improvement rather than working around it in the case.

---

### 4. Reproducibility
**Question**: Can the test be executed independently and produce consistent results?

**Assessment**: PARTIAL

**Findings**:
- **State independence**: self-contained. `action.ps1` additionally refuses to run if `archive/setup.md` already exists, which is a real guard — it catches a re-run against a dirty workspace, the exact condition that would make the case pass without testing anything.
- **Setup reliability**: standard setup plus seed; `action.ps1` also fails loudly if the source fixture is missing.
- **Clean workspace**: passes from clean by construction.
- **Timing sensitivity — PARTIAL, and inherent**: the case depends on a human closing the window within 1–2 seconds of the move. That is unavoidable for AC-8: the property under test only exists during a narrow window. The case is honest about it, explains why `move_detect_delay: 10` widens the window, and supplies the re-run rule that prevents a mistimed run from being recorded as a pass. This is disclosed timing sensitivity, not a hidden race.

**Evidence**:
- `action.ps1` guards: errors if `notes/setup.md` is missing, and errors if `archive/setup.md` already exists.
- The case's Fail Actions instruct preserving the workspace before re-running, because `Setup-TestEnvironment.ps1 -Clean` destroys the corrupted `guide.md` that would be the evidence.

**Recommendations**:
- Keep the re-run rule prominent during execution: a run where the log shows the update completed before the close was requested must be re-run, not recorded.

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
Four criteria pass and Reproducibility is PARTIAL by inherent nature rather than by defect. The timing sensitivity is intrinsic to AC-8 — an in-flight update only exists for a moment — and the case handles it the right way: it widens the window through the fixture config, discloses the constraint, and supplies an explicit re-run rule so a mistimed run cannot be recorded as a pass. The expected outcomes are genuinely discriminating: a failed drain shows up as a truncated or unrewritten `guide.md`, and a move that never happened shows up as a missing `archive/setup.md`. The one-directional-verify gap on `notes/setup.md` is documented and is covered by a manual criterion. Approved for execution.

### Critical Issues
- **The entire WF-010 test group is untracked in git** — 83 files under `test/e2e-acceptance-testing/manage-running-linkwatcher-instances-via-control-panel/`, with only `.gitkeep` tracked and nothing covered by `.gitignore`. This is the same failure mode that produced CR-1 on this feature (the hook auto-open was implemented, live-verified on 2026-08-10, and silently reverted by the 2026-08-14 rollout because the work was never committed). Any `git clean` erases the whole group. Committing is a human decision and was not performed by this audit.

### Improvement Opportunities
- The absence of `notes/setup.md` after the move can only be checked by a human today. If this recurs across workflows, an “absent files” assertion in the E2E harness would be the root-cause fix — route it as a framework improvement, not a per-case workaround.

### Strengths Identified
- The case names and defends against its own vacuous-pass mode: a close that lands after the update finished proves nothing, and the case says so and requires a re-run. Very few manual test cases state the condition under which their own PASS is meaningless.
- `action.ps1` refuses to run against a non-pristine workspace, so the most likely way to accidentally fake a pass is blocked mechanically.
- Fail Actions require preserving the workspace before re-setup, because the corrupted file *is* the evidence and `-Clean` would destroy it.
- The `action.ps1` (not `run.ps1`) naming decision is not stylistic — it is load-bearing and correct. `Run-E2EAcceptanceTest.ps1` classifies a case as fully scripted by the presence of `run.ps1` (filter at line 213); naming these `run.ps1` would have executed a window-driven case unattended with no panel open, producing a false PASS. The rationale is documented in every script header.
- `seed-sandbox.ps1` refuses to seed a sandbox missing `doc/project-config.json`, and the refusal is genuinely load-bearing: the launcher walks up to 10 levels looking for that file, the workspace sits inside the real LinkWatcher repository, so a missing config would silently start a daemon over the whole repo. Failing loudly here is the right call.
- Every sandbox launcher fixture is a byte-verbatim copy of the repository launcher (verified across all 10 sandbox projects), so the start path under test is the real one.
- Preconditions are unusually strong for manual cases: the single-instance guard, a stale `panel.port`, and pre-existing daemons are each called out with the reason they would invalidate the observation.

## Action Items

- [ ] **Commit the WF-010 test group to git** — 83 files are currently untracked (human decision).
- [ ] Proceed to E2E Acceptance Test Execution (PF-TSK-070), observing the re-run rule for mistimed closes.

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
