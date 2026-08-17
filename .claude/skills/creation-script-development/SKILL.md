---
name: creation-script-development
description: >-
  Craft for developing document-creation PowerShell scripts well — the judgment half of the
  script-creation work delegated by New Task Creation (PF-TSK-001, its document-creation
  infrastructure session), Framework Extension (PF-TSK-026), and Structure Change
  (PF-TSK-014). Covers the New-FrameworkDocument authoring model (what the wrapper owns vs.
  what the script keeps, plain-delegator vs. post-creating sub-patterns, the
  Invoke-DesignArtifactCreation exception for design/feature-linked creators), the
  template-to-script development process (placeholder replacement, import-path logic,
  parameter validation, frontmatter-vs-body replacement semantics), ID-registry and
  directory-type integration (the -Subdirectory vs. multiple-directory-types decision),
  error-handling patterns, and the script testing checklist with post-modification
  verification. Activated from PF-TSK-001's and PF-TSK-026's Check-Recommended-Skills steps
  (via recommended_skills); also consulted inline wherever a creation script is authored
  (e.g. Structure Change delegation). The Script Development Quick Reference guide stays the
  agnostic troubleshooting companion for PowerShell execution patterns and footguns. Not a
  template-authoring or general PowerShell skill.
user-invocable: false
---

# Creation Script Development Craft

This skill owns the **craft** of authoring PowerShell scripts that generate documents from
templates through the framework's standardized creation system — consistent ID management,
error handling, template integration, metadata, and directory management. The **creating
task** owns everything else: when a script is needed, checkpoints, soak registration, Pester
coverage, and completion. Primary hosts: **New Task Creation (PF-TSK-001)** (its
document-creation infrastructure session) and **Framework Extension (PF-TSK-026)**;
**Structure Change (PF-TSK-014)** delegates script creation here rather than doing it inline.

> **Division of labor.** The task owns process; this skill owns script-authoring judgment.
> For PowerShell *execution* patterns and language footguns, the agnostic
> [Script Development Quick Reference](../../../process-framework/guides/support/script-development-quick-reference.md)
> is the troubleshooting companion — consult it for anything that breaks while developing.

## Authoring model: `New-FrameworkDocument`

**Write new creation scripts against `New-FrameworkDocument`** (exported from
`Common-ScriptHelpers/DocumentManagement.psm1`), not the raw `New-StandardProjectDocument`
call. The wrapper owns the boilerplate every delegator used to repeat:

- `Invoke-StandardScriptInitialization` (preferences + console encoding)
- soak opt-in via `Register-SoakScript` (caller-aware — keyed on the calling `.ps1`), which
  is a **no-op under `-WhatIf`**: a creation script's tests are correctly all `-WhatIf` (it
  consumes real IDs), so it never self-registers through them — register it once explicitly
  (`Register-SoakScript -ScriptId <relative-path> -ScriptPath <absolute-path>`) after a real run
- effective `-WhatIf` resolution across the module boundary
- the `New-StandardProjectDocument` call (the unchanged inner core)
- the create-failure `try/catch` → standard error + `exit 1`

It **returns the assigned document ID** (or `$null` under `-WhatIf`) — capture it for the
success report and any post-creation writes. A post-creating script that also needs the
**created file's path** (to write a tracking-table or state-file link) passes `-PassThru`
and reads `Id` / `Path` (absolute) / `RelativePath` (project-root-relative, forward
slashes) off the returned object — never re-derive the filename by mirroring the writer's
internal kebab logic; a mirrored derivation silently desynchronizes when the writer's
naming changes (PF-IMP-1678). The script keeps only what is genuinely its
own: the `param()` block (preserving native `ValidateSet`/`ValidateScript` binder rejection), the
module-import bootstrap, the replacements/metadata data-building, its own
`Write-ProjectSuccess` report, and any bespoke post-creation tracking writes. Pass
`-Label "<noun>"` to set the failure-message noun; map the metadata hashtable to `-Metadata`.

### Two sub-patterns

| Script shape | Pattern |
|--------------|---------|
| **Plain delegator** (no post-creation writes) | Call `New-FrameworkDocument`, then build `$details` and `Write-ProjectSuccess`. **No `try/catch` of your own** — the wrapper owns the error path. |
| **Post-creating** (writes a tracking table, renames the file, etc. after the create) | Keep an **outer `try/catch`** around the whole body; the wrapper still handles create failure, your catch guards the *post-creation* writes. Capture the returned ID — with `-PassThru` when a write needs the created file's path — and run the bespoke writes inline. |

Live models: plain delegators — `New-Template.ps1` (metadata-heavy), `New-TempTaskState.ps1`
(variant selection); post-creating — `New-ArchitectureDecision.ps1` (ADR-index surgery),
`New-FeatureImplementationState.ps1` (tracking link + scaffolding chain). All under
`process-framework/scripts/file-creation/`.

### Exception: design / feature-linked creators

