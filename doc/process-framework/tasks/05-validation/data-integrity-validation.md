---
id: PF-TSK-076
type: Process Framework
category: Task Definition
version: 1.0
created: 2026-03-23
updated: 2026-03-23
task_type: Discrete
---

# Data Integrity Validation

## Purpose & Context

Systematically validates selected features for data consistency, constraint enforcement, migration safety, and backup/recovery patterns to ensure the application correctly preserves, transforms, and protects data throughout its lifecycle — from input through processing to storage and retrieval.

## AI Agent Role

**Role**: Data Quality Engineer
**Mindset**: Consistency-focused, corruption-prevention-oriented, recovery-aware
**Focus Areas**: Data validation rules, constraint enforcement, referential integrity, migration safety, idempotency, backup/recovery, data transformation correctness
**Communication Style**: Identify data corruption risks and integrity gaps, recommend defensive patterns, ask about data criticality levels and acceptable data loss thresholds

## When to Use

- When validating selected features for data integrity as part of the validation framework
- Before deploying features that modify, transform, or migrate data
- When investigating data corruption, inconsistency, or loss incidents
- As part of data migration planning or database schema change reviews
- When features involve concurrent data access, caching with write-back, or multi-step transactions

## Context Requirements

[View Context Map for this task](../../visualization/context-maps/05-validation/data-integrity-validation-map.md)

- **Critical (Must Read):**

  - **Feature Validation Guide** - [Feature Validation Guide](../../guides/05-validation/feature-validation-guide.md) - Comprehensive guide for conducting feature validation
  - **Feature Tracking** - [Feature Tracking](../../../product-docs/state-tracking/permanent/feature-tracking.md) - Current status of features to be validated
  - **Validation Tracking** - Link to the active validation tracking state file for the current validation round — see [Feature Validation Guide](../../guides/05-validation/feature-validation-guide.md) for setup
  - **Validation Report Template** - [Validation Report Template](../../templates/05-validation/validation-report-template.md) - Template for creating validation reports
  - **Codebase Structure** - Source code directory - Source code for selected features to analyze

- **Important (Load If Space):**

  - **Database Schema Designs** - [Schema Directory](../../../product-docs/technical/database/schemas) - Data model specifications
  - **Technical Design Documents** - [TDD Directory](../../../product-docs/technical/architecture/design-docs/tdd) - Data handling design specifications
  - **Test Suites** - Test directory - Existing data integrity and edge case tests
  - **New-ValidationReport Script** - [../../scripts/file-creation/05-validation/New-ValidationReport.ps1](../../scripts/file-creation/05-validation/New-ValidationReport.ps1) - Script for generating validation reports
  <!-- Component Relationship Index - Removed: file deleted -->

- **Reference Only (Access When Needed):**
  - **Architecture Decision Records** - [ADR Directory](../../../product-docs/technical/architecture) - Data-related architectural decisions
  - **Visual Notation Guide** - [Visual Notation Guide](../../guides/support/visual-notation-guide.md) - For interpreting context map diagrams
  - **ID Registry** - [PD ID Registry](../../PF-id-registry.json) - For understanding validation report ID assignments

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished! 🚨**
>
> **⚠️ MANDATORY: Use the [..\..\scripts\file-creation\05-validation\New-ValidationReport.ps1](../../scripts/file-creation/05-validation/New-ValidationReport.ps1) script for generating validation reports.**
>
> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

### Preparation

1. **Review Validation Scope**: Identify the specific selected features to validate (typically 2-3 features per session)
2. **Load Context Files**: Review feature implementations, data models, and existing data integrity tests for the selected features
3. **Prepare Data Integrity Criteria**: Review data model specifications, constraint requirements, and transaction consistency expectations
4. **🚨 CHECKPOINT**: Present validation scope, selected features, context files review, and data integrity criteria to human partner for approval before execution

### Execution

