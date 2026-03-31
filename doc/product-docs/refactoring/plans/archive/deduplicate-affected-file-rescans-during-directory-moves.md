---
id: PD-REF-125
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-30
updated: 2026-03-30
refactoring_scope: Deduplicate affected-file rescans during directory moves
priority: Medium
mode: lightweight
target_area: reference_lookup.py
---

# Lightweight Refactoring Plan: Deduplicate affected-file rescans during directory moves

- **Target Area**: reference_lookup.py
- **Priority**: Medium
- **Created**: 2026-03-30
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Dependencies and Impact
- **Affected Components**: `linkwatcher/reference_lookup.py`, `linkwatcher/handler.py`
- **Internal Dependencies**: `handler.py._handle_directory_moved()` calls `reference_lookup.process_directory_file_move()` in a loop
- **Risk Assessment**: Low — Internal performance optimization; no interface changes, no behavioral change

## Item 1: TD128 — Deduplicate affected-file rescans during directory moves

**Scope**: During directory moves, `process_directory_file_move` calls `cleanup_after_file_move` per moved file, which rescans all affected source files. If files A and B are both referenced by the same 50 source files, those 50 files are rescanned twice. Fix: add a `deferred_rescan_files` set parameter so the caller can collect affected files across the loop, then do one bulk rescan at the end.

**Changes Made**:
- [x] Added optional `deferred_rescan_files` parameter to `cleanup_after_file_move` — when provided, collects affected files into the set instead of rescanning immediately
- [x] Added optional `deferred_rescan_files` parameter to `process_directory_file_move`, passed through to `cleanup_after_file_move`
- [x] In `handler.py._handle_directory_moved`, created shared `deferred_rescan_files` set, passed to each `process_directory_file_move` call, then bulk rescans all collected files once after the loop

**Test Baseline**: 621 passed, 5 skipped, 5 xfailed
**Test Result**: 621 passed, 5 skipped, 5 xfailed (identical)

**Documentation & State Updates**:
- [x] Feature implementation state file (1.1.1) updated, or N/A — _Grepped state file; references handler._handle_directory_moved but not at parameter level. N/A._
- [x] TDD (1.1.1) updated, or N/A — _Grepped TDD; mentions process_directory_file_move and cleanup_after_file_move but with pre-existing parameter drift (co_moved_old_paths). Adding optional parameter doesn't change documented design. N/A._
- [x] Test spec (1.1.1) updated, or N/A — _Grepped test specs; no reference to cleanup_after_file_move or process_directory_file_move. N/A._
- [x] FDD (1.1.1) updated, or N/A — _No FDD for 1.1.1 at parameter level. N/A._
- [x] ADR updated, or N/A — _No ADR covers rescan deduplication. N/A._
- [x] Validation tracking updated, or N/A — _Performance optimization only; no validation dimension affected. N/A._
- [ ] Technical Debt Tracking: TD128 marked resolved

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD128 | Complete | None | None |

## Related Documentation
- [Technical Debt Tracking](/doc/product-docs/state-tracking/permanent/technical-debt-tracking.md)
