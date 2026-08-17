---
id: PD-IMP-003
type: Document
category: General
version: 1.2
created: 2026-07-15
updated: 2026-08-13
description: "Implementation plan for 7.1.1-linkwatcher-control-panel"
feature_name: 7.1.1-linkwatcher-control-panel
status: Completed
---

# 7.1.1 LinkWatcher Control Panel - Implementation Plan

## Executive Summary

The LinkWatcher Control Panel is the project's **first GUI surface**: a single-window Tkinter/ttk desktop application that acts as a *pure supervisor* over the LinkWatcher daemons running across every registered project. It lists each project's daemon state, starts and stops daemons, tails logs, views/edits per-project configuration, triggers link validation, and drains-then-terminates all managed daemons when the window closes. It introduces **no new daemon-side contract** — it manages daemons entirely through existing external surfaces (the lock file, OS process state, the launcher script, the `--validate` CLI mode, log files, and the per-project YAML config).

This plan sequences the **execution** of the already-completed design (FDD, UI Design, TDD, Test Spec). It does not restate design; it defines what order to build in, what each phase touches, where the dependencies and risks are, and which decomposed implementation tasks own each phase.

**Key Metrics:**
- Estimated implementation duration: ~7 work sessions (phases A–G; each leaves the panel runnable/demonstrable)
- Team size required: 1 (AI agent + human partner, per project model)
- Complexity level: Medium (Tier 2 — multiple interacting components, threading, process management, new GUI toolkit)
- Risk level: Medium (dominant risk is process-termination correctness; contained by the three-way identity guard)

## Feature Overview

### Purpose and Goals

**Purpose**: Give an operator running LinkWatcher across several projects one desktop window to see and control every daemon, instead of inspecting OS process lists and opening log/config files by hand.

- **Primary user goal**: identify and control every running daemon across projects from one window — start, stop, monitor, validate — without the command line.
- **Business objective**: make LinkWatcher activity visible and controllable; the window auto-opens whenever the `SessionStart` hook starts a daemon, so the operator always has a visible handle.
- **Success criteria**: an operator can manage all daemons from the panel; panel-initiated shutdown produces zero corrupted files; start/stop/log/validate/config-edit all achievable without the CLI.

Full functional detail is owned by the FDD and is not restated here.

> **Design sources**: [FDD PD-FDD-034](../../functional-design/fdds/fdd-7-1-1-linkwatcher-control-panel.md) · [UI Design PD-UIX-003](../design/ui-ux/features/ui-design-7-1-1-linkwatcher-control-panel.md) · [TDD PD-TDD-033](../architecture/design-docs/tdd/tdd-7-1-1-linkwatcher-control-panel-t2.md) · [Test Spec TE-TSP-045](../../../test/specifications/feature-specs/test-spec-7-1-1-linkwatcher-control-panel.md) · [Tier Assessment PD-ASS-201](../../documentation-tiers/assessments/PD-ASS-201-7.1.1-linkwatcher-control-panel.md)

### Requirements Summary

- **Functional Requirements**: 9 FRs (FR-1…FR-9) — daemon list, start, stop, live state sync, live log view, validation trigger, drain-then-terminate on close, hook auto-open, config view/edit. Owned by the FDD; referenced by ID in the phase table below.
- **Non-Functional Requirements**: Reliability is the dominant attribute (bounded drain that can never hang; wrong-process termination impossible via three-way identity). UI thread never blocked (≤ 100 ms interactions); displayed state converges on real state ≤ 5 s; bounded log-tail memory; WCAG 2.1 AA targets within Tkinter's limits.
- **Constraints**: Windows-only process semantics (no graceful cross-process signal → observational drain); zero new package dependencies (Tkinter stdlib, `psutil` already present); start only via the existing launcher; config validation only via `LinkWatcherConfig.validate()`; the deployed daemons run from the global install, not repo source.

### Stakeholders and Roles

- **Product Owner / Tech Lead / QA**: human partner (single-collaborator project model).
- **Implementer**: AI agent, under the decomposed implementation tasks referenced below.

## Architecture and Design

### System Architecture

New subpackage `src/linkwatcher/linkwatcher_control_panel/`, plus a thin `control_panel.py` entry script beside `main.py` (mirrors the deployed flat install layout; the daemon CLI is untouched). The panel is a supervisor layered entirely over existing surfaces — it adds **no** data layer and **no** database.

