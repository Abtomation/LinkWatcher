# AI Task-Based Development System

## Document Metadata

| Metadata      | Value                   |
| ------------- | ----------------------- |
| Document Type | Task System Entry Point |
| Created Date  | 2025-05-26              |
| Last Updated  | 2025-09-01              |
| Version       | 3.0                     |
| Status        | Active                  |

---

## 🚨 MANDATORY FIRST STEP: Choose Your Task

**🛑 STOP: You cannot proceed without selecting a task below. NO EXCEPTIONS.**

> **🎯 This project uses a TASK-BASED approach. Every piece of work must be done within a specific task framework and all documentation of this task must be read.**
>
> **⚠️ If no task fits your work, you MUST ask the human partner before proceeding.**

### Step 1: What are you working on?

```
Are you ADOPTING THE FRAMEWORK into an existing project?
├─ Yes → Start with [Codebase Feature Discovery](#codebase-feature-discovery)
│        Then → [Codebase Feature Analysis](#codebase-feature-analysis)
│        Then → [Retrospective Documentation Creation](#retrospective-documentation-creation)
│
├─ No → Are you working on a CHANGE REQUEST (new feature or enhancement)?
│  ├─ Yes → Do you need to research/discover what to build first?
│  │  ├─ Yes → Start with [Feature Discovery](#feature-discovery)
│  │  └─ No → Start with [Feature Request Evaluation](#feature-request-evaluation)
│  │           It classifies the request and routes to the correct next task:
│  │           ├─ New feature → [Feature Tier Assessment](#feature-tier-assessment) → Design → Implementation
│  │           └─ Enhancement → [Feature Enhancement](#feature-enhancement) (executes from state file)
│  │
│  ├─ No → Are you WORKING WITH BUGS?
│  │  ├─ Yes → What stage of bug management?
│  │  │  ├─ Discovered a bug during development → Use [Bug Triage](#bug-triage) (evaluate and prioritize)
│  │  │  ├─ Have a triaged bug to fix → Use [Bug Fixing](#bug-fixing)
│  │  │  └─ Need to systematically find bugs → Use testing tasks (Test Audit, Code Review)
│  │
│  ├─ No → Are you WORKING ON TECHNICAL DEBT or REFACTORING?
│  │  ├─ Yes → What stage of tech debt management?
│  │  │  ├─ Need to identify/assess tech debt → Use [Technical Debt Assessment](#technical-debt-assessment) (cyclical)
│  │  │  └─ Have assessed debt to fix → Use [Code Refactoring](#code-refactoring)
│  │
│  ├─ No → Are you REVIEWING CODE?
│  │  └─ Yes → Use [Code Review](#code-review)
│  │
│  ├─ No → Are you PREPARING A RELEASE?
│  │  └─ Yes → Use [Release & Deployment](#release--deployment)
│  │
│  ├─ No → Are you WORKING ON THE FRAMEWORK ITSELF?
│  │  └─ Yes → Use [Support Tasks](#support-tasks) (creating tasks, improving processes, changing structures, etc.)
│  │
│  └─ No → NONE OF THE ABOVE TASKS FIT?
│     └─ 🛑 **STOP: Ask your human partner before proceeding**
│        "No existing task fits this work. Should we proceed without a task template, or do we need to create a new task?"
```

### Step 2: Check for Ongoing Activities

These tasks run alongside your main work:

