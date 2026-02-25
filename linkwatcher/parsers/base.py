"""
Base parser interface for file type specific parsers.

This module defines the common interface that all parsers must implement.
"""

from abc import ABC, abstractmethod
from typing import List

from ..logging import get_logger
from ..models import LinkReference
from ..utils import find_line_number, looks_like_file_path, safe_file_read


class BaseParser(ABC):
    """
    Abstract base class for file parsers.

    All file type specific parsers should inherit from this class
    and implement the parse_file method.
    """

    def __init__(self):
        self.logger = get_logger()

    @abstractmethod
    def parse_file(self, file_path: str) -> List[LinkReference]:
        """
        Parse a file and extract all link references.

        Args:
            file_path: Path to the file to parse

        Returns:
            List of LinkReference objects found in the file
        """
        pass

    def _looks_like_file_path(self, text: str) -> bool:
        """Check if text looks like a file path."""
        return looks_like_file_path(text)

    def _safe_read_file(self, file_path: str) -> str:
        """Safely read file content."""
        return safe_file_read(file_path)

    def _find_line_number(self, lines: List[str], search_text: str) -> int:
        """Find line number containing specific text."""
        return find_line_number(lines, search_text)
