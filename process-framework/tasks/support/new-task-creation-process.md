---
id: PF-TSK-001
type: Process Framework
category: Task Definition
domain: agnostic
version: 1.8
created: 2025-07-06
updated: 2026-07-28
description: "Complete process for creating new tasks from concept to implementation-ready definition"
use_when: >-
  Creating new tasks for the framework. Triggers: 'create a new task', 'add a task definition', 'we need a task for X'.
triggers:
  - "create a new task"
  - "add a task definition"
  - "we need a task for X"
automation: full
scripts:
  - ../../scripts/file-creation/support/New-Task.ps1
trigger_status:
  - raw: "_(user request)_"
output_status:
  - raw: "`ai-tasks.md`, `PF-documentation-map.md` → task registered"
next_tasks:
  - task: process-improvement-task.md
    condition: "If task creation reveals process gaps or improvements needed"
---

# New Task Creation Process

> **▶ Execute this task under the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md).** This file holds only this task's specific content; the universal contract every task shares lives once in the protocol and is mandatory here.

## Purpose & Context

Complete process for creating a new task from concept to implementation-ready definition, including task definition creation, supporting infrastructure setup (directories, templates, guides), and multi-session implementation tracking.

## AI Agent Role

**Role**: Process Engineer
**Mindset**: Systematic, efficiency-focused, improvement-oriented
**Focus Areas**: Workflow optimization, automation opportunities, standardization, process completeness
**Communication Style**: Identify process bottlenecks and improvement opportunities, ask about workflow preferences and automation needs

## Context Requirements

- **Critical (Must Read):**

  - **Task Concept Description** - Human-provided description of the new task concept and its purpose
  - [`task-creation` craft skill](../../../.claude/skills/task-creation/SKILL.md) - the task-authoring craft (section-by-section customization judgment, generic-and-reusable standard, task-metadata schema reference), activated in Preparation Step 1 (Check Recommended Skills). Replaces the retired Task Creation Guide and **drives the customize-content steps in both modes.**
  - [`state-file-customization` craft skill](../../../.claude/skills/state-file-customization/SKILL.md) - the state-file craft (temp-state template-variant selection, phase customization, session planning), activated in Preparation Step 1; drives the customize-temp-state-file step (Full Mode)
  - [AI Tasks System](../../ai-tasks.md) - The generated routing tables (regenerated from task frontmatter by Build-TaskMetadata.ps1; not hand-edited)

- **Important (Load If Space):**

  - [Script Development Quick Reference](../../guides/support/script-development-quick-reference.md) - PowerShell execution patterns and parameter checking (**always check script parameters with `Get-Help <script> -Parameter *` before running**)
  - [`creation-script-development` craft skill](../../../.claude/skills/creation-script-development/SKILL.md) - the script-authoring craft (New-FrameworkDocument model, placeholder/registry/directory integration), activated in Preparation Step 1; for creating scripts when the task generates new files
  - [`template-development` craft skill](../../../.claude/skills/template-development/SKILL.md) - the template-design craft (principles, components, two-phase creation, copyable-instance archetype), activated in Preparation Step 1; for creating templates when needed
  - [Documentation Structure Guide](../../guides/framework/documentation-structure-guide.md) - For organizing and structuring documentation
  - [PF ID Registry](../../PF-id-registry.json) - For understanding and updating ID prefixes

