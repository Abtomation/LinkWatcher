---
id: PD-REF-135
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-02
updated: 2026-04-02
priority: Medium
refactoring_scope: Add _key_to_resolved_paths reverse index for O(1) key removal
target_area: In-Memory Link Database
mode: lightweight
---

# Lightweight Refactoring Plan: Add _key_to_resolved_paths reverse index for O(1) key removal

- **Target Area**: In-Memory Link Database
- **Priority**: Medium
- **Created**: 2026-04-02
- **Author**: AI Agent & Human Partner
- **Status**: Planning
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD138 — Add _key_to_resolved_paths reverse index for O(1) key removal

**Scope**: `_remove_key_from_indexes()` iterates ALL `_resolved_to_keys` entries O(R) to discard a key. Add a `_key_to_resolved_paths: Dict[str, Set[str]]` reverse index (key → set of resolved paths containing it) for O(1) removal. Mirrors the existing `_source_to_targets` pattern. Dimension: PE (Performance).

**Changes Made**:
- [x] Add `_key_to_resolved_paths` dict initialization in `__init__` (L181)
- [x] Maintain reverse index in `add_link()` resolved path population (L272-275)
- [x] Maintain reverse index in `_add_key_to_indexes()` (L493-496)
- [x] Use reverse index in `_remove_key_from_indexes()` instead of full scan (L471-475)
- [x] Clear reverse index in `clear()` (L696)
- [x] Added docstring for new index in module docstring (L56-62)

**Test Baseline**: 649 passed, 5 skipped, 6 xfailed
**Test Result**: 649 passed, 5 skipped, 6 xfailed — identical to baseline

**Documentation & State Updates**:
- [x] Feature implementation state file (0.1.2) updated, or N/A — _Grepped state-tracking/features for _remove_key_from_indexes/_resolved_to_keys — no references found_
- [x] TDD (0.1.2) updated, or N/A — _TDD references _resolved_to_keys in pseudocode but not _remove_key_from_indexes internals; internal optimization doesn't change interface. TD148 already tracks missing index documentation._
- [x] Test spec (0.1.2) updated, or N/A — _Grepped test-spec-0-1-2 — no references to changed methods; behavior unchanged_
- [x] FDD (0.1.2) updated, or N/A — _Grepped fdd-0-1-2 — no references to changed internal methods_
- [x] ADR updated, or N/A — _Grepped ADR directory — no references to _remove_key_from_indexes or _resolved_to_keys_
- [x] Validation tracking updated, or N/A — _R3 validation complete for 0.1.2; internal optimization doesn't invalidate validation results_
- [ ] Technical Debt Tracking: TD138 marked resolved

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD138 | Complete | None | Module docstring updated |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)

