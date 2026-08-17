---
id: PF-TSK-079
type: Process Framework
category: Task Definition
domain: agnostic
version: 1.13
created: 2026-03-24
updated: 2026-07-21
description: "Structurally evaluate the process framework for completeness, consistency, redundancy, accuracy, effectiveness, automation coverage, and scalability"
use_when: >-
  Structurally evaluate the process framework or specific parts of it for completeness, consistency, redundancy, accuracy, effectiveness, automation coverage, and scalability. Triggers: 'evaluate the framework', 'audit the framework', 'review framework area X'.
triggers:
  - "evaluate the framework"
  - "audit the framework"
  - "review framework area X"
automation: partial
scripts:
  - ../../scripts/file-creation/support/New-FrameworkEvaluationReport.ps1
  - ../../scripts/file-creation/support/New-ProcessImprovement.ps1
trigger_status:
  - raw: "_(schedule / user request)_"
output_status:
  - raw: "`process-improvement-tracking.md` → new IMP items (triggers PF-TSK-009)"
next_tasks:
  - task: process-improvement-task.md
    condition: "Implement the IMP entries identified by the evaluation"
  - task: structure-change-task.md
    condition: "If evaluation reveals structural reorganization needs"
  - task: new-task-creation-process.md
    condition: "If evaluation identifies missing tasks"
---

# Framework Evaluation

> **▶ Execute this task under the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md).** This file holds only this task's specific content; the universal contract every task shares lives once in the protocol and is mandatory here.

## Purpose & Context

Structurally evaluate the process framework — or a targeted subset of it — across seven evaluation dimensions: completeness, consistency, redundancy, accuracy, effectiveness, automation coverage, and scalability. The task produces a structured evaluation report with scored findings and registers actionable improvements as IMP entries for follow-up via Process Improvement (PF-TSK-009).

This task is analogous to the code validation tasks (05-validation) but targets the framework's own artifacts: tasks, templates, guides, scripts, context maps, state files, and workflows.

## AI Agent Role

**Role**: Process Quality Auditor
**Mindset**: Critical, systematic, evidence-based — assess against concrete criteria, not opinion
**Focus Areas**: Structural integrity, cross-reference accuracy, convention adherence, gap identification, scalability assessment
**Communication Style**: Present findings with evidence (file paths, specific examples), propose severity levels, ask about evaluation scope priorities

## Context Requirements

- **Critical (Must Read):**

  - **Evaluation Scope** — Human partner specifies what to evaluate: entire framework, a specific phase (e.g., "03-testing tasks"), a component type (e.g., "all templates"), or a workflow (e.g., "enhancement workflow end-to-end")
  - [Documentation Map](../../PF-documentation-map.md) — Central index of all framework artifacts; starting point for completeness checks
  - [AI Tasks System](../../ai-tasks.md) — Task registry; the authoritative list of all tasks and workflows

- **Important (Load If Space):**

  - [Process Framework Task Registry](../../infrastructure/process-framework-task-registry.md) — Automation status, script locations, file update patterns per task
  - [Process Framework Task Registry — Trigger & Output](../../infrastructure/process-framework-task-registry.md) — Task trigger conditions, output statuses, State File Trigger Index, and trigger chain diagrams
  - [PF ID Registry](../../PF-id-registry.json) — ID prefixes, directory mappings, counter state
  - [`task-creation` craft skill](../../../.claude/skills/task-creation/SKILL.md) — Defines expected task structure and quality standards

- **Reference Only (Access When Needed):**
  - [Process Improvement Tracking](../../../process-framework-central/state-tracking/permanent/process-improvement-tracking.md) — For registering new IMP entries
  - Individual task definitions, templates, guides, scripts — loaded as needed during evaluation

## Process

> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

### Session Scope

An evaluation may span multiple sessions depending on the scope and the depth of analysis required. This is expected and must not be used as justification to shortcut any step. Specifically:

