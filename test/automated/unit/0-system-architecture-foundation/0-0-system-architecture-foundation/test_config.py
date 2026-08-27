"""
Tests for configuration management.

This module tests the configuration system including loading from files,
environment variables, and validation.
"""

import dataclasses
import json
import os
import typing
from unittest.mock import patch

import pytest
import yaml

from linkwatcher.config import DEFAULT_CONFIG, TESTING_CONFIG, LinkWatcherConfig


def _schema_fields_of_type(*wanted):
    """Field names whose declared type is one of `wanted`, read from the dataclass.

    Derived here independently of the production helper on purpose: a test that
    asked `settings.py` which fields it validates could only ever confirm the
    module agrees with itself. Reading the schema directly is what makes the
    coverage assertions in `TestBug127NumericValidationDerivesFromSchema` able
    to fail (PD-BUG-127).
    """
    hints = typing.get_type_hints(LinkWatcherConfig)
    return [f.name for f in dataclasses.fields(LinkWatcherConfig) if hints.get(f.name) in wanted]


def _schema_fields_of_type_set_of_str():
    """Field names declared as `Set[str]`, read from the dataclass (TD275)."""
    hints = typing.get_type_hints(LinkWatcherConfig)
    return [
        f.name
        for f in dataclasses.fields(LinkWatcherConfig)
        if hints.get(f.name) in (typing.Set[str], set)
    ]


# The extension-bearing fields as of this bug, named outright. Read as a floor,
# not as the coverage rule: `_schema_fields_holding_extensions` derives the set
# so a field added later is picked up, and this list is what makes the derived
# set falsifiable if that derivation is ever narrowed (PD-BUG-129).
_KNOWN_EXTENSION_FIELDS = (
    "monitored_extensions",
    "validation_extensions",
    "parser_type_extensions",
)


def _schema_fields_holding_extensions():
    """Field names that hold file extensions, read from the dataclass.

    Derived by the `_extensions` naming suffix every such field already uses.
    Kept here rather than imported from `settings.py` for the reason given in
    `_schema_fields_of_type` — a test that asks the module which fields it
    checks can only confirm the module agrees with itself.
    """
    return [f.name for f in dataclasses.fields(LinkWatcherConfig) if f.name.endswith("_extensions")]


def _dotless_value_for(name):
    """A dotless value shaped to the field's declared type.

    `Set[str]` fields hold extensions directly; `parser_type_extensions` is a
    `Dict[str, str]` whose *values* are the extensions.
    """
    hints = typing.get_type_hints(LinkWatcherConfig)
    if hints.get(name) in (typing.Set[str], set):
        return {"md"}
    return {"python": "py"}


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

    def test_handler_normalizes_configured_extension_case(self, temp_project_dir):
        """PD-BUG-129 sibling site: `_handle_directory_moved` tests membership
        against this set directly instead of going through
        `should_monitor_file`, so an unnormalized `.MD` entry matched no file
        in the directory-move path. Normalizing once at the boundary is what
        makes that comparison correct — and `add_extension` already lowercases
        on that assumption.
        """
        from linkwatcher.database import LinkDatabase
        from linkwatcher.handler import LinkMaintenanceHandler
        from linkwatcher.parser import LinkParser
        from linkwatcher.updater import LinkUpdater

        config = LinkWatcherConfig(monitored_extensions={".MD", ".Yaml"})
        handler = LinkMaintenanceHandler(
            LinkDatabase(),
            LinkParser(),
            LinkUpdater(str(temp_project_dir)),
            str(temp_project_dir),
            # The service wires the config value in through this parameter
            # (service.py), so that is the boundary under test here.
            monitored_extensions=config.monitored_extensions,
            config=config,
        )

        assert handler.monitored_extensions == {".md", ".yaml"}

    def test_handler_does_not_alias_the_default_extension_set(self, temp_project_dir):
        """`add_extension` mutates this set, so it must never be the shared
        DEFAULT_CONFIG set (the `.copy()` the normalization replaced).
        """
        from linkwatcher.database import LinkDatabase
        from linkwatcher.handler import LinkMaintenanceHandler
        from linkwatcher.parser import LinkParser
        from linkwatcher.updater import LinkUpdater

        handler = LinkMaintenanceHandler(
            LinkDatabase(),
            LinkParser(),
            LinkUpdater(str(temp_project_dir)),
            str(temp_project_dir),
        )
        handler.monitored_extensions.add(".sentinel")

        assert ".sentinel" not in DEFAULT_CONFIG.monitored_extensions

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

    def test_default_config_equals_dataclass_defaults(self):
        """Regression guard for PD-BUG-103 root cause: DEFAULT_CONFIG and the
        LinkWatcherConfig dataclass defaults were two independently-maintained
        default sources that diverged (ignored_directories, monitored_extensions).
        The dataclass is the single source of truth; DEFAULT_CONFIG must not
        re-declare different values for any field."""
        import dataclasses

        dataclass_defaults = LinkWatcherConfig()
        diverged = [
            f.name
            for f in dataclasses.fields(LinkWatcherConfig)
            if getattr(DEFAULT_CONFIG, f.name) != getattr(dataclass_defaults, f.name)
        ]
        assert not diverged, (
            "DEFAULT_CONFIG diverged from LinkWatcherConfig dataclass defaults "
            f"on fields: {diverged} — defaults must have a single source of truth "
            "(PD-BUG-103)"
        )

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
            "log_level": "WARNING",
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


