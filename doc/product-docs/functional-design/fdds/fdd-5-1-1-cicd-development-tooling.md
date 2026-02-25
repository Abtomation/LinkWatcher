---
id: PD-FDD-032
type: Product Documentation
category: Functional Design Document
version: 1.0
created: 2026-02-20
updated: 2026-02-20
feature_id: 5.1.1
feature_name: CI/CD & Development Tooling
retrospective: true
consolidation_note: >
  Merged document. Replaces PD-FDD-032 (GitHub Actions CI) and PD-FDD-033
  (Test Automation). Also covers old features 5.1.3 (Code Quality Checks),
  5.1.4 (Coverage Reporting), 5.1.5 (Pre-commit Hooks), 5.1.6 (Package Building),
  and 5.1.7 (Windows Dev Scripts) which had no separate FDDs.
---

# CI/CD & Development Tooling - Functional Design Document

> **Retrospective Document**: This FDD describes the existing implemented functionality of the LinkWatcher CI/CD pipeline, test automation, code quality tooling, coverage reporting, pre-commit hooks, package building, and Windows development scripts. Documented after implementation during framework onboarding (PF-TSK-066).
>
> **Consolidation**: Merges the former PD-FDD-032 (GitHub Actions CI) and PD-FDD-033 (Test Automation), and adds functional requirements for old features 5.1.3 (Code Quality Checks), 5.1.4 (Coverage Reporting), 5.1.5 (Pre-commit Hooks), 5.1.6 (Package Building), and 5.1.7 (Windows Dev Scripts) which previously had no FDDs.
>
> **Source**: Derived from implementation state files (5.1.1 through 5.1.7), [CI_CD_IMPLEMENTATION_SUMMARY.md](../../../../CI_CD_IMPLEMENTATION_SUMMARY.md), and source code analysis.

## Feature Overview

- **Feature ID**: 5.1.1
- **Feature Name**: CI/CD & Development Tooling
- **Business Value**: Provides a complete automated development lifecycle — CI pipeline, test automation, code quality enforcement, coverage tracking, pre-commit hooks, package building, and developer convenience scripts — ensuring code quality is maintained on every push and PR while keeping local development efficient.
- **User Story**: As a developer, I want an automated CI/CD pipeline with integrated code quality checks, test execution, coverage reporting, pre-commit hooks, and convenient dev scripts so that quality is enforced automatically and local development is frictionless.

## Subsystem A: CI Pipeline

_GitHub Actions workflow definition and CI job orchestration._

### Functional Requirements

#### Core Functionality

- **5.1.1-FR-1**: The system SHALL provide a GitHub Actions workflow (`.github/workflows/ci.yml`) triggered on every push and pull request
- **5.1.1-FR-2**: The system SHALL run test suites across a Python version matrix (3.8, 3.9, 3.10, 3.11) on `windows-latest` runners
- **5.1.1-FR-3**: The system SHALL provide 5 CI jobs: `test` (matrix testing), `performance` (gated, main-branch only), `quality` (flake8/black/isort/mypy), `security` (safety/bandit), and `build` (package build + twine check)
- **5.1.1-FR-4**: The system SHALL upload code coverage reports to Codecov on Python 3.11 runs
- **5.1.1-FR-5**: The system SHALL provide a setup script (`scripts/setup_cicd.py`) for local CI environment bootstrapping

#### Business Rules

- **5.1.1-BR-1**: All CI jobs run exclusively on `windows-latest` — LinkWatcher is a Windows-focused tool
- **5.1.1-BR-2**: Performance tests only run on pushes to main branch (not on PRs) to preserve fast PR feedback
- **5.1.1-BR-3**: `build` job is gated behind `test` + `quality` — no package build without passing prerequisites
- **5.1.1-BR-4**: Integration tests, quality checks, and security scans use `continue-on-error: true` (soft failures) — non-blocking but visible

#### Acceptance Criteria

- **5.1.1-AC-1**: CI workflow triggers on all pushes and pull requests
- **5.1.1-AC-2**: Matrix testing passes on Python 3.8-3.11 on Windows
- **5.1.1-AC-3**: Coverage reports upload to Codecov successfully
- **5.1.1-AC-4**: Package build and twine check succeed when gating jobs pass

## Subsystem B: Test Automation

_Defines which test categories run in CI, their execution order, and failure tolerance._

### Functional Requirements

#### Core Functionality

