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
        self.quoted_pattern = re.compile(r'[\'"]([a-zA-Z0-9_\-./\\]+\.[a-zA-Z0-9]+)[\'"]')

        # Pattern for file paths within strings (not necessarily the entire string)
        self.embedded_pattern = re.compile(r"([a-zA-Z0-9_\-./\\]+\.[a-zA-Z0-9]+)")

        # Pattern for standalone file references (unquoted)
        self.standalone_pattern = re.compile(r"(?:^|\s)([a-zA-Z0-9_\-./\\]+\.[a-zA-Z0-9]+)(?:\s|$)")

    def parse_file(self, file_path: str) -> List[LinkReference]:
        """Parse Dart file for file references."""
        try:
            content = self._safe_read_file(file_path)
            lines = content.split("\n")
            references = []

            for line_num, line in enumerate(lines, 1):
                # Check for import statements
                for match in self.import_pattern.finditer(line):
                    import_path = match.group(1)

                    # Skip package imports
                    if import_path.startswith("package:"):
                        continue

                    # Skip dart: imports
                    if import_path.startswith("dart:"):
                        continue

                    references.append(
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

                # Check for part statements
                for match in self.part_pattern.finditer(line):
                    part_path = match.group(1)

                    references.append(
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

                # Check for other quoted file paths (in comments, strings, etc.)
                # Skip lines with imports/parts to avoid duplicates
                if not (self.import_pattern.search(line) or self.part_pattern.search(line)):
                    for match in self.quoted_pattern.finditer(line):
                        potential_file = match.group(1)

                        # Skip if it looks like a package import
                        if potential_file.startswith("package:") or potential_file.startswith(
                            "dart:"
                        ):
                            continue

                        if self._looks_like_file_path(potential_file):
                            references.append(
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

                    # Check for standalone file references
                    for match in self.standalone_pattern.finditer(line):
                        potential_file = match.group(1)

                        # Skip if it looks like a package import
                        if potential_file.startswith("package:") or potential_file.startswith(
                            "dart:"
                        ):
                            continue

                        if self._looks_like_file_path(potential_file):
                            references.append(
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

                    # Check for embedded file paths in strings and comments
                    # Look for file paths that appear anywhere in the line
                    for match in self.embedded_pattern.finditer(line):
                        potential_file = match.group(1)

                        # Skip if it looks like a package import
                        if potential_file.startswith("package:") or potential_file.startswith(
                            "dart:"
                        ):
                            continue

                        # Skip URLs (check if preceded by http:// or https://)
                        start_pos = match.start(1)
                        # Check if this looks like part of a URL (starts with //)
                        if potential_file.startswith("//"):
                            # Check if it's preceded by http: or https:
                            if start_pos >= 1 and line[start_pos - 1] == ":":
                                # Check for https: or http:
                                if (
                                    start_pos >= 6
                                    and line[start_pos - 6 : start_pos - 1] == "https"
                                ):
                                    continue
                                if start_pos >= 5 and line[start_pos - 5 : start_pos - 1] == "http":
                                    continue

                        # Skip if already found by other patterns
                        already_found = False
                        for existing_ref in references:
                            if (
                                existing_ref.line_number == line_num
                                and existing_ref.link_target == potential_file
                                and existing_ref.column_start
                                <= match.start(1)
                                < existing_ref.column_end
                            ):
                                already_found = True
                                break

                        if already_found:
                            continue

                        if self._looks_like_file_path(potential_file):
                            references.append(
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

            return references

        except Exception as e:
            self.logger.warning("parse_error", file_path=file_path, parser="dart", error=str(e))
            return []
