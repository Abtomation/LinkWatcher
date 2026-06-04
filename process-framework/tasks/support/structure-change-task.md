---
id: PF-TSK-014
type: Process Framework
category: Task Definition
domain: agnostic
version: 2.5
created: 2025-06-07
updated: 2026-05-16
description: "Manage structural changes to documentation"
---

# Structure Change Task

## Purpose & Context

This task **orchestrates** systematic changes to documentation structures, templates, or frameworks across multiple files. It plans the overall change, delegates specialized work to appropriate tasks/processes (e.g., task creation to PF-TSK-001, template work to the Template Development Guide), tracks progress, and coordinates handover — ensuring consistent, well-tested structural evolution with clear migration paths and rollback options.

> **Key principle**: PF-TSK-014 is a **coordinator**, not an executor of specialized work. It should never bypass the quality gates of specialized tasks by doing their work inline.

## AI Agent Role

**Role**: Project Coordinator / Change Manager
**Mindset**: Delegation-focused, impact-aware, change-management oriented
**Focus Areas**: Change impact analysis, delegation planning, progress tracking, handover coordination
**Communication Style**: Analyze dependencies and change ripple effects, identify which specialized tasks/processes to delegate to, ask about migration preferences and rollback requirements

## Context Requirements

[View Context Map for this task](../../visualization/context-maps/support/structure-change-map.md)

- **Critical (Must Read):**

  - [Structure Change Proposal](../../templates/support/structure-change-proposal-template.md) - Detailed description of proposed changes
  - [Documentation Map](../../PF-documentation-map.md) - Map of all documentation
  - [Visual Notation Guide](../../guides/support/visual-notation-guide.md) - For interpreting context map diagrams

