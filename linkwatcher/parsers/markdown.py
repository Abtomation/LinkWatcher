"""
Markdown file parser for extracting link references.

This parser handles standard markdown links, standalone file references,
and other markdown-specific link formats.
"""

import re
from typing import List

from ..models import LinkReference
from .base import BaseParser


class MarkdownParser(BaseParser):
    """Parser for Markdown files (.md)."""

    def __init__(self):
        # Pattern 1: Standard markdown links [text](link)
        self.link_pattern = re.compile(r"\[([^\]]+)\]\(([^)]+)\)")

        # Pattern 2: Standalone file references (quoted)
        self.quoted_pattern = re.compile(r'[\'"]([a-zA-Z0-9_\-./\\]+\.[a-zA-Z0-9]+)[\'"]')

        # Pattern 3: Unquoted file references (be careful in markdown)
        # Look for file paths that are clearly standalone
        self.standalone_pattern = re.compile(r"(?:^|\s)([a-zA-Z0-9_\-./\\]+\.[a-zA-Z0-9]+)(?:\s|$)")

    def parse_file(self, file_path: str) -> List[LinkReference]:
        """Parse markdown file for links."""
        try:
            content = self._safe_read_file(file_path)
            lines = content.split("\n")
            references = []

            for line_num, line in enumerate(lines, 1):
                # First, find standard markdown links
                for match in self.link_pattern.finditer(line):
                    link_text = match.group(1)
                    link_target = match.group(2)

                    # Skip external links
                    if link_target.startswith(("http://", "https://", "mailto:", "tel:")):
                        continue

                    # Skip anchors only
                    if link_target.startswith("#"):
                        continue

                    references.append(
                        LinkReference(
                            file_path=file_path,
                            line_number=line_num,
                            column_start=match.start(),
                            column_end=match.end(),
                            link_text=link_text,
                            link_target=link_target,
                            link_type="markdown",
                        )
                    )

                # Then, look for standalone file references
                # Check for quoted file paths (but avoid overlapping with markdown links)
                for match in self.quoted_pattern.finditer(line):
                    potential_file = match.group(1)
                    if self._looks_like_file_path(potential_file):
                        # Check if this overlaps with any markdown link
                        overlaps = False
                        for md_match in self.link_pattern.finditer(line):
                            if match.start() >= md_match.start() and match.end() <= md_match.end():
                                overlaps = True
                                break

                        if not overlaps:
                            references.append(
                                LinkReference(
                                    file_path=file_path,
                                    line_number=line_num,
                                    column_start=match.start(),
                                    column_end=match.end(),
                                    link_text=potential_file,
                                    link_target=potential_file,
                                    link_type="markdown-quoted",
                                )
                            )

                # Check for standalone file references (but avoid overlapping with markdown links)
                for match in self.standalone_pattern.finditer(line):
                    potential_file = match.group(1)
                    if self._looks_like_file_path(potential_file):
                        # Check if this overlaps with any markdown link
                        overlaps = False
                        for md_match in self.link_pattern.finditer(line):
                            if (
                                match.start(1) >= md_match.start()
                                and match.end(1) <= md_match.end()
                            ):
                                overlaps = True
                                break

                        if not overlaps:
                            references.append(
                                LinkReference(
                                    file_path=file_path,
                                    line_number=line_num,
                                    column_start=match.start(1),
                                    column_end=match.end(1),
                                    link_text=potential_file,
                                    link_target=potential_file,
                                    link_type="markdown-standalone",
                                )
                            )

            return references

        except Exception as e:
            print(f"Warning: Could not parse markdown file {file_path}: {e}")
            return []
