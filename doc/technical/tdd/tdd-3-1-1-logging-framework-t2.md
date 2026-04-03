---
id: PD-TDD-024
type: Technical Design Document
category: TDD Tier 2
version: 1.0
created: 2026-02-19
updated: 2026-02-20
feature_id: 3.1.1
feature_name: Logging System
consolidates: [3.1.1-3.1.5]
tier: 2
retrospective: true
---

# Lightweight Technical Design Document: Logging Framework

> **Retrospective Document**: This TDD describes the existing technical design of the LinkWatcher Logging Framework, documented after implementation during framework onboarding (PF-TSK-066). Content is reverse-engineered from source code analysis.
>
> **Source**: Derived from source code analysis of `linkwatcher/logging.py` and `linkwatcher/logging_config.py`.
>
> **Scope Note**: This feature consolidates old 3.1.1 (Logging Framework) with all sub-features: 3.1.2 (Colored Console Output), 3.1.3 (Statistics Tracking), 3.1.4 (Progress Reporting), and 3.1.5 (Error Reporting).

## 1. Overview

### 1.1 Purpose

The Logging Framework provides structured, contextual, and performance-aware logging for the entire LinkWatcher application. It is implemented across two modules: `linkwatcher/logging.py` (primary interface — `LinkWatcherLogger`, `LogContext`, `PerformanceLogger`) and `linkwatcher/logging_config.py` (runtime configuration — `LoggingConfigManager`).

The framework delivers dual-mode output (colored console + JSON file), per-thread context isolation, performance timing, domain-specific convenience methods (`file_moved`, `file_deleted`, `file_created`, `links_updated`, `scan_progress`, `operation_stats`), and runtime config hot-reload — all behind a simple `get_logger()` singleton interface. Test isolation is supported via `reset_logger()` and `reset_config_manager()`.

### 1.2 Related Features

| Feature | Relationship | Description |
|---------|-------------|-------------|
| 0.1.3 Configuration System | Consumer | Reads `log_level`, `log_file` settings from `LinkWatcherConfig` |
| 0.1.1 Core Architecture | Consumer | `service.py` uses `get_logger()`, `LogTimer`, `@with_context` |
| 0.1.2 In-Memory Database | Consumer | `database.py` uses `get_logger()` for operation logging |
| 1.1.1 Event Handler | Consumer | `handler.py` uses `get_logger()`, `@with_context`, `LogTimer` |
| 2.1.1 Parser Framework | Consumer | `parser.py` uses `get_logger()`, `LogTimer` |
| 2.2.1 Link Updater | Consumer | `updater.py` uses `get_logger()`, `LogTimer`, `@with_context` |
| _(3.1.2–3.1.5 Log sub-features)_ | _(consolidated into 3.1.1)_ | Colored output, statistics, progress, error reporting all part of this feature |

## 2. Key Requirements

**Key technical requirements this design satisfies:**

1. **Thread-safe contextual logging**: Per-thread log context using `threading.local()` — concurrent watchdog events from multiple threads must produce correct, non-interleaved log output
2. **Dual-mode output**: Simultaneous colored console output (human-readable) and optional JSON file output (machine-parsable) from a single log call
3. **Global singleton with one-time configuration**: All modules share one configured logger instance accessible via `get_logger()`; `setup_logging()` is the single configuration entry point
4. **Performance timing without boilerplate**: `LogTimer` context manager wraps any operation and emits a timing log entry on completion with zero caller code overhead
5. **Config hot-reload**: `LoggingConfigManager` watches a config file and applies changes to log level and filters within 1 second, without service restart

## 3. Quality Attribute Requirements

### 3.1 Performance Requirements

- **Response Time**: Log calls must be non-blocking for the caller — no synchronous I/O on the calling thread (file writes are buffered by the `RotatingFileHandler`)
- **Throughput**: Handles the rate of LinkWatcher file operations (human-speed events) without measurable overhead; structlog's processor chain adds negligible latency
- **Resource Usage**: Log file bounded at 10 MB per file × 6 files (1 active + 5 backups) = 60 MB max disk usage

### 3.2 Security Requirements

- **Data Protection**: Log messages include file paths from the monitored project — no credentials, tokens, or secrets are ever logged by LinkWatcher itself
- **Input Validation**: Log context values are developer-controlled — no user-supplied external input reaches the logging layer directly

### 3.3 Reliability Requirements

