---
id: PD-TDD-031
type: Product Documentation
category: Technical Design Document
version: 2.0
created: 2026-02-20
updated: 2026-03-13
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
> **Consolidation Scope**: This document consolidates the previously separate TDDs for GitHub Actions CI (5.1.1) and Test Automation (5.1.2) into a single unified reference covering all 7 FDD subsystems (A-G): CI Pipeline, Test Automation, Code Quality Checks, Coverage Reporting, Pre-commit Hooks, Package Building, and Windows Dev Scripts. All technical requirement IDs from the original documents are preserved with their original prefixes.

## Technical Overview

The LinkWatcher CI/CD system consists of a GitHub Actions pipeline defined in `.github/workflows/ci.yml` with 5 jobs running on `windows-latest` runners, a test automation layer orchestrating category-based test execution, code quality and coverage tooling configured via `pyproject.toml`, pre-commit hooks for local quality enforcement, PEP 621 package building, and `dev.bat` as the Windows developer command interface. The pipeline uses a matrix strategy for Python 3.8-3.11, gated job dependencies, and the `run_tests.py` CLI as the bridge between CI workflow steps and the pytest-based test suite.

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
| `build` | push only (not PRs) | `test` + `quality` | Strict | `python -m build` + `twine check` |

### Test Job Execution Flow

```
checkout -> setup-python -> cache pip -> install deps -> discover -> unit+coverage -> parsers -> integration -> codecov upload (3.11 only)
```

### Setup Script

`scripts/setup_cicd.py` provides local CI environment bootstrapping:
- Validates that Python is installed and required tools are available
- Installs dependencies from `requirements.txt` and test extras via `pip install ".[test]"` (pyproject.toml `[project.optional-dependencies] test`)
- Runs test discovery and quick tests to verify setup

### Key Technical Decisions (CI Pipeline)

**Windows-Only CI Pipeline**: All CI jobs run exclusively on `windows-latest`. LinkWatcher uses Windows-specific features (drive letters, UNC paths, case-insensitive matching, backslash paths). Testing on Linux/macOS would require platform abstraction that doesn't reflect actual usage. This keeps CI simple and relevant.

**Soft Failure for Non-Critical Jobs**: Integration tests, quality checks, and security scans use `continue-on-error: true`. Strict failure on all jobs would block merges for flake8 warnings or transient integration test issues. Unit and parser tests remain strict as they indicate real regressions.

**Gated Pipeline with Job Dependencies**: `performance` requires `test`; `build` requires `test` + `quality`. Both `performance` and `build` only run on push events (not PRs) — `performance` is further restricted to main branch via `if: github.event_name == 'push' && github.ref == 'refs/heads/main'`, while `build` runs on any push via `if: github.event_name == 'push'`. This prevents wasting CI minutes on builds that would fail anyway and gives PRs faster feedback.

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
- `--performance`: Performance tests only (filtered to `@pytest.mark.slow` marker)
- `--coverage`: Enable pytest-cov collection
- `--quick`: Fast subset (unit + parsers)
- `--all`: All test categories

### Key Technical Decisions (Test Automation)

**Sequential Test Category Execution**: Test categories run sequentially within a single job rather than as parallel jobs. This avoids repeated dependency installation overhead and provides ordered feedback (most stable tests first). Categories ordered: discover, unit, parsers, integration.

**Performance Tests Gated Behind Main Branch**: Performance job uses `if: github.event_name == 'push' && github.ref == 'refs/heads/main'` and `needs: [test]`. PRs get fast feedback without waiting for expensive performance benchmarks. Regressions are caught post-merge.

---

## Subsystem: Code Quality Checks

> Source feature: 5.1.3 Code Quality Checks

### CI Quality Job

The `quality` job runs on every push and PR, independent of other jobs (no `needs` dependencies). It executes 4 static analysis tools sequentially on Python 3.11:

| Step | Tool | Command | Configuration Source |
|------|------|---------|---------------------|
| Linting | flake8 | `flake8 linkwatcher tests --max-line-length=100 --extend-ignore=E203,W503` | CLI args (mirrors pyproject.toml intent) |
| Format check | black | `black --check linkwatcher tests` | `pyproject.toml [tool.black]` |
| Import order | isort | `isort --check-only linkwatcher tests` | `pyproject.toml [tool.isort]` |
| Type checking | mypy | `mypy linkwatcher --ignore-missing-imports` | `pyproject.toml [tool.mypy]` |

