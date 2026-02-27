"""
Generic file parser for extracting file references.

This parser handles any text file and looks for file-like patterns
using simple heuristics. It's used as a fallback for unsupported file types.
"""

import re
from typing import List

from ..models import LinkReference
from .base import BaseParser


class GenericParser(BaseParser):
    """Generic parser for any text file."""

    def __init__(self):
        super().__init__()
        # Pattern for quoted file paths
        # Use permissive match inside quotes — _looks_like_file_path() validates later
        self.quoted_pattern = re.compile(r'[\'"]([^\'"]+\.[a-zA-Z0-9]+)[\'"]')

        # Pattern for unquoted file paths (be conservative)
        self.unquoted_pattern = re.compile(r"(?:^|\s)([a-zA-Z0-9_\-./\\]+\.[a-zA-Z0-9]+)(?:\s|$)")

    def parse_file(self, file_path: str) -> List[LinkReference]:
        """Parse generic text file for file references."""
        try:
            content = self._safe_read_file(file_path)
            lines = content.split("\n")
            references = []

            for line_num, line in enumerate(lines, 1):
                # Look for quoted file paths first (more reliable)
                for match in self.quoted_pattern.finditer(line):
                    potential_file = match.group(1)

                    if self._looks_like_file_path(potential_file):
                        references.append(
                            LinkReference(
                                file_path=file_path,
                                line_number=line_num,
                                column_start=match.start(1),
                                column_end=match.end(1),
                                link_text=potential_file,
                                link_target=potential_file,
                                link_type="generic-quoted",
                            )
                        )

                # Look for unquoted file paths (less reliable, be conservative)
                # Only if no quoted paths were found on this line
                if not self.quoted_pattern.search(line):
                    for match in self.unquoted_pattern.finditer(line):
                        potential_file = match.group(1)

                        if self._looks_like_file_path(potential_file):
                            # Additional validation for unquoted paths
                            if self._is_likely_file_reference(potential_file, line):
                                references.append(
                                    LinkReference(
                                        file_path=file_path,
                                        line_number=line_num,
                                        column_start=match.start(1),
                                        column_end=match.end(1),
                                        link_text=potential_file,
                                        link_target=potential_file,
                                        link_type="generic-unquoted",
                                    )
                                )

            return references

        except Exception as e:
            self.logger.warning("parse_error", file_path=file_path, parser="generic", error=str(e))
            return []

    def _is_likely_file_reference(self, potential_file: str, line: str) -> bool:
        """Additional validation for unquoted file paths."""
        # Skip very short or very long paths
        if len(potential_file) < 3 or len(potential_file) > 200:
            return False

        # Skip if it looks like a URL
        if potential_file.startswith(("http://", "https://", "ftp://", "mailto:")):
            return False

        # Skip if it contains suspicious characters
        suspicious_chars = ["@", ":", "?", "&", "=", "%"]
        if any(char in potential_file for char in suspicious_chars):
            return False

        # More likely if it has path separators
        if "/" in potential_file or "\\" in potential_file:
            return True

        # More likely if preceded by file-related keywords
        file_keywords = ["file", "path", "include", "load", "read", "write", "open"]
        line_lower = line.lower()
        for keyword in file_keywords:
            if keyword in line_lower:
                return True

        # Default to false for unquoted paths without strong indicators
        return False
