---
id: PD-REF-054
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-03
updated: 2026-03-03
priority: Medium
mode: lightweight
refactoring_scope: Replace generic Exception with IOError in safe_file_read
target_area: linkwatcher/utils.py
---

# Lightweight Refactoring Plan: Replace generic Exception with IOError in safe_file_read

- **Target Area**: linkwatcher/utils.py
- **Priority**: Medium
- **Created**: 2026-03-03
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (≤15 min effort, single file, no architectural impact)

## Item 1: TD041 — Replace generic Exception with IOError in safe_file_read

**Scope**: Replace two `raise Exception(...)` in `safe_file_read()` (lines 252, 254) with `raise IOError(...)`. IOError is a subclass of Exception so all existing `except Exception` catch handlers (e.g., base.py:39) continue working. Docstring updated to document the specific type.

**Changes Made**:
- [x] Line 252: `raise Exception(...)` → `raise IOError(...)`
- [x] Line 254: `raise Exception(...)` → `raise IOError(...)`
- [x] Docstring: `Exception` → `IOError`

**Test Baseline**: 387 passed, 5 skipped, 7 xfailed
**Test Result**: 387 passed, 5 skipped, 7 xfailed (identical)

**Documentation & State Updates**:
- [x] Feature implementation state file updated (N/A — no feature scope change)
- [x] TDD updated (N/A — no interface/design change)
- [x] Test spec updated (N/A — no behavior change)
- [x] FDD updated (N/A — no functional change)
- [x] Technical Debt Tracking: TD041 marked resolved via Update-TechDebt.ps1

**Bugs Discovered**: None

<!-- BATCH MODE: Copy the "## Item N" section above for each additional debt item in this session -->

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD041 | Complete | None | None |

## Related Documentation
- [Technical Debt Tracking](/doc/product-docs/state-tracking/permanent/technical-debt-tracking.md)
