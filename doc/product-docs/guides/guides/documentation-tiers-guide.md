---
id: PD-GDE-001
type: Product Documentation
category: Guide
version: 1.0
created: 2025-06-10
updated: 2025-06-10
---

# Product Documentation Tiers

This document outlines the tiered approach to product documentation for features in the Breakout Buddies project. The goal is to ensure appropriate documentation based on feature complexity without creating unnecessary overhead.

## Documentation Tiers

### Tier 1: Simple Features (No Full TDD Required)

**Documentation Requirements:**
- Simple TDD using the [Simple TDD Template](/doc/product-docs/templates/tdd-t1-template.md)
- Brief technical notes in the task breakdown document
- Code comments for non-obvious implementations

**Examples of Tier 1 Features:**
- UI tweaks and styling changes
- Simple bug fixes
- Text content updates
- Minor enhancements to existing functionality
- Implementation of standard UI patterns

**Benefits:**
- Maintains development velocity for straightforward changes
- Reduces documentation overhead for simple features
- Focuses effort on implementation rather than documentation

### Tier 2: Moderate Features (Lightweight TDD)

**Documentation Requirements:**
- Lightweight TDD using the [Lightweight TDD Template](/doc/product-docs/templates/tdd-t2-template.md)
- Focus on key sections: data models, UI components, state management
- Brief implementation plan

**Examples of Tier 2 Features:**
- New screens using established patterns
- Extensions to existing functionality
- Features with moderate business logic
- Features affecting 2-3 components
- New API integrations using established patterns

**Benefits:**
- Provides sufficient planning without excessive documentation
- Ensures key technical decisions are documented
- Balances documentation effort with implementation needs

### Tier 3: Complex Features (Full TDD)

**Documentation Requirements:**
- Complete TDD using the [Complex TDD Template](/doc/product-docs/templates/tdd-t3-template.md)
- All sections thoroughly documented
- Detailed implementation plan
- Consider creating ADRs for significant architectural decisions

**Examples of Tier 3 Features:**
- Features spanning multiple components (4+)
- Features introducing new architectural patterns
- Features with complex business logic or data flows
- Features requiring significant database changes
- Features with complex security requirements
- Features introducing new technologies or integration points

**Benefits:**
- Ensures thorough planning for complex implementations
- Documents all aspects of the feature design
- Serves as a reference during implementation
- Helps identify potential issues before implementation begins

## Feature Complexity Assessment

Use the following criteria to assess the complexity of a feature and determine the appropriate documentation tier:

### Complexity Factors and Weights

Some factors have more impact on documentation needs than others. We use a weighted scoring system to reflect this:

| Factor | Weight | Low (1 point) | Medium (2 points) | High (3 points) |
|--------|--------|--------------|------------------|-----------------|
| **Scope** | 1.0 | Affects 1 component | Affects 2-3 components | Affects 4+ components |
| **State Management** | 1.0 | Simple local state | Moderate shared state | Complex global state |
| **Data Flow** | 1.0 | Simple data flow | Moderate data transformations | Complex data pipelines |
| **Business Logic** | 1.5 | Simple rules | Moderate rule complexity | Complex rules with many edge cases |
| **UI Complexity** | 0.5 | Standard widgets | Custom widgets | Complex interactive elements |
| **API Integration** | 1.0 | Simple API calls | Multiple API interactions | Complex API orchestration |
| **Database Changes** | 1.0 | No schema changes | Minor schema changes | Major schema changes |
| **Security Concerns** | 2.0 | Standard security | Moderate security needs | Complex security requirements |
| **New Technologies** | 1.0 | No new technologies | Minor new technologies | Major new technologies |

### Weighted Score Calculation

To calculate the weighted score:
1. Assign a score (1-3) for each factor
2. Multiply each score by its corresponding weight
3. Sum all weighted scores to get the total

### Complexity Score Interpretation

- **9-13 points**: Tier 1 (Simple) - No full TDD required
- **14-20 points**: Tier 2 (Moderate) - Lightweight TDD
- **21+ points**: Tier 3 (Complex) - Full TDD

*Note: The tier thresholds have been adjusted to account for the weighted scoring system.*

## Documentation Process

1. **Assess Complexity**: Use the complexity factors to determine the feature's complexity score
2. **Update Feature Tracking**: Add the appropriate documentation tier emoji (🔵/🟠/🔴) to the feature in the [Feature Tracking Document](/doc/process-framework/state-tracking/permanent/feature-tracking.md)
3. **Select Template**: Choose the appropriate documentation template based on the complexity tier:
   - **Tier 1 (🔵)**: Brief technical notes in task breakdown (no template required)
   - **Tier 2 (🟠)**: Use the [Lightweight TDD Template](/doc/product-docs/templates/tdd-t2-template.md)
   - **Tier 3 (🔴)**: Use the [TDD Template](/doc/product-docs/templates/tdd-t3-template.md)
4. **Create Documentation**: Create the documentation before implementation begins
5. **Review**: Review the documentation to ensure it addresses all aspects of the feature
6. **Implement**: Use the documentation as a guide during implementation
7. **Update**: Update the documentation if significant changes are made during implementation

## Integration with Feature Tracking

The [Feature Tracking Document](/doc/process-framework/state-tracking/permanent/feature-tracking.md) serves as the central source of truth for documentation tier assignments. Each feature in the tracking document includes:

- **Documentation Tier Emoji**: 🔵 (Tier 1), 🟠 (Tier 2), or 🔴 (Tier 3)
- **Documentation Links**: Direct links to technical design documents when available

### Assessment Status in Feature Tracking

- **Features with emojis** (🔵/🟠/🔴): Documentation tier has been assessed
- **Features without emojis**: Documentation tier assessment still needed

## Special Considerations

- **High-Risk Features**: Consider using a higher documentation tier for high-risk features, regardless of complexity score
- **Unfamiliar Domains**: Use a higher documentation tier when working in unfamiliar domains
- **Proof of Concept**: For features with technical uncertainty, consider creating a proof of concept before finalizing the TDD
- **Documentation Value**: Always consider the value that documentation will provide for the specific feature
- **Dependencies**: Features with many dependencies may require more detailed documentation
