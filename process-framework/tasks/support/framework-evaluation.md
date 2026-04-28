---
id: PF-TSK-079
type: Process Framework
category: Task Definition
domain: agnostic
version: 1.5
created: 2026-03-24
updated: 2026-04-14
---

# Framework Evaluation

## Purpose & Context

Structurally evaluate the process framework — or a targeted subset of it — across seven evaluation dimensions: completeness, consistency, redundancy, accuracy, effectiveness, automation coverage, and scalability. The task produces a structured evaluation report with scored findings and registers actionable improvements as IMP entries for follow-up via Process Improvement (PF-TSK-009).

This task is analogous to the code validation tasks (05-validation) but targets the framework's own artifacts: tasks, templates, guides, scripts, context maps, state files, and workflows.

## AI Agent Role

**Role**: Process Quality Auditor
**Mindset**: Critical, systematic, evidence-based — assess against concrete criteria, not opinion
**Focus Areas**: Structural integrity, cross-reference accuracy, convention adherence, gap identification, scalability assessment
**Communication Style**: Present findings with evidence (file paths, specific examples), propose severity levels, ask about evaluation scope priorities

## When to Use

- When periodically reviewing the framework's health (e.g., quarterly, after a batch of new tasks)
- When onboarding a new project and wanting to assess framework readiness
- When a specific framework area feels problematic (e.g., "test scripts seem inconsistent")
- After a significant structural change (SC-* task completion) to verify integrity
- When evaluating whether the framework scales to a different project size or type
- Before a major framework extension to identify gaps that should be addressed first

## Context Requirements

[View Context Map for this task](../../visualization/context-maps/support/framework-evaluation-map.md)

- **Critical (Must Read):**

  - **Evaluation Scope** — Human partner specifies what to evaluate: entire framework, a specific phase (e.g., "03-testing tasks"), a component type (e.g., "all templates"), or a workflow (e.g., "enhancement workflow end-to-end")
  - [Documentation Map](../../PF-documentation-map.md) — Central index of all framework artifacts; starting point for completeness checks
  - [AI Tasks System](../../ai-tasks.md) — Task registry; the authoritative list of all tasks and workflows

- **Important (Load If Space):**

  - [Process Framework Task Registry](../../infrastructure/process-framework-task-registry.md) — Automation status, script locations, file update patterns per task
  - [Process Framework Task Registry — Trigger & Output](../../infrastructure/process-framework-task-registry.md) — Task trigger conditions, output statuses, State File Trigger Index, and trigger chain diagrams
  - [PF ID Registry](../../PF-id-registry.json) — ID prefixes, directory mappings, counter state
  - [Task Creation Guide](../../guides/support/task-creation-guide.md) — Defines expected task structure and quality standards

- **Reference Only (Access When Needed):**
  - [Process Improvement Tracking](../../../process-framework-local/state-tracking/permanent/process-improvement-tracking.md) — For registering new IMP entries
  - [Visual Notation Guide](../../guides/support/visual-notation-guide.md) — For interpreting context map diagrams
  - Individual task definitions, templates, guides, scripts — loaded as needed during evaluation

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished! 🚨**
>
> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

### Session Scope

An evaluation may span multiple sessions depending on the scope and the depth of analysis required. This is expected and must not be used as justification to shortcut any step. Specifically:

- **Large evaluation scopes** (full framework, multi-phase) will naturally require multiple sessions for artifact inventory and dimension analysis alone
- **Data-driven validation** (Step 8) may require its own dedicated session(s) to collect and analyze historical data before conclusions can be drawn
- **Each session** must complete its planned work fully — including all checkpoint presentations and state file updates — before closing. Do not start a new analysis phase if the current one cannot be finished with proper finalization
- **Use a temporary state file** for multi-session evaluations to track which artifacts have been assessed, which dimensions are complete, and what remains:
  ```bash
  pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/support/New-TempTaskState.ps1 -TaskName "<Evaluation Scope>" -Description "<scope description>" -Confirm:\$false
  ```

The quality of an evaluation depends on thoroughness, not speed. A multi-session evaluation that properly validates every finding is more valuable than a single-session evaluation that relies on assumptions.

### Preparation

