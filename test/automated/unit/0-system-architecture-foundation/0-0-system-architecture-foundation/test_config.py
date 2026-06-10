"""
Tests for configuration management.

This module tests the configuration system including loading from files,
environment variables, and validation.
"""

import json
import os
from unittest.mock import patch

import pytest
import yaml

from linkwatcher.config import DEFAULT_CONFIG, TESTING_CONFIG, LinkWatcherConfig

pytestmark = [
    pytest.mark.feature("0.1.3"),
    pytest.mark.priority("Critical"),
    pytest.mark.cross_cutting(["1.1.1", "3.1.1"]),
    pytest.mark.test_type("unit"),
    pytest.mark.specification(
        "test/specifications/feature-specs/test-spec-0-1-3-configuration-system.md"
    ),
]


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

    def test_default_move_detection_timing(self):
        """Test default move detection timing values."""
        config = LinkWatcherConfig()
        assert config.move_detect_delay == 10.0
        assert config.dir_move_max_timeout == 300.0
        assert config.dir_move_settle_delay == 5.0

    def test_custom_move_detection_timing(self):
        """Test custom move detection timing values."""
        config = LinkWatcherConfig(
            move_detect_delay=20.0,
            dir_move_max_timeout=600.0,
            dir_move_settle_delay=10.0,
        )
        assert config.move_detect_delay == 20.0
        assert config.dir_move_max_timeout == 600.0
        assert config.dir_move_settle_delay == 10.0

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
        }

        config = LinkWatcherConfig._from_dict(data)

        assert config.monitored_extensions == {".md", ".txt", ".yaml"}
        assert config.ignored_directories == {".git", "node_modules"}
        assert config.dry_run_mode is True
        assert config.create_backups is False
        assert config.log_level == "DEBUG"
        assert config.max_file_size_mb == 20

    def test_from_dict_warns_on_unknown_keys(self, caplog):
        """Test that _from_dict logs warnings for unknown configuration keys (TD069)."""
        import logging

        data = {
            "dry_run_mode": True,
            "dry_run": True,  # typo — unknown key
            "nonexistent_option": "value",  # unknown key
        }

        with caplog.at_level(logging.WARNING, logger="linkwatcher.config.settings"):
            config = LinkWatcherConfig._from_dict(data)

        # Known key should be applied
        assert config.dry_run_mode is True

        # Unknown keys should each produce a warning
        warnings = [r.message for r in caplog.records if r.levelno == logging.WARNING]
        assert any("dry_run" in w for w in warnings)
        assert any("nonexistent_option" in w for w in warnings)

    def test_from_dict_rejects_dunder_keys(self):
        """Test that _from_dict silently skips underscore-prefixed keys (TD076)."""
        data = {
            "__dict__": {"injected": True},
            "_private": "should be ignored",
            "__class__": "malicious",
            "dry_run_mode": True,  # legitimate key — should still work
        }

        config = LinkWatcherConfig._from_dict(data)

        # Legitimate key applied
        assert config.dry_run_mode is True
        # Dunder/private keys did not modify config internals
        assert not hasattr(config, "_private")
        assert "injected" not in getattr(config, "__dict__", {})

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
            "LINKWATCHER_DRY_RUN_MODE": "true",
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
            "MYAPP_DRY_RUN_MODE": "yes",
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
            env_vars = {"LINKWATCHER_DRY_RUN_MODE": env_value}

            with patch.dict(os.environ, env_vars, clear=True):
                config = LinkWatcherConfig.from_env()
                assert config.dry_run_mode == expected, f"Failed for env_value: {env_value}"

    def test_from_env_invalid_int_falls_back_to_default(self, caplog):
        """Test that non-numeric int env var is ignored with a warning (TE-TAR-020)."""
        import logging

        env_vars = {"LINKWATCHER_MAX_FILE_SIZE_MB": "abc"}

        with caplog.at_level(logging.WARNING, logger="linkwatcher.config.settings"):
            with patch.dict(os.environ, env_vars):
                config = LinkWatcherConfig.from_env()

        # Default preserved
        assert config.max_file_size_mb == 10
        # Warning logged
        warnings = [r.message for r in caplog.records if r.levelno == logging.WARNING]
        assert any("abc" in w and "MAX_FILE_SIZE_MB" in w for w in warnings)

    def test_from_env_invalid_float_falls_back_to_default(self, caplog):
        """Test that non-numeric float env var is ignored with a warning (TE-TAR-020)."""
        import logging

        env_vars = {"LINKWATCHER_MOVE_DETECT_DELAY": "not-a-number"}

        with caplog.at_level(logging.WARNING, logger="linkwatcher.config.settings"):
            with patch.dict(os.environ, env_vars):
                config = LinkWatcherConfig.from_env()

        # Default preserved
        assert config.move_detect_delay == 10.0
        # Warning logged
        warnings = [r.message for r in caplog.records if r.levelno == logging.WARNING]
        assert any("not-a-number" in w and "MOVE_DETECT_DELAY" in w for w in warnings)

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

    def test_save_to_file_is_atomic(self, temp_project_dir):
        """Test that save_to_file uses atomic write (no leftover temp files on success)."""
        config = LinkWatcherConfig(log_level="DEBUG", dry_run_mode=True)
        config_file = temp_project_dir / "atomic_test.json"

        files_before = set(temp_project_dir.iterdir())
        config.save_to_file(str(config_file), format="json")
        files_after = set(temp_project_dir.iterdir())

        # Only the target file should be new — no leftover temp files
        new_files = files_after - files_before
        assert new_files == {config_file}

        # Verify content is valid
        import json

        data = json.loads(config_file.read_text(encoding="utf-8"))
        assert data["log_level"] == "DEBUG"
        assert data["dry_run_mode"] is True

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

    def test_validate_invalid_move_detect_delay(self):
        """Test validation with invalid move_detect_delay."""
        config = LinkWatcherConfig(move_detect_delay=0)
        issues = config.validate()
        assert any("move_detect_delay must be positive" in issue for issue in issues)

    def test_validate_invalid_dir_move_max_timeout(self):
        """Test validation with invalid dir_move_max_timeout."""
        config = LinkWatcherConfig(dir_move_max_timeout=-1)
        issues = config.validate()
        assert any("dir_move_max_timeout must be positive" in issue for issue in issues)

    def test_validate_invalid_dir_move_settle_delay(self):
        """Test validation with invalid dir_move_settle_delay."""
        config = LinkWatcherConfig(dir_move_settle_delay=0)
        issues = config.validate()
        assert any("dir_move_settle_delay must be positive" in issue for issue in issues)

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


