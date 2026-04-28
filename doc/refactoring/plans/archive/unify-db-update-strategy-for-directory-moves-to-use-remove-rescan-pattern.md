---
id: PD-REF-033
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-02
updated: 2026-03-02
target_area: LinkMaintenanceHandler._handle_directory_moved
refactoring_scope: Unify DB update strategy for directory moves to use remove+rescan pattern
priority: Medium
mode: lightweight
---

# Lightweight Refactoring Plan: Unify DB update strategy for directory moves to use remove+rescan pattern

- **Target Area**: LinkMaintenanceHandler._handle_directory_moved
- **Priority**: Medium
- **Created**: 2026-03-02
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (≤15 min effort, single file, no architectural impact)

## Item 1: TD017 — Unify DB update strategy in _handle_directory_moved

**Scope**: Replace `link_db.update_target_path()` in `_handle_directory_moved` with the same remove+rescan pattern used by file moves (`_cleanup_database_after_file_move`). Also upgrade reference lookup from exact-path `get_references_to_file()` to multi-format `_find_references_multi_format()` + `_collect_path_updates()`. This ensures both code paths use identical DB update logic, eliminating inconsistent edge-case behaviors and stale reference metadata.

**Changes** (all in `src/linkwatcher/handler.py`, `_handle_directory_moved` method):
- [x] Replace `self.link_db.get_references_to_file(old_file_path)` with `self._find_references_multi_format(old_file_path)`
- [x] Add `path_updates = self._collect_path_updates(old_file_path, new_file_path)` after finding references
- [x] Replace `self.link_db.update_target_path(old_file_path, new_file_path)` with `self._cleanup_database_after_file_move(references, path_updates, moved_file_path=old_file_path)`
- [N/A] Replace `self._rescan_moved_file_links(...)` — kept as-is; `_update_links_within_moved_file` would incorrectly recalculate relative links between co-moved files in a directory move
- [N/A] Remove `_rescan_moved_file_links` — still needed for directory moves

**Test Baseline**: 36 passed (directory move + integration tests), 344 passed full suite (9 pre-existing failures)
**Test Result**: 36 passed (directory move + integration tests), 344 passed full suite (same 9 pre-existing failures) — zero regressions

**Documentation & State Updates**:
- [x] Feature implementation state file updated (N/A — no feature state change)
- [x] TDD updated (added implementation note #8 and resolved debt entry to tdd-1-1-1-file-system-monitoring-t2.md)
- [x] Test spec updated (N/A — no behavior change)
- [x] FDD updated (N/A — no functional change)
- [x] Technical Debt Tracking: TD item marked resolved via Update-TechDebt.ps1

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD017 | Complete | None | TD tracking |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