- 🔧 **Need to improve the framework?** → [Support Tasks](#support-tasks) (tools review, process improvement, etc.)

### Still Unsure?

> 💡 **When in doubt, ask your human partner!** This project is a collaboration between you and your human sparring partner. They can help clarify which task is most appropriate.

---

## 🚀 Quick Start Guide

**Once you've selected your task above, choose your path:**

| If you are...                          | Go to...                                                                      |
| -------------------------------------- | ----------------------------------------------------------------------------- |
| 🆕 **New to this project**             | [Understanding Task-Based Development](#understanding-task-based-development) |
| 📋 **Ready to start your chosen task** | [Task Definitions](#task-definitions)                                         |
| 📚 **Looking for specific resources**  | [Quick Reference Table](#quick-reference-table)                               |
| 🤝 **Need collaboration guidance**     | [Working with Your Human Partner](#working-with-your-human-partner)           |
| ❓ **Stuck or confused**               | [Troubleshooting](#troubleshooting)                                           |

---

## 📋 Task Definitions

### 🎓 00 - Onboarding Tasks

_Framework adoption and existing codebase documentation activities_

| Task                                     | Use When                                                                                | Complexity | Link                                                                                               |
| ---------------------------------------- | --------------------------------------------------------------------------------------- | ---------- | -------------------------------------------------------------------------------------------------- |
| **Codebase Feature Discovery**           | Adopting process framework into existing project - discover features and assign all code | 🟡 Medium  | [→ Definition](/doc/process-framework/tasks/00-onboarding/codebase-feature-discovery.md)           |
| **Codebase Feature Analysis**            | After feature discovery - analyze patterns, dependencies, and design decisions           | 🟡 Medium  | [→ Definition](/doc/process-framework/tasks/00-onboarding/codebase-feature-analysis.md)            |
| **Retrospective Documentation Creation** | After analysis - create tier assessments and required design documentation               | 🔴 Complex | [→ Definition](/doc/process-framework/tasks/00-onboarding/retrospective-documentation-creation.md) |

### 📋 01 - Planning Tasks

_Research, assessment, and architectural planning activities_

| Task                           | Use When                                                                                | Complexity | Link                                                                                     |
| ------------------------------ | --------------------------------------------------------------------------------------- | ---------- | ---------------------------------------------------------------------------------------- |
| **Feature Request Evaluation** | **ENTRY POINT for all change requests** — classifies as new feature or enhancement, routes to correct workflow. For new features: adds to tracking and routes to Feature Tier Assessment. For enhancements: creates scoped Enhancement State Tracking File | 🟡 Medium | [→ Definition](/doc/process-framework/tasks/01-planning/feature-request-evaluation.md) |
| **Feature Discovery**          | Planning new features through research and analysis                                     | 🟡 Medium  | [→ Definition](/doc/process-framework/tasks/01-planning/feature-discovery-task.md)       |
| **Feature Tier Assessment**    | New feature needs complexity evaluation                                                 | 🟢 Simple  | [→ Definition](/doc/process-framework/tasks/01-planning/feature-tier-assessment-task.md) |
| **System Architecture Review** | Evaluating how new features fit into existing system architecture before implementation | 🟡 Medium  | [→ Definition](/doc/process-framework/tasks/01-planning/system-architecture-review.md)   |

### 🎨 02 - Design Tasks

_Technical and functional design activities_

| Task                       | Use When                                                                                  | Complexity | Link                                                                                  |
| -------------------------- | ----------------------------------------------------------------------------------------- | ---------- | ------------------------------------------------------------------------------------- |
| **FDD Creation**           | Create functional specifications for Tier 2/3 features before technical design            | 🟡 Medium  | [→ Definition](/doc/process-framework/tasks/02-design/fdd-creation-task.md)           |
| **TDD Creation**           | Complex feature needs technical design                                                    | 🟡 Medium  | [→ Definition](/doc/process-framework/tasks/02-design/tdd-creation-task.md)           |
| **ADR Creation**           | Document significant architectural decisions with context, alternatives, and consequences | 🟢 Simple  | [→ Definition](/doc/process-framework/tasks/02-design/adr-creation-task.md)           |
| **API Design**             | Design comprehensive API contracts and specifications before implementation begins        | 🟡 Medium  | [→ Definition](/doc/process-framework/tasks/02-design/api-design-task.md)             |
| **Database Schema Design** | Plan data model changes before coding to prevent data integrity issues                    | 🟡 Medium  | [→ Definition](/doc/process-framework/tasks/02-design/database-schema-design-task.md) |

### 🧪 03 - Testing Tasks

_Test planning, implementation, and quality assurance activities_

| Task                            | Use When                                                                               | Complexity | Link                                                                                        |
| ------------------------------- | -------------------------------------------------------------------------------------- | ---------- | ------------------------------------------------------------------------------------------- |
| **E2E Acceptance Test Execution** | Execute E2E acceptance test cases systematically, record results, and report issues discovered through human interaction with the running system | 🟡 Medium | [→ Definition](/doc/process-framework/tasks/03-testing/e2e-acceptance-test-execution-task.md) |
| **E2E Acceptance Test Case Creation** | Create concrete, reproducible E2E acceptance test cases from test specifications with exact steps, file contents, and expected outcomes | 🟡 Medium | [→ Definition](/doc/process-framework/tasks/03-testing/e2e-acceptance-test-case-creation-task.md) |
| **Test Specification Creation** | Create comprehensive test specifications from TDDs for Test-First Development          | 🟡 Medium  | [→ Definition](/doc/process-framework/tasks/03-testing/test-specification-creation-task.md) |
| **Test Audit**                  | Quality assurance evaluation of implemented test suites against effectiveness criteria | 🟡 Medium  | [→ Definition](/doc/process-framework/tasks/03-testing/test-audit-task.md)                  |

### ⚙️ 04 - Implementation Tasks

_Feature development and coding activities_

| Task                                  | Use When                                                                                            | Complexity | Link                                                                                                     |
| ------------------------------------- | --------------------------------------------------------------------------------------------------- | ---------- | -------------------------------------------------------------------------------------------------------- |
| **Feature Enhancement** | Execute enhancement steps from the Enhancement State Tracking File, referencing existing task documentation for quality guidance, adapted to the amendment context | 🟡 Medium | [→ Definition](/doc/process-framework/tasks/04-implementation/feature-enhancement.md) |
| **Implementation Finalization** | Complete remaining items and prepare feature for production | 🟡 Medium | [→ Definition](/doc/process-framework/tasks/04-implementation/implementation-finalization.md) |
| **Quality Validation** | Validate implementation against quality standards and business requirements | 🟡 Medium | [→ Definition](/doc/process-framework/tasks/04-implementation/quality-validation.md) |
| **Integration and Testing** | Integrate components and establish comprehensive test coverage | 🟡 Medium | [→ Definition](/doc/process-framework/tasks/04-implementation/integration-and-testing.md) |
| **UI Implementation** | Build user interface components and layouts for feature | 🟡 Medium | [→ Definition](/doc/process-framework/tasks/04-implementation/ui-implementation.md) |
| **Feature Implementation Planning**   | Analyze design documentation and create detailed implementation plan with task sequencing           | 🟡 Medium  | [→ Definition](/doc/process-framework/tasks/04-implementation/feature-implementation-planning-task.md)   |
| **Data Layer Implementation**         | Implement data models, repositories, and database integration for feature                           | 🟡 Medium  | [→ Definition](/doc/process-framework/tasks/04-implementation/data-layer-implementation.md)              |
| **Foundation Feature Implementation** | Implementing foundation features (0.x.x) that provide architectural foundations for the application | 🔴 Complex | [→ Definition](/doc/process-framework/tasks/04-implementation/foundation-feature-implementation-task.md) |

### ✅ 05 - Validation Tasks

_Quality validation and compliance verification activities_

| Task                                         | Use When                                                                                                                                 | Complexity | Link                                                                                                   |
| -------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- | ---------- | ------------------------------------------------------------------------------------------------------ |
| **Validation Preparation**                   | **ENTRY POINT for validation rounds** — select features, evaluate dimension applicability, create tracking state file, plan session sequence | 🟢 Simple  | [→ Definition](/doc/process-framework/tasks/05-validation/validation-preparation.md)                   |
| **Architectural Consistency Validation**     | Validate selected features for architectural pattern adherence, ADR compliance, and interface consistency                            | 🟡 Medium  | [→ Definition](/doc/process-framework/tasks/05-validation/architectural-consistency-validation.md)     |
| **Code Quality Standards Validation**        | Validate selected features for code quality standards, SOLID principles, and best practices adherence                        | 🟡 Medium  | [→ Definition](/doc/process-framework/tasks/05-validation/code-quality-standards-validation.md)        |
| **Integration Dependencies Validation**      | Validate selected features for dependency health, interface contracts, and data flow integrity                                       | 🟡 Medium  | [→ Definition](/doc/process-framework/tasks/05-validation/integration-dependencies-validation.md)      |
| **Documentation Alignment Validation**       | Validate selected features for TDD alignment, ADR compliance, and API documentation accuracy                                         | 🟡 Medium  | [→ Definition](/doc/process-framework/tasks/05-validation/documentation-alignment-validation.md)       |
| **Extensibility Maintainability Validation** | Validate selected features for extension points, configuration flexibility, and testing support                                      | 🟡 Medium  | [→ Definition](/doc/process-framework/tasks/05-validation/extensibility-maintainability-validation.md) |
| **AI Agent Continuity Validation**           | Validate selected features for context clarity, modular structure, and documentation quality to support AI agent workflow continuity | 🟡 Medium  | [→ Definition](/doc/process-framework/tasks/05-validation/ai-agent-continuity-validation.md)           |
| **Security & Data Protection Validation**    | Validate selected features for security best practices, data protection, input validation, and secrets management | 🟡 Medium  | [→ Definition](/doc/process-framework/tasks/05-validation/security-data-protection-validation.md)      |
| **Performance & Scalability Validation**     | Validate selected features for performance characteristics, resource efficiency, and scalability patterns | 🟡 Medium  | [→ Definition](/doc/process-framework/tasks/05-validation/performance-scalability-validation.md)       |
| **Observability Validation**                 | Validate selected features for logging coverage, monitoring instrumentation, alerting readiness, and diagnostic traceability | 🟡 Medium  | [→ Definition](/doc/process-framework/tasks/05-validation/observability-validation.md)                 |
| **Accessibility / UX Compliance Validation** | Validate selected features for accessibility standards, UX compliance, keyboard navigation, and inclusive design patterns | 🟡 Medium  | [→ Definition](/doc/process-framework/tasks/05-validation/accessibility-ux-compliance-validation.md)   |
| **Data Integrity Validation**                | Validate selected features for data consistency, constraint enforcement, migration safety, and backup/recovery patterns | 🟡 Medium  | [→ Definition](/doc/process-framework/tasks/05-validation/data-integrity-validation.md)                |

### 🔧 06 - Maintenance Tasks

_Code maintenance, review, and bug management activities_

| Task                 | Use When                                                                                    | Complexity | Link                                                                                 |
| -------------------- | ------------------------------------------------------------------------------------------- | ---------- | ------------------------------------------------------------------------------------ |
| **Code Refactoring** | Systematic code improvement and technical debt reduction without changing external behavior | 🟡 Medium  | [→ Definition](/doc/process-framework/tasks/06-maintenance/code-refactoring-task.md) |
| **Code Review**      | Reviewing implemented code for quality                                                      | 🟢 Simple  | [→ Definition](/doc/process-framework/tasks/06-maintenance/code-review-task.md)      |
| **Bug Triage**       | Systematically evaluate, prioritize, and assign reported bugs                               | 🟢 Simple  | [→ Definition](/doc/process-framework/tasks/06-maintenance/bug-triage-task.md)       |
| **Bug Fixing**       | Implement fixes for triaged bugs with root cause analysis and regression prevention         | 🟡 Medium  | [→ Definition](/doc/process-framework/tasks/06-maintenance/bug-fixing-task.md)       |

### 🚀 07 - Deployment Tasks

_Release preparation and deployment activities_

| Task                     | Use When                         | Complexity | Link                                                                                  |
| ------------------------ | -------------------------------- | ---------- | ------------------------------------------------------------------------------------- |
| **Release & Deployment** | Preparing and deploying releases | 🔴 Complex | [→ Definition](/doc/process-framework/tasks/07-deployment/release-deployment-task.md) |

### 🔁 Cyclical Tasks

_Recurring activities triggered by events or schedules_

| Task                                    | Trigger                                               | Frequency           | Link                                                                                             |
| --------------------------------------- | ----------------------------------------------------- | ------------------- | ------------------------------------------------------------------------------------------------ |
| **Documentation Tier Adjustment**       | Complexity changes during implementation              | As needed           | [→ Definition](/doc/process-framework/tasks/cyclical/documentation-tier-adjustment-task.md)      |
| **Technical Debt Assessment**           | Periodic code quality review or before major releases | Quarterly/As needed | [→ Definition](/doc/process-framework/tasks/cyclical/technical-debt-assessment-task.md)          |

### 🔧 Support Tasks

_Meta-framework tasks that work on the process framework itself_

| Task                          | Type     | Use When                                                                         | Link                                                                              |
| ----------------------------- | -------- | -------------------------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| **Project Initiation** | Support | Initial project setup including project-config.json creation | [→ Definition](/doc/process-framework/tasks/support/project-initiation-task.md) |
| **New Task Creation Process** | Discrete | Creating new tasks for the framework                                             | [→ Definition](/doc/process-framework/tasks/support/new-task-creation-process.md) |
| **Process Improvement**       | Discrete | Enhancing development workflows                                                  | [→ Definition](/doc/process-framework/tasks/support/process-improvement-task.md)  |
| **Structure Change**          | Discrete | Reorganizing directory structures, file locations, or documentation architecture | [→ Definition](/doc/process-framework/tasks/support/structure-change-task.md)     |
| **Framework Extension Task**  | Support  | Adding new framework capabilities with multiple interconnected components        | [→ Definition](/doc/process-framework/tasks/support/framework-extension-task.md)  |
| **Tools Review**              | Cyclical | Evaluating and enhancing project tools                                           | [→ Definition](/doc/process-framework/tasks/support/tools-review-task.md)         |

---

## 🔄 Common Workflows

**📋 For detailed guidance on task transitions, see the [Task Transition Guide](/doc/process-framework/guides/framework/task-transition-guide.md)**

### For New Feature Planning (research needed)

```
Feature Discovery → Feature Request Evaluation (classify as new) → Feature Tier Assessment → FDD Creation → [System Architecture Review] → [ADR Creation] → [API Design] → [Database Schema Design] → TDD Creation → [Test Specification Creation] → Feature Implementation Planning → [Decomposed Implementation Tasks] → Code Review → Release & Deployment
```

### For Complex Features

```
Feature Request Evaluation (classify as new) → Feature Tier Assessment → FDD Creation → [System Architecture Review] → [ADR Creation] → [API Design] → [Database Schema Design] → TDD Creation → [Test Specification Creation] → Feature Implementation Planning → [Decomposed Implementation Tasks] → Integration & Testing → Test Audit → Code Review → Release & Deployment
```

### For Simple Features

```
Feature Request Evaluation (classify as new) → Feature Tier Assessment → Feature Implementation Planning (with lightweight design) → [Decomposed Implementation Tasks] → Code Review → Release & Deployment
```

### For Enhancements to Existing Features

```
Feature Request Evaluation (classify as enhancement + scope + create state file) → Feature Enhancement (execute steps from state file) → Code Review → Release & Deployment
```

### For Bug Fixes

```
Bug Fixing → Code Review → Release & Deployment
```

### For Technical Debt Reduction

```
[Technical Debt Assessment (if not yet assessed)] → Code Refactoring → Code Review → Release & Deployment
```

### For Documentation/Process Changes

```
Structure Change → Code Review → Release & Deployment
```

### For E2E Acceptance Testing (milestone-triggered)

```
After milestone (all features for a user workflow implemented):
  Cross-cutting E2E Test Specification (New-TestSpecification.ps1 -CrossCutting) → E2E Test Case Creation (PF-TSK-069) → E2E Test Execution (PF-TSK-070)
```

> **Milestone trigger**: Check [User Workflow Map](/doc/product-docs/technical/design/user-workflow-map.md) — when all required features for a workflow reach "Implemented," create the cross-cutting E2E test specification for that workflow.

### For Feature Validation

```
Validation Preparation (PF-TSK-077) → [Select features + dimensions] → Dimension Task(s) → Code Review → Release & Deployment
```

> **Entry point**: Always start with [Validation Preparation](/doc/process-framework/tasks/05-validation/validation-preparation.md) to select features, evaluate dimension applicability, and create tracking state file. See [Dimension Catalog](/doc/process-framework/guides/05-validation/feature-validation-guide.md#dimension-catalog) for the full list of 11 validation dimensions.

### Always Running

- **Tools Review** (when triggered)
- **Documentation Tier Adjustment** (when needed)
- **Technical Debt Assessment** (quarterly/as needed)
- **Code Refactoring** (when triggered by technical debt assessment)

---

## 🤝 Working with Your Human Partner

> **Key Principle**: This is a two-person collaboration - you (AI agent) and your human sparring partner. There is no larger team.

### 🎯 Core Collaboration Guidelines

| Situation                        | What to Do                               |
| -------------------------------- | ---------------------------------------- |
| **Important decisions**          | Always consult your human partner        |
| **Multiple approaches possible** | Present options with pros/cons           |
| **Requirements unclear**         | Ask clarifying questions                 |
| **Stuck on technical issues**    | Explain the problem and ask for guidance |
| **Unsure about task choice**     | Describe what you're working on and ask  |

### 💬 Communication Best Practices

- **Be specific**: "I'm implementing user authentication and need to decide between JWT and session-based auth"
- **Show your thinking**: "I see two approaches: A (faster to implement) vs B (more secure)"
- **Ask for priorities**: "Should I focus on speed or security for this feature?"
- **Provide context**: "This connects to the login system we built last week"

---

## 🏗️ Framework Infrastructure

### Process Framework Registry

| Resource                                                                                                    | Purpose                                                                                                  | Use When                                                                           |
| ----------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| [Process Framework Task Registry](/doc/process-framework/infrastructure/process-framework-task-registry.md) | Comprehensive catalog of all 32 tasks with automation status, script locations, and file update patterns | Understanding task capabilities, automation coverage, or coordination requirements |

**Key Features:**

- ✅ **Complete Task Coverage**: All categorized (01-planning through 07-deployment), cyclical, and support tasks
- ✅ **Automation Analysis**: 15+ tasks with scripts, 17+ requiring manual updates
- ✅ **Script Locations**: Exact paths to automation scripts and output directories
- ✅ **File Update Mapping**: What files each task creates and updates
- ✅ **Self-Maintaining**: Updated by New Task Creation Process

### 📚 Quick Reference Table

| Resource Type           | Resource                          | Purpose                                      | Link                                                                                                                                   |
| ----------------------- | --------------------------------- | -------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| **📋 Task Definitions** | All Categorized Tasks             | Complete task workflows and processes        | [↑ Task Definitions](#task-definitions)                                                                                                |
| **🔄 Workflows**        | Common Task Workflows             | Standard development workflows               | [↑ Common Workflows](#common-workflows)                                                                                                |
| **🏗️ Infrastructure**   | Process Framework Registry        | Complete task catalog with automation status | [Process Framework Task Registry](/doc/process-framework/infrastructure/process-framework-task-registry.md)                            |
| **📊 State Tracking**   | Feature Tracking                  | Track feature development status             | [Feature Tracking](/doc/process-framework/state-tracking/permanent/feature-tracking.md)                                                |
| **📊 State Tracking**   | Technical Debt Tracking           | Track technical debt items                   | [Technical Debt Tracking](/doc/process-framework/state-tracking/permanent/technical-debt-tracking.md)                                  |
| **📖 Templates**        | State File Template               | Create new tracking files                    | [State File Template](/doc/process-framework/templates/support/state-file-template.md)                                               |
| **🔧 Automation**       | Task Creation Script              | Create new framework tasks                   | [New Task Creation Process](/doc/process-framework/tasks/support/new-task-creation-process.md)                                         |
| **📝 Feedback**         | Feedback Process                  | Submit tool and task feedback                | [Feedback Process Guide](/doc/process-framework/feedback/README.md)                                                                    |
| **📝 Feedback**         | Feedback Flowchart                | Visual feedback process guide                | [Feedback Process Flowchart](/doc/process-framework/visualization/process-flows/feedback-process-flowchart.md)                                            |
| **🎯 Guides**           | Task Transition Guide             | Guidance on task transitions                 | [Task Transition Guide](/doc/process-framework/guides/framework/task-transition-guide.md)                                                 |
| **🎯 Guides**           | API Specification Creation        | How to create API specifications             | [API Specification Creation Guide](/doc/process-framework/guides/02-design/api-specification-creation-guide.md)                           |
| **🎯 Guides**           | API Data Model Creation           | How to create API data models                | [API Data Model Creation Guide](/doc/process-framework/guides/02-design/api-data-model-creation-guide.md)                                 |
| **🎯 Guides**           | Foundation Feature Implementation | Comprehensive implementation guidance        | [Foundation Feature Implementation Usage Guide](/doc/process-framework/guides/04-implementation/foundation-feature-implementation-usage-guide.md) |
| **🎯 Guides**           | Integration & Testing             | Comprehensive testing guidance               | [Integration & Testing Usage Guide](/doc/process-framework/guides/03-testing/test-implementation-usage-guide.md)                           |
| **🗺️ Context Maps**     | API Design Task Map               | Visual API design relationships              | [API Design Task Context Map](/doc/process-framework/visualization/context-maps/02-design/api-design-task-map.md)                      |
| **🔧 Support Tasks**    | Process Improvement               | Enhance development workflows                | [Process Improvement Task](/doc/process-framework/tasks/support/process-improvement-task.md)                                           |
| **🔧 Support Tasks**    | Structure Change                  | Reorganize framework structure               | [Structure Change Task](/doc/process-framework/tasks/support/structure-change-task.md)                                                 |
| **🔧 Support Tasks**    | Framework Extension               | Add new framework capabilities               | [Framework Extension Task](/doc/process-framework/tasks/support/framework-extension-task.md)                                           |
| **🔧 Support Tasks**    | Tools Review                      | Evaluate and enhance tools                   | [Tools Review Task](/doc/process-framework/tasks/support/tools-review-task.md)                                                         |

---

## 📚 Documentation Types & Purposes

Understanding the different types of documentation helps you choose the right resource for your needs:

### 📋 **Tasks** (WHAT to do and WHEN)

- **Purpose**: Define complete workflows and processes
- **Content**: Step-by-step instructions, context requirements, outputs, checklists
- **Use When**: You need to execute a specific development process
- **Example**: [API Design Task](/doc/process-framework/tasks/02-design/api-design-task.md)

### 🔧 **Creation Guides** (HOW to use the tools)

- **Purpose**: Detailed instructions for using specific tools and scripts
- **Content**: Script parameters, template customization, examples, troubleshooting
- **Use When**: You need to use a PowerShell script or customize a template
- **Examples**:
  - [API Specification Creation Guide](/doc/process-framework/guides/02-design/api-specification-creation-guide.md)
  - [API Data Model Creation Guide](/doc/process-framework/guides/02-design/api-data-model-creation-guide.md)

### 🗺️ **Context Maps** (Visual relationships)

- **Purpose**: Visual representation of component relationships and dependencies
- **Content**: Mermaid diagrams, component classifications, relationship explanations
- **Use When**: You need to understand how different components interact
- **Example**: [API Design Task Context Map](/doc/process-framework/visualization/context-maps/02-design/api-design-task-map.md)

### 📖 **Usage Guides** (Comprehensive how-to)

- **Purpose**: End-to-end guidance combining multiple tools and processes
- **Content**: Workflows, best practices, common pitfalls, advanced techniques
- **Use When**: You need comprehensive guidance beyond individual tasks
- **Examples**:
  - [Foundation Feature Implementation Usage Guide](/doc/process-framework/guides/04-implementation/foundation-feature-implementation-usage-guide.md)
  - [Integration & Testing Usage Guide](/doc/process-framework/guides/03-testing/test-implementation-usage-guide.md)

### 🎯 **Key Principle**: No Redundant Documentation

- **Tasks** should be self-contained with complete process information
- **Creation Guides** focus on tool usage, not process workflow
- **Context Maps** provide visual understanding, not step-by-step instructions
- **Usage Guides** only exist when combining multiple complex processes

> **💡 Tip**: Start with the **Task** for process workflow, then reference **Creation Guides** for tool usage and **Context Maps** for visual understanding.

---

## 📊 Project State & Tracking

### Current State Files

| File                                                                                                  | Purpose                          | Status    |
| ----------------------------------------------------------------------------------------------------- | -------------------------------- | --------- |
| [Feature Tracking](/doc/process-framework/state-tracking/permanent/feature-tracking.md)               | Track feature development status | ✅ Active |
| [Technical Debt Tracking](/doc/process-framework/state-tracking/permanent/technical-debt-tracking.md) | Track technical debt items       | ✅ Active |

### Creating New State Files

Need to track something new? Use the [State File Template](/doc/process-framework/templates/support/state-file-template.md) to create:

- Bug Tracking
- Release Status
- Documentation Status
- Process Improvement Tracking

### Information Management Rules

1. **Read only what you need** - Focus on files referenced in your current task
2. **Ask before exploring** - Don't dive deep into the codebase without direction
3. **Update state files** - Keep project status current as you work
4. **Document decisions** - Record important choices in appropriate state files

---

## 🤖 AI Agent Process Checklist

> **Critical Process Reminder**: Follow this checklist for every task to ensure complete execution

### BEFORE Starting Any Task:

1. ✅ **Read .ai-entry-point.md** and follow to AI Task-Based Development System
2. ✅ **Read the COMPLETE task definition** including completion checklist
3. ✅ **Adopt the assigned AI Agent Role** specified in the task definition for optimal task execution
4. ✅ **Understand ALL required outputs** (not just primary deliverables)
5. ✅ **Note feedback form requirements** BEFORE starting work

### DURING Task Execution:

6. ✅ **Follow the task process step-by-step** as documented
7. ✅ **Use required automation scripts** (never create files manually)
8. ✅ **If a script fails**: Report the error → diagnose and fix the script → re-run the fixed script. Never bypass a broken script by manually creating files — fix the script first.
9. ✅ **Update state files** as you progress through the work

### BEFORE Claiming Task Completion:

10. ✅ **Verify ALL outputs** from task definition are complete
11. ✅ **Complete ALL items** in the mandatory completion checklist
12. ✅ **Submit feedback forms** for all tools used during the task

> **🚨 Remember**: A task is NOT complete until the feedback forms are submitted!

---

## 🔧 System Details

### Tool Feedback Process

After completing any task, use our **hybrid feedback approach**:

1. **Create feedback form** using the automation script:

   ```powershell
   cd doc/process-framework/scripts/file-creation/support
   ./New-FeedbackForm.ps1 -DocumentId "PF-TSK-XXX" -TaskContext "Task Name" -FeedbackType "MultipleTools"
   ```

   **FeedbackType options**: `"SingleTool"`, `"MultipleTools"`, `"TaskLevel"` (also accepts `"Single Tool"`, `"Multiple Tools"`, `"Task-Level"`)

2. **Choose evaluation mode** in the enhanced template:

   - **Task-Level**: Evaluate overall process effectiveness
   - **Multiple Tools**: Rate each tool used (effectiveness, clarity, completeness, efficiency, **conciseness**)
   - **Single Tool**: Detailed evaluation of specific tool

3. **Critical focus on conciseness**: Every evaluation must assess if documentation contains only task-essential information

4. **Identify follow-up actions**: Mark tools scoring ≤3 for detailed feedback

**Files saved**: doc/process-framework/feedback/feedback-forms/YYYYMMDD-HHMMSS-TASK-ID-feedback.md (template format)

> ⚠️ **Important**: Use **TASK ID** (e.g., PF-TSK-002) in filename, NOT artifact IDs created during task
>
> 🎯 **Conciseness Focus**: Combat overdocumentation by evaluating information relevance
>
> 📈 **Why this matters**: Your feedback drives continuous improvement through the [Tools Review Task](/doc/process-framework/tasks/support/tools-review-task.md)
>
> 📋 **More details**: See the [Feedback Process Guide](/doc/process-framework/feedback/README.md)
>
> 🔄 **Visual guide**: See the [Feedback Process Flowchart](/doc/process-framework/visualization/process-flows/feedback-process-flowchart.md)

### Best Practices

- ✅ **🚨 READ TASK DEFINITION COMPLETELY** - Always read the entire task definition including completion checklist BEFORE starting work
- ✅ **📋 CHECK COMPLETION CHECKLIST FIRST** - Review the completion requirements before starting to understand the full scope
- ✅ **Start with the right task** - Use this guide to choose appropriately
- ✅ **Follow task processes** - Each task has specific steps for a reason
- ✅ **Use automation scripts** - ALWAYS use provided PowerShell scripts for file creation (never create assessment files manually)
- ✅ **Update state files** - Keep project status current
- ✅ **Focus on outputs** - Ensure you produce what the task expects
- ✅ **🚨 COMPLETE ALL TASK STEPS** - Every task has a mandatory completion checklist - tasks are NOT finished until feedback forms are completed
- ✅ **Involve your partner** - Collaborate on important decisions
- ✅ **Minimize documentation overhead** - Update state files rather than creating new docs
- ✅ **🔗 MAINTAIN DOCUMENT LINKS**:
  - **🚨 CRITICAL**: ALWAYS start LinkWatcher at session beginning: `LinkWatcher/start_linkwatcher_background.ps1`
  - **⚠️ IMPORTANT**: NEVER run LinkWatcher in foreground - it will block the session!
  - LinkWatcher automatically maintains all document references in real-time
  - Use any method to move/rename files - LinkWatcher handles all updates automatically

---

## ❓ Troubleshooting

| Problem                                | Solution                                                                                                                                        |
| -------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| **Can't decide which task to use**     | Use the [Task Selection Guide](#mandatory-first-step-choose-your-task) or ask your human partner                                                |
| **Task seems too big/complex**         | Break it down with your human partner                                                                                                           |
| **Missing information for task**       | Ask your human partner for specific files or context                                                                                            |
| **Task definition unclear**            | Check the full task definition or ask for clarification                                                                                         |
| **Need to work across multiple tasks** | Discuss the approach with your human partner                                                                                                    |
| **Process feels inefficient**          | Note it for the next [Process Improvement](#process-improvement) task                                                                           |
| **Broken document links**              | Ensure LinkWatcher is running in background (`LinkWatcher/start_linkwatcher_background.ps1`) - it prevents and fixes broken links automatically |
| **Session blocked/frozen**             | LinkWatcher running in foreground - kill process: `Get-Process python* \| Stop-Process -Force` then restart in background                       |
| **Need to rename or move files**       | Use any method (VS Code, File Explorer, git commands) - LinkWatcher updates all references automatically                                        |
| **Need to delete files**               | Use any method - LinkWatcher will detect and handle reference cleanup automatically                                                             |
| **LinkWatcher not working**            | Check if running: `Get-Process python*` - If not found, restart: `LinkWatcher/start_linkwatcher_background.ps1`                                 |

---

## 🧠 Understanding Task-Based Development

_New to this approach? This section explains the concepts behind the system._

### 🏗️ Task and State Management Principles

These foundational principles govern how the framework operates and ensure consistency across AI agent sessions:

#### Task Granularity

Each task is designed with a defined level of granularity such that it can be fully processed and completed within a single session with an AI agent. This ensures continuity and prevents loss of progress due to limited context windows.

#### State Tracking Files

A central state tracking file is used to represent the current state of the project. Each state entry defines:

- The current status of a process or component
- The next task to be executed
- Relevant links to artifacts (documents, outputs) produced by completed tasks, which often serve as inputs for subsequent tasks

#### Task Output and Status Updates

Each task must:

- Update the relevant status at least one of the state tracking file to reflect progress or completion
- In most cases, generate a new artifact (e.g., design doc, implementation spec), which is linked from the tracking file to ensure traceability and reuse.

#### Artifacts

**Artifact Sharing Principle:**
An artifact can be worked on by multiple tasks when the combined outputs from those tasks create a cohesive unit that future tasks need to reference together.

**Separate Artifact Principle:**
If a task's output serves a different purpose or has different relevance for future work than other task outputs, it should create its own separate artifact.

**Key Decision Factor:**
The determining factor is not how many tasks will use the artifact, but whether the content from different tasks logically belongs together as a unified reference for downstream work.

**Example:**

- Tier evaluation output is only relevant for TDD creation (specific, limited purpose)
- TDD creation produces a Technical Design Document needed by multiple subsequent tasks (broad, ongoing reference)
- Since tier evaluation reasoning and technical design serve different purposes for future tasks, they belong in separate artifacts
- Future implementation tasks need the technical design specifications, not the evaluation process that led to them

**Guiding Question:**
"Do the outputs from these tasks form a logical, cohesive unit that future tasks will reference together, or do they serve different purposes with different audiences?"

#### Task Handover

Handover between tasks — especially across AI agent sessions — is primarily managed through artifacts that are linked in the state tracking files. This file acts as a persistent source of truth, enabling seamless task continuation by capturing both progress and dependencies.

### What Is Task-Based Development?

Task-based development organizes work around specific, well-defined activities with:

- **Clear inputs** - What you start with
- **Defined process** - Step-by-step guidance
- **Expected outputs** - What you produce
- **State tracking** - How progress is recorded

### Why Use This Approach?

- 🎯 **Focus** - Work on one well-defined activity at a time
- 🔄 **Consistency** - Follow proven processes for each type of work
- 📝 **Documentation** - Maintain clear records of what's been done
- 🔗 **Continuity** - Track project state across development sessions
- ⚡ **Efficiency** - Minimize overhead while maintaining quality

### Task Types Explained

- **Discrete**: One-time activities with clear completion criteria
- **Cyclical**: Recurring activities triggered by events or schedules
- **Continuous**: Ongoing activities that happen alongside other work

### Self-Documenting Workflow

The framewor
