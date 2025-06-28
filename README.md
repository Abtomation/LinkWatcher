# LinkWatcher 2.0 - Real-time Link Maintenance System

[![CI/CD Pipeline](https://github.com/YOUR_USERNAME/LinkWatcher/workflows/CI%2FCD%20Pipeline/badge.svg)](https://github.com/YOUR_USERNAME/LinkWatcher/actions)
[![Python 3.8+](https://img.shields.io/badge/python-3.8+-blue.svg)](https://www.python.org/downloads/)
[![Windows](https://img.shields.io/badge/platform-Windows-blue.svg)](https://www.microsoft.com/windows)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![codecov](https://codecov.io/gh/YOUR_USERNAME/LinkWatcher/branch/main/graph/badge.svg)](https://codecov.io/gh/YOUR_USERNAME/LinkWatcher)
[![Tests](https://img.shields.io/badge/tests-247%20passing-green.svg)](./tests/)

A modern, reliable link maintenance system that uses file system watching to detect file movements and automatically update all references in real-time.

## 🚀 Quick Start

```cmd
# 1. Clone the repository
git clone https://github.com/YOUR_USERNAME/LinkWatcher.git
cd LinkWatcher

# 2. Install dependencies
pip install -r requirements.txt

# 3. Start monitoring your project
python link_watcher_new.py

# 4. Move any file - watch links update automatically! ✨
```

### **Development Setup (Windows)**

```cmd
# Setup development environment
dev dev-setup

# Run tests
dev test

# Check code quality
dev lint

# Format code
dev format
```

> **Note**: LinkWatcher 2.0 is optimized for Windows development. All CI/CD and testing is performed on Windows platform.

## 💻 Windows Requirements

- **Operating System**: Windows 10/11
- **Python**: 3.8, 3.9, 3.10, or 3.11
- **PowerShell**: 5.1+ or PowerShell Core 7+
- **Git**: For development and cloning

**Supported Windows Features:**
- ✅ Windows path separators (`\`)
- ✅ Drive letter handling (`C:\`, `D:\`)
- ✅ UNC path support (`\\server\share`)
- ✅ Junction points (Windows symlinks)
- ✅ Long path support (>260 characters)
- ✅ Case-insensitive file matching
- ✅ Windows file attributes (hidden files)

### **Development Setup (Windows)**

```cmd
# Setup development environment
dev dev-setup

# Run tests
dev test

# Check code quality
dev lint

# Format code
dev format
```

> **Note**: LinkWatcher 2.0 is optimized for Windows development. All CI/CD and testing is performed on Windows platform.
## ✨ Features

- 🔄 **Real-time monitoring** - Automatically detects file moves/renames
- 📝 **Multi-format support** - Markdown, YAML, JSON, Python, Dart, and more
- 🛡️ **Safe updates** - Atomic operations with backup creation
- 🎯 **Accurate parsing** - File-type specific parsers for precision
- ⚡ **High performance** - Handles large projects efficiently
- 🔧 **Highly configurable** - Customize behavior for your needs
- 🧪 **Dry run mode** - Preview changes before applying
- 📊 **Detailed statistics** - Track operations and performance

## 📖 Documentation

| Document | Description |
|----------|-------------|
| [Installation Guide](docs/installation.md) | Detailed installation instructions |
| [Configuration Reference](docs/configuration.md) | All configuration options |
| [API Reference](docs/api-reference.md) | Programmatic usage |
| [Multi-Project Setup](MULTI_PROJECT_SETUP.md) | Using across multiple projects |
| [Architecture Overview](RESTRUCTURE_README.md) | Technical architecture details |
| [Migration Guide](docs/migration-guide.md) | Upgrading from v1.0 |
| [Troubleshooting](docs/troubleshooting.md) | Common issues and solutions |

## 🏗️ Architecture

LinkWatcher 2.0 features a modular architecture:

- **`linkwatcher/service.py`** - Main orchestration service
- **`linkwatcher/database.py`** - Link storage and management
- **`linkwatcher/parsers/`** - File-type specific parsers
- **`linkwatcher/updater.py`** - Safe file modification
- **`linkwatcher/handler.py`** - File system event handling
- **`linkwatcher/logging.py`** - Enhanced structured logging system
- **`linkwatcher/logging_config.py`** - Advanced logging configuration

## 📊 Enhanced Logging System

LinkWatcher 2.0 includes a comprehensive logging system with:

### **Features**
- **Structured Logging**: JSON-formatted logs with contextual information
- **Performance Monitoring**: Built-in timing and metrics collection
- **Multiple Outputs**: Console and file logging with different formats
- **Log Rotation**: Automatic file rotation with configurable size limits
- **Real-time Filtering**: Runtime log filtering by component, operation, level
- **Colored Output**: Beautiful console output with icons and colors

### **Quick Logging Setup**
```bash
# Enable debug logging
python link_watcher_new.py --debug

# Log to file
python link_watcher_new.py --log-file logs/linkwatcher.log

# Use configuration file
python link_watcher_new.py --config config-examples/debug-config.yaml
```

### **Real-time Dashboard**
```bash
# Monitor logs in real-time
python tools/logging_dashboard.py --log-file logs/linkwatcher.log

# Text mode (no curses)
python tools/logging_dashboard.py --text-mode
```

### **Configuration Examples**
- **[Basic Logging](config-examples/logging-config.yaml)** - Standard logging setup
- **[Debug Configuration](config-examples/debug-config.yaml)** - Troubleshooting setup
- **[Production Configuration](config-examples/production-config.yaml)** - Optimized for production
- **[Advanced Configuration](config-examples/advanced-logging-config.yaml)** - All features enabled

**📚 [Complete Logging Documentation](docs/LOGGING.md)**

## 🧪 Testing

### **Windows Testing Commands**

```cmd
# Quick development tests
dev test

# Run all tests (247 test methods)
dev test-all

# Run with coverage report
dev coverage

# Run specific test categories
python run_tests.py --unit          # Unit tests (35+ methods)
python run_tests.py --integration   # Integration tests (45+ methods)
python run_tests.py --parsers       # Parser tests (80+ methods)
python run_tests.py --performance   # Performance tests (5+ methods)
```

### **Alternative pytest Commands**
```cmd
# Run all tests
pytest tests/

# Run with coverage
pytest tests/ --cov=linkwatcher --cov-report=html

# Run specific test categories
pytest tests/unit/              # Unit tests
pytest tests/integration/       # Integration tests
pytest tests/parsers/           # Parser tests
pytest tests/performance/       # Performance tests (slower)
```

**Test Documentation:**
- [Test Suite Overview](tests/README.md) - **Complete guide** to test structure, documentation files, and usage
- [Test Plan](tests/TEST_PLAN.md) - **Strategy & Procedures**: Test methodology, execution matrices, environment setup, risk assessment
- [Test Case Status](tests/TEST_CASE_STATUS.md) - **Implementation Tracking**: Complete mapping of all 111 test cases to their implementations, status tracking, execution metrics
- [Manual Procedures](tests/manual/test_procedures.md) - Manual testing checklists
- [Test Template](tests/TEST_CASE_TEMPLATE.md) - Template for new test cases

## 🚀 CI/CD Pipeline

LinkWatcher features a comprehensive Windows-focused CI/CD pipeline:

**Automated Testing:**
- ✅ **247+ test methods** across all components
- ✅ **Python 3.8-3.11** compatibility testing
- ✅ **Windows-only** platform testing
- ✅ **Code coverage** reporting via Codecov
- ✅ **Performance benchmarks** on large projects

**Code Quality:**
- ✅ **Pre-commit hooks** (black, isort, flake8, mypy)
- ✅ **Automated formatting** and linting
- ✅ **Type checking** with mypy
- ✅ **Security scanning** for dependencies

**Pipeline Status:**
- **Build Status**: ![CI/CD Pipeline](https://github.com/YOUR_USERNAME/LinkWatcher/workflows/CI%2FCD%20Pipeline/badge.svg)
- **Coverage**: ![codecov](https://codecov.io/gh/YOUR_USERNAME/LinkWatcher/branch/main/graph/badge.svg)
- **Tests**: ![Tests](https://img.shields.io/badge/tests-247%20passing-green.svg)

## 📊 Performance

- Handles **1000+ files** efficiently
- **Sub-second** response to file changes
- **Memory efficient** - scales with project size
- **Thread-safe** operations

## 🤝 Contributing

We welcome contributions! LinkWatcher is optimized for Windows development.

**Quick Start for Contributors:**

```cmd
# 1. Fork and clone the repository
git clone https://github.com/YOUR_USERNAME/LinkWatcher.git
cd LinkWatcher

# 2. Setup development environment
dev dev-setup

# 3. Run tests to verify setup
dev test

# 4. Make your changes and test
dev test-all
dev lint
dev format
```

See [Contributing Guide](CONTRIBUTING.md) for detailed development workflow, testing guidelines, and code standards.

## 📜 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🔗 Links

- [Contributing Guide](CONTRIBUTING.md) - Development workflow and guidelines
- [Changelog](CHANGELOG.md) - Release history and changes
- [Original Implementation](old/link_watcher_old.py) (archived)
- [Test Suite](tests/) - Comprehensive test documentation
- [Example Configurations](examples/)

---

**Made with ❤️ for developers who move files and want their links to follow**
