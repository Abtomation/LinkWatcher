---
id: PD-REF-154
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-02
updated: 2026-04-02
priority: Medium
refactoring_scope: Add missing edge cases from PD-BUG-053 and PD-BUG-071 to FDD PD-FDD-024
mode: lightweight
target_area: File System Monitoring FDD
---

# Lightweight Refactoring Plan: Add missing edge cases from PD-BUG-053 and PD-BUG-071 to FDD PD-FDD-024

- **Target Area**: File System Monitoring FDD
- **Priority**: Medium
- **Created**: 2026-04-02
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD159 — Add missing edge cases from PD-BUG-053 and PD-BUG-071 to FDD

**Scope**: Add two edge case entries (1.1.1-EC-8 and 1.1.1-EC-9) to the Edge Cases & Error Handling section of FDD PD-FDD-024 (fdd-1-1-1-file-system-monitoring.md). PD-BUG-053 documents the observer-before-scan race condition edge case. PD-BUG-071 documents the extension-only filter for directory moves to ignored-dir names. Dimension: DA (Documentation Alignment).

**Debt Item ID**: TD159
**Dims**: DA

**Changes Made**:
- [x] Add 1.1.1-EC-8 (observer-before-scan timing) to Edge Cases section
- [x] Add 1.1.1-EC-9 (directory rename to ignored-dir name) to Edge Cases section
- [x] Update Validation Checklist count from EC-7 to EC-9

**Test Baseline**: 654 passed, 5 skipped, 6 xfailed
**Test Result**: 654 passed, 5 skipped, 6 xfailed — no regressions

**Documentation & State Updates**:
- [x] Feature implementation state file (1.1.1) updated, or N/A: _N/A — doc-only FDD change, no code component affected_
- [x] TDD (1.1.1) updated, or N/A: _N/A — no interface/design changes, edge cases are FDD-level_
- [x] Test spec (1.1.1) updated, or N/A: _N/A — no behavior change, bugs already fixed and tested_
- [x] FDD (1.1.1) updated: **Yes — this IS the FDD update**
- [x] ADR (1.1.1) updated, or N/A: _N/A — no architectural decision affected_
- [x] Validation tracking updated, or N/A: _N/A — doc-only change doesn't affect validation scores_
- [x] Technical Debt Tracking: TD159 marked resolved

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD159 | Complete | None | FDD PD-FDD-024 |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)

