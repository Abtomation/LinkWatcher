---
id: PF-MAI-001
type: Process Framework
category: Documentation Map
version: 1.3
created: 2023-06-15
updated: 2025-08-07
---

# Project Documentation Map

This document serves as a central index for all documentation in the Breakout Buddies project. It provides links to both process framework documents and product documentation to help you find the information you need.

## Process Framework Documents

These documents describe how we work and our development processes:

### Task Definitions

Our tasks are organized into four categories and follow a unified structure:

> **📋 Recent Enhancement (2025-08-01)**: All task definitions now include **AI Agent Role** sections that specify the professional role, mindset, focus areas, and communication style for optimal AI agent behavior during task execution.

#### Onboarding Tasks

- [Task: Codebase Feature Discovery](tasks/00-onboarding/codebase-feature-discovery.md) - Discover all features in existing codebase and assign every source file
- [Task: Codebase Feature Analysis](tasks/00-onboarding/codebase-feature-analysis.md) - Analyze implementation patterns, dependencies, and design decisions
- [Task: Retrospective Documentation Creation](tasks/00-onboarding/retrospective-documentation-creation.md) - Create tier assessments and required design documentation

#### Discrete Tasks

- [Task: Feature Tier Assessment](tasks/01-planning/feature-tier-assessment-task.md) - Assess complexity of new features
- [Task: FDD Creation](tasks/02-design/fdd-creation-task.md) - Create Functional Design Documents for Tier 2+ features
- [Task: TDD Creation](tasks/02-design/tdd-creation-task.md) - Create Technical Design Documents
- [Task: UI/UX Design](tasks/02-design/ui-ux-design-task.md) - Create comprehensive UI/UX design specifications for features with visual complexity
- [Task: Test Specification Creation](tasks/03-testing/test-specification-creation-task.md) - Create comprehensive test specifications from TDDs
- [Task: Test Implementation](tasks/03-testing/test-implementation-task.md) - Implement comprehensive test cases based on existing Test Specifications, enabling test-driven development
- [Task: Test Audit](tasks/03-testing/test-audit-task.md) - Systematic quality assessment of test implementations using six evaluation criteria
- [Task: Feature Implementation Planning](tasks/04-implementation/feature-implementation-planning-task.md) - Analyze design documentation and create detailed implementation plan with task sequencing and dependency mapping
- [Task: Data Layer Implementation](tasks/04-implementation/data-layer-implementation.md) - Implement data models, repositories, and database integration for feature
- [Task: Feature Implementation](tasks/04-implementation/feature-implementation-task.md) - Implement features based on designs
- [Task: Foundation Feature Implementation](tasks/04-implementation/foundation-feature-implementation-task.md) - Implement foundation features (0.x.x) that provide architectural foundations for the application
- [Task: Architectural Consistency Validation](tasks/05-validation/architectural-consistency-validation.md) - Validate foundational features for architectural pattern adherence, ADR compliance, and interface consistency
- [Task: Code Quality Standards Validation](tasks/05-validation/code-quality-standards-validation.md) - Validate foundational features for code quality standards, SOLID principles, and Flutter best practices adherence
- [Task: Integration Dependencies Validation](tasks/05-validation/integration-dependencies-validation.md) - Validate foundational features for dependency health, interface contracts, and data flow integrity
- [Task: Documentation Alignment Validation](tasks/05-validation/documentation-alignment-validation.md) - Validate foundational features for TDD alignment, ADR compliance, and API documentation accuracy
- [Task: Extensibility Maintainability Validation](tasks/05-validation/extensibility-maintainability-validation.md) - Validate foundational features for extension points, configuration flexibility, and testing support
- [Task: AI Agent Continuity Validation](tasks/05-validation/ai-agent-continuity-validation.md) - Validate foundational features for context clarity, modular structure, and documentation quality to support AI agent workflow continuity
- [Task: Code Review](tasks/06-maintenance/code-review-task.md) - Review code for quality and correctness
- [Task: Bug Triage](tasks/06-maintenance/bug-triage-task.md) - Systematically evaluate, prioritize, and assign reported bugs
- [Task: Bug Fixing](tasks/06-maintenance/bug-fixing-task.md) - Diagnose and fix bugs
- [Task: Release Deployment](tasks/07-deployment/release-deployment-task.md) - Manage releases and deployments
- [Task: System Architecture Review](tasks/01-planning/system-architecture-review.md) - Evaluate how new features fit into existing system architecture before implementation
- [Task: API Design](tasks/02-design/api-design-task.md) - Design comprehensive API contracts and specifications before implementation begins
- [Task: Database Schema Design](tasks/02-design/database-schema-design-task.md) - Plan data model changes before coding to prevent data integrity issues
- [Task: Code Refactoring](tasks/06-maintenance/code-refactoring-task.md) - Systematic code improvement and technical debt reduction without changing external behavior
- [Task: Feature Discovery](tasks/01-planning/feature-discovery-task.md) - Identify and document potential new features

