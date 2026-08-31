---
id: PD-UGD-010
type: Product Documentation
category: User Guide
version: 1.2
created: 2026-08-18
updated: 2026-08-28
description: "Complete reference for the LinkWatcher Control Panel: command-line options, panel-config.yaml keys, registry resolution, status values, keyboard shortcuts, and file locations"
handbook_content_type: reference
handbook_name: Control Panel Reference
---

# Control Panel Reference

Lookup reference for the LinkWatcher Control Panel. For how to perform operations, see [Control Panel Operations](../how-to/control-panel-operations.md).

## Launchers

Installed into the install directory (default `~/bin`) by `deployment/install_global.py`.

| Launcher | Notes |
|---|---|
| `linkwatcher-panel.bat` | Command Prompt wrapper |
| `linkwatcher-panel.ps1` | PowerShell wrapper |
| `control_panel.py` | The entry script both wrappers call, beside `main.py` |

Both wrappers use the install directory's dedicated venv interpreter and pass every argument straight through. They use the console interpreter, so a terminal launch can display the "already running" message.

## Command-line options

| Option | Value | Purpose |
|---|---|---|
| `--registry` | Path | Path to a child registry file — `project-registry.json` or `framework-registry.json`. Highest-precedence registry source. |
| `--project-root` | Directory | A workspace root; the panel supervises from the child registry that workspace owns, or — for a leaf project — from the one its parent owns, found via the parent-pointer in its framework face. Omitting it falls back to the current directory, so a launch from the workspace root needs no argument. |
| `--debug` | flag | Verbose (DEBUG) panel logging. |

## Registry resolution order

The panel resolves the registry through this chain, highest precedence first. The first source that yields a path wins.

| # | Source | Existence check |
|---|---|---|
| 1 | `--registry` argument | Taken as given |
| 2 | `LINKWATCHER_PROJECT_REGISTRY` environment variable | Taken as given |
| 3 | `project_registry` key in `panel-config.yaml` | Taken as given |
| 4 | The child registry the workspace root owns, in its own `process-framework-central/` — the root named by `--project-root`, or the current directory when no `--project-root` is given | Must exist on disk to count |
| 5 | Parent-pointer discovery — from `--project-root` first, then by walking up from the current directory | Must exist on disk to count |
| 6 | Unresolved | The panel still opens, showing a registry-error banner and starting no polling |

Sources 1–3 are used as supplied, so a configured-but-missing path surfaces later as an informative error rather than being silently skipped. Sources 4–5 are best-effort auto-locates and only count when the derived registry file actually exists.

**Which of the two auto-locates answers depends on the workspace.** A workspace that has children keeps their registry in its own `process-framework-central/` — named `project-registry.json` (listing `projects`) at a framework, or `framework-registry.json` (listing `frameworks`) at a framework-builder. Both are recognized. A leaf project owns no such registry, so it resolves through the parent-pointer in its framework face — `.framework-parent-pointer`, or the legacy `.framework-central-pointer` — to the registry its parent owns.

Two limits worth knowing:

- **Source 4 takes the current directory exactly, and never walks up.** The session hook passes its own `--project-root`; the `linkwatcher-panel` launchers forward your arguments and add none, so a launch from a workspace root is answered by the current directory instead. Walking *up* is deliberately not done: a producer's blueprint/template tree carries an empty seed registry, and adopting one from a parent directory would show "no registered projects" while daemons were in fact running elsewhere. Two consequences follow — a launch from a **deep subdirectory** of a non-leaf workspace falls through to source 5 and lists its *parent's* registry, and a launch from a **blueprint tree root** does reach that tree's empty seed registry. `panel.log` records which registry answered (`registry resolved via workspace: …`, or `via pointer: …`), which is how you tell them apart.
- **The framework face is read, not assumed.** The panel takes `paths.process_framework` from the workspace's `doc/project-config.json`, falling back to `process-framework/`, so a workspace whose face lives elsewhere (for example under `blueprint/`) resolves correctly — for both the pointer above and the launcher script that Start invokes.

Only the two filenames above are recognized. A workspace whose `process-framework-central/` holds some *other* registry falls through to source 5 and is supervised from its parent's list — a wrong answer that otherwise looks like a right one — so that case is logged as `central_registry_unrecognized` in `panel.log`, naming the directory and the filenames that were looked for.

## Panel settings (`panel-config.yaml`)

