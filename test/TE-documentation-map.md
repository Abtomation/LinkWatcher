---
id: TE-MAI-001
type: Test Documentation
category: Documentation Map
version: 1.0
created: 2026-04-03
updated: 2026-04-03
---

# Test Documentation Map

This document indexes all test documentation in the `test/` directory — specifications, audit reports, E2E acceptance tests, and test state tracking.

> **See also**: [Process Framework Documentation Map](/process-framework/PF-documentation-map.md) | [Product Documentation Map](/doc/PD-documentation-map.md)

## `audits/` — Test Audit Reports

_Created during test audit sessions (PF-TSK-030)._

- [Audits README](audits/README.md)

### `audits/foundation/`

- [Audit: Core Architecture 0.1.1 (TE-TAR-011)](audits/foundation/audit-report-0-1-1-pd-tst-102.md) - Foundation feature test quality assessment
- [Audit: In-Memory Database 0.1.2 (TE-TAR-011)](audits/foundation/audit-report-0-1-2-pd-tst-104.md) - Database test quality assessment
- [Audit: Configuration System 0.1.3](audits/foundation/audit-report-0-1-3-pd-tst-106.md) - Configuration test quality assessment

### `audits/authentication/`

- [Audit: File System Monitoring 1.1.1 (TE-TAR-012)](audits/authentication/audit-report-1-1-1-pd-tst-101.md) - File watching test quality assessment

### `audits/core-features/`

- [Audit: Link Parsing System 2.1.1 (TE-TAR-010)](audits/core-features/audit-report-2-1-1-pd-tst-103.md) - Parser test quality assessment
- [Audit: Link Updating 2.2.1](audits/core-features/audit-report-2-2-1-pd-tst-105.md) - Updater test quality assessment
- [Audit: Logging System 3.1.1](audits/core-features/audit-report-3-1-1-pd-tst-107.md) - Logging test quality assessment

## `e2e-acceptance-testing/` — E2E Acceptance Tests

- [E2E Acceptance Testing README](e2e-acceptance-testing/README.md) - Overview and test execution guide

### `e2e-acceptance-testing/templates/` — Test Groups

- [Master Test: PowerShell Regex Preservation](e2e-acceptance-testing/templates/powershell-regex-preservation/master-test-powershell-regex-preservation.md)
- [Master Test: PowerShell Parser Patterns](e2e-acceptance-testing/templates/powershell-parser-patterns/master-test-powershell-parser-patterns.md)
- [Master Test: Markdown Parser Scenarios](e2e-acceptance-testing/templates/markdown-parser-scenarios/master-test-markdown-parser-scenarios.md)
- [Master Test: YAML/JSON/Python Parser Scenarios](e2e-acceptance-testing/templates/yaml-json-python-parser-scenarios/master-test-yaml-json-python-parser-scenarios.md)
- [Master Test: Runtime Dynamic Operations](e2e-acceptance-testing/templates/runtime-dynamic-operations/master-test-runtime-dynamic-operations.md)
- [Master Test: Startup Operations](e2e-acceptance-testing/templates/startup-operations/master-test-startup-operations.md)
- [Master Test: Rapid Sequential Moves](e2e-acceptance-testing/templates/rapid-sequential-moves/master-test-rapid-sequential-moves.md)
- [Master Test: Multi-Format References](e2e-acceptance-testing/templates/multi-format-references/master-test-multi-format-references.md)
- [Master Test: Dry Run Mode](e2e-acceptance-testing/templates/dry-run-mode/master-test-dry-run-mode.md)
- [Master Test: Graceful Shutdown](e2e-acceptance-testing/templates/graceful-shutdown/master-test-graceful-shutdown.md)
- [Master Test: Error Recovery](e2e-acceptance-testing/templates/error-recovery/master-test-error-recovery.md)

## `specifications/` — Test Specifications

### `specifications/feature-specs/`

_Created during framework onboarding (PF-TSK-066 / PF-TSK-012) — documenting existing test suite._

- [Test Spec: Core Architecture (TE-TSP-035)](specifications/feature-specs/test-spec-0-1-1-core-architecture.md) - 0.1.1 Tier 3 — Existing test coverage with gap analysis
- [Test Spec: In-Memory Link Database (TE-TSP-036)](specifications/feature-specs/test-spec-0-1-2-in-memory-link-database.md) - 0.1.2 Tier 2 — Database thread-safety and CRUD operations
- [Test Spec: Configuration System (TE-TSP-037)](specifications/feature-specs/test-spec-0-1-3-configuration-system.md) - 0.1.3 Tier 1 — Multi-source config loading and validation
- [Test Spec: File System Monitoring (TE-TSP-038)](specifications/feature-specs/test-spec-1-1-1-file-system-monitoring.md) - 1.1.1 Tier 2 — Move detection, file filtering, monitoring
- [Test Spec: Link Parsing System (TE-TSP-039)](specifications/feature-specs/test-spec-2-1-1-link-parsing-system.md) - 2.1.1 Tier 2 — Parser registry with 6 format-specific parsers
- [Test Spec: Link Updating (TE-TSP-040)](specifications/feature-specs/test-spec-2-2-1-link-updating.md) - 2.2.1 Tier 2 — Atomic updates, dry-run, backup creation
- [Test Spec: Logging System (TE-TSP-041)](specifications/feature-specs/test-spec-3-1-1-logging-system.md) - 3.1.1 Tier 2 — Structured logging, filtering, metrics
- ~~Test Spec: Test Suite (TE-TSP-042)~~ - 🗄️ Archived (PF-PRO-009) — testing infrastructure generalized into framework
- ~~Test Spec: CI/CD & Development Tooling (TE-TSP-043)~~ - 🗄️ Archived (PF-PRO-009) — CI/CD infrastructure generalized into framework

### `specifications/cross-cutting-specs/`

- [E2E Acceptance Testing Scenarios (TE-TSP-044)](specifications/cross-cutting-specs/cross-cutting-spec-e2e-acceptance-testing-scenarios.md) - Cross-cutting — 19 E2E scenarios across 8 workflows, organized by [User Workflow Tracking](/doc/state-tracking/permanent/user-workflow-tracking.md)

## `state-tracking/` — Test State Tracking

### `state-tracking/permanent/`

- [State: Test Tracking](state-tracking/permanent/test-tracking.md) - Tracks implementation status of automated test files derived from test specifications
- [State: E2E Acceptance Test Tracking](state-tracking/permanent/e2e-test-tracking.md) - Tracks E2E acceptance test cases, workflow milestones, and execution status

## Maintaining This Documentation

When adding new test documentation:
1. Add the entry to the appropriate directory section in this map
2. Use local relative paths from `test/` (no `../test/` prefix needed)
3. For process framework documents, add to [Process Framework Documentation Map](/process-framework/PF-documentation-map.md) instead
4. For product documents, add to [Product Documentation Map](/doc/PD-documentation-map.md) instead
