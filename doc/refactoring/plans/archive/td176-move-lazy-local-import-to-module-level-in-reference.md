---
id: PD-REF-163
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-09
updated: 2026-04-09
target_area: ReferenceLookup
refactoring_scope: TD176: Move lazy local import to module-level in reference_lookup.py
priority: Medium
mode: lightweight
---

# Lightweight Refactoring Plan: TD176: Move lazy local import to module-level in reference_lookup.py

- **Target Area**: ReferenceLookup
- **Priority**: Medium
- **Created**: 2026-04-09
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD176 — Move lazy local import to module-level in reference_lookup.py

**Scope**: `ReferenceLookup._get_relative_path()` (line 757) uses `from .utils import get_relative_path` as a lazy local import. No circular dependency exists (`utils.py` does not import `reference_lookup`). Move to module-level import. Dimension: ID (Import Discipline).

**Changes Made**:
- [x] Added `from .utils import get_relative_path` to module-level imports (line 22)
- [x] Removed local import from `_get_relative_path()` method (was line 770)

**Test Baseline**: 755 passed, 5 skipped, 4 xfailed, 0 failed (56s)
**Test Result**: 755 passed, 5 skipped, 4 xfailed, 0 failed (55s) — identical to baseline

**Documentation & State Updates**:
- [x] Feature implementation state file (1.1.1) updated, or N/A — _Grepped state file for `_get_relative_path` and `get_relative_path` — no references found_
- [x] TDD (1.1.1) updated, or N/A — _No interface change; import location is not documented in TDD. Grepped TDD directory — no references._
- [x] Test spec (1.1.1) updated, or N/A — _No behavior change. Test spec 2.2.1 mentions `get_relative_path` only in test inventory — no spec update needed._
- [x] FDD (1.1.1) updated, or N/A — _No functional change affects FDD._
- [x] ADR updated, or N/A — _No architectural decision affected._
- [x] Validation tracking updated, or N/A — _Import-only change doesn't affect validation._
- [x] Technical Debt Tracking: TD176 marked resolved via Update-TechDebt.ps1

**Bugs Discovered**: None

## Item 2: TD178 — Handler encapsulation for monitored_extensions mutation

**Scope**: `service.add_parser()` (line 262) directly mutates `handler.monitored_extensions` via `.add()` instead of using a handler API method. Add `add_monitored_extension()` method to `LinkMaintenanceHandler` and call it from `service.add_parser()`. Dimension: AC (Architectural Consistency — encapsulation).

**Changes Made**:
- [x] Added `add_monitored_extension(self, extension)` method to `LinkMaintenanceHandler` in handler.py (before `_should_monitor_file`)
- [x] Updated `service.add_parser()` to call `self.handler.add_monitored_extension(extension)` instead of direct attribute mutation

**Test Baseline**: 755 passed, 5 skipped, 4 xfailed, 0 failed (shared with Item 1)
**Test Result**: 755 passed, 5 skipped, 4 xfailed, 0 failed (64s) — identical to baseline

**Documentation & State Updates**:
- [x] Feature implementation state file (1.1.1, 1.1.4, 2.1.1) updated, or N/A — _State files for 1.1.4 and 2.1.1 are in archive/. References describe `add_parser()` behavior ("updates handler.monitored_extensions") — still accurate, just mechanism changed. No update needed._
- [x] TDD (0.1.1) updated, or N/A — _TDD documents `add_parser` as "adds the extension to handler's monitored set" — contract unchanged, only internal mechanism changed from direct mutation to API call._
- [x] Test spec updated, or N/A — _Test spec 2.1.1 mentions `add_parser()` only in feature-level context — no behavior change._
- [x] FDD updated, or N/A — _No functional change._
- [x] ADR updated, or N/A — _No architectural decision affected._
- [x] Validation tracking updated, or N/A — _Encapsulation improvement doesn't affect validation._
- [ ] Technical Debt Tracking: TD item marked resolved

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD176 | Complete | None | None |
| 2 | TD178 | Complete | None | None |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
