# LinkWatcher 2.0 - How It Works

## 🎯 Overview

LinkWatcher is a real-time link maintenance system that automatically updates file references when files are moved, renamed, or deleted. It monitors your project directory and ensures that all links remain valid as your project structure evolves.

## 🏗️ Architecture

LinkWatcher uses a modular architecture with the following core components:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   File System   │    │   Link Parser   │    │  Link Database  │
│   Monitoring    │───▶│   (Multi-type)  │───▶│  (In-memory)    │
│   (Watchdog)    │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                                              │
         ▼                                              ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Event Handler  │───▶│  Link Updater   │───▶│  File Updates   │
│  (Move/Delete)  │    │  (Safe writes)  │    │  (Atomic ops)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🔄 How It Works

### 1. **Initial Scan Phase**

When LinkWatcher starts, it performs an initial scan:

1. **File Discovery**: Walks through the project directory recursively
2. **File Filtering**: Only processes files with monitored extensions (`.md`, `.yaml`, `.py`, etc.)
3. **Link Extraction**: Uses specialized parsers to find all file references
4. **Database Population**: Stores all found links in an in-memory database

```python
# Example: What gets stored for a markdown link
LinkReference(
    file_path="docs/README.md",
    line_number=15,
    column_start=25,
    column_end=45,
    link_text="API Guide",
    link_target="api/guide.md",
    link_type="markdown"
)
```

### 2. **Real-time Monitoring Phase**

After the initial scan, LinkWatcher continuously monitors for file system changes:

#### **File Move Detection**
```
File moved: src/utils.py → src/helpers/utils.py

1. Event Handler receives move event
2. Database lookup finds all references to "src/utils.py"
3. Link Updater modifies each referencing file
4. Database updates target paths
5. Success confirmation displayed
```

#### **File Deletion Detection**
```
File deleted: docs/old-guide.md

1. Event Handler receives delete event
2. Database lookup finds all references to "docs/old-guide.md"
3. Warning displayed about broken links
4. Database removes references to deleted file
```

### 3. **Link Update Process**

When a file is moved, LinkWatcher follows this process:

1. **Reference Discovery**: Find all files that link to the moved file
2. **Path Resolution**: Calculate the new relative paths
3. **File Modification**: Update each referencing file atomically
4. **Database Update**: Update the in-memory database
5. **Verification**: Confirm all updates were successful

## 🔍 Parser System

LinkWatcher uses specialized parsers for different file types:

### **Markdown Parser** (`.md`)
- Standard markdown links: `[text](link)`
- Quoted file references: `"path/to/file.md"`
- Standalone file paths

### **YAML Parser** (`.yaml`, `.yml`)
- String values containing file paths
- Configuration file references
- Include/import statements

### **Python Parser** (`.py`)
- Import statements: `from module import something`
- File path strings in code
- Configuration references

### **JSON Parser** (`.json`)
- String values containing file paths
- Configuration references

### **Dart Parser** (`.dart`)
- Import statements: `import 'package:name/file.dart'`
- Part statements: `part 'file.dart'`

### **Generic Parser**
- Fallback for any text file
- Looks for quoted file paths
- Basic pattern matching

## 💾 Database System

LinkWatcher maintains an in-memory database for fast lookups:

```python
# Database structure
{
    "target_file_path": [
        LinkReference(...),
        LinkReference(...),
    ],
    "another_file.md": [
        LinkReference(...),
    ]
}
```

### **Key Features**:
- **Thread-safe**: Uses locks for concurrent access
- **Fast lookups**: O(1) access to references by target file
- **Path normalization**: Handles different path formats consistently
- **Anchor support**: Handles links with anchors (`file.md#section`)

## 🛡️ Safety Features

### **Atomic Updates**
- Creates temporary files during updates
- Only replaces original on success
- Prevents data loss on failures

### **Backup Creation** (Optional)
- Creates `.bak` files before modifications
- Configurable backup behavior
- Easy rollback capability

### **Dry Run Mode**
- Preview changes without modifying files
- Test configuration and behavior
- Safe experimentation

### **Error Handling**
- Graceful degradation on parser errors
- Detailed error reporting
- Continues operation despite individual failures

## ⚙️ Configuration System

LinkWatcher supports multiple configuration sources:

### **Priority Order** (highest to lowest):
1. Command line arguments
2. Environment variables
3. Configuration file (YAML/JSON)
4. Default values

### **Key Settings**:
```yaml
# File monitoring
monitored_extensions: [".md", ".yaml", ".py", ".dart", ".json"]
ignored_directories: [".git", "node_modules", "__pycache__"]

# Behavior
create_backups: false
dry_run_mode: false
initial_scan_enabled: true

# Performance
max_file_size_mb: 10
scan_progress_interval: 50

# Output
colored_output: true
show_statistics: true
log_level: "INFO"
```

## 🚀 Usage Examples

### **Basic Usage**
```bash
# Start monitoring current directory
python main.py

# Monitor specific directory
python main.py --project-root /path/to/project

# Dry run mode (preview only)
python main.py --dry-run
```

### **With Configuration**
```bash
# Use custom config file
python main.py --config my-config.yaml

# Skip initial scan for faster startup
python main.py --no-initial-scan

# Quiet mode
python main.py --quiet
```

### **Environment Variables**
```bash
# Set via environment
export LINKWATCHER_DRY_RUN=true
export LINKWATCHER_CREATE_BACKUPS=true
export LINKWATCHER_LOG_LEVEL=DEBUG

python main.py
```

## 📊 Statistics and Monitoring

LinkWatcher provides detailed statistics:

### **During Operation**
- Files scanned during initial scan
- Real-time event notifications
- Update confirmations
- Error reports

### **Final Statistics**
```
📊 Final Statistics:
   Files moved: 5
   Files deleted: 2
   Files created: 3
   Links updated: 12
   Errors: 0
   Database: 156 references to 89 targets
```

## 🔧 Advanced Features

### **Custom Parsers**
Add support for new file types by implementing the `BaseParser` interface:

```python
class CustomParser(BaseParser):
    def parse_file(self, file_path: str) -> List[LinkReference]:
        # Your parsing logic here
        pass
```

### **Link Validation**
Check for broken links across your project:

```python
service = LinkWatcherService(".")
broken_links = service.check_links()
```

### **Force Rescan**
Rebuild the database from scratch:

```python
service.force_rescan()
```

## 🎯 Benefits

1. **Automatic Maintenance**: No manual link updates needed
2. **Real-time Updates**: Changes happen immediately
3. **Multi-format Support**: Works with various file types
4. **Safe Operations**: Atomic updates with error handling
5. **High Performance**: Efficient in-memory database
6. **Configurable**: Adapt to your project's needs
7. **Windows Optimized**: Full Windows path support

## 🔍 Troubleshooting

### **Common Issues**

1. **Links not updating**: Check if file extension is in `monitored_extensions`
   - See [File Type Quick Fix Guide](docs/FILE_TYPE_QUICK_FIX.md) for immediate solutions
   - See [Troubleshooting File Types](docs/TROUBLESHOOTING_FILE_TYPES.md) for detailed diagnosis
2. **Performance issues**: Adjust `max_file_size_mb` or add directories to `ignored_directories`
3. **Path issues**: Ensure consistent path separators in your project
4. **Permission errors**: Run with appropriate file system permissions

### **Debug Mode**
```bash
# Enable detailed logging
python main.py --config debug-config.yaml

# Where debug-config.yaml contains:
# log_level: "DEBUG"
# show_statistics: true
```

This documentation provides a comprehensive understanding of how LinkWatcher works, from its architecture to practical usage examples.