#### Support Tasks

- [Task: Project Initiation](tasks/support/project-initiation-task.md) - Initial project setup including project-config.json creation
- [Task: New Task Creation Process](tasks/support/new-task-creation-process.md) - Complete process for creating new tasks from concept to implementation-ready definition
- [Task: Process Improvement](tasks/support/process-improvement-task.md) - Improve development processes
- [Task: Structure Change](tasks/support/structure-change-task.md) - Manage structural changes to documentation
- [Task: Framework Extension Task](tasks/support/framework-extension-task.md) - Support task for fundamentally extending the framework with new functionalities and capabilities
- [Task: Tools Review](tasks/support/tools-review-task.md) - Review and improve project tools and templates

#### Cyclical Tasks

- [Task: Documentation Tier Adjustment](tasks/cyclical/documentation-tier-adjustment-task.md) - Adjust documentation requirements
- [Task: Technical Debt Assessment](tasks/cyclical/technical-debt-assessment-task.md) - Systematic approach to identifying, categorizing, and prioritizing technical debt across the codebase

### Core Process Documents

- [Process: Feature Tracking](state-tracking/permanent/feature-tracking.md) - Comprehensive list of all features with implementation status
- [Process: Test Case Implementation Tracking](state-tracking/permanent/test-implementation-tracking.md) - Tracks implementation status of test cases derived from test specifications
- [Process: Definition of Done](methodologies/definition-of-done.md) - Clear criteria for when a feature is considered complete
- [Process: Technical Debt Tracking](state-tracking/permanent/technical-debt-tracking.md) - System for tracking and managing technical debt
- [Process: Foundational Validation Tracking](state-tracking/temporary/foundational-validation-tracking.md) - Master tracking for foundational codebase validation across all validation types
- [Process: Feature Implementation Template](templates/templates/feature-implementation-template.md) - Template for planning and implementing features
- [Process: Implementation Plan Template](templates/templates/implementation-plan-template.md) - Template for creating implementation plan documents that define sequenced execution strategies for feature implementation
- [Process: Foundation Feature Template](templates/templates/foundation-feature-template.md) - Template for foundation feature structure and architectural documentation
- [Process: FDD Template](templates/templates/fdd-template.md) - Template for creating Functional Design Documents
- [Process: UI Design Template](templates/templates/ui-design-template.md) - Comprehensive template for creating UI/UX Design Documents with wireframes, visual specifications, accessibility requirements, and platform adaptations
- [Process: Architecture Impact Assessment Template](templates/templates/architecture-impact-assessment-template.md) - Template for creating architecture impact assessments
- [Process: API Specification Template](templates/templates/api-specification-template-template.md) - Template for creating comprehensive API contract definitions
- [Process: Schema Design Template](templates/templates/schema-design-template.md) - Template for database schema design documents
- [Process: Test Audit Report Template](templates/templates/test-audit-report-template.md) - Template for systematic test quality assessment reports
- [Process: Feedback Form Template](templates/templates/feedback-form-template.md) - Template for creating tool and process feedback forms
- [Process: Technical Debt Assessment Template](templates/templates/technical-debt-assessment-template.md) - Template for technical debt assessment reports
- [Process: Debt Item Template](templates/templates/debt-item-template.md) - Template for individual debt item records
- [Process: Prioritization Matrix Template](templates/templates/prioritization-matrix-template.md) - Template for debt prioritization matrices
- [Process: Temporary Task Creation State Template](templates/templates/temp-task-creation-state-template.md) - Template for tracking multi-session task creation implementation
- [Process: Structure Change State Template](templates/templates/structure-change-state-template.md) - Template for tracking multi-session structure change implementation
- [Process: Framework Extension Concept Template](templates/templates/framework-extension-concept-template.md) - Template for creating framework extension concept documents
- [Process: Validation Report Template](templates/templates/validation-report-template.md) - Template for creating foundational codebase validation reports
- [Process: Code Quality Standards Validation Concept](proposals/code-quality-standards-validation-concept.md) - Concept document for code quality validation task creation
- [Process: Database Schema Design Task Usage Guide](guides/guides/database-schema-design-task-usage-guide.md) - Comprehensive guide for using the Database Schema Design Task effectively
- [Process: Feature Implementation Planning Task Usage Guide](guides/guides/feature-implementation-planning-task-usage-guide.md) - Comprehensive guide for using the Feature Implementation Planning Task effectively to create detailed implementation plans
- [Process: Foundation Feature Implementation Usage Guide](guides/guides/foundation-feature-implementation-usage-guide.md) - Comprehensive guide for using the Foundation Feature Implementation task effectively
- [Process: Test Audit Usage Guide](guides/guides/test-audit-usage-guide.md) - Comprehensive guide for conducting systematic test quality assessments
- [Process: Feedback Form Guide](guides/guides/feedback-form-guide.md) - Comprehensive guide for completing feedback forms effectively
- [Process: Feedback Form Completion Instructions](guides/guides/feedback-form-completion-instructions.md) - Standardized instructions for completing feedback forms (referenced by all tasks)
- [Process: Task Transition Guide](guides/guides/task-transition-guide.md) - Guidance on when and how to transition between related tasks

