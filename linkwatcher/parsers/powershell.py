"""
PowerShell file parser for extracting file references.

This parser handles PowerShell files (.ps1, .psm1) and extracts file
references from line comments (#), block comments (<# #>), quoted
string literals (file and directory paths), and embedded markdown links.
"""

import re
from typing import List

from ..models import LinkReference
from .base import BaseParser
from .patterns import QUOTED_DIR_PATTERN_STRICT, QUOTED_PATH_PATTERN


class PowerShellParser(BaseParser):
    """Parser for PowerShell files (.ps1, .psm1)."""

    def __init__(self):
        super().__init__()
        self.quoted_pattern = QUOTED_PATH_PATTERN
        # Strict variant: requires content after last separator
        self.quoted_dir_pattern = QUOTED_DIR_PATTERN_STRICT

        # Pattern for markdown-style links embedded in quoted strings: [text](path)
        self.embedded_md_link_pattern = re.compile(r"\]\(([^)]+[/\\][^)]*)\)")

        # Pattern for file paths in comments and general text
        self.path_pattern = re.compile(r"([a-zA-Z0-9_\-./\\]+\.[a-zA-Z0-9]+)")

        # Pattern to detect block comment boundaries
        self.block_comment_start = re.compile(r"<#")
        self.block_comment_end = re.compile(r"#>")

    def parse_content(self, content: str, file_path: str) -> List[LinkReference]:
        """Parse PowerShell content for file references."""
        try:
            lines = content.split("\n")
            references = []
            in_block_comment = False

            for line_num, line in enumerate(lines, 1):
                # Track block comment state
                if not in_block_comment and self.block_comment_start.search(line):
                    in_block_comment = True
                    # Check if block comment opens and closes on the same line
                    if self.block_comment_end.search(line[line.find("<#") + 2 :]):
                        self._extract_paths_from_line(
                            line, line_num, file_path, "powershell-block-comment", references
                        )
                        in_block_comment = False
                        continue

                if in_block_comment:
                    if self.block_comment_end.search(line):
                        in_block_comment = False
                    # Extract paths from block comment lines
                    self._extract_paths_from_line(
                        line, line_num, file_path, "powershell-block-comment", references
                    )
                    continue

                # Line comment — extract paths from the comment portion
                if "#" in line:
                    # Find the comment start (but not inside a string)
                    comment_start = self._find_comment_start(line)
                    if comment_start is not None:
                        comment_part = line[comment_start:]
                        self._extract_paths_from_segment(
                            comment_part,
                            comment_start,
                            line_num,
                            file_path,
                            "powershell-comment",
                            references,
                        )

                # Quoted strings — file paths (both in code lines and comment lines)
                file_path_spans = set()
                for match in self.quoted_pattern.finditer(line):
                    potential_file = match.group(1)
                    if self._looks_like_file_path(potential_file):
                        file_path_spans.add((match.start(1), match.end(1)))
                        references.append(
                            LinkReference(
                                file_path=file_path,
                                line_number=line_num,
                                column_start=match.start(1),
                                column_end=match.end(1),
                                link_text=potential_file,
                                link_target=potential_file,
                                link_type="powershell-quoted",
                            )
                        )

                # Quoted strings — directory paths (no extension required)
                for match in self.quoted_dir_pattern.finditer(line):
                    # Skip if already matched as a file path
                    if (match.start(1), match.end(1)) in file_path_spans:
                        continue
                    potential_dir = match.group(1)
                    if self._looks_like_directory_path(potential_dir):
                        file_path_spans.add((match.start(1), match.end(1)))
                        references.append(
                            LinkReference(
                                file_path=file_path,
                                line_number=line_num,
                                column_start=match.start(1),
                                column_end=match.end(1),
                                link_text=potential_dir,
                                link_target=potential_dir,
                                link_type="powershell-quoted-dir",
                            )
                        )

                # Embedded markdown links in quoted strings: "[$var](some/path)"
                for match in self.embedded_md_link_pattern.finditer(line):
                    # Skip if this span is already covered by a file/dir match
                    if (match.start(1), match.end(1)) in file_path_spans:
                        continue
                    embedded_path = match.group(1)
                    # Strip trailing PS variable (e.g., "path/$varName" → "path/")
                    clean_path = re.sub(r"\$\w+$", "", embedded_path).rstrip("/")
                    if clean_path and (
                        self._looks_like_directory_path(embedded_path)
                        or self._looks_like_file_path(embedded_path)
                        or self._looks_like_directory_path(clean_path)
                    ):
                        references.append(
                            LinkReference(
                                file_path=file_path,
                                line_number=line_num,
                                column_start=match.start(1),
                                column_end=match.end(1),
                                link_text=embedded_path,
                                link_target=embedded_path,
                                link_type="powershell-embedded-md-link",
                            )
                        )

            return self._deduplicate(references)

        except Exception as e:
            self.logger.warning(
                "parse_error", file_path=file_path, parser="powershell", error=str(e)
            )
            return []

    def _find_comment_start(self, line: str) -> int | None:
        """Find the start position of a line comment, ignoring # inside strings."""
        in_single_quote = False
        in_double_quote = False
        i = 0
        while i < len(line):
            char = line[i]
            if char == "'" and not in_double_quote:
                in_single_quote = not in_single_quote
            elif char == '"' and not in_single_quote:
                in_double_quote = not in_double_quote
            elif char == "#" and not in_single_quote and not in_double_quote:
                return i
            i += 1
        return None

    def _extract_paths_from_line(
        self,
        line: str,
        line_num: int,
        file_path: str,
        link_type: str,
        references: List[LinkReference],
    ):
        """Extract all file paths from a full line."""
        self._extract_paths_from_segment(line, 0, line_num, file_path, link_type, references)

    def _extract_paths_from_segment(
        self,
        segment: str,
        offset: int,
        line_num: int,
        file_path: str,
        link_type: str,
        references: List[LinkReference],
    ):
        """Extract file paths from a text segment at a given offset."""
        for match in self.path_pattern.finditer(segment):
            potential_file = match.group(1)
            if self._looks_like_file_path(potential_file):
                references.append(
                    LinkReference(
                        file_path=file_path,
                        line_number=line_num,
                        column_start=offset + match.start(1),
                        column_end=offset + match.end(1),
                        link_text=potential_file,
                        link_target=potential_file,
                        link_type=link_type,
                    )
                )

    def _deduplicate(self, references: List[LinkReference]) -> List[LinkReference]:
        """Remove duplicate references (same line, same target, overlapping columns)."""
        seen = set()
        unique = []
        for ref in references:
            key = (ref.line_number, ref.link_target, ref.column_start)
            if key not in seen:
                seen.add(key)
                unique.append(ref)
        return unique
