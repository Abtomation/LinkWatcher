"""
Tests for advanced logging features and configuration management.
"""

import json
import tempfile
import time
from pathlib import Path

import pytest
import yaml

from linkwatcher.logging import get_logger
from linkwatcher.logging_config import (
    LoggingConfigManager,
    get_config_manager,
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
        """Test loading configuration from JSON file."""
        config_manager = LoggingConfigManager()

        config_data = {"log_level": "DEBUG"}

        with tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False) as f:
            json.dump(config_data, f)
            config_file = f.name

        try:
            config_manager.load_config_file(config_file)
            assert config_manager.config_file == Path(config_file)
        finally:
            Path(config_file).unlink()

    def test_yaml_config_loading(self):
        """Test loading YAML configuration."""
        config_manager = LoggingConfigManager()

        config_data = {"log_level": "WARNING"}

        with tempfile.NamedTemporaryFile(mode="w", suffix=".yaml", delete=False) as f:
            yaml.dump(config_data, f)
            config_file = f.name

        try:
            config_manager.load_config_file(config_file)
            assert config_manager.config_file == Path(config_file)
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


if __name__ == "__main__":
    pytest.main([__file__])
