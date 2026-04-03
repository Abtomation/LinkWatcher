---
id: PD-REF-074
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-27
updated: 2026-03-27
refactoring_scope: Fix encapsulation violation in handler.py _is_known_reference_target()
mode: lightweight
target_area: database.py, handler.py
priority: Medium
---

# Lightweight Refactoring Plan: Fix encapsulation violation in handler.py _is_known_reference_target()

- **Target Area**: database.py, handler.py
- **Priority**: Medium
- **Created**: 2026-03-27
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Dependencies and Impact
- **Affected Components**: linkwatcher/database.py (ABC + concrete class), linkwatcher/handler.py (consumer)
- **Internal Dependencies**: handler.py calls link_db methods; test_database.py, test_handler.py test these modules
- **Risk Assessment**: Low — additive method on ABC with single concrete implementation; handler change is mechanical delegation

## Item 1: TD062 — Fix _is_known_reference_target() encapsulation violation

**Scope**: handler.py `_is_known_reference_target()` (lines 565-580) directly accesses `link_db._lock` and `link_db.links`, bypassing the `LinkDatabaseInterface` abstraction. Fix: add `has_target_with_basename(filename: str) -> bool` to the ABC and implement it in `LinkDatabase` with the same basename-matching logic. Then update handler to delegate to the new method.

**Changes Made**:
- [x] Add `has_target_with_basename(filename: str) -> bool` abstract method to `LinkDatabaseInterface` (database.py:87-93)
- [x] Implement `has_target_with_basename()` in `LinkDatabase` with thread-safe basename scan (database.py:400-405)
- [x] Update `handler.py:_is_known_reference_target()` to delegate to `self.link_db.has_target_with_basename(filename)` (handler.py:575-576)

**Test Baseline**: 565 passed, 5 skipped, 7 xfailed
**Test Result**: 565 passed, 5 skipped, 7 xfailed (identical)

**Documentation & State Updates**:
- [x] Feature implementation state file (0.1.2) updated, or N/A: _Grepped state file — no references to `_is_known_reference_target` or method list_
- [x] TDD (0.1.2) updated: _Updated PD-TDD-022 method count from 9 to 10, added `has_target_with_basename()` to method list (lines 67, 243)_
- [x] Test spec (0.1.2) updated, or N/A: _Grepped test spec — no references to changed method_
- [x] FDD (0.1.2) updated, or N/A: _Grepped FDD — no method list or references to changed component_
- [x] ADR (0.1.2) updated: _Updated PD-ADR-040 method list and count from 9 to 10 (lines 54, 82)_
- [x] Validation tracking updated, or N/A: _Validation round 2 already COMPLETED/PASS — this fix resolves a noted finding, no status change needed_
- [x] Technical Debt Tracking: TD062 marked resolved via Update-TechDebt.ps1

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD062 | Complete | None | TDD PD-TDD-022 (9→10 methods), ADR PD-ADR-040 (9→10 methods) |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
