---
id: PF-TSP-035
type: Process Framework
category: Test Specification
version: 1.0
created: 2026-02-19
updated: 2026-02-25
feature_id: 0.1.1
feature_name: Core Architecture
tdd_path: doc/product-docs/technical/architecture/design-docs/tdd/tdd-0-1-1-core-architecture-t3.md
test_tier: 3
retrospective: true
---

# Test Specification: Core Architecture

> **Retrospective Document**: This test specification describes the existing test suite for the LinkWatcher Core Architecture, documented after implementation during framework onboarding (PF-TSK-066). Content is derived from analysis of existing test files.

## Overview

This document provides comprehensive test specifications for the **Core Architecture** feature (ID: 0.1.1), derived from the Technical Design Document [PD-TDD-021](../../../doc/product-docs/technical/architecture/design-docs/tdd/tdd-0-1-1-core-architecture-t3.md).

**Test Tier**: 3 (Full Suite — unit, integration, and end-to-end)
**TDD Reference**: [TDD PD-TDD-021](../../../doc/product-docs/technical/architecture/design-docs/tdd/tdd-0-1-1-core-architecture-t3.md)
**Created**: 2026-02-19
**Implementation Coverage**: 38/46 scenarios implemented (83%)

## Feature Context

### TDD Summary

The Core Architecture defines the `LinkWatcherService` class as an Orchestrator/Facade that coordinates all LinkWatcher subsystems (database, parser, updater, handler, observer) without implementing business logic itself. The service manages lifecycle (start/stop), signal handling (SIGINT/SIGTERM), initial directory scanning, and continuous file monitoring via a watchdog Observer on a daemon thread.

> **Consolidated Scope (v2.0)**: Core Architecture now includes Data Models (`models.py` — `LinkReference`, `FileOperation` dataclasses) and Path Utilities (`utils.py` — `should_monitor_file()`, `should_ignore_directory()`, path normalization). These were previously tracked as separate features 0.1.2 and 0.1.5.

### Test Complexity Assessment

**Selected Tier**: 3 — Core Architecture is the top-level orchestrator that integrates all subsystems. Full test suite is justified because:
- Service lifecycle involves threading (Observer daemon thread)
- Signal handling requires integration testing
- Initial scan touches parser, database, and file system
- Multiple integration test files exercise the full service pipeline

## Cross-References

### Functional Requirements Reference

> **📋 Primary Documentation**: [FDD PD-FDD-022](../../../doc/product-docs/functional-design/fdds/fdd-0-1-1-core-architecture.md)

#### Testing-Level Functional Context

Tests validate the core service lifecycle: initialization with subsystem wiring, initial scan populating the link database, continuous monitoring via Observer, graceful shutdown, and the public Python API surface.

**Acceptance Criteria to Test**:

- Service instantiation creates all subsystems (database, parser, updater, handler)
- Initial scan discovers and indexes all links in monitored files
- Service status reporting returns correct running state and statistics
- Force rescan clears and repopulates the database
- Dry-run mode toggles correctly on the updater

**Business Rules to Validate**:

- Default path is current directory when no path argument provided
- Broken link detection correctly identifies missing target files
- Custom parsers can be added at runtime for new file extensions

### API Specification Reference

> No external API — this is an internal service component. The public API is the Python package documented in `__init__.py`.

### Database Schema Reference

> No database schema — link storage uses an in-memory `Dict[str, List[LinkReference]]`. No persistence testing required.

### Technical Design Reference

> **📋 Primary Documentation**: [TDD PD-TDD-021](../../../doc/product-docs/technical/architecture/design-docs/tdd/tdd-0-1-1-core-architecture-t3.md)

#### Testing-Level Implementation Context

Tests cover the Orchestrator/Facade pattern: service construction wires all subsystems, lifecycle methods (start/stop) manage the Observer thread, and the service acts as a pass-through coordinator. Mock strategy focuses on isolating subsystems for unit tests while integration tests exercise the full pipeline.

**Component Testing Strategy**:

- `LinkWatcherService.__init__()` — verify all subsystems instantiated
- `LinkWatcherService._initial_scan()` — verify database populated
- `LinkWatcherService.start()/stop()` — verify Observer lifecycle
- `LinkWatcherService.get_status()` — verify status reporting
- `LinkWatcherService.force_rescan()` — verify database rebuild
- `LinkWatcherService.check_links()` — verify broken link detection

**Mock Requirements**:

- `temp_project_dir` fixture provides isolated file system
- `sample_files` fixture provides pre-created test files with links
- `file_helper` fixture provides utilities for creating test content

## Test Categories

### Unit Tests

#### Services

