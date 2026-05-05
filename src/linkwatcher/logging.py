"""
Enhanced logging system for LinkWatcher.

This module provides structured logging with multiple outputs, log levels,
and contextual information for better debugging and monitoring.

Two-module design
-----------------
The logging system is split across two modules:

- **logging.py** (this file): Core logging infrastructure — defines all
  classes, formatters, the global ``LinkWatcherLogger`` instance, and
  convenience functions.  This is the module that the rest of the codebase
  imports (``from .logging import get_logger, setup_logging``).

- **logging_config.py**: Runtime configuration management — loads config
  from YAML/JSON files, supports auto-reload on file change, and exposes
  ``LoggingConfigManager``.  It imports *from* this module and delegates
  all actual logging through the global logger created here.

Dual structlog + stdlib pipeline
--------------------------------
``LinkWatcherLogger.__init__`` wires two logging backends together:

1. **structlog** is configured as the *structured event API*.  All
   application log calls (``logger.info("file_moved", path=...)`` ) flow
   through structlog processors (timestamping, level filtering, rendering).

2. **stdlib logging** acts as the *transport layer*.  structlog is set up
   with ``LoggerFactory`` / ``BoundLogger`` from ``structlog.stdlib``, so
   processed events are handed to a stdlib ``logging.Logger`` which owns
   the actual handlers:

   - ``ColoredFormatter`` on a ``StreamHandler`` → coloured console output
   - ``JSONFormatter`` on a ``TimestampRotatingFileHandler`` → structured
     JSON file logs with timestamp-based rotation

Key classes
-----------
- ``LinkWatcherLogger`` — facade that owns both the stdlib logger and a
  structlog bound logger, plus a ``PerformanceLogger`` for timing.
- ``ColoredFormatter`` / ``JSONFormatter`` — stdlib formatters for console
  and file output respectively.
- ``TimestampRotatingFileHandler`` — ``RotatingFileHandler`` subclass that
  names rotated files with timestamps instead of numeric suffixes.
- ``PerformanceLogger`` — thread-safe operation timer with metric logging.
- ``LogTimer`` — context manager for timing code blocks.
- ``LogContext`` — thread-local key-value context injected into log records.

AI Context
----------
- **Entry point**: ``get_logger()`` returns the global
  ``LinkWatcherLogger`` singleton; ``setup_logging()`` initializes it.
  All other modules import only these two plus ``LogTimer`` and
  ``with_context``.
- **Delegation**: logging.py owns infrastructure; logging_config.py
  owns runtime config.  The config module imports *from* this module,
  never the reverse.
- **Common tasks**:
  - Changing log format: modify ``ColoredFormatter.format()`` (console)
    or ``JSONFormatter.format()`` (file).
  - Adding a log output: add a new stdlib handler in
    ``LinkWatcherLogger.__init__`` alongside the existing stream and
    file handlers.
  - Debugging log filtering: check ``structlog.stdlib.filter_by_level``
    and the structlog processor chain configured in
    ``LinkWatcherLogger.__init__``.
  - Module-level helpers: ``get_logger()``, ``setup_logging()``,
    ``reset_logger()``, ``with_context()``, ``LogTimer``.
"""

import glob
import json
import logging
import logging.handlers
import os
import sys
import threading
import time
from datetime import datetime
from enum import Enum
from functools import wraps
from pathlib import Path
from typing import Any, Dict, Optional, Union

import structlog
from colorama import Fore, Style, init

# Lazy colorama initialization — deferred from module level to first
# ColoredFormatter use to avoid wrapping sys.stdout/sys.stderr at import time
# (interferes with test harnesses and non-terminal environments).
_colorama_initialized = False


def _ensure_colorama():
    """Initialize colorama on first use, not at import time."""
    global _colorama_initialized
    if not _colorama_initialized:
        init(autoreset=True)
        _colorama_initialized = True


