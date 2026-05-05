#!/usr/bin/env python3
"""
Global Installation Script for LinkWatcher

Installs LinkWatcher to a global location (default: ~/bin) so it can be
used from any project directory. The agnostic startup script in
process-framework/tools/linkWatcher/ auto-detects this install location at
runtime; no per-project script regeneration is needed.

Usage:
    python deployment/install_global.py [--install-dir DIR]
"""

import argparse
import shutil
import signal
import subprocess
import sys
from pathlib import Path

# Default install location
DEFAULT_INSTALL_DIR = Path.home() / "bin"


def stop_running_linkwatcher(project_root):
    """Stop any running LinkWatcher instance before installation.

    Reads .linkwatcher.lock to find the PID and terminates the process.
    This prevents Permission denied errors when overwriting venv files.
    """
    lock_file = project_root / ".linkwatcher.lock"
    if not lock_file.exists():
        return

    try:
        pid = int(lock_file.read_text().strip())
    except (ValueError, OSError):
        return

    import os
    import platform

    try:
        if platform.system() == "Windows":
            subprocess.run(
                ["taskkill", "/F", "/PID", str(pid)],
                capture_output=True,
            )
        else:
            os.kill(pid, signal.SIGTERM)
        print(f"OK: Stopped running LinkWatcher (PID: {pid})")
    except (ProcessLookupError, PermissionError, OSError):
        pass

    # Clean up lock file
    try:
        lock_file.unlink(missing_ok=True)
    except OSError:
        pass


def check_python_version():
    """Check if Python version is compatible."""
    if sys.version_info < (3, 8):
        print("ERROR: Python 3.8 or higher is required")
        return False
    print(f"OK: Python {sys.version.split()[0]} detected")
    return True


def install_dependencies(project_root):
    """Install required Python packages from pyproject.toml."""
    print("\nInstalling dependencies...")

    try:
        subprocess.run(
            [sys.executable, "-m", "pip", "install", "-e", str(project_root)],
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
        "pyproject.toml",
    ]

    # Core directories to copy (full replacement)
    # (source_path, dest_name) — source relative to project_root, dest is flat name in install_dir
    core_dirs = [
        ("src/linkwatcher", "linkwatcher"),
        ("config-examples", "config-examples"),
    ]

    # Optional files (copy if they exist, skip silently if not)
    optional_files = []

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
    for source_name, dest_name in core_dirs:
        source_dir_path = project_root / source_name
        dest_dir_path = install_dir / dest_name

        if source_dir_path.exists():
            if dest_dir_path.exists():
                shutil.rmtree(dest_dir_path)
            shutil.copytree(
                source_dir_path,
                dest_dir_path,
                ignore=shutil.ignore_patterns("__pycache__", "*.pyc"),
            )
            print(f"   Copied directory: {source_name} -> {dest_name}")
        else:
            print(f"   WARNING: Directory not found: {source_name}")

    return True


def create_linkwatcher_venv(install_dir):
    """Create a dedicated virtual environment for LinkWatcher.

    PD-BUG-077: Using bare 'python' in wrapper/startup scripts resolves to a
    project's .venv in projects with virtual environments, causing silent import
    failures. A dedicated venv ensures LinkWatcher always has its dependencies.
    """
    venv_dir = install_dir / ".linkwatcher-venv"
    venv_python = venv_dir / "Scripts" / "python.exe"
    requirements = install_dir / "requirements.txt"

    print(f"\nCreating dedicated LinkWatcher venv at: {venv_dir}")

    # Create venv
    try:
        subprocess.run(
            [sys.executable, "-m", "venv", str(venv_dir)],
            check=True,
            capture_output=True,
            text=True,
        )
    except subprocess.CalledProcessError as e:
        print(f"ERROR: Failed to create venv: {e.stderr}")
        return False

    # Install dependencies — prefer requirements.txt, fall back to pyproject.toml
    try:
        subprocess.run(
            [str(venv_python), "-m", "pip", "install", "--upgrade", "pip", "--quiet"],
            check=True,
            capture_output=True,
            text=True,
        )
        if requirements.exists():
            subprocess.run(
                [str(venv_python), "-m", "pip", "install", "-r", str(requirements), "--quiet"],
                check=True,
                capture_output=True,
                text=True,
            )
        else:
            # Fall back to installing from pyproject.toml in install dir
            subprocess.run(
                [str(venv_python), "-m", "pip", "install", str(install_dir), "--quiet"],
                check=True,
                capture_output=True,
                text=True,
            )
    except subprocess.CalledProcessError as e:
        print(f"ERROR: Failed to install dependencies into venv: {e.stderr}")
        return False

    # Verify
    try:
        result = subprocess.run(
            [str(venv_python), "-c", "import watchdog; import yaml; import git; print('OK')"],
            capture_output=True,
            text=True,
        )
        if result.stdout.strip() == "OK":
            print("OK: LinkWatcher venv created and verified")
            return True
        else:
            print(f"ERROR: Venv verification failed: {result.stderr}")
            return False
    except Exception as e:
        print(f"ERROR: Venv verification failed: {e}")
        return False