### Automation Scripts

- [Process: New Bug Report Script](scripts/file-creation/New-BugReport.ps1) - PowerShell script for creating standardized bug reports during task execution
- [Process: New UI Design Script](scripts/file-creation/New-UIDesign.ps1) - PowerShell script for creating UI/UX Design documents with auto-assigned IDs and Design Guidelines references

## Product Documentation

These documents describe what we're building:

### Core Product Documents

- [Product: Roadmap](../product-docs/technical/implementation/roadmap.md) - Strategic plan for implementation organized by phase and priority
- [Product: Feature Dependencies](../product-docs/technical/design/feature-dependencies.md) - Visual map and matrix of feature dependencies

### Process Framework Checklists

- [Process: Feature Implementation Checklist](../product-docs/checklists/checklists/feature-implementation-checklist.md) - Comprehensive checklist for implementing features
- [Process: UI Component Checklist](../product-docs/checklists/checklists/ui-component-checklist.md) - Checklist for implementing UI components
- [Process: API Integration Checklist](../product-docs/checklists/checklists/api-integration-checklist.md) - Checklist for API integration
- [Process: Testing Checklist](../product-docs/checklists/checklists/testing-checklist.md) - Checklist for testing
- [Process: Security Checklist](../product-docs/checklists/checklists/security-checklist.md) - Checklist for security considerations
- [Process: Accessibility Checklist](../product-docs/checklists/checklists/accessibility-checklist.md) - Checklist for accessibility
- [Process: Performance Checklist](../product-docs/checklists/checklists/performance-checklist.md) - Checklist for performance optimization

### Process Framework Guides

