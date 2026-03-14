---
id: PD-TDD-026
type: Product Documentation
category: Technical Design Document
version: 1.0
created: 2026-02-20
updated: 2026-03-13
feature_id: 2.2.1
feature_name: Link Updating
consolidates: [2.2.1-2.2.5]
tier: 2
retrospective: true
---

# Link Updater - Technical Design Document (Tier 2)

> **Retrospective Document**: This TDD describes the existing implemented architecture of the LinkWatcher Link Updater, documented after implementation during framework onboarding (PF-TSK-066).
>
> **Source**: Derived from source code analysis of `linkwatcher/updater.py` and `linkwatcher/path_resolver.py`.
>
> **Scope Note**: This feature consolidates old 2.2.1 (Link Updater) with all sub-features: 2.2.2 (Relative Path Calculation), 2.2.3 (Anchor Preservation), 2.2.4 (Dry Run Mode), and 2.2.5 (Backup Creation).

## Technical Overview

The `LinkUpdater` class orchestrates all file modifications when referenced files move. It implements a four-phase pipeline: (1) group references by containing file, (2) sort references bottom-to-top within each file, (3) detect stale references (line out of bounds or target not found on expected line), (4) apply replacements via `_replace_in_line()` dispatcher and write atomically. Each file update returns an `UpdateResult` enum (`UPDATED`, `STALE`, or `NO_CHANGES`). Path resolution is delegated to the `PathResolver` class (`linkwatcher/path_resolver.py`). The class exposes two safety flags (`dry_run`, `backup_enabled`) as instance attributes and returns accumulated statistics including a `stale_files` list.

## Component Architecture

### LinkUpdater Class

**Location**: `linkwatcher/updater.py`

**Constructor**: `__init__(self, project_root: str = ".")`

Initializes `backup_enabled = True`, `dry_run = False` as instance attributes (not constructor parameters). Creates a `PathResolver` instance internally.

**Public API**:
- `update_references(references, old_path, new_path)` — Main entry point; returns statistics dict with keys `files_updated`, `references_updated`, `errors`, and `stale_files` (list of file paths where stale references were detected)
- `set_dry_run(enabled)` — Toggle dry-run mode at runtime
- `set_backup_enabled(enabled)` — Toggle backup creation at runtime

**Internal Methods**:
- `_group_references_by_file(references)` — Groups `LinkReference` list into `Dict[str, List[LinkReference]]` keyed by containing file path
- `_update_file_references(file_path, refs, old_path, new_path)` — Processes one file: read → sort → detect stale → replace → write. Returns `UpdateResult` enum (`UPDATED`, `NO_CHANGES`, or `STALE`)
- `_calculate_new_target(ref, old_path, new_path)` — Delegates to `PathResolver.calculate_new_target()`
- `_replace_in_line(line, ref, new_target)` — Dispatcher: routes to type-specific replacement method based on `ref.link_type`
- `_replace_markdown_target(line, ref, new_target)` — Replaces markdown inline link target `[text](old)` → `[text](new)`; when link text exactly matches `ref.link_target`, text is also updated to `new_target` (PD-BUG-012)
- `_replace_reference_target(line, ref, new_target)` — Replaces markdown reference-style link target
- `_replace_at_position(line, ref, new_target)` — Column-offset replacement for non-markdown link types; includes special handling for `python-import` (replaces dot-notation `link_text`) and quoted types (`python-quoted`, `markdown-quoted`, `html-anchor`)
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

### UpdateResult Enum

**Location**: `linkwatcher/updater.py`

```python
class UpdateResult(Enum):
    UPDATED = "updated"      # File was modified successfully
    STALE = "stale"          # Stale references detected — file NOT modified
    NO_CHANGES = "no_changes" # No changes needed
```

Returned by `_update_file_references()` and used by `update_references()` to populate statistics (including `stale_files` list).

### Stale Detection

