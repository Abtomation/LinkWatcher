---
id: PD-REF-078
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-27
updated: 2026-03-27
priority: Medium
target_area: src/linkwatcher/service.py
refactoring_scope: Remove handler private method coupling in service.py _initial_scan
mode: lightweight
---

# Lightweight Refactoring Plan: Remove handler private method coupling in service.py _initial_scan

- **Target Area**: src/linkwatcher/service.py
- **Priority**: Medium
- **Created**: 2026-03-27
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD067 — Remove handler private method coupling in _initial_scan

**Scope**: `service.py:_initial_scan()` accesses three handler internals: `self.handler.ignored_dirs`, `self.handler._should_monitor_file()`, and `self.handler._get_relative_path()`. All three have public equivalents available — `should_monitor_file()` and `get_relative_path()` in `src/linkwatcher/utils.py`, and `config.ignored_directories` on the service's own config. Replace handler private method calls with direct util imports and config access.

**Changes Made**:
- [x] Import `should_monitor_file` and `get_relative_path` from `linkwatcher.utils` in `service.py`
- [x] Import `DEFAULT_CONFIG` from `linkwatcher.config.defaults` for `config is None` fallback
- [x] Replace `self.handler.ignored_dirs` with config-derived `ignored_dirs` local variable
- [x] Replace `self.handler._should_monitor_file()` with direct `should_monitor_file()` call
- [x] Replace `self.handler._get_relative_path()` with direct `get_relative_path()` call

**Test Baseline**: 565 passed, 5 skipped, 7 xfailed
**Test Result**: 565 passed, 5 skipped, 7 xfailed (identical)

**Documentation & State Updates**:
- [x] Feature implementation state file (0.1.1) updated, or N/A — _Grepped state file — no references to `_initial_scan`, `_should_monitor_file`, `_get_relative_path`, or `ignored_dirs`_
- [x] TDD (0.1.1) updated, or N/A — _TDD mentions `_initial_scan` at high level ("Walk project directory, parse all monitored files, populate database") — description remains accurate, no coupling details documented_
- [x] Test spec (0.1.1) updated, or N/A — _Test spec references `_initial_scan` behavior ("database populated with links from files") — behavior unchanged, no spec update needed_
- [x] FDD (0.1.1) updated, or N/A — _Grepped FDD — no references to changed methods_
- [x] ADR updated, or N/A — _Grepped ADR directory — no references to changed methods_
- [x] Validation tracking updated, or N/A — _Grepped validation tracking — TD067 not tracked in any validation round_
- [x] Technical Debt Tracking: TD067 marked resolved

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD067 | Complete | None | None |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
