---
id: PF-GDE-029
type: Document
category: General
version: 1.1
created: 2025-07-27
updated: 2025-01-27
guide_description: Guide for customizing Technical Design Document templates
related_script: New-tdd.ps1
guide_title: TDD Creation Guide
related_tasks: PF-TSK-015
guide_status: Active
change_notes: "v1.1 - Added Separation of Concerns section for IMP-097/IMP-098 (cross-reference guidance)"
---

# TDD Creation Guide

## Overview

This guide provides comprehensive instructions for creating and customizing Technical Design Documents (TDDs) using the New-tdd.ps1 script and tier-specific templates. It helps you create appropriate design documentation based on feature complexity, ensuring architectural consistency and effective collaboration between development sessions.

## When to Use

Use this guide when you need to:

- Create a Technical Design Document for a feature that has received a complexity tier assessment
- Customize TDD templates for different complexity tiers (T1, T2, T3)
- Ensure proper architectural planning before feature implementation
- Document design decisions for handoff between AI agent sessions
- Plan integration with existing system components
- Coordinate work between multiple developers on complex features

> **🚨 CRITICAL**: Always use the New-tdd.ps1 script to create TDDs - never create them manually. This ensures proper ID assignment, tier-appropriate templates, and metadata integration with the framework.

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

- Access to PowerShell and the New-tdd.ps1 script in `doc/product-docs/technical/architecture/design-docs/tdd/`
- Completed Feature Tier Assessment for the feature you're documenting
- Understanding of the feature requirements and scope
- Familiarity with the project's architecture and component structure
- Access to the TDD Creation Task (PF-TSK-015) documentation
- Knowledge of the feature's complexity tier (T1, T2, or T3)

## Background

Technical Design Documents (TDDs) serve as architectural blueprints that guide feature implementation and ensure consistency across the codebase. The BreakoutBuddies project uses a tiered approach to TDD creation, where the depth and detail of documentation scales with feature complexity:

### Tier-Based Documentation Approach

- **Tier 1 (T1)**: Lightweight planning documents for simple features with minimal architectural impact
- **Tier 2 (T2)**: Standard TDDs with essential sections for moderate complexity features
- **Tier 3 (T3)**: Comprehensive TDDs with full architectural analysis for complex features

### TDD Creation Process Benefits

- **Architectural Consistency**: Ensures new features align with existing system design
- **Session Handoffs**: Provides context for AI agent transitions and developer collaboration
- **Implementation Guidance**: Offers clear technical direction for feature development
- **Risk Mitigation**: Identifies potential issues before implementation begins
- **Documentation Standards**: Maintains consistent technical documentation across the project

Each TDD receives a unique ID (PD-TDD-XXX) and includes tier-appropriate sections for requirements, design, implementation guidance, and session handoff notes.

## Template Structure Analysis

The TDD templates are designed with tier-specific structures that scale documentation depth with feature complexity. Understanding each tier's structure helps you choose the appropriate template and customize it effectively:

### Tier 1 (T1) - Feature Planning Document

**Purpose**: Lightweight planning for simple features with minimal architectural impact
**Key Sections**:

- **Overview**: Brief feature description and purpose
- **User Story**: Single user story capturing the core need
- **Requirements**: Simple list of 3-5 key requirements
- **Implementation Approach**: High-level approach with key components (UI, Logic, Data)
- **Dependencies**: List of feature or component dependencies
- **Testing Considerations**: 1-3 key testing points
- **AI Agent Session Handoff Notes**: Context for session transitions

**Customization Focus**: Keep content concise, focus on essential information only

### Tier 2 (T2) - Lightweight Technical Design Document

**Purpose**: Standard TDD with essential sections for moderate complexity features
**Key Sections**:

- **Overview**: Purpose and related features
- **Key Requirements**: 3-5 most important requirements
- **Design**: Data models, UI components, business logic, API contracts
- **Implementation Plan**: Phased approach with milestones
- **Testing Strategy**: Unit, integration, and user acceptance testing
- **Deployment Considerations**: Environment-specific considerations
- **AI Agent Session Handoff Notes**: Detailed context for transitions

**Customization Focus**: Balance detail with conciseness, include architectural decisions

### Tier 3 (T3) - Comprehensive Technical Design Document

**Purpose**: Full architectural analysis for complex features with system-wide impact
**Key Sections**:

