---
id: PF-GDE-042
type: Document
category: General
version: 1.2
created: 2025-08-17
updated: 2026-03-04
guide_title: Feature Validation Guide
guide_status: Active
guide_description: Comprehensive guide for conducting feature validation using the multi-dimension validation framework
related_script: New-ValidationReport.ps1
related_tasks: PF-TSK-031,PF-TSK-032,PF-TSK-033,PF-TSK-034,PF-TSK-035,PF-TSK-036,PF-TSK-072,PF-TSK-073,PF-TSK-074,PF-TSK-075,PF-TSK-076,PF-TSK-077
---

# Feature Validation Guide

## Overview

This guide provides comprehensive instructions for conducting feature validation using the multi-dimension validation framework. It covers all aspects of the validation process, from preparation through execution to reporting and remediation tracking.

The feature validation framework systematically evaluates a project's selected features across multiple specialized validation dimensions to ensure code quality, maintainability, security, performance, and AI agent continuity. The framework includes 11 validation dimensions — not all dimensions apply to every project or feature. Use the [Validation Preparation task](../../tasks/05-validation/validation-preparation.md) (PF-TSK-077) to select which features and dimensions to validate.

> **⚠️ Project Adaptation Required**: This guide uses illustrative example feature IDs (e.g., `0.2.1`–`0.2.4`). Replace them with your project's actual features as listed in your [Feature Tracking](../../../product-docs/state-tracking/permanent/feature-tracking.md) file.

## When to Use

Use this guide when:

- **Conducting feature validation** using any of the 11 validation dimension tasks
- **Planning validation rounds** — start with [Validation Preparation](../../tasks/05-validation/validation-preparation.md) to select features and dimensions
- **Interpreting validation results** and creating improvement roadmaps
- **Training new team members** on the validation framework
- **Establishing validation baselines** for new features

**Triggers for validation:**

- Major feature implementations completed
- Before significant architectural changes
- Quarterly codebase health assessments
- Prior to major releases
- When technical debt concerns arise

> **🚨 CRITICAL**: This validation framework requires systematic execution across multiple sessions. Do not attempt to validate all features and types in a single session due to context limitations.

## Table of Contents

