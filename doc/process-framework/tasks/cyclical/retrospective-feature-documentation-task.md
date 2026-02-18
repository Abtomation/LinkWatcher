---
id: PF-TSK-060
type: Process Framework
category: Task Definition
version: 2.0
created: 2026-02-17
updated: 2026-02-17
task_type: Cyclical
status: Superseded
---

# Retrospective Feature Documentation

> **SUPERSEDED**: This task has been split into three onboarding tasks as of 2026-02-17:
> - [Codebase Feature Discovery (PF-TSK-064)](../00-onboarding/codebase-feature-discovery.md)
> - [Codebase Feature Analysis (PF-TSK-065)](../00-onboarding/codebase-feature-analysis.md)
> - [Retrospective Documentation Creation (PF-TSK-066)](../00-onboarding/retrospective-documentation-creation.md)
>
> **Do not use this task. Use the onboarding tasks above.**

## Purpose & Context

Systematically document an entire existing codebase by identifying all features, assigning every source file to a feature, creating Feature Implementation State files for each, and then producing the required design documentation (FDD, TDD, Test Specifications, ADRs) based on tier assessments. This is a codebase-wide orchestration task that spans many sessions and uses a master state file to track overall progress.

This task is the primary mechanism for adopting the process framework into an existing, ongoing project. The approach is backwards-tracking: start from the code that exists, organize it into features, analyze it, and then create the documentation that the framework requires.

## AI Agent Role

**Role**: Technical Documentation Specialist & Codebase Archaeologist
**Mindset**: Systematic, thorough, reverse-engineering focused
**Focus Areas**: Codebase-wide inventory, feature boundary identification, code analysis, design documentation
**Communication Style**: Report progress metrics, clarify feature boundaries, ask about design decisions and rationale

## When to Use

**Primary Use Case**: Initial framework adoption for an existing project
- Process framework has been copied into the project
- Project has existing features but no framework documentation
- Feature tracking is empty or incomplete
- Need to systematically document the entire codebase

**Secondary Use Cases**:
- Resuming an ongoing retrospective documentation effort (load master state file)
- When existing features lack design documentation required by their tier
- As part of systematic documentation improvement initiatives

## Context Requirements

- **Critical (Must Read):**

  - [Retrospective Master State Template](../../templates/templates/retrospective-state-template.md) - **CRITICAL** template for tracking codebase-wide progress
  - [Feature Implementation State Template](../../templates/templates/feature-implementation-state-template.md) - **CRITICAL** template for per-feature code analysis
  - [Feature Tracking](../../state-tracking/permanent/feature-tracking.md) - Feature status and tier assessments
  - **Existing Codebase** - Source code, tests, and configuration

- **Important (Load If Space):**

  - [Feature Implementation State Tracking Guide](../../guides/guides/feature-implementation-state-tracking-guide.md) - Comprehensive guide for using the state template
  - [Feature Tier Assessment Task](../01-planning/feature-tier-assessment-task.md) - For creating tier assessments
  - [Documentation Tiers README](../../methodologies/documentation-tiers/README.md) - Understanding tier documentation requirements
  - [FDD Creation Task](../02-design/fdd-creation-task.md) - For creating Functional Design Documents
  - [TDD Creation Task](../02-design/tdd-creation-task.md) - For creating Technical Design Documents
  - [Test Specification Creation Task](../03-testing/test-specification-creation-task.md) - For creating Test Specifications
  - [ADR Creation Task](../02-design/adr-creation-task.md) - For creating Architecture Decision Records
  - [Task Transition Guide](../../guides/guides/task-transition-guide.md) - Understanding documentation workflow

- **Reference Only (Access When Needed):**
  - [Feature Dependencies](../../../product-docs/technical/design/feature-dependencies.md) - Understanding feature relationships
  - [Visual Notation Guide](../../guides/guides/visual-notation-guide.md) - For interpreting diagrams
  - [Documentation Map](../../documentation-map.md) - Overview of all framework documentation

## Process

