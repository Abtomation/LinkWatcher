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

## Task Types

Tasks are organized into four categories based on their nature and frequency:

### Setup Tasks

Framework adoption tasks for bringing an existing project into the process framework. These tasks systematically discover, analyze, and document an existing codebase.

### Discrete Tasks

One-time activities with clear start and end points. These tasks are performed sequentially and have specific completion criteria.

### Cyclical Tasks

Recurring activities that follow a defined cycle. These tasks are performed at regular intervals or triggered by specific events.

### Support Tasks

Meta-framework tasks that work on the process framework itself, such as creating new tasks, improving processes, or changing structures.

## Available Tasks

### Setup Tasks

| Task | Description | When to Use |
| ---- | ----------- | ----------- |
| [User Documentation Creation](07-deployment/user-documentation-creation.md) | Create or update user-facing product documentation when features introduce or change user-visible behavior | When working on User Documentation Creation |
| [Framework Evaluation](support/framework-evaluation.md) | Structurally evaluate the process framework or specific parts of it for completeness, consistency, redundancy, accuracy, effectiveness, automation coverage, and scalability | When working on Framework Evaluation |
| [Core Logic Implementation](04-implementation/core-logic-implementation.md) | Implement core business logic modules, wire integration points, and write unit tests for non-foundation features after Feature Implementation Planning | When working on Core Logic Implementation |
| [Validation Preparation](05-validation/validation-preparation.md) | Plan a validation round by selecting features and applicable dimensions, then create the tracking state file | When working on Validation Preparation |
| [Data Integrity Validation](05-validation/data-integrity-validation.md) | Validate selected features for data consistency, constraint enforcement, migration safety, and backup/recovery patterns | When working on Data Integrity Validation |
| [Accessibility UX Compliance Validation](05-validation/accessibility-ux-compliance-validation.md) | Validate selected features for accessibility standards, UX compliance, keyboard navigation, and inclusive design patterns | When working on Accessibility UX Compliance Validation |
| [Observability Validation](05-validation/observability-validation.md) | Validate selected features for logging coverage, monitoring instrumentation, alerting readiness, and diagnostic traceability | When working on Observability Validation |
| [Performance Scalability Validation](05-validation/performance-scalability-validation.md) | Validate selected features for performance characteristics, resource efficiency, and scalability patterns | When working on Performance Scalability Validation |
| [Security Data Protection Validation](05-validation/security-data-protection-validation.md) | Validate selected features for security best practices, data protection, input validation, and secrets management | When working on Security Data Protection Validation |
| [Manual Test Execution](03-testing/e2e-acceptance-test-execution-task.md) | Execute manual test cases systematically, record results, and report issues discovered through human interaction with the running system | When working on Manual Test Execution |
| [Manual Test Case Creation](03-testing/e2e-acceptance-test-case-creation-task.md) | Create concrete, reproducible manual test cases from test specifications with exact steps, file contents, and expected outcomes | When working on Manual Test Case Creation |
| [Feature Enhancement](04-implementation/feature-enhancement.md) | Execute enhancement steps from the Enhancement State Tracking File, referencing existing task documentation for quality guidance, adapted to the amendment context | When working on Feature Enhancement |
| [Feature Request Evaluation](01-planning/feature-request-evaluation.md) | Classify incoming change requests as new features or enhancements to existing features, and for enhancements create a scoped Enhancement State Tracking File | When working on Feature Request Evaluation |
| [Retrospective Documentation Creation](00-setup/retrospective-documentation-creation.md) | Create tier assessments and required design documentation for all analyzed features | When working on Retrospective Documentation Creation |
| [Codebase Feature Analysis](00-setup/codebase-feature-analysis.md) | Analyze implementation patterns, dependencies, and design decisions for each discovered feature | When working on Codebase Feature Analysis |
| [Codebase Feature Discovery](00-setup/codebase-feature-discovery.md) | Systematically discover all features in an existing codebase and assign every source file to at least one feature | When working on Codebase Feature Discovery |

### Discrete Tasks