5. **Input Data Validation Review**: Examine data entry points for proper type checking, range validation, format enforcement, and handling of null/empty/malformed inputs
6. **Constraint Enforcement Analysis**: Verify that uniqueness constraints, referential integrity, business rules, and invariants are enforced at the appropriate layer (database, application, or both)
7. **Data Transformation Correctness**: Review data transformation pipelines for lossless conversion, proper encoding handling, rounding errors, and edge case handling (empty collections, boundary values)
8. **Concurrent Access Safety**: Assess data operations under concurrent access — race conditions, dirty reads, lost updates, and proper use of transactions or optimistic locking
9. **Error Recovery & Idempotency**: Evaluate how data operations handle failures — partial writes, interrupted transactions, retry safety, and rollback completeness
10. **Backup & Recovery Patterns**: Review data persistence for backup capabilities, recovery procedures, and data export/import integrity
11. **Generate Validation Report**: Create detailed validation report using the automation script
    ```powershell
    # Navigate to validation directory and create data integrity validation report
    Set-Location "doc/product-docs/validation"
    ..\..\scripts\file-creation\05-validation\New-ValidationReport.ps1 -ValidationType "DataIntegrity" -FeatureIds "X.Y.Z,A.B.C" -SessionNumber 1
    ```
12. **Score Data Integrity Criteria**: Apply 4-point scoring system (0-3) to each data integrity criterion
13. **Document Findings**: Record specific data integrity risks, constraint gaps, and improvement recommendations
14. **🚨 CHECKPOINT**: Present data integrity scoring, risk findings, and improvement recommendations to human partner for review before finalization

### Finalization

15. **Update Validation Tracking**: Update the validation tracking matrix with report creation date and link
16. **Review Quality Gates**: Ensure validation meets minimum quality thresholds (average score ≥ 2.0)
17. **Plan Remediation**: For scores below threshold, create action items for data integrity improvements — prioritize by data loss risk severity
18. **🤖 AUTOMATED: Update Technical Debt Tracking**: Add any new open issues identified during validation to [Technical Debt Tracking](../../../product-docs/state-tracking/permanent/technical-debt-tracking.md) using the automation script:

    ```powershell
    .\doc\process-framework\scripts\update\Update-TechDebt.ps1 -Add -Description "Description" -Category "Data Integrity" -Location "Location" -Priority "Priority" -EstimatedEffort "Effort" -AssessmentId "PF-VAL-XXX" -Notes "Notes"
    ```
19. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Outputs

- **Data Integrity Validation Report** - Detailed validation report with scoring and findings, created in doc/product-docs/validation/reports/data-integrity/PF-VAL-XXX-data-integrity-features-[feature-range].md
- **Updated Validation Tracking Matrix** - Validation tracking file updated with report creation date and link in the data integrity column for validated features
- **Data Integrity Improvement Recommendations** - List of data integrity improvements needed for features scoring below quality threshold (if applicable)

## State Tracking

The following state files must be updated as part of this task:

- **Validation Tracking State File** - Update the active validation tracking matrix with report creation date and link (file location depends on validation round — see Feature Validation Guide)
- [Documentation Map](../../documentation-map.md) - Add new validation report to the validation reports section
- [Technical Debt Tracking](../../../product-docs/state-tracking/permanent/technical-debt-tracking.md) - Add new open issues identified during validation to the Technical Debt Registry

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

Before considering this task finished:

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] Data integrity validation report created with proper ID and scoring
  - [ ] Validation report contains detailed findings and data integrity recommendations
  - [ ] Quality gate assessment completed (average score ≥ 2.0 or remediation plan created)
- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] Validation tracking state file updated with report creation date and link
  - [ ] [Documentation Map](../../documentation-map.md) updated with new validation report entry
  - [ ] **AUTOMATED**: [Technical Debt Tracking](../../../product-docs/state-tracking/permanent/technical-debt-tracking.md) updated with new open issues using `Update-TechDebt.ps1`
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Completion Instructions](../../guides/framework/feedback-form-completion-instructions.md) for each tool used, using task ID "PF-TSK-076" and context "Data Integrity Validation"

## Next Tasks

- **Security & Data Protection Validation** - Data integrity measures intersect with data protection requirements
- **Integration & Dependencies Validation** - Data flow integrity across component boundaries
- **Performance & Scalability Validation** - Constraint enforcement and transaction patterns affect performance

## Related Resources

- [Feature Validation Guide](../../guides/05-validation/feature-validation-guide.md) - Comprehensive guide for conducting feature validation
- [Database Schema Designs](../../../product-docs/technical/database/schemas) - Data model specifications