An optional file in the install directory, beside `main.py`. Every key is optional; a missing file means all defaults.

**Read once, at startup.** The panel loads this file before it builds its window and never re-reads it, so an edit reaches the panel only when you close it and launch again. A second launch while a window is open does not help — it surfaces the running window and exits before reading anything.

| Key | Type | Default | Purpose |
|---|---|---|---|
| `grace_period_seconds` | positive number | `20.0` | How long a stopping daemon may keep writing before it is force-terminated |
| `log_idle_threshold_seconds` | positive number | `3.0` | How long a log must stay unchanged before the daemon counts as quiescent. Raised automatically to the project's own `move_detect_delay` when the log was written inside that window, so a buffered move is not cut short (clamped to `grace_period_seconds` − 2 s) |
| `poll_interval_seconds` | positive number | `2.5` | How often the panel re-reads registry, locks, and processes |
| `project_registry` | path string | none | Explicit registry path (resolution tier 3) |

```yaml
# <install-dir>/panel-config.yaml — all keys optional
grace_period_seconds: 30
log_idle_threshold_seconds: 3
poll_interval_seconds: 2.5
project_registry: C:\path\to\process-framework-central\project-registry.json
```

**Invalid values never stop the panel.** A missing, unreadable, non-UTF-8, or unparseable file falls back to all defaults. A single bad value falls back to that key's default. In every case the panel logs a warning naming the rejected key and continues. The numeric keys reject non-numbers, booleans, infinity, NaN, out-of-range values, and anything zero or negative. An unknown key is ignored with a "possible typo" warning.

## Daemon status values

| Glyph | Label | Meaning |
|---|---|---|
| `●` | Running | A verified daemon is running for this project |
| `■` | Stopped | No daemon and no lock file |
| `⚠` | Stopped (stale lock) | A lock file exists with nothing behind it |
| `▲` | Starting… | A requested start is in flight |
| `▲` | Stopping — draining… | A requested stop is in flight |
| `✕` | Force-stopped | Terminated after the grace period elapsed |
| `✕` | Start failed | The project launcher reported a failure |

Every status renders as glyph **and** text; color is never the sole carrier of meaning. A stale lock renders as *not running* — a lock with nothing behind it never looks like a live daemon.

`Force-stopped` and `Start failed` are outcome states: they stay visible for their own display period rather than being immediately overwritten by the next poll, so a forced stop cannot scroll past unseen.

## Action enablement

| Action | Enabled for | Disabled for |
|---|---|---|
| Start | `Stopped`, `Stopped (stale lock)` | Running, Starting…, Stopping…, and every other state |
| Stop | `Running` | All other states |
| Refresh | Always | — |

With no row selected, Start and Stop are both disabled. During panel shutdown all actions are disabled. Keyboard accelerators fire through the same enablement as the buttons, so a disabled action can never be triggered by a keystroke.

## Keyboard shortcuts

| Shortcut | Action |
|---|---|
| `Alt+S` | Start the selected daemon |
| `Alt+T` | Stop the selected daemon |
| `F5` | Refresh the list now |
| `Ctrl+1` | Log tab |
| `Ctrl+2` | Configuration tab |
| `Ctrl+3` | Validation tab |
| `Ctrl+S` | Save the configuration being edited |
| `Ctrl+End` | Jump to the live end of the log |
| Double-click a row | Select the project and focus the Log tab |

Giving the project list keyboard focus selects the first row, so the list is reachable without a mouse.

## Daemon identification

A process counts as a given project's daemon only when **both** hold:

1. Its command line runs `main.py`, and
2. its `--project-root` value names that project's root.

Path comparison is case-folded and separator-normalized, so `C:\...` and `c:\...` match, while `C:\proj\App` does not match `C:\proj\AppExtra`. A lock-file PID match alone is never sufficient — PIDs get recycled. A process carrying `--validate`, `--version`, `--help`, or `-h` is doing something else and exiting, and is never claimed as a daemon.

A daemon is a **process pair** — a venv shim parent and a base-interpreter child with near-identical command lines. The panel always resolves and acts on the whole pair.

This test is re-run against a fresh process snapshot at termination time, never trusted from poll time. If nothing passes at that moment, nothing is terminated.

## Detail panes

