"""
Generic file parser for extracting file references.

This parser handles any text file and looks for file-like patterns
using simple heuristics. It's used as a fallback for unsupported file types.

AI Context
----------
- **Entry point**: ``parse_content()`` — iterates lines with a
  three-pass strategy: quoted file paths first, then quoted
  directory paths, then unquoted paths (only if no quoted paths
  matched on the same line).
- **Pattern architecture**: 3 compiled regexes in ``__init__()`` —
  ``quoted_pattern`` and ``quoted_dir_pattern`` (shared from
  ``parsers/patterns.py``), and ``unquoted_pattern`` (conservative
  bare paths with lookahead boundary, PD-BUG-080).
- **Unquoted guard**: ``_is_likely_file_reference()`` adds extra
  validation for unquoted matches — requires path separators
  (``/`` or ``\\``) or file-related keywords (``file``, ``path``,
  ``include``, etc.) on the line.  Without these indicators,
  unquoted matches are rejected to reduce false positives.
- **Fallback role**: ``YamlParser`` and ``JsonParser`` delegate to
  this parser when their structured parsing fails (YAML/JSON
  decode errors).
- **Link types**: ``GENERIC_QUOTED``, ``GENERIC_QUOTED_DIR``,
  ``GENERIC_UNQUOTED``.
- **Common tasks**:
  - Debugging false positives: check ``_is_likely_file_reference()``
    for unquoted paths, or ``_looks_like_file_path()`` /
    ``_looks_like_directory_path()`` (from ``BaseParser``) for
    quoted paths.
  - Testing: ``test/automated/parsers/test_generic.py``.
"""

import os.path
import re
from typing import List

from ..link_types import LinkType
from ..models import LinkReference
from .base import BaseParser
from .patterns import QUOTED_DIR_PATTERN, QUOTED_PATH_PATTERN


class GenericParser(BaseParser):
    """Generic parser for any text file."""

    def __init__(self):
        super().__init__()
        self.quoted_pattern = QUOTED_PATH_PATTERN
        # PD-BUG-021: Quoted directory paths (paths with separators, no extension required)
        self.quoted_dir_pattern = QUOTED_DIR_PATTERN

        # Pattern for unquoted file paths (be conservative)
        # PD-BUG-080: Use lookahead for trailing boundary so sentence punctuation
        # doesn't break the match.
        self.unquoted_pattern = re.compile(
            r"(?:^|\s)([a-zA-Z0-9_\-./\\]+\.[a-zA-Z0-9]+)(?=[.,;:!?)\]}\s]|$)"
        )

    def parse_content(self, content: str, file_path: str) -> List[LinkReference]:
        """Parse generic text content for file references."""
        try:
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
                                link_type=LinkType.GENERIC_QUOTED,
                            )
                        )

                # PD-BUG-021: Look for quoted directory paths (paths without extensions)
                for match in self.quoted_dir_pattern.finditer(line):
                    potential_dir = match.group(1)

                    # Skip if it has a file extension (already handled by quoted_pattern)
                    _, ext = os.path.splitext(potential_dir)
                    if ext:
                        continue

                    if self._looks_like_directory_path(potential_dir):
                        references.append(
                            LinkReference(
                                file_path=file_path,
                                line_number=line_num,
                                column_start=match.start(1),
                                column_end=match.end(1),
                                link_text=potential_dir,
                                link_target=potential_dir,
                                link_type=LinkType.GENERIC_QUOTED_DIR,
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
                                        link_type=LinkType.GENERIC_UNQUOTED,
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
