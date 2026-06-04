---
id: PF-TSK-064
type: Process Framework
category: Task Definition
domain: agnostic
version: 1.9
created: 2026-02-17
updated: 2026-06-03
description: "Discover all features in existing codebase and assign every source file"
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

## Context Requirements

[View Context Map for this task](../../visualization/context-maps/00-setup/codebase-feature-discovery-map.md)

- **Critical (Must Read):**

  - **Prerequisite — [Project Initiation (PF-TSK-059)](project-initiation-task.md) outputs**: `project-config.json` (provides `paths.source_code`) and `source-code-layout.md` must already exist before this task runs — Step 7.f's source-structure script (`New-SourceStructure.ps1`) reads them. When adopting the framework into an existing codebase, run Project Initiation first.
  - [Retrospective Master State Template](../../templates/00-setup/retrospective-state-template.md) - Template for tracking codebase-wide progress
  - [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) - Feature status and tier assessments
  - [Assessment Guide](../../guides/01-planning/assessment-guide.md) - For performing tier assessments in Step 10
  - **Existing Codebase** - Source code, tests, and configuration

- **Important (Load If Space):**

  - [Script Development Quick Reference](../../guides/support/script-development-quick-reference.md) - PowerShell execution patterns and parameter checking (**always check script parameters with `-?` before running**)
  - [Feature Implementation State Tracking Guide](../../guides/04-implementation/feature-implementation-state-tracking-guide.md) - Guide for using the state template

- **Reference Only (Access When Needed):**
  - [Feature Dependencies](../../../doc/technical/architecture/feature-dependencies.md) - Understanding feature relationships
  - [Documentation Map](../../PF-documentation-map.md) - Overview of all framework documentation

## Feature Granularity

**Getting feature granularity right is the single most important outcome of this task.** Every downstream task — analysis, documentation, planning, implementation tracking — builds on the feature list produced here.

> **Read the [Feature Granularity Guide](../../guides/01-planning/feature-granularity-guide.md) before starting feature discovery.** It defines what constitutes a well-scoped feature, provides three validation tests, identifies common granularity mistakes in both directions, and offers scaling guidance by project size.

## Process

> **CRITICAL: This is a CODEBASE-WIDE, MULTI-SESSION task. Every session must start by reading the master state file and end by updating it.**
>
> **Three-phase structure**:
> - **Phase 1** (typically 1–2 sessions): Discover all features, add to Feature Tracking, audit existing project documentation.
> - **Phase 1b** (typically 1 session): Assess tiers for all discovered features and create Feature Implementation State files (lightweight for Tier 1, full for Tier 2/3).
> - **Phase 2** (typically many sessions): Process source files one by one in file-by-file order, writing inventory entries into the state files. Each session processes ~20–30 files.
>
> **FEEDBACK: Complete feedback forms at every phase boundary and at the end of every session.**
>
> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

### Preparation

1. **Check for Existing Master State File**:
   - Look in `../../../doc/state-tracking/temporary` for an existing retrospective master state file
   - **If found**: Read it, understand current phase and progress, continue from where the previous session left off
   - **If not found**: This is the first session — proceed to step 2

2. **Create Master State File** (first session only):
   - Use the automation script: `New-RetrospectiveMasterState.ps1 -ProjectName "[Project Name]"`
     - Script location: `../../scripts/file-creation/00-setup/New-RetrospectiveMasterState.ps1`
     - Automatically creates file at: `../../../doc/state-tracking/temporary/old/retrospective-master-state.md`
     - Automatically fills in project name, start date, and sets status to "DISCOVERY"
   - Template reference: [Retrospective Master State Template](../../templates/00-setup/retrospective-state-template.md)

