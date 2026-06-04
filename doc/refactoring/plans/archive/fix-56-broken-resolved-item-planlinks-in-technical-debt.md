---
id: PD-REF-233
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-06-04
updated: 2026-06-04
priority: Medium
refactoring_scope: Fix 56 broken resolved-item PlanLinks in technical-debt-tracking-archive.md (off-by-one relative prefix after PF-IMP-873 archive split, plus stale non-archive targets)
target_area: technical-debt-tracking-archive.md
mode: documentation-only
debt_item: TD258
---

# Documentation Refactoring Plan: Fix 56 broken resolved-item PlanLinks in technical-debt-tracking-archive.md (off-by-one relative prefix after PF-IMP-873 archive split, plus stale non-archive targets)

## Overview
- **Target Area**: technical-debt-tracking-archive.md
- **Priority**: Medium
- **Created**: 2026-06-04
- **Author**: AI Agent & Human Partner
- **Status**: Planning
- **Mode**: Documentation-only (no code changes, no test impact)
- **Debt Item**: TD258

## Refactoring Scope
<!-- Detailed description of what documentation will be refactored and why -->

### Current Issues
- **52 off-by-one relative links**: resolved-item PlanLinks use a 2-up prefix `](../../refactoring/plans/archive/…)` that resolves to the nonexistent `doc/state-tracking/refactoring/plans/archive/`. The archive file lives at `doc/state-tracking/permanent/archive/`, so the correct prefix is 3-up `../../../`.
- **4 stale non-archive links** (TD258 sub-findings, lines 242, 252, 255, 258): point at the pre-archive live location `[/]doc/refactoring/plans/<file>.md` (root-relative, missing the `archive/` segment) for plans that were since moved into `archive/`. Broken in two ways — wrong directory **and** non-canonical prefix.
- **Net**: 56 broken PlanLinks of ~70 total. The file carries 4 competing prefix styles (2-up relative, 3-up relative, leading-slash root, no-slash root).

