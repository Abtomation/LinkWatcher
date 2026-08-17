---
id: PF-TSK-026
type: Process Framework
category: Task Definition
domain: agnostic
version: 2.20
created: 2025-07-26
updated: 2026-08-10
description: "Support task for fundamentally extending the framework with new functionalities and capabilities"
use_when: >-
  Adding new framework capabilities with multiple interconnected components (multi-phase, multi-session). Triggers: 'start framework extension X', 'continue the centralized framework management extension', 'work on phase N of extension Y'.
triggers:
  - "start framework extension X"
  - "continue the centralized framework management extension"
  - "work on phase N of extension Y"
automation: semi
scripts:
  - ../../scripts/file-creation/support/New-FrameworkExtensionConcept.ps1
trigger_status:
  - raw: "_(user request)_"
output_status:
  - raw: "`ai-tasks.md`, `PF-documentation-map.md`, ID registry → updated"
next_tasks:
  - task: process-improvement-task.md
    condition: "If further refinements are needed for the extension"
---

# Framework Extension Task

> **▶ Execute this task under the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md).** This file holds only the Framework-Extension–specific content; the universal contract every task shares lives once in the protocol and is mandatory here.

## Purpose & Context

This task manages the systematic extension of the task-based development framework with entirely new functionalities, capabilities, or systematic approaches. It ensures that framework extensions are properly planned, implemented across multiple sessions, and integrated with existing framework components while maintaining consistency with established principles.

## AI Agent Role

**Role**: Framework Architect
**Mindset**: Extensibility-focused, component-oriented, integration-aware
**Focus Areas**: Framework design, component relationships, extensibility patterns, integration points
**Communication Style**: Consider framework evolution and component interactions, ask about long-term extensibility and integration requirements

## Context Requirements

