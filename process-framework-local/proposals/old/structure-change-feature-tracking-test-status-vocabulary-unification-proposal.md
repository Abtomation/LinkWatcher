---
id: PF-PRO-027
type: Document
category: General
version: 1.0
created: 2026-04-22
updated: 2026-04-22
---

# Structure Change Proposal: Feature-Tracking Test Status Vocabulary Unification

## Overview
Unify the test-status vocabulary used in the **feature-tracking.md `Test Status` column** so the legend and all scripts that write to the column agree. Today three writers emit two different vocabularies, and the read side (Validate-StateTracking Surface 15) compensates via a `Get-TestStatusGroup` canonicalization layer.

Target: legend ↔ writers ↔ reader all use one label per canonical state. Surface 15 collapses to identity comparison.

**Structure Change ID:** SC-PENDING
**Proposer:** AI Agent & Human Partner
**Date Proposed:** 2026-04-22
**Target Implementation Date:** 2026-04-22

**Related:**
- Precedent: [PF-IMP-554 / SC-024 — Test Tracking Status Legend Alignment](structure-change-test-tracking-status-legend-alignment-proposal.md) (already completed for **test-tracking.md**; this proposal extends the same discipline to **feature-tracking.md**).
- Source: [PF-IMP-574](../../state-tracking/permanent/process-improvement-tracking.md)
- Bridge artifact: [Validate-StateTracking.ps1 Surface 15 `Get-TestStatusGroup`](../../../process-framework/scripts/validation/Validate-StateTracking.ps1)

## Current Structure

### Legend (feature-tracking.md, 8 states)

| Symbol | Status            | Description |
|--------|-------------------|-------------|
| ⬜     | No Tests          | No test specifications exist for this feature |
| 🚫     | No Test Required  | Feature explicitly marked as not requiring tests |
| 📋     | Specs Created     | Test specifications exist but implementation not started |
| 🟡     | In Progress       | Some tests implemented, some pending |
| ✅     | All Passing       | All automated AND manual tests implemented and passing |
| 🔴     | Some Failing      | Some tests are failing |
| 🔧     | Automated Only    | Only automated tests exist; manual test cases not yet created |
| 🔄     | Re-testing Needed | Code changes require manual test re-execution |

### Two writers, two vocabularies

| Writer | Script | Vocabulary | Emits |
|---|---|---|---|
| W1 | [Update-TestFileAuditState.ps1:596-612](../../../process-framework/scripts/update/Update-TestFileAuditState.ps1) | Audit-centric | `✅ Audit Approved`, `🔴 Tests Failed Audit`, `🔄 Tests Need Update`, `🟡 Tests In Progress`, `🟡 Tests Partially Approved`, `🔍 Audit In Progress`, `⬜ No Tests` |
| W2 | [Update-TestExecutionStatus.ps1:344-346](../../../process-framework/scripts/test/e2e-acceptance-testing/Update-TestExecutionStatus.ps1) | Legend | `✅ All Passing`, `🔴 Some Failing`, `🔄 Re-testing Needed` |

> **Note**: An earlier draft listed Update-FeatureImplementationState.ps1:202 as a third writer. On re-verification, that script's `Update-FeatureTrackingStatus` call (line 186) writes to the **Implementation Status** column, not Test Status. Line 202's `✅ Audit Approved` is passed to `Update-TestImplementationStatus` (test-tracking.md per-test status, SC-024 vocabulary — correct, out of scope).

### Bridge (reader compensation)

[Validate-StateTracking.ps1 Surface 15 `Get-TestStatusGroup`](../../../process-framework/scripts/validation/Validate-StateTracking.ps1) maps both vocabularies into 9 canonical groups:

```powershell
if ($s -match '^✅\s*(All\s*Passing|Audit\s*Approved)')                                        { return "PASSING" }
if ($s -match '^🔴\s*(Some\s*Failing|Tests\s*Failed\s*Audit|Needs\s*Fix|Audit\s*Failed)')      { return "FAILING" }
if ($s -match '^🔄\s*(Re-?testing\s*Needed|Tests\s*Need\s*Update|Needs\s*Update|Needs\s*Audit)') { return "NEEDS_RETEST" }
if ($s -match '^(🟡|🔍)')                                                                      { return "IN_PROGRESS" }
# ...
```

### Example of drift in live rows

