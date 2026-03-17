"""
Tests for advanced logging features and configuration management.
"""

import json
import tempfile
import threading
import time
from datetime import datetime, timedelta
from pathlib import Path
from unittest.mock import Mock, patch

import pytest
import yaml

from linkwatcher.logging import LogLevel, get_logger, setup_logging
from linkwatcher.logging_config import (
    LogFilter,
    LoggingConfigManager,
    LogMetrics,
    get_config_manager,
    setup_advanced_logging,
)


class TestLogFilter:
    """Test the LogFilter class."""

    def test_component_filtering(self):
        """Test filtering by component."""
        log_filter = LogFilter()
        log_filter.add_component_filter("handler")
        log_filter.add_component_filter("updater")

        # Create mock log records
        record1 = Mock()
        record1.component = "handler"
        record1.levelno = 20  # INFO

        record2 = Mock()
        record2.component = "parser"
        record2.levelno = 20  # INFO

        record3 = Mock()
        record3.component = "updater"
        record3.levelno = 20  # INFO

        assert log_filter.should_log(record1) is True
        assert log_filter.should_log(record2) is False
        assert log_filter.should_log(record3) is True

    def test_operation_filtering(self):
        """Test filtering by operation."""
        log_filter = LogFilter()
        log_filter.add_operation_filter("file_move")
        log_filter.add_operation_filter("link_update")

        record1 = Mock()
        record1.operation = "file_move"
        record1.levelno = 20

        record2 = Mock()
        record2.operation = "file_scan"
        record2.levelno = 20

        assert log_filter.should_log(record1) is True
        assert log_filter.should_log(record2) is False

    def test_level_range_filtering(self):
        """Test filtering by log level range."""
        log_filter = LogFilter()
        log_filter.set_level_range(LogLevel.WARNING, LogLevel.ERROR)

        record1 = Mock()
        record1.levelno = 10  # DEBUG

        record2 = Mock()
        record2.levelno = 30  # WARNING

        record3 = Mock()
        record3.levelno = 40  # ERROR

        record4 = Mock()
        record4.levelno = 50  # CRITICAL

        assert log_filter.should_log(record1) is False
        assert log_filter.should_log(record2) is True
        assert log_filter.should_log(record3) is True
        assert log_filter.should_log(record4) is False

    def test_file_pattern_filtering(self):
        """Test filtering by file patterns."""
        log_filter = LogFilter()
        log_filter.add_file_pattern("docs/")
        log_filter.add_file_pattern(".md")

        record1 = Mock()
        record1.file_path = "docs/api.md"
        record1.levelno = 20

        record2 = Mock()
        record2.file_path = "../tests/unit/main.py"
        record2.levelno = 20

        record3 = Mock()
        record3.file_path = "README.md"
        record3.levelno = 20

        assert log_filter.should_log(record1) is True
        assert log_filter.should_log(record2) is False
        assert log_filter.should_log(record3) is True

    def test_exclude_pattern_filtering(self):
        """Test excluding patterns."""
        log_filter = LogFilter()
        log_filter.add_exclude_pattern("temp")
        log_filter.add_exclude_pattern(".tmp")

        record1 = Mock()
        record1.getMessage.return_value = "Processing file temp.md"
        record1.file_path = ""
        record1.levelno = 20

        record2 = Mock()
        record2.getMessage.return_value = "Processing file main.py"
        record2.file_path = "file.tmp"
        record2.levelno = 20

        record3 = Mock()
        record3.getMessage.return_value = "Processing file main.py"
        record3.file_path = "main.py"
        record3.levelno = 20

        assert log_filter.should_log(record1) is False
        assert log_filter.should_log(record2) is False
        assert log_filter.should_log(record3) is True

    def test_time_window_filtering(self):
        """Test time window filtering."""
        log_filter = LogFilter()
        log_filter.set_time_window(timedelta(seconds=1))

        record = Mock()
        record.levelno = 20

        # Should log immediately
        assert log_filter.should_log(record) is True

        # Wait for time window to expire
        time.sleep(1.1)

        # Should not log after time window
        assert log_filter.should_log(record) is False


