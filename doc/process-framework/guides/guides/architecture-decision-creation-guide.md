---
id: PF-GDE-033
type: Document
category: General
version: 1.1
created: 2025-07-27
updated: 2025-08-03
guide_status: Active
guide_title: Architecture Decision Creation Guide
related_tasks: PF-TSK-019
related_script: New-ArchitectureDecision.ps1
guide_description: Guide for customizing Architecture Decision Record templates
---

# Architecture Decision Creation Guide

## Overview

This guide provides comprehensive instructions for creating and customizing Architecture Decision Record (ADR) documents using the New-ArchitectureDecision.ps1 script and adr-template.md. It helps you document important architectural decisions, their context, and rationale for the BreakoutBuddies project.

## When to Use

Use this guide when you need to:

- Document significant architectural decisions and their rationale
- Record technology choices and their trade-offs
- Capture design decisions that affect system structure or behavior
- Create a historical record of architectural evolution
- Support future architectural reviews and decision-making
- Ensure architectural decisions are communicated to the development team

> **🚨 CRITICAL**: Always use the New-ArchitectureDecision.ps1 script to create ADRs - never create them manually. This ensures proper ID assignment, metadata integration, and framework compatibility. ADRs should be created for all significant architectural decisions to maintain project architectural history.

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

- Access to PowerShell and the New-ArchitectureDecision.ps1 script in `doc/product-docs/technical/architecture/decisions/`
- Understanding of the architectural decision that needs to be documented
- Knowledge of the context, alternatives, and consequences of the decision
- Familiarity with Architecture Decision Record (ADR) principles and formats
- Access to the System Architecture Review Task (PF-TSK-019) documentation
- Understanding of the project's architectural principles and constraints

## Background

Architecture Decision Records (ADRs) provide a structured way to document significant architectural decisions, their context, and rationale. They create a historical record of architectural evolution and support future decision-making processes.

### Purpose of Architecture Decision Records

- **Decision Documentation**: Capture the reasoning behind important architectural choices
- **Context Preservation**: Record the circumstances and constraints that influenced decisions
- **Alternative Analysis**: Document considered alternatives and why they were rejected
- **Consequence Tracking**: Record the expected outcomes and actual results of decisions
- **Knowledge Transfer**: Enable team members to understand architectural evolution over time

### Framework Integration

ADRs work alongside Architecture Assessments to provide comprehensive architectural governance. They reference system design documentation and integrate with the broader architectural decision-making process.

## Template Structure Analysis

The Architecture Decision Record template (adr-template.md) provides a structured format for documenting architectural decisions following industry-standard ADR practices:

### Core Template Sections

**Required sections:**

- **Title (ADR-NNNN format)**: Unique identifier and descriptive title for the decision
- **Status**: Current state of the decision (Proposed, Accepted, Deprecated, Superseded)
- **Context**: Problem statement and circumstances that motivated the decision
- **Decision**: Clear, specific description of what was decided
- **Consequences**: Both positive and negative outcomes expected from the decision

**Important sections:**

- **Impact Assessment**: Structured analysis of technical risk, implementation effort, affected components, and other impacts
- **Alternatives**: Detailed analysis of other options considered with structured pros/cons and rejection reasons
- **References**: Supporting documentation, resources, and related materials

**Metadata sections:**

- **Created/Updated dates**: Temporal tracking of decision evolution
- **Document metadata**: Framework integration fields (id, type, category, version)

### Section Interdependencies

- **Context** establishes the foundation that justifies the **Decision**
- **Decision** directly leads to the **Consequences** and **Impact Assessment** analysis
- **Impact Assessment** provides structured risk and effort analysis that complements **Consequences**
- **Alternatives** provides detailed comparative analysis with structured pros/cons that supports the **Decision**
- **Status** reflects the current lifecycle stage and affects how other sections are interpreted
- **References** support and validate the reasoning in **Context**, **Decision**, **Impact Assessment**, and **Alternatives**

### Customization Impact Areas

- **Context depth** determines the comprehensiveness of problem analysis
- **Decision specificity** affects implementation clarity and future reference value
- **Consequences completeness** impacts risk assessment and change management
- **Impact Assessment thoroughness** affects project planning, risk management, and resource allocation
- **Alternatives analysis depth** influences decision confidence, stakeholder buy-in, and future reviews

## Customization Decision Points

When creating Architecture Decision Records, you must make several key decisions that impact the ADR's effectiveness and long-term value:

### Decision Scope and Granularity Decision

