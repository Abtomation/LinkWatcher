"""
Python file parser for extracting file references.

This parser handles Python files and extracts file references
from strings and comments, excluding standard library imports.
"""

import re
from typing import List

from ..models import LinkReference
from .base import BaseParser


class PythonParser(BaseParser):
    """Parser for Python files (.py)."""

    def __init__(self):
        super().__init__()
        # Pattern for quoted file paths
        # Use permissive match inside quotes — _looks_like_file_path() validates later
        self.quoted_pattern = re.compile(r'[\'"]([^\'"]+\.[a-zA-Z0-9]+)[\'"]')

        # Pattern for file paths in comments (find all occurrences)
        self.comment_pattern = re.compile(r"([a-zA-Z0-9_\-./\\]+\.[a-zA-Z0-9]+)")

        # Pattern for local import statements (relative imports with dots/slashes)
        self.local_import_pattern = re.compile(r"^\s*(?:import|from)\s+([a-zA-Z0-9_./]+)")

        # Pattern for standard library imports (to exclude them)
        self.stdlib_import_pattern = re.compile(
            r"^\s*(?:import|from)\s+(?:os|sys|re|json|datetime|pathlib|typing|collections)\b"
        )

    def parse_file(self, file_path: str) -> List[LinkReference]:
        """Parse Python file for file references."""
        try:
            content = self._safe_read_file(file_path)
            lines = content.split("\n")
            references = []

            for line_num, line in enumerate(lines, 1):
                # Skip standard library imports but process local imports
                if self.stdlib_import_pattern.match(line):
                    continue

                # Look for quoted file paths
                for match in self.quoted_pattern.finditer(line):
                    potential_file = match.group(1)

                    if self._looks_like_file_path(potential_file):
                        references.append(
                            LinkReference(
                                file_path=file_path,
                                line_number=line_num,
                                column_start=match.start(1),
                                column_end=match.end(1),
                                link_text=potential_file,
                                link_target=potential_file,
                                link_type="python-quoted",
                            )
                        )

                # Look for local import statements
                import_match = self.local_import_pattern.match(line)
                if import_match:
                    import_path = import_match.group(1)
                    # Convert dot notation to file path (e.g., src.utils.string_utils -> src/utils/string_utils)
                    if "." in import_path and not import_path.startswith("."):
                        file_path_candidate = import_path.replace(".", "/")
                        if self._looks_like_local_import(file_path_candidate):
                            references.append(
                                LinkReference(
                                    file_path=file_path,
                                    line_number=line_num,
                                    column_start=import_match.start(1),
                                    column_end=import_match.end(1),
                                    link_text=import_path,
                                    link_target=file_path_candidate,
                                    link_type="python-import",
                                )
                            )

                # Look for file paths in comments (only in lines that contain #)
                if "#" in line:
                    comment_part = line[line.find("#") :]  # Get only the comment part
                    for match in self.comment_pattern.finditer(comment_part):
                        potential_file = match.group(1)

                        if self._looks_like_file_path(potential_file):
                            # Adjust column position to account for the comment offset
                            comment_start = line.find("#")
                            references.append(
                                LinkReference(
                                    file_path=file_path,
                                    line_number=line_num,
                                    column_start=comment_start + match.start(1),
                                    column_end=comment_start + match.end(1),
                                    link_text=potential_file,
                                    link_target=potential_file,
                                    link_type="python-comment",
                                )
                            )

            return references

        except Exception as e:
            self.logger.warning("parse_error", file_path=file_path, parser="python", error=str(e))
            return []

    def _looks_like_local_import(self, import_path: str) -> bool:
        """Check if an import path looks like a local module reference."""
        # Local imports typically start with project directories like src/, lib/, etc.
        # or contain multiple path segments
        if "/" in import_path and len(import_path.split("/")) >= 2:
            # Check if it looks like a local path (not a standard library)
            first_part = import_path.split("/")[0]
            # Common local directory names
            local_dirs = {"src", "lib", "app", "core", "utils", "helpers", "modules", "packages"}
            return first_part in local_dirs or len(import_path.split("/")) >= 3
        return False
