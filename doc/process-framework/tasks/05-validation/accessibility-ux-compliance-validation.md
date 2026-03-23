---
id: PF-TSK-075
type: Process Framework
category: Task Definition
version: 1.0
created: 2026-03-23
updated: 2026-03-23
task_type: Discrete
---

# Accessibility / UX Compliance Validation

## Purpose & Context

Systematically validates selected features for accessibility standards compliance, UX consistency, keyboard navigation support, and inclusive design patterns to ensure the application is usable by people with diverse abilities and meets established accessibility guidelines.

## AI Agent Role

**Role**: Accessibility Specialist
**Mindset**: Inclusive-design-focused, standards-compliant, user-empathy-driven
**Focus Areas**: WCAG compliance, keyboard navigation, screen reader compatibility, color contrast, focus management, semantic markup, touch target sizing
**Communication Style**: Identify accessibility barriers with specific WCAG criteria references, recommend inclusive alternatives, ask about target accessibility level (A, AA, AAA) and platform-specific requirements

## When to Use

- When validating selected features for accessibility compliance as part of the validation framework
- Before releasing UI-facing features to production
- When investigating accessibility complaints or audit findings
- As part of regulatory compliance reviews (ADA, Section 508, EN 301 549)
- When features involve user interaction, form inputs, navigation, or visual content presentation

## Context Requirements

[View Context Map for this task](../../visualization/context-maps/05-validation/accessibility-ux-compliance-validation-map.md)

- **Critical (Must Read):**

  - **Feature Validation Guide** - [Feature Validation Guide](../../guides/05-validation/feature-validation-guide.md) - Comprehensive guide for conducting feature validation
  - **Feature Tracking** - [Feature Tracking](../../state-tracking/permanent/feature-tracking.md) - Current status of features to be validated
  - **Validation Tracking** - Link to the active validation tracking state file for the current validation round — see [Feature Validation Guide](../../guides/05-validation/feature-validation-guide.md) for setup
  - **Validation Report Template** - [Validation Report Template](../../templates/05-validation/validation-report-template.md) - Template for creating validation reports
  - **Codebase Structure** - Source code directory - UI components and layouts for selected features

- **Important (Load If Space):**

  - **UI Design Documents** - UI/UX design specifications and style guides
  - **Design System** - Component library documentation and accessibility patterns
  - **Platform Guidelines** - Platform-specific accessibility guidelines (Material Design, Apple HIG, Web Content Accessibility Guidelines)
  - **New-ValidationReport Script** - [../../scripts/file-creation/05-validation/New-ValidationReport.ps1](../../scripts/file-creation/05-validation/New-ValidationReport.ps1) - Script for generating validation reports
  - **Component Relationship Index** - [Component Relationship Index](../../../product-docs/technical/architecture/component-relationship-index.md) - For understanding component interactions

- **Reference Only (Access When Needed):**
  - **Architecture Decision Records** - [ADR Directory](../../../product-docs/technical/architecture) - Accessibility-related architectural decisions
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

1. **Review Validation Scope**: Identify the specific selected features to validate (typically 2-3 features per session)
2. **Load Context Files**: Review feature UI implementations, design specifications, and existing accessibility configurations
3. **Prepare Accessibility Criteria**: Review target WCAG level, platform guidelines, and project-specific accessibility requirements
4. **🚨 CHECKPOINT**: Present validation scope, selected features, context files review, and accessibility criteria to human partner for approval before execution

### Execution

5. **Semantic Structure Analysis**: Verify that UI elements use proper semantic markup/widgets — headings hierarchy, landmark regions, list structures, and form labels
6. **Keyboard Navigation Review**: Test that all interactive elements are reachable and operable via keyboard — tab order, focus indicators, keyboard shortcuts, and focus trapping in modals
7. **Screen Reader Compatibility**: Assess that content is properly announced by assistive technology — alt text for images, ARIA labels for interactive elements, live region announcements for dynamic content
8. **Color & Contrast Assessment**: Verify that text, icons, and interactive elements meet minimum contrast ratios (4.5:1 for normal text, 3:1 for large text per WCAG AA)
9. **Touch Target & Interaction Review**: Ensure interactive elements meet minimum size requirements (44x44 dp/px) and have sufficient spacing to prevent accidental activation
10. **Motion & Animation Review**: Check that animations respect user preferences (prefers-reduced-motion), and that no content flashes more than 3 times per second
11. **Generate Validation Report**: Create detailed validation report using the automation script
    ```powershell
    # Navigate to validation directory and create accessibility validation report
    Set-Location "doc/product-docs/validation"
    ..\scripts\file-creation\New-ValidationReport.ps1 -ValidationType "AccessibilityUXCompliance" -FeatureIds "X.Y.Z,A.B.C" -SessionNumber 1
    ```
