---
id: PD-REF-146
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-02
updated: 2026-04-02
refactoring_scope: Add 5 missing public methods to TDD PD-TDD-021
target_area: Core Architecture TDD
priority: Medium
mode: lightweight
---

# Lightweight Refactoring Plan: Add 5 missing public methods to TDD PD-TDD-021

- **Target Area**: Core Architecture TDD
- **Priority**: Medium
- **Created**: 2026-04-02
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD147 — Add 5 missing public methods to TDD PD-TDD-021 Section 4.1

**Scope**: TDD PD-TDD-021 Section 4.1 (LinkWatcherService Class) only documents `__init__()`, `start()`, `stop()`, `_signal_handler()`, and `_initial_scan()`. Five public methods are missing: `get_status()`, `force_rescan()`, `set_dry_run()`, `add_parser()`, `check_links()`. These methods existed when the TDD was written (PF-TSK-066) but were omitted from the retrospective documentation. Dimension: DA (Documentation Alignment).

**Changes Made**:
<!-- Fill in after implementation -->
- [x] Add `get_status()`, `force_rescan()`, `set_dry_run()`, `add_parser()`, `check_links()` to Section 4.1 code block
- [x] Update Section 3.1 component diagram to show the 5 public API methods

**Test Baseline**: 652 passed, 5 skipped, 4 deselected, 6 xfailed
**Test Result**: 652 passed, 5 skipped, 4 deselected, 6 xfailed (no change — doc-only)

**Documentation & State Updates**:
- [x] Feature implementation state file (0.1.1) — N/A: grepped feature state files for method names, no hits
- [x] TDD (0.1.1) updated — this IS the TDD update (Section 4.1 + Section 3.1 diagram)
- [x] Test spec (0.1.1) — N/A: test spec already references these methods (lines 89-115), no behavior change requires spec update
- [x] FDD (0.1.1) — N/A: FDD covers functional requirements, not method-level API surface
- [x] ADR (0.1.1) — N/A: grepped ADR directory, no references to these methods
- [x] Validation tracking — auto-updated via Update-TechDebt.ps1 -ValidationNote
- [x] Technical Debt Tracking: TD147 marked resolved via Update-TechDebt.ps1

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD147 | Complete | None | TDD PD-TDD-021 Section 4.1 + Section 3.1 diagram |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)

