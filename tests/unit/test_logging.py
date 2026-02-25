"""
Tests for the enhanced logging system.
"""

import json
import logging
import tempfile
import threading
import time
from pathlib import Path
from unittest.mock import patch

import pytest

from linkwatcher.logging import (
    ColoredFormatter,
    JSONFormatter,
    LinkWatcherLogger,
    LogLevel,
    LogTimer,
    PerformanceLogger,
    get_logger,
    log_context,
    setup_logging,
    with_context,
)


class TestLogContext:
    """Test the thread-local logging context."""

    def test_set_and_get_context(self):
        """Test setting and getting context variables."""
        log_context.clear_context()

        log_context.set_context(operation="test", file_path="test.md")
        context = log_context.get_context()

        assert context["operation"] == "test"
        assert context["file_path"] == "test.md"

    def test_context_isolation_between_threads(self):
        """Test that context is isolated between threads."""
        results = {}

        def thread_function(thread_id):
            log_context.set_context(thread_id=thread_id, operation=f"op_{thread_id}")
            time.sleep(0.1)  # Allow other threads to run
            context = log_context.get_context()
            results[thread_id] = context

        # Start multiple threads
        threads = []
        for i in range(3):
            thread = threading.Thread(target=thread_function, args=(i,))
            threads.append(thread)
            thread.start()

        # Wait for all threads to complete
        for thread in threads:
            thread.join()

        # Verify each thread had its own context
        assert len(results) == 3
        for i in range(3):
            assert results[i]["thread_id"] == i
            assert results[i]["operation"] == f"op_{i}"

    def test_clear_context(self):
        """Test clearing context."""
        log_context.set_context(test="value")
        assert log_context.get_context()["test"] == "value"

        log_context.clear_context()
        assert log_context.get_context() == {}


class TestColoredFormatter:
    """Test the colored console formatter."""

    def test_colored_formatting(self):
        """Test colored output formatting."""
        formatter = ColoredFormatter(colored=True, show_icons=True)

        # Create a log record
        record = logging.LogRecord(
            name="test",
            level=logging.INFO,
            pathname="test.py",
            lineno=10,
            msg="Test message",
            args=(),
            exc_info=None,
        )

        formatted = formatter.format(record)

        # Should contain color codes and icon
        assert "ℹ️" in formatted
        assert "Test message" in formatted
        assert "INFO" in formatted

    def test_non_colored_formatting(self):
        """Test non-colored output formatting."""
        formatter = ColoredFormatter(colored=False, show_icons=False)

        record = logging.LogRecord(
            name="test",
            level=logging.WARNING,
            pathname="test.py",
            lineno=10,
            msg="Warning message",
            args=(),
            exc_info=None,
        )

        formatted = formatter.format(record)

        # Should not contain color codes or icons
        assert "\033[" not in formatted  # No ANSI color codes
        assert "⚠️" not in formatted
        assert "Warning message" in formatted
        assert "WARNING" in formatted

    def test_context_inclusion(self):
        """Test that context is included in formatted output."""
        formatter = ColoredFormatter(colored=False, show_icons=False)

        # Set context
        log_context.set_context(operation="test_op", file_count=5)

        record = logging.LogRecord(
            name="test",
            level=logging.INFO,
            pathname="test.py",
            lineno=10,
            msg="Test with context",
            args=(),
            exc_info=None,
        )

        formatted = formatter.format(record)

        # Should contain context information
        assert "operation=test_op" in formatted
        assert "file_count=5" in formatted

        log_context.clear_context()


