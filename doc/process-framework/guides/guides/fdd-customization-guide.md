---
id: PF-GDE-039
type: Document
category: General
version: 1.1
created: 2025-08-01
updated: 2025-01-27
guide_status: Active
guide_description: Guide for customizing FDD templates after creation
guide_category: Documentation
related_script: New-FDD.ps1
guide_title: FDD Customization Guide
change_notes: "v1.1 - Added Separation of Concerns section for IMP-097/IMP-098"
---

# FDD Customization Guide

## Overview

This guide provides comprehensive instructions for customizing Functional Design Document (FDD) templates after they are created using the New-FDD.ps1 script. FDDs capture functional requirements, user interactions, and business logic before technical implementation begins.

## When to Use

Use this guide when:

- You've created an FDD using New-FDD.ps1 and need to customize the template content
- You need to define functional requirements for Tier 2 (Moderate) or Tier 3 (Complex) features
- You're working on features with complex user interactions or business rules
- You need to create testable acceptance criteria before technical design

> **🚨 CRITICAL**: FDD templates created by New-FDD.ps1 are structural frameworks only. They MUST be extensively customized with actual functional requirements before use. Never use an uncustomized FDD template.

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

- **FDD Template Created**: An FDD template generated using New-FDD.ps1
- **Feature Information**: Feature ID, name, and basic description from feature tracking
- **Human Consultation Completed**: Direct consultation with human partner about how the feature should work from user perspective
- **Feature Tier Assessment**: Confirmation that the feature requires FDD (Tier 2 or Tier 3)
- **Understanding of Feature Context**: Knowledge of the feature's business value and user needs

## Background

Functional Design Documents (FDDs) bridge the gap between feature requirements and technical design. They focus on **what** a feature does from a user perspective, not **how** it's implemented technically. FDDs are essential for:

- **Stakeholder Alignment**: Ensuring everyone understands what the feature will do
- **Clear Requirements**: Defining functional requirements before technical complexity
- **Testable Specifications**: Creating acceptance criteria that can be verified
- **Risk Reduction**: Identifying edge cases and business rules early

FDDs use Feature ID prefixes (e.g., `1-1-1-FR-1` for Feature ID "1.1.1") to prevent requirement mixup between different features.

## Template Structure Analysis

The FDD template consists of several interconnected sections that work together to provide a complete functional specification:

### Required Sections

- **Feature Overview**: Establishes context and business value
- **Functional Requirements**: Core functionality (FR), User Interactions (UI), Business Rules (BR)
- **User Experience Flow**: Step-by-step user journey
- **Acceptance Criteria**: Testable success conditions
- **Edge Cases & Error Handling**: Exception scenarios and system responses

### Optional Sections

- **Dependencies**: Functional and technical prerequisites
- **Success Metrics**: Measurement criteria for feature success
- **Additional Notes**: Assumptions, constraints, special considerations

### Section Interdependencies

- Feature Overview provides context for all other sections
- Functional Requirements inform User Experience Flow design
- User Experience Flow drives Acceptance Criteria definition
- Edge Cases extend both Functional Requirements and Acceptance Criteria

## Customization Decision Points

### Critical Customization Choices

1. **Requirement Granularity**: How detailed should functional requirements be?

   - **Simple Features**: 3-5 core requirements may suffice
   - **Complex Features**: May need 10+ requirements across FR, UI, BR categories
   - **Decision Criteria**: Base on feature complexity and stakeholder needs

2. **User Experience Flow Detail**: How comprehensive should the user journey be?

   - **Linear Features**: Simple step-by-step flow
   - **Complex Features**: Multiple paths, decision points, alternative flows
   - **Decision Criteria**: Consider user personas and feature complexity

3. **Edge Case Coverage**: How many edge cases to document?
   - **Minimum**: Critical error scenarios and data validation
   - **Comprehensive**: All possible exception paths and system responses
   - **Decision Criteria**: Feature risk level and user impact

### Recommended Approaches

- **Start Simple**: Begin with core requirements, expand as needed
- **User-Centric**: Focus on user value and experience first
- **Testable**: Ensure all requirements can be verified through testing

## Separation of Concerns and Cross-Referencing

