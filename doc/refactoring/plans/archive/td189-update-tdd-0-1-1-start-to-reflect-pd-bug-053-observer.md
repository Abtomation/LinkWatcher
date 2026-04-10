---
id: PD-REF-173
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-09
updated: 2026-04-09
refactoring_scope: TD189: Update TDD-0-1-1 start() to reflect PD-BUG-053 observer-first ordering
mode: lightweight
target_area: Core Architecture TDD
priority: Medium
---

# Lightweight Refactoring Plan: TD189: Update TDD-0-1-1 start() to reflect PD-BUG-053 observer-first ordering

- **Target Area**: Core Architecture TDD
- **Priority**: Medium
- **Created**: 2026-04-09
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD189 — Update TDD-0-1-1 start() to reflect PD-BUG-053 observer-first ordering

**Scope**: TDD Section 4.1 `start()` pseudo-code shows scan-before-observer ordering, but PD-BUG-053 reversed this to observer-first with event deferral. Update the TDD pseudo-code and docstring to match the actual implementation in service.py:98-148.

**Dims**: DA (Documentation Alignment)

**Changes Made**:
<!-- Fill in after implementation -->
- [x] Update `start()` docstring from "optional scan → start observer → poll" to observer-first ordering
- [x] Replace `start()` pseudo-code body to show: begin_event_deferral → Observer start → initial_scan → notify_scan_complete → poll loop

**Test Baseline**: Documentation-only change — test baseline skipped.
**Test Result**: Documentation-only change — regression testing skipped.

**Documentation & State Updates**:
- [x] Feature implementation state file (0.1.1) updated, or N/A — _Grepped state file for start()/begin_event_deferral/notify_scan_complete — only generic "service.start()" mention at line 298, no startup ordering details. N/A._
- [x] TDD (0.1.1) updated — _This IS the TDD update. Section 4.1 start() pseudo-code corrected._
- [x] Test spec (0.1.1) updated, or N/A — _Grepped test-spec-0-1-1 — references start()/stop() lifecycle generically, no startup ordering claims. N/A._
- [x] FDD (0.1.1) updated, or N/A — _Grepped FDD directory for start()/begin_event_deferral — no matches. N/A._
- [x] ADR updated, or N/A — _ADR orchestrator-facade-pattern line 50 also has old ordering ("start() triggers optional initial scan, creates and starts the Observer"). Separate from TD189 scope — noted as discovered issue below._
- [x] Validation tracking updated, or N/A — _Feature 0.1.1 tracked in validation-tracking-4.md but this doc-only fix doesn't affect validation results. N/A._
- [x] Technical Debt Tracking: TD189 marked resolved via Update-TechDebt.ps1

**Bugs Discovered**: None

**Additional Finding**: ADR `orchestrator-facade-pattern-for-core-architecture.md` line 50 also describes the old scan-before-observer ordering. Not in TD189 scope — should be a separate TD item or included in TD190 scope.

<!-- BATCH MODE: Copy the "## Item N" section above for each additional debt item in this session -->

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD189 | Complete | None | TDD-0-1-1 Section 4.1 start() pseudo-code updated |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
