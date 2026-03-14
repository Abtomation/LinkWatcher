# Contributing to LinkWatcher

Thank you for your interest in contributing to LinkWatcher! This guide will help you get started with the development workflow.

## 🎯 Overview

LinkWatcher is a Windows-focused link maintenance system with a comprehensive CI/CD pipeline. All development and testing is optimized for Windows environments.

## 🛠️ Development Setup

### **Prerequisites**

- **Windows 10/11** (required)
- **Python 3.8+** (3.8, 3.9, 3.10, 3.11 supported)
- **Git** for version control
- **PowerShell** or **Command Prompt**

### **Quick Setup**

```cmd
# 1. Fork and clone the repository
git clone https://github.com/YOUR_USERNAME/LinkWatcher.git
cd LinkWatcher

# 2. Setup development environment (installs dependencies + pre-commit hooks)
dev dev-setup

# 3. Verify setup
dev test
```

### **Manual Setup**

```cmd
# Install dependencies
pip install -r requirements.txt
pip install ".[test]"
pip install -e ".[dev]"

# Install pre-commit hooks
python -m pre_commit install
python -m pre_commit install --hook-type commit-msg
```

## 🔧 Development Commands

LinkWatcher provides Windows-native batch commands for development:

### **Testing**

```cmd
dev test           # Quick tests (unit + parsers)
dev test-all       # All tests including slow ones
dev coverage       # Generate coverage report
dev ci-test        # Run full CI test suite locally
```

### **Code Quality**

```cmd
dev lint           # Run linting checks (flake8)
dev format         # Format code (black + isort)
dev type-check     # Run type checking (mypy)
```

### **Build & Package**

```cmd
dev clean          # Clean build artifacts
dev build          # Build distribution package
```

## 🧪 Testing Strategy

### **Test Structure**

```
tests/
├── unit/                    # Unit tests (35+ methods)
│   ├── test_database.py     # Database operations
│   ├── test_parser.py       # Core parsing functionality
│   ├── test_service.py      # Service lifecycle
│   ├── test_updater.py      # File update mechanisms
│   └── test_config.py       # Configuration management
├── integration/             # Integration tests (45+ methods)
│   ├── test_windows_platform.py    # Windows-specific tests
│   ├── test_complex_scenarios.py   # Real-world scenarios
│   ├── test_error_handling.py      # Error conditions
│   ├── test_file_movement.py       # File operations
│   ├── test_link_updates.py        # Link update operations
│   └── test_service_integration.py # End-to-end testing
├── parsers/                 # Parser tests (80+ methods)
│   ├── test_markdown_parser.py     # Markdown parsing
│   ├── test_yaml_parser.py         # YAML parsing
│   ├── test_json_parser.py         # JSON parsing
│   ├── test_python_parser.py       # Python import parsing
│   └── test_dart_parser.py         # Dart import parsing
├── performance/             # Performance tests (5+ methods)
│   └── test_large_projects.py      # Large-scale validation
└── manual/                  # Manual test procedures
    └── test_procedures.md           # Manual testing checklists
```

### **Test Categories**

- **Unit Tests**: Fast, isolated component testing
- **Integration Tests**: Component interaction testing
- **Parser Tests**: File format parsing validation
- **Performance Tests**: Large-scale performance validation
- **Manual Tests**: Real-world usage scenarios

### **Running Specific Tests**

```cmd
# By category
python run_tests.py --unit
python run_tests.py --integration
python run_tests.py --parsers
python run_tests.py --performance

# By file
pytest tests/unit/test_database.py
pytest tests/integration/test_windows_platform.py

# By test method
pytest tests/unit/test_database.py::TestLinkDatabase::test_add_link
```

## 📋 Development Workflow

### **1. Before You Start**

1. **Check existing issues** - Look for related work
2. **Create an issue** - Describe the feature/bug
3. **Fork the repository** - Create your own copy
4. **Create a branch** - Use descriptive names

```cmd
git checkout -b feature/your-feature-name
# or
git checkout -b fix/issue-description
```

### **2. Development Process**

1. **Write tests first** (TDD approach recommended)
2. **Implement your changes**
3. **Run tests frequently**

```cmd
# Quick feedback loop
dev test
```

4. **Check code quality**

```cmd
dev lint
dev format
dev type-check
```

### **3. Before Committing**

Pre-commit hooks will automatically run, but you can run them manually:

```cmd
# Run pre-commit checks
python -m pre_commit run --all-files

# Or use the dev command
dev lint
dev format
```

### **4. Commit Guidelines**

Use conventional commit messages:

```
feat: add new parser for TypeScript files
fix: resolve path handling issue on Windows
docs: update installation instructions
test: add integration tests for file movement
refactor: simplify database connection logic
```

### **5. Pull Request Process**

1. **Push your branch**

```cmd
git push origin feature/your-feature-name
```

2. **Create Pull Request** on GitHub
3. **Fill out PR template** with:
   - Description of changes
   - Testing performed
   - Breaking changes (if any)
