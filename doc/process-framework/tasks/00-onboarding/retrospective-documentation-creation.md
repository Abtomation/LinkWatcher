---
id: PF-TSK-066
type: Process Framework
category: Task Definition
version: 1.6
created: 2026-02-17
updated: 2026-03-02
task_type: Onboarding
---

# Retrospective Documentation Creation

## Purpose & Context

For each analyzed feature, create or validate a tier assessment, then produce the required design documentation (FDD, TDD, Test Specifications, ADRs) based on that tier. After all features are documented, verify completeness, finalize tracking, and archive the master state file.

This is the final onboarding task that transforms code analysis into formal design documentation, completing the framework adoption process.

## AI Agent Role

**Role**: Technical Documentation Specialist & Codebase Archaeologist
**Mindset**: Documentation-focused, quality-driven, completeness-oriented
**Focus Areas**: Tier assessment, design documentation creation, documentation completeness verification
**Communication Style**: Report documentation progress, ask about design rationale for unclear decisions, confirm tier assignments

## When to Use

- After [Codebase Feature Analysis (PF-TSK-065)](codebase-feature-analysis.md) is complete
- [Master state file](../../state-tracking/temporary/old/retrospective-master-state.md) shows Phase 2 done (all features analyzed)
- All [Feature Implementation State files](../../state-tracking/features/) have enriched analysis content
- Ready to create formal design documentation

## Context Requirements

**[📊 View Context Map for this task](../../visualization/context-maps/00-onboarding/retrospective-documentation-creation-map.md)** - Visual guide showing all components and their relationships

- **Critical (Must Read):**

  - [Retrospective Master State File](../../state-tracking/temporary/old/retrospective-master-state.md) — Read current state, verify Phase 2 complete
  - [Feature Tracking](../../../product-docs/state-tracking/permanent/feature-tracking.md) - Feature list, tiers, and documentation links
  - [Feature Implementation State Files](../../state-tracking/features/) — All enriched files from PF-TSK-065
  - [Feature Tier Assessment Task](../01-planning/feature-tier-assessment-task.md) - For creating tier assessments

- **Important (Load If Space):**

  - [Documentation Tiers README](../../../product-docs/documentation-tiers/README.md) - Understanding tier documentation requirements
  - [FDD Creation Task](../02-design/fdd-creation-task.md) - For creating Functional Design Documents
  - [TDD Creation Task](../02-design/tdd-creation-task.md) - For creating Technical Design Documents
  - [Test Specification Creation Task](../03-testing/test-specification-creation-task.md) - For creating Test Specifications
  - [ADR Creation Task](../02-design/adr-creation-task.md) - For creating Architecture Decision Records

- **Reference Only (Access When Needed):**
  - [API Design Task](../02-design/api-design-task.md) - For documenting existing API contracts
  - [Database Schema Design Task](../02-design/database-schema-design-task.md) - For documenting existing schema
  - [Cross-Cutting Test Specification Template](../../templates/03-testing/cross-cutting-test-specification-template.md) - Template for multi-feature test specifications
  - [Test Query Tool](/test/test_query.py) - Query test files by feature, priority, and markers
  - [Task Transition Guide](../../guides/framework/task-transition-guide.md) - Understanding documentation workflow
  - [Documentation Map](../../documentation-map.md) - For registering new documents

## Process

> **CRITICAL: This is a MULTI-SESSION task. Every session must start by reading the master state file and end by updating it.**
>
> **Priority order**: Foundation (0.x.x) first → Tier 3 → Tier 2. Tier 1 features only need assessment validation (no documentation beyond implementation state file).
>
> **FEEDBACK: Complete feedback forms after EVERY session, not just at the end.**
>
> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

### Preparation

1. **Read [Master State File](../../state-tracking/temporary/old/retrospective-master-state.md)**:
   - Verify Phase 2 is complete
   - Identify which features still need assessment and documentation
   - Set status to "ASSESSMENT_AND_DOCUMENTATION" if not already
2. **🚨 CHECKPOINT**: Present features needing documentation and proposed priority order to human partner

### Phase 3: Tier Assessment & Documentation Creation

#### Per Feature: Assess

