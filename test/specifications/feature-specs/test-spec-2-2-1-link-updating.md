---
id: TE-TSP-040
description: "2.2.1 Tier 2 — Atomic updates, dry-run, backup creation"
type: Process Framework
category: Test Specification
version: 1.1
created: 2026-02-24
updated: 2026-07-06
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
