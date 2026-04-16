---
id: PF-PRO-024
type: Document
category: General
version: 1.0
created: 2026-04-16
updated: 2026-04-16
---

# Structure Change Proposal: Test Tracking Status Legend Alignment

## Overview
Align test-tracking.md status legend to next-step wording and add Next Task column, matching the pattern established in feature-tracking.md and bug-tracking.md (PF-IMP-554).

**Structure Change ID:** SC-024
**Proposer:** AI Agent & Human Partner
**Date Proposed:** 2026-04-16
**Target Implementation Date:** 2026-04-16

## Current Structure

The test-tracking.md status legend uses past-tense labels that describe what *has happened* rather than what *needs to happen next*:

```markdown
| Status | Description |
|--------|-------------|
| 📝 **Specification Created** | Test specification document has been created but tests not yet implemented |
| 🟡 **Implementation In Progress** | Test implementation has started but is not complete |
| 🔄 **Ready for Validation** | Tests are implemented and ready for audit validation |
| ✅ **Tests Implemented** | All tests from specification have been implemented and are passing |
| 🟡 **Tests Approved with Dependencies** | Tests are approved by audit but some tests await implementation dependencies |
| 🔴 **Tests Failing** | Tests are implemented but some are currently failing |
| ⛔ **Implementation Blocked** | Test implementation is blocked by dependencies or issues |
| 🔄 **Needs Update** | Test specification or implementation needs updates due to code changes or audit findings |
| 🗑️ **Removed** | Test file has been removed due to being outdated or no longer needed |
```

No "Next Task" column exists.

## Proposed Structure

Rename past-tense labels to next-step wording and add Next Task column:

```markdown
| Status | Description | Next Task |
|--------|-------------|-----------|
| 📝 **Needs Implementation** | Test specification exists, tests not yet implemented | PF-TSK-053 |
| 🟡 **Implementation In Progress** | Test implementation has started but is not complete | — |
| 🔄 **Needs Audit** | Tests are implemented and ready for audit validation | PF-TSK-030 |
| ✅ **Audit Approved** | All tests from specification have been implemented, are passing, and passed audit | — |
| 🟡 **Approved — Pending Dependencies** | Tests passed audit but some await implementation dependencies | — |
| 🔴 **Needs Fix** | Tests are implemented but some are currently failing | — |
| ⛔ **Implementation Blocked** | Test implementation is blocked by dependencies or issues | — |
| 🔄 **Needs Update** | Test specification or implementation needs updates due to code changes or audit findings | — |
| 🗑️ **Removed** | Test file has been removed due to being outdated or no longer needed | — |
```

### Status Rename Mapping

| Old Label | New Label | Rationale |
|-----------|-----------|-----------|
| Specification Created | Needs Implementation | Next step is to implement tests |
| Ready for Validation | Needs Audit | Next step is audit; aligns with "Needs X" pattern |
| Tests Implemented | Audit Approved | Reflects that tests passed audit gate (terminal-ish) |
| Tests Approved (script-only variant) | Audit Approved | Consolidates with Tests Implemented → single canonical label |
| 🟢 Completed (table-row-only variant) | Audit Approved | Consolidates drift — 30 rows used unlisted status |
| Tests Approved with Dependencies | Approved — Pending Dependencies | Shorter, action-oriented |
| Tests Failing | Needs Fix | Next step is to fix the failures |

Unchanged: Implementation In Progress, Implementation Blocked, Needs Update, Removed — already follow acceptable patterns.

### Pre-existing Drift Fix (expanded scope)

Three different labels were used for the same post-audit state:
- **Legend**: `✅ Tests Implemented` (4 table rows)
- **Script**: `✅ Tests Approved` (Update-TestFileAuditState.ps1 output)
- **Table rows**: `🟢 Completed` (30 rows — not in legend at all)

All three are consolidated into `✅ Audit Approved`.

## Rationale

### Benefits
- Consistency with feature-tracking.md and bug-tracking.md status legends
- Next Task column enables AI agents to self-route without reading task definitions
- Next-step wording makes the workflow direction immediately clear

### Challenges
- 20+ files reference these status strings (scripts, tasks, guides, templates)
- Scripts with ValidateSet constraints (Update-CodeReviewState.ps1) will break if not updated atomically
- String-matching logic in New-AuditTracking.ps1 and Run-Tests.ps1 must be updated

## Affected Files

### Impact Matrix

