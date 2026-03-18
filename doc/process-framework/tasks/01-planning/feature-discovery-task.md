---
id: PF-TSK-013
type: Process Framework
category: Task Definition
version: 1.1
created: 2025-06-09
updated: 2026-03-02
task_type: Discrete
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

- [Feature Discovery Context Map](/doc/process-framework/visualization/context-maps/01-planning/feature-discovery-map.md) - Visual guide to the components relevant to this task

- **Critical (Must Read):**

  - User feedback and feature requests (if available)
  - [Feature Granularity Guide](/doc/process-framework/guides/03-testing/feature-granularity-guide.md) - Defines what constitutes a well-scoped feature with validation tests
  - [Development Guide](/doc/process-framework/guides/04-implementation/development-guide.md) - Development standards and practices
  - [Visual Notation Guide](/doc/process-framework/guides/support/visual-notation-guide.md) - For interpreting context map diagrams

- **Important (Load If Space):**

  - Competitive analysis data (if available)
  - [Technical Debt Tracking](../../state-tracking/permanent/technical-debt-tracking.md) - To identify opportunities for improvements

- **Reference Only (Access When Needed):**
  - [Feature Tracking](../../state-tracking/permanent/feature-tracking.md) - To understand existing features and gaps

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
   - Validate granularity using the three tests in the [Feature Granularity Guide](/doc/process-framework/guides/03-testing/feature-granularity-guide.md) (planning test, conversation test, independence test)
   - Document a clear description of the feature
   - Identify potential user benefits
   - Outline high-level implementation considerations
   - Estimate rough complexity and priority
9. Evaluate feature ideas against strategic goals and user needs
10. Group related features into coherent categories
11. Prioritize features based on value, complexity, and strategic alignment
12. **🚨 CHECKPOINT**: Present prioritized feature list with descriptions and rationale to human partner for approval

### Finalization

13. Add new features to the Feature Tracking document with:
    - Detailed descriptions in the "Notes" column to capture reasoning and context
    - Appropriate categorization and feature ID
    - Initial status (⬜ Not Started)
    - Priority assessment (P1-P5)
    - Dependencies (if identified)
14. Document any technical explorations needed for complex features in the Technical Debt Tracking document
15. **🚨 MANDATORY FINAL STEP**: Complete the Task Completion Checklist below

## Outputs

- **Updated Feature Tracking** - New features added to [Feature Tracking](../../state-tracking/permanent/feature-tracking.md) with:
  - Clear descriptions and justifications in the "Notes" column
  - Appropriate categories and initial status
  - Priority assessment
  - Dependencies (if identified)
  - User benefit information
- **Technical Exploration Items** - Any identified items requiring technical investigation before implementation added to [Technical Debt Tracking](../../state-tracking/permanent/technical-debt-tracking.md)

## State Tracking

The following state files must be updated as part of this task:

- [Feature Tracking](../../state-tracking/permanent/feature-tracking.md) - Update with:
  - New feature entries with appropriate IDs
  - Initial status (⬜ Not Started)
  - Priority assessment (P1-P5)
  - Comprehensive descriptions and context in the "Notes" column
  - Categorical grouping
  - Dependencies (if known)
  - User benefit information
- [Technical Debt Tracking](../../state-tracking/permanent/technical-debt-tracking.md) - Update with:
  - Any technical explorations needed before implementation
  - Open questions that require investigation

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

Before considering this task finished:

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] New features added to Feature Tracking document with comprehensive descriptions
  - [ ] User benefits and justifications captured in the Notes column
  - [ ] Technical exploration items documented in Technical Debt Tracking (if applicable)
- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] Feature tracking document updated with new features
  - [ ] Features properly categorized and given appropriate IDs
  - [ ] Initial priorities assigned to all new features
  - [ ] Dependencies identified and documented
  - [ ] Technical Debt Tracking updated with any required explorations
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Completion Instructions](../../guides/framework/feedback-form-completion-instructions.md) for each tool used, using task ID "PF-TSK-013" and context "Feature Discovery"

## Next Tasks

- [**Feature Tier Assessment**](feature-tier-assessment-task.md) - Assess the complexity of newly discovered features

## Related Resources

- [Feature Granularity Guide](/doc/process-framework/guides/03-testing/feature-granularity-guide.md) - Defines what constitutes a well-scoped feature with validation tests and scaling guidance
- [Feature Dependencies Map](/doc/product-docs/technical/design/feature-dependencies.md) - For understanding how new features relate to existing ones