- **New components**: `app.py` (Tk root, dispatcher, shutdown orchestration), `model.py` (observable `AppModel`), `discovery.py` (poll thread), `lifecycle.py` (start/drain/terminate), `log_tail.py`, `validation.py`, `config_edit.py`, `single_instance.py`, `settings.py`, `views/`.
- **Modified components**: `process-framework/tools/linkWatcher/start_linkwatcher_hook_wrapper.ps1` (auto-open call); `deployment/install_global.py` (ship the new entry script + subpackage).
- **Integration points**: launcher script, lock files + psutil, per-project log files, `main.py --validate`, `LinkWatcherConfig`, the central `project-registry.json`.

Component architecture and threading model are owned by [TDD §4.0](../architecture/design-docs/tdd/tdd-7-1-1-linkwatcher-control-panel-t2.md); this plan does not duplicate them.

### Data Layer Design

**N/A** — no database, no schema, no migrations. The only persisted state is the optional `panel-config.yaml` settings file and the transient `panel.port` single-instance file. In-memory state is a set of dataclasses rebuilt from external reality on every poll (see TDD §4.1).

### State Management Design

Single observable `AppModel` with one-way data flow (per UI Design §10.2): a **poller thread** and **per-action worker threads** do all blocking work and post results to a thread-safe queue that a `root.after(100)` dispatcher applies to the model on the UI thread. Tk widgets are touched only from the UI thread. Panel-initiated transitional states (STARTING, DRAINING) are pinned by the owning worker and carry deadlines, so a slow poll can't flicker a starting daemon and a hung action can't freeze a row. Mechanics owned by [TDD §4.3](../architecture/design-docs/tdd/tdd-7-1-1-linkwatcher-control-panel-t2.md).

### UI/UX Design

Master–detail single window: daemon list (Treeview) on the left, tabbed Log / Configuration / Validation detail on the right, toolbar + status bar, and a modal shutdown dialog. Visual tokens, spacing, accessibility, and interaction behavior are owned by [UI Design PD-UIX-003](../design/ui-ux/features/ui-design-7-1-1-linkwatcher-control-panel.md); the TDD §4.2 maps its components to concrete Tkinter/ttk widgets. This plan sequences the build; it does not redefine visuals.

## Implementation Approach

### Phase Breakdown

The phase skeleton adopts the TDD §6.2 seven-step sequence (each step leaves the panel in a runnable, demonstrable state). Effort scale: S = 1–3 h, M = 3–8 h, L = 8+ h.

**Phase A — Foundation & settings** (Effort: M)
- Deliverables: `control_panel.py` entry, `app.py` Tk root + window shell (empty states only), `settings.py` (panel-config loading + registry resolution chain), panel log.
- Dependencies: none (all runtime deps already exist).

**Phase B — Discovery, model & daemon list** (Effort: L)
- Deliverables: `discovery.py` poll thread with the full classification matrix (RUNNING / STOPPED / STALE_LOCK / orphan, three-way identity, pair resolution), `AppModel` + dispatcher queue, live daemon list rendering. **Milestone: panel is a truthful read-only monitor.**
- Dependencies: Phase A.

**Phase C — Lifecycle actions** (Effort: L)
- Deliverables: `lifecycle.py` — start via launcher shell-out, drain watcher + verified-pair termination + owned-lock cleanup, transitional-state pins with deadlines, toolbar enablement.
- Dependencies: Phase B (model + discovery + fixtures).

**Phase D — Shutdown orchestration** (Effort: M)
- Deliverables: `WM_DELETE_WINDOW` → modal shutdown dialog → parallel per-daemon drains → deterministic app exit (bounded by the grace period, can never hang).
- Dependencies: Phase C (drain/terminate logic).

**Phase E — Detail panes** (Effort: L)
- Deliverables: `log_tail.py` (incremental, rotation-aware), `validation.py` (`--validate` subprocess), `config_edit.py` (read → validate-on-save via `LinkWatcherConfig.validate()` → atomic replace), and their `views/` tabs.
- Dependencies: Phase B (model + selection); independent of C/D.

**Phase F — Single instance & hook auto-open** (Effort: S)
- Deliverables: `single_instance.py` (loopback socket + `panel.port` + SURFACE protocol); **modify** `start_linkwatcher_hook_wrapper.ps1` (detached `pythonw.exe` auto-open call); **modify** `deployment/install_global.py` (ship the entry script + subpackage).
- Dependencies: Phase A; scheduled after Phase E per the TDD order.

**Phase G — Hardening & accessibility** (Effort: M)
- Deliverables: all EC-1…EC-11 exercised against fixtures, worker error isolation verified, remaining component/state-logic tests.
- Dependencies: Phases B–F.

