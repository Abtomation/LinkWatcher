---
id: PD-REF-097
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-27
updated: 2026-03-27
target_area: README.md
refactoring_scope: Add --validate mention to README.md
priority: Medium
mode: lightweight
---

# Lightweight Refactoring Plan: Add --validate mention to README.md

- **Target Area**: README.md
- **Priority**: Medium
- **Created**: 2026-03-27
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD093 — Add --validate CLI flag to README Quick Start

**Scope**: README.md lists link validation in Features and Documentation table but never shows the `--validate` CLI flag in any code example. Add `python main.py --validate` to the Quick Start block for discoverability. Source: PD-VAL-062.

**Changes Made**:
- [x] Add `python main.py --validate` as step 5 in Quick Start code block (README.md)

**Test Baseline**: N/A — documentation-only change. Smoke: test_config.py 48 passed.
**Test Result**: N/A — documentation-only. Smoke: test_config.py 48 passed.

**Documentation & State Updates**:
- [x] Feature implementation state file (6.1.1) updated, or N/A — _6.1.1 state file tracks validator implementation, not README content. No update needed._
- [x] TDD (6.1.1) updated, or N/A — _No TDD for 6.1.1 (link validation). Documentation-only change._
- [x] Test spec (6.1.1) updated, or N/A — _No behavior change, only README text._
- [x] FDD (6.1.1) updated, or N/A — _No FDD for 6.1.1._
- [x] ADR updated, or N/A — _No ADR for link validation._
- [x] Validation tracking updated, or N/A — _TD093 originated from PD-VAL-062 doc alignment. Will be addressed when marked resolved._
- [x] Technical Debt Tracking: TD093 marked resolved via Update-TechDebt.ps1

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD093 | Complete | None | None |

## Related Documentation
- [Technical Debt Tracking](/doc/product-docs/state-tracking/permanent/technical-debt-tracking.md)
