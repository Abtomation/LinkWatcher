---
id: PD-FDD-034
type: Process Framework
category: Functional Design Document
version: 1.0
created: 2026-06-29
updated: 2026-06-29
description: "Functional Design Document for LinkWatcher Control Panel (7.1.1)"
feature_id: 7.1.1
feature_name: LinkWatcher Control Panel
---

# LinkWatcher Control Panel - Functional Design Document

## Feature Overview

- **Feature ID**: 7.1.1
- **Feature Name**: LinkWatcher Control Panel
- **Business Value**: LinkWatcher daemons run silently in the background, one per project, started automatically by a Claude `SessionStart` hook. Today an operator running LinkWatcher across several projects has no unified way to see what is running, stop a daemon, read its log, edit its configuration, or run a validation scan — they must inspect OS process lists and open log/config files by hand. The Control Panel gives a single desktop window to see and control all running daemons across every registered project, view their logs, view and edit each project's configuration, trigger link validation, and cleanly shut everything down when finished. The window also surfaces itself automatically whenever a daemon is auto-started by the hook, so the operator always has a visible handle on what LinkWatcher is doing.
- **User Story**: As a developer running LinkWatcher across multiple projects, I want one window that shows every running daemon and lets me start, stop, monitor, and validate them, so that I can manage link maintenance without hunting through process lists and log files.

## Related Documentation

> **Note**: This section provides cross-references to related technical documentation. FDDs focus on **functional-level concerns** (what the system does from a user perspective), while technical details are documented in specialized tasks.