| Service | Test Focus | Key Test Cases | Mock Dependencies |
|---------|-----------|----------------|-------------------|
| LinkWatcherService | Initialization | `test_service_initialization` — all components created, correct state | `temp_project_dir` fixture |
| LinkWatcherService | Default path | `test_service_initialization_default_path` — uses CWD when no path | None |
| LinkWatcherService | Initial scan | `test_initial_scan` — database populated with links from files | `temp_project_dir`, `sample_files` |
| LinkWatcherService | Status reporting | `test_get_status` — returns running, project_root, stats | `temp_project_dir` |
| LinkWatcherService | Force rescan | `test_force_rescan` — clears and repopulates database | `temp_project_dir`, `sample_files` |
| LinkWatcherService | Dry-run toggle | `test_set_dry_run` — toggles updater.dry_run flag | `temp_project_dir` |
| LinkWatcherService | Custom parsers | `test_add_custom_parser` — adds to parser registry and handler extensions | `temp_project_dir` |
| LinkWatcherService | Link checking (clean) | `test_check_links_no_broken_links` — zero broken when all targets exist | `temp_project_dir`, `sample_files` |
| LinkWatcherService | Link checking (broken) | `test_check_links_with_broken_links` — detects missing targets | `temp_project_dir`, `file_helper` |
| LinkWatcherService | Component integration | `test_service_components_integration` — all subsystems work together | `temp_project_dir`, `sample_files` |

**Test File**: [`test/automated/unit/test_service.py`](../../../test/automated/unit/test_service.py)
**Status**: Implemented (10 test methods)

#### Duplicate Instance Prevention (Lock File)

| Component | Test Focus | Key Test Cases | Mock Dependencies |
|-----------|-----------|----------------|-------------------|
| Lock file acquisition | Lock created on startup | `test_lock_file_created_on_startup` — `.linkwatcher.lock` created with current PID | `temp_project_dir` |
| Lock file release | Lock removed on shutdown | `test_lock_file_removed_on_shutdown` — lock file deleted after clean stop | `temp_project_dir` |
| Stale lock detection | Override stale lock | `test_stale_lock_file_overridden` — lock with dead PID is overridden | `temp_project_dir` |
| Duplicate prevention | Reject second instance | `test_duplicate_instance_prevented` — exits with error when live PID lock exists | `temp_project_dir` |
| Lock file content | Valid PID stored | `test_lock_file_contains_valid_pid` — file content matches `os.getpid()` | `temp_project_dir` |
| Corrupt lock file | Handle invalid content | `test_corrupt_lock_file_handled` — non-numeric content treated as stale | `temp_project_dir` |

**Test File**: `test/automated/unit/test_lock_file.py` (new)
**Status**: Pending implementation

### Integration Tests

#### Data Flow Testing — File Movement

| Flow | Components Involved | Test Scenario | Expected Outcome |
|------|-------------------|---------------|-----------------|
| Single rename | Service → Handler → Updater → Database | `test_fm_001_single_file_rename` | Links updated to new filename |
| Cross-directory move | Service → Handler → Updater → Database | `test_fm_002_file_move_different_directory` | Relative paths recalculated |
| Move + rename | Service → Handler → Updater → Database | `test_fm_003_file_move_with_rename` | Both path and name updated |
| Directory rename | Service → Handler → Updater → Database | `test_fm_004_directory_rename` | All files in directory updated |
| Nested directory | Service → Handler → Updater → Database | `test_fm_005_nested_directory_movement` | Deep path chains updated |

**Test File**: [`test/automated/integration/test_file_movement.py`](../../../test/automated/integration/test_file_movement.py) (7 methods including edge cases)

#### Data Flow Testing — Link Updates

| Flow | Components Involved | Test Scenario | Expected Outcome |
|------|-------------------|---------------|-----------------|
| Markdown links | Parser → Database → Updater | `test_lr_001_markdown_standard_links` | Standard MD links updated |
| Relative links | Parser → Database → Updater | `test_lr_002_markdown_relative_links` | Relative paths recalculated |
| Anchored links | Parser → Database → Updater | `test_lr_003_markdown_with_anchors` | Anchors preserved during update |
| YAML refs | Parser → Database → Updater | `test_lr_004_yaml_file_references` | YAML values updated |
| JSON refs | Parser → Database → Updater | `test_lr_005_json_file_references` | JSON values updated |
| Python imports | Parser → Database → Updater | `test_lr_006_python_imports` | Import paths updated |
| Dart imports | Parser → Database → Updater | `test_lr_007_dart_imports` | Dart import paths updated |

**Test File**: [`test/automated/integration/test_link_updates.py`](../../../test/automated/integration/test_link_updates.py) (7 methods)

#### Data Flow Testing — Sequential Operations

