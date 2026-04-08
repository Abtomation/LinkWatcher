---
id: PF-TSK-067
type: Process Framework
category: Task Definition
domain: agnostic
version: 1.2
created: 2026-02-19
updated: 2026-03-17
---

# Feature Request Evaluation

## Purpose & Context

This task evaluates incoming change requests to determine whether they represent new features or enhancements to existing features. For enhancements, it identifies the target feature (with human approval), assesses scope using practical criteria, and produces a scoped Enhancement State Tracking File that guides the Feature Enhancement task.

## AI Agent Role

**Role**: Change Request Analyst
**Mindset**: Classification-focused, scope-aware, existing-feature-knowledgeable
**Focus Areas**: Feature inventory analysis, scope assessment, execution planning, state file design
**Communication Style**: Present classification rationale clearly, propose target features with evidence, ask for human confirmation before proceeding

## When to Use

- When a change request arrives and it's unclear whether it's a new feature or an enhancement to an existing one
- When someone wants to add, modify, or extend functionality of an existing feature
- When a feature already exists in feature tracking but needs additional capability, behavioral changes, or scope expansion
- Before starting any modification to existing features — this task determines the right workflow

## Context Requirements

[View Context Map for this task](../../visualization/context-maps/01-planning/feature-request-evaluation-map.md)

- **Critical (Must Read):**

  - **Change Request** — The human partner's description of what needs to be added or changed, or a queued entry in [Feature Request Tracking](../../../doc/state-tracking/permanent/feature-request-tracking.md)
  - [Feature Request Tracking](../../../doc/state-tracking/permanent/feature-request-tracking.md) — Intake queue for product feature requests (check for "Submitted" entries)
  - [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) — Current feature inventory to identify existing features
  - [Feature Granularity Guide](../../guides/01-planning/feature-granularity-guide.md) — Defines what constitutes a well-scoped feature (used when classifying requests and validating new feature scope)
  - [Enhancement State Tracking Customization Guide](../../guides/04-implementation/enhancement-state-tracking-customization-guide.md) — Guide for customizing the Enhancement State Tracking File
  - [Visual Notation Guide](/process-framework/guides/support/visual-notation-guide.md) — For interpreting context map diagrams

- **Important (Load If Space):**

  - Feature State Files (`state-tracking/features/X.Y.Z-*-implementation-state.md`) — Implementation state of candidate target features (includes Dimension Profile for inheritance)
  - [Development Dimensions Guide](../../guides/framework/development-dimensions-guide.md) — Dimension definitions and applicability criteria for evaluating if enhancement scope changes dimension applicability
  - Existing Design Docs (FDD, TDD, ADR) associated with the target feature — For understanding current scope and design
  - [Enhancement Workflow Concept (PF-PRO-002)](../../../process-framework-local/proposals/old/enhancement-workflow-concept.md) — Full design rationale for this workflow