- **Overview**: Purpose, scope, and related features
- **Requirements**: Functional, non-functional requirements, and constraints
- **Architecture**: Component diagrams, data flow, state management
- **Detailed Design**: Models, services, UI components, API specifications
- **Implementation Plan**: Detailed phases with dependencies and milestones
- **Testing Strategy**: Comprehensive testing approach across all levels
- **Security Considerations**: Security analysis and mitigation strategies
- **Performance Considerations**: Performance requirements and optimization strategies
- **Deployment Strategy**: Detailed deployment and rollback procedures
- **Monitoring and Observability**: Logging, metrics, and monitoring requirements
- **AI Agent Session Handoff Notes**: Comprehensive context preservation

**Customization Focus**: Comprehensive coverage, detailed technical specifications, risk analysis

### Common Template Elements

**All tiers include**:

- **Metadata Section**: Document ID, feature ID, tier, creation/update dates
- **AI Agent Session Handoff Notes**: Critical for maintaining context between sessions
- **Implementation guidance**: Tier-appropriate level of technical direction
- **Testing considerations**: Scaled to feature complexity

## Customization Decision Points

When creating and customizing TDDs, you'll face several critical decisions that impact the effectiveness of your design documentation:

### Tier Selection Decision

**Decision**: Which complexity tier template should be used?
**Criteria**: Based on Feature Tier Assessment results

- **T1**: Simple features, minimal architectural impact, single developer, < 1 week effort
- **T2**: Moderate features, some architectural decisions, potential multi-developer, 1-4 weeks effort
- **T3**: Complex features, significant architectural impact, multi-developer coordination, > 4 weeks effort
  **Impact**: Determines documentation depth and required sections

### Detail Level Decision

**Decision**: How much technical detail should be included in each section?
**Criteria**:

- **T1**: High-level approach, key decisions only
- **T2**: Moderate detail, architectural decisions with rationale
- **T3**: Comprehensive detail, full technical specifications
  **Impact**: Affects implementation guidance quality and session handoff effectiveness

### Architecture Documentation Decision

**Decision**: What level of architectural documentation is needed?
**Criteria**:

- **T1**: Simple component list (UI, Logic, Data)
- **T2**: Component relationships and data flow
- **T3**: Full component diagrams, data flow, state management analysis
  **Impact**: Determines implementation consistency and integration success

### Implementation Planning Decision

**Decision**: How detailed should the implementation plan be?
**Criteria**:

- **T1**: Basic approach description
- **T2**: Phased approach with milestones
- **T3**: Detailed phases with dependencies, risks, and contingencies
  **Impact**: Affects project planning accuracy and execution success

### Session Handoff Detail Decision

**Decision**: What level of detail is needed in AI Agent Session Handoff Notes?
**Criteria**:

- **All Tiers**: Include current progress, next steps, key decisions, blockers
- **T2/T3**: Add architectural context, integration points, risk factors
- **T3**: Include comprehensive state, dependencies, and decision rationale
  **Impact**: Critical for maintaining context and continuity between development sessions

## Separation of Concerns and Cross-Referencing

