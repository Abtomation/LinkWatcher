---
id: PD-TDD-026
type: Product Documentation
category: Technical Design Document
version: 1.0
created: 2026-02-20
updated: 2026-02-20
feature_id: 2.2.1
feature_name: Link Updater
tier: 2
retrospective: true
---

# Link Updater - Technical Design Document (Tier 2)

> **Retrospective Document**: This TDD describes the existing implemented architecture of the LinkWatcher Link Updater, documented after implementation during framework onboarding (PF-TSK-066).
>
> **Source**: Derived from [2.2.1 Implementation State](../../../../process-framework/state-tracking/features/2.2.1-link-updater-implementation-state.md) and source code analysis of `linkwatcher/updater.py`.

## Technical Overview

The `LinkUpdater` class orchestrates all file modifications when referenced files move. It implements a three-phase pipeline: (1) group references by containing file, (2) sort references bottom-to-top within each file, (3) apply replacements via link-type-specific methods and write atomically. The class exposes two safety flags (`dry_run`, `backup_enabled`) and returns accumulated statistics.

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
- `_calculate_new_target(containing_file, old_path, new_path, original_target)` — Computes new relative path from containing file to new location, preserving anchors
- `_replace_markdown_target(line, ref, new_target)` — Replaces markdown inline link target `[text](old)` → `[text](new)`
- `_replace_reference_target(line, ref, new_target)` — Replaces markdown reference-style link target
- `_replace_at_position(line, ref, new_target)` — Generic column-offset replacement for non-markdown link types
- `_write_file_safely(file_path, content)` — Atomic write: backup (if enabled) → NamedTemporaryFile → shutil.move()

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
| `linkwatcher.logging.get_logger` | Structured logging | Direct import |
| `linkwatcher.logging.LogTimer` | Performance timing | Direct import |

### External Dependencies

| Package | Usage |
|---------|-------|
| `shutil` (stdlib) | `shutil.move()` for atomic file replacement |
| `tempfile` (stdlib) | `NamedTemporaryFile()` for safe writes |
| `colorama` (external) | Colored console output for update messages |
| `os`, `pathlib` (stdlib) | Path calculations and file operations |