class TestJSONFormatter:
    """Test the JSON formatter."""

    def test_json_formatting(self):
        """Test JSON output formatting."""
        formatter = JSONFormatter()

        record = logging.LogRecord(
            name="test.logger",
            level=logging.ERROR,
            pathname="/path/test.py",
            lineno=25,
            msg="Error message",
            args=(),
            exc_info=None,
        )
        record.module = "test"
        record.funcName = "test_function"
        record.thread = 12345
        record.threadName = "MainThread"

        formatted = formatter.format(record)
        data = json.loads(formatted)

        assert data["level"] == "ERROR"
        assert data["logger"] == "test.logger"
        assert data["message"] == "Error message"
        assert data["module"] == "test"
        assert data["function"] == "test_function"
        assert data["line"] == 25
        assert data["thread"] == 12345
        assert data["thread_name"] == "MainThread"
        assert "timestamp" in data

    def test_json_with_context(self):
        """Test JSON formatting with context."""
        formatter = JSONFormatter()

        # Set context
        log_context.set_context(operation="file_move", old_path="a.md", new_path="b.md")

        record = logging.LogRecord(
            name="test",
            level=logging.INFO,
            pathname="test.py",
            lineno=10,
            msg="File moved",
            args=(),
            exc_info=None,
        )
        record.module = "test"
        record.funcName = "test_function"
        record.thread = 12345
        record.threadName = "MainThread"

        formatted = formatter.format(record)
        data = json.loads(formatted)

        assert "context" in data
        assert data["context"]["operation"] == "file_move"
        assert data["context"]["old_path"] == "a.md"
        assert data["context"]["new_path"] == "b.md"

        log_context.clear_context()


class TestPerformanceLogger:
    """Test the performance logging functionality."""

    def test_timer_operations(self):
        """Test starting and ending timers."""
        perf_logger = PerformanceLogger("test.performance")

        timer_id = perf_logger.start_timer("test_operation")
        assert timer_id in perf_logger._timers

        time.sleep(0.01)  # Small delay

        with patch.object(perf_logger.logger, "info") as mock_info:
            perf_logger.end_timer(timer_id, "test_operation", file_count=5)

            # Verify the timer was removed and logged
            assert timer_id not in perf_logger._timers
            mock_info.assert_called_once()

            # Check the logged data
            call_args = mock_info.call_args
            assert call_args[0][0] == "operation_completed"
            assert call_args[1]["operation"] == "test_operation"
            assert call_args[1]["file_count"] == 5
            assert "duration_ms" in call_args[1]
            assert call_args[1]["duration_ms"] > 0

    def test_metric_logging(self):
        """Test logging performance metrics."""
        perf_logger = PerformanceLogger("test.performance")

        with patch.object(perf_logger.logger, "info") as mock_info:
            perf_logger.log_metric("files_processed", 150, "count", operation="scan")

            mock_info.assert_called_once_with(
                "metric", metric_name="files_processed", value=150, unit="count", operation="scan"
            )

    def test_invalid_timer_id(self):
        """Test handling of invalid timer IDs."""
        perf_logger = PerformanceLogger("test.performance")

        with patch.object(perf_logger.logger, "warning") as mock_warning:
            perf_logger.end_timer("invalid_id", "test_operation")

            mock_warning.assert_called_once_with(
                "timer_not_found", timer_id="invalid_id", operation="test_operation"
            )


class TestLinkWatcherLogger:
    """Test the main LinkWatcher logger class."""

    def test_logger_initialization(self):
        """Test logger initialization with default settings."""
        with tempfile.TemporaryDirectory() as temp_dir:
            log_file = Path(temp_dir) / "test.log"

            logger = LinkWatcherLogger(
                name="test.logger",
                level=LogLevel.DEBUG,
                log_file=str(log_file),
                colored_output=True,
                show_icons=True,
            )

            assert logger.name == "test.logger"
            assert logger.level == LogLevel.DEBUG
            assert logger.colored_output is True
            assert logger.show_icons is True

            # Test that log file was created
            logger.info("Test message")
            assert log_file.exists()

    def test_log_level_change(self):
        """Test changing log level dynamically."""
        logger = LinkWatcherLogger(level=LogLevel.INFO)

        assert logger.level == LogLevel.INFO

        logger.set_level(LogLevel.DEBUG)
        assert logger.level == LogLevel.DEBUG

    def test_convenience_methods(self):
        """Test convenience methods for common events."""
        logger = LinkWatcherLogger()

        with patch.object(logger.struct_logger, "info") as mock_info:
            logger.file_moved("old.md", "new.md", 3)

            mock_info.assert_called_once_with(
                "file_moved",
                old_path="old.md",
                new_path="new.md",
                references_count=3,
                event_type="file_move",
            )

        with patch.object(logger.struct_logger, "warning") as mock_warning:
            logger.file_deleted("deleted.md", 2)

            mock_warning.assert_called_once_with(
                "file_deleted", file_path="deleted.md", references_count=2, event_type="file_delete"
            )

    def test_context_management(self):
        """Test context setting and clearing."""
        logger = LinkWatcherLogger()

        logger.set_context(operation="test", thread_id=1)
        context = log_context.get_context()
        assert context["operation"] == "test"
        assert context["thread_id"] == 1

        logger.clear_context()
        context = log_context.get_context()
        assert context == {}


