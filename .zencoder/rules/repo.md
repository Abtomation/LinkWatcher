---
description: Repository Information Overview
alwaysApply: true
---

# LinkWatcher 2.0 Information

## Summary
**LinkWatcher 2.0** is a real-time link maintenance system built with Python. It uses file system watching (via `watchdog`) to automatically detect file movements and renames, updating all references (links) across a project in real-time. It supports multiple file formats including Markdown, YAML, JSON, Python, and Dart.

## Structure
- **linkwatcher_doc/**: Core Python package containing the service orchestration, database management, parsers, and update logic.
- **doc/process-framework/**: A structured meta-framework for development lifecycle management, including task definitions, state tracking, and templates.
- **LinkWatcher/**: Directory containing convenience startup scripts for different shells (PowerShell, Batch, Bash).
- **tests/**: Comprehensive test suite organized into unit, integration, parser, and performance tests.
- **tools/** & **scripts/**: Utility scripts for benchmarking, CI/CD setup, and a real-time logging dashboard.
- **deployment/**: Scripts for global installation and project-specific setup.

## Language & Runtime
**Language**: Python
**Version**: 3.8, 3.9, 3.10, 3.11
**Build System**: setuptools (pyproject.toml, setup.py)
**Package Manager**: pip

## Dependencies
**Main Dependencies**:
- `watchdog>=6.0.0`: File system monitoring
- `PyYAML>=6.0`: YAML parsing
- `markdown>=3.4.0`: Markdown parsing
- `gitpython>=3.1.0`: Git integration
- `colorama>=0.4.6`: Colored terminal output
- `structlog>=23.1.0`: Structured logging
- `tenacity>=8.2.0`: Retry mechanisms

**Development Dependencies**:
- `pytest`, `pytest-cov`, `pytest-mock`, `pytest-xdist`: Testing framework and plugins
- `black`, `isort`, `flake8`, `mypy`: Linting and formatting
- `pre-commit`: Git hooks management

## Build & Installation
```bash
# Install production dependencies
pip install -r requirements.txt

# Install for development
pip install -e .[dev,test]

# Global installation (via provided script)
python deployment/install_global.py
```

## Testing
**Framework**: pytest
**Test Location**: `tests/`
**Naming Convention**: `test_*.py` and `Test*` classes
**Configuration**: `pyproject.toml` ([tool.pytest.ini_options]), `pytest.ini`

**Run Command**:
```bash
# Using the dev utility
dev test         # Quick tests (unit + parsers)
dev test-all     # All tests

# Using the test runner script
python run_tests.py --all

# Direct pytest usage
pytest tests/
```

## Main Files & Resources
- **main.py**: Primary CLI entry point for starting the monitoring service.
- **linkwatcher_doc/service.py**: Core service orchestrator.
- **linkwatcher_doc/database.py**: Link reference storage and management.
- **dev.bat**: Windows development command utility.
- **CLAUDE.md**: Project overview and mandatory workflow guidelines.
- **.ai-entry-point.md**: Entry point for AI agents.

## Project Structure (Detailed)
- **Monorepo Style**: Contains both the core product (`linkwatcher_doc`) and a comprehensive process framework (`doc/process-framework`).
- **Process Framework**: Uses a strict task-based approach for all development activities, with mandatory deliverables and feedback cycles.
- **Windows Optimized**: Built and tested specifically for Windows environments, supporting drive letters, UNC paths, and Windows-specific file attributes.
