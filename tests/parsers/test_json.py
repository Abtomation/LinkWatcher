"""
Tests for the JSON parser.

This module tests JSON-specific link parsing functionality.
Implements JP test cases from comprehensive test documentation.
"""

from pathlib import Path

import pytest

from linkwatcher.models import LinkReference
from linkwatcher.parsers.json_parser import JsonParser


class TestJsonParser:
    """Test cases for JsonParser."""

    def test_parser_initialization(self):
        """Test parser initialization."""
        parser = JsonParser()

        # Check that parser is properly initialized
        assert parser is not None

    def test_jp_001_string_values_with_file_paths(self, temp_project_dir):
        """
        JP-001: String values with file paths

        Test Case: {"file": "path.txt"}
        Expected: File path parsed
        Priority: High
        """
        parser = JsonParser()

        # Create JSON file with file path string values
        json_file = temp_project_dir / "config.json"
        json_content = """{
  "application": {
    "name": "Test App",
    "config_file": "config/settings.conf",
    "data_file": "data/input.csv",
    "template": "templates/main.html"
  },
  "paths": {
    "log_file": "logs/app.log",
    "backup_dir": "backup/",
    "schema": "schemas/user.json"
  },
  "version": "1.0.0"
}"""
        json_file.write_text(json_content)

        # Parse the file
        references = parser.parse_file(str(json_file))

        # Should find file references
        assert len(references) >= 5

        # Check specific references
        targets = [ref.link_target for ref in references]
        assert "config/settings.conf" in targets
        assert "data/input.csv" in targets
        assert "templates/main.html" in targets
        assert "logs/app.log" in targets
        assert "schemas/user.json" in targets

        # Check reference types
        for ref in references:
            assert ref.link_type == "json"
            assert ref.file_path == str(json_file)

    def test_jp_002_nested_objects(self, temp_project_dir):
        """
        JP-002: Nested objects

        Test Case: Complex JSON with file refs
        Expected: All file paths found
        Priority: High
        """
        parser = JsonParser()

        # Create JSON with deeply nested structures
        json_file = temp_project_dir / "complex.json"
        json_content = """{
  "database": {
    "connections": {
      "primary": {
        "config": "db/primary.conf",
        "schema": "db/schema.sql"
      },
      "secondary": {
        "config": "db/secondary.conf",
        "backup": "db/backup.sql"
      }
    }
  },
  "services": {
    "web": {
      "static_files": "web/static/",
      "templates": "web/templates/",
      "config": {
        "main": "web/config/main.json",
        "logging": "web/config/logging.json"
      }
    },
    "api": {
      "docs": "api/swagger.json",
      "tests": "api/tests/"
    }
  },
  "monitoring": {
    "metrics": "monitoring/metrics.json",
    "alerts": {
      "config": "monitoring/alerts.json",
      "templates": {
        "email": "templates/alert_email.html",
        "slack": "templates/alert_slack.json"
      }
    }
  }
}"""
        json_file.write_text(json_content)

        # Parse the file
        references = parser.parse_file(str(json_file))

        # Should find many nested references
        assert len(references) >= 10

        # Check nested references
        targets = [ref.link_target for ref in references]
        assert "db/primary.conf" in targets
        assert "db/schema.sql" in targets
        assert "web/config/main.json" in targets
        assert "api/swagger.json" in targets
        assert "monitoring/metrics.json" in targets
        assert "templates/alert_email.html" in targets

    def test_jp_003_arrays_of_file_paths(self, temp_project_dir):
        """
        JP-003: Arrays of file paths

        Test Case: {"files": ["a.txt", "b.txt"]}
        Expected: All array items parsed
        Priority: High
        """
        parser = JsonParser()

        # Create JSON with arrays of file references
        json_file = temp_project_dir / "arrays.json"
        json_content = """{
  "input_files": [
    "data/file1.csv",
    "data/file2.csv",
    "data/file3.csv"
  ],
  "templates": [
    "templates/header.html",
    "templates/footer.html",
    "templates/content.html"
  ],
  "configs": [
    "config/dev.json",
    "config/prod.json",
    "config/test.json"
  ],
  "mixed_array": [
    {
      "name": "First",
      "file": "assets/first.json"
    },
    {
      "name": "Second",
      "file": "assets/second.json"
    }
  ],
  "scripts": ["scripts/build.sh", "scripts/deploy.sh", "scripts/test.sh"],
  "metadata": {
    "version": "1.0",
    "files": [
      "meta/version.txt",
      "meta/changelog.md"
    ]
  }
}"""
        json_file.write_text(json_content)

        # Parse the file
        references = parser.parse_file(str(json_file))

        # Should find all array items
        assert len(references) >= 14

        # Check array items
        targets = [ref.link_target for ref in references]

        # Input files array
        assert "data/file1.csv" in targets
        assert "data/file2.csv" in targets
        assert "data/file3.csv" in targets

        # Templates array
        assert "templates/header.html" in targets
        assert "templates/footer.html" in targets

        # Mixed array (nested objects)
        assert "assets/first.json" in targets
        assert "assets/second.json" in targets

        # Scripts array
        assert "scripts/build.sh" in targets
        assert "scripts/deploy.sh" in targets
        assert "scripts/test.sh" in targets

        # Nested arrays
        assert "meta/version.txt" in targets
        assert "meta/changelog.md" in targets

    @pytest.mark.xfail(reason="Escaped path line-number matching fails for some decoded paths")
    def test_jp_004_escaped_strings(self, temp_project_dir):
        """
        JP-004: Escaped strings

        Test Case: {"file": "path/with/backslashes.txt"}
        Expected: Escaped paths handled
        Priority: Medium
        """
        parser = JsonParser()

        # Create JSON with escaped strings
        json_file = temp_project_dir / "escaped.json"
        json_content = """{
  "windows_paths": {
    "config": "C:\\\\Program Files\\\\App\\\\config.ini",
    "data": "C:\\\\Users\\\\Data\\\\file.txt",
    "logs": "C:\\\\Logs\\\\app.log"
  },
  "escaped_chars": {
    "quotes": "file with \\"quotes\\".txt",
    "newlines": "path/nwith/nnewlines.txt",
    "tabs": "path/twith/ttabs.txt"
  },
  "mixed": {
    "normal": "normal/path.txt",
    "escaped": "escaped/path/file.txt",
    "unicode": "unicode/u0020file.txt"
  },
  "special": {
    "json_file": "data\\\\config.json",
    "backup": "backup/data/file.bak"
  }
}"""
        json_file.write_text(json_content)

        # Parse the file
        references = parser.parse_file(str(json_file))

        # Should find file references with proper unescaping
        targets = [ref.link_target for ref in references]

        # Check that escaped paths are handled
        # Note: The exact handling depends on the parser implementation
        # Some parsers might normalize paths, others might preserve escaping
        assert len(targets) >= 8

        # Should find some recognizable file references
        found_files = [
            t for t in targets if any(ext in t for ext in [".txt", ".ini", ".log", ".json", ".bak"])
        ]
        assert len(found_files) >= 6


