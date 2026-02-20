---
id: PD-FDD-028
type: Product Documentation
category: Functional Design Document
version: 1.0
created: 2026-02-20
updated: 2026-02-20
feature_id: 4.1.1
feature_name: Test Framework
retrospective: true
---

# Test Framework - Functional Design Document

> **Retrospective Document**: This FDD describes the existing implemented functionality of the LinkWatcher Test Framework, documented after implementation during framework onboarding (PF-TSK-066).
>
> **Source**: Derived from [4.1.1 Implementation State](../../../process-framework/state-tracking/features/4.1.1-test-framework-implementation-state.md), [tests/README.md](../../../../tests/README.md), [tests/TEST_PLAN.md](../../../../tests/TEST_PLAN.md), and source code analysis.

## Feature Overview

- **Feature ID**: 4.1.1
- **Feature Name**: Test Framework
- **Business Value**: Provides organized, reliable test infrastructure supporting 247+ test methods across 4 categories, enabling quick regression checks and targeted debugging for developers.
- **User Story**: As a developer contributing to LinkWatcher, I want a well-organized test framework so that I can quickly run relevant tests and get clear feedback on code changes.

## Functional Requirements

### Core Functionality

- **4.1.1-FR-1**: The system SHALL configure pytest via `pytest.ini` with strict markers, verbose output, and short tracebacks
- **4.1.1-FR-2**: The system SHALL provide shared fixtures in root `tests/conftest.py` including: `temp_project_dir`, `sample_files`, `link_database`, `link_parser`, `link_updater`, `test_config`, `link_service`, `populated_database`, `file_helper`
- **4.1.1-FR-3**: The system SHALL provide custom assertions (`assert_reference_found`, `assert_reference_not_found`) added to the pytest namespace
- **4.1.1-FR-4**: The system SHALL provide a CLI runner (`run_tests.py`) with flags for category-based execution: `--unit`, `--integration`, `--parsers`, `--performance`, `--critical`, `--quick`, `--all`, `--coverage`, `--discover`, `--lint`
- **4.1.1-FR-5**: The system SHALL define per-environment configurations in `tests/test_config.py` for `unit`, `integration`, `performance`, and `manual` environments
- **4.1.1-FR-6**: The system SHALL register 10 custom markers: `unit`, `integration`, `parser`, `performance`, `slow`, `manual`, `critical`, `high`, `medium`, `low`

### Business Rules

- **4.1.1-BR-1**: Unit test environment uses `dry_run=True` for safety; integration uses `dry_run=False` with backups for realism
- **4.1.1-BR-2**: Performance test environment disables logging and backups for minimal overhead
- **4.1.1-BR-3**: The `--quick` flag runs unit + parser tests only (fast feedback loop)
- **4.1.1-BR-4**: Default execution (no flags) falls back to `--quick` mode

### Acceptance Criteria

- **4.1.1-AC-1**: All 247+ test methods are discoverable via `pytest --collect-only`
- **4.1.1-AC-2**: `run_tests.py --unit` executes only tests in `tests/unit/`
- **4.1.1-AC-3**: All shared fixtures are available to tests in any subdirectory
- **4.1.1-AC-4**: Custom assertions provide clear error messages showing actual found references

## Dependencies

- **[0.1.4 Configuration System](../../../process-framework/state-tracking/features/0.1.4-configuration-system-implementation-state.md)**: Provides `TESTING_CONFIG` and `LinkWatcherConfig` for test fixtures
- **Depended on by**: 4.1.2 (Unit Tests), 4.1.3 (Integration Tests), 4.1.4 (Parser Tests), 4.1.5 (Performance Tests), 4.1.7 (Test Utilities)