# Fallback logger for rotation errors — writes to stderr independently of
# the file handler being rotated, avoiding circular-logging issues.
_fallback_logger = logging.getLogger("linkwatcher._fallback")
_fallback_logger.propagate = False
if not _fallback_logger.handlers:
    _fallback_handler = logging.StreamHandler(sys.stderr)
    _fallback_handler.setFormatter(logging.Formatter("%(asctime)s [%(levelname)s] %(message)s"))
    _fallback_logger.addHandler(_fallback_handler)
    _fallback_logger.setLevel(logging.WARNING)


class TimestampRotatingFileHandler(logging.handlers.RotatingFileHandler):
    """RotatingFileHandler that uses timestamps in rotated filenames.

    Instead of LinkWatcherLog.txt.1, produces LinkWatcherLog_20260316-091500.txt
    """

    def doRollover(self):
        if self.stream:
            self.stream.close()
            self.stream = None

        # Generate timestamp-based backup name
        timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
        base, ext = os.path.splitext(self.baseFilename)
        backup_name = f"{base}_{timestamp}{ext}"

        # Rename current log to timestamped backup
        if os.path.exists(self.baseFilename):
            try:
                os.rename(self.baseFilename, backup_name)
                logging.getLogger(__name__).info(
                    "Log rotated: %s -> %s", self.baseFilename, backup_name
                )
            except OSError as e:
                _fallback_logger.warning(
                    "Log rotation failed to rename %s -> %s: %s",
                    self.baseFilename,
                    backup_name,
                    e,
                )

        # Clean up old backups (keep only backupCount most recent)
        if self.backupCount > 0:
            pattern = f"{base}_*{ext}"
            backups = sorted(glob.glob(pattern), reverse=True)
            for old_backup in backups[self.backupCount :]:
                try:
                    os.remove(old_backup)
                except OSError as e:
                    _fallback_logger.warning(
                        "Log rotation failed to remove old backup %s: %s",
                        old_backup,
                        e,
                    )

        if not self.delay:
            self.stream = self._open()


class LogLevel(Enum):
    """Log levels for LinkWatcher."""

    DEBUG = "DEBUG"
    INFO = "INFO"
    WARNING = "WARNING"
    ERROR = "ERROR"
    CRITICAL = "CRITICAL"


class LogContext:
    """Thread-local context for logging."""

    def __init__(self):
        self._local = threading.local()

    def set_context(self, **kwargs):
        """Set context variables for current thread."""
        if not hasattr(self._local, "context"):
            self._local.context = {}
        self._local.context.update(kwargs)

    def get_context(self) -> Dict[str, Any]:
        """Get context variables for current thread."""
        if not hasattr(self._local, "context"):
            self._local.context = {}
        return self._local.context.copy()

    def clear_context(self):
        """Clear context for current thread."""
        if hasattr(self._local, "context"):
            self._local.context.clear()


# Global context instance
log_context = LogContext()


class ColoredFormatter(logging.Formatter):
    """Custom formatter with colors for console output."""

    COLORS = {
        "DEBUG": Fore.CYAN,
        "INFO": Fore.GREEN,
        "WARNING": Fore.YELLOW,
        "ERROR": Fore.RED,
        "CRITICAL": Fore.MAGENTA + Style.BRIGHT,
    }

    ICONS = {
        "DEBUG": "🔍",
        "INFO": "ℹ️",
        "WARNING": "⚠️",
        "ERROR": "❌",
        "CRITICAL": "🚨",
    }

    def __init__(self, colored: bool = True, show_icons: bool = True):
        if colored:
            _ensure_colorama()
        self.colored = colored
        self.show_icons = show_icons
        super().__init__()

    def format(self, record):
        # Add context to record
        context = log_context.get_context()
        for key, value in context.items():
            setattr(record, key, value)

        # Format timestamp
        timestamp = datetime.fromtimestamp(record.created).strftime("%H:%M:%S.%f")[:-3]

        # Get color and icon
        level_name = record.levelname
        color = self.COLORS.get(level_name, "") if self.colored else ""
        icon = self.ICONS.get(level_name, "") if self.show_icons else ""
        reset = Style.RESET_ALL if self.colored else ""

        # Format message
        message = record.getMessage()

        # Add context information if available
        context_str = ""
        if context:
            context_parts = []
            for key, value in context.items():
                if key not in [
                    "name",
                    "msg",
                    "args",
                    "levelname",
                    "levelno",
                    "pathname",
                    "filename",
                    "module",
                    "lineno",
                    "funcName",
                    "created",
                    "msecs",
                    "relativeCreated",
                    "thread",
                    "threadName",
                    "processName",
                    "process",
                    "getMessage",
                    "exc_info",
                    "exc_text",
                    "stack_info",
                ]:
                    context_parts.append(f"{key}={value}")
            if context_parts:
                context_str = f" [{', '.join(context_parts)}]"

        # Build final message
        if self.colored:
            formatted = (
                f"{color}{icon} {timestamp} {level_name:8} "
                f"{record.name:20} {message}{context_str}{reset}"
            )
        else:
            formatted = f"{timestamp} {level_name:8} {record.name:20} {message}{context_str}"

        return formatted


