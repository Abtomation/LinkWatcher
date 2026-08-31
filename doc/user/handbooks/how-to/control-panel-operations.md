---
id: PD-UGD-009
type: Product Documentation
category: User Guide
version: 1.4
created: 2026-08-18
updated: 2026-08-29
description: Launch the LinkWatcher Control Panel and use it to start, stop, inspect, and validate daemons across your projects
handbook_content_type: how-to
handbook_name: Control Panel Operations
---

# Control Panel Operations

## Overview

LinkWatcher runs as a background daemon — one per project, usually started automatically when you open a Claude session. The Control Panel is a desktop window that shows every registered project in one list and lets you act on any of them: start and stop daemons, read their logs, view and edit their configuration, and run a broken-link scan.

This guide covers the operations you perform in the window. For exact settings, status values, and shortcuts, see the [Control Panel Reference](../reference/control-panel-reference.md).

> **The panel only supervises.** It never becomes the daemon and never changes how daemons work. Closing the panel does, however, stop the daemons it manages — see [How the Control Panel Stops Daemons](../explanation/how-the-control-panel-stops-daemons.md) before you close the window on work you care about.

## Prerequisites

- LinkWatcher installed globally (`python deployment/install_global.py`), which puts the panel launchers in your install directory (default `~/bin`)
- At least one workspace registered in the child registry your workspace resolves to — `project-registry.json` or `framework-registry.json`, depending on the workspace's role
- Windows with a desktop session — the panel is a GUI application

## Open the panel

**Launch from the workspace you want to supervise** — *not* from the install directory. The launchers pass no arguments of their own, so the panel takes the current directory as the workspace root.

Which list you then get depends on the kind of workspace you are standing in:

- **A workspace that has children** — a framework listing its projects, or a framework-builder listing its frameworks — owns a registry. Launch from its root and you get that workspace's own list; launch from a subdirectory and the panel falls back to the parent-pointer and lists the *parent's* workspaces instead.
- **A leaf project** owns no registry of its own, so it is always supervised from the one its parent keeps — the list that holds the project itself alongside its siblings. That is the correct answer from anywhere inside the project, root included, and `--project-root` does not change it.

From the install directory the panel finds neither, so you get the registry-error banner.

```cmd
cd C:\path\to\your-workspace
linkwatcher-panel.bat
```

```powershell
cd C:\path\to\your-workspace
linkwatcher-panel.ps1
```

The launchers find their own interpreter and entry script from their own location, so they work from any directory. Calling them by bare name needs the install directory (default `~/bin`) on your `PATH`; otherwise call them by full path — `"%USERPROFILE%\bin\linkwatcher-panel.bat"` — which leaves the current directory free to name the workspace.

Name the workspace root explicitly when you cannot change directory, or to fix which root the panel takes rather than relying on where you happen to be standing (at a leaf this pins the root without changing the resulting list, per the rule above):

```cmd
linkwatcher-panel.bat --project-root "C:\path\to\your-workspace"
```

Both launchers accept the same options as the entry script, so you can also point the panel at a specific registry or turn on verbose logging:

```cmd
linkwatcher-panel.bat --registry "C:\path\to\project-registry.json"
linkwatcher-panel.bat --debug
```

If you run a launcher while a panel is already open, the second launch exits with a message instead of opening a duplicate, and the running window is surfaced. Usually it comes to the front; when Windows' foreground lock refuses to let a background process steal focus, its taskbar button flashes instead — click it to raise the window. Either way you never get a second panel.

**A second launch changes nothing but which window has focus.** It exits before reading the registry, so relaunching from a different directory — or with `--project-root`, or `--registry` — cannot change which workspace the open panel supervises. Close the panel first, then launch again.

**The list is empty for a few seconds after launch.** The panel shows `Discovering daemons…` while it takes its first pass over the process table — measured at around 7.5 seconds on a busy machine, and about 0.1 seconds for every poll after that. This is expected; the panel deliberately says "discovering" rather than falsely reporting an empty registry.

## Read the daemon list

The left pane lists one row per registered project with a status and an uptime. Status is always a glyph *and* a word — never color alone:

| Row shows | What it means |
|---|---|
| `● Running` | A verified daemon is running for this project |
| `■ Stopped` | No daemon, no lock file |
| `⚠ Stopped (stale lock)` | A lock file exists but nothing is behind it — safe to start |
| `▲ Starting…` | A start you requested is in flight |
| `▲ Stopping — draining…` | A stop you requested is in flight |
| `✕ Force-stopped` | The daemon did not go quiet in time and was terminated |
| `✕ Start failed` | The launcher reported a failure |

