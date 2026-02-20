---
id: PD-TDD-030
type: Product Documentation
category: Technical Design Document
version: 1.0
created: 2026-02-20
updated: 2026-02-20
feature_id: 4.1.6
feature_name: Test Fixtures
tier: 2
retrospective: true
---

# Test Fixtures - Technical Design Document (Tier 2)

> **Retrospective Document**: This TDD describes the existing implemented architecture of the LinkWatcher Test Fixtures, documented after implementation during framework onboarding (PF-TSK-066).
>
> **Source**: Derived from [4.1.6 Implementation State](../../../../process-framework/state-tracking/features/4.1.6-test-fixtures-implementation-state.md) and source code analysis.

## Technical Overview

Test fixtures are organized into three tiers: static fixture files in `tests/fixtures/` (sample markdown, YAML, JSON), manual markdown test cases in `manual_markdown_tests/` (24 files with interactive runner), and a complete manual test project in `manual_test/` (13 files). Programmatic fixture data is also available via `tests/test_config.py` constants.

## Component Architecture

### Fixture Organization

| Location | Type | Contents | Consumers |
|----------|------|----------|-----------|
| `tests/fixtures/` | Static files | `sample_markdown.md`, `sample_config.yaml`, `sample_data.json` | Parser tests, unit tests |
| `manual_markdown_tests/` | Manual test cases | 24 markdown files (LR-001–MP-009) + `test_runner.py` | Interactive parser validation |
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

## Key Technical Decisions

### Static vs. Dynamic Fixture Data

Static fixture files provide deterministic, human-readable inputs for exact-match assertions. They complement (not replace) the `TestProjectBuilder` from 4.1.7 which generates dynamic project structures for complex scenarios. Static fixtures are preferred when test correctness depends on known, inspectable content.

### Separate Manual Test Infrastructure

Manual test scripts (`create_test_structure.py`, `cleanup_test.py`) are kept separate from the pytest suite. Automated tests use temporary directories with automatic cleanup; manual/exploratory testing needs persistent structures. The `test_runner.py` in `manual_markdown_tests/` provides interactive parser validation outside the pytest framework.

## Dependencies

| Component | Usage |
|-----------|-------|
| `linkwatcher/parsers/markdown.py` | `MarkdownParser` used by `manual_markdown_tests/test_runner.py` |
| `tests/conftest.py` | pytest fixtures consume static fixture data via `file_helper` |
| PyYAML, json (stdlib) | Used for YAML/JSON fixture file content |
