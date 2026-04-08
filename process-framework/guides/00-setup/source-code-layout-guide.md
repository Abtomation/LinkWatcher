---
id: PF-GDE-058
type: Process Framework
category: Guide
domain: agnostic
version: 1.0
created: 2026-04-06
updated: 2026-04-06
---

# Source Code Layout Guide

## Overview

This guide explains how to complete and maintain the [Source Code Layout](/doc/technical/architecture/source-code-layout.md) document. It covers the feature-first directory organization pattern, layer definitions, sublayer thresholds, file placement rules, and scale transition criteria.

## When to Use

Use this guide when:

- **Setting up a new project** (PF-TSK-059) — to understand fixed rules and configure `paths.source_code`
- **Onboarding an existing project** (PF-TSK-064) — to complete the source layout doc after feature discovery
- **Creating new source files** — to determine where a file should be placed
- **Growing a feature** — to decide when sublayers are needed within a feature directory

## Prerequisites

Before completing the source layout document, ensure:

- `doc/project-config.json` exists with `paths.source_code` set
- `languages-config/{language}/{language}-config.json` exists with the `directoryStructure` section
- Feature tracking (`doc/state-tracking/permanent/feature-tracking.md`) has confirmed features

## Feature-First Directory Organization

### Core Principle

All projects use **feature-first** directory organization: top-level directories within the source root correspond to features tracked in `feature-tracking.md`. This mirrors how the framework tracks work — each feature has a state file, and each feature has a source directory.

### Why Feature-First from the Start

Feature-first organization is the framework default for all projects regardless of size (see Design Decision D1 in [PF-PRO-002](/process-framework-local/proposals/source-code-layout-framework.md)). Rationale:

- Feature state files already organize tracking by feature — the file system mirrors this
- The hybrid pattern (feature-first, internal by-layer when needed) handles all project scales
- Eliminates restructuring risk — moving from by-layer to feature-first requires updating all import statements
- Removes a decision point during Project Initiation when context is limited

### Basic Structure

```
{sourceRoot}/
  {feature_a}/          # One directory per tracked feature
    feature_a_module.py
    feature_a_utils.py
  {feature_b}/
    feature_b_service.py
  shared/               # Cross-cutting utilities
    utils.py
    constants.py
  main.py               # Entry point at source root
```

## Layer Definitions

Layers are sublayer directories created **within** a feature directory when it grows beyond the sublayer threshold. Layer names and purposes are defined in the language config (`directoryStructure.layers`).

### Standard Layers

| Layer | Purpose | Contains |
|-------|---------|----------|
| **data** | Database access, models, repositories | ORM models, repository classes, data mappers, migration scripts |
| **services** | Business logic, orchestration, validation | Service classes, validators, business rule implementations |
| **ui** | User interface, views, controllers | UI components, views, forms, controllers, display logic |

### Layer Dependency Rules

Layers follow a strict dependency direction:

```
ui --> services --> data
```

