---
id: PF-TSK-088
type: Process Framework
category: Task Definition
version: 1.1
created: 2026-05-10
updated: 2026-05-16
description: "Deploy framework code from canonical appdev to registered projects."
---

# Framework Rollout

## Purpose & Context

Deploy framework code from the canonical `appdev/process-framework/` to registered projects, and apply per-project working-document migrations that accompany framework structural changes.

**Operating model**: improvements are authored canonically in `appdev/`, then **pushed** to projects (vendored copies are read-only there). This task is the deliberate forward-deployment step. Replaces [PF-TSK-087 framework-blueprint-sync](framework-blueprint-sync-task.md), which propagated changes in the opposite direction (project → blueprint) and is being deprecated.

**Scope**: covers `appdev/process-framework/` mirroring to projects, project working-document migrations driven by `pending-migrations.md` ledgers, and the project-registration pre-step.

**Direction**: appdev → projects only. Reverse direction (project → appdev) does not exist in this model — framework changes happen in `appdev` directly.

## AI Agent Role

**Role**: Release Engineer
**Mindset**: Cautious, deterministic, recovery-first — every rollout must be cleanly rollback-able; every project state must be visible before, during, and after.
**Focus Areas**: Pre-flight verification, dry-run reasoning, atomic git tagging, registry consistency, recovery paths.
**Communication Style**: Surface what will change *before* it changes. Default to `-Check` first when human partner is unsure. Ask before any operation that crosses the appdev → project boundary if pre-flight surfaces unexpected state (uncommitted changes, version mismatches, registry drift).

## Key Concepts

### Project Registry (durable)

Path: `appdev/process-framework-central/project-registry.json`

Single source of truth for which projects exist, where they live on disk, and their rollout state. Keyed by stable `PRJ-NNN` ID (rename-safe). Schema documented in [centralized-framework-management proposal §3.10](../../../process-framework-central/proposals/centralized-framework-management.md). All rollout decisions read from this file.

### Rollout Tag Convention

Each rollout to one or more projects creates a git tag in `appdev` of the form `rollout-<YYYY-MM-DD-NNN>` (NNN is a same-day counter). The tag points to the appdev commit containing the `process-framework/` snapshot that was mirrored. Restores reference these tags. The tag is the backup — no physical `.bak/` directory needed.

### Framework Version Files (per project)

Three single-line files written into `<project>/process-framework/` by every rollout:

- `.framework-version` — current rolled version (e.g., `2026-05-08-001`)
- `.framework-version-previous` — prior version, used as the cheap rollback signal by `Restore-FrameworkVersion.ps1`
- `.framework-central-pointer` — absolute path to `appdev/`, consumed by project-side scripts that need to write to centralized state

### Pending Migrations Ledger (durable, per project)

Path: `appdev/process-framework-central/per-project-migrations/<PRJ-ID>/pending-migrations.md`

Append-only ledger of project working-document changes that the bulk push (Phase 1) **cannot** apply because they touch project-specific data (e.g., adding a column to `feature-tracking.md`, restructuring `state-tracking/permanent/`). Created by [Structure Change (PF-TSK-014)](structure-change-task.md) when the change affects project working docs. Phase 2 of this task drains the ledger in cwd=Project sessions.

> **🚨 Scope boundary — what migration entries are NOT for**: The ledger is **only** for changes to project files **outside** the rolled-out subtree (`<project>/doc/`, `<project>/test/`, `<project>/src/`, `<project>/CLAUDE.md`, etc.). Changes **inside** `blueprint/process-framework/` itself — adding files, moving files within the subtree, deleting files, or moving files *out* of the subtree into `process-framework-central/` — propagate automatically via the Mode B `robocopy /MIR` mirror at the next Push (the mirror adds new files, updates modified files, and orphan-deletes files no longer present in blueprint). Authors of intra-blueprint changes should **not** write migration entries for those — the mirror handles them. See [Structure Change Step 14.5](structure-change-task.md) Scope Boundary table for examples.

