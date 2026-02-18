---
id: PF-GDE-032
type: Document
category: General
version: 1.0
created: 2025-07-27
updated: 2025-07-27
guide_status: Active
guide_title: Architecture Assessment Creation Guide
guide_description: Guide for customizing architecture assessment templates
related_script: New-ArchitectureAssessment.ps1
related_tasks: PF-TSK-019
---

# Architecture Assessment Creation Guide

## Overview

This guide provides comprehensive instructions for creating and customizing Architecture Assessment documents using the New-ArchitectureAssessment.ps1 script and architecture-impact-assessment-template.md. It helps you evaluate the architectural impact of proposed changes and ensure system integrity in the BreakoutBuddies project.

## When to Use

Use this guide when you need to:

- Assess the architectural impact of proposed system changes
- Evaluate new feature implementations for system compatibility
- Document architectural risks and mitigation strategies
- Review integration points and dependencies before implementation
- Create comprehensive architectural analysis for complex features
- Support architectural decision-making processes

> **🚨 CRITICAL**: Always use the New-ArchitectureAssessment.ps1 script to create architecture assessments - never create them manually. This ensures proper ID assignment, metadata integration, and framework compatibility. Architecture assessments must be completed before implementing significant system changes.

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

- Access to PowerShell and the New-ArchitectureAssessment.ps1 script in `doc/product-docs/technical/architecture/assessments/`
- Understanding of the project's current system architecture and components
- Knowledge of the proposed changes or features requiring assessment
- Familiarity with architectural risk assessment methodologies
- Access to the System Architecture Review Task (PF-TSK-019) documentation
- Understanding of system integration points and dependencies

## Background

Architecture Assessments provide systematic evaluation of proposed changes to ensure they align with system architecture principles and don't introduce unacceptable risks. They serve as a critical checkpoint before implementing significant system modifications.

### Purpose of Architecture Assessments

- **Risk Evaluation**: Identify potential architectural risks and their impact on system integrity
- **Impact Analysis**: Assess how proposed changes affect existing system components and integrations
- **Decision Support**: Provide structured analysis to support architectural decision-making
- **Quality Assurance**: Ensure proposed changes meet architectural standards and best practices
- **Documentation**: Create a record of architectural considerations for future reference

### Framework Integration

Architecture Assessments integrate with Architecture Decision Records (ADRs) and system design documentation to provide comprehensive architectural governance and decision tracking.

## Template Structure Analysis

The Architecture Impact Assessment template (architecture-impact-assessment-template.md) provides a comprehensive structure for evaluating architectural changes:

### Core Template Sections

**Required sections:**

- **Assessment Overview**: Feature name, assessment type, date, assessor, and complexity tier
- **Assessment Description**: Clear explanation of what is being assessed and why
- **Feature Context**: Requirements summary, user impact, business value, and related documentation
- **Current Architecture Analysis**: Affected components, relationship changes, and data flow impact
- **Integration Analysis**: API integration points, database schema impact, and external system integration

**Critical analysis sections:**

- **Architectural Consistency Review**: Alignment with existing ADRs, pattern compliance, and design principle adherence
- **Risk Assessment**: Architectural risks with probability, impact, and mitigation strategies
- **Implementation Considerations**: Performance impact, security considerations, and scalability factors
- **Recommendations**: Assessment conclusion, implementation approach, and monitoring requirements

**Optional sections:**

- **Alternative Approaches**: Other implementation options considered
- **Migration Strategy**: Detailed migration planning for complex changes
- **Testing Strategy**: Specific testing approaches for architectural changes

### Section Interdependencies

- **Assessment Overview** establishes the foundation and complexity level for all analysis
- **Feature Context** provides the business justification that drives architectural decisions
- **Current Architecture Analysis** feeds into **Integration Analysis** and **Risk Assessment**
- **Architectural Consistency Review** validates decisions against **Risk Assessment** findings
- **Implementation Considerations** synthesizes all analysis into actionable **Recommendations**

