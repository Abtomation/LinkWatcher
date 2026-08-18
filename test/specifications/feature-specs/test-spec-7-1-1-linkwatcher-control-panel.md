---
id: TE-TSP-045
type: Document
category: General
version: 1.6
created: 2026-07-12
updated: 2026-08-18
description: "7.1.1 Tier 2 — Control Panel discovery classification, drain-then-terminate lifecycle, termination guard, detail panes, single instance"
feature_id: 7.1.1
feature_name: LinkWatcher Control Panel
tdd_path: doc/technical/architecture/design-docs/tdd/tdd-7-1-1-linkwatcher-control-panel-t2.md
test_tier: 2
---

# Test Specification: LinkWatcher Control Panel

## Overview

This document provides comprehensive test specifications for the **LinkWatcher Control Panel** feature (ID: 7.1.1), derived from the Technical Design Document [PD-TDD-033](../../../doc/technical/architecture/design-docs/tdd/tdd-7-1-1-linkwatcher-control-panel-t2.md).

**Test Tier**: 2 (Comprehensive: unit + integration + UI/component)
**TDD Reference**: [PD-TDD-033](../../../doc/technical/architecture/design-docs/tdd/tdd-7-1-1-linkwatcher-control-panel-t2.md)
**Created**: 2026-07-12
**Implementation Coverage**: 83/83 scenarios implemented (100%) — Phases A–G, plus the Code Review gap closure (PF-STA-111, three sessions): session 1 added UNIT-C7/C8, UNIT-S7, UNIT-M8 and corrected the EC-10/EC-11 coverage claims; session 2 added UNIT-D11/D12, UNIT-M9 and UNIT-L12…L15 (the last closing TD263); session 3 added INT-10 and UNIT-P1. Every assertion added across the three sessions was mutation-verified — broken deliberately, confirmed to turn its own test red, and restored

## Feature Context

### TDD Summary

The Control Panel is the project's first GUI surface: a single-window Tkinter/ttk desktop application acting as a **pure supervisor** over existing external surfaces (lock files, OS process state, the launcher script, `--validate` CLI mode, log files, per-project YAML config). Key components (new subpackage `src/linkwatcher/linkwatcher_control_panel/`): `discovery.py` (poll thread classifying each registry project via lock + psutil three-way identity agreement), `model.py` (single observable `AppModel`, one-way data flow, transitional-state pins with deadlines), `lifecycle.py` (start via launcher shell-out; observational drain-then-terminate bounded by a 20 s grace period), `single_instance.py` (localhost socket + `panel.port` file), `log_tail.py` (incremental rotation-aware tail), `validation.py` (`--validate` subprocess), `config_edit.py` (read / validate via `LinkWatcherConfig.validate()` / atomic save), `settings.py` (panel-config + registry resolution), `app.py` (Tk root, dispatcher queue, shutdown orchestration), `views/` (widgets rendering from the model only).

The TDD deliberately isolates every hard-to-test boundary behind an injectable seam (§5.5): fabricated lock/process fixtures for discovery, fake log-mtime source + fake clock for drain (no real 20 s waits), mockable launcher invocation, temp-file config fixtures, and display-free `AppModel` testing for UI-state truthfulness.

### Test Complexity Assessment

Automated test depth based on feature tier assessment:

- **Tier 1 🔵**: Core unit tests and key integration scenarios — focus on happy paths and critical edge cases
- **Tier 2 🟠**: Comprehensive unit tests, integration tests, and UI/component tests — broader edge case coverage
- **Tier 3 🔴**: Full automated test suite with exhaustive edge cases, error paths, and component interaction tests

**Selected Tier**: 2 — Per [PD-ASS-201](../../../doc/documentation-tiers/assessments/PD-ASS-201-7.1.1-linkwatcher-control-panel.md) (normalized score 1.80). Multiple interacting components (discovery, model, lifecycle, panes) with threading, process management, and a new GUI toolkit; Reliability is the dominant quality attribute (TDD §3) — drain bounds, termination-guard correctness, and error isolation get the deepest coverage. No Dimension Profile exists yet (Feature Implementation Planning runs after the TDD), so standard Tier 2 depth applies with no Critical-dimension escalations.

## Cross-References

### Functional Requirements Reference

> **📋 Primary Documentation**: FDD Creation Task (PF-TSK-027)
> **🔗 Link**: [Functional Design Document — PD-FDD-034](../../../doc/functional-design/fdds/fdd-7-1-1-linkwatcher-control-panel.md)
> **👤 Owner**: FDD Creation Task

#### Testing-Level Functional Context

Tests validate the panel-owned lifecycle model: truthful daemon-state display (FR-1/FR-4), drain-before-terminate semantics (BR-3/BR-7), per-project singleton protection (BR-1/BR-2), and the full edge-case catalog EC-1…EC-11. The FDD's emphasis — "particular emphasis on the drain-then-terminate shutdown behavior and on never acting on the wrong process" — drives the High-priority scenarios below.

**Acceptance Criteria to Test** (automatable at this level):

