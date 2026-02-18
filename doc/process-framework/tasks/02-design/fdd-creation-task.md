---
id: PF-TSK-027
type: Process Framework
category: Task Definition
version: 1.2
created: 2025-08-01
updated: 2025-01-27
task_type: Discrete
change_notes: "v1.2 - Added Information Flow and Separation of Concerns sections for IMP-097/IMP-098"
---

# FDD Creation

## Purpose & Context

Create comprehensive Functional Design Documents (FDD) that capture functional requirements, user interactions, and business logic before technical implementation begins. FDDs bridge the gap between feature requirements and technical design, ensuring clear understanding of what the feature does from a user perspective.

## AI Agent Role

**Role**: Product Analyst
**Mindset**: User-focused, detail-oriented, requirement-driven
**Focus Areas**: User experience flows, business logic, acceptance criteria, edge case identification
**Communication Style**: Ask clarifying questions about user needs and business rules, validate understanding with examples

## When to Use

- After Feature Tier Assessment for Tier 2 (Moderate) or Tier 3 (Complex) features
- Before TDD Creation when functional requirements need clarification
- When features have complex user interactions or business rules
- When features require stakeholder alignment on functional behavior
- When features involve multiple user personas or workflows
- When acceptance criteria need detailed specification before technical design

## Information Flow

> **📋 Detailed Guidance**: See [Task Transition Guide - Information Flow Section](../../guides/guides/task-transition-guide.md#information-flow-and-separation-of-concerns)

### Inputs from Other Tasks

- **Feature Tier Assessment**: Complexity tier, FDD requirement determination, quality attribute priorities
- **Feature Discovery Task** (if available): Background research, user needs analysis, competitive analysis
- **Feature Tracking**: Feature ID, name, description, initial requirements

### Outputs to Other Tasks

- **API Design Task**: Functional requirements for API endpoints, user-facing data requirements, functional workflows
- **Database Schema Design Task**: User data requirements, functional relationships, business rules for validation
- **UI/UX Design Task**: User interaction flows, functional workflows, user requirements, acceptance criteria for visual design
- **TDD Creation Task**: Functional requirements, user workflows, business rules, acceptance criteria
- **Test Specification Task**: Acceptance criteria, user workflows, functional validation requirements

### Cross-Reference Standards

When referencing other tasks' outputs in FDDs:

- Use brief summary (2-5 sentences) + link to source document
- Focus on **functional-level perspective** (what the system does from user perspective)
- Avoid duplicating API contracts, database schemas, or technical implementation details
- Reference technical decisions from TDD and data access patterns from API Design

### Separation of Concerns

**✅ FDDs Should Document:**

- User stories and personas
- Functional requirements (what the system must do)
- Business rules and validation logic
- User workflows and interaction flows
- Acceptance criteria
- User-facing error handling
- Functional dependencies
- User-level success metrics

**❌ FDDs Should NOT Document:**

- API endpoint contracts (owned by API Design Task)
- Database table schemas (owned by Database Schema Design Task)
- Technical implementation details (owned by TDD)
- Test cases and test data (owned by Test Specification Task)
- Component architecture (owned by TDD)
- Performance optimization strategies (owned by TDD)

## Context Requirements

B-design/visualization/context-maps/discrete/fdd-creation-map.md)

- **Critical (Must Read):**

  - **Feature Information** - Feature details from B-design/state-tracking/permanent/feature-tracking.md) including ID, name, description, and tier assessment
  - **Feature Tier Assessment** - Complexity evaluation and FDD requirement determination from A-planning/feature-tier-assessment-task.md)
  - **Human Input on Feature Behavior** - Direct consultation with human partner about how the feature should work from user perspective
  - B-design/guides/guides/fdd-customization-guide.md) - Essential guide for understanding FDD structure and customization requirements

- **Important (Load If Space):**

  - B-design/templates/templates/fdd-template.md) - Template structure for creating FDD documents
  - A-planning/feature-discovery-task.md) - Background research and analysis if available
  - B-design/state-tracking/permanent/feature-tracking.md) - Any existing user stories or requirements documentation

- **Reference Only (Access When Needed):**
  - B-design/guides/guides/visual-notation-guide.md) - For interpreting context map diagrams
  - [ID Registry](../discrete/id-registry.json) - For FDD ID assignment and directory mapping

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished! 🚨**
>
> **⚠️ MANDATORY: Use the ../discrete/02-design/02-design/02-design/02-design/New-FDD.ps1 automation script for document creation.**

### Preparation

1. **Identify Target Feature**: Locate the feature in B-design/state-tracking/permanent/feature-tracking.md) and verify it requires FDD creation
2. **Review Feature Tier Assessment**: Confirm the feature is Tier 2 or Tier 3, or has specific FDD triggers (complex interactions, business rules, etc.)
3. **Gather Existing Information**: Collect any available feature discovery results, user stories, or requirements documentation

