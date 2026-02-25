---
id: PF-STA-048
type: Document
category: State Tracking
version: 1.0
created: 2026-02-25
updated: 2026-02-25
task_name: test-file-audit-all-files
task_ref: PF-TSK-030
---

# Test File Audit State: All Test Files

> **Purpose**: Track audit progress for all 27 test files. For each file: what it tests, source code context, up-to-date status, gaps, and quality assessment.

## Audit Progress Summary

| Category | Files | Audited | Critical Issues | Warnings |
|----------|-------|---------|----------------|----------|
| Unit Tests | 7 | 7 | 2 | 8 |
| Integration Tests | 10 | 10 | 6 | 5 |
| Parser Tests | 7 | 7 | 4 | 3 |
| Performance Tests | 1 | 1 | 1 | 1 |
| Root-level Tests | 2 | 2 | 1 | 1 |
| **Total** | **27** | **27** | **14** | **18** |

## Test File Audit Tracker

### Unit Tests (tests/unit/)

| # | File | Up-to-date? | Gaps? | Quality |
|---|------|-------------|-------|---------|
| 1 | test_config.py | NO (wrong assertion L38) | YES - missing DEVELOPMENT/PRODUCTION configs, parser toggles, logging fields | Good |
| 2 | test_parser.py | Yes (facade only) | CRITICAL - 0 individual parser tests for 6 parsers (~800 lines) | Fair |
| 3 | test_service.py | Yes | YES - start()/stop() lifecycle completely untested | Good |
| 4 | test_logging.py | Yes | YES - 7 backward-compat functions, 4 convenience methods untested | Good |
| 5 | test_advanced_logging.py | Yes | YES - LoggingHandler, auto-reload, 6 CLI functions untested | Good |
| 6 | test_database.py | Yes (data quality issues) | YES - duplicate add, concurrent read+write untested | Good |
| 7 | test_updater.py | Yes | YES - _calculate_new_target_relative, Python import updates | Excellent |

### Integration Tests (tests/integration/)

| # | File | Up-to-date? | Gaps? | Quality |
|---|------|-------------|-------|---------|
| 8 | test_error_handling.py | NO - ALL API calls wrong | YES | Broken |
| 9 | test_service_integration.py | NO - MOST API calls wrong | YES | Broken |
| 10 | test_windows_platform.py | Partially | YES - weak assertions | Fair |
| 11 | test_file_movement.py | YES (correct API) | Minor gaps | Good |
| 12 | test_sequential_moves.py | NO - severely corrupted by LinkWatcher | YES | Broken |
| 13 | test_comprehensive_file_monitoring.py | Yes | YES - shallow (config-only checks) | Fair |
| 14 | test_image_file_monitoring.py | Partially | Minor gaps | Good |
| 15 | test_powershell_script_monitoring.py | YES | Minor gaps | Good |
| 16 | test_complex_scenarios.py | YES (correct API) | Minor gaps | Good |
| 17 | test_link_updates.py | MIXED - 7/10 methods broken | YES | Mixed |

### Parser Tests (tests/parsers/)

| # | File | Up-to-date? | Gaps? | Quality |
|---|------|-------------|-------|---------|
| 18 | test_dart.py | Partially | YES - part_pattern, embedded_pattern init, dedup | Good |
| 19 | test_generic.py | NO - wrong attribute name | YES - _is_likely_file_reference, Unicode failures | Broken |
| 20 | test_python.py | NO - wrong attribute names | YES - local imports, comment parsing | Broken |
| 21 | test_yaml.py | Yes | Minor - duplicate handling, column positions | Good |
| 22 | test_json.py | NO - wrong attribute (source_file) | YES - invalid JSON generation, path issues | Broken |
| 23 | test_markdown.py | Yes | YES - tests code-block awareness parser lacks | Good |
| 24 | test_image_files.py | Mostly | Minor gaps | Good |

### Performance Tests (tests/performance/)

| # | File | Up-to-date? | Gaps? | Quality |
|---|------|-------------|-------|---------|
| 25 | test_large_projects.py | NO - ALL on_moved() calls wrong | YES - psutil not guarded | Broken |

### Root-level Tests (tests/)

| # | File | Up-to-date? | Gaps? | Quality |
|---|------|-------------|-------|---------|
| 26 | test_config.py | N/A (utility module, not tests) | N/A | Good |
| 27 | test_move_detection.py | NO - not proper pytest, corrupted paths | YES - uses print, not assert | Poor |

## Session Tracking

### Session 1: 2026-02-25

**Focus**: Complete audit of all 27 test files
**Status**: COMPLETED
**Findings**: 14 critical issues, 18 warnings across the test suite
