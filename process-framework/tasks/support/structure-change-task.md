---
id: PF-TSK-014
type: Process Framework
category: Task Definition
domain: agnostic
version: 2.13
created: 2025-06-07
updated: 2026-08-10
description: "Manage structural changes to documentation"
use_when: >-
  Reorganizing directory structures, file locations, or documentation architecture. Triggers: 'reorganize directory X', 'move files from A to B', 'restructure docs', 'rename X to Y'.
triggers:
  - "reorganize directory X"
  - "move files from A to B"
  - "restructure docs"
  - "rename X to Y"
automation: semi
scripts:
  - ../../scripts/file-creation/support/New-StructureChangeState.ps1
  - ../../scripts/file-creation/support/New-PendingMigration.ps1
  - ../../scripts/validation/Build-DocumentationMap.ps1
trigger_status:
  - raw: "`process-improvement-tracking.md` / _(user request)_ → IMP item routed to PF-TSK-014"
output_status:
  - raw: "Documentation maps → updated; `process-improvement-tracking.md` → IMP item → `Completed`"
next_tasks:
  - task: process-improvement-task.md
    condition: "If further process refinements are needed"
  - task: tools-review-task.md
    condition: "Review any tools affected by structure changes"
---

# Structure Change Task

> **▶ Execute this task under the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md).** This file holds only the Structure-Change–specific content; the universal contract every task shares lives once in the protocol and is mandatory here.

## Purpose & Context

This task **orchestrates** systematic changes to documentation structures, templates, or frameworks across multiple files. It plans the overall change, delegates specialized work to appropriate tasks/processes (e.g., task creation to PF-TSK-001, template work to the `template-development` craft skill), tracks progress, and coordinates handover — ensuring consistent, well-tested structural evolution with clear migration paths and rollback options.

> **Key principle**: PF-TSK-014 is a **coordinator**, not an executor of specialized work. It should never bypass the quality gates of specialized tasks by doing their work inline.

## AI Agent Role

**Role**: Project Coordinator / Change Manager
**Mindset**: Delegation-focused, impact-aware, change-management oriented
**Focus Areas**: Change impact analysis, delegation planning, progress tracking, handover coordination
**Communication Style**: Analyze dependencies and change ripple effects, identify which specialized tasks/processes to delegate to, ask about migration preferences and rollback requirements

## Context Requirements

- **Critical (Must Read):**

  - [Structure Change Proposal](../../templates/support/structure-change-proposal-template.md) - Detailed description of proposed changes
  - [Documentation Map](../../PF-documentation-map.md) - Map of all documentation

