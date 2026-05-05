---
id: PD-UGD-008
type: Product Documentation
category: User Guide
version: 1.0
created: 2025-12-01
updated: 2026-04-16
---

# LinkWatcher Multi-Project Setup Guide

This guide explains how to use LinkWatcher across multiple projects from a single installation.

## Goal

Use LinkWatcher from any project directory while keeping the tool files in one central location.

**Example Structure:**
```
📁 VS_Code/
├── 📁 LinkWatcher/                    # Tool installation (this repo)
│   ├── main.py                       # Main entry point
│   ├── src/linkwatcher/               # Core package
│   ├── deployment/
│   │   └── install_global.py         # Global installer
│   ├── scripts/
│   │   └── check_links.py           # Standalone link checker
│   └── process-framework/tools/linkWatcher/
│       └── start_linkwatcher_background.ps1  # Agnostic background starter
├── 📁 ProjectA/                       # Any project that adopts the framework
│   ├── doc/project-config.json       # Identifies the project root
│   └── process-framework-local/tools/linkWatcher/
│       ├── .linkwatcher-ignore       # Per-project suppression rules
│       └── logs/                     # Runtime logs
└── 📁 ProjectB/
    └── ...
```

## Setup Steps

### 1. Install LinkWatcher Globally (one-time)

From the LinkWatcher directory:
```cmd
cd c:\Users\ronny\VS_Code\LinkWatcher
python deployment\install_global.py
```

This will:
- Install dependencies from `pyproject.toml`
- Copy LinkWatcher files to a global location (default: `~/bin`)
- Create a dedicated venv at `<install-dir>/.linkwatcher-venv`
- Create wrapper scripts for easy access

The agnostic background starter auto-detects the install location at runtime (env var `$LINKWATCHER_INSTALL_DIR` or fallback search of `~/bin`, `~/tools`, `~/scripts`, `~/.local/bin`, `~/LinkWatcher`), so no per-project configuration step is required.

### 2. Use LinkWatcher

From any project directory:

**Direct Usage:**
```cmd
# Start watching (from your project directory)
python %USERPROFILE%\bin\main.py

# With explicit project root
python %USERPROFILE%\bin\main.py --project-root c:\Users\ronny\VS_Code\YourProject

# Check links once (standalone utility)
python c:\Users\ronny\VS_Code\LinkWatcher\scripts\check_links.py
```

**Using Background Script (Windows):**
```cmd
# PowerShell (background — recommended for development sessions)
# Run from any project that has both process-framework/ and doc/project-config.json
process-framework\tools\linkWatcher\start_linkwatcher_background.ps1
```

**VS Code:**
LinkWatcher no longer auto-generates `.vscode/tasks.json`. If you want a one-click "Start LinkWatcher" task, add this manually to your project's `.vscode/tasks.json`:
```json
{
  "label": "Start LinkWatcher",
  "type": "shell",
  "command": "pwsh.exe",
  "args": ["-File", "${workspaceFolder}/process-framework/tools/linkWatcher/start_linkwatcher_background.ps1"]
}
```

## How It Works

1. **LinkWatcher automatically detects the current working directory** as the project root
2. **No configuration needed** — just run from your project directory
3. **Each project gets its own monitoring session** when you start LinkWatcher from that directory
4. **Links are updated only within the current project** directory tree
5. **A lock file** (`.linkwatcher.lock`) prevents duplicate instances per project

## Usage Examples

### Example 1: Monitor a Project
```cmd
cd c:\Users\ronny\VS_Code\YourProject
python %USERPROFILE%\bin\main.py
# Now monitoring: c:\Users\ronny\VS_Code\YourProject
```

### Example 2: Monitor a Specific Subdirectory
```cmd
python %USERPROFILE%\bin\main.py --project-root c:\Users\ronny\VS_Code\YourProject\docs
# Now monitoring: c:\Users\ronny\VS_Code\YourProject\docs
```

### Example 3: Background Mode with Logging
```cmd
python %USERPROFILE%\bin\main.py --log-file process-framework-local/tools/linkWatcher/logs/LinkWatcherLog_20260324-091626_20260325-224338_20260326-141107_20260327-131638.txt --debug
```

## Key Benefits

- **One installation, multiple projects**
- **No project-specific configuration required**
- **Automatic project root detection**
- **Works from any subdirectory**
- **VS Code integration per project**
- **Isolated monitoring per project**
- **Lock file prevents duplicate instances**

## Advanced Options

### Custom Project Root
```cmd
python %USERPROFILE%\bin\main.py --project-root c:\path\to\other\directory
```

### Skip Initial Scan
For faster startup on large projects:
```cmd
python %USERPROFILE%\bin\main.py --no-initial-scan
```

### Dry Run Mode
Preview link updates without modifying files:
```cmd
python %USERPROFILE%\bin\main.py --dry-run
```

### Quiet Mode
```cmd
python %USERPROFILE%\bin\main.py --quiet
```

## Troubleshooting

### "LinkWatcher not found" Error
- Make sure you ran `deployment/install_global.py` first
- Check the installation path shown during installation (default: `~/bin`)
- Manually specify the path if needed

### "Permission Denied" Error
- Ensure you have write permissions in your project directory

### Links Not Updating
- Verify LinkWatcher is monitoring the correct directory
- Check console output or log file for error messages
- Ensure file extensions are supported (`.md`, `.yaml`, `.json`, `.py`, `.dart`, etc.)

### LinkWatcher Already Running
- The background starter checks for a `.linkwatcher.lock` file
- If a stale lock file exists (process no longer running), it will be overridden automatically
- To force stop: `Get-Process python* | Stop-Process -Force`
