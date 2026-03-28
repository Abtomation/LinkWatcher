---
id: PD-REF-081
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-27
updated: 2026-03-27
refactoring_scope: Add source-file reverse index to LinkDatabase for O(R_file) lookups in remove_file_links and update_source_path
priority: Medium
mode: lightweight
target_area: linkwatcher/database.py
---

# Lightweight Refactoring Plan: Add source-file reverse index to LinkDatabase for O(R_file) lookups in remove_file_links and update_source_path

- **Target Area**: linkwatcher/database.py
- **Priority**: Medium
- **Created**: 2026-03-27
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD072 — Add source-file reverse index to LinkDatabase

**Scope**: `remove_file_links()` and `update_source_path()` currently iterate all target keys × all references (O(T*R)) to find references from a given source file. Add a `_source_to_targets: Dict[str, Set[str]]` reverse index mapping normalized source file paths to the set of target keys they reference. Maintain this index in `add_link()`, `remove_file_links()`, `update_source_path()`, and `clear()`. This reduces source-based lookups from O(T*R) to O(R_file).

**Changes**:
- [x] `__init__`: Add `self._source_to_targets: Dict[str, Set[str]]` reverse index
- [x] `add_link()`: Populate reverse index entry on each add
- [x] `remove_file_links()`: Use reverse index to find only relevant target keys instead of full scan
- [x] `update_source_path()`: Use reverse index to find relevant targets, then move index entry
- [x] `clear()`: Clear the reverse index
- No public API or interface changes

**Test Baseline**: 26 passed (test_database.py), 604 passed / 5 skipped / 7 xfailed (full suite)
**Test Result**: 26 passed (test_database.py), 604 passed / 5 skipped / 7 xfailed (full suite) — identical

**Documentation & State Updates**:
- [x] Feature implementation state file (0.1.2) updated, or N/A — grepped state file: mentions `add_link()`, `remove_file_links()` as API operations only, no internal data structure detail; no update needed
- [x] TDD (0.1.2) updated, or N/A — TDD shows `__init__` data structures in pseudocode (line 84-100) but describes design-level architecture, not implementation-level optimizations; internal reverse index is an optimization detail not warranting TDD change
- [x] Test spec (0.1.2) updated, or N/A — test spec references `remove_file_links()` behavior (removal, cleanup, logging) but not internal indexing strategy; no behavior change
- [x] FDD (0.1.2) updated, or N/A — FDD mentions `remove_file_links()` only as service-level operation; no functional change
- [x] ADR (target-indexed-in-memory-link-database) updated, or N/A — ADR documents target-indexed design decision and locking strategy; reverse index is an additive optimization compatible with the target-indexed decision, not a new architectural choice
- [x] Validation tracking updated, or N/A — feature 0.1.2 not tracked in validation-tracking-2.md
- [x] Technical Debt Tracking: TD072 marked resolved via Update-TechDebt.ps1

**Bugs Discovered**: None

<!-- BATCH MODE: Copy the "## Item N" section above for each additional debt item in this session -->

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD072 | Complete | None | None (all N/A verified) |

## Related Documentation
- [Technical Debt Tracking](/doc/product-docs/state-tracking/permanent/technical-debt-tracking.md)