> **📋 Detailed Guidance**: See [Task Transition Guide - Information Flow Section](task-transition-guide.md#information-flow-and-separation-of-concerns)

Functional Design Documents focus exclusively on **functional-level concerns**: user stories, functional requirements, business rules, user workflows, and acceptance criteria from a user perspective. This section helps you understand what to document in detail vs. what to reference from other tasks.

### What FDDs Own

**✅ Document in detail in FDDs:**

- User stories and use cases
- Functional requirements (what the system does from user perspective)
- Business rules and validation logic
- User workflows and interaction patterns
- Acceptance criteria and success conditions
- User-facing error handling and edge cases
- Functional dependencies and prerequisites
- User-level success metrics

### What Other Tasks Own

**❌ Reference briefly, document in detail elsewhere:**

- **API contracts** → API Specification (PF-TSK-020)
  - Endpoint specifications and request/response schemas
  - API authentication and authorization patterns
  - API error codes and status responses
- **Database schema details** → Database Schema Design (PF-TSK-021)
  - Table structures, relationships, constraints
  - RLS policies and database-level security
  - Migration strategies and data transformations
- **Implementation details** → TDD (PF-TSK-022)
  - Component architecture and design patterns
  - Service layer implementation
  - Business logic algorithms and data structures
- **Test implementation** → Test Specification (PF-TSK-012)
  - Test cases and test scenarios
  - Test data and mock strategies
  - Test implementation roadmap

### Cross-Reference Standards

When creating FDDs, use the following format for cross-references:

**Standard Format:**

```markdown
> **📋 Primary Documentation**: [Task Name] ([Task ID])
> **🔗 Link**: [Document Title - Document ID] > **👤 Owner**: [Task Name]
>
> **Purpose**: [Brief explanation of what's documented elsewhere]
```

**Brief Summary Guidelines:**

- Keep summaries to 2-5 sentences
- Focus on functional-level perspective (user-facing behaviors)
- Avoid duplicating detailed specifications from other tasks
- Link to the authoritative source

### Decision Framework: When to Document vs. Reference

Use this decision tree when deciding what to include in FDDs:

1. **Is it about user stories, functional requirements, or business rules?**

   - ✅ YES → Document in detail in FDD
   - ❌ NO → Continue to question 2

2. **Is it about API contracts, endpoints, or request/response formats?**

   - ✅ YES → Brief summary + reference to API Specification
   - ❌ NO → Continue to question 3

3. **Is it about database schema, tables, or RLS policies?**

   - ✅ YES → Brief summary + reference to Database Schema Design
   - ❌ NO → Continue to question 4

4. **Is it about component architecture, design patterns, or implementation details?**

   - ✅ YES → Brief summary + reference to TDD
   - ❌ NO → Continue to question 5

5. **Is it about test cases, test data, or test implementation?**
   - ✅ YES → Brief summary + reference to Test Specification
   - ❌ NO → Document in FDD if relevant to functional requirements

### Common Pitfalls to Avoid

**❌ Anti-Pattern 1: Documenting API Contracts**

- **Problem**: Including detailed endpoint specifications, request/response schemas in FDD
- **Solution**: Provide brief functional API requirements + link to API Specification

**❌ Anti-Pattern 2: Duplicating Database Schema**

- **Problem**: Copying table structures, relationships, and constraints into FDD
- **Solution**: Provide brief functional data requirements + link to Database Schema Design

**❌ Anti-Pattern 3: Over-Documenting Implementation Details**

- **Problem**: Including component architecture, design patterns, or algorithms in FDD
- **Solution**: Focus on user-facing behaviors + link to TDD for implementation details

**❌ Anti-Pattern 4: Documenting Test Cases**

- **Problem**: Including detailed test scenarios, test data, or test implementation in FDD
- **Solution**: Provide acceptance criteria + link to Test Specification for test details

**❌ Anti-Pattern 5: Technical Language in Functional Requirements**

- **Problem**: Using technical jargon or implementation details in functional requirements
- **Solution**: Focus on user-visible behaviors and outcomes, avoid technical terminology

### Examples of Proper Cross-Referencing

**Example 1: Referencing API Specification**

```markdown
## Related Documentation

### API Specification Reference

> **📋 Primary Documentation**: API Design Task (PF-TSK-020)
> **🔗 Link**: [API Data Models Registry - PF-STA-036] > **👤 Owner**: API Design Task

**Brief Summary**: Users authenticate via email/password or social login endpoints. Feature requires real-time data updates through WebSocket API. Users receive clear error messages for invalid input.
```

**Example 2: Referencing Database Schema**

```markdown
### Database Schema Reference

> **📋 Primary Documentation**: Database Schema Design Task (PF-TSK-021)
> **🔗 Link**: [Database Schema Design Document - PD-SCH-008] > **👤 Owner**: Database Schema Design Task

**Brief Summary**: Users can create and manage multiple bookings. Each booking is associated with a specific user and venue. Users can only view their own booking history.
```

**Example 3: Referencing Technical Design**

```markdown
### Technical Design Reference

> **📋 Primary Documentation**: TDD Creation Task (PF-TSK-022)
> **🔗 Link**: [Technical Design Document - PD-TDD-025] > **👤 Owner**: TDD Creation Task

**Brief Summary**: Feature provides real-time updates to users within 2 seconds. Users can access feature offline with cached data. Feature supports concurrent usage by multiple users.
```

**Example 4: Referencing Test Specification**

```markdown
### Test Specification Reference

> **📋 Primary Documentation**: Test Specification Creation Task (PF-TSK-012)
> **🔗 Link**: [Test Specification Document - PD-TST-018] > **👤 Owner**: Test Specification Creation Task

**Brief Summary**: All acceptance criteria must be validated through user scenario tests. Edge cases and error handling require functional testing. User workflows must be tested end-to-end.
```

## Step-by-Step Instructions

### 1. Customize Feature Overview

1. **Replace Feature Metadata**: Update `[Feature ID]`, `[Feature Name]` with actual values from feature tracking
2. **Define Business Value**: Replace `[Why this feature matters to users and business]` with clear value proposition
3. **Write User Story**: Complete the "As a [user type], I want [goal] so that [benefit]" format
   ```markdown
   - **Feature ID**: 1.1.1
   - **Feature Name**: User Registration
   - **Business Value**: Enables new users to create accounts and access platform features
   - **User Story**: As a new visitor, I want to create an account so that I can save my preferences and book escape rooms
   ```

**Expected Result:** Feature Overview section provides clear context and justification for the feature

### 2. Define Functional Requirements

1. **Create Core Functionality Requirements**: Define what the system must do using Feature ID prefixes
2. **Document User Interactions**: Specify how users interact with the feature
3. **Establish Business Rules**: Define validation logic, constraints, and business logic

   ```markdown
   ### Core Functionality

   - **1-1-1-FR-1**: System must validate email address format during registration
   - **1-1-1-FR-2**: System must create unique user account with encrypted password

   ### User Interactions

   - **1-1-1-UI-1**: User enters email, password, and confirms password in registration form
   - **1-1-1-UI-2**: System displays success message and redirects to dashboard after successful registration

   ### Business Rules

   - **1-1-1-BR-1**: Password must be minimum 8 characters with at least one number and special character
   - **1-1-1-BR-2**: Email address must be unique across all user accounts
   ```

**Expected Result:** All functional requirements clearly defined with proper Feature ID prefixes

### 3. Document User Experience Flow

1. **Define Entry Point**: How users access this feature
2. **Map Main Flow**: Step-by-step user actions and system responses
3. **Identify Decision Points**: Where users make choices and available options
4. **Document Alternative Paths**: Different ways users might complete the task
   ```markdown
   1. **Entry Point**: User clicks "Sign Up" button on homepage
   2. **Main Flow**:
      - User enters email address
      - User creates password and confirms it
      - User clicks "Create Account" button
      - System validates input and creates account
      - System sends confirmation email
      - User is redirected to dashboard
   3. **Decision Points**: User can choose to sign up with email or social media
   4. **Alternative Paths**: Social media registration bypasses password creation
   ```

**Expected Result:** Complete user journey documented with all major paths and decision points

### 4. Create Acceptance Criteria

1. **Write Testable Criteria**: Each criterion must be verifiable through testing
2. **Use Feature ID Prefixes**: Maintain traceability to functional requirements
3. **Make Criteria Measurable**: Avoid vague language, use specific conditions
   ```markdown
   - [ ] **1-1-1-AC-1**: User can successfully create account with valid email and password
   - [ ] **1-1-1-AC-2**: System rejects registration with invalid email format
   - [ ] **1-1-1-AC-3**: System rejects registration with weak password
   - [ ] **1-1-1-AC-4**: User receives confirmation email within 5 minutes of registration
   ```

**Expected Result:** All acceptance criteria are testable, measurable, and linked to functional requirements

### 5. Identify Edge Cases and Error Handling

1. **Document Exception Scenarios**: What can go wrong during feature use
2. **Define System Responses**: How the system should handle each edge case
3. **Consider Data Validation**: Invalid inputs and system boundaries
   ```markdown
   - **1-1-1-EC-1**: If email already exists, display "Email already registered" message
   - **1-1-1-EC-2**: If network fails during registration, save form data and retry
   - **1-1-1-EC-3**: If confirmation email fails to send, provide manual verification option
   ```

**Expected Result:** All major edge cases identified with expected system behaviors

### 6. Validation and Final Review

1. **Complete Validation Checklist**: Use the checklist in Quality Assurance section
2. **Review Feature ID Consistency**: Ensure all requirements use correct Feature ID prefix
3. **Verify Traceability**: Confirm acceptance criteria link back to functional requirements
4. **Check Completeness**: Ensure all template sections are meaningfully filled

**Expected Result:** FDD is complete, consistent, and ready for stakeholder review

## Quality Assurance

### Self-Review Checklist

- [ ] **Feature Overview Complete**: All metadata fields filled with meaningful content
- [ ] **Functional Requirements Defined**: Core functionality, user interactions, and business rules specified
- [ ] **Feature ID Prefixes Consistent**: All requirements use correct [Feature-ID] format
- [ ] **User Experience Flow Documented**: Complete user journey with decision points and alternative paths
- [ ] **Acceptance Criteria Testable**: All criteria are specific, measurable, and verifiable
- [ ] **Edge Cases Identified**: Major exception scenarios and error handling documented
- [ ] **No Template Placeholders Remaining**: All [bracketed] placeholders replaced with actual content
- [ ] **Human Consultation Reflected**: FDD content reflects input from human partner consultation

### Validation Criteria

- **Functional Validation**: All functional requirements clearly specify what the system must do
- **User-Centric Validation**: FDD focuses on user value and experience, not technical implementation
- **Testability Validation**: Acceptance criteria can be verified through testing
- **Completeness Validation**: All required sections contain meaningful, specific content
- **Consistency Validation**: Feature ID prefixes used consistently throughout document

### Integration Testing Procedures

- **Feature Tracking Integration**: Verify FDD links correctly in feature tracking document
- **TDD Preparation**: Ensure FDD provides sufficient functional detail for technical design
- **Stakeholder Review**: FDD should be understandable by non-technical stakeholders

## Examples

### Example 1: User Registration Feature FDD

Complete example of customizing an FDD for a user registration feature:

```markdown
# User Registration - Functional Design Document

## Feature Overview

- **Feature ID**: 1.1.1
- **Feature Name**: User Registration
- **Business Value**: Enables new users to create accounts and access platform features, increasing user base and engagement
- **User Story**: As a new visitor, I want to create an account so that I can save my preferences and book escape rooms

## Functional Requirements

### Core Functionality

- **1-1-1-FR-1**: System must validate email address format during registration
- **1-1-1-FR-2**: System must create unique user account with encrypted password storage
- **1-1-1-FR-3**: System must send confirmation email to verify email address

### User Interactions

- **1-1-1-UI-1**: User enters email, password, and confirms password in registration form
- **1-1-1-UI-2**: System displays real-time validation feedback for form fields
- **1-1-1-UI-3**: System shows success message and redirects to dashboard after registration

### Business Rules

- **1-1-1-BR-1**: Password must be minimum 8 characters with at least one number and special character
- **1-1-1-BR-2**: Email address must be unique across all user accounts
- **1-1-1-BR-3**: User account is inactive until email verification is completed

## Acceptance Criteria

- [ ] **1-1-1-AC-1**: User can successfully create account with valid email and password
- [ ] **1-1-1-AC-2**: System rejects registration with invalid email format
- [ ] **1-1-1-AC-3**: System rejects registration with weak password
- [ ] **1-1-1-AC-4**: User receives confirmation email within 5 minutes
```

**Result:** Complete FDD that clearly defines functional requirements and acceptance criteria

## Troubleshooting

### Requirements Too Technical

**Symptom:** Functional requirements describe implementation details rather than user-facing functionality

**Cause:** Confusion between functional requirements (what) and technical design (how)

**Solution:**

1. Focus on user-visible behavior and system responses
2. Avoid technical implementation details like database schemas or API calls
3. Ask "What does the user experience?" rather than "How does the system work?"

### Acceptance Criteria Not Testable

**Symptom:** Acceptance criteria use vague language like "user-friendly" or "fast performance"

**Cause:** Criteria written without considering how they will be verified

**Solution:**

1. Use specific, measurable conditions (e.g., "loads within 3 seconds")
2. Define clear pass/fail conditions
3. Ensure each criterion can be verified through testing

### Feature ID Prefix Inconsistency

**Symptom:** Requirements use different ID formats or missing Feature ID prefixes

**Cause:** Manual typing errors or misunderstanding of ID format

**Solution:**

1. Use consistent format: [Feature-ID]-[Type]-[Number] (e.g., "1-1-1-FR-1")
2. Replace dots in Feature ID with dashes for requirement prefixes
3. Double-check all requirements use the same Feature ID prefix

## Related Resources

- [FDD Template](../../templates/templates/fdd-template.md) - The template this guide helps customize
- [New-FDD.ps1 Script](../../scripts/file-creation/New-FDD.ps1) - Script for creating FDD documents
- [FDD Creation Task](../../tasks/02-design/fdd-creation-task.md) - Task definition for creating FDDs
- [Feature Tier Assessment Task](../../tasks/01-planning/feature-tier-assessment-task.md) - Determines when FDD is required
- [Feature Tracking](../../state-tracking/permanent/feature-tracking.md) - Central feature tracking document

---

_This guide provides comprehensive instructions for customizing FDD templates. Follow the step-by-step process to ensure your FDD captures complete functional requirements before technical design begins._
