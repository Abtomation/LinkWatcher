---
id: PD-REF-130
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-02
updated: 2026-04-02
refactoring_scope: Add missing batch update API docs to TDD PD-TDD-026
priority: Medium
target_area: Link Updater TDD
mode: lightweight
---

# Lightweight Refactoring Plan: Add missing batch update API docs to TDD PD-TDD-026

- **Target Area**: Link Updater TDD
- **Priority**: Medium
- **Created**: 2026-04-02
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD132 — Add batch update API docs to TDD PD-TDD-026

**Scope**: TDD PD-TDD-026 documents only `update_references()` as the public API and `_update_file_references()` as the internal per-file method. Two methods are missing: `update_references_batch()` (public, primary entry point for directory moves) and `_update_file_references_multi()` (internal, processes multiple old→new pairs per file in one read→modify→write cycle). Add both to the Public API and Internal Methods sections.

**Dims**: DA (Documentation Alignment)

**Changes Made**:
- [x] Added `update_references_batch(move_groups)` to Public API section with full signature and behavior description
- [x] Added `_update_file_references_multi(file_path, ref_tuples)` to Internal Methods section
- [x] Restructured Data Flow diagram into three sections: Single-Move Path, Batch Path (Directory Moves), and Shared Replacement Pipeline (`_apply_replacements`)
- [x] Updated Technical Overview paragraph to mention both entry points and shared pipeline

**Test Baseline**: N/A (documentation-only change)
**Test Result**: N/A

**Documentation & State Updates**:
- [x] Feature implementation state file (2.2.1) updated, or N/A — _Grepped state file for "batch" — no reference to batch API, N/A_
- [x] TDD (2.2.1) updated — this IS the TDD update
- [x] Test spec (2.2.1) updated, or N/A — _Documentation-only change, no behavior change affects spec, N/A_
- [x] FDD (2.2.1) updated, or N/A — _FDD describes functional requirements, not internal API — no change needed, N/A_
- [x] ADR updated, or N/A — _No architectural decision affected, N/A_
- [x] Validation tracking updated, or N/A — _Documentation alignment fix resolves the validation finding, no re-validation needed, N/A_
- [x] Technical Debt Tracking: TD132 marked resolved via Update-TechDebt.ps1

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD132 | Complete | None | TDD PD-TDD-026 (Public API, Internal Methods, Data Flow, Technical Overview) |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)

