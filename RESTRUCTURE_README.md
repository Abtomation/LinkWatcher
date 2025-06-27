# LinkWatcher 2.0 - Restructured Architecture

This document describes the new modular architecture of LinkWatcher, replacing the monolithic single-file design with a well-organized, maintainable structure.

## 🏗️ New Directory Structure

```
📁 LinkWatcher/
├── 📄 link_watcher_new.py         # New main entry point
├── 📄 old/link_watcher_old.py             # Original monolithic file (kept for reference)
├── 📄 requirements.txt
├── 📄 setup_project.py
├── 📄 install_global.py
│
├── 📁 linkwatcher/                # Core package
│   ├── 📄 __init__.py            # Package exports
│   ├── 📄 service.py             # Main service orchestration
│   ├── 📄 database.py            # Link database management
│   ├── 📄 parser.py              # Parser coordination
│   ├── 📄 updater.py             # File updating logic
│   ├── 📄 handler.py             # File system event handling
│   ├── 📄 models.py              # Data models
│   └── 📄 utils.py               # Utility functions
│
├── 📁 linkwatcher/parsers/        # File type parsers
│   ├── 📄 __init__.py
│   ├── 📄 base.py                # Base parser interface
│   ├── 📄 markdown.py            # Markdown parser
│   ├── 📄 yaml_parser.py         # YAML parser
│   ├── 📄 json_parser.py         # JSON parser
│   ├── 📄 dart.py                # Dart parser
│   ├── 📄 python.py              # Python parser
│   └── 📄 generic.py             # Generic text parser
│
├── 📁 linkwatcher/config/         # Configuration management
│   ├── 📄 __init__.py
│   ├── 📄 settings.py            # Configuration classes
│   └── 📄 defaults.py            # Default settings
│
├── 📁 tests/                     # Comprehensive test suite
│   ├── 📄 __init__.py
│   ├── 📄 conftest.py            # Pytest fixtures
│   ├── 📄 test_database.py       # Database tests
│   ├── 📄 test_parser.py         # Parser tests
│   ├── 📄 test_updater.py        # Updater tests
│   ├── 📄 test_service.py        # Service tests
│   ├── 📁 test_parsers/          # Parser-specific tests
│   │   ├── 📄 __init__.py
│   │   └── 📄 test_markdown.py   # Markdown parser tests
│   └── 📁 fixtures/              # Test data
│       ├── 📄 __init__.py
│       ├── 📄 sample_markdown.md
│       ├── 📄 sample_config.yaml
│       └── 📄 sample_data.json
│
└── 📁 scripts/                   # Utility scripts
    ├── 📄 __init__.py
    ├── 📄 check_links.py         # Standalone link checker
    └── 📄 benchmark.py           # Performance benchmarking
```

## 🎯 Key Improvements

### **1. Separation of Concerns**
- **`models.py`**: Clean data structures (`LinkReference`, `FileOperation`)
- **`database.py`**: Link storage and retrieval with thread safety
- **`parser.py`**: Coordinates file-type specific parsers
- **`updater.py`**: Handles file modifications safely
- **`handler.py`**: Manages file system events
- **`service.py`**: Orchestrates all components

### **2. Pluggable Parser Architecture**
- **Base interface**: `BaseParser` defines common contract
- **Specialized parsers**: Each file type has dedicated parser
- **Easy extensibility**: Add new parsers without touching core logic
- **Better accuracy**: File-type specific parsing rules

### **3. Configuration Management**
- **Flexible config**: YAML, JSON, environment variables, CLI args
- **Environment-specific**: Development, production, testing configs
- **Validation**: Built-in configuration validation
- **Defaults**: Sensible defaults for all settings

### **4. Comprehensive Testing**
- **Unit tests**: Each component tested in isolation
- **Integration tests**: End-to-end workflow testing
- **Fixtures**: Reusable test data and utilities
- **Performance tests**: Benchmarking and profiling

### **5. Better Error Handling**
- **Graceful degradation**: Failures don't crash the system
- **Detailed logging**: Better debugging information
- **Recovery mechanisms**: Automatic retry and fallback

## 🚀 Usage

### **Basic Usage (Same as Before)**
```bash
# Use the new entry point
python link_watcher_new.py

# Or keep using the original (still works)
python old/link_watcher_old.py
```

### **New Configuration Options**
```bash
# Use custom configuration
python link_watcher_new.py --config my_config.yaml

# Dry run mode (preview changes)
python link_watcher_new.py --dry-run

# Skip initial scan for faster startup
python link_watcher_new.py --no-initial-scan

# Quiet mode
python link_watcher_new.py --quiet
```

### **Configuration File Example**
```yaml
# linkwatcher_config.yaml
monitored_extensions:
  - .md
  - .yaml
  - .json
  - .py

ignored_directories:
  - .git
  - node_modules
  - __pycache__

create_backups: true
dry_run_mode: false
max_file_size_mb: 10
log_level: INFO
colored_output: true
```

