---
id: TE-STA-001
type: Process Framework
category: State File
version: 3.0
created: 2025-07-13
updated: 2026-03-23
tracking_scope: Test Tracking (Automated + Manual)
state_type: Implementation Status
---
# Test Tracking

This file tracks the implementation status of all tests — automated and E2E acceptance — derived from test specifications in the LinkWatcher project. Each entry represents a test file or E2E acceptance test case and its associated status, organized by feature categories.

## Status Legend

### Automated Test Statuses

| Status | Description |
|--------|-------------|
| 📝 **Specification Created** | Test specification document has been created but tests not yet implemented |
| 🟡 **Implementation In Progress** | Test implementation has started but is not complete |
| 🔄 **Ready for Validation** | Tests are implemented and ready for audit validation |
| ✅ **Tests Implemented** | All tests from specification have been implemented and are passing |
| 🟡 **Tests Approved with Dependencies** | Tests are approved by audit but some tests await implementation dependencies |
| 🔴 **Tests Failing** | Tests are implemented but some are currently failing |
| ⛔ **Implementation Blocked** | Test implementation is blocked by dependencies or issues |
| 🔄 **Needs Update** | Test specification or implementation needs updates due to code changes or audit findings |
| 🗑️ **Removed** | Test file has been removed due to being outdated or no longer needed |

### E2E Acceptance Test Statuses

| Status | Description |
|--------|-------------|
| 📋 **Case Created** | E2E acceptance test case exists but has never been executed |
| ✅ **Passed** | Last execution passed |
| 🔴 **Failed** | Last execution failed |
| 🔄 **Needs Re-execution** | Code changes invalidated the last result |
| ⬜ **Not Created** | E2E acceptance test case needed but not yet created |

## Coverage Summary

| Date | Total Coverage | Tests Passed | Tests Skipped | Tests Failed | Run Type |
|------|---------------|--------------|---------------|--------------|----------|
| 2026-03-22 | 57% | 186 | 0 | 0 | Category: unit |
| 2026-03-22 | 86% | 477 | 5 | 0 | All (excl. slow) |

## Testing Infrastructure

> Shared test fixtures, utilities, and performance benchmarks. These are project-specific implementations of the patterns described in the [Testing Setup Guide](/doc/process-framework/guides/03-testing/testing-setup-guide.md).

| Test ID | Feature ID | Test Type | Test File/Case | Status | Test Cases Count | Last Executed | Last Updated | Notes |
|---------|------------|-----------|----------------|--------|------------------|---------------|--------------|-------|
| TE-TST-098 | — | Automated | [conftest.py](../../automated/conftest.py) | ✅ Tests Implemented | 8 | — | 2026-03-22 | Root test fixtures (9 shared fixtures) |
| TE-TST-099 | — | Automated | [utils.py](../../automated/utils.py) | ✅ Tests Implemented | 5 | — | 2026-03-22 | Test utility functions and builders |
| TE-TST-126 | — | Automated | [test_large_projects.py](../../automated/performance/test_large_projects.py) | ✅ Tests Implemented | 4 | Run 2026-03-22: 2 passed, 2 skipped | 2026-03-22 | Performance benchmarks |
| TE-TST-131 | — | Automated | [test_benchmark.py](../../automated/performance/test_benchmark.py) | ✅ Tests Implemented | 3 | Run 2026-03-24: 3 passed | 2026-03-24 | Parsing, database, and scan benchmarks |

# Test Status by Feature Category

## 0. System Architecture & Foundation