### Task Sequencing

```
A ──▶ B ──▶ C ──▶ D
      │
      ├──▶ E              (needs model/selection; independent of C/D)
A ──▶ F                   (independent of B–E; scheduled after E)
B,C,D,E,F ──▶ G
```

1. Phase A — M (Depends on: none)
2. Phase B — L (Depends on: A)
3. Phase C — L (Depends on: B)
4. Phase D — M (Depends on: C)
5. Phase E — L (Depends on: B)
6. Phase F — S (Depends on: A)
7. Phase G — M (Depends on: B, C, D, E, F)

**Shared-component coordination**: `model.py` grows across B/C/D/E; `views/` across A/C/D/E; the test `conftest.py` fixtures (fake process table, fake clock, fake log-stat source) are built in B/C and consumed by every later phase. **External-surface phases**: launcher (C), `--validate` (E), central registry (B), hook wrapper + installer (F). **No database phase anywhere.**

### Technical Approach

- **Patterns**: observable model + one-way data flow; worker-thread + UI-dispatcher queue; injectable seams for every hard-to-test boundary (discovery, drain clock, launcher invocation, config save).
- **Libraries**: Tkinter/ttk (stdlib), `psutil >= 5.9.0` (already in `pyproject.toml`). **No new packages.**
- **Code organization**: `control_panel.py` entry at repo root; all logic under `src/linkwatcher/linkwatcher_control_panel/` with `views/` isolated so the toolkit stays swappable (PySide6 fallback rewrites only `views/`).
- **Reuse mandates (TDD decisions)**: start only via the launcher (D-T4); config validation only via `LinkWatcherConfig.validate()` (D-T6); three-way identity before any terminate (D-T5).

## Dependencies and Integration

### Internal Dependencies

- **Feature 0.1.1 Core Architecture** — `main.py` CLI + `.linkwatcher.lock` per-project PID lock. Status: 🟢 Completed. Integration: daemon identity + start path.
- **Feature 0.1.3 Configuration** — `LinkWatcherConfig.from_file()/validate()`. Status: 🟢 Completed. Integration: config editor validate-on-save (never a parallel validator).
- **Feature 3.1.1 Logging & Monitoring** — per-project `logs/linkwatcher/LinkWatcherLog*.txt`. Status: 🟢 Completed. Integration: log pane tail + drain quiescence heuristic.
- **Feature 6.1.1 Link Validation** — `--validate` scan. Status: 🟢 Completed. Integration: Validation pane subprocess (takes no lock).

All dependency features are complete — **nothing must be implemented first**.

### External Dependencies

- **psutil** `>= 5.9.0` — already present. Purpose: process enumeration/identity/termination.
- **Tkinter/ttk** — Python stdlib. Purpose: GUI toolkit (Decision D-T1, checkpoint-approved).
- **Central `project-registry.json`** (in appdev central) — consumed read-only for the project list.

### Integration Points

| Surface | Used by phase | Contract / notes |
|---------|---------------|------------------|
| Launcher `start_linkwatcher_background.ps1` | C | Exit 0 = started/already-running (idempotent), exit 1 = failure + stderr reason. Never spawn the daemon directly (D-T4). |
| Lock files + psutil | B, C | Three-way identity agreement (lock PID + `main.py` in cmdline + project root), re-verified **at kill time**, not only at poll time. |
| Per-project log files | C, E | Two consumers — log-pane tail and drain quiescence heuristic; both rotation-safe (target newest `LinkWatcherLog*.txt`). |
| `main.py --validate` | E | Short-lived subprocess, takes no lock; `--config` appended only when the per-project config exists (mirrors `run_linkwatcher_validate.ps1`). |
| `LinkWatcherConfig` | E | Sole config validator; never mocked in tests (D-T6). |
| Hook wrapper | F | One detached non-blocking `pythonw.exe` call; must not add session-start latency. |
| `install_global.py` | F | Must ship `control_panel.py` + the subpackage, or the deployed hook auto-open points at nothing. |

## Testing Strategy

Full test design (70 scenarios) is owned by [Test Spec TE-TSP-045](../../../test/specifications/feature-specs/test-spec-7-1-1-linkwatcher-control-panel.md). This plan maps its priority order to the build phases. Test files are created via `New-TestFile.ps1` into the scaffolded `test/automated/unit/7-operations-control/7-1-control-panel/`.

### Unit Testing

