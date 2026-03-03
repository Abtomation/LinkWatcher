#!/usr/bin/env python3
"""
CI/CD Setup Script for LinkWatcher

This script helps set up the CI/CD environment and validates the configuration.
"""

import os
import subprocess
import sys
from pathlib import Path


def run_command(cmd, description="", check=True):
    """Run a command and return the result."""
    print(f"🔧 {description}")
    print(f"   Command: {' '.join(cmd)}")

    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=check)
        if result.stdout:
            print(f"   Output: {result.stdout.strip()}")
        return result.returncode == 0
    except subprocess.CalledProcessError as e:
        print(f"   Error: {e}")
        if e.stdout:
            print(f"   Stdout: {e.stdout}")
        if e.stderr:
            print(f"   Stderr: {e.stderr}")
        return False


def check_prerequisites():
    """Check if required tools are installed."""
    print("📋 Checking Prerequisites...")

    tools = [
        ("python", ["python", "--version"]),
        ("pip", ["pip", "--version"]),
        ("git", ["git", "--version"]),
    ]

    all_good = True
    for tool, cmd in tools:
        if run_command(cmd, f"Checking {tool}", check=False):
            print(f"   ✅ {tool} is available")
        else:
            print(f"   ❌ {tool} is not available")
            all_good = False

    return all_good


def install_dependencies():
    """Install required dependencies."""
    print("\n📦 Installing Dependencies...")

    # Install main dependencies
    if not run_command(
        ["pip", "install", "-r", "requirements.txt"], "Installing main dependencies"
    ):
        return False

    # Install test dependencies
    if not run_command(
        ["pip", "install", "-r", "requirements-test.txt"], "Installing test dependencies"
    ):
        return False

    # Install development dependencies
    dev_packages = [
        "black>=23.0.0",
        "isort>=5.12.0",
        "flake8>=6.0.0",
        "mypy>=1.0.0",
        "pre-commit>=3.0.0",
        "build>=0.10.0",
        "twine>=4.0.0",
    ]

    if not run_command(["pip", "install"] + dev_packages, "Installing development tools"):
        return False

    print("   ✅ All dependencies installed")
    return True


def setup_pre_commit():
    """Set up pre-commit hooks."""
    print("\n🪝 Setting up Pre-commit Hooks...")

    if not run_command(["pre-commit", "install"], "Installing pre-commit hooks"):
        return False

    if not run_command(
        ["pre-commit", "install", "--hook-type", "commit-msg"], "Installing commit-msg hooks"
    ):
        return False

    print("   ✅ Pre-commit hooks installed")
    return True


def validate_configuration():
    """Validate CI/CD configuration files."""
    print("\n🔍 Validating Configuration...")

    required_files = [
        ".github/workflows/ci.yml",
        ".pre-commit-config.yaml",
        "pyproject.toml",
        "pytest.ini",
        "requirements-test.txt",
    ]

    all_good = True
    for file_path in required_files:
        if Path(file_path).exists():
            print(f"   ✅ {file_path} exists")
        else:
            print(f"   ❌ {file_path} missing")
            all_good = False

    return all_good


def run_test_suite():
    """Run a quick test to validate setup."""
    print("\n🧪 Running Test Validation...")

    # Test discovery
    if not run_command(["python", "run_tests.py", "--discover"], "Running test discovery"):
        return False

    # Quick tests
    if not run_command(["python", "run_tests.py", "--quick"], "Running quick tests", check=False):
        print("   ⚠️  Some tests failed, but setup is functional")
    else:
        print("   ✅ Quick tests passed")

    return True


def check_git_setup():
    """Check Git configuration."""
    print("\n📝 Checking Git Setup...")

    # Check if we're in a git repository
    if not run_command(["git", "status"], "Checking git repository", check=False):
        print("   ⚠️  Not in a git repository")
        return False

    # Check for GitHub remote
    result = subprocess.run(["git", "remote", "-v"], capture_output=True, text=True)
    if "github.com" in result.stdout:
        print("   ✅ GitHub remote configured")
    else:
        print("   ⚠️  No GitHub remote found")

    return True


def main():
    """Main setup function."""
    print("🚀 LinkWatcher CI/CD Setup")
    print("=" * 50)

    # Change to project root
    project_root = Path(__file__).parent.parent
    os.chdir(project_root)
    print(f"📁 Working directory: {project_root}")

    steps = [
        ("Prerequisites", check_prerequisites),
        ("Dependencies", install_dependencies),
        ("Pre-commit", setup_pre_commit),
        ("Configuration", validate_configuration),
        ("Git Setup", check_git_setup),
        ("Test Suite", run_test_suite),
    ]

    results = {}
    for step_name, step_func in steps:
        try:
            results[step_name] = step_func()
        except Exception as e:
            print(f"   ❌ Error in {step_name}: {e}")
            results[step_name] = False

    # Summary
    print("\n" + "=" * 50)
    print("📊 Setup Summary:")

    all_passed = True
    for step_name, passed in results.items():
        status = "✅ PASS" if passed else "❌ FAIL"
        print(f"   {step_name}: {status}")
        if not passed:
            all_passed = False

    if all_passed:
        print("\n🎉 CI/CD setup completed successfully!")
        print("\nNext steps:")
        print("1. Commit your changes: git add . && git commit -m 'feat: add CI/CD pipeline'")
        print("2. Push to GitHub: git push")
        print("3. Check GitHub Actions tab for pipeline execution")
        print("4. Set up branch protection rules (optional)")
    else:
        print("\n⚠️  Setup completed with some issues.")
        print("Please review the failed steps above.")
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
