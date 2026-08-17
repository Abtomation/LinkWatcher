---
id: PF-TEM-079
type: Process Framework
category: Template
version: 1.5
created: 2026-05-10
updated: 2026-08-10
description: Template for one entry in appdev/process-framework-central/per-project-migrations/<project-id>/pending-migrations.md. Each entry is one project working-doc migration written by Structure Change (PF-TSK-014) and applied by Framework Rollout Mode C (PF-TSK-088).
template_for: Template
usage_context: Process Framework - Template Creation
creates_document_prefix: PF-TEM
creates_document_version: 1.0
creates_document_category: Template
creates_document_type: Process Framework
---

# Pending Migration Entry Template

## Purpose

Defines the structure of a single entry in a project's `pending-migrations.md` ledger. Each entry describes one project working-document migration that needs to be applied to a specific project's `doc`, `test`, `CLAUDE.md`, or other working-tree files (any project file outside the Push-mirrored `process-framework` subtree).

> **🚨 Negative scope — when entries are NOT needed**: Entries are **only** for changes to project files **outside** the rolled-out subtree. Intra-`blueprint/process-framework` changes (additions, moves within the subtree, deletions, moves *out* of the subtree) propagate automatically via `Push-FrameworkUpdate.ps1`'s `robocopy /MIR` mirror. Do not write entries for those — the mirror handles them. See the [Framework Rollout Usage Guide — When you do NOT need a migration entry](../../guides/support/framework-rollout-usage-guide.md#when-you-do-not-need-a-migration-entry) for the canonical scope-boundary table.

