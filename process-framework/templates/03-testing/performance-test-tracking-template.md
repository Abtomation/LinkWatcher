---
id: TE-STA-003
type: Process Framework
category: State File
version: 1.0
created: [DATE]
updated: [DATE]
tracking_scope: Performance Test Tracking
state_type: Implementation Status
---
# Performance Test Tracking

> **Purpose**: Single source of truth for all performance tests in the [PROJECT_NAME] project — registry, baselines, lifecycle status, and related features.
>
> **Lifecycle**: ⬜ Needs Creation → 📋 Needs Baseline → ✅ Baselined → ⚠️ Needs Re-baseline
>
> **Related**: [Performance Testing Guide](/process-framework/guides/03-testing/performance-testing-guide.md) | [Results Database](/process-framework/scripts/test/performance_db.py)

## Status Legend

### Lifecycle Status

| Symbol | Status              | Description                                                                          | Next Task  |
| ------ | ------------------- | ------------------------------------------------------------------------------------ | ---------- |
| ⬜     | Needs Creation      | Test specified by scoping task, needs implementation                                 | PF-TSK-084 |
| 📋     | Needs Baseline      | Test created, needs audit (separate Audit Status column) then baseline capture       | PF-TSK-085 |
| ✅     | Baselined           | Baseline captured, stable — monitoring for regressions                               | —          |
| ⚠️     | Needs Re-baseline   | Baseline is stale due to code changes, needs re-capture                              | PF-TSK-085 |

### Audit Status

Tracked per-test in the **Audit Status** column. Set by [Test Audit (PF-TSK-030)](/process-framework/tasks/03-testing/test-audit-task.md) with `-TestType Performance`.

| Symbol | Status              | Description                                                                          |
| ------ | ------------------- | ------------------------------------------------------------------------------------ |
| 🔍     | Audit Approved      | All audit criteria pass — test is ready for baseline capture                        |
| 🔄     | Needs Update        | Test has methodology, tolerance, or measurement issues that need fixing before baseline capture |
| 🔴     | Audit Failed        | Fundamental methodology or measurement issues                                        |
| —      | _(not yet audited)_ | Test has not undergone audit. **Only valid** when Lifecycle Status is `📋 Needs Baseline`. A `✅ Baselined` row with `Audit Status = —` is a compliance hole (e.g., pre-gate migration) and needs retroactive audit. |

> **Audit gate**: Tests in `📋 Needs Baseline` status must reach `✅ Audit Approved` in the Audit Status column before baseline capture. The audit gate enforces a one-way flow: Lifecycle Status `✅ Baselined` implies an approved audit.

## Test Inventory

### Component Benchmarks (Level 1)

| Test ID | Operation | Related Features | Status | Baseline | Tolerance | Last Result | Last Run | Test File | Audit Status | Audit Report | Spec Ref |
|---------|-----------|-----------------|--------|----------|-----------|-------------|----------|-----------|--------------|--------------|----------|

### Operation Benchmarks (Level 2)

| Test ID | Operation | Related Features | Status | Baseline | Tolerance | Last Result | Last Run | Test File | Audit Status | Audit Report | Spec Ref |
|---------|-----------|-----------------|--------|----------|-----------|-------------|----------|-----------|--------------|--------------|----------|

### Scale Tests (Level 3)

| Test ID | Operation | Related Features | Status | Baseline | Tolerance | Last Result | Last Run | Test File | Audit Status | Audit Report | Spec Ref |
|---------|-----------|-----------------|--------|----------|-----------|-------------|----------|-----------|--------------|--------------|----------|

### Resource Bounds (Level 4)

| Test ID | Operation | Related Features | Status | Baseline | Tolerance | Last Result | Last Run | Test File | Audit Status | Audit Report | Spec Ref |
|---------|-----------|-----------------|--------|----------|-----------|-------------|----------|-----------|--------------|--------------|----------|

## Summary

| Level | Total | ✅ Baselined | 📋 Needs Baseline | ⬜ Needs Creation | ⚠️ Needs Re-baseline |
|-------|-------|-------------|-----------|-------------|----------|
| Component | 0 | 0 | 0 | 0 | 0 |
| Operation | 0 | 0 | 0 | 0 | 0 |
| Scale | 0 | 0 | 0 | 0 | 0 |
| Resource | 0 | 0 | 0 | 0 | 0 |
| **Total** | **0** | **0** | **0** | **0** | **0** |
