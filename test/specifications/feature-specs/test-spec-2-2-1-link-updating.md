---
id: PF-TSP-040
type: Process Framework
category: Test Specification
version: 1.0
created: 2026-02-24
updated: 2026-02-24
feature_id: 2.2.1
feature_name: Link Updating
tdd_path: doc/product-docs/technical/architecture/design-docs/tdd/tdd-2-2-1-link-updater-t2.md
test_tier: 2
retrospective: true
---

# Test Specification: Link Updating

> **Retrospective Document**: This test specification describes the existing test suite for Link Updating, documented after implementation during framework onboarding. Content is derived from analysis of existing test files.

## Overview

This document provides comprehensive test specifications for the **Link Updating** feature (ID: 2.2.1), derived from the Technical Design Document [PD-TDD-026](../../../doc/product-docs/technical/architecture/design-docs/tdd/tdd-2-2-1-link-updater-t2.md).

**Test Tier**: 2 (Unit + Integration)
**TDD Reference**: [TDD PD-TDD-026](../../../doc/product-docs/technical/architecture/design-docs/tdd/tdd-2-2-1-link-updater-t2.md)

## Feature Context

### TDD Summary

The `LinkUpdater` class performs atomic file modifications to update link references after file moves. It uses a bottom-to-top replacement strategy (sorting references by line/column descending), link-type-specific replacement functions (`_replace_markdown_target`, `_replace_reference_target`, `_replace_at_position`), and atomic writes via `NamedTemporaryFile` + `shutil.move()`. Supports dry-run mode and backup creation.

### Test Complexity Assessment

**Selected Tier**: 2 — Multiple replacement strategies, atomic write safety, and multi-format integration.

## Cross-References

### Functional Requirements Reference

> **Primary Documentation**: [FDD PD-FDD-027](../../../doc/product-docs/functional-design/fdds/fdd-2-2-1-link-updater.md)

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
| LinkUpdater | Exact path replace | `test_replace_path_part_exact_match` — exact match including leading slash | None |
| LinkUpdater | Partial path replace | `test_replace_path_part_partial_match` — `docs/old.txt` → `docs/new.txt` | None |
| LinkUpdater | No match | `test_replace_path_part_no_match` — non-matching path unchanged | None |
| LinkUpdater | Dry-run update | `test_update_references_dry_run` — reports success, file unchanged | `temp_project_dir` |
| LinkUpdater | Real update | `test_update_references_real_mode` — file content modified | `temp_project_dir` |
| LinkUpdater | Multi-ref same file | `test_update_multiple_references_same_file` — 3 refs all updated | `temp_project_dir` |
| LinkUpdater | Backup creation | `test_update_references_with_backup` — .linkwatcher.bak created with original content | `temp_project_dir` |
| LinkUpdater | Error handling | `test_update_references_error_handling` — non-existent file: 1 error, 0 updates | None |
| LinkUpdater | Atomic writes | `test_atomic_file_operations` — _write_file_safely called during updates | `temp_project_dir` |

**Test File**: [`tests/unit/test_updater.py`](../../../tests/unit/test_updater.py) (20 methods)

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

**Test File**: [`tests/integration/test_link_updates.py`](../../../tests/integration/test_link_updates.py) (10 methods)

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

## AI Agent Session Handoff Notes

### Implementation Context

**Feature Summary**: Atomic file modifier with link-type-specific replacement, dry-run, and backup support.
**Test Focus**: Replacement correctness across formats, dry-run isolation, backup creation, error handling.
**Key Challenges**: Verifying atomic write safety without actually simulating crashes.

### Files to Reference

- **TDD**: [`doc/product-docs/technical/architecture/design-docs/tdd/tdd-2-2-1-link-updater-t2.md`](../../../doc/product-docs/technical/architecture/design-docs/tdd/tdd-2-2-1-link-updater-t2.md)
- **Existing Tests**: [`tests/unit/test_updater.py`](../../../tests/unit/test_updater.py) (20 methods), [`tests/integration/test_link_updates.py`](../../../tests/integration/test_link_updates.py) (10 methods)
- **Source Code**: [`linkwatcher/updater.py`](../../../linkwatcher/updater.py)

---

_Retrospective Test Specification — documents existing test suite as of 2026-02-24._