### Rollout Log (durable)

Path: `appdev/process-framework-central/rollouts/rollout-log.md`

Append-only history of every rollout: timestamp, version tag, target project IDs, dry-run vs real, notable decisions. Survives across sessions; used for rollback and audit.

## Operating Modes

This task has **four distinct sub-flows**, each with its own session boundary. Pick one per session — they are not chained.

| Mode | When | cwd | Driver Script |
|---|---|---|---|
| **A. Project Registration (Retrofit)** | Retrofitting an existing project, or one-time PRJ-000 appdev self-registration. **For NEW projects, registration runs as a step inside [Project Initiation (PF-TSK-059)](../00-setup/project-initiation-task.md) — not via this task.** | Project | [Register-Project.ps1](../../scripts/file-creation/support/Register-Project.ps1) |
| **B. Phase 1 Rollout (Bulk Push)** | Coherent IMP batch ready to deploy | appdev | [Push-FrameworkUpdate.ps1](../../../../FrameworkBuilder/appdev/process-framework-central/scripts/Push-FrameworkUpdate.ps1) |
| **C. Phase 2 Per-Project Migrations** | Project's pending-migrations ledger has open entries | Project | (manual; references migration entries) |
| **D. Rollback** | Recent rollout broke a project | appdev | [Restore-FrameworkVersion.ps1](../../../../FrameworkBuilder/appdev/process-framework-central/scripts/Restore-FrameworkVersion.ps1) |

> **🚨 NEVER COMBINE MODES IN ONE SESSION.** Each mode produces a distinct artifact set and audit trail.

## Context Requirements

<!-- Uncomment and update when context map is created:
[View Context Map for this task](../../visualization/context-maps/support/framework-rollout-map.md) -->

- **Critical (Must Read):**

  - `appdev/process-framework-central/project-registry.json` — Authoritative project list; all routing decisions read from this file
  - [Framework Rollout Usage Guide](../../guides/support/framework-rollout-usage-guide.md) *(to be created)* — Customization patterns for Push/Restore/Register invocations and dry-run interpretation
  - `appdev/process-framework-central/rollouts/rollout-log.md` — Prior rollouts and their target project sets

- **Important (Load If Space):**

  - [Pending Migration Entry Template](../../templates/support/pending-migration-entry-template.md) *(to be created)* — Structure of one entry in the per-project ledger
  - [Script Development Quick Reference](../../guides/support/script-development-quick-reference.md) — PowerShell execution patterns; **always check parameters with `-?` before running**
  - [Project Initiation (PF-TSK-059)](../00-setup/project-initiation-task.md) — For new projects, registration is invoked as the final step of Project Initiation. PF-TSK-088 Mode A handles only retrofit and the PRJ-000 self-registration.

- **Reference Only (Access When Needed):**

  - [Structure Change (PF-TSK-014)](structure-change-task.md) — The task that *writes* `pending-migrations.md` entries (this task *applies* them)
  - [Process Improvement (PF-TSK-009)](process-improvement-task.md) — Coordinated through the IMP batch that triggers Mode B
  - [Visual Notation Guide](../../guides/support/visual-notation-guide.md) — For context map interpretation

> **Historical context (post-migration archived; do not rely on as live references):**
>
> - Source proposal `appdev/process-framework-central/proposals/centralized-framework-management.md` (working draft v4) — the design doc that produced this task. Will move to `proposals/old/` after the migration completes.
> - Extension state file `appdev/process-framework-central/state-tracking/temporary/temp-framework-extension-centralized-framework-management.md` — multi-phase implementation tracker. Will move to `state-tracking/temporary/old/` after Phase 10 completes.
> - [Framework Blueprint Sync (PF-TSK-087)](framework-blueprint-sync-task.md) — predecessor task being deprecated by this task (Phase 10 of the extension).

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished!**
>
> **⚠️ MANDATORY: Pick exactly one operating mode (A/B/C/D) per session. Do not combine.**

