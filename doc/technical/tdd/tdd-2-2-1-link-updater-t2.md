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
> **Source**: Derived from source code analysis of `src/linkwatcher/updater.py` and `src/linkwatcher/path_resolver.py`.
>
> **Scope Note**: This feature consolidates old 2.2.1 (Link Updater) with all sub-features: 2.2.2 (Relative Path Calculation), 2.2.3 (Anchor Preservation), 2.2.4 (Dry Run Mode), and 2.2.5 (Backup Creation).

## Technical Overview

The `LinkUpdater` class orchestrates all file modifications when referenced files move. It exposes two entry points: `update_references()` for single file moves, and `update_references_batch()` for multiple simultaneous moves (e.g., directory moves) which groups all references by containing file so each file is opened and written at most once. Both paths delegate per-file work through a shared replacement pipeline (`_apply_replacements()`) that implements: (1) sort references bottom-to-top within each file, (2) detect stale references (line out of bounds or target not found on expected line), (3) apply replacements via `_replace_in_line()` dispatcher and write atomically. Each file update returns an `UpdateResult` enum (`UPDATED`, `STALE`, or `NO_CHANGES`). Path resolution is delegated to the `PathResolver` class (`src/linkwatcher/path_resolver.py`). The class exposes two safety flags (`dry_run`, `backup_enabled`) as instance attributes and returns accumulated statistics including a `stale_files` list.

## Component Architecture

### LinkUpdater Class

**Location**: `src/linkwatcher/updater.py`

**Constructor**: `__init__(self, project_root: str = ".", python_source_root: str = "")`

Initializes `backup_enabled = True`, `dry_run = False` as instance attributes (not constructor parameters). Creates a `PathResolver` instance internally, passing `python_source_root` through for Python import path resolution (PD-BUG-078).

**Public API**:
- `update_references(references, old_path, new_path)` — Single-move entry point; returns statistics dict with keys `files_updated`, `references_updated`, `errors`, and `stale_files` (list of file paths where stale references were detected)
- `update_references_batch(move_groups)` — Batch entry point for multiple simultaneous moves (e.g., directory moves). Accepts `List[Tuple[List[LinkReference], str, str]]` where each tuple is `(references, old_path, new_path)`. Groups all references by containing file so each file is opened, modified, and written at most once — even when many moved files are referenced from the same source file. Returns aggregated `UpdateStats`. Delegates per-file work to `_update_file_references_multi()`
- `set_dry_run(enabled)` — Toggle dry-run mode at runtime
- `set_backup_enabled(enabled)` — Toggle backup creation at runtime

**Internal Methods**:
- `_group_references_by_file(references)` — Groups `LinkReference` list into `Dict[str, List[LinkReference]]` keyed by containing file path
- `_update_file_references(file_path, refs, old_path, new_path)` — Processes one file for a single old→new pair: builds `(ref, new_target)` replacement items, delegates to `_apply_replacements()`. Returns `UpdateResult` enum (`UPDATED`, `NO_CHANGES`, or `STALE`)
- `_update_file_references_multi(file_path, ref_tuples)` — Processes one file for multiple old→new pairs in a single read→modify→write cycle. Accepts `List[Tuple[LinkReference, str, str]]` where each tuple is `(reference, old_path, new_path)`. Computes `new_target` for each move, builds replacement items, delegates to `_apply_replacements()`. Returns `UpdateResult`
- `_calculate_new_target(ref, old_path, new_path)` — Delegates to `PathResolver.calculate_new_target()`
- `_replace_in_line(line, ref, new_target)` — Dispatcher: routes to type-specific replacement method based on `ref.link_type`
- `_replace_markdown_target(line, ref, new_target)` — Replaces markdown inline link target `[text](old)` → `[text](new)`; when link text exactly matches `ref.link_target`, text is also updated to `new_target` (PD-BUG-012)
- `_replace_reference_target(line, ref, new_target)` — Replaces markdown reference-style link target
- `_replace_at_position(line, ref, new_target)` — Column-offset replacement for non-markdown link types; includes special handling for `python-import` (replaces dot-notation `link_text`) and quoted types (`python-quoted`, `markdown-quoted`, `html-anchor`)
- `_write_file_safely(file_path, content)` — Atomic write: backup (if enabled) → NamedTemporaryFile → shutil.move()

### PathResolver Class

**Location**: `src/linkwatcher/path_resolver.py`

**Constructor**: `__init__(self, project_root, logger=None, python_source_root: str = "")`

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

**Location**: `src/linkwatcher/updater.py`

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

#### Single-Move Path

```
update_references(refs, old, new)
  │
  ├── _group_references_by_file(refs) → Dict[file, List[ref]]
  │
  └── for each file:
       ├── _update_file_references(file, refs, old, new) → UpdateResult
       │    ├── build (ref, new_target) replacement items
       │    └── _apply_replacements() → UpdateResult
       │
       └── update stats based on UpdateResult
```

#### Batch Path (Directory Moves)

```
update_references_batch(move_groups)
  │  move_groups = List[(refs, old_path, new_path)]
  │
  ├── flatten all (ref, old, new) tuples, group by ref.file_path
  │   → Dict[file, List[(ref, old_path, new_path)]]
  │
  └── for each file:
       ├── _update_file_references_multi(file, ref_tuples) → UpdateResult
       │    ├── build (ref, new_target) replacement items across all moves
       │    └── _apply_replacements() → UpdateResult
       │
       └── update stats based on UpdateResult
```

#### Shared Replacement Pipeline (`_apply_replacements`)

```
_apply_replacements(abs_file_path, file_path, replacement_items)
  │
  ├── read file content
  ├── sort replacement_items descending (line_number, column_start)
  ├── for each (ref, new_target):
  │    ├── stale detection (line bounds + content check)
  │    │    └── if stale → return UpdateResult.STALE
  │    └── _replace_in_line(line, ref, new_target)
  │         ├── "markdown" → _replace_markdown_target()
  │         ├── "markdown-reference" → _replace_reference_target()
  │         └── default → _replace_at_position()
  │              └── "python-import" → replace dot-notation link_text
  └── _write_file_safely(file_path, modified_content)
       ├── create .bak (if backup_enabled)
       ├── write to NamedTemporaryFile (same directory)
       └── shutil.move(temp → original)  [atomic rename]
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
| `os`, `pathlib` (stdlib) | Path calculations and file operations |