> **🚨 CRITICAL: This is a CODEBASE-WIDE, MULTI-SESSION task. Every session must start by reading the master state file and end by updating it.**
>
> **🚨 CRITICAL: This task is NOT complete until ALL phases are finished and ALL features are documented!**
>
> **⚠️ APPROACH: Discover ALL features → Assign ALL code → Analyze → Assess & Document → Finalize**
>
> **⚠️ FEEDBACK: Complete feedback forms after EVERY session, not just at the end.**

### Preparation

1. **Check for Existing Master State File**:
   - Look in `/doc/process-framework/state-tracking/temporary/` for an existing retrospective master state file
   - **If found**: Read it, understand current phase and progress, continue from where the previous session left off
   - **If not found**: This is the first session — proceed to step 2

2. **Create Master State File** (first session only):
   - Use [Retrospective Master State Template](../../templates/templates/retrospective-state-template.md)
   - Create at: `/doc/process-framework/state-tracking/temporary/retrospective-master-state.md`
   - Fill in project name and start date
   - Set status to "DISCOVERY"

3. **Survey the Project Structure** (first session only):
   - Scan the codebase directory structure (source directories, modules, packages)
   - Review existing documentation (README, architecture docs, HOW_IT_WORKS, etc.)
   - List ALL project source files (excluding `doc/`, `.git/`, `__pycache__/`, `node_modules/`, and other non-source directories)
   - Record the complete file list in the master state file's "Unassigned Files" section — every file starts as unassigned
   - Record the total file count in master state file under Coverage Metrics
   - Identify natural feature boundaries (directories, modules, functional areas)

   > **Important**: The `doc/` directory (including the process framework) is NOT part of the codebase to be inventoried. Only source code, tests, configuration, and scripts that implement the project's functionality are tracked.

### Phase 1: Feature Discovery & Code Assignment

**Objective**: Identify ALL features and create Feature Implementation State files with complete code inventories. Every source file in the codebase must be assigned to at least one feature.

> **Recommended batching**: Process one feature category per session (e.g., all foundation features, all parser features).

4. **Discover Features**:
   - Look at major functional areas in the codebase
   - Review directory structure for feature organization
   - Check existing documentation for feature descriptions
   - Use git history to understand feature scope and boundaries
   - For each feature discovered:
     a. Add entry to [Feature Tracking](../../state-tracking/permanent/feature-tracking.md) (if not already there)
     b. Assign Feature ID (e.g., 1.2.3 or 0.1.1 for foundation)
     c. Add feature name and brief description
     d. Set status appropriately
     e. Leave tier and documentation columns empty if no assessment exists yet

5. **Create Feature Implementation State Files** (for ALL features, including Tier 1):
   - Use [Feature Implementation State Template](../../templates/templates/feature-implementation-state-template.md)
   - Create at: `/doc/process-framework/state-tracking/features/[feature-id]-implementation-state.md`
   - Set `implementation_mode: Retrospective Analysis` in metadata
   - Link the file in [Feature Tracking](../../state-tracking/permanent/feature-tracking.md) in the ID column

6. **Populate Code Inventory** (Section 5 of each implementation state file):
   - **Files Created**: Files that primarily implement this feature
     - Feature-specific modules, components, services
     - Use git history: `git log --all --oneline --name-only -- path/to/feature/`
   - **Files Modified**: Files changed to support this feature
     - Use git blame to find feature-related changes
     - Look for feature-specific conditional code
   - **Files Used**: Dependencies and integrations
     - Check imports and dependencies
     - Identify shared utilities and libraries used
   - **Test Files**: All test files for this feature
     - Unit tests, integration tests, e2e tests

7. **Track Unassigned Files**:
   - After each batch of features, update the "Unassigned Files" section in the master state file
   - List files not yet assigned to any feature
   - Update the coverage percentage
   - **Phase 1 is NOT complete until coverage reaches 100%** (every source file assigned to at least one feature)