| Test ID | Feature ID | Test Type | Test File/Case | Status | Test Cases Count | Last Executed | Last Updated | Notes |
|---------|------------|-----------|----------------|--------|------------------|---------------|--------------|-------|
| TE-TST-102 | 0.1.1 | Automated | ✅ Tests Approved | ✅ Tests Implemented | 24 | Run 2026-03-22: 24 passed | 2026-03-22 | Core service orchestration unit tests |
| TE-TST-116 | 0.1.1 | Automated | ✅ Tests Approved | ✅ Tests Implemented | 17 | Run 2026-03-22: 17 passed | 2026-03-22 | Service integration with subsystems |
| TE-TST-119 | 0.1.1 | Automated | ✅ Tests Approved | ✅ Tests Implemented | 11 | Run 2026-03-22: 11 passed | 2026-03-22 | Complex multi-component scenarios |
| TE-TST-120 | 0.1.1 | Automated | ✅ Tests Approved | ✅ Tests Implemented | 19 | Run 2026-03-22: 18 passed, 1 skipped | 2026-03-22 | Error handling and graceful degradation |
| TE-TST-104 | 0.1.2 | Automated | ✅ Tests Approved | ✅ Tests Implemented | 26 | Run 2026-03-22: 26 passed | 2026-03-22 | In-memory database thread-safe operations |
| TE-TST-100 | 0.1.3 | Automated | [test_config.py](../../automated/test_config.py) | ✅ Tests Implemented | 10 | — | 2026-02-20 | Configuration system tests (root) |
| TE-TST-106 | 0.1.3 | Automated | ✅ Tests Approved | ✅ Tests Implemented | 42 | Run 2026-03-22: 42 passed | 2026-03-22 | Configuration system unit tests |
| TE-TST-122 | 0.1.1 | Automated | ✅ Tests Approved | ✅ Tests Implemented | 16 | Run 2026-03-22: 14 passed, 2 skipped | 2026-03-22 | Windows path handling integration tests |
| TE-TST-127 | 0.1.1 | Automated | ✅ Tests Approved | ✅ Tests Implemented | 10 | Run 2026-03-22: 10 passed | 2026-03-22 | Duplicate instance prevention lock file mechanism |

## 1. File Watching & Detection

| Test ID | Feature ID | Test Type | Test File/Case | Status | Test Cases Count | Last Executed | Last Updated | Notes |
|---------|------------|-----------|----------------|--------|------------------|---------------|--------------|-------|
| TE-TST-101 | 1.1.1 | Automated | ✅ Tests Approved | ✅ Tests Implemented | 20 | Run 2026-03-22: 20 passed | 2026-03-22 | File move detection integration |
| TE-TST-117 | 1.1.1 | Automated | ✅ Tests Approved | ✅ Tests Implemented | 7 | Run 2026-03-22: 7 passed | 2026-03-22 | File movement handling integration |
| TE-TST-121 | 1.1.1 | Automated | ✅ Tests Approved | ✅ Tests Implemented | 4 | Run 2026-03-22: 4 passed | 2026-03-22 | Sequential file move scenarios |
| TE-TST-123 | 1.1.1 | Automated | ✅ Tests Approved | ✅ Tests Implemented | 7 | Run 2026-03-22: 7 passed | 2026-03-22 | Comprehensive file type monitoring |
| TE-TST-124 | 1.1.1 | Automated | ✅ Tests Approved | ✅ Tests Implemented | 6 | Run 2026-03-22: 6 passed | 2026-03-22 | Image file monitoring |
| TE-TST-125 | 1.1.1 | Automated | ✅ Tests Approved | ✅ Tests Implemented | 5 | Run 2026-03-22: 5 passed | 2026-03-22 | PowerShell script monitoring |

## 2. Link Parsing & Update

