"""
JSON file parser for extracting file references.

This parser handles JSON files and extracts file path references
from string values throughout the JSON structure.
"""

import json
import os.path
from typing import List

from ..models import LinkReference
from .base import BaseParser


class JsonParser(BaseParser):
    """Parser for JSON files (.json)."""

    def parse_content(self, content: str, file_path: str) -> List[LinkReference]:
        """Parse JSON content for file references."""
        try:
            lines = content.split("\n")
            references = []

            try:
                # Parse JSON to find file references
                data = json.loads(content)

                # Track claimed (value, line) pairs to handle duplicate values (PD-BUG-013)
                claimed = set()
                self._search_start_line = 0  # Offset for O(V+L) scanning
                self._extract_json_file_refs(data, file_path, lines, references, claimed)

            except json.JSONDecodeError:
                # Fall back to generic parsing if JSON is invalid
                from .generic import GenericParser

                generic_parser = GenericParser()
                return generic_parser.parse_content(content, file_path)

            return references

        except Exception as e:
            self.logger.warning("parse_error", file_path=file_path, parser="json", error=str(e))
            return []

    @staticmethod
    def _find_unclaimed_line(
        lines: List[str], search_text: str, claimed: set, start_line: int = 0
    ) -> int:
        """Find next line containing search_text not yet claimed for this value (PD-BUG-013).

        Scans from start_line for O(V+L) amortized performance instead of O(V*L).
        Falls back to scanning lines before start_line for out-of-order edge cases.
        """
        # Scan from start_line forward
        for i in range(start_line, len(lines)):
            if search_text in lines[i] and (search_text, i + 1) not in claimed:
                return i + 1
        # Fallback: scan lines before start_line
        for i in range(0, start_line):
            if search_text in lines[i] and (search_text, i + 1) not in claimed:
                return i + 1
        return 0

    def _extract_json_file_refs(
        self,
        data,
        file_path: str,
        lines: List[str],
        references: List[LinkReference],
        claimed: set,
        path="",
    ):
        """Recursively extract file references from JSON data."""
        if isinstance(data, dict):
            for key, value in data.items():
                self._extract_json_file_refs(
                    value, file_path, lines, references, claimed, f"{path}.{key}"
                )
        elif isinstance(data, list):
            for i, item in enumerate(data):
                self._extract_json_file_refs(
                    item, file_path, lines, references, claimed, f"{path}[{i}]"
                )
        elif isinstance(data, str):
            # Check for file paths (with extension) or directory paths (PD-BUG-030)
            is_file = self._looks_like_file_path(data)
            is_dir = False
            if not is_file:
                _, ext = os.path.splitext(data)
                if not ext:
                    is_dir = self._looks_like_directory_path(data)

            if is_file or is_dir:
                # Find the next unclaimed line for this value (PD-BUG-013)
                line_num = self._find_unclaimed_line(lines, data, claimed, self._search_start_line)
                if line_num > 0:
                    claimed.add((data, line_num))
                    self._search_start_line = line_num - 1  # Resume from this line next time
                    # Find the column position
                    line_content = lines[line_num - 1]
                    col_start = line_content.find(f'"{data}"')
                    if col_start >= 0:
                        col_start += 1  # Skip opening quote
                        col_end = col_start + len(data)
                    else:
                        col_start = line_content.find(data)
                        col_end = col_start + len(data) if col_start >= 0 else 0

                    references.append(
                        LinkReference(
                            file_path=file_path,
                            line_number=line_num,
                            column_start=col_start,
                            column_end=col_end,
                            link_text=data,
                            link_target=data,
                            link_type="json-dir" if is_dir else "json",
                        )
                    )
