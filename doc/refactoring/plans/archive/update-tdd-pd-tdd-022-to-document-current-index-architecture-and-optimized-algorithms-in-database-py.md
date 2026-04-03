---
id: PD-REF-145
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-02
updated: 2026-04-02
mode: lightweight
refactoring_scope: Update TDD PD-TDD-022 to document current index architecture and optimized algorithms in database.py
priority: Medium
target_area: In-Memory Database TDD
---

# Lightweight Refactoring Plan: Update TDD PD-TDD-022 to document current index architecture and optimized algorithms in database.py

- **Target Area**: In-Memory Database TDD
- **Priority**: Medium
- **Created**: 2026-04-02
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD148 — TDD PD-TDD-022 missing index architecture and optimized algorithms

**Scope**: Update TDD sections 4.1 (Data Models) and 4.2 (Core Operations) to document the 5 secondary indexes (`_base_path_to_keys`, `_resolved_to_keys`, `_key_to_resolved_paths`, `_basename_to_keys`, `_parser_type_extensions`) and the index-optimized `get_references_to_file()` and `update_target_path()` algorithms added in commit 6e4efa4 (2026-03-31). Also fix the abstract interface method list and section 4.4 quality attribute claims. Dims: DA (Documentation Alignment).

**Root Cause**: TDD was created during framework onboarding (PF-TSK-066, commit 6638795, 2026-02-20) documenting the original naive implementation. The index optimization was added ~6 weeks later (6e4efa4, 2026-03-31) as part of code refactoring driven by performance/correctness improvements (TD138, TD139, PD-BUG-068). The refactoring tasks that introduced the indexes did not include TDD updates in their documentation checklists — or the TDD update was marked N/A because no public API changed (only internal implementation). This is a process gap: internal algorithm changes that significantly alter the design described in a TDD should trigger a TDD update even when the public API is unchanged.

**Changes Made**:
- [x] Section 4.1: Added all 6 secondary indexes (`_source_to_targets`, `_base_path_to_keys`, `_resolved_to_keys`, `_key_to_resolved_paths`, `_basename_to_keys`) + `_parser_type_extensions` to Data Models with design decisions
- [x] Section 4.1: Added `update_source_path` and `has_target_with_basename` to interface method list
- [x] Section 4.2: Updated `get_references_to_file()` to show two-phase index-based algorithm with suffix matching and extension-aware filtering
- [x] Section 4.2: Updated `update_target_path()` to show `_base_path_to_keys` usage and index maintenance via `_remove_key_from_indexes`/`_add_key_to_indexes`
- [x] Section 4.2: Updated `add_link()` to show all index maintenance operations
- [x] Section 4.2: Updated `remove_file_links()` to show `_source_to_targets` reverse index usage
- [x] Section 4.2: Updated `update_source_path()` to include resolved-target index rebuild
- [x] Section 4.4: Replaced "no bi-directional index" and "linear scan fallback" with accurate index-based performance characteristics
- [x] Section 3.4: Updated method count from 12 to 13 and added internal helper mention
- [x] Section 6.2: Added implementation steps 10-16 for index additions

**Test Baseline**: N/A — documentation-only change, no code modified
**Test Result**: N/A

**Documentation & State Updates**:
- [x] Feature implementation state file (0.1.2) updated, or N/A: _N/A — grepped state file, TDD content details are not tracked there_
- [x] TDD (0.1.2) updated: _This IS the TDD being updated_
- [x] Test spec (0.1.2) updated, or N/A: _N/A — no behavior change, documentation only_
- [x] FDD (0.1.2) updated, or N/A: _N/A — FDD describes functional behavior, not internal index structure_
- [x] ADR updated, or N/A: _N/A — grepped ADR directory for "database" and "index", no ADR covers internal database indexes_
- [x] Validation tracking updated, or N/A: _N/A — DA dimension already flagged this in R3, fixing it resolves the finding_
- [x] Technical Debt Tracking: TD148 marked resolved via Update-TechDebt.ps1

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD148 | Complete | None | TDD PD-TDD-022 (sections 3.4, 4.1, 4.2, 4.4, 6.2) |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)

