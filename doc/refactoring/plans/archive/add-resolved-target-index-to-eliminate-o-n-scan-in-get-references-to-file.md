---
id: PD-REF-124
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-30
updated: 2026-03-30
priority: Medium
mode: lightweight
refactoring_scope: Add resolved-target index to eliminate O(n) scan in get_references_to_file
target_area: src/linkwatcher/database.py
---

# Lightweight Refactoring Plan: Add resolved-target index to eliminate O(n) scan in get_references_to_file

- **Target Area**: src/linkwatcher/database.py
- **Priority**: Medium
- **Created**: 2026-03-30
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD127 — Add resolved-target index to eliminate O(n) scan in get_references_to_file

**Scope**: `get_references_to_file()` currently does an O(1) direct lookup then falls through to an O(n*m) scan of all keys and references to find anchored, relative, filename-only, and suffix matches. Add a `_resolved_target_to_keys` secondary index (populated at `add_link()` time by resolving each reference's target relative to its source file) to replace the full scan with O(1) lookups. Must maintain the index in all mutation methods: `add_link`, `remove_file_links`, `update_target_path`, `update_source_path`, `remove_targets_by_path`, `clear`.

**Debt Item ID**: TD127
**Test Baseline**: 621 passed, 5 skipped, 5 xfailed
**Test Result**: 621 passed, 5 skipped, 5 xfailed (identical — zero regressions)

**Changes Made**:
- [x] Add `_base_path_to_keys` and `_resolved_to_keys` dicts to `__init__`
- [x] Add `_resolve_target_paths()` helper to compute resolved paths at insertion time
- [x] Populate both indexes in `add_link()`
- [x] Rewrite `get_references_to_file()` — Phase 1: O(1) via indexes; Phase 2: suffix match scan over base paths only
- [x] Add `_remove_key_from_indexes()` / `_add_key_to_indexes()` maintenance helpers
- [x] Maintain indexes in `remove_file_links()` (clean on key deletion)
- [x] Maintain indexes in `update_target_path()` (remove old, add new)
- [x] Maintain indexes in `update_source_path()` (rebuild resolved index on source path change)
- [x] Maintain indexes in `remove_targets_by_path()` (clean on key deletion)
- [x] Clear both indexes in `clear()`
- [x] Bonus: `update_target_path()` and `remove_targets_by_path()` now use `_base_path_to_keys` for O(1) anchored key lookup

**Documentation & State Updates**:
- [x] Feature implementation state file (0.1.2) updated, or N/A — _Grepped state file: mentions `get_references_to_file()` as a key operation but doesn't describe internal implementation. No update needed._
- [x] TDD (0.1.2) updated, or N/A — _TDD describes "three-level resolution" strategy. This refactoring didn't change what paths match, only how they're found internally. No interface/design change. N/A._
- [x] Test spec (0.1.2) updated, or N/A — _No behavior change affects spec. N/A._
- [x] FDD (0.1.2) updated, or N/A — _FDD describes "three-level resolution" as a business rule. Internal optimization doesn't affect functional design. N/A._
- [x] ADR updated, or N/A — _ADR-040 documents target-indexed storage decision. Adding secondary indexes is consistent with that decision, not a change to it. N/A._
- [x] Validation tracking updated, or N/A — _0.1.2 validation completed in Round 2. Performance dimension report (PD-VAL-055) noted "O(T*R) anchor resolution" as Medium issue — this refactoring addresses it. No re-validation needed for an internal optimization. N/A._
- [x] Technical Debt Tracking: TD127 marked resolved via Update-TechDebt.ps1

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD127 | Complete | None | None (internal optimization, no doc impact) |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