class JSONFormatter(logging.Formatter):
    """JSON formatter for structured logging."""

    def format(self, record):
        # Create log entry
        log_entry = {
            "timestamp": datetime.fromtimestamp(record.created).isoformat(),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "module": record.module,
            "function": record.funcName,
            "line": record.lineno,
            "thread": record.thread,
            "thread_name": record.threadName,
        }

        # Add context
        context = log_context.get_context()
        if context:
            log_entry["context"] = context

        # Add exception info if present
        if record.exc_info:
            log_entry["exception"] = self.formatException(record.exc_info)

        return json.dumps(log_entry, default=str)


class PerformanceLogger:
    """Logger for performance metrics and timing."""

    def __init__(self, logger_name: str = "linkwatcher.performance"):
        self.logger = structlog.get_logger(logger_name)
        self._timers = {}
        self._timers_lock = threading.Lock()  # PD-BUG-027: thread-safe timer access

    def start_timer(self, operation: str) -> str:
        """Start timing an operation."""
        timer_id = f"{operation}_{int(time.time() * 1000000)}"
        with self._timers_lock:
            self._timers[timer_id] = time.perf_counter()
        return timer_id

    def end_timer(self, timer_id: str, operation: str, **kwargs):
        """End timing and log the result."""
        with self._timers_lock:
            start_time = self._timers.pop(timer_id, None)
        if start_time is not None:
            duration = time.perf_counter() - start_time

            self.logger.info(
                "operation_completed",
                operation=operation,
                duration_ms=round(duration * 1000, 2),
                **kwargs,
            )
        else:
            self.logger.warning("timer_not_found", timer_id=timer_id, operation=operation)

    def log_metric(self, metric_name: str, value: Union[int, float], unit: str = "", **kwargs):
        """Log a performance metric."""
        self.logger.info("metric", metric_name=metric_name, value=value, unit=unit, **kwargs)


