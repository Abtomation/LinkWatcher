"""
JSON file parser for extracting file references.

This parser handles JSON files and extracts file path references
from string values throughout the JSON structure.

AI Context
----------
- **Entry point**: ``parse_content()`` — parses JSON via
  ``json.loads()``, walks the parsed tree with
  ``_walk_structured_data()`` (inherited from ``BaseParser``),
  and processes each string value through
  ``_process_string_value()``.  Falls back to ``GenericParser``
  on ``JSONDecodeError``.
- **Pattern architecture**: No compiled regexes in this class.
  Uses ``_classify_path()`` (from ``BaseParser``) for file vs
  directory detection, and ``_path_pattern`` (from ``BaseParser``)
  for embedded path extraction.
- **Duplicate handling**: A ``claimed`` set of ``(value, line_num)``
  tuples prevents the same JSON value on the same line from being
  matched twice (PD-BUG-013).  ``_find_unclaimed_line()`` scans
  forward from ``_search_start_line`` for O(V+L) amortized
  performance.
- **Embedded path extraction**: ``_extract_embedded_paths()``
  handles compound strings containing spaces (PD-BUG-061), e.g.
  ``"Bash(python doc/scripts/run.py *)"``.
- **Link types**: ``JSON``, ``JSON_DIR``.
- **Common tasks**:
  - Debugging missed paths: check ``_classify_path()`` in
    ``base.py`` — it determines file vs directory classification.
  - Debugging duplicate matches: check the ``claimed`` set logic
    in ``_process_string_value()`` and ``_find_unclaimed_line()``.
  - Testing: ``test/automated/parsers/test_json.py``.
"""

import json
from typing import List

from ..link_types import LinkType
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

                # Walk the parsed tree and process each string value
                for value, _path in self._walk_structured_data(data):
                    self._process_string_value(value, file_path, lines, references, claimed)

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

    def _process_string_value(
        self,
        data: str,
        file_path: str,
        lines: List[str],
        references: List[LinkReference],
        claimed: set,
    ):
        """Process a single string value from the JSON tree."""
        # PD-BUG-061: If the string contains spaces, it may be a compound
        # command string with embedded paths (e.g., "Bash(python doc/scripts/run.py *)").
        # Try sub-path extraction first; fall through to whole-string check if nothing found.
        if " " in data:
            embedded = self._extract_embedded_paths(data, file_path, lines, references, claimed)
            if embedded:
                return

        # Check for file paths (with extension) or directory paths (PD-BUG-030)
        is_file, is_dir = self._classify_path(data)

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
                        link_type=LinkType.JSON_DIR if is_dir else LinkType.JSON,
                    )
                )

    def _extract_embedded_paths(
        self,
        data: str,
        file_path: str,
        lines: List[str],
        references: List[LinkReference],
        claimed: set,
    ) -> bool:
        """
        PD-BUG-061: Extract file paths embedded within compound strings.

        When a JSON string value contains spaces (e.g., a permission pattern like
        "Bash(python doc/scripts/run.py *)"), scan for path-like substrings
        using a regex pattern.

        Returns True if any embedded paths were found.
        """
        found = False
        line_num = 0
        val_col_start = 0
        for match in self._path_pattern.finditer(data):
            candidate = match.group(1)
            if "/" not in candidate and "\\" not in candidate:
                continue
            if self._looks_like_file_path(candidate):
                if not found:
                    line_num = self._find_unclaimed_line(
                        lines, data, claimed, self._search_start_line
                    )
                    if line_num == 0:
                        return False
                    claimed.add((data, line_num))
                    self._search_start_line = line_num - 1
                    line_content = lines[line_num - 1]
                    val_col_start = line_content.find(data)
                    if val_col_start < 0:
                        val_col_start = 0
                col_start = val_col_start + match.start(1)
                col_end = val_col_start + match.end(1)
                references.append(
                    LinkReference(
                        file_path=file_path,
                        line_number=line_num,
                        column_start=col_start,
                        column_end=col_end,
                        link_text=candidate,
                        link_target=candidate,
                        link_type=LinkType.JSON,
                    )
                )
                found = True
        return found
