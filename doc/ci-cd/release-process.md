---
id: PD-CIC-003
type: Documentation
category: CI-CD
version: 2.3
created: 2023-06-15
updated: 2026-06-13
---

# Release Process Guide

This document outlines the release process for LinkWatcher. LinkWatcher is deployed locally as a global tool installed to `C:\Users\ronny\bin\`.

## Freshness Stamp

> Read by the Release & Deployment freshness gate (PF-TSK-008). Re-set **both** fields
> whenever the mechanics in this guide change or are re-verified against a real release.

- **Verified against release:** `2.1.3`
- **Verified on:** 2026-06-22

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
- Stops any running LinkWatcher instance (via `.linkwatcher.lock`) so files can be overwritten
- Stops **all** daemons running from the install-dir venv — other projects' daemons lock `.linkwatcher-venv\Scripts\python.exe` and would fail the venv rebuild (PD-BUG-106); stopped daemons restart at each project's next session start
- Aborts cleanly (before any files are copied) if the venv `python.exe` is still locked after the daemon stop
- Checks the Python version (3.8+ required)
- Installs/updates dependencies from `pyproject.toml` (`pip install -e .`)
- Removes stale files from previous installs (e.g., old `link_watcher.py`)
- Copies `main.py`, `pyproject.toml`, the `src/linkwatcher` package, `config-examples/`, and the `doc/user/handbooks/` user handbooks (excluding `__pycache__`/`*.pyc`)
- Creates a dedicated LinkWatcher virtual environment (`.linkwatcher-venv`) with the pinned dependencies (PD-BUG-077)
- Creates wrapper scripts (`linkwatcher.bat`, `linkwatcher.ps1`, and `checklinks.bat` if `scripts/check_links.py` is present)
- Runs a smoke test (`main.py --help`) to verify the install works
- **Propagates per-project config-schema changes** (see [Config-Schema Propagation](#config-schema-propagation) below)

To install to a custom location:

```bash
python deployment/install_global.py --install-dir "D:\tools\linkwatcher"
```

### 3. Restart LinkWatcher

If LinkWatcher is running in the background, restart it to pick up changes:

```powershell
# Stop existing instance
Get-Process python* | Where-Object {
    (Get-CimInstance Win32_Process -Filter "ProcessId = $($_.Id)").CommandLine -match "main\.py"
} | Stop-Process -Force

# Start fresh
& process-framework\tools\linkWatcher\start_linkwatcher_background.ps1
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
| `main.py` | `~/bin/main.py` | Entry point |
| `pyproject.toml` | `~/bin/pyproject.toml` | Package metadata + dependencies |
| `src/linkwatcher` | `~/bin/linkwatcher/` | Core package (all modules) |
| `config-examples/` | `~/bin/config-examples/` | Example configurations |
| `doc/user/handbooks/` | `~/bin/doc/user/handbooks/` | User handbooks (structure-preserving so the per-project config template's pointer `<install>/doc/user/handbooks/configuration-guide.md` and the handbooks' absolute-from-root cross-links resolve; PD-BUG-104) |

(The install also creates `~/bin/.linkwatcher-venv/` and the `linkwatcher.*` wrapper scripts in `~/bin/`.)

## Release Checklist

- [ ] All changes committed and pushed to GitHub
- [ ] Version bumped in `pyproject.toml` (see Version Management) if a significant release
- [ ] Run `python deployment/install_global.py` - completes without errors
- [ ] Config-schema propagation step ran cleanly (no-op, or filed an IMP + synced the template if a project-configurable field changed)
- [ ] User-visible behavior changed? Update the affected handbooks (configuration-guide / quick-reference / capabilities-reference). Config-key drift in the configuration guide's Full Reference is caught automatically by the test sweep (`test_configschemadrift.py`); semantic, CLI, or behavior changes need this manual check.
- [ ] Restart LinkWatcher background process
- [ ] Verify LinkWatcher is running and detecting file changes
- [ ] **Freshness Stamp** above updated to this release's version and date

## Version Management

The version is defined in **two places that must be bumped together** (currently `2.1.3`):

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
