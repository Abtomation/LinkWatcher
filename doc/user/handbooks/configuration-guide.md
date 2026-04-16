---
id: PD-UGD-005
type: Product Documentation
category: User Guide
version: 1.0
created: 2026-04-16
updated: 2026-04-16
handbook_category: usage
handbook_name: Configuration Guide
---

# Configuration Guide

Complete guide to configuring LinkWatcher. Covers config files, CLI arguments, environment variables, environment presets, and the validation ignore system.

## Quick Start

LinkWatcher works out of the box with sensible defaults. To customize behavior, pick one of these methods:

```cmd
# Use a config file
python main.py --config my-config.yaml

# Override a single setting via CLI
python main.py --dry-run

# Override via environment variable
set LINKWATCHER_DRY_RUN_MODE=true
python main.py
```

## Configuration Precedence

When the same setting is specified in multiple places, the highest-priority source wins:

```
CLI arguments  >  Environment variables  >  Config file  >  Defaults
```

You can mix sources freely. For example, use a config file for base settings and an environment variable to override the log level in CI.

## Configuration File

LinkWatcher accepts YAML or JSON config files via `--config`:

```cmd
python main.py --config linkwatcher-config.yaml
```

### Full Reference

Below is a complete config file with all available settings and their defaults.

```yaml
# === File Monitoring ===
monitored_extensions:        # File types to watch for link references
  - ".md"
  - ".yaml"
  - ".yml"
  - ".json"
  - ".py"
  - ".dart"
  - ".txt"
  - ".ps1"
  - ".psm1"
  - ".bat"
  - ".toml"
  # Also available in defaults: .html, .htm, .css, .js, .ts, .jsx,
  # .tsx, .vue, .php, .xml, .csv, .png, .jpg, .jpeg, .gif, .svg,
  # .webp, .ico, .pdf, .mp4, .mp3, .wav

ignored_directories:         # Directories to skip entirely
  - ".git"
  - ".dart_tool"
  - "node_modules"
  - ".vscode"
  - "build"
  - "dist"
  - "__pycache__"
  - ".pytest_cache"
  - "coverage"
  - "docs/_build"
  - "target"
  - "bin"
  - "obj"
  - "tests"

# === Parser Toggles ===
enable_markdown_parser: true    # .md files
enable_yaml_parser: true        # .yaml, .yml files
enable_json_parser: true        # .json files
enable_dart_parser: true        # .dart files
enable_python_parser: true      # .py files
enable_powershell_parser: true  # .ps1, .psm1 files
enable_generic_parser: true     # All other monitored extensions

# === Update Behavior ===
create_backups: false        # Create .bak files before modifying a file
dry_run_mode: false          # Preview changes without modifying any files
atomic_updates: true         # Write to temp file, then replace (prevents corruption)

# === Performance ===
max_file_size_mb: 10         # Skip files larger than this (MB)
initial_scan_enabled: true   # Scan all files on startup to build link database
scan_progress_interval: 50   # Print progress every N files during initial scan

# === Logging ===
log_level: "INFO"            # DEBUG, INFO, WARNING, ERROR, CRITICAL
colored_output: true         # Colored console output with icons
show_statistics: true        # Print statistics on shutdown
log_file: null               # Log to file path (in addition to console)
log_file_max_size_mb: 10     # Max log file size before rotation
log_file_backup_count: 5     # Number of rotated log files to keep
json_logs: false             # Use JSON format for file logs
show_log_icons: true         # Show emoji icons in console output
performance_logging: false   # Log timing metrics for operations

# === Move Detection Timing ===
move_detect_delay: 10.0      # Seconds to wait for a matching CREATE after a DELETE
dir_move_max_timeout: 300.0  # Max seconds to wait for all files in a directory move
dir_move_settle_delay: 5.0   # Seconds after last file match before processing dir move

# === Validation Mode (--validate) ===
validation_extensions:       # File types to check for broken links
  - ".md"
  - ".yaml"
  - ".yml"
  - ".json"

validation_extra_ignored_dirs:  # Additional dirs to skip during validation
  - "LinkWatcher_run"
  - "old"
  - "archive"
  - "fixtures"
  - "e2e-acceptance-testing"
  - "config-examples"

validation_ignored_patterns:    # Suppress broken-link reports when target contains any of these
  - "path/to/"
  - "xxx"
  - "LinkWatcher/"

validation_ignore_file: ".linkwatcher-ignore"  # Path to per-file ignore rules

# === Python Import Resolution ===
python_source_root: ""       # Strip this prefix for import resolution (e.g., "src")
```