class TestLogMetrics:
    """Test the LogMetrics class."""

    def test_basic_metrics_collection(self):
        """Test basic metrics collection."""
        metrics = LogMetrics()

        # Create mock log records
        record1 = Mock()
        record1.levelname = "INFO"
        record1.component = "handler"
        record1.operation = "file_move"

        record2 = Mock()
        record2.levelname = "ERROR"
        record2.component = "updater"
        record2.operation = "link_update"

        record3 = Mock()
        record3.levelname = "WARNING"
        record3.component = "handler"
        record3.operation = "file_move"

        # Record metrics
        metrics.record_log(record1)
        metrics.record_log(record2)
        metrics.record_log(record3)

        # Check metrics
        current_metrics = metrics.get_metrics()

        assert current_metrics["total_logs"] == 3
        assert current_metrics["logs_by_level"]["INFO"] == 1
        assert current_metrics["logs_by_level"]["ERROR"] == 1
        assert current_metrics["logs_by_level"]["WARNING"] == 1
        assert current_metrics["logs_by_component"]["handler"] == 2
        assert current_metrics["logs_by_component"]["updater"] == 1
        assert current_metrics["logs_by_operation"]["file_move"] == 2
        assert current_metrics["logs_by_operation"]["link_update"] == 1
        assert current_metrics["error_count"] == 1
        assert current_metrics["warning_count"] == 1

    def test_metrics_reset(self):
        """Test resetting metrics."""
        metrics = LogMetrics()

        record = Mock()
        record.levelname = "INFO"
        record.component = "test"
        record.operation = "test"

        metrics.record_log(record)
        assert metrics.get_metrics()["total_logs"] == 1

        metrics.reset_metrics()
        assert metrics.get_metrics()["total_logs"] == 0

    def test_thread_safety(self):
        """Test that metrics collection is thread-safe."""
        metrics = LogMetrics()

        def record_logs():
            for i in range(100):
                record = Mock()
                record.levelname = "INFO"
                record.component = f"component_{i % 5}"
                record.operation = f"operation_{i % 3}"
                metrics.record_log(record)

        # Start multiple threads
        threads = []
        for _ in range(5):
            thread = threading.Thread(target=record_logs)
            threads.append(thread)
            thread.start()

        # Wait for all threads to complete
        for thread in threads:
            thread.join()

        # Check that all logs were recorded
        current_metrics = metrics.get_metrics()
        assert current_metrics["total_logs"] == 500


class TestLoggingConfigManager:
    """Test the LoggingConfigManager class."""

    def test_config_file_loading(self):
        """Test loading configuration from file."""
        config_manager = LoggingConfigManager()

        # Create temporary config file
        config_data = {
            "log_level": "DEBUG",
            "filters": {
                "components": ["handler", "updater"],
                "operations": ["file_move"],
                "level_range": {"min": "INFO", "max": "ERROR"},
            },
        }

        with tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False) as f:
            json.dump(config_data, f)
            config_file = f.name

        try:
            config_manager.load_config_file(config_file)

            # Check that filters were applied
            assert "handler" in config_manager.log_filter.component_filters
            assert "updater" in config_manager.log_filter.component_filters
            assert "file_move" in config_manager.log_filter.operation_filters
            assert config_manager.log_filter.min_level == LogLevel.INFO
            assert config_manager.log_filter.max_level == LogLevel.ERROR

        finally:
            Path(config_file).unlink()

    def test_yaml_config_loading(self):
        """Test loading YAML configuration."""
        config_manager = LoggingConfigManager()

        config_data = {
            "log_level": "WARNING",
            "filters": {"file_patterns": ["docs/", ".md"], "exclude_patterns": ["temp", ".tmp"]},
        }

        with tempfile.NamedTemporaryFile(mode="w", suffix=".yaml", delete=False) as f:
            yaml.dump(config_data, f)
            config_file = f.name

        try:
            config_manager.load_config_file(config_file)

            # Check that filters were applied
            assert "docs/" in config_manager.log_filter.file_path_patterns
            assert ".md" in config_manager.log_filter.file_path_patterns
            assert "temp" in config_manager.log_filter.exclude_patterns
            assert ".tmp" in config_manager.log_filter.exclude_patterns

        finally:
            Path(config_file).unlink()

    def test_runtime_filter_setting(self):
        """Test setting filters at runtime."""
        config_manager = LoggingConfigManager()

        config_manager.set_runtime_filter(
            component="test_component",
            operation="test_operation",
            min_level="WARNING",
            file_pattern="test/",
            exclude_pattern="ignore",
        )

        assert "test_component" in config_manager.log_filter.component_filters
        assert "test_operation" in config_manager.log_filter.operation_filters
        assert config_manager.log_filter.min_level == LogLevel.WARNING
        assert "test/" in config_manager.log_filter.file_path_patterns
        assert "ignore" in config_manager.log_filter.exclude_patterns

    def test_filter_clearing(self):
        """Test clearing all filters."""
        config_manager = LoggingConfigManager()

        # Set some filters
        config_manager.set_runtime_filter(component="test", operation="test")
        assert "test" in config_manager.log_filter.component_filters

        # Clear filters
        config_manager.clear_filters()
        assert len(config_manager.log_filter.component_filters) == 0
        assert len(config_manager.log_filter.operation_filters) == 0

    def test_debug_snapshot(self):
        """Test creating debug snapshot."""
        config_manager = LoggingConfigManager()

        # Set some configuration
        config_manager.set_runtime_filter(component="test", min_level="INFO")

        snapshot = config_manager.create_debug_snapshot()

        assert "timestamp" in snapshot
        assert "metrics" in snapshot
        assert "active_filters" in snapshot
        assert "test" in snapshot["active_filters"]["components"]
        assert snapshot["active_filters"]["min_level"] == "INFO"


