---
id: TE-STA-001
type: Process Framework
category: State File
version: 4.0
created: 2025-07-13
updated: 2026-06-11
tracking_scope: Test Tracking (Automated + Manual)
state_type: Implementation Status
---
# Test Tracking

This file tracks the implementation status of all **automated** tests derived from test specifications in the LinkWatcher project. Each entry represents a test file and its associated status, organized by feature categories.

> **E2E acceptance tests** are tracked separately in [E2E Acceptance Test Tracking](e2e-test-tracking.md).

## Status Legend

### Automated Test Statuses

| Status | Description | Next Task |
|--------|-------------|-----------|
| 📝 **Needs Implementation** | Test specification exists, tests not yet implemented | PF-TSK-053 |
| 🟡 **Implementation In Progress** | Test implementation has started but is not complete | — |
| 🔄 **Needs Audit** | Tests are implemented and ready for audit validation | PF-TSK-030 |
| ✅ **Audit Approved** | All tests passed audit and are production-ready | — |
| 🔴 **Needs Fix** | Tests are implemented but some are currently failing | — |
| ⛔ **Implementation Blocked** | Test implementation is blocked by dependencies or issues | — |
| 🔄 **Needs Update** | Test specification or implementation needs updates due to code changes or audit findings | — |
| 🗑️ **Removed** | Test file has been removed due to being outdated or no longer needed | — |

## Coverage Summary

| Date | Total Coverage | Tests Passed | Tests Skipped | Tests Failed | Run Type |
|------|---------------|--------------|---------------|--------------|----------|
| 2026-04-03 | 89% | 650 | 5 | 0 | All (excl. slow) |
| 2026-03-27 | — | 303 | 0 | 0 | Category: unit |
| 2026-03-22 | 86% | 477 | 5 | 0 | All (excl. slow) |

## Testing Infrastructure

> Shared test fixtures, utilities, and performance benchmarks. These are project-specific implementations of the patterns described in the [Test Infrastructure Guide](/process-framework/guides/03-testing/test-infrastructure-guide.md).

| Feature ID | Test Type | Test File/Case | Status | Test Cases Count | Last Executed | Last Updated | Notes |
|------------|-----------|----------------|--------|------------------|---------------|--------------|-------|
| — | Automated | [conftest.py](../../automated/conftest.py) | ✅ Audit Approved | 8 | — | 2026-03-22 | Root test fixtures (9 shared fixtures) |
| — | Automated | [utils.py](../../automated/utils.py) | ✅ Audit Approved | 5 | — | 2026-03-22 | Test utility functions and builders |
| — | — | — | — | — | — | — | Performance tests migrated to [performance-test-tracking.md](performance-test-tracking.md) |

# Test Status by Feature Category

## 0. System Architecture & Foundation

