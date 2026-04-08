---
id: PF-TSK-066
type: Process Framework
category: Task Definition
domain: agnostic
version: 2.0
created: 2026-02-17
updated: 2026-04-05
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
- [Master state file](../../../process-framework-local/state-tracking/temporary/old/retrospective-master-state.md) shows Phase 2 done (all features analyzed)
- All [Feature Implementation State files](/doc/state-tracking/features) have enriched analysis content
- Ready to create formal design documentation

## Context Requirements

[View Context Map for this task](../../visualization/context-maps/00-setup/retrospective-documentation-creation-map.md)

- **Critical (Must Read):**

  - [Retrospective Master State File](../../../process-framework-local/state-tracking/temporary/old/retrospective-master-state.md) — Read current state, verify Phase 2 complete
  - [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) - Feature list, tiers, and documentation links
  - [Feature Implementation State Files](/doc/state-tracking/features) — All enriched files from PF-TSK-065

- **Important (Load If Space):**

  - [Documentation Tiers README](../../../doc/documentation-tiers/README.md) - Understanding tier documentation requirements
  - [FDD Creation Task](../02-design/fdd-creation-task.md) - For creating Functional Design Documents
  - [TDD Creation Task](../02-design/tdd-creation-task.md) - For creating Technical Design Documents
  - [Test Specification Creation Task](../03-testing/test-specification-creation-task.md) - For creating Test Specifications
  - [Integration and Testing Task](../04-implementation/integration-and-testing.md) - For migrating pre-existing tests to framework structure (Step 8, migration mode)
  - [ADR Creation Task](../02-design/adr-creation-task.md) - For creating Architecture Decision Records

- **Reference Only (Access When Needed):**
  - [API Design Task](../02-design/api-design-task.md) - For documenting existing API contracts
  - [Database Schema Design Task](../02-design/database-schema-design-task.md) - For documenting existing schema
  - [Cross-Cutting Test Specification Template](../../templates/03-testing/cross-cutting-test-specification-template.md) - Template for multi-feature test specifications
  - [Test Query Tool](/process-framework/scripts/test/test_query.py) - Query test files by feature, priority, and markers
  - [Task Transition Guide](../../guides/framework/task-transition-guide.md) - Understanding documentation workflow
  - [PF Documentation Map](../../PF-documentation-map.md) - For registering process-framework artifacts
  - [PD Documentation Map](../../../doc/PD-documentation-map.md) - For registering product documents (FDDs, TDDs, ADRs, validation reports)
  - [TE Documentation Map](../../../test/TE-documentation-map.md) - For registering test specifications and audit reports

## Process

> **CRITICAL: This is a MULTI-SESSION task. Every session must start by reading the master state file and end by updating it.**
>
> **Priority order**: Foundation (0.x.x) first → Tier 3 → Tier 2. Tier 1 features only need tier validation (no documentation beyond implementation state file created in PF-TSK-064). All Tier 2+ features get FDD, TDD, Test Specification, and test migration (if pre-existing tests exist).
>
> **FEEDBACK: Complete feedback forms after EVERY session, not just at the end.**
>
> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

### Preparation

1. **Read [Master State File](../../../process-framework-local/state-tracking/temporary/old/retrospective-master-state.md)**:
   - Verify Phase 2 is complete
   - Identify which features still need assessment and documentation
   - Set status to "ASSESSMENT_AND_DOCUMENTATION" if not already
2. **Verify tech debt consolidation**: Confirm that [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md) has been populated with debt items from feature state files (PF-TSK-065 Step 14). If the registry is empty despite debt items in feature state files, consolidate before proceeding.
3. **🚨 CHECKPOINT**: Present features needing documentation and proposed priority order to human partner

### Phase 3: Documentation Creation

> **Prerequisite**: All features have tier assessments and Feature Implementation State files, created during [Codebase Feature Discovery (PF-TSK-064)](codebase-feature-discovery.md) Step 10.

3. **Validate Tier Assessments** (if needed):
   - Compare assessment tier with analysis findings from PF-TSK-065
   - If inaccurate based on deeper analysis, update the assessment and Feature Tracking
   - Document any discrepancies in master state session notes

4. **🚨 CHECKPOINT**: Confirm tier assignments are accurate for current batch of features before creating documents

#### Per Feature: Document (Tier 2+ only)

> **Extraction-First Principle**: Before writing any design document from scratch, check the feature's Section 4 "Existing Project Documentation" table for entries marked `Confirmed` or `Partially Accurate`. Extract validated content from those sources first, then supplement with findings from source code analysis. When reusing content, include attribution (e.g., "Derived from HOW_IT_WORKS.md, Architecture section").

