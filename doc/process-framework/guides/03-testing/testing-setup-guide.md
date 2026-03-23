---
id: PF-GDE-051
type: Document
category: General
version: 1.0
created: 2026-03-22
updated: 2026-03-22
guide_category: 03-testing
guide_title: Testing Setup Guide
guide_status: Active
guide_description: Language-specific guide for scaffolding test infrastructure in new or existing projects. Covers directory structure, configuration files, fixtures, and framework integration.
related_tasks: PF-TSK-014,PF-TSK-053
---

# Testing Setup Guide

## Overview

Language-specific guide for scaffolding test infrastructure in new or existing projects. Covers directory structure, configuration files, fixtures, and framework integration.

## When to Use

- During **Project Initiation** — scaffolding test infrastructure for a new project
- During **Codebase Feature Discovery** — onboarding an existing project into the framework
- When adding a **new language** to a multi-language project

## Prerequisites

- `project-config.json` exists with `testing.testDirectory` and `testing.language` configured
- Language config exists in `languages-config/{language}-config.json`
- The project's test runner is installed (e.g., `pip install pytest pytest-cov` for Python)

## Architecture

Testing infrastructure has two layers:

| Layer | Owned by | Purpose | Files |
|---|---|---|---|
| **Framework** | Process framework | Runs, tracks, and reports on tests | `Run-Tests.ps1`, `test-registry.yaml`, `test-tracking.md`, `{language}-config.json` |
| **Project** | The project | Contains the actual test code | `conftest.py`, `pytest.ini`, `test/**/*.py`, etc. |

This guide sets up the **project layer**. The framework layer is already in place.

## Step-by-Step Instructions

### 1. Create test directory structure

Create subdirectories matching your test categories in `project-config.json`:

```bash
# Read testDirectory from project-config.json (e.g., "test/automated")
mkdir -p test/automated/unit
mkdir -p test/automated/integration
mkdir -p test/automated/parsers      # optional, project-specific
mkdir -p test/automated/performance   # optional
```

Update `project-config.json` if categories were added:

```json
{
  "testing": {
    "testDirectory": "test/automated",
    "quickCategories": ["unit", "parsers"],
    "language": "python"
  }
}
```

**Expected Result:** `Run-Tests.ps1 -ListCategories` shows the created directories.

### 2. Create test runner configuration

Each language has a native config file that the test runner reads directly.

#### Python (pytest)

Create `pytest.ini` in project root:

```ini
[tool:pytest]
# Pytest-native configuration
# NOTE: Framework wrapper config is in doc/process-framework/languages-config/python-config.json
#       pytest.ini = pytest runtime config (markers, discovery, warnings, timeout)
#       python-config.json = Run-Tests.ps1 wrapper config (CLI flags, coverage args, categories)

testpaths = test/automated
python_files = test_*.py
python_classes = Test*
python_functions = test_*

addopts =
    --tb=short
    --strict-markers
    --strict-config
    --disable-warnings

markers =
    slow: Tests that take longer to run
    critical: Critical functionality tests
    # Add project-specific markers here

filterwarnings =
    ignore::DeprecationWarning

minversion = 7.0
timeout = 300
```

**Expected Result:** `python -m pytest --collect-only -q` discovers tests from the configured directory.

### 3. Create shared test fixtures / setup

#### Python (pytest)

Create `test/automated/conftest.py` with project-specific fixtures:

```python
"""
Shared pytest fixtures for the project.
Framework tracking: see languages-config/python-config.json testSetup section.
"""
import pytest
import tempfile
import shutil
from pathlib import Path


@pytest.fixture
def temp_project_dir():
    """Temporary directory for test isolation. Auto-cleaned after each test."""
    temp_dir = tempfile.mkdtemp()
    yield Path(temp_dir)
    shutil.rmtree(temp_dir, ignore_errors=True)


# Add project-specific fixtures below:
# @pytest.fixture
# def database():
#     """Set up test database."""
#     ...
```

Update `python-config.json` to register the setup file:

```json
"testSetup": {
  "mechanism": "pytest-fixtures",
  "configFiles": ["test/automated/conftest.py"],
  "discoveryCommand": "python -m pytest --fixtures -q"
}
```

**Expected Result:** `python -m pytest --fixtures -q` shows the shared fixtures.

### 4. Initialize framework tracking

Create empty tracking files for the new project:

```powershell
# Initialize test-registry.yaml (empty)
# Add entries as test files are created using Add-TestRegistryEntry

# Initialize test-tracking.md sections
# Sections are created automatically by Update-TestImplementationStatusEnhanced
```

Register each test file as it's created:

```powershell
# Via the Integration & Testing task (PF-TSK-053) which uses New-TestFile.ps1
# Or manually via TestTracking.psm1:
Add-TestRegistryEntry -FeatureId "1.2.3" -FileName "test_example.py" `
  -FilePath "test/automated/unit/test_example.py" -TestType "Unit" `
  -ComponentName "Example Component"
```

**Expected Result:** `Validate-TestTracking.ps1` passes with 0 errors.

### 5. Verify the setup

Run the full verification:

```powershell
# 1. Check categories are discovered
Run-Tests.ps1 -ListCategories

# 2. Run quick tests
Run-Tests.ps1 -Quick

# 3. Run with coverage
Run-Tests.ps1 -Coverage

# 4. Run with tracking update
Run-Tests.ps1 -All -UpdateTracking

# 5. Validate framework tracking
Validate-TestTracking.ps1
```

## Language-Specific Reference

| Concern | Python (pytest) | Dart (flutter_test) | JavaScript (Jest) |
|---|---|---|---|
| Native config | `pytest.ini` | `dart_test.yaml` | `jest.config.js` |
| Test discovery | Automatic by naming convention | Automatic by naming convention | Automatic by naming convention |
| Fixtures/setup | `conftest.py` (auto-discovered) | Helper files (manual import) | `jest.setup.js` (configured) |
| Markers/tags | `@pytest.mark.slow` | `@Tags('slow')` | `describe.skip()` / custom |
| Coverage | `pytest-cov` plugin | `--coverage` flag | `--coverage` flag |
| Framework config | `python-config.json` | `dart-config.json` | `javascript-config.json` |

## Related Resources

- [Test Infrastructure Guide](test-infrastructure-guide.md) — How the test/ directory connects to the process framework
- [Integration & Testing Usage Guide](test-implementation-usage-guide.md) — How to write tests using PF-TSK-053
- [Language Config Template](/doc/process-framework/templates/support/language-config-template.json) — Template for new language configurations
- [Run-Tests.ps1](/doc/process-framework/scripts/test/Run-Tests.ps1) — Framework test runner