def create_wrapper_scripts(install_dir):
    """Create wrapper scripts for easy execution.

    PD-BUG-077: All wrappers use the dedicated .linkwatcher-venv Python
    instead of bare 'python' to avoid resolving to a project's .venv.
    """
    scripts_created = []

    # Use venv Python path in all wrappers
    venv_python_rel = r".linkwatcher-venv\Scripts\python.exe"

    wrappers = {
        "linkwatcher.bat": (
            f"@echo off\n"
            f"REM PD-BUG-077: Use dedicated venv Python instead of bare python\n"
            f'set "LWPYTHON=%~dp0{venv_python_rel}"\n'
            f'if not exist "%LWPYTHON%" (\n'
            f"    echo Error: LinkWatcher venv not found."
            f" Run: python deployment/install_global.py\n"
            f"    exit /b 1\n"
            f")\n"
            f'"%LWPYTHON%" "%~dp0main.py" %*\n'
        ),
        "linkwatcher.ps1": (
            f"# LinkWatcher Wrapper Script\n"
            f"# PD-BUG-077: Use dedicated venv Python instead of bare 'python'\n"
            f'$lwVenvPython = Join-Path $PSScriptRoot "{venv_python_rel}"\n'
            f"if (-not (Test-Path $lwVenvPython)) {{\n"
            f'    Write-Host "Error: LinkWatcher venv not found. Run: python deployment/install_global.py" -ForegroundColor Red\n'  # noqa: E501
            f"    exit 1\n"
            f"}}\n"
            f'& $lwVenvPython "$PSScriptRoot\\main.py" @args\n'
        ),
    }

    # Add check_links wrappers only if check_links.py exists
    if (install_dir / "scripts" / "check_links.py").exists():
        wrappers["checklinks.bat"] = (
            f"@echo off\n"
            f"REM PD-BUG-077: Use dedicated venv Python instead of bare python\n"
            f'set "LWPYTHON=%~dp0{venv_python_rel}"\n'
            f'if not exist "%LWPYTHON%" (\n'
            f"    echo Error: LinkWatcher venv not found."
            f" Run: python deployment/install_global.py\n"
            f"    exit /b 1\n"
            f")\n"
            f'"%LWPYTHON%" "%~dp0scripts\\check_links.py" %*\n'
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


def test_installation(install_dir):
    """Test if the installation works using the dedicated venv Python."""
    print("\nTesting installation...")

    venv_python = install_dir / ".linkwatcher-venv" / "Scripts" / "python.exe"
    python_exe = str(venv_python) if venv_python.exists() else sys.executable

    try:
        result = subprocess.run(
            [python_exe, str(install_dir / "main.py"), "--help"],
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

    stop_running_linkwatcher(project_root)

    if not check_python_version():
        sys.exit(1)

    if not install_dependencies(project_root):
        print("\nERROR: Installation failed during dependency installation")
        sys.exit(1)

    if not install_linkwatcher(project_root, install_dir):
        print("\nERROR: Installation failed during file copying")
        sys.exit(1)

    if not create_linkwatcher_venv(install_dir):
        print("\nERROR: Failed to create dedicated LinkWatcher venv")
        sys.exit(1)

    create_wrapper_scripts(install_dir)

    if not test_installation(install_dir):
        print("\nERROR: Installation completed but tests failed")
        sys.exit(1)

    print("\n" + "=" * 50)
    print("LinkWatcher installed successfully!")
    print("=" * 50)
    print(f"\nInstallation directory: {install_dir}")
    print(f"\nUsage: python \"{install_dir / 'main.py'}\"")
    print("Or run the agnostic startup script:")
    print(r"  pwsh.exe -File process-framework\tools\linkWatcher\start_linkwatcher_background.ps1")


if __name__ == "__main__":
    main()
