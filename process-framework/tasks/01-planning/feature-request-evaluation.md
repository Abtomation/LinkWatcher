---
id: PF-TSK-067
type: Process Framework
category: Task Definition
domain: agnostic
version: 1.7
created: 2026-02-19
updated: 2026-08-04
change_notes: "v1.6 - PF-IMP-1592 BL-5 residue removal: Steps 16-18 scope/dimension/state-file-customization craft collapsed to enhancement-scoping reference pointers; the live-task Referenced-Task-Doc verification stays task-side"
description: "Classify change requests as new features or enhancements, assess new-feature complexity tier, scope enhancements, and create Enhancement State Tracking Files"
complexity: medium
use_when: >-
  **ENTRY POINT for all change requests** — classifies as new feature or enhancement, routes to correct workflow. For new features: adds to tracking, assesses the complexity tier inline (embedded procedure), and creates the tier-correct implementation state file. For enhancements: creates scoped Enhancement State Tracking File. Triggers: 'new feature request', 'classify this change request', 'scope this enhancement'.
triggers:
  - "new feature request"
  - "classify this change request"
  - "scope this enhancement"
automation: semi
scripts:
  - ../../scripts/update/Update-FeatureRequest.ps1
  - ../../scripts/file-creation/04-implementation/New-EnhancementState.ps1
  - ../../scripts/file-creation/01-planning/New-Assessment.ps1
  - ../../scripts/update/Update-FeatureTrackingFromAssessment.ps1
  - ../../scripts/file-creation/01-planning/New-Exploration.ps1
  - ../../scripts/update/Update-BatchFeatureStatus.ps1
trigger_status:
  - file: feature-request-tracking.md
    status: "📥 Submitted"
output_status:
  - raw: "`feature-request-tracking.md` → `✅ Completed`; `feature-tracking.md` → (new feature) tier emoji + post-assessment status (`📋 Needs FDD` T2+; `🗄️`/`🔌`/`🎨`/`🔧 Needs Impl Plan` T1 per design flags; retrospective onboarding → `🔎 Needs Test Scoping`) or `🔄 Needs Enhancement` + state file link (enhancement) or `🔬 Needs Technical Exploration` (blocked on a research question); `technical-exploration-tracking.md` → `📥 Queued` (when blocked); `user-workflow-tracking.md` → adds/maps workflows"
next_tasks:
  - task: ../04-implementation/feature-enhancement.md
    condition: "Execute the Enhancement State Tracking File created by this task (enhancement path)"
  - task: technical-exploration-task.md
    condition: "Feature diverted to 🔬 Needs Technical Exploration — a filed research question must resolve before it can advance"
  - task: ../02-design/fdd-creation-task.md
    condition: "New feature assessed Tier 2+ — create the Functional Design Document (new feature path)"
  - task: ../04-implementation/feature-implementation-planning-task.md
    condition: "New feature assessed Tier 1 with no design flags — proceed to implementation planning (new feature path)"
---

# Feature Request Evaluation

> **▶ Execute this task under the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md).** This file holds only this task's specific content; the universal contract every task shares lives once in the protocol and is mandatory here.

## Purpose & Context

This task evaluates incoming change requests to determine whether they represent new features or enhancements to existing features. For enhancements, it identifies the target feature (with human approval), assesses scope using practical criteria, and produces a scoped Enhancement State Tracking File that guides the Feature Enhancement task.

## AI Agent Role

**Role**: Change Request Analyst
**Mindset**: Classification-focused, scope-aware, existing-feature-knowledgeable
**Focus Areas**: Feature inventory analysis, scope assessment, execution planning, state file design
**Communication Style**: Present classification rationale clearly, propose target features with evidence, ask for human confirmation before proceeding

## Context Requirements

