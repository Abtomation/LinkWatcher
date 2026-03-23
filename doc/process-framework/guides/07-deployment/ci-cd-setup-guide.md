---
id: PF-GDE-052
type: Document
category: General
version: 1.0
created: 2026-03-22
updated: 2026-03-22
guide_description: Guide for scaffolding CI/CD infrastructure in new or existing projects. Covers CI pipelines, pre-commit hooks, dev scripts, and code quality automation.
guide_status: Active
guide_category: 07-deployment
related_tasks: PF-TSK-014,PF-TSK-008
guide_title: CI-CD Setup Guide
---

# CI/CD Setup Guide

## Overview

Guide for scaffolding CI/CD infrastructure in new or existing projects. Covers CI pipelines, pre-commit hooks, dev scripts, and code quality automation.

## When to Use

- During **Project Initiation** — setting up development tooling for a new project
- During **Codebase Feature Discovery** — onboarding an existing project into the framework
- When adding **CI/CD to an existing project** that doesn't have it yet

## Prerequisites

- `project-config.json` exists with project name and language configured
- Language config exists in `languages-config/{language}-config.json`
- Git repository initialized
- Language-specific tools installed (e.g., `black`, `isort`, `flake8` for Python)

## Architecture

CI/CD infrastructure is **not a product feature** — it's development tooling that the framework provides as scaffolding. Each component is optional and depends on your project's needs:

| Component | Purpose | When to use |
|---|---|---|
| **Pre-commit hooks** | Enforce code quality before commits | Always recommended |
| **Dev script** | Shortcut commands for common tasks | Always recommended |
| **CI pipeline** | Automated testing on push/PR | When using GitHub/GitLab/etc. |
| **Startup scripts** | Launch the application | For long-running services |

## Step-by-Step Instructions

### 1. Set up pre-commit hooks

Create `.pre-commit-config.yaml` in project root:

#### Python

```yaml
repos:
  - repo: https://github.com/psf/black
    rev: 24.4.2
    hooks:
      - id: black
        args: ['--line-length=100']

  - repo: https://github.com/pycqa/isort
    rev: 5.13.2
    hooks:
      - id: isort
        args: ['--profile=black', '--line-length=100']

  - repo: https://github.com/pycqa/flake8
    rev: 7.0.0
    hooks:
      - id: flake8
        args: ['--max-line-length=100']

  - repo: local
    hooks:
      - id: quick-tests
        name: Quick Tests
        entry: python -m pytest test/automated/unit/ -x -q --tb=short
        language: system
        pass_filenames: false
        always_run: true
```

Install:

```bash
pip install pre-commit
pre-commit install
```

**Expected Result:** `git commit` runs black, isort, flake8, and quick tests before committing.

### 2. Create dev script

Create `dev.bat` (Windows) or `dev.sh` (Unix) for shortcut commands:

#### Windows (dev.bat)

```batch
@echo off
if "%1"=="test" python -m pytest test/automated/unit/ test/automated/parsers/ -x -q --tb=short
if "%1"=="test-all" python -m pytest test/automated/ -q --tb=short
if "%1"=="coverage" python -m pytest test/automated/ --cov=YOUR_MODULE --cov-report=html --cov-report=term-missing -q --tb=short
if "%1"=="lint" python -m flake8 YOUR_MODULE/ test/ --max-line-length=100
if "%1"=="format" black YOUR_MODULE/ test/ --line-length=100 && isort YOUR_MODULE/ test/ --profile=black --line-length=100
if "%1"=="dev-setup" pip install -e ".[test]" && pre-commit install
if "%1"=="" echo Usage: dev [test^|test-all^|coverage^|lint^|format^|dev-setup]
```

Replace `YOUR_MODULE` with the project's module name from `project-config.json`.

**Expected Result:** `dev test` runs quick tests, `dev lint` runs linting.

### 3. Set up CI pipeline (optional)

Only needed when pushing to a Git hosting platform.

#### GitHub Actions

Create `.github/workflows/ci.yml`:

```yaml
name: CI
on: [push, pull_request]

jobs:
  test:
    runs-on: windows-latest  # or ubuntu-latest
    strategy:
      matrix:
        python-version: ['3.9', '3.10', '3.11']
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: ${{ matrix.python-version }}
      - run: pip install -e ".[test]"
      - run: python -m pytest test/automated/ --cov=YOUR_MODULE --cov-report=xml
      # Optional: upload coverage to Codecov
      # - uses: codecov/codecov-action@v4

  quality:
    runs-on: ubuntu-latest
    continue-on-error: true  # Advisory, not blocking
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.11'
      - run: pip install black isort flake8
      - run: black --check --line-length=100 YOUR_MODULE/
      - run: isort --check --profile=black --line-length=100 YOUR_MODULE/
      - run: flake8 --max-line-length=100 YOUR_MODULE/
```

**Expected Result:** CI runs on every push and PR, testing across Python versions.

### 4. Create startup scripts (optional)

For long-running services, create launch scripts in a `{project}_run/` directory:

```powershell
# start_service_background.ps1
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
Start-Process -NoNewWindow python -ArgumentList "$projectRoot/main.py" -WorkingDirectory $projectRoot
```

### 5. Verify the setup

```bash
# Test pre-commit
pre-commit run --all-files

# Test dev script
dev test
dev lint

# Test CI locally (if using act)
act -j test
```

## Related Resources

- [Testing Setup Guide](../03-testing/testing-setup-guide.md) — Set up test infrastructure (complementary to this guide)
- [Release & Deployment Task](/doc/process-framework/tasks/07-deployment/release-deployment-task.md) — Release process using the CI/CD infrastructure
- [Development Guide](../04-implementation/development-guide.md) — Development best practices

