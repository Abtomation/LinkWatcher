---
id: PF-TSK-086
type: Process Framework
category: Task Definition
version: 1.1
created: 2026-04-12
updated: 2026-04-13
---

# Performance & E2E Test Scoping

## Purpose & Context

Systematically identify which performance tests and E2E acceptance tests are needed for a specific feature after it passes code review. This task closes the workflow gap between Code Review and Completed by ensuring test needs are explicitly evaluated — not left to ad-hoc judgment or forgotten entirely.

The task uses a decision matrix (in the scoping guide) to determine performance test levels, and evaluates E2E needs by checking both tracked workflows in user-workflow-tracking.md and discovering untracked cross-feature interactions from the feature's dependencies and integration points. When untracked E2E-worthy scenarios are found, they are added to user-workflow-tracking.md first — keeping it as the single source of truth — then evaluated for milestone readiness. Outputs go to existing tracking files — no new document types are created.

## AI Agent Role

**Role**: Test Strategist
**Mindset**: Systematic, evidence-based, completeness-oriented
**Focus Areas**: Performance impact analysis, cross-feature dependency awareness, test coverage gap identification
**Communication Style**: Present clear rationale for each scoping decision; distinguish between "no tests needed" (with documented rationale) and "tests needed" (with specific entries); ask about non-obvious performance implications

## When to Use

- When a feature has status `🔎 Needs Test Scoping` in [feature-tracking.md](/doc/state-tracking/permanent/feature-tracking.md) (set by Code Review upon passing)
- After code review passes for any feature — this is the mandatory next step before `🟢 Completed`
- When retroactively scoping test needs for features that were completed before this task existed

## Context Requirements

[View Context Map for this task](../../visualization/context-maps/03-testing/performance-e2e-test-scoping-map.md)

- **Critical (Must Read):**

  - [Feature implementation state file](/doc/state-tracking/features) - The specific feature's state file to understand what code was changed and which modules were affected
  - [Performance & E2E Test Scoping Guide](/process-framework/guides/03-testing/performance-e2e-test-scoping-guide.md) - Decision matrix for performance test levels, E2E milestone evaluation process, and worked examples
  - [Feature Tracking](/doc/state-tracking/permanent/feature-tracking.md) - To identify features at `🔎 Needs Test Scoping` status
  - [Visual Notation Guide](/process-framework/guides/support/visual-notation-guide.md) - For interpreting context map diagrams

- **Important (Load If Space):**

  - [User Workflow Tracking](/doc/state-tracking/permanent/user-workflow-tracking.md) - Workflow-to-feature mappings for E2E milestone evaluation
  - [Feature Dependencies](/doc/technical/architecture/feature-dependencies.md) - Understanding which features depend on the scoped feature
  - [Performance Test Tracking](/test/state-tracking/permanent/performance-test-tracking.md) - Existing performance tests to avoid duplicates
  - [E2E Test Tracking](/test/state-tracking/permanent/e2e-test-tracking.md) - Existing E2E tests to avoid duplicates

- **Reference Only (Access When Needed):**
  - [Performance Testing Guide](/process-framework/guides/03-testing/performance-testing-guide.md) - 4-level methodology, baseline management, and trend analysis (the "how to test" companion)
  - [Test Specifications](/test/specifications/feature-specs) - Existing test specifications for the feature
  - [Process Framework Task Registry — Trigger & Output](/process-framework/infrastructure/process-framework-task-registry.md) - Verifying this task's position in the trigger chain (`🔗 TRIGGER & OUTPUT` blocks and State File Trigger Index)

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished! 🚨**
>
> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

### Phase 1: Context Gathering

1. **Select feature**: Read [feature-tracking.md](/doc/state-tracking/permanent/feature-tracking.md) and identify the next feature at `🔎 Needs Test Scoping` status
2. **Read feature state file**: Load the feature's implementation state file from `/doc/state-tracking/features/` to understand:
   - Which source files were created or modified
   - Which modules/subsystems were affected
   - What type of changes were made (new parser, database change, algorithm change, configuration, UI, etc.)
3. **Read feature dependencies**: Check [feature-dependencies.md](/doc/technical/architecture/feature-dependencies.md) to understand which other features depend on or are depended upon by this feature
4. **🚨 CHECKPOINT**: Present feature selection and summary of code changes to human partner before proceeding with scoping

### Phase 2: Performance Test Scoping

