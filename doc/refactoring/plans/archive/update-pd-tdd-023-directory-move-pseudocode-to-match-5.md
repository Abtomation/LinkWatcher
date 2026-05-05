---
id: PD-REF-204
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-29
updated: 2026-04-29
priority: Medium
mode: documentation-only
debt_item: TD226
refactoring_scope: Update PD-TDD-023 directory-move pseudocode to match 5-phase batched pipeline (TD226)
feature_id: 1.1.1
target_area: doc/technical/tdd/tdd-1-1-1-file-system-monitoring-t2.md
---

# Documentation Refactoring Plan: Update PD-TDD-023 directory-move pseudocode to match 5-phase batched pipeline (TD226)

## Overview
- **Target Area**: doc/technical/tdd/tdd-1-1-1-file-system-monitoring-t2.md
- **Priority**: Medium
- **Created**: 2026-04-29
- **Author**: AI Agent & Human Partner
- **Status**: Planning
- **Mode**: Documentation-only (no code changes, no test impact)
- **Debt Item**: TD226
- **Status**: Completed

## Refactoring Scope

### Current Issues
- **Issue 1 — Phase 1 stale method call**: TDD pseudocode lines 312-315 show `self._ref_lookup.process_directory_file_move(old_path, new_path, co_moved_old_paths=...)` called per file in a loop. Actual `_handle_directory_moved` ([handler.py:447-466](/src/linkwatcher/handler.py#L447-L466)) calls `collect_directory_file_refs` per file to gather references, then `_batch_update_references` ([handler.py:469](/src/linkwatcher/handler.py#L469)) performs a single batched updater pass across all referring files (TD129), and `_cleanup_and_rescan_moved_files` ([handler.py:472](/src/linkwatcher/handler.py#L472)) does deduplicated bulk rescan (TD128). Method `process_directory_file_move` still exists in [reference_lookup.py:342](/src/linkwatcher/reference_lookup.py#L342) but is no longer called by the directory-move flow.
- **Issue 2 — Phase 0 missing**: Pseudocode omits the `link_db.update_source_path` pre-loop ([handler.py:444-445](/src/linkwatcher/handler.py#L444-L445)) that re-keys DB source paths from old to new locations *before* reference lookups run. This is a correctness fix for PD-BUG-050 (Errno 2 when updater opens moved files at their old paths).
- **Issue 3 — Phase 2 oversimplified**: Pseudocode lines 321-325 show a flat `find_directory_path_references` → `update_references` → `cleanup_after_directory_path_move` sequence using a single `(src_dir, dest_dir)` mapping. Actual `_update_directory_path_references` ([handler.py:603-662](/src/linkwatcher/handler.py#L603-L662)) groups references by `link_target` and computes per-target `(ref_old, ref_new)` mappings via prefix replacement to correctly handle exact-match, subdirectory-match (`old_dir/assessments`), and backslash-variant cases.
- **Issue 4 — Phase 1.5 mislabeled and broken reference**: Pseudocode line 317 labels `_update_links_within_moved_file` as "Phase 1b" but actual code labels it "Phase 1.5" ([handler.py:474-485](/src/linkwatcher/handler.py#L474-L485)). Pseudocode line 319 references `abs_new` (not defined in the pseudocode block — defined in actual code at line 481).
- **Issue 5 — Phase numbering mismatch**: Actual code has Phases 0, 1, 1b, 1c, 1.5, 2 (six phase labels for what TD226 calls a "5-phase batched pipeline"). Current pseudocode has Phases 1, 1b, 2.

### Scope Discovery
- **Original Tech Debt Description (TD226)**: TDD directory-move pseudocode shows a 3-phase per-file pipeline (`process_directory_file_move` + `find_directory_path_references` + `find_parent_directory_references`); actual code is a 5-phase batched pipeline (Phase 0/1/1b/1c/1.5/2) introduced by TD128+TD129.
- **Actual Scope Findings**:
  - Core claim confirmed: pseudocode is structurally stale; actual code has Phase 0 (source-path re-key), batched Phase 1 collect → Phase 1b update → Phase 1c cleanup pipeline, Phase 1.5 inside-file links, Phase 2 link_target-grouped dir-path refs.
  - **Inaccuracy in TD226's description**: `find_parent_directory_references` was already removed from the pseudocode by PD-REF-198 (TD228, archived 2026-04-28) — replaced with a Note (lines 327-332) explaining parent/ancestor refs are unaffected by subdirectory moves. This was completed AFTER TD226 was filed (2026-04-22), so TD226's "3 calls" reference is historically accurate but no longer reflects the file's current state.
  - **Inaccuracy in TD226's "5-phase" count**: actual code uses six phase labels (0, 1, 1b, 1c, 1.5, 2). TD226's description enumerates them but calls it "5-phase" — minor labeling mismatch, not a substantive error.
- **Scope Delta**: TD226 also implicitly requested `find_parent_directory_references` be removed; PD-REF-198 already did that. This refactoring addresses only the remaining structural drift (Issues 1-5 above).

### Drift Root-Cause Trace (DA category)
- **Originating refactors**:
  - **TD128** (`Deduplicate affected-file rescans during directory moves`, [PD-REF-125](deduplicate-affected-file-rescans-during-directory-moves.md), 2026-03-30) — added the `deferred_rescan_files` set and bulk-rescan loop, transforming Phase 1's tail into what is now Phase 1c.
  - **TD129** (`Batch file writes during directory moves to avoid redundant I/O`, [PD-REF-126](batch-file-writes-during-directory-moves-to-avoid-redundant-i-o.md), 2026-03-30) — introduced `_batch_update_references` and `_cleanup_and_rescan_moved_files` helpers, replacing per-file `process_directory_file_move` calls with the Phase 1 / 1b / 1c collect-update-cleanup split.
  - **PD-BUG-050 fix** (Phase 0 source-path re-key) and **PD-BUG-091 fix** (Phase 1.5 propagation accounting) were applied earlier and remained undocumented in the pseudocode.
- **Drift mechanism**: TD129's plan ([PD-REF-126:29-32](batch-file-writes-during-directory-moves-to-avoid-redundant-i-o.md)) explicitly noted Phase 0 was already a separate pre-loop and that Phase 1c bulk rescan was already in place (from TD128). However, both TD128's and TD129's "Documentation & State Updates" checklists treated PD-TDD-023 as N/A or focused only on the prose narrative — the *Section 4.3 illustrative pseudocode block* was not re-synthesized after either refactor. This is the **same drift pattern as TD220 file-move pseudocode** ([PD-REF-195](update-pd-tdd-023-section-4-3-file-move-pseudocode-to.md)): prose edits naming new helpers were applied where present, but pseudocode rewriting — which requires manual regeneration of the method-call sequence — was missed.
- **Detection lag**: ~3.5 weeks (2026-03-30 TD128/TD129 → 2026-04-22 TD226 filed), surfaced during PF-TSK-083 Integration Narrative creation for WF-002 (PD-INT-006) when reviewing the directory-move flow.
- **Pattern**: Three TDs (TD220, TD228, TD226) all flagged drift in PD-TDD-023's directory/file-move pseudocode within ~3 weeks. The TDD's "Source: reverse-engineered from source code analysis" note (line 17) makes this section especially vulnerable to staleness when the implementation evolves. Process improvement opportunity logged separately if a pattern persists.

### Design Decision: Phase Granularity
PD-REF-198 (TD228) made a **side comment** ([PD-REF-198:56](remove-non-existent-phase-3-find-parent-directory.md)): "keep pseudocode at high-level (0/1/2) for readability; do not enumerate 1b/1c/1.5 in the TDD — those are batching-implementation details." That comment was **not enforced** — the current pseudocode still has a Phase 1b (line 317). Three options for resolution:

- **Option A (faithful to actual code)**: Pseudocode mirrors handler.py phase labels exactly (0, 1, 1b, 1c, 1.5, 2). Advantages: zero drift between code comments and TDD; clear traceability for future readers debugging the pipeline. Disadvantages: longer pseudocode block; exposes batching internals as if they were architecturally significant.
- **Option B (high-level only, supersede PD-REF-198's stated intent)**: Pseudocode shows Phase 0, Phase 1 (single block: "collect, batch-update, cleanup"), Phase 1.5, Phase 2. Advantages: matches PD-REF-198's design intent; abstracts performance details. Disadvantages: requires the reader to dig into the code to understand the batching structure; loses the per-phase comment provenance.
- **Option C (hybrid)**: Phase 0 / Phase 1 / Phase 1.5 / Phase 2 as the conceptual outline, with a brief in-pseudocode note that "Phase 1 is implemented as collect (1) → batch-update (1b) → cleanup with deferred rescan (1c) — see handler.py for details."

**Recommendation: Option C.** Captures correctness invariants (Phase 0 source-path re-key, Phase 1.5 outward-link updates, Phase 2 link_target grouping) at the level of detail readers need, while pointing to the implementation for batching specifics. Honors PD-REF-198's high-level intent without losing the TD128/TD129 attribution.

### Refactoring Goals
- **Goal 1**: Pseudocode signature matches actual: `_handle_directory_moved(self, event: FileMovedEvent)` (current shows `(self, src_dir: str, dest_dir: str)` — wrong since `_handle_directory_moved` always takes a `FileMovedEvent`, with synthetic events constructed at handler.py:740 for the dir-move-detector path).
- **Goal 2**: Add Phase 0 source-path re-key with PD-BUG-050 attribution.
- **Goal 3**: Replace per-file `process_directory_file_move` loop with the actual batched Phase 1 (collect → batch-update → cleanup), using Option C hybrid: outline as Phase 1 with TD128/TD129 attribution and `_batch_update_references` / `_cleanup_and_rescan_moved_files` references.
- **Goal 4**: Relabel Phase 1b → Phase 1.5 to match handler.py code comments, fix the `abs_new` undefined-variable issue.
- **Goal 5**: Update Phase 2 to reflect link_target grouping with prefix replacement (delegated to `_update_directory_path_references`); preserve the parent/ancestor Note added by PD-REF-198.
- **Goal 6**: Statistics update reflects actual `_update_stat` helper (consistency with how the file-move pseudocode was updated by PD-REF-195).

## Current State Analysis

### Documentation Quality Baseline
- **Accuracy**: Section 4.3 directory-move pseudocode is **inaccurate** — Phase 1 calls a method no longer used by this code path; Phase 0 is missing entirely; Phase 2 hides correctness-relevant link_target grouping.
- **Completeness**: Pseudocode is incomplete — omits Phase 0 (PD-BUG-050 fix) and the structural reality of TD128/TD129 batching.
- **Cross-references**: Cross-references in the TDD remain valid (no link changes needed for this fix).
- **Consistency**: Inconsistent — Section 4.3 directory-move pseudocode uses Phase 1/1b/2 while the file-move pseudocode (just above, lines 230-291, recently updated by PD-REF-195) reflects current code accurately. Sibling pseudocode blocks should match in fidelity.

### Affected Documents
- `doc/technical/tdd/tdd-1-1-1-file-system-monitoring-t2.md`:
  - Lines 293-333 — rewrite directory-move pseudocode block; preserve parent/ancestor Note from PD-REF-198 (relabel Phase 1b → Phase 1.5 to match handler.py).
  - Line 507 — fix Section 6 item 8 prose (bundled at L6 after human partner approval): drop false `co_moved_old_paths` claim, drop misleading PD-BUG-038 attribution (closed cannot-reproduce per [bug-tracking.md:177](/doc/state-tracking/permanent/bug-tracking.md)), correct method-name list, add TD128/TD129 attribution.

### Dependencies and Impact
- **Cross-references**:
  - [doc/state-tracking/features/1.1.1-file-system-monitoring-implementation-state.md](/doc/state-tracking/features/1.1.1-file-system-monitoring-implementation-state.md) references this TDD; no inline pseudocode duplication detected (verified via grep for `process_directory_file_move` in the state file → 0 hits).
  - [doc/technical/integration/directory-move-integration-narrative.md](/doc/technical/integration/directory-move-integration-narrative.md) (PD-INT-006) references this TDD; narrative describes the pipeline at a higher abstraction level, no pseudocode-level updates needed (verified via read — narrative describes "5 phases" generically without per-method-call detail).
- **State files**: No state-file updates needed (drift is contained to the TDD pseudocode block).
- **Risk Assessment**: Low — Documentation-only change; no code, no tests, no public interface affected.

## Refactoring Strategy

### Approach
Replace the pseudocode block at lines 293-333 with an Option C hybrid rewrite that:
1. Adds Phase 0 with PD-BUG-050 attribution.
2. Restructures Phase 1 to show the collect → batch-update → cleanup outline with TD128/TD129 attribution comments and references to `_batch_update_references` / `_cleanup_and_rescan_moved_files` helpers.
3. Relabels Phase 1.5 (formerly Phase 1b in pseudocode) and fixes the `abs_new` undefined-variable issue.
4. Updates Phase 2 to delegate to `_update_directory_path_references` with a brief note on link_target grouping.
5. Preserves the parent/ancestor Note from PD-REF-198.

### Implementation Plan
1. **Phase 1 — Rewrite pseudocode block**:
   - Step 1.1: Replace lines 293-333 with new pseudocode block per Goals 1-6.
   - Step 1.2: Verify final block reads cleanly and matches handler.py phase comments.
2. **Phase 2 — Verification**:
   - Step 2.1: Re-grep TDD for any remaining references to `process_directory_file_move`, `find_parent_directory_references` to confirm full sweep.
   - Step 2.2: LinkWatcher confirms no broken links (passive — runs in background).
   - Step 2.3: Diff against handler.py phase comments to confirm fidelity.

## Verification Approach
- **Link validation**: LinkWatcher running in background (passive); manual grep for stale method names post-edit.
- **Content accuracy**: Side-by-side compare new pseudocode vs. handler.py:409-512 phase structure and comments.
- **Consistency check**: Verify the rewritten directory-move block has the same level of fidelity as the file-move block above it (both updated post-PD-REF-195).

## Success Criteria

### Documentation Quality Improvements
- **Accuracy**: All pseudocode method calls correspond to methods invoked by actual `_handle_directory_moved` in handler.py.
- **Completeness**: Phase 0 (PD-BUG-050), Phase 1 batching outline (TD128/TD129), Phase 1.5 (PD-BUG-039), Phase 2 link_target grouping all represented.
- **Cross-references**: Zero broken links in affected documents (LinkWatcher reports clean).

### Documentation Integrity
- [x] All existing cross-references preserved or updated — verified via grep
- [x] No orphaned references created — `process_directory_file_move`, `find_parent_directory_references`, `co_moved_old_paths` all absent from updated TDD
- [x] Terminology consistent with project conventions (Phase numbering matches handler.py code comments) — Phase 0/1/1.5/2 outline with batched Phase 1 callout to handler.py phases 1b/1c
- [x] LinkWatcher confirms no broken links (running in background; passive validation)

## Documentation & State Updates Checklist (Lightweight Path L8)

Documentation-only shortcut applies for items 1–7 except where verification surfaced a concrete artifact to check. Per the path's instruction, each batched N/A still requires a justification.

1. **Feature implementation state file** — N/A. State file [1.1.1-file-system-monitoring-implementation-state.md](/doc/state-tracking/features/1.1.1-file-system-monitoring-implementation-state.md) has historical session-log entries at lines 120, 143-144, 369 describing the original (now-reverted) `co_moved_old_paths` and `find_parent_directory_references` work as completed-at-the-time records. Following PD-REF-198's explicit precedent ("state-file drift is out of scope (separate DA item if needed)") for the same TDD section, these chronological history rows are left unchanged — they accurately record what those sessions did, regardless of subsequent removal. Out-of-scope observation only; no follow-up TD filed.
2. **TDD updated** — ✅ This IS the change. PD-TDD-023 updates: pseudocode block (lines 293-363) and Section 6 item 8 prose (line 507).
3. **Test spec updated** — N/A. No feature-specific test spec exists for 1.1.1 (verified via Glob `test/specifications/**/*1.1.1*` → 0 matches).
4. **FDD updated** — N/A. [fdd-1-1-1-file-system-monitoring.md](/doc/functional-design/fdds/fdd-1-1-1-file-system-monitoring.md) exists but contains zero references to any of the implementation-level method names changed (verified via grep). FDDs describe functional requirements, not implementation phases.
5. **ADR updated** — N/A. Verified via grep across all 3 ADRs in `doc/technical/adr/` — zero matches for any changed method name.
6. **Integration Narrative updated** — N/A. [directory-move-integration-narrative.md](/doc/technical/integration/directory-move-integration-narrative.md) (PD-INT-006, the narrative whose creation surfaced TD226) already correctly references the "6-phase pipeline" with all current method names (`collect_directory_file_refs`, `_handle_directory_moved`, etc.). No drift.
7. **Validation tracking updated** — N/A. Active validation-tracking-3.md correctly describes "6 non-sequential phases (0/1/1b/1c/1.5/2)" at line 184; validation-tracking-4.md has zero matches. Validation reports under `doc/validation/reports/` are point-in-time snapshots and not modified.
8. **Technical Debt Tracking** — TD226 to be marked Resolved at L10 via `Update-TechDebt.ps1`.

## Implementation Tracking

### Progress Log
| Date | Phase | Completed Work | Issues Encountered | Next Steps |
|------|-------|----------------|-------------------|------------|
| 2026-04-29 | Plan | TD226 verified against handler.py:409-512; prior plans PD-REF-195/198 reviewed; Option C rewrite strategy chosen | None | Await L5 checkpoint approval, then execute rewrite |
| 2026-04-29 | L5 checkpoint | Plan approved with Option C (hybrid phase granularity) | None | Execute rewrite |
| 2026-04-29 | L6 implement | Rewrote directory-move pseudocode block (lines 293-333) with Phase 0 (PD-BUG-050), Phase 1 batched outline (TD128/TD129), Phase 1.5 (PD-BUG-039), Phase 2 link_target grouping; updated parent/ancestor Note to reference Phase 1.5; fixed signature `(self, event: FileMovedEvent)`; resolved undefined `abs_new` reference | During verification grep, found stale prose claim at line 507 (Section 6 item 8) referencing the obsolete `co_moved_old_paths` mechanism and PD-BUG-038 attribution | Surface to human partner for scope decision |
| 2026-04-29 | L6 scope expansion | Human partner approved bundling. Updated line 507 prose: dropped false `co_moved_old_paths` claim, dropped misleading PD-BUG-038 attribution (bug closed as cannot-reproduce per bug-tracking.md:177), corrected method-name list to reflect actual file-move (`find_references` + `get_old_path_variations`) vs directory-move (`collect_directory_file_refs` wrapper) split, added TD128/TD129 attribution | None | Verification pass |
| 2026-04-29 | L6 verify | Grep confirmed zero remaining occurrences of `process_directory_file_move`, `find_parent_directory_references`, `co_moved_old_paths`, "co-moved files" in TDD | None | Complete L8/L9/L10 |

## Results

### Results Summary
- **Files modified**: 1 — `doc/technical/tdd/tdd-1-1-1-file-system-monitoring-t2.md`
- **Pseudocode block**: lines 293-333 → 293-363 (added 30 lines: signature fix, Phase 0, batched Phase 1 outline with TD128/TD129 attribution, Phase 1.5 relabel + abs_new fix, Phase 2 link_target grouping, parent/ancestor Note relabel)
- **Prose fix**: line 507 (Section 6 item 8 "Unified DB update strategy") rewritten — drop false `co_moved_old_paths`/PD-BUG-038 claim, correct method-name list, add TD128/TD129 attribution
- **Stale references eliminated**: 3 — `process_directory_file_move`, `find_parent_directory_references`, `co_moved_old_paths` (verified zero matches in TDD post-edit)
- **Bug fixed in pseudocode**: undefined variable `abs_new` at original line 319 — now correctly defined inline before use
- **Tests**: not applicable (documentation-only)
- **Test baseline**: skipped (documentation-only exemption per Lightweight Path L3)
- **Regression testing**: skipped (documentation-only exemption per Lightweight Path L7)
- **Bugs discovered**: none

### Remaining Technical Debt
- None from this refactor. Out-of-scope observations:
  - State-file historical entries at [1.1.1 state file](/doc/state-tracking/features/1.1.1-file-system-monitoring-implementation-state.md) lines 120/143-144/369 describe reverted work (`co_moved_old_paths`, `find_parent_directory_references`). Following PD-REF-198 precedent, these are treated as session-log history not living state. No new TD filed.
  - **Pattern signal**: TD220 (file-move pseudocode), TD228 (Phase 3 removal), and TD226 (directory-move pseudocode) all addressed Section 4.3 drift in PD-TDD-023 within ~3 weeks. The TDD's "reverse-engineered from source" provenance (line 17) makes Section 4.3 drift-prone whenever handler.py is refactored. If a fourth such TD surfaces against this section, consider filing a process improvement to add an explicit "verify Section 4.3 pseudocode against handler.py phase comments" step to the Code Refactoring task's Documentation & State Updates checklist for changes to file-system-monitoring code.

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
- [PD-REF-195: TD220 file-move pseudocode update](update-pd-tdd-023-section-4-3-file-move-pseudocode-to.md) — sibling refactor (parallel pattern)
- [PD-REF-198: TD228 Phase 3 removal](remove-non-existent-phase-3-find-parent-directory.md) — same TDD section, prior fix
- [PD-REF-125: TD128 deduplicate rescans](deduplicate-affected-file-rescans-during-directory-moves.md) — originating refactor
- [PD-REF-126: TD129 batch file writes](batch-file-writes-during-directory-moves-to-avoid-redundant-i-o.md) — originating refactor
