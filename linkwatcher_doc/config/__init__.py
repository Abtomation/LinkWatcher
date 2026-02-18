"""
Configuration management for the LinkWatcher system.

This package provides configuration classes and default settings
for customizing LinkWatcher behavior.
"""

from .defaults import DEFAULT_CONFIG, DEVELOPMENT_CONFIG, PRODUCTION_CONFIG, TESTING_CONFIG
from .settings import LinkWatcherConfig

__all__ = [
    "LinkWatcherConfig",
    "DEFAULT_CONFIG",
    "DEVELOPMENT_CONFIG",
    "PRODUCTION_CONFIG",
    "TESTING_CONFIG",
]
