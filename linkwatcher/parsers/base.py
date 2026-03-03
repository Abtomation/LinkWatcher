"""
Base parser interface for file type specific parsers.

This module defines the common interface that all parsers must implement.
"""

from abc import ABC, abstractmethod
from typing import List

from ..logging import get_logger
from ..models import LinkReference
from ..utils import (
    find_line_number,
    looks_like_directory_path,
    looks_like_file_path,
    safe_file_read,
)


class BaseParser(ABC):
    """
    Abstract base class for file parsers.

    All file type specific parsers should inherit from this class
    and implement the parse_content method.
    """

    def __init__(self):
        self.logger = get_logger()

    def parse_file(self, file_path: str) -> List[LinkReference]:
        """
        Read a file and parse its content for link references.

        Args:
            file_path: Path to the file to parse

        Returns:
            List of LinkReference objects found in the file
        """
        try:
            content = self._safe_read_file(file_path)
            return self.parse_content(content, file_path)
        except Exception as e:
            self.logger.warning(
                "parse_error",
                file_path=file_path,
                parser=type(self).__name__,
                error=str(e),
            )
            return []

    @abstractmethod
    def parse_content(self, content: str, file_path: str) -> List[LinkReference]:
        """
        Parse content string for link references.

        Args:
            content: The file content to parse
            file_path: Path used for LinkReference entries (not read from disk)

        Returns:
            List of LinkReference objects found in the content
        """
        pass

    def _looks_like_file_path(self, text: str) -> bool:
        """Check if text looks like a file path."""
        return looks_like_file_path(text)

    def _looks_like_directory_path(self, text: str) -> bool:
        """Check if text looks like a directory path (PD-BUG-021)."""
        return looks_like_directory_path(text)

    def _safe_read_file(self, file_path: str) -> str:
        """Safely read file content."""
        return safe_file_read(file_path)

    def _find_line_number(self, lines: List[str], search_text: str) -> int:
        """Find line number containing specific text."""
        return find_line_number(lines, search_text)
