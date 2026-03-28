---
id: PF-GDE-050
type: Document
category: Guide
version: 1.1
created: 2026-03-16
updated: 2026-03-25
guide_description: How the test/ directory connects to the process framework, including new-project scaffolding
related_tasks: PF-TSK-053,PF-TSK-012,PF-TSK-030,PF-TSK-069,PF-TSK-070
guide_status: Active
guide_category: 03-testing
guide_title: Test Infrastructure Guide
---

# Test Infrastructure Guide

## Overview

The `test/` directory is the single home for all testing concerns in a project using the process framework. It unifies automated test code, test specifications, E2E acceptance test cases, and test audit reports under one roof, with clear connections to the process framework's tracking and governance infrastructure.

## When to Use

- When setting up test infrastructure for a new project adopting the process framework
- When migrating an existing project's tests into the framework structure
- When you need to understand how test files, specifications, and audits relate to each other
- When creating new tests and need to know where they belong

## Directory Structure

```
test/
├── automated/                      # All automated test code (subdirs = categories)
│   ├── unit/                       # Unit tests for individual components
│   ├── integration/                # Cross-component interaction tests
│   ├── parsers/                    # Format-specific parser tests (project-specific)
│   ├── performance/                # Benchmarks and scalability tests
│   ├── bug-validation/             # PD-BUG-* regression validation scripts
│   ├── fixtures/                   # Static test data files
│   ├── conftest.py                 # Shared pytest fixtures
│   ├── utils.py                    # Test helper functions and builders
│   ├── __init__.py                 # Package marker
│   └── test_*.py                   # Root-level test files
│
├── specifications/                 # Test specifications derived from TDDs
│   └── feature-specs/              # One spec per feature (PF-TSP-*)
│
├── e2e-acceptance-testing/          # Formal E2E acceptance test framework (E2E-*)
│   ├── templates/                  # Pristine test case fixtures (never modified)
│   │   └── <group-name>/           # One directory per E2E-GRP
│   │       └── E2E-NNN-<name>/     # Individual test cases
│   │           ├── test-case.md    # Steps, preconditions, expected results
│   │           ├── project/        # Starting state files
│   │           ├── expected/       # Post-test expected state
│   │           └── run.ps1         # (Scripted tests only) Automated test action
│   ├── workspace/                  # Generated working copies (gitignored)
│   └── results/                    # Execution logs (gitignored)
│
├── audits/                         # Test audit reports (TE-TAR-*)
│   └── <category>/                 # Grouped by feature category
│
```

## How It Connects to the Process Framework

### Source of Truth Files

| File | Location | Purpose | Updated By |
|------|----------|---------|------------|
| **pytest markers** (via `test_query.py`) | `test/automated/` | Test metadata embedded as pytest markers in test files (feature, priority, test_type) | `New-TestFile.ps1` (automated), manual edits |
| **test-tracking.md** | `test/state-tracking/permanent` | Automated test implementation progress, audit results | `New-TestFile.ps1`, manual edits |
| **e2e-test-tracking.md** | `test/state-tracking/permanent` | E2E acceptance test cases, workflow milestones, execution status | `New-E2EAcceptanceTestCase.ps1`, `Update-TestExecutionStatus.ps1`, manual edits |
| **feature-tracking.md** | `doc/process-framework/state-tracking/permanent` | Feature-level test status column | `New-TestFile.ps1`, `Update-TestExecutionStatus.ps1` |

### Key Principle: No Duplicate Tracking

The process framework eliminated redundant test tracking files. There is **no** separate README, TEST_PLAN, TEST_CASE_STATUS, or TEST_CASE_TEMPLATE in the test directory. All tracking is handled by:

- **pytest markers** — what test files exist and their metadata (query via `test_query.py`)
- **test-tracking.md** — automated test status, audit results
- **e2e-test-tracking.md** — E2E acceptance test cases and workflow milestones
- **test specifications** — what should be tested (derived from TDDs)
- **E2E acceptance test case templates** (PF-TEM-053, PF-TEM-054) — how to create E2E acceptance tests

### Automation Scripts

