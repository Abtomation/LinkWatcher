---
id: PF-TEM-080
type: Process Framework
category: Template
version: 1.2
created: 2026-05-29
updated: 2026-07-21
creates_document_type: Process Framework
creates_document_version: 1.0
creates_document_prefix: PF-TEM
template_for: Template
creates_document_category: Template
usage_context: Process Framework - Template Creation
description: Trimmed variant of the Pending Migration Entry Template (PF-TEM-079) for no-data-motion migrations (empty-dir/placeholder removal, config-key edit, in-place text substitution, or additive section append)
---

# Pending Migration Entry Cleanup Template

## Purpose

A trimmed variant of the [Pending Migration Entry Template (PF-TEM-079)](pending-migration-entry-template.md) for **no-data-motion migrations** — empty-directory removal, placeholder relocation, config/registry-key cleanup, in-place text substitution (link/path repoint, single-line fix), or additive section append (insert a self-contained section copied verbatim from a canonical blueprint source) where the change is mechanically `Remove-Item` / `New-Item`, a single config edit, a string-replace, or an insert-after-heading append with nothing to preserve. It keeps the audit-trail spine (ID, Source, Source Framework Version, Target Files, Rollback Implications) while dropping the full template's dual-branch Rollback scaffolding and separate Validation section.

PF-TEM-079 remains the canonical reference for all field semantics, the lifecycle (written by Structure Change, applied by Framework Rollout Mode C, scanned by Mode D), the container-file layout, and the summary table. This file defines only the trimmed entry form and when to use it.

## When to use this variant

Use the minimal form below when **all** of these hold:

- The migration moves **no data** — it removes an empty/placeholder directory, creates a placeholder, edits a config/registry key, substitutes in-place text (link/path repoint, single-line fix), or appends a self-contained section copied verbatim from a canonical blueprint source, with no content to migrate.
- The Migration Steps reduce to `Remove-Item` / `New-Item`, a single config/registry-key edit, a string-replace, or an insert-after-heading append (plus a "pre-check the target holds nothing that needs migrating — for a text substitution, that the old string is still present; for an additive append, that the target heading is absent; if real content is found, stop and reconcile" guard).
- The reversal, if any, is trivial — a single `New-Item` / `Remove-Item` to restore the prior placeholder, an inverse string-replace, or deleting the appended section.

Use the **full** [Pending Migration Entry Template (PF-TEM-079)](pending-migration-entry-template.md) when the migration moves or transforms real content, has multi-step reversal, ships its own apply script, needs the expanded Description / Validation guidance, or targets real content whose data motion already happened (a **drain**): there the Full form's shape is verify-completeness-then-delete, with the re-verification as its own apply-time step.

