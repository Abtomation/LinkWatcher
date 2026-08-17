---
name: perf-e2e-scoping
description: >-
  Craft for scoping per-feature performance and E2E test needs well — the judgment half of the
  framework's Performance & E2E Test Scoping task (PF-TSK-086). Covers the performance test
  decision matrix (levels 1–4), tier-based defaults, identifying the project's hot-path
  components, E2E milestone-readiness evaluation (tracked workflows + untracked cross-feature
  interaction discovery), recording conventions for tracking entries, documented "no tests needed"
  rationale, and edge cases; worked examples in a reference. Activated from the Performance & E2E
  Test Scoping task's Check-Recommended-Skills step (via recommended_skills); owns "when to test",
  not "how to test" (performance methodology stays in the Performance Testing Guide) and not test
  creation or audit.
user-invocable: false
---

# Performance & E2E Test Scoping Craft

This skill owns the **craft** of the scoping judgment — *when* a feature needs performance tests
and *whether* its completion makes a user workflow E2E-ready. It is the craft home for the
**Performance & E2E Test Scoping task (PF-TSK-086)**, which owns everything else: task selection,
role, checkpoints, tracking-entry creation via scripts, status updates, and the feedback form.

> **Division of labor.** The task owns process; this skill owns craft. Do **not** run checkpoints
> or write tracking entries from this skill — those stay in the task. This skill drives the
> decision-matrix application and milestone evaluation between the task's checkpoints.
>
> **"When to test", not "how to test".** Performance methodology (test levels in depth, baselines,
> trends) is the
> [Performance Testing Guide](../../../process-framework/guides/03-testing/performance-testing-guide.md);
> E2E test-case customization is the `e2e-test-case-creation` craft.

## Reference-don't-bundle: framework scripts this craft uses

This skill bundles **no executables**. The **task** records decisions with
`process-framework/scripts/file-creation/03-testing/New-PerformanceTestEntry.ps1` (auto-assigns
BM-/PH- IDs, inserts `⬜ Needs Creation` rows), `New-WorkflowEntry.ps1` (adds discovered
workflows), and `New-E2EMilestoneEntry.ps1` (milestone rows).

## Performance Test Decision Matrix

Walk through each question in order. A feature may trigger multiple test levels.

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

### By feature tier

| Feature Tier | Default Performance Testing | Exceptions |
|-------------|---------------------------|-----------|
| Tier 1 (Simple) | Not required | Required if touching a hot-path component |
| Tier 2 (Medium) | PE dimension evaluation | Always when touching hot-path components |
| Tier 3 (Complex) | Included by default | Mandatory for all hot-path components |

### Identifying hot-path components

Hot-path components are the modules that process every core operation — derive the project's list
from its architecture documentation / source layout (typically parsers, core data stores,
per-event handlers, scan/pipeline stages). Changes to configuration, logging, CLI, or
documentation are **not** hot-path and typically don't need performance tests.

Example (a file-watcher product):

| Component | Module(s) | Why Hot Path |
|-----------|-----------|-------------|
| Parser registry/facade | `src/<product>/parsers` | Called for every monitored file |
| Link database | `src/<product>/database.py` | Queried on every file event |
| Link updater | `src/<product>/updater.py` | Runs on every detected move |
| Move detector | `src/<product>/handler.py` | Processes every filesystem event |
| File scanner | `src/<product>/service.py` (scan methods) | Initial scan touches all files |

## E2E milestone evaluation

Key concepts that drive the task's workflow-participation and readiness steps:

- **E2E-ready** = all features required for the workflow to function end-to-end are implemented
  and have passed code review (status `🔎 Needs Test Scoping` or `🟢 Completed`).
- **A feature can participate in multiple workflows** — evaluate each one independently.
- **E2E tests are workflow-scoped, not feature-scoped** — a single E2E test may exercise multiple
  features.
- **Untracked-interaction discovery**: from the feature's dependencies and integration points,
  look for E2E-worthy scenarios not yet in `user-workflow-tracking.md` — a new interaction path
  between features, a changed interface other features depend on, a new user-facing capability
  spanning multiple modules. Add discovered scenarios to `user-workflow-tracking.md` *first* (the
  single source of truth — every E2E test must trace back to a tracked workflow), then evaluate
  readiness.
- **When nothing applies**: document "No cross-feature E2E scenarios identified — feature operates
  independently within its module."

## Recording scoping decisions

- **Performance entries** (`performance-test-tracking.md`): Status `⬜ Needs Creation` · Test
  Level 1–4 per the matrix · Target = specific subsystem or operation · Feature = the triggering
  feature ID · Rationale = which matrix question fired.
- **E2E entries** (`e2e-test-tracking.md`): Workflow ID from `user-workflow-tracking.md` · status
  per tracking conventions · Trigger = "All features implemented — workflow now E2E-ready" ·
  Features = all features in the workflow.
- **"No tests needed"**: the rationale goes in the task's scoping-results checkpoint summary —
  name which matrix questions were evaluated and why none fired (e.g. "Feature only adds a new
  config option — no hot-path changes, no workflow completion").

## Edge cases

- **Feature touches multiple subsystems** — evaluate each subsystem independently through the
  matrix; one feature can yield multiple entries at different levels.
- **Existing tests already cover the area** — if `performance-test-tracking.md` already has a test
  for the affected subsystem at the relevant level, do not duplicate; note "Existing test BM-XXX
  covers this — verify no regression during next Baseline Capture."
- **Retrospective scoping** (features completed before this task existed) — same process, driven
  from the feature state file's record of what code changed; existing tests may already cover most
  needs, so focus on gap identification.

## Post-scoping lifecycle

Both output kinds pass a mandatory **audit gate** before baseline capture or execution:

- **Performance tests**: `⬜ Needs Creation` → `📋 Needs Baseline` (Performance Test Creation) →
  `✅ Audit Approved` (Test Audit, `-TestType Performance`) → `✅ Baselined` (Baseline Capture)
- **E2E test cases**: `📋 Needs Execution` (E2E Test Case Creation) → `✅ Audit Approved` (Test
  Audit, `-TestType E2E`) → `✅ Passed` (E2E Test Execution)

Re-executions (`⚠️ Needs Re-baseline` / `🔄 Needs Re-execution`) are exempt (already audited).

## Worked examples

Four end-to-end walkthroughs (parser enhancement → perf tests; config enhancement → none; feature
completes a workflow → E2E; feature doesn't complete any workflow → none):
[references/worked-examples.md](references/worked-examples.md).
