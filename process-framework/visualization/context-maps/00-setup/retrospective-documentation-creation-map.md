---
id: PF-VIS-046
type: Process Framework
category: Context Map
version: 1.2
created: 2026-02-17
updated: 2026-04-05
workflow_phase: support
related_task: PF-TSK-066
---

# Retrospective Documentation Creation Context Map

This context map provides a visual guide to the components and relationships relevant to the Retrospective Documentation Creation task. Use this map to identify which components require attention and how they interact.

## Visual Component Diagram

```mermaid
graph TD
    classDef critical fill:#f9d0d0,stroke:#d83a3a
    classDef important fill:#d0e8f9,stroke:#3a7bd8
    classDef reference fill:#d0f9d5,stroke:#3ad83f

    MasterState([Retrospective Master State]) --> EnrichedStates([Enriched Implementation States])
    EnrichedStates --> TierTask[Tier Assessment Task]
    TierTask --> FeatureTracking([Feature Tracking])
    EnrichedStates --> QualityGate{{Quality Gate Check}}
    QualityGate --> |"As-Built"| FDD_AB[FDD - Descriptive]
    QualityGate --> |"Target-State"| FDD_TS[FDD - Prescriptive + Gap Analysis]
    QualityGate --> |"As-Built"| TDD_AB[TDD - Descriptive]
    QualityGate --> |"Target-State"| TDD_TS[TDD - Prescriptive + Gap Analysis]
    FDD_TS --> TechDebt([Tech Debt Items])
    TDD_TS --> TechDebt
    TechDebt --> QAR[/Quality Assessment Report/]
    EnrichedStates --> TestSpec[Test Spec Creation Task]
    TestSpec --> TestMigration[Test Migration via PF-TSK-053]
    EnrichedStates --> ADR[ADR Creation Task]
    DocTiers[Documentation Tiers] --> TierTask
    DocMap[Documentation Map] -.-> FeatureTracking
    APITask[API Design Task] -.-> FDD_AB
    DBTask[DB Schema Design Task] -.-> TDD_AB

    class MasterState,EnrichedStates,FeatureTracking,TierTask critical
    class DocTiers,QualityGate,FDD_AB,FDD_TS,TDD_AB,TDD_TS,TestSpec,TestMigration,ADR important
    class DocMap,APITask,DBTask,TechDebt,QAR reference
```

## Essential Components

### Critical Components (Must Understand)
- **[Retrospective Master State File](../../../../process-framework-local/state-tracking/temporary/old/retrospective-master-state.md)**: Tracks overall progress; read to verify Phase 2 complete, update after each session with assessment and documentation progress
- **[Enriched Feature Implementation State Files](/doc/state-tracking/features)**: Per-feature files from PF-TSK-065 with Design Decisions, Dependencies, and Implementation Patterns; serve as evidence base for all documentation
- **[Feature Tracking](../../../../doc/state-tracking/permanent/feature-tracking.md)**: Permanent registry updated with tier assignments and all document links as they are created
- **[Feature Tier Assessment Task](../../../tasks/01-planning/feature-tier-assessment-task.md)**: Task for creating or validating tier assessments based on actual code analysis

### Important Components (Should Understand)
- **[Documentation Tiers README](../../../../doc/documentation-tiers/README.md)**: Defines tier documentation requirements (Tier 2+: FDD+TDD+TestSpec+Test Migration, Foundation: +ADR)
- **[FDD Creation Task](../../../tasks/02-design/fdd-creation-task.md)**: Task for creating Functional Design Documents (Tier 2+) from implemented features
- **[TDD Creation Task](../../../tasks/02-design/tdd-creation-task.md)**: Task for creating Technical Design Documents (Tier 2+) reverse-engineered from code
- **[Test Specification Creation Task](../../../tasks/03-testing/test-specification-creation-task.md)**: Task for creating Test Specifications (Tier 2+) documenting existing tests
- **[Integration and Testing Task](../../../tasks/04-implementation/integration-and-testing.md)**: Task for migrating pre-existing tests to framework structure (Tier 2+, migration mode)
- **[ADR Creation Task](../../../tasks/02-design/adr-creation-task.md)**: Task for creating Architecture Decision Records (Foundation 0.x.x) documenting architectural patterns

### Reference Components (Access When Needed)
- **[Documentation Map](../../../PF-documentation-map.md)**: Registry for all new documents created (update after finalization)
- **[API Design Task](../../../tasks/02-design/api-design-task.md)**: Task for documenting existing API contracts (conditional per tier assessment)
- **[Database Schema Design Task](../../../tasks/02-design/database-schema-design-task.md)**: Task for documenting existing database schema (conditional per tier assessment)

## Key Relationships

