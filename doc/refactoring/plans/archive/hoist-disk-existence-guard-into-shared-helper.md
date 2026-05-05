---
id: PD-REF-207
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-29
updated: 2026-04-29
target_area: src/linkwatcher path-resolution modules
refactoring_scope: Hoist disk-existence guard into shared helper
priority: Medium
mode: lightweight
debt_item: TD242
---

# Lightweight Refactoring Plan: Hoist disk-existence guard into shared helper

- **Target Area**: src/linkwatcher path-resolution modules
- **Priority**: Medium
- **Created**: 2026-04-29
- **Author**: AI Agent & Human Partner
- **Status**: In Progress
- **Debt Item**: TD242
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD242 — Hoist disk-existence guard into shared helper

**Scope**: The disk-existence guard pattern (`os.path.join(project_root, relpath)` + `os.path.exists()` → return original target on miss) is duplicated in two path-resolution sites: `reference_lookup._calculate_updated_relative_path` (PD-BUG-033, validates the OLD resolved target) and `path_resolver._calculate_new_target_relative` directory-prefix branch (PD-BUG-095, validates the NEW candidate rewrite). Hoist into a shared helper `path_exists_under_root(project_root, candidate_relpath)` in `utils.py`. Dimension target: **EM** (Extensibility & Maintainability) — reducing duplication and providing the obvious primitive for any future early-exit branch that needs the guard.

**Scope decision — line-109 guard deferred**: The BUG-095 review minor finding #1 (add the disk-existence guard to `path_resolver._calculate_new_target_relative` direct-equality early-exit at line 109) was investigated but not implemented. Verification revealed 22 unit tests in `test_updater.py` rely on the line-109 string-rewrite-without-disk-check contract. The test count is itself evidence the string-rewrite behavior is intentional and widely-depended-on, not "forgotten guard". The failure mode the guard would defend against (a literal string match between a non-reference and a moved file's path) is vanishingly improbable, and no real-world incident has been observed. Resolved as accepted risk — if a real false-positive appears later, file a bug at that point.

**Changes Made**:
- [x] Add `path_exists_under_root(project_root, candidate_relpath) -> bool` to `src/linkwatcher/utils.py`
- [x] Replace inline guard in `reference_lookup.py:765-770` with helper call
- [x] Replace inline guard in `path_resolver.py:122-129` with helper call
- [ ] ~~Add helper call to `path_resolver.py:109-114` direct-equality early-exit~~ — **deferred** (see scope decision above)
- [ ] ~~Update unit tests in `test/automated/unit/test_updater.py`~~ — **N/A** (line-109 deferred, no tests need updating)

**Test Baseline**: 819 passed, 0 failed, 5 skipped, 5 xfailed, 4 deselected (slow-marked) — `pytest test/automated/ -m "not slow"`. No pre-existing failing tests.
**Test Result**: 819 passed, 0 failed, 5 skipped, 5 xfailed, 4 deselected. **No diff vs baseline — clean.**

**Documentation & State Updates**:
- [x] Feature implementation state file (0.1.1, 1.1.1, 2.2.1) updated — added `path_exists_under_root()` to 0.1.1 utils.py key components; added implementation log entries to 1.1.1 and 2.2.1 referencing PD-REF-207
- [x] TDD (1.1.1, 2.2.1) updated, or N/A — _N/A: Grepped tdd-2-2-1-link-updater-t2.md and tdd-1-1-1; TDD references `_calculate_new_target_relative` by name only, internal disk-existence guard is implementation detail not described in TDD. Pure helper extraction with no interface or algorithm changes._
- [x] Test spec (1.1.1, 2.2.1) updated, or N/A — _N/A: No behavior change. Existing test coverage (TestBug033RegexNotRewrittenOnMove, TestBug095RegexAndGlobNotCorruptedOnDirectoryMove, TestBug095PathResolverExistenceGuard, test_nonexistent_target_returns_original) continues to exercise the guard via the refactored helper._
- [x] FDD (1.1.1, 2.2.1) updated, or N/A — _N/A: No functional change. Helper extraction preserves observable behavior._
- [x] ADR updated, or N/A — _N/A: Grepped doc/technical/adr/ — no ADR references path_resolver, reference_lookup, or the disk-existence guard pattern._
- [x] Integration Narrative updated, or N/A — _N/A: Grepped doc/technical/integration/ — narratives describe `_calculate_new_target_relative` at high level (match strategies, return-original-on-no-match), do not describe the disk-existence guard implementation detail._
- [x] Validation tracking updated, or N/A — _N/A: Grepped validation-tracking-4.md — TD242 not raised by any validation round; discovered during PD-BUG-095 code review._
- [x] Technical Debt Tracking: TD242 marked resolved (see L10)

**Bugs Discovered**: None / [Description]

<!-- BATCH MODE: Copy the "## Item N" section above for each additional debt item in this session -->

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD242 | Complete (line-109 deferred — see Scope decision) | None | 0.1.1 utils.py components, 1.1.1 + 2.2.1 implementation logs |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
