---
id: PD-REF-023
type: Document
category: General
version: 1.0
created: 2026-03-02
updated: 2026-03-02
target_area: src/linkwatcher/handler.py
priority: Medium
refactoring_scope: Remove dual print+logger output pattern in handler.py (TD010)
---

# Refactoring Plan: Remove dual print+logger output pattern in handler.py (TD010)

## Overview
- **Target Area**: src/linkwatcher/handler.py
- **Priority**: Medium
- **Created**: 2026-03-02
- **Author**: AI Agent & Human Partner
- **Status**: Completed

## Refactoring Scope

### Current Issues
- 55 `print()` calls and 46 `logger.*` calls throughout handler.py
- 39 locations where print and logger output the same event — redundant maintenance burden
- 6 print-only error/warning messages with no persistent logging
- 1 residual diagnostic print firing 4x per file move (BUG-A, fixed during refactoring)

### Refactoring Goals
- Eliminate all 39 paired print+logger duplicates
- Assign each message to exactly ONE channel: print for live console progress or logger for persistent records
- Convert print-only errors/warnings to logger calls for proper persistent logging
- Maintain user-facing console output for manual testing scenarios

## Current State Analysis

### Code Quality Metrics (Baseline)
- **File Length**: 1365 lines
- **print() Calls**: 55
- **logger.* Calls**: 46
- **Paired Duplicates**: 39
- **Print-only errors**: 6

### Affected Components
- `src/linkwatcher/handler.py` — all changes confined to this file

### Dependencies and Impact
- **Internal Dependencies**: 19 test files covering handler.py functionality
- **External Dependencies**: None
- **Risk Assessment**: Low — output-only changes, no behavioral modification

## Refactoring Strategy

### Approach
Per-message classification: evaluate every print/logger call and assign to ONE channel based on purpose:
- **print()**: Live console feedback for manual testing (progress indicators, matched file counters)
- **logger.\*()**: Persistent logging of important events (errors, core events, completion summaries, warnings)

### Channel Assignment Rules
1. **Keep LOGGER, remove print** (31 locations): Errors, core events (file_moved, file_deleted, file_created, directory_moved), completion summaries, warnings, diagnostic events
2. **Keep PRINT, remove logger** (8 locations): Progress indicators ("Updating N references...", "Matched 3/5: filename", "Buffered N files for move detection")
3. **Keep both** (1 location): Broken reference detail in `_process_delayed_delete` — logger has structured data, print has readable list
4. **Convert print→logger** (6 locations): Print-only errors/warnings that needed persistent records
5. **Remove redundant print** (1 location): Already covered by logger-only call

### Implementation Plan
1. **Batch 1**: Event methods — on_moved, on_deleted, on_created, on_error
2. **Batch 2**: Reference lookup methods — _find_references_multi_format, _handle_file_moved
3. **Batch 3**: Directory/delete methods — _handle_directory_moved, _handle_file_deleted, _process_delayed_delete
4. **Batch 4**: Remaining event methods — _handle_directory_deleted, _handle_file_created, _handle_detected_move
5. **Batch 5**: Utility methods — _rescan methods, _update_links_within_moved_file, _calculate_updated_relative_path
6. **Batch 6**: Dir move detection methods — settle/timeout/processing methods

## Testing Strategy

### Existing Test Coverage
- 19 test files covering handler.py across unit, integration, and complex scenario tests
- Full suite: 344 passed, 9 pre-existing failures (confirmed identical before/after refactoring)

### Testing Approach During Refactoring
- Full test suite run after all changes applied
- Pre-existing failures verified via git stash comparison against unmodified code
- Zero regressions confirmed

## Results

### Final Metrics
- **File Length**: 1275 lines (was 1365, -90 lines, -6.6%)
- **print() Calls**: 23 (was 55, -58%)
- **logger.\* Calls**: 41 (was 46, -11%)
- **Paired Duplicates**: 0 (was 39, -100%)
- **Print-only errors**: 0 (was 6, all converted to logger)

### Achievements
- Eliminated all 39 paired print+logger duplicates
- 6 print-only errors/warnings converted to proper structured logger calls
- Fixed 1 residual diagnostic print (BUG-A) that fired 4x per file move
- TD012 (inline imports) resolved incidentally — linter auto-moved `import re` and `import shutil` to module level

### Bug Discovery
During systematic code review, discovered 8 issues (3 filed as bug reports, 4 added as tech debt):

| ID | Severity | Description |
|---|---|---|
| PD-BUG-024 | High | Incorrect relative path calculation in `_collect_path_updates` for cross-depth moves |
| PD-BUG-025 | Medium | Greedy `str.replace` for non-markdown link types can corrupt file content |
| PD-BUG-026 | Medium | `self.stats` dict mutated from multiple threads without synchronization |
| TD015 | Low | Redundant DB queries in `_collect_path_updates` |
| TD016 | Medium | Double-rescan of moved file links |
| TD017 | Medium | Inconsistent DB update strategies between file and directory moves |
| TD018 | Low | Per-file move detection timers never tracked/cancelled |

### Lessons Learned
- Per-message classification (rather than blanket "remove all prints") preserved the user's manual testing workflow while eliminating redundancy
- The logger's console handler means logger calls are visible on console in structured format — removing paired prints doesn't lose console visibility for important events
- Code review during output refactoring is effective at revealing logic bugs because you must understand each code path to classify its output

### Remaining Technical Debt
- TD005: God class (10+ responsibilities) — root cause of complexity
- TD007: Mega method _handle_file_moved
- TD009: Duplicated stale retry logic
- TD013: Duplicate synthetic event classes
- TD015-TD018: New items discovered during this refactoring

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
<!-- - [Technical Debt Assessment PF-TDA-001](/process-framework/assessments/technical-debt/assessments/handler-module-structural-debt-assessment.md) - Removed: file deleted -->
