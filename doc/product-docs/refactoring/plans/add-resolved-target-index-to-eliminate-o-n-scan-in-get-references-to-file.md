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
target_area: linkwatcher/database.py
---

# Lightweight Refactoring Plan: Add resolved-target index to eliminate O(n) scan in get_references_to_file

- **Target Area**: linkwatcher/database.py
- **Priority**: Medium
- **Created**: 2026-03-30
- **Author**: AI Agent & Human Partner
- **Status**: Planning
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD127 — Add resolved-target index to eliminate O(n) scan in get_references_to_file

**Scope**: `get_references_to_file()` currently does an O(1) direct lookup then falls through to an O(n*m) scan of all keys and references to find anchored, relative, filename-only, and suffix matches. Add a `_resolved_target_to_keys` secondary index (populated at `add_link()` time by resolving each reference's target relative to its source file) to replace the full scan with O(1) lookups. Must maintain the index in all mutation methods: `add_link`, `remove_file_links`, `update_target_path`, `update_source_path`, `remove_targets_by_path`, `clear`.

**Debt Item ID**: TD127
**Test Baseline**: [Fill before implementation]
**Test Result**: [Fill after running tests]

**Changes Made**:
<!-- Fill in after implementation -->
- [ ] Add `_resolved_target_to_keys` dict to `__init__`
- [ ] Populate index in `add_link()` by resolving target relative to source
- [ ] Use index in `get_references_to_file()` to replace O(n) loop
- [ ] Maintain index in `remove_file_links()`
- [ ] Maintain index in `update_target_path()`
- [ ] Maintain index in `update_source_path()`
- [ ] Maintain index in `remove_targets_by_path()`
- [ ] Clear index in `clear()`
- [ ] Bonus: use `_base_path_to_keys` in `update_target_path()` and `remove_targets_by_path()` to also eliminate their O(n) scans

**Documentation & State Updates**:
- [ ] Feature implementation state file (0.1.2) updated, or N/A
- [ ] TDD (0.1.2) updated, or N/A
- [ ] Test spec (0.1.2) updated, or N/A
- [ ] FDD (0.1.2) updated, or N/A
- [ ] ADR updated, or N/A
- [ ] Validation tracking updated, or N/A
- [ ] Technical Debt Tracking: TD127 marked resolved

**Bugs Discovered**: [Fill after implementation]

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD127 | [Complete/Blocked] | [None/Yes] | [None/List] |

## Related Documentation
- [Technical Debt Tracking](/doc/product-docs/state-tracking/permanent/technical-debt-tracking.md)
