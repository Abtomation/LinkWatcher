---
id: PD-REF-127
type: Document
category: General
version: 1.0
created: 2026-04-01
updated: 2026-04-01
refactoring_scope: Replace real project paths in test content strings with synthetic namespace to prevent LinkWatcher from mutating test assertions during directory moves
priority: Medium
target_area: test/automated
---

# Refactoring Plan: Replace real project paths in test content strings with synthetic namespace to prevent LinkWatcher from mutating test assertions during directory moves

## Overview
- **Target Area**: test/automated
- **Priority**: Medium
- **Created**: 2026-04-01
- **Author**: AI Agent & Human Partner
- **Status**: Completed

## Refactoring Scope

Test content strings in 14 test files use real project directory names (`doc`, `process-framework`) as path references. When LinkWatcher runs and real files move, it parses these test files and rewrites the path strings — mutating test assertions unintentionally. Git history confirms this has happened in at least 3 bulk-update commits (b3b29e2, ff5c27f, 07b1e51).

### Current Issues

- **Test mutation**: 176 occurrences across 14 files use real project paths as test content strings
- **Unintended coupling**: Test assertions drift when project structure changes
- **No guardrails**: No documented convention preventing future tests from using real paths
- **No existing tech debt item**: Identified during human-partner discussion (2026-04-01)

### Scope Discovery

- **Original Description**: User observed test suite uses examples overlapping with real `doc` and `process-framework` directories, causing confusion when structure changes trigger LinkWatcher updates in test files
- **Actual Scope Findings**: 176 path occurrences across 14 test files. Synthetic paths (`vendor/`, `src/`) that don't exist in the real project are already safe. The `conftest.py` fixtures properly use `tmp_path` but define no shared path namespace constant
- **Scope Delta**: Scope matches. The synthetic paths (vendor/, src/) can be left as-is since they don't collide with real project directories

### Refactoring Goals

- Goal 1: Replace all real project path references (`doc`, `process-framework`) in test content strings with a synthetic namespace (`alpha-project/`)
- Goal 2: Define a shared constant `TEST_PROJECT_ROOT` in `conftest.py` for future test authors
- Goal 3: Document test isolation rules in test-infrastructure-guide.md and test-file-creation-guide.md

## Current State Analysis

### Baseline

- **Test suite**: 649 passed, 5 skipped, 6 xfailed (2026-04-01)
- **Affected files**: 14 test files + conftest.py (documentation update target)
- **Affected occurrences**: ~176 path string references

### Affected Components

- `test/automated/conftest.py` — Add `TEST_PROJECT_ROOT` constant
- `test/automated/parsers/test_markdown.py` — 11 occurrences
- `test/automated/parsers/test_python.py` — 11 occurrences
- `test/automated/parsers/test_powershell.py` — 14 occurrences
- `test/automated/parsers/test_yaml.py` — 4 occurrences
- `test/automated/parsers/test_json.py` — 2 occurrences
- `test/automated/unit/test_database.py` — 24 occurrences
- `test/automated/unit/test_reference_lookup.py` — 19 occurrences
- `test/automated/unit/test_updater.py` — 31 occurrences
- `test/automated/unit/test_validator.py` — 19 occurrences
- `test/automated/integration/test_link_updates.py` — 9 occurrences
- `test/automated/test_directory_move_detection.py` — 20 occurrences
- `test/automated/bug-validation/PD-BUG-020_single_file_move_validation.py` — 5 occurrences
- `test/automated/bug-validation/PD-BUG-021_directory_path_detection_validation.py` — 7 occurrences
- `process-framework/guides/03-testing/test-infrastructure-guide.md` — Add isolation rules section
- `process-framework/guides/03-testing/test-file-creation-guide.md` — Add isolation rules section

### Dependencies and Impact

- **Internal Dependencies**: All test files are independent — changes to string content don't affect each other
- **Risk Assessment**: Low — purely string replacement in test content, no logic changes. All tests must pass identically after refactoring

## Refactoring Strategy

### Approach

