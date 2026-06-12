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
import platform
import re
import shutil
import signal
import subprocess
import sys
from pathlib import Path

# Default install location
DEFAULT_INSTALL_DIR = Path.home() / "bin"

# Core directories to copy (full replacement)
# (source_path, dest_path) — source relative to project_root, dest relative to
# install_dir (may be nested; copytree creates intermediate directories).
# doc/user/handbooks must keep its repo-relative structure (PD-BUG-104): the
# per-project config template points at
# <install>/doc/user/handbooks/configuration-guide.md, and the handbooks
# cross-link each other with absolute-from-root paths.
CORE_DIRS = [
    ("src/linkwatcher", "linkwatcher"),
    ("config-examples", "config-examples"),
    ("doc/user/handbooks", "doc/user/handbooks"),
]


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


def parse_daemon_lines(output):
    """Parse 'PID|CommandLine' lines from the daemon enumeration query.

    Tolerates blank lines and malformed entries (skipped) so a noisy
    PowerShell stdout can never crash the install.
    """
    processes = []
    for line in output.splitlines():
        line = line.strip()
        if not line or "|" not in line:
            continue
        pid_part, _, cmdline = line.partition("|")
        try:
            pid = int(pid_part)
        except ValueError:
            continue
        processes.append((pid, cmdline.strip()))
    return processes


def project_root_from_cmdline(cmdline):
    """Extract the --project-root value from a daemon command line, or None."""
    match = re.search(r'--project-root\s+"([^"]+)"', cmdline)
    return match.group(1) if match else None


def find_venv_daemon_processes(venv_dir):
    """Find ALL processes running from the install-dir venv (PD-BUG-106).

    Lock files only cover the source project's daemon; daemons started for
    other projects run from the same shared venv and are found here by
    executable path (covers python.exe and pythonw.exe). Returns a list of
    (pid, command_line); empty on any query failure (best-effort — the
    venv_python_locked pre-flight gate is the safety net).
    """
    ps_script = (
        "Get-CimInstance Win32_Process | "
        f"Where-Object {{ $_.ExecutablePath -like '{venv_dir}*' }} | "
        'ForEach-Object { "$($_.ProcessId)|$($_.CommandLine)" }'
    )
    try:
        result = subprocess.run(
            ["powershell", "-NoProfile", "-Command", ps_script],
            capture_output=True,
            text=True,
        )
    except (OSError, subprocess.SubprocessError):
        return []
    if result.returncode != 0:
        return []
    return parse_daemon_lines(result.stdout)


def stop_daemons_using_venv(install_dir):
    """Stop every LinkWatcher daemon running from the install-dir venv (PD-BUG-106).

    Windows locks the executable of a running process, so any daemon running
    from <install_dir>/.linkwatcher-venv blocks the venv rebuild with
    Permission denied. taskkill /T tree-kills: the venv-shim parent spawns a
    base-interpreter child that must go down with it. Stopped daemons restart
    at the next session start of their project; stale lock files are
    self-healed by daemon startup.
    """
    if platform.system() != "Windows":
        return
    venv_dir = install_dir / ".linkwatcher-venv"
    if not venv_dir.exists():
        return

    for pid, cmdline in find_venv_daemon_processes(venv_dir):
        subprocess.run(
            ["taskkill", "/F", "/T", "/PID", str(pid)],
            capture_output=True,
        )
        print(f"OK: Stopped LinkWatcher daemon using install venv (PID: {pid})")
        project_root = project_root_from_cmdline(cmdline)
        if project_root:
            print(f"   Project: {project_root} (daemon restarts at next session start)")


def venv_python_locked(install_dir):
    """Pre-flight gate: is the venv python.exe still locked by a process?

    Run AFTER stop_daemons_using_venv and BEFORE any files are copied — if a
    process slipped past enumeration, aborting here leaves no partial install
    state (the v2.1.1 failure mode aborted mid-flow: files copied, no
    venv/wrappers/smoke test).
    """
    venv_python = install_dir / ".linkwatcher-venv" / "Scripts" / "python.exe"
    if not venv_python.exists():
        return False
    try:
        with venv_python.open("ab"):
            pass
        return False
    except PermissionError:
        return True


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
    for source_name, dest_name in CORE_DIRS:
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


