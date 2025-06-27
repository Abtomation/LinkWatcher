#!/usr/bin/env python3
"""
Project-specific LinkWatcher Setup

This script sets up LinkWatcher for the current project directory.
Copy this file to any project where you want to use LinkWatcher.
"""

import json
import os
import sys
from pathlib import Path


def find_linkwatcher_installation():
    """Find the LinkWatcher installation directory."""
    possible_locations = [
        Path.home() / "bin",
        Path.home() / "tools",
        Path.home() / "scripts",
        Path.home() / ".local" / "bin",
        Path.home() / "LinkWatcher",
    ]

    for location in possible_locations:
        if (location / "old/link_watcher_old.py").exists():
            return location

    return None


def create_vscode_tasks(linkwatcher_dir):
    """Create VS Code tasks for the current project."""
    vscode_dir = Path(".vscode")
    tasks_file = vscode_dir / "tasks.json"

    # Create .vscode directory if it doesn't exist
    vscode_dir.mkdir(exist_ok=True)

    # Task configuration
    task_config = {
        "version": "2.0.0",
        "tasks": [
            {
                "label": "Start LinkWatcher",
                "type": "shell",
                "command": "python",
                "args": [str(linkwatcher_dir / "old/link_watcher_old.py")],
                "group": "build",
                "presentation": {"echo": True, "reveal": "always", "focus": False, "panel": "new"},
                "problemMatcher": [],
                "detail": "Start LinkWatcher for this project",
            },
            {
                "label": "Check Links",
                "type": "shell",
                "command": "python",
                "args": [str(linkwatcher_dir / "check_links.py")],
                "group": "test",
                "presentation": {"echo": True, "reveal": "always", "focus": False, "panel": "new"},
                "problemMatcher": [],
                "detail": "Check all links in this project",
            },
        ],
    }

    # If tasks.json exists, merge with existing tasks
    if tasks_file.exists():
        try:
            with open(tasks_file, "r") as f:
                existing_config = json.load(f)

            # Add our tasks to existing ones
            if "tasks" not in existing_config:
                existing_config["tasks"] = []

            # Remove any existing LinkWatcher tasks
            existing_config["tasks"] = [
                task
                for task in existing_config["tasks"]
                if task.get("label") not in ["Start LinkWatcher", "Check Links"]
            ]

            # Add our tasks
            existing_config["tasks"].extend(task_config["tasks"])
            task_config = existing_config

        except (json.JSONDecodeError, KeyError):
            print("⚠️  Could not parse existing tasks.json, creating new one")

    with open(tasks_file, "w") as f:
        json.dump(task_config, f, indent=2)

    print(f"✅ VS Code tasks created in {tasks_file}")
    return True


def create_convenience_scripts(linkwatcher_dir):
    """Create convenience scripts for this project."""
    project_dir = Path(".")

    # Windows batch script
    batch_script = project_dir / "start_linkwatcher.bat"
    batch_content = f"""@echo off
echo Starting LinkWatcher for this project...
python "{linkwatcher_dir / 'old/link_watcher_old.py'}"
pause
"""

    with open(batch_script, "w") as f:
        f.write(batch_content)

    # PowerShell script
    ps_script = project_dir / "start_linkwatcher.ps1"
    ps_content = f"""# LinkWatcher for this project
Write-Host "Starting LinkWatcher for this project..." -ForegroundColor Cyan
python "{linkwatcher_dir / 'old/link_watcher_old.py'}"
Read-Host "Press Enter to exit"
"""

    with open(ps_script, "w") as f:
        f.write(ps_content)

    # Shell script
    shell_script = project_dir / "start_linkwatcher.sh"
    shell_content = f"""#!/bin/bash
echo "Starting LinkWatcher for this project..."
python3 "{linkwatcher_dir / 'old/link_watcher_old.py'}"
"""

    with open(shell_script, "w") as f:
        f.write(shell_content)

    # Make shell script executable on Unix-like systems
    if os.name != "nt":
        os.chmod(shell_script, 0o755)

    print("✅ Convenience scripts created:")
    print(f"   - {batch_script}")
    print(f"   - {ps_script}")
    print(f"   - {shell_script}")


def main():
    """Main setup function for current project."""
    print("LinkWatcher Project Setup")
    print("=" * 30)

    current_dir = Path(".").resolve()
    print(f"Setting up LinkWatcher for: {current_dir}")

    # Find LinkWatcher installation
    linkwatcher_dir = find_linkwatcher_installation()

    if not linkwatcher_dir:
        print("\n❌ ERROR: LinkWatcher installation not found!")
        print("\nPlease install LinkWatcher globally first:")
        print("1. Go to the LinkWatcher directory")
        print("2. Run: python install_global.py")
        print("\nOr specify the LinkWatcher directory manually:")
        manual_path = input("Enter LinkWatcher directory path (or press Enter to exit): ").strip()

        if manual_path:
            linkwatcher_dir = Path(manual_path)
            if not (linkwatcher_dir / "old/link_watcher_old.py").exists():
                print(f"❌ ERROR: link_watcher.py not found in {linkwatcher_dir}")
                sys.exit(1)
        else:
            sys.exit(1)

    print(f"✅ Found LinkWatcher at: {linkwatcher_dir}")

    # Create VS Code tasks
    try:
        create_vscode_tasks(linkwatcher_dir)
    except Exception as e:
        print(f"⚠️  Warning: Could not create VS Code tasks: {e}")

    # Create convenience scripts
    try:
        create_convenience_scripts(linkwatcher_dir)
    except Exception as e:
        print(f"⚠️  Warning: Could not create convenience scripts: {e}")

    print("\n" + "=" * 50)
    print("🎉 Project setup completed!")
    print("=" * 50)

    print(f"\n📁 Project directory: {current_dir}")
    print(f"🔗 LinkWatcher location: {linkwatcher_dir}")

    print("\n📋 How to use:")
    print("1. Start LinkWatcher:")
    print(f"   python \"{linkwatcher_dir / 'old/link_watcher_old.py'}\"")
    print("   # Or use convenience scripts:")
    print("   ./start_linkwatcher.bat  (Windows)")
    print("   ./start_linkwatcher.sh   (Linux/Mac)")

    print("\n2. Check links:")
    print(f"   python \"{linkwatcher_dir / 'check_links.py'}\"")

    print("\n3. VS Code integration:")
    print("   Ctrl+Shift+P → 'Tasks: Run Task' → 'Start LinkWatcher'")

    print("\n🎯 LinkWatcher will monitor THIS project directory for file changes")
    print("   and automatically update links when files are moved or renamed!")


if __name__ == "__main__":
    main()
