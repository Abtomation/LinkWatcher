---
id: PF-ASS-000
type: Process Framework
category: Tier Assessment
version: 1.0
created: 2023-06-15
updated: 2025-05-29
---

# Documentation Tier Assignments

This directory contains the documentation tier assessments for all features in the Breakout Buddies project.

## Purpose

The purpose of these assessments is to determine the appropriate level of technical documentation required for each feature based on its complexity, and to evaluate whether specialized API and database design documentation is needed. This ensures that:

1. Complex features receive thorough documentation
2. Simple features don't suffer from documentation overhead
3. Documentation effort is proportional to feature complexity
4. Features requiring API or database design work are identified early in the planning process

## Documentation Tier System

We use a three-tier documentation system based on feature complexity:

- **Tier 1 (Simple)** 🔵: Brief technical notes in task breakdown (normalized score: 1.0-1.6)
- **Tier 2 (Moderate)** 🟠: Lightweight Technical Design Document (TDD) (normalized score: 1.61-2.3)
- **Tier 3 (Complex)** 🔴: Full Technical Design Document (TDD) (normalized score: 2.31-3.0)

### Normalized Scoring System

Features are assessed using a normalized scoring system that:
1. Assigns weights to different complexity factors
2. Calculates a weighted average (rather than a sum)
3. Results in a final score between 1.0 and 3.0

This approach allows for flexibility in adding or removing assessment criteria without changing the tier thresholds.

#### Factor Weights

| Factor | Weight | Reason for Weight |
|--------|--------|------------------|
| **Business Logic** | 2.5 | Complex business logic requires the most thorough documentation - explains "why" not just "how" |
| **Security Concerns** | 2.0 | Security aspects are critical and need detailed documentation for audit and compliance |
| **API Integration** | 1.5 | External dependencies and integration patterns need thorough documentation |
| **Data Flow** | 1.5 | Complex transformations and flow logic are hard to understand from code alone |
| **State Management** | 1.2 | Important for understanding component interactions |
| **Database Changes** | 1.2 | Schema changes have wide impact and need clear documentation |
| **New Technologies** | 1.0 | Important for team learning but becomes standard over time |
| **Scope** | 0.8 | Wide scope doesn't necessarily mean complex documentation needs |
| **UI Complexity** | 0.5 | UI patterns are often self-explanatory and require less documentation |

For detailed information on the tiered approach, see the [Documentation Tiers](../../../process-framework/methodologies/documentation-tiers/doc/product-docs/technical/README.md) document.

## Assessment Process

Each feature undergoes a comprehensive three-part assessment:

### 1. Documentation Tier Assessment
Features are evaluated using a standardized template that assesses complexity factors:

1. **Scope**: Number of components affected
2. **State Management**: Complexity of state management
3. **Data Flow**: Complexity of data transformations
4. **Business Logic**: Complexity of business rules
5. **UI Complexity**: Complexity of user interface
6. **API Integration**: Complexity of API interactions
7. **Database Changes**: Extent of database changes
8. **Security Concerns**: Security requirements
9. **New Technologies**: New technologies introduced

Each factor is scored from 1 (low complexity) to 3 (high complexity). The normalized score is calculated as:

```
Normalized Score = Sum(Factor Score × Factor Weight) / Sum(Factor Weights)
```

### 2. API Design Requirements Evaluation
Determines if the feature requires dedicated API design documentation by evaluating:
- New or modified API endpoints
- Complex request/response structures
- External service integrations
- Authentication/authorization changes

### 3. Database Design Requirements Evaluation
Determines if the feature requires dedicated database schema design documentation by evaluating:
- New database tables or schema modifications
- Complex relationships or constraints
- Performance indexing strategies
- Data migration requirements

This comprehensive approach ensures that both documentation complexity and specialized design needs are identified early in the planning process.

For a detailed guide on how to assess features and assign documentation tiers, see the [Assessment Guide](../../guides/guides/assessment-guide.md).

## File Structure

Each feature has its own assessment file in the `assessments` subfolder, named according to its assessment ID and feature ID:

- `assessments<!-- /ART-ASS-001-1.1.1-email-password-registration.md - File not found -->`
- `assessments<!-- /ART-ASS-002-1.1.2-social-login-integration.md - File not found -->`
- etc.

Each assessment is an artifact with a unique ID (ART-ASS-XXX) that is automatically assigned when the assessment is created.

## Creating New Assessments

To create a new assessment, use the provided PowerShell script:

```powershell
create-assessment-template.ps1 -FeatureId "1.1.3" -FeatureName "Password Reset Flow" -FeatureDescription "Allows users to reset their password via email verification" [-OpenInEditor]
```

This will:
1. Create a new assessment file with a unique artifact ID (ART-ASS-XXX)
2. Pre-populate the assessment template with the feature information
3. Open the file in your editor if the -OpenInEditor switch is used

## Tracking and Viewing Assessments

The progress of documentation tier assessments is tracked directly in the [feature-tracking.md](../../state-tracking/permanent/feature-tracking.md) file.

For information on assessment status and how to view assessed features, refer to the <!-- [Documentation Assessment](../../state-tracking/permanent/feature-tracking.md#documentation-assessment) - File not found --> section in the feature tracking document.

## Next Steps

1. Complete assessments for all remaining features following the priority order defined in the <!-- [feature-tracking.md](../../state-tracking/permanent/feature-tracking.md#assessment-priority) - File not found --> file
2. Create Technical Design Documents (TDDs) for Tier 2 and Tier 3 features
3. Review and adjust tier assignments as needed during implementation

## Updating Assessments

As features evolve and more information becomes available, assessments may be updated. When updating an assessment:

1. Document the reason for the change
2. Update the assessment date
3. Update the [Feature Tracking Document](../../state-tracking/permanent/feature-tracking.md) if the tier changes, using the format: 🔵/🟠/🔴 [Tier 1/2/3](../../../process-framework/methodologies/documentation-tiers/assessment-link-placeholder)

For details on assessment priority refer to the [Feature Tracking Document](../../state-tracking/permanent/feature-tracking.md) under the "Documentation Assessment Process" section.

## Adjusting Tiers During Implementation

During implementation, the actual complexity of a feature may differ from the initial assessment. The [Documentation Tier Adjustment Process](../../../process-framework/methodologies/documentation-tiers/adjustment-process.md) provides a structured approach for:

1. Identifying when a tier adjustment is needed during implementation
2. Reassessing complexity factors based on implementation realities
3. Updating documentation requirements to match the adjusted tier
4. Documenting the reasons for the adjustment

This process ensures that documentation requirements remain aligned with the actual complexity of features as they are implemented.
