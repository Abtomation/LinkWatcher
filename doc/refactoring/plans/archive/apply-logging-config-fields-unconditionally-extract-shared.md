---
id: PD-REF-199
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-28
updated: 2026-04-28
refactoring_scope: Apply logging config fields unconditionally; extract shared helper for service and validate branches
debt_item: TD232
mode: lightweight
priority: Medium
target_area: main.py logging setup
---

# Lightweight Refactoring Plan: Apply logging config fields unconditionally; extract shared helper for service and validate branches

- **Target Area**: main.py logging setup
- **Priority**: Medium
- **Created**: 2026-04-28
- **Author**: AI Agent & Human Partner
- **Status**: Superseded — plan was created but never executed
- **Debt Item**: TD232
- **Mode**: Lightweight (no architectural impact)

> **Superseded by [PD-REF-210](apply-config-logging-fields-unconditionally-and-reuse.md) (2026-04-29)** — TD232 + TD233 were resolved together under PD-REF-210 with substantively the same approach (extracting `_apply_logging_config(args, config)` helper called unconditionally from both service and validate branches). This plan is preserved for ID-registry consistency only.

## Item 1: TD232 — Apply logging config fields unconditionally in service-mode startup

**Scope**: In `main.py` service-mode startup, the second `setup_logging()` call is gated by `if config.log_file and not args.log_file:` ([main.py:336-345](/main.py#L336-L345)). When that condition is false (no `config.log_file` set, or `--log-file` passed), 4 display-related config fields (`log_level`, `colored_output`, `show_log_icons`, `json_logs`) are silently discarded. Decouple log-file gating from log-level/display gating so `config.log_*` fields apply unconditionally after `load_config`. The two file-logging-only fields (`log_file_max_size_mb`, `log_file_backup_count`) remain correctly gated on the presence of a log file. Dimension: CQ.

**Changes Made**:
<!-- Fill in after implementation -->
- [ ] Extract `_apply_logging_from_config(config, args)` helper (shared with Item 2)
- [ ] Replace the conditional second `setup_logging()` block at main.py:336-345 with a single helper call applied unconditionally after `load_config`

**Test Baseline**: 812 passed, 2 failed (pre-existing — `test_bm_001_parsing_throughput`, `test_ph_004_many_references_to_single_file`), 5 skipped, 5 xfailed
**Test Result**: _[fill after L7]_

**Documentation & State Updates**:
- [ ] Feature implementation state file (0.1.3 / 3.1.1) updated, or N/A — verified no reference to changed component
- [ ] TDD (0.1.3 / 3.1.1) updated, or N/A — verified no interface or significant internal design changes documented in TDD
- [ ] Test spec (0.1.3 / 3.1.1) updated, or N/A — verified no behavior change affects spec
- [ ] FDD (0.1.3 / 3.1.1) updated, or N/A — verified no functional change affects FDD
- [ ] ADR updated, or N/A — verified no architectural decision affected
- [ ] Integration Narrative updated, or N/A — verified no PD-INT references the helper
- [ ] Validation tracking updated, or N/A — verified feature is not tracked in current validation round or change doesn't affect validation
- [ ] Technical Debt Tracking: TD232 marked resolved

**Bugs Discovered**: _TBD_

## Item 2: TD233 — Apply logging config fields in --validate mode startup

**Scope**: In `main.py` `--validate` mode at [main.py:286-290](/main.py#L286-L290), `setup_logging()` is called with only CLI-derived args (`--debug`/`--quiet`); `config.log_level`, `config.log_file`, `config.json_logs`, `config.colored_output` are never applied to validate-mode output even though `load_config` runs immediately after at line 291. Refactor by reordering: load config first, then call the shared `_apply_logging_from_config(config, args)` helper introduced in Item 1, so both validate and service branches use the same logging-config-application logic. Dimension: CQ.

**Changes Made**:
<!-- Fill in after implementation -->
- [ ] Reorder: call `load_config` before logging setup in validate branch
- [ ] Replace the validate-branch `setup_logging()` call at main.py:286-290 with the shared helper

**Test Baseline**: 812 passed, 2 failed (pre-existing — `test_bm_001_parsing_throughput`, `test_ph_004_many_references_to_single_file`), 5 skipped, 5 xfailed
**Test Result**: _[fill after L7]_

**Documentation & State Updates**:
- [ ] Feature implementation state file (0.1.3 / 3.1.1) updated, or N/A
- [ ] TDD (0.1.3 / 3.1.1) updated, or N/A
- [ ] Test spec (0.1.3 / 3.1.1) updated, or N/A
- [ ] FDD (0.1.3 / 3.1.1) updated, or N/A
- [ ] ADR updated, or N/A
- [ ] Integration Narrative updated, or N/A
- [ ] Validation tracking updated, or N/A
- [ ] Technical Debt Tracking: TD233 marked resolved

**Bugs Discovered**: _TBD_

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD232 | _TBD_ | _TBD_ | _TBD_ |
| 2 | TD233 | _TBD_ | _TBD_ | _TBD_ |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
