---
id: PF-TSP-042
type: Process Framework
category: Test Specification
version: 1.0
created: 2026-02-24
updated: 2026-02-24
feature_id: 4.1.1
feature_name: Test Suite
tdd_path: doc/product-docs/technical/architecture/design-docs/tdd/tdd-4-1-1-test-suite-t2.md
test_tier: 2
retrospective: true
---

# Test Specification: Test Suite

> **Retrospective Document**: This test specification describes the existing test infrastructure for the LinkWatcher Test Suite, documented after implementation during framework onboarding. This is a meta-specification — it documents the testing of the test infrastructure itself.

## Overview

This document provides comprehensive test specifications for the **Test Suite** feature (ID: 4.1.1), derived from the Technical Design Document [PD-TDD-027](../../../doc/product-docs/technical/architecture/design-docs/tdd/tdd-4-1-1-test-suite-t2.md).

**Test Tier**: 2 (Infrastructure validation + performance)
**TDD Reference**: [TDD PD-TDD-027](../../../doc/product-docs/technical/architecture/design-docs/tdd/tdd-4-1-1-test-suite-t2.md)

## Feature Context

### TDD Summary

The Test Suite infrastructure consists of pytest configuration (`pytest.ini`), shared fixtures (`conftest.py`), test utilities (`utils.py`), a CLI test runner (`run_tests.py`), test configuration presets (`tests/test_config.py`), and performance benchmarks. It provides the foundation for all 328 test methods across 4 categories (unit, integration, parser, performance).

### Test Complexity Assessment

**Selected Tier**: 2 — Infrastructure feature validated by its own usage plus explicit performance benchmarks.

## Cross-References

### Functional Requirements Reference

> **Primary Documentation**: [FDD PD-FDD-028](../../../doc/product-docs/functional-design/fdds/fdd-4-1-1-test-suite.md)

**Acceptance Criteria to Test**:
- 328 test methods discoverable via `pytest --collect-only`
- `run_tests.py --unit` executes only `tests/unit/`
- Shared fixtures available in all subdirectories
- Custom assertions provide clear error messages

## Test Infrastructure Components

### Shared Fixtures (conftest.py)

[`tests/conftest.py`](../../../tests/conftest.py) provides 9 fixtures used across the entire test suite:

| Fixture | Scope | Purpose | Used By |
|---------|-------|---------|---------|
| `temp_project_dir` | function | Isolated temporary directory with cleanup | Most tests |
| `sample_files` | function | Pre-created .md, .txt, .py, .json files with links | Service, parser tests |
| `link_database` | function | Fresh `LinkDatabase` instance | Database, integration tests |
| `link_parser` | function | `LinkParser` instance | Parser tests |
| `link_updater` | function | `LinkUpdater` in dry-run mode | Updater tests |
| `test_config` | function | `TESTING_CONFIG` preset | Service tests |
| `link_service` | function | `LinkWatcherService` with test config | Integration tests |
| `populated_database` | function | Database pre-populated with sample file links | Database tests |
| `file_helper` | function | `TestFileHelper` class for creating test files | Integration tests |

**Custom Assertions**: `assert_reference_found(references, target, link_type)` and `assert_reference_not_found(references, target)` — added to `pytest` namespace.

### Test Utilities (utils.py)

[`tests/utils.py`](../../../tests/utils.py) provides builder classes and helpers:

| Utility | Type | Purpose |
|---------|------|---------|
| `TestProjectBuilder` | Builder class | Creates test project structures with markdown, YAML, JSON, Python files |
| `LinkReferenceBuilder` | Builder class | Creates `LinkReference` objects for test assertions |
| `PerformanceTimer` | Context manager | Times operations and prints duration |
| `temporary_project()` | Context manager | Creates temp directory with file structure, auto-cleans |
| `create_sample_project()` | Function | Creates complete sample project with cross-references |
| `create_large_project()` | Function | Creates 100+ file projects for performance testing |
| `simulate_file_move()` | Function | Wraps `service.handler.on_moved()` |
| `MockFileSystemEvent` | Class | Mock watchdog event |
| `assert_references_equal()` | Function | Sorted comparison of reference lists |
| `assert_file_contains()` / `assert_file_not_contains()` | Functions | File content assertions |
| `generate_markdown_with_links()` | Function | Content generator for markdown |
| `generate_yaml_with_file_refs()` | Function | Content generator for YAML |
| `generate_json_with_file_refs()` | Function | Content generator for JSON |

