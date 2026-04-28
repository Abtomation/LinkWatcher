---
id: TE-STA-002
type: Process Framework
category: State File
version: 1.0
created: [DATE]
updated: [DATE]
tracking_scope: E2E Acceptance Test Tracking
state_type: Implementation Status
---
# E2E Acceptance Test Tracking

E2E acceptance tests validate user-facing workflows that span multiple features. They require a running application instance and simulate real user actions. See [User Workflow Tracking](/doc/state-tracking/permanent/user-workflow-tracking.md) for workflow definitions.

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

## E2E Acceptance Test Cases

<!-- Convention: Groups (TE-E2G-*) act as parent headers. Cases (TE-E2E-*) listed immediately after a group belong to that group. There is no explicit parent column — the relationship is positional. -->
<!-- Add test case rows as workflows are implemented -->
