---
id: PF-TSK-013
type: Process Framework
category: Task Definition
version: 1.1
created: 2025-06-09
updated: 2026-03-02
---

# Feature Discovery

## Purpose & Context

Identify and document potential new features through user research, competitive analysis, and market trends. This task helps ensure the product roadmap remains innovative and responsive to user needs.

## AI Agent Role

**Role**: Product Analyst
**Mindset**: User-focused, research-oriented, questioning
**Focus Areas**: User needs, market research, competitive analysis, feature validation
**Communication Style**: Ask clarifying questions about user value and priorities, discuss market opportunities and user impact

## When to Use

- When planning the next phase of product development
- When seeking to differentiate from competitors
- When addressing specific user feedback patterns suggesting new needs
- When exploring new market opportunities
- When identifying potential enhancements to existing features

## Context Requirements

[View Context Map for this task](../../visualization/context-maps/01-planning/feature-discovery-map.md)

- **Critical (Must Read):**

  - User feedback and feature requests (if available)
  - [Feature Granularity Guide](/process-framework/guides/01-planning/feature-granularity-guide.md) - Defines what constitutes a well-scoped feature with validation tests
  - [Development Guide](/process-framework/guides/04-implementation/development-guide.md) - Development standards and practices
  - [Visual Notation Guide](/process-framework/guides/support/visual-notation-guide.md) - For interpreting context map diagrams

- **Important (Load If Space):**

  - Competitive analysis data (if available)
  - [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md) - To identify opportunities for improvements

- **Reference Only (Access When Needed):**
  - [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) - To understand existing features and gaps

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished! 🚨**
>
> **⚠️ MANDATORY: Document all discovered features in the Feature Tracking document.**
>
> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

### Preparation

1. Review existing features in the Feature Tracking document
2. Analyze user feedback and identify common themes or requests
3. Research competitive products and identify gaps in your offering
4. Identify current market trends and emerging technologies
5. Gather relevant stakeholder input and business requirements
6. **🚨 CHECKPOINT**: Present research findings, identified themes, and competitive gaps to human partner

### Execution

7. Conduct brainstorming sessions to generate feature ideas
8. For each potential feature:
   - Validate granularity using the three tests in the [Feature Granularity Guide](/process-framework/guides/01-planning/feature-granularity-guide.md) (planning test, conversation test, independence test)
   - Document a clear description of the feature
   - Identify potential user benefits
   - Outline high-level implementation considerations
   - Estimate rough complexity and priority
9. Evaluate feature ideas against strategic goals and user needs
10. Group related features into coherent categories
11. **Identify user-facing workflows**: Ask *"What does the user DO with this software?"* Map each workflow to the features that enable it. Create or update [User Workflow Tracking](/doc/state-tracking/permanent/user-workflow-tracking.md) with workflow definitions, required features, and priorities
12. Prioritize features based on value, complexity, and strategic alignment
12. **🚨 CHECKPOINT**: Present prioritized feature list with descriptions and rationale to human partner for approval

### Finalization

13. Add discovered features to [Feature Request Tracking](../../../doc/state-tracking/permanent/feature-request-tracking.md) using [`New-FeatureRequest.ps1`](../../scripts/file-creation/01-planning/New-FeatureRequest.ps1):
    ```powershell
    cd process-framework/scripts/file-creation/01-planning
    .\New-FeatureRequest.ps1 -Source "Feature Discovery YYYY-MM-DD" -Description "Feature description" -Priority "HIGH|MEDIUM|LOW" -Notes "User benefit, context, dependencies"
    ```
    Each discovered feature becomes a separate request in feature-request-tracking.md, to be classified by [Feature Request Evaluation](feature-request-evaluation.md) (new feature vs. enhancement to existing feature).
14. Document any technical explorations needed for complex features in the Technical Debt Tracking document
15. **🚨 MANDATORY FINAL STEP**: Complete the Task Completion Checklist below

## Outputs

- **Feature Requests** - Discovered features added to [Feature Request Tracking](../../../doc/state-tracking/permanent/feature-request-tracking.md) with:
  - Clear descriptions and justifications in the Notes column
  - Priority assessment
  - Dependencies and user benefit information in Notes
  - Each request awaits classification by [Feature Request Evaluation](feature-request-evaluation.md)
- **User Workflow Tracking** - [User Workflow Tracking](/doc/state-tracking/permanent/user-workflow-tracking.md) created or updated with user-facing workflows mapped to features
- **Technical Exploration Items** - Any identified items requiring technical investigation before implementation added to [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md)

## State Tracking

The following state files must be updated as part of this task:

- [Feature Request Tracking](../../../doc/state-tracking/permanent/feature-request-tracking.md) - Add discovered features as new requests with status "Submitted"
- [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md) - Update with:
  - Any technical explorations needed before implementation
  - Open questions that require investigation

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

Before considering this task finished:

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] Discovered features added to Feature Request Tracking with comprehensive descriptions
  - [ ] User benefits and justifications captured in the Notes column
  - [ ] Technical exploration items documented in Technical Debt Tracking (if applicable)
- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] Feature Request Tracking updated with discovered features (status: Submitted)
  - [ ] Initial priorities assigned to all new requests
  - [ ] Dependencies identified and documented in Notes
  - [ ] Technical Debt Tracking updated with any required explorations
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Completion Instructions](../../guides/framework/feedback-form-completion-instructions.md) for each tool used, using task ID "PF-TSK-013" and context "Feature Discovery"

## Next Tasks

- [**Feature Request Evaluation**](feature-request-evaluation.md) - Classify discovered features as new features or enhancements, then route to correct workflow

## Related Resources

- [Feature Granularity Guide](/process-framework/guides/01-planning/feature-granularity-guide.md) - Defines what constitutes a well-scoped feature with validation tests and scaling guidance
- [Feature Dependencies Map](/doc/technical/architecture/feature-dependencies.md) - For understanding how new features relate to existing ones