class LinkWatcherLogger:
    """Main logger class for LinkWatcher."""

    def __init__(
        self,
        name: str = "linkwatcher",
        level: LogLevel = LogLevel.INFO,
        log_file: Optional[str] = None,
        colored_output: bool = True,
        show_icons: bool = True,
        json_logs: bool = False,
        max_file_size: int = 10 * 1024 * 1024,  # 10MB
        backup_count: int = 5,
    ):
        self.name = name
        self.level = level
        self.colored_output = colored_output
        self.show_icons = show_icons
        self.json_logs = json_logs

        # Reset structlog to clear cached loggers from prior configurations
        # (PD-BUG-015: without this, cached BoundLogger instances retain old processor chains)
        structlog.reset_defaults()

        # Configure structlog
        structlog.configure(
            processors=[
                structlog.stdlib.filter_by_level,
                structlog.stdlib.add_logger_name,
                structlog.stdlib.add_log_level,
                structlog.stdlib.PositionalArgumentsFormatter(),
                structlog.processors.TimeStamper(fmt="iso"),
                structlog.processors.StackInfoRenderer(),
                structlog.processors.format_exc_info,
                structlog.processors.UnicodeDecoder(),
                structlog.processors.JSONRenderer()
                if json_logs
                else structlog.dev.ConsoleRenderer(),
            ],
            context_class=dict,
            logger_factory=structlog.stdlib.LoggerFactory(),
            wrapper_class=structlog.stdlib.BoundLogger,
            cache_logger_on_first_use=True,
        )

        # Create main logger
        self.logger = logging.getLogger(name)
        self.logger.setLevel(getattr(logging, level.value))

        # Clear existing handlers
        self.logger.handlers.clear()

        # Console handler
        console_handler = logging.StreamHandler(sys.stdout)
        console_formatter = ColoredFormatter(colored=colored_output, show_icons=show_icons)
        console_handler.setFormatter(console_formatter)
        console_handler.setLevel(getattr(logging, level.value))
        self.logger.addHandler(console_handler)

        # File handler (if specified)
        if log_file:
            self._setup_file_logging(log_file, max_file_size, backup_count)

        # Performance logger
        self.performance = PerformanceLogger()

        # Structured logger
        self.struct_logger = structlog.get_logger(name)

    def _setup_file_logging(self, log_file: str, max_file_size: int, backup_count: int):
        """Setup file logging with rotation."""
        log_path = Path(log_file)
        log_path.parent.mkdir(parents=True, exist_ok=True)

        # Rotating file handler with timestamp-based filenames
        file_handler = TimestampRotatingFileHandler(
            log_file, maxBytes=max_file_size, backupCount=backup_count, encoding="utf-8"
        )

        # Use JSON formatter for file logs
        file_formatter = JSONFormatter()
        file_handler.setFormatter(file_formatter)
        file_handler.setLevel(logging.DEBUG)  # Log everything to file

        self.logger.addHandler(file_handler)

    def set_level(self, level: LogLevel):
        """Change the logging level."""
        self.level = level
        self.logger.setLevel(getattr(logging, level.value))

        # Update console handler level
        for handler in self.logger.handlers:
            if isinstance(handler, logging.StreamHandler) and handler.stream == sys.stdout:
                handler.setLevel(getattr(logging, level.value))

    def set_context(self, **kwargs):
        """Set logging context for current thread."""
        log_context.set_context(**kwargs)

    def clear_context(self):
        """Clear logging context for current thread."""
        log_context.clear_context()

    def debug(self, message: str, **kwargs):
        """Log debug message."""
        self.struct_logger.debug(message, **kwargs)

    def info(self, message: str, **kwargs):
        """Log info message."""
        self.struct_logger.info(message, **kwargs)

    def warning(self, message: str, **kwargs):
        """Log warning message."""
        self.struct_logger.warning(message, **kwargs)

    def error(self, message: str, **kwargs):
        """Log error message."""
        self.struct_logger.error(message, **kwargs)

    def critical(self, message: str, **kwargs):
        """Log critical message."""
        self.struct_logger.critical(message, **kwargs)

    def exception(self, message: str, **kwargs):
        """Log exception with traceback."""
        self.struct_logger.exception(message, **kwargs)

    # Convenience methods for common LinkWatcher events
    def file_moved(self, old_path: str, new_path: str, references_count: int = 0):
        """Log file move event."""
        self.info(
            "file_moved",
            old_path=old_path,
            new_path=new_path,
            references_count=references_count,
            event_type="file_move",
        )

    def file_deleted(self, file_path: str, references_count: int = 0):
        """Log file deletion event."""
        self.warning(
            "file_deleted",
            file_path=file_path,
            references_count=references_count,
            event_type="file_delete",
        )

    def file_created(self, file_path: str):
        """Log file creation event."""
        self.info("file_created", file_path=file_path, event_type="file_create")

    def links_updated(self, file_path: str, references_updated: int):
        """Log link update event."""
        self.info(
            "links_updated",
            file_path=file_path,
            references_updated=references_updated,
            event_type="link_update",
        )

    def scan_progress(
        self, files_scanned: int, total_files: Optional[int] = None, info_level: bool = False
    ):
        """Log scan progress.

        Args:
            files_scanned: Number of files scanned so far.
            total_files: Total number of files to scan (if known).
            info_level: If True, log at INFO level for milestone progress.
        """
        log_fn = self.info if info_level else self.debug
        log_fn(
            "scan_progress",
            files_scanned=files_scanned,
            total_files=total_files,
            event_type="scan_progress",
        )

    def operation_stats(self, **stats):
        """Log operation statistics."""
        self.info("operation_stats", event_type="statistics", **stats)


