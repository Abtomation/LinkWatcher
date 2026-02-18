---
id: PF-TSK-019
type: Process Framework
category: Task Definition
version: 1.0
created: 2025-07-18
updated: 2025-07-18
task_type: Discrete
---

# System Architecture Review

## Purpose & Context

Evaluate how new features fit into existing system architecture before implementation begins, preventing architectural debt and integration conflicts. This task addresses a critical gap where development jumps from Feature Discovery directly to TDD Creation without proper architectural planning. It ensures architectural consistency and provides structured integration strategy for complex features.

**Enhanced with Architectural Integration Framework**: This task now serves as the gateway between feature work and architectural work, managing architectural context packages, tracking cross-cutting architectural state, and determining when foundation features (0.x.x) are needed to support feature implementation.

## AI Agent Role

**Role**: Software Architect
**Mindset**: Systems thinking, long-term vision, pattern-focused
**Focus Areas**: Cross-cutting concerns, reusable patterns, system integration, architectural consistency
**Communication Style**: Discuss architectural implications and long-term impact, ask about system-wide effects and integration requirements

## When to Use

- Before implementing any complex feature (Tier 2 or Tier 3 complexity)
- When a feature may impact existing system architecture or introduce new components
- Before features that modify existing component relationships or dependencies
- When architectural decisions need to be made or validated
- After FDD Creation for Tier 2+ features (when functional requirements are defined) but before TDD Creation
- After Feature Tier Assessment for Tier 1 features (when architectural impact is suspected)
- When integration with external systems or APIs is required

## Context Requirements

<!-- [View Context Map for this task](../../../visualization/context-maps/[task-type]/[task-name]-map.md) - Template/example link commented out -->

- **Critical (Must Read):**

  - **Functional Design Document (FDD)** - For Tier 2+ features, the FDD containing functional requirements and user flows that inform architectural decisions
  - [Feature Discovery Document](../feature-discovery-task.md) - Understanding of the feature requirements and scope
  - [Feature Tier Assessment](../feature-tier-assessment-task.md) - Complexity evaluation of the feature being reviewed
  - [Architecture Tracking](../../state-tracking/permanent/architecture-tracking.md) - Current architectural state and cross-cutting decisions
  - [System Architecture Documentation](/doc/product-docs/technical/architecture/README.md) - Current system architecture overview
  - [Architecture Decision Records](/doc/product-docs/technical/architecture/design-docs/adr/README.md) - Existing architectural decisions and context

- **Important (Load If Space):**

  - [Architectural Framework Usage Guide](../../guides/guides/architectural-framework-usage-guide.md) - **ESSENTIAL**: Guide for managing architectural work and context packages
  - [Architecture Context Packages](/doc/product-docs/technical/architecture/context-packages/) - Bounded architectural contexts for specific areas
  - [Component Relationship Index](/doc/product-docs/technical/architecture/component-relationship-index.md) - Understanding component interactions
  - [Database Reference](/doc/product-docs/technical/architecture/database-reference.md) - Current data model and relationships
  - [Project Structure](/doc/product-docs/technical/architecture/project-structure.md) - Code organization and module structure
  - [Technical Design Documents](/doc/product-docs/technical/architecture/design-docs/tdd/README.md) - Existing TDDs for related components

- **Reference Only (Access When Needed):**
  - [Code Dependency Analysis Results](../../../.ai-workspace/dependency-maps) - Detailed dependency graphs when available
  - [Technical Debt Tracking](/doc/process-framework/state-tracking/permanent/technical-debt-tracking.md) - Known architectural issues
  - [Visual Notation Guide](/doc/process-framework/guides/guides/visual-notation-guide.md) - For interpreting context map diagrams

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished! 🚨**
>
> **⚠️ MANDATORY: Use the appropriate automation tools where indicated.**

### Preparation

1. **Gather Feature Context**: Review Feature Discovery document and Feature Tier Assessment to understand feature requirements and complexity
2. **Load Current Architecture**: Examine existing system architecture documentation, ADRs, and component relationships
3. **Load Architectural State**: Review Architecture Tracking file to understand current architectural state and ongoing work
4. **Identify Relevant Context Packages**: Determine which architectural context packages are relevant to the feature
5. **Identify Impact Areas**: Determine which system components may be affected by the feature implementation
6. **Prepare Analysis Framework**: Set up structured approach for architectural evaluation using assessment template

### Execution

5. **Component Impact Analysis**:
   - Evaluate how the feature affects existing components
   - Identify new components that need to be created
   - Assess component relationship changes and dependencies
6. **Integration Point Assessment**:
   - Analyze API integration requirements and potential changes
   - Evaluate database schema impact and data flow implications
   - Assess external system integration needs
7. **Architectural Consistency Review**:
   - Verify feature aligns with existing architectural patterns and ADRs
   - Identify potential architectural conflicts or violations
   - Evaluate adherence to established architectural principles
8. **Architectural Slice Identification**:
   - Determine if feature requires new architectural work
   - Identify bounded architectural contexts needed
   - Assess if existing context packages need updates
9. **Foundation Feature Decision Tree**:
   ```
   Does feature require new architectural work?
   ├─ Yes → Is architecture work cross-cutting (affects multiple features)?
   │  ├─ Yes → Create Foundation Feature (0.x.x) for architectural work
   │  │       → Update/Create Architecture Context Package
   │  │       → Update Architecture Tracking
   │  └─ No → Include architectural work in feature TDD
   └─ No → Continue to existing workflow (TDD Creation, etc.)
   ```
