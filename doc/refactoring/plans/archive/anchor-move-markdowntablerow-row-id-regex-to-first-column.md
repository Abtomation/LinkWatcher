---
id: PD-REF-228
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-05-04
updated: 2026-05-04
target_area: process-framework/scripts/Common-ScriptHelpers/TableOperations.psm1
debt_item: PF-IMP-695
priority: LOW
refactoring_scope: Anchor Move-MarkdownTableRow row-id regex to first column
mode: lightweight
---

# Lightweight Refactoring Plan: Anchor Move-MarkdownTableRow row-id regex to first column

- **Target Area**: process-framework/scripts/Common-ScriptHelpers/TableOperations.psm1
- **Priority**: LOW
- **Created**: 2026-05-04
- **Author**: AI Agent & Human Partner
- **Status**: Planning
- **Debt Item**: PF-IMP-695
- **Mode**: Lightweight (no architectural impact)

## Item 1: PF-IMP-695 — Anchor row-id match in `Move-MarkdownTableRow` to the first column

**Scope**: `Move-MarkdownTableRow` in [TableOperations.psm1:834](/process-framework/scripts/Common-ScriptHelpers/TableOperations.psm1) currently locates the target row with `^\|.*$RowIdPattern.*\|`. The unanchored `.*` lets `$RowIdPattern` match anywhere in the row, so any row whose Description, Notes, or other column contains the same ID will be selected before the actual ID-bearing row. Same defect class as PF-IMP-693 (active, fixed) and PF-IMP-694 (latent, fixed). Fix: keep the regex parameter contract but match `$RowIdPattern` only against the trimmed first cell of each candidate line, parsed via the helper's existing `Split-MarkdownTableRow` companion (already used at lines 813 and 847). Three production callers — `Move-ToCompletedSection` in [Update-ProcessImprovement.ps1](/process-framework/scripts/update/Update-ProcessImprovement.ps1), the move-to-completed path in [Update-FeatureRequest.ps1](/process-framework/scripts/update/Update-FeatureRequest.ps1), and [Archive-Feature.ps1](/process-framework/scripts/update/Archive-Feature.ps1) — inherit the fix without their own changes; all three already pass `[regex]::Escape($Id)`. Dimension: code quality / maintainability (defect-class elimination).

**Changes Made**:
- [x] Replaced the unanchored regex `^\|.*$RowIdPattern.*\|` at the row-search loop in `Move-MarkdownTableRow` with a `Split-MarkdownTableRow` parse + first-cell anchored match `$candidateCells[0].Trim() -match "^$RowIdPattern$"`. Mirrors how the helper already parses headers and the matched row, preserves the documented regex contract, and skips non-table candidate lines safely. Added a 4-line comment block explaining the defect-class closure (PF-IMP-693/PF-IMP-694 reference).
- [x] Built a one-shot synthetic harness at `process-framework-local/tools/verify-imp-695.ps1` (5 tests: cross-column defect, two happy paths, two error paths). Pre-fix run: 4/5 (T1 fails — defect proven active). Post-fix run: 5/5.

**Test Baseline** (Run-Tests.ps1 -All, 2026-05-04): 839 passed, 3 skipped, 4 deselected, 4 xfailed, 0 failed, 0 errors. No pre-existing failures. Note: the pytest suite covers Python product code (linkwatcher); the PowerShell helper under change has no automated coverage in pytest. A synthetic PowerShell harness will provide direct verification of the defect-class closure (see L4).
**Test Result** (post-fix, 2026-05-04):
- pytest regression: 839 passed, 3 skipped, 4 deselected, 4 xfailed — identical to L3 baseline. Zero new failures.
- Synthetic harness: 5/5 passed (T1 cross-column, T2 happy-end, T3 happy-start, T4 row-not-found, T5 missing-source). Pre-fix was 4/5 (T1 failed, demonstrating the defect was active in code).

**Documentation & State Updates**:

Internal-only refactor — same signature, same return shape, no public API surface touched, regex contract preserved (still a regex; just anchored to first column). Grepped all 8 doc surfaces in one ripgrep pass:

```
grep -rln "Move-MarkdownTableRow" doc/state-tracking/features/ doc/technical/ doc/functional-design/ doc/user/ doc/state-tracking/validation/ test/specifications/ README.md
```

→ **0 matches**. The helper is referenced only from `process-framework/scripts/Common-ScriptHelpers/TableOperations.psm1` (definition + export list), three caller scripts (Update-ProcessImprovement, Update-FeatureRequest, Archive-Feature), `process-framework/PF-documentation-map.md` (which lists the helper as a process-framework asset, not a doc-surface reference), and process-improvement-tracking.md / feedback archive entries (history of prior IMPs that created/refactored the helper).

- [x] Items 1–8 collectively N/A — *Grepped all design/state/user-doc/validation surfaces for `Move-MarkdownTableRow` — 0 matches; no doc surface references the refactored internal.*
- [ ] **Item 9 (PF-IMP-695)**: status transition to Completed via `Update-ProcessImprovement.ps1` — performed at L11 after L10 checkpoint approval.

**Bugs Discovered**: None / [Description]

<!-- BATCH MODE: Use `-ItemCount N` when running New-RefactoringPlan.ps1 to pre-generate N Item sections up front. To add more items mid-session, copy the "## Item N" section above. -->

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | PF-IMP-695 | Complete | None | None — internal-only refactor; grepped 8 doc surfaces for `Move-MarkdownTableRow`, 0 matches |

**Defect-class status**: This was the last unfixed instance of the unanchored-row-match regex defect class shared with PF-IMP-693 (active, fixed) and PF-IMP-694 (latent, fixed). With this fix, no production caller of any row-search helper in the framework relies on unanchored row-id regex matching.

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