| Test ID | Feature ID | Test Type | Test File/Case | Status | Test Cases Count | Last Executed | Last Updated | Notes |
|---------|------------|-----------|----------------|--------|------------------|---------------|--------------|-------|
| TE-TST-103 | 2.1.1 | Automated | ✅ Tests Approved | ✅ Tests Implemented | 12 | Run 2026-03-22: 12 passed | 2026-03-22 | Parser framework base interface |
| TE-TST-109 | 2.1.1 | Automated | ✅ Tests Approved | ✅ Tests Implemented | 24 | Run 2026-03-22: 24 passed | 2026-03-22 | Markdown link parsing |
| TE-TST-110 | 2.1.1 | Automated | ✅ Tests Approved | ✅ Tests Implemented | 12 | Run 2026-03-22: 12 passed | 2026-03-22 | YAML file reference parsing |
| TE-TST-111 | 2.1.1 | Automated | ✅ Tests Approved | ✅ Tests Implemented | 16 | Run 2026-03-22: 16 passed | 2026-03-22 | JSON file reference parsing |
| TE-TST-112 | 2.1.1 | Automated | ✅ Tests Approved | ✅ Tests Implemented | 8 | Run 2026-03-22: 8 passed | 2026-03-22 | Python import parsing |
| TE-TST-113 | 2.1.1 | Automated | ✅ Tests Approved | ✅ Tests Implemented | 11 | Run 2026-03-22: 11 passed | 2026-03-22 | Dart import/part parsing |
| TE-TST-114 | 2.1.1 | Automated | ✅ Tests Approved | ✅ Tests Implemented | 21 | Run 2026-03-22: 21 passed | 2026-03-22 | Generic fallback parser |
| TE-TST-115 | 2.1.1 | Automated | ✅ Tests Approved | ✅ Tests Implemented | 6 | Run 2026-03-22: 6 passed | 2026-03-22 | Image file reference handling |
| TE-TST-105 | 2.2.1 | Automated | ✅ Tests Approved | ✅ Tests Implemented | 28 | Run 2026-03-22: 28 passed | 2026-03-22 | Link updater atomic operations |
| TE-TST-118 | 2.2.1 | Automated | ✅ Tests Approved | ✅ Tests Implemented | 26 | Run 2026-03-22: 26 passed | 2026-03-22 | Link update across file formats |
| TE-TST-129 | 2.1.1 | Automated | [test_powershell.py](../../automated/parsers/test_powershell.py) | ✅ Tests Implemented | 32 | Run 2026-03-22: 32 passed | 2026-03-22 | PowerShell parser tests — cmdlet patterns, embedded markdown links, regex filtering (PD-BUG-033), deduplication. Registered during test audit. |

## 3. Logging & Monitoring

| Test ID | Feature ID | Test Type | Test File/Case | Status | Test Cases Count | Last Executed | Last Updated | Notes |
|---------|------------|-----------|----------------|--------|------------------|---------------|--------------|-------|
| TE-TST-107 | 3.1.1 | Automated | ✅ Tests Approved | ✅ Tests Implemented | 25 | Run 2026-03-22: 25 passed | 2026-03-22 | Logging framework core tests |
| TE-TST-108 | 3.1.1 | Automated | ✅ Tests Approved | ✅ Tests Implemented | 19 | Run 2026-03-22: 19 passed | 2026-03-22 | Advanced logging features |

## E2E Acceptance Tests

> E2E acceptance tests validate user-facing workflows that span multiple features. They require a running LinkWatcher instance and simulate real user actions. See [User Workflow Map](/doc/product-docs/technical/design/user-workflow-map.md) for workflow definitions and [Cross-Cutting E2E Spec (PF-TSP-044)](/test/specifications/cross-cutting-specs/cross-cutting-spec-e2e-acceptance-testing-scenarios.md) for scenario details.

### Workflow Milestone Tracking