# Global logger instance
_logger: Optional[LinkWatcherLogger] = None


def get_logger() -> LinkWatcherLogger:
    """Get the global LinkWatcher logger instance."""
    global _logger
    if _logger is None:
        _logger = LinkWatcherLogger()
    return _logger


def reset_logger():
    """Reset the global logger instance, closing any open handlers.

    Intended for test isolation — avoids tests reaching into private
    module state (``_logger = None``).
    """
    global _logger
    if _logger is not None:
        _logger.debug("logger_reset", event_type="logging_lifecycle")
        for handler in _logger.logger.handlers[:]:
            handler.close()
            _logger.logger.removeHandler(handler)
    _logger = None


def setup_logging(
    level: LogLevel = LogLevel.INFO,
    log_file: Optional[str] = None,
    colored_output: bool = True,
    show_icons: bool = True,
    json_logs: bool = False,
    max_file_size: int = 10 * 1024 * 1024,
    backup_count: int = 5,
) -> LinkWatcherLogger:
    """Setup and configure the global logger."""
    global _logger
    # Close old logger's handlers to release file locks
    # (PD-BUG-015: prevents PermissionError on Windows when log files are replaced)
    if _logger is not None:
        for handler in _logger.logger.handlers[:]:
            handler.close()
    _logger = LinkWatcherLogger(
        level=level,
        log_file=log_file,
        colored_output=colored_output,
        show_icons=show_icons,
        json_logs=json_logs,
        max_file_size=max_file_size,
        backup_count=backup_count,
    )
    _logger.info(
        "logging_configured",
        event_type="logging_lifecycle",
        level=level.value,
        log_file=log_file,
        json_logs=json_logs,
    )
    return _logger


def with_context(**kwargs):
    """Decorator to add context to all log messages in a function."""

    def decorator(func):
        @wraps(func)
        def wrapper(*args, **func_kwargs):
            logger = get_logger()
            previous = log_context.get_context()
            logger.set_context(**kwargs)
            try:
                return func(*args, **func_kwargs)
            finally:
                logger.clear_context()
                if previous:
                    log_context.set_context(**previous)

        return wrapper

    return decorator


class LogTimer:
    """Context manager for timing operations."""

    def __init__(
        self,
        operation: str,
        logger: Optional[LinkWatcherLogger] = None,
        *,
        enabled: bool = True,
        **kwargs,
    ):
        self.operation = operation
        self.logger = logger or get_logger()
        self.kwargs = kwargs
        self.enabled = enabled
        self.start_time = None
        self.timer_id = None

    def __enter__(self):
        if not self.enabled:
            return self
        self.timer_id = self.logger.performance.start_timer(self.operation)
        self.start_time = time.perf_counter()
        self.logger.debug(f"started_{self.operation}", **self.kwargs)
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        if not self.enabled:
            return
        if self.timer_id:
            self.logger.performance.end_timer(self.timer_id, self.operation, **self.kwargs)

        if exc_type is not None:
            self.logger.error(
                f"failed_{self.operation}",
                error_type=exc_type.__name__,
                error_message=str(exc_val),
                **self.kwargs,
            )
        else:
            self.logger.debug(f"completed_{self.operation}", **self.kwargs)
