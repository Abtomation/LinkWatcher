"""
Tests for the Python parser.

This module tests Python-specific link parsing functionality.
"""

import pytest

from linkwatcher.link_types import LinkType
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
            "    python alpha-project/scripts/feedback_db.py init\n"
            "    python alpha-project/scripts/feedback_db.py record --json input.json\n"
            '"""\n'
        )
        references = parser.parse_content(content, "script.py")
        targets = [ref.link_target for ref in references]
        assert "alpha-project/scripts/feedback_db.py" in targets

    def test_docstring_with_directory_paths(self):
        """Directory paths in docstrings should be detected."""
        parser = PythonParser()
        content = (
            '"""Templates in alpha-project/scripts/templates/support/ are used for generation.\n'
            '"""\n'
        )
        references = parser.parse_content(content, "script.py")
        targets = [ref.link_target for ref in references]
        assert any("alpha-project/scripts/templates/support" in t for t in targets)

    def test_docstring_single_line(self):
        """Single-line docstring with path on the same line as triple-quotes."""
        parser = PythonParser()
        content = '"""See alpha-project/scripts/feedback_db.py for details."""\n'
        references = parser.parse_content(content, "script.py")
        targets = [ref.link_target for ref in references]
        assert "alpha-project/scripts/feedback_db.py" in targets

    def test_docstring_single_quotes(self):
        """Triple single-quoted docstrings should also be detected."""
        parser = PythonParser()
        content = "'''Usage:\n" "    python alpha-project/scripts/feedback_db.py init\n" "'''\n"
        references = parser.parse_content(content, "script.py")
        targets = [ref.link_target for ref in references]
        assert "alpha-project/scripts/feedback_db.py" in targets

    def test_docstring_link_type(self):
        """Docstring references should have python-docstring link type."""
        parser = PythonParser()
        content = '"""Usage:\n' "    python alpha-project/scripts/feedback_db.py init\n" '"""\n'
        references = parser.parse_content(content, "script.py")
        file_refs = [
            r for r in references if r.link_target == "alpha-project/scripts/feedback_db.py"
        ]
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


