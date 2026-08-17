---
id: PF-TSK-077
type: Process Framework
category: Task Definition
domain: agnostic
version: 1.2
created: 2026-03-23
updated: 2026-06-12
description: "Plan validation rounds by selecting features and applicable dimensions, create tracking state file"
complexity: simple
use_when: >-
  **ENTRY POINT for validation rounds** — select features, evaluate dimension applicability, create tracking state file, plan session sequence. Triggers: 'start a validation round', 'plan validation', 'prepare for validation'.
triggers:
  - "start a validation round"
  - "plan validation"
  - "prepare for validation"
automation: semi
scripts:
  - ../../scripts/file-creation/05-validation/New-ValidationTracking.ps1
trigger_status:
  - raw: "_(user request)_"
output_status:
  - raw: "Validation tracking state file → feature × dimension matrix created"
next_tasks:
  - task: dimension-validation-task.md
    condition: "Run once per planned dimension; the dispatcher's table maps each dimension to its path file"
---

# Validation Preparation

> **▶ Execute this task under the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md).** This file holds only this task's specific content; the universal contract every task shares lives once in the protocol and is mandatory here.

## Purpose & Context

Plans a validation round by selecting features to validate, evaluating which validation dimensions apply to each feature, creating the validation tracking state file with the feature×dimension matrix, and planning the session sequence for executing dimension tasks. This task ensures that validation scope is deliberate and traceable rather than ad-hoc.

## AI Agent Role

**Role**: Quality Assurance Planner
**Mindset**: Systematic, scope-aware, risk-based prioritization
**Focus Areas**: Feature maturity assessment, dimension applicability evaluation, session planning, validation coverage
**Communication Style**: Present dimension selection rationale per feature, ask about project-specific quality priorities, recommend validation sequence based on dependencies between dimensions

## Context Requirements

- **Critical (Must Read):**

  - **Feature Validation Guide** - [Feature Validation Guide](../../guides/05-validation/feature-validation-guide.md) - Comprehensive guide including the Dimension Catalog with applicability criteria
  - **Feature Tracking** - [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) - Current status of features to determine validation scope
  - **Validation Tracking Template** - [Validation Tracking Template](../../templates/05-validation/validation-tracking-template.md) - Template for creating the feature×dimension tracking matrix

- **Important (Load If Space):**

  - **Feature Implementation State Files** - [Feature States Directory](../../../doc/state-tracking/features) - Implementation status details per feature, including **Dimension Profiles** (primary source for dimension applicability)
  - **Development Dimensions Guide** - [Development Dimensions Guide](../../guides/framework/development-dimensions-guide.md) - Dimension definitions and applicability criteria
  - **Technical Design Documents** - [TDD Directory](../../../doc/technical/tdd) - Feature specifications for understanding what each feature does
  - **Previous Validation Reports** - [Validation Reports](../../../doc/validation/reports) - Prior validation results for context

- **Reference Only (Access When Needed):**
  - **Dimension Task Definitions** - [05-validation tasks](../05-validation/) - Individual dimension task definitions for understanding validation criteria
  - **ID Registry** - [PD ID Registry](../../PF-id-registry.json) - For understanding document ID assignments

## Process

> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

### Preparation

1. **Identify Validation Trigger**: Document why this validation round is being initiated (milestone, new features, periodic review, specific concern)
2. **Review Feature Tracking**: Examine [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) to identify features eligible for validation — typically features with status "Implemented", "Testing", or "Complete"
3. **Select Feature Scope**: Choose which features to include in this validation round based on:
   - Implementation completeness (features must be sufficiently implemented to validate)
   - Priority and risk level (high-risk features first)
   - Previous validation coverage (features not yet validated, or validated long ago)
   - Practical session budget (how many validation sessions are planned)
4. **🚨 CHECKPOINT**: Present selected feature scope with rationale to human partner for approval before dimension evaluation

### Execution

