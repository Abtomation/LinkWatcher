---
id: PF-REF-065
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-13
updated: 2026-03-13
target_area: CI/CD Pipeline
priority: Medium
refactoring_scope: Remove non-existent requirements-test.txt from CI pipeline, use pyproject.toml test extras instead
mode: lightweight
---

# Lightweight Refactoring Plan: Remove non-existent requirements-test.txt from CI pipeline, use pyproject.toml test extras instead

- **Target Area**: CI/CD Pipeline
- **Priority**: Medium
- **Created**: 2026-03-13
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (≤15 min effort, single file, no architectural impact)

## Item 1: TD053 — Remove non-existent requirements-test.txt from CI pipeline

**Scope**: CI pipeline (.github/workflows/ci.yml) references `requirements-test.txt` which doesn't exist. The `pip install -r requirements-test.txt` step silently fails. Test dependencies are already defined in `pyproject.toml [project.optional-dependencies] test`. Replace with `pip install ".[test]"` in both the `test` and `performance` jobs. Also update the pip cache key from `requirements*.txt` to `pyproject.toml`.

**Changes Made**:
- [x] Replace `pip install -r requirements-test.txt` with `pip install ".[test]"` in `test` job (ci.yml line 39)
- [x] Replace `pip install -r requirements-test.txt` with `pip install ".[test]"` in `performance` job (ci.yml line 82)
- [x] Update pip cache key hash from `requirements*.txt` to `pyproject.toml` (ci.yml line 31)
- [x] Replace `pip install -r requirements-test.txt` with `pip install ".[test]"` in dev.bat install-dev target (line 57)
- [x] Replace `pip install -r requirements-test.txt` with `pip install ".[test]"` in scripts/setup_cicd.py install step (line 66)
- [x] Remove `requirements-test.txt` from required_files validation list in scripts/setup_cicd.py (line 113) — was duplicate of existing pyproject.toml entry
- [x] Replace `pip install -r requirements-test.txt` with `pip install ".[test]"` in CONTRIBUTING.md manual setup (line 37)
- [x] Replace `pip install -r requirements-test.txt` with `pip install ".[test]"` in tests/README.md quick start (line 86)

**Test Baseline**: 411 passed, 5 skipped, 7 xfailed
**Test Result**: 411 passed, 5 skipped, 7 xfailed — no change

**Documentation & State Updates**:
- [x] Feature implementation state file (5.1.1) updated, or N/A — _N/A: no feature state file exists for 5.1.1 (only archive versions)_
- [x] TDD (PD-TDD-031) updated — removed TD053 notes about missing requirements-test.txt, updated dependency table and setup script description
- [x] Test spec (PF-TSP-043) updated, or N/A — _N/A: grepped test spec — no references to requirements-test.txt or CI install steps_
- [x] FDD (PD-FDD-032) updated, or N/A — _N/A: grepped FDD — no references to requirements-test.txt_
- [x] ADR updated, or N/A — _N/A: grepped ADR directory — no references to requirements-test.txt_
- [x] Foundational validation tracking (5.1.1) updated — TD053 entry to be marked resolved
- [x] Technical Debt Tracking: TD053 marked resolved

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD053 | Complete | None | TDD PD-TDD-031 updated |

## Related Documentation
- [Technical Debt Tracking](/doc/product-docs/state-tracking/permanent/technical-debt-tracking.md)