| Feature ID | Test Type | Test File/Case | Status | Test Cases Count | Last Executed | Last Updated | Notes |
|------------|-----------|----------------|--------|------------------|---------------|--------------|-------|
| 0.1.1 | Automated | [test_service.py](../../automated/unit/0-system-architecture-foundation/0-0-system-architecture-foundation/test_service.py) | ✅ Audit Approved | 36 | Run 2026-06-12: 36 passed | 2026-06-12 | Core service orchestration unit tests (6 classes incl. PD-BUG-053 event deferral, PD-BUG-070 regressions); Audit: [TE-TAR-013 v2.0](../../audits/unit/0-system-architecture-foundation/0-0-system-architecture-foundation/audit-report-0-1-1-test-service.md); 2026-06-12: +1 PD-BUG-107 initial-scan exclusion test (TestOwnOutputScanExclusion); count also reconciled for 5 tests added earlier without count bump (30→36) |
| 0.1.1 | Automated | [test_service_integration.py](../../automated/unit/0-system-architecture-foundation/0-0-system-architecture-foundation/test_service_integration.py) | ✅ Audit Approved | 17 | Run 2026-03-22: 17 passed | 2026-03-22 | Service integration with subsystems; Audit: [TE-TAR-014](../../audits/unit/0-system-architecture-foundation/0-0-system-architecture-foundation/audit-report-0-1-1-test-service-integration.md) |
| 0.1.1 | Automated | [test_complex_scenarios.py](../../automated/unit/0-system-architecture-foundation/0-0-system-architecture-foundation/test_complex_scenarios.py) | ✅ Audit Approved | 11 | Run 2026-03-22: 11 passed | 2026-03-22 | Complex multi-component scenarios; Audit: [TE-TAR-015](../../audits/unit/0-system-architecture-foundation/0-0-system-architecture-foundation/audit-report-0-1-1-test-complex-scenarios.md) |
| 0.1.1 | Automated | [test_error_handling.py](../../automated/unit/0-system-architecture-foundation/0-0-system-architecture-foundation/test_error_handling.py) | ✅ Audit Approved | 19 | Run 2026-03-22: 18 passed, 1 skipped | 2026-03-22 | Error handling and graceful degradation; Audit: [TE-TAR-016](../../audits/unit/0-system-architecture-foundation/0-0-system-architecture-foundation/audit-report-0-1-1-test-error-handling.md) |
| 0.1.2 | Automated | [test_database.py](../../automated/unit/0-system-architecture-foundation/0-0-system-architecture-foundation/test_database.py) | ✅ Audit Approved | 57 | Run 2026-04-03: 57 passed | 2026-04-03 | In-memory database thread-safe operations; Audit: [TE-TAR-019](../../audits/unit/0-system-architecture-foundation/0-0-system-architecture-foundation/audit-report-0-1-2-test-database.md); TD163 resolved: +14 tests for update_source_path, remove_targets_by_path, get_all_targets_with_references, get_source_files; Coverage 81%→93%; Audit Status: Tests Implemented; Audit Results: Passed: 57, Failed: 0; Test Cases Audited: 43; Audit Date: 2026-04-03; Audit Report: test/audits/unit/0-system-architecture-foundation/0-0-system-architecture-foundation/audit-report-0-1-2-test-database.md; Auditor: AI Agent |
| 0.1.3 | Automated | [test_config.py](../../automated/test_config.py) | ✅ Audit Approved | 0 | — | 2026-04-03 | Configuration/utility module (not a test file); provides TEST_ENVIRONMENTS, SAMPLE_CONTENTS, helper functions for other tests |
| 0.1.3 | Automated | [test_config.py](../../automated/unit/0-system-architecture-foundation/0-0-system-architecture-foundation/test_config.py) | ✅ Audit Approved | 56 | Run 2026-06-12: 56 passed | 2026-06-12 | Configuration system unit tests; Audit: [TE-TAR-020](../../audits/unit/0-system-architecture-foundation/0-0-system-architecture-foundation/audit-report-0-1-3-test-config.md); Audit Status: Audit Approved; Audit Results: Passed: 55, Failed: 0; Post-audit: +2 tests (invalid int/float env var), singleton mutation fix, coverage 94%→97%; Test Cases Audited: 53; Auditor: AI Agent; Audit Date: 2026-04-03; PD-BUG-103: +1 root-cause guard (DEFAULT_CONFIG == dataclass defaults field-for-field), written test-first (failed pre-unification); count corrected 57→56 to match actual collection (pre-existing +2 drift) |
| 0.1.1 | Automated | [test_windows_platform.py](../../automated/unit/0-system-architecture-foundation/0-0-system-architecture-foundation/test_windows_platform.py) | ✅ Audit Approved | 16 | Run 2026-03-22: 14 passed, 2 skipped | 2026-03-22 | Windows path handling integration tests; Audit: [TE-TAR-017](../../audits/unit/0-system-architecture-foundation/0-0-system-architecture-foundation/audit-report-0-1-1-test-windows-platform.md) |
| 0.1.1 | Automated | [test_lock_file.py](../../automated/unit/0-system-architecture-foundation/0-0-system-architecture-foundation/test_lock_file.py) | ✅ Audit Approved | 14 | Run 2026-06-08: 14 passed | 2026-06-08 | Duplicate instance prevention lock file mechanism (PD-BUG-099: +1 atomic-lock TOCTOU race regression test; TD255: +2 settle-read window regression tests; PD-BUG-100: +1 release_lock ownership regression test); Audit: [TE-TAR-018](../../audits/unit/0-system-architecture-foundation/0-0-system-architecture-foundation/audit-report-0-1-1-test-lock-file.md) |
| 0.1.1 | Automated | [test_pd_bug_100_launcher_lock_cleanup.py](../../automated/unit/test_pd_bug_100_launcher_lock_cleanup.py) | 🔄 Needs Audit | 5 | Run 2026-06-08: 5 passed | 2026-06-08 | PD-BUG-100 regression: launcher Get-DaemonExitDisposition must preserve a live foreign owner's lock (5 cases: foreign-live, own-crashed, foreign-dead, empty, no-lock) |
| 0.1.3 | Automated | [test_configschemadrift.py](../../automated/unit/0-system-architecture-foundation/0-0-system-architecture-foundation/test_configschemadrift.py) | ✅ Audit Approved | 7 | Run 2026-06-12: 7 passed | 2026-06-12 | Config schema drift guard (TE-TST-136, enhancement PF-STA-108): LinkWatcherConfig fields vs. configuration-guide Full Reference (keys + scalar defaults) and WIP template (keys ⊆ fields); spec scenario added to TE-TSP-037; Audit: [TE-TAR-075](../../audits/unit/0-system-architecture-foundation/0-0-system-architecture-foundation/audit-report-0-1-3-test-configschemadrift.md); Audit Results: Passed: 5, Failed: 0; Test Cases Audited: 5; Audit Status: Audit Approved; Audit Date: 2026-06-10; Auditor: AI Agent; Major Findings: Coverage PARTIAL: set/dict defaults compared by key presence only; masks live ignored_directories doc drift (TD261); 5 of 6 criteria PASS; non-vacuous drift guard with self-check; Audit Report: test/audits/unit/0-system-architecture-foundation/0-0-system-architecture-foundation/audit-report-0-1-3-test-configschemadrift.md; PD-BUG-103: +2 value-compare guards (guide ignored_directories + monitored_extensions vs code default), ignored_directories one written test-first (failed pre-fix) |
| 0.1.1 | Automated | [test_pd_bug_104_handbook_deployment.py](../../automated/unit/test_pd_bug_104_handbook_deployment.py) | 🔄 Needs Audit | 4 | Run 2026-06-10: 4 passed | 2026-06-10 | PD-BUG-104 regression (TE-TST-137): install_global CORE_DIRS must deploy doc/user/handbooks/ structure-preserving (3 manifest guards incl. anti-flattening negative + 1 tmp-dir install_linkwatcher copy test) |
| 0.1.1 | Automated | [test_pd_bug_106_installer_venv_daemon_stop.py](../../automated/unit/test_pd_bug_106_installer_venv_daemon_stop.py) | 🔄 Needs Audit | 17 | Run 2026-06-11: 17 passed | 2026-06-11 | PD-BUG-106 regression (TE-TST-139): installer must stop ALL daemons running from the install-dir venv (enumeration by executable path, taskkill /T tree-kill) and gate on venv python.exe writability BEFORE copying files; written test-first (17 failed pre-fix, 17 pass post-fix); incl. main()-wiring order + no-partial-state negative assertions |