- **Framework**: pytest (project standard).
- **Per-phase focus**:
  - A → UNIT-S1…S5 (settings / registry resolution).
  - B → conftest fake-process-table fixture + UNIT-D1…D10 (classification & three-way identity), UNIT-M1…M7 (model reconciliation, pins, expiry).
  - C → fake clock + log-stat fixtures + UNIT-L1…L11 (start, drain state machine, termination guard, lock cleanup).
  - E → UNIT-T1…T5 (log tail), UNIT-V1…V5 (validation), UNIT-C1…C6 (config save incl. atomic/interrupted).
  - F → UNIT-I1…I4 (single instance, real loopback sockets).
- **Highest-value target** (per the test spec): the termination guard — a PID match alone must never terminate (UNIT-L9), lock deleted only if self-owned (UNIT-L10/L11); and the config-save guarantee that invalid YAML/values never reach disk (UNIT-C2/C3/C5).

### UI/Component Testing

Headless — drive view **state logic** (enablement matrices, status→glyph+text mapping, single-visible-state panes) via `AppModel` without instantiating Tk widgets: COMP-1…COMP-8 (Phases D/E/G). Widget rendering and focus order are E2E/manual.

### Integration Testing

INT-1…INT-9 exercise the poller→queue→dispatcher→model pipeline and parallel shutdown orchestration with fixtures: external-start/stop convergence (B), start/stop/duplicate-start pipelines (C), parallel drains + bounded exit (D), config-save-while-running (E), worker error isolation (G).

### Test Data Requirements

- **Fake process table** (injectable seam): scripted entries — valid pair, recycled PID (right PID/wrong cmdline), wrong-root process, lockless orphan, parent/child pair.
- **Fake clock + log-stat source**: drain timelines (idle-at-3s, active-past-20s, rotated-mid-drain) — no real 20 s waits.
- **Real temp files**: lock/registry/config/log fixtures for atomic-replace and rotation tests; real loopback sockets.
- **`LinkWatcherConfig`**: deliberately real, never mocked.

**Deferred to E2E acceptance** (per the test spec): AC-5 (live log in the real window), AC-8 (real in-flight update completes), AC-9 end-to-end, AC-11 (real window auto-open/surfacing). **Deferred to Performance & E2E Test Scoping** (after code review): large-log tail timing and poll-cycle duration.

## Risk Assessment

### Technical Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|-----------|
| Wrong-process termination (PID recycling) | High | Low | Three-way identity guard re-checked at kill time; UNIT-L9 + lock-cleanup tests are High-priority; treated as the single most important test target |
| Threading defects (UI-thread violations, pin/poll races) | High | Medium | Hard rule: Tk touched only from the UI thread via the dispatcher queue; pins carry deadlines so hangs degrade to poll truth; model semantics fully unit-covered before integration tests |
| Drain heuristic drops in-flight move-correlations | Medium | Medium | Accepted by FDD BR-7 — atomic writes bound damage to *dropped* (never corrupted) updates; 20 s grace covers one full 10 s correlation window; real-daemon AC-8 fixture at E2E |
| Deployed-install divergence (daemons run from `~/bin`, dev from repo) | Medium | Medium | Installer update is in-scope (Phase F); verify hook auto-open against a real install before finalization |
| View logic accreting into widgets (untestable in CI) | Low | Medium | COMP tests force display-free factoring; "render from model only" is a standing design obligation |
| Registry lists frozen/irrelevant projects | Low | Medium | Open TDD question with a decision point in Phase B; default = show everything the registry lists |

### Schedule Risks

- **Phase G accessibility verdict could force a `views/` rewrite** — Mitigation: the model/view split localizes the blast radius to `views/`; the rest of the feature is unaffected, so a late Qt switch is a bounded, not catastrophic, cost.
- **Hook-wrapper edit sits on every session's startup path** — Mitigation: single detached non-blocking call; verify session start immediately after the edit.

### Resource Risks

- Single-implementer project; no cross-team coordination risk. New GUI toolkit is a first for the project — Mitigation: Tkinter is stdlib and the UI design's envelope needs only standard widgets (Decision D-T1).

## Quality Standards

### Code Quality

- Follow project Python conventions (naming, formatting; `dev lint` / `dev format`). Explicit error handling — every external surface fails into a pane-local error state, never a silent swallow or a crashed mainloop. Injectable seams and small focused modules per the testability obligation.

### Performance Requirements

- UI-thread interactions ≤ ~100 ms (all blocking work off-thread).
- Displayed state converges on real state ≤ 5 s (2.5 s poll + in-place row updates).
- Log tail reads appended bytes only into a 1,000-line capped buffer; instant open on arbitrarily large logs.
- Near-zero idle CPU (only the poll tick). (Formal perf tests deferred to PF-TSK-086.)