**Lifecycle**:
1. **Written by** [Structure Change (PF-TSK-014)](../../tasks/support/structure-change-task.md) — when a structural change in `appdev/process-framework/` requires a corresponding edit to project working documents.
2. **Read and applied by** [Framework Rollout Mode C (PF-TSK-088)](../../tasks/support/framework-rollout-task.md#mode-c-phase-2-per-project-migrations) — drained per-project, one entry per checkpoint.
3. **Scanned by** [Framework Rollout Mode D (PF-TSK-088)](../../tasks/support/framework-rollout-task.md#mode-d-rollback) — pre-flight scan of the ledger's Summary table (Status + Resolved + Backward-compatible columns) for entries resolved between the rollback target and current version; for non-backward-compatible hits, the "Rollback Implications" reversal steps are read from the relocated detail block in the per-project archive.

**Container files** (PF-IMP-983 archive split): the ledger `appdev/process-framework-central/per-project-migrations/<PROJECT-ID>/pending-migrations.md` holds the Summary table (all entries, all statuses) plus the detail sections of **Open** entries under `## Pending entries`. When an entry is resolved or skipped, [Update-PendingMigration.ps1](../../scripts/update/Update-PendingMigration.ps1) relocates its detail section to the sibling archive `<PROJECT-ID>/archive/pending-migrations-archive.md` (`## Resolved entries` / `## Skipped entries`), so the ledger reads as open work only.

## Entry ID Convention

Each entry has a stable ID of the form `MIG-<NNN>` scoped per project (i.e., MIG-001 in APP-001's ledger is unrelated to MIG-001 in APP-002's ledger). IDs are assigned sequentially by the Structure Change task at write time. Once assigned, IDs do not change — even if the entry is later rejected, status changes don't reassign.

## Entry Structure

> **Lighter alternative**: for no-data-motion migrations (empty-dir removal, placeholder relocation, a single config/registry-key cleanup, an in-place text substitution, or an additive section append copied from a canonical blueprint source), use the trimmed [Pending Migration Entry Cleanup Template (PF-TEM-080)](pending-migration-entry-cleanup-template.md) instead of the full structure below — it keeps the audit-trail spine but drops the dual-branch Rollback scaffolding and separate Validation section.

Each entry MUST include all required fields below. Optional fields are flagged as such.

```markdown
### MIG-NNN: <one-line title — verb-first, e.g., "Add 'priority' column to feature-tracking.md">

| Field | Value |
|---|---|
| **Status** | Open / Resolved / Skipped |
| **Source** | [<source-link>](relative-path-to-Structure-Change-state-file-or-task-session) |
| **Source Framework Version** | YYYY-MM-DD-NNN (the framework version this migration was authored against) |
| **Created** | YYYY-MM-DD |
| **Resolved** | YYYY-MM-DD (only when Status=Resolved; otherwise omit row or write `—`) |
| **Resolved By** | <session-id, agent-action note, or operator name> (only when Status=Resolved) |
| **Skip Reason** | *(optional)* rationale and/or audit link — only when Status=Skipped (stamped by `Update-PendingMigration.ps1 -SkipReason`). Omit row otherwise. |
| **Supersedes** | *(optional)* MIG-NNN — one-line explanation of why this entry subsumes the earlier one. Omit row entirely when not applicable. |

#### Target Files

- `<project-relative-path>` — <one-line summary of what changes here>
- `<project-relative-path>` — <one-line summary>

#### Description

<2–5 sentences explaining what the migration does, framed from the perspective of the operator who will apply it. Reference the structural change in appdev that motivates it. Avoid implementation prescriptions here — they go in Migration Steps.>

> **Declare cross-entry / bootstrap dependencies here.** If this entry only applies correctly after another migration entry (`MIG-NNN`) or a framework bootstrap that may not yet have reached the project (e.g. a `recommended_skills` block, a legend value another entry adds), state that dependency explicitly in the Description so the applier's pre-check can detect a missing prerequisite and **stop and reconcile** rather than apply against an unprepared tree. Do not assume a prior state that the project ledger doesn't record.

#### Migration Steps

1. <Concrete edit step — e.g., "Add an optional `Notes` bullet under each feature's §4 Documentation Inventory in the per-feature state files under doc/state-tracking/features/">
2. <Step 2>
3. <Step 3>

> **🚨 Script-owned state files — mutate row data through the owning script.** Some state files carry a **derived block** recomputed by their mutation scripts — canonically `feature-tracking.md`, whose Progress Summary (status counts + tier distribution) is recomputed by the mutation helpers; see the [Feature Tracking Mutation Guide](../../guides/support/feature-tracking-mutation-guide.md). When a step changes **row data** in such a file (a feature's Status, Doc Tier, Notes cell), it invokes the matching script/helper — e.g. `Update-FeatureTrackingStatus -FeatureId <Id> -Status "<value>"` — **never** a hand-rolled `-replace` on the row: a raw edit bypasses the recompute, so the derived counts silently drift (a status flip decrements one count and increments another).
>
> A **uniform relabel** is the exception: renaming a legend value across *every* occurrence (e.g. swapping a status/tier emoji) leaves the counts unchanged and has no owning script, so a whole-file in-place substitution is correct — just ensure it also rewrites the occurrences inside the legend and the derived block, which a whole-file `-replace` does by construction.

If the migration is mechanical and Structure Change provides a script, reference it: `process-framework/scripts/update/Apply-Migration-MIG-NNN.ps1` (and document its parameters here).

Phrase preconditions and no-op conditions as **apply-time checks** the Mode C operator runs against the live tree (e.g., "If `test/audits/` does not exist (`Test-Path test/audits` returns `False`), mark this entry Skipped"), not as predictions about the project's current state. Concrete specifics (line numbers, file lists, counts) are illustrative at authoring time — the operator re-derives them at apply time.

A mutation via the owning script can still leave **prose** stale that no script fixes — a status flip may strand a now-contradictory parenthetical in the same row's Notes cell. When the mutation is semantic, add a step to check and correct such prose (via the same mutation helper's Notes path — e.g. `Update-FeatureTrackingStatus … -StatusColumn "Notes"`).

#### Expected Outcome

<Verifiable post-condition that the operator can confirm. Examples:
- "doc/state-tracking/permanent/feature-tracking.md has a 'priority' column populated with default value 'P3' for all existing rows."
- "test/test-tracking.md row count unchanged; new 'baseline_run' column added with `null` default.">

#### Rollback Implications

**Backward-compatible**: `yes` | `no`

> **🚨 This field is REQUIRED and consumed by Framework Rollout Mode D pre-flight scan.** Set deliberately and document the reasoning.

##### If Backward-compatible: yes

> The prior framework version still parses post-migration working docs cleanly (e.g., the migration only adds optional fields, sections, or rows that older code paths ignore). Mode D rollback is safe without project-side reversal.

Document why: <one sentence — e.g., "New 'priority' column is optional in feature-tracking schema; prior version's parser ignores unknown columns.">

##### If Backward-compatible: no

> The prior framework version cannot correctly read post-migration working docs (e.g., a column was renamed, a required field was added, a section was restructured in a way the older parser doesn't understand).

Document what breaks: <one sentence — e.g., "Renamed column 'state' to 'status' in feature-tracking.md; prior framework version's `Validate-StateTracking.ps1` reads 'state' and errors on missing column.">

**Required reversal steps before Mode D rollback** — when an operator runs Mode D after this migration has been applied, they MUST first:

1. <Step 1, e.g., "In project working tree: `git revert <migration-commit>` to restore prior column name">
2. <Step 2>
3. <Verification — e.g., "Run prior framework version's Validate-StateTracking.ps1 against the project to confirm it parses cleanly">

#### Validation

- <How to verify this entry is fully and correctly applied. Examples:
  - "Run `process-framework/scripts/validation/Validate-StateTracking.ps1` from the project root and confirm zero errors related to feature-tracking.md schema."
  - "Open doc/state-tracking/permanent/feature-tracking.md in the IDE and visually confirm the new column is present in all rows.">

#### Notes (optional)

<Free-form notes from operators who applied the migration, edge cases encountered, or links to follow-on issues. Append-only — do not rewrite previous notes.>
```

## Field Semantics

### Status

- **Open** — entry is awaiting application. Mode C sessions read open entries. Detail section lives in the ledger.
- **Resolved** — entry has been applied; Resolved date and Resolved By recorded, and the detail section relocates to the per-project archive (`Update-PendingMigration.ps1` does both in one operation).
- **Skipped** — entry was deemed not applicable to this project (e.g., the structural change targets a feature that doesn't exist in this project). An optional **Skip Reason** row (rationale and/or audit link) may be recorded via `Update-PendingMigration.ps1 -SkipReason`; Skipped entries carry no resolution date. Skipped is permanent; if the situation changes, write a new entry rather than re-opening a Skipped one. Detail section relocates to the archive's `## Skipped entries`.

### Source

A link back to the Structure Change task session or state file that produced this entry. Format: `[PF-STA-NNN](relative/path/to/state-file.md)` or `[PF-TSK-014 session YYYY-MM-DD](session-note-link)`. The source is authoritative for "why does this migration exist?" — entries should be terse; the Source link carries the deep context.

### Source Framework Version

The appdev framework version (`YYYY-MM-DD-NNN`) this migration entry was authored against — the "source" version, distinct from any later version that revises it. `New-PendingMigration.ps1` stamps it automatically at creation from `<framework-root>/.framework-version`; pass `-SourceFrameworkVersion` to override. It is provenance metadata: Mode D's rollback pre-flight identifies applied migrations from the **Resolved** date and **Backward-compatible** columns.

### Rollback Implications

This is the **load-bearing field for rollback safety**. The Structure Change author must reason about it explicitly — never default to `yes` without justification. When in doubt, choose `no` and document the required reversal steps; over-cautious is safer than over-optimistic.

When `Rollback Implications` is set, the **default reading direction** is:
- `yes` → Mode D operator can proceed without project-side reversal.
- `no` → Mode D operator MUST follow the required reversal steps before rollback, or accept and document a deliberate schema-mismatched rollback (uncommon; only when the operator is also abandoning the project's current state).

### Supersedes

An optional field indicating that this entry replaces an earlier migration entry whose scope is fully subsumed by this one.

**When to use**: A later structural change broadens or replaces the work prescribed by an earlier, still-open migration entry. Rather than patching the old entry (which breaks its authoring lineage), write a new entry that supersedes it.

**Format**: `MIG-NNN — <one-line explanation>`. The explanation should name what the superseded entry did and why this entry subsumes it. Example: `MIG-002 (PF-IMP-787 — clean-slate audit archival). Drop MIG-002 from the apply queue once this entry is applied; this entry subsumes MIG-002's cleanup steps.`

**Mode C (apply) integration**: When a Mode C operator encounters a superseding entry, they mark the superseded entry as **Skipped** (not Resolved — it was never applied) before applying the superseding entry. The superseding entry's Migration Steps must be self-contained; they should not assume the superseded entry was applied first.

**Mode D (rollback pre-flight) integration**: Mode D scans all entries between the rollback target version and the current version. When a superseding entry has been applied, the superseded entry's Rollback Implications are moot — only the superseding entry's Rollback Implications apply. Mode D should skip superseded entries that were marked Skipped.

## Summary Table (in container file, not in this template)

The container `pending-migrations.md` file SHOULD have a summary table at the top for quick scanning:

```markdown
| ID | Title | Status | Source FW Version | Backward-compatible | Resolved |
|----|-------|--------|-------------------|---------------------|----------|
| MIG-001 | Add 'priority' column to feature-tracking | Resolved | 2026-05-12-001 | yes | 2026-05-15 |
| MIG-002 | Rename 'state' to 'status' in feature-tracking | Open | 2026-05-20-001 | no | — |
```

The summary table is the ledger's permanent full index — rows keep all statuses. Per-entry sections following this template appear below it under `## Pending entries` while Open; on resolve/skip the section relocates to the per-project archive (see Container files above), leaving only the summary row behind.

## Related Resources

- [Framework Rollout Task (PF-TSK-088)](../../tasks/support/framework-rollout-task.md) — Defines Mode C (apply) and Mode D (rollback) workflows that consume entries
- [Structure Change Task (PF-TSK-014)](../../tasks/support/structure-change-task.md) — Writes entries; responsible for filling Rollback Implications correctly
- [Centralized Framework Management Proposal §3.5](../../../../process-framework-central/proposals/old/centralized-framework-management.md) — Source design for per-project migrations (post-migration moves to `proposals/old/`)
