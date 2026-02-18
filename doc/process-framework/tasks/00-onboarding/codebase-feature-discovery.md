---
id: PF-TSK-064
type: Process Framework
category: Task Definition
version: 1.0
created: 2026-02-17
updated: 2026-02-17
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

## Process

> **CRITICAL: This is a CODEBASE-WIDE, MULTI-SESSION task. Every session must start by reading the master state file and end by updating it.**
>
> **Recommended batching**: Process one feature category per session (e.g., all foundation features, all parser features).
>
> **FEEDBACK: Complete feedback forms after EVERY session, not just at the end.**

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

   > **Important**: The `doc/` directory (including the process framework) is NOT part of the codebase to be inventoried. Only source code, tests, configuration, and scripts that implement the project's functionality are tracked.

### Execution

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

5. **Create Feature Implementation State Files**:
   - Use the automation script: `New-FeatureImplementationState.ps1 -FeatureName "[name]" -FeatureId "[X.Y.Z]" -ImplementationMode "Retrospective Analysis" -Description "[description]"`
     - Script location: `/doc/process-framework/scripts/file-creation/New-FeatureImplementationState.ps1`
     - Automatically creates file at: `/doc/process-framework/state-tracking/features/[X.Y.Z]-[name]-implementation-state.md`
     - Automatically sets `implementation_mode: Retrospective Analysis` in metadata
     - Automatically links the file in [Feature Tracking](../../state-tracking/permanent/feature-tracking.md) in the ID column (when `-FeatureId` is provided)

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

7. **Update Unassigned Files**:
   - After each batch of features, remove newly assigned files from the "Unassigned Files" section in the master state file
   - Update the coverage percentage (assigned files / total files)
   - **This task is NOT complete until coverage reaches 100%** (every source file assigned to at least one feature)

> **Note**: A file can appear in multiple features' inventories. "Files Created" indicates primary ownership. "Files Modified" and "Files Used" indicate shared involvement. A file is considered "assigned" when it appears in at least one feature's Code Inventory.

### Finalization

8. **Update Master State After Each Session**:
   - Mark features as "Impl State ✅" in the Feature Inventory table
   - Update coverage metrics
   - Log session notes
   - **Complete feedback form for the session**

9. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

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
- [ ] Feature Implementation State File created for EVERY feature (including Tier 1)
- [ ] Code Inventory complete in every implementation state file
- [ ] 100% codebase file coverage achieved (no unassigned files)
- [ ] Phase 1 marked complete in master state file
- [ ] **Feedback Forms**: Completed after EVERY session, using task ID "PF-TSK-064" and context "Codebase Feature Discovery"

## Next Tasks

- [**Codebase Feature Analysis (PF-TSK-065)**](codebase-feature-analysis.md) — Analyze implementation patterns, dependencies, and design decisions for each discovered feature

## Metrics and Evaluation

- **Codebase Coverage**: Percentage of source files assigned to features (Target: 100%)
- **Features per Session**: Number of features inventoried per session
- **Efficiency**: Sessions needed to reach 100% coverage

## Related Resources

- [Retrospective Master State Template](../../templates/templates/retrospective-state-template.md) - Template for tracking codebase-wide progress
- [Feature Implementation State Template](../../templates/templates/feature-implementation-state-template.md) - Template for per-feature code analysis
- [Feature Implementation State Tracking Guide](../../guides/guides/feature-implementation-state-tracking-guide.md) - Comprehensive guide for using the state template