> **Source context**: The load-bearing decisions made during evaluation are recorded in the tier assessment [PD-ASS-201](../../documentation-tiers/assessments/PD-ASS-201-7.1.1-linkwatcher-control-panel.md) (see its "Design Context Carried Forward" section). This FDD designs to the **revised lifecycle model** agreed during FDD creation (panel-close drives shutdown), which supersedes the VS-Code-exit auto-close model described in that assessment — see [Notes](#notes).

### API Specification Reference

> **📋 Primary Documentation**: API Design Task (PF-TSK-020) — **not invoked for the MVP**
> **👤 Owner**: API Design Task (if later required)

Per [PD-ASS-201](../../documentation-tiers/assessments/PD-ASS-201-7.1.1-linkwatcher-control-panel.md), the MVP introduces **no new API contract**. The panel wraps already-existing surfaces: the `main.py` CLI (including `--validate`), the start launcher, OS process enumeration/termination, and the per-project log file.

**Functional API Requirements**:

- No user-facing API endpoints are introduced; users interact only through the desktop window.
- **Caveat carried from the assessment**: if a graceful **stop-sentinel** control contract (a sentinel file the daemon polls) is later adopted instead of the bounded-drain approach, that introduces a UI↔daemon Service-Interface contract and would require API Design. It is **deferred / out of scope for the MVP**.

### Database Schema Reference

> **📋 Primary Documentation**: Database Schema Design Task (PF-TSK-021) — **not applicable**
> **👤 Owner**: N/A

**Functional Data Requirements**:

- No database and no schema. The panel reads transient state (running processes, lock/PID files, log files) and the existing registered-projects list; it persists no relational data of its own.

### Technical Design Reference

> **📋 Primary Documentation**: TDD Creation Task (PF-TSK-022) — **pending** (next design step)
> **🔗 Link**: [Technical Design Document - PD-TDD-XXX] (to be created)
> **👤 Owner**: TDD Creation Task

**Functional Technical Requirements**:

- The daemon list and log view must reflect actual running state with low latency, so the user trusts the panel as the source of truth for "what is running".
- Panel-initiated shutdown must complete in bounded time (the window must never hang on close) while still allowing in-flight updates to finish.
- A GUI/window toolkit (new to this CLI-only project) and the OS process-management approach are owned by the TDD / UI Design.

### Test Specification Reference

> **📋 Primary Documentation**: Test Specification Creation Task (PF-TSK-012) — **pending**
> **👤 Owner**: Test Specification Creation Task

**Functional Testing Requirements**:

- All acceptance criteria below must be validated, with particular emphasis on the drain-then-terminate shutdown behavior and on never acting on the wrong process.
- The shared-singleton and stale-process edge cases require explicit functional testing.

## Functional Requirements

### Core Functionality

- **7-1-1-FR-1**: The panel displays a list of all currently running LinkWatcher daemons across all registered projects, one row per project, showing project identity (name/path), running status, and basic liveness information (e.g. uptime).
- **7-1-1-FR-2**: The panel lets the user start a LinkWatcher daemon for a registered project that currently has none running.
- **7-1-1-FR-3**: The panel lets the user stop an individual running daemon on demand.
- **7-1-1-FR-4**: The panel keeps its displayed state in sync with the actual running state, automatically reflecting daemons that started or stopped outside the panel (e.g. a daemon auto-started by the `SessionStart` hook, or one that exited on its own).
- **7-1-1-FR-5**: The panel lets the user view the live log of a selected daemon (the project's `logs/linkwatcher/LinkWatcherLog.txt`), updating as new entries are written. *(Consumes Logging & Monitoring, feature 3.1.1 — not re-documented here.)*
- **7-1-1-FR-6**: The panel lets the user trigger an on-demand link-validation scan for a selected project and surfaces its outcome (broken-link count and report location). *(Consumes Link Validation, feature 6.1.1 — not re-documented here.)*
- **7-1-1-FR-7**: When the panel is closed, it initiates a graceful shutdown of every daemon it manages: each daemon is allowed to finish its in-flight updates before being terminated, after which the application exits.
- **7-1-1-FR-8**: When a LinkWatcher daemon is auto-started by the `SessionStart` hook, the Control Panel window opens automatically (or, if a window is already open, that window is surfaced/focused rather than a second one being created).
- **7-1-1-FR-9**: The panel lets the user view and edit the LinkWatcher configuration of a selected project, and persist the changes back to that project's configuration. *(Consumes Configuration, feature 0.1.3 — not re-documented here.)*

### User Interactions

- **7-1-1-UI-1**: The user opens the panel as a desktop **window** that lists the running daemons; selecting a daemon row exposes its available actions (stop, view log, validate).
- **7-1-1-UI-2**: **Start** — the user selects a registered project that is not currently running and starts its daemon; the new daemon appears in the list once it is running.
- **7-1-1-UI-3**: **Stop** — the user stops a selected daemon; the row shows a transitional "stopping / draining" state and then reflects "stopped" (or is removed) once the process has terminated.
- **7-1-1-UI-4**: **View log** — the user opens a log pane for the selected daemon showing recent log lines and updating live as the daemon writes new entries.
- **7-1-1-UI-5**: **Validate** — the user triggers a validation scan for a selected project; the panel shows that validation is running and then reports the result (broken-link count + report path).
- **7-1-1-UI-6**: **Close** — when the user closes the window, the panel shows a visible "shutting down / draining" indicator for the affected daemons and only exits once shutdown has completed (subject to the bounded grace period in 7-1-1-BR-7).
- **7-1-1-UI-7**: **Auto-open** — when a daemon is started by the `SessionStart` hook, the panel window appears automatically (newly launched, or the existing single window is brought to the foreground), so the operator gets an immediate visible handle on the just-started daemon without launching the panel manually.
- **7-1-1-UI-8**: **View / edit configuration** — the user opens a configuration view for a selected project, sees the project's current LinkWatcher settings, edits values, and saves; the panel confirms the save and indicates whether the running daemon must be restarted for the change to take effect.

### Business Rules

- **7-1-1-BR-1**: A project has **at most one** LinkWatcher daemon at any time (per-project singleton). The panel must not start a second daemon for a project that already has one running.
- **7-1-1-BR-2**: Daemon identity is resolved per project (via the project's lock/PID), so the panel always acts on the correct daemon and never starts, stops, or terminates an unrelated process.
- **7-1-1-BR-3**: Stopping a daemon — individually (7-1-1-FR-3) or via panel close (7-1-1-FR-7) — must **drain in-flight work first**: the daemon is allowed to finish buffered move-correlations and pending reference updates, and the panel waits for a quiescence signal (the daemon being idle, with no in-flight updates) before terminating it.
- **7-1-1-BR-4**: Closing the panel terminates **all** running daemons it manages, including daemons it did not itself start (e.g. hook-started ones). Stopping link maintenance this way is accepted behavior; the next Claude session's `SessionStart` hook will restart the relevant daemon.
- **7-1-1-BR-5**: The panel does **not** own automatic daemon start-up. The existing `SessionStart` hook remains the automatic start path; the panel provides manual start/stop plus shutdown-on-close, and coexists with hook-started daemons.
- **7-1-1-BR-6**: A validation scan runs as a separate, short-lived operation that does not require stopping, and does not interfere with, a running daemon for the same project.
- **7-1-1-BR-7**: Drain-before-terminate is bounded: if a daemon does not reach quiescence within a defined grace period, the panel escalates to a forced termination so that closing the panel can never hang indefinitely. Because daemon file writes are atomic (temp-file + rename), even a forced termination cannot leave a file partially written or corrupted — the only loss is any not-yet-applied in-flight update.
- **7-1-1-BR-8**: A hook-triggered daemon start opens the Control Panel window. Combined with single-instance behavior (7-1-1-EC-9), repeated hook-triggered starts across sessions surface/focus the one existing window rather than opening duplicate windows.
- **7-1-1-BR-9**: Saved configuration changes are persisted to the selected project's LinkWatcher configuration. Configuration is applied per LinkWatcher's existing config-load behavior; where a change cannot take effect on a live daemon, the panel makes the need to restart that daemon explicit rather than silently leaving the running daemon on stale settings. Invalid configuration is not saved (7-1-1-EC-11).

## User Experience Flow

1. **Entry Point**: The panel opens either way — the user launches it manually, **or** it opens automatically when the `SessionStart` hook starts a daemon (7-1-1-FR-8). If a window is already open, the auto-open surfaces/focuses it rather than creating a second.
2. **Main Flow**:
   - On open, the panel enumerates running LinkWatcher daemons across all registered projects and shows one row per project with its status (running / not running) and liveness info.
   - The user selects a daemon row to reveal its actions.
   - The user can **view the log** of the selected daemon, **stop** it, **view/edit its configuration**, or **trigger validation** for its project.
   - For a registered project with no running daemon, the user can **start** one; it appears in the list once running.
   - The list stays current as daemons start or stop outside the panel (hook auto-start, external exit).
3. **Decision Points**:
   - Per daemon: start vs. stop vs. view log vs. view/edit config vs. validate.
   - On window close: drain-then-terminate all managed daemons.
4. **Alternative Paths**:
   - A daemon auto-started by the `SessionStart` hook appears automatically (and brings the window forward) and can be stopped from the panel like any other.
   - A project with no daemon offers a Start action rather than stop/log/validate-on-running.
   - Validation can be run while the project's daemon is running (no stop required).
   - Configuration can be viewed/edited for a project regardless of whether its daemon is currently running.
5. **Exit Points**: The user closes the window → the panel drains and then terminates every managed daemon (forcing termination after the grace period if needed) → the application exits.

## Workflow Participation

| Workflow | Role in Workflow |
|----------|-----------------|
| [WF-010](../../state-tracking/permanent/user-workflow-tracking.md) — Manage running LinkWatcher instances via Control Panel | **Primary / sole feature.** This feature *is* the workflow: it provides the entire UI surface for viewing, starting, stopping, and monitoring running daemons across projects, and for the drain-and-terminate-on-close lifecycle. |
| [WF-009](../../state-tracking/permanent/user-workflow-tracking.md) — Link health audit → broken link report | **Alternative trigger.** Provides a GUI entry point to run a link-validation scan (feature 6.1.1) and view the broken-link report, complementing the existing `python main.py --validate` command-line trigger. |

> **Tracking note**: WF-010's detail text in [user-workflow-tracking.md](../../state-tracking/permanent/user-workflow-tracking.md) still describes the *VS-Code-exit auto-close* model. Under the revised lifecycle agreed for this FDD (panel-close drives drain-and-terminate), that wording is stale and should be updated — see [Notes](#notes).

## Acceptance Criteria

- [ ] **7-1-1-AC-1**: Given LinkWatcher daemons running for two or more registered projects, when the panel opens, then it lists exactly those running daemons with correct project identity and running status.
- [ ] **7-1-1-AC-2**: Given a registered project with no running daemon, when the user starts it from the panel, then a daemon for that project starts and appears in the list as running.
- [ ] **7-1-1-AC-3**: Given a running daemon, when the user stops it from the panel, then the daemon finishes its in-flight updates and terminates, and the row reflects the stopped state.
- [ ] **7-1-1-AC-4**: Given a daemon started by the `SessionStart` hook (not by the panel), when the panel is open, then that daemon appears in the list and can be stopped from the panel.
- [ ] **7-1-1-AC-5**: Given a selected running daemon, when the user opens its log, then the panel shows recent log entries and updates the view as the daemon writes new entries.
- [ ] **7-1-1-AC-6**: Given a selected project, when the user triggers validation, then a validation scan runs and the panel reports the broken-link count and the report path, without stopping the project's running daemon.
- [ ] **7-1-1-AC-7**: Given multiple running daemons, when the user closes the panel, then every managed daemon is drained and terminated and the application exits.
- [ ] **7-1-1-AC-8**: Given a file-reference update in progress when the panel is closed, when shutdown runs, then that in-progress update completes (no partial or corrupted file) before the daemon is terminated.
- [ ] **7-1-1-AC-9**: Given a daemon that does not reach quiescence within the grace period, when the panel is closing, then the panel force-terminates that daemon, the application still exits without hanging, and no file is left corrupted.
- [ ] **7-1-1-AC-10**: Given a project that already has a running daemon, when a start is attempted (including a race with the hook), then no second daemon is created for that project.
- [ ] **7-1-1-AC-11**: Given the `SessionStart` hook starts a daemon, when the daemon starts, then the Control Panel window opens automatically; and if a panel window is already open, that existing window is surfaced rather than a second window being created.
- [ ] **7-1-1-AC-12**: Given a selected project, when the user opens its configuration, changes a value, and saves, then the change is persisted to that project's LinkWatcher configuration and the panel indicates whether the running daemon must be restarted to apply it.

## Edge Cases & Error Handling

- **7-1-1-EC-1**: **Dead daemon still listed** — a daemon shown in the panel has already exited (crashed or killed externally). The panel detects the stale entry on its next state refresh and marks/removes it rather than attempting to act on a dead process.
- **7-1-1-EC-2**: **Duplicate-start race** — a start is requested for a project whose daemon the hook is concurrently starting. The panel detects the existing/instantiating daemon and does not create a duplicate (7-1-1-BR-1).
- **7-1-1-EC-3**: **Stale lock, no process** — a project has a lock/PID file but no live process. The panel reports the project as not running (optionally offering cleanup) and does not treat the stale lock as a live daemon.
- **7-1-1-EC-4**: **Drain timeout** — a daemon does not quiesce within the grace period during stop/close. The panel force-terminates it and surfaces that a forced stop occurred (7-1-1-BR-7).
- **7-1-1-EC-5**: **Log unavailable / rotated** — the selected daemon's log file is missing or was rotated while being viewed. The panel handles this gracefully (shows an empty/“no log” state or reattaches to the current log) rather than erroring.
- **7-1-1-EC-6**: **Validation failure** — validation is invoked for a project whose path/files are inaccessible, or the scan errors. The panel surfaces the failure and outcome instead of silently reporting success.
- **7-1-1-EC-7**: **Start failure** — a daemon fails to start (e.g. launcher/interpreter error). The panel surfaces the failure with a reason, and the list continues to reflect the true state (project remains "not running").
- **7-1-1-EC-8**: **No registered projects** — the registered-projects list is empty. The panel shows an empty state, not an error.
- **7-1-1-EC-9**: **Second panel instance** — the panel is launched (manually or by a hook auto-open) while one is already open. The panel avoids two instances issuing conflicting start/stop/close actions on the same daemons by surfacing the existing single window instead of opening a second; the exact mechanism is a design decision for the TDD.
- **7-1-1-EC-10**: **Missing / malformed config** — the selected project's configuration file is absent or unparseable. The panel surfaces this clearly (e.g. shows effective defaults or a read error) rather than crashing, and does not overwrite the file with partial/garbage content.
- **7-1-1-EC-11**: **Invalid config value** — the user edits a configuration value to something invalid. The panel validates on save, blocks the save, and explains what is wrong instead of persisting an invalid configuration.

## Dependencies

### Functional Dependencies

- **Feature 0.1.1 (Core Architecture — CLI entry point + per-project lock/PID)** — provides daemon identity and the start path the panel drives.
- **Feature 3.1.1 (Logging & Monitoring)** — provides the per-project log files the panel tails (7-1-1-FR-5).
- **Feature 6.1.1 (Link Validation)** — provides the `--validate` scan the panel triggers (7-1-1-FR-6).
- **Feature 0.1.3 (Configuration)** — provides the per-project configuration the panel views and edits (7-1-1-FR-9).
- **Registered-projects list** — the panel needs to know which projects exist in order to list and start their daemons.
- The existing **`SessionStart` hook auto-start path** remains in place; the panel coexists with it (7-1-1-BR-5).

### Technical Dependencies

> Reference only — owned by the TDD / UI Design, not specified here.

- OS process enumeration and termination facilities (to detect and stop daemons by per-project identity).
- A GUI/window toolkit (new to this project).
- The existing background-start launcher script.

## Success Metrics

- An operator can identify and control every running LinkWatcher daemon across projects from one window, without resorting to OS process tools or manually opening log files.
- Panel-initiated shutdown produces **zero corrupted files** (the atomic-write guarantee holds under both graceful and forced termination).
- Starting, stopping, viewing logs, and running validation are all achievable from the panel without using the command line.

## Validation Checklist

- [x] All functional requirements clearly defined with Feature ID prefixes
- [x] User interactions documented with specific UI behaviors
- [x] Business rules specified with validation logic
- [x] Acceptance criteria are testable and measurable
- [x] Edge cases identified with expected behaviors
- [x] Dependencies mapped (both functional and technical)
- [x] Success metrics defined for measuring feature effectiveness
- [x] User experience flow covers all major paths and decision points

## Notes

- **Lifecycle model revised during FDD creation.** The tier assessment (PD-ASS-201) carried forward an *auto-close-on-VS-Code-exit* model (anchored on the owning VS Code window PID, with a polling supervisor watching for that window's exit). During FDD creation this was **replaced** with a simpler **panel-owned shutdown** model: closing the Control Panel drains and terminates all managed daemons. This removes the VS-Code-PID watcher and the "no VS-Code-closed-event" supervisor rationale from the design. The assessment's "Design Context Carried Forward" notes on those points are therefore superseded by this FDD. **Follow-up**: WF-010's detail text in user-workflow-tracking.md still references the VS-Code auto-close model and should be corrected (flagged in [Workflow Participation](#workflow-participation)).
- **Startup ownership.** The panel deliberately does **not** replace the `SessionStart` hook as the automatic start mechanism; it adds manual control and shutdown-on-close on top (7-1-1-BR-5). The hook additionally triggers the panel window to auto-open (7-1-1-FR-8 / 7-1-1-BR-8), so a hook-started daemon is always paired with a visible panel. This makes the window the operator's standing handle on LinkWatcher activity — and, given close-terminates-all (7-1-1-BR-4), means closing that auto-opened window is also the deliberate way to stop the session's daemons.
- **Stop-sentinel deferred.** A true cooperative graceful-stop contract (a sentinel file the daemon polls) is out of scope for the MVP; the MVP uses bounded drain-then-force-terminate (7-1-1-BR-7). Adopting the sentinel later would introduce an API contract (see API Specification Reference).
- **UI Design required next.** PD-ASS-201 flagged UI Design as required (this is the project's first GUI surface). The window layout, daemon-list presentation, and log/validation panes are owned by the UI Design task, not this FDD.

---

_This Functional Design Document should be reviewed and approved before technical design begins._