Linting and format checks run as a single step (combined `run:` block); type checking runs as a separate step. Both steps use `continue-on-error: true`.

### Tool Configuration Centralization

All tool settings are centralized in `pyproject.toml`:

| Tool | Config Section | Key Settings |
|------|---------------|-------------|
| black | `[tool.black]` | `line-length = 100`, `target-version = ['py38', 'py39', 'py310', 'py311']` |
| isort | `[tool.isort]` | `profile = "black"`, `line_length = 100`, `multi_line_output = 3`, `include_trailing_comma = true` |
| mypy | `[tool.mypy]` | `python_version = "3.8"`, strict mode (`disallow_untyped_defs`, `warn_return_any`, `strict_equality`, etc.) |
| flake8 | CLI args only | `--max-line-length=100 --extend-ignore=E203,W503` (flake8 does not support pyproject.toml natively) |

### Local Quality Execution

`dev.bat` provides local equivalents of the CI quality job:
- `dev lint` — runs flake8, black `--check`, and isort `--check-only`
- `dev format` — runs black and isort (applies formatting)
- `dev type-check` — runs mypy with `--ignore-missing-imports`

### Key Technical Decisions (Code Quality)

**Soft Failure for All Quality Steps**: Both the linting/format step and the type-checking step use `continue-on-error: true`. Quality violations are reported but don't block merges, preventing flake8 warnings or mypy strictness issues from gating unrelated changes.

**isort "black" Profile**: isort is configured with `profile = "black"` to ensure its import formatting is compatible with black's formatting decisions, avoiding conflicts between the two tools.

**Strict mypy Configuration**: mypy runs with `disallow_untyped_defs`, `disallow_incomplete_defs`, `disallow_untyped_decorators`, `no_implicit_optional`, `warn_unreachable`, and `strict_equality`. This catches type errors early despite the soft CI failure mode.

---

## Subsystem: Coverage Reporting

> Source feature: 5.1.4 Coverage Reporting

### Coverage Toolchain

Coverage flows through a 3-tool chain: `pytest-cov` (pytest plugin) → `coverage.py` (measurement engine) → `codecov/codecov-action@v3` (cloud upload).

```
pytest --cov=linkwatcher → .coverage file → coverage.xml → codecov-action upload
```

### Coverage Configuration

Coverage is configured in `pyproject.toml` under two sections:

**`[tool.coverage.run]`**:
- `source = ["linkwatcher"]` — limits measurement to production code
- `omit = ["*/tests/*", "*/test_*"]` — excludes test files from coverage measurement

**`[tool.coverage.report]`**:
Excludes lines matching these patterns from coverage calculation:
- `pragma: no cover` — explicit exclusion marker
- `def __repr__` — debug representation methods
- `if self.debug:` / `if settings.DEBUG` — debug-only code paths
- `raise AssertionError` / `raise NotImplementedError` — intentional failure points
- `if 0:` / `if __name__ == .__main__.:` — unreachable/entry-point guards
- `class .*\bProtocol\):` — typing Protocol definitions
- `@(abc\.)?abstractmethod` — abstract method declarations

### CI Coverage Integration

Coverage upload occurs in the `test` job, gated to a single Python version:

```yaml
- name: Upload coverage to Codecov
  if: matrix.python-version == '3.11'
  uses: codecov/codecov-action@v3
  with:
    file: ./coverage.xml
    flags: unittests
    fail_ci_if_error: false
```

### Local Coverage

`dev.bat coverage` runs `python run_tests.py --coverage`, which generates an HTML report in `htmlcov/`.

### Key Technical Decisions (Coverage)

**Single Python Version Upload**: Coverage uploads only on the Python 3.11 matrix slot (`if: matrix.python-version == '3.11'`). Uploading from all 4 matrix slots would create duplicate or conflicting coverage reports on Codecov.

**Non-Blocking Upload**: `fail_ci_if_error: false` ensures Codecov API outages don't fail the CI pipeline.

---

## Subsystem: Pre-commit Hooks

> Source feature: 5.1.5 Pre-commit Hooks

### Hook Configuration

`.pre-commit-config.yaml` defines 5 hook repositories:

