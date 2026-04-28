---
id: PD-REF-088
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-27
updated: 2026-03-27
mode: lightweight
priority: Medium
refactoring_scope: Add empty link_target guard to add_link()
target_area: src/linkwatcher/database.py
---

# Lightweight Refactoring Plan: Add empty link_target guard to add_link()

- **Target Area**: src/linkwatcher/database.py
- **Priority**: Medium
- **Created**: 2026-03-27
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD074 — Add empty link_target guard to add_link()

**Scope**: Add an early return guard in `LinkDatabase.add_link()` when `reference.link_target` is empty/falsy. Without this, an empty string gets normalized and inserted as a key in `self.links`, creating a phantom entry that pollutes lookups.

**Changes Made**:
<!-- Fill in after implementation -->
- [x] Add `if not reference.link_target: return` guard at top of `add_link()` before acquiring lock

**Test Baseline**: 592 passed, 5 skipped, 7 xfailed
**Test Result**: 592 passed, 5 skipped, 7 xfailed (no change)

**Documentation & State Updates**:
- [x] Feature implementation state file (0.1.2) updated, or N/A — _Grepped state file for "add_link" — mentions it in API list but no internal detail that needs updating for an input guard_
- [x] TDD (0.1.2) updated, or N/A — _Grepped TDD-022 for "add_link" — documents API signature and threading semantics, not internal validation guards; no interface change_
- [x] Test spec (0.1.2) updated, or N/A — _Grepped test-spec for "add_link" — tests cover normal add_link behavior; guard is defensive for edge case not currently exercised by callers_
- [x] FDD (0.1.2) updated, or N/A — _Grepped FDD-023 for "add_link" — describes user-facing scan flow; internal guard is implementation detail_
- [x] ADR updated, or N/A — _Grepped ADR directory for "add_link" — target-indexed ADR documents storage strategy and threading, not input validation_
- [x] Validation tracking updated, or N/A — _0.1.2 tracked in validation-tracking-2 but all dimensions completed; trivial guard doesn't affect validation scores_
- [x] Technical Debt Tracking: TD074 marked resolved via Update-TechDebt.ps1

**Bugs Discovered**: None

<!-- BATCH MODE: Copy the "## Item N" section above for each additional debt item in this session -->

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD074 | Complete | None | None |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
