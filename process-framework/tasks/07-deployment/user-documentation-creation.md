---
id: PF-TSK-081
type: Process Framework
category: Task Definition
domain: agnostic
version: 1.0
created: 2026-03-27
updated: 2026-03-27
task_type: Discrete
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

- After a feature reaches "Implemented" or "Completed" status and has user-visible behavior (new CLI options, configuration, workflows)
- When an enhancement changes existing user-facing behavior (modified commands, changed defaults, new options)
- When a documentation gap is discovered during release preparation, validation, or user feedback
- When the handbook directory needs restructuring to accommodate new content areas

**Trigger mechanism**: The feature implementation state file (Section 4: Documentation Inventory) tracks a `User Documentation` entry. When a feature is implemented with user-visible behavior, this entry should be set to `❌ Needed`. This task resolves it to `✅` with links to the created handbook(s). A feature may have multiple user-facing handbooks (e.g., quick-fix guide + detailed troubleshooting guide).

**Workflow position**: This task sits between Code Review and Release & Deployment. After implementation and code review are complete, check whether the feature needs user documentation before proceeding to release.

## Context Requirements

<!-- Context map created in Session 4 -->

- **Critical (Must Read):**

  - **Feature implementation state file** (`doc/product-docs/state-tracking/features/`) — Understand what was implemented, key components, configuration options
  - **Existing handbooks directory** (`doc/product-docs/user/handbooks/`) — Understand current structure and content to avoid duplication
  - [Feature Tracking](../../../doc/product-docs/state-tracking/permanent/feature-tracking.md) — Identify which features need user documentation
  - [Visual Notation Guide](/process-framework/guides/support/visual-notation-guide.md) — For interpreting context map diagrams

- **Important (Load If Space):**

  - **Source code for the feature** — Verify CLI options, configuration keys, default values, error messages
  - **Existing README.md** — Check if feature is already partially documented there
  - **Test specifications** (`test/specifications/feature-specs/`) — Understand expected behavior and edge cases

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
   - Feature tracking for features at "Implemented" status without corresponding handbook entries
   - Enhancement state files for changed user-facing behavior
   - Specific feature request from human partner
2. **Audit existing documentation**: Review the handbooks directory and README.md to understand:
   - What user documentation already exists
   - Current directory structure and naming conventions
   - Whether the new content fits an existing handbook or needs a new one
3. **Read feature details**: Load the feature's implementation state file, source code (CLI options, config keys), and TDD/FDD to understand what needs to be documented from the user's perspective
4. **🚨 CHECKPOINT**: Present documentation scope (which features, new vs. update, proposed handbook structure) to human partner for approval

### Execution

5. **Evaluate handbook directory structure**: Before creating content, assess whether the current `doc/product-docs/user/handbooks/` organization supports the new content:
   - Are handbooks organized by topic (setup, usage, troubleshooting, configuration)?
   - Does the new feature fit an existing category or need a new one?
   - If restructuring is needed, propose the new structure at the checkpoint
6. **Create or update handbook**:
   - **For new handbooks**: Use the creation script:
     ```bash
     cd process-framework/scripts/file-creation/07-deployment && pwsh.exe -ExecutionPolicy Bypass -Command '& .\New-Handbook.ps1 -HandbookName "Feature Name" -Description "What users can do with this feature" -Confirm:$false'
     ```
   - **For existing handbooks**: Edit the file directly, maintaining the established structure and style
7. **Write user-focused content**: For each feature being documented, include:
   - **Quick start** — Minimal steps to use the feature (copy-paste ready)
   - **Configuration** — All relevant settings with defaults and examples
   - **Common workflows** — Step-by-step guides for typical use cases
   - **Troubleshooting** — Common issues and solutions
   - Verify all CLI options, config keys, and defaults against the actual source code
8. **Update README.md** (if applicable): Add or update feature entries in the main README's documentation table or feature list
9. **🚨 CHECKPOINT**: Present draft documentation to human partner for review — focus on accuracy, completeness, and clarity

### Finalization

10. **Update state files** using the automation script:
    ```bash
    cd process-framework/scripts/update && pwsh.exe -ExecutionPolicy Bypass -Command '& .\Update-UserDocumentationState.ps1 -FeatureId "X.Y.Z" -HandbookName "Feature Name" -HandbookPath "doc/product-docs/user/handbooks/filename.md" -HandbookId "PD-UGD-XXX" -Description "One-line description"'
    ```
    This automates updates to:
    - Feature implementation state file (appends handbook row to Documentation Inventory)
    - documentation-map.md (appends entry under User Handbooks section)
11. **Update feature-tracking.md** manually if a User Docs column exists
12. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Outputs

- **New or updated handbook(s)** — User-facing documentation in `doc/product-docs/user/handbooks/` created via `New-Handbook.ps1` (for new) or edited directly (for updates)
- **Updated README.md** — Main project README updated with documentation links or feature descriptions (if applicable)
- **Updated feature tracking** — Feature state file or tracking entry reflects that user documentation exists

## Tools and Scripts

- **[New-Handbook.ps1](../../scripts/file-creation/07-deployment/New-Handbook.ps1)** — Create new handbook files with auto-assigned PD-UGD IDs
- **[Update-UserDocumentationState.ps1](../../scripts/update/Update-UserDocumentationState.ps1)** — Automate finalization state file updates (feature state file + documentation-map.md)
- **[New-FeedbackForm.ps1](../../scripts/file-creation/support/New-FeedbackForm.ps1)** — Create feedback forms for task completion

## State Tracking

The following state files are updated by `Update-UserDocumentationState.ps1`:

- **Feature implementation state files** (`doc/product-docs/state-tracking/features/`) — Handbook row appended to Documentation Inventory table
- **[Documentation Map](../../documentation-map.md)** — Handbook entry appended under User Handbooks section

Manually updated:

- [Feature Tracking](../../../doc/product-docs/state-tracking/permanent/feature-tracking.md) — Update documentation status for documented features (if a "User Docs" column exists, mark as ✅)

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

Before considering this task finished:

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] Handbook(s) created or updated with accurate, user-focused content
  - [ ] All CLI options, config keys, and defaults verified against source code
  - [ ] Quick start section provides copy-paste ready commands
  - [ ] README.md updated if applicable
- [ ] **Update State Files**: Run `Update-UserDocumentationState.ps1` and verify
  - [ ] Feature implementation state file has handbook row in Documentation Inventory
  - [ ] documentation-map.md has handbook entry under User Handbooks
  - [ ] Feature tracking updated manually if User Docs column exists
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Completion Instructions](../../guides/framework/feedback-form-completion-instructions.md) for each tool used, using task ID "PF-TSK-081" and context "User Documentation Creation"

## Next Tasks

- [**Release & Deployment**](release-deployment-task.md) — User documentation should be complete before release
- [**Code Review**](../06-maintenance/code-review-task.md) — Review documentation accuracy if changes are substantial

## Related Resources

- **Handbook template** — Created via `New-Handbook.ps1` using the handbook template
- **Existing handbooks** — `doc/product-docs/user/handbooks/` for style and structure reference
- **[Update-UserDocumentationState.ps1](../../scripts/update/Update-UserDocumentationState.ps1)** — Automates finalization state updates
- [Feature Tracking](../../../doc/product-docs/state-tracking/permanent/feature-tracking.md) — Source for identifying undocumented features
