---
id: PD-REF-052
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-03
updated: 2026-03-03
refactoring_scope: Remove duplicate setup.py (TD040)
target_area: Project packaging
mode: lightweight
priority: Medium
---

# Lightweight Refactoring Plan: Remove duplicate setup.py (TD040)

- **Target Area**: Project packaging
- **Priority**: Medium
- **Created**: 2026-03-03
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (≤15 min effort, single file, no architectural impact)

## Item 1: TD040 — Remove duplicate setup.py

**Scope**: `setup.py` duplicates all metadata already declared in `pyproject.toml` (name, version, deps, entry points, package data). Modern pip/build tooling uses `pyproject.toml` exclusively when a `[build-system]` table is present. Delete `setup.py`, remove its reference from `scripts/setup_cicd.py` required-files list, and remove the `"setup.py"` entry from `[tool.coverage.run] omit` in `pyproject.toml`.

**Changes Made**:
- [x] Deleted `setup.py` (73 lines)
- [x] Removed `"setup.py"` from `scripts/setup_cicd.py:112` required_files list
- [x] Removed `"setup.py"` from `[tool.coverage.run] omit` in `pyproject.toml:118`

**Test Baseline**: 387 passed, 5 skipped, 7 xfailed
**Test Result**: 387 passed, 5 skipped, 7 xfailed (identical)

**Documentation & State Updates**:
- [x] Feature implementation state file updated — N/A (no feature boundary change)
- [x] TDD updated — N/A (no interface/design change)
- [x] Test spec updated — N/A (no behavior change)
- [x] FDD updated — N/A (no functional change)
- [x] Technical Debt Tracking: TD040 marked resolved

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD040 | Complete | None | None |

## Related Documentation
- [Technical Debt Tracking](/doc/product-docs/state-tracking/permanent/technical-debt-tracking.md)
