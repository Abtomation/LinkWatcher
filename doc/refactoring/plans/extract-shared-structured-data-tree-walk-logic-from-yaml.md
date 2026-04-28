---
id: PD-REF-165
type: Document
category: General
version: 1.0
created: 2026-04-09
updated: 2026-04-09
debt_item: TD180
priority: Medium
refactoring_scope: Extract shared structured-data tree-walk logic from YAML/JSON parsers
target_area: src/linkwatcher/parsers
---

# Refactoring Plan: Extract shared structured-data tree-walk logic from YAML/JSON parsers

## Overview
- **Target Area**: src/linkwatcher/parsers
- **Priority**: Medium
- **Created**: 2026-04-09
- **Author**: AI Agent & Human Partner
- **Status**: Completed
- **Debt Item**: TD180

## Refactoring Scope

YamlParser and JsonParser share duplicated structural logic for recursive tree walking, file/directory path classification, and embedded path extraction. Both parsers independently implement the same patterns with slightly different dedup mechanisms.

### Current Issues

- Duplicated recursive tree walk: both `_extract_yaml_file_refs` and `_extract_json_file_refs` have identical dict/list recursion and identical `is_file`/`is_dir` classification logic (~30 lines each)
- Duplicated `_extract_embedded_paths`: both use the same `path_pattern` regex and path-finding loop, though YAML adds multiline handling (PD-BUG-079) and JSON uses `claimed` set
- Same `path_pattern` regex compiled independently in both constructors
- Different dedup mechanisms solving the same problem: YAML uses `_find_next_occurrence` with `used_positions` from existing refs; JSON uses `_find_unclaimed_line` with a separate `claimed` set

### Scope Discovery

- **Original Tech Debt Description**: "~80% structural logic overlap, ~400 lines. Extract common StructuredDataParser base class."
- **Actual Scope Findings**: Total ~400 lines correct. Overlap is ~60-65%, not 80%. The recursive tree walk and file/dir classification are nearly identical. Line-finding and embedded path extraction have meaningful differences due to format-specific edge cases (JSON quotes/claimed set, YAML multiline blocks).
- **Scope Delta**: Narrower than originally described. A full base class extraction would force format-specific dedup logic into an over-abstract interface. Modified scope: extract only the truly shared logic (tree walk, path classification, embedded path core loop) into shared helper methods on BaseParser or a mixin.

### Refactoring Goals

- Eliminate duplicated recursive tree-walk logic between YAML and JSON parsers
- Share the `path_pattern` regex and core embedded path extraction loop
- Preserve format-specific dedup mechanisms (`used_positions` vs `claimed`) and YAML's multiline handling
- Maintain 100% behavior preservation — no functional changes

## Current State Analysis

### Affected Components

- `src/linkwatcher/parsers/yaml_parser.py` (210 lines) — YamlParser with `_extract_yaml_file_refs`, `_find_next_occurrence`, `_extract_embedded_paths`
- `src/linkwatcher/parsers/json_parser.py` (189 lines) — JsonParser with `_extract_json_file_refs`, `_find_unclaimed_line`, `_extract_embedded_paths`
- `src/linkwatcher/parsers/base.py` (82 lines) — BaseParser base class, target for shared methods

### Dependencies and Impact

- **Internal Dependencies**: `src/linkwatcher/parsers/__init__.py` imports both parsers; `src/linkwatcher/parser.py` dispatches to them via extension mapping. Tests in `test/automated/parsers/test_yaml.py` (18 tests) and `test/automated/parsers/test_json.py` (17 tests, 1 xfail).
- **External Dependencies**: None
- **Risk Assessment**: Low — structural-only refactoring, no public API changes, comprehensive test coverage

### Test Baseline

- **Full suite**: 757 passed, 5 skipped, 4 deselected, 4 xfailed (46.77s)
- **Parser tests (YAML+JSON)**: 35 passed, 1 xfailed
- **Pre-existing failures**: None (0 failed)

## Refactoring Strategy

### Approach

Add shared helper methods to `BaseParser` that encapsulate the duplicated tree-walk and path-classification logic. Each parser calls the shared methods but retains its own dedup mechanism and format-specific embedded path handling.

### Specific Techniques

