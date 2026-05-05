---
id: PD-REF-209
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-29
updated: 2026-04-29
refactoring_scope: Wire performance_logging config flag to gate LogTimer/PerformanceLogger
mode: lightweight
target_area: linkwatcher.config + linkwatcher.parser + linkwatcher.service + linkwatcher.logging
debt_item: TD231
priority: Medium
---

# Lightweight Refactoring Plan: Wire performance_logging config flag to gate LogTimer/PerformanceLogger

- **Target Area**: linkwatcher.config + linkwatcher.parser + linkwatcher.service + linkwatcher.logging
- **Priority**: Medium
- **Created**: 2026-04-29
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Debt Item**: TD231
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD231 — Wire `performance_logging` config flag to gate timing log output

**Scope**: The `performance_logging` field at [settings.py:127](src/linkwatcher/config/settings.py#L127) is declared `bool = False` but no production code branches on it; `LogTimer` invocations at [parser.py:80](src/linkwatcher/parser.py#L80), [parser.py:119](src/linkwatcher/parser.py#L119), and [service.py:133](src/linkwatcher/service.py#L133) run unconditionally, and `PerformanceLogger.end_timer` always emits INFO `operation_completed` entries. Wire the flag through to gate the 3 `LogTimer` call sites so users can disable per-file timing overhead in production as the example configs already imply.

**Approach**: Add `enabled: bool = True` keyword argument to `LogTimer.__init__`. When `enabled=False`, `__enter__`/`__exit__` short-circuit (no `start_timer`/`end_timer`, no debug logs). Default `True` preserves behavior for existing callers and tests. At the 3 call sites pass `enabled=<config>.performance_logging`. `PerformanceLogger` instantiation in `LinkWatcherLogger.__init__` is left untouched — instantiation alone produces no output, and gating its lifecycle would invasively change the bound-logger contract.

**Changes Made**:
- [x] `src/linkwatcher/logging.py` — Added `enabled: bool = True` kwarg to `LogTimer.__init__`; both `__enter__` and `__exit__` now short-circuit when `enabled=False`.
- [x] `src/linkwatcher/parser.py` — `LinkParser.__init__` stores `self.performance_logging` from config (with `DEFAULT_CONFIG` fallback); both `LogTimer` sites (`file_parsing`, `content_parsing`) now pass `enabled=self.performance_logging`.
- [x] `src/linkwatcher/service.py` — `initial_scan` `LogTimer` site now passes `enabled=(self.config or DEFAULT_CONFIG).performance_logging`, matching the existing `self.config or DEFAULT_CONFIG` pattern used elsewhere in the file (lines 190, 238).
- [x] `test/automated/unit/test_logging.py` — Added `test_disabled_skips_logging` (success path) and `test_disabled_swallows_exception_path` (exception path) to `TestLogTimer`. Both verify that `enabled=False` skips `start_timer`/`end_timer` calls and emits no debug/error logs while still letting exceptions propagate naturally.
- [x] `doc/user/handbooks/logging-and-monitoring.md` — Fixed default `true` → `false` to match `settings.py:127`; clarified that disabling avoids per-file log overhead.
- [x] `doc/technical/integration/configuration-change-integration-narrative.md` — Added `performance_logging` row to the Consumed fields table; replaced the (now-empty) Orphan fields table with a status note plus a "Resolved" entry referencing PD-REF-209 / TD231.

**Test Baseline**: 819 passed, 5 skipped, 4 deselected, 5 xfailed, 0 failed (captured 2026-04-29)
**Test Result**: 821 passed, 5 skipped, 4 deselected, 5 xfailed, 0 failed (delta: +2 passed = the 2 new gating tests; no regressions)

**Documentation & State Updates**:
- [x] Feature implementation state file (3.1.1) — N/A: state file describes `LogTimer` only at the level of "context manager for performance measurement" (line 44); the new `enabled` kwarg is an internal API detail that doesn't change that high-level characterization.
- [x] TDD (3.1.1) — Updated: `LogTimer` pseudocode at section "PerformanceLogger + LogTimer" now reflects the `enabled` parameter and the short-circuit branches in `__enter__`/`__exit__`, with a docstring note explaining how it ties to `config.performance_logging`.
- [x] Test spec (3.1.1) — Updated: added two rows to the `LogTimer` table (`test_disabled_skips_logging`, `test_disabled_swallows_exception_path`) and updated the Priority Order checklist line to include the disabled path.
- [x] FDD (3.1.1) — Updated: `3.1.1-FR-6` now states timing is reported "when `performance_logging` is enabled" and that it short-circuits when disabled (default); the User Interactions "Performance Timing" section now notes opt-in behavior.
- [x] ADR — N/A: grepped `doc/technical/architecture/decisions/` for `LogTimer`/`performance_logging` — no matches; this is a localized config-wiring fix, no architectural decision involved.
- [x] Integration Narrative (PD-INT-009) — Updated: added `performance_logging` to the Consumed fields table and recorded its resolution in the Orphan fields section. (No other PD-INT-* narratives reference `LogTimer` or `performance_logging` per Grep — the link-health-audit narrative match was a generic "performance" hit, not a `LogTimer` reference.)
- [x] Feature implementation state file (2.1.1 link-parsing) — N/A: state file describes `LinkParser` at facade level (`Facade + Registry pattern`, line 45); the new `self.performance_logging` attribute is an internal implementation detail that doesn't change the facade contract.
- [x] Validation tracking — N/A: 3.1.1 and 2.1.1 are listed in [validation-tracking-4](/doc/state-tracking/validation/validation-tracking-4.md) but the recorded validation scores were captured at points-in-time before this change; nothing in the validation tracking row is invalidated by adding a config gate to existing log emissions.
- [x] Test tracking — Updated: count for `test_logging.py` row in [test-tracking.md](/test/state-tracking/permanent/test-tracking.md) raised from 25 to 27 (preserves the pre-existing -1 drift that was present before this session). Pre-existing drift between marker count and actual collection across the repo is recorded as an observation in the feedback form.
- [x] Technical Debt Tracking: TD231 to be marked Resolved via `Update-TechDebt.ps1` in L10.

**Bugs Discovered**: None.

<!-- BATCH MODE: Copy the "## Item N" section above for each additional debt item in this session -->

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD231 | Complete | None | TDD 3.1.1 (LogTimer pseudocode), FDD 3.1.1 (FR-6 + Performance Timing UI section), test spec 3.1.1 (2 new test rows + checklist line), PD-INT-009 (move from Orphan to Consumed fields table), logging-and-monitoring handbook (default `true` → `false`), test-tracking.md (test_logging.py count 25→27) |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
