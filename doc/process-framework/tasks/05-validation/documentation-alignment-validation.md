---
id: PF-TSK-034
type: Process Framework
category: Task Definition
version: 1.4
created: 2025-08-16
updated: 2026-03-04
task_type: Discrete
---

# Documentation Alignment Validation

## Purpose & Context

Systematically validates selected features for documentation alignment, ensuring that Technical Design Documents (TDDs), Architecture Decision Records (ADRs), and API documentation accurately reflect the implemented code and maintain consistency across the codebase.

## AI Agent Role

**Role**: Documentation Specialist
**Mindset**: Detail-oriented, accuracy-focused, consistency-driven
**Focus Areas**: Documentation accuracy, TDD-code alignment, ADR compliance, API documentation completeness
**Communication Style**: Identify documentation gaps and inconsistencies, recommend specific documentation updates, ask about documentation standards when multiple approaches exist

## When to Use

- When validating selected features for documentation alignment as part of the validation framework
- Before major releases to ensure documentation accuracy and completeness
- When investigating discrepancies between documentation and implementation
- As part of regular documentation quality assessments
- When onboarding new team members who rely on accurate documentation

## Context Requirements

[View Context Map for this task](../../visualization/context-maps/05-validation/documentation-alignment-validation-map.md)

- **Critical (Must Read):**

  - **Feature Validation Guide** - [Feature Validation Guide](../../guides/05-validation/feature-validation-guide.md) - Comprehensive guide for conducting feature validation
  - **Feature Tracking** - [Feature Tracking](../../state-tracking/permanent/feature-tracking.md) - Current status of features to be validated
  - **Validation Tracking** - Link to the active validation tracking state file for the current validation round — see [Feature Validation Guide](../../guides/05-validation/feature-validation-guide.md) for setup
  - **Validation Report Template** - [Validation Report Template](../../templates/05-validation/validation-report-template.md) - Template for creating validation reports
  - **Technical Design Documents** - [TDD Directory](../../../product-docs/technical/design) - Technical specifications to validate against implementation

- **Important (Load If Space):**

  - **Architecture Decision Records** - [ADR Directory](../../../product-docs/technical/architecture/decisions) - Architectural decisions to validate compliance
  - **API Documentation** - [API Documentation](../../../product-docs/technical/api) - API specifications to validate against implementation
  - **Codebase Structure** - Source code directory - Source code for selected features to analyze
  - **New-ValidationReport Script** - [../../scripts/file-creation/05-validation/New-ValidationReport.ps1](../../scripts/file-creation/05-validation/New-ValidationReport.ps1) - Script for generating validation reports
  - **Component Relationship Index** - [Component Relationship Index](../../../product-docs/technical/architecture/component-relationship-index.md) - For understanding component interactions
  - **Feature Implementation State Files** - [Feature State Directory](../../state-tracking/features/) - Implementation state files with feature status, TDD/FDD links, and validation context

- **Reference Only (Access When Needed):**
  - **Documentation Standards** - [Documentation Guide](../../guides/05-validation/documentation-guide.md) - Standards for documentation quality and consistency
  - **TDD Creation Guide** - [TDD Creation Guide](../../guides/02-design/tdd-creation-guide.md) - Understanding TDD structure and requirements
  - **ADR Creation Guide** - [ADR Creation Guide](../../guides/02-design/architecture-decision-creation-guide.md) - Understanding ADR format and content
  - **Visual Notation Guide** - [Visual Notation Guide](../../guides/support/visual-notation-guide.md) - For interpreting context map diagrams
  - **ID Registry** - [ID Registry](../../../id-registry.json) - For understanding validation report ID assignments

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished! 🚨**
>
> **⚠️ MANDATORY: Use the ..\scripts\file-creation\New-ValidationReport.ps1 script for generating validation reports.**
>
> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

### Preparation

1. **Review Validation Scope**: Identify the specific selected features to validate (typically 3-4 features per session)
2. **Load Context Files**: Review feature implementations, existing TDDs, ADRs, and API documentation
3. **Prepare Documentation Criteria**: Review documentation standards and alignment requirements
4. **🚨 CHECKPOINT**: Present validation scope, selected features, TDD/ADR/API documentation inventory, and alignment criteria to human partner for approval before execution

### Execution

> **📋 Criteria Handling**:
>
> **Tier Assessment Verification**: For each feature, verify that the current tier assignment is still correct based on the feature's actual complexity and architectural significance. After confirming the tier, check that all documentation required for that tier level exists (e.g., Tier 2 requires TDD + FDD; Tier 3 additionally requires ADRs). Flag any missing required documentation as a finding.
>
> **Tier 1 features** lack TDDs by design. For TDD Alignment:
> - Substitute **Configuration/Code Documentation Accuracy**: validate that inline comments, docstrings, and README sections accurately describe the feature's behavior and interfaces.
> - Score the substituted criterion on the same 0–3 scale and note the substitution in the report.
>
> **ADR Compliance**: If ADRs exist for a feature, validate that the implementation complies with them. If no ADRs exist, skip this criterion — assessing whether an ADR should exist is handled by PF-TSK-031 (Architectural Consistency Validation).