- [Process: Development Guide](../product-docs/guides/guides/development-guide.md) - Best practices and guidelines for development
- [Process: Documentation Guide](guides/guides/documentation-guide.md) - Guidelines for documentation
- [Process: Testing Guide](../product-docs/guides/guides/testing-guide.md) - Guide for testing the application
- [Process: Assessment Quick Reference](methodologies/documentation-tiers/assessment-quick-reference.md) - Quick reference for feature tier assessment
- [Process: Visual Notation Guide](guides/guides/visual-notation-guide.md) - Standard notation used in diagrams and context maps
- [Process: Temporary State File Customization Guide](guides/guides/temp-state-tracking-customization-guide.md) - Guide for customizing temporary state files for different workflows
- [Process: Test Specification Creation Usage Guide](guides/guides/test-specification-creation-usage-guide.md) - Comprehensive guide for using the Test Specification Creation task effectively
- [Process: Test Implementation Usage Guide](guides/guides/test-implementation-usage-guide.md) - Comprehensive guide for using the Test Implementation task effectively
- [Process: System Architecture Review Usage Guide](guides/guides/system-architecture-review-usage-guide.md) - Comprehensive guide for using the System Architecture Review task effectively
- [Process: API Design Task Usage Guide](guides/guides/api-design-task-usage-guide.md) - Comprehensive guide for using the API Design Task effectively
- [Process: Code Refactoring Task Usage Guide](guides/guides/code-refactoring-task-usage-guide.md) - Comprehensive guide for using the Code Refactoring Task effectively

- [Process: Assessment Criteria Guide](guides/guides/assessment-criteria-guide.md) - Detailed criteria for identifying technical debt
- [Process: Prioritization Guide](guides/guides/prioritization-guide.md) - Guide for applying impact/effort matrix to prioritize debt
- [Process: Guide Creation Best Practices Guide](guides/guides/guide-creation-best-practices-guide.md) - Best practices for creating effective guides within the task framework
- [Process: Debt Item Creation Guide](guides/guides/debt-item-creation-guide.md) - Guide for customizing technical debt item templates
- [Process: State File Creation Guide](guides/guides/state-file-creation-guide.md) - Guide for customizing state tracking file templates
- [Process: Test File Creation Guide](guides/guides/test-file-creation-guide.md) - Guide for customizing test file templates
- [Process: Test Specification Creation Guide](guides/guides/test-specification-creation-guide.md) - Guide for customizing test specification templates
- [Process: TDD Creation Guide](guides/guides/tdd-creation-guide.md) - Guide for customizing Technical Design Document templates
- [Process: FDD Customization Guide](guides/guides/fdd-customization-guide.md) - Guide for customizing Functional Design Document templates
- [Process: UI Design Customization Guide](guides/guides/ui-design-customization-guide.md) - 19-step guide across 6 phases for customizing UI/UX Design Document templates with tiered examples
- [Process: API Data Model Creation Guide](guides/guides/api-data-model-creation-guide.md) - Guide for customizing API data model templates
- [Process: API Specification Creation Guide](guides/guides/api-specification-creation-guide.md) - Guide for customizing API specification templates
- [Process: Architecture Assessment Creation Guide](guides/guides/architecture-assessment-creation-guide.md) - Guide for customizing architecture assessment templates
- [Process: Architecture Decision Creation Guide](guides/guides/architecture-decision-creation-guide.md) - Guide for customizing Architecture Decision Record templates
- [Process: Schema Design Creation Guide](guides/guides/schema-design-creation-guide.md) - Guide for customizing database schema design templates
- [Process: Framework Extension Customization Guide](guides/guides/framework-extension-customization-guide.md) - Essential guide for customizing Framework Extension Concept documents
- [Process: Foundational Validation Guide](guides/guides/foundational-validation-guide.md) - Comprehensive guide for conducting foundational codebase validation using the 6-type validation framework
- [Process: Bug Reporting Guide](guides/guides/bug-reporting-guide.md) - Standardized procedures for reporting bugs discovered during task execution

### Visualization Resources

- [Context Maps README](visualization/context-maps/README.md) - Guide to using context maps for tasks
- [Context Maps Template](templates/templates/context-map-template.md) - Template for creating new context maps

#### Discrete Task Context Maps

