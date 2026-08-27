---
id: PD-REF-238
type: Product Documentation
category: Refactoring Plan
version: 1.0
created: 2026-08-27
updated: 2026-08-27
debt_item: TD301
description: "Refactoring plan: Correct superseded PD-BUG-141 records and pin the untested unusable-handle branch"
feature_id: 1.1.1
mode: lightweight
priority: Medium
refactoring_scope: Correct superseded PD-BUG-141 records and pin the untested unusable-handle branch
target_area: winapi_patch (watch-root deletion predicate) records and tests
---

# Lightweight Refactoring Plan: Correct superseded PD-BUG-141 records and pin the untested unusable-handle branch

- **Target Area**: winapi_patch (watch-root deletion predicate) records and tests
- **Priority**: Medium
- **Created**: 2026-08-27
- **Author**: AI Agent & Human Partner
- **Status**: Complete (2026-08-27) — TD301 Resolved
- **Debt Item**: TD301
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD301 — PD-BUG-141 records document the superseded fix; one branch untested

**Dims**: `DA` (Documentation Alignment) + `TST` (Testing). The DA half is the primary deliverable
per the Lightweight Path's DA-category guidance; the TST half is one added test.

**Scope**: PD-BUG-141 shipped two implementations — a path-normalization predicate (rejected at code
review on 2026-08-27 because junction- and `subst`-rooted watches stayed effectively constant-true)
and the directory-**identity** compare that replaced it. Three records still describe the rejected
first mechanism or misstate the resulting coverage. This item corrects those records and adds one
test pinning the previously untested unusable-watch-handle branch. **No production code changes** —
`src/linkwatcher/winapi_patch.py` is read, not modified.

### DA root-cause trace (drift mechanism)

`git log` cannot separate the v1 and v2 edits here: the entire PD-BUG-141 change set is still
uncommitted (`winapi_patch.py` and its test file are untracked), so the whole two-implementation
history sits in one working-tree blob. The trace therefore comes from the documentary record — the
successive review notes on the PD-BUG-141 archive row — rather than from version history.

**Mechanism**: the 2026-08-27 re-implementation updated the two rows in the 1.1.1 feature state file
that carry an explicit change-stamp column — the source-inventory row (206) and test-inventory row
(215), both re-stamped `PD-BUG-141 (2026-08-27)` — but never revisited the **bug-history row** (128),
which is dated by *when the bug was recorded* (2026-08-26) rather than by when its fix last changed.
A row whose date already looks settled does not present as needing a second pass, so the rewrite
silently left the rejected mechanism standing in the one place a reader treats as authoritative
history. The same shape produced the stale test docstring: the rewrite deleted the `os.path.isdir`
pre-check but not the docstring explaining why a test guarded it.

**Generalization (observation only, nothing filed)**: any bug whose fix is *re-implemented after a
review rejection* carries this exposure — change-stamped rows get swept, narrative rows dated at
filing time do not.

**Changes Made**:
<!-- Fill in after implementation -->
- [x] F1 (Major) — `doc/state-tracking/features/1.1.1-file-system-monitoring-implementation-state.md:128`:
      replace the rejected-mechanism text (`os.path.isdir` pre-check plus a normalized DOS-path
      compare) with the shipped directory-identity compare
- [x] F2 (Minor) — `test/automated/unit/1-file-watching-detection/test_watchrootdeletionpredicate.py:197-200`:
      replace the stale docstring rationale naming the removed `os.path.isdir` pre-check
- [x] F3 (Minor) — add one test passing an unusable watch handle, pinning `winapi_patch.py` lines
      115 and 138 (verified reachable: an invalid handle returns `True` without crashing)
- [x] Scope delta (a) — same row, stale status cell `👀 Needs Review` → `🔒 Closed`
- [x] Scope delta (b) — test count ripple: `test-tracking.md:87` (12 → 13) and state file line 215
      (`12 tests` → `13 tests`)
- [x] Scope delta (c) — test file metadata block: `Version 1.0` / `Updated: 2026-08-26` are stale
- [x] Scope delta (d) — test spec 1.1.1: the PD-BUG-141 row enumerates the suite case list,
      so the added unusable-watch-handle case was appended there too

