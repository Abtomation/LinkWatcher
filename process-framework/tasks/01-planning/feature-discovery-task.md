---
id: PF-TSK-013
type: Process Framework
category: Task Definition
version: 1.3
created: 2025-06-09
updated: 2026-07-14
description: "Identify and document potential new features"
complexity: medium
use_when: >-
  Planning new features through research and analysis
automation: semi
scripts:
  - ../../scripts/file-creation/01-planning/New-FeatureRequest.ps1
  - ../../scripts/file-creation/01-planning/New-Exploration.ps1
trigger_status:
  - raw: "_(user request)_"
output_status:
  - raw: "`feature-request-tracking.md` → `📥 Submitted`; `user-workflow-tracking.md` → creates/updates workflow definitions; `technical-exploration-tracking.md` → `📥 Queued`; `doc/founding/feature-landscape.md` (`PD-DOC-002`) → extended with the cycle's reasoning _(no tracking status)_"
next_tasks:
  - task: feature-request-evaluation.md
    condition: "Classify discovered features as new features or enhancements, then route to correct workflow"
  - task: technical-exploration-task.md
    condition: "Discovery filed exploration items — a queued research question must resolve before the dependent feature can be designed"
---

# Feature Discovery

> **▶ Execute this task under the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md).** This file holds only this task's specific content; the universal contract every task shares lives once in the protocol and is mandatory here.

## Purpose & Context

Identify and document potential new features through user research, competitive analysis, and market trends. This task helps ensure the product roadmap remains innovative and responsive to user needs.

## AI Agent Role

**Role**: Product Analyst
**Mindset**: User-focused, research-oriented, questioning
**Focus Areas**: User needs, market research, competitive analysis, feature validation
**Communication Style**: Ask clarifying questions about user value and priorities, discuss market opportunities and user impact

## Context Requirements

- **Critical (Must Read):**

  - User feedback and feature requests (if available)
  - [Product Concept](../../../doc/founding/product-concept.md) (`PD-DOC-001`) - The project's authoritative statement of what is being built and why. On a **greenfield** project this is what Preparation step 1 reads in place of existing features; its capability areas are where discovery starts
  - [Feature Granularity Guide](../../guides/01-planning/feature-granularity-guide.md) - Defines what constitutes a well-scoped feature with validation tests
  - [Development Guide](../../guides/04-implementation/development-guide.md) - Development standards and practices

- **Important (Load If Space):**

  - Competitive analysis data (if available)
  - [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md) - To identify opportunities for improvements
  - [Technical Exploration Tracking](../../../doc/state-tracking/permanent/technical-exploration-tracking.md) - The queue this task files research questions into (Step 15); check it for explorations already open against the same question

- **Reference Only (Access When Needed):**
  - [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) - To understand existing features and gaps

## Process

> **⚠️ MANDATORY: Document all discovered features in the Feature Request Tracking document.**
>
> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

### Preparation

1. Review existing features in the Feature Tracking document
   - **Greenfield projects** (no features yet): the [Product Concept](../../../doc/founding/product-concept.md) (`PD-DOC-001`) is what you read instead — it is the project's authoritative statement of what is being built, synthesized at [Project Initiation (PF-TSK-059)](../00-setup/project-initiation-task.md) Step 22 from the founding material in `doc/founding/inputs/`. Its **capability areas** are the starting point this step's "existing features" would otherwise provide; its **open questions** flag intent that is still unsettled. Read the founding inputs themselves where the concept's Sources table points at something you need in the original.
2. Analyze user feedback and identify common themes or requests
3. Research competitive products and identify gaps in your offering
4. Identify current market trends and emerging technologies
5. Gather relevant stakeholder input and business requirements
6. **🚨 CHECKPOINT**: Present research findings, identified themes, and competitive gaps to human partner

### Execution

7. Conduct brainstorming sessions to generate feature ideas
8. For each potential feature:
   - Validate granularity using the three tests in the [Feature Granularity Guide](../../guides/01-planning/feature-granularity-guide.md) (planning test, conversation test, independence test)
   - Document a clear description of the feature
   - Identify potential user benefits
   - Outline high-level implementation considerations
   - Estimate rough complexity and priority