1. [Dimension Catalog](#dimension-catalog)
2. [Prerequisites](#prerequisites)
3. [Background](#background)
4. [Validation Framework Overview](#validation-framework-overview)
5. [Validation Types Deep Dive](#validation-types-deep-dive)
6. [Step-by-Step Instructions](#step-by-step-instructions)
7. [Scoring and Interpretation](#scoring-and-interpretation)
8. [Examples](#examples)
9. [Troubleshooting](#troubleshooting)
10. [Related Resources](#related-resources)

## Dimension Catalog

The validation framework includes 11 dimensions. Each dimension has its own task definition with specialized AI agent role, validation criteria, and execution steps. **Not every dimension applies to every project or feature** — the [Validation Preparation task](../../tasks/05-validation/validation-preparation.md) guides dimension selection.

### Core Dimensions (Universal — apply to all projects)

| # | Dimension | Task | Focus | AI Agent Role |
|---|-----------|------|-------|---------------|
| 1 | **Architectural Consistency** | [PF-TSK-031](../../tasks/05-validation/architectural-consistency-validation.md) | Pattern adherence, ADR compliance, interface consistency | Software Architect |
| 2 | **Code Quality & Standards** | [PF-TSK-032](../../tasks/05-validation/code-quality-standards-validation.md) | SOLID principles, code style, language best practices | Code Quality Auditor |
| 3 | **Integration & Dependencies** | [PF-TSK-033](../../tasks/05-validation/integration-dependencies-validation.md) | Dependency health, interface contracts, data flow | Integration Specialist |
| 4 | **Documentation Alignment** | [PF-TSK-034](../../tasks/05-validation/documentation-alignment-validation.md) | TDD alignment, ADR compliance, API docs accuracy | Documentation Analyst |

### Extended Dimensions (Widely applicable — evaluate per project)

| # | Dimension | Task | Focus | Apply When |
|---|-----------|------|-------|------------|
| 5 | **Extensibility & Maintainability** | [PF-TSK-035](../../tasks/05-validation/extensibility-maintainability-validation.md) | Extension points, configuration flexibility, testing support | Growing/evolving projects |
| 6 | **AI Agent Continuity** | [PF-TSK-036](../../tasks/05-validation/ai-agent-continuity-validation.md) | Context clarity, modular structure, documentation quality | AI-assisted development workflows |
| 7 | **Security & Data Protection** | [PF-TSK-072](../../tasks/05-validation/security-data-protection-validation.md) | Auth, input validation, secrets management, OWASP | Features handling user input, auth, sensitive data, or external APIs |
| 8 | **Performance & Scalability** | [PF-TSK-073](../../tasks/05-validation/performance-scalability-validation.md) | Resource efficiency, algorithmic complexity, I/O patterns | Features with I/O, large data, real-time processing, or production load |
| 9 | **Observability** | [PF-TSK-074](../../tasks/05-validation/observability-validation.md) | Logging coverage, monitoring, alerting, error traceability | Background processes, async operations, production monitoring needs |
| 10 | **Accessibility / UX Compliance** | [PF-TSK-075](../../tasks/05-validation/accessibility-ux-compliance-validation.md) | WCAG compliance, keyboard navigation, screen reader support | UI-focused features or user-facing interactions |
| 11 | **Data Integrity** | [PF-TSK-076](../../tasks/05-validation/data-integrity-validation.md) | Data consistency, constraint enforcement, migration safety | Features modifying, transforming, or migrating data |

### Dimension Selection Guidance

- **Core dimensions** (1-4) should be applied to virtually all features in any project
- **Extended dimensions** (5-11) are evaluated per feature based on applicability criteria
- Mark non-applicable dimensions as **N/A** in the validation tracking matrix with brief rationale
- The [Validation Preparation task](../../tasks/05-validation/validation-preparation.md) formalizes dimension selection with documented rationale

> **Bounded catalog**: These 11 dimensions cover the full universe of software quality attributes. New dimensions are rare — if you think one is needed, check whether it fits as a sub-criterion of an existing dimension first.

## Prerequisites

Before conducting feature validation, ensure you have:

- **Access to the codebase**: Full read access to the project's application code
- **Validation framework setup**: All validation tasks, templates, and scripts are available
- **Feature knowledge**: Understanding of the features to be validated (see [Feature Tracking](../../../product-docs/state-tracking/permanent/feature-tracking.md))
- **Task system familiarity**: Experience with the AI Task-Based Development System
- **Context maps access**: Ability to read and interpret validation task context maps
- **Validation tracking access**: Read/write access to the validation tracking file

## Background

### Why Feature Validation Matters

Features implemented across multiple sessions by different AI agents can develop inconsistencies and quality variations. Systematic validation ensures these issues are identified and addressed.

**Key Challenges Addressed:**

- **Consistency Gaps**: Different implementation styles across features
- **Integration Weaknesses**: Misalignment between interconnected components
- **Documentation Drift**: Implementation diverging from design documents
- **Technical Debt**: Accumulated shortcuts requiring attention
- **AI Agent Continuity**: Code structure optimization for future AI agents
- **Extensibility Concerns**: Foundation readiness for future development

### Feature Scope

Consult your project's [Feature Tracking](../../../product-docs/state-tracking/permanent/feature-tracking.md) file for the definitive list of features to validate. The table below is an **illustrative example**:

| Feature ID | Feature Name            | Description                   |
| ---------- | ----------------------- | ----------------------------- |
| 0.2.1      | Core Architecture       | Central orchestration layer   |
| 0.2.2      | Data Storage Layer      | Persistence and data access   |
| 0.2.3      | Configuration System    | Settings loading & validation |
| 0.2.4      | Logging & Monitoring    | Application observability     |
| ...        | *(your other features)* | ...                           |

### Validation Philosophy

The validation framework uses a **multi-dimensional approach** where each selected feature is evaluated across 6 specialized validation types. This creates a comprehensive validation matrix (N features × 6 validation types) that ensures no aspect of code quality is overlooked.

## Validation Framework Overview

### Validation Dimensions

The feature validation framework consists of 11 specialized validation dimensions (see [Dimension Catalog](#dimension-catalog) above), each designed to evaluate different aspects of code quality. The 6 original dimensions are detailed below; for the 5 newer dimensions (Security, Performance, Observability, Accessibility, Data Integrity), refer to their task definitions directly.

1. **Architectural Consistency Validation** (PF-TSK-031)

   - **Focus**: Pattern adherence, ADR compliance, interface consistency
   - **Sessions**: 4 sessions (2-3 features per session)
   - **Key Areas**: Repository patterns, service layers, dependency direction

2. **Code Quality & Standards Validation** (PF-TSK-032)

   - **Focus**: Code style, SOLID principles, language best practices
   - **Sessions**: 4 sessions (2-3 features per session)
   - **Key Areas**: Formatting, naming conventions, performance

3. **Integration & Dependencies Validation** (PF-TSK-033)

   - **Focus**: Dependency health, interface contracts, data flow
   - **Sessions**: 3 sessions (cross-feature analysis)
   - **Key Areas**: Service integration, state management, API contracts

4. **Documentation Alignment Validation** (PF-TSK-034)

   - **Focus**: TDD alignment, ADR compliance, API documentation
   - **Sessions**: 3 sessions (3-4 features per session)
   - **Key Areas**: Design document accuracy, API documentation currency

5. **Extensibility & Maintainability Validation** (PF-TSK-035)

   - **Focus**: Extension points, configuration flexibility, testing support
   - **Sessions**: 3 sessions (cross-cutting concerns)
   - **Key Areas**: Modularity, scalability, maintainability

6. **AI Agent Continuity Validation** (PF-TSK-036)
   - **Focus**: Context clarity, modular structure, documentation quality
   - **Sessions**: 2 sessions (workflow optimization)
   - **Key Areas**: Code readability, context optimization, documentation clarity

### Validation Matrix Structure

The validation framework creates an N×M matrix (one row per selected feature, one column per selected validation dimension). Columns vary per validation round — only dimensions selected during [Validation Preparation](../../tasks/05-validation/validation-preparation.md) appear:

| Feature       | Arch | Quality | Integration | Docs | ... | Security | Performance | ... |
| ------------- | ---- | ------- | ----------- | ---- | --- | -------- | ----------- | --- |
| *(feature 1)* | ⏳   | ⏳      | ⏳          | ⏳   | ... | ⏳       | N/A         | ... |
| *(feature 2)* | ⏳   | ⏳      | ⏳          | ⏳   | ... | N/A      | ⏳          | ... |
| ...           | ...  | ...     | ...         | ...  | ... | ...      | ...         | ... |

Each cell represents a validation report linking a specific feature to a dimension. **N/A** marks dimensions explicitly excluded for a feature. Populate the rows with your project's actual feature IDs from [Feature Tracking](../../../product-docs/state-tracking/permanent/feature-tracking.md).

## Validation Types Deep Dive

### Architectural Consistency Validation

**Purpose**: Ensure all selected features follow established architectural patterns and decisions.

**Validation Criteria**:

- **Pattern Adherence**: Repository pattern, service layer consistency
- **ADR Compliance**: Implementation matches architectural decision records
- **Interface Consistency**: Similar features use consistent interfaces
- **Dependency Direction**: Proper dependency inversion and layer separation
- **Error Handling**: Consistent error handling patterns

**Session Planning**:

Group the selected features into batches of 2–4 per session, considering dependencies and related functionality. Example:

- Session 1: Core architecture features (e.g., data models, service layer)
- Session 2: Infrastructure features (e.g., logging, configuration)
- Session 3: Remaining features
- *(add sessions as needed for your project's feature count)*

### Code Quality & Standards Validation

**Purpose**: Ensure code quality, readability, and adherence to language best practices.

**Validation Criteria**:

- **Code Style**: Consistent formatting, naming conventions, documentation
- **SOLID Principles**: Single responsibility, open/closed, dependency inversion
- **Language Best Practices**: Component composition, state management, performance
- **Language Idioms**: Proper use of language features, type safety, async patterns
- **Performance**: Efficient algorithms, memory usage, unnecessary computations

### Integration & Dependencies Validation

**Purpose**: Ensure proper integration between selected components and healthy dependencies.

**Validation Criteria**:

- **Service Integration**: Proper service layer interactions
- **State Management**: Consistent state handling across features
- **API Contracts**: Well-defined interfaces between components
- **Data Flow**: Clear data flow patterns and transformations
- **Dependency Health**: Appropriate dependency management and versions

### Documentation Alignment Validation

**Purpose**: Ensure implementation aligns with design documentation and specifications.

**Validation Criteria**:

- **TDD Alignment**: Implementation matches technical design documents
- **ADR Compliance**: Code follows architectural decision records
- **API Documentation**: Current and accurate API documentation
- **Code Comments**: Meaningful and up-to-date inline documentation
- **README Accuracy**: Project documentation reflects current state

### Extensibility & Maintainability Validation

**Purpose**: Ensure the foundation supports future development and maintenance.

**Validation Criteria**:

- **Extension Points**: Clear mechanisms for extending functionality
- **Configuration Flexibility**: Configurable behavior without code changes
- **Testing Support**: Comprehensive test coverage and testability
- **Modularity**: Well-defined module boundaries and responsibilities
- **Scalability**: Architecture supports growth and increased load

### AI Agent Continuity Validation

**Purpose**: Ensure code structure supports effective AI agent workflows within context limitations.

**Validation Criteria**:

- **Context Clarity**: Code is understandable within limited context windows
- **Modular Structure**: Clear separation of concerns and responsibilities
- **Documentation Quality**: Comprehensive and accessible documentation
- **Workflow Optimization**: Code structure supports efficient AI agent workflows
- **Knowledge Transfer**: Easy onboarding for new AI agents

## Step-by-Step Instructions

### 1. Validation Session Preparation

1. **Select Validation Type and Features**

   - Choose one of the 6 validation types based on current priorities
   - Select 2-3 features for the session (follow session planning guidelines)
   - Review the specific validation task definition for your chosen type

2. **Generate Validation Report Template**

   ```powershell
   # Navigate to validation directory
   Set-Location "doc/product-docs/validation"

   # Generate validation report for specific type and features (use your project's actual feature IDs)
   ..\scripts\file-creation\New-ValidationReport.ps1 -ValidationType "ArchitecturalConsistency" -FeatureIds "<feature-1>,<feature-2>,<feature-3>" -SessionNumber 1
   ```

3. **Review Context Requirements**
   - Read the context map for your chosen validation type
   - Load all critical context files specified in the validation task
   - Ensure access to the selected features' implementation code

**Expected Result:** You should have a validation report template ready for completion and all necessary context loaded.

### 2. Conduct Validation Analysis

1. **Load Feature Implementation Code**

   - Navigate to the specific feature implementations
   - Review the code structure, patterns, and implementation details
   - Take notes on observations and potential issues

2. **Apply Validation Criteria**

   - Use the validation criteria specific to your chosen validation type
   - Score each criterion on the 4-point scale (1=Poor, 2=Adequate, 3=Good, 4=Excellent)
   - Document specific findings, evidence, and recommendations

3. **Cross-Feature Analysis**
   - Compare patterns and implementations across the selected features
   - Identify consistency issues or variations in approach
   - Note integration points and dependencies between features

**Expected Result:** Completed validation analysis with scores, findings, and recommendations for each feature.

### 3. Complete Validation Report

1. **Fill in Validation Results**

   - Complete all sections of the validation report template
   - Include specific code examples and evidence for findings
   - Provide actionable recommendations for each identified issue

2. **Calculate Overall Scores**

   - Calculate weighted scores for each feature
   - Identify any critical issues (score = 1) requiring immediate attention
   - Determine overall batch score and status

3. **Save and Link Report**
   ```powershell
   # Save the completed report in the appropriate validation subdirectory
   # The report should be named: PF-VAL-XXX-[validation-type]-features-[feature-range].md
   ```

**Expected Result:** Completed validation report saved in the correct location with proper naming convention.

### 4. Update Validation Tracking

1. **Update Validation Matrix**

   - Open the validation tracking file
   - Update the appropriate matrix cells with report completion dates and links
   - Update overall progress statistics

2. **Record Critical Issues**

   - Add any critical issues to the issues tracking section
   - Assign priority levels and remediation timelines
   - Link issues to specific validation reports

3. **Update Session Planning**
   - Mark completed validation sessions
   - Plan next validation sessions based on priorities and dependencies
   - Update overall validation progress status

**Expected Result:** Validation tracking file updated with current progress and any identified issues.

### 5. Generate Summary (Optional)

1. **Assess Need for Summary**

   - Determine if enough validation reports exist to warrant a summary
   - Consider generating summary after completing validation type or major milestone

2. **Generate Consolidated Summary**
   ```powershell
   # Generate validation summary (outputs to doc/product-docs/validation/reports/ by default)
   ../../scripts/file-creation/05-validation/Generate-ValidationSummary.ps1 -IncludeDetails

   # Or specify a custom output path
   ../../scripts/file-creation/05-validation/Generate-ValidationSummary.ps1 -OutputPath "custom-summary.md" -IncludeDetails
   ```

**Expected Result:** Consolidated validation summary available for strategic decision-making (when applicable).

## Scoring and Interpretation

### 4-Point Scoring Scale

Each validation criterion uses a standardized 4-point scale:

- **4 - Excellent**: Exceeds expectations, exemplary implementation

  - Code demonstrates best practices and innovative solutions
  - No improvements needed, serves as a model for other features
  - Fully supports extensibility and maintainability goals

- **3 - Good**: Meets requirements with minor improvements possible

  - Solid implementation following established patterns
  - Minor optimizations or enhancements could be beneficial
  - Generally supports project goals effectively

- **2 - Adequate**: Functional but needs improvement

  - Basic functionality works but lacks polish or optimization
  - Several areas for improvement identified
  - May require attention before major releases

- **1 - Poor**: Significant issues requiring immediate attention
  - Critical problems affecting functionality or maintainability
  - Immediate remediation required
  - May block other development work

### Quality Gates

**Overall Score Interpretation:**

- **≥ 3.0**: Foundation is production-ready and well-implemented
- **2.5-2.9**: Foundation needs targeted improvements but is functional
- **< 2.5**: Foundation requires significant refactoring before production use

**Critical Issue Handling:**

- Any criterion scoring 1 (Poor) is flagged as a critical issue
- Critical issues require immediate attention regardless of overall score
- Critical issues should be tracked and remediated before proceeding with dependent work

### Score Calculation

**Feature-Level Scoring:**

```
Feature Score = (Sum of all criterion scores) / (Number of criteria)
```

**Validation Type Scoring:**

```
Validation Type Score = (Sum of all feature scores) / (Number of features validated)
```

**Overall Foundation Score:**

```
Overall Score = (Sum of all validation type scores) / (Number of validation types completed)
```

### Handling N/A Criteria

When a validation criterion references an artifact that doesn't exist for a feature (e.g., no ADR, no TDD for Tier 1), consult the specific validation task definition for handling instructions. Each task defines whether to:

- **Substitute** an equivalent criterion (e.g., PF-TSK-034 substitutes TDD Alignment with Code Documentation Accuracy for Tier 1 features)
- **Skip** the criterion (e.g., PF-TSK-034 skips ADR Compliance when no ADRs exist)
- **Flag as a finding** (e.g., PF-TSK-031 assesses whether a missing ADR should be created)

When skipping a criterion, exclude it from the score denominator so it doesn't penalize the feature's overall score.

### Interpretation Guidelines

**For Individual Features:**

- Focus on features with scores < 2.5 for immediate improvement
- Prioritize critical issues (score = 1) across all features
- Use high-scoring features as examples for improvement

**For Validation Types:**

- Identify validation types with consistently low scores
- Look for patterns across features within a validation type
- Plan targeted improvement sessions for problematic validation types

**For Overall Foundation:**

- Track trends over time as validation progresses
- Use overall score to communicate foundation health to stakeholders
- Set improvement targets and track progress toward goals

## Examples

### Example 1: Architectural Consistency Validation Session

**Scenario**: Conducting architectural consistency validation for the first batch of selected features. *(Feature IDs below are illustrative — substitute your project's actual features.)*

**Step-by-Step Example**:

1. **Session Preparation**

   ```powershell
   # Navigate to validation directory
   Set-Location "doc/product-docs/validation"

   # Generate validation report for architectural consistency (use your project's feature IDs)
   ..\scripts\file-creation\New-ValidationReport.ps1 -ValidationType "ArchitecturalConsistency" -FeatureIds "0.2.1,0.2.2,0.2.3" -SessionNumber 1
   ```

2. **Load Context**

   - Review Architectural Consistency Validation task (PF-TSK-031)
   - Load context map for architectural validation
   - Access the selected features' implementation code

3. **Conduct Analysis**

   - **Feature A (0.2.1)**: Score pattern adherence, interface consistency
   - **Feature B (0.2.2)**: Evaluate service abstractions, dependency injection
   - **Feature C (0.2.3)**: Assess model structure, naming patterns

4. **Sample Findings**

   - Feature A: Score 3/4 (Good) - consistent interfaces, minor optimization opportunities
   - Feature B: Score 4/4 (Excellent) - exemplary dependency injection implementation
   - Feature C: Score 2/4 (Adequate) - functional but inconsistent naming conventions

5. **Update Tracking**
   - Update validation matrix cells for the validated features under Architectural column
   - Record completion date and link to validation report
   - Note any critical issues requiring attention

**Result:** Completed architectural validation report with actionable recommendations and updated tracking matrix.

### Example 2: Critical Issue Remediation Workflow

**Scenario**: Addressing a critical issue (score = 1) found during Code Quality validation.

**Issue Identified**: Inconsistent error handling patterns in a feature, affecting system reliability.

**Remediation Process**:

1. **Issue Documentation**: Record in validation tracking with HIGH priority
2. **Impact Assessment**: Evaluate effect on dependent features
3. **Remediation Planning**: Create improvement task with specific acceptance criteria
4. **Implementation**: Execute code improvements following established patterns
5. **Re-validation**: Conduct focused validation session to verify improvements
6. **Tracking Update**: Update validation matrix and close critical issue

**Result**: Critical issue resolved, validation score improved from 1 to 3, system reliability enhanced.

## Troubleshooting

### Validation Report Generation Fails

**Symptom:** New-ValidationReport.ps1 script fails with "Invalid ValidationType" error

**Cause:** ValidationType parameter doesn't match expected values or script can't find validation subdirectories

**Solution:**

1. Verify ValidationType uses exact values: "Architectural", "CodeQuality", "Integration", "Documentation", "Extensibility", "AIContinuity"
2. Ensure validation directory structure exists with all subdirectories
3. Check that you're running the script from the correct directory (doc/product-docs/validation/)

### Context Loading Issues

**Symptom:** Unable to access feature implementations or validation task definitions

**Cause:** Incorrect file paths or missing context files

**Solution:**

1. Verify you're working from the correct project root directory
2. Check that all validation tasks (PF-TSK-031 through PF-TSK-036) exist in doc/process-framework/tasks/05-validation/
3. Ensure feature implementations are accessible in the project's source directories
4. Review context map links and verify all referenced files exist

### Scoring Inconsistencies

**Symptom:** Difficulty applying consistent scoring across features or validation types

**Cause:** Unclear understanding of scoring criteria or inconsistent application

**Solution:**

1. Review the 4-point scoring scale definitions carefully
2. Use previous validation reports as scoring examples and benchmarks
3. Focus on relative scoring within each validation type
4. Document specific evidence for each score to maintain consistency
5. Consider peer review of scoring decisions for critical validations

### Validation Matrix Update Errors

**Symptom:** Unable to update validation tracking matrix or links don't work correctly

**Cause:** Incorrect file paths, naming conventions, or matrix cell references

**Solution:**

1. Verify validation report file names follow the pattern: PF-VAL-XXX-[validation-type]-features-[feature-range].md
2. Check that reports are saved in correct validation subdirectories
3. Ensure matrix cell updates use correct date format and relative file paths
4. Test all links after updating to verify they work correctly

### Session Planning Confusion

**Symptom:** Uncertainty about which features to validate together or session sequencing

**Cause:** Unclear understanding of validation session planning guidelines

**Solution:**

1. Follow the session planning guidelines in each validation type's deep dive section
2. Consider feature dependencies and integration points when grouping features
3. Start with architectural validation to establish baseline patterns
4. Prioritize high-impact features (Repository, Service Layer, State Management)
5. Consult the validation tracking file for current progress and next recommended sessions

## Related Resources

### Validation Framework Components

- [Validation Preparation Task](../../tasks/05-validation/validation-preparation.md) - PF-TSK-077 — **Start here** to plan a validation round
- [Feature Validation Tasks](../../tasks/05-validation/) - All 11 validation dimension task definitions
- [Validation Report Template](../../templates/05-validation/validation-report-template.md) - Template for creating validation reports
- [Validation Tracking Template](../../templates/05-validation/validation-tracking-template.md) - Template for creating the feature×dimension tracking matrix
- Validation Tracking State File - Active tracking file for the current validation round (created per validation round via Validation Preparation)

### Validation Task Definitions

- [Architectural Consistency Validation Task](../../tasks/05-validation/architectural-consistency-validation.md) - PF-TSK-031
- [Code Quality Standards Validation Task](../../tasks/05-validation/code-quality-standards-validation.md) - PF-TSK-032
- [Integration Dependencies Validation Task](../../tasks/05-validation/integration-dependencies-validation.md) - PF-TSK-033
- [Documentation Alignment Validation Task](../../tasks/05-validation/documentation-alignment-validation.md) - PF-TSK-034
- [Extensibility Maintainability Validation Task](../../tasks/05-validation/extensibility-maintainability-validation.md) - PF-TSK-035
- [AI Agent Continuity Validation Task](../../tasks/05-validation/ai-agent-continuity-validation.md) - PF-TSK-036
- [Security & Data Protection Validation Task](../../tasks/05-validation/security-data-protection-validation.md) - PF-TSK-072
- [Performance & Scalability Validation Task](../../tasks/05-validation/performance-scalability-validation.md) - PF-TSK-073
- [Observability Validation Task](../../tasks/05-validation/observability-validation.md) - PF-TSK-074
- [Accessibility / UX Compliance Validation Task](../../tasks/05-validation/accessibility-ux-compliance-validation.md) - PF-TSK-075
- [Data Integrity Validation Task](../../tasks/05-validation/data-integrity-validation.md) - PF-TSK-076

### Context Maps

- [Validation Preparation Context Map](../../visualization/context-maps/05-validation/validation-preparation-map.md) - PF-VIS-056
- [Architectural Consistency Validation Context Map](../../visualization/context-maps/05-validation/architectural-consistency-validation-map.md) - PF-VIS-028
- [Code Quality Standards Validation Context Map](../../visualization/context-maps/05-validation/code-quality-standards-validation-map.md) - PF-VIS-029
- [Integration Dependencies Validation Context Map](../../visualization/context-maps/05-validation/integration-dependencies-validation-map.md) - PF-VIS-030
- [Documentation Alignment Validation Context Map](../../visualization/context-maps/05-validation/documentation-alignment-validation-map.md) - PF-VIS-031
- [Extensibility Maintainability Validation Context Map](../../visualization/context-maps/05-validation/extensibility-maintainability-validation-map.md) - PF-VIS-032
- [AI Agent Continuity Validation Context Map](../../visualization/context-maps/05-validation/ai-agent-continuity-validation-map.md) - PF-VIS-033
- [Security & Data Protection Validation Context Map](../../visualization/context-maps/05-validation/security-data-protection-validation-map.md) - PF-VIS-051
- [Performance & Scalability Validation Context Map](../../visualization/context-maps/05-validation/performance-scalability-validation-map.md) - PF-VIS-052
- [Observability Validation Context Map](../../visualization/context-maps/05-validation/observability-validation-map.md) - PF-VIS-053
- [Accessibility / UX Compliance Validation Context Map](../../visualization/context-maps/05-validation/accessibility-ux-compliance-validation-map.md) - PF-VIS-054
- [Data Integrity Validation Context Map](../../visualization/context-maps/05-validation/data-integrity-validation-map.md) - PF-VIS-055

### Automation Scripts

- [New-ValidationReport.ps1](../../scripts/file-creation/05-validation/New-ValidationReport.ps1) - Generate validation report templates
- [Update-ValidationReportState.ps1](../../scripts/update/Update-ValidationReportState.ps1) - Update tracking with validation results
- [Generate-ValidationSummary.ps1](../../scripts/file-creation/05-validation/Generate-ValidationSummary.ps1) - Create consolidated validation summaries

### Supporting Documentation

- [AI Task-Based Development System](../../ai-tasks.md) - Main task system entry point
- [Feature Tracking](../../../product-docs/state-tracking/permanent/feature-tracking.md) - Current feature status
- [Visual Notation Guide](../support/visual-notation-guide.md) - For interpreting context maps and diagrams
