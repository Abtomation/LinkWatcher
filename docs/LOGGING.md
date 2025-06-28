# LinkWatcher Enhanced Logging System

## 🎯 Overview

LinkWatcher 2.0 features a comprehensive logging system that provides structured, contextual, and performance-aware logging capabilities. The system is designed for both development debugging and production monitoring.

## 🚀 Key Features

- **Structured Logging**: JSON-formatted logs for easy parsing and analysis
- **Contextual Information**: Thread-local context that enriches log messages
- **Performance Monitoring**: Built-in timing and metrics collection
- **Multiple Outputs**: Console and file logging with different formats
- **Log Rotation**: Automatic log file rotation with configurable size limits
- **Colored Output**: Beautiful console output with icons and colors
- **Thread Safety**: Safe for concurrent operations
- **Easy Migration**: Backward-compatible convenience functions

## 📊 Log Levels

| Level | Description | Use Case |
|-------|-------------|----------|
| `DEBUG` | Detailed diagnostic information | Development, troubleshooting |
| `INFO` | General operational messages | Normal operation tracking |
| `WARNING` | Warning messages for potential issues | Non-critical problems |
| `ERROR` | Error messages for failures | Error tracking and alerting |
| `CRITICAL` | Critical errors that may stop the application | System failures |

## 🔧 Configuration

### Basic Configuration

```python
from linkwatcher.logging import setup_logging, LogLevel

# Setup with default settings
logger = setup_logging()

# Setup with custom settings
logger = setup_logging(
    level=LogLevel.DEBUG,
    log_file="logs/linkwatcher.log",
    colored_output=True,
    show_icons=True,
    json_logs=False,
    max_file_size=10 * 1024 * 1024,  # 10MB
    backup_count=5
)
```

### Configuration File (YAML)

```yaml
# Logging configuration
log_level: "INFO"                    # DEBUG, INFO, WARNING, ERROR, CRITICAL
colored_output: true                 # Enable colored console output
show_statistics: true                # Show statistics on shutdown
log_file: "logs/linkwatcher.log"     # Log to file (optional)
log_file_max_size_mb: 10            # Max log file size before rotation
log_file_backup_count: 5            # Number of backup log files to keep
json_logs: false                     # Use JSON format for file logs
show_log_icons: true                 # Show emoji icons in console logs
performance_logging: true           # Enable performance metrics logging
```

### Environment Variables

```bash
export LINKWATCHER_LOG_LEVEL=DEBUG
export LINKWATCHER_COLORED_OUTPUT=true
export LINKWATCHER_LOG_FILE=/var/log/linkwatcher.log
```

### Command Line Arguments

```bash
# Enable debug logging
python link_watcher_new.py --debug

# Log to file
python link_watcher_new.py --log-file logs/debug.log

# Quiet mode (errors only)
python link_watcher_new.py --quiet
```

## 📝 Usage Examples

### Basic Logging

```python
from linkwatcher.logging import get_logger

logger = get_logger()

# Basic log messages
logger.info("Application started")
logger.warning("Configuration file not found, using defaults")
logger.error("Failed to parse file", file_path="invalid.md", error="syntax error")

# With additional context
logger.debug("Processing file",
            file_path="docs/api.md",
            file_size=1024,
            references_found=5)
```

### Contextual Logging

```python
from linkwatcher.logging import get_logger, with_context

logger = get_logger()

# Set context for current thread
logger.set_context(operation="file_scan", user_id="admin")

# All subsequent logs will include this context
logger.info("Starting scan")  # Will include operation=file_scan, user_id=admin
logger.debug("Found file", file_path="test.md")

# Clear context
logger.clear_context()

# Using decorator for automatic context management
@with_context(component="parser", file_type="markdown")
def parse_markdown_file(file_path):
    logger.info("Parsing file", file_path=file_path)
    # All logs in this function will include component=parser, file_type=markdown
```

### Performance Logging

```python
from linkwatcher.logging import get_logger, LogTimer

logger = get_logger()

# Using context manager for timing
with LogTimer("file_processing", logger, file_count=100):
    # Your code here
    process_files()
    # Automatically logs start, end, and duration

# Manual performance logging
timer_id = logger.performance.start_timer("database_query")
# ... perform operation ...
logger.performance.end_timer(timer_id, "database_query", records_processed=500)

# Log metrics
logger.performance.log_metric("memory_usage", 256.5, "MB", component="parser")
```

### Event-Specific Logging

```python
from linkwatcher.logging import get_logger

logger = get_logger()

# Convenience methods for common LinkWatcher events
logger.file_moved("docs/old.md", "docs/new.md", references_count=3)
logger.file_deleted("temp.md", references_count=1)
logger.file_created("new_doc.md")
logger.links_updated("README.md", references_updated=2)
logger.scan_progress(files_scanned=150, total_files=200)
logger.operation_stats(files_moved=5, links_updated=12, errors=0)
```

## 📋 Log Formats

### Console Output (Colored)

```
ℹ️  14:30:25.123 INFO     linkwatcher.service  Service started [project_root=/home/user/project, dry_run=false]
📁 14:30:25.456 INFO     linkwatcher.handler  File moved [old_path=docs/api.md, new_path=docs/reference/api.md, references_count=3]
✅ 14:30:25.789 INFO     linkwatcher.updater  Links updated [file_path=README.md, references_updated=2]
⚠️  14:30:26.012 WARNING linkwatcher.parser   Failed to parse file [file_path=invalid.md, error=syntax error]
```

### Console Output (Plain)