8. **Update Master State After Each Session**:
   - Mark features as "Impl State ✅" in the Feature Inventory table
   - Update coverage metrics
   - Log session notes
   - **Complete feedback form for the session**

> **Note**: A file can appear in multiple features' inventories. "Files Created" indicates primary ownership. "Files Modified" and "Files Used" indicate shared involvement. A file is considered "assigned" when it appears in at least one feature's Code Inventory.

### Phase 2: Analysis

**Objective**: For each feature with an implementation state file, analyze patterns, dependencies, and design decisions.

> **Recommended batching**: Analyze features in the same category together to identify cross-cutting patterns.

9. **Analyze Implementation Patterns** (for each feature):
   - **Component Architecture**: How is the code structured?
     - Identify layers (data, service, UI, utilities)
     - Map component relationships
   - **Data Flow**: How does data move through the system?
     - Trace input → processing → output
     - Identify transformations and validations
   - **Error Handling**: How are errors managed?
     - Exception handling patterns
     - Error propagation and recovery
   - Document in Feature Implementation State file → Design Decisions section

10. **Document Dependencies** (for each feature):
    - **Feature Dependencies**: Cross-feature integrations, shared components
    - **System Dependencies**: External libraries and versions
    - **Code Dependencies**: Shared utilities, base classes, interfaces
    - Document in Feature Implementation State file → Dependencies section

11. **Map Tests to Implementation** (for each feature):
    - **Test Coverage**: What's tested vs. what exists?
    - **Test Types**: Unit, integration, widget, e2e?
    - **Test Gaps**: Critical paths without tests, edge cases not covered
    - Document in Feature Implementation State file → Test Files section

12. **Note Complexity Factors** (for features without tier assessments):
    - Number of files/components
    - Integration complexity
    - Data flow complexity
    - State management complexity
    - These notes feed into Phase 3 (Tier Assessment & Documentation)

13. **Update Master State After Each Session**:
    - Mark features as "Analyzed ✅" in the Feature Inventory table
    - Log session notes with key discoveries
    - **Complete feedback form for the session**

### Phase 3: Tier Assessment & Documentation Creation

**Objective**: For each feature, ensure it has a validated tier assessment, then create the required design documents based on that tier. Each feature is assessed and documented together before moving to the next.

> **Priority order**: Foundation (0.x.x) first → Tier 3 → Tier 2. Tier 1 features only need assessment validation (no documentation beyond implementation state file).

#### Per Feature: Assess

14. **Create or Validate Tier Assessment**:
    - **If no assessment exists**: Use [Feature Tier Assessment Task](../01-planning/feature-tier-assessment-task.md)
      - Base scores on ACTUAL code analysis from Phase 2 (not assumptions)
      - Use Feature Implementation State file as evidence
      - Create assessment artifact
    - **If assessment already exists**: Validate against analysis findings
      - Compare assessment tier with actual complexity discovered
      - If inaccurate, update the assessment
      - Document any discrepancies in master state session notes
    - Update Feature Tracking with tier assignment
    - Update master state: mark feature as "📊 Assessment Created"

#### Per Feature: Document (Tier 2+ only)

15. **Create Functional Design Document (Tier 2+)**:
    - Use [FDD Creation Task](../02-design/fdd-creation-task.md)
    - **Source**: Feature Implementation State file + existing code
    - **Approach**: Descriptive (what it does) not prescriptive (what it should do)
    - **Content**: Document actual functionality, user flows, business rules as implemented
    - **Mark**: Add "Retrospective" note in header
    - Update master state: FDD ✅ for this feature

16. **Create Technical Design Document (Tier 2+)**:
    - Use [TDD Creation Task](../02-design/tdd-creation-task.md)
    - **Source**: Feature Implementation State file (Component Architecture, Data Flow, Design Decisions)
    - **Approach**: Reverse-engineer from actual code structure
    - **Content**: Document actual architecture, components, patterns, implementation decisions
    - **Mark**: Add "Retrospective" note in header
    - Update master state: TDD ✅ for this feature