| Pane | Source | Behavior |
|---|---|---|
| Log | The project's newest log in `logs/linkwatcher/` | Attaches to the last 64 KB, keeps 1,000 lines, reattaches across rotation |
| Configuration | `tools/linkwatcher/linkwatcher-config.yaml` in the project | Validate-on-save; atomic replace; never auto-creates |
| Validation | `main.py --validate` for the project | Takes no lock; one run per project at a time; 10-minute limit |

### Validation results

| Result | Condition |
|---|---|
| `✔ 0 broken links` | The scan exited cleanly with no findings |
| Broken-link count + report path | The scan found broken links and wrote a report |
| Failed, with reason | Spawn failure, timeout, or a nonzero exit with no report |

The broken-link count is read from the report file's `Broken links : N` line, with the report path taken from the scan's `Report written to <path>` output and falling back to `logs/linkwatcher/LinkWatcherBrokenLinks.txt`.

## File locations

### Install directory (default `~/bin`)

| Path | Purpose |
|---|---|
| `control_panel.py` | Panel entry script |
| `panel-config.yaml` | Panel settings (optional) |
| `logs/panel.log` | Panel diagnostic log, rotating at 1 MB with 3 backups |
| `panel.port` | Single-instance handshake port, written and removed by the panel |
| `doc/user/handbooks/` | These handbooks, shipped with the install |

### Per registered project

| Path | Purpose |
|---|---|
| `.linkwatcher.lock` | Daemon lock file |
| `tools/linkwatcher/linkwatcher-config.yaml` | Per-project configuration shown in the Configuration tab |
| `logs/linkwatcher/` | Daemon logs shown in the Log tab |
| `logs/linkwatcher/LinkWatcherBrokenLinks.txt` | Default validation report |
| `<framework face>/tools/linkWatcher/start_linkwatcher_background.ps1` | The launcher Start runs. The face is the project's declared `paths.process_framework`, defaulting to `process-framework/` |
| `<framework face>/.framework-parent-pointer` (legacy: `.framework-central-pointer`) | Consulted by registry resolution tier 5 |

## Single-instance behavior

Only one panel window exists at a time. The running panel binds a loopback listener and publishes its port to `panel.port` in the install directory. A later launch reads that file, sends a surface request, and exits without building a window. The port file is removed on exit, and only by the panel that owns it.

The second launch returns **before registry resolution runs**, so its `--project-root`, `--registry`, and working directory are all discarded. Changing which workspace is supervised requires closing the open panel first.

**Known limitation:** two launches within the same few milliseconds can both acquire the slot, producing two windows — never more, since the later writer owns `panel.port`. Both are functional; close either.

## Timing and limits

| Value | Setting | Default |
|---|---|---|
| Poll interval | `poll_interval_seconds` | 2.5 s |
| Log-idle threshold for drain | `log_idle_threshold_seconds` | 3 s |
| Idle required after recent activity | project's `move_detect_delay` | 10 s |
| Stop grace period | `grace_period_seconds` | 20 s |
| Shutdown watchdog | grace period + 15 s | 35 s |
| Launcher wait | fixed | 30 s |
| Process-exit wait | fixed | 10 s |
| Validation run limit | fixed | 600 s |
| Log-tail attach window | fixed | 64 KB |
| Log-tail buffer | fixed | 1,000 lines |
| First discovery pass | measured | ~7.5 s cold, ~0.1 s steady state |

## Known limitations

| Limitation | Consequence |
|---|---|
| Simultaneous launches can both win the single-instance slot | Two windows (never more); close either |
| A daemon still `Starting…` at panel close is not drained | It keeps running unmanaged; reopen the panel to list and manage it |
| The drain heuristic reads log activity, not internal daemon state | A pending move-correlation can be dropped at force-terminate; atomic writes mean dropped, never corrupted |
| The first discovery pass is slow on a busy machine | The list shows `Discovering daemons…` for several seconds after launch |
| The session-start hook does not open the panel | Launch it yourself with `linkwatcher-panel.bat` or `linkwatcher-panel.ps1` |

## Related Documentation

- [Control Panel Operations](../how-to/control-panel-operations.md) — how to perform each operation
- [How the Control Panel Stops Daemons](../explanation/how-the-control-panel-stops-daemons.md) — the drain-then-terminate model
- [Configuration Guide](../configuration-guide.md) — the per-project configuration schema
- [Quick Reference](../quick-reference.md) — daemon CLI options and environment variables
- [Link Validation](../link-validation.md) — validation scan details and report format

---

*This handbook is part of the LinkWatcher Product Documentation.*