- [API Design Map](visualization/context-maps/02-design/api-design-task-map.md) - Components for designing API contracts and specifications
- [Architectural Consistency Validation Map](visualization/context-maps/05-validation/architectural-consistency-validation-map.md) - Components for validating architectural pattern adherence and ADR compliance
- [Bug Fixing Map](visualization/context-maps/06-maintenance/bug-fixing-map.md) - Components for fixing bugs
- [Code Quality Standards Validation Map](visualization/context-maps/05-validation/code-quality-standards-validation-map.md) - Components for validating code quality standards and SOLID principles
- [Code Refactoring Map](visualization/context-maps/06-maintenance/code-refactoring-task-map.md) - Components for systematic code improvement and technical debt reduction
- [Integration Dependencies Validation Map](visualization/context-maps/05-validation/integration-dependencies-validation-map.md) - Components for validating dependency health, interface contracts, and data flow integrity
- [Documentation Alignment Validation Map](visualization/context-maps/05-validation/documentation-alignment-validation-map.md) - Components for validating TDD alignment, ADR compliance, and API documentation accuracy
- [Extensibility Maintainability Validation Map](visualization/context-maps/05-validation/extensibility-maintainability-validation-map.md) - Components for validating extension points, configuration flexibility, and testing support
- [AI Agent Continuity Validation Map](visualization/context-maps/05-validation/ai-agent-continuity-validation-map.md) - Components for validating context clarity, modular structure, and documentation quality for AI agent workflow continuity
- [Code Review Map](visualization/context-maps/06-maintenance/code-review-map.md) - Components for reviewing code changes
- [FDD Creation Map](visualization/context-maps/02-design/fdd-creation-map.md) - Components for creating Functional Design Documents
- [UI/UX Design Map](visualization/context-maps/02-design/ui-ux-design-task-map.md) - Components for creating UI/UX design specifications with Design Guidelines consultation
- [Feature Discovery Map](visualization/context-maps/01-planning/feature-discovery-map.md) - Components for exploring features
- [Feature Implementation Map](visualization/context-maps/04-implementation/feature-implementation-map.md) - Components for implementing features
- [Feature Tier Assessment Map](visualization/context-maps/01-planning/feature-tier-assessment-map.md) - Components for assessing complexity
- [Process Improvement Map](visualization/context-maps/support/process-improvement-map.md) - Components for improving processes
- [Release Deployment Map](visualization/context-maps/07-deployment/release-deployment-map.md) - Components for deployment
- [Structure Change Map](visualization/context-maps/support/structure-change-map.md) - Components for structural changes
- [Framework Extension Task Map](visualization/context-maps/support/framework-extension-task-map.md) - Context map for Framework Extension Task showing component relationships and workflow
- [System Architecture Review Map](visualization/context-maps/01-planning/system-architecture-review-map.md) - Components for evaluating system architecture
- [TDD Creation Map](visualization/context-maps/02-design/tdd-creation-map.md) - Components for creating design documents
- [Test Specification Creation Map](visualization/context-maps/03-testing/test-specification-creation-map.md) - Components for creating test specifications from TDDs
- [Test Implementation Map](visualization/context-maps/03-testing/test-implementation-map.md) - Components for implementing comprehensive test cases based on existing Test Specifications
- [Test Audit Map](visualization/context-maps/03-testing/test-audit-map.md) - Components for systematic test quality assessment workflow

#### Cyclical Task Context Maps

- [Documentation Review Map](visualization/context-maps/cyclical/documentation-review-map.md) - Components for reviewing documentation
- [Documentation Tier Adjustment Map](visualization/context-maps/cyclical/documentation-tier-adjustment-map.md) - Components for adjusting tiers
- [Tools Review Map](visualization/context-maps/support/tools-review-map.md) - Components for reviewing tools
- [Technical Debt Assessment Map](visualization/context-maps/cyclical/technical-debt-assessment-task-map.md) - Context map for Technical Debt Assessment task

### Product Technical Design