| Workflow | Description | Required Features | Features Ready | E2E Spec | E2E Cases | Status |
|----------|-------------|------------------|----------------|----------|-----------|--------|
| WF-001 | Single file move → links updated | 1.1.1, 2.1.1, 2.2.1 | 3/3 | [PF-TSP-044](/test/specifications/cross-cutting-specs/cross-cutting-spec-e2e-acceptance-testing-scenarios.md) | TE-E2G-001, TE-E2G-002, TE-E2G-003, TE-E2G-004 | 🔄 Re-execution Needed |
| WF-002 | Directory move → contained refs updated | 1.1.1, 0.1.2, 2.1.1, 2.2.1 | 4/4 | [PF-TSP-044](/test/specifications/cross-cutting-specs/cross-cutting-spec-e2e-acceptance-testing-scenarios.md) | TE-E2G-005 | ✅ Covered |
| WF-003 | Startup → initial project scan | 0.1.1, 0.1.3, 0.1.2, 2.1.1, 1.1.1, 3.1.1 | 6/6 | [PF-TSP-044](/test/specifications/cross-cutting-specs/cross-cutting-spec-e2e-acceptance-testing-scenarios.md) | TE-E2G-006 | ✅ Covered |
| WF-004 | Rapid sequential moves → consistency | 1.1.1, 0.1.2, 2.2.1 | 3/3 | [PF-TSP-044](/test/specifications/cross-cutting-specs/cross-cutting-spec-e2e-acceptance-testing-scenarios.md) | TE-E2G-007 | ✅ Covered |
| WF-005 | Multi-format file move | 2.1.1, 2.2.1, 1.1.1 | 3/3 | [PF-TSP-044](/test/specifications/cross-cutting-specs/cross-cutting-spec-e2e-acceptance-testing-scenarios.md) | TE-E2G-008 | ✅ Covered |
| WF-007 | Dry-run mode → preview | 0.1.3, 0.1.1, 2.2.1, 3.1.1 | 4/4 | [PF-TSP-044](/test/specifications/cross-cutting-specs/cross-cutting-spec-e2e-acceptance-testing-scenarios.md) | TE-E2G-009 | 🔴 Failing |
| WF-008 | Graceful shutdown → no corruption | 0.1.1, 2.2.1, 0.1.2 | 3/3 | [PF-TSP-044](/test/specifications/cross-cutting-specs/cross-cutting-spec-e2e-acceptance-testing-scenarios.md) | TE-E2G-010 | ✅ Covered |

### E2E Test Cases

