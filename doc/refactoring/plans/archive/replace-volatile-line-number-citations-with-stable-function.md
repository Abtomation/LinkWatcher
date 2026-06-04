---
id: PD-REF-232
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-06-04
updated: 2026-06-04
priority: Low
debt_item: TD257
refactoring_scope: Replace volatile line-number citations with stable function/section references in the Startup integration narrative
mode: documentation-only
target_area: Startup integration narrative (PD-INT-001)
---

# Documentation Refactoring Plan: Replace volatile line-number citations with stable function/section references in the Startup integration narrative

## Overview
- **Target Area**: Startup integration narrative (PD-INT-001)
- **Priority**: Low
- **Created**: 2026-06-04
- **Author**: AI Agent & Human Partner
- **Status**: Implementation complete — pending L11 state updates
- **Mode**: Documentation-only (no code changes, no test impact)
- **Debt Item**: TD257

## Refactoring Scope

The Startup integration narrative (`PD-INT-001`) cites absolute source line numbers throughout — both as markdown link display text plus `#LNNN` anchors (e.g. `[main.py:235](main.py#L235)`) and as bare prose (`(service.py:148-155)`, "begins at line 372"). These numbers drift on every edit to the cited source file. This refactor removes the drift *mechanism* (the line numbers themselves), replacing them with stable function/section references.

### Current Issues
- **Stale line numbers (verified against source 2026-06-04)**: All 7 `main.py` citations are off by +1 to +90 lines — `main()` cited `:235`, now at line 323; the config-validation `sys.exit(1)` cited `:348-353`, now line 440; `acquire_lock`'s exit cited `:205`, now line 285. The `src/linkwatcher` citations have also drifted — `logging.py` `setup_logging` cited `:565`, now 633; `service.py` `start`/`_initial_scan`/`_signal_handler` off by +4 to +8.
- **No automation maintains these numbers**: LinkWatcher updates link *paths* on file moves but does not track or update line anchors, so the drift is silent and unbounded.
- **Inconsistent citation style**: some links carry `#L` anchors, some prose carries bare numbers, and one link (`[handler.py](src/linkwatcher/handler.py)`) already has no number — there is no single convention.

### Scope Discovery
- **Original Tech Debt Description**: TD257 — scoped its examples to `main.py` line numbers (`:205`, `:235`, `:397`, `:348-353`), but its Notes state the root issue is "citing volatile line numbers in prose, not the specific stale values".
- **Actual Scope Findings**: The drift affects `main.py` **and** the `service.py`/`handler.py`/`logging.py`/`parser.py` citations across the whole file (~24 citations total). Two (`service.py:54`, `handler.py:234`) happen to still be correct but are equally volatile.
- **Scope Delta**: Broadened from `main.py`-only to **all** volatile line-number citations in the file (human-approved 2026-06-04). Fixing only `main.py` would leave a still-drifting document and re-open the same defect on the next `service.py`/`logging.py` edit, defeating TD257's stated goal ("so the narrative stops drifting on each code change").

### DA Root-Cause Trace
- **Originating artifact**: Narrative created 2026-04-22 by Integration Narrative Creation (PF-TSK-083); line numbers were captured as a point-in-time snapshot of then-current source.
- **Drift mechanism**: Absolute line numbers create an unenforced maintenance dependency on source files. Subsequent code edits — notably TD255 / PD-REF-230 inserting `_read_lock_owner_pid` (~29 lines) into `main.py`, plus refactors to `service.py` and `logging.py` — shifted actual line numbers with no corresponding narrative update. Git history is bulk-commit, so per-edit attribution is coarse, but the mechanism is structural, not a one-off oversight.
- **Primary deliverable (per DA guidance)**: Removing the drift mechanism so the narrative cannot drift on future code edits — not merely correcting the current stale values.