---

### Mode A: Project Registration (Retrofit)

**Run from**: `<project>` cwd (the project being registered).

**Scope**: Mode A is **retrofit-only**. Use it when:
- Onboarding an existing project that pre-dates the framework's centralized model (existing `src/`, `doc/`, `test/` content; no `project_id` in `doc/project-config.json`).
- One-time PRJ-000 self-registration for appdev itself (run with `-IsAppdev` flag from appdev cwd).

**Do NOT use Mode A for new projects.** New-project registration is a step inside [Project Initiation (PF-TSK-059)](../00-setup/project-initiation-task.md) — that task scaffolds the project AND invokes Register-Project as its final step. Treating new-project registration as a separate Mode A session creates a two-step user flow with avoidable handover friction.

Mode A assigns a stable PRJ-NNN ID, adds the project to the registry, writes `project_id` into the project's `doc/project-config.json`. Does **not** roll out framework code — that happens in Mode B after registration.

#### Preparation

1. Confirm this is a retrofit (existing project pre-dating the framework, or PRJ-000 self-registration). For new projects, route to PF-TSK-059 instead.
2. Confirm `appdev/process-framework-central/project-registry.json` exists and is well-formed.
3. Decide whether this registration is for an existing project (PRJ-001+) or for `appdev` itself (PRJ-000, special case via `-IsAppdev`).

#### Execution

4. Run `Register-Project.ps1`:
   ```bash
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/support/Register-Project.ps1 -Path "<absolute-project-path>" -Name "<DisplayName>" -Confirm:\$false
   ```

   For appdev itself (one-time, reserves PRJ-000):
   ```bash
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/support/Register-Project.ps1 -IsAppdev -Confirm:\$false
   ```

5. **Inspect script output**: confirm assigned PRJ-NNN, registry entry added, `project_id` written to `<project>/doc/project-config.json`.

6. **🚨 CHECKPOINT**: Present registration result to human partner before proceeding to first rollout (Mode B).

#### Finalization