### Minimal Config File

You only need to include settings you want to change. Everything else uses defaults.

```yaml
# Just monitor specific extensions and enable dry-run
monitored_extensions:
  - ".md"
  - ".yaml"
  - ".py"

dry_run_mode: true
```

## CLI Arguments

| Option | Description | Equivalent Config Key |
|--------|-------------|----------------------|
| `--project-root DIR` | Project root directory (default: `.`) | — |
| `--config FILE` | Path to YAML or JSON config file | — |
| `--dry-run` | Preview mode, no file modifications | `dry_run_mode` |
| `--no-initial-scan` | Skip startup file scan | `initial_scan_enabled` |
| `--quiet` | Suppress non-error output | — |
| `--log-file FILE` | Log to file (in addition to console) | `log_file` |
| `--debug` | Set log level to DEBUG | `log_level` |
| `--validate` | Scan for broken links and exit | — |
| `--version` | Show version and exit | — |

## Environment Variables

Every config field can be set via environment variable using the pattern:

```
LINKWATCHER_{FIELD_NAME_UPPER}
```

### Type Conversion

| Field Type | Environment Variable Format | Example |
|-----------|---------------------------|---------|
| `bool` | `true`, `1`, `yes`, `on` (case-insensitive) | `LINKWATCHER_DRY_RUN_MODE=true` |
| `int` | Integer string | `LINKWATCHER_MAX_FILE_SIZE_MB=25` |
| `float` | Decimal string | `LINKWATCHER_MOVE_DETECT_DELAY=15.0` |
| `Set[str]` | Comma-separated values | `LINKWATCHER_MONITORED_EXTENSIONS=.md,.yaml,.py` |
| `str` | Plain string | `LINKWATCHER_LOG_LEVEL=DEBUG` |

### Common Environment Variables

```cmd
set LINKWATCHER_DRY_RUN_MODE=true
set LINKWATCHER_CREATE_BACKUPS=true
set LINKWATCHER_LOG_LEVEL=DEBUG
set LINKWATCHER_MONITORED_EXTENSIONS=.md,.yaml,.py,.json
set LINKWATCHER_IGNORED_DIRECTORIES=.git,node_modules,build
set LINKWATCHER_MAX_FILE_SIZE_MB=25
set LINKWATCHER_COLORED_OUTPUT=1
set LINKWATCHER_LOG_FILE=logs/linkwatcher.log
set LINKWATCHER_VALIDATION_IGNORED_PATTERNS=path/to/,xxx,placeholder
```

## Environment Presets

LinkWatcher includes three built-in presets optimized for common scenarios. Use the corresponding example config file or set values programmatically.

### Development (default-like)

Verbose logging, all parsers enabled, standard monitoring.

```yaml
log_level: "DEBUG"
show_statistics: true
create_backups: false
dry_run_mode: false
```

### Production

Minimal logging, optimized for performance, structured JSON logs for log aggregation.

```yaml
log_level: "WARNING"
show_statistics: false
colored_output: false
initial_scan_enabled: false
max_file_size_mb: 5
json_logs: true
show_log_icons: false
performance_logging: false
```

### Testing

Safe defaults for test environments: dry-run enabled, backups on, minimal file set.

