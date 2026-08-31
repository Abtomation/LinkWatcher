---
id: TE-TSP-040
description: "2.2.1 Tier 2 — Atomic updates, dry-run, backup creation"
type: Process Framework
category: Test Specification
version: 1.2
created: 2026-02-24
updated: 2026-08-30
feature_id: 2.2.1
feature_name: Link Updating
tdd_path: doc/technical/tdd/tdd-2-2-1-link-updater-t2.md
test_tier: 2
retrospective: true
---

# Test Specification: Link Updating

> **Retrospective Document**: This test specification describes the existing test suite for Link Updating, documented after implementation during framework onboarding. Content is derived from analysis of existing test files.

## Overview

This document provides comprehensive test specifications for the **Link Updating** feature (ID: 2.2.1), derived from the Technical Design Document [PD-TDD-026](../../../doc/technical/tdd/tdd-2-2-1-link-updater-t2.md).

**Test Tier**: 2 (Unit + Integration)
**TDD Reference**: [TDD PD-TDD-026](../../../doc/technical/tdd/tdd-2-2-1-link-updater-t2.md)
**Implementation Coverage**: 36/40 scenarios implemented (90%)

## Feature Context

### TDD Summary

The `LinkUpdater` class performs atomic file modifications to update link references after file moves. It uses a bottom-to-top replacement strategy (sorting references by line/column descending), link-type-specific replacement functions (`_replace_markdown_target`, `_replace_reference_target`, `_replace_at_position`), and atomic writes via `NamedTemporaryFile` + `shutil.move()`. Supports dry-run mode and backup creation.

### Test Complexity Assessment

**Selected Tier**: 2 — Multiple replacement strategies, atomic write safety, and multi-format integration.

## Cross-References

### Functional Requirements Reference

> **Primary Documentation**: [FDD PD-FDD-027](../../../doc/functional-design/fdds/fdd-2-2-1-link-updater.md)

**Acceptance Criteria to Test**:
- Multiple references in one file all updated in single write
- Multiple references on same line updated correctly (rightmost first)
- Dry-run mode: no files modified, statistics accurate
- Atomic writes: no partial file on disk
- Backup creation when enabled
- Anchor preservation in updated paths

## Test Categories

### Unit Tests

| Component | Test Focus | Key Test Cases | Fixtures |
|-----------|-----------|----------------|----------|
| LinkUpdater | Initialization | `test_updater_initialization` — backup_enabled=True, dry_run=False | None |
| LinkUpdater | Dry-run toggle | `test_set_dry_run_mode` — toggle on/off | None |
| LinkUpdater | Backup toggle | `test_set_backup_enabled` — toggle on/off | None |
| LinkUpdater | Group by file | `test_group_references_by_file` — multi-file grouping | None |
| LinkUpdater | Simple new target | `test_calculate_new_target_simple` — old-to-new path calculation | None |
| LinkUpdater | Anchor preservation | `test_calculate_new_target_with_anchor` — #section preserved | None |
| LinkUpdater | Relative new target | `test_calculate_new_target_relative_path` — ../old.txt to ../new.txt | None |
| LinkUpdater | Markdown replacement | `test_replace_markdown_target` — `[text](old.txt)` → `[text](new.txt)` | None |
| LinkUpdater | Markdown anchor replace | `test_replace_markdown_target_with_anchor` — anchors preserved inline | None |
| LinkUpdater | Non-markdown replace | `test_replace_in_line_non_markdown` — YAML `file: old.txt` replacement | None |
| LinkUpdater | Path normalization | `test_normalize_path` — leading slashes, backslashes, `./` | None |
| LinkUpdater | Dry-run update | `test_update_references_dry_run` — reports success, file unchanged | `temp_project_dir` |
| LinkUpdater | Real update | `test_update_references_real_mode` — file content modified | `temp_project_dir` |
| LinkUpdater | Multi-ref same file | `test_update_multiple_references_same_file` — 3 refs all updated | `temp_project_dir` |
| LinkUpdater | Backup creation | `test_update_references_with_backup` — .bak created with original content | `temp_project_dir` |
| LinkUpdater | Error handling | `test_update_references_error_handling` — non-existent file: 1 error, 0 updates | None |
| LinkUpdater | Atomic writes | `test_atomic_file_operations` — _write_file_safely called during updates | `temp_project_dir` |
| LinkUpdater | Link text update (PD-BUG-012) | `test_link_text_updated_when_matches_old_target` — text matching old target updated to new target | None |
| LinkUpdater | Link text preserved (display name) | `test_link_text_not_updated_when_display_name` — display name text preserved unchanged | None |
| LinkUpdater | Link text preserved (filename) | `test_link_text_not_updated_when_filename_only` — filename-only text preserved unchanged | None |
| LinkUpdater | Link text end-to-end | `test_link_text_updated_end_to_end` — full file update with link text matching old target | `temp_project_dir` |
| ReferenceLookup | Dry-run gates moved-file rewrite (PD-BUG-116) | `test_dry_run_prevents_write` — moved file with re-depth-needing link stays byte-identical on disk, no `.bak` even with backup enabled | `temp_dir` |
| ReferenceLookup | Dry-run DB honesty (PD-BUG-116) | `test_dry_run_rescans_original_content` — DB rescan indexes the on-disk (original) content, not the previewed rewrite | `temp_dir` |
| ReferenceLookup | Live mode still rewrites (PD-BUG-116 guard) | `test_normal_mode_still_writes` — with `dry_run=False` the moved file's link is re-depthed on disk | `temp_dir` |

**Test File**: [`test/automated/unit/test_updater.py`](../../automated/unit/2-link-parsing-update/2-0-link-parsing-update/test_updater.py) (24 methods); PD-BUG-116 rows in [`test_reference_lookup.py`](../../automated/unit/1-file-watching-detection/1-0-file-watching-detection/test_reference_lookup.py) (`TestUpdateLinksWithinMovedFile`)

### Integration Tests

| Flow | Test Scenario | Expected Outcome | Fixtures |
|------|---------------|-----------------|----------|
| Markdown standard | `test_lr_001_markdown_standard_links` | 4 standard links updated, titles preserved | `temp_project_dir` |
| Markdown relative | `test_lr_002_markdown_relative_links` | Relative paths recalculated across directories | `temp_project_dir` |
| Markdown anchors | `test_lr_003_markdown_with_anchors` | 5 anchor links: path updated, fragment preserved | `temp_project_dir` |
| YAML references | `test_lr_004_yaml_file_references` | Unquoted, double-quoted, single-quoted, array forms | `temp_project_dir` |
| JSON references | `test_lr_005_json_file_references` | JSON strings updated, valid JSON maintained | `temp_project_dir` |
| Python imports | `test_lr_006_python_imports` | String references to .py file updated | `temp_project_dir` |
| Dart imports | `test_lr_007_dart_imports` | Single and double-quoted import refs updated | `temp_project_dir` |
| Generic text | `test_lr_008_generic_text_files` | Quoted and standalone refs in plain text updated | `temp_project_dir` |
| Mixed types | `test_mixed_reference_types` | 5 different reference types in one file all updated | `temp_project_dir` |
| False positives | `test_false_positive_avoidance` | Only real link found, not URLs/emails/versions | `temp_project_dir` |
| Substring corruption (PD-BUG-025) | `test_bug025_yaml_substring_path_not_corrupted` | YAML with config.yaml and configs/config.yaml: each updated independently, no substring corruption | `temp_project_dir` |
| Substring corruption (PD-BUG-025) | `test_bug025_generic_quoted_substring_not_corrupted` | PowerShell with helpers.py and core/helpers.py in quotes: each updated independently | `temp_project_dir` |