### Security Requirements

- **Process termination correctness** is the security-adjacent core: three-way identity agreement before any kill; lock deletion only when the lock still holds the terminated PID.
- Config editor text validated (YAML parse + `LinkWatcherConfig.validate()`) before any write; atomic replace prevents partial writes.
- Single-instance socket binds `127.0.0.1` only, fixed one-verb `SURFACE` protocol, accepts no data. Registry/lock contents treated as untrusted (malformed → surfaced error, never crash).
- Local single-user tool: no authentication/authorization, no network egress, no secrets.

## Deployment and Rollback

### Deployment Strategy

- Shipped as part of LinkWatcher's global install: `deployment/install_global.py` gains the new `control_panel.py` entry script and the `linkwatcher_control_panel` subpackage (Phase F). No environment sequence / feature flags / migrations — the panel is additive and inert until launched.
- The `SessionStart` hook wrapper gains the detached auto-open call; existing daemon start behavior is unchanged.

### Rollback Plan

- **Trigger**: the panel misbehaves or the hook auto-open regresses session start.
- **Steps**: revert the two modified files (`start_linkwatcher_hook_wrapper.ps1`, `install_global.py`) and remove the entry-script install step; the daemon and every existing surface are untouched, so removal is clean.
- **Consistency**: no data to reconcile (the panel persists no daemon state); the daemons run independently and survive panel removal.

## Implementation Artifacts

### Code Deliverables

- **Entry script**: `control_panel.py` (repo root, beside `main.py`).
- **Subpackage** `src/linkwatcher/linkwatcher_control_panel/`: `app.py`, `model.py`, `discovery.py`, `lifecycle.py`, `log_tail.py`, `validation.py`, `config_edit.py`, `single_instance.py`, `settings.py`, `views/`.
- **Modified**: `process-framework/tools/linkWatcher/start_linkwatcher_hook_wrapper.ps1`, `deployment/install_global.py`.
- **Tests**: `test/automated/unit/7-operations-control/7-1-control-panel/` — `test_panel_model.py`, `test_panel_settings.py`, `test_panel_discovery.py`, `test_panel_lifecycle.py`, `test_panel_log_tail.py`, `test_panel_validation.py`, `test_panel_config_edit.py`, `test_panel_single_instance.py`, `test_panel_integration.py`, `test_panel_views.py`, plus a local `conftest.py`.

### Documentation Deliverables

- Feature state file (this task, initialized).
- User documentation: **deferred** — evaluated in the feature state file's User Documentation inventory (the panel is user-visible, so how-to/reference rows will be marked `❌ Needed` and triggered via User Documentation Creation after test scoping).

### Test Artifacts

- Unit + integration + component test files (above); shared fixtures in the local `conftest.py`; general fixtures reused from `test/automated/conftest.py`.

## Success Criteria and Handoff

### Completion Criteria

- All 8 automatable acceptance criteria (AC-1/2/3/4/6/7/9-fixture/10/12) closed by passing tests; the 4 E2E-deferred ACs flagged for the milestone workflow.
- All 70 test-spec scenarios implemented and passing; zero new package dependencies.
- Critical-dimension gates met: termination-guard tests, atomic-save/interrupted-save tests, keyboard-only operability.
- Panel shipped by the installer; hook auto-open verified against a deployed install.

### Handoff Checklist

- [ ] All code written and reviewed (Code Review, PF-TSK-005)
- [ ] All tests passing
- [ ] Feature state file updated through implementation
- [ ] Hook auto-open verified against a real install
- [ ] Human partner sign-off

## Related Documentation

- [FDD PD-FDD-034](../../functional-design/fdds/fdd-7-1-1-linkwatcher-control-panel.md)
- [UI Design PD-UIX-003](../design/ui-ux/features/ui-design-7-1-1-linkwatcher-control-panel.md)
- [TDD PD-TDD-033](../architecture/design-docs/tdd/tdd-7-1-1-linkwatcher-control-panel-t2.md)
- [Test Spec TE-TSP-045](../../../test/specifications/feature-specs/test-spec-7-1-1-linkwatcher-control-panel.md)
- [Feature Implementation State PD-FIS-056](../../state-tracking/features/7.1.1-LinkWatcher-Control-Panel-implementation-state.md)
- [Task Definition: Feature Implementation Planning](../../../process-framework/tasks/04-implementation/feature-implementation-planning-task.md)

---

**Last Updated**: 2026-07-15
**Status**: Draft
**Owner**: AI Agent & Human Partner
