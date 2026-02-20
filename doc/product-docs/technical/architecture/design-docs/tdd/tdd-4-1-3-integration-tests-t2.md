---
id: PD-TDD-028
type: Product Documentation
category: Technical Design Document
version: 1.0
created: 2026-02-20
updated: 2026-02-20
feature_id: 4.1.3
feature_name: Integration Tests
tier: 2
retrospective: true
---

# Integration Tests - Technical Design Document (Tier 2)

> **Retrospective Document**: This TDD describes the existing implemented architecture of the LinkWatcher Integration Tests, documented after implementation during framework onboarding (PF-TSK-066).
>
> **Source**: Derived from [4.1.3 Implementation State](../../../../process-framework/state-tracking/features/4.1.3-integration-tests-implementation-state.md) and source code analysis.

## Technical Overview

Integration tests verify cross-component workflows using real file system operations. The `tests/integration/` directory contains 9+ test files organized by scenario type. Tests use the `link_service` composite fixture from conftest.py, which assembles a full `LinkWatcherService` with `dry_run=False` and `create_backups=True`.

## Component Architecture

### Test File Organization

| File | Scope | Key Scenarios |
|------|-------|---------------|
| `test_complex_scenarios.py` | Multi-step workflows | Rename chains, directory moves, cascading updates |
| `test_error_handling.py` | Error recovery | Permission errors, encoding issues, missing files |
| `test_file_movement.py` | Core move detection | Single file move, cross-directory move |
| `test_link_updates.py` | End-to-end updates | Parse → detect → update pipeline |
| `test_service_integration.py` | Full service | Service lifecycle, configuration, statistics |
| `test_windows_platform.py` | Platform-specific | Backslash paths, drive letters, case sensitivity |
| `test_sequential_moves.py` | Sequential operations | A→B→C move chains, concurrent moves |
| `test_comprehensive_file_monitoring.py` | File type coverage | All supported file types monitored |
| `test_image_file_monitoring.py` | Image files | PNG, JPG, SVG reference handling |
| `test_powershell_script_monitoring.py` | PowerShell | .ps1 file reference handling |

### Test Pattern: Simulate-and-Verify

All integration tests follow a consistent pattern:
1. Create project structure via `TestProjectBuilder` or `create_sample_project()`
2. Populate files with cross-references
3. Simulate file move via `simulate_file_move()` or `shutil.move()`
4. Execute link update via `link_service`
5. Verify file contents updated correctly

## Key Technical Decisions

### Scenario-Based Organization

Tests organized by workflow scenario rather than by component. A "file movement" test exercises handler + parser + database + updater together. This makes it easy to find tests for specific user stories.

### Real File System Operations

Integration tests use `dry_run_mode=False` with `create_backups=True`. The whole point is verifying real behavior — atomic writes, backup creation, encoding handling. Temp directories ensure cleanup.

### Platform-Specific Test Separation

Windows-specific tests in a dedicated file (`test_windows_platform.py`) can be skipped on non-Windows CI environments without polluting cross-platform tests.

## Dependencies

| Component | Usage |
|-----------|-------|
| `tests/conftest.py` | `link_service`, `temp_project_dir`, `sample_files` fixtures |
| `linkwatcher.service.LinkWatcherService` | Main integration target |
| `linkwatcher.database.LinkDatabase` | Database interactions |
| `linkwatcher.parser.LinkParser` | Cross-component parsing |
| `linkwatcher.updater.LinkUpdater` | Update operations |
| `linkwatcher.models.LinkReference` | Test data creation |