| Flow | Test Scenario | Expected Outcome |
|------|---------------|-----------------|
| Sequential dir moves | `test_sm_001_sequential_directory_moves` | Database state consistent after multiple moves |
| Renames after moves | `test_sm_002_sequential_renames_after_moves` | Combined operations tracked correctly |
| Database state debug | `test_sm_003_debug_database_state_during_moves` | State verified at each step |
| Multi-file moves | `test_multiple_files_sequential_moves` | All files tracked independently |

**Test File**: [`test/automated/integration/test_sequential_moves.py`](../../../test/automated/integration/test_sequential_moves.py) (4 methods)

#### Platform Testing — Windows

| Category | Test Scenario | Expected Outcome |
|----------|---------------|-----------------|
| Path separators | `test_cp_001_mixed_path_separators` | Forward/backslash handled |
| Path normalization | `test_cp_001_path_normalization_in_updates` | Consistent normalization |
| Relative resolution | `test_cp_001_relative_path_resolution` | Correct relative paths |
| Case sensitivity | `test_cp_002_case_sensitive_file_matching` | Case-insensitive match on Windows |
| Invalid chars | `test_cp_003_invalid_characters_handling` | Graceful handling |
| Reserved names | `test_cp_003_reserved_names_handling` | Windows reserved names handled |
| Long paths | `test_cp_004_long_path_support` | >260 char paths work |
| Unicode paths | `test_cp_005_unicode_characters_in_paths` | International characters supported |
| Spaces in paths | `test_cp_005_spaces_and_special_chars` | Spaces handled correctly |
| Junctions | `test_cp_006_junction_handling_windows` | Windows symlinks handled |
| Drive letters | `test_cp_007_drive_letter_paths` | C:\ style paths work |
| UNC paths | `test_cp_007_unc_path_handling` | \\server\share paths handled |
| Hidden files | `test_cp_008_hidden_file_handling` | Windows hidden attribute respected |
| Hidden dirs | `test_cp_008_hidden_directory_handling` | Hidden directories handled |

**Test File**: [`test/automated/integration/test_windows_platform.py`](../../../test/automated/integration/test_windows_platform.py) (14 methods)

### End-to-End Tests (Tier 3)

#### User Journeys

| User Journey | Steps | Success Criteria | Failure Scenarios |
|-------------|-------|-----------------|-------------------|
| Full service pipeline | 1. Create project with linked files → 2. Start service → 3. Move file → 4. Verify links updated → 5. Stop service | All links updated, clean shutdown | File locked, observer crash |
| Image file monitoring | 1. Create project with image refs → 2. Scan → 3. Move image → 4. Verify refs updated | PNG/SVG references updated | Binary file confusion |

**Test Files**:
- [`test/automated/integration/test_comprehensive_file_monitoring.py`](../../../test/automated/integration/test_comprehensive_file_monitoring.py) — Full monitoring pipeline
- [`test/automated/integration/test_image_file_monitoring.py`](../../../test/automated/integration/test_image_file_monitoring.py) (6 methods) — Image file handling

## Mock Requirements

### External Dependencies

| Dependency | Mock Type | Expected Behavior | Mock Data |
|-----------|----------|-------------------|-----------|
| File system | Fixture (`temp_project_dir`) | Isolated temporary directory | pytest `tmp_path` |
| Sample files | Fixture (`sample_files`) | Pre-created .md, .yaml, .json files with links | Created by fixture |
| File helper | Fixture (`file_helper`) | Utility for creating test files | `test/automated/conftest.py` |

### Internal Services

| Service | Mock Strategy | Key Methods | Return Values |
|---------|-------------|-------------|---------------|
| LinkDatabase | Real (in-memory) | `add_link()`, `get_stats()`, `get_links_for_target()` | Actual in-memory data |
| LinkParser | Real | `parse()` | Actual parsed links |
| LinkUpdater | Real | `update_links()` | Actual file modifications |
| Observer | Not mocked in unit tests (lazy creation) | N/A — created only in `start()` | N/A |

> **Note**: Unit tests avoid mocking subsystems because the service is a thin coordinator — testing with real subsystems is more valuable than testing mock interactions.

## Test Implementation Roadmap

### Priority Order

1. **High Priority** (Implemented ✅)

   - [x] Service initialization and component wiring
   - [x] Initial scan and database population
   - [x] File movement and link update pipeline (integration)
   - [x] Windows platform compatibility

2. **Medium Priority** (Implemented ✅)

   - [x] Broken link detection
   - [x] Force rescan functionality
   - [x] Sequential move handling
   - [x] Multi-format link updates (MD, YAML, JSON, Python, Dart)

3. **Low Priority** (Gaps identified)

   - [ ] Signal handler testing (SIGINT/SIGTERM) — requires process-level testing
   - [ ] Observer thread lifecycle testing — start/join/daemon behavior
   - [ ] Concurrent file event handling under load
   - [ ] Configuration source priority testing (CLI > env > file > defaults)