9. Evaluate feature ideas against strategic goals and user needs
10. Group related features into coherent categories
11. **Identify user-facing workflows**: Ask *"What does the user DO with this software?"* Map each workflow to the features that enable it. Create or update [User Workflow Tracking](../../../doc/state-tracking/permanent/user-workflow-tracking.md) with workflow definitions, required features, and priorities
12. Prioritize features based on value, complexity, and strategic alignment
13. **🚨 CHECKPOINT**: Present prioritized feature list with descriptions and rationale to human partner for approval

### Finalization

14. Add discovered features to [Feature Request Tracking](../../../doc/state-tracking/permanent/feature-request-tracking.md) using [`New-FeatureRequest.ps1`](../../scripts/file-creation/01-planning/New-FeatureRequest.ps1):
    ```powershell
    pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/01-planning/New-FeatureRequest.ps1 -Source "Feature Discovery YYYY-MM-DD" -Description "Feature description" -Priority "HIGH|MEDIUM|LOW" -Notes "User benefit, context, dependencies"
    ```
    Each discovered feature becomes a separate request in feature-request-tracking.md, to be classified by [Feature Request Evaluation](feature-request-evaluation.md) (new feature vs. enhancement to existing feature).
15. File any technical explorations needed for complex features into [Technical Exploration Tracking](../../../doc/state-tracking/permanent/technical-exploration-tracking.md) using [`New-Exploration.ps1`](../../scripts/file-creation/01-planning/New-Exploration.ps1) — one row per open research question that must resolve before the feature can be designed or implemented:
    ```powershell
    pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/01-planning/New-Exploration.ps1 -Source "Feature Discovery YYYY-MM-DD" -Description "The research question to answer" -Priority "HIGH|MEDIUM|LOW" -Notes "Acceptance criteria, context"
    ```
    Each row is filed at `📥 Queued` and executed later by [Technical Exploration](technical-exploration-task.md) (PF-TSK-093), which produces the findings document and unblocks the dependent work. This task **files** explorations; it does not run them. An exploration is an *open question to answer before building* — deferred rework from a shortcut already taken is technical debt instead ([Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md)).
16. **Record the cycle's reasoning in the Feature Landscape**: Steps 8, 10 and 12 produced granularity calls, a category grouping, and prioritization reasoning; Step 13 presented them. The *data* is now filed — the requests in feature-request-tracking.md, the explorations in technical-exploration-tracking.md. The **reasoning** has no other home, and the category grouping in particular is a cross-cutting decision no per-row tracker field can hold. Record it in [`doc/founding/feature-landscape.md`](../../../doc/founding/feature-landscape.md) (`PD-DOC-002`, blueprint-shipped stub from the [Feature Landscape template](../../templates/01-planning/feature-landscape-template.md)):
    - **Extend it in place** — one landscape per project, appended to on each discovery cycle, with a new row in its **Cycle Log**. Never create a second landscape document.
    - **Record**: the method this cycle used; the **granularity calls** worth keeping (features split, merged, or reshaped, and which of the three [Feature Granularity Guide](../../guides/01-planning/feature-granularity-guide.md) tests drove it — a feature that passed all three uneventfully needs no row); the **category rationale** (why each category is a category, plus borderline groupings); the **prioritization rationale** (why, not the value); and 0.x foundation candidates if the project uses that category.
    - **Reference features by `PD-FRQ` ID.** The landscape carries **no feature list** — descriptions, benefits, priorities and complexity all belong to the trackers that own them, and restating them here creates a duplicate that rots as those trackers move on.
    - **Scale it to the reasoning actually done.** A cycle that made no non-obvious calls leaves a thin record; that is correct, not incomplete.
    - **Relaunch projects only**: where this cycle deliberately complemented a blind-first draft against a predecessor product's feature list, fill the optional **Predecessor Complement** section — including the features deliberately *not* carried over, which is the half most easily lost. Every other project deletes that section.
    - Point each request's `Source` at this document so discovery provenance resolves to a real artifact rather than a bare date string.
17. **🚨 MANDATORY FINAL STEP**: Complete the Task Completion Checklist below

## Outputs

- **Feature Requests** - Discovered features added to [Feature Request Tracking](../../../doc/state-tracking/permanent/feature-request-tracking.md) with:
  - Clear descriptions and justifications in the Notes column
  - Priority assessment
  - Dependencies and user benefit information in Notes
  - Each request awaits classification by [Feature Request Evaluation](feature-request-evaluation.md)
