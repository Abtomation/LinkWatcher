"""
Advanced logging configuration and management for LinkWatcher.

This module provides runtime configuration management, log filtering,
and advanced logging features.
"""

import json
import logging
import os
import threading
import time
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any, Dict, List, Optional, Set, Union

from .logging import LogLevel, get_logger


class LogFilter:
    """Advanced log filtering based on various criteria."""

    def __init__(self):
        self.component_filters: Set[str] = set()
        self.operation_filters: Set[str] = set()
        self.min_level: Optional[LogLevel] = None
        self.max_level: Optional[LogLevel] = None
        self.file_path_patterns: List[str] = []
        self.exclude_patterns: List[str] = []
        self.time_window: Optional[timedelta] = None
        self.start_time: Optional[datetime] = None

    def add_component_filter(self, component: str):
        """Only log messages from specific components."""
        self.component_filters.add(component)

    def add_operation_filter(self, operation: str):
        """Only log messages for specific operations."""
        self.operation_filters.add(operation)

    def set_level_range(self, min_level: LogLevel, max_level: LogLevel):
        """Set minimum and maximum log levels."""
        self.min_level = min_level
        self.max_level = max_level

    def add_file_pattern(self, pattern: str):
        """Add file path pattern to include."""
        self.file_path_patterns.append(pattern)

    def add_exclude_pattern(self, pattern: str):
        """Add pattern to exclude from logs."""
        self.exclude_patterns.append(pattern)

    def set_time_window(self, duration: timedelta):
        """Set time window for log filtering."""
        self.time_window = duration
        self.start_time = datetime.now()

    def should_log(self, record: logging.LogRecord) -> bool:
        """Determine if a log record should be logged based on filters."""
        # Check time window
        if self.time_window and self.start_time:
            if datetime.now() - self.start_time > self.time_window:
                return False

        # Check level range
        if self.min_level:
            if record.levelno < getattr(logging, self.min_level.value):
                return False

        if self.max_level:
            if record.levelno > getattr(logging, self.max_level.value):
                return False

        # Check component filters
        if self.component_filters:
            component = getattr(record, "component", None)
            if component not in self.component_filters:
                return False

        # Check operation filters
        if self.operation_filters:
            operation = getattr(record, "operation", None)
            if operation not in self.operation_filters:
                return False

        # Check file path patterns
        if self.file_path_patterns:
            file_path = getattr(record, "file_path", "")
            if not any(pattern in file_path for pattern in self.file_path_patterns):
                return False

        # Check exclude patterns
        if self.exclude_patterns:
            message = record.getMessage()
            file_path = getattr(record, "file_path", "")
            for pattern in self.exclude_patterns:
                if pattern in message or pattern in file_path:
                    return False

        return True


class LoggingHandler(logging.Handler):
    """Custom logging handler with filtering support."""

    def __init__(self, base_handler: logging.Handler, log_filter: Optional[LogFilter] = None):
        super().__init__()
        self.base_handler = base_handler
        self.log_filter = log_filter
        self.setLevel(base_handler.level)
        self.setFormatter(base_handler.formatter)

    def emit(self, record):
        """Emit a log record if it passes the filter."""
        if self.log_filter and not self.log_filter.should_log(record):
            return

        self.base_handler.emit(record)


class LogMetrics:
    """Collect and track logging metrics."""

    def __init__(self):
        self.metrics = {
            "total_logs": 0,
            "logs_by_level": {},
            "logs_by_component": {},
            "logs_by_operation": {},
            "error_count": 0,
            "warning_count": 0,
            "start_time": datetime.now(),
        }
        self._lock = threading.Lock()

    def record_log(self, record: logging.LogRecord):
        """Record metrics for a log entry."""
        with self._lock:
            self.metrics["total_logs"] += 1

            # Count by level
            level = record.levelname
            self.metrics["logs_by_level"][level] = self.metrics["logs_by_level"].get(level, 0) + 1

            # Count errors and warnings
            if level == "ERROR":
                self.metrics["error_count"] += 1
            elif level == "WARNING":
                self.metrics["warning_count"] += 1

            # Count by component
            component = getattr(record, "component", "unknown")
            self.metrics["logs_by_component"][component] = (
                self.metrics["logs_by_component"].get(component, 0) + 1
            )

            # Count by operation
            operation = getattr(record, "operation", "unknown")
            self.metrics["logs_by_operation"][operation] = (
                self.metrics["logs_by_operation"].get(operation, 0) + 1
            )

    def get_metrics(self) -> Dict[str, Any]:
        """Get current metrics."""
        with self._lock:
            metrics = self.metrics.copy()
            metrics["uptime"] = datetime.now() - metrics["start_time"]
            metrics["logs_per_minute"] = self.metrics["total_logs"] / max(
                1, metrics["uptime"].total_seconds() / 60
            )
            return metrics

    def reset_metrics(self):
        """Reset all metrics."""
        with self._lock:
            self.metrics = {
                "total_logs": 0,
                "logs_by_level": {},
                "logs_by_component": {},
                "logs_by_operation": {},
                "error_count": 0,
                "warning_count": 0,
                "start_time": datetime.now(),
            }


