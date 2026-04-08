---
id: TE-STA-002
type: Process Framework
category: State File
version: 1.0
created: 2026-03-25
updated: 2026-04-07
tracking_scope: E2E Acceptance Test Tracking
state_type: Implementation Status
---
# E2E Acceptance Test Tracking

E2E acceptance tests validate user-facing workflows that span multiple features. They require a running LinkWatcher instance and simulate real user actions. See [User Workflow Tracking](/doc/state-tracking/permanent/user-workflow-tracking.md) for workflow definitions and [Cross-Cutting E2E Spec (PF-TSP-044)](/test/specifications/cross-cutting-specs/cross-cutting-spec-e2e-acceptance-testing-scenarios.md) for scenario details.

> **Split from**: [test-tracking.md](test-tracking.md) (PF-IMP-210) — E2E section was the scalability bottleneck.

## Status Legend

| Status | Description |
|--------|-------------|
| 📋 **Case Created** | E2E acceptance test case exists but has never been executed |
| ✅ **Passed** | Last execution passed |
| 🔴 **Failed** | Last execution failed |
| 🔄 **Needs Re-execution** | Code changes invalidated the last result |
| ⬜ **Not Created** | E2E acceptance test case needed but not yet created |

## Workflow Milestone Tracking

| Workflow | Description | Required Features | Features Ready | E2E Spec | E2E Cases | Status |
|----------|-------------|------------------|----------------|----------|-----------|--------|
| WF-001 | Single file move → links updated | 1.1.1, 2.1.1, 2.2.1 | 3/3 | [PF-TSP-044](/test/specifications/cross-cutting-specs/cross-cutting-spec-e2e-acceptance-testing-scenarios.md) | TE-E2G-001, TE-E2G-002, TE-E2G-003, TE-E2G-004 | 🔄 Re-execution Needed |
| WF-002 | Directory move → contained refs updated | 1.1.1, 0.1.2, 2.1.1, 2.2.1 | 4/4 | [PF-TSP-044](/test/specifications/cross-cutting-specs/cross-cutting-spec-e2e-acceptance-testing-scenarios.md) | TE-E2G-005 | 🔄 Re-execution Needed |
| WF-003 | Startup → initial project scan | 0.1.1, 0.1.3, 0.1.2, 2.1.1, 1.1.1, 3.1.1 | 6/6 | [PF-TSP-044](/test/specifications/cross-cutting-specs/cross-cutting-spec-e2e-acceptance-testing-scenarios.md) | TE-E2G-006 | 🔄 Re-execution Needed |
| WF-004 | Rapid sequential moves → consistency | 1.1.1, 0.1.2, 2.2.1 | 3/3 | [PF-TSP-044](/test/specifications/cross-cutting-specs/cross-cutting-spec-e2e-acceptance-testing-scenarios.md) | TE-E2G-007 | ✅ Covered |
| WF-005 | Multi-format file move | 2.1.1, 2.2.1, 1.1.1 | 3/3 | [PF-TSP-044](/test/specifications/cross-cutting-specs/cross-cutting-spec-e2e-acceptance-testing-scenarios.md) | TE-E2G-008 | 🔄 Re-execution Needed |
| WF-007 | Dry-run mode → preview | 0.1.3, 0.1.1, 2.2.1, 3.1.1 | 4/4 | [PF-TSP-044](/test/specifications/cross-cutting-specs/cross-cutting-spec-e2e-acceptance-testing-scenarios.md) | TE-E2G-009 | ✅ Covered |
| WF-008 | Graceful shutdown → no corruption | 0.1.1, 2.2.1, 0.1.2 | 3/3 | [PF-TSP-044](/test/specifications/cross-cutting-specs/cross-cutting-spec-e2e-acceptance-testing-scenarios.md) | TE-E2G-010 | ✅ Covered |

## E2E Test Cases

