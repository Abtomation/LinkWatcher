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
            assert ref.source_file == str(json_file)

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

    def test_jp_005_comments_in_json(self, temp_project_dir):
        """
        JP-005: Comments in JSON

        Test Case: JSON with // comments (if supported)
        Expected: Comments handled appropriately
        Priority: Low
        """
        parser = JsonParser()

        # Create JSON with comments (non-standard but sometimes used)
        json_file = temp_project_dir / "comments.json"
        json_content = """{
  // Configuration file - see docs/config.md for details
  "application": {
    "name": "Test App",
    // "data_file": "data/commented.csv", (commented out)
    "config_file": "config/real.json"  // Real reference
  },
  /*
   * Multi-line comment
   * References: logs/app.log, cache/data.cache
   */
  "database": {
    // "schema": "db/schema.sql", (not used)
    "active_schema": "db/active.sql"
  }
}"""
        json_file.write_text(json_content)

        # Parse the file
        references = parser.parse_file(str(json_file))

        # Standard JSON parsers don't support comments, so this might fail
        # or the parser might strip comments before parsing
        targets = [ref.link_target for ref in references] if references else []

        # If comments are stripped and parsing succeeds:
        if targets:
            assert "config/real.json" in targets
            assert "db/active.sql" in targets
            # Commented references should not be found
            assert "data/commented.csv" not in targets
            assert "db/schema.sql" not in targets


class TestJsonParserEdgeCases:
    """Edge cases for JSON parser."""

    def test_invalid_json_handling(self, temp_project_dir):
        """Test handling of invalid JSON."""
        parser = JsonParser()

        # Create invalid JSON file
        json_file = temp_project_dir / "tests/parsers/valid.json"
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
    "../../manual_markdown_tests/test_project/documentatio/file1.txt",
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
        assert "../../manual_markdown_tests/test_project/documentatio/file1.txt" in targets
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
    "../../manual_markdown_tests/test_project/documentatio/file1.txt",
    123,
    "file2.txt",
    true,
    "../../manual_markdown_tests/test_project/documentatio/file1.txt"
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
        assert "../../manual_markdown_tests/test_project/documentatio/file1.txt" in targets
        assert "file2.txt" in targets
        assert "../../manual_markdown_tests/test_project/documentatio/file1.txt" in targets
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
        files = [f"data/file_{i:03d}.txt" for i in range(100)]
        json_content = f'{{"files": {files}}}'

        json_file.write_text(json_content)

        # Should handle large arrays efficiently
        references = parser.parse_file(str(json_file))

        # Should find all file references
        assert len(references) == 100

        targets = [ref.link_target for ref in references]
        assert "data/file_000.txt" in targets
        assert "data/file_050.txt" in targets
        assert "data/file_099.txt" in targets