class TestBug123TypeInvalidValuesAreReported:
    """PD-BUG-123 regression: `validate()` raised on a type-invalid value
    instead of reporting it as an issue.

    `validate()`'s contract is to *return* a list of issues, so every caller
    reasonably treats it as non-raising. It performed type-dependent operations
    — `.upper()`, `<= 0`, iteration — directly on values that arrived
    unvalidated from YAML, so a well-formed config carrying a wrongly typed
    value raised out of the loader instead of appearing in the list.

    The daemon calls `validate()` at `main.py:453` inside a broad
    `except Exception`, which turns a precise per-key `config_issue` report into
    one generic `fatal_error` with a raw Python message — the operator is never
    told which key is wrong. `_from_dict`'s unguarded `set(value)` is the same
    defect one layer earlier: it failed before `validate()` was ever reached.

    Contract pinned here: a type-invalid value is *reported*, naming the key —
    never raised, from either `_from_dict` or `validate()`.
    """

    # ---- the four reported variants ------------------------------------

    def test_non_string_log_level_is_reported(self):
        config = LinkWatcherConfig(log_level=5)

        issues = config.validate()

        assert any("log_level" in issue for issue in issues), issues

    def test_non_numeric_file_size_is_reported(self):
        config = LinkWatcherConfig(max_file_size_mb="big")

        issues = config.validate()

        assert any("max_file_size_mb" in issue for issue in issues), issues

    def test_non_numeric_move_detect_delay_is_reported(self):
        config = LinkWatcherConfig(move_detect_delay="x")

        issues = config.validate()

        assert any("move_detect_delay" in issue for issue in issues), issues

    def test_non_iterable_extensions_survive_loading_and_are_reported(self, tmp_path):
        """The loader must not raise before `validate()` is reached.

        `monitored_extensions: 7` hit `set(value)` in `_from_dict`, so the
        failure happened during `from_file` — earlier than the function whose
        job is to report it.
        """
        cfg = tmp_path / "cfg.yaml"
        cfg.write_text("monitored_extensions: 7\n", encoding="utf-8")

        config = LinkWatcherConfig.from_file(str(cfg))  # raised TypeError pre-fix
        issues = config.validate()

        assert any("monitored_extensions" in issue for issue in issues), issues

    # ---- every numeric field, not just the two reported ------------------

    @pytest.mark.parametrize(
        "field",
        [
            "max_file_size_mb",
            "scan_progress_interval",
            "move_detect_delay",
            "dir_move_max_timeout",
            "dir_move_settle_delay",
        ],
    )
    def test_every_numeric_field_reports_a_string(self, field):
        config = LinkWatcherConfig(**{field: "not-a-number"})

        issues = config.validate()

        assert any(field in issue for issue in issues), issues

    def test_boolean_is_not_accepted_as_a_number(self):
        """`bool` is a subclass of `int`, so `True <= 0` is False and the value
        sailed through as a silent size of 1 rather than being reported.
        """
        config = LinkWatcherConfig(max_file_size_mb=True)

        issues = config.validate()

        assert any("max_file_size_mb" in issue for issue in issues), issues

    # ---- every Set[str] field, not just monitored_extensions -------------

    @pytest.mark.parametrize(
        "field",
        [
            "monitored_extensions",
            "ignored_directories",
            "validation_extensions",
            "validation_extra_ignored_dirs",
            "validation_ignored_patterns",
        ],
    )
    def test_every_set_field_reports_a_non_iterable(self, field, tmp_path):
        """Loader tolerance must be matched by validation coverage.

        Making `_from_dict` tolerant means a bad value now survives loading, so
        a field `validate()` does not check would trade a loud load-time failure
        for a later, more confusing runtime one.
        """
        cfg = tmp_path / "cfg.yaml"
        cfg.write_text("%s: 7\n" % field, encoding="utf-8")

        config = LinkWatcherConfig.from_file(str(cfg))
        issues = config.validate()

        assert any(field in issue for issue in issues), issues

    def test_bare_string_set_value_is_reported_not_split_into_characters(self, tmp_path):
        """`monitored_extensions: ".md"` became `{'.', 'm', 'd'}` — three
        nonsense extensions from one plausible operator mistake.
        """
        cfg = tmp_path / "cfg.yaml"
        cfg.write_text('monitored_extensions: ".md"\n', encoding="utf-8")

        config = LinkWatcherConfig.from_file(str(cfg))
        issues = config.validate()

        assert any("monitored_extensions" in issue for issue in issues), issues
        assert not any(
            "'m'" in issue or "'d'" in issue for issue in issues
        ), "string was split into per-character extensions: {!r}".format(issues)

    def test_non_string_extension_member_is_reported(self):
        config = LinkWatcherConfig(monitored_extensions={7})

        issues = config.validate()

        assert any("monitored_extensions" in issue for issue in issues), issues

    # ---- controls: the discriminating condition --------------------------
    #
    # The risk in this fix is breaking validation that already works, so these
    # must be green BEFORE and AFTER. They are the reason the type guards can
    # be trusted not to have swallowed the semantic checks.

    def test_control_valid_config_still_reports_nothing(self):
        config = LinkWatcherConfig(
            max_file_size_mb=10,
            log_level="INFO",
            monitored_extensions={".md", ".txt"},
            scan_progress_interval=50,
        )

        assert config.validate() == []

    def test_control_existing_semantic_messages_are_unchanged(self):
        """Byte-identical messages — the existing suite matches on these."""
        config = LinkWatcherConfig(
            max_file_size_mb=-5,
            log_level="INVALID",
            monitored_extensions={"md"},
            scan_progress_interval=-10,
            move_detect_delay=0,
            dir_move_max_timeout=-1,
            dir_move_settle_delay=0,
        )

        issues = config.validate()

        assert "max_file_size_mb must be positive" in issues
        assert "scan_progress_interval must be positive" in issues
        assert "move_detect_delay must be positive" in issues
        assert "dir_move_max_timeout must be positive" in issues
        assert "dir_move_settle_delay must be positive" in issues
        assert any("log_level must be one of" in issue for issue in issues)
        assert any("should start with a dot" in issue for issue in issues)

    def test_control_float_values_remain_valid(self):
        """The bool exclusion must not reject legitimate floats."""
        config = LinkWatcherConfig(move_detect_delay=2.5, dir_move_settle_delay=0.5)

        issues = config.validate()

        assert not any("move_detect_delay" in issue for issue in issues), issues
        assert not any("dir_move_settle_delay" in issue for issue in issues), issues

    def test_control_list_valued_set_field_still_coerces(self, tmp_path):
        """A YAML list is the normal authoring form and must still become a set."""
        cfg = tmp_path / "cfg.yaml"
        cfg.write_text('monitored_extensions: [".md", ".txt"]\n', encoding="utf-8")

        config = LinkWatcherConfig.from_file(str(cfg))

        assert config.monitored_extensions == {".md", ".txt"}
        assert config.validate() == []


