---
id: PD-REF-049
type: Document
category: General
version: 1.0
created: 2026-03-03
updated: 2026-03-03
refactoring_scope: Replace 8-module stdlib regex with comprehensive set lookup using sys.stdlib_module_names (3.10+) with fallback
priority: Medium
target_area: src/linkwatcher/parsers/python.py
---

# Refactoring Plan: Replace 8-module stdlib regex with comprehensive set lookup using sys.stdlib_module_names (3.10+) with fallback

## Overview
- **Target Area**: src/linkwatcher/parsers/python.py
- **Priority**: Medium
- **Created**: 2026-03-03
- **Author**: AI Agent & Human Partner
- **Status**: Completed

## Refactoring Scope
TD038: PythonParser stdlib exclusion list only has 8 modules — causes false-positive file references for unlisted stdlib imports.

### Current Issues
- `stdlib_import_pattern` regex only lists 8 modules: `os|sys|re|json|datetime|pathlib|typing|collections`
- Python 3.11 stdlib has 305 modules; 297 are unrecognized by the current filter
- Dotted stdlib imports with 3+ segments (e.g., `from email.mime.text import MIMEText`, `from xml.etree.ElementTree import parse`) pass through the filter and `_looks_like_local_import()` matches them as false-positive `python-import` references
- The regex approach doesn't scale for comprehensive coverage

### Refactoring Goals
- Eliminate false-positive file references from stdlib imports
- Use authoritative `sys.stdlib_module_names` set (Python 3.10+) with comprehensive fallback for 3.8/3.9
- Replace regex-based pattern with efficient set membership check

## Current State Analysis

### Code Quality Metrics (Baseline)
- **Stdlib modules recognized**: 8 of 305 (2.6% coverage)
- **Test baseline**: 7/7 parser tests pass
- **False-positive surface**: Any dotted stdlib import with 3+ segments triggers `_looks_like_local_import()`

### Affected Components
- `src/linkwatcher/parsers/python.py` — PythonParser class: replace `stdlib_import_pattern` regex with set-based lookup
- `tests/parsers/test_python.py` — Add test for previously-unfiltered stdlib imports

### Dependencies and Impact
- **Internal Dependencies**: `src/linkwatcher/handler.py` and `src/linkwatcher/service.py` use PythonParser via parser registry; no interface change
- **External Dependencies**: None
- **Risk Assessment**: Low — behavior change is strictly narrowing (fewer false positives, no new matches)

## Refactoring Strategy

### Approach
Replace `stdlib_import_pattern` regex with a module-level `_STDLIB_TOP_LEVEL_MODULES` frozenset. Use `sys.stdlib_module_names` (Python 3.10+) at import time, falling back to a hardcoded frozenset of public stdlib top-level modules for Python 3.8/3.9. In `parse_content`, extract the top-level module name from import lines and check set membership.

### Specific Techniques
- **Replace regex with set lookup**: Extract top-level module name via simple regex, check against frozenset — O(1) lookup instead of alternation-based regex
- **Version-adaptive stdlib source**: `try: sys.stdlib_module_names` / `except AttributeError: fallback` pattern
- **Import line extraction**: New regex `r"^\s*(?:import|from)\s+(\w+)"` to capture just the top-level module name

### Implementation Plan
1. **Phase 1**: Add module-level stdlib set
   - Define `_STDLIB_TOP_LEVEL_MODULES` using `sys.stdlib_module_names` with fallback
   - Filter to public modules only (no `_` prefix) in the fallback set

2. **Phase 2**: Refactor PythonParser.__init__ and parse_content
   - Remove `self.stdlib_import_pattern` from `__init__`
   - Add simple `_STDLIB_IMPORT_RE` regex at module level to extract top-level module name
   - Replace `self.stdlib_import_pattern.match(line)` with set lookup in `parse_content`

3. **Phase 3**: Add test coverage
   - Add test verifying dotted stdlib imports (e.g., `from email.mime.text import MIMEText`) are now filtered
   - Verify existing tests still pass

## Testing Strategy

### Existing Test Coverage
- **Unit Tests**: 7 tests in `tests/parsers/test_python.py` — covers initialization, import parsing, false-positive avoidance, positions, empty file, error handling
- **Integration Tests**: PythonParser tested indirectly via handler/service integration tests
- **Stdlib filtering test**: `test_skip_import_modules` covers `os`, `sys`, `json`, `pathlib`, `datetime` but NOT dotted stdlib imports

### Testing Approach During Refactoring
- **Regression**: Run all 7 existing parser tests after each change
- **New Test**: Add `test_skip_dotted_stdlib_imports` verifying `email.mime.text`, `xml.etree.ElementTree`, `logging.handlers` are filtered
- **Full Suite**: Run complete test suite after implementation

## Success Criteria

### Quality Improvements
- **Stdlib coverage**: 8 → 305 modules (100% on Python 3.10+, ~200 public modules on 3.8/3.9)
- **Maintainability**: Regex alternation replaced with declarative set — easier to extend
- **Technical Debt**: TD038 resolved

### Functional Requirements
- [ ] All existing functionality preserved (no new false negatives for actual file references)
- [ ] No breaking changes to public APIs
- [ ] All existing tests continue to pass
- [ ] Dotted stdlib imports no longer produce false-positive references

## Implementation Tracking

### Progress Log
| Date | Phase | Completed Work | Issues Encountered | Next Steps |
|------|-------|----------------|-------------------|------------|
| 2026-03-03 | Phase 1 | Module-level `_STDLIB_TOP_LEVEL_MODULES` frozenset with `sys.stdlib_module_names` + fallback | None | Phase 2 |
| 2026-03-03 | Phase 2 | Removed `self.stdlib_import_pattern` regex, added `_IMPORT_MODULE_RE` + set lookup in `parse_content` | None | Phase 3 |
| 2026-03-03 | Phase 3 | Added `test_skip_dotted_stdlib_imports` test (7 dotted stdlib assertions) | None | Finalize |

### Metrics Tracking
| Metric | Baseline | Final | Target | Status |
|--------|----------|-------|--------|--------|
| Stdlib modules recognized | 8 | 305 (3.10+) / ~170 (3.8/3.9) | 100% on 3.10+ | Achieved |
| Parser tests | 7/7 | 8/8 | All pass + new test | Achieved |
| Full test suite | 386 pass | 387 pass | No regressions | Achieved |

## Results and Lessons Learned

### Final Metrics
- **Stdlib coverage**: 8 → 305 modules (3725% improvement on Python 3.10+)
- **Approach**: Regex alternation → O(1) frozenset lookup
- **Technical Debt**: TD038 resolved

### Achievements
- Eliminated false-positive `python-import` references for all dotted stdlib imports
- Used `sys.stdlib_module_names` for automatic coverage on Python 3.10+
- Maintained backward compatibility with Python 3.8/3.9 via comprehensive fallback

### Challenges and Solutions
- No challenges encountered — straightforward refactoring

### Remaining Technical Debt
- None introduced by this refactoring

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
- [Code Quality Standards](/process-framework/guides/03-testing/code-quality-standards.md)
- [Testing Guidelines](/process-framework/guides/03-testing/testing-guidelines.md)