| Test ID | Workflow | Feature IDs | Test Type | Test File/Case | Status | Last Executed | Last Updated | Notes |
|---------|----------|-------------|-----------|----------------|--------|---------------|--------------|-------|
| TE-E2G-001 | WF-001 | 1.1.1, 2.1.1, 2.2.1 | E2E Group | [master-test-powershell-regex-preservation.md](../../e2e-acceptance-testing/templates/powershell-regex-preservation/master-test-powershell-regex-preservation.md) | 🔄 Needs Re-execution | 2026-04-07 | 2026-04-07 | PD-BUG-033: Regex preservation on file move |
| TE-E2E-001 | WF-001 | 1.1.1, 2.1.1, 2.2.1 | E2E Case | [TE-E2E-001-regex-preserved-on-file-move](../../e2e-acceptance-testing/templates/powershell-regex-preservation/TE-E2E-001-regex-preserved-on-file-move/test-case.md) | 🔄 Needs Re-execution | 2026-04-07 | 2026-04-07 | Verify regex patterns not rewritten, real paths updated |
| TE-E2G-002 | WF-001 | 1.1.1, 2.1.1, 2.2.1 | E2E Group | [master-test-powershell-parser-patterns.md](../../e2e-acceptance-testing/templates/powershell-parser-patterns/master-test-powershell-parser-patterns.md) | 🔄 Needs Re-execution | 2026-04-07 | 2026-04-07 | Fixture paths fixed + PS parser enhanced |
| TE-E2E-002 | WF-001 | 1.1.1, 2.1.1, 2.2.1 | E2E Case | [TE-E2E-002-powershell-md-file-move](../../e2e-acceptance-testing/templates/powershell-parser-patterns/TE-E2E-002-powershell-md-file-move/test-case.md) | 🔄 Needs Re-execution | 2026-04-07 | 2026-04-07 | Fixture paths fixed + PS parser enhanced |
| TE-E2E-003 | WF-001 | 1.1.1, 2.1.1, 2.2.1 | E2E Case | [TE-E2E-003-powershell-script-file-move](../../e2e-acceptance-testing/templates/powershell-parser-patterns/TE-E2E-003-powershell-script-file-move/test-case.md) | 🔄 Needs Re-execution | 2026-04-07 | 2026-04-07 | Fixture paths fixed + PS parser enhanced |
| TE-E2G-003 | WF-001 | 1.1.1, 2.1.1, 2.2.1 | E2E Group | [master-test-markdown-parser-scenarios.md](../../e2e-acceptance-testing/templates/markdown-parser-scenarios/master-test-markdown-parser-scenarios.md) | 🔄 Needs Re-execution | 2026-04-07 | 2026-04-07 | Expected file corrected + Verify script fixes |
| TE-E2E-004 | WF-001 | 1.1.1, 2.1.1, 2.2.1 | E2E Case | [TE-E2E-004-markdown-link-update-on-file-move](../../e2e-acceptance-testing/templates/markdown-parser-scenarios/TE-E2E-004-markdown-link-update-on-file-move/test-case.md) | 🔄 Needs Re-execution | 2026-04-07 | 2026-04-07 | Expected file corrected (prose text not a link) |
| TE-E2G-004 | WF-001 | 1.1.1, 2.1.1, 2.2.1 | E2E Group | [master-test-yaml-json-python-parser-scenarios.md](../../e2e-acceptance-testing/templates/yaml-json-python-parser-scenarios/master-test-yaml-json-python-parser-scenarios.md) | 🔄 Needs Re-execution | 2026-04-07 | 2026-04-07 | YAML, JSON, Python parser scenarios |
| TE-E2E-005 | WF-001 | 1.1.1, 2.1.1, 2.2.1 | E2E Case | [TE-E2E-005-yaml-link-update-on-file-move](../../e2e-acceptance-testing/templates/yaml-json-python-parser-scenarios/TE-E2E-005-yaml-link-update-on-file-move/test-case.md) | 🔄 Needs Re-execution | 2026-04-07 | 2026-04-07 | PD-BUG-046 fix verified — .conf move detected, YAML refs updated |
| TE-E2E-006 | WF-001 | 1.1.1, 2.1.1, 2.2.1 | E2E Case | [TE-E2E-006-json-link-update-on-file-move](../../e2e-acceptance-testing/templates/yaml-json-python-parser-scenarios/TE-E2E-006-json-link-update-on-file-move/test-case.md) | 🔄 Needs Re-execution | 2026-04-07 | 2026-04-07 | JSON link update on file move |
| TE-E2E-007 | WF-001 | 1.1.1, 2.1.1, 2.2.1 | E2E Case | [TE-E2E-007-python-import-update-on-file-move](../../e2e-acceptance-testing/templates/yaml-json-python-parser-scenarios/TE-E2E-007-python-import-update-on-file-move/test-case.md) | 🔄 Needs Re-execution | 2026-04-07 | 2026-04-07 | Python import update on file move |
| TE-E2G-005 | WF-001, WF-002 | 1.1.1, 0.1.2, 2.1.1, 2.2.1 | E2E Group | [master-test-runtime-dynamic-operations.md](../../e2e-acceptance-testing/templates/runtime-dynamic-operations/master-test-runtime-dynamic-operations.md) | 🔄 Needs Re-execution | 2026-04-07 | 2026-04-07 | Runtime dynamic operations: file/directory create, move, rename |
| TE-E2E-008 | WF-001 | 1.1.1, 2.1.1, 2.2.1 | E2E Case | [TE-E2E-008-file-create-and-move](../../e2e-acceptance-testing/templates/runtime-dynamic-operations/TE-E2E-008-file-create-and-move/test-case.md) | 🔄 Needs Re-execution | 2026-04-07 | 2026-04-07 | File create and move |
| TE-E2E-009 | WF-002 | 1.1.1, 0.1.2, 2.1.1, 2.2.1 | E2E Case | [TE-E2E-009-directory-create-and-move](../../e2e-acceptance-testing/templates/runtime-dynamic-operations/TE-E2E-009-directory-create-and-move/test-case.md) | 🔄 Needs Re-execution | 2026-04-07 | 2026-04-07 | Directory create and move |
| TE-E2E-010 | WF-001 | 1.1.1, 2.1.1, 2.2.1 | E2E Case | [TE-E2E-010-file-create-and-rename](../../e2e-acceptance-testing/templates/runtime-dynamic-operations/TE-E2E-010-file-create-and-rename/test-case.md) | 🔄 Needs Re-execution | 2026-04-07 | 2026-04-07 | File create and rename |
| TE-E2E-011 | WF-002 | 1.1.1, 0.1.2, 2.1.1, 2.2.1 | E2E Case | [TE-E2E-011-directory-create-and-rename](../../e2e-acceptance-testing/templates/runtime-dynamic-operations/TE-E2E-011-directory-create-and-rename/test-case.md) | 🔄 Needs Re-execution | 2026-04-07 | 2026-04-07 | Directory create and rename |
| TE-E2E-013 | WF-002 | 1.1.1, 0.1.2, 2.1.1, 2.2.1 | E2E Case | [TE-E2E-013-nested-directory-move](../../e2e-acceptance-testing/templates/runtime-dynamic-operations/TE-E2E-013-nested-directory-move/test-case.md) | 🔄 Needs Re-execution | 2026-04-07 | 2026-04-07 | Nested directory move |
| TE-E2E-014 | WF-002 | 1.1.1, 0.1.2, 2.1.1, 2.2.1 | E2E Case | [TE-E2E-014-directory-move-internal-refs](../../e2e-acceptance-testing/templates/runtime-dynamic-operations/TE-E2E-014-directory-move-internal-refs/test-case.md) | 🔄 Needs Re-execution | 2026-04-07 | 2026-04-07 | Directory move — internal references preserved |
| TE-E2G-006 | WF-003 | 0.1.1, 0.1.2, 0.1.3, 1.1.1, 2.1.1, 2.2.1 | E2E Group | [master-test-startup-operations.md](../../e2e-acceptance-testing/templates/startup-operations/master-test-startup-operations.md) | 🔄 Needs Re-execution | 2026-04-07 | 2026-04-07 | TE-E2E-012 still failing (PD-BUG-053); TE-E2E-015 passed |
| TE-E2E-012 | WF-003 | 0.1.1, 0.1.2, 0.1.3, 1.1.1, 2.1.1, 2.2.1 | E2E Case | [TE-E2E-012-file-operations-during-startup](../../e2e-acceptance-testing/templates/startup-operations/TE-E2E-012-file-operations-during-startup/test-case.md) | 🔄 Needs Re-execution | 2026-04-07 | 2026-04-07 | PD-BUG-053 (reopened): move event arrives before link DB indexed referencing files |
| TE-E2E-015 | WF-003 | 0.1.1, 0.1.3, 0.1.2, 2.1.1, 1.1.1 | E2E Case | [TE-E2E-015-startup-custom-config-excludes](../../e2e-acceptance-testing/templates/startup-operations/TE-E2E-015-startup-custom-config-excludes/test-case.md) | 🔄 Needs Re-execution | 2026-04-07 | 2026-04-07 | Startup custom config excludes — passed |
| TE-E2G-007 | WF-004 | 1.1.1, 0.1.2, 2.2.1 | E2E Group | [master-test-rapid-sequential-moves.md](../../e2e-acceptance-testing/templates/rapid-sequential-moves/master-test-rapid-sequential-moves.md) | ✅ Passed | 2026-03-31 | 2026-03-31 | Rapid sequential moves: consistency under fast operations |
| TE-E2E-016 | WF-004 | 1.1.1, 0.1.2, 2.2.1 | E2E Case | [TE-E2E-016-two-files-moved-rapidly](../../e2e-acceptance-testing/templates/rapid-sequential-moves/TE-E2E-016-two-files-moved-rapidly/test-case.md) | ✅ Passed | 2026-03-31 | 2026-03-31 | Two files moved rapidly |
| TE-E2E-017 | WF-004 | 1.1.1, 0.1.2, 2.2.1 | E2E Case | [TE-E2E-017-move-file-then-referencing-file](../../e2e-acceptance-testing/templates/rapid-sequential-moves/TE-E2E-017-move-file-then-referencing-file/test-case.md) | ✅ Passed | 2026-03-31 | 2026-03-31 | Move file then move referencing file |
| TE-E2G-008 | WF-005 | 2.1.1, 2.2.1, 1.1.1 | E2E Group | [master-test-multi-format-references.md](../../e2e-acceptance-testing/templates/multi-format-references/master-test-multi-format-references.md) | 🔄 Needs Re-execution | 2026-04-07 | 2026-04-07 | Multi-format: single file move updates refs across all formats |
| TE-E2E-018 | WF-005 | 2.1.1, 2.2.1, 1.1.1 | E2E Case | [TE-E2E-018-file-referenced-from-all-formats](../../e2e-acceptance-testing/templates/multi-format-references/TE-E2E-018-file-referenced-from-all-formats/test-case.md) | 🔄 Needs Re-execution | 2026-04-07 | 2026-04-07 | File referenced from all formats |
| TE-E2G-009 | WF-007 | 0.1.3, 0.1.1, 2.2.1, 3.1.1 | E2E Group | [master-test-dry-run-mode.md](../../e2e-acceptance-testing/templates/dry-run-mode/master-test-dry-run-mode.md) | ✅ Passed | 2026-03-30 | 2026-03-30 | PD-BUG-048 fix verified |
| TE-E2E-019 | WF-007 | 0.1.3, 0.1.1, 2.2.1, 3.1.1 | E2E Case | [TE-E2E-019-move-file-dry-run-no-changes](../../e2e-acceptance-testing/templates/dry-run-mode/TE-E2E-019-move-file-dry-run-no-changes/test-case.md) | ✅ Passed | 2026-03-30 | 2026-03-30 | PD-BUG-048 fix verified — lw_flags passthrough working |
| TE-E2G-010 | WF-008 | 0.1.1, 2.2.1, 0.1.2 | E2E Group | [master-test-graceful-shutdown.md](../../e2e-acceptance-testing/templates/graceful-shutdown/master-test-graceful-shutdown.md) | ✅ Passed | 2026-03-23 | 2026-03-23 | Graceful shutdown: no corruption on Ctrl+C |
| TE-E2E-020 | WF-008 | 0.1.1, 2.2.1, 0.1.2 | E2E Case | [TE-E2E-020-stop-during-idle](../../e2e-acceptance-testing/templates/graceful-shutdown/TE-E2E-020-stop-during-idle/test-case.md) | ✅ Passed | 2026-03-23 | 2026-03-23 | Stop during idle |
| TE-E2E-021 | WF-008 | 0.1.1, 2.2.1, 0.1.2 | E2E Case | [TE-E2E-021-stop-immediately-after-move](../../e2e-acceptance-testing/templates/graceful-shutdown/TE-E2E-021-stop-immediately-after-move/test-case.md) | ✅ Passed | 2026-03-23 | 2026-03-23 | Stop immediately after file move |
| TE-E2G-011 | — | 0.1.1, 2.2.1, 3.1.1 | E2E Group | [master-test-error-recovery.md](../../e2e-acceptance-testing/templates/error-recovery/master-test-error-recovery.md) | ✅ Passed | 2026-03-23 | 2026-03-23 | Error recovery: read-only file handling |
| TE-E2E-022 | — | 0.1.1, 2.2.1, 3.1.1 | E2E Case | [TE-E2E-022-read-only-referencing-file](../../e2e-acceptance-testing/templates/error-recovery/TE-E2E-022-read-only-referencing-file/test-case.md) | ✅ Passed | 2026-03-23 | 2026-03-23 | Read-only referencing file |

