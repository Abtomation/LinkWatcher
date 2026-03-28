---
id: PD-REF-105
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-27
updated: 2026-03-27
target_area: linkwatcher/validator.py
mode: lightweight
priority: Medium
refactoring_scope: Add target existence cache to LinkValidator
---

# Lightweight Refactoring Plan: Add target existence cache to LinkValidator

- **Target Area**: linkwatcher/validator.py
- **Priority**: Medium
- **Created**: 2026-03-27
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD085 — Add target existence cache to eliminate redundant os.path.exists() calls

**Scope**: `_target_exists()` and `_target_exists_at_root()` call `os.path.exists()` on every invocation with no deduplication. When N files reference the same target, the same path is stat'd N times. Add a `dict` cache (`_exists_cache`) on the `LinkValidator` instance, populated in `_target_exists()` / `_target_exists_at_root()` and cleared at the start of each `validate()` call so it cannot serve stale results.

**Changes Made**:
<!-- Fill in after implementation -->
- [x] Add `self._exists_cache: Dict[str, bool] = {}` in `__init__`
- [x] Clear cache at top of `validate()`
- [x] Use cache in `_target_exists()` and `_target_exists_at_root()`

**Test Baseline**: 74 passed (test_validator.py), 0 failed
**Test Result**: 74 passed (test_validator.py); 596 passed, 5 skipped, 7 xfailed (full suite)

**Documentation & State Updates**:
- [x] Feature implementation state file (6.1.1) updated, or N/A — _Grepped state file for `_target_exists` — no references_
- [x] TDD (6.1.1) updated, or N/A — _No TDD exists for 6.1.1 (Tier 1 feature)_
- [x] Test spec (6.1.1) updated, or N/A — _Grepped test specs for `_target_exists` — no references; behavior unchanged_
- [x] FDD (6.1.1) updated, or N/A — _No FDD exists for 6.1.1 (Tier 1 feature)_
- [x] ADR updated, or N/A — _Grepped ADR directory for `_target_exists` — no references; no architectural decision affected_
- [x] Validation tracking updated, or N/A — _6.1.1 Round 2 validation completed; internal cache doesn't affect validated behavior_
- [x] Technical Debt Tracking: TD085 marked resolved via Update-TechDebt.ps1

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD085 | Complete | None | None (all N/A) |

## Related Documentation
- [Technical Debt Tracking](/doc/product-docs/state-tracking/permanent/technical-debt-tracking.md)
