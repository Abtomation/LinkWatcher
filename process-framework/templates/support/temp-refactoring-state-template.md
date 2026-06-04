---
id: PF-TEM-076
type: Process Framework
category: Template
version: 1.0
created: 2026-05-07
updated: 2026-05-07
task_name: [TASK-NAME]
description: "Multi-session state tracking for code refactoring work (PF-TSK-022 Standard Path) — includes Test Baseline anchor (Step 5), Phase 0/A/B/C/D structure, bug-discovery log, and 3-phase closure (via New-TempTaskState.ps1 -Variant Refactoring)"
---

# Temporary Refactoring State: [Task Name]

> **⚠️ TEMPORARY FILE**: Tracks multi-session execution of a code refactoring per [PF-TSK-022 Standard Path](../../tasks/06-maintenance/code-refactoring-standard-path.md). Move to `doc/state-tracking/temporary/old/` after Phase D closure is complete and the refactoring plan is archived.
>
> **Use when**: ≥ 5 items or 3+ sessions expected (per Standard Path Step 2). For smaller refactorings, track progress directly in the refactoring plan's "Implementation Tracking" section instead.

## Refactoring Overview

- **Refactoring Name**: [Task Name]
- **Refactoring Plan**: [PD-REF-XXX — link to plan document created via New-RefactoringPlan.ps1]
- **Target Component(s)**: [Module / class / package being refactored]
- **Source Tech Debt Items**: [TDXXX — link to technical-debt-tracking.md entries; include the **Dims** column primary dimension(s) the refactor must improve]
- **Affected Feature(s)**: [Feature ID(s) and name(s)]
- **Scope Classification**: [Non-logic / Structural-only / Logic-changing] — determines which Step 15 bug-discovery categories apply (see Standard Path Step 15 N/A escape hatches)

## Test Baseline (Step 5 Anchor — Mandatory)

> **⚠️ Captured BEFORE any code changes.** This is the accountability anchor. Any NEW failures after refactoring are owned by this session; pre-existing failures are not.

- **Captured by**: `pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/test/Run-Tests.ps1 -All`
- **Date**: [YYYY-MM-DD]
- **Total tests**: [N]
- **Passed**: [N]
- **Failed**: [N]
- **Errors**: [N]
- **Pre-existing failing tests** (exact pytest FAILED lines):
  ```
  [Paste FAILED lines verbatim from pytest output, or write "(none)" if baseline is fully green]
  ```
- **Coverage assessment** (per Step 6):
  - **Sufficient / Insufficient**: [Sufficient / Insufficient]
  - **Characterization tests added**: [None / TE-TST-XXX, TE-TST-XXX]

## E2E Acceptance Test Coverage Snapshot (Step 4)

| E2E Group | Status before refactor | Re-execution required after? |
| --------- | ---------------------- | ---------------------------- |
| [TE-E2G-XXX] | [Last execution status] | [Yes / No — set Yes if affected functionality is touched] |

## Implementation Roadmap

### Phase 0: Prerequisites

**Priority**: HIGH — Block Phase A until complete.

- [ ] **Refactoring Plan created** — [PD-REF-XXX](path)
- [ ] **Tech debt items identified and Dims column read** — TDXXX
- [ ] **E2E acceptance coverage reviewed** — see snapshot above
- [ ] **Test Baseline captured** — see baseline section above
- [ ] **Test coverage assessed** — characterization tests added if insufficient
- [ ] **Baseline measurements captured** — performance / complexity / quality metrics recorded in plan
- [ ] **🚨 CHECKPOINT 1 (Step 8)**: Analysis findings, baseline metrics, and coverage status approved by human partner

### Phase A: Strategy & ADR

**Priority**: HIGH — Locks the approach before any code changes.

- [ ] **Refactoring strategy defined** in plan document
- [ ] **🚨 CHECKPOINT 2 (Step 10)**: Strategy approved before implementing changes
- [ ] **ADRs created** (if applicable — pattern change / DI strategy / error handling / module boundaries / data-flow):
  - [ ] [PD-ADR-XXX — title]
  - [ ] Architecture Tracking updated with decision impact

### Phase B: Incremental Implementation

**Priority**: HIGH — Small, testable increments with frequent commits.

- [ ] **Increment 1**: [Description]
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
  - **Commit**: [SHA]
  - **Tests after**: [Passed / Failed — same as baseline?]
  - **🚨 CHECKPOINT (per-increment for high-risk)**: [Approved / N/A]
- [ ] **Increment 2**: [Description]
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
  - **Commit**: [SHA]
  - **Tests after**: [Passed / Failed — same as baseline?]
  - **🚨 CHECKPOINT**: [Approved / N/A]
- [ ] **Test reference updates** (after any module rename / split / move / import removal):
  - [ ] `grep -rn "from old_module\|import old_module\|@patch.*old_module" test/` swept and updated

### Phase C: Behavior Validation

