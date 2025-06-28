"""
Configuration classes for the LinkWatcher system.

This module provides configuration management with support for
loading from files, environment variables, and programmatic settings.
"""

import json
import os
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Dict, List, Optional, Set

import yaml


@dataclass
class LinkWatcherConfig:
    """Configuration for LinkWatcher system."""

    # File monitoring settings
    monitored_extensions: Set[str] = field(
        default_factory=lambda: {".md", ".yaml", ".yml", ".dart", ".py", ".json", ".txt"}
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
        }
    )

    # Parser settings
    enable_markdown_parser: bool = True
    enable_yaml_parser: bool = True
    enable_json_parser: bool = True
    enable_dart_parser: bool = True
    enable_python_parser: bool = True
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

    # Advanced settings
    custom_parsers: Dict[str, str] = field(default_factory=dict)
    exclude_patterns: Set[str] = field(default_factory=set)
    include_patterns: Set[str] = field(default_factory=set)

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

        # Convert sets from lists
        if "monitored_extensions" in data:
            config.monitored_extensions = set(data["monitored_extensions"])

        if "ignored_directories" in data:
            config.ignored_directories = set(data["ignored_directories"])

        if "exclude_patterns" in data:
            config.exclude_patterns = set(data["exclude_patterns"])

        if "include_patterns" in data:
            config.include_patterns = set(data["include_patterns"])

        # Set other attributes
        for key, value in data.items():
            if hasattr(config, key) and key not in [
                "monitored_extensions",
                "ignored_directories",
                "exclude_patterns",
                "include_patterns",
            ]:
                setattr(config, key, value)

        return config

    @classmethod
    def from_env(cls, prefix: str = "LINKWATCHER_") -> "LinkWatcherConfig":
        """Load configuration from environment variables."""
        config = cls()

        # Map environment variables to config attributes
        env_mappings = {
            f"{prefix}MONITORED_EXTENSIONS": "monitored_extensions",
            f"{prefix}IGNORED_DIRECTORIES": "ignored_directories",
            f"{prefix}CREATE_BACKUPS": "create_backups",
            f"{prefix}DRY_RUN": "dry_run_mode",
            f"{prefix}MAX_FILE_SIZE_MB": "max_file_size_mb",
            f"{prefix}LOG_LEVEL": "log_level",
            f"{prefix}COLORED_OUTPUT": "colored_output",
        }

        for env_var, attr_name in env_mappings.items():
            if env_var in os.environ:
                value = os.environ[env_var]

                # Convert string values to appropriate types
                if attr_name in ["monitored_extensions", "ignored_directories"]:
                    setattr(config, attr_name, set(value.split(",")))
                elif attr_name in ["create_backups", "dry_run_mode", "colored_output"]:
                    setattr(config, attr_name, value.lower() in ["true", "1", "yes", "on"])
                elif attr_name == "max_file_size_mb":
                    setattr(config, attr_name, int(value))
                else:
                    setattr(config, attr_name, value)

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

        if format.lower() == "json":
            with open(config_path, "w", encoding="utf-8") as f:
                json.dump(data, f, indent=2)
        elif format.lower() in ["yaml", "yml"]:
            with open(config_path, "w", encoding="utf-8") as f:
                yaml.dump(data, f, default_flow_style=False, indent=2)
        else:
            raise ValueError(f"Unsupported format: {format}")

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

        return issues
