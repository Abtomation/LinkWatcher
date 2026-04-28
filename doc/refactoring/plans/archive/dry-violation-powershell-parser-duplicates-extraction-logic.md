---
id: PD-REF-129
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-02
updated: 2026-04-02
priority: Medium
target_area: src/linkwatcher/parsers/powershell.py
mode: lightweight
refactoring_scope: DRY violation: PowerShell parser duplicates extraction logic
---

# Lightweight Refactoring Plan: DRY violation: PowerShell parser duplicates extraction logic

- **Target Area**: src/linkwatcher/parsers/powershell.py
- **Priority**: Medium
- **Created**: 2026-04-02
- **Author**: AI Agent & Human Partner
- **Status**: Planning
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD131 — DRY violation in PowerShell parser extraction logic

**Scope**: `parse_content` lines 99-204 duplicate 4 extraction phases (quoted paths, all-quoted embedded, directory paths, embedded markdown links) that already exist in `_extract_all_paths_from_line`. Refactor `parse_content` to delegate its per-line extraction to `_extract_all_paths_from_line`, removing ~105 lines of duplicated code. The only behavioral difference is that `_extract_all_paths_from_line` has a 5th step (unquoted paths) not present in `parse_content` — but `parse_content` already handles comments via `_extract_paths_from_segment` which covers unquoted paths for comment text, so adding unquoted extraction for code lines is a safe superset (dedup prevents double-counting).

**Dims**: CQ (Code Quality)

**Changes Made**:
- [x] Replaced `parse_content` lines 99-204 (4 duplicated extraction phases) with a single call to `_extract_all_paths_from_line`
- [x] Enhanced `_extract_all_paths_from_line` to derive link_type variants (`-dir`, `-embedded-md-link`) from the base type, preserving distinct `link_type` values per extraction phase
- [x] Kept comment extraction via `_extract_paths_from_segment` as-is (handles offset-aware comment-specific extraction)

**Test Baseline**: 39 passed, 0 failed (powershell parser); 631 passed, 14 failed (full suite, pre-existing)
**Test Result**: 39 passed, 0 failed (powershell parser); 631 passed, 14 failed (full suite, same pre-existing failures)

**Documentation & State Updates**:
- [x] Feature implementation state file (2.1.1) updated, or N/A — _Grepped state file: references PowerShellParser at high level only, no mention of internal extraction methods; no update needed_
- [x] TDD (2.1.1) updated, or N/A — _Grepped TDD: references parse_content as public API; internal method restructuring doesn't change interface; no update needed_
- [x] Test spec (2.1.1) updated, or N/A — _Grepped test spec: no matches for changed methods; no behavior change affects spec_
- [x] FDD (2.1.1) updated, or N/A — _Grepped FDD: mentions PowerShellParser at component level only; no functional change_
- [x] ADR updated, or N/A — _Grepped ADR directory: no matches for PowerShellParser or changed methods_
- [x] Validation tracking updated, or N/A — _2.1.1 is tracked in R3 validation-tracking-3.md but this internal refactoring doesn't affect validation scores; DRY note in PD-VAL-065 is the source of this TD_
- [x] Technical Debt Tracking: TD131 marked resolved via Update-TechDebt.ps1

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD131 | Complete | None | None |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