- [Product: Technical Design Documents](../product-docs/technical/design/README.md) - Detailed technical designs for complex features
- [Product: UI/UX Design Guidelines (PD-UIX-001)](../product-docs/technical/design/ui-ux/design-system/design-guidelines.md) - Living reference for design principles, visual foundation (colors, typography, spacing), component library, accessibility standards (WCAG 2.1 Level AA), and platform-specific guidelines - MUST be consulted for every UI Design task
- [Product: Project Structure](../product-docs/technical/architecture/project-structure.md) - Detailed breakdown of the project structure
- [Product: Component Relationship Index](../product-docs/technical/architecture/component-relationship-index.md) - Comprehensive reference of all component relationships and interactions

## How to Use This Documentation

### For Planning New Features

1. Use the [Task: Feature Discovery](tasks/01-planning/feature-discovery-task.md) process to identify potential new features
2. Check the [Process: Feature Tracking](state-tracking/permanent/feature-tracking.md) document to identify features that need implementation
3. Use the [Task: Feature Tier Assessment](tasks/01-planning/feature-tier-assessment-task.md) process to determine the feature's complexity
4. Follow the [Task: TDD Creation](tasks/02-design/tdd-creation-task.md) process to create tier-appropriate design documentation
5. Consult the [Product: Feature Dependencies](../product-docs/technical/design/feature-dependencies.md) map to understand dependencies

### During Implementation

1. Follow the [Task: Feature Implementation](tasks/04-implementation/feature-implementation-task.md) process
2. Use the appropriate specialized checklists for specific aspects (UI, API, etc.)
3. Document any intentional technical debt in the [Process: Technical Debt Tracking](state-tracking/permanent/technical-debt-tracking.md)
4. Adhere to the guidelines in the [Process: Development Guide](../product-docs/guides/guides/development-guide.md)

### After Implementation

1. Follow the [Task: Code Review](tasks/06-maintenance/code-review-task.md) process
2. Verify your implementation against the [Process: Definition of Done](methodologies/definition-of-done.md) criteria
3. Update the [Process: Feature Tracking](state-tracking/permanent/feature-tracking.md) document
4. Use the [Task: Bug Fixing](tasks/06-maintenance/bug-fixing-task.md) process for any issues that arise
5. Plan for addressing any technical debt created during implementation

## Document Relationships

```mermaid
graph TD
    A[Feature Tracking] --> B[Roadmap]
    A --> C[Feature Dependencies]
    C --> D[Feature Implementation Template]
    D --> E[Technical Design Documents]
    D --> F[Feature Implementation Checklist]
    F --> G[Specialized Checklists]
    F --> H[Definition of Done]
    F --> I[Technical Debt Tracker]

    classDef process fill:#d4f1f9,stroke:#0099cc,color:#005577
    classDef product fill:#d5e8d4,stroke:#82b366,color:#2d5930

    class A,D,F,G,H,I process
    class B,C,E product
```

This diagram shows how the various documents relate to each other in the development workflow, with process framework documents in blue and product documentation in green.

## Task Structure and Types

Our project uses a unified task structure with four task types:

### Onboarding Tasks
| PF-TSK-066 | [/process-framework/tasks/00-onboarding/retrospective-documentation-creation.md](/process-framework/tasks/00-onboarding/retrospective-documentation-creation.md) | Documentation | Retrospective Documentation Creation | /doc/process-framework/tasks/../../../tasks/README.md |
| PF-TSK-065 | [/process-framework/tasks/00-onboarding/codebase-feature-analysis.md](/process-framework/tasks/00-onboarding/codebase-feature-analysis.md) | Documentation | Codebase Feature Analysis | /doc/process-framework/tasks/../../../tasks/README.md |
| PF-TSK-064 | [/process-framework/tasks/00-onboarding/codebase-feature-discovery.md](/process-framework/tasks/00-onboarding/codebase-feature-discovery.md) | Documentation | Codebase Feature Discovery | /doc/process-framework/tasks/../../../tasks/README.md |