- **Extract Method (Pull Up)**: Move the recursive tree-walk logic (dict/list recursion + string classification) into a shared `_walk_structured_data` method on BaseParser
- **Extract Method (Pull Up)**: Move the `path_pattern` regex and core embedded path iteration into a shared `_iter_embedded_paths` method on BaseParser
- **Preserve format-specific methods**: Keep `_find_next_occurrence` (YAML), `_find_unclaimed_line` (JSON), and format-specific `_extract_embedded_paths` overrides in their respective parsers

### Implementation Plan

1. **Phase 1**: Add shared methods to BaseParser
   - Add `path_pattern` regex as class attribute on BaseParser
   - Add `_walk_structured_data()` method that yields string values from recursive dict/list/str traversal
   - Add `_classify_path()` method encapsulating is_file/is_dir logic with os.path.splitext

2. **Phase 2**: Refactor YamlParser to use shared methods
   - Replace `_extract_yaml_file_refs` recursive body with call to `_walk_structured_data` + `_classify_path`
   - Remove duplicated `path_pattern` from `__init__`
   - Run YAML parser tests after each change

3. **Phase 3**: Refactor JsonParser to use shared methods
   - Replace `_extract_json_file_refs` recursive body with call to `_walk_structured_data` + `_classify_path`
   - Remove duplicated `path_pattern` from `__init__`
   - Run JSON parser tests after each change

## Testing Strategy

### Existing Test Coverage

- **YAML parser tests**: 18 tests covering simple values, nested structures, arrays, multiline, comments, anchors, edge cases, directory paths, compound strings
- **JSON parser tests**: 17 tests (1 xfail) covering string values, nested objects, arrays, edge cases, duplicate line numbers, directory paths, compound strings
- Coverage is sufficient — both happy paths and edge cases for all refactored code paths are exercised

### Testing Approach During Refactoring

- **Regression Testing**: Run `pytest test/automated/parsers/test_yaml.py test/automated/parsers/test_json.py` after each phase
- **Full Suite**: Run `Run-Tests.ps1 -All` after all changes to verify no cross-parser regressions
- **New Test Requirements**: None expected — structural-only refactoring

### Functional Requirements

- [ ] All existing functionality preserved
- [ ] No breaking changes to public APIs
- [ ] All existing tests continue to pass
- [ ] Performance maintained or improved

## Implementation Tracking

### Progress Log

| Date | Phase | Completed Work | Issues Encountered | Next Steps |
|------|-------|----------------|-------------------|------------|
| 2026-04-09 | Phase 1 | Added `_path_pattern`, `_walk_structured_data`, `_classify_path` to BaseParser | None | Refactor YAML parser |
| 2026-04-09 | Phase 2 | Refactored YamlParser to use shared methods | None | Refactor JSON parser |
| 2026-04-09 | Phase 3 | Refactored JsonParser to use shared methods | Stack iteration order broke integration test | Fixed by reversing push order |
| 2026-04-09 | Validation | Full suite: 757 passed (identical to baseline) | None | Finalization |

## Results and Lessons Learned

### Achievements

- Eliminated duplicated recursive tree-walk logic from both parsers (single source of truth in `_walk_structured_data`)
- Eliminated duplicated path classification logic (`_classify_path` replaces 6 lines in each parser)
- Shared `_path_pattern` regex compiled once on the base class instead of per-instance in each parser
- Removed unnecessary `__init__` overrides, `os.path` and `re` imports from both parsers
- Line count: base.py +44, yaml_parser.py -22, json_parser.py -26 (net -4 lines; value is in deduplication, not line reduction)

### Challenges and Solutions

- Stack-based iteration visited dict items in reverse insertion order, breaking `_search_start_line` forward-scan optimization → Fixed by pushing items in reversed order so they pop in insertion order

### Lessons Learned

- When converting recursion to iteration with a stack, insertion order matters if downstream code relies on sequential scanning assumptions (like `_search_start_line`)

### Remaining Technical Debt

- The `_extract_embedded_paths` methods still have ~60% overlap between parsers, but the differences (YAML multiline handling vs JSON claimed-set dedup) are meaningful enough that further extraction would create an overly abstract interface. Acceptable as-is.

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