**Priority**: HIGH — Behavior preservation is the primary success criterion.

- [ ] **Step 15 bug discovery checklist** completed (skip-N/A if scope is non-logic; only Hidden Dependencies + Integration Issues if structural-only):
  - [ ] Logic Errors
  - [ ] Hidden Dependencies
  - [ ] Performance Issues
  - [ ] Error Handling Gaps
  - [ ] Integration Issues
  - [ ] Data Handling Bugs
  - [ ] Concurrency Issues
  - [ ] Resource Management
- [ ] **Step 16 test gap assessment for extracted units** (skip-N/A if non-logic): unit tests / dedicated test files for new classes / coverage for new boundaries
- [ ] **Step 18 behavior preservation diff** vs Step 5 baseline:
  - **Result**: [Same as baseline / NEW failures (list)]
  - **NEW-failure ownership**: [Fixed in this session / Reported as bug PD-BGT-XXX]
- [ ] **Step 19 metrics measured** vs baseline:
  - **Before**: [snapshot]
  - **After**: [snapshot]
  - **Improvement**: [delta]
- [ ] **🚨 CHECKPOINT 3 (Step 20)**: Before/after metrics, discovered bugs, improvement summary approved

### Phase D: Closure

**Priority**: HIGH — All state-file updates that establish the post-refactor truth.

#### Phase D.1: During / On-Completion (Step 22 Phase 1+2)

- [ ] **Refactoring Plan updated** — actual results, lessons learned, residual debt
- [ ] **Bug Tracking** — discovered bugs added with refactoring context
- [ ] **Technical Debt Tracking**: `Update-TechDebt.ps1 -DebtId TDXXX -NewStatus Resolved -ResolutionNotes "..." -PlanLink "[TDXXX](path)"`
  - [ ] **Audit-flagged TD closure** (only if resolved TD's Source/Notes reference a `TE-TAR-*` audit report) — `Update-TestFileAuditState.ps1 -TestFilePath ... -AuditStatus "Audit Approved" -AuditReportPath ...` if all findings resolved; else route to Test Audit re-audit
- [ ] **Feature Tracking** — status improved (e.g., `🔄 Needs Enhancement` → `🟡 In Progress`)
- [ ] **Architecture Tracking** — for foundation features / architectural changes
- [ ] **Test Tracking** — note test improvements / new requirements; columns mirroring code values updated where refactor changed them
- [ ] **E2E Re-execution flagged** (where applicable): `Update-TestExecutionStatus.ps1 -FeatureId X.Y.Z -Status "Needs Re-execution" -Reason "Refactoring [scope]"`
- [ ] **Product documentation updated** (Step 14 — feature state file / TDD / FDD / test spec / Integration Narrative — if module boundaries / interfaces / patterns changed)

#### Phase D.2: Post-Completion (Step 22 Phase 3)

- [ ] **Refactoring Plan archived** to `doc/refactoring/plans/archive`
- [ ] **Architecture Tracking context packages updated** (architectural refactors only)
- [ ] **Source layout refreshed** (only if file moves changed directory structure): `New-SourceStructure.ps1 -Update`
- [ ] **This temp state file archived** to `doc/state-tracking/temporary/old/`
- [ ] **Feedback form created** for the session(s)

## Discovered Bugs Log

> Populated during Phase B/C per Step 15 bug-discovery checklist. Use New-BugReport.ps1 to file each.

| # | Severity (🔴/🟠/🟡/🟢) | Category | Description | Bug ID | Action (per Step 15 matrix) |
| - | --------------------- | -------- | ----------- | ------ | --------------------------- |
| 1 | [emoji]               | [category] | [description] | [PD-BGT-XXX] | [STOP / fix-now / defer / TD] |

## Session Log

### Session 1 — [YYYY-MM-DD]

- **Focus**: [Phase 0 / A / B / C / D scope this session]
- **Completed**: [bullets]
- **Issues / Blockers**: [bullets]
- **Checkpoints reached**: [list]
- **Next session plan**: [bullets]

### Session 2 — [YYYY-MM-DD]

- **Focus**:
- **Completed**:
- **Issues / Blockers**:
- **Checkpoints reached**:
- **Next session plan**:

## Notes / Decisions Log

- **[YYYY-MM-DD]** — [Decision]: [rationale]
- **[YYYY-MM-DD]** — [Decision]: [rationale]

## Update History

| Date | Change | Updated By |
| ---- | ------ | ---------- |
| [YYYY-MM-DD] | Initial creation — scope plan + Phase 0 outline | PF-TSK-022 (this session) |
| [YYYY-MM-DD] | Phase A complete — strategy + ADRs | Session N closeout |
| [YYYY-MM-DD] | Phase B/C complete — implementation + behavior validation | Session N closeout |
| [YYYY-MM-DD] | Phase D complete — state files closed; tracker ready for archival | Final session closeout |
