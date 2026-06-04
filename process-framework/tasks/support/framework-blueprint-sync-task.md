---
id: PF-TSK-087
type: Process Framework
category: Task Definition
version: 1.3
created: 2026-05-05
updated: 2026-05-05
---

# framework-blueprint-sync

## Purpose & Context

Propagate framework improvements made within real working projects back to the corresponding FrameworkBuilder blueprint, ensuring blueprints stay current with battle-tested evolutions.

**Operating model**: improvements are made at the project level (where they get exercised in real work), not directly in blueprints. This task is the deliberate pull-back step. Blueprints are intentionally one sync behind reality — that lag is the validation period.

**Scope**: covers all top-level framework directories of a chosen framework variant — `process-framework/`, `process-framework-local/`, `doc/`, `test/`, `src/` skeleton, root files (`CLAUDE.md`, etc.). Not limited to any one subdir.

**Direction**: project → blueprint only. This task does NOT push blueprint changes back into existing projects (no back-propagation).

## AI Agent Role

**Role**: Framework Curator
**Mindset**: Conservative — propagate only proven, framework-general evolutions; preserve project-specific content; treat the blueprint as a published interface that downstream projects will copy.
**Focus Areas**: Diff detection, classifying changes as framework-general vs project-specific, schema preservation in registries and doc-maps, blueprint internal consistency.
**Communication Style**: Surface every "is this project-specific or framework-general?" classification to the human partner. Default to asking when in doubt — wrong-direction syncs (project-specific content into blueprint) are harder to reverse than missed syncs.

## When to Use

**Triggers**:
- After a session in any project that introduced framework-level structural changes (new directories, registry prefixes, template fields, doc-map sections)
- After a Process Improvement (PF-TSK-009) or Tools Review (PF-TSK-010) that touched framework files
- Periodically (e.g., monthly) to catch accumulated drift the user hasn't explicitly flagged
- Before starting a new project from a blueprint, to verify the blueprint is current
- When the **sync backlog** for the target variant has accumulated enough items to warrant a session

**Prerequisites**:
- The framework variant being synced exists under `FrameworkBuilder/` and is identifiable by name (e.g., `appdev`) or path
- The source project has the framework files in a known location (typically project root subdirs)

## Key Concepts

### Sync Backlog (durable, per-variant)

Path: `FrameworkBuilder/{variant}/sync-backlog.md`

An evergreen working document listing all known drift items for the target blueprint that have not yet been synced. Accumulates across sessions so the task never starts from scratch:
- New drift items discovered in any session get appended (even if not synced that session)
- Synced items are removed (or marked resolved with date)
- The backlog is the canonical "what does this blueprint still owe?" list

### Sync Log (durable, per-variant)

Path: `FrameworkBuilder/{variant}/sync-log.md`

Append-only history of every sync session: when, from which project, what was synced, what was skipped, notable decisions.

### Session Temp State (per-session)

Created fresh each session via `New-TempTaskState.ps1`. Contains the subset of backlog items the user chose to tackle this session, with per-item classification and progress. Moved to `temporary/old/` at session end — the durable record lives in the backlog and log.

## Per-Directory Handling Rules

Different top-level framework directories have different sync semantics by design:

| Directory                    | Rule                              | Rationale |
|------------------------------|-----------------------------------|-----------|
| `process-framework/`         | **Wholesale replace** from project | By design, contains only framework artifacts (tasks, templates, guides, scripts, infrastructure docs). No project-specific content lives here. Project version is always canonical. Registry counters get reset on next project initialization, so overwriting them in the blueprint is fine. |
| `process-framework-local/`   | **Structure-only sync** | Skeleton (empty registry, empty state-tracking dirs, empty feedback dir). Sync only structural additions (new subdirs, new skeleton-file fields). Do NOT copy project content (feedback forms, populated registries, evaluation reports). |
| `doc/`                       | **Diff + classify + checkpoint** | Mix of framework docs (templates, doc-map structure) and project content (FDDs, TDDs, ADRs, validation reports). Per-item user decision. |
| `test/`                      | **Diff + classify + checkpoint** | Mix of framework structure (audit category dirs, registry prefixes, doc-map sections) and project content (test files, audit reports, populated trackers). Per-item user decision. |
| `src/` (skeleton)            | **Skip by default; user-confirmed structure-only sync if needed** | Project source code is project-specific. Blueprint typically has only minimal scaffolding (e.g., language-specific package markers). |
| Root files (`CLAUDE.md`, etc.) | **Diff + classify + checkpoint** | `CLAUDE.md` is mostly framework-general but commonly contains project-specific snippets. Per-item review. |

