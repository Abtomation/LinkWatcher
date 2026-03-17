---
id: PF-GDE-050
type: Document
category: Guide
version: 1.0
created: 2026-03-16
updated: 2026-03-16
guide_description: How the test/ directory connects to the process framework
related_tasks: PF-TSK-053,PF-TSK-012,PF-TSK-030,PF-TSK-069,PF-TSK-070
guide_status: Active
guide_category: 03-testing
guide_title: Test Infrastructure Guide
---

# Test Infrastructure Guide

## Overview

The `test/` directory is the single home for all testing concerns in a project using the process framework. It unifies automated test code, test specifications, manual test cases, and test audit reports under one roof, with clear connections to the process framework's tracking and governance infrastructure.

## When to Use

- When setting up test infrastructure for a new project adopting the process framework
- When migrating an existing project's tests into the framework structure
- When you need to understand how test files, specifications, and audits relate to each other
- When creating new tests and need to know where they belong

## Directory Structure

```
test/
├── automated/                      # All pytest-discovered test code
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
├── manual-testing/                 # Formal manual test framework (MT-*)
│   ├── templates/                  # Pristine test case fixtures (never modified)
│   │   └── <group-name>/           # One directory per MT-GRP
│   │       └── MT-NNN-<name>/      # Individual test cases
│   │           ├── test-case.md    # Steps, preconditions, expected results
│   │           ├── project/        # Starting state files
│   │           └── expected/       # Post-test expected state
│   ├── workspace/                  # Generated working copies (gitignored)
│   └── results/                    # Execution logs (gitignored)
│
├── audits/                         # Test audit reports (PF-TAR-*)
│   └── <category>/                 # Grouped by feature category
│
└── test-registry.yaml              # Central registry of all test files (PD-TST-*)
```

## How It Connects to the Process Framework

### Source of Truth Files

| File | Location | Purpose | Updated By |
|------|----------|---------|------------|
| **test-registry.yaml** | `test/` | Central registry of all automated test files with PD-TST IDs, feature mappings, and status | `New-TestFile.ps1` (automated), manual edits |
| **test-tracking.md** | `doc/process-framework/state-tracking/permanent` | Workflow status tracker — test implementation progress, audit results, execution dates | `New-TestFile.ps1`, `Update-TestExecutionStatus.ps1`, manual edits |
| **feature-tracking.md** | `doc/process-framework/state-tracking/permanent` | Feature-level test status column | `New-TestFile.ps1`, `Update-TestExecutionStatus.ps1` |

### Key Principle: No Duplicate Tracking

The process framework eliminated redundant test tracking files. There is **no** separate README, TEST_PLAN, TEST_CASE_STATUS, or TEST_CASE_TEMPLATE in the test directory. All tracking is handled by:

- **test-registry.yaml** — what test files exist, their IDs, features, and status
- **test-tracking.md** — workflow status, audit results, execution history
- **test specifications** — what should be tested (derived from TDDs)
- **manual test case templates** (PF-TEM-053, PF-TEM-054) — how to create manual tests

### Automation Scripts

| Script | Location | Purpose |
|--------|----------|---------|
| `New-TestFile.ps1` | `scripts/file-creation/` | Create automated test files with PD-TST IDs |
| `New-ManualTestCase.ps1` | `scripts/file-creation/` | Create manual test cases with MT IDs |
| `New-TestSpecification.ps1` | `scripts/file-creation/` | Create test specifications with PF-TSP IDs |
| `New-TestAuditReport.ps1` | `scripts/file-creation/` | Create test audit reports with PF-TAR IDs |
| `Run-Tests.ps1` | `scripts/test/` | Project-agnostic test runner (reads project-config.json) |
| `Setup-TestEnvironment.ps1` | `scripts/test/manual-testing/` | Copy pristine fixtures to workspace for manual testing |
| `Verify-TestResult.ps1` | `scripts/test/manual-testing/` | Compare workspace state against expected state |
| `Update-TestExecutionStatus.ps1` | `scripts/test/manual-testing/` | Update test-tracking.md with manual test results |
| `Validate-TestTracking.ps1` | `scripts/validation/` | Validate consistency between registry, tracking, and disk |

### Related Tasks

| Task | ID | Relationship to test/ |
|------|----|-----------------------|
| Integration and Testing | PF-TSK-053 | Creates test files in `test/automated/` using `New-TestFile.ps1` |
| Test Specification Creation | PF-TSK-012 | Creates specs in `test/specifications/feature-specs/` |
| Test Audit | PF-TSK-030 | Creates audit reports in `test/audits/` |
| Manual Test Case Creation | PF-TSK-069 | Creates test cases in `test/manual-testing/templates/` |
| Manual Test Execution | PF-TSK-070 | Executes tests from `test/manual-testing/templates/` in `workspace/` |

## Configuration

The test directory path is configured in `doc/process-framework/project-config.json`:

```json
{
  "paths": {
    "tests": "test/automated"
  }
}
```

`Run-Tests.ps1` and `New-TestFile.ps1` read this path to locate test files.

Pytest configuration (`pytest.ini` or `pyproject.toml`) must match:

```ini
[tool:pytest]
testpaths = test/automated
```

## Running Tests

Use the project-agnostic test runner:

```bash
# From project root (via process framework scripts)
cd doc/process-framework/scripts/test
pwsh.exe -ExecutionPolicy Bypass -Command '& .\Run-Tests.ps1 -Unit'
pwsh.exe -ExecutionPolicy Bypass -Command '& .\Run-Tests.ps1 -All -Coverage'
pwsh.exe -ExecutionPolicy Bypass -Command '& .\Run-Tests.ps1 -Quick'
```

Or use pytest directly:

```bash
python -m pytest test/automated/                    # All tests
python -m pytest test/automated/unit/                # Unit tests only
python -m pytest test/automated/ --cov=linkwatcher   # With coverage
```

## Setting Up Test Infrastructure for a New Project

When adopting the process framework into an existing project:

1. Create the `test/` directory structure (automated/, specifications/, manual-testing/)
2. Create `test/test-registry.yaml` with the standard header
3. Set up `conftest.py` in `test/automated/` with project-specific fixtures
4. Configure `pytest.ini` with `testpaths = test/automated`
5. Update `project-config.json` with `"tests": "test/automated"`
6. Migrate existing tests into the appropriate subdirectories (unit/, integration/, etc.)
7. Register test files using `New-TestFile.ps1`

This is typically done during the onboarding workflow (PF-TSK-064 Codebase Feature Discovery → PF-TSK-066 Retrospective Documentation Creation).

## Related Resources

- [Test Specification Creation Task (PF-TSK-012)](/doc/process-framework/tasks/03-testing/test-specification-creation-task.md)
- [Integration and Testing Task (PF-TSK-053)](/doc/process-framework/tasks/04-implementation/integration-and-testing.md)
- [Test Audit Task (PF-TSK-030)](/doc/process-framework/tasks/03-testing/test-audit-task.md)
- [Manual Test Case Creation Task (PF-TSK-069)](/doc/process-framework/tasks/03-testing/manual-test-case-creation-task.md)
- [Manual Test Case Template (PF-TEM-054)](/doc/process-framework/templates/03-testing/manual-test-case-template.md)
- [Test File Template (test-file-template.py)](/doc/process-framework/templates/03-testing/test-file-template.py)
