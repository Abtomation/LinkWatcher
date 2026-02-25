---
id: PD-FDD-028
type: Product Documentation
category: Functional Design Document
version: 2.0
created: 2026-02-20
updated: 2026-02-20
feature_id: 4.1.1
feature_name: Test Suite
retrospective: true
consolidates: [4.1.1 (Test Framework), 4.1.3 (Integration Tests), 4.1.4 (Parser Tests), 4.1.6 (Test Fixtures)]
supersedes:
  - PD-FDD-028 v1.0 (Test Framework)
  - PD-FDD-029 (Integration Tests)
  - PD-FDD-030 (Parser Tests)
  - PD-FDD-031 (Test Fixtures)
---

# Test Suite (4.1.1) - Functional Design Document

> **Retrospective Document**: This FDD describes the existing implemented functionality of the LinkWatcher Test Suite, documented after implementation during framework onboarding (PF-TSK-066). It consolidates four previously separate FDDs (Test Framework, Integration Tests, Parser Tests, Test Fixtures) into a single coherent document.
>
> **Sources**: Derived from [tests/README.md](../../../../tests/README.md), [tests/TEST_PLAN.md](../../../../tests/TEST_PLAN.md), [tests/TEST_CASE_STATUS.md](../../../../tests/TEST_CASE_STATUS.md), and source code analysis.

## Feature Overview

- **Feature ID**: 4.1.1
- **Feature Name**: Test Suite
- **Business Value**: Provides a complete, organized test infrastructure supporting 247+ test methods across 4 categories (unit, integration, parser, performance), with shared fixtures, custom assertions, and deterministic test data — enabling quick regression checks, targeted debugging, and end-to-end workflow verification for developers contributing to LinkWatcher.
- **User Story**: As a developer contributing to LinkWatcher, I want a comprehensive, well-organized test suite with shared infrastructure, integration verification, parser-specific coverage, and stable test data, so that I can quickly run relevant tests, get clear feedback on code changes, and be confident that all components work correctly together.

## Subsystem: Test Framework Infrastructure

_Provides the foundational pytest configuration, shared fixtures, custom assertions, and CLI runner that all other test subsystems depend on._

### Functional Requirements

#### Core Functionality

- **4.1.1-FR-1**: The system SHALL configure pytest via `pytest.ini` with strict markers, verbose output, and short tracebacks
- **4.1.1-FR-2**: The system SHALL provide shared fixtures in root `tests/conftest.py` including: `temp_project_dir`, `sample_files`, `link_database`, `link_parser`, `link_updater`, `test_config`, `link_service`, `populated_database`, `file_helper`
- **4.1.1-FR-3**: The system SHALL provide custom assertions (`assert_reference_found`, `assert_reference_not_found`) added to the pytest namespace
- **4.1.1-FR-4**: The system SHALL provide a CLI runner (`run_tests.py`) with flags for category-based execution: `--unit`, `--integration`, `--parsers`, `--performance`, `--critical`, `--quick`, `--all`, `--coverage`, `--discover`, `--lint`
- **4.1.1-FR-5**: The system SHALL define per-environment configurations in `tests/test_config.py` for `unit`, `integration`, `performance`, and `manual` environments
- **4.1.1-FR-6**: The system SHALL register 10 custom markers: `unit`, `integration`, `parser`, `performance`, `slow`, `manual`, `critical`, `high`, `medium`, `low`

#### Business Rules

- **4.1.1-BR-1**: Unit test environment uses `dry_run=True` for safety; integration uses `dry_run=False` with backups for realism
- **4.1.1-BR-2**: Performance test environment disables logging and backups for minimal overhead
- **4.1.1-BR-3**: The `--quick` flag runs unit + parser tests only (fast feedback loop)
- **4.1.1-BR-4**: Default execution (no flags) falls back to `--quick` mode

#### Acceptance Criteria

- **4.1.1-AC-1**: All 247+ test methods are discoverable via `pytest --collect-only`
- **4.1.1-AC-2**: `run_tests.py --unit` executes only tests in `tests/unit/`
- **4.1.1-AC-3**: All shared fixtures are available to tests in any subdirectory
- **4.1.1-AC-4**: Custom assertions provide clear error messages showing actual found references

## Subsystem: Integration Tests

_Provides end-to-end verification that LinkWatcher components work together correctly in real file system scenarios, catching interaction bugs that unit tests miss._

### Functional Requirements

#### Core Functionality

- **4.1.3-FR-1**: The system SHALL provide integration tests verifying end-to-end file move to link update workflows across parser, database, and updater components
- **4.1.3-FR-2**: The system SHALL provide error handling tests for recovery across component boundaries (permissions, encoding, missing files)
- **4.1.3-FR-3**: The system SHALL provide Windows platform-specific tests for path separators, drive letters, case sensitivity, and UNC paths
- **4.1.3-FR-4**: The system SHALL provide complex scenario tests for rename chains, directory moves, and sequential multi-step operations
- **4.1.3-FR-5**: The system SHALL provide file type monitoring tests for images, PowerShell scripts, and comprehensive file monitoring
- **4.1.3-FR-6**: The system SHALL use real file system operations (not mocked) with automatic temp directory cleanup

#### Business Rules

- **4.1.3-BR-1**: Integration tests use `dry_run_mode=False` with `create_backups=True` for realistic testing
- **4.1.3-BR-2**: Integration tests use the `link_service` composite fixture for full service setup
- **4.1.3-BR-3**: Tests are organized by scenario type (not by component) for workflow-oriented coverage

