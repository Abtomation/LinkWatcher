---
id: PD-TDD-026
description: "2.2.1 Tier 2 — Bottom-to-top atomic write strategy"
type: Product Documentation
category: Technical Design Document
version: 1.2
created: 2026-02-20
updated: 2026-08-30
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
- `_replace_in_line(line, ref, new_target)` — (PD-BUG-150 rework, 2026-08-30) Thin delegator to `replacement.replace_in_line()`; the dispatch itself moved to the shared module so the within-moved-file path cannot reach the primitives without it. Routes to the type-specific replacer based on `ref.link_type`
- `_replace_markdown_target(line, ref, new_target)` — Replaces markdown inline link target `[text](old)` → `[text](new)`; when link text exactly matches `ref.link_target`, text is also updated to `new_target` (PD-BUG-012). (PD-BUG-152, 2026-08-31) The pattern also matches the optional whitespace CommonMark permits around the destination — `[x]( old )` — and writes it back verbatim. The parser records `link_target` **stripped**, so without those groups the two juxtapositions the pattern requires (`](` immediately before the target, and the target immediately before a title or `)`) could never hold for a padded link: the substitution matched nothing and the line was returned unchanged, leaving the link pointing at a path that no longer exists. Preserving rather than normalizing the padding follows the PD-BUG-118 / PD-BUG-120 / PD-BUG-124 rule a rewrite changes WHERE a link points, never HOW it was written. (PD-BUG-155, 2026-08-31) The function now iterates two wrapper variants - angle-wrapped then tight - returning on the first that substitutes, so a destination the author enclosed in angle brackets keeps them. The variants cannot be confused: the wrapped pattern requires a literal opening bracket immediately after the link syntax, which no tight destination has, and the tight pattern's whitespace group cannot match that bracket
- `_replace_reference_target(line, ref, new_target)` — Replaces a markdown reference-definition target. (PD-BUG-150 rework, 2026-08-30) Thin delegator to `replacement.replace_reference_target()`. Anchoring on the label is load-bearing, not cosmetic: the parser records this reference's span as the WHOLE definition line, so positional replacement overwrites label and title along with the target
- `_replace_at_position(line, ref, new_target)` — (PD-BUG-150, 2026-08-30) Now a thin delegator to `replacement.replace_at_position()`; the implementation moved to the shared module (see [Shared Replacement Primitives](#shared-replacement-primitives-pd-bug-150) below) so the within-moved-file rewrite path uses the same one. `_filter_contained_overlaps` moved with it, and `_ESCAPABLE_STRUCTURED_TYPES` is now an alias of the module constant. Behaviour is unchanged — the updater's 78 tests pass untouched. Column-offset replacement for non-markdown link types; includes special handling for `python-import` (replaces dot-notation `link_text`) and quoted types (`python-quoted`, `markdown-quoted`, `html-anchor`). (PD-BUG-126, 2026-08-19) When the span covers an **escaped** JSON/YAML source literal — recognized by `link_text` (raw source) differing from `link_target` (decoded value) on a type in `_ESCAPABLE_STRUCTURED_TYPES` — the replacement is re-escaped with `json.dumps(..., ensure_ascii=False)[1:-1]` before splicing, because writing raw text into an escaped string literal is what left files unparseable in the PD-BUG-124 class. `ensure_ascii=False` is load-bearing: the default re-spells non-ASCII as `\uXXXX`, changing HOW a target was written while changing where it points — the same rule `_apply_separator_style` and `apply_trailing_separator_style` enforce
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
- `_apply_separator_style(normalized_path, original_target)` — (PD-BUG-112) Re-applies the authored separator style so backslashes survive normalization. (PD-BUG-124, 2026-08-18) The separator it emits is the author's own backslash *unit* via `utils.authored_backslash_unit()`, not a bare `\`: an escaped-string context (`.py`, and any parser reporting raw spans) authors one separator as `\\`, and halving it re-creates exactly the escape corruption this method exists to prevent — loudly for `\x`, silently for `\n`. Same correction applied in `_convert_to_original_link_type`.
- `utils.apply_trailing_separator_style(result, original_target)` — (PD-BUG-118; promoted from a `PathResolver` static method to shared `utils` by PD-BUG-120, 2026-08-17) Re-appends an authored trailing separator that `normalize_path()` stripped, so a directory reference written as `doc/x/` is not rewritten as `doc/x`. Applied once at the `calculate_new_target` choke point so every match branch (and the anchor path) is covered. Sibling of `_apply_separator_style` above and of the authored-form guard in `reference_lookup._calculate_updated_relative_path`: a rewrite changes *where* a target points, never how it was written. Preserves a genuine trailing `..` segment. Shared rather than duplicated because the **second** recalculation path needed the same rule (PD-BUG-120). (PD-BUG-124, 2026-08-18) The restored separator is the authored one re-appended *verbatim*, escaping included (`utils.trailing_separator_run()`) — targets are spliced back into the file's raw source, where synthesizing a bare `\` for a separator the author wrote as `\\` escapes the closing quote and leaves the file unparseable. A caller that renders in a *fixed* style passes it as `separator`: `ReferenceLookup` always emits forward slashes and passes `"/"`, so its output never gains a mixed form like `../doc/x\` and no longer depends on the result's depth. `PathResolver` passes nothing and gets the authored form, which is what it already renders path bodies in (`_apply_separator_style`).
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
2. **Target not found on line** — `ref.link_target` not present on the expected line. Special case: for `python-import` type, falls back to checking `ref.link_text` (dot-notation) on the line. (PD-BUG-126, 2026-08-19) A second fallback covers the escapable structured types (`json`, `json-dir`, `yaml`, `yaml-dir`): when `link_text` differs from `link_target` the recorded span covers an escaped literal, so the decoded target is legitimately absent from the raw line and `link_text` is checked instead. Without it the file is declared stale and **every** update in it is abandoned — including references that update correctly today, which is why the parser and updater halves of PD-BUG-126 had to land together. If `new_target` is already present, the reference is skipped (already handled by an earlier replacement).

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

(PD-BUG-150, 2026-08-30) This is a **contract of the replacement primitives, not of this class**: `replacement.replace_at_position()` trusts the caller's columns, so every caller must work right-to-left. The within-moved-file path in `ReferenceLookup` now obeys the same rule — it previously used a position-blind `line.replace(target, new, 1)` and had no ordering to violate.

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

## Shared Replacement Primitives (PD-BUG-150)

**Location**: `src/linkwatcher/replacement.py` (added 2026-08-30)

A leaf module — it imports only `link_types` and `models`, so it cannot close an import cycle with either caller — holding the replacement mechanics both rewrite paths need, dispatch included:

- `filter_contained_overlaps(items, file_path, logger)` — drops refs whose column range is strictly contained in another ref on the same line (PD-BUG-098). Strict containment only; partial overlap remains unaddressed and unobserved.
- `replace_at_position(line, ref, new_target, logger, on_ambiguous_skip=None)` — replaces at the recorded column span, with the PYTHON_IMPORT dot-notation branch, the escaped-literal re-escaping (PD-BUG-126) and the bounded invalid-column fallback that refuses an ambiguous unbounded replace. The optional callback lets a caller count refusals; `LinkUpdater` passes `_note_ambiguous_skip` to keep feeding `UpdateStats["errors"]` (TD252), and the moved-file path passes nothing.
- `replace_markdown_target(line, ref, new_target)` / `replace_reference_target(line, ref, new_target)` — format-aware rewrites for the two link types whose recorded span covers the whole construct rather than just the target. Both preserve the title; the markdown one also updates link text that exactly matches the old target (PD-BUG-012). **Both also preserve whitespace authored around the destination** and match it explicitly, because the parser records `link_target` stripped — the reference-definition replacer always did (`\s*` on both sides); the markdown one did not until PD-BUG-152 (2026-08-31), so a padded inline link matched nothing and was silently left stale in **both** rewrite paths. (PD-BUG-155, 2026-08-31) Both replacers additionally try an angle-wrapped variant of their pattern, because the parser now records a CommonMark angle-bracket destination unwrapped; the brackets are written back verbatim.
- `replace_markdown_at_span(line, ref, new_target)` — (PD-BUG-153, 2026-08-30) `replace_markdown_target` **confined to the reference's own recorded span**: it rewrites `line[column_start:column_end]` and splices the result back. The line-scoped form substitutes wherever its target appears, so a reference whose old target equals another's new target re-matches text that other pass just wrote and re-depths it a second time. Falls back to the line-scoped helper when a span is invalid or not construct-shaped — a safety net only: a `MARKDOWN` span exactly covers its `[text](target "title")` construct, measured across 13 shapes with 0 exceptions.
- `replace_in_line(line, ref, new_target, logger, on_ambiguous_skip=None)` — **the entry point every caller should use.** Routes `MARKDOWN` to `replace_markdown_at_span`, `MARKDOWN_REFERENCE` to `replace_reference_target`, and everything else to `replace_at_position`. The `MARKDOWN` branch went to the line-scoped `replace_markdown_target` until **PD-BUG-154** (2026-08-31) moved it onto the span-confined helper — see the note at the end of this section.

**Why extracted rather than re-implemented.** LinkWatcher rewrites link targets in two places: `updater._apply_replacements` for references in **other** files, and `reference_lookup._replace_links_in_lines` for links **inside a file that just moved**. Four bugs — PD-BUG-098, then PD-BUG-118 through PD-BUG-120, then PD-BUG-150 — are the same shape: a hardening lands on the first path and the second is left uncovered. PD-BUG-150 was the position awareness itself. Sharing one implementation is what stops the next recurrence; copying it a third time is what produced this family.

**Why the dispatch lives here too (rework, 2026-08-30).** The first version of this fix moved only the primitives and left the link-type dispatch behind in `LinkUpdater`. Phase 1 then routed *every* non-`MARKDOWN` reference straight into positional replacement — including `MARKDOWN_REFERENCE`, whose span covers the whole `[label]: target "title"` line — so every reference definition in a moved file was overwritten by its bare target, silently and counted as a success. Code Review (PF-TSK-005) rejected it. A fix whose stated purpose was ending the divergence between the two paths had reintroduced a narrower one, because the guard did not travel with the primitive it guards. It does now. Measured at the rework across every link-type shape the parsers emit (33 shapes, seven parsers): `MARKDOWN` and `MARKDOWN_REFERENCE` appeared to be the only types whose span is wider than their target, so those two branches were called the whole guard. **That bound was wrong, and Code Review round 2 rejected the rework for it.** `POWERSHELL_QUOTED_DIR` is a third: `powershell.py` strips the captured text into `link_target` (`potential_dir = match.group(1).strip()`) while `column_start`/`column_end` keep the raw match extent, so the span still covers padding the target no longer names and the splice destroyed the author's whitespace — silently, counted as a successful update, on **both** rewrite paths (a regression in the moved-file path, pre-existing since PD-BUG-098 in the updater path). Re-measured by damage rather than by shape census: 47,057 real references, 16 damaged, all of that one type. (PD-BUG-150 round 3, 2026-08-31) **The enumeration is gone rather than corrected.** A span narrower than its construct is now guaranteed upstream by the parser-side invariant 2.1.1-FR-9 (`BaseParser._tighten_span`), keyed on `span.strip() == target` so construct-spanning and escaped spans are excluded by construction rather than by name. The dispatch handles construct-spanning types; the invariant handles every other type, including a parser added later that nobody remembers to add to a list. Correcting the count would only have reset the clock — an enumeration is a fact about today's parsers, and this one had already been falsified twice.

**Within-moved-file rewrite (PD-BUG-153, 2026-08-30).** `_replace_links_in_lines` makes **one pass** over every reference, ordered descending by `(line, column)`. Positional references go through `filter_contained_overlaps` then `replace_in_line`; inline markdown goes to `replace_markdown_at_span`. The ordering is load-bearing — a replacement changes the line's length, so working right-to-left keeps every not-yet-applied span pointing at the text it was measured against.

This replaced a two-phase structure whose second phase rewrote markdown content-globally, after the positional phase, deduplicated by target. That phase carried two defects. It held its **own copy** of the markdown regex, so it never applied the PD-BUG-012 link-text rule the updater path had applied since March — a self-named link kept advertising its old path while its target was re-depthed. And being global it let one reference's freshly written target be re-matched by the next reference's pass, compounding a link that had already been rewritten: the PD-BUG-150 shape surviving in the markdown half. Descending order alone does not close that — it repairs the forward chain but not the mirror image, where the left-hand link's old target is what the right-hand link becomes — which is why the replacement is confined to its span rather than merely reordered.

The de-duplication went with the content-global pass it existed to serve: each reference now writes its own span, so collapsing duplicates would strand every one after the first. The `link_pattern_not_found` event is gone with that phase; a markdown reference that cannot be rewritten now reports `link_target_not_found_on_line` like every other type.

The moved-file path thereby inherits two behaviours it never had: the `ambiguous_fallback_replacement_skipped` / `overlapping_references_resolved` warnings, and PD-BUG-126 escaped-literal handling — an escaped JSON/YAML literal in a moved file was previously skipped with `link_target_not_found_on_line`, because `link_target` holds the decoded value and the raw line carries the escaped one.

**Updater-path span reach (PD-BUG-154, 2026-08-31).** The same defect survived on the **updater** path — references in *other* files — because `replace_in_line` dispatched `MARKDOWN` to the line-scoped `replace_markdown_target`. It is closed by routing that branch to `replace_markdown_at_span`, so both callers now get span confinement whichever entry point they use, and the moved-file path's explicit special-case becomes redundant rather than load-bearing. The trigger is the same mirror image described above: with two links on one line and two moves in one batch, a link whose old target equals a neighbour's new target re-matched the text that neighbour's pass had just written and re-pointed it at a third file, silently, both counting as updated. Descending column order does not save it, because it is the **left** link's pass that reaches rightward over text already rewritten.

> **Reachability.** No production input could trigger this. The only production caller of `update_references_batch` is the directory-move Phase 1b batch, whose moves are uniformly prefixed — every old path under `old_dir`, every new path under `new_dir` — so the two path sets are disjoint and the chain condition (one moved file landing exactly where another departed) cannot form; the two renames that would make them intersect are both refused by the OS. Single-file moves use `update_references`, one old→new pair, where the chain also cannot form. The fix is therefore behaviour-preserving for every input the daemon can actually see, and was taken on structural grounds: leaving the documented shared entry point as the *unsafe* markdown path is the divergence this module exists to prevent. `MARKDOWN_REFERENCE` stays line-scoped and is safe there — its pattern is anchored to the `[label]:` prefix and end-of-line, so a definition line admits exactly one match.

**Ambiguous-skip reporting (rework, 2026-08-30).** A reference the primitives *refuse* to rewrite (invalid columns plus a target occurring more than once — the PD-BUG-098 refusal) is reported once, by the primitive, and tallied into a single `moved_file_ambiguous_skips` warning carrying the count. Previously the resulting no-op was reported a **second** time as `link_target_not_found_on_line` — a warning naming a different and wrong cause, since the target is on the line and was refused, not missing — and nothing counted the refusal, so a reference left unrewritten inside a moved file had no number anywhere. The updater path surfaces the same event through `UpdateStats["errors"]` (TD252); this path returns only a count of links updated, hence the dedicated warning. Raised as a Code Review suggestion at the rework and fixed in the same change.

## Simultaneous-Move Repair (PD-BUG-114, 2026-08-10)

The within-moved-file recalculation path (`reference_lookup.update_links_within_moved_file` → `_calculate_updated_relative_path`) carries a repair layer for links whose **target moved in the same operation** as the file containing them. Without it, the PD-BUG-033 existence guard — which resolves each outgoing link against the moved file's OLD directory and skips targets missing from disk — silently dropped such links, and the target's own move event could not repair them afterwards (either `find_references` missed the re-indexed stale link, or the updater hit the referencing file's already-vacated old path).

- **Move memory**: `ReferenceLookup.record_move(old, new)` keeps a 300-second-TTL map of processed moves (TTL matches the `DirectoryMoveDetector` window; destination chains are followed for twice-moved files). The handler records every single-file move at the top of `_handle_file_moved` (covering self-links) and every per-file mapping plus the directory itself in `_handle_directory_moved` Phase 0.
- **Guard consult**: when the existence guard finds the old-resolved target missing, it consults the move memory. On a hit whose new target exists on disk, the link is rewritten to the target's new location (fragment preserved) and `link_target_move_applied` is logged at info; a hit whose mapped target is also gone logs `link_target_move_stale` at warning and leaves the link unchanged.
- **Pending recalcs**: a guard miss registers the skipped link under its resolved old target (`link_recalc_pending`, debug — non-path strings land here harmlessly and expire with the TTL). When a later move event's old path matches a pending key, `apply_pending_recalcs()` re-runs the moved-file recalculation for the recorded files (`pending_link_recalc_applied`, info) — the handler invokes it after single-file processing and as Phase 1.6 of directory moves.
- **Thread safety (PD-BUG-119, 2026-08-17)**: the move memory is the first cross-event mutable state on `ReferenceLookup`, and the class is shared by **two** threads — the watchdog observer thread (`_handle_file_moved`) and the `DirectoryMoveDetector` worker thread (`_handle_directory_moved`, started as a daemon thread in `dir_move_detector._trigger_processing`) — because `handler.on_moved` does not serialize move processing. Both dicts are therefore guarded by a single non-reentrant `_move_memory_lock`, matching the lock-guarded-shared-state pattern every other component here already follows. Two constraints define the design: the prune, the chain read-modify-write and the record in `record_move` are **one** critical section (splitting them is what allowed a concurrent insert to raise `RuntimeError: dictionary changed size during iteration` mid-prune, abandoning the whole move update), and `setdefault` + store in `_resolve_or_register_pending_recalc` are likewise one section (splitting them let a concurrent `apply_pending_recalcs` pop leave the store in an orphaned dict, losing the deferred repair silently). A third constraint was added by **PD-BUG-122** (2026-08-18): the re-check of `_recent_moves` belongs in that same section as the registration, because the caller's `_lookup_recent_move` miss has already released the lock — a competing thread that completes an entire move pass for the key in that gap would otherwise leave the registration under a key whose apply has already run, which nothing pops again. The method therefore returns the mapped target when it finds one, and the caller recalculates immediately instead of deferring. Conversely the lock is **never** held across file I/O or across `apply_pending_recalcs`' repair callback — that callback re-enters `_lookup_recent_move` / `_resolve_or_register_pending_recalc` through the link recalculation, so holding a non-reentrant lock there deadlocks the daemon. `_prune_move_memory` is a caller-holds-the-lock helper and does not acquire. Any new cross-event mutable state added to this class needs the same treatment.
- **Same-directory renames** run the full recalculation (the former early return is removed) so a vanished target reaches this repair.
- **Authored trailing separator on rewritten links (PD-BUG-120, 2026-08-17)**: the authored-form guard below only protects links that still resolve unchanged; a link that legitimately *is* rewritten returned raw `os.path.relpath` output, which drops a trailing separator — `doc/x/` came back as `../doc/x`. `_calculate_updated_relative_path` therefore applies the shared `utils.apply_trailing_separator_style` to the recalculated path at both return points (covering all three producing sites: the move-memory `relpath` branch, the move-memory root-destination branch, and the main branch) and *before* the `#fragment` is reattached, since the separator belongs to the path, not after the anchor. Same rule as PD-BUG-118 on the sibling path, reached through a different function — `PathResolver`'s choke point never sees these links. (PD-BUG-124, 2026-08-18) Both call sites now pass `separator="/"`: this module always emits forward-slash output, so the restored separator must not be inferred from whether the recalculated result happens to carry one. Without it, one authored backslash form produced a forward slash at multi-segment depth and a bare backslash at single-segment depth — the latter corrupting the `.py` literal it was written into.
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
