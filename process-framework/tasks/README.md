---
id: PF-TSK-000
type: Process Framework
Category: Task
version: 2.0
created: 2023-06-15
updated: 2025-05-27
---

# Development Tasks

This directory contains definitions for common development tasks in the project. The task-based approach provides a streamlined, self-documenting workflow that maintains project state through artifacts rather than explicit handover documentation.

## Purpose

The task-based approach helps to:

1. Streamline development by focusing on specific, well-defined activities
2. Ensure consistent processes across different sessions
3. Maintain clear documentation trails through task outputs
4. Optimize context by focusing only on relevant information for each task
5. Create clear boundaries between different types of work
6. Eliminate handover documentation through self-documenting artifacts

## Available Tasks

### 00 - Setup Tasks

| Task | Description | When to Use |
| ---- | ----------- | ----------- |
| [Codebase Feature Discovery](00-setup/codebase-feature-discovery.md) | Systematically discover all features in an existing codebase and assign every source file to at least one feature | When adopting the framework into an existing project |
| [Codebase Feature Analysis](00-setup/codebase-feature-analysis.md) | Analyze implementation patterns, dependencies, and design decisions for each discovered feature | After feature discovery |
| [Retrospective Documentation Creation](00-setup/retrospective-documentation-creation.md) | Create tier assessments and required design documentation for all analyzed features | After feature analysis |
| [Project Initiation](00-setup/project-initiation-task.md) | Initial project setup including project-config.json creation | When starting a new project |

### 01 - Planning Tasks

| Task | Description | When to Use |
| ---- | ----------- | ----------- |
| [Feature Request Evaluation](01-planning/feature-request-evaluation.md) | Classify incoming change requests as new features or enhancements to existing features | Entry point for all change requests |
| [Feature Tier Assessment](01-planning/feature-tier-assessment-task.md) | Assess the complexity tier of features | When new features need complexity assessment |
| [Feature Discovery](01-planning/feature-discovery-task.md) | Identify and document potential new features | When planning new features or exploring product opportunities |
| [System Architecture Review](01-planning/system-architecture-review.md) | Evaluate how new features fit into existing system architecture before implementation | Before implementing features with architectural impact |

### 02 - Design Tasks

| Task | Description | When to Use |
| ---- | ----------- | ----------- |
| [Integration Narrative Creation](02-design/integration-narrative-creation.md) | Create Integration Narratives for cross-feature workflows | When all workflow features reach Implemented status, or reactively during bug fixes requiring cross-feature understanding |
| [FDD Creation](02-design/fdd-creation-task.md) | Create Functional Design Documents for features requiring functional specification | When Tier 2+ features need functional design |
| [TDD Creation](02-design/tdd-creation-task.md) | Create Technical Design Documents | When assessed features need technical design |
| [ADR Creation](02-design/adr-creation-task.md) | Create Architecture Decision Records to document significant architectural decisions and their rationale | When documenting architectural decisions |
| [API Design Task](02-design/api-design-task.md) | Design comprehensive API contracts and specifications before implementation begins | When features require API contracts |
| [Database Schema Design Task](02-design/database-schema-design-task.md) | Systematic data model planning before implementation to prevent data integrity issues | When features require data model changes |

### 03 - Testing Tasks

| Task | Description | When to Use |
| ---- | ----------- | ----------- |
| [Performance Baseline Capture](03-testing/performance-baseline-capture-task.md) | Run performance tests, record results in trend database, update tracking, flag regressions | When working on Performance Baseline Capture |
| [Performance Test Creation](03-testing/performance-test-creation-task.md) | Implement performance tests from specifications, register in tracking, capture initial measurements | When working on Performance Test Creation |
| [Test Specification Creation](03-testing/test-specification-creation-task.md) | Create comprehensive test specifications from existing Technical Design Documents | When TDDs are ready for test planning |
| [E2E Acceptance Test Case Creation](03-testing/e2e-acceptance-test-case-creation-task.md) | Create concrete, reproducible E2E acceptance test cases from test specifications | When test specifications are ready for E2E cases |
| [E2E Acceptance Test Execution](03-testing/e2e-acceptance-test-execution-task.md) | Execute E2E acceptance test cases systematically, record results, and report issues | When E2E test cases are ready for execution |
| [Test Audit](03-testing/test-audit-task.md) | Quality assurance task for evaluating implemented test suites against effectiveness criteria | When evaluating test suite quality |

### 04 - Implementation Tasks