> **📋 Detailed Guidance**: See [Task Transition Guide - Information Flow Section](task-transition-guide.md#information-flow-and-separation-of-concerns)

Technical Design Documents focus exclusively on **implementation-level concerns**: component architecture, design patterns, service implementation, state management, and technical integration. This section helps you understand what to document in detail vs. what to reference from other tasks.

### What TDDs Own

**✅ Document in detail in TDDs:**

- Component architecture and design patterns
- Service layer implementation approach
- State management strategy
- Business logic and algorithms
- Technical integration patterns
- Code structure and organization
- Implementation-specific quality attributes (performance optimization, error handling)
- Technical dependencies and integration points

### What Other Tasks Own

**❌ Reference briefly, document in detail elsewhere:**

- **Functional requirements** → FDD (PF-TSK-010)
  - User stories and use cases
  - Business rules and workflows
  - Feature specifications and acceptance criteria
- **API contracts** → API Specification (PF-TSK-020)
  - Endpoint specifications and request/response schemas
  - API authentication and authorization patterns
  - API error handling and status codes
- **Database schema details** → Database Schema Design (PF-TSK-021)
  - Table structures, relationships, constraints
  - RLS policies and database-level security
  - Migration strategies and data transformations
- **Comprehensive test plans** → Test Specification (PF-TSK-012)
  - Detailed test cases and test data
  - Testing procedures and acceptance criteria
  - Test environment setup

### Cross-Reference Standards

When creating TDDs, use the following format for cross-references:

**Standard Format:**

```markdown
> **📋 Primary Documentation**: [Task Name] ([Task ID])
> **🔗 Link**: [Document Title - Document ID] > **👤 Owner**: [Task Name]
>
> **Purpose**: [Brief explanation of what's documented elsewhere]
```

**Brief Summary Guidelines:**

- Keep summaries to 2-5 sentences
- Focus on implementation-level perspective
- Avoid duplicating detailed specifications from other tasks
- Link to the authoritative source

### Decision Framework: When to Document vs. Reference

Use this decision tree when deciding what to include in TDDs:

1. **Is it about component architecture, design patterns, or service implementation?**

   - ✅ YES → Document in detail in TDD
   - ❌ NO → Continue to question 2

2. **Is it about functional requirements, user stories, or business workflows?**

   - ✅ YES → Brief summary + reference to FDD
   - ❌ NO → Continue to question 3

3. **Is it about API contracts, endpoints, or request/response formats?**

   - ✅ YES → Brief summary + reference to API Specification
   - ❌ NO → Continue to question 4

4. **Is it about database schema, tables, or RLS policies?**

   - ✅ YES → Brief summary + reference to Database Schema Design
   - ❌ NO → Continue to question 5

5. **Is it about comprehensive test cases or testing procedures?**
   - ✅ YES → Brief summary + reference to Test Specification
   - ❌ NO → Document in TDD if relevant to implementation design

### Common Pitfalls to Avoid

**❌ Anti-Pattern 1: Duplicating Functional Requirements**

- **Problem**: Copying user stories, use cases, and business rules into TDD
- **Solution**: Provide brief implementation context + link to FDD

**❌ Anti-Pattern 2: Documenting API Contracts**

- **Problem**: Including detailed endpoint specifications, request/response schemas
- **Solution**: Provide brief service integration approach + link to API Specification

**❌ Anti-Pattern 3: Duplicating Database Schema**

- **Problem**: Copying table structures, relationships, and constraints into TDD
- **Solution**: Provide brief data access pattern summary + link to Database Schema Design

**❌ Anti-Pattern 4: Creating Comprehensive Test Plans**

- **Problem**: Including detailed test cases, test data, and testing procedures
- **Solution**: Provide brief testability considerations + link to Test Specification

**❌ Anti-Pattern 5: Over-Documenting Validation Rules**

- **Problem**: Duplicating validation rules already defined in API Specification or FDD
- **Solution**: Reference validation rules and focus on implementation approach

### Examples of Proper Cross-Referencing

**Example 1: Referencing Functional Requirements**

```markdown
## 5. Cross-References

### 5.1 Functional Requirements Reference

> **📋 Primary Documentation**: FDD Creation Task (PF-TSK-010)
> **🔗 Link**: [Functional Design Document - PD-FDD-042] > **👤 Owner**: FDD Creation Task

**Brief Summary**: This feature implements user authentication with email/password and social login. The TDD focuses on the technical implementation of authentication flows, token management, and session handling.
```

**Example 2: Referencing API Specification**

```markdown
### 5.2 API Specification Reference

> **📋 Primary Documentation**: API Design Task (PF-TSK-020)
> **🔗 Link**: [API Data Models Registry - PF-STA-036] > **👤 Owner**: API Design Task

**Brief Summary**: The authentication API provides endpoints for login, logout, and token refresh. This TDD describes how the Flutter service layer integrates with these endpoints using the Supabase client.
```

**Example 3: Referencing Database Schema**

```markdown
### 5.3 Database Schema Reference

> **📋 Primary Documentation**: Database Schema Design Task (PF-TSK-021)
> **🔗 Link**: [Database Schema Design Document - PD-SCH-008] > **👤 Owner**: Database Schema Design Task

**Brief Summary**: User authentication data is stored in the auth.users table with profile extensions in public.user_profiles. This TDD focuses on repository pattern implementation for data access and caching strategies.
```

## Step-by-Step Instructions

### 1. Prepare TDD Information

1. **Verify Feature Tier Assessment** is complete

   - Locate the feature's tier assessment document
   - Confirm the assigned complexity tier (T1, T2, or T3)
   - Review the assessment rationale and key complexity factors

2. **Gather Required Information**:

   - **Feature ID**: Unique identifier (e.g., "1.2.3")
   - **Feature Name**: Clear, descriptive name (e.g., "User Authentication System")
   - **Tier**: Complexity tier from assessment (1, 2, or 3)
   - **Requirements**: Functional and non-functional requirements
   - **Dependencies**: Related features and system components

3. **Review Related Documentation**:
   - Existing TDDs for similar features
   - Project architecture documentation
   - Component relationship index
   - Feature tracking information

**Expected Result:** Complete understanding of feature scope, complexity, and documentation requirements

### 2. Create TDD Using New-tdd.ps1

1. **Navigate to the TDD directory**:

   ```powershell
   cd doc/product-docs/technical/architecture/design-docs/tdd
   ```

2. **Execute the New-tdd.ps1 script** with your prepared parameters:

   ```powershell
   # For Tier 1 (simple features)
   .\New-tdd.ps1 -FeatureId "1.2.3" -FeatureName "User Profile Display" -Tier 1

   # For Tier 2 (moderate features)
   .\New-tdd.ps1 -FeatureId "2.1.4" -FeatureName "Authentication System" -Tier 2 -OpenInEditor

   # For Tier 3 (complex features)
   .\New-tdd.ps1 -FeatureId "3.1.1" -FeatureName "Real-time Collaboration" -Tier 3 -OpenInEditor
   ```

3. **Verify TDD Creation**:
   - Check the success message for the assigned ID (PD-TDD-XXX)
   - Note the file path where the TDD was created
   - Confirm the correct tier template was applied

**Expected Result:** New TDD file created with proper ID, tier-appropriate template, and basic metadata populated

### 3. Customize the TDD Content

1. **Complete Core Sections** based on tier:

   - **T1**: Overview, User Story, Requirements, Implementation Approach
   - **T2**: Overview, Key Requirements, Design, Implementation Plan
   - **T3**: All sections including Architecture, Detailed Design, Security, Performance

2. **Fill in Technical Details**:

   - **Data Models**: Define required data structures with code examples
   - **Component Architecture**: Describe component relationships and interactions
   - **API Specifications**: Document required APIs and interfaces
   - **Integration Points**: Identify system integration requirements

3. **Document Implementation Guidance**:
   - **Implementation Steps**: Break down development into logical phases
   - **Dependencies**: Document prerequisite work and blocking factors
   - **Risk Factors**: Identify potential implementation challenges
   - **Success Criteria**: Define measurable completion criteria

**Expected Result:** Comprehensive TDD with tier-appropriate technical detail and clear implementation guidance

### 4. Complete AI Agent Session Handoff Notes

1. **Document Current State**:

   - Progress made on the TDD
   - Key architectural decisions and rationale
   - Outstanding questions or uncertainties
   - Next steps for implementation

2. **Provide Implementation Context**:

   - Critical design decisions that affect implementation
   - Integration points with existing systems
   - Potential risks or challenges identified
   - Dependencies that must be resolved first

3. **Include Handoff Checklist**:
   - What has been completed in this session
   - What needs to be done next
   - Key files and resources to reference
   - Important context for the next developer/session

**Expected Result:** Comprehensive handoff notes that enable seamless transition between development sessions

### Validation and Testing

After completing the TDD customization:

1. **Validate Content Completeness**:

   - Ensure all tier-required sections are filled with meaningful content
   - Verify technical details are accurate and implementable
   - Check that architectural decisions are well-justified
   - Confirm implementation guidance is clear and actionable

2. **Test Integration with Framework**:

   - Verify the TDD links properly to feature tracking
   - Check that dependencies are correctly documented
   - Test that the document supports the TDD Creation Task workflow
   - Confirm integration with related architectural documentation

3. **Review for Implementation Readiness**:
   - Validate that the TDD provides sufficient guidance for implementation
   - Check that all architectural decisions are documented
   - Ensure session handoff notes enable effective transitions
   - Verify that testing strategy aligns with feature complexity

## Quality Assurance

[Optional section for template customization guides. Provide comprehensive quality assurance guidance including:

### Self-Review Checklist

- [ ] Template sections are properly customized
- [ ] All required fields are completed
- [ ] Customization aligns with task requirements
- [ ] Cross-references and links are correct
- [ ] Examples are relevant and accurate

### Validation Criteria

- Functional validation: Template works as intended
- Content validation: Information is accurate and complete
- Integration validation: Template integrates properly with related components
- Standards validation: Follows project conventions and standards

### Integration Testing Procedures

- Test template with related scripts and tools
- Verify workflow integration points
- Validate cross-references and dependencies
- Confirm compatibility with existing framework components]

## Examples

### Example 1: Tier 2 TDD - User Authentication System

Creating a TDD for a moderate complexity authentication feature:

```powershell
# Navigate to TDD directory
cd doc/product-docs/technical/architecture/design-docs/tdd

# Create Tier 2 TDD
.\New-tdd.ps1 -FeatureId "2.1.4" -FeatureName "User Authentication System" -Tier 2 -OpenInEditor
```

**Customization approach:**

- **Overview**: "Implement secure user authentication with JWT tokens, supporting login, logout, and session management"
- **Key Requirements**: Multi-factor authentication, secure token storage, session timeout, password policies
- **Design**: Authentication service, token management, secure storage, UI components
- **Implementation Plan**: Phase 1 (basic auth), Phase 2 (MFA), Phase 3 (session management)
- **Testing Strategy**: Unit tests for auth service, integration tests for login flow, security testing

**Result:** Comprehensive T2 TDD that provides clear implementation guidance for moderate complexity feature

### Example 2: Tier 3 TDD - Real-time Collaboration System

Creating a TDD for a complex real-time feature:

```powershell
# Create comprehensive Tier 3 TDD
.\New-tdd.ps1 -FeatureId "3.1.1" -FeatureName "Real-time Collaboration" -Tier 3 -OpenInEditor
```

**Customization approach:**

- **Architecture**: WebSocket connections, event sourcing, conflict resolution, state synchronization
- **Detailed Design**: Real-time service architecture, data models for collaborative state, API specifications
- **Security Considerations**: Authentication for WebSocket connections, data encryption, access control
- **Performance Considerations**: Connection scaling, message queuing, state optimization
- **Deployment Strategy**: Gradual rollout, monitoring, rollback procedures

**Result:** Comprehensive T3 TDD with full architectural analysis for complex system integration

## Troubleshooting

### Wrong Tier Template Applied

**Symptom:** TDD template doesn't match feature complexity or contains inappropriate sections

**Cause:** Incorrect tier parameter provided to New-tdd.ps1 script or outdated feature assessment

**Solution:**

1. Verify the feature's tier assessment document
2. Delete the incorrectly created TDD file
3. Re-run New-tdd.ps1 with the correct tier parameter
4. If tier assessment is outdated, complete a new Feature Tier Assessment first

### TDD Creation Script Fails

**Symptom:** New-tdd.ps1 reports errors or fails to create the TDD file

**Cause:** Script path issues, missing templates, or PowerShell execution policy restrictions

**Solution:**

1. Ensure you're running from the correct directory: `doc/product-docs/technical/architecture/design-docs/tdd/`
2. Verify the tier template exists in `doc/product-docs/templates/templates/`
3. Check PowerShell execution policy: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`
4. Verify all required parameters are provided correctly

### Session Handoff Notes Incomplete

**Symptom:** AI Agent Session Handoff Notes section lacks sufficient detail for effective transitions

**Cause:** Insufficient documentation of current state, decisions, or next steps

**Solution:**

1. Review the handoff notes checklist in Step 4
2. Document all architectural decisions made during the session
3. Include specific next steps with clear priorities
4. Add context about any blockers or dependencies identified
5. Reference specific files, components, or resources needed for continuation

## Related Resources

- [TDD Creation Task (PF-TSK-015)](../../tasks/02-design/tdd-creation-task.md) - The task that uses this guide
- [Feature Tier Assessment Task](../../tasks/01-planning/feature-tier-assessment-task.md) - Required prerequisite for TDD creation
- [New-tdd.ps1 Script](../../scripts/file-creation/New-tdd.ps1) - Script for creating TDDs
- [TDD T1 Template](../../../product-docs/templates/templates/tdd-t1-template.md) - Tier 1 template for simple features
- [TDD T2 Template](../../../product-docs/templates/templates/tdd-t2-template.md) - Tier 2 template for moderate features
- [TDD T3 Template](../../../product-docs/templates/templates/tdd-t3-template.md) - Tier 3 template for complex features
- [Guide Creation Best Practices Guide (PF-GDE-024)](guide-creation-best-practices-guide.md) - Best practices for guide creation
- [Component Relationship Index](../../../product-docs/technical/architecture/component-relationship-index.md) - For understanding system architecture

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
