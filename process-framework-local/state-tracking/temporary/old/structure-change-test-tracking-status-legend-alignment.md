---
id: PF-STA-090
type: Document
category: General
version: 1.0
created: 2026-04-16
updated: 2026-04-16
change_name: test-tracking-status-legend-alignment
---

# Structure Change State: Test Tracking Status Legend Alignment

> **⚠️ TEMPORARY FILE**: This file tracks implementation of a content update structure change. Move to `process-framework-local/state-tracking/temporary/old` after all changes are validated.

## Structure Change Overview
- **Change Name**: Test Tracking Status Legend Alignment
- **Change ID**: SC-024
- **Change Type**: Content Update
- **Scope**: Rename past-tense status labels in test-tracking.md to next-step wording and add Next Task column per PF-IMP-554
- **Proposal**: [PF-PRO-024](../../../proposals/old/structure-change-test-tracking-status-legend-alignment-proposal.md)
- **Expected Completion**: 2026-04-16

## Content Changes

### Change Description
Rename 5 past-tense status labels to next-step wording and add a Next Task column to the status legend in test-tracking.md. Cascade the renames to all scripts, task definitions, guides, templates, and infrastructure docs that reference these status strings.

### Status Rename Mapping

| Old Label | New Label |
|-----------|-----------|
| Specification Created | Needs Implementation |
| Ready for Validation | Needs Audit |
| Tests Implemented | Audit Approved |
| Tests Approved with Dependencies | Approved — Pending Dependencies |
| Tests Failing | Needs Fix |

### Affected Files
Files requiring content updates:

| File | Change Required | Priority | Status |
|------|----------------|----------|--------|
| test/state-tracking/permanent/test-tracking.md | Legend rename + add Next Task column + all table row status values | HIGH | PENDING |
| process-framework/templates/03-testing/test-tracking-template.md | Legend rename + add Next Task column | HIGH | PENDING |
| process-framework/templates/03-testing/audit-tracking-template.md | Legend rename | MEDIUM | PENDING |
| process-framework/templates/03-testing/test-audit-report-template.md | Status references | MEDIUM | PENDING |
| test/state-tracking/audit/audit-tracking-e2e-1.md | Legend rename + status values | MEDIUM | PENDING |
| process-framework/tasks/03-testing/test-audit-task.md | Status references (~12 lines) | MEDIUM | PENDING |
| process-framework/tasks/06-maintenance/code-review-task.md | Status references (~3 lines) | MEDIUM | PENDING |
| process-framework/tasks/04-implementation/integration-and-testing.md | Status references (~5 lines) | MEDIUM | PENDING |
| process-framework/guides/03-testing/test-audit-usage-guide.md | Status references (~9 lines) | MEDIUM | PENDING |
| process-framework/infrastructure/process-framework-task-registry.md | Status references (~7 lines) | MEDIUM | PENDING |
| process-framework/infrastructure/task-transition-registry.md | Status references (~7 lines) | MEDIUM | PENDING |
| process-framework/scripts/AUTOMATION-USAGE-GUIDE.md | Example status values | LOW | PENDING |
| process-framework/visualization/context-maps/03-testing/test-audit-map.md | Mermaid diagram + description | LOW | PENDING |

### Non-File Updates
Scripts requiring string literal updates:

| Component | Change Required | Status |
|-----------|----------------|--------|
| scripts/test/Run-Tests.ps1 | Status assignment (line 430): Tests Failing → Needs Fix, Tests Implemented → Audit Approved | PENDING |
| scripts/file-creation/03-testing/New-TestFile.ps1 | Display + functional: Specification Created → Needs Implementation | PENDING |
| scripts/file-creation/03-testing/New-AuditTracking.ps1 | Auditable statuses array: Tests Implemented → Audit Approved, Tests Approved with Dependencies → Approved — Pending Dependencies | PENDING |
| scripts/update/Update-CodeReviewState.ps1 | ValidateSet (BREAKING): Tests Implemented → Audit Approved, Tests Failing → Needs Fix | PENDING |
| scripts/update/Update-FeatureImplementationState.ps1 | Switch statement: Tests Implemented → Audit Approved | PENDING |
| scripts/update/Update-TestFileAuditState.ps1 | Switch + aggregation: Tests Approved → Audit Approved (lines 534, 589-593) | PENDING |
| scripts/Common-ScriptHelpers/TestTracking.psm1 | Examples only | PENDING |
| scripts/Common-ScriptHelpers/FeatureTracking.psm1 | Examples only | PENDING |

## Implementation Roadmap

### Phase 1: Preparation (Session 1)
- [ ] **Identify all affected files** (grep for patterns, review references)
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
- [ ] **Document changes** in Affected Files table above
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
- [ ] **Checkpoint**: Present change plan to human partner for approval
  - **Status**: [NOT_STARTED/COMPLETED]

### Phase 2: Execution & Validation (Session 1-2)
- [ ] **Apply content changes**: Update files per the Affected Files table
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
- [ ] **Update non-file components**: Fix scripts, configs if needed
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
- [ ] **Validate**: Grep for old patterns, confirm no stale content remains
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]
- [ ] **Update documentation**: Update Documentation Map and any affected guides
  - **Status**: [NOT_STARTED/IN_PROGRESS/COMPLETED]

## Session Tracking

### Session 1: 2026-04-16
**Focus**: Full process — proposal, impact analysis, execution
**Completed**:
- Impact analysis (grep + script audit + task definition audit)
- Structure change proposal PF-PRO-024 created
- State tracking file PF-STA-090 created

**Issues/Blockers**:
- None so far

**Next Session Plan**:
- Execute all 4 phases after human approval

## State File Updates Required

- [ ] **Documentation Map**: Update if document names/locations changed
  - **Status**: [PENDING/COMPLETED]
- [ ] **Process Improvement Tracking**: Record completion if IMP-linked
  - **Status**: [PENDING/COMPLETED]

## Completion Criteria

This file can be archived to `state-tracking/temporary/old/` when:

- [ ] All content changes applied
- [ ] Validation confirms no stale patterns remain
- [ ] Documentation updated if needed
- [ ] Feedback form completed
