---
id: PF-REF-040
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-03
updated: 2026-03-03
target_area: Testing Configuration
refactoring_scope: Fix pytest.ini testpaths typo TD029
priority: Medium
mode: lightweight
---

# Lightweight Refactoring Plan: Fix pytest.ini testpaths typo TD029

- **Target Area**: Testing Configuration
- **Priority**: Medium
- **Created**: 2026-03-03
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (≤15 min effort, single file, no architectural impact)

## Item 1: TD029 — Fix pytest.ini testpaths typo

**Scope**: `pytest.ini` has `testpaths = test` but the actual test directory is `tests/`. Pytest resolves via fallback discovery, but the configuration is misleading. Change `testpaths = test` to `testpaths = tests`.

**Changes Made**:
<!-- Fill in after implementation -->
- [x] Change `testpaths = test` to `testpaths = tests` in pytest.ini line 5

**Test Baseline**: 392 passed, 5 skipped, 7 xfailed, 2 errors (pre-existing)
**Test Result**: 392 passed, 5 skipped, 7 xfailed, 2 errors (pre-existing) — identical

**Documentation & State Updates**:
- [x] Feature implementation state file updated — N/A
- [x] TDD updated — N/A (no interface/design change)
- [x] Test spec updated — N/A (no behavior change)
- [x] FDD updated — N/A (no functional change)
- [x] Technical Debt Tracking: TD029 marked resolved

**Bugs Discovered**: None

<!-- BATCH MODE: Copy the "## Item N" section above for each additional debt item in this session -->

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD029 | Complete | None | None |

## Related Documentation
- [Technical Debt Tracking](/doc/product-docs/state-tracking/permanent/technical-debt-tracking.md)
