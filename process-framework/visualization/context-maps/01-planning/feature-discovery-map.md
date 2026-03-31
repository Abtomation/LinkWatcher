---
id: PF-VIS-006
type: Process Framework
category: Context Map
version: 1.0
created: 2025-06-12
updated: 2025-06-12
related_task: PF-TSK-013
---

# Feature Discovery Context Map

This context map provides a visual guide to the components and relationships relevant to the Feature Discovery task. Use this map to identify which components require attention and how they interact.

## Visual Component Diagram

```mermaid
graph TD
    classDef critical fill:#f9d0d0,stroke:#d83a3a
    classDef important fill:#d0e8f9,stroke:#3a7bd8
    classDef reference fill:#d0f9d5,stroke:#3ad83f

    FeatureIdea[/Feature Idea/] --> DiscoveryTemplate[/Feature Discovery Template/]
    DiscoveryTemplate --> FeatureSpec([Feature Specification])
    ExistingFeatures[/Existing Features/] --> FeatureSpec
    UserNeeds[/User Needs Analysis/] --> FeatureSpec
    FeatureSpec -.-> FeatureTracking[/Feature Tracking/]
    FeatureSpec -.-> TierAssessment([Feature Tier Assessment])

    class FeatureIdea,DiscoveryTemplate critical
    class UserNeeds,FeatureSpec,ExistingFeatures important
    class FeatureTracking,TierAssessment reference
```

## Essential Components

### Critical Components (Must Understand)
- **Feature Idea**: Initial concept or idea for the feature
- **Feature Discovery Template**: Structured template for exploring and defining a feature

### Important Components (Should Understand)
- **User Needs Analysis**: Analysis of user requirements and needs
- **Feature Specification**: Detailed specification of the feature being defined
- **Existing Features**: Documentation of current features to ensure integration and avoid duplication

### Reference Components (Access When Needed)
- **Feature Tracking**: Documentation tracking feature status
- **Feature Tier Assessment**: Assessment of feature complexity for documentation purposes

## Key Relationships

1. **Feature Idea → Discovery Template**: The initial idea is documented using the discovery template
2. **Discovery Template → Feature Specification**: The template guides creation of the feature specification
3. **User Needs Analysis → Feature Specification**: User needs inform the feature requirements
4. **Existing Features → Feature Specification**: Existing functionality informs how the new feature integrates
5. **Feature Specification -.-> Feature Tracking**: The specification enables tracking of the feature
6. **Feature Specification -.-> Tier Assessment**: The specification feeds into complexity assessment

## Implementation in AI Sessions

1. Begin by examining the Feature Idea to understand the core concept
2. Use the Feature Discovery Template to structure the discovery process
3. Analyze User Needs to understand the problem being solved
4. Review Existing Features to ensure integration and avoid duplication
5. Create a detailed Feature Specification based on findings
6. Update Feature Tracking with the new feature information
7. Prepare for Feature Tier Assessment if proceeding to implementation

## Related Documentation

- [Feature Tracking](../../../../doc/product-docs/state-tracking/permanent/feature-tracking.md) - Feature status tracking

---
