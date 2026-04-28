---
id: PD-REF-195
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-28
updated: 2026-04-28
mode: documentation-only
debt_item: TD220
target_area: doc/technical/tdd/tdd-1-1-1-file-system-monitoring-t2.md
feature_id: 1.1.1
priority: Medium
refactoring_scope: Update PD-TDD-023 Section 4.3 file-move pseudocode to reflect post-TD022 ReferenceLookup delegation (TD220)
---

# Documentation Refactoring Plan: Update PD-TDD-023 Section 4.3 file-move pseudocode to reflect post-TD022 ReferenceLookup delegation (TD220)

## Overview
- **Target Area**: doc/technical/tdd/tdd-1-1-1-file-system-monitoring-t2.md
- **Priority**: Medium
- **Created**: 2026-04-28
- **Author**: AI Agent & Human Partner
- **Status**: Planning
- **Mode**: Documentation-only (no code changes, no test impact)
- **Debt Item**: TD220

## Refactoring Scope

### Current Issues
- TDD Section 4.3 file-move pseudocode (lines 252-272) shows direct `self.link_db.get_references_to_file`, `self.parser.parse_file`, `self.link_db.remove_file_links`, and `self.link_db.add_link` calls.
- Actual `_handle_file_moved` ([handler.py:336-407](/src/linkwatcher/handler.py)) delegates via `self._ref_lookup.*` since TD022 (2026-03-03).
- Pseudocode signature `(self, src_path: str, dest_path: str)` no longer matches actual `(self, event: FileMovedEvent)`.
- Pseudocode is missing post-TD022 steps: `get_old_path_variations` (path-format capture before DB mutation) and `retry_stale_references` (stale line-number retry).
- Pseudocode shows an inline rescan loop (`remove_file_links` + `parse_file` + `add_link`) but actual code uses `cleanup_after_file_move` plus `_update_links_within_moved_file` (the latter handles within-file content updates AND DB updates for the moved file's own entries).

### Scope Discovery
- **Original Tech Debt Description**: TDD PD-TDD-023 Section 4.3 pseudocode for `_handle_file_moved` shows stale direct calls (`link_db.get_references_to_file`, `parser.parse_file`, `link_db.remove_file_links`, `link_db.add_link`) that no longer match handler.py after TD022 refactor — handler now delegates all reference lookup and DB management to `ReferenceLookup` (`self._ref_lookup`). Update the TDD pseudocode to reflect the post-TD022 architecture.
- **Actual Scope Findings**: Confirmed accurate. TDD prose at lines 28, 29, 95, 134, 446, 452, 460-462 already documents post-TD022 architecture correctly; only the Section 4.3 file-move pseudocode block (lines 252-272) is out of date.
- **Scope Delta**: None — scope matches original description.

### Drift Root Cause Analysis (DA category)
- **Originating refactor**: TD022 ReferenceLookup extraction (refactoring plan archived as [extract-reference-lookup-from-handler-py-into-reference-lookup-py-td022.md](/doc/refactoring/plans/archive/extract-reference-lookup-from-handler-py-into-reference-lookup-py-td022.md), 2026-03-03).
- **Drift mechanism**: TD022 updated TDD *descriptive prose* to reference `_ref_lookup` delegation (lines 28, 29, 95, 134-135, 446, 452, 460-462) but the Section 4.3 *illustrative pseudocode block* was not re-synthesized after the implementation change. Prose edits naming the new delegation pattern were applied; pseudocode rewriting — which requires manual regeneration of the method-call sequence and step structure — was missed.
- **Detection lag**: ~7 weeks (2026-03-03 → 2026-04-22), surfaced during PF-TSK-083 Integration Narrative creation for WF-001 (PD-INT-002) when reviewing the file-move flow.
- **Out-of-scope observation (not bundled)**: TD226 covers the directory-move pipeline pseudocode in the same Section 4.3 (lines 274-316), drifted via TD128/TD129 (5-phase batched pipeline). Same root-cause pattern — separately tracked, not addressed here.

### Refactoring Goals
- Pseudocode signature matches actual: `_handle_file_moved(self, event: FileMovedEvent)`.
- Step sequence reflects post-TD022 method calls: `find_references` → `get_old_path_variations` → `update_references` → `retry_stale_references` → `cleanup_after_file_move` → `_update_links_within_moved_file`.
- Comments preserve key invariants (TD022 ReferenceLookup delegation, PD-BUG-025 single-read pattern, capture-old-targets-before-mutation ordering).
- Statistics update reflects actual `_update_stat` helper rather than the obsolete direct `self.stats[...]` mutation.

## Current State Analysis

### Documentation Quality Baseline
- **Accuracy**: Section 4.3 file-move pseudocode is **inaccurate** — uses obsolete `link_db.*` and `parser.parse_file` direct calls. Surrounding prose is accurate and references TD022 delegation correctly.
- **Completeness**: Pseudocode is incomplete — omits `get_old_path_variations`, `retry_stale_references`, and `_update_links_within_moved_file` steps that exist in the actual handler.
- **Cross-references**: Cross-references in the TDD are valid (no link changes needed for this fix).
- **Consistency**: Inconsistent — Section 4.3 pseudocode contradicts the surrounding prose in the same TDD (which describes ReferenceLookup delegation correctly).

### Affected Documents
- `doc/technical/tdd/tdd-1-1-1-file-system-monitoring-t2.md` — Section 4.3 file-move pseudocode block (lines 252-272) replaced with post-TD022 pseudocode that mirrors actual handler.py:336-407.

### Dependencies and Impact
- **Cross-references**: Integration Narrative PD-INT-002 (WF-001) references this TDD section — no edits required there since the prose change is internal to the pseudocode block.
- **State files**: None require updates (documentation-only change, no behavior or interface changes).
- **Risk Assessment**: **Low** — text-only edit to a single illustrative code block; no runtime impact, no test impact, no API surface change.

## Refactoring Strategy

### Approach
Replace the pseudocode block in Section 4.3 (lines 252-272) with a faithful reduction of the actual `_handle_file_moved` (handler.py:336-407). Preserve illustrative comments; surface invariants (TD022 delegation, capture-before-mutation ordering, PD-BUG-025 single-read pattern). No edits to surrounding prose, headings, or other pseudocode blocks (the directory pipeline at lines 274-316 is owned by TD226).

### Proposed Pseudocode (replacement for lines 252-272)

```python
def _handle_file_moved(self, event: FileMovedEvent):
    # Step 1: Resolve relative paths from event
    old_path = self._get_relative_path(event.src_path)
    new_path = self._get_relative_path(event.dest_path)
    if not old_path or not new_path:
        return

    # Step 2: Look up references via ReferenceLookup (TD022 delegation)
    # Uses path-format variations (raw, abs, with/without ./ prefix)
    references = self._ref_lookup.find_references(old_path)

    if references:
        # Step 3: Capture old path variations BEFORE any mutation
        # — required for correct DB cleanup since updates mutate the DB
        old_targets = self._ref_lookup.get_old_path_variations(old_path)

        # Step 4: Update files first (before modifying the DB)
        update_stats = self.updater.update_references(references, old_path, new_path)

        # Step 5: Retry references with stale line numbers
        # (rescans affected files and retries once — TD009 dedup)
        self._ref_lookup.retry_stale_references(old_path, new_path, update_stats)

        # Step 6: Remove old DB entries and rescan affected files
        # moved_file_path skips the moved file — handled by Step 7
        self._ref_lookup.cleanup_after_file_move(
            references, old_targets, moved_file_path=old_path
        )

        self._update_stat("links_updated", update_stats["references_updated"])
        self._update_stat("errors", update_stats["errors"])

    # Step 7: Update links WITHIN the moved file (PD-BUG-025 single-read pattern)
    # Handles content updates AND DB updates for the moved file's own entries
    if self._should_monitor_file(event.dest_path):
        self._update_links_within_moved_file(old_path, new_path, event.dest_path)

    self._update_stat("files_moved")
```

### Implementation Plan
1. **Phase 1**: Replace lines 252-272 with the proposed pseudocode block above. Keep the surrounding "**File move pipeline** (`_handle_file_moved`):" header line unchanged.
2. **Phase 2**: Verify the directory move pipeline pseudocode (lines 274-316) and Section 4.4 prose are not unintentionally touched by the edit.

## Verification Approach
- **Content accuracy**: Manual line-by-line comparison of new pseudocode against handler.py:336-407 and the `_ref_lookup.*` API in `src/linkwatcher/reference_lookup.py`.
- **Link validation**: LinkWatcher running in background; no link targets change.
- **Consistency check**: Confirm method names match actual `ReferenceLookup` public methods; confirm TDD prose at lines 28, 29, 95, 134, 446, 452, 460-462 remains consistent with the new pseudocode (it already is — that's the whole point of the fix).

## Success Criteria

### Documentation Quality Improvements
- **Accuracy**: Section 4.3 file-move pseudocode matches the actual `_handle_file_moved` implementation in handler.py:336-407 (signature, method calls, step ordering).
- **Completeness**: All post-TD022 steps are represented — `find_references`, `get_old_path_variations`, `retry_stale_references`, `cleanup_after_file_move`, `_update_links_within_moved_file`.
- **Cross-references**: No broken links introduced (no link targets changed; LinkWatcher passive).

### Documentation Integrity
- [x] All existing cross-references preserved or updated — no link targets changed.
- [x] No orphaned references created — no removed identifiers.
- [x] Terminology consistent with project conventions — uses TD022/PD-BUG-025/TD009 references already established in surrounding TDD prose.
- [x] LinkWatcher confirms no broken links — no link targets changed; LinkWatcher running in background.

## Documentation & State Updates Checklist (Lightweight Path L8)

Per the **Documentation-only shortcut** (lightweight-path.md L8): items 1–7 below are batched as N/A with a single justification. Item 8 (tech debt) is handled individually.

**Justification for batching items 1–7 as N/A**: Documentation-only change — TDD pseudocode block replaced with post-TD022 pseudocode. No behavioral code changes; the changed file IS a design document, and no downstream design/state documents reference the pseudocode block. Surrounding TDD prose at lines 28, 29, 95, 134-135, 446, 452, 460-462 already correctly describes the post-TD022 architecture and required no update.

1. Feature implementation state file updated, or N/A — **N/A** (per shortcut)
2. TDD updated, or N/A — **Updated** (this refactoring's deliverable; the TDD is the target)
3. Test spec updated, or N/A — **N/A** (per shortcut)
4. FDD updated, or N/A — **N/A** (per shortcut)
5. ADR updated, or N/A — **N/A** (per shortcut)
6. Integration Narrative updated, or N/A — **N/A** (per shortcut; PD-INT-002 references the TDD section but only via a link, not the pseudocode contents)
7. Validation tracking updated, or N/A — **N/A** (per shortcut)
8. Technical Debt Tracking: TD220 marked **Resolved** via `Update-TechDebt.ps1` — see L10 below.

## Implementation Tracking

### Progress Log
| Date | Phase | Completed Work | Issues Encountered | Next Steps |
|------|-------|----------------|-------------------|------------|
| 2026-04-28 | Verification | Confirmed TDD Section 4.3 pseudocode drift via line-by-line comparison with handler.py:336-407; traced drift origin to TD022 (2026-03-03); 7-week detection lag | None | Proceed to plan creation |
| 2026-04-28 | Plan creation | PD-REF-195 created with `-DocumentationOnly` mode | None | L5 checkpoint |
| 2026-04-28 | L5 checkpoint | Plan + proposed pseudocode presented to human partner | None | Human approved → implement |
| 2026-04-28 | L6 implementation | Replaced lines 252-272 in tdd-1-1-1-file-system-monitoring-t2.md with post-TD022 pseudocode; verified via re-read that surrounding directory pipeline (lines 274-316) and Section 4.4 prose were untouched | None | L8/L9/L10 finalization |

## Results

### Results Summary

| Metric | Value |
|---|---|
| Files modified | 1 (`doc/technical/tdd/tdd-1-1-1-file-system-monitoring-t2.md`) |
| Lines changed | -21 / +37 (net +16, including added comments for clarity) |
| Tests run | N/A (documentation-only — exempted from L3/L7) |
| Test regressions | N/A |
| Bugs discovered | PF-IMP-620 — Update-TechDebt.ps1 -PlanLink overwrites column 0 (TD ID) in Recently Resolved row instead of preserving the ID and storing the plan reference separately or in Notes. Required manual ID-column repair in technical-debt-tracking.md after the Resolve operation. Same silent-success anti-pattern as TD223/TD224. Bash MSYS path mangling on Windows (POSIX `/...` paths get `C:/Program Files/Git/` prepended) compounded the visible corruption but is a known caller-side hazard, not a project bug. |
| Tech debt items resolved | TD220 |
| Out-of-scope observations | TD226 (directory move pipeline pseudocode also stale, separately tracked); minor prose staleness in Section 4.4 line 402 ("delegated to `link_db`, `updater`, `parser`" omits `_ref_lookup`) — not addressed |

### Remaining Technical Debt
- **TD226** (Medium) — Directory move pipeline pseudocode (Section 4.3, lines 274-316 → now 293-335 after this edit) shows 3-phase per-file pipeline but actual implementation is a 5-phase batched pipeline (TD128/TD129). Same drift pattern; separately tracked.
- **Minor prose staleness** (not yet a TD item): Section 4.4 line 402 "All event handler methods return quickly — heavy processing delegated to `link_db`, `updater`, `parser`" omits `_ref_lookup`. Suggest filing as a separate TD if discovered repeatedly during future TDD reviews.

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)

