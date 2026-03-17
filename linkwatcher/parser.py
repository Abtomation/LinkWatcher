"""
Main link parser that coordinates file-type specific parsers.

This module provides the main LinkParser class that delegates to
specialized parsers based on file type.
"""

import os
from typing import List, Optional

from .config.settings import LinkWatcherConfig
from .logging import LogTimer, get_logger
from .models import LinkReference
from .parsers import (
    DartParser,
    GenericParser,
    JsonParser,
    MarkdownParser,
    PowerShellParser,
    PythonParser,
    YamlParser,
)


class LinkParser:
    """
    Main parser that coordinates file-type specific parsers.
    This provides a unified interface while delegating to specialized parsers.
    """

    def __init__(self, config: Optional[LinkWatcherConfig] = None):
        self.parsers = {}
        self.logger = get_logger()

        if config is None or config.enable_markdown_parser:
            self.parsers[".md"] = MarkdownParser()
        if config is None or config.enable_yaml_parser:
            yaml_parser = YamlParser()
            self.parsers[".yaml"] = yaml_parser
            self.parsers[".yml"] = yaml_parser
        if config is None or config.enable_json_parser:
            self.parsers[".json"] = JsonParser()
        if config is None or config.enable_dart_parser:
            self.parsers[".dart"] = DartParser()
        if config is None or config.enable_python_parser:
            self.parsers[".py"] = PythonParser()
        if config is None or config.enable_powershell_parser:
            ps_parser = PowerShellParser()
            self.parsers[".ps1"] = ps_parser
            self.parsers[".psm1"] = ps_parser

        self.generic_parser = (
            GenericParser() if (config is None or config.enable_generic_parser) else None
        )

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
                elif self.generic_parser is not None:
                    # Fall back to generic parser
                    self.logger.debug(
                        "using_generic_parser", file_path=file_path, file_ext=file_ext
                    )
                    return self.generic_parser.parse_file(file_path)
                else:
                    self.logger.debug("no_parser_available", file_path=file_path, file_ext=file_ext)
                    return []

        except Exception as e:
            self.logger.warning(
                "file_parsing_failed",
                file_path=file_path,
                error=str(e),
                error_type=type(e).__name__,
            )
            return []

    def parse_content(self, content: str, file_path: str) -> List[LinkReference]:
        """Parse already-read content for link references.

        Args:
            content: The file content to parse
            file_path: Path used for routing to the correct parser and for LinkReference entries
        """
        try:
            file_ext = os.path.splitext(file_path)[1].lower()

            with LogTimer("content_parsing", self.logger, file_path=file_path, file_ext=file_ext):
                # Use specialized parser if available
                if file_ext in self.parsers:
                    parser = self.parsers[file_ext]
                    self.logger.debug(
                        "using_specialized_parser",
                        file_path=file_path,
                        parser_type=type(parser).__name__,
                    )
                    return parser.parse_content(content, file_path)
                elif self.generic_parser is not None:
                    # Fall back to generic parser
                    self.logger.debug(
                        "using_generic_parser", file_path=file_path, file_ext=file_ext
                    )
                    return self.generic_parser.parse_content(content, file_path)
                else:
                    self.logger.debug("no_parser_available", file_path=file_path, file_ext=file_ext)
                    return []

        except Exception as e:
            self.logger.warning(
                "content_parsing_failed",
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
