---
id: PF-TSK-065
type: Process Framework
category: Task Definition
domain: agnostic
version: 1.9
created: 2026-02-17
updated: 2026-04-05
---

# Codebase Feature Analysis

## Purpose & Context

For each feature with an implementation state file, analyze implementation patterns, dependencies, and design decisions. This enriches the feature documentation created during Codebase Feature Discovery (PF-TSK-064) with the detailed analysis needed for subsequent documentation creation.

This task produces enriched Feature Implementation State files that serve as the evidence base for tier assessment and design documentation in the next onboarding task.

## AI Agent Role

**Role**: Technical Documentation Specialist & Codebase Archaeologist
**Mindset**: Analytical, pattern-recognition focused, dependency-aware
**Focus Areas**: Implementation patterns, data flow analysis, dependency mapping, test coverage assessment
**Communication Style**: Report analysis findings, highlight cross-cutting patterns, ask about design rationale

## When to Use

- After [Codebase Feature Discovery (PF-TSK-064)](codebase-feature-discovery.md) is complete
- Master state file shows Phase 1 done (100% file coverage achieved)
- All features have Feature Implementation State files with code inventories
- Need to analyze patterns, dependencies, and design decisions before documentation creation

## Context Requirements

[View Context Map for this task](../../visualization/context-maps/00-setup/codebase-feature-analysis-map.md)

- **Critical (Must Read):**

  - [Retrospective Master State File](../../../process-framework-local/state-tracking/temporary/old/retrospective-master-state.md) — Read current state, verify Phase 1 complete
  - [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) - Feature list and current status
  - [Feature Implementation State Files](/doc/state-tracking/features) — All files created during PF-TSK-064
  - [Feature Implementation State Tracking Guide](../../guides/04-implementation/feature-implementation-state-tracking-guide.md) - Guide for populating analysis sections

- **Important (Load If Space):**
  - [Feature Tier Assessment Task](../01-planning/feature-tier-assessment-task.md) - Understanding what analysis feeds into tier assessment

- **Reference Only (Access When Needed):**
  - [Documentation Tiers README](../../../doc/documentation-tiers/README.md) - Understanding tier documentation requirements
  - [Feature Dependencies](../../../doc/technical/architecture/feature-dependencies.md) - Existing dependency documentation
  - [Test Query Tool](/process-framework/scripts/test/test_query.py) - Query test files by feature, priority, and markers
  - [Test Tracking](../../../test/state-tracking/permanent/test-tracking.md) - Test implementation status tracking

## Process

> **CRITICAL: This is a MULTI-SESSION task.** Every session must start by reading the master state file and end by updating it. Complete feedback forms after EVERY session.
>
> **Parallel session rules** — each session analyzes **one feature**. To avoid conflicts:
> - Only write to **your feature's state file** during Steps 3–8
> - Use `Update-RetrospectiveMasterState.ps1` for master state coordination (claim/complete)
> - **All shared file updates** (feature tracking, test tracking, workflow tracking, tech debt tracking) are deferred to a single finalization session (Steps 13–16)
> - When running sequentially, batch features in the same category to spot cross-cutting patterns
>
> **🚨 All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint. Never proceed past a checkpoint without approval.**

### Preparation

1. **Read [Master State File](../../../process-framework-local/state-tracking/temporary/old/retrospective-master-state.md)**:
   - Verify Phase 1 is complete
   - Identify which features still need analysis
   - Set status to "ANALYSIS" if not already
2. **🚨 CHECKPOINT**: Present which features need analysis and proposed batching order to human partner
3. **Claim feature in master state**: Before starting analysis, mark your feature as in-progress:
   ```bash
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/update/Update-RetrospectiveMasterState.ps1 -StateFile "<path>" -FeatureId "<id>" -Column "Analyzed" -Status "InProgress"
   ```
   > If the feature already shows 🟡 (claimed by another session), select a different feature.

### Execution

