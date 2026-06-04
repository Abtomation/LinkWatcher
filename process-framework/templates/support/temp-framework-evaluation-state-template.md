---
id: PF-TEM-081
type: Process Framework
category: Template
version: 1.0
created: 2026-06-03
updated: 2026-06-03
task_name: [TASK-NAME]
description: "Template for tracking multi-session framework evaluation (PF-TSK-079) — Artifacts-in-Scope inventory, per-dimension progress across the seven evaluation dimensions, findings log with scores and routing, and session plan (via New-TempTaskState.ps1 -Variant FrameworkEvaluation)"
---

# Temporary Framework Evaluation State: [Task Name]

> **⚠️ TEMPORARY FILE**: This file tracks a multi-session [Framework Evaluation (PF-TSK-079)](../../tasks/support/framework-evaluation.md). Move to `process-framework-central/state-tracking/temporary/old` after the evaluation report is generated and all IMPs are registered.

## Evaluation Overview

- **Evaluation Scope**: [Brief description of the evaluation scope]
- **Scope Type**: [Full framework / Phase scope / Component type / Workflow scope / Targeted]
- **Source / Trigger**: [What prompted this evaluation — e.g., human request, milestone, prior finding]
- **Target Report**: [PF-EVR-XXX — link once generated at Step 10]
- **Dimensions Selected**: [List the dimensions in scope; default is all seven — Completeness, Consistency, Redundancy, Accuracy, Effectiveness, Automation Coverage, Scalability]

## Artifacts in Scope (Step 4)

> Enumerate every artifact in scope — counts in the report must be backed by this list (no approximate totals).

| File Path | ID | Type | Assessed? |
| --------- | -- | ---- | --------- |
| [path/to/artifact] | [PF-XXX-NNN] | [task/template/guide/script/context map/state file] | [NOT_STARTED/IN_PROGRESS/DONE] |

## Dimension Progress (Steps 5–7)

| # | Dimension | Status | Score (1–4) | Key Evidence / Notes |
| - | --------- | ------ | ----------- | -------------------- |
| 1 | Completeness | [NOT_STARTED/IN_PROGRESS/DONE] | [—] | [Evidence: file paths, specific gaps] |
| 2 | Consistency | [NOT_STARTED/IN_PROGRESS/DONE] | [—] | [Evidence] |
| 3 | Redundancy | [NOT_STARTED/IN_PROGRESS/DONE] | [—] | [Evidence] |
| 4 | Accuracy | [NOT_STARTED/IN_PROGRESS/DONE] | [—] | [Evidence] |
| 5 | Effectiveness | [NOT_STARTED/IN_PROGRESS/DONE] | [—] | [Evidence] |
| 6 | Automation Coverage | [NOT_STARTED/IN_PROGRESS/DONE] | [—] | [Evidence] |
| 7 | Scalability (if selected) | [NOT_STARTED/IN_PROGRESS/DONE/SKIPPED] | [—] | [Evidence] |

## Findings Log (Steps 7–8)

> One row per finding (score ≤ 3). Routing: IMP (PF-TSK-009 default) / PF-TSK-026 (extension) / PF-TSK-014 (structural) / PF-TSK-001 (new task).

| Finding | Dimension | Score | Severity | Suggested Fix | Effort | Routing |
| ------- | --------- | ----- | -------- | ------------- | ------ | ------- |
| [F1 — short description] | [dimension] | [1–3] | [Critical/Major/Minor/Cosmetic] | [fix] | [IMP / PF-TSK-026 / PF-TSK-014 / PF-TSK-001] |

## Evaluation Roadmap

### Phase 1: Scope & Inventory (Steps 1–4)

**Priority**: HIGH — Must complete before dimension analysis

- [ ] **Define scope & dimensions**: Agree scope and selected dimensions with human partner (Steps 1–2)
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
- [ ] **CHECKPOINT** (Step 3): Scope + dimensions approved
  - **Status**: [NOT_STARTED/APPROVED/REJECTED]
- [ ] **Inventory artifacts** (Step 4): Populate the Artifacts in Scope table — enumerate, do not approximate
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]

### Phase 2: Dimension Analysis (Steps 5–6)

**Priority**: HIGH — Core evaluation work; may span multiple sessions

- [ ] **Evaluate each dimension** (Step 5): Assess artifacts per dimension; record evidence in the Dimension Progress table
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
- [ ] **Industry research** (Step 6): Calibrate scores against external norms; capture comparisons for the report
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]

> Data-driven validation (Step 8): any removal/merge/restructure proposal needs historical-data backing before it becomes an IMP. This may need its own session — track it as a Phase 2 sub-item.

### Phase 3: Findings & Checkpoint (Steps 7–9)

**Priority**: HIGH

- [ ] **Score & draft findings** (Steps 7–8): Populate the Findings Log with scores, severity, fixes, and routing
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
- [ ] **CHECKPOINT** (Step 9): Findings summary + routing decisions approved
  - **Status**: [NOT_STARTED/APPROVED/REJECTED]

### Phase 4: Report & Registration (Steps 10–12)

**Priority**: MEDIUM — Finalization

- [ ] **Generate evaluation report** (Step 10): `New-FrameworkEvaluationReport.ps1`; customize with findings and scores
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
  - **Report**: [PF-EVR-XXX]
- [ ] **Register IMP entries** (Step 11): `New-ProcessImprovement.ps1` for each approved finding; link back to the report
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
- [ ] **Complete feedback form** (Step 12): PF-TSK-079
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]

## Session Tracking

### Session 1: [YYYY-MM-DD]

**Focus**: [Session focus]
**Completed**:

- [List completed items]

**Issues/Blockers**:

- [List any issues encountered]

**Next Session Plan**:

- [Plan for next session — which artifacts/dimensions remain]

## Completion Criteria

This temporary state file can be moved to `process-framework-central/state-tracking/temporary/old` when:

- [ ] All in-scope artifacts are assessed (Artifacts in Scope table complete)
- [ ] All selected dimensions are scored with supporting evidence
- [ ] Evaluation report (PF-EVR-XXX) is generated and customized
- [ ] IMP entries are registered for each approved finding, linked to the report
- [ ] Feedback form is completed

## Notes and Decisions

### Key Decisions Made

- [Decision]: [Rationale]

### Evaluation Notes

- [Note]