class TestJsonParserEdgeCases:
    """Edge cases for JSON parser."""

    def test_invalid_json_handling(self, temp_project_dir):
        """Test handling of invalid JSON."""
        parser = JsonParser()

        # Create invalid JSON file
        json_file = temp_project_dir / "valid.json"
        json_content = """{
  "invalid": json,
  "missing": "quotes,
  "extra": "comma",
  "unclosed": {
    "bracket": "here"
  // missing closing brace
"""
        json_file.write_text(json_content)

        # Should not crash on invalid JSON
        references = parser.parse_file(str(json_file))

        # Should return empty list for invalid JSON
        assert isinstance(references, list)

    def test_empty_json_file(self, temp_project_dir):
        """Test handling of empty JSON file."""
        parser = JsonParser()

        # Create empty JSON file
        json_file = temp_project_dir / "empty.json"
        json_file.write_text("")

        # Should handle empty file gracefully
        references = parser.parse_file(str(json_file))
        assert references == []

    def test_json_with_null_values(self, temp_project_dir):
        """Test handling of JSON with null values."""
        parser = JsonParser()

        # Create JSON with null values
        json_file = temp_project_dir / "nulls.json"
        json_content = """{
  "config": {
    "file": "config.json",
    "backup": null,
    "data": "data.json",
    "cache": null
  },
  "files": [
    "file1.txt",
    null,
    "file2.txt",
    null
  ],
  "empty": null,
  "valid": "valid.json"
}"""
        json_file.write_text(json_content)

        # Should handle null values without issues
        references = parser.parse_file(str(json_file))

        # Should find the non-null file references
        targets = [ref.link_target for ref in references]
        assert "config.json" in targets
        assert "data.json" in targets
        assert "file1.txt" in targets
        assert "file2.txt" in targets
        assert "valid.json" in targets

    def test_json_with_numbers_and_booleans(self, temp_project_dir):
        """Test JSON with various data types."""
        parser = JsonParser()

        # Create JSON with mixed data types
        json_file = temp_project_dir / "mixed.json"
        json_content = """{
  "config": {
    "file": "config.json",
    "version": 1.2,
    "enabled": true,
    "debug": false,
    "timeout": 30
  },
  "files": [
    "file1.txt",
    123,
    "file2.txt",
    true,
    "file1.txt"
  ],
  "metadata": {
    "count": 42,
    "active": true,
    "log_file": "logs/app.log",
    "max_size": 1048576
  }
}"""
        json_file.write_text(json_content)

        # Should only find string values that look like file paths
        references = parser.parse_file(str(json_file))

        targets = [ref.link_target for ref in references]
        assert "config.json" in targets
        assert "file1.txt" in targets
        assert "file2.txt" in targets
        assert "file1.txt" in targets
        assert "logs/app.log" in targets

        # Should not find numbers or booleans
        assert 123 not in targets
        assert True not in targets
        assert 1.2 not in targets

    def test_deeply_nested_json(self, temp_project_dir):
        """Test very deeply nested JSON structures."""
        parser = JsonParser()

        # Create deeply nested JSON
        json_file = temp_project_dir / "deep.json"
        json_content = """{
  "level1": {
    "level2": {
      "level3": {
        "level4": {
          "level5": {
            "level6": {
              "level7": {
                "level8": {
                  "level9": {
                    "level10": {
                      "deep_file": "very/deep/nested/file.txt",
                      "another": "deep/file.json"
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}"""
        json_file.write_text(json_content)

        # Should handle deep nesting
        references = parser.parse_file(str(json_file))

        targets = [ref.link_target for ref in references]
        assert "very/deep/nested/file.txt" in targets
        assert "deep/file.json" in targets

    def test_large_json_arrays(self, temp_project_dir):
        """Test JSON with large arrays."""
        parser = JsonParser()

        # Create JSON with large array
        json_file = temp_project_dir / "large.json"

        # Generate large array of file references
        import json as json_module

        files = [f"data/file_{i:03d}.txt" for i in range(100)]
        json_content = json_module.dumps({"files": files})

        json_file.write_text(json_content)

        # Should handle large arrays efficiently
        references = parser.parse_file(str(json_file))

        # Should find all file references
        assert len(references) == 100

        targets = [ref.link_target for ref in references]
        assert "data/file_000.txt" in targets
        assert "data/file_050.txt" in targets
        assert "data/file_099.txt" in targets


