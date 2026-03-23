---
id: PF-REF-066
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-13
updated: 2026-03-13
priority: Medium
refactoring_scope: Fix broken pyproject.toml entry point TD054
mode: lightweight
target_area: pyproject.toml
---

# Lightweight Refactoring Plan: Fix broken pyproject.toml entry point TD054

- **Target Area**: pyproject.toml
- **Priority**: Medium
- **Created**: 2026-03-13
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (≤15 min effort, single file, no architectural impact)

## Item 1: TD054 — Fix broken pyproject.toml entry point

**Scope**: The `[project.scripts]` section references `linkwatcher.cli:main`, but `linkwatcher/cli.py` does not exist. The actual entry point is `main.py` at the project root, which is not inside the `linkwatcher` package and cannot serve as a setuptools console_scripts entry point. Fix: remove the broken `[project.scripts]` section since the application is run via `python main.py`.

**Changes Made**:
- [x] Removed `[project.scripts]` section from pyproject.toml (lines 56-57)
- [x] Updated FDD 5.1.1 (fdd-5-1-1-cicd-development-tooling.md:168) to remove broken entry point reference from 5.1.6-FR-2

**Test Baseline**: 411 passed, 5 skipped, 7 xfailed
**Test Result**: 411 passed, 5 skipped, 7 xfailed — no regressions

**Documentation & State Updates**:
- [x] Feature implementation state file (5.1.6) updated, or N/A — archive file references `cli:main` but archived files are not updated per convention: _N/A — archived state file, no update needed_
- [x] TDD (5.1.1) updated, or N/A — verified no interface/design changes documented: _N/A — grepped TDD 5.1.1, no references to cli:main or project.scripts_
- [x] Test spec (5.1.1) updated, or N/A — verified no behavior change affects spec: _N/A — grepped test spec, no references to cli:main_
- [x] FDD (5.1.1) updated: _Updated 5.1.6-FR-2 to remove broken entry point reference_
- [x] ADR updated, or N/A — verified no architectural decision affected: _N/A — grepped ADR directory, no references to cli:main or project.scripts_
- [x] Foundational validation tracking updated, or N/A: _N/A — 5.1.1 CI/CD is not a foundational feature (those are 0.x.x and 1.x.x)_
- [x] Technical Debt Tracking: TD054 marked resolved via Update-TechDebt.ps1

**Bugs Discovered**: None

<!-- BATCH MODE: Copy the "## Item N" section above for each additional debt item in this session -->

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD054 | Complete | None | FDD 5.1.1 (5.1.6-FR-2) |

## Related Documentation
- [Technical Debt Tracking](/doc/product-docs/state-tracking/permanent/technical-debt-tracking.md)