- [feature-tracking.md:120](../../../doc/state-tracking/permanent/feature-tracking.md#L120) — `✅ All Passing` (legend vocab)
- [feature-tracking.md:173](../../../doc/state-tracking/permanent/feature-tracking.md#L173) — `✅ Audit Approved` (aggregator vocab)

Both canonicalize to PASSING, but they coexist in the same column.

## Proposed Structure

### Unified legend (hybrid — preserves both populations)

Option 3 from the Step 5 checkpoint: **keep legend's broader taxonomy AND add aggregator-only states; unify the collision pairs to the legend label**. The audit-state detail remains authoritative in `test-tracking.md`; the feature-tracking column is a feature-level outcome view.

| Symbol | Status                     | Description                                                            | Written by |
|--------|----------------------------|------------------------------------------------------------------------|------------|
| ⬜     | No Tests                   | No test specifications exist for this feature                          | W1, human  |
| 🚫     | No Test Required           | Feature explicitly marked as not requiring tests                       | human      |
| 📋     | Specs Created              | Test specifications exist but implementation not started               | human      |
| 🟡     | In Progress                | Some tests implemented, some pending                                   | W1, human  |
| 🔍     | Audit In Progress          | At least one test file is currently undergoing audit                   | W1         |
| 🟡     | Tests Partially Approved   | Some test files passed audit, others are still pending audit           | W1         |
| ✅     | All Passing                | All automated AND manual tests implemented and passing                 | W1, W2, W3, human |
| 🔴     | Some Failing               | One or more tests are failing or failed audit                          | W1, W2, human |
| 🔧     | Automated Only             | Only automated tests exist; manual test cases not yet created          | human      |
| 🔄     | Re-testing Needed          | Code changes or audit findings require test updates / re-execution     | W1, W2, human |

Two additions to the legend: `🔍 Audit In Progress`, `🟡 Tests Partially Approved`. No removals.

### Status rename mapping

| Old (aggregator vocab) | New (canonical) | Rationale |
|---|---|---|
| `✅ Audit Approved` | `✅ All Passing` | Feature-level outcome view — audit gate detail remains in test-tracking.md |
| `🔴 Tests Failed Audit` | `🔴 Some Failing` | Consistent with legend label; failure type still visible per-test in test-tracking.md |
| `🔄 Tests Need Update` | `🔄 Re-testing Needed` | Legend label subsumes "update needed → re-test" |
| `🟡 Tests In Progress` | `🟡 In Progress` | Legend label |
| `🟡 Tests Partially Approved` | `🟡 Tests Partially Approved` | Added to legend — no change |
| `🔍 Audit In Progress` | `🔍 Audit In Progress` | Added to legend — no change |

Writers W2 and Update-TestExecutionStatus.ps1 regex on line 362 already use legend vocab; only update the regex to match any new/preserved values.

## Rationale

### Benefits

- **Eliminates `Get-TestStatusGroup` canonicalization layer** — Surface 15 collapses to direct equality, removing ~12 lines of regex-based mapping and its maintenance burden.
- **One vocabulary = one mental model** — future writers/readers don't need to know about the bridge; if they emit a legend value, it's correct.
- **Precedent match** — SC-024 already established this discipline for test-tracking.md's per-test vocabulary; this applies it to feature-tracking.md's per-feature vocabulary.
- **Information preservation** — unlike a pure rename, this hybrid adds new legend rows (`🔍 Audit In Progress`, `🟡 Tests Partially Approved`) so no audit-cycle granularity is lost.
- **Concrete defect reduction** — the 4 split-brain mismatches logged in [PF-IMP-575](../../state-tracking/permanent/process-improvement-tracking.md) are the category of bug that unification prevents.

### Challenges

- **Two aggregator-only states added to legend** may feel odd to human readers who maintain feature-tracking manually. Mitigation: description column states when each applies.
- **W1 rename is a breaking change to its output** — consumers that substring-match on "Audit Approved" must be updated atomically.
- **Existing `✅ Audit Approved` / `🔴 Tests Failed Audit` rows** in feature-tracking.md must be rewritten to the new labels — string-substitution migration, scope-limited.
- **Surface 15 collapse must happen in the same commit as the vocabulary change** or validation will flag every migrated row.

## Affected Files

### Impact Matrix (scope derived from Step 4 analysis)

| File | Change Type | Status Strings Affected | Usage Type |
|------|------------|------------------------|------------|
| [doc/state-tracking/permanent/feature-tracking.md](../../../doc/state-tracking/permanent/feature-tracking.md) | Legend + table rows | All mapped statuses (legend + 12 existing row occurrences) | Source of truth |
| [process-framework/scripts/update/Update-TestFileAuditState.ps1](../../../process-framework/scripts/update/Update-TestFileAuditState.ps1) | Output string literals (lines ~596-612) | Audit Approved → All Passing; Tests Failed Audit → Some Failing; Tests Need Update → Re-testing Needed; Tests In Progress → In Progress | Script (FUNCTIONAL — BREAKING) |
| [process-framework/scripts/test/e2e-acceptance-testing/Update-TestExecutionStatus.ps1](../../../process-framework/scripts/test/e2e-acceptance-testing/Update-TestExecutionStatus.ps1) | Regex bridge (line 362) | Update regex to drop retired aggregator labels after W1 migrates | Script (FUNCTIONAL) |
| [process-framework/scripts/validation/Validate-StateTracking.ps1](../../../process-framework/scripts/validation/Validate-StateTracking.ps1) | Surface 15 — **two places** | (a) Internal aggregator (~lines 1525-1540) — rename emitted labels to match W1's new legend vocab (otherwise Surface 15 simulation doesn't match writer output); (b) `Get-TestStatusGroup` — drop it, replace with direct string equality | Script (FUNCTIONAL + SIMPLIFIED) |
| [process-framework/scripts/Common-ScriptHelpers/FeatureTracking.psm1:58](../../../process-framework/scripts/Common-ScriptHelpers/FeatureTracking.psm1) | Example string in documentation | Update "✅ Audit Approved" to "✅ All Passing" in the example | Script (EXAMPLE) |
| [process-framework/scripts/AUTOMATION-USAGE-GUIDE.md](../../../process-framework/scripts/AUTOMATION-USAGE-GUIDE.md) (lines 27, 140, 205) | Example strings showing feature-tracking Test Status | Update `"✅ Audit Approved"` → `"✅ All Passing"` in examples. **Note**: these examples also show a non-existent `-TestStatus` parameter — defect to be logged separately as a new IMP; only the vocabulary fix is in scope here. | Docs (EXAMPLE) |
| [process-framework-local/state-tracking/permanent/process-improvement-tracking.md](../../state-tracking/permanent/process-improvement-tracking.md) | Close PF-IMP-574, annotate PF-IMP-575 likely auto-resolves | — | State file |

### Files verified NOT in scope

- **test-tracking.md and all audit reports** — already handled by SC-024; their `✅ Audit Approved` usage is per-test and correct.
- [process-framework/scripts/update/Update-CodeReviewState.ps1](../../../process-framework/scripts/update/Update-CodeReviewState.ps1) — its `-TestStatusUpdate` ValidateSet targets `Update-TestImplementationStatus` (per-test status in test-tracking.md), not feature-tracking Test Status. Its SC-024 vocabulary is correct for its target.
- [process-framework/tasks/03-testing/test-audit-task.md](../../../process-framework/tasks/03-testing/test-audit-task.md) — `Audit Approved` references are per-test (test-file status), not feature-tracking Test Status. `🚫 No Test Required` references stay valid (legend-only, unchanged).
- [process-framework/tasks/03-testing/test-specification-creation-task.md](../../../process-framework/tasks/03-testing/test-specification-creation-task.md) — uses `📋 Specs Created` / `🚫 No Test Required` which are legend-only and unchanged.
- [process-framework/visualization/context-maps/03-testing/test-specification-creation-map.md](../../../process-framework/visualization/context-maps/03-testing/test-specification-creation-map.md) — uses legend vocabulary already.
- Archived files under `process-framework-local/proposals/old/`, `process-framework-local/state-tracking/temporary/old/`, `process-framework-local/feedback/archive/`, and `test/audits/` — historical, do not touch.

## Migration Strategy

### Phase 1: Atomically update all writers and the Surface 15 internal aggregator

1. Update-TestFileAuditState.ps1 (lines ~596-612) — rename the four aggregator outputs to legend labels; keep `🟡 Tests Partially Approved` and `🔍 Audit In Progress` as-is (now also legend states).
2. Update-TestExecutionStatus.ps1 (line 362) — update regex to drop retired aggregator labels after W1 migrates.
3. Validate-StateTracking.ps1 internal aggregator (~lines 1525-1540) — rename its emitted labels to match W1's new legend vocabulary. **Must happen in same commit as W1** or Surface 15 reports mismatches on every audited feature.
4. FeatureTracking.psm1 (line 58) — update the example string.
5. AUTOMATION-USAGE-GUIDE.md (lines 27, 140, 205) — update the `-TestStatus` example values to legend vocabulary.

### Phase 2: Update source of truth (legend)

1. Edit feature-tracking.md legend table — add two rows (`🔍 Audit In Progress`, `🟡 Tests Partially Approved`); existing rows unchanged.

### Phase 3: Rewrite existing table rows

1. Grep feature-tracking.md for retired aggregator labels (`✅ Audit Approved`, `🔴 Tests Failed Audit`, `🔄 Tests Need Update`, `🟡 Tests In Progress`) and rewrite to legend labels.
2. Leave `🟡 Tests Partially Approved` and `🔍 Audit In Progress` rows as-is.

### Phase 4: Simplify Surface 15

1. Drop `Get-TestStatusGroup` function in Validate-StateTracking.ps1.
2. Rewrite Surface 15 comparison logic to direct string equality between test-tracking's aggregated view and feature-tracking's Test Status column.
3. Re-run `Validate-StateTracking.ps1 -Surface TestStatusAggregation` — expect 0 errors (or only the 4 already-logged PF-IMP-575 cases, which should auto-resolve after Phase 1 triggers Update-TestFileAuditState for those features).

### Phase 5: Close out

1. Close PF-IMP-574 (vocabulary unification) — Completed.
2. Re-evaluate PF-IMP-575 — likely auto-resolves after Phase 4 validation; if any cases remain, manually run Update-TestFileAuditState.ps1 per feature to re-aggregate.
3. Archive this proposal to `process-framework-local/proposals/old/`.

## Testing Approach

### Test Cases
- Run `Update-TestFileAuditState.ps1 -WhatIf` for a test feature with all test files `Audit Approved` — expect output to write `✅ All Passing` to feature-tracking.
- Run same with partial `Audit Approved` — expect `🟡 Tests Partially Approved`.
- Run same with at least one `🔄 Needs Update` test — expect `🔄 Re-testing Needed`.
- Run `Validate-StateTracking.ps1 -Surface TestStatusAggregation` — expect 0 errors.
- Grep feature-tracking.md for retired labels (`Audit Approved`, `Tests Failed Audit`, `Tests Need Update`, `Tests In Progress` as column values) — expect 0 hits.

### Success Criteria
- All three writers emit legend vocabulary exclusively.
- Surface 15 uses direct string comparison (no canonicalization function).
- `Validate-StateTracking.ps1 -Surface All` passes with 0 errors.
- No remaining retired aggregator labels in feature-tracking.md active table rows.

## Rollback Plan

### Trigger Conditions
- Any writer script breaks (Update-TestFileAuditState, Update-FeatureImplementationState, Update-CodeReviewState, Update-TestExecutionStatus) after edits.
- Surface 15 reports new unresolvable errors after Phase 4 simplification.
- Downstream tooling (feedback DB, bug-tracker queries, etc.) found to rely on retired labels.

### Rollback Steps
1. All changes are text substitutions and small logic changes — `git diff HEAD` identifies every touched file.
2. Revert writer scripts first (restores old output vocabulary).
3. Restore `Get-TestStatusGroup` in Validate-StateTracking.ps1 (Surface 15 regains its bridge).
4. Revert feature-tracking.md legend and row edits.
5. Rollback is safe at any phase boundary; Phase 1-3 independently reversible, Phase 4 depends on Phases 1-3 being complete or fully reverted.

## Resources Required

### Personnel
- AI Agent + Human Partner — ~1 session (single contiguous execution, no multi-session split expected).

### Tools
- Grep (for reference sweeps and migration verification)
- pwsh.exe + Update-*.ps1 scripts (for -WhatIf smoke tests)
- Validate-StateTracking.ps1 (post-change validation)

## Metrics

### Implementation Metrics
- Number of files touched: expected ~7-8 (listed in impact matrix).
- Lines changed in Validate-StateTracking.ps1 Surface 15: expected net reduction (Get-TestStatusGroup removal > identity check addition).
- Grep hits for retired aggregator labels after migration: 0 in active files.

### User Experience Metrics
- Surface 15 runtime: marginal decrease (no regex mapping per row).
- Post-audit feature-tracking row-writes by W1: use legend vocab (no human re-editing needed afterward).

## Approval

**Approved By:** _________________
**Date:** 2026-04-22

**Comments:**