## Customization Decision Points

When creating architecture assessments, you must make several key decisions that impact the assessment's depth and effectiveness:

### Assessment Scope Decision

**Decision**: Comprehensive full-system assessment vs. focused component assessment
**Criteria**:

- Comprehensive for features affecting multiple system components or introducing new architectural patterns
- Focused for features with limited scope affecting specific components
- Consider feature complexity tier (Tier 1 = focused, Tier 3 = comprehensive)
  **Impact**: Determines the depth of analysis required and time investment needed

### Risk Analysis Granularity Decision

**Decision**: High-level risk overview vs. detailed risk analysis with quantified impacts
**Criteria**:

- High-level for well-understood changes with established patterns
- Detailed for novel implementations or changes affecting critical system components
- Consider organizational risk tolerance and change management requirements
  **Impact**: Affects decision-making confidence and mitigation strategy development

### Integration Analysis Depth Decision

**Decision**: Basic integration review vs. comprehensive integration impact analysis
**Criteria**:

- Basic for features with minimal external dependencies
- Comprehensive for features introducing new integrations or modifying existing ones
- Consider the number of affected integration points and their criticality
  **Impact**: Determines implementation complexity and coordination requirements

### Recommendation Specificity Decision

**Decision**: General guidance vs. specific implementation recommendations
**Criteria**:

- General guidance for early-stage assessments or when multiple approaches are viable
- Specific recommendations for critical decisions or when clear optimal approaches exist
- Consider the target audience's technical expertise and decision-making authority
  **Impact**: Affects implementation guidance clarity and decision-making speed

## Step-by-Step Instructions

### 1. Prepare Assessment Context and Gather Information

1. **Review the feature requirements and context**:

   - Understand the feature's primary functionality and business value
   - Identify the user impact and implementation scope
   - Gather related documentation (feature discovery, tier assessment, existing ADRs)

2. **Gather assessment parameters**:

   - **Feature Name**: Descriptive name for the feature being assessed
   - **Assessment Type**: Type of assessment (New Feature, Enhancement, Refactoring, etc.)
   - **Assessor Name**: Name of the person conducting the assessment
   - **Feature Complexity**: Tier level from Feature Tier Assessment (Tier 1/2/3)

3. **Analyze current system architecture**:
   - Review existing system components and their relationships
   - Understand current data flows and integration points
   - Identify architectural patterns and design principles in use

**Expected Result:** Complete understanding of the feature context and current system architecture

### 2. Create Architecture Assessment Using New-ArchitectureAssessment.ps1

1. **Navigate to the architecture assessments directory**:

   ```powershell
   cd c:\Users\ronny\VS_Code\BreakoutBuddies\breakoutbuddies\doc\product-docs\technical\architecture\assessments
   ```

2. **Execute the New-ArchitectureAssessment.ps1 script**:

   ```powershell
   # Basic architecture assessment creation
   .\New-ArchitectureAssessment.ps1 -FeatureName "User Profile Enhancement" -AssessmentType "Enhancement" -AssessorName "Architecture Team"

   # With feature complexity specified
   .\New-ArchitectureAssessment.ps1 -FeatureName "Real-time Booking System" -AssessmentType "New Feature" -AssessorName "Lead Architect" -FeatureComplexity "Tier 3" -OpenInEditor
   ```

3. **Verify assessment creation**:
   - Check the success message for the assigned ID (PD-ARCH-XXX)
   - Note the file path in the architecture assessments directory
   - Confirm the basic template structure and metadata

**Expected Result:** New architecture assessment file created with proper ID, metadata, and template structure

### 3. Complete Comprehensive Architecture Analysis

1. **Analyze affected components and relationships**:

   - Create the affected components table with impact levels and modification requirements
   - Document component relationship changes (new, modified, removed)
   - Analyze data flow impact including new flows, modifications, and storage requirements