3. **Survey the Project Structure & List All Unassigned Files** (first session only):
   - Scan the codebase directory structure (source directories, modules, packages)
   - Review existing documentation (README, architecture docs, HOW_IT_WORKS, etc.)
   - List ALL project source files (excluding `doc`, `.git/`, `__pycache__/`, `node_modules/`, and other non-source directories)
   - Record the complete file list in the master state file's "Unassigned Files" section — every file starts as unassigned
   - Record the total file count in master state file under Coverage Metrics
   - Identify natural feature boundaries (directories, modules, functional areas)
   - **🔍 Framework Improvement Observations**: While surveying the project, note any conventions, build tooling, code organization approaches, or developer experience patterns that the process framework doesn't currently capture. Record observations in the master state file's "Framework Improvement Observations" section.

4. **🚨 CHECKPOINT**: Present project structure overview, total file count, and initial observations about feature boundaries to human partner

5. **Audit Existing Project Documentation** (first session, alongside step 4):
   - Identify all non-source documentation files (markdown, txt, rst, etc.) **outside** `doc`
     - Root docs (README.md, HOW_IT_WORKS.md, CONTRIBUTING.md, etc.)
     - `docs` directory files
     - `tests/` documentation files (specifications/, audits/, etc.)
     - Any other project-level documentation
   - For each documentation file:
     a. Classify its **Type**: Architecture Overview, User Guide, Test Plan, CI/CD, Troubleshooting, Developer Guide, Configuration, Changelog, or Other
     b. For user-facing documents (User Guide, Troubleshooting, handbooks), also classify the **Diátaxis content type**: `tutorials` (guided learning), `how-to` (task-oriented), `reference` (facts/lookup), or `explanation` (concepts/why). This informs later placement when docs are migrated to the declared taxonomy. See [PD-id-registry.json](../../../doc/PD-id-registry.json) `PD-UGD.subdirectories.values` for the project's declared content types.
     c. Skim its content to determine which features it describes
     d. Note what content is potentially extractable for each relevant feature
   - Record the full inventory in the master state file's "Existing Documentation Inventory" section
   - Record which features each document relates to — this will be transferred to each feature's "Existing Project Documentation" table after state files are created in Step 10

   - **🔍 Framework Improvement Observations**: While auditing documentation, note any documentation practices, naming conventions, or content structure approaches that could improve the process framework. Record in the master state "Framework Improvement Observations" section.

   > **Scope**: Only audit files with substantive documentation about features, architecture, or processes. Skip placeholder READMEs, test fixture markdown files, and process framework documentation.

   > **Important**: The `doc` directory (including the process framework) is NOT part of the codebase to be inventoried. Only source code, tests, configuration, and scripts that implement the project's functionality are tracked.

### Execution

6. **Discover Features (Two-Phase Approach)**:

   > **Read the [Feature Granularity Guide](../../guides/01-planning/feature-granularity-guide.md) before starting this step.** The quality of the feature list determines the value of everything that follows.

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