> **Backward-compatibility is NOT assumed by this variant.** A no-data-motion cleanup can still be `Backward-compatible: no` — e.g., older framework docs reference the removed path (see PF-TEM-079's MIG-002 precedent in any project ledger). The Rollback Implications field is kept below for exactly this reason; only the verbose dual-branch scaffolding is dropped.

## Entry ID Convention

Same as the full template: each entry has a per-project `MIG-<NNN>` ID assigned sequentially by Structure Change at write time; IDs are stable once assigned. See [PF-TEM-079 § Entry ID Convention](pending-migration-entry-template.md#entry-id-convention).

## Entry Structure (minimal form)

```markdown
### MIG-NNN: <verb-first title — e.g., "Remove empty `test/legacy/` placeholder dir">

| Field | Value |
|---|---|
| **Status** | Open / Resolved / Skipped |
| **Source** | [<link>](relative-path-to-Structure-Change-state-file-or-session) |
| **Source Framework Version** | YYYY-MM-DD-NNN |
| **Created** | YYYY-MM-DD |
| **Resolved** | YYYY-MM-DD (only when Status=Resolved; otherwise omit row) |
| **Resolved By** | <session-id or operator> (only when Status=Resolved) |
| **Supersedes** | *(optional)* MIG-NNN — one-line reason. Omit row when not applicable. |

#### Target Files

- `<project-relative-path>` — <one-line: what is removed / created>

#### Description

<1–2 sentences: which empty-dir / placeholder / key is removed, which in-place text is substituted (link/path repoint, single-line fix), or which section is appended (name its canonical blueprint source), and the appdev structural change that motivates it. State explicitly that there is no data motion.>

> **Declare any cross-entry / bootstrap dependency here** — if this cleanup only applies correctly after another `MIG-NNN` or a framework bootstrap that may not have reached the project, say so explicitly so the applier's pre-check can stop and reconcile on a missing prerequisite.

#### Migration Steps

1. **Pre-check** the target holds nothing that needs migrating — an empty/placeholder directory (e.g., `Get-ChildItem <path> -Force` returns nothing or `.gitkeep` only), a config/registry key whose only value is the obsolete one being removed, for an in-place text substitution that the exact old string is still present (e.g., `Select-String '<old>' <file>`) so the replace no-ops if already applied, or — for an additive append — that the target heading/string is **absent** (e.g., `Select-String '<new-heading>' <file>` returns nothing) so the append no-ops if already applied. If real content needing migration is found, **stop and reconcile** — switch to the full PF-TEM-079 form.
2. <The `Remove-Item` / `New-Item`, single config/registry edit, string-replace (e.g. `(Get-Content <file> -Raw) -replace '<old>','<new>' | Set-Content <file>`), or insert-the-section step (copy the section verbatim from its canonical blueprint source and insert it after the named anchor heading).>

> **Script-owned state files**: a uniform relabel (e.g. renaming a legend value across every occurrence) is a legitimate whole-file substitution, but changing **row data** in a file with a recomputed derived block — e.g. a feature's Status/Doc Tier cell in `feature-tracking.md` — goes through the owning mutation script, never a string-replace. See the [full template's rule](pending-migration-entry-template.md#migration-steps).

#### Expected Outcome (doubles as validation)

<Verifiable post-condition — e.g., "`Test-Path <old>` returns `False`; `<new>` exists with `.gitkeep`", "`Select-String '<old>' <file>` returns nothing and the new string is present", or — for an additive append — "`Select-String '<new-heading>' <file>` returns the appended heading and any links in the section resolve in the project tree". For a cleanup this single check serves as both expected outcome and validation.>

#### Rollback Implications

**Backward-compatible**: `yes` | `no`

<One line. If `yes`: why the prior framework version still parses the project cleanly. If `no`: the single trivial reversal step — e.g., "Before Mode D rollback, recreate `<old-path>` as an empty placeholder," "re-run the inverse string-replace," or "delete the appended section.">
```

## What this variant drops (and why)

Relative to [PF-TEM-079 § Entry Structure](pending-migration-entry-template.md#entry-structure):

- **Dual-branch Rollback Implications** (the `If Backward-compatible: yes` / `If Backward-compatible: no` blocks with multi-step reversal examples) → collapsed to one line plus at most one reversal step. No-data-motion reversals are trivial by definition.
- **Separate Validation section** → folded into Expected Outcome; for a cleanup the post-condition check *is* the validation.
- **The "if the migration is mechanical and provides a script…" note** → cleanups don't ship apply scripts.
- **Notes (optional)** → omit unless a real edge case needs recording; copy the row back from PF-TEM-079 if so.

All dropped material still lives in PF-TEM-079. Promote an entry to the full form the moment a migration stops being a trivial cleanup.

## Related Resources

- [Pending Migration Entry Template (PF-TEM-079)](pending-migration-entry-template.md) — the canonical full template and authoritative field semantics
- [Structure Change Task (PF-TSK-014)](../../tasks/support/structure-change-task.md) — writes entries; chooses full vs. cleanup form
- [Framework Rollout Task (PF-TSK-088)](../../tasks/support/framework-rollout-task.md) — Mode C applies entries; Mode D pre-flight scans the Rollback Implications field
