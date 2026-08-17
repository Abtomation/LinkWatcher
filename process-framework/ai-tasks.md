# AI Task-Based Development System

## Document Metadata

| Metadata      | Value                   |
| ------------- | ----------------------- |
| Document Type | Task System Entry Point |
| Created Date  | 2025-05-26              |
| Last Updated  | 2026-06-12              |
| Version       | 3.3                     |
| Status        | Active                  |

---

## Choosing Your Task

> You run every task under the [Task Execution Protocol](guides/framework/task-execution-protocol-guide.md) — selecting a task is its first step (do not begin work without one). This page is the **task catalog** the protocol selects from: how to choose is below, then the task table.

### How to Choose a Task

The human partner tells you what to work on. Your job is to map that instruction to the right task:

1. **Establish what the request refers to and where that work currently stands** — then select the task that owns the next step.
2. **Scan the Use When column** in the [Task Definitions table](#task-definitions) below. Each task's Use When description includes example trigger phrasings — match against the human's wording (literal or semantic).
3. **If the instruction could route to either framework or product path**, consult the [Framework Path vs. Product Path Disambiguation](#framework-path-vs-product-path-disambiguation) note below.
4. **Read the matched task's full definition** including its completion checklist before starting work.
5. **If no task's Use When matches**, stop and ask the human partner — do not invent a task or proceed without a framework.

### Framework Path vs. Product Path Disambiguation

When the human's instruction could route to either path, this disambiguation applies:

- **Framework path** = anything under `process-framework/` or root-level routing files (`CLAUDE.md`, `MEMORY.md`, `ai-tasks.md`). Phase 5/7 (post-2026-05-11): the legacy `process-framework-local/` directory has been eliminated — project-local framework state lives under `doc/state-tracking/` (state files, PF-STA/PF-TMP registries) and the project's `logs/linkwatcher/` (LinkWatcher runtime); cross-project framework state (IMP tracking, feedback, proposals, evaluation reports) lives in `appdev/process-framework-central/` resolved via the project's `.framework-central-pointer`.
- **Product path** = everything else (`src/`, `test/`, `doc/`, `README.md`, etc.).

**Policy (absolute, no escalation)**: Work targeting the framework path routes through Support Tasks only. PF-TSK-022 (Code Refactoring), PF-TSK-007 (Bug Fixing), and PF-TSK-005 (Code Review) are for product code only — even when the framework work is shaped like a refactor, a bug fix, or a code review.

> **Filing a discovered issue (not selecting a task)?** This same framework/product boundary decides where a discovered problem is *filed* — product bug, feature request, framework improvement (IMP), or technical debt. See the [Issue Classification and Routing Guide](guides/framework/issue-classification-and-routing-guide.md).

> **Why framework code refactors live in PF-TSK-009 and not PF-TSK-022**: PF-TSK-022 prescribes pytest baselines, characterization tests via `New-TestFile.ps1`, TDD/FDD/ADR alignment, audit-flagged TD closure — all product-shaped artifacts that don't apply to framework scripts. PF-TSK-009's execute-changes step (medium-risk path) is the right home: agent runs a synthetic PowerShell harness against real state files (happy / error / defect-specific cases), records pre-fix and post-fix counts in IMP completion notes.

### Ongoing Activity Chains

These task chains span multiple sessions — each link is its own task selection, triggered by the prior link's output:

- 🔧 **Framework feedback chain** (Phase 7 workflow, post-2026-05-11): [Tools Review (PF-TSK-010)](#tools-review) collects feedback forms and writes raw IMPs into the central **Section 1 — Intake** → [IMP Triage (PF-TSK-089)](#imp-triage) sorts Intake into destination sections (Improvements / Extensions / Structural Changes / Active Pilots / Rejected) → owning task ([Process Improvement (PF-TSK-009)](#process-improvement) / [Structure Change (PF-TSK-014)](#structure-change) / [Framework Extension Task (PF-TSK-026)](#framework-extension-task)) implements.

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

### 🎓 00 - Setup Tasks

_Project setup, framework adoption, and existing codebase documentation activities_

<!-- BEGIN GENERATED: task-table:00-setup -->
| Task | Use When | Complexity | Link |
| ---- | -------- | ---------- | ---- |
| **Codebase Feature Analysis** | After feature discovery - analyze patterns, dependencies, and design decisions | 🟡 Medium | [→ Definition](tasks/00-setup/codebase-feature-analysis.md) |
| **Codebase Feature Discovery** | Adopting process framework into existing project - discover features and assign all code. Triggers: 'onboard the codebase', 'adopt the framework', 'discover features in existing code'. | 🟡 Medium | [→ Definition](tasks/00-setup/codebase-feature-discovery.md) |
| **Codebase Source Migration** | Relocate legacy source into the scaffolded per-feature src/ directories during onboarding, file-by-file, with behavior-preserving per-item verification | 🟡 Medium | [→ Definition](tasks/00-setup/codebase-source-migration-task.md) |
| **Project Initiation** | Starting a new project or adapting the process framework to a new domain | 🟡 Medium | [→ Definition](tasks/00-setup/project-initiation-task.md) |
| **Retrospective Documentation Creation** | After analysis - validate tier assessments and create required design documentation (FDD, TDD, ADRs) for Tier 2+ features | 🔴 Complex | [→ Definition](tasks/00-setup/retrospective-documentation-creation.md) |
<!-- END GENERATED: task-table:00-setup -->

### 📋 01 - Planning Tasks

_Research, assessment, and architectural planning activities_

<!-- BEGIN GENERATED: task-table:01-planning -->
| Task | Use When | Complexity | Link |
| ---- | -------- | ---------- | ---- |
| **Feature Discovery** | Planning new features through research and analysis | 🟡 Medium | [→ Definition](tasks/01-planning/feature-discovery-task.md) |
| **Feature Request Evaluation** | **ENTRY POINT for all change requests** — classifies as new feature or enhancement, routes to correct workflow. For new features: adds to tracking, assesses the complexity tier inline (embedded procedure), and creates the tier-correct implementation state file. For enhancements: creates scoped Enhancement State Tracking File. Triggers: 'new feature request', 'classify this change request', 'scope this enhancement'. | 🟡 Medium | [→ Definition](tasks/01-planning/feature-request-evaluation.md) |
| **System Architecture Review** | Evaluating how new features fit into existing system architecture before implementation | 🟡 Medium | [→ Definition](tasks/01-planning/system-architecture-review.md) |
| **Technical Exploration** | Execute a queued technical exploration spike — a bounded research investigation that must resolve before a feature's design or implementation can proceed. Produces a findings document and resolves the exploration tracker row. | 🟡 Medium | [→ Definition](tasks/01-planning/technical-exploration-task.md) |
<!-- END GENERATED: task-table:01-planning -->

### 🎨 02 - Design Tasks

_Technical and functional design activities_

<!-- BEGIN GENERATED: task-table:02-design -->
| Task | Use When | Complexity | Link |
| ---- | -------- | ---------- | ---- |
| **API Design Task** | Design comprehensive API contracts and specifications before implementation begins | 🟡 Medium | [→ Definition](tasks/02-design/api-design-task.md) |
| **Database Schema Design Task** | Plan data model changes before coding to prevent data integrity issues | 🟡 Medium | [→ Definition](tasks/02-design/database-schema-design-task.md) |
| **FDD Creation** | Create functional specifications for Tier 2/3 features before technical design. Triggers: 'create FDD', 'write functional design', 'document feature X functionally'. | 🟡 Medium | [→ Definition](tasks/02-design/fdd-creation-task.md) |
| **Instruction Design** | Create the instruction design for a feature whose deliverable includes instruction artifacts an agent executes. Triggers: 'create the instruction design', 'design the instructions for feature X', 'spec the procedure'. | 🟡 Medium | [→ Definition](tasks/02-design/instruction-design-task.md) |
| **Integration Narrative Creation** | Create Integration Narratives for cross-feature workflows | 🟡 Medium | [→ Definition](tasks/02-design/integration-narrative-creation.md) |
| **Technical Design Document (TDD) Creation** | Complex feature needs technical design. Triggers: 'create TDD', 'write technical design', 'design feature X technically'. | 🟡 Medium | [→ Definition](tasks/02-design/tdd-creation-task.md) |
| **UI Design** | Create UI/UX design specifications: wireframes, visual specs, component definitions, accessibility requirements, platform adaptations as a PD-UIX design document. Triggers: 'create UI design', 'design the UI for feature X', 'spec the screens'. | 🟡 Medium | [→ Definition](tasks/02-design/ui-design-task.md) |
<!-- END GENERATED: task-table:02-design -->

### 🧪 03 - Testing Tasks

_Test planning, implementation, and quality assurance activities_

<!-- BEGIN GENERATED: task-table:03-testing -->
| Task | Use When | Complexity | Link |
| ---- | -------- | ---------- | ---- |
| **E2E Acceptance Test Case Creation** | Create concrete, reproducible E2E acceptance test cases from test specifications with exact steps, file contents, and expected outcomes. Triggers: 'create e2e test case', 'write acceptance test', 'add E2E test for workflow X'. | 🟡 Medium | [→ Definition](tasks/03-testing/e2e-acceptance-test-case-creation-task.md) |
| **E2E Acceptance Test Execution** | Execute E2E acceptance test cases systematically, record results, and report issues discovered through human interaction with the running system. Triggers: 'run e2e tests', 'execute acceptance tests', 'do the E2E for workflow X'. | 🟡 Medium | [→ Definition](tasks/03-testing/e2e-acceptance-test-execution-task.md) |
| **Performance & E2E Test Scoping** | Identify per-feature performance and E2E test needs after code review | 🟡 Medium | [→ Definition](tasks/03-testing/performance-and-e2e-test-scoping-task.md) |
| **Performance Baseline Capture** | Run performance tests, record results in trend database, update tracking, flag regressions | 🟢 Simple | [→ Definition](tasks/03-testing/performance-baseline-capture-task.md) |
| **Performance Test Creation** | Implement performance tests from specifications, register in tracking, capture initial measurements | 🟡 Medium | [→ Definition](tasks/03-testing/performance-test-creation-task.md) |
| **Test Audit** | Quality assurance evaluation of implemented test suites against effectiveness criteria. Triggers: 'audit the tests', 'review test quality', 'audit e2e/perf/unit tests'. | 🟡 Medium | [→ Definition](tasks/03-testing/test-audit-task.md) |
| **Test Specification Creation** | Create automated test specifications from TDDs for Test-First Development. Triggers: 'create test spec', 'write test specification', 'spec the tests for feature X'. | 🟡 Medium | [→ Definition](tasks/03-testing/test-specification-creation-task.md) |
<!-- END GENERATED: task-table:03-testing -->

### ⚙️ 04 - Implementation Tasks

_Feature development and coding activities_

<!-- BEGIN GENERATED: task-table:04-implementation -->
| Task | Use When | Complexity | Link |
| ---- | -------- | ---------- | ---- |
| **Core Logic Implementation** | General-purpose coding task for non-foundation features: create modules, wire integration points, write tracked unit tests | 🟡 Medium | [→ Definition](tasks/04-implementation/core-logic-implementation.md) |
| **Data Layer Implementation** | Implement data models, repositories, and database integration for feature | 🟡 Medium | [→ Definition](tasks/04-implementation/data-layer-implementation.md) |
| **Feature Enhancement** | Execute enhancement steps from the Enhancement State Tracking File, referencing existing task documentation for quality guidance, adapted to the amendment context | 🟡 Medium | [→ Definition](tasks/04-implementation/feature-enhancement.md) |
| **Feature Implementation Planning Task** | Analyze design documentation and create detailed implementation plan with task sequencing | 🟡 Medium | [→ Definition](tasks/04-implementation/feature-implementation-planning-task.md) |
| **Foundation Feature Implementation Task** | Implementing foundation features (0.x.x) that provide architectural foundations for the application | 🔴 Complex | [→ Definition](tasks/04-implementation/foundation-feature-implementation-task.md) |
| **Implementation Finalization** | Complete remaining items and close out the feature | 🟡 Medium | [→ Definition](tasks/04-implementation/implementation-finalization.md) |
| **Integration and Testing** | Integrate components and establish comprehensive test coverage | 🟡 Medium | [→ Definition](tasks/04-implementation/integration-and-testing.md) |
| **State Management Implementation** | Implement state management layer connecting data layer to UI layer | 🟡 Medium | [→ Definition](tasks/04-implementation/state-management-implementation.md) |
| **UI Implementation** | Build user interface components and layouts for feature | 🟡 Medium | [→ Definition](tasks/04-implementation/ui-implementation.md) |
<!-- END GENERATED: task-table:04-implementation -->

### ✅ 05 - Validation Tasks

_Quality validation and compliance verification activities_

<!-- BEGIN GENERATED: task-table:05-validation -->
| Task | Use When | Complexity | Link |
| ---- | -------- | ---------- | ---- |
| **Dimension Validation** | Execute one validation dimension (security, performance, code quality, architectural consistency, etc.) against selected features after Validation Preparation; the dimension's path file supplies the specialized role, analysis steps, and criteria. Triggers: 'run the security validation', 'validate code quality', 'do the architectural-consistency dimension'. | 🟡 Medium | [→ Definition](tasks/05-validation/dimension-validation-task.md) |
| **Validation Preparation** | **ENTRY POINT for validation rounds** — select features, evaluate dimension applicability, create tracking state file, plan session sequence. Triggers: 'start a validation round', 'plan validation', 'prepare for validation'. | 🟢 Simple | [→ Definition](tasks/05-validation/validation-preparation.md) |
<!-- END GENERATED: task-table:05-validation -->

### 🔧 06 - Maintenance Tasks

_Code maintenance, review, and bug management activities_

<!-- BEGIN GENERATED: task-table:06-maintenance -->
| Task | Use When | Complexity | Link |
| ---- | -------- | ---------- | ---- |
| **Bug Fixing** | Implement fixes for triaged product bugs with root cause analysis and regression prevention. Triggers: 'fix this bug', 'resolve issue X', 'fix the bug from PD-BUG-NNN' (product code only). | 🟡 Medium | [→ Definition](tasks/06-maintenance/bug-fixing-task.md) |
| **Bug Triage** | Systematically evaluate, prioritize, and assign reported product bugs. Triggers: 'triage this bug', 'evaluate bug report X', 'prioritize the bug backlog' (product code only — framework defects are filed as IMPs and fixed via Process Improvement). | 🟢 Simple | [→ Definition](tasks/06-maintenance/bug-triage-task.md) |
| **Code Refactoring Task** | Systematic product-code improvement and technical debt reduction without changing external behavior. Does **NOT** cover building comprehensive test suites for new features (unit / component / integration / e2e) — route to [Integration & Testing](tasks/04-implementation/integration-and-testing.md) (PF-TSK-053). Triggers: 'refactor X', 'reduce tech debt in module Y', 'clean up Z' (product code only — framework refactors go to Process Improvement). | 🟡 Medium | [→ Definition](tasks/06-maintenance/code-refactoring-task.md) |
| **Code Review** | Reviewing implemented product code for quality. Triggers: 'review the code', 'do a code review', 'check this PR' (product code only — framework changes are reviewed inline at Process Improvement's decision-review checkpoint). | 🟢 Simple | [→ Definition](tasks/06-maintenance/code-review-task.md) |
<!-- END GENERATED: task-table:06-maintenance -->

### 🚀 07 - Deployment Tasks

_Release preparation and deployment activities_

<!-- BEGIN GENERATED: task-table:07-deployment -->
| Task | Use When | Complexity | Link |
| ---- | -------- | ---------- | ---- |
| **Git Commit and Push** | Committing and pushing from the current working directory, on the human's request, in one of two modes. **Mode A — Session Commit**: stage the explicit paths a body of work touched. **Mode B — Remainder Sweep**: commit whatever uncommitted work is left in the tree. Triggers: 'commit my changes', 'commit and push', 'commit the rest', 'sweep the uncommitted work'. | 🟢 Simple | [→ Definition](tasks/07-deployment/git-commit-and-push.md) |
| **Release & Deployment** | Preparing and deploying releases. Runs the agnostic release gates, then **delegates project-specific deploy/version/distribute mechanics to the project's Release Process Guide** (`doc/ci-cd/release-process.md`) and gates on that guide's freshness. | 🔴 Complex | [→ Definition](tasks/07-deployment/release-deployment-task.md) |
| **User Documentation Creation** | Feature introduces or changes user-visible behavior and needs handbook/quick-reference/README updates | 🟡 Medium | [→ Definition](tasks/07-deployment/user-documentation-creation.md) |
<!-- END GENERATED: task-table:07-deployment -->

### 🔁 Cyclical Tasks

_Recurring activities triggered by events or schedules_

<!-- BEGIN GENERATED: task-table:cyclical -->
| Task | Trigger | Frequency | Link |
| ---- | ------- | --------- | ---- |
| **Documentation Tier Adjustment Task** | Complexity changes during implementation | As needed | [→ Definition](tasks/cyclical/documentation-tier-adjustment-task.md) |
| **Technical Debt Assessment Task** | Periodic code quality review or before major releases | Quarterly/As needed | [→ Definition](tasks/cyclical/technical-debt-assessment-task.md) |
<!-- END GENERATED: task-table:cyclical -->

### 🔧 Support Tasks

_Meta-framework tasks that work on the process framework itself_

<!-- BEGIN GENERATED: task-table:support -->
| Task | Use When | Link |
| ---- | -------- | ---- |
| **Framework Domain Adaptation** | Migrating the process framework to a different business domain while preserving core structure | [→ Definition](tasks/support/framework-domain-adaptation.md) |
| **Framework Evaluation** | Structurally evaluate the process framework or specific parts of it for completeness, consistency, redundancy, accuracy, effectiveness, automation coverage, and scalability. Triggers: 'evaluate the framework', 'audit the framework', 'review framework area X'. | [→ Definition](tasks/support/framework-evaluation.md) |
| **Framework Extension Task** | Adding new framework capabilities with multiple interconnected components (multi-phase, multi-session). Triggers: 'start framework extension X', 'continue the centralized framework management extension', 'work on phase N of extension Y'. | [→ Definition](tasks/support/framework-extension-task.md) |
| **Framework Rollout** | Deploy framework code from a producer face's canonical blueprint tree to its registered children. Phase 1 (cwd=producer root): commit + tag the producer repo, push to its remote, mirror the payload-filtered framework tree to the targets. Phase 2 (cwd=Project): apply per-project working-doc migrations from the central pending-migrations ledger. Triggers: 'push framework to project X', 'roll out framework update', 'rollback framework version', 'register new project'. | [→ Definition](tasks/support/framework-rollout-task.md) |
| **IMP Triage** | Sort raw IMPs from the Intake section into Improvements / Extensions / Structural Changes / Active Pilots / Rejected. Detect duplicate-topic clusters across open sections and consolidate them into new Extension IMPs. Triggers: 'triage the IMP intake', 'drain the intake', 'sort the incoming IMPs'. | [→ Definition](tasks/support/imp-triage-task.md) |
| **New Task Creation Process** | Creating new tasks for the framework. Triggers: 'create a new task', 'add a task definition', 'we need a task for X'. | [→ Definition](tasks/support/new-task-creation-process.md) |
| **Process Improvement** | Enhancing existing framework artifacts: content edits to tasks/guides/templates, behavior-preserving script refactors, defect fixes. Triggers: 'improve task X', 'fix script Y', 'update guide Z', 'implement IMP-NNN' (only IMPs whose tracking row carries Resp Task blank or PF-TSK-009 — for any other Resp Task value, that column names the owning task; check the row before selecting). | [→ Definition](tasks/support/process-improvement-task.md) |
| **Structure Change Task** | Reorganizing directory structures, file locations, or documentation architecture. Triggers: 'reorganize directory X', 'move files from A to B', 'restructure docs', 'rename X to Y'. | [→ Definition](tasks/support/structure-change-task.md) |
| **Tools Review Task** | Periodic review of feedback forms accumulated since last review — extract findings, file raw IMPs into central Intake. Triggers: 'do tools review', 'review feedback forms', 'process the feedback backlog'. | [→ Definition](tasks/support/tools-review-task.md) |
<!-- END GENERATED: task-table:support -->

---

## 🔄 Common Workflows

**📋 For detailed guidance on task transitions, see the [Task Transition Registry](infrastructure/task-transition-registry.md)**

### For New Feature Planning (research needed)

```
Feature Discovery → [Technical Exploration] → Feature Request Evaluation (classify as new, assess tier) → FDD Creation → [System Architecture Review] → [Database Schema Design] → [API Design] → [UI Design] → [Instruction Design] → TDD Creation → [Test Specification Creation] → Feature Implementation Planning → [Decomposed Implementation Tasks] → Code Review → Performance & E2E Test Scoping (PF-TSK-086) → [User Documentation Creation] → Release & Deployment
```

> **Optional exploration step**: Feature Discovery (step 15) files open research questions — "which booking engine?", "is this integration feasible?" — into [Technical Exploration Tracking](../doc/state-tracking/permanent/technical-exploration-tracking.md) as `📥 Queued` rows. [Technical Exploration](tasks/01-planning/technical-exploration-task.md) (PF-TSK-093) runs each spike and produces a findings document before the dependent design proceeds. The step is **conditional** — most features need no spike. It also applies **later in the chain**: when a question blocks a feature that already has a row, Feature Request Evaluation diverts it to `🔬 Needs Technical Exploration` and the exploration returns it to its pipeline status once resolved (divert-and-return, like `🔄 Needs Enhancement`).

### For Complex Features

```
Feature Request Evaluation (classify as new, assess tier) → FDD Creation → [System Architecture Review] → [Database Schema Design] → [API Design] → [UI Design] → [Instruction Design] → TDD Creation → [Test Specification Creation] → Feature Implementation Planning → [Decomposed Implementation Tasks] → Integration & Testing → Test Audit → Code Review → Performance & E2E Test Scoping (PF-TSK-086) → [User Documentation Creation] → Release & Deployment
```

### For Simple Features

```
Feature Request Evaluation (classify as new, assess tier + create lightweight state file) → Feature Implementation Planning (with lightweight design) → [Decomposed Implementation Tasks] → Code Review → Performance & E2E Test Scoping (PF-TSK-086) → [User Documentation Creation] → Release & Deployment
```

### For Enhancements to Existing Features

```
Feature Request Evaluation (classify as enhancement + scope + create state file) → Feature Enhancement (execute steps from state file) → Code Review → Performance & E2E Test Scoping (PF-TSK-086) → [User Documentation Creation] → Release & Deployment
```

### For Framework Adoption (existing project)

```
Project Initiation (project-config.json + source-code-layout.md) → Codebase Feature Discovery (discover + tier assessment + state files + code inventory) → Codebase Source Migration (relocate legacy code into src/<feature>/, file-by-file with verification) → Codebase Feature Analysis (enrich state files) → Retrospective Documentation Creation (FDD/TDD/ADR for Tier 2+)
```

> **Prerequisite**: [Project Initiation](tasks/00-setup/project-initiation-task.md) runs first even for an existing codebase — it creates `project-config.json` and `source-code-layout.md`, which Codebase Feature Discovery's source-structure step (Step 7.f) consumes (directory creation is intentionally deferred from Project Initiation to Discovery).
>
> **Note**: Tier assessment and state file creation happen within Codebase Feature Discovery (Step 10). The assessed tier determines whether the lightweight (Tier 1) or full (Tier 2/3) state file template is used.
>
> **Source relocation**: Discovery scaffolds empty `src/<feature>/` directories and assigns every file to an owning feature but leaves the code in place; [Codebase Source Migration](tasks/00-setup/codebase-source-migration-task.md) moves it in afterward — one file at a time, rewriting references both directions and verifying behavior against a per-file baseline — so Analysis operates on code already in its final locations.

### For Greenfield Projects (Architecture-First)

```
Project Initiation → [Feature Request Evaluation (classify + assess tier) → [ADR Creation] → TDD Creation → Foundation Feature Implementation] (repeat for each 0.x feature) → then use standard workflows above for business features (1.x+)
```

> **When to use**: For new projects that need architectural foundations (0.x features) before business features. The 0.x foundation category is an opt-in decision made during [Project Initiation](tasks/00-setup/project-initiation-task.md). Complete all foundation features first — business feature workflows (Simple/Complex/Enhancement above) depend on the architectural patterns established by 0.x features.

### For Bug Fixes

```
M/L-scope: Bug Fixing → Code Review → Release & Deployment
S-scope quick path: Bug Fixing (with inline triage + self-review) → Release & Deployment
```

> **L-scope architectural fixes**: The AI agent may route to Performance & E2E Test Scoping (PF-TSK-086) after Code Review if the fix changes feature behavior significantly.

### For Technical Debt Reduction

```
[Technical Debt Assessment (if not yet assessed)] → Code Refactoring → Code Review → Performance & E2E Test Scoping (PF-TSK-086) → Release & Deployment
```

### For Documentation/Process Changes

```
Structure Change → Code Review → Release & Deployment
```

> **Note**: Documentation/process changes don't go through Performance & E2E Test Scoping since they don't affect product code.

### For E2E Acceptance Testing (milestone-triggered)

```
Performance & E2E Test Scoping (PF-TSK-086) identifies workflow as E2E-ready →
  [Integration Narrative Creation (PF-TSK-083)] → Cross-cutting E2E Test Specification (New-TestSpecification.ps1 -CrossCutting) → E2E Test Case Creation (PF-TSK-069) → Test Audit (PF-TSK-030, -TestType E2E) → E2E Test Execution (PF-TSK-070)
```

> **Milestone trigger**: The [Performance & E2E Test Scoping task (PF-TSK-086)](tasks/03-testing/performance-and-e2e-test-scoping-task.md) checks [User Workflow Tracking](../doc/state-tracking/permanent/user-workflow-tracking.md) after each feature passes code review. When all required features for a workflow are implemented, the scoping task adds a milestone entry to e2e-test-tracking.md. Create the Integration Narrative first (provides verified cross-feature understanding), then the cross-cutting E2E test specification.
>
> **Audit gate**: Newly created E2E test cases must pass Test Audit (`✅ Audit Approved`) before execution. Test cases marked `🔄 Needs Re-execution` are exempt (already audited).

### For Performance Testing

```
Performance & E2E Test Scoping (PF-TSK-086) identifies perf tests needed →
  Performance Test Creation (PF-TSK-084) → Test Audit (PF-TSK-030, -TestType Performance) → Performance Baseline Capture (PF-TSK-085)
```

> **Trigger**: The [Performance & E2E Test Scoping task (PF-TSK-086)](tasks/03-testing/performance-and-e2e-test-scoping-task.md) applies the [decision matrix](../.claude/skills/perf-e2e-scoping/SKILL.md#performance-test-decision-matrix) (`perf-e2e-scoping` craft skill) after code review and adds `⬜ Needs Creation` entries to performance-test-tracking.md. Performance Test Creation implements tests from those entries; Baseline Capture records results and detects regressions. Baseline Capture also runs standalone for pre-release verification and post-refactoring checks.
>
> **Audit gate**: Newly created performance tests must pass Test Audit (`✅ Audit Approved`) before baseline capture. Tests marked `⚠️ Needs Re-baseline` are exempt (already audited).

### For Feature Validation

```
Validation Preparation (PF-TSK-077) → [Select features + dimensions] → Dimension Task(s) → Code Review → Release & Deployment
```

> **Entry point**: Always start with [Validation Preparation](tasks/05-validation/validation-preparation.md) to select features, evaluate dimension applicability, and create tracking state file. See [Dimension Catalog](guides/05-validation/feature-validation-guide.md#dimension-catalog) for the full list of 11 validation dimensions.

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
| [Process Framework Task Registry](infrastructure/process-framework-task-registry.md) | Comprehensive catalog of all 32 tasks with automation status, script locations, and file update patterns | Understanding task capabilities, automation coverage, or coordination requirements |

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
| **🏗️ Infrastructure**   | Process Framework Registry        | Complete task catalog with automation status | [Process Framework Task Registry](infrastructure/process-framework-task-registry.md)                            |
| **📊 State Tracking**   | Feature Tracking                  | Track feature development status             | [Feature Tracking](../doc/state-tracking/permanent/feature-tracking.md)                                                |
| **📊 State Tracking**   | Feature Request Tracking          | Intake queue for product feature requests    | [Feature Request Tracking](../doc/state-tracking/permanent/feature-request-tracking.md)                                |
| **📊 State Tracking**   | Technical Debt Tracking           | Track technical debt items                   | [Technical Debt Tracking](../doc/state-tracking/permanent/technical-debt-tracking.md)                                  |
| **📖 Templates**        | State File Template               | Create new tracking files                    | [State File Template](templates/support/state-file-template.md)                                               |
| **🔧 Automation**       | Task Creation Script              | Create new framework tasks                   | [New Task Creation Process](tasks/support/new-task-creation-process.md)                                         |
| **📝 Feedback**         | Feedback Process                  | Submit tool and task feedback                | [Feedback Process Guide](../process-framework-central/feedback/archive/README.md)                                                            |
| **📝 Feedback**         | Feedback Flowchart                | Visual feedback process guide                | [Feedback Process Flowchart](visualization/process-flows/feedback-process-flowchart.md)                                            |
| **🎯 Guides**           | Task Transition Guide             | Guidance on task transitions                 | [Task Transition Registry](infrastructure/task-transition-registry.md)                                                 |
| **🎯 Guides**           | API Design Craft                  | API spec + data model customization craft    | [`api-design` craft skill](../.claude/skills/api-design/SKILL.md)                                                  |
| **🔧 Support Tasks**    | Process Improvement               | Enhance development workflows                | [Process Improvement Task](tasks/support/process-improvement-task.md)                                           |
| **🔧 Support Tasks**    | Structure Change                  | Reorganize framework structure               | [Structure Change Task](tasks/support/structure-change-task.md)                                                 |
| **🔧 Support Tasks**    | Framework Extension               | Add new framework capabilities               | [Framework Extension Task](tasks/support/framework-extension-task.md)                                           |
| **🔧 Support Tasks**    | Tools Review                      | Evaluate and enhance tools                   | [Tools Review Task](tasks/support/tools-review-task.md)                                                         |
| **🔧 Support Tasks**    | Framework Domain Adaptation       | Migrate framework to different domain        | [Framework Domain Adaptation](tasks/support/framework-domain-adaptation.md)                                      |

---

## 📚 Documentation Types & Purposes

Understanding the different types of documentation helps you choose the right resource for your needs:

### 📋 **Tasks** (WHAT to do and WHEN)

- **Purpose**: Define complete workflows and processes
- **Content**: Step-by-step instructions, context requirements, outputs, checklists
- **Use When**: You need to execute a specific development process
- **Example**: [API Design Task](tasks/02-design/api-design-task.md)

### 🔧 **Creation Guides** (HOW to use the tools)

- **Purpose**: Detailed instructions for using specific tools and scripts
- **Content**: Script parameters, template customization, examples, troubleshooting
- **Use When**: You need to use a PowerShell script or customize a template
- **Example**: [CI/CD Setup Guide](guides/07-deployment/ci-cd-setup-guide.md)
- **Note**: Task-owned *customization craft* increasingly lives in framework **craft skills** under `.claude/skills/` (e.g. `ui-design`, `api-design`), activated by the owning task's Check Recommended Skills step — not in standalone creation guides

### 📖 **Usage Guides** (Multi-tool operational reference)

- **Purpose**: Operational reference spanning **multiple tools or artifacts** that no single Creation Guide covers — decision criteria, invocation patterns, worked examples
- **Content**: Cross-tool conventions, worked examples, troubleshooting — **not** task-workflow steps (those live in the task definition; re-documenting them is the [task-usage-guide anti-pattern](guides/support/guide-creation-best-practices-guide.md))
- **Examples**: [Framework Rollout Usage Guide](guides/support/framework-rollout-usage-guide.md)

### 🎯 **Key Principle**: No Redundant Documentation

- **Tasks** should be self-contained with complete process information
- **Creation Guides** focus on tool usage, not process workflow
- **Usage Guides** combine multiple tools/artifacts for operational reference — never to restate a task's workflow (the task-usage-guide anti-pattern)

> **💡 Tip**: Start with the **Task** for process workflow, then reference **Creation Guides** for tool usage.

---

## 📊 Project State & Tracking

### Current State Files

| File                                                                                                  | Purpose                          | Status    |
| ----------------------------------------------------------------------------------------------------- | -------------------------------- | --------- |
| [Feature Tracking](../doc/state-tracking/permanent/feature-tracking.md)               | Track feature development status | ✅ Active |
| [Feature Request Tracking](../doc/state-tracking/permanent/feature-request-tracking.md) | Intake queue for product feature requests | ✅ Active |
| [Technical Debt Tracking](../doc/state-tracking/permanent/technical-debt-tracking.md) | Track technical debt items       | ✅ Active |

### Creating New State Files

Need to track something new? Use the [State File Template](templates/support/state-file-template.md) to create:

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

## 📦 AI Agent Session Management

### Feedback Forms for Multi-Session Tasks

Complete one feedback form at the end of **each session**, not at the end of the entire task. Feedback from early sessions degrades if deferred to the final session.

### One Batch Per Session (Validation Tasks)

**Never run multiple validation batches in the same session.** Each batch is a complete task cycle: analysis → checkpoint → report generation → state file updates → feedback form. Complete ALL finalization steps (including tech debt tracking updates and feedback form) for one batch before ending the session. The next batch starts in a fresh session.

**Why**: Each batch is meant to close out cleanly through its own checkpoint cycle — analysis → human review → report generation → state file updates → feedback form. Running a second batch in the same session compresses both batches' finalization steps into one rushed pass, and prior-batch findings start to contaminate the new batch's analysis. Keeping one batch per session preserves per-batch checkpoint discipline and keeps each batch's state file updates and feedback form grounded in the work that just happened.

---

## 🔧 System Details

### Tool Feedback Process

At the end of each session, the AI agent creates a feedback form and **fills in all sections**. The human partner contributes independently after the session by appending rows to the form's Human Intervention Log.

1. **Create feedback form** using the automation script:

   ```bash
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/support/New-FeedbackForm.ps1 -DocumentId "PF-TSK-XXX" -TaskContext "Task Name" -FeedbackType "MultipleTools" -Confirm:\$false
   ```

   **FeedbackType options**: `"SingleTool"`, `"MultipleTools"`, `"TaskLevel"` (also accepts `"Single Tool"`, `"Multiple Tools"`, `"Task-Level"`)

2. **Fill in all sections** — the human partner contributes after the session by appending rows to the Human Intervention Log

**Files saved**: `appdev/process-framework-central/feedback/feedback-forms/YYYYMMDD-HHMMSS_<PROJECT-ID>_PF-TSK-XXX_feedback.md` (Phase 7 underscore-separated format with `<PROJECT-ID>` segment, 2026-05-11). Resolved via `Get-CentralFrameworkPath` regardless of cwd.

> ⚠️ **Important**: Use **TASK ID** (e.g., PF-TSK-009) in filename, NOT artifact IDs created during task
>
> 📈 **Why this matters**: Your feedback drives continuous improvement through the [Tools Review Task](tasks/support/tools-review-task.md)
>
> 📋 **More details**: See the [Feedback Process Guide](../process-framework-central/feedback/archive/README.md)
>
> 🔄 **Visual guide**: See the [Feedback Process Flowchart](visualization/process-flows/feedback-process-flowchart.md)

---

## ❓ Troubleshooting

| Problem                                | Solution                                                                                                                                        |
| -------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| **Can't decide which task to use**     | Use the [task-selection guidance](#choosing-your-task) or ask your human partner                                                |
| **Task seems too big/complex**         | Break it down with your human partner                                                                                                           |
| **Missing information for task**       | Ask your human partner for specific files or context                                                                                            |
| **Task definition unclear**            | Check the full task definition or ask for clarification                                                                                         |
| **Need to work across multiple tasks** | Discuss the approach with your human partner                                                                                                    |
| **Process feels inefficient**          | Note it for the next [Process Improvement](#process-improvement) task                                                                           |
| **Broken document links**              | Confirm the SessionStart hook fired (look for the LinkWatcher startup line in initial context); if absent, check `.claude/settings.json` and re-trigger via `/hooks` or a new session. For validate-run false positives and link-form rules: `<LinkWatcher install>/doc/user/handbooks/link-validation.md` (install default `%USERPROFILE%\bin`, override via `LINKWATCHER_INSTALL_DIR`) |
| **Need to rename or move files**       | Use any method (VS Code, File Explorer, git commands) - LinkWatcher updates all references automatically                                        |
| **Need to delete files**               | Use any method - LinkWatcher will detect and handle reference cleanup automatically                                                             |
| **LinkWatcher not working**            | Check if running: `Get-Process python*`. If not, manually invoke the hook wrapper: `pwsh.exe -ExecutionPolicy Bypass -File process-framework/tools/linkWatcher/start_linkwatcher_hook_wrapper.ps1` and inspect `logs/linkwatcher/LinkWatcherError.txt`. Full diagnostic flow: `<LinkWatcher install>/doc/user/handbooks/logging-and-monitoring.md` |

---

## 🧠 Understanding Task-Based Development

_New to this approach? This section explains the concepts behind the system._

### 🏗️ Task and State Management Principles

These foundational principles govern how the framework operates and ensure consistency across AI agent sessions:

#### Task Granularity

Each task is designed with a defined level of granularity such that it can be fully processed and completed within a single session with an AI agent. This ensures continuity, keeps each session focused on a coherent unit of work, and prevents partial progress from being stranded between sessions.

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

### Self-Documenting Workflow

The framewor