| Script | Location | Purpose |
|--------|----------|---------|
| `New-TestFile.ps1` | `scripts/file-creation/` | Create automated test files with pytest markers |
| `New-E2EAcceptanceTestCase.ps1` | `scripts/file-creation/` | Create E2E acceptance test cases with TE-E2E/TE-E2G IDs |
| `New-TestSpecification.ps1` | `scripts/file-creation/` | Create test specifications with PF-TSP IDs |
| `New-TestAuditReport.ps1` | `scripts/file-creation/` | Create test audit reports with TE-TAR IDs, update test-tracking.md |
| `Run-Tests.ps1` | `scripts/test/` | Language-agnostic test runner (reads project-config.json + languages-config/) |
| `Setup-TestEnvironment.ps1` | `scripts/test/e2e-acceptance-testing/` | Copy pristine fixtures to workspace for E2E acceptance testing |
| `Verify-TestResult.ps1` | `scripts/test/e2e-acceptance-testing/` | Compare workspace state against expected state |
| `Run-E2EAcceptanceTest.ps1` | `scripts/test/e2e-acceptance-testing/` | Orchestrate scripted test pipeline: Setup → run.ps1 → wait → Verify |
| `Update-TestExecutionStatus.ps1` | `scripts/test/e2e-acceptance-testing/` | Update e2e-test-tracking.md with E2E acceptance test results |
| `Validate-TestTracking.ps1` | `scripts/validation/` | Validate consistency between registry, tracking, and disk |

### Related Tasks

| Task | ID | Relationship to test/ |
|------|----|-----------------------|
| Integration and Testing | PF-TSK-053 | Creates test files in `test/automated/` using `New-TestFile.ps1` |
| Test Specification Creation | PF-TSK-012 | Creates specs in `test/specifications/feature-specs/` |
| Test Audit | PF-TSK-030 | Creates audit reports in `test/audits/` |
| E2E Acceptance Test Case Creation | PF-TSK-069 | Creates test cases in `test/e2e-acceptance-testing/templates/` |
| E2E Acceptance Test Execution | PF-TSK-070 | Executes tests from `test/e2e-acceptance-testing/templates/` in `workspace/` |

## E2E Acceptance Test Execution Modes

E2E acceptance test cases support two execution modes, set via the `Execution Mode` field in `test-case.md` metadata:

| Mode | Created With | Executed By | How |
|------|-------------|-------------|-----|
| **manual** | `New-E2EAcceptanceTestCase.ps1` (default) | Human | Follow Steps section in test-case.md |
| **scripted** | `New-E2EAcceptanceTestCase.ps1 -Scripted` | AI agent or human via script | `Run-E2EAcceptanceTest.ps1` orchestrates Setup → run.ps1 → wait → Verify |

### Scripted Tests

Scripted test cases include a `run.ps1` file that performs the test action (e.g., `Move-Item`, `Set-Content`). The script contains **only the action** — setup and verification are handled by existing infrastructure.

**Pipeline**: Stop LW → `Setup-TestEnvironment.ps1` → Start LW (workspace-scoped) → settle → `run.ps1` → wait for propagation → `Verify-TestResult.ps1` → Stop LW

LinkWatcher is started scoped to the workspace case directory (not the full project), keeping scan times to a few seconds instead of 40-65s. A configurable settling delay (`-SettleSeconds`, default 3) after scan completion ensures link indexing finishes before the test action runs.

```bash
# Run a single scripted test case
pwsh.exe -ExecutionPolicy Bypass -Command '& doc/process-framework/scripts/test/e2e-acceptance-testing/Run-E2EAcceptanceTest.ps1 -TestCase "TE-E2E-001" -Group "my-group"'

# Run all scripted tests in a group (clean workspace, detailed diffs)
pwsh.exe -ExecutionPolicy Bypass -Command '& doc/process-framework/scripts/test/e2e-acceptance-testing/Run-E2EAcceptanceTest.ps1 -Group "my-group" -Clean -Detailed'

# Run all scripted tests across all groups
pwsh.exe -ExecutionPolicy Bypass -Command '& doc/process-framework/scripts/test/e2e-acceptance-testing/Run-E2EAcceptanceTest.ps1'

# Increase settling delay for complex fixtures
pwsh.exe -ExecutionPolicy Bypass -Command '& doc/process-framework/scripts/test/e2e-acceptance-testing/Run-E2EAcceptanceTest.ps1 -Group "my-group" -SettleSeconds 5'
```

Test cases without `run.ps1` are automatically skipped by `Run-E2EAcceptanceTest.ps1` with a message suggesting manual execution.

### How Scripted Tests Differ from Automated Tests