class TestLogTimer:
    """Test the LogTimer context manager."""

    def test_successful_operation(self):
        """Test timing a successful operation."""
        logger = LinkWatcherLogger()

        with patch.object(logger, "debug") as mock_debug:
            with LogTimer("test_operation", logger, file_count=5):
                time.sleep(0.01)

            # Should have logged start and completion
            assert mock_debug.call_count == 2

            # Check start log
            start_call = mock_debug.call_args_list[0]
            assert start_call[0][0] == "started_test_operation"
            assert start_call[1]["file_count"] == 5

            # Check completion log
            end_call = mock_debug.call_args_list[1]
            assert end_call[0][0] == "completed_test_operation"
            assert end_call[1]["file_count"] == 5

    def test_failed_operation(self):
        """Test timing a failed operation."""
        logger = LinkWatcherLogger()

        with patch.object(logger, "debug") as mock_debug, patch.object(
            logger, "error"
        ) as mock_error:
            try:
                with LogTimer("test_operation", logger, file_count=5):
                    raise ValueError("Test error")
            except ValueError:
                pass

            # Should have logged start and error
            mock_debug.assert_called_once_with("started_test_operation", file_count=5)
            mock_error.assert_called_once()

            error_call = mock_error.call_args
            assert error_call[0][0] == "failed_test_operation"
            assert error_call[1]["error_type"] == "ValueError"
            assert error_call[1]["error_message"] == "Test error"
            assert error_call[1]["file_count"] == 5


class TestWithContextDecorator:
    """Test the with_context decorator."""

    def test_context_decorator(self):
        """Test that context is properly set and cleared."""

        @with_context(operation="test_function", component="test")
        def test_function():
            context = log_context.get_context()
            return context

        # Context should be empty before call
        log_context.clear_context()
        assert log_context.get_context() == {}

        # Call function and check context
        result = test_function()
        assert result["operation"] == "test_function"
        assert result["component"] == "test"

        # Context should be cleared after call
        assert log_context.get_context() == {}

    def test_context_decorator_with_exception(self):
        """Test that context is cleared even when function raises exception."""

        @with_context(operation="failing_function")
        def failing_function():
            raise ValueError("Test error")

        log_context.clear_context()

        try:
            failing_function()
        except ValueError:
            pass

        # Context should still be cleared
        assert log_context.get_context() == {}


class TestGlobalLoggerFunctions:
    """Test global logger setup and access functions."""

    @pytest.mark.xfail(reason="Global structlog cached state bleeds between test instances")
    def test_setup_logging(self):
        """Test global logger setup."""
        with tempfile.TemporaryDirectory() as temp_dir:
            log_file = Path(temp_dir) / "global_test.log"

            logger = setup_logging(
                level=LogLevel.DEBUG, log_file=str(log_file), colored_output=False
            )

            assert isinstance(logger, LinkWatcherLogger)
            assert logger.level == LogLevel.DEBUG
            assert logger.colored_output is False

            # Test that get_logger returns the same instance
            same_logger = get_logger()
            assert same_logger is logger

    def test_get_logger_default(self):
        """Test getting logger with default settings."""
        # Reset global logger
        import linkwatcher.logging

        linkwatcher.logging._logger = None

        logger = get_logger()
        assert isinstance(logger, LinkWatcherLogger)
        assert logger.level == LogLevel.INFO  # Default level


if __name__ == "__main__":
    pytest.main([__file__])