1. **Retrospective Master State → Enriched Implementation States**: Master state tracks which features need assessment and which need documentation
2. **Enriched Implementation States → Tier Assessment Task**: Analysis content (complexity factors, patterns) provides evidence for tier assignment
3. **Tier Assessment Task → Feature Tracking**: Tier assignments are recorded in Feature Tracking
4. **Enriched Implementation States → Quality Gate Check**: Section 8 "Quality Assessment" (populated in PF-TSK-065) determines documentation mode — As-Built features get descriptive docs, Target-State features get prescriptive docs with gap analysis
5. **Target-State FDD/TDD → Tech Debt Items**: Each gap in the Gap Analysis section generates a tech debt item via `Update-TechDebt.ps1 -Add`
6. **Tech Debt Items → Quality Assessment Report**: One QAR per Target-State feature links all gaps and tech debt items together with a remediation sequence
7. **Documentation Tiers → All Documentation Tasks**: Tier determines which documents are required (Tier 2+: FDD+TDD+TestSpec+Test Migration, Foundation: +ADR)
8. **Documentation Tasks → Feature Tracking**: All created document links are added to Feature Tracking in appropriate columns

## Implementation in AI Sessions

1. **Every Session Start**: Read [Retrospective Master State](../../../../process-framework-local/state-tracking/temporary/old/retrospective-master-state.md) to verify Phase 2 complete and identify features needing assessment/documentation
2. **Per-Feature Documentation Loop** (priority: Foundation → Tier 3 → Tier 2):
   - **Assess**: Create/validate tier assessment using [Feature Tier Assessment Task](../../../tasks/01-planning/feature-tier-assessment-task.md) based on analysis from enriched implementation state
   - **Update Tracking**: Add tier to [Feature Tracking](../../../../doc/state-tracking/permanent/feature-tracking.md), mark "📊 Assessment Created" in master state
   - **Document Tier 2+ Features** (check Section 8 "Quality Assessment" for classification):
     - **As-Built features**: Create descriptive FDD/TDD (mark "Retrospective", set `documentation_mode: as-built`)
     - **Target-State features**: Create prescriptive FDD/TDD with Gap Analysis section (mark "Retrospective — Target-State", set `documentation_mode: target-state`)
     - **Target-State features**: Generate tech debt items from gaps, create Quality Assessment Report (PD-QAR-XXX)
     - Add document links to Feature Tracking
   - **Document Tier 2+ Features (continued)**:
     - Create Test Specification using [Test Specification Creation Task](../../../tasks/03-testing/test-specification-creation-task.md) (document existing tests, mark "Retrospective")
     - Migrate pre-existing tests using [Integration and Testing Task](../../../tasks/04-implementation/integration-and-testing.md) in migration mode (restructure to framework template, assign TE-TST IDs, add pytest markers, remove originals)
     - Add document links to Feature Tracking
   - **Document Foundation Features**:
     - Create ADRs using [ADR Creation Task](../../../tasks/02-design/adr-creation-task.md) for architectural decisions (mark unknowns clearly, mark "Retrospective")
     - Add document links to Feature Tracking
   - **Conditional Documents**: Create API/DB design docs if tier assessment indicates
3. **Every Session End**: Update [Retrospective Master State](../../../../process-framework-local/state-tracking/temporary/old/retrospective-master-state.md) with completed assessments and documents, log session notes
4. **Finalization Phase**:
   - Verify all codebase coverage (100%), all features have assessments, all Tier 2+ have FDD+TDD+Test Specs (+ tests migrated if pre-existing), Foundation features have ADRs, all Target-State features have Quality Assessment Reports with linked tech debt items
   - Update [Documentation Map](../../../PF-documentation-map.md) with all new documents
   - Calculate final metrics, archive master state file

## Related Documentation

- [Retrospective Documentation Creation Task (PF-TSK-066)](../../../tasks/00-setup/retrospective-documentation-creation.md) - Full task definition with detailed process steps
- [Codebase Feature Analysis Task (PF-TSK-065)](../../../tasks/00-setup/codebase-feature-analysis.md) - Prerequisite task that enriches feature implementation state files
- [Documentation Tiers README](../../../../doc/documentation-tiers/README.md) - Tier definitions and documentation requirements
- [Feature Tier Assessment Task](../../../tasks/01-planning/feature-tier-assessment-task.md) - How to create tier assessments
- [FDD Creation Task](../../../tasks/02-design/fdd-creation-task.md) - How to create Functional Design Documents
- [TDD Creation Task](../../../tasks/02-design/tdd-creation-task.md) - How to create Technical Design Documents
- [Test Specification Creation Task](../../../tasks/03-testing/test-specification-creation-task.md) - How to create Test Specifications
- [Integration and Testing Task](../../../tasks/04-implementation/integration-and-testing.md) - How to migrate pre-existing tests to framework structure
- [ADR Creation Task](../../../tasks/02-design/adr-creation-task.md) - How to create Architecture Decision Records
- [Quality Assessment Report Template](../../../templates/00-setup/quality-assessment-report-template.md) - Template for Target-State feature quality reports
- [New-QualityAssessmentReport.ps1](../../../scripts/file-creation/00-setup/New-QualityAssessmentReport.ps1) - Script for creating Quality Assessment Reports
- [Visual Notation Guide](../../../guides/support/visual-notation-guide.md) - Understanding diagram symbols and notation

---

*Note: This context map is part of the Retrospective Documentation Creation task (PF-TSK-066), the final step in adopting the process framework into an existing project.*
