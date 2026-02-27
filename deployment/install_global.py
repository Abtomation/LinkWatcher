#!/usr/bin/env python3
"""
Global Installation Script for LinkWatcher

Installs LinkWatcher to a global location (default: ~/bin) so it can be
used from any project directory. Also updates the startup scripts in
LinkWatcher_run/ to point to the install location.

Usage:
    python deployment/install_global.py [--install-dir DIR]
"""

import argparse
import os
import shutil
import subprocess
import sys
from pathlib import Path

# Default install location
DEFAULT_INSTALL_DIR = Path.home() / "bin"


def check_python_version():
    """Check if Python version is compatible."""
    if sys.version_info < (3, 8):
        print("ERROR: Python 3.8 or higher is required")
        return False
    print(f"OK: Python {sys.version.split()[0]} detected")
    return True


def install_dependencies(project_root):
    """Install required Python packages."""
    print("\nInstalling dependencies...")

    requirements_file = project_root / "requirements.txt"

    try:
        subprocess.run(
            [sys.executable, "-m", "pip", "install", "-r", str(requirements_file)],
            check=True,
            capture_output=True,
            text=True,
        )
        print("OK: Dependencies installed successfully")
        return True
    except subprocess.CalledProcessError as e:
        print(f"ERROR: Failed to install dependencies: {e}")
        print(f"Error output: {e.stderr}")
        return False


def clean_stale_files(install_dir):
    """Remove known stale files from previous installations."""
    stale_files = [
        "link_watcher.py",
        "link_watcher_new.py",
        "checklinks",
        "linkwatcher_sh",
        "checklinks_sh",
    ]
    stale_dirs = [
        "__pycache__",
    ]

    for name in stale_files:
        path = install_dir / name
        if path.exists():
            path.unlink()
            print(f"   Removed stale file: {name}")

    for name in stale_dirs:
        path = install_dir / name
        if path.is_dir():
            shutil.rmtree(path)
            print(f"   Removed stale directory: {name}")


def install_linkwatcher(project_root, install_dir):
    """Copy LinkWatcher files to the install directory."""
    print(f"\nInstalling LinkWatcher to: {install_dir}")

    install_dir.mkdir(parents=True, exist_ok=True)

    # Clean up stale files from previous installs
    clean_stale_files(install_dir)

    # Core files to copy (relative to project root)
    core_files = [
        "main.py",
        "requirements.txt",
    ]

    # Core directories to copy (full replacement)
    core_dirs = [
        "linkwatcher",
        "config-examples",
    ]

    # Optional files (copy if they exist, skip silently if not)
    optional_files = [
        "scripts/check_links.py",
    ]

    # Copy required files
    for file_name in core_files:
        source_file = project_root / file_name
        dest_file = install_dir / file_name

        if source_file.exists():
            shutil.copy2(source_file, dest_file)
            print(f"   Copied: {file_name}")
        else:
            print(f"   ERROR: Required file missing: {file_name}")
            return False

    # Copy optional files
    for file_name in optional_files:
        source_file = project_root / file_name
        dest_file = install_dir / file_name

        dest_file.parent.mkdir(parents=True, exist_ok=True)

        if source_file.exists():
            shutil.copy2(source_file, dest_file)
            print(f"   Copied: {file_name}")
        else:
            print(f"   Skipped (not found): {file_name}")

    # Copy directories (full replacement to avoid stale .pyc etc.)
    for dir_name in core_dirs:
        source_dir_path = project_root / dir_name
        dest_dir_path = install_dir / dir_name

        if source_dir_path.exists():
            if dest_dir_path.exists():
                shutil.rmtree(dest_dir_path)
            shutil.copytree(
                source_dir_path,
                dest_dir_path,
                ignore=shutil.ignore_patterns("__pycache__", "*.pyc"),
            )
            print(f"   Copied directory: {dir_name}")
        else:
            print(f"   WARNING: Directory not found: {dir_name}")

    return True


def create_wrapper_scripts(install_dir):
    """Create wrapper scripts for easy execution."""
    scripts_created = []

    wrappers = {
        "linkwatcher.bat": f'@echo off\npython "{install_dir / "main.py"}" %*\n',
        "linkwatcher.ps1": f'# LinkWatcher Wrapper Script\npython "{install_dir / "main.py"}" @args\n',
    }

    # Add check_links wrappers only if check_links.py exists
    if (install_dir / "scripts" / "check_links.py").exists():
        wrappers["checklinks.bat"] = (
            f'@echo off\npython "{install_dir / "scripts" / "check_links.py"}" %*\n'
        )

    for name, content in wrappers.items():
        script_path = install_dir / name
        try:
            with open(script_path, "w") as f:
                f.write(content)
            scripts_created.append(name)
        except Exception as e:
            print(f"   WARNING: Could not create {name}: {e}")

    if scripts_created:
        print(f"OK: Wrapper scripts created: {', '.join(scripts_created)}")


