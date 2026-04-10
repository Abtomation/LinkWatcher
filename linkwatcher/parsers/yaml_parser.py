"""
YAML file parser for extracting file references.

This parser handles YAML files and extracts file path references
from values throughout the YAML structure.

AI Context
----------
- **Entry point**: ``parse_content()`` — parses YAML via
  ``yaml.safe_load()``, walks the parsed tree with
  ``_walk_structured_data()`` (inherited from ``BaseParser``),
  and processes each string value through
  ``_process_string_value()``.  Falls back to ``GenericParser``
  on ``YAMLError``.
- **Pattern architecture**: No compiled regexes in this class.
  Uses ``_classify_path()`` (from ``BaseParser``) for file vs
  directory detection, and ``_path_pattern`` (from ``BaseParser``)
  for embedded path extraction.
- **Embedded path extraction**: ``_extract_embedded_paths()``
  handles compound strings containing spaces (PD-BUG-060), e.g.
  ``"pwsh.exe -File doc/scripts/Run.ps1"``.  Supports multiline
  YAML blocks (literal ``|`` / folded ``>``) where
  ``yaml.safe_load()`` resolves newlines (PD-BUG-079).
- **Line mapping**: ``_find_next_occurrence()`` with
  ``_search_start_line`` offset provides O(V+L) amortized
  line-number lookup for parsed values back to raw lines.
- **Link types**: ``YAML``, ``YAML_DIR``.
- **Common tasks**:
  - Debugging missed paths: check ``_classify_path()`` in
    ``base.py`` — it determines file vs directory classification.
  - Debugging embedded paths: check ``_extract_embedded_paths()``
    and the ``_path_pattern`` regex in ``base.py``.
  - Testing: ``test/automated/parsers/test_yaml.py``.
"""

from typing import List

import yaml

from ..link_types import LinkType
from ..models import LinkReference
from .base import BaseParser


class YamlParser(BaseParser):
    """Parser for YAML files (.yaml, .yml)."""

    def parse_content(self, content: str, file_path: str) -> List[LinkReference]:
        """Parse YAML content for file references."""
        try:
            lines = content.split("\n")
            references = []
            self._search_start_line = 0  # Offset for O(V+L) scanning

            try:
                # Parse YAML to find file references
                data = yaml.safe_load(content)

                # Walk the parsed tree and process each string value
                for value, _path in self._walk_structured_data(data):
                    self._process_string_value(value, file_path, lines, references)

            except yaml.YAMLError:
                # Fall back to generic parsing if YAML is invalid
                from .generic import GenericParser

                generic_parser = GenericParser()
                return generic_parser.parse_content(content, file_path)

            return references

        except Exception as e:
            self.logger.warning("parse_error", file_path=file_path, parser="yaml", error=str(e))
            return []

    def _process_string_value(
        self, data: str, file_path: str, lines: List[str], references: List[LinkReference]
    ):
        """Process a single string value from the YAML tree."""
        # PD-BUG-060: If the string contains spaces, it may be a compound
        # command string with embedded paths (e.g., "pwsh.exe -File doc/scripts/Run.ps1").
        # Try sub-path extraction first; fall through to whole-string check if nothing found.
        if " " in data:
            embedded = self._extract_embedded_paths(data, file_path, lines, references)
            if embedded:
                return

        # Check for file paths (with extension) or directory paths (PD-BUG-030)
        is_file, is_dir = self._classify_path(data)

        if is_file or is_dir:
            # Find all occurrences of this value to get accurate line numbers
            line_num, col_start = self._find_next_occurrence(lines, data, references)
            if line_num > 0:
                col_end = col_start + len(data) if col_start >= 0 else 0

                references.append(
                    LinkReference(
                        file_path=file_path,
                        line_number=line_num,
                        column_start=col_start,
                        column_end=col_end,
                        link_text=data,
                        link_target=data,
                        link_type=LinkType.YAML_DIR if is_dir else LinkType.YAML,
                    )
                )

    def _find_next_occurrence(
        self, lines: List[str], search_text: str, existing_refs: List[LinkReference]
    ) -> tuple:
        """
        Find the next occurrence of search_text that hasn't been used yet.
        Returns (line_number, column_start) or (0, 0) if not found.
        """
        # Get positions of already found references for this text
        used_positions = set()
        for ref in existing_refs:
            if ref.link_target == search_text:
                used_positions.add((ref.line_number, ref.column_start))

        # Scan from the last-found line (values appear in file order)
        start = self._search_start_line
        for line_idx in range(start, len(lines)):
            line = lines[line_idx]
            line_num = line_idx + 1
            col_start = 0
            while True:
                col_start = line.find(search_text, col_start)
                if col_start == -1:
                    break

                pos = (line_num, col_start)
                if pos not in used_positions:
                    self._search_start_line = line_idx
                    return line_num, col_start

                col_start += 1  # Move past this occurrence

        # Fallback: scan lines before start (handles out-of-order edge cases)
        for line_idx in range(0, start):
            line = lines[line_idx]
            line_num = line_idx + 1
            col_start = 0
            while True:
                col_start = line.find(search_text, col_start)
                if col_start == -1:
                    break

                pos = (line_num, col_start)
                if pos not in used_positions:
                    return line_num, col_start

                col_start += 1

        return 0, 0

    def _extract_embedded_paths(
        self, data: str, file_path: str, lines: List[str], references: List[LinkReference]
    ) -> bool:
        """
        PD-BUG-060: Extract file paths embedded within compound strings.

        When a YAML string value contains spaces (e.g., a command line like
        "pwsh.exe -File doc/scripts/Run-Tests.ps1 -Quick"), scan for path-like
        substrings using a regex pattern.

        PD-BUG-079: For multiline strings (literal `|` or folded `>` blocks),
        yaml.safe_load() resolves them into a single string with embedded newlines.
        The whole resolved string won't match any single raw line, so we search
        for each path candidate individually in the raw lines.

        Returns True if any embedded paths were found.
        """
        is_multiline = "\n" in data
        found = False
        line_num = 0
        val_col_start = 0
        for match in self._path_pattern.finditer(data):
            candidate = match.group(1)
            if "/" not in candidate and "\\" not in candidate:
                continue
            if self._looks_like_file_path(candidate):
                if is_multiline:
                    # PD-BUG-079: Search for each candidate path directly in raw lines
                    cand_line, cand_col = self._find_next_occurrence(lines, candidate, references)
                    if cand_line == 0:
                        continue
                    references.append(
                        LinkReference(
                            file_path=file_path,
                            line_number=cand_line,
                            column_start=cand_col,
                            column_end=cand_col + len(candidate),
                            link_text=candidate,
                            link_target=candidate,
                            link_type=LinkType.YAML,
                        )
                    )
                    found = True
                else:
                    if not found:
                        line_num, val_col_start = self._find_next_occurrence(lines, data, [])
                        if line_num == 0:
                            return False
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
                            link_type=LinkType.YAML,
                        )
                    )
                    found = True
        return found
