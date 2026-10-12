---
id: PD-CIC-003
description: "Project-specific release process guide — deploy, version, and distribute mechanics with a release checklist."
type: Documentation
category: CI-CD
version: 2.4
created: 2023-06-15
updated: 2026-08-20
---

# Release Process Guide

This document outlines the release process for LinkWatcher. LinkWatcher is deployed locally as a global tool installed to `C:\Users\ronny\bin\`.

## Freshness Stamp

> Read by the Release & Deployment freshness gate (PF-TSK-008). Re-set **both** fields
> whenever the mechanics in this guide change or are re-verified against a real release.

- **Verified against release:** `2.2.1`
- **Verified on:** 2026-08-31

## Architecture

LinkWatcher has two locations:

- **Source repository**: `C:\Users\ronny\VS_Code\LinkWatcher\` - development copy with full codebase, tests, docs
- **Global install**: `C:\Users\ronny\bin\` - deployed copy that the background process runs from

The agnostic startup script in `process-framework/tools/linkWatcher/` auto-detects the global install location at runtime — no per-project startup-script regeneration is needed.

## Release Process

### 1. Commit and Push Changes

Ensure all changes are committed and pushed to GitHub:

```bash
git add -A
git commit -m "Description of changes"
git push origin main
```

### 2. Run the Install Script

Deploy the updated code to the global install location:

```bash
python deployment/install_global.py
```

This script:
- Stops **every process running from the install-dir venv** — this project's own daemon, other projects' daemons, **and a running Control Panel** — so nothing locks `.linkwatcher-venv\Scripts\python.exe` and fails the venv rebuild (PD-BUG-106); processes are identified by executable path, never by a lock-file PID (PD-BUG-121). Daemons restart at each project's next session start; **the Control Panel does not restart itself** — relaunch it manually after the install (see step 3)
- Waits for `.linkwatcher-venv\Scripts\python.exe` to actually be released before judging the stop — killing is asynchronous, and checking with no tolerance aborted releases on a lock that was already dissolving (PD-BUG-158). The wait runs whether or not the installer did the killing, so a Control Panel you closed by hand moments earlier (step 3 below) is covered too; with the interpreter already free it costs a single file check, not the timeout. If the interpreter is *still* locked after that wait, the install aborts cleanly before any files are copied, and the message reports what can actually be observed — the surviving venv PIDs, or plainly that no venv process exists and the handle is held from outside it
- Checks the Python version (3.8+ required)
- Removes stale files from previous installs (e.g., old `link_watcher.py`)
- Copies `main.py`, `control_panel.py`, `pyproject.toml`, the `src/linkwatcher` package, `config-examples/`, and the `doc/user/handbooks/` user handbooks (excluding `__pycache__`/`*.pyc`)
- Generates `requirements.txt` in the install dir from the runtime dependencies declared in `pyproject.toml` — the deployed venv is a flat tree with no package build, so the venv installs from this file (falling back to `pyproject.toml` only if it is absent)
- Creates a dedicated LinkWatcher virtual environment (`.linkwatcher-venv`) with those pinned dependencies (PD-BUG-077)
- Creates wrapper scripts (`linkwatcher.bat`, `linkwatcher.ps1`, `linkwatcher-panel.bat`, `linkwatcher-panel.ps1`, and `checklinks.bat` if `scripts/check_links.py` is present). The panel wrappers use the console `python.exe`, not `pythonw.exe`, so a terminal launch can surface the panel's dependency diagnostics
- Runs smoke tests (`main.py --help`, and `control_panel.py --help` in a GUI-safe form) to verify the install works
- **Propagates per-project config-schema changes** (see [Config-Schema Propagation](#config-schema-propagation) below)

To install to a custom location:

```bash
python deployment/install_global.py --install-dir "D:\tools\linkwatcher"
```

### 3. Restart LinkWatcher

The install script has already stopped every venv process, so this step is a **restart**, not a stop-then-start. Start this project's daemon fresh:

```powershell
& process-framework\tools\linkWatcher\start_linkwatcher_background.ps1
```

If a daemon survived (an instance started from a different install, say), stop it with the project's own tool — it matches on command line plus project root and verifies the post-condition, rather than trusting a lock-file PID:

```powershell
& process-framework\tools\linkWatcher\stop_linkwatcher.ps1
```

**Control Panel**: the install kills a running panel with the rest of the venv processes and nothing restarts it. Relaunch it manually if it was open:

```powershell
& "$env:USERPROFILE\bin\linkwatcher-panel.ps1"
```

### 4. Verify

Check that LinkWatcher is running with the updated code:

```powershell
# Confirm process is running
Get-Process python* | Where-Object {
    (Get-CimInstance Win32_Process -Filter "ProcessId = $($_.Id)").CommandLine -match "main\.py"
}

