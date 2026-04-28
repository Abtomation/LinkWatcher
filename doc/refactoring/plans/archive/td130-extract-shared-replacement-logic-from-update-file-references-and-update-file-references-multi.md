---
id: PD-REF-128
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-02
updated: 2026-04-02
refactoring_scope: TD130: Extract shared replacement logic from _update_file_references and _update_file_references_multi
mode: lightweight
target_area: src/linkwatcher/updater.py
priority: Medium
---

# Lightweight Refactoring Plan: TD130: Extract shared replacement logic from _update_file_references and _update_file_references_multi

- **Target Area**: src/linkwatcher/updater.py
- **Priority**: Medium
- **Created**: 2026-04-02
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD130 — Extract shared replacement logic into _apply_replacements helper

**Scope**: `_update_file_references` (L182-312) and `_update_file_references_multi` (L314-427) share ~100 lines of identical logic: bottom-to-top sorting, stale detection, line replacement, Phase 2 python module rename, and file write. Extract a `_apply_replacements(self, abs_file_path, file_path, replacement_items)` helper that both methods delegate to after preparing their `List[Tuple[LinkReference, str]]` replacement items. Dims: CQ (Code Quality).

**Changes Made**:
- [x] New `_apply_replacements` method extracted (updater.py) with full algorithm docstring
- [x] `_update_file_references` refactored to build replacement_items then delegate to `_apply_replacements`
- [x] `_update_file_references_multi` refactored to build replacement_items then delegate to `_apply_replacements`

**Test Baseline**: 28 passed, 0 failed (test_updater.py)
**Test Result**: 28 passed, 0 failed (test_updater.py); full suite passes (Run-Tests.ps1 -All)

**Documentation & State Updates**:
- [x] Feature implementation state file (2.2.1) updated, or N/A — _Grepped state file: references `_update_file_references_multi` in history entry only (factual record). Both methods still exist with same signatures. No update needed._
- [x] TDD (2.2.1) updated, or N/A — _Grepped TDD PD-TDD-026: references `_update_file_references()` as internal method. Method still exists, delegates to `_apply_replacements`. Public API unchanged. No update needed._
- [x] Test spec (2.2.1) updated, or N/A — _Grepped test specs: no references to changed methods. No update needed._
- [x] FDD (2.2.1) updated, or N/A — _Grepped FDD PD-FDD-027: no references to changed methods. No update needed._
- [x] ADR updated, or N/A — _Grepped ADR directory: no references to changed methods. No update needed._
- [x] Validation tracking updated, or N/A — _2.2.1 is COMPLETE in validation-tracking-3.md. Internal refactoring does not affect validation results. No update needed._
- [x] Technical Debt Tracking: TD130 marked resolved via Update-TechDebt.ps1
- [x] Technical Debt Tracking: TD162 marked resolved via Update-TechDebt.ps1

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD130+TD162 | Complete | None | None required |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
