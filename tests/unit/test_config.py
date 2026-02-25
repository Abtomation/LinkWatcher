"""
Tests for configuration management.

This module tests the configuration system including loading from files,
environment variables, and validation.
"""

import json
import os
import tempfile
from pathlib import Path
from unittest.mock import mock_open, patch

import pytest
import yaml

from linkwatcher.config import DEFAULT_CONFIG, TESTING_CONFIG, LinkWatcherConfig
from linkwatcher.config.settings import LinkWatcherConfig as ConfigClass


class TestLinkWatcherConfig:
    """Test cases for LinkWatcherConfig class."""

    def test_default_initialization(self):
        """Test default configuration initialization."""
        config = LinkWatcherConfig()

        # Check default values
        assert ".md" in config.monitored_extensions
        assert ".yaml" in config.monitored_extensions
        assert ".json" in config.monitored_extensions
        assert ".py" in config.monitored_extensions

        assert ".git" in config.ignored_directories
        assert "node_modules" in config.ignored_directories
        assert "__pycache__" in config.ignored_directories

        assert config.create_backups is False
        assert config.dry_run_mode is False
        assert config.atomic_updates is True
        assert config.log_level == "INFO"
        assert config.max_file_size_mb == 10

    def test_custom_initialization(self):
        """Test configuration with custom values."""
        config = LinkWatcherConfig(
            monitored_extensions={".md", ".txt"},
            ignored_directories={".git"},
            dry_run_mode=True,
            log_level="DEBUG",
            max_file_size_mb=5,
        )

        assert config.monitored_extensions == {".md", ".txt"}
        assert config.ignored_directories == {".git"}
        assert config.dry_run_mode is True
        assert config.log_level == "DEBUG"
        assert config.max_file_size_mb == 5

    def test_from_dict(self):
        """Test creating configuration from dictionary."""
        data = {
            "monitored_extensions": [".md", ".txt", ".yaml"],
            "ignored_directories": [".git", "node_modules"],
            "dry_run_mode": True,
            "create_backups": False,
            "log_level": "DEBUG",
            "max_file_size_mb": 20,
            "exclude_patterns": ["*.tmp", "*.bak"],
            "include_patterns": ["important.*"],
        }

        config = LinkWatcherConfig._from_dict(data)

        assert config.monitored_extensions == {".md", ".txt", ".yaml"}
        assert config.ignored_directories == {".git", "node_modules"}
        assert config.dry_run_mode is True
        assert config.create_backups is False
        assert config.log_level == "DEBUG"
        assert config.max_file_size_mb == 20
        assert config.exclude_patterns == {"*.tmp", "*.bak"}
        assert config.include_patterns == {"important.*"}

    def test_to_dict(self):
        """Test converting configuration to dictionary."""
        config = LinkWatcherConfig(
            monitored_extensions={".md", ".txt"},
            ignored_directories={".git"},
            dry_run_mode=True,
            log_level="DEBUG",
        )

        data = config.to_dict()

        # Sets should be converted to lists
        assert isinstance(data["monitored_extensions"], list)
        assert set(data["monitored_extensions"]) == {".md", ".txt"}
        assert isinstance(data["ignored_directories"], list)
        assert set(data["ignored_directories"]) == {".git"}

        # Other values should be preserved
        assert data["dry_run_mode"] is True
        assert data["log_level"] == "DEBUG"

    def test_from_json_file(self, temp_project_dir):
        """Test loading configuration from JSON file."""
        config_data = {
            "monitored_extensions": [".md", ".txt"],
            "ignored_directories": [".git", "node_modules"],
            "dry_run_mode": True,
            "log_level": "DEBUG",
            "max_file_size_mb": 15,
        }

        config_file = temp_project_dir / "config.json"
        config_file.write_text(json.dumps(config_data, indent=2))

        config = LinkWatcherConfig.from_file(str(config_file))

        assert config.monitored_extensions == {".md", ".txt"}
        assert config.ignored_directories == {".git", "node_modules"}
        assert config.dry_run_mode is True
        assert config.log_level == "DEBUG"
        assert config.max_file_size_mb == 15

    def test_from_yaml_file(self, temp_project_dir):
        """Test loading configuration from YAML file."""
        config_data = {
            "monitored_extensions": [".md", ".yaml", ".json"],
            "ignored_directories": [".git", ".vscode"],
            "create_backups": False,
            "log_level": "WARNING",
            "colored_output": False,
        }

        config_file = temp_project_dir / "config.yaml"
        config_file.write_text(yaml.dump(config_data))

        config = LinkWatcherConfig.from_file(str(config_file))

        assert config.monitored_extensions == {".md", ".yaml", ".json"}
        assert config.ignored_directories == {".git", ".vscode"}
        assert config.create_backups is False
        assert config.log_level == "WARNING"
        assert config.colored_output is False

    def test_from_yml_file(self, temp_project_dir):
        """Test loading configuration from .yml file."""
        config_data = {"monitored_extensions": [".py", ".dart"], "dry_run_mode": True}

        config_file = temp_project_dir / "config.yml"
        config_file.write_text(yaml.dump(config_data))

        config = LinkWatcherConfig.from_file(str(config_file))

        assert config.monitored_extensions == {".py", ".dart"}
        assert config.dry_run_mode is True

    def test_from_file_not_found(self):
        """Test loading from non-existent file."""
        with pytest.raises(FileNotFoundError):
            LinkWatcherConfig.from_file("nonexistent.json")

    def test_from_file_unsupported_format(self, temp_project_dir):
        """Test loading from unsupported file format."""
        config_file = temp_project_dir / "config.ini"
        config_file.write_text("[section]\nkey=value")

        with pytest.raises(ValueError, match="Unsupported configuration file format"):
            LinkWatcherConfig.from_file(str(config_file))

    def test_from_env_basic(self):
        """Test loading configuration from environment variables."""
        env_vars = {
            "LINKWATCHER_MONITORED_EXTENSIONS": ".md,.txt,.yaml",
            "LINKWATCHER_IGNORED_DIRECTORIES": ".git,node_modules",
            "LINKWATCHER_DRY_RUN": "true",
            "LINKWATCHER_CREATE_BACKUPS": "false",
            "LINKWATCHER_LOG_LEVEL": "DEBUG",
            "LINKWATCHER_MAX_FILE_SIZE_MB": "25",
            "LINKWATCHER_COLORED_OUTPUT": "1",
        }

        with patch.dict(os.environ, env_vars):
            config = LinkWatcherConfig.from_env()

        assert config.monitored_extensions == {".md", ".txt", ".yaml"}
        assert config.ignored_directories == {".git", "node_modules"}
        assert config.dry_run_mode is True
        assert config.create_backups is False
        assert config.log_level == "DEBUG"
        assert config.max_file_size_mb == 25
        assert config.colored_output is True

    def test_from_env_custom_prefix(self):
        """Test loading from environment with custom prefix."""
        env_vars = {
            "MYAPP_MONITORED_EXTENSIONS": ".md,.py",
            "MYAPP_DRY_RUN": "yes",
            "MYAPP_LOG_LEVEL": "ERROR",
        }

        with patch.dict(os.environ, env_vars):
            config = LinkWatcherConfig.from_env(prefix="MYAPP_")

        assert config.monitored_extensions == {".md", ".py"}
        assert config.dry_run_mode is True
        assert config.log_level == "ERROR"

    def test_from_env_boolean_variations(self):
        """Test various boolean value formats from environment."""
        boolean_tests = [
            ("true", True),
            ("True", True),
            ("TRUE", True),
            ("1", True),
            ("yes", True),
            ("on", True),
            ("false", False),
            ("False", False),
            ("FALSE", False),
            ("0", False),
            ("no", False),
            ("off", False),
            ("invalid", False),  # Invalid values default to False
        ]

        for env_value, expected in boolean_tests:
            env_vars = {"LINKWATCHER_DRY_RUN": env_value}

            with patch.dict(os.environ, env_vars, clear=True):
                config = LinkWatcherConfig.from_env()
                assert config.dry_run_mode == expected, f"Failed for env_value: {env_value}"

    def test_save_to_json_file(self, temp_project_dir):
        """Test saving configuration to JSON file."""
        config = LinkWatcherConfig(
            monitored_extensions={".md", ".txt"}, dry_run_mode=True, log_level="DEBUG"
        )

        config_file = temp_project_dir / "saved_config.json"
        config.save_to_file(str(config_file), format="json")

        # Verify file was created and contains correct data
        assert config_file.exists()

        with open(config_file, "r") as f:
            data = json.load(f)

        assert set(data["monitored_extensions"]) == {".md", ".txt"}
        assert data["dry_run_mode"] is True
        assert data["log_level"] == "DEBUG"

    def test_save_to_yaml_file(self, temp_project_dir):
        """Test saving configuration to YAML file."""
        config = LinkWatcherConfig(
            monitored_extensions={".py", ".dart"}, create_backups=False, max_file_size_mb=20
        )

        config_file = temp_project_dir / "saved_config.yaml"
        config.save_to_file(str(config_file), format="yaml")

        # Verify file was created and contains correct data
        assert config_file.exists()

        with open(config_file, "r") as f:
            data = yaml.safe_load(f)

        assert set(data["monitored_extensions"]) == {".py", ".dart"}
        assert data["create_backups"] is False
        assert data["max_file_size_mb"] == 20

    def test_save_unsupported_format(self, temp_project_dir):
        """Test saving to unsupported format."""
        config = LinkWatcherConfig()
        config_file = temp_project_dir / "config.ini"

        with pytest.raises(ValueError, match="Unsupported format"):
            config.save_to_file(str(config_file), format="ini")

    def test_merge_configurations(self):
        """Test merging two configurations."""
        config1 = LinkWatcherConfig(
            monitored_extensions={".md", ".txt"}, dry_run_mode=True, log_level="DEBUG"
        )

        config2 = LinkWatcherConfig(
            monitored_extensions={".py", ".yaml"}, create_backups=False, max_file_size_mb=20
        )

        merged = config1.merge(config2)

        # config2 values should override config1
        assert merged.monitored_extensions == {".py", ".yaml"}
        assert merged.create_backups is False
        assert merged.max_file_size_mb == 20

        # config1 values should be preserved where not overridden
        assert merged.dry_run_mode is True
        assert merged.log_level == "DEBUG"

    def test_validate_valid_config(self):
        """Test validation of valid configuration."""
        config = LinkWatcherConfig(
            max_file_size_mb=10,
            log_level="INFO",
            monitored_extensions={".md", ".txt"},
            scan_progress_interval=50,
        )

        issues = config.validate()
        assert issues == []

    def test_validate_invalid_file_size(self):
        """Test validation with invalid file size."""
        config = LinkWatcherConfig(max_file_size_mb=0)

        issues = config.validate()
        assert any("max_file_size_mb must be positive" in issue for issue in issues)

    def test_validate_invalid_log_level(self):
        """Test validation with invalid log level."""
        config = LinkWatcherConfig(log_level="INVALID")

        issues = config.validate()
        assert any("log_level must be one of" in issue for issue in issues)

    def test_validate_invalid_extensions(self):
        """Test validation with invalid extensions."""
        config = LinkWatcherConfig(monitored_extensions={"md", "txt"})  # Missing dots

        issues = config.validate()
        assert any("should start with a dot" in issue for issue in issues)

    def test_validate_invalid_scan_interval(self):
        """Test validation with invalid scan interval."""
        config = LinkWatcherConfig(scan_progress_interval=0)

        issues = config.validate()
        assert any("scan_progress_interval must be positive" in issue for issue in issues)

    def test_validate_multiple_issues(self):
        """Test validation with multiple issues."""
        config = LinkWatcherConfig(
            max_file_size_mb=-5,
            log_level="INVALID",
            monitored_extensions={"md"},
            scan_progress_interval=-10,
        )

        issues = config.validate()
        assert len(issues) >= 4  # Should find multiple issues