```
14:30:25.123 INFO     linkwatcher.service  Service started [project_root=/home/user/project, dry_run=false]
14:30:25.456 INFO     linkwatcher.handler  File moved [old_path=docs/api.md, new_path=docs/reference/api.md, references_count=3]
14:30:25.789 INFO     linkwatcher.updater  Links updated [file_path=README.md, references_updated=2]
14:30:26.012 WARNING linkwatcher.parser   Failed to parse file [file_path=invalid.md, error=syntax error]
```

### JSON Output (File Logs)

```json
{
  "timestamp": "2024-01-15T14:30:25.123456",
  "level": "INFO",
  "logger": "linkwatcher.service",
  "message": "Service started",
  "module": "service",
  "function": "start",
  "line": 75,
  "thread": 12345,
  "thread_name": "MainThread",
  "context": {
    "project_root": "/home/user/project",
    "dry_run": false
  }
}
```

## 🔍 Debugging and Troubleshooting

### Enable Debug Logging

```bash
# Command line
python link_watcher_new.py --debug

# Environment variable
export LINKWATCHER_LOG_LEVEL=DEBUG

# Configuration file
log_level: "DEBUG"
```

### Debug Configuration Example

```yaml
# debug-config.yaml
log_level: "DEBUG"
colored_output: true
show_statistics: true
log_file: "logs/linkwatcher-debug.log"
log_file_max_size_mb: 50
log_file_backup_count: 10
json_logs: true
show_log_icons: true
performance_logging: true
create_backups: true  # Safety during debugging
```

### Common Debug Scenarios

```python
# Debug file parsing issues
logger.set_context(component="parser")
logger.debug("Parsing file", file_path=file_path, file_size=os.path.getsize(file_path))

# Debug link resolution
logger.set_context(component="updater")
logger.debug("Resolving link",
            original_target=original_target,
            reference_file=ref.file_path,
            resolved_target=resolved_target)

# Debug performance issues
with LogTimer("slow_operation", logger, file_count=1000):
    slow_operation()
```

## 📊 Log Analysis

### Analyzing JSON Logs

```bash
# Find all errors
jq 'select(.level == "ERROR")' logs/linkwatcher.log

# Find file move operations
jq 'select(.message == "file_moved")' logs/linkwatcher.log

# Performance analysis
jq 'select(.message == "operation_completed") | {operation: .operation, duration: .duration_ms}' logs/linkwatcher.log

# Count operations by type
jq -r '.context.event_type // "unknown"' logs/linkwatcher.log | sort | uniq -c
```

### Log Aggregation with ELK Stack

```yaml
# logstash.conf
input {
  file {
    path => "/var/log/linkwatcher/*.log"
    codec => json
  }
}

filter {
  if [logger] =~ /linkwatcher/ {
    mutate {
      add_tag => ["linkwatcher"]
    }
  }
}

output {
  elasticsearch {
    hosts => ["localhost:9200"]
    index => "linkwatcher-%{+YYYY.MM.dd}"
  }
}
```

## 🚀 Production Recommendations

### Production Configuration

```yaml
# production-config.yaml
log_level: "WARNING"                 # Only warnings and errors
colored_output: false                # Disable colors for log aggregation
show_statistics: false               # Disable statistics
log_file: "/var/log/linkwatcher/linkwatcher.log"
log_file_max_size_mb: 100           # Larger files, less rotation
log_file_backup_count: 3            # Fewer backup files
json_logs: true                      # Structured logs for monitoring
show_log_icons: false                # No icons for production
performance_logging: false          # Disable for performance
```

### Monitoring and Alerting

```bash
# Monitor error rate
tail -f /var/log/linkwatcher/linkwatcher.log | jq 'select(.level == "ERROR")'

# Alert on critical errors
tail -f /var/log/linkwatcher/linkwatcher.log | jq 'select(.level == "CRITICAL")' | while read line; do
  echo "CRITICAL ERROR: $line" | mail -s "LinkWatcher Critical Error" admin@company.com
done
```

### Log Rotation with logrotate

```bash
# /etc/logrotate.d/linkwatcher
/var/log/linkwatcher/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 644 linkwatcher linkwatcher
    postrotate
        systemctl reload linkwatcher
    endscript
}
```

## 🔄 Migration from Print Statements

The new logging system provides backward-compatible functions for easy migration:

```python
# Old code
print(f"{Fore.GREEN}✓ File moved: {old_path} → {new_path}")

# New code (easy migration)
from linkwatcher.logging import log_info
log_info("File moved", old_path=old_path, new_path=new_path)

# New code (recommended)
from linkwatcher.logging import get_logger
logger = get_logger()
logger.file_moved(old_path, new_path, references_count=3)
```

## 🧪 Testing Logging

```python
import pytest
from unittest.mock import patch
from linkwatcher.logging import get_logger

def test_file_move_logging():
    logger = get_logger()

    with patch.object(logger.struct_logger, 'info') as mock_info:
        logger.file_moved("old.md", "new.md", 3)

        mock_info.assert_called_once_with(
            "file_moved",
            old_path="old.md",
            new_path="new.md",
            references_count=3,
            event_type="file_move"
        )
```

## 📚 Best Practices

1. **Use Structured Logging**: Include relevant context in log messages
2. **Set Appropriate Levels**: Use DEBUG for development, INFO for normal operation, WARNING/ERROR for issues
3. **Include Context**: Use the context system to add relevant information
4. **Performance Logging**: Use LogTimer for timing critical operations
5. **Log Rotation**: Configure appropriate log rotation for production
6. **Monitor Logs**: Set up monitoring and alerting for error conditions
7. **Test Logging**: Include logging verification in your tests

This enhanced logging system provides comprehensive observability for LinkWatcher operations while maintaining performance and usability.
