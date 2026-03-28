---
id: PD-REF-101
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-27
updated: 2026-03-27
refactoring_scope: Eliminate triple file read in LinkValidator._check_file()
target_area: Link Validation
mode: lightweight
priority: Medium
---

# Lightweight Refactoring Plan: Eliminate triple file read in LinkValidator._check_file()

- **Target Area**: Link Validation
- **Priority**: Medium
- **Created**: 2026-03-27
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD084 — Eliminate triple file read for markdown files in LinkValidator._check_file()

**Scope**: `_check_file()` reads each markdown file 3 times: once via `parse_file()`, once via `_get_code_block_lines()`, once via `_get_archival_details_lines()`. Refactor to read file once, pass content to `parse_content()`, and refactor the two helper methods to accept pre-read lines instead of a file path. Source: PD-VAL-059 performance validation.

**Changes Made**:
- [x] Read file once in `_check_file()`, use `self.parser.parse_content(content, file_path)` (validator.py:210-221)
- [x] Refactor `_get_code_block_lines()` to accept `lines: List[str]` instead of `file_path: str` (validator.py:371-389)
- [x] Refactor `_get_archival_details_lines()` to accept `lines: List[str]` instead of `file_path: str` (validator.py:391-451)

**Test Baseline**: test_validator.py — 74 passed
**Test Result**: test_validator.py — 74 passed. Full regression: 593 passed, 5 skipped, 7 xfailed. No new failures.

**Documentation & State Updates**:
- [x] Feature implementation state file (6.1.1) updated, or N/A — _No references to changed private methods in state file._
- [x] TDD (6.1.1) updated, or N/A — _6.1.1 is Tier 1, no TDD exists._
- [x] Test spec (6.1.1) updated, or N/A — _No test spec for 6.1.1; no behavior change._
- [x] FDD (6.1.1) updated, or N/A — _6.1.1 is Tier 1, no FDD exists._
- [x] ADR updated, or N/A — _Grepped ADR directory — no references to changed methods._
- [x] Validation tracking updated, or N/A — _R2-M-013 references this descriptively; will be addressed when TD084 is marked resolved via Update-TechDebt._
- [x] Technical Debt Tracking: TD084 marked resolved via Update-TechDebt.ps1

**Bugs Discovered**: None

<!-- BATCH MODE: Copy the "## Item N" section above for each additional debt item in this session -->

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD084 | Complete | None | None |

## Related Documentation
- [Technical Debt Tracking](/doc/product-docs/state-tracking/permanent/technical-debt-tracking.md)
