---
id: PF-GDE-061
type: Process Framework
category: Guide
version: 1.0
created: 2026-04-12
updated: 2026-04-12
related_task: PF-TSK-086
---

# Performance & E2E Test Scoping Guide

## Overview

This guide provides the decision matrix and evaluation process for the Performance & E2E Test Scoping task (PF-TSK-086). It answers two questions for each feature that passes code review:

1. **Does this feature need performance tests?** — Use the decision matrix
2. **Does this feature's completion make any user workflow E2E-ready?** — Use the E2E milestone evaluation

This guide owns "when to test." For "how to test," see the [Performance Testing Guide](/process-framework/guides/03-testing/performance-testing-guide.md) (test levels, baselines, trends) and the [E2E Acceptance Test Case Customization Guide](/process-framework/guides/03-testing/e2e-acceptance-test-case-customization-guide.md).

## When to Use

Consult this guide during execution of PF-TSK-086 (Performance & E2E Test Scoping), specifically:

- **Step 5**: When applying the performance decision matrix
- **Steps 8-9**: When evaluating E2E milestone readiness
- **Any time** you need to justify a "no tests needed" decision with documented rationale

## Table of Contents

1. [Performance Test Decision Matrix](#performance-test-decision-matrix)
2. [E2E Milestone Evaluation](#e2e-milestone-evaluation)
3. [Recording Scoping Decisions](#recording-scoping-decisions)
4. [Worked Examples](#worked-examples)
5. [Edge Cases](#edge-cases)
6. [Related Resources](#related-resources)

## Performance Test Decision Matrix

Walk through each question in order. A feature may trigger multiple test levels.

### Does This Feature Need Performance Tests?

```
Feature changes a parser or database module?
├─ Yes → Component benchmarks needed (Level 1)
│        Target: the specific parser or database operation affected
│
Feature changes an end-to-end operation pipeline?
├─ Yes → Operation benchmarks needed (Level 2)
│        Target: the affected operation (initial scan, move handling, validation)
│
Feature changes data structures, algorithms, or scaling characteristics?
├─ Yes → Scale tests needed (Level 3)
│        Target: the operation at extreme conditions (1000+ files, deep dirs)
│
Feature changes memory allocation, caching, or concurrency?
├─ Yes → Resource bounds needed (Level 4)
│        Target: memory/CPU under the affected operation
│
None of the above?
└─ No performance testing needed for this feature
    Document rationale: what the feature changes and why it doesn't affect hot paths
```

### By Feature Tier

| Feature Tier | Default Performance Testing | Exceptions |
|-------------|---------------------------|-----------|
| Tier 1 (Simple) | Not required | Required if touching a hot-path component |
| Tier 2 (Medium) | PE dimension evaluation | Always when touching parsers, updater, or handler |
| Tier 3 (Complex) | Included by default | Mandatory for all hot-path components |

### Identifying Hot-Path Components

For this project, the following are hot-path components (processing every file or link operation):

| Component | Module(s) | Why Hot Path |
|-----------|-----------|-------------|
| Parser registry/facade | `linkwatcher/parsers/` | Called for every monitored file |
| Link database | `linkwatcher/database.py` | Queried on every file event |
| Link updater | `linkwatcher/updater.py` | Runs on every detected move |
| Move detector | `linkwatcher/handler.py` | Processes every filesystem event |
| File scanner | `linkwatcher/service.py` (scan methods) | Initial scan touches all files |

Changes to configuration, logging, CLI, or documentation are **not** hot-path and typically don't need performance tests.

## E2E Milestone Evaluation

### Process

1. **Read [user-workflow-tracking.md](/doc/state-tracking/permanent/user-workflow-tracking.md)** to find all tracked workflows this feature participates in
2. **Discover untracked cross-feature interactions**: Using the feature's dependencies and integration points, check for E2E-worthy scenarios not yet in user-workflow-tracking.md:
   - Does the feature introduce a new interaction path between two or more features?
   - Does the feature change an interface that other features depend on?
   - Does the feature create a new user-facing capability spanning multiple modules?
   If yes: **add the new scenario to user-workflow-tracking.md first**, then continue evaluation. This keeps user-workflow-tracking.md as the single source of truth.
3. **For each relevant workflow** (previously tracked + newly added): Check if ALL required features are now at `🔎 Needs Test Scoping` or `🟢 Completed` status
4. **If a workflow is now fully implemented**: It is E2E-ready — add entries to e2e-test-tracking.md
5. **If a workflow is NOT fully implemented**: Document which features are still pending — no E2E entries yet

### Key Concepts

- **E2E-ready** means all features required for the workflow to function end-to-end are implemented and have passed code review
- **A feature can participate in multiple workflows** — evaluate each one independently
- **E2E tests are workflow-scoped, not feature-scoped** — a single E2E test may exercise multiple features
- **The scoping task feeds workflow tracking** — if a cross-feature scenario is discovered that isn't tracked, add it to user-workflow-tracking.md. Every E2E test must trace back to a tracked workflow.

### When No Interactions Apply

If a feature does not appear in any tracked workflow and no new cross-feature interactions are identified, document: "No cross-feature E2E scenarios identified — feature operates independently within its module."

## Recording Scoping Decisions

### Performance Test Entries

When adding rows to [performance-test-tracking.md](/test/state-tracking/permanent/performance-test-tracking.md):

| Field | Value |
|-------|-------|
| Status | `⬜ Specified` |
| Test Level | Level 1/2/3/4 per decision matrix |
| Target | Specific subsystem or operation |
| Feature | The feature ID that triggered this entry |
| Rationale | Why this test is needed (which decision matrix question was triggered) |

### E2E Test Entries

When adding entries to [e2e-test-tracking.md](/test/state-tracking/permanent/e2e-test-tracking.md):

| Field | Value |
|-------|-------|
| Workflow | The workflow ID from user-workflow-tracking.md |
| Status | Per tracking file conventions |
| Trigger | "All features implemented — workflow now E2E-ready" |
| Features | List of all features in the workflow |

### "No Tests Needed" Documentation

When no tests are needed, the rationale must be documented in the checkpoint summary (Step 11 of the task). Include:
- Which decision matrix questions were evaluated
- Why none were triggered (e.g., "Feature only adds a new config option — no hot-path changes, no workflow completion")

## Worked Examples

### Example 1: Parser Enhancement (Performance Tests Needed)

**Feature**: 2.1.1 Link Parsing System — adds backtick path detection to markdown parser

**Decision matrix walkthrough**:
- *Changes a parser or database module?* — **Yes**, modifies `linkwatcher/parsers/markdown_parser.py`. → **Level 1 Component benchmark needed** for markdown parser throughput
- *Changes an end-to-end operation pipeline?* — **Yes**, parsing is part of initial scan and file-move handling. → **Level 2 Operation benchmark** should be verified (regression check, not new test if one exists)
- *Changes data structures, algorithms, or scaling?* — No, same algorithm, new pattern match only
- *Changes memory allocation, caching, or concurrency?* — No

**Result**: Add one Level 1 entry to performance-test-tracking.md targeting markdown parser throughput. Verify existing Level 2 operation benchmark doesn't regress.

### Example 2: Configuration Enhancement (No Performance Tests Needed)

**Feature**: 0.1.3 Configuration System — adds new `validation_extensions` config option

**Decision matrix walkthrough**:
- *Changes a parser or database module?* — No, only `linkwatcher/config.py`
- *Changes an end-to-end operation pipeline?* — No, config loading happens once at startup
- *Changes data structures, algorithms, or scaling?* — No
- *Changes memory allocation, caching, or concurrency?* — No

**Result**: No performance tests needed. Rationale: "Feature adds a configuration option read once at startup — no hot-path impact."

### Example 3: Feature Completes a Workflow (E2E Tests Needed)

**Feature**: 6.1.1 Link Validation — the last feature needed for the "Link Health Audit" workflow

**E2E evaluation**:
1. Read user-workflow-tracking.md → 6.1.1 participates in "Link Health Audit" workflow
2. Check other features in workflow: 0.1.1 (Completed), 2.1.1 (Completed), 6.1.1 (now at Needs Test Scoping) → All features implemented
3. Workflow is now E2E-ready

**Result**: Add entry to e2e-test-tracking.md for "Link Health Audit" workflow with all three participating features listed.

### Example 4: Feature Doesn't Complete Any Workflow (No E2E Tests)

**Feature**: 3.1.1 Logging System — participates in "Operational Monitoring" workflow

**E2E evaluation**:
1. Read user-workflow-tracking.md → 3.1.1 participates in "Operational Monitoring" workflow
2. Check other features: feature X.Y.Z is still at `🟡 In Progress` → workflow NOT E2E-ready

**Result**: No E2E tests yet. Document: "Operational Monitoring workflow requires X.Y.Z which is still In Progress."

## Edge Cases

### Feature Touches Multiple Subsystems

Evaluate each subsystem independently through the decision matrix. A single feature can result in multiple performance test entries at different levels.

### Existing Performance Tests Already Cover the Area

If [performance-test-tracking.md](/test/state-tracking/permanent/performance-test-tracking.md) already has a test for the affected subsystem at the relevant level, do not add a duplicate. Instead, note: "Existing test BM-XXX covers this — verify no regression during next Baseline Capture."

### Retrospective Scoping (Pre-Existing Features)

For features that were marked Completed before this task existed, apply the same process. The feature state file still documents what code was changed. The key difference: existing performance tests may already cover most needs, so focus on gap identification.

## Post-Scoping Lifecycle

After scoping identifies test needs, the downstream lifecycle includes an **audit gate** before baseline capture or execution:

- **Performance tests**: `⬜ Specified → 📋 Created` (PF-TSK-084) → `🔍 Audit Approved` (PF-TSK-030, `-TestType Performance`) → `✅ Baselined` (PF-TSK-085)
- **E2E test cases**: `📋 Case Created` (PF-TSK-069) → `🔍 Audit Approved` (PF-TSK-030, `-TestType E2E`) → `✅ Passed` (PF-TSK-070)

The audit gate is mandatory for newly created tests. Re-executions (`⚠️ Stale` for performance, `🔄 Needs Re-execution` for E2E) are exempt.

## Related Resources

- [Performance Testing Guide](/process-framework/guides/03-testing/performance-testing-guide.md) - 4-level methodology, baseline management, trend analysis ("how to test")
- [Performance & E2E Test Scoping Task (PF-TSK-086)](/process-framework/tasks/03-testing/performance-and-e2e-test-scoping-task.md) - The task that uses this guide
- [Test Audit Task (PF-TSK-030)](/process-framework/tasks/03-testing/test-audit-task.md) - Audit gate for newly created performance and E2E tests
- [Performance Test Tracking](/test/state-tracking/permanent/performance-test-tracking.md) - Registry of all performance tests
- [E2E Test Tracking](/test/state-tracking/permanent/e2e-test-tracking.md) - Registry of all E2E acceptance tests
- [User Workflow Tracking](/doc/state-tracking/permanent/user-workflow-tracking.md) - Workflow-to-feature mappings
- [Feature Dependencies](/doc/technical/architecture/feature-dependencies.md) - Feature dependency graph
- [Definition of Done](/process-framework/guides/04-implementation/definition-of-done.md) - Performance section
