"""
Data models for the LinkWatcher system.

This module contains the core data structures used throughout the system.

AI Context
----------
- **Primary export**: ``LinkReference`` — the universal DTO that carries
  parsed link data between every pipeline stage (parser → database →
  reference_lookup → path_resolver → updater → validator).  Imported by
  6 modules.
- ``FileOperation`` is used only by handler/service for move/delete/create
  event representation.
- **Common tasks**:
  - Adding a field to ``LinkReference``: update the dataclass here, then
    grep for ``LinkReference(`` across all parsers to add the new argument
    at every construction site.
  - Understanding ``link_type`` values: see ``link_types.py`` for the
    canonical ``LinkType`` enum (37 members across 7 parser families).
"""

from dataclasses import dataclass
from datetime import datetime
from typing import Optional


@dataclass
class LinkReference:
    """Represents a link reference found in a file.

    Universal DTO produced by every parser and consumed by database,
    reference_lookup, path_resolver, updater, and validator.

    Fields
    ------
    file_path : str
        Absolute path of the source file containing this reference.
    line_number : int
        1-based line number where the reference appears.
    column_start : int
        0-based column offset of the link target start within the line.
    column_end : int
        0-based column offset one past the link target end.
    link_text : str
        Display text of the link (e.g., the ``[text]`` in markdown links,
        or the original import string for Python imports).  May be empty
        for bare-path patterns.
    link_target : str
        The file path or import path the link points to, as extracted
        from the source.
    link_type : str
        Discriminator identifying the syntactic pattern that produced
        this reference.  Values come from the ``LinkType`` enum in
        ``link_types.py`` (7 families: markdown, python, yaml, json,
        dart, powershell, generic).  The updater uses this to choose
        the correct replacement strategy for each pattern.
    """

    file_path: str
    line_number: int
    column_start: int
    column_end: int
    link_text: str
    link_target: str
    link_type: str  # see LinkType enum in link_types.py


@dataclass
class FileOperation:
    """Represents a file system operation."""

    operation_type: str  # 'moved', 'deleted', 'created'
    old_path: Optional[str]
    new_path: Optional[str]
    timestamp: datetime
