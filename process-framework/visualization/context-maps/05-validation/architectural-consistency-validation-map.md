---
id: PF-VIS-028
type: Process Framework
category: Context Map
version: 1.0
created: 2025-08-15
updated: 2025-08-15
related_task: PF-TSK-031
---

# Architectural Consistency Validation Context Map

This context map provides a visual guide to the components and relationships relevant to the Architectural Consistency Validation task. Use this map to identify which components require attention and how they interact.

## Visual Component Diagram

```mermaid
graph TD
    classDef critical fill:#f9d0d0,stroke:#d83a3a
    classDef important fill:#d0e8f9,stroke:#3a7bd8
    classDef reference fill:#d0f9d5,stroke:#3ad83f

    FT([Feature Tracking]) --> VT([Validation Tracking])
    FT --> VRT[Validation Report Template]
    ADR[ADR Directory] --> VRT
    VT --> VRS[New-ValidationReport Script]
    CRI[Component Relationship Index] -.-> TDD[Technical Design Documents]
    LIB[src/ Codebase] --> VRT
    VRS --> VR[(Validation Report)]

    class FT,VT,VRT,ADR critical
    class CRI,TDD,LIB,VRS important
    class VR reference
```

## Essential Components

### Critical Components (Must Understand)

- **Feature Tracking**: Current status and details of features to be validated
- **Validation Tracking**: Active validation tracking matrix tracking progress across all validation types
- **Validation Report Template**: Standardized template for creating architectural consistency reports
- **ADR Directory**: Architecture Decision Records that define the architectural standards to validate against

### Important Components (Should Understand)

- **Component Relationship Index**: Understanding of how components interact architecturally
- **Technical Design Documents**: Detailed specifications for selected features
- **src/ Codebase**: Source code implementations to analyze for architectural patterns
- **New-ValidationReport Script**: Automation tool for generating validation reports

### Reference Components (Access When Needed)

- **Validation Report**: Final output document with scoring and architectural findings

## Key Relationships

1. **Feature Tracking → Validation Tracking**: Feature status determines which features are ready for validation
2. **Feature Tracking → Validation Report Template**: Feature details populate the validation report structure
3. **ADR Directory → Validation Report Template**: Architectural decisions provide validation criteria and standards
4. **Validation Tracking → New-ValidationReport Script**: Matrix tracking guides report generation parameters
5. **src/ Codebase → Validation Report Template**: Source code analysis provides validation findings
6. **Component Relationship Index -.-> Technical Design Documents**: Optional reference for understanding architectural context

## Implementation in AI Sessions

1. Begin by examining **Feature Tracking** and **Validation Tracking** to identify validation scope
2. Load **ADR Directory** to understand architectural standards and decision criteria
3. Review **Validation Report Template** to understand expected output structure
4. Analyze **src/ Codebase** implementations against architectural patterns and ADR compliance
5. Use **New-ValidationReport Script** to generate standardized validation reports
6. Update **Validation Tracking** matrix with completed validation results

## Related Documentation

- [Architectural Consistency Validation Task](../../../tasks/05-validation/architectural-consistency-validation.md) - Complete task definition and process
- [Feature Tracking](../../../../doc/state-tracking/permanent/feature-tracking.md) - Current status of features
- Validation Tracking State File - Active validation tracking matrix (file location depends on validation round)
- [Architecture Decision Records](/doc/technical/adr) - Architectural standards and decisions

---
