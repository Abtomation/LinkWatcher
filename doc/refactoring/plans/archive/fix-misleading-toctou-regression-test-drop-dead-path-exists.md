---
id: PD-REF-234
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-06-04
updated: 2026-06-04
target_area: test_lock_file.py lock-file mechanism (feature 0.1.1)
feature_id: 0.1.1
mode: lightweight
priority: Low
debt_item: TD256
refactoring_scope: Fix misleading TOCTOU regression test: drop dead Path.exists monkeypatch and rename to reflect live-rival-refuses behavior
---

# Lightweight Refactoring Plan: Fix misleading TOCTOU regression test: drop dead Path.exists monkeypatch and rename to reflect live-rival-refuses behavior

- **Target Area**: test_lock_file.py lock-file mechanism (feature 0.1.1)
- **Priority**: Low
- **Created**: 2026-06-04
- **Author**: AI Agent & Human Partner
- **Status**: Planning
- **Debt Item**: TD256
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD256 — Drop dead `Path.exists` monkeypatch and rename misleading TOCTOU test

**Scope** (Dims: TST): `test_acquire_lock_atomic_against_toctou_race` monkeypatches `Path.exists → False` to "force the TOCTOU window", but the rewritten `acquire_lock` (and its helper `_read_lock_owner_pid`) never call `Path.exists()` — the patch is inert against the current `os.open(O_CREAT|O_EXCL)` implementation. The test passes solely because the atomic create hits the real rival lock on disk. Independent verification confirmed the TD claim; the only behaviour the test still uniquely exercises is "a **real, live** rival process holds the lock → refuse" (via the real `_is_pid_running`, unlike the mocked `test_duplicate_instance_prevented`). The fix (TD Option A) removes the dead monkeypatch, renames the test to `test_acquire_lock_refuses_when_live_rival_holds_lock`, and rewrites the name/docstring so they stop claiming an atomicity/TOCTOU property the test does not verify. Option B (a genuine two-process race test) was rejected at the L5 checkpoint: `O_EXCL` atomicity is an OS-level guarantee, a race test re-tests the OS and is inherently flaky, and the marginal coverage gain is low.

**Changes Made**:
- [x] Renamed `test_acquire_lock_atomic_against_toctou_race` → `test_acquire_lock_refuses_when_live_rival_holds_lock`
- [x] Removed the dead `monkeypatch.setattr(Path, "exists", lambda self: False)` line and its misleading TOCTOU comment; dropped the now-unused `monkeypatch` fixture parameter
- [x] Rewrote the docstring to describe the behaviour actually verified (real live rival → refuse) and to contrast with `test_duplicate_instance_prevented` (real `_is_pid_running` vs mocked)
- Imports unchanged (`Path`, `subprocess`, `patch`, etc. still used by sibling tests). Verified empirically: all 13 tests in the file pass after the patch removal, confirming the monkeypatch was inert against the current `O_EXCL` implementation.

**Test Baseline** (L3, `Run-Tests.ps1 -All`, 2026-06-04): 842 passed, 3 skipped, 6 deselected, 4 xfailed, **0 failed**. Target `test_lock_file.py` confirmed present in run output (18% mark). No pre-existing failures.
**Test Coverage (L4)**: N/A — Test-only refactoring; no production code changes. The modified test verifies its own behaviour.
**Test Result** (L7, `Run-Tests.ps1 -All`, 2026-06-04): 842 passed, 3 skipped, 6 deselected, 4 xfailed, **0 failed** — identical to the L3 baseline. Zero diff, no new failures (test count unchanged since this is a rename, not an add/remove). E2E re-execution not warranted — test-only change, no production behaviour modified.

**Documentation & State Updates**:
<!-- Test-only shortcut: items 1–8 batched N/A; item 9 (tech debt) individual. -->
- **Items 1–8 (feature state, TDD, test spec, FDD, ADR, integration narrative, user docs, validation tracking)**: N/A — *Test-only refactoring — no production code changes; design, user-facing, and state documents do not reference test internals.* (Grep for the old test name across the repo returned only the test file, the TD256 row, and this plan — no design/spec/doc surface references it.)
- [x] Technical Debt Tracking (item 9): TD256 marked resolved at L11 via `Update-TechDebt.ps1`.

**Bugs Discovered**: None

<!-- BATCH MODE: Use `-ItemCount N` when running New-RefactoringPlan.ps1 to pre-generate N Item sections up front. To add more debt items mid-session (i.e., new TD IDs — sub-findings of an existing TD become additional `Changes Made` bullets within its Item, not new Items), copy the "## Item N" section above. -->

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD256 | Complete | None | None (test-only; items 1–8 N/A, TD256 resolved) |

## Related Documentation
- [Technical Debt Tracking](../../../state-tracking/permanent/technical-debt-tracking.md)
