"""
Tests for the Python parser.

This module tests Python-specific link parsing functionality.
"""

from pathlib import Path

import pytest

from linkwatcher.models import LinkReference
from linkwatcher.parsers.python import PythonParser


class TestPythonParser:
    """Test cases for PythonParser."""

    def test_parser_initialization(self):
        """Test parser initialization."""
        parser = PythonParser()

        # Check that regex patterns are compiled
        assert parser.local_import_pattern is not None
        assert parser.quoted_pattern is not None
        assert parser.comment_pattern is not None

    def test_parse_import_statements(self, temp_project_dir):
        """Test parsing Python import statements."""
        parser = PythonParser()

        # Create Python file with imports
        py_file = temp_project_dir / "main.py"
        content = """#!/usr/bin/env python3
\"\"\"Main application module.\"\"\"

import os
import sys
from pathlib import Path

# Local imports
from utils import helper_functions
from config.settings import DATABASE_CONFIG
import data.models as models

# Relative imports
from .local_module import LocalClass
from ..parent_module import ParentClass

# File references in comments and strings
# See "config.yaml" for configuration
CONFIG_FILE = "tests/parsers/config.json"
TEMPLATE_PATH = 'templates/main.html'
"""
        py_file.write_text(content)

        # Parse the file
        references = parser.parse_file(str(py_file))

        # Should find various references
        assert len(references) >= 3

        # Check for specific references
        targets = [ref.link_target for ref in references]

        # Should find quoted file references
        assert "config.yaml" in targets
        assert "tests/parsers/config.json" in targets
        assert "templates/main.html" in targets

        # Check link types
        for ref in references:
            assert ref.link_type in ["python-quoted", "python-comment", "python-import"]

    def test_skip_import_modules(self, temp_project_dir):
        """Test that import statements for modules are skipped."""
        parser = PythonParser()

        # Create Python file with various imports
        py_file = temp_project_dir / "imports.py"
        content = """
# Standard library imports (should be ignored)
import os
import sys
import json
from pathlib import Path
from datetime import datetime

# Third-party imports (should be ignored)
import requests
import numpy as np
from flask import Flask, render_template

# Local imports (should be ignored unless they look like files)
from utils import helpers
from config import settings
import local_module

# But file references should be found
DATA_FILE = "data.json"
"""
        py_file.write_text(content)

        # Parse the file
        references = parser.parse_file(str(py_file))

        # Should only find actual file references, not import modules
        targets = [ref.link_target for ref in references]

        # Should find file reference
        assert "data.json" in targets

        # Should not find module imports
        assert "os" not in targets
        assert "requests" not in targets
        assert "utils" not in targets
        assert "config" not in targets

    def test_skip_dotted_stdlib_imports(self, temp_project_dir):
        """Test that dotted stdlib imports (e.g., email.mime.text) are filtered.

        Regression test for TD038: previously only 8 stdlib modules were
        recognized, so dotted imports like 'from email.mime.text import MIMEText'
        produced false-positive python-import references.
        """
        parser = PythonParser()

        py_file = temp_project_dir / "stdlib_dotted.py"
        content = """
from email.mime.text import MIMEText
from xml.etree.ElementTree import parse
from logging.handlers import RotatingFileHandler
from http.client import HTTPConnection
from urllib.parse import urlparse
import collections.abc
from concurrent.futures import ThreadPoolExecutor

# But local imports should still be found
DATA_FILE = "data.json"
"""
        py_file.write_text(content)

        references = parser.parse_file(str(py_file))
        targets = [ref.link_target for ref in references]

        # Should find actual file reference
        assert "data.json" in targets

        # Should NOT find false positives from stdlib dotted imports
        assert "email/mime/text" not in targets
        assert "xml/etree/ElementTree" not in targets
        assert "logging/handlers" not in targets
        assert "http/client" not in targets
        assert "urllib/parse" not in targets
        assert "collections/abc" not in targets
        assert "concurrent/futures" not in targets

    def test_avoid_false_positives(self, temp_project_dir):
        """Test that false positives are avoided."""
        parser = PythonParser()

        # Create Python file with potential false positives
        py_file = temp_project_dir / "false_positives.py"
        content = '''"""Module with potential false positives."""

# These should NOT be detected as file references
VERSION = "1.2.3"
EMAIL = "user@example.com"
URL = "https://example.com/api"
REGEX_PATTERN = r"\\d+\\.\\d+"
SQL_QUERY = "SELECT * FROM users WHERE id = 1"

# These SHOULD be detected as file references
CONFIG_FILE = "config.json"
DATA_PATH = "data/users.csv"

# Edge cases
EXTENSION_ONLY = ".txt"  # Should not be detected
NO_EXTENSION = "filename"  # Might be detected depending on heuristics
'''
        py_file.write_text(content)

        # Parse the file
        references = parser.parse_file(str(py_file))

        targets = [ref.link_target for ref in references]

        # Should find actual file references
        assert "config.json" in targets
        assert "data/users.csv" in targets

        # Should not find false positives
        assert "1.2.3" not in targets
        assert "user@example.com" not in targets
        assert "https://example.com/api" not in targets
        assert "SELECT * FROM users WHERE id = 1" not in targets

    def test_line_and_column_positions(self, temp_project_dir):
        """Test that line and column positions are correctly recorded."""
        parser = PythonParser()

        # Create Python file with known positions
        py_file = temp_project_dir / "positions.py"
        content = '''"""Test file for position tracking."""

CONFIG = "config.json"
DATA_FILE = 'data.csv'
'''
        py_file.write_text(content)

        # Parse the file
        references = parser.parse_file(str(py_file))

        # Check positions
        for ref in references:
            assert ref.line_number > 0
            assert ref.column_start >= 0
            assert ref.column_end > ref.column_start

            # Verify position makes sense
            lines = content.split("\n")
            if ref.line_number <= len(lines):
                line = lines[ref.line_number - 1]
                if ref.column_end <= len(line):
                    extracted = line[ref.column_start : ref.column_end]
                    # Should contain the link target or be part of the string
                    assert ref.link_target in extracted or ref.link_target in line

    def test_empty_file(self, temp_project_dir):
        """Test parsing an empty Python file."""
        parser = PythonParser()

        # Create empty file
        py_file = temp_project_dir / "empty.py"
        py_file.write_text("")

        # Parse the file
        references = parser.parse_file(str(py_file))

        # Should return empty list
        assert references == []

    def test_error_handling(self):
        """Test error handling for invalid files."""
        parser = PythonParser()

        # Try to parse non-existent file
        references = parser.parse_file("nonexistent.py")

        # Should return empty list without crashing
        assert references == []
