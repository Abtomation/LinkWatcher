---
id: PF-GDE-050
type: Process Framework
category: Guide
version: 1.2
created: 2026-03-16
updated: 2026-06-03
related_task: PF-TSK-053,PF-TSK-012,PF-TSK-030,PF-TSK-069,PF-TSK-070
guide_title: Test Infrastructure Guide
description: "How the test/ directory connects to the process framework — directory conventions, automation scripts, tracking relationships, new-project scaffolding, and pre-existing-test migration"
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
│   │   └── <N>-<slug>/             # Per feature category (PF-IMP-871 Phase 3a; nested for level-2)
│   ├── performance/                # 4-level perf taxonomy (PF-IMP-871 Phase 3b)
│   │   ├── level1-component/       # Component-level benchmarks (BM-*)
│   │   ├── level2-operation/       # Operation-level benchmarks (BM-*)
│   │   ├── level3-scale/           # Scale tests (PH-*)
│   │   └── level4-resource/        # Resource tests (PH-*)
│   ├── fixtures/                   # Static test data files
│   ├── conftest.py                 # Shared pytest fixtures
│   ├── utils.py                    # Test helper functions and builders
│   ├── __init__.py                 # Package marker
│   └── test_*.py                   # Root-level test files
│
├── bug-validation/                 # PD-BUG-* regression validation scripts (top-level since PF-IMP-871 Phase 2b — formerly under automated/)
│
├── specifications/                 # Test specifications derived from TDDs
│   └── feature-specs/              # One spec per feature (PF-TSP-*)
│
├── e2e-acceptance-testing/          # Formal E2E acceptance test framework (E2E-*)
│   └── <workflow-slug>/             # Per workflow from user-workflow-tracking.md (PF-IMP-871 Phase 3c1)
│       ├── templates/               # Pristine test case fixtures (never modified)
│       │   └── E2E-NNN-<name>/      # Individual test cases (Group layer collapsed in Phase 3c2)
│       │       ├── test-case.md    # Steps, preconditions, expected results
│       │       ├── project/        # Starting state files
│       │       ├── expected/       # Post-test expected state
│       │       └── run.ps1         # (Scripted tests only) Automated test action
│       ├── workspace/               # Generated working copies (gitignored)
│       └── results/                 # Execution logs (gitignored)
│
├── audits/                         # Test audit reports (TE-TAR-*) — audit location = subject location (PF-IMP-871 Phase 3a)
│   ├── unit/<N>-<slug>/            # Mirrors automated/unit/<N>-<slug>/
│   ├── performance/level{1-4}-*/   # Mirrors automated/performance/level{1-4}-*/
│   └── e2e/<workflow-slug>/        # Mirrors e2e-acceptance-testing/<workflow-slug>/
│
```

## How It Connects to the Process Framework

### Source of Truth Files

| File | Location | Purpose | Updated By |
|------|----------|---------|------------|
| **pytest markers** (via `test_query.py`) | `test/automated/` | Test metadata embedded as pytest markers in test files (feature, priority, test_type) | `New-TestFile.ps1` (automated), manual edits |
| **test-tracking.md** | `test/state-tracking/permanent` | Automated test implementation progress, audit results | `New-TestFile.ps1`, manual edits |
| **e2e-test-tracking.md** | `test/state-tracking/permanent` | E2E acceptance test cases, workflow milestones, execution status | `New-E2EAcceptanceTestCase.ps1`, `Update-TestExecutionStatus.ps1`, manual edits |
| **feature-tracking.md** | `doc/state-tracking/permanent` | Feature-level test status column | `New-TestFile.ps1`, `Update-TestExecutionStatus.ps1` |

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
| `New-TestFile.ps1` | `scripts/file-creation` | Create automated test files with pytest markers |
| `New-E2EAcceptanceTestCase.ps1` | `scripts/file-creation` | Create E2E acceptance test cases with TE-E2E/TE-E2G IDs |
| `New-TestSpecification.ps1` | `scripts/file-creation` | Create test specifications with PF-TSP IDs |
| `New-TestAuditReport.ps1` | `scripts/file-creation` | Create test audit reports with TE-TAR IDs, update test-tracking.md |
| `Run-Tests.ps1` | `scripts/test` | Language-agnostic test runner (reads project-config.json + languages-config/) |
| `Setup-TestEnvironment.ps1` | `scripts/test/e2e-acceptance-testing/` | Copy pristine fixtures to workspace for E2E acceptance testing |
| `Verify-TestResult.ps1` | `scripts/test/e2e-acceptance-testing/` | Compare workspace state against expected state |
| `Run-E2EAcceptanceTest.ps1` | `scripts/test/e2e-acceptance-testing/` | Orchestrate scripted test pipeline: Setup → run.ps1 → wait → Verify |
| `Update-TestExecutionStatus.ps1` | `scripts/test/e2e-acceptance-testing/` | Update e2e-test-tracking.md with E2E acceptance test results |
| `Validate-TestTracking.ps1` | `scripts/validation` | Validate consistency between registry, tracking, and disk |

### Related Tasks

| Task | ID | Relationship to test/ |
|------|----|-----------------------|
| Integration and Testing | PF-TSK-053 | Creates test files in `test/automated/` using `New-TestFile.ps1` |
| Test Specification Creation | PF-TSK-012 | Creates specs in `test/specifications/feature-specs` |
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

**Pipeline**: `Setup-TestEnvironment.ps1` → `run.ps1` → optional wait → `Verify-TestResult.ps1`

The runner is project-agnostic — it handles setup, action execution, and verification only. Projects that need tool-specific lifecycle management (e.g., starting/stopping a background service) should handle it in their test cases' `run.ps1` scripts. Use `-WaitSeconds N` (default: 0) when the action triggers asynchronous effects that need time to settle before verification.

```bash
# Run a single scripted test case
pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/test/e2e-acceptance-testing/Run-E2EAcceptanceTest.ps1 -TestCase "TE-E2E-001" -Workflow "my-workflow"

