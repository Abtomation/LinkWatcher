---
id: PD-REF-031
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-02
updated: 2026-03-02
refactoring_scope: Eliminate double-rescan of moved file links (TD016)
mode: lightweight
target_area: LinkMaintenanceHandler
priority: Medium
---

# Lightweight Refactoring Plan: Eliminate double-rescan of moved file links (TD016)

- **Target Area**: LinkMaintenanceHandler
- **Priority**: Medium
- **Created**: 2026-03-02
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (≤15 min effort, single file, no architectural impact)

## Item 1: TD016 — Eliminate double-rescan of moved file links

**Scope**: `_handle_file_moved` calls `_cleanup_database_after_file_move` which rescans all affected source files (including the moved file itself if self-referencing), then calls `_update_links_within_moved_file` which removes and re-adds the moved file's DB entries again. Fix: pass the moved file's old path to `_cleanup_database_after_file_move` so it excludes the moved file from its rescan loop, making `_update_links_within_moved_file` the single authority for the moved file's own DB entries.

**Changes Made**:
- [x] Added `moved_file_path=None` parameter to `_cleanup_database_after_file_move` (line 366)
- [x] Added `if file_path == moved_file_path: continue` guard in the rescan loop (line 394)
- [x] Updated call site in `_handle_file_moved` to pass `moved_file_path=old_path` (line 272)

**Test Baseline**: 344 passed, 9 failed (pre-existing), 4 skipped
**Test Result**: 344 passed, 9 failed (same pre-existing), 4 skipped — no regressions. 25/25 move detection tests pass.

**Documentation & State Updates**:
- [x] Feature implementation state file updated — N/A (no feature state change)
- [x] TDD updated — N/A (no interface/design change, internal method only)
- [x] Test spec updated — N/A (no behavior change, internal optimization)
- [x] FDD updated — N/A (no functional change)
- [x] Technical Debt Tracking: TD016 marked resolved via Update-TechDebt.ps1

**Bugs Discovered**: None

<!-- BATCH MODE: Copy the "## Item N" section above for each additional debt item in this session -->

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD016 | Complete | None | None (all N/A) |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