class TestAdvancedLoggingIntegration:
    """Test integration of advanced logging features."""

    def test_setup_advanced_logging(self):
        """Test setting up advanced logging."""
        with tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False) as f:
            config_data = {"log_level": "DEBUG", "filters": {"components": ["test"]}}
            json.dump(config_data, f)
            config_file = f.name

        try:
            config_manager = setup_advanced_logging(config_file)

            assert isinstance(config_manager, LoggingConfigManager)
            assert "test" in config_manager.log_filter.component_filters

        finally:
            Path(config_file).unlink()

    def test_config_manager_singleton(self):
        """Test that config manager is a singleton."""
        manager1 = get_config_manager()
        manager2 = get_config_manager()

        assert manager1 is manager2

    @patch("linkwatcher.logging_config.get_logger")
    def test_logging_with_filters(self, mock_get_logger):
        """Test that logging respects filters."""
        mock_logger = Mock()
        mock_get_logger.return_value = mock_logger

        config_manager = LoggingConfigManager()
        config_manager.set_runtime_filter(component="allowed")

        # This would require integration with actual logging system
        # For now, just verify the filter configuration
        assert "allowed" in config_manager.log_filter.component_filters


class TestLoggingPerformance:
    """Test logging performance and overhead."""

    def test_logging_overhead(self):
        """Test that logging doesn't add significant overhead."""
        logger = get_logger()

        # Time logging operations
        start_time = time.time()

        for i in range(1000):
            logger.debug("test_message", iteration=i, component="test")

        end_time = time.time()
        duration = end_time - start_time

        # Should complete 1000 log operations in reasonable time
        assert duration < 1.0  # Less than 1 second

    def test_filter_performance(self):
        """Test that filtering doesn't add significant overhead."""
        log_filter = LogFilter()
        log_filter.add_component_filter("test")
        log_filter.add_operation_filter("test_op")
        log_filter.set_level_range(LogLevel.INFO, LogLevel.ERROR)

        # Create mock record
        record = Mock()
        record.levelno = 20  # INFO
        record.component = "test"
        record.operation = "test_op"
        record.file_path = "test.py"
        record.getMessage.return_value = "test message"

        # Time filter operations
        start_time = time.time()

        for _ in range(10000):
            log_filter.should_log(record)

        end_time = time.time()
        duration = end_time - start_time

        # Should complete 10000 filter operations quickly
        assert duration < 0.1  # Less than 100ms


if __name__ == "__main__":
    pytest.main([__file__])