### Known Protected Artifacts (root files)

Intentional cross-project artifacts that live at blueprint root and **must never be deleted, modified, or treated as project-specific leakage** by sync sessions:

| Artifact | Purpose | Protection |
|----------|---------|-----------|
| `ratings.db` | SQLite feedback ratings database shared across all framework variants | Never delete or overwrite; sync inspects but does not modify |
| `ratings.db.bak-*` | Timestamped backups from feedback DB rotation | Never delete or modify; treat as protected siblings of `ratings.db` |

Add new entries when a new cross-project artifact is identified (i.e., one that legitimately spans multiple variants/projects). Any populated DB/binary file at blueprint root not on this list requires explicit user confirmation before any DELETE or overwrite — see Step 11 validation rule.

## Context Requirements

<!-- Context map to be created in a follow-up session -->

- **Critical (Must Read):**

  - [Framework Registry](../../../../FrameworkBuilder/Framework_Registry.json) - Lists registered framework variants; resolves variant name to path
  - User's specification of which framework variant + which directories are in scope
  - Sync backlog for the target variant (if exists): `FrameworkBuilder/{variant}/sync-backlog.md`

- **Important (Load If Space):**

  - Source project's framework files (the directories chosen for sync)
  - Target blueprint files (e.g., `FrameworkBuilder/appdev/{dir}/`)
  - Sync log for the target variant: `FrameworkBuilder/{variant}/sync-log.md`

- **Reference Only (Access When Needed):**
  - [Visual Notation Guide](/process-framework/guides/support/visual-notation-guide.md) - For interpreting context map diagrams
  - [Process Improvement Task](process-framework/tasks/support/process-improvement-task.md) - Often the upstream task that produced changes worth syncing
  - [Tools Review Task](process-framework/tasks/support/tools-review-task.md) - Same upstream relationship

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished!**

### Preparation

1. **Confirm target framework variant with user**. Ask which framework under `FrameworkBuilder/` is the sync target (e.g., `appdev`). Resolve via [Framework Registry](../../../../FrameworkBuilder/Framework_Registry.json) (or direct path if not registered). Verify path exists and is writable.

2. **Confirm source project**. Default: the current working directory if it has the framework files at expected locations. Otherwise ask.

3. **Locate or create the sync backlog** at `FrameworkBuilder/{variant}/sync-backlog.md`. If missing, create from a minimal template (just headers for each top-level directory). Note in the session whether this is the variant's first sync.

4. **Read the sync log** at `FrameworkBuilder/{variant}/sync-log.md` to understand recent sync history. Skim last 2–3 entries.

### Execution

5. **Discover new drift**. For each in-scope top-level directory, walk the source project and the blueprint, comparing structure:
   - Files/dirs present in project but missing in blueprint
   - Files/dirs present in both with content differences
   - Files/dirs present in blueprint but missing in project (flag — likely stale blueprint or project-removed; ask user)
   - Subdirectory shape differences

   > **🚨 Walk depth**: Consult the [Blueprint Sync Consideration Policy Guide](../../guides/support/blueprint-sync-consideration-policy-guide.md) before declaring a directory clean. It classifies every second-level subdir and skeleton file as **Ignore Content** / **Consider Structure** / **Always Consider Section-Shape**, and lists the section/table/schema surfaces to compare for skeleton files (registries, trackers, doc-maps). Do not declare a directory "no structural drift" after a 1-level walk — subdirs tagged Always Consider Section-Shape need section-level comparison.

   Cross-reference against the sync backlog: separate findings into **already-known** (present in backlog) and **newly-discovered** (not in backlog).

6. **Update the sync backlog** with all newly-discovered items. This is critical: the backlog is updated even if the user decides not to sync those items this session — the discoveries persist.

7. **Create a session temp state file** via:
   ```
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/support/New-TempTaskState.ps1 -TaskName "{variant}-{YYYYMMDD}" -Variant BlueprintSync -Confirm:$false
   ```
   Produces `process-framework-local/state-tracking/temporary/temp-blueprint-sync-{variant}-{YYYYMMDD}.md` from the [Blueprint Sync State template](../../templates/support/temp-blueprint-sync-state-template.md). Populate with:
   - The full known-drift inventory (backlog items + new discoveries)
   - User's selection for this session
   - Per-item classification and target directory rule

