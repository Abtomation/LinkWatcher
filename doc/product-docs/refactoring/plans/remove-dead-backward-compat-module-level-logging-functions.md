---
id: PD-REF-108
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-27
updated: 2026-03-27
refactoring_scope: Remove dead backward-compat module-level logging functions
target_area: Logging System
mode: lightweight
priority: Medium
---

# Lightweight Refactoring Plan: Remove dead backward-compat module-level logging functions

- **Target Area**: Logging System
- **Priority**: Medium
- **Created**: 2026-03-27
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD106 — Remove dead backward-compat module-level logging functions

**Scope**: Remove 7 unused module-level functions (`log_file_moved`, `log_file_deleted`, `log_links_updated`, `log_error`, `log_warning`, `log_info`, `log_debug`) from `linkwatcher/logging.py:601-635`. These are labeled "backward compatibility" but have zero callers anywhere in the codebase (confirmed by grep). Also remove the docstring reference at line 67-68. Reduces namespace clutter and eliminates misleading framing.

**Changes Made**:
- [x] Remove 7 backward-compat functions (lines 601-635) and their "backward compatibility" comment
- [x] Update docstring reference at lines 67-68 to describe actual module-level helpers

**Test Baseline**: 596 passed, 5 skipped, 7 xfailed
**Test Result**: 596 passed, 5 skipped, 7 xfailed (identical)

**Documentation & State Updates**:
- [x] Feature implementation state file (3.1.1) updated, or N/A — _Grepped state file for backward-compat/log_file_moved — no references found_
- [x] TDD (3.1.1) updated, or N/A — _Grepped TDD for backward-compat/log_file_moved — no references found_
- [x] Test spec (3.1.1) updated, or N/A — _Grepped test spec for backward-compat/log_file_moved — no references found_
- [x] FDD (3.1.1) updated, or N/A — _Grepped FDD for backward-compat/log_file_moved — no references found_
- [x] ADR updated, or N/A — _Grepped ADR directory for backward-compat/log_file_moved — no references found_
- [x] Validation tracking updated, or N/A — _validation-tracking-2.md mentions backward-compat in issue descriptions (R2-L-008, R2-L-014) but these are read-only historical records of findings; will be resolved via Update-TechDebt.ps1 -ValidationNote_
- [x] Technical Debt Tracking: TD item marked resolved

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD106 | Complete | None | None (all N/A verified) |

## Related Documentation
- [Technical Debt Tracking](/doc/product-docs/state-tracking/permanent/technical-debt-tracking.md)