**Decision**: Single focused decision vs. multiple related decisions in one ADR
**Criteria**:

- Single decision for clear, isolated architectural choices
- Multiple related decisions only when they are tightly coupled and cannot be separated
- Consider future maintainability and the ability to supersede individual decisions
  **Impact**: Affects ADR clarity, future reference value, and ability to track decision evolution

### Context Detail Level Decision

**Decision**: High-level context overview vs. comprehensive problem analysis
**Criteria**:

- High-level for well-understood problems with clear stakeholder alignment
- Comprehensive for complex problems requiring detailed justification
- Consider the audience's familiarity with the problem domain and decision complexity
  **Impact**: Determines decision justification strength and future understanding for new team members

### Alternative Analysis Depth Decision

**Decision**: Brief alternative mention vs. detailed comparative analysis
**Criteria**:

- Brief mention for obvious decisions with clear superior options
- Detailed analysis for complex trade-offs or when multiple viable options exist
- Consider the importance of the decision and potential for future reconsideration
  **Impact**: Affects decision confidence, stakeholder buy-in, and ability to revisit decisions later

### Consequences Specificity Decision

**Decision**: General consequence categories vs. specific measurable impacts
**Criteria**:

- General categories for early-stage decisions or when specific impacts are uncertain
- Specific measurable impacts for critical decisions or when concrete metrics are available
- Consider the ability to validate consequences and the decision's risk level
  **Impact**: Determines the ability to evaluate decision success and guide future similar decisions

### Status Management Strategy Decision

**Decision**: Conservative status progression vs. rapid decision implementation
**Criteria**:

- Conservative progression (Proposed → Accepted → Implemented) for high-risk decisions
- Rapid implementation for low-risk decisions or urgent architectural needs
- Consider organizational change management processes and stakeholder approval requirements
  **Impact**: Affects decision implementation timeline and organizational alignment

## Step-by-Step Instructions

### 1. Analyze the Architectural Decision Context

1. **Identify and document the decision context**:

   - Understand the problem or situation that requires an architectural decision
   - Gather relevant background information and constraints
   - Identify stakeholders affected by the decision

2. **Collect decision parameters**:

   - **Title**: Clear, descriptive title for the architectural decision
   - **Description**: Brief explanation of what the decision addresses (optional)
   - **Status**: Initial status (typically "Proposed" for new decisions)
   - **Context**: Detailed problem statement and motivating factors

3. **Research alternatives and consequences**:
   - Identify all viable alternative approaches
   - Analyze the consequences (positive and negative) of each option
   - Gather supporting references and documentation

**Expected Result:** Complete understanding of the decision context, alternatives, and implications

### 2. Create Architecture Decision Record Using New-ArchitectureDecision.ps1

1. **Navigate to the ADR directory**:

   ```powershell
   cd c:\Users\ronny\VS_Code\BreakoutBuddies\breakoutbuddies\doc\product-docs\technical\architecture\design-docs\adr
   ```

2. **Execute the New-ArchitectureDecision.ps1 script**:

   ```powershell
   # Basic ADR creation
   .\New-ArchitectureDecision.ps1 -Title "State Management Pattern Selection" -Description "Decision on state management approach for the application"

   # With specific status and editor opening
   .\New-ArchitectureDecision.ps1 -Title "Database Migration Strategy" -Description "Approach for handling database schema changes" -Status "Proposed" -OpenInEditor
   ```

3. **Verify ADR creation**:
   - Check the success message for the assigned ID (PD-ADR-XXX)
   - Note the file path in the adr/adr directory
   - Confirm the basic template structure and metadata are properly populated

**Expected Result:** New ADR file created with proper ID, metadata, and template structure ready for customization

### 3. Complete Comprehensive Decision Documentation

1. **Develop detailed context section**:

   - Provide comprehensive problem statement explaining why this decision is needed
   - Document relevant background information and constraints
   - Include any triggering events or circumstances that motivated the decision

2. **Document the specific decision**:

   - Write a clear, specific statement of what was decided
   - Avoid ambiguity and ensure the decision is actionable
   - Include any implementation guidelines or constraints

3. **Complete impact assessment**:

   - Assess technical risk level (Low/Medium/High) and potential technical issues
   - Estimate implementation effort and development complexity
   - Identify all affected components, systems, modules, or teams
   - Determine if migration of existing code or data is required
   - Evaluate expected performance impact on the system
   - Consider security implications and any security changes needed

