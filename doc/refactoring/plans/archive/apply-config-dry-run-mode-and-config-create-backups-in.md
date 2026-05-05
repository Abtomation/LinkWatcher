---
id: PD-REF-203
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-29
updated: 2026-04-29
mode: lightweight
target_area: src/linkwatcher/service.py
debt_item: TD235
refactoring_scope: Apply config.dry_run_mode and config.create_backups in LinkWatcherService.__init__
priority: Medium
---

# Lightweight Refactoring Plan: Apply config.dry_run_mode and config.create_backups in LinkWatcherService.__init__

- **Target Area**: src/linkwatcher/service.py
- **Priority**: Medium
- **Created**: 2026-04-29
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Debt Item**: TD235
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD235 — Apply config.dry_run_mode and config.create_backups in LinkWatcherService.__init__

**Scope**: `LinkWatcherService.__init__` reads several config fields (parser_type_extensions, python_source_root, monitored_extensions, ignored_directories) but silently ignores `config.dry_run_mode` and `config.create_backups`. `main.py:377-378` compensates with post-init `service.set_dry_run()` and `service.updater.set_backup_enabled()` calls, but the 27 test files that instantiate `LinkWatcherService` directly do NOT — they run with hardcoded `LinkUpdater` defaults (`backup_enabled=True, dry_run=False`) regardless of the config they pass. `TESTING_CONFIG` (defaults.py:129-130) explicitly sets `dry_run_mode=True, create_backups=True` but those values are dropped on the test path.

Apply both fields inside `LinkWatcherService.__init__` so the service constructor alone honors the full config. Setters are kept for runtime mutation. Remove the now-redundant post-init calls in `main.py`.

**Dimension**: EM (Encapsulation/Modularity), CQ-relevant per TD235 notes. Refactoring restores constructor as single source of truth for config application — clients should not need to know which subset of config fields the constructor handles.

**Feature**: 0.1.1 Core Architecture (PD-FIS-046). Workflows: WF-003, WF-007, WF-008.

**Test Coverage Assessment**: Insufficient. `test_set_dry_run` (test_service.py:105) exercises only the runtime setter. No existing test constructs `LinkWatcherService` with a config carrying non-default `dry_run_mode`/`create_backups` and verifies updater state reflects them. Adding 2 targeted unit tests (`test_init_applies_config_dry_run_mode`, `test_init_applies_config_create_backups`) to lock the new behavior.

**Changes Made**:
- [x] Apply `config.dry_run_mode` and `config.create_backups` to `self.updater` in `LinkWatcherService.__init__` after updater construction (guarded by `if config is not None:`) — [service.py:96-98](src/linkwatcher/service.py#L96-L98)
- [x] Remove redundant post-init `service.set_dry_run()` and `service.updater.set_backup_enabled()` calls in main.py — [main.py:374](main.py#L374)
- [x] Add `test_init_applies_config_dry_run_mode` and `test_init_applies_config_create_backups` to [test/automated/unit/test_service.py](test/automated/unit/test_service.py)
- [x] Updated 5 Integration Narratives to reflect that the service constructor now applies the two flags (configuration-change, dry-run-mode, startup, graceful-shutdown, single-file-move). The configuration-change narrative's "Post-init setter ordering" error section and the dry-run-mode narrative's "set_dry_run() not called before start() (embedder scenario)" section are marked RESOLVED with TD235 / PD-REF-203 reference.

**Test Baseline**: 814 passed, 5 skipped, 5 deselected, 5 xfailed, 0 failed (run 2026-04-29, `pytest test/automated/ -m "not slow"`)
**Test Result**: 819 passed, 5 skipped, 4 deselected, 5 xfailed, 0 failed. Diff: +5 passed (2 new tests for TD235 + minor collection delta), 0 NEW failures. Targeted run of `test_service.py` confirms all 35 tests pass including the 2 new ones.

**Documentation & State Updates**:
- [x] Feature implementation state file (0.1.1) — N/A: grepped `0.1.1-core-architecture-implementation-state.md` for `set_dry_run|set_backup_enabled|dry_run_mode|create_backups` — no references.
- [x] TDD (0.1.1) — N/A: grepped `tdd-0-1-1-core-architecture-t3.md`. Only references are to `set_dry_run()` as a public service method (lines 144, 256-257), which is preserved per the resolution. No interface or internal design changes.
- [x] Test spec (0.1.1) — N/A: grepped `test-spec-0-1-1-core-architecture.md`. Only reference is to `test_set_dry_run` (line 112), still valid behavior. No behavior change affects spec.
- [x] FDD (0.1.1) — N/A: feature 0.1.1 has no FDD (Tier 3 has TDD only).
- [x] ADR (0.1.1) — N/A: grepped `orchestrator-facade-pattern-for-core-architecture.md` — no references to changed component. The constructor's role applying config to sub-components is consistent with the orchestrator-facade ADR's intent.
- [x] **Integration Narratives — UPDATED** (5 files):
  - [configuration-change-integration-narrative.md](doc/technical/integration/configuration-change-integration-narrative.md) — most extensive: exit point, flow summary, participating-features rows for 0.1.1 and 2.2.1, Mermaid diagram edges, Step 7/8 of Data Flow Sequence, Configuration Propagation table, "Post-init setter ordering" error section marked RESOLVED.
  - [dry-run-mode-integration-narrative.md](doc/technical/integration/dry-run-mode-integration-narrative.md) — Step 4/5 of Data Flow, Configuration Propagation table, "Critical note" replaced, "set_dry_run() not called before start() (embedder scenario)" marked RESOLVED.
  - [startup-integration-narrative.md](doc/technical/integration/startup-integration-narrative.md) — Configuration Propagation row.
  - [graceful-shutdown-integration-narrative.md](doc/technical/integration/graceful-shutdown-integration-narrative.md) — `create_backups` and `dry_run_mode` propagation rows.
  - [single-file-move-integration-narrative.md](doc/technical/integration/single-file-move-integration-narrative.md) — `dry_run_mode` propagation row.
- [x] Validation tracking — N/A: TD235 originates from PF-TSK-083 PD-INT-009 (Integration Narrative work), not from any validation round. Active validation rounds 3 and 4 do reference 0.1.1 but no validation report findings reference TD235.
- [ ] Technical Debt Tracking: TD235 marked resolved (handled in L10 via `Update-TechDebt.ps1`).

**Bugs Discovered**: None.

<!-- BATCH MODE: Copy the "## Item N" section above for each additional debt item in this session -->

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD235 | Complete | None | 5 Integration Narratives updated; TDD/test spec/ADR/state file confirmed N/A |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