class TestDefaultConfigurations:
    """Test cases for default configuration instances."""

    def test_default_config_exists(self):
        """Test that DEFAULT_CONFIG is properly defined."""
        assert DEFAULT_CONFIG is not None
        assert isinstance(DEFAULT_CONFIG, LinkWatcherConfig)

        # Check some expected defaults
        assert ".md" in DEFAULT_CONFIG.monitored_extensions
        assert ".git" in DEFAULT_CONFIG.ignored_directories
        assert DEFAULT_CONFIG.create_backups is False
        assert DEFAULT_CONFIG.log_level == "INFO"

    def test_testing_config_exists(self):
        """Test that TESTING_CONFIG is properly defined."""
        assert TESTING_CONFIG is not None
        assert isinstance(TESTING_CONFIG, LinkWatcherConfig)

        # Check testing-specific settings
        assert TESTING_CONFIG.dry_run_mode is True
        assert TESTING_CONFIG.log_level == "DEBUG"
        assert TESTING_CONFIG.show_statistics is False
        assert TESTING_CONFIG.colored_output is False

    def test_configs_are_independent(self):
        """Test that config instances are independent."""
        # Modify one config
        original_extensions = DEFAULT_CONFIG.monitored_extensions.copy()
        DEFAULT_CONFIG.monitored_extensions.add(".test")

        # Other config should not be affected
        assert ".test" not in TESTING_CONFIG.monitored_extensions

        # Restore original state
        DEFAULT_CONFIG.monitored_extensions = original_extensions

    def test_config_validation(self):
        """Test that default configs are valid."""
        default_issues = DEFAULT_CONFIG.validate()
        assert default_issues == [], f"DEFAULT_CONFIG has validation issues: {default_issues}"

        testing_issues = TESTING_CONFIG.validate()
        assert testing_issues == [], f"TESTING_CONFIG has validation issues: {testing_issues}"


