---
id: PD-REF-230
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-06-04
updated: 2026-06-04
target_area: main.py acquire_lock (duplicate-instance lock)
mode: lightweight
debt_item: TD255
refactoring_scope: Close the acquire_lock create-then-write TOCTOU window so a rival cannot reclaim an empty in-progress lock
priority: Low
---

# Lightweight Refactoring Plan: Close the acquire_lock create-then-write TOCTOU window so a rival cannot reclaim an empty in-progress lock

- **Target Area**: main.py acquire_lock (duplicate-instance lock)
- **Priority**: Low
- **Created**: 2026-06-04
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Debt Item**: TD255
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD255 — Close the create-then-write TOCTOU window in acquire_lock

**Dimension**: CQ (Code Quality)

**Scope**: `acquire_lock` ([main.py:217-281](../../../../main.py#L217-L281)) creates the lock atomically with `O_CREAT|O_EXCL` but writes the owner PID in a *separate* `os.write` a moment later. In the sub-µs window between create and PID-write the lock file exists but is empty; a racing instance hits `FileExistsError`, parses the empty body (`int("")` → `ValueError` → `existing_pid = None`), falls through to the "stale lock" branch, **unlinks the legitimate fresh lock**, and double-acquires. Fix (localized, interface-preserving): when a rival reads an empty/unparseable lock body, *settle-read* — re-read a few times with a short back-off before deciding; reclaim as stale only if it stays unparseable (a genuine orphan), otherwise it will see the now-written PID and defer to the live owner. No change to the `acquire_lock`→`Path` / `release_lock(Path)` signatures (so the TD's fd-hold approach and its `release_lock` semantics change are deliberately avoided). The `TimestampRotatingFileHandler` rotation back-off that masks the downstream storm is **not** touched.

**Changes Made**:
- [x] [main.py](../../../../main.py): added `import time`.
- [x] [main.py](../../../../main.py): extracted `_read_lock_owner_pid(lock_file, settle_attempts=5, settle_delay=0.02)` — settle-reads an empty lock body (re-reads with a short back-off) so a rival's create-then-write window is not mistaken for a stale lock; non-numeric content → `None` immediately (corruption); persistently empty → `None` (orphan, reclaimable); numeric → parsed PID.
- [x] [main.py](../../../../main.py): `acquire_lock` `FileExistsError` branch now calls `_read_lock_owner_pid(lock_file)` instead of the inline `int(lock_file.read_text().strip())`. No change to `acquire_lock`→`Path` / `release_lock(Path)` signatures.
- [x] [test_lock_file.py](../../../../test/automated/unit/0-system-architecture-foundation/0-0-system-architecture-foundation/test_lock_file.py): added `test_acquire_lock_defers_to_owner_filling_empty_lock` (empty lock fills with a live rival PID mid-settle → `SystemExit(1)`; asserts re-read happened) and `test_acquire_lock_reclaims_persistently_empty_lock` (empty stays empty → orphan reclaimed).

**Test Baseline**: `Run-Tests.ps1 -All` (2026-06-04) — 849 selected: **842 passed, 3 skipped, 4 xfailed, 0 failed, 0 errors** (123s). No pre-existing failures. Target `test_lock_file.py` included (11 passed).
**Test Result**: `Run-Tests.ps1 -All` (2026-06-04, post-fix) — **844 passed, 3 skipped, 4 xfailed, 0 failed, 0 errors** (103s). Diff vs baseline: **+2 passed** (the two new TD255 regression tests), **no new failures, no errors**. The defer-test fails on pre-fix code (empty read → `int("")` → reclaim → no `SystemExit`), confirming it guards the actual bug.

**Documentation & State Updates** (feature 0.1.1):
- [x] Feature implementation state file (0.1.1) **updated** — added `_read_lock_owner_pid()` to the `main.py` function inventory (Components table). Behavioral descriptions (lock prevents duplicates / overrides stale) already accurate.
- [x] TDD (0.1.1) **updated** — `tdd-0-1-1-core-architecture-t3.md` §4.3: amended the FileExistsError read-PID step and Error Handling bullet to document the settle-read of a momentarily-empty (mid-write) lock. PID-reuse "Residual limitation" left intact (different residual, not touched).
- [x] Test spec (0.1.1) — **N/A**: `test-spec-0-1-1-core-architecture.md` lists a representative (non-exhaustive — already omits 5 of the pre-existing 11 methods) set; the 2 additions cover edge cases of already-specified duplicate-prevention/stale behavior — no *specified* behavior changed.
- [x] FDD (0.1.1) — **N/A**: FR-8 (prevent duplicates, exit with error), EC-7 (stale override), EC-8 (can't-create → warn) all remain accurate; no functional change.
- [x] ADR — **N/A**: recursive grep of `doc/` surfaced no ADR referencing the lock mechanism.
- [x] Integration Narrative — **N/A** (behavioral): `startup-integration-narrative.md` describes `acquire_lock` behavior (abort on live PID / override stale), which is preserved. _Observation: the narrative's cited `main.py:NNN` line numbers were already stale before this change and are now shifted ~29 lines further by the helper insertion — pre-existing DA drift, broader than TD255; surfaced to human, not fixed here._
- [x] User documentation — **N/A**: `multi-project-setup.md` and `link-validation.md` describe lock behavior only (prevents duplicates / overrides stale / no lock in `--validate`), all preserved; `README.md` has no lock references.
- [x] Validation tracking — **N/A**: no active validation round; the `PD-VAL-*` matches are completed point-in-time reports and the change has no behavioral/interface effect on validation outcomes.
- [ ] Technical Debt Tracking: TD item marked resolved → **deferred to L11** (after L10 checkpoint).

**Bugs Discovered**: None.

<!-- BATCH MODE: Use `-ItemCount N` when running New-RefactoringPlan.ps1 to pre-generate N Item sections up front. To add more debt items mid-session (i.e., new TD IDs — sub-findings of an existing TD become additional `Changes Made` bullets within its Item, not new Items), copy the "## Item N" section above. -->

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD255 | Complete | None | TDD 0.1.1 §4.3 (settle-read); feature state file 0.1.1 (function inventory). 6 other surfaces N/A. |

## Related Documentation
- [Technical Debt Tracking](../../../state-tracking/permanent/technical-debt-tracking.md)