7. Validate: `<project>/doc/project-config.json` `project_id` field matches the central registry entry.
8. Validate: registry's `current_framework_version` is `null` (no rollout yet) and `last_rollout` is `null` for retrofit. (For PRJ-000 self-registration: `version_freeze: true` and `frozen_at_version: null`.)
9. **🚨 MANDATORY FINAL STEP**: Complete the [Mode A Completion Checklist](#mode-a-completion-checklist) below.

---

### Mode B: Phase 1 Rollout (Bulk Push)

**Run from**: `appdev/` cwd.

**Per IMP batch.** Mirrors `appdev/process-framework/` to one or more registered projects. Single-session.

#### Preparation

1. Confirm cwd is `appdev/` (script will refuse otherwise).
2. Confirm `appdev/process-framework/` has the intended changes staged or committed (`git status` clean except for the rollout commit-to-be).
3. Decide rollout scope:
   - All eligible projects (omit `-Project`)
   - Canary subset: specify one or more `-Project <PRJ-NNN>` (substitute the actual ID, e.g., `-Project PRJ-001`)
4. Read `appdev/process-framework-central/rollouts/rollout-log.md` tail to confirm the previous rollout completed cleanly.
5. **MANDATORY DRY-RUN**: invoke with `-Check` first to surface what will change without writing files.

#### Execution

6. **Dry-run**:
   ```bash
   pwsh.exe -ExecutionPolicy Bypass -File appdev/process-framework-central/scripts/Push-FrameworkUpdate.ps1 -Check -Confirm:\$false
   ```
   Optionally with `-Project <PRJ-NNN>` to scope dry-run to one project.

7. **🚨 CHECKPOINT**: Review dry-run output with human partner. Confirm:
   - Files reported as changed match expectations.
   - No unexpected projects are in scope (frozen projects should be skipped automatically).
   - Pre-flight passes (no uncommitted changes in `appdev/process-framework/` unless `-Force`).

8. **Real rollout**:
   ```bash
   pwsh.exe -ExecutionPolicy Bypass -File appdev/process-framework-central/scripts/Push-FrameworkUpdate.ps1 -Confirm:\$false
   ```
   Or with `-Project <PRJ-NNN>` for canary.

9. The script:
   - Commits + tags `appdev` at `rollout-<YYYY-MM-DD-NNN>`.
   - Pushes commit + tag to GitHub remote (`Abtomation/framework-appdev`) for off-machine durability.
   - Mirrors `appdev/process-framework/` → each filtered project's `process-framework/`.
   - Writes/updates `.framework-version`, `.framework-version-previous`, `.framework-central-pointer` in each target project.
   - Appends entry to `rollout-log.md` recording target project IDs.
   - Updates `current_framework_version` and `last_rollout` for each target in `project-registry.json`.

#### Finalization

10. Validate: `git tag` shows the new `rollout-*` tag in `appdev`.
11. Validate: GitHub remote received the push (`git push origin main` and tag push exit code 0; warn-only if network failed but local commit + tag still applied).
12. Validate: each target project's `.framework-version` reads the new version.
13. Validate: `rollout-log.md` has the new entry.
14. **If PRJ-T01 was in scope**: refresh the sandbox baseline commit (see [Sandbox Baseline Maintenance](#sandbox-baseline-maintenance-prj-t01-only) below).
15. **🚨 MANDATORY FINAL STEP**: Complete the [Mode B Completion Checklist](#mode-b-completion-checklist) below.

#### Sandbox Baseline Maintenance (PRJ-T01 only)

> **Scope**: This subsection applies **only when `PRJ-T01` (the appdev framework self-test sandbox at `FrameworkBuilder/sandboxes/appdev/PRJ-000/`) is among the projects targeted by the Push**. Skip entirely if PRJ-T01 was not in scope.

**Why**: The sandbox is the canonical E2E target for the Framework Self-Testing extension (PF-PRO-035). Its E2E tests reset between runs to a known baseline using `git checkout HEAD -- <path>` against the sandbox's own git repository (see [E2E Acceptance Test Execution (PF-TSK-070) §Sandbox Execution](../03-testing/e2e-acceptance-test-execution-task.md#sandbox-execution-prj-t01-only)). If a Push lands new rolled-out content in the sandbox but the new content is **not** committed to `HEAD`, the next test reset would revert the rolled-out content and break tests that depend on it.

**The discipline**: every Push to PRJ-T01 must be followed by a baseline commit that captures the post-rollout state. Sandbox state is rollout-pipeline-owned — **no ad-hoc copies, no manual edits**. Every change to the sandbox flows through Push (and then through this baseline-commit step).

**SOP** — after a Push that targeted PRJ-T01 lands:

```bash
pwsh.exe -ExecutionPolicy Bypass -File appdev/process-framework-central/scripts/Commit-SandboxBaseline.ps1 -Confirm:\$false
```

The script:
- Reads PRJ-T01's path from `project-registry.json`.
- In the sandbox's own git repo: `git add -A` then `git commit -m "baseline: post-rollout v<framework-version>"`.
- Refuses to run if the sandbox working tree is clean (nothing to baseline — Push didn't actually change anything in PRJ-T01).
- Refuses to run if cwd is anywhere other than appdev.

After this step, the sandbox's `HEAD` reflects the post-rollout state, and the next E2E test reset cycle uses it as the canonical pristine baseline.

**Anti-pattern to avoid**: don't manually copy a single framework script from `appdev/blueprint/.../X.ps1` into `sandboxes/appdev/PRJ-000/process-framework/.../X.ps1` to "sync" a pending edit for E2E testing. This contaminates the sandbox state in ways the rollout/restore E2E tests (Phase 3.5 Tier C cases WF-006 / WF-NEW-B) cannot trust. To test a pending edit E2E, do a real Push to PRJ-T01 (commits + tags appdev — that's the cost) and then run `Commit-SandboxBaseline.ps1`.

---

### Mode C: Phase 2 Per-Project Migrations

**Run from**: `<project>` cwd (the project whose ledger has open entries). Project-cwd is mandatory: the project's own LinkWatcher catches edits in real-time, project-specific validation scripts run naturally, and the project's IDE workspace context auto-loads.

**Per project, when ledger has entries.** Applies migrations from `pending-migrations.md` against project working documents (`doc/feature-tracking.md`, `doc/state-tracking/permanent/*.md`, `test/test-tracking.md`, etc.).

> **🚨 BACKWARD-COMPATIBILITY DESIGN PRINCIPLE**: Mode C migrations should be designed to be **backward-compatible** with the prior framework version whenever possible — additive columns optional, new sections placed where prior version still parses cleanly, schema changes default to no-op for old code paths. This makes Mode D rollback safe by construction. When a migration *cannot* be backward-compatible (e.g., a column rename that breaks the prior schema), the migration entry MUST flag this in its "Rollback Implications" field, and Mode D will require manual project-side reversal before rollback (see Mode D warning).

#### Preparation

1. Read `appdev/process-framework-central/per-project-migrations/<PRJ-ID>/pending-migrations.md`. Identify open entries.
2. For each open entry, read the linked Structure Change source (the task that wrote the entry) to understand the rationale and the entry's "Rollback Implications" field.
3. Confirm the project is on the framework version that introduced the migration entries (check `<project>/process-framework/.framework-version`).
4. Plan which entries will be processed in this session (one entry per checkpoint is the safe pattern).

#### Execution

5. For each entry chosen for this session:
   - Apply the migration to the named project working document.
   - Verify the change matches the entry's expected outcome (entry should specify before/after state or schema).
   - Run any project-side validation referenced in the entry (e.g., `Validate-StateTracking.ps1`).
   - **🚨 CHECKPOINT** with human partner before marking the entry resolved.
   - Mark the entry resolved with [Update-PendingMigration.ps1](../../scripts/update/Update-PendingMigration.ps1) (PF-IMP-932) — it flips the Status in **both** the Summary-table row and the per-entry section in a single write, stamping the Resolved date and the Resolved By attribution, so the two Status sites stay in lockstep:
     ```bash
     pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/update/Update-PendingMigration.ps1 -Project <PRJ-ID> -MigrationId MIG-NNN -ResolvedBy "<PRJ-ID> Mode C <date> (<project-name>)" -Confirm:\$false
     ```
     For an entry that turns out not to apply to this project, use `-NewStatus Skipped` instead (no `-ResolvedBy` needed). If the two Status sites were already inconsistent, the script reports the drift and repairs both.

6. If an entry surfaces unexpected divergence (project working doc has drifted from what the entry assumes), pause and ask the human partner — do **not** force the migration.

#### Finalization

7. Validate: applied entries are marked resolved with timestamp; remaining entries still open.
8. Validate: `Validate-StateTracking.ps1` against the project passes.
9. **🚨 MANDATORY FINAL STEP**: Complete the [Mode C Completion Checklist](#mode-c-completion-checklist) below.

---

### Mode D: Rollback

**Run from**: `appdev/` cwd.

**Emergency.** Reverts a project's `process-framework/` to a previous version after a rollout broke it.

> **🚨 SCOPE WARNING — `doc/` AND `test/` ARE NOT REVERTED**: Mode D restores `<project>/process-framework/` from appdev's git tags. It does **NOT** touch `<project>/doc/` or `<project>/test/`. If recent Mode C migrations modified those directories, those changes remain in place after rollback. Two consequences:
>
> 1. **Backward-compatible Mode C migrations** (the design default — see Mode C principle): rollback is safe; the prior framework version still parses the post-migration working docs cleanly.
> 2. **Non-backward-compatible Mode C migrations** (flagged in the entry's "Rollback Implications" field): the operator MUST reverse the project working-doc changes manually via the project's git history (`git revert`, `git checkout` of specific files, or restoring from a project-side backup) **BEFORE** running Mode D — otherwise the rolled-back framework will read schema-mismatched working docs and produce errors.
>
> When in doubt, scan `pending-migrations.md` for entries resolved between the rollback target version and the current version, check their "Rollback Implications" fields, and surface any non-backward-compatible entries to the human partner before proceeding.

#### Preparation

1. Identify the broken project's PRJ-NNN ID.
2. Read the project's `<project>/process-framework/.framework-version-previous` — this is the rollback target by default.
3. (Optional) Identify a specific older version if the prior version is also broken: scan `rollout-log.md` for prior tags.
4. **Scan recent Mode C migrations**: read the project's `pending-migrations.md` ledger and review entries resolved between the rollback target and the current version. Flag any entries whose "Rollback Implications" field indicates non-backward-compatible changes.
5. **🚨 CHECKPOINT** with human partner: confirm rollback is the right call (a failed migration may be fixable forward instead) AND confirm any non-backward-compatible Mode C migrations have been manually reversed in the project before proceeding.

#### Execution

5. Run `Restore-FrameworkVersion.ps1`:
   ```bash
   pwsh.exe -ExecutionPolicy Bypass -File appdev/process-framework-central/scripts/Restore-FrameworkVersion.ps1 -Project <PRJ-NNN> -Confirm:\$false
   ```
   Or with `-ToVersion 2026-05-08-001` to rollback to a specific older version.

6. The script:
   - Reads the project's `.framework-version-previous` (or uses `-ToVersion` if specified).
   - Checks out `appdev` at the corresponding `rollout-<YYYY-MM-DD-NNN>` tag.
   - Re-mirrors `appdev/process-framework/` (at the tagged state) → project's `process-framework/`.
   - Updates `.framework-version` and `.framework-version-previous` to reflect the rollback.
   - Appends a "rollback" entry to `rollout-log.md`.
   - Restores `appdev` working tree to the latest commit (rollback affects the project, not appdev's main branch).

#### Finalization

7. Validate: target project's `.framework-version` matches the rollback target.
8. Validate: `rollout-log.md` has the rollback entry with reason note.
9. Validate: original failure mode is no longer reproduced in the target project.
10. **🚨 MANDATORY FINAL STEP**: Complete the [Mode D Completion Checklist](#mode-d-completion-checklist) below.

---

## Outputs

### Mode A Outputs

- **Updated** `appdev/process-framework-central/project-registry.json` — New PRJ-NNN entry with name, path, added date, freeze defaults.
- **Updated `<project>/doc/project-config.json`** — `project_id` field added/updated.
- **(For real projects only)** New `appdev/process-framework-central/per-project-migrations/<PRJ-ID>/` directory with empty `pending-migrations.md` skeleton.

### Mode B Outputs

- **New git tag in appdev** — `rollout-<YYYY-MM-DD-NNN>`.
- **New commit pushed to GitHub remote** (`Abtomation/framework-appdev`).
- **Mirrored `<project>/process-framework/`** for each target project (every file replaced).
- **Updated `<project>/process-framework/.framework-version`** and `.framework-version-previous` and `.framework-central-pointer` for each target.
- **New entry in** `appdev/process-framework-central/rollouts/rollout-log.md`.
- **Updated** `appdev/process-framework-central/project-registry.json` — `current_framework_version` and `last_rollout` for each target.

### Mode C Outputs

- **Modified project working documents** — exactly the files named in the resolved migration entries.
- **Updated `appdev/process-framework-central/per-project-migrations/<PRJ-ID>/pending-migrations.md`** — entries marked resolved with timestamp.

### Mode D Outputs

- **Reverted `<project>/process-framework/`** — files restored to the rollback target version.
- **Updated `<project>/process-framework/.framework-version`** and `.framework-version-previous`.
- **New rollback entry in** `appdev/process-framework-central/rollouts/rollout-log.md` — clearly distinguishable from forward rollouts.

## State Tracking

The following state files are updated by this task (which file depends on which mode):

- `appdev/process-framework-central/project-registry.json` — Modes A, B (registry path resolved at session start via `<project>/process-framework/.framework-central-pointer` for project-side scripts, or directly from cwd for appdev-side scripts)
- `appdev/process-framework-central/rollouts/rollout-log.md` — Modes B, D
- Per-project `pending-migrations.md` ledger — Mode C
- Per-project `<project>/process-framework/.framework-version` and `.framework-version-previous` — Modes B, D
- Per-project `<project>/doc/project-config.json` — Mode A

> **No temp state file required.** Each mode is single-session by design. Cross-session continuity lives in the durable artifacts above (registry, rollout log, pending-migrations ledger).

## ⚠️ MANDATORY Task Completion Checklist

**TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF**

> Use the checklist matching the operating mode for this session.

### Mode A Completion Checklist

- [ ] **Registration verified**:
  - [ ] PRJ-NNN ID assigned and shown in `Register-Project.ps1` output
  - [ ] `appdev/process-framework-central/project-registry.json` contains the new entry
  - [ ] `<project>/doc/project-config.json` `project_id` field matches registry
  - [ ] (For real projects) `appdev/process-framework-central/per-project-migrations/<PRJ-ID>/` directory created with empty ledger
- [ ] **Checkpoint with human partner** completed before any subsequent rollout
- [ ] **Complete Feedback Form**: [Feedback Form Guide](../../guides/framework/feedback-form-guide.md), task ID `PF-TSK-088`, context "Framework Rollout (Mode A: Project Registration)"

### Mode B Completion Checklist

- [ ] **Pre-flight passed**:
  - [ ] cwd was `appdev/`
  - [ ] No uncommitted changes in `appdev/process-framework/` (or `-Force` was explicitly chosen with rationale)
  - [ ] Dry-run output reviewed and approved by human partner
- [ ] **Rollout completed**:
  - [ ] Git tag `rollout-<version>` exists in appdev
  - [ ] GitHub remote received commit + tag (or warning logged with rationale if network failed)
  - [ ] Each target project's `.framework-version` matches the new version
  - [ ] `appdev/process-framework-central/rollouts/rollout-log.md` has the new entry
  - [ ] `appdev/process-framework-central/project-registry.json` shows updated `current_framework_version` and `last_rollout` per target
- [ ] **Frozen projects verified skipped** (if any are in registry with `version_freeze: true`)
- [ ] **If PRJ-T01 was in scope**: `Commit-SandboxBaseline.ps1` was run and produced a new baseline commit in `sandboxes/appdev/PRJ-000/`. See [Sandbox Baseline Maintenance](#sandbox-baseline-maintenance-prj-t01-only).
- [ ] **Complete Feedback Form**: [Feedback Form Guide](../../guides/framework/feedback-form-guide.md), task ID `PF-TSK-088`, context "Framework Rollout (Mode B: Phase 1 Bulk Push)"

### Mode C Completion Checklist

- [ ] **Migration entries processed**:
  - [ ] Each entry chosen for this session is marked resolved (or skipped) via [Update-PendingMigration.ps1](../../scripts/update/Update-PendingMigration.ps1), so the Summary row and per-entry Status stay in lockstep
  - [ ] Project working documents reflect the migration outcomes
  - [ ] No entry was force-applied past unexpected divergence (any divergence escalated to human partner)
- [ ] **Project validation passes**:
  - [ ] `Validate-StateTracking.ps1` against the project succeeds
  - [ ] Any migration-specific validation referenced in entries succeeded
- [ ] **Remaining entries clearly visible** in `pending-migrations.md` for the next Mode C session
- [ ] **Complete Feedback Form**: [Feedback Form Guide](../../guides/framework/feedback-form-guide.md), task ID `PF-TSK-088`, context "Framework Rollout (Mode C: Per-Project Migrations)"

### Mode D Completion Checklist

- [ ] **Recent Mode C migrations scanned**: `pending-migrations.md` entries between rollback target and current version reviewed for "Rollback Implications" field
- [ ] **Non-backward-compatible Mode C migrations reversed**: any flagged entries have been manually reverted in the project's `doc/` or `test/` BEFORE rollback (or human partner explicitly accepted schema-mismatched state)
- [ ] **Rollback target confirmed** with human partner before execution
- [ ] **Rollback completed**:
  - [ ] Target project's `.framework-version` matches the rollback target
  - [ ] Target project's `.framework-version-previous` updated correctly
  - [ ] `appdev/process-framework-central/rollouts/rollout-log.md` has the rollback entry
  - [ ] Original failure mode is no longer reproduced
- [ ] **Appdev working tree** is on the latest main commit (not stuck on the rollback tag)
- [ ] **Forward-fix path identified** (so the rolled-back project gets back onto a healthy version eventually)
- [ ] **Complete Feedback Form**: [Feedback Form Guide](../../guides/framework/feedback-form-guide.md), task ID `PF-TSK-088`, context "Framework Rollout (Mode D: Rollback)"

## Next Tasks

- **Mode A → Mode B**: After registering a new project, the first rollout to that project (Mode B with `-Project PRJ-NNN`) deploys the framework code.
- **Mode B → Mode C**: After a rollout that includes structural migrations, project-side Mode C sessions (one per affected project) drain the `pending-migrations.md` ledgers.
- **Mode B → Mode D**: If a rollout breaks a project, Mode D rolls it back; a forward-fix to the broken framework version follows in `appdev`, then a new Mode B re-deploys.
- **Mode C → no specific next**: Migration sessions are tail-end; each one is self-contained.
- **Trigger upstream**: [Process Improvement (PF-TSK-009)](process-improvement-task.md) and [Structure Change (PF-TSK-014)](structure-change-task.md) are the upstream IMP-batch sources that motivate Mode B sessions.

## Related Resources

- [Push-FrameworkUpdate.ps1](../../../../FrameworkBuilder/appdev/process-framework-central/scripts/Push-FrameworkUpdate.ps1) *(to be created in centralized-framework-management Phase 3)* — Mode B driver
- [Restore-FrameworkVersion.ps1](../../../../FrameworkBuilder/appdev/process-framework-central/scripts/Restore-FrameworkVersion.ps1) *(to be created)* — Mode D driver
- [Register-Project.ps1](../../scripts/file-creation/support/Register-Project.ps1) *(to be created)* — Mode A driver (and invoked from PF-TSK-059 for new projects)
- [Pending Migration Entry Template](../../templates/support/pending-migration-entry-template.md) *(to be created)* — Ledger entry structure (must include "Rollback Implications" field)
- [Framework Rollout Usage Guide](../../guides/support/framework-rollout-usage-guide.md) *(to be created)* — Customization patterns
- [Framework Rollout Context Map](../../visualization/context-maps/support/framework-rollout-map.md) *(to be created)* — Component relationships
- [Project Initiation (PF-TSK-059)](../00-setup/project-initiation-task.md) — Owns new-project registration; invokes Register-Project.ps1 as final step
- [Structure Change (PF-TSK-014)](structure-change-task.md) — Writes the `pending-migrations.md` entries this task applies (responsible for filling "Rollback Implications" field)
- [Framework Blueprint Sync (PF-TSK-087)](framework-blueprint-sync-task.md) — Predecessor task being deprecated (Phase 10 of the centralized-framework-management extension)