## 1. File Watching & Detection

| Feature ID | Test Type | Test File/Case | Status | Test Cases Count | Last Executed | Last Updated | Notes |
|------------|-----------|----------------|--------|------------------|---------------|--------------|-------|
| 1.1.1 | Automated | [test_move_detection.py](../../automated/unit/1-file-watching-detection/1-0-file-watching-detection/test_move_detection.py) | ✅ Audit Approved | 46 | Run 2026-06-12: 46 passed | 2026-06-12 | File move detection integration; Audit: [TE-TAR-025](../../audits/unit/1-file-watching-detection/1-0-file-watching-detection/audit-report-1-1-1-test-move-detection.md); Audit Results: Passed: 20, Failed: 0; Auditor: AI Agent; Audit Date: 2026-04-03; Audit Status: Audit Approved; Major Findings: 1 zero-assertion smoke test (test_true_delete_timer_reports_broken_refs_when_file_gone); Audit Report: test/audits/unit/1-file-watching-detection/1-0-file-watching-detection/audit-report-1-1-1-test-move-detection.md; Test Cases Audited: 20; 2026-06-11: +5 PD-BUG-102 regression tests (TestModifyEventRescan — on_modified rescan); count also reconciled for 5 PD-BUG-105 tests added earlier without count bump (20→30); 2026-06-12: +8 PD-BUG-107 tests (TestOwnOutputExclusion — 5 event-guard regressions; TestOwnOutputPredicate — 3 registry unit tests) (30→38); 2026-06-12: +4 PD-BUG-108 tests (TestIgnoredDirectoryEventBoundary — native move out of ignored tree indexes dest, create-like semantics) (38→42); 2026-06-12: +3 PD-BUG-109 regression tests (TestOwnOutputPredicate — outside-root log dir must not be excluded: ancestor, sibling, root-prefix-lookalike) (42→45); 2026-06-12: +1 PD-BUG-109 review-amendment test (drive-root project keeps inside log dir excluded — code-review finding) (45→46) |
| 1.1.1 | Automated | [test_file_movement.py](../../automated/unit/1-file-watching-detection/1-0-file-watching-detection/test_file_movement.py) | ✅ Audit Approved | 7 | Run 2026-03-22: 7 passed | 2026-04-03 | File movement handling integration; Audit: [TE-TAR-026](../../audits/unit/1-file-watching-detection/1-0-file-watching-detection/audit-report-1-1-1-test-file-movement.md); Audit Date: 2026-04-03; Audit Results: Passed: 7, Failed: 0; Auditor: AI Agent; Test Cases Audited: 7; Audit Status: Audit Approved; Audit Report: test/audits/unit/1-file-watching-detection/1-0-file-watching-detection/audit-report-1-1-1-test-file-movement.md |
| 1.1.1 | Automated | [test_sequential_moves.py](../../automated/unit/1-file-watching-detection/1-0-file-watching-detection/test_sequential_moves.py) | ✅ Audit Approved | 4 | Run 2026-03-22: 4 passed | 2026-04-03 | Sequential file move scenarios; Audit: [TE-TAR-027](../../audits/unit/1-file-watching-detection/1-0-file-watching-detection/audit-report-1-1-1-test-sequential-moves.md); Audit Date: 2026-04-03; Test Cases Audited: 4; Audit Results: Passed: 4, Failed: 0; Audit Status: Audit Approved; Auditor: AI Agent; Audit Report: test/audits/unit/1-file-watching-detection/1-0-file-watching-detection/audit-report-1-1-1-test-sequential-moves.md; Major Findings: SM-003 zero assertions (diagnostic only, 15+ prints); Excessive print() debug output across all methods |
| 1.1.1 | Automated | [test_comprehensive_file_monitoring.py](../../automated/unit/1-file-watching-detection/1-0-file-watching-detection/test_comprehensive_file_monitoring.py) | ✅ Audit Approved | 7 | Run 2026-03-22: 7 passed | 2026-04-03 | Comprehensive file type monitoring; Audit: [TE-TAR-028](../../audits/unit/1-file-watching-detection/1-0-file-watching-detection/audit-report-1-1-1-test-comprehensive-file-monitoring.md); Audit Status: Audit Approved; Audit Results: Passed: 7, Failed: 0; Test Cases Audited: 7; Major Findings: Config-only tests, no behavioral move tests; Uses raw tempfile instead of pytest tmp_path; Audit Report: test/audits/unit/1-file-watching-detection/1-0-file-watching-detection/audit-report-1-1-1-test-comprehensive-file-monitoring.md; Audit Date: 2026-04-03; Auditor: AI Agent |
| 1.1.1 | Automated | [test_image_file_monitoring.py](../../automated/unit/1-file-watching-detection/1-0-file-watching-detection/test_image_file_monitoring.py) | ✅ Audit Approved | 6 | Run 2026-03-22: 6 passed | 2026-03-22 | Image file monitoring; Audit: [TE-TAR-029](../../audits/unit/1-file-watching-detection/1-0-file-watching-detection/audit-report-1-1-1-test-image-file-monitoring.md) |
| 1.1.1 | Automated | [test_powershell_script_monitoring.py](../../automated/unit/1-file-watching-detection/1-0-file-watching-detection/test_powershell_script_monitoring.py) | ✅ Audit Approved | 5 | Run 2026-03-22: 5 passed | 2026-03-22 | PowerShell script monitoring; Audit: [TE-TAR-030](../../audits/unit/1-file-watching-detection/1-0-file-watching-detection/audit-report-1-1-1-test-powershell-script-monitoring.md) |
| 1.1.1 | Automated | [test_reference_lookup.py](../../automated/unit/1-file-watching-detection/1-0-file-watching-detection/test_reference_lookup.py) | ✅ Audit Approved | 39 | Run 2026-03-27: 39 passed | 2026-03-27 | ReferenceLookup unit tests (TD066). 92% coverage. Path variations, reference finding, stale retry, DB cleanup, file rescanning, directory moves, link updates in moved files, path recalculation. |
| 1.1.1 | Automated | [test_e2eworkspaceexclusion.py](../../automated/unit/test_e2eworkspaceexclusion.py) | 🔄 Needs Audit | 4 | Run 2026-06-11: 4 passed | 2026-06-11 | PD-BUG-105 regression guard (TE-TST-138): project config must exclude e2e-acceptance-testing from the live daemon and preserve all built-in default ignores; written test-first (2 failed pre-fix, 4 pass post-fix) |

