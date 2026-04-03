---
id: PD-REF-121
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-27
updated: 2026-03-27
mode: lightweight
refactoring_scope: Fix TDD overstatement of PowerShell Join-Path/Import-Module dedicated support
target_area: PowerShellParser documentation
priority: Medium
---

# Lightweight Refactoring Plan: Fix TDD overstatement of PowerShell Join-Path/Import-Module dedicated support

- **Target Area**: PowerShellParser documentation
- **Priority**: Medium
- **Created**: 2026-03-27
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD124 — Fix TDD overstatement of PowerShell Join-Path/Import-Module dedicated support

**Scope**: The TDD for feature 2.1.1 (tdd-2-1-1-parser-framework-t2.md, line 206) claims the PowerShellParser uses a `join_path_pattern` for `Join-Path -ChildPath` arguments and extracts `Import-Module` paths via dedicated handling. The actual code has no such dedicated patterns — paths from these constructs are caught incidentally by the general `quoted_pattern` and `path_pattern`. The module docstring in powershell.py (line 6) repeats this overstatement. Both need correction.

**Changes Made**:
<!-- Fill in after implementation -->
- [x] TDD line 206: Rewrote PowerShellParser description to accurately list shared patterns from patterns.py, path_pattern for comments, and block_comment_start/end for region tracking
- [x] powershell.py docstring: Replaced "Join-Path arguments, and Import-Module paths" with "quoted string literals (file and directory paths), and embedded markdown links"

**Test Baseline**: N/A — documentation-only change
**Test Result**: N/A — documentation-only change

**Documentation & State Updates**:
- [x] Feature implementation state file (2.1.1) updated — fixed 3 references (summary, component table, enhancement log)
- [x] TDD (2.1.1) updated — primary fix target, rewrote PowerShellParser description
- [x] Test spec (2.1.1) — N/A: grepped test spec; only reference is to test method names (`test_join_path_patterns`) which accurately describe the tests, not parser internals
- [x] FDD (2.1.1) updated — fixed AC-5 acceptance criterion description
- [x] ADR — N/A: grepped ADR directory for Join-Path/Import-Module — no matches
- [x] Validation tracking — N/A: this is a documentation accuracy fix, does not affect validation scoring
- [x] Technical Debt Tracking: TD124 marked Resolved via Update-TechDebt.ps1

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD124 | Complete | None | TDD 2.1.1, powershell.py docstring, state file 2.1.1 (×3), FDD 2.1.1 |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
