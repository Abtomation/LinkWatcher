#!/usr/bin/env python3
"""
Test runner script for LinkWatcher.

This script provides convenient ways to run different categories of tests
and generate reports.
"""

import argparse
import subprocess
import sys
from pathlib import Path


def run_command(cmd, description=""):
    """Run a command and return the result."""
    print(f"\n{'='*60}")
    if description:
        print(f"Running: {description}")
    print(f"Command: {' '.join(cmd)}")
    print("=" * 60)

    try:
        result = subprocess.run(cmd, capture_output=False, text=True)
        return result.returncode == 0
    except Exception as e:
        print(f"Error running command: {e}")
        return False


def run_unit_tests(verbose=False, coverage=False):
    """Run unit tests."""
    cmd = ["python", "-m", "pytest", "tests/unit/"]

    if verbose:
        cmd.append("-v")

    if coverage:
        cmd.extend(["--cov=linkwatcher", "--cov-report=html", "--cov-report=term"])

    return run_command(cmd, "Unit Tests")


def run_integration_tests(verbose=False):
    """Run integration tests."""
    cmd = ["python", "-m", "pytest", "tests/integration/"]

    if verbose:
        cmd.append("-v")

    return run_command(cmd, "Integration Tests")


def run_parser_tests(verbose=False):
    """Run parser-specific tests."""
    cmd = ["python", "-m", "pytest", "tests/parsers/"]

    if verbose:
        cmd.append("-v")

    return run_command(cmd, "Parser Tests")


def run_performance_tests(verbose=False):
    """Run performance tests."""
    cmd = ["python", "-m", "pytest", "tests/performance/", "-m", "slow"]

    if verbose:
        cmd.append("-v")

    return run_command(cmd, "Performance Tests")


def run_critical_tests(verbose=False):
    """Run only critical priority tests."""
    cmd = ["python", "-m", "pytest", "-m", "critical"]

    if verbose:
        cmd.append("-v")

    return run_command(cmd, "Critical Tests")


def run_all_tests(verbose=False, coverage=False):
    """Run all tests."""
    cmd = ["python", "-m", "pytest", "tests/"]

    if verbose:
        cmd.append("-v")

    if coverage:
        cmd.extend(["--cov=linkwatcher", "--cov-report=html", "--cov-report=term"])

    # Exclude slow tests by default
    cmd.extend(["-m", "not slow"])

    return run_command(cmd, "All Tests (excluding slow)")


def run_quick_tests(verbose=False):
    """Run a quick subset of tests for development."""
    cmd = ["python", "-m", "pytest", "tests/unit/", "tests/parsers/", "-x"]

    if verbose:
        cmd.append("-v")

    return run_command(cmd, "Quick Tests (unit + parsers)")


def generate_coverage_report():
    """Generate detailed coverage report."""
    cmd = [
        "python",
        "-m",
        "pytest",
        "tests/",
        "--cov=linkwatcher",
        "--cov-report=html",
        "--cov-report=term-missing",
        "--cov-report=xml",
    ]

    success = run_command(cmd, "Coverage Report Generation")

    if success:
        print("\n" + "=" * 60)
        print("Coverage reports generated:")
        print("- HTML report: htmlcov/index.html")
        print("- XML report: coverage.xml")
        print("=" * 60)

    return success


def run_test_discovery():
    """Run test discovery to check for issues."""
    cmd = ["python", "-m", "pytest", "--collect-only", "-q"]

    return run_command(cmd, "Test Discovery")


def run_linting():
    """Run code linting on test files."""
    try:
        # Try to run flake8 if available
        cmd = ["python", "-m", "flake8", "tests/", "--max-line-length=100"]
        return run_command(cmd, "Linting Tests")
    except:
        print("Flake8 not available, skipping linting")
        return True


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(description="LinkWatcher Test Runner")

    parser.add_argument("--unit", action="store_true", help="Run unit tests")
    parser.add_argument("--integration", action="store_true", help="Run integration tests")
    parser.add_argument("--parsers", action="store_true", help="Run parser tests")
    parser.add_argument("--performance", action="store_true", help="Run performance tests")
    parser.add_argument("--critical", action="store_true", help="Run critical tests only")
    parser.add_argument("--quick", action="store_true", help="Run quick test subset")
    parser.add_argument("--all", action="store_true", help="Run all tests")
    parser.add_argument("--coverage", action="store_true", help="Generate coverage report")
    parser.add_argument("--discover", action="store_true", help="Run test discovery")
    parser.add_argument("--lint", action="store_true", help="Run linting on tests")
    parser.add_argument("-v", "--verbose", action="store_true", help="Verbose output")

    args = parser.parse_args()

    # If no specific test type is specified, run quick tests
    if not any(
        [
            args.unit,
            args.integration,
            args.parsers,
            args.performance,
            args.critical,
            args.quick,
            args.all,
            args.coverage,
            args.discover,
            args.lint,
        ]
    ):
        args.quick = True

    success = True

    # Run test discovery first if requested
    if args.discover:
        success &= run_test_discovery()

    # Run linting if requested
    if args.lint:
        success &= run_linting()

    # Run specific test categories
    if args.unit:
        success &= run_unit_tests(args.verbose, args.coverage)

    if args.integration:
        success &= run_integration_tests(args.verbose)

    if args.parsers:
        success &= run_parser_tests(args.verbose)

    if args.performance:
        success &= run_performance_tests(args.verbose)

    if args.critical:
        success &= run_critical_tests(args.verbose)

    if args.quick:
        success &= run_quick_tests(args.verbose)

    if args.all:
        success &= run_all_tests(args.verbose, args.coverage)

    if args.coverage and not (args.unit or args.all):
        success &= generate_coverage_report()

    # Print summary
    print("\n" + "=" * 60)
    if success:
        print("✅ All tests completed successfully!")
    else:
        print("❌ Some tests failed!")
    print("=" * 60)

    return 0 if success else 1


if __name__ == "__main__":
    sys.exit(main())