7. **Consolidation Review (before creating state files)**:

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
   - Compare your feature count to the ranges in the [Feature Granularity Guide](../../guides/01-planning/feature-granularity-guide.md#scaling-guidance)
   - If significantly above range: look for merge opportunities
   - If significantly below range: look for features that are too broad

   **🚨 CHECKPOINT — Validate with human partner:**
   Present the final feature list with a one-line description per feature. Discuss any borderline cases. Get explicit approval on the list before creating state files.

   > **Why this matters:** Each feature generates a state file, and subsequent tasks create documentation proportional to the feature count. Getting this right here avoids significant rework later.

   **After consolidation, for each confirmed feature:**
   a. **Add entry via scripted atomic mutation** — Use [`Update-FeatureCategory.ps1`](../../scripts/update/Update-FeatureCategory.ps1) (PF-IMP-871 / PF-PRO-034 Phase 3a) for each confirmed feature. Call once per structural level that doesn't exist yet — outer levels first:
      ```powershell
      # Category 1 doesn't exist yet: create category, subgroup, then feature row (3 calls)
      cd process-framework/scripts/update
      .\Update-FeatureCategory.ps1 -Id "1" -Name "Customer Management"
      .\Update-FeatureCategory.ps1 -Id "1.2" -Name "Customer Read"
      .\Update-FeatureCategory.ps1 -Id "1.2.3" -Name "Read by ID"

      # Category 1.2 already exists from a previous feature: just add the new feature row
      .\Update-FeatureCategory.ps1 -Id "1.2.4" -Name "Read by Email"
      ```
      The script writes the `<details><summary>` block / `### N.X` subgroup heading / feature row at the correct level and chains to `New-TestInfrastructure.ps1 -Update`, which scaffolds the matching `test/automated/unit/<N>-<slug>/[<N.X>-<slug>/]` dirs and `test/audits/unit/...` mirrors. Leave Doc Tier empty if no assessment exists yet — `Update-FeatureCategory.ps1` defaults it to blank.

      (Per PF-PRO-002 / PF-IMP-760, feature-tracking.md is a lightweight cross-feature index: ID / Feature / Status / Priority / Doc Tier / Test Status / Dependencies / Notes — no per-design-document columns.)

   **Scaffold source directory structure:**
   f. Run the source structure scaffold script to create feature directories and generate the initial source layout doc:
      ```bash
      pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/00-setup/New-SourceStructure.ps1 -Scaffold -Confirm:\$false
      ```
      This creates: source root directory, shared/ directory, one directory per confirmed feature, package markers, and fills the Project Configuration + Directory Tree placeholder sections in [source-code-layout.md](../../../doc/technical/architecture/source-code-layout.md) (this file is created from the blueprint template during Project Initiation or must exist before running this script).
   g. Complete the **Dependency Flow** section in source-code-layout.md — document which feature directories may import from which
   h. Complete the **File Placement Decision Tree** section — adapt the generic tree from the [Source Code Layout Guide](../../guides/00-setup/source-code-layout-guide.md) to this project's features
   i. The scaffolded `src/<feature>/` directories stay **empty** at this stage — Discovery assigns every file to an owning feature but does not move it. Relocating the assigned legacy source into these directories (and the no-source-at-root conformance check that confirms it) is owned by [Codebase Source Migration (PF-TSK-091)](codebase-source-migration-task.md), which runs next and builds its queue from the per-feature File Inventories.

8. **Populate User Workflow Tracking File**:
   - Based on the discovered features, identify user-facing workflows — end-to-end paths a user follows that span multiple features (e.g., "file move → links updated" requires detection + parsing + updating)
   - Populate the blueprint-provided `/doc/state-tracking/permanent/user-workflow-tracking.md` (shipped with the framework as an empty scaffold — the `## Workflows` table and `## Workflow Details` section are already present). Add one entry per workflow with [`New-WorkflowEntry.ps1`](../../scripts/file-creation/03-testing/New-WorkflowEntry.ps1) (auto-assigns the WF-### ID), supplying:
     - Workflow name and description
     - Required features for each workflow
     - Priority (Impl Status and E2E Status are seeded by the script and later auto-derived by `Update-WorkflowTracking.ps1`)
   - Record which WF-IDs each feature participates in — the `workflows:` metadata field will be added to Feature Implementation State files after they are created in Step 10
   - This file enables workflow-level tracking across the project lifecycle

9. **🚨 CHECKPOINT**: Review workflow tracking with human partner before starting file-by-file inventory

10. **Assess Feature Tiers & Create Implementation State Files**:

    For each discovered feature, assess the complexity tier and create the appropriate state file. This must happen before code inventory (Phase 2) so state files exist to receive inventory entries.

    **Per feature:**
    a. Perform tier assessment following the [Feature Tier Assessment Task (PF-TSK-002)](../01-planning/feature-tier-assessment-task.md) process — base scores on initial codebase observations
    b. Create the assessment artifact using `New-Assessment.ps1`
    c. Create the Feature Implementation State file using the assessed tier to select the template:

    ```bash
    # Tier 1 (lightweight template)
    pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/04-implementation/New-FeatureImplementationState.ps1 -FeatureName "[name]" -FeatureId "X.Y.Z" -Lightweight -ImplementationMode "Retrospective Analysis" -Description "[description]" -Confirm:\$false

    # Tier 2/3 (full template)
    pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/04-implementation/New-FeatureImplementationState.ps1 -FeatureName "[name]" -FeatureId "X.Y.Z" -ImplementationMode "Retrospective Analysis" -Description "[description]" -Confirm:\$false
    ```

    - **Naming**: Use hyphenated names (e.g., `"Database-Management"` not `"Database Management"`). Spaces in filenames break markdown links in VS Code and other renderers. The script sanitizes spaces automatically, but hyphenated input is preferred for consistency.
    - Script location: `../../scripts/file-creation/04-implementation/New-FeatureImplementationState.ps1`
    - Automatically creates file at: `/doc/state-tracking/features/[X.Y.Z]-[name]-implementation-state.md`
    - Automatically links the file in [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md)
    d. Update Feature Tracking with tier assignment using `Update-FeatureTrackingFromAssessment.ps1`. **For retrospective onboarding** (this task), code already exists, so the post-assessment workflow is irrelevant — override the default with `-Status "🔎 Needs Test Scoping"` to land Tier 1 features at the appropriate retrospective status (PF-TSK-086 Test Scoping is the next applicable workflow step). Tier 2+ features may also need an override if their FDD/TDD will be created retrospectively in PF-TSK-066 — typically `-Status "🔎 Needs Test Scoping"` after Phase 3 documentation completes, or skip the script entirely and let PF-TSK-066 Step 13d set the post-Phase-3 status.

    Example for Tier 1 retrospective:
    ```powershell
    pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/update/Update-FeatureTrackingFromAssessment.ps1 -AssessmentId "PD-ASS-XXX" -Status "🔎 Needs Test Scoping" -Force
    ```

    > **Sub-components:** Capabilities classified as sub-components during consolidation review should be documented as sections or notes within their parent feature's state file.

11. **🚨 CHECKPOINT**: Review tier assessments and created state files with human partner before starting file-by-file inventory

12. **Populate Code Inventories — File-by-File** (Phase 2):

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
   - Add this file to the owning feature's **"File Inventory"** table with appropriate Role, Ownership, and Origin
   - Add **EVERY** referenced file from step (a) to the owning feature's **"File Inventory"** table
     - Include the import/reference location in Notes (e.g., `from .logging import get_logger`)
     - List specific functions/classes used where clear (e.g., `get_logger()`, `LinkDatabase.add_link()`)
   - Do **not** hold findings in context to batch-write later — the state file IS the map, not the context window. Write immediately after each file is analyzed.

   **d. Verify completeness before marking processed**
   - **Verify**: Re-read the import section of the file you just analyzed
   - Count: Does the number of entries in "Files Used by" match the number of internal project imports?
   - Cross-check: Is every `from .module import` statement documented in the state file?
   - **Only after verification**: mark the file ✅ in the master state's "Unassigned Files" table

   > **Batch the Status flips at session end**: collect the verified file paths during the session, then run a single bulk update at the session boundary (replaces N sequential Edit calls). Coverage Metrics is recalculated atomically by the script:
   >
   > ```bash
   > pwsh.exe -ExecutionPolicy Bypass -Command '& process-framework/scripts/update/Update-RetrospectiveMasterState.ps1 -StateFile "<path>" -FilePaths @("src/a.py","src/b.py","ui/c.py") -Confirm:$false'
   > ```
   >
   > If Coverage Metrics ever drifts from the table state (e.g., after a hand-edit), repair without flipping anything via `-RecalculateMetrics`.

   > **Scaling principle**: This approach scales to any codebase size. The context window holds only one file's analysis at a time. The state files accumulate entries across sessions and become the complete map by the end.

   > **Files can appear in multiple inventories**: A file may appear in many features' "Files Used by" tables. "Files Created by" indicates primary ownership. A file is considered "assigned" (for coverage purposes) when it appears in at least one feature's Code Inventory.

   > **Cross-Feature External Entries**: When a file is owned by feature X but referenced from feature Y's code, write the **canonical** description (role, behavior, key APIs) once in feature X's File Inventory with `Ownership: Owned`. In feature Y's File Inventory, add a **one-line abbreviated** row with `Ownership: External` that cites the canonical entry and names the specific consumption point — e.g., `External use; canonical entry in feature X. Imported by [Y/module.py](path) as <symbol>.` Do **not** duplicate the full description in consuming features — single source of truth keeps the description from drifting across rows.

   > **Test files**: When processing test files, assign them to the feature they primarily test. Add the test file to the owning feature's **"Test Files"** section in the Feature Implementation State file. Note the test type (unit, integration, parser, performance, e2e) and the test framework used. If a test file covers multiple features, note the cross-cutting nature — these may need a cross-cutting test specification during Retrospective Documentation Creation (PF-TSK-066).

   > **Documentation files**: When processing documentation files (markdown, etc.) during the file-by-file pass, if they were not already audited in step 4, classify them and add entries to the relevant feature's "Existing Project Documentation" table.

   > **Scope per session**: Process approximately 20–30 files per session. Stop at a clean boundary (end of a file, not mid-analysis), update the master state, and complete the feedback form before ending the session.

   > **This task is NOT complete until coverage reaches 100%** — every source file assigned to at least one feature.

### Finalization

13. **Update Master State After Each Session**:
   - Mark features as "Impl State ✅" in the Feature Inventory table
   - Update coverage metrics
   - Log session notes
   - **Complete feedback form for the session**

14. **Quality Verification (Before Marking Task Complete)**:
    - **Automated Validation**: Run the onboarding completeness script to verify 100% coverage and state file existence:
      ```bash
      pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/validation/Validate-OnboardingCompleteness.ps1 -Detailed
      ```
      Script location: `../../scripts/validation/Validate-OnboardingCompleteness.ps1`
      - Checks every source file is assigned to at least one feature's Code Inventory
      - Checks every feature in feature-tracking.md has a state file
      - **Must report PASS before proceeding**. Fix any unassigned files or missing state files first.
    - **Random Sampling**: Select 5-10 high-connectivity files (files with many dependencies) from different features
    - For each sampled file:
      - Re-read the actual import statements in the source file
      - Compare against the "Files Used by" entries in the corresponding Feature Implementation State file
      - Verify: Every import is documented; no incorrect entries exist
    - **If discrepancies found**: Fix them and document the pattern to prevent future occurrences
    - **Document the verification**: Add verification results to master state session notes

15. **🚨 CHECKPOINT**: Present quality verification results and final coverage metrics to human partner for approval

16. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Outputs

- **Retrospective Master State File** — Created (or updated) with progress
- **Tier Assessment Artifacts** (PD-ASS-XXX) — One per feature, created in Step 10
- **Feature Implementation State Files** (PD-FIS-XXX) — One per feature, **PERMANENT**:
  - Location: `/doc/state-tracking/features/[feature-id]-implementation-state.md`
  - Template: Lightweight (Tier 1) or Full (Tier 2/3) — selected based on tier assessment
  - Content: Complete code inventory (files created/modified/used), test files
  - Marked: `implementation_mode: Retrospective Analysis`
- **Updated Feature Tracking** — All features added with IDs, tiers, and descriptions
- **User Workflow Tracking** — Initial workflow definitions with feature-to-workflow mappings

## State Tracking

### New State Files Created

- **Retrospective Master State File** (TEMPORARY):
  - Location: `../../../doc/state-tracking/temporary/old/retrospective-master-state.md`
  - Purpose: Track codebase-wide retrospective progress across all onboarding sessions
  - Updated: After EVERY session
  - Lifecycle: Shared across all onboarding tasks (PF-TSK-064, PF-TSK-065, PF-TSK-066), archived when complete

- **Feature Implementation State Files** (PERMANENT) — one per feature:
  - Location: `/doc/state-tracking/features/[feature-id]-implementation-state.md`
  - Template: Lightweight (Tier 1) or Full (Tier 2/3)
  - Marked: `implementation_mode: Retrospective Analysis`
  - Lifecycle: Permanent (never archived)

### Existing State Files Updated

- [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) — Feature entries added with IDs and descriptions
- [User Workflow Tracking](../../../doc/state-tracking/permanent/user-workflow-tracking.md) — Created with workflow definitions and feature mappings

## ⚠️ MANDATORY Task Completion Checklist

**TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF**

- [ ] Master State File created in `../../../doc/state-tracking/temporary`
- [ ] ALL features discovered and added to Feature Tracking
- [ ] **Consolidation Review completed** (Step 6): Feature list validated against granularity criteria and approved by human partner
- [ ] **Tier assessments completed** (Step 10): Every feature has a tier assessment artifact
- [ ] **Feature Implementation State File created** for EVERY feature: Tier 1 uses lightweight template, Tier 2/3 uses full template
- [ ] Code Inventory complete in every Feature Implementation State file
- [ ] 100% codebase file coverage achieved (no unassigned files)
- [ ] `Validate-OnboardingCompleteness.ps1` reports PASS
- [ ] Existing Project Documentation audit complete — all non-source docs classified and mapped to features in master state "Existing Documentation Inventory" section
- [ ] User Workflow Tracking file created with workflow definitions, required features, and status columns
- [ ] `workflows:` metadata field added to all Feature Implementation State files
- [ ] **Quality Verification completed** (Step 14): Random sample of 5-10 high-connectivity files verified, all import statements match documentation
- [ ] Phase 1 marked complete in master state file
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Guide](../../guides/framework/feedback-form-guide.md) for each tool used, using task ID "PF-TSK-064" and context "Codebase Feature Discovery"
  - **Scope note**: Evaluate the Codebase Feature Discovery task (PF-TSK-064) and its tools (master state file, feature implementation state files), not the features you discovered.

## Next Tasks

- [**Codebase Source Migration (PF-TSK-091)**](codebase-source-migration-task.md) — Relocate the assigned legacy source into the scaffolded `src/<feature>/` directories, file-by-file with behavior-preserving verification. Builds its Source Migration Queue from the per-feature File Inventories produced here.
  - Followed by [**Codebase Feature Analysis (PF-TSK-065)**](codebase-feature-analysis.md) — analyzes implementation patterns, dependencies, and design decisions once the code is in its final `src/<feature>/` locations.

## Metrics and Evaluation

- **Codebase Coverage**: Percentage of source files assigned to features (Target: 100%)
- **Files Processed per Session**: Number of source files analyzed and written to state files per session (Target: ~20–30)
- **Efficiency**: Sessions needed to reach 100% coverage
- **Quality Verification**: Percentage of sampled files with complete and accurate dependency documentation (Target: 100%)

## Related Resources

- [Feature Granularity Guide](../../guides/01-planning/feature-granularity-guide.md) - Defines what constitutes a well-scoped feature with validation tests and scaling guidance
- [Retrospective Master State Template](../../templates/00-setup/retrospective-state-template.md) - Template for tracking codebase-wide progress
- [Feature Implementation State Template (Full)](../../templates/04-implementation/feature-implementation-state-template.md) - Full template for Tier 2/3 features
- [Feature Implementation State Template (Lightweight)](../../templates/04-implementation/feature-implementation-state-lightweight-template.md) - Lightweight template for Tier 1 features
- [Assessment Guide](../../guides/01-planning/assessment-guide.md) - For performing tier assessments in Step 10
- [Feature Implementation State Tracking Guide](../../guides/04-implementation/feature-implementation-state-tracking-guide.md) - Comprehensive guide for using the state template
- [Test Query Tool](../../scripts/test/test_query.py) - Query test files by feature, priority, and markers
- [Test Tracking](../../../test/state-tracking/permanent/test-tracking.md) - Test implementation status tracking (populated during PF-TSK-065)
- [Validate-OnboardingCompleteness.ps1](../../scripts/validation/Validate-OnboardingCompleteness.ps1) - Validates 100% source file coverage and feature state file existence
- [Onboarding Edge Cases Guide](../../guides/00-setup/onboarding-edge-cases.md) - Edge-case guidance for ambiguous file assignment, shared utilities, and confidence tagging
