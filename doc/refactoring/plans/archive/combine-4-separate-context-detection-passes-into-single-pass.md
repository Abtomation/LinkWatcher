---
id: PD-REF-189
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-09
updated: 2026-04-09
target_area: LinkValidator
mode: lightweight
priority: Medium
refactoring_scope: Combine 4 separate context detection passes into single pass
---

# Lightweight Refactoring Plan: Combine 4 separate context detection passes into single pass

- **Target Area**: LinkValidator
- **Priority**: Medium
- **Created**: 2026-04-09
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD204 — Combine 4 context detection passes into single pass

**Scope**: Replace 4 separate `_get_*_lines()` static methods (code blocks, archival details, table rows, placeholder lines) with a single `_get_context_lines()` method that returns all 4 frozensets in one pass over the lines. Dims: PE (Performance). Single file: `linkwatcher/validator.py`.

**Changes Made**:
- [x] Replaced 4 static methods (`_get_code_block_lines`, `_get_archival_details_lines`, `_get_table_row_lines`, `_get_placeholder_lines`) with single `_get_context_lines()` returning a 4-tuple of frozensets
- [x] Updated call site at line 335-340 to single destructured call
- [x] Removed redundant `_FENCE_RE.match()` check in table row detection (fence lines never start with `|`)
- [x] Updated test `test_get_placeholder_lines_detects_replace_with_actual` → `test_get_context_lines_detects_placeholder_lines`

**Test Baseline**: 763 passed, 5 skipped, 4 deselected, 4 xfailed, 0 failed (34.33s)
**Test Result**: 763 passed, 5 skipped, 4 deselected, 4 xfailed, 0 failed (35.34s) — identical to baseline

**Documentation & State Updates**:
- [x] Feature implementation state file (6.1.1) updated, or N/A — _N/A: grepped state file — no references to changed internal method names_
- [x] TDD (6.1.1) updated, or N/A — _N/A: grepped TDD — no references to changed methods; no interface change (same frozenset outputs)_
- [x] Test spec (6.1.1) updated, or N/A — _N/A: grepped test specs — no references to changed methods_
- [x] FDD (6.1.1) updated, or N/A — _N/A: internal implementation change only, no functional behavior change_
- [x] ADR updated, or N/A — _N/A: no architectural decision affected_
- [x] Validation tracking updated, or N/A — _N/A: change doesn't affect active validation rounds_
- [x] Technical Debt Tracking: TD204 marked resolved via Update-TechDebt.ps1

**Bugs Discovered**: None

<!-- BATCH MODE: Copy the "## Item N" section above for each additional debt item in this session -->

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD204 | Complete | None | None |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