Replace real project path prefixes in test content strings with a synthetic namespace that cannot collide with the real project structure. The synthetic namespace `alpha-project/` is chosen because it doesn't exist anywhere in the repo. Sub-paths mirror the original structure for readability (e.g., `doc/guides/setup.md` → `alpha-project/docs/setup.md`).

### Specific Techniques

- **String replacement**: Replace `doc` and `process-framework` path prefixes in test content strings with `alpha-project/` equivalents
- **Constant extraction**: Define `TEST_PROJECT_ROOT = "alpha-project"` in conftest.py for future test authors
- **Preserve test semantics**: Each replacement must maintain the same path structure depth and file extension to preserve parser behavior being tested

### Implementation Plan

1. **Phase 1: Infrastructure** — Add `TEST_PROJECT_ROOT` constant to conftest.py
2. **Phase 2: Parser tests** — Replace paths in test_markdown.py, test_python.py, test_powershell.py, test_yaml.py, test_json.py. Run parser tests after each file.
3. **Phase 3: Unit tests** — Replace paths in test_database.py, test_reference_lookup.py, test_updater.py, test_validator.py. Run unit tests after each file.
4. **Phase 4: Integration + bug-validation tests** — Replace paths in test_link_updates.py, test_directory_move_detection.py, PD-BUG-020, PD-BUG-021. Run full suite.
5. **Phase 5: Documentation** — Add "Test Isolation Rules" section to test-infrastructure-guide.md and test-file-creation-guide.md

## Testing Strategy

### Existing Test Coverage

- **Full suite**: 649 passed, 5 skipped, 6 xfailed — this IS the test coverage since we're modifying the test files themselves
- **No manual test groups affected**: This refactoring changes test internals only, not production code

### Testing Approach During Refactoring

- **Regression**: Run targeted test category after each file change (e.g., `pytest test/automated/parsers/` after parser changes)
- **Full suite**: Run `pytest test/automated/` after completing each phase and at end
- **New Test Requirements**: None — existing tests validate their own correctness

## Success Criteria

### Functional Requirements

- [x] All 649 tests continue to pass with identical results
- [x] Zero real project paths (`doc`, `process-framework`) remain in test content strings
- [x] `TEST_PROJECT_ROOT` constant defined in conftest.py
- [x] Test isolation rules documented in two guide files

## Implementation Tracking

### Progress Log

| Date | Phase | Completed Work | Issues Encountered | Next Steps |
|------|-------|----------------|-------------------|------------|
| 2026-04-01 | Phase 1 | Added TEST_PROJECT_ROOT to conftest.py | None | Phase 2 |
| 2026-04-01 | Phase 2 | Replaced paths in 5 parser test files | None | Phase 3 |
| 2026-04-01 | Phase 3 | Replaced paths in 4 unit test files | 2 assertion fixes needed for path variation depth changes | Phase 4 |
| 2026-04-01 | Phase 4 | Replaced paths in 4 integration/bug-validation files | None | Phase 5 |
| 2026-04-01 | Phase 5 | Updated test-infrastructure-guide.md and test-file-creation-guide.md | None | Finalization |

## Results and Lessons Learned

### Achievements

- Eliminated all 176 real project path references from 14 test files
- All 649 tests pass identically to baseline (649 passed, 5 skipped, 6 xfailed)
- Established `TEST_PROJECT_ROOT` convention and documented isolation rules in 2 guides
- Test suite is now structurally independent from project directory layout

### Challenges and Solutions

- Path variation depth change: Replacing `doc/sub/file.md` (3 parts) with `alpha-project/docs/sub/file.md` (4 parts) changed the "first dir stripped" variation from `sub/file.md` to `docs/sub/file.md`. Two assertions in test_reference_lookup.py needed updating → Fixed by adjusting assertions to match actual path variation behavior.

### Lessons Learned

- When replacing path prefixes in tests that verify path-manipulation logic, the number of path segments matters. Assertions about "stripped" or "relative" path variants must be updated to reflect the new segment count.

### Remaining Technical Debt

- None introduced. Test specification markdown files in `test/specifications/` still contain real links to project docs, but these are documentation references (not parsed test content) and are managed by LinkWatcher intentionally.

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