## 2. Link Parsing & Update

| Feature ID | Test Type | Test File/Case | Status | Test Cases Count | Last Executed | Last Updated | Notes |
|------------|-----------|----------------|--------|------------------|---------------|--------------|-------|
| 2.1.1 | Automated | [test_parser.py](../../automated/unit/2-link-parsing-update/2-0-link-parsing-update/test_parser.py) | ✅ Audit Approved | 20 | Run 2026-04-28: 20 passed | 2026-04-28 | Parser framework base interface; Audit: [TE-TAR-031](../../audits/unit/2-link-parsing-update/2-0-link-parsing-update/audit-report-2-1-1-test-parser.md); TD171 resolved: added 4 tests for parse_content() facade (specialized routing, generic fallback, no-parser, error handling); TD227 resolved (PD-REF-197): added 4 tests for max_file_size_mb gate (under-limit parses, oversized skipped, zero disables check, missing file graceful); Audit Status: Audit Approved; Test Cases Audited: 12; Auditor: AI Agent; Audit Report: test/audits/unit/2-link-parsing-update/2-0-link-parsing-update/audit-report-2-1-1-test-parser.md; Audit Results: Passed: 12, Failed: 0; Audit Date: 2026-04-03 |
| 2.1.1 | Automated | [test_markdown.py](../../automated/unit/2-link-parsing-update/2-0-link-parsing-update/test_markdown.py) | ✅ Audit Approved | 47 | Run 2026-04-17: 44 passed, 3 xfailed | 2026-04-17 | Markdown link parsing; Audit: [TE-TAR-033](../../audits/unit/2-link-parsing-update/2-0-link-parsing-update/audit-report-2-1-1-test-markdown.md); Auditor: AI Agent; Audit Report: test/audits/unit/2-link-parsing-update/2-0-link-parsing-update/audit-report-2-1-1-test-markdown.md; Audit Status: Audit Approved; Test Cases Audited: 28; Major Findings: 4 xfail tests documenting known limitations (standalone refs, malformed links, escaped chars, bracket placeholders); Audit Results: Passed: 24, Failed: 0; Audit Date: 2026-04-03 |
| 2.1.1 | Automated | [test_yaml.py](../../automated/unit/2-link-parsing-update/2-0-link-parsing-update/test_yaml.py) | ✅ Audit Approved | 17 | Run 2026-04-17: 17 passed | 2026-04-17 | YAML file reference parsing; Audit: [TE-TAR-034](../../audits/unit/2-link-parsing-update/2-0-link-parsing-update/audit-report-2-1-1-test-yaml.md); Test Cases Audited: 14; Audit Report: test/audits/unit/2-link-parsing-update/2-0-link-parsing-update/audit-report-2-1-1-test-yaml.md; Auditor: AI Agent; Major Findings: 1 xfail: multiline YAML strings treated as atomic values; Audit Results: Passed: 13, Failed: 0; Audit Date: 2026-04-03; Audit Status: Audit Approved |
| 2.1.1 | Automated | [test_json.py](../../automated/unit/2-link-parsing-update/2-0-link-parsing-update/test_json.py) | ✅ Audit Approved | 16 | Run 2026-03-22: 16 passed | 2026-04-03 | JSON file reference parsing; Audit: [TE-TAR-035](../../audits/unit/2-link-parsing-update/2-0-link-parsing-update/audit-report-2-1-1-test-json.md); Audit Date: 2026-04-03; Audit Status: Audit Approved; Audit Results: Passed: 18, Failed: 0; Major Findings: 1 xfail: escaped string line-number matching; Test Cases Audited: 19; Audit Report: test/audits/unit/2-link-parsing-update/2-0-link-parsing-update/audit-report-2-1-1-test-json.md; Auditor: AI Agent |
| 2.1.1 | Automated | [test_python.py](../../automated/unit/2-link-parsing-update/2-0-link-parsing-update/test_python.py) | ✅ Audit Approved | 8 | Run 2026-03-22: 8 passed | 2026-04-03 | Python import parsing; Audit: [TE-TAR-036](../../audits/unit/2-link-parsing-update/2-0-link-parsing-update/audit-report-2-1-1-test-python.md); Audit Status: Audit Approved; Audit Results: Passed: 17, Failed: 0; Auditor: AI Agent; Major Findings: No findings — all 17 tests pass with 93pct coverage; Audit Report: test/audits/unit/2-link-parsing-update/2-0-link-parsing-update/audit-report-2-1-1-test-python.md; Test Cases Audited: 17; Audit Date: 2026-04-03 |
| 2.1.1 | Automated | [test_dart.py](../../automated/unit/2-link-parsing-update/2-0-link-parsing-update/test_dart.py) | ✅ Audit Approved | 11 | Run 2026-03-22: 11 passed | 2026-03-22 | Dart import/part parsing |
| 2.1.1 | Automated | [test_generic.py](../../automated/unit/2-link-parsing-update/2-0-link-parsing-update/test_generic.py) | ✅ Audit Approved | 38 | Run 2026-04-28: 38 passed | 2026-04-28 | Generic fallback parser; +17 PD-BUG-095 regression tests (TestBug095LooksLikeRegexOrGlob, TestBug095PathDetectorsRejectRegexAndGlob — regex/glob string rejection in path classifiers) |
| 2.1.1 | Automated | [test_image_files.py](../../automated/unit/2-link-parsing-update/2-0-link-parsing-update/test_image_files.py) | ✅ Audit Approved | 6 | Run 2026-03-22: 6 passed | 2026-03-22 | Image file reference handling |
| 2.2.1 | Automated | [test_updater.py](../../automated/unit/2-link-parsing-update/2-0-link-parsing-update/test_updater.py) | ✅ Audit Approved | 49 | Run 2026-04-29: 49 passed | 2026-04-29 | Link updater atomic operations; TD172 resolved: +13 tests for update_references_batch (5), _update_file_references_multi (4), _replace_reference_target (4); TD251 resolved: +3 tests in TestPythonImportIdempotency for Phase-1 idempotency guard on PYTHON_IMPORT in `_replace_at_position` (PD-REF-215); PD-BUG-098: +4 tests in TestOverlappingReferenceCorruption (inner-contained-in-outer, triple-nested overlap, non-overlapping sanity, invalid-columns bounded fallback); TD252 resolved: +1 test test_ambiguous_fallback_increments_errors_count for Option C errors propagation (PD-REF-219); Audit: [TE-TAR-021](../../audits/unit/2-link-parsing-update/2-0-link-parsing-update/audit-report-2-2-1-test-updater.md); Auditor: AI Agent; Audit Date: 2026-04-03 |
| 2.2.1 | Automated | [test_link_updates.py](../../automated/unit/2-link-parsing-update/2-0-link-parsing-update/test_link_updates.py) | ✅ Audit Approved | 41 | Run 2026-04-28: 40 passed, 1 xfailed | 2026-04-28 | Link update across file formats; +3 PD-BUG-078 regression tests (src/ layout python_source_root); +3 PD-BUG-094 regression tests (Phase 2 module prefix double-apply); +6 PD-BUG-095 regression tests (TestBug095RegexAndGlobNotCorruptedOnDirectoryMove ×4 + TestBug095PathResolverExistenceGuard ×2 — regex/glob preservation on directory moves, Layer 2 existence guard); +3 PD-REF-193 tests (TD212/TD213): test_bug094_from_import_no_double_prefix (from-import form), test_bug094_phase2_multi_rename_order_independent (direct Phase 2 multi-rename verification), test_bug094_dir_move_multi_import_no_double_prefix (xfail strict — tracks PD-BUG-096); Audit: [TE-TAR-022](../../audits/unit/2-link-parsing-update/2-0-link-parsing-update/audit-report-2-2-1-test-link-updates.md); Major Findings: No integration test for update_references_batch() directory move path; PD-BUG-054 assertion fix confirmed correct; Audit Results: Passed: 26, Failed: 0; Audit Status: Audit Approved; Audit Report: test/audits/unit/2-link-parsing-update/2-0-link-parsing-update/audit-report-2-2-1-test-link-updates.md; Test Cases Audited: 26; Auditor: AI Agent; Audit Date: 2026-04-03 |
| 2.1.1 | Automated | [test_powershell.py](../../automated/unit/2-link-parsing-update/2-0-link-parsing-update/test_powershell.py) | ✅ Audit Approved | 32 | Run 2026-04-28: 39 passed | 2026-04-28 | PowerShell parser tests — cmdlet patterns, embedded markdown links, regex filtering (PD-BUG-033 + PD-BUG-095), deduplication. PD-BUG-095: TestRegexPatternFiltering::test_parser_filters_regex_with_quantified_escape now asserts parser-level rejection of regex strings (Layer 1). Registered during test audit. |