5. **Review Dimension Catalog**: Consult the Dimension Catalog in the [Feature Validation Guide](../../guides/05-validation/feature-validation-guide.md) to understand all available validation dimensions and their applicability criteria
6. **Evaluate Dimension Applicability**: For each selected feature, determine which dimensions apply:

   **Primary source**: Read the feature's **Dimension Profile** from its [implementation state file](../../../doc/state-tracking/features). If a profile exists, use it as the starting point — the profile was evaluated during Feature Implementation Planning (PF-TSK-044) with full design context. Verify and update if implementation has changed the picture.

   **Fallback** (legacy features without profiles): Evaluate from scratch using the criteria below.

   | Dimension | Apply When |
   |-----------|-----------|
   | Architectural Consistency (AC) | Universal — always apply |
   | Code Quality & Standards (CQ) | Universal — always apply |
   | Integration & Dependencies (ID) | Universal — always apply |
   | Documentation Alignment (DA) | Universal — always apply |
   | Extensibility & Maintainability (EM) | Apply for growing/evolving projects |
   | Security & Data Protection (SE) | Apply when feature handles user input, auth, sensitive data, or external APIs |
   | Performance & Scalability (PE) | Apply when feature involves I/O, large data, real-time processing, or production load |
   | Observability (OB) | Apply when feature has background processes, async operations, or production monitoring needs |
   | Accessibility / UX Compliance (UX) | Apply when feature has UI components or user-facing interactions |
   | Data Integrity (DI) | Apply when feature modifies, transforms, or migrates data |

   Mark dimensions as **N/A** for features where they don't apply, with brief rationale.

   > **Note**: AI Agent Continuity is a standalone validation task (run via [Dimension Validation](dimension-validation-task.md), the [ai-agent-continuity path](ai-agent-continuity-validation-path.md)) — it is not a development dimension and does not appear in feature Dimension Profiles. Include it in validation rounds for projects using AI-assisted development workflows.

   > **Re-validation shortcut**: When running a subsequent round on the same feature set and dimension applicability is unchanged (no new features added, no feature scope changes, no new dimensions adopted by the framework), reference the prior round's validated matrix instead of re-evaluating from scratch. State "Dimension applicability unchanged from Round N — see [prior tracking file]" and skip to Step 7.

   > **Feedback loop**: If validation discovers that a dimension was incorrectly marked N/A during planning, update the feature's Dimension Profile in its implementation state file for future work.

7. **🤖 AUTOMATED - Create Validation Tracking State File**: Use the automation script to generate the tracking file:

   ```powershell
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/05-validation/New-ValidationTracking.ps1 -RoundNumber [N] -Description "[Round focus]" -ArchivePriorRound
   ```

   The script auto-populates:
   - **Feature Scope** table from feature-tracking.md (all active features)
   - **Prior round quality scores** (R(N-1) Score column) from the previous round's tracking file
   - **Prior Round reference** link in Purpose & Context section
   - `-ArchivePriorRound` moves the prior round's tracking file to `archive/`

   Then customize:
   - Review auto-populated feature rows for accuracy (remove features not in scope, add Workflow Cohort)
   - Add/remove dimension columns based on which dimensions are selected
   - Mark N/A cells for features where specific dimensions don't apply