# Run all scripted tests in a workflow (clean workspace, detailed diffs)
pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/test/e2e-acceptance-testing/Run-E2EAcceptanceTest.ps1 -Workflow "my-workflow" -Clean -Detailed

# Run all scripted tests across all workflows
pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/test/e2e-acceptance-testing/Run-E2EAcceptanceTest.ps1

# Add post-action wait for async effects (e.g., background service propagation)
pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/test/e2e-acceptance-testing/Run-E2EAcceptanceTest.ps1 -Workflow "my-workflow" -WaitSeconds 12
```

Test cases without `run.ps1` are automatically skipped by `Run-E2EAcceptanceTest.ps1` with a message suggesting manual execution.

### How Scripted Tests Differ from Automated Tests

| Aspect | Automated (`test/automated/`) | Scripted E2E acceptance (`test/e2e-acceptance-testing/`) |
|--------|-------------------------------|------------------------------------------|
| **Environment** | Isolated test harness (pytest, mocks) | Real running system (e.g., LinkWatcher) |
| **What they test** | Individual components in isolation | End-to-end behavior on real file system |
| **Speed** | Fast (seconds) | Slower (waits for system event propagation) |
| **When to run** | Every code change, CI | After significant changes, pre-release |

## User Workflow Tracking and E2E Test Planning

E2E acceptance tests validate **user-facing workflows** that span multiple features. The planning and tracking flow:

```
User Workflow Tracking (what workflows exist, which features they need)
    → Milestone: all features for a workflow reach "Implemented"
    → Cross-cutting E2E Test Specification (scenarios per workflow)
    → E2E Test Case Creation (PF-TSK-069)
    → E2E Test Execution (PF-TSK-070)
```

**Key files:**
- [User Workflow Tracking](../../../doc/state-tracking/permanent/user-workflow-tracking.md) — state tracking artifact mapping workflows to features
- [Cross-cutting E2E specs](../../../test/specifications/cross-cutting-specs) — scenario definitions per workflow
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

The [Release & Deployment task](../../tasks/07-deployment/release-deployment-task.md) references priorities in its pre-release gate: Critical tests must all pass, Extended tests are informational.

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

See [Language Configurations README](../../languages-config/README.md) for how to add support for new languages.

`New-TestFile.ps1` reads `project-config.json` for the test directory path. Your language's test runner configuration (e.g., `pytest.ini`, `pyproject.toml`) should match the `testDirectory` setting.

### Test Categories

`Run-Tests.ps1` discovers test categories automatically by scanning subdirectories of the test directory. No configuration needed — if a subdirectory exists, it becomes an available category. Use `-ListCategories` to see what's available.

## Running Tests

Use the language-agnostic test runner:

```bash
# List available categories
pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/test/Run-Tests.ps1 -ListCategories

# Run a specific category
pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/test/Run-Tests.ps1 -Category unit

# Quick run (categories from project-config.json quickCategories, stop on first failure)
pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/test/Run-Tests.ps1 -Quick

# Multiple categories at once
pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/test/Run-Tests.ps1 -Category unit,integration

# All tests with coverage
pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/test/Run-Tests.ps1 -All -Coverage

# Test discovery
pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/test/Run-Tests.ps1 -Discover

