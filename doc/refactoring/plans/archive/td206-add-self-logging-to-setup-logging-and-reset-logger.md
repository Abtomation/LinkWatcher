---
id: PD-REF-187
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-09
updated: 2026-04-09
target_area: Logging Framework
mode: lightweight
priority: Medium
refactoring_scope: TD206: Add self-logging to setup_logging and reset_logger
---

# Lightweight Refactoring Plan: TD206: Add self-logging to setup_logging and reset_logger

- **Target Area**: Logging Framework
- **Priority**: Medium
- **Created**: 2026-04-09
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD206 — Add self-logging to setup_logging() and reset_logger()

**Scope**: `setup_logging()` and `reset_logger()` in `src/linkwatcher/logging.py` don't log their own invocations, making config changes and logger resets invisible in log output. Add INFO log on setup (after creating new logger) and DEBUG log on reset (before closing handlers). Dimension: OB (Observability).

**Changes Made**:
- [x] Add `_logger.debug("logger_reset", event_type="logging_lifecycle")` in `reset_logger()` before closing handlers (logging.py:553)
- [x] Add `_logger.info("logging_configured", event_type="logging_lifecycle", level=..., log_file=..., json_logs=...)` in `setup_logging()` after creating new logger (logging.py:586-591)

**Test Baseline**: 763 passed, 5 skipped, 4 deselected, 4 xfailed, 0 failures
**Test Result**: 763 passed, 5 skipped, 4 deselected, 4 xfailed, 0 failures — identical to baseline

**Documentation & State Updates**:
- [x] Feature implementation state file (3.1.1) — N/A: _Grepped state file — no references to setup_logging or reset_logger internals_
- [x] TDD (3.1.1) — N/A: _TDD references setup_logging/reset_logger as API descriptions; no interface change, only added log output_
- [x] Test spec (3.1.1) — N/A: _Test spec lists setup_logging test coverage; no behavior change affects spec_
- [x] FDD (3.1.1) — N/A: _FDD references setup_logging as business rule; no functional change_
- [x] ADR — N/A: _Grepped ADR directory — no references to setup_logging or reset_logger_
- [x] Validation tracking — N/A: _TD206 source is PD-VAL-095 (validation round 4, already complete); change doesn't affect open validation_
- [ ] Technical Debt Tracking: TD item marked resolved

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD206 | Complete | None | None |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
