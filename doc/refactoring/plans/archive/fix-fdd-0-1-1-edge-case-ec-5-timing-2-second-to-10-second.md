---
id: PD-REF-157
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-02
updated: 2026-04-02
target_area: Core Architecture FDD
refactoring_scope: Fix FDD 0.1.1 edge case EC-5 timing: 2-second to 10-second
mode: lightweight
priority: Medium
---

# Lightweight Refactoring Plan: Fix FDD 0.1.1 edge case EC-5 timing: 2-second to 10-second

- **Target Area**: Core Architecture FDD
- **Priority**: Medium
- **Created**: 2026-04-02
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD157 — FDD 0.1.1-EC-5 timing mismatch (2s → 10s)

**Scope**: Edge case 0.1.1-EC-5 in FDD PD-FDD-022 states "2-second pending-delete timer" but the actual `move_detect_delay` default has been 10.0 seconds since commit `2ac9a60` (bug fix that increased the delay for Windows directory move detection reliability). The FDD was accurate when originally written (commit `6638795`, when handler used `2.0`), but the subsequent code change did not update the FDD. Fix: update the FDD edge case text to say "10-second" and reference the configurable `move_detect_delay` setting.

**Dims**: DA (Documentation Alignment)

**Changes Made**:
- [x] Update 0.1.1-EC-5 in fdd-0-1-1-core-architecture.md: "2-second" → "10-second (configurable via `move_detect_delay`)"

**Test Baseline**: N/A — documentation-only change, no code modified
**Test Result**: N/A

**Documentation & State Updates**:
- [x] Feature implementation state file (0.1.1) updated, or N/A — _documentation-only FDD text fix, no code component changed_
- [x] TDD (0.1.1) updated, or N/A — _Grepped TDD for "EC-5" and "2-second" — no references to this edge case timing_
- [x] Test spec (0.1.1) updated, or N/A — _no behavior change, documentation-only fix_
- [x] FDD (0.1.1) updated — this IS the FDD fix
- [x] ADR (0.1.1) updated, or N/A — _Grepped ADR directory for "2-second" and "EC-5" — no references_
- [x] Validation tracking updated, or N/A — _source validation PD-VAL-072 already completed; this resolves the finding_
- [x] Technical Debt Tracking: TD157 marked resolved via Update-TechDebt.ps1

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD157 | Complete | None | FDD 0.1.1 EC-5 |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)

