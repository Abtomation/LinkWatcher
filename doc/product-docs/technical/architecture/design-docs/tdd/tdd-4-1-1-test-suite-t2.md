---
id: PD-TDD-027
type: Product Documentation
category: Technical Design Document
version: 2.0
created: 2026-02-20
updated: 2026-02-20
feature_id: 4.1.1
feature_name: Test Suite
tier: 2
retrospective: true
consolidates:
  - { id: PD-TDD-027, feature: "4.1.1 Test Framework" }
  - { id: PD-TDD-028, feature: "4.1.3 Integration Tests" }
  - { id: PD-TDD-029, feature: "4.1.4 Parser Tests" }
  - { id: PD-TDD-030, feature: "4.1.6 Test Fixtures" }
supersedes:
  - tdd-4-1-1-test-framework-t2.md
  - tdd-4-1-3-integration-tests-t2.md
  - tdd-4-1-4-parser-tests-t2.md
  - tdd-4-1-6-test-fixtures-t2.md
---

# Test Suite - Technical Design Document (Tier 2)

> **Retrospective Document**: This TDD describes the existing implemented architecture of the LinkWatcher Test Suite, documented after implementation during framework onboarding (PF-TSK-066).
>
> **Consolidation Scope**: This document consolidates the previously separate TDDs for Test Framework (4.1.1), Integration Tests (4.1.3), Parser Tests (4.1.4), and Test Fixtures (4.1.6) into a single unified reference. All technical requirement IDs from the original documents are preserved with their original prefixes.

## Technical Overview

The LinkWatcher test suite is built on pytest and comprises 247+ test methods organized across 4 test categories (unit, integration, parsers, performance). The suite includes a root `conftest.py` with shared fixtures, a `run_tests.py` CLI for category-based execution, `test_config.py` for per-environment configurations, static and manual fixture data, and dedicated test files for integration scenarios and parser coverage. The framework supports 10 custom markers and a fixture hierarchy that composes LinkWatcher components for integration testing.

---

## Subsystem: Test Framework Infrastructure

> Source feature: 4.1.1 Test Framework

### pytest.ini Configuration

Defines strict mode, custom markers, test discovery paths, verbose output, and short tracebacks. Markers include priority levels (`critical`, `high`, `medium`, `low`) and categories (`unit`, `integration`, `parser`, `performance`, `slow`, `manual`).

### Root conftest.py

**Shared Fixtures** (session/function scoped):
- `temp_project_dir` -- Creates a temporary directory with auto-cleanup
- `sample_files` -- Populates temp dir with sample file types
- `link_database` -- Fresh `LinkDatabase` instance
- `link_parser` -- Fresh `LinkParser` instance
- `link_updater` -- Fresh `LinkUpdater` with temp dir as project root
- `test_config` -- `LinkWatcherConfig` from TESTING_CONFIG
- `link_service` -- Composite fixture: full `LinkWatcherService` with test config applied
- `populated_database` -- Pre-populated `LinkDatabase` with sample references
- `file_helper` -- `TestFileHelper` for creating test files on demand

**Custom Assertions** (added to `pytest` namespace):
- `assert_reference_found(references, target, link_type=None)` -- Verifies a reference exists
- `assert_reference_not_found(references, target)` -- Verifies a reference does not exist

### run_tests.py CLI Runner

Argparse-based CLI providing 10 execution modes. Each flag maps to a pytest invocation targeting specific directories or markers. Default (no flags) falls back to `--quick` which runs unit + parser tests.

### test_config.py

Defines `TEST_ENVIRONMENTS` dict with 4 configs:
- `unit`: `dry_run=True`, minimal logging
- `integration`: `dry_run=False`, `create_backups=True`
- `performance`: logging disabled, backups disabled
- `manual`: all features enabled, colored output

Also defines `SAMPLE_CONTENTS` and `TEST_PROJECT_STRUCTURES` for test data.

### Key Technical Decisions (Test Framework)

**Fixture Hierarchy in Root conftest.py**: All shared fixtures defined in root `tests/conftest.py` rather than per-directory. pytest automatically discovers root conftest for all subdirectories. Avoids fixture duplication across test categories.

**Category-Based Test Organization**: 4-directory structure matches `run_tests.py` flags: `--unit` maps to `tests/unit/`, `--parsers` maps to `tests/parsers/`, etc. Each category has distinct characteristics (speed, isolation, realism).

