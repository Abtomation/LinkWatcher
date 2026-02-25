---
id: PD-TDD-031
type: Product Documentation
category: Technical Design Document
version: 2.0
created: 2026-02-20
updated: 2026-02-20
feature_id: 5.1.1
feature_name: "CI/CD & Development Tooling"
tier: 2
retrospective: true
consolidates:
  - { id: PD-TDD-031, feature: "5.1.1 GitHub Actions CI" }
  - { id: PD-TDD-032, feature: "5.1.2 Test Automation" }
supersedes:
  - tdd-5-1-1-github-actions-ci-t2.md
  - tdd-5-1-2-test-automation-t2.md
---

# CI/CD & Development Tooling - Technical Design Document (Tier 2)

> **Retrospective Document**: This TDD describes the existing implemented architecture of the LinkWatcher CI/CD pipeline and test automation, documented after implementation during framework onboarding (PF-TSK-066).
>
> **Consolidation Scope**: This document consolidates the previously separate TDDs for GitHub Actions CI (5.1.1) and Test Automation (5.1.2) into a single unified reference. All technical requirement IDs from the original documents are preserved with their original prefixes.

## Technical Overview

The LinkWatcher CI/CD system consists of a GitHub Actions pipeline defined in `.github/workflows/ci.yml` with 5 jobs running on `windows-latest` runners, and a test automation layer that orchestrates category-based test execution within the pipeline. The pipeline uses a matrix strategy for Python 3.8-3.11, gated job dependencies, and the `run_tests.py` CLI as the bridge between CI workflow steps and the pytest-based test suite.

---

## Subsystem: GitHub Actions CI Pipeline

> Source feature: 5.1.1 GitHub Actions CI

### Pipeline Job Structure

| Job | Trigger | Dependencies | Failure Mode | Purpose |
|-----|---------|-------------|--------------|---------|
| `test` | push, PR | None | Strict (unit/parser), Soft (integration) | Matrix testing across Python 3.8-3.11 |
| `performance` | push to main only | `test` | Soft (`continue-on-error`) | Performance benchmarks with artifact upload |
| `quality` | push, PR | None | Soft (`continue-on-error`) | flake8, black, isort, mypy checks |
| `security` | push, PR | None | Soft (`continue-on-error`) | safety + bandit scans with artifact upload |
| `build` | push, PR | `test` + `quality` | Strict | `python -m build` + `twine check` |

### Test Job Execution Flow

```
checkout -> setup-python -> cache pip -> install deps -> discover -> unit+coverage -> parsers -> integration -> codecov upload (3.11 only)
```

### Setup Script

`scripts/setup_cicd.py` provides local CI environment bootstrapping:
- Validates Python version and required packages
- Installs dependencies from `requirements.txt` and `requirements-test.txt`
- Runs test discovery and quick tests to verify setup

### Key Technical Decisions (CI Pipeline)

**Windows-Only CI Pipeline**: All CI jobs run exclusively on `windows-latest`. LinkWatcher uses Windows-specific features (drive letters, UNC paths, case-insensitive matching, backslash paths). Testing on Linux/macOS would require platform abstraction that doesn't reflect actual usage. This keeps CI simple and relevant.

**Soft Failure for Non-Critical Jobs**: Integration tests, quality checks, and security scans use `continue-on-error: true`. Strict failure on all jobs would block merges for flake8 warnings or transient integration test issues. Unit and parser tests remain strict as they indicate real regressions.

**Gated Pipeline with Job Dependencies**: `performance` requires `test`; `build` requires `test` + `quality`. This prevents wasting CI minutes on builds that would fail anyway. Performance tests only run on main-branch pushes (not PRs) for faster PR feedback.

---

## Subsystem: Test Automation

> Source feature: 5.1.2 Test Automation

### CI Test Job Steps

Test automation is configured within the CI workflow (`ci.yml`) test job as a sequence of `run_tests.py` invocations. Each test category is executed as a separate workflow step with explicit CLI flags. This subsystem bridges 4.1.1 (test framework) and 5.1.1 (CI pipeline) by defining execution order, failure tolerance, and artifact collection.

| Step | Command | Failure Mode | Purpose |
|------|---------|-------------|---------|
| Test Discovery | `python run_tests.py --discover` | Strict | Verify test collection works |
| Unit Tests | `python run_tests.py --unit --coverage` | Strict | Core logic validation + coverage |
| Parser Tests | `python run_tests.py --parsers` | Strict | Parser correctness |
| Integration Tests | `python run_tests.py --integration` | Soft (`continue-on-error`) | Cross-component workflows |

### CI Performance Job Steps

| Step | Command | Failure Mode | Purpose |
|------|---------|-------------|---------|
| Performance Tests | `python run_tests.py --performance` | Soft (`continue-on-error`) | Benchmark validation |
| Artifact Upload | `actions/upload-artifact@v3` | N/A | Store performance results |

### Execution Flow

```
[test job - runs on every push/PR]
  discover -> unit+coverage -> parsers -> integration -> codecov upload

[performance job - main branch push only, gated behind test]
  performance tests -> artifact upload
```

### run_tests.py CLI Interface

The test automation relies on `run_tests.py` flags to select categories:
- `--discover`: Test collection validation
- `--unit`: Unit tests only
- `--parsers`: Parser tests only
- `--integration`: Integration tests only
- `--performance`: Performance tests only
- `--coverage`: Enable pytest-cov collection
- `--quick`: Fast subset (unit + parsers)
- `--all`: All test categories

### Key Technical Decisions (Test Automation)

**Sequential Test Category Execution**: Test categories run sequentially within a single job rather than as parallel jobs. This avoids repeated dependency installation overhead and provides ordered feedback (most stable tests first). Categories ordered: discover, unit, parsers, integration.

**Performance Tests Gated Behind Main Branch**: Performance job uses `if: github.event_name == 'push' && github.ref == 'refs/heads/main'` and `needs: [test]`. PRs get fast feedback without waiting for expensive performance benchmarks. Regressions are caught post-merge.

---

## Dependencies (Consolidated)

| Component | Usage | Subsystems |
|-----------|-------|------------|
| `run_tests.py` | Test execution entry point called by CI workflow | CI Pipeline, Test Automation |
| `.github/workflows/ci.yml` | Workflow definition containing all job and step definitions | CI Pipeline, Test Automation |
| `requirements.txt` / `requirements-test.txt` | Dependency installation in CI environment | CI Pipeline, Test Automation |
| `scripts/setup_cicd.py` | Local CI environment bootstrapping | CI Pipeline |
| `actions/checkout@v4` | Repository checkout | CI Pipeline |
| `actions/setup-python@v4` | Python version matrix setup | CI Pipeline |
| `actions/cache@v3` | Pip dependency caching | CI Pipeline |
| `actions/upload-artifact@v3` | Performance result artifact storage | Test Automation |
| `codecov/codecov-action@v3` | Coverage report upload | CI Pipeline, Test Automation |
| `pytest` / `pytest-cov` | Test execution engine and coverage collection | Test Automation |
