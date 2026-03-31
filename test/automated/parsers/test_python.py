"""
Tests for the Python parser.

This module tests Python-specific link parsing functionality.
"""

import pytest

from linkwatcher.parsers.python import PythonParser

pytestmark = [
    pytest.mark.feature("2.1.1"),
    pytest.mark.priority("Critical"),
    pytest.mark.test_type("parser"),
    pytest.mark.specification(
        "test/specifications/feature-specs/test-spec-2-1-1-link-parsing-system.md"
    ),
]


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

    def test_quoted_directory_paths(self, temp_project_dir):
        """Test that quoted directory paths (no file extension) are detected.

        Regression test for PD-BUG-056: Python parser did not detect string
        literals containing directory paths like "vendor/tools/build".
        The parser only used QUOTED_PATH_PATTERN (requires file extension) and
        missed directory references entirely.
        """
        parser = PythonParser()

        dir_a = "vendor/tools/build"
        dir_b = "vendor/tools/templates"
        dir_c = "test/automated/unit"
        dir_d = "src/components/ui/widgets"

        py_file = temp_project_dir / "dir_paths.py"
        content = (
            '"""Module with directory path references."""\n\n'
            f'SCRIPTS_DIR = "{dir_a}"\n'
            f'TEMPLATES_DIR = "{dir_b}"\n'
            f'OUTPUT_DIR = "{dir_c}"\n'
            f'NESTED_DIR = "{dir_d}"\n'
        )
        py_file.write_text(content)

        references = parser.parse_file(str(py_file))
        targets = [ref.link_target for ref in references]

        # Should find directory path references
        assert dir_a in targets
        assert dir_b in targets
        assert dir_c in targets
        assert dir_d in targets

        # All should be python-quoted-dir type
        dir_refs = [r for r in references if r.link_type == "python-quoted-dir"]
        assert len(dir_refs) >= 4

    def test_quoted_directory_paths_no_false_positives(self, temp_project_dir):
        """Test that non-directory strings are not falsely detected as directories.

        Regression test for PD-BUG-056: ensures the directory path detection
        doesn't introduce false positives for version strings, URLs, etc.
        """
        parser = PythonParser()

        py_file = temp_project_dir / "no_false_dirs.py"
        content = '''"""Module with non-directory strings."""

VERSION = "1.2.3"
NAME = "hello world"
URL = "https://example.com/api"
SINGLE = "simple"
'''
        py_file.write_text(content)

        references = parser.parse_file(str(py_file))
        targets = [ref.link_target for ref in references]

        # None of these should be detected as directory paths
        assert "1.2.3" not in targets
        assert "hello world" not in targets
        assert "https://example.com/api" not in targets
        assert "simple" not in targets

    def test_error_handling(self):
        """Test error handling for invalid files."""
        parser = PythonParser()

        # Try to parse non-existent file
        references = parser.parse_file("nonexistent.py")

        # Should return empty list without crashing
        assert references == []


class TestPythonParserDocstrings:
    """PD-BUG-062: Python parser detects file paths inside triple-quoted docstrings."""

    def test_docstring_with_file_paths(self):
        """File paths in docstrings should be detected."""
        parser = PythonParser()
        content = (
            '"""Usage:\n'
            "    python doc/scripts/feedback_db.py init\n"
            "    python doc/scripts/feedback_db.py record --json input.json\n"
            '"""\n'
        )
        references = parser.parse_content(content, "script.py")
        targets = [ref.link_target for ref in references]
        assert "doc/scripts/feedback_db.py" in targets

    def test_docstring_with_directory_paths(self):
        """Directory paths in docstrings should be detected."""
        parser = PythonParser()
        content = (
            '"""Templates in doc/scripts/templates/support/ are used for generation.\n' '"""\n'
        )
        references = parser.parse_content(content, "script.py")
        targets = [ref.link_target for ref in references]
        assert any("doc/scripts/templates/support" in t for t in targets)

    def test_docstring_single_line(self):
        """Single-line docstring with path on the same line as triple-quotes."""
        parser = PythonParser()
        content = '"""See doc/scripts/feedback_db.py for details."""\n'
        references = parser.parse_content(content, "script.py")
        targets = [ref.link_target for ref in references]
        assert "doc/scripts/feedback_db.py" in targets

    def test_docstring_single_quotes(self):
        """Triple single-quoted docstrings should also be detected."""
        parser = PythonParser()
        content = "'''Usage:\n" "    python doc/scripts/feedback_db.py init\n" "'''\n"
        references = parser.parse_content(content, "script.py")
        targets = [ref.link_target for ref in references]
        assert "doc/scripts/feedback_db.py" in targets

    def test_docstring_link_type(self):
        """Docstring references should have python-docstring link type."""
        parser = PythonParser()
        content = '"""Usage:\n' "    python doc/scripts/feedback_db.py init\n" '"""\n'
        references = parser.parse_content(content, "script.py")
        file_refs = [r for r in references if r.link_target == "doc/scripts/feedback_db.py"]
        assert len(file_refs) >= 1
        assert file_refs[0].link_type == "python-docstring"

    def test_non_docstring_code_unaffected(self):
        """Normal quoted strings outside docstrings should still use python-quoted type."""
        parser = PythonParser()
        content = '"""Module docstring."""\n' 'path = "src/utils/helpers.py"\n'
        references = parser.parse_content(content, "script.py")
        quoted_refs = [r for r in references if r.link_target == "src/utils/helpers.py"]
        assert len(quoted_refs) >= 1
        assert quoted_refs[0].link_type == "python-quoted"

    def test_docstring_does_not_leak(self):
        """Lines after closing triple-quote should not be treated as docstring."""
        parser = PythonParser()
        content = '"""Docstring."""\n' "# comment with src/utils/helpers.py\n"
        references = parser.parse_content(content, "script.py")
        comment_refs = [r for r in references if r.link_target == "src/utils/helpers.py"]
        assert len(comment_refs) >= 1
        assert comment_refs[0].link_type == "python-comment"
