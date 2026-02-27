---
id: PD-CIC-003
type: Documentation
version: 2.0
created: 2023-06-15
updated: 2026-02-26
---

# Release Process Guide

This document outlines the release process for LinkWatcher. LinkWatcher is deployed locally as a global tool installed to `C:\Users\ronny\bin\`.

## Architecture

LinkWatcher has two locations:

- **Source repository**: `C:\Users\ronny\VS_Code\LinkWatcher\` - development copy with full codebase, tests, docs
- **Global install**: `C:\Users\ronny\bin\` - deployed copy that the background process runs from

The startup scripts in `LinkWatcher_run/` reference the global install location. The install script copies source files and updates all startup scripts automatically.

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
- Checks Python version (3.8+ required)
- Installs/updates pip dependencies from `requirements.txt`
- Removes stale files from previous installs (e.g., old `link_watcher.py`)
- Copies `main.py`, `requirements.txt`, `linkwatcher/` package, and `config-examples/`
- Excludes `__pycache__` and `.pyc` files from the copy
- Creates wrapper scripts (`linkwatcher.bat`, `linkwatcher.ps1`, `checklinks.bat`)
- Updates all startup scripts in `LinkWatcher_run/` to point to the install path
- Runs a smoke test (`main.py --help`) to verify the install works

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
& LinkWatcher_run\start_linkwatcher_background.ps1
```

### 4. Verify

Check that LinkWatcher is running with the updated code:

```powershell
# Confirm process is running
Get-Process python* | Where-Object {
    (Get-CimInstance Win32_Process -Filter "ProcessId = $($_.Id)").CommandLine -match "main\.py"
}

# Check recent log output
Get-Content LinkWatcher_run\LinkWatcherLog.txt -Tail 20
```

## What Gets Deployed

| Source | Deployed To | Purpose |
|--------|-------------|---------|
| `main.py` | `~/bin/main.py` | Entry point |
| `requirements.txt` | `~/bin/requirements.txt` | Dependencies |
| `linkwatcher/` | `~/bin/linkwatcher/` | Core package (all modules) |
| `config-examples/` | `~/bin/config-examples/` | Example configurations |
| `scripts/check_links.py` | `~/bin/scripts/check_links.py` | Link checker utility (optional) |

## Release Checklist

- [ ] All changes committed and pushed to GitHub
- [ ] Run `python deployment/install_global.py` - completes without errors
- [ ] Restart LinkWatcher background process
- [ ] Verify LinkWatcher is running and detecting file changes
- [ ] Update `CHANGELOG.md` if this is a significant release

## Version Management

Version is defined in `setup.py` (currently `2.0.0`). For significant releases:

1. Update `version` in `setup.py`
2. Update `CHANGELOG.md` with changes
3. Optionally create a git tag:
   ```bash
   git tag v2.1.0
   git push origin v2.1.0
   ```

## Related Documentation

- [Development Guide](../guides/guides/development-guide.md)
- [Testing Guide](../guides/guides/testing-guide.md)
- [Definition of Done](../../process-framework/methodologies/definition-of-done.md)
