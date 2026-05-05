---
id: PD-REF-202
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-29
updated: 2026-04-29
refactoring_scope: Honor show_statistics flag in _print_final_stats
feature_id: 0.1.1
debt_item: TD229
mode: lightweight
priority: Medium
target_area: src/linkwatcher/service.py
---

# Lightweight Refactoring Plan: Honor show_statistics flag in _print_final_stats

- **Target Area**: src/linkwatcher/service.py
- **Priority**: Medium
- **Created**: 2026-04-29
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Debt Item**: TD229
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD229 — Honor `show_statistics` flag in `_print_final_stats`

**Dims**: CQ (Code Quality)

**Scope**: The `show_statistics` config field is declared at [settings.py:121](/src/linkwatcher/config/settings.py#L121), set across 4 presets in [defaults.py](/src/linkwatcher/config/defaults.py#L90-L126), and overridden to `False` by `--quiet` at [main.py:84](/main.py#L84) — but `_print_final_stats()` at [service.py:230-244](/src/linkwatcher/service.py#L230-L244) is invoked unconditionally from `stop()` and never reads the flag. Field is inert and the user-facing config option (documented in [logging-and-monitoring.md](/doc/user/handbooks/logging-and-monitoring.md#L59)) does not work as documented. Add an early-return guard inside `_print_final_stats()` so the flag controls shutdown statistics output as documented.

**Changes Made**:
- [x] Added early-return guard in `_print_final_stats()` at [service.py:236-238](/src/linkwatcher/service.py#L236-L238): `config = self.config if self.config else DEFAULT_CONFIG; if not config.show_statistics: return`. Used the same `self.config or DEFAULT_CONFIG` fallback pattern already used in `_initial_scan()` to handle the `config=None` constructor case.
- [x] Added 2 unit tests in [test/automated/unit/test_service.py](/test/automated/unit/test_service.py) (`test_print_final_stats_skipped_when_show_statistics_false`, `test_print_final_stats_logs_when_show_statistics_true`) verifying that `logger.operation_stats` is/isn't called per the flag.
- [x] Updated PD-INT-009 ([configuration-change-integration-narrative.md](/doc/technical/integration/configuration-change-integration-narrative.md)) — moved `show_statistics` from "Orphan configuration fields" to "Consumed fields" table; updated resolved-fields note.
- [x] Updated PD-INT-008 ([graceful-shutdown-integration-narrative.md](/doc/technical/integration/graceful-shutdown-integration-narrative.md)) — `_print_final_stats()` description now mentions the `show_statistics` gating.

**Test Baseline**: 814 passed, 5 skipped, 5 deselected, 5 xfailed, 0 failed (captured 2026-04-29 before refactor)
**Test Result**: 819 passed, 5 skipped, 4 deselected, 5 xfailed, 0 failed. Diff vs baseline: +5 passed (2 new TD229 tests + 2 unrelated TD235 tests added by another session + 1 other delta). **No new failures owned by this session.**

**Documentation & State Updates**:
- [x] Feature implementation state file (0.1.1) updated, or N/A — _N/A: grepped [0.1.1-core-architecture-implementation-state.md](/doc/state-tracking/features/0.1.1-core-architecture-implementation-state.md) for `show_statistics` and `_print_final_stats` — no references found. State file describes the orchestration role of the service at a high level and does not mention this flag._
- [x] TDD (0.1.1) updated, or N/A — _N/A: TDD-0-1-1 references `_print_final_stats()` in the architecture diagram and pseudocode for `stop()`, but only at call-site level; the early-return guard is internal logic gating the existing log call (no interface change, no algorithm/data-structure change). The TDD shows `self._print_final_stats()` as still being invoked from `stop()`, which remains true._
- [x] Test spec (0.1.1) updated, or N/A — _N/A: grepped [test/specifications/](/test/specifications/) — no references to `show_statistics` or `_print_final_stats`._
- [x] FDD (0.1.1) updated, or N/A — _N/A: no FDD exists for feature 0.1.1._
- [x] ADR (0.1.1) updated, or N/A — _N/A: only [orchestrator-facade-pattern-for-core-architecture.md](/doc/technical/adr/orchestrator-facade-pattern-for-core-architecture.md) mentions "prints statistics" at a high architectural level. The fact that `stop()` prints statistics is unchanged (default behavior); only the new option to suppress them via config is added — no architectural decision affected._
- [x] Integration Narrative updated, or N/A — _Updated PD-INT-009 (configuration-change) and PD-INT-008 (graceful-shutdown) — see Changes Made above._
- [x] Validation tracking updated, or N/A — _N/A: no active validation tracking files in [doc/state-tracking/permanent/](/doc/state-tracking/permanent/). Historical validation reports (PD-VAL-076, PD-VAL-095, PD-VAL-042) reference `_print_final_stats()` but are read-only historical records._
- [x] Technical Debt Tracking: TD item marked resolved (via `Update-TechDebt.ps1` — see L10)

**Bugs Discovered**: None.

<!-- BATCH MODE: Copy the "## Item N" section above for each additional debt item in this session -->

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD229 | Complete | None | PD-INT-009, PD-INT-008 |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