2. **Conduct integration analysis**:

   - Document API integration points (new APIs, existing API changes, external dependencies)
   - Analyze database schema impact (new tables, schema modifications, migration strategy)
   - Review external system integration requirements and configuration changes

3. **Perform architectural consistency review**:

   - Check alignment with existing ADRs and document compliance status
   - Verify architectural pattern compliance (state management, component architecture, data access)
   - Assess design principle adherence (single responsibility, separation of concerns, testability)

4. **Complete risk assessment and recommendations**:
   - Identify architectural risks with probability, impact, and mitigation strategies
   - Document implementation considerations (performance, security, scalability)
   - Provide clear recommendations with assessment conclusion and monitoring requirements

**Expected Result:** Comprehensive architecture assessment with detailed analysis, risk evaluation, and actionable recommendations

### Validation and Testing

1. **Validate assessment completeness**:

   - Verify that all affected components are identified with appropriate impact levels
   - Check that risk assessments include probability, impact, and mitigation strategies
   - Ensure architectural consistency review covers all relevant ADRs and patterns
   - Confirm that recommendations are actionable and specific

2. **Test assessment accuracy**:

   - Review component analysis against actual system architecture
   - Validate integration analysis with existing API and database documentation
   - Cross-check risk assessments with similar past assessments
   - Verify that recommendations align with architectural principles and constraints

3. **Review stakeholder alignment**:

   - Confirm assessment addresses the concerns of development teams
   - Verify that business impact analysis aligns with feature requirements
   - Check that technical recommendations are feasible within project constraints
   - Ensure risk mitigation strategies are realistic and implementable

4. **Validate framework integration**:
   - Check that metadata fields are properly completed
   - Verify that the assessment references relevant ADRs and documentation
   - Ensure compatibility with existing architectural governance processes

## Quality Assurance

Comprehensive quality assurance ensures architecture assessments meet project standards and provide valuable architectural guidance:

### Self-Review Checklist

- [ ] Assessment overview clearly identifies feature, complexity, and assessment scope
- [ ] All affected components are identified with appropriate impact levels
- [ ] Integration analysis covers API, database, and external system impacts
- [ ] Architectural consistency review addresses relevant ADRs and patterns
- [ ] Risk assessment includes probability, impact, and realistic mitigation strategies
- [ ] Recommendations are actionable, specific, and aligned with architectural principles
- [ ] Cross-references and links to related documentation are correct and accessible

### Validation Criteria

- **Functional validation**: Assessment provides actionable guidance for implementation decisions
- **Content validation**: Component analysis and risk assessments are accurate and complete
- **Integration validation**: Assessment integrates properly with ADRs and architectural documentation
- **Standards validation**: Follows project architectural assessment conventions and quality standards
- **Stakeholder validation**: Assessment addresses the needs of development teams and decision-makers

### Integration Testing Procedures

- **ADR Alignment**: Verify that architectural consistency review accurately reflects existing ADRs
- **Component Analysis**: Check that affected components analysis matches actual system architecture
- **Risk Validation**: Confirm that identified risks are realistic and mitigation strategies are feasible
- **Implementation Feasibility**: Validate that recommendations can be implemented within project constraints
- **Documentation Integration**: Ensure assessment references and links to related architectural documentation

## Examples

### Example 1: Real-time Booking System Assessment

Creating an architecture assessment for a new real-time booking feature:

```powershell
# Navigate to architecture assessments directory
cd c:\Users\ronny\VS_Code\BreakoutBuddies\breakoutbuddies\doc\product-docs\technical\architecture\assessments

# Create architecture assessment for complex new feature
.\New-ArchitectureAssessment.ps1 -FeatureName "Real-time Booking System" -AssessmentType "New Feature" -AssessorName "Lead Architect" -FeatureComplexity "Tier 3" -OpenInEditor
```

**Customization approach:**