class TestBug127NumericValidationDerivesFromSchema:
    """PD-BUG-127: `validate()` checked a hardcoded list of five numeric field
    names while the dataclass declared seven, so `log_file_max_size_mb` and
    `log_file_backup_count` were never type-checked.

    Both are consumed by `main._apply_logging_config` *before* `validate()`
    runs, so a wrongly typed value produced one of three outcomes, all measured:

    - `log_file_max_size_mb: big` — `TypeError` in the `RotatingFileHandler`
      constructor (`if maxBytes > 0`), which reaches `main()`'s broad
      `except Exception` as a generic `fatal_error` naming no key.
    - `log_file_max_size_mb: true` — silently accepted as 1 MB, because `bool`
      is a subclass of `int` (the trap `_is_number` exists for, on a field that
      never reached it).
    - `log_file_backup_count: x` / `3.5` — survives startup and fails at the
      first rollover, inside the stdlib `emit` handler that swallows it: the
      triggering record is lost and rotated logs are never pruned, so the log
      directory grows without bound.

    Contract pinned here: the *field set* and the int-vs-number rule are both
    derived from the dataclass type hints, so a numeric field added later
    cannot be silently left unvalidated. The hardcoded-list predecessor of this
    class asserted "every numeric field" over a list that was itself copied
    from `validate()`'s coverage — it could never have caught this gap.
    """

    # ---- the reported variants -------------------------------------------

    def test_rotation_size_reports_a_string(self):
        config = LinkWatcherConfig(log_file_max_size_mb="big")

        issues = config.validate()

        assert any("log_file_max_size_mb" in issue for issue in issues), issues

    def test_rotation_size_reports_a_bool(self):
        """`True * 1024 * 1024` is 1 MB — accepted silently pre-fix."""
        config = LinkWatcherConfig(log_file_max_size_mb=True)

        issues = config.validate()

        assert any("log_file_max_size_mb" in issue for issue in issues), issues

    def test_backup_count_reports_a_string(self):
        config = LinkWatcherConfig(log_file_backup_count="x")

        issues = config.validate()

        assert any("log_file_backup_count" in issue for issue in issues), issues

    def test_backup_count_reports_a_float(self):
        """A whole-valued float is no better: `backups[3.5:]` and `backups[3.0:]`
        both raise `TypeError: slice indices must be integers`, so this field
        needs a strict `int`, not merely a number.
        """
        for value in (3.5, 3.0):
            config = LinkWatcherConfig(log_file_backup_count=value)

            issues = config.validate()

            assert any("log_file_backup_count" in issue for issue in issues), "%r accepted: %r" % (
                value,
                issues,
            )

    # ---- bounds: this field does not share the default rule ---------------

    def test_backup_count_zero_is_valid(self):
        """0 is a real setting — `doRollover` skips pruning entirely — so the
        blanket "must be positive" rule the other numeric fields use would
        reject a value the code deliberately handles.
        """
        config = LinkWatcherConfig(log_file_backup_count=0)

        issues = config.validate()

        assert not any("log_file_backup_count" in issue for issue in issues), issues

    def test_backup_count_negative_is_reported(self):
        config = LinkWatcherConfig(log_file_backup_count=-1)

        issues = config.validate()

        assert any("log_file_backup_count" in issue for issue in issues), issues

    def test_rotation_size_zero_is_reported(self):
        """Unlike the backup count, a size of 0 is not meaningful."""
        config = LinkWatcherConfig(log_file_max_size_mb=0)

        issues = config.validate()

        assert any("log_file_max_size_mb" in issue for issue in issues), issues

    # ---- the drift guard: coverage derived from the schema ----------------

    def test_every_numeric_field_in_the_schema_reports_a_string(self):
        """Derived from the dataclass, not from a hand-written list.

        A numeric field added to `LinkWatcherConfig` without a validation rule
        turns this red. The predecessor test hardcoded the same five names
        `validate()` already covered, so code and test drifted together and the
        gap this bug records survived both.
        """
        numeric_fields = _schema_fields_of_type(int, float)

        assert len(numeric_fields) >= 7, numeric_fields

        for name in numeric_fields:
            issues = LinkWatcherConfig(**{name: "not-a-number"}).validate()

            assert any(name in issue for issue in issues), "%s unvalidated: %r" % (
                name,
                issues,
            )

    def test_every_numeric_field_in_the_schema_rejects_a_bool(self):
        for name in _schema_fields_of_type(int, float):
            issues = LinkWatcherConfig(**{name: True}).validate()

            assert any(name in issue for issue in issues), "%s accepted a bool: %r" % (
                name,
                issues,
            )

    def test_every_set_field_in_the_schema_is_validated(self):
        """TD275, folded in with this fix: `_SET_FIELDS` hardcoded names the
        module already derives from type hints, so its stated invariant was not
        mechanically enforced. Coverage now comes from the schema and this test
        is what enforces it.
        """
        set_fields = _schema_fields_of_type_set_of_str()

        assert len(set_fields) >= 5, set_fields

        for name in set_fields:
            issues = LinkWatcherConfig(**{name: 7}).validate()

            assert any(name in issue for issue in issues), "%s unvalidated: %r" % (
                name,
                issues,
            )

    # ---- controls: valid values must be unaffected ------------------------

    def test_control_valid_rotation_values_report_nothing(self):
        config = LinkWatcherConfig(log_file_max_size_mb=25, log_file_backup_count=7)

        assert config.validate() == []

    def test_control_int_declared_fields_still_accept_ints(self):
        for name in _schema_fields_of_type(int):
            issues = LinkWatcherConfig(**{name: 3}).validate()

            assert not any(name in issue for issue in issues), issues

    def test_control_float_declared_fields_still_accept_floats(self):
        """The strict-int rule applies only where the schema declares `int`."""
        for name in _schema_fields_of_type(float):
            issues = LinkWatcherConfig(**{name: 2.5}).validate()

            assert not any(name in issue for issue in issues), issues

    def test_control_existing_messages_are_unchanged(self):
        """The type-message wording for the previously covered fields must not
        drift — the PD-BUG-123 suite matches on these byte-identically.
        """
        issues = LinkWatcherConfig(max_file_size_mb="big").validate()

        assert "max_file_size_mb must be a number (got str)" in issues


