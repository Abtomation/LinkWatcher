"""
Base parser interface for file type specific parsers.

This module defines the common interface that all parsers must implement.
"""

import os.path
import re
from abc import ABC, abstractmethod
from typing import Generator, List, Tuple

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

    # --- Shared structured-data helpers (TD-180) ---

    #: Regex for extracting file paths from compound strings.
    #: Shared by YAML and JSON parsers (PD-BUG-060, PD-BUG-061).
    _path_pattern = re.compile(r"([a-zA-Z0-9_\-./\\]+\.[a-zA-Z0-9]+)")

    @staticmethod
    def _walk_structured_data(data) -> Generator[Tuple[str, str], None, None]:
        """Yield ``(value, yaml_path)`` for every string leaf in a nested dict/list structure.

        This captures the recursive tree-walk logic shared by YAML and JSON parsers.
        Non-string leaves (int, float, bool, None) are silently skipped.

        Items are yielded in insertion order (matching the original recursive traversal)
        to preserve the ``_search_start_line`` forward-scan optimisation used by both parsers.
        """
        stack = [(data, "")]
        while stack:
            node, path = stack.pop()
            if isinstance(node, dict):
                # Push in reverse so that the first key is popped (processed) first.
                for key, value in reversed(list(node.items())):
                    stack.append((value, f"{path}.{key}"))
            elif isinstance(node, list):
                for i in range(len(node) - 1, -1, -1):
                    stack.append((node[i], f"{path}[{i}]"))
            elif isinstance(node, str):
                yield node, path

    def _classify_path(self, text: str) -> Tuple[bool, bool]:
        """Classify *text* as a file path, directory path, or neither.

        Returns ``(is_file, is_dir)``.  At most one will be True.
        """
        is_file = self._looks_like_file_path(text)
        if is_file:
            return True, False
        _, ext = os.path.splitext(text)
        if not ext and self._looks_like_directory_path(text):
            return False, True
        return False, False