- **User Workflow Tracking** - [User Workflow Tracking](../../../doc/state-tracking/permanent/user-workflow-tracking.md) created or updated with user-facing workflows mapped to features
- **Technical Exploration Items** - Any identified items requiring technical investigation before implementation filed into [Technical Exploration Tracking](../../../doc/state-tracking/permanent/technical-exploration-tracking.md) at `📥 Queued`, for [Technical Exploration](technical-exploration-task.md) (PF-TSK-093) to execute
- **Feature Landscape** - [`doc/founding/feature-landscape.md`](../../../doc/founding/feature-landscape.md) (`PD-DOC-002`) extended in place with this cycle's reasoning: method, granularity calls, category rationale, prioritization rationale, and a Cycle Log row. Carries no feature list — it references `PD-FRQ` IDs and is the artifact each request's `Source` points at

## State Tracking

The following state files must be updated as part of this task:

- [Feature Request Tracking](../../../doc/state-tracking/permanent/feature-request-tracking.md) - Add discovered features as new requests with status "📥 Submitted"
- [Technical Exploration Tracking](../../../doc/state-tracking/permanent/technical-exploration-tracking.md) - File one `📥 Queued` row per:
  - Technical exploration needed before implementation
  - Open question that requires investigation before the feature can proceed

## ⚠️ MANDATORY Task Completion Checklist

> Completion discipline, output verification, and the feedback form are governed by the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md) (Phase C). The items below are the **task-specific** verifications that plug into it.

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] Discovered features added to Feature Request Tracking with comprehensive descriptions
  - [ ] User benefits and justifications captured in the Notes column
  - [ ] Technical exploration items filed into Technical Exploration Tracking at `📥 Queued` (if applicable)
  - [ ] **Feature Landscape extended** (Step 16): this cycle's method, granularity calls, category rationale and prioritization rationale recorded in `doc/founding/feature-landscape.md`, with a Cycle Log row and features referenced by `PD-FRQ` ID only (no feature list restated)
- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] Feature Request Tracking updated with discovered features (status: 📥 Submitted)
  - [ ] Initial priorities assigned to all new requests
  - [ ] Dependencies identified and documented in Notes
  - [ ] Technical Exploration Tracking updated with any required explorations
- [ ] **Feedback form** completed per the [Task Execution Protocol → Feedback step](../../guides/framework/task-execution-protocol-guide.md#feedback-step) — task ID `PF-TSK-013`, context "Feature Discovery".

## File Operations

| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Updates** | [`feature-request-tracking.md`](../../../doc/state-tracking/permanent/feature-request-tracking.md) | `New-FeatureRequest.ps1` | Add discovered features as new requests with status "📥 Submitted" |
| **Updates** | [`technical-exploration-tracking.md`](../../../doc/state-tracking/permanent/technical-exploration-tracking.md) | [`New-Exploration.ps1`](../../scripts/file-creation/01-planning/New-Exploration.ps1) | File technical explorations needed before implementation as `📥 Queued` rows |
| **Updates** | [`doc/founding/feature-landscape.md`](../../../doc/founding/feature-landscape.md) | Manual | Extend in place (Step 16) with the cycle's method, granularity calls, category and prioritization rationale, and a Cycle Log row. Blueprint-shipped stub (`PD-DOC-002`); no creation script — one landscape per project |

## Next Tasks

- [**Feature Request Evaluation**](feature-request-evaluation.md) - Classify discovered features as new features or enhancements, then route to correct workflow
- [**Technical Exploration**](technical-exploration-task.md) - Discovery filed exploration items — a queued research question must resolve before the dependent feature can be designed

<!-- merged from transition-registry entry: Feature Discovery -->
### Prerequisites for Transition

- [ ] New features identified and documented
- [ ] Features added to Feature Request Tracking with initial priorities
- [ ] Dependencies between features identified
- [ ] Technical debt implications noted

### Next Task Selection

- **If features need complexity assessment**: → Feature Request Evaluation (classifies the feature and assesses its tier inline)
- **If features are well-understood and simple**: → Feature Implementation
- **If exploring technical feasibility**: → Continue with additional discovery cycles

### Preparation for Next Task

1. Ensure Feature Request Tracking is updated with all new features
2. Verify feature descriptions are clear and actionable
3. Confirm initial priorities are assigned
4. Review dependencies for implementation order

## Related Resources

- [Feature Granularity Guide](../../guides/01-planning/feature-granularity-guide.md) - Defines what constitutes a well-scoped feature with validation tests and scaling guidance
- [Feature Dependencies Map](../../../doc/technical/architecture/feature-dependencies.md) - For understanding how new features relate to existing ones
