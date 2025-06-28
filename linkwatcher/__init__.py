"""
LinkWatcher - Real-time Link Maintenance System

A modern, reliable link maintenance system that uses file system watching
to detect file movements and automatically update all references in real-time.
"""

__version__ = "2.0.0"
__author__ = "LinkWatcher Team"

from .database import LinkDatabase
from .logging import LogLevel, LogTimer, get_logger, setup_logging, with_context
from .models import FileOperation, LinkReference
from .parser import LinkParser
from .service import LinkWatcherService
from .updater import LinkUpdater

__all__ = [
    "LinkWatcherService",
    "LinkDatabase",
    "LinkParser",
    "LinkUpdater",
    "LinkReference",
    "FileOperation",
    # Logging
    "get_logger",
    "setup_logging",
    "LogLevel",
    "LogTimer",
    "with_context",
]
