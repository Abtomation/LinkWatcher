"""
Data models for the LinkWatcher system.

This module contains the core data structures used throughout the system.
"""

from dataclasses import dataclass
from datetime import datetime
from typing import Optional


@dataclass
class LinkReference:
    """Represents a link reference found in a file."""

    file_path: str
    line_number: int
    column_start: int
    column_end: int
    link_text: str
    link_target: str
    link_type: str  # 'markdown', 'yaml', 'direct', etc.


@dataclass
class FileOperation:
    """Represents a file system operation."""

    operation_type: str  # 'moved', 'deleted', 'created'
    old_path: Optional[str]
    new_path: Optional[str]
    timestamp: datetime