12. **Score Accessibility Criteria**: Apply 4-point scoring system (0-3) to each accessibility criterion
13. **Document Findings**: Record specific accessibility barriers with WCAG success criteria references and remediation recommendations
14. **🚨 CHECKPOINT**: Present accessibility scoring, barrier findings, and remediation recommendations to human partner for review before finalization

### Finalization

15. **Update Validation Tracking**: Update the validation tracking matrix with report creation date and link
16. **Review Quality Gates**: Ensure validation meets minimum quality thresholds (average score ≥ 2.0)
17. **Plan Remediation**: For scores below threshold, create action items for accessibility improvements — prioritize by impact on users with disabilities
18. **🤖 AUTOMATED: Update Technical Debt Tracking**: Add any new open issues identified during validation to [Technical Debt Tracking](../../state-tracking/permanent/technical-debt-tracking.md) using the automation script:

    ```powershell
    .\doc\process-framework\scripts\update\Update-TechDebt.ps1 -Add -Description "Description" -Category "Accessibility" -Location "Location" -Priority "Priority" -EstimatedEffort "Effort" -AssessmentId "PF-VAL-XXX" -Notes "Notes"
    ```
19. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Outputs

- **Accessibility / UX Compliance Validation Report** - Detailed validation report with scoring and findings, created in doc/product-docs/validation/reports/accessibility-ux-compliance/PF-VAL-XXX-accessibility-ux-compliance-features-[feature-range].md
- **Updated Validation Tracking Matrix** - Validation tracking file updated with report creation date and link in the accessibility column for validated features
- **Accessibility Remediation Recommendations** - List of accessibility improvements needed for features scoring below quality threshold, with WCAG criteria references (if applicable)

## State Tracking

The following state files must be updated as part of this task:

- **Validation Tracking State File** - Update the active validation tracking matrix with report creation date and link (file location depends on validation round — see Feature Validation Guide)
- [Documentation Map](../../documentation-map.md) - Add new validation report to the validation reports section
- [Technical Debt Tracking](../../state-tracking/permanent/technical-debt-tracking.md) - Add new open issues identified during validation to the Technical Debt Registry

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

Before considering this task finished:

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] Accessibility / UX compliance validation report created with proper ID and scoring
  - [ ] Validation report contains detailed findings with WCAG criteria references
  - [ ] Quality gate assessment completed (average score ≥ 2.0 or remediation plan created)
- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] Validation tracking state file updated with report creation date and link
  - [ ] [Documentation Map](../../documentation-map.md) updated with new validation report entry
  - [ ] **AUTOMATED**: [Technical Debt Tracking](../../state-tracking/permanent/technical-debt-tracking.md) updated with new open issues using `Update-TechDebt.ps1`
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Completion Instructions](../../guides/framework/feedback-form-completion-instructions.md) for each tool used, using task ID "PF-TSK-075" and context "Accessibility / UX Compliance Validation"

## Next Tasks

- **Documentation Alignment Validation** - Verify that accessibility requirements are properly documented
- **Code Quality & Standards Validation** - Accessibility patterns are part of broader code quality standards
- **Extensibility & Maintainability Validation** - Accessible component patterns affect long-term maintainability

## Related Resources

- [Feature Validation Guide](../../guides/05-validation/feature-validation-guide.md) - Comprehensive guide for conducting feature validation
- [Component Relationship Index](../../../product-docs/technical/architecture/component-relationship-index.md) - For understanding component interactions
- WCAG 2.1 Guidelines - Web Content Accessibility Guidelines (external reference)