class TestBug129ExtensionChecksDeriveFromSchema:
    """PD-BUG-129: the leading-dot check named `monitored_extensions` literally,
    so the other two extension-bearing fields escaped it entirely.

    Both escapes fail the same silent way — by matching nothing against a
    suffix that always carries its dot:

    - `validation_extensions: [md]` — `should_monitor_file` compares against
      `os.path.splitext(...)[1]`, so no file is ever selected. `--validate`
      then reports `Files scanned: 0` and `No broken links found` at exit 0 on
      a tree that does have broken links. Measured: the same tree exits 1 with
      no config and 0 with this one.
    - `parser_type_extensions: {python: py}` — compared in `database.py`
      against a `splitext` result, so every extensionless Python/Dart import
      reference is silently filtered out of lookups. Being a `Dict`, the field
      escapes even the string-collection type check above.

    Third occurrence of one root cause: `validate()` iterating a hardcoded
    field list while the schema declares more (PD-BUG-127 was the second, one
    check higher in the same function). Contract pinned here: the *field set*
    is derived from the schema, so an extension field added later cannot be
    silently left unchecked.
    """

    # ---- the reported defect ---------------------------------------------

    def test_validation_extensions_reports_a_dotless_entry(self):
        config = LinkWatcherConfig(validation_extensions={"md"})

        issues = config.validate()

        assert any("validation_extensions" in issue for issue in issues), issues

    def test_parser_type_extensions_reports_a_dotless_value(self):
        """The `Dict` field: its *values* are extensions."""
        config = LinkWatcherConfig(parser_type_extensions={"python": "py"})

        issues = config.validate()

        assert any("parser_type_extensions" in issue for issue in issues), issues

    def test_issue_names_the_offending_field(self):
        """With three fields checked, `Extension 'md' should start with a dot`
        no longer tells the operator which key is wrong — the whole point of
        the bug is that they learn it.
        """
        issues = LinkWatcherConfig(validation_extensions={"md"}).validate()

        assert "validation_extensions entry 'md' should start with a dot" in issues

    # ---- the derived-coverage contract ------------------------------------

    def test_every_extension_field_in_the_schema_is_checked(self):
        """The load-bearing assertion. The field set is derived here from the
        dataclass independently of the production helper — asking `settings.py`
        which fields it checks could only confirm the module agrees with
        itself, which is exactly how the predecessor of this check let two
        fields through.
        """
        extension_fields = _schema_fields_holding_extensions()

        for known in _KNOWN_EXTENSION_FIELDS:
            assert known in extension_fields, "%s dropped out of the derived set: %r" % (
                known,
                extension_fields,
            )

        for name in extension_fields:
            config = LinkWatcherConfig(**{name: _dotless_value_for(name)})

            issues = config.validate()

            assert any(name in issue for issue in issues), "%s unchecked: %r" % (
                name,
                issues,
            )

    # ---- controls: valid and already-covered behavior must be unaffected ---

    def test_control_monitored_extensions_is_still_reported(self):
        """The originally covered field must not regress out of coverage."""
        issues = LinkWatcherConfig(monitored_extensions={"md", "txt"}).validate()

        assert any("should start with a dot" in issue for issue in issues), issues

    def test_control_dotted_values_report_nothing(self):
        config = LinkWatcherConfig(
            monitored_extensions={".md"},
            validation_extensions={".md", ".yaml"},
            parser_type_extensions={"python": ".py", "dart": ".dart"},
        )

        assert config.validate() == []

    def test_control_wrongly_typed_field_reports_only_the_type_issue(self):
        """A non-collection value must not also produce a spurious dot issue —
        the type issue above already names the problem (PD-BUG-123 ordering).
        """
        issues = LinkWatcherConfig(validation_extensions=7).validate()

        assert any("must be a list of strings" in issue for issue in issues), issues
        assert not any("should start with a dot" in issue for issue in issues), issues

    def test_control_non_extension_set_fields_are_not_dot_checked(self):
        """`ignored_directories` is also `Set[str]` but holds directory names —
        dot-checking it would reject every valid config.
        """
        issues = LinkWatcherConfig(ignored_directories={".git", "node_modules"}).validate()

        assert not any("ignored_directories" in issue for issue in issues), issues


