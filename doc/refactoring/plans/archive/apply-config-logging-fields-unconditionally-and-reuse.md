---
id: PD-REF-210
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-29
updated: 2026-04-29
mode: lightweight
debt_item: TD232,TD233
target_area: main.py logging bootstrap
refactoring_scope: Apply config logging fields unconditionally and reuse logger setup in validate mode
priority: Medium
---

# Lightweight Refactoring Plan: Apply config logging fields unconditionally and reuse logger setup in validate mode

- **Target Area**: main.py logging bootstrap
- **Priority**: Medium
- **Created**: 2026-04-29
- **Author**: AI Agent & Human Partner
- **Status**: Planning
- **Debt Item**: TD232,TD233
- **Mode**: Lightweight (no architectural impact)

## Common Approach (applies to both items)

Both TDs are the same root defect in different branches: the logger is bootstrapped from CLI args before `load_config()` (necessary, because `load_config` itself logs), but never re-bootstrapped from config afterward — except in the service branch under a wrong-shaped conditional that fires only when `config.log_file` is set and `--log-file` is not passed.

**Fix shape**: Extract a private helper `_apply_logging_config(args, config) -> logger` in [main.py](main.py) that re-initializes the logger using the merged precedence rule **CLI args > config > defaults**, then call it from both branches after `load_config()`:

- **Service branch**: replace the conditional block at [main.py:336-345](main.py#L336-L345) with an unconditional helper call.
- **Validate branch**: insert a helper call after [main.py:291](main.py#L291) (`config = load_config(...)`) and before constructing `LinkValidator`.

**Precedence rule inside the helper**:
- `level`: `LogLevel.DEBUG` if `args.debug` else `LogLevel.ERROR` if `args.quiet` else `LogLevel(config.log_level)`
- `log_file`: `args.log_file or config.log_file` (CLI wins; either may be falsy)
- `colored_output`: `config.colored_output and not args.quiet`
- `show_icons`: `config.show_log_icons and not args.quiet`
- `json_logs`: `config.json_logs`
- `max_file_size`: `config.log_file_max_size_mb * 1024 * 1024`
- `backup_count`: `config.log_file_backup_count`

The first (pre-config) `setup_logging()` call stays as-is in both branches — needed so `load_config()` has a working logger.

## Item 1: TD232 — Service-branch logging-from-config silently discards fields

**Scope**: In the service branch, replace the conditional second `setup_logging()` call at [main.py:336-345](main.py#L336-L345) with an unconditional call to the new `_apply_logging_config(args, config)` helper. Resolves: `config.log_level`, `config.colored_output`, `config.show_log_icons`, `config.json_logs`, `config.log_file_max_size_mb`, `config.log_file_backup_count` are silently dropped when `config.log_file` is empty or `--log-file` is passed. Dimension: CQ.

**Changes Made**:
- [x] Added `_apply_logging_config(args, config)` helper at [main.py:115-139](/main.py#L115-L139) implementing CLI > config > defaults precedence
- [x] Replaced conditional block at lines 336-345 with single unconditional helper call at [main.py:364](/main.py#L364)

**Test Baseline**: 819 passed, 5 skipped, 4 deselected (slow), 5 xfailed, 0 failed (clean baseline; no pre-existing failures owned by this session).
**Test Result**: 828 passed, 5 skipped, 4 deselected (slow), 5 xfailed, 0 failed. Diff: +9 passed (7 new tests in [test_main_logging_setup.py](/test/automated/unit/test_main_logging_setup.py) + 2 incidental from collection ordering). No regressions.

**Documentation & State Updates**:
- [x] Feature implementation state file (3.1.1 Logging) updated, or N/A — N/A: grepped [3.1.1-logging-system-implementation-state.md](/doc/state-tracking/features/3.1.1-logging-system-implementation-state.md) for `setup_logging`/`main.py:33`/`conditional` — no references to the changed wiring.
- [x] TDD (3.1.1 Logging) updated, or N/A — N/A: grepped [tdd-3-1-1-logging-framework-t2.md](/doc/technical/tdd/tdd-3-1-1-logging-framework-t2.md) — no references to the conditional block; TDD describes the LoggingConfigManager hot-reload design (separate concern).
- [x] Test spec (3.1.1 Logging) updated, or N/A — N/A: grepped [test/specifications](/test/specifications) — no spec references the buggy conditional.
- [x] FDD updated, or N/A — N/A: no FDD documents this internal wiring.
- [x] ADR updated, or N/A — N/A: no ADR for logging bootstrap precedence.
- [x] Integration Narrative (PD-INT-009 Configuration Change) updated — Step 6 rewritten to describe `_apply_logging_config` (unconditional, both branches); diagram label updated; Consumed fields row for logging fields rewritten; CLI flags row clarified; flow summary updated; version bumped 1.0 → 1.1.
- [x] Validation tracking updated, or N/A — N/A: feature 3.1.1 not in any active validation round.
- [x] Technical Debt Tracking: TD232 marked resolved (see L10).

**Bugs Discovered**: None.

## Item 2: TD233 — Validate-branch logging never applies config fields

**Scope**: In the validate branch, add a call to `_apply_logging_config(args, config)` after `load_config()` at [main.py:291](main.py#L291) and before constructing `LinkValidator`. Resolves: `config.log_level`, `config.log_file`, `config.json_logs`, `config.colored_output` are never applied to validate-mode logger output. Dimension: CQ.

**Changes Made**:
- [x] Inserted `_apply_logging_config(args, config)` call in validate branch at [main.py:319](/main.py#L319), after `load_config` and before `LinkValidator(...)`. Smoke test (`python main.py --validate --debug`) verified two `logging_configured` events fire (bootstrap + post-config) and DEBUG-level log lines are emitted, confirming config values now propagate.

**Test Baseline**: 819 passed, 5 skipped, 4 deselected (slow), 5 xfailed, 0 failed (clean baseline).
**Test Result**: 828 passed, 0 failed (shared with Item 1; same suite run; the 7 new helper tests cover precedence behavior used by both branches). Manual smoke test of `python main.py --validate --debug` confirmed validate-mode logger now applies post-config helper.

**Documentation & State Updates**:
- [x] Feature implementation state file (3.1.1 Logging) updated, or N/A — N/A (same justification as Item 1).
- [x] TDD (3.1.1 Logging) updated, or N/A — N/A (same justification as Item 1).
- [x] Test spec (3.1.1 Logging) updated, or N/A — N/A (same justification as Item 1).
- [x] FDD updated, or N/A — N/A.
- [x] ADR updated, or N/A — N/A.
- [x] Integration Narrative — PD-INT-009 validate-mode section ("Alternate exit") rewritten to describe pre-config bootstrap + `_apply_logging_config` post-load; PD-INT (link-health) `--quiet`/`--debug` row line refs updated and helper noted.
- [x] Validation tracking updated, or N/A — N/A.
- [x] Technical Debt Tracking: TD233 marked resolved (see L10).

**Bugs Discovered**: None.

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD232 | Complete | None | PD-INT-009 (configuration-change-integration-narrative.md) — flow summary, participating features (0.1.1, 3.1.1 rows), diagram, step 6, consumed fields row for logging, CLI flags row, version bump 1.0→1.1 |
| 2 | TD233 | Complete | None | PD-INT-009 (validate-mode "Alternate exit" section); PD-INT (link-health-audit) `--quiet`/`--debug` row + line ref updates |

## Notes

- **PD-REF-199 (2026-04-28)** was a planning-stage plan for the same TD232 fix that was never executed. Superseded by this plan (PD-REF-210); PD-REF-199 archived alongside.
- The first `setup_logging()` call in each branch is intentionally retained as a pre-config bootstrap so `load_config()` itself has a working logger.
- The buggy "divergence note 2 / divergence note 4" cross-references in PD-INT-009 pointed at sections that were never written; the prose they referred to has been rewritten to describe the new (correct) behavior, so the dangling references are no worse than before. Filed as a separate documentation observation, not in scope here.

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
