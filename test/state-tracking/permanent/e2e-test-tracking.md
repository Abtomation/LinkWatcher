---
id: TE-STA-002
type: Process Framework
category: State File
version: 1.0
created: 2026-03-25
updated: 2026-06-12
tracking_scope: E2E Acceptance Test Tracking
state_type: Implementation Status
---
# E2E Acceptance Test Tracking

E2E acceptance tests validate user-facing workflows that span multiple features. They require a running LinkWatcher instance and simulate real user actions. See [User Workflow Tracking](/doc/state-tracking/permanent/user-workflow-tracking.md) for workflow definitions and [Cross-Cutting E2E Spec (PF-TSP-044)](/test/specifications/cross-cutting-specs/cross-cutting-spec-e2e-acceptance-testing-scenarios.md) for scenario details.

> **Split from**: [test-tracking.md](test-tracking.md) (PF-IMP-210) — E2E section was the scalability bottleneck.

## Status Legend

### Lifecycle Status

| Symbol | Status | Description | Next Task |
|--------|--------|-------------|-----------|
| ⬜ | **Not Created** | E2E acceptance test case needed but not yet created | PF-TSK-069 |
| 📋 | **Needs Execution** | E2E acceptance test case exists but has never been executed | PF-TSK-070 |
| ✅ | **Passed** | Last execution passed — no action needed | — |
| 🔴 | **Failed** | Last execution failed — needs bug triage | PF-TSK-041 |
| 🔄 | **Needs Re-execution** | Code changes invalidated the last result | PF-TSK-070 |

### Audit Status

Tracked per-test in the **Audit Status** column. Set by [Test Audit (PF-TSK-030)](/process-framework/tasks/03-testing/test-audit-task.md) with `-TestType E2E`.

| Symbol | Status | Description |
|--------|--------|-------------|
| 🔍 | **Audit Approved** | All audit criteria pass — test is ready for execution |
| 🔍 | **Audit In Progress** | Multi-session audit underway — interim state until approved or marked Needs Update |
| 🔄 | **Needs Update** | Test case or fixtures need corrections before execution |
| 🔴 | **Audit Failed** | Scenario fundamentally flawed or fixtures incorrect |
| — | _(not yet audited)_ | Test case has not undergone audit. **Only valid** when Lifecycle Status is `📋 Needs Execution`. A `✅ Passed` or `🔴 Failed` row with `Audit Status = —` is a compliance hole (e.g., test executed without prior audit) and needs retroactive audit. |

> **Audit gate**: Tests in `📋 Needs Execution` status must reach `✅ Audit Approved` in the Audit Status column before execution. The audit gate enforces a one-way flow: Lifecycle Status `✅ Passed` or `🔴 Failed` implies an approved audit. Tests at `🔄 Needs Re-execution` are exempt (already audited prior to first execution).

## Workflow Milestone Tracking

| Workflow | Description | Required Features | Features Ready | E2E Spec | E2E Cases | Status |
|----------|-------------|------------------|----------------|----------|-----------|--------|
| WF-001 | Single file move → links updated | 1.1.1, 2.1.1, 2.2.1 | 3/3 | [PF-TSP-044](/test/specifications/cross-cutting-specs/cross-cutting-spec-e2e-acceptance-testing-scenarios.md) | TE-E2G-001, TE-E2G-002, TE-E2G-003, TE-E2G-004 | 🔄 Re-execution Needed |
| WF-002 | Directory move → contained refs updated | 1.1.1, 0.1.2, 2.1.1, 2.2.1 | 4/4 | [PF-TSP-044](/test/specifications/cross-cutting-specs/cross-cutting-spec-e2e-acceptance-testing-scenarios.md) | TE-E2G-005 | 🔄 Re-execution Needed |
| WF-003 | Startup → initial project scan | 0.1.1, 0.1.3, 0.1.2, 2.1.1, 1.1.1, 3.1.1 | 6/6 | [PF-TSP-044](/test/specifications/cross-cutting-specs/cross-cutting-spec-e2e-acceptance-testing-scenarios.md) | TE-E2G-006 | 🔄 Re-execution Needed |
| WF-004 | Rapid sequential moves → consistency | 1.1.1, 0.1.2, 2.2.1 | 3/3 | [PF-TSP-044](/test/specifications/cross-cutting-specs/cross-cutting-spec-e2e-acceptance-testing-scenarios.md) | TE-E2G-007 | 🔄 Re-execution Needed |
| WF-005 | Multi-format file move | 2.1.1, 2.2.1, 1.1.1 | 3/3 | [PF-TSP-044](/test/specifications/cross-cutting-specs/cross-cutting-spec-e2e-acceptance-testing-scenarios.md) | TE-E2G-008 | 🔄 Re-execution Needed |
| WF-007 | Dry-run mode → preview | 0.1.3, 0.1.1, 2.2.1, 3.1.1 | 4/4 | [PF-TSP-044](/test/specifications/cross-cutting-specs/cross-cutting-spec-e2e-acceptance-testing-scenarios.md) | TE-E2G-009 | ✅ Covered |
| WF-008 | Graceful shutdown → no corruption | 0.1.1, 2.2.1, 0.1.2 | 3/3 | [PF-TSP-044](/test/specifications/cross-cutting-specs/cross-cutting-spec-e2e-acceptance-testing-scenarios.md) | TE-E2G-010 | 🔴 Failing |
| WF-006 | Configuration change → behavior adapts | 0.1.3, 1.1.1, 3.1.1 | 3/3 | — | TE-E2G-012 | 🔄 Re-execution Needed |
| WF-009 | Link health audit → broken link report | 0.1.1, 2.1.1, 6.1.1 | 3/3 | — | TE-E2G-013 | ✅ Covered |

