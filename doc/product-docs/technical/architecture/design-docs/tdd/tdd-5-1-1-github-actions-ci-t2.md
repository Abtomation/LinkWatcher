---
id: PD-TDD-031
type: Product Documentation
category: Technical Design Document
version: 1.0
created: 2026-02-20
updated: 2026-02-20
feature_id: 5.1.1
feature_name: GitHub Actions CI
tier: 2
retrospective: true
---

# GitHub Actions CI - Technical Design Document (Tier 2)

> **Retrospective Document**: This TDD describes the existing implemented architecture of the LinkWatcher GitHub Actions CI pipeline, documented after implementation during framework onboarding (PF-TSK-066).
>
> **Source**: Derived from [5.1.1 Implementation State](../../../../process-framework/state-tracking/features/5.1.1-github-actions-ci-implementation-state.md) and source code analysis.

## Technical Overview

The CI/CD pipeline is defined in `.github/workflows/ci.yml` and consists of 5 jobs running on `windows-latest` runners. Jobs use a matrix strategy for Python 3.8–3.11 in the test job, with gated dependencies between jobs. The pipeline leverages standard GitHub Actions (`actions/checkout@v4`, `actions/setup-python@v4`, `actions/cache@v3`) and external services (Codecov).

## Component Architecture

### Pipeline Job Structure

| Job | Trigger | Dependencies | Failure Mode | Purpose |
|-----|---------|-------------|--------------|---------|
| `test` | push, PR | None | Strict (unit/parser), Soft (integration) | Matrix testing across Python 3.8–3.11 |
| `performance` | push to main only | `test` | Soft (`continue-on-error`) | Performance benchmarks with artifact upload |
| `quality` | push, PR | None | Soft (`continue-on-error`) | flake8, black, isort, mypy checks |
| `security` | push, PR | None | Soft (`continue-on-error`) | safety + bandit scans with artifact upload |
| `build` | push, PR | `test` + `quality` | Strict | `python -m build` + `twine check` |

### Test Job Execution Flow

```
checkout → setup-python → cache pip → install deps → discover → unit+coverage → parsers → integration → codecov upload (3.11 only)
```

### Setup Script

`scripts/setup_cicd.py` provides local CI environment bootstrapping:
- Validates Python version and required packages
- Installs dependencies from `requirements.txt` and `requirements-test.txt`
- Runs test discovery and quick tests to verify setup

## Key Technical Decisions

### Windows-Only CI Pipeline

All CI jobs run exclusively on `windows-latest`. LinkWatcher uses Windows-specific features (drive letters, UNC paths, case-insensitive matching, backslash paths). Testing on Linux/macOS would require platform abstraction that doesn't reflect actual usage. This keeps CI simple and relevant.

### Soft Failure for Non-Critical Jobs

Integration tests, quality checks, and security scans use `continue-on-error: true`. Strict failure on all jobs would block merges for flake8 warnings or transient integration test issues. Unit and parser tests remain strict as they indicate real regressions.

### Gated Pipeline with Job Dependencies

`performance` requires `test`; `build` requires `test` + `quality`. This prevents wasting CI minutes on builds that would fail anyway. Performance tests only run on main-branch pushes (not PRs) for faster PR feedback.

## Dependencies

| Component | Usage |
|-----------|-------|
| `run_tests.py` | Test execution entry point called by CI workflow |
| `requirements.txt` / `requirements-test.txt` | Dependency installation in CI environment |
| `actions/checkout@v4` | Repository checkout |
| `actions/setup-python@v4` | Python version matrix setup |
| `actions/cache@v3` | Pip dependency caching |
| `codecov/codecov-action@v3` | Coverage report upload |