- **Important (Load If Space):**
  - **LinkWatcher Capabilities Reference** — `<LinkWatcher install>/doc/user/handbooks/linkwatcher-capabilities-reference.md` (install default `%USERPROFILE%\bin`, override via `LINKWATCHER_INSTALL_DIR`) - What LinkWatcher updates automatically vs. what needs manual attention during moves (see [LinkWatcher and Structure Changes](#linkwatcher-and-structure-changes) below)
  - [Script Development Quick Reference](../../guides/support/script-development-quick-reference.md) - PowerShell execution patterns and parameter checking (**always check script parameters with `Get-Help <script> -Parameter *` before running**)
  - [`template-development` craft skill](../../../.claude/skills/template-development/SKILL.md) - **REQUIRED** for creating or updating templates (consulted inline at the point of delegation — this task has no skill binding)
  - [`creation-script-development` craft skill](../../../.claude/skills/creation-script-development/SKILL.md) - **REQUIRED** for creating automation scripts (consulted inline at the point of delegation — this task has no skill binding)
  - [Process Framework Documentation](../../README.md) - Current documentation structure
  - [Feedback Forms](../../../process-framework-central/feedback/feedback-forms) - Feedback related to current structure

- **Reference Only (Access When Needed):**
  - [Process Framework Task Registry — Trigger & Output fields](../../infrastructure/process-framework-task-registry.md) - Consult trigger/output blocks and State File Trigger Index when changes affect task trigger conditions or state file interactions

## Process

> **⚠️ MANDATORY: Create backup copies of all files before making changes.**
>
> **📋 IMPORTANT: Use established document creation processes for all new templates, guides, and scripts. Do NOT create these manually - use the provided scripts and follow the development guides.**
>
> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

### Scope Assessment

1. **Identify Scope**: Review the structure change requirements and identify all files affected. For an IMP-triggered change, first verify the row's premise against the live tree — its described current state, counts, and fix direction are raw input that may have staled or been wrong at filing (PF-IMP-1591's premise was false and the correct fix was the opposite of what was filed); carry any disconfirmation into the classification and the Step 2 checkpoint as a scope input. Classify the change:

   | Criteria | Lightweight | Full |
   |---|---|---|
   | **Files affected** | ≤ 5 files | > 5 files |
   | **Change type** | Single-type (rename, move, update references, add column) | Multi-type (template + guide + script + content) |
   | **Breaking changes** | No (backward-compatible or self-contained) | Yes (changes that affect other tasks/workflows) |
   | **Cross-references** | Handled by LinkWatcher or minimal manual updates | Extensive manual cross-reference updates needed |
   | **Incoming references** | ≤ 20 files reference the affected file(s) | > 20 files reference the affected file(s) (grep to verify) |

   > A change qualifies as **Lightweight** if it meets ALL lightweight criteria. If ANY criterion falls into Full, use the Full process. **Files affected** counts the files whose content this change decides; per-project pending-migration ledger entries scaffolded from a single decision ([Step 14.5](#full-process)) count as one, however many projects they fan out to.

2. **🚨 HUMAN APPROVAL REQUIRED**: Present the scope assessment to the human partner with a recommendation (Lightweight or Full) and the reasoning. **Do not proceed until the human confirms the mode.**

   > If Lightweight → continue to [Lightweight Process](#lightweight-process)
   > If Full → continue to [Full Process](#full-process)
   >
   > **Lean-Full Variant**: If the change exits Lightweight on file count alone and is either *pure text substitution* (status-label rename, terminology update, deprecation propagation) or a *content rewrite of existing files* (e.g. guide/task distillation) — with no new templates/scripts/tasks/guides, no breaking changes, and nothing to delegate — use the Full path with the [Lean-Full Variant](#lean-full-variant) shortcut. Proposal not required.
   >
   > **Multi-batch execution (large changes)**: A large structural change may be run as a **sequence of batches**, each classified Lightweight or Full on its own merits. When you do, create the **durable state file early** ([New-StructureChangeState.ps1](../../scripts/file-creation/support/New-StructureChangeState.ps1)) and make its audit table + per-batch progress + deferred queue the source of truth — **not** the owning IMP row's Notes, which bloat and strand a multi-session run. Any keep/delete/merge or per-file plan the batches execute lives in that durable artifact (or the IMP row), never only in a session transcript, so the next session can resume without re-deriving it.

---

### Lightweight Process

> For small, contained structure changes (≤ 5 files, single-type, no breaking changes).

3. **Study LinkWatcher capabilities**: Read the LinkWatcher Capabilities Reference (`<LinkWatcher install>/doc/user/handbooks/linkwatcher-capabilities-reference.md`, see Context Requirements) before any change that moves, renames, or deletes a file or directory — do not assume, the reference is authoritative, and the [Move Procedure](#file-and-directory-move-procedure)'s diagnosis table presumes its coverage rules. When the change alters no paths, the operative fact is narrower: LinkWatcher updates path references only — never text patterns, and never the prose descriptions surrounding a path — which is what the Step 5 sweep exists for; read the full reference anyway when the change's exposure to path references is unclear.
4. **Make Changes**: Implement the structure change directly:
   - Use established scripts when creating new documents ([New-Template.ps1](../../scripts/file-creation/support/New-Template.ps1), [New-Guide.ps1](../../scripts/file-creation/support/New-Guide.ps1), etc.)
   - For markdown table changes, consider [Add-MarkdownTableColumn.ps1](../../scripts/Add-MarkdownTableColumn.ps1)
   - **For file/directory moves**: Follow the [File and Directory Move Procedure](#file-and-directory-move-procedure) below
   - **For file splits** (one file into two): Follow the [File Split Procedure](#file-split-procedure) below
   - **For framework-script edits** (`.ps1` / `.psm1`): follow [Framework-Script Edit Verification](#framework-script-edit-verification).

5. **Grep sweep for replaced patterns**: Before the checkpoint, grep the entire project for old values/patterns being replaced (status labels, terminology, naming conventions). LinkWatcher updates path references automatically, but does **not** update text patterns — status labels in particular are typically scattered across task definitions, guides, scripts, context maps, and test specs. Update any active references found — a hit re-opens Step 4, so re-run any verification already performed (e.g. a touched script's Pester run) over the expanded set — and bring sweep results to the checkpoint.

   > File/directory moves and file splits already include grep verification in their dedicated procedures — this step covers the broader case (non-path replacements).
   >
   > **Pending-migration pointer (cwd=appdev)**: if this change touches a `blueprint/` file *outside* `blueprint/process-framework/` (e.g. `blueprint/CLAUDE.md`, `blueprint/doc/`), file a pending-migration entry per the [completion checklist](#lightweight-completion-checklist) — Push mirrors only `blueprint/process-framework/` (plus per-skill `.claude/skills/`), so anything else reaches existing projects only via a migration entry (see Full [Step 14.5](#full-process)).

6. **🚨 CHECKPOINT**: Present implemented changes and affected files to human partner for review
7. **Verify**: Confirm all changes are correct:
   - All affected files updated
   - Cross-references valid (check LinkWatcher log if relevant)
   - No broken links or orphaned references

8. **Regenerate the affected documentation maps and verify**:
   - All three maps (PF / PD / TE) are generated, DO-NOT-EDIT projections (PF-PRO-037 / PF-PRO-050) of each artifact's source description (`.SYNOPSIS` / `description:` frontmatter / `metadata.description`) — **never hand-edited**. Moves/adds/removes are picked up automatically on regeneration.
   - **Regenerate each tree the change touched**: `pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/validation/Build-DocumentationMap.ps1` (PF, default), `… Build-DocumentationMap.ps1 -Tree PD` (product `doc/`), `… Build-DocumentationMap.ps1 -Tree TE` (test `test/`).
   - **Run the drift check per regenerated tree**: append `-Check` to each tree's invocation (`Build-DocumentationMap.ps1 -Check` / `-Tree PD -Check` / `-Tree TE -Check`) — each must exit 0 (in sync). On non-zero exit, the on-disk map differs from generator output; rerun that tree's generator and re-check. `-ReportMissing` lists files still lacking a source description.

9. **🚨 MANDATORY FINAL STEP**: Complete the [Lightweight Completion Checklist](#lightweight-completion-checklist) below

---

### File and Directory Move Procedure

When moving or renaming files/directories as part of a structure change, follow this procedure for each move:

1. **Move one file or directory at a time** — do not batch multiple moves simultaneously
2. **Wait for LinkWatcher to finish processing** — check the active log file (`ls -lt logs/linkwatcher/LinkWatcherLog*.txt | head -1`) for completion of the update cycle. Phase 5 moved LinkWatcher's runtime artifacts from `process-framework-local/tools/linkWatcher/` to the project-root `logs/linkwatcher/` directory.
3. **Verify all references were updated** — grep for the old path across the project; no remaining hits means *literal* references are clean. **This grep does not catch runtime-constructed paths** (`Join-Path`, f-strings, here-strings, `write_text` / `Set-Content` / `Out-File` targets): a script that builds the moved path at runtime won't surface in grep yet keeps emitting the old location. For directory moves and any path that scripts write into, also apply the [generator audit (Full Step 4.b)](#full-process) to the moved location and fix the write site before considering the move complete
4. **If references were NOT updated**, diagnose the root cause before manual fixing:

   | Symptom | Likely Cause | Action |
   |---------|-------------|--------|
   | Path inside `[brackets]` not updated | Template placeholder (e.g., `[Feature Name]`) — not a real link | Manual update required — LinkWatcher correctly skips these |
   | Path inside fenced code block not updated | Illustrative example, not a navigable reference | Manual update required — LinkWatcher correctly skips these |
   | Path doesn't resolve to any file on disk | Hypothetical example or already-deleted target | Manual update or removal required |
   | Path exists but LinkWatcher missed it | Possible phantom link target (see PD-BUG-075) or unsupported pattern | Investigate root cause — check if the file type is monitored and the pattern is in the Capabilities Reference (`<LinkWatcher install>/doc/user/handbooks/linkwatcher-capabilities-reference.md`); per-file-type fixes: `file-type-quick-fix.md` alongside it |
   | External URL (`http://`, `https://`) | LinkWatcher does not update external URLs | Manual update required if URL changed |

> **Key rule**: Always identify the root cause before manually fixing. If LinkWatcher should have updated a reference but didn't, that's a bug to investigate — not something to silently work around.

5. **If the moved target is a runtime or output directory** (logs, generated caches, build output), update `.gitignore` in the same change so its new path stays ignored. A stale ignore rule still naming the *old* path lets the relocated runtime files — often multi-MB logs — get swept into the next commit.

---

### File Split Procedure

When splitting one file into two separate files (e.g., extracting a section into its own document), follow this procedure:

1. **Create the new file** with the content to be extracted. Use established scripts if applicable (e.g., `New-Guide.ps1`, `New-Template.ps1`)
2. **Remove the extracted content** from the original file
3. **If the original file needs to move or rename** (e.g., its scope changed), follow the [File and Directory Move Procedure](#file-and-directory-move-procedure) for that step
4. **Review all references to the original file** — this is the critical split-specific step:
   - Grep for all files referencing the original file path
   - For each reference, check whether it refers to content that stayed in the original file, moved to the new file, or is relevant to both
   - Update references accordingly: some will stay, some will point to the new file, and some may need to reference both files
   - Pay special attention to anchor links (`#section`) — sections that moved to the new file need their references redirected
5. **Update documentation maps** — add the new file and update the original file's entry if its scope or description changed

> **Why manual review is required**: LinkWatcher updates references when files move, but a split creates a *new* file — it doesn't know which references should point to the new file vs. the original. Every reference must be evaluated by the agent.

---

### File and Directory Deletion Procedure

When **deleting** a file or directory as part of a structure change (sibling to the Move and Split procedures above), follow this procedure for each target:

1. **Classify the target** — the class drives every decision below:
   - *Migrated* — content already relocated (e.g. to `process-framework-central`); the old path is dead and references repoint to the new home.
   - *Only-copy* — content exists nowhere else; inventory what depends on it and decide repoint / de-link / **restore-before-delete** before removing anything.
   - *Disposable runtime* — logs, generated caches, `*.tmp`; safe to remove because the generator recreates it.
2. **Inventory inbound references**: grep the project for the path. For each hit, decide repoint (target moved), de-link (target gone for good), or restore-before-delete (the reference is load-bearing and the content must survive elsewhere first).
3. **Purge dead references in project-owned files; leave historical/archive prose intact** — completed state files, archived tracking rows, and changelog entries legitimately name now-deleted paths; editing them rewrites history.
4. **Fix mirrored-blueprint write sites**: if a `.ps1`/`.psm1`/template under `blueprint/process-framework/` constructs or defaults to the deleted path, fix the write site. If that fix is out of this change's scope, file an IMP so the stale default is not left to resurrect the directory.
5. **Delete, then re-validate**: run [`Validate-StateTracking.ps1`](../../scripts/validation/Validate-StateTracking.ps1) and confirm the deletion holds for one validation cycle — a deleted directory reappearing empty is the tell that a stale validation-output default (Step 4) is recreating it.

### Task Retirement / Merge Procedure

When **retiring or merging a task definition** (sibling to the Move and Split procedures), the task file is deleted *and* a web of generated and hand-written task metadata must be reconciled:

1. **Re-point referrers**: update every `next_tasks` entry and in-body link that targets the retiring task (across task definitions, guides, and workflows) to its successor or merge target.
2. **Reconcile the hand-written registry regions**: [`Build-TaskMetadata.ps1`](../../scripts/validation/Build-TaskMetadata.ps1) regenerates the task tables, but the [task registry](../../infrastructure/process-framework-task-registry.md)'s trigger-chain diagram and the State-File Trigger Index are **hand-written** and survive regeneration — add a catalog tombstone, fix the trigger-chain diagram, and scrub the State-File Trigger Index manually.
3. **Resolve the retired task's `status` / `trigger_status` ownership**: decide for each owned status whether it is a within-session transient (drop it) or must be **re-homed** to the merge target, and update the affected state files accordingly.
4. **Delete the task file** via the [File and Directory Deletion Procedure](#file-and-directory-deletion-procedure) above.
5. **Regenerate and drift-check both projections**: `Build-TaskMetadata.ps1` then `-Check` (exit 0), and `Build-DocumentationMap.ps1` then `-Check` (exit 0).

### Framework-Script Edit Verification

For any framework-script edit (`.ps1` / `.psm1`) made during a structure change — Lightweight Step 4 or Full Step 14 — add or update the script's Pester unit test (`<ScriptName>.Tests.ps1` under `appdev/test/automated/unit/framework/<area>/`) inline with the edit. The test pass via `pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/test/Run-Tests.ps1 -Category <area>` (or `-Quick`) is the validation evidence — and for mass renames / column moves / path-prefix changes touching many scripts, the cheapest catch for silent breakage. If the change affects a tracked user workflow ([user-workflow-tracking.md](../../../doc/state-tracking/permanent/user-workflow-tracking.md)) or a measured performance surface, file a follow-up via [E2E Acceptance Test Case Creation (PF-TSK-069)](../03-testing/e2e-acceptance-test-case-creation-task.md) or [Performance Test Creation (PF-TSK-084)](../03-testing/performance-test-creation-task.md) respectively.

---

### Full Process

> For large, multi-type, or breaking structure changes.

#### Lean-Full Variant

> **When to use**: If the only reason this change exited Lightweight is file count, and the change is either *pure text substitution* (status-label rename, terminology update, deprecation propagation) or a *content rewrite of existing files* (e.g. guide/task distillation) — in both cases single-purpose, with no new templates/scripts/tasks/guides, no breaking changes, and nothing to delegate — the proposal and delegation planning are overkill. Run the Full path with these shortcuts:
> - **Steps 3–4 still apply** (LinkWatcher study + the mandatory Impact Analysis) — a lean change still needs its full scope mapped. **Skip only Step 5** (the proposal); go from Step 4 straight to Step 6.
> - In Step 6, use `-ChangeType "Content Update"` (or `"Rename"` for path moves).
> - **Skip Steps 11–13** (no delegation — nothing to delegate by definition).
> - Run the [Lightweight grep sweep](#lightweight-process) (its Step 5) before the execution checkpoint — for a mechanical substitution, grep that no active reference to the old token/pattern remains; for a content rewrite (no single old→new token), instead confirm inbound references and `#anchor` links to any renamed or removed headings still resolve (LinkWatcher does not validate anchors). Then continue with Step 14 (Direct Execution).
> - In cleanup (Step 19), there is no proposal to archive — skip that bullet only.
> - **Large per-file sweeps** may fan out to parallel sub-agents — each edits its file and reports a per-file diff, the orchestrator verifies — provided the edits are independent and cannot collide.

#### Preparation

3. **Study LinkWatcher capabilities**: Read the LinkWatcher Capabilities Reference (`<LinkWatcher install>/doc/user/handbooks/linkwatcher-capabilities-reference.md`, see Context Requirements) to understand what LinkWatcher updates automatically and what requires manual attention. Do not assume — the reference is authoritative. This knowledge is essential for accurate impact analysis (next step) and for distinguishing LinkWatcher-handled updates from manual work during execution.
4. **🚨 MANDATORY Impact Analysis**: Before creating the proposal, systematically assess the full scope of the change. This step prevents incremental scope discovery during execution.

   a. **Reference grep**: For each affected file, grep the entire project to find all files that reference it (markdown links, imports, script paths, string literals). Record the count and list.
   b. **Code audit (consumers and generators)**: Identify all code that interacts with the affected file(s). Two passes — both required:
      - **Consumers** (read or write the literal path): Check `process-framework/scripts/` and the broader codebase for scripts/code that target the path. Largely covered by the reference grep (sub-step a).
      - **Generators** (recreate the file from templates, f-strings, here-strings): Reference grep often **misses** these because the path is constructed at runtime (e.g., `f"{base}/{filename}"`). For each affected file, search for: `write_text`, `Set-Content`, `Out-File`, here-strings (`@"..."@`, `@'...'@`), Python f-strings producing the file's content, and template-substitution patterns. **Why**: SC-029 missed `install_global.py::update_startup_scripts()` (regenerates `start_linkwatcher_background.ps1` from an f-string template) until execution.
   c. **Task definition audit**: Search task definitions (`process-framework/tasks/`) for manual update instructions referencing the affected file(s) (e.g., "update documentation-map.md").
   d. **Infrastructure doc consultation**: Read [Process Framework Task Registry](../../infrastructure/process-framework-task-registry.md) (catalogs what each task creates/updates) and [Task Transition Registry](../../infrastructure/task-transition-registry.md) (documents handover interfaces between tasks) to identify additional downstream impacts.
   e. **Present impact matrix**: Compile findings into a matrix (affected files × change type: link update, content update, script change, task definition change) and present at the checkpoint below.
   f. **Plan completeness checks** — for specific change shapes, additional verification before the matrix is final:
      - *Directory moves*: grep `*.ps1`/`*.psm1` for hardcoded references to the moving path prefix; the plan must enumerate every affected script upfront, since sub-step (a)'s generic grep can miss in-script path construction *(PF-IMP-813)*.
      - *Project-local state moves*: framework-management content (`temp-framework-extension-*`, `temp-task-creation-*`, PF-TSK-001/026 sessions, IMP triage outputs) routes to `appdev/process-framework-central/`, **not** any project's `doc/state-tracking/` *(PF-IMP-816)*.
      - *Files separated from blueprint*: the plan must explicitly answer "what does a new project see in its place?" (filename, content, generator) — no TBDs *(PF-IMP-824)*.
      - *Artifact-class removal, or any file merge/move/delete — hidden-dependency audit*: two dependency kinds escape the content grep in sub-steps (a)–(b). **(i) Type-registration systems** (when the change removes an entire artifact class): audit the [`PF-id-registry.json`](../../PF-id-registry.json) prefix entry + its `directories` map, [`domain-config.json`](../../domain-config.json) `artifact_metadata_schemas` + category enums, and any dedicated `Validate-StateTracking.ps1` surface — none is reachable by grepping the artifact's path. **(ii) Existence markers**: grep `*.ps1`/`*.psm1` for `Test-Path`/sentinel checks on the affected path — a file used only as a root marker (e.g. `Core.psm1`'s `Get-ProjectRoot` keys on `process-framework/.ai-entry-point.md`) is read by no content grep yet must survive (often as a pointer stub) or the dependent script breaks *(PF-IMP-1198/1199)*.

   > **Why this step exists**: SC-009 demonstrated that without structured impact analysis, scope gaps are caught incrementally by the human partner across multiple checkpoints — wasting review cycles and risking missed items.

5. **Create Structure Change Proposal**: Use the [New-StructureChangeProposal.ps1](../../scripts/file-creation/support/New-StructureChangeProposal.ps1) script. Incorporate the impact matrix from Step 4 into the proposal:
   ```powershell
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/support/New-StructureChangeProposal.ps1 -ChangeName "Change Name" -Description "Brief description"
   ```
   > **Skip if [Lean-Full Variant](#lean-full-variant) applies.**
   > **Proposal-equivalent**: An existing **owner-approved analysis** — a [Framework Evaluation](framework-evaluation.md) finding, or an approved IMP's analysis already captured in a state/eval file — may serve as the proposal-of-record in place of a fresh `New-StructureChangeProposal` doc. Reference it from the state file's *Proposal Document* field (it need not be a standalone proposal file) and fold the Step 4 impact matrix into the structure change state file.
6. **Create Structure Change State Tracking File**: Use the [New-StructureChangeState.ps1](../../scripts/file-creation/support/New-StructureChangeState.ps1) script to create tracking file with implementation roadmap
   ```powershell
   # Create the structure change state tracking file. Phase 5/7 (post-2026-05-11): the script routes its
   # output itself via Get-StateTrackingContext — process-framework-central/state-tracking/ (appdev) or
   # doc/state-tracking/ (projects) — so no navigation is needed.
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/support/New-StructureChangeState.ps1 -ChangeName "Change Name" -ChangeType "Template Update|Directory Reorganization|Metadata Structure|Documentation Architecture|Rename|Content Update|Framework Extension" -Description "Brief description"
   # Use -ChangeType "Rename" for lightweight rename/move operations (simplified template without pilot/rollback/metrics sections)
   # Use -ChangeType "Content Update" for content-only changes across files (simplified template without pilot/rollback/metrics sections)
   # Use -ChangeType "Framework Extension" for adding/modifying framework docs (artifact tracking, no pilot/rollback/metrics)
   # Use -FromProposal when a detailed proposal already exists — generates a lightweight state file (phase checklist + session log only, no redundant sections)
   ```
7. Use the existing temporary state-tracking directory for transition files. Phase 5/7: resolved via `Get-StateTrackingContext` — appdev → `process-framework-central/state-tracking/temporary/`; projects → `doc/state-tracking/temporary/`.
8. Create mapping documents and migration checklists in the temporary directory
9. Establish clear metrics for measuring the success of the structure change
10. **🚨 CHECKPOINT**: Present structure change proposal (including impact matrix from Step 4), migration plan, and impact analysis to human partner for approval

#### Execution

> **🚨 ORCHESTRATOR PRINCIPLE**: PF-TSK-014 plans, tracks, and coordinates structure changes. It does NOT perform specialized work inline. When a deliverable requires template creation, guide creation, script creation, or task creation, **delegate to the appropriate specialized task or process** and track completion.

11. **Delegation Planning**: Review the deliverables identified in the proposal and classify each one:

   | Deliverable Type | Delegate To | Process |
   |---|---|---|
   | New task definition | [New Task Creation Process (PF-TSK-001)](new-task-creation-process.md) | Full task creation workflow with quality gates |
   | New/updated template | [`template-development` craft skill](../../../.claude/skills/template-development/SKILL.md) + [New-Template.ps1](../../scripts/file-creation/support/New-Template.ps1) | Template development process |
   | New/updated guide | [New-Guide.ps1](../../scripts/file-creation/support/New-Guide.ps1) | Guide creation process |
   | New automation script | [`creation-script-development` craft skill](../../../.claude/skills/creation-script-development/SKILL.md) + [script template](../../templates/support/document-creation-script-template.ps1) | Script development process |
   | Content migration | PF-TSK-014 (this task) | Direct execution — see step 14 |
   | Cross-reference updates | PF-TSK-014 (this task) | Direct execution — LinkWatcher handles most |

   Record the delegation plan in the structure change state tracking file.

   > **Content edits to *existing* tasks, templates, or guides are inline Direct Execution (Step 14), not delegation.** The rows above are for *creating* a new artifact (or a rewrite substantial enough to warrant the specialized task's quality gates). A wording, section, or reference edit to an existing file is done directly — it does not route through an external process.

12. **🚨 CHECKPOINT** *(skip if nothing is delegated)*: Present the delegation plan to the human partner — which deliverables are delegated, which are handled directly, and the execution order. **Skip this checkpoint when Step 11 classified every deliverable as Direct Execution** (zero delegated) — there is no delegation plan to approve, and the Step 10 proposal approval already covered the direct work. Proceed to Step 13.

13. **Execute Delegated Work**: For each delegated deliverable:
    a. Start the delegated task/process (may be a separate session if context-heavy)
    b. Track completion status in the structure change state tracking file
    c. **🚨 CHECKPOINT**: Confirm each delegated deliverable meets expectations before proceeding to the next

14. **Direct Execution — Migration and Updates**: Handle work that belongs to PF-TSK-014 directly:
    - **Pre-execution sanity check**: Before applying changes, grep/inspect each file named in the plan to confirm its current state matches the plan's assumption — plans authored across sessions can stale *(PF-IMP-815)*.
    - **Shared-file concurrency**: when the change edits files other sessions also touch (ai-tasks.md, registries, generators), apply the [parallel-session safety principle](../../guides/framework/task-execution-protocol-guide.md#operating-principles-apply-throughout) — read-before-write, and treat a `-Check` failure tracing to a concurrent generator edit as non-blocking *(PF-IMP-1191)*.
    - Create migration plan for updating files affected by structure changes
    - Pilot changes on a small subset of files to validate the approach
    - **🚨 CHECKPOINT**: Present pilot results to human partner for approval before full rollout
    - Implement changes across remaining files
    - For markdown table changes, consider [Add-MarkdownTableColumn.ps1](../../scripts/Add-MarkdownTableColumn.ps1)
    - **For file/directory moves**: Follow the [File and Directory Move Procedure](#file-and-directory-move-procedure)
    - **For file splits** (one file into two): Follow the [File Split Procedure](#file-split-procedure)
    - **For framework-script edits** (`.ps1` / `.psm1`): follow [Framework-Script Edit Verification](#framework-script-edit-verification).

14.5. **Per-project working-doc migrations** (Phase 7 capability, 2026-05-11) — when the structure change affects project working docs (anything inside `<project>/doc/`, `<project>/test/`, or `<project>/src/` that gets reorganized as part of the structure change), the change cannot be applied unilaterally from appdev; it must be deployed to each registered project's working tree by a subsequent Framework Rollout Mode C (PF-TSK-088) session.

    Write one Pending Migration Entry per affected registered project to `appdev/process-framework-central/per-project-migrations/<PROJECT-ID>/pending-migrations.md`.

    **Scaffold via [New-PendingMigration.ps1](../../scripts/file-creation/support/New-PendingMigration.ps1)** (PF-IMP-931) — it allocates the next per-project `MIG-NNN` (highest in that ledger + 1), inserts the Summary-table row + entry skeleton, and fans the same entry across projects in one call:

    ```bash
    pwsh.exe -ExecutionPolicy Bypass -File blueprint/process-framework/scripts/file-creation/support/New-PendingMigration.ps1 \
      -AllProjects -Title "Add 'priority' column to feature-tracking.md" -Source "PF-IMP-NNN" \
      -TargetFiles "doc/state-tracking/permanent/feature-tracking.md — add 'priority' column" \
      -BackwardCompatible yes -Confirm:\$false
    ```

    Target selection: `-Project APP-NNN[,APP-MMM]` for specific projects, `-AllProjects` for every eligible project (appdev / sandboxes / version-frozen are excluded and the skipped set is logged), or `-BatchFile <json>` for several distinct migrations at once. Use `-Variant Cleanup` ([PF-TEM-080](../../templates/support/pending-migration-entry-cleanup-template.md)) for no-data-motion migrations (empty-dir removal, placeholder relocation, single config/registry-key cleanup, in-place text substitution, additive section append); the default is the full form ([PF-TEM-079](../../templates/support/pending-migration-entry-template.md)).

    Each entry needs this prose: **Description** (what changes and why), **Migration Steps** (ordered procedure Mode C executes), **Expected Outcome** (post-migration state), **Rollback Implications** (the load-bearing `yes`/`no` flag — when `no`, document the manual reversal steps; Mode D pre-flight scans `no` entries and surfaces them as operator-action-required), and **Validation** (how Mode C confirms success). Supply it **up-front in `-BatchFile`** (`Description`, `MigrationSteps`, `ExpectedOutcome`, `RollbackImplications`, `ReversalSteps`, `Validation` — PF-IMP-1417) so a fan-out across projects files complete in one shot; in Direct mode the script scaffolds structure only and you fill the `<!-- TODO -->` placeholders in every generated entry afterwards. Phrase preconditions and no-op conditions as apply-time checks the Mode C operator runs against the live tree (not predictions about the project's current state), and treat concrete specifics (line numbers, file lists) as illustrative — the operator re-derives them at apply time. Then commit the ledger updates with the structure change.

    The Mode C session (PF-TSK-088) is run from inside each project's working tree and applies any unapplied entries from the project's ledger. PF-TSK-014 is responsible for *authoring* the entries; Mode C is responsible for *applying* them.

    > **🚨 Scope boundary — when migration entries are NOT needed**: Pending migration entries cover **only** changes to project files **outside** the rolled-out subtree (`<project>/doc/`, `<project>/test/`, `<project>/src/`, `<project>/CLAUDE.md`, project-config.json schema bumps, etc.). They do **NOT** cover changes inside `blueprint/process-framework` itself — those propagate automatically via Mode B Push (`Push-FrameworkUpdate.ps1`'s `robocopy /MIR` orphan-removal mirror). For the canonical change-shape decision table (intra-blueprint vs. project-working-tree, with worked examples), see the [Framework Rollout Usage Guide — When you do NOT need a migration entry](../../guides/support/framework-rollout-usage-guide.md#when-you-do-not-need-a-migration-entry).
    >
    > If the change is purely intra-blueprint, skip step 14.5 entirely — no ledger writes, no Mode C session.

14.7. **Smoke-test affected scripts** (when scope >5 scripts per Step 4f): exercise each once with safe params or `-WhatIf` to catch silent breakage (projectRoot computation, template matching, path-prefix construction) before further work layers on top *(PF-IMP-814)*.

#### If Rejected or Abandoned at a Checkpoint

If the change is rejected at the Step 10 proposal gate, invalidated by the Step 14 pilot, or abandoned at any other checkpoint, tear down cleanly instead of leaving orphans:

a. **Delete the orphaned artifacts** created for this change — the proposal and the execution-tracking state file. Their consumed IDs stay consumed (registry gaps are expected and never backfilled).
b. **Move the source IMP to Rejected**: `Update-ProcessImprovement.ps1 -ImprovementId "IMP-XXX" -NewStatus "Rejected" -ValidationNotes "<why the change was abandoned>"` — the notes become the Rejection Reason.
c. **A per-session feedback form is still required.** Non-completion is not an exemption — the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md) feedback step applies to every session, including an aborted one. The completion checklists below read as completion-only; that does not make the form skippable on abort.

#### Finalization

15. Verify all files have been updated correctly
16. Document any issues encountered and their resolutions
17. **Regenerate the affected documentation maps and verify**:
    - All three maps (PF / PD / TE) are generated, DO-NOT-EDIT projections (PF-PRO-037 / PF-PRO-050) — **never hand-edited**. Regenerate each tree the change touched, then drift-check it: `Build-DocumentationMap.ps1` (PF) / `… -Tree PD` / `… -Tree TE`, each followed by the same invocation with `-Check` appended — every regenerated tree must exit 0. Rerun that tree's generator on any non-zero `-Check`.
    - **If a task was added, retired, or renamed**, also regenerate the task-metadata projections (ai-tasks.md tables, both registries, tasks/README): [`Build-TaskMetadata.ps1`](../../scripts/validation/Build-TaskMetadata.ps1), then `Build-TaskMetadata.ps1 -Check` — must exit 0.

#### 🚨 MANDATORY Cleanup Phase

18. **🚨 CRITICAL CLEANUP STEP**: Archive completed temporary state tracking files to the resolved `state-tracking/temporary/old/` directory (via `Get-StateTrackingContext`)
19. **Archive completed proposal**: Move the structure change proposal to its `old/` subdirectory (e.g., `proposals/old`) — the proposal has served its purpose and should not remain alongside active proposals
20. Remove excessive migration mapping documents if they don't provide ongoing value
21. Clean up any redundant documentation created during the process
22. Update the Process Improvement Tracking file with cleanup completion

#### Final Completion

23. **🚨 MANDATORY FINAL STEP**: Complete the [Full Completion Checklist](#full-completion-checklist) below

## Outputs

- **Updated Structure Files** - Templates and guides with new structure
- **Migrated Content Files** - All content files updated to the new structure
- **Structure Change Tracking** - State tracking file documenting the structure change
- **Migration Artifacts** - Temporary files used during migration (to be archived or deleted)

## State Tracking

The following state files must be updated as part of this task:

- **Structure Change State File** - Create using New-StructureChangeState.ps1 to track multi-session implementation progress
- [Process Improvement Tracking](../../../process-framework-central/state-tracking/permanent/process-improvement-tracking.md) - Update to reflect the process improvement
- [PF Documentation Map](../../PF-documentation-map.md) - Regenerate (`Build-DocumentationMap.ps1`) if process-framework document organization changes
- [PD Documentation Map](../../../doc/PD-documentation-map.md) - Regenerate (`Build-DocumentationMap.ps1 -Tree PD`) if product document organization changes
- [TE Documentation Map](../../../test/TE-documentation-map.md) - Regenerate (`Build-DocumentationMap.ps1 -Tree TE`) if test artifact organization changes

<!-- Note to task creator: Replace placeholders with actual linked state files (e.g., [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md)) -->

## ⚠️ Task Completion Checklists (Structure-Change–specific)

> Completion discipline, output verification, and the feedback form are governed by the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md) (Phase C). The items below are the **Structure-Change–specific** verifications that plug into it.

### Lightweight Completion Checklist

- [ ] **Scope Assessment**: Human partner confirmed Lightweight mode
- [ ] **Verify Changes**: All affected files updated correctly
  - [ ] New documents created using established scripts (if applicable)
  - [ ] Cross-references valid — run [`run_linkwatcher_validate.ps1`](../../tools/linkWatcher/run_linkwatcher_validate.ps1) (LinkWatcher broken-link scan, exit 1 on any broken link); confirm no NEW broken links in the printed report (no baseline mode — judge pre-existing link debt from the report)
  - [ ] Run [`Validate-StateTracking.ps1`](../../scripts/validation/Validate-StateTracking.ps1) — no NEW errors vs the pre-change baseline (`-SaveBaseline` before the first change → compare with `-Baseline <printed path>` here; equals 0 errors on a project without pre-existing validation debt)
  - [ ] Regenerate the PF map via [`Build-DocumentationMap.ps1`](../../scripts/validation/Build-DocumentationMap.ps1), then run [`Build-DocumentationMap.ps1 -Check`](../../scripts/validation/Build-DocumentationMap.ps1) — exit 0 (map in sync)
  - [ ] **If a task was added, retired, or renamed**: regenerate the task-metadata projections via [`Build-TaskMetadata.ps1`](../../scripts/validation/Build-TaskMetadata.ps1), then `Build-TaskMetadata.ps1 -Check` — exit 0. N/A otherwise.
  - [ ] **Framework script verification**: for each `.ps1`/`.psm1` whose *behavior* changed this session, the corresponding Pester unit test (`<ScriptName>.Tests.ps1`, fixture modeled on a real project's row format) exists, was added/updated alongside the edit, and runs green; a touched Python script with no Pester harness was verified by a recorded before/after contrast run instead. N/A if the change touched no scripts, or only comments/docstrings (no behavior change).
- [ ] **Update State Files**:
  - [ ] [Process Improvement Tracking](../../../process-framework-central/state-tracking/permanent/process-improvement-tracking.md) updated (if this change addresses an IMP item)
  - [ ] Each affected map regenerated and `-Check`-clean: PF via [`Build-DocumentationMap.ps1`](../../scripts/validation/Build-DocumentationMap.ps1), [PD](../../../doc/PD-documentation-map.md) via `-Tree PD`, [TE](../../../test/TE-documentation-map.md) via `-Tree TE` — only for trees whose organization changed (all three are generated DO-NOT-EDIT projections)
  - [ ] **Pending-migration entries filed (cwd=appdev only)**: If this change touched a `blueprint/` file outside `blueprint/process-framework/` (e.g. `blueprint/CLAUDE.md`, `blueprint/doc/`, `blueprint/test/`), a pending-migration entry has been filed under `process-framework-central/per-project-migrations/<PROJECT-ID>/pending-migrations.md` for every registered product project, using the [Pending Migration Entry Template](../../templates/support/pending-migration-entry-template.md). `Push-FrameworkUpdate.ps1` mirrors only `blueprint/process-framework/` (plus per-skill `.claude/skills/`); everything else in `blueprint/` reaches existing projects only via a migration entry. N/A if the change touched only `blueprint/process-framework/` (which Push mirrors automatically).
- [ ] **Feedback form** completed per the [Task Execution Protocol → Feedback step](../../guides/framework/task-execution-protocol-guide.md#feedback-step) — task ID `PF-TSK-014`, context "Structure Change (Lightweight)".

---

### Full Completion Checklist

- [ ] **Scope Assessment**: Human partner confirmed Full mode
- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] **Delegation completed**: All delegated deliverables completed through their specialized tasks/processes
  - [ ] **No specialized work done inline**: Task creation used PF-TSK-001, templates used Template Dev Guide, scripts used Script Dev Guide
  - [ ] All affected content files migrated to new structure
  - [ ] Structure change tracking file properly maintained (delegation status recorded)
  - [ ] Run `Validate-StateTracking.ps1` — no NEW errors vs the pre-change baseline (`-SaveBaseline` before the first change → compare with `-Baseline <printed path>` here; equals 0 errors on a project without pre-existing validation debt)
  - [ ] Run [`run_linkwatcher_validate.ps1`](../../tools/linkWatcher/run_linkwatcher_validate.ps1) — LinkWatcher broken-link scan (exit 1 on any broken link); confirm no NEW broken links in the printed report (no baseline mode — judge pre-existing link debt from the report)
  - [ ] Regenerate the PF map via [`Build-DocumentationMap.ps1`](../../scripts/validation/Build-DocumentationMap.ps1), then run [`Build-DocumentationMap.ps1 -Check`](../../scripts/validation/Build-DocumentationMap.ps1) — exit 0 (map in sync)
  - [ ] **If a task was added, retired, or renamed**: regenerate the task-metadata projections via [`Build-TaskMetadata.ps1`](../../scripts/validation/Build-TaskMetadata.ps1), then `Build-TaskMetadata.ps1 -Check` — exit 0. N/A otherwise.
  - [ ] **Framework script verification**: for each `.ps1`/`.psm1` whose *behavior* changed this session, the corresponding Pester unit test (`<ScriptName>.Tests.ps1`, fixture modeled on a real project's row format) exists, was added/updated alongside the edit, and runs green; a touched Python script with no Pester harness was verified by a recorded before/after contrast run instead. N/A if the change touched no scripts, or only comments/docstrings (no behavior change).
- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] Structure change state tracking file completed and properly maintained
  - [ ] [Process Improvement Tracking](../../../process-framework-central/state-tracking/permanent/process-improvement-tracking.md) updated with structure change completion
  - [ ] Each affected map regenerated and `-Check`-clean: PF via [`Build-DocumentationMap.ps1`](../../scripts/validation/Build-DocumentationMap.ps1), [PD](../../../doc/PD-documentation-map.md) via `-Tree PD`, [TE](../../../test/TE-documentation-map.md) via `-Tree TE` — only for trees whose organization changed (all three are generated DO-NOT-EDIT projections)
  - [ ] **Pending-migration entries filed (cwd=appdev only)**: If this change touched a `blueprint/` file outside `blueprint/process-framework/` (e.g. `blueprint/CLAUDE.md`, `blueprint/doc/`, `blueprint/test/`), a pending-migration entry has been filed under `process-framework-central/per-project-migrations/<PROJECT-ID>/pending-migrations.md` for every registered product project, using the [Pending Migration Entry Template](../../templates/support/pending-migration-entry-template.md). `Push-FrameworkUpdate.ps1` mirrors only `blueprint/process-framework/` (plus per-skill `.claude/skills/`); everything else in `blueprint/` reaches existing projects only via a migration entry. N/A if the change touched only `blueprint/process-framework/` (which Push mirrors automatically).
- [ ] **Feedback form** completed per the [Task Execution Protocol → Feedback step](../../guides/framework/task-execution-protocol-guide.md#feedback-step) — task ID `PF-TSK-014`, context "Structure Change (Full)".
- [ ] **🚨 MANDATORY Cleanup Phase**: Remove temporary documentation artifacts created during the structure change:
  - [ ] **🚨 CRITICAL**: Archive completed temporary state tracking files to the resolved `state-tracking/temporary/old/` directory (via `Get-StateTrackingContext`)
  - [ ] **🚨 CRITICAL**: Archive completed structure change proposal to its `old/` subdirectory
  - [ ] Remove excessive migration mapping documents if they don't provide ongoing value
  - [ ] Clean up any redundant documentation created during the process
  - [ ] Update the Process Improvement Tracking file with cleanup completion
        **Cleanup Criteria**:
  - Archive: Completed temporary state tracking files (move to old/ directory for historical reference)
  - Archive: Completed proposals (move to proposals/old/ directory — no longer active)
  - Keep: Files that provide ongoing reference value or audit trail
  - Remove: Redundant tracking files, excessive migration artifacts, temporary working documents

## File Operations

| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | Structure change state document | `New-StructureChangeState.ps1` | Tracks structural changes and their impact |
| **Creates** | Structure change proposal (optional) | `New-StructureChangeProposal.ps1` | Proposal document for review |
| **Updates** | `per-project-migrations/<PRJ>/pending-migrations.md` | `New-PendingMigration.ps1` (Step 14.5, conditional) | Scaffolds a Pending Migration Entry per affected project when the change touches project working docs |
| **Updates** | [`process-improvement-tracking.md`](../../../../process-framework-central/state-tracking/permanent/process-improvement-tracking.md) | Manual (conditional) | If addressing an IMP entry |
| **Updates** | [`PF-documentation-map.md`](../../PF-documentation-map.md) | Generated by [`Build-DocumentationMap.ps1`](../../scripts/validation/Build-DocumentationMap.ps1); `-Check` drift gate | Steps 8/17 regenerate then require `-Check` exit 0 — the map is a generated, DO-NOT-EDIT projection of each artifact's source description (PF-PRO-037, supersedes PF-IMP-836) |
| **Updates** | [`PD-documentation-map.md`](../../../doc/PD-documentation-map.md) | Generated by [`Build-DocumentationMap.ps1 -Tree PD`](../../scripts/validation/Build-DocumentationMap.ps1); `-Check` drift gate | If product doc organization changes — regenerate (DO-NOT-EDIT projection, PF-PRO-050) |
| **Updates** | [`TE-documentation-map.md`](../../../test/TE-documentation-map.md) | Generated by [`Build-DocumentationMap.ps1 -Tree TE`](../../scripts/validation/Build-DocumentationMap.ps1); `-Check` drift gate | If test artifact organization changes — regenerate (DO-NOT-EDIT projection, PF-PRO-050) |

## Next Tasks

- [**Process Improvement**](process-improvement-task.md) - If further process refinements are needed
- [**Tools Review**](tools-review-task.md) - Review any tools affected by structure changes

<!-- merged from transition-registry entry: Structure Change -->
### Prerequisites for Transition

- [ ] Structure change plan executed
- [ ] Files moved/reorganized as planned
- [ ] All links and references updated
- [ ] Structure change documented
- [ ] **Framework script verification done**: if the structure change touched any `.ps1`/`.psm1` files (path-prefix changes, helper-module signature changes, script renames), their Pester unit tests (fixtures modeled on a real project's row format) were added/updated alongside the edit and the targeted Pester run is green; a touched Python script with no Pester harness was verified by a recorded before/after contrast run instead. The test suite is the cheapest catch for silent breakage in mass renames / column moves / path-prefix changes. N/A if no scripts were touched. Introduced by the Framework Self-Testing extension (PF-PRO-035).

### Next Task Selection

- **Always**: → Return to interrupted development work or continue with planned tasks

## Related Resources

### Delegation Targets (for Full Process)

- [New Task Creation Process (PF-TSK-001)](new-task-creation-process.md) - **DELEGATE** task definition creation here
- [`template-development` craft skill](../../../.claude/skills/template-development/SKILL.md) - **DELEGATE** template creation/updates here
- [New-Template.ps1](../../scripts/file-creation/support/New-Template.ps1) - Script for creating new templates
- [New-Guide.ps1](../../scripts/file-creation/support/New-Guide.ps1) - Script for creating new guides
- [Document Creation Script Template](../../templates/support/document-creation-script-template.ps1) - Template for creating automation scripts
- [`creation-script-development` craft skill](../../../.claude/skills/creation-script-development/SKILL.md) - **DELEGATE** script creation here

### Additional Resources

- [Documentation Structure Guide](../../guides/framework/documentation-structure-guide.md) - Principles for documentation structure
- [Migration Best Practices](../../guides/support/migration-best-practices.md) - Guidance for content migration

### Automation Scripts

- [Add-MarkdownTableColumn.ps1](../../scripts/Add-MarkdownTableColumn.ps1) - Utility script for adding columns to markdown tables with intelligent table detection and positioning