## 3. Logging & Monitoring

| Feature ID | Test Type | Test File/Case | Status | Test Cases Count | Last Executed | Last Updated | Notes |
|------------|-----------|----------------|--------|------------------|---------------|--------------|-------|
| 3.1.1 | Automated | [test_logging.py](../../automated/unit/3-logging-monitoring/3-0-logging-monitoring/test_logging.py) | ✅ Audit Approved | 30 | Run 2026-06-04: 30 passed | 2026-06-04 | Logging framework core tests (PD-BUG-099: +2 rotation-failure regression tests in TestTimestampRotatingFileHandlerRotationFailure). PD-REF-209 (TD231): added 2 tests for `LogTimer(enabled=False)` gating (`test_disabled_skips_logging`, `test_disabled_swallows_exception_path`). Audit: [TE-TAR-023](../../audits/unit/3-logging-monitoring/3-0-logging-monitoring/audit-report-3-1-1-test-logging.md); Audit Report: test/audits/unit/3-logging-monitoring/3-0-logging-monitoring/audit-report-3-1-1-test-logging.md; Major Findings: Re-audit confirms prior findings. TimestampRotatingFileHandler.doRollover still untested (34 lines). Untested convenience methods: file_created, links_updated, scan_progress, operation_stats.; Auditor: AI Agent; Audit Status: Audit Approved; Audit Results: Passed: 25, Failed: 0; Test Cases Audited: 25; Audit Date: 2026-04-03 |
| 3.1.1 | Automated | [test_advanced_logging.py](../../automated/unit/3-logging-monitoring/3-0-logging-monitoring/test_advanced_logging.py) | ✅ Audit Approved | 20 | Run 2026-04-03: 20 passed | 2026-04-03 | Advanced logging features; Audit: [TE-TAR-024](../../audits/unit/3-logging-monitoring/3-0-logging-monitoring/audit-report-3-1-1-test-advanced-logging.md); TD168 resolved: Added 14 tests (TestConfigLoadingErrors, TestConfigUtilities, TestConfigHotReload), strengthened 2 existing assertions. Coverage 59%->99%. Assertion density 1.7->2.4. All TE-TAR-024 findings addressed.; Test Cases Audited: 20; Audit Results: Passed: 20, Failed: 0; Audit Date: 2026-04-03; Auditor: AI Agent; Audit Report: test/audits/unit/3-logging-monitoring/3-0-logging-monitoring/audit-report-3-1-1-test-advanced-logging.md; Audit Status: Audit Approved |
| 3.1.1 | Automated | [test_pd-bug-077_startup_venv_validation.py](../../automated/unit/3-logging-monitoring/3-0-logging-monitoring/test_pd-bug-077_startup_venv_validation.py) | ✅ Audit Approved | 4 | Run 2026-04-12: 4 passed | 2026-04-12 | PD-BUG-077 regression tests: bare python in startup script, venv reference, startup verification, install_global venv creation. Relocated from test/automated/bug-validation/ to unit tree (MIG-004, 2026-06-04) — genuine regression coverage, reclassified test_type bug_validation→unit |
| 3.1.1 | Automated | [test_main_logging_setup.py](../../automated/unit/3-logging-monitoring/3-0-logging-monitoring/test_main_logging_setup.py) | 🟡 Implementation In Progress |  | — | 2026-04-29 |  |

