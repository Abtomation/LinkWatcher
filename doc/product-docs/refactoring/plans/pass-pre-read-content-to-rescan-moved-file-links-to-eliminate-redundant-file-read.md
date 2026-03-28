---
id: PD-REF-114
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-27
updated: 2026-03-27
mode: lightweight
target_area: Move Handling
refactoring_scope: Pass pre-read content to rescan_moved_file_links to eliminate redundant file read
priority: Medium
---

# Lightweight Refactoring Plan: Pass pre-read content to rescan_moved_file_links to eliminate redundant file read

- **Target Area**: Move Handling
- **Priority**: Medium
- **Created**: 2026-03-27
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD108 — Eliminate redundant file read in rescan_moved_file_links

**Scope**: `rescan_moved_file_links()` always reads the file from disk via `parse_file()`, but all 4 callers inside `update_links_within_moved_file()` already have the file content in memory (read at line 421). Add an optional `content` parameter; when provided, use `parse_content()` instead of `parse_file()` to skip the redundant disk read. The `process_directory_file_move()` caller (line 309) has no content available, so it continues using the default disk-read path.

**Changes Made**:
- [x] Add `content: str = None` parameter to `rescan_moved_file_links()` (reference_lookup.py:232)
- [x] When `content` is provided, use `self.parser.parse_content(content, abs_new_path)` instead of `self.parser.parse_file(abs_new_path)` (reference_lookup.py:243-246)
- [x] Pass `content` from all 4 callsites in `update_links_within_moved_file()` (lines 429, 450, 463, 543)

**Test Baseline**: 597 passed, 5 skipped, 7 xfailed
**Test Result**: 597 passed, 5 skipped, 7 xfailed. Full regression identical to baseline.

**Documentation & State Updates**:
- [x] Feature implementation state file (1.1.1) updated, or N/A — _Grepped state files for `rescan_moved_file_links` — no references._
- [x] TDD (1.1.1) updated, or N/A — _Grepped TDD directory — no references to changed method._
- [x] Test spec (1.1.1) updated, or N/A — _Grepped test specs — no references. No behavior change._
- [x] FDD (1.1.1) updated, or N/A — _Grepped FDD directory — no references to changed method._
- [x] ADR updated, or N/A — _Grepped ADR directory — no references._
- [x] Validation tracking updated, or N/A — _TD108 sourced from PD-VAL-055; will be auto-noted when marked resolved via Update-TechDebt._
- [x] Technical Debt Tracking: TD108 marked resolved via Update-TechDebt.ps1

**Bugs Discovered**: None

<!-- BATCH MODE: Copy the "## Item N" section above for each additional debt item in this session -->

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD108 | Complete | None | None |

## Related Documentation
- [Technical Debt Tracking](/doc/product-docs/state-tracking/permanent/technical-debt-tracking.md)
