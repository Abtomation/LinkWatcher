---
id: PD-REF-053
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-03
updated: 2026-03-03
priority: Medium
refactoring_scope: Consolidate 3-pass get_references_to_file into single pass
target_area: src/linkwatcher/database.py
mode: lightweight
---

# Lightweight Refactoring Plan: Consolidate 3-pass get_references_to_file into single pass

- **Target Area**: src/linkwatcher/database.py
- **Priority**: Medium
- **Created**: 2026-03-03
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (≤15 min effort, single file, no architectural impact)

## Item 1: TD042 — Consolidate 3-pass get_references_to_file into single pass

**Scope**: `get_references_to_file` in `linkwatcher/database.py:71-100` performs 3 separate passes over `self.links`: (1) direct key lookup, (2) full iteration for anchored keys, (3) full iteration for relative-path resolution via `_reference_points_to_file`. Passes 2 and 3 both iterate the full collection and can be merged into a single loop that checks both anchored-key matching and relative-path resolution, collecting results into a set to avoid duplicates.

**Changes Made**:
- [x] Merged passes 2 and 3 into a single iteration over `self.links.items()` with `continue` to skip relative-path check when anchored-key match already found
- [x] Replaced `ref not in all_references` O(n) linear scan with `id(ref) not in seen` O(1) set lookup for deduplication

**Test Baseline**: 387 passed, 5 skipped, 7 xfailed
**Test Result**: 387 passed, 5 skipped, 7 xfailed (identical)

**Documentation & State Updates**:
- [x] Feature implementation state file updated — N/A (internal optimization, no feature-level change)
- [x] TDD updated — N/A (no interface/design change)
- [x] Test spec updated — N/A (no behavior change)
- [x] FDD updated — N/A (no functional change)
- [x] Technical Debt Tracking: TD042 marked resolved via Update-TechDebt.ps1

**Bugs Discovered**: None

<!-- BATCH MODE: Copy the "## Item N" section above for each additional debt item in this session -->

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD042 | Complete | None | None |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