# Check recent log output (flat logs/linkwatcher/ layout)
Get-Content logs/linkwatcher/LinkWatcherLog.txt -Tail 20
```

## Config-Schema Propagation

LinkWatcher is the **upstream source** of the *project-configurable* per-project validation config schema — the `--validate` keys in [config-examples/linkwatcher-config.yaml](../../config-examples/linkwatcher-config.yaml). Other projects receive a per-project validation config copied from a framework-distributed template (`blueprint/process-framework/tools/linkWatcher/linkwatcher-config.template.yaml` in appdev). When LinkWatcher adds/removes/renames a project-configurable **field**, those downstream configs need updating — but appdev only acts if it knows the schema changed.

The install script's last step ([deployment/propagate_config_schema.py](../../deployment/propagate_config_schema.py)) closes that loop automatically:

1. Resolves the appdev framework root via `process-framework/.framework-central-pointer`.
2. Compares the **top-level field names** of the WIP template against the appdev template (values — including the per-project folder keys under `path_resolution_overrides` — are data and are ignored).
3. **If a field was added/removed/renamed:** files one high-priority IMP into central intake (so each project's `tools/linkwatcher/linkwatcher-config.yaml` gets updated and configured by hand — appdev directly, PRJ-001/PRJ-002 via per-project migration, PRJ-T01 via the next Push) and syncs the appdev template so new projects bootstrap with the latest schema.

It is non-fatal: on a standalone clone (no `.framework-central-pointer`) it skips silently, and when the schema is unchanged it is a no-op.

> **To propagate a new project-configurable key:** add it (active, with an empty/default value) to [config-examples/linkwatcher-config.yaml](../../config-examples/linkwatcher-config.yaml) — not just in a comment. Prefer fixed-key structures over maps with variable keys so the schema stays comparable.

## What Gets Deployed

| Source | Deployed To | Purpose |
|--------|-------------|---------|
| `main.py` | `~/bin/main.py` | Daemon / CLI entry point |
| `control_panel.py` | `~/bin/control_panel.py` | Control Panel entry point (feature 7.1.1); the `linkwatcher_control_panel` subpackage it imports ships inside `src/linkwatcher` below |
| `pyproject.toml` | `~/bin/pyproject.toml` | Package metadata + dependency declarations |
| `src/linkwatcher` | `~/bin/linkwatcher/` | Core package (all modules) |
| `config-examples/` | `~/bin/config-examples/` | Example configurations |
| `doc/user/handbooks/` | `~/bin/doc/user/handbooks/` | User handbooks (structure-preserving so the per-project config template's pointer `<install>/doc/user/handbooks/configuration-guide.md` and the handbooks' absolute-from-root cross-links resolve; PD-BUG-104) |

(The install also generates `~/bin/requirements.txt`, creates `~/bin/.linkwatcher-venv/`, and writes the `linkwatcher.*` and `linkwatcher-panel.*` wrapper scripts in `~/bin/`.)

## Release Checklist

- [ ] All changes committed and pushed to GitHub
- [ ] Version bumped in `pyproject.toml` (see Version Management) if a significant release
- [ ] Run `python deployment/install_global.py` - completes without errors
- [ ] Config-schema propagation step ran cleanly (no-op, or filed an IMP + synced the template if a project-configurable field changed)
- [ ] User-visible behavior changed? Update the affected handbooks (configuration-guide / quick-reference / capabilities-reference). Config-key drift in the configuration guide's Full Reference is caught automatically by the test sweep (`test_configschemadrift.py`); semantic, CLI, or behavior changes need this manual check.
- [ ] Restart LinkWatcher background process
- [ ] Relaunch the Control Panel if it was open (the install kills it; nothing restarts it)
- [ ] Verify LinkWatcher is running and detecting file changes
- [ ] **Freshness Stamp** above updated to this release's version and date

## Version Management

The version is defined in **two places that must be bumped together** (currently `2.2.1`):

- `pyproject.toml` under `[project].version` — package metadata
- `src/linkwatcher/__init__.py` `__version__` — the value `main.py --version` actually reports (the deployed venv installs from `requirements.txt`, so there is no package metadata to read at runtime; the hardcode is authoritative in the install)

Discovered in the v2.1.1 release: bumping only `pyproject.toml` ships a binary that reports the old version.

For significant releases:

1. Update `version` in `pyproject.toml` **and** `__version__` in `src/linkwatcher/__init__.py`
2. Tag the release commit and push the tag:
   ```bash
   git tag v2.1.1
   git push origin v2.1.1
   ```
   `install_global.py` prints a warning at deploy time when the version being installed has no matching `v<version>` tag, so create the tag before running the install step (or right after, then re-run). The check is a nudge, not a hard gate — it never blocks a dev install of an as-yet-unreleased version.

## Related Documentation

- [Development Guide](../../process-framework/guides/04-implementation/development-guide.md)
- [Definition of Done](../../process-framework/guides/04-implementation/definition-of-done.md)
- [Configuration Guide](../user/handbooks/configuration-guide.md) - Full per-project config key reference
