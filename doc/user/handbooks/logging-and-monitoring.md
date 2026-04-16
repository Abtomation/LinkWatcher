---
id: PD-UGD-006
type: Product Documentation
category: User Guide
version: 1.0
created: 2026-04-16
updated: 2026-04-16
handbook_category: usage
handbook_name: Logging and Monitoring
---

# Logging and Monitoring

LinkWatcher provides structured logging with colored console output, JSON file logging, automatic log rotation, and a real-time monitoring dashboard. This handbook covers how to configure and use all logging features.

## Quick Start

```cmd
# Run with debug logging (see all internal operations)
python main.py --debug

# Log to a file (JSON format, in addition to console)
python main.py --log-file logs/linkwatcher.log

# Suppress all non-error output
python main.py --quiet

# Combine: debug logging to file, normal console
python main.py --log-file logs/linkwatcher.log
```

## CLI Options

| Flag | Description |
|------|-------------|
| `--debug` | Set log level to DEBUG (default: INFO) |
| `--log-file <path>` | Write JSON-formatted logs to a file, in addition to console output |
| `--quiet` | Suppress all non-error console output (sets level to ERROR, disables colors and icons) |
| `--config <path>` | Load settings from a YAML or JSON config file (includes logging options) |

Flags can be combined. `--debug` and `--quiet` are mutually exclusive in practice — `--quiet` wins because it sets the level to ERROR.

## Configuration

All logging options can be set in a YAML or JSON config file passed via `--config`. CLI flags override config file values.

### Logging Settings

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `log_level` | string | `"INFO"` | Log level: `DEBUG`, `INFO`, `WARNING`, `ERROR`, `CRITICAL` |
| `colored_output` | bool | `true` | Enable colored console output with severity-based coloring |
| `show_log_icons` | bool | `true` | Show emoji icons next to log messages in console |
| `log_file` | string | *(none)* | Path to log file; enables file logging when set |
| `log_file_max_size_mb` | int | `10` | Maximum log file size in MB before rotation triggers |
| `log_file_backup_count` | int | `5` | Number of rotated backup files to keep |
| `json_logs` | bool | `false` | Use JSON format for structured console output (file output is always JSON) |
| `performance_logging` | bool | `true` | Enable performance timing metrics in log output |
| `show_statistics` | bool | `true` | Show operation statistics on shutdown |

### Example Config File

```yaml
# logging settings in your config file
log_level: "DEBUG"
colored_output: true
show_log_icons: true
log_file: "logs/linkwatcher.log"
log_file_max_size_mb: 10
log_file_backup_count: 5
json_logs: false
performance_logging: true
show_statistics: true
```

Use it with:

```cmd
python main.py --config my-config.yaml
```

See [config-examples/logging-config.yaml](/config-examples/logging-config.yaml) for a complete example with all settings.

## Console Output

By default, LinkWatcher displays colored console output with emoji icons indicating severity:

| Level | Color | Icon | When Used |
|-------|-------|------|-----------|
| DEBUG | Cyan | 🔍 | Internal operations, scan progress, timing details |
| INFO | Green | ℹ️ | File moves detected, links updated, configuration loaded |
| WARNING | Yellow | ⚠️ | File deletions, invalid configurations, missing files |
| ERROR | Red | ❌ | Failed operations, file access errors |
| CRITICAL | Magenta (bright) | 🚨 | Fatal errors preventing operation |

Each log line shows: `icon timestamp level logger message [context]`

Example output:

```
ℹ️ 09:15:23.456 INFO     linkwatcher          logging_configured level=INFO
ℹ️ 09:15:24.012 INFO     linkwatcher          file_moved old_path=doc/old.md new_path=doc/new.md references_count=3
⚠️ 09:15:25.789 WARNING  linkwatcher          file_deleted file_path=doc/removed.md
```

To disable colors (e.g., for piping to a file): set `colored_output: false` in config.
To disable icons: set `show_log_icons: false` in config.

## File Logging

When `--log-file` is specified (or `log_file` is set in config), LinkWatcher writes **JSON-formatted** log entries to the file. Each line is a standalone JSON object:

```json
{
  "timestamp": "2026-04-16T09:15:24.012345",
  "level": "INFO",
  "logger": "linkwatcher",
  "message": "file_moved",
  "module": "handler",
  "function": "on_moved",
  "line": 42,
  "thread": 12345,
  "thread_name": "FileEventThread",
  "context": {"old_path": "doc/old.md", "new_path": "doc/new.md"}
}
```

File logging always captures **all levels** (DEBUG and above), regardless of the console log level. This means you can run with default INFO console output while still capturing full debug detail in the log file.

## Log Rotation