1. **Define Evaluation Scope**: Agree with human partner on what to evaluate. Options:
   - **Full framework** — all tasks, templates, guides, scripts, context maps, state files
   - **Phase scope** — a specific workflow phase (e.g., "01-planning", "05-validation")
   - **Component type** — all artifacts of one type (e.g., "all creation scripts", "all templates")
   - **Workflow scope** — an end-to-end workflow (e.g., "Feature Enhancement workflow from request to deployment")
   - **Targeted** — a specific set of artifacts identified by the human partner

2. **Select Evaluation Dimensions**: Determine which of the seven dimensions to evaluate. By default, all dimensions apply. The human partner may narrow the focus.

   | # | Dimension | What It Assesses | Default |
   |---|-----------|-----------------|---------|
   | 1 | **Completeness** | Are all expected artifacts present? Do tasks have context maps, templates have guides, scripts have error handling? | Always |
   | 2 | **Consistency** | Do artifacts follow the same structure, naming conventions, metadata format, and cross-referencing patterns? | Always |
   | 3 | **Redundancy** | Is there duplicated content, overlapping task responsibilities, or unnecessary artifacts? | Always |
   | 4 | **Accuracy** | Do cross-references resolve? Do ID registries match actual files? Do scripts reference existing templates? | Always |
   | 5 | **Effectiveness** | Are process steps clear and actionable? Are templates useful? Do guides answer the questions they should? | Always |
   | 6 | **Automation Coverage** | Are manual steps that could be scripted still manual? Do existing scripts cover the full workflow? | Always |
   | 7 | **Scalability** | Would this work for small and large projects? Are there hardcoded assumptions about project size, language, or domain? | On request |

3. **🚨 CHECKPOINT**: Present evaluation scope and selected dimensions to human partner for approval before starting analysis.

### Execution

4. **Inventory Artifacts in Scope**: List all artifacts within the evaluation scope. For each, note:
   - File path and ID
   - Type (task, template, guide, script, context map, state file)
   > **⚠️ Enumeration required**: Every count claimed in the evaluation report must be backed by a specific list of items in the "Artifacts in Scope" table. Do not use approximate counts (e.g., "~28 templates") — enumerate each item so downstream work can rely on accurate totals without re-auditing.

5. **Evaluate Each Dimension**: For each selected dimension, systematically assess the artifacts in scope:

   **Dimension 1 — Completeness**:
   - For each task: Does it have a context map? Are referenced templates/guides/scripts present?
   - For each template: Is there a corresponding creation script? A customization guide (if complex)?
   - For each script: Does it have error handling, `-WhatIf` support, and documentation?
   - For each workflow in ai-tasks.md: Can every step be executed with existing artifacts?

   **Dimension 2 — Consistency**:
   - Do all tasks follow the unified task structure (Purpose, AI Agent Role, When to Use, Context Requirements, Process, Outputs, State Tracking, Checklist, Next Tasks)?
   - Do all templates use the same metadata format and placeholder conventions?
   - Do all scripts follow the same import pattern, parameter naming, and error handling approach?
   - Are naming conventions consistent (e.g., `-task` suffix, kebab-case filenames)?

   **Dimension 3 — Redundancy**:
   - Are there tasks with overlapping responsibilities?
   - Is the same guidance duplicated across multiple guides or task definitions?
   - Are there templates that could be consolidated?
   - Are there scripts that duplicate logic instead of sharing modules?

   **Dimension 4 — Accuracy**:
   - Verify cross-references: Do links in task definitions resolve to existing files?
   - Verify ID registry: Do `nextAvailable` counters match actual file counts? Do directory mappings match reality?
   - Verify documentation map: Are all artifacts listed? Are there stale entries?
   - Verify script references: Do scripts point to existing templates and output directories?

   **Dimension 5 — Effectiveness**:
   - Are process steps specific and actionable (not vague like "review the code")?
   - Do task definitions include enough context for an AI agent to execute without guessing?
   - Are templates structured so that placeholders clearly indicate what content is needed?
   - Do guides answer practical questions rather than restating what's already in the task?

   **Dimension 6 — Automation Coverage**:
   - Which task outputs are created manually vs. via scripts?
   - Are there recurring manual steps that could be automated?
   - Do validation scripts cover the scope needed?
   - Are state file updates automated where they should be?

   **Dimension 7 — Scalability** (when selected):
   - Are there hardcoded project-specific references (paths, feature names, language-specific commands)?
   - Would the framework work for a 5-file project? A 500-file project?
   - Does the task/template complexity scale appropriately with project size?
   - Are there unnecessary overhead for simple projects or missing structure for complex ones?