- **Reference Only (Access When Needed):**
  - [Documentation Map](../../PF-documentation-map.md) - For updating with new artifacts
  - [Task Transition Registry](../../infrastructure/task-transition-registry.md) - Generated view of per-task "Transitioning FROM" sections (regenerated from each task's `## Next Tasks` subsections)
  - [Process Framework Task Registry](../../infrastructure/process-framework-task-registry.md) - Generated catalog (regenerated from task frontmatter + `## File Operations`; includes the `🔗 TRIGGER & OUTPUT` blocks and State File Trigger Index)
  - [Process Improvement Tracking](../../../process-framework-central/state-tracking/permanent/process-improvement-tracking.md) - For tracking infrastructure completion
  - [New-Task.ps1](../../scripts/file-creation/support/New-Task.ps1) - Script for creating task definitions
  - [New-TempTaskState.ps1](../../scripts/file-creation/support/New-TempTaskState.ps1) - Script for creating temporary state files
  - [New-Template.ps1](../../scripts/file-creation/support/New-Template.ps1) - Script for creating templates
  - [New-Guide.ps1](../../scripts/file-creation/support/New-Guide.ps1) - Script for creating guides

## Process

> **⚠️ MANDATORY: Create temporary state tracking file for multi-session implementation.**
>
> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

---

### Preparation

1. **Check Recommended Skills**: Read the active language-config (`languages-config/{language}/{language}-config.json`) and `project-config.json` for `recommended_skills` entries keyed to `new-task-creation-process`, and activate each bound craft skill available in the session:
   - **`task-creation`** — the **task-authoring craft** this task delegates to (section-by-section customization judgment, the generic-and-reusable standard, the task-metadata schema reference); drives the customize-content steps in both modes.
   - **`state-file-customization`** — the **state-file craft** (temp-state template-variant selection, phase customization, session planning); drives the customize-temp-state-file step in Full Mode.
   - **`creation-script-development`** — the **script-authoring craft** (New-FrameworkDocument model, placeholder/registry/directory integration); applies when the new task creates files (Full Mode document-creation infrastructure session).
   - **`template-development`** — the **template-design craft** (principles, components, two-phase creation, copyable-instance archetype); applies when the new task needs a template (Full Mode templates-and-guides session).

   If a bound skill is not listed in the session, read its `SKILL.md` directly under [`.claude/skills/`](../../../.claude/skills/) and apply it — that file is the canonical source the Skill tool loads, so a direct read is equivalent, not degraded. A craft is unavailable for this run only if its skill file is absent (the corresponding retired guides have no successors).

2. **Gather Task Concept**: Obtain clear description of the new task concept from human partner. Require him to take critical decisions
3. **Create Concept Document** (Recommended): Create a comprehensive concept document in `appdev/process-framework-central/proposals/[task-name]-concept.md` for human review before implementation
   - Include purpose, context, process outline, outputs, and integration considerations
   - Allow human partner to review and approve concept before proceeding
   - Reference concept document in temporary state tracking file
4. **Review Available Artifacts**: Examine what directories, templates, guides, and state files currently exist in the process framework
5. **Evaluate Task Requirements**: Determine which artifacts are actually needed for this specific task (not all tasks need all types of artifacts)

   > **Existing-artifacts reuse**: When supporting artifacts (template, guide, script, or output directory) already exist for the area and only the task definition is missing, this task is **supplementing an existing artifact family**, not building greenfield. Make a reuse-vs-create decision per artifact here in Step 5. **Reuse** means: link the artifact from the new task's Context Requirements / Related Resources, update the existing artifact to reference the new task back, and rename/update it in place rather than creating a duplicate (LinkWatcher follows renames automatically). The artifact-creation steps below — Lightweight Step 12L (its *Reused supporting artifacts* item) and Full-Mode Sessions 2–3 — carry this reuse branch.

6. **🚨 CHECKPOINT**: Present task concept summary, available artifacts review, and required artifacts to human partner for alignment

7. **🔍 Scope Assessment — Propose Approach to Human Partner**:

   Evaluate the following criteria:
   - Does this task create **new file types** as outputs?
   - Are **new templates, guides, or scripts** needed?
   - Will implementation require **multiple sessions**?

   Based on your evaluation, propose one of two modes to the human partner:

   | Criteria | → Lightweight Mode | → Full Mode |
   |----------|-------------------|-------------|
   | Creates new file types | No | Yes |
   | Needs new templates/guides/scripts | No | Yes |
   | Requires multiple sessions | No | Yes |

   **If ALL answers are "No"** → Propose **Lightweight Mode** to the human partner with your reasoning.
   **If ANY answer is "Yes"** → Propose **Full Mode** (current multi-session process).

   > **🚨 MANDATORY**: The AI agent MUST present the scope assessment and proposed mode to the human partner and receive explicit approval before proceeding. The human partner may override the recommendation in either direction.

   - If **Lightweight Mode approved** → Continue with [Lightweight Mode Process](#lightweight-mode-process) below
   - If **Full Mode approved** → Continue with [Full Mode Process](#full-mode-process) below

---

## Lightweight Mode Process

> **When to use**: Approved by human partner after Scope Assessment. For tasks that do NOT create new file types and do NOT require new templates, guides, or scripts. Completes in a single session.

### Lightweight Execution

8L. **Create Task Definition**: Use [New-Task.ps1](../../scripts/file-creation/support/New-Task.ps1) and the [`task-creation` craft skill](../../../.claude/skills/task-creation/SKILL.md)
   ```bash
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/support/New-Task.ps1 -TaskName "Your Task Name" -WorkflowPhase "04-implementation" -Description "Your description" -Confirm:\$false
   ```
   > **📝 NAMING**: Rename the generated file to include `-task` suffix (e.g., `your-task-name.md` → `your-task-name-task.md`)

9L. **🚨 CRITICAL: Customize Task Definition Content** — Applying the [`task-creation` craft skill](../../../.claude/skills/task-creation/SKILL.md), customize all placeholder sections:
   - **Context Requirements** — Critical, Important, and Reference inputs with actual links
   - **Process** — Detailed step-by-step instructions (Preparation, Execution, Finalization)
   - **Outputs** — Specific outputs with exact file locations and formats
   - **State Tracking** — Link to actual state files this task updates
   - **Task Completion Checklist** — Customized verification items
   - **Next Tasks** — Link to actual follow-up tasks
   - **AI Agent Role** — Appropriate professional role after "Purpose & Context" section
   > **🌍 IMPORTANT**: Make tasks **generic and reusable** — use category references and examples instead of project-specific details — and **lean**: new tasks start edge-file-less; edge-case prose never lands in the task body (PF-PRO-059 — see the skill's lean-core standard).

9L-a. **Search for Recommended Skills**: Search for Claude Code skills (e.g., from the [Anthropic skills repository](https://github.com/anthropics/skills) or other known skill sources) that could support the new task's work. If a relevant skill exists, add a "Check Recommended Skills" step as the first Preparation step in the task definition, referencing both `languages-config` and `project-config.json` `recommended_skills` entries keyed to the task's slug (filename without `.md`). Also note the skill in the seed mapping table in the [Project Initiation task](../00-setup/project-initiation-task.md)'s recommended-skills step if it is broadly applicable.
   - **Author-a-craft-skill branch**: when no existing skill covers the new task's craft *and* the task carries substantial recurring judgment (decision rules, quality gates, worked-example-shaped know-how distinct from its step sequence), author a **framework craft skill** for it per the [Craft Skill Authoring guide](../../guides/support/craft-skill-authoring-guide.md) — in this session if scope allows, else as a filed follow-up. Craft skills live under `blueprint/.claude/skills/`, are `user-invocable: false`, bind via `recommended_skills` with `kind: "craft"`, and require their agent-coupling-registry row in the same change.

10L. **🚨 CHECKPOINT**: Present customized task definition to human partner for review

11L. **Populate task-metadata frontmatter + authored sections, then regenerate** (PF-PRO-042): the new task's own frontmatter and two authored body sections are the single source of truth — the ai-tasks.md tables, both infrastructure registries, and the tasks/README catalog are generated from them by `Build-TaskMetadata.ps1` and are never hand-edited. Per the template's TASK METADATA SCHEMA comment, fill in:
   - **Frontmatter**: `complexity` (or `frequency` for cyclical) and `automation` are seeded by `New-Task.ps1`; add the nested fields where applicable — `triggers`, `scripts`, `trigger_status`, `output_status`, `next_tasks`.
   - **`## File Operations`** table — every file the task creates/updates (aggregated into the task's registry catalog entry).
   - **`## Next Tasks`** transition subsections (Prerequisites for Transition / Next Task Selection / Preparation for Next Task) — aggregated into the task-transition-registry.

   Then regenerate the projections (`New-Task.ps1` already ran the first one at creation; re-run it to pick up the fields you just added):
   ```bash
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/validation/Build-TaskMetadata.ps1
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/validation/Build-DocumentationMap.ps1
   ```
   `Build-TaskMetadata.ps1 -ReportMissing` flags any required field still missing; both generators have a `-Check` pre-commit gate that blocks commits on drift.

12L. **Update the manual residue** — the parts that are NOT generated from the new task's own file:
   - **Other task definitions**: Grep for tasks that precede or follow the new one. Add the new task to *their* `next_tasks` frontmatter and Related Resources sections, then regenerate (their transition projections change too). You are editing their source files, not the registries.
   - **Hand-written ai-tasks.md prose**: the decision tree, Common Workflows, and workflow diagrams sit outside the generated table regions — update them if the new task changes a workflow.
   - **Registry trigger-chain diagrams**: these live in a hand-written region of the task registry — update if the trigger chain changed.
   - **Reused supporting artifacts**: for any template, guide, or script reused rather than newly created, ensure each references the new task (Related Resources section and/or `related_task` frontmatter).

13L. **Framework Evaluation (separate session)**: Run [Framework Evaluation](framework-evaluation.md) (PF-TSK-079) targeting the new task in a dedicated session to validate completeness, consistency, and integration quality. The new task must **not** be used in production workflows until Framework Evaluation passes.

14L. **🚨 MANDATORY FINAL STEP**: Complete the [Lightweight Task Completion Checklist](#lightweight-task-completion-checklist) below

### Lightweight Outputs

- **Task Definition File** — Generated and fully customized task definition with AI Agent Role
- **✅ Regenerated projections** — process-framework/ai-tasks.md tables, both infrastructure registries, and the tasks/README catalog are regenerated by New-Task.ps1 via Build-TaskMetadata.ps1; PF-documentation-map.md is refreshed separately by Build-DocumentationMap.ps1

> **Not produced in Lightweight Mode**: No temp state file, no concept document, no templates, no guides, no scripts, no directory structures, no ID registry changes.

---

## Full Mode Process

> **When to use**: Approved by human partner after Scope Assessment. For tasks that create new file types or require new templates, guides, or scripts. Spans multiple sessions.

### Execution

8. **Create Temporary State Tracking File**: Use the [New-TempTaskState.ps1](../../scripts/file-creation/support/New-TempTaskState.ps1) script to create tracking file with implementation roadmap

   ```bash
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/support/New-TempTaskState.ps1 -TaskName "Task Name" -Description "Brief task description" -Confirm:\$false
   ```

   **Reference**: [`state-file-customization` craft skill](../../../.claude/skills/state-file-customization/SKILL.md)

9. **🚨 CRITICAL: Customize Temporary State File** - Applying the [`state-file-customization` craft skill](../../../.claude/skills/state-file-customization/SKILL.md) (activated in Preparation Step 1), customize the generated temp state file:

   - **Task Overview** - Update task name, type, and ID information
   - **Infrastructure Analysis** - Document which artifacts are needed vs. available for reuse
   - **Required Artifacts Table** - List specific templates, guides, scripts, directories needed for this task
   - **File Creation Requirements** - Determine whether the task creates new files (determines if document creation infrastructure is needed)
   - **Implementation Roadmap** - Adjust phases and priorities based on task requirements
   - **Session Planning** - Customize for expected workflow and dependencies

   > **Reference**: This transforms the meta-template into a functional tracking document for multi-session implementation

10. **Execute Multi-Session Implementation**: Follow the structured roadmap in the temporary state file across multiple sessions:

   **Session 1 - Core Task Infrastructure:**

   - Create task definition using [New-Task.ps1](../../scripts/file-creation/support/New-Task.ps1) and the [`task-creation` craft skill](../../../.claude/skills/task-creation/SKILL.md)
     ```bash
     pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/support/New-Task.ps1 -TaskName "Your Task Name" -WorkflowPhase "04-implementation" -Description "Your description" -Confirm:\$false
     ```
     > **Note**: The script emits a single-line `Customization required — see <guide>` pointer on success, so real warnings (section-not-found, ID collision, etc.) are not drowned in alarm noise — see `process-framework/templates/support/document-creation-script-template.ps1` Pattern 1 for the canonical recipe. The generated file is a meta-template requiring full Phase-2 content customization.
     > **✨ ENHANCED**: After creating the file, the script regenerates the task-metadata projections (ai-tasks.md tables, both registries, tasks/README) via Build-TaskMetadata.ps1. PF-documentation-map.md is refreshed separately by Build-DocumentationMap.ps1.
     > **📝 NAMING**: Rename the generated file to include `-task` suffix (e.g., `your-task-name.md` → `your-task-name-task.md`) for easy identification

   - **🚨 CRITICAL: Phase 2 - Customize Task Definition Content** - Applying the [`task-creation` craft skill](../../../.claude/skills/task-creation/SKILL.md), customize all placeholder sections in the generated task file:
     - **Context Requirements** - Critical, Important, and Reference inputs with actual links to files
     - **Process** - Detailed step-by-step instructions (Preparation, Execution, Finalization) specific to this task
     - **Outputs** - Specific outputs with exact file locations and formats
     - **State Tracking** - Link to actual state files that this task updates
     - **Task Completion Checklist** - Customize verification items for this specific task
     - **Next Tasks** - Link to actual follow-up tasks in the workflow
     > **Reference**: the two-phase model in the [`task-creation` craft skill](../../../.claude/skills/task-creation/SKILL.md) ("The two-phase model") - this phase transforms the meta-template into a functional task definition
     >
     > **🌍 IMPORTANT**: Make tasks **generic and reusable** - use category references and examples (e.g., "business types: B2B, B2C, SaaS") instead of project-specific details. Use placeholders in commands. Keep them **lean**: new tasks start edge-file-less; edge-case prose never lands in the task body (PF-PRO-059). See the [`task-creation` craft skill](../../../.claude/skills/task-creation/SKILL.md) for detailed guidance.

   - **Search for Recommended Skills**: Search for Claude Code skills that could support the new task's work. If a relevant skill exists, add a "Check Recommended Skills" step as the first Preparation step in the task definition, referencing both `languages-config` and `project-config.json` `recommended_skills` entries keyed to the task's slug (filename without `.md`). Also note the skill in the seed mapping table in the [Project Initiation task](../00-setup/project-initiation-task.md)'s recommended-skills step if broadly applicable. When no existing skill covers a substantial task craft, author a framework craft skill per the [Craft Skill Authoring guide](../../guides/support/craft-skill-authoring-guide.md) (see Step 9L-a's author-a-craft-skill branch).

   - **🚨 CHECKPOINT**: Present customized task definition to human partner for review before proceeding to infrastructure setup
   - **Assign AI Agent Role**: Add appropriate professional role assignment to the task definition after "Purpose & Context" section
     - Select from established professional roles (Senior Software Engineer, Software Architect, Debugging Specialist, Code Quality Auditor, Product Analyst, Technical Lead, DevOps Engineer, QA Engineer, Business Analyst, Legal Requirements Specialist, etc.)
     - Use format: Role, Mindset, Focus Areas, Communication Style (keep to 3-4 lines maximum)
   - Evaluate if task creates new files as outputs (determines if document creation infrastructure is needed)

   **Session 2 - Document Creation Infrastructure (conditional):**

   > **⚠️ CONDITIONAL**: Only execute if task creates new files as outputs

   > **Reuse**: If the output directory, creation script, template, or guide already exists for the area, reuse and link it (and update it to reference the new task) rather than creating a new one — see *Existing-artifacts reuse* in Preparation. The Session 2–3 "create" steps then become "verify + link" steps.

   - Create directory structure for task outputs (consider using subdirectories for better organization)
   - Create document creation script applying the [`creation-script-development` craft skill](../../../.claude/skills/creation-script-development/SKILL.md) and using the [Document Creation Script Template](../../templates/support/document-creation-script-template.ps1)
     - Use `DirectoryType` parameter for ID registry-based directory resolution
     - Configure subdirectory mappings in ID registry if needed
   - Update [PF ID Registry](../../PF-id-registry.json) with new ID prefix for file types created by task
   - **Register the new document creation script for soak verification** with `Register-SoakScript -ScriptId <relative-path-from-project-root> -ScriptPath <absolute-path>` (loaded via `Common-ScriptHelpers`). The script's first `$DefaultSoakCounter` (default 3) successful real invocations must then call `Confirm-SoakInvocation -Outcome success` after agent verification of the on-disk effects — see [`script-soak-tracking.md`](../../../../process-framework-central/state-tracking/permanent/script-soak-tracking.md) and [PF-PRO-028 Script Self-Verification](../../../process-framework-central/proposals/old/script-self-verification.md). This explicit register is **required, not redundant**: a creation script delegating to `New-FrameworkDocument` has its in-wrapper `Register-SoakScript` no-op under `-WhatIf`, and its tests are correctly all `-WhatIf`, so it never self-registers — confirm the row appeared with `Get-SoakStatus`.

   **Session 3 - Templates and Craft Skills:**

   - Create task-specific template applying the [`template-development` craft skill](../../../.claude/skills/template-development/SKILL.md) and using [New-Template.ps1](../../scripts/file-creation/support/New-Template.ps1) (if task creates files)
     ```bash
     pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/support/New-Template.ps1 -TemplateName "Your Template Name" -TemplateDescription "Template description" -DocumentPrefix "PF-XXX" -DocumentCategory "YourCategory" -Confirm:\$false
     ```
     > **Note**: The script emits a single-line `Customization required — see <guide>` pointer on success; the generated file is a meta-template requiring content customization. Update the path to match your actual project location. Replace `PF-XXX` with the appropriate document prefix and `YourCategory` with the document category.

   - Author the template's customization craft as a **craft skill** per the [Craft Skill Authoring Guide](../../guides/support/craft-skill-authoring-guide.md) (PF-GDE-077) — which covers authoring (via `skill-creator`) and wiring it into the new task's Check Recommended Skills step (if task creates files)

     - **Purpose**: Teach an agent how to *fill in* the template the task's script creates — customization decision points, per-section judgment, worked examples
     - **NOT**: a `New-Guide.ps1` guide (customization craft is a skill, never a guide), and not task-workflow execution docs (those live in the task definition)

   **Session 4 - Metadata Projection & Cross-Cutting:**

   - **Populate task-metadata frontmatter + authored sections, then regenerate** (PF-PRO-042): the ai-tasks.md tables, both infrastructure registries, and the tasks/README catalog are generated from the new task's frontmatter + `## File Operations` + `## Next Tasks` transition subsections — never hand-edited. Fill the nested frontmatter (`triggers`, `scripts`, `trigger_status`, `output_status`, `next_tasks`) and both authored sections per the template's TASK METADATA SCHEMA comment, then regenerate:
     ```bash
     pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/validation/Build-TaskMetadata.ps1
     pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/validation/Build-DocumentationMap.ps1
     ```
     `Build-TaskMetadata.ps1 -ReportMissing` flags missing required fields; both generators' `-Check` pre-commit gates block drift.
   - **Update the manual residue** (NOT generated from the new task's own file):
     - **Other task definitions**: add the new task to *their* `next_tasks` frontmatter and Related Resources, then regenerate (their transition projections change too).
     - **Hand-written ai-tasks.md prose**: decision tree, Common Workflows, workflow diagrams — update if the new task changes a workflow.
     - **Registry trigger-chain diagrams** (hand-written region): update if the trigger chain changed.
     - **Reused supporting artifacts**: ensure each reused template/guide/script references the new task (Related Resources and/or `related_task` frontmatter).

   **Session 5 - Framework Evaluation (mandatory, separate session):**

   - Run [Framework Evaluation](framework-evaluation.md) (PF-TSK-079) targeting the new task to validate completeness, consistency, and integration quality
   - The new task must **not** be used in production workflows until Framework Evaluation passes
   > **⚠️ MANDATORY**: This session must run as a dedicated session after all task infrastructure is finalized. Do not combine with Session 4.

11. **Track Progress**: Update the temporary state file after each session with:
   - Completed items and their status
   - Issues encountered and resolutions
   - Next session planning
   - Placeholder component tracking

### Finalization

12. **Update Documentation Map**: Add all new artifacts to the [documentation map](../../PF-documentation-map.md)
13. **Verify Infrastructure Completeness**: Ensure all required directories and placeholder files exist
14. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Outputs

### Preparation Outputs (Optional but Recommended)

- **Task Concept Document** - Comprehensive concept document in `appdev/process-framework-central/proposals/[task-name]-concept.md` for human review and approval

### Session 1 Outputs (Core Infrastructure)

- **Task Definition File** - Generated task definition in `/process-framework/tasks/[type]/[task-name].md` with assigned AI Agent Role
- **Temporary State Tracking File** - Multi-session implementation tracker in `process-framework-central/state-tracking/temporary/temp-task-creation-[task-name].md`
- **✅ Regenerated projections** - New-Task.ps1 regenerates the task-metadata projections via Build-TaskMetadata.ps1:
  - **AI Tasks Registry** - New task row in [ai-tasks.md](../../ai-tasks.md) (generated table region)
  - **Tasks README** - New task in the [tasks/README.md](../README.md) generated catalog
  - **Both infrastructure registries** - [process-framework-task-registry.md](../../infrastructure/process-framework-task-registry.md) and [task-transition-registry.md](../../infrastructure/task-transition-registry.md) regenerated from the task's frontmatter + authored sections
  - **Documentation Map** - refreshed separately by Build-DocumentationMap.ps1 (from the task's `description:` frontmatter)
- **Required Directory Structure** - Only the directories actually needed for task outputs (if task creates new files)

### Session 2 Outputs (Document Creation Infrastructure - conditional)

> **⚠️ CONDITIONAL**: Only produced if task creates new files as outputs

- **Task Output Directory Structure** - Directories created for storing task outputs
- **Document Creation Script** - PowerShell script for generating files created by the task (applying the [`creation-script-development` craft skill](../../../.claude/skills/creation-script-development/SKILL.md) and using [document-creation-script-template.ps1](../../templates/support/document-creation-script-template.ps1))
- **Updated ID Registry** - New ID prefix added to the appropriate [ID registry](../../PF-id-registry.json) for file types created by task

### Session 3 Outputs (Templates and Craft Skills)

- **Task-Specific Template** - Template for files generated by the task (created applying the [`template-development` craft skill](../../../.claude/skills/template-development/SKILL.md) and using [New-Template.ps1](../../scripts/file-creation/support/New-Template.ps1), only if task creates files)
- **Template Customization Craft Skill** - A craft skill teaching an agent how to fill in the template the task's script creates, authored per the [Craft Skill Authoring Guide](../../guides/support/craft-skill-authoring-guide.md) (PF-GDE-077) and bound to the new task's Check Recommended Skills step (only if task creates files)
  - **Purpose**: Helps an agent customize the template the script creates — decision points, per-section judgment
  - **NOT**: A guide (customization craft is a skill), and not task-workflow execution docs

### Session 4 Outputs (Documentation)

- **Updated Documentation Map** - All new artifacts registered in [PF-documentation-map.md](../../PF-documentation-map.md)

### Session 5 Outputs (Framework Evaluation)

- **Framework Evaluation Report** - Evaluation of the new task for completeness, consistency, and integration quality via [Framework Evaluation](framework-evaluation.md) (PF-TSK-079)

### Final Outputs (All Sessions Complete)

- **Updated Documentation Map** - All new artifacts registered in the [documentation map](../../PF-documentation-map.md)
- **Complete Task Infrastructure** - Fully functional task with all supporting components
- **Deleted Temporary State File** - Temporary tracking file removed after completion

## State Tracking

The following state files are updated as part of this task:

### ✅ Regenerated Projections (via New-Task.ps1 → Build-TaskMetadata.ps1)

- [AI Tasks System](../../ai-tasks.md) - **GENERATED**: task table regions regenerated from task frontmatter
- [Tasks README](../README.md) - **GENERATED**: catalog region regenerated
- [Process Framework Task Registry](../../infrastructure/process-framework-task-registry.md) - **GENERATED**: catalog / automation summary / trigger index regenerated
- [Task Transition Registry](../../infrastructure/task-transition-registry.md) - **GENERATED**: per-task transition sections regenerated
- [Documentation Map](../../PF-documentation-map.md) - refreshed separately by Build-DocumentationMap.ps1

### 🔧 Manual Updates Required (Full Mode only)

- **Temporary State File** - Create `temp-task-creation-[task-name].md` to track implementation progress across sessions

## ⚠️ MANDATORY Task Completion Checklist

> Completion discipline, output verification, and the feedback form are governed by the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md) (Phase C). The items below are the **task-specific** verifications that plug into it.

> **Note**: Use the checklist matching the mode approved during Scope Assessment.

### Lightweight Task Completion Checklist

> **Use this checklist when Lightweight Mode was approved by the human partner.**

- [ ] **Craft skills checked**: `recommended_skills` consulted at Preparation Step 1; the bound craft skills (`task-creation`, plus `state-file-customization` / `creation-script-development` / `template-development` where their steps applied) activated when available (or their absence noted)
- [ ] **Scope Assessment Documented**: Human partner approved Lightweight Mode
- [ ] **Task Definition Verified**:
  - [ ] Task definition file generated using [New-Task.ps1](../../scripts/file-creation/support/New-Task.ps1)
  - [ ] **🚨 Task definition content fully customized** — All placeholder sections replaced with task-specific content:
    - [ ] Context Requirements lists actual files with links
    - [ ] Process section has detailed step-by-step instructions
    - [ ] Outputs section specifies exact deliverables and locations
    - [ ] State Tracking links to actual state files
    - [ ] Task Completion Checklist customized for this task
    - [ ] Next Tasks links to actual follow-up tasks
    - [ ] **🌍 Task is generic and reusable** — Uses category references and examples instead of project-specific details
  - [ ] **AI Agent Role assigned** with appropriate professional role, mindset, focus areas, and communication style
- [ ] **Metadata projection verified**: the new task's frontmatter (`triggers`/`scripts`/`trigger_status`/`output_status`/`next_tasks` where applicable), `## File Operations`, and `## Next Tasks` transition subsections are filled in; `Build-TaskMetadata.ps1` and `Build-DocumentationMap.ps1` regenerated; both `-Check` gates green; `Build-TaskMetadata.ps1 -ReportMissing` reports no gap for the new task
- [ ] **Manual residue completed** (not generated from the new task's own file):
  - [ ] Other task definitions updated — the new task added to *their* `next_tasks` frontmatter and Related Resources where appropriate, and projections regenerated
  - [ ] Hand-written [ai-tasks.md](../../ai-tasks.md) prose (decision tree, Common Workflows, workflow diagrams) updated if the new task changes a workflow
  - [ ] Registry trigger-chain diagrams (hand-written region) updated if the trigger chain changed
- [ ] **Framework Evaluation Completed**:
  - [ ] [Framework Evaluation](framework-evaluation.md) (PF-TSK-079) run targeting the new task in a dedicated session
  - [ ] Evaluation confirms completeness, consistency, and integration quality
  - [ ] Any issues identified during evaluation are resolved
- [ ] **Feedback form** completed per the [Task Execution Protocol → Feedback step](../../guides/framework/task-execution-protocol-guide.md#feedback-step) — task ID `PF-TSK-001`, context "New Task Creation Process (Lightweight)".
  - **⚠️ IMPORTANT**: Evaluate the New Task Creation Process itself (PF-TSK-001), not the task you created.

---

### Full Mode Task Completion Checklist

> **Use this checklist when Full Mode was approved by the human partner.** Complete verification applies to the ENTIRE task across all sessions.

#### Session 1 Completion (Core Infrastructure)

- [ ] **Craft skills checked**: `recommended_skills` consulted at Preparation Step 1; the bound craft skills (`task-creation`, plus `state-file-customization` / `creation-script-development` / `template-development` where their sessions applied) activated when available (or their absence noted)
- [ ] **Core Outputs Verified**:
  - [ ] Task definition file generated using [New-Task.ps1](../../scripts/file-creation/support/New-Task.ps1) and the [`task-creation` craft skill](../../../.claude/skills/task-creation/SKILL.md)
  - [ ] **🚨 Phase 2: Task definition content fully customized** - All placeholder sections replaced with task-specific content:
    - [ ] Context Requirements lists actual files with links
    - [ ] Process section has detailed step-by-step instructions
    - [ ] Outputs section specifies exact deliverables and locations
    - [ ] State Tracking links to actual state files
    - [ ] Task Completion Checklist customized for this task
    - [ ] Next Tasks links to actual follow-up tasks
    - [ ] **🌍 Task is generic and reusable** - Uses category references and examples instead of project-specific details, placeholders in commands
  - [ ] **AI Agent Role assigned** to task definition after "Purpose & Context" section with appropriate professional role, mindset, focus areas, and communication style
  - [ ] Temporary state tracking file created using [New-TempTaskState.ps1](../../scripts/file-creation/support/New-TempTaskState.ps1) script
  - [ ] File creation evaluation completed (CREATES_FILES or NO_FILES_CREATED decision made)
  - [ ] ✅ **REGENERATED**: ai-tasks.md tables, tasks/README catalog, and both infrastructure registries regenerated by the script via Build-TaskMetadata.ps1 (PF-documentation-map.md refreshed separately by Build-DocumentationMap.ps1)

#### Session 2 Completion (Document Creation Infrastructure - conditional)

> **⚠️ CONDITIONAL**: Only verify if task creates new files as outputs

- [ ] **Document Creation Infrastructure Verified**:
  - [ ] Task output directory structure created
  - [ ] Document creation script created applying the [`creation-script-development` craft skill](../../../.claude/skills/creation-script-development/SKILL.md) and using the [Document Creation Script Template](../../templates/support/document-creation-script-template.ps1)
  - [ ] ID registry updated with new prefix for file types created by task
  - [ ] Script tested and functional
  - [ ] Script registered for soak verification — entry visible in [`script-soak-tracking.md`](../../../../process-framework-central/state-tracking/permanent/script-soak-tracking.md) (verify via `Get-SoakStatus -ScriptId <relative-path>`)

#### Session 3 Completion (Templates and Craft Skills)

- [ ] **Templates and Craft Skills Verified**:
  - [ ] Task-specific template created applying the [`template-development` craft skill](../../../.claude/skills/template-development/SKILL.md) and using [New-Template.ps1](../../scripts/file-creation/support/New-Template.ps1) (if task creates files)
  - [ ] Template customization craft authored as a **craft skill** per the [Craft Skill Authoring Guide](../../guides/support/craft-skill-authoring-guide.md) (PF-GDE-077) and bound to the new task's Check Recommended Skills step (if task creates files)
  - [ ] Craft skill teaches template customization, NOT task execution workflow
  - [ ] Template and craft skill properly integrated with the task definition

#### Session 4 Completion (Documentation)

- [ ] **Metadata Projection Verified**:
  - [ ] New task's frontmatter + `## File Operations` + `## Next Tasks` transition subsections filled in; `Build-TaskMetadata.ps1` + `Build-DocumentationMap.ps1` regenerated; both `-Check` gates green; `-ReportMissing` clean for the new task
- [ ] **Manual Residue Completed** (not generated from the new task's own file):
  - [ ] Other task definitions updated — the new task added to *their* `next_tasks` frontmatter and Related Resources where appropriate, and projections regenerated
  - [ ] Hand-written [ai-tasks.md](../../ai-tasks.md) prose (decision tree, Common Workflows, workflow diagrams) updated if the new task changes the workflow
  - [ ] Registry trigger-chain diagrams (hand-written region) updated if the trigger chain changed

#### Session 5 Completion (Framework Evaluation)

- [ ] **Framework Evaluation Completed**:
  - [ ] [Framework Evaluation](framework-evaluation.md) (PF-TSK-079) run targeting the new task in a dedicated session
  - [ ] Evaluation confirms completeness, consistency, and integration quality
  - [ ] Any issues identified during evaluation are resolved

#### Final Task Completion (All Sessions)

- [ ] **All Infrastructure Complete**:
  - [ ] All components from temporary state file implemented (no placeholders remaining)
  - [ ] [Documentation Map](../../PF-documentation-map.md) updated with all new artifacts
  - [ ] Temporary state tracking file deleted (task infrastructure complete)
  - [ ] Task fully functional and ready for use
- [ ] **Feedback form** completed per the [Task Execution Protocol → Feedback step](../../guides/framework/task-execution-protocol-guide.md#feedback-step) — task ID `PF-TSK-001`, context "New Task Creation Process (Full Mode)".
  - **⚠️ IMPORTANT**: Evaluate the New Task Creation Process itself (PF-TSK-001), not the task you created. Assess how well the process worked, the effectiveness of the tools used (New-Task.ps1, guides, etc.), and the clarity of the process steps.

## File Operations

| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | `[kebab-case-task-name].md` | [`New-Task.ps1`](../../scripts/file-creation/support/New-Task.ps1) | New task document with standardized structure |
| **Creates** | Temporary task creation state file (Full Mode) | `New-TempTaskState.ps1` (conditional) | Multi-session tracking in resolved `state-tracking/temporary/` (via `Get-StateTrackingContext` — appdev: `process-framework-central/state-tracking/temporary/`; projects: `doc/state-tracking/temporary/`) |
| **Updates** | [`ai-tasks.md`](../../ai-tasks.md) | `New-Task.ps1` → `Build-TaskMetadata.ps1` | Regenerate the per-category task table regions from task frontmatter (PF-PRO-042) |
| **Updates** | [`tasks/README.md`](../README.md) | `New-Task.ps1` → `Build-TaskMetadata.ps1` | Regenerate the catalog region |
| **Updates** | [`process-framework-task-registry.md`](../../infrastructure/process-framework-task-registry.md) | `New-Task.ps1` → `Build-TaskMetadata.ps1` | Regenerate catalog entry / automation summary / trigger index from the task's frontmatter + `## File Operations` |
| **Updates** | [`task-transition-registry.md`](../../infrastructure/task-transition-registry.md) | `New-Task.ps1` → `Build-TaskMetadata.ps1` | Regenerate the task's "Transitioning FROM" section from its `## Next Tasks` subsections |
| **Updates** | [`PF-documentation-map.md`](../../PF-documentation-map.md) | Manual via `Build-DocumentationMap.ps1` | Refresh from the task's `description:` frontmatter (separate generator) |
| **Updates** | [`script-soak-tracking.md`](../../../../process-framework-central/state-tracking/permanent/script-soak-tracking.md) | Manual via `Register-SoakScript` | Conditional (Session 2 only): if the task creates a new document creation script, register it for 5-invocation soak verification (PF-PRO-028). |

## Next Tasks

### Lightweight Mode — Next Tasks

- **[Framework Evaluation](framework-evaluation.md)** (PF-TSK-079) — Mandatory quality gate in a separate session before the new task can be used in production workflows
- **New Task Usage** — The new task is ready for use after Framework Evaluation passes

### Full Mode — Next Tasks

- **Continue Multi-Session Implementation** — Use the temporary state tracking file to continue implementation across sessions:
  - Session 2: Document creation infrastructure (if task creates new files)
  - Session 3: Templates and craft skills creation
  - Session 4: Metadata projection and cross-cutting updates
  - Session 5: Framework Evaluation (PF-TSK-079) — mandatory quality gate before task can be used
- **Track Progress** — Update temporary state file after each session with completed items and next steps
- **Delete Temporary State File** — Remove the temporary tracking file once all infrastructure is complete and functional

### Follow-Up Tasks (Both Modes)

- [**Process Improvement**](process-improvement-task.md) - If task creation reveals process gaps or improvements needed
- **New Task Usage** - Once complete, the new task can be used for its intended purpose

<!-- merged from transition-registry entry: New Task Creation Process -->
### Prerequisites for Transition

- [ ] New task definition created
- [ ] Task integrated into framework
- [ ] Task documentation completed
- [ ] Task transition patterns defined

### Next Task Selection

- **Always**: → Update Task Transition Guide (this document) to include new task

## Related Resources

### Core Guides

- [`task-creation` craft skill](../../../.claude/skills/task-creation/SKILL.md) - the task-authoring craft (replaces the retired Task Creation Guide); activated by the Check Recommended Skills step
- [`state-file-customization` craft skill](../../../.claude/skills/state-file-customization/SKILL.md) - the state-file craft (replaces the retired Temporary State File Customization Guide); activated by the Check Recommended Skills step
- [`creation-script-development` craft skill](../../../.claude/skills/creation-script-development/SKILL.md) - the script-authoring craft (replaces the retired Document Creation Script Development Guide); activated by the Check Recommended Skills step
- [`template-development` craft skill](../../../.claude/skills/template-development/SKILL.md) - the template-design craft (replaces the retired Template Development Guide); activated by the Check Recommended Skills step
- [Documentation Structure Guide](../../guides/framework/documentation-structure-guide.md) - Guide for organizing and structuring documentation

### Automation Scripts

- [New-Task.ps1](../../scripts/file-creation/support/New-Task.ps1) - Script for creating task definitions
- [New-TempTaskState.ps1](../../scripts/file-creation/support/New-TempTaskState.ps1) - Script for creating temporary state tracking files
- [New-Template.ps1](../../scripts/file-creation/support/New-Template.ps1) - Script for creating templates
- [New-Guide.ps1](../../scripts/file-creation/support/New-Guide.ps1) - Script for creating guides

### Templates

- [Task Template](../../templates/support/task-template.md) - Template for creating task definitions
- [Temporary Task State Template](../../templates/support/temp-task-creation-state-template.md) - Template for multi-session state tracking
- [Document Creation Script Template](../../templates/support/document-creation-script-template.ps1) - Template for creating PowerShell scripts

### Related Tasks

- [Process Improvement Task](process-improvement-task.md) - For implementing infrastructure components over time
