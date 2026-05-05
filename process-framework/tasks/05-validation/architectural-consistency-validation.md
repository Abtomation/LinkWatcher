---
id: PF-TSK-031
type: Process Framework
category: Task Definition
version: 1.1
created: 2025-08-15
updated: 2026-04-03
---

# Architectural Consistency Validation

## Purpose & Context

Systematically validates selected features for architectural pattern adherence, ADR compliance, and interface consistency to ensure the codebase maintains structural integrity and follows established architectural decisions.

## AI Agent Role

**Role**: Software Architect
**Mindset**: Systematic, pattern-focused, consistency-oriented
**Focus Areas**: Architectural patterns, design principles, interface contracts, ADR compliance
**Communication Style**: Identify architectural deviations and inconsistencies, recommend pattern improvements, ask about architectural trade-offs when multiple valid approaches exist

## When to Use

- When validating selected features for architectural consistency as part of the validation framework
- Before major architectural changes to establish baseline consistency
- When investigating architectural debt or pattern violations
- As part of regular codebase health assessments
- When onboarding new team members to demonstrate architectural standards

## Context Requirements

[View Context Map for this task](../../visualization/context-maps/05-validation/architectural-consistency-validation-map.md)

- **Critical (Must Read):**

  - **Feature Validation Guide** - [Feature Validation Guide](../../guides/05-validation/feature-validation-guide.md) - Comprehensive guide for conducting feature validation
  - **Feature Tracking** - [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) - Current status of features to be validated
  - **Validation Tracking** - Link to the active validation tracking state file for the current validation round — see [Feature Validation Guide](../../guides/05-validation/feature-validation-guide.md) for setup
  - **Validation Report Template** - [Validation Report Template](../../templates/05-validation/validation-report-template.md) - Template for creating validation reports
  - **Architecture Decision Records** - [ADR Directory](../../../doc/technical) - Architectural decisions to validate against

- **Important (Load If Space):**

  <!-- Component Relationship Index - Removed: file deleted -->
  - **Technical Design Documents** - [TDD Directory](../../../doc/technical/tdd) - Technical specifications for selected features
  - **Codebase Structure** - Source code directory - Source code for selected features
  - **New-ValidationReport Script** - [../../scripts/file-creation/05-validation/New-ValidationReport.ps1](../../scripts/file-creation/05-validation/New-ValidationReport.ps1) - Script for generating validation reports

- **Reference Only (Access When Needed):**
  - **Visual Notation Guide** - [Visual Notation Guide](../../guides/support/visual-notation-guide.md) - For interpreting context map diagrams
  - **ID Registry** - [PD ID Registry](../../PF-id-registry.json) - For understanding validation report ID assignments
  - **Documentation Map** - [Product Documentation Map](../../../doc/PD-documentation-map.md) - For updating with new validation reports

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished!**
>
> **⚠️ MANDATORY: Use the [..\..\scripts\file-creation\05-validation\New-ValidationReport.ps1](../../scripts/file-creation/05-validation/New-ValidationReport.ps1) script for generating validation reports.**
>
> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

### Preparation

1. **Review Validation Scope**: Identify the specific selected features to validate (typically 2-3 features per session)
2. **Load Context Files**: Review feature tracking, ADRs, and technical design documents for the selected features
3. **Prepare Validation Criteria**: Review architectural patterns, design principles, and interface contracts that should be validated
4. **🚨 CHECKPOINT**: Present validation scope, selected features, context files review, and validation criteria to human partner for approval before execution

### Execution

5. **Analyze Architectural Patterns**: Examine each feature's implementation for adherence to established patterns (Repository, Service Layer, etc.)
6. **Validate ADR Compliance**: Check that implementation follows architectural decisions documented in ADRs
   > **When no ADR exists for a feature**: Assess whether the feature's architectural decisions are significant enough to warrant an ADR (e.g., non-obvious pattern choices, trade-offs with alternatives). If an ADR should exist, note it as a finding and recommend creating one using [New-ArchitectureDecision.ps1](/process-framework/scripts/file-creation/02-design/New-ArchitectureDecision.ps1) and the [Architecture Decision Creation Guide](/process-framework/guides/02-design/architecture-decision-creation-guide.md). If not (feature follows established project patterns without notable decisions), skip this criterion.
