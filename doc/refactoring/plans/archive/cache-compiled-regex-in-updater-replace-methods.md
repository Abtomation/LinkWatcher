---
id: PD-REF-123
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-28
updated: 2026-03-28
target_area: Link Updating
mode: lightweight
priority: Medium
refactoring_scope: Cache compiled regex in updater replace methods
---

# Lightweight Refactoring Plan: Cache compiled regex in updater replace methods

- **Target Area**: Link Updating
- **Priority**: Medium
- **Created**: 2026-03-28
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD120 — Cache compiled regex in updater replace methods

**Scope**: `_replace_markdown_target()` and `_replace_reference_target()` in updater.py compile a new regex per call via `re.sub(pattern, ...)`. Add instance-level `_regex_cache` dict to `LinkUpdater` and use cached compiled patterns instead. Source: PD-VAL-059 performance validation.

**Changes Made**:
- [x] Add `self._regex_cache: Dict[str, re.Pattern] = {}` to `LinkUpdater.__init__()` (updater.py:70)
- [x] Replace `re.sub(pattern, ...)` with cached `re.compile(pattern).sub(...)` in `_replace_markdown_target()` (updater.py:305-308)
- [x] Replace `re.sub(pattern, ...)` with cached `re.compile(pattern).sub(...)` in `_replace_reference_target()` (updater.py:329-332)

**Test Baseline**: 597 passed, 5 skipped, 7 xfailed
**Test Result**: 597 passed, 5 skipped, 7 xfailed. No new failures.

**Documentation & State Updates**:
- [x] Feature implementation state file (2.2.1) updated, or N/A — _Grepped state file: no references to `_replace_markdown_target`, `_replace_reference_target`, or regex caching. Internal optimization, no state change._
- [x] TDD (2.2.1) updated, or N/A — _Grepped tdd-2-2-1: no references to regex compilation or caching. Internal implementation detail._
- [x] Test spec (2.2.1) updated, or N/A — _Grepped test-spec-2-2-1: no references to regex caching. No behavior change._
- [x] FDD (2.2.1) updated, or N/A — _Grepped fdd-2-2-1: no references to regex compilation. Internal optimization._
- [x] ADR updated, or N/A — _No ADR for link updating regex patterns._
- [x] Validation tracking updated, or N/A — _R2-L-019 references this issue descriptively. Will be addressed when TD120 is marked resolved._
- [x] Technical Debt Tracking: TD120 marked resolved via Update-TechDebt.ps1

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD120 | Complete | None | None |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
