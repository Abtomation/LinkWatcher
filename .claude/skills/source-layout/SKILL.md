---
name: source-layout
description: >-
  Craft for organizing source code and completing the project's Source Code Layout document
  well — the judgment half of the layout-owning steps in Project Initiation (PF-TSK-059) and
  Codebase Feature Discovery (PF-TSK-064). Covers the feature-first organization principle,
  standard layer definitions and the layer-dependency-rules narrative (companion to
  project-config.json layering_rules — JSON leads, prose follows), the sublayer threshold, the
  file placement decision tree consulted during any implementation, scale transition criteria
  (anchor preserved for materialized layout-doc links), and directory-tree maintenance rules.
  Activated from the two owning tasks' Check-Recommended-Skills steps (via recommended_skills);
  also consulted inline (no binding) by Dimension Validation's layer-boundary check and whenever
  a new source file needs placing. Not a code-migration, refactoring, or architecture-design
  skill.
user-invocable: false
---

# Source Code Layout Craft

This skill owns the **craft** of organizing source code feature-first and completing the
project's [Source Code Layout](../../../doc/technical/architecture/source-code-layout.md) document.
It is the craft home for the layout-owning steps of **Project Initiation (PF-TSK-059)** and
**Codebase Feature Discovery (PF-TSK-064)**, which own everything else: the step sequences,
checkpoints, and the scaffold script invocation. Its placement rules are also consulted inline
whenever a source file is created during implementation, and its Layer Dependency Rules section
is the narrative companion Dimension Validation's layer-boundary check references.

> **Division of labor.** The tasks own process; this skill owns craft. The scaffold/update
> mechanics live in `process-framework/scripts/file-creation/00-setup/New-SourceStructure.ps1`
> (reference-don't-bundle — `Get-Help New-SourceStructure.ps1 -Parameter *` for parameters): `-Scaffold` creates the source
> root, shared/ and feature directories and generates the initial Directory Tree; `-Update`
> regenerates the tree after structure changes. The fixed rules (no source at repo root,
> feature-first, explicit shared/, entry point at source root) are stated in the layout
> document itself.

> **Language note:** examples use Python filenames for concreteness. The organization, layering,
> and placement rules are language-agnostic — substitute your language's conventions, and read
> `__init__.py` as whatever package/module marker your language uses (if any).

## Feature-First Organization

Top-level directories within the source root correspond to features tracked in
`feature-tracking.md` — the file system mirrors the framework's tracking, for all projects
regardless of size. Rationale: feature state files already organize tracking by feature; the
hybrid pattern (feature-first, internal by-layer when needed) handles all scales; and starting
feature-first eliminates the restructuring risk of a later by-layer → feature-first move (every
import statement) plus a low-context decision point at Project Initiation.

```
{sourceRoot}/
  {feature_a}/          # One directory per tracked feature
    feature_a_module.py
  {feature_b}/
    feature_b_service.py
  shared/               # Cross-cutting utilities
    utils.py
  main.py               # Entry point at source root
```

## Layer Dependency Rules

Layers are sublayer directories created **within** a feature directory when it grows beyond the
sublayer threshold:

| Layer | Purpose | Contains |
|-------|---------|----------|
| **data** | Database access, models, repositories | ORM models, repository classes, data mappers, migration scripts |
| **services** | Business logic, orchestration, validation | Service classes, validators, business rule implementations |
| **ui** | User interface, views, controllers | UI components, views, forms, controllers, display logic |

> **🔑 Source of truth**: `doc/project-config.json::layering_rules` is the machine-readable,
> enforceable declaration of the project's layer dependency rules — **JSON leads, this prose
> follows**. When updating layer rules, edit the JSON first and mirror the change in the
> project's own layout document. The Code Quality (CQ) dimension of Dimension Validation reads
> the JSON; the detection workflow lives in the Feature Validation Guide's Layer-Boundary
> Validation section.

Default dependency direction — `ui --> services --> data`:

- **ui** may import from **services** and **data**
- **services** may import from **data** only
- **data** should not import from **services** or **ui**
- All layers may import from **shared/**

Projects with stricter architectures (clean/hexagonal, service-mediated UI) tighten these
defaults by declaring tighter `may_import_from` allowlists in their `layering_rules` block —
e.g. forbidding UI→data via `ui.may_import_from = ["services", "shared"]`. The framework default
stays permissive; enforcement is project-driven.

## Sublayer Threshold

The threshold (`directoryStructure.sublayerThreshold` in the language config, default 8) decides
when a flat feature directory splits into data/services/ui sublayers. Judgment rules:

1. **Count only source files** — exclude package markers, test files, generated files.
2. **Sublayer all at once** — organize every existing file into layers, not just the new one.
3. **Feature-level files stay at the feature root** — constants and feature-level utilities that
   don't clearly belong to one layer.
4. **Document the transition** — add a Scale Transition Notes entry (format below).

## File Placement Decision Tree

The generic tree — Codebase Feature Discovery's layout step adapts it to the project's actual
features (the adapted version in the project's own `source-code-layout.md` is then the operative
one during implementation):

```
Is this file shared across multiple features?
  YES --> Place in shared/
  NO  --> Does it belong to an existing feature?
    YES --> Is that feature directory sublayered?
      YES --> Place in the appropriate layer (data/services/ui)
      NO  --> Place directly in the feature directory
    NO  --> Is it a new feature?
      YES --> Create a new feature directory, place file there
      NO  --> Is it the main entry point?
        YES --> Place at source root
        NO  --> Ask: should this be a new feature or part of shared/?
```

| File type | Placement |
|-----------|-----------|
| Database model / repository | `{feature}/data/` (or flat `{feature}/`) |
| Service class | `{feature}/services/` (or flat) |
| UI component | `{feature}/ui/` (or flat) |
| Cross-feature utility / config parser | `shared/` |
| Main entry point | Source root |
| Feature constants | Feature directory root |

## Completing the Layout Document

- **At Project Initiation**: one action only — set `paths.source_code` in
  `doc/project-config.json`. No directories yet; features aren't known.
- **At Codebase Feature Discovery** (after features are consolidated): run
  `New-SourceStructure.ps1 -Scaffold`, then complete the manual sections — Dependency Flow
  (which feature directories may import from which, from discovered dependencies) and the
  adapted File Placement Decision Tree — and validate no application source remains at the
  repository root.
- **During implementation**: consult the project's `source-code-layout.md` for placement; run
  `New-SourceStructure.ps1 -Update` after structure changes.

## Scale Transition Criteria

Record a Scale Transition Notes entry in `source-code-layout.md` when: **adding sublayers**
(date, feature, triggering file count, layer distribution), **extracting shared code** (what
moved to shared/ and why), or **splitting a feature**.

```markdown
### {Date} — {Feature Name}: Added sublayers

- **Trigger**: {file count} files exceeded threshold of {threshold}
- **Distribution**: data ({n} files), services ({n} files), ui ({n} files)
- **Notes**: {any relevant context}
```

## Maintaining the Directory Tree

The layout document's Directory Tree section is **auto-generated** by
`New-SourceStructure.ps1 -Update`: never edit it manually; run `-Update` after a stable state
(moves complete, tests pass); the manual sections (Dependency Flow, decision tree, Scale
Transition Notes) are never touched by the script.
