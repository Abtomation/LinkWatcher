"""
Default configuration values for the LinkWatcher system.

This module provides the default configuration that can be used
as a starting point or fallback.
"""

from .settings import LinkWatcherConfig

# Default configuration instance — instantiated from the LinkWatcherConfig
# dataclass defaults, which are the single source of truth for the schema
# (PD-BUG-103: this module previously re-declared the default sets and
# silently diverged from settings.py).
DEFAULT_CONFIG = LinkWatcherConfig()

# Configuration for different environments
DEVELOPMENT_CONFIG = LinkWatcherConfig(
    # More verbose logging for development
    log_level="DEBUG",
    show_statistics=True,
    # Safer defaults for development
    create_backups=False,
    dry_run_mode=False,
    # Standard monitoring
    monitored_extensions=DEFAULT_CONFIG.monitored_extensions.copy(),
    ignored_directories=DEFAULT_CONFIG.ignored_directories.copy(),
)

PRODUCTION_CONFIG = LinkWatcherConfig(
    # Less verbose logging for production
    log_level="WARNING",
    show_statistics=False,
    colored_output=False,
    # Performance optimized
    initial_scan_enabled=False,  # Skip initial scan for faster startup
    max_file_size_mb=5,  # Smaller file size limit
    # Standard monitoring
    monitored_extensions=DEFAULT_CONFIG.monitored_extensions.copy(),
    ignored_directories=DEFAULT_CONFIG.ignored_directories.copy(),
)

TESTING_CONFIG = LinkWatcherConfig(
    # Testing-specific settings
    log_level="DEBUG",
    show_statistics=False,
    colored_output=False,
    # Safe for testing (keep backups enabled for testing backup functionality)
    create_backups=True,
    dry_run_mode=True,  # Don't actually modify files in tests
    # Minimal monitoring for tests
    monitored_extensions={".md", ".txt", ".png", ".svg"},
    ignored_directories={".git", "node_modules"},
)