- **Assessment Overview**: Document Tier 3 complexity requiring comprehensive analysis
- **Current Architecture Analysis**: Identify affected components (booking service, notification service, database, WebSocket connections)
- **Integration Analysis**: New WebSocket APIs, database schema changes for real-time data, external payment system integration
- **Risk Assessment**: High-impact risks including performance degradation, data consistency issues, and scalability concerns
- **Recommendations**: Phased implementation approach with performance monitoring and rollback procedures

**Result:** Comprehensive assessment that guides implementation decisions and risk mitigation for a complex architectural change

### Example 2: User Profile Enhancement Assessment

Creating an assessment for a moderate complexity feature enhancement:

```powershell
# Create architecture assessment for enhancement
.\New-ArchitectureAssessment.ps1 -FeatureName "User Profile Enhancement" -AssessmentType "Enhancement" -AssessorName "Architecture Team" -FeatureComplexity "Tier 2"
```

**Customization approach:**

- **Assessment Overview**: Document Tier 2 complexity with focused analysis on user management components
- **Current Architecture Analysis**: Limited impact on user service and profile database tables
- **Integration Analysis**: Minor API changes, database schema additions, no external system impact
- **Risk Assessment**: Low to medium risks focused on data migration and backward compatibility
- **Recommendations**: Standard implementation approach with migration strategy for existing user data

**Result:** Focused assessment that provides clear guidance for a well-understood enhancement with manageable risks

## Troubleshooting

### Script Execution Fails with Path Error

**Symptom:** New-ArchitectureAssessment.ps1 script fails with "Cannot find common helpers" error

**Cause:** Script cannot locate the Common-ScriptHelpers.psm1 module due to incorrect path resolution

**Solution:**

1. Verify you're running the script from the correct directory: `doc/product-docs/technical/architecture/assessments/`
2. Check that the Common-ScriptHelpers.psm1 file exists at `doc/process-framework/scripts/Common-ScriptHelpers.psm1`
3. Ensure PowerShell execution policy allows script execution: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

### Assessment Scope Too Broad or Unfocused

**Symptom:** Architecture assessment becomes overwhelming with too many components or risks to analyze

**Cause:** Attempting to assess multiple features or overly broad system changes in a single assessment

**Solution:**

1. Break complex features into separate, focused assessments for each major component or subsystem
2. Use the feature complexity tier to guide assessment scope (Tier 1 = focused, Tier 3 = comprehensive)
3. Create separate assessments for different phases of implementation if the feature has multiple stages
4. Focus each assessment on specific architectural concerns rather than trying to cover everything

### Risk Assessment Lacks Specificity

**Symptom:** Risk assessments are too generic or don't provide actionable mitigation strategies

**Cause:** Insufficient analysis of specific architectural impacts or lack of concrete mitigation planning

**Solution:**

1. Review similar past assessments to understand risk patterns and effective mitigation strategies
2. Consult with development teams to understand specific implementation concerns and constraints
3. Focus on architectural risks rather than general project risks (performance, scalability, maintainability)
4. Ensure each risk has specific probability, impact, and actionable mitigation steps

## Related Resources

- [System Architecture Review Task (PF-TSK-019)](../../tasks/01-planning/system-architecture-review.md) - The task that uses this guide
- [New-ArchitectureAssessment.ps1 Script](../../scripts/file-creation/New-ArchitectureAssessment.ps1) - Script for creating architecture assessments
- [Architecture Impact Assessment Template](../../templates/templates/architecture-impact-assessment-template.md) - Template customized by this guide
- [Architecture Decision Creation Guide (PF-GDE-033)](architecture-decision-creation-guide.md) - Guide for creating related ADRs
- [Guide Creation Best Practices Guide (PF-GDE-024)](guide-creation-best-practices-guide.md) - Best practices for guide creation
- [Architecture Decision Records (ADRs)](https://adr.github.io/) - External resource for ADR principles and practices

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
