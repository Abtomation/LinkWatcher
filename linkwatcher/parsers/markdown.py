"""
Markdown file parser for extracting link references.

This parser handles standard markdown links, standalone file references,
and other markdown-specific link formats.
"""

import os.path
import re
from typing import List

from ..models import LinkReference
from .base import BaseParser
from .patterns import QUOTED_DIR_PATTERN, QUOTED_PATH_PATTERN


class MarkdownParser(BaseParser):
    """Parser for Markdown files (.md)."""

    def __init__(self):
        super().__init__()
        # Pattern 1: Standard markdown links [text](link) - handles balanced parentheses
        self.link_pattern = re.compile(r"\[([^\]]+)\]\(((?:[^()]|\([^)]*\))*)\)")

        # Pattern 2: Standalone file references (quoted)
        self.quoted_pattern = QUOTED_PATH_PATTERN

        # Pattern 3: Reference-style link definitions [label]: url "title"
        self.reference_pattern = re.compile(r"^\s*\[([^\]]+)\]:\s*(.+)$")

        # Pattern 4: Unquoted file references (be careful in markdown)
        self.standalone_pattern = re.compile(r"(?:^|\s)([a-zA-Z0-9_\-./\\]+\.[a-zA-Z0-9]+)(?:\s|$)")

        # Pattern 5: HTML anchor tags <a href="link">text</a> (PD-BUG-011)
        self.html_anchor_pattern = re.compile(
            r'<a\s+[^>]*href=[\'"]([^\'"]+)[\'"][^>]*>', re.IGNORECASE
        )

        # Pattern 6: Quoted directory paths — no extension required (PD-BUG-031)
        self.quoted_dir_pattern = QUOTED_DIR_PATTERN

        # Pattern 7: Backtick-quoted file paths — `path/to/file.ext` (PD-BUG-054)
        self.backtick_path_pattern = re.compile(r"`([^`]+\.[a-zA-Z0-9]+)`")

        # Pattern 8: Backtick-quoted directory paths — `path/to/dir` (PD-BUG-054)
        self.backtick_dir_pattern = re.compile(r"`([^`]*[/\\][^`]*)`")

        # Pattern 9: Bare path with separators — matches paths like
        # doc/process-framework/scripts/file-creation (PD-BUG-054)
        # Also matches leading-slash paths like /doc/process-framework/... (PD-BUG-055)
        # Requires at least 2 path segments to reduce false positives.
        self.bare_path_pattern = re.compile(
            r"(?:^|(?<=\s))"
            r"(/?[a-zA-Z0-9_.][a-zA-Z0-9_.\-]*(?:[/\\][a-zA-Z0-9_.\-]+){2,}/?)"
            r"(?=\s|$|&&|\|)"
        )

        # Pattern 10: @-prefixed path references — @doc/path/to/file.md (PD-BUG-055)
        # Used in CLAUDE.md for @-mention style file references.
        # Captures the path without the @ prefix.
        self.at_prefix_pattern = re.compile(
            r"@([a-zA-Z0-9_.][a-zA-Z0-9_.\-]*(?:[/\\][a-zA-Z0-9_.\-]+)+)"
        )

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

        # Check for title with parentheses (trickier since outer
        # parens are already removed). Look for pattern: url (title)
        # where there's a space before the opening paren
        paren_match = re.match(r"^(.+?)\s+\(([^)]*)\)$", link_content)
        if paren_match:
            return paren_match.group(1).strip()

        # If no title found, return the original content
        return link_content

    def _is_skippable_target(self, link_target: str) -> bool:
        """Return True if the link target is external or anchor-only."""
        return link_target.startswith(("http://", "https://", "mailto:", "tel:", "#"))

    def _overlaps_any(self, start: int, end: int, spans: List[tuple]) -> bool:
        """Return True if the range [start, end) is contained within any span."""
        for span_start, span_end in spans:
            if start >= span_start and end <= span_end:
                return True
        return False

    def _extract_standard_links(self, line: str, line_num: int, file_path: str) -> tuple:
        """Extract standard markdown links: [text](target).

        Returns (references, md_spans) where md_spans are (start, end) tuples
        for all markdown link matches, used for overlap prevention by downstream
        extractors.
        """
        refs = []
        md_spans = []
        for match in self.link_pattern.finditer(line):
            md_spans.append((match.start(), match.end()))
            link_text = match.group(1)
            link_target = self._extract_url_from_link_content(match.group(2))
            if self._is_skippable_target(link_target):
                continue
            refs.append(
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
        return refs, md_spans

    def _extract_reference_links(
        self, line: str, line_num: int, file_path: str
    ) -> List[LinkReference]:
        """Extract reference-style link definitions: [label]: url "title"."""
        ref_match = self.reference_pattern.match(line)
        if not ref_match:
            return []
        ref_target = self._extract_url_from_link_content(ref_match.group(2))
        if self._is_skippable_target(ref_target):
            return []
        return [
            LinkReference(
                file_path=file_path,
                line_number=line_num,
                column_start=ref_match.start(),
                column_end=ref_match.end(),
                link_text=ref_match.group(1),
                link_target=ref_target,
                link_type="markdown-reference",
            )
        ]

    def _extract_html_anchors(self, line: str, line_num: int, file_path: str) -> tuple:
        """Extract HTML anchor tags: <a href="target">.

        Returns (references, html_anchor_spans) where spans are used for
        overlap prevention by downstream extractors.
        """
        refs = []
        html_anchor_spans = []
        for match in self.html_anchor_pattern.finditer(line):
            link_target = match.group(1)
            if self._is_skippable_target(link_target):
                continue
            html_anchor_spans.append((match.start(), match.end()))
            refs.append(
                LinkReference(
                    file_path=file_path,
                    line_number=line_num,
                    column_start=match.start(1) - 1,
                    column_end=match.end(1) + 1,
                    link_text=link_target,
                    link_target=link_target,
                    link_type="html-anchor",
                )
            )
        return refs, html_anchor_spans

    def _extract_quoted_paths(
        self,
        line: str,
        line_num: int,
        file_path: str,
        md_spans: List[tuple],
        html_spans: List[tuple],
    ) -> List[LinkReference]:
        """Extract quoted file path references: "path/to/file.ext"."""
        refs = []
        for match in self.quoted_pattern.finditer(line):
            potential_file = match.group(1)
            if not self._looks_like_file_path(potential_file):
                continue
            if self._overlaps_any(match.start(), match.end(), md_spans):
                continue
            if self._overlaps_any(match.start(), match.end(), html_spans):
                continue
            refs.append(
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
        return refs

    def _extract_quoted_dirs(
        self,
        line: str,
        line_num: int,
        file_path: str,
        md_spans: List[tuple],
        html_spans: List[tuple],
    ) -> List[LinkReference]:
        """Extract quoted directory path references (PD-BUG-031)."""
        refs = []
        for match in self.quoted_dir_pattern.finditer(line):
            potential_dir = match.group(1)
            _, ext = os.path.splitext(potential_dir)
            if ext:
                continue
            if not self._looks_like_directory_path(potential_dir):
                continue
            if self._overlaps_any(match.start(), match.end(), md_spans):
                continue
            if self._overlaps_any(match.start(), match.end(), html_spans):
                continue
            refs.append(
                LinkReference(
                    file_path=file_path,
                    line_number=line_num,
                    column_start=match.start(1),
                    column_end=match.end(1),
                    link_text=potential_dir,
                    link_target=potential_dir,
                    link_type="markdown-quoted-dir",
                )
            )
        return refs

    def _extract_standalone_refs(
        self,
        line: str,
        line_num: int,
        file_path: str,
        md_spans: List[tuple],
    ) -> List[LinkReference]:
        """Extract unquoted standalone file references."""
        refs = []
        for match in self.standalone_pattern.finditer(line):
            potential_file = match.group(1)
            if not self._looks_like_file_path(potential_file):
                continue
            if self._overlaps_any(match.start(1), match.end(1), md_spans):
                continue
            refs.append(
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
        return refs

    def _extract_backtick_paths(
        self,
        line: str,
        line_num: int,
        file_path: str,
        md_spans: List[tuple],
    ) -> List[LinkReference]:
        """Extract backtick-quoted file paths: `path/to/file.ext` (PD-BUG-054)."""
        refs = []
        for match in self.backtick_path_pattern.finditer(line):
            potential_file = match.group(1)
            if not self._looks_like_file_path(potential_file):
                continue
            if self._overlaps_any(match.start(), match.end(), md_spans):
                continue
            refs.append(
                LinkReference(
                    file_path=file_path,
                    line_number=line_num,
                    column_start=match.start(1),
                    column_end=match.end(1),
                    link_text=potential_file,
                    link_target=potential_file,
                    link_type="markdown-backtick",
                )
            )
        return refs

    def _extract_backtick_dirs(
        self,
        line: str,
        line_num: int,
        file_path: str,
        md_spans: List[tuple],
    ) -> List[LinkReference]:
        """Extract backtick-quoted directory paths: `path/to/dir` (PD-BUG-054)."""
        refs = []
        for match in self.backtick_dir_pattern.finditer(line):
            potential_dir = match.group(1)
            _, ext = os.path.splitext(potential_dir)
            if ext:
                continue
            if not self._looks_like_directory_path(potential_dir):
                continue
            if self._overlaps_any(match.start(), match.end(), md_spans):
                continue
            refs.append(
                LinkReference(
                    file_path=file_path,
                    line_number=line_num,
                    column_start=match.start(1),
                    column_end=match.end(1),
                    link_text=potential_dir,
                    link_target=potential_dir,
                    link_type="markdown-backtick-dir",
                )
            )
        return refs

    def _extract_bare_paths(
        self,
        line: str,
        line_num: int,
        file_path: str,
        all_spans: List[tuple],
    ) -> List[LinkReference]:
        """Extract bare paths with separators: doc/path/to/dir (PD-BUG-054)."""
        refs = []
        for match in self.bare_path_pattern.finditer(line):
            potential_path = match.group(1)
            if self._overlaps_any(match.start(1), match.end(1), all_spans):
                continue
            _, ext = os.path.splitext(potential_path)
            if ext:
                if not self._looks_like_file_path(potential_path):
                    continue
            else:
                if not self._looks_like_directory_path(potential_path):
                    continue
            refs.append(
                LinkReference(
                    file_path=file_path,
                    line_number=line_num,
                    column_start=match.start(1),
                    column_end=match.end(1),
                    link_text=potential_path,
                    link_target=potential_path,
                    link_type="markdown-bare-path",
                )
            )
        return refs

    def _extract_at_prefix_paths(
        self,
        line: str,
        line_num: int,
        file_path: str,
        all_spans: List[tuple],
    ) -> List[LinkReference]:
        """Extract @-prefixed path references: @doc/path/file.md (PD-BUG-055)."""
        refs = []
        for match in self.at_prefix_pattern.finditer(line):
            potential_path = match.group(1)
            if self._overlaps_any(match.start(), match.end(), all_spans):
                continue
            _, ext = os.path.splitext(potential_path)
            if ext:
                if not self._looks_like_file_path(potential_path):
                    continue
            else:
                if not self._looks_like_directory_path(potential_path):
                    continue
            refs.append(
                LinkReference(
                    file_path=file_path,
                    line_number=line_num,
                    column_start=match.start(1),
                    column_end=match.end(1),
                    link_text=potential_path,
                    link_target=potential_path,
                    link_type="markdown-at-prefix",
                )
            )
        return refs

    def parse_content(self, content: str, file_path: str) -> List[LinkReference]:
        """Parse markdown content for links."""
        try:
            lines = content.split("\n")
            references = []
            in_mermaid_block = False

            for line_num, line in enumerate(lines, 1):
                stripped = line.strip()
                # Track mermaid fenced code blocks — content is illustrative,
                # not navigable paths (PD-BUG-055)
                if stripped.startswith("```"):
                    if in_mermaid_block:
                        in_mermaid_block = False
                        continue
                    elif stripped.startswith("```mermaid"):
                        in_mermaid_block = True
                        continue
                if in_mermaid_block:
                    continue

                std_refs, md_spans = self._extract_standard_links(line, line_num, file_path)
                references.extend(std_refs)
                references.extend(self._extract_reference_links(line, line_num, file_path))

                html_refs, html_anchor_spans = self._extract_html_anchors(line, line_num, file_path)
                references.extend(html_refs)

                # Skip standalone/quoted extraction on reference definition lines
                if self.reference_pattern.match(line) is not None:
                    continue

                references.extend(
                    self._extract_quoted_paths(
                        line, line_num, file_path, md_spans, html_anchor_spans
                    )
                )
                references.extend(
                    self._extract_quoted_dirs(
                        line, line_num, file_path, md_spans, html_anchor_spans
                    )
                )
                references.extend(
                    self._extract_standalone_refs(line, line_num, file_path, md_spans)
                )

                # Backtick-quoted paths and dirs (PD-BUG-054)
                all_spans = md_spans + html_anchor_spans
                references.extend(
                    self._extract_backtick_paths(line, line_num, file_path, all_spans)
                )
                references.extend(self._extract_backtick_dirs(line, line_num, file_path, all_spans))
                # Bare paths with separators (PD-BUG-054, PD-BUG-055)
                references.extend(self._extract_bare_paths(line, line_num, file_path, all_spans))
                # @-prefixed paths (PD-BUG-055)
                references.extend(
                    self._extract_at_prefix_paths(line, line_num, file_path, all_spans)
                )

            return references

        except Exception as e:
            self.logger.warning("parse_error", file_path=file_path, parser="markdown", error=str(e))
            return []
