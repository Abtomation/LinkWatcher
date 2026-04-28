---
id: PD-REF-099
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-27
updated: 2026-03-27
mode: lightweight
refactoring_scope: Replace print() calls with structured logger calls in service.py
priority: Medium
target_area: src/linkwatcher/service.py
---

# Lightweight Refactoring Plan: Replace print() calls with structured logger calls in service.py

- **Target Area**: src/linkwatcher/service.py
- **Priority**: Medium
- **Created**: 2026-03-27
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD099 — Replace print() with structured logger in service.py

**Scope**: All 20 `print()` calls in `src/linkwatcher/service.py` bypass the structured logging pipeline (structlog → ColoredFormatter console + JSONFormatter file). Replace with `self.logger.info()` / `self.logger.debug()` calls so that service lifecycle events, scan progress, and link check results appear in both console and file log streams. The ColoredFormatter already handles colored console output, so direct `Fore.*` usage becomes unnecessary.

**Changes Made**:
<!-- Fill in after implementation -->
- [x] Replace `print()` in `start()` with `self.logger.info()` for service lifecycle messages (service_starting, initial_scan_starting, initial_scan_complete, monitoring_started)
- [x] Replace `print()` in `_initial_scan()` with `self.logger.scan_progress()` for progress and `self.logger.info("scan_complete")` for summary
- [x] Replace `print()` in `stop()` with `self.logger.info()` (service_stopping, service_stopped)
- [x] Replace `print()` in `force_rescan()` with `self.logger.info()` (rescan_starting, rescan_complete)
- [x] Replace `print()` in `set_dry_run()` with `self.logger.info("dry_run_toggled", enabled=...)`
- [x] Replace `print()` in `check_links()` with `self.logger.info()`/`self.logger.warning()` (link_check_starting, broken_links_found, broken_link, all_links_valid)
- [x] Removed unused `from colorama import Fore` import

**Test Baseline**: 593 passed, 5 skipped, 7 xfailed
**Test Result**: 593 passed, 5 skipped, 7 xfailed — identical to baseline

**Documentation & State Updates**:
- [x] Feature implementation state file (0.1.1) updated, or N/A — verified no reference to changed component: _N/A — grepped state file, only reference is colorama dependency listing (unchanged)_
- [x] TDD (0.1.1) updated, or N/A — verified no interface/design changes documented: _N/A — TDD references `_print_final_stats()` which is unchanged; no interface changes_
- [x] Test spec (0.1.1) updated, or N/A — verified no behavior change affects spec: _N/A — test spec references `force_rescan()`/`check_links()` method signatures which are unchanged_
- [x] FDD (0.1.1) updated, or N/A — verified no functional change affects FDD: _N/A — no functional change_
- [x] ADR updated, or N/A — verified no architectural decision affected: _N/A — grepped ADR directory, no references to print/console output pattern_
- [x] Validation tracking updated, or N/A — verified feature is not tracked in a validation round or change doesn't affect validation: _N/A — this fixes an observability finding (PD-VAL-054), doesn't change validation results_
- [x] Technical Debt Tracking: TD099 marked resolved via Update-TechDebt.ps1

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD099 | Complete | None | None |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
