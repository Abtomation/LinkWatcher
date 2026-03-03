"""
JSON file parser for extracting file references.

This parser handles JSON files and extracts file path references
from string values throughout the JSON structure.
"""

import json
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
    def _find_unclaimed_line(lines: List[str], search_text: str, claimed: set) -> int:
        """Find next line containing search_text not yet claimed for this value (PD-BUG-013)."""
        for i, line in enumerate(lines, 1):
            if search_text in line and (search_text, i) not in claimed:
                return i
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
        elif isinstance(data, str) and self._looks_like_file_path(data):
            # Find the next unclaimed line for this value (PD-BUG-013)
            line_num = self._find_unclaimed_line(lines, data, claimed)
            if line_num > 0:
                claimed.add((data, line_num))
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
                        link_type="json",
                    )
                )