3. **Create or Validate Tier Assessment**:
   - **If no assessment exists**: Use [Feature Tier Assessment Task](../01-planning/feature-tier-assessment-task.md)
     - Base scores on ACTUAL code analysis from PF-TSK-065 (not assumptions)
     - Use [Feature Implementation State file](../../state-tracking/features/) as evidence
     - Create assessment artifact
   - **If assessment already exists**: Validate against analysis findings
     - Compare assessment tier with actual complexity discovered
     - If inaccurate, update the assessment
     - Document any discrepancies in master state session notes
   - Update [Feature Tracking](../../../product-docs/state-tracking/permanent/feature-tracking.md) with tier assignment
   - Update [master state](../../state-tracking/temporary/old/retrospective-master-state.md): mark feature as "📊 Assessment Created"

4. **🚨 CHECKPOINT**: Present tier assessments for current batch of features for review before creating documents

#### Per Feature: Document (Tier 2+ only)

> **Extraction-First Principle**: Before writing any design document from scratch, check the feature's Section 4 "Existing Project Documentation" table for entries marked `Confirmed` or `Partially Accurate`. Extract validated content from those sources first, then supplement with findings from source code analysis. When reusing content, include attribution (e.g., "Derived from HOW_IT_WORKS.md, Architecture section").

5. **Create Functional Design Document (Tier 2+)**:
   - Use [FDD Creation Task](../02-design/fdd-creation-task.md)
   - **Source**: [Feature Implementation State file](../../state-tracking/features/) + existing code
   - **Check first**: Section 4 "Existing Project Documentation" for confirmed docs with functional/user-facing content
   - **Approach**: Descriptive (what it does) not prescriptive (what it should do)
   - **Content**: Document actual functionality, user flows, business rules as implemented
   - **Mark**: Add "Retrospective" note in header
   - Update master state: FDD ✅ for this feature

6. **Create Technical Design Document (Tier 2+)**:
   - Use [TDD Creation Task](../02-design/tdd-creation-task.md)
   - **Source**: [Feature Implementation State file](../../state-tracking/features/) (Component Architecture, Data Flow, Design Decisions)
   - **Check first**: Section 4 "Existing Project Documentation" for confirmed docs with architecture/technical content
   - **Approach**: Reverse-engineer from actual code structure
   - **Content**: Document actual architecture, components, patterns, implementation decisions
   - **Mark**: Add "Retrospective" note in header
   - Update master state: TDD ✅ for this feature

7. **Create Test Specification (Tier 3 only)**:
   - Use [Test Specification Creation Task](../03-testing/test-specification-creation-task.md)
   - **Check first**: The feature's test files listed in Section 6 of the [Feature Implementation State file](../../state-tracking/features/); browse the existing test directory structure on disk
   - **Source**: Existing test files (primary), [Feature Implementation State file](../../state-tracking/features/) → Test Files section and [Master State File](../../state-tracking/temporary/old/retrospective-master-state.md) (secondary)
   - **Approach**: Document and formalize existing test coverage, then identify gaps — not design tests from scratch
   - **Adapting PF-TSK-012 steps**: The task assumes pre-implementation spec creation. For retrospective use:
     - *Preparation Steps 1-5*: Replace "Review the Target TDD" with reviewing existing test files and the feature state file
     - *Step 6 "Define Test Categories"*: Categorize existing tests into the defined categories rather than designing new ones
     - *Step 7 "Specify Test Cases"*: Extract Arrange/Act/Assert from existing test code rather than specifying new cases
     - *Step 8 "Map TDD Components to Tests"*: Map existing tests back to TDD components to reveal coverage gaps
     - *Step 10 "AI Session Context"*: Focus the roadmap on gap coverage (untested components) rather than full implementation
   - **Content**: Document existing tests, coverage, test scenarios
   - **Gaps**: Identify missing test coverage as a gap analysis section
   - **Cross-cutting**: If test files on disk cover multiple features, create cross-cutting test specifications using `New-TestSpecification.ps1 -CrossCutting -FeatureIds "X.Y.Z,A.B.C" -FeatureName "scenario-name"`. These go in `/test/specifications/cross-cutting-specs/`
   - **Mark**: Add "Retrospective" note in header
   - Update master state: Test Spec ✅
   - **Multiple specs in one session**: When creating specs for several features, complete each spec fully before starting the next — create the file via `New-TestSpecification.ps1`, then update all 5 state files (feature-tracking, test-registry, id-registry, documentation-map, test-tracking) per PF-TSK-012's State Tracking section. This keeps tracking consistent and avoids end-of-session drift.