| Task | Description | When to Use |
| ---- | ----------- | ----------- |
| [Feature Implementation Planning](04-implementation/feature-implementation-planning-task.md) | Analyze design documentation and create detailed implementation plan with task sequencing | When features have completed TDDs |
| [Foundation Feature Implementation](04-implementation/foundation-feature-implementation-task.md) | Implement foundation features (0.x.x) that provide architectural foundations | When implementing foundation features |
| [Core Logic Implementation](04-implementation/core-logic-implementation.md) | Implement core business logic modules, wire integration points, and write unit tests | When implementing non-foundation features |
| [Data Layer Implementation](04-implementation/data-layer-implementation.md) | Implement data models, repositories, and database integration for feature | When implementing data layer components |
| [Integration and Testing](04-implementation/integration-and-testing.md) | Integrate components and establish comprehensive test coverage | When integrating components |
| [Quality Validation](04-implementation/quality-validation.md) | Validate implementation against quality standards and business requirements | When validating implementation quality |
| [Implementation Finalization](04-implementation/implementation-finalization.md) | Complete remaining items and prepare feature for production | When finalizing implementation |
| [Feature Enhancement](04-implementation/feature-enhancement.md) | Execute enhancement steps from the Enhancement State Tracking File | When enhancing existing features |

### 05 - Validation Tasks

| Task | Description | When to Use |
| ---- | ----------- | ----------- |
| [Validation Preparation](05-validation/validation-preparation.md) | Plan a validation round by selecting features and applicable dimensions | Entry point for validation rounds |
| [Architectural Consistency Validation](05-validation/architectural-consistency-validation.md) | Validate selected features for architectural pattern adherence, ADR compliance, and interface consistency | During validation rounds |
| [Code Quality Standards Validation](05-validation/code-quality-standards-validation.md) | Validate selected features for code quality standards, SOLID principles, and best practices adherence | During validation rounds |
| [Integration Dependencies Validation](05-validation/integration-dependencies-validation.md) | Validate selected features for dependency health, interface contracts, and data flow integrity | During validation rounds |
| [Documentation Alignment Validation](05-validation/documentation-alignment-validation.md) | Validate selected features for TDD alignment, ADR compliance, and API documentation accuracy | During validation rounds |
| [Extensibility Maintainability Validation](05-validation/extensibility-maintainability-validation.md) | Validate selected features for extension points, configuration flexibility, and testing support | During validation rounds |
| [AI Agent Continuity Validation](05-validation/ai-agent-continuity-validation.md) | Validate selected features for context clarity, modular structure, and documentation quality | During validation rounds |
| [Security Data Protection Validation](05-validation/security-data-protection-validation.md) | Validate selected features for security best practices, data protection, input validation | During validation rounds |
| [Performance Scalability Validation](05-validation/performance-scalability-validation.md) | Validate selected features for performance characteristics, resource efficiency, and scalability | During validation rounds |
| [Observability Validation](05-validation/observability-validation.md) | Validate selected features for logging coverage, monitoring instrumentation, and diagnostic traceability | During validation rounds |
| [Accessibility UX Compliance Validation](05-validation/accessibility-ux-compliance-validation.md) | Validate selected features for accessibility standards, UX compliance, and inclusive design patterns | During validation rounds |
| [Data Integrity Validation](05-validation/data-integrity-validation.md) | Validate selected features for data consistency, constraint enforcement, and backup/recovery patterns | During validation rounds |

### 06 - Maintenance Tasks

| Task | Description | When to Use |
| ---- | ----------- | ----------- |
| [Code Review](06-maintenance/code-review-task.md) | Review implemented code | When feature implementation is complete |
| [Code Refactoring Task](06-maintenance/code-refactoring-task.md) | Systematic code improvement and technical debt reduction without changing external behavior | When addressing assessed technical debt |
| [Bug Triage](06-maintenance/bug-triage-task.md) | Systematically evaluate, prioritize, and assign reported bugs | When new bugs need evaluation and prioritization |
| [Bug Fixing](06-maintenance/bug-fixing-task.md) | Fix reported bugs | When addressing issues in existing functionality |

### 07 - Deployment Tasks

| Task | Description | When to Use |
| ---- | ----------- | ----------- |
| [Git Commit and Push](07-deployment/git-commit-and-push.md) | Commit current working directory changes and push to remote repository | When working on Git Commit and Push |
| [Release & Deployment](07-deployment/release-deployment-task.md) | Manage releases and deployments | When preparing and deploying releases |
| [User Documentation Creation](07-deployment/user-documentation-creation.md) | Create or update user-facing product documentation | When features introduce or change user-visible behavior |

### Cyclical Tasks