4. **Analyze Implementation Patterns** (for each feature):
   - **Check Existing Project Documentation** (before source analysis):
     - Open the feature's Section 4 "Existing Project Documentation" table
     - If entries exist: skim each listed document for content relevant to this feature
     - While analyzing source code in subsequent sub-steps, confirm or flag each entry:
       - `Confirmed` — content accurately describes the implementation
       - `Partially Accurate` — mostly right, some gaps (note specifics in Notes column)
       - `Outdated` — no longer reflects implementation (note what changed)
     - If no entries exist (new project or feature had no pre-existing docs): skip this sub-step
   - **Component Architecture**: How is the code structured?
     - Identify layers (data, service, UI, utilities)
     - Map component relationships
   - **Data Flow**: How does data move through the system?
     - Trace input → processing → output
     - Identify transformations and validations
   - **Error Handling**: How are errors managed?
     - Exception handling patterns
     - Error propagation and recovery
   > **Cross-Feature Code Boundaries**: When a source file contains code owned by another feature (e.g., timer logic in `ui/ui.py` owned by 0.2.0 while analyzing 1.1.0):
   > 1. **Analyze only your feature's code** — note the other feature's presence but do not analyze its logic
   > 2. **Record as a dependency** in Step 5 (Feature Dependencies), noting which feature owns the co-located code and how the features interact
   > 3. **Report as technical debt** — interleaved feature code in shared files indicates a separation-of-concerns issue. Log it via [New-BugReport.ps1](../../scripts/file-creation/06-maintenance/New-BugReport.ps1) or note it for [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md)
   - Document in [Feature Implementation State file](/doc/state-tracking/features) → Design Decisions section

5. **Document Dependencies** (for each feature):
   - **Feature Dependencies**: Cross-feature integrations, shared components
   - **System Dependencies**: External libraries and versions
   - **Code Dependencies**: Shared utilities, base classes, interfaces
   - **User-Facing Workflows**: Note which user workflows this feature participates in (e.g., "file move → links updated" requires detection + parsing + updating) in the feature state file's Dependencies section _(shared file update deferred to finalization)_
   - Document in [Feature Implementation State file](/doc/state-tracking/features) → Dependencies section
   - **Format for Feature Dependency references**: Use `[feature_id Feature Name](./feature_id-feature-name-implementation-state.md)` — e.g., `**[0.1.2 Data Models](./0.1.2-data-models-implementation-state.md)**` (these are example paths within the feature state directory, not links to actual files). Do NOT use PF-FEA IDs in dependency entries.

6. **🚨 CHECKPOINT**: Present analysis findings for the feature for review before continuing
   > **T1 fast path**: For Tier 1 features with ≤5 source files, you may defer this checkpoint and instead present analysis findings together with test coverage at Step 8 as a single combined checkpoint.