| Test ID | Workflow | Feature IDs | Test Type | Test File/Case | Status | Last Executed | Last Updated | Notes |
|---------|----------|-------------|-----------|----------------|--------|---------------|--------------|-------|
| TE-E2G-001 | WF-001 | 1.1.1, 2.1.1, 2.2.1 | E2E Group | [master-test-powershell-regex-preservation.md](../../e2e-acceptance-testing/templates/powershell-regex-preservation/master-test-powershell-regex-preservation.md) | ✅ Passed | 2026-03-15 | 2026-03-15 | PD-BUG-033: Regex preservation on file move |
| TE-E2E-001 | WF-001 | 1.1.1, 2.1.1, 2.2.1 | E2E Case | [TE-E2E-001-regex-preserved-on-file-move](../../e2e-acceptance-testing/templates/powershell-regex-preservation/TE-E2E-001-regex-preserved-on-file-move/test-case.md) | ✅ Passed | 2026-03-15 | 2026-03-15 | Verify regex patterns not rewritten, real paths updated |
| TE-E2G-002 | WF-001 | 1.1.1, 2.1.1, 2.2.1 | E2E Group | [master-test-powershell-parser-patterns.md](../../e2e-acceptance-testing/templates/powershell-parser-patterns/master-test-powershell-parser-patterns.md) | 🔴 Failed | 2026-03-18 | 2026-03-18 | PD-BUG-044: Reference resolution fails for nested project structures |
| TE-E2E-002 | WF-001 | 1.1.1, 2.1.1, 2.2.1 | E2E Case | [TE-E2E-002-powershell-md-file-move](../../e2e-acceptance-testing/templates/powershell-parser-patterns/TE-E2E-002-powershell-md-file-move/test-case.md) | 🔴 Failed | 2026-03-18 | 2026-03-18 | PD-BUG-044: Reference resolution fails for nested project structures |
| TE-E2E-003 | WF-001 | 1.1.1, 2.1.1, 2.2.1 | E2E Case | [TE-E2E-003-powershell-script-file-move](../../e2e-acceptance-testing/templates/powershell-parser-patterns/TE-E2E-003-powershell-script-file-move/test-case.md) | 🔴 Failed | 2026-03-18 | 2026-03-18 | PD-BUG-044: Reference resolution fails for nested project structures |
| TE-E2G-003 | WF-001 | 1.1.1, 2.1.1, 2.2.1 | E2E Group | [master-test-markdown-parser-scenarios.md](../../e2e-acceptance-testing/templates/markdown-parser-scenarios/master-test-markdown-parser-scenarios.md) | 🔴 Failed | 2026-03-18 | 2026-03-18 | PD-BUG-044: Verify script line ending mismatch (links correctly updated) |
| TE-E2E-004 | WF-001 | 1.1.1, 2.1.1, 2.2.1 | E2E Case | [TE-E2E-004-markdown-link-update-on-file-move](../../e2e-acceptance-testing/templates/markdown-parser-scenarios/TE-E2E-004-markdown-link-update-on-file-move/test-case.md) | 🔴 Failed | 2026-03-18 | 2026-03-18 | PD-BUG-044: Verify script line ending mismatch (links correctly updated) |
| TE-E2G-004 | WF-001 | 1.1.1, 2.1.1, 2.2.1 | E2E Group | [master-test-yaml-json-python-parser-scenarios.md](../../e2e-acceptance-testing/templates/yaml-json-python-parser-scenarios/master-test-yaml-json-python-parser-scenarios.md) | ✅ Passed | 2026-03-23 | 2026-03-23 | YAML, JSON, Python parser scenarios |
| TE-E2E-005 | WF-001 | 1.1.1, 2.1.1, 2.2.1 | E2E Case | [TE-E2E-005-yaml-link-update-on-file-move](../../e2e-acceptance-testing/templates/yaml-json-python-parser-scenarios/TE-E2E-005-yaml-link-update-on-file-move/test-case.md) | ✅ Passed | 2026-03-23 | 2026-03-23 | PD-BUG-046 fix verified — .conf move detected, YAML refs updated |
| TE-E2E-006 | WF-001 | 1.1.1, 2.1.1, 2.2.1 | E2E Case | [TE-E2E-006-json-link-update-on-file-move](../../e2e-acceptance-testing/templates/yaml-json-python-parser-scenarios/TE-E2E-006-json-link-update-on-file-move/test-case.md) | ✅ Passed | 2026-03-23 | 2026-03-23 | JSON link update on file move |
| TE-E2E-007 | WF-001 | 1.1.1, 2.1.1, 2.2.1 | E2E Case | [TE-E2E-007-python-import-update-on-file-move](../../e2e-acceptance-testing/templates/yaml-json-python-parser-scenarios/TE-E2E-007-python-import-update-on-file-move/test-case.md) | ✅ Passed | 2026-03-23 | 2026-03-23 | Python import update on file move |
| TE-E2G-005 | WF-001, WF-002 | 1.1.1, 0.1.2, 2.1.1, 2.2.1 | E2E Group | [master-test-runtime-dynamic-operations.md](../../e2e-acceptance-testing/templates/runtime-dynamic-operations/master-test-runtime-dynamic-operations.md) | ✅ Passed | 2026-03-23 | 2026-03-23 | Runtime dynamic operations: file/directory create, move, rename |
| TE-E2E-008 | WF-001 | 1.1.1, 2.1.1, 2.2.1 | E2E Case | [TE-E2E-008-file-create-and-move](../../e2e-acceptance-testing/templates/runtime-dynamic-operations/TE-E2E-008-file-create-and-move/test-case.md) | ✅ Passed | 2026-03-23 | 2026-03-23 | File create and move |
| TE-E2E-009 | WF-002 | 1.1.1, 0.1.2, 2.1.1, 2.2.1 | E2E Case | [TE-E2E-009-directory-create-and-move](../../e2e-acceptance-testing/templates/runtime-dynamic-operations/TE-E2E-009-directory-create-and-move/test-case.md) | ✅ Passed | 2026-03-23 | 2026-03-23 | Directory create and move |
| TE-E2E-010 | WF-001 | 1.1.1, 2.1.1, 2.2.1 | E2E Case | [TE-E2E-010-file-create-and-rename](../../e2e-acceptance-testing/templates/runtime-dynamic-operations/TE-E2E-010-file-create-and-rename/test-case.md) | ✅ Passed | 2026-03-23 | 2026-03-23 | File create and rename |
| TE-E2E-011 | WF-002 | 1.1.1, 0.1.2, 2.1.1, 2.2.1 | E2E Case | [TE-E2E-011-directory-create-and-rename](../../e2e-acceptance-testing/templates/runtime-dynamic-operations/TE-E2E-011-directory-create-and-rename/test-case.md) | ✅ Passed | 2026-03-23 | 2026-03-23 | Directory create and rename |
| TE-E2E-013 | WF-002 | 1.1.1, 0.1.2, 2.1.1, 2.2.1 | E2E Case | [TE-E2E-013-nested-directory-move](../../e2e-acceptance-testing/templates/runtime-dynamic-operations/TE-E2E-013-nested-directory-move/test-case.md) | ✅ Passed | 2026-03-23 | 2026-03-23 | Nested directory move |
| TE-E2E-014 | WF-002 | 1.1.1, 0.1.2, 2.1.1, 2.2.1 | E2E Case | [TE-E2E-014-directory-move-internal-refs](../../e2e-acceptance-testing/templates/runtime-dynamic-operations/TE-E2E-014-directory-move-internal-refs/test-case.md) | ✅ Passed | 2026-03-23 | 2026-03-23 | Directory move — internal references preserved |
| TE-E2G-006 | WF-003 | 0.1.1, 0.1.2, 0.1.3, 1.1.1, 2.1.1, 2.2.1 | E2E Group | [master-test-startup-operations.md](../../e2e-acceptance-testing/templates/startup-operations/master-test-startup-operations.md) | 🔴 Failed | 2026-03-23 | 2026-03-23 | PD-BUG-047: TE-E2E-012 run.ps1 infrastructure issue |
| TE-E2E-012 | WF-003 | 0.1.1, 0.1.2, 0.1.3, 1.1.1, 2.1.1, 2.2.1 | E2E Case | [TE-E2E-012-file-operations-during-startup](../../e2e-acceptance-testing/templates/startup-operations/TE-E2E-012-file-operations-during-startup/test-case.md) | 🔴 Failed | 2026-03-23 | 2026-03-23 | PD-BUG-047: TE-E2E-012 run.ps1 infrastructure issue |
| TE-E2E-015 | WF-003 | 0.1.1, 0.1.3, 0.1.2, 2.1.1, 1.1.1 | E2E Case | [TE-E2E-015-startup-custom-config-excludes](../../e2e-acceptance-testing/templates/startup-operations/TE-E2E-015-startup-custom-config-excludes/test-case.md) | ✅ Passed | 2026-03-23 | 2026-03-23 | Startup with custom config excludes |
| TE-E2G-007 | WF-004 | 1.1.1, 0.1.2, 2.2.1 | E2E Group | [master-test-rapid-sequential-moves.md](../../e2e-acceptance-testing/templates/rapid-sequential-moves/master-test-rapid-sequential-moves.md) | ✅ Passed | 2026-03-23 | 2026-03-23 | Rapid sequential moves: consistency under fast operations |
| TE-E2E-016 | WF-004 | 1.1.1, 0.1.2, 2.2.1 | E2E Case | [TE-E2E-016-two-files-moved-rapidly](../../e2e-acceptance-testing/templates/rapid-sequential-moves/TE-E2E-016-two-files-moved-rapidly/test-case.md) | ✅ Passed | 2026-03-23 | 2026-03-23 | Two files moved rapidly |
| TE-E2E-017 | WF-004 | 1.1.1, 0.1.2, 2.2.1 | E2E Case | [TE-E2E-017-move-file-then-referencing-file](../../e2e-acceptance-testing/templates/rapid-sequential-moves/TE-E2E-017-move-file-then-referencing-file/test-case.md) | ✅ Passed | 2026-03-23 | 2026-03-23 | Move file then move referencing file |
| TE-E2G-008 | WF-005 | 2.1.1, 2.2.1, 1.1.1 | E2E Group | [master-test-multi-format-references.md](../../e2e-acceptance-testing/templates/multi-format-references/master-test-multi-format-references.md) | ✅ Passed | 2026-03-23 | 2026-03-23 | Multi-format: single file move updates refs across all formats |
| TE-E2E-018 | WF-005 | 2.1.1, 2.2.1, 1.1.1 | E2E Case | [TE-E2E-018-file-referenced-from-all-formats](../../e2e-acceptance-testing/templates/multi-format-references/TE-E2E-018-file-referenced-from-all-formats/test-case.md) | ✅ Passed | 2026-03-23 | 2026-03-23 | File referenced from all formats |
| TE-E2G-009 | WF-007 | 0.1.3, 0.1.1, 2.2.1, 3.1.1 | E2E Group | [master-test-dry-run-mode.md](../../e2e-acceptance-testing/templates/dry-run-mode/master-test-dry-run-mode.md) | 🔴 Failed | 2026-03-23 | 2026-03-23 | PD-BUG-048: orchestrator lacks --dry-run support |
| TE-E2E-019 | WF-007 | 0.1.3, 0.1.1, 2.2.1, 3.1.1 | E2E Case | [TE-E2E-019-move-file-dry-run-no-changes](../../e2e-acceptance-testing/templates/dry-run-mode/TE-E2E-019-move-file-dry-run-no-changes/test-case.md) | 🔴 Failed | 2026-03-23 | 2026-03-23 | PD-BUG-048: orchestrator lacks --dry-run support |
| TE-E2G-010 | WF-008 | 0.1.1, 2.2.1, 0.1.2 | E2E Group | [master-test-graceful-shutdown.md](../../e2e-acceptance-testing/templates/graceful-shutdown/master-test-graceful-shutdown.md) | ✅ Passed | 2026-03-23 | 2026-03-23 | Graceful shutdown: no corruption on Ctrl+C |
| TE-E2E-020 | WF-008 | 0.1.1, 2.2.1, 0.1.2 | E2E Case | [TE-E2E-020-stop-during-idle](../../e2e-acceptance-testing/templates/graceful-shutdown/TE-E2E-020-stop-during-idle/test-case.md) | ✅ Passed | 2026-03-23 | 2026-03-23 | Stop during idle |
| TE-E2E-021 | WF-008 | 0.1.1, 2.2.1, 0.1.2 | E2E Case | [TE-E2E-021-stop-immediately-after-move](../../e2e-acceptance-testing/templates/graceful-shutdown/TE-E2E-021-stop-immediately-after-move/test-case.md) | ✅ Passed | 2026-03-23 | 2026-03-23 | Stop immediately after file move |
| TE-E2G-011 | — | 0.1.1, 2.2.1, 3.1.1 | E2E Group | [master-test-error-recovery.md](../../e2e-acceptance-testing/templates/error-recovery/master-test-error-recovery.md) | ✅ Passed | 2026-03-23 | 2026-03-23 | Error recovery: read-only file handling |
| TE-E2E-022 | — | 0.1.1, 2.2.1, 3.1.1 | E2E Case | [TE-E2E-022-read-only-referencing-file](../../e2e-acceptance-testing/templates/error-recovery/TE-E2E-022-read-only-referencing-file/test-case.md) | ✅ Passed | 2026-03-23 | 2026-03-23 | Read-only referencing file |

