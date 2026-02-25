---
id: PF-TSP-038
type: Process Framework
category: Test Specification
version: 1.0
created: 2026-02-24
updated: 2026-02-24
feature_id: 1.1.1
feature_name: File System Monitoring
tdd_path: doc/product-docs/technical/architecture/design-docs/tdd/tdd-1-1-1-file-system-monitoring-t2.md
test_tier: 2
retrospective: true
---

# Test Specification: File System Monitoring

> **Retrospective Document**: This test specification describes the existing test suite for File System Monitoring, documented after implementation during framework onboarding. Content is derived from analysis of existing test files.

## Overview

This document provides comprehensive test specifications for the **File System Monitoring** feature (ID: 1.1.1), derived from the Technical Design Document [PD-TDD-023](../../../doc/product-docs/technical/architecture/design-docs/tdd/tdd-1-1-1-file-system-monitoring-t2.md).

**Test Tier**: 2 (Unit + Integration)
**TDD Reference**: [TDD PD-TDD-023](../../../doc/product-docs/technical/architecture/design-docs/tdd/tdd-1-1-1-file-system-monitoring-t2.md)

## Feature Context

### TDD Summary

File System Monitoring uses the `LinkMaintenanceHandler` class to process watchdog events. It implements a state-machine approach: native moves via `on_moved`, cross-tool moves via delete+create pairing with a 2-second timer buffer, and directory moves via recursive walk. The handler coordinates with database, parser, and updater subsystems.

### Test Complexity Assessment

**Selected Tier**: 2 — Event handling with timer-based move detection, directory walking, and multi-subsystem coordination.

## Cross-References

### Functional Requirements Reference

> **Primary Documentation**: [FDD PD-FDD-024](../../../doc/product-docs/functional-design/fdds/fdd-1-1-1-file-system-monitoring.md)

**Acceptance Criteria to Test**:
- File move detected within seconds regardless of tool used
- All files with links to moved file have those links updated
- Directory move updates links for every file within it
- Delete+create pair within 2 seconds treated as move
- Content save (without move) does NOT trigger link maintenance

### Technical Design Reference

> **Primary Documentation**: [TDD PD-TDD-023](../../../doc/product-docs/technical/architecture/design-docs/tdd/tdd-1-1-1-file-system-monitoring-t2.md)

**Component Testing Strategy**:
- `LinkMaintenanceHandler.on_moved()` — native move event routing
- `LinkMaintenanceHandler._handle_file_moved()` — 4-step pipeline: find refs → update files → rescan → log
- `LinkMaintenanceHandler._handle_dir_moved()` — walk + path mapping
- Delete+create pairing — `pending_deletes` buffer with timer callbacks
- File filtering — `should_monitor_file()` and `should_ignore_directory()`

## Test Categories

### Unit Tests

| Component | Test Focus | Key Test Cases | Fixtures |
|-----------|-----------|----------------|----------|
| Move detection | Delete+create pairing | `test_move_detection_logic` — simulates pending delete + file creation, verifies handler detects move and updates references | Manual setup |

**Test File**: [`tests/test_move_detection.py`](../../../tests/test_move_detection.py)
**Status**: Implemented (1 test method)

### Integration Tests

#### File Movement

| Flow | Test Scenario | Expected Outcome | Fixtures |
|------|---------------|-----------------|----------|
| Single rename | `test_fm_001_single_file_rename` | Markdown and YAML references updated to new filename | `temp_project_dir`, `file_helper` |
| Cross-directory move | `test_fm_002_file_move_different_directory` | Root-level and relative path references recalculated | `temp_project_dir`, `file_helper` |
| Move + rename | `test_fm_003_file_move_with_rename` | References in markdown, YAML, JSON, Python all updated | `temp_project_dir`, `file_helper` |
| Directory rename | `test_fm_004_directory_rename` | All references to files within directory updated | `temp_project_dir`, `file_helper` |
| Nested directory move | `test_fm_005_nested_directory_movement` | Deep path chains updated correctly | `temp_project_dir`, `file_helper` |
| Non-existent file | `test_move_nonexistent_file` | No crash, database remains clean | `temp_project_dir` |
| Overwrite target | `test_move_to_existing_file` | References updated from source to destination | `temp_project_dir` |

**Test File**: [`tests/integration/test_file_movement.py`](../../../tests/integration/test_file_movement.py) (7 methods)

#### Sequential Moves

| Flow | Test Scenario | Expected Outcome | Fixtures |
|------|---------------|-----------------|----------|
| 4 sequential moves | `test_sm_001_sequential_directory_moves` | References correct at each step (regression test for move 3+ bug) | `temp_project_dir`, `file_helper` |
| Rename after move | `test_sm_002_sequential_renames_after_moves` | Combined operations tracked correctly | `temp_project_dir`, `file_helper` |
| Debug database state | `test_sm_003_debug_database_state_during_moves` | State verified at each step (diagnostic) | `temp_project_dir`, `file_helper` |
| Multi-file independence | `test_multiple_files_sequential_moves` | One file's moves don't corrupt another file's references | `temp_project_dir`, `file_helper` |

**Test File**: [`tests/integration/test_sequential_moves.py`](../../../tests/integration/test_sequential_moves.py) (4 methods)

#### File Type Monitoring