- **Large evaluation scopes** (full framework, multi-phase) will naturally require multiple sessions for artifact inventory and dimension analysis alone
- **Data-driven validation** (Step 8) may require its own dedicated session(s) to collect and analyze historical data before conclusions can be drawn
- **Each session** must complete its planned work fully — including all checkpoint presentations and state file updates — before closing. Do not start a new analysis phase if the current one cannot be finished with proper finalization
- **Use a temporary state file** for multi-session evaluations to track which artifacts have been assessed, which dimensions are complete, and what remains. The `FrameworkEvaluation` variant scaffolds an evaluation-shaped state file (Artifacts in Scope inventory, per-dimension progress, findings log, session plan):
  ```bash
  pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/support/New-TempTaskState.ps1 -TaskName "<Evaluation Scope>" -Variant FrameworkEvaluation -Description "<scope description>" -Confirm:\$false
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
   | 3 | **Redundancy** | Does anything not carry its weight — duplicated *coverage* (removable/combinable), duplicated *machinery* (scaffolding to consolidate), or plain *superfluity* (an unnecessary step, instruction, or artifact to delete)? | Always |
   | 4 | **Accuracy** | Do cross-references resolve? Do ID registries match actual files? Do scripts reference existing templates? | Always |
   | 5 | **Effectiveness** | Are process steps clear and actionable? Are templates useful? Do guides answer the questions they should? | Always |
   | 6 | **Automation Coverage** | Are manual steps that could be scripted still manual? Do existing scripts cover the full workflow? | Always |
   | 7 | **Scalability** | Would this work for small and large projects? Are there hardcoded assumptions about project size, language, or domain? | On request |

3. **🚨 CHECKPOINT**: Present evaluation scope and selected dimensions to human partner for approval before starting analysis.

### Execution

4. **Inventory Artifacts in Scope**: List all artifacts within the evaluation scope. For each, note:
   - File path and ID
   - Type (task, template, guide, script, context map, state file)
   > **⚠️ Read in-scope task definitions in full first**: build the inventory from the task files themselves, not from the [Documentation Map](../../PF-documentation-map.md)'s one-line listing alone. The map is a flat index; a task's complete artifact set (every referenced template, guide, script, state file) and its full step inventory surface only by reading the task file, so a map-only inventory systematically under-counts the artifacts and steps actually in scope. For script-backed tasks and workflows, enumerate the **backing scripts** as first-class in-scope artifacts — both the `scripts:` declared in the task's frontmatter and any scripts its steps invoke — since Automation Coverage (Dimension 6) and Completeness (Dimension 1) assess those scripts directly.
   > **⚠️ Enumeration required**: Every count claimed in the evaluation report must be backed by a specific list of items in the "Artifacts in Scope" table. Do not use approximate counts (e.g., "~28 templates") — enumerate each item so downstream work can rely on accurate totals without re-auditing. For a large homogeneous set (e.g. 1,300+ test cases), category-level enumeration with exact per-category counts satisfies this — the requirement is exact, verifiable totals, not per-filename listing.

5. **Evaluate Each Dimension**: For each selected dimension, systematically assess the artifacts in scope:

   **Dimension 1 — Completeness**:
   - For each task: Does it have a context map? Are referenced templates/guides/scripts present?
   - For each template: Is there a corresponding creation script? A customization guide (if complex)?
   - For each script: Does it have error handling, `-WhatIf` support, and documentation?
   - For each workflow in ai-tasks.md: Can every step be executed with existing artifacts?

   **Dimension 2 — Consistency**:
   - Do all tasks follow the unified task structure (Purpose, AI Agent Role, Context Requirements, Process, Outputs, State Tracking, Checklist, Next Tasks)?
   - Do all templates use the same metadata format and placeholder conventions?
   - Do all scripts follow the same import pattern, parameter naming, and error handling approach?
   - Are naming conventions consistent (e.g., `-task` suffix, kebab-case filenames)?

   **Dimension 3 — Redundancy** — hunt for anything that doesn't carry its weight; the kind sets the fix:
   - **Coverage (intent) redundancy** — the same content/cases duplicated: overlapping task responsibilities, guidance repeated across guides/tasks, consolidatable templates, duplicated test *cases*. Be conservative — deliberate defense-in-depth and descriptive repetition are legitimate, so *remove or combine* only where coverage is genuinely duplicated.
   - **Machinery redundancy** — the same scaffolding copy-pasted: scripts duplicating logic instead of importing a shared module, or test files re-inventing fixtures/subprocess/path-resolution boilerplate. The fix is *consolidate into shared helpers*, leaving coverage unchanged.
   - **Superfluity** — a single step, instruction, or artifact that adds nothing: not duplicated, just dead weight, over-specification, or a note restating what a step already says. Verify it is genuinely non-load-bearing, then *delete*.

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

   > **Attribute validator findings correctly**: when a validation script (`Validate-IdRegistry.ps1`, `Validate-StateTracking.ps1`, `Build-DocumentationMap.ps1 -Check`, …) surfaces an issue, decide whether the defect lies in the **evaluated artifact** (a real problem in the thing under review) or in the **validator's own scope** (false positive, over-/under-report, or coverage gap). They route differently — an artifact defect is a finding against that artifact; a validator gap is a finding against the validator. Don't record a validator's coverage limitation as a defect of the artifact it scanned, or vice versa.

6. **Conduct Industry Research**: For each dimension being evaluated, briefly research how comparable frameworks, industry standards, or recognized best practices address the same concern:
   - Search for relevant framework design patterns, process maturity models, or tooling approaches
   - Note where the evaluated artifacts align with or diverge from external norms
   - Use findings to calibrate dimension scores (e.g., an internally "good" result may be "adequate" relative to industry practice)
   - Include external comparisons as supporting evidence in the evaluation report
   - When evaluating framework rhetoric or AI-agent-targeted guidance, include current Claude model prompt-engineering best practices as one external comparison. Wording effective for older models can become stale for newer ones — particularly around tool-call triggering, instruction emphasis, and verbosity. Treat as one source among several, not as standalone justification to overhaul existing rhetoric.
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
   - Suggested fix — for an accumulated/systemic finding, cover the adoption/detection gap that let it accumulate (missing authoring pointer, no validator/detector) and what makes the fix stick, not only the artifact repair
   - Estimated effort (Low / Medium / High)
   - Suggested priority (Low / Medium / High)
   - Suggested route — a triage *hint*, not a routing decision (see routing guidance below)

   **Verify each finding against the live artifact before it becomes an IMP**: a finding is a hypothesis until checked against the current files. For each, confirm the problem is still real and not already handled by an existing script, validator surface, blueprint-provided file, or config field, then open the target file to confirm the suggested fix fits what is actually there (the field, section, or behavior it assumes exists). For a fix targeting a rolled-out blueprint artifact, also confirm it stays project-agnostic — a reference to an appdev-local artifact would dangle in every rolled-out copy. Re-check findings carried over from another project's working tree against the framework source — project state drifts. Drop or rewrite any finding that fails either check rather than filing it, and record each dropped candidate in the report's Withdrawn During Verification table — the report should show its own false-positive rate, not only surviving findings.

   **Fix vs. route**: a finding whose fix is confined to artifacts this session or its parent extension created or modified (a designed-in case when the evaluation runs as the New-Task-Creation gate inside its own extension) may, on human approval at the Step 9 checkpoint, be fixed in-session instead of becoming an IMP — record it in the report's Findings Resolved In-Session table. Anything whose fix spreads beyond those artifacts routes as an IMP; an in-scope interim fix may still land alongside the routed clean-slate IMP.

   > **Routing guidance**: Not all findings belong as standalone IMPs. Before listing improvements, group related findings that share a root cause or solution, then attach a **suggested route** to each finding/group. Post-Phase-7, every finding is registered into Section 1 — Intake regardless (Step 11); the suggested route is a triage hint recorded in Notes, and [IMP Triage (PF-TSK-089)](imp-triage-task.md) makes the actual routing decision. Suggest one of:
   > - **Improvement** (default) — isolated, self-contained change executable via [Process Improvement](process-improvement-task.md) (PF-TSK-009)
   > - **PF-TSK-026** — interconnected findings that together require a new framework capability (new task + template + script + guide); hint delegation to [Framework Extension](framework-extension-task.md)
   > - **PF-TSK-014** — findings that require file moves, directory reorganization, or structural changes; hint delegation to [Structure Change](structure-change-task.md)
   > - **PF-TSK-001** — findings that reveal a missing task definition; hint delegation to [New Task Creation Process](new-task-creation-process.md)
   >
   > Present the suggested routes at the Step 9 checkpoint for human review.

   **Multi-level solution thinking**: For a significant finding (score ≤ 2 or high-priority) that questions a design decision or admits more than one defensible fix shape, do not converge on a single fix immediately. Present at least three solution approaches at different ambition levels:
   - **Incremental** — minimal change that improves the current setup without restructuring
   - **Moderate restructuring** — targeted reorganization of the affected area that improves structure without redesigning from scratch
   - **Clean-slate redesign** — how this area would look if built from scratch, unconstrained by the current implementation

   This prevents premature convergence on the first viable strategy and ensures the human partner can weigh trade-offs across the full solution space before choosing a direction. A finding with one obvious fix — however severe — records that single suggested fix directly.

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
   - **Cross-cutting findings**: a finding spanning 2+ dimensions gets a single **primary home** — list it once in the report's Cross-Cutting Findings section and reference it from each affected dimension, rather than repeating it under every dimension (which inflates finding counts and distorts dimension scores)
   - Proposed improvement entries with **suggested routes** (triage hints for PF-TSK-089, not final routing — see Step 8)
   - Get approval before generating the report
   - If the human reframes scope at this checkpoint, choose: re-checkpoint after rescoring, or proceed and record the adjustment in the report's Scope Description (deliberate exclusions belong here, not as Rejected IMPs)

### Finalization

10. **Generate Evaluation Report**: Use the creation script to generate the report from the template:
   ```bash
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/support/New-FrameworkEvaluationReport.ps1 -EvaluationScope "Description of scope" -Confirm:\$false
   ```
   Then customize the generated report with the evaluation findings, dimension scores, and improvement recommendations.

11. **Register Improvement Entries**: For each approved improvement, add an IMP entry to [Process Improvement Tracking](../../../process-framework-central/state-tracking/permanent/process-improvement-tracking.md) using the automation script:
    ```bash
    # Single item
    # Phase 7 (2026-05-11): -Priority dropped from Single param set — all IMPs land in Section 1 — Intake;
    # Triage routes from there. Use Update-ProcessImprovement.ps1 -MoveToSection after Triage if needed.
    # Length caps (single and batch): -Description 10–500 chars (-Notes is uncapped) — compose to length;
    # pre-flight a borderline call with -WhatIf (validation fires before anything is created).
    pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/support/New-ProcessImprovement.ps1 -Description "Improvement description" -Source "Framework Evaluation PF-EVR-XXX" -SourceLink "appdev/process-framework-central/evaluation-reports/FILENAME.md" -Confirm:\$false

    # Batch mode (preferred for multiple improvements) — pass a JSON array file:
    pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/support/New-ProcessImprovement.ps1 -BatchFile "improvements.json" -Confirm:\$false
    ```
    > **Routed findings**: findings given a delegation-suggesting route in Step 8 are still registered (for traceability) into Section 1 — Intake like every other finding; record the suggested target task as a triage hint in the Notes column (e.g., "Suggested route: PF-TSK-026 — interconnected with IMP-XXX, IMP-YYY"). [IMP Triage (PF-TSK-089)](imp-triage-task.md) makes the actual routing call and moves the row from Intake to the owning section — this task neither sets a status beyond Intake nor moves rows itself.

12. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Outputs

- **Framework Evaluation Report** — Structured report in `appdev/process-framework-central/evaluation-reports`, created via `New-FrameworkEvaluationReport.ps1`. Contains: evaluation scope, dimension scores, detailed findings per dimension, cross-cutting findings (issues spanning 2+ dimensions listed once), improvement recommendations, and overall assessment.
- **Improvement Entries** — IMP entries registered in [Process Improvement Tracking](../../../process-framework-central/state-tracking/permanent/process-improvement-tracking.md) for each actionable finding, with source linking back to the evaluation report.

## State Tracking

The following state files must be updated as part of this task:

- [Process Improvement Tracking](../../../process-framework-central/state-tracking/permanent/process-improvement-tracking.md) — Add IMP entries for each improvement identified during evaluation

## ⚠️ MANDATORY Task Completion Checklist

> Completion discipline, output verification, and the feedback form are governed by the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md) (Phase C). The items below are the **task-specific** verifications that plug into it.

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] Framework Evaluation Report created in `appdev/process-framework-central/evaluation-reports` via script
  - [ ] Report customized with all evaluation findings, dimension scores, and recommendations
  - [ ] All dimension scores include supporting evidence (file paths, specific examples)
- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] IMP entries added to [Process Improvement Tracking](../../../process-framework-central/state-tracking/permanent/process-improvement-tracking.md) for each approved improvement
  - [ ] Each IMP entry links back to the evaluation report as source
- [ ] **Feedback form** completed per the [Task Execution Protocol → Feedback step](../../guides/framework/task-execution-protocol-guide.md#feedback-step) — task ID `PF-TSK-079`, context "Framework Evaluation".

## File Operations

| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | `appdev/process-framework-central/evaluation-reports/YYYYMMDD-framework-evaluation-{scope}.md` | Script | Evaluation report from template (PF-TEM-064) |
| **Updates** | [`process-improvement-tracking.md`](../../../../process-framework-central/state-tracking/permanent/process-improvement-tracking.md) | Script | Adds improvement entries via New-ProcessImprovement.ps1 |

## Next Tasks

- [**Process Improvement**](process-improvement-task.md) — Implement the IMP entries identified by the evaluation
- [**Structure Change**](structure-change-task.md) — If evaluation reveals structural reorganization needs
- [**New Task Creation Process**](new-task-creation-process.md) — If evaluation identifies missing tasks

<!-- merged from transition-registry entry: Framework Evaluation -->
### Prerequisites for Transition

- [ ] Evaluation scope defined and approved
- [ ] All selected dimensions evaluated with scores and evidence
- [ ] Evaluation report created via New-FrameworkEvaluationReport.ps1
- [ ] IMP entries registered for actionable findings

### Next Task Selection

- **Improvements needed**: → Process Improvement (to address IMP entries from evaluation)
- **Structural issues found**: → Structure Change (for reorganization needs)
- **Missing tasks identified**: → New Task Creation Process (to fill gaps)
- **No major issues**: → Return to development work

## Related Resources

- [Documentation Map](../../PF-documentation-map.md) — Central index of all framework artifacts
- [Process Framework Task Registry](../../infrastructure/process-framework-task-registry.md) — Task automation status overview
- [`task-creation` craft skill](../../../.claude/skills/task-creation/SKILL.md) — Expected task structure and quality standards
- [AI Tasks System](../../ai-tasks.md) — Task registry and workflow definitions
- [Feature Validation Guide](../../guides/05-validation/feature-validation-guide.md) — Analogous approach for code validation (reference for evaluation methodology)