5. **Apply decision matrix**: Consult the [Performance & E2E Test Scoping Guide](/process-framework/guides/03-testing/performance-e2e-test-scoping-guide.md) decision matrix against the feature's code changes. For each question in the matrix:
   - Identify whether the feature's changes match the trigger condition
   - If yes, note the recommended performance test level(s)
   - Document the specific code change that triggers the recommendation
6. **Check existing coverage**: Read [performance-test-tracking.md](/test/state-tracking/permanent/performance-test-tracking.md) to verify no existing tests already cover the identified needs
7. **Record performance scoping decision**:
   - **If performance tests needed**: Use the automation script to add entries:
     ```bash
     pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/03-testing/New-PerformanceTestEntry.ps1 -Level <1-4> -Operation "<description>" -RelatedFeatures "<feature IDs>" -Tolerance "<threshold>" -Rationale "<decision matrix trigger>"
     ```
     The script auto-assigns test IDs (BM-xxx or PH-xxx), inserts into the correct level section with status `⬜ Specified`, and updates the Summary table.
   - **If no performance tests needed**: Document rationale in the checkpoint summary (e.g., "Feature only adds configuration options, no hot-path changes")

### Phase 3: E2E Test Scoping

8. **Check tracked workflow participation**: Read [user-workflow-tracking.md](/doc/state-tracking/permanent/user-workflow-tracking.md) to determine which tracked user workflows this feature participates in
9. **Discover untracked cross-feature interactions**: Using the feature's dependencies (from Step 3) and integration points (from Step 2), identify any cross-feature scenarios that would benefit from E2E testing but are **not yet tracked** in user-workflow-tracking.md. Common indicators:
   - The feature introduces a new interaction path between two or more features (e.g., a new parser path that feeds differently into the updater)
   - The feature changes an interface that other features depend on
   - The feature creates a new user-facing capability that spans multiple modules
   If untracked scenarios are found: **add them to [user-workflow-tracking.md](/doc/state-tracking/permanent/user-workflow-tracking.md) first** using the automation script, then proceed with evaluation:
     ```bash
     pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/03-testing/New-WorkflowEntry.ps1 -Workflow "<name>" -UserAction "<user action>" -RequiredFeatures "<feature IDs>" -Priority "<P1-P4>" -Description "<one-paragraph description>"
     ```
     This keeps user-workflow-tracking.md as the single source of truth for all E2E-worthy scenarios.
10. **Evaluate E2E milestone readiness**: For each workflow this feature participates in (both previously tracked and newly added), check if completing this feature makes the workflow E2E-ready (all required features at `🔎 Needs Test Scoping` or `🟢 Completed`)
11. **Record E2E scoping decision**:
    - **If workflow now E2E-ready**: Add milestone entry using the automation script:
      ```bash
      pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/03-testing/New-E2EMilestoneEntry.ps1 -WorkflowId "<WF-xxx>"
      ```
      The script validates the workflow exists, reads its description and features, counts ready features, and inserts into the Workflow Milestone Tracking table.
    - **If not yet E2E-ready**: Document which features are still pending for each relevant workflow
    - **If no cross-feature interactions found**: Document "No cross-feature E2E scenarios identified" with rationale

### Phase 4: Finalization

12. **🚨 CHECKPOINT**: Present complete scoping results to human partner:
    - Performance test decisions (needed/not needed, with rationale for each)
    - E2E test decisions (workflow readiness evaluation, with rationale)
    - Any newly added workflows in user-workflow-tracking.md (from Step 9)
    - Proposed entries for tracking files
13. **Update feature status**: Set the feature's status to `🟢 Completed`:
    ```bash
    pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/update/Update-BatchFeatureStatus.ps1 -FeatureIds "<X.Y.Z>" -Status "🟢 Completed" -UpdateType "StatusOnly" -Force
    ```
14. **Update workflow statuses**: Run the workflow tracking sync to propagate the status change:
    ```bash
    pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/update/Update-WorkflowTracking.ps1
    ```
15. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Outputs