| Task | Description | When to Use |
| ---- | ----------- | ----------- |
| [Documentation Tier Adjustment](cyclical/documentation-tier-adjustment-task.md) | Adjust documentation tiers during implementation | When actual complexity differs from assessment |
| [Technical Debt Assessment](cyclical/technical-debt-assessment-task.md) | Systematic approach to identifying, categorizing, and prioritizing technical debt | Quarterly or as needed |

### Support Tasks

| Task | Description | When to Use |
| ---- | ----------- | ----------- |
| [New Task Creation Process](support/new-task-creation-process.md) | Complete process for creating new tasks | When the framework needs a new task definition |
| [Process Improvement](support/process-improvement-task.md) | Implement specific process improvements | When a process needs enhancement |
| [Structure Change](support/structure-change-task.md) | Manage systematic changes to documentation structures | When updating templates or document structures |
| [Framework Extension Task](support/framework-extension-task.md) | Fundamentally extend the framework with new capabilities | When adding new framework functionalities |
| [Tools Review](support/tools-review-task.md) | Review and improve development tools | After completing 5 tasks or monthly |
| [Framework Evaluation](support/framework-evaluation.md) | Evaluate the process framework for completeness, consistency, and effectiveness | When assessing framework quality |

## Task Structure

Each task is defined with the following sections:

1. **Task Metadata**: Version information and creation dates
2. **Purpose**: What the task accomplishes
3. **When to Use**: Specific scenarios where this task is appropriate
4. **Inputs**: Files and information needed to complete the task
5. **Process**: Step-by-step guidance for completing the task
6. **Outputs**: Files and changes produced by the task
7. **State Tracking**: How project state files are updated
8. **Next Tasks**: Tasks that typically follow this one
9. **Task Completion**: Steps to complete before finishing the task, including feedback collection

Additional sections for specific task types:

- **Cycle Frequency** (Cyclical): How often the task should be performed
- **Trigger Events** (Cyclical): What events trigger this task
- **Metrics and Evaluation** (Cyclical): How to measure task effectiveness
- **Continuous Improvement** (Cyclical): How to improve the task over time

## Feedback Collection

At the end of each task, feedback should be collected on the tools used during the task:

1. **Create Feedback Form**: Use the [feedback form template](../templates/support/feedback-form-template.md)
2. **Evaluate Tools**: Rate and provide comments on each tool's effectiveness, clarity, completeness, and efficiency
3. **Suggest Improvements**: Document what worked well and what could be improved
4. **Save Feedback**: Store the feedback form (artifact) in the `/process-framework-local/feedback/feedback-forms` directory with the naming convention `YYYYMMDD-HHMMSS-document-id-feedback.md`

> **Important**: Feedback forms are artifacts (using ART-FEE-XXX IDs), not documents. They evaluate documents (with [PREFIX]-XXX-XXX IDs).

This feedback is essential for the continuous improvement of project tools and processes. The [Tools Review Task](support/tools-review-task.md) uses this feedback to identify and implement improvements.

## Self-Documenting Workflow

Tasks in this system are designed to be self-documenting through their outputs:

1. Each task produces concrete artifacts (documents, code, etc.)
2. State tracking files (like feature-tracking.md) maintain the project status
3. The next task can determine what to work on by examining the state files
4. No explicit handover documentation is needed between sessions

## State Tracking

State tracking is a core component of the task-based approach:

1. **State Files**: Located in `/process-framework-local/state-tracking` directory
2. **Consistent Updates**: Each task must update relevant state files
3. **Project Status**: State files reflect the current project status
4. **Task Transitions**: State files guide transitions between tasks

## Creating New Tasks

To create a new task:

1. Use the [task template](../templates/support/task-template.md)
2. Place the task in the appropriate workflow phase subdirectory
4. Focus on a specific, well-defined activity
5. Include clear guidance on context, process, and outputs
6. Ensure state tracking is properly defined
7. Add the task to this index

For detailed guidance on creating and improving tasks, refer to the [Task Creation and Improvement Guide](../guides/support/task-creation-guide.md).

## Task Flow

Tasks naturally flow from one to another based on their inputs and outputs:

1. **Feature Discovery** → **Feature Tier Assessment** → **TDD Creation** → **Test Specification Creation** → **Feature Implementation** → **Code Review**
2. **Bug Fixing** can occur at any point when issues are identified
3. **Cyclical Tasks** are triggered by events or schedules and integrate with the main workflow
4. **Support Tasks** are used to improve the framework itself

For a complete understanding of task relationships, refer to the state tracking files that show the current status of all project elements.
