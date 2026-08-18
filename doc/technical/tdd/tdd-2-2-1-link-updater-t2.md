---
id: PD-TDD-026
description: "2.2.1 Tier 2 — Bottom-to-top atomic write strategy"
type: Product Documentation
category: Technical Design Document
version: 1.1
created: 2026-02-20
updated: 2026-07-06
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

**Constructor**: `__init__(self, project_root: str = ".", python_source_root: str = "", path_resolution_overrides: Optional[Dict[str, str]] = None)`

Initializes `backup_enabled = True`, `dry_run = False` as instance attributes (not constructor parameters). Creates a `PathResolver` instance internally, passing `python_source_root` through for Python import path resolution (PD-BUG-078) and `path_resolution_overrides` through for virtual-root resolution in override folders (v1.1 — see [Override-Aware Path Resolution](#override-aware-path-resolution-v11)). `path_resolution_overrides` is a passthrough only; `LinkUpdater` does not interpret it.

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

**Constructor**: `__init__(self, project_root, logger=None, python_source_root: str = "", path_resolution_overrides: Optional[Dict[str, str]] = None)`

The constructor normalizes `path_resolution_overrides` once (via the shared `build_resolution_overrides` helper) into a length-sorted folder→base list held on the instance, mirroring how `Validator` holds `self._resolution_overrides`. When the dict is empty or absent, override resolution is a no-op and all behavior is identical to v1.0.

**Public API**:
- `calculate_new_target(ref, old_path, new_path)` — Computes new target path for a reference, preserving anchors and link style

**Internal Methods**:
- `_calculate_new_target_relative(original_target, old_path, new_path, source_file)` — Multi-strategy path matching and conversion
- `_resolution_base_for(source_file)` — (v1.1) Returns the resolution base for *source_file*: the relative base prefix when the file lives under a configured override folder (longest-prefix match), else `""` (project-root-relative, the v1.0 behavior). Delegates the folder-match lookup to the shared helper.
- `_match_direct(absolute_target_norm, old_path_norm)` — Direct path equality check
- `_match_stripped(absolute_target_norm, old_path_norm)` — Match after stripping leading slashes
- `_match_resolved(absolute_target_norm, old_path_norm, source_file, link_info)` — Resolve-relative and filename-only fallback match
- `_analyze_link_type(target, source_file)` — Classify link as absolute, relative-explicit, or filename-only
- `_resolve_to_absolute_path(target, source_file, link_info)` — Convert link target to absolute path for comparison. (v1.1) For an `is_absolute` (`/…`) target from an override-folder source, resolves against the source file's resolution base instead of returning the target verbatim.
- `_convert_to_original_link_type(new_absolute_path, source_file, link_info)` — Convert absolute path back to original link style. (v1.1) For an `is_absolute` target from an override-folder source, strips the resolution base prefix back off so the rebuilt link keeps its virtual-root `/…` style.
- `_apply_separator_style(normalized_path, original_target)` — (PD-BUG-112) Re-applies the authored separator style so backslashes survive normalization
- `utils.apply_trailing_separator_style(result, original_target)` — (PD-BUG-118; promoted from a `PathResolver` static method to shared `utils` by PD-BUG-120, 2026-08-17) Re-appends an authored trailing separator that `normalize_path()` stripped, so a directory reference written as `doc/x/` is not rewritten as `doc/x`. Applied once at the `calculate_new_target` choke point so every match branch (and the anchor path) is covered. Sibling of `_apply_separator_style` above and of the authored-form guard in `reference_lookup._calculate_updated_relative_path`: a rewrite changes *where* a target points, never how it was written. Preserves a genuine trailing `..` segment. Shared rather than duplicated because the **second** recalculation path needed the same rule (PD-BUG-120); the restored separator follows the *result's* own style, falling back to the original's — `PathResolver` renders the result in the original's style before calling it (`_apply_separator_style`), so it is unaffected, while `ReferenceLookup`'s always-forward-slash output would otherwise gain a mixed form like `../doc/x\`.
- `_calculate_relative_path_between_files(source_file, target_file)` — Calculate relative path between two files
- `_calculate_new_python_import(original_target, old_path, new_path)` — Python import path resolution

### Shared Resolution-Override Helper (v1.1)

**Location**: `src/linkwatcher/resolution_overrides.py` (new module)

Extracted from `validator.py` so `Validator` and `PathResolver` share one virtual-root algorithm and cannot drift. Pure functions, no I/O:

- `build_resolution_overrides(raw: Optional[Dict[str, str]]) -> List[Tuple[str, str]]` — Normalizes the configured folder→base map to forward slashes, strips leading/trailing slashes, drops empty folders, and sorts by descending folder length so the first prefix match is the most specific. (Lifted verbatim from `Validator._build_resolution_overrides`.)
- `resolution_base_for_rel(overrides, source_rel: str) -> str` — Given a project-root-relative source path, returns the matching base (relative string, possibly `""`) via longest-prefix match, or `""` when no folder matches.

`Validator` retains its thin `_resolution_base_for` wrapper (absolute-base form + its existing `validation_resolution_override_applied` log event); `PathResolver` adds its own thin `_resolution_base_for` wrapper (relative-base form + a new `update_resolution_override_applied` log event). The normalization and folder-match logic live once in the shared module — this is a behavior-preserving extraction for `validator.py` (verified by its existing validate suite).

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

## Override-Aware Path Resolution (v1.1)

> **Added in v1.1 (2026-06-29)** — blueprint-aware reference updating enhancement (PF-STA-110). Extends `path_resolution_overrides` virtual-root resolution — previously honoured only by validation (`--validate`) — into the live move/update path. Functional behavior is in [PD-FDD-027 § Override-Folder Reference Maintenance](../../functional-design/fdds/fdd-2-2-1-link-updater.md).

### Problem

Files in an override folder (canonically the `process-framework/` blueprint) write host-absolute (`/…`) references against a *virtual* rollout-destination root, not their on-disk location. `path_resolution_overrides` maps such a folder to a resolution **base**: a `/…` link in a source under folder `F` resolves against `<project_root>/<base>/`. The validator honoured this; `PathResolver` did not. In `_calculate_new_target_relative`, an `is_absolute` target was returned **verbatim** by `_resolve_to_absolute_path` (e.g. `/process-framework/tasks/foo.md`), while the moved file's `old_path` arrives project-root-relative with the override-folder prefix (e.g. `process-framework/process-framework/tasks/foo.md` on disk). The match strategies therefore never fired, and references to a file moved/renamed inside an override folder were left broken — defeating LinkWatcher's founding blueprint-restructuring use case.

### Resolution Base (per source file)

`PathResolver._resolution_base_for(source_file)` returns the **relative** base for the source file via the shared helper: the configured base string when the file is under an override folder (longest-prefix match), else `""`. `""` means project-root-relative — identical to v1.0 — so files outside every configured folder are unaffected. The base is computed once per source file, not per reference (PE consideration).

### Input: base-aware resolution (`_resolve_to_absolute_path`)

For an `is_absolute` (`/…`) target whose source has a non-empty resolution base, resolve to the comparison form `"<base>/" + target.lstrip("/")` (normalized, forward-slash, root-relative) instead of returning the `/…` target verbatim. With base `process-framework`, `/process-framework/tasks/foo.md` → `process-framework/process-framework/tasks/foo.md`, which now equals the moved file's `old_path` so `_match_direct` / `_match_stripped` fire. An empty base leaves the v1.0 verbatim behavior intact.

### Output: base-stripping reconstruction (`_convert_to_original_link_type`)

On a match, the new absolute path is the moved file's new on-disk location (e.g. `process-framework/tasks/foo-renamed.md` carrying the base prefix). For an `is_absolute` target from an override source, strip the resolution base back off and re-prepend `/`: `"/" + new_path_norm.removeprefix(base + "/")` → `/process-framework/tasks/foo-renamed.md`. This preserves the virtual-root style rather than emitting a full on-disk `/…` path or a relative path. Separator-style reconstruction (the existing `\`-preservation) is unchanged.

### Interaction with existing strategies and guards

- **Early-exit branches skipped for virtual-root links (anti-hijack)**: The two early-exit branches in `_calculate_new_target_relative` (direct equality, directory-prefix) compare the *unresolved* normalized target against `old_path`. For an override-source `/…` link that comparison is semantically wrong — the link denotes `<base>/…`, so when a **real root-level path coincides with the virtual path** (e.g. a root `test/x.md` moves while a blueprint link says `/test/x.md`), the early exit would hijack the virtual-root link and rewrite it against the wrong file. v1.1 therefore skips both early-exit branches when the source has a non-empty resolution base and the target is host-absolute (`is_virtual_root_link`); together with the gated PD-BUG-045 suffix block (next bullet), Step-3 base-aware resolution is the only match path for virtual-root links. (Found by the Step-13 quality audit; regression-tested by the "not hijacked by coinciding root move/dir move" cases.)
- **PD-BUG-045 suffix match (gated for virtual-root links)**: The inline suffix-match block compares the *unresolved* link form against `old_path`, exactly like the early exits — so it remained reachable for a virtual-root link whenever Step-3 base-aware resolution found no match (the link's true `<base>/…` target did not move) while an unrelated suffix-coinciding file did move, rewriting the link to the wrong target and dropping the virtual-root style (2026-07-06 code-review Major finding). The block is therefore gated on `not is_virtual_root_link`; it remains in place unchanged for the genuine nested-project case it was built for. Regression-tested by the "not hijacked by suffix-coinciding move" case.
- **PD-BUG-095 / PD-BUG-112 disk-existence & separator guards (retained)**: The override match resolves through the `_match_* → _convert_to_original_link_type` path. A disk-existence containment check (`path_exists_under_root` on the resolved override target) is applied on this path so a `/…` reference whose base-resolved target does not exist on disk is left unchanged — the same protection the early-exit branches already give regex/glob-shaped strings. The match itself is anchored on equality with a real moved `old_path`, so it cannot fire on a non-existent target.
- **SE / path-traversal containment**: The base is config-supplied. The shared helper normalizes it (forward slashes, stripped) and `os.path.normpath` collapses any `..`; the resolved base and resolved target are required to stay under `project_root` (`path_exists_under_root` containment). A crafted base or a `../`-bearing link cannot resolve outside the project root.

### Scope boundary (intentionally unchanged)

Override-awareness covers references **to** a moved file expressed as host-absolute `/…` links **from sibling files**. The separate path that fixes relative links **inside** a moved file (`reference_lookup._filter_relative_links`) is **not** changed — those are relative links resolved against the moved file's own directory, to which the virtual-root override does not apply.

## Simultaneous-Move Repair (PD-BUG-114, 2026-08-10)

The within-moved-file recalculation path (`reference_lookup.update_links_within_moved_file` → `_calculate_updated_relative_path`) carries a repair layer for links whose **target moved in the same operation** as the file containing them. Without it, the PD-BUG-033 existence guard — which resolves each outgoing link against the moved file's OLD directory and skips targets missing from disk — silently dropped such links, and the target's own move event could not repair them afterwards (either `find_references` missed the re-indexed stale link, or the updater hit the referencing file's already-vacated old path).

- **Move memory**: `ReferenceLookup.record_move(old, new)` keeps a 300-second-TTL map of processed moves (TTL matches the `DirectoryMoveDetector` window; destination chains are followed for twice-moved files). The handler records every single-file move at the top of `_handle_file_moved` (covering self-links) and every per-file mapping plus the directory itself in `_handle_directory_moved` Phase 0.
- **Guard consult**: when the existence guard finds the old-resolved target missing, it consults the move memory. On a hit whose new target exists on disk, the link is rewritten to the target's new location (fragment preserved) and `link_target_move_applied` is logged at info; a hit whose mapped target is also gone logs `link_target_move_stale` at warning and leaves the link unchanged.
- **Pending recalcs**: a guard miss registers the skipped link under its resolved old target (`link_recalc_pending`, debug — non-path strings land here harmlessly and expire with the TTL). When a later move event's old path matches a pending key, `apply_pending_recalcs()` re-runs the moved-file recalculation for the recorded files (`pending_link_recalc_applied`, info) — the handler invokes it after single-file processing and as Phase 1.6 of directory moves.
- **Thread safety (PD-BUG-119, 2026-08-17)**: the move memory is the first cross-event mutable state on `ReferenceLookup`, and the class is shared by **two** threads — the watchdog observer thread (`_handle_file_moved`) and the `DirectoryMoveDetector` worker thread (`_handle_directory_moved`, started as a daemon thread in `dir_move_detector._trigger_processing`) — because `handler.on_moved` does not serialize move processing. Both dicts are therefore guarded by a single non-reentrant `_move_memory_lock`, matching the lock-guarded-shared-state pattern every other component here already follows. Two constraints define the design: the prune, the chain read-modify-write and the record in `record_move` are **one** critical section (splitting them is what allowed a concurrent insert to raise `RuntimeError: dictionary changed size during iteration` mid-prune, abandoning the whole move update), and `setdefault` + store in `_register_pending_recalc` are likewise one section (splitting them let a concurrent `apply_pending_recalcs` pop leave the store in an orphaned dict, losing the deferred repair silently). Conversely the lock is **never** held across file I/O or across `apply_pending_recalcs`' repair callback — that callback re-enters `_lookup_recent_move` / `_register_pending_recalc` through the link recalculation, so holding a non-reentrant lock there deadlocks the daemon. `_prune_move_memory` is a caller-holds-the-lock helper and does not acquire. Any new cross-event mutable state added to this class needs the same treatment.
- **Same-directory renames** run the full recalculation (the former early return is removed) so a vanished target reaches this repair.
- **Authored trailing separator on rewritten links (PD-BUG-120, 2026-08-17)**: the authored-form guard below only protects links that still resolve unchanged; a link that legitimately *is* rewritten returned raw `os.path.relpath` output, which drops a trailing separator — `doc/x/` came back as `../doc/x`. `_calculate_updated_relative_path` therefore applies the shared `utils.apply_trailing_separator_style` to the recalculated path at both return points (covering all three producing sites: the move-memory `relpath` branch, the move-memory root-destination branch, and the main branch) and *before* the `#fragment` is reattached, since the separator belongs to the path, not after the anchor. Same rule as PD-BUG-118 on the sibling path, reached through a different function — `PathResolver`'s choke point never sees these links.
- **Authored-form preservation (semantic, not textual, recalculation)**: before recalculating, `_calculate_updated_relative_path` resolves the link *as authored* against the file's new directory; if that already equals the intended target, the original string is returned untouched. This is what keeps unmoved targets from being rewritten. The guard is required because `os.path.relpath` returns a **canonical** path, so without it the removal of the same-directory early return would reformat every non-canonical link that was never wrong — `./x` → `x`, `..\x` → `../x`, `dir/` → `dir` — on every in-place rename. Rewrites therefore occur only when the as-authored link no longer resolves to its target from the new location. (Added by the PD-BUG-114 code review, 2026-08-10; an earlier draft of this section asserted the no-write property held without such a guard, which was incorrect.)

### Wiring

`path_resolution_overrides` threads from config through the existing constructor chain, mirroring `python_source_root`: `service.py` (`LinkUpdater(..., path_resolution_overrides=config.path_resolution_overrides)`) → `LinkUpdater.__init__` (passthrough) → `PathResolver.__init__` (normalize + hold). The `path_resolution_overrides` config key already exists (0.1.3 Configuration System); no schema change.

### Observability

`PathResolver` emits a distinct `update_resolution_override_applied` log event when override resolution rewrites a host-absolute reference, mirroring the validator's `validation_resolution_override_applied`, so blueprint rewrites are auditable and a misconfigured base is diagnosable.

## Dependencies

### Internal Dependencies

| Component | Usage | Import |
|-----------|-------|--------|
| `linkwatcher.models.LinkReference` | Input data type (line_number, column_start, link_type, link_target, link_text) | Direct import |
| `linkwatcher.path_resolver.PathResolver` | Path resolution and new target calculation | Direct import |
| `linkwatcher.resolution_overrides` | (v1.1) Shared virtual-root override normalization/lookup, consumed by both `PathResolver` and `Validator` | Direct import |
| `linkwatcher.logging.get_logger` | Structured logging | Direct import |

### External Dependencies

| Package | Usage |
|---------|-------|
| `re` (stdlib) | Regex-based markdown link replacement |
| `shutil` (stdlib) | `shutil.move()` for atomic file replacement, `shutil.copy2()` for backups |
| `tempfile` (stdlib) | `NamedTemporaryFile()` for safe writes |
| `enum` (stdlib) | `UpdateResult` enum definition |
| `os`, `pathlib` (stdlib) | Path calculations and file operations |