### Test File Structure

```
test/automated/
├── unit/
│   └── test_service.py                          # 10 methods — service lifecycle
├── integration/
│   ├── test_file_movement.py                     # 7 methods — file move/rename
│   ├── test_link_updates.py                      # 7 methods — multi-format updates
│   ├── test_sequential_moves.py                  # 4 methods — sequential operations
│   ├── test_windows_platform.py                  # 14 methods — Windows compatibility
│   ├── test_comprehensive_file_monitoring.py     # Full monitoring pipeline
│   ├── test_image_file_monitoring.py             # 6 methods — image file handling
│   ├── test_complex_scenarios.py                 # Complex scenario testing
│   └── test_service_integration.py               # Service integration tests
├── conftest.py                                   # Shared fixtures
└── utils.py                                      # Test utilities
```

### Coverage Gaps

- **~~Duplicate instance prevention~~**: Lock file lifecycle tests — **Added** (see Unit Tests > Duplicate Instance Prevention)
- **Signal handling**: No tests for SIGINT/SIGTERM → `_signal_handler()` behavior
- **Observer thread lifecycle**: `start()`/`stop()` with actual Observer not tested in unit tests (would require thread management in tests)
- **CLI entry point**: `main.py` argument parsing not directly tested
- **Configuration loading**: Multi-source config priority not tested
- **`final.py`**: Startup helper has no tests
- **Data Models** (`models.py`): `LinkReference` and `FileOperation` dataclass construction/equality — now in scope (consolidated from old 0.1.2)
- **Path Utilities** (`utils.py`): `should_monitor_file()`, `should_ignore_directory()`, path normalization edge cases — now in scope (consolidated from old 0.1.5)
- **Loose assertions** (found during test audit PF-TAR-011, 2026-03-15): Several integration tests use `>= N` rather than exact counts, which could hide partial failures. Low priority but worth tightening.
- **Permissive error recovery validation**: Some error handling tests (EH-001 through EH-008) verify service doesn't crash but don't validate actual recovery occurred (e.g., `assert service.link_db is not None` without checking DB state)

## AI Agent Session Handoff Notes

### Implementation Context

**Feature Summary**: Core Architecture is the top-level orchestrator (`LinkWatcherService`) that coordinates database, parser, updater, handler, and observer subsystems.
**Test Focus**: Service lifecycle, subsystem wiring, initial scan, file movement pipeline
**Key Challenges**: Testing signal handling and Observer thread lifecycle without flaky tests

### Test Implementation Guidelines

1. **Start with**: Unit tests in `test_service.py` — they test the service API surface
2. **Mock Strategy**: Use real subsystems (not mocks) since the service is a thin coordinator
3. **Test Data**: Use `temp_project_dir` and `sample_files` fixtures from `conftest.py`
4. **Validation Points**: Database population after scan, link update correctness after file moves

### Files to Reference

- **TDD**: [`doc/product-docs/technical/architecture/design-docs/tdd/tdd-0-1-1-core-architecture-t3.md`](../../../doc/product-docs/technical/architecture/design-docs/tdd/tdd-0-1-1-core-architecture-t3.md)
- **Existing Tests**: [`test/automated/unit/test_service.py`](../../../test/automated/unit/test_service.py), `test/automated/integration/test_*.py`
- **Fixtures**: [`test/automated/conftest.py`](../../../test/automated/conftest.py) — shared test setup
- **Test Utilities**: [`test/automated/utils.py`](../../../test/automated/utils.py) — helper functions

### Success Criteria

- [x] All high-priority tests implemented and passing
- [x] Mock requirements satisfied (using fixture-based approach)
- [x] Integration test coverage across all file formats
- [x] Windows platform compatibility tests passing
- [ ] Signal handling and thread lifecycle tests (identified gap)

## Related Resources

- **Source TDD**: [PD-TDD-021](../../../doc/product-docs/technical/architecture/design-docs/tdd/tdd-0-1-1-core-architecture-t3.md)
- **FDD**: [PD-FDD-022](../../../doc/product-docs/functional-design/fdds/fdd-0-1-1-core-architecture.md)
- **ADR**: [PD-ADR-039](../../../doc/product-docs/technical/architecture/design-docs/adr/adr/orchestrator-facade-pattern-for-core-architecture.md)
- **Feature Tier Assessment**: [ART-ASS-191](../../../doc/product-docs/documentation-tiers/assessments/ART-ASS-191-0-1-1-core-architecture.md)
- **Implementation State**: [PF-FEA-003](../../../doc/product-docs/state-tracking/features/0.1.1-core-architecture-implementation-state.md)

---

_Retrospective Test Specification — documents existing test suite as of 2026-02-19._
