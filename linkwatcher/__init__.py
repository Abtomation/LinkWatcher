"""
LinkWatcher - Real-time Link Maintenance System

A modern, reliable link maintenance system that uses file system watching
to detect file movements and automatically update all references in real-time.
"""

# Ensure UTF-8 I/O on Windows regardless of system code page.
# Must run before any import that triggers colorama.init(), which
# wraps stdout/stderr and inherits whatever encoding they have.
import sys as _sys

if _sys.platform == "win32":
    for _stream_name in ("stdout", "stderr"):
        _stream = getattr(_sys, _stream_name, None)
        if _stream and hasattr(_stream, "reconfigure"):
            try:
                if (_stream.encoding or "").lower().replace("-", "") != "utf8":
                    _stream.reconfigure(encoding="utf-8", errors="replace")
            except Exception:
                pass  # frozen/redirected streams may not support reconfigure
    del _stream_name, _stream
del _sys

__version__ = "2.0.0"
__author__ = "LinkWatcher Team"

from .database import LinkDatabase, LinkDatabaseInterface
from .logging import LogLevel, LogTimer, get_logger, setup_logging, with_context
from .models import FileOperation, LinkReference
from .parser import LinkParser
from .path_resolver import PathResolver
from .service import LinkWatcherService
from .updater import LinkUpdater

__all__ = [
    "LinkWatcherService",
    "LinkDatabase",
    "LinkDatabaseInterface",
    "LinkParser",
    "LinkUpdater",
    "PathResolver",
    "LinkReference",
    "FileOperation",
    # Logging
    "get_logger",
    "setup_logging",
    "LogLevel",
    "LogTimer",
    "with_context",
]
