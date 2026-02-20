---
id: PF-TSK-064
type: Process Framework
category: Task Definition
version: 1.4
created: 2026-02-17
updated: 2026-02-20
task_type: Onboarding
---

# Codebase Feature Discovery

## Purpose & Context

Systematically discover all features in an existing codebase, assign every source file to at least one feature, and create Feature Implementation State files with complete code inventories. This is the first step in adopting the process framework into an existing project.

This task produces the foundational inventory that subsequent onboarding tasks (Analysis, then Documentation Creation) build upon. It is complete when 100% of source files are assigned to features.

## AI Agent Role

**Role**: Technical Documentation Specialist & Codebase Archaeologist
**Mindset**: Systematic, thorough, reverse-engineering focused
**Focus Areas**: Codebase-wide inventory, feature boundary identification, code organization mapping
**Communication Style**: Report progress metrics, clarify feature boundaries, ask about design decisions

## When to Use

**Primary Use Case**: First step when adopting the process framework into an existing project
- Process framework has been copied into the project
- Project has existing features but no framework documentation
- Feature tracking is empty or incomplete
- Need to systematically inventory the entire codebase

**Secondary Use Case**: Resuming an ongoing discovery effort (load master state file)

## Context Requirements

**[📊 View Context Map for this task](../../visualization/context-maps/00-onboarding/codebase-feature-discovery-map.md)** - Visual guide showing all components and their relationships

- **Critical (Must Read):**

  - [Retrospective Master State Template](../../templates/templates/retrospective-state-template.md) - Template for tracking codebase-wide progress
  - [Feature Implementation State Template](../../templates/templates/feature-implementation-state-template.md) - Template for per-feature code analysis
  - [Feature Tracking](../../state-tracking/permanent/feature-tracking.md) - Feature status and tier assessments
  - **Existing Codebase** - Source code, tests, and configuration

- **Important (Load If Space):**

  - [Feature Implementation State Tracking Guide](../../guides/guides/feature-implementation-state-tracking-guide.md) - Comprehensive guide for using the state template

- **Reference Only (Access When Needed):**
  - [Feature Dependencies](../../../product-docs/technical/design/feature-dependencies.md) - Understanding feature relationships
  - [Documentation Map](../../documentation-map.md) - Overview of all framework documentation

## Feature Granularity

**Getting feature granularity right is the single most important outcome of this task.** Every downstream task — analysis, documentation, planning, implementation tracking — builds on the feature list produced here.

> **🚨 CRITICAL**: Read the [Feature Granularity Guide](../../guides/guides/feature-granularity-guide.md) before starting feature discovery. It defines what constitutes a well-scoped feature, provides three validation tests, identifies common granularity mistakes in both directions, and offers scaling guidance by project size.

## Process

> **CRITICAL: This is a CODEBASE-WIDE, MULTI-SESSION task. Every session must start by reading the master state file and end by updating it.**
>
> **Two-phase structure**:
> - **Phase 1** (typically 1–2 sessions): Discover all features, create all Feature Implementation State files, audit existing project documentation. No code inventory yet.
> - **Phase 2** (typically many sessions): Process source files one by one in file-by-file order, writing inventory entries immediately as each file is analyzed. Each session processes ~20–30 files.
>
> **FEEDBACK: Complete feedback forms at every phase boundary and at the end of every session.**

### Preparation

1. **Check for Existing Master State File**:
   - Look in `/doc/process-framework/state-tracking/temporary/` for an existing retrospective master state file
   - **If found**: Read it, understand current phase and progress, continue from where the previous session left off
   - **If not found**: This is the first session — proceed to step 2

2. **Create Master State File** (first session only):
   - Use the automation script: `New-RetrospectiveMasterState.ps1 -ProjectName "[Project Name]"`
     - Script location: `/doc/process-framework/scripts/file-creation/New-RetrospectiveMasterState.ps1`
     - Automatically creates file at: `/doc/process-framework/state-tracking/temporary/retrospective-master-state.md`
     - Automatically fills in project name, start date, and sets status to "DISCOVERY"
   - Template reference: [Retrospective Master State Template](../../templates/templates/retrospective-state-template.md)

