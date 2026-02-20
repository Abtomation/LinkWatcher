---
id: PD-FDD-025
type: Product Documentation
category: Functional Design Document
version: 1.0
created: 2026-02-19
updated: 2026-02-19
feature_id: 3.1.1
feature_name: Logging Framework
retrospective: true
---

# Logging Framework - Functional Design Document

> **Retrospective Document**: This FDD describes the existing implemented functionality of the LinkWatcher Logging Framework, documented after implementation during framework onboarding (PF-TSK-066). Content is descriptive ("what is") rather than prescriptive ("what should be").
>
> **Source**: Derived from [3.1.1 Implementation State](../../../process-framework/state-tracking/features/3.1.1-logging-framework-implementation-state.md), [docs/LOGGING.md](../../../../docs/LOGGING.md) (primary existing documentation), and source code analysis of `linkwatcher/logging.py` and `linkwatcher/logging_config.py`.

## Feature Overview

- **Feature ID**: 3.1.1
- **Feature Name**: Logging Framework
- **Business Value**: Provides full operational visibility into LinkWatcher's file-watching activity. Users can see every file move, link update, scan, and error in real time — either in a colored console or a structured JSON log file — enabling effective debugging and confidence that the tool is working correctly.
- **User Story**: As a developer running LinkWatcher, I want structured, readable log output for every file operation so that I can verify links are being maintained correctly and diagnose issues when they arise.

## Related Documentation

### Architecture Overview Reference

> **📋 Primary Documentation**: [docs/LOGGING.md](../../../../docs/LOGGING.md)
> **👤 Source**: Pre-framework project documentation (Confirmed in PF-TSK-065 analysis)
>
> **Purpose**: Complete logging system documentation — log levels, configuration options, API usage, performance monitoring, and advanced features.

**Functional Architecture Summary** (derived from docs/LOGGING.md):

- The logging system provides two parallel output streams: a human-readable colored console and an optional JSON file with rotation
- Every LinkWatcher component uses a shared `get_logger()` singleton that is configured once at startup
- Domain-specific convenience methods (`file_moved`, `links_updated`, `scan_progress`, etc.) provide pre-structured log entries with relevant context fields automatically attached

### Technical Design Reference

> **📋 Primary Documentation**: TDD (to be created as part of PF-TSK-066)
>
> **Purpose**: Detailed technical implementation of `LinkWatcherLogger`, `LogContext`, `PerformanceLogger`, `LoggingConfigManager`, design patterns, and component interactions.

**Functional Technical Requirements**:

- Logging must be thread-safe — concurrent file-watching events from multiple threads must produce correct, non-interleaved log output
- Log file rotation must be automatic and non-blocking — users should never need to manually manage log files
- Config changes must take effect within 1 second without service restart

## Functional Requirements

### Core Functionality

- **3.1.1-FR-1**: The system SHALL provide structured log messages at five severity levels: DEBUG, INFO, WARNING, ERROR, and CRITICAL
- **3.1.1-FR-2**: The system SHALL output human-readable, color-coded log messages to the console with emoji-based level indicators (e.g., ✅ INFO, ⚠️ WARNING, ❌ ERROR)
- **3.1.1-FR-3**: The system SHALL optionally write JSON-formatted log messages to a rotating log file configurable via startup arguments or config file
- **3.1.1-FR-4**: The system SHALL provide domain-specific log methods for LinkWatcher operations: `file_moved`, `file_deleted`, `links_updated`, `scan_progress`, and `operation_stats`
- **3.1.1-FR-5**: The system SHALL maintain isolated per-thread logging context so that concurrent operations do not mix their contextual information
- **3.1.1-FR-6**: The system SHALL measure and report operation timing via `PerformanceLogger` and `LogTimer` context manager
- **3.1.1-FR-7**: The system SHALL support runtime log level and filter configuration via a YAML or JSON config file
- **3.1.1-FR-8**: The system SHALL hot-reload the config file and apply changes while the service is running, without restart

### User Interactions

- **3.1.1-UI-1**: Users configure initial log level via CLI arguments: `--debug` (DEBUG level), `--quiet` (ERROR level only), or the default INFO level
- **3.1.1-UI-2**: Users optionally direct log output to a file via `--log-file <path>` CLI argument
- **3.1.1-UI-3**: Users see colored, emoji-labeled console log entries in real time for every file move, link update, scan, and error
- **3.1.1-UI-4**: Users can edit the logging config file while LinkWatcher is running to change log level or filters; changes take effect within 1 second
- **3.1.1-UI-5**: Users see a session summary (`operation_stats`) on shutdown, including counts of files moved, links updated, and errors encountered

### Business Rules

- **3.1.1-BR-1**: Console output uses ANSI color coding by level: DEBUG=cyan, INFO=green, WARNING=yellow, ERROR=red, CRITICAL=bright red
- **3.1.1-BR-2**: File output uses JSON format with automatic rotation at 10 MB, retaining 5 backup files; users never need to manually rotate logs
- **3.1.1-BR-3**: Log context is per-thread via `threading.local()` — each worker thread maintains its own independent context (current operation, current file path)
- **3.1.1-BR-4**: All components share a single configured logger instance via `get_logger()`; only `setup_logging()` at startup configures the instance
- **3.1.1-BR-5**: Config hot-reload polls the config file's `mtime` every 1 second via a daemon thread — changes are picked up within 1 second and the daemon thread terminates automatically when the service stops

## User Experience Flow

1. **Entry Point**: User starts LinkWatcher via CLI (`python main.py [project-path] [options]`)

