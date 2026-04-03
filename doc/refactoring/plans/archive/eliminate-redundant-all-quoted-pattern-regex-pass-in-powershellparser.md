---
id: PD-REF-144
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-02
updated: 2026-04-02
priority: Medium
mode: lightweight
target_area: linkwatcher/parsers/powershell.py
refactoring_scope: Eliminate redundant all_quoted_pattern regex pass in PowerShellParser
---

# Lightweight Refactoring Plan: Eliminate redundant all_quoted_pattern regex pass in PowerShellParser

- **Target Area**: linkwatcher/parsers/powershell.py
- **Priority**: Medium
- **Created**: 2026-04-02
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD146 — Redundant all_quoted_pattern regex pass

**Scope**: In `_extract_all_paths_from_line()`, step 1 (`quoted_pattern`) and step 2 (`all_quoted_pattern`) both scan every quoted string. `all_quoted_pattern` is a superset of `quoted_pattern`, so every step 1 match is re-matched in step 2. Merge both steps into a single `all_quoted_pattern` pass: if the whole content is a file path, add it directly; otherwise extract embedded paths. Eliminates one full regex pass per line.

**Dims**: PE (Performance)

**Changes Made**:
- [x] Merged steps 1 (`quoted_pattern`) and 2 (`all_quoted_pattern`) into single `all_quoted_pattern` pass in `_extract_all_paths_from_line()`
- [x] Removed `quoted_pattern` attribute from `PowerShellParser.__init__()` (no longer needed)
- [x] Removed unused `QUOTED_PATH_PATTERN` import
- [x] Updated `test_parser_initialization` to assert `all_quoted_pattern` instead of `quoted_pattern`

**Test Baseline**: 656 passed, 5 skipped, 6 xfailed (39 PS parser tests)
**Test Result**: 656 passed, 5 skipped, 6 xfailed (39 PS parser tests) — identical

**Documentation & State Updates**:
- [x] Feature implementation state file (2.1.1) updated, or N/A — _Grepped state file: references to `quoted_pattern` are about MarkdownParser (PF-STA-057), not PowerShellParser internal. No update needed._
- [x] TDD (2.1.1) updated, or N/A — _Grepped TDD PD-TDD-025: no references to `quoted_pattern` or `all_quoted_pattern`._
- [x] Test spec (2.1.1) updated, or N/A — _Grepped test-spec-2-1-1: no references to changed internal method._
- [x] FDD (2.1.1) updated, or N/A — _Grepped FDD PD-FDD-026: no references to `quoted_pattern` or `all_quoted_pattern`._
- [x] ADR updated, or N/A — _Grepped ADR directory: no references to changed component._
- [x] Validation tracking updated, or N/A — _Internal performance optimization, no functional change affecting validation criteria._
- [x] Technical Debt Tracking: TD146 marked resolved via Update-TechDebt.ps1

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD146 | Complete | None | None (all N/A — internal-only change) |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)