5. **Create Functional Design Document (Tier 2+)**:
   - Use [FDD Creation Task](../02-design/fdd-creation-task.md)
   - **Source**: [Feature Implementation State file](/doc/state-tracking/features) + existing code
   - **Check first**: Section 4 "Existing Project Documentation" for confirmed docs with functional/user-facing content
   - **Read**: Section 8 "Quality Assessment" for the feature's classification

   **As-Built features** (average score >= 2.0):
   - **Approach**: Descriptive (what it does) not prescriptive (what it should do)
   - **Content**: Document actual functionality, user flows, business rules as implemented
   - **Mark**: Add "Retrospective" note in header. Set `documentation_mode: as-built` in metadata

   **Target-State features** (average score < 2.0):
   - **Approach**: Prescriptive (what the correct design should be), informed by current implementation
   - **Content**: Document intended functionality, user flows, business rules as they should work
   - **Gap Analysis section**: For each gap between current and target state, describe:
     - What currently exists
     - What the target state should be
     - The dimension(s) affected (structural clarity, error handling, etc.)
     - Severity (CRITICAL / HIGH / MEDIUM / LOW)
   - **Mark**: Add "Retrospective — Target-State" note in header. Set `documentation_mode: target-state` in metadata

   - Update master state: FDD ✅ for this feature

6. **Create Technical Design Document (Tier 2+)**:
   - Use [TDD Creation Task](../02-design/tdd-creation-task.md)
   - **Source**: [Feature Implementation State file](/doc/state-tracking/features) (Component Architecture, Data Flow, Design Decisions)
   - **Check first**: Section 4 "Existing Project Documentation" for confirmed docs with architecture/technical content
   - **Read**: Section 8 "Quality Assessment" for the feature's classification

   **As-Built features** (average score >= 2.0):
   - **Approach**: Reverse-engineer from actual code structure
   - **Content**: Document actual architecture, components, patterns, implementation decisions
   - **Mark**: Add "Retrospective" note in header. Set `documentation_mode: as-built` in metadata

   **Target-State features** (average score < 2.0):
   - **Approach**: Prescriptive — document the intended architecture and design
   - **Content**: Document target architecture, component structure, patterns, and design decisions as they should be
   - **Gap Analysis section**: For each architectural gap, describe current vs. target state with severity
   - **Mark**: Add "Retrospective — Target-State" note in header. Set `documentation_mode: target-state` in metadata

   - Update master state: TDD ✅ for this feature

7. **Create Test Specification (Tier 2+)**:
   - Use [Test Specification Creation Task](../03-testing/test-specification-creation-task.md)
   - **Check first**: The feature's test files listed in Section 6 of the [Feature Implementation State file](/doc/state-tracking/features); browse the existing test directory structure on disk
   - **Source**: Existing test files (primary), [Feature Implementation State file](/doc/state-tracking/features) → Test Files section and [Master State File](../../../process-framework-local/state-tracking/temporary/old/retrospective-master-state.md) (secondary)
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
   - **Multiple specs in one session**: When creating specs for several features, complete each spec fully before starting the next — create the file via `New-TestSpecification.ps1`, then update all 5 state files (feature-tracking, test-registry, id-registry, TE-documentation-map, test-tracking) per PF-TSK-012's State Tracking section. This keeps tracking consistent and avoids end-of-session drift.

8. **Migrate Pre-Existing Tests to Framework Structure (Tier 2+)**:
   - **Purpose**: Ensure pre-existing tests are fully consumed by the framework — no parallel test systems
   - **Delegate to**: [Integration and Testing Task (PF-TSK-053)](../04-implementation/integration-and-testing.md) in **migration mode**
   - **Migration mode framing** — the following PF-TSK-053 adaptations apply:
     - *Step 1 "Review Test Specification"*: Use the test specification just created in Step 7 as the reference
     - *Step 7 "Create Test Files"*: Use `New-TestFile.ps1` to create new framework-structured test files. Copy test logic (assertions, setup, fixtures) from the pre-existing files into the generated framework files. Do not rewrite test logic — restructure it to match the template and add pytest markers (`feature`, `priority`, `test_type`)
     - *Steps 8-11*: Verify existing tests cover the spec; fill gaps only where the spec identifies missing coverage
     - *Steps 12-13 "Mocks and Coverage"*: Migrate existing mocks/fixtures; run coverage to establish baseline
     - *Steps 17-18 "Run and Review"*: Execute migrated tests to confirm they still pass
     - *Steps 20-22 "Bug Discovery"*: Skip — migration should not introduce new bugs; report only if pre-existing tests were already failing
     - *Step 24 "Validate Test Tracking"*: Run `Validate-TestTracking.ps1` to confirm registration is consistent
   - **After migration**: Remove the original pre-existing test files. The framework-structured files are the sole test artifacts
   - **State updates**: test-tracking.md, feature-tracking.md Test Status, and Feature Implementation State File are updated by `New-TestFile.ps1` automation
   - Update master state: Tests Migrated ✅ for this feature