- **Performance scoping decision** — Either new rows in [performance-test-tracking.md](/test/state-tracking/permanent/performance-test-tracking.md) (status `⬜ Specified`) or documented rationale for "no performance tests needed"
- **E2E scoping decision** — Either new/updated entries in [e2e-test-tracking.md](/test/state-tracking/permanent/e2e-test-tracking.md) or documented rationale for "no E2E scenarios identified"
- **Newly discovered workflows** — Any cross-feature interactions added to [user-workflow-tracking.md](/doc/state-tracking/permanent/user-workflow-tracking.md) that were not previously tracked (if any)
- **Updated feature status** — Feature moved from `🔎 Needs Test Scoping` to `🟢 Completed` in [feature-tracking.md](/doc/state-tracking/permanent/feature-tracking.md)
- **Updated workflow status** — [user-workflow-tracking.md](/doc/state-tracking/permanent/user-workflow-tracking.md) updated if feature completion changes workflow readiness

## State Tracking

The following state files must be updated as part of this task:

- [Feature Tracking](/doc/state-tracking/permanent/feature-tracking.md) - Update feature status from `🔎 Needs Test Scoping` to `🟢 Completed`
- [Performance Test Tracking](/test/state-tracking/permanent/performance-test-tracking.md) - Add rows for identified performance test needs (if any)
- [E2E Test Tracking](/test/state-tracking/permanent/e2e-test-tracking.md) - Add/update entries for E2E-ready workflows (if any)
- [User Workflow Tracking](/doc/state-tracking/permanent/user-workflow-tracking.md) - Update workflow status if feature completion changes readiness

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

Before considering this task finished:

- [ ] **Verify Scoping Completeness**: Confirm all scoping decisions are documented
  - [ ] Performance decision matrix fully evaluated against feature's code changes
  - [ ] Untracked cross-feature interactions evaluated; any discovered scenarios added to user-workflow-tracking.md
  - [ ] E2E milestone readiness evaluated for all relevant workflows (including newly added)
  - [ ] Each decision (test needed / not needed) has documented rationale
  - [ ] No duplicate entries created in tracking files
- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] Performance test entries added to [performance-test-tracking.md](/test/state-tracking/permanent/performance-test-tracking.md) (if needed) with status `⬜ Specified`
  - [ ] E2E test entries added to [e2e-test-tracking.md](/test/state-tracking/permanent/e2e-test-tracking.md) (if needed)
  - [ ] Rationale documented for any "no tests needed" decisions
- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] [Feature Tracking](/doc/state-tracking/permanent/feature-tracking.md) shows `🟢 Completed` for the scoped feature
  - [ ] [User Workflow Tracking](/doc/state-tracking/permanent/user-workflow-tracking.md) updated if applicable
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Guide](../../guides/framework/feedback-form-guide.md) for each tool used, using task ID "PF-TSK-086" and context "Performance & E2E Test Scoping"

## Next Tasks

- [**Performance Test Creation (PF-TSK-084)**](/process-framework/tasks/03-testing/performance-test-creation-task.md) - If performance tests were identified, implement them from the `⬜ Specified` entries in performance-test-tracking.md. Full downstream lifecycle: `⬜ Specified → 📋 Created → 🔍 Audit Approved → ✅ Baselined`
- [**E2E Acceptance Test Case Creation (PF-TSK-069)**](/process-framework/tasks/03-testing/e2e-acceptance-test-case-creation-task.md) - If E2E tests were identified for newly E2E-ready workflows. Full downstream lifecycle: `📋 Case Created → 🔍 Audit Approved → ✅ Passed`
- [**Release & Deployment (PF-TSK-018)**](/process-framework/tasks/07-deployment/release-deployment-task.md) - If no tests are needed and the feature is ready for release

> **Audit gate**: Both performance tests and E2E test cases must pass [Test Audit (PF-TSK-030)](/process-framework/tasks/03-testing/test-audit-task.md) before proceeding to baseline capture or execution respectively. The audit step is mandatory for newly created tests — see each downstream task's prerequisites for details.

## Related Resources

- [Performance Testing Guide](/process-framework/guides/03-testing/performance-testing-guide.md) - 4-level methodology, baseline management, trend analysis (the "how to test" companion to this task's "when to test" scope)
- [Performance & E2E Test Scoping Guide](/process-framework/guides/03-testing/performance-e2e-test-scoping-guide.md) - Decision matrix and worked examples for this task
- [Test Infrastructure Guide](/process-framework/guides/03-testing/test-infrastructure-guide.md) - How the test/ directory connects to the process framework
- [Definition of Done](/process-framework/guides/04-implementation/definition-of-done.md) - Performance section (Section 8)
- [Development Dimensions Guide](/process-framework/guides/framework/development-dimensions-guide.md) - PE dimension definition
