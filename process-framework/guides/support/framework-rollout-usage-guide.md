---
id: PF-GDE-066
type: Process Framework
category: Guide
version: 1.0
created: 2026-05-10
updated: 2026-05-10
related_script: process-framework/scripts/file-creation/support/Register-Project.ps1
related_task: PF-TSK-088, PF-TSK-014, PF-TSK-059
description: "Customization and usage patterns for Framework Rollout (PF-TSK-088): Push/Restore/Register script invocations, dry-run interpretation, partial-rollout recovery, frozen-project handling, and Pending Migration Entry Template usage by Structure Change task authors."
---

# Framework Rollout Usage Guide

## Overview

Practical patterns for working with the [Framework Rollout Task (PF-TSK-088)](../../tasks/support/framework-rollout-task.md) and its three driver scripts:

- `Register-Project.ps1` — assigns PRJ-NNN, registers a project (Mode A retrofit, or invoked from PF-TSK-059 for new projects)
- `appdev/process-framework-central/scripts/Push-FrameworkUpdate.ps1` — Mode B bulk-push driver
- `appdev/process-framework-central/scripts/Restore-FrameworkVersion.ps1` — Mode D rollback driver

> **🚨 NOT a re-explanation of PF-TSK-088.** The task definition is authoritative for *what* and *when*. This guide covers *how to work effectively with the script outputs*: dry-run interpretation, recovery from partial state, customization patterns for the [Pending Migration Entry Template (PF-TEM-079)](../../templates/support/pending-migration-entry-template.md) when Structure Change writes entries, and the most common operational pitfalls. If you need workflow guidance, read the task definition.

## When to Use

