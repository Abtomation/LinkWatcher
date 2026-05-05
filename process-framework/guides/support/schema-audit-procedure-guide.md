---
id: PF-GDE-064
type: Process Framework
category: Guide
version: 1.0
created: 2026-05-04
updated: 2026-05-04
related_script: Validate-StateTracking.ps1
---

# Schema Audit Procedure

## Overview

How to reconcile template-frontmatter schema drift surfaced by `Validate-StateTracking.ps1 -Detailed` (Surface 10: Metadata Schema Conformance).

The validate script's Surface 10 checks every task, template, guide, and context map against the schema declared in [`domain-config.json`](/process-framework/domain-config.json) under `artifact_metadata_schemas`. Frontmatter fields that aren't declared as `required` or `optional` for that artifact type produce **"Unknown field"** warnings. Per [PF-IMP-646](/process-framework-local/state-tracking/permanent/process-improvement-tracking.md), these warnings are marked `-DetailOnly` because they're dominated by legitimate template-subtype fields rather than typos — the default summary line `"Warnings: N (M hidden — use -Detailed to view)"` is the trigger for this audit.

## When to Use

Run this audit when **either** condition holds:

- The default-mode summary shows the hidden-warning count rising notably (e.g., > 150) — drift is accumulating
- You add a new template with novel frontmatter fields and want to confirm whether they should be declared in the schema or are local-only

There is no calendar cadence; the trigger is signal-driven from the validation output.

## Prerequisites

- [`Validate-StateTracking.ps1`](/process-framework/scripts/validation/Validate-StateTracking.ps1) is present and runs cleanly
- [`process-framework/domain-config.json`](/process-framework/domain-config.json) contains an `artifact_metadata_schemas` section with entries for `task`, `template`, `guide`, `context_map`
- You can edit `domain-config.json` (no automation script wraps schema edits — direct JSON edits)

## Background

### The schema system

`artifact_metadata_schemas` declares per-artifact-type frontmatter contracts:

```json
"guide": {
  "required": ["id", "type", "category", "version", "created", "updated"],
  "optional": ["related_task", "related_script"],
  "field_values": {
    "id_pattern": "^(PF-GDE-\\d{3}|PF-MTH-\\d{3})$",
    "type": ["Process Framework"],
    "category": ["Guide", "Methodology", "Template"]
  }
}
```

Surface 10 enforces three things per file:

1. **Required fields present** (`ERROR` if missing)
2. **`field_values` constraints** for `id`, `type`, `category` (`ERROR` if violated)
3. **No unknown fields** (`WARNING -DetailOnly` if a frontmatter key isn't in `required` or `optional`)

Errors and the first two warning classes display in default mode. Class 3 is hidden by default and revealed by `-Detailed`.

### The two reconciliation paths

Each "Unknown field" finding maps to one of two outcomes:

| Outcome | When | Action |
|---|---|---|
| **Declare** | The field is legitimate — used intentionally by one or more templates of this artifact type and should be allowed | Add the field name to the artifact type's `optional` array in `domain-config.json` |
| **Fix** | The field is a typo, leftover from a refactor, or doesn't belong in this artifact type | Edit the offending template/guide/task file's frontmatter to remove or rename the field |

A finding is never "ignore" — every line in `-Detailed` output represents real drift between intent and declaration.

## Step-by-Step Instructions

### 1. Capture the audit output

```powershell
pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/validation/Validate-StateTracking.ps1 -Surface MetadataSchema -Detailed > schema-audit.txt 2>&1
```

Scoping with `-Surface MetadataSchema` keeps output focused on the relevant findings.

**Expected result:** `schema-audit.txt` contains all "Unknown field" warnings plus the conforming/violation summary at the end.

### 2. Group findings by artifact type and field name

Parse the output for lines of the form `Unknown field: <name> (not in schema for <artifact_type>)`. Cluster by `(artifact_type, field_name)` pairs — each pair is one decision, regardless of how many files raised it.

A field appearing in **many** files of one artifact type is almost always legitimate (declare). A field appearing in **one** file is more likely a typo (fix).

### 3. Decide and act on each cluster

For each `(artifact_type, field_name)` cluster:

1. **Read one representative file's frontmatter** to confirm the field's role
2. **Decide**:
   - Multiple files use it consistently with the same semantics → **Declare**
   - Single occurrence with no obvious purpose, or a near-miss of an existing field name (e.g., `created_at` vs `created`) → **Fix**
3. **Apply**:
   - **Declare**: edit `domain-config.json`, append the field name to `artifact_metadata_schemas.<type>.optional`. Keep the array alphabetically grouped where it already is.
   - **Fix**: edit the offending file's frontmatter (rename, remove, or move to body)

### 4. Re-run and verify

```powershell
pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/validation/Validate-StateTracking.ps1 -Surface MetadataSchema
```

**Expected result:** the default-mode summary's hidden-warning count drops by exactly the number of findings reconciled. New errors should be zero — if the count increased, you likely introduced a `field_values` violation (e.g., declared an optional field but typo'd the name in `domain-config.json`).

