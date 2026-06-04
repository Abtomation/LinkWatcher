---
id: PF-TEM-079
type: Process Framework
category: Template
version: 1.0
created: 2026-05-10
updated: 2026-05-10
description: Template for one entry in appdev/process-framework-central/per-project-migrations/PRJ-NNN/pending-migrations.md. Each entry is one project working-doc migration written by Structure Change (PF-TSK-014) and applied by Framework Rollout Mode C (PF-TSK-088).
template_for: Template
usage_context: Process Framework - Template Creation
creates_document_prefix: PF-TEM
creates_document_version: 1.0
creates_document_category: Template
creates_document_type: Process Framework
---

# Pending Migration Entry Template

## Purpose

Defines the structure of a single entry in a project's `pending-migrations.md` ledger. Each entry describes one project working-document migration that needs to be applied to a specific project's `doc/`, `test/`, `CLAUDE.md`, or other working-tree files (any project file outside the Push-mirrored `process-framework/` subtree).

> **🚨 Negative scope — when entries are NOT needed**: Entries are **only** for changes to project files **outside** the rolled-out subtree. Intra-`blueprint/process-framework/` changes (additions, moves within the subtree, deletions, moves *out* of the subtree) propagate automatically via `Push-FrameworkUpdate.ps1`'s `robocopy /MIR` mirror. Do not write entries for those — the mirror handles them. See [Framework Rollout Task — Pending Migrations Ledger](../../tasks/support/framework-rollout-task.md) and [Structure Change Step 14.5](../../tasks/support/structure-change-task.md) Scope Boundary for the authoritative explanation.

**Lifecycle**:
1. **Written by** [Structure Change (PF-TSK-014)](../../tasks/support/structure-change-task.md) — when a structural change in `appdev/process-framework/` requires a corresponding edit to project working documents.
2. **Read and applied by** [Framework Rollout Mode C (PF-TSK-088)](../../tasks/support/framework-rollout-task.md#mode-c-phase-2-per-project-migrations) — drained per-project, one entry per checkpoint.
3. **Scanned by** [Framework Rollout Mode D (PF-TSK-088)](../../tasks/support/framework-rollout-task.md#mode-d-rollback) — pre-flight scan of resolved entries between rollback target and current version, looking for non-backward-compatible "Rollback Implications" that require manual project-side reversal.

**Container file**: `appdev/process-framework-central/per-project-migrations/<PRJ-NNN>/pending-migrations.md`. The full ledger has a TOC + summary table + per-entry sections matching this template.

## Entry ID Convention

Each entry has a stable ID of the form `MIG-<NNN>` scoped per project (i.e., MIG-001 in PRJ-001's ledger is unrelated to MIG-001 in PRJ-002's ledger). IDs are assigned sequentially by the Structure Change task at write time. Once assigned, IDs do not change — even if the entry is later rejected, status changes don't reassign.

## Entry Structure

> **Lighter alternative**: for no-data-motion migrations (empty-dir removal, placeholder relocation, or a single config/registry-key cleanup), use the trimmed [Pending Migration Entry Cleanup Template (PF-TEM-080)](pending-migration-entry-cleanup-template.md) instead of the full structure below — it keeps the audit-trail spine but drops the dual-branch Rollback scaffolding and separate Validation section.

Each entry MUST include all required fields below. Optional fields are flagged as such.

```markdown
### MIG-NNN: <one-line title — verb-first, e.g., "Add 'priority' column to feature-tracking.md">

| Field | Value |
|---|---|
| **Status** | Open / Resolved / Skipped |
| **Source** | [<source-link>](relative-path-to-Structure-Change-state-file-or-task-session) |
| **Source Framework Version** | YYYY-MM-DD-NNN (the version containing this migration) |
| **Created** | YYYY-MM-DD |
| **Resolved** | YYYY-MM-DD (only when Status=Resolved; otherwise omit row or write `—`) |
| **Resolved By** | <session-id, agent-action note, or operator name> (only when Status=Resolved) |
| **Supersedes** | *(optional)* MIG-NNN — one-line explanation of why this entry subsumes the earlier one. Omit row entirely when not applicable. |

#### Target Files

- `<project-relative-path>` — <one-line summary of what changes here>
- `<project-relative-path>` — <one-line summary>

#### Description

<2–5 sentences explaining what the migration does, framed from the perspective of the operator who will apply it. Reference the structural change in appdev that motivates it. Avoid implementation prescriptions here — they go in Migration Steps.>

#### Migration Steps

1. <Concrete edit step, e.g., "Add a new column 'priority' between 'tier' and 'status' in the table at line 42 of doc/state-tracking/permanent/feature-tracking.md">
2. <Step 2>
3. <Step 3>

If the migration is mechanical and Structure Change provides a script, reference it: `process-framework/scripts/update/Apply-Migration-MIG-NNN.ps1` (and document its parameters here).

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

- **Open** — entry is awaiting application. Mode C sessions read open entries.
- **Resolved** — entry has been applied; Resolved date and Resolved By recorded.
- **Skipped** — entry was deemed not applicable to this project (e.g., the structural change targets a feature that doesn't exist in this project). Skipped is permanent; if the situation changes, write a new entry rather than re-opening a Skipped one.

### Source

A link back to the Structure Change task session or state file that produced this entry. Format: `[PF-STA-NNN](relative/path/to/state-file.md)` or `[PF-TSK-014 session YYYY-MM-DD](session-note-link)`. The source is authoritative for "why does this migration exist?" — entries should be terse; the Source link carries the deep context.

### Source Framework Version

The framework version (`YYYY-MM-DD-NNN`) in which this migration entry was written. Used by Mode D's pre-flight scan: when rolling back from version A to version B, Mode D scans entries with Source Framework Version > B to find non-backward-compatible migrations that may have been applied since version B.

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

Then per-entry sections following this template appear below the summary table.

## Related Resources

- [Framework Rollout Task (PF-TSK-088)](../../tasks/support/framework-rollout-task.md) — Defines Mode C (apply) and Mode D (rollback) workflows that consume entries
- [Structure Change Task (PF-TSK-014)](../../tasks/support/structure-change-task.md) — Writes entries; responsible for filling Rollback Implications correctly
- [Centralized Framework Management Proposal §3.5](../../../../process-framework-central/proposals/centralized-framework-management.md) — Source design for per-project migrations (post-migration moves to `proposals/old/`)
