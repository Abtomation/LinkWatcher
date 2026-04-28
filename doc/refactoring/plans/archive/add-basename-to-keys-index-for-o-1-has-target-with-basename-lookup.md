---
id: PD-REF-139
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-02
updated: 2026-04-02
priority: Medium
refactoring_scope: Add _basename_to_keys index for O(1) has_target_with_basename lookup
mode: lightweight
target_area: LinkDatabase
---

# Lightweight Refactoring Plan: Add _basename_to_keys index for O(1) has_target_with_basename lookup

- **Target Area**: LinkDatabase
- **Priority**: Medium
- **Created**: 2026-04-02
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Dependencies and Impact
- **Affected Components**: `src/linkwatcher/database.py` (index maintenance + lookup rewrite)
- **Internal Dependencies**: `linkwatcher/handler.py:_is_known_reference_target()` calls `has_target_with_basename()` — behavior unchanged (same return values)
- **Risk Assessment**: Low — additive secondary index following established pattern (`_base_path_to_keys`, `_resolved_to_keys`). No API/interface changes.

## Item 1: TD139 — Add `_basename_to_keys` index for O(1) `has_target_with_basename` lookup

**Scope**: `has_target_with_basename()` iterates all `self.links` keys O(N) computing `os.path.basename()` on each call. Called from `handler._is_known_reference_target()` on every unmonitored file event on the observer thread. Fix: add `_basename_to_keys: Dict[str, Set[str]]` secondary index (basename → target keys), maintained at `add_link()`, `_remove_key_from_indexes()`, `_add_key_to_indexes()`, and `clear()`. Rewrite `has_target_with_basename()` to a single `in` check.

**Changes Made**:
- [x] Add `_basename_to_keys` dict to `__init__()` (database.py:191)
- [x] Maintain index in `add_link()` when new key is created (database.py:278-282)
- [x] Maintain index in `_remove_key_from_indexes()` on key removal (database.py:493-497)
- [x] Maintain index in `_add_key_to_indexes()` on key re-addition (database.py:504-508)
- [x] Clear index in `clear()` (database.py:716)
- [x] Rewrite `has_target_with_basename()` to use index (database.py:700-704)
- [x] Add 7 tests in `TestHasTargetWithBasename` class (test_database.py:692-756): hit, miss, empty_database, after_removal, after_clear, after_target_update, multiple_keys_same_basename

**Test Baseline**: 649 passed, 5 skipped, 6 xfailed. Database tests: 38 passed.
**Test Result**: 656 passed (+7 new), 5 skipped, 6 xfailed. Database tests: 45 passed (+7 new). Zero failures.

**Documentation & State Updates**:
- [x] Feature implementation state file (0.1.2) updated, or N/A — _N/A: grepped state file for has_target_with_basename/_basename_to_keys — no references found_
- [x] TDD (0.1.2) updated, or N/A — _N/A: TDD line 67 mentions has_target_with_basename() in method list — method still exists with same signature, no change needed_
- [x] Test spec (0.1.2) updated, or N/A — _N/A: grepped test spec — no references to has_target_with_basename found_
- [x] FDD (0.1.2) updated, or N/A — _N/A: grepped FDD — no references to has_target_with_basename found_
- [x] ADR (0.1.2) updated, or N/A — _N/A: ADR line 54 mentions has_target_with_basename in locking context — method still acquires lock, no change needed_
- [x] Validation tracking updated, or N/A — _N/A: 0.1.2 validation complete in R3; internal performance optimization doesn't affect validation scores_
- [ ] Technical Debt Tracking: TD139 marked resolved

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD139 | Complete | None | None (all N/A — internal optimization, no API change) |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