**Scope narrowed (approved at the Effort Assessment Gate)**: TD301's "correct the coverage claim"
half is deliberately **not** done by editing the PD-BUG-141 archive row. That row is an append-only
audit trail of three successive reviews, and it *already carries* the correction — appended by the
same review that filed TD301 ("only 3 of the 5 uncovered lines are non-Windows or absent-watchdog
branches (162, 166-167) while 115 and 138 are the unusable-watch-handle branch"). Rewriting the
earlier Verification note would edit history for no gain. Once F3 lands, only 162/166-167 remain
uncovered — exactly "the non-Windows and absent-watchdog defensive branches" — so the original
claim's substance becomes true and only its count (5 → 3) is stale, which the appended note states.
The accurate post-fix figure is recorded in the TD resolution notes instead.

**Test Baseline**: 1698 passed, 0 failed, 3 skipped, 6 deselected, 3 xfailed (103.39s,
`Run-Tests.ps1 -All`, 2026-08-27). **No pre-existing failures** — any new failure is owned by this
session. Target-file baseline: TE-TST-159 12/12 passing, `winapi_patch.py` coverage 89%
(uncovered: 115, 138, 162, 166-167).

**Test Coverage Assessment (L4)**: Test-only refactoring — coverage assessment N/A; no production
code changes, and the modified test file verifies its own behavior. The added test increases
coverage of an existing production branch rather than locking behavior ahead of a change.

**Test Result**: **1699 passed, 0 failed**, 3 skipped, 6 deselected, 3 xfailed (107.88s) — same
command as the baseline. Diff vs. L3: **+1 passed (1698 → 1699)**, the added test; every other
count identical; **no new failures**, and the baseline had none to inherit. Target file: TE-TST-159
13/13. `winapi_patch.py` coverage **89% → 94%**, uncovered now only `162, 166-167` — exactly the
non-Windows and absent-watchdog defensive branches. `black --check` and `isort --check-only` clean
on both changed and referenced files.

**Load-bearing verification (F3)**: the new assertion was mutation-verified rather than accepted on
a fail-first claim. Inverting the branch under test (`winapi_patch.py:138`, `return True` →
`return False`) turned **exactly one** test red — `test_unusable_watch_handle_is_reported_deleted`
— with the precise signature `assert False is True`, and the other 12 stayed green. That is the
discriminating condition: no other assertion in the suite depends on that branch, so the mapping
between test and defect is confirmed rather than assumed. Source restored from a pre-mutation copy
and **md5-verified identical**; production code leaves this session byte-for-byte unchanged.

**Documentation & State Updates**:
- [x] **Feature implementation state file (1.1.1) — UPDATED**: bug-history row (128) rewritten from
      the rejected path-normalization mechanism to the shipped identity compare, naming the v1
      rejection so the superseded approach stays legible as history; status cell `👀 Needs Review`
      → `🔒 Closed`. Test-inventory row (215) count `12 tests` → `13 tests`, stamped `TD301`.
- [x] TDD (1.1.1) — **N/A**: grepped `doc/technical/tdd/` for `PD-BUG-141` and `winapi_patch` — 0
      matches. No production code changed, so no internal design to re-document.
- [x] **Test spec (1.1.1) — UPDATED**: the PD-BUG-141 row enumerates the suite's cases, so the added
      unusable-watch-handle case was appended. Not strictly a behavior change, but omitting it
      would recreate the exact record-vs-reality drift this item exists to close.
- [x] FDD (1.1.1) — **N/A**: `1.1.1-EC-12` re-read and verified accurate against the shipped
      identity compare — it already names junction/`subst` support and the unreachable-root
      limitation. No functional change.
- [x] ADR — **N/A**: grepped both ADR trees (`doc/technical/adr`,
      `doc/technical/architecture/design-docs/adr`) for `winapi` / `_is_observed_path_deleted` /
      `PD-BUG-141` — 0 matches.
- [x] Integration Narrative — **N/A**: grepped `doc/technical/integration` — 0 matches.
- [x] User documentation — **N/A**: capabilities reference re-read (Watch Liveness Monitoring
      bullet) and verified accurate — identity-based, junction/`subst` named, unreachable-root
      limitation stated. `README.md` 0 matches. No user-visible change.
- [x] Validation tracking — **N/A**: 1.1.1 is tracked in `validation-tracking-3.md`, but that round
      is COMPLETE and this change alters no production code.
- [x] **Test tracking files — UPDATED**: `Test Cases Count` synced 12 → 13 via
      `Validate-TestTracking.ps1 -Fix -Path <file>` (scripted, not hand-edited). The `Last Run`
      cell (`Run 2026-08-27: 12 passed`) mirrors a code value that changed and was corrected by
      hand — see Tooling Gaps below. Full `Validate-TestTracking.ps1`: **0 errors** (27 warnings,
      all pre-existing; none name this file).
      <!-- ADDED BY HAND: the generated lightweight template omits this item, which the Lightweight
           Path document lists as checklist item 9. Load-bearing here — this change alters the
           test-tracking.md Test Cases Count. Framework finding, raised at the L5 checkpoint. -->
- [x] **Technical Debt Tracking — DONE (L11)**: TD301 marked Resolved via `Update-TechDebt.ps1`
      (with `-PlanLink` to this plan) and auto-moved to the archive. Audit-status closure **N/A** —
      TD301 was filed at Code Review (PF-TSK-005), and its row references no `TE-TAR-*` report, so
      there is no audit loop to close. Feature Tracking **N/A** — 1.1.1 is already `🟢 Completed`
      and no production code changed. Bug Tracking **N/A** — no bugs discovered.

**E2E re-execution**: **N/A** — production code is byte-identical (verified by md5 before and after
the mutation probe), so no runtime behavior changed and no E2E group needs re-execution. Consistent
with the PD-BUG-141 fix sessions, which also declined to flag the 34-entry E2E cascade.

**Bugs Discovered**: None.

### Tooling gaps encountered (for the feedback form)

1. **Lightweight plan template omits a checklist item.** The generated
   `lightweight-refactoring-plan-template.md` produces 9 Documentation & State Updates items; the
   Lightweight Path document specifies 10. The missing one is item 9, *Test tracking files updated*
   — load-bearing here, since this change alters a `Test Cases Count`. Added by hand.
2. **No script can refresh a run-note on a `🔄 Needs Audit` row.** `Validate-TestTracking.ps1 -Fix`
   syncs the count but not the `Last Run` cell, and `Update-TestFileAuditState.ps1`'s `AuditStatus`
   ValidateSet has no `Needs Audit` member — using it would have wrongly flipped the row out of the
   audit queue. Hand-edit was the only route. Same family as the known `Update-BugStatus.ps1`
   no-amend-only-mode gap.
3. **Not a gap — memory correction**: `Validate-TestTracking.ps1 -Fix` *did* correct a populated
   count (12 → 13) cleanly. The known Check 8 defect (PF-IMP-2172) is specific to **blank** cells.

<!-- BATCH MODE: Use `-ItemCount N` when running New-RefactoringPlan.ps1 to pre-generate N Item sections up front. To add more debt items mid-session (i.e., new TD IDs — sub-findings of an existing TD become additional `Changes Made` bullets within its Item, not new Items), copy the "## Item N" section above. -->

## Results Summary

| Item | Debt ID / Origin | Status | Bugs Found | Doc Updates |
|------|------------------|--------|------------|-------------|
| 1 | TD301 | Complete | None | 1.1.1 feature state file (bug-history row + status cell + test-inventory count); test spec 1.1.1 (PD-BUG-141 case list); test-tracking.md (count 12→13 scripted, run-note + notes cell); TE-TST-159 docstring + metadata. TDD / FDD / ADR / Integration Narrative / user docs / validation tracking verified N/A with per-surface greps. |

**Status**: Complete — pending L11 state updates (TD301 resolution, plan archive).

**Scope delta vs. the original TD301 description**: two changes, both approved at the Effort
Assessment Gate. **Narrowed** — TD301's "correct the coverage claim" half was dropped, because the
claim sits on the append-only PD-BUG-141 archive row which *already* carries that correction,
appended by the very review that filed TD301; rewriting the earlier note would edit an audit trail
for no gain, and after F3 only 162/166-167 remain uncovered, making the original claim's substance
true and only its count (5 → 3) stale. **Widened** — four records the TD did not name were found
stale by the same drift: the bug-history status cell (`👀 Needs Review` on a closed bug), the test
count in two places, the test file's metadata block, and the test spec's case list.

**Calibration note for future assessments**: the TD was filed accurately on the three items it
named and materially under-scoped on the ripple. The pattern is worth remembering — a TD filed for
"stale record X" tends to miss the sibling records that mirror the same value.

## Related Documentation
- [Technical Debt Tracking](../../../state-tracking/permanent/technical-debt-tracking.md)