### **Programmatic Usage**
```python
from linkwatcher import LinkWatcherService, LinkWatcherConfig

# Create custom configuration
config = LinkWatcherConfig(
    monitored_extensions={'.md', '.txt'},
    dry_run_mode=True
)

# Create and start service
service = LinkWatcherService('/path/to/project')
service.set_dry_run(config.dry_run_mode)
service.start(initial_scan=True)
```

## 🧪 Testing

### **Run All Tests**
```bash
# Install test dependencies
pip install pytest pytest-cov

# Run all tests
pytest

# Run with coverage
pytest --cov=linkwatcher

# Run specific test file
pytest tests/test_database.py

# Run with verbose output
pytest -v
```

### **Run Benchmarks**
```bash
# Basic benchmark
python scripts/benchmark.py

# Custom benchmark
python scripts/benchmark.py --files 500 --output results.json
```

### **Check Links**
```bash
# Check all links in project
python scripts/check_links.py

# Save results to file
python scripts/check_links.py --output broken_links.txt

# Quiet mode
python scripts/check_links.py --quiet
```

## 🔧 Development

### **Adding a New Parser**
1. Create parser class inheriting from `BaseParser`
2. Implement `parse_file()` method
3. Add to `linkwatcher/parsers/__init__.py`
4. Register in `parser.py`
5. Add tests in `tests/test_parsers/`

Example:
```python
# linkwatcher/parsers/xml.py
from .base import BaseParser
from ..models import LinkReference

class XmlParser(BaseParser):
    def parse_file(self, file_path: str) -> List[LinkReference]:
        # Implementation here
        pass
```

### **Extending Configuration**
1. Add new fields to `LinkWatcherConfig` in `settings.py`
2. Update `defaults.py` with default values
3. Add validation in `validate()` method
4. Update documentation

### **Adding New Features**
1. Identify the appropriate module (service, database, parser, etc.)
2. Add the feature with proper error handling
3. Write comprehensive tests
4. Update documentation
5. Consider backward compatibility

## 📊 Performance Improvements

### **Compared to Original**
- **Faster imports**: Only load needed components
- **Better memory usage**: More efficient data structures
- **Parallel processing**: Thread-safe operations
- **Reduced I/O**: Smarter file handling
- **Caching**: Better caching strategies

### **Benchmarking Results**
Run `python scripts/benchmark.py` to see current performance metrics.

## 🔄 Migration from v1.0

### **Backward Compatibility**
- Original `link_watcher.py` still works
- Same command-line interface
- Same functionality and behavior
- Gradual migration possible

### **Migration Steps**
1. **Test**: Run both versions side by side
2. **Configure**: Create configuration file if needed
3. **Switch**: Use `link_watcher_new.py` instead
4. **Customize**: Take advantage of new features
5. **Clean up**: Remove old file when confident

### **Breaking Changes**
- None! The new version is fully backward compatible
- New features are opt-in
- Configuration is optional (defaults work)

## 🛠️ Troubleshooting

### **Import Errors**
```bash
# Make sure you're in the right directory
cd /path/to/LinkWatcher

# Install dependencies
pip install -r requirements.txt

# Check Python path
python -c "import linkwatcher; print('OK')"
```

### **Configuration Issues**
```bash
# Validate configuration
python -c "from linkwatcher.config import LinkWatcherConfig; config = LinkWatcherConfig.from_file('config.yaml'); print(config.validate())"
```

### **Performance Issues**
```bash
# Run benchmark to identify bottlenecks
python scripts/benchmark.py

# Use smaller file size limit
python link_watcher_new.py --config config_with_smaller_limits.yaml
```

## 🎉 Benefits Summary

### **For Developers**
- ✅ **Easier to understand**: Clear module boundaries
- ✅ **Easier to test**: Isolated components
- ✅ **Easier to extend**: Plugin architecture
- ✅ **Better debugging**: Detailed error messages
- ✅ **Modern Python**: Type hints, dataclasses, pathlib

### **For Users**
- ✅ **Same functionality**: No feature loss
- ✅ **Better performance**: Optimized operations
- ✅ **More reliable**: Better error handling
- ✅ **More configurable**: Flexible settings
- ✅ **Better feedback**: Improved logging and statistics

### **For Projects**
- ✅ **Future-proof**: Extensible architecture
- ✅ **Maintainable**: Clean code organization
- ✅ **Testable**: Comprehensive test coverage
- ✅ **Scalable**: Handles larger projects better
- ✅ **Professional**: Industry-standard structure

---

## 🚀 Next Steps

1. **Try the new version**: `python link_watcher_new.py`
2. **Run tests**: `pytest` to verify everything works
3. **Create config**: Customize settings for your needs
4. **Provide feedback**: Report any issues or suggestions
5. **Contribute**: Help improve the system further

The new architecture provides a solid foundation for future enhancements while maintaining full compatibility with existing workflows. Enjoy the improved LinkWatcher experience! 🎉
