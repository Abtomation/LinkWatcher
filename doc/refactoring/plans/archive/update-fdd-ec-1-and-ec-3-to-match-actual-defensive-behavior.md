---
id: PD-REF-103
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-27
updated: 2026-03-27
refactoring_scope: Update FDD EC-1 and EC-3 to match actual defensive behavior
target_area: Logging System
priority: Medium
mode: lightweight
---

# Lightweight Refactoring Plan: Update FDD EC-1 and EC-3 to match actual defensive behavior

- **Target Area**: Logging System
- **Priority**: Medium
- **Created**: 2026-03-27
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD092 — Update FDD EC-1 and EC-3 to match actual code behavior

**Scope**: FDD PD-FDD-025 (fdd-3-1-1-logging-framework.md) has two edge case descriptions that don't match code. EC-1 says missing log dir causes console-only fallback, but `logging.py:381` creates the directory via `mkdir(parents=True)`. EC-3 says invalid config logs WARNING, but `logging_config.py:69` logs ERROR. Update both EC descriptions to match actual behavior.

**Changes Made**:
- [x] Update EC-1 in FDD: "falls back to console-only logging and emits a WARNING about the missing directory" → "creates the directory automatically (including parent directories) and proceeds with file logging"
- [x] Update EC-3 in FDD: "logs a WARNING" → "logs an ERROR"
- [x] Update TDD tdd-3-1-1 line 311: "logged as WARNING" → "logged as ERROR" (same EC-3 mismatch propagated to TDD)
- [x] Update test spec test-spec-3-1-1 line 158: "malformed config → WARNING" → "malformed config → ERROR"

**Test Baseline**: N/A — documentation-only change, no code modified
**Test Result**: N/A — no code changes

**Documentation & State Updates**:
- [x] Feature implementation state file (3.1.1) updated, or N/A — _Grepped state file: EC-1/EC-3 not referenced. No update needed._
- [x] TDD (3.1.1) updated — _Fixed "WARNING" → "ERROR" on line 311 (same EC-3 mismatch)_
- [x] Test spec (3.1.1) updated — _Fixed "WARNING" → "ERROR" on line 158 (same EC-3 mismatch)_
- [x] FDD (3.1.1) updated — _Primary fix: EC-1 and EC-3 corrected_
- [x] ADR updated, or N/A — _No ADR for logging system error handling_
- [x] Validation tracking updated, or N/A — _TD092 not referenced in validation tracking files. Source PD-VAL-062 is descriptive only._
- [x] Technical Debt Tracking: TD092 marked resolved via Update-TechDebt.ps1

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD092 | Complete | None | FDD PD-FDD-025, TDD PD-TDD-024, Test Spec TE-TSP-041 |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
