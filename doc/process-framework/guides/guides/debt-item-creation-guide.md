---
id: PF-GDE-025
type: Document
category: General
version: 1.0
created: 2025-07-27
updated: 2025-07-27
guide_description: Guide for customizing technical debt item templates
guide_title: Debt Item Creation Guide
related_tasks: PF-TSK-023
guide_status: Active
related_script: New-DebtItem.ps1
---

# Debt Item Creation Guide

## Overview

This guide provides comprehensive instructions for creating and customizing technical debt item records using the New-DebtItem.ps1 script and debt-item-template.md. It helps you document individual technical debt items with proper categorization, impact assessment, and remediation planning to support systematic technical debt management.

## When to Use

Use this guide when you need to:

- Document a specific technical debt item identified during code review or assessment
- Create detailed records for debt items found during the Technical Debt Assessment Task (PF-TSK-023)
- Customize debt item templates for specific types of technical debt
- Ensure consistent documentation of technical debt across the project
- Plan remediation strategies for identified technical debt

> **🚨 CRITICAL**: Always use the New-DebtItem.ps1 script to create debt items - never create them manually. This ensures proper ID assignment and metadata integration with the framework.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Background](#background)
3. [Template Structure Analysis](#template-structure-analysis) _(Optional - for template customization guides)_
4. [Customization Decision Points](#customization-decision-points) _(Optional - for template customization guides)_
5. [Step-by-Step Instructions](#step-by-step-instructions)
6. [Quality Assurance](#quality-assurance) _(Optional - for template customization guides)_
7. [Examples](#examples)
8. [Troubleshooting](#troubleshooting)
9. [Related Resources](#related-resources)

## Prerequisites

Before you begin, ensure you have:

- Access to PowerShell and the New-DebtItem.ps1 script in `doc/process-framework/assessments/`
- Understanding of the technical debt item you want to document
- Familiarity with the project's codebase structure and components
- Access to the Technical Debt Assessment Task (PF-TSK-023) if this item was identified during an assessment
- Knowledge of the debt item's location, category, and initial priority assessment

## Background

Technical debt items are individual records that document specific instances of technical debt within the codebase. Unlike the broader Technical Debt Assessment Task (PF-TSK-023) which evaluates debt across the entire project, debt items focus on documenting, analyzing, and planning remediation for specific problems.

The debt item creation process uses a standardized template that ensures consistent documentation across all debt items. This consistency enables:

- Systematic prioritization based on impact and effort assessments
- Effective tracking of remediation progress
- Clear communication about technical debt to stakeholders
- Integration with the broader technical debt management framework

Each debt item receives a unique ID (PF-TDI-XXX) and includes comprehensive sections for problem description, impact assessment, effort estimation, and remediation planning.

## Template Structure Analysis

The debt-item-template.md is structured to capture comprehensive information about technical debt items. Understanding each section helps you customize the template effectively:

### Core Metadata Section

- **Document ID**: Automatically assigned (PF-TDI-XXX format)
- **Debt Category**: Categorizes the type of debt (Code Quality, Security, Performance, Architecture, Documentation)
- **Debt Priority**: Initial priority assessment (Critical, High, Medium, Low)
- **Debt Location**: Component or area where the debt exists

### Item Overview Section

Provides a quick summary of the debt item with key identifying information. This section is primarily populated by script parameters but may need customization for complex items.

### Description Section

**Critical customization area** - Contains three key subsections:

- **Problem Statement**: Detailed description of the technical debt issue
- **Current State**: How the issue currently manifests in the codebase
- **Desired State**: What the ideal solution would look like

### Technical Details Section

**High customization impact** - Includes:

- **Affected Components**: List of system components impacted by this debt
- **Code Locations**: Specific file paths, line numbers, or locations
- **Dependencies**: Relationships to other debt items or system components

### Impact Assessment Section

**Critical for prioritization** - Evaluates both business and technical impact:

- **Business Impact**: User experience, performance, security, maintainability
- **Technical Impact**: Development velocity, code quality, testing difficulty, deployment risk
- **Risk Level**: Overall risk assessment with supporting factors

### Effort Estimation Section

**Essential for planning** - Provides complexity and effort assessments:

- **Complexity Assessment**: Technical, business logic, and integration complexity
- **Estimated Effort**: Breakdown by analysis, implementation, testing, documentation
- **Required Skills**: Expertise needed for remediation

### Remediation Plan Section

**Action-oriented** - Contains approach options, recommendations, and implementation steps

### Prioritization Section

**Framework integration** - Connects to broader technical debt management processes

### Tracking Information Section

**Audit trail** - Links to assessments, status history, and related work

## Customization Decision Points

When customizing debt item templates, you'll face several critical decisions that impact the effectiveness of your documentation:

### Category Selection Decision

**Decision**: Which debt category best describes this item?
**Options**: Code Quality, Security, Performance, Architecture, Documentation
**Criteria**:

- Code Quality: Maintainability, readability, duplication issues
- Security: Vulnerabilities, authentication, authorization problems
- Performance: Speed, memory usage, scalability issues
- Architecture: Design patterns, component structure, coupling problems
- Documentation: Missing or outdated documentation
  **Impact**: Affects prioritization algorithms and assignment to appropriate team members

### Priority Assessment Decision

**Decision**: What initial priority should this debt item receive?
**Options**: Critical, High, Medium, Low
**Criteria**:

- Critical: Blocks development, security vulnerabilities, production issues
- High: Significantly impacts development velocity or user experience
- Medium: Moderate impact on maintainability or performance
- Low: Minor issues that can be addressed when convenient
  **Impact**: Determines scheduling and resource allocation

### Scope Definition Decision

**Decision**: How broadly or narrowly should this debt item be defined?
**Criteria**:

- Single focused issue: Easier to estimate and resolve
- Multiple related issues: May be more efficient to address together
- System-wide patterns: Consider breaking into multiple items
  **Impact**: Affects effort estimation accuracy and implementation complexity

### Detail Level Decision

**Decision**: How much technical detail should be included?
**Criteria**:

- High detail: Better for complex architectural issues
- Moderate detail: Appropriate for most code quality issues
- Minimal detail: Sufficient for straightforward problems
  **Impact**: Affects usefulness for future developers and implementation planning

### Remediation Approach Decision

**Decision**: Should multiple remediation options be documented?
**Criteria**:

- Complex issues: Document multiple approaches with trade-offs
- Straightforward issues: Single recommended approach may suffice
- Uncertain solutions: Include research phase in remediation plan
  **Impact**: Affects implementation flexibility and decision-making speed

## Step-by-Step Instructions

### 1. Prepare Debt Item Information

1. **Identify the technical debt issue** you want to document

   - Review code, architecture, or assessment findings
   - Gather specific details about the problem
   - Determine the scope and impact of the issue

2. **Collect required parameters** for the New-DebtItem.ps1 script:

   - **ItemTitle**: Clear, descriptive title (e.g., "Outdated Authentication Library", "Duplicated Validation Logic")
   - **Category**: Choose from Code Quality, Security, Performance, Architecture, Documentation
   - **Priority**: Initial assessment - Critical, High, Medium, Low
   - **Location**: Component or area where debt exists (e.g., "lib/auth/", "UI Components", "Database Layer")

3. **Research the debt item context**:
   - Identify affected code files and components
   - Understand the business and technical impact
   - Consider potential remediation approaches

**Expected Result:** You have all necessary information to create a comprehensive debt item record

### 2. Create the Debt Item Using New-DebtItem.ps1

1. **Navigate to the assessments directory**:

   ```powershell
   cd doc/process-framework/assessments
   ```

2. **Execute the New-DebtItem.ps1 script** with your prepared parameters:

   ```powershell
   # Basic usage
   .\New-DebtItem.ps1 -ItemTitle "Outdated Authentication Library" -Category "Security" -Priority "High" -Location "lib/auth/"

   # With editor opening
   .\New-DebtItem.ps1 -ItemTitle "Duplicated Validation Logic" -Category "Code Quality" -Priority "Medium" -Location "UI Components" -OpenInEditor
   ```

3. **Verify the debt item creation**:
   - Check the success message for the assigned ID (PF-TDI-XXX)
   - Note the file path where the debt item was created
   - Confirm the metadata fields were populated correctly

**Expected Result:** A new debt item file is created with proper ID assignment and basic metadata populated

### 3. Customize the Debt Item Template

1. **Open the created debt item file** for editing:

   ```powershell
   # Use the path provided in the creation success message
   code "doc/process-framework/assessments/technical-debt/debt-items/PF-TDI-XXX-your-item-title.md"
   ```

2. **Complete the Description section**:

   - **Problem Statement**: Provide detailed description of the technical debt issue
   - **Current State**: Describe how the issue currently manifests in the codebase
   - **Desired State**: Explain what the ideal solution would look like

3. **Fill in Technical Details**:
   - **Affected Components**: List all system components impacted by this debt
   - **Code Locations**: Add specific file paths, line numbers, or code snippets
   - **Dependencies**: Document relationships to other debt items or components

**Expected Result:** The debt item has comprehensive problem description and technical context

### 4. Complete Impact and Effort Assessment

1. **Assess Business Impact** for each category:

   - **User Experience**: Rate High/Medium/Low and describe impact on users
   - **Performance**: Evaluate system performance implications
   - **Security**: Assess security risks and vulnerabilities
   - **Maintainability**: Consider long-term maintenance burden

2. **Evaluate Technical Impact**:

   - **Development Velocity**: How does this debt slow down development?
   - **Code Quality**: Impact on overall codebase quality
   - **Testing Difficulty**: Does this make testing harder or less reliable?
   - **Deployment Risk**: Risk factors for production deployments

3. **Estimate Effort Requirements**:
   - **Complexity Assessment**: Rate technical, business logic, and integration complexity
   - **Time Estimates**: Break down effort by analysis, implementation, testing, documentation
   - **Required Skills**: List expertise needed for successful remediation

**Expected Result:** Comprehensive impact and effort assessment that supports prioritization decisions

### 5. Develop Remediation Plan

1. **Document Approach Options** (if multiple viable approaches exist):

   - Describe each approach with pros, cons, effort estimates, and risk levels
   - Consider both quick fixes and comprehensive solutions
   - Evaluate trade-offs between approaches

2. **Select and Document Recommended Approach**:

   - Choose the most appropriate option based on project constraints
   - Provide clear rationale for the selection
   - Consider timing, resources, and strategic alignment

3. **Create Implementation Steps**:
   - Break down the remediation into specific, actionable steps
   - Include validation and testing procedures
   - Define success criteria for completion

**Expected Result:** Clear, actionable remediation plan with justified approach selection

### Validation and Testing

After completing the debt item customization:

1. **Validate Template Completeness**:

   - Ensure all critical sections are filled with meaningful content
   - Verify that technical details are accurate and specific
   - Check that impact assessments are realistic and well-justified

2. **Test Integration with Framework**:

   - Confirm the debt item links properly to related assessments
   - Verify that the item can be referenced in technical-debt-tracking.md
   - Test that cross-references and dependencies are correctly documented

3. **Review for Consistency**:
   - Check that category, priority, and impact assessments align
   - Ensure effort estimates are reasonable for the described scope
   - Verify that the remediation plan addresses the identified problems

## Quality Assurance

Comprehensive quality assurance ensures your debt item documentation meets framework standards and provides value for technical debt management:

### Self-Review Checklist

**Content Completeness:**

- [ ] Problem Statement clearly describes the technical debt issue
- [ ] Current State accurately reflects how the issue manifests
- [ ] Desired State provides a clear vision for resolution
- [ ] Affected Components lists all impacted system parts
- [ ] Code Locations includes specific file paths or areas
- [ ] Impact assessments are realistic and well-justified
- [ ] Effort estimates are reasonable for the described scope
- [ ] Remediation plan provides actionable steps

**Framework Integration:**

- [ ] Category selection aligns with the type of technical debt
- [ ] Priority assessment reflects actual business and technical impact
- [ ] Dependencies and relationships are correctly documented
- [ ] Links to related assessments or tasks are accurate
- [ ] Metadata fields are properly completed

**Quality Standards:**

- [ ] Technical details are accurate and verifiable
- [ ] Language is clear and accessible to team members
- [ ] Examples and code snippets are relevant and correct
- [ ] Cross-references link to existing, accessible resources

### Validation Criteria

**Functional Validation:**

- Debt item can be referenced in technical-debt-tracking.md
- All internal links and cross-references work correctly
- Template integrates properly with assessment workflows
- Information supports effective prioritization decisions

**Content Validation:**

- Technical details are accurate and current
- Impact assessments reflect real project conditions
- Effort estimates align with project experience
- Remediation approaches are technically feasible

**Integration Validation:**

- Debt item connects properly to related framework components
- Category and priority align with project standards
- Dependencies are correctly identified and documented
- Item supports broader technical debt management objectives

**Standards Validation:**

- Follows project documentation conventions
- Uses consistent terminology and formatting
- Meets accessibility and usability requirements
- Aligns with technical debt management best practices

### Integration Testing Procedures

**Framework Integration Testing:**

1. Verify the debt item appears correctly in technical debt tracking
2. Test that cross-references to assessments work properly
3. Confirm that the item can be prioritized using project criteria
4. Validate integration with remediation planning processes

**Content Accuracy Testing:**

1. Review technical details with subject matter experts
2. Verify that code locations and examples are current
3. Test that remediation approaches are technically sound
4. Confirm that impact assessments reflect actual conditions

**Workflow Integration Testing:**

1. Test the debt item creation process end-to-end
2. Verify that the item supports decision-making workflows
3. Confirm that tracking and reporting processes work correctly
4. Validate that the item integrates with project management tools

## Examples

### Example 1: Security Debt Item - Outdated Authentication Library

Creating a debt item for an outdated authentication library:

```powershell
# Navigate to assessments directory
cd doc/process-framework/assessments

# Create the debt item
.\New-DebtItem.ps1 -ItemTitle "Outdated Authentication Library" -Category "Security" -Priority "High" -Location "lib/auth/"
```

**Customization approach:**

- **Problem Statement**: "The project uses an outdated version of the authentication library (v2.1) that contains known security vulnerabilities (CVE-2023-1234, CVE-2023-5678)"
- **Current State**: "Authentication works but exposes the application to potential security breaches. Library version is 18 months behind current stable release"
- **Desired State**: "Updated to latest stable version (v3.2) with all security patches applied and deprecated methods refactored"
- **Affected Components**: Authentication service, user management, session handling
- **Impact Assessment**: High security risk, medium development velocity impact
- **Effort Estimate**: 16 hours (4 analysis, 8 implementation, 3 testing, 1 documentation)

**Result:** Comprehensive security debt item that clearly communicates risk and remediation requirements

### Example 2: Code Quality Debt Item - Duplicated Validation Logic

Creating a debt item for code duplication:

```powershell
# Create with editor opening for immediate customization
.\New-DebtItem.ps1 -ItemTitle "Duplicated Validation Logic" -Category "Code Quality" -Priority "Medium" -Location "UI Components" -OpenInEditor
```

**Customization approach:**

- **Problem Statement**: "Form validation logic is duplicated across 8 different UI components, making maintenance difficult and error-prone"
- **Current State**: "Each form component implements its own validation with slight variations, leading to inconsistent user experience"
- **Desired State**: "Centralized validation service with reusable validation rules and consistent error handling"
- **Code Locations**: `lib/widgets/forms/`, `lib/screens/auth/`, `lib/screens/profile/`
- **Remediation Plan**: Extract common validation logic, create validation service, refactor existing components
- **Success Criteria**: Single source of truth for validation rules, consistent error messages, reduced code duplication by 80%

**Result:** Well-documented code quality debt item with clear refactoring plan

## Troubleshooting

### Script Execution Fails with "Execution Policy" Error

**Symptom:** PowerShell displays "execution of scripts is disabled on this system" when running New-DebtItem.ps1

**Cause:** PowerShell execution policy prevents script execution for security reasons

**Solution:**

1. Open PowerShell as Administrator
2. Run: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`
3. Confirm the change when prompted
4. Retry the New-DebtItem.ps1 script

### Debt Item File Not Created in Expected Location

**Symptom:** Script reports success but debt item file cannot be found

**Cause:** Script may be running from incorrect directory or path resolution issues

**Solution:**

1. Ensure you're running the script from `doc/process-framework/assessments/`
2. Check the full path reported in the success message
3. Verify the `technical-debt/debt-items/` directory exists
4. If directory is missing, create it manually: `New-Item -ItemType Directory -Path "technical-debt/debt-items" -Force`

### Template Sections Appear Incomplete or Malformed

**Symptom:** Created debt item has placeholder text or missing sections

**Cause:** Template file may be corrupted or script replacements failed

**Solution:**

1. Verify the debt-item-template.md file exists and is properly formatted
2. Check that all required parameters were provided to the script
3. Re-run the script with `-OpenInEditor` flag to immediately review the output
4. If issues persist, manually copy and customize the template file

### Cannot Link Debt Item to Assessment

**Symptom:** Unable to reference the debt item in technical debt tracking or assessments

**Cause:** Incorrect ID format or missing metadata fields

**Solution:**

1. Verify the debt item has a proper PF-TDI-XXX ID in the metadata
2. Check that the debt item file is in the correct directory structure
3. Ensure the technical-debt-tracking.md file exists and is accessible
4. Update the tracking file manually if automatic integration fails

### Impact Assessment Seems Inconsistent

**Symptom:** Priority level doesn't match the described impact and effort

**Cause:** Misalignment between initial script parameters and detailed assessment

**Solution:**

1. Review the impact assessment sections for accuracy
2. Adjust the priority level in the metadata if needed
3. Ensure business and technical impact ratings support the overall priority
4. Consider whether the debt item should be split into multiple items if scope is too broad

## Related Resources

- [Technical Debt Assessment Task (PF-TSK-023)](../../tasks/cyclical/technical-debt-assessment-task.md) - The broader task that often identifies debt items
- [Guide Creation Best Practices Guide (PF-GDE-024)](guide-creation-best-practices-guide.md) - Best practices for creating and customizing guides
- [New-DebtItem.ps1 Script](../../scripts/file-creation/New-DebtItem.ps1) - The script used to create debt items
- [Debt Item Template](../../templates/templates/debt-item-template.md) - The template customized by this guide
- [Technical Debt Tracking](../../state-tracking/permanent/technical-debt-tracking.md) - Central tracking for all technical debt items

<!--
TEMPLATE USAGE GUIDANCE:

ENHANCED METADATA:
- related_script: Include if this guide helps customize templates created by a specific script
- related_tasks: Include task IDs that this guide supports (comma-separated)
- These fields enhance traceability and make guides easier to discover and maintain

TEMPLATE CUSTOMIZATION GUIDE SECTIONS:
For guides that help customize templates created by scripts, use these optional sections:
- Template Structure Analysis: Break down the template structure and explain each section
- Customization Decision Points: Guide users through key customization decisions
- Validation and Testing: Include within Step-by-Step Instructions for testing procedures
- Quality Assurance: Provide comprehensive QA guidance with checklists and validation criteria

GENERAL GUIDE SECTIONS:
All guides use the standard sections: Overview, When to Use, Prerequisites, Background,
Step-by-Step Instructions, Examples, Troubleshooting, Related Resources
-->