Log files are automatically rotated when they exceed the configured maximum size (`log_file_max_size_mb`, default 10 MB).

**How it works:**

1. When the active log file exceeds the size limit, it is renamed with a timestamp suffix
2. A new empty log file is created
3. Old backups beyond `log_file_backup_count` (default: 5) are deleted

**Rotated file naming:**

```
linkwatcher.log                         ← active log
linkwatcher_20260416-091500.log         ← rotated backup (timestamp of rotation)
linkwatcher_20260415-180000.log         ← older backup
```

This timestamp-based naming (instead of numeric suffixes like `.1`, `.2`) makes it easy to identify when each log was created.

## Logging Dashboard

LinkWatcher includes a real-time terminal dashboard for monitoring log output. It reads from a JSON log file and displays statistics, recent entries, and performance metrics.

### Usage

```cmd
# Monitor a log file in real-time (curses UI)
python tools/logging_dashboard.py --log-file logs/linkwatcher.log

# Text mode (no curses — works in any terminal)
python tools/logging_dashboard.py --log-file logs/linkwatcher.log --text-mode

# Custom refresh rate (seconds)
python tools/logging_dashboard.py --log-file logs/linkwatcher.log --refresh-rate 0.5
```

### Dashboard Features

- **Log counts by level** — totals for DEBUG, INFO, WARNING, ERROR
- **Logs by component** — which modules are most active
- **Performance data** — operation timing metrics
- **Recent log entries** — scrollable list of latest events
- **Errors/warnings per minute** — trend tracking

The dashboard requires a running LinkWatcher instance writing to a log file. Start LinkWatcher with `--log-file` first, then point the dashboard at the same file.

## Runtime Configuration Reload

LinkWatcher supports automatic config file reloading. When enabled, the logging configuration is re-read when the config file changes on disk — no restart required.

This is configured programmatically through the `LoggingConfigManager`. When using a config file via `--config`, changes to `log_level` in the config file are picked up automatically if auto-reload is enabled.

## Tips and Best Practices

- **Development**: Use `--debug` to see all internal operations (file scanning, link detection, event handling)
- **Production**: Use a config file with `log_level: "WARNING"` and `log_file` set for quiet operation with full file logging
- **Debugging issues**: Combine `--debug --log-file debug.log` — console shows everything live, the log file preserves it for later analysis
- **Disk space**: The default rotation settings (10 MB × 5 backups = 50 MB max) are suitable for most projects. For very active projects, increase `log_file_backup_count`
- **Machine parsing**: Log files are JSON — one object per line. Use `jq` or any JSON parser to filter and analyze

## Troubleshooting

### No file output

**Problem:** `--log-file` is set but no log file appears.

**Solution:** Check that the parent directory exists. LinkWatcher creates the file and parent directories automatically, but filesystem permissions may prevent this. Verify with:

```cmd
python main.py --log-file logs/linkwatcher.log --debug
```

Look for error messages about file creation in the console output.

### Colors not showing

**Problem:** Console output appears without colors or with escape codes visible.

**Solution:**
- On Windows, LinkWatcher uses `colorama` for color support. Ensure `colorama` is installed: `pip install colorama`
- If piping output to a file or another program, colors are automatically disabled. Set `colored_output: false` in config to suppress escape codes explicitly
- Some terminals don't support ANSI colors — use `--quiet` or set `colored_output: false`

### Log file growing too large

**Problem:** Log file exceeds expected size.

**Solution:** Verify rotation settings in your config:

```yaml
log_file_max_size_mb: 10       # rotate at 10 MB
log_file_backup_count: 5       # keep 5 backups (50 MB total max)
```

If the file grows beyond `log_file_max_size_mb`, rotation should trigger automatically. If rotation fails (e.g., file locked by another process), a warning is logged to stderr.

### Dashboard shows no data

**Problem:** The logging dashboard starts but shows empty panels.

**Solution:**
- Ensure LinkWatcher is running with `--log-file` pointing to the same file the dashboard reads
- The log file must contain JSON entries (the default file format). If you see plain text in the file, verify `json_logs` is not interfering with file formatting (file output is always JSON regardless of this setting)
- Check the file path matches exactly between LinkWatcher and the dashboard

## Related Documentation

- [Quick Reference](/doc/user/handbooks/quick-reference.md) — CLI options, config basics, environment variables
- [Configuration Guide](/doc/user/handbooks/configuration-guide.md) — Complete configuration reference
- [Capabilities Reference](/doc/user/handbooks/linkwatcher-capabilities-reference.md) — What LinkWatcher detects and updates
- [config-examples/logging-config.yaml](/config-examples/logging-config.yaml) — Example logging configuration

---

*This handbook is part of the LinkWatcher Product Documentation.*