## 6. Link Validation & Reporting

| Feature ID | Test Type | Test File/Case | Status | Test Cases Count | Last Executed | Last Updated | Notes |
|------------|-----------|----------------|--------|------------------|---------------|--------------|-------|
| 6.1.1 | Automated | [test_validator.py](../../automated/unit/6-link-validation-reporting/6-0-link-validation-reporting/test_validator.py) | 🟢 Completed | 124 | Run 2026-06-05: 124 passed | 2026-06-05 | Link validation unit tests; +13 cases 2026-06-05 (path_resolution_overrides enhancement, PF-STA-106) — pending next audit cycle; Coverage: 100% (linkwatcher/validator.py); Audit: [TE-TAR-032](../../audits/unit/6-link-validation-reporting/6-0-link-validation-reporting/audit-report-6-1-1-test-validator.md); Tech debt: TD169 (resolved), TD170 (resolved — PD-REF-160, 96%→100%); Audit Report: test/audits/unit/6-link-validation-reporting/6-0-link-validation-reporting/audit-report-6-1-1-test-validator.md; Major Findings: TD169: Parametrized TestShouldCheckTarget (resolved); TD170: Coverage gaps filled 90%→96%→100% (resolved); Audit Date: 2026-04-03; Auditor: AI Agent; Test Cases Audited: 107; Audit Status: Audit Approved; Audit Results: Passed: 107, Failed: 0 |
| 6.1.1 | Automated | [test_shouldmonitorfileancestorpath.py](../../automated/unit/6-link-validation-reporting/6-0-link-validation-reporting/test_shouldmonitorfileancestorpath.py) | 🟢 Completed | 6 | Run 2026-04-28: 6 passed | 2026-04-28 | PD-BUG-087 regression tests (TE-TST-131): ancestor directory check above project_root. Created 2026-04-12 during bug fix; status not updated after PD-BUG-087 closed.; Audit: [TE-TAR-065](../../audits/unit/6-link-validation-reporting/6-0-link-validation-reporting/audit-report-6-1-1-test-shouldmonitorfileancestorpath.md); Audit Report: test/audits/unit/6-link-validation-reporting/6-0-link-validation-reporting/audit-report-6-1-1-test-shouldmonitorfileancestorpath.md; Test Cases Audited: 5; Auditor: AI Agent; Audit Date: 2026-04-20; Audit Results: Passed: 5, Failed: 0; Audit Status: Audit Approved; Major Findings: Missing regression test for ValueError fallback branch (utils.py:78-80) — registered as TD214 (resolved PD-REF-194: added test_file_not_under_project_root_falls_back_to_full_path) |