4. **Wait for CI/CD** - All tests must pass
5. **Address review feedback**

## 🏗️ Architecture Guidelines

### **Code Organization**

```
linkwatcher/
├── __init__.py              # Package initialization
├── service.py               # Main orchestration service
├── database.py              # Link storage and management
├── updater.py               # Safe file modification
├── handler.py               # File system event handling
├── config.py                # Configuration management
└── parsers/                 # File-type specific parsers
    ├── __init__.py
    ├── base.py              # Base parser interface
    ├── markdown.py          # Markdown parser
    ├── yaml_parser.py       # YAML parser
    ├── json_parser.py       # JSON parser
    ├── python_parser.py     # Python import parser
    └── dart_parser.py       # Dart import parser
```

### **Design Principles**

1. **Windows-First**: Optimize for Windows development
2. **Modular Design**: Clear separation of concerns
3. **Thread Safety**: All operations must be thread-safe
4. **Error Handling**: Graceful degradation and recovery
5. **Performance**: Efficient handling of large projects
6. **Testability**: All code must be testable

### **Adding New Parsers**

1. **Inherit from BaseParser**

```python
from linkwatcher.parsers.base import BaseParser

class YourParser(BaseParser):
    def get_supported_extensions(self):
        return ['.your_ext']

    def parse_file(self, file_path):
        # Implementation
        pass
```

2. **Add comprehensive tests**

```python
# tests/parsers/test_your_parser.py
class TestYourParser:
    def test_parse_valid_file(self):
        # Test implementation
        pass
```

3. **Register the parser**

```python
# In linkwatcher/parsers/__init__.py
from .your_parser import YourParser
```

## 🚨 Code Quality Standards

### **Code Style**

- **Black** for code formatting
- **isort** for import sorting
- **flake8** for linting
- **mypy** for type checking

### **Testing Requirements**

- **Minimum 90% code coverage**
- **All new features must have tests**
- **All bug fixes must have regression tests**
- **Performance tests for significant changes**

### **Documentation Requirements**

- **Docstrings** for all public methods
- **Type hints** for all function signatures
- **README updates** for new features
- **Changelog entries** for releases

## 🔄 CI/CD Pipeline

### **Automated Checks**

Every push and pull request triggers:

1. **Test Suite** (247+ tests on Windows)
2. **Code Quality** (linting, formatting, type checking)
3. **Security Scan** (dependency vulnerabilities)
4. **Performance Tests** (on main branch)
5. **Coverage Report** (uploaded to Codecov)

### **Branch Protection**

- **All checks must pass** before merging
- **At least one review** required for PRs
- **Up-to-date branches** required

### **Release Process**

1. **Version bump** in `setup.py` and `pyproject.toml`
2. **Update CHANGELOG.md**
3. **Create release tag**
4. **Automated PyPI deployment** (future)

## 🐛 Bug Reports

### **Before Reporting**

1. **Search existing issues**
2. **Check if it's already fixed** in main branch
3. **Reproduce the issue** consistently

### **Bug Report Template**

```markdown
## Bug Description
Brief description of the issue

## Steps to Reproduce
1. Step one
2. Step two
3. Step three

## Expected Behavior
What should happen

## Actual Behavior
What actually happens

## Environment
- Windows Version:
- Python Version:
- LinkWatcher Version:

## Additional Context
Any other relevant information
```

## 💡 Feature Requests

### **Feature Request Template**

```markdown
## Feature Description
Brief description of the proposed feature

## Use Case
Why is this feature needed?

## Proposed Solution
How should this feature work?

## Alternatives Considered
Other approaches you've considered

## Additional Context
Any other relevant information
```

## 📚 Resources

### **Documentation**

- [Test Plan](tests/TEST_PLAN.md) - Comprehensive testing strategy
- [CI/CD Guide](docs/ci-cd.md) - Pipeline documentation
- [Architecture Overview](RESTRUCTURE_README.md) - Technical details
- [API Reference](docs/api-reference.md) - Programmatic usage

### **Development Tools**

- [Windows Batch Script](dev.bat) - Development commands
- [Pre-commit Config](.pre-commit-config.yaml) - Code quality hooks
- [GitHub Actions](.github/workflows/ci.yml) - CI/CD pipeline

## 🤝 Community

### **Getting Help**

1. **Check documentation** first
2. **Search existing issues**
3. **Create a new issue** with detailed information
4. **Be patient and respectful**

### **Code of Conduct**

- **Be respectful** to all contributors
- **Provide constructive feedback**
- **Help others learn and grow**
- **Focus on the code, not the person**

## 🎉 Recognition

Contributors will be recognized in:

- **CONTRIBUTORS.md** file
- **Release notes** for significant contributions
- **GitHub contributors** section

---

**Thank you for contributing to LinkWatcher! Your efforts help make file link maintenance easier for developers everywhere.** 🚀
