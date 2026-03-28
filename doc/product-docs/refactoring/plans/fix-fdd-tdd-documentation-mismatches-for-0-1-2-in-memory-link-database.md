---
id: PD-REF-086
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-27
updated: 2026-03-27
refactoring_scope: Fix FDD/TDD documentation mismatches for 0.1.2 In-Memory Link Database
priority: Medium
mode: lightweight
target_area: FDD PD-FDD-023, TDD PD-TDD-022
---

# Lightweight Refactoring Plan: Fix FDD/TDD documentation mismatches for 0.1.2 In-Memory Link Database

- **Target Area**: FDD PD-FDD-023, TDD PD-TDD-022
- **Priority**: Medium
- **Created**: 2026-03-27
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD078 — Fix FDD/TDD documentation mismatches for 0.1.2 In-Memory Link Database

**Scope**: FDD PD-FDD-023 BR-5 incorrectly claims database uses its own `_normalize_path()` independent of utils.py — actually imports `normalize_path` from utils.py (database.py:16). FDD Technical Dependencies section incorrectly references `pathlib.Path` for normalization. TDD PD-TDD-022 line 67 documents "10 methods" but the interface defines 12 abstract methods — `update_source_path()` and `get_references_to_directory()` are missing from the summary (though listed in the pseudocode at lines 79-82). The `last_scan` property is also omitted from the count.

**Debt Item ID**: TD078
**Assessment Source**: PD-VAL-051 (Documentation Alignment Validation Round 2 Session 7)

**Changes Made**:
- [x] FDD BR-5 (line 81): Corrected `_normalize_path()` claim → `normalize_path()` imported from `linkwatcher/utils.py`
- [x] FDD Technical Dependencies (line 133): Replaced `pathlib` reference → `linkwatcher.utils` for `normalize_path()`
- [x] TDD method count summary (line 67): Updated from 9 to 12 methods, added `update_source_path()`, `get_references_to_directory()`, `has_target_with_basename()`, and `last_scan` property
- [x] TDD pseudocode section (~line 207): Added pseudocode for `update_source_path()` and `get_references_to_directory()` matching documentation depth of existing CRUD methods
- [x] TDD usability implementation (line 304): Updated method count from 10 to 12

**Test Baseline**: N/A — documentation-only changes, no code modified
**Test Result**: N/A — documentation-only changes

**Documentation & State Updates**:
- [x] Feature implementation state file (0.1.2) — N/A: _Grepped state file — references `normalize_path()` correctly from utils.py, no inaccuracy_
- [x] TDD (0.1.2) updated — method count corrected, pseudocode added for undocumented methods
- [x] Test spec (0.1.2) — N/A: _Grepped test spec — references `normalize_path` correctly, no behavior change_
- [x] FDD (0.1.2) updated — BR-5 and Technical Dependencies corrected
- [x] ADR (0.1.2) — N/A: _Grepped ADR — no references to normalize_path or the undocumented methods_
- [x] Validation tracking — N/A: _TD078 originated from completed PD-VAL-051 round; no active validation affected_
- [ ] Technical Debt Tracking: TD078 marked resolved

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD078 | Complete | None | FDD PD-FDD-023 (BR-5, Technical Dependencies), TDD PD-TDD-022 (method count, pseudocode, usability section) |

## Related Documentation
- [Technical Debt Tracking](/doc/product-docs/state-tracking/permanent/technical-debt-tracking.md)