8. **Plan Session Sequence**: Determine the order of dimension validation sessions:
   - Consider dimension dependencies (e.g., Architectural Consistency before Integration Dependencies)
   - Group features into batches of 2-3 per dimension session
   - **Workflow cohort grouping**: When possible, batch features that co-participate in the same user workflow (per [User Workflow Tracking](../../../doc/state-tracking/permanent/user-workflow-tracking.md)). This enables the validator to assess cross-feature workflow effects within a single session rather than discovering them across separate sessions. Annotate cohorts in the validation tracking file's Feature Scope table (e.g., "Cohort: WF-001").
   - Estimate total sessions needed
   - **One batch per session** — see [AI Agent Session Management](../../ai-tasks.md#-ai-agent-session-management) for the rationale
9. **🚨 CHECKPOINT**: Present the complete validation plan to human partner for approval:
   - Feature×dimension matrix (which features get which dimensions)
   - Dimension selection rationale for non-obvious choices
   - Session sequence and estimated session count
   - Any features or dimensions deferred with explanation

### Finalization

10. **Record Validation Plan**: Ensure the validation tracking state file captures:
    - Validation trigger and rationale
    - Feature scope selection reasoning
    - Dimension applicability decisions with rationale for N/A markings
    - Planned session sequence
11. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Outputs

- **Validation Tracking State File** - Feature×dimension tracking matrix in `state-tracking/temporary/`, customized from the validation tracking template with selected features and applicable dimensions
- **Validation Plan** - Session sequence with feature batches per dimension, documented in the tracking state file

## State Tracking

The following state files must be updated as part of this task:

- **Validation Tracking State File** - Create new file in `state-tracking/temporary/` from [Validation Tracking Template](../../templates/05-validation/validation-tracking-template.md)
- [Product Documentation Map](../../../doc/PD-documentation-map.md) - Generated, DO-NOT-EDIT (`Build-DocumentationMap.ps1 -Tree PD`, PF-PRO-050); no manual entry — regeneration picks up any indexed doc's `description:`

## ⚠️ MANDATORY Task Completion Checklist

> Completion discipline, output verification, and the feedback form are governed by the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md) (Phase C). The items below are the **task-specific** verifications that plug into it.

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] Validation tracking state file created with feature×dimension matrix
  - [ ] All dimension applicability decisions documented with rationale
  - [ ] Session sequence planned with feature batches per dimension
- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] Validation tracking state file created in `state-tracking/temporary/`
  - [ ] [Product Documentation Map](../../../doc/PD-documentation-map.md) regenerated via `Build-DocumentationMap.ps1 -Tree PD` if a PD-map-indexed doc was added (generated DO-NOT-EDIT projection)
- [ ] **Feedback form** completed per the [Task Execution Protocol → Feedback step](../../guides/framework/task-execution-protocol-guide.md#feedback-step) — task ID `PF-TSK-077`, context "Validation Preparation".

## File Operations

| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | Validation Tracking State File | 🤖 Automated | Created via `New-ValidationTracking.ps1 -RoundNumber [N] -ArchivePriorRound` |
| **Moves** | Prior round tracking file | 🤖 Automated | Moved to `archive/` when `-ArchivePriorRound` is specified |
| **Updates** | [`PD-documentation-map.md`](../../../doc/PD-documentation-map.md) | Generated by [`Build-DocumentationMap.ps1 -Tree PD`](../../scripts/validation/Build-DocumentationMap.ps1) | Regenerate if a PD-map-indexed doc was added (DO-NOT-EDIT projection, PF-PRO-050) |

## Next Tasks

- **[Dimension Validation](dimension-validation-task.md) (PF-TSK-092)** — execute once per planned dimension in the round (one dimension per session). The task's dispatch table maps each dimension to its path file (where that dimension's role, analysis steps, and criteria live):
  - [Architectural Consistency](architectural-consistency-validation-path.md) · [Code Quality & Standards](code-quality-standards-validation-path.md) · [Integration & Dependencies](integration-dependencies-validation-path.md) · [Documentation Alignment](documentation-alignment-validation-path.md) · [Extensibility & Maintainability](extensibility-maintainability-validation-path.md) · [AI Agent Continuity](ai-agent-continuity-validation-path.md) · [Security & Data Protection](security-data-protection-validation-path.md) · [Performance & Scalability](performance-scalability-validation-path.md) · [Observability](observability-validation-path.md) · [Accessibility / UX Compliance](accessibility-ux-compliance-validation-path.md) · [Data Integrity](data-integrity-validation-path.md)

## Related Resources

- [Feature Validation Guide](../../guides/05-validation/feature-validation-guide.md) - Comprehensive guide with Dimension Catalog
- [Validation Tracking Template](../../templates/05-validation/validation-tracking-template.md) - Template for creating tracking matrices
- [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) - Feature implementation status