| Task                                                                                                  | Description                                                                                                                                        | When to Use                                               |
| ----------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------- |
|[Project Initiation](00-setup/project-initiation-task.md) | Initial project setup including project-config.json creation | When working on Project Initiation |
| [Implementation Finalization](04-implementation/implementation-finalization.md) | Complete remaining items and prepare feature for production | When working on Implementation Finalization |
| [Quality Validation](04-implementation/quality-validation.md) | Validate implementation against quality standards and business requirements | When working on Quality Validation |
| [Integration and Testing](04-implementation/integration-and-testing.md) | Integrate components and establish comprehensive test coverage | When working on Integration and Testing |
| [Data Layer Implementation](04-implementation/data-layer-implementation.md) | Implement data models, repositories, and database integration for feature | When working on Data Layer Implementation |
| [Feature Implementation Planning](04-implementation/feature-implementation-planning-task.md) | Analyze design documentation and create detailed implementation plan with task sequencing and dependency mapping | When working on Feature Implementation Planning |
| [AI Agent Continuity Validation](05-validation/ai-agent-continuity-validation.md)                     | Validate selected features for context clarity, modular structure, and documentation quality to support AI agent workflow continuity           | When working on AI Agent Continuity Validation            |
| [Extensibility Maintainability Validation](05-validation/extensibility-maintainability-validation.md) | Validate selected features for extension points, configuration flexibility, and testing support                                                | When working on Extensibility Maintainability Validation  |
| [Documentation Alignment Validation](05-validation/documentation-alignment-validation.md)             | Validate selected features for TDD alignment, ADR compliance, and API documentation accuracy                                                   | When working on Documentation Alignment Validation        |
| [Integration Dependencies Validation](05-validation/integration-dependencies-validation.md)           | Validate selected features for dependency health, interface contracts, and data flow integrity                                                 | When working on Integration Dependencies Validation       |
| [Code Quality Standards Validation](05-validation/code-quality-standards-validation.md)               | Validate selected features for code quality standards, SOLID principles, and best practices adherence                                 | When working on Code Quality Standards Validation         |
| [Architectural Consistency Validation](05-validation/architectural-consistency-validation.md)         | Validate selected features for architectural pattern adherence, ADR compliance, and interface consistency across the codebase                 | When working on Architectural Consistency Validation      |
| [Test Audit](03-testing/test-audit-task.md)                                                           | Quality assurance task for evaluating implemented test suites against effectiveness criteria                                                       | When working on Test Audit                                |
| [ADR Creation](02-design/adr-creation-task.md)                                                        | Create Architecture Decision Records to document significant architectural decisions and their rationale                                           | When working on ADR Creation                              |
| [FDD Creation](02-design/fdd-creation-task.md)                                                        | Create Functional Design Documents for features requiring functional specification                                                                 | When working on FDD Creation                              |
| [Foundation Feature Implementation Task](04-implementation/foundation-feature-implementation-task.md) | Specialized task for implementing foundation features (0.x.x) that provide architectural foundations for the application                           | When working on Foundation Feature Implementation Task    |
| [Technical Debt Assessment Task](cyclical/technical-debt-assessment-task.md)                          | Systematic approach to identifying, categorizing, and prioritizing technical debt across the codebase                                              | When working on Technical Debt Assessment Task            |
| [Code Refactoring Task](06-maintenance/code-refactoring-task.md)                                      | Systematic code improvement and technical debt reduction without changing external behavior                                                        | When working on Code Refactoring Task                     |
| [Database Schema Design Task](02-design/database-schema-design-task.md)                               | Systematic data model planning before implementation to prevent data integrity issues, migration problems, and architectural inconsistencies       | When working on Database Schema Design Task               |
| [API Design Task](02-design/api-design-task.md)                                                       | Design comprehensive API contracts and specifications before implementation begins, ensuring consistent interfaces and proper integration patterns | When working on API Design Task                           |
| [System Architecture Review](01-planning/system-architecture-review.md)                               | Task for evaluating how new features fit into existing system architecture before implementation                                                   | When working on System Architecture Review                |

| [Test Specification Creation](03-testing/test-specification-creation-task.md) | Create comprehensive test specifications from existing Technical Design Documents to enable Test-First Development Integration approach | When working on Test Specification Creation |
| [Feature Tier Assessment](01-planning/feature-tier-assessment-task.md) | Assess the complexity tier of features | When new features need complexity assessment |
| [TDD Creation](02-design/tdd-creation-task.md) | Create Technical Design Documents | When assessed features need technical design |
| [Feature Implementation Planning](04-implementation/feature-implementation-planning-task.md) | Plan and execute feature implementation using decomposed tasks | When features have completed TDDs |
| [Code Review](06-maintenance/code-review-task.md) | Review implemented code | When feature implementation is complete |

| [Bug Triage](06-maintenance/bug-triage-task.md) | Systematically evaluate, prioritize, and assign reported bugs | When new bugs need evaluation and prioritization |
| [Bug Fixing](06-maintenance/bug-fixing-task.md) | Fix reported bugs | When addressing issues in existing functionality |
| [Release & Deployment](07-deployment/release-deployment-task.md) | Manage releases and deployments | When preparing and deploying releases |
| [Process Improvement](support/process-improvement-task.md) | Implement specific process improvements | When a process needs enhancement |
| [Structure Change](support/structure-change-task.md) | Manage systematic changes to documentation structures | When updating templates or document structures |
| [Feature Discovery](01-planning/feature-discovery-task.md) | Identify and document potential new features | When planning new features or exploring product opportunities |

### Cyclical Tasks

| Task                                                                            | Description                                      | When to Use                                    |
| ------------------------------------------------------------------------------- | ------------------------------------------------ | ---------------------------------------------- |
| [Tools Review](support/tools-review-task.md)                                    | Review and improve development tools             | After completing 5 tasks or monthly            |
| [Documentation Tier Adjustment](cyclical/documentation-tier-adjustment-task.md) | Adjust documentation tiers during implementation | When actual complexity differs from assessment |

## Task Structure

Each task is defined with the following sections:

1. **Task Metadata**: Version information, task type, and creation dates
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
4. **Save Feedback**: Store the feedback form (artifact) in the `/doc/process-framework/feedback/feedback-forms` directory with the naming convention `YYYYMMDD-HHMMSS-document-id-feedback.md`

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

1. **State Files**: Located in `/doc/process-framework/state-tracking/` directory
2. **Consistent Updates**: Each task must update relevant state files
3. **Project Status**: State files reflect the current project status
4. **Task Transitions**: State files guide transitions between tasks

## Creating New Tasks

To create a new task:

1. Determine the appropriate task type (Discrete, Cyclical, Continuous, or Support)
2. Use the [task template](../templates/support/task-template.md)
3. Place the task in the appropriate subdirectory
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