## Examples

### Example: Declare a legitimate field

`schema-audit.txt` shows 8 lines like:

```
[WARNING] [MetadataSchema] process-framework/templates/02-design/tdd-t2-template.md: Unknown field: applies_to (not in schema for template)
[WARNING] [MetadataSchema] process-framework/templates/02-design/tdd-t3-template.md: Unknown field: applies_to (not in schema for template)
... (6 more template files use applies_to consistently)
```

8 templates use `applies_to` for the same purpose → **declare**. Edit `domain-config.json`:

```json
"template": {
  "optional": [
    "related_task",
    "related_script",
    ...,
    "workflow_phase",
    "applies_to"   // ← added
  ]
}
```

Re-run shows 8 fewer hidden warnings.

### Example: Fix a typo

`schema-audit.txt` shows one line:

```
[WARNING] [MetadataSchema] process-framework/guides/support/some-guide.md: Unknown field: updatd (not in schema for guide)
```

Single occurrence; field name is one character off from `updated` → **fix**. Edit `some-guide.md` frontmatter:

```yaml
---
updatd: 2026-04-15   # ← typo
---
```

becomes:

```yaml
---
updated: 2026-04-15
---
```

## Troubleshooting

### Hidden-warning count increased after my changes

**Symptom:** After declaring fields and re-running, the default-mode summary shows *more* hidden warnings than before.

**Cause:** Most likely a JSON typo in the `optional` array of `domain-config.json` — a misnamed field still doesn't match real frontmatter, and you may have introduced a new validation error elsewhere.

**Solution:** `python -c "import json; json.load(open('process-framework/domain-config.json'))"` to confirm valid JSON, then re-read the diff of your `domain-config.json` edit. Each newly-declared field name must match the actual frontmatter key character-for-character.

### A field is used in only 2-3 files but I'm unsure if it's legitimate

**Symptom:** Borderline cluster — too few occurrences to confidently declare, but no obvious typo either.

**Cause:** Often means the field was introduced for a specific template subtype that hasn't proliferated yet.

**Solution:** Check the templates' purpose (read the template file). If the field is meaningful and likely to recur, declare it. If it's experimental or one-off, fix it (remove from frontmatter, document in the body). When in doubt, declare — the cost of a too-permissive schema is low; the cost of false typo-fix is bigger.

### Re-running default mode still shows large hidden-warning count

**Symptom:** After reconciling 50+ findings, default summary still shows ~60 hidden warnings.

**Cause:** Surface 10 also surfaces unknown fields in **task** and **context_map** files — the audit must cover all four artifact types, not just templates and guides.

**Solution:** The `-Surface MetadataSchema` run already includes all artifact types; re-read `schema-audit.txt` and confirm you addressed every cluster, not just the largest ones.

## Related Resources

- [Validate-StateTracking.ps1](/process-framework/scripts/validation/Validate-StateTracking.ps1) — Surface 10 implementation (lines ~824-958)
- [domain-config.json](/process-framework/domain-config.json) — `artifact_metadata_schemas` section
- [Process Improvement Tracking](/process-framework-local/state-tracking/permanent/process-improvement-tracking.md) — PF-IMP-646 (introduced `-DetailOnly`) and PF-IMP-690 (this guide)
