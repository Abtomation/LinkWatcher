---
id: PF-TSK-088
type: Process Framework
category: Task Definition
version: 1.13
created: 2026-05-10
updated: 2026-08-10
description: "Deploy framework code from a producer face's canonical blueprint tree to its registered children."
use_when: >-
  Deploy framework code from a producer face's canonical blueprint tree to its registered children. Phase 1 (cwd=producer root): commit + tag the producer repo, push to its remote, mirror the payload-filtered framework tree to the targets. Phase 2 (cwd=Project): apply per-project working-doc migrations from the central pending-migrations ledger. Triggers: 'push framework to project X', 'roll out framework update', 'rollback framework version', 'register new project'.
triggers:
  - "push framework to project X"
  - "roll out framework update"
  - "rollback framework version"
  - "register new project"
automation: manual
scripts:
  - ../../scripts/file-creation/support/Register-Project.ps1
  - ../../scripts/file-creation/support/New-PendingMigration.ps1
  - ../../scripts/update/Update-PendingMigration.ps1
  - ../../scripts/rollout/Push-FrameworkUpdate.ps1
  - ../../scripts/rollout/Restore-FrameworkVersion.ps1
  - ../../scripts/rollout/Commit-SandboxBaseline.ps1
---

# Framework Rollout

> **▶ Execute this task under the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md).** This file holds only this task's specific content; the universal contract every task shares lives once in the protocol and is mandatory here.

## Purpose & Context

Deploy framework code from the producer face's canonical framework source tree (`paths.blueprint` → `paths.process_framework`) to its registered children, and apply per-project working-document migrations that accompany framework structural changes.

**Operating model**: improvements are authored canonically at the producer face, then **pushed** to its children (vendored copies are read-only there). This task is the deliberate forward-deployment step. It replaces the former project→blueprint reverse-sync model (the framework-blueprint-sync task, removed 2026-06-17).

**Scope**: covers mirroring the producer's framework source to registered children, project working-document migrations driven by `pending-migrations.md` ledgers, and the project-registration pre-step.

**Direction**: producer → children only. Reverse direction (child → producer) does not exist in this model — framework changes happen at the owning producer face.

## AI Agent Role

**Role**: Release Engineer
**Mindset**: Cautious, deterministic, recovery-first — every rollout must be cleanly rollback-able; every project state must be visible before, during, and after.
**Focus Areas**: Pre-flight verification, dry-run reasoning, atomic git tagging, registry consistency, recovery paths.
**Communication Style**: Surface what will change *before* it changes. Default to `-Check` first when human partner is unsure. Ask before any operation that crosses the producer → child boundary if pre-flight surfaces unexpected state (uncommitted changes, version mismatches, registry drift).

## Key Concepts

### Child Registry (durable)

Path: `<producer>/process-framework-central/<registry file>` — file name, collection key, and version-pin field are role-derived via `Get-ChildRegistryInfo` (P-10): `project-registry.json` at a framework face, `framework-registry.json` at FB.

Single source of truth for which children exist, where they live on disk, and their rollout state. Keyed by a stable mnemonic-derived child ID (`APP-NNN` under FWK-APP, P-14; rename-safe). Schema documented in [centralized-framework-management proposal §3.10](../../../process-framework-central/proposals/old/centralized-framework-management.md). All rollout decisions read from this file.

### Rollout Tag Convention

Each rollout to one or more children creates a git tag in the producer repo of the form `rollout-<YYYY-MM-DD-NNN>` (NNN is a same-day counter). The tag points to the producer commit containing the framework-source snapshot that was mirrored. The tag is the backup — no physical `.bak/` directory needed.

### Framework Version Files (per project)

Three single-line files written into `<project>/process-framework/` by every rollout:

- `.framework-version` — current rolled version (e.g., `2026-05-08-001`)
- `.framework-version-previous` — prior version, used as the cheap rollback signal by `Restore-FrameworkVersion.ps1`
- `.framework-central-pointer` — absolute path to the producer workspace root, consumed by project-side scripts that need to write to centralized state

### Pending Migrations Ledger (durable, per project)

Path: `<producer>/process-framework-central/<ledger dir>/<PROJECT-ID>/pending-migrations.md` (+ sibling `archive/pending-migrations-archive.md`); the ledger dir name is role-derived (`per-framework-migrations` at FB)

Ledger of project working-document changes that the bulk push (Phase 1) **cannot** apply because they touch project-specific data (e.g., adding a column to `feature-tracking.md`, restructuring `state-tracking/permanent/`). Created by [Structure Change (PF-TSK-014)](structure-change-task.md) when the change affects project working docs. Phase 2 of this task drains the ledger in cwd=Project sessions. The ledger holds the full Summary table (all entries, all statuses) plus the detail sections of **open** entries; resolving or skipping an entry relocates its detail section to the per-project archive (PF-IMP-983), where Mode D pre-flight reads the "Rollback Implications" reversal steps of non-backward-compatible entries.