- **Reference Only (Access When Needed):**
  - [Feature Tier Assessment Task](feature-tier-assessment-task.md) — For routing new features to the correct workflow
  - [Task-Based Development Principles](../../ai-tasks.md#understanding-task-based-development) — For understanding framework principles

## Process

> **CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished!**
>
> **IMPORTANT: The AI agent must propose the target feature and wait for human approval before creating the state file.**
>
> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

### Phase 1: Classification

1. **Read the change request** — Understand what the human partner wants to add or change. Also check [Feature Request Tracking](../../../doc/state-tracking/permanent/feature-request-tracking.md) for queued requests with status "Submitted" — the human partner may point to a specific request ID, or the agent can propose which queued request to evaluate
2. **Review feature tracking** — Read `feature-tracking.md` to understand the current feature inventory. Make yourself familiar with some potential features by looking at the feature state tracking files.
3. **Classify the request** — Determine: is this a new feature or an enhancement to an existing feature? Apply the three validation tests from the [Feature Granularity Guide](../../guides/01-planning/feature-granularity-guide.md) to validate the scope of new features.
4. **🚨 CHECKPOINT**: Present classification decision with rationale to human partner for approval
   - **New Feature** → Continue to step 5a
   - **Enhancement** → Continue to step 5b

### Phase 2a: New Feature Routing

5a. **Route to existing workflow** — For new features:
   - Add the new feature to `feature-tracking.md` and note the assigned feature ID
   - Check [User Workflow Tracking](/doc/state-tracking/permanent/user-workflow-tracking.md) — does this feature create a new user workflow or extend an existing one? Update the workflow tracking file accordingly (add new workflows, add feature to existing workflows' Required Features). Set `workflows:` metadata in the new feature's implementation state file with the applicable WF-IDs.
   - **Update feature request tracking and create state file** — If this request originated from [Feature Request Tracking](../../../doc/state-tracking/permanent/feature-request-tracking.md), close it using [`Update-FeatureRequest.ps1`](../../scripts/update/Update-FeatureRequest.ps1). The script also creates the feature implementation state file and links it in feature-tracking:
     ```powershell
     cd process-framework/scripts/update
     .\Update-FeatureRequest.ps1 -RequestId "PD-FRQ-XXX" -Classification "NewFeature" -FeatureId "X.Y.Z" -FeatureName "Feature Name" -NewStatus "Completed" -Notes "Brief description"
     ```
     If the request did NOT originate from feature-request-tracking, create the state file manually using `New-FeatureImplementationState.ps1`.
   - **Source directory auto-creation**: When `New-FeatureImplementationState.ps1` runs, it automatically calls `New-SourceStructure.ps1 -Update` to create the feature's source directory and refresh the [Source Code Layout](/doc/technical/architecture/source-code-layout.md) directory tree (only if source-code-layout.md exists).
   - Inform the human partner that the existing workflow applies (Feature Tier Assessment → Design → Implementation)
   - This task is complete. Proceed to the Task Completion Checklist.

### Phase 2b: Enhancement Scoping

5b. **Propose target feature(s)** — Identify which existing feature(s) this enhances:
   - Locate the candidate feature(s) in `feature-tracking.md`
   - Read each feature's implementation state file to understand its current scope
   - Locate any existing design documentation (FDD, TDD, ADR)
   - Check [User Workflow Tracking](/doc/state-tracking/permanent/user-workflow-tracking.md) — does this enhancement affect any user workflows? If so, note the affected WF-IDs in the enhancement scope. If the enhancement changes which workflows the feature participates in, update the feature state file's `workflows:` metadata accordingly.
   - **Multi-feature requests**: If the change request affects multiple existing features, identify all of them. Present the full list at the checkpoint below.
6. **🚨 CHECKPOINT**: Present target feature proposal with rationale to human partner and wait for explicit approval before continuing
   - **For multi-feature requests**: Present all affected features and confirm with the human partner whether to proceed with separate Enhancement State Tracking Files for each, or whether the request should be split into independent evaluations. The default is **one state file per target feature**, each scoped to that feature's portion of the work, with cross-references linking the related state files.

7. **Assess enhancement scope** — After human approval of the target feature(s), evaluate each using practical criteria:
   - How many files are affected?
   - Can all work (implementation + doc updates + state tracking) be completed in a single session, or will it span multiple sessions?
   - Which design documents (FDD, TDD, ADR) need reviewing or amending?
   - Are new tests required, or only modifications to existing tests?
   - Does the enhancement affect the feature's public interface or only internal implementation?

8. **Evaluate dimension impact** — For each target feature:
   - Read the parent feature's **Dimension Profile** from its implementation state file
   - Evaluate if the enhancement scope **changes** dimension applicability (e.g., adds SE concerns because enhancement handles new user input, or adds DI concerns because enhancement introduces file write operations)
   - Note any dimensions that become newly Critical or Relevant, and any that are reduced
   - This information will be recorded in the Enhancement State Tracking File's Dimension Impact Assessment section

9. **Create Enhancement State Tracking File(s)** — Use the `New-EnhancementState.ps1` script for each target feature:
   ```powershell
   cd process-framework/scripts/file-creation
   New-EnhancementState.ps1 -TargetFeature "[Feature ID]" -EnhancementName "[Brief Name]" -Description "[Scope description]" -Dims "SE,PE,DI"
   ```
   The `-Dims` parameter populates the Dimension Impact Assessment section with inherited and adjusted dimensions from step 8.
   **Multi-feature requests**: Run the script once per target feature. In each generated state file, add a "Related Enhancement State Files" section listing the other state files created for the same change request, so the Feature Enhancement task can coordinate the work.

   Then customize each generated file following the [Enhancement State Tracking Customization Guide](../../guides/04-implementation/enhancement-state-tracking-customization-guide.md). The template contains 17 pre-defined workflow blocks mirroring the standard feature development workflow. Customization involves:
   - Filling in enhancement metadata (target feature, scope description, estimated sessions)
   - Building the existing documentation inventory (links to current FDD, TDD, ADR, state file)
   - Evaluating each workflow block and marking it **Applicable** or **Not Applicable** with rationale
   - Adding adaptation notes to applicable blocks explaining how the referenced task applies to this enhancement
   - Planning session boundaries (for multi-session enhancements)

### Phase 3: Finalization

10. **🚨 CHECKPOINT**: Present completed Enhancement State Tracking File (including Dimension Impact Assessment) to human partner for review before finalizing
11. **Update tracking files** — If this request originated from [Feature Request Tracking](../../../doc/state-tracking/permanent/feature-request-tracking.md), close the request and update feature-tracking using [`Update-FeatureRequest.ps1`](../../scripts/update/Update-FeatureRequest.ps1):
    ```powershell
    cd process-framework/scripts/update
    .\Update-FeatureRequest.ps1 -RequestId "PD-FRQ-XXX" -Classification "Enhancement" -FeatureId "X.Y.Z" -NewStatus "Completed" -EnhancementStateFile "Enhancement State File: [PF-STA-XXX](path/to/file.md)" -Notes "Enhancement State File created"
    ```
    This script moves the request to Completed in feature-request-tracking.md and sets the target feature's status to "🔄 Needs Revision" in feature-tracking.md with a link to the Enhancement State Tracking File.

    If the request did NOT originate from feature-request-tracking (e.g., ad-hoc human request), manually set the target feature's status to "🔄 Needs Revision" in `feature-tracking.md` and add a link to the Enhancement State Tracking File.
12. **MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Outputs

- **Classification Decision** — New feature or enhancement, with rationale communicated to human partner
- **Human-approved target feature** — AI agent's proposal confirmed by human partner (enhancement path only)
- **For new features**: New entry in `feature-tracking.md` + new feature implementation state file
- **For enhancements**: Customized Enhancement State Tracking File in `doc/state-tracking/temporary` with:
  - Target feature identification and existing doc inventory
  - Scope assessment using practical criteria
  - **Dimension Impact Assessment** — inherited dimensions from parent feature's profile, with any adjustments for the enhancement scope (new Critical/Relevant dimensions, reduced dimensions)
  - 17 workflow blocks each evaluated as Applicable/Not Applicable with rationale and adaptation notes
  - Session boundary planning (for multi-session enhancements)
  - **Updated feature tracking** — Target feature set to "🔄 Needs Revision" with link to state file (enhancement path only)

## State Tracking

The following state files must be updated as part of this task:

- [Feature Request Tracking](../../../doc/state-tracking/permanent/feature-request-tracking.md) — Update request status to Completed after classification (if request originated from this file)
- [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) — For new features: add new entry. For enhancements: set target feature status to "🔄 Needs Revision" with link to Enhancement State Tracking File
- **Enhancement State Tracking File** (created by this task) — In `doc/state-tracking/temporary`
- **Feature Implementation State File** — For new features: create new state file. For enhancements: no change (handled by Feature Enhancement task) — In `doc/state-tracking/features`

## MANDATORY Task Completion Checklist

**TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF**

Before considering this task finished:

- [ ] **Verify Classification**: Confirm change request has been classified
  - [ ] Classification decision (new feature or enhancement) communicated to human partner with rationale
  - [ ] For new features: new entry added to feature tracking + state file created → task complete
  - [ ] For enhancements: target feature proposed and human approval obtained

- [ ] **Verify Enhancement Outputs** (enhancement path only):
  - [ ] Enhancement State Tracking File created using `New-EnhancementState.ps1`
  - [ ] State file customized following Enhancement State Tracking Customization Guide
  - [ ] All 17 workflow blocks evaluated as Applicable/Not Applicable with rationale
  - [ ] Session boundary planning included (if multi-session)
  - [ ] Target feature status set to "🔄 Needs Revision" in feature tracking with link to state file

- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Completion Instructions](../../guides/framework/feedback-form-completion-instructions.md) for each tool used, using task ID "PF-TSK-067" and context "Feature Request Evaluation"

## Next Tasks

- [**Feature Enhancement**](../04-implementation/feature-enhancement.md) — Execute the Enhancement State Tracking File created by this task (enhancement path)
- [**Feature Tier Assessment**](feature-tier-assessment-task.md) — Assess complexity of new feature (new feature path)

## Related Resources

- [Feature Granularity Guide](../../guides/01-planning/feature-granularity-guide.md) — Defines what constitutes a well-scoped feature with validation tests and scaling guidance
- [Enhancement Workflow Concept (PF-PRO-002)](../../../process-framework-local/proposals/old/enhancement-workflow-concept.md) — Full design rationale for this workflow
- [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) — Current feature inventory
- [Enhancement State Tracking Customization Guide](../../guides/04-implementation/enhancement-state-tracking-customization-guide.md) — Guide for customizing state files