class TestMoveDetectionConfigWiring:
    """Test that move detection timing config is wired to handler components."""

    def test_handler_uses_config_move_detect_delay(self, temp_project_dir):
        """Test that handler passes move_detect_delay from config to MoveDetector."""
        from linkwatcher.database import LinkDatabase
        from linkwatcher.handler import LinkMaintenanceHandler
        from linkwatcher.parser import LinkParser
        from linkwatcher.updater import LinkUpdater

        config = LinkWatcherConfig(move_detect_delay=25.0)
        db = LinkDatabase()
        parser = LinkParser()
        updater = LinkUpdater(str(temp_project_dir))
        handler = LinkMaintenanceHandler(db, parser, updater, str(temp_project_dir), config=config)
        assert handler._move_detector._delay == 25.0

    def test_handler_uses_config_dir_move_timeouts(self, temp_project_dir):
        """Test that handler passes dir move timeouts from config to DirectoryMoveDetector."""
        from linkwatcher.database import LinkDatabase
        from linkwatcher.handler import LinkMaintenanceHandler
        from linkwatcher.parser import LinkParser
        from linkwatcher.updater import LinkUpdater

        config = LinkWatcherConfig(dir_move_max_timeout=120.0, dir_move_settle_delay=2.0)
        db = LinkDatabase()
        parser = LinkParser()
        updater = LinkUpdater(str(temp_project_dir))
        handler = LinkMaintenanceHandler(db, parser, updater, str(temp_project_dir), config=config)
        assert handler._dir_move_detector._max_timeout == 120.0
        assert handler._dir_move_detector._settle_delay == 2.0

    def test_handler_uses_defaults_without_config(self, temp_project_dir):
        """Test that handler uses DEFAULT_CONFIG values when no config provided."""
        from linkwatcher.database import LinkDatabase
        from linkwatcher.handler import LinkMaintenanceHandler
        from linkwatcher.parser import LinkParser
        from linkwatcher.updater import LinkUpdater

        db = LinkDatabase()
        parser = LinkParser()
        updater = LinkUpdater(str(temp_project_dir))
        handler = LinkMaintenanceHandler(db, parser, updater, str(temp_project_dir))
        assert handler._move_detector._delay == 10.0
        assert handler._dir_move_detector._max_timeout == 300.0
        assert handler._dir_move_detector._settle_delay == 5.0

    def test_move_detection_timing_roundtrip_json(self, temp_project_dir):
        """Test that move detection timing survives JSON save/load roundtrip."""
        config = LinkWatcherConfig(
            move_detect_delay=15.0,
            dir_move_max_timeout=600.0,
            dir_move_settle_delay=8.0,
        )
        config_file = temp_project_dir / "timing_config.json"
        config.save_to_file(str(config_file), format="json")
        loaded = LinkWatcherConfig.from_file(str(config_file))
        assert loaded.move_detect_delay == 15.0
        assert loaded.dir_move_max_timeout == 600.0
        assert loaded.dir_move_settle_delay == 8.0

    def test_move_detection_timing_roundtrip_yaml(self, temp_project_dir):
        """Test that move detection timing survives YAML save/load roundtrip."""
        config = LinkWatcherConfig(
            move_detect_delay=20.0,
            dir_move_max_timeout=500.0,
            dir_move_settle_delay=3.0,
        )
        config_file = temp_project_dir / "timing_config.yaml"
        config.save_to_file(str(config_file), format="yaml")
        loaded = LinkWatcherConfig.from_file(str(config_file))
        assert loaded.move_detect_delay == 20.0
        assert loaded.dir_move_max_timeout == 500.0
        assert loaded.dir_move_settle_delay == 3.0


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

    def test_default_config_includes_bat_extension(self):
        """Regression test for PD-BUG-058: .bat files must be monitored by default."""
        assert ".bat" in DEFAULT_CONFIG.monitored_extensions, (
            ".bat not in DEFAULT_CONFIG.monitored_extensions — "
            "dev.bat contains file paths that need link maintenance"
        )

    def test_default_config_includes_toml_extension(self):
        """Regression test for PD-BUG-058: .toml files must be monitored by default."""
        assert ".toml" in DEFAULT_CONFIG.monitored_extensions, (
            ".toml not in DEFAULT_CONFIG.monitored_extensions — "
            "pyproject.toml contains file paths that need link maintenance"
        )

    def test_dataclass_default_includes_bat_extension(self):
        """Regression test for PD-BUG-058: .bat in dataclass default_factory."""
        config = LinkWatcherConfig()
        assert ".bat" in config.monitored_extensions

    def test_dataclass_default_includes_toml_extension(self):
        """Regression test for PD-BUG-058: .toml in dataclass default_factory."""
        config = LinkWatcherConfig()
        assert ".toml" in config.monitored_extensions

    def test_configs_are_independent(self):
        """Test that config instances are independent."""
        # Work on a copy to avoid polluting the singleton if this test fails
        default_copy = DEFAULT_CONFIG.monitored_extensions.copy()
        default_copy.add(".test")

        # The original DEFAULT_CONFIG and TESTING_CONFIG must be unaffected
        assert ".test" not in DEFAULT_CONFIG.monitored_extensions
        assert ".test" not in TESTING_CONFIG.monitored_extensions

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
            "LINKWATCHER_DRY_RUN_MODE": "true",
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

    def test_malformed_json_handling(self, temp_project_dir):
        """Test handling of malformed JSON configuration."""
        malformed_json = '{"monitored_extensions": [".md", ".txt",}'  # Missing closing bracket

        config_file = temp_project_dir / "malformed.json"
        config_file.write_text(malformed_json)

        with pytest.raises(json.JSONDecodeError):
            LinkWatcherConfig.from_file(str(config_file))

    def test_validation_ignored_patterns_default(self):
        """Test that validation_ignored_patterns has a sensible default."""
        config = LinkWatcherConfig()
        assert isinstance(config.validation_ignored_patterns, set)
        assert "path/to/" in config.validation_ignored_patterns
        assert "xxx" in config.validation_ignored_patterns

    def test_validation_ignored_patterns_from_dict(self):
        """Test loading validation_ignored_patterns from dict."""
        data = {"validation_ignored_patterns": ["example/", "templates/"]}
        config = LinkWatcherConfig._from_dict(data)
        assert config.validation_ignored_patterns == {"example/", "templates/"}

    def test_validation_ignored_patterns_from_yaml(self, temp_project_dir):
        """Test loading validation_ignored_patterns from YAML config file."""
        config_data = {
            "validation_ignored_patterns": ["custom/pattern/", "another/"],
            "log_level": "INFO",
        }
        config_file = temp_project_dir / "patterns.yaml"
        config_file.write_text(yaml.dump(config_data))

        config = LinkWatcherConfig.from_file(str(config_file))
        assert config.validation_ignored_patterns == {"custom/pattern/", "another/"}

    def test_validation_ignored_patterns_roundtrip(self, temp_project_dir):
        """Test validation_ignored_patterns survives save/load roundtrip."""
        config = LinkWatcherConfig(validation_ignored_patterns={"foo/", "bar/baz/"})
        config_file = temp_project_dir / "roundtrip_patterns.json"
        config.save_to_file(str(config_file), format="json")
        loaded = LinkWatcherConfig.from_file(str(config_file))
        assert loaded.validation_ignored_patterns == {"foo/", "bar/baz/"}

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
