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
    # Known working location
    known_location = Path(r"C:\Users\ronny\bin")
    if (known_location / "main.py").exists():
        return known_location
    
    # Fallback to search in common locations
    possible_locations = [
        Path.home() / "bin",
        Path.home() / "tools",
        Path.home() / "scripts",
        Path.home() / ".local" / "bin",
        Path.home() / "LinkWatcher",
    ]

    for location in possible_locations:
        if (location / "main.py").exists():
            return location

    return None


def create_vscode_tasks(linkwatcher_dir):
    """Create VS Code tasks for the current project."""
    # Create .vscode directory in the project root (parent of LinkWatcher directory)
    setup_script_dir = Path(__file__).parent
    project_root = setup_script_dir.parent
    vscode_dir = project_root / ".vscode"
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
                "args": [str(linkwatcher_dir / "main.py")],
                "group": "build",
                "presentation": {"echo": True, "reveal": "always", "focus": False, "panel": "new"},
                "problemMatcher": [],
                "detail": "Start LinkWatcher for this project",
            },
            {
                "label": "Check Links",
                "type": "shell",
                "command": "python",
                "args": [str(linkwatcher_dir / "scripts/check_links.py")],
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
    # Create scripts in the same directory as this setup script
    setup_script_dir = Path(__file__).parent
    linkwatcher_project_dir = setup_script_dir
    linkwatcher_project_dir.mkdir(exist_ok=True)

    # Windows batch script
    batch_script = linkwatcher_project_dir / "start_linkwatcher.bat"
    batch_content = f"""@echo off
echo Starting LinkWatcher for this project...
python "{linkwatcher_dir / 'main.py'}"
pause
"""

    with open(batch_script, "w") as f:
        f.write(batch_content)

    # PowerShell script
    ps_script = linkwatcher_project_dir / "start_linkwatcher.ps1"
    ps_content = f"""# LinkWatcher for this project
Write-Host "Starting LinkWatcher for this project..." -ForegroundColor Cyan
python "{linkwatcher_dir / 'main.py'}"
Read-Host "Press Enter to exit"
"""

    with open(ps_script, "w") as f:
        f.write(ps_content)

    # Shell script
    shell_script = linkwatcher_project_dir / "start_linkwatcher.sh"
    shell_content = f"""#!/bin/bash
echo "Starting LinkWatcher for this project..."
python3 "{linkwatcher_dir / 'main.py'}"
"""

    with open(shell_script, "w") as f:
        f.write(shell_content)

    # Python script for background execution (the one that works)
    python_script = linkwatcher_project_dir / "start_link_watcher.py"
    python_content = f'''#!/usr/bin/env python3
"""
Start the link watcher service with better debugging
"""

import subprocess
import sys
import os

def main():
    print("Starting Link Watcher Service...")
    
    # Use the actual working LinkWatcher
    linkwatcher_path = r"{linkwatcher_dir / 'main.py'}"
    
    try:
        # Run the actual working LinkWatcher
        subprocess.run([sys.executable, linkwatcher_path], check=True)
    except KeyboardInterrupt:
        print("\\nStopping service...")
    except Exception as e:
        print(f"Error starting LinkWatcher: {{e}}")

if __name__ == "__main__":
    main()
'''

    with open(python_script, "w") as f:
        f.write(python_content)

    # Make shell script executable on Unix-like systems
    if os.name != "nt":
        os.chmod(shell_script, 0o755)

    print("✅ Convenience scripts created in LinkWatcher directory:")
    print(f"   - {batch_script.name}")
    print(f"   - {ps_script.name}")
    print(f"   - {shell_script.name}")
    print(f"   - {python_script.name} (for background execution)")
    print(f"   Location: {linkwatcher_project_dir.resolve()}")


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
            if not (linkwatcher_dir / "main.py").exists():
                print(f"❌ ERROR: main.py not found in {linkwatcher_dir}")
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
    print("1. Start LinkWatcher in FOREGROUND (for debugging):")
    print(f"   python \"{linkwatcher_dir / 'main.py'}\"")
    print("   # Or use convenience scripts in LinkWatcher directory:")
    print("   ./LinkWatcher/start_linkwatcher.bat  (Windows)")
    print("   ./LinkWatcher/start_linkwatcher.sh   (Linux/Mac)")

    print("\n2. Start LinkWatcher in BACKGROUND (recommended):")
    print("   Start-Process -FilePath \"python\" -ArgumentList \"LinkWatcher/start_link_watcher.py\" -WindowStyle Hidden")
    print("   # Or use PowerShell script:")
    print("   ./LinkWatcher/start_linkwatcher.ps1")

    print("\n3. Check links:")
    print(f"   python \"{linkwatcher_dir / 'scripts/check_links.py'}\"")

    print("\n4. VS Code integration:")
    print("   Ctrl+Shift+P → 'Tasks: Run Task' → 'Start LinkWatcher'")

    print("\n🎯 LinkWatcher will monitor THIS project directory for file changes")
    print("   and automatically update links when files are moved or renamed!")
    print("\n⚠️  IMPORTANT: For AI agents, always use BACKGROUND mode to avoid blocking!")


if __name__ == "__main__":
    main()
