---
id: PD-REF-227
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-05-04
updated: 2026-05-04
mode: lightweight
target_area: Update-FeatureRequest.ps1 and Update-PerformanceTracking.ps1
priority: Medium
debt_item: PF-IMP-694
refactoring_scope: Replace unanchored ad-hoc row-match regex with TableOperations helpers
---

# Lightweight Refactoring Plan: Replace unanchored ad-hoc row-match regex with TableOperations helpers

- **Target Area**: Update-FeatureRequest.ps1 and Update-PerformanceTracking.ps1
- **Priority**: Medium
- **Created**: 2026-05-04
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Debt Item**: PF-IMP-694
- **Mode**: Lightweight (no architectural impact)

## Item 1: PF-IMP-694 — Replace unanchored row-match regex with TableOperations helpers

**Scope**: Two PowerShell update scripts — `Update-FeatureRequest.ps1` and `Update-PerformanceTracking.ps1` — use the same defective row-lookup regex pattern: `"\|\s*$([regex]::Escape($Id))\s*\|[^\r\n]*"`. The regex is unanchored (no `^` line anchor and no first-column constraint), so it matches the target ID in **any** column of any row, not just the first. This is a latent bug of the same class as PF-IMP-693 (which fixed the active version of this defect in `Update-ProcessImprovement.ps1`). Latent because the IDs in these specific tables don't currently overlap across columns, but defensive correctness requires elimination of the defect class. Replace the four regex sites with `ConvertFrom-MarkdownTable` (column-aware, schema-correct) following the proven pattern established by PF-IMP-693.

**Affected sites (4)**:
- `process-framework/scripts/update/Update-FeatureRequest.ps1:170` — `Update-RequestRow` function (used in classification path; section `## Active Feature Requests`, ID column = `ID`)
- `process-framework/scripts/update/Update-FeatureRequest.ps1:416` — Defer/Reject inline path (same section, same ID column)
- `process-framework/scripts/update/Update-PerformanceTracking.ps1:213` — `Update-TestEntryContent` function (Test Inventory tables across 4 level subsections; ID column = `ID`)
- `process-framework/scripts/update/Update-PerformanceTracking.ps1:373` — Baselined-transition pre-read (same Test Inventory tables)

**Pattern (proven by PF-IMP-693)**:
```powershell
$rows = ConvertFrom-MarkdownTable -Content $content -Section "## Section Name" -IncludeRawLine
$row  = $rows | Where-Object { $_.ID -eq $TargetId } | Select-Object -First 1
if (-not $row) { Write-Log "..." -Level "ERROR"; return $null }
$currentEntry = $row._RawLine
$columns      = Split-MarkdownTableRow $currentEntry
```

For `Update-PerformanceTracking.ps1`, the Test Inventory table is split across four `### Level N` subsections under `## Test Inventory`. Use `-AllTables` so all four level tables are searched:
```powershell
$rows = ConvertFrom-MarkdownTable -Content $content -Section "## Test Inventory" -AllTables -IncludeRawLine
```

**Changes Made**:
- [x] `Update-FeatureRequest.ps1:170` — replaced ad-hoc regex in `Update-RequestRow` with `ConvertFrom-MarkdownTable -Section "## Active Feature Requests" -IncludeRawLine` + `Where-Object { $_.ID -eq $RequestId }` + `Split-MarkdownTableRow -Line $row._RawLine` (subsumed the manual leading/trailing empty-element trimming).
- [x] `Update-FeatureRequest.ps1:416` — replaced ad-hoc regex in defer/reject inline path with the same helper pattern.
- [x] `Update-PerformanceTracking.ps1:213` — replaced ad-hoc regex in `Update-TestEntryContent` with `ConvertFrom-MarkdownTable -Section "## Test Inventory" -AllTables -IncludeRawLine` + `Where-Object { $_.'Test ID' -eq $TestId }`. `-AllTables` scans all four `### Level N` subsections, matching the existing scope.
- [x] `Update-PerformanceTracking.ps1:373` — replaced ad-hoc regex in Baselined-transition pre-read with the same helper pattern.
- [x] Verified all four sites preserve existing behavior on happy path (column updates, status transitions, error logging) via 5-test manual verification harness — all passed.
- [x] PowerShell parser syntax check on both modified scripts — both parse OK.

**Test Baseline**: 839 passed, 3 skipped, 4 deselected, 4 xfailed, **0 failures, 0 errors** (115.42s on 2026-05-04). Captured via `Run-Tests.ps1 -All`. Note: refactor targets framework PowerShell tooling, not product Python code — no test in the suite covers the affected functions directly. Baseline is recorded to confirm absence of inadvertent product-side regressions.

