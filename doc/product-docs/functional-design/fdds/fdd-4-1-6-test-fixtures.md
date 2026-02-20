---
id: PD-FDD-031
type: Product Documentation
category: Functional Design Document
version: 1.0
created: 2026-02-20
updated: 2026-02-20
feature_id: 4.1.6
feature_name: Test Fixtures
retrospective: true
---

# Test Fixtures - Functional Design Document

> **Retrospective Document**: This FDD describes the existing implemented functionality of the LinkWatcher Test Fixtures, documented after implementation during framework onboarding (PF-TSK-066).
>
> **Source**: Derived from [4.1.6 Implementation State](../../../process-framework/state-tracking/features/4.1.6-test-fixtures-implementation-state.md) and source code analysis.

## Feature Overview

- **Feature ID**: 4.1.6
- **Feature Name**: Test Fixtures
- **Business Value**: Provides stable, version-controlled test data files and manual test project structures that ensure reproducible, deterministic test execution across the entire test suite.
- **User Story**: As a developer, I want pre-built test data files and manual test project structures so that I can run tests with known-good inputs and manually validate LinkWatcher behavior against realistic project layouts.

## Functional Requirements

### Core Functionality

- **4.1.6-FR-1**: The system SHALL provide static fixture files in `tests/fixtures/` for markdown, YAML, and JSON formats with representative link/reference content
- **4.1.6-FR-2**: The system SHALL provide 24 manual markdown test cases (LR-001 through MP-009) in `manual_markdown_tests/` covering link detection scenarios
- **4.1.6-FR-3**: The system SHALL provide an interactive `test_runner.py` for manual parser validation against the markdown test cases
- **4.1.6-FR-4**: The system SHALL provide a complete manual test project structure (13 files) in `manual_test/` with docs, src, assets, and scripts subdirectories
- **4.1.6-FR-5**: The system SHALL provide `SAMPLE_CONTENTS` dict (5 content types) and `TEST_PROJECT_STRUCTURES` (simple/complex layouts) in `tests/test_config.py`

### Business Rules

- **4.1.6-BR-1**: Static fixtures provide deterministic, human-readable inputs — dynamic generation (via `TestProjectBuilder`) is used alongside for complex scenarios
- **4.1.6-BR-2**: Manual test projects persist on disk for exploratory testing; automated tests use temporary directories
- **4.1.6-BR-3**: Fixture files must cover all supported file types to ensure parser test coverage

### Acceptance Criteria

- **4.1.6-AC-1**: 3 static fixture files exist in `tests/fixtures/` (sample_markdown.md, sample_config.yaml, sample_data.json)
- **4.1.6-AC-2**: 24 manual markdown test cases runnable via `test_runner.py`
- **4.1.6-AC-3**: Manual test project contains 13 files in realistic directory structure
- **4.1.6-AC-4**: `SAMPLE_CONTENTS` and `TEST_PROJECT_STRUCTURES` constants available for programmatic test data creation

## Dependencies

- **[4.1.1 Test Framework](../../../process-framework/state-tracking/features/4.1.1-test-framework-implementation-state.md)**: Provides pytest fixtures (`temp_project_dir`, `file_helper`) that load static fixture data
- **[4.1.4 Parser Tests](../../../process-framework/state-tracking/features/4.1.4-parser-tests-implementation-state.md)**: Primary consumer of static fixture files for parser validation
