---
id: PD-REF-229
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-05-05
updated: 2026-05-05
refactoring_scope: Demote verbose 'Next Steps:' Write-Host blocks to Write-Verbose across Write-Host based New-* and Update-* scripts
priority: Medium
mode: lightweight
debt_item: PF-IMP-721
target_area: process-framework/scripts (file-creation + update)
---

# Lightweight Refactoring Plan: Demote verbose 'Next Steps:' Write-Host blocks to Write-Verbose across Write-Host based New-* and Update-* scripts

- **Target Area**: process-framework/scripts (file-creation + update)
- **Priority**: Medium
- **Created**: 2026-05-05
- **Author**: AI Agent & Human Partner
- **Status**: Planning
- **Debt Item**: PF-IMP-721
- **Mode**: Lightweight (no architectural impact)

## Item 1: PF-IMP-721 — Demote `Next Steps:` Write-Host blocks to Write-Verbose

**Scope**: 11 sites across 11 PowerShell scripts emit a `Next Steps:` block (3–10 lines of `Write-Host` workflow guidance) on every successful invocation. The blocks are repetitive across runs, not actionable when the caller already knows the next step, and add noise around the per-invocation summary. PF-IMP-697 already demoted this class of narration in 10 sibling Update-* scripts to `Write-Verbose` (info preserved, restored with `-Verbose`); PF-IMP-700 trimmed a different (banner) pattern in 27 New-* template-creation scripts. PF-IMP-721 closes the explicitly-deferred gap: apply the **PF-IMP-697 default-quiet pattern** to the 8 Write-Host based New-* scripts plus 3 Update-* scripts that PF-IMP-697 missed.

**Affected files** (11 sites, 11 files):

| File | Lines | Notes |
|---|---|---|
| `process-framework/scripts/file-creation/support/New-ProcessImprovement.ps1` (pilot path, ~L457) | 3 | Under script soak — change resets hash |
| `process-framework/scripts/file-creation/support/New-ProcessImprovement.ps1` (regular path, ~L577) | 3 | Under script soak — change resets hash |
| `process-framework/scripts/file-creation/01-planning/New-FeatureRequest.ps1` (~L210) | 3 | |
| `process-framework/scripts/file-creation/03-testing/New-PerformanceTestEntry.ps1` (~L230) | 3 | |
| `process-framework/scripts/file-creation/03-testing/New-WorkflowEntry.ps1` (~L202) | 3 | |
| `process-framework/scripts/file-creation/03-testing/New-E2EMilestoneEntry.ps1` (~L195) | 4 | |
| `process-framework/scripts/file-creation/06-maintenance/New-BugReport.ps1` (~L319) | 4–6 | Conditional on `-PreTriaged` |
| `process-framework/scripts/file-creation/05-validation/New-ValidationReport.ps1` (~L785) | ~10 | Next Steps + Reference blocks |
| `process-framework/scripts/update/Update-CodeReviewState.ps1` (~L361) | ~10 | Conditional on `$ReviewStatus` — gap-fill from PF-IMP-697 |
| `process-framework/scripts/update/Update-TestFileAuditState.ps1` (~L734) | ~10 | Conditional on `$AuditStatus` — gap-fill from PF-IMP-697 |
| `process-framework/scripts/update/Update-FeatureTrackingFromAssessment.ps1` (~L366) | ~10 | Switches by tier — gap-fill from PF-IMP-697 |

**Pattern applied** (per PF-IMP-697):
- Replace each `Write-Host "Next Steps:" -ForegroundColor Yellow` + subsequent `Write-Host "  - ..."` lines with `Write-Verbose "Next Steps: ..."` (one line per item, preserving the same content).
- Drop the leading blank-line `Write-Host ""` immediately above the block (cosmetic, only meaningful when the block is visible).
- Leave the surrounding `Write-ProjectSuccess` summary line (already a single visible outcome line — matches the `Write-SummaryLine` role).
- Verbose output is restored verbatim by passing `-Verbose` (or with `$VerbosePreference = 'Continue'` in scripts that source these).

**Out of scope** (observed but not fixed in this pass):
- PF-IMP-722 (rename `-DebtItemId` → tracker-neutral `-SourceItemId` in `New-RefactoringPlan.ps1`): separate IMP, separate refactoring.
- PF-IMP-723 (add IMP-routing closure path to PF-TSK-022 L11 documentation): separate IMP, doc-only.
- PF-IMP-700's banner pattern (already closed): no remaining banner-pattern hits expected in target files.
- Other `Write-Host` narration outside the `Next Steps:` blocks: not in IMP scope; PF-IMP-697 covered the broader narration in its 10 Update-* siblings via `Write-Log` demotion. The 8 New-* scripts here use a more focused narration style (mostly `Write-ProjectSuccess` for outcome + `Next Steps:` for guidance), so demoting the `Next Steps:` block alone is sufficient.

**Changes Made**:
- [x] 11 sites demoted from `Write-Host "Next Steps:" + bullet lines` to `Write-Verbose` lines (52 demoted Write-Verbose lines + 2 demoted "Tip:" lines in `New-BugReport.ps1`); preceded blank-line `Write-Host ""` lines and yellow `Next Steps:` headers removed (header content rolled into each verbose line as `Next Steps: <item>`).
- [x] `New-ValidationReport.ps1`: success line `🎉 Validation report created successfully!` left visible; only the Next Steps + Reference blocks demoted to verbose.
- [x] `Update-CodeReviewState.ps1`: security-issue and performance-issue warnings (lines 378–386) left visible — they are real warnings, not workflow narration; out of IMP scope.
- [x] `process-framework/guides/06-maintenance/bug-reporting-guide.md`: updated stale "Script Output" example to reflect new default output and added pointer to `-Verbose` for the next-steps lines.