**Test Coverage Assessment (L4)**: The affected functions live in `process-framework/scripts/update/*.ps1` — framework tooling. The project has **no Pester infrastructure** (no `*.Tests.ps1` files anywhere in repo) and `New-TestFile.ps1` generates Python pytest files, not PowerShell tests. Establishing Pester scaffolding solely to characterize a 4-site mechanical helper substitution would be disproportionate scope. Verification strategy mirrors PF-IMP-693 precedent: **manual functional invocation against real state files**:
- Run each script with `-WhatIf` against a sample valid ID before refactor (capture output)
- Run each script with `-WhatIf` against the same sample ID after refactor (compare output)
- Run each script with `-WhatIf` against a non-existent ID to verify error path preserved
- Run each script with an ID that appears as a substring in a non-matching column (e.g., in Notes or Source) to verify the new column-aware lookup correctly rejects the false-positive match (the latent defect the refactor closes)

**Test Result**: 839 passed, 3 skipped, 4 deselected, 4 xfailed, **0 failures, 0 errors** (105.91s on 2026-05-04). **Diff vs L3 baseline: identical** — zero new failures, zero regressions.

**Manual Functional Verification (per L4 strategy)**: 5 verification tests run via inline Pester-substitute harness. All passed:
1. Defect-class case (PD-FRQ-001 appearing as full-cell value in Source column of PD-FRQ-002 row): OLD regex returned a malformed substring spanning two rows (`| PD-FRQ-001 | Spawned from prior request | ... | 2026-04-01 |` mixing PD-FRQ-001's ID from row-1's Source column with row-1's date). NEW helper correctly returned PD-FRQ-001's actual row by ID-column equality.
2. Happy path on real `feature-request-tracking.md` — PD-FRQ-001 found correctly.
3. Not-found path on feature requests — PD-FRQ-9999 yields no match.
4. Performance-tracking `-AllTables` happy path — BM-001 correctly located across 4 level subsections (16 rows total).
5. Performance-tracking not-found path — BM-9999 yields no match.

**Documentation & State Updates** (L8 grep-recipe shortcut applied):
<!-- Per L8 internal-only-refactor grep recipe: identifiers `Update-FeatureRequest`, `Update-PerformanceTracking`, `Update-RequestRow`, `Update-TestEntryContent` were searched across all 8 product-doc surfaces (doc/state-tracking/features/, doc/technical/, doc/functional-design/, doc/user/, doc/state-tracking/validation/, test/specifications/, README.md) — **0 matches**. Items 1-8 share the collective justification below; item 9 handled individually since this is an IMP, not a TD. -->
- [x] Items 1-8 (Feature state file, TDD, Test spec, FDD, ADR, Integration Narrative, User doc, Validation tracking) — **N/A collectively**: grepped all 8 product-doc surfaces for `Update-FeatureRequest`, `Update-PerformanceTracking`, `Update-RequestRow`, `Update-TestEntryContent` — 0 matches. The refactor targets framework tooling under `process-framework/scripts/update/`; no product doc surface references the refactored scripts or functions. Internal-only signature-preserving change; identical external behavior on all current data.
- [x] **Process Improvement Tracking** (replaces "Technical Debt Tracking" for IMP-routed refactors): **PF-IMP-694** to be marked Resolved at L11 via `Update-ProcessImprovement.ps1 -NewStatus Resolved`.

**Bugs Discovered**: None. The defect class itself was already filed as PF-IMP-694 (latent) and PF-IMP-693 (active, since closed) — no new defects surfaced during the refactor.

<!-- BATCH MODE: Use `-ItemCount N` when running New-RefactoringPlan.ps1 to pre-generate N Item sections up front. To add more items mid-session, copy the "## Item N" section above. -->

## Results Summary

| Item | IMP/Debt ID | Status | Bugs Found | Doc Updates |
|------|-------------|--------|------------|-------------|
| 1 | PF-IMP-694 | Complete | None | None (8 product-doc surfaces grepped — 0 matches) |

**Status set on**: 2026-05-04
**Sites refactored**: 4 (Update-FeatureRequest.ps1 ×2, Update-PerformanceTracking.ps1 ×2)
**Test diff (L7 vs L3)**: identical — 839 passed, 0 failures both runs.
**Defect class closed**: unanchored row-match regex matching IDs in any column. Same defect class as PF-IMP-693 (which fixed the active version in Update-ProcessImprovement.ps1). Update-ProcessImprovement.ps1 + Update-FeatureRequest.ps1 + Update-PerformanceTracking.ps1 — the three IMP/feature-request/performance-test row-update scripts — now all use the column-aware helper pattern.

**Latent defect remaining (out of scope)**: `Move-MarkdownTableRow` in `TableOperations.psm1:834` has the same defect class (already filed as **PF-IMP-695**). That helper-level defect is broader (fixes all callers including Move-ToCompletedSection in Update-ProcessImprovement.ps1) and warrants its own refactor session.

## Related Documentation
- [Process Improvement Tracking](/process-framework-local/state-tracking/permanent/process-improvement-tracking.md) — PF-IMP-694 entry
- [Sister fix PF-IMP-693](/process-framework-local/state-tracking/permanent/process-improvement-tracking.md) — the active-bug precedent that established the helper pattern
- [TableOperations.psm1](/process-framework/scripts/Common-ScriptHelpers/TableOperations.psm1) — `ConvertFrom-MarkdownTable`, `Split-MarkdownTableRow`