8. **Classify each candidate item**:
   - **For `process-framework/` items**: classification is automatic — wholesale replace applies.
   - **For `process-framework-local/` items**: classification is automatic — structure-only sync applies.
   - **For `doc/`, `test/`, root files**: classify per item:
     - **Framework-general → SYNC**
     - **Project-specific → SKIP**
     - **Ambiguous → ASK**

   **Reference Verification sub-step (mandatory for blueprint-only items)** — applies to any registry prefix, template, or script present in the blueprint but missing in the project (i.e., the items Step 5 flagged for "ask user"). Before recommending REMOVE or RETAIN, grep both trees' framework code for the identifier:
   - **ID-registry prefix** (e.g., `PD-ARC`, `WF`) → grep code for the prefix string in `process-framework/scripts/`, `process-framework/templates/`, and the corresponding `*-id-registry.json` files in both trees
   - **Template** (e.g., `pre-framework-quality-assessment-template.md`) → grep for the template filename and any `New-*.ps1` script that references it
   - **Script** (e.g., `New-QualityAssessmentReport.ps1`) → grep for the script filename in task definitions, doc-maps, and other scripts

   **Decision rule**:
   - References found in either tree's framework code → **recommend RETAIN IN BLUEPRINT** (framework-canonical scaffolding for tasks not yet exercised in this project); record the path:line of the strongest reference as evidence.
   - No references found in either tree → **recommend REMOVE candidate**; record the scope greped (e.g., "no references found in `process-framework/scripts/`, `process-framework/templates/`, both ID registries") as evidence.

   **🚨 The agent does NOT auto-classify or auto-apply REMOVE for blueprint-only items.** In both branches the recommendation + evidence is presented at the Step 9 inventory checkpoint, and **the human decides per-case** whether to apply the recommendation. Record both the recommendation and the human's decision in the Per-Item Classification table (Status column) and in Notes on Specific Items.

9. **Present session inventory checkpoint**. Show the user:
   ```
   ## Sync Session: {variant} ← {project} ({YYYY-MM-DD})

   ### Known drift in backlog (N items)
   - ...

   ### Newly discovered this session (M items)
   - ...

   ### Selected for this session (K items)
   - process-framework/ — wholesale replace
   - process-framework-local/ — structure additions: [list]
   - doc/ classified items: [sync/skip/ask details]
   - test/ classified items: [sync/skip/ask details]
   - root files: [sync/skip/ask details]

   ### Deferred to backlog (P items)
   - ...
   ```
   **Do not proceed until user confirms selection and resolves ambiguous items.** For every blueprint-only item (per Step 8 Reference Verification sub-step), include the recommendation (RETAIN / REMOVE candidate) **and** the grep evidence backing it. The human decides per-case; the agent does not REMOVE without an explicit per-item human approval.

10. **Apply approved changes per directory rule**:
    - **`process-framework/`**: copy entire tree from project to blueprint, replacing. (Exception: do NOT copy `__pycache__/` or other tooling artifacts.)
    - **`process-framework-local/`**: create new subdirs as needed; for skeleton files (`PF-id-registry-local.json`), merge new structural fields without copying values.
    - **`doc/`, `test/`, root files**: apply per item type:
      - **New directories**: create with empty contents (or `.gitkeep` if needed)
      - **New files** (templates, README, scripts): copy from project, then strip project-specific identifiers (project name, populated examples, ID counters)
      - **Modified files** (registries, doc-maps, templates): for registries, merge new prefixes but reset `nextAvailable` to `1`; for doc-maps, add structural sections but omit project-specific entries; for templates, preserve placeholder syntax
    - **Scaffolders**: if a scaffolder script (e.g., `New-TestInfrastructure.ps1`) hardcodes a directory or file list now out of sync, update it. Per the thin-scaffolder principle, scaffolders should defer to the blueprint where possible — flag any scaffolder reproducing blueprint structure as a candidate for refactor.