- **Error Handling**: If file logging fails (disk full, permission denied), the system falls back to console-only output and logs the failure; console logging is not affected by file handler failures
- **Thread Safety**: `threading.local()` provides automatic per-thread context isolation
- **Config Integrity**: If hot-reload encounters an invalid config file, the last valid configuration is retained — the logger never enters an unconfigured state

### 3.4 Usability Requirements

- **Transparency**: Every significant LinkWatcher operation produces a log entry — users can always understand what the tool is doing
- **Error Messages**: Errors include structured context (file path, operation, error message) via the `exception()` method and `@with_context` decorator
- **Loading States**: Initial scan progress is reported via `scan_progress()` with file counts at DEBUG level (every `scan_progress_interval` files) and INFO level at milestone intervals (every 4x the interval); `LogTimer` reports completion timing

## 4. Technical Design

### 4.1 Core Components

**`LinkWatcherLogger`** (`linkwatcher/logging.py`) — Primary interface:

```python
class LinkWatcherLogger:
    def __init__(self, name: str = "linkwatcher", level=LogLevel.INFO,
                 log_file=None, colored_output=True, show_icons=True,
                 json_logs=False, max_file_size=10*1024*1024, backup_count=5):
        # stdlib logging: StreamHandler (console) + RotatingFileHandler (file)
        self.logger = logging.getLogger(name)
        # structlog: reset_defaults() then configure() with cache_logger_on_first_use=True
        self.struct_logger = structlog.get_logger(name)
        # Performance logger instance
        self.performance = PerformanceLogger()

    # Standard level methods (delegate to self.struct_logger)
    def debug(self, message: str, **kwargs): ...
    def info(self, message: str, **kwargs): ...
    def warning(self, message: str, **kwargs): ...
    def error(self, message: str, **kwargs): ...
    def critical(self, message: str, **kwargs): ...
    def exception(self, message: str, **kwargs): ...

    # Context delegation to global log_context instance
    def set_context(self, **kwargs): ...
    def clear_context(self): ...

    # Domain-specific convenience methods
    def file_moved(self, old_path: str, new_path: str, references_count: int = 0): ...
    def file_deleted(self, file_path: str, references_count: int = 0): ...
    def file_created(self, file_path: str): ...
    def links_updated(self, file_path: str, references_updated: int): ...
    def scan_progress(self, files_scanned: int, total_files: Optional[int] = None, info_level: bool = False): ...
    def operation_stats(self, **stats): ...
```

**Module-level singleton** (`linkwatcher/logging.py`):

```python
_logger: Optional[LinkWatcherLogger] = None

def get_logger() -> LinkWatcherLogger:
    global _logger
    if _logger is None:
        _logger = LinkWatcherLogger()  # lazy init with defaults
    return _logger

def setup_logging(level=LogLevel.INFO, log_file=None, colored_output=True,
                  show_icons=True, json_logs=False, max_file_size=10*1024*1024,
                  backup_count=5) -> LinkWatcherLogger:
    global _logger
    # Close old logger's handlers to release file locks (PD-BUG-015)
    if _logger is not None:
        for handler in _logger.logger.handlers[:]:
            handler.close()
    _logger = LinkWatcherLogger(level=level, log_file=log_file, ...)
    return _logger

def reset_logger():
    """Reset the global logger instance, closing handlers. For test isolation."""
    global _logger
    if _logger is not None:
        for handler in _logger.logger.handlers[:]:
            handler.close()
            _logger.logger.removeHandler(handler)
    _logger = None
```

**`LogContext`** (`linkwatcher/logging.py`) — Thread-local context:

```python
class LogContext:
    """Thread-local context for logging."""
    def __init__(self):
        self._local = threading.local()

    def set_context(self, **kwargs):
        """Merge kwargs into current thread's context (update, not replace)."""
        if not hasattr(self._local, 'context'):
            self._local.context = {}
        self._local.context.update(kwargs)

    def get_context(self) -> dict:
        if not hasattr(self._local, 'context'):
            self._local.context = {}
        return self._local.context.copy()

    def clear_context(self):
        if hasattr(self._local, 'context'):
            self._local.context.clear()

# Global context instance — shared by all modules via get_logger().set_context()
log_context = LogContext()

def with_context(**kwargs):
    """Decorator: sets context before call, clears on exit via try/finally."""
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **func_kwargs):
            logger = get_logger()
            logger.set_context(**kwargs)
            try:
                return func(*args, **func_kwargs)
            finally:
                logger.clear_context()
        return wrapper
    return decorator
```

