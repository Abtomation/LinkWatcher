"""
Main link parser that coordinates file-type specific parsers.

This module provides the main LinkParser class that delegates to
specialized parsers based on file type.
"""

import os
from typing import List

from .logging import LogTimer, get_logger
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
        self.logger = get_logger()

    def parse_file(self, file_path: str) -> List[LinkReference]:
        """Parse a file and extract all link references."""
        try:
            file_ext = os.path.splitext(file_path)[1].lower()

            with LogTimer("file_parsing", self.logger, file_path=file_path, file_ext=file_ext):
                # Use specialized parser if available
                if file_ext in self.parsers:
                    parser = self.parsers[file_ext]
                    self.logger.debug(
                        "using_specialized_parser",
                        file_path=file_path,
                        parser_type=type(parser).__name__,
                    )
                    return parser.parse_file(file_path)
                else:
                    # Fall back to generic parser
                    self.logger.debug(
                        "using_generic_parser", file_path=file_path, file_ext=file_ext
                    )
                    return self.generic_parser.parse_file(file_path)

        except Exception as e:
            self.logger.warning(
                "file_parsing_failed",
                file_path=file_path,
                error=str(e),
                error_type=type(e).__name__,
            )
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
