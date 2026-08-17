---
id: PF-TSK-011
type: Process Framework
category: Task Definition
version: 1.2
created: 2023-06-15
updated: 2026-07-22
description: "Adjust documentation requirements"
use_when: >-
  Complexity changes during implementation
frequency: "As needed"
automation: manual
trigger_status:
  - raw: "_(user recognition)_ — complexity change during implementation"
output_status:
  - raw: "`feature-tracking.md` → tier emoji updated (🔵/🟠/🔴)"
next_tasks:
  - task: ../04-implementation/feature-implementation-planning-task.md
    condition: "Continue with implementation planning using updated requirements"
  - task: ../support/tools-review-task.md
    condition: "If assessment tools need improvement based on findings"
---

# Documentation Tier Adjustment Task

> **▶ Execute this task under the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md).** This file holds only this task's specific content; the universal contract every task shares lives once in the protocol and is mandatory here.

## Purpose & Context

Ensure documentation requirements remain aligned with the true complexity of features by adjusting documentation tiers during implementation when actual complexity differs from initial assessments, preventing both documentation debt and excessive documentation.

## AI Agent Role

**Role**: Technical Writer
**Mindset**: Clarity-focused, user-oriented, structured
**Focus Areas**: Documentation quality, information architecture, usability, appropriate documentation levels
**Communication Style**: Ensure documentation serves its intended audience, ask about documentation needs and complexity changes

## Context Requirements

- **Critical (Must Read):**

  - [Original Assessment Document](../../../doc/documentation-tiers/assessments) - Initial complexity assessment
  - [Normalized Scoring System](../../../doc/documentation-tiers/README.md#normalized-scoring-system) - Guide for scoring complexity

- **Reference Only (Access When Needed):**
  - [Feature Tracking Document](../../../doc/state-tracking/permanent/feature-tracking.md) - Current documentation tier assignment

## Process

> **⚠️ MANDATORY: Always document adjustment rationale for future reference and process improvement.**
>
> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

### Preparation

1. **Recognize Complexity Changes**

   - During implementation, identify if the feature's actual complexity differs significantly from the initial assessment
   - Document specific complexity factors that have changed
   - Collect evidence to support the need for adjustment

2. **Quantify Complexity Changes**
   - Reassess the complexity factors using the normalized scoring system
   - Recalculate the normalized score
   - Determine if the new score falls into a different tier range
3. **🚨 CHECKPOINT**: Present complexity reassessment and proposed tier change to human partner for approval

### Execution

4. **Document the Adjustment Rationale**

   - Document which specific complexity factors changed and why
   - Explain the impact on the overall complexity
   - Note any lessons learned for future assessments
   - Identify patterns that could improve initial assessments

5. **Update the Documentation Tier**
   - Update the feature's assessment document with the new tier
   - Update the feature tracking document with the new tier emoji
   - Update any project management tools to reflect the new requirements
6. **🚨 CHECKPOINT**: Present updated tier assignments and documentation plan to human partner for review

### Finalization

7. **Adapt Documentation Plan**

   - If upgrading to a higher tier: Create or expand documentation as needed
   - If downgrading to a lower tier: Simplify planned documentation
   - Allocate appropriate time for documentation tasks

8. **Implement Documentation Changes**
   - Create or modify documentation according to the new tier requirements
   - Ensure documentation meets the standards for the new tier
   - **🚨 MANDATORY FINAL STEP**: Complete the Task Completion Checklist below

## Cycle Frequency

- As needed during feature implementation
- At key implementation milestones:
  - After data model implementation
  - After core business logic implementation
  - After UI component creation

## Trigger Events

- Discovery of unexpected complexity factors
- Simplification of initially complex aspects
- Completion of key implementation milestones
- Significant changes to feature requirements

## Outputs

- **Updated Assessment Document** - Revised complexity assessment with new tier assignment
- **Adjustment Rationale** - Documentation of why the adjustment was needed
- **Updated Documentation** - Documentation that meets the requirements of the new tier

## State Tracking

The following state files must be updated as part of this task:

- [Feature Tracking Document](../../../doc/state-tracking/permanent/feature-tracking.md) - Update with:
  - New documentation tier emoji (🔵/🟠/🔴)
  - Link to updated assessment document
  - Date of tier adjustment
  - Notes about why the adjustment was needed

## ⚠️ MANDATORY Task Completion Checklist

> Completion discipline, output verification, and the feedback form are governed by the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md) (Phase C). The items below are the **task-specific** verifications that plug into it.

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] Updated assessment document with new tier assignment
  - [ ] Documented adjustment rationale with specific complexity factors
  - [ ] Updated documentation that meets the new tier requirements
  - [ ] Evidence supporting the need for adjustment
- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] Feature tracking document shows the new documentation tier
  - [ ] Project timeline reflects any changes to documentation schedule
  - [ ] Adjustment date and rationale are recorded
- [ ] **Feedback form** completed per the [Task Execution Protocol → Feedback step](../../guides/framework/task-execution-protocol-guide.md#feedback-step) — task ID `PF-TSK-011`, context "Documentation Tier Adjustment".
- [ ] **Communicate Changes**: Ensure all stakeholders are aware of the tier adjustment and its implications

## File Operations

| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Updates** | [`feature-tracking.md`](../../../doc/state-tracking/permanent/feature-tracking.md) | Manual | Adjust tier classification when complexity changes during implementation |

## Next Tasks

- [**Feature Implementation Planning**](../04-implementation/feature-implementation-planning-task.md) - Continue with implementation planning using updated requirements
- [**Tools Review**](../support/tools-review-task.md) - If assessment tools need improvement based on findings

<!-- merged from transition-registry entry: Documentation Tier Adjustment -->
### Prerequisites for Transition

- [ ] Tier adjustment assessment completed
- [ ] New tier assigned and documented
- [ ] Feature Tracking updated with new tier
- [ ] Rationale for tier change documented

### Next Task Selection

```
What is the new tier assignment?
├─ Tier increased (more complex) → Add required documentation tasks
│   └─ Example: Tier 1→2 may require TDD Creation
├─ Tier decreased (less complex) → Remove unnecessary documentation
│   └─ Example: Tier 3→2 may skip Test Specification Creation
└─ Tier unchanged → Continue with current task
```

### Preparation for Next Task

1. Review new tier requirements and adjust task sequence
2. Update project timeline based on tier change
3. Communicate tier change to stakeholders
4. Prepare context for adjusted documentation requirements

## Related Resources

- [Tier-assessment criteria (`feature-request-evaluation` skill)](../../../.claude/skills/feature-request-evaluation/references/tier-assessment.md) - Scoring criteria and reassessment triggers for feature complexity

## Metrics and Evaluation

- **Adjustment Frequency**: Percentage of features requiring tier adjustments
- **Assessment Accuracy**: Improvement in initial assessment accuracy over time
- **Documentation Quality**: Alignment between documentation and actual feature complexity
- **Success Criteria**: Documentation quality matches actual feature complexity with minimal disruption to project timeline

## Continuous Improvement

The tier adjustment process should be evaluated periodically:

- Review patterns in tier adjustments to improve initial assessments
- Refine complexity factors and weights based on implementation experience
- Update assessment guidelines to capture commonly missed complexity indicators
- Improve the efficiency of the adjustment process itself