6. **Conduct Industry Research**: For each dimension being evaluated, briefly research how comparable frameworks, industry standards, or recognized best practices address the same concern:
   - Search for relevant framework design patterns, process maturity models, or tooling approaches
   - Note where the evaluated artifacts align with or diverge from external norms
   - Use findings to calibrate dimension scores (e.g., an internally "good" result may be "adequate" relative to industry practice)
   - Include external comparisons as supporting evidence in the evaluation report
   > This step grounds the evaluation in external reality rather than internal assumptions alone. Depth of research should be proportional to the evaluation scope — a targeted evaluation may need only a few searches, while a full framework evaluation warrants broader research.

7. **Score Findings**: For each dimension evaluated, assign a score:

   | Score | Label | Meaning |
   |-------|-------|---------|
   | 4 | Excellent | No issues found; meets or exceeds expectations |
   | 3 | Good | Minor issues only; functional and effective |
   | 2 | Adequate | Notable gaps or issues; works but needs improvement |
   | 1 | Poor | Significant problems; impedes framework effectiveness |

8. **Identify Improvements**: For each finding with score ≤ 3, draft an improvement entry with:
   - Description of the issue
   - Affected artifact(s)
   - Suggested fix
   - Estimated effort (Low / Medium / High)
   - Suggested priority (Low / Medium / High)
   - Route to (see routing guidance below)

   > **Routing guidance**: Not all findings belong as standalone IMPs. Before listing improvements, group related findings that share a root cause or solution, then decide per finding/group:
   > - **IMP** (default) — isolated, self-contained improvement executable via [Process Improvement](process-improvement-task.md) (PF-TSK-009)
   > - **PF-TSK-026** — interconnected findings that together require a new framework capability (new task + template + script + guide). Register as IMP but mark for delegation to [Framework Extension](framework-extension-task.md)
   > - **PF-TSK-014** — findings that require file moves, directory reorganization, or structural changes. Register as IMP but mark for delegation to [Structure Change](structure-change-task.md)
   > - **PF-TSK-001** — findings that reveal a missing task definition. Register as IMP but mark for delegation to [New Task Creation Process](new-task-creation-process.md)
   >
   > Present routing decisions at the Step 9 checkpoint for human approval.

   **Multi-level solution thinking**: For significant findings (score ≤ 2 or high-priority), do not converge on a single fix immediately. Present at least three solution approaches at different ambition levels:
   - **Incremental** — minimal change that improves the current setup without restructuring
   - **Moderate restructuring** — targeted reorganization of the affected area that improves structure without redesigning from scratch
   - **Clean-slate redesign** — how this area would look if built from scratch, unconstrained by the current implementation

   This prevents premature convergence on the first viable strategy and ensures the human partner can weigh trade-offs across the full solution space before choosing a direction.

   **Data-driven validation for removal/merge proposals**: When a finding proposes **removing, merging, or fundamentally restructuring** an existing framework mechanism (e.g., reducing feedback dimensions, merging templates, consolidating tasks), the proposal must be validated against historical data before it can become an IMP. This means:
   - Trace the mechanism's actual contribution by analyzing historical data (e.g., which feedback dimensions triggered which IMPs, how often a template section was used, which task steps prevented errors)
   - Quantify the mechanism's unique signal — would the improvements it surfaced still have been identified without it?
   - Present the data analysis at the checkpoint, not just the proposal
   - If the data shows the mechanism carries unique, non-redundant signal, the removal/merge proposal must be rejected regardless of how intuitive it seems

   This validation may require its own multi-session data collection effort (see Session Scope below). The cost of collecting data is always lower than the cost of removing a mechanism that was silently preventing problems.

   > **Rationale**: IMP-525 (2026-04-14) proposed reducing feedback form dimensions from 5 to 3 based on intuitive reasoning about correlation. Data-driven analysis of 309 IMPs across 31 reviews showed all 5 dimensions carry distinct, non-redundant improvement signal. The proposal was rejected. This step exists to prevent similar premature structural changes.