3. **Survey the Project Structure & List All Unassigned Files** (first session only):
   - Scan the codebase directory structure (source directories, modules, packages)
   - Review existing documentation (README, architecture docs, HOW_IT_WORKS, etc.)
   - List ALL project source files (excluding `doc/`, `.git/`, `__pycache__/`, `node_modules/`, and other non-source directories)
   - Record the complete file list in the master state file's "Unassigned Files" section — every file starts as unassigned
   - Record the total file count in master state file under Coverage Metrics
   - Identify natural feature boundaries (directories, modules, functional areas)

4. **Audit Existing Project Documentation** (first session, alongside step 3):
   - Identify all non-source documentation files (markdown, txt, rst, etc.) **outside** `doc/process-framework/`
     - Root docs (README.md, HOW_IT_WORKS.md, CONTRIBUTING.md, CHANGELOG.md, etc.)
     - `docs/` directory files
     - `tests/` documentation files (README.md, TEST_PLAN.md, TEST_CASE_STATUS.md, etc.)
     - Any other project-level documentation
   - For each documentation file:
     a. Classify its **Type**: Architecture Overview, User Guide, Test Plan, CI/CD, Troubleshooting, Developer Guide, Configuration, Changelog, or Other
     b. Skim its content to determine which features it describes
     c. Note what content is potentially extractable for each relevant feature
   - Record the full inventory in the master state file's "Existing Documentation Inventory" section
   - For each affected feature: populate the "Existing Project Documentation" table in Section 4 of the feature's implementation state file, setting all entries to `Unconfirmed`

   > **Scope**: Only audit files with substantive documentation about features, architecture, or processes. Skip placeholder READMEs, test fixture markdown files, and process framework documentation.

   > **Important**: The `doc/` directory (including the process framework) is NOT part of the codebase to be inventoried. Only source code, tests, configuration, and scripts that implement the project's functionality are tracked.

### Execution

5. **Discover Features (Two-Phase Approach)**:

   > **Read the [Feature Granularity Guide](../../guides/guides/feature-granularity-guide.md) before starting this step.** The quality of the feature list determines the value of everything that follows.

   **Phase A — Top-Down Capability Discovery:**
   Start from what the system *does*, not from its file structure.

   - Read the project's entry points (main files, CLI commands, API routes) to understand the system's top-level capabilities
   - Review existing documentation (README, architecture docs, API docs) for described capabilities
   - Ask: "If I were explaining this system to someone, what are the major things it does?"
   - Draft an initial feature list at this level — these are your candidate features

   **Phase B — Bottom-Up Validation:**
   Walk the source tree to verify and refine.

   - For each source directory or module, check: does it fit into one of the candidate features?
   - If a file doesn't fit any candidate feature, it either:
     - Reveals a **missing feature** you didn't identify top-down → add it
     - Is a **shared utility** used by multiple features → assign to the feature it most closely supports, or create a "shared infrastructure" feature if substantial
   - If you find yourself splitting a candidate feature because the code is too diverse, that's valid — but apply the three tests (planning, conversation, independence) before splitting
   - If you find multiple candidate features living in a single file with no clear boundary, consider merging them

   **Output:** A reviewed candidate feature list ready for consolidation review.