17. **Create Test Specification (Tier 3 only)**:
    - Use [Test Specification Creation Task](../03-testing/test-specification-creation-task.md)
    - **Source**: Feature Implementation State file → Test Files section
    - **Content**: Document existing tests, coverage, test scenarios
    - **Gaps**: Identify missing test coverage
    - **Mark**: Add "Retrospective" note in header
    - Update master state: Test Spec ✅

18. **Create Architecture Decision Records (Foundation 0.x.x)**:
    - Use [ADR Creation Task](../02-design/adr-creation-task.md)
    - **Source**: Feature Implementation State file → Design Decisions
    - **Content**: Document architectural patterns/decisions discovered in code
    - **Note**: Mark unknowns (alternatives considered, full rationale) clearly
    - Update master state: ADR ✅

19. **Create Conditional Documents** (if tier assessment indicates):
    - **API Design**: Use [API Design Task](../02-design/api-design-task.md) — document existing API contracts
    - **Database Schema**: Use [Database Schema Design Task](../02-design/database-schema-design-task.md) — document existing schema
    - **UI/UX Design**: Use [UI/UX Design Task](../02-design/ui-ux-design-task.md) — document existing UI components
    - Update master state for each document created

#### After Each Feature

20. **Update Feature Tracking**:
    - Add document links to appropriate columns as documents are created

21. **Update Master State After Each Session**:
    - Mark assessment and document completion status per feature
    - Log session notes
    - **Complete feedback form for the session**

### Phase 4: Finalization

**Objective**: Verify completeness, finalize all tracking, archive master state.

22. **Verify Codebase Coverage**:
    - All source files assigned to at least one feature? ✅
    - All features have Feature Implementation State files? ✅
    - Coverage metric = 100%? ✅

23. **Verify Documentation Completeness**:
    - All features have tier assessments (created or validated)? ✅
    - All Tier 2+ features have FDD and TDD? ✅
    - All Tier 3 features have Test Specifications? ✅
    - Foundation features have ADRs (where architectural decisions exist)? ✅
    - All conditional documents created per assessment? ✅
    - All documents marked "Retrospective"? ✅

24. **Verify Tracking Completeness**:
    - All document links in Feature Tracking? ✅
    - All Feature Implementation State files linked in Feature Tracking? ✅

25. **Update Documentation Map**: Add all new documents to [Documentation Map](../../documentation-map.md)

26. **Calculate Final Metrics**:
    - Total features documented
    - Total documents created (by type)
    - Total sessions and time spent
    - Coverage percentage achieved
    - Record in master state file Completion Summary section

27. **Archive Master State File**:
    - Move from `/temporary/` to `/temporary/archived/` (or `/temporary/old/`)

