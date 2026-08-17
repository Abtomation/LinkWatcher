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

<!-- BEGIN GENERATED: task-catalog -->
### 00 - Setup Tasks

| Task | Description |
| ---- | ----------- |
| [Codebase Feature Analysis](00-setup/codebase-feature-analysis.md) | Analyze implementation patterns, dependencies, and design decisions |
| [Codebase Feature Discovery](00-setup/codebase-feature-discovery.md) | Discover all features in existing codebase and assign every source file |
| [Codebase Source Migration](00-setup/codebase-source-migration-task.md) | Relocate legacy source into the scaffolded per-feature src/ directories during onboarding, file-by-file, with behavior-preserving per-item verification |
| [Project Initiation](00-setup/project-initiation-task.md) | Initial project setup including ../doc/project-config.json creation |
| [Retrospective Documentation Creation](00-setup/retrospective-documentation-creation.md) | Create tier assessments and required design documentation |

### 01 - Planning Tasks

| Task | Description |
| ---- | ----------- |
| [Feature Discovery](01-planning/feature-discovery-task.md) | Identify and document potential new features |
| [Feature Request Evaluation](01-planning/feature-request-evaluation.md) | Classify change requests as new features or enhancements, assess new-feature complexity tier, scope enhancements, and create Enhancement State Tracking Files |
| [System Architecture Review](01-planning/system-architecture-review.md) | Evaluate how new features fit into existing system architecture before implementation |
| [Technical Exploration](01-planning/technical-exploration-task.md) | Execute a technical exploration spike: bounded research that must resolve before a feature can proceed to design/implementation |

### 02 - Design Tasks

| Task | Description |
| ---- | ----------- |
| [API Design Task](02-design/api-design-task.md) | Design comprehensive API contracts and specifications before implementation begins |
| [Database Schema Design Task](02-design/database-schema-design-task.md) | Plan data model changes before coding to prevent data integrity issues |
| [FDD Creation](02-design/fdd-creation-task.md) | Create Functional Design Documents for Tier 2+ features |
| [Instruction Design](02-design/instruction-design-task.md) | Design the instruction-medium parts of a feature: the executable procedure, its artifact inventory with declared kinds, its instruction contract, and its verification plan, captured as a PD-IND design document |
| [Integration Narrative Creation](02-design/integration-narrative-creation.md) | Create Integration Narratives explaining how 2+ features collaborate in cross-cutting workflows |
| [Technical Design Document (TDD) Creation](02-design/tdd-creation-task.md) | Create Technical Design Documents |
| [UI Design](02-design/ui-design-task.md) | Systematic UI/UX design planning before implementation: translate functional requirements into wireframes, visual specifications, component definitions, accessibility requirements, and platform adaptations as a PD-UIX design document. |

### 03 - Testing Tasks

| Task | Description |
| ---- | ----------- |
| [E2E Acceptance Test Case Creation](03-testing/e2e-acceptance-test-case-creation-task.md) | Create concrete, reproducible E2E acceptance test cases from test specifications with exact steps, file contents, and expected outcomes |
| [E2E Acceptance Test Execution](03-testing/e2e-acceptance-test-execution-task.md) | Execute E2E acceptance test cases systematically, record results, and report issues through human interaction with the running system |
| [Performance & E2E Test Scoping](03-testing/performance-and-e2e-test-scoping-task.md) | Identify per-feature performance and E2E test needs after code review |
| [Performance Baseline Capture](03-testing/performance-baseline-capture-task.md) | Run performance tests, record results in trend database, update tracking, flag regressions |
| [Performance Test Creation](03-testing/performance-test-creation-task.md) | Implement performance tests from specifications, register in tracking, capture initial measurements |
| [Test Audit](03-testing/test-audit-task.md) | Systematic quality assessment of test implementations using six evaluation criteria |
| [Test Specification Creation](03-testing/test-specification-creation-task.md) | Create comprehensive test specifications from TDDs |

### 04 - Implementation Tasks

| Task | Description |
| ---- | ----------- |
| [Core Logic Implementation](04-implementation/core-logic-implementation.md) | General-purpose coding task for non-foundation features: create modules, wire integration points, write tracked unit tests |
| [Data Layer Implementation](04-implementation/data-layer-implementation.md) | Implement data models, repositories, and database integration for feature |
| [Feature Enhancement](04-implementation/feature-enhancement.md) | Execute enhancement steps from Enhancement State Tracking File, adapting existing task guidance to amendment context |
| [Feature Implementation Planning Task](04-implementation/feature-implementation-planning-task.md) | Analyze design documentation and create detailed implementation plan with task sequencing and dependency mapping |
| [Foundation Feature Implementation Task](04-implementation/foundation-feature-implementation-task.md) | Implement foundation features (0.x.x) that provide architectural foundations for the application |
| [Implementation Finalization](04-implementation/implementation-finalization.md) | Complete remaining items and close out the feature |
| [Integration and Testing](04-implementation/integration-and-testing.md) | Integrate components and establish comprehensive test coverage |
| [State Management Implementation](04-implementation/state-management-implementation.md) | Implement state management layer connecting data layer to UI layer |
| [UI Implementation](04-implementation/ui-implementation.md) | Build user interface components and layouts for feature |