class LoggingConfigManager:
    """Manage logging configuration at runtime."""

    def __init__(self):
        self.logger = get_logger()
        self.log_filter = LogFilter()
        self.metrics = LogMetrics()
        self.config_file: Optional[Path] = None
        self.auto_reload = False
        self._config_watch_thread: Optional[threading.Thread] = None
        self._stop_watching = threading.Event()

    def load_config_file(self, config_file: Union[str, Path], auto_reload: bool = False):
        """Load logging configuration from file."""
        self.config_file = Path(config_file)
        self.auto_reload = auto_reload

        if not self.config_file.exists():
            self.logger.warning("logging_config_file_not_found", config_file=str(self.config_file))
            return

        try:
            with open(self.config_file, "r") as f:
                if self.config_file.suffix.lower() == ".json":
                    config = json.load(f)
                else:
                    # Assume YAML
                    import yaml

                    config = yaml.safe_load(f)

            self._apply_config(config)
            self.logger.info("logging_config_loaded", config_file=str(self.config_file))

            if auto_reload:
                self._start_config_watching()

        except Exception as e:
            self.logger.error(
                "logging_config_load_failed", config_file=str(self.config_file), error=str(e)
            )

    def _apply_config(self, config: Dict[str, Any]):
        """Apply configuration settings."""
        # Apply log level
        if "log_level" in config:
            try:
                level = LogLevel(config["log_level"])
                self.logger.set_level(level)
            except ValueError:
                self.logger.warning("invalid_log_level", level=config["log_level"])

        # Apply filters
        if "filters" in config:
            filter_config = config["filters"]

            if "components" in filter_config:
                for component in filter_config["components"]:
                    self.log_filter.add_component_filter(component)

            if "operations" in filter_config:
                for operation in filter_config["operations"]:
                    self.log_filter.add_operation_filter(operation)

            if "file_patterns" in filter_config:
                for pattern in filter_config["file_patterns"]:
                    self.log_filter.add_file_pattern(pattern)

            if "exclude_patterns" in filter_config:
                for pattern in filter_config["exclude_patterns"]:
                    self.log_filter.add_exclude_pattern(pattern)

            if "level_range" in filter_config:
                range_config = filter_config["level_range"]
                min_level = LogLevel(range_config.get("min", "DEBUG"))
                max_level = LogLevel(range_config.get("max", "CRITICAL"))
                self.log_filter.set_level_range(min_level, max_level)

            if "time_window_minutes" in filter_config:
                duration = timedelta(minutes=filter_config["time_window_minutes"])
                self.log_filter.set_time_window(duration)

    def _start_config_watching(self):
        """Start watching config file for changes."""
        if self._config_watch_thread and self._config_watch_thread.is_alive():
            return

        self._stop_watching.clear()
        self._config_watch_thread = threading.Thread(target=self._watch_config_file)
        self._config_watch_thread.daemon = True
        self._config_watch_thread.start()

    def _watch_config_file(self):
        """Watch config file for changes and reload."""
        if not self.config_file:
            return

        last_modified = self.config_file.stat().st_mtime

        while not self._stop_watching.wait(1.0):  # Check every second
            try:
                current_modified = self.config_file.stat().st_mtime
                if current_modified > last_modified:
                    self.logger.info(
                        "logging_config_file_changed", config_file=str(self.config_file)
                    )
                    self.load_config_file(self.config_file, auto_reload=False)
                    last_modified = current_modified
            except Exception as e:
                self.logger.error("config_watch_error", error=str(e))

    def stop_config_watching(self):
        """Stop watching config file."""
        self._stop_watching.set()
        if self._config_watch_thread:
            self._config_watch_thread.join(timeout=2.0)

    def set_runtime_filter(self, **kwargs):
        """Set runtime log filters."""
        if "component" in kwargs:
            self.log_filter.add_component_filter(kwargs["component"])

        if "operation" in kwargs:
            self.log_filter.add_operation_filter(kwargs["operation"])

        if "min_level" in kwargs:
            self.log_filter.min_level = LogLevel(kwargs["min_level"])

        if "max_level" in kwargs:
            self.log_filter.max_level = LogLevel(kwargs["max_level"])

        if "file_pattern" in kwargs:
            self.log_filter.add_file_pattern(kwargs["file_pattern"])

        if "exclude_pattern" in kwargs:
            self.log_filter.add_exclude_pattern(kwargs["exclude_pattern"])

        self.logger.info("runtime_filter_applied", filters=kwargs)

    def clear_filters(self):
        """Clear all active filters."""
        self.log_filter = LogFilter()
        self.logger.info("log_filters_cleared")

    def get_metrics(self) -> Dict[str, Any]:
        """Get current logging metrics."""
        return self.metrics.get_metrics()

    def export_logs(
        self,
        output_file: Union[str, Path],
        start_time: Optional[datetime] = None,
        end_time: Optional[datetime] = None,
        filters: Optional[Dict[str, Any]] = None,
    ) -> int:
        """Export logs to file with optional filtering."""
        # This would require access to log files or a log buffer
        # For now, return a placeholder implementation
        self.logger.info(
            "log_export_requested",
            output_file=str(output_file),
            start_time=start_time,
            end_time=end_time,
            filters=filters,
        )
        return 0

    def create_debug_snapshot(self) -> Dict[str, Any]:
        """Create a debug snapshot with current state."""
        return {
            "timestamp": datetime.now().isoformat(),
            "metrics": self.get_metrics(),
            "active_filters": {
                "components": list(self.log_filter.component_filters),
                "operations": list(self.log_filter.operation_filters),
                "file_patterns": self.log_filter.file_path_patterns,
                "exclude_patterns": self.log_filter.exclude_patterns,
                "min_level": self.log_filter.min_level.value if self.log_filter.min_level else None,
                "max_level": self.log_filter.max_level.value if self.log_filter.max_level else None,
            },
            "config_file": str(self.config_file) if self.config_file else None,
            "auto_reload": self.auto_reload,
        }