**Per-Environment Configurations**: Different test categories need different `LinkWatcherConfig` settings. Unit tests use `dry_run=True` for safety; integration tests use real file operations with backups; performance tests minimize overhead.

---

## Subsystem: Integration Tests

> Source feature: 4.1.3 Integration Tests

### Test File Organization

Integration tests verify cross-component workflows using real file system operations. The `tests/integration/` directory contains 9+ test files organized by scenario type. Tests use the `link_service` composite fixture from conftest.py, which assembles a full `LinkWatcherService` with `dry_run=False` and `create_backups=True`.

| File | Scope | Key Scenarios |
|------|-------|---------------|
| `test_complex_scenarios.py` | Multi-step workflows | Rename chains, directory moves, cascading updates |
| `test_error_handling.py` | Error recovery | Permission errors, encoding issues, missing files |
| `test_file_movement.py` | Core move detection | Single file move, cross-directory move |
| `test_link_updates.py` | End-to-end updates | Parse, detect, update pipeline |
| `test_service_integration.py` | Full service | Service lifecycle, configuration, statistics |
| `test_windows_platform.py` | Platform-specific | Backslash paths, drive letters, case sensitivity |
| `test_sequential_moves.py` | Sequential operations | A-to-B-to-C move chains, concurrent moves |
| `test_comprehensive_file_monitoring.py` | File type coverage | All supported file types monitored |
| `test_image_file_monitoring.py` | Image files | PNG, JPG, SVG reference handling |
| `test_powershell_script_monitoring.py` | PowerShell | .ps1 file reference handling |

### Test Pattern: Simulate-and-Verify

All integration tests follow a consistent pattern:
1. Create project structure via `TestProjectBuilder` or `create_sample_project()`
2. Populate files with cross-references
3. Simulate file move via `simulate_file_move()` or `shutil.move()`
4. Execute link update via `link_service`
5. Verify file contents updated correctly

### Key Technical Decisions (Integration Tests)

**Scenario-Based Organization**: Tests organized by workflow scenario rather than by component. A "file movement" test exercises handler + parser + database + updater together. This makes it easy to find tests for specific user stories.

**Real File System Operations**: Integration tests use `dry_run_mode=False` with `create_backups=True`. The whole point is verifying real behavior -- atomic writes, backup creation, encoding handling. Temp directories ensure cleanup.

**Platform-Specific Test Separation**: Windows-specific tests in a dedicated file (`test_windows_platform.py`) can be skipped on non-Windows CI environments without polluting cross-platform tests.

---

## Subsystem: Parser Tests

> Source feature: 4.1.4 Parser Tests

### Test File Mapping

Parser tests provide one-to-one test coverage for each LinkWatcher parser implementation. The `tests/parsers/` directory contains 7 test files that directly import and test individual parser classes. Tests follow a parse-and-assert pattern using custom assertions from conftest.py, with heavy edge case coverage reflecting the critical role of parser accuracy.

| Test File | Parser Under Test | Import |
|-----------|-------------------|--------|
| `test_markdown.py` | `parsers/markdown.py` | `MarkdownParser` |
| `test_yaml.py` | `parsers/yaml_parser.py` | `YAMLParser` |
| `test_json.py` | `parsers/json_parser.py` | `JSONParser` |
| `test_python.py` | `parsers/python.py` | `PythonParser` |
| `test_dart.py` | `parsers/dart.py` | `DartParser` |
| `test_generic.py` | `parsers/generic.py` | `GenericParser` |
| `test_image_files.py` | Image file handling | Multiple parsers |

### Test Pattern: Parse-and-Assert

Each test method follows a consistent structure:
1. Create a file with known content in `temp_project_dir`
2. Instantiate the parser and call `parse_file(file_path)`
3. Assert expected references found via `assert_reference_found(refs, target, link_type)`
4. Assert non-references NOT found via `assert_reference_not_found(refs, target)`

### Edge Case Coverage Strategy

Each parser test file includes systematic edge case methods:
- **Empty files**: Zero references returned without errors
- **Malformed content**: Parser degrades gracefully (no exceptions)
- **Special characters**: Paths with spaces, unicode, special chars
- **Format-specific**: Markdown anchors, YAML nested refs, JSON recursive objects, Python stdlib skip list, Dart package prefix filtering

### Key Technical Decisions (Parser Tests)

**One Test File Per Parser**: One-to-one mapping ensures clear test ownership. Each parser's unique syntax rules get dedicated test focus. Easy to run parser-specific tests in isolation.