| Aspect | Automated (`test/automated/`) | Scripted E2E acceptance (`test/e2e-acceptance-testing/`) |
|--------|-------------------------------|------------------------------------------|
| **Environment** | Isolated test harness (pytest, mocks) | Real running system (e.g., LinkWatcher) |
| **What they test** | Individual components in isolation | End-to-end behavior on real file system |
| **Speed** | Fast (seconds) | Slower (waits for system event propagation) |
| **When to run** | Every code change, CI | After significant changes, pre-release |

## User Workflow Map and E2E Test Planning

E2E acceptance tests validate **user-facing workflows** that span multiple features. The planning and tracking flow:

```
User Workflow Map (what workflows exist, which features they need)
    → Milestone: all features for a workflow reach "Implemented"
    → Cross-cutting E2E Test Specification (scenarios per workflow)
    → E2E Test Case Creation (PF-TSK-069)
    → E2E Test Execution (PF-TSK-070)
```

**Key files:**
- [User Workflow Map](/doc/product-docs/technical/design/user-workflow-map.md) — planning artifact mapping workflows to features
- [Cross-cutting E2E specs](/test/specifications/cross-cutting-specs/) — scenario definitions per workflow
- **e2e-test-tracking.md** — Workflow Milestone Tracking + E2E Test Cases table
- **test-registry.yaml** — E2E entries only (retained until E2E marker migration in Phase 7), with `featureIds` (multi-feature), `workflow`, `group` fields and `TE-E2G-NNN` / `TE-E2E-NNN` IDs

## Test Priority

Each test file has a `priority` pytest marker indicating its importance for release gating:

| Priority | Meaning | When to Run | Examples |
|----------|---------|-------------|----------|
| **Critical** | Must pass before any release. Core functionality. | Every CI run, pre-release gate | Foundation unit tests, parser tests, core data models |
| **Standard** | Normal test coverage. Expected to pass. | Regular development, pre-release | Integration tests, logging tests (default for new entries) |
| **Extended** | Edge cases, performance, stress tests. | Periodic, not release-blocking | Performance benchmarks |

Priority is set when creating test files via `New-TestFile.ps1 -Priority "Critical"` (default: Standard). Validated by `Validate-TestTracking.ps1` (Check 7).

The [Release & Deployment task](/doc/process-framework/tasks/07-deployment/release-deployment-task.md) references priorities in its pre-release gate: Critical tests must all pass, Extended tests are informational.

## Configuration

Testing configuration is split between two files:

### Project Configuration (`project-config.json`)

Project-specific settings — test directory, language, quick categories:

```json
{
  "testing": {
    "language": "python",
    "testDirectory": "test/automated",
    "quickCategories": ["unit", "parsers"]
  }
}
```

### Language Configuration (`languages-config/{language}/{language}-config.json`)

Language-specific commands — test runner, coverage, lint:

```json
{
  "language": "python",
  "testing": {
    "baseCommand": "python -m pytest",
    "coverageArgs": "--cov={module} --cov-report=html --cov-report=term",
    "discoveryCommand": "python -m pytest --collect-only -q",
    "lintCommand": "python -m flake8 {testDir} --max-line-length=100"
  }
}
```

See [Language Configurations README](/doc/process-framework/languages-config/README.md) for how to add support for new languages.

`New-TestFile.ps1` reads `project-config.json` for the test directory path. Your language's test runner configuration (e.g., `pytest.ini`, `pyproject.toml`) should match the `testDirectory` setting.

### Test Categories

`Run-Tests.ps1` discovers test categories automatically by scanning subdirectories of the test directory. No configuration needed — if a subdirectory exists, it becomes an available category. Use `-ListCategories` to see what's available.

## Running Tests

Use the language-agnostic test runner:

```bash
# List available categories
pwsh.exe -ExecutionPolicy Bypass -Command '& doc/process-framework/scripts/test/Run-Tests.ps1 -ListCategories'

# Run a specific category
pwsh.exe -ExecutionPolicy Bypass -Command '& doc/process-framework/scripts/test/Run-Tests.ps1 -Category unit'

# Quick run (categories from project-config.json quickCategories, stop on first failure)
pwsh.exe -ExecutionPolicy Bypass -Command '& doc/process-framework/scripts/test/Run-Tests.ps1 -Quick'

# Multiple categories at once
pwsh.exe -ExecutionPolicy Bypass -Command '& doc/process-framework/scripts/test/Run-Tests.ps1 -Category unit,integration'

# All tests with coverage
pwsh.exe -ExecutionPolicy Bypass -Command '& doc/process-framework/scripts/test/Run-Tests.ps1 -All -Coverage'

# Test discovery
pwsh.exe -ExecutionPolicy Bypass -Command '& doc/process-framework/scripts/test/Run-Tests.ps1 -Discover'

# Run tests and auto-update test-tracking.md with per-file pass/fail results
pwsh.exe -ExecutionPolicy Bypass -Command '& doc/process-framework/scripts/test/Run-Tests.ps1 -Category unit -UpdateTracking'
```

