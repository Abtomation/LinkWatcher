"""
Dart file parser for extracting file references.

This parser handles Dart files and extracts import statements
and other file references, excluding package imports.
"""

import re
from typing import List

from ..models import LinkReference
from .base import BaseParser


class DartParser(BaseParser):
    """Parser for Dart files (.dart)."""

    def __init__(self):
        super().__init__()
        # Pattern for import statements
        self.import_pattern = re.compile(r"import\s+['\"]([^'\"]+)['\"]")

        # Pattern for part statements
        self.part_pattern = re.compile(r"part\s+['\"]([^'\"]+)['\"]")

        # Pattern for quoted file paths (excluding package imports)
        # Use permissive match inside quotes — _looks_like_file_path() validates later
        self.quoted_pattern = re.compile(r'[\'"]([^\'"]+\.[a-zA-Z0-9]+)[\'"]')

        # Pattern for file paths within strings (not necessarily the entire string)
        self.embedded_pattern = re.compile(r"([a-zA-Z0-9_\-./\\]+\.[a-zA-Z0-9]+)")

        # Pattern for standalone file references (unquoted)
        self.standalone_pattern = re.compile(r"(?:^|\s)([a-zA-Z0-9_\-./\\]+\.[a-zA-Z0-9]+)(?:\s|$)")

    def parse_content(self, content: str, file_path: str) -> List[LinkReference]:
        """Parse Dart content for file references."""
        try:
            lines = content.split("\n")
            references = []

            for line_num, line in enumerate(lines, 1):
                references.extend(self._extract_imports(line, line_num, file_path))
                references.extend(self._extract_parts(line, line_num, file_path))

                # Quoted, standalone, and embedded only on non-import/non-part lines
                if not (self.import_pattern.search(line) or self.part_pattern.search(line)):
                    references.extend(self._extract_quoted_refs(line, line_num, file_path))
                    references.extend(self._extract_standalone_refs(line, line_num, file_path))
                    references.extend(
                        self._extract_embedded_refs(line, line_num, file_path, references)
                    )

            return references

        except Exception as e:
            self.logger.warning("parse_error", file_path=file_path, parser="dart", error=str(e))
            return []

    def _extract_imports(self, line: str, line_num: int, file_path: str) -> List[LinkReference]:
        """Extract import statement references from a line."""
        results = []
        for match in self.import_pattern.finditer(line):
            import_path = match.group(1)
            if import_path.startswith("package:") or import_path.startswith("dart:"):
                continue
            results.append(
                LinkReference(
                    file_path=file_path,
                    line_number=line_num,
                    column_start=match.start(1),
                    column_end=match.end(1),
                    link_text=import_path,
                    link_target=import_path,
                    link_type="dart-import",
                )
            )
        return results

    def _extract_parts(self, line: str, line_num: int, file_path: str) -> List[LinkReference]:
        """Extract part statement references from a line."""
        results = []
        for match in self.part_pattern.finditer(line):
            part_path = match.group(1)
            results.append(
                LinkReference(
                    file_path=file_path,
                    line_number=line_num,
                    column_start=match.start(1),
                    column_end=match.end(1),
                    link_text=part_path,
                    link_target=part_path,
                    link_type="dart-part",
                )
            )
        return results

    def _extract_quoted_refs(self, line: str, line_num: int, file_path: str) -> List[LinkReference]:
        """Extract quoted file path references from a line."""
        results = []
        for match in self.quoted_pattern.finditer(line):
            potential_file = match.group(1)
            if potential_file.startswith("package:") or potential_file.startswith("dart:"):
                continue
            if self._looks_like_file_path(potential_file):
                results.append(
                    LinkReference(
                        file_path=file_path,
                        line_number=line_num,
                        column_start=match.start(1),
                        column_end=match.end(1),
                        link_text=potential_file,
                        link_target=potential_file,
                        link_type="dart-quoted",
                    )
                )
        return results

    def _extract_standalone_refs(
        self, line: str, line_num: int, file_path: str
    ) -> List[LinkReference]:
        """Extract standalone (unquoted) file path references from a line."""
        results = []
        for match in self.standalone_pattern.finditer(line):
            potential_file = match.group(1)
            if potential_file.startswith("package:") or potential_file.startswith("dart:"):
                continue
            if self._looks_like_file_path(potential_file):
                results.append(
                    LinkReference(
                        file_path=file_path,
                        line_number=line_num,
                        column_start=match.start(1),
                        column_end=match.end(1),
                        link_text=potential_file,
                        link_target=potential_file,
                        link_type="dart-standalone",
                    )
                )
        return results

    def _extract_embedded_refs(
        self,
        line: str,
        line_num: int,
        file_path: str,
        references: List[LinkReference],
    ) -> List[LinkReference]:
        """Extract embedded file path references from a line, deduplicating against existing refs."""
        results = []
        for match in self.embedded_pattern.finditer(line):
            potential_file = match.group(1)
            if potential_file.startswith("package:") or potential_file.startswith("dart:"):
                continue

            # Skip URLs (check if preceded by http:// or https://)
            start_pos = match.start(1)
            if potential_file.startswith("//"):
                if start_pos >= 1 and line[start_pos - 1] == ":":
                    if start_pos >= 6 and line[start_pos - 6 : start_pos - 1] == "https":
                        continue
                    if start_pos >= 5 and line[start_pos - 5 : start_pos - 1] == "http":
                        continue

            # Skip if already found by other patterns
            already_found = False
            for existing_ref in references:
                if (
                    existing_ref.line_number == line_num
                    and existing_ref.link_target == potential_file
                    and existing_ref.column_start <= match.start(1) < existing_ref.column_end
                ):
                    already_found = True
                    break

            if already_found:
                continue

            if self._looks_like_file_path(potential_file):
                results.append(
                    LinkReference(
                        file_path=file_path,
                        line_number=line_num,
                        column_start=match.start(1),
                        column_end=match.end(1),
                        link_text=potential_file,
                        link_target=potential_file,
                        link_type="dart-embedded",
                    )
                )
        return results