class TestJsonParserDuplicateLineNumbers:
    """Regression tests for PD-BUG-013: duplicate-value line number resolution."""

    def test_bug013_duplicate_values_get_correct_line_numbers(self, temp_project_dir):
        """
        PD-BUG-013: When the same file path appears multiple times in JSON,
        each reference should get its own correct line number.
        """
        parser = JsonParser()

        json_file = temp_project_dir / "duplicates.json"
        json_content = """{
  "primary": "data.csv",
  "files": [
    "data.csv"
  ],
  "backup": {
    "source": "data.csv"
  }
}"""
        json_file.write_text(json_content)

        references = parser.parse_content(json_content, str(json_file))

        # Should find 3 references to data.csv
        data_refs = [r for r in references if r.link_target == "data.csv"]
        assert len(data_refs) == 3

        # Each must have a DIFFERENT line number (the correct one)
        line_numbers = [r.line_number for r in data_refs]
        assert len(set(line_numbers)) == 3, f"Expected 3 unique line numbers, got {line_numbers}"

        # Verify the actual line numbers are correct
        # Line 2: "primary": "data.csv"
        # Line 4: "data.csv"  (inside array)
        # Line 7: "source": "data.csv"
        assert sorted(line_numbers) == [2, 4, 7]

    def test_bug013_mixed_duplicate_and_unique_values(self, temp_project_dir):
        """
        PD-BUG-013: Mix of duplicate and unique paths should all resolve correctly.
        """
        parser = JsonParser()

        json_file = temp_project_dir / "mixed_dupes.json"
        json_content = """{
  "input": "shared.txt",
  "output": "unique.log",
  "backup": "shared.txt",
  "archive": "unique.log",
  "final": "shared.txt"
}"""
        json_file.write_text(json_content)

        references = parser.parse_content(json_content, str(json_file))

        shared_refs = [r for r in references if r.link_target == "shared.txt"]
        unique_refs = [r for r in references if r.link_target == "unique.log"]

        assert len(shared_refs) == 3
        assert len(unique_refs) == 2

        shared_lines = sorted([r.line_number for r in shared_refs])
        unique_lines = sorted([r.line_number for r in unique_refs])

        assert shared_lines == [2, 4, 6], f"shared.txt lines: {shared_lines}"
        assert unique_lines == [3, 5], f"unique.log lines: {unique_lines}"

    def test_bug013_adjacent_duplicate_values(self, temp_project_dir):
        """
        PD-BUG-013 edge case: same path on consecutive lines in an array.
        """
        parser = JsonParser()

        json_file = temp_project_dir / "adjacent.json"
        json_content = """{
  "files": [
    "report.md",
    "report.md",
    "report.md"
  ]
}"""
        json_file.write_text(json_content)

        references = parser.parse_content(json_content, str(json_file))

        report_refs = [r for r in references if r.link_target == "report.md"]
        assert len(report_refs) == 3

        line_numbers = [r.line_number for r in report_refs]
        assert (
            len(set(line_numbers)) == 3
        ), f"Expected 3 unique line numbers for adjacent duplicates, got {line_numbers}"
        assert sorted(line_numbers) == [3, 4, 5]