---

## Process Instructions

### How to Use This File

This file tracks tests at the **test file level** (automated) and **test case/group level** (E2E acceptance). Each entry represents either an automated test file or an E2E acceptance test case/group. For detailed test case information, refer to the actual test files or E2E acceptance test case documents.

### Column Definitions

- **Test ID**: Unique identifier (TE-TST-### for automated, TE-E2G-### for E2E groups, TE-E2E-### for E2E cases)
- **Feature ID**: Reference to the feature being tested (links to feature-tracking.md)
- **Test Type**: `Automated`, `E2E Group`, or `E2E Case`
- **Test File/Case**: Path and link to the test file or E2E acceptance test case document
- **Status**: Current status (see Status Legend above)
- **Test Cases Count**: Number of test cases (automated files only)
- **Last Executed**: Date of last E2E acceptance test execution (— for automated tests)
- **Last Updated**: Date of last update to this entry
- **Notes**: Additional context, blockers, or important information

### Workflow Integration

This file is updated by the following tasks:
- **[Integration & Testing (PF-TSK-053)](../../../doc/process-framework/tasks/04-implementation/integration-and-testing.md)**: Updates automated test implementation status and test case counts
- **[New-TestFile.ps1](../../../../scripts/New-TestFile.ps1)**: Generates Test File IDs and updates test registry
- **E2E Acceptance Test Case Creation**: Adds E2E acceptance test case/group entries (PF-TSK-069)
- **E2E Acceptance Test Execution**: Updates E2E acceptance test execution status and dates (PF-TSK-070)

**Note**: Test specification status is tracked in the [Feature Tracking](../../../doc/product-docs/state-tracking/permanent/feature-tracking.md) file to avoid redundancy.

### Validation and Quality Assurance

The project includes validation tooling to ensure data integrity between test tracking files and actual test files on disk:

#### Validation Script
- **Validate-TestTracking.ps1** (located in `doc/process-framework/scripts/validation/`): Validates consistency between test-registry.yaml, this tracking file, and actual test files on disk
- **Note**: This script is language-agnostic and works with any project configured via `project-config.json`

#### Validation Capabilities
- Validates consistency between test registry, tracking files, and actual test files
- Checks for orphaned files, missing references, and ID conflicts
- Ensures YAML structure integrity and ID uniqueness
- Cross-references registry and tracking file entries
- Generates detailed validation reports for quality assurance

#### Usage
```powershell
# Run validation from project root
doc/process-framework/scripts/validation/Validate-TestTracking.ps1
```

### Status Transitions

#### Automated Tests

1. **⬜ Not Started** → **🟡 Implementation In Progress** (when test implementation begins)
2. **🟡 Implementation In Progress** → **🔄 Ready for Validation** (when all tests pass and are ready for audit)
3. **🟡 Implementation In Progress** → **🔴 Tests Failing** (when tests start failing)
4. **🔴 Tests Failing** → **🔄 Ready for Validation** (when tests are fixed and ready for audit)
5. **🔄 Ready for Validation** → **✅ Tests Implemented** (when tests pass audit and are approved)
6. **🔄 Ready for Validation** → **🔄 Needs Update** (when audit finds issues requiring improvements)
7. **🔄 Needs Update** → **🟡 Implementation In Progress** (when returning to implementation after audit feedback)
8. **Any Status** → **⛔ Implementation Blocked** (when blocked by dependencies)
9. **Any Status** → **🔄 Needs Update** (when code changes require test updates)
10. **Any Status** → **🗑️ Removed** (when test file is deleted or no longer needed)

#### E2E Acceptance Tests

1. **⬜ Not Created** → **📋 Case Created** (when E2E acceptance test case is written)
2. **📋 Case Created** → **✅ Passed** (when first execution passes)
3. **📋 Case Created** → **🔴 Failed** (when first execution fails)
4. **✅ Passed** → **🔄 Needs Re-execution** (when code changes invalidate the result)
5. **🔴 Failed** → **🔄 Needs Re-execution** (when code changes invalidate the result)
6. **🔄 Needs Re-execution** → **✅ Passed** (when re-execution passes)
7. **🔄 Needs Re-execution** → **🔴 Failed** (when re-execution fails)

### Adding New Test Files

When creating new automated test files:
1. Use the [New-TestFile.ps1](../../../../scripts/New-TestFile.ps1) script to generate Test File ID
2. Add entry to this file with "⬜ Not Started" implementation status and Test Type "Automated"
3. Update the [test-registry.yaml](../../test-registry.yaml) file
4. Test specification status is tracked in the [Feature Tracking](../../../doc/product-docs/state-tracking/permanent/feature-tracking.md) file

### Adding E2E Acceptance Test Cases

When creating new E2E acceptance test cases:
1. Create test case using the E2E Acceptance Test Case Creation task (PF-TSK-069)
2. Add entry to this file with Test Type "E2E Case" or "E2E Group" and status "📋 Case Created"
3. Set Last Executed to "—" (not yet executed)
4. Update [Feature Tracking](../../../doc/product-docs/state-tracking/permanent/feature-tracking.md) Test Status if needed

---

## Recent Updates