def update_startup_scripts(project_root, install_dir):
    """Update LinkWatcher_run/ startup scripts to point to the install directory."""
    run_dir = project_root / "LinkWatcher_run"
    if not run_dir.exists():
        print("Skipping startup script update (LinkWatcher_run/ not found)")
        return

    main_py_path = install_dir / "main.py"

    scripts = {
        "start_linkwatcher.bat": (
            f"@echo off\n"
            f"echo Starting LinkWatcher for this project...\n"
            f'python "{main_py_path}"\n'
            f"pause\n"
        ),
        "start_linkwatcher.sh": (
            f"#!/bin/bash\n"
            f'echo "Starting LinkWatcher for this project..."\n'
            f'python3 "{main_py_path}"\n'
        ),
        "start_linkwatcher.ps1": (
            f"# LinkWatcher for this project\n"
            f'Write-Host "Starting LinkWatcher for this project..." -ForegroundColor Cyan\n'
            f'python "{main_py_path}"\n'
            f'Read-Host "Press Enter to exit"\n'
        ),
        "start_linkwatcher_background.ps1": (
            f"# LinkWatcher Background Starter for this project\n"
            f"\n"
            f"# Check if LinkWatcher is already running\n"
            f'$existingProcess = Get-Process -Name "python*" -ErrorAction SilentlyContinue |\n'
            f"    Where-Object {{\n"
            f"        try {{\n"
            f'            $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId = $($_.Id)" -ErrorAction SilentlyContinue).CommandLine\n'
            f'            $cmdLine -and $cmdLine -match "main\\.py"\n'
            f"        }} catch {{\n"
            f"            $false\n"
            f"        }}\n"
            f"    }}\n"
            f"\n"
            f"if ($existingProcess) {{\n"
            f'    Write-Host "LinkWatcher is already running (PID: $($existingProcess.Id -join \', \'))" -ForegroundColor Yellow\n'
            f'    Write-Host "Not starting a new instance." -ForegroundColor Yellow\n'
            f"    return\n"
            f"}}\n"
            f"\n"
            f'Write-Host "Starting LinkWatcher in background for this project..." -ForegroundColor Cyan\n'
            f"\n"
            f"# Start the LinkWatcher in background using Start-Process\n"
            f'$process = Start-Process -FilePath "python" -ArgumentList "{main_py_path}" -WindowStyle Hidden -PassThru\n'
            f"\n"
            f"if ($process) {{\n"
            f'    Write-Host "LinkWatcher started successfully in background (PID: $($process.Id))" -ForegroundColor Green\n'
            f"}} else {{\n"
            f'    Write-Host "Failed to start LinkWatcher" -ForegroundColor Red\n'
            f"}}\n"
        ),
    }

    updated = []
    for name, content in scripts.items():
        script_path = run_dir / name
        try:
            with open(script_path, "w") as f:
                f.write(content)
            updated.append(name)
        except Exception as e:
            print(f"   WARNING: Could not update {name}: {e}")

    if updated:
        print(f"OK: Startup scripts updated: {', '.join(updated)}")


def test_installation(install_dir):
    """Test if the installation works."""
    print("\nTesting installation...")

    try:
        result = subprocess.run(
            [sys.executable, str(install_dir / "main.py"), "--help"],
            capture_output=True,
            text=True,
        )

        if result.returncode == 0:
            print("OK: LinkWatcher runs successfully")
            return True
        else:
            print(f"ERROR: LinkWatcher failed: {result.stderr}")
            return False

    except Exception as e:
        print(f"ERROR: Test failed: {e}")
        return False


def main():
    """Main installation function."""
    parser = argparse.ArgumentParser(description="Install LinkWatcher globally")
    parser.add_argument(
        "--install-dir",
        type=Path,
        default=DEFAULT_INSTALL_DIR,
        help=f"Installation directory (default: {DEFAULT_INSTALL_DIR})",
    )
    args = parser.parse_args()

    install_dir = args.install_dir.resolve()
    project_root = Path(__file__).parent.parent.resolve()

    print("LinkWatcher Global Installation")
    print("=" * 40)
    print(f"Source:  {project_root}")
    print(f"Target:  {install_dir}")

    if not check_python_version():
        sys.exit(1)

    if not install_dependencies(project_root):
        print("\nERROR: Installation failed during dependency installation")
        sys.exit(1)

    if not install_linkwatcher(project_root, install_dir):
        print("\nERROR: Installation failed during file copying")
        sys.exit(1)

    create_wrapper_scripts(install_dir)
    update_startup_scripts(project_root, install_dir)

    if not test_installation(install_dir):
        print("\nERROR: Installation completed but tests failed")
        sys.exit(1)

    print("\n" + "=" * 50)
    print("LinkWatcher installed successfully!")
    print("=" * 50)
    print(f"\nInstallation directory: {install_dir}")
    print(f"\nUsage: python \"{install_dir / 'main.py'}\"")
    print("Or use the startup scripts in LinkWatcher_run/")


if __name__ == "__main__":
    main()