---

## Process Instructions

### Status Transitions

1. **⬜ Not Created** → **📋 Case Created** (when E2E acceptance test case is written)
2. **📋 Case Created** → **✅ Passed** (when first execution passes)
3. **📋 Case Created** → **🔴 Failed** (when first execution fails)
4. **✅ Passed** → **🔄 Needs Re-execution** (when code changes invalidate the result)
5. **🔴 Failed** → **🔄 Needs Re-execution** (when code changes invalidate the result)
6. **🔄 Needs Re-execution** → **✅ Passed** (when re-execution passes)
7. **🔄 Needs Re-execution** → **🔴 Failed** (when re-execution fails)

### Adding E2E Acceptance Test Cases

When creating new E2E acceptance test cases:
1. Create test case using the E2E Acceptance Test Case Creation task (PF-TSK-069)
2. Add entry to this file with Test Type "E2E Case" or "E2E Group" and status "📋 Case Created"
3. Set Last Executed to "—" (not yet executed)
4. Update [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) Test Status if needed

### Workflow Integration

This file is updated by the following tasks:
- **E2E Acceptance Test Case Creation** (PF-TSK-069): Adds E2E acceptance test case/group entries
- **E2E Acceptance Test Execution** (PF-TSK-070): Updates E2E acceptance test execution status and dates
- **[Update-TestExecutionStatus.ps1](../../../process-framework/scripts/test/e2e-acceptance-testing/Update-TestExecutionStatus.ps1)**: Automates status updates after test execution
- **[New-E2EAcceptanceTestCase.ps1](../../../process-framework/scripts/file-creation/03-testing/New-E2EAcceptanceTestCase.ps1)**: Automates entry creation for new test cases