7. **Map Tests to Implementation** (for each feature):
   - **Test Coverage**: What's tested vs. what exists?
   - **Test Types**: Unit, integration, parser, performance, e2e?
   - **Test Gaps**: Critical paths without tests, edge cases not covered
   - **Cross-cutting Tests**: Identify test files that validate interactions across multiple features
   - Document in [Feature Implementation State file](/doc/state-tracking/features) → Test Files section
   > **If no tests exist for this feature**: record "No tests" in the state file Test Files section, and flag as a test gap for future Test Specification Creation.
   > **Note**: Test tracking infrastructure updates are deferred to finalization _(see [Parallel Session Rules](#process))_.

8. **🚨 CHECKPOINT**: Present test coverage gaps and cross-cutting patterns to human partner

9. **Evaluate Implementation Quality** (for each feature):

   > **Onboarding Quality Gate**: This step scores the feature's implementation quality to determine how it will be documented in PF-TSK-066. Features meeting quality standards are documented as-built (descriptive). Features below standard are documented with a target-state design plus gap analysis that auto-generates tech debt items.

   Using the analysis findings from Steps 4-7, score the feature on each dimension using the 0-3 scale:

   | Score | Meaning |
   |-------|---------|
   | **0** | Absent or broken — capability doesn't exist or is non-functional |
   | **1** | Present but problematic — exists but has significant issues |
   | **2** | Adequate — works correctly, follows reasonable patterns |
   | **3** | Well-implemented — clean, robust, follows best practices |

   | Dimension | What to Evaluate |
   |-----------|-----------------|
   | **Structural clarity** | Clean separation of concerns, reasonable layering, no god classes/functions |
   | **Error handling** | Consistent patterns, no silent failures, appropriate recovery |
   | **Data integrity** | Proper validation at boundaries, no injection vectors, consistent patterns |
   | **Test coverage** | Existing tests cover critical paths (from Step 7 test mapping) |
   | **Maintainability** | Readable code, reasonable complexity, no excessive coupling |

   **Classification**:
   - Calculate the average score across all 5 dimensions
   - Average **>= 2.0** → **As-Built** (feature will be documented descriptively in PF-TSK-066)
   - Average **< 2.0** → **Target-State** (feature will be documented prescriptively with gap analysis in PF-TSK-066)

   **Record in Feature Implementation State file** → Section 8 "Quality Assessment":
   - Enter each dimension score with brief evidence notes
   - Enter the average score and classification (As-Built / Target-State)

10. **🚨 CHECKPOINT**: Present quality scores and classifications for the feature to human partner for validation before committing

11. **Note Complexity Factors** (for features without tier assessments):
   - Number of files/components
   - Integration complexity
   - Data flow complexity
   - State management complexity
   - These notes feed into the next task (Retrospective Documentation Creation)

12. **Mark feature complete in master state**:
    ```bash
    pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/update/Update-RetrospectiveMasterState.ps1 -StateFile "<path>" -FeatureId "<id>" -Column "Analyzed" -Status "Complete"
    ```

### Finalization

> **⚠️ IMPORTANT**: Finalization must run as a **single session** after all parallel analysis sessions have completed (all features show ✅ in the "Analyzed" column). This session consolidates findings and batch-updates all shared files.

13. **Consolidate Cross-Cutting Findings**:
    - Read all enriched [Feature Implementation State files](/doc/state-tracking/features)
    - Identify cross-cutting patterns that span multiple features (shared utilities, common error handling approaches, repeated architectural decisions)
    - Validate bidirectional dependencies: if Feature A lists Feature B as a dependency, verify Feature B's state file acknowledges the reverse relationship
    - Document cross-cutting patterns in the master state session log
    - **🔍 Framework Improvement Observations**: During pattern consolidation, note any implementation patterns, testing approaches, error handling strategies, or architectural conventions that could improve the process framework. Record in the master state "Framework Improvement Observations" section.

14. **Batch-Update Shared Files**:
    - **[User Workflow Tracking](/doc/state-tracking/permanent/user-workflow-tracking.md)**: Create or update workflow definitions from workflow notes collected in feature state files during Step 5.  Verify every feature appears in at least one workflow (or is explicitly documented with `workflows: []`). Update Impl Status column based on feature-tracking.md statuses. Flag orphan workflows or missing coverage.
    - **[Test Tracking](../../../test/state-tracking/permanent/test-tracking.md)**: Register test files discovered during Step 7. Ensure each test file has pytest markers (feature, priority, test_type, cross_cutting). Add entries organized by feature category. Use `New-TestFile.ps1` for individual files or batch-populate for large suites.
    - **[Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md)**: Update Test Status column (✅ for features with tests, 🚫 for features without). Update Quality column with classification (As-Built / Target-State) from Step 9.
    - **[Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md)**: Extract technical debt items identified in feature state files (Section 9 "Known Issues & Technical Debt") and register them in the central registry using `Update-TechDebt.ps1 -Add`. Assign appropriate dimension tags, priority levels, and code locations. This ensures all discovered debt is centrally tracked for future Technical Debt Assessment cycles.

15. **Update [Master State](../../../process-framework-local/state-tracking/temporary/old/retrospective-master-state.md)**:
    - Verify all features show ✅ in the "Analyzed" column (use `Update-RetrospectiveMasterState.ps1` to fix any missed updates)
    - **Reconcile Progress Overview counters**: Compare the Progress Overview table counters against actual Feature Inventory status markers. If any counter is stale (e.g., shows "Not Started" for features already marked ✅), run `Update-RetrospectiveMasterState.ps1` on any feature to trigger a full recalculation, or manually correct the counters
    - Update "Existing Documentation Inventory": mark Confirmed column ✅ for docs whose feature-level entries have all been confirmed/flagged
    - Log session notes with key discoveries and cross-cutting findings
    - **Complete feedback form for the session**

16. **🚨 CHECKPOINT**: Present complete analysis summary, workflow map validation results, cross-cutting patterns, quality classifications summary, and complexity factors to human partner for approval before marking task complete
17. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Outputs

- **Enriched [Feature Implementation State Files](/doc/state-tracking/features)** — updated with:
  - Design Decisions section populated
  - Dependencies section populated
  - Implementation Patterns documented
  - Test coverage mapped
  - Complexity factors noted

## Tools and Scripts

- **[Update-RetrospectiveMasterState.ps1](../../scripts/update/Update-RetrospectiveMasterState.ps1)** — Atomic updates to master state Feature Inventory (claim/complete features, recalculate Progress Overview counters). Used for parallel session coordination.
- **[New-FeedbackForm.ps1](../../scripts/file-creation/support/New-FeedbackForm.ps1)** — Create feedback forms for session completion

## State Tracking

### Existing State Files Updated

- [Retrospective Master State File](../../../process-framework-local/state-tracking/temporary/old/retrospective-master-state.md) — Phase 2 progress, features marked as analyzed
- [Feature Implementation State Files](/doc/state-tracking/features) — Enriched with analysis content (Design Decisions, Dependencies, Implementation Patterns)
- [User Workflow Tracking](/doc/state-tracking/permanent/user-workflow-tracking.md) — Workflow definitions updated during finalization
- [Test Tracking](../../../test/state-tracking/permanent/test-tracking.md) — Test files registered during finalization
- [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) — Test Status column updated during finalization
- [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md) — Debt items from feature state files registered during finalization

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

- [ ] Implementation patterns analyzed and documented for every feature
- [ ] Dependencies identified and documented for every feature
- [ ] Test coverage mapped for every feature
- [ ] **Quality Assessment completed** (Step 9): Every feature scored on 5 dimensions (0-3 scale), classified as As-Built or Target-State, and recorded in Feature Implementation State file Section 8
- [ ] Quality scores and classifications validated by human partner (Step 10 checkpoint)
- [ ] Complexity factors noted for features without tier assessments
- [ ] Existing Project Documentation entries confirmed or flagged for every analyzed feature (Section 4 Confirmed column updated)
- [ ] **Finalization (single session)**:
  - [ ] Cross-cutting patterns consolidated across all feature state files
  - [ ] Bidirectional dependencies validated
  - [ ] Test files have pytest markers and are listed in [test-tracking.md](../../../test/state-tracking/permanent/test-tracking.md)
  - [ ] Feature Tracking Test Status column updated for all features
  - [ ] Feature Tracking Quality column updated for all features (As-Built / Target-State)
  - [ ] Technical debt items from feature state files registered in [technical-debt-tracking.md](../../../doc/state-tracking/permanent/technical-debt-tracking.md)
  - [ ] Workflow map validated — all features mapped to workflows, no orphan workflows, Impl Status column updated
- [ ] All features show ✅ in "Analyzed" column of [master state file](../../../process-framework-local/state-tracking/temporary/old/retrospective-master-state.md)
- [ ] Phase 2 marked complete in master state file
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Guide](../../guides/framework/feedback-form-guide.md) for each tool used, using task ID "PF-TSK-065" and context "Codebase Feature Analysis"
  - **⚠️ IMPORTANT**: Evaluate the Codebase Feature Analysis task (PF-TSK-065) and its tools (feature implementation state files, analysis process), not the features you analyzed.

## Next Tasks

- [**Retrospective Documentation Creation (PF-TSK-066)**](retrospective-documentation-creation.md) — Create tier assessments and required design documentation for all analyzed features

## Metrics and Evaluation

- **Analysis Coverage**: Features analyzed / Total features (Target: 100%)
- **Features per Session**: Number of features analyzed per session
- **Cross-cutting Patterns**: Number of shared patterns identified across features

## Related Resources

- [Codebase Feature Discovery (PF-TSK-064)](codebase-feature-discovery.md) - Prerequisite task
- [Feature Implementation State Template](../../templates/04-implementation/feature-implementation-state-template.md) - Template structure reference
- [Feature Implementation State Tracking Guide](../../guides/04-implementation/feature-implementation-state-tracking-guide.md) - Guide for populating analysis sections
- [Test Query Tool](/process-framework/scripts/test/test_query.py) - Query test files by feature, priority, and markers
- [Test Tracking](../../../test/state-tracking/permanent/test-tracking.md) - Test implementation status tracking
- [Onboarding Edge Cases Guide](../../guides/00-setup/onboarding-edge-cases.md) - Edge-case guidance for ambiguous file assignment, shared utilities, and confidence tagging
