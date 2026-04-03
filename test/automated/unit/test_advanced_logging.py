"""
Tests for advanced logging features and configuration management.
"""

import json
import logging
import tempfile
import time
from pathlib import Path
from unittest.mock import patch

import pytest
import yaml

from linkwatcher.logging import LogLevel, get_logger, reset_logger
from linkwatcher.logging_config import (
    LoggingConfigManager,
    get_config_manager,
    reset_config_manager,
    set_log_level,
    setup_advanced_logging,
)

pytestmark = [
    pytest.mark.feature("3.1.1"),
    pytest.mark.priority("Standard"),
    pytest.mark.test_type("unit"),
    pytest.mark.specification(
        "test/specifications/feature-specs/test-spec-3-1-1-logging-system.md"
    ),
]


class TestLoggingConfigManager:
    """Test the LoggingConfigManager class."""

    def test_config_file_loading(self):
        """Test loading JSON config applies log level behaviorally."""
        config_manager = LoggingConfigManager()

        config_data = {"log_level": "DEBUG"}

        with tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False) as f:
            json.dump(config_data, f)
            config_file = f.name

        try:
            config_manager.load_config_file(config_file)
            assert config_manager.config_file == Path(config_file)
            # Verify log level was actually applied (behavioral, not just stored)
            assert config_manager.logger.level == LogLevel.DEBUG
            assert config_manager.logger.logger.level == logging.DEBUG
        finally:
            Path(config_file).unlink()

    def test_yaml_config_loading(self):
        """Test loading YAML config applies log level behaviorally."""
        config_manager = LoggingConfigManager()

        config_data = {"log_level": "WARNING"}

        with tempfile.NamedTemporaryFile(mode="w", suffix=".yaml", delete=False) as f:
            yaml.dump(config_data, f)
            config_file = f.name

        try:
            config_manager.load_config_file(config_file)
            assert config_manager.config_file == Path(config_file)
            # Verify log level was actually applied
            assert config_manager.logger.level == LogLevel.WARNING
            assert config_manager.logger.logger.level == logging.WARNING
        finally:
            Path(config_file).unlink()

    def test_debug_snapshot(self):
        """Test creating debug snapshot."""
        config_manager = LoggingConfigManager()

        snapshot = config_manager.create_debug_snapshot()

        assert "timestamp" in snapshot
        assert "config_file" in snapshot
        assert "auto_reload" in snapshot


class TestAdvancedLoggingIntegration:
    """Test integration of advanced logging features."""

    def test_setup_advanced_logging(self):
        """Test setting up advanced logging."""
        with tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False) as f:
            config_data = {"log_level": "DEBUG"}
            json.dump(config_data, f)
            config_file = f.name

        try:
            config_manager = setup_advanced_logging(config_file)
            assert isinstance(config_manager, LoggingConfigManager)
        finally:
            Path(config_file).unlink()

    def test_config_manager_singleton(self):
        """Test that config manager is a singleton."""
        manager1 = get_config_manager()
        manager2 = get_config_manager()

        assert manager1 is manager2


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


class TestConfigLoadingErrors:
    """Test error handling paths in config loading."""

    def test_missing_config_file(self):
        """Test loading a nonexistent config file warns and returns early."""
        config_manager = LoggingConfigManager()
        original_level = config_manager.logger.level

        config_manager.load_config_file("/nonexistent/path/config.json")

        # File path is stored even for missing files
        assert config_manager.config_file == Path("/nonexistent/path/config.json")
        # Log level unchanged — config was not applied
        assert config_manager.logger.level == original_level

    def test_invalid_log_level_in_config(self):
        """Test that an invalid log level in config triggers warning, level unchanged."""
        config_manager = LoggingConfigManager()
        original_level = config_manager.logger.level

        config_data = {"log_level": "NONEXISTENT_LEVEL"}

        with tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False) as f:
            json.dump(config_data, f)
            config_file = f.name

        try:
            config_manager.load_config_file(config_file)
            # Level should remain unchanged after invalid value
            assert config_manager.logger.level == original_level
            assert config_manager.config_file == Path(config_file)
        finally:
            Path(config_file).unlink()

    def test_malformed_json_config(self):
        """Test that malformed JSON triggers error handler, no crash."""
        config_manager = LoggingConfigManager()
        original_level = config_manager.logger.level

        with tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False) as f:
            f.write("{invalid json content!!!}")
            config_file = f.name

        try:
            # Should not raise — error is caught internally
            config_manager.load_config_file(config_file)
            assert config_manager.config_file == Path(config_file)
            # Level unchanged due to load failure
            assert config_manager.logger.level == original_level
        finally:
            Path(config_file).unlink()

    def test_malformed_yaml_config(self):
        """Test that malformed YAML triggers error handler, no crash."""
        config_manager = LoggingConfigManager()
        original_level = config_manager.logger.level

        with tempfile.NamedTemporaryFile(mode="w", suffix=".yaml", delete=False) as f:
            f.write(":\n  - :\n  invalid: [unterminated")
            config_file = f.name

        try:
            config_manager.load_config_file(config_file)
            assert config_manager.config_file == Path(config_file)
            assert config_manager.logger.level == original_level
        finally:
            Path(config_file).unlink()