# Run tests and auto-update test-tracking.md with per-file pass/fail results
pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/test/Run-Tests.ps1 -Category unit -UpdateTracking
```

## Setting Up Test Infrastructure for a New Project

Use this section when adopting the process framework into an existing project or scaffolding tests for a new one. This is typically done during Project Initiation (PF-TSK-059) or the setup workflow (PF-TSK-064 → PF-TSK-066).

The recommended path is **blueprint copy first, then language customization**:
1. Copy `FrameworkBuilder/<variant>/` into your project (this provides the test directory tree, tracking files, `TE-id-registry.json`, audit dirs, and `.gitkeep` markers — all canonical empty starters).
2. Run the language-customization script described below to layer language-specific files (fixtures, package markers, E2E `.gitignore`) on top.

### Apply Language Customizations (Recommended)

Run the script to layer language-specific customizations on top of the blueprint-provided test tree:

```powershell
cd process-framework/scripts/file-creation/00-setup
.\New-TestInfrastructure.ps1 -Language "<your-language>"
```

**What it does:**
- Verifies the blueprint-provided tracking files (`test-tracking.md`, `e2e-test-tracking.md`, `performance-test-tracking.md`, `TE-id-registry.json`) are present; warns if any are missing
- Idempotently ensures structural directories exist: `test/automated/{categories}/`, `test/specifications/feature-specs/`, `cross-cutting-specs/`, `test/e2e-acceptance-testing/{templates,workspace,results}/`, `test/audits/`, `test/state-tracking/permanent/`
- Creates the shared fixture file (e.g., `conftest.py` for Python) from language config
- Creates package markers (e.g., `__init__.py` for Python) where the language config requires
- Creates `.gitignore` for E2E `workspace/` and `results/` directories

**The script does not create tracking files or the TE-id-registry** — those are canonical content in the blueprint copy and have no template file. If they are missing, restore from the blueprint or version control.

**Prerequisites:**
- Blueprint copy already applied (provides `test/state-tracking/permanent/*.md` and `test/TE-id-registry.json`)
- `project-config.json` must exist with testing section configured
- `languages-config/{language}/{language}-config.json` must exist — see [Language Configurations README](../../languages-config/README.md)

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

## Migrating Pre-Existing Tests Into the Framework

The setup steps above scaffold the empty `test/` tree and create *new* tests — they do **not** migrate a project's pre-existing test files into the framework structure. That migration is a Tier 2+ onboarding activity owned by **[Retrospective Documentation Creation (PF-TSK-066)](../../tasks/00-setup/retrospective-documentation-creation.md) Step 8**, which delegates to **[Integration and Testing (PF-TSK-053)](../../tasks/04-implementation/integration-and-testing.md) in migration mode**.

In migration mode you:

- Create framework-structured test files with `New-TestFile.ps1` and copy the existing assertions, setup, and fixtures into them — restructure to match the template, do **not** rewrite the test logic — adding the `feature` / `priority` / `test_type` pytest markers.
- Verify the migrated tests cover the feature's test specification; fill only the gaps the spec identifies.
- Run the migrated tests to confirm they still pass, then **remove the original pre-existing test files** so no parallel test system remains.
- Let the `New-TestFile.ps1` automation register everything in `test-tracking.md` and `feature-tracking.md`.

See [Retrospective Documentation Creation Step 8](../../tasks/00-setup/retrospective-documentation-creation.md) for the full migration-mode procedure.

## Test Isolation Rules

### Never use real project directory names in test content

Test content strings (parsed text, assertion values, file content written to temp dirs) must **never** use real project directory names like `doc`, `process-framework`, or `src/linkwatcher`. LinkWatcher treats these as real file references and rewrites them when the corresponding real directories move.

### Use the `alpha-project/` synthetic namespace

All test path references use the `alpha-project/` prefix, which does not exist in the real project. A shared constant `TEST_PROJECT_ROOT = "alpha-project"` is defined in `test/automated/conftest.py`.

**Mapping convention:**
| Real project path | Test equivalent |
|---|---|
| `doc/guides/setup.md` | `alpha-project/docs/guides/setup.md` |
| `process-framework/templates/...` | `alpha-project/framework/templates/...` |
| `doc/scripts/feedback_db.py` | `alpha-project/scripts/feedback_db.py` |

### Safe synthetic paths (no change needed)

Paths using directories that don't exist in the real project are already safe: `vendor/`, `src/`, `lib`, `config/`, `components/`. These do not need to be replaced.

### Rules summary

1. **Never** use `doc`, `process-framework`, or `src/linkwatcher` as path prefixes in test content strings
2. **Always** use `alpha-project/` or another non-existent directory name
3. **Store** paths in variables and derive both content and assertions from the same variable when practical
4. Paths used only as **filesystem paths within `tmp_path`** (never written as string content) are safe regardless of name

**Why**: Real project paths in test strings break when directories are renamed or moved. LinkWatcher updates real files but cannot update string literals inside test code, causing content and assertion strings to silently diverge. Git history confirms this happened in commits b3b29e2, ff5c27f, 07b1e51.

See [Test File Creation Guide — Path Usage](test-file-creation-guide.md#path-usage-in-test-content) for the full pattern and examples.

## Related Resources

- [Test Specification Creation Task (PF-TSK-012)](../../tasks/03-testing/test-specification-creation-task.md)
- [Integration and Testing Task (PF-TSK-053)](../../tasks/04-implementation/integration-and-testing.md)
- [Test Audit Task (PF-TSK-030)](../../tasks/03-testing/test-audit-task.md)
- [E2E Acceptance Test Case Creation Task (PF-TSK-069)](../../tasks/03-testing/e2e-acceptance-test-case-creation-task.md)
- [E2E Acceptance Test Case Template (PF-TEM-054)](../../templates/03-testing/e2e-acceptance-test-case-template.md)
- [Test File Template (test-file-template.py.template)](../../templates/03-testing/test-file-template.py.template)
- [Language Config Template](../../templates/support/language-config-template.json) — Template for new language configurations
- [Language Configurations README](../../languages-config/README.md) — How to add support for new languages