- **Critical (Must Read):**

  - **Change Request** — The human partner's description of what needs to be added or changed, or a queued entry in [Feature Request Tracking](../../../doc/state-tracking/permanent/feature-request-tracking.md)
  - [Feature Request Tracking](../../../doc/state-tracking/permanent/feature-request-tracking.md) — Intake queue for product feature requests (check for "📥 Submitted" entries)
  - [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) — Current feature inventory to identify existing features
  - [Feature Granularity Guide](../../guides/01-planning/feature-granularity-guide.md) — Defines what constitutes a well-scoped feature (used when classifying requests and validating new feature scope)
  - [`feature-request-evaluation` craft skill](../../../.claude/skills/feature-request-evaluation/SKILL.md) — the evaluation judgment craft, activated in Step 1 (Check Recommended Skills): its [tier-assessment reference](../../../.claude/skills/feature-request-evaluation/references/tier-assessment.md) carries the complexity-tier scoring criteria and the Design Requirements Evaluation (DB / API / UI / Instruction) criteria used by the embedded tier-assessment procedure (new feature path, Phase 2a); its [enhancement-scoping reference](../../../.claude/skills/feature-request-evaluation/references/enhancement-scoping.md) carries the Enhancement State Tracking File customization craft (Phase 2b). Replaces the retired Assessment Guide and Enhancement State Tracking Customization Guide.
  - [Documentation Tiers README](../../../doc/documentation-tiers/README.md) — Tier definitions, criteria, and the normalized scoring system

- **Important (Load If Space):**

  - Feature State Files (`state-tracking/features/X.Y.Z-*-implementation-state.md`) — Implementation state of candidate target features (includes Dimension Profile for inheritance)
  - [Development Dimensions Guide](../../guides/framework/development-dimensions-guide.md) — Dimension definitions and applicability criteria for evaluating if enhancement scope changes dimension applicability
  - [Feature Implementation State Template](../../templates/04-implementation/feature-implementation-state-template.md) / [Lightweight variant](../../templates/04-implementation/feature-implementation-state-lightweight-template.md) — Full (Tier 2/3) and lightweight (Tier 1) state-file templates; the assessed tier selects the variant
  - Existing Design Docs (FDD, TDD, ADR) associated with the target feature — For understanding current scope and design
  - [Enhancement Workflow Concept (PF-PRO-002)](../../../process-framework-central/proposals/old/enhancement-workflow-concept.md) — Full design rationale for this workflow