The status bar at the bottom summarizes the list, for example `3 of 7 daemons running`.

The panel keeps this picture honest by re-reading reality every couple of seconds. A daemon someone else started or stopped — from a session hook, a terminal, or Task Manager — appears on the next poll without you doing anything. Press **F5** to force a refresh.

## Start a daemon

1. Select the project row. Start is enabled only when the daemon is stopped, including the stale-lock case.
2. Click **▶ Start** (or press **Alt+S**).

The panel does not spawn the daemon itself — it runs that project's own `start_linkwatcher_background.ps1`, the same launcher the session hook uses. You therefore inherit its behavior exactly: its duplicate-instance guard, its stale-lock reclaim, and its logging. Starting a project that is already running is harmless.

The row shows `▲ Starting…` until a poll confirms a real daemon. If the launcher fails, the row shows `✕ Start failed` and the reason goes to the panel log.

## Stop a daemon

1. Select a running project row. Stop is enabled only for `● Running`.
2. Click **■ Stop** (or press **Alt+T**).

The panel does not kill the process immediately. It watches the project's newest log file until it stops changing, then terminates the verified process pair. If the log is still busy when the grace period expires (20 seconds by default), the daemon is terminated anyway and the row reports `✕ Force-stopped` so you know a forced stop happened rather than a clean one.

The full reasoning, and what a forced stop can cost you, is in [How the Control Panel Stops Daemons](../explanation/how-the-control-panel-stops-daemons.md).

## Watch a project log

Select a row and open the **Log** tab (**Ctrl+1**, or double-click the row).

The pane tails that project's newest log file live. It loads the last 64 KB on attach and keeps the most recent 1,000 lines, so opening a log that has been running for weeks is instant. When LinkWatcher rotates its log, the pane reattaches to the new file on its own.

Scroll up to read back through the buffer; press **Ctrl+End** to jump back to the live end.

## Run a link validation scan

Select a row, open the **Validation** tab (**Ctrl+3**), and click **▶ Run validation**.

The scan runs `main.py --validate` for that project as a separate short-lived process. **It takes no lock and does not touch the running daemon** — you can validate a project whose daemon is live. The result is one of:

- `✔ 0 broken links` — the scan finished clean
- a broken-link count, with an **Open report** button for the report file (`logs/linkwatcher/LinkWatcherBrokenLinks.txt` by default)
- a failure, with the captured reason — a scan that could not complete is never shown as a pass

One scan runs per project at a time. Starting a second scan for the same project while the first is in flight is refused; other projects are unaffected. A scan that hangs is abandoned after 10 minutes and reported as failed.

## View and edit a project configuration

Select a row and open the **Configuration** tab (**Ctrl+2**). The pane shows that project's `tools/linkwatcher/linkwatcher-config.yaml`.

Edit the text and click **Save** (or press **Ctrl+S**); **Discard** reverts your edits. Every save goes through the real configuration loader before anything is written:

1. The text is parsed as YAML. A syntax error is reported with its line number and **nothing is written**.
2. The candidate content is validated by constructing the actual configuration object the daemon uses at startup. An invalid value is reported and **nothing is written**.
3. Only content that passes both is moved into place atomically.

A rejected save therefore leaves your existing configuration byte-for-byte untouched. An empty or comments-only file is valid — it means "use all built-in defaults."

If the project has no configuration file yet, the pane says so and offers a **Create default config** button. It never writes that file behind your back.

**Changes do not reach a running daemon.** LinkWatcher reads its configuration at startup, so restart that project's daemon for an edit to take effect.

**Unsaved edits are protected.** If you try to select another project or switch tabs with unsaved changes in the editor, the panel warns you first.

## Close the panel

Closing the window **stops every daemon the panel manages**. A modal dialog appears showing each daemon draining, with a `k of n stopped` counter, and the panel exits when they are all resolved. You cannot dismiss this dialog — the panel is committed at that point — but it is bounded and cannot hang.

If nothing is running, the panel simply exits.

This is the panel's most consequential behavior and the one most likely to surprise you. Read [How the Control Panel Stops Daemons](../explanation/how-the-control-panel-stops-daemons.md) if you want daemons to keep running after you are done looking at them.

## When something goes wrong

### The list shows a registry error instead of projects

**Problem:** The panel opens but shows a banner saying the project registry could not be located.

