"""
YAML file parser for extracting file references.

This parser handles YAML files and extracts file path references
from values throughout the YAML structure.
"""

from typing import List

import yaml

from ..models import LinkReference
from .base import BaseParser


class YamlParser(BaseParser):
    """Parser for YAML files (.yaml, .yml)."""

    def parse_file(self, file_path: str) -> List[LinkReference]:
        """Parse YAML file for file references."""
        try:
            content = self._safe_read_file(file_path)
            lines = content.split("\n")
            references = []

            try:
                # Parse YAML to find file references
                data = yaml.safe_load(content)

                # Look for file-like values in the YAML
                self._extract_yaml_file_refs(data, file_path, lines, references)

            except yaml.YAMLError:
                # Fall back to generic parsing if YAML is invalid
                from .generic import GenericParser

                generic_parser = GenericParser()
                return generic_parser.parse_file(file_path)

            return references

        except Exception as e:
            print(f"Warning: Could not parse YAML file {file_path}: {e}")
            return []

    def _extract_yaml_file_refs(
        self, data, file_path: str, lines: List[str], references: List[LinkReference], path=""
    ):
        """Recursively extract file references from YAML data."""
        if isinstance(data, dict):
            for key, value in data.items():
                self._extract_yaml_file_refs(value, file_path, lines, references, f"{path}.{key}")
        elif isinstance(data, list):
            for i, item in enumerate(data):
                self._extract_yaml_file_refs(item, file_path, lines, references, f"{path}[{i}]")
        elif isinstance(data, str) and self._looks_like_file_path(data):
            # Find the line number for this value
            line_num = self._find_line_number(lines, data)
            if line_num > 0:
                # Find the column position
                line_content = lines[line_num - 1]
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
                        link_type="yaml",
                    )
                )