## E2E Test Cases

<!-- Convention: Groups (TE-E2G-*) act as parent headers. Cases (TE-E2E-*) listed immediately after a group belong to that group. There is no explicit parent column — the relationship is positional. -->
<!-- Notes column: free-text; bug/issue references are status-snapshots, not auto-updated. Verify current status (e.g., in bug-tracking.md) before treating any reference as a live constraint. -->

| Test ID | Workflow | Feature IDs | Test Type | Test File/Case | Status | Last Executed | Last Updated | Audit Status | Audit Report | Notes |
|---------|----------|-------------|-----------|----------------|--------|---------------|--------------|--------------|--------------|-------|
| TE-E2G-001 | WF-001 | 1.1.1, 2.1.1, 2.2.1 | E2E Group | [master-test-powershell-regex-preservation.md](../../e2e-acceptance-testing/single-file-move-links-updated/templates/master-test-powershell-regex-preservation.md) | 🔄 Needs Re-execution | 2026-06-12 | 2026-06-12 | — | — | PD-BUG-033: Regex preservation on file move |
| TE-E2E-001 | WF-001 | 1.1.1, 2.1.1, 2.2.1 | E2E Case | [TE-E2E-001-regex-preserved-on-file-move](../../e2e-acceptance-testing/single-file-move-links-updated/templates/TE-E2E-001-regex-preserved-on-file-move/test-case.md) | 🔄 Needs Re-execution | 2026-06-12 | 2026-06-12 | 🔍 Audit In Progress | [TE-TAR-064](../../audits/e2e/audit-report-te-e2e-015-test-case.md) | PD-BUG-109: own-output exclusion swallows watched tree (workspace LW log outside project root) - no events processed |
| TE-E2G-002 | WF-001 | 1.1.1, 2.1.1, 2.2.1 | E2E Group | [master-test-powershell-parser-patterns.md](../../e2e-acceptance-testing/single-file-move-links-updated/templates/master-test-powershell-parser-patterns.md) | 🔄 Needs Re-execution | 2026-06-12 | 2026-06-12 | — | — | Suffix duplication: move-target-2.ps1 rewritten to move-target-2.ps1-2.ps1 |
| TE-E2E-002 | WF-001 | 1.1.1, 2.1.1, 2.2.1 | E2E Case | [TE-E2E-002-powershell-md-file-move](../../e2e-acceptance-testing/single-file-move-links-updated/templates/TE-E2E-002-powershell-md-file-move/test-case.md) | 🔄 Needs Re-execution | 2026-06-12 | 2026-06-12 | ✅ Audit Approved | [TE-TAR-038](../../audits/e2e/audit-report-2-1-1-test-case.md) | PD-BUG-109: own-output exclusion swallows watched tree (workspace LW log outside project root) - no events processed |
| TE-E2E-003 | WF-001 | 1.1.1, 2.1.1, 2.2.1 | E2E Case | [TE-E2E-003-powershell-script-file-move](../../e2e-acceptance-testing/single-file-move-links-updated/templates/TE-E2E-003-powershell-script-file-move/test-case.md) | 🔄 Needs Re-execution | 2026-06-12 | 2026-06-12 | ✅ Audit Approved | [TE-TAR-039](../../audits/e2e/audit-report-te-e2e-003-test-case.md) | PD-BUG-109: own-output exclusion swallows watched tree (workspace LW log outside project root) - no events processed |
| TE-E2G-003 | WF-001 | 1.1.1, 2.1.1, 2.2.1 | E2E Group | [master-test-markdown-parser-scenarios.md](../../e2e-acceptance-testing/single-file-move-links-updated/templates/master-test-markdown-parser-scenarios.md) | 🔄 Needs Re-execution | 2026-06-12 | 2026-06-12 | — | — | Markdown parser scenarios — bare path updates in prose are correct behavior |
| TE-E2E-004 | WF-001 | 1.1.1, 2.1.1, 2.2.1 | E2E Case | [TE-E2E-004-markdown-link-update-on-file-move](../../e2e-acceptance-testing/single-file-move-links-updated/templates/TE-E2E-004-markdown-link-update-on-file-move/test-case.md) | 🔄 Needs Re-execution | 2026-06-12 | 2026-06-12 | ✅ Audit Approved | [TE-TAR-040](../../audits/e2e/audit-report-te-e2e-004-test-case.md) | PD-BUG-109: own-output exclusion swallows watched tree (workspace LW log outside project root) - no events processed |
| TE-E2G-004 | WF-001 | 1.1.1, 2.1.1, 2.2.1 | E2E Group | [master-test-yaml-json-python-parser-scenarios.md](../../e2e-acceptance-testing/single-file-move-links-updated/templates/master-test-yaml-json-python-parser-scenarios.md) | 🔄 Needs Re-execution | 2026-06-12 | 2026-06-12 | — | — | YAML, JSON, Python parser scenarios |
| TE-E2E-005 | WF-001 | 1.1.1, 2.1.1, 2.2.1 | E2E Case | [TE-E2E-005-yaml-link-update-on-file-move](../../e2e-acceptance-testing/single-file-move-links-updated/templates/TE-E2E-005-yaml-link-update-on-file-move/test-case.md) | 🔄 Needs Re-execution | 2026-06-12 | 2026-06-12 | ✅ Audit Approved | [TE-TAR-041](../../audits/e2e/audit-report-te-e2e-005-test-case.md) | PD-BUG-109: own-output exclusion swallows watched tree (workspace LW log outside project root) - no events processed |
| TE-E2E-006 | WF-001 | 1.1.1, 2.1.1, 2.2.1 | E2E Case | [TE-E2E-006-json-link-update-on-file-move](../../e2e-acceptance-testing/single-file-move-links-updated/templates/TE-E2E-006-json-link-update-on-file-move/test-case.md) | 🔄 Needs Re-execution | 2026-06-12 | 2026-06-12 | ✅ Audit Approved | [TE-TAR-042](../../audits/e2e/audit-report-te-e2e-006-test-case.md) | PD-BUG-109: own-output exclusion swallows watched tree (workspace LW log outside project root) - no events processed |
| TE-E2E-007 | WF-001 | 1.1.1, 2.1.1, 2.2.1 | E2E Case | [TE-E2E-007-python-import-update-on-file-move](../../e2e-acceptance-testing/single-file-move-links-updated/templates/TE-E2E-007-python-import-update-on-file-move/test-case.md) | 🔄 Needs Re-execution | 2026-06-12 | 2026-06-12 | ✅ Audit Approved | [TE-TAR-043](../../audits/e2e/audit-report-te-e2e-007-test-case.md) | PD-BUG-109: own-output exclusion swallows watched tree (workspace LW log outside project root) - no events processed |
| TE-E2G-005 | WF-001, WF-002 | 1.1.1, 0.1.2, 2.1.1, 2.2.1 | E2E Group | [master-test-runtime-dynamic-operations.md](../../e2e-acceptance-testing/directory-move-contained-refs-updated/templates/master-test-runtime-dynamic-operations.md) | 🔄 Needs Re-execution | 2026-06-12 | 2026-06-12 | — | — | Runtime dynamic operations: file/directory create, move, rename |
| TE-E2E-008 | WF-001 | 1.1.1, 2.1.1, 2.2.1 | E2E Case | [TE-E2E-008-file-create-and-move](../../e2e-acceptance-testing/single-file-move-links-updated/templates/TE-E2E-008-file-create-and-move/test-case.md) | 🔄 Needs Re-execution | 2026-06-12 | 2026-06-12 | — | — | PD-BUG-109: own-output exclusion swallows watched tree (workspace LW log outside project root) - no events processed |
| TE-E2E-009 | WF-002 | 1.1.1, 0.1.2, 2.1.1, 2.2.1 | E2E Case | [TE-E2E-009-directory-create-and-move](../../e2e-acceptance-testing/directory-move-contained-refs-updated/templates/TE-E2E-009-directory-create-and-move/test-case.md) | 🔄 Needs Re-execution | 2026-06-12 | 2026-06-12 | — | — | PD-BUG-109: own-output exclusion swallows watched tree (workspace LW log outside project root) - no events processed |
| TE-E2E-010 | WF-001 | 1.1.1, 2.1.1, 2.2.1 | E2E Case | [TE-E2E-010-file-create-and-rename](../../e2e-acceptance-testing/single-file-move-links-updated/templates/TE-E2E-010-file-create-and-rename/test-case.md) | 🔄 Needs Re-execution | 2026-06-12 | 2026-06-12 | — | — | PD-BUG-109: own-output exclusion swallows watched tree (workspace LW log outside project root) - no events processed |
| TE-E2E-011 | WF-002 | 1.1.1, 0.1.2, 2.1.1, 2.2.1 | E2E Case | [TE-E2E-011-directory-create-and-rename](../../e2e-acceptance-testing/directory-move-contained-refs-updated/templates/TE-E2E-011-directory-create-and-rename/test-case.md) | 🔄 Needs Re-execution | 2026-06-12 | 2026-06-12 | — | — | PD-BUG-109: own-output exclusion swallows watched tree (workspace LW log outside project root) - no events processed |
| TE-E2E-013 | WF-002 | 1.1.1, 0.1.2, 2.1.1, 2.2.1 | E2E Case | [TE-E2E-013-nested-directory-move](../../e2e-acceptance-testing/directory-move-contained-refs-updated/templates/TE-E2E-013-nested-directory-move/test-case.md) | 🔄 Needs Re-execution | 2026-06-12 | 2026-06-12 | — | — | PD-BUG-109: own-output exclusion swallows watched tree (workspace LW log outside project root) - no events processed |
| TE-E2E-014 | WF-002 | 1.1.1, 0.1.2, 2.1.1, 2.2.1 | E2E Case | [TE-E2E-014-directory-move-internal-refs](../../e2e-acceptance-testing/directory-move-contained-refs-updated/templates/TE-E2E-014-directory-move-internal-refs/test-case.md) | 🔄 Needs Re-execution | 2026-06-12 | 2026-06-12 | — | — | PD-BUG-109: own-output exclusion swallows watched tree (workspace LW log outside project root) - no events processed |
| TE-E2E-029 | WF-001 | 1.1.1, 2.1.1, 2.2.1 | E2E Case | [TE-E2E-029-external-edit-then-move](../../e2e-acceptance-testing/single-file-move-links-updated/templates/TE-E2E-029-external-edit-then-move/test-case.md) | 🔄 Needs Re-execution | 2026-06-12 | 2026-06-12 | ✅ Audit Approved | [audit-report-te-e2e-029-test-case](../../audits/e2e/audit-report-te-e2e-029-test-case.md) | PD-BUG-109: own-output exclusion swallows watched tree (workspace LW log outside project root) - no events processed |
| TE-E2G-006 | WF-003 | 0.1.1, 0.1.2, 0.1.3, 1.1.1, 2.1.1, 2.2.1 | E2E Group | [master-test-startup-operations.md](../../e2e-acceptance-testing/startup-initial-project-scan/templates/master-test-startup-operations.md) | 🔄 Needs Re-execution | 2026-06-12 | 2026-06-12 | — | — | Both cases passing after PD-BUG-053 fix confirmed stable |
| TE-E2E-012 | WF-003 | 0.1.1, 0.1.2, 0.1.3, 1.1.1, 2.1.1, 2.2.1 | E2E Case | [TE-E2E-012-file-operations-during-startup](../../e2e-acceptance-testing/startup-initial-project-scan/templates/TE-E2E-012-file-operations-during-startup/test-case.md) | 🔄 Needs Re-execution | 2026-06-12 | 2026-06-12 | — | — | PD-BUG-109: own-output exclusion swallows watched tree (workspace LW log outside project root) - no events processed |
| TE-E2E-015 | WF-003 | 0.1.1, 0.1.3, 0.1.2, 2.1.1, 1.1.1 | E2E Case | [TE-E2E-015-startup-custom-config-excludes](../../e2e-acceptance-testing/startup-initial-project-scan/templates/TE-E2E-015-startup-custom-config-excludes/test-case.md) | 🔄 Needs Re-execution | 2026-06-12 | 2026-06-12 | — | — | PD-BUG-109: own-output exclusion swallows watched tree (workspace LW log outside project root) - no events processed |
| TE-E2G-007 | WF-004 | 1.1.1, 0.1.2, 2.2.1 | E2E Group | [master-test-rapid-sequential-moves.md](../../e2e-acceptance-testing/rapid-sequential-moves-consistency/templates/master-test-rapid-sequential-moves.md) | 🔄 Needs Re-execution | 2026-06-12 | 2026-06-12 | — | — | Rapid sequential moves: consistency under fast operations |
| TE-E2E-016 | WF-004 | 1.1.1, 0.1.2, 2.2.1 | E2E Case | [TE-E2E-016-two-files-moved-rapidly](../../e2e-acceptance-testing/rapid-sequential-moves-consistency/templates/TE-E2E-016-two-files-moved-rapidly/test-case.md) | 🔄 Needs Re-execution | 2026-06-12 | 2026-06-12 | ✅ Audit Approved | [TE-TAR-044](../../audits/e2e/audit-report-te-e2g-007-test-case.md) | PD-BUG-109: own-output exclusion swallows watched tree (workspace LW log outside project root) - no events processed |
| TE-E2E-017 | WF-004 | 1.1.1, 0.1.2, 2.2.1 | E2E Case | [TE-E2E-017-move-file-then-referencing-file](../../e2e-acceptance-testing/rapid-sequential-moves-consistency/templates/TE-E2E-017-move-file-then-referencing-file/test-case.md) | 🔄 Needs Re-execution | 2026-06-12 | 2026-06-12 | ✅ Audit Approved | [TE-TAR-045](../../audits/e2e/audit-report-te-e2e-017-test-case.md) | PD-BUG-109: own-output exclusion swallows watched tree (workspace LW log outside project root) - no events processed |
| TE-E2G-008 | WF-005 | 2.1.1, 2.2.1, 1.1.1 | E2E Group | [master-test-multi-format-references.md](../../e2e-acceptance-testing/multi-format-file-move-all-parsers-handle/templates/master-test-multi-format-references.md) | 🔄 Needs Re-execution | 2026-06-12 | 2026-06-12 | — | — | Multi-format: single file move updates refs across all formats |
| TE-E2E-018 | WF-005 | 2.1.1, 2.2.1, 1.1.1 | E2E Case | [TE-E2E-018-file-referenced-from-all-formats](../../e2e-acceptance-testing/multi-format-file-move-all-parsers-handle/templates/TE-E2E-018-file-referenced-from-all-formats/test-case.md) | 🔄 Needs Re-execution | 2026-06-12 | 2026-06-12 | ✅ Audit Approved | [TE-TAR-046](../../audits/e2e/audit-report-te-e2e-018-test-case.md) | PD-BUG-109: own-output exclusion swallows watched tree (workspace LW log outside project root) - no events processed |
| TE-E2G-009 | WF-007 | 0.1.3, 0.1.1, 2.2.1, 3.1.1 | E2E Group | [master-test-dry-run-mode.md](../../e2e-acceptance-testing/dry-run-mode-preview-without-changes/templates/master-test-dry-run-mode.md) | ✅ Passed | 2026-06-11 | 2026-06-11 | — | — | PD-BUG-048 fix verified |
| TE-E2E-019 | WF-007 | 0.1.3, 0.1.1, 2.2.1, 3.1.1 | E2E Case | [TE-E2E-019-move-file-dry-run-no-changes](../../e2e-acceptance-testing/dry-run-mode-preview-without-changes/templates/TE-E2E-019-move-file-dry-run-no-changes/test-case.md) | ✅ Passed | 2026-06-12 | 2026-06-12 | ✅ Audit Approved | [TE-TAR-047](../../audits/e2e/audit-report-te-e2e-019-test-case.md) |  |
| TE-E2G-010 | WF-008 | 0.1.1, 2.2.1, 0.1.2 | E2E Group | [master-test-graceful-shutdown.md](../../e2e-acceptance-testing/graceful-shutdown-no-corrupted-files/templates/master-test-graceful-shutdown.md) | 🔴 Failed | 2026-06-12 | 2026-06-12 | — | — | Graceful shutdown: no corruption on Ctrl+C |
| TE-E2E-020 | WF-008 | 0.1.1, 2.2.1, 0.1.2 | E2E Case | [TE-E2E-020-stop-during-idle](../../e2e-acceptance-testing/graceful-shutdown-no-corrupted-files/templates/TE-E2E-020-stop-during-idle/test-case.md) | ✅ Passed | 2026-06-12 | 2026-06-12 | ✅ Audit Approved | [TE-TAR-048](../../audits/e2e/audit-report-0-1-1-test-case.md) |  |
| TE-E2E-021 | WF-008 | 0.1.1, 2.2.1, 0.1.2 | E2E Case | [TE-E2E-021-stop-immediately-after-move](../../e2e-acceptance-testing/graceful-shutdown-no-corrupted-files/templates/TE-E2E-021-stop-immediately-after-move/test-case.md) | 🔴 Failed | 2026-06-12 | 2026-06-12 | ✅ Audit Approved | [TE-TAR-049](../../audits/e2e/audit-report-te-e2e-021-test-case.md) | PD-BUG-109: own-output exclusion swallows watched tree (workspace LW log outside project root) - no events processed |
| TE-E2G-011 | WF-008 | 0.1.1, 2.2.1, 3.1.1 | E2E Group | [master-test-error-recovery.md](../../e2e-acceptance-testing/graceful-shutdown-no-corrupted-files/templates/master-test-error-recovery.md) | 🔴 Failed | 2026-06-12 | 2026-06-12 | — | — | Error recovery: read-only file handling (folded into WF-008 graceful-shutdown dir per MIG-003 — no dedicated workflow) |
| TE-E2E-022 | WF-008 | 0.1.1, 2.2.1, 3.1.1 | E2E Case | [TE-E2E-022-read-only-referencing-file](../../e2e-acceptance-testing/graceful-shutdown-no-corrupted-files/templates/TE-E2E-022-read-only-referencing-file/test-case.md) | 🔴 Failed | 2026-06-12 | 2026-06-12 | ✅ Audit Approved | [TE-TAR-050](../../audits/e2e/audit-report-te-e2e-022-test-case.md) | PD-BUG-109: own-output exclusion swallows watched tree (workspace LW log outside project root) - no events processed |
| TE-E2G-012 | WF-006 | 0.1.3, 1.1.1, 3.1.1 | E2E Group | [master-test-configuration-behavior-adaptation.md](../../e2e-acceptance-testing/configuration-change-behavior-adapts/templates/master-test-configuration-behavior-adaptation.md) | 🔄 Needs Re-execution | 2026-06-12 | 2026-06-12 | — | — | Bug fix PD-BUG-109 |
| TE-E2E-023 | WF-006 | 0.1.3, 1.1.1, 3.1.1 | E2E Case | [TE-E2E-023-custom-monitored-extensions](../../e2e-acceptance-testing/configuration-change-behavior-adapts/templates/TE-E2E-023-custom-monitored-extensions/test-case.md) | 🔄 Needs Re-execution | 2026-06-12 | 2026-06-12 | ✅ Audit Approved | [TE-TAR-051](../../audits/e2e/audit-report-te-e2e-023-test-case.md) | PD-BUG-109: own-output exclusion swallows watched tree (workspace LW log outside project root) - no events processed |
| TE-E2E-024 | WF-006 | 0.1.3, 1.1.1, 3.1.1 | E2E Case | [TE-E2E-024-custom-ignored-directories](../../e2e-acceptance-testing/configuration-change-behavior-adapts/templates/TE-E2E-024-custom-ignored-directories/test-case.md) | 🔄 Needs Re-execution | 2026-06-12 | 2026-06-12 | ✅ Audit Approved | [TE-TAR-052](../../audits/e2e/audit-report-te-e2e-024-test-case.md) | PD-BUG-109: own-output exclusion swallows watched tree (workspace LW log outside project root) - no events processed |
| TE-E2E-025 | WF-006 | 0.1.3, 1.1.1, 3.1.1 | E2E Case | [TE-E2E-025-backup-creation-enabled](../../e2e-acceptance-testing/configuration-change-behavior-adapts/templates/TE-E2E-025-backup-creation-enabled/test-case.md) | 🔄 Needs Re-execution | 2026-06-12 | 2026-06-12 | ✅ Audit Approved | [TE-TAR-053](../../audits/e2e/audit-report-te-e2e-025-test-case.md) | PD-BUG-109: own-output exclusion swallows watched tree (workspace LW log outside project root) - no events processed |
| TE-E2G-013 | WF-009 | 0.1.1, 2.1.1, 6.1.1 | E2E Group | [master-test-link-validation-audit.md](../../e2e-acceptance-testing/link-health-audit-broken-link-report/templates/master-test-link-validation-audit.md) | ✅ Passed | 2026-06-10 | 2026-06-10 | — | — | All 3 cases passing after PD-BUG-088 fix |
| TE-E2E-026 | WF-009 | 0.1.1, 2.1.1, 6.1.1 | E2E Case | [TE-E2E-026-validate-clean-workspace](../../e2e-acceptance-testing/link-health-audit-broken-link-report/templates/TE-E2E-026-validate-clean-workspace/test-case.md) | ✅ Passed | 2026-06-12 | 2026-06-12 | ✅ Audit Approved | [TE-TAR-054](../../audits/e2e/audit-report-te-e2e-026-test-case.md) |  |
| TE-E2E-027 | WF-009 | 0.1.1, 2.1.1, 6.1.1 | E2E Case | [TE-E2E-027-validate-broken-links-detected](../../e2e-acceptance-testing/link-health-audit-broken-link-report/templates/TE-E2E-027-validate-broken-links-detected/test-case.md) | ✅ Passed | 2026-06-12 | 2026-06-12 | ✅ Audit Approved | [TE-TAR-055](../../audits/e2e/audit-report-te-e2e-027-test-case.md) |  |
| TE-E2E-028 | WF-009 | 0.1.1, 2.1.1, 6.1.1 | E2E Case | [TE-E2E-028-validate-ignore-rules-suppress](../../e2e-acceptance-testing/link-health-audit-broken-link-report/templates/TE-E2E-028-validate-ignore-rules-suppress/test-case.md) | ✅ Passed | 2026-06-12 | 2026-06-12 | ✅ Audit Approved | [TE-TAR-056](../../audits/e2e/audit-report-te-e2e-028-test-case.md) |  |
---

