---
id: PD-ARC-001
type: Process Framework
category: Architecture
version: 1.1
created: 2026-04-06
updated: 2026-05-06
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
| Source root | `src/linkwatcher` |
| Language | Python |
| Directory naming | `snake_case` |
| File naming | `snake_case` |
| Shared directory | _none — flat module layout (see Note below)_ |
| Executable entry point | `main.py` (at repo root, see Note below) |

**Note on Fixed Rules deviations:** LinkWatcher predates this layout doc and uses a flat
module structure rather than the framework's prescribed feature-first organization with
a dedicated `shared/` directory. Two specific deviations:

1. **Rule 3 (Shared code in explicit directory):** No `shared/` directory exists.
   Cross-cutting helpers (`utils.py`, `models.py`, `link_types.py`, `logging.py`) live
   directly in `src/linkwatcher/` as foundation modules. The `parsers/` and `config/`
   subdirectories group cohesive module families, not features.
2. **Rule 6 (Entry point at source root):** The executable entry point is `main.py`
   at the repository root (next to `setup.py`), not inside `src/linkwatcher/`. This
   is the standard `src/`-layout Python convention — `src/linkwatcher/` is an importable
   package, not an executable directory.

These deviations are documented for clarity. New code should follow the actual structure
described below rather than the framework template's feature-first defaults.

## Directory Tree

> **Auto-generated** — this section is maintained by `New-SourceStructure.ps1 -Update`.
> Do not edit manually. Run the script after any directory structure change.

```
src/linkwatcher/
  config/
    __init__.py
    defaults.py
    settings.py
  parsers/
    __init__.py
    base.py
    dart.py
    generic.py
    json_parser.py
    markdown.py
    patterns.py
    powershell.py
    python.py
    yaml_parser.py
  __init__.py
  database.py
  dir_move_detector.py
  handler.py
  link_types.py
  logging_config.py
  logging.py
  models.py
  move_detector.py
  parser.py
  path_resolver.py
  reference_lookup.py
  service.py
  updater.py
  utils.py
  validator.py
```

## Dependency Flow

> LinkWatcher uses a flat-module layered architecture. Modules are organized by layer
> (foundation → infrastructure → orchestration), not by feature. Imports flow upward
> through the layers; no cycles.

```
Layer 1 — Foundation (no internal imports)
  logging.py, models.py, utils.py, link_types.py, move_detector.py
  ^
Layer 2 — Infrastructure (depend on foundation only)
  config/, database.py, dir_move_detector.py, path_resolver.py, parsers/
  ^
Layer 3 — Domain (depend on foundation + infrastructure)
  parser.py, updater.py, validator.py, reference_lookup.py
  ^
Layer 4 — Orchestration (depend on all lower layers)
  handler.py, service.py
```

**Import rules:**

| Layer / Module | May import from |
|----------------|----------------|
| Layer 1 (foundation modules) | standard library + third-party only |
| `config/` | standard library + third-party only |
| `database.py`, `dir_move_detector.py` | Layer 1 |
| `path_resolver.py`, `parsers/` | Layer 1 |
| `parser.py` | Layer 1, `config/`, `parsers/` |
| `updater.py` | Layer 1, `path_resolver.py` |
| `validator.py` | Layer 1, `config/`, `parser.py` |
| `reference_lookup.py` | Layer 1, `database.py`, `parser.py`, `updater.py` |
| `handler.py` | Layer 1, `config/`, `database.py`, `dir_move_detector.py`, `move_detector.py`, `parser.py`, `reference_lookup.py`, `updater.py` |
| `service.py` | Layer 1, `config/`, `database.py`, `handler.py`, `parser.py`, `parsers/`, `updater.py` |
| `parsers/` submodules | Layer 1, sibling parser modules (`base.py`, `patterns.py`) |

**Note:** `logging_config.py` is a thin wrapper around `logging.py` (only imports from
it) and is positioned with the foundation layer.

## File Placement Decision Tree

> "I'm creating a new module — where does it go?" LinkWatcher's flat structure has
> only two subdirectory groupings (`config/` and `parsers/`); everything else lives
> directly under `src/linkwatcher/`.

```
Is this a new file-format parser (e.g., for a new file type LinkWatcher should monitor)?
  YES -> src/linkwatcher/parsers/{format}.py
         (subclass BaseParser; register in parsers/__init__.py)
  NO  -> Is this configuration data or settings logic?
    YES -> src/linkwatcher/config/{name}.py
    NO  -> Is this an executable entry point or CLI?
      YES -> Repository root (next to main.py, setup.py)
      NO  -> Is this an operational tool (dashboard, monitor, ad-hoc utility)?
        YES -> tools/ at repository root
        NO  -> It is a core module — place directly in src/linkwatcher/
               and assign it to the lowest possible layer (see Dependency Flow).
               If the module would create an import cycle, refactor first.
```

**Current file-to-module mapping:**

| Location | Module purpose |
|----------|---------------|
| `src/linkwatcher/logging.py`, `logging_config.py` | Structured logging system |
| `src/linkwatcher/models.py` | Data classes (`LinkReference`, `FileOperation`) |
| `src/linkwatcher/utils.py` | Path normalization, file-monitoring helpers |
| `src/linkwatcher/link_types.py` | Link classification enums |
| `src/linkwatcher/move_detector.py` | Delete+create correlation for move detection |
| `src/linkwatcher/dir_move_detector.py` | Directory-batch move detection |
| `src/linkwatcher/config/` | Default and user-supplied configuration |
| `src/linkwatcher/database.py` | In-memory link reference database |
| `src/linkwatcher/path_resolver.py` | Relative/absolute path resolution |
| `src/linkwatcher/parsers/` | File-type-specific link parsers |
| `src/linkwatcher/parser.py` | Top-level parser dispatcher |
| `src/linkwatcher/updater.py` | Atomic file modification |
| `src/linkwatcher/validator.py` | Broken-link validation (`--validate` mode) |
| `src/linkwatcher/reference_lookup.py` | Cross-file reference queries |
| `src/linkwatcher/handler.py` | File-system event handler (watchdog integration) |
| `src/linkwatcher/service.py` | Top-level orchestration service |

## Scale Transition Notes

> Document when sublayers were added within feature directories and why.
> See the [Source Code Layout Guide](/process-framework/guides/00-setup/source-code-layout-guide.md#scale-transition-criteria)
> for the entry format.

No sublayer transitions yet.