The design creators (FDD, TDD, Schema, API Data Model, API Specification, UI Design, Test
Specification) delegate to **`Invoke-DesignArtifactCreation`** — a richer orchestrator
(create + feature-tracking status + per-feature state-file Documentation Inventory row).
**Do not route those through `New-FrameworkDocument`**; extend `Invoke-DesignArtifactCreation`
instead. The PD/TE documentation maps are generated separately
(`Build-DocumentationMap.ps1 -Tree PD|TE`) — never appended to by the orchestrator.

## Development process

1. **Analyze requirements** — document type, template location, ID prefix (add to the
   appropriate PF/PD/TE ID registry if new), parameters, output location, special
   integrations.
2. **Copy the script template** —
   `process-framework/templates/support/document-creation-script-template.ps1` →
   `process-framework/scripts/file-creation/<phase>/New-YourScript.ps1` (all creation
   scripts live under `scripts/file-creation/`).
3. **Replace every `[PLACEHOLDER]`** — script name/type/purpose, ID prefix, template path,
   output directory, parameters, template-replacement keys, metadata fields, success-report
   details. Full placeholder tables:
   [references/patterns-and-integration.md](references/patterns-and-integration.md).
4. **Configure the import path** for the script's depth (the reference holds the three
   standard forms).
5. **Add parameter validation** — `ValidateSet`, `ValidateLength`, `ValidateScript` on the
   `param()` block; validation stays in the script so binder rejection and tab completion work.
   Constraints do not reach `Get-Help` — document any non-obvious ones in the `.PARAMETER` text.
6. **Build replacements and metadata.** 🚨 `-Replacements` apply to the document **body
   only** — template frontmatter is stripped and rebuilt from `-Metadata` (plus the
   template's `creates_*` fields), so a placeholder in template frontmatter is never
   substituted. Metadata string values are made YAML-safe at the writer
   (`ConvertTo-YamlSafeScalar`): pass free text — including the instance `description:` the
   documentation map indexes — straight through, no pre-quoting needed.
7. **Add optional post-creation updates** behind `ShouldProcess` gates (tracking tables,
   index surgery) — this is what makes the script the post-creating sub-pattern.
8. **Test**: syntax check, `-WhatIf -Verbose` run, then a real test document — see the
   checklist below.

## Directory management

Directories resolve through the ID registry (`DirectoryType`), are created automatically,
and support two subdirectory approaches:

| Approach | Use when | Example |
|---|---|---|
| `-Subdirectory` parameter (optionally registry-validated via the prefix's `subdirectories` field) | Categories are open-ended or caller-determined | Handbook content types (`New-Handbook.ps1 -ContentType`), guide subdirectories (`New-Guide.ps1 -SubDirectory`) |
| Multiple directory types in the ID registry | Categories are fixed at framework design time | API specs vs. models; feature-specs vs. cross-cutting-specs |

Prefer `DirectoryType` over a raw `OutputDirectory`: the structure is then changeable by
updating the ID registry alone. Registry schema details and the `-Topic` L2 facet:
[references/patterns-and-integration.md](references/patterns-and-integration.md).

## Error handling

- The create-failure path is the **wrapper's** — a plain delegator writes no `try/catch`.
- A post-creating script keeps one outer `try/catch` ending in
  `Write-ProjectError -Message "..." -ExitCode 1`.
- Validate early with `[ValidateScript({ ... })]` or explicit
  `Write-ProjectError` guards (template exists, prefix known) before doing work.

## Script testing checklist

Before considering a creation script complete:

- [ ] Module import loads Common-ScriptHelpers without errors (test from multiple cwd's)
- [ ] Document created in the correct location with the correct name
- [ ] ID assigned and registry updated
- [ ] All template placeholders replaced with actual values
- [ ] Metadata complete and properly formatted
- [ ] Graceful failure with helpful errors; invalid parameters caught
- [ ] Output directories created when absent
- [ ] `-WhatIf` runs the logic path without side effects

Run `-WhatIf` first, then create a real test document, verify the output, and clean up test
files. Know that the real run **permanently burns a live ID**: cleanup deletes the file, but
registry counters never decrement (`id_gaps_policy` — gaps are expected, never backfilled).
That cost is why the sibling creator Pester suites stay `-WhatIf`-only; one deliberate real
run per authoring session is the accepted price of the "ID assigned and registry updated"
check.

## Post-modification verification

After modifying any creation script, verify the referencing documents are still accurate:
grep `doc/`, `process-framework/`, and `test/` for the script filename, **read every hit**
(references in guides, tasks, and templates may carry parameter names, paths, or behavioral
descriptions your change invalidated), and update or file follow-ups. This catches stale
documentation that would otherwise persist until the next Tools Review cycle.

## Reference index

- [references/patterns-and-integration.md](references/patterns-and-integration.md) — the
  placeholder tables, import-path forms, template metadata contract (`creates_*` fields,
  placeholder conventions), ID-registry schema (prefixes, subdirectories/topics), a minimal
  plain-delegator example, language-config integration (loading pattern, placeholder
  substitution, when to use vs. hardcode, Update-LanguageConfig.ps1), and advanced patterns
  (custom file naming, multiple-template selection, conditional replacements, debugging
  tips). Load when actually writing or modifying a script.
