#!/usr/bin/env python3
"""
Global Installation Script for LinkWatcher

This script installs LinkWatcher as a global tool that can be used from any project directory.
"""

import os
import shutil
import subprocess
import sys
from pathlib import Path


def check_python_version():
    """Check if Python version is compatible."""
    if sys.version_info < (3, 7):
        print("ERROR: Python 3.7 or higher is required")
        return False
    print(f"OK: Python {sys.version.split()[0]} detected")
    return True


def install_dependencies():
    """Install required Python packages."""
    print("\nInstalling dependencies...")

    # Look for requirements.txt in the parent directory (project root)
    requirements_file = Path(__file__).parent.parent / "requirements.txt"

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


def get_install_directory():
    """Get the directory where LinkWatcher should be installed."""
    # Try to find a good location for the tools
    possible_locations = [
        Path.home() / "bin",
        Path.home() / "tools",
        Path.home() / "scripts",
        Path.home() / ".local" / "bin",
    ]

    for location in possible_locations:
        if location.exists() or location.parent.exists():
            return location

    # Default to home directory
    return Path.home() / "LinkWatcher"


def install_linkwatcher():
    """Install LinkWatcher to a global location."""
    source_dir = Path(__file__).parent.parent  # Go to project root
    install_dir = get_install_directory()

    print(f"\nInstalling LinkWatcher to: {install_dir}")

    # Create install directory
    install_dir.mkdir(parents=True, exist_ok=True)

    # Copy core files and directories
    core_files = [
        "main.py",
        "scripts/check_links.py", 
        "requirements.txt"
    ]
    
    core_dirs = [
        "linkwatcher",
        "config-examples"
    ]

    # Copy files
    for file_name in core_files:
        source_file = source_dir / file_name
        dest_file = install_dir / file_name
        
        # Create parent directory if needed
        dest_file.parent.mkdir(parents=True, exist_ok=True)

        if source_file.exists():
            shutil.copy2(source_file, dest_file)
            print(f"   ✅ Copied: {file_name}")
        else:
            print(f"   ❌ Missing: {file_name}")
            return False
    
    # Copy directories
    for dir_name in core_dirs:
        source_dir_path = source_dir / dir_name
        dest_dir_path = install_dir / dir_name
        
        if source_dir_path.exists():
            # Remove existing directory or file if it exists
            if dest_dir_path.exists():
                if dest_dir_path.is_dir():
                    shutil.rmtree(dest_dir_path)
                else:
                    dest_dir_path.unlink()  # Remove file
            shutil.copytree(source_dir_path, dest_dir_path)
            print(f"   ✅ Copied directory: {dir_name}")
        else:
            print(f"   ❌ Missing directory: {dir_name}")

    return install_dir


def create_wrapper_scripts(install_dir):
    """Create wrapper scripts for easy execution."""

    scripts_created = []

    # Windows batch script
    batch_script = install_dir / "linkwatcher.bat"
    batch_content = f"""@echo off
python "{install_dir / 'main.py'}" %*
"""

    try:
        with open(batch_script, "w") as f:
            f.write(batch_content)
        scripts_created.append(str(batch_script))
    except Exception as e:
        print(f"   ⚠️  Could not create {batch_script}: {e}")

    # PowerShell script
    ps_script = install_dir / "linkwatcher.ps1"
    ps_content = f"""# LinkWatcher Wrapper Script
python "{install_dir / 'main.py'}" @args
"""

    try:
        with open(ps_script, "w") as f:
            f.write(ps_content)
        scripts_created.append(str(ps_script))
    except Exception as e:
        print(f"   ⚠️  Could not create {ps_script}: {e}")

    # Shell script for Unix-like systems (skip on Windows if there's a conflict)
    shell_script = install_dir / "linkwatcher_sh"  # Use different name to avoid conflicts
    shell_content = f"""#!/bin/bash
python3 "{install_dir / 'main.py'}" "$@"
"""

    try:
        with open(shell_script, "w") as f:
            f.write(shell_content)
        
        # Make shell script executable on Unix-like systems
        if os.name != "nt":
            os.chmod(shell_script, 0o755)
        scripts_created.append(str(shell_script))
    except Exception as e:
        print(f"   ⚠️  Could not create {shell_script}: {e}")

    # Check links wrapper
    check_batch = install_dir / "checklinks.bat"
    check_batch_content = f"""@echo off
python "{install_dir / 'scripts/check_links.py'}" %*
"""

    try:
        with open(check_batch, "w") as f:
            f.write(check_batch_content)
        scripts_created.append(str(check_batch))
    except Exception as e:
        print(f"   ⚠️  Could not create {check_batch}: {e}")

    check_shell = install_dir / "checklinks_sh"  # Use different name to avoid conflicts
    check_shell_content = f"""#!/bin/bash
python3 "{install_dir / 'scripts/check_links.py'}" "$@"
"""

    try:
        with open(check_shell, "w") as f:
            f.write(check_shell_content)
        
        if os.name != "nt":
            os.chmod(check_shell, 0o755)
        scripts_created.append(str(check_shell))
    except Exception as e:
        print(f"   ⚠️  Could not create {check_shell}: {e}")

    if scripts_created:
        print("OK: Wrapper scripts created:")
        for script in scripts_created:
            print(f"   - {script}")
    else:
        print("⚠️  Warning: No wrapper scripts could be created")

    return install_dir


