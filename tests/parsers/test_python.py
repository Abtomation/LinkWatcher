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
        assert parser.import_pattern is not None
        assert parser.quoted_pattern is not None
        assert parser.standalone_pattern is not None

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
CONFIG_FILE = "app_config.json"
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
        assert "app_config.json" in targets
        assert "templates/main.html" in targets

        # Check link types
        for ref in references:
            assert ref.link_type in ["python-quoted", "python-standalone"]

    def test_parse_string_literals(self, temp_project_dir):
        """Test parsing file references in string literals."""
        parser = PythonParser()

        # Create Python file with string references
        py_file = temp_project_dir / "config.py"
        content = '''"""Configuration module."""

# File paths in various string formats
DATABASE_URL = "sqlite:///data/app.db"
LOG_FILE = 'logs/application.log'
CONFIG_PATH = """config/settings.yaml"""
TEMPLATE_DIR = r"templates/"

# File references in f-strings
def get_file_path(name):
    return f"data/{name}.json"

# File references in multi-line strings
HELP_TEXT = """
For more information, see:
- User guide: docs/user-guide.md
- API reference: docs/api.md
"""

# Dictionary with file references
FILES = {
    "schema": "database/schema.sql",
    "migrations": "database/migrations/",
    "static": "static/css/styles.css"
}
'''
        py_file.write_text(content)

        # Parse the file
        references = parser.parse_file(str(py_file))

        # Should find file references
        assert len(references) >= 5

        # Check specific references
        targets = [ref.link_target for ref in references]
        expected_targets = [
            "data/app.db",
            "logs/application.log",
            "config/settings.yaml",
            "docs/user-guide.md",
            "docs/api.md",
            "database/schema.sql",
            "static/css/styles.css",
        ]

        for expected in expected_targets:
            assert expected in targets, f"Expected target '{expected}' not found in {targets}"

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

    def test_docstring_references(self, temp_project_dir):
        """Test parsing file references in docstrings."""
        parser = PythonParser()

        # Create Python file with docstring references
        py_file = temp_project_dir / "documented.py"
        content = '''"""
Main application module.

This module handles the core functionality. For configuration,
see "config.yaml" and for data schemas see 'schemas/user.json'.

Examples:
    Load configuration from config/app.yaml:

    >>> load_config("config/app.yaml")

See Also:
    - Documentation: docs/README.md
    - Examples: examples/basic.py
"""

def process_data():
    """
    Process data from input files.

    Reads from "input/data.csv" and writes to 'output/results.json'.

    Args:
        None

    Returns:
        bool: Success status

    See Also:
        Schema definition in schemas/data.json
    """
    pass
'''
        py_file.write_text(content)

        # Parse the file
        references = parser.parse_file(str(py_file))

        # Should find references in docstrings
        targets = [ref.link_target for ref in references]
        expected_targets = [
            "config.yaml",
            "schemas/user.json",
            "config/app.yaml",
            "docs/README.md",
            "examples/basic.py",
            "input/data.csv",
            "output/results.json",
            "schemas/data.json",
        ]

        for expected in expected_targets:
            assert expected in targets, f"Expected target '{expected}' not found in {targets}"

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

    def test_complex_python_file(self, temp_project_dir):
        """Test parsing a complex Python file."""
        parser = PythonParser()

        # Create complex Python file
        py_file = temp_project_dir / "complex.py"
        content = '''#!/usr/bin/env python3
"""
Complex Python module for testing.

Configuration files:
- Main config: "config/main.yaml"
- Database config: 'config/database.json'
"""

import os
import sys
from pathlib import Path

# Configuration
CONFIG_DIR = "config/"
MAIN_CONFIG = "config/main.yaml"
DB_CONFIG = 'config/database.json'

class DataProcessor:
    """Process data files."""

    def __init__(self):
        """Initialize with default paths."""
        self.input_dir = "data/input/"
        self.output_dir = 'data/output/'
        self.schema_file = "schemas/data.json"

    def load_template(self, name):
        """Load template file."""
        return f"templates/{name}.html"

    def process(self):
        """
        Main processing function.

        Reads from input/raw.csv and writes to output/processed.json.
        Uses schema from schemas/processing.yaml.
        """
        # Implementation here
        pass

# File mappings
FILE_MAPPINGS = {
    "users": "data/users.csv",
    "products": "data/products.json",
    "orders": "data/orders.xml"
}

# Multi-line string with file references
HELP_TEXT = """
Available data files:
- Users: data/users.csv
- Products: data/products.json
- Configuration: config/main.yaml

For more help, see docs/help.md
"""

if __name__ == "__main__":
    # Load configuration from "config/main.yaml"
    print("Starting data processor...")
'''
        py_file.write_text(content)

        # Parse the file
        references = parser.parse_file(str(py_file))

        # Should find multiple references
        assert len(references) >= 10

        # Check for expected file references
        targets = [ref.link_target for ref in references]
        expected_targets = [
            "config/main.yaml",
            "config/database.json",
            "data/input/",
            "data/output/",
            "schemas/data.json",
            "input/raw.csv",
            "output/processed.json",
            "schemas/processing.yaml",
            "data/users.csv",
            "data/products.json",
            "data/orders.xml",
            "docs/help.md",
        ]

        for expected in expected_targets:
            assert expected in targets, f"Expected target '{expected}' not found in {targets}"

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
