---
id: PF-TSK-077
type: Process Framework
category: Task Definition
domain: agnostic
version: 1.0
created: 2026-03-23
updated: 2026-03-23
task_type: Discrete
---

# Validation Preparation

## Purpose & Context

Plans a validation round by selecting features to validate, evaluating which validation dimensions apply to each feature, creating the validation tracking state file with the feature×dimension matrix, and planning the session sequence for executing dimension tasks. This task ensures that validation scope is deliberate and traceable rather than ad-hoc.

## AI Agent Role

**Role**: Quality Assurance Planner
**Mindset**: Systematic, scope-aware, risk-based prioritization
**Focus Areas**: Feature maturity assessment, dimension applicability evaluation, session planning, validation coverage
**Communication Style**: Present dimension selection rationale per feature, ask about project-specific quality priorities, recommend validation sequence based on dependencies between dimensions

## When to Use

- Before starting a new validation round for any set of features
- When new features reach implementation-complete status and need quality validation
- When establishing validation baselines for a new project adopting the framework
- When periodic validation is triggered (milestone review, quarterly assessment, pre-release)
- When a specific quality concern (security incident, performance regression) warrants targeted validation

## Context Requirements

[View Context Map for this task](../../visualization/context-maps/05-validation/validation-preparation-map.md)

- **Critical (Must Read):**

  - **Feature Validation Guide** - [Feature Validation Guide](../../guides/05-validation/feature-validation-guide.md) - Comprehensive guide including the Dimension Catalog with applicability criteria
  - **Feature Tracking** - [Feature Tracking](../../../product-docs/state-tracking/permanent/feature-tracking.md) - Current status of features to determine validation scope
  - **Validation Tracking Template** - [Validation Tracking Template](../../templates/05-validation/validation-tracking-template.md) - Template for creating the feature×dimension tracking matrix

- **Important (Load If Space):**

  - **Feature Implementation State Files** - [Feature States Directory](../../../product-docs/state-tracking/features) - Implementation status details per feature, including **Dimension Profiles** (primary source for dimension applicability)
  - **Development Dimensions Guide** - [Development Dimensions Guide](../../guides/framework/development-dimensions-guide.md) - Dimension definitions and applicability criteria
  - **Technical Design Documents** - [TDD Directory](../../../product-docs/technical/architecture/design-docs/tdd) - Feature specifications for understanding what each feature does
  - **Previous Validation Reports** - [Validation Reports](../../../product-docs/validation/reports) - Prior validation results for context

- **Reference Only (Access When Needed):**
  - **Dimension Task Definitions** - [05-validation tasks](../05-validation/) - Individual dimension task definitions for understanding validation criteria
  - **Visual Notation Guide** - [Visual Notation Guide](../../guides/support/visual-notation-guide.md) - For interpreting context map diagrams
  - **ID Registry** - [PD ID Registry](../../PF-id-registry.json) - For understanding document ID assignments

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished! 🚨**
>
> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

### Preparation

1. **Identify Validation Trigger**: Document why this validation round is being initiated (milestone, new features, periodic review, specific concern)
2. **Review Feature Tracking**: Examine [Feature Tracking](../../../product-docs/state-tracking/permanent/feature-tracking.md) to identify features eligible for validation — typically features with status "Implemented", "Testing", or "Complete"
3. **Select Feature Scope**: Choose which features to include in this validation round based on:
   - Implementation completeness (features must be sufficiently implemented to validate)
   - Priority and risk level (high-risk features first)
   - Previous validation coverage (features not yet validated, or validated long ago)
   - Practical session budget (how many validation sessions are planned)
4. **🚨 CHECKPOINT**: Present selected feature scope with rationale to human partner for approval before dimension evaluation

### Execution

5. **Review Dimension Catalog**: Consult the Dimension Catalog in the [Feature Validation Guide](../../guides/05-validation/feature-validation-guide.md) to understand all available validation dimensions and their applicability criteria
6. **Evaluate Dimension Applicability**: For each selected feature, determine which dimensions apply:

   **Primary source**: Read the feature's **Dimension Profile** from its [implementation state file](../../../product-docs/state-tracking/features/). If a profile exists, use it as the starting point — the profile was evaluated during Feature Implementation Planning (PF-TSK-044) with full design context. Verify and update if implementation has changed the picture.

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

   > **Note**: AI Agent Continuity is a standalone validation task (PF-TSK-036) — it is not a development dimension and does not appear in feature Dimension Profiles. Include it in validation rounds for projects using AI-assisted development workflows.

   > **Feedback loop**: If validation discovers that a dimension was incorrectly marked N/A during planning, update the feature's Dimension Profile in its implementation state file for future work.

7. **Create Validation Tracking State File**: Copy the [Validation Tracking Template](../../templates/05-validation/validation-tracking-template.md) to `state-tracking/temporary/` with a descriptive name (e.g., `validation-round-2-features-X.Y.Z-A.B.C.md`). Customize:
   - Fill in feature rows with selected features
   - Add/remove dimension columns based on which dimensions are selected
   - Mark N/A cells for features where specific dimensions don't apply
8. **Plan Session Sequence**: Determine the order of dimension validation sessions:
   - Consider dimension dependencies (e.g., Architectural Consistency before Integration Dependencies)
   - Group features into batches of 2-3 per dimension session
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
- [Documentation Map](../../documentation-map.md) - Add new validation tracking state file if it will be referenced long-term

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

Before considering this task finished:

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] Validation tracking state file created with feature×dimension matrix
  - [ ] All dimension applicability decisions documented with rationale
  - [ ] Session sequence planned with feature batches per dimension
- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] Validation tracking state file created in `state-tracking/temporary/`
  - [ ] [Documentation Map](../../documentation-map.md) updated if applicable
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Completion Instructions](../../guides/framework/feedback-form-completion-instructions.md) for each tool used, using task ID "PF-TSK-077" and context "Validation Preparation"

## Next Tasks

- **Dimension Validation Tasks** — Execute the planned dimension tasks in sequence:
  - [Architectural Consistency Validation](architectural-consistency-validation.md) (PF-TSK-031)
  - [Code Quality Standards Validation](code-quality-standards-validation.md) (PF-TSK-032)
  - [Integration Dependencies Validation](integration-dependencies-validation.md) (PF-TSK-033)
  - [Documentation Alignment Validation](documentation-alignment-validation.md) (PF-TSK-034)
  - [Extensibility Maintainability Validation](extensibility-maintainability-validation.md) (PF-TSK-035)
  - [AI Agent Continuity Validation](ai-agent-continuity-validation.md) (PF-TSK-036)
  - [Security & Data Protection Validation](security-data-protection-validation.md) (PF-TSK-072)
  - [Performance & Scalability Validation](performance-scalability-validation.md) (PF-TSK-073)
  - [Observability Validation](observability-validation.md) (PF-TSK-074)
  - [Accessibility / UX Compliance Validation](accessibility-ux-compliance-validation.md) (PF-TSK-075)
  - [Data Integrity Validation](data-integrity-validation.md) (PF-TSK-076)

## Related Resources

- [Feature Validation Guide](../../guides/05-validation/feature-validation-guide.md) - Comprehensive guide with Dimension Catalog
- [Validation Tracking Template](../../templates/05-validation/validation-tracking-template.md) - Template for creating tracking matrices
- [Feature Tracking](../../../product-docs/state-tracking/permanent/feature-tracking.md) - Feature implementation status