### 05 - Validation Tasks

| Task | Description |
| ---- | ----------- |
| [Dimension Validation](05-validation/dimension-validation-task.md) | Execute a single validation dimension against selected features using the shared validation process plus the dimension's path file. |
| [Validation Preparation](05-validation/validation-preparation.md) | Plan validation rounds by selecting features and applicable dimensions, create tracking state file |

### 06 - Maintenance Tasks

| Task | Description |
| ---- | ----------- |
| [Bug Fixing](06-maintenance/bug-fixing-task.md) | Diagnose and fix bugs |
| [Bug Triage](06-maintenance/bug-triage-task.md) | Systematically evaluate, prioritize, and assign reported bugs |
| [Code Refactoring Task](06-maintenance/code-refactoring-task.md) | Systematic code improvement and technical debt reduction without changing external behavior |
| [Code Review](06-maintenance/code-review-task.md) | Review code for quality and correctness |

### 07 - Deployment Tasks

| Task | Description |
| ---- | ----------- |
| [Git Commit and Push](07-deployment/git-commit-and-push.md) | Commit work in the current working directory and push it — a session's own paths (Mode A) or the uncommitted remainder (Mode B) |
| [Release & Deployment](07-deployment/release-deployment-task.md) | Manage releases and deployments |
| [User Documentation Creation](07-deployment/user-documentation-creation.md) | Feature introduces or changes user-visible behavior and needs handbook/quick-reference/README updates |

### Cyclical Tasks

| Task | Description |
| ---- | ----------- |
| [Documentation Tier Adjustment Task](cyclical/documentation-tier-adjustment-task.md) | Adjust documentation requirements |
| [Technical Debt Assessment Task](cyclical/technical-debt-assessment-task.md) | Systematic approach to identifying, categorizing, and prioritizing technical debt across the codebase |

### Support Tasks

| Task | Description |
| ---- | ----------- |
| [Framework Domain Adaptation](support/framework-domain-adaptation.md) | Systematically adapt the process framework from one business domain to another while preserving core structure |
| [Framework Evaluation](support/framework-evaluation.md) | Structurally evaluate the process framework for completeness, consistency, redundancy, accuracy, effectiveness, automation coverage, and scalability |
| [Framework Extension Task](support/framework-extension-task.md) | Support task for fundamentally extending the framework with new functionalities and capabilities |
| [Framework Rollout](support/framework-rollout-task.md) | Deploy framework code from a producer face's canonical blueprint tree to its registered children. |
| [IMP Triage](support/imp-triage-task.md) | Sort raw IMPs from the Intake section into Improvements / Extensions / Structural Changes / Active Pilots / Rejected. |
| [New Task Creation Process](support/new-task-creation-process.md) | Complete process for creating new tasks from concept to implementation-ready definition |
| [Process Improvement](support/process-improvement-task.md) | Improve development processes |
| [Structure Change Task](support/structure-change-task.md) | Manage structural changes to documentation |
| [Tools Review Task](support/tools-review-task.md) | Review and improve project tools and templates |
<!-- END GENERATED: task-catalog -->

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
2. **Evaluate Tools**: Rate and provide comments on each tool across all five dimensions: effectiveness, clarity, completeness, efficiency, and conciseness
3. **Suggest Improvements**: Document what worked well and what could be improved
4. **Save Feedback**: Store the feedback form (artifact) in the `appdev/process-framework-central/feedback/feedback-forms/` directory with the naming convention `YYYYMMDD-HHMMSS_<PRJ-ID>_PF-TSK-XXX_feedback.md`

> **Important**: Feedback forms are artifacts (using PF-FEE-XXX IDs), not documents. They evaluate documents (with [PREFIX]-XXX-XXX IDs).

This feedback is essential for the continuous improvement of project tools and processes. The [Tools Review Task](support/tools-review-task.md) uses this feedback to identify and implement improvements.

## Self-Documenting Workflow

Tasks in this system are designed to be self-documenting through their outputs:

1. Each task produces concrete artifacts (documents, code, etc.)
2. State tracking files (like feature-tracking.md) maintain the project status
3. The next task can determine what to work on by examining the state files
4. No explicit handover documentation is needed between sessions

## State Tracking

State tracking is a core component of the task-based approach:

1. **State Files**: Located in `doc/state-tracking` (project-local) and `appdev/process-framework-central/state-tracking/` (cross-project)
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

For detailed guidance on creating and improving tasks, apply the [`task-creation` craft skill](../../.claude/skills/task-creation/SKILL.md).

## Task Flow

Tasks naturally flow from one to another based on their inputs and outputs:

1. **Feature Discovery** → **Feature Request Evaluation** (assess tier) → **TDD Creation** → **Test Specification Creation** → **Feature Implementation** → **Code Review**
2. **Bug Fixing** can occur at any point when issues are identified
3. **Cyclical Tasks** are triggered by events or schedules and integrate with the main workflow
4. **Support Tasks** are used to improve the framework itself

For a complete understanding of task relationships, refer to the state tracking files that show the current status of all project elements.