- **ui** may import from **services** and **data**
- **services** may import from **data** only
- **data** should not import from **services** or **ui**
- All layers may import from **shared/**

## Sublayer Threshold

The sublayer threshold (defined in `directoryStructure.sublayerThreshold`, default: 8) determines when a flat feature directory should be split into sublayer directories.

### When to Add Sublayers

Add sublayers when a feature directory exceeds the threshold number of files:

**Before** (flat, 5 files — below threshold):
```
invoicing/
  invoice_service.py
  invoice_model.py
  invoice_repository.py
  invoice_form.py
  invoice_utils.py
```

**After** (sublayered, 10 files — above threshold):
```
invoicing/
  data/
    invoice_model.py
    invoice_repository.py
    invoice_mapper.py
  services/
    invoice_service.py
    invoice_calculator.py
    invoice_validator.py
  ui/
    invoice_form.py
    invoice_list.py
    invoice_detail.py
  invoice_utils.py          # Feature-level utils stay at feature root
```

### Sublayer Rules

1. **Count only source files** — exclude `__init__.py`, test files, and generated files
2. **Sublayer all at once** — when adding sublayers, organize all existing files into appropriate layers (not just the new file)
3. **Feature-level files** — files that don't clearly belong to a single layer (e.g., feature constants, feature-level utilities) remain at the feature directory root
4. **Document the transition** — add an entry to the Scale Transition Notes section of `source-code-layout.md`

## File Placement Decision Tree

Use this decision tree when creating a new file:

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

### Common File Placement Examples

| File Type | Placement | Example |
|-----------|-----------|---------|
| Database model | `{feature}/data/` (or `{feature}/` if flat) | `invoicing/data/invoice_model.py` |
| Repository/DAO | `{feature}/data/` (or `{feature}/` if flat) | `invoicing/data/invoice_repository.py` |
| Service class | `{feature}/services/` (or `{feature}/` if flat) | `invoicing/services/invoice_service.py` |
| UI component | `{feature}/ui/` (or `{feature}/` if flat) | `invoicing/ui/invoice_form.py` |
| Cross-feature utility | `shared/` | `shared/date_utils.py` |
| Configuration parser | `shared/` | `shared/config_loader.py` |
| Main entry point | Source root | `src/main.py` |
| Feature constants | Feature directory root | `invoicing/constants.py` |

## Completing the Source Layout Document

### During Project Initiation (PF-TSK-059)

Only one action is needed:

1. Set `paths.source_code` in `doc/project-config.json` to the source directory name (e.g., `src`)

No directories are created yet — features are not known at this point.

### During Codebase Feature Discovery (PF-TSK-064)

After features are consolidated (Step 7), complete the source layout doc:

1. **Run the scaffold script**: `New-SourceStructure.ps1 -Scaffold` creates the source root, shared directory, feature directories, fills Project Configuration, and generates the initial Directory Tree
2. **Complete Dependency Flow**: Document which feature directories may import from which, based on discovered dependencies
3. **Complete File Placement Decision Tree**: Adapt the generic decision tree above to the project's specific features and conventions
4. **Validate**: Confirm no application source files exist at repository root

### During Implementation

When creating new source files during any implementation task:

1. Consult `source-code-layout.md` for file placement
2. Use the File Placement Decision Tree to determine the correct directory
3. If directory structure changed, run `New-SourceStructure.ps1 -Update` to refresh the Directory Tree section

## Scale Transition Criteria

Document scale transitions in the Scale Transition Notes section of `source-code-layout.md` when:

1. **Adding sublayers to a feature** — record the date, feature name, file count that triggered the transition, and the layer distribution
2. **Extracting shared code** — record when code was moved from a feature to shared/ and why
3. **Splitting a feature** — record when a feature directory was split into multiple features

### Scale Transition Entry Format

```markdown
### {Date} — {Feature Name}: Added sublayers

- **Trigger**: {file count} files exceeded threshold of {threshold}
- **Distribution**: data ({n} files), services ({n} files), ui ({n} files)
- **Notes**: {any relevant context}
```

## Maintaining the Directory Tree

The Directory Tree section of `source-code-layout.md` is **auto-generated** by `New-SourceStructure.ps1 -Update`. Key rules:

- **Never edit the Directory Tree manually** — it is regenerated from the actual file system
- **Run `-Update` after stable state** — after all file moves for a session are complete and tests pass (Design Decision D10)
- **Manual sections are preserved** — Dependency Flow, File Placement Decision Tree, and Scale Transition Notes are never touched by the script

## Related Resources

- [Source Code Layout](/doc/technical/architecture/source-code-layout.md) — the project-specific layout document
- [PF-PRO-002 Concept](/process-framework-local/proposals/source-code-layout-framework.md) — design decisions and rationale
- [Feature Tracking](/doc/state-tracking/permanent/feature-tracking.md) — confirmed feature list