class TestBug143ExplicitlySetValuesSurviveMerge:
    """PD-BUG-143: `merge()` had no record of which fields were *set*, so it
    inferred it from `value != default`.

    `from_env()` builds a full `LinkWatcherConfig()` and mutates only the
    fields whose environment variable is present. By the time `merge()` sees
    that object, "set to the default" and "never set at all" are byte-identical
    — so an environment variable deliberately set to a field's default was
    discarded and the config file won, contradicting the precedence documented
    in FDD 3.1.1-BR-6 and in this module's own docstring (CLI > env > file >
    defaults). Silently: no warning, no log record.

    Booleans are the severe case, and the reason this is not a corner case.
    A boolean has only two values — the default and not-the-default — so
    whenever a config file sets the meaningful one, the environment's
    counter-value *is* the default and is dropped. For all 17 boolean fields
    the environment could therefore never reverse a file setting in either
    direction. `dry_run_mode` had no escape at all: `--dry-run` only sets True
    and there is no `--no-dry-run`, so a file that enabled dry run could not be
    disabled from anywhere.

    The defect lived only in `merge()`. `from_env()` reads correctly, and the
    CLI layer assigns attributes directly in `main.load_config` without going
    through `merge()` — so env-over-file was the sole live surface.

    Contract pinned here: an explicitly set value wins regardless of whether it
    equals the schema default. Configs built programmatically record nothing
    and keep the historical value-vs-default inference, so library callers are
    unaffected.
    """

    @staticmethod
    def _resolve(tmp_path, file_values, env_values):
        """Assemble a config the way `main.load_config` does: defaults, then
        file, then environment — through the real `from_file` / `from_env`.

        The environment is replaced wholesale rather than updated, so an
        ambient `LINKWATCHER_*` variable in the developer's shell cannot
        change what these assertions measure.
        """
        config_file = tmp_path / "linkwatcher-config.yaml"
        config_file.write_text(yaml.safe_dump(file_values), encoding="utf-8")

        merged = LinkWatcherConfig().merge(LinkWatcherConfig.from_file(str(config_file)))

        clean = {k: v for k, v in os.environ.items() if not k.startswith("LINKWATCHER_")}
        clean.update(env_values)
        with patch.dict(os.environ, clean, clear=True):
            env_config = LinkWatcherConfig.from_env()

        return merged.merge(env_config)

    # ---- the reported defect ----------------------------------------------

    def test_float_env_value_equal_to_default_wins_over_the_file(self, tmp_path):
        resolved = self._resolve(
            tmp_path,
            {"move_detect_delay": 25},
            {"LINKWATCHER_MOVE_DETECT_DELAY": "10"},
        )

        assert resolved.move_detect_delay == 10.0
        assert resolved.move_detect_delay != 25, "the config file value survived the environment"

    def test_int_env_value_equal_to_default_wins_over_the_file(self, tmp_path):
        resolved = self._resolve(
            tmp_path,
            {"max_file_size_mb": 25},
            {"LINKWATCHER_MAX_FILE_SIZE_MB": "10"},
        )

        assert resolved.max_file_size_mb == 10
        assert resolved.max_file_size_mb != 25, "the config file value survived the environment"

    def test_str_env_value_equal_to_default_wins_over_the_file(self, tmp_path):
        resolved = self._resolve(
            tmp_path,
            {"log_level": "DEBUG"},
            {"LINKWATCHER_LOG_LEVEL": "INFO"},
        )

        assert resolved.log_level == "INFO"
        assert resolved.log_level != "DEBUG", "the config file value survived the environment"

    def test_env_can_turn_off_a_boolean_the_file_turned_on(self, tmp_path):
        """`dry_run_mode` defaults False. The file enables it; the environment
        must be able to disable it — the case with no other escape, since
        `--dry-run` only sets True.
        """
        resolved = self._resolve(
            tmp_path,
            {"dry_run_mode": True},
            {"LINKWATCHER_DRY_RUN_MODE": "false"},
        )

        assert resolved.dry_run_mode is False
        assert resolved.dry_run_mode is not True, "dry run stayed on despite the environment"

    def test_env_can_turn_on_a_boolean_the_file_turned_off(self, tmp_path):
        """The other direction: `initial_scan_enabled` defaults True, so the
        environment's re-enabling value is the default and was dropped.
        """
        resolved = self._resolve(
            tmp_path,
            {"initial_scan_enabled": False},
            {"LINKWATCHER_INITIAL_SCAN_ENABLED": "true"},
        )

        assert resolved.initial_scan_enabled is True
        assert (
            resolved.initial_scan_enabled is not False
        ), "the initial scan stayed disabled despite the environment"

    # ---- the derived-coverage contract ------------------------------------

    def test_every_boolean_field_can_be_reversed_from_the_environment(self, tmp_path):
        """The load-bearing assertion. The field set is derived from the
        dataclass rather than listed, so a boolean field added later is covered
        automatically — the precedent PD-BUG-127 and PD-BUG-129 set.

        For each boolean the file is written with the *non-default* value and
        the environment with the default, which is exactly the shape that was
        being discarded.
        """
        bool_fields = _schema_fields_of_type(bool)
        assert len(bool_fields) >= 17, f"derivation narrowed unexpectedly: {bool_fields}"

        defaults = LinkWatcherConfig()
        survived = []
        for name in bool_fields:
            default = getattr(defaults, name)
            resolved = self._resolve(
                tmp_path,
                {name: not default},
                {f"LINKWATCHER_{name.upper()}": "true" if default else "false"},
            )
            if getattr(resolved, name) is not default:
                survived.append(name)

        assert survived == [], f"config file value survived the environment for: {survived}"

    def test_known_boolean_fields_are_in_the_derived_set(self):
        """A named floor, so the derivation above is falsifiable rather than
        self-confirming: if `_schema_fields_of_type(bool)` were ever narrowed,
        the breadth test would quietly cover less and still pass.
        """
        derived = set(_schema_fields_of_type(bool))

        for name in ("dry_run_mode", "create_backups", "initial_scan_enabled", "colored_output"):
            assert name in derived, f"{name} missing from the derived boolean field set"

    # ---- controls ---------------------------------------------------------

    def test_control_env_value_differing_from_the_default_still_wins(self, tmp_path):
        """The case that always worked, pinned so the fix cannot regress it."""
        resolved = self._resolve(
            tmp_path,
            {"move_detect_delay": 25},
            {"LINKWATCHER_MOVE_DETECT_DELAY": "30"},
        )

        assert resolved.move_detect_delay == 30.0

    def test_control_file_only_configuration_is_unchanged(self, tmp_path):
        """No environment layer: the file must win over the defaults, including
        for a key it sets *to* the default, and a key it never mentions must
        stay at the default.
        """
        resolved = self._resolve(
            tmp_path,
            {"move_detect_delay": 25, "log_level": "INFO", "dry_run_mode": True},
            {},
        )

        assert resolved.move_detect_delay == 25
        assert resolved.log_level == "INFO"
        assert resolved.dry_run_mode is True
        assert resolved.max_file_size_mb == 10, "an unmentioned key drifted off its default"

    def test_control_programmatic_construction_keeps_the_default_inference(self):
        """A config built by keyword records nothing as explicitly set, so
        `merge` falls back to the historical value-vs-default rule. Without
        this fallback, merging a plain `LinkWatcherConfig()` would reset every
        field on the target.
        """
        base = LinkWatcherConfig(dry_run_mode=True, log_level="DEBUG")

        merged = base.merge(LinkWatcherConfig())

        assert merged.dry_run_mode is True, "a plain construction wiped the target"
        assert merged.log_level == "DEBUG"

    def test_control_a_merged_config_carries_forward_only_its_inputs_explicit_fields(
        self, tmp_path
    ):
        """`merge` copies all 39 fields onto its result. If that copying were
        recorded as explicit intent, the result could never be merged *into*
        anything again without overwriting every field.
        """
        config_file = tmp_path / "linkwatcher-config.yaml"
        config_file.write_text(yaml.safe_dump({"log_level": "DEBUG"}), encoding="utf-8")
        from_file = LinkWatcherConfig().merge(LinkWatcherConfig.from_file(str(config_file)))

        result = LinkWatcherConfig(dry_run_mode=True).merge(from_file)

        assert result.log_level == "DEBUG", "the file layer did not apply"
        assert result.dry_run_mode is True, "an unset field in the merged config wiped the target"

    def test_control_the_explicit_field_record_never_reaches_to_dict(self):
        """`to_dict` feeds `save_to_file`. A private bookkeeping attribute
        leaking in would be written into the user's YAML or JSON.
        """
        config = LinkWatcherConfig()
        config.dry_run_mode = True

        keys = set(config.to_dict())

        assert not any(k.startswith("_") for k in keys), sorted(keys)
        assert keys == {f.name for f in dataclasses.fields(LinkWatcherConfig)}

    def test_control_a_saved_config_round_trips(self, tmp_path):
        """End-to-end guard on the same leak: save then reload, and confirm the
        reloaded config carries the value and no stray key.
        """
        config = LinkWatcherConfig()
        config.dry_run_mode = True
        target = tmp_path / "saved-config.yaml"

        config.save_to_file(str(target))
        reloaded = LinkWatcherConfig.from_file(str(target))

        assert reloaded.dry_run_mode is True
        written = yaml.safe_load(target.read_text(encoding="utf-8"))
        assert not any(k.startswith("_") for k in written), sorted(written)