class TestDocstringColumnPositions:
    """PD-BUG-118 (Defect A) regression: docstring extraction on a line that
    CONTAINS triple quotes recorded column offsets relative to the extracted
    docstring text (``inner``), not the physical line.

    ``parse_content`` builds ``inner`` from ``_TRIPLE_QUOTE_RE.split(line)`` and
    then stored ``match.start()`` directly as ``column_start``.  The offset of
    the docstring content within the line (e.g. ``len('    \"\"\"') == 7``) was
    dropped, so every recorded column was short by that amount.  The updater's
    ``_replace_at_position`` slices the line at those columns, consuming and
    duplicating characters adjacent to the real target.

    The invariant these tests pin is simple and total: for EVERY reference the
    parser emits, ``line[column_start:column_end]`` must equal ``link_target``.
    A pure docstring *body* line (no triple quotes) was always correct — it is
    kept here as the control that discriminates the buggy branch from the sound
    one.
    """

    def _assert_columns_are_line_absolute(self, parser, content, file_path="script.py"):
        """Every emitted ref must slice back to its own link_target."""
        lines = content.split("\n")
        references = parser.parse_content(content, file_path)
        assert references, "expected at least one reference"
        for ref in references:
            line = lines[ref.line_number - 1]
            sliced = line[ref.column_start : ref.column_end]
            assert sliced == ref.link_target, (
                f"column drift: type={ref.link_type} target={ref.link_target!r} "
                f"cols=[{ref.column_start},{ref.column_end}) sliced={sliced!r} "
                f"line={line!r}"
            )
        return references

    def test_docstring_dir_columns_on_triple_quote_line(self):
        """The exact PD-BUG-118 evidence line from performance_db.py."""
        parser = PythonParser()
        line = '    """Resolve database path to test/state-tracking/permanent/."""'
        content = "def _resolve_db_path():\n" + line + "\n"
        refs = self._assert_columns_are_line_absolute(parser, content)

        # Defect C trims the swallowed sentence period, so the target is the
        # directory itself — trailing separator kept, punctuation excluded.
        dir_refs = [r for r in refs if r.link_target == "test/state-tracking/permanent/"]
        assert len(dir_refs) == 1, "expected the docstring directory reference"
        ref = dir_refs[0]
        # Pin the true position explicitly — the shift was exactly len('    """').
        assert ref.column_start == line.index("test/state-tracking/permanent/")
        assert ref.column_start != 25, "regression: column recorded relative to inner text"
        # The sentence period must sit OUTSIDE the replaced span.
        assert line[ref.column_end] == ".", "sentence period is inside the replaced span"

    def test_docstring_file_columns_on_triple_quote_line(self):
        """File paths (with extension) on a triple-quote line — python-docstring type."""
        parser = PythonParser()
        line = '    """See doc/user/handbooks/quick-reference.md for details."""'
        content = "def f():\n" + line + "\n"
        self._assert_columns_are_line_absolute(parser, content)

    def test_deeper_indentation_shifts_columns_further(self):
        """Indentation is part of the dropped offset — deeper nesting drifts more."""
        parser = PythonParser()
        line = '            """Templates in process-framework/templates/support/."""'
        content = "class A:\n    def f(self):\n        def g():\n" + line + "\n"
        self._assert_columns_are_line_absolute(parser, content)

    def test_two_docstring_segments_on_one_line(self):
        """Two triple-quoted segments on one line.

        ``inner`` joins disjoint segments with a space, so a single scalar
        offset cannot describe both — only span-aware scanning of the real line
        keeps columns correct for the SECOND segment.  This is the case that
        discriminates a span-based fix from an add-one-offset fix.
        """
        parser = PythonParser()
        line = 'x = """doc/alpha/beta/""" + """doc/gamma/delta/"""'
        content = line + "\n"
        refs = self._assert_columns_are_line_absolute(parser, content)
        targets = {r.link_target for r in refs}
        assert "doc/gamma/delta/" in targets, "second segment's path must still be found"

    def test_docstring_body_line_columns_unchanged(self):
        """Control: a pure docstring body line has no triple quotes and was
        always correct.  It must stay correct after the fix."""
        parser = PythonParser()
        body = "    Resolve database path to test/state-tracking/permanent/."
        content = 'def f():\n    """\n' + body + '\n    """\n'
        refs = self._assert_columns_are_line_absolute(parser, content)
        assert any(r.link_target == "test/state-tracking/permanent/" for r in refs)

    def test_code_after_closing_quotes_on_same_line(self):
        """Text outside the triple quotes must not be scanned as docstring, and
        any reference found there must still carry line-absolute columns."""
        parser = PythonParser()
        line = '    """Docs in doc/alpha/beta/."""  # see doc/gamma/delta/notes.md'
        content = "def f():\n" + line + "\n"
        self._assert_columns_are_line_absolute(parser, content)

    def test_sentence_period_not_swallowed_into_directory_target(self):
        """PD-BUG-118 (Defect C): _BARE_DIR_RE's character class contains '.', so
        a sentence-ending period after a trailing separator was captured as part
        of the path.  Everything inside the recorded span is destroyed by the
        rewrite, so the period was eaten from the prose."""
        parser = PythonParser()
        line = '    """Resolve database path to test/state-tracking/permanent/."""'
        content = "def f():\n" + line + "\n"
        refs = self._assert_columns_are_line_absolute(parser, content)

        dir_refs = [r for r in refs if r.link_type == LinkType.PYTHON_DOCSTRING_DIR]
        assert dir_refs, "expected a docstring directory reference"
        target = dir_refs[0].link_target
        assert (
            target == "test/state-tracking/permanent/"
        ), "sentence punctuation captured into the link target: {!r}".format(target)
        assert not target.endswith("."), "trailing sentence period still in target"

    def test_trailing_period_without_slash_trimmed(self):
        """A path ending in a period but no trailing slash is trimmed too."""
        parser = PythonParser()
        line = '    """Config lives in doc/state-tracking/permanent."""'
        content = "def f():\n" + line + "\n"
        refs = self._assert_columns_are_line_absolute(parser, content)
        dir_refs = [r for r in refs if r.link_type == LinkType.PYTHON_DOCSTRING_DIR]
        assert dir_refs, "expected a docstring directory reference"
        assert dir_refs[0].link_target == "doc/state-tracking/permanent"

    def test_backticked_path_in_docstring_keeps_delimiters(self):
        """The reported 'eaten closing backtick' shape: a backticked path inside a
        docstring must slice back exactly, leaving both backticks outside the span."""
        parser = PythonParser()
        line = '    """See `doc/state-tracking/` for status."""'
        content = "def f():\n" + line + "\n"
        refs = self._assert_columns_are_line_absolute(parser, content)
        targets = [r.link_target for r in refs]
        assert "doc/state-tracking/" in targets, "expected the backticked directory path"
        for ref in refs:
            assert "`" not in ref.link_target, "backtick captured into target: {!r}".format(
                ref.link_target
            )
