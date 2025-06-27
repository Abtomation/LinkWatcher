"""
Main link parser that coordinates file-type specific parsers.

This module provides the main LinkParser class that delegates to
specialized parsers based on file type.
"""

import os
from typing import List

from .models import LinkReference
from .parsers import DartParser, GenericParser, JsonParser, MarkdownParser, PythonParser, YamlParser


class LinkParser:
    """
    Main parser that coordinates file-type specific parsers.
    This provides a unified interface while delegating to specialized parsers.
    """

    def __init__(self):
        self.parsers = {
            ".md": MarkdownParser(),
            ".yaml": YamlParser(),
            ".yml": YamlParser(),
            ".json": JsonParser(),
            ".dart": DartParser(),
            ".py": PythonParser(),
        }
        self.generic_parser = GenericParser()

    def parse_file(self, file_path: str) -> List[LinkReference]:
        """Parse a file and extract all link references."""
        try:
            file_ext = os.path.splitext(file_path)[1].lower()

            # Use specialized parser if available
            if file_ext in self.parsers:
                parser = self.parsers[file_ext]
                return parser.parse_file(file_path)
            else:
                # Fall back to generic parser
                return self.generic_parser.parse_file(file_path)

        except Exception as e:
            print(f"Warning: Could not parse {file_path}: {e}")
            return []

    def add_parser(self, extension: str, parser):
        """Add a custom parser for a specific file extension."""
        self.parsers[extension.lower()] = parser

    def remove_parser(self, extension: str):
        """Remove a parser for a specific file extension."""
        self.parsers.pop(extension.lower(), None)

    def get_supported_extensions(self) -> List[str]:
        """Get list of supported file extensions."""
        return list(self.parsers.keys())