**Solution:** The panel looks for a registry in this order: the `--registry` argument, the `LINKWATCHER_PROJECT_REGISTRY` environment variable, the `project_registry` key in `panel-config.yaml`, then two automatic locates — the child registry the workspace root owns (`--project-root`, or the current directory), and failing that the registry its parent owns, found through the framework parent-pointer. Supply one of them — the simplest fix is usually to launch from the workspace root, name it explicitly, or pass the registry path. **Close this panel before relaunching**: the window showing the banner is the open instance, and a second launch surfaces it again without re-resolving anything.

```cmd
linkwatcher-panel.bat --project-root "C:\path\to\your-workspace"
linkwatcher-panel.bat --registry "C:\path\to\project-registry.json"
```

### The list shows the wrong projects

**Problem:** The panel opens and lists workspaces, but not the ones you expected — for example the frameworks registered above your workspace rather than the projects inside it.

**Solution:** Start with `panel.log` in the install directory, which records which registry answered on a line reading `registry resolved via workspace: …` or `via pointer: …`. Read that against the workspace you launched from:

- **`via pointer`, at a workspace that has children** — you launched from a subdirectory rather than the root, so the panel fell back to the parent's registry. **Close the open panel first** — a second launch only surfaces the window you are already looking at and re-resolves nothing — then launch again from the workspace root, or with `--project-root` naming it.
- **`via pointer`, at a leaf project** — this is the correct answer rather than a fault. A leaf owns no registry, so it is supervised from its parent's, which lists the project alongside its siblings. Nothing on the command line changes that: `--project-root` naming the leaf returns the identical list. To supervise a different set, close the open panel first — as above, a second launch re-resolves nothing — then launch again from the workspace that owns it, or pass `--registry` with the path you want.
- **`via workspace`, but not the list you meant** — the directory you launched from owns a registry of its own; the blueprint-seed case below is the common instance.

### The list is empty but nothing looks wrong

**Problem:** The panel shows "No registered projects found."

**Solution:** This is usually not an error — the registry was read successfully and contains no projects. Register a project and it appears on the next poll.

One case looks identical but is not. Launching from the root of a producer's blueprint or template tree resolves *that tree's* registry, which is an empty seed — so the panel truthfully reports an empty registry that is not the one you meant. Check the `registry resolved via workspace: …` line in `panel.log`: if it names a path inside a blueprint or template tree, close the panel and launch again from the real workspace root, or with `--project-root` naming it.

### A project I know is running shows as Stopped

**Problem:** A daemon is running but its row says stopped.

**Solution:** The panel claims a process as a project's daemon only when the command line runs `main.py` *and* its `--project-root` names that project. A daemon started without `--project-root` cannot be attributed to any project and is deliberately never claimed — the panel will not guess and risk stopping the wrong process. Start the daemon through the project launcher (or the panel) so it carries the flag.

### A row says "Stopped (stale lock)"

**Problem:** A lock file exists but no daemon is behind it.

**Solution:** Nothing to clean up by hand — Start is enabled for this state, and the project launcher reclaims the stale lock as it starts.

### A stop reported "Force-stopped"

**Problem:** The row shows a forced stop rather than a clean one.

**Solution:** The project's log kept changing for the whole grace period, so the daemon was terminated without going quiet. Check that project's log for what it was busy with. If this happens routinely on your projects, raise `grace_period_seconds` in `panel-config.yaml` — then close the panel and launch it again, since that file is read only at startup and an edit does not reach a running window.

### Two panel windows are open

**Problem:** Two windows appeared instead of one.

**Solution:** A known edge case — two launches within the same few milliseconds can both claim the single-instance slot. It stops at two, never more. Close either one; both are fully functional, so simply avoid driving start and stop from both at once.

### The panel misbehaves and there is no console output

**Problem:** Something went wrong but you have no error to look at.

**Solution:** The panel keeps its own diagnostic log at `<install-dir>/logs/panel.log`, separate from the daemon logs, recording forced terminations, start and validation failures, and internal errors. For verbose entries, **close the panel and launch it again** with `--debug` — while a window is open, a second launch only surfaces it, and the new process's log level exits with that process.

## Related Documentation

- [Control Panel Reference](../reference/control-panel-reference.md) — options, settings, status values, shortcuts, file locations
- [How the Control Panel Stops Daemons](../explanation/how-the-control-panel-stops-daemons.md) — the drain-then-terminate model
- [Configuration Guide](../configuration-guide.md) — the per-project configuration keys you edit in the Configuration tab
- [Link Validation](../link-validation.md) — what the validation scan checks and how to read its report
- [Multi-Project Setup](../multi-project-setup.md) — registering projects for a shared installation
- [Logging and Monitoring](../logging-and-monitoring.md) — the daemon logging the Log tab displays

---

*This handbook is part of the LinkWatcher Product Documentation.*