- **Reference Only (Access When Needed):**
  - [Task-Based Development Principles](../../ai-tasks.md#understanding-task-based-development) — For understanding framework principles

## Process

> **IMPORTANT: The AI agent must propose the target feature and wait for human approval before creating the state file.**
>
> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

### Phase 1: Classification

1. **Check Recommended Skills**: Read the active language-config (`languages-config/{language}/{language}-config.json`) and `project-config.json` for `recommended_skills` entries keyed to `feature-request-evaluation`. If the `feature-request-evaluation` craft skill is available in the session, activate it — it owns the **evaluation judgment craft** this task delegates to (tier-assessment scoring criteria and the Design Requirements Evaluation on the new-feature path; Enhancement State Tracking File customization on the enhancement path). If it is not listed in the session, read [`SKILL.md`](../../../.claude/skills/feature-request-evaluation/SKILL.md) directly and apply it — that file is the canonical source the Skill tool loads, so a direct read is equivalent, not degraded. The judgment craft is unavailable for this run only if the skill file itself is absent (the retired procedural guides have no successors).
2. **Read the change request** — Understand what the human partner wants to add or change. Also check [Feature Request Tracking](../../../doc/state-tracking/permanent/feature-request-tracking.md) for queued requests with status "📥 Submitted" — the human partner may point to a specific request ID, or the agent can propose which queued request to evaluate. When several queued requests are evaluated together (backlog drains), propose a **batch plan** — which requests, in what order — and get it approved before starting; the batch then shares one classification checkpoint (step 7) and one assessment checkpoint (step 12) covering all its requests, so checkpoint discipline holds without a round trip per request. Keep a batch to what one session can finish end-to-end, including closure.
3. **Review feature tracking** — Read `feature-tracking.md` to understand the current feature inventory. Make yourself familiar with some potential features by looking at the feature state tracking files.
4. **Classify the request** — Determine whether this is a **new feature**, an **enhancement** to an existing feature, or **neither — not an actionable product change**. Apply the three validation tests from the [Feature Granularity Guide](../../guides/01-planning/feature-granularity-guide.md) to validate the scope of new features. A request is *not an actionable product change* when it is really a framework/process concern, a test-infrastructure or technical-debt item, or already satisfied by existing behavior — these close as **Rejected** (step 7 Reject outcome) rather than being forced into the new-feature/enhancement binary.

5. **Detect structural level (new feature path only)** — For new features, determine the smallest structural creation needed in `feature-tracking.md`:
   - **Level 3 (feature row)**: New feature fits an existing subgroup → only a feature row is added to that subgroup's table
   - **Level 2 (subgroup)**: New feature needs a new subgroup under an existing category → a new `### N.X` heading + empty table is created, then the feature row
   - **Level 1 (category)**: New feature belongs in a wholly new category → a new `<details><summary>` block is created, then a subgroup, then the feature row

   The level determines the `-Id` argument passed to [`Update-FeatureCategory.ps1`](../../scripts/update/Update-FeatureCategory.ps1) in step 8 (single digit `1` for category, `1.2` for subgroup, `1.2.3` for feature row). The script chains to [`New-TestInfrastructure.ps1 -Update`](../../scripts/file-creation/00-setup/New-TestInfrastructure.ps1) to scaffold the matching test/audit dirs (PF-IMP-871 / PF-PRO-034).

6. **Confirm names (new structural levels only)** — Name new categories and subgroups using noun-based phrases that produce clean kebab-case slugs (e.g., "Customer Management" → `1-customer-management/`, "Logging & Monitoring" → `2-logging-monitoring/`).

7. **🚨 CHECKPOINT**: Present classification decision (and structural-level finding for new features) with rationale to human partner for approval — for an approved batch (step 2), present every request's decision together in one checkpoint
   - **New Feature** → Continue to step 8 (Phase 2a)
   - **Enhancement** → Continue to step 16 (Phase 2b)
   - **Reject (not an actionable product change)** → Close the request with [`Update-FeatureRequest.ps1`](../../scripts/update/Update-FeatureRequest.ps1) `-RequestId "PD-FRQ-XXX" -NewStatus "Rejected" -Notes "<reason>"`. When the request is really a framework/process, test-infrastructure, or technical-debt concern, redirect it to its proper home and cross-reference that in the Notes — file a framework IMP via [`New-ProcessImprovement.ps1`](../../scripts/file-creation/support/New-ProcessImprovement.ps1) (framework/process/test-infra) or a technical-debt item (tech debt); for an already-satisfied request, name the existing feature that covers it. This task is then complete — proceed to the Task Completion Checklist.

### Phase 2a: New Feature Routing & Tier Assessment

> The new-feature path is self-contained: it adds the feature, **assesses its complexity tier inline** (this procedure was formerly the standalone Feature Tier Assessment task — embedded here per PF-IMP-1132, mirroring how Codebase Feature Discovery already embeds assessment during onboarding), creates the tier-correct implementation state file, and routes to design. **Order matters**: assess the tier *before* creating the state file so the correct template variant (lightweight Tier 1 / full Tier 2/3) is chosen.

8. **Add the feature to tracking** — Use [`Update-FeatureCategory.ps1`](../../scripts/update/Update-FeatureCategory.ps1) to atomically create the structural row(s) identified in step 5. The script's level is inferred from the `-Id` dot-count and creates parent levels in order from outer to inner (call once per level needed):
   ```powershell
   # Level-3 only (existing subgroup):
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/update/Update-FeatureCategory.ps1 -Id "1.2.3" -Name "Read by ID" -Priority "P2"

   # Level-2 + level-3 (new subgroup under category 1):
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/update/Update-FeatureCategory.ps1 -Id "1.2" -Name "Customer Read"
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/update/Update-FeatureCategory.ps1 -Id "1.2.3" -Name "Read by ID"

   # Level-1 + level-2 + level-3 (new category):
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/update/Update-FeatureCategory.ps1 -Id "1" -Name "Customer Management"
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/update/Update-FeatureCategory.ps1 -Id "1.2" -Name "Customer Read"
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/update/Update-FeatureCategory.ps1 -Id "1.2.3" -Name "Read by ID"
   ```
   The new row starts at `⬜ Needs Assessment` — a within-session transient resolved by step 14 below. The script chains to `New-TestInfrastructure.ps1 -Update` after the mutation, which scaffolds the matching `automated/unit/<N>-<slug>/[<N.X>-<slug>/]` test dirs and `audits/unit/...` mirrors automatically (PF-IMP-871 / PF-PRO-034).

9. **Map user workflows** — Check [User Workflow Tracking](../../../doc/state-tracking/permanent/user-workflow-tracking.md): does this feature create a new user workflow or extend an existing one? Update the workflow tracking file accordingly (add new workflows, add the feature to existing workflows' Required Features). You will pass these WF-IDs to step 13's `-Workflows` parameter, which writes them to the new state file's `workflows:` metadata.

10. **Create the tier assessment document** — ALWAYS use the [`New-Assessment.ps1`](../../scripts/file-creation/01-planning/New-Assessment.ps1) script (manual creation is prohibited — it breaks ID tracking and causes conflicts). The script resolves its output directory from the registry, so run it from any working directory. All three parameters are mandatory:
   ```powershell
   process-framework/scripts/file-creation/01-planning/New-Assessment.ps1 -FeatureId "X.X.X" -FeatureName "Feature Name" -FeatureDescription "Brief description of what the feature does"
   ```

11. **Score and evaluate design requirements** — Following the `feature-request-evaluation` skill's [tier-assessment reference](../../../.claude/skills/feature-request-evaluation/references/tier-assessment.md):
   - Evaluate and score each complexity factor; calculate the normalized score and determine the tier (🔵 Tier 1 / 🟠 Tier 2 / 🔴 Tier 3).
   - Declare the feature's **Implementation Medium** (`code` | `instruction` | `mixed`) and complete the **Design Requirements Evaluation** (DB / API / UI / Instruction) per the [tier-assessment reference — Design Requirements Evaluation](../../../.claude/skills/feature-request-evaluation/references/tier-assessment.md#design-requirements-evaluation), marking each "Yes"/"No" with justification. These flags are recorded in the assessment document — the single source of truth (not in master feature-tracking.md columns, per PF-PRO-002 / PF-IMP-760) — and drive the next-status transition in step 14.

12. **🚨 CHECKPOINT**: Present the assessment scores, tier assignment, and Design Requirements Evaluation (DB / API / UI / Instruction) to the human partner for approval before creating the state file — for an approved batch (step 2), present every feature's assessment together in one checkpoint.

13. **Create the Feature Implementation State file (tier-correct variant)** — The approved tier selects the template:
   ```powershell
   # Tier 1 (lightweight template):
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/04-implementation/New-FeatureImplementationState.ps1 -FeatureName "[name]" -FeatureId "X.Y.Z" -Lightweight -Workflows "[WF-IDs]" -Description "[description]"

   # Tier 2/3 (full template):
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/04-implementation/New-FeatureImplementationState.ps1 -FeatureName "[name]" -FeatureId "X.Y.Z" -Workflows "[WF-IDs]" -Description "[description]"
   ```
   - Script: `process-framework/scripts/file-creation/04-implementation/New-FeatureImplementationState.ps1`; creates `/doc/state-tracking/features/[X.Y.Z]-[name]-implementation-state.md` and links it in feature-tracking.md.
   - **Retrospective onboarding** (when this procedure is invoked from Codebase Feature Discovery): add `-ImplementationMode "Retrospective Analysis"`.
   - The script auto-calls `New-SourceStructure.ps1 -Update` (refreshes the [Source Code Layout](../../../doc/technical/architecture/source-code-layout.md) tree if it exists) and `New-TestInfrastructure.ps1 -Update` (PF-IMP-871).
   - `-Workflows` writes the `workflows:` frontmatter from the step-9 WF-IDs (comma-separated; omit for a feature in no user workflow → `workflows: []`).
   - If this evaluation surfaced material design discussion (mechanisms weighed, trade-offs, rejected alternatives), seed it into the new state file now — settled choices in §Design Decisions, open threads in §Open Questions — so it carries into FDD/TDD/planning instead of dying with the session. Cross-task handover runs through artifacts, not conversation.

14. **Transition feature-tracking status** — Run [`Update-FeatureTrackingFromAssessment.ps1`](../../scripts/update/Update-FeatureTrackingFromAssessment.ps1):
   ```powershell
   process-framework/scripts/update/Update-FeatureTrackingFromAssessment.ps1 -FeatureId "X.X.X" -AssessmentId "PD-ASS-XXX"
   ```
   This moves the feature from `⬜ Needs Assessment` to the next status — `📋 Needs FDD` (Tier 2+); `🗄️ Needs DB Design` / `🔌 Needs API Design` / `🎨 Needs UI Design` / `📜 Needs Instruction Design` / `🔧 Needs Impl Plan` (Tier 1, per the design-required flags, in chain order DB → API → UI → Instruction); retrospective onboarding overrides Tier 1 with `-Status "NeedsTestScoping"` — and adds the tier emoji (🔵/🟠/🔴) and the assessment link.

15. **Close the originating request (if any) and route onward**:
   - If this request originated from [Feature Request Tracking](../../../doc/state-tracking/permanent/feature-request-tracking.md), close it with [`Update-FeatureRequest.ps1`](../../scripts/update/Update-FeatureRequest.ps1) — **omit `-FeatureName`** (the tier-correct state file was already created in step 13; passing `-FeatureName` would re-create it as a full-template duplicate). Carry the assessment outcome in `-Notes` — tier, assessment ID, and the design-requirement flags that were set — so the closed queue row stays traceable without reopening the assessment:
     ```powershell
     process-framework/scripts/update/Update-FeatureRequest.ps1 -RequestId "PD-FRQ-XXX" -Classification "NewFeature" -FeatureId "X.Y.Z" -NewStatus "Completed" -Notes "Added as feature X.Y.Z; Tier 2 (PD-ASS-XXX); design required: DB, API"
     ```
     Write `design required: none` when no flag was set.
   - **Blocked on an open research question?** If the feature cannot advance to its next status until a technical question is answered (which library, whether an integration is feasible, whether a platform supports X), file the exploration and divert the feature instead of routing it onward:
     ```powershell
     # 1. File the research question into the exploration queue
     process-framework/scripts/file-creation/01-planning/New-Exploration.ps1 -Source "Feature Request Evaluation" -Description "The research question to answer" -Priority "HIGH|MEDIUM|LOW" -RelatedFeature "X.Y.Z" -Notes "Acceptance criteria; blocks <next status>"
     # 2. Divert the feature — the block is visible in feature-tracking, not implied
     process-framework/scripts/update/Update-BatchFeatureStatus.ps1 -FeatureIds "X.Y.Z" -Status "NeedsTechnicalExploration" -UpdateType "StatusOnly"
     ```
     **Divert-and-return** (mirrors `🔄 Needs Enhancement`): [Technical Exploration](technical-exploration-task.md) (PF-TSK-093) runs the spike, records the findings, and returns the feature to the pipeline status it would otherwise have taken — so record that intended status in the exploration's `-Notes`. The tier assessment (steps 10–14) still stands; only the *next* step waits. A question that blocks **classification itself** (you cannot tell new-feature from enhancement until it is answered) is filed the same way at step 4, before the step-7 checkpoint — there is no feature row to divert yet.
   - Inform the human partner of the assigned tier and the next task: **FDD Creation** (Tier 2+) or **Feature Implementation Planning** (Tier 1, no design flags), routing through **Database Schema Design** / **API Design** / **UI Design** first if those flags were set (design-chain order: DB → API → 🎨 UI → TDD). If the feature was diverted to an exploration, the next task is **Technical Exploration** instead.
   - This task is complete. Proceed to the Task Completion Checklist.

### Phase 2b: Enhancement Scoping

16. **Propose target feature(s)** — Identify which existing feature(s) this enhances:
   - Locate the candidate feature(s) in `feature-tracking.md`
   - Read each feature's implementation state file to understand its current scope
   - Locate any existing design documentation (FDD, TDD, ADR)
   - Check [User Workflow Tracking](../../../doc/state-tracking/permanent/user-workflow-tracking.md) — does this enhancement affect any user workflows? If so, note the affected WF-IDs in the enhancement scope. If the enhancement changes which workflows the feature participates in, update the feature state file's `workflows:` metadata accordingly.
   - **Multi-feature requests**: If the change request affects multiple existing features, identify all of them. Present the full list at the checkpoint below.
17. **🚨 CHECKPOINT**: Present target feature proposal with rationale to human partner and wait for explicit approval before continuing
   - **For multi-feature requests**: Present all affected features and confirm with the human partner whether to proceed with separate Enhancement State Tracking Files for each, or whether the request should be split into independent evaluations. The default is **one state file per target feature**, each scoped to that feature's portion of the work, with cross-references linking the related state files.

18. **Assess enhancement scope** — After human approval of the target feature(s), evaluate each against the scope-assessment criteria in the `feature-request-evaluation` skill's [enhancement-scoping reference](../../../.claude/skills/feature-request-evaluation/references/enhancement-scoping.md)

19. **Evaluate dimension impact** — For each target feature, run the dimension-impact assessment per the same [enhancement-scoping reference](../../../.claude/skills/feature-request-evaluation/references/enhancement-scoping.md); the outcome is recorded in the Enhancement State Tracking File's Dimension Impact Assessment section

20. **Create Enhancement State Tracking File(s)** — Use the `New-EnhancementState.ps1` script for each target feature:
   ```powershell
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/04-implementation/New-EnhancementState.ps1 -TargetFeature "[Feature ID]" -EnhancementName "[Brief Name]" -Description "[Scope description]" -Dims "SE,PE,DI"
   ```
   The `-Dims` parameter populates the Dimension Impact Assessment section with inherited and adjusted dimensions from step 19.
   **Multi-feature requests**: Run the script once per target feature. In each generated state file, add a "Related Enhancement State Files" section listing the other state files created for the same change request, so the Feature Enhancement task can coordinate the work.

   Then customize each generated file following the `feature-request-evaluation` skill's [enhancement-scoping reference](../../../.claude/skills/feature-request-evaluation/references/enhancement-scoping.md) — header sections, the 17 workflow-block Applicable/Not-Applicable evaluations, adaptation notes, and session planning. In addition:
   - Verify each block's **Referenced Task Doc** still names a live task in [ai-tasks.md](../../ai-tasks.md) — tasks get merged, retired, and renumbered, and a dead reference generated here only surfaces mid-execution in the Feature Enhancement session. Correct it in the state file; when the stale reference came from the template rather than from this session's authoring, it is a framework defect — file an IMP so the next generated file is clean

### Phase 3: Finalization

21. **🚨 CHECKPOINT**: Present completed Enhancement State Tracking File (including Dimension Impact Assessment) to human partner for review before finalizing
22. **Update tracking files** — If this request originated from [Feature Request Tracking](../../../doc/state-tracking/permanent/feature-request-tracking.md), close the request and update feature-tracking using [`Update-FeatureRequest.ps1`](../../scripts/update/Update-FeatureRequest.ps1):
    ```powershell
    pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/update/Update-FeatureRequest.ps1 -RequestId "PD-FRQ-XXX" -Classification "Enhancement" -FeatureId "X.Y.Z" -NewStatus "Completed" -EnhancementStateFile "Enhancement State File: [PF-STA-XXX](path/to/file.md)" -Notes "Enhancement State File created"
    ```
    This script moves the request to ✅ Completed in feature-request-tracking.md and sets the target feature's status to "🔄 Needs Enhancement" in feature-tracking.md with a link to the Enhancement State Tracking File.

    If the request did NOT originate from feature-request-tracking (e.g., ad-hoc human request), invoke the `Update-FeatureTrackingStatus` helper from Common-ScriptHelpers to set the target feature's status and notes — never edit `feature-tracking.md` directly (see [Feature Tracking Mutation Guide](../../guides/support/feature-tracking-mutation-guide.md)):
    ```powershell
    Import-Module process-framework/scripts/Common-ScriptHelpers.psm1
    Update-FeatureTrackingStatus -FeatureId "X.Y.Z" -Status "🔄 Needs Enhancement" `
        -Notes "Enhancement State File: [PF-STA-XXX](path/to/file.md)"
    ```
23. **MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Outputs

- **Classification Decision** — New feature, enhancement, or rejection (not an actionable product change — redirected to its proper home), with rationale communicated to human partner
- **Human-approved target feature** — AI agent's proposal confirmed by human partner (enhancement path only)
- **For new features**: New entry in `feature-tracking.md`; a **tier assessment document** (`PD-ASS-XXX`) with the Design Requirements Evaluation; a **tier-correct feature implementation state file** (lightweight Tier 1 / full Tier 2/3); feature-tracking status transitioned to the post-assessment status (📋 Needs FDD / design / impl-plan per tier and design flags)
- **For enhancements**: Customized Enhancement State Tracking File in `doc/state-tracking/temporary` with:
  - Target feature identification and existing doc inventory
  - Scope assessment using practical criteria
  - **Dimension Impact Assessment** — inherited dimensions from parent feature's profile, with any adjustments for the enhancement scope (new Critical/Relevant dimensions, reduced dimensions)
  - 17 workflow blocks each evaluated as Applicable/Not Applicable with rationale and adaptation notes
  - Session boundary planning (for multi-session enhancements)
  - **Updated feature tracking** — Target feature set to "🔄 Needs Enhancement" with link to state file (enhancement path only)

## State Tracking

The following state files must be updated as part of this task:

- [Feature Request Tracking](../../../doc/state-tracking/permanent/feature-request-tracking.md) — Update request status to ✅ Completed after classification (if request originated from this file)
- [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) — For new features: add the entry, then transition it to the post-assessment status (📋 Needs FDD / 🗄️/🔌/🎨/🔧 / 🔎 per tier and design flags) with the tier emoji and assessment link. For enhancements: set target feature status to "🔄 Needs Enhancement" with link to Enhancement State Tracking File
- **Tier Assessment Document** (new features) — `PD-ASS-XXX` in `doc/documentation-tiers/assessments`, including the Design Requirements Evaluation (DB / API / UI / Instruction)
- **Enhancement State Tracking File** (created by this task) — In `doc/state-tracking/temporary`
- **Feature Implementation State File** — For new features: create the tier-correct variant (lightweight Tier 1 / full Tier 2/3) after assessment. For enhancements: no change (handled by Feature Enhancement task) — In `doc/state-tracking/features`

## MANDATORY Task Completion Checklist

> Completion discipline, output verification, and the feedback form are governed by the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md) (Phase C). The items below are the **task-specific** verifications that plug into it.

- [ ] **Verify Classification**: Confirm change request has been classified
  - [ ] Classification decision (new feature or enhancement) communicated to human partner with rationale
  - [ ] For enhancements: target feature proposed and human approval obtained

- [ ] **Verify New Feature Outputs** (new feature path only):
  - [ ] Feature entry added to feature-tracking.md at the correct structural level (via `Update-FeatureCategory.ps1`)
  - [ ] Tier assessment document created via `New-Assessment.ps1` with complexity scores, rationale, a declared Implementation Medium, and a complete Design Requirements Evaluation (DB / API / UI / Instruction each "Yes"/"No" with justification)
  - [ ] Tier assignment correct for the normalized score; presented at the step 12 checkpoint and approved
  - [ ] Feature Implementation State file created in the **tier-correct variant** (lightweight Tier 1 / full Tier 2/3) and linked in feature-tracking.md
  - [ ] feature-tracking status transitioned via `Update-FeatureTrackingFromAssessment.ps1` (tier emoji + post-assessment status + assessment link)
  - [ ] Originating request (if any) closed via `Update-FeatureRequest.ps1` **without** `-FeatureName`

- [ ] **Verify Enhancement Outputs** (enhancement path only):
  - [ ] Enhancement State Tracking File created using `New-EnhancementState.ps1`
  - [ ] State file customized following the `feature-request-evaluation` skill's enhancement-scoping reference
  - [ ] All 17 workflow blocks evaluated as Applicable/Not Applicable with rationale
  - [ ] Session boundary planning included (if multi-session)
  - [ ] Target feature status set to "🔄 Needs Enhancement" in feature tracking with link to state file

- [ ] **Feedback form** completed per the [Task Execution Protocol → Feedback step](../../guides/framework/task-execution-protocol-guide.md#feedback-step) — task ID `PF-TSK-067`, context "Feature Request Evaluation".

## File Operations

| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | Tier Assessment Document `PD-ASS-XXX` (new features) | `New-Assessment.ps1` | Complexity scoring + Design Requirements Evaluation (DB / API / UI / Instruction) |
| **Creates** | Feature Implementation State File (new features) | `New-FeatureImplementationState.ps1` | Tier-correct variant (`-Lightweight` Tier 1; full Tier 2/3) — created after tier assessment (step 13) |
| **Creates** | Enhancement State Tracking File (enhancements) | `New-EnhancementState.ps1` | Scoped enhancement steps with Dimension Impact Assessment |
| **Updates** | [`feature-tracking.md`](../../../doc/state-tracking/permanent/feature-tracking.md) | `Update-FeatureCategory.ps1` | New features: creates the structural row(s) at `⬜ Needs Assessment` |
| **Updates** | [`feature-tracking.md`](../../../doc/state-tracking/permanent/feature-tracking.md) | `Update-FeatureTrackingFromAssessment.ps1` | New features: transitions to post-assessment status (📋/🗄️/🔌/🔧/🔎) + tier emoji + assessment link |
| **Updates** | [`feature-request-tracking.md`](../../../doc/state-tracking/permanent/feature-request-tracking.md) | `Update-FeatureRequest.ps1` | Request status: 📥 Submitted → Classified (New Feature/Enhancement) → ✅ Completed (new-feature closure omits `-FeatureName`) |
| **Updates** | [`feature-tracking.md`](../../../doc/state-tracking/permanent/feature-tracking.md) | `Update-FeatureRequest.ps1` | For enhancements: sets target to 🔄 Needs Enhancement with state-file link |
| **Updates** | [`user-workflow-tracking.md`](../../../doc/state-tracking/permanent/user-workflow-tracking.md) | Manual | Updated for new features that map to user workflows |
| **Updates** | [`technical-exploration-tracking.md`](../../../doc/state-tracking/permanent/technical-exploration-tracking.md) | `New-Exploration.ps1` | *Conditional*: files a `📥 Queued` research question that blocks the feature (or its classification) |
| **Updates** | [`feature-tracking.md`](../../../doc/state-tracking/permanent/feature-tracking.md) | `Update-BatchFeatureStatus.ps1` | *Conditional*: diverts the blocked feature to `🔬 Needs Technical Exploration` (cleared by PF-TSK-093 on resolution) |

## Next Tasks

- [**Feature Enhancement**](../04-implementation/feature-enhancement.md) — Execute the Enhancement State Tracking File created by this task (enhancement path)
- [**FDD Creation**](../02-design/fdd-creation-task.md) — New feature assessed Tier 2+: create the Functional Design Document (new feature path; route through [Database Schema Design](../02-design/database-schema-design-task.md) / [API Design](../02-design/api-design-task.md) / [UI Design](../02-design/ui-design-task.md) first if those flags were set in the assessment)
- [**Feature Implementation Planning**](../04-implementation/feature-implementation-planning-task.md) — New feature assessed Tier 1 with no design flags (new feature path)
- [**Technical Exploration**](technical-exploration-task.md) — Feature diverted to `🔬 Needs Technical Exploration`: a filed research question must resolve before it can advance

<!-- merged from transition-registry entry: Feature Request Evaluation (PF-TSK-067) -->
### Prerequisites for Transition

- [ ] Change request classified (new feature or enhancement)
- [ ] For new features: tier assessed and approved; tier-correct state file created; feature-tracking status transitioned to the post-assessment status
- [ ] For enhancements: target feature proposed and human-approved; Enhancement State Tracking File created and customized; target feature status set to "🔄 Needs Enhancement"

### Next Task Selection

- **If classified as new feature**: tier assessed inline → **FDD Creation** (Tier 2+) or **Feature Implementation Planning** (Tier 1, no design flags), routing through Database Schema Design / API Design / UI Design first if those flags were set (design-chain order: DB → API → 🎨 UI → TDD)
- **If classified as enhancement**: → Feature Enhancement (PF-TSK-068)
- **If blocked on an open research question** (either path): feature diverted to `🔬 Needs Technical Exploration` → Technical Exploration (PF-TSK-093), which returns it to the pipeline status above once the findings land

### Preparation for Next Task

1. Ensure Enhancement State Tracking File is fully customized (no placeholder content)
2. Verify target feature's status shows "🔄 Needs Enhancement" with link to state file
3. Confirm all execution steps have referenced task documentation links

## Related Resources

- [Feature Granularity Guide](../../guides/01-planning/feature-granularity-guide.md) — Defines what constitutes a well-scoped feature with validation tests and scaling guidance
- [Enhancement Workflow Concept (PF-PRO-002)](../../../process-framework-central/proposals/old/enhancement-workflow-concept.md) — Full design rationale for this workflow
- [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) — Current feature inventory
- [`feature-request-evaluation` craft skill](../../../.claude/skills/feature-request-evaluation/SKILL.md) — the evaluation judgment craft (tier-assessment scoring + enhancement state-file customization; replaces the retired Assessment Guide and Enhancement State Tracking Customization Guide); activated by the Check Recommended Skills step
