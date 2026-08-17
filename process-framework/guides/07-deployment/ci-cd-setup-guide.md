---
id: PF-GDE-052
type: Process Framework
category: Guide
version: 1.2
created: 2026-03-22
updated: 2026-08-04
related_task: PF-TSK-014,PF-TSK-008
description: "Guide for scaffolding CI/CD infrastructure (pipelines, pre-commit hooks, dev scripts)"
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
- Language config exists in `process-framework/languages-config/{language}/{language}-config.json`
- Git repository initialized
- Language-specific tools installed (e.g., `black`, `isort`, `flake8` for Python)

## Architecture

CI/CD infrastructure is **not a product feature** — it's development tooling that the framework provides as scaffolding. Each component is optional and depends on your project's needs — except the framework's own pre-commit gates (state-tracking, documentation-map, corruption guards; sections below), which are the expected default for every framework project:

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

#### Framework state-tracking gate (PF-IMP-1211 / PF-PRO-049)

Add the state-tracking validation gate to the `local` `repos:` block so structural drift (broken tracker links, surface coverage gaps, ID-counter drift) is caught at commit time. It is **warn-first** (non-blocking) by default — findings are shown but never block the commit — so it can be adopted on a project that still carries pre-existing debt:

```yaml
  - repo: local
    hooks:
      - id: state-tracking-validate
        name: State tracking validation (warn-first; promote with Run-StateTrackingGate.ps1 -Blocking)
        entry: pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/validation/Run-StateTrackingGate.ps1
        language: system
        pass_filenames: false
        always_run: true
        verbose: true
        stages: [pre-commit]
```

**Promoting to blocking.** When the project carries pre-existing *error* debt you don't want to fail on, ratchet against a committed baseline so only NEW errors block:

```bash
# 1. Capture the current state as the accepted baseline; commit the printed JSON file into the repo:
pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/validation/Validate-StateTracking.ps1 -SaveBaseline
# 2. Make the hook blocking and point it at the committed baseline (edit the hook entry):
#    entry: ... Run-StateTrackingGate.ps1 -Blocking -Baseline <committed-baseline>.json
```

A project with **no** error debt can promote to blocking without a baseline (`Run-StateTrackingGate.ps1 -Blocking`) — any error then fails the commit. The validator only fingerprints *errors*, so a 0-error baseline behaves identically to a plain blocking run.

#### Framework documentation-map drift gates (PF-PRO-050)

Add the documentation-map drift gates so a stale generated map is caught at commit time. The PD (product-design) and TE (test) maps regenerate from your project's own `doc/` and `test/` artifacts, so they drift whenever you add a design or test document without regenerating. They are DO-NOT-EDIT projections — fix drift by rerunning `Build-DocumentationMap.ps1 -Tree <PD|TE>`, not by editing the map. These gates are blocking (`-Check` exits non-zero on drift), so before adding them to a project that already has design or test artifacts, run each gate's `-Check` command once and regenerate any drifted tree — otherwise the project's next commit fails on pre-existing drift:

```yaml
  - repo: local
    hooks:
      - id: documentation-map-pd-in-sync
        name: Product documentation map in sync (regenerate with Build-DocumentationMap.ps1 -Tree PD)
        entry: pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/validation/Build-DocumentationMap.ps1 -Tree PD -Check
        language: system
        pass_filenames: false
        always_run: true
        stages: [pre-commit]
      - id: documentation-map-te-in-sync
        name: Test documentation map in sync (regenerate with Build-DocumentationMap.ps1 -Tree TE)
        entry: pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/validation/Build-DocumentationMap.ps1 -Tree TE -Check
        language: system
        pass_filenames: false
        always_run: true
        stages: [pre-commit]
```

#### Framework corruption guards (PF-IMP-615 / PF-IMP-1616)

Add the two corruption guards so repository corruption is caught before it reaches committed HEAD. Both exist because real incidents did: `.git/objects/<hex>/<sha>` literals pasted into tracked files (PF-IMP-615) and NUL-byte corruption in tracked text files (PF-IMP-1616). They are fast, blocking checks with no baseline or promotion step:

```yaml
  - repo: local
    hooks:
      - id: no-git-objects-literal
        name: Detect .git/objects/ literal paths (corruption guard)
        entry: pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/validation/Check-GitObjectsLiteral.ps1
        language: system
        pass_filenames: false
        always_run: true
        stages: [pre-commit]
      - id: no-nul-bytes
        name: Detect NUL-byte corruption in tracked text files
        entry: pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/validation/Check-NulBytes.ps1
        language: system
        pass_filenames: false
        always_run: true
        stages: [pre-commit]
```

#### Gates that do NOT ship to projects (appdev-only)

The canonical framework workspace (appdev) runs five additional gates. Four guard editing of the canonical framework tree: `task-metadata-in-sync` (`Build-TaskMetadata.ps1 -Check`), the PF-tree `documentation-map-in-sync` (`Build-DocumentationMap.ps1 -Check`), `script-convention-lint` (`Run-ScriptConventionGate.ps1`), and `core-file-budget` (`Check-CoreFileBudget.ps1`, which holds task definitions and guides to per-file word budgets so accretion surfaces as it happens rather than after readers stumble). Do **not** add these to a project's config: task definitions, guides, the PF documentation map, and the framework script fleet are edited only in the canonical workspace and arrive in projects already in sync via Framework Rollout. The fifth, `no-untracked-artifacts` (`Check-UntrackedArtifacts.ps1`), warns when an authored artifact is invisible to git — either never added, or swallowed by an ignore rule; it is agnostic enough to serve a project unchanged, but whether it joins the shipped set is a gate-distribution decision rather than a per-project one. The complete recommended project set is exactly the gates documented above: quick tests, state-tracking gate, PD/TE documentation-map drift gates, and the two corruption guards.

### 2. Create dev script

Create `dev.bat` (Windows) or `dev.sh` (Unix) for shortcut commands:

#### Windows (dev.bat)

```batch
@echo off
if "%1"=="test" python -m pytest test/automated/unit/ -x -q --tb=short
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

- [Test Infrastructure Guide](../03-testing/test-infrastructure-guide.md) — Test directory structure, tracking, and scaffolding (complementary to this guide)
- [Release & Deployment Task](../../tasks/07-deployment/release-deployment-task.md) — Release process using the CI/CD infrastructure
- [Development Guide](../04-implementation/development-guide.md) — Development best practices