8. **Create Architecture Decision Records (Foundation 0.x.x)**:
   - Use [ADR Creation Task](../02-design/adr-creation-task.md)
   - **Source**: [Feature Implementation State file](../../state-tracking/features/) → Design Decisions
   - **Content**: Document architectural patterns/decisions discovered in code
   - **Note**: Mark unknowns (alternatives considered, full rationale) clearly
   - Update master state: ADR ✅

9. **Create Conditional Documents** (if tier assessment indicates):
   - **API Design**: Use [API Design Task](../02-design/api-design-task.md) — document existing API contracts
   - **Database Schema**: Use [Database Schema Design Task](../02-design/database-schema-design-task.md) — document existing schema
   - Update master state for each document created

#### After Each Feature

10. **🚨 CHECKPOINT**: Present created documents for current batch of features for review

11. **Update [Feature Tracking](../../../product-docs/state-tracking/permanent/feature-tracking.md)**:
    - Add document links to appropriate columns as documents are created

12. **Update [Master State](../../state-tracking/temporary/old/retrospective-master-state.md) After Each Session**:
   - Mark assessment and document completion status per feature
   - Log session notes
   - **Complete feedback form for the session**

### Phase 4: Finalization

13. **Verify Codebase Coverage**:
    - All source files assigned to at least one feature? ✅
    - All features have [Feature Implementation State files](../../state-tracking/features/)? ✅
    - Coverage metric = 100%? ✅

14. **Verify Documentation Completeness**:
    - All features have tier assessments (created or validated)? ✅
    - All Tier 2+ features have FDD and TDD? ✅
    - All Tier 3 features have Test Specifications? ✅
    - Foundation features have ADRs (where architectural decisions exist)? ✅
    - All conditional documents created per assessment? ✅
    - All documents marked "Retrospective"? ✅

15. **Verify Tracking Completeness**:
    - All document links in [Feature Tracking](../../../product-docs/state-tracking/permanent/feature-tracking.md)? ✅
    - All [Feature Implementation State files](../../state-tracking/features/) linked in Feature Tracking? ✅

16. **🚨 CHECKPOINT**: Present completeness verification results and reconciliation plan to human partner for approval

17. **Reconcile Pre-existing Documentation**:
    - Review the master state "Existing Documentation Inventory" table
    - For each document, determine its disposition:
      - **Keep**: Document serves an ongoing project purpose beyond what FDDs/TDDs cover (e.g., README.md, CONTRIBUTING.md)
      - **Archive**: Document's content has been fully extracted into formal design documents and no longer serves a unique purpose (e.g., HOW_IT_WORKS.md superseded by TDDs/FDDs)
    - Archive superseded documents: move to `doc/archived-pre-framework/`
    - Update the master state inventory with the disposition (Keep / Archived) for each document

18. **Update Documentation Map**: Add all new documents to [Documentation Map](../../documentation-map.md)

19. **Calculate Final Metrics**:
    - Total features documented
    - Total documents created (by type)
    - Total sessions and time spent
    - Coverage percentage achieved
    - Record in [master state file](../../state-tracking/temporary/old/retrospective-master-state.md) Completion Summary section

20. **Archive Master State File**:
    - Move from `/temporary/` to `/temporary/archived/` (or `/temporary/old/`)

21. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Outputs

### Phase 3 Outputs: Tier Assessment & Documentation
- **Tier Assessment Artifacts** (ART-ASS-XXX) — per feature
- **Functional Design Documents** (PD-FDD-XXX) — Tier 2+ features, marked "Retrospective"
- **Technical Design Documents** (PD-TDD-XXX) — Tier 2+ features, marked "Retrospective"
- **Test Specifications** (PD-TST-XXX) — Tier 3 features, marked "Retrospective"
- **Architecture Decision Records** (PD-ADR-XXX) — Foundation 0.x.x features, marked "Retrospective"
- **API/DB Design Documents** — Conditional per assessment, marked "Retrospective"

### Phase 4 Outputs: Finalization
- **Updated [Feature Tracking](../../../product-docs/state-tracking/permanent/feature-tracking.md)** — All document links in appropriate columns
- **Updated [Documentation Map](../../documentation-map.md)** — All new documents registered
- **Reconciled pre-existing documentation** — Superseded docs archived to `doc/archived-pre-framework/`, project-essential docs (README.md, CONTRIBUTING.md, etc.) kept in place
- **Archived [Master State File](../../state-tracking/temporary/old/retrospective-master-state.md)** — Moved to `/temporary/archived/`