**`PerformanceLogger` + `LogTimer`** (`linkwatcher/logging.py`):

```python
class LogTimer:
    """Context manager: records start time, delegates timing to PerformanceLogger on __exit__."""
    def __init__(self, operation: str, logger: Optional[LinkWatcherLogger] = None, **kwargs):
        self.operation = operation
        self.logger = logger or get_logger()
        self.kwargs = kwargs
        self.start_time = None
        self.timer_id = None

    def __enter__(self):
        self.timer_id = self.logger.performance.start_timer(self.operation)
        self.start_time = time.perf_counter()
        self.logger.debug(f"started_{self.operation}", **self.kwargs)
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        if self.timer_id:
            self.logger.performance.end_timer(self.timer_id, self.operation, **self.kwargs)
        if exc_type is not None:
            self.logger.error(f"failed_{self.operation}", error_type=exc_type.__name__,
                              error_message=str(exc_val), **self.kwargs)
        else:
            self.logger.debug(f"completed_{self.operation}", **self.kwargs)
```

**`LoggingConfigManager`** (`linkwatcher/logging_config.py`) — Advanced config:

```python
class LoggingConfigManager:
    def __init__(self):
        self.logger = get_logger()
        self.config_file: Optional[Path] = None
        self.auto_reload = False
        self._config_watch_thread: Optional[threading.Thread] = None
        self._stop_watching = threading.Event()

    def load_config_file(self, config_file, auto_reload=False):
        """Load YAML/JSON config, optionally start watching for changes."""
        ...

    def _start_config_watching(self):
        """Start daemon thread polling config file mtime every 1 second."""
        self._config_watch_thread = threading.Thread(
            target=self._watch_config_file)
        self._config_watch_thread.daemon = True
        self._config_watch_thread.start()

    def _watch_config_file(self):
        last_modified = self.config_file.stat().st_mtime
        while not self._stop_watching.wait(1.0):
            current_modified = self.config_file.stat().st_mtime
            if current_modified > last_modified:
                self.load_config_file(self.config_file, auto_reload=False)
                last_modified = current_modified

    def stop_config_watching(self): ...
    def create_debug_snapshot(self) -> dict: ...

# Module-level singleton with reset for test isolation
_config_manager: Optional[LoggingConfigManager] = None

def get_config_manager() -> LoggingConfigManager: ...
def reset_config_manager():
    """Reset global config manager. For test isolation."""
    global _config_manager
    _config_manager = None
```

### 4.2 Output Pipeline Architecture

```
Caller: logger.info("File moved", src=..., dest=...)
           │
           ▼
    structlog processor chain:
      - Add timestamps
      - Add thread context from LogContext.get_context()
      - Format key-value pairs
           │
    ┌──────┴──────────────────────┐
    ▼                              ▼
ColoredFormatter                JSONFormatter
(console StreamHandler)         (file RotatingFileHandler, optional)
    │                              │
    ▼                              ▼
Terminal (ANSI colors)          .log file (10MB rotation, 5 backups)
```

### 4.3 Design Patterns Used

**Singleton Pattern**:
- `_logger` module-level variable with lazy `get_logger()` accessor
- `setup_logging()` for explicit one-time configuration at startup
- All modules call `get_logger()` — they never instantiate `LinkWatcherLogger` directly

**Context Manager Pattern**:
- `LogTimer` implements `__enter__`/`__exit__` for automatic timing with guaranteed completion log
- Usage: `with LogTimer("initial_scan", logger): ...`

**Decorator Pattern**:
- `@with_context(operation="file_move", src_path=src)` injects context before method execution and guarantees cleanup via `try/finally`
- Consumers use it on event handler methods to add per-call structured context without boilerplate

**Observer Pattern (config hot-reload)**:
- `LoggingConfigManager` daemon thread polls config file `mtime` and notifies `LinkWatcherLogger` of changes
- Polling chosen over inotify/watchdog to avoid circular dependency with the file watching subsystem

### 4.4 Quality Attribute Implementation

#### Performance Implementation

- structlog's `cache_logger_on_first_use=True` binds the processor chain at first log call — subsequent calls have minimal overhead
- `RotatingFileHandler` buffers writes — file I/O does not block the calling thread's log call
- `LogContext` uses `threading.local()` — no locking required for context reads/writes

#### Reliability Implementation

- Console and file handlers are independent — file handler failure does not affect console output
- `LoggingConfigManager` catches all exceptions during config reload; invalid configs are logged as ERROR and the previous config is retained
#### Security Implementation