- **5.1.2-FR-1**: The system SHALL execute test categories sequentially in CI: discover -> unit (with coverage) -> parsers -> integration
- **5.1.2-FR-2**: The system SHALL gate performance tests behind the `test` job and restrict them to main-branch pushes only
- **5.1.2-FR-3**: The system SHALL apply `continue-on-error: true` to integration and performance test steps for soft failure tolerance
- **5.1.2-FR-4**: The system SHALL upload performance test results as CI artifacts for trend analysis
- **5.1.2-FR-5**: The system SHALL use `run_tests.py` CLI flags (`--discover`, `--unit --coverage`, `--parsers`, `--integration`, `--performance`) for category selection

#### Business Rules

- **5.1.2-BR-1**: Test categories are ordered by reliability: discover -> unit -> parsers -> integration (most stable first for early feedback)
- **5.1.2-BR-2**: Integration test soft failures do not block PR merges — visibility without blocking
- **5.1.2-BR-3**: Performance tests are expensive and only needed for main branch validation — PRs skip them for faster feedback

#### Acceptance Criteria

- **5.1.2-AC-1**: All 4 test categories execute sequentially in CI test job
- **5.1.2-AC-2**: Performance tests only trigger on main branch pushes
- **5.1.2-AC-3**: Integration test failures don't block CI pipeline completion
- **5.1.2-AC-4**: Performance result artifacts are uploaded and accessible

## Subsystem C: Code Quality Checks

_Static analysis and formatting tooling configuration._

### Functional Requirements

#### Core Functionality

- **5.1.3-FR-1**: The system SHALL provide a CI `quality` job that runs flake8 (linting, max-line-length=100, E203/W503 ignored), black (format checking), isort (import order checking), and mypy (type checking with `--ignore-missing-imports`)
- **5.1.3-FR-2**: The system SHALL centralize tool configuration in `pyproject.toml` under `[tool.black]` (line-length=100, target Python 3.8-3.11), `[tool.isort]` (profile="black", trailing comma, grid wrap), and `[tool.mypy]` (strict mode: `disallow_untyped_defs`, `warn_return_any`, `strict_equality`)
- **5.1.3-FR-3**: The system SHALL provide a local shortcut `run_tests.py --lint` for running flake8

#### Business Rules

- **5.1.3-BR-1**: Quality checks use `continue-on-error: true` — they report issues without blocking the pipeline
- **5.1.3-BR-2**: Tool configuration is centralized in `pyproject.toml` to avoid scattered config files

#### Acceptance Criteria

- **5.1.3-AC-1**: CI quality job runs all 4 tools (flake8, black, isort, mypy) on every push and PR
- **5.1.3-AC-2**: Tool configuration in `pyproject.toml` is consistent with CI job invocations
- **5.1.3-AC-3**: `run_tests.py --lint` runs flake8 locally and reports results

## Subsystem D: Coverage Reporting

_Code coverage measurement, reporting, and Codecov integration._

### Functional Requirements

#### Core Functionality

- **5.1.4-FR-1**: The system SHALL collect coverage via `pytest-cov` (wrapping `coverage.py`) configured in `pyproject.toml` under `[tool.coverage.run]` and `[tool.coverage.report]`
- **5.1.4-FR-2**: The system SHALL limit coverage source to the `linkwatcher` package, omitting tests, test files, and `setup.py`
- **5.1.4-FR-3**: The system SHALL upload coverage to Codecov via `codecov/codecov-action@v3` on the Python 3.11 matrix slot only (`if: matrix.python-version == '3.11'`)
- **5.1.4-FR-4**: The system SHALL provide `run_tests.py --coverage` for local HTML coverage report generation in `htmlcov/`
- **5.1.4-FR-5**: The system SHALL define exclusion patterns in `[tool.coverage.report]` for lines that shouldn't count (e.g., `pragma: no cover`, `__repr__`, abstract methods, Protocol definitions)

#### Business Rules

- **5.1.4-BR-1**: Coverage upload happens on one Python version only (3.11) to avoid duplicate reports
- **5.1.4-BR-2**: Coverage source is restricted to production code — test files are excluded from measurement

#### Acceptance Criteria

- **5.1.4-AC-1**: Coverage percentage is reported on every PR via Codecov badge
- **5.1.4-AC-2**: `run_tests.py --coverage` generates an HTML report locally
- **5.1.4-AC-3**: Exclusion patterns correctly omit non-production lines from coverage calculations

## Subsystem E: Pre-commit Hooks

_Git hook configuration for pre-commit quality enforcement._

### Functional Requirements

#### Core Functionality