#### Acceptance Criteria

- **4.1.3-AC-1**: 45+ integration test methods all passing
- **4.1.3-AC-2**: Tests verify actual file modifications on disk (not dry-run output)
- **4.1.3-AC-3**: Windows-specific tests pass on Windows runners and can be skipped on other platforms
- **4.1.3-AC-4**: Runnable via `python run_tests.py --integration` or `pytest tests/integration/`

## Subsystem: Parser Tests

_Ensures each file-type parser correctly identifies all file references, preventing false positives and negatives that would cascade through the entire link update system._

### Functional Requirements

#### Core Functionality

- **4.1.4-FR-1**: The system SHALL provide dedicated test files for each parser: Markdown, YAML, JSON, Python, Dart, Generic, and image files (7 test files)
- **4.1.4-FR-2**: The system SHALL verify standard link syntax extraction for each supported format
- **4.1.4-FR-3**: The system SHALL test edge cases: empty files, malformed content, special characters, nested structures, and format-specific features
- **4.1.4-FR-4**: The system SHALL use custom assertions (`assert_reference_found`, `assert_reference_not_found`) for clear test output
- **4.1.4-FR-5**: The system SHALL maintain 80+ test methods covering all parser behaviors

#### Business Rules

- **4.1.4-BR-1**: One-to-one mapping between parser implementations and test files (e.g., `test_markdown.py` tests `parsers/markdown.py`)
- **4.1.4-BR-2**: Edge cases are prioritized because parser correctness directly determines link update accuracy
- **4.1.4-BR-3**: Tests use `temp_project_dir` and `file_helper` fixtures for file creation

#### Acceptance Criteria

- **4.1.4-AC-1**: 80+ parser test methods all passing
- **4.1.4-AC-2**: Each parser has tests for standard syntax, edge cases, and error handling
- **4.1.4-AC-3**: Runnable via `python run_tests.py --parsers` or `pytest tests/parsers/`
- **4.1.4-AC-4**: False positive tests verify that non-file-reference strings are NOT extracted

## Subsystem: Test Fixtures

_Provides stable, version-controlled test data files and manual test project structures that ensure reproducible, deterministic test execution across the entire test suite._

### Functional Requirements

#### Core Functionality

- **4.1.6-FR-1**: The system SHALL provide static fixture files in `tests/fixtures/` for markdown, YAML, and JSON formats with representative link/reference content
- **4.1.6-FR-2**: The system SHALL provide 24 manual markdown test cases (LR-001 through MP-009) in `manual_markdown_tests/` covering link detection scenarios
- **4.1.6-FR-3**: The system SHALL provide an interactive `test_runner.py` for manual parser validation against the markdown test cases
- **4.1.6-FR-4**: The system SHALL provide a complete manual test project structure (13 files) in `manual_test/` with docs, src, assets, and scripts subdirectories
- **4.1.6-FR-5**: The system SHALL provide `SAMPLE_CONTENTS` dict (5 content types) and `TEST_PROJECT_STRUCTURES` (simple/complex layouts) in `tests/test_config.py`

#### Business Rules

- **4.1.6-BR-1**: Static fixtures provide deterministic, human-readable inputs — dynamic generation (via `TestProjectBuilder`) is used alongside for complex scenarios
- **4.1.6-BR-2**: Manual test projects persist on disk for exploratory testing; automated tests use temporary directories
- **4.1.6-BR-3**: Fixture files must cover all supported file types to ensure parser test coverage

#### Acceptance Criteria

- **4.1.6-AC-1**: 3 static fixture files exist in `tests/fixtures/` (sample_markdown.md, sample_config.yaml, sample_data.json)
- **4.1.6-AC-2**: 24 manual markdown test cases runnable via `test_runner.py`
- **4.1.6-AC-3**: Manual test project contains 13 files in realistic directory structure
- **4.1.6-AC-4**: `SAMPLE_CONTENTS` and `TEST_PROJECT_STRUCTURES` constants available for programmatic test data creation

## Dependencies

### Feature Dependencies

- **0.1.3 Configuration System**: Provides `TESTING_CONFIG` and `LinkWatcherConfig` for test fixtures
- **2.1.1 Link Parsing System**: Test targets — each parser test file directly imports and tests its corresponding parser class

### Internal Cross-Subsystem Dependencies

| From Subsystem | To Subsystem | Relationship |
|---|---|---|
| Integration Tests | Framework Infrastructure | Uses `link_service` fixture and `temp_project_dir` |
| Parser Tests | Framework Infrastructure | Uses `temp_project_dir`, `file_helper` fixtures and custom assertions |
| Test Fixtures | Framework Infrastructure | Provides data consumed by pytest fixtures |
| Parser Tests | Test Fixtures | Primary consumer of static fixture files for parser validation |

### Technical Dependencies

- **pytest** (>=7.0): Test framework and runner
- **pytest-cov** (>=4.0): Coverage reporting integration

## Validation Checklist

- [x] All functional requirements clearly defined with Feature ID prefixes
- [x] Business rules specified for each subsystem
- [x] Acceptance criteria are testable and measurable
- [x] Dependencies mapped (functional and technical)
- [x] All four original FDD scopes fully represented

---

_Retrospective Functional Design Document — consolidates PD-FDD-028/029/030/031 as of 2026-02-20._