### Test Configuration ([tests/test_config.py](../../../tests/test_config.py))

**Note**: This file (PD-TST-100) is a utility module, not a test file. It contains:
- `TEST_ENVIRONMENTS` — 4 presets (unit, integration, performance, manual)
- `SAMPLE_CONTENTS` — 5 content types (markdown, yaml, json, python, text)
- `TEST_PROJECT_STRUCTURES` — simple and complex project layouts
- `PERFORMANCE_TEST_CONFIGS` / `TEST_TIMEOUTS` — performance settings
- Helper functions: `get_test_config()`, `get_test_data_dir()`, `create_test_project()`

## Test Categories

### Performance Tests

| Component | Test Focus | Key Test Cases | Fixtures |
|-----------|-----------|----------------|----------|
| Large projects | 1000+ files | `test_ph_001_thousand_plus_files` — scan <30s, single move <5s | `temp_project_dir` |
| Deep nesting | 15 levels | `test_ph_002_deep_directory_structures` — scan <10s, deep move <3s | `temp_project_dir` |
| Large files | Up to 5MB | `test_ph_003_large_files` — 4 file sizes scanned <15s | `temp_project_dir` |
| Many refs single target | 100 files × 1 target | `test_ph_004_many_references_to_single_file` — 200+ refs, move <10s | `temp_project_dir` |
| Rapid operations | 50 moves | `test_ph_005_rapid_file_operations` — <30s total, avg <0.5s per move | `temp_project_dir` |
| Memory usage | 200 files | `test_memory_usage_monitoring` — scan <100MB, 10 ops <20MB additional | `psutil` |
| CPU usage | 100 files | `test_cpu_usage_monitoring` — avg CPU <80%, peak <95% | `psutil` |

**Test File**: [`tests/performance/test_large_projects.py`](../../../tests/performance/test_large_projects.py) (7 methods)

## Test Implementation Roadmap

### Priority Order

1. **High Priority** (Implemented ✅)
   - [x] Shared fixtures accessible across all subdirectories
   - [x] Builder classes for complex test setups
   - [x] Performance benchmarks for large projects
   - [x] Custom assertions with clear error messages

2. **Medium Priority** (Implemented ✅)
   - [x] Memory and CPU monitoring tests
   - [x] Content generators for multiple file types
   - [x] Test configuration presets

3. **Low Priority** (Gaps identified)
   - [ ] `run_tests.py` CLI execution modes (TDD: 10 execution modes — not tested via test code)
   - [ ] Marker-based filtering (`@pytest.mark.slow` registered but not in pytest config)
   - [ ] Category execution isolation (`--unit` only runs `tests/unit/`)
   - [ ] Fixture independence verification (one test's fixture doesn't affect another's)
   - [ ] `conftest.py` fixture availability from nested subdirectories

### Coverage Gaps

- **Unregistered marker**: `@pytest.mark.slow` used in `test_large_projects.py` but not registered in pytest configuration — causes `PytestUnknownMarkWarning`
- **CLI test runner**: `run_tests.py` has 10 execution modes but none are tested programmatically
- **Fixture scope**: No explicit test that fixtures are available from all subdirectories
- **Test discovery count**: Documentation says "247+" but pytest collects 328 tests — count is outdated

## AI Agent Session Handoff Notes

### Implementation Context

**Feature Summary**: Pytest infrastructure with shared fixtures, builder utilities, and performance benchmarks.
**Test Focus**: Performance under load, infrastructure correctness (validated by usage).
**Key Challenges**: Performance tests are inherently flaky due to hardware variance; psutil dependency optional.

### Files to Reference

- **TDD**: [`doc/product-docs/technical/architecture/design-docs/tdd/tdd-4-1-1-test-suite-t2.md`](../../../doc/product-docs/technical/architecture/design-docs/tdd/tdd-4-1-1-test-suite-t2.md)
- **Infrastructure**: [`tests/conftest.py`](../../../tests/conftest.py), [`tests/utils.py`](../../../tests/utils.py), [`tests/test_config.py`](../../../tests/test_config.py)
- **Performance Tests**: [`tests/performance/test_large_projects.py`](../../../tests/performance/test_large_projects.py)
- **Config**: [`pyproject.toml`](../../../pyproject.toml) (test config)

---

_Retrospective Test Specification — documents existing test suite as of 2026-02-24._