- **Before every Mode B (Push) session**: read [Dry-Run Interpretation](#dry-run-interpretation) so the agent and human partner share a vocabulary for what the diff output means.
- **When authoring a `pending-migrations.md` entry** as part of [Structure Change (PF-TSK-014)](../../tasks/support/structure-change-task.md): read [Authoring Pending Migration Entries](#authoring-pending-migration-entries) for the Rollback Implications field semantics.
- **When a Push fails partway** (one project mirrored, another errored): read [Partial-Rollout Recovery](#partial-rollout-recovery).
- **When a project is in the registry but should not receive rollouts** (release freeze, vendor handoff, archival): read [Frozen Projects](#frozen-projects).
- **When a Mode D rollback is being considered**: read [Rollback Decision Patterns](#rollback-decision-patterns) before invoking `Restore-FrameworkVersion.ps1` — sometimes a forward-fix is the right call instead.

## Prerequisites

- The agent has the [Framework Rollout Task (PF-TSK-088)](../../tasks/support/framework-rollout-task.md) loaded as critical context.
- `appdev/` is a git repository with origin remote `https://github.com/Abtomation/framework-appdev.git`.
- `appdev/process-framework-central/project-registry.json` exists and is well-formed.

## Background

The Rollout system has **three durable artifacts** the agent reads before every operation, and **three per-project files** the scripts maintain in each rolled-out project:

**Durable artifacts in appdev (read at session start):**

| Artifact | Purpose |
|---|---|
| `project-registry.json` | Source of truth for which projects exist, their paths, freeze state, last-rollout timestamp |
| `rollout-log.md` | Append-only audit trail of every rollout (forward + rollback) |
| `per-project-migrations/<PRJ-NNN>/pending-migrations.md` | Per-project ledger of working-doc migrations that Structure Change has queued |

**Per-project files (written by Push, read by Restore):**

| File | Purpose |
|---|---|
| `<project>/process-framework/.framework-version` | Records which appdev version this project is currently running |
| `<project>/process-framework/.framework-version-previous` | Default rollback target (the version installed BEFORE the most recent Push) |
| `<project>/process-framework/.framework-central-pointer` | Absolute path to appdev (consumed by project-side scripts that write to centralized state) |

The git tag `rollout-<YYYY-MM-DD-NNN>` in appdev is the canonical snapshot for any version. `Restore-FrameworkVersion.ps1` resolves the tag via `git worktree add --detach` to materialize the target version without disturbing appdev's main working tree.

## Dry-Run Interpretation

`Push-FrameworkUpdate.ps1 -Check` is **mandatory** before any real Mode B rollout. The output has three sections; here's how to read each.

### Pre-flight block

```
═══ Framework Rollout — Pre-flight ═══
  Mode             : DRY-RUN (-Check)
  appdev root      : C:\Users\ronny\VS_Code\FrameworkBuilder\appdev
  Working tree     : clean
  Origin remote    : https://github.com/Abtomation/framework-appdev.git
  Current version  : 2026-05-12-001
  Next version     : 2026-05-13-001
  Target projects  : PRJ-001, PRJ-002
```

**What to verify:**

- **Working tree** — should be `clean`. If `dirty`, the Push will refuse unless `-Force`. Investigate: are there in-progress framework edits that should be committed first? Or stale state from a half-completed prior session?
- **Origin remote** — should match the expected GitHub URL exactly. A mismatch is rare but indicates either renamed remote or wrong appdev clone.
- **Current version vs Next version** — confirm the version-bump matches expectation. Same-day re-rollouts increment NNN (e.g., `2026-05-13-001` → `2026-05-13-002`); new days reset to `001`.
- **Target projects** — should match what the human partner asked for. Frozen projects auto-skip; if a frozen project is mentioned in the human's request, the script will warn but still skip it. Re-reading the registry for `version_freeze: true` is part of pre-flight verification.

### Per-project diff block

```
═══ Per-Project Diff ═══
  PRJ-001 (LinkWatcher): added=3 modified=18 deleted=1
    Sample added   : tasks/support/imp-triage-task.md, scripts/update/Apply-Migration-MIG-002.ps1
    Sample modified: ai-tasks.md, PF-documentation-map.md, tasks/support/process-improvement-task.md
    Sample deleted : guides/old/blueprint-sync-consideration-policy-guide.md
  PRJ-002 (ExampleProject): added=3 modified=18 deleted=1
    Sample added   : tasks/support/imp-triage-task.md, ...
```

**What to verify:**

- **Counts match expectation** — if the IMP batch you're rolling out claimed to add 3 new tasks but the diff shows added=12, something else is going on. Investigate before proceeding.
- **Sample paths look right** — top-of-list samples are usually the most prominent additions/modifications. Glaringly project-specific paths in the modified list (e.g., `feature-tracking.md`, `bug-tracking.md`) signal that LinkWatcher in appdev edited project-state files that should NOT be in `process-framework/` — investigate before proceeding.
- **Deleted samples** — most rollouts have 0 deletions. A deletion typically means a framework artifact was removed in this batch (e.g., deprecated guide). Confirm the deletion is intentional.
- **PRJ-001 vs PRJ-002 counts differ wildly** — usually means one project drifted from canonical (someone hand-edited `<project>/process-framework/`). The drift will be wiped by the Push (since /MIR mirrors). If the drift contains valuable work, capture it via Structure Change → IMP first.

### Identical-output across projects

For all-projects rollouts, every project's diff should be **identical** unless a project was at a different starting version. If counts differ, you likely have either:
- A project at a different starting version (compare `.framework-version` per project)
- A project with hand-edits in `<project>/process-framework/` (drift)

## When you do NOT need a migration entry

Pending migration entries exist for **one** purpose: changes to project files **outside** the rolled-out subtree (`<project>/doc/`, `<project>/test/`, `<project>/src/`, `<project>/CLAUDE.md`, project-config.json schema bumps, etc.). Mode B's `robocopy /MIR` mirror does not touch those — they need Mode C sessions in each affected project to apply.

**Inside** `blueprint/process-framework/`, the mirror handles everything for you. Authors of intra-blueprint changes routinely overestimate the work needed; the table below is the canonical "is this me?" reference.

| Change shape (intra-blueprint) | Migration entry needed? | How it propagates |
|---|---|---|
| Move a file *within* `blueprint/process-framework/` | **No** | `/MIR` copies new path, deletes old |
| Add a new file inside `blueprint/process-framework/` | **No** | `/MIR` copies it to every project |
| Delete a file from `blueprint/process-framework/` | **No** | `/MIR` orphan-removes it from every project |
| Rename a file inside `blueprint/process-framework/` | **No** | `/MIR` treats as delete-old + add-new |
| Move a file *out of* `blueprint/process-framework/` into `process-framework-central/` | **No** | `/MIR` orphan-removes the blueprint side; central side is per-appdev only and was never rolled out |
| Change script behavior inside `blueprint/process-framework/scripts/` | **No** | `/MIR` updates the file in every project |
| Restructure sections inside a framework doc (`tasks/`, `guides/`, `templates/`) | **No** | `/MIR` updates the file in every project |

| Change shape (project working-tree) | Migration entry needed? | How it propagates |
|---|---|---|
| Add / rename / remove a column in `<project>/doc/state-tracking/permanent/feature-tracking.md` | **Yes** | Mode C session in each project applies the edit |
| Add a new section to `<project>/CLAUDE.md` template | **Yes** (if modifying existing projects' `CLAUDE.md`) | Mode C session |
| Restructure `<project>/doc/state-tracking/permanent/` layout | **Yes** | Mode C session |
| Bump schema in `<project>/doc/project-config.json` | **Yes** | Mode C session |
| Add / rename a tracking file in `<project>/test/` | **Yes** | Mode C session |

### Worked example: "I moved a script from `blueprint/process-framework/scripts/` to `process-framework-central/scripts/`. Do I need a migration entry?"

**No.** The mirror handles three pieces independently:

1. The blueprint-side script file gets orphan-removed from every project at the next Push (the source no longer contains it).
2. The new central-side script lives only in `process-framework-central/`, which is per-appdev and is **never** copied to projects (per Centralized Framework Management §3.1).
3. Any callers that referenced the script via its blueprint path need their paths updated — but those edits also live inside `blueprint/process-framework/`, so they too propagate via the mirror.

### Worked example: "I changed a script's behavior. Do I need a migration entry?"

**No.** The mirror replaces the file content in every project. Script behavior changes propagate automatically. Migration entries are about **project-side data structure** (where the projects own the canonical data), not about framework code behavior.

### When in doubt

Ask: "Does the change require a per-project edit to a file the projects own, that the mirror won't touch?" If yes → write an entry. If no → no entry needed.

## Authoring Pending Migration Entries

When [Structure Change (PF-TSK-014)](../../tasks/support/structure-change-task.md) needs to enqueue project working-doc edits, it writes entries into each affected project's `pending-migrations.md` using the [Pending Migration Entry Template (PF-TEM-079)](../../templates/support/pending-migration-entry-template.md). The most-mistake-prone field is **Rollback Implications** — get it right at write time so Mode D's pre-flight scan can be trusted.

### Rollback Implications: yes vs no

The decision tree:

```
Will the prior framework version's parsers / scripts / validators
correctly read the post-migration working docs?

├─ YES, no errors, no missed data    → Backward-compatible: yes
├─ NO, parser errors / missed data   → Backward-compatible: no
└─ UNSURE                            → Choose `no`. Over-cautious is safer.
```

### Examples (verified through this guide)

**Backward-compatible: yes**

| Migration | Why |
|---|---|
| Add an OPTIONAL new column to `feature-tracking.md` with sensible default | Prior parser ignores unknown columns; new column is read-only-additive |
| Append a new SECTION to `state-tracking/permanent/architecture-tracking.md` | Prior parser doesn't reach the new section; existing sections unchanged |
| Add a new ROW to `feature-request-tracking.md` for a backfilled request | Row addition is the parser's normal expansion path |

**Backward-compatible: no**

| Migration | Why |
|---|---|
| Rename column `state` → `status` in `feature-tracking.md` | Prior `Validate-StateTracking.ps1` reads `state` and errors on missing column |
| Change a YAML frontmatter field's required schema (e.g., `version: int` → `version: semver-string`) | Prior schema validator rejects the new format |
| Restructure `state-tracking/permanent/feature-tracking.md` from one master table into per-feature subsections | Prior parser expects the master-table format; restructure breaks read path |

### Required-reversal-steps wording (when `no`)

When `no`, the entry MUST list concrete commands. Bad: "revert manually". Good: structured steps like:

```markdown
**Required reversal steps before Mode D rollback**:

1. From <project> cwd: `git log --oneline doc/state-tracking/permanent/feature-tracking.md` to find the migration commit hash (it should be the most recent change touching that file authored by this Mode C session).
2. `git revert <hash> -- doc/state-tracking/permanent/feature-tracking.md` (revert just the column-rename change).
3. Run prior framework version's `Validate-StateTracking.ps1` to confirm it parses without error.
4. Commit the revert with message "revert: undo MIG-NNN before Mode D rollback to <prior-version>".
```

If the entry author can't write concrete steps, that's a **strong signal that the migration shouldn't be backward-incompatible in the first place** — refactor the migration to be additive instead, or split it into a forward-only step (current rollout) plus a forward-only deprecation (later rollout when no project remains on the old version).

## Partial-Rollout Recovery

`Push-FrameworkUpdate.ps1` continues past per-project errors (it doesn't abort the whole batch on one project's failure). The output's tail looks like:

```
═══ Rollout Complete ═══
  Version       : 2026-05-13-001
  Succeeded     : 1 project(s) — PRJ-001
  Failed        : 1 project(s) — PRJ-002
  Recovery      : the git tag rollout-2026-05-13-001 is durable; failed projects can be re-rolled by re-running with -Project <id>.
```

### What to do (in order)

1. **Inspect the failure cause** — `Push-FrameworkUpdate.ps1` writes the per-project error to stderr in the moment it occurs. The most common causes are:
   - **Robocopy permissions error** — the project's `process-framework/` is read-locked by an editor or running process. Resolution: close the project's IDE, kill any LinkWatcher process touching that path, retry.
   - **Path doesn't exist** — registry has a stale path (project moved on disk). Resolution: hand-edit `project-registry.json` to fix the path, then retry.
   - **Disk full** — verify, free space, retry.

2. **Verify the GIT TAG IS DURABLE** — `git tag -l rollout-<version>` should show the tag. If yes, the snapshot is preserved; you can retry the failing projects without re-creating the version.

3. **Re-run the Push for the failed projects only** — `Push-FrameworkUpdate.ps1 -Project <PRJ-NNN>` (one or more failed). The script will detect that the appdev tag already exists (it'll be at the current commit), skip the commit/tag step, and just re-run the per-project mirror.

   > ⚠️ **Edge case**: If the underlying issue was that appdev's working tree got modified between the partial-rollout and the retry, the version computation may produce a NEW version (`2026-05-13-002`) instead of re-using `2026-05-13-001`. This means the failed project will receive a *different* version than the succeeded project. To avoid this, do not commit anything to appdev's `process-framework/` between the partial rollout and its retry.

4. **Check the rollout-log.md** — the partial rollout's log entry will list both succeeded and failed targets in the Note. If you re-ran successfully, append a brief follow-up note to the log (manually) recording the recovery.

## Frozen Projects

A project with `version_freeze: true` in `project-registry.json` is excluded from rollouts. Use cases:

- **Vendor handoff** — the project is being delivered to a customer who'll maintain their own framework copy; you don't want to keep updating it.
- **Release freeze** — the project is in a release-stabilization window and shouldn't receive framework changes.
- **Archival** — the project is no longer maintained but you want to keep its registry entry for historical accuracy.

### Freeze workflow

There's no script for freeze toggling — it's a direct edit to `project-registry.json`. Convention:

```json
"PRJ-002": {
  ...
  "version_freeze": true,
  "frozen_at_version": "2026-05-13-001",
  "notes": "Frozen 2026-05-15 for v2 release window. Thaw target: 2026-06-01."
}
```

`frozen_at_version` records the version at the time of freeze (audit trail). When un-freezing later:

1. Set `version_freeze: false`.
2. Leave `frozen_at_version` populated (audit trail of "this project was frozen at X").
3. Run a Push targeting the project explicitly (`-Project <PRJ-NNN>`) to bring it back up to current.

### What `Push-FrameworkUpdate.ps1` does for frozen projects

- **No `-Project` filter**: silently skipped (no log entry — they're not in the eligible set).
- **With `-Project <frozen-id>`**: warning emitted ("Project X is frozen ... Skipping despite explicit -Project request"); other named projects still proceed.

## Rollback Decision Patterns

`Restore-FrameworkVersion.ps1` is the rollback hammer; before reaching for it, evaluate whether a forward-fix is appropriate.

### Use Mode D (rollback) when:

- The new framework version produced an error that **blocks ongoing project work** (CI broken, validation script erroring, agent unable to load critical context).
- A bug was just introduced that affects multiple projects (rolling back is faster than fixing forward across all of them).
- The window is short (<24h since rollout) — minimal Mode C migrations to reverse.

### Forward-fix instead when:

- The new framework version has a **non-blocking** issue (e.g., a script's UX is worse but still works).
- Mode C migrations have already been applied and are non-backward-compatible (the Mode D scope warning forces manual project reversal — slower than forward-fix).
- The fix is small and obvious (single-line change in a script). Forward-fix becomes the next rollout's content.
- Multiple projects are affected and rolling back would unwind too much accumulated state.

### When in doubt: rollback ONE project as a test

`Restore-FrameworkVersion.ps1 -Project <PRJ-001>` rolls back just one. If the original failure is no longer reproduced, you have evidence that the framework change was the cause. Then decide: continue rolling back others, or forward-fix and re-Push.

## Examples

### Example 1: First-ever rollout (post Phase 4.5 + Phase 6)

```bash
# From cwd=appdev:
pwsh.exe -ExecutionPolicy Bypass -File process-framework-central/scripts/Push-FrameworkUpdate.ps1 -Check
```

Expected dry-run output (first rollout):
- `Current version: (none — first rollout)`
- `Next version: 2026-05-15-001` (or whatever today's date is)
- Per-project: every file shown as `added` (huge counts because the project's `process-framework/` was empty pre-rollout — wait, PRJ-001 and PRJ-002 already have framework code from PF-TSK-087 era, so it'll be `modified` for most files plus a few `added` and `deleted`)

Then real run:
```bash
pwsh.exe -ExecutionPolicy Bypass -File process-framework-central/scripts/Push-FrameworkUpdate.ps1 -Confirm:$false
```

### Example 2: Canary to one project

```bash
# Roll out only to PRJ-002 (canary):
pwsh.exe -ExecutionPolicy Bypass -File process-framework-central/scripts/Push-FrameworkUpdate.ps1 -Project PRJ-002 -Check
```

After verifying canary is stable for a few sessions, promote globally:

```bash
# All eligible projects:
pwsh.exe -ExecutionPolicy Bypass -File process-framework-central/scripts/Push-FrameworkUpdate.ps1
```

The version computed will be a NEW version (different tag) because the canary's tag and content differ from the global state at the time of promotion (assuming any further appdev commits happened between canary and global).

### Example 3: Rollback after a bad Push

```bash
# Roll PRJ-002 back to its prior version:
pwsh.exe -ExecutionPolicy Bypass -File process-framework-central/scripts/Restore-FrameworkVersion.ps1 -Project PRJ-002
```

### Example 4: Retrofit registration

For a project being onboarded to the framework's centralized model:

```bash
# From cwd=appdev:
pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/support/Register-Project.ps1 -Path "C:/path/to/SomeProject" -Name "SomeProject" -AppdevPath "." -WhatIf
```

Then real:

```bash
pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/support/Register-Project.ps1 -Path "C:/path/to/SomeProject" -Name "SomeProject" -AppdevPath "." -Confirm:\$false
```

After registration: the next Push (with `-Project <new-PRJ-NNN>`) deploys the framework to the project for the first time.

## Troubleshooting

### Push refuses with "appdev/process-framework/ has uncommitted changes"

**Cause:** Edits were made to `process-framework/` in appdev that weren't committed. The script refuses by default to prevent silently committing in-progress work.

**Solution:** Commit the changes (or stash them deliberately if not part of this rollout). Then re-run Push.

If the changes are unintentional or were left over from a prior session: investigate (`git diff process-framework/`) before discarding — they may represent IMPs in flight.

### "Tag rollout-<version> does not exist in appdev" during Restore

**Cause:** Either the version is wrong, or the tag was never pushed to this clone of appdev (someone else pushed it from another machine).

**Solution:** Try `git fetch --tags` from cwd=appdev to pull tags from origin. Re-run Restore.

If the tag truly doesn't exist anywhere: the rollback target is unrecoverable. Either:
- Pick an older version that does have a tag (use `-ToVersion`)
- Forward-fix instead

### Restore reports "Project's .framework-version-previous is empty"

**Cause:** The project has only had one Push (so there's no "previous" — only the current version exists).

**Solution:** Specify `-ToVersion` explicitly. The legitimate target is then "no framework" — which means deletion of `<project>/process-framework/`, which Restore doesn't do. In practice: a single-Push project that broke means you need to either forward-fix in appdev and re-Push, or unregister and re-Initialize the project.

### Robocopy partial copy with exit code 2 or 3

**Symptom:** Push reports success but some files weren't copied. Robocopy exit codes 0-7 are non-fatal; the script accepts ≤7 as success.

**Cause:** Most commonly: a file in the destination was open/locked when robocopy tried to overwrite it (text editor, IDE, antivirus scan).

**Solution:** Close any open editors on the project. Re-run `Push-FrameworkUpdate.ps1 -Project <PRJ-NNN>` to retry just that project — robocopy /MIR will catch up.

### "Cannot validate argument on parameter 'ToVersion'" (Restore)

**Symptom:** Parameter binding error before any operation.

**Cause:** `-ToVersion` value doesn't match `YYYY-MM-DD-NNN` format.

**Solution:** Check `appdev/process-framework-central/rollouts/rollout-log.md` for the correct version string of a prior rollout.

## Related Resources

- [Framework Rollout Task (PF-TSK-088)](../../tasks/support/framework-rollout-task.md) — Authoritative task definition
- [Pending Migration Entry Template (PF-TEM-079)](../../templates/support/pending-migration-entry-template.md) — Per-entry structure
- [Structure Change (PF-TSK-014)](../../tasks/support/structure-change-task.md) — Writes pending-migrations.md entries
- [Project Initiation (PF-TSK-059)](../../tasks/00-setup/project-initiation-task.md) — New-project registration is integrated here (not Mode A)
- [Framework Rollout Context Map (PF-VIS-067)](../../visualization/context-maps/support/framework-rollout-map.md) — Component relationships
- [Centralized Framework Management Proposal](../../../process-framework-central/proposals/centralized-framework-management.md) — Source design (post-migration moves to `proposals/old/`)