4. **Analyze alternatives with structured comparison**:

   - For each alternative considered, create a structured analysis:
     - Clear name/description of the alternative
     - List specific pros (benefits and advantages)
     - List specific cons (drawbacks and limitations)
     - Explain the decision rationale (why rejected or not chosen)
   - Ensure all viable alternatives are documented, not just obvious ones

5. **Document consequences and outcomes**:

   - List both positive and negative consequences of the chosen decision
   - Include short-term and long-term implications
   - Consider how consequences relate to the impact assessment

6. **Add supporting references**:
   - Link to relevant documentation, research, or external resources
   - Reference related ADRs or architectural assessments
   - Include any standards or best practices that influenced the decision

**Expected Result:** Comprehensive ADR with detailed decision documentation, thorough analysis, and supporting references

### Validation and Testing

1. **Validate decision documentation completeness**:

   - Verify that the context section clearly explains the problem and motivation
   - Check that the decision statement is specific, actionable, and unambiguous
   - Confirm that the impact assessment covers all required areas (technical risk, effort, components, migration, performance, security)
   - Ensure all considered alternatives are documented with structured pros/cons analysis
   - Confirm that consequences include both positive and negative impacts

2. **Test decision clarity and implementability**:

   - Review the decision with stakeholders to ensure understanding
   - Verify that the decision provides sufficient guidance for implementation
   - Check that consequences are realistic and measurable where possible
   - Ensure the decision aligns with existing architectural principles

3. **Review integration with architectural governance**:

   - Confirm the ADR references relevant existing ADRs and assessments
   - Verify that the decision doesn't conflict with established architectural patterns
   - Check that the status progression follows organizational approval processes
   - Ensure proper integration with the documentation map and related resources

4. **Validate framework integration**:
   - Check that metadata fields are properly completed
   - Verify that the ADR follows the established template structure
   - Ensure compatibility with existing ADR numbering and filing systems

## Quality Assurance

Comprehensive quality assurance ensures ADRs meet project standards and provide valuable architectural guidance:

### Self-Review Checklist

- [ ] ADR title clearly identifies the architectural decision being made
- [ ] Context section provides comprehensive problem statement and motivation
- [ ] Decision statement is specific, actionable, and unambiguous
- [ ] Impact assessment includes technical risk, implementation effort, affected components, migration needs, performance impact, and security implications
- [ ] All considered alternatives are documented with structured pros/cons analysis and clear rejection reasons
- [ ] Consequences include both positive and negative impacts with realistic assessments
- [ ] References section includes relevant supporting documentation and resources
- [ ] Status reflects the current state of the decision accurately
- [ ] Cross-references and links to related ADRs and documentation are correct

### Validation Criteria

- **Functional validation**: ADR provides clear guidance for architectural implementation
- **Content validation**: Decision analysis is thorough, accurate, and well-reasoned
- **Integration validation**: ADR integrates properly with existing architectural governance
- **Standards validation**: Follows ADR best practices and project documentation conventions
- **Stakeholder validation**: ADR addresses the needs of architects, developers, and decision-makers

### Integration Testing Procedures

- **Decision Consistency**: Verify that the ADR doesn't conflict with existing architectural decisions
- **Reference Validation**: Check that all referenced documents and resources are accessible
- **Implementation Guidance**: Confirm that the decision provides sufficient detail for implementation
- **Governance Integration**: Ensure the ADR follows organizational approval and review processes
- **Documentation Map**: Verify that the ADR is properly integrated into the project documentation structure

## Examples

### Example 1: State Management Pattern Selection ADR

Creating an ADR for selecting the state management approach in the BreakoutBuddies Flutter application:

```powershell
# Navigate to ADR directory
cd c:\Users\ronny\VS_Code\BreakoutBuddies\breakoutbuddies\doc\product-docs\technical\architecture\design-docs\adr

# Create state management decision ADR
.\New-ArchitectureDecision.ps1 -Title "State Management Pattern Selection" -Description "Decision on state management approach for Flutter application architecture" -Status "Proposed" -OpenInEditor
```

**Customization approach:**

- **Context**: Document the need for consistent state management across the application, current pain points with ad-hoc state handling, and scalability requirements
- **Decision**: Choose Riverpod as the primary state management solution for its type safety, testability, and Flutter integration
- **Impact Assessment**: Technical Risk: Medium, Implementation Effort: 2-3 weeks, Affected Components: All UI screens and data layers, Migration Required: Yes, Performance Impact: Positive, Security Implications: None
- **Alternatives**:
  - Provider: Pros (familiar, simple) / Cons (lacks type safety, limited composition) / Rejected due to scalability concerns
  - Bloc: Pros (predictable, testable) / Cons (verbose, steep learning curve) / Rejected due to complexity overhead
  - GetX: Pros (feature-rich, fast) / Cons (opinionated, global state issues) / Rejected due to maintainability concerns