9. **🚨 CHECKPOINT**: Present evaluation findings summary to human partner:
   - Dimension scores with key evidence
   - Top findings (most impactful issues)
   - Proposed improvement entries with routing decisions (IMP vs delegated task)
   - Get approval before generating the report

### Finalization

10. **Generate Evaluation Report**: Use the creation script to generate the report from the template:
   ```bash
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/support/New-FrameworkEvaluationReport.ps1 -EvaluationScope "Description of scope" -Confirm:\$false
   ```
   Then customize the generated report with the evaluation findings, dimension scores, and improvement recommendations.

11. **Register Improvement Entries**: For each approved improvement, add an IMP entry to [Process Improvement Tracking](../../../process-framework-local/state-tracking/permanent/process-improvement-tracking.md) using the automation script:
    ```bash
    # Single item
    pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/support/New-ProcessImprovement.ps1 -Description "Improvement description" -Priority "MEDIUM" -Source "Framework Evaluation PF-EVR-XXX" -SourceLink "../../evaluation-reports/FILENAME.md" -Confirm:\$false

    # Batch mode (preferred for multiple improvements) — pass a JSON array file:
    pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/support/New-ProcessImprovement.ps1 -BatchFile "improvements.json" -Confirm:\$false
    ```
    > **Routed findings**: IMPs marked for delegation in Step 8 should still be registered (for traceability), but include the target task in the Notes column (e.g., "Delegate to PF-TSK-026 — interconnected with IMP-XXX, IMP-YYY"). After registration, use [Update-ProcessImprovement.ps1](../../scripts/update/Update-ProcessImprovement.ps1) to set their status to `Deferred`.

12. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Outputs

- **Framework Evaluation Report** — Structured report in `process-framework-local/evaluation-reports`, created via `New-FrameworkEvaluationReport.ps1`. Contains: evaluation scope, dimension scores, detailed findings per dimension, cross-cutting findings (issues spanning 2+ dimensions listed once), improvement recommendations, and overall assessment.
- **Improvement Entries** — IMP entries registered in [Process Improvement Tracking](../../../process-framework-local/state-tracking/permanent/process-improvement-tracking.md) for each actionable finding, with source linking back to the evaluation report.

## State Tracking

The following state files must be updated as part of this task:

- [Process Improvement Tracking](../../../process-framework-local/state-tracking/permanent/process-improvement-tracking.md) — Add IMP entries for each improvement identified during evaluation

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

Before considering this task finished:

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] Framework Evaluation Report created in `process-framework-local/evaluation-reports` via script
  - [ ] Report customized with all evaluation findings, dimension scores, and recommendations
  - [ ] All dimension scores include supporting evidence (file paths, specific examples)
- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] IMP entries added to [Process Improvement Tracking](../../../process-framework-local/state-tracking/permanent/process-improvement-tracking.md) for each approved improvement
  - [ ] Each IMP entry links back to the evaluation report as source
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Guide](../../guides/framework/feedback-form-guide.md) for each tool used, using task ID "PF-TSK-079" and context "Framework Evaluation"

## Next Tasks

- [**Process Improvement**](process-improvement-task.md) — Implement the IMP entries identified by the evaluation
- [**Structure Change**](structure-change-task.md) — If evaluation reveals structural reorganization needs
- [**New Task Creation Process**](new-task-creation-process.md) — If evaluation identifies missing tasks

## Related Resources

- [Documentation Map](../../PF-documentation-map.md) — Central index of all framework artifacts
- [Process Framework Task Registry](../../infrastructure/process-framework-task-registry.md) — Task automation status overview
- [Task Creation Guide](../../guides/support/task-creation-guide.md) — Expected task structure and quality standards
- [AI Tasks System](../../ai-tasks.md) — Task registry and workflow definitions
- [Feature Validation Guide](../../guides/05-validation/feature-validation-guide.md) — Analogous approach for code validation (reference for evaluation methodology)