- **Important (Load If Space):**
  - [LinkWatcher Capabilities Reference](../../../doc/user/handbooks/linkwatcher-capabilities-reference.md) - What LinkWatcher updates automatically vs. what needs manual attention during moves (see [LinkWatcher and Structure Changes](#linkwatcher-and-structure-changes) below)
  - [Script Development Quick Reference](../../guides/support/script-development-quick-reference.md) - PowerShell execution patterns and parameter checking (**always check script parameters with `-?` before running**)
  - [Template Development Guide](../../guides/support/template-development-guide.md) - **REQUIRED** for creating or updating templates
  - [Document Creation Script Development Guide](../../guides/support/document-creation-script-development-guide.md) - **REQUIRED** for creating automation scripts
  - [Process Framework Documentation](../../README.md) - Current documentation structure
  - [Feedback Forms](../../feedback/feedback-forms) - Feedback related to current structure

- **Reference Only (Access When Needed):**
  - [Process Framework Task Registry — Trigger & Output fields](../../infrastructure/process-framework-task-registry.md) - Consult trigger/output blocks and State File Trigger Index when changes affect task trigger conditions or state file interactions

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished!**
>
> **⚠️ MANDATORY: Create backup copies of all files before making changes.**
>
> **📋 IMPORTANT: Use established document creation processes for all new templates, guides, and scripts. Do NOT create these manually - use the provided scripts and follow the development guides.**
>
> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

### Scope Assessment

1. **Identify Scope**: Review the structure change requirements and identify all files affected. Classify the change:

   | Criteria | Lightweight | Full |
   |---|---|---|
   | **Files affected** | ≤ 5 files | > 5 files |
   | **Change type** | Single-type (rename, move, update references, add column) | Multi-type (template + guide + script + content) |
   | **Breaking changes** | No (backward-compatible or self-contained) | Yes (changes that affect other tasks/workflows) |
   | **Cross-references** | Handled by LinkWatcher or minimal manual updates | Extensive manual cross-reference updates needed |
   | **Incoming references** | ≤ 20 files reference the affected file(s) | > 20 files reference the affected file(s) (grep to verify) |

   > A change qualifies as **Lightweight** if it meets ALL lightweight criteria. If ANY criterion falls into Full, use the Full process.

2. **🚨 HUMAN APPROVAL REQUIRED**: Present the scope assessment to the human partner with a recommendation (Lightweight or Full) and the reasoning. **Do not proceed until the human confirms the mode.**

   > If Lightweight → continue to [Lightweight Process](#lightweight-process)
   > If Full → continue to [Full Process](#full-process)
   >
   > **Mechanical Variant**: If the change exits Lightweight on file count alone but is *pure text substitution* (status-label rename, terminology update, deprecation propagation) with no new templates/scripts/tasks/guides and no breaking changes — use the Full path with the [Mechanical Rename Variant](#mechanical-rename-variant) shortcut. Proposal not required.

---

### Lightweight Process

> For small, contained structure changes (≤ 5 files, single-type, no breaking changes).

3. **Study LinkWatcher capabilities**: Read the [LinkWatcher Capabilities Reference](../../../doc/user/handbooks/linkwatcher-capabilities-reference.md) to understand what LinkWatcher updates automatically and what requires manual attention. Do not assume — the reference is authoritative.
4. **Make Changes**: Implement the structure change directly:
   - Use established scripts when creating new documents ([New-Template.ps1](../../scripts/file-creation/support/New-Template.ps1), [New-Guide.ps1](../../scripts/file-creation/support/New-Guide.ps1), etc.)
   - For markdown table changes, consider [Add-MarkdownTableColumn.ps1](../../scripts/Add-MarkdownTableColumn.ps1)
   - **For file/directory moves**: Follow the [File and Directory Move Procedure](#file-and-directory-move-procedure) below
   - **For file splits** (one file into two): Follow the [File Split Procedure](#file-split-procedure) below
   - **For framework-script edits** (`.ps1` / `.psm1`): add or update the script's Pester unit test (`<ScriptName>.Tests.ps1` under `appdev/test/automated/unit/framework/<area>/`) inline with the edit. Run `pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/test/Run-Tests.ps1 -Category <area>` (or `-Quick`) — the test pass is the validation evidence. If the change affects a tracked user workflow ([user-workflow-tracking.md](../../../doc/state-tracking/permanent/user-workflow-tracking.md)) or a measured performance surface, route follow-up to [E2E Acceptance Test Case Creation (PF-TSK-069)](../03-testing/e2e-acceptance-test-case-creation-task.md) or [Performance Test Creation (PF-TSK-084)](../03-testing/performance-test-creation-task.md) respectively.

5. **Grep sweep for replaced patterns**: Before the checkpoint, grep the entire project for old values/patterns being replaced (status labels, terminology, naming conventions). LinkWatcher updates path references automatically, but does **not** update text patterns — status labels in particular are typically scattered across task definitions, guides, scripts, context maps, and test specs. Update any active references found and bring sweep results to the checkpoint.

   > File/directory moves and file splits already include grep verification in their dedicated procedures — this step covers the broader case (non-path replacements).

6. **🚨 CHECKPOINT**: Present implemented changes and affected files to human partner for review
7. **Verify**: Confirm all changes are correct:
   - All affected files updated
   - Cross-references valid (check LinkWatcher log if relevant)
   - No broken links or orphaned references

8. **Update Documentation Maps and verify**:
   - Update the **hand-maintained** maps if document organization changed:
     - Product documents (FDDs, TDDs, ADRs, handbooks) → [PD Documentation Map](../../../doc/PD-documentation-map.md)
     - Test artifacts (test specs, audit reports) → [TE Documentation Map](../../../test/TE-documentation-map.md)
   - **Regenerate the PF map** (process-framework artifacts): `pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/validation/Build-DocumentationMap.ps1` — the PF map is a generated, DO-NOT-EDIT projection (PF-PRO-037); moves/adds/removes are picked up automatically from each artifact's source description (`.SYNOPSIS` / `description:` frontmatter / `metadata.description`).
   - **Run drift check** (process-framework only): `pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/validation/Build-DocumentationMap.ps1 -Check` — must exit 0 (in sync). On non-zero exit, the on-disk map differs from generator output; rerun the generator (preceding bullet) and re-check. `-ReportMissing` lists files still lacking a source description.

9. **🚨 MANDATORY FINAL STEP**: Complete the [Lightweight Completion Checklist](#lightweight-completion-checklist) below

---

### File and Directory Move Procedure

When moving or renaming files/directories as part of a structure change, follow this procedure for each move:

1. **Move one file or directory at a time** — do not batch multiple moves simultaneously
2. **Wait for LinkWatcher to finish processing** — check the active log file (`ls -lt logs/linkwatcher/LinkWatcherLog*.txt | head -1`) for completion of the update cycle. Phase 5 moved LinkWatcher's runtime artifacts from `process-framework-local/tools/linkWatcher/` to the project-root `logs/linkwatcher/` directory.
3. **Verify all references were updated** — grep for the old path across the project; if no hits remain, the move is complete
4. **If references were NOT updated**, diagnose the root cause before manual fixing:

   | Symptom | Likely Cause | Action |
   |---------|-------------|--------|
   | Path inside `[brackets]` not updated | Template placeholder (e.g., `[Feature Name]`) — not a real link | Manual update required — LinkWatcher correctly skips these |
   | Path inside fenced code block not updated | Illustrative example, not a navigable reference | Manual update required — LinkWatcher correctly skips these |
   | Path doesn't resolve to any file on disk | Hypothetical example or already-deleted target | Manual update or removal required |
   | Path exists but LinkWatcher missed it | Possible phantom link target (see PD-BUG-075) or unsupported pattern | Investigate root cause — check if the file type is monitored and the pattern is in the [Capabilities Reference](../../../doc/user/handbooks/linkwatcher-capabilities-reference.md) |
   | External URL (`http://`, `https://`) | LinkWatcher does not update external URLs | Manual update required if URL changed |

> **Key rule**: Always identify the root cause before manually fixing. If LinkWatcher should have updated a reference but didn't, that's a bug to investigate — not something to silently work around.

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

### Full Process

> For large, multi-type, or breaking structure changes.

#### Mechanical Rename Variant

> **When to use**: If the only reason this change exited Lightweight is file count, and the change is *pure text substitution* (single-type, no breaking changes, no new templates/scripts/tasks/guides), the proposal is overkill. Run the Full path with these shortcuts:
> - **Skip Step 5** (no proposal). Skip to Step 6 directly.
> - In Step 6, use `-ChangeType "Content Update"` (or `"Rename"` for path moves).
> - **Skip Steps 11–13** (no delegation — nothing to delegate by definition).
> - Run the [Lightweight grep sweep](#lightweight-process) (its Step 5) before the execution checkpoint, then continue with Step 14 (Direct Execution).
> - In cleanup (Step 19), there is no proposal to archive — skip that bullet only.

#### Preparation

3. **Study LinkWatcher capabilities**: Read the [LinkWatcher Capabilities Reference](../../../doc/user/handbooks/linkwatcher-capabilities-reference.md) to understand what LinkWatcher updates automatically and what requires manual attention. Do not assume — the reference is authoritative. This knowledge is essential for accurate impact analysis (next step) and for distinguishing LinkWatcher-handled updates from manual work during execution.
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

   > **Why this step exists**: SC-009 demonstrated that without structured impact analysis, scope gaps are caught incrementally by the human partner across multiple checkpoints — wasting review cycles and risking missed items.

5. **Create Structure Change Proposal**: Use the [New-StructureChangeProposal.ps1](../../scripts/file-creation/support/New-StructureChangeProposal.ps1) script. Incorporate the impact matrix from Step 4 into the proposal:
   ```powershell
   cd process-framework/scripts/file-creation
   .\New-StructureChangeProposal.ps1 -ChangeName "Change Name" -Description "Brief description"
   ```
   > **Skip if [Mechanical Rename Variant](#mechanical-rename-variant) applies.**
6. **Create Structure Change State Tracking File**: Use the [New-StructureChangeState.ps1](../../scripts/file-creation/support/New-StructureChangeState.ps1) script to create tracking file with implementation roadmap
   ```powershell
   # Navigate to the state-tracking directory and create structure change state tracking file
   # Phase 5/7 (post-2026-05-11): state-tracking lives at process-framework-central/state-tracking/ (appdev)
   # or doc/state-tracking/ (projects) — resolved via Get-StateTrackingContext.
   cd $(Get-StateTrackingContext).StateTrackingRoot
   ./New-StructureChangeState.ps1 -ChangeName "Change Name" -ChangeType "Template Update|Directory Reorganization|Metadata Structure|Documentation Architecture|Rename|Content Update|Framework Extension" -Description "Brief description"
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
   | New/updated template | [Template Development Guide](../../guides/support/template-development-guide.md) + [New-Template.ps1](../../scripts/file-creation/support/New-Template.ps1) | Template development process |
   | New/updated guide | [New-Guide.ps1](../../scripts/file-creation/support/New-Guide.ps1) | Guide creation process |
   | New automation script | [Document Creation Script Development Guide](../../guides/support/document-creation-script-development-guide.md) + [script template](../../templates/support/document-creation-script-template.ps1) | Script development process |
   | Content migration | PF-TSK-014 (this task) | Direct execution — see step 14 |
   | Cross-reference updates | PF-TSK-014 (this task) | Direct execution — LinkWatcher handles most |

   Record the delegation plan in the structure change state tracking file.

12. **🚨 CHECKPOINT**: Present the delegation plan to the human partner — which deliverables are delegated, which are handled directly, and the execution order.

13. **Execute Delegated Work**: For each delegated deliverable:
    a. Start the delegated task/process (may be a separate session if context-heavy)
    b. Track completion status in the structure change state tracking file
    c. **🚨 CHECKPOINT**: Confirm each delegated deliverable meets expectations before proceeding to the next

14. **Direct Execution — Migration and Updates**: Handle work that belongs to PF-TSK-014 directly:
    - **Pre-execution sanity check**: Before applying changes, grep/inspect each file named in the plan to confirm its current state matches the plan's assumption — plans authored across sessions can stale *(PF-IMP-815)*.
    - Create migration plan for updating files affected by structure changes
    - Pilot changes on a small subset of files to validate the approach
    - **🚨 CHECKPOINT**: Present pilot results to human partner for approval before full rollout
    - Implement changes across remaining files
    - For markdown table changes, consider [Add-MarkdownTableColumn.ps1](../../scripts/Add-MarkdownTableColumn.ps1)
    - **For file/directory moves**: Follow the [File and Directory Move Procedure](#file-and-directory-move-procedure)
    - **For file splits** (one file into two): Follow the [File Split Procedure](#file-split-procedure)
    - **For framework-script edits** (`.ps1` / `.psm1`): add or update the script's Pester unit test (`<ScriptName>.Tests.ps1` under `appdev/test/automated/unit/framework/<area>/`) inline with the edit. The test pass via `Run-Tests.ps1 -Category <area>` (or `-Quick`) is the validation evidence. For mass renames / column moves / path-prefix changes touching many scripts, the test suite is the cheapest way to catch silent breakage; for workflow-affecting or perf-affecting changes, file a follow-up via [PF-TSK-069](../03-testing/e2e-acceptance-test-case-creation-task.md) / [PF-TSK-084](../03-testing/performance-test-creation-task.md).

14.5. **Per-project working-doc migrations** (Phase 7 capability, 2026-05-11) — when the structure change affects project working docs (anything inside `<project>/doc/`, `<project>/test/`, or `<project>/src/` that gets reorganized as part of the structure change), the change cannot be applied unilaterally from appdev; it must be deployed to each registered project's working tree by a subsequent Framework Rollout Mode C (PF-TSK-088) session.

    Write one Pending Migration Entry per affected registered project to `appdev/process-framework-central/per-project-migrations/<PRJ-ID>/pending-migrations.md`.

    **Scaffold via [New-PendingMigration.ps1](../../scripts/file-creation/support/New-PendingMigration.ps1)** (PF-IMP-931) — it allocates the next per-project `MIG-NNN` (highest in that ledger + 1), inserts the Summary-table row + entry skeleton, and fans the same entry across projects in one call:

    ```bash
    pwsh.exe -ExecutionPolicy Bypass -File blueprint/process-framework/scripts/file-creation/support/New-PendingMigration.ps1 \
      -AllProjects -Title "Add 'priority' column to feature-tracking.md" -Source "PF-IMP-NNN" \
      -TargetFiles "doc/state-tracking/permanent/feature-tracking.md — add 'priority' column" \
      -BackwardCompatible yes -Confirm:\$false
    ```

    Target selection: `-Project PRJ-NNN[,PRJ-MMM]` for specific projects, `-AllProjects` for every eligible project (appdev / sandboxes / version-frozen are excluded and the skipped set is logged), or `-BatchFile <json>` for several distinct migrations at once. Use `-Variant Cleanup` ([PF-TEM-080](../../templates/support/pending-migration-entry-cleanup-template.md)) for no-data-motion migrations (empty-dir removal, placeholder relocation, single config/registry-key cleanup); the default is the full form ([PF-TEM-079](../../templates/support/pending-migration-entry-template.md)).

    The script scaffolds **structure only** — after it runs, fill the `<!-- TODO -->` prose in each generated entry: **Description** (what changes and why), **Migration Steps** (ordered procedure Mode C executes), **Expected Outcome** (post-migration state), **Rollback Implications** (the load-bearing `yes`/`no` flag — when `no`, document the manual reversal steps; Mode D pre-flight scans `no` entries and surfaces them as operator-action-required), and **Validation** (how Mode C confirms success). Then commit the ledger updates with the structure change.

    The Mode C session (PF-TSK-088) is run from inside each project's working tree and applies any unapplied entries from the project's ledger. PF-TSK-014 is responsible for *authoring* the entries; Mode C is responsible for *applying* them.

    > **🚨 Scope boundary — when migration entries are NOT needed**: Pending migration entries cover **only** changes to project files **outside** the rolled-out subtree (`<project>/doc/`, `<project>/test/`, `<project>/src/`, `<project>/CLAUDE.md`, project-config.json schema bumps, etc.). They do **NOT** cover changes inside `blueprint/process-framework/` itself — those propagate automatically via Mode B Push (`Push-FrameworkUpdate.ps1`'s `robocopy /MIR` orphan-removal mirror). Concretely:
    >
    > | Change shape | Migration entry needed? | How it propagates |
    > |---|---|---|
    > | Move a file *within* `blueprint/process-framework/` (e.g. `state-tracking/X.md` → `state-tracking/Y.md`) | No | Mirror copies new path; deletes old |
    > | Add a new file inside `blueprint/process-framework/` | No | Mirror copies it to every project |
    > | Delete a file from `blueprint/process-framework/` | No | Mirror orphans it from every project |
    > | Move a file *out of* `blueprint/process-framework/` (e.g. into `process-framework-central/`) | No | Mirror deletes the blueprint-side copy; central-side is per-appdev only |
    > | Rename a column in `<project>/doc/state-tracking/permanent/feature-tracking.md` | **Yes** | Mode C session in each project edits the file |
    > | Add a section to project `CLAUDE.md` template | **Yes** (if it modifies existing projects' `CLAUDE.md`) | Mode C session in each project edits the file |
    >
    > If the change is purely intra-blueprint, skip step 14.5 entirely — no ledger writes, no Mode C session.

14.7. **Smoke-test affected scripts** (when scope >5 scripts per Step 4f): exercise each once with safe params or `-WhatIf` to catch silent breakage (projectRoot computation, template matching, path-prefix construction) before further work layers on top *(PF-IMP-814)*.

#### Finalization

15. Verify all files have been updated correctly
16. Document any issues encountered and their resolutions
17. **Update Documentation Maps and verify**:
    - Update the hand-maintained maps if document organization changed: [PD](../../../doc/PD-documentation-map.md) / [TE](../../../test/TE-documentation-map.md)
    - **Regenerate + drift-check the PF map** (process-framework artifacts): `Build-DocumentationMap.ps1`, then `Build-DocumentationMap.ps1 -Check` — must exit 0 (in sync). The PF map is a generated, DO-NOT-EDIT projection (PF-PRO-037); rerun the generator on any non-zero `-Check`.

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
- [PF Documentation Map](../../PF-documentation-map.md) - Update if process-framework document organization changes
- [PD Documentation Map](../../../doc/PD-documentation-map.md) - Update if product document organization changes
- [TE Documentation Map](../../../test/TE-documentation-map.md) - Update if test artifact organization changes

<!-- Note to task creator: Replace placeholders with actual linked state files (e.g., [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md)) -->

## ⚠️ MANDATORY Task Completion Checklists

### Lightweight Completion Checklist

**TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF**

- [ ] **Scope Assessment**: Human partner confirmed Lightweight mode
- [ ] **Verify Changes**: All affected files updated correctly
  - [ ] New documents created using established scripts (if applicable)
  - [ ] Cross-references valid (no broken links)
  - [ ] Run [`Validate-StateTracking.ps1`](../../scripts/validation/Validate-StateTracking.ps1) — 0 errors across all surfaces
  - [ ] Regenerate the PF map via [`Build-DocumentationMap.ps1`](../../scripts/validation/Build-DocumentationMap.ps1), then run [`Build-DocumentationMap.ps1 -Check`](../../scripts/validation/Build-DocumentationMap.ps1) — exit 0 (map in sync)
  - [ ] **Framework script tests**: for each `.ps1`/`.psm1` edited or created in this session, the corresponding Pester unit test (`<ScriptName>.Tests.ps1`) exists, was added/updated alongside the edit, and runs green. N/A if the change touched no PowerShell scripts.
- [ ] **Update State Files**:
  - [ ] [Process Improvement Tracking](../../../process-framework-central/state-tracking/permanent/process-improvement-tracking.md) updated (if this change addresses an IMP item)
  - [ ] PF map regenerated via [`Build-DocumentationMap.ps1`](../../scripts/validation/Build-DocumentationMap.ps1) if process-framework organization changed; hand-maintained [PD](../../../doc/PD-documentation-map.md) / [TE](../../../test/TE-documentation-map.md) maps updated if their organization changed
  - [ ] **Pending-migration entries filed (cwd=appdev only)**: If this change touched a `blueprint/` file outside `blueprint/process-framework/` (e.g. `blueprint/CLAUDE.md`, `blueprint/doc/`, `blueprint/test/`), a pending-migration entry has been filed under `process-framework-central/per-project-migrations/<PRJ-NNN>/pending-migrations.md` for every registered product project, using the [Pending Migration Entry Template](../../templates/support/pending-migration-entry-template.md). `Push-FrameworkUpdate.ps1` mirrors only `blueprint/process-framework/`; everything else in `blueprint/` reaches existing projects only via a migration entry. N/A if the change touched only `blueprint/process-framework/` (which Push mirrors automatically).
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Guide](../../guides/framework/feedback-form-guide.md) for each tool used, using task ID "PF-TSK-014" and context "Structure Change (Lightweight)"

---

### Full Completion Checklist

**TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF**

- [ ] **Scope Assessment**: Human partner confirmed Full mode
- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] **Delegation completed**: All delegated deliverables completed through their specialized tasks/processes
  - [ ] **No specialized work done inline**: Task creation used PF-TSK-001, templates used Template Dev Guide, scripts used Script Dev Guide
  - [ ] All affected content files migrated to new structure
  - [ ] Structure change tracking file properly maintained (delegation status recorded)
  - [ ] Run `Validate-StateTracking.ps1` — 0 errors across all surfaces
  - [ ] Regenerate the PF map via [`Build-DocumentationMap.ps1`](../../scripts/validation/Build-DocumentationMap.ps1), then run [`Build-DocumentationMap.ps1 -Check`](../../scripts/validation/Build-DocumentationMap.ps1) — exit 0 (map in sync)
  - [ ] **Framework script tests**: for each `.ps1`/`.psm1` edited or created in this session, the corresponding Pester unit test (`<ScriptName>.Tests.ps1`) exists, was added/updated alongside the edit, and runs green. N/A if the change touched no PowerShell scripts.
- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] Structure change state tracking file completed and properly maintained
  - [ ] [Process Improvement Tracking](../../../process-framework-central/state-tracking/permanent/process-improvement-tracking.md) updated with structure change completion
  - [ ] PF map regenerated via [`Build-DocumentationMap.ps1`](../../scripts/validation/Build-DocumentationMap.ps1) if process-framework organization changed; hand-maintained [PD](../../../doc/PD-documentation-map.md) / [TE](../../../test/TE-documentation-map.md) maps updated if their organization changed
  - [ ] **Pending-migration entries filed (cwd=appdev only)**: If this change touched a `blueprint/` file outside `blueprint/process-framework/` (e.g. `blueprint/CLAUDE.md`, `blueprint/doc/`, `blueprint/test/`), a pending-migration entry has been filed under `process-framework-central/per-project-migrations/<PRJ-NNN>/pending-migrations.md` for every registered product project, using the [Pending Migration Entry Template](../../templates/support/pending-migration-entry-template.md). `Push-FrameworkUpdate.ps1` mirrors only `blueprint/process-framework/`; everything else in `blueprint/` reaches existing projects only via a migration entry. N/A if the change touched only `blueprint/process-framework/` (which Push mirrors automatically).
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Guide](../../guides/framework/feedback-form-guide.md) for each tool used, using task ID "PF-TSK-014" and context "Structure Change (Full)"
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

## Next Tasks

- [**Process Improvement**](process-improvement-task.md) - If further process refinements are needed
- [**Tools Review**](tools-review-task.md) - Review any tools affected by structure changes

## Related Resources

### Delegation Targets (for Full Process)

- [New Task Creation Process (PF-TSK-001)](new-task-creation-process.md) - **DELEGATE** task definition creation here
- [Template Development Guide](../../guides/support/template-development-guide.md) - **DELEGATE** template creation/updates here
- [New-Template.ps1](../../scripts/file-creation/support/New-Template.ps1) - Script for creating new templates
- [New-Guide.ps1](../../scripts/file-creation/support/New-Guide.ps1) - Script for creating new guides
- [Document Creation Script Template](../../templates/support/document-creation-script-template.ps1) - Template for creating automation scripts
- [Document Creation Script Development Guide](../../guides/support/document-creation-script-development-guide.md) - **DELEGATE** script creation here

### Additional Resources

- [Documentation Structure Guide](../../guides/framework/documentation-structure-guide.md) - Principles for documentation structure
- [Migration Best Practices](../../guides/support/migration-best-practices.md) - Guidance for content migration
- [Task Creation and Improvement Guide](../../guides/support/task-creation-guide.md) - Guide for creating and improving tasks

### Automation Scripts

- [Add-MarkdownTableColumn.ps1](../../scripts/Add-MarkdownTableColumn.ps1) - Utility script for adding columns to markdown tables with intelligent table detection and positioning
