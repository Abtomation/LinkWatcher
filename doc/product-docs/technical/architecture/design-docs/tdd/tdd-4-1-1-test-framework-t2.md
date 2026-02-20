---
id: PD-TDD-027
type: Product Documentation
category: Technical Design Document
version: 1.0
created: 2026-02-20
updated: 2026-02-20
feature_id: 4.1.1
feature_name: Test Framework
tier: 2
retrospective: true
---

# Test Framework - Technical Design Document (Tier 2)

> **Retrospective Document**: This TDD describes the existing implemented architecture of the LinkWatcher Test Framework, documented after implementation during framework onboarding (PF-TSK-066).
>
> **Source**: Derived from [4.1.1 Implementation State](../../../../process-framework/state-tracking/features/4.1.1-test-framework-implementation-state.md) and source code analysis.

## Technical Overview

The test framework is built on pytest with a root `conftest.py` providing shared fixtures, a `run_tests.py` CLI for category-based execution, and `test_config.py` defining per-environment configurations. The framework supports 4 test directories (unit/, integration/, parsers/, performance/), 10 custom markers, and a fixture hierarchy that composes LinkWatcher components for integration testing.

## Component Architecture

### pytest.ini Configuration

Defines strict mode, custom markers, test discovery paths, verbose output, and short tracebacks. Markers include priority levels (`critical`, `high`, `medium`, `low`) and categories (`unit`, `integration`, `parser`, `performance`, `slow`, `manual`).

### Root conftest.py

**Shared Fixtures** (session/function scoped):
- `temp_project_dir` — Creates a temporary directory with auto-cleanup
- `sample_files` — Populates temp dir with sample file types
- `link_database` — Fresh `LinkDatabase` instance
- `link_parser` — Fresh `LinkParser` instance
- `link_updater` — Fresh `LinkUpdater` with temp dir as project root
- `test_config` — `LinkWatcherConfig` from TESTING_CONFIG
- `link_service` — Composite fixture: full `LinkWatcherService` with test config applied
- `populated_database` — Pre-populated `LinkDatabase` with sample references
- `file_helper` — `TestFileHelper` for creating test files on demand

**Custom Assertions** (added to `pytest` namespace):
- `assert_reference_found(references, target, link_type=None)` — Verifies a reference exists
- `assert_reference_not_found(references, target)` — Verifies a reference does not exist

### run_tests.py CLI Runner

Argparse-based CLI providing 10 execution modes. Each flag maps to a pytest invocation targeting specific directories or markers. Default (no flags) falls back to `--quick` which runs unit + parser tests.

### test_config.py

Defines `TEST_ENVIRONMENTS` dict with 4 configs:
- `unit`: `dry_run=True`, minimal logging
- `integration`: `dry_run=False`, `create_backups=True`
- `performance`: logging disabled, backups disabled
- `manual`: all features enabled, colored output

Also defines `SAMPLE_CONTENTS` and `TEST_PROJECT_STRUCTURES` for test data.

## Key Technical Decisions

### Fixture Hierarchy in Root conftest.py

All shared fixtures defined in root `tests/conftest.py` rather than per-directory. pytest automatically discovers root conftest for all subdirectories. Avoids fixture duplication across test categories.

### Category-Based Test Organization

4-directory structure matches `run_tests.py` flags: `--unit` → `tests/unit/`, `--parsers` → `tests/parsers/`, etc. Each category has distinct characteristics (speed, isolation, realism).

### Per-Environment Configurations

Different test categories need different `LinkWatcherConfig` settings. Unit tests use `dry_run=True` for safety; integration tests use real file operations with backups; performance tests minimize overhead.

## Dependencies

| Component | Usage |
|-----------|-------|
| `linkwatcher.__init__` | `LinkDatabase`, `LinkParser`, `LinkUpdater`, `LinkWatcherService` for fixtures |
| `linkwatcher.config` | `TESTING_CONFIG`, `LinkWatcherConfig` for per-environment configs |
| `pytest` (>=7.0) | Test framework and fixture system |
| `pytest-cov`, `pytest-mock`, `pytest-xdist`, `pytest-timeout` | Test plugins |