- **5.1.5-FR-1**: The system SHALL provide a `.pre-commit-config.yaml` with 4 hook repositories: `pre-commit-hooks` (v4.4.0 — trailing whitespace, end-of-file fixer, YAML/JSON validation, merge conflict detection, large file check, debug statement detection), `black` (v23.7.0 — `--line-length=100`), `isort` (v5.12.0 — `--profile=black`), and `flake8` (v6.0.0 — `--max-line-length=100`)
- **5.1.5-FR-2**: The system SHALL include a local `pytest-quick` hook that runs `python run_tests.py --quick` at the `commit` stage with `always_run: true`
- **5.1.5-FR-3**: The system SHALL support installation via `pre-commit install` and `pre-commit install --hook-type commit-msg`, automated through `scripts/setup_cicd.py` and Makefile/dev.bat `pre-commit` targets

#### Business Rules

- **5.1.5-BR-1**: Pre-commit hooks mirror the CI quality checks to catch issues before they reach the pipeline
- **5.1.5-BR-2**: Quick tests run on every commit to prevent broken code from entering version control

#### Acceptance Criteria

- **5.1.5-AC-1**: All 4 external hook repos plus the local pytest-quick hook execute on `git commit`
- **5.1.5-AC-2**: `pre-commit install` is automated by setup scripts (setup_cicd.py, dev.bat, Makefile)
- **5.1.5-AC-3**: Hooks block the commit if formatting, linting, or quick tests fail

## Subsystem F: Package Building

_Python package configuration, build pipeline, and distribution tooling._

### Functional Requirements

#### Core Functionality

- **5.1.6-FR-1**: The system SHALL provide dual package configuration: `pyproject.toml` (PEP 621 standard, primary) and `setup.py` (legacy compatibility) with identical metadata: name=linkwatcher, version=2.0.0, Python >=3.8
- **5.1.6-FR-2**: The system SHALL define runtime dependencies (watchdog, PyYAML, colorama), optional dependency groups (`[test]` and `[dev]`), and an entry point (`linkwatcher=linkwatcher.cli:main`)
- **5.1.6-FR-3**: The system SHALL provide a CI `build` job that runs `python -m build` + `twine check dist/*`, gated behind `test` and `quality` jobs
- **5.1.6-FR-4**: The system SHALL provide deployment scripts (`deployment/install_global.py`, `deployment/setup_project.py`) for local installation
- **5.1.6-FR-5**: The system SHALL provide Makefile targets `clean`, `build`, and `release-check` for package management

#### Business Rules

- **5.1.6-BR-1**: `pyproject.toml` is the primary configuration; `setup.py` exists only for legacy tool compatibility
- **5.1.6-BR-2**: No package build is attempted without passing tests and quality checks (CI gating)

#### Acceptance Criteria

- **5.1.6-AC-1**: `python -m build` succeeds and produces both sdist and wheel artifacts
- **5.1.6-AC-2**: `twine check dist/*` passes with no errors
- **5.1.6-AC-3**: `pip install -e .` works from the project root

## Subsystem G: Windows Dev Scripts

_Developer convenience scripts for Windows-native command-line usage._

### Functional Requirements

#### Core Functionality

- **5.1.7-FR-1**: The system SHALL provide `dev.bat` (Windows batch) and `Makefile` (cross-platform make) exposing identical command sets: `install`, `install-dev`, `test`, `test-quick`, `test-all`, `coverage`, `lint`, `format`, `type-check`, `clean`, `build`, `pre-commit`, `ci-test`, and `dev-setup`
- **5.1.7-FR-2**: The system SHALL use goto-label routing (`if "%1"=="test" goto test`) in `dev.bat` for Windows CMD compatibility
- **5.1.7-FR-3**: The system SHALL provide a Makefile `help` target (default) that lists all available commands
- **5.1.7-FR-4**: The system SHALL provide a Makefile `release-check` target that chains clean -> lint -> type-check -> test-all -> build -> twine check
- **5.1.7-FR-5**: Both scripts SHALL delegate to `run_tests.py` for test execution and to standard Python tools (black, isort, flake8, mypy) for quality checks

#### Business Rules

- **5.1.7-BR-1**: `dev.bat` and `Makefile` must expose the same commands for consistency regardless of shell choice
- **5.1.7-BR-2**: All dev commands work from the project root directory without additional setup beyond `dev dev-setup`

#### Acceptance Criteria

- **5.1.7-AC-1**: `dev test`, `dev lint`, `dev build` all execute successfully from the project root
- **5.1.7-AC-2**: `make help` lists all available targets
- **5.1.7-AC-3**: `make release-check` runs the full quality pipeline end-to-end

## Dependencies

- **[4.1.1 Test Framework](../../../process-framework/state-tracking/permanent/feature-tracking.md)**: CI test jobs and dev scripts invoke `run_tests.py` from the test framework
- **[0.1.1 Core Architecture](../../../process-framework/state-tracking/permanent/feature-tracking.md)**: The `linkwatcher` package being built and tested is the core product