2. **Startup Configuration**:
   - CLI args (`--debug`, `--quiet`, `--log-file`) configure the logging system at startup
   - If a logging config file is specified or discovered, `LoggingConfigManager` loads it
   - Both the console handler (colored) and optional file handler (JSON) are initialized

3. **Real-Time Operation Logging**:
   - As LinkWatcher monitors the project, every significant event produces a structured log entry
   - File moves appear as: `INFO ✅ File moved: old/path.md → new/path.md`
   - Link updates appear as: `INFO ✅ Updated 3 links in docs/guide.md`
   - Errors appear in red: `ERROR ❌ Failed to update docs/locked.md: PermissionError`

4. **Performance Timing**:
   - Operations wrapped in `LogTimer` automatically emit a timing log on completion
   - Example: `DEBUG ⏱ Initial scan completed in 0.42s (47 files, 312 links)`

5. **Runtime Config Change** (optional):
   - User edits the logging config YAML to change log_level from INFO to DEBUG
   - Within 1 second, the hot-reload thread detects the change and applies it
   - Subsequent log entries now include DEBUG-level messages — no restart needed

6. **Shutdown Summary**:
   - On shutdown, `operation_stats` is logged with the complete session summary
   - Example: `INFO 📊 Session: 8 files moved, 24 links updated, 0 errors, 1 warning`

7. **Exit Point**: Service terminates; log file (if configured) is flushed and closed; daemon thread exits automatically

## Acceptance Criteria

- [x] **3.1.1-AC-1**: Starting with `--debug` makes DEBUG-level messages appear in console output
- [x] **3.1.1-AC-2**: Starting with `--quiet` suppresses INFO and WARNING messages; only ERROR and CRITICAL are shown
- [x] **3.1.1-AC-3**: Console messages are ANSI color-coded by level with emoji indicators in each line
- [x] **3.1.1-AC-4**: When `--log-file` is specified, valid JSON log entries are written to the specified file
- [x] **3.1.1-AC-5**: The log file automatically rotates when it reaches 10 MB, creating up to 5 backup files
- [x] **3.1.1-AC-6**: `file_moved`, `file_deleted`, `links_updated`, `scan_progress`, and `operation_stats` produce structured log entries with the correct context fields (source_path, dest_path, count, etc.)
- [x] **3.1.1-AC-7**: Editing the logging config file while the service runs applies changes to log output within 1 second
- [x] **3.1.1-AC-8**: Log entries from concurrent threads do not contain each other's context data

> **Note**: All acceptance criteria are checked as this is a retrospective document — the feature is fully implemented and operational.

## Edge Cases & Error Handling

- **3.1.1-EC-1**: If the directory for the specified log file does not exist, the system falls back to console-only logging and emits a WARNING about the missing directory
- **3.1.1-EC-2**: If the log file cannot be written (permissions error, disk full), the system logs the error to console and continues with console-only output
- **3.1.1-EC-3**: If the logging config file contains invalid YAML or JSON, the system logs a WARNING and continues with the last valid configuration (or defaults if never successfully loaded)
- **3.1.1-EC-4**: If `setup_logging()` is called after log messages have already been emitted, the `cache_logger_on_first_use=True` structlog setting may cause some reconfiguration to not apply — the logger is effectively immutable after first use
- **3.1.1-EC-5**: Log context set manually via `set_context()` without using the `with_context()` decorator must be explicitly cleared via `clear_context()` to avoid context leaking to subsequent operations on the same thread

## Dependencies

### Functional Dependencies

- **0.1.4 Configuration System**: Provides `log_level` and `log_file` settings that `LoggingConfigManager` reads when loading a project config file; without it, logger uses hardcoded defaults

### Technical Dependencies

- **structlog** (≥21.0): Structured key-value logging output and processor pipeline
- **colorama** (≥0.4): Cross-platform ANSI color support for Windows console output
- **PyYAML** (≥5.0): YAML config file parsing in `LoggingConfigManager` (optional — only needed for YAML config files)
- **logging + logging.handlers** (stdlib): Handler infrastructure, `RotatingFileHandler`, `StreamHandler`
- **threading** (stdlib): `threading.local()` for per-thread context; `threading.Lock` for metrics; `threading.Thread` for config hot-reload daemon

## Success Metrics

- Every file move, link update, scan, and error produces a structured log entry with relevant context
- Console output is immediately readable to developers without any tooling — level, operation type, and paths are visible at a glance
- JSON log files are directly parsable by log aggregation tools (jq, Splunk, ELK, etc.)
- Users can understand exactly what LinkWatcher did in a session by reading the shutdown summary
- No log file management burden on users — rotation is fully automatic

## Validation Checklist

- [x] All functional requirements clearly defined with Feature ID prefixes (3.1.1-FR-1 through 3.1.1-FR-8)
- [x] User interactions documented (CLI args → startup config → real-time log output → runtime changes → shutdown summary)
- [x] Business rules specified (color coding, JSON rotation, thread isolation, singleton, hot-reload timing)
- [x] Acceptance criteria are testable and measurable (3.1.1-AC-1 through 3.1.1-AC-8)
- [x] Edge cases identified with expected behaviors (3.1.1-EC-1 through 3.1.1-EC-5)
- [x] Dependencies mapped (functional: Configuration System; technical: structlog, colorama, PyYAML, stdlib)
- [x] Success metrics defined
- [x] User experience flow covers all major paths (startup, real-time ops, runtime config, shutdown)

---

_Retrospective Functional Design Document — documents existing implementation as of 2026-02-19._