11. **Validate blueprint internal consistency**:
    - All new ID-registry prefixes have a corresponding template OR are referenced by an existing script
    - All new doc-map entries point to files that exist in the blueprint
    - No project-specific identifier leaked outside `process-framework/` (grep for project name in changed blueprint files; `process-framework/` is exempt since it's wholesale-replaced and assumed to be project-neutral by design — flag if grep finds anything there as a project hygiene issue)
    - **Protected artifacts unmodified**: every populated DB/binary file at blueprint root either appears in the [Known Protected Artifacts](#known-protected-artifacts-root-files) list (no action) or has explicit user confirmation as protected/leak before any DELETE or overwrite. **No autonomous DELETE on populated binary files at blueprint root.**
    - Scaffolders (if touched) still produce a self-consistent tree

### Finalization

12. **Update the sync backlog**: mark synced items as resolved (or remove); leave unfinished/deferred items as "still pending" with date discovered.

13. **Append to sync log** at `FrameworkBuilder/{variant}/sync-log.md`. Format:
    ```
    ## YYYY-MM-DD — {project} → {variant}

    **Scope**: {dirs synced}
    **Items synced** (N):
    - ...
    **Items skipped** (M):
    - ... (reason)
    **Items deferred to backlog** (K):
    - ...
    **Notable decisions**:
    - ...
    ```

14. **Update source project tracking**: if the source project had a temp state, IMPs, or other tracking that flagged the synced changes, mark them as "synced to {variant} on YYYY-MM-DD".

15. **Move session temp state** to `process-framework-local/state-tracking/temporary/old/` — the durable record lives in the backlog and log.

16. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below.

## Outputs

- **Updated blueprint files** under `FrameworkBuilder/{variant}/` — the synced changes
- **Updated sync backlog** at `FrameworkBuilder/{variant}/sync-backlog.md` — new discoveries appended; synced items removed
- **New sync log entry** at `FrameworkBuilder/{variant}/sync-log.md` — append-only history
- **Session temp state** (transient, archived at session end) — per-session work tracker

## State Tracking

- **Per-variant durable state**: `FrameworkBuilder/{variant}/sync-backlog.md` and `FrameworkBuilder/{variant}/sync-log.md` (live in the blueprint repo, not the source project)
- **Per-session transient state**: temp state file via `New-TempTaskState.ps1` (lives in source project's `process-framework-local/state-tracking/temporary/`)

The backlog + log are the canonical durable artifacts. The temp state is scaffolding for one session.

## ⚠️ MANDATORY Task Completion Checklist

**TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF**

- [ ] **Target framework variant confirmed** with user and path verified
- [ ] **Source project confirmed**
- [ ] **Sync backlog located or created** at `FrameworkBuilder/{variant}/sync-backlog.md`
- [ ] **New drift discovered** by walking project vs blueprint
- [ ] **Backlog updated** with newly-discovered items (even if not synced this session)
- [ ] **Session temp state created** with full inventory and user selection
- [ ] **Inventory classified** per directory rules; ambiguous items resolved at checkpoint
- [ ] **Approved changes applied** per directory:
  - [ ] `process-framework/` wholesale-replaced (if in scope)
  - [ ] `process-framework-local/` structure-only sync (if in scope)
  - [ ] `doc/`, `test/`, root files: per-item classified items applied
  - [ ] Scaffolder updates applied (if needed)
- [ ] **Blueprint internal consistency validated**:
  - [ ] No project-specific identifiers leaked outside `process-framework/`
  - [ ] All new registry prefixes have a template or script reference
  - [ ] All new doc-map entries point to existing blueprint files
  - [ ] No autonomous DELETE on populated binary files at blueprint root; protected artifacts list checked
  - [ ] Scaffolders (if touched) still produce a consistent tree
- [ ] **Sync backlog updated** (synced items resolved; deferred items retained)
- [ ] **Sync log entry appended** at `FrameworkBuilder/{variant}/sync-log.md`
- [ ] **Source project tracking updated** if applicable (temp state, IMPs marked synced)
- [ ] **Session temp state moved** to `temporary/old/`
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Guide](../../guides/framework/feedback-form-guide.md) for each tool used, using task ID "PF-TSK-087" and context "Framework Blueprint Sync"

## Next Tasks

- **Framework Evaluation (PF-TSK-079)** - Periodically run on the blueprint after several syncs to verify it's still self-consistent and complete
- **Process Improvement (PF-TSK-009)** - If sync surfaces gaps in the sync workflow itself, log IMPs to refine this task

## Related Resources

- [Blueprint Sync Consideration Policy Guide](../../guides/support/blueprint-sync-consideration-policy-guide.md) - Per-subdirectory and per-skeleton-file classification policy for Step 5 (Discover new drift)
- [Framework Registry](../../../../FrameworkBuilder/Framework_Registry.json) - Registered framework variants
- [Process Improvement Task](process-framework/tasks/support/process-improvement-task.md) - Common upstream source of changes worth syncing
- [Tools Review Task](process-framework/tasks/support/tools-review-task.md) - Same upstream relationship
- [Framework Evaluation Task](process-framework/tasks/support/framework-evaluation.md) - Validates blueprint health periodically
- PF-STA-103 (temp) - Initial validation case: 5 drift items between LinkWatcher `test/` and `FrameworkBuilder/appdev/test/`
