---
id: PD-TDD-026
type: Product Documentation
category: Technical Design Document
version: 1.0
created: 2026-02-20
updated: 2026-02-20
feature_id: 2.2.1
feature_name: Link Updating
consolidates: [2.2.1-2.2.5]
tier: 2
retrospective: true
---

# Link Updater - Technical Design Document (Tier 2)

> **Retrospective Document**: This TDD describes the existing implemented architecture of the LinkWatcher Link Updater, documented after implementation during framework onboarding (PF-TSK-066).
>
> **Source**: Derived from source code analysis of `linkwatcher/updater.py`.
>
> **Scope Note**: This feature consolidates old 2.2.1 (Link Updater) with all sub-features: 2.2.2 (Relative Path Calculation), 2.2.3 (Anchor Preservation), 2.2.4 (Dry Run Mode), and 2.2.5 (Backup Creation).

## Technical Overview

The `LinkUpdater` class orchestrates all file modifications when referenced files move. It implements a three-phase pipeline: (1) group references by containing file, (2) sort references bottom-to-top within each file, (3) apply replacements via link-type-specific methods and write atomically. Path resolution is delegated to the `PathResolver` class (`linkwatcher/path_resolver.py`). The class exposes two safety flags (`dry_run`, `backup_enabled`) and returns accumulated statistics.

## Component Architecture

### LinkUpdater Class

**Location**: `linkwatcher/updater.py`

**Constructor**: `__init__(self, project_root, dry_run=False, backup_enabled=True)`

**Public API**:
- `update_references(references, old_path, new_path)` — Main entry point; returns statistics dict
- `set_dry_run(enabled)` — Toggle dry-run mode at runtime
- `set_backup_enabled(enabled)` — Toggle backup creation at runtime

**Internal Methods**:
- `_group_references_by_file(references)` — Groups `LinkReference` list into `Dict[str, List[LinkReference]]` keyed by containing file path
- `_update_file_references(file_path, refs, old_path, new_path)` — Processes one file: read → sort → replace → write
- `_calculate_new_target(ref, old_path, new_path)` — Delegates to `PathResolver.calculate_new_target()`
- `_replace_markdown_target(line, ref, new_target)` — Replaces markdown inline link target `[text](old)` → `[text](new)`; when link text exactly matches `ref.link_target`, text is also updated to `new_target` (PD-BUG-012)
- `_replace_reference_target(line, ref, new_target)` — Replaces markdown reference-style link target
- `_replace_at_position(line, ref, new_target)` — Generic column-offset replacement for non-markdown link types
- `_write_file_safely(file_path, content)` — Atomic write: backup (if enabled) → NamedTemporaryFile → shutil.move()

### PathResolver Class

**Location**: `linkwatcher/path_resolver.py`

**Constructor**: `__init__(self, project_root, logger=None)`

**Public API**:
- `calculate_new_target(ref, old_path, new_path)` — Computes new target path for a reference, preserving anchors and link style

**Internal Methods**:
- `_calculate_new_target_relative(original_target, old_path, new_path, source_file)` — Multi-strategy path matching and conversion
- `_match_direct(absolute_target_norm, old_path_norm)` — Direct path equality check
- `_match_stripped(absolute_target_norm, old_path_norm)` — Match after stripping leading slashes
- `_match_resolved(absolute_target_norm, old_path_norm, source_file, link_info)` — Resolve-relative and filename-only fallback match
- `_analyze_link_type(target, source_file)` — Classify link as absolute, relative-explicit, or filename-only
- `_resolve_to_absolute_path(target, source_file, link_info)` — Convert link target to absolute path for comparison
- `_convert_to_original_link_type(new_absolute_path, source_file, link_info)` — Convert absolute path back to original link style
- `_calculate_relative_path_between_files(source_file, target_file)` — Calculate relative path between two files
- `_calculate_new_python_import(original_target, old_path, new_path)` — Python import path resolution

### Data Flow

```
update_references(refs, old, new)
  │
  ├── _group_references_by_file(refs) → Dict[file, List[ref]]
  │
  └── for each file:
       ├── read file content
       ├── sort refs descending (line_number, column_start)
       ├── for each ref:
       │    ├── _calculate_new_target() → new_target
       │    └── dispatch by link_type:
       │         ├── "markdown_link" → _replace_markdown_target()
       │         ├── "markdown_reference" → _replace_reference_target()
       │         └── default → _replace_at_position()
       └── _write_file_safely(file_path, modified_content)
            ├── create .linkwatcher.bak (if backup_enabled)
            ├── write to NamedTemporaryFile (same directory)
            └── shutil.move(temp → original)  [atomic rename]
```

## Key Technical Decisions

### Bottom-to-Top Sort Order

References are sorted by `(line_number, column_start)` in descending order before replacement. This ensures that modifying a later reference in the file never shifts the character positions of earlier, not-yet-processed references. Without this, multi-reference files would require costly position recalculation after each edit.

### Atomic Write via Temp File

`_write_file_safely()` writes to a `NamedTemporaryFile` in the same directory as the target file, then uses `shutil.move()` to atomically replace the original. Because temp and target are on the same filesystem, `shutil.move()` performs an OS-level atomic rename. At no point does a partial file exist on disk.

### Link-Type Dispatch

The updater dispatches to type-specific replacement methods rather than using generic string replacement. This prevents incorrect modifications when the target string appears elsewhere in the line. Markdown inline links use regex-aware replacement; generic types use exact column-offset slicing.

## Dependencies

### Internal Dependencies

| Component | Usage | Import |
|-----------|-------|--------|
| `linkwatcher.models.LinkReference` | Input data type (line_number, column_start, link_type, link_target) | Direct import |
| `linkwatcher.path_resolver.PathResolver` | Path resolution and new target calculation | Direct import |
| `linkwatcher.logging.get_logger` | Structured logging | Direct import |
| `linkwatcher.logging.LogTimer` | Performance timing | Direct import |

### External Dependencies

| Package | Usage |
|---------|-------|
| `shutil` (stdlib) | `shutil.move()` for atomic file replacement |
| `tempfile` (stdlib) | `NamedTemporaryFile()` for safe writes |
| `colorama` (external) | Colored console output for update messages |
| `os`, `pathlib` (stdlib) | Path calculations and file operations |
