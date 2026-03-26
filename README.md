# LinkWatcher 2.0 - Real-time Link Maintenance System

[![Python 3.8+](https://img.shields.io/badge/python-3.8+-blue.svg)](https://www.python.org/downloads/)
[![Windows](https://img.shields.io/badge/platform-Windows-blue.svg)](https://www.microsoft.com/windows)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A modern, reliable link maintenance system that uses file system watching to detect file movements and automatically update all references in real-time.

## 🚀 Quick Start

```cmd
# 1. Clone the repository
git clone https://github.com/YOUR_USERNAME/LinkWatcher.git
cd LinkWatcher

# 2. Install dependencies
pip install -e .

# 3. Start monitoring your project
python main.py

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
| [Quick Reference](doc/product-docs/user/handbooks/quick-reference.md) | CLI options, config, environment variables, examples |
| [Multi-Project Setup](doc/product-docs/user/handbooks/multi-project-setup.md) | Using across multiple projects |
| [File Type Quick Fix](doc/product-docs/user/handbooks/file-type-quick-fix.md) | **Quick fix** for file types not being monitored |
| [File Type Troubleshooting](doc/product-docs/user/handbooks/troubleshooting-file-types.md) | **Detailed guide** for file type monitoring issues |

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
python main.py --debug

# Log to file
python main.py --log-file logs/linkwatcher.log

# Use configuration file
python main.py --config config-examples/debug-config.yaml
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

**📚 See configuration examples above for logging setup.**

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
pytest test/automated/unit/              # Unit tests (35+ methods)
pytest test/automated/integration/       # Integration tests (45+ methods)
pytest test/automated/parsers/           # Parser tests (80+ methods)
pytest test/automated/performance/       # Performance tests (slower)
```

### **Alternative: Process Framework Test Runner**
```cmd
# Language-agnostic test runner (reads project-config.json + languages-config/)
pwsh.exe -ExecutionPolicy Bypass -Command '& doc/process-framework/scripts/test/Run-Tests.ps1 -ListCategories'
pwsh.exe -ExecutionPolicy Bypass -Command '& doc/process-framework/scripts/test/Run-Tests.ps1 -Category unit'
pwsh.exe -ExecutionPolicy Bypass -Command '& doc/process-framework/scripts/test/Run-Tests.ps1 -All -Coverage'
pwsh.exe -ExecutionPolicy Bypass -Command '& doc/process-framework/scripts/test/Run-Tests.ps1 -Quick'
```

### **Direct pytest Commands**
```cmd
# Run all tests
pytest test/automated/

# Run with coverage
pytest test/automated/ --cov=linkwatcher --cov-report=html
```

**Test Documentation:**
- [Test Infrastructure Guide](doc/process-framework/guides/03-testing/test-infrastructure-guide.md) - How the test/ directory connects to the process framework
- [Test Registry](test/test-registry.yaml) - Central registry of all test files with PD-TST IDs
- [Test Specifications](test/specifications/feature-specs/) - Feature-level test specifications
- [E2E Acceptance Tests](test/e2e-acceptance-testing) - Formal E2E acceptance test framework with E2E-* IDs

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

## 📜 License

MIT License

## 🔗 Links

- [Test Suite](test/automated/) - Comprehensive test documentation
- [Example Configurations](config-examples/) - YAML configuration examples

---

**Made with ❤️ for developers who move files and want their links to follow**