- No external input reaches the logging system — all log messages are generated internally by LinkWatcher components
- File paths logged are OS-provided, not user-supplied — no injection risk

## 5. Cross-References

### 5.1 Functional Requirements Reference

> **📋 Primary Documentation**: FDD PD-FDD-025
> **🔗 Link**: [FDD PD-FDD-025](../../functional-design/fdds/fdd-3-1-1-logging-framework.md) — Logging Framework Functional Design Document

**Brief Summary**: This TDD implements all 8 functional requirements from FDD PD-FDD-025: 5-level logging (FR-1), colored console output (FR-2), JSON file logging with rotation (FR-3), domain-specific methods (FR-4), thread-isolated context (FR-5), performance timing (FR-6), YAML/JSON config (FR-7), and config hot-reload (FR-8).

### 5.2 Testing Reference

> **📋 Primary Documentation**: Existing test suite
> **🔗 Link**: [test/automated/unit/test_logging.py](../../../test/automated/unit/test_logging.py), [test/automated/unit/test_advanced_logging.py](../../../test/automated/unit/test_advanced_logging.py)

**Brief Summary**: The logging framework is covered by two unit test files. `test_logging.py` covers `LinkWatcherLogger`, `LogContext`, `PerformanceLogger`, and the singleton API. `test_advanced_logging.py` covers `LoggingConfigManager` including config loading, debug snapshots, and hot-reload behavior.

## 6. Implementation Plan

### 6.1 Dependencies

All dependencies are fully implemented (retrospective document):

- `linkwatcher/config/settings.py` (0.1.3) — `LinkWatcherConfig` for optional config integration
- `structlog` — structured logging processor chain
- `colorama` — ANSI color output on Windows
- `PyYAML` — YAML config file parsing (optional, `LoggingConfigManager` only)

### 6.2 Implementation Notes (Retrospective)

The logging framework is split across two modules reflecting two development phases:

1. `linkwatcher/logging.py` — core logging API (singleton, levels, context, timing)
2. `linkwatcher/logging_config.py` — runtime configuration layer added later (log level management, config hot-reload)

Key design decisions that shaped the implementation:

1. **Dual backend**: stdlib `logging` for handler infrastructure (rotation, multiple outputs) + structlog for structured key-value output — combining the mature handler ecosystem with structlog's structured output
2. **`cache_logger_on_first_use=True`**: Makes structlog effectively immutable after first log call — `setup_logging()` must be called before any component calls `get_logger()` to avoid partial reconfiguration
3. **Domain-specific methods**: `file_moved()`, `links_updated()`, etc. enforce consistent log structure for key operations — all consumers get the same field names automatically

## 7. Quality Measurement

### 7.1 Performance Monitoring

- `LogTimer` provides per-operation timing; used to track initial scan time, link update time, and parse time
- `operation_stats()` provides session-level throughput metrics on shutdown

## 8. Open Questions

None — this is a retrospective document for a fully implemented, stable feature.

**Known Technical Debt**:
- `cache_logger_on_first_use=True` means structlog configuration is immutable after first log call — if `setup_logging()` is not called early enough in startup, the logger runs with defaults and reconfiguration has no effect. **Mitigated (PD-BUG-015)**: `LinkWatcherLogger.__init__()` now calls `structlog.reset_defaults()` before `structlog.configure()`, and `setup_logging()` closes old handlers before replacing the global logger instance
- `LoggingConfigManager` hot-reload applies only to log level — it does not support dynamically switching between console-only and file+console output modes

## 9. AI Agent Session Handoff Notes

### Current Status

**Retrospective TDD** — Feature 3.1.1 Logging Framework is fully implemented and stable. This document was created during onboarding (PF-TSK-066) to formally document the design.

### Next Steps

No implementation work needed. Next documentation step: FDD and TDD creation continues for remaining Tier 2 features (2.1.1, 2.2.1, 4.1.1, 4.1.3, 4.1.4, 4.1.6, 5.1.1, 5.1.2).

### Key Decisions

- **Dual backend (stdlib + structlog)**: Gets handler ecosystem from stdlib, structured output from structlog — avoids reimplementing either
- **Singleton pattern**: Ensures all modules share one configured logger — no per-module logger creation needed
- **Daemon thread for hot-reload**: Polling over inotify/watchdog avoids circular dependency with the file watching subsystem; daemon thread terminates automatically on process exit

### Known Issues

None for this feature.