9. **Create Architecture Decision Records (Foundation 0.x.x)**:
   - Use [ADR Creation Task](../02-design/adr-creation-task.md)
   - **Source**: [Feature Implementation State file](/doc/state-tracking/features) → Design Decisions
   - **Content**: Document architectural patterns/decisions discovered in code
   - **Note**: Mark unknowns (alternatives considered, full rationale) clearly
   - Update master state: ADR ✅

10. **Create Conditional Documents** (if tier assessment indicates):
   - **API Design**: Use [API Design Task](../02-design/api-design-task.md) — document existing API contracts
   - **Database Schema**: Use [Database Schema Design Task](../02-design/database-schema-design-task.md) — document existing schema
   - Update master state for each document created

11. **Generate Tech Debt Items from Gap Analysis** (Target-State features only):
   - For each gap identified in the FDD and TDD Gap Analysis sections:
     - Create a tech debt item using:
       ```powershell
       pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/update/Update-TechDebt.ps1 -Add -Description "<gap description>" -Priority "<CRITICAL|HIGH|MEDIUM|LOW>" -Source "Onboarding QAR: <Feature Name>" -Notes "Gap <GAP-ID> from Quality Assessment Report <PD-QAR-XXX>"
       ```
     - Record the assigned PD-TDI-XXX ID
   - Update the Feature Implementation State file Section 10 "Known Limitations & Tech Debt" with links to created items

12. **Create Quality Assessment Report** (Target-State features only):
   - Use the automation script:
     ```powershell
     pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/00-setup/New-QualityAssessmentReport.ps1 -FeatureName "<name>" -FeatureId "<id>" -Tier <tier> -AverageScore <score>
     ```
   - Fill in:
     - Section 2: Dimension scores with evidence (copy from Feature Implementation State file Section 8)
     - Section 3: Overall quality narrative — systemic issues, not just individual symptoms
     - Section 4: Gap analysis summary — link each gap to its PD-TDI-XXX tech debt item from Step 11
     - Section 5: Recommended remediation sequence — order by dependency and impact
     - Section 6: Links to feature state file, FDD, TDD, and tech debt items
   - Update Feature Implementation State file Section 8 "Quality Assessment Report" link
   - Update master state: QAR ✅ for this feature

#### After Each Feature

13. **🚨 CHECKPOINT**: Present created documents for current batch of features for review

14. **Update [Feature Implementation State File](/doc/state-tracking/features)** for the feature:
    - **Section 3 (Progress)**: Mark documentation milestones as complete (FDD ✅, TDD ✅, Test Spec ✅, ADR ✅ as applicable)
    - **Section 4 (Quick Links)**: Add links to all created documents (FDD, TDD, Test Spec, ADR, QAR)
    - **Section 10 (Next Steps)**: Update to reflect documentation is complete; replace any stale "pending documentation" markers with actual next actions (e.g., implementation planning, enhancement work)

15. **Update [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md)**:
    - Add document links to appropriate columns as documents are created

16. **Update [Master State](../../../process-framework-local/state-tracking/temporary/old/retrospective-master-state.md) After Each Session**:
   - Mark assessment and document completion status per feature
   - Log session notes
   - **Complete feedback form for the session**

### Phase 4: Finalization

17. **Verify Codebase Coverage**:
    - All source files assigned to at least one feature? ✅
    - All features have [Feature Implementation State files](/doc/state-tracking/features)? ✅
    - Coverage metric = 100%? ✅

18. **Verify Documentation Completeness**:
    - All features have tier assessments (created or validated)? ✅
    - All Tier 2+ features have FDD and TDD? ✅
    - All Tier 2+ features have Test Specifications? ✅
    - All Tier 2+ features with pre-existing tests: tests migrated to framework structure? ✅
    - Foundation features have ADRs (where architectural decisions exist)? ✅
    - All conditional documents created per assessment? ✅
    - All Target-State features have Quality Assessment Reports with tech debt items? ✅
    - All documents marked "Retrospective" (or "Retrospective — Target-State")? ✅