def propagate_config_schema_signal(project_root):
    """Best-effort: detect a per-project config-schema change and signal it downstream.

    LinkWatcher is the upstream source of the project-configurable validation
    config schema; at release it diffs that schema against the framework template
    and, on a change, files a high-priority IMP + syncs the framework template.
    Non-fatal — never blocks the install. See deployment/propagate_config_schema.py
    (PD-FRQ-006 / PF-PRO-039 Fork 1).
    """
    try:
        sys.path.insert(0, str(Path(__file__).parent))
        import propagate_config_schema

        propagate_config_schema.propagate(project_root)
    except Exception as e:  # noqa: BLE001 — propagation must never fail the release
        print(f"   WARNING: config-schema propagation step errored (non-fatal): {e}")


def read_deployed_version(init_path):
    """Parse __version__ from a linkwatcher __init__.py.

    Returns the version string, or None if the file is unreadable or has no
    __version__ line. Parsing (rather than importing) keeps this side-effect-free
    and testable without an installed package.
    """
    try:
        text = Path(init_path).read_text(encoding="utf-8")
    except OSError:
        return None
    match = re.search(r'^__version__\s*=\s*["\']([^"\']+)["\']', text, re.MULTILINE)
    return match.group(1) if match else None


def git_tags(project_root):
    """Return the repo's git tags as a set, or None if git is unavailable.

    A None result (not a repo, git not installed, command failed) suppresses the
    release-tag warning — we only warn when we can affirmatively read the tags.
    """
    try:
        result = subprocess.run(
            ["git", "-C", str(project_root), "tag", "--list"],
            capture_output=True,
            text=True,
        )
    except (OSError, subprocess.SubprocessError):
        return None
    if result.returncode != 0:
        return None
    return {line.strip() for line in result.stdout.splitlines() if line.strip()}


def release_tag_missing(version, tags):
    """Pure decision: should we warn about a missing release tag?

    Returns True only when the version is known, the tag set is known, and no
    'v<version>' tag is present. Returns False whenever either input is None — an
    undeterminable state must never produce a spurious warning.
    """
    if not version or tags is None:
        return False
    return f"v{version}" not in tags


def check_release_tag(project_root):
    """Warn (non-fatal) if the version being deployed has no matching git tag.

    The tag is created at release time, after the __version__ bump, so this is a
    nudge at the deploy step — deliberately not a hard gate, since it must never
    block a dev install of an as-yet-unreleased version. Mirrors the non-fatal
    contract of propagate_config_schema_signal (PF-IMP-1106).
    """
    version = read_deployed_version(project_root / "src" / "linkwatcher" / "__init__.py")
    if release_tag_missing(version, git_tags(project_root)):
        print(
            f"\nWARNING: deploying version {version} but no git tag 'v{version}' exists.\n"
            f"   If this is a release, create and push the tag:\n"
            f"       git tag v{version}\n"
            f"       git push origin v{version}"
        )


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
    stop_daemons_using_venv(install_dir)

    if venv_python_locked(install_dir):
        print(
            "\nERROR: The install venv's python.exe is still locked by a running"
            " process.\n"
            f"   Check for processes running from: {install_dir / '.linkwatcher-venv'}\n"
            "   No files were copied — the existing installation is unchanged."
        )
        sys.exit(1)

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

    propagate_config_schema_signal(project_root)

    check_release_tag(project_root)

    print("\n" + "=" * 50)
    print("LinkWatcher installed successfully!")
    print("=" * 50)
    print(f"\nInstallation directory: {install_dir}")
    print(f"\nUsage: python \"{install_dir / 'main.py'}\"")
    print("Or run the agnostic startup script:")
    print(r"  pwsh.exe -File process-framework\tools\linkWatcher\start_linkwatcher_background.ps1")


if __name__ == "__main__":
    main()