- **Consequences**: Positive impacts (better testability, type safety, performance) and negative impacts (learning curve, migration effort)
- **References**: Link to Riverpod documentation, Flutter state management best practices, and related architectural assessments

**Result:** Comprehensive ADR that guides development team on state management implementation and provides rationale for future reference

### Example 2: Database Migration Strategy ADR

Creating an ADR for database schema change management:

```powershell
# Create database migration strategy ADR
.\New-ArchitectureDecision.ps1 -Title "Database Migration Strategy" -Description "Approach for handling database schema changes and versioning" -Status "Proposed"
```

**Customization approach:**

- **Context**: Document challenges with current manual schema changes, need for automated migrations, and production deployment requirements
- **Decision**: Implement automated migration system using Supabase migration tools with version control integration
- **Impact Assessment**: Technical Risk: Low, Implementation Effort: 1 week, Affected Components: Database layer and deployment pipeline, Migration Required: No, Performance Impact: Neutral, Security Implications: Improved (version-controlled schema changes)
- **Alternatives**:
  - Manual migrations: Pros (simple, direct control) / Cons (error-prone, not scalable) / Rejected due to reliability concerns
  - Custom scripts: Pros (flexible, tailored) / Cons (maintenance overhead, reinventing wheel) / Rejected due to development cost
  - Third-party tools: Pros (feature-rich, proven) / Cons (vendor lock-in, learning curve) / Rejected due to Supabase integration
- **Consequences**: Improved deployment reliability, reduced manual errors, but increased initial setup complexity
- **References**: Supabase migration documentation, database versioning best practices, and deployment pipeline requirements

**Result:** Clear guidance for database change management that supports reliable deployments and team coordination

## Troubleshooting

### Script Execution Fails with Path Error

**Symptom:** New-ArchitectureDecision.ps1 script fails with "Cannot find common helpers" error

**Cause:** Script cannot locate the Common-ScriptHelpers.psm1 module due to incorrect path resolution

**Solution:**

1. Verify you're running the script from the correct directory: `doc/product-docs/technical/architecture/design-docs/adr/`
2. Check that the Common-ScriptHelpers.psm1 file exists at `doc/process-framework/scripts/Common-ScriptHelpers.psm1`
3. Ensure PowerShell execution policy allows script execution: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

### ADR Decision Statement Too Vague or Ambiguous

**Symptom:** ADR decision section doesn't provide clear implementation guidance or is open to multiple interpretations

**Cause:** Decision statement lacks specificity or focuses on problems rather than solutions

**Solution:**

1. Rewrite the decision statement to be specific and actionable (e.g., "Use Riverpod for state management" instead of "Improve state management")
2. Include implementation constraints or guidelines within the decision section
3. Ensure the decision answers "what exactly will be done" rather than "what problem needs solving"
4. Review the decision with stakeholders to confirm understanding and eliminate ambiguity

### Alternatives Section Lacks Depth or Justification

**Symptom:** Alternatives are listed without sufficient analysis or rejection reasons are superficial

**Cause:** Insufficient research into alternative approaches or rushed decision-making process

**Solution:**

1. Research each alternative thoroughly, including pros, cons, and implementation implications
2. Provide specific reasons for rejection based on project constraints, requirements, or trade-offs
3. Include quantitative comparisons where possible (performance, cost, complexity metrics)
4. Consult with team members who have experience with the rejected alternatives to ensure fair analysis

## Related Resources

- [System Architecture Review Task (PF-TSK-019)](../../tasks/01-planning/system-architecture-review.md) - The task that uses this guide
- [New-ArchitectureDecision.ps1 Script](../../scripts/file-creation/New-ArchitectureDecision.ps1) - Script for creating ADRs
- [ADR Template](../../templates/templates/adr-template.md) - Template customized by this guide
- [Architecture Assessment Creation Guide (PF-GDE-032)](architecture-assessment-creation-guide.md) - Guide for creating related architecture assessments
- [Guide Creation Best Practices Guide (PF-GDE-024)](guide-creation-best-practices-guide.md) - Best practices for guide creation
- [Architecture Decision Records (ADRs)](https://adr.github.io/) - External resource for ADR principles and best practices
- [Documenting Architecture Decisions](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions) - Original ADR concept by Michael Nygard

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
