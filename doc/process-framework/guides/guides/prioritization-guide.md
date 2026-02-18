---
id: PF-GDE-023
type: Document
category: General
version: 1.0
created: 2025-07-24
updated: 2025-07-24
guide_description: Guide for applying impact/effort matrix to prioritize debt
guide_title: Prioritization Guide
guide_status: Active
---
# Prioritization Guide

## Overview

This guide provides a systematic approach to prioritizing technical debt using an impact/effort matrix. It helps teams make data-driven decisions about which debt items to address first, ensuring maximum business value from remediation efforts.

## When to Use

Use this guide when:
- Prioritizing debt items identified during assessments
- Planning technical debt remediation roadmaps
- Making resource allocation decisions
- Communicating debt priorities to stakeholders
- Reviewing and updating existing priorities

> **🚨 CRITICAL**: Always consider current business priorities and team capacity when setting debt priorities. A high-priority debt item that can't be addressed for months may be less valuable than a medium-priority item that can be fixed immediately.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Background](#background)
3. [Impact Assessment Framework](#impact-assessment-framework)
4. [Effort Estimation Framework](#effort-estimation-framework)
5. [Priority Matrix Application](#priority-matrix-application)
6. [Examples](#examples)
7. [Troubleshooting](#troubleshooting)
8. [Related Resources](#related-resources)

## Prerequisites

Before you begin, ensure you have:

- **Complete debt assessment**: All debt items identified and documented
- **Business context**: Understanding of current business priorities and constraints
- **Team input**: Feedback from developers on effort estimates and technical impact
- **Stakeholder alignment**: Agreement on business impact criteria and priorities

## Background

The impact/effort matrix is a decision-making tool that helps prioritize work based on two key dimensions:

- **Impact**: The potential positive effect of addressing the debt item
- **Effort**: The resources (time, people, complexity) required to address the item

This creates four priority quadrants:
1. **Critical Priority** (High Impact, Low Effort): "Quick Wins" - Address immediately
2. **High Priority** (High Impact, High Effort): "Major Projects" - Plan carefully
3. **Medium Priority** (Low Impact, Low Effort): "Fill-ins" - Address when capacity allows
4. **Low Priority** (Low Impact, High Effort): "Questionable" - Consider deferring

The goal is to maximize business value while working within realistic resource constraints.

## Impact Assessment Framework

### Business Impact Dimensions

#### 1. User Experience Impact
**High Impact (3 points):**
- Causes user-facing errors or crashes
- Significantly degrades performance (>2 second delays)
- Blocks critical user workflows
- Affects user data integrity or security

**Medium Impact (2 points):**
- Causes minor user inconvenience
- Moderate performance degradation (0.5-2 second delays)
- Affects non-critical features
- Reduces user satisfaction but doesn't block workflows

**Low Impact (1 point):**
- No direct user impact
- Cosmetic or minor usability issues
- Affects developer tools or internal processes only
- Minimal performance impact (<0.5 seconds)

#### 2. Development Velocity Impact
**High Impact (3 points):**
- Blocks new feature development
- Causes frequent development delays
- Requires workarounds that slow all development
- Makes code changes risky or difficult

**Medium Impact (2 points):**
- Slows specific types of development
- Requires occasional workarounds
- Makes some areas of code harder to modify
- Increases development time by 20-50%

**Low Impact (1 point):**
- Minor development inconvenience
- Affects code aesthetics more than functionality
- Increases development time by <20%
- Easy to work around

#### 3. Maintenance Cost Impact
**High Impact (3 points):**
- Causes frequent production issues
- Requires ongoing manual intervention
- Creates cascading failures
- Significantly increases support burden

**Medium Impact (2 points):**
- Occasional production issues
- Requires periodic manual fixes
- Increases monitoring or support effort
- Moderate maintenance overhead

**Low Impact (1 point):**
- Minimal ongoing maintenance
- Self-contained issues
- Low support burden
- Rare or no production impact

#### 4. Risk and Security Impact
**High Impact (3 points):**
- Security vulnerabilities
- Data integrity risks
- Compliance violations
- System stability risks

**Medium Impact (2 points):**
- Potential security concerns
- Minor compliance issues
- Moderate stability risks
- Performance degradation risks

**Low Impact (1 point):**
- No security implications
- No compliance impact
- Minimal stability risk
- Theoretical or future risks only

### Overall Impact Calculation

**High Impact (3 points):** Any dimension scores High (3), OR three or more dimensions score Medium (2)
**Medium Impact (2 points):** One or two dimensions score Medium (2), others Low (1)
**Low Impact (1 point):** All dimensions score Low (1)

## Effort Estimation Framework

### Technical Complexity Assessment

#### 1. Scope of Changes
**High Effort (3 points):**
- Requires architectural changes
- Affects multiple modules or services
- Needs database schema changes
- Requires API changes affecting multiple clients

**Medium Effort (2 points):**
- Affects single module but multiple components
- Requires refactoring existing code
- Needs configuration or deployment changes
- Affects shared utilities or libraries

**Low Effort (1 point):**
- Localized to single component
- Simple code changes
- No external dependencies
- Minimal testing required

#### 2. Team and Skill Requirements
**High Effort (3 points):**
- Requires multiple team members
- Needs specialized expertise not available on team
- Requires coordination across teams
- Needs external consultation or training

**Medium Effort (2 points):**
- Requires 2-3 team members
- Needs some specialized knowledge
- Requires coordination within team
- Some learning or research required

**Low Effort (1 point):**
- Single developer can handle
- Uses existing team expertise
- No special coordination needed
- Straightforward implementation

#### 3. Risk and Testing Requirements
**High Effort (3 points):**
- High risk of breaking existing functionality
- Requires extensive testing (integration, performance, security)
- Needs careful rollout strategy
- Requires significant validation

**Medium Effort (2 points):**
- Moderate risk of side effects
- Requires standard testing suite
- Needs some validation
- Standard deployment process

**Low Effort (1 point):**
- Low risk of side effects
- Minimal testing required
- Easy to validate
- Simple deployment

#### 4. Timeline Estimation
**High Effort (3 points):** >2 weeks of development time
**Medium Effort (2 points):** 3-10 days of development time
**Low Effort (1 point):** <3 days of development time

### Overall Effort Calculation

**High Effort (3 points):** Any dimension scores High (3), OR three or more dimensions score Medium (2)
**Medium Effort (2 points):** One or two dimensions score Medium (2), others Low (1)
**Low Effort (1 point):** All dimensions score Low (1)

## Priority Matrix Application

### Step 1: Score All Debt Items

For each debt item:
1. Assess impact using the framework above
2. Estimate effort using the framework above
3. Calculate priority score: Impact ÷ Effort
4. Assign to priority quadrant

### Step 2: Create Priority Matrix

```
                    EFFORT
                Low    Medium    High
              ┌─────┬─────────┬─────┐
         High │ 🔴  │   🟡    │  🟢  │
IMPACT       ├─────┼─────────┼─────┤
       Medium│ 🟡  │   🟡    │  🟢  │
              ├─────┼─────────┼─────┤
          Low │ 🟢  │   🟢    │  🟢  │
              └─────┴─────────┴─────┘
```

### Step 3: Apply Business Context

Consider additional factors:
- **Current sprint/release priorities**
- **Team capacity and availability**
- **Dependencies between debt items**
- **Stakeholder requirements**
- **External deadlines or constraints**

### Step 4: Create Implementation Roadmap

**Phase 1: Critical Priority (🔴)**
- Address immediately
- Target: Complete within current sprint
- Resource allocation: Highest priority

**Phase 2: High Priority (🟡)**
- Plan for next sprint/release
- Target: Complete within 1-2 sprints
- Resource allocation: Plan dedicated time

**Phase 3: Medium/Low Priority (🟢)**
- Address when capacity allows
- Target: Complete when convenient
- Resource allocation: Fill-in work

## Examples

### Example 1: Authentication Module Debt Assessment

**Debt Items Identified:**
1. **Hardcoded API keys in source code**
2. **Missing input validation on login form**
3. **Outdated authentication library**
4. **Poor error handling in auth flow**
5. **Missing unit tests for auth service**

**Impact Assessment:**
```
Item 1 - Hardcoded API Keys:
- User Experience: Low (1) - No direct user impact
- Development Velocity: Medium (2) - Slows deployment process
- Maintenance Cost: Medium (2) - Security risk management
- Risk/Security: High (3) - Major security vulnerability
Overall Impact: High (3)

Item 2 - Missing Input Validation:
- User Experience: High (3) - Can cause crashes/errors
- Development Velocity: Low (1) - Doesn't affect development
- Maintenance Cost: Medium (2) - Support burden from errors
- Risk/Security: High (3) - Security vulnerability
Overall Impact: High (3)
```

**Effort Assessment:**
```
Item 1 - Hardcoded API Keys:
- Scope: Low (1) - Localized changes
- Team/Skills: Low (1) - Standard practice
- Risk/Testing: Medium (2) - Needs deployment testing
- Timeline: Low (1) - <1 day
Overall Effort: Low (1)

Item 2 - Missing Input Validation:
- Scope: Low (1) - Single component
- Team/Skills: Low (1) - Standard validation
- Risk/Testing: Low (1) - Easy to test
- Timeline: Low (1) - <1 day
Overall Effort: Low (1)
```

**Priority Matrix Results:**
- Item 1: High Impact (3) ÷ Low Effort (1) = 3.0 → 🔴 Critical Priority
- Item 2: High Impact (3) ÷ Low Effort (1) = 3.0 → 🔴 Critical Priority
- Item 3: Medium Impact (2) ÷ High Effort (3) = 0.67 → 🟢 Low Priority
- Item 4: Medium Impact (2) ÷ Medium Effort (2) = 1.0 → 🟡 High Priority
- Item 5: Low Impact (1) ÷ Low Effort (1) = 1.0 → 🟡 Medium Priority

**Implementation Plan:**
1. **Immediate (This Sprint)**: Fix hardcoded API keys and add input validation
2. **Next Sprint**: Improve error handling
3. **Future**: Add unit tests, consider library upgrade

### Example 2: Performance Optimization Assessment

**Scenario**: Mobile app experiencing slow loading times

**Debt Items:**
1. **Inefficient image loading** - High Impact (3), Low Effort (1) → 🔴 Critical
2. **Unoptimized database queries** - High Impact (3), Medium Effort (2) → 🟡 High Priority
3. **Large bundle size** - Medium Impact (2), High Effort (3) → 🟢 Low Priority

**Business Context Considerations:**
- App store reviews mentioning slow performance
- Upcoming marketing campaign requiring good performance
- Limited development capacity due to feature deadlines

**Adjusted Priorities:**
1. **Critical**: Fix image loading (quick win before marketing campaign)
2. **High**: Optimize database queries (plan for post-campaign sprint)
3. **Deferred**: Bundle size optimization (address in future release)

## Troubleshooting

### Disagreement on Impact Assessment

**Symptom:** Team members assign different impact scores to the same debt item

**Cause:** Different perspectives on business priorities or technical implications

**Solution:**
1. Facilitate discussion with specific examples
2. Involve stakeholders for business impact clarification
3. Use data (metrics, user feedback) to support assessments
4. Document assumptions and reasoning for future reference

### All Items Appear High Priority

**Symptom:** Most debt items are assessed as high impact and/or low effort

**Cause:** Insufficient discrimination in assessment criteria or scope too narrow

**Solution:**
1. Review assessment criteria and apply more strictly
2. Compare items relatively rather than absolutely
3. Consider expanding scope to include more varied debt types
4. Force-rank items within each category

### Effort Estimates Consistently Wrong

**Symptom:** Actual effort significantly differs from estimates

**Cause:** Insufficient understanding of complexity or missing dependencies

**Solution:**
1. Break down large items into smaller, more estimable pieces
2. Include buffer time for unknowns and dependencies
3. Track actual vs. estimated effort to improve future estimates
4. Involve multiple team members in estimation process

### Priority Changes Frequently

**Symptom:** Debt priorities change often, disrupting planning

**Cause:** Changing business priorities or new information about debt items

**Solution:**
1. Establish regular review cycles rather than ad-hoc changes
2. Set criteria for when priorities can be changed
3. Communicate priority changes clearly to all stakeholders
4. Maintain historical record of priority changes and reasons

## Related Resources

- [Technical Debt Assessment Task Usage Guide](technical-debt-assessment-task-usage-guide.md) - Complete assessment process
- [Assessment Criteria Guide](assessment-criteria-guide.md) - Detailed criteria for identifying debt
- [Technical Debt Tracking](../../state-tracking/permanent/technical-debt-tracking.md) - Permanent state tracking
- [Prioritization Matrix Template](../../templates/templates/prioritization-matrix-template.md) - Template for creating matrices