6. **Consolidation Review (before creating state files)**:

   Review the candidate feature list systematically before committing to it. This review prevents creating state files that later need to be merged or deleted.

   **Check for over-granularization:**
   - Are any candidates implemented entirely within another candidate's source files? → Merge as a documented capability of the parent feature
   - Are there clusters of candidates that follow the same pattern and serve the same broader purpose? → Consider grouping into one feature with noted sub-components
   - Do any candidates fail all three feature tests (planning, conversation, independence)? → Demote to sub-component

   **Check for under-granularization:**
   - Does any candidate span multiple unrelated responsibilities? → Split if each part passes the three tests independently
   - Would a bug in one area of a candidate never affect another area of the same candidate? → Likely separate features
   - Is any candidate difficult to describe without listing several distinct capabilities? → Consider splitting

   **Check against scaling guidance:**
   - Compare your feature count to the ranges in the [Feature Granularity Guide](../../guides/guides/feature-granularity-guide.md#scaling-guidance)
   - If significantly above range: look for merge opportunities
   - If significantly below range: look for features that are too broad

   **Validate with human partner:**
   Present the final feature list with a one-line description per feature. Discuss any borderline cases. Agree on the list before creating state files.

   > **Why this matters:** Each feature generates a state file, and subsequent tasks create documentation proportional to the feature count. Getting this right here avoids significant rework later.

   **After consolidation, for each confirmed feature:**
   a. Add entry to [Feature Tracking](../../state-tracking/permanent/feature-tracking.md) (if not already there)
   b. Assign Feature ID (e.g., 1.2.3 or 0.1.1 for foundation)
   c. Add feature name and brief description
   d. Set status appropriately
   e. Leave tier and documentation columns empty if no assessment exists yet

7. **Create Feature Implementation State Files**:
   - Use the automation script: `New-FeatureImplementationState.ps1 -FeatureName "[name]" -FeatureId "[X.Y.Z]" -ImplementationMode "Retrospective Analysis" -Description "[description]"`
     - Script location: `/doc/process-framework/scripts/file-creation/New-FeatureImplementationState.ps1`
     - Automatically creates file at: `/doc/process-framework/state-tracking/features/[X.Y.Z]-[name]-implementation-state.md`
     - Automatically sets `implementation_mode: Retrospective Analysis` in metadata
     - Automatically links the file in [Feature Tracking](../../state-tracking/permanent/feature-tracking.md) in the ID column (when `-FeatureId` is provided)

   > **Sub-components:** Capabilities that were identified during discovery but classified as sub-components during consolidation review should be documented as sections or notes within their parent feature's state file. No information is lost — it's organized at the right level.

8. **Populate Code Inventories — File-by-File** (Phase 2):

   The master state's "Unassigned Files" list is the work queue. Process each file in order. For every file:

   **a. Deeply read the file**
   - Understand what it does and which feature created it
   - **Systematically extract ALL import/reference statements:**
     - For Python: `from X import Y` and `import X` statements at the top of the file
     - For JavaScript/TypeScript: `import ... from '...'` and `require('...')`
     - For other languages: language-specific import/include/require statements
     - Path strings in code (file paths, config references)
     - Subprocess calls, config file reads, log file paths
     - Any other file the code touches at runtime

   **b. Chase non-import references**
   - For any file referenced by path string or subprocess call (not just Python/language imports), actually read that referenced file to confirm what it is and which feature owns it
   - Do not skip this step — runtime references are as important as import dependencies for completeness

   **c. Immediately write findings to the relevant state file**
   - Add this file to the owning feature's **"Files Created by This Feature"** table
   - Add **EVERY** referenced file from step (a) to the owning feature's **"Files Used by This Feature"** table
     - Include the import/reference location (e.g., `from .logging import get_logger`)
     - List specific functions/classes used where clear (e.g., `get_logger()`, `LinkDatabase.add_link()`)
   - Do **not** hold findings in context to batch-write later — the state file IS the map, not the context window. Write immediately after each file is analyzed.

   **d. Verify completeness before marking processed**
   - **🚨 CRITICAL VERIFICATION**: Re-read the import section of the file you just analyzed
   - Count: Does the number of entries in "Files Used by" match the number of internal project imports?
   - Cross-check: Is every `from .module import` statement documented in the state file?
   - **Only after verification**: Set the file's Status column to ✅ in the master state's "Unassigned Files" table
   - Update the coverage percentage (processed files / total files)

   > **Scaling principle**: This approach scales to any codebase size. The context window holds only one file's analysis at a time. The state files accumulate entries across sessions and become the complete map by the end.

   > **Files can appear in multiple inventories**: A file may appear in many features' "Files Used by" tables. "Files Created by" indicates primary ownership. A file is considered "assigned" (for coverage purposes) when it appears in at least one feature's Code Inventory.

   > **Test files**: When processing test files, assign them to the feature they primarily test. Add the test file to the owning feature's **"Test Files"** section in the Feature Implementation State file. Note the test type (unit, integration, parser, performance, e2e) and the test framework used. If a test file covers multiple features, note the cross-cutting nature — these may need a cross-cutting test specification during Retrospective Documentation Creation (PF-TSK-066).

   > **Documentation files**: When processing documentation files (markdown, etc.) during the file-by-file pass, if they were not already audited in step 4, classify them and add entries to the relevant feature's "Existing Project Documentation" table.

   > **Scope per session**: Process approximately 20–30 files per session. Stop at a clean boundary (end of a file, not mid-analysis), update the master state, and complete the feedback form before ending the session.

   > **This task is NOT complete until coverage reaches 100%** — every source file assigned to at least one feature.

### Finalization

9. **Update Master State After Each Session**:
   - Mark features as "Impl State ✅" in the Feature Inventory table
   - Update coverage metrics
   - Log session notes
   - **Complete feedback form for the session**

10. **Quality Verification (Before Marking Task Complete)**:
    - **Random Sampling**: Select 5-10 high-connectivity files (files with many dependencies) from different features
    - For each sampled file:
      - Re-read the actual import statements in the source file
      - Compare against the "Files Used by" entries in the corresponding Feature Implementation State file
      - Verify: Every import is documented; no incorrect entries exist
    - **If discrepancies found**: Fix them and document the pattern to prevent future occurrences
    - **Document the verification**: Add verification results to master state session notes

11. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Outputs

- **Retrospective Master State File** — Created (or updated) with Phase 1 progress
- **Feature Implementation State Files** (PF-FIS-XXX) — one per feature, **PERMANENT**:
  - Location: `/doc/process-framework/state-tracking/features/[feature-id]-implementation-state.md`
  - Content: Complete code inventory (files created/modified/used), test files
  - Marked: `implementation_mode: Retrospective Analysis`
- **Updated Feature Tracking** — All features added with IDs and descriptions

## State Tracking

### New State Files Created

- **Retrospective Master State File** (TEMPORARY):
  - Location: `/doc/process-framework/state-tracking/temporary/retrospective-master-state.md`
  - Purpose: Track codebase-wide retrospective progress across all onboarding sessions
  - Updated: After EVERY session
  - Lifecycle: Shared across all onboarding tasks (PF-TSK-064, PF-TSK-065, PF-TSK-066), archived when complete

- **Feature Implementation State Files** (PERMANENT) — one per feature:
  - Location: `/doc/process-framework/state-tracking/features/[feature-id]-implementation-state.md`
  - Marked: `implementation_mode: Retrospective Analysis`
  - Lifecycle: Permanent (never archived)

### Existing State Files Updated

- [Feature Tracking](../../state-tracking/permanent/feature-tracking.md) — Feature entries added with IDs and descriptions

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

- [ ] Master State File created in `/doc/process-framework/state-tracking/temporary/`
- [ ] ALL features discovered and added to Feature Tracking
- [ ] **Consolidation Review completed** (Step 6): Feature list validated against granularity criteria and approved by human partner
- [ ] Feature Implementation State File created for EVERY feature (including Tier 1)
- [ ] Code Inventory complete in every implementation state file
- [ ] 100% codebase file coverage achieved (no unassigned files)
- [ ] Existing Project Documentation audit complete — all non-source docs classified and mapped to features in master state "Existing Documentation Inventory" section
- [ ] **Quality Verification completed** (Step 10): Random sample of 5-10 high-connectivity files verified, all import statements match documentation
- [ ] Phase 1 marked complete in master state file
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Completion Instructions](../../guides/guides/feedback-form-completion-instructions.md) for each tool used, using task ID "PF-TSK-064" and context "Codebase Feature Discovery"
  - **⚠️ IMPORTANT**: Evaluate the Codebase Feature Discovery task (PF-TSK-064) and its tools (master state file, feature implementation state files), not the features you discovered.