| File | Change Type | Status Strings Affected | Usage Type |
|------|------------|------------------------|------------|
| test/state-tracking/permanent/test-tracking.md | Legend + table rows | All renamed statuses | Content |
| process-framework/templates/03-testing/test-tracking-template.md | Legend | All renamed statuses | Template |
| process-framework/scripts/test/Run-Tests.ps1 | String literals | Tests Implemented, Tests Failing | Script (FUNCTIONAL) |
| process-framework/scripts/file-creation/03-testing/New-TestFile.ps1 | String literals | Specification Created, Implementation In Progress | Script (DISPLAY+FUNCTIONAL) |
| process-framework/scripts/file-creation/03-testing/New-AuditTracking.ps1 | Status array | Tests Implemented, Tests Approved with Dependencies | Script (FUNCTIONAL) |
| process-framework/scripts/update/Update-CodeReviewState.ps1 | ValidateSet | Tests Implemented, Tests Failing | Script (FUNCTIONAL — BREAKING) |
| process-framework/scripts/update/Update-FeatureImplementationState.ps1 | Switch statement | Tests Implemented, Implementation In Progress | Script (FUNCTIONAL) |
| process-framework/scripts/Common-ScriptHelpers/TestTracking.psm1 | Examples | Implementation In Progress | Script (EXAMPLE) |
| process-framework/scripts/Common-ScriptHelpers/FeatureTracking.psm1 | Examples | Tests Implemented | Script (EXAMPLE) |
| process-framework/tasks/03-testing/test-audit-task.md | Status references | Tests Implemented, Tests Approved with Dependencies, Implementation In Progress, Ready for Validation | Task def (NORMATIVE) |
| process-framework/tasks/06-maintenance/code-review-task.md | Status references | Tests Implemented, Tests Failing | Task def (NORMATIVE) |
| process-framework/tasks/04-implementation/integration-and-testing.md | Status references | Implementation In Progress, Ready for Validation | Task def (NORMATIVE) |
| process-framework/guides/03-testing/test-audit-usage-guide.md | Status references | Ready for Validation, Tests Implemented, Implementation In Progress | Guide (NORMATIVE) |
| process-framework/infrastructure/process-framework-task-registry.md | Status references | Specification Created, Implementation In Progress, Ready for Validation, Tests Implemented | Infrastructure (NORMATIVE) |
| process-framework/infrastructure/task-transition-registry.md | Status references | Ready for Validation, Tests Approved with Dependencies | Infrastructure (NORMATIVE) |
| process-framework/templates/03-testing/audit-tracking-template.md | Legend | Tests Implemented, Tests Approved with Dependencies | Template |
| process-framework/templates/03-testing/test-audit-report-template.md | Status references | Tests Approved with Dependencies | Template |
| test/state-tracking/audit/audit-tracking-e2e-1.md | Legend + status values | Tests Implemented, Tests Approved with Dependencies | State file |
| process-framework/scripts/AUTOMATION-USAGE-GUIDE.md | Examples | Tests Implemented | Docs (EXAMPLE) |
| process-framework-local/state-tracking/permanent/process-improvement-tracking.md | IMP-554 description | Specification Created, Tests Implemented, Tests Failing | State file |

### Files NOT updated (archived/old)
- Files under `process-framework-local/proposals/old/` — historical, no update needed
- Files under `process-framework-local/state-tracking/temporary/old/` — historical
- Files under `process-framework-local/feedback/archive/` — historical
- Test audit reports (test/audits/) — historical records, keep original status labels

## Migration Strategy

### Phase 1: Scripts (atomically update all functional code)
1. Update ValidateSet in Update-CodeReviewState.ps1
2. Update switch statement in Update-FeatureImplementationState.ps1
3. Update status assignment in Run-Tests.ps1
4. Update auditable statuses array in New-AuditTracking.ps1
5. Update display messages and function calls in New-TestFile.ps1
6. Update examples in TestTracking.psm1 and FeatureTracking.psm1

### Phase 2: Source of truth (legends and templates)
1. Update test-tracking.md status legend (add Next Task column, rename statuses)
2. Update all status values in test-tracking.md table rows
3. Update test-tracking-template.md legend
4. Update audit-tracking-template.md legend
5. Update test-audit-report-template.md references
6. Update audit-tracking-e2e-1.md legend and status values

### Phase 3: Task definitions and guides
1. Update test-audit-task.md status references
2. Update code-review-task.md status references
3. Update integration-and-testing.md status references
4. Update test-audit-usage-guide.md status references
5. Update AUTOMATION-USAGE-GUIDE.md examples

### Phase 4: Infrastructure docs
1. Update process-framework-task-registry.md
2. Update task-transition-registry.md
3. Update process-improvement-tracking.md (mark PF-IMP-554 completed)

## Testing Approach

### Success Criteria
- All scripts execute without errors (test with `-WhatIf` where supported)
- `Validate-StateTracking.ps1` passes with 0 errors
- No remaining references to old status labels in active files (grep verification)
- Status transitions in scripts produce correct new labels

## Rollback Plan

### Trigger Conditions
- Scripts fail to execute after rename
- Validate-StateTracking.ps1 reports errors that can't be resolved

### Rollback Steps
1. Revert all changes using `git diff HEAD` to identify changed files
2. Restore original status strings (all changes are text substitutions)

## Approval

**Approved By:** _________________
**Date:** 2026-04-16

**Comments:**