### Execution

4. **🚨 MANDATORY: Consult Human Partner**: Focus consultation on high-level requirements and business context
   - **Human Responsibilities**: High-level user workflow, business value, and key business rules
   - **AI Responsibilities**: Detailed functional specifications, edge cases, acceptance criteria, and technical integration
   - Request overall user experience flow and primary business objectives
   - Ask about critical business constraints and validation rules
   - Clarify success criteria from business perspective
5. **Create FDD Document**: Use the automation script to generate the FDD structure
   ```bash
   # Windows command pattern using absolute path with echo method:
   echo c:\Users\[YourUsername]\VS_Code\BreakoutBuddies\breakoutbuddies\doc\process-framework\scripts\file-creation\New-FDD.ps1 -FeatureId [Feature-ID] -FeatureName "Feature Name Here" | powershell -NoProfile -
   ```
   > **Note**: Replace `[YourUsername]` with your actual Windows username, `[Feature-ID]` with the feature ID (e.g., 6.4.1), and `"Feature Name Here"` with your feature name.
   > **Important**: Use the echo method to avoid PowerShell quote handling issues in Windows CMD.
6. **Develop Detailed Functional Requirements**: Using human input as foundation, create comprehensive specifications with Feature ID prefixes:
   - Core functionality requirements ([Feature-ID]-FR-1, [Feature-ID]-FR-2, etc.)
   - User interaction flows ([Feature-ID]-UI-1, [Feature-ID]-UI-2, etc.)
   - Business rules and validation logic ([Feature-ID]-BR-1, [Feature-ID]-BR-2, etc.)
7. **Create Detailed User Experience Flow**: Expand human-provided workflow into complete user journey with decision points and alternative paths
8. **Define Comprehensive Acceptance Criteria**: Create testable, measurable acceptance criteria based on functional requirements
9. **Identify Edge Cases and Error Handling**: Document edge cases and error handling scenarios with expected behaviors
10. **Map Dependencies**: Identify functional and technical dependencies from other features or systems

### Finalization

11. **Validate Completeness**: Review FDD against the validation checklist in the template
12. **Verify Automated Updates**: The ../discrete/02-design/02-design/02-design/02-design/New-FDD.ps1 script automatically updates feature tracking - verify the updates were applied correctly
13. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Outputs

- **Functional Design Document (FDD)** - Complete FDD document in `/doc/product-docs/functional-design/fdds/fdd-[feature-id]-[feature-name].md` with assigned FDD ID
- **Updated Feature Tracking** - Feature status updated to "📋 FDD Created" with FDD link in B-design/state-tracking/permanent/feature-tracking.md)

## State Tracking

The following state files are automatically updated by the ../discrete/02-design/02-design/02-design/02-design/New-FDD.ps1 script:

- B-design/state-tracking/permanent/feature-tracking.md) - Automatically updated with feature status "📋 FDD Created" and FDD document link in the FDD column

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

Before considering this task finished:

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] FDD document created with proper ID and complete content in `/doc/product-docs/functional-design/fdds/`
  - [ ] All FDD template sections filled with meaningful content (no placeholders remaining)
  - [ ] Functional requirements, user interactions, and business rules clearly documented
  - [ ] Acceptance criteria are testable and measurable
  - [ ] Edge cases and error handling scenarios identified
- [ ] **Verify Automated Updates**: Ensure the ../discrete/02-design/02-design/02-design/02-design/New-FDD.ps1 script successfully updated state tracking files
  - [ ] B-design/state-tracking/permanent/feature-tracking.md) automatically updated with FDD link and status "📋 FDD Created"
- [ ] **Human Consultation Completed**: Confirmed that human partner was consulted about feature behavior and requirements
- [ ] **Complete Feedback Forms**: Follow the B-design/guides/guides/feedback-form-completion-instructions.md) for each tool used, using task ID "PF-TSK-027" and context "FDD Creation"

## Next Tasks

- B-design/tdd-creation-task.md) - Create Technical Design Document based on functional requirements defined in the FDD
- B-design/test-specification-creation-task.md) - Create comprehensive test specifications using FDD acceptance criteria
- B-design/feature-implementation-task.md) - Implement the feature using both FDD and TDD as guidance

## Related Resources

- B-design/templates/templates/fdd-template.md) - Template for creating Functional Design Documents
- B-design/guides/guides/fdd-customization-guide.md) - Guide for customizing FDD templates after creation
- A-planning/feature-tier-assessment-task.md) - Task for determining if FDD is required
- B-design/state-tracking/permanent/feature-tracking.md) - Central tracking document for all features
- B-design/proposals/proposals/functional-design-document-integration-concept.md) - Original concept document for FDD integration