7. **Assess Interface Consistency**: Verify that interfaces follow consistent patterns and contracts across features
   > **Justified divergence check**: Not every pattern difference is a defect. Before flagging an inconsistency, verify that different design constraints (stateless vs stateful, pure vs side-effecting, hot-path vs setup-only) don't justify the divergence. "No issues found" is a valid validation outcome — do not manufacture findings to fill a report.
8. **Generate Validation Report**: Create detailed validation report using the automation script
   ```powershell
   # Navigate to validation directory and create architectural consistency report
   Set-Location "doc/validation"
   ..\..\scripts\file-creation\05-validation\New-ValidationReport.ps1 -ValidationType "ArchitecturalConsistency" -FeatureIds "0.2.1,0.2.2,0.2.3" -SessionNumber 1
   ```
9. **Score Validation Criteria**: Apply 4-point scoring system (0-3) to each validation criterion
10. **Document Findings**: Record specific architectural deviations, inconsistencies, and recommendations
11. **🚨 CHECKPOINT**: Present validation scoring, architectural findings, and recommendations to human partner for review before finalization

### Finalization

12. **Update Validation Tracking**: Update the validation tracking matrix with report creation date and link
13. **Review Quality Gates**: Check if validation meets minimum quality thresholds (average score ≥ 2.0)
14. **Plan Remediation**: For scores below threshold, create action items for architectural improvements
15. **🤖 AUTOMATED: Update Technical Debt Tracking**: Add any new open issues identified during validation — **apply the [Tech Debt Quality Gate](/process-framework/guides/05-validation/feature-validation-guide.md#tech-debt-item-quality-gate) filters before creating each item** — to [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md) using the automation script:

    ```powershell
    process-framework/scripts/update/Update-TechDebt.ps1 -Add -Description "Description" -Dims "AC" -Location "Location" -Priority "Priority" -EstimatedEffort "Effort" -AssessmentId "PF-VAL-XXX" -Notes "Notes"
    ```
16. **Generate Round Summary** (if this is the final dimension in the current validation round): Generate a consolidated validation summary:
    ```powershell
    process-framework/scripts/file-creation/05-validation/Generate-ValidationSummary.ps1 -OutputPath "doc/validation/summaries/" -SummaryType "Detailed"
    ```
17. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Outputs

- **Architectural Consistency Validation Report** - Detailed validation report with scoring and findings, created in doc/validation/reports/architectural-consistency/PF-VAL-XXX-architectural-consistency-features-[feature-range].md
- **Updated Validation Tracking Matrix** - Validation tracking file updated with report creation date and link in the architectural consistency column for validated features
- **Remediation Action Items** - List of architectural improvements needed for features scoring below quality threshold (if applicable)

## State Tracking

The following state files must be updated as part of this task:

- **Validation Tracking State File** - Update the active validation tracking matrix with report creation date and link (file location depends on validation round — see Feature Validation Guide)
- [Product Documentation Map](../../../doc/PD-documentation-map.md) - Add new validation report to the validation reports section
- [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md) - Add new open issues identified during validation to the Technical Debt Registry

## ⚠️ MANDATORY Task Completion Checklist

**TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF**

Before considering this task finished:

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] Architectural consistency validation report created with proper ID and scoring
  - [ ] Validation report contains detailed findings and recommendations
  - [ ] Quality gate assessment completed (average score ≥ 2.0 or remediation plan created)
- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] Validation tracking state file updated with report creation date and link
  - [ ] [Product Documentation Map](../../../doc/PD-documentation-map.md) updated with new validation report entry
  - [ ] **AUTOMATED**: [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md) updated with new open issues using `Update-TechDebt.ps1`
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Guide](../../guides/framework/feedback-form-guide.md) for each tool used, using task ID "PF-TSK-031" and context "Architectural Consistency Validation"

## Next Tasks

- **Code Quality & Standards Validation** - Next validation type to apply to the same or different set of selected features
- **Integration & Dependencies Validation** - Cross-feature validation that builds on architectural consistency findings
- **Documentation Alignment Validation** - Verify that architectural documentation matches validated implementation patterns

## Related Resources

- [Feature Validation Guide](../../guides/05-validation/feature-validation-guide.md) - Comprehensive guide for conducting feature validation
- [Architecture Decision Records](../../../doc/technical/adr) - Architectural decisions to validate against
- Project architecture guidelines - Platform-specific architectural patterns
