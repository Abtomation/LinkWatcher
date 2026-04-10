---
id: PD-REF-168
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-09
updated: 2026-04-09
priority: Medium
target_area: LinkValidator
mode: lightweight
refactoring_scope: Extract _should_check_target guard clauses into predicate list
---

# Lightweight Refactoring Plan: Extract _should_check_target guard clauses into predicate list

- **Target Area**: LinkValidator
- **Priority**: Medium
- **Created**: 2026-04-09
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD184 — Extract _should_check_target guard clauses into predicate list

**Scope**: Refactor `_should_check_target()` in `linkwatcher/validator.py:416-485` from 12+ sequential if/return guard clauses into a tuple of `(predicate_fn, description)` pairs iterated by a single `any()` loop. Reduces cyclomatic complexity from ~13 to ~2 while preserving identical behavior. No interface changes — method signature, return values, and call sites unchanged.

**Changes Made**:
<!-- Fill in after implementation -->
- [x] Extract guard clauses into `_TARGET_SKIP_PREDICATES` tuple of `(callable, str)` at module level
- [x] Rewrite `_should_check_target()` to iterate predicates with `any()`

**Test Baseline**: 757 passed, 0 failed, 5 skipped, 4 deselected, 4 xfailed
**Test Result**: 758 passed, 0 failed, 5 skipped, 4 deselected, 4 xfailed (+1 from new plan file detected by test)

**Documentation & State Updates**:
- [x] Feature implementation state file (6.1.1) updated, or N/A — _Tier 1 feature — no design documents exist for 6.1.1 Link Validation. State file not updated as this is an internal refactoring with no status change._
- [x] TDD (6.1.1) updated, or N/A — _Tier 1 feature — no design documents exist for 6.1.1 Link Validation._
- [x] Test spec (6.1.1) updated, or N/A — _Tier 1 feature — no design documents exist for 6.1.1 Link Validation._
- [x] FDD (6.1.1) updated, or N/A — _Tier 1 feature — no design documents exist for 6.1.1 Link Validation._
- [x] ADR (6.1.1) updated, or N/A — _Tier 1 feature — no design documents exist for 6.1.1 Link Validation._
- [x] Validation tracking updated, or N/A — _No active validation round for 6.1.1._
- [ ] Technical Debt Tracking: TD184 marked resolved

**Bugs Discovered**: None

<!-- BATCH MODE: Copy the "## Item N" section above for each additional debt item in this session -->

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD184 | Complete | None | None (Tier 1 — no design docs) |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
