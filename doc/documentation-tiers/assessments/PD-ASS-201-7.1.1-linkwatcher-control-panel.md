---
id: PD-ASS-201
type: Document
category: General
version: 1.0
created: 2026-06-29
updated: 2026-06-29
description: "Documentation tier assessment for LinkWatcher Control Panel (7.1.1)"
feature_id: 7.1.1
---

# Documentation Tier Assessment: LinkWatcher Control Panel

## Feature Description

Desktop/tray control panel for operating running LinkWatcher daemon instances: list/start/stop daemons, auto-close a daemon when its owning VS Code window exits, view logs, and trigger link validation. A new GUI shell over existing CLI/process/log surfaces.

## Complexity Assessment

| Factor                | Weight | Score | Weighted Score   | Justification                    |
| --------------------- | ------ | ----- | ---------------- | -------------------------------- |
| **Scope**             | 0.8    | 3     | 2.4              | Several components: GUI/tray shell, daemon-process manager, owner-VS-Code-PID watcher, log viewer, validation trigger (4+) |
| **State Management**  | 1.2    | 2     | 2.4              | Moderate shared state — UI mirrors external daemon/process state, owner-PID registry, polling timers, log-tail position |
| **Data Flow**         | 1.5    | 2     | 3.0              | Moderate — enumerate/parse process command lines, tail log files, spawn/kill processes, invoke `--validate` subprocess |
| **Business Logic**    | 2.5    | 2     | 5.0              | Moderate rules with edge cases — owner-PID liveness, sibling detection, grace-delay drain, auto-close decision, force-kill/stale-lock handling |
| **UI Complexity**     | 0.5    | 2     | 1.0              | Custom widgets (tray menu, daemon list, log pane) but no complex interactive visualizations |
| **API Integration**   | 1.5    | 2     | 3.0              | Multiple integrations — OS process APIs, the LinkWatcher CLI (`main.py`/start scripts), log files; no external services |
| **Database Changes**  | 1.2    | 1     | 1.2              | None — no schema; minimal local state via marker files at most |
| **Security Concerns** | 2.0    | 1     | 2.0              | Standard — local, single-user, no network or secrets (terminating the wrong process is a correctness, not security, concern) |
| **New Technologies**  | 1.0    | 2     | 2.0              | A GUI/tray toolkit (e.g. pystray / PySide / Tkinter) is new to this CLI-only project |

**Sum of Weighted Scores**: 22.0
**Sum of Weights**: 12.2
**Normalized Score**: 22.0 / 12.2 = **1.80**

## Design Requirements Evaluation

### UI Design Required

- [x] Yes - Entirely new GUI surface (the project's first): tray/window shell, daemon-list view, log viewer, navigation. Components fall outside any existing design system because none exists yet.

### API Design Required

- [x] No - The MVP wraps existing surfaces (the `main.py` CLI incl. `--validate`, the start scripts, OS process enumeration/termination, and the daemon log file); it introduces no new endpoints or contracts. **Caveat:** if the optional graceful **stop-sentinel** mechanism is adopted (a UI↔daemon control contract via a sentinel file the daemon polls), that introduces a Service-Interface contract that would flip this to **Yes** — a decision deferred to the design phase.

### Database Design Required

- [x] No - No tables/schema. Any persisted state (e.g. owner-PID markers) is small flat files, not a database.

## Documentation Tier Assignment

**Assigned Tier**:

- [ ] Tier 1 (Simple) 🔵 (1.0-1.6)
- [x] Tier 2 (Moderate) 🟠 (1.61-2.3)
- [ ] Tier 3 (Complex) 🔴 (2.31-3.0)

## Rationale

Normalized score 1.80 lands squarely in Tier 2. The feature is a genuine new application with moderate lifecycle logic (the auto-close/sibling/drain rules are the substance) and a new GUI technology, but it has no database, no heavy security surface, and no complex external orchestration — it sits on top of existing, already-built CLI/process/log surfaces rather than adding backend complexity. The dominant weighted factor (Business Logic, weight 2.5) is Moderate, which anchors the score in Tier 2 rather than Tier 3. Tier 2 holds under sensitivity checks (Scope→2 gives 1.74; Business Logic→3 gives 2.0 — both still Tier 2).

## Special Considerations

- **First GUI surface in a CLI-only project** — introduces a UI toolkit and the app-shell pattern; mild new-technology risk.
- **Process-management correctness** — the app starts and terminates OS processes; killing the wrong daemon is the main risk to design carefully (mitigated by per-project lock/PID identification).
- **Auto-close design choice is load-bearing** — the grace-delay approach needs no backend change; the stop-sentinel alternative would add a UI↔daemon contract (see API caveat). Decide in the design phase.
- **No backend product change for the MVP** — depends on existing features 0.1.1 (Core Architecture / CLI + lock), 3.1.1 (Logging & Monitoring / log files), 6.1.1 (Link Validation / `--validate`).

## Implementation Notes

- Surfaces consumed: `main.py --validate` (separate short-lived process, no lock contention), the `start_linkwatcher_background.ps1` launcher, OS process enumeration (`Get-CimInstance Win32_Process` / equivalent), and the per-project `logs/linkwatcher/LinkWatcherLog.txt`.
- The daemon is a venv-shim parent → child pair per project; manage at the parent PID.
- Auto-close anchors on the owning VS Code window PID (all Claude tabs in one window share it); "sibling" check is owner-PID liveness, not a counter.

## Design Context Carried Forward (for the FDD / design phase)

Recorded here because the originating evaluation discussion is **not** a declared input to FDD Creation; this is the durable carrier of the load-bearing decisions made during evaluation.

- **Functional decomposition (shell + views).** Four areas: (1) daemon session management (list/start/stop across projects), (2) log viewing, (3) validation triggering, (4) auto-close on VS Code exit. The Control Panel is the app **shell**; (2) and (3) are *views that consume* existing features 3.1.1 (Logging & Monitoring) and 6.1.1 (Link Validation) — cross-reference their backends, do not re-document them.
- **Auto-close anchor + shared-singleton constraint.** The daemon is a per-project singleton reused by every VS Code window and Claude tab on that project. Auto-close must anchor on the owning VS Code **window** PID and must NOT terminate a daemon while any other window/session still needs it. Per-Claude-session `SessionEnd` hooks were **rejected** for exactly this reason. Cross-project is already safe (different projects → independent daemons).
- **No "VS Code closed" event exists.** VS Code is not the launcher (a Claude hook is) and fires no catchable shutdown signal, so auto-close requires a persistent **polling supervisor** — the functional motivation for a long-running manager/tray app rather than a hook.
- **Graceful drain vs. data safety.** Atomic writes (temp + rename) mean any stop, even a hard kill, never corrupts a file; the only risk is *dropped* in-flight move-correlations buffered within `move_detect_delay` (~10s; up to 300s for directory batches). MVP approach: a log-idle grace delay before terminating. A true graceful stop would need the optional **stop-sentinel** (see the API-design caveat above).
- **Workflow mapping.** Participates in WF-010 (manage running instances via Control Panel) and is an alternative trigger for WF-009 (link health audit).