---

## Process Instructions

### How to Use This File

This file tracks automated tests at the **test file level**. Each entry represents a test file and its associated status. For E2E acceptance tests, see [E2E Acceptance Test Tracking](e2e-test-tracking.md).

### Column Definitions

- **Feature ID**: Reference to the feature being tested (links to feature-tracking.md)
- **Test Type**: `Automated`
- **Test File/Case**: Path and link to the test file (unique identifier)
- **Status**: Current status (see Status Legend above)
- **Test Cases Count**: Number of test cases
- **Last Executed**: Date/result of last test execution
- **Last Updated**: Date of last update to this entry
- **Notes**: Additional context, blockers, or important information

### Workflow Integration

This file is updated by the following tasks:
- **[Integration & Testing (PF-TSK-053)](../../../process-framework/tasks/04-implementation/integration-and-testing.md)**: Updates automated test implementation status and test case counts
- **[New-TestFile.ps1](../../../process-framework/scripts/file-creation/03-testing/New-TestFile.ps1)**: Creates test files with pytest markers and adds tracking entry

**Note**: Test specification status is tracked in the [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) file to avoid redundancy.

### Validation and Quality Assurance

The project includes validation tooling to ensure data integrity between test tracking files and actual test files on disk:

#### Validation Script
- **Validate-TestTracking.ps1** (located in `process-framework/scripts/validation`): Validates consistency between pytest markers (via `test_query.py`), this tracking file, and actual test files on disk
- **Note**: This script is language-agnostic and works with any project configured via `project-config.json`