### Discrete Tasks
| PF-TSK-056 | [/process-framework/tasks/04-implementation/state-management-implementation.md](/process-framework/tasks/04-implementation/state-management-implementation.md) | Documentation | State Management Implementation | /doc/process-framework/tasks/../../../tasks/README.md |
| PF-TSK-055 | [/process-framework/tasks/04-implementation/implementation-finalization.md](/process-framework/tasks/04-implementation/implementation-finalization.md) | Documentation | Implementation Finalization | /doc/process-framework/tasks/../../../tasks/README.md |
| PF-TSK-054 | [/process-framework/tasks/04-implementation/quality-validation.md](/process-framework/tasks/04-implementation/quality-validation.md) | Documentation | Quality Validation | /doc/process-framework/tasks/../../../tasks/README.md |
| PF-TSK-053 | [/process-framework/tasks/04-implementation/integration-and-testing.md](/process-framework/tasks/04-implementation/integration-and-testing.md) | Documentation | Integration and Testing | /doc/process-framework/tasks/../../../tasks/README.md |
| PF-TSK-052 | [/process-framework/tasks/04-implementation/ui-implementation.md](/process-framework/tasks/04-implementation/ui-implementation.md) | Documentation | UI Implementation | /doc/process-framework/tasks/../../../tasks/README.md |
| PF-TSK-051 | [/process-framework/tasks/04-implementation/data-layer-implementation.md](/process-framework/tasks/04-implementation/data-layer-implementation.md) | Documentation | Data Layer Implementation | /doc/process-framework/tasks/../../../tasks/README.md |
| PF-TSK-044 | [/process-framework/tasks/04-implementation/feature-implementation-planning-task.md](/process-framework/tasks/04-implementation/feature-implementation-planning-task.md) | Documentation | Feature Implementation Planning | /doc/process-framework/tasks/../../../tasks/README.md |

| PF-TSK-043 | [/process-framework/tasks/02-design/ui-ux-design-task.md](/process-framework/tasks/02-design/ui-ux-design-task.md) | Documentation | UI/UX Design Task | /doc/process-framework/tasks/../../../tasks/README.md |

| PF-TSK-29 | [/process-framework/tasks/03-testing/test-implementation-task.md](/process-framework/tasks/03-testing/test-implementation-task.md) | Documentation | Test Implementation | /doc/process-framework/tasks/README.md |
| PF-TSK-17 | [/process-framework/tasks/04-implementation/task-infrastructure-setup-task.md](/process-framework/tasks/04-implementation/task-infrastructure-setup-task.md) | Documentation | Task Infrastructure Setup | /doc/process-framework/tasks/README.mdd |
| PF-TSK-16 | [/process-framework/tasks/03-testing/test-specification-creation-task.md](/process-framework/tasks/03-testing/test-specification-creation-task.md) | Documentation | Test Specification Creation | /doc/process-framework/tasks/README.mdd |
Self-contained tasks with a clear beginning and end. These tasks are performed on-demand when needed and have specific triggers.

### Cyclical Tasks

Tasks that run on a periodic basis or in response to specific accumulations of work. These tasks have defined cycle frequencies and trigger events.

## Task Structure

All tasks follow a unified structure with these key sections:

- **Purpose & Context**: The goal of the task and why it's important
- **When to Use**: Specific situations when the task should be triggered
- **Context Requirements**: Prioritized list of files and information needed, organized by:
  - **Context Map**: Visual guide showing components relevant to the task and their relationships
  - **Critical (Must Read)**: Essential files for AI agent context window
  - **Important (Load If Space)**: Valuable but optional context
  - **Reference Only (Access When Needed)**: Files needed for specific operations
- **Process**: Divided into Preparation, Execution, and Finalization phases
- **Outputs**: What the task produces
- **State Tracking**: What tracking files need to be updated
- **Task Completion Checklist**: Mandatory steps before considering the task complete

## Maintaining This Documentation

As the project evolves, it's important to keep this documentation up-to-date:

1. When adding new documents, add them to this map
2. When moving documents, update all references to them
3. Periodically review all documents to ensure they remain relevant and accurate
4. Use the [Task: Tools Review](tasks/support/tools-review-task.md) process to collect and implement feedback

---

_This document is part of the Process Framework and serves as a central map of all documentation.