class TestConfigurationIntegration:
    """Integration tests for configuration system."""

    def test_config_file_roundtrip_json(self, temp_project_dir):
        """Test saving and loading JSON configuration."""
        original_config = LinkWatcherConfig(
            monitored_extensions={".md", ".py", ".dart"},
            ignored_directories={".git", ".vscode", "build"},
            dry_run_mode=True,
            create_backups=False,
            log_level="DEBUG",
            max_file_size_mb=25,
            exclude_patterns={"*.tmp", "*.bak"},
            include_patterns={"important.*"},
        )

        config_file = temp_project_dir / "roundtrip.json"

        # Save configuration
        original_config.save_to_file(str(config_file), format="json")

        # Load configuration
        loaded_config = LinkWatcherConfig.from_file(str(config_file))

        # Compare configurations
        assert loaded_config.monitored_extensions == original_config.monitored_extensions
        assert loaded_config.ignored_directories == original_config.ignored_directories
        assert loaded_config.dry_run_mode == original_config.dry_run_mode
        assert loaded_config.create_backups == original_config.create_backups
        assert loaded_config.log_level == original_config.log_level
        assert loaded_config.max_file_size_mb == original_config.max_file_size_mb
        assert loaded_config.exclude_patterns == original_config.exclude_patterns
        assert loaded_config.include_patterns == original_config.include_patterns

    def test_config_file_roundtrip_yaml(self, temp_project_dir):
        """Test saving and loading YAML configuration."""
        original_config = LinkWatcherConfig(
            monitored_extensions={".yaml", ".json"},
            dry_run_mode=False,
            colored_output=True,
            show_statistics=True,
        )

        config_file = temp_project_dir / "roundtrip.yaml"

        # Save configuration
        original_config.save_to_file(str(config_file), format="yaml")

        # Load configuration
        loaded_config = LinkWatcherConfig.from_file(str(config_file))

        # Compare configurations
        assert loaded_config.monitored_extensions == original_config.monitored_extensions
        assert loaded_config.dry_run_mode == original_config.dry_run_mode
        assert loaded_config.colored_output == original_config.colored_output
        assert loaded_config.show_statistics == original_config.show_statistics

    def test_env_override_file_config(self, temp_project_dir):
        """Test that environment variables can override file configuration."""
        # Create file configuration
        file_config_data = {
            "monitored_extensions": [".md"],
            "dry_run_mode": False,
            "log_level": "INFO",
        }

        config_file = temp_project_dir / "base_config.json"
        config_file.write_text(json.dumps(file_config_data))

        # Load base configuration
        base_config = LinkWatcherConfig.from_file(str(config_file))

        # Override with environment variables
        env_vars = {
            "LINKWATCHER_MONITORED_EXTENSIONS": ".md,.py,.yaml",
            "LINKWATCHER_DRY_RUN": "true",
            "LINKWATCHER_LOG_LEVEL": "DEBUG",
        }

        with patch.dict(os.environ, env_vars):
            env_config = LinkWatcherConfig.from_env()

        # Merge configurations (env overrides file)
        final_config = base_config.merge(env_config)

        assert final_config.monitored_extensions == {".md", ".py", ".yaml"}
        assert final_config.dry_run_mode is True
        assert final_config.log_level == "DEBUG"

    def test_partial_config_loading(self, temp_project_dir):
        """Test loading partial configuration (not all fields specified)."""
        partial_config_data = {
            "monitored_extensions": [".md", ".txt"],
            "log_level": "WARNING"
            # Other fields should use defaults
        }

        config_file = temp_project_dir / "partial_config.json"
        config_file.write_text(json.dumps(partial_config_data))

        config = LinkWatcherConfig.from_file(str(config_file))

        # Specified fields should be set
        assert config.monitored_extensions == {".md", ".txt"}
        assert config.log_level == "WARNING"

        # Unspecified fields should use defaults
        assert config.create_backups is False  # Default value
        assert config.dry_run_mode is False  # Default value
        assert config.max_file_size_mb == 10  # Default value

    def test_config_with_custom_parsers(self, temp_project_dir):
        """Test configuration with custom parsers."""
        config_data = {
            "custom_parsers": {".custom": "my_custom_parser", ".special": "another_parser"},
            "monitored_extensions": [".md", ".custom", ".special"],
        }

        config_file = temp_project_dir / "custom_parsers.json"
        config_file.write_text(json.dumps(config_data))

        config = LinkWatcherConfig.from_file(str(config_file))

        assert config.custom_parsers == {
            ".custom": "my_custom_parser",
            ".special": "another_parser",
        }
        assert config.monitored_extensions == {".md", ".custom", ".special"}

    def test_malformed_json_handling(self, temp_project_dir):
        """Test handling of malformed JSON configuration."""
        malformed_json = '{"monitored_extensions": [".md", ".txt",}'  # Missing closing bracket

        config_file = temp_project_dir / "malformed.json"
        config_file.write_text(malformed_json)

        with pytest.raises(json.JSONDecodeError):
            LinkWatcherConfig.from_file(str(config_file))

    def test_malformed_yaml_handling(self, temp_project_dir):
        """Test handling of malformed YAML configuration."""
        malformed_yaml = """
monitored_extensions:
  - .md
  - .txt
invalid_yaml: [unclosed list
"""

        config_file = temp_project_dir / "malformed.yaml"
        config_file.write_text(malformed_yaml)

        with pytest.raises(yaml.YAMLError):
            LinkWatcherConfig.from_file(str(config_file))