19. **Verify Tracking Completeness**:
    - All document links in [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md)? ✅
    - All [Feature Implementation State files](/doc/state-tracking/features) linked in Feature Tracking? ✅

20. **🚨 CHECKPOINT**: Present completeness verification results and reconciliation plan to human partner for approval

21. **Pre-existing Documentation Gap Analysis**:
    > **Goal**: Verify that all valuable content from pre-existing documentation has been consumed by framework docs created during Phase 3. After onboarding, no pre-existing docs should remain as active references outside the framework tree.
    - Review the master state "Existing Documentation Inventory" table
    - For each pre-existing document, assess consumption status:
      - **Fully consumed**: All valuable content has been captured in framework docs (FDDs, TDDs, ADRs, etc.) created during Phase 3 → record which framework docs captured it
      - **Partially consumed**: Some content was extracted but sections remain uncaptured → identify the gaps
      - **Not consumed**: Document was not used as source material during Phase 3 → evaluate if content is valuable
    - For partially/not consumed documents with valuable content:
      - Determine which framework document type would capture the remaining content (handbook, guide, architecture doc, etc.)
      - Present the gaps and proposed framework doc targets to human partner
      - Create the missing framework docs or flag as follow-up work
    - Archive all originals to `doc/archive-pre-framework/manuals`
    - Rewrite root `README.md` to reference framework documentation exclusively
    - Update the master state inventory with the consumption status and target framework doc(s) for each document

22. **Harvest Framework Improvement Ideas**:
    > **Goal**: Formalize any observations accumulated during onboarding (PF-TSK-064, PF-TSK-065, and this task) into actionable PF-IMP entries for the framework's continuous improvement cycle.
    - Review the master state "Framework Improvement Observations" section
    - For each observation, evaluate: Is this an actionable improvement the framework should adopt?
    - **🚨 CHECKPOINT**: Present the list of candidate improvements to human partner for approval
    - For each approved observation, create a PF-IMP entry:
      ```powershell
      # Single item
      pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/support/New-ProcessImprovement.ps1 -Description "<improvement description>" -Priority "LOW|MEDIUM|HIGH" -Source "Onboarding: [Project Name]" -Notes "<context from observation>"

      # Batch mode (preferred for multiple improvements) — pass a JSON array file:
      pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/support/New-ProcessImprovement.ps1 -BatchFile "improvements.json"
      ```
    - If no observations were recorded during onboarding, note "No framework improvement observations" in the master state session log and skip this step

23. **Update Documentation Maps**: Add all new documents to the appropriate map:
    - Process-framework artifacts → [PF Documentation Map](../../PF-documentation-map.md)
    - Product documents (FDDs, TDDs, ADRs) → [PD Documentation Map](../../../doc/PD-documentation-map.md)
    - Test specifications and audit reports → [TE Documentation Map](../../../test/TE-documentation-map.md)

24. **Calculate Final Metrics**:
    - Total features documented
    - Total documents created (by type)
    - Total sessions and time spent
    - Coverage percentage achieved
    - Record in [master state file](../../../process-framework-local/state-tracking/temporary/old/retrospective-master-state.md) Completion Summary section

25. **Archive Master State File**:
    - Move from `/temporary/` to `/temporary/archived/` (or `/temporary/old/`)

26. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Outputs

### Phase 3 Outputs: Documentation
- **Functional Design Documents** (PD-FDD-XXX) — Tier 2+ features, marked "Retrospective"
- **Technical Design Documents** (PD-TDD-XXX) — Tier 2+ features, marked "Retrospective"
- **Test Specifications** (PD-TST-XXX) — Tier 2+ features, marked "Retrospective"
- **Migrated Test Files** (TE-TST-XXX) — Tier 2+ features with pre-existing tests, restructured to framework template with pytest markers
- **Architecture Decision Records** (PD-ADR-XXX) — Foundation 0.x.x features, marked "Retrospective"
- **API/DB Design Documents** — Conditional per assessment, marked "Retrospective"
- **Quality Assessment Reports** (PD-QAR-XXX) — One per Target-State feature, linking dimension scores to tech debt items with remediation sequence
- **Tech Debt Items** (PD-TDI-XXX) — Auto-generated from gap analysis in Target-State FDDs/TDDs

