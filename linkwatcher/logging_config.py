"""
Advanced logging configuration and management for LinkWatcher.

This module provides runtime configuration management for the logging
system defined in logging.py.

AI Context
----------
- **Entry point**: ``LoggingConfigManager`` — instantiated by service
  or CLI when a config file is provided.  ``load_config_file()`` reads
  YAML/JSON and applies settings to the global logger.
- **Delegation**: imports ``get_logger()`` and ``LogLevel`` from
  logging.py; all actual log output flows through the logger defined
  there.  This module only *configures*, never emits logs directly.
- **Common tasks**:
  - Adding a config option: add parsing logic in
    ``_apply_config()`` and document the key in config-examples/.
  - Debugging config reload: check ``_watch_config_file()`` thread
    and ``auto_reload`` flag — it polls for file mtime changes.
  - CLI utilities at module bottom (``parse_log_level()``,
    ``configure_from_args()``) are used by main.py argument parsing.
"""

import json
import threading
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, Optional, Union

from .logging import LogLevel, get_logger


class LoggingConfigManager:
    """Manage logging configuration at runtime."""

    def __init__(self):
        self.logger = get_logger()
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
            with open(self.config_file, "r", encoding="utf-8") as f:
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
        if "log_level" in config:
            try:
                level = LogLevel(config["log_level"])
                self.logger.set_level(level)
            except ValueError:
                self.logger.warning("invalid_log_level", level=config["log_level"])

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

    def create_debug_snapshot(self) -> Dict[str, Any]:
        """Create a debug snapshot with current state."""
        return {
            "timestamp": datetime.now().isoformat(),
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


def reset_config_manager():
    """Reset the global config manager instance.

    Intended for test isolation — avoids tests reaching into private
    module state (``_config_manager = None``).
    """
    global _config_manager
    _config_manager = None


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
