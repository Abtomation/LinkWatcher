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
- **Line attribution**: ``_find_unclaimed_line()`` matches the
  QUOTED form ``"value"`` (PD-BUG-134), so a value is never
  attributed to an earlier line whose larger literal merely
  contains it -- a compound command embedding it, or a longer path
  it prefixes.
- **Embedded path extraction**: ``_extract_embedded_paths()``
  handles compound strings containing spaces (PD-BUG-061), e.g.
  ``"Bash(python doc/scripts/run.py *)"``.
- **Link types**: ``JSON``, ``JSON_DIR``.
- **Common tasks**:
  - Debugging missed paths: check ``_classify_path()`` in
    ``base.py`` — it determines file vs directory classification.
  - Debugging duplicate matches: check the ``claimed`` set logic
    in ``_process_string_value()`` and ``_find_unclaimed_line()``.
  - Testing: ``test/automated/unit/2-link-parsing-update/2-0-link-parsing-update/test_json.py``.
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
                # PD-BUG-126: literals located by decoding are claimed by
                # (line, column) -- a decoded value is not unique enough,
                # since several spellings decode to the same string.
                self._escaped_taken = set()
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
        """Find next line holding search_text AS A VALUE, unclaimed (PD-BUG-013).

        The needle is the QUOTED form (PD-BUG-134).  A bare substring search
        matched any line whose larger literal merely CONTAINED the value --
        a compound command embedding it, or a longer path it prefixes -- so
        the reference was recorded against the wrong line, the updater
        rewrote the occurrence there, and the line the value actually
        occupies went silently stale.  Nothing was logged, because a line WAS
        found: the ``path_value_line_not_located`` warning only fires when
        none is.

        Requiring the delimiters costs nothing in JSON, where every string
        value is quote-delimited, and makes this consistent with
        ``_find_decoded_literal``, which has always matched whole literals.
        A value whose raw literal carries escapes appears on no line in
        either form; that is the caller's escaped path, unchanged.

        Scans from start_line for O(V+L) amortized performance instead of
        O(V*L), then wraps to the lines before it for out-of-order edge cases.
        """
        needle = '"' + search_text + '"'
        span = min(start_line, len(lines))
        for i in list(range(span, len(lines))) + list(range(0, span)):
            if needle in lines[i] and (search_text, i + 1) not in claimed:
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
            else:
                self._add_escaped_reference(data, file_path, lines, references, is_dir)

    def _add_escaped_reference(self, data, file_path, lines, references, is_dir):
        """Record a value whose source literal is escaped (PD-BUG-126).

        Reached when the plain search found no line, which for a value that
        already classified as a path means the author escaped it -- so the
        decoded text the caller holds does not appear in the raw line.

        The reference deliberately carries two different strings:
        ``link_text`` is the RAW source occupying the span, ``link_target``
        the DECODED value used for resolution.  The updater depends on that
        split (the shape ``PYTHON_IMPORT`` already uses) to read the line as
        current instead of stale.
        """
        line_num, col_start, col_end, raw_inner = self._find_decoded_literal(
            lines, data, json.loads, self._search_start_line, self._escaped_taken
        )
        if line_num == 0:
            # This used to drop the reference with no trace, so a target
            # could go stale on a move with nothing in the log at all (the
            # observability half of PD-BUG-126).
            self.logger.warning(
                "path_value_line_not_located",
                file_path=file_path,
                parser="json",
                value=data,
            )
            return

        self._escaped_taken.add((line_num, col_start))
        self._search_start_line = line_num - 1
        references.append(
            LinkReference(
                file_path=file_path,
                line_number=line_num,
                column_start=col_start,
                column_end=col_end,
                link_text=raw_inner,
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

        Returns True when the value has been HANDLED -- either embedded paths
        were recorded, or it holds path candidates whose escaped source literal
        could not be located (reported rather than dropped).  False means "no
        embedded paths here", which is what lets the caller fall through to
        whole-string classification for a value like "file with spaces.txt".

        PD-BUG-130: the handled/not-handled distinction is load-bearing.  This
        used to return False when the *line lookup* failed, so an escaped
        compound value fell through and, whenever the whole string happened to
        end in the path, was registered with the ENTIRE command line as its
        target.
        """
        candidates = self._collect_path_candidates(data)
        if not candidates:
            return False

        line_num = self._find_unclaimed_line(lines, data, claimed, self._search_start_line)
        if line_num == 0:
            # PD-BUG-130: the decoded value appears on no raw line, so the
            # source literal is escaped.  Map spans through the raw text
            # instead of discarding every candidate.
            return self._add_escaped_embedded_paths(data, candidates, file_path, lines, references)

        claimed.add((data, line_num))
        self._search_start_line = line_num - 1
        line_content = lines[line_num - 1]
        val_col_start = line_content.find(data)
        if val_col_start < 0:
            val_col_start = 0
        for start, end, text, is_dir in candidates:
            references.append(
                LinkReference(
                    file_path=file_path,
                    line_number=line_num,
                    column_start=val_col_start + start,
                    column_end=val_col_start + end,
                    link_text=text,
                    link_target=text,
                    link_type=LinkType.JSON_DIR if is_dir else LinkType.JSON,
                )
            )
        return True

    def _add_escaped_embedded_paths(self, data, candidates, file_path, lines, references) -> bool:
        """Record compound-string candidates whose literal is escaped (PD-BUG-130).

        Sibling of ``_add_escaped_reference``, which covers the whole-string
        case (PD-BUG-126).  Each candidate span is an offset into the DECODED
        value, so it is mapped onto the raw literal before being recorded;
        ``link_text`` then carries the RAW spelling and ``link_target`` the
        decoded path -- the split the updater uses to rewrite the reference in
        the author's own escaping.

        Always returns True.  Even when the literal cannot be located the value
        has been dealt with and reported, and must not fall through to
        whole-string classification.
        """
        line_num, inner_start, _inner_end, raw_inner = self._find_decoded_literal(
            lines, data, json.loads, self._search_start_line, self._escaped_taken
        )
        index = self._build_decoded_to_raw_index(raw_inner, json.loads) if line_num else None
        if line_num == 0 or index is None:
            self.logger.warning(
                "path_value_line_not_located",
                file_path=file_path,
                parser="json",
                value=data,
            )
            return True

        self._escaped_taken.add((line_num, inner_start))
        self._search_start_line = line_num - 1
        line_content = lines[line_num - 1]
        for start, end, text, is_dir in candidates:
            col_start = inner_start + index[start]
            col_end = inner_start + index[end]
            references.append(
                LinkReference(
                    file_path=file_path,
                    line_number=line_num,
                    column_start=col_start,
                    column_end=col_end,
                    link_text=line_content[col_start:col_end],
                    link_target=text,
                    link_type=LinkType.JSON_DIR if is_dir else LinkType.JSON,
                )
            )
        return True
