"""
Configuration classes for the LinkWatcher system.

This module provides configuration management with support for
loading from files, environment variables, and programmatic settings.

AI Context
----------
- **Entry point**: ``LinkWatcherConfig`` dataclass — instantiated by
  service or tests.  Class methods ``from_file()``, ``from_env()``,
  and ``from_dict()`` provide alternative constructors.
- **Precedence chain**: defaults → file → env → CLI, combined via
  ``merge()`` (other's non-default values override this config's).
- **Common tasks**:
  - Adding a config field: add a dataclass field with default, then
    add its env-var mapping in ``from_env()`` and YAML key handling
    in ``_from_dict()``.  Update config-examples/ YAML files.
  - Debugging config loading: ``_from_dict()`` uses ``setattr`` with
    a dunder guard; ``from_file()`` delegates to PyYAML/json.
  - Understanding type coercion: ``_from_dict()`` converts lists to
    sets for ``monitored_extensions`` and ``ignored_directories``.
"""

import dataclasses
import json
import logging
import os
import tempfile
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Dict, List, Optional, Set, get_type_hints

import yaml

logger = logging.getLogger(__name__)


@dataclass
class LinkWatcherConfig:
    """Configuration for the LinkWatcher real-time link maintenance system.

    Configuration precedence (highest to lowest):
        1. CLI arguments — passed directly to LinkWatcherConfig fields
        2. Environment variables — loaded via ``from_env(prefix)``
        3. Configuration file (YAML/JSON) — loaded via ``from_file(path)``
        4. Dataclass defaults — defined on each field below

    Use ``merge()`` to combine two configs: the *other* config's non-default
    values override *this* config's values, which enables the precedence
    chain (e.g., ``file_config.merge(env_config).merge(cli_config)``).

    Configuration groups:
        - **File monitoring**: ``monitored_extensions``, ``ignored_directories``
        - **Parsers**: ``enable_<format>_parser`` flags
        - **Update behavior**: ``create_backups``, ``dry_run_mode``, ``atomic_updates``
        - **Performance**: ``max_file_size_mb``, ``initial_scan_enabled``,
          ``scan_progress_interval``
        - **Logging**: ``log_level``, ``colored_output``, ``log_file``,
          ``json_logs``, etc.
        - **Validation**: ``validation_extensions``,
          ``validation_extra_ignored_dirs``,
          ``validation_ignored_patterns``, ``validation_ignore_file``
        - **Move detection timing**: ``move_detect_delay``,
          ``dir_move_max_timeout``, ``dir_move_settle_delay``
    """

    # File monitoring settings
    monitored_extensions: Set[str] = field(
        default_factory=lambda: {
            ".md",
            ".yaml",
            ".yml",
            ".dart",
            ".py",
            ".json",
            ".txt",
            ".ps1",
            ".psm1",
            ".bat",
            ".toml",
        }
    )

    ignored_directories: Set[str] = field(
        default_factory=lambda: {
            ".git",
            ".dart_tool",
            "node_modules",
            ".vscode",
            "build",
            "dist",
            "__pycache__",
            "tests",
            "LinkWatcher_run",
        }
    )

    # Parser settings
    enable_markdown_parser: bool = True
    enable_yaml_parser: bool = True
    enable_json_parser: bool = True
    enable_dart_parser: bool = True
    enable_python_parser: bool = True
    enable_powershell_parser: bool = True
    enable_generic_parser: bool = True

    # Update behavior
    create_backups: bool = False
    dry_run_mode: bool = False
    atomic_updates: bool = True

    # Performance settings
    max_file_size_mb: int = 10
    initial_scan_enabled: bool = True
    scan_progress_interval: int = 50

    # Logging settings
    log_level: str = "INFO"
    colored_output: bool = True
    show_statistics: bool = True
    log_file: Optional[str] = None
    log_file_max_size_mb: int = 10
    log_file_backup_count: int = 5
    json_logs: bool = False
    show_log_icons: bool = True
    performance_logging: bool = False

    # Validation settings
    validation_extensions: Set[str] = field(
        default_factory=lambda: {
            ".md",
            ".yaml",
            ".yml",
            ".json",
        }
    )
    validation_extra_ignored_dirs: Set[str] = field(
        default_factory=lambda: {
            "LinkWatcher_run",
            "old",
            "archive",
            "fixtures",
            "e2e-acceptance-testing",
            "config-examples",
        }
    )
    validation_ignored_patterns: Set[str] = field(
        default_factory=lambda: {
            "path/to/",
            "xxx",
        }
    )
    validation_ignore_file: str = ".linkwatcher-ignore"

    # Move detection timing
    move_detect_delay: float = 10.0
    dir_move_max_timeout: float = 300.0
    dir_move_settle_delay: float = 5.0

    @classmethod
    def from_file(cls, config_path: str) -> "LinkWatcherConfig":
        """Load configuration from a file."""
        config_path = Path(config_path)

        if not config_path.exists():
            raise FileNotFoundError(f"Configuration file not found: {config_path}")

        if config_path.suffix.lower() == ".json":
            return cls._from_json(config_path)
        elif config_path.suffix.lower() in [".yaml", ".yml"]:
            return cls._from_yaml(config_path)
        else:
            raise ValueError(f"Unsupported configuration file format: {config_path.suffix}")

    @classmethod
    def _from_json(cls, config_path: Path) -> "LinkWatcherConfig":
        """Load configuration from JSON file."""
        with open(config_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        return cls._from_dict(data)

    @classmethod
    def _from_yaml(cls, config_path: Path) -> "LinkWatcherConfig":
        """Load configuration from YAML file."""
        with open(config_path, "r", encoding="utf-8") as f:
            data = yaml.safe_load(f)
        return cls._from_dict(data)

    @classmethod
    def _from_dict(cls, data: Dict[str, Any]) -> "LinkWatcherConfig":
        """Create configuration from dictionary."""
        config = cls()
        known_fields = {f.name for f in dataclasses.fields(cls)}

        # Warn about unknown keys (likely typos)
        for key in data:
            if key not in known_fields:
                logger.warning("Unknown configuration key '%s' — ignored (possible typo?)", key)

        # Convert sets from lists
        if "monitored_extensions" in data:
            config.monitored_extensions = set(data["monitored_extensions"])

        if "ignored_directories" in data:
            config.ignored_directories = set(data["ignored_directories"])

        if "validation_extra_ignored_dirs" in data:
            config.validation_extra_ignored_dirs = set(data["validation_extra_ignored_dirs"])

        if "validation_ignored_patterns" in data:
            config.validation_ignored_patterns = set(data["validation_ignored_patterns"])

        # Set other attributes
        for key, value in data.items():
            if key.startswith("_"):
                continue
            if key in known_fields and key not in [
                "monitored_extensions",
                "ignored_directories",
                "validation_extra_ignored_dirs",
                "validation_ignored_patterns",
            ]:
                setattr(config, key, value)

        return config

    @classmethod
    def from_env(cls, prefix: str = "LINKWATCHER_") -> "LinkWatcherConfig":
        """Load configuration from environment variables.

        Environment variable names are derived from field names:
        ``{prefix}{FIELD_NAME_UPPER}`` — e.g. ``LINKWATCHER_DRY_RUN_MODE``.

        Type conversion is automatic based on the field's type annotation:
        ``Set[str]`` splits on ``,``; ``bool`` accepts true/1/yes/on;
        ``int`` and ``float`` are parsed; everything else is kept as a string.
        """
        config = cls()
        type_hints = get_type_hints(cls)

        for f in dataclasses.fields(cls):
            env_var = f"{prefix}{f.name.upper()}"
            if env_var not in os.environ:
                continue

            value = os.environ[env_var]
            field_type = type_hints[f.name]

            if field_type is Set[str] or field_type is set:
                setattr(config, f.name, set(value.split(",")))
            elif field_type is bool:
                setattr(config, f.name, value.lower() in ("true", "1", "yes", "on"))
            elif field_type is int:
                try:
                    setattr(config, f.name, int(value))
                except ValueError:
                    logger.warning(
                        "Invalid value '%s' for env var %s (expected int) — using default",
                        value,
                        env_var,
                    )
            elif field_type is float:
                try:
                    setattr(config, f.name, float(value))
                except ValueError:
                    logger.warning(
                        "Invalid value '%s' for env var %s (expected float) — using default",
                        value,
                        env_var,
                    )
            else:
                setattr(config, f.name, value)

        return config

    def to_dict(self) -> Dict[str, Any]:
        """Convert configuration to dictionary."""
        result = {}

        for key, value in self.__dict__.items():
            if isinstance(value, set):
                result[key] = list(value)
            else:
                result[key] = value

        return result

    def save_to_file(self, config_path: str, format: str = "yaml"):
        """Save configuration to file."""
        config_path = Path(config_path)
        data = self.to_dict()

        if format.lower() not in ("json", "yaml", "yml"):
            raise ValueError(f"Unsupported format: {format}")

        # Write to a temporary file first, then atomically replace the target
        dir_path = str(config_path.parent)
        temp_fd = None
        temp_path = None
        try:
            temp_fd, temp_path = tempfile.mkstemp(dir=dir_path, suffix=config_path.suffix)
            with os.fdopen(temp_fd, "w", encoding="utf-8") as f:
                temp_fd = None  # os.fdopen takes ownership of the fd
                if format.lower() == "json":
                    json.dump(data, f, indent=2)
                else:
                    yaml.dump(data, f, default_flow_style=False, indent=2)
            os.replace(temp_path, str(config_path))
            temp_path = None  # successfully moved
        finally:
            if temp_fd is not None:
                os.close(temp_fd)
            if temp_path is not None:
                try:
                    os.unlink(temp_path)
                except OSError:
                    pass

    def merge(self, other: "LinkWatcherConfig") -> "LinkWatcherConfig":
        """Merge this configuration with another, returning a new instance."""
        merged = LinkWatcherConfig()
        default_config = LinkWatcherConfig()

        # Start with this config's values
        for key, value in self.__dict__.items():
            if isinstance(value, set):
                setattr(merged, key, value.copy())
            else:
                setattr(merged, key, value)

        # Override with other config's values, but only if they differ from defaults
        for key, value in other.__dict__.items():
            default_value = getattr(default_config, key)

            # Only override if the other config's value is different from default
            if value != default_value:
                if isinstance(value, set):
                    setattr(merged, key, value.copy())
                else:
                    setattr(merged, key, value)

        return merged

    def validate(self) -> List[str]:
        """Validate configuration and return list of issues."""
        issues = []

        # Check file size limit
        if self.max_file_size_mb <= 0:
            issues.append("max_file_size_mb must be positive")

        # Check log level
        valid_log_levels = ["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"]
        if self.log_level.upper() not in valid_log_levels:
            issues.append(f"log_level must be one of: {valid_log_levels}")

        # Check extensions format
        for ext in self.monitored_extensions:
            if not ext.startswith("."):
                issues.append(f"Extension '{ext}' should start with a dot")

        # Check scan progress interval
        if self.scan_progress_interval <= 0:
            issues.append("scan_progress_interval must be positive")

        # Check move detection timing
        if self.move_detect_delay <= 0:
            issues.append("move_detect_delay must be positive")
        if self.dir_move_max_timeout <= 0:
            issues.append("dir_move_max_timeout must be positive")
        if self.dir_move_settle_delay <= 0:
            issues.append("dir_move_settle_delay must be positive")

        return issues