## Setting Up Test Infrastructure for a New Project

Use this section when adopting the process framework into an existing project or scaffolding tests for a new one. This is typically done during Project Initiation (PF-TSK-059) or the setup workflow (PF-TSK-064 → PF-TSK-066).

### Automated Setup (Recommended)

Run the bootstrapping script to create the entire test infrastructure:

```powershell
cd doc/process-framework/scripts/file-creation/00-setup
.\New-TestInfrastructure.ps1 -Language "<your-language>"
```

**What it creates:**
- `test/automated/{categories}/` — from `project-config.json` `quickCategories` + defaults
- `test/specifications/feature-specs/` and `cross-cutting-specs/`
- `test/e2e-acceptance-testing/templates/`, `workspace/`, `results/`
- `test/audits/`
- `test/state-tracking/permanent/test-tracking.md` and `e2e-test-tracking.md`
- `test/TE-id-registry.json`
- Shared fixture file (e.g., `conftest.py` for Python) from language config
- Package markers (e.g., `__init__.py` for Python) where needed
- `.gitignore` for E2E workspace/results directories

**Prerequisites:**
- `project-config.json` must exist with testing section configured
- `languages-config/{language}/{language}-config.json` must exist — see [Language Configurations README](/doc/process-framework/languages-config/README.md)

**Options:**
- `-TestCategories @("unit", "api", "integration")` — override default categories
- `-ProjectName "MyProject"` — override project name from config
- `-WhatIf` — preview without making changes

The script is **idempotent** — safe to re-run; it skips existing files and directories.

### After Running the Script

1. **Create native test runner config** for your language:

   | Language | Native Config | Runner Setup |
   |----------|--------------|--------------|
   | Python | `pytest.ini` or `pyproject.toml` | `pip install pytest pytest-cov` |
   | Dart | `dart_test.yaml` | Included with Flutter SDK |
   | JavaScript | `jest.config.js` | `npm install --save-dev jest` |

2. **Install test dependencies** for your language's test runner.

3. **Verify the setup:**

   ```powershell
   Run-Tests.ps1 -ListCategories      # Categories discovered
   Run-Tests.ps1 -Quick                # Quick tests pass
   Validate-TestTracking.ps1           # Framework tracking consistent
   ```

### Manual Setup (Alternative)

If you prefer manual setup or need to customize individual steps, ensure the following structure exists:

```
test/
├── automated/{categories}/     # From project-config.json quickCategories
├── specifications/
│   ├── feature-specs/
│   └── cross-cutting-specs/
├── e2e-acceptance-testing/
│   ├── templates/
│   ├── workspace/              # gitignored
│   └── results/                # gitignored
├── audits/
├── state-tracking/permanent/
│   ├── test-tracking.md
│   └── e2e-test-tracking.md
└── TE-id-registry.json
```

Create shared fixture files and package markers appropriate for your language, register them in `testSetup.configFiles` in your language config.

## Related Resources

- [Test Specification Creation Task (PF-TSK-012)](/doc/process-framework/tasks/03-testing/test-specification-creation-task.md)
- [Integration and Testing Task (PF-TSK-053)](/doc/process-framework/tasks/04-implementation/integration-and-testing.md)
- [Test Audit Task (PF-TSK-030)](/doc/process-framework/tasks/03-testing/test-audit-task.md)
- [E2E Acceptance Test Case Creation Task (PF-TSK-069)](/doc/process-framework/tasks/03-testing/e2e-acceptance-test-case-creation-task.md)
- [E2E Acceptance Test Case Template (PF-TEM-054)](/doc/process-framework/templates/03-testing/e2e-acceptance-test-case-template.md)
- [Test File Template (test-file-template.py.template)](/doc/process-framework/templates/03-testing/test-file-template.py.template)
- [Language Config Template](/doc/process-framework/templates/support/language-config-template.json) — Template for new language configurations
- [Language Configurations README](/doc/process-framework/languages-config/README.md) — How to add support for new languages