| Category | Test Scenario | Expected Outcome | Fixtures |
|----------|---------------|-----------------|----------|
| Extension coverage | `test_all_common_extensions_are_monitored` | 28+ extensions covered | `LinkWatcherService` |
| Web files | `test_web_development_files_monitored` | html, css, js, ts, jsx, tsx, vue, php | `LinkWatcherService` |
| Image files | `test_image_files_monitored` | png, jpg, jpeg, gif, svg, webp, ico | `LinkWatcherService` |
| Document files | `test_document_and_data_files_monitored` | yaml, json, csv, xml, pdf, txt, md | `LinkWatcherService` |
| Media files | `test_media_files_monitored` | mp4, mp3, wav | `LinkWatcherService` |
| Multi-type detection | `test_comprehensive_link_detection_and_updates` | 9 file types detected in single scan | `LinkWatcherService` |
| Category coverage | `test_extension_coverage_by_category` | Minimum thresholds per category | `LinkWatcherService` |

**Test File**: [`tests/integration/test_comprehensive_file_monitoring.py`](../../../tests/integration/test_comprehensive_file_monitoring.py) (7 methods)

#### Image File Monitoring

| Category | Test Scenario | Expected Outcome | Fixtures |
|----------|---------------|-----------------|----------|
| Extension check | `test_png_svg_files_are_monitored` | .png and .svg in monitored set | `LinkParser` |
| Image ref scan | `test_image_references_found_in_initial_scan` | Inline, reference-style, definition images found | `LinkWatcherService` |
| Image move | `test_image_file_movement_updates_links` | PNG move updates relative paths, preserves titles | `LinkWatcherService` |
| PNG parsing | `test_png_file_parsing` | Binary PNG returns zero links (no false positives) | `LinkParser` |
| SVG parsing | `test_svg_file_parsing` | SVG with embedded `<a href>` returns references | `LinkParser` |
| Parser delegation | `test_parser_extension_support` | Image extensions not in specialized parser list | `LinkParser` |

**Test File**: [`tests/integration/test_image_file_monitoring.py`](../../../tests/integration/test_image_file_monitoring.py) (6 methods)

#### PowerShell Script Monitoring

| Category | Test Scenario | Expected Outcome | Fixtures |
|----------|---------------|-----------------|----------|
| Extension check | `test_ps1_extension_in_monitored_extensions` | .ps1, .sh, .bat all monitored | Manual setup |
| Should monitor | `test_should_monitor_ps1_files` | `_should_monitor_file` returns True for .ps1 | Manual setup |
| PS1 move | `test_powershell_script_move_updates_markdown_links` | All 4 markdown links to PS1 updated | Manual setup |
| Multi-script | `test_multiple_powershell_scripts_move` | Only moved script's links updated | Manual setup |
| Link formats | `test_powershell_script_with_different_link_formats` | Standard, titled, reference-style, inline code links handled | Manual setup |

**Test File**: [`tests/integration/test_powershell_script_monitoring.py`](../../../tests/integration/test_powershell_script_monitoring.py) (5 methods)

## Test Implementation Roadmap

### Priority Order

1. **High Priority** (Implemented ✅)
   - [x] Single file rename and cross-directory moves
   - [x] Directory rename with recursive updates
   - [x] Multi-format reference updates during moves
   - [x] Extension monitoring coverage

2. **Medium Priority** (Implemented ✅)
   - [x] Sequential move correctness (regression test)
   - [x] Image file monitoring and binary file safety
   - [x] PowerShell script monitoring
   - [x] Edge cases (non-existent files, overwrites)

3. **Low Priority** (Gaps identified)
   - [ ] Cross-tool move detection timing (delete+create with actual 2-second timer)
   - [ ] True delete processing (timer expires without matching create)
   - [ ] Event deduplication under rapid sequential moves
   - [ ] Thread safety of `pending_deletes` with `move_detection_lock`
   - [ ] File filtering for ignored directories (`.git/`, `__pycache__/`)
   - [ ] Statistics counter accuracy after operations
   - [ ] Per-file error handling (one failing file doesn't abort directory move)

### Coverage Gaps

- **Timer-based move detection**: The 2-second delete buffer and `_execute_delete` timer callback are not tested with real timers
- **Event deduplication**: 4-tuple key deduplication not explicitly tested
- **File filtering**: `should_monitor_file()` and `should_ignore_directory()` edge cases not directly tested
- **Statistics**: Session counters (files_moved, links_updated, errors) not verified
- **Error resilience**: Per-file try/except in directory moves not tested with intentional failures

## AI Agent Session Handoff Notes

### Implementation Context

**Feature Summary**: Watchdog-based file system monitoring with native and cross-tool move detection, directory walks, and multi-subsystem coordination.
**Test Focus**: Move detection correctness, multi-format link updates, extension coverage, sequential move robustness.
**Key Challenges**: Testing timer-based behavior deterministically; testing real watchdog events vs simulated events.

### Files to Reference

- **TDD**: [`doc/product-docs/technical/architecture/design-docs/tdd/tdd-1-1-1-file-system-monitoring-t2.md`](../../../doc/product-docs/technical/architecture/design-docs/tdd/tdd-1-1-1-file-system-monitoring-t2.md)
- **Existing Tests**: [`tests/test_move_detection.py`](../../../tests/test_move_detection.py), [`tests/integration/test_file_movement.py`](../../../tests/integration/test_file_movement.py), [`tests/integration/test_sequential_moves.py`](../../../tests/integration/test_sequential_moves.py), [`tests/integration/test_comprehensive_file_monitoring.py`](../../../tests/integration/test_comprehensive_file_monitoring.py), [`tests/integration/test_image_file_monitoring.py`](../../../tests/integration/test_image_file_monitoring.py), [`tests/integration/test_powershell_script_monitoring.py`](../../../tests/integration/test_powershell_script_monitoring.py)
- **Source Code**: [`linkwatcher/handler.py`](../../../linkwatcher/handler.py)
- **Fixtures**: [`tests/conftest.py`](../../../tests/conftest.py) — `temp_project_dir`, `file_helper`

---

_Retrospective Test Specification — documents existing test suite as of 2026-02-24._