5. **TDD Alignment Analysis**: Compare Technical Design Documents with actual implementation to identify discrepancies
6. **ADR Compliance Validation**: Verify that architectural decisions documented in ADRs are properly implemented and followed
7. **API Documentation Accuracy**: Cross-reference API documentation with actual API implementations and interfaces
8. **Documentation Completeness Assessment**: Identify missing documentation for implemented features and functionality
9. **Generate Validation Report**: Create detailed validation report using the automation script
   ```powershell
   # Navigate to validation directory and create documentation alignment report
   Set-Location "doc/product-docs/validation"
    ..\scripts\file-creation\New-ValidationReport.ps1 -ValidationType "DocumentationAlignment" -FeatureIds "0.2.1,0.2.2,0.2.3,0.2.4" -SessionNumber 1
   ```
10. **Score Documentation Criteria**: Apply 4-point scoring system (0-3) to each documentation alignment criterion
11. **Document Findings**: Record specific documentation gaps, inconsistencies, and improvement recommendations
12. **Root Cause Analysis**: For each significant documentation gap identified:
    - Identify which task in the development workflow should have created or updated the documentation (e.g., TDD Creation, Feature Implementation, Code Refactoring)
    - Check whether that task's process steps or completion checklist explicitly require this documentation update
    - If the originating task lacks coverage, record it as a process improvement opportunity (via New-ProcessImprovement.ps1) in addition to the documentation remediation action item
13. **🚨 CHECKPOINT**: Present documentation alignment scoring, gap analysis findings, root cause analysis, and remediation recommendations to human partner for review before finalization

### Finalization

14. **Update Validation Tracking**: Update the validation tracking matrix with report creation date and link
15. **Review Quality Gates**: Ensure validation meets minimum quality thresholds (average score ≥ 2.0)
16. **Plan Remediation**: For scores below threshold, create action items for documentation improvements
17. **🤖 AUTOMATED: Update Technical Debt Tracking**: Add any new open issues identified during validation to [Technical Debt Tracking](../../state-tracking/permanent/technical-debt-tracking.md) using the automation script:

    ```powershell
    .\doc\process-framework\scripts\update\Update-TechDebt.ps1 -Add -Description "Description" -Category "Category" -Location "Location" -Priority "Priority" -EstimatedEffort "Effort" -AssessmentId "PF-VAL-XXX" -Notes "Notes"
    ```
18. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Outputs

- **Documentation Alignment Validation Report** - Detailed validation report with scoring and findings, created in doc/product-docs/validation/reports/documentation-alignment/PF-VAL-XXX-documentation-alignment-features-[feature-range].md
- **Updated Validation Tracking** - Matrix cell updated with report creation date and link in the active validation tracking state file
- **Documentation Gap Analysis** - Comprehensive analysis of missing or outdated documentation identified during validation
- **Remediation Action Items** - Specific recommendations for improving documentation alignment and completeness

## State Tracking

The following state files must be updated as part of this task:

- **Validation Tracking State File** - Update the active validation tracking matrix with report creation date and link (file location depends on validation round — see Feature Validation Guide)
- [Documentation Map](../../documentation-map.md) - Add new validation report to the appropriate section with ID, path, and description
- [Technical Debt Tracking](../../state-tracking/permanent/technical-debt-tracking.md) - Add new open issues identified during validation to the Technical Debt Registry

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

Before considering this task finished:

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] Documentation Alignment validation report generated using ../../scripts/file-creation/05-validation/New-ValidationReport.ps1 script
  - [ ] Validation report contains comprehensive scoring (0-3 scale) for all documentation criteria
  - [ ] Documentation gaps and inconsistencies documented with specific remediation recommendations
  - [ ] Report saved in correct directory: `doc/product-docs/validation/reports/documentation-alignment`
- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] Validation tracking state file matrix updated with report creation date and link
  - [ ] [Documentation Map](../../documentation-map.md) updated with new validation report entry
  - [ ] **AUTOMATED**: [Technical Debt Tracking](../../state-tracking/permanent/technical-debt-tracking.md) updated with new open issues using `Update-TechDebt.ps1`
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Completion Instructions](../../guides/framework/feedback-form-completion-instructions.md) for each tool used, using task ID "PF-TSK-034" and context "Documentation Alignment Validation"

## Next Tasks

- [**Extensibility & Maintainability Validation**](extensibility-maintainability-validation-task.md) - Validate how well documentation supports future extensibility and maintainability
- [**AI Agent Continuity Validation**](ai-agent-continuity-validation-task.md) - Assess documentation quality for AI agent context and workflow continuity
- [**TDD Creation**](../02-design/tdd-creation-task.md) - Create or update Technical Design Documents based on validation findings

## Related Resources

- [Documentation Guide](../../guides/05-validation/documentation-guide.md) - Standards for documentation quality and consistency
- [TDD Creation Guide](../../guides/02-design/tdd-creation-guide.md) - Guide for creating and updating Technical Design Documents
- [ADR Creation Guide](../../guides/02-design/architecture-decision-creation-guide.md) - Guide for creating Architecture Decision Records
- API documentation standards and best practices for your technology stack
