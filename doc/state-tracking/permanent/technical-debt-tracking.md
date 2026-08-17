---
id: PF-FST-005
description: "Registry of technical debt items with priority, status, and remediation tracking."
type: Process Framework
category: State Tracking
version: 1.2
created: 2025-06-15
updated: 2026-08-17
---

# Technical Debt Tracker

This document tracks technical debt. As a solo developer, it's important to be intentional about technical debt - sometimes taking shortcuts is necessary to make progress, but these should be documented and addressed later.

## What is Technical Debt?

Technical debt refers to the implied cost of future rework caused by choosing an easy or quick solution now instead of a better approach that would take longer. It's not inherently bad, but it should be managed.

## Technical Debt Dimensions

Technical debt items are tagged with **Primary Dimension** using the standard abbreviations from the [Development Dimensions Guide](/process-framework/guides/framework/development-dimensions-guide.md), plus **TST** (Testing) and **AIC** (AI Agent Continuity) for non-dimension debt.

**Valid values**: AC, CQ, ID, DA, EM, SE, PE, OB, UX, DI, TST, AIC

> **Note**: Resolved items (in the collapsed section below) retain their legacy Category names for historical accuracy.

## Priority Levels

- **Critical**: Must be addressed before the next release
- **High**: Should be addressed in the next development cycle
- **Medium**: Should be addressed when convenient
- **Low**: Nice to fix, but not urgent

## Technical Debt Registry

| ID    | Description                                                | Dims        | Location                                                                     | Created Date | Priority | Estimated Effort | Status      | Resolution Date | Assessment ID | Workflows | Notes                                                                                                |
| ----- | ---------------------------------------------------------- | ----------- | ---------------------------------------------------------------------------- | ------------ | -------- | ---------------- | ----------- | --------------- | ------------- | --------- | ---------------------------------------------------------------------------------------------------- |
| TD260 | No automated end-to-end regression that two near-simultaneous daemon starts yield exactly one daemon per project root. PD-BUG-100's tests pin the launcher cleanup decision (TE-TST-135) and the release_lock/launcher lock-preservation decision in isolation, not the real concurrent-start to single-daemon outcome (the bug's literal symptom). | TST DI | process-framework/tools/linkWatcher/start_linkwatcher_background.ps1 + main.py acquire_lock (concurrent-start path) | 2026-06-08 | Low | M (~3-5h; concurrency harness is flaky-prone) | Open | - | - | - | Surfaced in PD-BUG-100 code review (PF-TSK-005) 2026-06-08; author pinned the precise defective decision instead of building the harness. Cross-ref PD-BUG-100 (Closed). |
| TD261 | Config schema drift guard (test_configschemadrift.py, TE-TST-136) compares set/dict-valued defaults by key presence only, not value — missing a fully-inlined-list value check. Currently masks live drift in configuration-guide.md ignored_directories vs LinkWatcherConfig default. Extend guard to value-compare set/dict defaults for guide fields listed without an abbreviation marker. | TST | test/automated/unit/0-system-architecture-foundation/0-0-system-architecture-foundation/test_configschemadrift.py | 2026-06-10 | Low | Small | Open | - | - | - | Surfaced by Test Audit TE-TAR-075 (feature 0.1.3). Routed to PF-TSK-022 (test-only Lightweight path). |
| TD262 | rescan_file_links() is not atomic: it removes a file's DB links, then parses, with each DB call acquiring the lock separately (reference_lookup.py:243). A parse failure (e.g. transiently locked file on Windows) leaves the file's links absent until the next modify event; a timer-thread move processed in the remove/re-add window can miss that file's references. Pre-existing, but the PD-BUG-102 on_modified rescan raises invocation frequency from rare (move pipeline) to every external save. Fix shape: parse first, then swap old/new link sets under a single lock acquisition. | DI | src/linkwatcher/reference_lookup.py | 2026-06-12 | Low | S | Open | - | - | - | Discovered during PD-BUG-102 code review 2026-06-12 |
| TD263 | Exit-confirmation path untested in panel lifecycle: wait_for_exit timeout branch and daemon_exit_unconfirmed warning have no coverage because FakeTerminator removes PIDs synchronously (TE-TAR-090) | TST | test/automated/unit/7-operations-control/7-1-control-panel/test_panel_lifecycle.py | 2026-08-13 | Medium | Small | Open | - | - | - | - |
| TD264 | CRLF normalization in log_tail is documented as tested in three places but has no test: no backslash-r appears in test_panel_log_tail.py and the held-back-CR branches (log_tail.py 198-199, 201-202) never execute (TE-TAR-094) | TST | test/automated/unit/7-operations-control/7-1-control-panel/test_panel_log_tail.py | 2026-08-13 | Medium | Small | Open | - | - | - | - |
| TD265 | PD-BUG-114 repair path: no regression coverage for the directory-move wiring or the cross-directory authored-form boundary | DI | test/automated/unit/2-link-parsing-update/test_simultaneousmoves.py; src/linkwatcher/handler.py:562-563, 610-611 | 2026-08-17 | Medium | S | Open | - | - | - | All 10 PD-BUG-114 tests deliver single-file FileMovedEvents. Nothing asserts Phase 0 record_move per moved file, the record_move(old_dir, new_dir) directory mapping, or Phase 1.6 apply_pending_recalcs. Existing directory-move tests execute those handler lines (they are NOT in the coverage miss list) but assert nothing about the repair, so the half of the wiring serving the bulk-restructuring case that triage named the primary use case is unverified. Second gap: the authored-form guard also changes cross-directory behavior, not only in-place renames - a non-canonical form such as dot-slash-dot-dot that still resolves after a sideways move is now preserved where it was previously canonicalized. test_cross_directory_move_still_rewrites pins only the case that does need a rewrite; the boundary case that must not be rewritten is unpinned. Third gap, measured by coverage during the review: three defensive branches added by this fix are never executed - reference_lookup.py:369-374 (the pending_link_recalc_dropped warning), :904-909 (the link_target_move_stale warning), and :416-422 (TTL expiry pruning in _prune_move_memory). Module coverage is otherwise healthy (reference_lookup 91 percent, handler 82 percent). Found during Code Review (PF-TSK-005) of the PD-BUG-114 fix, 2026-08-17. |
| TD266 | ReferenceLookup.record_move chain-following is O(n squared) across a directory move | PE | src/linkwatcher/reference_lookup.py:324-341, 412-422 | 2026-08-17 | Low | S | Open | - | - | - | Each record_move copies the whole move memory (list of _recent_moves.items()) to follow destination chains, and _prune_move_memory walks the structure twice more. _handle_directory_moved Phase 0 calls record_move once per moved file, so a directory move of N files costs O(N squared) dict work plus N full copies of a growing dict. At N around 1000 that is roughly 500k tuple comparisons plus 1000 copies, and the 300 second TTL keeps entries alive so consecutive directory moves compound. The README claims 1000-plus files handled efficiently. A reverse index (destination to keys) or an early exit when the old path is not a known destination makes the chain scan O(1) amortized. Found during Code Review (PF-TSK-005) of the PD-BUG-114 fix, 2026-08-17; outside that bug Dims (DI OB), so routed as debt rather than blocking closure. |
| TD267 | Authored-form preservation guard suppresses link rewrites without any log trace | OB | src/linkwatcher/reference_lookup.py:925-929 | 2026-08-17 | Low | S | Open | - | - | - | The guard added by the PD-BUG-114 code-review follow-up is now the branch that decides a link needs no rewrite, and it returns silently. If it ever over-matches, the symptom is a stale link with nothing in the log - the same diagnostic hole the PD-BUG-114 root-cause note called out for the PD-BUG-033 existence guard (fix must also address the silent return - the guard branch emits no log). A debug event, for example link_authored_form_preserved with the original target and the resolved target, costs what the neighbouring link_recalc_pending debug event costs. Found during Code Review (PF-TSK-005) of the PD-BUG-114 fix, 2026-08-17. |