## Process Instructions

### Status Transitions

1. **⬜ Not Created** → **📋 Needs Execution** (when E2E acceptance test case is written)
2. **📋 Needs Execution** → **✅ Passed** (when first execution passes)
3. **📋 Needs Execution** → **🔴 Failed** (when first execution fails)
4. **✅ Passed** → **🔄 Needs Re-execution** (when code changes invalidate the result)
5. **🔴 Failed** → **🔄 Needs Re-execution** (when code changes invalidate the result)
6. **🔄 Needs Re-execution** → **✅ Passed** (when re-execution passes)
7. **🔄 Needs Re-execution** → **🔴 Failed** (when re-execution fails)

### Adding E2E Acceptance Test Cases

When creating new E2E acceptance test cases:
1. Create test case using the E2E Acceptance Test Case Creation task (PF-TSK-069)
2. Add entry to this file with Test Type "E2E Case" or "E2E Group" and status "📋 Needs Execution"
3. Set Last Executed to "—" (not yet executed)
4. Update [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) Test Status if needed

### Workflow Integration

This file is updated by the following tasks:
- **E2E Acceptance Test Case Creation** (PF-TSK-069): Adds E2E acceptance test case/group entries
- **E2E Acceptance Test Execution** (PF-TSK-070): Updates E2E acceptance test execution status and dates
- **[Update-TestExecutionStatus.ps1](../../../process-framework/scripts/test/e2e-acceptance-testing/Update-TestExecutionStatus.ps1)**: Automates status updates after test execution
- **[New-E2EAcceptanceTestCase.ps1](../../../process-framework/scripts/file-creation/03-testing/New-E2EAcceptanceTestCase.ps1)**: Automates entry creation for new test cases