class TestConfigUtilities:
    """Test module-level utility functions."""

    def test_set_log_level_with_string(self):
        """Test set_log_level() with a string argument."""
        logger = get_logger()
        original_level = logger.level

        try:
            set_log_level("DEBUG")
            assert logger.level == LogLevel.DEBUG
            assert logger.logger.level == logging.DEBUG
        finally:
            logger.set_level(original_level)

    def test_set_log_level_with_enum(self):
        """Test set_log_level() with a LogLevel enum argument."""
        logger = get_logger()
        original_level = logger.level

        try:
            set_log_level(LogLevel.WARNING)
            assert logger.level == LogLevel.WARNING
            assert logger.logger.level == logging.WARNING
        finally:
            logger.set_level(original_level)

    def test_set_log_level_invalid_string(self):
        """Test set_log_level() with invalid string raises ValueError."""
        with pytest.raises(ValueError):
            set_log_level("NOT_A_LEVEL")

    def test_reset_config_manager(self):
        """Test reset_config_manager() clears the singleton."""
        manager1 = get_config_manager()
        reset_config_manager()
        manager2 = get_config_manager()

        # After reset, a new instance should be created
        assert manager1 is not manager2

    def test_reset_config_manager_allows_fresh_config(self):
        """Test that after reset, fresh config can be loaded independently."""
        manager1 = get_config_manager()
        manager1.auto_reload = True  # Modify state

        reset_config_manager()
        manager2 = get_config_manager()

        # New manager should have default state
        assert manager2.auto_reload is False
        assert manager2.config_file is None


class TestConfigHotReload:
    """Test config file watching and hot-reload functionality."""

    def test_start_config_watching_creates_thread(self):
        """Test that auto_reload=True starts a daemon watch thread."""
        config_manager = LoggingConfigManager()

        config_data = {"log_level": "DEBUG"}

        with tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False) as f:
            json.dump(config_data, f)
            config_file = f.name

        try:
            config_manager.load_config_file(config_file, auto_reload=True)
            assert config_manager.auto_reload is True
            assert config_manager._config_watch_thread is not None
            assert config_manager._config_watch_thread.is_alive()
            assert config_manager._config_watch_thread.daemon is True
        finally:
            config_manager.stop_config_watching()
            Path(config_file).unlink()

    def test_stop_config_watching(self):
        """Test that stop_config_watching() cleanly terminates the thread."""
        config_manager = LoggingConfigManager()

        config_data = {"log_level": "DEBUG"}

        with tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False) as f:
            json.dump(config_data, f)
            config_file = f.name

        try:
            config_manager.load_config_file(config_file, auto_reload=True)
            assert config_manager._config_watch_thread.is_alive()

            config_manager.stop_config_watching()
            # Thread should stop within the 2s join timeout
            assert not config_manager._config_watch_thread.is_alive()
        finally:
            Path(config_file).unlink()

    def test_config_change_triggers_reload(self):
        """Test that modifying config file triggers reload via watcher."""
        config_manager = LoggingConfigManager()

        config_data = {"log_level": "INFO"}

        with tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False) as f:
            json.dump(config_data, f)
            config_file = f.name

        try:
            config_manager.load_config_file(config_file, auto_reload=True)
            assert config_manager.logger.level == LogLevel.INFO

            # Modify config file to change level
            time.sleep(0.1)  # Ensure mtime differs
            with open(config_file, "w") as f:
                json.dump({"log_level": "DEBUG"}, f)

            # Wait for watcher to detect change (polls every 1s)
            time.sleep(2.5)

            assert config_manager.logger.level == LogLevel.DEBUG
        finally:
            config_manager.stop_config_watching()
            Path(config_file).unlink()

    def test_start_watching_idempotent(self):
        """Test that calling _start_config_watching twice doesn't create duplicate threads."""
        config_manager = LoggingConfigManager()

        config_data = {"log_level": "DEBUG"}

        with tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False) as f:
            json.dump(config_data, f)
            config_file = f.name

        try:
            config_manager.load_config_file(config_file, auto_reload=True)
            first_thread = config_manager._config_watch_thread

            # Calling again should not create a new thread
            config_manager._start_config_watching()
            assert config_manager._config_watch_thread is first_thread
        finally:
            config_manager.stop_config_watching()
            Path(config_file).unlink()

    def test_watch_config_file_handles_stat_error(self):
        """Test that watch thread handles file stat errors gracefully."""
        config_manager = LoggingConfigManager()

        config_data = {"log_level": "DEBUG"}

        with tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False) as f:
            json.dump(config_data, f)
            config_file = f.name

        try:
            config_manager.load_config_file(config_file, auto_reload=True)
            assert config_manager._config_watch_thread.is_alive()

            # Delete the file while watcher is running — should not crash
            Path(config_file).unlink()
            time.sleep(2.0)  # Let the watcher encounter the missing file

            # Thread should still be alive (error caught internally)
            assert config_manager._config_watch_thread.is_alive()
        finally:
            config_manager.stop_config_watching()
            # File already deleted; no cleanup needed


if __name__ == "__main__":
    pytest.main([__file__])
