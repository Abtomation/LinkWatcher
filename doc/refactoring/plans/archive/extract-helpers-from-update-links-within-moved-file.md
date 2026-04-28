---
id: PD-REF-136
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-02
updated: 2026-04-02
target_area: reference_lookup
refactoring_scope: Extract helpers from update_links_within_moved_file
priority: Medium
mode: lightweight
---

# Lightweight Refactoring Plan: Extract helpers from update_links_within_moved_file

- **Target Area**: reference_lookup
- **Priority**: Medium
- **Created**: 2026-04-02
- **Author**: AI Agent & Human Partner
- **Status**: Planning
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD135 — Extract helpers from update_links_within_moved_file()

**Scope**: Extract three private helpers from `update_links_within_moved_file()` in `src/linkwatcher/reference_lookup.py` to separate mixed concerns (read, parse, filter, calculate, replace, write, rescan). The method is ~200 LOC mixing content I/O, link filtering, path recalculation, content replacement (markdown-specific + generic), backup/write, and DB rescan. After extraction the main method becomes a clear orchestrator. No interface or signature changes.

**Helpers to extract**:
1. `_filter_relative_links(references)` — filters out URLs, absolute paths, Windows drive-letter paths
2. `_replace_links_in_lines(lines, relative_links, old_file_path, new_file_path)` — replacement loop with markdown-specific and generic branches, returns `(lines, links_updated)`
3. `_write_with_backup(abs_new_path, content, backup_enabled)` — backup creation + file write

**Changes Made**:
- [x] Extract `_filter_relative_links(references)` — filters URLs, absolute paths, drive-letter paths from parsed references
- [x] Extract `_replace_links_in_lines(lines, relative_links, old_file_path, new_file_path)` — markdown regex + line-targeted replacement loop, returns `(lines, links_updated)`
- [x] Extract `_write_with_backup(abs_new_path, content, backup_enabled)` — backup creation + file write
- [x] Simplify main method to orchestrator (~70 LOC down from ~200 LOC)

**Test Baseline**: 67 passed (unit/integration), 649 passed full suite
**Test Result**: 67 passed (unit/integration), 649 passed, 5 skipped, 6 xfailed — no regressions

**Documentation & State Updates**:
- [x] Feature implementation state file (1.1.1) updated, or N/A — _Grepped state file: references prior TD035 extraction into reference_lookup.py, not internal method structure. No update needed._
- [x] TDD (1.1.1) updated, or N/A — _Grepped TDD: references `_update_links_within_moved_file` (handler wrapper), not ReferenceLookup internals. No interface changes._
- [x] Test spec (1.1.1) updated, or N/A — _Grepped test spec: no references to `update_links_within_moved_file`. No behavior change._
- [x] FDD (1.1.1) updated, or N/A — _Grepped FDD: no references to changed method._
- [x] ADR updated, or N/A — _Grepped ADR directory: no references to changed method._
- [x] Validation tracking updated, or N/A — _R3 validation complete for 1.1.1. Internal helper extraction doesn't affect validation results._
- [x] Technical Debt Tracking: TD135 marked resolved

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD135 | Complete | None | None |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