- **AC-1** list correctness → Integration: discovery→model flow (INT-1, INT-2)
- **AC-2** start from panel → UNIT-L1…L3, INT-3
- **AC-3** stop drains then terminates → UNIT-L4…L7, INT-4
- **AC-4** hook-started daemon manageable → INT-1 (external start reflected), INT-4
- **AC-6** validation without stopping daemon → UNIT-V1…V5
- **AC-7** close drains and terminates all → INT-5, INT-6
- **AC-9** grace-period bound, no hang → UNIT-L5, INT-6
- **AC-10** no duplicate daemon → UNIT-L2, INT-9
- **AC-12** config edit persisted + restart notice → UNIT-C1…C6, INT-7

**Deferred to E2E acceptance testing** (cannot be fully closed by automated tests against fixtures; flagged for the milestone-triggered E2E workflow):

- **AC-5** (live log view in the real window), **AC-8** (real in-flight update completes — needs a real daemon mid-update), **AC-9** end-to-end against a real daemon, **AC-11** (real window auto-open/surfacing from the hook). The TDD (§7.3) already routes AC-8/AC-9 drain-with-in-flight-move to E2E acceptance.

**Business Rules to Validate**:

- **BR-1/BR-2** singleton + correct-process identity → discovery three-way agreement and termination-guard tests
- **BR-3/BR-7** bounded drain → drain state-machine tests with fake clock
- **BR-6** validation never touches the daemon → validation runner takes no lock, subprocess-only
- **BR-9** restart-needed notice whenever the daemon is running → config save integration test

### Technical Design Reference

> **📋 Primary Documentation**: TDD Creation Task (PF-TSK-022)
> **🔗 Link**: [Technical Design Document — PD-TDD-033](../../../doc/technical/architecture/design-docs/tdd/tdd-7-1-1-linkwatcher-control-panel-t2.md)
> **👤 Owner**: TDD Creation Task
>
> **UI Design**: [PD-UIX-003](../../../doc/technical/design/ui-ux/features/ui-design-7-1-1-linkwatcher-control-panel.md) owns visual/interaction design; its "UI-state truthfulness" property (§10.4) is tested here by driving `AppModel` directly — pixel/widget behavior is an E2E/manual concern.

#### Testing-Level Implementation Context

Every TDD component gets isolated unit coverage through its designed seam; integration tests exercise the poller→queue→dispatcher→model pipeline and the parallel shutdown orchestration with fixtures. The security-adjacent invariant (TDD §3.2/§7.2) — *termination requires three-way agreement (lock PID + `main.py` in command line + project root); a PID match alone is never sufficient* — is treated as the single most important unit-test target, alongside the config-save guarantee that invalid YAML/values never reach disk.

**Component Testing Strategy**:

- All components under `src/linkwatcher/linkwatcher_control_panel/` covered per the [Component-to-Test Mapping](#component-to-test-mapping)
- Views tested as headless state logic (enablement matrices, state mapping) — widget instantiation is not unit-tested (no display in CI)
- No API and no database → those template sections intentionally removed (per [PD-FDD-034](../../../doc/functional-design/fdds/fdd-7-1-1-linkwatcher-control-panel.md): no new API contract, no schema)

**Mock Requirements**:

- Process table and lock files: fabricated fixtures (never real daemon processes in unit tests)
- Subprocesses (launcher, `--validate`): mocked invocations with scripted exit codes / output
- `LinkWatcherConfig.validate()`: deliberately **real**, never mocked (TDD D-T6 — no parallel validator to drift)
- Time: fake clock injected into drain logic (no real 20 s waits)

## Component-to-Test Mapping

| TDD Component | Test Type(s) | Key Test Focus |
|----------------|-------------|----------------|
| [`model.py` (AppModel, pins)](../../../src/linkwatcher/linkwatcher_control_panel) | Unit | Observable updates, reconciliation rule, pin deadlines, selection survival |
| [`settings.py`](../../../src/linkwatcher/linkwatcher_control_panel) | Unit | panel-config defaults/overrides, registry resolution order |
| [`discovery.py`](../../../src/linkwatcher/linkwatcher_control_panel) | Unit, Integration | Classification matrix (RUNNING/STOPPED/STALE_LOCK/orphan), three-way identity, pair resolution |
| [`lifecycle.py`](../../../src/linkwatcher/linkwatcher_control_panel) | Unit, Integration | Start via launcher, drain state machine, force-terminate, termination guard, lock cleanup |
| [`log_tail.py`](../../../src/linkwatcher/linkwatcher_control_panel) | Unit | Incremental reads, rotation reattach, bounded buffer, missing-log state |
| [`validation.py`](../../../src/linkwatcher/linkwatcher_control_panel) | Unit | Exit-code → state mapping, count/report extraction, failure surfacing |
| [`config_edit.py`](../../../src/linkwatcher/linkwatcher_control_panel) | Unit, Integration | Validate-on-save pipeline, atomic replace, read-error states |
| [`single_instance.py`](../../../src/linkwatcher/linkwatcher_control_panel) | Unit | Socket bind, SURFACE protocol, stale port takeover |
| [`app.py` (dispatcher, shutdown)](../../../src/linkwatcher/linkwatcher_control_panel) | Integration | Poller→queue→model pipeline, parallel drains, bounded exit, error isolation |
| [`views/` (state logic)](../../../src/linkwatcher/linkwatcher_control_panel) | Component | Action enablement, status rendering rules, single-visible-state panes |

## Test Categories

### Unit Tests

#### Models — `model.py`

| ID | Test Focus | Key Test Cases | Edge Cases |
| -- | ---------- | -------------- | ---------- |
| UNIT-M1 | Observable updates | Subscriber callback fires on snapshot update; unchanged rows produce no spurious notification | Multiple subscribers |
| UNIT-M2 | Keyed snapshots | Snapshot update replaces the row for its `project_id` only | Unknown project_id added, removed project dropped |
| UNIT-M3 | Selection survival | `selected_project_id` retained across full poll refresh (keyed by project, not index) | Selected project disappears from registry |
| UNIT-M4 | Pin overrides poll | Row pinned DRAINING stays DRAINING when a poll reports RUNNING (truthful-state rule, FR-4) | STARTING pin vs. poll STOPPED |
| UNIT-M5 | Pin expiry | Pin whose deadline passed is dropped; next poll truth wins (hung action never freezes a row) | Deadline exactly at boundary |
| UNIT-M6 | Pin resolution | STARTING pin cleared when poll observes the running pair; DRAINING cleared on observed exit | Poll confirms before worker resolves |
| UNIT-M7 | Shutdown mode | `shutting_down = True` reflected to subscribers as global mode | Set twice (idempotent) |
| UNIT-M8 | Failed poll is not an empty registry (CR-14) | A poll that raised returns no snapshots **plus** an error; applying that as truth used to drop every row and clear the selection, which reloads the Configuration pane and discards unsaved edits. Rows, selection, pins and `last_refresh` are all preserved on a no-rows-plus-error result. Paired with two discriminating cases: a *successful* empty poll still clears rows and selection (so a deregistered registry is not masked), and a poll returning rows **with** an error still applies the rows — matching `list_pane_display`'s "rows win" precedence | fake clock, injected `refreshed_at` |
| UNIT-M9 | Stale poll rejection (CR-7) | Results are applied in completion order, so a slow poll can land after a faster later one; sequences stamped at poll *start* let the model drop the straggler, including its error. Paired with guards that a genuinely newer poll still applies and that unsequenced callers are unaffected | fake clock |

#### Services

**`settings.py` — panel settings + registry resolution**

| ID | Test Focus | Key Test Cases | Mock Dependencies |
| -- | ---------- | -------------- | ----------------- |
| UNIT-S1 | Defaults | Missing `panel-config.yaml` → grace 20 s, log-idle 3 s, poll 2.5 s | tmp install dir |
| UNIT-S2 | Partial override | File with only `grace_period_seconds` → that key overridden, rest defaults | tmp file |
| UNIT-S3 | Invalid values | Non-numeric / negative values rejected → defaults + surfaced warning, never crash | tmp file |
| UNIT-S4 | Registry resolution order | CLI arg beats env var beats config key (each level tested) | env patching, tmp files |
| UNIT-S5 | Unresolved registry | No source configured → error-banner state, **distinct from** empty-registry (EC-8) state | — |
| UNIT-S7 | Non-finite / non-UTF-8 settings (CR-10, CR-11) | `.inf` / `.nan` / `-.inf` and an out-of-float-range integer are rejected like any other invalid value — they used to pass every gate (both are `float`, and neither satisfies `<= 0`) and reach the discovery thread, where `Event.wait(inf)` raises `OverflowError` outside the caller's try and silently kills polling. A non-UTF-8 `panel-config.yaml` yields defaults + a warning instead of aborting startup before any window exists. Paired with a case asserting legitimate values (including ints) still apply with no warnings | tmp install dir, raw bytes |

**`discovery.py` — classification & identity**

| ID | Test Focus | Key Test Cases | Mock Dependencies |
| -- | ---------- | -------------- | ----------------- |
| UNIT-D1 | RUNNING classification | Lock PID + live process with `main.py` + project root in cmdline → RUNNING, uptime = oldest `create_time` of pair | fake process table |
| UNIT-D2 | STALE_LOCK (dead PID) | Lock exists, PID not in process table → STALE_LOCK, rendered not-running, never acted on (EC-1/EC-3) | fake process table |
| UNIT-D3 | STALE_LOCK (recycled PID) | Lock PID alive but cmdline lacks `main.py` → STALE_LOCK (three-way agreement fails, KR-03) | fake process table |
| UNIT-D4 | Wrong project root | Live `main.py` process for a *different* root → not this project's daemon | fake process table |
| UNIT-D5 | Lockless orphan | No lock, but matching process found by cmdline scan → RUNNING with detail note | fake process table |
| UNIT-D6 | STOPPED | No lock, no matching process → STOPPED | fake process table |
| UNIT-D7 | Pair resolution | Verified process plus parent/child matching the cmdline test → `pids` contains the whole pair | fake process table with parent/child |
| UNIT-D8 | Malformed lock | Garbage lock-file content → defensive STALE_LOCK/error detail, no exception | tmp lock file |
| UNIT-D9 | Malformed registry | Unparseable `project-registry.json` → surfaced error state, no crash | tmp registry file |
| UNIT-D10 | Empty registry | Zero projects → empty snapshot set (EC-8 calm state) | tmp registry file |
| UNIT-D11 | Run-mode discrimination (CR-4) | A `main.py --validate` scan of the *same* project carries the same entry script and the same `--project-root` as the daemon; it must never be claimed, or a stopped project renders RUNNING and Stop/close truncates the scan. `--version` / `--help` likewise. Paired with a guard case proving ordinary daemon flags (`--debug`, `--quiet`, `--dry-run`, `--no-initial-scan`, `--log-file`) are still claimed | process entries |
| UNIT-D12 | Wrapper shells are not daemons (CR-5) | `bash -c '…'`, `pwsh -Command '& …'` and `cmd /c '…'` whose single quoted argument mentions `main.py … --project-root X` must not be claimed — the old fallback regex-searched a *re-joined* argv. Paired with a guard case keeping the documented one-token raw command line parseable | process entries |

**`lifecycle.py` — start / drain / terminate**

| ID | Test Focus | Key Test Cases | Mock Dependencies |
| -- | ---------- | -------------- | ----------------- |
| UNIT-L1 | Start success | Launcher invoked with project's own script path; exit 0 → STARTING pin posted | mocked subprocess |
| UNIT-L2 | Start idempotent | Exit 0 on already-running (launcher singleton guard) → no error, no duplicate (EC-2/AC-10) | mocked subprocess |
| UNIT-L3 | Start failure | Exit 1 → START_FAILED with captured stderr as reason (EC-7) | mocked subprocess |
| UNIT-L4 | Drain quiescence | Newest log silent ≥ `log_idle_threshold` (3 s) → terminate verified pair | fake clock + fake log stat source |
| UNIT-L5 | Drain timeout | Log stays active until grace period (20 s) elapses → force-terminate, FORCE_STOPPED surfaced (EC-4/AC-9) | fake clock + fake log stat source |
| UNIT-L6 | Rotation-safe watch | Active log renamed mid-drain → watcher retargets newest `LinkWatcherLog*.txt` | tmp log dir |
| UNIT-L7 | No log file | Project with no log file at all → treated as quiescent (drain does not wait the full grace on nothing) | tmp log dir |
| UNIT-L8 | Terminate targets pair | Both PIDs of the verified pair terminated; unrelated PIDs untouched | fake process table |
| UNIT-L9 | Termination guard | Refuses to terminate when three-way agreement fails at kill time (PID recycled between poll and action) | fake process table |
| UNIT-L10 | Lock cleanup (owned) | After confirmed exit, lock deleted **only if** it still holds the terminated PID | tmp lock file |
| UNIT-L11 | Lock cleanup (foreign) | Lock now holds a different PID → left intact | tmp lock file |
| UNIT-L12 | Pin outlives its worker (CR-8) | The DRAINING pin TTL must exceed the stop worker's worst case — the full grace period plus the exit wait — or the row reverts to Running mid-stop and re-enables a Stop the busy guard then swallows | pure arithmetic over the module constants |
| UNIT-L13 | Launcher shell resolution (CR-9) | `pwsh.exe` is resolved to an absolute path with relative PATH entries skipped, so Windows' current-directory-first search cannot supply the shell. `shutil.which` is *not* usable here — on Windows it prepends `os.curdir` even when given an explicit `path=`. Paired with a guard that an unresolvable PATH degrades to the bare name rather than losing Start | tmp dirs, decoy exe |
| UNIT-L14 | Capture sweep (CR-12) | Every successful Start leaked a stdout/stderr capture pair (the spawned daemon inherits the handle; the CRT opens without `FILE_SHARE_DELETE`), so each run sweeps aged captures. Paired with guards that only this module's own prefixes are touched and that an in-flight capture survives | tmp dir |
| UNIT-L15 | Unconfirmed exit (TD263) | A terminator whose target does *not* leave the process table drives `wait_for_exit` to its timeout: the outcome reports `exited=False` and the lock is left intact. Previously unreachable because the fake terminator removed PIDs synchronously (TE-TAR-090) | unlinked fake terminator, fake clock |

**`log_tail.py`**

| ID | Test Focus | Key Test Cases | Mock Dependencies |
| -- | ---------- | -------------- | ----------------- |
| UNIT-T1 | Initial tail | Open on large file seeks to `max(0, size − 64 KB)`; only tail rendered | tmp log file |
| UNIT-T2 | Incremental reads | Tick reads appended bytes only (byte-offset tracked, no full re-read) | tmp log file |
| UNIT-T3 | Rotation reattach | File missing or size shrank → reattach to newest `LinkWatcherLog*.txt` from start (EC-5) | tmp log dir |
| UNIT-T4 | Bounded buffer | Display buffer capped at 1,000 lines, trimmed from top | tmp log file |
| UNIT-T5 | Missing log | No log file → placeholder state, never an exception (EC-5) | tmp dir |

**`validation.py`**

| ID | Test Focus | Key Test Cases | Mock Dependencies |
| -- | ---------- | -------------- | ----------------- |
| UNIT-V1 | Clean result | Exit 0 → state `ok`, broken_count 0 | mocked subprocess |
| UNIT-V2 | Broken links | Exit 1 with report → state `broken`, count parsed, report path = `logs/linkwatcher/LinkWatcherBrokenLinks.txt` (AC-6) | mocked subprocess + tmp report |
| UNIT-V3 | Failure | Spawn error / nonzero without report → state `failed` with captured stderr, never rendered as success (EC-6) | mocked subprocess |
| UNIT-V4 | Single run per project | Second trigger while running for same project rejected; other projects unaffected (BR-6) | mocked subprocess |
| UNIT-V5 | Command construction | `--config` appended only when the per-project config exists (mirrors [run_linkwatcher_validate.ps1](../../../process-framework/tools/linkWatcher/run_linkwatcher_validate.ps1) semantics); no lock taken | tmp config file |

**`config_edit.py`**

| ID | Test Focus | Key Test Cases | Mock Dependencies |
| -- | ---------- | -------------- | ----------------- |
| UNIT-C1 | Read error | Missing/unreadable config → read-error state with path + reason, editor-disabled signal, file never auto-written (EC-10) | tmp dir |
| UNIT-C2 | Invalid YAML blocked | Parse error → save blocked, line-numbered reason, file on disk untouched (EC-11) | tmp config file |
| UNIT-C3 | Invalid values blocked | Parses as YAML but fails `LinkWatcherConfig.validate()` (real validator, D-T6) → save blocked, file untouched | tmp config file |
| UNIT-C4 | Atomic save | Valid content → temp file in same directory + `os.replace`; result byte-identical to submitted text | tmp config file |
| UNIT-C5 | Interrupted save | Failure injected between temp-write and replace → original file intact, no truncation | tmp config file |
| UNIT-C6 | Default skeleton | "Create default config" writes a minimal commented skeleton that round-trips through `LinkWatcherConfig.from_file()` | tmp dir |
| UNIT-C7 | Non-UTF-8 read (CR-2) | A config with an undecodable byte → read-error state, **not** an escaping `UnicodeDecodeError`; also asserts it is *not* decoded leniently, since lossy text would be written back on the next save (EC-10) | tmp config file with raw bytes |
| UNIT-C8 | Wrongly typed value blocked (CR-3) | `log_level: 5`, `max_file_size_mb: 'big'`, `monitored_extensions: 7`, `move_detect_delay: 'x'` — the real loader *raises* on each rather than reporting an issue (PD-BUG-123) → save blocked with an operator-facing explanation, file byte-identical, no temp residue. Paired with a discriminating case asserting an ordinary `validate()` issue still takes the issue path, so the handler cannot swallow normal reporting (EC-11, KR-05) | tmp config file, real validator |

**`single_instance.py`**

| ID | Test Focus | Key Test Cases | Mock Dependencies |
| -- | ---------- | -------------- | ----------------- |
| UNIT-I1 | First launch | Binds `127.0.0.1` ephemeral port; writes port to `panel.port` | tmp install dir, real socket |
| UNIT-I2 | Second launch | Reads port file, connects, sends `SURFACE`, reports "already running" | real sockets |
| UNIT-I3 | Surface dispatch | Listener receives `SURFACE` → surface callback posted exactly once | real sockets |
| UNIT-I4 | Stale port file | Port file present, nothing listening → connect fails → new launch takes over and rewrites port file | tmp install dir |

### Integration Tests

#### Data Flow Testing

| ID | Flow | Components Involved | Test Scenario | Expected Outcome |
| -- | ---- | ------------------- | ------------- | ---------------- |
| INT-1 | External start convergence | discovery → queue → dispatcher → AppModel | Fixture "daemon" (lock + fake process entry) appears between polls | Model shows RUNNING within 2 poll cycles (TDD §7.1 convergence target; KR-01, AC-1/AC-4) |
| INT-2 | External stop convergence | discovery → model | Fixture process removed from table, lock left behind | Row becomes STALE_LOCK, never acted on as live (EC-1) |
| INT-3 | Start action pipeline | views dispatch → lifecycle worker → queue → model | Start on STOPPED project (mocked launcher exit 0), then poll observes pair | STARTING pin posted, then resolved to RUNNING (AC-2) |
| INT-4 | Stop action pipeline | lifecycle worker → drain → model | Stop on RUNNING fixture; fake log goes idle | DRAINING pin → terminate called on pair → poll confirms STOPPED (AC-3) |
| INT-5 | Shutdown orchestration | app shutdown → parallel lifecycle workers → model | 3 running fixtures: one quiesces fast, one at grace boundary, one never | Parallel drains; rows resolve STOPPED/STOPPED/FORCE_STOPPED; exit condition reached (AC-7) |
| INT-6 | Shutdown bound | app shutdown with fake clock | No daemon ever quiesces | Exit condition reached at grace period + margin — close can never hang (AC-9/BR-7) |
| INT-7 | Config save + running daemon | config_edit + model | Valid save while project's row is RUNNING | Restart-needed notice state produced (BR-9/AC-12); not shown when STOPPED |
| INT-8 | Worker error isolation | any worker → panel log → model | Worker raises unexpectedly | Exception caught, written to panel log, rendered as pane-local error; other rows/panes unaffected (TDD §3.3) |
| INT-9 | Duplicate-start race | lifecycle + discovery | Start requested while fixture daemon already present for the project | Launcher's idempotent path taken; exactly one RUNNING row, no second start (EC-2/AC-10) |
| INT-10 | Observability instrumentation (CR-13, CR-19) | Dispatcher queue depth is logged at DEBUG when non-empty (and *not* when idle, or the panel writes ten lines a second doing nothing); a poll past the §7.1 500 ms budget is raised to WARNING so a responsiveness problem is visible without re-running under `--debug`; an exception Tk raises inside its own callback is recorded with its traceback and the handler itself can never raise. Both rules live in module-level, Tk-free functions so they are assertable without a display (the Decision 11a precedent) | real `panel.log` logger, fake clock |
| UNIT-P1 | Installer and packaging (CR-17, CR-18, CR-20) | Smoke-test failure reasons render from whichever stream carries them — `control_panel.py` reports dependency problems on **stdout**, so rendering `stderr` alone printed an empty reason; the GitPython floor excludes the CVE-bearing releases; an apostrophe in the install path is doubled before interpolation into a single-quoted PowerShell literal. Lives in `test_panel_installer_packaging.py` (TE-TST-153) because the code is in `deployment/` and `pyproject.toml`, not the panel subpackage | fake CompletedProcess, real `pyproject.toml` |

### UI/Component Tests

> Headless: these drive view **state logic** (pure functions / model observers) without instantiating Tk widgets — per the TDD's display-free testability design. Widget rendering and focus order are validated at E2E acceptance against the keyboard navigation order in PD-UIX-003 §5.2.

#### UI Components

| ID | Component | Test Focus | User Interactions | Validations |
| -- | --------- | ---------- | ----------------- | ----------- |
| COMP-1 | Toolbar enablement | Enablement matrix per `DaemonStatus` | Selection changes, in-flight transitions | Start enabled only for STOPPED/STALE_LOCK; Stop only for RUNNING; both disabled during transitions and with no selection (BR-1, PD-UIX-003 §4.2) |
| COMP-2 | Status rendering | Status → glyph + label + token mapping | — | Every `DaemonStatus` maps to a glyph **and** text (never color-only); FORCE_STOPPED/START_FAILED/STALE_LOCK map to error/warning tokens (PD-UIX-003 §3.4) |
| COMP-3 | Validation pane state | One visible state at a time | Run triggered / completes / fails | idle → running → result/failure transitions mirror `ValidationRun.state`; result persists until next run or project switch |
| COMP-4 | Config notice line | Single-message rule | Edit / save-invalid / save-valid | Exactly one of dirty ⓘ / error ❌ / restart ⚠ / saved — never stacked (PD-UIX-003 §4.4) |
| COMP-5 | Shutdown dialog rows | Per-daemon terminal states + progress | Window close | Rows: Draining → Stopped/Force-stopped; "k of n stopped" counter correct; force-stopped rows persist until exit |
| COMP-6 | Unsaved-changes guard | Dirty editor intercepts navigation | Row/tab switch with dirty text | Guard signal raised (Save/Discard/Cancel path), no silent discard |
| COMP-7 | Log pane scroll-lock | Auto-scroll pause/resume logic | Scroll up / re-enable / Ctrl+End | Following pauses on scroll-up, resumes on re-enable — state machine only, no widget |
| COMP-8 | Empty state | No registered projects | — | Empty-state content selected, toolbar all-disabled (EC-8) |

#### State Management

| State Change | Trigger | Expected UI-Facing Update | Test Method |
| ------------ | ------- | ------------------------- | ----------- |
| RUNNING → DRAINING (pin) | Stop action | Row transitional, Stop disabled | Drive `AppModel` + enablement function (UNIT-M4, COMP-1) |
| Pin deadline expiry | Hung worker | Row reverts to poll truth | Fake clock advance (UNIT-M5) |
| `shutting_down = True` | Window close | All interactions disabled, dialog state active | Model flag + enablement functions (UNIT-M7, COMP-5) |
| Validation state transitions | Subprocess lifecycle | Pane swaps single visible state | `ValidationRun` state walk (COMP-3) |

## Edge-Case Coverage (EC-1…EC-11)

> The FDD's edge-case catalog is the hardening pass's checklist (TDD §6.2 step 7). Swept in Phase G (2026-08-10): every case traced to the test(s) that actually exercise it, and the two uncovered halves closed.

| EC | Behavior required (PD-FDD-034) | Covered by |
| -- | ------------------------------ | ---------- |
| EC-1 | Dead daemon still listed → detected on refresh, never acted on | UNIT-D2 (classification), INT-2 (row stops claiming a live daemon, no PIDs), COMP-1 (Stop disabled) |
| EC-2 | Duplicate-start race → no second daemon | UNIT-L2 (launcher idempotent path), INT-9 (start against a stale STOPPED row) |
| EC-3 | Stale lock, no process → reported not running | UNIT-D2, UNIT-L9 (termination guard refuses), COMP-2 (label reads "Stopped (stale lock)") |
| EC-4 | Drain timeout → force-terminate, surfaced | UNIT-L5 (grace bound with fake clock), COMP-5 (row keeps its error surfacing until exit) |
| EC-5 | Log missing / rotated → graceful | UNIT-T3 (reattach), UNIT-T5 (placeholder, never an exception) |
| EC-6 | Validation failure → surfaced, never reported as success | UNIT-V3 (spawn failure → `failed`), COMP-3 (failure is its own visible state, no report link) |
| EC-7 | Start failure → reason surfaced, list stays truthful | UNIT-L3 (captured reason) **+ EC-7 pipeline test** (the START_FAILED outcome pin decays and poll truth wins) |
| EC-8 | No registered projects → empty state, not an error | UNIT-D10 (empty snapshot set), UNIT-S5 (distinct from unresolved registry), **COMP-8** (calm wording, toolbar all-disabled, and a pending discovery is never rendered as "no projects") |
| EC-9 | Second panel instance → surface the existing window | UNIT-I1…I4 incl. the recycled-port guard (a foreign listener must not block the panel) |
| EC-10 | Missing / malformed config → surfaced, never overwritten | UNIT-C1 (read-error state, file never auto-written), **UNIT-C7** (non-UTF-8 file → read-error, not an escaping `UnicodeDecodeError`, and never decoded leniently) |
| EC-11 | Invalid config value → save blocked, explained | UNIT-C2 (line-numbered YAML error), UNIT-C3 (real `LinkWatcherConfig.validate()`), **UNIT-C8** (wrongly *typed* value, where the real loader raises instead of reporting an issue), all asserting the file on disk is untouched |

> **Coverage correction (Code Review 2026-08-17, findings CR-2 / CR-3).** The two
> rows above previously cited only UNIT-C1 and UNIT-C2/C3 and read as full
> coverage of EC-10 and EC-11, but neither edge case was covered at the point
> that mattered. UNIT-C1 exercised only `OSError`, so a **non-UTF-8** config
> raised `UnicodeDecodeError` (a `ValueError`) straight out of `read_config`'s
> documented "never raises" contract; UNIT-C3 exercised only well-typed-but-invalid
> values, so a **wrongly typed** value (`log_level: 5`) raised `AttributeError`
> out of the save pipeline with no blocked-save notice and no log entry. UNIT-C7,
> UNIT-C8, UNIT-S7 and UNIT-M8 close the gap; each was mutation-verified (break
> the fix, confirm that assertion — and only it — goes red). This is the second
> corrected over-claim in this table's history: TE-TAR-094 previously found CRLF
> normalization documented as tested with no test behind it (TD264, still open).

## Mock Requirements

### External Dependencies

| Dependency | Mock Type | Expected Behavior | Mock Data |
| ---------- | --------- | ----------------- | --------- |
| psutil process table | Fake (injectable seam) | Returns scripted process entries (pid, cmdline, create_time, parent/children); supports kill/terminate recording | Process tuples for: valid pair, recycled PID, wrong-root process, orphan |
| Launcher subprocess ([start_linkwatcher_background.ps1](../../../process-framework/tools/linkWatcher/start_linkwatcher_background.ps1)) | Mock | Scripted exit code + stdout/stderr; records invocation args | exit 0 (started / already running), exit 1 + stderr reason |
| `--validate` subprocess ([main.py](../../../main.py)) | Mock | Scripted exit code + output; records command line | exit 0; exit 1 + report file; spawn failure |
| Clock / time source | Fake | Injectable monotonic time advanced by tests | Drain timelines: idle-at-3s, active-past-20s |
| Log file stat source | Fake or tmp files | size + mtime sequences driving the drain heuristic | Silent log, chattering log, rotated log |
| Lock files / registry / config / logs | Real temp files (`temp_project_dir`-style fixtures) | Genuine filesystem behavior for atomic-replace and rotation tests | Fabricated lock contents, registry JSON, YAML configs |
| Loopback sockets | Real (ephemeral ports) | Genuine bind/connect/SURFACE exchange | — |
| Tk display | **Avoided** | No widget instantiation in automated tests | — |

### Internal Services

| Service | Mock Strategy | Key Methods | Return Values |
| ------- | ------------- | ----------- | ------------- |
| [`LinkWatcherConfig`](../../../src/linkwatcher/config) | **Never mocked** (TDD D-T6) | `from_file()`, `validate()` | Real validation results — the tests assert the panel reuses feature 0.1.3's rules |
| `AppModel` | Real instance, driven directly | `subscribe()`, snapshot/pin updates | Observed notifications |
| Panel log | Real temp file | WARN+ writes from workers | Asserted content for INT-8 (forced stops, failures recorded) |

## Test Implementation Roadmap

### Priority Order

1. **High Priority** (correctness core — KR-01/02/03; implement alongside TDD implementation steps 2–4)

   - [x] Discovery classification matrix + three-way identity (UNIT-D1…D10) — TE-TST-142, Phase B
   - [x] Termination guard + lock cleanup (UNIT-L8…L11) — TE-TST-146, Phase C
   - [x] Drain state machine with fake clock (UNIT-L4…L7) — TE-TST-146, Phase C
   - [x] Model reconciliation, pins, pin expiry (UNIT-M1…M7) — TE-TST-143, Phase B
   - [x] Convergence + stop/shutdown pipelines (INT-1, INT-2, INT-4, INT-5, INT-6) — INT-1/INT-2 Phase B, INT-4 Phase C, INT-5/INT-6 Phase D (TE-TST-144)

2. **Medium Priority** (safety of persisted state + remaining flows; TDD implementation steps 3–6)

   - [x] Config save pipeline incl. atomic/interrupted save (UNIT-C1…C6, INT-7) — TE-TST-150/144, Phase E
   - [x] Start flow + duplicate-start race (UNIT-L1…L3, INT-3, INT-9) — TE-TST-146/144, Phase C
   - [x] Validation runner (UNIT-V1…V5) — TE-TST-149, Phase E
   - [x] Settings + registry resolution (UNIT-S1…S5) — TE-TST-141, Phase A
   - [x] Single instance (UNIT-I1…I4) — TE-TST-151, Phase F
   - [x] Worker error isolation (INT-8) — TE-TST-144, Phase G

3. **Low Priority** (view logic + polish; TDD implementation step 7 hardening pass)
   - [x] Log tail unit tests (UNIT-T1…T5) — TE-TST-148, Phase E
   - [x] Component/state-logic tests (COMP-1…COMP-8) — TE-TST-147; COMP-1 (Phase C), COMP-5 (Phase D), COMP-3/4/6/7 (Phase E), COMP-2/COMP-8 (Phase G) — each created when its rule became live code

> **Supplemental scenarios beyond the tables above** (implemented in TE-TST-146/147/144, Phases C–D): launcher timeout bounded and surfaced; missing launcher script fails without spawning; corrupt/missing lock is a calm cleanup no-op; controller one-action-per-project busy guard; enablement matrix + shutdown-row-display totality over `DaemonStatus`; shutdown watchdog forces completion on a hung worker; zero-target close completes immediately without shutdown mode; an in-flight stop is adopted by shutdown, never double-drained. **Phase E additions** (TE-TST-148/149/150): per-tick read cap absorbs a log burst over several ticks; a newer log sibling takes over when the current file goes quiet; validation spawn failure surfaces as `failed`; validation timeout bounded; an empty/comments-only config saves cleanly ("empty means defaults" contract); create-default never overwrites and builds parent directories.
>
> **Correction (2026-08-14, Test Audit TE-TAR-094)**: CRLF normalization — including a `\r\n` pair split across two reads — was previously listed among the Phase E additions above but is **not covered by any test**. `test_panel_log_tail.py` contains no carriage return, and `log_tail.py`'s held-back-`\r` branches never execute. The behavior exists in the code; only the test claim was wrong. Tracked as **TD264** and routed to Code Refactoring (PF-TSK-022).

> **Performance tests** (large-log tail timing, poll-cycle duration — TDD §7.1) are **not** specified here: per-feature performance test needs are decided by Performance & E2E Test Scoping (PF-TSK-086) after code review.

### Test File Structure

Test files are created via `New-TestFile.ps1` (TE-TST IDs assigned at creation) in the already-scaffolded feature directory [test/automated/unit/7-operations-control/7-1-control-panel](../../automated/unit/7-operations-control/7-1-control-panel):

```
test/automated/unit/7-operations-control/7-1-control-panel/
├── test_panel_model.py            # UNIT-M1…M7
├── test_panel_settings.py         # UNIT-S1…S5
├── test_panel_discovery.py        # UNIT-D1…D10
├── test_panel_lifecycle.py        # UNIT-L1…L11
├── test_panel_log_tail.py         # UNIT-T1…T5
├── test_panel_validation.py       # UNIT-V1…V5
├── test_panel_config_edit.py      # UNIT-C1…C6
├── test_panel_single_instance.py  # UNIT-I1…I4
├── test_panel_integration.py      # INT-1…INT-9
└── test_panel_views.py            # COMP-1…COMP-8
```

Shared fixtures (fake process table, fake clock, lock/registry builders) belong in a `conftest.py` local to this directory; general fixtures (`temp_project_dir`, file creators) come from [test/automated/conftest.py](../../automated/conftest.py).

### Dependencies Between Tests

- The **fake process table** fixture must exist before UNIT-D*, UNIT-L8…L11, and all INT-* tests — it is the foundation seam.
- The **fake clock + log stat source** fixtures must exist before UNIT-L4…L7 and INT-5/INT-6.
- UNIT-M* (model semantics) should pass before INT-* — the integration assertions read model state and assume its notification contract.
- UNIT-C1…C5 require feature 0.1.3's real `LinkWatcherConfig` (already implemented — no blocker).
- COMP-* tests depend on view state logic being factored into display-free functions (a design obligation the TDD's §4.2 "render from model only" rule already imposes on implementation).

## Related Resources

- **Source TDD**: [PD-TDD-033](../../../doc/technical/architecture/design-docs/tdd/tdd-7-1-1-linkwatcher-control-panel-t2.md)
- **FDD**: [PD-FDD-034](../../../doc/functional-design/fdds/fdd-7-1-1-linkwatcher-control-panel.md)
- **UI Design**: [PD-UIX-003](../../../doc/technical/design/ui-ux/features/ui-design-7-1-1-linkwatcher-control-panel.md)
- **Feature Tier Assessment**: [PD-ASS-201](../../../doc/documentation-tiers/assessments/PD-ASS-201-7.1.1-linkwatcher-control-panel.md)
- **Development Guide**: [process-framework/guides/04-implementation/development-guide.md](../../../process-framework/guides/04-implementation/development-guide.md)
- **Test Infrastructure Guide**: [process-framework/guides/03-testing/test-infrastructure-guide.md](../../../process-framework/guides/03-testing/test-infrastructure-guide.md)
- **Shared Fixtures**: [test/automated/conftest.py](../../automated/conftest.py)
