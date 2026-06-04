---
id: PF-TEM-080
type: Process Framework
category: Template
version: 1.0
created: 2026-05-29
updated: 2026-05-29
creates_document_type: Process Framework
creates_document_version: 1.0
creates_document_prefix: PF-TEM
template_for: Template
creates_document_category: Template
usage_context: Process Framework - Template Creation
description: Trimmed variant of the Pending Migration Entry Template (PF-TEM-079) for no-data-motion migrations (empty-dir or placeholder-only cleanup)
---

# Pending Migration Entry Cleanup Template

## Purpose

A trimmed variant of the [Pending Migration Entry Template (PF-TEM-079)](pending-migration-entry-template.md) for **no-data-motion migrations** — empty-directory removal, placeholder relocation, or config/registry-key cleanup where the change is mechanically `Remove-Item` / `New-Item` (or a single config edit) with nothing to preserve. It keeps the audit-trail spine (ID, Source, Source Framework Version, Target Files, Rollback Implications) while dropping the full template's dual-branch Rollback scaffolding and separate Validation section.

PF-TEM-079 remains the canonical reference for all field semantics, the lifecycle (written by Structure Change, applied by Framework Rollout Mode C, scanned by Mode D), the container-file layout, and the summary table. This file defines only the trimmed entry form and when to use it.

## When to use this variant

Use the minimal form below when **all** of these hold:

- The migration moves **no data** — it removes an empty/placeholder directory, creates a placeholder, or edits a config/registry key with no content to migrate.
- The Migration Steps reduce to `Remove-Item` / `New-Item` (plus a "pre-check the target is empty/placeholder-only; if real content is found, stop and reconcile" guard).
- The reversal, if any, is trivial — a single `New-Item` / `Remove-Item` to restore the prior placeholder.

Use the **full** [Pending Migration Entry Template (PF-TEM-079)](pending-migration-entry-template.md) when the migration moves or transforms real content, has multi-step reversal, ships its own apply script, or needs the expanded Description / Validation guidance.

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

<1–2 sentences: which empty-dir / placeholder / key is cleaned up, and the appdev structural change that motivates it. State explicitly that there is no data motion.>

#### Migration Steps

1. **Pre-check** the target is empty / placeholder-only (e.g., `Get-ChildItem <path> -Force` returns nothing or `.gitkeep` only). If real content is found, **stop and reconcile** — switch to the full PF-TEM-079 form.
2. <The `Remove-Item` / `New-Item` (or single config/registry edit) step.>

#### Expected Outcome (doubles as validation)

<Verifiable post-condition — e.g., "`Test-Path <old>` returns `False`; `<new>` exists with `.gitkeep`." For a cleanup this single check serves as both expected outcome and validation.>

#### Rollback Implications

**Backward-compatible**: `yes` | `no`

<One line. If `yes`: why the prior framework version still parses the project cleanly. If `no`: the single trivial reversal step — e.g., "Before Mode D rollback, recreate `<old-path>` as an empty placeholder.">
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