# Global configuration manager instance
_config_manager: Optional[LoggingConfigManager] = None


def get_config_manager() -> LoggingConfigManager:
    """Get the global logging configuration manager."""
    global _config_manager
    if _config_manager is None:
        _config_manager = LoggingConfigManager()
    return _config_manager


def setup_advanced_logging(
    config_file: Optional[Union[str, Path]] = None,
    auto_reload: bool = False,
    enable_metrics: bool = True,
) -> LoggingConfigManager:
    """Setup advanced logging with configuration management."""
    config_manager = get_config_manager()

    if config_file:
        config_manager.load_config_file(config_file, auto_reload)

    return config_manager


# CLI-style functions for runtime log management
def set_log_level(level: Union[str, LogLevel]):
    """Set log level at runtime."""
    logger = get_logger()
    if isinstance(level, str):
        level = LogLevel(level)
    logger.set_level(level)


def filter_by_component(*components: str):
    """Filter logs to only show specific components."""
    config_manager = get_config_manager()
    for component in components:
        config_manager.set_runtime_filter(component=component)


def filter_by_operation(*operations: str):
    """Filter logs to only show specific operations."""
    config_manager = get_config_manager()
    for operation in operations:
        config_manager.set_runtime_filter(operation=operation)


def exclude_pattern(*patterns: str):
    """Exclude logs matching patterns."""
    config_manager = get_config_manager()
    for pattern in patterns:
        config_manager.set_runtime_filter(exclude_pattern=pattern)


def clear_all_filters():
    """Clear all active log filters."""
    get_config_manager().clear_filters()


def show_log_metrics():
    """Display current logging metrics."""
    metrics = get_config_manager().get_metrics()
    logger = get_logger()
    logger.info("current_log_metrics", **metrics)
