---
id: PD-TDD-029
type: Product Documentation
category: Technical Design Document
version: 1.0
created: 2026-02-20
updated: 2026-02-20
feature_id: 4.1.4
feature_name: Parser Tests
tier: 2
retrospective: true
---

# Parser Tests - Technical Design Document (Tier 2)

> **Retrospective Document**: This TDD describes the existing implemented architecture of the LinkWatcher Parser Tests, documented after implementation during framework onboarding (PF-TSK-066).
>
> **Source**: Derived from [4.1.4 Implementation State](../../../../process-framework/state-tracking/features/4.1.4-parser-tests-implementation-state.md) and source code analysis.

## Technical Overview

Parser tests provide one-to-one test coverage for each LinkWatcher parser implementation. The `tests/parsers/` directory contains 7 test files that directly import and test individual parser classes. Tests follow a parse-and-assert pattern using custom assertions from conftest.py, with heavy edge case coverage reflecting the critical role of parser accuracy.

## Component Architecture

### Test File Mapping

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

## Key Technical Decisions

### One Test File Per Parser

One-to-one mapping ensures clear test ownership. Each parser's unique syntax rules get dedicated test focus. Easy to run parser-specific tests in isolation.

### Custom Assertion Helpers

`assert_reference_found` and `assert_reference_not_found` eliminate repetitive list-comprehension assertions. They provide clear error messages showing actual found references and support optional `link_type` parameter for precise matching.

### Edge Case Priority

80+ methods with heavy edge case emphasis because parser correctness directly determines link update accuracy. A missed reference means a broken link after file move; a false positive means corrupting unrelated content.

## Dependencies

| Component | Usage |
|-----------|-------|
| `tests/conftest.py` | `temp_project_dir`, `file_helper` fixtures; custom assertions |
| `linkwatcher.models.LinkReference` | Test data verification |
| All `linkwatcher.parsers.*` classes | Test targets |
| `pytest` (>=7.0) | Test framework |