### Refactoring Goals
- Remove every absolute line-number citation (display `:NNN`, link `#LNNN` anchors, and bare-prose numbers) from the narrative.
- Where the enclosing function/method is not already named at the citation site, add a stable function/section reference so navigation precision is preserved.
- Leave link *path* targets unchanged (they resolve via LinkWatcher's project-root fallback) — strip only the volatile fragment.

## Current State Analysis

### Documentation Quality Baseline
- **Accuracy**: Function/behavior descriptions are accurate; only the line-number citations are stale. Stripping the numbers keeps the accurate function references.
- **Completeness**: All participating components are already documented — no completeness gap.
- **Cross-references**: Link path targets resolve (project-root fallback); the `#LNNN` fragments point to wrong lines but do not break the links.
- **Consistency**: Citation style is inconsistent (some links carry `#L` anchors, some prose carries bare numbers, one link already has none) — this refactor standardizes on "function name + bare file link".

### Affected Documents
- `doc/technical/integration/startup-integration-narrative.md` — strip ~24 line-number citations; add a function reference at the ~3 sites that lack one. **Sole file changed.**

### Dependencies and Impact
- **Cross-references**: None — no other document cites this narrative's line numbers.
- **State files**: Technical Debt Tracking (TD257 → Resolved). `PD-INT-001` has no feature-state dependency on the line numbers.
- **Risk Assessment**: Low — documentation-only, no path changes, no behavior/code/test impact. Worst case is a marginally less precise citation, mitigated by naming the enclosing function.

## Refactoring Strategy

### Approach
Single-pass in-place edit of the narrative. For each citation: delete the `:NNN` / `:NNN-MMM` from the display text and the `#LNNN` / `#LNNN-LMMM` fragment from the link target, preserving the file path. Where the citation site does not already name the enclosing function/method, insert a function reference. Finally, bump the narrative's `updated` date and `version`.

### Implementation Plan
1. **Phase 1 — Markdown-link citations**: Data Flow Sequence (steps 1-8), Callback/Event Chains, Configuration Propagation table, and Error Handling sections. Strip `:NNN` display text + `#LNNN` anchors; the function/method is already named at each of these sites.
   - Mapping examples: `[main.py:235](main.py#L235)` → `[main.py](main.py)`; `[src/linkwatcher/logging.py:565](src/linkwatcher/logging.py#L565)` → `[src/linkwatcher/logging.py](src/linkwatcher/logging.py)`.
2. **Phase 2 — Bare-prose citations + missing function names**:
   - Exit point `(service.py:148-155)` and `Monitor loop ... [service.py:148]` → reference the monitor loop in `LinkWatcherService.start` (the `while self.running` loop).
   - "release_lock() is inside the inner try/finally that begins at line 372" → "the inner `try/finally` around service construction in `main()`".
   - Configuration-Propagation `[service.py:127]` → `service.start`.
3. **Phase 3 — Finalize**: bump frontmatter `updated` → 2026-06-04 and `version` → 1.1.

## Verification Approach
- **Link validation**: grep the narrative for residual patterns `\.py:\d` (display numbers), `..#L\d` (anchors), and `\bline \d` (bare prose) → expect 0 hits. Link *path* targets are unchanged, so no link can break (LinkWatcher does not validate line anchors).
- **Content accuracy**: each retained reference names an actual function/method present in the cited file (verified against `main.py` and `src/linkwatcher/*.py` during analysis).
- **Consistency check**: all citations follow "function name (in prose/bold) + `[file](path)` link with no line fragment".

## Success Criteria

### Documentation Quality Improvements
- **Accuracy**: Narrative no longer cites stale absolute line numbers — citations now name the enclosing function/method, which cannot go stale on a code edit.
- **Completeness**: Unchanged — all participating components remain documented; function references preserve navigation precision.
- **Cross-references**: Zero residual line-number citations (`\.py:\d` / `..#L\d` / `line \d` → 0 hits); all 26 retained py-file links well-formed with paths intact.

### Documentation Integrity
- [x] All existing cross-references preserved or updated — link path targets unchanged; only volatile fragments stripped.
- [x] No orphaned references created — grep confirms no empty/malformed link targets.
- [x] Terminology consistent with project conventions — citations standardized on "function name + bare file link".
- [x] LinkWatcher confirms no broken links — link *paths* unchanged (fragment-only strip cannot break a path); LinkWatcher does not validate line anchors.

## Implementation Tracking

### Progress Log
<!-- Track progress during implementation -->
| Date | Phase | Completed Work | Issues Encountered | Next Steps |
|------|-------|----------------|-------------------|------------|
| 2026-06-04 | Analysis | Traced all ~24 citations against `main.py` + `src/linkwatcher/*.py`; confirmed all 7 `main.py` numbers stale (+1 to +90) and `service.py`/`logging.py`/`parser.py` numbers also drifting | None | — |
| 2026-06-04 | Implementation | Stripped `:NNN` display text + `#LNNN` anchors from 25 citation sites; added function references at the 4 sites lacking one (monitor loop ×2 → `LinkWatcherService.start`; "line 372" → inner `try/finally` in `main()`; config-table → `service.start`); bumped frontmatter `version` 1.0→1.1, `updated`→2026-06-04 | None | — |
| 2026-06-04 | Verification | Grep for `\.py:\d`, `..#L\d`, `line \d`, `:N-M)` → 0 hits; all 26 retained py-file links well-formed with paths intact, no empty targets | None | — |

> **L3 (Test Baseline)**: *Documentation-only change — test baseline skipped.*
> **L7 (Regression testing)**: *Documentation-only change — regression testing skipped.*

## Documentation & State Updates
<!-- Check each — for N/A, write brief justification (e.g., "Grepped TDD — no references to changed content") -->

> **Doc-only shortcut**: Per [code-refactoring-lightweight-path.md L8](../../tasks/06-maintenance/code-refactoring-lightweight-path.md), items 1–7 may be batched as N/A with a single justification: *"Documentation-only change — no behavioral code changes; design and state documents do not need updates for [description of change]."* Still check item 8 individually. Update items 1–7 individually only if a specific document requires changes (e.g., a TDD that documented affected file paths).

**Batched N/A (items 1–7), single justification**: *Documentation-only change confined to one narrative's own line-number citations — no behavioral code change, and no design/state document references those line numbers (the few inbound references cite the narrative by path/ID, which is unchanged). Verified by grepping the repo for `startup-integration-narrative` / `PD-INT-001`.*

- [x] N/A — Feature implementation state file: no feature state file references the narrative's line numbers (inbound refs are by path/ID).
- [x] N/A — TDD: no interface/design change; TDDs do not cite this narrative's line numbers.
- [x] N/A — Test spec: no behavior change.
- [x] N/A — FDD: no functional change.
- [x] N/A — ADR: no architectural decision affected.
- [x] N/A — Integration Narrative: the sibling `rapid-sequential-moves-integration-narrative.md` references this narrative only by path link (unaffected); no narrative cites the refactored line numbers.
- [x] N/A — Validation tracking: `validation-tracking-4.md` (WF-003 + DA dimension) status is "Ready for validation sessions" — no DA session run, no finding tied to TD257 or these line numbers; this standalone TD resolution doesn't alter the round's scope or recorded findings.
- [ ] Technical Debt Tracking: TD257 marked resolved — **deferred to L11 (after L10 approval)**.

## Results

### Remaining Technical Debt
- TD257 fully resolved by this refactor — no residual debt within scope.
- **Observation (out of scope, not filed)**: the sibling `rapid-sequential-moves-integration-narrative.md` carries the same defect pattern — one volatile citation `[service.py:76-94](src/linkwatcher/service.py#L76-L94)`. TD257 is scoped to the Startup narrative only, so this is recorded as an observation, not a follow-up action.

## Related Documentation
- [Technical Debt Tracking](../../../state-tracking/permanent/technical-debt-tracking.md)
