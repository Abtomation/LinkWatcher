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
        super().__init__()
        # Pattern 1: Standard markdown links [text](link) - handles balanced parentheses
        # This regex properly handles nested parentheses in titles
        self.link_pattern = re.compile(r"\[([^\]]+)\]\(((?:[^()]|\([^)]*\))*)\)")

        # Pattern 2: Standalone file references (quoted)
        self.quoted_pattern = re.compile(r'[\'"]([a-zA-Z0-9_\-./\\]+\.[a-zA-Z0-9]+)[\'"]')

        # Pattern 3: Reference-style link definitions [label]: url "title"
        self.reference_pattern = re.compile(r"^\s*\[([^\]]+)\]:\s*(.+)$")

        # Pattern 4: Unquoted file references (be careful in markdown)
        # Look for file paths that are clearly standalone
        self.standalone_pattern = re.compile(r"(?:^|\s)([a-zA-Z0-9_\-./\\]+\.[a-zA-Z0-9]+)(?:\s|$)")

    def _extract_url_from_link_content(self, link_content: str) -> str:
        """
        Extract just the URL from link content, removing any title.

        Handles titles in formats:
        - url "title"
        - url 'title'
        - url (title)
        """
        link_content = link_content.strip()

        # Check for title with double quotes
        if '"' in link_content:
            # Find the last quote that could start a title
            parts = link_content.split('"')
            if len(parts) >= 3:  # url "title"
                # Everything before the last pair of quotes is the URL
                url_part = '"'.join(parts[:-2]).strip()
                if url_part:
                    return url_part

        # Check for title with single quotes
        if "'" in link_content:
            # Find the last quote that could start a title
            parts = link_content.split("'")
            if len(parts) >= 3:  # url 'title'
                # Everything before the last pair of quotes is the URL
                url_part = "'".join(parts[:-2]).strip()
                if url_part:
                    return url_part

        # Check for title with parentheses (this is trickier since the outer parens are already removed)
        # Look for pattern: url (title) where there's a space before the opening paren
        paren_match = re.match(r"^(.+?)\s+\(([^)]*)\)$", link_content)
        if paren_match:
            return paren_match.group(1).strip()

        # If no title found, return the original content
        return link_content

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
                    link_content = match.group(2)

                    # Extract just the URL, removing any title
                    link_target = self._extract_url_from_link_content(link_content)

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

                # Then, look for reference-style link definitions
                ref_match = self.reference_pattern.match(line)
                if ref_match:
                    ref_label = ref_match.group(1)
                    ref_content = ref_match.group(2)

                    # Extract just the URL, removing any title
                    ref_target = self._extract_url_from_link_content(ref_content)

                    # Skip external links
                    if not ref_target.startswith(("http://", "https://", "mailto:", "tel:")):
                        # Skip anchors only
                        if not ref_target.startswith("#"):
                            references.append(
                                LinkReference(
                                    file_path=file_path,
                                    line_number=line_num,
                                    column_start=ref_match.start(),
                                    column_end=ref_match.end(),
                                    link_text=ref_label,
                                    link_target=ref_target,
                                    link_type="markdown-reference",
                                )
                            )

                # Then, look for standalone file references
                # Skip if this line is a reference definition
                is_reference_line = self.reference_pattern.match(line) is not None

                if not is_reference_line:
                    # Check for quoted file paths (but avoid overlapping with markdown links)
                    for match in self.quoted_pattern.finditer(line):
                        potential_file = match.group(1)
                        if self._looks_like_file_path(potential_file):
                            # Check if this overlaps with any markdown link
                            overlaps = False
                            for md_match in self.link_pattern.finditer(line):
                                if (
                                    match.start() >= md_match.start()
                                    and match.end() <= md_match.end()
                                ):
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
            self.logger.warning("parse_error", file_path=file_path, parser="markdown", error=str(e))
            return []