| Repository | Version | Hooks | Purpose |
|-----------|---------|-------|---------|
| `pre-commit/pre-commit-hooks` | v4.4.0 | trailing-whitespace, end-of-file-fixer, check-yaml, check-json, check-merge-conflict, check-added-large-files, debug-statements | General file hygiene (7 hooks) |
| `psf/black` | 23.7.0 | black (`--line-length=100`) | Code formatting |
| `pycqa/isort` | 5.12.0 | isort (`--profile=black`, `--line-length=100`) | Import ordering |
| `pycqa/flake8` | 6.0.0 | flake8 (`--max-line-length=100`, `--extend-ignore=E203,W503`) | Linting |
| local | — | pytest-quick | Quick test execution |

### Local pytest-quick Hook

```yaml
- repo: local
  hooks:
    - id: pytest-quick
      name: pytest-quick
      entry: python run_tests.py --quick
      language: system
      pass_filenames: false
      always_run: true
      stages: [commit]
```

This hook runs `run_tests.py --quick` (unit + parser tests) on every commit via `always_run: true`. It uses `language: system` (no isolated virtualenv) and `pass_filenames: false` (runs full test suite, not per-file).

### Installation

Pre-commit hooks are installed via two mechanisms:
- `dev.bat pre-commit` — runs `python -m pre_commit install` and `python -m pre_commit install --hook-type commit-msg`
- `dev.bat dev-setup` — calls `install-dev` then `pre-commit` targets
- `scripts/setup_cicd.py` — also installs pre-commit hooks during CI environment bootstrapping

### Key Technical Decisions (Pre-commit)

**CI-Mirroring Hook Strategy**: Pre-commit hooks mirror the CI quality job tools (black, isort, flake8) with identical arguments. This catches formatting and linting issues before they reach the CI pipeline, reducing feedback loop time from minutes (CI) to seconds (local hook).

**Quick Tests on Every Commit**: The local pytest-quick hook runs unit and parser tests on every commit (`always_run: true`). This prevents broken code from entering version control at the cost of ~10-30 seconds per commit.

---

## Subsystem: Package Building

> Source feature: 5.1.6 Package Building

### Build System Configuration

`pyproject.toml` defines the build system using PEP 621:

```toml
[build-system]
requires = ["setuptools>=61.0", "wheel"]
build-backend = "setuptools.build_meta"
```

### Package Metadata

| Field | Value |
|-------|-------|
| name | linkwatcher |
| version | 2.0.0 |
| requires-python | >=3.8 |
| license | MIT |
| build-backend | setuptools.build_meta |

### Dependency Groups

| Group | Section | Packages |
|-------|---------|----------|
| Runtime | `[project.dependencies]` | watchdog>=6.0.0, PyYAML>=6.0, colorama>=0.4.6, structlog>=21.0.0 |
| Test | `[project.optional-dependencies] test` | pytest, pytest-cov, pytest-mock, pytest-xdist, pytest-timeout, coverage, factory-boy, freezegun, responses |
| Dev | `[project.optional-dependencies] dev` | black, isort, flake8, mypy, pre-commit |

### Package Discovery

```toml
[tool.setuptools.packages.find]
where = ["."]
include = ["linkwatcher*"]

[tool.setuptools.package-data]
linkwatcher = ["config/*.yaml", "config/*.json"]
```

### CI Build Job

The `build` job is gated behind `test` + `quality` jobs and only runs on push events (not PRs):

```yaml
build:
  needs: [test, quality]
  if: github.event_name == 'push'
  steps:
    - python -m build        # Creates sdist + wheel in dist/
    - twine check dist/*     # Validates package metadata
    - upload-artifact@v3     # Stores dist/ as CI artifact
```

### Local Build

`dev.bat build` calls `dev.bat clean` first (removes build/, dist/, *.egg-info, __pycache__, .pytest_cache, .coverage, htmlcov), then runs `python -m build`.

### Key Technical Decisions (Package Building)

**PEP 621 as Sole Configuration**: `pyproject.toml` is the only package configuration file. Legacy `setup.py` and `Makefile` were removed (TD039, TD040) to eliminate duplication.

**Gated Build Job**: The build job requires both `test` and `quality` to pass. This prevents building packages from code that fails tests or quality checks. Combined with `if: github.event_name == 'push'`, PRs get faster feedback without unnecessary build steps.

