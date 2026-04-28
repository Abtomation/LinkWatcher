---
id: PF-STA-095
type: Document
category: General
version: 1.0
created: 2026-04-22
updated: 2026-04-22
change_name: feature-tracking-test-status-vocabulary-unification
---

# Structure Change State: Feature Tracking Test Status Vocabulary Unification

> **Lightweight state file**: This change has a detailed proposal document. This file tracks **execution progress only** — see the proposal for rationale, affected files, and migration strategy.

## Structure Change Overview
- **Change Name**: Feature Tracking Test Status Vocabulary Unification
- **Change ID**: SC-027 (tentative — assigned at execution time if registry bookkeeping needed)
- **Proposal Document**: [PF-PRO-027](../../../proposals/old/structure-change-feature-tracking-test-status-vocabulary-unification-proposal.md)
- **Source IMP**: [PF-IMP-574](../../permanent/process-improvement-tracking.md)
- **Change Type**: Content Update (functional — breaking script output change)
- **Scope**: Unify feature-tracking.md Test Status column vocabulary across legend and two writer scripts (Update-TestFileAuditState.ps1, Update-TestExecutionStatus.ps1) plus Surface 15 internal aggregator; collapse Surface 15 reader canonicalization to identity comparison.
- **Expected Completion**: 2026-04-22 (single session)

## Implementation Roadmap

> **Cross-check reminder**: Every file in the proposal's Impact Matrix appears in at least one phase checklist below.

### Phase 1: Update writers + Surface 15 internal aggregator (atomic commit)
- [x] **Update-TestFileAuditState.ps1 (~lines 596-612)**: Rename 4 output labels — `Audit Approved` → `All Passing`, `Tests Failed Audit` → `Some Failing`, `Tests Need Update` → `Re-testing Needed`, `Tests In Progress` → `In Progress`. Keep `Tests Partially Approved` and `Audit In Progress` as-is.
  - **Status**: COMPLETED
- [x] **Update-TestExecutionStatus.ps1 (line 362)**: Update regex to drop retired aggregator labels after W1 migrates.
  - **Status**: COMPLETED
- [x] **Validate-StateTracking.ps1 internal aggregator (~lines 1525-1540)**: Rename emitted labels to match W1's new legend vocab.
  - **Status**: COMPLETED
- [x] **FeatureTracking.psm1 (line 58)**: Update `✅ Audit Approved` example → `✅ All Passing`.
  - **Status**: COMPLETED
- [x] **AUTOMATION-USAGE-GUIDE.md (lines 27, 140, 205)**: Update `-TestStatus "✅ Audit Approved"` examples → `-TestStatus "✅ All Passing"`.
  - **Status**: COMPLETED
- [x] **Smoke test**: Update-TestFileAuditState.ps1 -DryRun on feature 3.1.1 confirmed output `✅ All Passing`.
  - **Status**: COMPLETED

### Phase 2: Update legend (source of truth)
- [x] **feature-tracking.md legend**: Added 2 rows — `🔍 Audit In Progress`, `🟡 Tests Partially Approved`. No removals.
  - **Status**: COMPLETED

### Phase 3: Rewrite existing table rows
- [x] **Grep + rewrite**: Rewrote 1 retired-label row in feature-tracking.md (`6.1.1 Link Validation` from `✅ Audit Approved` → `✅ All Passing`). No other retired-label rows found.
  - **Status**: COMPLETED
- [x] **Verify**: Post-rewrite grep for retired labels returned 0 hits.
  - **Status**: COMPLETED

### Phase 4: Simplify Surface 15
- [x] **Drop `Get-TestStatusGroup`**: Removed from Validate-StateTracking.ps1.
  - **Status**: COMPLETED
- [x] **Rewrite Surface 15 comparison**: Replaced canonical-group comparison with direct string equality (using `$validStatuses` list + `Get-NormalizedStatus` whitespace helper).
  - **Status**: COMPLETED
- [x] **Re-run validation**: `Validate-StateTracking.ps1 -Surface TestStatusAggregation` → 8/8 checks passed, 0 errors, 0 warnings. PF-IMP-575's 4 split-brain cases auto-resolved.
  - **Status**: COMPLETED
- [x] **Full validation**: Ran on all surfaces except 6 (FeatureDeps has a pre-existing path bug unrelated to SC-027). 2 errors surfaced — both pre-existing (Surface 10 git-commit-and-push-map metadata, Surface 14 SourceLayout 'linkwatcher' path) — neither caused by SC-027.
  - **Status**: COMPLETED

### Phase 5: Close out
- [x] **Close PF-IMP-574**: Marked Completed via Update-ProcessImprovement.ps1 with MEDIUM impact and full validation notes.
  - **Status**: COMPLETED
- [x] **Re-evaluate PF-IMP-575**: Already closed by parallel session earlier same day as Rejected ("No longer valid" — Surface 15 now passes 8/8). No action needed.
  - **Status**: COMPLETED
- [x] **Archive proposal**: PF-PRO-027 moved to `process-framework-local/proposals/old/`.
  - **Status**: COMPLETED
- [x] **Archive this state file**: Moved to `process-framework-local/state-tracking/temporary/old/`.
  - **Status**: COMPLETED

## Session Tracking

### Session 1: 2026-04-22
**Focus**: Full execution of SC-027 (Phases 1-5) in a single session
**Completed**:
- Phase 1: 5 source-code edits + DryRun smoke test confirming W1 emits `✅ All Passing`
- Phase 2: feature-tracking.md legend gained 2 new rows (🔍 Audit In Progress, 🟡 Tests Partially Approved)
- Phase 3: 1 retired-label row rewritten (6.1.1); post-fix grep = 0 hits
- Phase 4: `Get-TestStatusGroup` dropped; Surface 15 now uses `$validStatuses` + direct string equality; 8/8 features pass
- Phase 5: PF-IMP-574 closed, PF-IMP-575 already handled, proposal + state file archived, feedback form (PF-FEE-988) completed

**Issues/Blockers**:
- Update-ProcessImprovement.ps1 error-message confusion when trying to re-close PF-IMP-575 (already in Completed). Manual check confirmed IMP was already Rejected by parallel session.
- Surface 6 (FeatureDeps) crashes with `.git/objects/` path lookup — pre-existing, unrelated to SC-027.

**Next Session Plan**:
- N/A — SC-027 is closed.

## State File Updates Required

- [x] **Documentation Map**: No document organization changes — no map update required.
  - **Status**: N/A
- [x] **Process Improvement Tracking**: PF-IMP-574 moved to Completed section with validation notes.
  - **Status**: COMPLETED

## Completion Criteria

This file can be archived to `state-tracking/temporary/old/` when:

- [x] All phases completed successfully
- [x] All proposal-listed files addressed (6 files edited per impact matrix)
- [x] Documentation updated (legend + AUTOMATION-USAGE-GUIDE examples)
- [x] Feedback form completed (PF-FEE-988)