## Next Tasks

- [**Codebase Feature Analysis (PF-TSK-065)**](codebase-feature-analysis.md) — Analyze implementation patterns, dependencies, and design decisions for each discovered feature

## Metrics and Evaluation

- **Codebase Coverage**: Percentage of source files assigned to features (Target: 100%)
- **Files Processed per Session**: Number of source files analyzed and written to state files per session (Target: ~20–30)
- **Efficiency**: Sessions needed to reach 100% coverage
- **Quality Verification**: Percentage of sampled files with complete and accurate dependency documentation (Target: 100%)

## Related Resources

- [Feature Granularity Guide](../../guides/guides/feature-granularity-guide.md) - Defines what constitutes a well-scoped feature with validation tests and scaling guidance
- [Retrospective Master State Template](../../templates/templates/retrospective-state-template.md) - Template for tracking codebase-wide progress
- [Feature Implementation State Template](../../templates/templates/feature-implementation-state-template.md) - Template for per-feature code analysis
- [Feature Implementation State Tracking Guide](../../guides/guides/feature-implementation-state-tracking-guide.md) - Comprehensive guide for using the state template
- [Test Registry](/test/test-registry.yaml) - Registry of all test files mapped to features (populated during PF-TSK-065)
- [Test Implementation Tracking](../../state-tracking/permanent/test-implementation-tracking.md) - Test implementation status tracking (populated during PF-TSK-065)
