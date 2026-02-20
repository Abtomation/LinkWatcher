---
id: PF-TSK-065
type: Process Framework
category: Task Definition
version: 1.2
created: 2026-02-17
updated: 2026-02-20
task_type: Onboarding
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

**[📊 View Context Map for this task](../../visualization/context-maps/00-onboarding/codebase-feature-analysis-map.md)** - Visual guide showing all components and their relationships

- **Critical (Must Read):**

  - [Retrospective Master State File](../../state-tracking/temporary/retrospective-master-state.md) — Read current state, verify Phase 1 complete
  - [Feature Tracking](../../state-tracking/permanent/feature-tracking.md) - Feature list and current status
  - [Feature Implementation State Files](../../state-tracking/features/) — All files created during PF-TSK-064
  - [Feature Implementation State Tracking Guide](../../guides/guides/feature-implementation-state-tracking-guide.md) - Guide for populating analysis sections

- **Important (Load If Space):**
  - [Feature Tier Assessment Task](../01-planning/feature-tier-assessment-task.md) - Understanding what analysis feeds into tier assessment

- **Reference Only (Access When Needed):**
  - [Documentation Tiers README](../../methodologies/documentation-tiers/README.md) - Understanding tier documentation requirements
  - [Feature Dependencies](../../../product-docs/technical/design/feature-dependencies.md) - Existing dependency documentation
  - [Test Registry](/test/test-registry.yaml) - Registry for mapping test files to features
  - [Test Implementation Tracking](../../state-tracking/permanent/test-implementation-tracking.md) - Test implementation status tracking

## Process

> **CRITICAL: This is a MULTI-SESSION task. Every session must start by reading the master state file and end by updating it.**
>
> **Recommended batching**: Analyze features in the same category together to identify cross-cutting patterns.
>
> **FEEDBACK: Complete feedback forms after EVERY session, not just at the end.**

### Preparation

1. **Read [Master State File](../../state-tracking/temporary/retrospective-master-state.md)**:
   - Verify Phase 1 is complete
   - Identify which features still need analysis
   - Set status to "ANALYSIS" if not already

### Execution

2. **Analyze Implementation Patterns** (for each feature):
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
   - Document in [Feature Implementation State file](../../state-tracking/features/) → Design Decisions section

3. **Document Dependencies** (for each feature):
   - **Feature Dependencies**: Cross-feature integrations, shared components
   - **System Dependencies**: External libraries and versions
   - **Code Dependencies**: Shared utilities, base classes, interfaces
   - Document in [Feature Implementation State file](../../state-tracking/features/) → Dependencies section
   - **Format for Feature Dependency references**: Use `[feature_id Feature Name](./feature_id-feature-name-implementation-state.md)` — e.g., `**[0.1.2 Data Models](./0.1.2-data-models-implementation-state.md)**`. Do NOT use PF-FEA IDs in dependency entries.

4. **Map Tests to Implementation** (for each feature):
   - **Test Coverage**: What's tested vs. what exists?
   - **Test Types**: Unit, integration, parser, performance, e2e?
   - **Test Gaps**: Critical paths without tests, edge cases not covered
   - **Cross-cutting Tests**: Identify test files that validate interactions across multiple features
   - Document in [Feature Implementation State file](../../state-tracking/features/) → Test Files section
   - **Register in Test Tracking Infrastructure**:
     - Add each test file to [test-registry.yaml](/test/test-registry.yaml) with feature mapping, test type, and cross-cutting features if applicable
     - Add entries to [Test Implementation Tracking](../../state-tracking/permanent/test-implementation-tracking.md) organized by feature category
     - Update [Feature Tracking](../../state-tracking/permanent/feature-tracking.md) Test Status column (✅ for features with tests, 🚫 for features without)
     - Use the automation script `New-TestFile.ps1` for registering individual test files, or batch-populate the registry directly for large existing test suites

5. **Note Complexity Factors** (for features without tier assessments):
   - Number of files/components
   - Integration complexity
   - Data flow complexity
   - State management complexity
   - These notes feed into the next task (Retrospective Documentation Creation)

### Finalization

6. **Update [Master State](../../state-tracking/temporary/retrospective-master-state.md) After Each Session**:
   - Mark features as "Analyzed ✅" in the Feature Inventory table
   - Update master state "Existing Documentation Inventory": mark Confirmed column ✅ for docs whose feature-level entries have all been confirmed/flagged
   - Log session notes with key discoveries
   - **Complete feedback form for the session**

7. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Outputs

- **Enriched [Feature Implementation State Files](../../state-tracking/features/)** — updated with:
  - Design Decisions section populated
  - Dependencies section populated
  - Implementation Patterns documented
  - Test coverage mapped
  - Complexity factors noted

## State Tracking

### Existing State Files Updated

- [Retrospective Master State File](../../state-tracking/temporary/retrospective-master-state.md) — Phase 2 progress, features marked as analyzed
- [Feature Implementation State Files](../../state-tracking/features/) — Enriched with analysis content (Design Decisions, Dependencies, Implementation Patterns)

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

- [ ] Implementation patterns analyzed and documented for every feature
- [ ] Dependencies identified and documented for every feature
- [ ] Test coverage mapped for every feature
- [ ] Test files registered in [test-registry.yaml](/test/test-registry.yaml) and [test-implementation-tracking.md](../../state-tracking/permanent/test-implementation-tracking.md)
- [ ] Feature Tracking Test Status column updated for all features
- [ ] Complexity factors noted for features without tier assessments
- [ ] Existing Project Documentation entries confirmed or flagged for every analyzed feature (Section 4 Confirmed column updated)
- [ ] Phase 2 marked complete in [master state file](../../state-tracking/temporary/retrospective-master-state.md)
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Completion Instructions](../../guides/guides/feedback-form-completion-instructions.md) for each tool used, using task ID "PF-TSK-065" and context "Codebase Feature Analysis"
  - **⚠️ IMPORTANT**: Evaluate the Codebase Feature Analysis task (PF-TSK-065) and its tools (feature implementation state files, analysis process), not the features you analyzed.

## Next Tasks

- [**Retrospective Documentation Creation (PF-TSK-066)**](retrospective-documentation-creation.md) — Create tier assessments and required design documentation for all analyzed features

## Metrics and Evaluation

- **Analysis Coverage**: Features analyzed / Total features (Target: 100%)
- **Features per Session**: Number of features analyzed per session
- **Cross-cutting Patterns**: Number of shared patterns identified across features

## Related Resources

- [Codebase Feature Discovery (PF-TSK-064)](codebase-feature-discovery.md) - Prerequisite task
- [Feature Implementation State Template](../../templates/templates/feature-implementation-state-template.md) - Template structure reference
- [Feature Implementation State Tracking Guide](../../guides/guides/feature-implementation-state-tracking-guide.md) - Guide for populating analysis sections
- [Test Registry](/test/test-registry.yaml) - Registry for mapping test files to features with cross-cutting support
- [Test Implementation Tracking](../../state-tracking/permanent/test-implementation-tracking.md) - Test implementation status tracking