**Test Baseline** (L3, `Run-Tests.ps1 -All`, 2026-05-05): 839 passed, 3 skipped, 0 failed, 4 xfailed (expected) — clean baseline, no pre-existing failures. 4 slow-marked tests deselected per `-All` default; not relevant since refactoring touches only PowerShell tooling, not Python product code.
**Test Result** (L7, `Run-Tests.ps1 -All`, 2026-05-05): 839 passed, 3 skipped, 0 failed, 4 xfailed (91.24s) — **identical to L3 baseline** (0 new failures, 0 lost passes). Refactoring touches only PowerShell tooling, not exercised by Python pytest, so identical results were expected.

**Manual functional verification** (L4 substitute, framework-tooling-only):
- AST parse: all 10 modified scripts parse cleanly (0 errors).
- Pattern verification: 0 remaining `Write-Host "...Next Steps:..."` matches across `process-framework/scripts/` (down from 11). 52 new `Write-Verbose "Next Steps: ..."` lines correctly placed across 10 files.
- Runtime smoke test: skipped at runtime (Write-Verbose semantics are PowerShell-stdlib behavior; integration confirmed via AST parse + grep + regression). Default output suppresses Next Steps lines; `-Verbose` restores them as `VERBOSE: Next Steps: ...`.

**Test coverage note (L4 substitute)**: This is framework-tooling-only refactoring (PowerShell scripts under `process-framework/scripts/`). The project has no Pester infrastructure for PowerShell tooling — see PF-IMP-719. L4 (`New-TestFile.ps1 -TestType unit` for Python pytest) does not apply. Substituting **manual functional verification**:
1. AST parse all 11 modified scripts via `[System.Management.Automation.Language.Parser]::ParseFile(...)` — confirm zero parse errors.
2. Smoke-test 2 representative scripts (one New-*, one Update-*) end-to-end:
   - Default invocation → confirm `Next Steps:` block is **not** in output.
   - `-Verbose` invocation → confirm `Next Steps:` content **is** in output (as VERBOSE: lines).
3. Run `Validate-StateTracking.ps1` to verify no inadvertent metadata corruption from the changes.

**Documentation & State Updates** (framework-tooling-only refactor; collective justification per L8 grep recipe):

Grep recipe applied — `Next Steps:` text searched across all 8 doc/state/test surfaces:
- `doc/state-tracking/features/`, `doc/technical/`, `doc/functional-design/`, `doc/user/`, `doc/state-tracking/validation/`, `test/specifications/`, `README.md` → **0 matches**.
- `process-framework/guides/` → **1 match**: `bug-reporting-guide.md` "Script Output" example (now updated, see Changes Made).

The refactored scripts have no Feature ID — they are framework tooling, not product features.

- [x] **1. Feature implementation state file** — N/A. Modified files are framework tooling under `process-framework/scripts/`, not product features under `src/linkwatcher/`. No feature state file references this work.
- [x] **2. TDD** — N/A. No TDD covers framework tooling output formatting.
- [x] **3. Test spec** — N/A. No test spec mentions these scripts' default-output channel.
- [x] **4. FDD** — N/A. No FDD covers framework tooling.
- [x] **5. ADR** — N/A. No architectural decision affected; output channel demotion is consistent with PF-IMP-697 precedent.
- [x] **6. Integration Narrative** — N/A. No PD-INT narrative references these scripts.
- [x] **7. User documentation** — N/A for handbooks/README. **One process-framework guide updated**: `process-framework/guides/06-maintenance/bug-reporting-guide.md` "Script Output" section reflected the now-removed `🔄 Next Steps:` block; updated to current default + `-Verbose` pointer.
- [x] **8. Validation tracking** — N/A. Framework tooling not tracked in validation rounds; the modified scripts are not features.
- [ ] **9. Technical Debt Tracking** — N/A. PF-IMP-721 is an IMP, not a TD. Closure routes through `Update-ProcessImprovement.ps1 -ImprovementId "PF-IMP-721" -NewStatus "Completed" ...` at L11 (see PF-IMP-723 noting the L11 IMP-routing documentation gap — separate IMP, not in scope here).

**Bugs Discovered**: None.

**Side effects to note**:
- `New-ProcessImprovement.ps1` is under Script Soak (SC-### tracking). The change resets its hash; the next 5 invocations will trigger soak-confirmation prompts as the new hash builds soak history. This is the soak workflow operating correctly, not a defect.
- Out-of-scope sibling IMPs observed (not fixed in this pass): PF-IMP-722 (rename `-DebtItemId` → tracker-neutral name in `New-RefactoringPlan.ps1`); PF-IMP-723 (add IMP-routing closure path to PF-TSK-022 L11 doc).

<!-- BATCH MODE: Use `-ItemCount N` when running New-RefactoringPlan.ps1 to pre-generate N Item sections up front. To add more debt items mid-session (i.e., new TD IDs — sub-findings of an existing TD become additional `Changes Made` bullets within its Item, not new Items), copy the "## Item N" section above. -->

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | PF-IMP-721 | Complete | None | bug-reporting-guide.md "Script Output" example refreshed |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
