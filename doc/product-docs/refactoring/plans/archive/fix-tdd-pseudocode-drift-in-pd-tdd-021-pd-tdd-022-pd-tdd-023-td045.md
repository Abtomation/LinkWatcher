---
id: PF-REF-057
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-04
updated: 2026-03-04
priority: Medium
refactoring_scope: Fix TDD pseudocode drift in PD-TDD-021, PD-TDD-022, PD-TDD-023 (TD045)
target_area: TDD Documentation
mode: lightweight
---

# Lightweight Refactoring Plan: Fix TDD pseudocode drift in PD-TDD-021, PD-TDD-022, PD-TDD-023 (TD045)

- **Target Area**: TDD Documentation
- **Priority**: Medium
- **Created**: 2026-03-04
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (≤15 min effort, single file, no architectural impact)

## Item 1: TD045a — PD-TDD-021 (Core Architecture) pseudocode drift

**Scope**: Fix pseudocode in PD-TDD-021 to match actual service.py, __init__.py, and main.py. Drift caused by TD004 (handler config rework, 2026-02-25), commit e88d560 (constructor/model refactoring, 2026-03-02), and TD033 (PathResolver extraction, 2026-03-03).

**Changes Made**:
- [x] §3.1 Component Diagram: Fix constructor params, move signal handlers from `start()` to `__init__()`
- [x] §3.2 Data Flow: `LinkWatcherService(config)` → `LinkWatcherService(project_root, config=config)`
- [x] §4.1 Pseudocode: Fix `__init__` signature, `self.database` → `self.link_db`, updater/handler constructors, signal registration location, `start()` signature, `_print_statistics()` → `_print_final_stats()`
- [x] §4.3 CLI: Fix arg names to match actual (`--project-root`, `--no-initial-scan`, `--quiet`, `--log-file`, `--version`)
- [x] §4.3 Package API: Add `PathResolver`, `LogTimer`, `with_context` to exports

**Test Baseline**: N/A (documentation only)
**Test Result**: N/A

**Documentation & State Updates**:
- [x] Feature implementation state file updated — N/A
- [x] TDD updated — **this IS the TDD update**
- [x] Test spec updated — N/A
- [x] FDD updated — N/A
- [x] Technical Debt Tracking: TD045 marked resolved

**Bugs Discovered**: None

## Item 2: TD045b — PD-TDD-022 (In-Memory Database) pseudocode drift

**Scope**: Fix PD-TDD-022 to document all 9 public methods and correct normalize_path architecture. Drift caused by TD001/TD002 (shared normalize_path, 2026-02-25) and TD006 (3 new public methods, 2026-03-02).

**Changes Made**:
- [x] §1.2: `1.1.2 Event Handler` → `1.1.1 File System Monitoring`
- [x] §3.4: Expand method list from 6 to 9 (add `remove_targets_by_path()`, `get_all_targets_with_references()`, `get_source_files()`)
- [x] §4.2: `self._normalize_path(...)` → `normalize_path(...)` throughout
- [x] §4.3: Replace private method definition with shared utility import note
- [x] §4.4: "6 public methods" → "9 public methods"; remove "immutable by convention"
- [x] §6.1: Fix feature references (`0.1.2 Data Models` → `Data Models (part of 0.1.1)`, `1.1.2` → `1.1.1`)

**Test Baseline**: N/A (documentation only)
**Test Result**: N/A

**Documentation & State Updates**:
- [x] Feature implementation state file updated — N/A
- [x] TDD updated — **this IS the TDD update**
- [x] Test spec updated — N/A
- [x] FDD updated — N/A
- [x] Technical Debt Tracking: TD045 marked resolved (shared)

**Bugs Discovered**: None

## Item 3: TD045c — PD-TDD-023 (File System Monitoring) pseudocode drift

**Scope**: Fix PD-TDD-023 to reflect 4-module architecture, correct constructor signature, FileOperation fields, timer value, and method names. Drift caused by TD004 (2026-02-25), commit e88d560 (2026-03-02), PF-REF-042 (2026-03-03), and TD035 (2026-03-03).

**Changes Made**:
- [x] §1.2: `0.1.3 In-Memory Database` → `0.1.2 In-Memory Database`
- [x] §2: "2-second timer buffer" → "10-second timer buffer"
- [x] §3.3: `_dir_move_lock` → `_lock`
- [x] §4.1 FileOperation: Fix all field names and types to match actual `operation_type, old_path, new_path, timestamp: datetime`
- [x] §4.1: "3-module" → "4-module"; constructor to `(link_db, parser, updater, project_root, monitored_extensions=None, ignored_directories=None)`; add ReferenceLookup; `self.logger = get_logger()`
- [x] §4.2-4.3: Fix method names (`_handle_dir_moved` → `_handle_directory_moved`, etc.)
- [x] §4.3: `should_monitor_file(new_path, self.config)` → `self._should_monitor_file(file_path)`
- [x] §6.2, §8, §9: Update module count to 4, LOC to ~475, fix key decisions text

**Test Baseline**: N/A (documentation only)
**Test Result**: N/A

**Documentation & State Updates**:
- [x] Feature implementation state file updated — N/A
- [x] TDD updated — **this IS the TDD update**
- [x] Test spec updated — N/A
- [x] FDD updated — N/A
- [x] Technical Debt Tracking: TD045 marked resolved (shared)

**Bugs Discovered**: None

## Root Cause Analysis

**Why drift happened**: Code Refactoring task (PF-TSK-022) lacked Step 12 (Update Product Documentation) until v1.3 (2026-03-03). All major code changes occurred between 2026-02-25 and 2026-03-03 during this gap:
- **TD004** (2026-02-25): Changed handler/service constructors
- **Commit e88d560** (2026-03-02): Changed FileOperation fields, attribute names
- **TD001/TD002** (2026-02-25): Moved normalize_path to shared utility
- **TD006** (2026-03-02): Added 3 new database public methods
- **TD033, PF-REF-042, TD035** (2026-03-03): Extracted PathResolver, ReferenceLookup, reduced handler LOC

**Process improvement already applied**: Step 12 now exists in PF-TSK-022 v1.3.

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD045a | Complete | None | PD-TDD-021 |
| 2 | TD045b | Complete | None | PD-TDD-022 |
| 3 | TD045c | Complete | None | PD-TDD-023 |

## Related Documentation
- [Technical Debt Tracking](/doc/process-framework/state-tracking/permanent/technical-debt-tracking.md)
- [PF-VAL-042 Documentation Alignment Validation](/doc/product-docs/validation/reports/documentation-alignment/PF-VAL-042-documentation-alignment-features-0.1.1-0.1.2-0.1.3-1.1.1.md)