## State Tracking

### Existing State Files Updated

- [Retrospective Master State File](../../state-tracking/temporary/old/retrospective-master-state.md) — Phase 3+4 progress, final metrics, archived on completion
- [Feature Implementation State Files](../../state-tracking/features/) — Documentation Inventory section updated with created document links
- [Feature Tracking](../../../product-docs/state-tracking/permanent/feature-tracking.md) — Tier assignments and all document links added
- [Documentation Map](../../documentation-map.md) — All new documents registered

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

- [ ] **Phase 3 Complete: Tier Assessment & Documentation**
  - [ ] Every feature has a tier assessment (created or validated)
  - [ ] [Feature Tracking](../../../product-docs/state-tracking/permanent/feature-tracking.md) updated with all tier assignments
  - [ ] **All Tier 2+ features**: FDD created, marked "Retrospective"
  - [ ] **All Tier 2+ features**: TDD created, marked "Retrospective"
  - [ ] **All Tier 3 features**: Test Specification created, marked "Retrospective"
  - [ ] **All Foundation 0.x.x features**: ADR created where architectural decisions exist, marked "Retrospective"
  - [ ] **Conditional documents**: API/DB designs created where assessment indicates
  - [ ] All documents accurately reflect implemented code
  - [ ] All document links added to [Feature Tracking](../../../product-docs/state-tracking/permanent/feature-tracking.md)

- [ ] **Phase 4 Complete: Finalization**
  - [ ] [Feature Tracking](../../../product-docs/state-tracking/permanent/feature-tracking.md) verified complete with ALL document links
  - [ ] Run [`Validate-StateTracking.ps1`](../../scripts/validation/Validate-StateTracking.ps1) — 0 errors across all surfaces
  - [ ] Pre-existing documentation reconciled — each doc in master state inventory marked Keep or Archived; superseded docs moved to `doc/archived-pre-framework/`
  - [ ] [Documentation Map](../../documentation-map.md) updated with all new documents
  - [ ] Final metrics calculated and recorded in [master state](../../state-tracking/temporary/old/retrospective-master-state.md)
  - [ ] [Master State File](../../state-tracking/temporary/old/retrospective-master-state.md) archived to `/temporary/archived/`

- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Completion Instructions](../../guides/framework/feedback-form-completion-instructions.md) for each tool used, using task ID "PF-TSK-066" and context "Retrospective Documentation Creation"
  - **⚠️ IMPORTANT**: Evaluate the Retrospective Documentation Creation task (PF-TSK-066) and its tools (tier assessment workflow, documentation creation process), not the documents you created.

## Next Tasks

After completing the full retrospective documentation effort:

- [**Feature Implementation Planning**](../04-implementation/feature-implementation-planning-task.md) — For implementing features after documentation
- [**Feature Enhancement**](../04-implementation/feature-enhancement.md) — For extending or modifying existing features
- [**Code Review Task**](../06-maintenance/code-review-task.md) — For validating existing implementation against documented design
- [**Technical Debt Assessment**](../cyclical/technical-debt-assessment-task.md) — For identifying and prioritizing technical debt discovered during analysis

## Metrics and Evaluation

- **Feature Documentation Coverage**: Features documented / Total features requiring documentation (Target: 100% of Tier 2+)
- **Documentation Quality**: Completeness, accuracy against actual code, usefulness
- **Documents per Session**: Documents created per session
- **Total Documents Created**: By type (FDD, TDD, Test Spec, ADR, API, DB)

## Related Resources

- [Codebase Feature Discovery (PF-TSK-064)](codebase-feature-discovery.md) - First onboarding task
- [Codebase Feature Analysis (PF-TSK-065)](codebase-feature-analysis.md) - Second onboarding task (prerequisite)
- [Feature Tier Assessment Task](../01-planning/feature-tier-assessment-task.md) - For creating tier assessments
- [Documentation Tiers README](../../../product-docs/documentation-tiers/README.md) - Tier definitions and documentation requirements
- [Task Transition Guide](../../guides/framework/task-transition-guide.md) - Understanding documentation workflow
