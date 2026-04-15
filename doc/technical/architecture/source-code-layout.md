---
id: PD-ARC-001
type: Process Framework
category: Architecture
version: 1.0
created: 2026-04-06
updated: 2026-04-07
---

# Source Code Layout

> For guidance on completing this document, see the
> [Source Code Layout Guide](/process-framework/guides/00-setup/source-code-layout-guide.md)

## Fixed Rules

These rules are prescribed by the framework and apply to all projects:

1. **No application source files at repository root** — all source code lives in
   the dedicated source directory
2. **Feature-first organization** — top-level directories within source root
   correspond to features
3. **Shared code in explicit directory** — cross-cutting utilities live in a
   dedicated shared/ directory, not scattered across features
4. **Tests organized by type** — test/ uses type-based subdirectories
   (unit, integration, performance), feature association via test markers
5. **Config at project root** — configuration files live at repository root,
   not inside the source directory
6. **Entry point at source root** — main entry point file lives directly in
   the source directory

## Project Configuration

| Setting | Value |
|---------|-------|
| Source root | [Source Root] |
| Language | [Language] |
| Directory naming | [Directory Naming Convention] |
| File naming | [File Naming Convention] |
| Shared directory | [Shared Directory Name] |

## Directory Tree

> **Auto-generated** — this section is maintained by `New-SourceStructure.ps1 -Update`.
> Do not edit manually. Run the script after any directory structure change.

```
[Source Root]/
  [feature_directory_1]/
  [feature_directory_2]/
  shared/
  [entry_point_file]
```

## Dependency Flow

> Which directories may import from which. Feature directories may import
> from shared/ but not from other feature directories without documented
> rationale.

```
shared/ <── all feature directories may import from here
  ^
[foundation_feature]/ <── features providing infrastructure others depend on
  ^
[data_layer_feature]/ <── features managing data access
  ^
  ├── [feature_a]/
  ├── [feature_b]/
  └── [feature_c]/ <── also imports from [feature_a] ([documented rationale])
```

**Import rules:**

| Directory | May import from |
|-----------|----------------|
| `shared/` | standard library only |
| `[foundation_feature]/` | `shared/` |
| `[data_layer_feature]/` | `shared/`, `[foundation_feature]/` |
| `[feature_a]/` | `shared/`, `[foundation_feature]/`, `[data_layer_feature]/` |
| `[feature_b]/` | `shared/`, `[foundation_feature]/`, `[data_layer_feature]/` |
| `[feature_c]/` | `shared/`, `[foundation_feature]/`, `[data_layer_feature]/`, `[feature_a]/` |

## File Placement Decision Tree

> "I'm creating a new file for feature X — where does it go?"
> See the [Source Code Layout Guide](/process-framework/guides/00-setup/source-code-layout-guide.md)
> for general guidance.

```
Is this a cross-cutting utility (formatting, constants, shared helpers)?
  YES -> [Source Root]/shared/
  NO  -> Is it infrastructure (config, error handling, logging)?
    YES -> [Source Root]/[foundation_feature]/
    NO  -> Is it data access management (connections, migrations, schema)?
      YES -> [Source Root]/[data_layer_feature]/
      NO  -> Does it belong to a specific business feature?
        YES -> Is that feature directory sublayered?
          YES -> Place in the appropriate layer:
                - Database models/repositories -> {feature}/data/
                - Business logic/services      -> {feature}/services/
                - UI components/views          -> {feature}/ui/
          NO  -> Place directly in [Source Root]/{feature}/
        NO  -> Is it a developer utility script?
          YES -> [Source Root]/[developer_tools]/ (or scripts/ if shell script)
          NO  -> Is it the main entry point?
            YES -> [Source Root]/[entry_point_file]
            NO  -> Ask: should this be a new feature or part of shared/?
```

**Current file-to-feature mapping** (complete during onboarding or after migration):

| Current location | Target location | Feature |
|-----------------|----------------|---------|
| _Fill in during Codebase Feature Discovery or implementation_ | | |

## Scale Transition Notes

> Document when sublayers were added within feature directories and why.
> See the [Source Code Layout Guide](/process-framework/guides/00-setup/source-code-layout-guide.md#scale-transition-criteria)
> for the entry format.

No sublayer transitions yet.