### Scope Discovery
- **Original Tech Debt Description**: "Resolved-item PlanLinks … use a `../../refactoring/plans/archive/…` prefix (2 ups) … off-by-one after the 2026-05-26 archive-split (PF-IMP-873) … Recompute the relative PlanLinks so they resolve to `doc/refactoring/plans/archive/`." → implies 52 links, single failure mode.
- **Actual Scope Findings**: The 52 two-up links (as described) **plus** 4 stale non-archive links the TD did not mention. All 56 target files confirmed present in `doc/refactoring/plans/archive/` (PowerShell `Test-Path` sweep: 0 missing). 1 link (TD255's own row, line 268) already uses the correct `../../../` form; ~14 root-relative links already resolve via root-relative fallback and are out of scope.
- **Scope Delta**: **Broader than original** — 56 broken links vs 52 named, and a second failure mode (missing `archive/` segment). Human approved **Option B**: fix all 56 broken links; leave the benign already-resolving root-relative links untouched (full normalization to one style was deferred as Option C).

### Root Cause (DA drift mechanism)
PF-IMP-873 (2026-05-26 archive-split) migrated resolved TD rows from the live tracker (`doc/state-tracking/permanent/technical-debt-tracking.md`) into the archive subdir (`…/permanent/archive/…`) via `Update-TechDebt.ps1`, which copies row text **verbatim** — including each row's relative PlanLink. Those links were correct one directory level up (live tracker) but became off-by-one in the deeper archive subdir. LinkWatcher did not recompute them because **no file moved** — only table rows migrated between two files (LinkWatcher recomputes relative links on file moves, not on row-level content migration). The 4 stale non-archive links predate the split: they referenced live plans that were later archived, and the file-move that archived those plans was never reflected in these particular rows. Underlying class: relative links embedded in migratable table rows are fragile to row migration between directories of differing depth. (Git history unavailable for corroboration — the archive file is currently untracked.)

### Refactoring Goals
- All 56 broken PlanLinks resolve to their archived plan files.
- Fixed links use the canonical relative form `../../../refactoring/plans/archive/<file>.md`, matching the single pre-existing correct sibling (TD255's row, line 268).
- Zero broken PlanLinks in the file after the change (verified by `Test-Path` sweep / LinkWatcher `--validate`).

## Current State Analysis

### Documentation Quality Baseline
- **Accuracy**: N/A — no code interfaces/behaviors involved (archival history doc).
- **Completeness**: N/A.
- **Cross-references**: 56 of ~70 resolved-item PlanLinks broken (off-by-one relative prefix and/or stale non-archive location). 1 link already correct (`../../../`, TD255 row). ~14 root-relative links already resolve via root-relative fallback.
- **Consistency**: 4 competing PlanLink prefix styles present in the file.

### Affected Documents
- `doc/state-tracking/permanent/archive/technical-debt-tracking-archive.md` — **only file modified**; rewrite 56 broken PlanLink prefixes to `../../../refactoring/plans/archive/`.

### Dependencies and Impact
- **Cross-references**: links target plan files in `doc/refactoring/plans/archive/` — all 56 targets confirmed present on disk.
- **State files**: TD258 row in the live tracker `technical-debt-tracking.md` (marked Resolved at L11). No other state files affected.
- **Risk Assessment**: **Low** — link-text edits in an archival history doc; no code, no behavior, no runtime impact. Reversible.

## Refactoring Strategy

### Approach
Two mechanical edit groups, both converging on the canonical `../../../refactoring/plans/archive/<file>.md` form (matching the pre-existing correct sibling, TD255 line 268). The ~14 already-resolving root-relative archive links are intentionally left untouched (Option B; normalize-all was deferred as Option C).

### Implementation Plan
1. **Phase 1 — Bulk prefix fix (52 links)**:
   - Step 1.1: Edit replace-all `](../../refactoring/plans/archive/` → `](../../../refactoring/plans/archive/` in the archive file. (Does not touch the 3-up correct sibling or any root-relative link — verified no substring collision.)

2. **Phase 2 — Stale link repair (4 links)**:
   - Step 2.1: Rewrite lines 242, 252, 255, 258 from `[/]doc/refactoring/plans/<file>.md` to `../../../refactoring/plans/archive/<file>.md` (adds the missing `archive/` segment and converts to the canonical relative prefix).

3. **Phase 3 — Verify**:
   - Step 3.1: PowerShell `Test-Path` sweep of every archive target referenced (expect 0 missing); residual count of broken `](../../refactoring/…` and stale `](doc/refactoring/plans/<file>.md)` forms = 0.

## Verification Approach
- **Link validation**: PowerShell `Test-Path` sweep extracting every `…/archive/<file>.md` target and confirming existence (expect 0 missing), plus a residual-pattern scan confirming 0 remaining `](../../refactoring/…` (2-up) and 0 remaining stale `](doc/refactoring/plans/<file>.md)` links. Optionally LinkWatcher `python main.py --validate`.
- **Content accuracy**: N/A — no code-derived content; only link path tokens change.
- **Consistency check**: confirm all 56 fixed links use the identical `../../../refactoring/plans/archive/` prefix, matching the pre-existing correct sibling (line 268).

> **L3/L4 exemptions**: Documentation-only change (only `technical-debt-tracking-archive.md` modified, no `.py`/code files) — test baseline (L3) and regression testing (L7) skipped; coverage assessment (L4) N/A.

## Success Criteria

### Documentation Quality Improvements
- **Accuracy**: N/A.
- **Completeness**: N/A.
- **Cross-references**: Zero broken PlanLinks in `technical-debt-tracking-archive.md`; all 56 fixed links use the canonical `../../../refactoring/plans/archive/` prefix.

### Documentation Integrity
<!-- Ensure no documentation regressions -->
- [x] All existing cross-references preserved or updated — 56 broken PlanLinks fixed; benign root-relative links preserved
- [x] No orphaned references created — all 73 archive references resolve to existing files
- [x] Terminology consistent with project conventions — 56 fixed links use the canonical `../../../` form matching the pre-existing correct siblings (TD255, TD257)
- [x] LinkWatcher confirms no broken links — PowerShell `Test-Path` sweep: 0 of 67 distinct archive targets missing; 0 remaining 2-up and 0 remaining stale non-archive forms

## Implementation Tracking

### Progress Log
<!-- Track progress during implementation -->
| Date | Phase | Completed Work | Issues Encountered | Next Steps |
|------|-------|----------------|-------------------|------------|
| 2026-06-04 | Phase 1 | Bulk replace-all `](../../refactoring/plans/archive/` → `](../../../…` (52 links) | None | Phase 2 |
| 2026-06-04 | Phase 2 | Repaired 4 stale non-archive links (TD224, TD241, TD231, TD244): added `archive/` segment + canonical prefix | None | Phase 3 |
| 2026-06-04 | Phase 3 | Verified: 0 broken 2-up, 0 stale non-archive, 0 of 67 archive targets missing, 58 canonical 3-up | Parallel session appended a resolved TD257 row mid-session (used correct prefix; out of scope) | Results + L10 checkpoint |

## Documentation & State Updates
<!-- Check each — for N/A, write brief justification (e.g., "Grepped TDD — no references to changed content") -->

> **Doc-only shortcut**: Per [code-refactoring-lightweight-path.md L8](../../tasks/06-maintenance/code-refactoring-lightweight-path.md), items 1–7 may be batched as N/A with a single justification: *"Documentation-only change — no behavioral code changes; design and state documents do not need updates for [description of change]."* Still check item 8 individually. Update items 1–7 individually only if a specific document requires changes (e.g., a TDD that documented affected file paths).

> **Items 1–7 batched N/A** (doc-only shortcut): *Documentation-only change — only PlanLink path tokens in `technical-debt-tracking-archive.md` were rewritten; no behavioral code changes, so feature state files, TDD, test spec, FDD, ADR, Integration Narratives, and validation tracking do not need updates.*

- [x] Feature implementation state file — N/A (doc-only, see batch note)
- [x] TDD — N/A (doc-only, see batch note)
- [x] Test spec — N/A (doc-only, see batch note)
- [x] FDD — N/A (doc-only, see batch note)
- [x] ADR — N/A (doc-only, see batch note)
- [x] Integration Narrative — N/A (doc-only, see batch note)
- [x] Validation tracking — N/A (doc-only, see batch note)
- [x] Technical Debt Tracking: TD258 marked Resolved via `Update-TechDebt.ps1` (moved to archive ## Resolved; PlanLink to PD-REF-233)

## Results

### Summary
- **56 broken PlanLinks fixed**: 52 cat-1 (`../../` → `../../../`, bulk replace-all) + 4 stale non-archive (TD224, TD241, TD231, TD244 — added `archive/` segment + canonical prefix).
- **Verification**: 0 remaining 2-up broken links, 0 remaining stale non-archive links, 0 of 67 distinct archive targets missing on disk (73 occurrences), 58 canonical 3-up links.

### Remaining Technical Debt
- **Style drift (intentional, out of scope per Option B)**: ~15 already-resolving root-relative PlanLinks (`/doc/refactoring/plans/archive/…` and `doc/refactoring/plans/archive/…`) remain un-normalized. They resolve correctly via root-relative fallback, so they are **not broken** — only inconsistent with the canonical `../../../` form. Normalizing all PlanLinks to one style was deferred as Option C; not currently tracked as new debt (Low value, no functional impact). Root-cause durability note: relative links in migratable table rows re-break on future row migrations between differing-depth directories; a root-anchored convention would be immune.

## Related Documentation
- [Technical Debt Tracking](../../../state-tracking/permanent/technical-debt-tracking.md)