---

## Subsystem: Windows Dev Scripts

> Source feature: 5.1.7 Windows Dev Scripts

### dev.bat Architecture

`dev.bat` is a Windows batch file using goto-label routing for command dispatch:

```batch
if "%1"=="test" goto test
if "%1"=="lint" goto lint
...
:test
python run_tests.py --quick
goto end
```

### Command Set

| Command | Category | Delegates To | Purpose |
|---------|----------|-------------|---------|
| `dev install` | Setup | `pip install -r requirements.txt` | Install runtime deps |
| `dev install-dev` | Setup | `pip install -r requirements.txt` + `pip install ".[test]"` + `pip install -e ".[dev]"` | Install all deps |
| `dev test` | Testing | `python run_tests.py --quick` | Quick tests (unit + parsers) |
| `dev test-quick` | Testing | `python run_tests.py --unit --parsers` | Quick dev tests |
| `dev test-all` | Testing | `python run_tests.py --all` | All test categories |
| `dev coverage` | Testing | `python run_tests.py --coverage` | Tests with HTML coverage |
| `dev lint` | Quality | flake8 + black --check + isort --check-only | Linting checks |
| `dev format` | Quality | black + isort | Apply formatting |
| `dev type-check` | Quality | `mypy linkwatcher --ignore-missing-imports` | Type checking |
| `dev clean` | Build | rmdir/del commands | Remove build artifacts |
| `dev build` | Build | clean + `python -m build` | Build package |
| `dev pre-commit` | CI/CD | `python -m pre_commit install` (2 hook types) | Install git hooks |
| `dev ci-test` | CI/CD | run_tests.py: discover → unit+coverage → parsers → integration | Local CI simulation |
| `dev dev-setup` | CI/CD | install-dev + pre-commit | Full dev environment setup |

### Key Technical Decisions (Windows Dev Scripts)

**Batch File as Canonical Interface**: `dev.bat` uses Windows CMD-native goto-label routing rather than PowerShell or cross-platform scripts. This ensures zero-dependency execution on any Windows machine with Python installed — no PowerShell version requirements, no bash/WSL dependency.

**Delegation to run_tests.py**: Testing commands delegate to `run_tests.py` rather than invoking pytest directly. This centralizes test category definitions (--unit, --parsers, --integration, --performance) and ensures CI and local dev use identical test selection logic.

---

## Dependencies (Consolidated)

| Component | Usage | Subsystems |
|-----------|-------|------------|
| `run_tests.py` | Test execution entry point called by CI workflow and dev.bat | CI Pipeline, Test Automation, Windows Dev Scripts |
| `.github/workflows/ci.yml` | Workflow definition containing all job and step definitions | CI Pipeline, Test Automation, Code Quality, Coverage, Package Building |
| `requirements.txt` | Runtime dependency installation in CI environment | CI Pipeline, Test Automation |
| `pyproject.toml` | Package metadata, build system, tool configs, dependency groups | CI Pipeline, Test Automation, Code Quality, Coverage, Package Building |
| `scripts/setup_cicd.py` | Local CI environment bootstrapping and pre-commit installation | CI Pipeline, Pre-commit Hooks |
| `actions/checkout@v4` | Repository checkout | CI Pipeline |
| `actions/setup-python@v4` | Python version matrix setup | CI Pipeline |
| `actions/cache@v3` | Pip dependency caching | CI Pipeline |
| `actions/upload-artifact@v3` | Artifact storage for performance results, security reports, dist packages | Test Automation, Package Building |
| `codecov/codecov-action@v3` | Coverage report upload | Coverage Reporting |
| `pytest` / `pytest-cov` | Test execution engine and coverage collection | Test Automation, Coverage Reporting |
| `.pre-commit-config.yaml` | Git hook definitions for 5 hook repositories | Pre-commit Hooks |
| `dev.bat` | Windows command router delegating to Python tools and run_tests.py | Windows Dev Scripts, Pre-commit Hooks |
| `flake8` / `black` / `isort` / `mypy` | Static analysis and formatting tools | Code Quality, Pre-commit Hooks |
| `build` / `twine` | Package building and validation | Package Building |
| `safety` / `bandit` | Dependency and code security scanning | CI Pipeline |