## Recently Resolved Technical Debt

> 🗄️ **Archived** — Resolved and rejected debt rows live in [archive/technical-debt-tracking-archive.md](archive/technical-debt-tracking-archive.md) (sibling file, split 2026-05-26 per PF-IMP-873 to keep this file scannable as resolved history grows; PRJ-001's resolved section reached 73% of file size before split).
>
> `Update-TechDebt.ps1` reads and writes the archive automatically when transitioning to `Resolved` / `Rejected` and when using `-Section "Resolved" -ResolvedDebtId -UpdateNotes` for post-resolution notes. The archive holds two sections: `## Resolved` (debt paid down) and `## Rejected` (won't-fix / accepted-as-design) — kept distinct so trend analysis can separate "we paid it down" from "we decided not to."

## Technical Debt Management Strategy

As a solo developer, follow these guidelines for managing technical debt:

1. **Be intentional**: When creating technical debt, do so consciously and document it immediately
2. **Comment in code**: Mark technical debt in code with `// TODO: [TD###] Description` comments
3. **Regular review**: Review this document periodically to reassess priorities
4. **Batch similar items**: Address similar technical debt items together for efficiency
5. **Refactoring sessions**: Dedicate occasional focused sessions to addressing technical debt

## Linking with Assessment System

**Assessment ID Column**: Links debt items to their originating technical debt assessments:

- **Assessment IDs**: Use format `PD-TDA-XXX` for items identified during formal assessments
- **Debt Item IDs**: Individual debt items get `PD-TDI-XXX` IDs during assessment
- **Manual Items**: Items identified outside assessments leave Assessment ID blank (`-`)

**Workflow Integration**:

1. During Technical Debt Assessment, individual debt items are created with `PD-TDI-XXX` IDs
2. Assessment generates report with `PD-TDA-XXX` ID
3. When adding items to this registry, reference the assessment ID in the Assessment ID column
4. This creates traceability from registry entries back to detailed assessment documentation

## Adding New Technical Debt Items

When adding a new technical debt item:

1. Assign the next available ID (TD###)
2. Add a detailed description
3. Categorize it appropriately
4. Note the exact location in code
5. Assign a priority
6. Estimate the effort required to fix it
7. Add any relevant notes
8. Add a corresponding comment in the code

## Resolving Technical Debt Items

Use [Update-TechDebt.ps1](../../../process-framework/scripts/update/Update-TechDebt.ps1) to automate steps 1-4:

```powershell
# Mark as in progress
Update-TechDebt.ps1 -DebtId "TD###" -NewStatus "InProgress"

# Resolve (moves to Recently Resolved, sets date)
Update-TechDebt.ps1 -DebtId "TD###" -NewStatus "Resolved" -ResolutionNotes "What was done."

# Resolve with plan link (pass a repo-root-relative path; the script derives the ../ prefix from the archive location)
Update-TechDebt.ps1 -DebtId "TD###" -NewStatus "Resolved" -ResolutionNotes "What was done." -PlanLink "doc/refactoring/plans/your-plan-file.md"
```

After running the script:
5. Remove the corresponding TODO comment from the code

---

_This document is part of the Process Framework and provides a system for tracking and managing technical debt._