### Phase 4 Outputs: Finalization
- **Updated [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md)** — All document links in appropriate columns
- **Updated Documentation Maps** — All new documents registered in the appropriate map: product docs (FDDs/TDDs/ADRs) → [PD Documentation Map](../../../doc/PD-documentation-map.md); test specs → [TE Documentation Map](../../../test/TE-documentation-map.md); process artifacts → [PF Documentation Map](../../PF-documentation-map.md)
- **Pre-existing documentation gap analysis** — All pre-existing docs verified as consumed by framework docs or gaps identified and addressed; originals archived to `doc/archive-pre-framework/manuals`; root README.md rewritten to reference framework docs
- **Framework Improvement Entries** (PF-IMP-XXX) — Observations from onboarding formalized as process improvement entries (if any)
- **Archived [Master State File](../../../process-framework-local/state-tracking/temporary/old/retrospective-master-state.md)** — Moved to `/temporary/archived/`

## State Tracking

### Existing State Files Updated

- [Retrospective Master State File](../../../process-framework-local/state-tracking/temporary/old/retrospective-master-state.md) — Phase 3+4 progress, final metrics, archived on completion
- [Feature Implementation State Files](/doc/state-tracking/features) — Documentation Inventory section updated with created document links
- [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) — Tier assignments and all document links added
- [Test Tracking](../../../test/state-tracking/permanent/test-tracking.md) — Migrated test files registered with TE-TST IDs (updated by `New-TestFile.ps1` automation)
- [PD Documentation Map](../../../doc/PD-documentation-map.md) — Product documents (FDDs, TDDs, ADRs) registered
- [TE Documentation Map](../../../test/TE-documentation-map.md) — Test specifications and audit reports registered
- [PF Documentation Map](../../PF-documentation-map.md) — Process-framework artifacts registered

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

- [ ] **Phase 3 Complete: Documentation**
  - [ ] Tier assessments validated against PF-TSK-065 analysis findings (updated if inaccurate)
  - [ ] **All Tier 2+ features**: FDD created, marked "Retrospective"
  - [ ] **All Tier 2+ features**: TDD created, marked "Retrospective"
  - [ ] **All Tier 2+ features**: Test Specification created, marked "Retrospective"
  - [ ] **All Tier 2+ features with pre-existing tests**: Tests migrated to framework structure (TE-TST IDs, pytest markers, registered in test-tracking.md), original test files removed
  - [ ] **All Foundation 0.x.x features**: ADR created where architectural decisions exist, marked "Retrospective"
  - [ ] **Conditional documents**: API/DB designs created where assessment indicates
  - [ ] **All Target-State features**: Tech debt items generated from FDD/TDD gap analysis (Steps 11)
  - [ ] **All Target-State features**: Quality Assessment Report created with dimension scores, gap analysis, and remediation sequence (Step 12)
  - [ ] All As-Built documents accurately reflect implemented code; all Target-State documents describe intended design with gap analysis
  - [ ] All [Feature Implementation State files](/doc/state-tracking/features) updated: Section 3 progress, Section 4 Quick Links, Section 10 Next Steps reflect created documents
  - [ ] All document links added to [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md)

- [ ] **Phase 4 Complete: Finalization**
  - [ ] [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) verified complete with ALL document links
  - [ ] Run [`Validate-StateTracking.ps1`](../../scripts/validation/Validate-StateTracking.ps1) — 0 errors across all surfaces
  - [ ] Pre-existing documentation gap analysis complete — each doc in master state inventory marked with consumption status (Fully Consumed / Partially Consumed / Not Consumed) and target framework doc(s); gaps addressed or flagged as follow-up; originals archived to `doc/archive-pre-framework/manuals`; root README.md rewritten to reference framework docs
  - [ ] Framework improvement observations reviewed and approved observations formalized as PF-IMP entries (or noted as "none" in session log)
  - [ ] Documentation Maps updated with all new documents: [PD Documentation Map](../../../doc/PD-documentation-map.md) (FDDs/TDDs/ADRs), [TE Documentation Map](../../../test/TE-documentation-map.md) (test specs), [PF Documentation Map](../../PF-documentation-map.md) (process artifacts)
  - [ ] Final metrics calculated and recorded in [master state](../../../process-framework-local/state-tracking/temporary/old/retrospective-master-state.md)
  - [ ] [Master State File](../../../process-framework-local/state-tracking/temporary/old/retrospective-master-state.md) archived to `/temporary/archived/`

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
- [Documentation Tiers README](../../../doc/documentation-tiers/README.md) - Tier definitions and documentation requirements
- [Task Transition Guide](../../guides/framework/task-transition-guide.md) - Understanding documentation workflow
- [Onboarding Edge Cases Guide](../../guides/00-setup/onboarding-edge-cases.md) - Edge-case guidance for ambiguous file assignment, shared utilities, and confidence tagging
