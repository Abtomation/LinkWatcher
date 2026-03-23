---
id: PF-TSP-044
type: Document
category: General
version: 1.0
created: 2026-03-18
updated: 2026-03-18
feature_ids: ["1.1.1", "2.1.1", "2.2.1", "0.1.1", "0.1.2", "0.1.3", "3.1.1"]
test_type: cross-cutting
test_name: E2E Acceptance Testing Scenarios
---

# Cross-Cutting Test Specification: E2E Acceptance Testing Scenarios

## Overview

This document defines **E2E acceptance test scenarios** that validate user-facing workflows spanning multiple features. These scenarios require a running LinkWatcher instance and simulate real user actions (file moves, directory moves, configuration changes) with observable outcomes.

**Test Type**: Cross-Cutting (E2E Acceptance)
**Features Covered**: 0.1.1, 0.1.2, 0.1.3, 1.1.1, 2.1.1, 2.2.1, 3.1.1
**Created**: 2026-03-18
**User Workflow Map**: [user-workflow-map.md](/doc/product-docs/technical/design/user-workflow-map.md)
**Implementation Coverage**: 19/19 spec scenarios have E2E test cases (100%), plus 3 additional runtime scenarios — see [Coverage Summary](#coverage-summary) for details

## Feature Context

### Features Under Test

| Feature ID | Feature Name | Role in E2E Scenarios |
|------------|-------------|----------------------|
| 0.1.1 | Core Architecture | Orchestrates startup, shutdown, and subsystem coordination |
| 0.1.2 | In-Memory Link Database | Stores file-to-reference mappings, batch lookups for directory moves |
| 0.1.3 | Configuration System | Loads settings, controls monitoring scope, dry-run mode |
| 1.1.1 | File System Monitoring | Detects file/directory moves via delete+create pairing |
| 2.1.1 | Link Parsing System | Parses references in 7 file formats (MD, YAML, JSON, Python, Dart, PowerShell, generic) |
| 2.2.1 | Link Updating | Recalculates relative paths and performs atomic file writes |
| 3.1.1 | Logging System | Logs operations, provides structured output for verification |

### Integration Points

LinkWatcher's core value is a **detection → parsing → updating pipeline** that runs as a single observable chain from the user's perspective. Individual feature tests validate components in isolation with mocks; E2E tests validate the full chain with the actual running system.

### Justification for Cross-Cutting Specification

- Individual feature test specs test components in isolation (mocked dependencies). E2E tests validate the full pipeline with real file system events.
- The delete+create move detection timing (1.1.1) interacts with database state (0.1.2) and parser selection (2.1.1) in ways that unit tests cannot reproduce.
- User-visible outcomes (file contents after move) depend on all features working in concert, not just passing in isolation.

## Scenario Groups

Scenarios are organized by user workflow (from [User Workflow Map](/doc/product-docs/technical/design/user-workflow-map.md)).

### WF-001: Single File Move — Links Updated

**Workflow**: User moves a single file; all references are automatically updated.
**Features**: 1.1.1, 2.1.1, 2.2.1
**Priority**: P1

| ID | Scenario | Arrange | Act | Assert | Priority | E2E Case |
|----|----------|---------|-----|--------|----------|----------|
| S-001 | Move markdown file with standard links | Project with MD file referenced by other MD files via relative links | Move the MD file to a subdirectory | All referencing files have updated relative paths | High | [TE-E2E-004](../../e2e-acceptance-testing/templates/markdown-parser-scenarios/TE-E2E-004-markdown-link-update-on-file-move/test-case.md) |
| S-002 | Move PowerShell script referenced via Import-Module | Project with PS1 file referenced by other PS1 files | Move the PS1 script to a subdirectory | All Import-Module/Join-Path references updated; regex patterns preserved | High | [TE-E2E-002](../../e2e-acceptance-testing/templates/powershell-parser-patterns/TE-E2E-002-powershell-md-file-move/test-case.md), [TE-E2E-003](../../e2e-acceptance-testing/templates/powershell-parser-patterns/TE-E2E-003-powershell-script-file-move/test-case.md) |
| S-003 | Move file referenced from YAML config | Project with file referenced in YAML configs | Move the referenced file | YAML path values updated correctly | Medium | [TE-E2E-005](../../e2e-acceptance-testing/templates/yaml-json-python-parser-scenarios/TE-E2E-005-yaml-link-update-on-file-move/test-case.md) |
| S-004 | Move file referenced from JSON config | Project with file referenced in JSON files | Move the referenced file | JSON path values updated correctly | Medium | [TE-E2E-006](../../e2e-acceptance-testing/templates/yaml-json-python-parser-scenarios/TE-E2E-006-json-link-update-on-file-move/test-case.md) |
| S-005 | Move Python module referenced via imports | Project with Python file referenced via import statements | Move the Python file | Import paths updated correctly | Medium | [TE-E2E-007](../../e2e-acceptance-testing/templates/yaml-json-python-parser-scenarios/TE-E2E-007-python-import-update-on-file-move/test-case.md) |
| S-006 | Move file with special characters in name | Project with files containing spaces, brackets, ampersands in names | Move a special-character file | References updated, special chars handled correctly | High | Partially in TE-E2E-004 |
| S-007 | Regex patterns preserved during PS1 file move | PS1 with regex patterns + real file references | Move the PS1 file | Regex patterns byte-identical, real paths updated | Critical | [TE-E2E-001](../../e2e-acceptance-testing/templates/powershell-regex-preservation/TE-E2E-001-regex-preserved-on-file-move/test-case.md) |

### WF-002: Directory Move — All Contained References Updated

**Workflow**: User moves a directory; all references to contained files are updated.
**Features**: 1.1.1, 0.1.2, 2.1.1, 2.2.1
**Priority**: P1

| ID | Scenario | Arrange | Act | Assert | Priority | E2E Case |
|----|----------|---------|-----|--------|----------|----------|
| S-008 | Move directory with multiple referenced files | Directory with 3+ files referenced from outside | Move the entire directory | All references to all contained files updated | High | [TE-E2E-009](../../e2e-acceptance-testing/templates/runtime-dynamic-operations/TE-E2E-009-directory-create-and-move/test-case.md) |
| S-009 | Move nested directory structure | Directory with subdirectories containing referenced files | Move the top-level directory | References at all nesting levels updated | High | [TE-E2E-013](../../e2e-acceptance-testing/templates/runtime-dynamic-operations/TE-E2E-013-nested-directory-move/test-case.md) |
| S-010 | Move directory — internal references preserved | Directory where files reference each other internally | Move the directory | Internal relative references still valid (no change needed) | Medium | [TE-E2E-014](../../e2e-acceptance-testing/templates/runtime-dynamic-operations/TE-E2E-014-directory-move-internal-refs/test-case.md) |

### WF-003: Startup — Initial Project Scan

**Workflow**: User starts LinkWatcher; initial scan catalogs all files and references.
**Features**: 0.1.1, 0.1.3, 0.1.2, 2.1.1, 1.1.1, 3.1.1
**Priority**: P1

| ID | Scenario | Arrange | Act | Assert | Priority | E2E Case |
|----|----------|---------|-----|--------|----------|----------|
| S-011 | Fresh startup on existing project | Project with known files and references | Start LinkWatcher | Log shows all files scanned, database populated, monitoring active | High | [TE-E2E-012](../../e2e-acceptance-testing/templates/startup-operations/TE-E2E-012-file-operations-during-startup/test-case.md) |
| S-012 | Startup with custom config (exclude directories) | Project + config excluding a directory | Start LinkWatcher with config | Excluded directory's files not scanned or monitored | Medium | [TE-E2E-015](../../e2e-acceptance-testing/templates/startup-operations/TE-E2E-015-startup-custom-config-excludes/test-case.md) |

### WF-004: Rapid Sequential Moves — Consistency Maintained

**Workflow**: User performs multiple file moves rapidly; system stays consistent.
**Features**: 1.1.1, 0.1.2, 2.2.1
**Priority**: P2

| ID | Scenario | Arrange | Act | Assert | Priority | E2E Case |
|----|----------|---------|-----|--------|----------|----------|
| S-013 | Two files moved within 1 second | Project with 2 files referenced from a third | Move both files rapidly | Both references updated correctly, no race conditions | High | [TE-E2E-016](../../e2e-acceptance-testing/templates/rapid-sequential-moves/TE-E2E-016-two-files-moved-rapidly/test-case.md) |
| S-014 | Move file, then move its referencing file | File A references File B | Move B, then immediately move A | Both files have correct references after both moves | Medium | [TE-E2E-017](../../e2e-acceptance-testing/templates/rapid-sequential-moves/TE-E2E-017-move-file-then-referencing-file/test-case.md) |

### WF-005: Multi-Format File Move

**Workflow**: User moves a file referenced from multiple file formats.
**Features**: 2.1.1, 2.2.1, 1.1.1
**Priority**: P2

| ID | Scenario | Arrange | Act | Assert | Priority | E2E Case |
|----|----------|---------|-----|--------|----------|----------|
| S-015 | File referenced from MD, YAML, JSON, and Python simultaneously | File referenced in all 4 formats | Move the referenced file | All 4 format types have updated references | High | [TE-E2E-018](../../e2e-acceptance-testing/templates/multi-format-references/TE-E2E-018-file-referenced-from-all-formats/test-case.md) |

### WF-007: Dry-Run Mode — Preview Without Changes

**Workflow**: User runs in dry-run mode; no files are actually modified.
**Features**: 0.1.3, 0.1.1, 2.2.1, 3.1.1
**Priority**: P3

| ID | Scenario | Arrange | Act | Assert | Priority | E2E Case |
|----|----------|---------|-----|--------|----------|----------|
| S-016 | Move file in dry-run mode | Start LinkWatcher with --dry-run, project with references | Move a referenced file | Log shows what would be updated, but files are unchanged | High | [TE-E2E-019](../../e2e-acceptance-testing/templates/dry-run-mode/TE-E2E-019-move-file-dry-run-no-changes/test-case.md) |

### WF-008: Graceful Shutdown — No Corrupted Files

**Workflow**: User stops LinkWatcher; no files left in corrupted state.
**Features**: 0.1.1, 2.2.1, 0.1.2
**Priority**: P2

| ID | Scenario | Arrange | Act | Assert | Priority | E2E Case |
|----|----------|---------|-----|--------|----------|----------|
| S-017 | Stop during idle | LinkWatcher running, no pending moves | Stop the process | Clean shutdown, no errors | Medium | [TE-E2E-020](../../e2e-acceptance-testing/templates/graceful-shutdown/TE-E2E-020-stop-during-idle/test-case.md) |
| S-018 | Stop immediately after file move | Move a file, then immediately stop LinkWatcher | Stop within 1 second of move | Files are either fully updated or not modified at all (atomic) | High | [TE-E2E-021](../../e2e-acceptance-testing/templates/graceful-shutdown/TE-E2E-021-stop-immediately-after-move/test-case.md) |

### Error Recovery

**Workflow**: System handles error conditions gracefully.
**Features**: 0.1.1, 2.2.1, 3.1.1
**Priority**: P2

| ID | Scenario | Arrange | Act | Assert | Priority | E2E Case |
|----|----------|---------|-----|--------|----------|----------|
| S-019 | Move file to read-only directory | Project with references, target location is read-only | Move a file; LinkWatcher attempts to update a read-only referencing file | Error logged, other files still updated, no crash | Medium | [TE-E2E-022](../../e2e-acceptance-testing/templates/error-recovery/TE-E2E-022-read-only-referencing-file/test-case.md) |

## Mock Requirements

E2E acceptance tests use **no mocks** — they run against the actual LinkWatcher system with real file system events. This is the defining characteristic of E2E acceptance testing vs. automated integration testing.

## Coverage Summary

### Existing E2E Test Cases (22 cases in 11 groups)

| E2E ID | Scenario | Group | Status |
|--------|----------|-------|--------|
| TE-E2E-001 | S-007: Regex patterns preserved during PS1 move | TE-E2G-001 | ✅ Passed |
| TE-E2E-002 | S-002: Move MD file referenced in PS1 comments | TE-E2G-002 | 📋 Case Created |
| TE-E2E-003 | S-002: Move PS1 script referenced via Import-Module | TE-E2G-002 | 📋 Case Created |
| TE-E2E-004 | S-001: Move MD file with standard links + special chars | TE-E2G-003 | 📋 Case Created |
| TE-E2E-005 | S-003: Move file referenced from YAML configs | TE-E2G-004 | 📋 Case Created |
| TE-E2E-006 | S-004: Move file referenced from JSON configs | TE-E2G-004 | 📋 Case Created |
| TE-E2E-007 | S-005: Move Python module referenced via imports | TE-E2G-004 | 📋 Case Created |
| TE-E2E-008 | Runtime file create + move | TE-E2G-005 | 📋 Case Created |
| TE-E2E-009 | S-008: Runtime directory create + move | TE-E2G-005 | 📋 Case Created |
| TE-E2E-010 | Runtime file create + rename | TE-E2G-005 | 📋 Case Created |
| TE-E2E-011 | Runtime directory create + rename | TE-E2G-005 | 📋 Case Created |
| TE-E2E-012 | S-011: File operations during startup | TE-E2G-006 | 📋 Case Created |
| TE-E2E-013 | S-009: Nested directory move | TE-E2G-005 | 📋 Case Created |
| TE-E2E-014 | S-010: Directory move — internal refs preserved | TE-E2G-005 | 📋 Case Created |
| TE-E2E-015 | S-012: Startup with custom config (exclude dirs) | TE-E2G-006 | 📋 Case Created |
| TE-E2E-016 | S-013: Two files moved within 1 second | TE-E2G-007 | 📋 Case Created |
| TE-E2E-017 | S-014: Move file, then move referencing file | TE-E2G-007 | 📋 Case Created |
| TE-E2E-018 | S-015: File referenced from MD, YAML, JSON, Python | TE-E2G-008 | 📋 Case Created |
| TE-E2E-019 | S-016: Move file in dry-run mode | TE-E2G-009 | 📋 Case Created |
| TE-E2E-020 | S-017: Stop during idle | TE-E2G-010 | 📋 Case Created |
| TE-E2E-021 | S-018: Stop immediately after file move | TE-E2G-010 | 📋 Case Created |
| TE-E2E-022 | S-019: Read-only referencing file | TE-E2G-011 | 📋 Case Created |

### Coverage Gaps

All 19 spec scenarios now have E2E test cases. No remaining coverage gaps.

## Related Resources

- [User Workflow Map](/doc/product-docs/technical/design/user-workflow-map.md) — Workflow definitions and feature mappings
- [Test Registry](/test/test-registry.yaml) — Registry entries for cross-cutting test files
- [Test Tracking](/test/state-tracking/permanent/test-tracking.md) — Implementation status
- Feature Test Specifications:
  - [0.1.1 Core Architecture](/test/specifications/feature-specs/test-spec-0-1-1-core-architecture.md)
  - [0.1.2 In-Memory Database](/test/specifications/feature-specs/test-spec-0-1-2-in-memory-link-database.md)
  - [0.1.3 Configuration System](/test/specifications/feature-specs/test-spec-0-1-3-configuration-system.md)
  - [1.1.1 File System Monitoring](/test/specifications/feature-specs/test-spec-1-1-1-file-system-monitoring.md)
  - [2.1.1 Link Parsing System](/test/specifications/feature-specs/test-spec-2-1-1-link-parsing-system.md)
  - [2.2.1 Link Updating](/test/specifications/feature-specs/test-spec-2-2-1-link-updating.md)
  - [3.1.1 Logging System](/test/specifications/feature-specs/test-spec-3-1-1-logging-system.md)