```yaml
log_level: "DEBUG"
show_statistics: false
colored_output: false
create_backups: true
dry_run_mode: true
monitored_extensions:
  - ".md"
  - ".txt"
  - ".png"
  - ".svg"
```

Pre-built config files for these presets are available in the [`config-examples/`](/config-examples) directory.

## Validation Ignore System

When running `--validate`, you can suppress false-positive broken link reports using a `.linkwatcher-ignore` file.

### Format

```
# Comments start with #
source_glob -> target_substring
```

A broken link is suppressed only when **both** conditions match:
- The source file matches the glob pattern
- The link target contains the substring

### Example

```
# Template files use placeholder paths that don't exist
process-framework/templates/**/*.md -> related-design.md
process-framework/templates/**/*.md -> related-api.md

# Archive sections reference removed files intentionally
doc/archive/**/*.md -> old-docs/
```

### Configuration

The ignore file location defaults to `.linkwatcher-ignore` in the project root. Override it in your config:

```yaml
validation_ignore_file: "my-project/.linkwatcher-ignore"
```

You can also suppress patterns globally (without per-file matching) using `validation_ignored_patterns`:

```yaml
validation_ignored_patterns:
  - "path/to/"        # Skip all placeholder paths
  - "example.com"     # Skip example URLs
```

## Tips and Best Practices

- **Start with defaults** — LinkWatcher works out of the box for most projects. Only configure what you need to change.
- **Use config files for team settings** — Check your config file into version control so the team shares the same behavior.
- **Use environment variables for CI** — Override specific settings per-environment without modifying the config file.
- **Disable unused parsers** — If you don't use Dart, set `enable_dart_parser: false` to skip Dart-specific parsing.
- **Test with `--dry-run`** — Always preview changes before enabling live updates on a new project.
- **Keep `atomic_updates: true`** — This prevents file corruption if LinkWatcher is interrupted during an update.
- **Tune `move_detect_delay`** — If your editor or tool creates temporary files that trigger false moves, increase this value.

## Troubleshooting

### Config file not loading

**Problem:** Settings from your config file don't take effect.

**Solution:** Check the file path and format:
```cmd
# Verify the file exists and is valid YAML
python -c "import yaml; print(yaml.safe_load(open('my-config.yaml')))"

# Run with the config and check startup output
python main.py --config my-config.yaml
```

Unknown keys in the config file produce a warning in the log — check for typos.

### Environment variable ignored

**Problem:** An environment variable doesn't change behavior.

**Solution:** Verify the naming convention matches exactly: `LINKWATCHER_` prefix + field name in UPPER_CASE. For example, `dry_run_mode` becomes `LINKWATCHER_DRY_RUN_MODE`. Boolean values must be `true`, `1`, `yes`, or `on`.

### Move detection too slow or too fast

**Problem:** File moves aren't detected, or unrelated file operations are misidentified as moves.

**Solution:** Adjust the timing settings:
```yaml
move_detect_delay: 15.0       # Increase if moves are missed (default: 10s)
dir_move_settle_delay: 8.0    # Increase if directory moves are incomplete
```

### Too many files scanned

**Problem:** Initial scan is slow because irrelevant directories are being scanned.

**Solution:** Add directories to the ignore list:
```yaml
ignored_directories:
  - ".git"
  - "node_modules"
  - "your_large_directory"
```

## Related Documentation

- [Quick Reference](/doc/user/handbooks/quick-reference.md) — CLI options at a glance
- [Capabilities Reference](/doc/user/handbooks/linkwatcher-capabilities-reference.md) — What LinkWatcher detects and updates
- [Link Validation](/doc/user/handbooks/link-validation.md) — Detailed validation mode guide
- [File Type Quick Fix](/doc/user/handbooks/file-type-quick-fix.md) — Adding file type monitoring
- [Config Examples](/config-examples) — Pre-built YAML configuration files

---

*This handbook is part of the LinkWatcher Product Documentation.*
