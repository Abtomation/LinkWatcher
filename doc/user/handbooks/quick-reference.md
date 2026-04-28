---
id: PD-UGD-007
type: Product Documentation
category: User Guide
version: 1.0
created: 2025-12-01
updated: 2026-04-16
---

# LinkWatcher 2.0 - Quick Reference Guide

## Quick Start

```cmd
# Basic usage - monitor current directory
python main.py

# Monitor specific directory
python main.py --project-root c:\path\to\project

# Preview mode (no file changes)
python main.py --dry-run
```

## Command Line Options

| Option | Description | Example |
|--------|-------------|---------|
| `--project-root DIR` | Set project directory | `--project-root c:\my\project` |
| `--config FILE` | Use config file | `--config settings.yaml` |
| `--dry-run` | Preview mode only | `--dry-run` |
| `--no-initial-scan` | Skip startup scan | `--no-initial-scan` |
| `--quiet` | Minimal output | `--quiet` |
| `--log-file FILE` | Log to file (in addition to console) | `--log-file logs\linkwatcher.log` |
| `--validate` | Scan for broken links and exit | `--validate` |
| `--debug` | Enable debug logging | `--debug` |
| `--version` | Show version | `--version` |

## Configuration File Example

```yaml
# linkwatcher-config.yaml
monitored_extensions:
  - ".md"
  - ".yaml"
  - ".py"
  - ".dart"
  - ".json"

ignored_directories:
  - ".git"
  - "node_modules"
  - "__pycache__"
  - ".dart_tool"

create_backups: false
dry_run_mode: false
initial_scan_enabled: true
max_file_size_mb: 10
log_level: "INFO"
colored_output: true
show_statistics: true
```

## Environment Variables

```cmd
REM Configuration via environment
set LINKWATCHER_DRY_RUN=true
set LINKWATCHER_CREATE_BACKUPS=true
set LINKWATCHER_LOG_LEVEL=DEBUG
set LINKWATCHER_MONITORED_EXTENSIONS=.md,.yaml,.py
set LINKWATCHER_IGNORED_DIRECTORIES=.git,node_modules
set LINKWATCHER_MAX_FILE_SIZE_MB=25
set LINKWATCHER_COLORED_OUTPUT=1
```

## Supported File Types

| Extension | Parser | What It Finds |
|-----------|--------|---------------|
| `.md` | Markdown | `[text](link)`, quoted paths, standalone files |
| `.yaml`, `.yml` | YAML | String values with file paths |
| `.py` | Python | Import statements, file path strings |
| `.dart` | Dart | Import/part statements |
| `.json` | JSON | String values with file paths |
| Others | Generic | Quoted file paths in any text file |

## What Happens When You Move a File

```
1. File moved: src/utils.py -> src/helpers/utils.py
2. LinkWatcher detects the move event
3. Searches database for all references to src/utils.py
4. Updates each file containing references:
   - Python imports: from src.utils -> from src.helpers.utils
   - Markdown links: `[Utils](src/utils.py)` -> `[Utils](src/helpers/utils.py)`
   - YAML configs: file: src/utils.py -> file: src/helpers/utils.py
5. Updates internal database
6. Shows confirmation: "Updated 3 references in 2 files"
```

## Output Examples

### Startup
```
LinkWatcher v2.0 - Real-time Link Maintenance System
============================================================
Project root: C:\Users\user\MyProject
Configuration:
   Monitored extensions: .dart, .json, .md, .py, .yaml
   Ignored directories: .dart_tool, .git, .vscode, build, node_modules
   Initial scan: enabled
   Dry run mode: disabled
   Backup creation: disabled
============================================================

Git repository detected
Performing initial scan...
   Scanned 50 files...
   Scanned 100 files...
Initial scan complete:
   45 files with links
   127 total references
   89 unique targets
LinkWatcher is now monitoring file changes...
Press Ctrl+C to stop
```

### File Move Event
```
File moved: docs/api.md -> docs/reference/api.md
Updating 3 unique references...
Updated 2 reference(s) in README.md
Updated 1 reference(s) in docs/index.md
```

### Final Statistics
```
Final Statistics:
   Files moved: 5
   Files deleted: 1
   Files created: 2
   Links updated: 12
   Errors: 0
   Database: 156 references to 89 targets
```

## Troubleshooting

### Common Issues

**Links not updating?**
```cmd
REM Check if file extension is monitored
python main.py --config debug.yaml

REM debug.yaml:
REM monitored_extensions: [".md", ".txt", ".your_extension"]
```

**Too many files being scanned?**
```yaml
# Add directories to ignore list
ignored_directories: [".git", "node_modules", "your_large_dir"]
```

**Want to see what would change?**
```cmd
python main.py --dry-run
```

**Need more details?**
```cmd
python main.py --debug
```

## Example Link Formats Detected

### Markdown Files
```text
`[API Guide](docs/api.md)`           <- Standard markdown link
`[Config](config/settings.yaml)`     <- Cross-format reference
"src/utils.py"                     <- Quoted file path
docs/examples/basic.md             <- Standalone file reference
```

### YAML Files
```yaml
include: "config/database.yaml"    # Include statement
template: templates/base.html      # Template reference
script: scripts/deploy.py          # Script reference
```

### Python Files
```python
from utils.helpers import func     # Import statement
config_file = "config/app.yaml"    # File path string
with open("data/input.json") as f: # File operation
```

### Dart Files
```dart
import 'package:myapp/utils.dart'; // Package import
part 'models.dart';                // Part statement
```

## Best Practices

1. **Start with dry-run**: Always test with `--dry-run` first
2. **Use configuration files**: Keep settings in version control
3. **Monitor selectively**: Only include necessary file extensions
4. **Ignore build directories**: Add build/dist folders to ignored_directories
5. **Regular backups**: Enable backups for critical projects
6. **Check git status**: Review changes before committing

## Related

- [README](../../../README.md) - Project overview and installation
- [Multi-Project Setup](multi-project-setup.md) - Using across multiple projects
- [Link Validation](link-validation.md) - Scan workspace for broken file references
- [File Type Quick Fix](file-type-quick-fix.md) - Quick fix for file types not being monitored
- [Troubleshooting File Types](troubleshooting-file-types.md) - Detailed file type monitoring guide