**Custom Assertion Helpers**: `assert_reference_found` and `assert_reference_not_found` eliminate repetitive list-comprehension assertions. They provide clear error messages showing actual found references and support optional `link_type` parameter for precise matching.

**Edge Case Priority**: 80+ methods with heavy edge case emphasis because parser correctness directly determines link update accuracy. A missed reference means a broken link after file move; a false positive means corrupting unrelated content.

---

## Subsystem: Test Fixtures

> Source feature: 4.1.6 Test Fixtures

### Fixture Organization

Test fixtures are organized into three tiers: static fixture files in `tests/fixtures/` (sample markdown, YAML, JSON), manual markdown test cases in `manual_markdown_tests/` (24 files with interactive runner), and a complete manual test project in `manual_test/` (13 files). Programmatic fixture data is also available via `tests/test_config.py` constants.

| Location | Type | Contents | Consumers |
|----------|------|----------|-----------|
| `tests/fixtures/` | Static files | `sample_markdown.md`, `sample_config.yaml`, `sample_data.json` | Parser tests, unit tests |
| `manual_markdown_tests/` | Manual test cases | 24 markdown files (LR-001 to MP-009) + `test_runner.py` | Interactive parser validation |
| `manual_test/` | Project structure | 13 files across docs/, src/, assets/, scripts/ | Manual end-to-end testing |
| `tests/test_config.py` | Constants | `SAMPLE_CONTENTS` (5 types), `TEST_PROJECT_STRUCTURES` (simple/complex) | Programmatic test data creation |

### Static Fixture Content

- **sample_markdown.md**: Contains standard markdown links (`[text](path)`), reference links, image references, and edge cases (anchors, query params)
- **sample_config.yaml**: YAML file with `path:` keys, `include:` lists, and nested references to other project files
- **sample_data.json**: JSON with `"file"`, `"path"`, and `"src"` keys containing file path references

### Manual Test Case Categories

| Prefix | Category | Count |
|--------|----------|-------|
| LR-* | Link Reference detection | Various |
| MP-* | Multi-Parser scenarios | Various |
| test_project_* | Project structure simulation | Various |

### Key Technical Decisions (Test Fixtures)

**Static vs. Dynamic Fixture Data**: Static fixture files provide deterministic, human-readable inputs for exact-match assertions. They complement (not replace) the `TestProjectBuilder` from 4.1.7 which generates dynamic project structures for complex scenarios. Static fixtures are preferred when test correctness depends on known, inspectable content.

**Separate Manual Test Infrastructure**: Manual test scripts (`create_test_structure.py`, `cleanup_test.py`) are kept separate from the pytest suite. Automated tests use temporary directories with automatic cleanup; manual/exploratory testing needs persistent structures. The `test_runner.py` in `manual_markdown_tests/` provides interactive parser validation outside the pytest framework.

---

## Dependencies (Consolidated)

| Component | Usage | Subsystems |
|-----------|-------|------------|
| `linkwatcher.__init__` | `LinkDatabase`, `LinkParser`, `LinkUpdater`, `LinkWatcherService` for fixtures | Test Framework |
| `linkwatcher.config` | `TESTING_CONFIG`, `LinkWatcherConfig` for per-environment configs | Test Framework |
| `linkwatcher.service.LinkWatcherService` | Main integration target | Integration Tests |
| `linkwatcher.database.LinkDatabase` | Database interactions | Integration Tests, Test Framework |
| `linkwatcher.parser.LinkParser` | Cross-component parsing | Integration Tests, Test Framework |
| `linkwatcher.updater.LinkUpdater` | Update operations | Integration Tests, Test Framework |
| `linkwatcher.models.LinkReference` | Test data creation and verification | Integration Tests, Parser Tests |
| All `linkwatcher.parsers.*` classes | Test targets | Parser Tests |
| `linkwatcher/parsers/markdown.py` | `MarkdownParser` used by manual test runner | Test Fixtures |
| `tests/conftest.py` | Shared fixtures and custom assertions | All subsystems |
| `tests/test_config.py` | Environment configs and sample data constants | Test Framework, Test Fixtures |
| `pytest` (>=7.0) | Test framework and fixture system | All subsystems |
| `pytest-cov`, `pytest-mock`, `pytest-xdist`, `pytest-timeout` | Test plugins | Test Framework |
| PyYAML, json (stdlib) | Fixture file content | Test Fixtures |