Before replacing a reference, `_update_file_references()` performs two stale checks:
1. **Line index out of bounds** — `ref.line_number` exceeds file length → `STALE`
2. **Target not found on line** — `ref.link_target` not present on the expected line. Special case: for `python-import` type, falls back to checking `ref.link_text` (dot-notation) on the line. If `new_target` is already present, the reference is skipped (already handled by an earlier replacement).

When stale is detected, the file is NOT modified and `UpdateResult.STALE` is returned.

### Data Flow

```
update_references(refs, old, new)
  │
  ├── _group_references_by_file(refs) → Dict[file, List[ref]]
  │
  └── for each file:
       ├── _update_file_references() → UpdateResult
       │    ├── read file content
       │    ├── sort refs descending (line_number, column_start)
       │    ├── for each ref:
       │    │    ├── _calculate_new_target() → new_target
       │    │    ├── stale detection (line bounds + content check)
       │    │    │    └── if stale → return UpdateResult.STALE
       │    │    └── _replace_in_line(line, ref, new_target)
       │    │         ├── "markdown" → _replace_markdown_target()
       │    │         ├── "markdown-reference" → _replace_reference_target()
       │    │         └── default → _replace_at_position()
       │    │              └── "python-import" → replace dot-notation link_text
       │    └── _write_file_safely(file_path, modified_content)
       │         ├── create .linkwatcher.bak (if backup_enabled)
       │         ├── write to NamedTemporaryFile (same directory)
       │         └── shutil.move(temp → original)  [atomic rename]
       │
       └── update stats based on UpdateResult:
            ├── UPDATED → files_updated++, references_updated += count
            ├── STALE → stale_files.append(file_path)
            └── NO_CHANGES → debug log only
```

## Key Technical Decisions

### Bottom-to-Top Sort Order

References are sorted by `(line_number, column_start)` in descending order before replacement. This ensures that modifying a later reference in the file never shifts the character positions of earlier, not-yet-processed references. Without this, multi-reference files would require costly position recalculation after each edit.

### Atomic Write via Temp File

`_write_file_safely()` writes to a `NamedTemporaryFile` in the same directory as the target file, then uses `shutil.move()` to atomically replace the original. Because temp and target are on the same filesystem, `shutil.move()` performs an OS-level atomic rename. At no point does a partial file exist on disk.

### Link-Type Dispatch

The `_replace_in_line()` method dispatches to type-specific replacement methods based on `ref.link_type`:
- `"markdown"` → `_replace_markdown_target()` — regex-aware replacement preserving `[text](target)` structure
- `"markdown-reference"` → `_replace_reference_target()` — regex-aware replacement preserving `[label]: target` structure
- All others → `_replace_at_position()` — column-offset slicing; special cases for `"python-import"` (replaces dot-notation `link_text` instead of `link_target`) and quoted types (`"python-quoted"`, `"markdown-quoted"`, `"html-anchor"` — preserves surrounding quotes)

This prevents incorrect modifications when the target string appears elsewhere in the line.

## Dependencies

### Internal Dependencies

| Component | Usage | Import |
|-----------|-------|--------|
| `linkwatcher.models.LinkReference` | Input data type (line_number, column_start, link_type, link_target, link_text) | Direct import |
| `linkwatcher.path_resolver.PathResolver` | Path resolution and new target calculation | Direct import |
| `linkwatcher.logging.get_logger` | Structured logging | Direct import |

### External Dependencies

| Package | Usage |
|---------|-------|
| `re` (stdlib) | Regex-based markdown link replacement |
| `shutil` (stdlib) | `shutil.move()` for atomic file replacement, `shutil.copy2()` for backups |
| `tempfile` (stdlib) | `NamedTemporaryFile()` for safe writes |
| `enum` (stdlib) | `UpdateResult` enum definition |
| `colorama` (external) | Colored console output for dry-run messages |
| `os`, `pathlib` (stdlib) | Path calculations and file operations |
