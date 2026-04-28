---
id: PF-TSK-081
type: Process Framework
category: Task Definition
domain: agnostic
version: 1.0
created: 2026-03-27
updated: 2026-03-27
---

# User Documentation Creation

## Purpose & Context

Create or update user-facing product documentation (handbooks, quick-reference guides, README sections) when features introduce or change user-visible behavior. This task ensures that implemented functionality is discoverable and usable by end users, closing the gap between feature implementation and user awareness.

**Focus**: Produce clear, action-oriented documentation written from the user's perspective — not developer documentation or design docs (those are handled by implementation and design tasks).

## AI Agent Role

**Role**: Technical Writer
**Mindset**: User-empathetic, clarity-focused, action-oriented
**Focus Areas**: User workflows, discoverability, progressive disclosure (quick start → detailed reference), consistent terminology
**Communication Style**: Present documentation drafts with rationale for structure choices, ask about target audience assumptions and terminology preferences

## When to Use

- When a feature has status `📖 Needs User Docs` in [feature-tracking.md](/doc/state-tracking/permanent/feature-tracking.md) (set by [Performance & E2E Test Scoping (PF-TSK-086)](/process-framework/tasks/03-testing/performance-and-e2e-test-scoping-task.md) when the feature state file's `### User Documentation` section has status `❌ Needed`)
- When an enhancement changes existing user-facing behavior (modified commands, changed defaults, new options)
- When a documentation gap is discovered during release preparation, validation, or user feedback

**Trigger mechanism**: The feature implementation state file (Section 4: Documentation Inventory) has a `### User Documentation` subsection. During implementation planning (PF-TSK-044), this is set to `❌ Needed` for features with user-visible behavior, or `N/A` for internal features. After test scoping (PF-TSK-086), features with `❌ Needed` get status `📖 Needs User Docs` in feature-tracking.md. This task resolves the state file entry to `✅ Created` with links to the created handbook(s), and sets the feature to `🟢 Completed`. A feature may have multiple user-facing handbooks (e.g., quick-fix guide + detailed troubleshooting guide).

**Workflow position**: This task sits between Performance & E2E Test Scoping and Release & Deployment. After test scoping routes a feature to `📖 Needs User Docs`, this task creates the documentation and completes the feature.

## Context Requirements

<!-- Context map created in Session 4 -->

- **Critical (Must Read):**

  - **Feature implementation state file** (`doc/state-tracking/features`) — Understand what was implemented, key components, configuration options
  - **Existing handbooks directory** (`doc/user/handbooks`) — Understand current structure and content to avoid duplication
  - [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) — Identify which features need user documentation
  - [Visual Notation Guide](/process-framework/guides/support/visual-notation-guide.md) — For interpreting context map diagrams

- **Important (Load If Space):**

  - **Source code for the feature** — Verify CLI options, configuration keys, default values, error messages
  - **Existing README.md** — Check if feature is already partially documented there
  - **Test specifications** (`test/specifications/feature-specs`) — Understand expected behavior and edge cases

- **Reference Only (Access When Needed):**
  - **TDD/FDD for the feature** — Technical details that may need user-facing explanation
  - **Configuration examples** (`config-examples/`) — Existing config file examples to reference or extend

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished! 🚨**
>
> **⚠️ MANDATORY: Use the handbook creation script where indicated.**
>
> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

### Preparation

1. **Identify documentation scope**: Determine which feature(s) need user documentation by checking:
   - [Feature tracking](/doc/state-tracking/permanent/feature-tracking.md) for features at `📖 Needs User Docs` status
   - Feature implementation state files for `### User Documentation` entries with `❌ Needed` status
   - Enhancement state files for changed user-facing behavior
   - Specific feature request from human partner
2. **Audit existing documentation**: Review the handbooks directory and README.md to understand:
   - What user documentation already exists
   - Current directory structure and naming conventions
   - Whether the new content fits an existing handbook or needs a new one
3. **Read feature details**: Load the feature's implementation state file, source code (CLI options, config keys), and TDD/FDD to understand what needs to be documented from the user's perspective
4. **🚨 Review and refine Diátaxis content type analysis**: The feature state file's `### User Documentation` table already contains entries created by [Feature Implementation Planning (PF-TSK-044)](../04-implementation/feature-implementation-planning-task.md) — one row per identified content type with status `❌ Needed`. Your job here is to **validate and refine** that analysis now that implementation is complete, since implementation often reveals content types that were not foreseen during planning (or makes planned content types unnecessary).

   **Review questions for each existing row**:
   - Is this content type still needed given what was actually implemented?
   - Did the feature simplify so that a planned content type is now unnecessary?

   **Refinement questions for the feature as a whole**:
   - Did implementation surface additional content types not identified at planning time?
   - If yes, add new rows with status `❌ Needed` for those types.

   Apply the [Diátaxis Content Type Guide](../../guides/07-deployment/diataxis-content-type-guide.md) to validate and extend the rows. The guide defines the [decision matrix](../../guides/07-deployment/diataxis-content-type-guide.md#decision-matrix), [content type values](../../guides/07-deployment/diataxis-content-type-guide.md#content-type-values) (declared in [PD-id-registry.json](/doc/PD-id-registry.json) `PD-UGD.subdirectories.values`), [L2 topics](../../guides/07-deployment/diataxis-content-type-guide.md#l2-topics-optional) (optional project-declared groupings via `PD-UGD.topics.values`), and the [status taxonomy](../../guides/07-deployment/diataxis-content-type-guide.md#status-taxonomy).

   **Fresh-analysis fallback**: If the feature state file has only a single generic row (e.g., from a feature created before this taxonomy was adopted) or is missing entries entirely, perform the analysis from scratch using the guide's decision matrix — one row per identified content type, each `❌ Needed`.

   **Multi-session work**: If multiple content types are identified and creating all of them exceeds one session, complete one content type per session. The state file tracks per-type completion — the feature is `🟢 Completed` only when all rows reach `✅ Created`.

5. **🚨 CHECKPOINT**: Present documentation scope to human partner for approval. Include:
   - Which features need documentation
   - For each feature: the content types from PF-TSK-044's planning entries, plus any refinements (additions, removals, adjustments) with rationale
   - New vs. update decision per document
   - Session plan if multi-session

### Execution

6. **Create or update handbook** — for each content type identified in Step 4:
   - **For new handbooks**: Use the creation script, passing the Diátaxis `-ContentType` and (if applicable) `-Topic`:
     ```bash
     pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/07-deployment/New-Handbook.ps1 -HandbookName "Feature Name" -Description "What users can do with this feature" -ContentType "how-to" -Confirm:\$false
     ```
     Add `-Topic "<topic>"` when the project has declared L2 topics and the doc belongs in a specific topic group.
   - **For existing handbooks**: Edit the file directly, maintaining the established structure and style
7. **Write content appropriate to the Diátaxis type**:
   - **`tutorials/`** — Lead the reader step-by-step from zero to first success. Concrete, hands-on, no theory. Every step must succeed.
   - **`how-to/`** — Task-oriented. Start with the goal, list the practical steps, finish with the result. Assume a competent user.
   - **`reference/`** — Information-oriented. Complete, accurate, minimal interpretation. Facts the user needs to look up: CLI options, config keys, defaults, error codes, schemas.
   - **`explanation/`** — Understanding-oriented. Background, context, architecture, trade-offs, "why." No step-by-step instructions.
   - Verify all CLI options, config keys, and defaults against the actual source code regardless of content type
8. **Update README.md** (if applicable): Add or update feature entries in the main README's documentation table or feature list
9. **🚨 CHECKPOINT**: Present draft documentation to human partner for review — focus on accuracy, completeness, content-type fit (does each doc stay within its Diátaxis lane?), and clarity

### Finalization

10. **Update state files** for each handbook created, using the automation script:
    ```bash
    pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/update/Update-UserDocumentationState.ps1 -FeatureId "X.Y.Z" -HandbookName "Feature Name" -HandbookPath "doc/user/handbooks/how-to/filename.md" -HandbookId "PD-UGD-XXX" -ContentType "how-to" -Description "One-line description"
    ```
    This automates updates to:
    - Feature implementation state file (appends handbook row to `### User Documentation` table with Content Type column, updates per-type status)
    > **Note**: PD-documentation-map.md is already updated by `New-Handbook.ps1` — no separate action needed.
    >
    > **Multi-type features**: Run the update script once per created handbook. Feature status stays at `📖 Needs User Docs` until ALL identified content types are `✅ Created`.
11. **Update feature status to Completed** — only when all identified content types for the feature are complete:
    ```bash
    pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/update/Update-BatchFeatureStatus.ps1 -FeatureIds "<X.Y.Z>" -Status "🟢 Completed" -UpdateType "StatusOnly" -Force
    ```
12. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Outputs

- **New or updated handbook(s)** — User-facing documentation in `doc/user/handbooks/<content-type>/[<topic>/]` created via `New-Handbook.ps1` (for new) or edited directly (for updates). Content type values (Diátaxis standard: `tutorials`, `how-to`, `reference`, `explanation`) are declared in [PD-id-registry.json](/doc/PD-id-registry.json) under `PD-UGD.subdirectories.values`. L2 topic values are project-declared in `PD-UGD.topics.values` (optional).
- **Updated README.md** — Main project README updated with documentation links or feature descriptions (if applicable)
- **Updated feature tracking** — Feature state file or tracking entry reflects that user documentation exists

## Tools and Scripts

- **[New-Handbook.ps1](../../scripts/file-creation/07-deployment/New-Handbook.ps1)** — Create new handbook files with auto-assigned PD-UGD IDs
- **[Update-UserDocumentationState.ps1](../../scripts/update/Update-UserDocumentationState.ps1)** — Automate finalization state file updates (feature state file Documentation Inventory)
- **[New-FeedbackForm.ps1](../../scripts/file-creation/support/New-FeedbackForm.ps1)** — Create feedback forms for task completion

## State Tracking

The following state files are updated by `Update-UserDocumentationState.ps1`:

- **Feature implementation state files** (`doc/state-tracking/features`) — Handbook row appended to `### User Documentation` table, status updated to `✅ Created`

Updated by `New-Handbook.ps1` (automated at creation time):

- **[PD Documentation Map](../../../doc/PD-documentation-map.md)** — Handbook entry appended under User Handbooks section

Updated manually (Step 11):

- [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) — Feature status set from `📖 Needs User Docs` to `🟢 Completed` via `Update-BatchFeatureStatus.ps1`

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

Before considering this task finished:

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] Handbook(s) created or updated with accurate, user-focused content
  - [ ] All CLI options, config keys, and defaults verified against source code
  - [ ] Quick start section provides copy-paste ready commands
  - [ ] README.md updated if applicable
- [ ] **Update State Files**: Run `Update-UserDocumentationState.ps1` and verify
  - [ ] Feature implementation state file has handbook row in `### User Documentation` table with status `✅ Created`
  - [ ] PD-documentation-map.md has handbook entry under User Handbooks (automated by `New-Handbook.ps1`)
  - [ ] Feature tracking updated from `📖 Needs User Docs` to `🟢 Completed` via `Update-BatchFeatureStatus.ps1`
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Guide](../../guides/framework/feedback-form-guide.md) for each tool used, using task ID "PF-TSK-081" and context "User Documentation Creation"

## Next Tasks

- [**Release & Deployment**](release-deployment-task.md) — User documentation should be complete before release
- [**Code Review**](../06-maintenance/code-review-task.md) — Review documentation accuracy if changes are substantial

## Related Resources

- **Handbook template** — Created via `New-Handbook.ps1` using the handbook template
- **Existing handbooks** — `doc/user/handbooks` for style and structure reference
- **[Update-UserDocumentationState.ps1](../../scripts/update/Update-UserDocumentationState.ps1)** — Automates feature state file updates (Documentation Inventory)
- [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) — Source for identifying undocumented features