- **Critical (Must Read):**

  - **Framework Extension Concept Document** - Human-provided concept document defining the extension scope, workflow, and integration strategy
  - [`framework-extension-concept` craft skill](../../../.claude/skills/framework-extension-concept/SKILL.md) - the concept-document craft (template-variant selection, section-by-section customization judgment, Modification-Focused completeness tables, validation checklist), activated at Step 0 (Check Recommended Skills). Replaces the retired Framework Extension Customization Guide and **drives the concept customization at Step 2.**
  - [Task-Based Development Principles](../../ai-tasks.md#understanding-task-based-development) - Understanding of framework principles for consistent extension
  - [New Task Creation Process](new-task-creation-process.md) - For creating individual tasks within the extension

- **Important (Load If Space):**

  - [Script Development Quick Reference](../../guides/support/script-development-quick-reference.md) - PowerShell execution patterns and parameter checking (**always check script parameters with `Get-Help <script> -Parameter *` before running**)
  - [Documentation Map](../../PF-documentation-map.md) - For understanding current framework structure and updating with new artifacts
  - [Process Improvement Tracking](../../../process-framework-central/state-tracking/permanent/process-improvement-tracking.md) - For tracking framework capability enhancements
  - [New-TempTaskState.ps1](../../scripts/file-creation/support/New-TempTaskState.ps1) - State tracking for creation-heavy extensions (use `-Variant FrameworkExtension` for multi-artifact tracking)
  - [New-StructureChangeState.ps1](../../scripts/file-creation/support/New-StructureChangeState.ps1) - State tracking for modification-heavy extensions
  - [`template-development` craft skill](../../../.claude/skills/template-development/SKILL.md) - the template-design craft, activated at Step 0; for creating extension-specific templates
  - [`creation-script-development` craft skill](../../../.claude/skills/creation-script-development/SKILL.md) - the script-authoring craft, activated at Step 0; for creating automation scripts

- **Reference Only (Access When Needed):**
  - [PF ID Registry](../../PF-id-registry.json) - For adding new ID prefixes for extension-created file types
  - [Process Framework Task Registry — Trigger & Output](../../infrastructure/process-framework-task-registry.md) - For studying existing trigger/output chains (`🔗 TRIGGER & OUTPUT` blocks and State File Trigger Index)
  - [Structure Change Task](structure-change-task.md) - For understanding structural modifications vs. extensions
  - [Process Improvement Task](process-improvement-task.md) - For understanding granular improvements vs. extensions

## Process

> **🚨 Core invariants for this task:**
> - It is a **multi-session** task — create a comprehensive concept document and get human approval *before* implementation, then track progress across sessions in a temporary state file.
> - **Never proceed past a `🚨 CHECKPOINT`** without presenting findings and getting explicit human approval; implement all work incrementally.
> - On an error, surprise, or ambiguous fork at any step, consult the task's [edge-case file](../../../.claude/skills/framework-extension-concept/references/edge-cases.md) — consult-on-stumble incident guidance (PF-PRO-059 two-zone convention).

### Phase 1: Concept Development & Approval

> **Two entry points.** **From scratch** (default): run Steps 1–5 in order. **Resume an existing concept**: when a Framework Extension Concept already exists for this IMP — scaffolded in a prior session and left *Awaiting Human Review* with unfilled impact sections, authored ahead as the IMP's seed, or held pending another extension — Steps 1–2 collapse to re-verifying the concept's decisions against the live tree — IDs and registry pools, paths, every "currently open / currently N" claim — and completing its impact sections; pick up at Step 4. A held concept is a snapshot, and a sibling extension landing meanwhile invalidates exactly those decisions (PF-IMP-1681). An IMP row reading "Needs Implementation" does not imply the concept is ready — reconcile the two before coding.

0. **Check Recommended Skills**: Read the active language-config (`languages-config/{language}/{language}-config.json`) and `project-config.json` for `recommended_skills` entries keyed to `framework-extension-task`, and activate each bound craft skill available in the session:
   - **`framework-extension-concept`** — the **concept-document craft** this task delegates to (template-variant selection for `New-FrameworkExtensionConcept.ps1`, section-by-section customization judgment, the Modification-Focused completeness tables, the concept validation checklist); drives the concept customization at Step 2.
   - **`template-development`** — the **template-design craft**; applies when the extension creates or updates templates (Step 13 Phase B).
   - **`creation-script-development`** — the **script-authoring craft** (New-FrameworkDocument model, placeholder/registry/directory integration); applies when the extension creates automation scripts (Step 13).

   If a bound skill is not listed in the session, read its `SKILL.md` directly under [`.claude/skills/`](../../../.claude/skills/) and apply it — that file is the canonical source the Skill tool loads, so a direct read is equivalent, not degraded. A craft is unavailable for this run only if its skill file is absent (the corresponding retired guides have no successors). *(Step 0 by design — this task's step numbers are externally load-bearing, e.g. the archive-split procedure is cited as "Step 14" from the extension state template.)*

1. **Pre-Concept Analysis** — before creating the concept document, study the landscape:
   - (a) **Read the [Task Transition Registry](../../infrastructure/task-transition-registry.md)** to understand how existing tasks connect and hand over work
   - (a2) **Study the [Process Framework Task Registry — Trigger & Output](../../infrastructure/process-framework-task-registry.md)** (`🔗 TRIGGER & OUTPUT` blocks and State File Trigger Index) to understand which state file statuses trigger which tasks and what outputs each task produces — this reveals the full signal chain the extension must integrate with
   - (b) **Study existing project patterns AND framework-lineage patterns** (predecessor projects, blueprint sources, sibling projects sharing the same framework instance) solving similar problems — identify precedents in the project's current workflow (e.g., how E2E tracking handles non-standard test types, how validation dimensions were modularized) **and in the framework's history** (e.g., how the same abstraction was handled in a predecessor project that shaped this framework, or by a sibling project that adopted the framework before this one). Also familiarize yourself with established industry taxonomies/patterns for the problem domain (e.g., Diataxis for documentation organization, OWASP for security, Twelve-Factor for configuration) so you have proven external models to compare against in (c). When the extension would change or replace an existing structure or rule, also dig out its **provenance** — the decision record that shaped the current state (git history, archived proposals/concepts) and any written re-open conditions (PF-IMP-1606).
   - (c) **Establish the abstraction model** — what are the natural levels in the framework's architecture? **Where in the existing data model does this information already live? Could the new tracking duplicate state already maintained elsewhere (e.g., per-feature state files' §4 Documentation Inventory, ID registries, existing tracking columns)?** Where industry taxonomies (from (b)) are relevant, **carefully evaluate how to adapt them to the framework** rather than choosing between copy-verbatim and reject-outright. Define categories that genuinely fit the framework — neither copying industry terminology blindly nor reinventing what proven external models already solve.
   - (d) **Trace the full lifecycle end-to-end** — who triggers → who plans → who creates → who runs → who records → who reviews → how do you know what's left?
   - (e) **Evaluate scalability, abstraction level, and ownership** for every new concept — will this scale as the framework grows? Does it match the framework's architecture? Who owns each artifact, process, and decision? When evaluating scale, extrapolate genuinely (e.g., 10× current artifact count) — don't anchor on current framework scale.
   > Each sub-step should produce a concrete answer. If you cannot answer a question, that is a gap to resolve before proceeding.
2. **Create Framework Extension Concept Document** using the standardized script:
   ```powershell
   # The script self-routes output to appdev central proposals/ regardless of cwd — run from repo root.
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/support/New-FrameworkExtensionConcept.ps1 -ExtensionName "[Extension Name]" -ExtensionDescription "[Brief description]" -Type [Creation/Modification/Hybrid] -ExtensionScope "[Extension scope]" -OpenInEditor
   ```
   - **`-Type`** selects a type-specific template: `Creation` (new artifacts only), `Modification` (changes to existing artifacts only), or `Hybrid` (both)
   - Script creates structural template in `appdev/process-framework-central/proposals/<PROJECT-ID>_[extension-name]-concept.md` — Phase 7 (2026-05-11): PRJ-ID-prefixed filename, `project_id` stamped in frontmatter. Output dir resolved via `Get-CentralFrameworkPath` regardless of cwd.
   - **CRITICAL**: Template requires extensive customization applying the [`framework-extension-concept` craft skill](../../../.claude/skills/framework-extension-concept/SKILL.md) (activated at Step 0)
   - Define extension scope and new capabilities to be added
   - Specify workflow definition with clear input-process-output flow
   - Create artifact dependency map showing how new artifacts serve as inputs for subsequent tasks
   - Define state tracking integration strategy (new permanent state files vs. updating existing ones)
   - Include integration strategy with current framework workflow
3. **Present Concept for Human Review (concept-direction approval)** — Get explicit approval of the concept's direction and scope before investing in the deeper impact analysis (Step 4). This is a lightweight go/no-go on the idea itself; it is **not** the final implementation sign-off — that is Step 5, after impact analysis and the pilot decision are on the table. When Pre-Concept Analysis (Step 1) already reframed routing or surfaced an in-flight sibling extension (or a "is this really an extension?" call), raise that direction question here *before* fully authoring the concept — scaffold the concept via Step 2's script, author the Step 1 findings into it (the concept is the durable home for that analysis even at this early stop; Step 4's author-into-the-concept rule, applied early), and present that scaffold plus the open question rather than a finished write-up, so the go/no-go isn't gated on full authoring the answer might discard. If the answer re-routes the work away, archive the scaffold — it becomes the record of why.
   > **Not-adopted disposition (this checkpoint or Step 5)**: declining the extension on the evidence is a first-class outcome alongside approval and revision — never phrase it as decided indefinitely. The concept is still fully authored, as the **evaluation record** (the evidence, each candidate's disposition, what was verified), with **falsifiable re-open conditions** — testable triggers ("if the shared substrate stops being shared", "if project count exceeds N"), not "revisit later" — and its Status set to `Evaluated — Not Adopted (re-open conditions recorded)`. Archive it to `proposals/old/` and cite it as the driving IMP's rejection reason in the same call (`Update-ProcessImprovement.ps1 -NewStatus Rejected -RejectionReason "<summary — see PF-PRO-NNN>" -ArchiveConcept "<PF-PRO-NNN>"`). The [`framework-extension-concept` craft skill](../../../.claude/skills/framework-extension-concept/SKILL.md) covers repurposing the concept's proposal-shaped sections into an evaluation record; a worked example is appdev's framework-tree-partition evaluation (PF-PRO-057).
4. **Analyze Framework Impact** — For each existing framework element (task, script, template) that the extension will modify:
   - Read the complete element — and where the concept inherited a claim about it from a Framework Evaluation (PF-TSK-079) report or other point-in-time source, re-verify that claim against the live artifact rather than trusting the snapshot. Evaluations capture a moment; the artifact may have drifted since the eval ran.
   - Summarize: (a) what information it has at each step, (b) what it is responsible for, (c) what it delegates
   - Document how the extension affects it, considering its actual knowledge state
   - **Author this analysis into the concept document's own impact sections** — the filled concept is the checkpoint artifact, not a chat-only narration. For a Modification/Hybrid concept these are *Interfaces to Existing Framework*, the *Modification Details* audit subsections (State Tracking Audit / Guide Update Inventory / Automation Integration Strategy), and *Required Components Analysis*; for a Creation concept, *Interfaces to Existing Framework* and *Detailed Workflow & Artifact Management*. Do not propose modifications based on assumptions; summarize the filled analysis at the Step 5 checkpoint.
   - **Trace each declaration to its enforcement site** — the bullets above are keyed by *artifact*. Separately enumerate what the extension **declares**: every rule, grant, default, budget, invariant, or convention it states normatively (must / may / never / by default). For each, name the artifact that will enforce or consume it at execution time and confirm that artifact's current text agrees. Two failure verdicts, both material — **no enforcement site**: the declaration is inert and will be silently ignored; **a site that contradicts it**: two documents now answer one question differently, and whichever one the agent reads at execution time wins. A declaration ships together with its enforcement edit, in the same extension. The checks below run this trace for particular declaration kinds — a kind not listed still needs it.
   > **Validation script check** — two modes, by what the change touches:
   >   - **Live-instance regression check**: if the extension modifies state-file *structure* (columns, sections, headings) the host project already has instances of, identify which [Validate-StateTracking.ps1](../../scripts/validation/Validate-StateTracking.ps1) surfaces parse those files, include them in the impact analysis, and run the validator before and after the change (`-SaveBaseline` before, `-Baseline <path>` after, to prove no *new* errors against pre-existing debt).
   >   - **Template / master-state-schema verification (no live instance)**: if the extension changes a *template* or a master-state *schema* the host project has no materialized instance of (common in appdev, where product state files are absent), a plain validator run exercises nothing and passes vacuously. Build a **synthetic instance** from the template into a temp dir and run `Validate-StateTracking.ps1 -ProjectRoot <temp-dir> -Surface <relevant-surface>`. Then confirm from the per-surface coverage report (PF-IMP-1209) that the surface actually examined it — the report shows a per-surface `examined N / recorded M` denominator, and a surface the coverage note names as having **examined 0 instances** means the validator did **not** parse your synthetic instance, so its green is meaningless.
   >
   > **Column-index / value-recognition impact check**: If the extension modifies tracking file structure (adds, removes, or reorders columns), grep for `Split-MarkdownTableRow` and hardcoded column index patterns (e.g., `\[3\]`, `\[4\]`) in all scripts that reference the modified tracking file; if it adds or removes a value in an enumerated set (status legend, `ValidateSet`), grep for scripts that branch on the value — including duplicated branch logic. Scripts that *read* column indices or *recognize* values break just as silently as scripts that *write* them.
   >
   > **00-setup impact check**: Check all 00-setup tasks (project-initiation, codebase-feature-discovery, codebase-feature-analysis, retrospective-documentation-creation) for impact even when the extension primarily affects later phases. Setup tasks declare configurations (ID prefixes, tracking schemas, directory structures, registries) that downstream tasks consume — adding a new artifact type, new ID prefix, or new tracking field typically requires updates here so new projects pick up the extension by default.
   >
   > **Documented-home check**: For each modified artifact in the impact list, verify it has a documented home — a task definition, customization guide, or other clearly-owned location that anchors its usage. Catches framework asymmetries where a script/template/guide exists without a parent task definition (e.g., UI Design has `New-UIDesign.ps1` + template + customization guide + context map but no task definition; surfaced only via grep for the missing PF-TSK reference). If a modified artifact has no documented home, file an IMP for the asymmetry before proceeding — the extension shouldn't extend an undocumented surface.
   >   - **Also check each *created* artifact's directory home**: the directory it will live in must itself be documented — named and owned by a task definition, a guide (e.g. the documentation-structure guide), or an ID registry's `directories` mapping — so the artifact is discoverable by the tasks meant to find it. Where the extension introduces a new directory, documenting that directory is part of the extension's own scope.
   >
   > **ID-prefix ownership check**: If the extension adds, reuses, or changes an ID prefix, establish from the registry internals which registry owns it — the rolled-out [`PF-id-registry.json`](../../PF-id-registry.json) (portable; projects recognize its prefixes) or the central appdev-only `PF-id-registry-central.json` (never rolled out; `Register-Project.ps1` deliberately omits its cross-project prefixes from project registries) — and whether project-side validators must recognize the prefix. Prefix names mislead: `PF-SST` reads like the pool for framework-shipped state trackers but is central-only (that pool is `PF-FST`).
   >
   > **Soak-tracking status check**: For each PowerShell script targeted for modification, check its soak-tracking status via `Get-SoakStatus -ScriptId <relative-path>` against [`script-soak-tracking.md`](../../../../process-framework-central/state-tracking/permanent/script-soak-tracking.md). Hash-changing edits reset the counter and require re-soaking (default 3 successful invocations). This feeds session sequencing — modifying N soak-tracked scripts means ~3N re-soak invocations to schedule across follow-up sessions in the Phase 2 session plan.
   >
   > **Routing self-check**: After completing impact analysis, re-evaluate routing — does the resulting work shape still match PF-TSK-026 (new capability requiring multiple interconnected components), or has it shifted to [PF-TSK-014](structure-change-task.md) (reorganization, file moves, schema changes) or [PF-TSK-009](process-improvement-task.md) (content edits to a single task/guide/template)? Impact analysis frequently reframes scope from extension to reorganization or improvement. If the work has shifted, re-route via `Update-ProcessImprovement.ps1 -ImprovementId <ID> -MoveToSection StructuralChanges|Improvements -RoutedBy "PF-TSK-026" -Reason "<why>"` and stop — the receiving task picks up in its own session. Present the routing decision (continue with PF-TSK-026 or re-route) as part of the Step 5 checkpoint material.
   >
   > **Mechanism/value self-check**: If impact analysis or a pre-audit shows the chosen mechanism *relocates* complexity rather than removing it (a new DSL/hook surface, config escape hatches, or conditionals that grow without bound), pause and re-present the value hypothesis as an explicit go/no-go — "is this mechanism worth the surface area it adds?" — before authoring components. A same-problem, different-mechanism pivot re-scopes the existing concept in place rather than filing a fresh one (contrast Step 5's fresh-concept path, which is for scope that has outgrown the concept entirely). Present the go/no-go as part of the Step 5 checkpoint material.
4.5. **Pilot vs. Full Rollout Decision** (PF-PRO-030) — for extensions that introduce new behavior with unknown failure modes (e.g., new helper invariants, new hooks, new assertion patterns adopted across many scripts), evaluate whether a **pilot** is appropriate before broad rollout. The pilot mitigates the risk of broad-scope rollback by validating the new behavior in a small representative subset first.
   - **Default**: `Full Rollout` — extension's modifications apply across all targeted artifacts at Phase 4. Use when the change is mechanical or fully understood — including a **behavior-preserving, golden-file-verifiable refactor**, whose failure mode is caught by the equivalence harness rather than by production soak, so it needs no pilot scaffolding. A behavior-preserving refactor that is *not* golden-file-verifiable (e.g. a test-file migration — suite-green can hide a silently-weakened test) earns the same no-pilot default via a **mutation spot-check**: break the code-under-test and confirm the migrated test goes red.
   - **Pilot**: select 1-3 representative adopter artifacts; broader adoption is filed as a separate IMP after the pilot resolves. Use when the change introduces behavior whose failure modes can only be observed in production conditions.
   - **If `Pilot` is chosen**, define at this step:
     - **Adopter artifacts**: which 1-3 files/scripts/components will adopt the new behavior in Phase 4 — grep the [Active Pilots section](../../../process-framework-central/state-tracking/permanent/process-improvement-tracking.md#section-5--active-pilots) for each candidate before committing to it: an artifact already adopted by a live pilot must have that pilot reconciled first (resolve it, or pick a different adopter), since two pilots claiming one artifact give it two overlapping rollback scopes.
     - **Success criteria**: concrete observable signal that the pilot has succeeded (e.g., "all adopter soak counters reach 0", "30 days of clean operation", "no related bug reports").
     - **Decision trigger**: a follow-up IMP filed at Phase 4 finalization that, when processed, drives the rollout/rollback decision.
   - The pilot decision and (if applicable) the three definitions above are part of the Step 5 checkpoint material.
5. **🚨 CHECKPOINT (full-package approval)**: Present concept document, impact analysis, **pilot vs. full-rollout decision (and pilot definitions if applicable)**, and proposed implementation approach to human partner for approval. Unlike Step 3's concept-direction approval, this is the **final go/no-go before Phase 2 begins** — it signs off the complete package, not just the idea. State a one-line result for each Step-4 impact sub-check — validation-script check, column-index/value-recognition impact, 00-setup impact, documented-home, ID-prefix ownership, soak-tracking status, mechanism/value self-check, routing self-check (or "N/A — <why>" for each) — so the sign-off is informed rather than trusting blockquotes that are easy to skim past during Step 4. Before sign-off, also re-answer Step 1(c)'s duplication question — *where does this information already live?* — for **each artifact in the final scope**: scope that entered after Step 1 (often at this very checkpoint) has never faced it, and duplication gets caught here or ships (PF-IMP-1618).
   > **Single-session lightweight path**: If the extension meets **all** of these criteria — (1) artifact scope is bounded — either modification-only, OR creates at most one new template/guide artifact and no new tasks, (2) completable in a single session, (3) no new ID prefixes needed — then at this checkpoint, propose the lightweight path to the human partner. If approved:
   > - **Skip Phase 2 entirely** (Steps 6–10: no temp state file, no roadmap, no session planning)
   > - **Phase 3 compresses to**: Implement modifications (Step 12) → verify linked documents with grep sweep → integration testing (Step 15)
   > - **Phase 4 compresses to**: Checkpoint (Step 16) → update core framework files (Step 17) → update permanent state files (Step 19) → completion checklist (Step 22). Skip Steps 18 (usage docs), 20 (state file archival), and 21 (concept archival — archive concept inline at this step instead).
   > - **Pilot interaction (PF-PRO-030)**: If a pilot was chosen at Step 4.5, Step 19's pilot row registration is unchanged (still required), and Step 21's pilot conditional applies — complete the driving IMP **without `-ArchiveConcept`** (do not archive the concept inline). The concept remains in `proposals/` until the pilot reaches `Resolved` status, at which point `Update-ProcessImprovement.ps1 -NewStatus Resolved` archives the concept and moves the pilot row from Active Pilots to Completed Improvements (PF-IMP-729).
   >
   > **Mid-session scope growth**: If any of the three lightweight criteria stops holding mid-session (e.g., human feedback reframes scope to require new artifacts, multi-session work, or a new ID prefix), switch to the full path — create the temp state file (Step 6) retroactively, update the concept document in place to reflect the broader scope, and resume Phase 2 from Step 7. **If the scope grows so far that the current concept no longer describes the work** (a fundamentally larger umbrella, not just a bigger version of the same idea), don't stretch the concept in place — file a new umbrella IMP, defer the original IMP with a cross-reference to it, archive the original concept, and author a fresh concept for the new scope.

### Phase 2: State Tracking & Planning

> **Human-initiated extension (no driving IMP yet)?** File it at Phase 2 start — [`New-ProcessImprovement.ps1`](../../scripts/file-creation/support/New-ProcessImprovement.ps1), then `Update-ProcessImprovement.ps1 -MoveToSection Extensions -RoutedBy "PF-TSK-026" -Reason "<one-line>"` — so the Step 19 pilot row and the Step 21 completion transition have their anchor, and the in-flight extension is visible to IMP Triage and parallel sessions from Phase 2 onward. (A single inline-authorized filing needs no separate triage session.)

6. **Create Temporary State Tracking File** — choose the template based on extension type:
   - **Creation-heavy** (new tasks, templates, scripts): Use `New-TempTaskState.ps1` (FrameworkExtension variant):
     ```powershell
     pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/support/New-TempTaskState.ps1 -TaskName "[Extension Name]" -Variant "FrameworkExtension" -Description "Framework extension for [brief description]"
     ```
   - **Modification-heavy** (primarily changing existing tasks, templates, scripts): Use `New-StructureChangeState.ps1` with the `"Framework Extension"` ChangeType — lightweight artifact tracking without pilot/rollback/metrics:
     ```powershell
     pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/support/New-StructureChangeState.ps1 -ChangeName "[Extension Name]" -ChangeType "Framework Extension" -Description "Framework extension for [brief description]"
     ```
   - **Concept-backed (either type)**: an approved concept already exists by this point (Step 5 requires it), so `New-StructureChangeState.ps1 -FromProposal` is often the better fit — it scaffolds a lightweight phase-checklist + session-log tracker that *references* the concept rather than re-transcribing its roadmap. Prefer it when the concept already carries the roadmap detail; choose the richer variants above only when you need their artifact-tracking or task-impact tables.
     ```powershell
     pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/support/New-StructureChangeState.ps1 -ChangeName "[Extension Name]" -FromProposal -Description "Framework extension for [brief description]"
     ```
7. **Develop Implementation Roadmap** with detailed multi-session breakdown in the temporary state file. **Roadmap lines do not override framework rules**: where a line restates one (feedback-form cadence, a checkpoint gate, a task or gate ID), verify it against the rule's canonical source — inherited text drifts, and the framework rule governs (e.g. the feedback form completes at the end of *every* calendar session per [ai-tasks.md](../../ai-tasks.md#-ai-agent-session-management), never as a terminal roadmap item)
8. **Identify Required Components** (tasks, templates, guides, scripts, directories) and their dependencies
   - If the extension introduces language-specific commands or tooling, check if new fields are needed in `languages-config` files. Use [Update-LanguageConfig.ps1](../../scripts/update/Update-LanguageConfig.ps1) to add fields consistently across all language configs and the template.
   - For each new task, verify its routing entry in [ai-tasks.md](../../ai-tasks.md) carries concrete triggers (specific events, states, or conditions) — not generic "when needed" statements. Per [PF-IMP-875](../../../../process-framework-central/state-tracking/permanent/process-improvement-tracking.md), the task's own When-to-Use section convention has been removed; routing/disambiguation is now centralized in ai-tasks.md.
9. **Plan Integration Points** with existing framework components and state tracking files
10. **🚨 CHECKPOINT**: Present implementation roadmap, required components list, and session plan to human partner for approval. When the concept document already carries the roadmap and session plan and the Step 5 full-package checkpoint presented them, record this approval as obtained at Step 5 rather than re-presenting.

### Phase 3: Multi-Session Implementation

> **📋 SESSION CADENCE & LOGGING**: **One sitting = one `### Session N` entry, however many
> roadmap phases it covers.** Never split a single calendar sitting into multiple Session
> entries — log all phases run in that sitting under its one entry, noting which phases it
> covered. ("Roadmap phases" are the state file's Implementation Roadmap headings — see the
> phase-terminology note below; they are offset by one from this task definition's Phase 1–4
> headings.)
>
> **Continue-or-finalize decision after each phase**: each roadmap phase ends in a
> `🚨 CHECKPOINT` plus phase-closure work (artifact-tracking updates, session-log entry,
> next-session plan). When a phase completes, decide explicitly with the human partner whether
> to continue with the next phase in the same sitting or end the session — recommend one,
> factoring remaining session budget. Continuing requires the finished phase's checkpoint
> approval and its phase-closure work done first; never let momentum compress a checkpoint's
> review into the next phase. (The Step 5 single-session lightweight path pre-approves
> compressing all phases into one sitting.)
>
> **Resuming a phase across sessions**: When a phase spans more than one session, label the
> continuation in Session Tracking with a `(continuation)` suffix (e.g. `Session 5 — Phase 3
> (continuation)`), or sub-number parallel sub-streams within a phase (e.g. `3.1a` / `3.1b`).
> Pick one convention per extension and stay consistent. When the interval since the phase's
> last session is significant (weeks, or an explicit deferral), first re-verify the state
> file's open rows against the live tree before acting on them — a deferred tracker is a
> snapshot whose rows decay silently (project set outgrown, mechanisms superseded, work
> completed elsewhere and unlogged). Read-side counterpart of Step 14's
> Record-working-tree-reality note (PF-IMP-1681).
>
> **Phase & session terminology**: the **roadmap phases** are the state file's Implementation
> Roadmap headings (Phase 1 Concept → Phase 2 Artifact Creation → Phase 3 Integration → Phase 4
> Finalization) and are the **session-planning authority**. They are *not* this task
> definition's Phase 1–4 headings (Concept / State Tracking & Planning / Multi-Session
> Implementation / Finalization), which are offset by one — so "continue with phase 3" always
> means the *roadmap* phase. For sessions: a *calendar session* is one
> agent sitting; a *roadmap session* — the `Session N` units in the Step 11 plan — is a planned
> chunk of work that usually, but not always, maps to one calendar session. The Session Tracking
> log records calendar sessions and notes which roadmap units each covered.

11. **Execute Session-by-Session Implementation** following the detailed roadmap in temporary state tracking file:
    - **Session 1**: Core task definitions and primary infrastructure
    - **Session 2**: Supporting templates and document creation scripts
    - **Session 3**: Usage guides and integration documentation
    - **Session 4**: Framework integration and testing
12. **Modify Existing Task Definitions** (if the extension requires inserting steps into existing tasks):
    > **Step renumbering warning**: Inserting or removing numbered steps triggers cascading renumbering of all subsequent steps plus internal "Step N" cross-references. For large tasks (e.g., Bug Fixing) this can involve 10+ sequential edits. To reduce effort and errors: (1) add steps at the end of a phase where possible to minimize renumbering, (2) batch-verify all "Step" references with grep after renumbering to catch stale cross-references.
13. **Progressive Component Creation** using two-phase document creation approach:
    - **Phase A - Structure Generation**: Use scripts (New-Task.ps1, New-Template.ps1, New-Guide.ps1) to generate basic document frameworks
      - Script outputs are STARTING POINTS requiring extensive customization
      - Scripts create structural frameworks with placeholder content that MUST be replaced
    - **Phase B - Content Customization**: Apply the craft skills and best-practices guides to fully customize generated structures
      - Templates require comprehensive content development applying the [`template-development` craft skill](../../../.claude/skills/template-development/SKILL.md)
      - Guides require extensive customization following the [Guide Creation Best Practices Guide](../../guides/support/guide-creation-best-practices-guide.md)
      - Tasks require detailed process definition applying the [`task-creation` craft skill](../../../.claude/skills/task-creation/SKILL.md) (via [New Task Creation, PF-TSK-001](new-task-creation-process.md))
    - **Phase C - Framework Script Tests** (for extensions that create or modify `.ps1` / `.psm1` files): Add a Pester unit test (`<ScriptName>.Tests.ps1` under `appdev/test/automated/unit/framework/<area>/`) alongside each new script and run `pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/test/Run-Tests.ps1 -Category <area>` (or `-Quick`) to confirm green before moving on. **For behavior-preserving mass conversions** — mechanical refactors that must reproduce byte-identical side-effects across many scripts — per-script Pester is the wrong tool (it asserts expected behavior, not unchanged behavior); use the [golden-file equivalence harness recipe](../../guides/support/script-development-quick-reference.md#behavior-preserving-refactor-verification-golden-file-equivalence-harness) instead. If the extension introduces a new tracked user workflow, file a follow-up via [E2E Acceptance Test Case Creation (PF-TSK-069)](../03-testing/e2e-acceptance-test-case-creation-task.md); if it introduces a new measured performance surface, route to [Performance Test Creation (PF-TSK-084)](../03-testing/performance-test-creation-task.md).
    > **⚠️ Cross-cutting reminder**: Each task created via [PF-TSK-001](new-task-creation-process.md) carries its routing/registry/transition data in its own frontmatter + `## File Operations` + `## Next Tasks` subsections; running `Build-TaskMetadata.ps1` regenerates the ai-tasks.md tables, both registries, and the tasks/README catalog from them (PF-PRO-042). The manual residue — sibling tasks' Next Tasks/Related Resources references and the hand-written ai-tasks/registry diagrams — is completed during Phase 3 for each new task, not deferred to Phase 4.
14. **Update Temporary State Tracking** after each session with progress and next steps
    > **Record working-tree reality**: When you run a generator or migration in place during the session (regenerate a map, run a conversion, apply a migration), log that run in the Session Tracking entry even if its approval checkpoint is still open — mark it "run, pending approval". The next session reads the state file to learn what the working tree actually contains; an unlogged in-place run strands that fact in the transcript and leaves the next session's status wrong.
    > **Archive-split convention (PF-IMP-895)**: When the state file exceeds ~800 lines, archive completed session logs to a sibling file to keep the active file within read-budget thresholds. Procedure:
    > 1. Create a sibling file named `<state-file-name>-session-archive.md` in the same directory.
    > 2. Add a header linking back to the active state file: `# Session Archive for [Extension Name]` + `> Archived sessions from [active state file link]. See that file for current status.`
    > 3. Cut all completed `### Session N` entries except the most recent 2–3 (keep those for continuity context) and paste them into the archive file, preserving order.
    > 4. In the active state file's `## Session Tracking` section, add a reference line above the remaining sessions: `> **Archived sessions**: Sessions 1–N are in [<state-file-name>-session-archive.md](<relative-link>).`
    >
    > This follows the same archive-split pattern used for process-improvement-tracking.md (2026-05-13). The archive is audit-trail only — no task reads it during normal operation. Check line count at the start of each session; split proactively rather than after the file has already become unwieldy.
15. **Integration Testing** to ensure compatibility with existing framework components

### Phase 4: Framework Integration & Finalization

16. **🚨 CHECKPOINT**: First run the **end-of-extension re-read** — re-read every artifact from phases before the last, checking status banners and dependency notes against what actually shipped, `version`/`updated` frontmatter against the last real edit, and every command snippet the extension authored (run it, or read the target script's param block). Per-phase verification cannot catch cross-phase staleness — an artifact green at its own phase is silently falsified by a later one; prioritize rows whose Artifact Tracking `Verified How` reads `read-only review` or `—` (PF-IMP-1681). Then present completed extension components, integration test results, re-read findings, and remaining work to human partner for review. **Fix vs. route** for defects surfaced at closure: fix inline what is confined to the extension's own artifacts (components this extension created or modified); anything whose fix spreads beyond them — a fleet-wide migration, a behavior change to a widely-called script, a new convention — routes as an IMP, optionally alongside an in-scope interim fix.
17. **Update Core Framework Files**:
    - Add new tasks via their frontmatter + authored sections, then regenerate the task-metadata projections (ai-tasks.md tables, both registries, tasks/README): `pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/validation/Build-TaskMetadata.ps1` (PF-PRO-042; `-Check` is a pre-commit drift gate)
    - Ensure every new artifact carries a one-line source description (`.SYNOPSIS` for scripts, `description:` frontmatter for markdown, `metadata.description` for JSON) — this is what the generated [PF-documentation-map.md](../../PF-documentation-map.md) renders.
    - Update the appropriate [ID registry](../../PF-id-registry.json) with new ID prefixes if needed
    - **Regenerate the documentation map(s)**: `pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/validation/Build-DocumentationMap.ps1` (PF, default). If the extension also added or moved product or test artifacts, regenerate those trees too: `… Build-DocumentationMap.ps1 -Tree PD` and/or `… -Tree TE`. All three maps are generated, DO-NOT-EDIT projections (PF-PRO-037 / PF-PRO-050).
    - **Run the drift check per regenerated tree**: append `-Check` to each invocation (`Build-DocumentationMap.ps1 -Check` / `-Tree PD -Check` / `-Tree TE -Check`) — each must exit 0 (in sync). On non-zero exit, the on-disk map differs from what the generator produces; rerun that tree's generator and re-check. `-ReportMissing` lists any new artifact still lacking a source description.
18. **Create Usage Documentation** demonstrating how to use the new framework extension
19. **Update Permanent State Files** as defined in the concept document
    - **Soak-register new state-mutating scripts**: register each new PowerShell script that **mutates framework documents or tracked state** (the assert-then-soak / helper-routed "Pattern B" scripts soak exists to verify) with `Register-SoakScript -ScriptId <relative-path-from-project-root> -ScriptPath <absolute-path>` (loaded via `Common-ScriptHelpers`); its first `$DefaultSoakCounter` (default 3) successful invocations then call `Confirm-SoakInvocation -Outcome success` after agent verification — see [`script-soak-tracking.md`](../../../../process-framework-central/state-tracking/permanent/script-soak-tracking.md) and the [PF-PRO-028 Script Self-Verification proposal](../../../process-framework-central/proposals/old/script-self-verification.md). This explicit register is **required, not redundant**, for a helper-armored creation script (one delegating to `New-FrameworkDocument`): its in-wrapper `Register-SoakScript` no-ops under `-WhatIf`, and its tests are correctly all `-WhatIf`, so it never self-registers — confirm the row appeared with `Get-SoakStatus`. **Exempt**: standalone tool-wrapper scripts that don't mutate framework state *and* are fully verified by Pester (+ E2E) — registering one only creates a perpetually-stuck soak row (mirrors the de-facto no-soak treatment of the `tools/linkWatcher/` wrappers). Skip non-script artifacts (templates, guides, state files, sub-modules) as before.
    - **Pending-migration entries (cwd=appdev only)** — the governing rule: an appdev session never edits a registered project's working tree, so any extension outcome that must change one reaches the project only via a migration entry under `process-framework-central/per-project-migrations/<PROJECT-ID>/pending-migrations.md` (use the [Pending Migration Entry Template](../../templates/support/pending-migration-entry-template.md)). The four triggers below name the recognized change classes — a change fitting none of them that must still alter a project's tree files an entry all the same. **For each trigger, evaluate whether the change must retroactively reach already-onboarded projects, and decide at a checkpoint, not silently** — purely additive, agent-read metadata that existing projects can ignore is the canonical skip case (worked precedent: the BL-4 `kind`-discriminator back-fill to project-config bindings); when retroactive application is needed, file an entry for every registered product project. **A staged entry is inert until the next [Framework Rollout (PF-TSK-088)](framework-rollout-task.md) Mode C drains it** — staging it in appdev does not change the target projects, so treat the extension as reaching projects only once that rollout runs.
      1. **Bootstrap-seeded content** — the extension touched a `blueprint/` file *outside* `blueprint/process-framework/` (e.g. `blueprint/CLAUDE.md`, `blueprint/doc/`, `blueprint/test/`). `Push-FrameworkUpdate.ps1` mirrors only `blueprint/process-framework/` (plus per-skill `.claude/skills/` — trigger 3); the rest of `blueprint/` seeds project working trees at `Register-Project` bootstrap, so post-bootstrap changes don't reach existing projects without a migration.
      2. **Retroactive onboarding output** — the extension changed an onboarding artifact (a `00-setup` task, or a template/guide consumed during onboarding) whose output is already *materialized* in already-onboarded projects (e.g. state files, `source-code-layout.md`, scaffolded `src/`/`test/` directories). Push mirrors the changed task/template, but the artifacts those already produced in existing projects are not regenerated.
      3. **Framework-owned skill bindings** — skill *files* under `blueprint/.claude/skills/` auto-deploy via `Push-FrameworkUpdate.ps1`'s per-skill `.claude/skills/` mirror and need no migration entry; the skill's `recommended_skills` *binding* (project-config / language-config) is a project-local config edit that reaches already-registered projects only via a Mode C migration entry — the binding is rollout-applied, not manual or deferred.
      4. **Extension-initiated change to a project's existing tree** — the extension obsoletes, rewrites, or deletes something a project already has that is not onboarding output (a legacy directory the extension made obsolete, a project-local file the framework no longer owns). Nothing mirrors or bootstraps this; the migration entry is the only sanctioned route — never touch the project's copy from cwd=appdev (PF-IMP-1617).
    - **If a pilot was chosen at Step 4.5** (PF-PRO-030), register the pilot in the **Section 5 — Active Pilots** subsection of the central [process-improvement-tracking.md](../../../process-framework-central/state-tracking/permanent/process-improvement-tracking.md) (Phase 7 schema, 2026-05-11):
      ```powershell
      # Length caps: -Adopters/-SuccessCriteria ≤500 chars, -DecisionTrigger ≤200 — compose to length.
      pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/support/New-ProcessImprovement.ps1 `
          -AsPilot `
          -SourceConcept "<PF-PRO-NNN>" -OriginatingTask "<PF-TSK-NNN>" `
          -Adopters "<comma-separated adopter artifacts>" `
          -SuccessCriteria "<criteria text>" `
          -DecisionTrigger "<PF-IMP-NNN or descriptive text>"
      ```
      The script consumes the next PF-IMP-NNN ID from the registry and writes the pilot row with status `Active`. Note the assigned PF-IMP-NNN — Step 21 conditional below depends on its status.
20. **Move Temporary State Tracking** file to `the resolved `state-tracking/temporary/old/` directory (via `Get-StateTrackingContext`)`. (This step is unchanged whether or not a pilot was chosen — the implementation work is complete; the pilot lifecycle is now owned by the Active Pilots row.)
21. **Archive Completed Concept Document**: Move the framework extension concept document from `appdev/process-framework-central/proposals/` to `appdev/process-framework-central/proposals/old/` — the concept has served its purpose and should not remain alongside active proposals. Archive it with the driving IMP's completion transition rather than by hand, so the move is `-WhatIf`-able and re-runnable (PF-IMP-1688):
    ```powershell
    pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/update/Update-ProcessImprovement.ps1 `
        -ImprovementId "<driving PF-IMP-NNN>" -NewStatus "Completed" -Impact "<HIGH|MEDIUM|LOW>" `
        -ValidationNotes "<what shipped>" -ArchiveConcept "<PF-PRO-NNN>"
    ```
    - **Conditional on pilot status (PF-PRO-030)**: if a pilot was chosen at Step 4.5, run the completion transition **without `-ArchiveConcept`** — complete the driving IMP now (implementation is genuinely done; leaving it open would duplicate the pilot row, PF-IMP-1872 precedent 2026-07-29) but leave the concept in `proposals/`: it is the source of truth for the rollout/rollback decision and the spec for what is being scaled, and its archival is bound to the **pilot row**, not the driving IMP. When the pilot is later resolved via [`Update-ProcessImprovement.ps1`](../../scripts/update/Update-ProcessImprovement.ps1) `-NewStatus Resolved`, the script archives the concept doc and moves the pilot row from Active Pilots to Completed Improvements (PF-IMP-729). Record in the driving IMP's ValidationNotes that the concept archival rides the pilot (name the pilot row and decision-trigger IMPs).
22. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Outputs

### Concept Phase Outputs

- **Framework Extension Concept Document** - Comprehensive proposal in `appdev/process-framework-central/proposals/[extension-name]-concept.md` including workflow definition, artifact dependency map, and state tracking integration plan
- **Impact Analysis** - Documentation of how the extension affects existing framework components

### Implementation Phase Outputs

- **New Task Definitions** - Multiple interconnected tasks with clear input requirements, process workflows, and output specifications
- **Supporting Infrastructure** - Templates, guides, scripts, and directories for extension functionality
- **Integration Documentation** - Documentation showing how the extension works with existing framework workflow
- **Updated Core Framework Files** - Modified ai-tasks.md, the appropriate generated documentation map (PF-documentation-map.md for PF artifacts, doc/PD-documentation-map.md for product artifacts, test/TE-documentation-map.md for test artifacts — all regenerated via `Build-DocumentationMap.ps1 [-Tree PD|TE]`, never hand-edited), and the appropriate ID registry

### State Tracking Outputs

- **Temporary State Tracking File** - Multi-session implementation tracker with detailed roadmap and progress tracking
- **Updated Permanent State Files** - Enhanced existing state files or new permanent state files as defined in concept

## State Tracking

The following state files must be updated as part of this task:

- **Temporary State Tracking File** - Create using New-TempTaskState.ps1 to track multi-session implementation progress
- [Documentation Map](../../PF-documentation-map.md) - Update with all new artifacts and their relationships
- [Process Improvement Tracking](../../../process-framework-central/state-tracking/permanent/process-improvement-tracking.md) - Update with framework capability enhancements
- **Additional State Files** - As defined in the framework extension concept document (may include new permanent state files or updates to existing ones)

## ⚠️ MANDATORY Task Completion Checklist

> Completion discipline, output verification, and the feedback form are governed by the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md) (Phase C). The items below are the **Framework-Extension–specific** verifications that plug into it.

> **Note**: This is typically a multi-session task. Complete verification applies to the ENTIRE extension across all sessions. For **single-session lightweight path** extensions (approved at Step 5), items marked *(full path only)* can be skipped.

Before considering this task finished:

- [ ] **Craft skills checked**: `recommended_skills` consulted at Step 0; the bound craft skills (`framework-extension-concept`, plus `template-development` / `creation-script-development` where the extension created templates or scripts) activated when available (or their absence noted)
- [ ] **Phase 1 — Verify Concept**: Confirm concept development and approval completed

  - [ ] Framework extension concept document created using New-FrameworkExtensionConcept.ps1 script
  - [ ] Template extensively customized applying the `framework-extension-concept` craft skill
  - [ ] Comprehensive workflow definition with clear input-process-output flow
  - [ ] Artifact dependency map clearly shows how new artifacts serve as inputs for subsequent tasks
  - [ ] State tracking integration strategy defined (new permanent state files vs. updating existing ones)
  - [ ] Human approval obtained for concept before implementation

- [ ] **Phases 2–3 — Verify Implementation**: Confirm all extension components implemented using two-phase approach *(full path only)*

  - [ ] **Phase A - Structure Generation**: All document structures generated using appropriate scripts
    - [ ] Task definitions created using New-Task.ps1 (structural framework only)
    - [ ] Templates created using New-Template.ps1 (structural framework only)
    - [ ] Guides created using New-Guide.ps1 (structural framework only)
  - [ ] **Phase B - Content Customization**: All generated structures fully customized
    - [ ] Task definitions contain detailed input-process-output specifications (not placeholder content)
    - [ ] Templates contain comprehensive customizable content (not placeholder sections)
    - [ ] Guides contain detailed step-by-step instructions and examples (not template boilerplate)
  - [ ] Integration documentation shows how extension works with existing framework
  - [ ] Multi-session implementation tracked in temporary state file with two-phase progress tracking
  - [ ] **Framework script verification**: for each new or modified `.ps1`/`.psm1` produced by this extension, the corresponding Pester unit test (`<ScriptName>.Tests.ps1`, fixture modeled on a real project's row format) exists and runs green; a new/modified Python script with no Pester harness was verified by a recorded before/after contrast run instead. Full Pester suite passes at extension close. N/A if the extension produced no scripts.

- [ ] **Phase 4 — Verify Framework Integration**: Confirm extension properly integrated

  - [ ] [ai-tasks.md](../../ai-tasks.md) updated with new tasks
  - [ ] [Documentation Map](../../PF-documentation-map.md) regenerated via [`Build-DocumentationMap.ps1`](../../scripts/validation/Build-DocumentationMap.ps1) (plus `-Tree PD` / `-Tree TE` if the extension touched product/test artifacts); every new artifact carries a source description
  - [ ] Run [`Build-DocumentationMap.ps1 -Check`](../../scripts/validation/Build-DocumentationMap.ps1) (and `-Tree PD -Check` / `-Tree TE -Check` for any regenerated tree) — exit 0 (maps in sync)
  - [ ] [PF ID Registry](../../PF-id-registry.json) updated with new prefixes if needed
  - [ ] Permanent state files updated as defined in concept document
  - [ ] **Guide Update Inventory resolved**: every row of the concept's Guide Update Inventory carries a terminal disposition — **done**, or **skipped with a recorded reason** — before documentation is reported complete. "Optional" is not a terminal state; an optional-marked row left unresolved is a skip without a reason (PF-IMP-1638). N/A if the concept has no such table (Creation-type).

- [ ] **Phase 4 — Update State Files**: Ensure all state tracking files have been updated
  - [ ] Temporary state tracking file moved to the resolved `state-tracking/temporary/old/` directory (via `Get-StateTrackingContext`)
  - [ ] **Concept document archive (PF-PRO-030 pilot rule)**: if no pilot was chosen at Step 4.5, concept document moved to `appdev/process-framework-central/proposals/old/` via the driving IMP's `-ArchiveConcept` completion. **If a pilot was chosen: the driving IMP is Completed *without* `-ArchiveConcept` (its ValidationNotes name the pilot row + decision trigger), the concept document remains in `appdev/process-framework-central/proposals/`, and the pilot row in [Section 5 — Active Pilots](../../../process-framework-central/state-tracking/permanent/process-improvement-tracking.md#section-5--active-pilots) has status `Active` (concept will be archived later by `Update-ProcessImprovement.ps1 -NewStatus Resolved` when the pilot resolves).**
  - [ ] [Documentation Map](../../PF-documentation-map.md) reflects all new artifacts
  - [ ] [Process Improvement Tracking](../../../process-framework-central/state-tracking/permanent/process-improvement-tracking.md) updated with framework capability enhancement
  - [ ] **Pilot row registered (PF-PRO-030)**: if a pilot was chosen at Step 4.5, the pilot row exists in the Active Pilots section with status `Active`, decision trigger noted, and adopters listed. N/A if Full Rollout was chosen.
  - [ ] **Soak verification registered**: every new **state-mutating** PowerShell script (mutates framework documents/tracked state) is registered in [`script-soak-tracking.md`](../../../../process-framework-central/state-tracking/permanent/script-soak-tracking.md) via `Register-SoakScript` (verify via `Get-SoakStatus -ScriptId <id>`). Standalone tool-wrapper scripts verified by Pester (+ E2E) that don't mutate framework state are exempt (registering them creates perpetually-stuck soak rows — mirrors the `tools/linkWatcher` wrappers). N/A if the extension created no new state-mutating scripts.
  - [ ] **Module helper `-WhatIf` verification**: Any new `.psm1` helper that exposes `[CmdletBinding(SupportsShouldProcess=$true)]` has been smoke-tested by invocation from a script (not just an in-process call from a non-module pwsh session), confirming `$WhatIfPreference` is honored across the module boundary. Module SessionState isolation prevents preference inheritance via the scope chain; helpers must read the caller's preference explicitly via `$PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')`. N/A if no module helpers were created. (See `ExecutionVerification.psm1::_Test-CallerWhatIf` for the canonical pattern.)
  - [ ] **Pending-migration entries filed (cwd=appdev only)**: All four Step 19 migration triggers evaluated — (1) the extension touched a `blueprint/` file outside `blueprint/process-framework/` (e.g. `blueprint/CLAUDE.md`, `blueprint/doc/`, `blueprint/test/`), (2) it changed an onboarding artifact (`00-setup` task or onboarding-consumed template/guide) whose output is already materialized in already-onboarded projects, (3) it shipped a framework-owned skill, whose `recommended_skills` binding reaches registered projects only via a Mode C migration entry (skill *files* auto-deploy via the per-skill `.claude/skills/` mirror), or (4) it requires a change to a project's *existing* working tree that is not onboarding output (deleting an obsoleted legacy directory, rewriting a project-local file the framework no longer owns) — and wherever one fires, the retroactive-need decision was made at a checkpoint (Step 19's evaluate-and-decide rule; additive, agent-read metadata is the canonical skip case) and any needed entries filed under `process-framework-central/per-project-migrations/<PROJECT-ID>/pending-migrations.md` for every registered product project, using the [Pending Migration Entry Template](../../templates/support/pending-migration-entry-template.md). `Push-FrameworkUpdate.ps1` mirrors only `blueprint/process-framework/` plus per-skill `.claude/skills/`; content outside those, and already-produced onboarding output, reach existing projects only via a migration entry, which takes effect only when the next Framework Rollout Mode C drains it (staged ≠ applied). N/A if no trigger applies.
- [ ] **Feedback form** completed per the [Task Execution Protocol → Feedback step](../../guides/framework/task-execution-protocol-guide.md#feedback-step) — task ID `PF-TSK-026`, context "Framework Extension Task".

## File Operations

| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | Framework extension concept document | [`New-FrameworkExtensionConcept.ps1`](../../scripts/file-creation/support/New-FrameworkExtensionConcept.ps1) | Detailed concept document for framework extension |
| **Creates** | Temporary state tracking file | `New-TempTaskState.ps1` | Multi-session implementation tracking |
| **Updates** | [`PF-documentation-map.md`](../../PF-documentation-map.md) | Manual | Register new framework documents |
| **Updates** | [`process-improvement-tracking.md`](../../../../process-framework-central/state-tracking/permanent/process-improvement-tracking.md) | Manual | Track extension progress if linked to IMP entry |
| **Updates** | [`script-soak-tracking.md`](../../../../process-framework-central/state-tracking/permanent/script-soak-tracking.md) | Manual via `Register-SoakScript` | Conditional: if the extension creates new PowerShell scripts, each is registered for 5-invocation soak verification (PF-PRO-028). |
| **Updates** | Multiple process framework files (varies) | Manual | Updates vary based on extension scope |

## Next Tasks

- [**Process Improvement Task**](process-improvement-task.md) - If further refinements are needed for the extension
- **Extension-Specific Tasks** - Use the newly created tasks that comprise the framework extension

<!-- merged from transition-registry entry: Framework Extension Task -->
### Prerequisites for Transition

- [ ] Framework Extension Concept Document created and approved
- [ ] Impact analysis documented, including the per-declaration enforcement trace (Step 4)
- [ ] **Pilot vs. Full Rollout decision made at Step 4.5** (PF-PRO-030); if pilot, adopters / success criteria / decision trigger defined
- [ ] New task definitions created and integrated into `ai-tasks.md`
- [ ] Supporting infrastructure created (templates, guides, scripts, directories)
- [ ] Core framework files updated (`ai-tasks.md`, `PF-documentation-map.md`, PF ID Registry)
- [ ] Temporary state tracking file completed (all phases done)
- [ ] **Framework script verification done**: every new or modified `.ps1`/`.psm1` produced by this extension has a co-located Pester unit test (`<ScriptName>.Tests.ps1`, fixture modeled on a real project's row format) green at extension close; a new/modified Python script with no Pester harness was verified by a recorded before/after contrast run instead. N/A if the extension produced no scripts. Introduced by the Framework Self-Testing extension (PF-PRO-035).
- [ ] **If pilot was chosen**: pilot row exists in central [Section 5 — Active Pilots](../../../../process-framework-central/state-tracking/permanent/process-improvement-tracking.md#section-5--active-pilots) with status `Active`; the driving IMP is Completed without `-ArchiveConcept`; concept doc remains in `appdev/process-framework-central/proposals/` (archive deferred until pilot resolves)

### Next Task Selection

- **Further refinements needed**: → Process Improvement (for polish and adjustments)
- **New tasks ready to use**: → Execute the newly created extension-specific tasks
- **Documentation updates needed**: → Structure Change (if reorganization required)
- **Pilot was chosen — eventual rollout/rollback decision**: → Process Improvement (later session) processes the decision-trigger IMP filed at Phase 4. On resolution: `Update-ProcessImprovement.ps1 -ImprovementId <pilot PF-IMP-NNN> -NewStatus Resolved -Impact <HIGH|MEDIUM|LOW> -ValidationNotes "<decision summary>"` records the disposition, automatically archives the concept doc to `proposals/old/`, and moves the pilot row from Active Pilots to Completed Improvements (PF-IMP-729). The originally-deferred archive is owned by this later session, not the original Framework Extension Task session.

## Related Resources

### Core Framework Resources

- [Task-Based Development Principles](../../ai-tasks.md#understanding-task-based-development) - Understanding framework principles
- [New Task Creation Process](new-task-creation-process.md) - For creating individual tasks within extensions
- [Structure Change Task](structure-change-task.md) - For understanding structural modifications vs. extensions
- [Process Improvement Task](process-improvement-task.md) - For understanding granular improvements vs. extensions

### Development Infrastructure

- [`template-development` craft skill](../../../.claude/skills/template-development/SKILL.md) - the template-design craft (replaces the retired Template Development Guide); activated by the Step 0 Check Recommended Skills
- [`creation-script-development` craft skill](../../../.claude/skills/creation-script-development/SKILL.md) - the script-authoring craft (replaces the retired Document Creation Script Development Guide); activated by the Step 0 Check Recommended Skills
- [`framework-extension-concept` craft skill](../../../.claude/skills/framework-extension-concept/SKILL.md) - the concept-document craft (replaces the retired Framework Extension Customization Guide); activated by the Step 0 Check Recommended Skills

### State Management

- [New-TempTaskState.ps1](../../scripts/file-creation/support/New-TempTaskState.ps1) - State tracking for creation-heavy extensions (use `-Variant FrameworkExtension` for multi-artifact tracking)
- [New-StructureChangeState.ps1](../../scripts/file-creation/support/New-StructureChangeState.ps1) - State tracking for modification-heavy extensions
- [Documentation Map](../../PF-documentation-map.md) - Framework structure and artifact relationships
- [Process Improvement Tracking](../../../process-framework-central/state-tracking/permanent/process-improvement-tracking.md) - Framework capability tracking