def test_installation(install_dir):
    """Test if the installation works."""
    print("\nTesting installation...")

    try:
        # Test the main script
        result = subprocess.run(
            [sys.executable, str(install_dir / "main.py"), "--help"],
            capture_output=True,
            text=True,
        )

        if result.returncode == 0:
            print("OK: LinkWatcher script runs successfully")

            # Test check links
            result2 = subprocess.run(
                [sys.executable, str(install_dir / "scripts/check_links.py"), "--help"],
                capture_output=True,
                text=True,
            )

            if result2.returncode == 0:
                print("OK: Check links script runs successfully")
                return True
            else:
                print(f"ERROR: Check links script failed: {result2.stderr}")
                return False
        else:
            print(f"ERROR: LinkWatcher script failed: {result.stderr}")
            return False

    except Exception as e:
        print(f"ERROR: Test failed: {e}")
        return False


def main():
    """Main installation function."""
    print("LinkWatcher Global Installation")
    print("=" * 40)

    # Check Python version
    if not check_python_version():
        sys.exit(1)

    # Install dependencies
    if not install_dependencies():
        print("\nERROR: Installation failed during dependency installation")
        sys.exit(1)

    # Install LinkWatcher
    install_dir = install_linkwatcher()
    if not install_dir:
        print("\nERROR: Installation failed during file copying")
        sys.exit(1)

    # Create wrapper scripts
    create_wrapper_scripts(install_dir)

    # Test installation
    if not test_installation(install_dir):
        print("\nERROR: Installation completed but tests failed")
        print("You may need to troubleshoot the installation")
        sys.exit(1)

    print("\n" + "=" * 50)
    print("🎉 LinkWatcher installed successfully!")
    print("=" * 50)

    print(f"\nInstallation directory: {install_dir}")

    print("\n📋 Usage from any project:")
    print("1. Navigate to your project directory:")
    print("   cd /path/to/your/project")
    print()
    print("2. Start LinkWatcher:")
    if os.name == "nt":
        print(f"   python \"{install_dir / 'main.py'}\"")
        print(f"   # Or if {install_dir} is in your PATH:")
        print("   linkwatcher.bat")
    else:
        print(f"   python3 \"{install_dir / 'main.py'}\"")
        print(f"   # Or if {install_dir} is in your PATH:")
        print("   linkwatcher")

    print()
    print("3. Check links in current project:")
    if os.name == "nt":
        print(f"   python \"{install_dir / 'scripts/check_links.py'}\"")
        print("   checklinks.bat")
    else:
        print(f"   python3 \"{install_dir / 'scripts/check_links.py'}\"")
        print("   checklinks")

    print(f"\n💡 Tip: Add {install_dir} to your PATH environment variable")
    print("   to use 'linkwatcher' and 'checklinks' commands from anywhere!")

    print("\n🔗 The tool will automatically monitor the current directory")
    print("   where you run it from, regardless of where it's installed.")


if __name__ == "__main__":
    main()