10. **Create Architecture Impact Assessment**: Document findings using assessment template
    ```powershell
    # Create architecture assessment document (when script is available)
    cd doc/product-docs/technical/architecture/assessments
    ../../scripts/file-creation/New-ArchitectureAssessment.ps1 -FeatureName "Feature Name" -AssessmentType "Impact"
    ```
11. **Risk Assessment**: Identify architectural risks, complexity factors, and potential integration issues

### Finalization

12. **Define Integration Strategy**: Outline approach for integrating the feature into existing architecture
13. **Create Architectural Decisions**: Use existing ADR system if new architectural decisions are needed
    ```powershell
    # Create ADR if architectural decisions are required
    cd doc/product-docs/technical/architecture/design-docs/adr
    ../../scripts/file-creation/New-ArchitectureDecision.ps1 -Title "Decision Title" -Status "Proposed"
    ```
14. **Update Architecture Context Packages**: Update or create context packages based on architectural analysis
    - Update existing context packages with new information
    - Create new context packages if new architectural areas identified
    - Ensure context packages reflect current architectural state
15. **Update Architecture Tracking**: Record architectural analysis outcomes and next steps
    - Update Current Architecture State table
    - Add session summary with key outcomes
    - Update ADR index if new decisions were made
16. **Provide Implementation Guidance**: Document architectural constraints and recommendations for next steps
    - If Foundation Feature needed: Provide guidance for foundation feature implementation
    - If regular feature: Provide guidance for TDD Creation
    - Include architectural context loading instructions for next agent
17. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Outputs

- **Architecture Impact Assessment Document** - Comprehensive analysis of architectural implications stored in `/doc/product-docs/technical/architecture/assessments/[feature-name]-architecture-impact-assessment.md`
- **Integration Points Specification** - Detailed integration requirements and approach documented within the assessment
- **Component Relationship Diagram** - Visual representation of how feature fits into architecture (when applicable)
- **Architectural Risk Assessment** - Identified risks and mitigation strategies documented in assessment
- **Implementation Guidance Document** - Architectural constraints and recommendations for next phase (Foundation Feature or TDD Creation)
- **New Architecture Decision Records** - ADRs created when architectural decisions are required (stored in existing ADR system)
- **Updated Architecture Context Packages** - Context packages updated or created based on architectural analysis
- **Updated Architecture Tracking** - Architecture tracking file updated with session outcomes and next steps
- **Foundation Feature Specification** - If foundation feature needed, specification for 0.x.x feature creation

## State Tracking

The following state files must be updated as part of this task:

- [Architecture Tracking](../../state-tracking/permanent/architecture-tracking.md) - Update with architectural analysis outcomes and next steps
- [Feature Tracking](../../state-tracking/permanent/feature-tracking.md) - Update feature status to "🏗️ Architecture Reviewed" and add Architecture Impact Assessment link to Arch Review column
- [Technical Debt Tracking](../../state-tracking/permanent/technical-debt-tracking.md) - Add any architectural debt items identified during review
- [Architecture Decision Log](../../state-tracking/permanent/process-improvement-tracking.md) - Record architectural decisions made during review (if applicable)

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

Before considering this task finished:

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] Architecture Impact Assessment document created and comprehensive
  - [ ] Integration strategy clearly defined and documented
  - [ ] Architectural risks identified and mitigation strategies provided
  - [ ] Implementation guidance provided for next phase (Foundation Feature or TDD Creation)
  - [ ] New ADRs created if architectural decisions were required
  - [ ] Architecture context packages updated or created as needed
  - [ ] Foundation feature specification created if foundation feature needed
- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] [Architecture Tracking](../../state-tracking/permanent/architecture-tracking.md) updated with session outcomes
  - [ ] [Feature Tracking](../../state-tracking/permanent/feature-tracking.md) updated with status "🏗️ Architecture Reviewed" and Architecture Impact Assessment link in Arch Review column
  - [ ] [Technical Debt Tracking](../../state-tracking/permanent/technical-debt-tracking.md) updated with any identified architectural debt
  - [ ] [Process Improvement Tracking](../../state-tracking/permanent/process-improvement-tracking.md) updated with architectural decisions made
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Completion Instructions](../../guides/guides/feedback-form-completion-instructions.md) for each tool used, using task ID "PF-TSK-019" and context "System Architecture Review"

## Next Tasks

- [**Foundation Feature Implementation**](../04-implementation/foundation-feature-implementation-task.md) - If foundation feature (0.x.x) needed, implement architectural work first
- [**API Design**](../02-design/api-design-task.md) - If API design requirements identified during assessment, design API contracts before TDD Creation
- [**Database Schema Design**](../02-design/database-schema-design-task.md) - If database design requirements identified during assessment, design schema before TDD Creation
- [**TDD Creation Task**](../02-design/tdd-creation-task.md) - Create Technical Design Documents based on architectural guidance and FDD requirements (if no foundation feature needed)
- [**Feature Implementation Task**](../04-implementation/feature-implementation-task.md) - Implement feature following architectural constraints and integration strategy

## Related Resources

- [Architecture Decision Records System](/doc/product-docs/technical/architecture/design-docs/adr/README.md) - For creating architectural decisions
- [System Architecture Documentation](/doc/product-docs/technical/architecture/README.md) - Current architecture overview
- [Component Relationship Index](/doc/product-docs/technical/architecture/component-relationship-index.md) - Understanding system components
- [Feature Tier Assessment Task](../feature-tier-assessment-task.md) - Prerequisite task for complexity evaluation