28. **🚨 MANDATORY**: Complete the [Task Completion Checklist](#task-completion-checklist) below
    - **Complete final feedback form for the session**

## Outputs

### Phase 1 Outputs: Feature Discovery & Code Assignment
- **Feature Implementation State Files** (PF-FIS-XXX) — one per feature, **PERMANENT**:
  - Location: `/doc/process-framework/state-tracking/features/[feature-id]-implementation-state.md`
  - Content: Complete code inventory (files created/modified/used), test files
  - Marked: `implementation_mode: Retrospective Analysis`

### Phase 2 Outputs: Analysis
- **Enriched Feature Implementation State Files** — updated with:
  - Design Decisions section populated
  - Dependencies section populated
  - Implementation Patterns documented

### Phase 3 Outputs: Tier Assessment & Documentation
- **Tier Assessment Artifacts** (ART-ASS-XXX):
  - Location: `/doc/process-framework/methodologies/documentation-tiers/assessments/`
  - Content: Evidence-based tier assessment per feature
- **Functional Design Documents** (PD-FDD-XXX) — Tier 2+ features
- **Technical Design Documents** (PD-TDD-XXX) — Tier 2+ features
- **Test Specifications** (PD-TST-XXX) — Tier 3 features
- **Architecture Decision Records** (PD-ADR-XXX) — Foundation 0.x.x features
- **API/DB/UI Design Documents** — Conditional per assessment
- All documents marked "Retrospective" in header

### Phase 4 Outputs: Finalization
- **Updated Feature Tracking** — All document links in appropriate columns
- **Updated Documentation Map** — All new documents registered
- **Archived Master State File** — Moved to `/temporary/archived/`

## State Tracking

### New State Files Created

- **Retrospective Master State File** (TEMPORARY) — Created in step 2:
  - Location: `/doc/process-framework/state-tracking/temporary/retrospective-master-state.md`
  - Purpose: Track codebase-wide retrospective progress across all sessions
  - Updated: After EVERY session
  - Lifecycle: Archived when all retrospective documentation is complete
  - Content: Phase progress, coverage metrics, feature inventory, session log
  - **Supersedes**: PF-STA-042 (comprehensive retrospective framework integration state)

- **Feature Implementation State Files** (PERMANENT) — Created in step 5, one per feature:
  - Location: `/doc/process-framework/state-tracking/features/[feature-id]-implementation-state.md`
  - Purpose: Permanent code inventory and analysis for each feature
  - Marked: `implementation_mode: Retrospective Analysis`
  - Lifecycle: Permanent (never archived)

### Existing State Files Updated

- [Feature Tracking](../../state-tracking/permanent/feature-tracking.md):
  - Feature entries added (Phase 1)
  - Tier assignments and document links added (Phase 3, ongoing)
  - Notes: "Retrospective documentation complete [date]" (Phase 4)

- [Documentation Map](../../documentation-map.md):
  - All new documents registered (Phase 4)

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

- [ ] **Phase 1 Complete: Feature Discovery & Code Assignment**
  - [ ] Master State File created in `/doc/process-framework/state-tracking/temporary/`
  - [ ] ALL features discovered and added to Feature Tracking
  - [ ] Feature Implementation State File created for EVERY feature (including Tier 1)
  - [ ] Code Inventory complete in every implementation state file
  - [ ] 100% codebase file coverage achieved (no unassigned files)
  - [ ] Phase 1 marked complete in master state file

- [ ] **Phase 2 Complete: Analysis**
  - [ ] Implementation patterns analyzed and documented for every feature
  - [ ] Dependencies identified and documented for every feature
  - [ ] Test coverage mapped for every feature
  - [ ] Phase 2 marked complete in master state file

- [ ] **Phase 3 Complete: Tier Assessment & Documentation Creation**
  - [ ] Every feature has a tier assessment (created or validated)
  - [ ] Feature Tracking updated with all tier assignments
  - [ ] **All Tier 2+ features**: FDD created, marked "Retrospective"
  - [ ] **All Tier 2+ features**: TDD created, marked "Retrospective"
  - [ ] **All Tier 3 features**: Test Specification created, marked "Retrospective"
  - [ ] **All Foundation 0.x.x features**: ADR created where architectural decisions exist, marked "Retrospective"
  - [ ] **Conditional documents**: API/DB/UI designs created where assessment indicates
  - [ ] All documents accurately reflect implemented code
  - [ ] All document links added to Feature Tracking
  - [ ] Phase 3 marked complete in master state file

- [ ] **Phase 4 Complete: Finalization**
  - [ ] [Feature Tracking](../../state-tracking/permanent/feature-tracking.md) verified complete with ALL document links
  - [ ] [Documentation Map](../../documentation-map.md) updated with all new documents
  - [ ] Final metrics calculated and recorded in master state
  - [ ] Master State File archived to `/temporary/archived/`

- [ ] **Feedback Forms**: Completed after EVERY session (not just at the end), using task ID "PF-TSK-060" and context "Retrospective Feature Documentation"

## Next Tasks

After completing the full retrospective documentation effort:

- [**Feature Implementation Task**](../04-implementation/feature-implementation-task.md) — For extending or modifying features after documentation
- [**Code Review Task**](../06-maintenance/code-review-task.md) — For validating existing implementation against documented design
- [**Technical Debt Assessment**](../cyclical/technical-debt-assessment-task.md) — For identifying and prioritizing technical debt discovered during analysis

## Metrics and Evaluation

- **Codebase Coverage**:
  - Percentage of source files assigned to features
  - Target: 100%

- **Feature Documentation Coverage**:
  - Features with complete documentation matching their tier
  - Track: Features documented / Total features requiring documentation
  - Target: 100% of Tier 2+ features documented

- **Documentation Quality**:
  - Completeness: All required sections filled
  - Accuracy: Documentation matches actual code
  - Usefulness: Documentation helps with maintenance/extension

- **Efficiency**:
  - Sessions per phase
  - Features processed per session
  - Documents created per session

- **Success Criteria**:
  - 100% codebase file coverage ✅
  - All features have Feature Implementation State files ✅
  - All Tier 2+ features have FDD and TDD ✅
  - All Tier 3 features have Test Specifications ✅
  - Foundation features have ADRs for architectural decisions ✅
  - All documents marked "Retrospective" ✅
  - All documents linked in Feature Tracking ✅

## Continuous Improvement

### Process Insights
- **Common Code Patterns**: Track recurring architectural patterns for future feature design
- **Documentation Gaps**: Identify types of information difficult to extract retrospectively (→ improve forward documentation)
- **Assessment Accuracy**: Note discrepancies between tier assessment scores and actual complexity discovered during analysis
- **Feature Boundary Challenges**: Document cases where feature boundaries were unclear or overlapping

### Quality Improvements
- **Documentation Templates**: Refine templates based on retrospective documentation challenges
- **Analysis Tools**: Develop tools/scripts to automate code inventory (git history analysis, dependency mapping)
- **Best Practices**: Document patterns that make features easy to document retrospectively

### Lessons Learned
- What made code analysis easy/difficult?
- What design decisions were well-documented in code vs. undocumented?
- What test coverage patterns were most helpful for documentation?
- How accurate were feature boundaries identified during discovery?

## Related Resources

### Core Resources (Must Read)
- [Retrospective Master State Template](../../templates/templates/retrospective-state-template.md) - **CRITICAL** template for tracking codebase-wide progress
- [Feature Implementation State Template](../../templates/templates/feature-implementation-state-template.md) - **CRITICAL** template used for per-feature code analysis
- [Feature Implementation State Tracking Guide](../../guides/guides/feature-implementation-state-tracking-guide.md) - Comprehensive guide for using the state template
- [Feature Tier Assessment Task](../01-planning/feature-tier-assessment-task.md) - Understanding feature complexity assessment
- [Documentation Tiers README](../../methodologies/documentation-tiers/README.md) - Tier definitions and documentation requirements

### Documentation Tasks (Phase 3)
- [FDD Creation Task](../02-design/fdd-creation-task.md) - Creating Functional Design Documents
- [TDD Creation Task](../02-design/tdd-creation-task.md) - Creating Technical Design Documents
- [Test Specification Creation Task](../03-testing/test-specification-creation-task.md) - Creating Test Specifications
- [ADR Creation Task](../02-design/adr-creation-task.md) - Creating Architecture Decision Records
- [API Design Task](../02-design/api-design-task.md) - Creating API Design documents
- [Database Schema Design Task](../02-design/database-schema-design-task.md) - Creating Database Schema designs
- [UI/UX Design Task](../02-design/ui-ux-design-task.md) - Creating UI/UX Design documents

### Supporting Resources
- [Task Transition Guide](../../guides/guides/task-transition-guide.md) - Understanding documentation workflow and information flow
- [Feature Tracking](../../state-tracking/permanent/feature-tracking.md) - Current feature status and documentation needs
- [Retrospective Documentation Concept](../../proposals/retrospective-documentation-concept.md) - Original concept (superseded)
- [Retrospective Task Redesign Summary](../../proposals/retrospective-task-redesign-summary.md) - Historical redesign notes (superseded by v2.0)
