"""
Enhanced logging system for LinkWatcher.

This module provides structured logging with multiple outputs, log levels,
and contextual information for better debugging and monitoring.
"""

import json
import logging
import logging.handlers
import os
import sys
import threading
import time
from datetime import datetime
from enum import Enum
from pathlib import Path
from typing import Any, Dict, Optional, Union

import structlog
from colorama import Fore, Style, init

# Initialize colorama for cross-platform colored output
init(autoreset=True)


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
            formatted = f"{color}{icon} {timestamp} {level_name:8} {record.name:20} {message}{context_str}{reset}"
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

    def start_timer(self, operation: str) -> str:
        """Start timing an operation."""
        timer_id = f"{operation}_{int(time.time() * 1000000)}"
        self._timers[timer_id] = time.perf_counter()
        return timer_id

    def end_timer(self, timer_id: str, operation: str, **kwargs):
        """End timing and log the result."""
        if timer_id in self._timers:
            duration = time.perf_counter() - self._timers[timer_id]
            del self._timers[timer_id]

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

        # Rotating file handler
        file_handler = logging.handlers.RotatingFileHandler(
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

    def scan_progress(self, files_scanned: int, total_files: Optional[int] = None):
        """Log scan progress."""
        self.debug(
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
    _logger = LinkWatcherLogger(
        level=level,
        log_file=log_file,
        colored_output=colored_output,
        show_icons=show_icons,
        json_logs=json_logs,
        max_file_size=max_file_size,
        backup_count=backup_count,
    )
    return _logger


def with_context(**kwargs):
    """Decorator to add context to all log messages in a function."""

    def decorator(func):
        def wrapper(*args, **func_kwargs):
            logger = get_logger()
            logger.set_context(**kwargs)
            try:
                return func(*args, **func_kwargs)
            finally:
                logger.clear_context()

        return wrapper

    return decorator


class LogTimer:
    """Context manager for timing operations."""

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
            self.logger.error(
                f"failed_{self.operation}",
                error_type=exc_type.__name__,
                error_message=str(exc_val),
                **self.kwargs,
            )
        else:
            self.logger.debug(f"completed_{self.operation}", **self.kwargs)


# Backward compatibility functions for easy migration
def log_file_moved(old_path: str, new_path: str, references_count: int = 0):
    """Log file move event (backward compatibility)."""
    get_logger().file_moved(old_path, new_path, references_count)


def log_file_deleted(file_path: str, references_count: int = 0):
    """Log file deletion event (backward compatibility)."""
    get_logger().file_deleted(file_path, references_count)


def log_links_updated(file_path: str, references_updated: int):
    """Log link update event (backward compatibility)."""
    get_logger().links_updated(file_path, references_updated)


def log_error(message: str, **kwargs):
    """Log error message (backward compatibility)."""
    get_logger().error(message, **kwargs)


def log_warning(message: str, **kwargs):
    """Log warning message (backward compatibility)."""
    get_logger().warning(message, **kwargs)


def log_info(message: str, **kwargs):
    """Log info message (backward compatibility)."""
    get_logger().info(message, **kwargs)


def log_debug(message: str, **kwargs):
    """Log debug message (backward compatibility)."""
    get_logger().debug(message, **kwargs)