> **🚨 Scope boundary — what migration entries are NOT for**: The ledger is **only** for changes to project files **outside** the rolled-out subtree (`<project>/doc/`, `<project>/test/`, `<project>/src/`, `<project>/CLAUDE.md`, etc.). Changes **inside** `blueprint/process-framework` itself — adding files, moving files within the subtree, deleting files, or moving files *out* of the subtree into `process-framework-central` — propagate automatically via the Mode B `robocopy /MIR` mirror at the next Push (the mirror adds new files, updates modified files, and orphan-deletes files no longer present in blueprint). Authors of intra-blueprint changes should **not** write migration entries for those — the mirror handles them. See the [Framework Rollout Usage Guide — When you do NOT need a migration entry](../../guides/support/framework-rollout-usage-guide.md#when-you-do-not-need-a-migration-entry) for the canonical scope-boundary table and worked examples.

### Rollout Log (durable)

Path: `<producer>/process-framework-central/rollouts/rollout-log.md`

Append-only history of every real rollout and rollback: timestamp, version tag, target project IDs, notable decisions. (Dry-run `-Check` previews are **not** recorded — they change nothing on any project.) Survives across sessions; used for rollback and audit.

## Operating Modes

This task has **four distinct sub-flows**, each with its own session boundary. Pick one per session — they are not chained.

| Mode | When | Script-enforced cwd | Session home | Driver Script |
|---|---|---|---|---|
| **A. Project Registration (Retrofit)** | Retrofitting an existing project, or declaring a producer face's own identity (`-Self`). **For NEW projects, registration AND the first push run as Phase A steps inside [Project Initiation (PF-TSK-059)](../00-setup/project-initiation-task.md) — not via this task.** | workspace root for `-Self` only (retrofit is parameter-driven) | producer | [Register-Project.ps1](../../scripts/file-creation/support/Register-Project.ps1) |
| **B. Phase 1 Rollout (Bulk Push)** | Coherent IMP batch ready to deploy | producer root (script refuses elsewhere) | producer | [Push-FrameworkUpdate.ps1](../../scripts/rollout/Push-FrameworkUpdate.ps1) |
| **C. Phase 2 Per-Project Migrations** | Project's pending-migrations ledger has open entries | — (no driver script) | Project | (manual; references migration entries) |
| **D. Rollback** | Recent rollout broke a project | producer root (script refuses elsewhere) | producer | [Restore-FrameworkVersion.ps1](../../scripts/rollout/Restore-FrameworkVersion.ps1) |

> **Script-enforced cwd** is what the driver mechanically refuses to run without; **Session home** is where the session belongs — a sequence/context constraint that binds even where no script checks it (each mode's "Run from" line carries the rationale). Mode C's Project home is just as mandatory as a script check, only enforced by sequence, not code.

> **🚨 NEVER COMBINE MODES IN ONE SESSION.** Each mode produces a distinct artifact set and audit trail.

## Context Requirements

- **Critical (Must Read):**

  - `<producer>/process-framework-central/<registry file>` — Authoritative child list (role-derived name); all routing decisions read from this file
  - [Framework Rollout Usage Guide](../../guides/support/framework-rollout-usage-guide.md) — Customization patterns for Push/Restore/Register invocations and dry-run interpretation
  - `<producer>/process-framework-central/rollouts/rollout-log.md` — Prior rollouts and their target project sets

- **Important (Load If Space):**

  - [Pending Migration Entry Template](../../templates/support/pending-migration-entry-template.md) — Structure of one entry in the per-project ledger
  - [Script Development Quick Reference](../../guides/support/script-development-quick-reference.md) — PowerShell execution patterns; **always check parameters with `Get-Help <script> -Parameter *` before running**
  - [Project Initiation (PF-TSK-059)](../00-setup/project-initiation-task.md) — For new projects, registration and the first push are Phase A steps of Project Initiation (run from its producer-face session). PF-TSK-088 Mode A handles only retrofit and the `-Self` workspace-identity declaration; Mode B owns all subsequent pushes.

- **Reference Only (Access When Needed):**

  - [Structure Change (PF-TSK-014)](structure-change-task.md) — The task that *writes* `pending-migrations.md` entries (this task *applies* them)
  - [Process Improvement (PF-TSK-009)](process-improvement-task.md) — Coordinated through the IMP batch that triggers Mode B

> **Historical context (post-migration archived; do not rely on as live references):**
>
> - Source proposal `appdev/process-framework-central/proposals/old/centralized-framework-management.md` (working draft v4) — the design doc that produced this task. Archived 2026-07-16 when the migration completed.
> - Extension state file `appdev/process-framework-central/state-tracking/temporary/old/temp-framework-extension-centralized-framework-management.md` — multi-phase implementation tracker. Archived 2026-07-16 when Phase 10 completed (all phases 0–10 done).

## Process

> **⚠️ MANDATORY: Pick exactly one operating mode (A/B/C/D) per session. Do not combine.**

---

### Mode A: Project Registration (Retrofit)

**Run from**: the producer face's cwd (appdev). A genuine retrofit target has no framework copy of its own yet, so registration runs from the producer face (the target project via `-Path`, the producer via `-ProducerPath "."`); the `-Self` identity declaration runs from the workspace's own root.

**Scope**: Mode A is **retrofit-only**. Use it when:
- Onboarding an existing project that pre-dates the framework's centralized model (existing `src/`, `doc/`, `test/` content; no `project_id` in `doc/project-config.json`).
- Declaring a producer face's own identity (run with `-Self -SelfId FWK-XXXX` from the workspace root). This writes config only — a producer face holds no self-row in its own child registry; its identity row lives in its **parent's** registry, hand-written (PF-PRO-068 P-13; the retired `-IsAppdev` bootstrap's PRJ-000 self-row was removed by the same change).

**Do NOT use Mode A for new projects.** New-project registration is a Phase A step inside [Project Initiation (PF-TSK-059)](../00-setup/project-initiation-task.md) — that task bootstraps the project, invokes Register-Project, and delivers the first push, all from one producer-face session. Treating new-project registration as a separate Mode A session creates a multi-session user flow with avoidable handover friction.

Mode A assigns a stable child ID minted from the producer mnemonic (APP-NNN under FWK-APP), adds the project to the registry, writes `project_id` into the project's `doc/project-config.json`. Does **not** roll out framework code — that happens in Mode B after registration.

#### Preparation

1. Confirm this is a retrofit (existing project pre-dating the framework, or a workspace identity declaration via `-Self`). For new projects, route to PF-TSK-059 instead.
2. Confirm the producer's central child registry exists and is well-formed.
3. Decide whether this registration is for an existing project (child ID minted from the producer mnemonic) or a workspace's own identity (`-Self -SelfId FWK-XXXX`, config-only write).

#### Execution

4. Run `Register-Project.ps1`:
   ```bash
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/support/Register-Project.ps1 -Path "<absolute-project-path>" -Name "<DisplayName>" -ProducerPath "." -Confirm:\$false
   ```

   For a producer face's own identity (config-only write; the registry row lives at the parent):
   ```bash
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/support/Register-Project.ps1 -Self -SelfId FWK-XXXX -Confirm:\$false
   ```

5. **Inspect script output**: confirm the assigned child ID, registry entry added, `project_id` written to `<project>/doc/project-config.json`.

6. **🚨 CHECKPOINT**: Present registration result to human partner before proceeding to first rollout (Mode B).

#### Finalization

7. Validate: `<project>/doc/project-config.json` `project_id` field matches the central registry entry.
8. Validate: registry's `current_framework_version` is `null` (no rollout yet) and `last_rollout` is `null` for retrofit. (A `-Self` run writes config only — validate `doc/project-config.json` `project_id` instead; there is no registry row to check.)
9. **🚨 MANDATORY FINAL STEP**: Complete the [Mode A Completion Checklist](#mode-a-completion-checklist) below.

---

### Mode B: Phase 1 Rollout (Bulk Push)

**Run from**: the producer workspace root cwd (`Push-FrameworkUpdate.ps1` refuses elsewhere; the IMP batch and the framework edit target live at the producer face).

**Per IMP batch.** Mirrors the producer's framework source tree (payload-filtered where a manifest exists) to one or more registered children. Single-session.

> **New-project first push is delegated**: the very first push to a freshly bootstrapped project runs as a [Project Initiation (PF-TSK-059)](../00-setup/project-initiation-task.md) Phase A step — same producer-face session that bootstrapped and registered it, scoped `-Project <PROJECT-ID>`, with an expected `0/0/0` content diff (the payload is version stamps, the central pointer, the rollout tag, and registry/log entries — 0/0/0 is the correct result, not a no-op signal). Mode B owns every subsequent push to that project. Retrofits (Mode A registrations) still take their first push here as a normal Mode B session.

#### Preparation

0. **Owner-review precondition (PF-PRO-059)**: if the workspace `CLAUDE.md` defines a **Standing Orders** section, confirm the owner review is current before anything ships — pending digests in `feedback/reviews/` newer than the `Last review:` stamp have been read, the 3–5 sampled deep-dives done, and the stamp updated. If digests are pending, the owner review happens first (it can open this same session); nothing ships unreviewed. *(Numbered 0 so Mode B's existing step numbers stay stable.)*
1. Confirm cwd is the producer workspace root (script will refuse otherwise).
2. Confirm the producer's framework source tree has the intended changes staged or committed (`git status` clean except for the rollout commit-to-be).
3. Decide rollout scope:
   - All eligible projects (omit `-Project`)
   - Canary subset: specify one or more `-Project <PROJECT-ID>` (substitute the actual ID, e.g., `-Project APP-001`)
4. Read the producer's `process-framework-central/rollouts/rollout-log.md` tail to confirm the previous rollout completed cleanly.
5. **MANDATORY DRY-RUN**: invoke with `-Check` first to surface what will change without writing files.

#### Execution

6. **Dry-run**:
   ```bash
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/rollout/Push-FrameworkUpdate.ps1 -Check -Confirm:\$false
   ```
   Optionally with `-Project <PROJECT-ID>` to scope dry-run to one project.

   **Pre-push self-test**: if the rollout touches framework scripts (`.ps1`/`.psm1` changed since the previous rollout version; on a first-ever push to a fresh bootstrap, that baseline is the bootstrap itself), run the self-test suite before the checkpoint — `pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/test/Run-Tests.ps1 -All` (or `-Category <area>` if localized). Re-run a handful of failures in isolation before judging the result: full-suite runs race concurrent sessions' state writes into false negatives, and the isolation result — not the raced full-suite count — is the checkpoint input. A non-clean result is a checkpoint go/no-go item, not an automatic block.

7. **🚨 CHECKPOINT**: Review dry-run output with human partner. Confirm:
   - Files reported as changed match expectations.
   - No unexpected projects are in scope (frozen projects should be skipped automatically).
   - Pre-flight passes (no uncommitted changes in the framework source tree unless `-Force`).
   - Self-test result reviewed if the rollout touched scripts.

8. **Real rollout**:
   ```bash
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/rollout/Push-FrameworkUpdate.ps1 -Confirm:\$false
   ```
   Or with `-Project <PROJECT-ID>` for canary.

9. The script:
   - Commits + tags the producer repo at `rollout-<YYYY-MM-DD-NNN>`.
   - Pushes commit + tag to the config-declared remote (`repository_url`) for off-machine durability.
   - Mirrors the payload-filtered framework source → each filtered target's `process-framework/`.
   - Writes/updates `.framework-version`, `.framework-version-previous`, `.framework-central-pointer` in each target project.
   - Appends entry to `rollout-log.md` recording target project IDs.
   - Updates the version-pin field and `last_rollout` for each target in the child registry.
   - Commits the central rollout state (child registry + `rollout-log.md`) as a second `rollout-meta: <version>` commit and pushes it to the remote, so the audit trail lands in version control at rollout time.

#### Finalization

10. Validate: `git tag` shows the new `rollout-*` tag in the producer repo.
11. Validate: the remote received the push (`git push origin main` and tag push exit code 0; warn-only if network failed but local commit + tag still applied).
12. Validate: each target project's `.framework-version` reads the new version.
13. Validate: `rollout-log.md` has the new entry.
14. **If APP-T01 was in scope**: refresh the sandbox baseline commit (see [Sandbox Baseline Maintenance](#sandbox-baseline-maintenance-app-t01-only) below).
15. **🚨 MANDATORY FINAL STEP**: Complete the [Mode B Completion Checklist](#mode-b-completion-checklist) below.

#### Sandbox Baseline Maintenance (APP-T01 only)

> **Scope**: This subsection applies **only when `APP-T01` (the appdev framework self-test sandbox at `FrameworkBuilder/sandboxes/appdev/PRJ-000/`) is among the projects targeted by the Push**. Skip entirely if APP-T01 was not in scope.

**Why**: The sandbox is the canonical E2E target for the Framework Self-Testing extension (PF-PRO-035). Its E2E tests reset between runs to a known baseline using `git checkout HEAD -- <path>` against the sandbox's own git repository (see [E2E Acceptance Test Execution (PF-TSK-070) §Sandbox Execution](../03-testing/e2e-acceptance-test-execution-task.md#sandbox-execution-app-t01-only)). If a Push lands new rolled-out content in the sandbox but the new content is **not** committed to `HEAD`, the next test reset would revert the rolled-out content and break tests that depend on it.

**The discipline**: every Push to APP-T01 must be followed by a baseline commit that captures the post-rollout state. Sandbox state is rollout-pipeline-owned — **no ad-hoc copies, no manual edits**. Every change to the sandbox flows through Push (and then through this baseline-commit step).

**SOP** — after a Push that targeted APP-T01 lands:

```bash
pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/rollout/Commit-SandboxBaseline.ps1 -Confirm:\$false
```

The script:
- Reads the sandbox row (derived key pattern) from the child registry (producer root found by an upward probe from the script's own location — runnable from any cwd).
- In the sandbox's own git repo: `git add -A` then `git commit -m "baseline: post-rollout v<framework-version>"`.
- Refuses to run if the sandbox working tree is clean (nothing to baseline — Push didn't actually change anything in APP-T01), unless `-Force`.
- Runs a **mid-test contamination check** — skipped on a genuine post-rollout, i.e. when `process-framework/.framework-version` is among the changed paths (a Push always bumps that stamp and no E2E test touches it; PF-IMP-1334). Otherwise, if any changed path overlaps a TE-E2E test's `mutates`/`creates` list in `sandbox-reset-registry.json`, the working tree was most likely captured mid-test rather than in a post-rollout pristine state, and it refuses (unless `-Force`) so a contaminated state isn't baselined.

After this step, the sandbox's `HEAD` reflects the post-rollout state, and the next E2E test reset cycle uses it as the canonical pristine baseline.

**Anti-pattern to avoid**: don't manually copy a single framework script from `appdev/blueprint/.../X.ps1` into `sandboxes/appdev/PRJ-000/process-framework/.../X.ps1` to "sync" a pending edit for E2E testing. This contaminates the sandbox state in ways the rollout/restore E2E tests (Phase 3.5 Tier C cases WF-006 / WF-NEW-B) cannot trust. To test a pending edit E2E, do a real Push to APP-T01 (commits + tags appdev — that's the cost) and then run `Commit-SandboxBaseline.ps1`.

---

### Mode C: Phase 2 Per-Project Migrations

**Run from**: `<project>` cwd (the project whose ledger has open entries). Project-cwd is mandatory: the project's own LinkWatcher catches edits in real-time, project-specific validation scripts run naturally, and the project's IDE workspace context auto-loads.

**Per project, when ledger has entries.** Applies migrations from `pending-migrations.md` against project working documents (`doc/feature-tracking.md`, `doc/state-tracking/permanent/*.md`, `test/test-tracking.md`, etc.).

> **🚨 BACKWARD-COMPATIBILITY DESIGN PRINCIPLE**: Mode C migrations should be designed to be **backward-compatible** with the prior framework version whenever possible — additive columns optional, new sections placed where prior version still parses cleanly, schema changes default to no-op for old code paths. This makes Mode D rollback safe by construction. When a migration *cannot* be backward-compatible (e.g., a column rename that breaks the prior schema), the migration entry MUST flag this in its "Rollback Implications" field, and Mode D will require manual project-side reversal before rollback (see Mode D warning).

#### Preparation

1. Read the producer's `process-framework-central/<ledger dir>/<PROJECT-ID>/pending-migrations.md`. Identify open entries.
2. For each open entry, read the linked Structure Change source (the task that wrote the entry) to understand the rationale and the entry's "Rollback Implications" field.
3. Confirm the project is on the framework version that introduced the migration entries (check `<project>/process-framework/.framework-version`).
4. **Re-verify each entry's assumed starting state against the live tree.** Entry content is an authoring-time snapshot — run its no-op/precondition checks and confirm its target files and layout assumptions against the project as it is now. Classify each entry: applies as written / no-op (mark Skipped with a note) / diverged (needs adaptation — resolve at the planning checkpoint, not mid-apply).
5. Plan which entries will be processed in this session (one entry per checkpoint is the safe pattern).
6. Save a pre-migration validation baseline: run `Validate-StateTracking.ps1 -SaveBaseline` against the project and note the printed baseline path — the finalization gate (Step 10) compares against it, so pre-existing validation debt doesn't block migration sign-off.

#### Execution

7. For each entry chosen for this session:
   - Apply the migration to the named project working document.
   - Verify the change matches the entry's expected outcome (entry should specify before/after state or schema).
   - Run any project-side validation referenced in the entry (e.g., `Validate-StateTracking.ps1`).
   - **🚨 CHECKPOINT** with human partner before marking the entry resolved.
   - Mark the entry resolved with [Update-PendingMigration.ps1](../../scripts/update/Update-PendingMigration.ps1) (PF-IMP-932) — it flips the Status in **both** the Summary-table row and the per-entry section in a single write, stamping the Resolved date and the Resolved By attribution, so the two Status sites stay in lockstep:
     ```bash
     pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/update/Update-PendingMigration.ps1 -Project <PROJECT-ID> -MigrationId MIG-NNN -ResolvedBy "<PROJECT-ID> Mode C <date> (<project-name>)" -Confirm:\$false
     ```
     For an entry that turns out not to apply to this project, use `-NewStatus Skipped` instead (no `-ResolvedBy` needed) — add `-SkipReason "<why / audit link>"` to record the rationale in the archived detail block. If the two Status sites were already inconsistent, the script reports the drift and repairs both. The same write also relocates the entry's detail section to the per-project archive (`<PROJECT-ID>/archive/pending-migrations-archive.md`, PF-IMP-983) — the ledger keeps the full Summary table plus open detail sections only.

   > **Test-suite / bulk-move entries**: when an entry relocates test code or many path-dense files, run the affected test suite before and after the moves (pass/fail baseline → regression run) and handle LinkWatcher deliberately — follow the [Test-Suite Migration Pattern](../../guides/support/framework-rollout-usage-guide.md#test-suite-migration-pattern-mode-c) in the usage guide. What LinkWatcher auto-updates during relocations vs. what needs manual handling: `<LinkWatcher install>/doc/user/handbooks/linkwatcher-capabilities-reference.md`; interpreting post-migration `--validate` output: `link-validation.md` alongside it (install default `%USERPROFILE%\bin`, override via `LINKWATCHER_INSTALL_DIR`).

8. If an entry surfaces unexpected divergence (project working doc has drifted from what the entry assumes), pause and ask the human partner — do **not** force the migration. Resolution options: adapt the entry in place (human-approved scope expansion), or route the gap upstream per the [Issue Classification and Routing Guide](../../guides/framework/issue-classification-and-routing-guide.md) — drifted structure becomes a new [Structure Change (PF-TSK-014)](structure-change-task.md) entry; a framework defect surfaced by the divergence is filed as an IMP. For reorg-shaped adaptations, Structure Change's move/split procedures provide the mechanics.

#### Finalization

9. Validate: applied entries are marked resolved with timestamp; remaining entries still open.
10. Validate: `Validate-StateTracking.ps1 -Baseline <pre-migration baseline path from Step 6>` against the project reports **no NEW errors** (pre-existing debt doesn't block sign-off; on a debt-free project this equals a clean pass).
11. **🚨 MANDATORY FINAL STEP**: Complete the [Mode C Completion Checklist](#mode-c-completion-checklist) below.

---

### Mode D: Rollback

**Run from**: the producer workspace root cwd (`Restore-FrameworkVersion.ps1` refuses elsewhere; rollback reads the producer's central registry, rollout log, and `rollout-*` git tags).

**Emergency.** Reverts a project's `process-framework/` to a previous version after a rollout broke it.

> **🚨 SCOPE WARNING — `doc/` AND `test/` ARE NOT REVERTED**: Mode D restores `<project>/process-framework/` from the producer's git tags. It does **NOT** touch `<project>/doc/` or `<project>/test/`. If recent Mode C migrations modified those directories, those changes remain in place after rollback. Two consequences:
>
> 1. **Backward-compatible Mode C migrations** (the design default — see Mode C principle): rollback is safe; the prior framework version still parses the post-migration working docs cleanly.
> 2. **Non-backward-compatible Mode C migrations** (flagged in the entry's "Rollback Implications" field): the operator MUST reverse the project working-doc changes manually via the project's git history (`git revert`, `git checkout` of specific files, or restoring from a project-side backup) **BEFORE** running Mode D — otherwise the rolled-back framework will read schema-mismatched working docs and produce errors.
>
> When in doubt, scan the ledger's Summary table (`pending-migrations.md`) for entries resolved between the rollback target version and the current version — the Backward-compatible column flags them; for any `no` entry, read its "Rollback Implications" reversal steps in the relocated detail section (`<PROJECT-ID>/archive/pending-migrations-archive.md`) and surface it to the human partner before proceeding.

#### Preparation

1. Identify the broken project's child ID.
2. Read the project's `<project>/process-framework/.framework-version-previous` — this is the rollback target by default.
3. (Optional) Identify a specific older version if the prior version is also broken: scan `rollout-log.md` for prior tags.
4. **Scan recent Mode C migrations**: read the Summary table of the project's `pending-migrations.md` ledger and identify entries resolved between the rollback target and the current version. For any row with Backward-compatible = `no`, read the entry's "Rollback Implications" reversal steps in the project's `archive/pending-migrations-archive.md` and flag it.
5. **🚨 CHECKPOINT** with human partner: confirm rollback is the right call (a failed migration may be fixable forward instead) AND confirm any non-backward-compatible Mode C migrations have been manually reversed in the project before proceeding.

#### Execution

6. Run `Restore-FrameworkVersion.ps1`:
   ```bash
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/rollout/Restore-FrameworkVersion.ps1 -Project <PROJECT-ID> -Confirm:\$false
   ```
   Or with `-ToVersion 2026-05-08-001` to rollback to a specific older version.

7. The script:
   - Reads the project's `.framework-version-previous` (or uses `-ToVersion` if specified) as the rollback target, and validates the corresponding `rollout-<YYYY-MM-DD-NNN>` tag exists.
   - Materializes the target version via `git worktree add --detach` into a temporary worktree at the tag — **the producer's main working tree is never touched**.
   - Mirrors the temp worktree's framework source → project's `process-framework` (robocopy `/MIR`, preserving per-project `.framework-version-previous` / `.framework-central-pointer`).
   - Writes per-project `.framework-version` (the target) and `.framework-version-previous` (the was-current version); refreshes `.framework-central-pointer`.
   - Removes the temporary worktree (in a `finally`, so it is cleaned up even on error).
   - Updates the central registry (version-pin field, `last_rollout`) and appends a ROLLBACK entry to `rollout-log.md`.
   - Commits the central state changes (child registry + `rollout-log.md`) as a `rollout-meta` commit and pushes to origin (warn-only on failure), unless central state is redirected outside the producer repo.

#### Finalization

8. Validate: target project's `.framework-version` matches the rollback target.
9. Validate: `rollout-log.md` has the rollback entry with reason note.
10. Validate: original failure mode is no longer reproduced in the target project.
11. **🚨 MANDATORY FINAL STEP**: Complete the [Mode D Completion Checklist](#mode-d-completion-checklist) below.

---

## Outputs

### Mode A Outputs

- **Updated** `<producer>/process-framework-central/<registry file>` — New child-ID entry with name, path, added date, freeze defaults.
- **Updated `<project>/doc/project-config.json`** — `project_id` field added/updated.
- **(For real projects only)** New `<project>/doc/state-tracking/PF-id-registry-local.json` provisioned with the project-local prefixes (`PF-STA`, `PF-TMP`) when absent — idempotent, preserving existing counters if the file already exists.
- **(For real projects only)** New `<producer>/process-framework-central/per-project-migrations/<PROJECT-ID>/` directory with empty `pending-migrations.md` skeleton.

### Mode B Outputs

- **New git tag in the producer repo** — `rollout-<YYYY-MM-DD-NNN>`.
- **New commit pushed to the config-declared remote** (`repository_url`).
- **Mirrored `<project>/process-framework/`** for each target project (every file replaced).
- **Updated `<project>/process-framework/.framework-version`** and `.framework-version-previous` and `.framework-central-pointer` for each target.
- **New entry in** `<producer>/process-framework-central/rollouts/rollout-log.md`.
- **Updated** `<producer>/process-framework-central/<registry file>` — `current_framework_version` and `last_rollout` for each target.

### Mode C Outputs

- **Modified project working documents** — exactly the files named in the resolved migration entries.
- **Updated `<producer>/process-framework-central/per-project-migrations/<PROJECT-ID>/pending-migrations.md`** — Summary rows marked resolved with timestamp; resolved/skipped detail sections relocated out.
- **Updated (or created) `<producer>/process-framework-central/per-project-migrations/<PROJECT-ID>/archive/pending-migrations-archive.md`** — receives the relocated detail sections (PF-IMP-983).

### Mode D Outputs

- **Reverted `<project>/process-framework/`** — files restored to the rollback target version.
- **Updated `<project>/process-framework/.framework-version`** and `.framework-version-previous`.
- **New rollback entry in** `<producer>/process-framework-central/rollouts/rollout-log.md` — clearly distinguishable from forward rollouts.

## State Tracking

The following state files are updated by this task (which file depends on which mode):

- `<producer>/process-framework-central/<registry file>` — Modes A, B (registry path resolved at session start via `<project>/process-framework/.framework-central-pointer` for project-side scripts, or directly from cwd for producer-side scripts)
- `<producer>/process-framework-central/rollouts/rollout-log.md` — Modes B, D
- Per-project `pending-migrations.md` ledger + `archive/pending-migrations-archive.md` — Mode C
- Per-project `<project>/process-framework/.framework-version` and `.framework-version-previous` — Modes B, D
- Per-project `<project>/doc/project-config.json` — Mode A

> **No temp state file required.** Each mode is single-session by design. Cross-session continuity lives in the durable artifacts above (registry, rollout log, pending-migrations ledger).

## ⚠️ MANDATORY Task Completion Checklist

> Completion discipline, output verification, and the feedback form are governed by the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md) (Phase C). The items below are the **task-specific** verifications that plug into it.

> Use the checklist matching the operating mode for this session.

### Mode A Completion Checklist

- [ ] **Registration verified**:
  - [ ] Child ID assigned and shown in `Register-Project.ps1` output
  - [ ] `<producer>/process-framework-central/<registry file>` contains the new entry
  - [ ] `<project>/doc/project-config.json` `project_id` field matches registry
  - [ ] (For real projects) `<project>/doc/state-tracking/PF-id-registry-local.json` provisioned with `PF-STA`/`PF-TMP` prefixes
  - [ ] (For real projects) `<producer>/process-framework-central/per-project-migrations/<PROJECT-ID>/` directory created with empty ledger
- [ ] **Checkpoint with human partner** completed before any subsequent rollout
- [ ] **Feedback form** completed per the [Task Execution Protocol → Feedback step](../../guides/framework/task-execution-protocol-guide.md#feedback-step) — task ID `PF-TSK-088`, context "Framework Rollout (Mode A: Project Registration)".

### Mode B Completion Checklist

- [ ] **Pre-flight passed**:
  - [ ] **Owner review current (PF-PRO-059)**: where the workspace defines Standing Orders, pending digests were reviewed and the `Last review:` stamp updated before the push (Step 0)
  - [ ] cwd was the producer workspace root
  - [ ] No uncommitted changes in the framework source tree (or `-Force` was explicitly chosen with rationale)
  - [ ] Dry-run output reviewed and approved by human partner
  - [ ] If the rollout touched framework scripts (`.ps1`/`.psm1`), the self-test suite was run and its result reviewed at the checkpoint
- [ ] **Rollout completed**:
  - [ ] Git tag `rollout-<version>` exists in the producer repo
  - [ ] GitHub remote received commit + tag (or warning logged with rationale if network failed)
  - [ ] Each target project's `.framework-version` matches the new version
  - [ ] `<producer>/process-framework-central/rollouts/rollout-log.md` has the new entry
  - [ ] `<producer>/process-framework-central/<registry file>` shows updated `current_framework_version` and `last_rollout` per target
  - [ ] **Central rollout state committed**: `project-registry.json` + `rollout-log.md` landed as the `rollout-meta: <version>` commit (Push does this automatically; verify with `git log --oneline -2`)
- [ ] **Frozen projects verified skipped** (if any are in registry with `version_freeze: true`)
- [ ] **If APP-T01 was in scope**: `Commit-SandboxBaseline.ps1` was run and produced a new baseline commit in `sandboxes/appdev/PRJ-000/`. See [Sandbox Baseline Maintenance](#sandbox-baseline-maintenance-app-t01-only).
- [ ] **Feedback form** completed per the [Task Execution Protocol → Feedback step](../../guides/framework/task-execution-protocol-guide.md#feedback-step) — task ID `PF-TSK-088`, context "Framework Rollout (Mode B: Phase 1 Bulk Push)".

### Mode C Completion Checklist

- [ ] **Migration entries processed**:
  - [ ] Each entry chosen for this session is marked resolved (or skipped) via [Update-PendingMigration.ps1](../../scripts/update/Update-PendingMigration.ps1), so the Summary row and per-entry Status stay in lockstep and the detail section lands in `archive/pending-migrations-archive.md`
  - [ ] Project working documents reflect the migration outcomes
  - [ ] No entry was force-applied past unexpected divergence (any divergence escalated to human partner)
- [ ] **Project validation passes**:
  - [ ] `Validate-StateTracking.ps1 -Baseline <pre-migration baseline path>` reports no NEW errors vs the pre-migration baseline (equals a clean pass on a debt-free project)
  - [ ] [`run_linkwatcher_validate.ps1`](../../tools/linkWatcher/run_linkwatcher_validate.ps1) — LinkWatcher broken-link scan (exit 1 on any broken link); confirm no NEW broken links in the printed report (no baseline mode — judge pre-existing link debt from the report)
  - [ ] Any migration-specific validation referenced in entries succeeded
- [ ] **Remaining entries clearly visible** in `pending-migrations.md` for the next Mode C session
- [ ] **Feedback form** completed per the [Task Execution Protocol → Feedback step](../../guides/framework/task-execution-protocol-guide.md#feedback-step) — task ID `PF-TSK-088`, context "Framework Rollout (Mode C: Per-Project Migrations)".

### Mode D Completion Checklist

- [ ] **Recent Mode C migrations scanned**: `pending-migrations.md` Summary rows between rollback target and current version reviewed; "Rollback Implications" of Backward-compatible=`no` entries read from `archive/pending-migrations-archive.md`
- [ ] **Non-backward-compatible Mode C migrations reversed**: any flagged entries have been manually reverted in the project's `doc/` or `test/` BEFORE rollback (or human partner explicitly accepted schema-mismatched state)
- [ ] **Rollback target confirmed** with human partner before execution
- [ ] **Rollback completed**:
  - [ ] Target project's `.framework-version` matches the rollback target
  - [ ] Target project's `.framework-version-previous` updated correctly
  - [ ] `<producer>/process-framework-central/rollouts/rollout-log.md` has the rollback entry
  - [ ] **Central rollback state committed**: `project-registry.json` + `rollout-log.md` landed as the `rollout-meta: rollback <project> to <version>` commit (Restore does this automatically)
  - [ ] Original failure mode is no longer reproduced
- [ ] **Temporary rollback worktree removed** — no `.rollback-worktree-*` directory remains in the producer repo (the script removes it in a `finally`; the producer's main working tree is never moved)
- [ ] **Forward-fix path identified** (so the rolled-back project gets back onto a healthy version eventually)
- [ ] **Feedback form** completed per the [Task Execution Protocol → Feedback step](../../guides/framework/task-execution-protocol-guide.md#feedback-step) — task ID `PF-TSK-088`, context "Framework Rollout (Mode D: Rollback)".

## File Operations

> Mode letters A–D refer to this task's Operating Modes. `process-framework-central` paths are producer-face-only; `<project>/` paths are written into each registered target project.

| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Updates** | `process-framework-central/project-registry.json` | `Register-Project.ps1` (A); `Push-FrameworkUpdate.ps1` (B) | A: new child-ID entry; B: `current_framework_version` + `last_rollout` per target |
| **Updates** | `<project>/doc/project-config.json` | `Register-Project.ps1` (A) | Adds/updates the `project_id` field |
| **Creates** | `process-framework-central/per-project-migrations/<PROJECT-ID>/pending-migrations.md` | `Register-Project.ps1` (A) | Empty ledger skeleton (real projects only) |
| **Creates** | producer-repo git tag `rollout-<YYYY-MM-DD-NNN>` (+ commit pushed to the config-declared remote) | `Push-FrameworkUpdate.ps1` (B) | Rollout snapshot tag = the rollback target |
| **Replaces** | `<project>/process-framework/` (entire tree) | `Push-FrameworkUpdate.ps1` (B) | Mirrors the canonical framework into each target |
| **Updates** | `<project>/process-framework/.framework-version`, `.framework-version-previous`, `.framework-central-pointer` | `Push-FrameworkUpdate.ps1` (B); `Restore-FrameworkVersion.ps1` (D) | Version-stamp + central-pointer files per target |
| **Updates** | `process-framework-central/rollouts/rollout-log.md` | `Push-FrameworkUpdate.ps1` (B); `Restore-FrameworkVersion.ps1` (D) | New rollout (B) or rollback (D) entry |
| **Updates** | project working documents named in the resolved migration entries | manual (C) | Exactly the files listed in the ledger entries |
| **Updates** | `process-framework-central/per-project-migrations/<PROJECT-ID>/pending-migrations.md` + `archive/pending-migrations-archive.md` | `Update-PendingMigration.ps1` (C) | Marks entries resolved; relocates detail blocks to the archive |
| **Reverts** | `<project>/process-framework/` to the prior version | `Restore-FrameworkVersion.ps1` (D) | Restores to `.framework-version-previous` |

## Next Tasks

- **Mode A → Mode B**: After registering a new project, the first rollout to that project (Mode B with `-Project <PROJECT-ID>`) deploys the framework code.
- **Mode B → Mode C**: After a rollout that includes structural migrations, project-side Mode C sessions (one per affected project) drain the `pending-migrations.md` ledgers.
- **Mode B → Mode D**: If a rollout breaks a project, Mode D rolls it back; a forward-fix to the broken framework version follows at the producer face, then a new Mode B re-deploys.
- **Mode C → no specific next**: Migration sessions are tail-end; each one is self-contained.
- **Trigger upstream**: [Process Improvement (PF-TSK-009)](process-improvement-task.md) and [Structure Change (PF-TSK-014)](structure-change-task.md) are the upstream IMP-batch sources that motivate Mode B sessions.

## Related Resources

- [Push-FrameworkUpdate.ps1](../../scripts/rollout/Push-FrameworkUpdate.ps1) — Mode B driver
- [Restore-FrameworkVersion.ps1](../../scripts/rollout/Restore-FrameworkVersion.ps1) — Mode D driver
- [Register-Project.ps1](../../scripts/file-creation/support/Register-Project.ps1) — Mode A driver (and invoked from PF-TSK-059 for new projects)
- [Pending Migration Entry Template](../../templates/support/pending-migration-entry-template.md) — Ledger entry structure (must include "Rollback Implications" field)
- [Framework Rollout Usage Guide](../../guides/support/framework-rollout-usage-guide.md) — Customization patterns and mode/component diagrams
- [Project Initiation (PF-TSK-059)](../00-setup/project-initiation-task.md) — Owns new-project registration and the delegated first push (its Phase A, producer-face session)
- [Structure Change (PF-TSK-014)](structure-change-task.md) — Writes the `pending-migrations.md` entries this task applies (responsible for filling "Rollback Implications" field)