#### Validation Capabilities
- Validates consistency between pytest markers in test files, tracking files, and actual test files on disk
- Checks for orphaned files and missing references
- Verifies marker integrity and metadata consistency
- Cross-references marker metadata and tracking file entries
- Generates detailed validation reports for quality assurance

#### Usage
```powershell
# Run validation from project root
process-framework/scripts/validation/Validate-TestTracking.ps1
```

### Status Transitions

#### Automated Tests

1. **⬜ Not Started** → **🟡 Implementation In Progress** (when test implementation begins)
2. **🟡 Implementation In Progress** → **🔄 Needs Audit** (when all tests pass and are ready for audit)
3. **🟡 Implementation In Progress** → **🔴 Needs Fix** (when tests start failing)
4. **🔴 Needs Fix** → **🔄 Needs Audit** (when tests are fixed and ready for audit)
5. **🔄 Needs Audit** → **✅ Audit Approved** (when tests pass audit and are approved)
6. **🔄 Needs Audit** → **🔄 Needs Update** (when audit finds issues requiring improvements)
7. **🔄 Needs Update** → **🟡 Implementation In Progress** (when returning to implementation after audit feedback)
8. **Any Status** → **⛔ Implementation Blocked** (when blocked by dependencies)
9. **Any Status** → **🔄 Needs Update** (when code changes require test updates)
10. **Any Status** → **🗑️ Removed** (when test file is deleted or no longer needed)

### Adding New Test Files

When creating new automated test files:
1. Use the [New-TestFile.ps1](../../../process-framework/scripts/file-creation/03-testing/New-TestFile.ps1) script to create the test file with pytest markers
2. Add entry to this file with "⬜ Not Started" implementation status and Test Type "Automated"
3. Test specification status is tracked in the [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) file

---

## Recent Updates
