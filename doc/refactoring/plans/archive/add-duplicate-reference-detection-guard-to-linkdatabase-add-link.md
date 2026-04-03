---
id: PD-REF-104
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-27
updated: 2026-03-27
target_area: LinkDatabase
priority: Medium
mode: lightweight
refactoring_scope: Add duplicate reference detection guard to LinkDatabase.add_link()
---

# Lightweight Refactoring Plan: Add duplicate reference detection guard to LinkDatabase.add_link()

- **Target Area**: LinkDatabase
- **Priority**: Medium
- **Created**: 2026-03-27
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD100 — Add duplicate reference detection guard to add_link()

**Scope**: `LinkDatabase.add_link()` in `linkwatcher/database.py` blindly appends every `LinkReference` without checking if an identical reference (same source file, line number, and normalized target) already exists. Add a duplicate-detection guard that skips insertion when the reference is already present. This prevents inflated stats, redundant update work during file moves, and potential issues if `rescan_file_links(remove_existing=False)` is used.

**Changes Made**:
- [x] Added duplicate check in `add_link()` before appending — guards on normalized source file + line number + column_start (`database.py:154-159`)
- [x] Added 3 unit tests: `test_add_link_duplicate_detection`, `test_add_link_same_target_different_lines`, `test_add_link_same_line_different_columns` (`test_database.py`)
- [x] Updated thread safety test to use unique references per thread (was creating genuine duplicates across threads)
- [x] Removed redundant `source_norm` re-computation after the guard (reuses variable from duplicate check)

**Test Baseline**: 593 passed, 5 skipped, 7 xfailed
**Test Result**: 596 passed, 5 skipped, 7 xfailed (+3 new tests)

**Documentation & State Updates**:
- [x] Feature implementation state file (0.1.2) updated, or N/A — _N/A: grepped state file, mentions `add_link()` only in operations list, no design claims to update_
- [x] TDD (0.1.2) updated — _Updated pseudocode in TDD-022 to include duplicate guard_
- [x] Test spec (0.1.2) updated, or N/A — _N/A: grepped test spec, mentions `test_add_link` test but no behavior claims contradicted; new tests extend coverage_
- [x] FDD (0.1.2) updated, or N/A — _N/A: grepped FDD-023, mentions `add_link()` in flow description only, no behavioral claims affected_
- [x] ADR updated — _Updated ADR PD-ADR-040: replaced "No uniqueness enforcement" limitation with "Duplicate guard" description_
- [x] Validation tracking updated, or N/A — _N/A: 0.1.2 validation round 2 completed, this defensive guard doesn't invalidate any scores_
- [x] Technical Debt Tracking: TD100 marked resolved via Update-TechDebt.ps1

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD100 | Complete | None | TDD-022 pseudocode, ADR PD-ADR-040 limitation |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