**Test File**: [`test/automated/integration/test_link_updates.py`](../../automated/unit/2-link-parsing-update/2-0-link-parsing-update/test_link_updates.py) (12 methods)

### Override-Aware Resolution Tests (v1.1)

> **Added in v1.1 (2026-06-29)** — blueprint-aware reference updating enhancement (PF-STA-110). Scenarios for `PathResolver` honouring `path_resolution_overrides` on the live move/update path. Design: [PD-TDD-026 § Override-Aware Path Resolution](../../../doc/technical/tdd/tdd-2-2-1-link-updater-t2.md#override-aware-path-resolution-v11). These are **specified, not yet implemented** — implemented in Session 2 (state file Step 15). Each is configured with a `path_resolution_overrides` mapping (the key is unexercised by the default suite, so coverage must set it explicitly).

| # | Scenario | Test Focus | Expected Outcome |
|---|----------|-----------|------------------|
| a | Override-source `/…` reference rewritten | A file under the configured override folder references a moved/renamed sibling via a host-absolute `/…` link | Link rewritten to the new name, **leading-slash virtual-root style preserved** (e.g. `/process-framework/tasks/foo.md` → `/process-framework/tasks/foo-task.md`) |
| b | Non-override source unchanged (regression) | The *same* `/…` reference in a file **outside** every override folder | Left **byte-for-byte unchanged** — proves override resolution is scoped and v1.0 behavior is preserved |
| c | Non-existent resolved target guarded | An override-source `/…` reference whose base-resolved target does not exist on disk | Left unchanged (`path_exists_under_root` containment guard, mirroring PD-BUG-095) |
| d | Separator-style preserved on override rewrite (PD-BUG-112) | An override-source reference written with backslash separators | Rewrite keeps backslash style; no `\`→`/` flip that would corrupt a string literal |
| e | Directory restructure inside blueprint | A folder moved/renamed inside the override folder, with multiple sibling `/…` references to files under it | **All** affected `/…` references rewritten to the new directory, virtual-root style preserved |
| f | Virtual-root link not hijacked by coinciding moves | A real root-level path coinciding with the virtual path moves (file or directory), or an unrelated file whose old path merely path-suffix-matches the virtual link moves (2026-07-06 code-review Major finding) | Virtual-root link left **unchanged** — the early-exit branches *and* the PD-BUG-045 suffix block are all skipped for virtual-root links; Step-3 base-aware resolution is their only match path |

**Additional required assertions** (state file Step 15):
- A regression assertion that **non-override resolution is byte-for-byte unchanged** (covers scenario b and the broader no-config default path).
- Coverage placed in `test/automated/unit/2-link-parsing-update/2-0-link-parsing-update/test_updater.py` (unit) and `test_link_updates.py` (integration), using the existing test markers/registry conventions.

### Simultaneous-Move Repair Tests (PD-BUG-114)

> **Added 2026-08-10** — regression coverage for the PD-BUG-114 fix (move memory + pending recalcs in `ReferenceLookup`). Scenario class: file A links to file B and **both** vacate their old disk locations before either move event is processed. Design: [PD-TDD-026 § Simultaneous-Move Repair](../../../doc/technical/tdd/tdd-2-2-1-link-updater-t2.md).

| Scenario | Test | Expected Outcome |
|----------|------|------------------|
| Referencing file's event first | `test_both_endpoints_move_referencing_file_event_first` | A's link re-pointed at B's new location and re-depthed for A's new location; stale as-authored link absent (negative assertion); unmoved-target links re-depthed |
| Target file's event first | `test_both_endpoints_move_target_file_event_first` | Same outcome in the opposite processing order |
| DB consistency | `test_database_consistent_after_simultaneous_move` | `get_references_to_file(B_new)` returns A at its new path |
| Fragment preservation | `test_fragment_preserved_across_simultaneous_move` | `#fragment` survives the repair |
| In-place rename + concurrent target move | `test_rename_in_place_with_concurrent_target_move` | Same-directory rename reaches the repair path (former early return removed) |
| PD-BUG-033 guard regression | `test_never_existed_target_still_not_rewritten` | Link-shaped strings whose target never existed remain unmodified |

#### Authored-Form Preservation (PD-BUG-114 code review follow-up)

> **Added 2026-08-10** — the Code Review Major finding. Removing the same-directory early return routed in-place renames through `os.path.relpath`, which canonicalizes; links that already resolved correctly were reformatted. Recalculation must be **semantic, not textual**. Design: [PD-TDD-026 § Authored-form preservation](../../../doc/technical/tdd/tdd-2-2-1-link-updater-t2.md).

| Scenario | Test | Expected Outcome |
|----------|------|------------------|
| Dot-slash form, in-place rename | `test_dot_slash_link_untouched_by_same_directory_rename` | `./target.md` survives byte-identical; canonicalized `target.md` absent (negative assertion) |
| Backslash form, in-place rename | `test_backslash_link_untouched_by_same_directory_rename` | `..\other\C.md` in a `.ps1` keeps its separators; forward-slash form absent |
| Trailing-slash directory link | `test_trailing_slash_directory_link_untouched` | `../assets/` keeps its trailing slash; file byte-identical |
| Boundary: cross-directory move | `test_cross_directory_move_still_rewrites` | Suppression must NOT leak — the same `./target.md` form moved deeper IS recalculated to `../target.md` |

**Test File**: [`test/automated/unit/2-link-parsing-update/test_simultaneousmoves.py`](../../automated/unit/2-link-parsing-update/test_simultaneousmoves.py) (TE-TST-145, 10 methods). Manual validation: `test/bug-validation/PD-BUG-114_simultaneous_move_validation.py` (3 scenarios — both event orders plus authored-form preservation).

#### Path-Span Integrity (PD-BUG-118)

> **Added 2026-08-17** — a reference-update pass corrupted content *adjacent* to the matched path. Three independent mechanisms, all confirmed by reproduction: docstring reference columns recorded relative to the extracted docstring text rather than the physical line; `normalize_path()` output stripping an authored trailing separator; and bare-path character classes swallowing sentence punctuation into the target. The governing contract is the same one the authored-form guard above states for the sibling write path — a rewrite changes **where** a target points, never how it was written, and never a character outside the matched span.

| Scenario | Test | Expected Outcome |
|----------|------|------------------|
| Docstring column drift, end-to-end | `test_docstring_line_replacement_has_no_character_duplication` | The literal bug evidence line rewrites cleanly; `ptest/` and `permanentanent` absent (negative assertions) |
| Prose outside the span | `test_docstring_replacement_leaves_prose_byte_identical` | Whole line byte-identical apart from the path itself |
| Exact directory match | `test_exact_directory_match_preserves_trailing_slash` | `doc/state-tracking/` → `doc/moved-tracking/` — authored trailing slash kept |
| Control: no slash authored | `test_slashless_target_stays_slashless` | A target authored without a trailing slash must not gain one |
| Directory-prefix branch | `test_subdirectory_prefix_match_preserves_trailing_slash` | Prefix-match rewrites preserve the trailing slash too |
| Root-absolute form | `test_leading_slash_form_preserves_trailing_slash` | `/doc/x/` keeps **both** leading and trailing slash |
| Backslash form | `test_backslash_target_preserves_trailing_backslash` | Separator style *and* trailing separator survive (PD-BUG-112 sibling) |
| No-op move | `test_no_op_move_does_not_rewrite_file` | A move whose old and new paths are equal must never write the file |

**Test File**: [`test/automated/unit/2-link-parsing-update/2-0-link-parsing-update/test_updater.py`](../../automated/unit/2-link-parsing-update/2-0-link-parsing-update/test_updater.py) (74 methods; `TestDocstringColumnCorruption` 2, `TestTrailingSlashPreservation` 6, `TestBug124EscapedBackslashSeparators` 5). Parser-side columns and punctuation trimming are specified in [test-spec-2-1-1](test-spec-2-1-1-link-parsing-system.md). Manual validation: `test/bug-validation/PD-BUG-118_path_span_corruption_validation.py` (10 checks across both defect classes, driving the real service with a real directory move).

#### Move-Memory Thread Safety (PD-BUG-119, PD-BUG-122)

> **Added 2026-08-17** — the move memory the simultaneous-move fix introduced (`_recent_moves`, `_pending_recalcs`) is reached from two threads: the watchdog observer thread via `_handle_file_moved`, and the DirectoryMoveDetector worker thread via `_handle_directory_moved`. `handler.on_moved` does not serialize them, so a single-file move landing inside an open directory-move settle window interleaves with per-file processing. The contract: concurrent move processing leaves move memory and pending recalcs consistent — no exception escapes, and no deferred repair is lost. **Extended 2026-08-18 (PD-BUG-122)**: atomicity of each individual operation is not enough — the link recalculation's *check-then-register pair* spans two acquisitions, so the registration re-checks move memory inside its own critical section and resolves inline when the move landed in the gap.
>
> Interleavings are driven **deterministically** rather than raced: each test hooks a callable the production code already invokes inside the vulnerable window (a timestamp comparison inside `_prune_move_memory`'s iteration; the `time.monotonic()` call between `setdefault` and the store in `_resolve_or_register_pending_recalc`), so the competing thread runs at exactly the right instruction inside the real code path.

| Scenario | Test | Expected Outcome |
|----------|------|------------------|
| Registration during prune, via `record_move` | `test_record_move_survives_registration_during_prune` | No `RuntimeError` escapes; the competing registration is retained. This is the severe path — `record_move` sits at the top of `_handle_file_moved`'s try, so an escape abandons the **entire** move update |
| Registration during prune, via lookup | `test_lookup_recent_move_survives_registration_during_prune` | Lookup still returns its answer; the quiet path, where the error would be swallowed by `_calculate_updated_relative_path` and leave the link silently stale |
| Pop during registration | `test_registration_is_not_lost_to_a_concurrent_apply` | The pending entry is either still queued or delivered to `apply_pending_recalcs` — never dropped into an orphaned dict (two-sided assertion: "delivered only" would fail on benign orderings, "queued only" would pass a run that consumed nothing) |
| Move landing between check and register | `test_move_landing_between_check_and_register_is_not_orphaned` | The link is repaired inline **and** no pending entry is left under the consumed key. PD-BUG-122: `_lookup_recent_move` releases the lock before the registration re-acquires it, so a competing thread completing an entire move pass in that gap would otherwise orphan the registration under an already-applied key — nothing pops it again, and the link stays stale with no exception and no log line (two-sided assertion: link-only would pass an implementation that repairs but leaks the entry; orphan-only would pass one that drops the registration entirely) |
| Re-entrant repair (design pin) | `test_apply_pending_recalcs_does_not_deadlock_on_reentrant_repair` | `apply_pending_recalcs` must release the lock before its repair callback, which re-enters the guarded methods. Passes pre-fix by construction; it exists to fail an over-locking fix, whose deadlock is worse than the race |
| Concurrent stress (backstop) | `test_two_threads_hammering_move_memory_raise_nothing` | Covers `record_move`'s chain read-modify-write; no exception, and every recorded move stays resolvable |

**Test File**: [`test/automated/unit/2-link-parsing-update/test_movememorythreadsafety.py`](../../automated/unit/2-link-parsing-update/test_movememorythreadsafety.py) (TE-TST-152, 6 methods). No manual validation script: a race in internal state has no trigger a human can drive reproducibly by hand, so a manual run that observed no corruption would prove nothing.

#### Authored Trailing Separator Inside a Moved File (PD-BUG-120)

> **Added 2026-08-17** — the sibling half of Path-Span Integrity above. PD-BUG-118 restored the authored trailing separator for references in **other** files, at the `PathResolver.calculate_new_target` choke point; links **inside** a moved file are recalculated by `reference_lookup._calculate_updated_relative_path`, which that helper never reaches and which returns raw `os.path.relpath` output — so `doc/x/` came back as `../doc/x`. The authored-form guard (PD-BUG-114) only protects links that still resolve unchanged, so the loss lands exactly on legitimate rewrites. Contract, unchanged from its sibling: a rewrite changes **where** a target points, never how it was written. The damaging manifestation is a path used as a concatenation prefix in a moved `.py`/`.ps1`/`.yaml` — `logs/linkwatcher/` + `run.log` silently becomes `../logs/linkwatcherrun.log`, with nothing logged.

| Scenario | Test | Expected Outcome |
|----------|------|------------------|
| Main branch (target exists) | `test_bug120_main_branch_keeps_trailing_slash` | `doc/state-tracking/` → `../doc/state-tracking/`; slash-less form absent (negative assertion) |
| `./dir/` authored form | `test_bug120_dot_slash_authored_form_keeps_trailing_slash` | The dot-slash form keeps its trailing separator through recalculation |
| Backslash authored form | `test_bug120_backslash_authored_form_keeps_a_trailing_separator` | Ends in a separator matching the style this module emits — always forward slash, never a mixed `../doc/x\` (rule tightened by PD-BUG-124: it no longer depends on the result's own style, which was absent at single-segment depth) |
| Move-memory branch | `test_bug120_move_memory_branch_keeps_trailing_slash` | A target that moved in the same operation is re-pointed **with** its separator |
| Move-memory, root destination | `test_bug120_move_memory_to_root_keeps_trailing_slash` | Distinct return site: the mapped target is returned without `relpath` and still keeps the separator |
| Trailing separator + anchor | `test_bug120_trailing_slash_with_anchor_keeps_both` | `doc/x/#top` → `../doc/x/#top` — the separator belongs before the fragment |
| Control: none authored | `test_bug120_no_separator_invented_when_none_authored` | A reference authored without a separator must not gain one |
| Control: file target | `test_bug120_file_target_unaffected` | File references are untouched by the restoration |
| End-to-end, markdown | `test_bug120_markdown_directory_link_keeps_trailing_slash` | Real service move: `[state](doc/state-tracking/)` → `(../doc/state-tracking/)` |
| End-to-end, concatenation prefix | `test_bug120_python_concatenation_prefix_keeps_trailing_slash` | `LOG_DIR = "logs/linkwatcher/"` in a moved `.py` still concatenates to a valid path |

**Test Files**: unit — [`test/automated/unit/1-file-watching-detection/1-0-file-watching-detection/test_reference_lookup.py`](../../automated/unit/1-file-watching-detection/1-0-file-watching-detection/test_reference_lookup.py) (`TestBug120TrailingSeparatorPreserved`, 8 methods, at the function that produces the value); end-to-end — [`test/automated/unit/2-link-parsing-update/2-0-link-parsing-update/test_link_updates.py`](../../automated/unit/2-link-parsing-update/2-0-link-parsing-update/test_link_updates.py) (`TestBug120TrailingSeparatorWithinMovedFile`, 2 methods, driving the real service). Manual validation: `test/bug-validation/PD-BUG-120_trailing_separator_within_moved_file_validation.py` (6 checks, including what the concatenation in the moved file evaluates to before and after).

#### Escaped Backslash Separators (PD-BUG-124)

> **Added 2026-08-18** — the third pass over the same contract, and the first where restoring the separator was itself the damage. Link targets are extracted from, and spliced back into, the file's **raw source**. Inside an escaped string literal (`.py`, and any parser reporting raw spans) one separator is authored as `\\`; every reconstruction site emitted a bare `\`, which the language then reads as an escape character. Two failure shapes, and the quiet one is the dangerous one: **loud** when the bare backslash escapes the closing quote (`LOG = "logs2\"` → unterminated string literal, the reported case), **silent** when it forms a valid escape (`logs\deep\notes.txt` still parses, but `\n` decodes to a newline and the value is quietly wrong, with `links_updated=1` logged as success).
>
> Three sites shared it, all reached from `PathResolver`: the trailing separator (`utils.apply_trailing_separator_style`, the reported case, on both recalculation paths) and **two body-separator sites** that the report did not name and the Step 20 similar-issue sweep found — `_apply_separator_style` (directory-prefix branch) and `_convert_to_original_link_type` (match branch, the silent one). Both trace to PD-BUG-112 rather than to this cycle.
>
> Contract, unchanged from its two siblings above and now stated at full strength: a rewrite changes **where** a target points, never how it was written — and **never leaves the containing file invalid**. The corollary this bug adds: preserving the authored *path* is not enough if the authored *escaping* is dropped. Because the assertion must catch the silent shape, the end-to-end scenario checks the **decoded value**, not just that the file parses.

| Scenario | Test | Expected Outcome |
|----------|------|------------------|
| Trailing separator, dir renamed | `test_trailing_separator_preserves_authored_escaping` | An authored `\\` comes back `\\`; the bare-backslash form absent (negative assertion) |
| Body separators, prefix branch | `test_directory_prefix_branch_preserves_authored_escaping` | Escaping survives on every segment, not just the last; the halved form would be a truncated hex escape |
| Body separators, match branch | `test_match_branch_preserves_authored_escaping` | The **silent** case — the halved form still parses, so the assertion pins the exact escaped output |
| Control: unescaped authoring | `test_single_backslash_authoring_is_unchanged` | Markdown authors one backslash and means it — separators must not gain an escape (green before *and* after the fix) |
| End-to-end, file validity | `test_rewritten_python_file_still_parses_and_keeps_its_value` | The rewritten `.py` parses **and** its constant decodes to the intended path — a parse check alone would pass the silent case |
| Single-segment result | `test_single_segment_result_does_not_emit_a_bare_backslash` | `reference_lookup` emits forward-slash output at every depth; no bare trailing backslash |
| Style vs result depth | `test_style_does_not_depend_on_result_depth` | One authored form, two destination depths, both genuinely recalculated — the restored separator must match (the secondary defect) |

**Test Files**: unit — [`test/automated/unit/2-link-parsing-update/2-0-link-parsing-update/test_updater.py`](../../automated/unit/2-link-parsing-update/2-0-link-parsing-update/test_updater.py) (`TestBug124EscapedBackslashSeparators`, 5 methods, covering all three reconstruction sites plus the end-to-end file-validity contract); [`test/automated/unit/1-file-watching-detection/1-0-file-watching-detection/test_reference_lookup.py`](../../automated/unit/1-file-watching-detection/1-0-file-watching-detection/test_reference_lookup.py) (`TestBug124TrailingSeparatorStyleIsConsistent`, 2 methods, at the function that produces the value). Manual validation: `test/bug-validation/PD-BUG-124_escaped_backslash_separator_validation.py` (5 checks driving the real service, printing source, *parses* and *decodes* per case so the silent shape is visible to the human).

#### Escaped Structured Literals (PD-BUG-126)

> **Added 2026-08-19** — the fourth pass over the same contract, reached from the other end: not the separator being reconstructed wrongly, but the reference never arriving at the updater at all. Both structured-data parsers located a value by searching the **raw** source line for the **decoded** text; every JSON escape form makes those differ, so the search returned 0 and the reference was dropped silently. Nothing was logged, and the target went stale on the next move while a plain sibling on the same line updated normally.
>
> The two halves are inseparable, and that is the load-bearing part of this contract: making the references **visible** exposes them to the write-back path, where splicing raw text into an escaped literal is exactly the PD-BUG-124 corruption. Measured on a file holding one escaped value and one plain one, a parser-only fix yields `files_updated=0` and `stale_files=[config.json]` — the plain sibling, which worked before, stops updating. A detection-only fix is therefore net-negative, not merely incomplete.
>
> Contract: a value is located by whichever spelling the author chose; the recorded span addresses the raw source; the replacement is written back in the same escaped form; and a value that cannot be located is **logged**, never dropped in silence. The rule from the three siblings above holds unchanged — a rewrite changes **where** a target points, never how it was written — and it now covers the character set as well as the separators.

| Scenario | Test | Expected Outcome |
|----------|------|------------------|
| Escaped forward slash | `test_escaped_forward_slash_is_detected` | `\/` decodes to an ordinary POSIX path — detected and located on its own line |
| Unicode escape | `test_unicode_escape_is_detected` | `\u0078` decodes to `x`; refutes the hypothesis that this class is Windows-specific |
| Backslash-authored path | `test_escaped_backslash_path_is_detected` | The reported case — the only valid JSON spelling of a Windows path is detected |
| Span addresses raw source | `test_span_covers_the_raw_literal_not_the_decoded_value` | A span sized to the shorter decoded value would leave escape debris behind on write-back |
| Control: escape-free value | `test_plain_value_still_detected` | The pre-existing path is untouched by the new branch (green before *and* after) |
| Both spellings, one file | `test_escaped_and_plain_values_both_detected` | Each is claimed on its own line; the claim key is (line, column), since several spellings decode alike |
| No false stale | `test_escaped_ref_does_not_mark_file_stale` | The escaped literal must not abandon updates for the whole file |
| Plain sibling survives | `test_plain_sibling_still_updates` | The regression guard for the coupling above — measured failing on a parser-only fix |
| Write-back validity | `test_escaped_ref_is_rewritten_and_file_stays_valid_json` | The rewritten file still parses **and** decodes to the intended target |
| Non-ASCII authoring | `test_non_ascii_authoring_survives_the_rewrite` | Code Review amendment: `ensure_ascii=False`, so an authored character is not re-spelled as a unicode escape — negative assertion on the escape form, since the re-spelled value is valid and decode-identical and would otherwise pass unnoticed |

**Test Files**: parser — [`test/automated/unit/2-link-parsing-update/2-0-link-parsing-update/test_json.py`](../../automated/unit/2-link-parsing-update/2-0-link-parsing-update/test_json.py); updater — [`test/automated/unit/2-link-parsing-update/2-0-link-parsing-update/test_updater.py`](../../automated/unit/2-link-parsing-update/2-0-link-parsing-update/test_updater.py); manual validation — `test/bug-validation/PD-BUG-126_escaped_json_literal_validation.py` (7/7 through the real service)

#### Column-Position Replacement Inside a Moved File (PD-BUG-150)

> **Added 2026-08-30** — the fourth pass over the same divergence, and the one that closes it structurally. Every prior entry above records the same shape: a hardening lands at the choke point for references in **other** files, and the sibling path that rewrites links **inside** a moved file is left uncovered. Here the uncovered mechanic was position awareness itself. `updater._apply_replacements` has replaced at the parser's recorded column span since PD-BUG-098; `reference_lookup._replace_links_in_lines` still called `lines[idx].replace(target, new, 1)`, which discards `column_start`/`column_end` and rewrites the **leftmost** match.
>
> With two or more references whose targets are duplicates or nested on one line, every replacement therefore landed on the same span. The old target survives as a substring of its own replacement for the `../` depth family a move-deeper produces, so the first span was rewritten once per reference (`../doc/` → `../../../doc/`, and → `../../../../doc/` with three) while the later spans were never touched. Silent in both directions: the full count is logged as `moved_file_links_updated` and no warning is emitted. Markdown links were immune only because they take a different branch — a content-global regex that is position-independent.
>
> **Structural resolution**: the two implementations were merged rather than re-hardened in parallel. `src/linkwatcher/replacement.py` is a leaf module holding `filter_contained_overlaps`, `replace_at_position`, the two format-aware markdown replacers and the `replace_in_line` dispatch that chooses between them; `LinkUpdater` delegates to it and the moved-file path now calls it directly, so a future hardening cannot reach one path and miss the other. Two ordering contracts come with it, both pinned below: positional refs are processed **descending** by `(line, column)` so an earlier replacement's length change cannot stale the next span's columns, and the markdown regex runs **last** for the same reason.
>
> **Assertion strength note.** Every scenario here compares the **whole rewritten line**, not a substring count. That is not stylistic: dropping the descending order yields ``Both `../../doc/` an../../doc/oc/` are ...``, which still contains `../../doc/` exactly twice and no over-deepened path — so the count-based assertions written first passed on visibly corrupted output. Established by mutation while authoring, and the reason the ordering mutation now turns five tests red instead of none.

> **Rework, 2026-08-30** — Code Review (PF-TSK-005) rejected the first fix. It routed every non-`MARKDOWN` reference into positional replacement, but a `MARKDOWN_REFERENCE` span covers the **whole** `[label]: target "title"` line, so the splice overwrote label and title with the bare target — destroying the definition and orphaning every `[text][label]` usage in the file, silently and counted as a success. `updater` never had the defect because it dispatches on link type before reaching positional replacement; the extraction took the primitive without its guard. The dispatch now lives beside the primitive. The four scenarios below pin it, and the bound was measured end to end rather than assumed: across 33 link-type shapes from seven parsers, `MARKDOWN` and `MARKDOWN_REFERENCE` are the only types whose recorded span is wider than their target **That bound was wrong** — see the round-3 note below.

> **Round 3, 2026-08-31** — Code Review rejected the rework in turn, for the bound itself. `POWERSHELL_QUOTED_DIR` is a third wide-span type: `powershell.py` strips the captured text into `link_target` while the columns keep the raw match extent, so the span still covers padding the target no longer names and the splice destroyed the authored whitespace — silently, counted as an update, on **both** rewrite paths (a regression here, pre-existing since PD-BUG-098 in the updater path).
>
> **The enumeration is gone rather than corrected.** Correcting a list only resets the clock: it is a fact about today's parsers, and this one had already been falsified twice. A span narrower than its construct is now guaranteed upstream by the parser-side invariant 2.1.1-FR-9 (`BaseParser._tighten_span`), keyed on `span.strip() == target`, so construct-spanning and escaped spans are excluded **by construction** rather than by name — and a parser added later is covered without anyone remembering to list it.
>
> **Bound re-derived by damage, not by shape census** — which is how rounds 1 and 2 got it wrong. A damage oracle rewrites every reference in the repo with a sentinel and requires that mapping it back reproduces the line byte for byte: **16 damaged of 47,057 before, 0 of 47,231 after**, every one `POWERSHELL_QUOTED_DIR`.

| Scenario | Test | Expected Outcome |
|----------|------|------------------|
| Duplicate directory refs | `test_duplicate_directory_refs_each_rewritten_at_its_own_position` | The filed reproduction: both spans reach `../../doc/`; pre-fix the first compounded to `../../../doc/` and the second stayed stale |
| Duplicate file refs | `test_duplicate_file_refs_each_rewritten_at_its_own_position` | The shape with **real links and no prose** — pre-fix leaves a path resolving nowhere, which is why this was split out of PD-BUG-149 |
| Three copies on one line | `test_three_duplicate_refs_on_one_line` | The incident shape: the leftmost span absorbed all N rewrites, reaching `../../../../doc/` |
| Control: nested targets | `test_nested_targets_still_rewritten_correctly` | `../doc/` and `../doc/sub/` already worked; guards against an over-correction that breaks nesting |
| Control: distinct targets | `test_distinct_targets_on_one_line_unaffected` | Two unrelated targets on one line do not interfere |
| Markdown duplicates | `test_duplicate_markdown_links_each_rewritten_without_warning` | (Renamed and re-expected at PD-BUG-153, 2026-08-30.) Each reference is rewritten at its own span and counted, so the pair now yields **2**, not the 1 the content-global pass produced. Neither may be reported as missing — asserted against `link_target_not_found_on_line`, since `link_pattern_not_found` is gone with the phase that emitted it and an assertion naming it could no longer fail |
| Reference definition + title | `test_reference_definition_with_title_keeps_label_and_title` | Only the target changes; label and title are byte-identical afterwards |
| Reference definition, no title | `test_reference_definition_without_title_keeps_label` | The absent title does not narrow the span — the label must survive too |
| Reference definition, directory | `test_reference_definition_with_directory_target_keeps_label` | The third damaged shape; a directory target is not a separate link type |
| Definition + positional refs | `test_reference_definition_alongside_positional_refs` | The shape the E2E fixtures carry: a definition block under a body of ordinary links — definitions and inline links must coexist in the single ordered pass (PD-BUG-153 merged the two phases) |
| Ambiguous skip reporting | `test_ambiguous_skip_reported_once_and_counted` | A refused replacement is reported once by its real cause and tallied into `moved_file_ambiguous_skips`; it is no longer ALSO reported as a missing target, a second warning naming the wrong cause |
| Padded quoted directory (round 3) | `test_padded_quoted_directory_keeps_its_whitespace` | Four spellings — padded both sides, leading only, trailing only, plus a tight control. The target is re-depthed and the authored padding survives; pre-fix the bare target was spliced across a span that covered the whitespace, so it was destroyed silently and counted as an update. Extensionless on purpose: an extension-bearing target is captured tight and never showed the defect |
| Padded quoted directory, updater path (round 3) | `TestBug150PaddedQuotedDirectorySpan::test_padding_survives_a_reference_update` (`test_updater.py`) | The same damage in a *referring* file, where it is **pre-existing** rather than a regression — the updater has spliced at columns since PD-BUG-098. Pins that one choke point repairs both paths |
| Contained overlap (design pin) | `test_contained_overlap_does_not_chop_the_outer_replacement` | Refs are hand-built: a single parse emits one reference per span, so the parser cannot currently produce this. Carried because the other path proved it real (PD-BUG-098) and both now share one implementation; without the pre-pass the outer splice leaves `...file.md.md` |

**Test Files**: unit and end-to-end — [`test/automated/unit/1-file-watching-detection/1-0-file-watching-detection/test_reference_lookup.py`](../../automated/unit/1-file-watching-detection/1-0-file-watching-detection/test_reference_lookup.py) (`TestBug150ColumnPositionIgnored`, 16 methods — 7 from the original fix, 5 added at the rework and 4 at round 3; fourteen drive the real parser **and** the real updater end to end, so the columns under test are the ones the parser actually produces rather than hand-picked constants that could agree with a broken implementation). Manual validation: `test/bug-validation/PD-BUG-150_moved_file_column_position_validation.py` (**6** checks through the real service handler; **0/4 pre-fix, 3/5 against the rejected fix, 5/5 post-rework, and 5/6 against the round-2 build vs 6/6 after round 3**). Each round repeats the same lesson: the build being replaced passed every check its predecessor shipped with. At round 3 checks 1–5 all pass against the defective build and only check 6 fails, so the prior validation could not have caught it.

**Mutation contrast** (re-measured 2026-08-30 at the rework, per the load-bearing-assertion obligation): dropping the `MARKDOWN_REFERENCE` branch from `replace_in_line` turns exactly the 4 new tests red and nothing else — as does reverting Phase 1 to call `replace_at_position` directly, which is the rejected fix's exact behaviour; dropping the `MARKDOWN` branch turns 2 updater tests red, so the moved dispatch is load-bearing for both paths; reverting to leftmost `.replace()` turns 4 red; ascending order turns 6 red; dropping the markdown de-duplication turns exactly the markdown test red; dropping the contained-overlap pre-pass turns exactly the overlap test red. Each of the three sub-mechanisms behind the ambiguous-skip reporting was mutated separately — dropping the refusal branch, never passing the callback, and dropping the summary warning — and each turns exactly that one test red. No mutation leaves the set green. (The leftmost and ascending counts are one higher than the original fix's 3 and 5 because the new combined scenario also carries duplicate spans.)

**Mutation contrast, round 3** (2026-08-31, full suite per mutation — a run scoped to one test file gives a false map): removing `_tighten_span` turns exactly the 10 padding tests red and nothing else; tightening only the leading edge turns 7 (the trailing-padding subsets); removing the `span.strip() != target` guard turns exactly the 2 indented reference-definition tests. That last guard is deliberately **not** claimed load-bearing: with it removed the damage oracle still reports zero damage, because `MARKDOWN_REFERENCE` is rewritten by a pattern-anchored replacer that never reads the span. Its test therefore pins what the guard actually guarantees — that normalization never moves a span it does not understand — rather than a corruption it does not prevent. Asserting otherwise would repeat the false-completeness pattern that got rounds 1 and 2 rejected.

#### Markdown Link Text and Span Reach Inside a Moved File (PD-BUG-153)

> **Added 2026-08-30** — the fifth pass over the same divergence, and the half PD-BUG-150 did not
> reach. That fix made the *positional* references in a moved file position-aware and left the
> markdown ones on a content-global regex the moved-file path had written for itself. Two defects
> lived in that copy.
>
> **Stale link text (the filed defect).** Because the copy existed, it never applied the PD-BUG-012
> rule the shared `replace_markdown_target` had applied since March: when a link's text is exactly
> its target — the `[references/x.md](references/x.md)` idiom — the text follows the move too. In a
> moved file the target was re-depthed and the visible text was not, so the rendered link advertised
> a path that no longer resolves from the new location. Silent, and counted as an update. It never
> self-heals: once the text differs from the target the equality condition is dead for that link
> forever, and each later move drifts it further. 258 self-named links were measured in this repo at
> triage (all relative; the 4 backtick-wrapped ones are inert, since the rule is exact equality).
>
> **Compounded targets (folded in at the fix checkpoint).** The pass was global, so when one
> reference's NEW target equalled another's OLD target the second pass re-matched text the first had
> just written and re-depthed it again — pointing a link at a different file, silently. Verified
> pre-existing on unmodified source: `[x](doc/a.md)` alone becomes `../doc/a.md` and
> `[y](../doc/a.md)` alone becomes `../../doc/a.md`, but together `[x]` lands on `../../doc/a.md`.
>
> **Structural resolution**: the two phases became one pass ordered descending by `(line, column)`,
> with inline markdown routed to a new shared primitive, `replacement.replace_markdown_at_span` —
> `replace_markdown_target` confined to the reference's own recorded span. The link-text rule
> arrives with the helper instead of being copied, and no reference can reach another's output.
>
> **Two mechanisms, deliberately separated below.** Ordering alone repairs the *forward* chain;
> only span confinement repairs the *reverse* one, where the left link's old target is what the
> right link becomes and the right link is already rewritten when the left pass runs. The first
> draft of these tests did not separate them — every chain case went green with span confinement
> removed, pinning the ordering change and not the mechanism the fix was built on. Mutation
> verification caught that; the reverse-chain class exists because of it.

| Scenario | Test | Expected Outcome |
|----------|------|------------------|
| Self-named link | `test_self_named_link_updates_both_halves` | Text and target both re-depth; asserts the stale text is **absent**, since a positive-only assertion passes against the bug (the target was always updated) |
| Self-named with title | `test_self_named_link_with_title_keeps_title_and_updates_text` | The title survives the text update |
| Control: normal text | `test_normal_link_text_is_never_rewritten` | Display text that is not the target is left byte-identical |
| Boundary: backticked text | `test_backtick_wrapped_text_is_not_treated_as_self_named` | The rule is exact equality — ``[`../doc/a.md`]`` is not the target, and rewriting it would change rendered prose, not a path |
| Boundary: reference definition | `test_reference_definition_label_is_untouched` | A definition's `link_text` is its label; it stays on the positional path with its label-anchored replacer |
| Forward chain, two lines | `test_chain_collision_does_not_compound_targets` | The filed reproduction. Red against the real pre-fix code; no single mutation reproduces whole-file-global reach, so it is pinned by the removal of that pass rather than by any one mechanism |
| Forward chain, one line | `test_chain_collision_on_a_single_line` | Same shape sharing a line — repaired by the descending order |
| Forward chain + self-named | `test_chain_collision_self_named_does_not_compound` | Both defects on one construct |
| **Reverse chain** | `test_reverse_chain_does_not_overwrite_the_right_hand_link` | The shape ordering cannot save — goes red when `replace_markdown_at_span` is swapped for the line-scoped helper |
| **Reverse chain + self-named** | `test_reverse_chain_self_named_keeps_each_pair_consistent` | Each text/target pair stays internally consistent at its own depth |
| Duplicates, one line | `test_duplicate_targets_on_one_line_are_both_updated` | De-duplication went with the content-global pass; collapsing would strand the second |
| Duplicates, separate lines | `test_duplicate_targets_on_separate_lines_are_both_updated` | Same, across lines |
| Distinct targets, one line | `test_distinct_targets_on_one_line_each_land_at_own_span` | Two unrelated markdown links do not interfere |
| Markdown + positional, one line | `test_markdown_and_positional_reference_share_a_line` | Ordering guard for the merge: what were two phases now share one pass, so neither may invalidate the other's columns |
| Surrounding prose | `test_link_text_and_surrounding_prose_are_preserved` | The span must not swallow neighbouring text |

**Test Files**: unit — [`test/automated/unit/2-link-parsing-update/test_bug153movedfilemarkdownrewrite.py`](../../automated/unit/2-link-parsing-update/test_bug153movedfilemarkdownrewrite.py) (TE-TST-162, 15 tests); manual validation — [`test/bug-validation/PD-BUG-153_moved_file_markdown_link_text_validation.py`](../../bug-validation/PD-BUG-153_moved_file_markdown_link_text_validation.py) (6 checks).

**Mutation contrast** (measured 2026-08-30, per the load-bearing-assertion obligation): removing the link-text rule reddens exactly the 4 self-named tests and drops the manual validation to 4/6; removing span confinement reddens exactly the 2 reverse-chain tests plus the renamed sibling duplicate test and drops it to 4/6 on a *different* check; reverting the descending order reddens the forward-chain and shared-line tests plus 6 pre-existing PD-BUG-150 tests; restoring the de-duplication reddens exactly the 3 duplicate tests.

> **Sibling, fixed separately**: the same span-reach defect was live on the updater path, which still dispatched `MARKDOWN` to the line-scoped replacer. Measured at this fix's similar-issues check, filed as **PD-BUG-154**, and closed 2026-08-31 — see [Updater-Path Span Reach (PD-BUG-154)](#updater-path-span-reach-pd-bug-154) below.

#### Padded Inline Markdown Link Never Re-Depthed (PD-BUG-152)

> **Added 2026-08-31.** CommonMark permits whitespace around an inline link destination, and all
> spellings render to an identical anchor — verified through markdown-it: `[x]( ../doc/y.md )`,
> `[x]( ../doc/y.md)` and `[x](../doc/y.md )` all produce `<a href="../doc/y.md">`. The markdown
> parser strips the captured destination (`_extract_url_from_link_content` begins with
> `link_content.strip()`), so `link_target` holds the **tight** path while the source line is
> padded. `replace_markdown_target` anchored its pattern on `](` immediately followed by the target
> and on the target immediately followed by a title or `)` — two juxtapositions that can never hold
> for a padded link. The substitution matched nothing, the line was returned unchanged, and the
> link was left pointing at a path that no longer exists.
>
> **Scope corrected at triage — both rewrite paths, one choke point.** The bug was filed as
> moved-file-only. Since the PD-BUG-153 fix, `replace_markdown_target` is reached by *both* paths:
> the updater path via `replace_in_line`, and the moved-file path via `replace_markdown_at_span`.
> The **updater path is the larger exposure** — it reaches every file referencing a moved target
> rather than only the file being moved — and it fails **silently**, with no warning and no count.
> The moved-file path at least emits `link_target_not_found_on_line`.
>
> **Resolution**: the pattern matches the padding in groups of its own and writes it back verbatim.
> Preserving rather than normalizing it is the rule PD-BUG-118 / PD-BUG-120 / PD-BUG-124 established
> and which `replace_reference_target` already honoured (it has carried `\s*` on both sides all
> along — confirmed at the similar-issues sweep, so there is no companion defect).

| Scenario | Test | Expected Outcome |
|----------|------|------------------|
| Padding both sides / leading / trailing / wider | `test_padded_target_is_replaced_and_padding_preserved` | Re-depthed with the authored spacing intact at its authored width; asserts the **old** padded form is absent, since the defect returned the line unchanged |
| Padding with each title quoting | `test_padding_and_title_are_both_preserved` | Padding and title both survive, in all three title quotings |
| Control: tight form | `test_tight_form_is_unaffected` | The spelling that always worked is untouched |
| Control: non-matching target | `test_non_matching_target_is_left_alone` | A padded link to a *different* target is not rewritten |
| Self-named text + padded target | `test_self_named_text_still_updates_with_padding` | The PD-BUG-012 rule survives the widened pattern; equality is against the tight target |
| Moved-file path, three paddings | `test_padded_link_follows_the_move` | The filed reproduction, through the real `ReferenceLookup` |
| Moved-file path, padded + tight | `test_padded_and_tight_links_on_one_line_both_follow` | Discriminating: pre-fix the tight half re-depthed and the padded half stayed stale |
| Moved-file path, padded chain collision | `test_padded_chain_collision_does_not_compound` | Widening the pattern must not revive PD-BUG-153 compounding — span confinement has to keep holding now that padded occurrences match at all |
| Control: padded reference definition | `test_padded_reference_definition_still_preserved` | The sibling replacer already handled padding; the fix must not disturb it |
| **Updater path**, three paddings | `test_padded_link_in_another_file_is_updated` | The half the bug was not filed against, and the silent one |
| Updater path with title | `test_padded_link_with_title_in_another_file` | Padding and title preserved off the moved-file path too |
| Control: updater path tight | `test_tight_link_in_another_file_unaffected` | Unchanged behaviour for the working spelling |

**Test Files**: unit — [`test/automated/unit/2-link-parsing-update/test_bug152paddedinlinemarkdownlink.py`](../../automated/unit/2-link-parsing-update/test_bug152paddedinlinemarkdownlink.py) (TE-TST-163, 12 functions / 21 parametrized cases); manual validation — [`test/bug-validation/PD-BUG-152_padded_inline_markdown_link_validation.py`](../../bug-validation/PD-BUG-152_padded_inline_markdown_link_validation.py) (8 checks, 3/8 pre-fix).

**Mutation contrast** (measured 2026-08-31, per the load-bearing-assertion obligation): 17 of the 21 cases are red against fully reverted source and the 4 controls are green both ways. Dropping the **leading**-whitespace group reddens 12 and leaves the trailing-only cases green; dropping the **trailing** group reddens 12 and leaves the leading-only cases green; matching the padding but **stripping it on write-back** reddens 16 and leaves only the 4 controls — so these tests pin padding *preservation*, not merely that a replacement occurred. That third mutation is the one that matters: without it the suite would pass a fix that silently normalized away the author's spacing.

#### Updater-Path Span Reach (PD-BUG-154)

> **Added 2026-08-31.** The sibling of PD-BUG-153, on the other rewrite path. `replace_in_line` —
> the shared entry point both paths use — dispatched `MARKDOWN` to the line-scoped
> `replace_markdown_target`, which anchors on the old target and substitutes **every** match in the
> string it is handed. Handed a whole line, that reach extends over neighbouring links.
>
> **The reverse chain is the shape ordering cannot save.** With two links on one line and two moves
> in one batch, a link whose OLD target equals a neighbour's NEW target re-matches the text that
> neighbour's pass has just written. Measured on pre-fix source, moves `old/a.md → new/a.md` and
> `new/a.md → final/a.md`:
>
>     [x] old/a.md  [y] new/a.md   ->  [x] new/a.md    [y] final/a.md   correct
>     [x] new/a.md  [y] old/a.md   ->  [x] final/a.md  [y] final/a.md   WRONG
>
> Descending column order repairs the first and not the second, because it is the **left** link's
> pass that reaches rightward over text already rewritten. Silent — both count as updated, no
> warning. `MARKDOWN_REFERENCE` is not exposed: its pattern is anchored to the `[label]:` prefix and
> end-of-line, so a definition line admits exactly one match.
>
> **Reachability (established at triage, and why priority is Low).** No production input can trigger
> this. The only production caller of `update_references_batch` is the directory-move Phase 1b
> batch, whose moves are uniformly prefixed — every old path under `old_dir`, every new path under
> `new_dir` — so the two sets are disjoint and the chain cannot form; the renames that would make
> them intersect are refused by the OS. Single-file moves use `update_references`, one old→new pair.
> The fix is therefore behaviour-preserving for every reachable input and was taken on structural
> grounds: leaving the documented shared entry point as the *unsafe* markdown path is the divergence
> `replacement.py` exists to prevent.

| Scenario | Test | Expected Outcome |
|----------|------|------------------|
| **Reverse chain** | `test_reverse_chain_leaves_the_right_link_alone` | The filed reproduction, through the real `update_references_batch` with real parser spans. Asserts `final/a.md` appears **once** — a positive-only assertion passes against the bug, since the left link was always rewritten correctly |
| Control: forward chain | `test_forward_chain_is_unaffected` | The mirror shape was already correct; if this reddens, the fix broke ordering rather than reach |
| Title preserved | `test_title_is_preserved` | The span covers `[text](target "title")`; splicing a bare target across it is the regression the first PD-BUG-150 fix shipped |
| Self-named text | `test_self_named_link_text_still_follows_the_move` | The PD-BUG-012 rule must survive the switch to the span-confined helper |
| Boundary: backticked text | `test_non_matching_link_text_is_left_alone` | The rule is exact equality, never resemblance |
| Duplicates, one line | `test_duplicate_targets_on_one_line_are_both_updated` | Guard on the fix, not the bug: line-scoped replacement rewrote both in the first pass and the second ref short-circuited on "already handled"; confinement removes that accident, so each duplicate needs its own pass |
| Boundary: reference definition | `test_reference_definition_stays_on_the_label_anchored_path` | `MARKDOWN_REFERENCE` must **not** be routed to the span helper — its span covers the whole line, so slicing would eat the label and orphan every `[text][label]` usage |
| **Dispatch mechanism** | `test_replace_in_line_confines_markdown_to_the_recorded_span` | Pins the dispatch directly, independent of the updater — so a future revert reddens even if no updater-level scenario exercises the chain |

**Test Files**: unit — [`test/automated/unit/2-link-parsing-update/test_bug154updatermarkdownspanreach.py`](../../automated/unit/2-link-parsing-update/test_bug154updatermarkdownspanreach.py) (TE-TST-164, 8 tests). No manual validation test: the Step 21 scenario must be reproducible by UI or filesystem actions, and no filesystem action sequence can produce the triggering batch.

**Mutation contrast** (measured 2026-08-31, per the load-bearing-assertion obligation): reverting the one-line dispatch to the line-scoped helper reddens **exactly 2** of the 8 — the reverse-chain case and the dispatch-mechanism case — and leaves the other 1844 tests in the suite untouched, so these tests pin the changed mechanism and nothing else. Splicing the bare target across the span instead (the behaviour Code Review rejected in the first PD-BUG-150 fix) reddens **7 of 8**, so the title, self-named-text and non-matching-text guards are load-bearing against that historical failure mode; the reference-definition case correctly survives it, because `MARKDOWN_REFERENCE` never enters the span helper — which is the discrimination that boundary test exists to make. The 6 guard cases pass both pre- and post-fix by design: they protect the fix rather than reproduce the bug, and their contrast comes from the second mutation, not the first.


## Test Implementation Roadmap

### Priority Order

1. **High Priority** (Implemented ✅)
   - [x] Dry-run vs real mode behavior
   - [x] Multi-format link updates (markdown, YAML, JSON, Python, Dart, generic)
   - [x] Anchor preservation
   - [x] Backup creation
   - [x] Multiple references in same file

2. **Medium Priority** (Implemented ✅)
   - [x] Path normalization and replacement strategies
   - [x] Relative path calculation
   - [x] Error handling for non-existent files

3. **Low Priority** (Gaps identified)
   - [ ] Bottom-to-top sort verification (TDD: references sorted descending by line/column)
   - [ ] Multiple references on same line (TDD: rightmost first — not explicitly tested)
   - [ ] Atomic write failure recovery (TDD: NamedTemporaryFile + shutil.move atomicity)
   - [ ] Encoding handling (TDD mentions file read errors from encoding issues)
   - [ ] Containing file deleted between parse and update (TDD: logged and skipped)
   - [ ] Unknown `link_type` fallback to `_replace_at_position()` (TDD: column-offset replacement)

### Coverage Gaps

- **Sort order verification**: TDD specifies bottom-to-top replacement order — no test explicitly verifies sort behavior
- **Same-line multi-ref**: TDD acceptance criteria AC-2 — not tested
- **Atomic write safety**: `_write_file_safely` is tested for being called but not for crash recovery
- **Encoding errors**: No test for files with encoding issues (e.g., UTF-16, binary mixed content)

---

_Retrospective Test Specification — documents existing test suite as of 2026-02-24._
