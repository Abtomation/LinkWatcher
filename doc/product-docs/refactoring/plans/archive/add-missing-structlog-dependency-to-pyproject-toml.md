---
id: PD-REF-055
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-04
updated: 2026-03-04
target_area: pyproject.toml
refactoring_scope: Add missing structlog dependency to pyproject.toml
mode: lightweight
priority: Medium
---

# Lightweight Refactoring Plan: Add missing structlog dependency to pyproject.toml

- **Target Area**: pyproject.toml
- **Priority**: Medium
- **Created**: 2026-03-04
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (≤15 min effort, single file, no architectural impact)

## Item 1: TD043 — Add missing structlog dependency to pyproject.toml

**Scope**: `structlog` is imported in `linkwatcher/logging.py` (line 21) and used extensively (17 references) but is not declared in `pyproject.toml` `[project.dependencies]`. This means a clean `pip install linkwatcher` in a fresh environment will fail with `ModuleNotFoundError`. Fix: add `structlog>=21.0.0` to the dependencies list.

**Changes Made**:
- [x] Add `"structlog>=21.0.0"` to `[project.dependencies]` in `pyproject.toml`

**Test Baseline**: 387 passed, 5 skipped, 7 xfailed
**Test Result**: 387 passed, 5 skipped, 7 xfailed (identical)

**Documentation & State Updates**:
- [x] Feature implementation state file updated (N/A — packaging fix only)
- [x] TDD updated (N/A — no interface/design change)
- [x] Test spec updated (N/A — no behavior change)
- [x] FDD updated (N/A — no functional change)
- [x] Technical Debt Tracking: TD043 marked resolved via Update-TechDebt.ps1

**Bugs Discovered**: None

<!-- BATCH MODE: Copy the "## Item N" section above for each additional debt item in this session -->

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD043 | Complete | None | None |

## Related Documentation
- [Technical Debt Tracking](/doc/product-docs/state-tracking/permanent/technical-debt-tracking.md)
