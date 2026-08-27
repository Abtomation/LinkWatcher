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
  A whole scalar must land on an occurrence that IS that scalar,
  not one inside a larger literal (``_is_standalone_scalar``,
  PD-BUG-134); the plain scan runs behind it as a fallback, and
  block-scalar candidates opt out via ``whole_value=False``.
- **Link types**: ``YAML``, ``YAML_DIR``.
- **Common tasks**:
  - Debugging missed paths: check ``_classify_path()`` in
    ``base.py`` — it determines file vs directory classification.
  - Debugging embedded paths: check ``_extract_embedded_paths()``
    and the ``_path_pattern`` regex in ``base.py``.
  - Testing: ``test/automated/unit/2-link-parsing-update/2-0-link-parsing-update/test_yaml.py``.
"""

from typing import List

import yaml

from ..link_types import LinkType
from ..models import LinkReference
from .base import BaseParser


class YamlParser(BaseParser):
    """Parser for YAML files (.yaml, .yml)."""

    # Characters that may introduce or terminate a whole scalar value on a
    # line, used by _is_standalone_scalar (PD-BUG-134).
    _VALUE_LEAD = frozenset(":-,[{")
    _VALUE_TRAIL = frozenset(",]}#")
    _SCALAR_QUOTES = frozenset("\"'")

    def parse_content(self, content: str, file_path: str) -> List[LinkReference]:
        """Parse YAML content for file references."""
        try:
            lines = content.split("\n")
            references = []
            self._search_start_line = 0  # Offset for O(V+L) scanning
            # PD-BUG-126: literals located by decoding are claimed by
            # (line, column) -- a decoded value is not unique enough,
            # since several spellings decode to the same string.
            self._escaped_taken = set()

            try:
                # PD-BUG-092: Use safe_load_all to handle multi-document YAML
                # (--- separators). Previously safe_load() raised ComposerError
                # on any multi-document stream, forcing a GenericParser fallback
                # that missed bare directory paths.
                for data in yaml.safe_load_all(content):
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
            else:
                self._add_escaped_reference(data, file_path, lines, references, is_dir)

    def _add_escaped_reference(self, data, file_path, lines, references, is_dir):
        """Record a value whose source scalar is escaped (PD-BUG-126).

        Narrower than the JSON twin: YAML honours backslash escapes only in
        DOUBLE-quoted scalars, so the plain and single-quoted forms never
        reach here -- for them raw and decoded text are identical and the
        ordinary search already succeeds.
        """
        line_num, col_start, col_end, raw_inner = self._find_decoded_literal(
            lines, data, yaml.safe_load, self._search_start_line, self._escaped_taken
        )
        if line_num == 0:
            # Previously dropped with no trace, leaving a target to go stale
            # on a move with nothing logged (observability half of the bug).
            self.logger.warning(
                "path_value_line_not_located",
                file_path=file_path,
                parser="yaml",
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
                link_type=LinkType.YAML_DIR if is_dir else LinkType.YAML,
            )
        )

    def _find_next_occurrence(
        self,
        lines: List[str],
        search_text: str,
        existing_refs: List[LinkReference],
        whole_value: bool = True,
    ) -> tuple:
        """
        Find the next occurrence of search_text that hasn't been used yet.
        Returns (line_number, column_start) or (0, 0) if not found.

        PD-BUG-134: when *search_text* is a whole scalar, an occurrence only
        counts if it IS that scalar rather than a substring of a larger
        literal.  A bare search matched a compound scalar embedding the value
        or a longer path it prefixes, so the reference was recorded against
        the wrong line and the line the scalar really occupies went silently
        stale.  ``used_positions`` cannot catch that: it rejects a position
        another reference already took, and no reference holds a position
        inside somebody else's literal.

        The strict pass runs first; if no line qualifies, the plain scan runs
        as before.  YAML has more scalar shapes than the standalone rule
        recognises (an explicit ``!!str`` tag, say), and tightening a lookup
        must never turn a mis-attributed reference into a dropped one.

        Pass ``whole_value=False`` where *search_text* is deliberately a
        fragment -- the per-candidate lookup inside a multiline block scalar
        (PD-BUG-079), where the path sits mid-command by construction.
        """
        # Get positions of already found references for this text
        used_positions = set()
        for ref in existing_refs:
            if ref.link_target == search_text:
                used_positions.add((ref.line_number, ref.column_start))

        if whole_value:
            line_num, col_start = self._scan_occurrences(
                lines, search_text, used_positions, standalone=True
            )
            if line_num:
                return line_num, col_start

        return self._scan_occurrences(lines, search_text, used_positions, standalone=False)

    def _scan_occurrences(
        self, lines: List[str], search_text: str, used_positions: set, standalone: bool
    ) -> tuple:
        """Scan for search_text, forward from the last-found line then wrapping.

        With *standalone* set, an occurrence must be a whole scalar value on
        its line (PD-BUG-134).  ``_search_start_line`` advances only on a
        forward hit, so a strict pass that finds nothing leaves the scan
        offset untouched for the plain pass behind it.
        """
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
                if pos not in used_positions and (
                    not standalone or self._is_standalone_scalar(line, col_start, len(search_text))
                ):
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
                if pos not in used_positions and (
                    not standalone or self._is_standalone_scalar(line, col_start, len(search_text))
                ):
                    return line_num, col_start

                col_start += 1

        return 0, 0

    @classmethod
    def _is_standalone_scalar(cls, line: str, col: int, length: int) -> bool:
        """Is the span at *col* a whole scalar value on this line (PD-BUG-134)?

        YAML gives no delimiter to key on -- a plain scalar is unquoted -- so
        the test is what surrounds the span.  A value follows the syntax that
        introduces one (``key:``, a ``-`` sequence entry, a flow ``[``/``{``
        or ``,``) or an opening quote, and ends at end-of-line, whitespace, a
        closing quote, a flow separator, or a comment.

        That rejects the two shapes the bug produced -- a longer path the
        span merely prefixes (next character is ``/``) and a span sitting
        mid-command inside a compound scalar (preceded by a command word) --
        while accepting sequence entries, flow members and commented values.
        A key position is rejected too: the span is followed by ``:``.
        """
        end = col + length
        prefix = line[:col]

        if col == 0 or not prefix.strip():
            lead_ok = True
        elif line[col - 1] in cls._SCALAR_QUOTES:
            lead_ok = True
        else:
            lead_ok = prefix.rstrip()[-1] in cls._VALUE_LEAD

        if end >= len(line):
            trail_ok = True
        else:
            following = line[end]
            trail_ok = (
                following.isspace()
                or following in cls._VALUE_TRAIL
                or following in cls._SCALAR_QUOTES
            )

        return lead_ok and trail_ok

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

        Returns True when the value has been HANDLED -- either embedded paths
        were recorded, or it holds path candidates whose escaped source scalar
        could not be located (reported rather than dropped).  False means "no
        embedded paths here", letting the caller fall through to whole-string
        classification.

        PD-BUG-130: that distinction is load-bearing.  This used to return
        False when the *line lookup* failed, so an escaped compound scalar fell
        through and, whenever the whole string happened to end in the path, was
        registered with the ENTIRE command line as its target.
        """
        candidates = self._collect_path_candidates(data)
        if not candidates:
            return False

        if "\n" in data:
            # PD-BUG-079: a multiline block scalar resolves to a string that
            # matches no single raw line, so each candidate is located on its
            # own.  Escapes do not arise here -- block scalars are literal.
            found = False
            for _start, _end, candidate, is_dir in candidates:
                # whole_value=False (PD-BUG-134): a candidate inside a block
                # scalar is a fragment of a command line by construction, so
                # the standalone-scalar rule would reject every one of them.
                cand_line, cand_col = self._find_next_occurrence(
                    lines, candidate, references, whole_value=False
                )
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
                        link_type=LinkType.YAML_DIR if is_dir else LinkType.YAML,
                    )
                )
                found = True
            return found

        line_num, val_col_start = self._find_next_occurrence(lines, data, [])
        if line_num == 0:
            # PD-BUG-130: the decoded scalar appears on no raw line, so it is a
            # double-quoted scalar carrying escapes.  Map spans through the raw
            # text instead of discarding every candidate.
            return self._add_escaped_embedded_paths(data, candidates, file_path, lines, references)

        for start, end, text, is_dir in candidates:
            references.append(
                LinkReference(
                    file_path=file_path,
                    line_number=line_num,
                    column_start=val_col_start + start,
                    column_end=val_col_start + end,
                    link_text=text,
                    link_target=text,
                    link_type=LinkType.YAML_DIR if is_dir else LinkType.YAML,
                )
            )
        return True

    def _add_escaped_embedded_paths(self, data, candidates, file_path, lines, references) -> bool:
        """Record compound-scalar candidates whose literal is escaped (PD-BUG-130).

        Sibling of ``_add_escaped_reference``, which covers the whole-string
        case (PD-BUG-126), and twin of the JSON method of the same name.  Each
        candidate span is an offset into the DECODED scalar, so it is mapped
        onto the raw literal first; ``link_text`` then carries the RAW spelling
        and ``link_target`` the decoded path, the split the updater uses to
        rewrite in the author's own escaping.

        Reached only for DOUBLE-quoted scalars: YAML honours backslash escapes
        nowhere else, so plain and single-quoted scalars are located by the
        ordinary search.

        Always returns True -- an unlocatable value is reported, never fallen
        through to whole-string classification.
        """
        line_num, inner_start, _inner_end, raw_inner = self._find_decoded_literal(
            lines, data, yaml.safe_load, self._search_start_line, self._escaped_taken
        )
        index = self._build_decoded_to_raw_index(raw_inner, yaml.safe_load) if line_num else None
        if line_num == 0 or index is None:
            self.logger.warning(
                "path_value_line_not_located",
                file_path=file_path,
                parser="yaml",
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
                    link_type=LinkType.YAML_DIR if is_dir else LinkType.YAML,
                )
            )
        return True
